class IngredientParseError < ApplicationRecord
  belongs_to :recipe, optional: true
  belongs_to :import_run

  validates :original_text, :parser_version, :error, presence: true
end
