class Recipe < ApplicationRecord
  belongs_to :author, optional: true
  belongs_to :category, optional: true
  has_many :recipe_ingredients, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients

  validates :title, presence: true

  validates :required_ingredient_count, numericality: { greater_than_or_equal_to: 0, only_integer: true }
end
