require 'obscenity/active_model'

class Post < ActiveRecord::Base
  belongs_to :topic
  belongs_to :user
  delegate :username, to: :user
  delegate :pub_sub_channel, to: :topic

  # Setup hstore
  store_accessor :data

  #attr_accessible :content, :post_type, :data, :created_at, :user_id, :topic_id, :place_id,:likes,
   #               :dislikes, :offensive, :img_url, :width, :height, :latitude, :longitude ,:special_type
  enums %w(TEXT IMAGE AUDIO VIDEO)

  #enum for special type for favr
  enums %w(DEFAULT DOER_STARTED DOER_FINISHED OWNER_ACKNOWLEDGED OWNER_REJECTED DOER_RESPONDED_ACK DOER_RESPONDED_REJ OWNER_REVOKED COMPLETION_REMINDER_SENT EXPIRED_AFTER_STARTED EXPIRED_AFTER_FINISHED EXPIRED OWNER_REOPENED)


  validates :content, presence: true
  validates :content, obscenity: { sanitize: true, replacement: "snork" }

  def as_json(options=nil)
    super(only: [:id, :topic_id, :content, :created_at, :user_id, :post_type,:place_id,:likes, :dislikes, :offensive, :width, :height, :data, :created_at], methods: [:username,:avatar_url, :image_url])
  end

  def image_url
    self.img_url
  end

  def avatar_url
    if self.user.avatar_url.url.nil? || self.user.avatar_url.url === "null"
      avatar = Topic.get_avatar(username)
    else
      if Rails.env.development?
        bucket = AWS_Bucket::Avatar_D
      elsif Rails.env.staging?
        bucket = AWS_Bucket::Avatar_S
      else
        bucket = AWS_Bucket::Avatar_P
      end
      avatar =  "https://s3.ap-southeast-1.amazonaws.com/"+bucket+"/"+self.user.id.to_s+".jpeg"
    end
    return avatar
  end


  def create_post(content, topic_id,user_id, post_type, latitude, longitude, temp_id,height=0, width=0, isfavrpost=false,action_id = -1,special_type=0)

    post = Post.create(content: content, topic_id: topic_id, user_id: user_id, post_type:post_type, height: height, width: width, latitude: latitude, longitude: longitude,special_type: special_type)

    if post_type == IMAGE.to_s
      post.delay.image_upload_delayed_job(content)
    end

    history = Historychange.new

    history.type_name = 'post'
    history.type_id = post.id
    history.type_action = 'create'
    history.parent_id = post.topic_id
    history.save

    history.type_name = 'topic'
    history.type_id =  post.topic.id
    history.type_action = 'update'
    history.parent_id = nil
    history.save

    topic = Topic.find(post.topic_id)
    post.broadcast_temp_id(temp_id)
    post.fav_topic_push_notification
    topic.update_event_broadcast(post.id,action_id)

    return post
  end

  # Topic main channel

  def pub_sub_channel
    "topics_#{self.id}"
  end

  def broadcast
    data = {
        id: self.id,
        topic_id: self.topic_id,
        content: self.content,
        created_at: self.created_at,
        likes: self.likes,
        dislikes: self.dislikes,
        user_id: self.user_id,
        offensive: self.offensive,
        username: self.username,
        latitude: self.latitude,
        longitude: self.longitude,
        post_type: self.post_type,
        height: self.height,
        width: self.width,
        history_id: 0 ,
        special_type: self.special_type
    }

    Pusher[self.pub_sub_channel].trigger_async("broadcast", data)
  end

  def broadcast_to_topic(topic_id)
    data = {
        id: self.id,
        topic_id: self.topic_id,
        content: self.content,
        created_at: self.created_at,
        likes: self.likes,
        dislikes: self.dislikes,
        user_id: self.user_id,
        offensive: self.offensive,
        username: self.username,
        avatar_url: avatar_url,
        latitude: self.latitude,
        longitude: self.longitude,
        post_type: self.post_type,
        height: self.height,
        width: self.width,
        history_id: 0,
        special_type: self.special_type
    }

    p "post channel with respect to topic"
    p self.pub_sub_channel

    p sub_channel = "topics_" + topic_id
    p  self.content
    p "sub_channel"

    Pusher[sub_channel].trigger_async("broadcast", data)
  end

  def broadcast_temp_id(temp_id)
    data = {
        id: self.id,
        topic_id: self.topic_id,
        content: self.content,
        created_at: self.created_at,
        likes: self.likes,
        dislikes: self.dislikes,
        user_id: self.user_id,
        offensive: self.offensive,
        temp_id: temp_id,
        username: self.username,
        avatar_url: avatar_url,
        latitude: self.latitude,
        longitude: self.longitude,
        post_type: self.post_type,
        height: self.height,
        width: self.width,
        special_type: self.special_type
    }

    Pusher[self.pub_sub_channel].trigger "broadcast", data
  end

  def broadcast_other_app(temp_id)
      data = {
          id: self.id,
          topic_id: self.topic_id,
          content: self.content,
          image_url: self.img_url,
          width:  self.width,
          height: self.height,
          user_id: self.user_id,
          username: self.username,
          avatar_url: avatar_url,
          post_type: self.post_type,
          place_id: self.place_id,
          likes: self.likes,
          dislikes: self.dislikes,
          offensive: self.offensive,
          temp_id: temp_id,
          created_at: created_at,
          data: self.data,
          special_type: self.special_type
      }
    channel_name = "topic_" + self.topic_id.to_s+ "_channel"
    Pusher[channel_name].trigger_async("broadcast", data)
  end

  def broadcast_hive
   total_posts = self.topic.posts
   post_users = []
   total_posts.map {|pst| post_users.push(pst.user_id)}

    if post_users.count > 1
      post_users = post_users.uniq!
    end
    data = {
        id: self.id,
        topic_id: self.topic_id,
        content: self.content,
        image_url: self.img_url,
        width:  self.width,
        height: self.height,
        user_id: self.user_id,
        username: self.username,
        avatar_url: avatar_url,
        post_type: self.post_type,
        place_id: self.place_id,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        created_at: created_at,
        data: self.data,
        special_type: self.special_type,
        post_users: post_users
    }
    channel_name = "hive_topic_" + self.topic_id.to_s+ "_channel"
    Pusher[channel_name].trigger_async("broadcast", data)


    channel_name = "rt_comment_follow_channel"
    Pusher[channel_name].trigger_async("broadcast", data)

  end

  def update_event_broadcast_hive
    data = {
        id: self.id,
        topic_id: self.topic_id,
        content: self.content,
        image_url: self.img_url,
        width:  self.width,
        height: self.height,
        user_id: self.user_id,
        username: self.username,
        avatar_url: avatar_url,
        post_type: self.post_type,
        place_id: self.place_id,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        created_at: created_at,
        data: self.data,
        special_type: self.special_type
    }

    channel_name = "hive_topic_" + self.topic_id.to_s+ "_channel"
    Pusher[channel_name].trigger_async("update_post", data)
  end

  def update_event_broadcast_other_app
    data = {
        id: self.id,
        topic_id: self.topic_id,
        content: self.content,
        image_url: self.img_url,
        width:  self.width,
        height: self.height,
        user_id: self.user_id,
        username: self.username,
        post_type: self.post_type,
        place_id: self.place_id,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        created_at: created_at,
        data: self.data,
        special_type: self.special_type,
        other_app: true

    }

    channel_name = "topic_" + self.topic_id.to_s+ "_channel"
    Pusher[channel_name].trigger_async("update_post", data)
  end

  def delete_event_broadcast_hive
    data = {
        id: self.id,
        topic_id: self.topic_id,
        content: self.content,
        image_url: self.img_url,
        width:  self.width,
        height: self.height,
        user_id: self.user_id,
        username: self.username,
        post_type: self.post_type,
        place_id: self.place_id,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        created_at: created_at,
        data: self.data,
        special_type: self.special_type
    }

    channel_name = "hive_topic_" + self.topic_id.to_s+ "_channel"
    Pusher[channel_name].trigger_async("delete_post", data)
  end

  def delete_event_broadcast_other_app
    data = {
        id: self.id,
        topic_id: self.topic_id,
        content: self.content,
        image_url: self.img_url,
        width:  self.width,
        height: self.height,
        user_id: self.user_id,
        username: self.username,
        post_type: self.post_type,
        place_id: self.place_id,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        created_at: self.created_at,
        data: self.data ,
        special_type: self.special_type
    }

    channel_name = "topic_" + self.topic_id.to_s+ "_channel"
    Pusher[channel_name].trigger_async("delete_post", data)
  end




  # Search the database for related contents

  def self.search_data(search)
    if search
      #find(:all, :conditions => ['lower(content) LIKE ?', "%#{search.downcase}%"])
      where("lower(content) like ?", "%#{search.downcase}%")
    else
      find(:all)
    end
  end


  def user_add_likes(current_user, post_id, choice)
    actionlog = ActionLog.new
    #history = Historychange.new
    post = Post.find(post_id)
    user = User.find(current_user.id)
    post_user = User.find(post.user_id)
    topic = Topic.find(post.topic_id)

    new_post = [ ]
    testDataArray = [ ]
    test_check = false
    check_like = ActionLog.where(type_name: "post", type_id: post_id, action_type: "like", action_user_id: user.id)
    check_dislike = ActionLog.where(type_name: "post", type_id: post_id, action_type: "dislike", action_user_id: user.id)

    action_status = 0
    postsArray = Topic.find(post.topic_id).posts.where(["likes > ? OR dislikes > ?", 0, 0])

    if postsArray.present?
      postsArray.each do |pa|
        total = pa.likes + pa.dislikes
        testDataArray.push ({ total: total, id: pa.id, created_at: pa.created_at })
      end

      new_post = testDataArray.sort_by { |x| [x[:total], x[:created_at]] }
      testPost = Post.find(new_post.last[:id])
    end

    if choice == "like"
      if check_dislike.present?
        post.dislikes = post.dislikes - 1
        ActionLog.find_by_type_name_and_type_id_and_action_type_and_action_user_id("post", post_id, "dislike", user.id).delete
        test_check = true
        action_status = -1
      else
        unless check_like.present?
          post.likes = post.likes + 1
          post_user.point = post_user.point + 1
          #actionlog.create_record("post", post_id, "like", user.id)
          actionlog =   ActionLog.create(type_name: "post", type_id: post_id, action_type: "like", action_user_id: user.id)
          test_check = true

          action_status = 1
        end
      end
    elsif choice == "dislike"
      if check_like.present?
        post.likes = post.likes - 1
        post_user.point = post_user.point - 1
        ActionLog.find_by_type_name_and_type_id_and_action_type_and_action_user_id("post", post_id, "like", user.id).delete
        test_check = true
        action_status = -1
      else
        unless check_dislike.present?
          post.dislikes = post.dislikes + 1
          #actionlog.create_record("post", post_id, "dislike", user.id)
          actionlog =   ActionLog.create(type_name: "post", type_id: post_id, action_type: "dislike", action_user_id: user.id)
          test_check = true
          action_status = 1
        end
      end
    end
    post.save!
    post_user.save!
    post.reload

    #history.create_record("post", post.id, "update", self.topic_id)

    if action_status!= 0
      hiveapplication = HiveApplication.find(topic.hiveapplication_id)
      if hiveapplication.id ==1
        #broadcast new topic creation to hive_channel only
        post.update_event_broadcast_hive
        topic.update_event_broadcast_hive
      elsif hiveapplication.devuser_id==1 and hiveapplication.id!=1
        #All Applications under Herenow except Hive
        post.update_event_broadcast_hive
        post.update_event_broadcast_other_app
        topic.update_event_broadcast_hive
        topic.update_event_broadcast_other_app_with_content
      else
        #3rd party app
        post.update_event_broadcast_hive
        post.update_event_broadcast_other_app
        topic.update_event_broadcast_hive
        topic.update_event_broadcast_other_app
      end
    end

    #post.update_event_broadcast   unless action_status == 0
    #topic.update_event_broadcast  unless action_status == 0

    if test_check == true
      newTestDataArray = [ ]
      newPostsArray = Topic.find(post.topic_id).posts.where(["likes > ? OR dislikes > ?", 0, 0])
      if newPostsArray.present?
        newPostsArray.each do |npa|
          newTotal = npa.likes + npa.dislikes
          newTestDataArray.push({ total: newTotal, id: npa.id, created_at: npa.created_at })
        end

        newer_post = newTestDataArray.sort_by { |x| [x[:total], x[:created_at]] }
        newer_TestPost = Post.find(newer_post.last[:id])

        if new_post.present?
          unless testPost.id == newer_TestPost.id
            topic = Topic.find(post.topic_id)
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
        else
          topic = Topic.find(post.topic_id)
          #topic.update_event_broadcast
        end
      end

    end
    return action_status
  end

  def user_offensive_post(current_user, post_id, post)
    actionlog = ActionLog.new
    user = User.find(current_user.id)
    admin_user = User.find_by_email("info@raydiusapp.com")
    admin_user1 = User.find_by_email("gamebot@raydiusapp.com")
    check = ActionLog.where(type_name: "post", type_id: post_id, action_type: "offensive", action_user_id: user.id)
    #history = Historychange.new

    unless check.present?
      unless self.user_id == admin_user.id #or self.user_id == admin_user1.id
        post.offensive += 1
        post.save!
        post.reload
        mail = UserMailer.report_offensive_post(user, post)
        mail.deliver
        #actionlog.create_record("post", post_id, "offensive", current_user.id)
        actionlog=    ActionLog.create(type_name: "post", type_id: post_id, action_type: "offensive", action_user_id: current_user.id)
        #history.create_record("post", self.id, "update", self.topic_id)
        #post.update_event_broadcast
      end
    end
  end

  def remove_records

    checkLikedPost = ActionLog.where(type_name: "post", action_type: "like", type_id: self.id)
    checkFavouritePost = ActionLog.where(type_name: "post", action_type: "favourite", type_id: self.id)
    checkOffensivePost = ActionLog.where(type_name: "post", action_type: "offensive", type_id: self.id)

    checkLikedPost.each do |clp|
      clp.delete
    end

    checkFavouritePost.each do |cfp|
      cfp.delete
    end

    checkOffensivePost.each do |cop|
      cop.delete
    end

    s3 = Aws::S3::Client.new
    if Rails.env.development?
      bucket_name = AWS_Bucket::Image_D
    elsif Rails.env.staging?
      bucket_name = AWS_Bucket::Image_S
    else
      bucket_name = AWS_Bucket::Image_P
    end

    if self.img_url.present?
      file_name = self.img_url
      resp = s3.delete_object({
        bucket: bucket_name,
        key: file_name,
      })
    end

  end

  def self.delete_S3_file(bucket_name, file_name,post_type)
    s3 = Aws::S3::Client.new
    p file_name
    p bucket_name
    p post_type

    resp = s3.delete_object({
      bucket: bucket_name,
      key: file_name,
    })

    if post_type == Post::IMAGE    #delete medium and small version
      names = file_name.split(".")
      p sfilename = names[0] +  "_s." + names[1]
      p mfilename =  names[0] +  "_m." + names[1]

      resp = s3.delete_objects({
        bucket: bucket_name,
        delete: {
          objects: [
            {
              key: sfilename,
            },
            {
              key: mfilename,
            },
          ],
        },
      })
    end
  end

  def notify_reply_message_to_topic_owner(user_id)

    user_to_push= []
    user_to_push.push(user_id.to_s)

    #notification = {
    #  aliases: user_to_push,
    #  aps: { alert: self.content, badge: "+1", sound: "default" },
    #  post:{
    #      id: self.id,
    #      topic_id: self.topic_id,
    #      content: self.content,
    #      image_url: self.img_url,
    #      width:  self.width,
    #      height: self.height,
    #      created_at: self.created_at,
    #      user_id: self.user_id,
    #      username: self.username,
    #      post_type: self.post_type,
    #      place_id: self.place_id,
    #      likes: self.likes,
    #      dislikes: self.dislikes,
    #      offensive: self.offensive,
    #      created_at: self.created_at,
    #      data: self.data
    #  }
    #}.to_json


    user= User.find_by_id(user_id)
    if user.data.present?
      hash_array = user.data
      to_device_id = hash_array["device_id"] if  hash_array["device_id"].present?
    end

    if Rails.env.production?
      appID = PushWoosh_Const::CM_P_APP_ID
    elsif Rails.env.staging?
      appID = PushWoosh_Const::CM_S_APP_ID
    else
      appID = PushWoosh_Const::CM_D_APP_ID
    end

    @auth = {:application  => appID ,:auth => PushWoosh_Const::API_ACCESS}

    notification_options = {
        send_date: "now",
        badge: "1",
        sound: "default",
        content:{
            fr:self.content,
            en:self.content
        },

        data:{
            post:{
                id: self.id,
                topic_id: self.topic_id,
                content: self.content,
                image_url: self.img_url,
                width:  self.width,
                height: self.height,
                user_id: self.user_id,
                username: self.username,
                post_type: self.post_type,
                place_id: self.place_id,
                likes: self.likes,
                dislikes: self.dislikes,
                offensive: self.offensive,
                created_at: self.created_at,
                data: self.data
            }
        },
        devices: [to_device_id]
    }

    options = @auth.merge({:notifications  => [notification_options]})
    options = {:request  => options}

    full_path = 'https://cp.pushwoosh.com/json/1.3/createMessage'
    url = URI.parse(full_path)
    req = Net::HTTP::Post.new(url.path, initheader = {'Content-Type' =>'application/json'})
    req.body = options.to_json
    con = Net::HTTP.new(url.host, url.port)
    con.use_ssl = true

    r = con.start {|http| http.request(req)}
    p "create post broadcast"
    p "pushwoosh"

  end

  def post_image_upload_delayed_job(filename)
    p "delayed job starts!"
    uploader = PhotoUploader.new
    uploader.retrieve_from_store!(File.basename(filename))
    uploader.cache_stored_file!
    uploader.resize_to_fit(uploader.get_geometry[0]/5,uploader.get_geometry[1]/5)
    uploader.store!
    p "delayed job ends!"
  end

  def fav_topic_push_notification
    usersArray = [ ]
    blockUsersArray = [ ]
    pushUsers = [ ]
    topic = Topic.find(self.topic_id)

    usersFavouritedTopic = ActionLog.where(type_name: "topic", action_type: "favourite", type_id: self.topic_id)
    blocked_current_user = ActionLog.where(type_name: "user", action_type: "block", type_id: self.user_id)

    usersFavouritedTopic.map { |u| usersArray.push(u.action_user_id) unless usersArray.include?(u.action_user_id) } if usersFavouritedTopic.present?
    blocked_current_user.map { |u| blockUsersArray.push(u.action_user_id) unless blockUsersArray.include?(u.action_user_id) } if blocked_current_user.present?

    if blocked_current_user.present? &&  usersFavouritedTopic.present?
      users = User.all(:conditions => ["id not in (?) and id in (?)", blockUsersArray,usersArray])
    elsif  blocked_current_user.count == 0 &&  usersFavouritedTopic.present?
      users = User.all(:conditions => ["id in (?)", usersArray])
    elsif blocked_current_user.present? && usersFavouritedTopic.count==0
      users = User.all(:conditions => ["id not in (?)", blockUsersArray])
    end


    if Rails.env.production?
      appID = PushWoosh_Const::FV_P_APP_ID
    elsif Rails.env.staging?
      appID = PushWoosh_Const::FV_S_APP_ID
    else
      appID = PushWoosh_Const::FV_D_APP_ID
    end

    @auth = {:application  => appID ,:auth => PushWoosh_Const::API_ACCESS}


    if users.present?
      users.each do |u|
        pushUsers.push(u.id.to_s)
      end

      users.each do |user|
        if user.data.present?
          hash_array = user.data
          device_id = hash_array["device_id"] if  hash_array["device_id"].present?
          to_device_id.push(device_id)
        end
      end

      if topic.place_id.present?
        place = Place.find(topic.place_id)

        #notification = {
        #    aliases: pushUsers,
        #    aps: { alert: "A topic you are subscribed to has been updated.", badge: "+1", sound: "default" },
        #    topic_title: Topic.find(self.topic_id).title,
        #    topic_id: self.topic_id,
        #    content: self.content[0..14],
        #    post_author: self.username,
        #    place_name: place.name
        #}
        #Urbanairship.push(notification)

        notification_options = {
            send_date: "now",
            badge: "1",
            sound: "default",
            content:{
                fr:"A topic you are subscribed to has been updated.",
                en:"A topic you are subscribed to has been updated."
            },
            data:{  topic_title: Topic.find(self.topic_id).title,
                    topic_id: self.topic_id,
                    content: self.content[0..14],
                    post_author: self.username,
                    place_name: place.name
            },
            devices: to_device_id
        }

        options = @auth.merge({:notifications  => [notification_options]})
        options = {:request  => options}

        full_path = 'https://cp.pushwoosh.com/json/1.3/createMessage'
        url = URI.parse(full_path)
        req = Net::HTTP::Post.new(url.path, initheader = {'Content-Type' =>'application/json'})
        req.body = options.to_json
        con = Net::HTTP.new(url.host, url.port)
        con.use_ssl = true

        r = con.start {|http| http.request(req)}

        p "pushwoosh"

      else
        #notification = {
        #    aliases: pushUsers,
        #    aps: { alert: "A topic you are subscribed to has been updated.", badge: "+1", sound: "default" },
        #    topic_title: Topic.find(self.topic_id).title,
        #    topic_id: self.topic_id,
        #    content: self.content[0..14],
        #    post_author: self.username,
        #    address: topic.address
        #}
        #
        #Urbanairship.push(notification)

        notification_options = {
            send_date: "now",
            badge: "1",
            sound: "default",
            content:{
                fr:"A topic you are subscribed to has been updated.",
                en:"A topic you are subscribed to has been updated."
            },
            data:{  topic_title: Topic.find(self.topic_id).title,
                    topic_id: self.topic_id,
                    content: self.content[0..14],
                    post_author: self.username,
                    address: topic.address
            },
            devices: to_device_id
        }

        options = @auth.merge({:notifications  => [notification_options]})
        options = {:request  => options}

        full_path = 'https://cp.pushwoosh.com/json/1.3/createMessage'
        url = URI.parse(full_path)
        req = Net::HTTP::Post.new(url.path, initheader = {'Content-Type' =>'application/json'})
        req.body = options.to_json
        con = Net::HTTP.new(url.host, url.port)
        con.use_ssl = true

        r = con.start {|http| http.request(req)}

        p "pushwoosh"

      end
    end
  end

  handle_asynchronously :post_image_upload_delayed_job
end
