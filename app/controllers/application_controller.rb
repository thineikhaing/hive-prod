class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery

  include UserHelper, AuthenticationHelper, UtilityHelper

  before_filter :current_browser

  def current_browser
    @browser = Browser.new(ua: request.user_agent)
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
end
