class Api::PostsController < ApplicationController
  def create
    if current_user.present?
      topic = Topic.find(params[:topic_id].to_i)
      if  topic.hiveapplication_id!=1
        data = getHashValuefromString(params[:data]) if params[:data].present?


            #get all extra columns that define in app setting
        appAdditionalField = AppAdditionalField.where(:app_id => topic.hiveapplication_id, :table_name => "Post")
        if appAdditionalField.present?
          defined_Fields = Hash.new
          appAdditionalField.each do |field|
            defined_Fields[field.additional_column_name] = nil
          end
          #get all extra columns that define in app setting against with the params data
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
        p result
        post = Post.create(content: params[:post], post_type: params[:post_type],  topic_id: params[:topic_id], user_id: current_user.id, data: result) if params[:post_type] == Post::TEXT.to_s

      else
        post = Post.create(content: params[:post], post_type: params[:post_type],  topic_id: params[:topic_id], user_id: current_user.id) if params[:post_type] == Post::TEXT.to_s
      end

      if topic.hiveapplication_id ==1 #Hive Application
        post.broadcast_hive
      else
        post.broadcast_hive
        post.broadcast_other_app
      end
      render json: { post: post}
    end
  end

  def retrieve_post
    if params[:app_key].present? && params[:topic_id].present?
      application_id = HiveApplication.find_by_api_key(params[:app_key])
      if application_id.present?
        topic = Topic.find(params[:topic_id])
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
        render json: { status: false}
      end
    else
      render json: { status: false}
    end
  end
end
