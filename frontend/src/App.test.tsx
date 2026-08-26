import { screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { App } from "@/App";
import * as categoriesApi from "@/features/categories/api/categories";
import * as ingredientsApi from "@/features/pantry/api/ingredients";
import * as pantryApi from "@/features/pantry/api/pantry";
import * as recipesApi from "@/features/recipes/api/recipes";
import {
  makeIngredients,
  makeMatchesPage,
  makePantry,
  makePantryItem,
  makeRecipeDetail,
  makeRecipeMatch,
} from "@/test/factories";
import { renderWithProviders } from "@/test/render";

describe("App", () => {
  it("shows the latest ten categories below the home-page search", async () => {
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue([]);
    const getCategories = vi.spyOn(categoriesApi, "getCategories").mockResolvedValue({
      data: [
        { id: "category-1", name: "Breakfast" },
        { id: "category-2", name: "Dinner" },
      ],
      nextCursor: null,
    });

    renderWithProviders(<App />);

    expect(await screen.findByText("Breakfast")).toBeInTheDocument();
    expect(screen.getByText("Dinner")).toBeInTheDocument();
    expect(getCategories).toHaveBeenCalledWith(10);
  });

  it("shows the ingredient search and selected ingredients on the recipe results page", async () => {
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue(makePantry("Egg"));

    renderWithProviders(<App />, { route: "/recipes" });

    expect(screen.getByPlaceholderText("Add an ingredient...")).toBeInTheDocument();
    expect(await screen.findByText("Egg")).toBeInTheDocument();
  });

  it("hides the ingredient search on recipe detail pages", () => {
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue([]);

    renderWithProviders(<App />, { route: "/recipes/recipe-id-1" });

    expect(screen.queryByPlaceholderText("Add an ingredient...")).not.toBeInTheDocument();
  });

  it("adds ingredients from the shared search", async () => {
    const user = userEvent.setup();
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue([]);
    vi.spyOn(categoriesApi, "getCategories").mockResolvedValue({ data: [], nextCursor: null });
    vi.spyOn(ingredientsApi, "searchIngredients").mockResolvedValue(makeIngredients("Egg"));
    const addPantryItem = vi
      .spyOn(pantryApi, "addPantryItem")
      .mockResolvedValue(makePantryItem());

    renderWithProviders(<App />);
    await user.type(screen.getByPlaceholderText("Add an ingredient..."), "Egg");
    await user.click(await screen.findByRole("button", { name: "Egg" }));

    expect(addPantryItem.mock.calls[0][0]).toBe("i1");
  });

  it("requests matches only after Find recipes is pressed", async () => {
    const user = userEvent.setup();
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue(makePantry("Egg"));
    vi.spyOn(categoriesApi, "getCategories").mockResolvedValue({ data: [], nextCursor: null });
    const getRecipeMatches = vi
      .spyOn(recipesApi, "getRecipeMatches")
      .mockResolvedValue(makeMatchesPage([]));

    renderWithProviders(<App />);

    const findRecipes = await screen.findByRole("button", { name: "Find recipes →" });
    expect(getRecipeMatches).not.toHaveBeenCalled();

    await user.click(findRecipes);

    await screen.findByText("Nothing close enough yet");
    expect(getRecipeMatches).toHaveBeenCalledWith(["i1"]);
  });

  it("keeps the current matches after returning from a recipe detail", async () => {
    const user = userEvent.setup();
    const getPantry = vi.spyOn(pantryApi, "getPantry").mockResolvedValue(makePantry("Egg"));
    vi.spyOn(categoriesApi, "getCategories").mockResolvedValue({ data: [], nextCursor: null });
    const getRecipeMatches = vi.spyOn(recipesApi, "getRecipeMatches").mockResolvedValue(
      makeMatchesPage([makeRecipeMatch({ id: "recipe-id-1", title: "Egg Fried Rice" })]),
    );
    vi.spyOn(recipesApi, "getRecipe").mockResolvedValue(
      makeRecipeDetail({ id: "recipe-id-1", title: "Egg Fried Rice" }),
    );

    renderWithProviders(<App />);

    await user.click(await screen.findByRole("button", { name: "Find recipes →" }));
    await user.click(await screen.findByRole("link", { name: /egg fried rice/i }));
    await user.click(await screen.findByRole("button", { name: "Back to recipes" }));

    expect(await screen.findByRole("heading", { name: "Recipes you can make" })).toBeInTheDocument();
    expect(screen.queryByText("Ready to find recipes")).not.toBeInTheDocument();
    expect(getPantry).toHaveBeenCalledTimes(1);
    expect(getRecipeMatches).toHaveBeenCalledTimes(1);
  });

});
