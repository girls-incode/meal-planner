import { useInfiniteQuery } from "@tanstack/react-query";
import { getRecipeMatches } from "@/api/recipes";
import { usePantry } from "./usePantry";

export function useRecipeMatches() {
  const { data: pantryItems } = usePantry();

  const ingredientIds = (pantryItems ?? []).map((item) => item.ingredient.id);
  // Stable, order-independent cache key so that distinct ingredient sets produce distinct cache entries
  // (prevents the bug where swapping one ingredient for another with the same pantry size would show stale results)
  const sortedIdsKey = [...ingredientIds].sort().join(",");

  return useInfiniteQuery({
    queryKey: ["recipe-matches", sortedIdsKey],
    queryFn: ({ pageParam }) =>
      pageParam
        ? getRecipeMatches(ingredientIds, { cursor: pageParam })
        : getRecipeMatches(ingredientIds),
    initialPageParam: null as string | null,
    getNextPageParam: (lastPage) => lastPage.nextCursor,
    enabled: ingredientIds.length > 0,
  });
}
