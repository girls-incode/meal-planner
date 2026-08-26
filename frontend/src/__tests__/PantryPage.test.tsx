import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { PantryPage } from "@/pages/PantryPage";
import { ApiError } from "@/api/client";
import * as pantryApi from "@/api/pantry";
import * as ingredientsApi from "@/api/ingredients";
import { makeIngredients, makePantry, makePantryItem } from "@/test/factories";
import { renderWithProviders } from "@/test/render";

function renderPage() {
  return renderWithProviders(<PantryPage />);
}

/** Types into the search box and picks the named suggestion. */
async function addIngredient(user: ReturnType<typeof userEvent.setup>, name: string) {
  await user.type(screen.getByPlaceholderText("Add an ingredient..."), name);
  await user.click(await screen.findByRole("button", { name }));
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

  it("displays the API error message when adding a pantry item fails", async () => {
    const user = userEvent.setup();
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue([]);
    vi.spyOn(ingredientsApi, "searchIngredients").mockResolvedValue(makeIngredients("Egg"));
    vi.spyOn(pantryApi, "addPantryItem").mockRejectedValue(
      new ApiError(422, "ingredient already in pantry"),
    );

    renderPage();
    await addIngredient(user, "Egg");

    await waitFor(() => {
      expect(screen.getByRole("alert")).toHaveTextContent("ingredient already in pantry");
    });
  });

  it("displays a generic message when the failure is not an ApiError", async () => {
    const user = userEvent.setup();
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue([]);
    vi.spyOn(ingredientsApi, "searchIngredients").mockResolvedValue(makeIngredients("Egg"));
    vi.spyOn(pantryApi, "addPantryItem").mockRejectedValue(new Error("Network error"));

    renderPage();
    await addIngredient(user, "Egg");

    await waitFor(() => {
      expect(screen.getByRole("alert")).toHaveTextContent(
        "Something went wrong. Please try again.",
      );
    });
  });

  it("adds the selected ingredient to the pantry", async () => {
    const user = userEvent.setup();
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue([]);
    vi.spyOn(ingredientsApi, "searchIngredients").mockResolvedValue(makeIngredients("Egg"));
    const addPantryItem = vi
      .spyOn(pantryApi, "addPantryItem")
      .mockResolvedValue(makePantryItem());

    renderPage();
    await addIngredient(user, "Egg");

    expect(addPantryItem.mock.calls[0][0]).toBe("i1");
  });
});
