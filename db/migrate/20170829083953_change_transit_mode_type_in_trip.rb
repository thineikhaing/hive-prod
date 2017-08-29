class ChangeTransitModeTypeInTrip < ActiveRecord::Migration[5.0]
  def change
    change_column :trips, :transit_mode, :string
  end
end
