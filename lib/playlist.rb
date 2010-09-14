class Eko::Playlist < Sequel::Model
  plugin :validation_helpers
  many_to_many :songs
  
  def self.create_from_options(options)
    puts options.inspect
    
  end
end

Eko::Playlist.plugin :timestamps