class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :ingredient

  validates :raw_text, presence: true
  # a given ingredient_id can only appear once per recipe_id so a recipe can't list the same ingredient twice
  validates :ingredient_id, uniqueness: { scope: :recipe_id }
end
