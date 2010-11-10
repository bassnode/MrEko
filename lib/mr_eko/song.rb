class MrEko::Song < Sequel::Model
  plugin :validation_helpers
  many_to_many :playlists
  MODES = %w(minor major)
  CHROMATIC_SCALE = %w(C C# D D# E F F# G G# A A# B).freeze

  def self.enmfp_data(filename)
    json = JSON.parse(`#{File.join(MrEko::HOME_DIR, 'ext', 'enmfp', enmfp_binary)} #{File.expand_path(filename)}`).first
    puts json
    Hashie::Mash.new(json)
  end
  
  # Use the platform-specific binary.
  def self.enmfp_binary
    case RUBY_PLATFORM
    when /darwin/
      'codegen.Darwin'
    when /686/
      'codegen.Linux-i686'
    when /x86/
      'codegen.Linux-x86_64'
    else
      'codegen.windows.exe'
    end
  end

  def self.create_from_file!(filename)
    md5 = MrEko.md5(filename)
    existing = where(:md5 => md5).first
    return existing unless existing.nil?
    
    code = enmfp_data(filename)

    if code.keys.include?('error') || !code.songs
      analysis = MrEko.nest.track.analysis(filename)
      profile  = MrEko.nest.track.profile(:md5 => md5).body.track
    else
      puts "!!USING CALCULATED HASH CODE!!:"
      profile = MrEko.nest.song.identify(:code => code.code).songs.first
      analysis = MrEko.nest.song.profile(:id => profile.id, :bucket => 'audio_summary').songs.first.audio_summary
    end
    
    # require "ruby-debug"; debugger

    # TODO: add ruby-mp3info as fallback for parsing ID3 tags
    # since Echonest seems a bit flaky in that dept.
    song                = new()
    song.filename       = File.expand_path(filename)
    song.md5            = md5
    song.code           = code.code
    song.tempo          = analysis.tempo
    song.duration       = analysis.duration
    song.fade_in        = analysis.end_of_fade_in
    song.fade_out       = analysis.start_of_fade_out
    song.key            = analysis.key
    song.mode           = analysis.mode
    song.loudness       = analysis.loudness
    song.time_signature = analysis.time_signature
    song.echonest_id    = profile.id
    song.bitrate        = profile.bitrate
    song.title          = profile.title
    song.artist         = profile.artist || profile.artist_name
    song.album          = profile.release
    song.danceability   = profile.audio_summary.danceability || analysis.danceability
    song.energy         = profile.audio_summary.energy || analysis.energy

    song.save
  end
  
  # Takes 'minor' or 'major' and returns its integer representation.
  def self.mode_lookup(mode)
    MODES.index(mode)
  end

  # Takes a chromatic key (eg: G#) and returns its integer representation.  
  def self.key_lookup(key_letter)
    CHROMATIC_SCALE.index(key_letter)
  end
  
  # Takes an integer and returns its standard (chromatic) representation.
  def key_letter
    CHROMATIC_SCALE[key]
  end
  
  def validate
    super
    set_md5 # no Sequel callback for this?
    validates_unique :md5
  end
  
  private
  def set_md5
    self.md5 ||= MrEko.md5(filename)
  end
  
end

MrEko::Song.plugin :timestamps
