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

  def create_song(opts={})
    defaults = {
      :filename => 'third_eye.mp3',
      :artist => 'Tool',
      :title => 'Third Eye',
      :md5 => Digest::MD5.hexdigest(Time.now.to_s + rand(10000000).to_s),
      :created_on => Time.now,
      :duration => 567,
      :tempo => 143
    }.merge(opts)

    MrEko::Song.create(defaults)
  end

end
