import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { describe, expect, it } from "vitest";
import { RecipeCard } from "@/components/RecipeCard";
import type { RecipeMatch } from "@/api/types";

function makeRecipe(overrides: Partial<RecipeMatch> = {}): RecipeMatch {
  return {
    id: "1",
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
    ...overrides,
  };
}

function renderCard(recipe: RecipeMatch) {
  return render(
    <MemoryRouter>
      <RecipeCard recipe={recipe} />
    </MemoryRouter>,
  );
}

describe("RecipeCard", () => {
  it("shows 'Ready to cook' for a full match", () => {
    renderCard(makeRecipe({ matchPercentage: 100, missingCount: 0 }));
    expect(screen.getByText("Ready to cook")).toBeInTheDocument();
  });

  it("shows the missing ingredient count for a partial match", () => {
    renderCard(makeRecipe({ matchPercentage: 75, missingCount: 2 }));
    expect(screen.getByText("Missing 2 ingredients")).toBeInTheDocument();
  });

  it("renders the total cook time", () => {
    renderCard(makeRecipe({ prepTimeMinutes: 10, cookTimeMinutes: 25 }));
    expect(screen.getByText("35 min")).toBeInTheDocument();
  });
});
