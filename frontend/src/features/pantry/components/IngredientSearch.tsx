import { useState } from "react";
import { Search } from "lucide-react";
import { Input } from "@/components/ui/input";
import { useIngredientSearch } from "@/features/pantry/hooks/useIngredientSearch";
import type { Ingredient } from "@/api/types";

interface IngredientSearchProps {
  onAdd: (ingredient: Ingredient) => void;
  excludeIds?: string[];
}

export function IngredientSearch({ onAdd, excludeIds = [] }: IngredientSearchProps) {
  const [query, setQuery] = useState("");
  const { data: results = [], isFetching } = useIngredientSearch(query);
  const suggestions = results.filter((ingredient) => !excludeIds.includes(ingredient.id));

  function handleSelect(ingredient: Ingredient) {
    onAdd(ingredient);
    setQuery("");
  }

  return (
    <div className="relative">
      <div className="relative">
        <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="Add an ingredient..."
          className="pl-9"
          aria-label="Search for an ingredient to add"
        />
      </div>
      {query.trim().length > 0 && (
        <ul className="absolute z-10 mt-1 w-full overflow-hidden rounded-lg border border-border bg-card shadow-md">
          {isFetching && (
            <li className="px-3 py-2 text-sm text-muted-foreground">Searching…</li>
          )}
          {!isFetching && suggestions.length === 0 && (
            <li className="px-3 py-2 text-sm text-muted-foreground">No ingredients found</li>
          )}
          {suggestions.map((ingredient) => (
            <li key={ingredient.id}>
              <button
                type="button"
                onClick={() => handleSelect(ingredient)}
                className="block w-full px-3 py-2 text-left text-sm hover:bg-secondary"
              >
                {ingredient.name}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
