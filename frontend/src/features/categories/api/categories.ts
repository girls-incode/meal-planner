import { apiClient } from "@/api/client";
import type { NamedEntity } from "@/api/types";

export interface CategoriesPage {
  data: NamedEntity[];
  nextCursor: string | null;
}

export function getCategories(limit = 20): Promise<CategoriesPage> {
  return apiClient.get<CategoriesPage>(`/api/v1/categories?limit=${limit}`);
}
