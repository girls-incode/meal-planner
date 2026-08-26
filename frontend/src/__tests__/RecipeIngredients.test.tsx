import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { RecipeIngredients } from "@/components/RecipeIngredients";
import { makeIngredient } from "@/test/factories";

describe("RecipeIngredients", () => {
  it("renders available recipe lines and missing ingredient names with distinct styles", () => {
    render(
      <RecipeIngredients
        ingredients={[
          {
            ingredient: makeIngredient({ id: "i1", name: "Chicken" }),
            rawText: "1 lb chicken breast, diced",
            owned: true,
          },
          {
            ingredient: makeIngredient({ id: "i2", name: "Soy Sauce" }),
            rawText: "3 tbsp soy sauce",
            owned: false,
          },
        ]}
        missingIngredients={[makeIngredient({ id: "i2", name: "Soy Sauce" })]}
      />,
    );

    expect(screen.getByText("1 lb chicken breast, diced")).toHaveClass("text-foreground");
    expect(screen.getByText("Soy Sauce")).toHaveClass("text-muted-foreground");
    expect(screen.queryByText("3 tbsp soy sauce")).not.toBeInTheDocument();
  });

  it("keeps available ingredients first and preserves each group's order", () => {
    render(
      <RecipeIngredients
        ingredients={[
          {
            ingredient: makeIngredient({ id: "i1", name: "Chicken" }),
            rawText: "1 lb chicken breast, diced",
            owned: true,
          },
          {
            ingredient: makeIngredient({ id: "i2", name: "Rice" }),
            rawText: "2 cups cooked rice",
            owned: true,
          },
        ]}
        missingIngredients={[
          makeIngredient({ id: "i3", name: "Soy Sauce" }),
          makeIngredient({ id: "i4", name: "Sesame Oil" }),
        ]}
      />,
    );

    const rendered = screen.getAllByRole("listitem").map((item) => item.textContent);

    expect(rendered).toEqual([
      "1 lb chicken breast, diced",
      "2 cups cooked rice",
      "Soy Sauce",
      "Sesame Oil",
    ]);
  });
});
