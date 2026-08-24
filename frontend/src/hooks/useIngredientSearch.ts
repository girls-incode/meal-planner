import { useQuery } from "@tanstack/react-query";
import { searchIngredients } from "@/api/ingredients";

export function useIngredientSearch(query: string) {
  return useQuery({
    queryKey: ["ingredient-search", query],
    queryFn: () => searchIngredients(query),
    enabled: query.trim().length > 0,
  });
}
