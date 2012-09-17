class MrEkoTest < Test::Unit::TestCase

  def path_to(binary)
    File.join(MrEko::HOME_DIR, 'ext', 'enmfp', binary)
  end

  context "the module" do

    should "return an Echonest API instance for nest" do
      assert_instance_of Echonest::Api, MrEko.nest
    end

    should "return a Sequel instance for connection" do
      assert_instance_of Sequel::SQLite::Database, MrEko.connection
    end

    should "return the MD5 of the passed filename" do
      md5 = Digest::MD5.hexdigest(open(__FILE__).read)
      assert_equal md5, MrEko.md5(__FILE__)
    end

    context 'db_name' do

      should 'return the test DB when in that env' do
        assert_equal 'db/eko_test.db', MrEko.db_name
      end

      should 'return the main DB when not in the test env' do
        MrEko.stubs(:env).returns('development')
        assert_equal File.join(MrEko::USER_DIR, 'eko.db'), MrEko.db_name
      end
    end

    context 'enmfp_binary' do

      should 'return proper Darwin bin' do
        MrEko.stubs(:ruby_platform).returns("i686-darwin10.6.0")
        assert_equal path_to('codegen.Darwin'), MrEko.enmfp_binary
      end

      should 'return proper Windows bin' do
        MrEko.stubs(:ruby_platform).returns("Win32")
        assert_equal path_to('codegen.windows.exe'), MrEko.enmfp_binary
      end

      should 'return proper 686 bin' do
        MrEko.stubs(:ruby_platform).returns("i686-linux")
        assert_equal path_to('codegen.Linux-i686'), MrEko.enmfp_binary
      end

      should 'return proper x86 bin' do
        MrEko.stubs(:ruby_platform).returns("x86_64-linux")
        assert_equal path_to('codegen.Linux-x86_64'), MrEko.enmfp_binary
      end
    end
  end

end
