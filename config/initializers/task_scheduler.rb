require 'rubygems'
require 'rufus/scheduler'
scheduler = Rufus::Scheduler.new

#scheduler.every  :monday do # Use any day of the week or :weekend, :weekday
#  CarActionLog.delete_all
#end

scheduler.cron '05 00 * * mon' do
  CarActionLog.delete_all
  SgAccidentHistory.delete_all

  ActiveRecord::Base.connection.execute("TRUNCATE TABLE car_action_logs
 RESTART IDENTITY")

  ActiveRecord::Base.connection.execute("TRUNCATE TABLE sg_accident_histories
 RESTART IDENTITY")
end

scheduler.cron '05 00 * * *' do
  p "update user daily points"
  users = User.all
  users.each do |user|
    user.daily_points = 10
    user.save
  end
end

scheduler.every 3.minutes do
 p "check accident!"
 SgAccidentHistory.get_incident_and_breakdown
end


# scheduler.every 15.minutes do
#   ActiveRecord::Base.connection.execute("TRUNCATE TABLE taxi_availabilities
#  RESTART IDENTITY")
#
#   TaxiAvailability.fetch_nearby_taxi
# end

#scheduler.every '2s' do
#  puts 'check blood pressure'
#end