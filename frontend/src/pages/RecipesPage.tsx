import { RecipeCard } from "@/components/RecipeCard";
import { RecipeEmptyState } from "@/components/RecipeEmptyState";
import { Loader } from "@/components/Loader";
import { useRecipeMatches } from "@/hooks/useRecipeMatches";
import { usePantry } from "@/hooks/usePantry";
import { ApiError } from "@/api/client";

export function RecipesPage() {
  const {
    data: pantryItems = [],
    isLoading: isPantryLoading,
    isError: isPantryError,
  } = usePantry();
  const {
    data: matches,
    isLoading,
    isError,
    error: recipeError,
  } = useRecipeMatches();

  const recipes = matches?.data ?? [];

  if (isPantryLoading) {
    return <Loader label="Loading pantry…" />;
  }

  if (isPantryError) {
    return (
      <RecipeEmptyState
        title="Something went wrong"
        description="We couldn't load your pantry. Please try again."
      />
    );
  }

  if (pantryItems.length === 0) {
    return (
      <RecipeEmptyState
        title="Your kitchen is empty"
        description="Add a few ingredients you have and we'll find recipes you can make."
        actionLabel="Add ingredients"
      />
    );
  }

  if (isError) {
    const errorDescription =
      recipeError instanceof ApiError
        ? recipeError.message
        : "We couldn't load your recipe matches. Please try again.";

    return (
      <RecipeEmptyState
        title="Something went wrong"
        description={errorDescription}
      />
    );
  }

  if (isLoading) {
    return <Loader label="Loading recipes…" />;
  }

  if (recipes.length === 0) {
    return (
      <RecipeEmptyState
        title="Nothing close enough yet"
        description="Try adding another ingredient or allowing recipes with more missing items."
        actionLabel="Add ingredient"
      />
    );
  }

  return (
    <div className="mx-auto max-w-6xl px-4 py-10">
      <h1 className="mb-6 text-2xl font-bold text-foreground">
        Recipes you can make
      </h1>
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {recipes.map((recipe) => (
          <RecipeCard key={recipe.id} recipe={recipe} />
        ))}
      </div>
    </div>
  );
}
