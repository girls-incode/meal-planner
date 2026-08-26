import { Link } from "react-router-dom";
import { IngredientSearch } from "@/components/IngredientSearch";
import { IngredientChip } from "@/components/IngredientChip";
import { EmptyState } from "@/components/EmptyState";
import { usePantry, useAddPantryItem, useRemovePantryItem } from "@/hooks/usePantry";
import { ApiError } from "@/api/client";
import type { Ingredient } from "@/api/types";

export function PantryPage() {
  const { data: pantryItems = [], isLoading } = usePantry();
  const addPantryItem = useAddPantryItem();
  const removePantryItem = useRemovePantryItem();

  function handleAdd(ingredient: Ingredient) {
    addPantryItem.mutate(ingredient.id);
  }

  function handleRemove(itemId: string) {
    removePantryItem.mutate(itemId);
  }

  const mutationError = addPantryItem.error ?? removePantryItem.error;

  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-6 px-4 py-10">
      <div className="flex flex-col gap-1">
        <h1 className="text-2xl font-bold text-foreground">What do you have at home?</h1>
        <p className="text-sm text-muted-foreground">
          Add a few ingredients and we&apos;ll find recipes you can make right now.
        </p>
      </div>

      <IngredientSearch
        onAdd={handleAdd}
        excludeIds={pantryItems.map((item) => item.ingredient.id)}
      />

      {mutationError && (
        <p role="alert" className="text-sm text-destructive">
          {mutationError instanceof ApiError ? mutationError.message : "Something went wrong. Please try again."}
        </p>
      )}

      {!isLoading && pantryItems.length === 0 && (
        <EmptyState
          title="Your kitchen is empty"
          description="Add a few ingredients you have and we'll find recipes you can make."
        />
      )}

      {pantryItems.length > 0 && (
        <div className="flex flex-col gap-3">
          <h2 className="text-sm font-medium text-muted-foreground">Your ingredients</h2>
          <div className="flex flex-wrap gap-2">
            {pantryItems.map((item) => (
              <IngredientChip
                key={item.id}
                label={item.ingredient.name}
                onRemove={() => handleRemove(item.id)}
                disabled={removePantryItem.isPending}
              />
            ))}
          </div>
        </div>
      )}

      <Link
        to="/recipes"
        className="mt-2 inline-flex items-center justify-center rounded-full bg-primary px-6 py-3 text-sm font-semibold text-primary-foreground transition-colors hover:bg-primary-hover"
      >
        Find recipes →
      </Link>
    </div>
  );
}
