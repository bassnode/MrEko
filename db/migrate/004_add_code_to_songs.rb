Sequel.migration do
  up do
    alter_table(:songs) do
      add_column :code, String, :text => true
    end
  end

  down do
    alter_table(:songs) do
      drop_column :code
    end
  end
end
