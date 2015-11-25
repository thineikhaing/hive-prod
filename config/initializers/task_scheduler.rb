require 'rubygems'
require 'rufus/scheduler'
scheduler = Rufus::Scheduler.new

#scheduler.every  :monday do # Use any day of the week or :weekend, :weekday
#  CarActionLog.delete_all
#end

scheduler.cron "00 09 * * mon" do
  CarActionLog.delete_all
end

scheduler.cron '5 0 * * *' do
  users = User.all
  users.each do |user|
    user.daily_points += 10
    user.save
  end
end

#scheduler.every '3s' do

#end


#
#scheduler.every '2s' do
#  puts 'check blood pressure'
#end
#
