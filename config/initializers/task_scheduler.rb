require 'rubygems'
require 'rufus/scheduler'
scheduler = Rufus::Scheduler.new

#scheduler.every  :monday do # Use any day of the week or :weekend, :weekday
#  CarActionLog.delete_all
#end

scheduler.cron "00 09 * * mon" do
  CarActionLog.delete_all
end

scheduler.in '7d' do
  CarActionLog.delete_all
end

#scheduler.every '3s' do
#  puts 'Hello... Rufus'
#  CarActionLog.delete_all
#end
#
#scheduler.every '2s' do
#  puts 'check blood pressure'
#end
#
