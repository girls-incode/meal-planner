import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { Loader } from "@/components/Loader";

describe("Loader", () => {
  it("renders an accessible loading status with the default label", () => {
    render(<Loader />);

    expect(screen.getByRole("status")).toHaveTextContent("Loading…");
  });

  it("supports a custom label and max width", () => {
    render(<Loader label="Loading recipes…" maxWidth="3xl" />);

    expect(screen.getByRole("status")).toHaveTextContent("Loading recipes…");
    expect(screen.getByRole("status")).toHaveClass("max-w-3xl");
  });
});
