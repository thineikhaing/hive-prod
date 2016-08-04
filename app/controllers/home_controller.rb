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

   def create_train_fault_alert

     if Rails.env.development?
       round_key = RoundTrip_key::Development_Key

     elsif Rails.env.staging?
       round_key = RoundTrip_key::Staging_Key

     else
       round_key = RoundTrip_key::Production_Key
     end

     p "call to controller"
     if params[:topic]
       title= ''
       smrt = params[:topic][:smrt]
       start_place_id = params[:topic][:start_place_id]
       end_place_id = params[:topic][:end_place_id]
       toward_id = params[:topic][:toward]
       reason = params[:topic][:reason]
       hiveapplication_id = params[:topic][:hiveapplication_id]



       station1 = Place.find(start_place_id)
       station2 = Place.find(end_place_id)
       towards = Place.find(toward_id)
       add_info = params[:topic][:additional_info]


       if start_place_id.present? && end_place_id.present?
         p title = "[#{smrt}]"+reason +", between "+station1.name+" and "+station2.name

       elsif start_place_id.present? && end_place_id.blank?
         p title =  "[#{smrt}]"+reason +" from "+station1.name
       end

       if toward_id.present?
         title += " towards "+towards.name
       end

       if add_info.present?
         title += " "+add_info
       end
       p "title before create"
       p title

       topic = Topic.create(title:title, user_id: User.first.id, topic_type: 10 ,start_place_id: start_place_id , end_place_id: end_place_id,
                            topic_sub_type: 0, hiveapplication_id: hiveapplication_id, place_id: Place.first.id)

       topic.hive_broadcast
       topic.app_broadcast_with_content

       p station1name = station1.name.chomp(' MRT')
       p station2name = station2.name.chomp(' MRT')

       p "notify to round trip user"
       topic.notify_train_fault_to_roundtrip_users(smrt, station1name, station2name, towards.name)

       # p "Push Woosh Authentication"
       # if Rails.env.production?
       #   appID = PushWoosh_Const::RT_P_APP_ID
       # elsif Rails.env.staging?
       #   appID = PushWoosh_Const::RT_S_APP_ID
       # else
       #   appID = PushWoosh_Const::RT_D_APP_ID
       # end
       #
       # @auth = {:application  => appID ,:auth => PushWoosh_Const::API_ACCESS}
       #
       #
       # users = User.where("app_data ->'app_id#{hiveapplication.id}' = '#{hiveapplication.api_key}'")
       #
       # p users.count
       # to_device_id = []
       # time_allowance = Time.now - 10.minutes.ago
       # users.each do |u|
       #   if u.check_in_time.present?
       #     time_difference = Time.now - u.check_in_time
       #     unless time_difference.to_i > time_allowance.to_i
       #       hash_array = u.data
       #       if hash_array.present?
       #         device_id = hash_array["device_id"] if  hash_array["device_id"].present?
       #         to_device_id.push(device_id)
       #       end
       #
       #     end
       #   end
       # end
       #
       # notification_options = {
       #     send_date: "now",
       #     badge: "1",
       #     sound: "default",
       #     content:{
       #         fr:topic.title,
       #         en:topic.title
       #     },
       #     data:{
       #         trainfault_datetime: Time.now,
       #         smrtline: smrt,
       #         station1: station1name,
       #         station2: station2name,
       #         towards: towards.name,
       #         topic: topic,
       #         type: "train fault"
       #     },
       #     devices: to_device_id
       # }
       #
       # if to_device_id.count > 0
       #   options = @auth.merge({:notifications  => [notification_options]})
       #   options = {:request  => options}
       #   full_path = 'https://cp.pushwoosh.com/json/1.3/createMessage'
       #   url = URI.parse(full_path)
       #   req = Net::HTTP::Post.new(url.path, initheader = {'Content-Type' =>'application/json'})
       #   req.body = options.to_json
       #   con = Net::HTTP.new(url.host, url.port)
       #   con.use_ssl = true
       #   r = con.start {|http| http.request(req)}
       #   p "pushwoosh"
       # end

       flash[:notice] = "Create SMRT alert message successfully!"
       redirect_to create_train_fault_alert_path
     end
   end

   private

   def special_layout
     # Check if logged in, because current_user could be nil.
     # "special_layout"
     "special_layout"
   end

end
