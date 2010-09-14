class Eko::Song < Sequel::Model
  plugin :validation_helpers
  many_to_many :playlists
  MODES = %w(minor major)
  CHROMATIC_SCALE = %w(C C# D D# E F F# G G# A A# B).freeze
  
  def self.create_from_file!(filename)
    #analysis = Eko.nest.track.analysis(filename)
    #profile = Eko.nest.track.profile(:id => analysis.id)
    puts "DOING Echonest ANALYSIS..."
    create(:filename => filename)
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
    self.md5 ||= Eko.md5(filename)
  end
  
end

Eko::Song.plugin :timestamps
