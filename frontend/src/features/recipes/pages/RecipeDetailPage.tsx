import { useParams, useNavigate } from "react-router-dom";
import { ArrowLeft } from "lucide-react";
import { MatchBadge } from "@/features/recipes/components/MatchBadge";
import { Loader } from "@/components/Loader";
import { Button } from "@/components/ui/button";
import { Rating } from "@/features/recipes/components/Rating";
import { RecipeTime } from "@/features/recipes/components/RecipeTime";
import { RecipeImage } from "@/features/recipes/components/RecipeImage";
import { RecipeIngredients } from "@/features/recipes/components/RecipeIngredients";
import { RecipeMetadata } from "@/features/recipes/components/RecipeMetadata";
import { useRecipe } from "@/features/recipes/hooks/useRecipe";

export function RecipeDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { data: recipe, isLoading, isError } = useRecipe(id);

  if (isLoading) {
    return <Loader maxWidth="3xl" />;
  }

  if (isError || !recipe) {
    return (
      <div className="mx-auto max-w-3xl px-4 py-10 text-muted-foreground">
        We couldn't load this recipe.
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-3xl px-4 py-10">
      <Button
        variant="ghost"
        onClick={() => navigate("/recipes")}
        className="group mb-6"
        aria-label="Back to recipes"
      >
        <ArrowLeft className="size-4 transition-transform group-hover:-translate-x-1" />
        Back to recipes
      </Button>

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
