import { RecipeCard } from "@/features/recipes/components/RecipeCard";
import { RecipeEmptyState } from "@/features/recipes/components/RecipeEmptyState";
import { Loader } from "@/components/Loader";
import { Button } from "@/components/ui/button";
import { usePantryWorkspace } from "@/features/pantry/context";
import { usePantry } from "@/features/pantry/hooks/usePantry";
import { useRecipeMatches } from "@/features/recipes/hooks/useRecipeMatches";
import { useScrollPagination } from "@/features/recipes/hooks/useScrollPagination";
import { ApiError } from "@/api/client";

interface RecipesPageProps {
  ingredientIds?: string[] | null;
  searchVersion?: number;
}

export function RecipesPage({
  ingredientIds,
  searchVersion,
}: RecipesPageProps) {
  const workspace = usePantryWorkspace();
  const selectedIngredientIds =
    ingredientIds ?? workspace?.ingredientIds ?? null;
  const selectedSearchVersion = searchVersion ?? workspace?.searchVersion ?? 0;
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
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    isFetchNextPageError,
  } = useRecipeMatches(selectedIngredientIds ?? [], selectedSearchVersion);

  const recipes = matches?.pages.flatMap((page) => page.data) ?? [];
  const loadMoreRef = useScrollPagination({
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    isFetchNextPageError,
  });

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
      />
    );
  }

  if (selectedIngredientIds === null) {
    return (
      <RecipeEmptyState
        title="Ready to find recipes"
        description="Choose ingredients and select Find recipes to see your matches."
      />
    );
  }

  if (isError && recipes.length === 0) {
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
      {hasNextPage && (
        <div ref={loadMoreRef} className="min-h-px">
          {isFetchingNextPage && <Loader label="Loading more recipes…" />}
          {isFetchNextPageError && (
            <Button
              type="button"
              variant="link"
              onClick={() => fetchNextPage()}
              className="mx-auto block py-6"
            >
              Try loading more recipes
            </Button>
          )}
        </div>
      )}
    </div>
  );
}
