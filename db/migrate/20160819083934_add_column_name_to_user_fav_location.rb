class AddColumnNameToUserFavLocation < ActiveRecord::Migration[5.0]
  def up
    add_column :user_fav_locations, :name, :string
  end

  def down
    remove_column :user_fav_locations, :name, :string
  end
end
