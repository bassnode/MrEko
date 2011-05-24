ENV['EKO_ENV'] = 'test'
require "bundler/setup"
Bundler.setup

require 'test/unit'
require 'shoulda'
require 'mocha'
require "mr_eko"
require "ruby-debug"

require 'sequel/extensions/migration'
Sequel::Migrator.apply(MrEko.connection, File.join(File.dirname(__FILE__), "..", "db", "migrate"))
# Clear the tables out
(MrEko.connection.tables - [:schema_info]).each do |table|
  MrEko.connection.run "DELETE FROM #{table}"
end

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

  def assert_difference(expression, difference = 1, message = nil, &block)
    b = block.send(:binding)
    exps = expression.is_a?(Array) ? expression : [expression]
    before = exps.map { |e| eval(e, b) }

    yield

    exps.each_with_index do |e, i|
      error = "#{e.inspect} didn't change by #{difference}"
      error = "#{message}.\n#{error}" if message
      assert_equal(before[i] + difference, eval(e, b), error)
    end
  end


end
