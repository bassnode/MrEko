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
  
  def self.key_lookup(key_letter)
    CHROMATIC_SCALE.index(key_letter)
  end
  
  def self.mode_lookup(mode)
    MODES.index(mode)
  end
  
  def key_letter
    CHROMATIC_SCALE[key]
  end
  
  
  def validate
    super
    set_md5 # no callback for this?
    validates_unique :md5
  end
  
  private
  def set_md5
    self.md5 ||= Eko.md5(filename)
  end
  
end

Eko::Song.plugin :timestamps
