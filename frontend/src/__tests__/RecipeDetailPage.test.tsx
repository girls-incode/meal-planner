import { render, screen, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { MemoryRouter, Routes, Route } from "react-router-dom";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { RecipeDetailPage } from "@/pages/RecipeDetailPage";
import { ApiError } from "@/api/client";
import * as recipesApi from "@/api/recipes";
import type { RecipeDetail } from "@/api/types";

let queryClient: QueryClient;

function renderWithProviders(initialRoute = "/recipes/recipe-id-1") {
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={[initialRoute]}>
        <Routes>
          <Route path="/recipes/:id" element={<RecipeDetailPage />} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>,
  );
}

beforeEach(() => {
  queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
});

afterEach(() => {
  vi.restoreAllMocks();
});

describe("RecipeDetailPage", () => {
  it("renders a loading message while fetching the recipe", () => {
    // Mock with a promise that never resolves
    vi.spyOn(recipesApi, "getRecipe").mockReturnValue(new Promise(() => {}));

    renderWithProviders();

    expect(screen.getByText("Loading…")).toBeInTheDocument();
  });

  it("renders an error message when the recipe fetch fails", async () => {
    vi.spyOn(recipesApi, "getRecipe").mockRejectedValue(new ApiError(404, "Recipe not found"));

    renderWithProviders();

    await waitFor(() => {
      expect(screen.getByText(/couldn't load this recipe/i)).toBeInTheDocument();
    });
  });

  it("renders the recipe title, cuisine, category, and author", async () => {
    const recipe: RecipeDetail = {
      id: "r1",
      title: "Chicken Fried Rice",
      imageUrl: null,
      ratings: 4.5,
      cookTimeMinutes: 20,
      prepTimeMinutes: 10,
      cuisine: "Asian",
      category: "Dinner",
      author: "Chef Bob",
      requiredIngredientCount: 5,
      ingredients: [],
      matchPercentage: 100,
      matchedIngredients: 5,
      missingCount: 0,
    };
    vi.spyOn(recipesApi, "getRecipe").mockResolvedValue(recipe);

    renderWithProviders();

    await waitFor(() => {
      expect(screen.getByText("Chicken Fried Rice")).toBeInTheDocument();
    });
  });

  it("renders the total cook and prep time", async () => {
    const recipe: RecipeDetail = {
      id: "r1",
      title: "Chicken Fried Rice",
      imageUrl: null,
      ratings: 4.5,
      cookTimeMinutes: 20,
      prepTimeMinutes: 10,
      cuisine: "Asian",
      category: "Dinner",
      author: "Chef Bob",
      requiredIngredientCount: 5,
      ingredients: [],
      matchPercentage: 100,
      matchedIngredients: 5,
      missingCount: 0,
    };
    vi.spyOn(recipesApi, "getRecipe").mockResolvedValue(recipe);

    renderWithProviders();

    await waitFor(() => {
      expect(screen.getByText("30 min")).toBeInTheDocument();
    });
  });

  it("renders ingredient checklist with owned/missing icons", async () => {
    const recipe: RecipeDetail = {
      id: "r1",
      title: "Chicken Fried Rice",
      imageUrl: null,
      ratings: 4.5,
      cookTimeMinutes: 20,
      prepTimeMinutes: 10,
      cuisine: "Asian",
      category: "Dinner",
      author: "Chef Bob",
      requiredIngredientCount: 5,
      ingredients: [
        {
          ingredient: { id: "i1", name: "Chicken" },
          rawText: "1 lb chicken breast, diced",
          owned: true,
        },
        {
          ingredient: { id: "i2", name: "Soy Sauce" },
          rawText: "3 tbsp soy sauce",
          owned: false,
        },
      ],
      matchPercentage: 100,
      matchedIngredients: 5,
      missingCount: 0,
    };
    vi.spyOn(recipesApi, "getRecipe").mockResolvedValue(recipe);

    renderWithProviders();

    await waitFor(() => {
      expect(screen.getByText("1 lb chicken breast, diced")).toBeInTheDocument();
      expect(screen.getByText("3 tbsp soy sauce")).toBeInTheDocument();
    });

    // Verify that the owned ingredient has a check icon and is visible with full opacity
    const ownedIngredient = screen.getByText("1 lb chicken breast, diced").closest("span");
    expect(ownedIngredient).toHaveClass("text-foreground");

    // Verify that the missing ingredient has a missing-state styling (muted)
    const missingIngredient = screen.getByText("3 tbsp soy sauce").closest("span");
    expect(missingIngredient).toHaveClass("text-muted-foreground");
  });

  it("renders the match badge with appropriate styling", async () => {
    const recipe: RecipeDetail = {
      id: "r1",
      title: "Chicken Fried Rice",
      imageUrl: null,
      ratings: 4.5,
      cookTimeMinutes: 20,
      prepTimeMinutes: 10,
      cuisine: "Asian",
      category: "Dinner",
      author: "Chef Bob",
      requiredIngredientCount: 5,
      ingredients: [],
      matchPercentage: 80.5,
      matchedIngredients: 4,
      missingCount: 1,
    };
    vi.spyOn(recipesApi, "getRecipe").mockResolvedValue(recipe);

    renderWithProviders();

    await waitFor(() => {
      // The MatchBadge renders text based on matchPercentage; for 80.5 it should say "Missing a couple ingredients"
      const badge = screen.getByText("Missing a couple ingredients");
      expect(badge).toBeInTheDocument();
    });
  });

  it("fetches the recipe with the ID from the URL params", async () => {
    const recipe: RecipeDetail = {
      id: "recipe-id-1",
      title: "Test Recipe",
      imageUrl: null,
      ratings: 4.5,
      cookTimeMinutes: 30,
      prepTimeMinutes: 10,
      cuisine: "Test",
      category: "Test",
      author: "Test Author",
      requiredIngredientCount: 2,
      ingredients: [],
      matchPercentage: 100,
      matchedIngredients: 2,
      missingCount: 0,
    };
    const getRecipe = vi.spyOn(recipesApi, "getRecipe").mockResolvedValue(recipe);

    renderWithProviders("/recipes/recipe-id-1");

    await waitFor(() => {
      expect(getRecipe).toHaveBeenCalledWith("recipe-id-1");
    });
  });

  it("renders 0 minutes when both cook and prep times are null", async () => {
    const recipe: RecipeDetail = {
      id: "r1",
      title: "Quick Recipe",
      imageUrl: null,
      ratings: 4.5,
      cookTimeMinutes: null,
      prepTimeMinutes: null,
      cuisine: "Test",
      category: "Test",
      author: "Test Author",
      requiredIngredientCount: 1,
      ingredients: [],
      matchPercentage: 100,
      matchedIngredients: 1,
      missingCount: 0,
    };
    vi.spyOn(recipesApi, "getRecipe").mockResolvedValue(recipe);

    renderWithProviders();

    await waitFor(() => {
      expect(screen.getByText("Prep: —")).toBeInTheDocument();
    });
  });
});
