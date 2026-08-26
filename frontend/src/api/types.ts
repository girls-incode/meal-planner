export interface Ingredient {
  id: string;
  name: string;
}

export interface NamedEntity {
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
  cuisine: string | null;
  category: NamedEntity | null;
  author: NamedEntity | null;
}

export interface RecipeDetail extends Omit<RecipeMatch, "author"> {
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

export interface CategoriesPage {
  data: NamedEntity[];
  nextCursor: string | null;
}
