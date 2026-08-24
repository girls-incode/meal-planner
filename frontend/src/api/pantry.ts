import { apiClient } from "./client";
import type { PantryItem } from "./types";

export function getPantry(): Promise<PantryItem[]> {
  return apiClient.get<PantryItem[]>("/api/v1/pantry");
}

export function addPantryItem(ingredientId: string): Promise<PantryItem> {
  return apiClient.post<PantryItem>("/api/v1/pantry_items", { ingredient_id: ingredientId });
}

export function removePantryItem(pantryItemId: string): Promise<void> {
  return apiClient.delete<void>(`/api/v1/pantry_items/${pantryItemId}`);
}
