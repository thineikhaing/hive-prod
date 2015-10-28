class AddSocalIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :socal_id, :integer
  end
end
