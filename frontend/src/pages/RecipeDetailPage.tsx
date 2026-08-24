import { useParams } from "react-router-dom";
import { Check, X } from "lucide-react";
import { MatchBadge } from "@/components/MatchBadge";
import { useRecipe } from "@/hooks/useRecipe";

export function RecipeDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { data: recipe, isLoading, isError } = useRecipe(id);

  if (isLoading) {
    return <div className="mx-auto max-w-3xl px-4 py-10 text-muted-foreground">Loading…</div>;
  }

  if (isError || !recipe) {
    return (
      <div className="mx-auto max-w-3xl px-4 py-10 text-muted-foreground">
        We couldn&apos;t load this recipe.
      </div>
    );
  }

  const totalTime = (recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0);

  return (
    <div className="mx-auto max-w-3xl px-4 py-10">
      {recipe.imageUrl && (
        <img
          src={recipe.imageUrl}
          alt={recipe.title}
          className="mb-6 aspect-video w-full rounded-2xl object-cover"
        />
      )}

      <h1 className="text-2xl font-bold text-foreground">{recipe.title}</h1>

      <div className="mt-3 flex flex-wrap items-center gap-3">
        <MatchBadge matchPercentage={recipe.matchPercentage} />
        <span className="text-sm text-muted-foreground">
          {totalTime > 0 ? `${totalTime} min` : "—"}
        </span>
      </div>

      <div className="mt-8">
        <h2 className="mb-3 text-lg font-semibold text-foreground">Ingredients</h2>
        <ul className="flex flex-col gap-2">
          {recipe.ingredients.map((entry) => (
            <li key={entry.ingredient.id} className="flex items-center gap-2 text-sm">
              {entry.owned ? (
                <Check className="size-4 shrink-0 text-success" />
              ) : (
                <X className="size-4 shrink-0 text-muted-foreground" />
              )}
              <span className={entry.owned ? "text-foreground" : "text-muted-foreground"}>
                {entry.rawText}
              </span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
