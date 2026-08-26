import { useQuery } from "@tanstack/react-query";
import { getRecipe } from "@/features/recipes/api/recipes";

export function useRecipe(id: string | undefined) {
  return useQuery({
    queryKey: ["recipe", id],
    queryFn: () => {
      if (!id) throw new Error("Recipe ID is required");
      return getRecipe(id);
    },
    enabled: Boolean(id),
  });
}
