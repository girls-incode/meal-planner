import { apiClient } from "@/api/client";
import type { PantryItem, PantryItemsPage } from "@/api/types";

export async function getPantry(): Promise<PantryItem[]> {
  const items: PantryItem[] = [];
  let cursor: string | null = null;

  do {
    const params = new URLSearchParams({ limit: "100" });
    if (cursor) params.set("cursor", cursor);
    const page = await apiClient.get<PantryItemsPage>(`/api/v1/pantry-items?${params}`);
    items.push(...page.data);
    cursor = page.nextCursor;
  } while (cursor);

  return items;
}

export function addPantryItem(ingredientId: string): Promise<PantryItem> {
  return apiClient.post<PantryItem>("/api/v1/pantry-items", { ingredientId });
}

export function removePantryItem(pantryItemId: string): Promise<void> {
  return apiClient.delete<void>(`/api/v1/pantry-items/${pantryItemId}`);
}
