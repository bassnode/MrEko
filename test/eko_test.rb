class EkoTest < Test::Unit::TestCase  

  context "the module" do
    should "return an Echonest API instance for nest" do
      assert_instance_of Echonest::Api, Eko.nest
    end
    
    should "return a Sequel instance for connection" do
      assert_instance_of Sequel::SQLite::Database, Eko.connection
    end
    
    should "raise an error when there is no api.key found" do
      File.expects(:exists?).with('api.key').returns(false)
      assert_raise(RuntimeError){ Eko.setup_echonest! }
    end
    
    should "return the MD5 of the passed filename" do
      md5 = Digest::MD5.hexdigest(open(__FILE__).read)
      assert_equal md5, Eko.md5(__FILE__)
    end
  end

end