class CreateData < ActiveRecord::Migration
  def change
    Devuser.create(email: "info@raydiusapp.com", password: "p@ssw0rd!", password_confirmation: "p@ssw0rd!", username: "Hive Admin", verified: true)
    User.create(email: "info@raydiusapp.com", password: "p@ssw0rd!", password_confirmation: "p@ssw0rd!", username: "Hive Admin", role: 1)
  end
end
