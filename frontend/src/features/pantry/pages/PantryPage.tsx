import { LatestCategories } from "@/features/categories/components/LatestCategories";
import { PantryIngredients } from "@/features/pantry/components/PantryIngredients";
import { usePantryWorkspace } from "@/features/pantry/context";
import { ApiErrorAlert } from "@/components/ApiErrorAlert";
import { EmptyState } from "@/components/EmptyState";
import { usePantry, useRemovePantryItem } from "@/features/pantry/hooks/usePantry";

interface PantryPageProps {
  onFindRecipes?: () => void;
}

export function PantryPage({ onFindRecipes }: PantryPageProps) {
  const workspace = usePantryWorkspace();
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

      {removePantryItem.error && <ApiErrorAlert error={removePantryItem.error} />}

      {!isLoading && pantryItems.length === 0 && (
        <EmptyState
          title="Your kitchen is empty"
          description="Add a few ingredients you have and we'll find recipes you can make."
        />
      )}

      <PantryIngredients
        items={pantryItems}
        onRemove={handleRemove}
        onFindRecipes={onFindRecipes ?? workspace?.onFindRecipes ?? (() => {})}
        isAdding={workspace?.isAdding}
        isRemoving={removePantryItem.isPending}
      />

      <LatestCategories />
    </div>
  );
}
