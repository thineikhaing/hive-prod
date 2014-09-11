class HiveapplicationController < ApplicationController
  require 'securerandom'  #to generate api key for application
  before_filter :detect_format, :set_cache_buster

  #Reset session if user click back button in browser
  def set_cache_buster
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
  end

  def login_page
    # Just a temporary login page to prevent people from looking at the content
    if params[:hive].present?
      if params[:hive][:login_password].present?
        if params[:hive][:login_password] == App_Password::Key
          redirect_to hiveapplication_index_path
        else
          #show error msg for wrong password
          flash.now[:notice] = "Wrong Password"
          render layout: nil
        end
      end
    else
      render layout: nil
    end
  end

  def index
    # Clear session data
    session[:session_devuser_id] = nil
    session[:no_of_apps] = nil
    session[:app_id] = nil
    session[:table_name] = nil
    session[:transaction_list_topics] = []
    session[:transaction_list_posts] = []
  end

  def sign_in
    # Check for user authentication
    user = Devuser.find_by_email(params[:dev_users][:email])
    error_notice = "WE COULDN'T FIND AN ACCOUNT WITH THAT USER ID/PASSWORD COMBINATION. PLEASE TRY AGAIN"

    if user.present?
      unless user.valid_password?(params[:dev_users][:password])
        # Redirects back to index if password is wrong
        flash[:notice] = error_notice
        redirect_to hiveapplication_index_path
      else
        if user.verified == true
          #store CURRENT_USER_ID in session
          session[:session_devuser_id] = user.id
          # Redirects to create application view if user has verified account.
          redirect_to hiveapplication_dev_portal_path
          #redirect_to HIVEAPPLICATION_APPLICATION_LIST_PATH
        else
          # Redirects back to index view if user hasn't verified account.
          flash[:notice] = error_notice
          redirect_to hiveapplication_index_path
        end
      end
    else
      # Redirects back to index view if user enters the wrong email address.
      flash[:notice] = error_notice
      redirect_to hiveapplication_index_path
    end
  end

  def dev_portal
    # Check for CURRENT_USER
    # Shows list of hiveapplications owned
    #clear the session array
    session[:transaction_list_topics] = []
    session[:transaction_list_posts] = []
    session[:app_id] = nil
    session[:table_name] = nil
    if current_user.present?
      @hive_applications = current_user.hive_applications.order("id ASC")
      session[:no_of_apps] = current_user.hive_applications.count
    else
      # Returns to sign in page if CURRENT_USER doesn't exist
      redirect_to hiveapplication_index_path
    end
  end

  #function to regenerate api key wiich is not used for the time being
  def regenerate_api_key
    # Check if CURRENT_USER and APPLICATION_ID is present
    if current_user.present?  && params[:app_id].present?
      hive_application = HiveApplication.find_by_id(params[:app_id])
      if hive_application.present?
        # Generates new APPLICATION_KEY
        api_key = SecureRandom.hex
        hive_application.api_key = api_key
        hive_application.save!

        user = Devuser.find(current_user.id)
        @hive_applications = user.hive_applications.order("id ASC")
      end
    end

  end

  def sign_up
    if params[:sign_up].present?
      # Check if email exists
      dev_user = Devuser.find_by_email(params[:sign_up][:email])

      # Verifications
      if dev_user.present?
        flash.now[:notice] = "Email already exists"
      elsif HiveApplication.is_a_valid_email(params[:sign_up][:email]) == false
        flash.now[:notice] = "Invalid email address"
      elsif params[:sign_up][:password]!= params[:sign_up][:confirm_password]
        flash.now[:notice] = "Password and Confirm Password must be the same"
      else
        #generate verification code
        verification_code = HiveApplication.generate_verification_code

        #create new Devuser
        devuser = Devuser.create(username: params[:sign_up][:username], email: params[:sign_up][:email], password: params[:sign_up][:password])
        encrypted_code = encryption(verification_code)
        devuser.email_verification_code = verification_code
        devuser.save!

        # Sends email verification
        mailer = UserMailer.account_verification(params[:sign_up][:username], params[:sign_up][:email], encrypted_code)
        mailer.deliver

        #add batch job to delete the user record if user does not verify
        HiveApplication.add_dev_user_activation_job(devuser.id)

        redirect_to hiveapplication_index_path
      end
    end
  end

  def add_application
    # Check if CURRENT_USER exist
    if current_user.present?
      if params[:dev_portal].present?

        # Generate random number for APPLICATION_KEY
        api_key = SecureRandom.hex

        hive_application = HiveApplication.create(app_name: params[:dev_portal][:application_name], app_type: params[:dev_portal][:application_type], description: params[:dev_portal][:description], icon_url: params[:dev_portal][:application_icon] ,devuser_id: current_user.id, theme_color: params[:dev_portal][:theme_color], api_key: api_key )
        flash[:notice] = ""
        hive_application.errors.full_messages.each do |message|
          # do stuff for each error
          flash[:notice] << message
        end

        unless hive_application.errors.any?
          # Creates a bot for the the application
          User.create(email: "bot@#{params[:dev_portal][:application_name]}", username: "#{params[:dev_portal][:application_name]} Bot", role: User::BOT)

          # Redirect back to list of applications
          redirect_to hiveapplication_application_list_path
        end
      end
    else
      # Redirect to sign in page
      redirect_to hiveapplication_index_path
    end
  end

  def edit_application
    # Show the Topics, Posts, Places, Users
    # Check if APPLICATION_ID and CURRENT_USER exist
    if params[:app_id].present? && current_user.present?
      session[:app_id] = params[:app_id].to_i
      @application = HiveApplication.find(params[:app_id])
      @Topicfields = table_list(params[:app_id], "Topic")

      @Postfields =  table_list(params[:app_id], "Post")

      #else
      #id, additional_column_name, status{ 0:default, 1:create, 2:edit, 3:delete }
      if session[:transaction_list_topics].present?  == false
        id=0
        @Topicfields.each do |topic_field|
          id+=1
          session[:transaction_list_topics].push({"field_id" => topic_field.id, "id"=> id, "additional_column_name"=> topic_field.additional_column_name, "status"=> 0})
        end
      end
      @Topicfieldbyapp = session[:transaction_list_topics]
      if session[:transaction_list_posts].present?  == false
        id=0
        @Postfields.each do |topic_field|
          id+=1
          session[:transaction_list_posts].push({"field_id"=> topic_field.id, "id"=> id, "additional_column_name"=> topic_field.additional_column_name, "status"=> 0 })
        end
      end
      @Postfieldbyapp = session[:transaction_list_posts]

      check_status_changes
      # Check if APPLICATION_ID that user click and CURRENT_USER exist
    elsif params[:dev_portal].present? && current_user.present?
      application_id = params[:dev_portal][:application_id]
      application = HiveApplication.find(application_id)

      #save the updated Application information
      if application.present?
        application.app_name = params[:dev_portal][:application_name]
        application.app_type = params[:dev_portal][:application_type]
        application.description = params[:dev_portal][:description]
        application.theme_color = params[:dev_portal][:theme_color]

        if params[:dev_portal][:application_icon].present?
          application.icon_url = params[:dev_portal][:application_icon]
        end

        application.save!

        #redirect back to Application List Page
        redirect_to hiveapplication_application_list_path
      end
    else
      #redirect back to Sign in Page
      redirect_to hiveapplication_index_path
    end

  end

  def delete_application
    # Check if APPLICATION_ID and CURRENT_USER exist
    if params[:app_id].present?  && current_user.present?
      application = HiveApplication.find(params[:app_id])
      if application.present?

        #delete image from Amazon server
        application.icon_url = nil
        application.remove_icon_url = true
        application.save!

        #delete related records from different tables
        AppAdditionalField.where(:app_id => params[:app_id] ).delete_all
        topics = Topic.where(:hiveapplication_id =>  params[:app_id])
        if topics.present?
          topics.each do |topic|
            Post.where(:topic_id=>topic.id).delete_all
            tags = TopicWithTag.where(:topic_id=> topic.id)
            if tags.present?
              tags.each do |tag|
                Tag.find(tag.tag_id).delete
              end
            end
            ActionLog.where(:type_name => "topic", :type_id => topic.id).delete_all
          end
          topics.delete_all
        end


        #delete the application record
        application.delete
      end
      user = Devuser.find(current_user.id)
      @hive_applications = user.hive_applications
    else
      #redirect back to Sign in Page
      redirect_to hiveapplication_index_path
    end

  end

  def delete_additional_column
    if params[:field_id].present?

      #delete from session variable
      if params[:table_name].present?
        if params[:table_name]=="Topic" and session[:transaction_list_topics].present?
          topics = session[:transaction_list_topics]
          topics.each do |field|
            if field["id"].to_i == params[:field_id].to_i
              field["status"] = 3
            end
          end
          @Topicfieldbyapp = session[:transaction_list_topics]
        elsif params[:table_name]=="Post" and session[:transaction_list_posts].present?
         session[:transaction_list_posts].each do |field|
            if field["id"].to_i == params[:field_id].to_i
              field[:status] = 3
            end
         end
         @Postfieldbyapp = session[:transaction_list_posts]
        end

        redirect_to hiveapplication_edit_application_path(:app_id => session[:app_id])
      end
    end
  end

  def update_additional_column
    if params[:field_id].present?
      #update to session variable
      if params[:table_name].present?
        new_column_name = params[:column_name]
        if params[:table_name]=="Topic" and session[:transaction_list_topics].present?
          topics = session[:transaction_list_topics]
          topics.each do |field|
            if field["id"].to_i == params[:field_id].to_i
              field["additional_column_name"] = new_column_name
              field["status"] = 2
            end
          end
          @Topicfieldbyapp = session[:transaction_list_topics]
        elsif params[:table_name]=="Post" and session[:transaction_list_posts].present?
          session[:transaction_list_posts].each do |field|
            if field["id"].to_i == params[:field_id].to_i
              field["additional_column_name"] = new_column_name
              field["status"] = 2
            end
          end
          @Postfieldbyapp = session[:transaction_list_posts]
        end
        redirect_to hiveapplication_edit_application_path(:app_id => session[:app_id])
      end
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
        job.delete if job.name == "dev-user-activation-#{dev_user.id}"
      end
    else
      # invalid email address or verification code
      flash[:notice] = "invalid verification"
      render "hiveapplication/index"
    end
  end

  def reset_password
    # Show user information if they forgotten password (email link)
    if params[:token].present?
      @devuser = Devuser.find_by_reset_password_token!(params[:token])
    end
  end

  def update_password
    # Updates PASSWORD
    @devuser = Devuser.find_by_reset_password_token!(params[:token])

    # Check if the activation code is within 2 hours
    if @devuser.reset_password_sent_at < 2.hours.ago
      redirect_to hiveapplication_forget_password_path, :alert => "Password reset has expired."
    elsif @devuser.update_attributes(params[:devuser])
      redirect_to hiveapplication_index_path, :notice => "Password has been reset!"
    else
      render :reset_password #err in saving password, show on reset_password page
    end
  end

  def forget_password
    # Sends email for user to change PASSWORD
    if params[:email].present?
      user = Devuser.find_by_email(params[:email])
      if user.present?
        user.send_password_reset
        redirect_to hiveapplication_index_path, :notice => "Email sent with password reset instructions."
      else
        redirect_to hiveapplication_index_path, :notice => "Email address does not exist."
      end
    end
  end

  def detect_format
    # Used to detect current brower used. (Android, Tablet, Iphone, Web browser(Chrome, Firefox, etc))
    unless current_browser.mobile? or current_browser.tablet?
      request.format = :html
    else
      request.format = :mobile
    end
  end

  def table_list(app_id,table_name)
    # Table list (temporary)
    #@table_list = ["Topic", "Post"]
    return AppAdditionalField.where(:app_id=> app_id, :table_name => table_name)
  end

  def edit_column
    # Edits the field stored in data(hstore)
    #if params[:AppAdditionalColumn].present?
      if params[:field_id].present?
        if params[:table_name]=="Topic"
          if session[:transaction_list_topics].present?
            topics = session[:transaction_list_topics]
            id = topics.last["id"]
          else
            id = 0
            topics = []
          end
          id +=1
          topics.push({"id" => id, "field_id" => 0, "additional_column_name"=> params[:additional_column_name], "status"=> 1})
          session[:transaction_list_topics] = topics
          @Topicfieldbyapp = session[:transaction_list_topics]
        elsif params[:table_name]=="Post"
          if session[:transaction_list_posts].present?
            posts = session[:transaction_list_posts]
            id = posts.last["id"]
          else
            id = 0
            posts = []
          end
          id +=1
          posts.push({"id" => id, "field_id" => 0, "additional_column_name"=> params[:additional_column_name], "status"=> 1})
          session.delete(:transaction_list_posts)
          session[:transaction_list_posts] = posts
          @Postfieldbyapp = session[:transaction_list_posts]
        end
        redirect_to hiveapplication_edit_application_path(:app_id => session[:app_id])
      #end
    end
  end


  def check_status_changes
    #check the status to show the alert message when user click back to basic option
    status_change = false
    session[:transaction_list_topics].each do |topic|
      if topic["status"]!= 0
        status_change = true
        break
      end
    end
    if status_change == false
      session[:transaction_list_posts].each do |post|
        if post["status"]!= 0
          status_change = true
          break
        end
      end
    end
    cookies[:status_change] = status_change
  end

  def clear_columns_changes
    #to clear the session data of all additional columns' changes
    cookies[:status_change] = false
    session[:transaction_list_topics] = []
    session[:transaction_list_posts] = []
    redirect_to hiveapplication_edit_application_path(:app_id => session[:app_id])
  end

  def save_columns_changes
    #to save the session data of all additional columns' changes  to table
    if session[:transaction_list_topics].present?
      topics = session[:transaction_list_topics]
      #for topics
      topics.each do |topic|
        case topic["status"] # a_variable is the variable we want to compare
          when 1    #new column
            app_add_field = AppAdditionalField.create(app_id: session[:app_id].to_i, table_name: "Topic", additional_column_name: topic["additional_column_name"])
            AppAdditionalField.add_column("Topic",topic["additional_column_name"],session[:app_id])

          when 2    #edit
            if topic["field_id"] >0
              field_record = AppAdditionalField.find(topic["field_id"])
              if field_record.present?
                old_column_name = field_record.additional_column_name
                new_column_name = topic["additional_column_name"]

                field_record.additional_column_name = new_column_name
                field_record.save!

                AppAdditionalField.edit_column("Topic",old_column_name,new_column_name,session[:app_id])
              end

            else
              #new column
              app_add_field = AppAdditionalField.create(app_id: session[:app_id].to_i, table_name: "Topic", additional_column_name: topic["additional_column_name"])
              AppAdditionalField.add_column("Topic",topic["additional_column_name"],session[:app_id])
            end

          when 3    #delete
            if topic["field_id"]>0
              additional_field = AppAdditionalField.find(topic["field_id"])
              if additional_field.present?
                field_name = additional_field.additional_column_name
                additional_field.delete

                AppAdditionalField.delete_column("Topic",field_name,session[:app_id])
              end
            end
        end
      end
    end
    if session[:transaction_list_posts].present?
      posts = session[:transaction_list_posts]
      #for post
      posts.each do |post|
        case post["status"] # a_variable is the variable we want to compare
          when 1    #new column
            app_add_field = AppAdditionalField.create(app_id: session[:app_id].to_i, table_name: "Post", additional_column_name: post["additional_column_name"])
            AppAdditionalField.add_column("Post",post["additional_column_name"],session[:app_id])

          when 2    #edit
            if post["field_id"] >0
              p "edit"
              p post["field_id"]
              field_record = AppAdditionalField.find(post["field_id"])
              if field_record.present?
                old_column_name = field_record.additional_column_name
                new_column_name = post["additional_column_name"]

                field_record.additional_column_name = new_column_name
                field_record.save!

                AppAdditionalField.edit_column("Post",old_column_name,new_column_name,session[:app_id])
              end

            else
              app_add_field = AppAdditionalField.create(app_id: session[:app_id].to_i, table_name: "Post", additional_column_name: post["additional_column_name"])
              AppAdditionalField.add_column("Post",post["additional_column_name"],session[:app_id])
            end

          when 3    #delete
            if post["field_id"]>0
              additional_field = AppAdditionalField.find(post["field_id"])
              if additional_field.present?
                field_name = additional_field.additional_column_name
                additional_field.delete

                AppAdditionalField.delete_column("Post",field_name,session[:app_id])
              end
            end
        end
      end
    end
    clear_columns_changes
  end

end
