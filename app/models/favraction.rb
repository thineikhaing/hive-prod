class Favraction < ActiveRecord::Base
  belongs_to :user
  belongs_to :topic

  has_one :topic
  has_many :users

  validates :topic_id, presence: true
  validates :doer_user_id, presence: true

  #enum for favr action status
  enums %w(DEFAULT DOER_STARTED DOER_FINISHED OWNER_ACKNOWLEDGED OWNER_REJECTED DOER_RESPONDED_ACK DOER_RESPONDED_REJ OWNER_REVOKED COMPLETION_REMINDER_SENT EXPIRED_AFTER_STARTED EXPIRED_AFTER_FINISHED EXPIRED)

  def create_record(topic_id, doer_user_id, status, user_id)
    Favraction.create(topic_id: topic_id, doer_user_id: doer_user_id, status: status, user_id: user_id)
  end
  def as_json(options=nil)
    super(only: [:id, :topic_id, :content, :doer_user_id, :status, :user_id, :created_at, :updated_at, :post_id, :honor_to_owner, :honor_to_doer])
  end

  def delay_send_notifiction_to_doer
    p "timer delay job for " + self.id.to_s
    action_topic = Topic.find(self.topic_id)
    p action_topic
    user = User.find_by_username("FavrBot")
    doer = User.find(self.doer_user_id)
    user_to_push=[]
    user_to_push.push(doer.id.to_s)

    p "before urban airship"
    if action_topic.present?
      notification = {
          aliases: user_to_push,
          aps: { alert: "Remember to finish the task", badge: "+1", sound: "default" },
          topic_id: action_topic.id
      }.to_json
      p notification
      if Rails.env.production?
        p "production"
        app_key = Urbanairship_Const::FV_P_Key
        app_secret = Urbanairship_Const::FV_P_Secret
        master_secret= Urbanairship_Const::FV_P_Master_Secret
      elsif Rails.env.staging?
        p "staging"
        app_key = Urbanairship_Const::FV_S_Key
        app_secret= Urbanairship_Const::FV_S_Secret
        master_secret= Urbanairship_Const::FV_S_Master_Secret
      else
        p "development"
        app_key = Urbanairship_Const::FV_D_Key
        app_secret= Urbanairship_Const::FV_D_Secret
        master_secret= Urbanairship_Const::FV_D_Master_Secret
      end
      p "after setting"
      full_path = 'https://go.urbanairship.com/api/push/'
      url = URI.parse(full_path)
      req = Net::HTTP::Post.new(url.path, initheader = {'Content-Type' =>'application/json'})
      req.body = notification
      req.basic_auth app_key, master_secret
      p "HTTP New"
      con = Net::HTTP.new(url.host, url.port)
      con.use_ssl = true

      r = con.start {|http| http.request(req)}
      p "after sent"

      logger.info "\n\n##############\n\n  " + "Resonse body: " + r.body + "  \n\n##############\n\n"

      p "after urban airship"
      p user_to_push

      self.status= COMPLETION_REMINDER_SENT
      self.save!

      title = "Completion reminder has been sent to " + doer.username
      post = Post.new
      temp_id= "favrbot1"
      post.create_record(title, self.topic_id, user.id, Post::TEXT.to_s, action_topic.latitude, action_topic.longitude,temp_id,0,0,true,self.id)
    end
  end

  def delay_change_favr_topic_status
    p "delay favr action task job for " + self.id.to_s
    action_topic = Topic.find(self.topic_id)
    user = User.find_by_username("FavrBot")
    doer = User.find(self.doer_user_id)
    if action_topic.state == Topic::IN_PROGRESS
      action_topic.state = Topic::TASK_EXPIRED
      action_topic.save!

      self.status =EXPIRED_AFTER_STARTED
      self.save!

      title = "This task is already expired"
      temp_id= "favrbot2"
      post = Post.new
      post.create_record(title, action_topic.id, user.id, Post::TEXT.to_s, action_topic.latitude, action_topic.longitude,temp_id,0,0,true,self.id)
      sent_expire_notificatoin
    elsif action_topic.state == Topic::FINISHED
      action_topic.state = Topic::TASK_EXPIRED
      action_topic.save!

      total_points = action_topic.free_points + action_topic.points
      doer.points += (total_points/2.0).ceil
      doer.save!
      #doer.update_user_points
      data = {
          user_id: doer.id,
          points: doer.points
      }
      Pusher["favr_channel"].trigger  "update_user_points", data

      self.status = EXPIRED_AFTER_FINISHED
      self.save!

      title = "This task is already expired"
      temp_id= "favrbot2"
      post = Post.new

      post.create_record(title, action_topic.id, user.id, Post::TEXT.to_s, action_topic.latitude, action_topic.longitude,temp_id,0,0,true,self.id)
      sent_expire_notificatoin
    end
  end

  def sent_expire_notificatoin
    p "inside urban airship function"
    action_topic = Topic.find(self.topic_id)
    p action_topic
    users_to_sent=[]
    users_to_sent.push ( action_topic.user_id.to_s )
    users_to_sent.push ( self.doer_user_id.to_s )

    p "before urban airship"
    if action_topic.present?
      notification = {
          aliases: users_to_sent,
          aps: { alert: "Your favr request is expired", badge: "+1", sound: "default" },
          topic_id: action_topic.id
      }.to_json

      if Rails.env.production?
        p "production"
        app_key = Urbanairship_Const::FV_P_Key
        app_secret = Urbanairship_Const::FV_P_Secret
        master_secret= Urbanairship_Const::FV_P_Master_Secret
      elsif Rails.env.staging?
        p "staging"
        app_key = Urbanairship_Const::FV_S_Key
        app_secret= Urbanairship_Const::FV_S_Secret
        master_secret= Urbanairship_Const::FV_S_Master_Secret
      else
        p "development"
        app_key = Urbanairship_Const::FV_D_Key
        app_secret= Urbanairship_Const::FV_D_Secret
        master_secret= Urbanairship_Const::FV_D_Master_Secret
      end
      p "after setting"
      full_path = 'https://go.urbanairship.com/api/push/'
      url = URI.parse(full_path)
      req = Net::HTTP::Post.new(url.path, initheader = {'Content-Type' =>'application/json'})
      req.body = notification
      req.basic_auth app_key, master_secret
      p "HTTP New"
      con = Net::HTTP.new(url.host, url.port)
      con.use_ssl = true

      r = con.start {|http| http.request(req)}
      p "after sent"
      p users_to_sent
      logger.info "\n\n##############\n\n  " + "Resonse body: " + r.body + "  \n\n##############\n\n"

      p "after urban airship"
    end
  end


end