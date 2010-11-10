class AddCodeToSongs < Sequel::Migration
  def up
    alter_table(:songs) do
      add_column :code, String, :text => true
    end
  end
  
  def down
    alter_table(:songs) do
      drop_column :code
    end
  end
end