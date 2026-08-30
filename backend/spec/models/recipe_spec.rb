require "rails_helper"

RSpec.describe Recipe, type: :model do
  it "is valid with a title" do
    expect(build(:recipe)).to be_valid
  end

  it "is invalid without a title" do
    expect(build(:recipe, title: nil)).not_to be_valid
  end

  it "is invalid with a negative required_ingredient_count" do
    expect(build(:recipe, required_ingredient_count: -1)).not_to be_valid
  end

  it "has many recipe_ingredients and ingredients through them" do
    recipe = create(:recipe)
    ingredient = create(:ingredient)
    create(:recipe_ingredient, recipe:, ingredient:)

    expect(recipe.ingredients).to contain_exactly(ingredient)
  end

  it "optionally belongs to a category" do
    category = create(:category)

    expect(create(:recipe, category:).category).to eq(category)
    expect(build(:recipe, category: nil)).to be_valid
  end

  it "optionally belongs to an author" do
    author = create(:author)

    expect(create(:recipe, author:).author).to eq(author)
    expect(build(:recipe, author: nil)).to be_valid
  end

  it "destroys its recipe_ingredients when destroyed" do
    recipe = create(:recipe)
    create(:recipe_ingredient, recipe:)

    expect { recipe.destroy! }.to change(RecipeIngredient, :count).by(-1)
  end
end
