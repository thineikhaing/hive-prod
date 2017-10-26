class ChangecolumnBusIdToString < ActiveRecord::Migration[5.1]
  def up
    change_column :sg_bus_stops, :bus_id, :string
  end

  def down
    change_column :sg_bus_stops, :bus_id, :string
  end
end
