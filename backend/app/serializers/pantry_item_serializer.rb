module PantryItemSerializer
  def self.as_json(pantry_item)
    {
      id: pantry_item.id,
      ingredient: IngredientSerializer.as_json(pantry_item.ingredient),
      quantity: pantry_item.quantity,
      unit: pantry_item.unit,
      expiresAt: pantry_item.expires_at
    }
  end

  def self.collection_as_json(pantry_items)
    pantry_items.map { |item| as_json(item) }
  end
end
