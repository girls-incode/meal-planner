FactoryBot.define do
  factory :recipe do
    sequence(:title) { |n| "Recipe #{n}" }
    prep_time_minutes { 10 }
    cook_time_minutes { 20 }
    ratings { 4.5 }
    cuisine { "American" }
    association :category
    association :author
    image_url { "https://example.com/image.jpg" }
    required_ingredient_count { 0 }
  end
end
