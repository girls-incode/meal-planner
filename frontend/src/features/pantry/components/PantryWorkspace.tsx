import { useState } from "react";
import { Outlet, useLocation, useNavigate } from "react-router-dom";
import { ApiErrorAlert } from "@/components/ApiErrorAlert";
import { IngredientSearch } from "@/features/pantry/components/IngredientSearch";
import { PantryIngredients } from "@/features/pantry/components/PantryIngredients";
import type { PantryWorkspaceContext } from "@/features/pantry/context";
import {
  useAddPantryItem,
  usePantry,
  useRemovePantryItem,
} from "@/features/pantry/hooks/usePantry";

export function PantryWorkspace() {
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
  const pantryIngredientIds = pantryItems.map((item) => item.ingredient.id);

  function handleFindRecipes() {
    if (!pantryItems.length) return;

    setRecipeSearch((previousSearch) => ({
      ingredientIds: pantryIngredientIds,
      // Bumped on every click so consumers can detect a new search even when
      // ingredientIds is unchanged from the previous one (e.g. re-clicking
      // "Find Recipes" with the same pantry contents).
      version: (previousSearch?.version ?? 0) + 1,
    }));
    navigate("/recipes");
  }

  const mutationError = addPantryItem.error ?? removePantryItem.error;
  const context: PantryWorkspaceContext = {
    ingredientIds: recipeSearch?.ingredientIds ?? null,
    searchVersion: recipeSearch?.version ?? 0,
    isAdding: addPantryItem.isPending,
    onFindRecipes: handleFindRecipes,
  };

  return (
    <>
      {showsIngredientSearch && (
        <div className="mx-auto max-w-2xl px-4 pt-6">
          <IngredientSearch
            onAdd={(ingredient) => addPantryItem.mutate(ingredient.id)}
            excludeIds={pantryIngredientIds}
          />
          {pathname === "/recipes" && (
            <PantryIngredients
              className="mt-4"
              items={pantryItems}
              onRemove={(itemId) => removePantryItem.mutate(itemId)}
              onFindRecipes={handleFindRecipes}
              isAdding={addPantryItem.isPending}
              isRemoving={removePantryItem.isPending}
            />
          )}
          {mutationError && (
            <ApiErrorAlert error={mutationError} className="mt-2" />
          )}
        </div>
      )}
      <Outlet context={context} />
    </>
  );
}
