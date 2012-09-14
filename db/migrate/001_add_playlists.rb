Sequel.migration do
  up do
    create_table(:playlists) do
      primary_key :id
      String :name
      DateTime :created_on
      DateTime :updated_on

      index :name, :unique => true
    end
  end

  down do
    drop_table :playlists
  end
end
