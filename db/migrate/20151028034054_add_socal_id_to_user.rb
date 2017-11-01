class AddSocalIdToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :socal_id, :integer
  end
end
