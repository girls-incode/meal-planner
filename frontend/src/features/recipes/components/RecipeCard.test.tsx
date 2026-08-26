import { screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { RecipeCard } from "@/features/recipes/components/RecipeCard";
import { makeIngredients, makeRecipeMatch } from "@/test/factories";
import { renderWithProviders } from "@/test/render";
import type { RecipeMatch } from "@/api/types";

function renderCard(overrides: Partial<RecipeMatch> = {}) {
  return renderWithProviders(<RecipeCard recipe={makeRecipeMatch(overrides)} />);
}

describe("RecipeCard", () => {
  it("shows 'Ready to cook' for a full match", () => {
    renderCard({ matchPercentage: 100, missingCount: 0 });

    expect(screen.getByText("Ready to cook")).toBeInTheDocument();
  });

  it("shows the missing ingredient count for a partial match", () => {
    renderCard({
      matchPercentage: 75,
      missingCount: 2,
      missingIngredients: makeIngredients("Milk", "Butter"),
    });

    expect(screen.getByText(/Missing 2 ingredients/)).toBeInTheDocument();
  });

  it("shows missing ingredient names and limits the list to three", () => {
    renderCard({
      missingCount: 4,
      missingIngredients: makeIngredients("Milk", "Butter", "Flour", "Eggs"),
    });

    expect(screen.getByText("Milk")).toBeInTheDocument();
    expect(screen.getByText("Butter")).toBeInTheDocument();
    expect(screen.getByText("Flour")).toBeInTheDocument();
    expect(screen.getByText("+1 more")).toBeInTheDocument();
    expect(screen.queryByText("Eggs")).not.toBeInTheDocument();
  });

  it("renders the total cook time", () => {
    renderCard({ prepTimeMinutes: 10, cookTimeMinutes: 25 });

    expect(screen.getByText("35 min")).toBeInTheDocument();
  });

  it("shows cuisine, category, and author names when available", () => {
    renderCard({
      cuisine: "Italian",
      category: { id: "category-1", name: "Pasta" },
      author: { id: "author-1", name: "Chef Ada" },
    });

    expect(screen.getByText("Italian")).toBeInTheDocument();
    expect(screen.getByText("Pasta")).toBeInTheDocument();
    expect(screen.getByText("Chef Ada")).toBeInTheDocument();
  });

  it("hides recipe metadata that is null", () => {
    renderCard({ cuisine: null, category: null, author: null });

    expect(screen.queryByText("Cuisine:")).not.toBeInTheDocument();
    expect(screen.queryByText("Category:")).not.toBeInTheDocument();
    expect(screen.queryByText("Author:")).not.toBeInTheDocument();
  });
});
