class AddPlaylists < Sequel::Migration
  def up
    create_table(:playlists) do
      primary_key :id
      String :name
      DateTime :created_on
      DateTime :updated_on
      
      index :name, :unique => true
    end
  end
  
  def down
    drop_table :playlists
  end
end