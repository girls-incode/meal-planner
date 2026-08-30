import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { addPantryItem, getPantry, removePantryItem } from "@/features/pantry/api/pantry";

export const pantryQueryKey = ["pantry"] as const;
const PANTRY_STALE_TIME = 60_000;

export function usePantry() {
  return useQuery({
    queryKey: pantryQueryKey,
    queryFn: ({ signal }) => getPantry(signal),
    // Mutations invalidate this query immediately. Between mutations, avoid
    // refetching the same pantry whenever a route-level observer remounts.
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
