class AddImgUrlToUserFavLocation < ActiveRecord::Migration[5.0]
  def change
    add_column :user_fav_locations, :img_url, :string
  end
end
