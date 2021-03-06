require 'value_enums'
class Topic < ActiveRecord::Base
  include UserHelper
  belongs_to :hiveapplication
  belongs_to :user
  belongs_to :place
  belongs_to :start_place, class_name: "Place", foreign_key: "start_place_id",primary_key: :id
  belongs_to :end_place, class_name: "Place", foreign_key: "end_place_id",primary_key: :id

  has_many :topic_with_tags

  has_many  :posts, :dependent => :destroy
  has_many :suggesteddates
  has_many :votes
  has_many :invitees

  has_many :historychanges

  delegate :latitude, :longitude, :address, :name, to: :place

  # Setup hstore
  store_accessor :data

  def self.current=(user)
    Thread.current[:current_user] = user
  end

  def self.current
    Thread.current[:current_user]
  end

  # hstore_accessor :options,
  #     color: :string,
  #     weight: :integer,
  #     price: :float,
  #     built_at: :datetime,
  #     build_date: :date,
  #     tags: :array, # deprecated
  #     ratings: :hash # deprecated
  #     miles: :decimal
  #
  #enums for topic type

  scope :this_month, -> { where(created_at: Time.now.beginning_of_month..Time.now.end_of_month) }

  enums %w(NORMAL IMAGE AUDIO VIDEO RPSGAME WEB POLL LUNCHEON FAVR CARMMUNICATE TRAINFAULT)

  enums %w(NONE FLARE BEACON STICKY PROMO COSHOOT QUESTION ERRAND)

  #Topic states
  enums %w(DEFAULT OPENED IN_PROGRESS FINISHED ACKNOWLEDGED REJECTED REVOKED TASK_EXPIRED EXPIRED)

  #Favr Actions
  enums %w(CREATE START FINISH ACKNOWLEDGE REJECT REVOKE REOPEN EXTEND REMINDER_TIMEUP TASK_TIMEUP FAVR_TIMEUP )
  enums %w(NO YES)

  paginates_per 5


  #attr_accessible :title, :topic_type, :topic_sub_type, :place_id, :hiveapplication_id, :user_id, :data, :created_at,
                  # :image_url, :width, :height, :value, :unit, :likes, :dislikes, :offensive, :notification_range,
                  # :special_type , :extra_info, :valid_start_date, :valid_end_date, :points, :free_points, :state,
                  # :title_indexes, :checker, :given_time

  # Return the tags and location tags related to the topic

  def tag_information
    tags = TopicWithTag.where(topic_id: self.id)
    { tags: tags }
  end

  def as_json(options=nil)
    if options[:content].present?      #return topic json with content information
      super(only: [:id, :state, :title, :points, :free_points, :topic_type, :topic_sub_type, :place_id, :hiveapplication_id,
                   :user_id, :image_url,:width, :height, :data, :value, :unit, :likes, :dislikes, :offensive, :notification_range,
                   :special_type,:start_place_id, :end_place_id, :created_at], methods: [:username,:avatar_url,:local_avatar, :place_information,
                                                                                         :rtplaces_information, :post_information,
                                                                                         :content, :active_user])
    else
      super(only: [:id,:state, :title, :points, :free_points, :topic_type, :topic_sub_type, :place_id, :hiveapplication_id,
                   :user_id, :image_url,:width, :height, :data, :value, :unit, :likes, :dislikes, :offensive, :notification_range,
                   :special_type,:start_place_id, :end_place_id, :created_at], methods: [:username, :avatar_url,:local_avatar, :place_information,
                                                                                        :post_information,:rtplaces_information, :content,:active_user])
    end
  end


  def username
    User.find_by_id(self.user_id).username
  end

  def avatar_url
    User.find_by_id(self.user_id).avatar_url.url
    # if Rails.env.development?
    #   bucket = AWS_Bucket::Avatar_D
    # elsif Rails.env.staging?
    #   bucket = AWS_Bucket::Avatar_S
    # else
    #   bucket = AWS_Bucket::Avatar_P
    # end
    # if !User.find_by_id(self.user_id).avatar_url.url.nil?
    #   avatar = "https://s3.ap-southeast-1.amazonaws.com/"+bucket+"/"+self.user_id.to_s+".jpeg"
    # else
    #   avatar = nil
    # end
    # return avatar

  end


  def local_avatar
    Topic.get_avatar(self.username)
  end

  def place_information
    if self.place_id.present? and self.place_id > 0
      place = Place.find(self.place_id)
      { id: place.id, name: place.name, latitude: place.latitude, longitude: place.longitude, address: place.address, category: place.category, source: place.source, source_id: place.source_id, user_id: place.user_id, country: place.country, postal_code: place.postal_code, chain_name: place.chain_name, contact_number: place.contact_number, img_url: place.img_url,locality: place.locality, region: place.region, neighbourhood: place.neighbourhood, data: place.data }
    else
      { id: nil, name: nil, latitude: nil, longitude: nil, address: nil , custom_pin_url: nil, source: nil, user_id: nil, popular: nil }
    end
  end


  def post_information
    first_post = Post.where(topic_id: self.id).last
  end


  def rtplaces_information
    @client = GooglePlaces::Client.new(GoogleAPI::Google_Key)
    rt_user = Topic.current

    if self.start_place_id.present? and self.start_place_id > 0
      place = Place.find(self.start_place_id)

      if rt_user.present?
        fav = UserFavLocation.where(user_id: rt_user.id, place_id: place.id).take
      end

      if fav.present?
        place_name = fav.name
      elsif place.short_name.present? && place.source != Place::HERENOW.to_s
        if place.name.length >= 6
          p = place.name.last(6).to_s
          if p.count("0-9") == 6
            place_name = place.short_name
          else
            place_name = place.name
          end
        else
          place_name = place.name
        end

      else
        place_name = place.name
      end

      start_place = { id: place.id, name: place_name, short_name: place.short_name, latitude: place.latitude,
          longitude: place.longitude, address: place.address,
          category: place.category, source: place.source,
          source_id: place.source_id, user_id: place.user_id,
          country: place.country, postal_code: place.postal_code,
          chain_name: place.chain_name, contact_number: place.contact_number,
          img_url: place.img_url,locality: place.locality, region: place.region,
          neighbourhood: place.neighbourhood, data: place.data }
    else
      { id: nil, name: nil, latitude: nil, longitude: nil, address: nil , custom_pin_url: nil, source: nil, user_id: nil, popular: nil }
    end

    if self.end_place_id.present? and self.end_place_id > 0
      place = Place.find(self.end_place_id)

      if rt_user.present?
        fav = UserFavLocation.where(user_id: rt_user.id, place_id: place.id).take
      end

      if fav.present?
        place_name = fav.name
      elsif place.short_name.present? && place.source != Place::HERENOW.to_s
        if place.name.length >= 6
          p = place.name.last(6).to_s
          if p.count("0-9") == 6
            place_name = place.short_name
          else
              place_name = place.name
          end

        else
          place_name = place.name
        end

      else
        place_name = place.name
      end

      end_place = { id: place.id, name: place_name, short_name: place.short_name, latitude: place.latitude,
          longitude: place.longitude, address: place.address,
          category: place.category, source: place.source,
          source_id: place.source_id, user_id: place.user_id,
          country: place.country, postal_code: place.postal_code,
          chain_name: place.chain_name, contact_number: place.contact_number,
          img_url: place.img_url,locality: place.locality, region: place.region,
          neighbourhood: place.neighbourhood, data: place.data }
    else
      { id: nil, name: nil, latitude: nil, longitude: nil, address: nil , custom_pin_url: nil, source: nil, user_id: nil, popular: nil }
    end


    { start_place: start_place, end_place: end_place}


  end

  def active_user
    return 0
    # if (self.place_id != 0)
      # place = Place.find(self.place_id)
      # posts = self.posts
      # users = User.nearest(place.latitude, place.longitude, 1)
      #
      # usersArray = []
      # active_users = []
      # post_users = []
      #
      # posts.each do |post|
      #   post_users.push(post.user_id)
      # end
      #
      # post_users = post_users & post_users
      #
      # time_allowance = Time.now - 2.weeks.ago
      # users.each do |u|
      #   usersArray.push(u)
      #   active_users.push(u.id)
      # end
      # # p "post user and active users"
      # # p post_users
      # # p active_users
      #
      # active_post_user = post_users
    #   return active_post_user.count
    # end

  end


  # Check for special type for topic creation

  def self.check_special_type(flare, beacon, sticky, promo, coshoot,question,errand)
    special_type = ""
    special_type.present? ? special_type << "," << FLARE.to_s : special_type << FLARE.to_s if flare.present?
    special_type.present? ? special_type << "," << BEACON.to_s : special_type << BEACON.to_s if beacon.present?
    special_type.present? ? special_type << "," << STICKY.to_s : special_type << STICKY.to_s if sticky.present?
    special_type.present? ? special_type << "," << PROMO.to_s : special_type << PROMO.to_s if promo.present?
    special_type.present? ? special_type << "," << COSHOOT.to_s : special_type << COSHOOT.to_s if coshoot.present?
    special_type.present? ? special_type << "," << QUESTION.to_s : special_type << QUESTION.to_s if question.present?
    special_type.present? ? special_type << "," << ERRAND.to_s : special_type << ERRAND.to_s if errand.present?
    special_type
  end

  def hive_broadcast
    Topic.current = nil

    data = {
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        topic_type: self.topic_type,
        state: self.state,
        topic_sub_type: self.topic_sub_type,
        place_id: self.place_id,
        start_place_id:self.start_place_id,
        end_place_id: self.end_place_id,
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
        points: self.points,
        free_points:self.free_points,
        data: self.data,
        methods: {
            username: username,
            place_information: self.place_information,
            tag_information: self.tag_information,
            rtplaces_information:rtplaces_information
        }
    }

    Pusher["hive_channel"].trigger_async("new_topic", data)
  end

  def app_broadcast
    Topic.current = nil

    hiveapplication = HiveApplication.find(self.hiveapplication_id)
    data = {
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        topic_type: self.topic_type,
        state: self.state,
        topic_sub_type: self.topic_sub_type,
        place_id: self.place_id,
        start_place_id:self.start_place_id,
        end_place_id: self.end_place_id,
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
        points: self.points,
        free_points:self.free_points,
        methods: {
            username: username,
            avatar_url: avatar_url,
            place_information: self.place_information,
            tag_information: self.tag_information,
            rtplaces_information:rtplaces_information
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
        state: self.state,
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
        points: self.points,
        free_points:self.free_points,
        methods: {
            content: self.content,
            username: username,
            place_information: self.place_information,
            tag_information: self.tag_information,
            rtplaces_information:rtplaces_information
        }
    }
    channel_name = hiveapplication.api_key+ "_channel"
    Pusher[channel_name].trigger_async("new_topic", data)

    p "channel_name"
    p channel_name
    p "trigger new topic pusher app_broadcast"

  end

  def update_event_broadcast_hive
    data = {
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        topic_type: self.topic_type,
        state: self.state,
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
        points: self.points,
        free_points:self.free_points,
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
        state: self.state,
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
        points: self.points,
        free_points:self.free_points,
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
        state: self.state,
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
        points: self.points,
        free_points:self.free_points,
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

  def content(post_id=-1,action_id=-1)

    # p "get content of topic"

    testDataArray = [ ]
    if action_id > -1
      post_content = ""
      post_created_at = ""
      favr_action = Favraction.find(action_id)
      if favr_action.present?
        doer = User.find(favr_action.doer_user_id)
        doer_name = doer.username
        if post_id > -1
          post = Post.find(post_id)
          post_content= post.content
          post_created_at = post.created_at
        end
        p "update even content"
        p  favr_action.status
        p favr_action.id
        action = {action_id: favr_action.id,topic_id:favr_action.topic_id,
                  status: favr_action.status,doer_id:favr_action.doer_user_id,
                  doer_name: doer_name,post_id: post_id, post_content: post_content,
                  post_created_at: post_created_at, honor_to_doer: favr_action.honor_to_doer,
                  honor_to_owner: favr_action.honor_to_owner,
                  user_id: favr_action.user_id,
                  created_at:favr_action.created_at,
                  updated_at:favr_action.updated_at}
        {action: action}

      end
    end

    hiveapplication = HiveApplication.find(self.hiveapplication_id)

    if hiveapplication.present?

      if Rails.env.development?
        mealbox_key = Mealbox_key::Development_Key
      elsif Rails.env.staging?
        mealbox_key = Mealbox_key::Staging_Key
      else
        mealbox_key = Mealbox_key::Production_Key
      end

      if hiveapplication.api_key ==  mealbox_key   #api key for mealbox
        p "api key for mealbox"

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
          p "popular post"
          { popular_post: post, comment_post: self.posts.first}
        else
          p "popular post nil?"
          { popular_post: nil,comment_post: self.posts.first}
        end
      end
    end

  end

  def update_event_broadcast(postid=-1,action_id = -1)
    p "update event boradcast"

    avatar = User.find_by_id(self.user_id).avatar_url
    if avatar.nil?
      username = User.find_by_id(self.user_id).username

      if username  == "FavrBot"
        avatar = "assets/Avatars/Chat-Avatar-Admin.png"
      else
        avatar = Topic.get_avatar(username)
      end

    end

    data = {
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        topic_type: self.topic_type,
        offensive: self.offensive,
        likes: self.likes,
        dislikes: self.dislikes,
        radius: nil,
        extra_info: self.extra_info,
        state: self.state,
        points: self.points,
        free_points:self.free_points,
        title_indexes:self.title_indexes,
        checker:self.checker,
        given_time: self.given_time,
        valid_start_date: self.valid_start_date,
        valid_end_date: self.valid_end_date,
        avatar_url: avatar,

        methods: [
            last_post_at: self.last_post_at,
            url: nil,
            username: self.username,
            flare: self.type_flare,
            beacon: self.type_beacon,
            sticky: self.type_sticky,
            promo: self.type_promo,
            coshoot:self.type_coshoot,
            question:self.type_question,
            errand:self.type_errand,
            content: self.content(postid,action_id),
            place_information: self.place_information,
            tag_information: self.tag_information
        ],
        history_id: Historychange.where(type_name: "topic", type_action: "update", type_id: self.id).last.id
    }

      Pusher["favr_channel"].trigger  "update_topic", data

  end

  def delete_event_broadcast_hive
    data = {
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        topic_type: self.topic_type,
        state: self.state,
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
        points: self.points,
        free_points:self.free_points,
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
        state: self.state,
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
        points: self.points,
        free_points:self.free_points,
        methods: {
            username: username,
            place_information: self.place_information,
            tag_information: self.tag_information
        }
    }
    channel_name = hiveapplication.api_key + "_channel"
    Pusher[channel_name].trigger_async("delete_topic", data)
  end

  #def overall_broadcast
  #  data = {
  #      id: self.id,
  #      title: self.title,
  #      user_id: self.user_id,
  #      topic_type: self.topic_type,
  #      offensive: self.offensive,
  #      likes: self.likes,
  #      dislikes: self.dislikes,
  #      extra_info: self.extra_info,
  #      state: self.state,
  #      points: self.points,
  #      free_points:self.free_points,
  #      title_indexes:self.title_indexes,
  #      checker: self.checker,
  #      given_time: self.given_time,
  #      valid_start_date: self.valid_start_date,
  #      valid_end_date: self.valid_end_date,
  #      methods: [
  #
  #          username: self.username,
  #
  #          place_information: self.place_information,
  #          tag_information: self.tag_information
  #      ],
  #  }
  #
  #    Pusher["favr_channel"].trigger_async("new_topic", data)
  #  p "Favr Channer Trigger"
  #end

  # Check if flare exists

  def type_flare
    type = self.special_type.split(",")

    if type.present?
      if type.include?(FLARE.to_s)
        return YES
      else
        return NO
      end
    else
      return NO
    end
  end

  # Check if beacon exists

  def type_beacon
    type = self.special_type.split(",")

    if type.present?
      if type.include?(BEACON.to_s)
        return YES
      else
        return NO
      end
    else
      return NO
    end
  end

  # Check if sticky exists

  def type_sticky
    type = self.special_type.split(",")

    if type.present?
      if type.include?(STICKY.to_s)
        return YES
      else
        return NO
      end
    else
      return NO
    end
  end

  def type_promo
    type = self.special_type.split(",")

    if type.present?
      if type.include?(PROMO.to_s)
        return YES
      else
        return NO
      end
    else
      return NO
    end
  end

  def type_coshoot
    type = self.special_type.split(",")

    if type.present?
      if type.include?(COSHOOT.to_s)
        return YES
      else
        return NO
      end
    else
      return NO
    end
  end

  def type_question
    type = self.special_type.split(",")

    if type.present?
      if type.include?(QUESTION.to_s)
        return YES
      else
        return NO
      end
    else
      return NO
    end
  end

  def type_errand
    type = self.special_type.split(",")

    if type.present?
      if type.include?(ERRAND.to_s)
        return YES
      else
        return NO
      end
    else
      return NO
    end
  end

  def last_post_at
    posts.blank? ? self.created_at : posts.first.created_at
  end


  def overall_broadcast

     hiveapplication = HiveApplication.find_by_app_name('Favr')
     self.hiveapplication_id = hiveapplication.id
     self.save

     p self.user.username

     avatar = User.find_by_id(self.user_id).avatar_url
     if avatar.nil?
       username = User.find_by_id(self.user_id).username

       if username  == "FavrBot"
         avatar = "assets/Avatars/Chat-Avatar-Admin.png"
       else
         avatar = Topic.get_avatar(username)
       end
     end

    data = {
        created_at: self.created_at,
        id: self.id,
        title: self.title,
        user_id: self.user_id,
        topic_type: self.topic_type,
        offensive: self.offensive,
        likes: self.likes,
        dislikes: self.dislikes,
        radius: nil,
        extra_info: nil,
        state: self.state,
        points: self.points,
        free_points:self.free_points,
        title_indexes:self.title_indexes,
        checker: self.checker,
        given_time: self.given_time,
        valid_start_date: self.valid_start_date,
        valid_end_date: self.valid_end_date,
        avatar_url:avatar,
        methods: [
            last_post_at: self.last_post_at,
            url: nil,
            username: self.username,
            flare: self.type_flare,
            beacon: self.type_beacon,
            sticky: self.type_sticky,
            promo: self.type_promo,
            coshoot:self.type_coshoot,
            question:self.type_question,
            errand:self.type_errand,
            content: self.content,
            place_information: self.place_information,
            tag_information: self.tag_information
        ],
        history_id: Historychange.find_by_type_id_and_type_action_and_type_name(self.id, "create", "topic").id
    }

      Pusher["favr_channel"].trigger_async("new_topic", data)

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
        state: self.state,
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
        points: self.points,
        free_points:self.free_points,
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
          topic_user.points = topic_user.points + 1
          #actionlog.create_record("topic", topic_id, "like", user.id)
          actionlog =   ActionLog.create(type_name: "topic", type_id: topic_id, action_type: "like", action_user_id: user.id)
          action_status = 1
        end
      end
    elsif choice == "dislike"
      if check_like.present?
        topic.likes = topic.likes - 1
        topic_user.points = topic_user.points - 1
        ActionLog.find_by_type_name_and_type_id_and_action_type_and_action_user_id("topic", topic_id, "like", user.id).delete
        action_status = -1
      else
        unless check_dislike.present?
          topic.dislikes = topic.dislikes + 1
          topic_user.points = topic_user.points + 1
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

    s3 = Aws::S3::Client.new
    resp = s3.delete_object({
      bucket: bucket_name,
      key: file_name,
    })

    if topic_type == Topic::IMAGE    #delete medium and small version
      names = file_name.split(".")
      sfilename = names[0] +  "_s." +  names[1]
      mfilename =  names[0] +  "_m." + names[1]
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

  def notify_carmmunicate_msg_to_nearby_users
    hiveapplication = HiveApplication.find(self.hiveapplication_id)
    user_id = []
    to_device_id = []
    time_allowance = Time.now - 10.minutes.ago
    users = User.where("app_data ->'app_id#{hiveapplication.id}' = '#{hiveapplication.api_key}'")
    p "carmic users"
    p users
    users.each do |u|
      if u.data.present? && u.id != self.user_id
        hash_array = u.data
        device_id = hash_array["device_id"] if  hash_array["device_id"].present?
        to_device_id.push(device_id)
        user_id.push(u.id)
      end

    end
    p "user to push"
    p user_id

    p "device_id"
    p to_device_id

    if Rails.env.production?
      appID = PushWoosh_Const::CM_P_APP_ID
    elsif Rails.env.staging?
      appID = PushWoosh_Const::CM_S_APP_ID
    else
      appID = PushWoosh_Const::CM_D_APP_ID
    end

    @auth = {:application  => appID ,:auth => PushWoosh_Const::API_ACCESS}

    p "Push Woosh Authentication"

    if !self.title.nil?
      if self.title.include? ":"
        title = self.title.match(":").post_match
      else
        title = self.title
      end
    else
      title = ""
    end

    avatar = Topic.get_avatar(username)

    notification_options = {
        send_date: "now",
        badge: "+1",
        sound: "default",
        content:{
            fr:title,
            en:title
        },
        data:{
            id: self.id,
            title: self.title,
            user_id: self.user_id,
            topic_type: self.topic_type,
            state: self.state,
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
            points: self.points,
            free_points:self.free_points,
            methods: {
                username: username,
                avatar: avatar,
                place_information: self.place_information,
                tag_information: self.tag_information,
                to_device_id: to_device_id
            }
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

  def notify_carmmunicate_msg_to_selected_users (users_to_push, isprivatemsg)
    to_plate_number =""
    if (isprivatemsg)  and users_to_push.length>0
      user_id = users_to_push.first.to_i
      user= User.find_by_id(user_id)
      if user.data.present?
        hash_array = user.data
        to_plate_number = hash_array["plate_number"] if  hash_array["plate_number"].present?

      end
    end


    p "users_to_push"
    p users_to_push

    to_device_id = []

    users_to_push.each do |u|
      user= User.find_by_id(u)
      if user.data.present?
        hash_array = user.data
        device_id = hash_array["device_id"] if  hash_array["device_id"].present?
        to_device_id.push(device_id)
      end
    end


    p "device_id"
    p to_device_id


    if Rails.env.production?
      appID = PushWoosh_Const::CM_P_APP_ID
    elsif Rails.env.staging?
      appID = PushWoosh_Const::CM_S_APP_ID
    else
      appID = PushWoosh_Const::CM_D_APP_ID
    end

    @auth = {:application  => appID ,:auth => PushWoosh_Const::API_ACCESS}

    p "Push Woosh Authentication"

    if !self.title.nil?
      if self.title.include? ":"
        title = self.title.match(":").post_match
      else
        title = self.title
      end
    else
      title = ""
    end

    avatar = Topic.get_avatar(username)

    notification_options = {
        send_date: "now",
        badge: "+1",
        sound: "default",
        content:{
            fr:title,
            en:title
        },
        data:{
             id: self.id,
             title: self.title,
             user_id: self.user_id,
             topic_type: self.topic_type,
             state: self.state,
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
             points: self.points,
             free_points:self.free_points,
             methods: {
                 username: username,
                 avatar: avatar,
                 place_information: self.place_information,
                 tag_information: self.tag_information,
                 is_private_message: isprivatemsg,
                 to_plate_number: to_plate_number,
                 to_device_id: to_device_id
             }
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


  def self.get_avatar(username)
    avatar_url = nil

    #GET AVATAR URL
    #check for special case that cannot match the avatar
    avatar_url = "assets/Avatars/Chat-Avatar-Puppy.png" if(username.index("Snorkie").present?)
    avatar_url = "assets/Avatars/Chat-Avatar-Koala.png" if(username.index("Bear").present?)
    avatar_url = "assets/Avatars/Chat-Avatar-Kitten.png" if(username.index("Cat").present?)
    avatar_url = "assets/Avatars/Chat-Avatar-Kitten.png" if(username.index("Jaguar").present?)
    avatar_url = "assets/Avatars/Chat-Avatar-Lion.png" if(username.index("Lion").present?)
    avatar_url = "assets/Avatars/Chat-Avatar-Admin.png" if(username.index("Raydius GameBot").present?)

    urls = ["assets/Avatars/Chat-Avatar-Chipmunk.png",
            "assets/Avatars/Chat-Avatar-Puppy.png",
            "assets/Avatars/Chat-Avatar-Panda.png",
            "assets/Avatars/Chat-Avatar-Koala.png",
            "assets/Avatars/Chat-Avatar-Husky.png",
            "assets/Avatars/Chat-Avatar-Horse.png",
            "assets/Avatars/Chat-Avatar-Llama.png",
            "assets/Avatars/Chat-Avatar-Aardvark.png",
            "assets/Avatars/Chat-Avatar-Alligator.png",
            "assets/Avatars/Chat-Avatar-Beaver.png",
            "assets/Avatars/Chat-Avatar-Bluebird.png",
            "assets/Avatars/Chat-Avatar-Butterfly.png",
            "assets/Avatars/Chat-Avatar-Eagle.png",
            "assets/Avatars/Chat-Avatar-Elephant.png",
            "assets/Avatars/Chat-Avatar-Giraffe.png",
            "assets/Avatars/Chat-Avatar-Kangaroo.png",
            "assets/Avatars/Chat-Avatar-Monkey.png",
            "assets/Avatars/Chat-Avatar-Swan.png",
            "assets/Avatars/Chat-Avatar-Whale.png",
            "assets/Avatars/Chat-Avatar-Penguin.png",
            "assets/Avatars/Chat-Avatar-Duck.png",
            "assets/Avatars/Chat-Avatar-Admin.png",]

    urls.each do |url|
      if avatar_url.nil?
        url_one = [ ]
        url_one= url.split ('.png')
        url_two = [ ]
        url_two = url_one[0].split('-')
        user_names = username.split (" ")
        last_index = user_names.length
        last_name = user_names[Integer(last_index)-1]
        last_name = last_name.gsub(/[^a-zA-Z ]/,'').gsub(/ +/,' ')

        if last_name.upcase == url_two[Integer(url_two.length)-1].upcase
          avatar_url = url
        end

      end
    end

    #if still blank put the default avatar
    if avatar_url.nil?
      avatar_url = "assets/Avatars/Chat-Avatar.png"
    end
    @avatar_url = avatar_url
  end

  def notify_roundtrip_users
    topic = self

    place_name = topic.place_information[:name]
    # place_name =   topic.rtplaces_information[:start_place][:name] if topic.topic_type == 11

    sns = Aws::SNS::Client.new
    iphone_notification = {
        aps: {
            alert: topic.title,
            sound: "default",
            badge: 0,
            extra:  {
                topic_id: topic.id,
                topic_title: topic.title,
                broadcast_user: topic.user_id,
                topic_username: topic.username,
                place_name: place_name,
                create_at: topic.created_at,
                shared: true
            }
        }
    }

    android_notification = {
        data: {
            message: topic.title,
            badge: 0,
            extra:  {
                topic_id: topic.id,
                topic_title: topic.title,
                broadcast_user: topic.user_id,
                topic_username: topic.username,
                place_name: place_name,
                create_at: topic.created_at,
                shared: true
            }
        }
    }

    sns_message = {
        default: topic.title,
        APNS_SANDBOX: iphone_notification.to_json,
        APNS: iphone_notification.to_json,
        GCM: android_notification.to_json
    }.to_json

    # sns = Aws::SNS::Client.new
    # iphone_notification = {
    #     aps: {
    #         alert: "test",
    #         sound: "default",
    #         badge: 0,
    #     }
    # }
    #
    # sns_message = {
    #     default:"test",
    #     APNS_SANDBOX: iphone_notification.to_json,
    #     APNS: iphone_notification.to_json,
    # }.to_json
    #
    # sns.publish(target_arn: arn, message: sns_message, message_structure:"json")

    hiveapplication = HiveApplication.find(topic.hiveapplication_id)

    to_endpoint_arn = []
    users_by_location = []
    radius = 1 if radius.nil?
    start_users =end_users= users= []
    if topic.start_place.present?
      s_center_point = [topic.start_place.latitude.to_f, topic.start_place.longitude.to_f]
      s_box = Geocoder::Calculations.bounding_box(s_center_point, radius, {units: :km})
      start_users = User.where(last_known_latitude: s_box[0] .. s_box[2], last_known_longitude: s_box[1] .. s_box[3])
      start_users = start_users.where("app_data ->'app_id#{hiveapplication.id}' = '#{hiveapplication.api_key}'")
    end

    if topic.end_place.present?
      e_center_point =  [topic.end_place.latitude.to_f, topic.end_place.longitude.to_f]
      e_box = Geocoder::Calculations.bounding_box(e_center_point, radius, {units: :km})
      end_users = User.where(last_known_latitude: e_box[0] .. e_box[2], last_known_longitude: e_box[1] .. e_box[3])
      end_users = end_users.where("app_data ->'app_id#{hiveapplication.id}' = '#{hiveapplication.api_key}'")
    end

    if topic.place.present?
      center_point = [topic.place.latitude.to_f, topic.place.longitude.to_f]
      s_box = Geocoder::Calculations.bounding_box(center_point, radius, {units: :km})
      users = User.where(last_known_latitude: s_box[0] .. s_box[2], last_known_longitude: s_box[1] .. s_box[3])
      users = users.where("app_data ->'app_id#{hiveapplication.id}' = '#{hiveapplication.api_key}'")
    end


    users_by_location = start_users+end_users+users
    users_by_location = users_by_location.uniq{ |user| [user[:id]]}
    time_allowance = Time.now - 1.day.ago

    users_by_location.each do |u|
      if u.check_in_time.present?
        time_difference = Time.now - u.check_in_time
        if time_difference < time_allowance
          if u.id != topic.user_id
            p "user id:::"
            p u.id
            push_tokens = UserPushToken.where(user_id: u.id, notify: true)
            push_tokens.map{|pt|
              duplicate_token = UserPushToken.where(user_id: topic.user_id, endpoint_arn: pt.endpoint_arn)
              if duplicate_token.present?
                p "delete previous push token record"
                pt.delete
              else
                if !pt.endpoint_arn.nil?
                  begin
                    sns.publish(target_arn: pt.endpoint_arn, message: sns_message, message_structure:"json")
                  rescue
                    p "EndpointDisabledException or InvalidParameter"
                    p pt.endpoint_arn

                      resp = sns.delete_endpoint({
                        endpoint_arn: pt.endpoint_arn, # required
                      })
                      UserPushToken.find_by_endpoint_arn(pt.endpoint_arn).delete
                    end
                end
              end
            }
          end
        end
      end
    end
  end


  def notify_train_fault_to_roundtrip_users(name, station1, station2, towards)

    sns = Aws::SNS::Client.new
    target_topic = 'arn:aws:sns:ap-southeast-1:378631322826:Roundtrip_S_Broadcast_Noti'

    iphone_notification = {
        aps: {
            alert: self.title,
            sound: "default",
            badge: 0,
            extra:  {
                smrtline: name,
                station1: station1,
                station2: station2,
                towards: towards,
                topic_id: self.id,
                topic_title: self.title,
                start_place: self.rtplaces_information[:start_place][:name],
                end_place:  self.rtplaces_information[:end_place][:name],
                topic_username: self.username,
                create_at: self.created_at,
                type: "train fault"
            }
        }
    }


    android_notification = {
        data: {
            message: self.title ,
            badge: 0,
            extra:  {
                smrtline: name,
                station1: station1,
                station2: station2,
                towards: towards,
                topic_id: self.id,
                topic_title: self.title,
                start_place: self.rtplaces_information[:start_place][:name],
                end_place:  self.rtplaces_information[:end_place][:name],
                topic_username: self.username,
                create_at: self.created_at,
                type: "train fault"
            }
        }
    }

    sns_message = {
        default: self.title,
        APNS_SANDBOX: iphone_notification.to_json,
        APNS: iphone_notification.to_json,
        GCM: android_notification.to_json
    }.to_json

    #AWS ns notification message to hybrid roundtrip app
    sns.publish(target_arn: target_topic, message: sns_message, message_structure:"json")

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

    datetime = datetime.sort_by! { |x,y| x[:date_time] }

    confirmed_event_date = nil
    if (self.data["confirmed_date"] != nil)
      sug = Suggesteddate.find(self.data["confirmed_date"])
      date_str = sug.suggested_datetime.to_date.strftime("%A, %d %B")
      sug.suggesttime.nil? ? event_time = "" : event_time = " at "+ sug.suggesttime.to_time.strftime("%I:%M %p")
      confirmed_event_date = date_str << "" << event_time
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
        confirmed_date: confirmed_event_date,
        valid_end_date: self.valid_end_date
    }
  end


  def broadcast_event(confirm_date)
    vote_maybe = 0
    vote_yes = 0
    vote_no = 0
    datetime = [ ]

    self.suggesteddates.each do |sd|
      votes = sd.votes
      vote_users = []

      votes.each do |v|
        if v.vote == Vote::MAYBE
          vote_maybe = vote_maybe + 1
        elsif v.vote == Vote::YES
          vote_yes = vote_yes + 1
          vote_users.push({user_name: v.user.username})
        elsif v.vote == Vote::NO
          vote_no = vote_no + 1
        end
      end

      datetime.push({id: sd.id, date_time: sd.suggested_datetime,
        time: sd.suggesttime, maybe: vote_maybe, yes: vote_yes, no: vote_no ,
        vote: sd.vote , admin_confirm: sd.admin_confirm,vote_users: vote_users
        })
      vote_maybe = 0
      vote_yes = 0
      vote_no = 0
    end

    datetime = datetime.sort_by! { |x,y| x[:date_time] }

    confirmed_event_date = nil

    p "confirmed date"
    p self.data["confirmed_date"]

    if (self.data["confirmed_date"] != "")
      if !confirm_date.nil?
        sug = Suggesteddate.find(confirm_date)
        date_str = sug.suggested_datetime.to_date.strftime("%A, %d %B")
        sug.suggesttime.nil? ? event_time = "" : event_time = " at "+ sug.suggesttime.to_time.strftime("%I:%M %p")
        confirmed_event_date = date_str << "" << event_time
      end


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
        host_id: user.id,
        creator_name: user.username,
        creator_email: user.email,
        confirm_state: self.data["confirm_state"],
        confirmed_date: confirmed_event_date,
        valid_end_date: self.valid_end_date
    }

    p "#{self.data["invitation_code"]}_channel"
    Pusher["#{self.data["invitation_code"]}_channel"].trigger_async("broadcast_event", data)
  end


  # *********** Socal ************

  def retrieve_data
    datetime = [ ]
    vote_maybe = 0
    vote_yes = 0
    vote_no = 0

    voter_emails = []
    self.suggesteddates.each do |sd|
      votes = sd.votes

      vote_users = []
      votes.each do |v|
        if v.vote == Vote::MAYBE
          vote_maybe = vote_maybe + 1
        elsif v.vote == Vote::YES
          vote_yes = vote_yes + 1
          vote_users.push({user_name: v.user.username})
          voter_emails.push( v.user.email)

        elsif v.vote == Vote::NO
          vote_no = vote_no + 1
        end
      end

      datetime.push({id: sd.id, date_time: sd.suggested_datetime,time: sd.suggesttime,
        maybe: vote_maybe, yes: vote_yes, no: vote_no , vote: sd.vote ,
        admin_confirm: sd.admin_confirm ,vote_users: vote_users})

      vote_maybe = 0
      vote_yes = 0
      vote_no = 0
    end

    usermails = voter_emails.to_set

    # datetime = datetime.sort_by! { |x,y| x[:date_time] }


    confirmed_event_date = nil
    confirm_date_id = 0
    if self.data != nil
      if (self.data["confirm_state"] != nil)
        if (self.data["confirm_state"] == "1")
          sug = Suggesteddate.find(self.data["confirmed_date"])
          confirm_date_id = sug.id
          date_str = sug.suggested_datetime.to_date.strftime("%A, %d %B")
          sug.suggesttime.nil? ? event_time = "" : event_time = " at "+ sug.suggesttime.to_time.strftime("%I:%M %p")
          confirmed_event_date = date_str << "" << event_time
        end
      end
    end


    user = User.find(self.user_id)

    vote_data = []
    self.votes.each do |vote|
        vote_data.push({date_id: vote.suggesteddate_id,  user_id: vote.user_id, user_name: vote.user.username, email: vote.user.email})
    end

    vote_data = vote_data.group_by { |d| d[:date_id] }

    data = {
        topic_id: self.id,
        host: user.username,
        host_email: user.email,
        title: self.title,
        latitude: self.data["latitude"],
        longitude: self.data["longitude"],
        address: self.data["address"],
        place_name: self.data["place_name"],
        description: self.data["content"],
        datetime: datetime,
        invitation_code: self.data["invitation_code"],
        host_id: user.id,
        creator_name: user.username,
        creator_email: user.email,
        host_token: user.authentication_token,
        confirm_state: self.data["confirm_state"],
        confirmed_date: confirmed_event_date,
        votes: vote_data,
        voter_emails:usermails.to_a,
        confirm_date_id:confirm_date_id,
        created_at: self.created_at,
        valid_end_date: self.valid_end_date
    }
  end

  # delay job to change the topic stas and actions
  def delay_change_topic_status(topic_id)
    p "delay job for topic ::: "+ topic_id.to_s
    action_topic = Topic.find(topic_id)
    if action_topic.present?
      if (action_topic.state == OPENED)
        p "state opened"
        owner = User.find(action_topic.user_id)
        p "owner old points : " + owner.points.to_s
        owner.points += action_topic.points
        owner.save!
        #owner.update_user_points
        data = {
            user_id: owner.id,
            points: owner.points
        }
        Pusher["favr_channel"].trigger  "update_user_points", data

        p "owner new points : " + owner.points.to_s
        action_topic.state = EXPIRED
        action_topic.save!

        temp_id= "favrbot3"
        p temp_id

        if action_topic.special_type== QUESTION.to_s
          title = "This Question is already expired"
        elsif action_topic.special_type== ERRAND.to_s
          title = "This Errand is already expired"
        end
        p "title "+ title
        create_user = User.find_by_username("FavrBot")
        post = Post.new
        post.create_post(title, action_topic.id, create_user.id, Post::TEXT.to_s, action_topic.latitude, action_topic.longitude,temp_id)
        p "Post has been created "

        p "send notification"
        sent_expire_notificatoin(topic_id)

      elsif (action_topic.state == TASK_EXPIRED)
        p "TASK_EXPIRED"
        owner = User.find(action_topic.user_id)
        action_record = Favraction.where(:topic_id => action_topic.id).order("id")
        if action_record.present?
          last_action_record = action_record.first
          if last_action_record.present?
            if last_action_record.status == Favraction::EXPIRED_AFTER_STARTED
              owner.points += action_topic.points
              owner.save!
              #owner.update_user_points
              data = {
                  user_id: owner.id,
                  points: owner.points
              }
              Pusher["favr_channel"].trigger  "update_user_points", data
            end
          end
        end
        action_topic.state = EXPIRED
        action_topic.save!


        temp_id= "favrbot3"
        if action_topic.special_type== QUESTION.to_s
          title = "This Question is already expired"
        elsif action_topic.special_type== ERRAND.to_s
          title = "This Errand is already expired"
        end
        p "title "+ title
        create_user = User.find_by_username("FavrBot")
        post = Post.new
        post.create_post(title, action_topic.id, create_user.id, Post::TEXT.to_s, action_topic.latitude, action_topic.longitude,temp_id)
        p "Post has been created "

        p "send notification"
        sent_expire_notificatoin(topic_id)
        #action_topic.update_event_broadcast
      elsif (action_topic.state == REJECTED)
        #elsif action_topic.state== REJECTED && favr_actions.status == Favraction::OWNER_REJECTED
        owner = User.find(action_topic.user_id)
        p "OWNER_REJECTED"
        owner = User.find(action_topic.user_id)
        p "owner old points : " + owner.points.to_s
        total_points = action_topic.points + action_topic.free_points
        half_point = (total_points/2.0).ceil
        remaining_point = total_points- half_point

        if(remaining_point >= action_topic.points)
          owner.points += action_topic.points
        else
          owner.points  += remaining_point
        end
        owner.save!
        #owner.update_user_points
        data = {
            user_id: owner.id,
            points: owner.points
        }
        Pusher["favr_channel"].trigger  "update_user_points", data

        p "owner new points : " + owner.points.to_s
        action_topic.state = EXPIRED
        action_topic.save!

        temp_id= "favrbot3"
        if action_topic.special_type== QUESTION.to_s
          title = "This Question is already expired"
        elsif action_topic.special_type== ERRAND.to_s
          title = "This Errand is already expired"
        end
        p "title "+ title
        create_user = User.find_by_username("FavrBot")
        post = Post.new
        post.create_post(title, action_topic.id, create_user.id, Post::TEXT.to_s, action_topic.latitude, action_topic.longitude,temp_id)
        p "Post has been created "
        p "send notification"
        sent_expire_notificatoin(topic_id)
        #action_topic.update_event_broadcast
        #end
      end
    end
    #end
  end

  def sent_expire_notificatoin(topic)
    p "send expire notification"
    action_topic = Topic.find(topic)
    p action_topic
    users_to_sent=[]
    users_to_sent.push ( action_topic.user_id.to_s )

    if Rails.env.production?
      appID = PushWoosh_Const::FV_P_APP_ID
    elsif Rails.env.staging?
      appID = PushWoosh_Const::FV_S_APP_ID
    else
      appID = PushWoosh_Const::FV_D_APP_ID
    end

    @auth = {:application  => appID ,:auth => PushWoosh_Const::API_ACCESS}

    if action_topic.present?

      to_device_id = []

      users= User.where("id = ? ", action_topic.user_id)
      users.each do |user|
        if user.data.present?
          hash_array = user.data
          device_id = hash_array["device_id"] if  hash_array["device_id"].present?
          to_device_id.push(device_id)
        end
      end

      notification_options = {
          send_date: "now",
          badge: "1",
          sound: "default",
          content:{
              fr:"Your favr request is expired",
              en:"Your favr request is expired"
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

  def self.nearest(latitude, longitude, radius)
    # Contains bottom-left and top-right corners
    radius = 0.3 unless radius.present?
    center_point = [latitude.to_f, longitude.to_f]
    p box = Geocoder::Calculations.bounding_box(center_point, radius, {units: :km})
    #Topic.where(data["latitude"] => box[0] .. box[2], data["longitude"] => box[1] .. box[3])
    Topic.where("data -> 'latitude' = ? and data -> 'longitude' = ?", box[0] .. box[2],box[1] .. box[3])
  end

  handle_asynchronously :topic_image_upload_job

end
