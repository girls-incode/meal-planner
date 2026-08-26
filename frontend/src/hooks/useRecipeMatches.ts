import { useInfiniteQuery } from "@tanstack/react-query";
import { getRecipeMatches } from "@/api/recipes";

export function useRecipeMatches(ingredientIds: string[], searchVersion = 0) {
  // Stable, order-independent ingredient key, plus a version for an explicit re-search.
  const sortedIdsKey = [...ingredientIds].sort().join(",");

  return useInfiniteQuery({
    queryKey: ["recipe-matches", sortedIdsKey, searchVersion],
    queryFn: ({ pageParam }) =>
      pageParam
        ? getRecipeMatches(ingredientIds, { cursor: pageParam })
        : getRecipeMatches(ingredientIds),
    initialPageParam: null as string | null,
    getNextPageParam: (lastPage) => lastPage.nextCursor,
    enabled: ingredientIds.length > 0,
  });
}
