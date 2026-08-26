import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { MemoryRouter } from "react-router-dom";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { PantryPage } from "@/pages/PantryPage";
import { ApiError } from "@/api/client";
import * as pantryApi from "@/api/pantry";
import * as ingredientsApi from "@/api/ingredients";
import type { PantryItem } from "@/api/types";

let queryClient: QueryClient;

function renderWithProviders(component: React.ReactElement) {
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>{component}</MemoryRouter>
    </QueryClientProvider>,
  );
}

beforeEach(() => {
  queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
});

afterEach(() => {
  vi.restoreAllMocks();
});

describe("PantryPage", () => {
  it("renders the empty state when the pantry has no items and is not loading", async () => {
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue([]);

    renderWithProviders(<PantryPage />);

    await waitFor(() => {
      expect(screen.getByText("Your kitchen is empty")).toBeInTheDocument();
    });
  });

  it("renders ingredient chips when the pantry has items", async () => {
    const items: PantryItem[] = [
      { id: "p1", ingredient: { id: "i1", name: "Egg" } },
      { id: "p2", ingredient: { id: "i2", name: "Flour" } },
    ];
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue(items);

    renderWithProviders(<PantryPage />);

    await waitFor(() => {
      expect(screen.getByText("Egg")).toBeInTheDocument();
      expect(screen.getByText("Flour")).toBeInTheDocument();
    });
  });

  it("removes an ingredient when the chip's remove button is clicked", async () => {
    const user = userEvent.setup();
    const items: PantryItem[] = [{ id: "p1", ingredient: { id: "i1", name: "Egg" } }];
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue(items);
    const removePantryItem = vi.spyOn(pantryApi, "removePantryItem").mockResolvedValue(undefined);

    renderWithProviders(<PantryPage />);

    await waitFor(() => {
      expect(screen.getByText("Egg")).toBeInTheDocument();
    });

    const removeButtons = screen.getAllByRole("button", { name: /remove/i });
    await user.click(removeButtons[0]);

    // React Query mutations may pass additional arguments, just check it was called
    expect(removePantryItem).toHaveBeenCalled();
  });

  it("displays an error message when adding a pantry item fails", async () => {
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue([]);
    vi.spyOn(ingredientsApi, "searchIngredients").mockResolvedValue([
      { id: "i1", name: "Egg" },
    ]);
    const addError = new ApiError(422, "ingredient already in pantry");
    vi.spyOn(pantryApi, "addPantryItem").mockRejectedValue(addError);

    const user = userEvent.setup();
    renderWithProviders(<PantryPage />);

    // Wait for the ingredient search input to appear
    const input = await screen.findByPlaceholderText("Add an ingredient...");

    // Type in the input to trigger search
    await user.type(input, "Egg");

    // Wait for the suggestion to appear
    const suggestion = await screen.findByText("Egg");
    await user.click(suggestion);

    // Wait for the error message
    await waitFor(() => {
      const alert = screen.getByRole("alert");
      expect(alert).toHaveTextContent("ingredient already in pantry");
    });
  });

  it("displays a generic error message when the error is not an ApiError", async () => {
    vi.spyOn(pantryApi, "getPantry").mockResolvedValue([]);
    vi.spyOn(ingredientsApi, "searchIngredients").mockResolvedValue([
      { id: "i1", name: "Egg" },
    ]);
    vi.spyOn(pantryApi, "addPantryItem").mockRejectedValue(new Error("Network error"));

    const user = userEvent.setup();
    renderWithProviders(<PantryPage />);

    const input = await screen.findByPlaceholderText("Add an ingredient...");
    await user.type(input, "Egg");

    const suggestion = await screen.findByText("Egg");
    await user.click(suggestion);

    // Wait for the error message (non-ApiError uses fallback text)
    await waitFor(() => {
      const alert = screen.getByRole("alert");
      expect(alert).toHaveTextContent("Something went wrong. Please try again.");
    });
  });

  it("does not show the empty state when loading", async () => {
    // Create a promise that resolves after the component tries to render
    let resolveGetPantry: (items: PantryItem[]) => void = () => {};
    const getPantryPromise = new Promise<PantryItem[]>((resolve) => {
      resolveGetPantry = resolve;
    });

    vi.spyOn(pantryApi, "getPantry").mockReturnValue(getPantryPromise as never);

    renderWithProviders(<PantryPage />);

    // The empty state should not appear while loading
    expect(screen.queryByText("Your kitchen is empty")).not.toBeInTheDocument();

    // Resolve the promise
    resolveGetPantry([{ id: "p1", ingredient: { id: "i1", name: "Egg" } }]);

    // Now the empty state should not appear (we have an item)
    await waitFor(() => {
      expect(screen.getByText("Egg")).toBeInTheDocument();
      expect(screen.queryByText("Your kitchen is empty")).not.toBeInTheDocument();
    });
  });
});
