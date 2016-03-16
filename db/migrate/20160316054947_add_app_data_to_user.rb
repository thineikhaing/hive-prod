class AddAppDataToUser < ActiveRecord::Migration
  def up
    add_column :users, :app_data, :hstore
  end

  def down
    remove_column :users, :app_data, :hstore
  end
end
