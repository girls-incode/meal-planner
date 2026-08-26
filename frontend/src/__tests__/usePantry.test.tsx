import { renderHook, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactNode } from "react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { usePantry, useAddPantryItem, useRemovePantryItem } from "@/hooks/usePantry";
import { ApiError } from "@/api/client";
import * as pantryApi from "@/api/pantry";
import type { PantryItem } from "@/api/types";

function wrapper(queryClient: QueryClient) {
  return function Wrapper({ children }: { children: ReactNode }) {
    return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
  };
}

afterEach(() => {
  vi.restoreAllMocks();
});

describe("usePantry", () => {
  it("fetches and returns the pantry items", async () => {
    const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    const items: PantryItem[] = [
      { id: "p1", ingredient: { id: "i1", name: "Egg" } },
      { id: "p2", ingredient: { id: "i2", name: "Flour" } },
    ];
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue(items);

    const { result } = renderHook(() => usePantry(), { wrapper: wrapper(queryClient) });

    await waitFor(() => {
      expect(result.current.data).toEqual(items);
    });
  });

  it("populates error state when fetching fails", async () => {
    const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    const error = new ApiError(500, "Server error");
    vi.spyOn(pantryApi, "getPantry").mockRejectedValue(error);

    const { result } = renderHook(() => usePantry(), { wrapper: wrapper(queryClient) });

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
      expect(result.current.error).toEqual(error);
    });
  });
});

describe("useAddPantryItem", () => {
  it("calls addPantryItem with the ingredient ID", async () => {
    const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    const addPantryItem = vi.spyOn(pantryApi, "addPantryItem").mockResolvedValue({
      id: "p1",
      ingredient: { id: "i1", name: "Egg" },
    });

    const { result } = renderHook(() => useAddPantryItem(), { wrapper: wrapper(queryClient) });

    result.current.mutate("i1");

    await waitFor(() => {
      expect(addPantryItem).toHaveBeenCalled();
      expect(addPantryItem.mock.calls[0][0]).toBe("i1");
    });
  });

  it("invalidates pantry and recipe-matches queries on success", async () => {
    const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue([]);
    vi.spyOn(pantryApi, "addPantryItem").mockResolvedValue({
      id: "p1",
      ingredient: { id: "i1", name: "Egg" },
    });

    const invalidateQueries = vi.spyOn(queryClient, "invalidateQueries");

    const { result } = renderHook(() => useAddPantryItem(), { wrapper: wrapper(queryClient) });

    result.current.mutate("i1");

    await waitFor(() => {
      // Should have been called twice: once for ["pantry"], once for ["recipe-matches"]
      expect(invalidateQueries).toHaveBeenCalledWith({ queryKey: ["pantry"] });
      expect(invalidateQueries).toHaveBeenCalledWith({ queryKey: ["recipe-matches"] });
    });
  });

  it("populates error state on failure", async () => {
    const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    const error = new ApiError(422, "ingredient already in pantry");
    vi.spyOn(pantryApi, "addPantryItem").mockRejectedValue(error);

    const { result } = renderHook(() => useAddPantryItem(), { wrapper: wrapper(queryClient) });

    result.current.mutate("i1");

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
      expect(result.current.error).toEqual(error);
    });
  });
});

describe("useRemovePantryItem", () => {
  it("calls removePantryItem with the pantry item ID", async () => {
    const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    const removePantryItem = vi.spyOn(pantryApi, "removePantryItem").mockResolvedValue(undefined);

    const { result } = renderHook(() => useRemovePantryItem(), { wrapper: wrapper(queryClient) });

    result.current.mutate("p1");

    await waitFor(() => {
      expect(removePantryItem).toHaveBeenCalled();
      expect(removePantryItem.mock.calls[0][0]).toBe("p1");
    });
  });

  it("invalidates pantry and recipe-matches queries on success", async () => {
    const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    vi.spyOn(pantryApi, "removePantryItem").mockResolvedValue(undefined);

    const invalidateQueries = vi.spyOn(queryClient, "invalidateQueries");

    const { result } = renderHook(() => useRemovePantryItem(), { wrapper: wrapper(queryClient) });

    result.current.mutate("p1");

    await waitFor(() => {
      expect(invalidateQueries).toHaveBeenCalledWith({ queryKey: ["pantry"] });
      expect(invalidateQueries).toHaveBeenCalledWith({ queryKey: ["recipe-matches"] });
    });
  });

  it("populates error state on failure", async () => {
    const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    const error = new ApiError(404, "Pantry item not found");
    vi.spyOn(pantryApi, "removePantryItem").mockRejectedValue(error);

    const { result } = renderHook(() => useRemovePantryItem(), { wrapper: wrapper(queryClient) });

    result.current.mutate("p1");

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
      expect(result.current.error).toEqual(error);
    });
  });
});
