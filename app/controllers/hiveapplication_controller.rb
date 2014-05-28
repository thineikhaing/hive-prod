class HiveapplicationController < ApplicationController
  require 'securerandom'  #to generate api key for application
  def index
    session[:session_devuser_id] = nil
    session[:no_of_apps] = nil
  end

  def sign_in
    user = Devuser.find_by_email(params[:dev_users][:email])
    error_notice = "WE COULDN'T FIND AN ACCOUNT WITH THAT USER ID/PASSWORD COMBINATION. PLEASE TRY AGAIN"

    # Check for user authentication
    if user.present?
      unless user.valid_password?(params[:dev_users][:password])
        # Redirects back to index if password is wrong
        flash[:notice] = error_notice
        redirect_to root_path
      else
        if user.verified == true
          #store current user id in session
          session[:session_devuser_id] = user.id
          # Redirects to create application view if user has verified account.
          redirect_to hiveapplication_dev_portal_path
          #redirect_to hiveapplication_application_list_path
        else
          # Redirects back to index view if user hasn't verified account.
          flash[:notice] = error_notice
          redirect_to root_path
        end
      end
    else
      # Redirects back to index view if user enters the wrong email address.
      flash[:notice] = error_notice
      redirect_to root_path
    end
  end

  def dev_portal
    p current_user
    if current_user.present?
      @hive_applications = current_user.hive_applications.order("id DESC")
      session[:no_of_apps] = current_user.hive_applications.count
    else
      redirect_to root_path
    end
  end

  def application_list
    if current_user.present?
      @hive_applications = current_user.hive_applications.order("id DESC")
    else
      redirect_to root_path
    end
  end

  def regenerate_api_key
    if current_user.present?  && params[:app_id].present?
      application_id = params[:app_id]
      hive_application = HiveApplication.find(application_id)
      if hive_application.present?
        api_key = SecureRandom.hex
        hive_application.api_key = api_key
        hive_application.save!

        user = Devuser.find(current_user.id)
        @hive_applications = user.hive_applications.order("id DESC")
      end
    end

  end

  def sign_up
    if params[:sign_up].present?
      # Check if email exists
      dev_user = Devuser.find_by_email(params[:sign_up][:email])

      if dev_user.present?
        flash.now[:notice] = "Email already exists"
      elsif HiveApplication.is_a_valid_email(params[:sign_up][:email]) == false
        flash.now[:notice] = "Invalid email address"
      elsif params[:sign_up][:password]!= params[:sign_up][:confirm_password]
        flash.now[:notice] = "Password and Confirm Password must be the same"
      else
        verification_code = HiveApplication.generate_verification_code

        devuser = Devuser.create(username: params[:sign_up][:username], email: params[:sign_up][:email], password: params[:sign_up][:password])
        encrypted_code = encryption(verification_code)
        devuser.email_verification_code = verification_code
        devuser.save!

        # Sends email verification
        mailer = UserMailer.account_verification(params[:sign_up][:username], params[:sign_up][:email], encrypted_code)
        mailer.deliver

        HiveApplication.add_dev_user_activation_job(devuser.id)

        render "hiveapplication/index"
      end
    end
  end

  def add_application
    if current_user.present?
      p params[:dev_portal]
      if params[:dev_portal].present?
        hive_application = HiveApplication.create(app_name: params[:dev_portal][:application_name], app_type: params[:dev_portal][:application_type], description: params[:dev_portal][:description], icon_url: params[:dev_portal][:application_icon] ,devuser_id: current_user.id )
        p hive_application
        if hive_application.present?
          #generate random number for api key
          api_key = SecureRandom.hex
          hive_application.api_key = api_key
          hive_application.save!

          User.create(username: "#{params[:dev_portal][:application_name]} Bot", role: User::BOT)

          redirect_to hiveapplication_application_list_path
        end
      end
    else
      redirect_to root_path
    end
  end

  def edit_application
    p current_user.present?
    if params[:app_id].present? && current_user.present?
      @application = HiveApplication.find(params[:app_id])
    elsif params[:dev_portal].present? && current_user.present?
      application_id = params[:dev_portal][:application_id]
      application = HiveApplication.find(application_id)

      if application.present?
        application.app_name = params[:dev_portal][:application_name]
        application.app_type = params[:dev_portal][:application_type]
        application.description = params[:dev_portal][:description]

        if params[:dev_portal][:application_icon].present?
          application.icon_url = params[:dev_portal][:application_icon]
        end

        application.save!
        redirect_to hiveapplication_application_list_path
      end
    else
      redirect_to root_path
    end
  end

  def delete_application
    if params[:app_id].present?  && current_user.present?
      application = HiveApplication.find(params[:app_id])
      if application.present?
        application.icon_url = nil
        application.remove_icon_url = true
        application.save
        application.delete
      end
      user = Devuser.find(current_user.id)
      @hive_applications = user.hive_applications
    else
      redirect_to root_path
    end

  end


  def verify
    #token stands for iv and code is used for encrypted_verification_code
    verification_code = decryption(params[:token],params[:code])
    dev_user = Devuser.find_by_email_verification_code_and_email_and_verified(verification_code, params[:email],false )

    if dev_user.present?
      dev_user.verified = true
      dev_user.save!

      #delete the batched job which deactivate the dev user account
      jobs= Delayed::Job.all
      jobs.each do |job|
        if job.name == "dev-user-activation-#{dev_user.id}"
          p job.name+ " has been removed from queue"
          job.delete
        end
      end
    else
      # invalid email address or verification code
      flash[:notice] = "invalid verification"
      render "hiveapplication/index"
    end
  end

  def reset_password
    if params[:token].present?
      @devuser = Devuser.find_by_reset_password_token!(params[:token])
    end
  end

  def update_password
    @devuser = Devuser.find_by_reset_password_token!(params[:token])
    if @devuser.reset_password_sent_at < 2.hours.ago
      redirect_to hiveapplication_forget_password_path, :alert => "Password reset has expired."
    elsif @devuser.update_attributes(params[:devuser])
      redirect_to root_url, :notice => "Password has been reset!"
    else
      render :reset_password #err in saving password, show on reset_password page
    end
  end

  def forget_password
    if params[:email].present?
      user = Devuser.find_by_email(params[:email])
      if user.present?
        user.send_password_reset
        redirect_to root_url, :notice => "Email sent with password reset instructions."
      else
        redirect_to root_url, :notice => "Email address does not exist."
      end


    end
  end
end
