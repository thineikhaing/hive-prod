class Devuser < ActiveRecord::Base
  has_many :hive_applications

  #check mandatory fields are present?
  validates :username, presence: {message: "User Name is mandatory"}
  validates :email, presence: {message: "Email is mandatory"}
  validates :password, presence: {message: "Password is mandatory"}

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup hstore
  store_accessor :data

  attr_accessible :username, :email, :password, :password_confirmation, :verified, :email_verification_code, :hiveapplication_id, :data

  def send_password_reset
    generate_token(:reset_password_token)
    self.reset_password_sent_at = Time.zone.now
    save!
    UserMailer.password_reset(self).deliver
  end

  def generate_token(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
  end
end
