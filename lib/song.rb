class Eko::Song < Sequel::Model
  plugin :validation_helpers
  many_to_many :playlists
  
  def self.analyze(filename)
    analysis = Eko.nest.track.analysis(filename)
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
