import { renderHook, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { useRecipeMatches } from "@/hooks/useRecipeMatches";
import * as recipesApi from "@/api/recipes";
import { makeMatchesPage, makeRecipeMatch } from "@/test/factories";
import { createTestQueryClient, queryWrapper } from "@/test/render";

describe("useRecipeMatches", () => {
  it("does not fetch matches without submitted ingredient IDs", () => {
    const getRecipeMatches = vi
      .spyOn(recipesApi, "getRecipeMatches")
      .mockResolvedValue(makeMatchesPage([]));

    renderHook(() => useRecipeMatches([]), { wrapper: queryWrapper() });

    expect(getRecipeMatches).not.toHaveBeenCalled();
  });

  it("fetches matches with the submitted ingredient IDs", async () => {
    const getRecipeMatches = vi
      .spyOn(recipesApi, "getRecipeMatches")
      .mockResolvedValue(makeMatchesPage([]));

    renderHook(() => useRecipeMatches(["i1", "i2"]), { wrapper: queryWrapper() });

    await waitFor(() => {
      expect(getRecipeMatches).toHaveBeenCalledWith(["i1", "i2"]);
    });
  });

  it("returns the first page and its next cursor", async () => {
    const recipes = [makeRecipeMatch()];
    vi.spyOn(recipesApi, "getRecipeMatches").mockResolvedValue(
      makeMatchesPage(recipes, "cursor-abc"),
    );

    const { result } = renderHook(() => useRecipeMatches(["i1"]), { wrapper: queryWrapper() });

    await waitFor(() => {
      expect(result.current.data?.pages).toEqual([
        { data: recipes, nextCursor: "cursor-abc" },
      ]);
    });
  });

  it("requests the next page with the cursor returned by the previous page", async () => {
    const getRecipeMatches = vi
      .spyOn(recipesApi, "getRecipeMatches")
      .mockResolvedValueOnce(makeMatchesPage([makeRecipeMatch({ id: "r1" })], "cursor-abc"))
      .mockResolvedValueOnce(makeMatchesPage([makeRecipeMatch({ id: "r2" })]));

    const { result } = renderHook(() => useRecipeMatches(["i1"]), { wrapper: queryWrapper() });

    await waitFor(() => expect(result.current.hasNextPage).toBe(true));
    await result.current.fetchNextPage();

    expect(getRecipeMatches).toHaveBeenLastCalledWith(["i1"], { cursor: "cursor-abc" });
    await waitFor(() => {
      expect(result.current.data?.pages.flatMap((page) => page.data.map((recipe) => recipe.id))).toEqual([
        "r1",
        "r2",
      ]);
    });
  });

  it("produces a distinct cache key when submitted ingredient IDs change, even with the same count", async () => {
    const queryClient = createTestQueryClient();
    const getRecipeMatches = vi
      .spyOn(recipesApi, "getRecipeMatches")
      .mockResolvedValue(makeMatchesPage());

    const { rerender } = renderHook(({ ingredientIds }: { ingredientIds: string[] }) => useRecipeMatches(ingredientIds), {
      wrapper: queryWrapper(queryClient),
      initialProps: { ingredientIds: ["i1", "i2"] },
    });

    await waitFor(() => expect(getRecipeMatches).toHaveBeenCalledTimes(1));

    // Swap both ingredient IDs while keeping the submitted list the same size.
    rerender({ ingredientIds: ["i3", "i4"] });

    await waitFor(() => {
      // A second fetch proves the swap produced a new cache key rather than a stale hit.
      expect(getRecipeMatches).toHaveBeenCalledTimes(2);
    });
  });
});
