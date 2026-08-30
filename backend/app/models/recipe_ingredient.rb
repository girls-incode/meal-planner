class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :ingredient

  validates :raw_text, presence: true
  validates :ingredient_id, uniqueness: { scope: :recipe_id }
end
