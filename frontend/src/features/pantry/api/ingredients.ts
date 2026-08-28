import { apiClient } from "@/api/client";
import type { Ingredient, IngredientsPage } from "@/api/types";

export function searchIngredients(query: string): Promise<Ingredient[]> {
  const params = new URLSearchParams({ q: query, limit: "20" });
  return apiClient.get<IngredientsPage>(`/api/v1/ingredients?${params}`).then((page) => page.data);
}
