class Api::DownloaddataController < ApplicationController


  def initial_retrieve
    if params[:app_key].present?
      hiveApplication = HiveApplication.find_by_api_key(params[:app_key])

      params[:radius].present? ? radius = params[:radius] : radius = nil

      topics = Place.nearest_topics_within(params[:latitude], params[:longitude], radius)

      if params[:most_popular_post].present?
       popular_post = 1
      end

      if params[:newest_post].present?
       newest_post = 1
      end

      if params[:num_posts].present?
         num_posts =   params[:num_posts].to_i
      else
        num_posts = 0
      end
      if hiveApplication.present?
        if newest_post == 1 and   popular_post ==1
          render json: { topics: JSON.parse(topics.to_json(latest_post: newest_post, popular_post: popular_post, num_posts: num_posts))}
        elsif   newest_post == 1 and   popular_post ==0
          render json: { topics: JSON.parse(topics.to_json(latest_post: newest_post, num_posts: num_posts))}
        elsif newest_post == 0 and   popular_post ==1
          render json: { topics: JSON.parse(topics.to_json(popular_post: popular_post, num_posts: num_posts))}
        else
          render json: { topics: JSON.parse(topics.to_json(num_posts: num_posts))}
        end
      else
        render json: { status: false }
      end
    end
  end

  def retrieve_hiveapplications
    render json: {apps: HiveApplication.all.to_json(:test => "true") }
  end

  def retrieve_users
    userArray = [ ]
    userInfo = [ ]

    if params[:user_ids].present?
      userArray = params[:user_ids].split(",")

      User.where(id: userArray).each do |user|
        likedTopicArray = [ ]
        likedPostArray = [ ]
        liked_topics = ActionLog.where(type_name: "topic", action_type: "like", action_user_id: user.id)
        liked_posts = ActionLog.where(type_name: "post", action_type: "like", action_user_id: user.id)

        liked_topics.map { |lt| likedTopicArray.push(lt.type_id) } if liked_topics.present?
        liked_posts.map { |lp| likedPostArray.push(lp.type_id) } if liked_posts.present?

        userData = {
            user_id: user.id,
            username: user.username,
            liked_topics: likedTopicArray,
            liked_posts: likedPostArray
        }
        userInfo.push(userData)
      end

      render json: { users: userInfo }
    else
      render json: { status: false }
    end
  end

end
