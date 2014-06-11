class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include UserHelper, AuthenticationHelper
  before_filter :current_browser

  def current_browser
    @browser = Browser.new(ua: request.user_agent)
  end
end
