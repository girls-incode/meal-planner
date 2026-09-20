require "rails_helper"

RSpec.describe RecipeMatcher do
  let(:pantry) { create(:pantry) }

  def add_to_pantry(*ingredients)
    ingredients.each { |ingredient| create(:pantry_item, pantry:, ingredient:) }
  end

  # Mirrors what RecipeImport::Importer persists: duplicate ingredients collapse to one
  # recipe_ingredient row and the denominator counts distinct ingredients, not
  # source lines. Deriving the count from `.uniq` rather than the raw splat is
  # what lets a caller express a recipe that lists the same ingredient twice.
  def recipe_with_ingredients(*ingredients, title: "Recipe")
    ingredient_ids = ingredients.uniq.map(&:id).sort
    recipe = create(:recipe, title:, canonical_ingredient_ids: ingredient_ids, required_ingredient_count: ingredient_ids.size)
    ingredients.uniq.each { |ingredient| create(:recipe_ingredient, recipe:, ingredient:) }
    recipe
  end

  def match(ingredient_ids:, limit: RecipeMatcher::DEFAULT_LIMIT, max_missing: RecipeMatcher::DEFAULT_MAX_MISSING, cursor: nil)
    described_class.new(ingredient_ids:, limit:, max_missing:, cursor:).call.to_a.first(limit)
  end

  def cursor_for(recipe, ingredient_ids, max_missing: RecipeMatcher::DEFAULT_MAX_MISSING)
    RecipeMatchCursor.encode(recipe:, ingredient_ids:, max_missing:)
  end

  describe "#call" do
    it "continues from an opaque cursor without repeating the previous page" do
      chicken = create(:ingredient, name: "chicken")
      recipes = %w[One Two Three].map { |title| recipe_with_ingredients(chicken, title:) }
      add_to_pantry(chicken)

      first_page = match(ingredient_ids: [ chicken.id ], limit: 2)
      cursor = cursor_for(first_page.last, [ chicken.id ])
      second_page = match(ingredient_ids: [ chicken.id ], limit: 2, cursor:)

      expect(second_page.map(&:id)).not_to include(*first_page.map(&:id))
      expect((first_page + second_page).map(&:id)).to include(*recipes.map(&:id))
    end

    it "moves from complete matches to partial matches without repeating recipes" do
      chicken = create(:ingredient, name: "chicken")
      rice = create(:ingredient, name: "rice")
      soy_sauce = create(:ingredient, name: "soy sauce")
      complete_high = recipe_with_ingredients(chicken, title: "Complete high").tap { |recipe| recipe.update!(ratings: 5.0) }
      complete_middle = recipe_with_ingredients(chicken, title: "Complete middle").tap { |recipe| recipe.update!(ratings: 4.0) }
      complete_low = recipe_with_ingredients(chicken, title: "Complete low").tap { |recipe| recipe.update!(ratings: 3.0) }
      partial = recipe_with_ingredients(chicken, rice, soy_sauce, title: "Partial")

      first_page = match(ingredient_ids: [ chicken.id, rice.id ], limit: 2)
      cursor = cursor_for(first_page.last, [ chicken.id, rice.id ])
      second_page = match(ingredient_ids: [ chicken.id, rice.id ], limit: 2, cursor:)

      expect(first_page.map(&:id)).to eq([ complete_high.id, complete_middle.id ])
      expect(second_page.map(&:id)).to eq([ complete_low.id, partial.id ])
      expect((first_page + second_page).map(&:id)).to contain_exactly(
        complete_high.id, complete_middle.id, complete_low.id, partial.id
      )
    end

    it "rejects a cursor created for different search filters" do
      chicken = create(:ingredient, name: "chicken")
      beef = create(:ingredient, name: "beef")
      recipe_with_ingredients(chicken)
      add_to_pantry(chicken)
      result = match(ingredient_ids: [ chicken.id ], limit: 1)
      cursor = cursor_for(result.first, [ chicken.id ])

      expect {
        match(ingredient_ids: [ beef.id ], limit: 1, cursor:)
      }.to raise_error(Cursor::InvalidCursor)
    end

    it "returns a full match at 100% when the pantry covers every ingredient" do
      chicken = create(:ingredient, name: "chicken")
      rice = create(:ingredient, name: "rice")
      recipe = recipe_with_ingredients(chicken, rice, title: "Chicken and Rice")
      add_to_pantry(chicken, rice)

      result = described_class.new(ingredient_ids: [ chicken.id, rice.id ]).call.find { |r| r.id == recipe.id }

      expect(result.match_percentage).to eq(100.0)
      expect(result.missing_count).to eq(0)
      expect(result.matched_ingredients).to eq(2)
    end

    it "returns a partial match with the correct missing count" do
      chicken = create(:ingredient, name: "chicken")
      rice = create(:ingredient, name: "rice")
      soy_sauce = create(:ingredient, name: "soy sauce")
      recipe = recipe_with_ingredients(chicken, rice, soy_sauce, title: "Chicken Fried Rice")
      add_to_pantry(chicken, rice)

      result = described_class.new(ingredient_ids: [ chicken.id, rice.id ]).call.find { |r| r.id == recipe.id }

      expect(result.match_percentage).to eq(66.7)
      expect(result.missing_count).to eq(1)
    end

    it "reaches 100% when a recipe lists the same ingredient on more than one line" do
      flour = create(:ingredient, name: "flour")
      sugar = create(:ingredient, name: "sugar")
      butter = create(:ingredient, name: "butter")
      # "To Die For Blueberry Muffins" shape: flour and sugar each appear twice.
      recipe = recipe_with_ingredients(flour, sugar, sugar, butter, flour, title: "Muffins")
      add_to_pantry(flour, sugar, butter)

      result = described_class.new(ingredient_ids: [ flour.id, sugar.id, butter.id ]).call.find { |r| r.id == recipe.id }

      expect(result.required_ingredient_count).to eq(3)
      expect(result.matched_ingredients).to eq(3)
      expect(result.missing_count).to eq(0)
      expect(result.match_percentage).to eq(100.0)
    end

    it "does not match ingredients that merely share a word" do
      almond_flour = create(:ingredient, name: "almond flour")
      all_purpose = create(:ingredient, name: "all-purpose flour")
      recipe_with_ingredients(all_purpose, title: "Shortbread")
      add_to_pantry(almond_flour)

      expect(described_class.new(ingredient_ids: [ almond_flour.id ]).call.map(&:title)).not_to include("Shortbread")
    end

    it "excludes recipes with zero overlap with the pantry" do
      chicken = create(:ingredient, name: "chicken")
      unrelated = create(:ingredient, name: "chocolate")
      recipe_with_ingredients(unrelated, title: "Chocolate Cake")
      add_to_pantry(chicken)

      result = described_class.new(ingredient_ids: [ chicken.id ]).call

      expect(result.map(&:title)).not_to include("Chocolate Cake")
    end

    it "excludes recipes missing more ingredients than max_missing allows" do
      chicken = create(:ingredient, name: "chicken")
      a, b, c = create_list(:ingredient, 3)
      recipe = recipe_with_ingredients(chicken, a, b, c, title: "Needs Many More")
      add_to_pantry(chicken)

      result = described_class.new(ingredient_ids: [ chicken.id ], max_missing: 1).call

      expect(result.map(&:id)).not_to include(recipe.id)
    end

    it "orders equal-coverage matches by missing count and paginates without repeats" do
      available = create_list(:ingredient, 2)
      fewer_missing = recipe_with_ingredients(available.first, create(:ingredient), title: "Fewer Missing")
      more_missing = recipe_with_ingredients(*available, *create_list(:ingredient, 2), title: "More Missing")
      fewer_missing.update!(ratings: 3.5)
      more_missing.update!(ratings: 4.9)

      first_page = match(ingredient_ids: available.map(&:id), limit: 1)
      cursor = cursor_for(first_page.last, available.map(&:id))
      second_page = match(ingredient_ids: available.map(&:id), limit: 1, cursor:)

      expect(first_page.map(&:id)).to eq([ fewer_missing.id ])
      expect(second_page.map(&:id)).to eq([ more_missing.id ])
    end

    it "uses rating when coverage and missing count tie" do
      available = create(:ingredient, name: "available")
      missing = create(:ingredient, name: "missing")
      higher_rated = recipe_with_ingredients(available, missing, title: "Higher Rated")
      higher_rated.update!(ratings: 4.9)
      lower_rated = recipe_with_ingredients(available, missing, title: "Lower Rated")
      lower_rated.update!(ratings: 3.5)

      result = described_class.new(ingredient_ids: [ available.id ]).call

      expect(result.map(&:id).first(2)).to eq([ higher_rated.id, lower_rated.id ])
    end

    it "does not N+1 across a page of results" do
      chicken = create(:ingredient, name: "chicken")
      create_list(:recipe, 5, canonical_ingredient_ids: [ chicken.id ], required_ingredient_count: 1).each do |recipe|
        create(:recipe_ingredient, recipe:, ingredient: chicken)
      end
      add_to_pantry(chicken)

      query_count = count_queries { described_class.new(ingredient_ids: [ chicken.id ]).call.to_a }
      # The complete-match query is followed by one bounded partial query only
      # when the complete phase cannot prove there is no next page. This stays
      # constant as the number of returned recipes grows.
      expect(query_count).to eq(2)
    end
  end

  describe ".missing_ingredients_by_recipe" do
    it "returns only the ingredients the pantry does not already have, batched in one query" do
      chicken = create(:ingredient, name: "chicken")
      soy_sauce = create(:ingredient, name: "soy sauce")
      recipe = recipe_with_ingredients(chicken, soy_sauce, title: "Chicken Stir Fry")
      add_to_pantry(chicken)

      result = described_class.missing_ingredients_by_recipe(recipe_ids: [ recipe.id ], pantry:)

      expect(result[recipe.id].map(&:name)).to eq([ "soy sauce" ])
    end

    it "returns an empty hash for an empty recipe id list without querying" do
      expect(described_class.missing_ingredients_by_recipe(recipe_ids: [], pantry:)).to eq({})
    end
  end
end
