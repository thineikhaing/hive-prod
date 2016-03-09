class HomeController < ApplicationController
   layout :special_layout
  def index
    # render layout: nil

  end

  def sign_in
    # Check for user authentication
    user = Devuser.find_by_email(params[:dev_users][:email])

    error_notice = "WE COULDN'T FIND AN ACCOUNT WITH THAT USER ID/PASSWORD COMBINATION. PLEASE TRY AGAIN"

    if user.nil?
      user = Devuser.find_by_username(params[:dev_users][:email])
    end
    if user.present?
      unless user.valid_password?(params[:dev_users][:password])
        # Redirects back to index if password is wrong
        flash[:notice] = error_notice
        redirect_to root_path
      else
        if user.verified == true
          #store CURRENT_USER_ID in session
          session[:session_devuser_id] = user.id
          # Redirects to create application view if user has verified account.
          redirect_to developer_portal_path
          #redirect_to HIVEAPPLICATION_APPLICATION_LIST_PATH
        else
          # Redirects back to index view if user hasn't verified account.
          flash[:notice] = error_notice
          redirect_to root_path
        end
      end
    else
      # Redirects back to index view if user enters the wrong email address.
      flash[:notice] = error_notice
      redirect_to root_path
    end



  end

  def developer_portal
    # Check for CURRENT_USER
    # Shows list of hiveapplications owned
    #clear the session array
    session[:transaction_list_topics] = []
    session[:transaction_list_posts] = []
    session[:app_id] = nil
    session[:table_name] = nil

    if session[:session_devuser_id].nil?
      redirect_to root_path
    else

      cur_user = Devuser.find(session[:session_devuser_id])
      p cur_user.role


      if cur_user.present?

        if cur_user.role == 1
          @hive_applications = cur_user.hive_applications.order("id ASC")
          session[:no_of_apps] = cur_user.hive_applications.count



        end

        render layout: "special_layout"

      else
        # Returns to sign in page if CURRENT_USER doesn't exist
        redirect_to root_path
      end

    end



  end


   private

   def special_layout
     # Check if logged in, because current_user could be nil.
     # "special_layout"
     "special_layout"
   end

end
