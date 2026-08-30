import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { ApiError } from "@/api/client";
import { ApiErrorAlert } from "@/components/ApiErrorAlert";

describe("ApiErrorAlert", () => {
  it("renders the API error message", () => {
    render(<ApiErrorAlert error={new ApiError(422, "Ingredient already in pantry")} />);

    expect(screen.getByRole("alert")).toHaveTextContent("Ingredient already in pantry");
  });

  it("falls back to a generic message for other errors", () => {
    render(<ApiErrorAlert error={new Error("Network error")} />);

    expect(screen.getByRole("alert")).toHaveTextContent("Something went wrong. Please try again.");
  });
});
