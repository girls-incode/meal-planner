module RecipeDetailSerializer
  def self.as_json(recipe, owned_ingredient_ids:, missing_ingredients: [])
    {
      id: recipe.id,
      title: recipe.title,
      imageUrl: recipe.image_url,
      ratings: recipe.ratings,
      cookTimeMinutes: recipe.cook_time_minutes,
      prepTimeMinutes: recipe.prep_time_minutes,
      cuisine: recipe.cuisine,
      category: CategorySerializer.as_json(recipe.category),
      author: recipe.author&.name,
      requiredIngredientCount: recipe.required_ingredient_count,
      # Grouped by raw_text: a compound line ("salt and ground black pepper
      # to taste") is parsed into multiple recipe_ingredients rows, but should
      # render as the single line the recipe actually lists, owned only if
      # every ingredient in that line is in the pantry.
      ingredients: recipe.recipe_ingredients.group_by(&:raw_text).map do |raw_text, lines|
        {
          ingredient: IngredientSerializer.as_json(lines.first.ingredient),
          quantity: lines.first.quantity,
          unit: lines.first.unit,
          preparation: lines.first.preparation,
          qualifier: lines.first.qualifier,
          rawText: raw_text,
          owned: lines.all? { |ri| owned_ingredient_ids.include?(ri.ingredient_id) }
        }
      end,
      missingIngredients: missing_ingredients.map { |ingredient| IngredientSerializer.as_json(ingredient) }
    }
  end
end
