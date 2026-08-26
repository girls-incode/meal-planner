import { renderHook, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { useRecipe } from "@/features/recipes/hooks/useRecipe";
import { ApiError } from "@/api/client";
import * as recipesApi from "@/features/recipes/api/recipes";
import { makeRecipeDetail } from "@/test/factories";
import { queryWrapper } from "@/test/render";

describe("useRecipe", () => {
  it("does not fetch when no id is given", async () => {
    const getRecipe = vi
      .spyOn(recipesApi, "getRecipe")
      .mockResolvedValue(makeRecipeDetail());

    renderHook(() => useRecipe(undefined), { wrapper: queryWrapper() });

    await waitFor(() => expect(getRecipe).not.toHaveBeenCalled());
  });

  it("fetches the recipe for the given id and returns it", async () => {
    const recipe = makeRecipeDetail({ id: "r1", title: "Chicken Fried Rice" });
    const getRecipe = vi.spyOn(recipesApi, "getRecipe").mockResolvedValue(recipe);

    const { result } = renderHook(() => useRecipe("r1"), { wrapper: queryWrapper() });

    await waitFor(() => expect(result.current.data).toEqual(recipe));
    expect(getRecipe).toHaveBeenCalledWith("r1");
  });

  it("populates error state when the fetch fails", async () => {
    const error = new ApiError(404, "Recipe not found");
    vi.spyOn(recipesApi, "getRecipe").mockRejectedValue(error);

    const { result } = renderHook(() => useRecipe("r1"), { wrapper: queryWrapper() });

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
      expect(result.current.error).toEqual(error);
    });
  });
});
