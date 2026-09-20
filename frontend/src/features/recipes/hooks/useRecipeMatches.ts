import { useInfiniteQuery } from "@tanstack/react-query";
import { getRecipeMatches } from "@/features/recipes/api/recipes";

export function useRecipeMatches(ingredientIds: string[], searchVersion = 0) {
  /*
   * Sort ingredientIds before joining them into the query key so that the
   * same set of ingredients always produces the same key regardless of the
   * order they were selected/added in (e.g. ["a", "b"] and ["b", "a"] both
   * become "a,b"), letting React Query reuse a cached result instead of
   * treating them as two different searches.
   */
  const sortedIdsKey = [...ingredientIds].sort().join(",");

  return useInfiniteQuery({
    /*
     * searchVersion is bumped by the caller on every explicit "Find recipes"
     * click (see PantryWorkspace), so including it here forces a brand-new
     * query - and a fresh fetch - even when sortedIdsKey hasn't changed from
     * the previous search.
     */
    queryKey: ["recipe-matches", sortedIdsKey, searchVersion],
    queryFn: ({ pageParam }) =>
      pageParam
        ? getRecipeMatches(ingredientIds, { cursor: pageParam })
        : getRecipeMatches(ingredientIds),
    initialPageParam: null as string | null,
    getNextPageParam: (lastPage) => lastPage.nextCursor,
    enabled: ingredientIds.length > 0,
    /*
     * Each match result is an immutable snapshot of one "Find recipes"
     * action, not data that changes over time on its own - the only way to
     * get new results is to trigger a new search, which produces a new query
     * via searchVersion above. So this query never needs to be refetched in
     * the background; staleTime: Infinity means navigating to a recipe's
     * detail page and back reuses the already-fetched result instead of
     * silently re-fetching and replacing it.
     */
    staleTime: Infinity,
  });
}
