require 'value_enums'
class Topic < ActiveRecord::Base
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


  # hstore_accessor :options,
  #                 color: :string,
  #     weight: :integer,
  #     price: :float,
  #     built_at: :datetime,
  #     build_date: :date,
  #     tags: :array, # deprecated
  #     ratings: :hash # deprecated
  # miles: :decimal
  #
  #enums for topic type

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
                   :special_type,:start_place_id, :end_place_id, :created_at], methods: [:username,:avatar_url, :place_information, :tag_information, :post_information, :rtplaces_information, :content, :active_user])
    else
      super(only: [:id,:state, :title, :points, :free_points, :topic_type, :topic_sub_type, :place_id, :hiveapplication_id,
                   :user_id, :image_url,:width, :height, :data, :value, :unit, :likes, :dislikes, :offensive, :notification_range,
                   :special_type,:start_place_id, :end_place_id, :created_at], methods: [:username, :avatar_url, :place_information, :tag_information,:post_information,:rtplaces_information, :content,:active_user])
    end
  end


  def username
    User.find_by_id(self.user_id).username
  end

  def avatar_url
    User.find_by_id(self.user_id).avatar_url
    # if avatar.nil?
    #   username = User.find_by_id(self.user_id).username
    #
    #   if username  == "FavrBot"
    #     avatar = "assets/Avatars/Chat-Avatar-Admin.png"
    #   else
    #   avatar = Topic.get_avatar(username)
    #   end
    # end

    # return avatar
  end


  def local_avatar
    avatar = User.find_by_id(self.user_id).avatar_url
    if avatar.nil?
      username = User.find_by_id(self.user_id).username
      if username  == "FavrBot"
        avatar = "assets/Avatars/Chat-Avatar-Admin.png"
        else
        avatar = Topic.get_avatar(username)
      end

    else
      avatar = nil
    end
    return avatar
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

    places = {}
    if self.start_place_id.present? and self.start_place_id > 0
      place = Place.find(self.start_place_id)
      start_place = { id: place.id, name: place.name, latitude: place.latitude, longitude: place.longitude, address: place.address, category: place.category, source: place.source, source_id: place.source_id, user_id: place.user_id, country: place.country, postal_code: place.postal_code, chain_name: place.chain_name, contact_number: place.contact_number, img_url: place.img_url,locality: place.locality, region: place.region, neighbourhood: place.neighbourhood, data: place.data }
    else
      { id: nil, name: nil, latitude: nil, longitude: nil, address: nil , custom_pin_url: nil, source: nil, user_id: nil, popular: nil }
    end

    if self.end_place_id.present? and self.end_place_id > 0
      place = Place.find(self.end_place_id)
      end_place = { id: place.id, name: place.name, latitude: place.latitude, longitude: place.longitude, address: place.address, category: place.category, source: place.source, source_id: place.source_id, user_id: place.user_id, country: place.country, postal_code: place.postal_code, chain_name: place.chain_name, contact_number: place.contact_number, img_url: place.img_url,locality: place.locality, region: place.region, neighbourhood: place.neighbourhood, data: place.data }
    else
      { id: nil, name: nil, latitude: nil, longitude: nil, address: nil , custom_pin_url: nil, source: nil, user_id: nil, popular: nil }
    end


    { start_place: start_place, end_place: end_place}


  end

  def active_user
    place = Place.find(self.place_id)
    posts = self.posts
    users = User.nearest(place.latitude, place.longitude, 1)

    usersArray = []
    active_users = []
    post_users = []

    posts.each do |post|
      post_users.push(post.user_id)
    end

    post_users = post_users & post_users

    time_allowance = Time.now - 2.weeks.ago
    users.each do |u|
      usersArray.push(u)
      active_users.push(u.id)
      # if u.check_in_time.present?
      #   time_difference = Time.now - u.check_in_time
      #   unless time_difference.to_i > time_allowance.to_i
      #     usersArray.push(u)
      #     active_users.push(u.id)
      #   end
      # end
    end
    # p "post user and active users"
    # p post_users
    # p active_users

    active_post_user = post_users

    return active_post_user.count
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

    p "trigger new topic pusher"
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

      mealbox_key = ""
      if Rails.env.development?
        mealbox_key = Mealbox_key::Development_Key
      elsif Rails.env.staging?
        mealbox_key = Mealbox_key::Staging_Key
      else
        mealbox_key = Mealbox_key::Production_Key
      end

      hiveapplication.api_key

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

        if last_name == url_two[Integer(url_two.length)-1]
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

    if users_to_push.present?
        notify_carmmunicate_msg_to_selected_users(users_to_push, false)

    end
  end


  def notify_train_fault_to_roundtrip_users(name, station1, station2, towards)

    p "start added active users"

    @users_to_push = []
    @to_device_id = []

    @users = User.all

    time_allowance = Time.now - 10.minutes.ago
    @users.each do |u|
      if u.check_in_time.present?
        time_difference = Time.now - u.check_in_time
        unless time_difference.to_i > time_allowance.to_i
          @users_to_push.push(u)
        end
      end
    end

    @users_to_push.each do |u|
      user= User.find_by_id(u)
      if user.data.present?
        hash_array = user.data
        device_id = hash_array["device_id"] if  hash_array["device_id"].present?
        @to_device_id.push(device_id)
      end
    end

    p "notification options"

    p "device id::::"
    p @to_device_id

    p "title:::"
    p self.title

    notification_options = {
        send_date: "now",
        badge: "1",
        sound: "default",
        content:{
            fr:self.title,
            en:self.title
        },
        data:{
            trainfault_datetime: Time.now,
            smrtline: name,
            station1: station1,
            station2: station2,
            towards: towards,
            type: "train fault"
        },
        devices: @to_device_id
    }

    p "after noti options"

    appID = PushWoosh_Const::RT_D_APP_ID
    @auth = {:application  => appID ,:auth => PushWoosh_Const::API_ACCESS}

    if @to_device_id.count > 0
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

    p "end pushwoosh"

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

      if ! confirm_date.nil?
        confirmed_event_date = Suggesteddate.find(confirm_date).suggested_datetime
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
    p "confirm date :::"
    p self.data["confirmed_date"]
    if (self.data["confirmed_date"] != nil)
      if (self.data["confirmed_date"] == "0")
        p "confirm date is 0, do nothing"
      else
        p "confirm date is not 0"
        p self.data["confirmed_date"]
        p self.data["confirmed_date"]
      confirmed_event_date = Suggesteddate.find(self.data["confirmed_date"]).suggested_datetime
      end
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
        confirmed_date: Time.now
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
