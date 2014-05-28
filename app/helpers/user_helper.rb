module UserHelper
  def current_user
    Devuser.find_by_id(session[:session_devuser_id])
  end
end
