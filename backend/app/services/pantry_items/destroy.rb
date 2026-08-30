# typed: true
# frozen_string_literal: true

module PantryItems
  class Destroy
    extend T::Sig

    sig { params(pantry: Pantry, pantry_item_id: String).returns(PantryItem) }
    def self.call(pantry:, pantry_item_id:)
      new(pantry:, pantry_item_id:).call
    end

    sig { params(pantry: Pantry, pantry_item_id: String).void }
    def initialize(pantry:, pantry_item_id:)
      @pantry = pantry
      @pantry_item_id = pantry_item_id
    end

    sig { returns(PantryItem) }
    def call
      pantry_item = @pantry.pantry_items.find(@pantry_item_id)
      ingredient_id = pantry_item.ingredient_id
      pantry_item.destroy!

      ActiveSupport::Notifications.instrument(
        "pantry.updated",
        pantry_id: @pantry.id, action: "removed", ingredient_id: ingredient_id
      )

      pantry_item
    end
  end
end
