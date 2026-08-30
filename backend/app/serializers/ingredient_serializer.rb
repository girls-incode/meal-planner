module IngredientSerializer
  def self.as_json(ingredient)
    { id: ingredient.id, name: ingredient.name }
  end

  def self.collection_as_json(ingredients)
    ingredients.map { |ingredient| as_json(ingredient) }
  end
end
