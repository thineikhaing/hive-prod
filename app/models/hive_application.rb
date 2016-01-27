class HiveApplication < ActiveRecord::Base
  belongs_to :devuser
  has_many :topics  , :foreign_key => 'hiveapplication_id'

  #xss_foliate :sanitize => [ :body]

  # **must** specify class of uploader, otherwise base uploader is used, and no
  # ...

  #check mandatory fields are present?
  #validates :app_name, presence: {message: "Application Name is mandatory"}
  ##validates :app_type, presence: {message: "Application Type is mandatory"}
  #validates :description, presence: {message: "Application Description is mandatory"}
  #validates :icon_url, presence: {message: "Application icon must be uploaded"}

  mount_uploader :icon_url, ApplicationiconUploader

  #attr_accessible :app_name, :app_type, :description, :api_key, :icon_url ,:theme_color, :devuser_id, :created_at
  validates :app_name, :length => { :maximum => 32 }
  validates :description, :length => { :maximum => 255 }

  def as_json(options=nil)
    if options.present?
      super(only: [:id, :app_name, :app_type, :description, :theme_color, :created_at, :updated_at], methods:[:img_icon_url] )
    else
      super(only: [:id, :app_name, :app_type, :api_key, :description, :theme_color, :devuser_id, :created_at, :updated_at], methods:[:img_icon_url] )
    end

  end

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


  def img_icon_url
    self.icon_url.url
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
    elsif email =~ /^.*@.*(.com|.org|.net|.io)$/ then
      return true
    else
      return false
    end
  end

  def self.is_a_valid_password(pass)
    # Check the number of '@' signs.
    if pass.length < 8 then
      return false
      # check the pass has one number
    elsif pass =~/\d/ then
      return true
    else
      return false
    end
  end

end


