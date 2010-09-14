class Eko::Song < Sequel::Model
  plugin :validation_helpers
  many_to_many :playlists
  
  def self.create_from_file!(filename)
    #analysis = Eko.nest.track.analysis(filename)
    puts "DOING Echonest ANALYSIS..."
    create(:filename => filename)
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
