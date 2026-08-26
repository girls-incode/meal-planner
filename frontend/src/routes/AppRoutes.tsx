import { Route, Routes } from "react-router-dom";
import { PantryWorkspace } from "@/features/pantry/components/PantryWorkspace";
import { PantryPage } from "@/features/pantry/pages/PantryPage";
import { RecipeDetailPage } from "@/features/recipes/pages/RecipeDetailPage";
import { RecipesPage } from "@/features/recipes/pages/RecipesPage";
import { AppLayout } from "@/layouts/AppLayout";

export function AppRoutes() {
  return (
    <Routes>
      <Route element={<AppLayout />}>
        <Route element={<PantryWorkspace />}>
          <Route index element={<PantryPage />} />
          <Route path="recipes" element={<RecipesPage />} />
          <Route path="recipes/:id" element={<RecipeDetailPage />} />
        </Route>
      </Route>
    </Routes>
  );
}
