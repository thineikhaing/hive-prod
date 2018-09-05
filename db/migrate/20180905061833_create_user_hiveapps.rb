class CreateUserHiveapps < ActiveRecord::Migration[5.1]
  def change
    create_table :user_hiveapps do |t|
      t.integer :user_id
      t.integer :hive_application_id

      t.timestamps
    end
  end
end
