import { IngredientChip } from "@/features/pantry/components/IngredientChip";
import { Button } from "@/components/ui/button";
import type { PantryItem } from "@/api/types";

interface PantryIngredientsProps {
  items: PantryItem[];
  onRemove: (itemId: string) => void;
  onFindRecipes: () => void;
  isAdding?: boolean;
  isRemoving?: boolean;
  className?: string;
}

export function PantryIngredients({
  items,
  onRemove,
  onFindRecipes,
  isAdding = false,
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

      <Button
        type="button"
        onClick={onFindRecipes}
        disabled={items.length === 0 || isAdding}
        size="lg"
        className="mt-6 w-full"
      >
        {isAdding ? "Adding ingredient…" : "Find recipes →"}
      </Button>
    </section>
  );
}
