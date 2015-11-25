class AddFlagColumnToUser < ActiveRecord::Migration
  def change
    add_column :users, :daily_points, :integer , default:10
  end
end
