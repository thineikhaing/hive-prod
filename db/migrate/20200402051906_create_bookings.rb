class CreateBookings < ActiveRecord::Migration[5.2]
  def change
    create_table :bookings do |t|
      t.integer :user_id
      t.integer :place_id
      t.datetime :booking_date
      t.time :checkin_time
      t.time :checkout_time
      t.integer :status, default: 0, null: false
      t.string :description

      t.timestamps
    end
  end
end
