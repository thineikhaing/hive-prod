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

      render json:{status:200, message:"Favourite Buses List",favbuses: favbuses, bus_stops: busstops}
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
      render json:{status:200, message:"Favourite Buses List",favbuses: favbuses, bus_stops: busstops}
    else
      render json:{status: 201, message: "unauthorized."}
    end
  end

  def calculate_transit_fare
      smrt_mrt = params[:smrt_mrt].to_i
      sbs_mrt = params[:sbs_mrt].to_i
      smrt_bus = params[:smrt_bus].to_i
      sbs_bus = params[:sbs_bus].to_i
      price_table = "db/sms-bus-Sep142018.csv"

      total_fare =0.0
      total_distance = (smrt_mrt + sbs_mrt + smrt_bus+sbs_bus) * 0.001
      total_distance = total_distance.round(1)
      if total_distance >= 40.2
        total_fare = 2.02
      elsif total_distance > 0
        CSV.foreach(price_table) do |row|
          range = row[0]
          num1= range.match(",").pre_match.to_f
          num2= range.match(",").post_match.to_f

          if total_distance.between?(num1,num2)
            "total fare"
            total_fare =  (row[1].to_i* 0.01)
          end
        end
      end

    render json:{status: 200, message: "fare", fare:total_fare.round(2)}
  end

  def calculate_taxi_rate_api
    total_distance_km = params[:distance].to_i
    total_duration_min  = params[:duration]
    p "depature"
    depature = params[:depature]
    params[:depature].present? ? depature = params[:depature] : depature = params[:departure]
    p depature= depature.downcase!
    distance = total_distance_km - 1
    total_time = total_duration_min

    flat_rate = 3.2
    firstmeter = 0
    secondmeter = 0

    short_d_fare = 0
    if (distance <= 0)
      p "distance less than 1km"
       distance = 0.9
      short_d_fare = (0.55 * distance).round(2)
    end

    if (distance >= 1)
      firstmeter =  0.55                # (0.22 for every 400 m | 0.55 per km thereafter or less > 1 km and ≤ 10 km)
    end

    if (distance > 10)
      secondmeter = 0.63                # (0.22 for every 350 m | 0.63 per km thereafter or less > 10 km)
    end

    waiting_rate = 0.30               # (0.22 every 45 seconds or less | 0.30 per min)
    peekhour = 0.25                   # 25% of metered fare (Monday to Friday 0600 - 0930 and 1800 – 0000 hours)
    public_holiday = 0.25             # 25% of metered fare
    late_night = 0.5                  # 50% of metered fare (0000 – 0559 hours)

    # location
    changi_airport_friday_to_Sunday = 5 # (Singapore Changi Airport: Friday - Sunday from 1700 to 0000 hours)
    changi_airport = 3
    seletar_airport = 3                   # (Seletar Airport)
    sentosa = 3                           # S$3.00 (Resorts World Sentosa)
    expo = 2                              # S$2.00 (Singapore Expo)
    waiting_min = total_distance_km/2       # for 10 km waiting time is 5mins

    today = Time.new

    morning_t1 = Time.parse('06:00')
    morning_t2 = Time.parse('09:30')
    evening_t1 = Time.parse('18:00')
    evening_t2 = Time.parse('00:00')
    late_t1  = Time.parse('00:00')
    late_t2  = Time.parse('05:59')

    changi_t1 = Time.parse('17:00')
    changi_t2 = Time.parse('00:00')

    first_10km = 0.0,rest_km =0.0

    net_meterfare= 0.0,  waiting_charge= 0.0,
    peekhour_charge = 0.0 , latehour_charge = 0.0 , pbHoliday_charge= 0.0, location_charge=0.0

    if distance > 0
      p "first 10 km"
      p first_10km = (distance + 1) * firstmeter

      if distance > 10
        p "rest meter"
        restmeter = distance - 10 +1
        p rest_km = restmeter * secondmeter
      end

      # sum of the first 10 km and rest km for net meter fare
      p "net meter fare"
      p net_meterfare = (short_d_fare + first_10km + rest_km).round(2)

      # calculate charge for waiting time in traffic
      waiting_charge = (waiting_min * waiting_rate).round(2)


      # calculate charge for peek hours
      if !(today.saturday? || today.sunday?)
        p "it's weekdays"
        if today.to_f > morning_t1.to_f and today.to_f < morning_t2.to_f
          p "time is between morning peekhour"
          p peekhour_charge = net_meterfare * peekhour
        end
      end

      if  today.to_f > evening_t1.to_f and today.to_f < evening_t2.to_f
        p "time is between evening peekhour"
        p peekhour_charge = net_meterfare * peekhour
      end


      # calculate charge for late night

      if  today.to_f > late_t1.to_f and today.to_f < late_t2.to_f
        p "calculate charge for late night"
        latehour_charge = net_meterfare * late_night
      end


      # calculate charge for holidays
      publicH = Holidays.on(today, :sg)

      if publicH.count == 1
        p "calculate charge for holidays"
        pbHoliday_charge = net_meterfare * public_holiday
      end

      # calculate charge based on location

      if depature.include?('seletar') ||  depature.include?('sentosa') ||  depature.include?('resorts world')
        location_charge = 3
      end

      if depature.include?('expo')
        location_charge = 2
      end

      if depature.include?('changi') ||  depature.include?('terminal') ||  depature.include?('airport')

        if today.friday? || today.saturday? || today.sunday?
          p "today is friday to sunday"
          if  today.to_f > changi_t1.to_f and today.to_f < changi_t2.to_f
            location_charge = 5
          else
            location_charge = 3
          end

        else
          p "not friday nor sunday"
          p location_charge = 3
        end
      end

      p total_estimated_fare = (flat_rate + net_meterfare + waiting_charge +  peekhour_charge + latehour_charge + pbHoliday_charge + location_charge).round(2)


      render json:{total_estimated_fare: total_estimated_fare} , status: 200
    end

  end

  def search_busstop
    if params[:search_string]
      search_string = params[:search_string]
      if search_string.numeric?
        results = SgBusStop.where("(bus_id::text LIKE ?)", "#{search_string}%").all
      else
        results = SgBusStop.where("(lower(description) LIKE ?)", "%#{search_string.downcase}%").all
      end

      render json: {status:200, message:"Search Result",results: results}

    end
  end

  def nearest_busstop_within
    nearby_buses = []
    radius= params[:radius]
    latitude = params[:latitude]
    longitude = params[:longitude]
    radius = 1 if radius.nil?
    center_point = [latitude.to_f, longitude.to_f]
    box = Geocoder::Calculations.bounding_box(center_point, radius, {units: :km})
    sgbusStops = SgBusStop.where(latitude: box[0] .. box[2], longitude: box[1] .. box[3])
    busInfos = Hash.new
    sgbusStops.each do |stop|
      busRoute = SgBusRoute.where(bus_stop_code: stop.bus_id)
      buses = []
      buses_num = []
      buses_char = []
      busRoute.each do |route|
        if is_numeric? route.service_no
          buses_num.push(route.service_no)
        else
          buses_char.push(route.service_no)
        end

      end
      buses_num = buses_num.map(&:to_i).sort
      buses = buses_num + buses_char
      busInfos = {stop: stop, buses:buses}
      nearby_buses.push(busInfos)

    end
    render json: {busStops: nearby_buses}

  end

  def get_bus_arrivaltime
    tempnextBus = Hash.new
    tempwaitTime = Hash.new
    service = params[:service]
    bus_id = params[:bus_id]

    busLat = "%.5g" % params[:latitude].to_f
    busLng = "%.5g" % params[:longitude].to_f

    if params[:latitude] and params[:longitude]
      busstops = SgBusStop.where(description: params[:name])
      if busstops.count == 1
        bLat = "%.5g" % busstops.take.latitude.to_f
        bLng = "%.5g" % busstops.take.longitude.to_f
        if (busLat == bLat and busLng == bLng)
          p "found bus stop"
          bus_id = busstops.take.bus_id
        end

      else
        busstops.each do |stop|
          lat = "%.5g" % stop.latitude.to_f
          lng = "%.5g" % stop.longitude.to_f
          if (busLat == lat and busLng == lng)
            bus_id = stop.bus_id
          end
        end
      end

    end

    if bus_id.nil?
      busstops = SgBusStop.all
      busstops.each do |stop|
        lat = "%.5g" % stop.latitude.to_f unless stop.latitude.nil?
        lng = "%.5g" % stop.longitude.to_f unless stop.longitude.nil?
        if (busLat == lat and busLng == lng)
          bus_id = stop.bus_id
        end
      end
    end

    p "BUS STOP ID:::"
    p bus_id
    p service

    uri = URI('http://datamall2.mytransport.sg/ltaodataservice/BusArrivalv2')
    params = { :BusStopCode => bus_id, :ServiceNo => service, :SST => true}
    uri.query = URI.encode_www_form(params)
    res = Net::HTTP::Get.new(uri,
                             initheader = {"accept" =>"application/json", "AccountKey"=>"4G40nh9gmUGe8L2GTNWbgg==",
                                           "UniqueUserID"=>"d52627a6-4bde-4fa1-bd48-c6270b02ffc0"})
    con = Net::HTTP.new(uri.host, uri.port)
    r = con.start {|http| http.request(res)}
    response_data = JSON.parse(r.body)

    results = response_data["Services"]
    busStopCode = response_data["BusStopCode"]

    bus_route_info = SgBusRoute.where(service_no: service, bus_stop_code:bus_id).take

    if results.present?

      nextBus = results[0]["NextBus"]
      origin_code = nextBus["OriginCode"]
      destination_code  = nextBus["DestinationCode"]

      bus_service = SgBusService.where(service_no: service, origin_code: origin_code, destination_code: destination_code).take
      if bus_service.nil?
        bus_service = SgBusService.where(service_no: service, destination_code: destination_code).take
      end
      if bus_service.nil?
        bus_service = SgBusService.where(service_no: service, origin_code: origin_code).take
      end

      bus_freq_interval = "-"

      if !bus_service.nil?
        formatted_time = Time.now.getlocal('+08:00').strftime("%H:%M")

        allowed_ranges = [
            "06:30".."08:30",
            "08:31".."16:59",
            "17:00".."19:00",
            "19:01".."06:29"
        ]

        allowed_ranges.each_with_index{ |range,i|
          if range.cover?(formatted_time)
            p range
            bus_freq_interval = bus_service.am_peak_freq if i==0
            bus_freq_interval = bus_service.am_offpeak_freq if i==1
            bus_freq_interval = bus_service.pm_peak_freq if i==2
            bus_freq_interval = bus_service.pm_offpeak_freq if i==3
          end
        }
      end




      sebseqBus =  results[0]["NextBus2"]

      est_time = Time.parse(nextBus["EstimatedArrival"])
      arrivalTime = est_time.strftime("at %I:%M%p")

      wait_time = 0
      if Time.now < est_time
        wait_time = TimeDifference.between(Time.now,est_time).in_minutes
        wait_time = wait_time.round
      end

      tempnextBus[:nextBusInText] = arrivalTime
      tempwaitTime[:wait_time] = wait_time
      results[0]["NextBus"].merge!(tempnextBus)
      results[0]["NextBus"].merge!(tempwaitTime)


      if (sebseqBus["EstimatedArrival"]).present?
        est_time = Time.parse(sebseqBus["EstimatedArrival"])
        arrivalTime = est_time.strftime("at %I:%M%p")
        wait_time = 0
        if Time.now < est_time
          wait_time = TimeDifference.between(Time.now,est_time).in_minutes
          wait_time = wait_time.round
        end

        tempnextBus[:nextBusInText] = arrivalTime
        tempwaitTime[:wait_time] = wait_time
        results[0]["NextBus2"].merge!(tempnextBus)
        results[0]["NextBus2"].merge!(tempwaitTime)
      end

      render json:{bus_freq:bus_freq_interval,nextBus:nextBus,results: results, bus_id: bus_id, bus_route_info:bus_route_info } , status: 200
    else
      render json:{error_msg:"No Available Result!"}
    end

  end

  def busstop_info
    busRoute = SgBusRoute.where(bus_stop_code: params[:bus_id])
    buses = []
    buses_num = []
    buses_char = []
    route = []
    busRoute.each do |r|
      if is_numeric? r.service_no
        buses_num.push(r.service_no)
      else
        buses_char.push(r.service_no)
      end
      route.push(r)
    end


    buses_char = buses_char.map(&:to_s).uniq
    buses_num = buses_num.map(&:to_i).uniq.sort
    buses = buses_num + buses_char

    route = route.uniq{ |r| [r["service_no"]]}
    render json: {buses: buses,route:route}

  end


  def subsequence_businfo
    service_no = params[:service_no]
    sequence1 = params[:sequence1].to_i
    sequence2 = params[:sequence2].to_i

    total_stop = sequence1 - sequence2
    total_stop = total_stop.abs

    # service_no = service_no.gsub(/[^0-9]/, '')
    frombusId = params[:frombusId]
    tobusId = params[:tobusId]
    bus_route = [ ]
    busArray = [ ]
    direction = 0

    if !params[:frombusId].nil?
      limit = sequence1 - sequence2
      bus_route_dir1 = SgBusRoute.where("service_no=? and direction =1 and stop_sequence between ? and ?", service_no, sequence1, sequence2)
      bus_route_dir2 = SgBusRoute.where("service_no=? and direction =2 and stop_sequence between ? and ?", service_no, sequence1, sequence2)

      if bus_route_dir1.present?
        bus_route_dir1.each do |d1|
          if (d1.bus_stop_code == frombusId.to_i && d1.stop_sequence == sequence1 )
            bus_route = bus_route_dir1
            direction= 1
          end
        end

      end

      if bus_route_dir2.present?
        bus_route_dir2.each do |d2|
          if (d2.bus_stop_code == frombusId.to_i && d2.stop_sequence == sequence2 )
            bus_route = bus_route_dir2
            direction =2
          end
        end

      end
    end


    bus_route.each do |route|
      busArray.push(SgBusStop.find_by_bus_id(route.bus_stop_code))
    end

    if params[:depart]
      frombusId = nil
      frombusId = nil
        if params[:depart_lat] and params[:depart_lng]
          p "departure bus"
           #busstops = SgBusStop.where(description: params[:depart])
           busstops = SgBusStop.all
          busstops.each do |stop|
            lat = stop.latitude.round(4) unless stop.latitude.nil?
            lng = stop.longitude.round(4) unless stop.longitude.nil?
            depart_lat = params[:depart_lat].to_f.round(4)
            depart_lng = params[:depart_lng].to_f.round(4)
            if (depart_lat== lat and depart_lng == lng)
              p "from bus id"
              p frombusId = stop.bus_id
            end

            if frombusId.nil?
              busstops = SgBusStop.where(description: params[:depart])
              if busstops.present?
                p frombusId = busstops.take.bus_id
              end
            end

          end
        end

        if params[:arrive_lat] and params[:arrive_lng]
          p "Arrival bus"
          busstops = SgBusStop.all
          busstops.each do |stop|
            lat = stop.latitude.round(4) unless stop.latitude.nil?
            lng = stop.longitude.round(4) unless stop.longitude.nil?
            arrive_lat = params[:arrive_lat].to_f.round(4)
            arrive_lng = params[:arrive_lng].to_f.round(4)
            if (arrive_lat == lat and arrive_lng == lng)
              p "to bus id"
              p tobusId = stop.bus_id
            end

            if tobusId.nil?
              busstops = SgBusStop.where(description: params[:arrive])
              if busstops.present?
                p tobusId = busstops.take.bus_id
              end
            end

          end

        end
    end

    if busArray.count == 0
      p "search from start and end points"
      p "start stop"
      p frombusId
      p bus_start = SgBusRoute.where(service_no: service_no, bus_stop_code: frombusId)
      p "end stop"
      p bus_end = SgBusRoute.where(service_no: service_no, bus_stop_code: tobusId)

      if bus_start.count == 1
        bus_start = bus_start.take
        p "Start stop direction"
        p direction = bus_start.direction
        bus_end_arr = bus_end.where("direction =?",direction)
        if bus_end_arr.count > 1
          p "compare end stop id with start stop id"
          bus_end_arr.each do |end_id|
            if end_id.id > bus_start.id
              p bus_end = end_id
            end
          end
        else
          p bus_end = bus_end_arr.take
        end

      elsif bus_end.count == 1
        bus_end = bus_end.take
        direction = bus_end.direction

        bus_start = bus_start.where("direction =? ",direction).take
      else
        p bus_start = bus_start.take
        bus_end = bus_end.take
        if !bus_start.nil?
          direction = bus_start.direction
        end
      end

      if !bus_start.nil?

        start_id = bus_start.id
        end_id = bus_end.id
        sg_bus_routes = SgBusRoute.where(id: start_id .. end_id)

        sg_bus_routes.each do |route|
          p route.bus_stop_code
          # if route.distance.present?
          busArray.push(SgBusStop.find_by_bus_id(route.bus_stop_code))
          # end
        end
      end

    end

    render json:{results: busArray,count: busArray.count,direction:direction} , status: 200
  end

  def subsequence_mrtinfo

    from = params[:from]
    to = params[:to]
    fromId= params[:fromId].to_s
    toId = params[:toId].to_s
    shortname= params[:shortname].to_s
    sequence = ""
    s_id, e_id = ''

    substring = " MRT Station"
    from.slice! substring
    to.slice! substring

    p from = from.gsub(/\s+$/,'')
    p to = to.gsub(/\s+$/,'')

    if params[:shortname].present?
      if shortname == "NS"
        start_ns = NS.where(code: fromId).take
        end_ns = NS.where(code: toId).take

        if start_ns.id > end_ns.id
          sequence = NS.where(id: end_ns.id .. start_ns.id).order(id: :desc)
        else
          sequence = NS.where(id: start_ns.id .. end_ns.id)
        end

      elsif shortname == "CG"
        start_cg = EW.where(code: fromId).take
        end_cg = EW.where(code: toId).take

        if fromId.to_s.include?("EW")
          start_cg = EW.find(62)
        elsif toId.to_s.include?("EW")
          end_cg = EW.find(62)
        end

        sequence = []
        if fromId.to_s.include?("EW")
          start_station = EW.where(code: fromId).take
          sequence.push(start_station)
        end

        if start_cg.id > end_cg.id
          seq = EW.where(id: end_cg.id .. start_cg.id).order(id: :desc)
          seq.each do |data|
            sequence.push(data)
          end

        else
          seq = EW.where(id: start_cg.id .. end_cg.id)
          seq.each do |data|
            sequence.push(data)
          end
        end

        if toId.to_s.include?("EW")
          end_station = EW.where(code: toId).take
          sequence.push(end_station)
        end
      elsif shortname == "EW"
        start_ns = EW.where(code: fromId).take
        end_ns = EW.where(code: toId).take

        if start_ns.id > end_ns.id
          sequence = EW.where(id: end_ns.id .. start_ns.id).order(id: :desc)
        else
          sequence = EW.where(id: start_ns.id .. end_ns.id)
        end

      elsif shortname == "NE"
        start_ns = NE.where(code: fromId).take
        end_ns = NE.where(code: toId).take

        if start_ns.id > end_ns.id
          sequence = NE.where(id: end_ns.id .. start_ns.id).order(id: :desc)
        else
          sequence = NE.where(id: start_ns.id .. end_ns.id)
        end

      elsif shortname == "CC"
        start_ns = CC.where(code: fromId).take
        end_ns = CC.where(code: toId).take
        # sequence = CC.where(id: start_ns.id .. end_ns.id)

        if start_ns.id > end_ns.id
          sequence = CC.where(id: end_ns.id .. start_ns.id).order(id: :desc)
        else
          sequence = CC.where(id: start_ns.id .. end_ns.id)
        end

      elsif shortname == "DT"
        start_ns = DT.where(code: fromId).take
        end_ns = DT.where(code: toId).take
        # sequence = DT.where(id: start_ns.id .. end_ns.id)

        if start_ns.id > end_ns.id
          sequence = DT.where(id: end_ns.id .. start_ns.id).order(id: :desc)
        else
          sequence = DT.where(id: start_ns.id .. end_ns.id)
        end

      end
    end

    mrt_line_name = ""
    if params[:mrt_line_name].present?
      mrt_line_name = params[:mrt_line_name]
    else
      mrt_line_name = params[:shortname]
    end

    if mrt_line_name == "North South Line"
      start_ns = NS.find_by_name(from)
      end_ns = NS.find_by_name(to)
      if start_ns.id > end_ns.id
        sequence = NS.where(id: end_ns.id .. start_ns.id).order(id: :desc)
      else
        sequence = NS.where(id: start_ns.id .. end_ns.id).order(id: :asc)
      end
    elsif mrt_line_name == "North East Line"
      start_ne = NE.find_by_name(from)
      end_ne = NE.find_by_name(to)

      if start_ne.id > end_ne.id
        sequence = NE.where(id: end_ne.id .. start_ne.id).order(id: :desc)
      else
        sequence = NE.where(id: start_ne.id .. end_ne.id).order(id: :asc)
      end

    elsif mrt_line_name == "East West Line"
      p start_ew = EW.find_by_name(from)

      p end_ew = EW.find_by_name(to)


      if start_ew.code == "CG2" and end_ew.code == "EW4"
        p 'start CG2 (changi), end EW4 tanah merah'
        sequence = EW.where(id: "63") + EW.where(id: "62") + EW.where(id: "32")

      elsif start_ew.code == "CG2" and end_ew.code == "CG1"
        p 'start CG2 (changi), end CG1 expo'
        sequence = EW.where(id: "63") + EW.where(id: "62")

      elsif start_ew.code == "CG1" and end_ew.code == "CG2"
        p 'start CG1 (expo), end CG2 changi'
        sequence = EW.where(id: "62") + EW.where(id: "63")

      elsif start_ew.code == "CG1" and end_ew.code == "EW4"
        p 'start CG1 (expo), end EW4 Tanah'
        sequence = EW.where(id: "62") + EW.where(id: "32")


      elsif start_ew.code == "EW4" and end_ew.code == "CG2"
        p 'start EW4 (Tanah), end CG2 changi'
        sequence = EW.where(id: "32") + EW.where(id: "62")+ EW.where(id: "63")

      elsif start_ew.code == "EW4" and end_ew.code == "CG1"
        p 'start  EW4 (Tanah), end CG1 (expo)'
        sequence =  EW.where(id: "32") + EW.where(id: "62")

      else

        if start_ew.id > end_ew.id
          sequence = EW.where(id: end_ew.id .. start_ew.id).order(id: :desc)
        else
          sequence = EW.where(id: start_ew.id .. end_ew.id).order(id: :asc)
        end

      end


    elsif mrt_line_name == "Circle Line"
      start_cc = CC.find_by_name(from)
      end_cc = CC.find_by_name(to)

      if start_cc.id > end_cc.id
        sequence = CC.where(id: end_cc.id .. start_cc.id).order(id: :desc)
      else
        sequence = CC.where(id: start_cc.id .. end_cc.id).order(id: :asc)
      end
    elsif mrt_line_name == "Downtown Line"
      p start_dt = DT.find_by_name(from)
      p end_dt = DT.find_by_name(to)

      if start_dt.id > end_dt.id
        sequence = DT.where(id: end_dt.id .. start_dt.id).order(id: :desc)
      else
        sequence = DT.where(id: start_dt.id .. end_dt.id).order(id: :asc)
      end
    elsif mrt_line_name == "Sentosa Express"

      p start_dt = SE.find_by_name(from)
      p end_dt = SE.find_by_name(to)

      if start_dt.id > end_dt.id
        sequence = SE.where(id: end_dt.id .. start_dt.id).order(id: :desc)
      else
        sequence = SE.where(id: start_dt.id .. end_dt.id).order(id: :asc)
      end

    end


    render json:{results: sequence}

  end

  def is_numeric?(obj)
    obj.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
  end

end



class String
  def numeric?
    Float(self) != nil rescue false
  end
end
