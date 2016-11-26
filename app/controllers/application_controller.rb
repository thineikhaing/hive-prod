class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery

  include UserHelper, AuthenticationHelper, UtilityHelper

  before_action :current_browser
  before_action :set_user

  # This token check if the client device is login and has a valid token.
  # Token is generate from Application API token has encryption key.
  # Validity is configuratable
  # author : Thin 31 March 2015
  def verify_authenticity_api_token
    authenticate_or_request_with_http_token do |token, options|
      p token
      p "authenticate ::::"
    end
    authenticate_or_request_with_http_token do |token, options|
      Devuser.find_by(auth_token: token)
      p "authenticate_or_request_with_http_token"
    end
  end


  def authorize_user
    redirect_to root_url, alert: "Not authorized. Please login..." if current_user.nil?
  end

  def current_browser
    @browser = Browser.new(ua: request.user_agent)

  end

  def set_user
    p "session data user"
    if params[:auth_token].present? && params[:user_id].present?
      Topic.current = User.find(params[:user_id])  #get user by user_id
    end
  end

  def check_banned_profanity(content)
    contentArray = [ ]
    content.downcase!
    profanity_filter = YAML.load_file("config/banned_profanity.yml") # From file
    profanity_filter.each do |profanity|

      if content.include?(" ")
        contentArray = content.split(" ")
      else
        contentArray.push(content)
      end

      contentArray.each do |myContent|
        if myContent == profanity
          return true
        end
      end
    end

    return false
  end

  helper_method :set_user
end
