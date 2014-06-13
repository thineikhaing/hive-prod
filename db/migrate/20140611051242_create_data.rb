class CreateData < ActiveRecord::Migration
  def change
    Devuser.create(email: "info@raydiusapp.com", password: "p@ssw0rd!", password_confirmation: "p@ssw0rd!", username: "Hive Admin", verified: true)
    admin = User.create(email: "info@raydiusapp.com", password: "p@ssw0rd!", password_confirmation: "p@ssw0rd!", username: "Hive Admin", role: 1)

    CSV.foreach("db/migrate/20140328083723_stations_seed.csv") do |row|
      Place.create(name: row[0], latitude: row[1], longitude: row[2], address: row[3], locality: row[4], country: row[5], img_url: row[6], user_id: admin.id, source: 0)
      puts "Created: #{row}"
    end
  end
end
