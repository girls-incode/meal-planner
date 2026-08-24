import { Link } from "react-router-dom";
import { RecipeCard } from "@/components/RecipeCard";
import { EmptyState } from "@/components/EmptyState";
import { useRecipeMatches } from "@/hooks/useRecipeMatches";
import { usePantry } from "@/hooks/usePantry";

export function RecipesPage() {
  const { data: pantryItems = [] } = usePantry();
  const { data: recipes = [], isLoading, isError } = useRecipeMatches();

  if (pantryItems.length === 0) {
    return (
      <div className="mx-auto max-w-2xl px-4 py-10">
        <EmptyState
          title="Your kitchen is empty"
          description="Add a few ingredients you have and we'll find recipes you can make."
          action={
            <Link
              to="/"
              className="mt-2 inline-flex items-center justify-center rounded-full bg-primary px-6 py-2.5 text-sm font-semibold text-primary-foreground transition-colors hover:bg-primary-hover"
            >
              Add ingredients
            </Link>
          }
        />
      </div>
    );
  }

  if (isError) {
    return (
      <div className="mx-auto max-w-2xl px-4 py-10">
        <EmptyState
          title="Something went wrong"
          description="We couldn't load your recipe matches. Please try again."
        />
      </div>
    );
  }

  if (!isLoading && recipes.length === 0) {
    return (
      <div className="mx-auto max-w-2xl px-4 py-10">
        <EmptyState
          title="Nothing close enough yet"
          description="Try adding another ingredient or allowing recipes with more missing items."
          action={
            <Link
              to="/"
              className="mt-2 inline-flex items-center justify-center rounded-full bg-primary px-6 py-2.5 text-sm font-semibold text-primary-foreground transition-colors hover:bg-primary-hover"
            >
              Add ingredient
            </Link>
          }
        />
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-6xl px-4 py-10">
      <h1 className="mb-6 text-2xl font-bold text-foreground">Recipes you can make</h1>
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {recipes.map((recipe) => (
          <RecipeCard key={recipe.id} recipe={recipe} />
        ))}
      </div>
    </div>
  );
}
