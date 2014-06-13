module UserHelper
  def current_user
    if params[:auth_token].present? && params[:user_id].present?
      p "if"
      user = User.find(params[:user_id])  #get user by user_id
      if user.present?
        if Devise.secure_compare(user.authentication_token, params[:auth_token]) == true #check the user auth_token and params are the same
          user
        end
      end
    elsif  session[:session_devuser_id].present?
      p "else"
      Devuser.find_by_id(session[:session_devuser_id])
    end
  end
end
