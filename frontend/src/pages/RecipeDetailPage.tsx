import { useParams, useNavigate } from "react-router-dom";
import { useState } from "react";
import { CheckCircle, XCircle, ImageOff, ArrowLeft } from "lucide-react";
import { MatchBadge } from "@/components/MatchBadge";
import { Loader } from "@/components/Loader";
import { Rating } from "@/components/Rating";
import { RecipeTime } from "@/components/RecipeTime";
import { useRecipe } from "@/hooks/useRecipe";

export function RecipeDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { data: recipe, isLoading, isError } = useRecipe(id);
  const [imageLoadError, setImageLoadError] = useState(false);

  if (isLoading) {
    return <Loader maxWidth="3xl" />;
  }

  if (isError || !recipe) {
    return (
      <div className="mx-auto max-w-3xl px-4 py-10 text-muted-foreground">
        We couldn&apos;t load this recipe.
      </div>
    );
  }

  const hasValidImage = recipe.imageUrl && !imageLoadError;

  return (
    <div className="mx-auto max-w-3xl px-4 py-10">
      <button
        onClick={() => navigate("/recipes")}
        className="group mb-6 inline-flex cursor-pointer items-center gap-2 bg-transparent p-0 text-sm transition-colors"
        aria-label="Back to recipes"
      >
        <ArrowLeft className="size-4 text-muted-foreground transition-all group-hover:-translate-x-1 group-hover:text-foreground" />
        <span className="text-muted-foreground transition-colors group-hover:text-foreground">Back to recipes</span>
      </button>

      {hasValidImage ? (
        <img
          src={recipe.imageUrl ?? undefined}
          alt={recipe.title}
          className="mb-6 aspect-video w-full rounded-2xl object-cover"
          onError={() => setImageLoadError(true)}
        />
      ) : (
        <div className="mb-6 flex aspect-video w-full items-center justify-center rounded-2xl bg-secondary">
          <div className="flex flex-col items-center gap-2 text-muted-foreground">
            <ImageOff className="size-8" />
            <span className="text-sm">Recipe image unavailable</span>
          </div>
        </div>
      )}

      <h1 className="text-2xl font-bold text-foreground">{recipe.title}</h1>

      <Rating value={recipe.ratings} size="md" className="mt-2 gap-2" />

      <div className="mt-4 flex flex-wrap items-center gap-4">
        <MatchBadge matchPercentage={recipe.matchPercentage} />

        <RecipeTime
          prepTimeMinutes={recipe.prepTimeMinutes}
          cookTimeMinutes={recipe.cookTimeMinutes}
          size="md"
        />
      </div>

      <div className="mt-8">
        <h2 className="mb-4 text-lg font-semibold text-foreground">Ingredients</h2>
        <ul className="flex flex-col gap-2.5">
          {[...recipe.ingredients]
            .sort((a, b) => {
              // Sort by owned status: owned ingredients first
              if (a.owned === b.owned) return 0;
              return a.owned ? -1 : 1;
            })
            .map((entry) => (
            <li key={entry.ingredient.id} className="flex items-center gap-3 rounded-lg px-3 py-2 transition-colors"
              style={{
                backgroundColor: entry.owned ? "rgba(76, 175, 80, 0.05)" : "rgba(229, 138, 69, 0.05)"
              }}>
              {entry.owned ? (
                <CheckCircle className="size-5 shrink-0 text-primary" />
              ) : (
                <XCircle className="size-5 shrink-0 text-destructive" />
              )}
              <span className={entry.owned ? "text-foreground font-medium" : "text-muted-foreground"}>
                {entry.rawText}
              </span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
