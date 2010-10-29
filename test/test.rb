ENV['EKO_ENV'] = 'test'
require 'bundler'
Bundler.setup
Bundler.require :test

class Test::Unit::TestCase
  
  # Could be fleshed out some more.
  def sequel_dataset_stub
    data = mock()
    data.stubs(:all).returns( [] )
    data
  end

end