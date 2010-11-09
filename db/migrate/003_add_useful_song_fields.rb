class AddUsefulSongFields < Sequel::Migration
  def up
    alter_table(:songs) do
      add_column :echonest_id, String
      add_column :danceability, Float    
      add_column :energy, Float    
      add_column :bitrate, Integer, :size => 4
      add_index :echonest_id
    end
  end
  
  def down
    alter_table(:songs) do
      drop_column :echonest_id
      drop_column :danceability
      drop_column :energy
      drop_column :bitrate
    end
  end
end