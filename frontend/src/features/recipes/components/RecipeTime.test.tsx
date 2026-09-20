import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { RecipeTime } from "@/features/recipes/components/RecipeTime";

describe("RecipeTime", () => {
  it("renders prep, cook, and the summed total", () => {
    render(<RecipeTime prepTimeMinutes={10} cookTimeMinutes={25} />);

    expect(screen.getByText("Prep: 10 min")).toBeInTheDocument();
    expect(screen.getByText("Cook: 25 min")).toBeInTheDocument();
    expect(screen.getByText("Total:")).toBeInTheDocument();
    expect(screen.getByText("35 min")).toBeInTheDocument();
  });

  it.each([null, 0])(
    "omits the prep segment when prep time is %s",
    (prepTimeMinutes) => {
      render(
        <RecipeTime prepTimeMinutes={prepTimeMinutes} cookTimeMinutes={25} />,
      );

      expect(screen.queryByText(/Prep:/)).not.toBeInTheDocument();
      expect(screen.getByText("Cook: 25 min")).toBeInTheDocument();
      expect(screen.getByText("25 min")).toBeInTheDocument();
    },
  );

  it.each([null, 0])(
    "omits the cook segment when cook time is %s",
    (cookTimeMinutes) => {
      render(
        <RecipeTime prepTimeMinutes={10} cookTimeMinutes={cookTimeMinutes} />,
      );

      expect(screen.queryByText(/Cook:/)).not.toBeInTheDocument();
      expect(screen.getByText("Prep: 10 min")).toBeInTheDocument();
      expect(screen.getByText("10 min")).toBeInTheDocument();
    },
  );

  it("shows an instant total when there is no prep or cook time", () => {
    render(<RecipeTime prepTimeMinutes={null} cookTimeMinutes={null} />);

    expect(screen.queryByText(/Prep:/)).not.toBeInTheDocument();
    expect(screen.queryByText(/Cook:/)).not.toBeInTheDocument();
    expect(screen.getByText("Instant")).toBeInTheDocument();
  });

  it("always renders the total, even with no times to sum", () => {
    render(<RecipeTime prepTimeMinutes={0} cookTimeMinutes={0} />);

    expect(screen.getByText("Total:")).toBeInTheDocument();
    expect(screen.getByText("Instant")).toBeInTheDocument();
  });
});
