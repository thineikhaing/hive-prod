class CreateSgMrtStations < ActiveRecord::Migration[5.1]
  def change
    create_table :sg_mrt_stations do |t|
      t.string :type
      t.string :code
      t.string :name
      t.float :latitude
      t.float :longitude

      t.timestamps
    end
  end
end
