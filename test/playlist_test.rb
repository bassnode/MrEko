class PlaylistTest < Test::Unit::TestCase

  context "a new playlist" do
    setup do
      @playlist = MrEko::Playlist.new
    end

    should "have no songs" do
      assert_equal 0, @playlist.songs.size
    end
  end

  context "create_from_options" do

    setup do
      @options = {:tempo => 100..200}
      MrEko::Song.delete
      @playlist_count = MrEko::Playlist.count
    end

    should "not create a playlist when there no songs found" do
      assert_equal 0, MrEko::Song.count
      assert_raise(MrEko::NoSongsError){ MrEko::Playlist.create_from_options(@options) }
      assert_equal @playlist_count, MrEko::Playlist.count
    end

    should "create a playlist when there are songs found" do
      assert create_song(:tempo => @options[:tempo].max)

      assert MrEko::Playlist.create_from_options(@options)
      assert_equal @playlist_count + 1, MrEko::Playlist.count
    end

  end

  context 'output' do
    setup do
      @playlist = MrEko::Playlist.create(:name => "Best Playlist#{rand(1000)}")
      @song1 = create_song(:title => 'Song A')
      @song2 = create_song(:title => 'Song B')
      @playlist.songs << @song1
      @playlist.songs << @song2
    end

    context 'default format' do

      should 'be PLS' do
        assert @playlist.output.match /^\[playlist\]/
        assert @playlist.output.match /NumberOfEntries/
      end
    end

    context 'text format' do

      should 'contain a comma-sep list of the song name and file path' do
        assert @playlist.output(:text).match /#{@song1.filename}\, #{@song1.title}/
        assert @playlist.output(:text).match /#{@song2.filename}\, #{@song2.title}/
      end
    end
  end

  context "prepare_options" do

    context "when passed a preset option" do

      should "only use the presets' options, not the others passed" do
        opts = { :time_signature => 4, :preset => :gym }
        transformed = MrEko::Playlist.prepare_options(opts)

        assert_nil transformed.detect{ |opt| opt.has_key?(:time_signature) }
        assert_equal MrEko::Presets::FACTORY[:gym].detect{ |opt| opt.has_key?(:tempo) }[:tempo],
                     transformed.detect{ |opt| opt.has_key?(:tempo) }[:tempo]
      end
    end

    context "transformation" do

      should "handle less-than sign" do
        transformed = MrEko::Playlist.prepare_options({:duration => "<20"})
        assert_equal "duration < 20".lit, transformed.last
      end

      should "handle greater-than sign" do
        transformed = MrEko::Playlist.prepare_options({:tempo => ">151"})
        assert_equal "tempo > 151".lit, transformed.last
      end

      should "handle basic assignment" do
        transformed = MrEko::Playlist.prepare_options({:artist => "Radiohead"})
        assert_equal( {:artist => "Radiohead"}, transformed.last )
      end

      context "percentage values" do
        [:energy, :danceability].each do |attribute|
          should "translate #{attribute} into decimal form" do
            transformed = MrEko::Playlist.prepare_options({attribute => 32})
            assert_equal( {attribute => 0.32}, transformed.last )
          end
        end
      end
    end

    context "defaults" do
      should "be overridable" do
        transformed = MrEko::Playlist.prepare_options({:tempo => 180})
        assert_equal 180, transformed.detect{ |opt| opt.has_key?(:tempo) }[:tempo]
      end

      should "be set for tempo" do
        transformed = MrEko::Playlist.prepare_options({})
        assert_equal 0..500, transformed.detect{ |opt| opt.has_key?(:tempo) }[:tempo]
      end

      should "be set for duration" do
        transformed = MrEko::Playlist.prepare_options({})
        assert_equal 10..1200, transformed.detect{ |opt| opt.has_key?(:duration) }[:duration]
      end
    end

    context "for mode" do

      should "transform into numeric representation" do
        transformed = MrEko::Playlist.prepare_options(:mode => 'minor')
        assert_equal 0, transformed.detect{ |opt| opt.key?(:mode) }[:mode]
      end
    end

    context "for key" do

      should "transform into numeric representation" do
        transformed = MrEko::Playlist.prepare_options(:key => 'C#')
        assert_equal 1, transformed.detect{ |opt| opt.key?(:key) }[:key]
      end
    end

  end
end
