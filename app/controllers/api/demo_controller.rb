class Api::DemoController < ApplicationController

  def test
    User.create(email: "ximen@example.com", password: "password", username: "Xi Men Chui Xue", data: {nickname: "East Door Blow Snow", ranked: 1, role: "Force Beater" })
    #User.create(username: "hj", email: "hj@example.com", password: "password")
    render json: "Hi"
  end

  def test2
    users = User.all
    users.each do |u|
      if u.data.present?
        p "data present"
        if u.data.has_key?("role") == true
          data_hash = u.data.except("role")
          p "data hash"
          p data_hash
          u.data = data_hash
          u.save!
        end
      end
    end
    render json: "test2"
  end

  def test3
    User.all.each do |u|
      if u.data.present?
        if u.data.has_key?("role") == false
          data_hash = u.data
          data_hash[:role] = "Noob"
          u.data = data_hash
          u.data_will_change!
          u.save!
        end
      else
        u.data = { role: "Noob" }
        u.save!
      end
    end
    render json: "test3"
  end

  def test4
    p User::BOT
    render json: {random_code: SecureRandom.urlsafe_base64}
  end

end
