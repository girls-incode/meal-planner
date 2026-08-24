import { useQuery } from "@tanstack/react-query";
import { getRecipeMatches } from "@/api/recipes";
import { usePantry } from "./usePantry";

export function useRecipeMatches() {
  const { data: pantryItems } = usePantry();

  return useQuery({
    queryKey: ["recipe-matches", pantryItems?.length ?? 0],
    queryFn: () => getRecipeMatches(),
    enabled: (pantryItems?.length ?? 0) > 0,
  });
}
