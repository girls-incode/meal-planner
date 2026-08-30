# typed: true
# frozen_string_literal: true

class PantryItemCursor < Cursor
  extend T::Sig

  purpose "pantry-items-cursor"

  # Scoped to the pantry, so a cursor cannot be carried across sessions.
  sig { params(item: PantryItem, pantry_id: String).returns(String) }
  def self.encode(item, pantry_id:)
    encode_signed({ "created_at" => item.created_at.iso8601(6), "id" => item.id }, scope: pantry_id)
  end

  sig { params(value: T.anything, pantry_id: String).returns(T::Hash[String, T.untyped]) }
  def self.decode(value, pantry_id:)
    decode_signed(value, scope: pantry_id)
  end
end
