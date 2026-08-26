import { useQuery } from "@tanstack/react-query";
import { getCategories } from "@/api/categories";

export function useCategories(limit = 20) {
  return useQuery({
    queryKey: ["categories", limit],
    queryFn: () => getCategories(limit),
  });
}
