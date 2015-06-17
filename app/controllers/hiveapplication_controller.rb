class HiveapplicationController < ApplicationController
  require 'securerandom'  #to generate api key for application

  before_filter :detect_format, :set_cache_buster

  skip_before_filter :verify_authenticity_token

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

    if user.nil?
      user = Devuser.find_by_username(params[:dev_users][:email])
    end
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

  def verify_signup

  end

  def sign_up
    @flag = true

    if !params[:username].blank?
      @submit = true
      username = Devuser.find_by_username(params[:username])

      if username.present?
        @err_username = "THIS ID IS NOT AVAILABLE"
        @flag = false
      else
        p @username = params[:username]
        p @err_username = nil
        @flag = true
      end

    end

    if !params[:email].blank?

      email = Devuser.find_by_email(params[:email])
      if email.present?
        @err_email = "EMAIL ALREADY EXISTS"
        @flag = false
      elsif HiveApplication.is_a_valid_email(params[:email]) == false
        @err_email = "PLEASE ENTER A VALID EMAIL ADDRESS"
        @flag = false
      else
        @email = params[:email]
        @flag = true
      end

    end

    if !params[:confirm_email].blank?
      if params[:email]!= params[:confirm_email]
        @err_confirmEmail = "EMAIL DO NOT MATCH"
        @flag = false
      else
        @confirm_email = params[:confirm_email]
        @flag = true
      end

    end

    if !params[:password].blank?
      if HiveApplication.is_a_valid_password(params[:password])  == false
        @err_password = "PASSWORDS MUST BE AT LEAST A CHARACTERS LONG AND INCLUDE A NUMBER"
        @flag = false
      else
        @password = params[:password]
        @flag = true
      end
    end

    if !params[:confirm_password].blank?

      if params[:password]!= params[:confirm_password]
        @err_confirmPassword = "PASSWORDS DO NOT MATCH"
        @flag = false
      else
        @confirm_password = params[:confirm_password]
        @flag = true
      end

    end



    if params[:sign_up].present?
      @submit = true
      # Check if email exists
      dev_user = Devuser.find_by_email(params[:sign_up][:email])
      dev_username = Devuser.find_by_username(params[:sign_up][:username])

      # Verifications
      if dev_user.present?
        @err_email = "EMAIL ALREADY EXISTS"
        @flag = false
      elsif HiveApplication.is_a_valid_email(params[:sign_up][:email]) == false
        @err_email = "PLEASE ENTER A VALID EMAIL ADDRESS"
        @flag = false
      else
        @email = params[:sign_up][:email]
      end

      if params[:sign_up][:email]!= params[:sign_up][:confirm_email]
        @err_confirmEmail = "EMAIL DO NOT MATCH"
        @flag = false
      else
        @confirm_email = params[:sign_up][:confirm_email]
      end

      if params[:sign_up][:password]!= params[:sign_up][:confirm_password]
        @err_confirmPassword = "PASSWORDS DO NOT MATCH"
        @flag = false
      else
        @password = params[:sign_up][:password]
      end

      if HiveApplication.is_a_valid_password(params[:sign_up][:password])  == false
        @err_password = "PASSWORDS MUST BE AT LEAST A CHARACTERS LONG AND INCLUDE A NUMBER"
        @flag = false
      else
        @confirm_password = params[:sign_up][:confirm_password]
      end

      if dev_username.present?
        @err_username = "THIS ID IS NOT AVAILABLE"
        @flag = false
      else
        @username = params[:sign_up][:username]
      end

      if @username == ''
        @err_username = "THIS ID IS REQUIRED"
        @flag = false
      end

      if @flag ==  true
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

        hive_application = HiveApplication.create(app_name: params[:dev_portal][:application_name],
                                                  app_type: params[:dev_portal][:application_type],
                                                  description: params[:dev_portal][:description],
                                                  icon_url: params[:dev_portal][:application_icon] ,
                                                  devuser_id: current_user.id, theme_color: params[:dev_portal][:theme_color],
                                                  api_key: api_key )
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
            topic.remove_record
            posts = Post.where(:topic_id=>topic.id).delete_all
            posts.each do|post|
              post.remove_record
            end
            posts.delete_all
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
      update_additional_field_table(topics, "Topic",session[:app_id])
    end
    if session[:transaction_list_posts].present?
      posts = session[:transaction_list_posts]
      #for post
      update_additional_field_table(posts, "Post",session[:app_id])
    end
    clear_columns_changes
  end

  def update_additional_field_table(transaction_list, table_name,app_id)
    transaction_list.each do |tran|
      case tran["status"] # a_variable is the variable we want to compare
        when 1    #new column
          app_add_field = AppAdditionalField.create(app_id:app_id, table_name: table_name, additional_column_name: tran["additional_column_name"])
          AppAdditionalField.add_column(table_name,tran["additional_column_name"],app_id)
        when 2    #edit
          if tran["field_id"] >0
            field_record = AppAdditionalField.find(tran["field_id"])
            if field_record.present?
              old_column_name = field_record.additional_column_name
              new_column_name = tran["additional_column_name"]

              field_record.additional_column_name = new_column_name
              field_record.save!

              AppAdditionalField.edit_column(table_name,old_column_name,new_column_name,app_id)
            end

          else
            app_add_field = AppAdditionalField.create(app_id: app_id, table_name: table_name, additional_column_name: tran["additional_column_name"])
            AppAdditionalField.add_column(table_name,tran["additional_column_name"],app_id)
          end

        when 3    #delete
          if tran["field_id"]>0
            additional_field = AppAdditionalField.find(tran["field_id"])
            if additional_field.present?
              field_name = additional_field.additional_column_name
              additional_field.delete

              AppAdditionalField.delete_column(table_name,field_name,app_id)
            end
          end
      end
    end
  end

  #to display the list of topics and post under each app
  def edit_topic_post
    session[:app_id] = params[:app_id]
    topic_ids = []
    @topics = Topic.where(hiveapplication_id: session[:app_id])
    if @topics.present?
      @topics.each do |t|
        topic_ids.push(t.id)
      end
      @posts = Post.where(topic_id:topic_ids)
    end

    if Rails.env.development?
      @image_url = AWS_Link::AWS_Image_D_Link
      @audio_url = AWS_Link::AWS_Audio_D_Link
    elsif Rails.env.staging?
      @image_url = AWS_Link::AWS_Image_S_Link
      @audio_url = AWS_Link::AWS_Audio_S_Link
    else
      @image_url = AWS_Link::AWS_Image_P_Link
      @audio_url = AWS_Link::AWS_Audio_P_Link
    end
  end

  #to edit topic by topic_id
  def edit_topic
    if params[:topic_id].present?
      topic = Topic.find_by_id(params[:topic_id])
      if topic.present?
        topic.title = params[:topic_title]
        topic.save!
      end
    end
    redirect_to hiveapplication_edit_topic_post_path(:app_id => session[:app_id])
  end

  #to delete topic by topic_id
  def delete_topic
    if params[:topic_id].present?
      topic = Topic.find_by_id(params[:topic_id])
      if topic.present?
        topic.remove_records

        #delete file from S3 if topic type is IMAGE AUDIO VIDEO
        bucket_name = ""
        file_name=""
        if topic.topic_type == Topic::IMAGE
          file_name = topic.image_url
          if Rails.env.development?
            bucket_name = AWS_Bucket::Image_D
          elsif Rails.env.staging?
            bucket_name = AWS_Bucket::Image_S
          else
            bucket_name = AWS_Bucket::Image_P
          end
          topic.delete_S3_file(bucket_name, file_name,topic.topic_type)
        elsif topic.topic_type == Topic::AUDIO
          file_name = topic.image_url
          if Rails.env.development?
            bucket_name = AWS_Bucket::Audio_D
          elsif Rails.env.staging?
            bucket_name = AWS_Bucket::Audio_S
          else
            bucket_name = AWS_Bucket::Audio_P
          end
          topic.delete_S3_file(bucket_name, file_name,topic.topic_type)
        end

        #broadcast delete topic pusher message
        if topic.hiveapplication_id ==1 #Hive Application
                                        #if hiveapplication.devuser_id == 1
          topic.delete_event_broadcast_hive
        else
          topic.delete_event_broadcast_hive
          topic.delete_event_broadcast_other_app
        end

        topic.delete
      end
    end
    redirect_to hiveapplication_edit_topic_post_path(:app_id => session[:app_id])
  end

  #to edit post by post_id
  def edit_post
    if params[:post_id].present?
      post = Post.find_by_id(params[:post_id])
      if post.present?
        post.content = params[:post_content]
        post.save!
      end
    end
    redirect_to hiveapplication_edit_topic_post_path(:app_id => session[:app_id])
  end

  #to delete post by post_id
  def delete_post
    if params[:post_id].present?
      post = Post.find_by_id(params[:post_id])
      if post.present?
        post.remove_records

        bucket_name = ""
        file_name=""
        if post.post_type == Post::IMAGE
          file_name = post.img_url
          if Rails.env.development?
            bucket_name = AWS_Bucket::Image_D
          elsif Rails.env.staging?
            bucket_name = AWS_Bucket::Image_S
          else
            bucket_name = AWS_Bucket::Image_P
          end
          post.delete_S3_file(bucket_name, file_name,post.post_type)
        elsif post.post_type == Post::AUDIO
          file_name = post.img_url
          if Rails.env.development?
            bucket_name = AWS_Bucket::Audio_D
          elsif Rails.env.staging?
            bucket_name = AWS_Bucket::Audio_S
          else
            bucket_name = AWS_Bucket::Audio_P
          end
          post.delete_S3_file(bucket_name, file_name,post.post_type)
        end

        #broadcast delete post pusher message
        topic = Topic.find_by_id(post.topic_id)
        if topic.hiveapplication_id ==1 #Hive Application
                                        #if hiveapplication.devuser_id == 1
          post.delete_event_broadcast_hive
        else
          post.delete_event_broadcast_hive
          post.delete_event_broadcast_other_app
        end

        post.delete
      end
    end
    redirect_to hiveapplication_edit_topic_post_path(:app_id => session[:app_id])
  end
end
