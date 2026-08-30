class PantryItem < ApplicationRecord
  belongs_to :pantry
  belongs_to :ingredient
  belongs_to :user, optional: true

  validates :ingredient_id, uniqueness: { scope: :pantry_id }
end
