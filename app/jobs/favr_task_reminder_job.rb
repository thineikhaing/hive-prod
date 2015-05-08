class FavrTaskReminderJob < Struct.new(:action_id)

  def perform
    favr_action.delay_send_notifiction_to_doer
  end

  def display_name
    return "favraction-task-reminder-#{action_id}"
  end

  def error(job, exception)
    p 'fail to run the job'
  end


  private
  def favr_action
    @favr_action ||= Favraction.find(action_id)
  end


end