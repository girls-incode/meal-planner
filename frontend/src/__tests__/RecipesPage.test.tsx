import { render, screen, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { afterEach, describe, expect, it, vi } from "vitest";
import { RecipesPage } from "@/pages/RecipesPage";
import * as pantryApi from "@/api/pantry";
import * as recipesApi from "@/api/recipes";
import type { PantryItem, RecipeMatch } from "@/api/types";

function renderPage() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });

  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>
        <RecipesPage />
      </MemoryRouter>
    </QueryClientProvider>,
  );
}

afterEach(() => {
  vi.restoreAllMocks();
});

describe("RecipesPage", () => {
  it("shows the empty-pantry state when there are no pantry items", async () => {
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue([]);

    renderPage();

    expect(await screen.findByText("Your kitchen is empty")).toBeInTheDocument();
  });

  it("renders matched recipes when the pantry has items", async () => {
    const pantryItems: PantryItem[] = [{ id: "p1", ingredient: { id: "i1", name: "Egg" } }];
    const recipes: RecipeMatch[] = [
      {
        id: "r1",
        title: "Golden Sweet Cornbread",
        imageUrl: null,
        ratings: 4.7,
        cookTimeMinutes: 25,
        prepTimeMinutes: 10,
        matchedIngredients: 8,
        requiredIngredientCount: 8,
        missingCount: 0,
        matchPercentage: 100,
        missingIngredients: [],
      },
    ];

    vi.spyOn(pantryApi, "getPantry").mockResolvedValue(pantryItems);
    vi.spyOn(recipesApi, "getRecipeMatches").mockResolvedValue(recipes);

    renderPage();

    expect(await screen.findByText("Golden Sweet Cornbread")).toBeInTheDocument();
  });

  it("shows an error state when the matches request fails", async () => {
    const pantryItems: PantryItem[] = [{ id: "p1", ingredient: { id: "i1", name: "Egg" } }];

    vi.spyOn(pantryApi, "getPantry").mockResolvedValue(pantryItems);
    vi.spyOn(recipesApi, "getRecipeMatches").mockRejectedValue(new Error("network error"));

    renderPage();

    await waitFor(() => {
      expect(screen.getByText("Something went wrong")).toBeInTheDocument();
    });
  });
});
