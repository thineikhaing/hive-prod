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
    User.create(email: "favrbot@raydiusapp.com", password: "p@ssw0rd!", password_confirmation: "p@ssw0rd!", username: "FavrBot", role: 1)
    User.create(email: "info@juiceapp.com", password: "password!123", password_confirmation: "password!123", username: "JuiceAppBoard", role: 1)

    api_key = SecureRandom.hex
    HiveApplication.create(devuser_id: 1, app_name: "Hive",app_type: "social",description: "a way to connect nearby people (with each other, and with businesses) anonymously",api_key: api_key )

    api_key = SecureRandom.hex
    HiveApplication.create(devuser_id: 1, app_name: "MealBox",app_type: "food",description: "Mealbox",api_key: api_key )

    api_key = SecureRandom.hex
    carmmic_app = HiveApplication.create(devuser_id: 1, app_name: "Carmmunicate",app_type: "social",description: "Carmmunicate",api_key: api_key )

    api_key = SecureRandom.hex
    socal_app = HiveApplication.create(devuser_id: 1, app_name: "Socal",app_type: "social",description: "Socal",api_key: api_key )

    api_key = SecureRandom.hex
    HiveApplication.create(devuser_id: 1, app_name: "Favr",app_type: "social",description: "Favr",api_key: api_key )

    hive_app = HiveApplication.find_by_app_name('Favr')
    AppAdditionalField.create(app_id: hive_app.id,table_name: "User", additional_column_name: "device_id")


    if carmmic_app.present?
      AppAdditionalField.create(app_id: carmmic_app.id,table_name: "User", additional_column_name: "color")
      AppAdditionalField.create(app_id: carmmic_app.id,table_name: "User", additional_column_name: "plate_number")
      AppAdditionalField.create(app_id: carmmic_app.id,table_name: "User", additional_column_name: "transport_mode")
      AppAdditionalField.create(app_id: carmmic_app.id,table_name: "User", additional_column_name: "speed")
      AppAdditionalField.create(app_id: carmmic_app.id,table_name: "User", additional_column_name: "activity")
      AppAdditionalField.create(app_id: carmmic_app.id,table_name: "User", additional_column_name: "direction")
      AppAdditionalField.create(app_id: carmmic_app.id,table_name: "User", additional_column_name: "device_id")
      AppAdditionalField.create(app_id: carmmic_app.id,table_name: "User", additional_column_name: "heartrate")


      AppAdditionalField.create(app_id: carmmic_app.id,table_name: "Topic", additional_column_name: "color")
      AppAdditionalField.create(app_id: carmmic_app.id,table_name: "Topic", additional_column_name: "plate_number")

      AppAdditionalField.create(app_id: carmmic_app.id,table_name: "Post", additional_column_name: "color")
      AppAdditionalField.create(app_id: carmmic_app.id,table_name: "Post", additional_column_name: "plate_number")
    end

    if socal_app.present?

      AppAdditionalField.create(app_id: socal_app.id,table_name: "Topic", additional_column_name: "content")
      AppAdditionalField.create(app_id: socal_app.id,table_name: "Topic", additional_column_name: "place_name")
      AppAdditionalField.create(app_id: socal_app.id,table_name: "Topic", additional_column_name: "address")
      AppAdditionalField.create(app_id: socal_app.id,table_name: "Topic", additional_column_name: "latitude")
      AppAdditionalField.create(app_id: socal_app.id,table_name: "Topic", additional_column_name: "longitude")
      AppAdditionalField.create(app_id: socal_app.id,table_name: "Topic", additional_column_name: "confirm_state")
      AppAdditionalField.create(app_id: socal_app.id,table_name: "Topic", additional_column_name: "confirmed_date")
      AppAdditionalField.create(app_id: socal_app.id,table_name: "Topic", additional_column_name: "invitation_code")

    end



    CSV.foreach("db/migrate/20140328083723_stations_seed.csv") do |row|
      Place.create(name: row[0], latitude: row[1], longitude: row[2], address: row[3], locality: row[4], country: row[5], img_url: row[6], user_id: admin.id, source: 0)
      puts "Created: #{row}"
    end
  end
end
