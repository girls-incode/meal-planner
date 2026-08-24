import { apiClient } from "./client";
import type { RecipeDetail, RecipeMatch } from "./types";

export function getRecipeMatches(maxMissing = 5): Promise<RecipeMatch[]> {
  const params = new URLSearchParams({ max_missing: String(maxMissing) });
  return apiClient.get<RecipeMatch[]>(`/api/v1/recipes/matches?${params}`);
}

export function getRecipe(id: string): Promise<RecipeDetail> {
  return apiClient.get<RecipeDetail>(`/api/v1/recipes/${id}`);
}
