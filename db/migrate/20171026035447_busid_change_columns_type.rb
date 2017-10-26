class BusidChangeColumnsType < ActiveRecord::Migration[5.1]
  def change
    change_column(:sg_bus_stops, :bus_id, :string)
  end
end
