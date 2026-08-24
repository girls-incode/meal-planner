import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { IngredientChip } from "@/components/IngredientChip";

describe("IngredientChip", () => {
  it("renders the ingredient label", () => {
    render(<IngredientChip label="Chicken" onRemove={vi.fn()} />);
    expect(screen.getByText("Chicken")).toBeInTheDocument();
  });

  it("calls onRemove when the remove button is clicked", async () => {
    const onRemove = vi.fn();
    render(<IngredientChip label="Chicken" onRemove={onRemove} />);

    await userEvent.click(screen.getByRole("button", { name: /remove chicken/i }));

    expect(onRemove).toHaveBeenCalledTimes(1);
  });

  it("disables the remove button when disabled", () => {
    render(<IngredientChip label="Chicken" onRemove={vi.fn()} disabled />);
    expect(screen.getByRole("button", { name: /remove chicken/i })).toBeDisabled();
  });
});
