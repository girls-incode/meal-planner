import { useQuery } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { searchIngredients } from "@/api/ingredients";

export function useIngredientSearch(query: string) {
  const [debouncedQuery, setDebouncedQuery] = useState("");

  // Debounce the query: only update the debounced value after 300ms of no changes
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedQuery(query);
    }, 300);

    return () => clearTimeout(timer);
  }, [query]);

  return useQuery({
    queryKey: ["ingredient-search", debouncedQuery],
    queryFn: () => searchIngredients(debouncedQuery),
    enabled: debouncedQuery.trim().length > 0,
  });
}
