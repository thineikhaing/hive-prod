class UserMailer < ActionMailer::Base
  default from: "no-reply@raydiusapp.com"

  def account_verification(username, email, verification_code)
    @verify = verification_code
    @username = username
    if Rails.env.development? || Rails.env.testing?
      @email = "http://localhost:5000/verify?email=" + email
    elsif Rails.env.staging? || Rails.env.production?
      @email = "http://h1ve-staging.herokuapp.com/verify?email=" + email
    end
    mail(:to => email, :subject => "Please complete your verification")
  end

  def password_reset(user)
    if Rails.env.development? || Rails.env.testing?
      @reset_pwd_url = "http://localhost:5000/reset_password?token=" + user.reset_password_token
    elsif Rails.env.staging? || Rails.env.production?
      @reset_pwd_url = "http://h1ve-staging.herokuapp.com/reset_password?token=" + user.reset_password_token
    end
    mail :to => user.email, :subject => "Password Reset"
  end

end
