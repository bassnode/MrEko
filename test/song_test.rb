require 'ostruct'
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

  def song_identify_stub
    Hashie::Mash.new(:artist_id => "ARZQYSZ1187FB3AC39", :artist_name => "Sebastian",
                     :id => "SOEQMAC12A6701D920", :message => "OK (match type 6)", :score =>57, :tag => 0, :title => "Ross Ross Ross",
                     :audio_summary => Hashie::Mash.new(:analysis_url => "url", :audio_md5 => "fb592e1fa581a8ad0b0478a45130e9e0",
                                                        :danceability => 0.265574327869162, :duration =>1223,
                                                        :energy => 0.732951527606216, :key => 11, :loudness =>-10.328,
                                                        :mode => 0, :tempo => 137.538, :time_signature =>1)
                    )
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

    should 'not atempt to catalog via ENMFP if the tags_only option is passed in' do
      MrEko::Song.expects(:catalog_via_tags).with(TEST_MP3, kind_of(Hash)).returns(nil)
      MrEko::Song.expects(:catalog_via_enmfp).never

      MrEko::Song.create_from_file!(TEST_MP3, :tags_only => true)

    end
  end


  context 'catalog_via_enmfp' do

    should 'try uploading if the ENMFP fingerprint contains errors' do
      MrEko::Song.stubs(:enmfp_data).raises(MrEko::EnmfpError)
      MrEko::Song.expects(:get_datapoints_by_upload).with(TEST_MP3).returns([stub_everything, stub_everything(:audio_summary => stub_everything, :id => 'yu82')])
      MrEko::Song.catalog_via_enmfp(TEST_MP3)
    end

    should 'return nil when the file is too big' do
      MrEko::Song.stubs(:file_too_big?).returns(true)
      MrEko.nest.song.expects(:identify).never
      assert_nil MrEko::Song.catalog_via_enmfp(TEST_MP3)
    end

    should 'try to upload when no songs are returned from the Song#identify call' do
      MrEko::Song.stubs(:enmfp_data).returns(enmfp_data_stub)
      MrEko::Song.expects(:identify_from_enmfp_data).with(enmfp_data_stub).raises(MrEko::EnmfpError.new("no songs"))
      MrEko::Song.expects(:get_datapoints_by_upload).returns([stub_everything, stub_everything(:audio_summary => stub_everything, :id => 'yu82')])

      MrEko::Song.catalog_via_enmfp(TEST_MP3)
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

  context 'cleaning funky ID3 tags' do

    should "decode iTunes' crazy tags" do
      dm = Iconv.conv('UTF-16', 'LATIN1', 'Dead Meadow')
      tag_stub = OpenStruct.new(:artist => dm, :title => 'Good Moaning')
      ID3Lib::Tag.expects(:new).once.returns(tag_stub)
      parsed_tags = MrEko::Song.parse_id3_tags(TEST_MP3)

      assert_equal "Dead Meadow", parsed_tags.artist
    end

    should "not blow up when there isn't any crazy encoding" do
      tag_stub = OpenStruct.new(:artist => 'Dead Meadow', :title => 'Good Moaning')
      ID3Lib::Tag.expects(:new).once.returns(tag_stub)

      assert_nothing_raised{ MrEko::Song.parse_id3_tags(TEST_MP3) }
    end
  end
end
