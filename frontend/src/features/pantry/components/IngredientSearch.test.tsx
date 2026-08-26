import { screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { IngredientSearch } from "@/features/pantry/components/IngredientSearch";
import * as ingredientsApi from "@/features/pantry/api/ingredients";
import { makeIngredients } from "@/test/factories";
import { renderWithProviders } from "@/test/render";

function renderSearch(props: Partial<React.ComponentProps<typeof IngredientSearch>> = {}) {
  const onAdd = props.onAdd ?? vi.fn();
  renderWithProviders(<IngredientSearch onAdd={onAdd} excludeIds={props.excludeIds ?? []} />);
  return { onAdd, user: userEvent.setup() };
}

function input() {
  return screen.getByPlaceholderText("Add an ingredient...") as HTMLInputElement;
}

describe("IngredientSearch", () => {
  it("shows no suggestion list until the user types", () => {
    vi.spyOn(ingredientsApi, "searchIngredients").mockResolvedValue([]);

    renderSearch();

    expect(screen.queryByRole("list")).not.toBeInTheDocument();
  });

  it("shows matching suggestions for the typed query", async () => {
    vi.spyOn(ingredientsApi, "searchIngredients").mockResolvedValue(makeIngredients("Egg"));

    const { user } = renderSearch();
    await user.type(input(), "egg");

    expect(await screen.findByRole("button", { name: "Egg" })).toBeInTheDocument();
  });

  it("tells the user when nothing matches", async () => {
    vi.spyOn(ingredientsApi, "searchIngredients").mockResolvedValue([]);

    const { user } = renderSearch();
    await user.type(input(), "zzz");

    expect(await screen.findByText("No ingredients found")).toBeInTheDocument();
  });

  it("calls onAdd with the selected ingredient and clears the input", async () => {
    const ingredients = makeIngredients("Egg");
    vi.spyOn(ingredientsApi, "searchIngredients").mockResolvedValue(ingredients);

    const { onAdd, user } = renderSearch();
    await user.type(input(), "egg");
    await user.click(await screen.findByRole("button", { name: "Egg" }));

    expect(onAdd).toHaveBeenCalledWith(ingredients[0]);
    expect(input().value).toBe("");
  });

  it("hides ingredients listed in excludeIds", async () => {
    // makeIngredients assigns ids i1 and i2 in order.
    vi.spyOn(ingredientsApi, "searchIngredients").mockResolvedValue(
      makeIngredients("Egg", "Egg White"),
    );

    const { user } = renderSearch({ excludeIds: ["i2"] });
    await user.type(input(), "egg");

    expect(await screen.findByRole("button", { name: "Egg" })).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "Egg White" })).not.toBeInTheDocument();
  });
});
