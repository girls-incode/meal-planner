import { apiClient } from "./client";
import type { RecipeDetail, RecipeMatchesPage } from "./types";

export interface RecipeMatchOptions {
  maxMissing?: number;
  limit?: number;
  cursor?: string;
}

export function getRecipeMatches(
  ingredientIds: string[],
  options: RecipeMatchOptions = {},
): Promise<RecipeMatchesPage> {
  const body: Record<string, unknown> = { ingredients: ingredientIds };
  if (options.maxMissing !== undefined) body.max_missing = options.maxMissing;
  if (options.limit !== undefined) body.limit = options.limit;
  if (options.cursor !== undefined) body.cursor = options.cursor;

  return apiClient.post<RecipeMatchesPage>("/api/v1/recipes/matches", body);
}

export function getRecipe(id: string): Promise<RecipeDetail> {
  return apiClient.get<RecipeDetail>(`/api/v1/recipes/${id}`);
}
