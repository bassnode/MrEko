begin
  require ::File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  require "rubygems"
  require "bundler"
  Bundler.setup
end

require "sqlite3"
require "sequel"
require "logger"
require "digest/md5"
require "echonest"

EKO_ENV = ENV['EKO_ENV'] || 'development'
Sequel.default_timezone = :utc 

module Eko
  
  class << self
    
    def env
      EKO_ENV
    end

    def connection
      @connection
    end    
    
    def nest
      @nest
    end
    
    def md5(filename)
      Digest::MD5.hexdigest(open(filename).read)
    end
    
    def load!
      @logger ||= Logger.new(STDOUT)
      setup_db!
      setup_echonest!
    end
    
    def setup_db!
      return @connection if @connection
      @connection = Sequel.sqlite(db_name)
      @connection.loggers << @logger
    end
    
    # FIXME: Allow the key to be somewhere more public like
    # in the user's home dir or /etc
    def setup_echonest!
      raise "You need to create an api.key" unless File.exists?('api.key')
      @nest ||= Echonest(File.read('api.key'))
    end
    
    def db_name
      env == 'test' ? 'db/eko_test.db' : 'db/eko.db'
    end
  end
end


Eko.load!
require "lib/playlist"
require "lib/song"
