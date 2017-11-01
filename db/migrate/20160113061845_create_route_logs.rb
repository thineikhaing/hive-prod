class CreateRouteLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :route_logs do |t|
      t.integer :user_id
      t.string :start_address
      t.string :end_address
      t.float :start_latitude
      t.float :start_longitude
      t.float :end_latitude
      t.float :end_longitude
      t.time :start_time
      t.time :end_time
      t.string :transport_type

      t.timestamps null: false
    end
  end
end
