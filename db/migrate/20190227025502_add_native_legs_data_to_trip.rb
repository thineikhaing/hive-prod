class AddNativeLegsDataToTrip < ActiveRecord::Migration[5.2]
  def change
    add_column :trips, :start_addr, :string
    add_column :trips, :end_addr, :string
    add_column :trips, :currency, :string
    add_column :trips, :native_legs, :hstore
  end
end
