import { renderHook, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactNode } from "react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useRecipeMatches } from "@/hooks/useRecipeMatches";
import * as pantryApi from "@/api/pantry";
import * as recipesApi from "@/api/recipes";
import type { PantryItem, RecipeMatch } from "@/api/types";

function wrapper({ children }: { children: ReactNode }) {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
}

afterEach(() => {
  vi.restoreAllMocks();
});

describe("useRecipeMatches", () => {
  it("does not fetch matches when the pantry is empty", async () => {
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue([]);
    const getRecipeMatches = vi.spyOn(recipesApi, "getRecipeMatches").mockResolvedValue([]);

    renderHook(() => useRecipeMatches(), { wrapper });

    await waitFor(() => expect(pantryApi.getPantry).toHaveBeenCalled());
    expect(getRecipeMatches).not.toHaveBeenCalled();
  });

  it("fetches matches with the correct ingredient IDs when the pantry has items", async () => {
    const items: PantryItem[] = [
      { id: "p1", ingredient: { id: "i1", name: "Egg" } },
      { id: "p2", ingredient: { id: "i2", name: "Flour" } },
    ];
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue(items);
    const getRecipeMatches = vi.spyOn(recipesApi, "getRecipeMatches").mockResolvedValue([]);

    renderHook(() => useRecipeMatches(), { wrapper });

    await waitFor(() => {
      expect(getRecipeMatches).toHaveBeenCalledWith(["i1", "i2"]);
    });
  });

  it("produces a distinct cache key when ingredient IDs change, even with the same count", async () => {
    const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    const mockRecipes: RecipeMatch[] = [
      {
        id: "r1",
        title: "Recipe 1",
        imageUrl: null,
        ratings: 4.5,
        cookTimeMinutes: 30,
        prepTimeMinutes: 10,
        matchedIngredients: 2,
        requiredIngredientCount: 3,
        missingCount: 1,
        matchPercentage: 66.7,
        missingIngredients: [],
      },
    ];

    const getRecipeMatches = vi.spyOn(recipesApi, "getRecipeMatches").mockResolvedValue(mockRecipes);

    // First render: pantry with [i1, i2]
    const items1: PantryItem[] = [
      { id: "p1", ingredient: { id: "i1", name: "Egg" } },
      { id: "p2", ingredient: { id: "i2", name: "Flour" } },
    ];
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue(items1);

    const { rerender } = renderHook(() => useRecipeMatches(), {
      wrapper: ({ children }: { children: React.ReactNode }) => (
        <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
      ),
    });

    await waitFor(() => {
      // First call with [i1, i2]
      const calls = getRecipeMatches.mock.calls;
      expect(calls.length).toBeGreaterThan(0);
    });

    const callCountAfterFirst = getRecipeMatches.mock.calls.length;

    // Re-render with different IDs but same count: [i3, i4] (simulating ingredient swap)
    const items2: PantryItem[] = [
      { id: "p3", ingredient: { id: "i3", name: "Sugar" } },
      { id: "p4", ingredient: { id: "i4", name: "Butter" } },
    ];
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue(items2);
    queryClient.setQueryData(["pantry"], items2);

    rerender();

    await waitFor(() => {
      // Should have called getRecipeMatches again with the new IDs, not from stale cache
      const calls = getRecipeMatches.mock.calls;
      expect(calls.length).toBeGreaterThan(callCountAfterFirst);
    });
  });
});
