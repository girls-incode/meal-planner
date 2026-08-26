import { apiClient } from "@/api/client";
import type { RecipeDetail, RecipeMatchesPage } from "@/api/types";

export interface RecipeMatchOptions {
  maxMissing?: number;
  limit?: number;
  cursor?: string;
}

export function getRecipeMatches(
  ingredientIds: string[],
  options: RecipeMatchOptions = {},
): Promise<RecipeMatchesPage> {
  return apiClient.post<RecipeMatchesPage>("/api/v1/recipes/matches", {
    ingredients: ingredientIds,
    max_missing: options.maxMissing,
    limit: options.limit,
    cursor: options.cursor,
  });
}

export function getRecipe(id: string): Promise<RecipeDetail> {
  return apiClient.get<RecipeDetail>(`/api/v1/recipes/${id}`);
}
