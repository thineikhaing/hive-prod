FactoryBot.define do
  factory :hiveapplication, class: HiveApplication do
    sequence(:app_name)  { |n| "#{n}" }
    sequence(:app_type)  { |n| "#{n}" }
    sequence(:devuser_id)  { |n| "#{n}" }
    sequence(:description)  { |n| "#{n}" }
  end
end