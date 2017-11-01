class CreateSgBusRoutes < ActiveRecord::Migration[5.1]
  def change
    create_table :sg_bus_routes do |t|
      t.string :service_no
      t.string :operator
      t.integer :direction
      t.integer :stop_sequence
      t.string :bus_stop_code
      t.float :distance
      t.string :wd_firstbus
      t.string :wd_lastbus
      t.string :sat_firstbus
      t.string :sat_lastbus
      t.string :sun_firstbus
      t.string :sun_lastbus

      t.timestamps
    end


  end
end
