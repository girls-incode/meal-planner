# typed: true
# frozen_string_literal: true

class IngredientCursor < Cursor
  extend T::Sig

  purpose "ingredients-cursor"

  # Scoped to the search query: a cursor replayed under a different `q` would
  # silently skip or repeat rows, so it is rejected instead.
  sig { params(ingredient: Ingredient, query: String).returns(String) }
  def self.encode(ingredient, query:)
    encode_signed({ "name" => ingredient.name, "id" => ingredient.id }, scope: query)
  end

  sig { params(value: T.anything, query: String).returns(T::Hash[String, T.untyped]) }
  def self.decode(value, query:)
    decode_signed(value, scope: query)
  end
end
