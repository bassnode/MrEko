class MrEko::Song < Sequel::Model
  plugin :validation_helpers
  many_to_many :playlists
  MODES = %w(minor major)
  CHROMATIC_SCALE = %w(C C# D D# E F F# G G# A A# B).freeze
  
  def self.create_from_file!(filename)
    analysis = MrEko.nest.track.analysis(filename)
    md5 = MrEko.md5(filename)
    profile  = MrEko.nest.track.profile(:md5 => md5)

    song                = new()
    song.filename       = File.expand_path(filename)
    song.md5            = md5
    song.tempo          = analysis.tempo
    song.duration       = analysis.duration
    song.fade_in        = analysis.end_of_fade_in
    song.fade_out       = analysis.start_of_fade_out
    song.key            = analysis.key
    song.mode           = analysis.mode
    song.loudness       = analysis.loudness
    song.time_signature = analysis.time_signature
    song.title          = profile.body.title
    song.artist         = profile.body.artist
    song.album          = profile.body.release

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
