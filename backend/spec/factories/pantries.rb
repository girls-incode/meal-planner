FactoryBot.define do
  factory :pantry do
    sequence(:session_token) { |n| "session-token-#{n}" }
  end
end
