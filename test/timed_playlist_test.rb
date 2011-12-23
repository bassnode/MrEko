class TimedPlaylistTest < Test::Unit::TestCase

  context 'a new TimedPlaylist' do

    should 'accept a hash of options' do
      assert MrEko::TimedPlaylist.new(:length => 600, :name => 'whatever')
    end

    should 'set those options as expected' do
      pl = MrEko::TimedPlaylist.new(:length => 600, :name => 'Awesome')
      assert_equal 600, pl.length
      assert_equal 'Awesome', pl.name
    end

  end

  context 'initial' do

    should 'add the attribute to the list of initial attributes' do
      MrEko::TimedPlaylist.new(:length => 600, :name => 'sad shit') do |pl|
        assert pl.initial(:mode, :minor)
        assert_equal :minor, pl.attributes[:initial][:mode]
      end
    end
  end

  context 'final' do

    should 'add the attribute to the list of final attributes' do
      MrEko::TimedPlaylist.new(:length => 200, :name => 'Rock') do |pl|
        assert pl.final(:tempo, 120)
        assert_equal 120, pl.attributes[:final][:tempo]
      end
    end
  end

  context 'static' do

    should 'add the attribute to the list of static attributes' do
      MrEko::TimedPlaylist.new(:length => 1000, :name => 'Bump') do |pl|
        assert pl.static(:genre, 'HipHop')
        assert_equal 'HipHop',  pl.attributes[:static][:genre]
      end
    end
  end

  context 'save' do

    should 'raise an exception when there are no songs for the parameters' do

      # No moar songs!
      MrEko::Song.delete

      list = MrEko::TimedPlaylist.new(:length => 360) do |pl|
        pl.initial(:tempo, 100)
        pl.final(:tempo, 106)
      end

      assert_raises(MrEko::NoSongsError){ list.save }
    end

    should 'populate the step_map' do
      create_song(:tempo => 100)

      list = MrEko::TimedPlaylist.new(:length => 360) do |pl|
        pl.initial(:tempo, 100)
        pl.final(:tempo, 106)
      end

      assert list.step_map.empty?
      assert list.save
      assert !list.step_map.empty?
    end

    should 'increase the step length to 4.minutes if value is less than that' do
      create_song(:tempo => 70)

      list = MrEko::TimedPlaylist.new(:length => 300) do |pl|
        pl.initial(:tempo, 60)
        pl.final(:tempo, 80)
      end

      assert list.save
      assert_equal [20, 240], list.step_map[:tempo]
    end

    should 'populate the step_map with the proper mode step data' do
      create_song(:mode => 0)

      list = MrEko::TimedPlaylist.new(:length => 3060) do |pl|
        pl.initial(:mode, :major)
        pl.final(:mode, :minor)
      end

      assert list.save
      assert_equal [2, 3060.to_f/2], list.step_map[:mode]
    end

    should 'populate the step_map with the proper tempo and loudness step data' do
      create_song(:tempo => 65)
      create_song(:loudness => -10)

      list = MrEko::TimedPlaylist.new(:length => 3600) do |pl|
        pl.initial(:tempo, 60)
        pl.final(:tempo, 70)

        pl.initial(:loudness, -13)
        pl.final(:loudness, -9)
      end

      assert list.save
      assert_equal [10, 3600.to_f/10], list.step_map[:tempo]
      assert_equal [4, 3600.to_f/4], list.step_map[:loudness]
    end

    should 'populate the step_map with the proper energy and danceability fractional step data' do
      create_song(:energy => 0.7)
      create_song(:danceability => 0.23)

      list = MrEko::TimedPlaylist.new(:length => 3600) do |pl|
        pl.initial(:energy, 0.622)
        pl.final(:energy, 0.888)

        pl.initial(:danceability, 0.22)
        pl.final(:danceability, 0.88)
      end

      assert list.save
      assert_equal [3, (3600.to_f/3).round], list.step_map[:energy]
      assert_equal [7, (3600.to_f/7).round], list.step_map[:danceability]
    end

    should 'populate the step_map with the proper key step data' do
      create_song(:key => MrEko.key_lookup('C#'))

      list = MrEko::TimedPlaylist.new(:length => 3060) do |pl|
        pl.initial(:key, 'C#')
        pl.final(:key, 'A#')
      end

      step = MrEko.key_lookup('A#') - MrEko.key_lookup('C#')
      assert list.save
      assert_equal [step, 3060.to_f/step], list.step_map[:key]
    end


    context 'validation' do
      should "raise an exception when initial and final attribute keys don't match" do
        pl = MrEko::TimedPlaylist.new(:length => 1000) do |pl|
          assert pl.initial(:tempo, 66)
        end

        assert_raise(MrEko::TimedPlaylist::InvalidAttributes){ pl.save }
      end
    end
  end
end
