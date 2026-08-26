import { renderHook, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { usePantry, useAddPantryItem, useRemovePantryItem } from "@/hooks/usePantry";
import { ApiError } from "@/api/client";
import * as pantryApi from "@/api/pantry";
import { makePantry, makePantryItem } from "@/test/factories";
import { createTestQueryClient, queryWrapper } from "@/test/render";

describe("usePantry", () => {
  it("fetches and returns the pantry items", async () => {
    const items = makePantry("Egg", "Flour");
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue(items);

    const { result } = renderHook(() => usePantry(), { wrapper: queryWrapper() });

    await waitFor(() => {
      expect(result.current.data).toEqual(items);
    });
  });

  it("populates error state when fetching fails", async () => {
    const error = new ApiError(500, "Server error");
    vi.spyOn(pantryApi, "getPantry").mockRejectedValue(error);

    const { result } = renderHook(() => usePantry(), { wrapper: queryWrapper() });

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
      expect(result.current.error).toEqual(error);
    });
  });
});

describe("useAddPantryItem", () => {
  it("calls addPantryItem with the ingredient ID", async () => {
    const addPantryItem = vi
      .spyOn(pantryApi, "addPantryItem")
      .mockResolvedValue(makePantryItem());

    const { result } = renderHook(() => useAddPantryItem(), { wrapper: queryWrapper() });

    result.current.mutate("i1");

    // React Query v5 calls mutationFn with (variables, context), so assert on
    // the first argument rather than the whole call.
    await waitFor(() => {
      expect(addPantryItem.mock.calls[0][0]).toBe("i1");
    });
  });

  it("optimistically adds the item before the request resolves", async () => {
    const queryClient = createTestQueryClient();
    queryClient.setQueryData(["pantry"], makePantry("Egg"));
    // Never resolves, so the cache we observe is purely the optimistic update.
    vi.spyOn(pantryApi, "addPantryItem").mockReturnValue(new Promise(() => {}));

    const { result } = renderHook(() => useAddPantryItem(), {
      wrapper: queryWrapper(queryClient),
    });

    result.current.mutate("i2");

    await waitFor(() => {
      expect(queryClient.getQueryData(["pantry"])).toHaveLength(2);
    });
  });

  it("rolls the optimistic update back when the request fails", async () => {
    const queryClient = createTestQueryClient();
    const items = makePantry("Egg");
    queryClient.setQueryData(["pantry"], items);
    vi.spyOn(pantryApi, "addPantryItem").mockRejectedValue(new ApiError(422, "already added"));

    const { result } = renderHook(() => useAddPantryItem(), {
      wrapper: queryWrapper(queryClient),
    });

    result.current.mutate("i2");

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
    });
    expect(queryClient.getQueryData(["pantry"])).toEqual(items);
  });

  it("invalidates pantry and recipe-matches queries once settled", async () => {
    const queryClient = createTestQueryClient();
    vi.spyOn(pantryApi, "addPantryItem").mockResolvedValue(makePantryItem());
    const invalidateQueries = vi.spyOn(queryClient, "invalidateQueries");

    const { result } = renderHook(() => useAddPantryItem(), {
      wrapper: queryWrapper(queryClient),
    });

    result.current.mutate("i1");

    await waitFor(() => {
      expect(invalidateQueries).toHaveBeenCalledWith({ queryKey: ["pantry"] });
      expect(invalidateQueries).toHaveBeenCalledWith({ queryKey: ["recipe-matches"] });
    });
  });

  it("populates error state on failure", async () => {
    const error = new ApiError(422, "ingredient already in pantry");
    vi.spyOn(pantryApi, "addPantryItem").mockRejectedValue(error);

    const { result } = renderHook(() => useAddPantryItem(), { wrapper: queryWrapper() });

    result.current.mutate("i1");

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
      expect(result.current.error).toEqual(error);
    });
  });
});

describe("useRemovePantryItem", () => {
  it("calls removePantryItem with the pantry item ID", async () => {
    const removePantryItem = vi
      .spyOn(pantryApi, "removePantryItem")
      .mockResolvedValue(undefined);

    const { result } = renderHook(() => useRemovePantryItem(), { wrapper: queryWrapper() });

    result.current.mutate("p1");

    await waitFor(() => {
      expect(removePantryItem.mock.calls[0][0]).toBe("p1");
    });
  });

  it("optimistically removes the item before the request resolves", async () => {
    const queryClient = createTestQueryClient();
    queryClient.setQueryData(["pantry"], makePantry("Egg", "Flour"));
    vi.spyOn(pantryApi, "removePantryItem").mockReturnValue(new Promise(() => {}));

    const { result } = renderHook(() => useRemovePantryItem(), {
      wrapper: queryWrapper(queryClient),
    });

    result.current.mutate("p1");

    await waitFor(() => {
      expect(queryClient.getQueryData(["pantry"])).toHaveLength(1);
    });
  });

  it("rolls the optimistic removal back when the request fails", async () => {
    const queryClient = createTestQueryClient();
    const items = makePantry("Egg", "Flour");
    queryClient.setQueryData(["pantry"], items);
    vi.spyOn(pantryApi, "removePantryItem").mockRejectedValue(new ApiError(404, "not found"));

    const { result } = renderHook(() => useRemovePantryItem(), {
      wrapper: queryWrapper(queryClient),
    });

    result.current.mutate("p1");

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
    });
    expect(queryClient.getQueryData(["pantry"])).toEqual(items);
  });

  it("invalidates pantry and recipe-matches queries once settled", async () => {
    const queryClient = createTestQueryClient();
    vi.spyOn(pantryApi, "removePantryItem").mockResolvedValue(undefined);
    const invalidateQueries = vi.spyOn(queryClient, "invalidateQueries");

    const { result } = renderHook(() => useRemovePantryItem(), {
      wrapper: queryWrapper(queryClient),
    });

    result.current.mutate("p1");

    await waitFor(() => {
      expect(invalidateQueries).toHaveBeenCalledWith({ queryKey: ["pantry"] });
      expect(invalidateQueries).toHaveBeenCalledWith({ queryKey: ["recipe-matches"] });
    });
  });

  it("populates error state on failure", async () => {
    const error = new ApiError(404, "Pantry item not found");
    vi.spyOn(pantryApi, "removePantryItem").mockRejectedValue(error);

    const { result } = renderHook(() => useRemovePantryItem(), { wrapper: queryWrapper() });

    result.current.mutate("p1");

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
      expect(result.current.error).toEqual(error);
    });
  });
});
