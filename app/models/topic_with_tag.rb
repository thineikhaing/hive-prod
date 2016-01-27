class TopicWithTag < ActiveRecord::Base
  #attr_accessible :topic_id, :tag_id

  belongs_to :topic
  belongs_to :tag

  def add_record(topic_id, tag_id)
    TopicWithTag.create(topic_id: topic_id, tag_id: tag_id)
  end

end
