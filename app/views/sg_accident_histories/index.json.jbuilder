json.array!(@sg_accident_histories) do |sg_accident_history|
  json.extract! sg_accident_history, :id, :type, :message, :accident_datetime, :latitude, :longitude, :summary, :notify
  json.url sg_accident_history_url(sg_accident_history, format: :json)
end
