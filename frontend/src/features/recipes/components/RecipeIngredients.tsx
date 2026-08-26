import { CheckCircle, XCircle } from "lucide-react";
import type { RecipeDetail } from "@/api/types";

interface RecipeIngredientsProps {
  ingredients: RecipeDetail["ingredients"];
  missingIngredients: RecipeDetail["missingIngredients"];
}

export function RecipeIngredients({ ingredients, missingIngredients }: RecipeIngredientsProps) {
  return (
    <div className="mt-8">
      <h2 className="mb-4 text-lg font-semibold text-foreground">Ingredients</h2>
      <ul className="flex flex-col gap-2.5">
        {ingredients.filter((entry) => entry.owned).map((entry) => (
          <li
            key={entry.ingredient.id}
            className="flex items-center gap-3 rounded-lg bg-primary/5 px-3 py-2 transition-colors"
          >
            <CheckCircle className="size-5 shrink-0 text-primary" />
            <span className="text-foreground font-medium">
              {entry.rawText}
            </span>
          </li>
        ))}
        {missingIngredients.map((ingredient) => (
          <li
            key={ingredient.id}
            className="flex items-center gap-3 rounded-lg bg-destructive/5 px-3 py-2 transition-colors"
          >
            <XCircle className="size-5 shrink-0 text-destructive" />
            <span className="text-muted-foreground">{ingredient.name}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}
