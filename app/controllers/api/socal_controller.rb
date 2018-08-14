class Api::SocalController < ApplicationController
  skip_before_action :verify_authenticity_token

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

    user.username = params[:name]
    hiveapp = HiveApplication.find_by_app_name("Socal")
    app_data['app_id'+hiveapp.id.to_s] = hiveapp.api_key
    user.app_data = user.app_data.merge(app_data)
    user.save!

    # hiveapp = HiveApplication.find_by_api_key(params[:app_key])
    hiveapplication = HiveApplication.find_by_app_name("Socal")
    topic = Socal.new
    topic = topic.create_event(
        params[:event_name],
        params[:datetime],data,
        hiveapp.id,
        params[:invitation_code],user.id)

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
    votes = params[:votes]
    user_name = params[:post_name]
    email = params[:email]
    p user = User.find_by_email(email)
    hiveapp = HiveApplication.find_by_app_name("Socal")

    app_data = Hash.new
    app_data['app_id'+hiveapp.id.to_s] = hiveapp.api_key

    if user.blank?
      user = User.create!(username: user_name,email: email, password: Devise.friendly_token)
    end

    user.username = params[:post_name]
    user.app_data = Hash.new if user.app_data.nil?
    user.app_data = user.app_data.merge(app_data)
    user.save!

    Vote.where(user_id: user.id).delete_all
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
    topic =  Topic.where("data -> 'invitation_code' = ? ", params[:invitation_code]).take
    topic.broadcast_event(nil)
    render json: { status: true , topic: topic.retrieve_data, user: user}
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

end
