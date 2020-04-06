class Api::SocalController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create_booking
    hiveapp = HiveApplication.find_by_api_key(params[:app_key])
    user = User.find(params[:user_id]) 
    # booking_title = params[:title]
    place_name = params[:place_name]
    address = params[:address]
    latitude = params[:latitude]
    longitude = params[:longitude]
    google_place_id = params[:google_place_id]
    p "check in date and time"
    ENV['TZ']= 'UTC' 
    p booking_date = Date.parse(params[:checkin_date])
    p booking_time = Time.parse(params[:checkin_date])
  
    place = ''
    check_records = Place.where(name:place_name,source:Place::GOOGLE)
    check_records.each do |cr|
      p "exisiting google record"
      place = cr if cr.address.downcase == address.downcase if address.present?
    end

    if place == ""
      place = Place.create(
          name: place_name,
          latitude:latitude,
          longitude:longitude,
          address: address,
          source: Place::GOOGLE,
          source_id: google_place_id,
          user_id: user.id,
          country: "Singapore")
    end
    place.save!
    
    p "google place"
    p place

    booking = Booking.create!(user_id: user.id,place_id: place.id,booking_date: booking_date,booking_time: booking_time)

    render json: {status: 200, bookings: user.bookings, user: user}

  end

  def get_bookings
    # hiveapp = HiveApplication.find_by_api_key(params[:app_key])
    user = User.find(params[:user_id]) 
    bookings = Booking.where(user_id: user.id).order(:booking_date)

    # Booking.where("Date(booking_date) = ?", Date.today)
    active_bookings = bookings.where("booking_date > ?", Date.today)
    past_bookings = bookings.where("booking_date < ?", Date.today)
    render json: {status: 200,bookings:bookings, active_bookings: active_bookings, past_bookings:past_bookings, user: user}
  end

  def get_booking
    user = User.find(params[:user_id]) 
    booking = Booking.find(params[:id])
    render json: {status: 200, booking: booking, user: user}
  end

  def delete_booking
    user = User.find(params[:user_id]) 
    Booking.delete(params[:id])
    booking = Booking.where(user_id: user.id).order(:booking_date)
    render json: {status: 200, booking: booking, user: user}
  end

  def create_event
    app_data = Hash.new
    data = getHashValuefromString(params[:data]) if params[:data].present?
    user = User.find_by_email(params[:email])
    if user.nil?
      user = User.new
      user.email = params[:email]
      user.password = Devise.friendly_token
      user.app_data = app_data
      user.save(validate: false)
    end
    user.app_data = Hash.new if user.app_data.nil?

    user.username = params[:name]

    hiveapp = HiveApplication.find_by_api_key(params[:app_key])
    app_data['app_id'+hiveapp.id.to_s] = hiveapp.api_key
    user.app_data = user.app_data.merge(app_data)
    user.save!
    hiveapp = HiveApplication.find_by_api_key(params[:app_key])

    topic = Socal.new
    topic = topic.create_event(
        params[:event_name],
        params[:datetime],data,
        hiveapp.id,
        params[:invitation_code],user.id,params[:valid_date])

    topic.data["address"] = params[:address]
    topic.data["place_name"] = params[:place_name]
    topic.data["content"] = params[:content]

    topic.save!

    p "Create event"
    p data
    user = User.find(topic.user_id)
    first_sug = Suggesteddate.find_by_topic_id(topic.id)
    suggesteddates = Suggesteddate.where(topic_id: topic.id)

    if topic.valid?
      render json: {status: true, topic: topic.retrieve_data, user: user, suggesteddates: suggesteddates}
    else
      render json: {status: false}
    end

  end

  def retrieve_invitation_code
    render json:{invitation_code: Socal.generate_invitation_code, host_code: Socal.generate_invitation_code}
  end

  def retrieve_event
   p_invite_code = params[:invitation_code].to_s

   if p_invite_code.length == 22
     #personalized code
     n_invite_code = "" + p_invite_code
     n_invite_code[16,4] = ""
     p_user_code= p_invite_code.slice(16,4)
     if p_user_code == "0000"
       p_topic = Topic.where("data -> 'invitation_code' = ? ", n_invite_code).take
       p_creator = User.find(p_topic.user_id)

       render json:{status: 'host', topic: p_topic.retrieve_data, invitee_name: p_creator.username, invitee_email: p_creator.email }

     else
       p_invitee = Invitee.find_by_invitation_code(p_invite_code)
       p_topic = Topic.find(p_invitee.topic_id)
       p_user = User.find(p_invitee.user_id)
       votes = Vote.where(user_id: p_user.id, topic_id: p_topic.id)

       if votes.present?
         render json: {status: 'host', topic: p_topic.retrieve_data, invitee_name: p_user.username, invitee_email: p_user.email, user_voted_states: 1 }
       else
         render json: { status: 'host', topic: p_topic.retrieve_data, invitee_name: p_user.username, invitee_email: p_user.email, user_voted_state: 0 }
       end

     end
   else
     #normal code
     p "retrieve topic"
     p p_topic = Topic.where("data -> 'invitation_code' = ? ", params[:invitation_code]).take
     if p_topic.present?
       p p_topic.retrieve_data
       p "retrieve data by topic"
       render json: { status: 'invitee',topic: p_topic.retrieve_data, posts: p_topic.posts , code: 200}
     else
       render json: { code: 400 }
     end
   end

  end

  def vote_date

    topic =  Topic.where("data -> 'invitation_code' = ? ", params[:invitation_code]).take

    if params[:votes]
      votes = params[:votes]
      user_name = params[:post_name]
      email = params[:email]
      user = User.find_by_email(email)

      hiveapp = HiveApplication.find_by_api_key(params[:app_key])
      app_data = Hash.new
      app_data['app_id'+hiveapp.id.to_s] = hiveapp.api_key
      if user.blank?
        user = User.create!(username: user_name,email: email, password: Devise.friendly_token)
      end
      p user.username = params[:post_name]
      user.app_data = Hash.new if user.app_data.nil?
      user.app_data = user.app_data.merge(app_data)
      p user.save!


      Vote.where(user_id: user.id, topic_id:params[:topic_id]).delete_all
      votes = JSON.parse(votes)
      votes.each do |v|
        suggesteddate = Suggesteddate.find(v)
        vote = Vote.find_by_topic_id_and_suggesteddate_id_and_user_id(suggesteddate.topic_id, v, user.id)
        if vote.present?
          vote.vote = Vote::YES
          vote.save!
        else
          p "create_new"
          Vote.create(topic_id: suggesteddate.topic_id, selected_datetime: suggesteddate.suggested_datetime, suggesteddate_id: suggesteddate.id, vote: Vote::YES, user_id: user.id)
        end
      end
    elsif params[:confirm_date]
      sug = Suggesteddate.find(params[:confirm_date])
      sug.admin_confirm = true
      sug.save
      topic.data["confirmed_date"] = sug.id
      topic.data["confirm_state"] = 1
      topic.save!

    end
    topic.broadcast_event(nil)
    render json: { status: true , topic: topic.retrieve_data, user: user,posts: topic.posts}
  end


  def confirm_dates

    id =  params[:sug_id]
    topic = params[:topic]
    sug = Suggesteddate.where(id: id, topic_id: topic).take
    sug.admin_confirm = true
    sug.save

    # Suggesteddate.where(topic_id: topic, admin_confirm: false).delete_all

    status ='ok'
    render json: {status: status}

  end


  def create_post
    user = User.find_by_email(params[:email])
    topic = Topic.where("data -> 'invitation_code' = ? ", params[:invitation_code]).take
    post = Post.create(content: params[:content], topic_id: topic.id, user_id: user.id)

    p "create post"
    p user.id

    data={
        id: post.id,
        content: post.content,
        invitation_code: topic.data["invitation_code"],
        username: user.username,
        created_at: post.created_at
    }
    p data

    Pusher["#{topic.data["invitation_code"]}_channel"].trigger_async("new_post",data)
    render json:{post: data}
  end

  def signup

    new_user = true

    user = User.find_by_email(params[:email])
    if user.present?
      if user.socal_register
        render json: { status: 201 }
        new_user = false
      end
    end
    p new_user
    if new_user
      hiveapp = HiveApplication.find_by_api_key(params[:app_key])
      app_data = Hash.new
      app_data['app_id'+hiveapp.id.to_s] = hiveapp.api_key

      if user.nil?
        user = User.new(email: params[:email])
      end

      user.username = params[:name]
      user.password = params[:password]
      user.app_data = Hash.new if user.app_data.nil?
      user.app_data = user.app_data.merge(app_data)
      user.socal_register = true
      user.save!

      render json: { user: user, status: 200 }

    end

  end

  def signin
    if params[:email].present? and params[:password].present?
      user = User.find_by_email(params[:email])
      if user.present?
        hiveapp = HiveApplication.find_by_api_key(params[:app_key])
        app_data = Hash.new
        app_data['app_id'+hiveapp.id.to_s] = hiveapp.api_key

        if user.valid_password?(params[:password])
          user.app_data = Hash.new if user.app_data.nil?
          user.app_data = user.app_data.merge(app_data)
          user.socal_register = true
          user.save!
          render json: { user: user, status: 200 }

        else
          render json: { status: 201, message: 'Wrong Password. Please try again.'}
        end

      else
        render json: { status: 201, message: 'No account found with those details. Reset your password or sign up for a new account.'}
      end
    end
  end

  def get_events
    if params[:user_id].present?
      confirm_topics = []
      active_topics = []

      hiveapp = HiveApplication.find_by_api_key(params[:app_key])
      topics = Topic.where(user_id: params[:user_id], hiveapplication_id: hiveapp.id)
      net_topics = topics.where.not(data: nil).order("id desc")

      count = 0
      active_count = 0
      net_topics.map{|t,i|

        if t.data["confirm_state"] == "1"
          count = count+1
          t_index = { "index" => count}
          confirm_topics.push(t.retrieve_data.merge(t_index))
        else
          active_count = active_count+1
          t_index = { "index" => active_count}
          active_topics.push(t.retrieve_data.merge(t_index))
        end

      }

      vote_topic_ids = Vote.where(user_id: params[:user_id]).pluck("topic_id").uniq
      vote_topics = []
      count = 0
      vote_topic_ids.each do |vt|
        topic = Topic.find(vt)
        count = count+1
        t_index = { "index" => count}
        vote_topics.push(topic.retrieve_data.merge(t_index))
      end


      render json: { status: 200, topics: confirm_topics, active_topics: active_topics ,vote_topics: vote_topics}
    end
  end


  def create_user
    user = User.find_by_email(params[:email])
    if user.nil?
      user = User.new(email: params[:email])
    end
    user.username = params[:username]
    user.save!

    topic = Topic.where("data -> 'invitation_code'=?",params[:invitation_code]).take

    if user.present?
      post_content = user.username + " has joined the conversation"
      post = Post.create(content: post_content, topic_id: topic.id, user_id: user.id)

      data = {
          id: post.id,
          content: post.content,
          invitation_code: params[:invitation_code],
          username: user.username,
          created_at: post.created_at
      }

      Pusher["#{params[:invitation_code]}_channel"].trigger_async("new_post", data)

      votes = Vote.where(user_id: user.id, topic_id: topic.id)

      if votes.present?
        render json: { user_voted_status: 1 }
      else
        render json: { user_voted_status: 0 }
      end
    end
  end

  def download_posts
    posts_array = []
    topic = Topic.where("data -> 'invitation_code' = ? ", params[:invitation_code]).take
    posts = Post.where(topic_id: topic.id)

    if posts.present?
      posts.each do |po|
        posts_array.push({ id: po.id, content: po.content, invitation_code: params[:invitation_code], created_at: po.created_at, username: User.find(po.user_id).username })
      end
    end

    render json:{posts: posts_array}
  end

  def topic_state
    topic = Topic.where("data -> 'invitation_code'=?",params[:invitation_code]).take
    topic.data["confirm_state"] = params[:confirm_state]
    topic.data["confirmed_date"] = params[:confirmed_date_id]
    topic.save!
    topic.broadcast_event(params[:confirmed_date_id])
    render json:{status: true}

  end

  def retrieve_popular_date
    topic = Topic.where("data -> 'invitation_code' =? ", params[:invitation_code]).take
    suggesteddates = topic.suggesteddates
    summary = []
    fav_date = ""
    yes = 0
    no = 0
    maybe = 0

    suggesteddates.each do |sd|
      if sd.suggested_datetime  > Time.now == true
        if sd.votes.present?
          sd.votes.each do |vote|
            if vote.vote == Vote::MAYBE
              maybe =  maybe + 1
            elsif vote.vote == Vote::YES
              yes = yes + 1
            elsif vote.vote == Vote::NO
              no = no + 1
            end
          end
        end
      summary.push(suggesteddate_id: sd.id, date: sd.suggested_datetime, yes: yes, no: no, maybe: maybe, favourite: false)
      end
      yes = 0
      no = 0
      maybe = 0

    end

    sorting_dates = summary.sort_by{ |sd| sd[:yes]}.reverse
    highest_count_date = sorting_dates.first

    if highest_count_date[:yes] > 0
      check_duplicate = sorting_dates.select { |s| s[:yes] == highest_count_date[:yes]}

      if check_duplicate.count > 1
        check = check_duplicate.sort_by{ |cd| cd[:date]}
        summary.each do |sd|
          sd[:favourite] = true if check.first[:date] == sd[:date]
        end
      else
        summary.each do |sd|
          sd[:favourite] = true if sd[:date] == sorting_dates.first[:date]
        end
      end

      select_favourite_date = summary.select { |k| k[:favourite] == true }
      fav_date = select_favourite_date.last
    end

    if fav_date.present?
      render json:{popular_date: fav_date}
    else
      render json:{popular_date: nil}
    end

  end

  def get_suggesteddates
    sug = Suggesteddate.where(topic_id: params[:topic]).order(:suggested_datetime)
    topic = Topic.find(params[:topic])
    render json:{status: 'ok', suggesteddats: sug, topic: topic.retrieve_data}
  end



  def mvc_suggesteddate

    if params[:delete_id]
      Suggesteddate.find(params[:delete_id]).destroy rescue ActiveRecord::RecordNotFound
      render json: {status: 'delete'}
    end

    if params[:update_id]
      updatesug = Suggesteddate.find(params[:update_id])
      c_date = params[:rawdate] +" " + params[:time] + "+800"
      strdate = Time.parse(c_date).to_s
      str_date_array = strdate.split(" ")
      strdate = str_date_array[0] + "T" + str_date_array[1] + str_date_array[2]
      updatesug.suggested_datetime  = strdate
      updatesug.save
      render json: {status: 'update'}

    end

  end

  def update_topic

    topic = Topic.find(params[:update_id])
    topic.title = params[:title]
    topic.data["place_name"] = params[:place_name]
    topic.data["latitude"] = params[:latitude]
    topic.data["longitude"] = params[:longitude]
    topic.save

    sug = Suggesteddate.where(topic_id: params[:update_id])
    first_sug = Suggesteddate.find_by_topic_id(topic.id)
    invitees = TopicInvitees.where(topic_id: params[:update_id])

    render json: {status: 'update_topic', topic: topic.retrieve_data, suggesteddates: sug,invitees: invitees,first_sug: first_sug}

  end
  def vote_date1
    # confirm_date = params[:id]
    # invitee_email = params[:invitee_email]
    #
    # suggesteddate = Suggesteddate.find(confirm_date)
    # suggesteddate.vote +=1
    # suggesteddate.save!
    #
    # user = User.find(suggesteddate.user_id)
    #
    # vote = Vote.find_by_topic_id_and_suggesteddate_id_and_user_id(suggesteddate.topic_id, suggesteddate.id, user.id)
    # if vote.present?
    #  vote.vote = Vote::YES
    #  vote.save!
    # else
    #  Vote.create(topic_id: suggesteddate.topic_id, selected_datetime: suggesteddate.suggested_datetime, suggesteddate_id: suggesteddate.id, vote: Vote::YES, user_id: user.id)
    # end
    #
    # if !invitee_email.nil?
    #  t_inv = TopicInvitees.where(topic_id: suggesteddate.topic_id, invitee_email: invitee_email)
    #  if t_inv.count == 0
    #    t_inv = TopicInvitees.new
    #    t_inv.topic_id = suggesteddate.topic_id
    #    t_inv.invitee_email = invitee_email
    #    t_inv.save!
    #  end
    # end
    #
    # topic = Topic.find(suggesteddate.topic_id)
    # topic.broadcast_event(confirm_date)
    #
    # render json:{status: true}

    temp_votes = params[:votes].split("{")
    user = User.find_by_email(params[:email])
    temp_votes.each do |v|
      v_array= v.split(",")
      suggesteddate = Suggesteddate.find(v_array[0])
      vote = Vote.find_by_topic_id_and_suggesteddate_id_and_user_id(suggesteddate.topic_id, suggesteddate.id, user.id)

      if vote.present?
        vote.vote = v_array[1]
        vote.save!
      else
        Vote.create(topic_id: suggesteddate.topic_id, selected_datetime: suggesteddate.suggested_datetime, suggesteddate_id: suggesteddate.id, vote: v_array[1], user_id: user.id)
      end
    end

    topic =  Topic.where("data -> 'invitation_code' = ? ", params[:invitation_code]).take
    topic.broadcast_event(nil)

    render json: { status: true }

  end
end


class DateTime
  def self.combine(d, t)
    # pass in a date and time or strings
    d = Date.parse(d) if d.is_a? String 
    t = Time.zone.parse(t) if t.is_a? String
    # + 12 hours to make sure we are in the right zone
    # (eg. PST and PDT switch at 2am)
    zone = (Time.zone.parse(d.strftime("%Y-%m-%d")) + 12.hours ).zone
    new(d.year, d.month, d.day, t.hour, t.min, t.sec, zone)
  end
end