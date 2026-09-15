class Ingredient < ApplicationRecord
  has_many :recipe_ingredients, dependent: :restrict_with_exception
  has_many :pantry_items, dependent: :restrict_with_exception

  before_validation :canonicalize_name
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :search, ->(query) { where("name ILIKE ?", "%#{sanitize_sql_like(query)}%") }
  scope :in_recipe_catalog, -> {
    joins(:recipe_ingredients).distinct
  }

  private

  def canonicalize_name
    self.name = name&.strip&.downcase
  end
end
