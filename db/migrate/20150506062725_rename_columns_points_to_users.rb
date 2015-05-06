class RenameColumnsPointsToUsers < ActiveRecord::Migration
  def change
    rename_column :users, :point, :points
  end
end
