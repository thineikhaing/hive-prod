require 'value_enums'

class Tag < ActiveRecord::Base
  belongs_to :topic

  has_many :topicwithtags

  enums %w(NORMAL LOCATION)

  attr_accessible :tag_type, :keyword


  def as_json(option=nil)
    super(only: [:id, :keyword, :tag_type])
  end


  def add_record(topic_id, name, tag_type)
    topicwithtag = TopicWithTag.new
    tagsArray = [ ]
    nameArray = name.split(",")
    count = 0
    profanity = false

    nameArray.each do |na|
      na.downcase!
      checkProfanity = na.split(" ")
      checkProfanity.map { |cp| profanity = true if cp == "cunt" or cp == "shit" or cp == "cocksucker" or cp == "piss" or cp == "tits" or cp == "fuck" or cp == "motherfucker" or cp == "suck" or cp == "cheebye" }

      unless profanity == true
        tag = Tag.find_by_keyword_and_tag_type(na, tag_type)

        if tag.present?
          topicwithtag.add_record(topic_id, tag.id)
        else
          count += 1
          new_tag = Tag.create(keyword: na[0 .. 24], tag_type: tag_type)
          topicwithtag.add_record(topic_id, new_tag.id)
          tagsArray.push({ keyword: new_tag})
        end
      end
      profanity = false
    end

    #Pusher["hive_channel"].trigger_async("new_tag", { tags: tagsArray }) if count > 0
  end

  def remove_records(tag_id)
    topicwithtag = TopicWithTag.where(tag_id: tag_id)

    topicwithtag.each do |twt|
      twt.delete
    end

  end

  # Search the database for related tags

  def self.search_data(search)
    if search
      #find(:all, :conditions => ['lower(tag) LIKE ?', "%#{search.downcase}%"])
      where("lower(keyword) like ?", "%#{search.downcase}%")
    else
      find(:all)
    end
  end

end
