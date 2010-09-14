begin
  # Require the preresolved locked set of gems.
  require ::File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fallback on doing the resolve at runtime.
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
  # autoload :Playlist, 'lib/playlist'
  
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
      setup_db
      setup_echonest
    end
    
    def setup_db
      return @connection if @connection
      @connection = Sequel.sqlite(db_name)
      @connection.loggers << @logger
    end
    
    def setup_echonest
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
