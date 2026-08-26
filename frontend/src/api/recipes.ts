import { apiClient } from "./client";
import type { RecipeDetail, RecipeMatch } from "./types";

export interface RecipeMatchOptions {
  maxMissing?: number;
  limit?: number;
  page?: number;
}

export function getRecipeMatches(
  ingredientIds: string[],
  options: RecipeMatchOptions = {},
): Promise<RecipeMatch[]> {
  const body: Record<string, unknown> = { ingredients: ingredientIds };
  if (options.maxMissing !== undefined) body.max_missing = options.maxMissing;
  if (options.limit !== undefined) body.limit = options.limit;
  if (options.page !== undefined) body.page = options.page;

  return apiClient.post<RecipeMatch[]>("/api/v1/recipes/matches", body);
}

export function getRecipe(id: string): Promise<RecipeDetail> {
  return apiClient.get<RecipeDetail>(`/api/v1/recipes/${id}`);
}
