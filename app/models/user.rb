require 'value_enums'

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :topics
  has_many :posts

  # Setup hstore
  store_accessor :data
  include Authenticable

  attr_accessible :username, :email, :password, :password_confirmation, :authentication_token, :avatar_url, :role, :quid, :honor_rating, :created_at, :data
  after_initialize :ensure_authentication_token

  enums %w(BOT ADMIN VENDOR NORMAL)
end
