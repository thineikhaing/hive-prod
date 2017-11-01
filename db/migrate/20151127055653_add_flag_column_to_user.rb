class AddFlagColumnToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :daily_points, :integer , default:10
  end
end
