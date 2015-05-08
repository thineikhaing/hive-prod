class FavrTaskJob < Struct.new(:action_id)

  def perform
    favr_action.delay_change_favr_topic_status
  end

  def display_name
    return "favraction-task-#{action_id}"
  end

  def error(job, exception)
    p 'fail to run the job'
  end


  private

  def favr_action
    @favr_action ||= Favraction.find(action_id)
  end
end