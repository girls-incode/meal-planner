import { IngredientChip } from "@/components/IngredientChip";
import type { PantryItem } from "@/api/types";

interface PantryIngredientsProps {
  items: PantryItem[];
  onRemove: (itemId: string) => void;
  onFindRecipes: () => void;
  isRemoving?: boolean;
  className?: string;
}

export function PantryIngredients({
  items,
  onRemove,
  onFindRecipes,
  isRemoving = false,
  className,
}: PantryIngredientsProps) {
  return (
    <section className={className}>
      {items.length > 0 && (
        <div className="flex flex-col gap-3">
          <h2 className="text-sm font-medium text-muted-foreground">Your ingredients</h2>
          <div className="flex flex-wrap gap-2">
            {items.map((item) => (
              <IngredientChip
                key={item.id}
                label={item.ingredient.name}
                onRemove={() => onRemove(item.id)}
                disabled={isRemoving}
              />
            ))}
          </div>
        </div>
      )}

      <button
        type="button"
        onClick={onFindRecipes}
        disabled={items.length === 0}
        className="mt-6 inline-flex w-full cursor-pointer items-center justify-center rounded-full bg-primary px-6 py-3 text-sm font-semibold text-primary-foreground transition-colors hover:bg-primary-hover disabled:cursor-not-allowed disabled:opacity-50"
      >
        Find recipes →
      </button>
    </section>
  );
}
