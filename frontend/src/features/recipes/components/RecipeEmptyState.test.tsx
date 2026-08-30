import { screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { RecipeEmptyState } from "@/features/recipes/components/RecipeEmptyState";
import { renderWithProviders } from "@/test/render";

describe("RecipeEmptyState", () => {
  it("renders the title and description", () => {
    renderWithProviders(
      <RecipeEmptyState title="Your kitchen is empty" description="Add a few ingredients to get started." />,
    );

    expect(screen.getByText("Your kitchen is empty")).toBeInTheDocument();
    expect(screen.getByText("Add a few ingredients to get started.")).toBeInTheDocument();
  });

  it("renders no action link", () => {
    renderWithProviders(<RecipeEmptyState title="Nothing here" description="Nothing to see." />);

    expect(screen.queryByRole("link")).not.toBeInTheDocument();
  });
});
