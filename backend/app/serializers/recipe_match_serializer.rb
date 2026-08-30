module RecipeMatchSerializer
  def self.as_json(recipe, missing_ingredients: [])
    {
      id: recipe.id,
      title: recipe.title,
      imageUrl: recipe.image_url,
      ratings: recipe.ratings,
      cookTimeMinutes: recipe.cook_time_minutes,
      prepTimeMinutes: recipe.prep_time_minutes,
      cuisine: recipe.cuisine,
      category: CategorySerializer.as_json(recipe.category),
      author: AuthorSerializer.as_json(recipe.author),
      matchedIngredients: recipe.matched_ingredients.to_i,
      requiredIngredientCount: recipe.required_ingredient_count,
      missingCount: recipe.missing_count.to_i,
      matchPercentage: recipe.match_percentage.to_f,
      missingIngredients: missing_ingredients.map { |i| IngredientSerializer.as_json(i) }
    }
  end

  def self.collection_as_json(recipes, missing_by_recipe: {})
    recipes.map { |recipe| as_json(recipe, missing_ingredients: missing_by_recipe[recipe.id] || []) }
  end
end
