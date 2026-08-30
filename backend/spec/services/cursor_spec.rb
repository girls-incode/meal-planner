# frozen_string_literal: true

require "rails_helper"

# Covers the signing/version/scope layer shared by every cursor. Individual
# cursor classes only add a payload builder on top of this, so their behaviour
# is exercised through the request specs rather than duplicated here.
RSpec.describe Cursor do
  let(:ingredient) { create(:ingredient, name: "chicken") }

  it "round-trips a payload for the same scope" do
    cursor = IngredientCursor.encode(ingredient, query: "chi")

    expect(IngredientCursor.decode(cursor, query: "chi")).to include(
      "name" => "chicken", "id" => ingredient.id
    )
  end

  it "rejects a cursor that was not produced by the verifier" do
    expect { IngredientCursor.decode("not-a-cursor", query: "chi") }
      .to raise_error(Cursor::InvalidCursor, "cursor is invalid")
  end

  it "rejects a tampered cursor" do
    cursor = IngredientCursor.encode(ingredient, query: "chi")

    expect { IngredientCursor.decode("#{cursor}x", query: "chi") }
      .to raise_error(Cursor::InvalidCursor)
  end

  it "rejects a cursor replayed under a different scope" do
    cursor = IngredientCursor.encode(ingredient, query: "chi")

    expect { IngredientCursor.decode(cursor, query: "beef") }
      .to raise_error(Cursor::InvalidCursor)
  end

  # The purpose string derives a distinct signing key per cursor class, which is
  # what lets decode skip field-level validation of its own payload.
  it "rejects a cursor minted by a different cursor class" do
    cursor = CategoryCursor.encode(create(:category))

    expect { IngredientCursor.decode(cursor, query: "chi") }
      .to raise_error(Cursor::InvalidCursor)
  end

  it "requires a subclass to declare a purpose" do
    anonymous = Class.new(described_class)

    expect { anonymous.encode({ "id" => "1" }) }
      .to raise_error(NotImplementedError, /must declare a purpose/)
  end
end
