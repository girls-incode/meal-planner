FactoryBot.define do
  factory :recipe_ingredient do
    recipe
    ingredient
    raw_text { "1 cup #{ingredient&.name || 'something'}" }
  end
end
