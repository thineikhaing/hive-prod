class CreateTrips < ActiveRecord::Migration[5.0]
  def change
    create_table :trips do |t|
      t.references :user
      t.integer :start_place_id
      t.integer :end_place_id
      t.integer :transit_mode
      t.datetime :depature_time
      t.datetime :arrival_time
      t.float :distance
      t.float :fare
      t.hstore :data
      t.timestamps
    end
  end
end
