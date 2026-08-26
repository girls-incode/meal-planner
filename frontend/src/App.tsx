import { Routes, Route, Link } from "react-router-dom";
import { PantryPage } from "@/pages/PantryPage";
import { RecipesPage } from "@/pages/RecipesPage";
import { RecipeDetailPage } from "@/pages/RecipeDetailPage";

export function App() {
  return (
    <div className="min-h-screen bg-background">
      <header className="border-b border-border">
        <nav className="mx-auto flex max-w-6xl items-center gap-6 px-4 py-4">
          <Link to="/" className="flex items-center gap-2 text-lg font-bold text-foreground">
            <img src="/favicon.png" alt="Meal Planner" className="w-6 h-6 rounded" />
            Meal Planner
          </Link>
          <Link to="/" className="text-sm text-muted-foreground hover:text-foreground">
            Pantry
          </Link>
          <Link to="/recipes" className="text-sm text-muted-foreground hover:text-foreground">
            Recipes
          </Link>
        </nav>
      </header>

      <main>
        <Routes>
          <Route path="/" element={<PantryPage />} />
          <Route path="/recipes" element={<RecipesPage />} />
          <Route path="/recipes/:id" element={<RecipeDetailPage />} />
        </Routes>
      </main>
    </div>
  );
}
