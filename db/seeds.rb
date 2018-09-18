# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

User.create(email: "info@juiceapp.com", password: "password!123", password_confirmation: "password!123", username: "JuiceAppBoard", role: 1)

ActiveRecord::Base.connection.execute("TRUNCATE TABLE sg_mrt_stations RESTART IDENTITY")

CSV.foreach("db/mrt_stations/ns_seeds.csv") do |row|
  NS.create(code: row[0],name: row[1], latitude: row[2], longitude: row[3])
  puts "Created: #{row}"
end

CSV.foreach("db/mrt_stations/ew_seeds.csv") do |row|
  EW.create(code: row[0],name: row[1], latitude: row[2], longitude: row[3])
  puts "Created: #{row}"
end

CSV.foreach("db/mrt_stations/ne_seeds.csv") do |row|
  NE.create(code: row[0],name: row[1], latitude: row[2], longitude: row[3])
  puts "Created: #{row}"
end

CSV.foreach("db/mrt_stations/cc_seeds.csv") do |row|
  CC.create(code: row[0],name: row[1], latitude: row[2], longitude: row[3])
  puts "Created: #{row}"
end

CSV.foreach("db/mrt_stations/se_seeds.csv") do |row|
  SE.create(code: row[0],name: row[1], latitude: row[2], longitude: row[3])
  puts "Created: #{row}"
end

CSV.foreach("db/mrt_stations/dt_seeds.csv") do |row|
  DT.create(code: row[0],name: row[1], latitude: row[2], longitude: row[3])
  puts "Created: #{row}"
end
