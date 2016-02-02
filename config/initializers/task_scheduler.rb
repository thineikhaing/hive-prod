require 'rubygems'
require 'rufus/scheduler'
scheduler = Rufus::Scheduler.new

#scheduler.every  :monday do # Use any day of the week or :weekend, :weekday
#  CarActionLog.delete_all
#end

scheduler.cron '05 00 * * mon' do
  CarActionLog.delete_all
end

scheduler.cron '05 00 * * *' do
  p "update user daily points"
  users = User.all
  users.each do |user|
    user.daily_points = 10
    user.save
  end
end

scheduler.every 2.minutes do

  p "check accident!"
  SgAccidentHistory.get_incident_and_breakdown

end



#scheduler.every '2s' do
#  puts 'check blood pressure'
#end

