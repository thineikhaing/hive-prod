class CreateUserFavBuses < ActiveRecord::Migration[5.1]
  def change
    create_table :user_fav_buses do |t|
      t.integer :user_id
      t.string :service
      t.string :busid

      t.timestamps
    end
  end
end
