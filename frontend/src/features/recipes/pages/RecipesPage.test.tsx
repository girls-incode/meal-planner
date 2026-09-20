import { screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { RecipesPage } from "@/features/recipes/pages/RecipesPage";
import { ApiError } from "@/api/client";
import * as pantryApi from "@/features/pantry/api/pantry";
import * as recipesApi from "@/features/recipes/api/recipes";
import { makeMatchesPage, makePantry, makeRecipeMatch } from "@/test/factories";
import { renderWithProviders } from "@/test/render";

function renderPage(
  ingredientIds: string[] | null = ["i1"],
  searchVersion = 1,
) {
  return renderWithProviders(
    <RecipesPage ingredientIds={ingredientIds} searchVersion={searchVersion} />,
  );
}

function mockPantry() {
  vi.spyOn(pantryApi, "getPantry").mockResolvedValue(makePantry("Egg"));
}

describe("RecipesPage", () => {
  it("shows a loading state while the pantry is being fetched", () => {
    vi.spyOn(pantryApi, "getPantry").mockReturnValue(new Promise(() => {}));

    renderPage();

    expect(screen.getByText("Loading pantry…")).toBeInTheDocument();
  });

  it("shows the empty-pantry state when there are no pantry items", async () => {
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue([]);

    renderPage();

    expect(
      await screen.findByText("Your kitchen is empty"),
    ).toBeInTheDocument();
  });

  it("waits for Find recipes before fetching matches", async () => {
    mockPantry();
    const getRecipeMatches = vi.spyOn(recipesApi, "getRecipeMatches");

    renderPage(null);

    expect(
      await screen.findByText("Ready to find recipes"),
    ).toBeInTheDocument();
    expect(getRecipeMatches).not.toHaveBeenCalled();
  });

  it("renders the recipes from the response's data array", async () => {
    mockPantry();
    vi.spyOn(recipesApi, "getRecipeMatches").mockResolvedValue(
      makeMatchesPage([makeRecipeMatch({ title: "Golden Sweet Cornbread" })]),
    );

    renderPage();

    expect(
      await screen.findByText("Golden Sweet Cornbread"),
    ).toBeInTheDocument();
  });

  it("renders the page when the response carries a nextCursor", async () => {
    mockPantry();
    vi.spyOn(recipesApi, "getRecipeMatches").mockResolvedValue(
      makeMatchesPage(
        [makeRecipeMatch({ title: "Golden Sweet Cornbread" })],
        "cursor-abc",
      ),
    );

    renderPage();

    expect(
      await screen.findByText("Golden Sweet Cornbread"),
    ).toBeInTheDocument();
  });

  it("shows the empty-matches state when the response data array is empty", async () => {
    mockPantry();
    vi.spyOn(recipesApi, "getRecipeMatches").mockResolvedValue(
      makeMatchesPage([]),
    );

    renderPage();

    expect(
      await screen.findByText("Nothing close enough yet"),
    ).toBeInTheDocument();
    expect(
      screen.queryByRole("link", { name: "Add ingredient" }),
    ).not.toBeInTheDocument();
  });

  it("surfaces the API error message when the matches request fails", async () => {
    mockPantry();
    vi.spyOn(recipesApi, "getRecipeMatches").mockRejectedValue(
      new ApiError(422, "ingredients contains unknown ingredients"),
    );

    renderPage();

    expect(
      await screen.findByText("ingredients contains unknown ingredients"),
    ).toBeInTheDocument();
  });

  it("falls back to a generic message when the error is not an ApiError", async () => {
    mockPantry();
    vi.spyOn(recipesApi, "getRecipeMatches").mockRejectedValue(
      new Error("network error"),
    );

    renderPage();

    expect(
      await screen.findByText(/couldn't load your recipe matches/i),
    ).toBeInTheDocument();
  });
});
