require "rails_helper"

RSpec.describe RecipeIngredients::Replace do
  def row(recipe, ingredient, raw_text: "1 #{ingredient.name}")
    { recipe_id: recipe.id, ingredient_id: ingredient.id, raw_text: }
  end

  it "replaces normalized rows and the searchable projection atomically" do
    recipe = create(:recipe)
    chicken = create(:ingredient, name: "chicken")
    rice = create(:ingredient, name: "rice")

    described_class.call(rows_by_recipe_id: { recipe.id => [ row(recipe, rice), row(recipe, chicken) ] })

    expect(recipe.reload).to have_attributes(
      canonical_ingredient_ids: [ chicken.id, rice.id ].sort,
      required_ingredient_count: 2
    )
    expect(recipe.recipe_ingredients.pluck(:ingredient_id)).to contain_exactly(chicken.id, rice.id)
  end

  it "rejects duplicate canonical ingredient IDs before changing the recipe" do
    recipe = create(:recipe)
    chicken = create(:ingredient, name: "chicken")

    expect {
      described_class.call(rows_by_recipe_id: { recipe.id => [ row(recipe, chicken), row(recipe, chicken) ] })
    }.to raise_error(RecipeIngredients::Replace::DuplicateIngredient)

    expect(recipe.reload).to have_attributes(canonical_ingredient_ids: [], required_ingredient_count: 0)
    expect(recipe.recipe_ingredients).to be_empty
  end

  it "rejects rows assigned to a different recipe" do
    recipe = create(:recipe)
    other_recipe = create(:recipe)
    chicken = create(:ingredient, name: "chicken")

    expect {
      described_class.call(rows_by_recipe_id: { recipe.id => [ row(other_recipe, chicken) ] })
    }.to raise_error(ArgumentError, "recipe ingredient row belongs to another recipe")

    expect(recipe.reload).to have_attributes(canonical_ingredient_ids: [], required_ingredient_count: 0)
    expect(recipe.recipe_ingredients).to be_empty
  end

  it "rolls back replaced rows and the projection when an insert fails" do
    recipe = create(:recipe)
    chicken = create(:ingredient, name: "chicken")
    rice = create(:ingredient, name: "rice")
    described_class.call(rows_by_recipe_id: { recipe.id => [ row(recipe, chicken) ] })

    expect {
      described_class.call(rows_by_recipe_id: { recipe.id => [ row(recipe, rice, raw_text: nil) ] })
    }.to raise_error(ActiveRecord::NotNullViolation)

    expect(recipe.reload).to have_attributes(canonical_ingredient_ids: [ chicken.id ], required_ingredient_count: 1)
    expect(recipe.recipe_ingredients.pluck(:ingredient_id)).to eq([ chicken.id ])
  end
end
