class FavrActionJob < Struct.new(:topic_id)

  def perform
    action_topic.delay_change_topic_status(topic_id)
  end

  def display_name
    return "favraction-Topic-#{topic_id}"
  end

  def error(job, exception)
    p 'fail to run the job'
  end

  #def success(job)
  #  action_topic.update_event_broadcast()
  #end

  private

  def action_topic
    @action_topic ||= Topic.find(topic_id)
  end
end