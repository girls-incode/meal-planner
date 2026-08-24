import { useQuery } from "@tanstack/react-query";
import { getRecipe } from "@/api/recipes";

export function useRecipe(id: string | undefined) {
  return useQuery({
    queryKey: ["recipe", id],
    queryFn: () => getRecipe(id as string),
    enabled: Boolean(id),
  });
}
