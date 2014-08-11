require 'obscenity/active_model'

class Post < ActiveRecord::Base
  belongs_to :topic
  belongs_to :user
  delegate :username, to: :user

  # Setup hstore
  store_accessor :data

  attr_accessible :content, :post_type, :data, :created_at, :user_id, :topic_id, :place_id,:likes, :dislikes, :offensive, :img_url, :width, :height
  enums %w(TEXT IMAGE AUDIO VIDEO)
  validates :content, presence: true
  validates :content, obscenity: { sanitize: true, replacement: "snork" }

  def as_json(options=nil)
    super(only: [:id, :topic_id, :content, :created_at, :user_id, :post_type,:place_id,:likes, :dislikes, :offensive,:img_url, :width, :height, :data], methods: [:username])
  end


  def broadcast_other_app
      data = {
          id: self.id,
          topic_id: self.topic_id,
          content: self.content,
          img_url: self.img_url,
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
        img_url: self.img_url,
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
    }
    channel_name = "topic_" + self.topic_id.to_s+ "_channel"
    Pusher[channel_name].trigger_async("broadcast", data)
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
          post_user.points = post_user.points + 1
          ActionLog.create_record("post", post_id, "like", user.id)
          test_check = true
          action_status = 1
        end
      end
    elsif choice == "dislike"
      if check_like.present?
        post.likes = post.likes - 1
        post_user.points = post_user.points - 1
        ActionLog.find_by_type_name_and_type_id_and_action_type_and_action_user_id("post", post_id, "like", user.id).delete
        test_check = true
        action_status = -1
      else
        unless check_dislike.present?
          post.dislikes = post.dislikes + 1
          actionlog.create_record("post", post_id, "dislike", user.id)
          test_check = true
          action_status = 1
        end
      end
    end
    post.save!
    post_user.save!
    post.reload

    #history.create_record("post", post.id, "update", self.topic_id)
    #post.update_event_broadcast   unless action_status == 0
    #topic.update_event_broadcast  unless action_status == 0

    if test_check == true
      newTestDataArray = [ ]
      newPostsArray = Topic.find(post.topic_id).posts.where(["likes > ? OR dislikes > ?", 0, 0])

      newPostsArray.each do |npa|
        newTotal = npa.likes + npa.dislikes
        newTestDataArray.push({ total: newTotal, id: npa.id, created_at: npa.created_at })
      end
      newer_post = newTestDataArray.sort_by { |x| [x[:total], x[:created_at]] }
      newer_TestPost = Post.find(newer_post.last[:id])

      if new_post.present?
        unless testPost.id == newer_TestPost.id
          topic = Topic.find(post.topic_id)
          topic.update_event_broadcast
        end
      else
        topic = Topic.find(post.topic_id)
        topic.update_event_broadcast
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
      unless self.user_id == admin_user.id or self.user_id == admin_user1.id
        post.offensive += 1
        post.save!
        post.reload
        #mail = UserMailer.report_offensive_post(user, post)
        #mail.deliver
        actionlog.create_record("post", post_id, "offensive", current_user.id)
        #history.create_record("post", self.id, "update", self.topic_id)
        #post.update_event_broadcast
      end
    end
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

end
