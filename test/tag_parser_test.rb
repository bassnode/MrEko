class TagParserTest < Test::Unit::TestCase

  context 'parse' do

    should 'return an abject with the tags' do
      parser = MrEko::TagParser.parse(TEST_MP3)

      assert_equal 'Swamp Rooters', parser.artist
      assert_equal 'Swamp Cat Rag', parser.title
      assert_equal 'Misc', parser.album
    end

    should 'handles files without tags' do
      parser = MrEko::TagParser.parse(TAGLESS_MP3)

      assert_nil parser.artist
      assert_nil parser.title
      assert_nil parser.album
    end
  end
end
