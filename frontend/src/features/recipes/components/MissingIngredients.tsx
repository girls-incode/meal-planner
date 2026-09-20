import { Badge } from "@/components/ui/badge";
import type { Ingredient } from "@/api/types";

interface MissingIngredientsProps {
  ingredients: Ingredient[];
  count: number;
}

const DISPLAY_LIMIT = 3;

export function MissingIngredients({
  ingredients,
  count,
}: MissingIngredientsProps) {
  if (!ingredients.length) return null;

  const hasMoreIngredients = ingredients.length - DISPLAY_LIMIT;

  return (
    <div className="rounded-lg bg-accent/10 p-2">
      <p className="mb-1.5 text-xs font-medium text-accent-foreground">
        Missing {count} ingredient{count === 1 ? "" : "s"}
      </p>
      <div className="flex flex-wrap gap-1">
        {ingredients.slice(0, DISPLAY_LIMIT).map((ingredient) => (
          <Badge
            key={ingredient.id}
            variant="secondary"
            className="bg-accent/30 text-accent-foreground"
          >
            {ingredient.name}
          </Badge>
        ))}
        {hasMoreIngredients > 0 && (
          <Badge
            variant="secondary"
            className="bg-accent/30 text-accent-foreground"
          >
            +{hasMoreIngredients} more
          </Badge>
        )}
      </div>
    </div>
  );
}
