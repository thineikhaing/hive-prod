class CreateTaxiAvailabilities < ActiveRecord::Migration[5.1]
  def change
    create_table :taxi_availabilities do |t|
      t.float :latitude
      t.float :longitude
      t.datetime :date_time

      t.timestamps null: false
    end
  end
end
