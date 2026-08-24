import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { addPantryItem, getPantry, removePantryItem } from "@/api/pantry";

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
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: pantryQueryKey });
      queryClient.invalidateQueries({ queryKey: ["recipe-matches"] });
    },
  });
}

export function useRemovePantryItem() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: removePantryItem,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: pantryQueryKey });
      queryClient.invalidateQueries({ queryKey: ["recipe-matches"] });
    },
  });
}
