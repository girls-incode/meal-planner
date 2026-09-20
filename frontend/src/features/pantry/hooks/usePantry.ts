import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { addPantryItem, getPantry, removePantryItem } from "@/features/pantry/api/pantry";

export const pantryQueryKey = ["pantry"] as const;
const PANTRY_STALE_TIME = 60_000; // 1min

export function usePantry() {
  return useQuery({
    queryKey: pantryQueryKey,
    queryFn: ({ signal }) => getPantry(signal),
    // Adding/removing items already invalidates this query via onSettled below,
    // so the cache is refetched right when the pantry actually changes. This
    // staleTime just stops *redundant* refetches in between: navigating across
    // routes (e.g. "/" <-> "/recipes") remounts usePantry() each time, and
    // without a staleTime that would refetch unchanged data on every remount.
    staleTime: PANTRY_STALE_TIME,
  });
}

export function useAddPantryItem() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: addPantryItem,
    onSettled: () => queryClient.invalidateQueries({ queryKey: pantryQueryKey }),
  });
}

export function useRemovePantryItem() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: removePantryItem,
    onSettled: () => queryClient.invalidateQueries({ queryKey: pantryQueryKey }),
  });
}
