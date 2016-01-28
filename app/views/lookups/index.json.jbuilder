json.array!(@lookups) do |lookup|
  json.extract! lookup, :id, :lookup_type, :name, :value
  json.url lookup_url(lookup, format: :json)
end
