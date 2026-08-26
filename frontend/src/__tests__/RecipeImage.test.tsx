import { act, fireEvent, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { RecipeImage } from "@/components/RecipeImage";
import { renderWithProviders } from "@/test/render";

describe("RecipeImage", () => {
  afterEach(() => vi.useRealTimers());

  it("shows a placeholder until the image has loaded", () => {
    vi.useFakeTimers();
    renderWithProviders(<RecipeImage src="https://example.com/recipe.jpg" alt="Pasta" />);

    expect(screen.getByRole("status", { name: "Loading recipe image" })).toBeInTheDocument();

    fireEvent.load(screen.getByRole("img", { name: "Pasta" }));

    act(() => vi.advanceTimersByTime(350));

    expect(screen.queryByRole("status", { name: "Loading recipe image" })).not.toBeInTheDocument();
  });
});
