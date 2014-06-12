module Authenticable
  extend ActiveSupport::Concern

  def ensure_authentication_token
    self.authentication_token ||= generate_authentication_token
  end

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end
end
