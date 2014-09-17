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

        post = Post.create(content: params[:post], post_type: params[:post_type],  topic_id: params[:topic_id], user_id: current_user.id, place_id: place_id, data: result) if params[:post_type] == Post::TEXT.to_s
        if params[:post_type] == Post::IMAGE.to_s
          post = Post.create(content: params[:post], post_type: params[:post_type],  topic_id: params[:topic_id], user_id: current_user.id, img_url: params[:img_url], width: params[:width], height: params[:height], place_id: place_id, data: result)
          post.delay.post_image_upload_delayed_job(params[:img_url])
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
        render json: { post: post,temp_id: params[:temp_id],  profanity_counter: current_user.profanity_counter}
      else
        render json: { error_msg: "Invalid topic id" } , status: 400
      end
    else
      render json: { error_msg: "Params user id and/ or  authentication token must be presented" } , status: 400
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
        render json: {posts: posts}
      else
        render json: { error_msg: "Invalid application key" }, status: 400
      end
    else
      render json: { error_msg: "Params application key and topic id must be presented" } , status: 400
    end
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
          #post.delete_event_broadcast
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
