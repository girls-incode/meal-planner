import { renderHook, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { useRecipeMatches } from "@/hooks/useRecipeMatches";
import * as pantryApi from "@/api/pantry";
import * as recipesApi from "@/api/recipes";
import {
  makeIngredient,
  makeMatchesPage,
  makePantry,
  makePantryItem,
  makeRecipeMatch,
} from "@/test/factories";
import { createTestQueryClient, queryWrapper } from "@/test/render";

describe("useRecipeMatches", () => {
  it("does not fetch matches when the pantry is empty", async () => {
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue([]);
    const getRecipeMatches = vi
      .spyOn(recipesApi, "getRecipeMatches")
      .mockResolvedValue(makeMatchesPage([]));

    renderHook(() => useRecipeMatches(), { wrapper: queryWrapper() });

    await waitFor(() => expect(pantryApi.getPantry).toHaveBeenCalled());
    expect(getRecipeMatches).not.toHaveBeenCalled();
  });

  it("fetches matches with the ingredient IDs from the pantry", async () => {
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue(makePantry("Egg", "Flour"));
    const getRecipeMatches = vi
      .spyOn(recipesApi, "getRecipeMatches")
      .mockResolvedValue(makeMatchesPage([]));

    renderHook(() => useRecipeMatches(), { wrapper: queryWrapper() });

    await waitFor(() => {
      expect(getRecipeMatches).toHaveBeenCalledWith(["i1", "i2"]);
    });
  });

  it("returns the paginated envelope, including nextCursor", async () => {
    const recipes = [makeRecipeMatch()];
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue(makePantry("Egg"));
    vi.spyOn(recipesApi, "getRecipeMatches").mockResolvedValue(
      makeMatchesPage(recipes, "cursor-abc"),
    );

    const { result } = renderHook(() => useRecipeMatches(), { wrapper: queryWrapper() });

    await waitFor(() => {
      expect(result.current.data).toEqual({ data: recipes, nextCursor: "cursor-abc" });
    });
  });

  it("produces a distinct cache key when ingredient IDs change, even with the same count", async () => {
    const queryClient = createTestQueryClient();
    const getRecipeMatches = vi
      .spyOn(recipesApi, "getRecipeMatches")
      .mockResolvedValue(makeMatchesPage());

    vi.spyOn(pantryApi, "getPantry").mockResolvedValue(makePantry("Egg", "Flour"));

    const { rerender } = renderHook(() => useRecipeMatches(), {
      wrapper: queryWrapper(queryClient),
    });

    await waitFor(() => expect(getRecipeMatches).toHaveBeenCalledTimes(1));

    // Swap both ingredients for different IDs, keeping the pantry size the same.
    queryClient.setQueryData(["pantry"], [
      makePantryItem({ id: "p3", ingredient: makeIngredient({ id: "i3", name: "Sugar" }) }),
      makePantryItem({ id: "p4", ingredient: makeIngredient({ id: "i4", name: "Butter" }) }),
    ]);
    rerender();

    await waitFor(() => {
      // A second fetch proves the swap produced a new cache key rather than a stale hit.
      expect(getRecipeMatches).toHaveBeenCalledTimes(2);
    });
  });
});
