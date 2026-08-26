import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { MissingIngredients } from "@/features/recipes/components/MissingIngredients";

describe("MissingIngredients", () => {
  it("renders up to three ingredients and the remaining count", () => {
    render(
      <MissingIngredients
        count={4}
        ingredients={[
          { id: "1", name: "Milk" },
          { id: "2", name: "Butter" },
          { id: "3", name: "Flour" },
          { id: "4", name: "Eggs" },
        ]}
      />,
    );

    expect(screen.getByText("Missing 4 ingredients")).toBeInTheDocument();
    expect(screen.getByText("Milk")).toBeInTheDocument();
    expect(screen.getByText("+1 more")).toBeInTheDocument();
    expect(screen.queryByText("Eggs")).not.toBeInTheDocument();
  });

  it("renders nothing when there are no missing ingredients", () => {
    const { container } = render(<MissingIngredients count={0} ingredients={[]} />);

    expect(container).toBeEmptyDOMElement();
  });
});
