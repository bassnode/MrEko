class MrEko::PlaylistEntry < Sequel::Model
  many_to_one :playlists
  many_to_one :songs
end
