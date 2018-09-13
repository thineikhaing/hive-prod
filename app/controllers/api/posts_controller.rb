class Api::PostsController < ApplicationController

  def create
    if current_user.present?
      topic = Topic.find_by_id(params[:topic_id].to_i)
      if topic.present?
        if check_banned_profanity(params[:post])
          user = User.find_by_id(current_user.id)
          user.profanity_counter += 1
          user.offence_date = Time.now
          user.save!
        end

        data = getHashValuefromString(params[:data]) if params[:data].present?

        place_id = nil
        #check the place_id presents
        if params[:place_id].present?
          place_id = params[:place_id].to_i
        else
          #create place first if the place_id is null
          place = Place.create_place_by_lat_lng(params[:latitude], params[:longitude],current_user)
          if place.present?
            place_id = place.id
            Checkinplace.create(place_id: place.id, user_id: current_user.id)
          end
        end

        #get all extra columns that define in app setting
        appAdditionalField = AppAdditionalField.where(:app_id => topic.hiveapplication_id, :table_name => "Post")
        if appAdditionalField.present?

          defined_Fields = Hash.new
          appAdditionalField.each do |field|
            defined_Fields[field.additional_column_name] = nil
          end

          #compare all extra columns that define in app setting against with the params data
          if data.present?
            data = defined_Fields.deep_merge(data)
            result = Hash.new
            defined_Fields.keys.each do |key|
              result.merge!(data.extract! (key))
            end
          else
            result = defined_Fields
          end
        end

        result = nil unless result.present?

        post = Post.create(content: params[:post],
                           post_type: params[:post_type],
                           topic_id: params[:topic_id],
                           user_id: current_user.id,
                           place_id: place_id, data: result) if params[:post_type] == Post::TEXT.to_s

        if params[:post_type] == Post::IMAGE.to_s  or  params[:post_type] == Post::AUDIO.to_s
          post = Post.create(content: params[:post],
                             post_type: params[:post_type],
                             topic_id: params[:topic_id],
                             user_id: current_user.id,
                             img_url: params[:image_url],
                             width: params[:width],
                             height: params[:height],
                             place_id: place_id,
                             data: result)
          # post.delay.post_image_upload_delayed_job(params[:image_url]) if params[:post_type] == Post::IMAGE.to_s
        end


        if post.present? and params[:notify_topic_owner].present?
          if params[:notify_topic_owner].to_i==1
            if Rails.env.development?
              post.notify_reply_message_to_topic_owner(topic.user_id)
            else
              post.notify_reply_message_to_topic_owner(topic.user_id)
              post.notify_reply_message_to_topic_owner(topic.user_id)
            end
          end
        end
        #else
        #  post = Post.create(content: params[:post], post_type: params[:post_type],  topic_id: params[:topic_id], user_id: current_user.id) if params[:post_type] == Post::TEXT.to_s
        #  post = Post.create(content: params[:post], post_type: params[:post_type],  topic_id: params[:topic_id], user_id: current_user.id, img_url: params[:img_url], width: params[:width], height: params[:height]) if params[:post_type] == IMAGE::TEXT.to_s
        #end
        hiveapplication = HiveApplication.find(topic.hiveapplication_id)
        if topic.hiveapplication_id ==1 #Hive Application
                                        #if hiveapplication.devuser_id == 1
          post.broadcast_hive
        else
          post.broadcast_hive
          post.broadcast_other_app(params[:temp_id])
        end
        render json: { status:200, message: "Post create successfully",post: post,temp_id: params[:temp_id],  profanity_counter: current_user.profanity_counter,posts: topic.posts}
      else
        render json: { status:201, message:"Invalid topic id",error_msg: "Invalid topic id" } , status: 400
      end
    elsif params[:auth_token]
      currentuser = User.find_by_authentication_token(params[:auth_token])
      if currentuser.present?

        temp_id= params[:temp_id]

        if check_banned_profanity(params[:post])
          currentuser.profanity_counter += 1
          currentuser.offence_date = Time.now
          currentuser.save!
        end
        post = Post.new

        post = Post.create(content: params[:post],
                           post_type: params[:post_type],
                           topic_id: params[:topic_id],
                           user_id: currentuser.id,
                           place_id: place_id, data: result) if params[:post_type] == Post::TEXT.to_s

        if params[:post_type] == Post::IMAGE.to_s  or  params[:post_type] == Post::AUDIO.to_s
          post = Post.create(content: params[:post],
                             post_type: params[:post_type],
                             topic_id: params[:topic_id],
                             user_id: currentuser.id,
                             img_url: params[:post],
                             width: params[:width],
                             height: params[:height],
                             place_id: 0,
                             data: nil)
          post.delay.post_image_upload_delayed_job(params[:post]) if params[:post_type] == Post::IMAGE.to_s
        end

        post.broadcast_to_topic(params[:topic_id])
        p 'broadcast_to_topic'

        render json: { status: 200, message:"create topic successfully",post: post, temp_id: params[:temp_id], profanity_counter: currentuser.profanity_counter, offence_date: currentuser.offence_date }

      else
        render json: { status:201, message:"Params user id and/ or  authentication token must be presented", error_msg: "Params user id and/ or  authentication token must be presented" } , status: 400
      end

    else
      render json: { status:201, message: "Params user id and/ or  authentication token must be presented", error_msg: "Params user id and/ or  authentication token must be presented" } , status: 400
    end
  end


  def retrieve_post
    if params[:app_key].present? && params[:topic_id].present?
      application_id = HiveApplication.find_by_api_key(params[:app_key])
      if application_id.present?
        topic = Topic.find_by_id(params[:topic_id])

        if topic.present?
          params[:numPosts].present? ? no_of_posts= params[:numPosts].to_i : no_of_posts=0
          params[:post_id].present? ? post_id= params[:post_id].to_i : post_id=0
          if no_of_posts ==0 && post_id ==0
            #topic.posts.find(:all,:order => "id DESC", :limit => 10)
            posts =  topic.posts.order("id DESC").limit(10)
          elsif no_of_posts > 0 && post_id ==0
            #topic.posts.find(:all,:order => "id DESC", :limit => no_of_posts)
            posts =  topic.posts.order("id DESC").limit(no_of_posts)
          elsif no_of_posts == 0 && post_id > 0
            posts =  topic.posts.where("id < ?", post_id).order("id DESC").limit(10)
          elsif no_of_posts > 0 && post_id > 0
            posts =  topic.posts.where("id < ?", post_id).order("id DESC").limit(no_of_posts)

          end
        end

        post_avatar_url = Hash.new
        posts.each do |post|
          username = post.user.username
          if post.user.avatar_url.url.nil? || post.user.avatar_url.url === "null"
            p "post avatar url"
            p avatar = Topic.get_avatar(username)
            post_avatar_url[post.id] = avatar
          else
            post_avatar_url[post.id] = post.user.avatar_url.url
          end

          #get the post location
        end

        render json: {status:200, message:"Post list",posts: posts,topic:topic,post_avatar_url:post_avatar_url}
      else
        render json: {status: 201, message: "Invalid application key", error_msg: "Invalid application key" }, status: 400
      end
    else
      render json: {status: 201, message: "Params application key and topic id must be presented",error_msg: "Params application key and topic id must be presented" } , status: 400
    end
  end

  def get_avatar(username)
    avatar_url = nil

    #GET AVATAR URL
    #check for special case that cannot match the avatar
    avatar_url = "assets/Avatars/Chat-Avatar-Puppy.png" if(username.index("Snorkie").present?)
    avatar_url = "assets/Avatars/Chat-Avatar-Koala.png" if(username.index("Bear").present?)
    avatar_url = "assets/Avatars/Chat-Avatar-Kitten.png" if(username.index("Cat").present?)
    avatar_url = "assets/Avatars/Chat-Avatar-Kitten.png" if(username.index("Jaguar").present?)
    avatar_url = "assets/Avatars/Chat-Avatar-Kitten.png" if(username.index("Lion").present?)
    avatar_url = "assets/Avatars/Chat-Avatar-Kitten.png" if(username.index("Tiger").present?)
    avatar_url = "assets/Avatars/Chat-Avatar-Admin.png" if(username.index("Raydius GameBot").present?)

    urls = ["assets/Avatars/Chat-Avatar-Chipmunk.png",
            "assets/Avatars/Chat-Avatar-Puppy.png",
            "assets/Avatars/Chat-Avatar-Panda.png",
            "assets/Avatars/Chat-Avatar-Koala.png",
            "assets/Avatars/Chat-Avatar-Husky.png",
            "assets/Avatars/Chat-Avatar-Horse.png",
            "assets/Avatars/Chat-Avatar-Llama.png",
            "assets/Avatars/Chat-Avatar-Aardvark.png",
            "assets/Avatars/Chat-Avatar-Alligator.png",
            "assets/Avatars/Chat-Avatar-Beaver.png",
            "assets/Avatars/Chat-Avatar-Bluebird.png",
            "assets/Avatars/Chat-Avatar-Butterfly.png",
            "assets/Avatars/Chat-Avatar-Eagle.png",
            "assets/Avatars/Chat-Avatar-Elephant.png",
            "assets/Avatars/Chat-Avatar-Giraffe.png",
            "assets/Avatars/Chat-Avatar-Kangaroo.png",
            "assets/Avatars/Chat-Avatar-Monkey.png",
            "assets/Avatars/Chat-Avatar-Swan.png",
            "assets/Avatars/Chat-Avatar-Whale.png",
            "assets/Avatars/Chat-Avatar-Penguin.png",
            "assets/Avatars/Chat-Avatar-Duck.png",
            "assets/Avatars/Chat-Avatar-Admin.png",]
    urls.each do |url|
      if avatar_url.nil?
        url_one = [ ]
        url_one= url.split ('.png')
        url_two = [ ]
        url_two = url_one[0].split('-')
        user_names = username.split (" ")
        last_index = user_names.length
        if user_names[Integer(last_index)-1] == url_two[Integer(url_two.length)-1]
          avatar_url = url
        end
      end
    end

    #if still blank put the default avatar
    if avatar_url.nil?
      avatar_url = "assets/Avatars/Chat-Avatar.png"
    end
    @avatar_url = avatar_url
  end

  def delete
    if params[:app_key].present? and params[:post_id].present?
      hiveapplication = HiveApplication.find_by_api_key(params[:app_key])
      if hiveapplication.present?
        post =  Post.find_by_id(params[:post_id])
        if post.present?
          post.remove_records
          hiveapplication = HiveApplication.find(hiveapplication.id)
          if hiveapplication.id ==1
          #if hiveapplication.devuser_id == 1
            post.delete_event_broadcast_hive
          else
            post.delete_event_broadcast_hive
            post.delete_event_broadcast_other_app
          end

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
          #post.delete_event_broadcast
          topic = Topic.find_by_id(post.topic_id)
          if topic.hiveapplication_id ==1 #Hive Application
                                          #if hiveapplication.devuser_id == 1
            post.delete_event_broadcast_hive
          else
            post.delete_event_broadcast_hive
            post.delete_event_broadcast_other_app
          end

          post.delete

          render json: { status: true }
        else
          render json: { error_msg: "Invalid post id" }, status: 400
        end
      else
        render json: { error_msg: "Invalid application key" } , status: 400
      end
    else
      render json: { error_msg: "Params application key and post id must be presented" }, status: 400
    end
  end

  def post_liked
    if params[:post_id].present? && params[:choice].present?
      post = Post.find_by_id(params[:post_id])
      if post.present?
        action_status = post.user_add_likes(current_user, params[:post_id], params[:choice])
        post.reload

        render json: { post: post, action_status: action_status}
      else
        render json: { error_msg: "Invalid post id" } , status: 400
      end
    else
      render json: { error_msg: "Params post id and choice must be presented" }, status: 400
    end
  end

  def post_offensive
    if params[:post_id].present?
      post = Post.find_by_id(params[:post_id])
      if post.present?
        post.user_offensive_post(current_user, params[:post_id], post)
        post.reload

        render json: { post: post }
      else
        render json: { error_msg: "Invalid post id" }, status: 400
      end
    else
      render json: { error_msg: "Param post id must be presented" }, status: 400
    end
  end

  def posts_by_ids
    if params[:app_key].present? and params[:post_ids].present?
      app = HiveApplication.find_by_api_key(params[:app_key])
      if app.present?
        arr_post_ids = eval(params[:post_ids]) #convert string array into array
        posts = Post.where(:id => arr_post_ids)
        render json: { posts: posts }
      else
        render json: { error_msg: "Invalid application key" }, status: 400
      end
    else
      render json: { error_msg: "Params application key and post id(s) must be presented" } , status: 400
    end
  end

end
