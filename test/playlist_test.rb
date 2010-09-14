class PlaylistTest < Test::Unit::TestCase  
  def sequel_dataset_stub
    data = mock()
    data.stubs(:all).returns( [] )
    data
  end
  
  context "a new playlist" do
    setup do
      @playlist = Eko::Playlist.new
    end
    
    should "have no songs" do
      assert_equal 0, @playlist.songs.size
    end
  end
  
  context "create_from_options" do
    
    setup do
      @options = {:tempo => 100..200}
      Eko::Song.delete
      @playlist_count = Eko::Playlist.count
    end

    should "not create a playlist when there no songs found" do
      assert_equal 0, Eko::Song.count
      assert_raise(Eko::Playlist::NoSongsError){ Eko::Playlist.create_from_options(@options) }
      assert_equal @playlist_count, Eko::Playlist.count
    end
    
    should "create a playlist when there are songs found" do
      assert Eko::Song.insert(  :tempo => @options[:tempo].max, 
                                :filename => 'third_eye.mp3',
                                :artist => 'Tool', 
                                :title => 'Third Eye',
                                :md5 => Digest::MD5.hexdigest(Time.now.to_s),
                                :created_on => Time.now,
                                :duration => 567
                              )
                              
      assert Eko::Playlist.create_from_options(@options)
      assert_equal @playlist_count + 1, Eko::Playlist.count
    end
    
    should "filter out certain options before querying for songs" do
      unfiltered_options = {:name => "Rock You in Your Face mix #{rand(1000)}", :time_signature => 4}
      Eko::Song.expects(:where).with(Not(has_key(:name))).once.returns(sequel_dataset_stub)
      assert_raise(Eko::Playlist::NoSongsError){ Eko::Playlist.create_from_options(unfiltered_options) }
    end
  end 
  
  context "prepare_options!" do
    
    context "when passed a preset option" do
      should "only use the presets' options, not the others passed" do
        opts = { :time_signature => 4, :preset => :gym }
        Eko::Playlist.prepare_options!(opts)
        assert !opts.has_key?(:time_signature)
        assert_equal Eko::Presets::FACTORY[:gym][:tempo], opts[:tempo]
      end
    end
    
    context "for tempo" do
      
      should "not transform when tempo is a Range" do
        opts = {:tempo => 160..180}
        Eko::Playlist.prepare_options!(opts)
        assert_equal 160..180, opts[:tempo]
      end
      
      should "transform even when there aren't any passed tempo opts" do
        opts = {:time_signature => 4}
        Eko::Playlist.prepare_options!(opts)
        assert opts.has_key? :tempo
      end

      should "remove min and max keys" do
        opts = {:min_tempo => 100, :max_tempo => 200}
        Eko::Playlist.prepare_options!(opts)
        assert !opts.has_key?(:min_tempo)
        assert !opts.has_key?(:max_tempo)
      end
      
      should "create a range with the passed min and max tempos" do
        opts = {:min_tempo => 100, :max_tempo => 200}
        Eko::Playlist.prepare_options!(opts)
        assert_equal 100..200, opts[:tempo]
      end
    end
    
    context "for duration" do
      
      should "not transform when duration is a Range" do
        opts = {:duration => 200..2010}
        Eko::Playlist.prepare_options!(opts)
        assert_equal 200..2010, opts[:duration]
      end
      
      should "transform even when there aren't any passed duration opts" do
        opts = {:time_signature => 4}
        Eko::Playlist.prepare_options!(opts)
        assert opts.has_key? :duration
      end

      should "remove min and max keys" do
        opts = {:min_duration => 100, :max_duration => 2000}
        Eko::Playlist.prepare_options!(opts)
        assert !opts.has_key?(:min_duration)
        assert !opts.has_key?(:max_duration)
      end

      should "create a range with the passed min and max durations" do
        opts = {:min_duration => 100, :max_duration => 2000}
        Eko::Playlist.prepare_options!(opts)
        assert_equal 100..2000, opts[:duration]
      end
    end
    
    context "for mode" do
      should "transform into numeric representation" do
        opts = {:mode => 'minor'}
        Eko::Playlist.prepare_options!(opts)
        assert_equal 0, opts[:mode]
      end
    end

    context "for key" do
      should "transform into numeric representation" do
        opts = {:key => 'C#'}
        Eko::Playlist.prepare_options!(opts)
        assert_equal 1, opts[:key]
      end
    end

  end
end