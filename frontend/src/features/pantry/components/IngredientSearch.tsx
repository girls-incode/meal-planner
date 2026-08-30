import { useState } from "react";
import { Search } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { useIngredientSearch } from "@/features/pantry/hooks/useIngredientSearch";
import type { Ingredient } from "@/api/types";

interface IngredientSearchProps {
  onAdd: (ingredient: Ingredient) => void;
  excludeIds?: string[];
}

export function IngredientSearch({ onAdd, excludeIds = [] }: IngredientSearchProps) {
  const [query, setQuery] = useState("");
  const { data: results = [], isFetching, isCurrentQuery } = useIngredientSearch(query);
  const isSearching = isFetching || !isCurrentQuery;
  const suggestions = isCurrentQuery
    ? results.filter((ingredient) => !excludeIds.includes(ingredient.id))
    : [];

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
          {isSearching && (
            <li className="px-3 py-2 text-sm text-muted-foreground">Searching…</li>
          )}
          {!isSearching && suggestions.length === 0 && (
            <li className="px-3 py-2 text-sm text-muted-foreground">No ingredients found</li>
          )}
          {suggestions.map((ingredient) => (
            <li key={ingredient.id}>
              <Button
                type="button"
                variant="ghost"
                onClick={() => handleSelect(ingredient)}
                className="block w-full justify-start rounded-none px-3 py-2 text-left text-sm font-normal"
              >
                {ingredient.name}
              </Button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
