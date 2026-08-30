class Category < ApplicationRecord
  has_many :recipes, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: true

  scope :in_recipe_catalog, -> { joins(:recipes).distinct }
end
