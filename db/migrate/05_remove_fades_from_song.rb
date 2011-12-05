class AddCodeToSongs < Sequel::Migration
  def up
    alter_table(:songs) do
      drop_column :fade_in
      drop_column :fade_out
    end
  end

  def down
    alter_table(:songs) do
      add_column :fade_in, Float
      add_column :fade_out, Float
    end
  end
end
