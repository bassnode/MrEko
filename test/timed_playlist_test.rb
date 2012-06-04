class TimedPlaylistTest < Test::Unit::TestCase

  context 'a new TimedPlaylist' do

    should 'set the passed options as expected' do
      pl = MrEko::TimedPlaylist.new(:length => 600, :facet => :tempo)
      assert_equal 600, pl.length
      assert_equal :tempo, pl.facet
    end

  end

  context 'save' do

    should 'raise an exception when there are no songs for the parameters' do
      # No moar songs!
      MrEko::Song.delete

      list = MrEko::TimedPlaylist.new(:length => 360, :facet => :tempo) do |pl|
        pl.initial = 100
        pl.final = 106
      end

      assert_raises(MrEko::NoSongsError){ list.save }
    end

    context 'facet range' do

      should 'add the attribute to the list of initial attributes' do
        list = MrEko::TimedPlaylist.new(:length => 600, :name => 'sad shit', :facet => :mode)
        list.initial = :minor

        assert_equal :minor, list.initial
      end

      should 'add the attribute to the list of final attributes' do
        list = MrEko::TimedPlaylist.new(:length => 200, :name => 'Rock', :facet => :tempo)
        list.final = 120

        assert_equal 120, list.final
      end

      should 'raise an error if only one facet boundary is set' do
        list = MrEko::TimedPlaylist.new(:length => 3600, :facet => :mode)
        list.initial = :minor

        assert_raise(MrEko::InvalidAttributes){ list.save }
      end

      context 'value translation' do
        [:energy, :danceability].each do |attr|
          should "turn #{attr} into a percentage" do
            song = create_song(attr => 0.76)
            list = MrEko::TimedPlaylist.new(:length => 3600, :facet => attr)
            list.initial = 60
            list.final = 100
            assert list.save

            assert_equal 0.60, list.initial
            assert_equal 1.0, list.final
          end
        end

        should "translate mode into a number" do
          song = create_song(:mode => 0)
          list = MrEko::TimedPlaylist.new(:length => 3600, :facet => :mode)
          list.initial = 'minor'
          list.final = 'major'
          assert list.save

          assert_equal 0, list.initial
          assert_equal 1, list.final
        end

        should "translate key into a number" do
          song = create_song(:key => 5)
          list = MrEko::TimedPlaylist.new(:length => 3600, :facet => :key)
          list.initial = 'F'
          list.final = 'A'
          assert list.save

          assert_equal 5, list.initial
          assert_equal 9, list.final
        end
      end
    end

    context 'the songs' do
      setup do
        MrEko::Song.delete
        @song_count = 40

        @song_count.times do |i|
          create_song(:tempo => 50 + i , :duration => 1.minutes, :title => "Song #{i}")
        end

        @list = MrEko::TimedPlaylist.new(:length => 30.minutes, :facet => :tempo, :initial => 50, :final => 100)
        @list.save
      end

      should "fill the requested duration" do
        assert_equal 30, @list.songs.size
      end

      should "fit the required constraints" do
        assert @list.songs.all?{ |song| song.tempo >= @list.initial && song.tempo <= @list.final }
      end

      should "be sorted ascending, by default" do
        sorted = @list.songs.sort_by &:tempo
        assert_equal sorted, @list.songs
      end
    end
  end

end
