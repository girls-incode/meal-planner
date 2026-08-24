import { renderHook, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactNode } from "react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useRecipeMatches } from "@/hooks/useRecipeMatches";
import * as pantryApi from "@/api/pantry";
import * as recipesApi from "@/api/recipes";
import type { PantryItem } from "@/api/types";

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

  it("refetches matches when the pantry item count changes", async () => {
    const items: PantryItem[] = [{ id: "p1", ingredient: { id: "i1", name: "Egg" } }];
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue(items);
    const getRecipeMatches = vi.spyOn(recipesApi, "getRecipeMatches").mockResolvedValue([]);

    renderHook(() => useRecipeMatches(), { wrapper });

    await waitFor(() => expect(getRecipeMatches).toHaveBeenCalledTimes(1));
  });
});
