require 'obscenity/active_model'

class Post < ActiveRecord::Base
  belongs_to :topic
  belongs_to :user
  delegate :username, to: :user
  delegate :pub_sub_channel, to: :topic

  # Setup hstore
  store_accessor :data

  attr_accessible :content, :post_type, :data, :created_at, :user_id, :topic_id, :place_id,:likes, :dislikes, :offensive, :img_url, :width, :height
  enums %w(TEXT IMAGE AUDIO VIDEO)
  validates :content, presence: true
  validates :content, obscenity: { sanitize: true, replacement: "snork" }

  def as_json(options=nil)
    super(only: [:id, :topic_id, :content, :created_at, :user_id, :post_type,:place_id,:likes, :dislikes, :offensive, :width, :height, :data, :created_at], methods: [:username, :image_url])
  end

  def image_url
    self.img_url
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
        history_id: 0
    }

    Pusher[self.pub_sub_channel].trigger_async("broadcast", data)
  end

  def broadcast_other_app(temp_id)
      data = {
          id: self.id,
          topic_id: self.topic_id,
          content: self.content,
          image_url: self.img_url,
          width:  self.width,
          height: self.height,
          created_at: self.created_at,
          user_id: self.user_id,
          username: self.username,
          post_type: self.post_type,
          place_id: self.place_id,
          likes: self.likes,
          dislikes: self.dislikes,
          offensive: self.offensive,
          temp_id: temp_id,
          created_at: created_at,
          data: self.data
      }
    channel_name = "topic_" + self.topic_id.to_s+ "_channel"
    Pusher[channel_name].trigger_async("broadcast", data)
  end

  def broadcast_hive
    data = {
        id: self.id,
        topic_id: self.topic_id,
        content: self.content,
        image_url: self.img_url,
        width:  self.width,
        height: self.height,
        created_at: self.created_at,
        user_id: self.user_id,
        username: self.username,
        post_type: self.post_type,
        place_id: self.place_id,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        created_at: created_at,
        data: self.data,
    }
    channel_name = "hive_topic_" + self.topic_id.to_s+ "_channel"
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
        created_at: self.created_at,
        user_id: self.user_id,
        username: self.username,
        post_type: self.post_type,
        place_id: self.place_id,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        created_at: created_at,
        data: self.data
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
        created_at: self.created_at,
        user_id: self.user_id,
        username: self.username,
        post_type: self.post_type,
        place_id: self.place_id,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        created_at: created_at,
        data: self.data
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
        created_at: self.created_at,
        user_id: self.user_id,
        username: self.username,
        post_type: self.post_type,
        place_id: self.place_id,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        created_at: created_at,
        data: self.data
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
        created_at: self.created_at,
        user_id: self.user_id,
        username: self.username,
        post_type: self.post_type,
        place_id: self.place_id,
        likes: self.likes,
        dislikes: self.dislikes,
        offensive: self.offensive,
        created_at: created_at,
        data: self.data
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

  end

  def delete_S3_file(bucket_name, file_name,post_type)
    s3= AWS::S3::new(
        :access_key_id      => 'AKIAIJMZ5RLXRO6LJHPQ',     # required
        :secret_access_key  => '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',    # required
        :region => "ap-southeast-1",
    )
    bucket = s3.buckets[bucket_name]
    object = bucket.objects[file_name]
    object.delete

    if post_type == Post::IMAGE    #delete medium and small version
      names = file_name.split(".")
      sfilename = names[0] +  "_s." +  names[1]
      mfilename =  names[0] +  "_m." + names[1]

      object = bucket.objects[sfilename]
      object.delete

      object = bucket.objects[mfilename]
      object.delete
    end

  end

  def notify_reply_message_to_topic_owner(app_key, master_secret, user_id)
    #topic = Topic.find(self.topic_id)
    user_to_push= []
    user_to_push.push(user_id.to_s)
    notification = {
      aliases: user_to_push,
      aps: { alert: self.content, badge: "+1", sound: "default" },
      post:{
          id: self.id,
          topic_id: self.topic_id,
          content: self.content,
          image_url: self.img_url,
          width:  self.width,
          height: self.height,
          created_at: self.created_at,
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
    }.to_json

    p "user_to_push"
    p user_to_push
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
  end

  def post_image_upload_delayed_job(filename)
    p "delayed job starts!"
    uploader = PhotoUploader.new
    uploader.retrieve_from_store!(filename)
    uploader.cache_stored_file!
    uploader.resize_to_fit(uploader.get_geometry[0]/5,uploader.get_geometry[1]/5)
    uploader.store!
    p "delayed job ends!"
  end
  handle_asynchronously :post_image_upload_delayed_job
end
