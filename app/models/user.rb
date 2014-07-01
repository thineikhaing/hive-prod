require 'value_enums'

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :topics
  has_many :posts
  has_many :user_push_tokens
  has_many  :user_accounts

  # Setup hstore
  store_accessor :data
  include Authenticable

  attr_accessible :username, :email, :password, :password_confirmation, :authentication_token, :avatar_url, :role, :quid, :honor_rating, :created_at, :data, :device_id

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
