class AddHiveApplicationIdToUserAccount < ActiveRecord::Migration
  def change
    add_column :user_accounts, :hiveapplication_id, :integer
  end
end
