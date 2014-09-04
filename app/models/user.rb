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
  has_many  :user_accounts

  # Setup hstore
  store_accessor :data
  include Authenticable

  attr_accessible :username, :email, :password, :password_confirmation, :authentication_token, :avatar_url, :role, :point, :flareMode, :alert_count, :paid_alert_count, :credits, :last_known_latitude, :last_known_longitude, :check_in_time, :profanity_counter, :offence_date, :positive_honor, :negative_honor, :honored_times, :created_at, :data, :device_id

  after_initialize :ensure_authentication_token
  after_initialize :ensure_username

  validates_uniqueness_of    :email, :case_sensitive => false, :allow_blank => true

  enums %w(BOT ADMIN VENDOR NORMAL)

  def self.search_data(search)
    where("lower(username) like ?", "%#{search.downcase}%")
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
        self.save!
      else
        self.username = name
        self.save!
      end
    end
  end


end




