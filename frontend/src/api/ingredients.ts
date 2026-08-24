import { apiClient } from "./client";
import type { Ingredient } from "./types";

export function searchIngredients(query: string): Promise<Ingredient[]> {
  const params = new URLSearchParams({ q: query });
  return apiClient.get<Ingredient[]>(`/api/v1/ingredients?${params}`);
}
