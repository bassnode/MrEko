require "rubygems"
require "bundler"
Bundler.setup

require "sqlite3"
require "sequel"
require "logger"
require "digest/md5"
require "echonest"

EKO_ENV = ENV['EKO_ENV'] || 'development'
Sequel.default_timezone = :utc 

module MrEko
  VERSION = '0.1.0'
  USER_DIR = File.join(ENV['HOME'], ".mreko")
  HOME_DIR = File.join(File.dirname(__FILE__), '..')
  
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
    
    def setup!
      @logger ||= Logger.new(STDOUT)
      setup_db!
      setup_echonest!
    end
    
    def setup_db!
      return @connection if @connection
      @connection = Sequel.sqlite(db_name)
      @connection.loggers << @logger
    end
    
    def setup_echonest!
      @nest ||= Echonest(File.read(api_key))
    end
    
    def db_name
      env == 'test' ? 'db/eko_test.db' : 'db/eko.db'
    end
    
    def api_key
      [File.join(USER_DIR, 'echonest_api.key'), File.join(HOME_DIR, 'echonest_api.key')].each do |file|
        return file if File.exists?(file)
      end
      raise "You need to create an echonest_api.key file in #{USER_DIR}"
    end
  end
end


MrEko.setup!

require "lib/mr_eko/presets"
require "lib/mr_eko/playlist"
require "lib/mr_eko/song"
