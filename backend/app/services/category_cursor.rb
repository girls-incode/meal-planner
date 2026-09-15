# typed: true
# frozen_string_literal: true

class CategoryCursor < Cursor
  extend T::Sig

  purpose "categories-cursor"

  sig { params(category: Category).returns(String) }
  def self.encode(category)
    encode_signed({ "name" => category.name, "id" => category.id })
  end

  sig { params(value: T.anything).returns(T::Hash[String, T.untyped]) }
  def self.decode(value)
    decode_signed(value)
  end
end
