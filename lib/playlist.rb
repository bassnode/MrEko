class Eko::Playlist < Sequel::Model
  plugin :validation_helpers
  many_to_many :songs
end

Eko::Playlist.plugin :timestamps