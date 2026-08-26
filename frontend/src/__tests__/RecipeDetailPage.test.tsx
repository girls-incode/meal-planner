import { screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { RecipeDetailPage } from "@/pages/RecipeDetailPage";
import { ApiError } from "@/api/client";
import * as recipesApi from "@/api/recipes";
import { makeRecipeDetail } from "@/test/factories";
import { renderWithProviders } from "@/test/render";
import type { RecipeDetail } from "@/api/types";

function renderPage(route = "/recipes/recipe-id-1") {
  return renderWithProviders(<RecipeDetailPage />, { route, path: "/recipes/:id" });
}

function renderRecipe(overrides: Partial<RecipeDetail> = {}) {
  vi.spyOn(recipesApi, "getRecipe").mockResolvedValue(makeRecipeDetail(overrides));
  return renderPage();
}

describe("RecipeDetailPage", () => {
  it("renders a loading message while fetching the recipe", () => {
    vi.spyOn(recipesApi, "getRecipe").mockReturnValue(new Promise(() => {}));

    renderPage();

    expect(screen.getByText("Loading…")).toBeInTheDocument();
  });

  it("renders an error message when the recipe fetch fails", async () => {
    vi.spyOn(recipesApi, "getRecipe").mockRejectedValue(new ApiError(404, "Recipe not found"));

    renderPage();

    expect(await screen.findByText(/couldn't load this recipe/i)).toBeInTheDocument();
  });

  it("renders the recipe title", async () => {
    renderRecipe({ title: "Chicken Fried Rice" });

    expect(await screen.findByText("Chicken Fried Rice")).toBeInTheDocument();
  });

  it("shows cuisine, category, and author names when available", async () => {
    renderRecipe({
      cuisine: "Italian",
      category: { id: "category-1", name: "Pasta" },
      author: "Chef Ada",
    });

    expect(await screen.findByText("Italian")).toBeInTheDocument();
    expect(screen.getByText("Pasta")).toBeInTheDocument();
    expect(screen.getByText("Chef Ada")).toBeInTheDocument();
  });

  it("hides metadata when every value is null", async () => {
    renderRecipe({ cuisine: null, category: null, author: null });

    await screen.findByText("Chicken Fried Rice");
    expect(screen.queryByText("Cuisine:")).not.toBeInTheDocument();
    expect(screen.queryByText("Category:")).not.toBeInTheDocument();
    expect(screen.queryByText("Author:")).not.toBeInTheDocument();
  });

  it("renders the total cook and prep time", async () => {
    renderRecipe({ prepTimeMinutes: 10, cookTimeMinutes: 20 });

    expect(await screen.findByText("30 min")).toBeInTheDocument();
  });

  it("renders an instant total when the recipe has no prep or cook time", async () => {
    renderRecipe({ prepTimeMinutes: null, cookTimeMinutes: null });

    expect(await screen.findByText("Instant")).toBeInTheDocument();
  });

  it("renders the match badge for the recipe's match percentage", async () => {
    renderRecipe({ matchPercentage: 80.5, matchedIngredients: 4, missingCount: 1 });

    expect(await screen.findByText("Missing a couple ingredients")).toBeInTheDocument();
  });

  it("fetches the recipe with the ID from the URL params", async () => {
    const getRecipe = vi
      .spyOn(recipesApi, "getRecipe")
      .mockResolvedValue(makeRecipeDetail({ id: "recipe-id-1" }));

    renderPage("/recipes/recipe-id-1");

    await waitFor(() => {
      expect(getRecipe).toHaveBeenCalledWith("recipe-id-1");
    });
  });
});
