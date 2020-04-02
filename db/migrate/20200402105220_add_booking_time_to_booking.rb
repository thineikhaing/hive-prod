class AddBookingTimeToBooking < ActiveRecord::Migration[6.0]
  def change
    add_column :bookings, :booking_time, :time
  end
end
