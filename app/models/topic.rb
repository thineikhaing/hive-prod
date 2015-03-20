require 'value_enums'
class Topic < ActiveRecord::Base
  belongs_to :hiveapplication
  belongs_to :user
  belongs_to :place

  has_many :topic_with_tags

  has_many  :posts, :dependent => :destroy
  has_many :suggesteddates
  has_many :votes
  has_many :invitees

  # Setup hstore
  store_accessor :data
  #enums for topic type

  enums %w(NORMAL IMAGE AUDIO VIDEO)

  enums %w(NONE FLARE BEACON STICKY PROMO COSHOOT QUESTION ERRAND)

   attr_accessible :title, :topic_type, :topic_sub_type, :place_id, :hiveapplication_id, :user_id, :data, :created_at, :image_url, :width, :height, :value, :unit, :likes, :dislikes, :offensive, :notification_range, :special_type

  # Return the tags and location tags related to the topic

  def tag_information
    tags = TopicWithTag.where(topic_id: self.id)
    { tags: tags }
  end

  def as_json(options=nil)
    if options[:content].present?      #return topic json with content information
      super(only: [:id, :title, :topic_type, :topic_sub_type, :place_id, :hiveapplication_id, :user_id, :image_url,:width, :height, :data, :value, :unit, :likes, :dislikes, :offensive, :notification_range, :special_type, :created_at], methods: [:username, :place_information, :tag_information, :content])
    else
      super(only: [:id, :title, :topic_type, :topic_sub_type, :place_id, :hiveapplication_id, :user_id, :image_url,:width, :height, :data, :value, :unit, :likes, :dislikes, :offensive, :notification_range, :special_type, :created_at], methods: [:username, :place_information, :tag_information])
    end
  end

  def username
    User.find_by_id(self.user_id).username
  end

  def place_information
    if self.place_id.present? and self.place_id > 0
      place = Place.find(self.place_id)
      { id: place.id, name: place.name, latitude: place.latitude, longitude: place.longitude, address: place.address, category: place.category, source: place.source, source_id: place.source_id, user_id: place.user_id, country: place.country, postal_code: place.postal_code, chain_name: place.chain_name, contact_number: place.contact_number, img_url: place.img_url,locality: place.locality, region: place.region, neighbourhood: place.neighbourhood, data: place.data }
    else
      { id: nil, name: nil, latitude: nil, longitude: nil, address: nil , custom_pin_url: nil, source: nil, user_id: nil, popular: nil }
    end
  end

  def content
    testDataArray = [ ]
    hiveapplication = HiveApplication.find(self.hiveapplication_id)
    if hiveapplication.present?
      mealbox_key = ""
      if Rails.env.development?
        mealbox_key = Mealbox_key::Development_Key
      elsif Rails.env.staging?
        mealbox_key = Mealbox_key::Staging_Key
      else
        mealbox_key = Mealbox_key::Production_Key
      end
      if hiveapplication.api_key ==  mealbox_key   #api key for mealbox
        postsArray = self.posts.where(["likes > ? OR dislikes > ?", 0, 0])
        if postsArray.present?
          postsArray.each do |pa|
          total = pa.likes + pa.dislikes
          testDataArray.push({ total: total, id: pa.id, created_at: pa.created_at })
          end
        end
        new_post = testDataArray.sort_by { |x| [x[:total], x[:created_at]] }
        if new_post.present?
          post = Post.find(new_post.last[:id])
        end
        if post.present?
         { popular_post: post, comment_post: self.posts.first}
        else
         { popular_post: nil,comment_post: self.posts.first}

        end
     end
    end
  end

  def hive_broadcast
    data = {
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        topic_type: self.topic_type,
        topic_sub_type: self.topic_sub_type,
        place_id: self.place_id,
        image_url: self.image_url,
        width:  self.width,
        height: self.height,
        hiveapplication_id: self.hiveapplication_id,
        value:  self.value,
        unit: self.unit,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        notification_range: self.notification_range,
        sepcial_type: self.special_type,
        created_at: self.created_at,
        data: self.data,
        methods: {
            username: username,
            place_information: self.place_information,
            tag_information: self.tag_information
        }
    }

    Pusher["hive_channel"].trigger_async("new_topic", data)
  end

  def app_broadcast
    hiveapplication = HiveApplication.find(self.hiveapplication_id)
    data = {
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        topic_type: self.topic_type,
        topic_sub_type: self.topic_sub_type,
        place_id: self.place_id,
        image_url: self.image_url,
        width:  self.width,
        height: self.height,
        hiveapplication_id: self.hiveapplication_id,
        value:  self.value,
        unit: self.unit,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        notification_range: self.notification_range,
        special_type: self.special_type,
        created_at: self.created_at,
        data: self.data,
        methods: {
            username: username,
            place_information: self.place_information,
            tag_information: self.tag_information
        }
    }
    channel_name = hiveapplication.api_key+ "_channel"
    Pusher[channel_name].trigger_async("new_topic", data)
  end

  def app_broadcast_with_content
    hiveapplication = HiveApplication.find(self.hiveapplication_id)
    data = {
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        topic_type: self.topic_type,
        topic_sub_type: self.topic_sub_type,
        place_id: self.place_id,
        image_url: self.image_url,
        width:  self.width,
        height: self.height,
        hiveapplication_id: self.hiveapplication_id,
        value:  self.value,
        unit: self.unit,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        notification_range: self.notification_range,
        special_type: self.special_type,
        created_at: self.created_at,
        data: self.data,
        methods: {
            username: username,
            place_information: self.place_information,
            tag_information: self.tag_information,
            content: self.content
        }
    }
    channel_name = hiveapplication.api_key+ "_channel"
    Pusher[channel_name].trigger_async("new_topic", data)
  end

  def update_event_broadcast_hive
    data = {
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        topic_type: self.topic_type,
        topic_sub_type: self.topic_sub_type,
        place_id: self.place_id,
        image_url: self.image_url,
        width:  self.width,
        height: self.height,
        hiveapplication_id: self.hiveapplication_id,
        value:  self.value,
        unit: self.unit,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        notification_range: self.notification_range,
        special_type: self.special_type,
        created_at: self.created_at,
        data: self.data,
        methods: {
            username: username,
            place_information: self.place_information,
            tag_information: self.tag_information
        }
    }

    Pusher["hive_channel"].trigger_async("update_topic", data)
  end

  def update_event_broadcast_other_app
    hiveapplication = HiveApplication.find(self.hiveapplication_id)
    data = {
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        topic_type: self.topic_type,
        topic_sub_type: self.topic_sub_type,
        place_id: self.place_id,
        image_url: self.image_url,
        width:  self.width,
        height: self.height,
        hiveapplication_id: self.hiveapplication_id,
        value:  self.value,
        unit: self.unit,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        notification_range: self.notification_range,
        special_type: self.special_type,
        created_at: self.created_at,
        data: self.data,
        methods: {
            username: username,
            place_information: self.place_information,
            tag_information: self.tag_information
        }
    }
    channel_name = hiveapplication.api_key+ "_channel"
    Pusher[channel_name].trigger_async("update_topic", data)
  end

  def update_event_broadcast_other_app_with_content
    hiveapplication = HiveApplication.find(self.hiveapplication_id)
    data = {
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        topic_type: self.topic_type,
        topic_sub_type: self.topic_sub_type,
        place_id: self.place_id,
        image_url: self.image_url,
        width:  self.width,
        height: self.height,
        hiveapplication_id: self.hiveapplication_id,
        value:  self.value,
        unit: self.unit,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        notification_range: self.notification_range,
        special_type: self.special_type,
        created_at: self.created_at,
        data: self.data,
        methods: {
            username: username,
            place_information: self.place_information,
            tag_information: self.tag_information,
            content: self.content
        }
    }
    channel_name = hiveapplication.api_key+ "_channel"
    Pusher[channel_name].trigger_async("update_topic", data)
  end

  def delete_event_broadcast_hive
    data = {
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        topic_type: self.topic_type,
        topic_sub_type: self.topic_sub_type,
        place_id: self.place_id,
        image_url: self.image_url,
        width:  self.width,
        height: self.height,
        hiveapplication_id: self.hiveapplication_id,
        value:  self.value,
        unit: self.unit,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        notification_range: self.notification_range,
        special_type: self.special_type,
        created_at: self.created_at,
        data: self.data,
        methods: {
            username: username,
            place_information: self.place_information,
            tag_information: self.tag_information
        }
    }

    Pusher["hive_channel"].trigger_async("delete_topic", data)
  end

  def delete_event_broadcast_other_app
    hiveapplication = HiveApplication.find(self.hiveapplication_id)
    data = {
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        topic_type: self.topic_type,
        topic_sub_type: self.topic_sub_type,
        place_id: self.place_id,
        image_url: self.image_url,
        width:  self.width,
        height: self.height,
        hiveapplication_id: self.hiveapplication_id,
        value:  self.value,
        unit: self.unit,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        notification_range: self.notification_range,
        special_type: self.special_type,
        created_at: self.created_at,
        data: self.data,
        methods: {
            username: username,
            place_information: self.place_information,
            tag_information: self.tag_information
        }
    }
    channel_name = hiveapplication.api_key + "_channel"
    Pusher[channel_name].trigger_async("delete_topic", data)
  end

  # Search the database for related titles

  def self.search_data(search)
    if search
      #find(:all, :conditions => ['lower(title) LIKE ?', "%#{search.downcase}%"])
      where("lower(title) like ?", "%#{search.downcase}%")
    else
      find(:all)
    end
  end

  def delete_event_broadcast_other_app_with_content
    hiveapplication = HiveApplication.find(self.hiveapplication_id)
    data = {
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        topic_type: self.topic_type,
        topic_sub_type: self.topic_sub_type,
        place_id: self.place_id,
        image_url: self.image_url,
        width:  self.width,
        height: self.height,
        hiveapplication_id: self.hiveapplication_id,
        value:  self.value,
        unit: self.unit,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        notification_range: self.notification_range,
        special_type: self.special_type,
        created_at: self.created_at,
        data: self.data,
        methods: {
            username: username,
            place_information: self.place_information,
            tag_information: self.tag_information,
            content: self.content
        }
    }
    channel_name = hiveapplication.api_key + "_channel"
    Pusher[channel_name].trigger_async("delete_topic", data)
  end

  # Check for the total counts of likes and dislikes
  # Returns the most popular post, sorted by highest total counts and created_at
  # Check for any new posts, return nil if there is no new post

  def popular_post
    testDataArray = [ ]
    postsArray = self.posts.where(["likes > ? OR dislikes > ?", 0, 0])

    if postsArray.present?
      postsArray.each do |pa|
        total = pa.likes + pa.dislikes
        testDataArray.push({ total: total, id: pa.id, created_at: pa.created_at })
      end

      new_post = testDataArray.sort_by { |x| [x[:total], x[:created_at]] }
      post = Post.find(new_post.last[:id])
      post
    else
      nil
    end
  end

  def latest_post
    if self.posts.last == self.posts.first
      nil
    else
      self.posts.last
    end
  end

  def num_posts
    if @no_of_post>0
      self.posts.last(@no_of_post)
    else
     nil
    end
  end

  def user_add_likes(current_user, topic_id, choice)
    actionlog = ActionLog.new
    user = User.find(current_user.id)
    topic = Topic.find(topic_id)
    topic_user = User.find(topic.user_id)
    action_status = 0
    check_like = ActionLog.where(type_name: "topic", type_id: topic_id, action_type: "like", action_user_id: current_user.id)
    check_dislike = ActionLog.where(type_name: "topic", type_id: topic_id, action_type: "dislike", action_user_id: current_user.id)

    if choice == "like"
      if check_dislike.present?
        topic.dislikes = topic.dislikes - 1
        ActionLog.find_by_type_name_and_type_id_and_action_type_and_action_user_id("topic", topic_id, "dislike", user.id).delete
        action_status = -1
      else
        unless check_like.present?
          topic.likes = topic.likes + 1
          topic_user.point = topic_user.point + 1
          #actionlog.create_record("topic", topic_id, "like", user.id)
          actionlog =   ActionLog.create(type_name: "topic", type_id: topic_id, action_type: "like", action_user_id: user.id)
          action_status = 1
        end
      end
    elsif choice == "dislike"
      if check_like.present?
        topic.likes = topic.likes - 1
        topic_user.point = topic_user.point - 1
        ActionLog.find_by_type_name_and_type_id_and_action_type_and_action_user_id("topic", topic_id, "like", user.id).delete
        action_status = -1
      else
        unless check_dislike.present?
          topic.dislikes = topic.dislikes + 1
          topic_user.point = topic_user.point + 1
          #actionlog.create_record("topic", topic_id, "dislike", current_user.id)
          actionlog =   ActionLog.create(type_name: "topic", type_id: topic_id, action_type: "dislike", action_user_id: user.id)
          action_status = 1
        end
      end
    end

    topic.save!
    topic_user.save!
    topic.reload

    if action_status!= 0
      hiveapplication = HiveApplication.find(topic.hiveapplication_id)
      if hiveapplication.id ==1
        #broadcast new topic creation to hive_channel only
        topic.update_event_broadcast_hive
      elsif hiveapplication.devuser_id==1 and hiveapplication.id!=1
        #All Applications under Herenow except Hive
        topic.update_event_broadcast_hive
        topic.update_event_broadcast_other_app_with_content
      else
        topic.update_event_broadcast_hive
        topic.update_event_broadcast_other_app
      end
    end
    return action_status
  end

  def user_offensive_topic(current_user, topic_id, topic)
    actionlog = ActionLog.new
    user = User.find(current_user.id)
    admin_user = User.find_by_email("info@raydiusapp.com")
    admin_user1 = User.find_by_email("gamebot@raydiusapp.com")
    check = ActionLog.where(type_name: "topic", type_id: topic_id, action_type: "offensive", action_user_id: user.id)
    unless check.present?
      unless self.user_id == admin_user.id #or self.user_id == admin_user1.id
        topic.offensive +=1
        topic.save!
        topic.reload
        mail = UserMailer.report_offensive_topic(user, topic)
        mail.deliver
        actionlog =   ActionLog.create(type_name: "topic", type_id: topic_id, action_type: "offensive", action_user_id: user.id)
        hiveapplication = HiveApplication.find(topic.hiveapplication_id)
        if hiveapplication.id ==1
          #broadcast new topic creation to hive_channel only
          topic.update_event_broadcast_hive
        elsif hiveapplication.devuser_id==1 and hiveapplication.id!=1
          #All Applications under Herenow except Hive
          topic.update_event_broadcast_hive
          topic.update_event_broadcast_other_app_with_content
        else
          #3rd party app
          topic.update_event_broadcast_hive
          topic.update_event_broadcast_other_app
        end
      end
    end
  end

  def delete_S3_file(bucket_name, file_name,topic_type)
    s3= AWS::S3::new(
        :access_key_id      => 'AKIAIJMZ5RLXRO6LJHPQ',     # required
        :secret_access_key  => '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',    # required
        :region => "ap-southeast-1",
    )
    bucket = s3.buckets[bucket_name]
    object = bucket.objects[file_name]
    object.delete
    if topic_type == Topic::IMAGE    #delete medium and small version
      names = file_name.split(".")
      sfilename = names[0] +  "_s." +  names[1]
      mfilename =  names[0] +  "_m." + names[1]

      object = bucket.objects[sfilename]
      object.delete

      object = bucket.objects[mfilename]
      object.delete
    end
  end

  def remove_records
    tags = TopicWithTag.where(topic_id: self.id)
    actions = ActionLog.where(type_name: "topic", type_id: self.id)

    #if self.topic_type == Topic::FAVR
    #  favr_actions= Favraction.where(topic_id: self.id)
    #  favr_actions.each do |favr_action|
    #    Favraction.find(favr_action.id).delete
    #  end
    #end

    tags.each do |tag|
      checkTags = TopicWithTag.where(tag_id: tag.tag_id)

      if checkTags.count == 1
        checkTags.each do |ct|
          TopicWithTag.find(ct.id).delete
        end
        Tag.find(tag.tag_id).delete
      end
    end

    actions.each do |a|
      a.delete
    end

    posts = self.posts

    posts.map { |po|
      po.remove_records
      #po.delete_event_broadcast
      po.delete
    }
  end

  def notify_carmmunicate_msg_to_selected_users (users_to_push, isprivatemsg, app_key, master_secret )
    to_plate_number =""
    if (isprivatemsg)  and users_to_push.length>0
      user_id = users_to_push.first.to_i
      user= User.find_by_id(user_id)
      if user.data.present?
        hash_array = user.data
        to_plate_number = hash_array["plate_number"] if  hash_array["plate_number"].present?
      end
    end
    notification = {
        aliases: users_to_push,
        aps: { alert: self.title, badge: "+1", sound: "default" },
        topic:{id: self.id,
        title: self.title,
        user_id: self.user_id,
        topic_type: self.topic_type,
        topic_sub_type: self.topic_sub_type,
        place_id: self.place_id,
        image_url: self.image_url,
        width:  self.width,
        height: self.height,
        hiveapplication_id: self.hiveapplication_id,
        value:  self.value,
        unit: self.unit,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        notification_range: self.notification_range,
        special_type: self.special_type,
        created_at: self.created_at,
        data: self.data,
        methods: {
            username: username,
            place_information: self.place_information,
            tag_information: self.tag_information,
            is_private_message: isprivatemsg,
            to_plate_number: to_plate_number
          }
        }
    }.to_json

    p "users_to_push"
    p users_to_push

    full_path = 'https://go.urbanairship.com/api/push/'
    url = URI.parse(full_path)
    req = Net::HTTP::Post.new(url.path, initheader = {'Content-Type' =>'application/json'})
    req.body = notification
    req.basic_auth app_key, master_secret
    con = Net::HTTP.new(url.host, url.port)
    con.use_ssl = true

    r = con.start {|http| http.request(req)}
    p "after sent"
    logger.info "\n\n##############\n\n  " + "Resonse body: " + r.body + "  \n\n##############\n\n"
    p "after urban airship"

  end

  def notify_carmmunicate_msg_to_nearby_users
    users_to_push=[]
    place = Place.find_by_id(self.place_id)
    current_lat = place.latitude
    current_lng = place.longitude
    user = User.find(self.user_id)

    #get the user within 5KM
    users_to_push = get_active_users_to_push(current_lat, current_lng, 5, user.id)

    #get the user within 10KM if there is no user to push within 5KM
    unless users_to_push.present?
      users_to_push = get_active_users_to_push(current_lat, current_lng, 10, user.id)
    end

    if Rails.env.production?
      dev_app_key = Urbanairship_Const::CM_P_Dev_Key
      dev_app_secret = Urbanairship_Const::CM_P_Dev_Secret
      dev_master_secret= Urbanairship_Const::CM_P_Dev_Master_Secret

      adhoc_app_key = Urbanairship_Const::CM_P_Adhoc_Key
      adhoc_app_secret = Urbanairship_Const::CM_P_Adhoc_Secret
      adhoc_master_secret= Urbanairship_Const::CM_P_Adhoc_Master_Secret
    elsif Rails.env.staging?
      dev_app_key = Urbanairship_Const::CM_S_Dev_Key
      dev_app_secret= Urbanairship_Const::CM_S_Dev_Secret
      dev_master_secret= Urbanairship_Const::CM_S_Dev_Master_Secret

      adhoc_app_key = Urbanairship_Const::CM_S_Adhoc_Key
      adhoc_app_secret = Urbanairship_Const::CM_S_Adhoc_Secret
      adhoc_master_secret= Urbanairship_Const::CM_S_Adhoc_Master_Secret
    else
      app_key = Urbanairship_Const::CM_D_Key
      app_secret= Urbanairship_Const::CM_D_Secret
      master_secret= Urbanairship_Const::CM_D_Master_Secret
    end

    if users_to_push.present?
      if Rails.env.development?
        notify_carmmunicate_msg_to_selected_users(users_to_push, false,app_key,master_secret)
      else
        notify_carmmunicate_msg_to_selected_users(users_to_push, false, dev_app_key, dev_master_secret)
        notify_carmmunicate_msg_to_selected_users(users_to_push, false, adhoc_app_key, adhoc_master_secret)
      end
    end
  end

  def get_active_users_to_push(current_lat, current_lng, raydius, current_user_id)
    usersArray = [ ]
    activeUsersArray = []

    users = User.nearest(current_lat, current_lng, raydius)
    #time_allowance = Time.now - 10.minutes.ago
    time_allowance = Time.now - 20.seconds.ago

    users.each do |u|
      if u.check_in_time.present?
        time_difference = Time.now - u.check_in_time
        unless time_difference.to_i > time_allowance.to_i
          usersArray.push(u)
        end
      end
    end

    usersArray.each do |ua|
      unless ua.id == current_user_id
        activeUsersArray.push(ua.id.to_s)
      end
    end
    p "activeUsersArray"
    p activeUsersArray
  end

  def user_favourite_topic(current_user, topic_id, choice)
    if choice == "favourite"
      check = ActionLog.where(type_name: "topic", type_id: topic_id, action_type: "favourite", action_user_id: current_user.id)
      actionlog =   ActionLog.create(type_name: "topic", type_id: topic_id, action_type: "favourite", action_user_id: user.id) unless check.present?
    elsif choice == "unfavourite"
      ActionLog.find_by_type_name_and_type_id_and_action_type_and_action_user_id("topic", topic_id, "favourite", current_user.id).delete
    end
  end

  def topic_image_upload_job
    p "delayed job starts!"
    uploader = PhotoUploader.new
    uploader.retrieve_from_store!(self.image_url)
    uploader.cache_stored_file!
    uploader.resize_to_fit(uploader.get_geometry[0]/5,uploader.get_geometry[1]/5)
    uploader.store!
    p "delayed job ends!"
  end

  # ********* For Socal  **************

  def retrieve_socaldata
    datetime = [ ]
    vote_maybe = 0
    vote_yes = 0
    vote_no = 0

    self.suggesteddates.each do |sd|
      votes = sd.votes

      votes.each do |v|
        if v.vote == Vote::MAYBE
          vote_maybe = vote_maybe + 1
        elsif v.vote == Vote::YES
          vote_yes = vote_yes + 1
        elsif v.vote == Vote::NO
          vote_no = vote_no + 1
        end
      end

      datetime.push({id: sd.id, dateNtime: sd.suggested_datetime, maybe: vote_maybe, yes: vote_yes, no: vote_no, vote: sd.vote, admin_confirm: sd.admin_confirm })

      vote_maybe = 0
      vote_yes = 0
      vote_no = 0
    end

    confirmed_event_date = nil

    if (self.data["confirmed_date"] != nil)
      confirmed_event_date = Suggesteddate.find(self.data["confirmed_date"]).suggested_datetime
    end
    user = User.find(self.user_id)

    data = {
        topic_id: self.id,
        title: self.title,
        latitude: self.data["latitude"],
        longitude: self.data["longitude"],
        address: self.data["address"],
        place_name: self.data["place_name"],
        description: self.data["content"],
        datetime: datetime,
        invitation_code: self.data["invitation_code"],
        creator_name: user.username,
        creator_email: user.email,
        confirm_state: self.data["confirm_state"],
        confirmed_date: confirmed_event_date
    }
  end


  def broadcast_event(confirm_date)
    vote_maybe = 0
    vote_yes = 0
    vote_no = 0
    datetime = [ ]

    self.suggesteddates.each do |sd|
      votes = sd.votes

      votes.each do |v|
        if v.vote == Vote::MAYBE
          vote_maybe = vote_maybe + 1
        elsif v.vote == Vote::YES
          vote_yes = vote_yes + 1
        elsif v.vote == Vote::NO
          vote_no = vote_no + 1
        end
      end

      datetime.push({id: sd.id, dateNtime: sd.suggested_datetime, maybe: vote_maybe, yes: vote_yes, no: vote_no, vote: sd.vote , admin_confirm: sd.admin_confirm})
    end

    confirmed_event_date = nil

    p "confirmed date"
    p self.data["confirmed_date"]

    if (self.data["confirmed_date"] != "")

      confirmed_event_date = Suggesteddate.find(confirm_date).suggested_datetime

    end
    user = User.find(self.user_id)
    data = {
        topic_id: self.id,
        title: self.title,
        latitude: self.data["latitude"],
        longitude: self.data["longitude"],
        address: self.data["address"],
        place_name: self.data["place_name"],
        description: self.data["content"],
        datetime: datetime,
        invitation_code: self.data["invitation_code"],
        creator_name: user.username,
        creator_email: user.email,
        confirm_state: self.data["confirm_state"],
        confirmed_date: confirmed_event_date
    }

    Pusher["#{self.data["invitation_code"]}_channel"].trigger_async("broadcast_event", data)
  end


  # *********** Socal ************

  def retrieve_data
    datetime = [ ]
    vote_maybe = 0
    vote_yes = 0
    vote_no = 0

    self.suggesteddates.each do |sd|
      votes = sd.votes

      votes.each do |v|
        if v.vote == Vote::MAYBE
          vote_maybe = vote_maybe + 1
        elsif v.vote == Vote::YES
          vote_yes = vote_yes + 1
        elsif v.vote == Vote::NO
          vote_no = vote_no + 1
        end
      end

      datetime.push({id: sd.id, dateNtime: sd.suggested_datetime, maybe: vote_maybe, yes: vote_yes, no: vote_no , vote: sd.vote , admin_confirm: sd.admin_confirm })

      vote_maybe = 0
      vote_yes = 0
      vote_no = 0
    end

    confirmed_event_date = nil
    if (self.data["confirmed_date"] != nil)
      confirmed_event_date = Suggesteddate.find(self.data["confirmed_date"]).suggested_datetime
    end

    user = User.find(self.user_id)

    data = {
        topic_id: self.id,
        host: user.username,
        title: self.title,
        latitude: self.data["latitude"],
        longitude: self.data["longitude"],
        address: self.data["address"],
        place_name: self.data["place_name"],
        description: self.data["content"],
        datetime: datetime,
        invitation_code: self.data["invitation_code"],
        creator_name: user.username,
        creator_email: user.email,
        confirm_state: self.data["confirm_state"],
        confirmed_date: confirmed_event_date
    }
  end

  handle_asynchronously :topic_image_upload_job
end
