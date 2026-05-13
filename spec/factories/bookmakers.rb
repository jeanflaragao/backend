FactoryBot.define do
  factory :bookmaker do
    association :user

    sequence(:name) { |n| "Bookmaker #{n}" }

    website { "https://example.com" }
    country { "United Kingdom" }
    status { "active" }
  end
end
