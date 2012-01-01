class TimedPlaylistTest < Test::Unit::TestCase

  context 'a new TimedPlaylist' do

    should 'set the passed options as expected' do
      pl = MrEko::TimedPlaylist.new(:length => 600, :facet => :tempo)
      assert_equal 600, pl.length
      assert_equal :tempo, pl.facet
    end

  end

  context 'initial' do

    should 'add the attribute to the list of initial attributes' do
      MrEko::TimedPlaylist.new(:length => 600, :name => 'sad shit', :facet => :mode) do |pl|
        assert pl.initial = :minor
        assert_equal :minor, pl.initial
      end
    end
  end

  context 'final' do

    should 'add the attribute to the list of final attributes' do
      MrEko::TimedPlaylist.new(:length => 200, :name => 'Rock', :facet => :tempo) do |pl|
        assert pl.final = 120
        assert_equal 120, pl.final
      end
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

    context 'validation' do
      should "raise an exception when initial and final attribute keys don't match" do
        pl = MrEko::TimedPlaylist.new(:length => 1000, :facet => :tempo) do |pl|
          assert pl.initial = 66
        end

        assert_raise(MrEko::InvalidAttributes){ pl.save }
      end
    end
  end
end
