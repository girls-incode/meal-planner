import { act, fireEvent, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { RecipeImage } from "@/features/recipes/components/RecipeImage";
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

  it("shows the fallback when there is no src", () => {
    renderWithProviders(<RecipeImage src={null} alt="Pasta" />);

    expect(screen.getByText("Image unavailable")).toBeInTheDocument();
    expect(screen.queryByRole("img")).not.toBeInTheDocument();
  });

  it("shows the fallback when the image fails to load", () => {
    renderWithProviders(<RecipeImage src="https://example.com/recipe.jpg" alt="Pasta" />);

    fireEvent.error(screen.getByRole("img", { name: "Pasta" }));

    expect(screen.getByText("Image unavailable")).toBeInTheDocument();
    expect(screen.queryByRole("img")).not.toBeInTheDocument();
  });

  it("retries with a fresh loading state when src changes after a failure", () => {
    const { rerender } = renderWithProviders(
      <RecipeImage src="https://example.com/recipe.jpg" alt="Pasta" />,
    );

    fireEvent.error(screen.getByRole("img", { name: "Pasta" }));
    expect(screen.getByText("Image unavailable")).toBeInTheDocument();

    rerender(<RecipeImage src="https://example.com/other.jpg" alt="Pasta" />);

    expect(screen.getByRole("status", { name: "Loading recipe image" })).toBeInTheDocument();
    expect(screen.getByRole("img", { name: "Pasta" })).toBeInTheDocument();
  });

  it("applies the className prop to the wrapper in both the loaded and fallback states", () => {
    const { rerender, container } = renderWithProviders(
      <RecipeImage src="https://example.com/recipe.jpg" alt="Pasta" className="custom-class" />,
    );

    expect(container.firstChild).toHaveClass("custom-class");

    rerender(<RecipeImage src={null} alt="Pasta" className="custom-class" />);

    expect(container.firstChild).toHaveClass("custom-class");
  });
});
