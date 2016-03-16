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
          redirect_to application_portal_path
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



      # lat = params[:cur_lat] if params[:cur_lat].present?
      # lng = params[:cur_long] if params[:cur_long].present?
      #
      # if params[:cur_lat.present?]
      #   @placesMap =  Place.nearest(lat,lng,1)
      # else
      #   @placesMap = Place.all.reload
      # end

      # @hive_applications.each do |app|
      #
      #   if app.api_key == @carmmunicate_key
      #
      #     p "query detail info of carmunicate"
      #
      #     topics_by_places = [ ]
      #     @CMlatestTopics = [ ]
      #     @CMlatestTopicUser = [ ]
      #
      #     @placesMap.map{|f|
      #       topics_by_places.push(f.topics.where(hiveapplication_id: app.id).last)
      #     }
      #
      #       topics_by_places.each do |t|
      #         if t.present?
      #           @CMlatestTopics.push(t)
      #         end
      #       end
      #
      #       @CMlatestTopics.each do |t|
      #         @CMlatestTopicUser.push(t.username)
      #       end
      #
      #   end
      #
      #   if app.api_key == @meal_key
      #     p "query detail info of meal box"
      #
      #     topics_by_places = [ ]
      #     @MBlatestTopics = [ ]
      #     @MBlatestTopicUser = [ ]
      #
      #     @placesMap.map{|f|
      #       topics_by_places.push(f.topics.where(hiveapplication_id: app.id).last)
      #     }
      #
      #     topics_by_places.each do |t|
      #       if t.present?
      #         @MBlatestTopics.push(t)
      #       end
      #     end
      #
      #     @MBlatestTopics.each do |t|
      #       @MBlatestTopicUser.push(t.username)
      #     end
      #
      #   end
      #
      #   if app.api_key == @favr_key
      #     p "query detail info of favr"
      #
      #     topics_by_places = [ ]
      #     @FVlatestTopics = [ ]
      #     @FVlatestTopicUser = [ ]
      #
      #     @placesMap.map{|f|
      #       topics_by_places.push(f.topics.where(hiveapplication_id: app.id).last)
      #     }
      #
      #     topics_by_places.each do |t|
      #       if t.present?
      #         @FVlatestTopics.push(t)
      #       end
      #     end
      #
      #     @FVlatestTopics.each do |t|
      #       @FVlatestTopicUser.push(t.username)
      #     end
      #
      #   end
      #
      #   if app.api_key == @socal_key
      #     p "query detial info of socal"
      #
      #     topics_by_places = [ ]
      #     @SClatestTopics = [ ]
      #     @SClatestTopicUser = [ ]
      #
      #     @placesMap.map{|f|
      #       topics_by_places.push(f.topics.where(hiveapplication_id: app.id).last)
      #     }
      #
      #     topics_by_places.each do |t|
      #       if t.present?
      #         @SClatestTopics.push(t)
      #       end
      #     end
      #
      #     @SClatestTopics.each do |t|
      #       @SClatestTopicUser.push(t.username)
      #     end
      #
      #
      #   end
      #
      #   if app.api_key == @round_key
      #     p "query detial info of socal"
      #
      #     topics_by_places = [ ]
      #     @RTlatestTopics = [ ]
      #     @RTlatestTopicUser = [ ]
      #
      #     @placesMap.map{|f|
      #       topics_by_places.push(f.topics.where(hiveapplication_id: app.id).last)
      #     }
      #
      #     topics_by_places.each do |t|
      #       if t.present?
      #         @RTlatestTopics.push(t)
      #       end
      #     end
      #
      #
      #     @RTlatestTopics.each do |t|
      #       @RTlatestTopicUser.push(t.username)
      #     end
      #
      #
      #   end
      #
      #   if app.api_key == @hive_key
      #
      #   topics_by_places = [ ]
      #   @latestTopics = [ ]
      #   @latestTopicUser = [ ]
      #
      #   @placesMap.map{|f|
      #     topics_by_places.push(f.topics.where(hiveapplication_id: app.id).last)
      #   }
      #
      #     topics_by_places.each do |t|
      #       if t.present?
      #         @latestTopics.push(t)
      #       end
      #     end
      #
      #     @latestTopics.each do |t|
      #       @latestTopicUser.push(t.username)
      #     end
      #
      #     p "query detial info of hive"
      #   end
      # end


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
     #gon.watch.newplaces = @placesMap
     gon.places =  @placesMap.as_json
     gon.latestTopicUser = @latestTopicUser
     gon.latestTopics = @latestTopics
   end

   private

   def special_layout
     # Check if logged in, because current_user could be nil.
     # "special_layout"
     "special_layout"
   end

end
