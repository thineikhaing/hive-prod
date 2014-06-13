class CreatePlaces < ActiveRecord::Migration
  def change
    create_table :places do |t|
      t.string :name
      t.string :category
      t.string :address
      t.string :locality
      t.string :region
      t.string :neighbourhood
      t.string :country
      t.string :postal_code
      t.string :website_url
      t.string :chain_name
      t.string :contact_number
      t.string :img_url
      t.string :source
      t.integer :source_id
      t.integer :user_id
      t.hstore :data

      t.float :latitude
      t.float :longitude

      t.timestamps
    end
  end
end
