json.array!(@user_fav_locations) do |user_fav_location|
  json.extract! user_fav_location, :id, :user_id, :place_id, :place_type
  json.url user_fav_location_url(user_fav_location, format: :json)
end
