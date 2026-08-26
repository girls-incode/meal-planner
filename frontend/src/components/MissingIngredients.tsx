import type { Ingredient } from "@/api/types";

interface MissingIngredientsProps {
  ingredients: Ingredient[];
  count: number;
}

export function MissingIngredients({ ingredients, count }: MissingIngredientsProps) {
  if (ingredients.length === 0) return null;

  return (
    <div className="rounded-lg bg-orange-50 p-2">
      <p className="mb-1.5 text-xs font-medium text-orange-900">
        Missing {count} ingredient{count === 1 ? "" : "s"}
      </p>
      <div className="flex flex-wrap gap-1">
        {ingredients.slice(0, 3).map((ingredient) => (
          <span
            key={ingredient.id}
            className="inline-block rounded-full bg-orange-200 px-2 py-0.5 text-xs text-orange-900"
          >
            {ingredient.name}
          </span>
        ))}
        {ingredients.length > 3 && (
          <span className="inline-block rounded-full bg-orange-200 px-2 py-0.5 text-xs text-orange-900">
            +{ingredients.length - 3} more
          </span>
        )}
      </div>
    </div>
  );
}
