class AddAddressToUserFavLocation < ActiveRecord::Migration[5.2]
  def change
    add_column :user_fav_locations, :address, :string
  end
end
