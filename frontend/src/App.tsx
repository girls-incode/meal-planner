import { useState } from "react";
import { Routes, Route, useLocation, useNavigate } from "react-router-dom";
import { AppHeader } from "@/components/AppHeader";
import { IngredientSearch } from "@/components/IngredientSearch";
import { PantryIngredients } from "@/components/PantryIngredients";
import { PantryPage } from "@/pages/PantryPage";
import { RecipesPage } from "@/pages/RecipesPage";
import { RecipeDetailPage } from "@/pages/RecipeDetailPage";
import { ApiError } from "@/api/client";
import { useAddPantryItem, usePantry, useRemovePantryItem } from "@/hooks/usePantry";
import type { Ingredient } from "@/api/types";

export function App() {
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const { data: pantryItems = [] } = usePantry();
  const addPantryItem = useAddPantryItem();
  const removePantryItem = useRemovePantryItem();
  const [recipeSearch, setRecipeSearch] = useState<{
    ingredientIds: string[];
    version: number;
  } | null>(null);
  const showsIngredientSearch = pathname === "/" || pathname === "/recipes";

  function handleAdd(ingredient: Ingredient) {
    addPantryItem.mutate(ingredient.id);
  }

  function handleRemove(itemId: string) {
    removePantryItem.mutate(itemId);
  }

  function handleFindRecipes() {
    if (pantryItems.length === 0) return;

    setRecipeSearch((previousSearch) => ({
      ingredientIds: pantryItems.map((item) => item.ingredient.id),
      version: (previousSearch?.version ?? 0) + 1,
    }));
    navigate("/recipes");
  }

  const mutationError = addPantryItem.error ?? removePantryItem.error;

  return (
    <div className="min-h-screen bg-background">
      <AppHeader />

      <main>
        {showsIngredientSearch && (
          <div className="mx-auto max-w-2xl px-4 pt-6">
            <IngredientSearch
              onAdd={handleAdd}
              excludeIds={pantryItems.map((item) => item.ingredient.id)}
            />
            {pathname === "/recipes" && (
              <PantryIngredients
                className="mt-4"
                items={pantryItems}
                onRemove={handleRemove}
                onFindRecipes={handleFindRecipes}
                isRemoving={removePantryItem.isPending}
              />
            )}
            {mutationError && (
              <p role="alert" className="mt-2 text-sm text-destructive">
                {mutationError instanceof ApiError
                  ? mutationError.message
                  : "Something went wrong. Please try again."}
              </p>
            )}
          </div>
        )}

        <Routes>
          <Route path="/" element={<PantryPage onFindRecipes={handleFindRecipes} />} />
          <Route
            path="/recipes"
            element={
              <RecipesPage
                ingredientIds={recipeSearch?.ingredientIds ?? null}
                searchVersion={recipeSearch?.version ?? 0}
              />
            }
          />
          <Route path="/recipes/:id" element={<RecipeDetailPage />} />
        </Routes>
      </main>
    </div>
  );
}
