class CreateSgBusStops < ActiveRecord::Migration[5.0]
  def change
    create_table :sg_bus_stops do |t|
      t.integer :bus_id
      t.string :road_name
      t.string :description
      t.float :latitude
      t.float :longitude

      t.timestamps
    end
  end
end
