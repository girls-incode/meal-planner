class Ingredient < ApplicationRecord
  has_many :recipe_ingredients, dependent: :restrict_with_exception
  has_many :recipes, through: :recipe_ingredients

  has_many :pantry_items, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # Casts to text so the query matches the gin_trgm_ops expression index —
  # a trigram index cannot serve ILIKE against citext directly. ILIKE (rather
  # than LIKE) keeps the case-insensitivity citext was providing.
  scope :search, ->(query) { where("name::text ILIKE ?", "%#{sanitize_sql_like(query)}%") }

  scope :in_recipe_catalog, -> {
    joins(:recipe_ingredients)
      .where.not("ingredients.name::text ~ '[0-9]+%'")
      .distinct
  }
end
