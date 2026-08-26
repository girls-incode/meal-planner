import { screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { PantryPage } from "@/features/pantry/pages/PantryPage";
import * as pantryApi from "@/features/pantry/api/pantry";
import { makePantry } from "@/test/factories";
import { renderWithProviders } from "@/test/render";

function renderPage(onFindRecipes = vi.fn()) {
  return renderWithProviders(<PantryPage onFindRecipes={onFindRecipes} />);
}

describe("PantryPage", () => {
  it("renders the empty state when the pantry has no items", async () => {
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue([]);

    renderPage();

    expect(await screen.findByText("Your kitchen is empty")).toBeInTheDocument();
  });

  it("renders ingredient chips when the pantry has items", async () => {
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue(makePantry("Egg", "Flour"));

    renderPage();

    expect(await screen.findByText("Egg")).toBeInTheDocument();
    expect(screen.getByText("Flour")).toBeInTheDocument();
  });

  it("does not show the empty state while the pantry is loading", () => {
    vi.spyOn(pantryApi, "getPantry").mockReturnValue(new Promise(() => {}));

    renderPage();

    expect(screen.queryByText("Your kitchen is empty")).not.toBeInTheDocument();
  });

  it("removes an ingredient when the chip's remove button is clicked", async () => {
    const user = userEvent.setup();
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue(makePantry("Egg"));
    const removePantryItem = vi
      .spyOn(pantryApi, "removePantryItem")
      .mockResolvedValue(undefined);

    renderPage();

    await user.click(await screen.findByRole("button", { name: /remove egg/i }));

    // React Query v5 calls mutationFn with (variables, context), so assert on
    // the first argument rather than the whole call.
    expect(removePantryItem.mock.calls[0][0]).toBe("p1");
  });

});
