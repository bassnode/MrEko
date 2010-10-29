class AddUsefulSongFields < Sequel::Migration
  def up
    alter_table(:songs) do
      add_column :echonest_id, String
      add_column :danceability, Float    
      add_index :echonest_id
    end
  end
  
  def down
    alter_table(:songs) do
      drop_column :echonest_id
      drop_column :danceability
      drop_index :echonest_id
    end
  end
end