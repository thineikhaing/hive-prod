class UserMailer < ActionMailer::Base
  default from: "no-reply@raydiusapp.com"

  def account_verification(username, email, verification_code)
    @verify = verification_code
    @username = username
    @email = email

    mail(:to => email, :subject => "Please complete your verification")
  end

  def password_reset(user)
    @user = user
    mail :to => user.email, :subject => "Password Reset"
  end

end
