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

  def report_offensive_topic(user, topic)
    @user = user
    @topic = topic
    receiver = User.find_by_email("info@raydiusapp.com")
    mail(:to => receiver.email, :subject => "Report for offensive topic")
  end

  def report_offensive_post(user, post)
    @user = user
    @post = post
    receiver = User.find_by_email("info@raydiusapp.com")
    mail(:to => receiver.email, :subject => "Report for offensive post")
  end

  def send_invitation(contact, pub_inv_code, inv_code, title, count)
    @invitation_code = pub_inv_code
    @title = title

    topic = Topic.find_by_invitation_code(pub_inv_code)
    @creator_name = topic.creator_name

    emails = ""

    user = User.find_or_create_by_email(contact[:email])
    user.username = contact[:name]
    user.save!

    count_str = count.to_s

    while count_str.length < 4
      count_str = "0" << count_str
    end

    @personal_invitation_code = inv_code.to_s
    @personal_invitation_code = @personal_invitation_code[0..15] + count_str  + @personal_invitation_code[16..17]

    Invitee.create!(user_id: user.id, topic_id: topic.id, invitation_code: @personal_invitation_code)
    @user = user

    pub_img = Topic.find_by_invitation_code(pub_inv_code).qr_code

    qr = RQRCode::QRCode.new("#{ActionMailer::Base.default_url_options[:host]}/use_invitation?i_code=#{@personal_invitation_code}", size: 14)
    png = qr.to_img
    img = png.resize(400,400).save("public/personalized_qr_code.png")

    attachments.inline["pub_qrcode"] = {
        :content => File.read(File.open(pub_img).path),
        :mime_type => "image/png",
        :encoding => "base64"
    }

    attachments.inline["qrcode"] = {
        :content => File.read(File.open(img).path),
        :mime_type => "image/png",
        :encoding => "base64"
    }

    mail(:to => contact[:email], :subject => "You have been invited to #{@title}")
  end

end
