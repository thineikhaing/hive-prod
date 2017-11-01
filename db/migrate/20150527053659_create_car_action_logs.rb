class CreateCarActionLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :car_action_logs do |t|
      t.integer :user_id
      t.integer :speed
      t.integer :direction
      t.float :latitude
      t.float :longitude
      t.string :activity
      t.string :heartrate

      t.timestamps
    end
  end
end
