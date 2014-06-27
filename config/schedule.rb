every 1.day, :at => '12:00 am' do
  runner "User.regenerate_auth_token_for_expiry_tokens"
end