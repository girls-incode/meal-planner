import { PantryIngredients } from "@/components/PantryIngredients";
import { LatestCategories } from "@/components/LatestCategories";
import { EmptyState } from "@/components/EmptyState";
import { usePantry, useRemovePantryItem } from "@/hooks/usePantry";
import { ApiError } from "@/api/client";

interface PantryPageProps {
  onFindRecipes: () => void;
}

export function PantryPage({ onFindRecipes }: PantryPageProps) {
  const { data: pantryItems = [], isLoading } = usePantry();
  const removePantryItem = useRemovePantryItem();

  function handleRemove(itemId: string) {
    removePantryItem.mutate(itemId);
  }

  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-6 px-4 py-10">
      <div className="flex flex-col gap-1">
        <h1 className="text-2xl font-bold text-foreground">What do you have at home?</h1>
        <p className="text-sm text-muted-foreground">
          Add a few ingredients and we&apos;ll find recipes you can make right now.
        </p>
      </div>

      {removePantryItem.error && (
        <p role="alert" className="text-sm text-destructive">
          {removePantryItem.error instanceof ApiError
            ? removePantryItem.error.message
            : "Something went wrong. Please try again."}
        </p>
      )}

      {!isLoading && pantryItems.length === 0 && (
        <EmptyState
          title="Your kitchen is empty"
          description="Add a few ingredients you have and we'll find recipes you can make."
        />
      )}

      <PantryIngredients
        items={pantryItems}
        onRemove={handleRemove}
        onFindRecipes={onFindRecipes}
        isRemoving={removePantryItem.isPending}
      />

      <LatestCategories />
    </div>
  );
}
