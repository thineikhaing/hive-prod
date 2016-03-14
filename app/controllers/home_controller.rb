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
          redirect_to developer_portal_path
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

  def developer_portal


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

      @placesMap = Place.order("created_at DESC").reload

      lat = params[:cur_lat] if params[:cur_lat].present?
      lng = params[:cur_long] if params[:cur_long].present?

      @hive_applications.each do |app|

        if app.api_key == @carmmunicate_key

          p "query detail info of carmunicate"

          topics_by_places = [ ]
          @CMlatestTopics = [ ]
          @CMlatestTopicUser = [ ]

          if params[:cur_lat].present? &&  params[:api_key] == @carmmunicate_key

            places =  Place.nearest(lat,lng,3)

            if places.present?
              places_id = []
              places.each do |p|
                places_id.push p.id
              end
              p @topics_list = Topic.where(:place_id => places_id,hiveapplication_id:app.id).order("id desc")
              p "carmic topic count"
              p @topics_list.count

              @CMlatestTopics =  @topics_list

             end

          else

            @placesMap.map{|f|
              topics_by_places.push(f.topics.where(hiveapplication_id: app.id).last)
            }

            topics_by_places.each do |t|
              if t.present?
                @CMlatestTopics.push(t)
              end
            end

          end

          if @CMlatestTopics.present?
            @CMlatestTopics.each do |t|
              @CMlatestTopicUser.push(t.username)
            end
          end

        end

        if app.api_key == @meal_key
          p "query detail info of meal box"

          topics_by_places = [ ]
          @MBlatestTopics = [ ]
          @MBlatestTopicUser = [ ]

          if params[:cur_lat].present? &&  params[:api_key] == @meal_key

            places =  Place.nearest(lat,lng,3)

            if places.present?
              places_id = []
              places.each do |p|
                places_id.push p.id
              end
              p @topics_list = Topic.where(:place_id => places_id,hiveapplication_id:app.id).order("id desc")
              p "carmic topic count"
              p @topics_list.count

              @MBlatestTopics =  @topics_list

            end

          else

            @placesMap.map{|f|
              topics_by_places.push(f.topics.where(hiveapplication_id: app.id).last)
            }

            topics_by_places.each do |t|
              if t.present?
                @MBlatestTopics.push(t)
              end
            end

          end

          if @MBlatestTopics.present?
            @MBlatestTopics.each do |t|
              @MBlatestTopicUser.push(t.username)
            end
          end
        end

        if app.api_key == @favr_key
          p "query detail info of favr"

          topics_by_places = [ ]
          @FVlatestTopics = [ ]
          @FVlatestTopicUser = [ ]

          if params[:cur_lat].present? &&  params[:api_key] == @favr_key

            places =  Place.nearest(lat,lng,3)

            if places.present?
              places_id = []
              places.each do |p|
                places_id.push p.id
              end
              p @topics_list = Topic.where(:place_id => places_id,hiveapplication_id:app.id).order("id desc")
              p "carmic topic count"
              p @topics_list.count

              @FVlatestTopics =  @topics_list

            end
          else

            @placesMap.map{|f|
              topics_by_places.push(f.topics.where(hiveapplication_id: app.id).last)
            }

            topics_by_places.each do |t|
              if t.present?
                @FVlatestTopics.push(t)
              end
            end

          end

          if @FVlatestTopics.present?

            @FVlatestTopics.each do |t|
              @FVlatestTopicUser.push(t.username)
            end
          end

        end

        if app.api_key == @socal_key
          p "query detial info of socal"

          topics_by_places = [ ]
          @SClatestTopics = [ ]
          @SClatestTopicUser = [ ]

          if params[:cur_lat].present? &&  params[:api_key] == @socal_key

            places =  Place.nearest(lat,lng,3)

            if places.present?
              places_id = []
              places.each do |p|
                places_id.push p.id
              end
              p @topics_list = Topic.where(:place_id => places_id,hiveapplication_id:app.id).order("id desc")
              p "carmic topic count"
              p @topics_list.count

              @SClatestTopics =  @topics_list

            end
          else

            @placesMap.map{|f|
              topics_by_places.push(f.topics.where(hiveapplication_id: app.id).last)
            }

            topics_by_places.each do |t|
              if t.present?
                @SClatestTopics.push(t)
              end
            end

          end

          if @SClatestTopics.present?
            @SClatestTopics.each do |t|
              @SClatestTopicUser.push(t.username)
            end
          end

        end

        if app.api_key == @round_key
          p "query detial info of socal"

          topics_by_places = [ ]
          @RTlatestTopics = [ ]
          @RTlatestTopicUser = [ ]

          if params[:cur_lat].present? &&  params[:api_key] == @round_key

            places =  Place.nearest(lat,lng,3)

            if places.present?
              places_id = []
              places.each do |p|
                places_id.push p.id
              end
              p @topics_list = Topic.where(:place_id => places_id,hiveapplication_id:app.id).order("id desc")
              p "carmic topic count"
              p @topics_list.count

              @RTlatestTopics =  @topics_list

            end
          else

            @placesMap.map{|f|
              topics_by_places.push(f.topics.where(hiveapplication_id: app.id).last)
            }

            topics_by_places.each do |t|
              if t.present?
                @RTlatestTopics.push(t)
              end
            end

          end

          if @RTlatestTopics.present?
            @RTlatestTopics.each do |t|
              @RTlatestTopicUser.push(t.username)
            end
          end

        end

        if app.api_key == @hive_key

          topics_by_places = [ ]
          @latestTopics = [ ]
          @latestTopicUser = [ ]

          if params[:cur_lat].present? &&  params[:api_key] == @hive_key

            places =  Place.nearest(lat,lng,3)
            if places.present?
              places_id = []
              places.each do |p|
                places_id.push p.id
              end
              p @topics_list = Topic.where(:place_id => places_id,hiveapplication_id:app.id).order("id desc")
              p "carmic topic count"
              p @topics_list.count

              @latestTopics =  @topics_list

            end
          else
            @placesMap.map{|f|
              topics_by_places.push(f.topics.where(hiveapplication_id: app.id).last)
            }

            topics_by_places.each do |t|
              if t.present?
                @latestTopics.push(t)
              end
            end
          end


          if @latestTopics.present?
            @latestTopics.each do |t|
              @latestTopicUser.push(t.username)
            end
          end

          p "query detial info of hive"
        end
      end





      render layout: "special_layout"

    end

  end

   def get_all_topics(lat,lng,hive_id)

     places = Place.nearest(lat,lng,5)
     if places.present?
       places_id = []
       places.each do |p|
         places_id.push p.id
       end
       p @topics_list = Topic.where(:place_id => places_id,hiveapplication_id:hive_id).order("id desc")
       p @total_topic_count = @topics_list = Topic.where(:place_id => places_id).order("id desc")

       # if not @topics_list.nil?
       #   for topic in @topics_list
       #     #getting avatar url
       #     @topic_avatar_url = Hash.new
       #     if topic.offensive < 3 and topic.special_type == 3
       #       @topic_avatar_url[topic.id] = "/assets/Avatars/Chat-Avatar-Admin.png"
       #     else
       #       username = topic.user.username
       #       get_avatar(username)
       #       @topic_avatar_url[topic.id] = request.url.split('?').first + @avatar_url
       #     end
       #   end
       # end

     end
   end


   def get_nearest_user(lat, lng)
     @usersArray = []
     @activeuserRadius = []

     users = User.nearest(lat, lng, 6)
     users =users.where("data -> 'color' != ''")

     users.each do |u|
       if u.check_in_time.present?
         @usersArray.push(u)
       end
     end


     @usersArray.each do |ua|
       user = User.find(ua.id)
       @activeuserRadius.push(user)
     end

     p @us
   end



   def get_all_posts(topicid)
     p "call get all post"
     p @topic_title = Topic.find(topicid).title

     p @topic = Topic.where(id: topicid).first.reload
     p @posts = @topic.posts.includes(:user).sort #limits max 20 posts???
     @post_avatar_url = Hash.new

     @posts.each do |post|
       username = post.user.username
       get_avatar(username)
       p @post_avatar_url[post.id] = request.url.split('?').first + (@avatar_url)
     end

     @topicid = Integer(topicid)

   end

   def map_view
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
       end

       # else
       #   @latestTopicUser.push("nothing")
       # end
     end
     p "detail info"
     gon.places =  @placesMap.as_json
     p "************"
     gon.latestTopicUser = @latestTopicUser

     p gon.latestTopics = @latestTopics

   end


   private

   def special_layout
     # Check if logged in, because current_user could be nil.
     # "special_layout"
     "special_layout"
   end

end
