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

  attr_accessible :username, :email, :password, :authentication_token, :avatar_url, :role, :quid, :honor_rating, :created_at, :data

  enums %w(BOT VENDOR NORMAL)
end
