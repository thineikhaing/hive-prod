class RegenerateAuthTokenJob < Struct.new(:user_id)

  def perform
    p "Regenerate Authentication Token performs"
    User.regenerate_auth_token_for_expiry_tokens
  end

  def display_name
    return "regenerate_auth_token"
  end

  def error(job, exception)
    p 'fail to run the job'
  end

end
