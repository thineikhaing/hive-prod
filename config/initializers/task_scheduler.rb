require 'rubygems'
require 'rufus/scheduler'
scheduler = Rufus::Scheduler.new



scheduler.cron '05 00 * * mon' do
  CarActionLog.delete_all
  SgAccidentHistory.delete_all

  ActiveRecord::Base.connection.execute("TRUNCATE TABLE car_action_logs
 RESTART IDENTITY")

  ActiveRecord::Base.connection.execute("TRUNCATE TABLE sg_accident_histories
 RESTART IDENTITY")

  ActiveRecord::Base.connection.execute("TRUNCATE TABLE sg_mrt_stations
 RESTART IDENTITY")

 # ActiveRecord::Base.connection.execute("TRUNCATE TABLE topics RESTART IDENTITY")

 vh_query = "Vehicle breakdown"
 ac_query = "Accident"
 ht_query = "Heavy traffic"
 acc_topics = Topic.where("title LIKE ? or title LIKE ? or title LIKE ?", "%#{vh_query}%", "%#{ac_query}%", "%#{ht_query}%",)
 acc_topics.each do |t|
   if t.posts.count == 0
     p "delete"
     p t.delete
   end
 end

end


scheduler.cron '05 00 * * *' do
  p "update user daily points"
  users = User.all
  users.each do |user|
    user.daily_points = 10
    user.save
  end

  p "flash topic if there is no post within 24 hrs"

  # Topic.where(created_at: 24.hours.ago..Time.now,topic_type: 10)

  topics = Topic.where('updated_at > ? and topic_type = ?', 24.hours.ago,10)
  if topics.present?
    topics.each do |topic|
      if topic.posts.present?
        p "keep this topic"
      else
        topic.delete
      end
    end
  end

end

# scheduler.every 5.minutes do
#  p "check accident!"
#  SgAccidentHistory.get_incident_and_breakdown
# end


# command out


#scheduler.every  :monday do # Use any day of the week or :weekend, :weekday
#  CarActionLog.delete_all
#end


# scheduler.every 2.minutes do
#   p "UAT remote test!"
#   SgAccidentHistory.test_ygn_device_remotenoti
# end

# scheduler.every 15.minutes do
#   ActiveRecord::Base.connection.execute("TRUNCATE TABLE taxi_availabilities
#  RESTART IDENTITY")
#
#   TaxiAvailability.fetch_nearby_taxi
# end

#scheduler.every '2s' do
#  puts 'check blood pressure'
#end
