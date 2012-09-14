Sequel.migration do
  up do
    alter_table(:playlists_songs) do
      add_column :position, Integer
    end

    rename_table :playlists_songs, :playlist_entries
  end

  down do
    alter_table(:playlists_songs) do
      drop_column :position
    end
    rename_table :playlist_entries, :playlists_songs
  end
end
