class RenameColumnsPointsToUsers < ActiveRecord::Migration[5.1]
  def change
    rename_column :users, :point, :points
  end
end
