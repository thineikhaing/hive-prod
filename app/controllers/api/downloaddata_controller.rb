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

      topics_array=[]
      topics.each do |t|
        #post_info = t.get_post_info(popular_post, newest_post, num_post)
        if newest_post == 1 and   popular_post ==1
          if num_posts>0
            topics_array.push({topic: t, newest_post: t.get_newest_post, popular_post: t.get_popular_post, posts: t.get_post_info(num_posts)} )
          else
            topics_array.push( {topic: t, newest_post: t.get_newest_post, popular_post:get_popular_post})
          end
        elsif   newest_post == 1 and   popular_post ==0
          if num_posts>0
            topics_array.push({topic: t, newest_post: t.get_newest_post, posts: t.get_post_info(num_posts)})
          else
            topics_array.push({topic: t, newest_post: t.get_newest_post})
          end
        elsif newest_post == 0 and   popular_post ==1
          if num_posts>0
            topics_array.push({topic: t, popular_post: t.get_popular_post, posts: t.get_post_info(num_posts)})
          else
            topics_array.push({topic: t, popular_post: t.get_popular_post})
          end
        else
          if num_posts>0
            topics_array.push( {topic: t, posts: t.get_post_info(num_posts)} )
          else
            topics_array.push({topic: t} )
          end
        end
      end

      if hiveApplication.present?
        render json: { topics: topics_array}
      else
        render json: { status: false }
      end
    end
  end

  def retrieve_hiveapplications
    render json: {apps: HiveApplication.all.to_json(:test => "true") }
  end
end
