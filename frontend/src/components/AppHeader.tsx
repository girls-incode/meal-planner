import { Link } from "react-router-dom";

export function AppHeader() {
  return (
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
  );
}
