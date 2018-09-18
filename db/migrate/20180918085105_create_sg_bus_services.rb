class CreateSgBusServices < ActiveRecord::Migration[5.1]
  def change
    create_table :sg_bus_services do |t|
      t.string :service_no
      t.string :operator
      t.integer :direction
      t.string :category
      t.string :origin_code
      t.string :destination_code
      t.string :am_peak_freq
      t.string :am_offpeak_freq
      t.string :pm_peak_freq
      t.string :pm_offpeak_freq
      t.string :loop_desc
      t.timestamps
    end
  end
end
