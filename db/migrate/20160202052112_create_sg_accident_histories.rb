class CreateSgAccidentHistories < ActiveRecord::Migration[5.1]
  def change
    create_table :sg_accident_histories do |t|
      t.string :type
      t.string :message
      t.datetime :accident_datetime
      t.float :latitude
      t.float :longitude
      t.text :summary
      t.boolean :notify, default: false

      t.timestamps null: false
    end
  end
end
