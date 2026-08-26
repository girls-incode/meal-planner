import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { RecipeTime } from "@/components/RecipeTime";

describe("RecipeTime", () => {
  it("renders prep, cook, and total time", () => {
    render(<RecipeTime prepTimeMinutes={10} cookTimeMinutes={25} />);

    expect(screen.getByText("Prep: 10 min")).toBeInTheDocument();
    expect(screen.getByText("Cook: 25 min")).toBeInTheDocument();
    expect(screen.getByText("35 min")).toBeInTheDocument();
  });

  it("shows unavailable individual times and an instant total", () => {
    render(<RecipeTime prepTimeMinutes={null} cookTimeMinutes={null} />);

    expect(screen.getByText("Prep: —")).toBeInTheDocument();
    expect(screen.getByText("Cook: —")).toBeInTheDocument();
    expect(screen.getByText("Instant")).toBeInTheDocument();
  });
});
