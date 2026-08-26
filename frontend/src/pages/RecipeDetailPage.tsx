import { useParams, useNavigate } from "react-router-dom";
import { ArrowLeft } from "lucide-react";
import { MatchBadge } from "@/components/MatchBadge";
import { Loader } from "@/components/Loader";
import { Rating } from "@/components/Rating";
import { RecipeTime } from "@/components/RecipeTime";
import { RecipeImage } from "@/components/RecipeImage";
import { RecipeIngredients } from "@/components/RecipeIngredients";
import { RecipeMetadata } from "@/components/RecipeMetadata";
import { useRecipe } from "@/hooks/useRecipe";

export function RecipeDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { data: recipe, isLoading, isError } = useRecipe(id);

  if (isLoading) {
    return <Loader maxWidth="3xl" />;
  }

  if (isError || !recipe) {
    const errorMessage = isError && recipe === undefined
      ? "We couldn't load this recipe."
      : null;

    return (
      <div className="mx-auto max-w-3xl px-4 py-10 text-muted-foreground">
        {errorMessage || "We couldn't load this recipe."}
      </div>
    );
  }

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

      <div className="mb-6 aspect-video w-full overflow-hidden rounded-2xl">
        <RecipeImage src={recipe.imageUrl} alt={recipe.title} />
      </div>

      <h1 className="text-2xl font-bold text-foreground">{recipe.title}</h1>

      <RecipeMetadata
        cuisine={recipe.cuisine}
        category={recipe.category?.name ?? null}
        author={recipe.author}
        className="mt-3 flex flex-wrap gap-x-4 gap-y-2 text-sm text-muted-foreground"
      />

      <Rating value={recipe.ratings} size="md" className="mt-2 gap-2" />

      <div className="mt-4 flex flex-wrap items-center gap-4">
        <MatchBadge matchPercentage={recipe.matchPercentage} />

        <RecipeTime
          prepTimeMinutes={recipe.prepTimeMinutes}
          cookTimeMinutes={recipe.cookTimeMinutes}
          size="md"
        />
      </div>

      <RecipeIngredients
        ingredients={recipe.ingredients}
        missingIngredients={recipe.missingIngredients}
      />
    </div>
  );
}
