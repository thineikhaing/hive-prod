require 'rubygems'
require 'rufus/scheduler'
scheduler = Rufus::Scheduler.new

#scheduler.every  :monday do # Use any day of the week or :weekend, :weekday
#  CarActionLog.delete_all
#end
scheduler.in '7d' do
  # whatever...
  CarActionLog.delete_all
end

#scheduler.cron("5 0 * * *") do
#  CarActionLog.delete_all
#end

#scheduler.every '3s' do
# User.update_latlng
#end
