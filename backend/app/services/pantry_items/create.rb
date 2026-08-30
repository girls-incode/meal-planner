# typed: true
# frozen_string_literal: true

module PantryItems
  class Create
    extend T::Sig

    sig { params(pantry: Pantry, ingredient_id: String).returns(PantryItem) }
    def self.call(pantry:, ingredient_id:)
      new(pantry:, ingredient_id:).call
    end

    sig { params(pantry: Pantry, ingredient_id: String).void }
    def initialize(pantry:, ingredient_id:)
      @pantry = pantry
      @ingredient_id = ingredient_id
    end

    sig { returns(PantryItem) }
    def call
      pantry_item = @pantry.pantry_items.create!(ingredient_id: @ingredient_id)

      ActiveSupport::Notifications.instrument(
        "pantry.updated",
        pantry_id: @pantry.id, action: "added", ingredient_id: @ingredient_id
      )

      pantry_item
    end
  end
end
