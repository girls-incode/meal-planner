class AddRatingsRangeCheckToRecipes < ActiveRecord::Migration[8.1]
  def change
    # RecipeMatchCursor and RecipeMatcher substitute a sentinel value for a
    # NULL rating so pagination can compare `ratings` as a plain, always-
    # present number instead of special-casing NULL. That substitution is
    # only sound if a real rating can never be negative; this constraint
    # makes that guarantee explicit at the database level instead of leaving
    # it as an assumption the application code quietly depends on.
    add_check_constraint :recipes, "ratings IS NULL OR ratings >= 0", name: "ratings_non_negative"
  end
end
