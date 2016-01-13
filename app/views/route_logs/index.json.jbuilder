json.array!(@route_logs) do |route_log|
  json.extract! route_log, :id, :user_id, :start_address, :end_address, :start_latitude, :start_longitude, :end_latitude, :end_longitude, :start_time, :end_time, :transport_type
  json.url route_log_url(route_log, format: :json)
end
