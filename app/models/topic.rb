class Topic < ActiveRecord::Base
  belongs_to :hiveapplication
  belongs_to :user
  belongs_to :place

  has_many  :posts
  # Setup hstore
  store_accessor :data

  #enums for topic type
  enums %w(NORMAL IMAGE AUDIO VIDEO)

  attr_accessible :title, :topic_type, :topic_sub_type, :place_id, :hiveapplication_id, :user_id, :data, :created_at, :image_url, :width, :height, :value, :unit, :likes, :dislikes, :offensive, :notification_range, :special_type

  def as_json(options=nil)
    if options[:popular_post].present? and options[:latest_post].present?
      if options[:num_posts].present? and options[:num_posts].to_i>0
        @no_of_post =options[:num_posts].to_i
        super(only: [:id, :title, :topic_type, :topic_sub_type, :place_id, :hiveapplication_id, :user_id, :image_url,:width, :height, :data, :value, :unit, :likes, :dislikes, :offensive, :notification_range, :special_type, :created_at], methods: [:username, :place_information, :popular_post, :latest_post, :num_posts])
      else
        super(only: [:id, :title, :topic_type, :topic_sub_type, :place_id, :hiveapplication_id, :user_id, :image_url,:width, :height, :data, :value, :unit, :likes, :dislikes, :offensive, :notification_range, :special_type, :created_at], methods: [:username, :place_information, :popular_post, :latest_post])
      end
    elsif options[:popular_post].present? and options[:latest_post].nil?
      if options[:num_posts].present?  and options[:num_posts].to_i>0
        @no_of_post =options[:num_posts].to_i
        super(only: [:id, :title, :topic_type, :topic_sub_type, :place_id, :hiveapplication_id, :user_id, :image_url,:width, :height, :data, :value, :unit, :likes, :dislikes, :offensive, :notification_range, :special_type, :created_at], methods: [:username, :place_information, :popular_post, :num_posts])
      else
        super(only: [:id, :title, :topic_type, :topic_sub_type, :place_id, :hiveapplication_id, :user_id, :image_url,:width, :height, :data, :value, :unit, :likes, :dislikes, :offensive, :notification_range, :special_type, :created_at], methods: [:username, :place_information, :popular_post])
      end
    elsif options[:popular_post].nil? and options[:latest_post].present?
      if options[:num_posts].present?  and options[:num_posts].to_i>0
        @no_of_post =options[:num_posts].to_i
        super(only: [:id, :title, :topic_type, :topic_sub_type, :place_id, :hiveapplication_id, :user_id, :image_url,:width, :height, :data, :value, :unit, :likes, :dislikes, :offensive, :notification_range, :special_type, :created_at], methods: [:username, :place_information, :latest_post, :num_posts])
      else
        super(only: [:id, :title, :topic_type, :topic_sub_type, :place_id, :hiveapplication_id, :user_id, :image_url,:width, :height, :data, :value, :unit, :likes, :dislikes, :offensive, :notification_range, :special_type, :created_at], methods: [:username, :place_information, :latest_post])
      end
    else
      if options[:num_posts].present?  and options[:num_posts].to_i>0
        @no_of_post =options[:num_posts].to_i
        super(only: [:id, :title, :topic_type, :topic_sub_type, :place_id, :hiveapplication_id, :user_id, :image_url,:width, :height, :data, :value, :unit, :likes, :dislikes, :offensive, :notification_range, :special_type, :created_at], methods: [:username, :place_information, :num_posts])
      else
        super(only: [:id, :title, :topic_type, :topic_sub_type, :place_id, :hiveapplication_id, :user_id, :image_url,:width, :height, :data, :value, :unit, :likes, :dislikes, :offensive, :notification_range, :special_type, :created_at], methods: [:username, :place_information])
      end
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
        methods: {
            username: username,
            place_information: self.place_information
        }
    }

    Pusher["hive_channel"].trigger_async("new_topic", data)
  end

  def app_broadcast
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
        data: self.data,
        methods: {
            username: username,
            place_information: self.place_information
        }
    }
    channel_name = "hive_application_"+ self.hiveapplication_id.to_s+ "_channel"
    Pusher[channel_name].trigger_async("new_topic", data)
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

  def image_upload_delayed_job(filename)
    p "delayed job starts!"
    uploader = PhotoUploader.new
    uploader.retrieve_from_store!(filename)
    uploader.cache_stored_file!
    uploader.resize_to_fit(uploader.get_geometry[0]/5,uploader.get_geometry[1]/5)
    uploader.store!
    p "delayed job ends!"
  end

end
