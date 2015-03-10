class Api::SocalController < ApplicationController

  def create_event
    invitee_array = []
    topic = Socal.new
    topic = topic.create_event(params[:event_name],
    params[:invitation_code],
    params[:latitude],
    params[:longitude],
    params[:place_name],
    params[:address],
    params[:description],
    params[:datetime],
    params[:email],
    params[:name])

    invitee_list = params[:invitees].split("{")

    invitee_list.each_with_index do |i, index|
      temp = i.split(",")
      invitee_array.push({name: temp[0], email: temp[1]})

      inv_code = Topic.where("data -> 'invitation_code' = ? ", params[:invitation_code]).take
      inv_code = inv_code.data["invitation_code"]

      #mail = UserMailer.delay.send_invitation({ name: temp[0], email: temp[1] }, params[:invitation_code], inv_code, params[:event_name], index+1)
      #mail.deliver
    end

    if topic.valid?
      render json: {status: true}
    else
      render json: {status: false}
    end
  end

  def retrieve_invitation_code
    render json:{invitation_code: Socal.generate_invitation_code}
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

        render json:{topic: p_topic.retrieve_socaldata, invitee_name: p_creator.username, invitee_email: p_creator.email }

      else
        p_invitee = Invitee.find_by_invitation_code(p_invite_code)
        p_topic = Topic.find(p_invitee.topic_id)
        p_user = User.find(p_invitee.user_id)
        votes = Vote.where(user_id: p_user.id, topic_id: p_topic.id)

        if votes.present?
          render json: { topic: p_topic.retrieve_data, invitee_name: p_user.username, invitee_email: p_user.email, user_voted_states: 1 }
        else
          render json: { topic: p_topic.retrieve_data, invitee_name: p_user.username, invitee_email: p_user.email, user_voted_state: 0 }
        end

      end
    else
      #normal code
      p_topic = Topic.where("data -> 'invitation_code' = ? ", params[:invitation_code]).take
      render json: { topic: p_topic.retrieve_data }
    end

  end

  def vote_date
    temp_votes = params[:votes].split("{")
    user = User.find_by_email(params[:email])
    temp_votes.each do |v|
      v_array = v.split(",")
      suggesteddate  = Suggesteddate.find(v_array[0])
      vote = Vote.find_by_topic_id_and_suggesteddate_id_and_user_id(suggesteddate.topic_id, suggesteddate.id,user.id)

      if vote.present?
        vote.vote = v_array[1]
        vote.save!
      else
        Vote.create(topic_id: suggesteddate.topic_id, selected_datetime: suggesteddate.suggested_datetime, suggesteddate_id: suggesteddate.id, vote: v_array[1], user_id: user.id)
      end
    end

    topic = Topic.where("data -> 'invitation_code' = ? ", params[:invitation_code]).take
    topic.broadcast_event

    render json:{status: true}
  end

  def create_post
    user = User.find_by_email(params[:email])
    topic = Topic.where("data -> 'invitation_code' = ? ", params[:invitation_code]).take
    post = Post.create(content: params[:content], topic_id: topic.id, user_id: user.id)

    data={
        id: post.id,
        content: post.content,
        invitation_code: topic.data["]invitation_code"],
        username: user.username,
        created_at: post.created_at
    }

    Pusher["#{topic.data["invitation_code"]}_channel"].trigger_async("new_post",data)
    render json:{post: data}
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
    topic.data["confirmed_date"] = Suggesteddate.find(params[:confirmed_date_id])
    topic.save!

    topic.broadcast_event

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

end
