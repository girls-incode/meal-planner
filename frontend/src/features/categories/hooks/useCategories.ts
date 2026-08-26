import { useQuery } from "@tanstack/react-query";
import { getCategories } from "@/features/categories/api/categories";

export function useCategories(limit = 20) {
  return useQuery({
    queryKey: ["categories", limit],
    queryFn: () => getCategories(limit),
  });
}
