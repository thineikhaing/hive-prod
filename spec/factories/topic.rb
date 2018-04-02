# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :topic, class: Topic do
    sequence(:title)  { |n| "#{n}" }
    sequence(:data)  { |n| "#{n}" }
    sequence(:user_id)  { |n| "#{n}" }
    sequence(:hiveapplication_id)  { |n| "#{n}" }
  end
end
