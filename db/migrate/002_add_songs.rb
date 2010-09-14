class AddSongs < Sequel::Migration
  def up
    create_table(:songs) do
      primary_key :id
      String :md5, :length => 32
      String :filename
      String :artist, :length => 100
      String :album
      String :title
      Float :duration
      Float :loudness
      Float :fade_out
      Float :fade_in
      Float :tempo
      Integer :time_signature, :length => 1
      Integer :key, :length => 2
      Integer :mode, :length => 1
      DateTime :created_on
      DateTime :updated_on
    
      index :md5, :unique => true
    end
    
    create_table :playlists_songs do
      Integer :playlist_id
      Integer :song_id
      
      index [:playlist_id, :song_id], :unique => true
    end
  end
  
  def down
    drop_table :songs
    drop_table :playlists_songs
  end
end