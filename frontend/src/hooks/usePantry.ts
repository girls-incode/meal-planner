import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { addPantryItem, getPantry, removePantryItem } from "@/api/pantry";
import type { PantryItem } from "@/api/types";

export const pantryQueryKey = ["pantry"] as const;

export function usePantry() {
  return useQuery({
    queryKey: pantryQueryKey,
    queryFn: getPantry,
  });
}

export function useAddPantryItem() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: addPantryItem,
    onMutate: async (ingredientId: string) => {
      // Cancel any in-flight requests to avoid race conditions
      await queryClient.cancelQueries({ queryKey: pantryQueryKey });

      // Snapshot the current state
      const previousData = queryClient.getQueryData<PantryItem[]>(pantryQueryKey);

      // Optimistically update the cache
      if (previousData) {
        queryClient.setQueryData<PantryItem[]>(
          pantryQueryKey,
          (old) => [
            ...(old ?? []),
            {
              id: `temp-${ingredientId}`, // Temporary ID, will be replaced on success
              ingredient: { id: ingredientId, name: "" }, // Minimal object, real data arrives on sync
            },
          ]
        );
      }

      return { previousData };
    },
    onError: (_, __, context) => {
      // Roll back on error
      if (context?.previousData) {
        queryClient.setQueryData(pantryQueryKey, context.previousData);
      }
    },
    onSettled: () => {
      // Reconcile with server after mutation completes (success or error)
      queryClient.invalidateQueries({ queryKey: pantryQueryKey });
      queryClient.invalidateQueries({ queryKey: ["recipe-matches"] });
    },
  });
}

export function useRemovePantryItem() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: removePantryItem,
    onMutate: async (pantryItemId: string) => {
      // Cancel any in-flight requests to avoid race conditions
      await queryClient.cancelQueries({ queryKey: pantryQueryKey });

      // Snapshot the current state
      const previousData = queryClient.getQueryData<PantryItem[]>(pantryQueryKey);

      // Optimistically update the cache
      if (previousData) {
        queryClient.setQueryData<PantryItem[]>(
          pantryQueryKey,
          (old) => (old ?? []).filter((item) => item.id !== pantryItemId)
        );
      }

      return { previousData };
    },
    onError: (_, __, context) => {
      // Roll back on error
      if (context?.previousData) {
        queryClient.setQueryData(pantryQueryKey, context.previousData);
      }
    },
    onSettled: () => {
      // Reconcile with server after mutation completes (success or error)
      queryClient.invalidateQueries({ queryKey: pantryQueryKey });
      queryClient.invalidateQueries({ queryKey: ["recipe-matches"] });
    },
  });
}
