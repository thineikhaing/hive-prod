class Api::RoundtripController < ApplicationController
  require 'google_maps_service'
  require 'twitter'
  after_action  :set_access_control_headers

  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
  end

  def get_rt_privacy_policy
    if params[:app_key].present?
      hiveapp = HiveApplication.find_by_api_key(params[:app_key])
      pp = PrivacyPolicy.find_by_hiveapplication_id(hiveapp.id)
      title = pp.title rescue ''
      content = pp.content rescue ''
      render json:{status:200, message:"Privacy Policy",title: title,content: content}
    else
      render json:{status:201, message:"Invalid App Key"}
    end
  end

  def save_trip

    route_hash = Hash.new []
    user_id = params[:user_id]
    auth_token = params[:auth_token]
    start_latlng = params[:start_latlng]
    end_latlng = params[:end_latlng]

    s_lat = start_latlng.partition(',').first
    s_lng = start_latlng.partition(',').last
    e_lat = end_latlng.partition(',').first
    e_lng = end_latlng.partition(',').last

    arrival_name = params[:arrival_name]
    depature_name = params[:depature_name]
    source=  params[:source]
    transit_mode = params[:transit_mode]
    depature_time = params[:depature_time].to_datetime
    arrival_time = params[:arrival_time].to_datetime
    fare = params[:fare]
    trip_route = params[:trip_route]
    trip_eta = params[:trip_eta]

    category = ""
    locality=""
    country=""
    postcode=""
    img_url = nil
    choice="others"
    address = ""

    start_id = 0
    end_id = 0
    total_distance = 0.0

 #    ActiveRecord::Base.connection.execute("TRUNCATE TABLE trips
 # RESTART IDENTITY")

    if params[:start_latlng]
      p "start address"
      p s_geo_localization = "#{s_lat},#{s_lng}"
      s_query = Geocoder.search(s_geo_localization).first
      p address = s_query.address
      country = s_query.country
      p "source_id?"
      p s_query.place_id

      s_place = Place.new
      start_place = s_place.add_record(depature_name, s_lat, s_lng, address, 7,
                                       s_query.place_id, nil, user_id, auth_token,
                                       choice,img_url,category,locality,country,postcode)
      p "start place info::::"
      p start_id = start_place[:place].id
    end

    if params[:end_latlng]
      p "end address"
      p e_geo_localization = "#{e_lat},#{e_lng}"
      e_query = Geocoder.search(e_geo_localization).first
      p address = e_query.address
      country = e_query.country
      e_query.place_id

      e_place = Place.new
      end_place = e_place.add_record(arrival_name, e_lat, e_lng, address, 7,
                                     e_query.place_id, nil, user_id, auth_token,
                                     choice,img_url,category,locality,country,postcode)
      p "end end info::::"
      p end_id = end_place[:place].id

    end

    prev_trip = Trip.where(user_id: user_id, start_place_id: start_id, end_place_id:end_id, transit_mode: transit_mode)

    if prev_trip.present?
      user_trips  = Trip.where(user_id: user_id)
      p "Trip already exit"
      render json:{message:"Trip is already exit.", status: 200, trips: user_trips}
    else
      if params[:trip_route].present?
        if source.to_i == Place::ONEMAP
          trip_route = params[:trip_route][:legs]
          trip_route.each do |index,data|
            f_detail =  Hash.new []
            t_detail =  Hash.new []
            distance = data[:distance].to_f
            total_distance = total_distance + distance
            mode = data[:mode]

            from_detail = data[:from]
            from_name = from_detail[:name]
            from_lat = from_detail[:lat]
            from_lng = from_detail[:lon]

            to_detail = data[:to]
            to_name = to_detail[:name]
            to_lat = to_detail[:lat]
            to_lng = to_detail[:lon]

            f_detail.merge!(name: from_name, lat: from_lat, lng: from_lng)
            t_detail.merge!(name: to_name, lat: to_lat, lng: to_lng)

            geo_points = data[:legGeometry][:points]
            short_name = ""
            total_stops = 0

            if data[:mode] != "WALK"
              total_stops = to_detail[:stopSequence].to_i - from_detail[:stopSequence].to_i
              short_name = data[:routeShortName]
              from_stopSequence = from_detail[:stopSequence]
              to_stopSequence = to_detail[:stopSequence]
              f_detail.merge!(stopSequence: from_stopSequence)
              t_detail.merge!(stopSequence: to_stopSequence)
            end

            route_hash[index] = {from:f_detail, to: t_detail,
                                 distance:distance, mode: mode,
                                 geo_point: geo_points,short_name: short_name,
                                 total_stops: total_stops}

          end

        elsif source.to_i == Place::GOOGLE
          trip_route = params[:trip_route][:steps]
          trip_route.each do |index,data|
            f_detail =  Hash.new []
            t_detail =  Hash.new []
            distance = data[:distance][:value].to_f
            total_distance = total_distance + distance
            travel_mode = data[:travel_mode]

            from_detail = data[:start_location]
            from_lat = from_detail[:lat]
            from_lng = from_detail[:lng]

            to_detail = data[:end_location]
            to_lat = to_detail[:lat]
            to_lng = to_detail[:lng]

            f_detail.merge!(lat: from_lat, lng: from_lng)
            t_detail.merge!(lat: to_lat, lng: to_lng)

            geo_points = data[:polyline][:points]
            short_name = ""
            mode = ""
            total_stops = 0

            if travel_mode != "WALKING" && travel_mode != "DRIVING"
              total_stops = data[:transit_details][:num_stops]
              transit_name = data[:transit_details][:line][:name]
              transit_color = data[:transit_details][:line][:color]
              mode = data[:transit_details][:line][:vehicle][:type]

              if mode == "SUBWAY"
                if transit_name == "North South Line"
                  short_name = "NS"
                elsif transit_name == "East West Line"
                  short_name = "EW"
                elsif transit_name == "North Eest Line"
                  short_name = "NE"
                elsif transit_name == "Circle Line"
                  short_name = "CC"
                elsif transit_name == "Downtown Line"
                  short_name = "DT"
                else
                  short_name = "LRT"
                end
              else
                short_name = data[:transit_details][:line][:short_name]
              end
            else
              if travel_mode == "WALKING"
                mode = "WALK"
              else
                mode = "DRIVE"
              end

            end

            route_hash[index] = {from:f_detail, to: t_detail,
                                 distance:distance, mode: mode,
                                 geo_point: geo_points,short_name: short_name,
                                 transit_color:transit_color,total_stops: total_stops}

          end

        end

      end


      tripData = Hash.new
      tripData[:route_detail] = route_hash
      tripData[:source] = source
      tripData[:country] = country
      tripData[:trip_eta] = trip_eta
      total_distance = total_distance.round(2)

      # a.gsub!(/\"/, '\'')
      #eval(a)
      trip = Trip.create(user_id: user_id,start_place_id: start_id,
                         end_place_id: end_id,transit_mode: transit_mode,
                         depature_time: depature_time, arrival_time: arrival_time,
                         distance: total_distance, fare: fare, data: tripData,
                         depart_latlng:start_latlng, arr_latlng: end_latlng,
                         depature_name:depature_name,arrival_name:arrival_name)
      trip = trip.save!

      user_trips  = Trip.where(user_id: user_id)

      if user_trips.count > 11
        ids = user_trips.limit(10).order('id DESC').pluck(:id)
        user_trips.where('id NOT IN (?)', ids).destroy_all
      end

      user_trips  = Trip.where(user_id: user_id)

      trip_detail =  []
      user_trips.each do |trip|
        detail = trip.data["route_detail"]
        trip_detail.push(eval(detail))
      end

      render json:{status: 200,message:"save user trip!", trips: user_trips,trip_detail:trip_detail}

    end

  end

  def get_trip
    trips  = Trip.where(user_id: params[:user_id])
    render json:{status:200, message:"Get user trip",trips:trips}
  end

  def delete_trip
    if current_user.present?
      if params[:id].present?
        trip_to_delete = Trip.find(params[:id])
        if trip_to_delete.present?
          trip_to_delete.destroy
          trips = Trip.where(user_id: params[:user_id])

          trip_detail =  []
          trips.each do |trip|
            detail = trip.data["route_detail"]
            trip_detail.push(eval(detail))
          end

          render json: {status:200, message: "Delete trip by id.", trips: trips,trip_detail:trip_detail}  , status: 200
        end
      elsif params[:ids].present?
        p "selected id to delete"
        p selected_ids = params[:ids].to_a

        for i in 0..selected_ids.count-1
          trip_id = selected_ids[i].to_i
          Trip.find(trip_id).destroy
        end
        trips = Trip.where(user_id: params[:user_id]).order('id DESC')
        trip_detail =  []
        trips.each do |trip|
          detail = trip.data["route_detail"]
          trip_detail.push(eval(detail))
        end

        render json: {status:200, message: "Delete trip by id.", trips: trips,trip_detail:trip_detail}  , status: 200
      end
    else
      render json:{status:201, message: "Params auth_token and user_id must be presented and valid.", error_msg: "Params auth_token and user_id must be presented and valid."} , status: 400
    end
  end

  def transit_annoucement_by_admin
    text = params[:text]
    tags  = []
    station_tags = Hash.new
    station_tags["tags"] = tags
    tweet = Tweet.create(text: params[:text], creator: "Admin",hashtags:station_tags,posted_at:Time.now)
    Pusher["hive_channel"].trigger_async("new_tweet", tweet)
    if params[:shared].to_i == 1
        p "send noti"
        Tweet.send_tweet_noti(tweet)
    end

    render json: {status:200, message: "Created new transit announcement",tweet:tweet}  , status: 200
  end


  def get_smrt_tweets
    transit_annoucement = []
    smrt_tweets = []
    sbs_tweets = []
    nsl_tweets = []
    ewl_tweets = []
    ccl_tweets = []
    nel_tweets = []
    dtl_tweets = []
    lrt_tweets = []
    lta_tweets = []
    bus_tweets = []
    others_tweets = []
    mrt_status = ''
    tweet_counter = 0

    # domain_url = 'https://api.twitter.com'
    # @consumer = OAuth::Consumer.new(Twitter_Config::Consumer_key, Twitter_Config::Consumer_secret, {:site=> domain_url})
    # accesstoken = OAuth::AccessToken.new(@consumer, Twitter_Config::Access_token, Twitter_Config::Access_token_secret)
    # smrt_request = accesstoken.request(:get, "https://api.twitter.com/1.1/search/tweets.json?from=SMRT_Singapore&result_type=recent").body
    # sbs_request = accesstoken.request(:get, "https://api.twitter.com/1.1/search/tweets.json?from=SBSTransit_Ltd&result_type=recent").body
    # smrt_results= JSON.parse(smrt_request)
    # sbs_results = JSON.parse(sbs_request)
    # smrt_recent_tweet = smrt_results["statuses"]
    # sbs_recent_tweet = sbs_results["statuses"]

    smrt_client = $twitter_client.search("from:SMRT_Singapore", result_type: "recent")
    sbs_client = $twitter_client.search("from:SBSTransit_Ltd", result_type: "recent")

    smrt_client.collect do |tweet|
    # Tweet.expiring_soon.where(creator: "SMRT_Singapore").order("created_at desc").collect do |tweet|
      text = tweet.text
      if text.downcase.include?("wishing") || text.downcase.include?("watch")|| text.downcase.include?("love")|| text.downcase.include?("join us") || text.downcase.include?("our bus guides")|| text.downcase.include?("enjoy")|| text.downcase.include?("happy")
        # p "found non alert"
      else
        tweet_counter = tweet_counter + 1
        smrt_tweets.push(tweet)

        created_at = tweet.created_at.dup.localtime.strftime("%b-%d %I:%M%p %a")
        p "hashtag ++++"
        p hashtags = tweet.hashtags
        tags  = []
        hashtags.each do |tag|
          tags.push(tag.text)
        end
        if((Date.today-20.days)) <= Date.parse(created_at)
          topic_id = 0
          post_count = 0
          tweet_topic = Topic.find_by_title(text)
          if tweet_topic.present?
            topic_id = tweet_topic.id
            topic_posts = Post.where(topic_id: topic_id)
            post_count = topic_posts.count
          end

          header = "MRT"
          mrt_status = 'last'
          if text.downcase.include?("update")
            mrt_status = 'update'
            header = 'MRT (UPDATE)'
          elsif text.downcase.include?("cleared")
            mrt_status = 'cleared'
            header = 'MRT (ClEARED)'
          elsif text.downcase.include?("alert")
            mrt_status = 'alert'
            header = 'MRT (ALERT)'
          end

          if text.downcase.include?("nsl") || text.downcase.include?("north-south")
            line_color = "#d32f2f"
            nsl_tweets.push({id: tweet_counter,header: header,text: text, created_at: tweet.created_at,name: "SMRT Transit",topic_id: topic_id,post_count: post_count,line_color:line_color,mrt_status:mrt_status})
          elsif text.downcase.include?("ewl") || text.downcase.include?("east-west")
            line_color = "#189e4a"
            ewl_tweets.push({id: tweet_counter,header: header,text: text, created_at: tweet.created_at,name: "SMRT Transit",topic_id: topic_id,post_count: post_count,line_color:line_color,mrt_status:mrt_status})
          elsif text.downcase.include?("ccl")
            line_color = "#FF9900"
            ccl_tweets.push({id: tweet_counter,header: header,text: text, created_at: tweet.created_at,name: "SMRT Transit",topic_id: topic_id,post_count: post_count,line_color:line_color,mrt_status:mrt_status})
          elsif text.downcase.include?("lrt")
            line_color = "gray"
            lrt_tweets.push({id: tweet_counter,header: header,text: text, created_at: tweet.created_at,name: "SMRT Transit",topic_id: topic_id,post_count: post_count,line_color:line_color,mrt_status:mrt_status})
          else
            line_color = "#5f57ba"
            others_tweets.push({id: tweet_counter,header: header,text: text, created_at: tweet.created_at,name: "SMRT Transit",topic_id: topic_id,post_count: post_count,line_color:line_color,mrt_status:mrt_status})
          end

          tweet_data = {id: tweet_counter,header: header,text: text, created_at: tweet.created_at,name: "SMRT Transit",topic_id: topic_id,post_count: post_count,line_color:line_color,mrt_status:mrt_status}
          transit_annoucement.push(tweet_data)
        end
      end

    end

    Tweet.expiring_soon.where(creator: "Admin").order("created_at desc").collect do |tweet|

      tweet_counter = tweet_counter + 1
      text = tweet.text
      topic_id = 0
      post_count = 0
      tweet_topic = Topic.find_by_title(text)
      if tweet_topic.present?
        topic_id = tweet_topic.id
        topic_posts = Post.where(topic_id: topic_id)
        post_count = topic_posts.count
      end
      if text.downcase.include?("train") || text.downcase.include?("ewl") || text.downcase.include?("nel") || text.downcase.include?("ccl") || text.downcase.include?("dtl") || text.downcase.include?("nel") || text.downcase.include?("lrt")
        header = "MRT"
        mrt_status = 'last'
        if text.downcase.include?("update")
          mrt_status = 'update'
          header = 'MRT (UPDATE)'
        elsif text.downcase.include?("cleared")
          mrt_status = 'cleared'
          header = 'MRT (ClEARED)'
        elsif text.downcase.include?("alert")
          mrt_status = 'alert'
          header = 'MRT (ALERT)'
        end

        if text.downcase.include?("nsl")
          line_color = "#d32f2f"
          nsl_tweets.push({id: tweet_counter,header: header,text: text, created_at: tweet.created_at,name: "Admin",topic_id: topic_id,post_count: post_count,line_color:line_color,mrt_status:mrt_status})
        elsif text.downcase.include?("ewl") || text.downcase.include?("east-west")
          line_color = "#189e4a"
          ewl_tweets.push({id: tweet_counter,header: header,text: text, created_at: tweet.created_at,name: "Admin",topic_id: topic_id,post_count: post_count,line_color:line_color,mrt_status:mrt_status})
        elsif text.downcase.include?("ccl")
          line_color = "#FF9900"
          ccl_tweets.push({id: tweet_counter,header: header,text: text, created_at: tweet.created_at,name: "Admin",topic_id: topic_id,post_count: post_count,line_color:line_color,mrt_status:mrt_status})
        elsif text.downcase.include?("lrt")
          line_color = "gray"
          lrt_tweets.push({id: tweet_counter,header: header,text: text, created_at: tweet.created_at,name: "Admin",topic_id: topic_id,post_count: post_count,line_color:line_color,mrt_status:mrt_status})
        elsif text.downcase.include?("dtl")
          line_color = "#0e56a3"
          dtl_tweets.push({id: tweet_counter,header:header,text: text, created_at: tweet.created_at,name: "Admin",topic_id: topic_id,post_count:post_count,line_color:line_color,mrt_status:mrt_status})
        elsif text.downcase.include?("nel")
          line_color = "purple"
          nel_tweets.push({id: tweet_counter,header:header,text: text, created_at: tweet.created_at,name: "Admin",topic_id: topic_id,post_count:post_count,line_color:line_color,mrt_status:mrt_status})
        else
          line_color = "#5f57ba"
          others_tweets.push({id: tweet_counter,header: header,text: text, created_at: tweet.created_at,name: "Admin",topic_id: topic_id,post_count: post_count,line_color:line_color,mrt_status:mrt_status})
        end

      elsif text.downcase.include?("svcs") || text.downcase.include?("svc") || text.downcase.include?("services") || text.downcase.include?("service")

        tweet_text = text.to_s
        if text.downcase.include?("svcs")
          service_header = tweet_text.downcase.partition("svcs").last
        elsif text.downcase.include?("svc")
          service_header = tweet_text.downcase.partition("svc").last
        elsif text.downcase.include?("services")
          service_header = tweet_text.downcase.partition("services").last
        elsif text.downcase.include?("service")
          service_header = tweet_text.downcase.partition("service").last
        end

        if text.downcase.include?("to operate")
          service_no =   service_header.partition(" to operate ").first
        elsif text.downcase.include?("under the")
          service_no =   service_header.partition(" under the ").first
        elsif text.downcase.include?("(towards")
          service_no =   service_header.partition(" (towards ").first
        elsif text.downcase.include?("to skip")
          service_no =   service_header.partition(" to skip ").first
        elsif text.downcase.include?("heading towards")
          service_no =   service_header.partition(" heading towards ").first
        elsif text.downcase.include?("continues to")
          service_no =   service_header.partition(" continues to ").first
        elsif text.downcase.include?("is still")
          service_no =   service_header.partition(" is still ").first
        elsif text.downcase.include?("is being diverted")
          if text.downcase.include?("from")
            service_no =   service_header.partition(" from ").first
          else
            service_no =   service_header.partition(" is being diverted ").first
          end
        elsif text.downcase.include?("will call at a pair")
          service_no =   service_header.partition(" will call at a pair ").first
        elsif text.downcase.include?("along")
          if text.downcase.include?("are delayed")
            service_no =   service_header.partition(" are delayed ").first
          elsif text.downcase.include?("(loop service) will be")
            service_no =  service_header.partition(" (loop service) will be ").first
          elsif text.downcase.include?("will be diverted")
            service_no =   service_header.partition("will be diverted").first
          elsif text.downcase.include?("will skip")
            service_no =   service_header.partition("will skip").first
          else
            service_no =   service_header.partition(" along ").first
          end
        elsif text.downcase.include?("are delayed")
          service_no =   service_header.partition(" are delayed ").first
        elsif text.downcase.include?("is back to")
          service_no =   service_header.partition(" is back to ").first
          if text.downcase.include?("along")
            service_no =   service_header.partition(" along ").first
          end
        elsif text.downcase.include?("are back to")
          service_no =   service_header.partition(" are back to ").first
        elsif text.downcase.include?("will be diverted")
          service_no =   service_header.partition(" will be diverted ").first
        elsif text.downcase.include?("will skip")
          service_no =   service_header.partition(" will skip ").first
        elsif text.downcase.include?("which plies")
          service_no =   service_header.partition(", which plies ").first
        elsif text.downcase.include?("has also been affected")
          service_no =   service_header.partition(" has also been affected ").first
        elsif text.downcase.include?("will be withdrawn")
          service_no =   service_header.partition(" will be withdrawn ").first
        elsif text.to_s.downcase.include?("https://")
          service_no =   service_header.partition("https://").first
        else
          service_no = " "+service_header.split(/[^\d]/).join
        end

         header = "SERVICE " + service_no
         header = header.upcase
         line_color = "#22b5d0"
         bus_tweets.push({id: tweet_counter,header:header,text: text, created_at: tweet.created_at,name: "Admin",topic_id: topic_id,post_count:post_count,line_color:line_color,mrt_status:""})
       else
         header = "ANNOUNCEMENT"
         line_color = "#5f57ba"
      end

      tweet_data = {id: tweet_counter,header: header,text: text, created_at: tweet.created_at,name: "Admin",topic_id: topic_id,post_count: post_count,line_color:line_color,mrt_status:mrt_status}
      transit_annoucement.push(tweet_data)

    end


    sbs_client.collect do |tweet|
    # Tweet.expiring_soon.where(creator: "SBSTransit_Ltd").order("created_at desc").collect do |tweet|
      mrt_status = ""

      check_retweet = tweet.retweeted_status.text.to_s
      if check_retweet === ""
        text = tweet.text
      else
        text = tweet.retweeted_status.text
      end

      if text.downcase.include?("wishing") || text.downcase.include?("watch")|| text.downcase.include?("love")|| text.downcase.include?("join us") || text.downcase.include?("our bus guides") || text.downcase.include?("enjoy")
        # p "found non alert"
      else
        tweet_counter = tweet_counter + 1
        sbs_tweets.push(tweet)
        created_at = tweet.created_at.dup.localtime.strftime("%b-%d %I:%M%p %a")
        hashtags = tweet.hashtags
        tags  = []
        hashtags.each do |tag|
          tags.push(tag.text)
        end
        if((Date.today-20.days)) <= Date.parse(created_at)
          topic_id = 0
          post_count = 0
          tweet_topic = Topic.find_by_title(text)
          if tweet_topic.present?
            topic_id = tweet_topic.id
            topic_posts = Post.where(topic_id: topic_id)
            post_count = topic_posts.count
          end

          header = ""

          if text.downcase.include?("svcs") || text.downcase.include?("svc") || text.downcase.include?("services") || text.downcase.include?("service")
            tweet_text = text.to_s
            if text.downcase.include?("svcs")
              service_header = tweet_text.downcase.partition("svcs").last
            elsif text.downcase.include?("svc")
              service_header = tweet_text.downcase.partition("svc").last
            elsif text.downcase.include?("services")
              service_header = tweet_text.downcase.partition("services").last
            elsif text.downcase.include?("service")
              service_header = tweet_text.downcase.partition("service").last
            end

            service_no = ""
            if text.downcase.include?("to operate")
              service_no =   service_header.partition(" to operate ").first
            elsif text.downcase.include?("under the")
              service_no =   service_header.partition(" under the ").first
            elsif text.downcase.include?("(towards")
              service_no =   service_header.partition(" (towards ").first
              if text.downcase.include?("are delayed")
                service_no =   service_header.partition(" are delayed ").first
              end
            elsif text.downcase.include?("to skip")
              service_no =   service_header.partition(" to skip ").first
            elsif text.downcase.include?("heading towards")
              service_no =   service_header.partition(" heading towards ").first
            elsif text.downcase.include?("continues to")
              service_no =   service_header.partition(" continues to ").first
            elsif text.downcase.include?("is still")
              service_no =   service_header.partition(" is still ").first
            elsif text.downcase.include?("is back to")
              service_no =   service_header.partition(" is back to ").first
              if text.downcase.include?("along")
                service_no =   service_header.partition(" along ").first
              end
            elsif text.downcase.include?("is being diverted")
              if text.downcase.include?("from")
                service_no =   service_header.partition(" from ").first
              else
                service_no =   service_header.partition(" is being diverted ").first
              end
            elsif text.downcase.include?("will call at a pair")
              service_no =   service_header.partition(" will call at a pair ").first
            elsif text.downcase.include?("along")
              if text.downcase.include?("are delayed")
                service_no =   service_header.partition(" are delayed ").first
              elsif text.downcase.include?("(loop service) will be")
                service_no =  service_header.partition(" (loop service) will be ").first
              elsif text.downcase.include?("will be diverted")
                service_no =   service_header.partition("will be diverted").first
              elsif text.downcase.include?("will skip")
                service_no =   service_header.partition("will skip").first
              elsif text.downcase.include?("is being diverted")
                service_no =   service_header.partition("is being diverted").first
                if text.downcase.include?("from")
                  service_no =   service_header.partition("from").first
                end
              else
                service_no =   service_header.partition("along").first
              end
            elsif text.downcase.include?("are delayed")
              service_no =   service_header.partition(" are delayed ").first

            elsif text.downcase.include?("are back to")
              service_no =   service_header.partition(" are back to ").first
            elsif text.downcase.include?("will be diverted")
              service_no =   service_header.partition("will be diverted").first
            elsif text.downcase.include?("will skip")
              service_no =   service_header.partition(" will skip ").first
            elsif text.downcase.include?("which plies")
              service_no =   service_header.partition(", which plies ").first
            elsif text.downcase.include?("has also been affected")
              service_no =   service_header.partition(" has also been affected ").first
            elsif text.downcase.include?("will be withdrawn")
              service_no =   service_header.partition(" will be withdrawn ").first
            elsif text.to_s.downcase.include?("https://")
              service_no =   service_header.partition("https://").first
            else
              service_no = " "+service_header.split(/[^\d]/).join
            end

           if service_no === ""
             header = "ANNOUNCEMENT"
           else
             header = "SERVICE" + remove_uris(service_no) #service_header.split(/[^\d]/).join
             header = header.upcase
           end

            line_color = "#22b5d0"
            if text.downcase.exclude?("dtl") && text.downcase.exclude?("lrt") && text.downcase.exclude?("train") && text.downcase.exclude?("nel")
              bus_tweets.push({id: tweet_counter,header:header,text: text, created_at: tweet.created_at,name: "SBS Transit",topic_id: topic_id,post_count:post_count,line_color:line_color,mrt_status:mrt_status})
            end
          end


          if text.downcase.include?("lrt")
              header = "MRT|LRT"
              line_color = "#5f57ba"
              lrt_tweets.push({id: tweet_counter,header:header,text: text, created_at: tweet.created_at,name: "SBS Transit",topic_id: topic_id,post_count:post_count,line_color:line_color,mrt_status:mrt_status})
          end

          if text.downcase.include?("dtl") || text.downcase.include?("expo")
              header = "MRT"
              line_color = "#0e56a3"
              dtl_tweets.push({id: tweet_counter,header:header,text: text, created_at: tweet.created_at,name: "SBS Transit",topic_id: topic_id,post_count:post_count,line_color:line_color,mrt_status:mrt_status})
          end

          if !text.downcase.include?("tunnel") && text.downcase.include?("nel")
            header = "MRT"
            line_color = "purple"
            nel_tweets.push({id: tweet_counter,header:header,text: text, created_at: tweet.created_at,name: "SBS Transit",topic_id: topic_id,post_count:post_count,line_color:line_color,mrt_status:mrt_status})
          end

          if header === ""
            if text.downcase.include?("bus")
                header = "ANNOUNCEMENT"
                line_color = "#22b5d0"
                bus_tweets.push({id: tweet_counter,header:header,text: text, created_at: tweet.created_at,name: "SBS Transit",topic_id: topic_id,post_count:post_count,line_color:line_color,mrt_status:mrt_status})
              else
                header = "ANNOUNCEMENT"
                line_color = "#22b5d0"
                bus_tweets.push({id: tweet_counter,header:header,text: text, created_at: tweet.created_at,name: "SBS Transit",topic_id: topic_id,post_count:post_count,line_color:line_color,mrt_status:mrt_status})
            end

          end

          tweet_data = {id: tweet_counter,header:header,text: text, created_at: tweet.created_at,name: "SBS Transit",topic_id: topic_id,post_count:post_count,line_color:line_color,mrt_status:mrt_status}
          transit_annoucement.push(tweet_data)
        end
      end

    end



    transit_annoucement = transit_annoucement.sort {|x,y| x[:created_at] <=> y[:created_at]}.reverse!

    lta_status = SgAccidentHistory.last(3)
    line_color = "#5f57ba"
    lta_status.each do |data|
      tweet_counter = tweet_counter + 1
      topic_id = 0
      post_count = 0
      tweet_topic = Topic.where(title: data.message, topic_type:10).last


      if tweet_topic.present?
        topic_id = tweet_topic.id
        topic_posts = Post.where(topic_id: topic_id)
        post_count = topic_posts.count
      end

      lta_data = {id: tweet_counter, lta_id: data.id,header:data.type,text: data.message, created_at: data.created_at,hashtags:data.type,name: "LTA",
      topic_id: topic_id, post_count: post_count,line_color:line_color,mrt_status:""}
      transit_annoucement.push(lta_data)
      lta_tweets.push(lta_data)
    end

    lta_tweets = lta_tweets.sort {|x,y| x[:created_at] <=> y[:created_at]}.reverse!
    lrt_tweets = lrt_tweets.sort {|x,y| x[:created_at] <=> y[:created_at]}.reverse!

    # transit_annoucement.push(lta_tweets)
    render json: {
      status: 200,
      message: "Transit Tweet List",
      tweets:transit_annoucement,
      smrt_recent_tweet:smrt_client,
      sbs_recent_tweet:sbs_client,
      bus_tweets:bus_tweets,
      nsl_tweets:nsl_tweets,
      ewl_tweets:ewl_tweets,
      ccl_tweets:ccl_tweets,
      nel_tweets: nel_tweets,
      dtl_tweets: dtl_tweets,
      lta_tweets: lta_tweets,
      lrt_tweets:lrt_tweets,
      others_tweets:others_tweets}  , status: 200
  end

  URI_REGEX = %r"((?:(?:[^ :/?#]+):)(?://(?:[^ /?#]*))(?:[^ ?#]*)(?:\?(?:[^ #]*))?(?:#(?:[^ ]*))?)"

def remove_uris(text)
  text.split(URI_REGEX).collect do |s|
    unless s =~ URI_REGEX
      s
    end
  end.join
end

  def save_user_fav_buses
    if current_user.present?
      service = params[:service]
      busid = params[:busid]
      p check_dup = UserFavBus.where(user_id: current_user.id, service: service, busid: busid)

      if check_dup.empty?
        UserFavBus.create(user_id: current_user.id, service: service, busid: busid)
      end
      favbuses = UserFavBus.where(user_id: current_user.id)
      busstops = []
      favbuses.each do |stop|
        bus = SgBusStop.where(bus_id: stop.busid).take
        format_bus = {id:stop.id, busid: stop.busid, service: stop.service,road_name: bus.road_name, description: bus.description, lat: bus.latitude, lng: bus.longitude}
        busstops.push(format_bus)
      end

      render json:{status:200, message:"Favourite Buses List",favbuses: favbuses, bus_stops: busstops, status: 200}
    else
      render json:{status: 201, message: "unauthorized."}
    end

  end


  def get_user_fav_buses
    if current_user.present?
      if params[:id]
        UserFavBus.delete(params[:id])
      end
      favbuses = UserFavBus.where(user_id: current_user.id)
      busstops = []
      favbuses.each do |stop|
        bus = SgBusStop.where(bus_id: stop.busid).take
        format_bus = {id:stop.id, busid: stop.busid, service: stop.service,road_name: bus.road_name, description: bus.description, lat: bus.latitude, lng: bus.longitude}
        busstops.push(format_bus)
      end
      render json:{status:200, message:"Favourite Buses List",favbuses: favbuses, bus_stops: busstops, status: 200}
    else
      render json:{status: 201, message: "unauthorized."}
    end
  end

  def demo_train_service_alert
    alertHash = Hash.new
    affectedSegments = []
    messages = []

    curTime = Time.now.strftime("%H%M")

  params[:line].present? ? line = params[:line] : line = "NEL"
  params[:towards].present? ? towards = params[:towards] : towards = "HarbourFront"
  params[:stations].present? ? stations = params[:stations] : stations = "NE9, NE8, NE7, NE6"
  params[:free_stations].present? ? free_stations = params[:free_stations] : free_stations = "NE9, NE8, NE7, NE6"
  params[:content].present? ? content = params[:content] : content = curTime+"hrs: NEL - Additional travelling time of 20 miutes between Boon Keng and Dhoby Ghaut stations towards HarbourFront station due to a signal fault."
  params[:status].present? ? t_status = params[:status].to_i : t_status = 2

    segment1 = {
      Line: line,
      Direction: towards,
      Stations: stations,
      FreePublicBus:  free_stations,
      FreeMRTShuttle: free_stations,
      MRTShuttleDirection:towards
    }

    message1 = {
      Content:content,
      CreatedDate: Time.now
    }

    affectedSegments.push(segment1)
    if params[:show_content].to_i == 1
      messages.push(message1)
    end

    alertHash["Status"]= t_status
    alertHash["AffectedSegments"]= affectedSegments
    alertHash["Message"]= messages

    render json:{source: "hive", value: alertHash, status: 200}
end



end
