import type {
  Ingredient,
  PantryItem,
  RecipeDetail,
  RecipeMatch,
  RecipeMatchesPage,
} from "@/api/types";

/**
 * Fixture builders for tests. Each takes partial overrides so a test only
 * spells out the fields it actually cares about.
 */

export function makeIngredient(overrides: Partial<Ingredient> = {}): Ingredient {
  return { id: "i1", name: "Egg", ...overrides };
}

/** `makeIngredients("Egg", "Milk")` → two ingredients with ids i1, i2. */
export function makeIngredients(...names: string[]): Ingredient[] {
  return names.map((name, index) => makeIngredient({ id: `i${index + 1}`, name }));
}

export function makePantryItem(overrides: Partial<PantryItem> = {}): PantryItem {
  return { id: "p1", ingredient: makeIngredient(), ...overrides };
}

/** `makePantry("Egg", "Flour")` → pantry items p1/p2 holding ingredients i1/i2. */
export function makePantry(...names: string[]): PantryItem[] {
  return names.map((name, index) =>
    makePantryItem({
      id: `p${index + 1}`,
      ingredient: makeIngredient({ id: `i${index + 1}`, name }),
    }),
  );
}

export function makeRecipeMatch(overrides: Partial<RecipeMatch> = {}): RecipeMatch {
  return {
    id: "r1",
    title: "Golden Sweet Cornbread",
    imageUrl: null,
    ratings: 4.7,
    cookTimeMinutes: 25,
    prepTimeMinutes: 10,
    matchedIngredients: 8,
    requiredIngredientCount: 8,
    missingCount: 0,
    matchPercentage: 100,
    missingIngredients: [],
    cuisine: "Asian",
    category: { id: "category-1", name: "Dinner" },
    author: { id: "author-1", name: "Chef Bob" },
    ...overrides,
  };
}

export function makeRecipeDetail(overrides: Partial<RecipeDetail> = {}): RecipeDetail {
  return {
    id: "r1",
    title: "Chicken Fried Rice",
    imageUrl: null,
    ratings: 4.5,
    cookTimeMinutes: 20,
    prepTimeMinutes: 10,
    matchedIngredients: 5,
    requiredIngredientCount: 5,
    missingCount: 0,
    matchPercentage: 100,
    missingIngredients: [],
    cuisine: "Asian",
    category: { id: "category-1", name: "Dinner" },
    author: "Chef Bob",
    ingredients: [],
    ...overrides,
  };
}

/** The cursor-paginated envelope returned by POST /api/v1/recipes/matches. */
export function makeMatchesPage(
  data: RecipeMatch[] = [makeRecipeMatch()],
  nextCursor: string | null = null,
): RecipeMatchesPage {
  return { data, nextCursor };
}
