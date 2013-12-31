Sequel.migration do
  up do
    create_table(:api_logs) do
      primary_key :id
      DateTime :created_on

      index :created_on
    end

  end

  down do
    drop_table :api_logs
  end
end
