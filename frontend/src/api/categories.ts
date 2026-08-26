import { apiClient } from "./client";
import type { CategoriesPage } from "./types";

export function getCategories(limit = 20): Promise<CategoriesPage> {
  return apiClient.get<CategoriesPage>(`/api/v1/categories?limit=${limit}`);
}
