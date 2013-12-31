ENV['EKO_ENV'] = 'test'
require "bundler/setup"

require 'test/unit'
require 'shoulda'
require 'mocha/setup'
require "mr_eko"
require "ruby-debug"
# Clear the tables out
(MrEko.connection.tables - [:schema_info]).each do |table|
  MrEko.connection.run "DELETE FROM #{table}"
end

class Test::Unit::TestCase

  TEST_MP3 = File.join(File.dirname(__FILE__), 'data', 'they_want_a_test.mp3')
  TAGLESS_MP3 = File.join(File.dirname(__FILE__), 'data', 'tagless.mp3')
  UNICODE_MP3 = File.join(File.dirname(__FILE__), 'data', 'unicode.mp3')


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
