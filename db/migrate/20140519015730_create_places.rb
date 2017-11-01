class CreatePlaces < ActiveRecord::Migration[5.1]
  def change
    create_table :places do |t|
      t.string :name
      t.string :category, default: ""
      t.string :address, null: false, default: ""
      t.string :locality, default: ""
      t.string :region , default: ""
      t.string :neighbourhood , default: ""
      t.string :country, default: ""
      t.string :postal_code, default: ""
      t.string :website_url, default: ""
      t.string :chain_name , default: ""
      t.string :contact_number, default: ""
      t.string :img_url
      t.string :source, default: ""
      t.integer :source_id , default: 0
      t.integer :user_id
      t.hstore :data

      t.float :latitude, null: false, default: 0
      t.float :longitude, null: false, default: 0
      t.timestamps
    end
  end
end
