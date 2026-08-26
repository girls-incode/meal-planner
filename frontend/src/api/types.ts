export interface Ingredient {
  id: string;
  name: string;
}

export interface PantryItem {
  id: string;
  ingredient: Ingredient;
}

export interface RecipeMatch {
  id: string;
  title: string;
  imageUrl: string | null;
  ratings: number | null;
  cookTimeMinutes: number | null;
  prepTimeMinutes: number | null;
  matchedIngredients: number;
  requiredIngredientCount: number;
  missingCount: number;
  matchPercentage: number;
  missingIngredients: Ingredient[];
}

export interface RecipeDetail extends RecipeMatch {
  cuisine: string | null;
  category: string | null;
  author: string | null;
  ingredients: Array<{
    ingredient: Ingredient;
    rawText: string;
    owned: boolean;
  }>;
}

export interface RecipeMatchesPage {
  data: RecipeMatch[];
  nextCursor: string | null;
}
