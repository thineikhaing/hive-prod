require 'value_enums'

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :topics
  has_many :checkinplaces
  has_many :posts
  has_many :user_push_tokens
  has_many :user_accounts
  has_many :car_action_logs
  has_many :places
  has_many :trips
  has_many :user_fav_locations
  has_many :user_fav_buses
  has_many :user_friend_lists
  has_many :user_hiveapps
  belongs_to :incident_history

  # Setup hstore
  store_accessor :data
  include Authenticable

  # attr_accessible :username, :email, :password, :password_confirmation, :authentication_token, :avatar_url, :role,
  #                 :point, :flareMode, :alert_count, :paid_alert_count, :credits, :last_known_latitude, :last_known_longitude,
  #                 :check_in_time, :profanity_counter, :offence_date, :positive_honor, :negative_honor, :honored_times,
  #                 :created_at, :data, :device_id,:socal_id,:daily_points

  after_initialize :ensure_authentication_token
  after_initialize :ensure_username

  validates_uniqueness_of    :email, :case_sensitive => false, :allow_blank => true

  enums %w(BOT ADMIN VENDOR NORMAL)

  def self.sns_arn(device_type)

    platform_type = Rails.env == 'development' ? 'APNS_SANDBOX' : 'APNS'

    app_name =
    if Rails.env.development?
      app_name = "Roundtrip_D"
    elsif Rails.env.staging?
      app_name = "Roundtrip_S"
    else
      app_name = "Roundtrip"
    end
    platform_type = 'GCM' if device_type == 'Android'
    app_name = "Roundtrip_S" if device_type == 'Android'

    "arn:aws:sns:ap-southeast-1:378631322826:app/#{platform_type}/#{app_name}"
  end

  def self.generate_new_username
    prefix = %w(
      Angry Anxious Befuddled Bemused Bewildered Bored Bright-eyed Cheerful Cool Cranky Ecstatic Excited
      Grumpy Happy Hungry Jolly Laid-back Lolling Mellow Merry Mystified Paranoid Playful Sober Tipsy
    )

    suffix = %w(
      Aardvark Alligator Beaver Bear Butterfly Cat Chihuahua Chipmunk Corgi Elephant Eagle Giraffe
      Horse Husky Kangaroo Koala Llama Lion Monkey Panda Puppy Shiba Snorkie Swan Tiger Whale Penguin Duck
    )

    username = "#{prefix.sample} #{suffix.sample}"
    username = "#{prefix.sample} #{suffix.sample}" if User.find_by_username(username).present?
    username
  end

  def self.create_endpoint(device_type, device_token,user_id)
    user_endpoint_arn = nil
    begin
      p "Create end point at SNS"
      sns_client = Aws::SNS::Client.new
      endpoint = sns_client.create_platform_endpoint(
        platform_application_arn: User.sns_arn(device_type),
        token: device_token,
        custom_user_data: user_id.to_s
        )
        user_endpoint_arn = endpoint[:endpoint_arn]

    rescue => e
      p "exception"
      p e
      result = e.message.match(/Endpoint(.*)already/)
      if result.present?
        p "endpoint"
        p user_endpoint_arn = result[1].strip
        if !user_endpoint_arn.nil?

          sns_client = Aws::SNS::Client.new
          resp = sns_client.set_endpoint_attributes({
                  endpoint_arn: user_endpoint_arn, # required
                  attributes: { # required
                    "CustomUserData" => user_id.to_s,
                  },
          })
        end
      end
    end

    if !user_endpoint_arn.nil?
        User.subscribe_to_topic(user_endpoint_arn)
        user_token = UserPushToken.find_by(endpoint_arn:user_endpoint_arn)
        if user_token.present?
          user_token.update(user_id: user_id)
        else
          UserPushToken.create(user_id: user_id,endpoint_arn:user_endpoint_arn,push_token: device_token)
        end
    end

  end

  def self.subscribe_to_topic(endpoint_arn)
    p "subscribe_to_topic"
    topic_arn = Rails.env == 'production' ? "arn:aws:sns:ap-southeast-1:378631322826:Roundtrip_P_Broadcast_Noti" : "arn:aws:sns:ap-southeast-1:378631322826:Roundtrip_S_Broadcast_Noti"
    begin
       p "subscribe to roundtrip topic"
        sns_client = Aws::SNS::Client.new
        subscription = sns_client.subscribe(
          topic_arn: topic_arn,
          protocol: 'application',
          endpoint: endpoint_arn)
        subscription.subscription_arn
    rescue => e
      p 'Topic subscription failed.'
    end
  end

  def send_password_reset
    p generate_token(:reset_password_token)
    self.reset_password_sent_at = Time.zone.now
    p self.reset_password_token =  SecureRandom.urlsafe_base64
    save!
    UserMailer.carmic_password_reset(self).deliver
  end

  def send_password_reset_to_app
    # p generate_token(:reset_password_token)
    UserMailer.password_reset_to_app(self).deliver
  end

  def generate_token(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
  end

  def self.search_data(search)
    where("lower(username) = ?", "#{search.downcase}%")
  end


  def self.regenerate_auth_token_for_expiry_tokens
    users = User.where(:token_expiry_date => Date.today )
    users.each do |user|
      token = ""
      loop do
        token = Devise.friendly_token
        break token unless User.where(authentication_token: token).first
      end
      user.authentication_token =  token
      user.token_expiry_date = Date.today + 6.months
      user.save!
    end
  end


  def user_topic_retrival(choice)
    likes = ActionLog.where(type_name:"topic", action_type:"like", action_user_id:self.id)
    dislikes = ActionLog.where(type_name:"topic", action_type:"dislike", action_user_id:self.id)
    favourites = ActionLog.where(type_name:"topic", action_type:"favourite", action_user_id:self.id)
    offensives = ActionLog.where(type_name:"topic", action_type:"offensive", action_user_id:self.id)

    like_ids =[]
    dislike_ids = []
    favourite_ids = []
    offensive_ids = []

    likes.each do |l|
      like_ids.push(l.type_id)
    end

    dislikes.each do |dl|
      dislike_ids.push(dl.type_id)
    end

    favourites.each do |f|
      favourite_ids.push(f.type_id)
    end

    offensives.each do |o|
      offensive_ids.push(o.type_id)
    end

    if choice == "detail"
      like_topics = Topic.where(id: like_ids)
      dislike_topics = Topic.where(id: dislike_ids)
      favourite_topics = Topic.where(id:  favourite_ids)
      offensive_topics = Topic.where(id: offensive_ids)

      {likes: like_topics, dislikes: dislike_topics, favourites: favourite_topics, offensives: offensive_topics, point: self.point}
    else
      {likes: like_ids, dislikes: dislike_ids, favourites: favourite_ids, offensives: offensive_ids, point: self.point}
    end

  end

  def update_user_points
    data = {
        user_id: self.id,
        points: self.points
    }

    Pusher["favr_channel"].trigger  "update_user_points", data
  end


  def favourite_user(current_user, user_id, choice)

    if choice == "favourite"
      check = ActionLog.where(type_name: "user", type_id: user_id, action_type: "favourite", action_user_id: current_user.id)
      ActionLog.create(type_name: "user",type_id: user_id, action_type: "favourite", action_user_id: current_user.id) unless check.present?
    elsif choice == "unfavourite"
      check = ActionLog.find_by(type_name: "user", type_id: user_id, action_type: "favourite", action_user_id: current_user.id)
      check.delete if check.present?
    end
  end

  def block_user(current_user, user_id, choice)
    admin_user = User.find_by_email("info@raydiusapp.com")
    #admin_user1 = User.find_by_email("gamebot@raydiusapp.com")

    if choice == "block"
      unless user_id == admin_user.id or user_id == admin_user1.id
        check = ActionLog.where(type_name: "user", type_id: user_id, action_type: "block", action_user_id: current_user.id )
        ActionLog.create(type_name: "user",type_id: user_id, action_type: "block", action_user_id: current_user.id) unless check.present?
      end
    elsif choice == "unblock"
      exist = ActionLog.find(type_name: "user", type_id: user_id, action_type: "block",action_user_id: current_user.id)
      exist.delete if exist.present?
    end
  end

  def self.nearest(latitude, longitude, radius=1)
    # Contains bottom-left and top-right corners
    center_point = [latitude.to_f, longitude.to_f]
    box = Geocoder::Calculations.bounding_box(center_point, radius, {units: :km})

    # users = users.where("app_data ->'app_id#{hive_application.id}' = '#{hive_application.api_key}'")

    User.where(last_known_latitude: box[0] .. box[2], last_known_longitude: box[1] .. box[3])
  end


  def update_user_peerdrivedata (speed, direction, activity,heartrate)
    User.update_data_column("speed", speed, self.id)
    User.update_data_column("direction", direction, self.id)
    User.update_data_column("activity", activity, self.id)
    User.update_data_column("heartrate", heartrate, self.id)
  end



  def self.update_data_column(name, value, user_id)
    u = User.find(user_id)
    unless u.data.present?
      p "have data"
      data_hash = {}
      data_hash[name] = value
      u.data = data_hash
      u.save!
    else
      if u.data.has_key?(name) == false
        p "don't have key"
        data_hash = u.data
        data_hash[name] = value
        u.data = data_hash
        u.data_will_change!
        u.save!
      else
        if value.length > 0
          data_hash = u.data.except(name)
          data_hash[name] = value
          u.data = data_hash
          u.data_will_change!
          u.save!
        end
      end
    end
  end

  def self.update_latlng

    @places = Place.all.each
    @users = User.where("data -> 'color' != ''").each

    loop do
      a1,a2=@users.next,@places.next
      p 'user last know lat'
      p a1.last_known_latitude
      p 'place lat'
      p a2.latitude

      a1.last_known_latitude = a2.latitude
      a1.last_known_longitude = a2.longitude
      a1.save

      a1.last_known_latitude -= 0.003
      a1.last_known_longitude -= 0.004

      a1.save

    end
  end

  private

  def email_required?
    device_id.blank?
  end

  def ensure_username
    prefix = %w(
      Angry Anxious Befuddled Bemused Bewildered Bored Bright-eyed Cheerful Cool Cranky Ecstatic Excited
      Grumpy Happy Hungry Jolly Laid-back Lolling Mellow Merry Mystified Paranoid Playful Sober Tipsy
    )

    suffix = %w(
      Aardvark Alligator Beaver Bear Bluebird Butterfly Cat Chihuahua Chipmunk Elephant Eagle Giraffe
      Horse Husky Jaguar Kangaroo Koala Llama Lion Monkey Panda Puppy Snorkie Swan Tiger Whale Penguin Duck
    )

    name = ""

    if username.blank?
      name = "#{prefix.sample} #{suffix.sample}"

      if User.find_by_username(name).present?

        name = name + User.where("lower(username) like ?", "%#{name.downcase}%").count.to_s

        self.username = name
        #self.save!
      else
        self.username = name
        #self.save!
      end
    end

  end


end
