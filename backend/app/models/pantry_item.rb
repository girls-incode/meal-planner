class PantryItem < ApplicationRecord
  belongs_to :pantry
  belongs_to :ingredient

  validates :ingredient_id, uniqueness: { scope: :pantry_id }
end
