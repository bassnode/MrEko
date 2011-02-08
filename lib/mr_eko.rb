require "rubygems"
require "bundler"
Bundler.setup

require "sqlite3"
require "sequel"
require "logger"
require "hashie"
require "digest/md5"
require "echonest"

STDOUT.sync = true

EKO_ENV = ENV['EKO_ENV'] || 'development'
Sequel.default_timezone = :utc

module MrEko
  VERSION = '0.2.3'
  USER_DIR = File.join(ENV['HOME'], ".mreko")
  FINGERPRINTS_DIR = File.join(USER_DIR, 'fingerprints')
  HOME_DIR = File.join(File.dirname(__FILE__), '..')

  MODES = %w(minor major)
  CHROMATIC_SCALE = %w(C C# D D# E F F# G G# A A# B).freeze

  class << self
    attr_accessor :logger

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
      setup_directories!
      setup_db!
      setup_echonest!
    end

    def setup_directories!
      Dir.mkdir(USER_DIR) unless File.directory?(USER_DIR)
      Dir.mkdir(FINGERPRINTS_DIR) unless File.directory?(FINGERPRINTS_DIR)
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

    # Takes 'minor' or 'major' and returns its integer representation.
    def mode_lookup(mode)
      MODES.index(mode.downcase)
    end

    # Takes a chromatic key (eg: G#) and returns its integer representation.
    def key_lookup(key_letter)
      CHROMATIC_SCALE.index(key_letter.upcase)
    end

    # Takes an integer and returns its standard (chromatic) representation.
    def key_letter(key)
      CHROMATIC_SCALE[key]
    end
  end
end


MrEko.setup!

require "lib/mr_eko/core"
require "lib/mr_eko/presets"
require "lib/mr_eko/playlist"
require "lib/mr_eko/song"
