class Createdata < ActiveRecord::Migration
  require 'securerandom'  #to generate api key for application
  def change
    Devuser.create(email: "info@raydiusapp.com", password: "p@ssw0rd!", password_confirmation: "p@ssw0rd!", username: "Hive Admin", verified: true)
    admin = User.create(email: "info@raydiusapp.com", password: "p@ssw0rd!", password_confirmation: "p@ssw0rd!", username: "Hive Admin", role: 1)
    User.create(email: "khinephyuphyu@rs-v.com", password: "p@ssw0rd!", password_confirmation: "p@ssw0rd!", username: "Lee Min Ho's Wife", role: 1)
    User.create(email: "hninhtet@rs-v.com", password: "p@ssw0rd!", password_confirmation: "p@ssw0rd!", username: "Hyomin's Admirer", role: 1)
    User.create(email: "kale@rs-v.com", password: "p@ssw0rd!", password_confirmation: "p@ssw0rd!", username: "Do you want to build a Snowman?", role: 1)
    User.create(email: "hj@rs-v.com", password: "p@ssw0rd!", password_confirmation: "p@ssw0rd!", username: "Seungyeon's Husband", role: 1)
    User.create(email: "admin1@rs-v.com", password: "p@ssw0rd!", password_confirmation: "p@ssw0rd!", username: "Admin Puppy", role: 1)
    User.create(email: "admin2@rs-v.com", password: "p@ssw0rd!", password_confirmation: "p@ssw0rd!", username: "Admin Kitty", role: 1)
    User.create(email: "admin3@rs-v.com", password: "p@ssw0rd!", password_confirmation: "p@ssw0rd!", username: "Admin Penguin", role: 1)
    User.create(email: "admin4@rs-v.com", password: "p@ssw0rd!", password_confirmation: "p@ssw0rd!", username: "Admin Piggy", role: 1)
    User.create(email: "admin5@rs-v.com", password: "p@ssw0rd!", password_confirmation: "p@ssw0rd!", username: "Admin Bear", role: 1)
    User.create(email: "admin6@rs-v.com", password: "p@ssw0rd!", password_confirmation: "p@ssw0rd!", username: "Admin Panda", role: 1)

    api_key = SecureRandom.hex
    HiveApplication.create(devuser_id: 1, app_name: "Hive",app_type: "social",description: "a way to connect nearby people (with each other, and with businesses) anonymously",api_key: api_key )
    api_key = SecureRandom.hex
    HiveApplication.create(devuser_id: 1, app_name: "MealBox",app_type: "food",description: "Mealbox",api_key: api_key )
    api_key = SecureRandom.hex
    app = HiveApplication.create(devuser_id: 1, app_name: "Carmmunicate",app_type: "social",description: "Carmmunicate",api_key: api_key )
    if app.present?
      AppAdditionalField.create(app_id: app.id,table_name: "User", additional_column_name: "color")
      AppAdditionalField.create(app_id: app.id,table_name: "User", additional_column_name: "plate_number")
      AppAdditionalField.create(app_id: app.id,table_name: "User", additional_column_name: "transport_mode")
      AppAdditionalField.create(app_id: app.id,table_name: "User", additional_column_name: "speed")
      AppAdditionalField.create(app_id: app.id,table_name: "User", additional_column_name: "activity")
      AppAdditionalField.create(app_id: app.id,table_name: "User", additional_column_name: "direction")
    end

    CSV.foreach("db/migrate/20140328083723_stations_seed.csv") do |row|
      Place.create(name: row[0], latitude: row[1], longitude: row[2], address: row[3], locality: row[4], country: row[5], img_url: row[6], user_id: admin.id, source: 0)
      puts "Created: #{row}"
    end
  end
end