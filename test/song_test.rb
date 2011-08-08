class SongTest < Test::Unit::TestCase

  TEST_MP3 = File.join(File.dirname(__FILE__), 'data', 'they_want_a_test.mp3')
  TAGLESS_MP3 = File.join(File.dirname(__FILE__), 'data', 'tagless.mp3')

  def enmfp_data_stub(overrides={})
    opts = {
      'code'         => '98ouhajsnd081oi2he0da8sdoihjasdi2y9e8aASD3e8yaushdjQWD',
      'tag'          => 0,
      'raw_data'     => "[]", # JSON returned from EN
      'metadata' => {
        'artist'       => 'SebastiAn',
        'title'        => 'Ross Ross Ross',
        'release'      => 'Total',
        'genre'        => 'Electronic',
        'filename'     => '/Users/you/Music/sebastian-ross_ross_ross.mp3',
        'bitrate'      => 320,
        'sample_rate'  => 44100,
        'codegen_time' => 9.221,
        'duration'     => 219,
      }
    }.merge(overrides)

    Hashie::Mash.new(opts)
  end

  def setup
    MrEko::Song.delete
  end


  context 'create_from_file!' do

    should 'catalog from tags by default' do
      MrEko::Song.expects(:catalog_via_tags).with(TEST_MP3, kind_of(Hash)).returns(MrEko::Song.new)
      MrEko::Song.create_from_file!(TEST_MP3)
    end

    should 'try cataloging via ENMFP when tags dont work' do
      MrEko::Song.expects(:catalog_via_tags).with(TEST_MP3, kind_of(Hash)).returns(nil)
      MrEko::Song.expects(:catalog_via_enmfp).with(TEST_MP3, kind_of(Hash)).returns(MrEko::Song.new)
      MrEko::Song.create_from_file!(TEST_MP3)
    end

    should 'not try cataloging if we have it stored already' do
      md5  = MrEko.md5(TEST_MP3)
      stub = MrEko::Song.new

      MrEko::Song.expects(:where).with(:md5 => md5).returns( [stub] )
      MrEko::Song.expects(:catalog_via_enmfp).never
      MrEko::Song.expects(:catalog_via_tags).never

      assert_equal stub, MrEko::Song.create_from_file!(TEST_MP3)
    end
  end


  context 'catalog_via_enmfp' do

    should 'raise an error if the ENMFP fingerprint contains errors' do
      MrEko::Song.stubs(:enmfp_data).returns(enmfp_data_stub('error' => 'BOOM'))
      assert_raise(MrEko::Song::EnmfpError){ MrEko::Song.catalog_via_enmfp(TEST_MP3) }
    end

    should 'try to upload when no songs are returned from the Song#identify call' do
      stub_data = enmfp_data_stub
      empty_profile_stub = stub(:songs => [])
      id_opts = {
        :code    => stub_data.raw_data,
        :artist  => stub_data.metadata.artist,
        :title   => stub_data.metadata.title,
        :release => stub_data.metadata.release,
        :bucket  => 'audio_summary'
      }
      MrEko::Song.stubs(:enmfp_data).returns(stub_data)
      Echonest::ApiMethods::Song.any_instance.expects(:identify).with(id_opts).returns(empty_profile_stub)
      MrEko::Song.expects(:get_datapoints_by_upload).returns([stub_everything, stub_everything(:id => 'whatever')])
      MrEko::Song.catalog_via_enmfp(TEST_MP3)
    end

    should 'try to get the profile data when a song is returned from the Song#identify call' do
      stub_data = enmfp_data_stub
      profile_stub = stub(:songs => [stub_everything(:id => 'FJJ299KLOP')])
      profile_details_stub = stub(:songs => [stub(:audio_summary => stub_everything)])

      MrEko::Song.stubs(:enmfp_data).returns(stub_data)
      Echonest::ApiMethods::Song.any_instance.expects(:identify).returns(profile_stub)
      Echonest::ApiMethods::Song.any_instance.expects(:profile).with(:id => 'FJJ299KLOP', :bucket => 'audio_summary').returns(profile_details_stub)
      MrEko::Song.expects(:get_datapoints_by_upload).never


      assert_difference 'MrEko::Song.count' do
        MrEko::Song.catalog_via_enmfp(TEST_MP3)
      end
    end
  end

  context 'catalog_via_tags' do

    context 'for a mp3 with no useful tag information' do

      setup do
        @mp3 = MrEko::Song.parse_id3_tags(TAGLESS_MP3)
        assert_nil @mp3.artist
        assert_nil @mp3.title
      end

      should 'return nil' do
        assert_nil MrEko::Song.catalog_via_tags(TAGLESS_MP3)
      end
    end

    context 'for a mp3 with the required tag information' do

      setup do
        @mp3 = MrEko::Song.parse_id3_tags(TEST_MP3)
        assert_not_nil @mp3.artist
        assert_not_nil @mp3.title
      end

      should 'create a Song' do
        songs_stub = [stub(:audio_summary => stub_everything, :artist => @mp3.artist, :title => @mp3.title, :id => 'xxx')]
        Echonest::ApiMethods::Song.any_instance.expects(:search).returns(stub(:songs => songs_stub))

        assert_difference 'MrEko::Song.count' do
          MrEko::Song.catalog_via_tags(TEST_MP3)
        end
      end
    end
  end
end
