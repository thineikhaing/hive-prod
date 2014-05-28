class DevUserActivationJob < Struct.new(:user_id)

  def perform
    p "Inactivate Devuser account delay job performs"
    # del inactivate account from Devuser table
    dev_user.delete
    p "Devuser account has been deleted"
  end

  def display_name
    return "dev-user-activation-#{user_id}"
  end

  def error(job, exception)
    p 'fail to run the job'
  end


  private
  def dev_user
    @dev_user ||= Devuser.find(user_id)
  end


end
