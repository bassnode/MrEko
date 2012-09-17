require "rubygems"
require "bundler"

require "sqlite3"
require "sequel"
require 'sequel/extensions/migration'
require "logger"
require "hashie"
require "digest/md5"
require 'id3lib'
require "echonest"
begin
  require 'ruby-debug'
rescue LoadError
end

STDOUT.sync = true

EKO_ENV = ENV['EKO_ENV'] || 'development'
Sequel.default_timezone = :utc

module MrEko
  VERSION = '0.5.2'
  USER_DIR = File.join(ENV['HOME'], ".mreko")
  FINGERPRINTS_DIR = File.join(USER_DIR, 'fingerprints')
  LOG_DIR = File.join(USER_DIR, 'logs')
  HOME_DIR = File.join(File.dirname(__FILE__), '..')

  MODES = %w(minor major).freeze
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
      setup_directories!
      setup_logger!
      setup_db!
      setup_echonest!
    end

    # Output to STDOUT in debug, otherwise, save to logfile
    def setup_logger!
      out = ENV['DEBUG'] ? STDOUT : File.join(LOG_DIR, "#{env}.log")
      @logger ||= Logger.new(out)
    end

    def setup_directories!
      Dir.mkdir(USER_DIR) unless File.directory?(USER_DIR)
      Dir.mkdir(FINGERPRINTS_DIR) unless File.directory?(FINGERPRINTS_DIR)
      Dir.mkdir(LOG_DIR) unless File.directory?(LOG_DIR)
    end

    def setup_db!
      return @connection if @connection
      @connection = Sequel.sqlite(db_name)
      @connection.loggers << @logger

      File.unlink(MrEko.db_name) if File.exist?(MrEko.db_name) && env == 'test'
      Sequel::Migrator.apply(MrEko.connection, File.join(File.dirname(__FILE__), "..", "db", "migrate"))
    end

    def setup_echonest!
      @nest ||= Echonest(File.read(api_key))
    end

    def db_name
      env == 'test' ? File.join('db', 'eko_test.db') : File.join(USER_DIR, 'eko.db')
    end

    def api_key
      [File.join(USER_DIR, 'echonest_api.key'), File.join(HOME_DIR, 'echonest_api.key')].each do |file|
        return file if File.exists?(file)
      end
      raise "You need to create an echonest_api.key file in #{USER_DIR}"
    end

    # Takes 'minor' or 'major' and returns its integer representation.
    def mode_lookup(mode)
      MODES.index(mode.to_s.downcase)
    end

    # Takes a chromatic key (eg: G#) and returns its integer representation.
    def key_lookup(key_letter)
      CHROMATIC_SCALE.index(key_letter.upcase)
    end

    # Takes an integer and returns its standard (chromatic) representation.
    def key_letter(key)
      CHROMATIC_SCALE[key]
    end

    # Use the platform-specific binary.
    def enmfp_binary
      bin = case ruby_platform
      when /darwin/
        'codegen.Darwin'
      when /686/
        'codegen.Linux-i686'
      when /x86/
        'codegen.Linux-x86_64'
      else
        'codegen.windows.exe'
      end

      File.join(HOME_DIR, 'ext', 'enmfp', bin)
    end

    def ruby_platform
      RUBY_PLATFORM
    end

  end
end


MrEko.setup!

Dir.glob('lib/mr_eko/ext/*.rb').each do |f|
  require f
end
require "mr_eko/exceptions"
require "mr_eko/core"
require "mr_eko/presets"
require "mr_eko/playlist"
require "mr_eko/timed_playlist"
require "mr_eko/song"
require "mr_eko/playlist_entry"
