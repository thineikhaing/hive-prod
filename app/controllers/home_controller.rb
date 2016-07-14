class HomeController < ApplicationController
   layout :special_layout
  def home
    # render layout: nil
  end

  def dev_sign_in
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
        redirect_to root_path
      else
        if user.verified == true
          #store CURRENT_USER_ID in session
          session[:session_devuser_id] = user.id
          # Redirects to create application view if user has verified account.
          redirect_to devapp_list_path
          #redirect_to HIVEAPPLICATION_APPLICATION_LIST_PATH
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



  def application_portal
    place_for_map_view
    if current_user.nil?
      redirect_to root_path

    else
      cur_user = Devuser.find(current_user.id)
      @hive_applications = cur_user.hive_applications.order("id ASC")


      if Rails.env.development?
        @carmmunicate_key = Carmmunicate_key::Development_Key
        @favr_key = Favr_key::Development_Key
        @meal_key = Mealbox_key::Development_Key
        @socal_key = Socal_key::Development_Key
        @hive_key = Hive_key::Development_Key
        @round_key = RoundTrip_key::Development_Key

      elsif Rails.env.staging?
        @carmmunicate_key = Carmmunicate_key::Staging_Key
        @favr_key = Favr_key::Staging_Key
        @meal_key = Mealbox_key::Staging_Key
        @socal_key = Socal_key::Staging_Key
        @hive_key = Hive_key::Staging_Key
        @round_key = RoundTrip_key::Staging_Key

      else
        @carmmunicate_key = Carmmunicate_key::Production_Key
        @favr_key = Favr_key::Production_Key
        @meal_key = Mealbox_key::Production_Key
        @socal_key = Socal_key::Production_Key
        @hive_key = Hive_key::Production_Key
        @round_key = RoundTrip_key::Production_Key

      end



      render layout: "special_layout"

    end

  end

   def place_for_map_view
     @placesMap = Place.order("created_at DESC").reload

     #filtering for normal topic, image, audio and video
     @latestTopics = [ ]
     @latestTopicUser = [ ]

     @placesMap.map { |f|
       @latestTopics.push(f.topics.last)
     }

     @latestTopics.each do |topic|
       if topic.present?
         @latestTopicUser.push(topic.username)
       else
         @latestTopicUser.push("nothing")
       end
     end

     gon.places =  @placesMap.as_json
     gon.latestTopicUser = @latestTopicUser
     gon.latestTopics = @latestTopics
   end


   def devapp_list

     # place_for_map_view

     @placesMap = Place.order("created_at DESC").reload

     gon.places = @placesMap

     if Rails.env.development?
       @carmmunicate_key = Carmmunicate_key::Development_Key
       @favr_key = Favr_key::Development_Key
       @meal_key = Mealbox_key::Development_Key
       @socal_key = Socal_key::Development_Key
       @hive_key = Hive_key::Development_Key
       @round_key = RoundTrip_key::Development_Key

     elsif Rails.env.staging?
       @carmmunicate_key = Carmmunicate_key::Staging_Key
       @favr_key = Favr_key::Staging_Key
       @meal_key = Mealbox_key::Staging_Key
       @socal_key = Socal_key::Staging_Key
       @hive_key = Hive_key::Staging_Key
       @round_key = RoundTrip_key::Staging_Key

     else
       @carmmunicate_key = Carmmunicate_key::Production_Key
       @favr_key = Favr_key::Production_Key
       @meal_key = Mealbox_key::Production_Key
       @socal_key = Socal_key::Production_Key
       @hive_key = Hive_key::Production_Key
       @round_key = RoundTrip_key::Production_Key
     end

     if current_user.nil?
       redirect_to root_path
     else
       cur_user = Devuser.find(current_user.id)
       @hive_applications = cur_user.hive_applications.order("id ASC")
       p "hive applicaiton by current user"
       gon.test = "testing gon from controller"
       p gon.hiveapplicaiton = @hive_applications
     end

   end

   def edit_application
     if params[:dev_portal].present? && current_user.present?
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
       redirect_to devapp_list_path
     end
     end

   end
   private

   def special_layout
     # Check if logged in, because current_user could be nil.
     # "special_layout"
     "special_layout"
   end

end
