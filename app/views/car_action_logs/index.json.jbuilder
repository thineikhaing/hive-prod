json.array!(@car_action_logs) do |car_action_log|
  json.extract! car_action_log, :id, :user_id, :speed, :direction, :latitude, :longitude, :activity, :heartrate
  json.url car_action_log_url(car_action_log, format: :json)
end
