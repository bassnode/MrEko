ENV['EKO_ENV'] = 'test'
require "bundler/setup"
Bundler.setup

require 'test/unit'
require 'shoulda'
require 'mocha'
require "mr_eko"

require 'sequel/extensions/migration'
Sequel::Migrator.apply(MrEko.connection, File.join(File.dirname(__FILE__), "..", "db", "migrate"))

class Test::Unit::TestCase
  
  # Could be fleshed out some more.
  def sequel_dataset_stub
    data = mock()
    data.stubs(:all).returns( [] )
    data
  end

end