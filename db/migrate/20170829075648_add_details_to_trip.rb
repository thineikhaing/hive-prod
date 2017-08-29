class AddDetailsToTrip < ActiveRecord::Migration[5.0]
  def change
    add_column :trips, :depart_latlng, :string
    add_column :trips, :arr_latlng, :string
    add_column :trips, :depature_name, :string
    add_column :trips, :arrival_name, :string
  end
end
