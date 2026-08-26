import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { Rating } from "@/features/recipes/components/Rating";

describe("Rating", () => {
  it("renders the numeric rating and five stars", () => {
    render(<Rating value={4.5} />);

    expect(screen.getByText("(4.5)")).toBeInTheDocument();
    expect(document.querySelectorAll("svg")).toHaveLength(5);
  });

  it.each([null, 0])("renders nothing for an unavailable rating: %s", (value) => {
    const { container } = render(<Rating value={value} />);

    expect(container).toBeEmptyDOMElement();
  });
});
