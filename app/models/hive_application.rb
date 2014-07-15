class HiveApplication < ActiveRecord::Base
  belongs_to :devuser
  has_many :topics
  # **must** specify class of uploader, otherwise base uploader is used, and no
  # ...

  #check mandatory fields are present?
  #validates :app_name, presence: {message: "Application Name is mandatory"}
  ##validates :app_type, presence: {message: "Application Type is mandatory"}
  #validates :description, presence: {message: "Application Description is mandatory"}
  #validates :icon_url, presence: {message: "Application icon must be uploaded"}

  mount_uploader :icon_url, ApplicationiconUploader

  attr_accessible :app_name, :app_type, :description, :api_key, :icon_url ,:theme_color, :devuser_id, :created_at
  validates :app_name, :length => { :maximum => 32 }
  validates :description, :length => { :maximum => 255 }

  def self.generate_verification_code(length=16)
    # Generates an alphanumerical verification code (length = 16bits)
    chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ0123456789'
    verification_code = ''
    length.times { verification_code << chars[rand(chars.size)] }

    return verification_code
  end

  def self.get_application_type
    ["Please select a type", "food", "social", "game"]
  end


  def self.add_dev_user_activation_job(user_id)
    # Adds a batch job with a time limit of n minutes (1 for development, 1440 for production)
    Delayed::Job.enqueue DevUserActivationJob.new(user_id),:priority => 0,:run_at => 1.minutes.from_now
  end

  def self.is_a_valid_email(email)
    # Check the number of '@' signs.
    if email.count("@") != 1 then
      return false
      # check the email using a simple regex.
    elsif email =~ /^.*@.*(.com|.org|.net)$/ then
      return true
    else
      return false
    end
  end
end
