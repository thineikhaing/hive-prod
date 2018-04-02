# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :devuser, class: Devuser do
    sequence(:email)  { |n| "#{n}" }
    sequence(:password)  { |n| "#{n}" }
    sequence(:username)  { |n| "#{n}" }
  end
end
