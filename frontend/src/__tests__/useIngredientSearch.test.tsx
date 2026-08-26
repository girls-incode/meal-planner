import { act, renderHook, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useIngredientSearch } from "@/hooks/useIngredientSearch";
import * as ingredientsApi from "@/api/ingredients";
import { makeIngredients } from "@/test/factories";
import { queryWrapper } from "@/test/render";

/** Must match the debounce in useIngredientSearch. */
const DEBOUNCE_MS = 300;

afterEach(() => {
  vi.useRealTimers();
});

describe("useIngredientSearch", () => {
  it("does not fetch for an empty query", async () => {
    const searchIngredients = vi
      .spyOn(ingredientsApi, "searchIngredients")
      .mockResolvedValue([]);

    renderHook(() => useIngredientSearch(""), { wrapper: queryWrapper() });

    await waitFor(() => expect(searchIngredients).not.toHaveBeenCalled());
  });

  it("does not fetch for a whitespace-only query", async () => {
    const searchIngredients = vi
      .spyOn(ingredientsApi, "searchIngredients")
      .mockResolvedValue([]);

    renderHook(() => useIngredientSearch("   "), { wrapper: queryWrapper() });

    await waitFor(() => expect(searchIngredients).not.toHaveBeenCalled());
  });

  it("returns the results once the query settles", async () => {
    const results = makeIngredients("Egg");
    const searchIngredients = vi
      .spyOn(ingredientsApi, "searchIngredients")
      .mockResolvedValue(results);

    const { result } = renderHook(() => useIngredientSearch("egg"), {
      wrapper: queryWrapper(),
    });

    await waitFor(() => expect(result.current.data).toEqual(results));
    expect(searchIngredients).toHaveBeenCalledWith("egg");
  });

  it("holds the request until the full debounce interval has elapsed", () => {
    vi.useFakeTimers();
    const searchIngredients = vi
      .spyOn(ingredientsApi, "searchIngredients")
      .mockResolvedValue([]);

    renderHook(() => useIngredientSearch("egg"), { wrapper: queryWrapper() });

    act(() => {
      vi.advanceTimersByTime(DEBOUNCE_MS - 1);
    });
    expect(searchIngredients).not.toHaveBeenCalled();

    act(() => {
      vi.advanceTimersByTime(1);
    });
    expect(searchIngredients).toHaveBeenCalledWith("egg");
  });

  it("restarts the debounce on every keystroke", () => {
    vi.useFakeTimers();
    const searchIngredients = vi
      .spyOn(ingredientsApi, "searchIngredients")
      .mockResolvedValue([]);

    const { rerender } = renderHook(({ query }) => useIngredientSearch(query), {
      initialProps: { query: "e" },
      wrapper: queryWrapper(),
    });

    // Type again just before the first debounce would have fired.
    act(() => {
      vi.advanceTimersByTime(DEBOUNCE_MS - 1);
    });
    rerender({ query: "eg" });

    // The original deadline passes with no request, because typing reset it.
    act(() => {
      vi.advanceTimersByTime(1);
    });
    expect(searchIngredients).not.toHaveBeenCalled();

    act(() => {
      vi.advanceTimersByTime(DEBOUNCE_MS);
    });
    expect(searchIngredients).toHaveBeenCalledTimes(1);
    expect(searchIngredients).toHaveBeenCalledWith("eg");
  });

  it("only fetches the final query when typing quickly", async () => {
    const searchIngredients = vi
      .spyOn(ingredientsApi, "searchIngredients")
      .mockResolvedValue([]);

    const { rerender } = renderHook(({ query }) => useIngredientSearch(query), {
      initialProps: { query: "" },
      wrapper: queryWrapper(),
    });

    rerender({ query: "e" });
    rerender({ query: "eg" });
    rerender({ query: "egg" });

    await waitFor(() => expect(searchIngredients).toHaveBeenCalledWith("egg"));
    // The intermediate queries were cancelled before their debounce elapsed.
    expect(searchIngredients).toHaveBeenCalledTimes(1);
  });
});

