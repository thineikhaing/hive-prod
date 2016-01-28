class CreateUserFavLocations < ActiveRecord::Migration
  def change
    create_table :user_fav_locations do |t|
      t.integer :user_id
      t.integer :place_id
      t.string :place_type

      t.timestamps null: false
    end
  end
end
