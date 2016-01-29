json.array!(@privacy_policies) do |privacy_policy|
  json.extract! privacy_policy, :id, :title, :content
  json.url privacy_policy_url(privacy_policy, format: :json)
end
