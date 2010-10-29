class MrEkoTest < Test::Unit::TestCase  

  context "the module" do
    
    should "return an Echonest API instance for nest" do
      assert_instance_of Echonest::Api, MrEko.nest
    end
    
    should "return a Sequel instance for connection" do
      assert_instance_of Sequel::SQLite::Database, MrEko.connection
    end
    
    # should "raise an error when there is no api.key found" do
      # File.expects(:exists?).with(File.join(MrEko::USER_DIR, 'echonest_api.key')).returns(false)
      # File.expects(:exists?).with(File.join(MrEko::HOME_DIR, 'echonest_api.key')).returns(false)
      # assert_raise(RuntimeError){ MrEko.setup_echonest! }
    # end
    
    should "return the MD5 of the passed filename" do
      md5 = Digest::MD5.hexdigest(open(__FILE__).read)
      assert_equal md5, MrEko.md5(__FILE__)
    end
  end

end