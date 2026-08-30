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
      # Grouped by raw_text so a compound line split into several ingredients
      # ("salt and ground black pepper to taste" -> salt + black pepper) still
      # renders as the single line the recipe actually lists. The line counts
      # as owned only when every one of its ingredients is in the pantry.
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
