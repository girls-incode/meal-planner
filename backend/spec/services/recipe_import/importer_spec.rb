require "rails_helper"
require "tempfile"
require "stringio"

RSpec.describe RecipeImport::Importer do
  def with_fixture_file(recipes)
    file = Tempfile.new([ "recipes", ".json" ])
    file.write(recipes.to_json)
    file.close
    yield file.path
  ensure
    file.unlink
  end

  it "imports a recipe with its ingredients, quantities, and units" do
    recipes = [
      {
        "title" => "Golden Sweet Cornbread",
        "cook_time" => 25,
        "prep_time" => 10,
        "ingredients" => [ "1 cup all-purpose flour", "1 egg" ],
        "ratings" => 4.74,
        "cuisine" => "",
        "category" => "Cornbread",
        "author" => "bluegirl",
        "image" => "https://example.com/cornbread.jpg"
      }
    ]

    with_fixture_file(recipes) { |path| described_class.new(file: path).call }

    recipe = Recipe.find_by!(title: "Golden Sweet Cornbread")
    expect(recipe.category).to have_attributes(name: "Cornbread")
    expect(recipe.author).to have_attributes(name: "bluegirl")
    expect(recipe.required_ingredient_count).to eq(2)
    expect(recipe.canonical_ingredient_ids).to eq(recipe.ingredients.pluck(:id).sort)
    expect(recipe.cook_time_minutes).to eq(25)
    expect(recipe.ingredients.map(&:name)).to contain_exactly("all-purpose flour", "egg")

    flour_line = recipe.recipe_ingredients.joins(:ingredient).find_by(ingredients: { name: "all-purpose flour" })
    expect(flour_line.quantity).to eq(1)
    expect(flour_line.unit).to eq("cup")
  end

  it "persists structured ingredient line attributes and import metadata" do
    recipes = [
      {
        "title" => "Structured Bread",
        "ingredients" => [ "3 cups bread flour, divided, or as needed", "1 cup diced tomato" ]
      }
    ]

    with_fixture_file(recipes) { |path| described_class.new(file: path).call }

    recipe = Recipe.find_by!(title: "Structured Bread")
    flour = recipe.recipe_ingredients.joins(:ingredient).find_by(ingredients: { name: "bread flour" })
    tomato = recipe.recipe_ingredients.joins(:ingredient).find_by(ingredients: { name: "tomato" })

    expect([ flour.quantity.to_f, flour.unit, flour.preparation, flour.qualifier, flour.raw_text ])
      .to eq([ 3.0, "cup", nil, "divided, or as needed", "3 cups bread flour, divided, or as needed" ])
    expect([ tomato.quantity.to_f, tomato.unit, tomato.preparation ]).to eq([ 1.0, "cup", "diced" ])
    expect(ImportRun.where(status: "completed").order(:created_at).last.parser_version).to eq(described_class::PARSER_VERSION)
    expect(recipe.recipe_ingredients.pluck(:ingredient_id)).to contain_exactly(flour.ingredient_id, tomato.ingredient_id)
  end

  it "strips a parenthetical comment that follows the unit, not just one that precedes it" do
    recipes = [
      {
        "title" => "Pork Chops",
        "ingredients" => [ "1 pound (1/2-inch thick) pork chops", "3 (12 ounce) packages cream cheese" ]
      }
    ]

    with_fixture_file(recipes) { |path| described_class.new(file: path).call }

    expect(Recipe.find_by!(title: "Pork Chops").ingredients.map(&:name))
      .to contain_exactly("pork chops", "cream cheese")
  end

  it "normalizes messy scraped ingredient text without relying on the alias dictionary" do
    recipes = [
      {
        "title" => "Messy Text Recipe",
        "ingredients" => [
          "1 can 100% pure pumpkin",
          "2 persian cucumbers, sliced",
          "1 orange, juiced and zested",
          "1 pound frozen boneless turkey breast (such as butterball®)",
          "1 stalk celery rib, finely diced",
          "1 delicata squash - ends trimmed, halved lengthwise, seeded"
        ]
      }
    ]

    with_fixture_file(recipes) { |path| described_class.new(file: path).call }

    expect(Recipe.find_by!(title: "Messy Text Recipe").ingredients.map(&:name)).to contain_exactly(
      "pure pumpkin",
      "persian cucumbers",
      "orange",
      "frozen boneless turkey breast",
      "celery rib",
      "delicata squash"
    )
  end

  describe "required_ingredient_count" do
    it "counts distinct canonical ingredients, not source lines" do
      recipes = [
        {
          "title" => "Muffins",
          "ingredients" => [
            "1 ½ cups all-purpose flour",
            "¾ cup white sugar",
            "½ cup white sugar",
            "⅓ cup all-purpose flour",
            "¼ cup butter"
          ]
        }
      ]

      with_fixture_file(recipes) { |path| described_class.new(file: path).call }

      recipe = Recipe.find_by!(title: "Muffins")
      expect(recipe.ingredients.map(&:name)).to contain_exactly("all-purpose flour", "white sugar", "butter")
      # Five lines, three distinct ingredients. Counting lines would leave this
      # recipe permanently unable to reach a 100% match.
      expect(recipe.required_ingredient_count).to eq(3)
    end

    it "excludes lines that could not be imported" do
      recipes = [ { "title" => "Partly Broken", "ingredients" => [ "1 egg", nil ] } ]

      with_fixture_file(recipes) { |path| described_class.new(file: path).call }

      expect(Recipe.find_by!(title: "Partly Broken").required_ingredient_count).to eq(1)
    end
  end

  describe "compound ingredient lines" do
    it "splits the salt and pepper family into two ingredients" do
      recipes = [
        # Evidence that both halves are ingredients in their own right. In the
        # real file this is overwhelming: bare "salt" appears 3,255 times and
        # "black pepper" 1,349.
        { "title" => "Evidence", "ingredients" => [ "1 teaspoon salt", "1 teaspoon ground black pepper" ] },
        {
          "title" => "Seasoned",
          "ingredients" => [
            "salt and ground black pepper to taste",
            "1 pinch salt and ground black pepper to taste",
            "salt and freshly ground black pepper to taste"
          ]
        }
      ]

      with_fixture_file(recipes) { |path| described_class.new(file: path).call }

      recipe = Recipe.find_by!(title: "Seasoned")
      expect(recipe.ingredients.map(&:name)).to contain_exactly("salt", "black pepper")
      expect(recipe.required_ingredient_count).to eq(2)
      expect(Ingredient.where("name LIKE ?", "salt and%")).to be_empty
    end

    it "leaves a compound line intact when the corpus gives no evidence for its halves" do
      recipes = [ { "title" => "No Evidence", "ingredients" => [ "salt and ground black pepper to taste" ] } ]

      with_fixture_file(recipes) { |path| described_class.new(file: path).call }

      # Neither "salt" nor "black pepper" appears alone anywhere, so the split
      # is not inferred. Splitting on the word "and" alone would be a guess.
      expect(Recipe.find_by!(title: "No Evidence").ingredients.map(&:name))
        .to contain_exactly("salt and ground black pepper")
    end

    it "keeps single products that merely contain the word 'and' intact" do
      recipes = [
        {
          "title" => "Not Compound",
          "ingredients" => [ "2 teaspoons garlic and herb seasoning", "1 cup american and cheddar cheese blend" ]
        }
      ]

      with_fixture_file(recipes) { |path| described_class.new(file: path).call }

      expect(Recipe.find_by!(title: "Not Compound").ingredients.map(&:name))
        .to contain_exactly("garlic and herb seasoning", "american and cheddar cheese blend")
    end
  end

  it "keeps ingredients that share a head noun distinct" do
    recipes = [
      { "title" => "Recipe A", "ingredients" => [ "1 cup almond flour", "1 cup coconut milk" ] },
      { "title" => "Recipe B", "ingredients" => [ "1 cup all-purpose flour", "1 cup milk" ] }
    ]

    with_fixture_file(recipes) { |path| described_class.new(file: path).call }

    # Folding "almond flour" into "flour" would tell someone with almond flour
    # they can bake bread. The importer never merges one ingredient into another.
    expect(Ingredient.pluck(:name))
      .to contain_exactly("almond flour", "coconut milk", "all-purpose flour", "milk")
  end

  it "is idempotent — re-running does not create duplicate recipes or ingredients" do
    recipes = [ { "title" => "Golden Sweet Cornbread", "category" => "Bread", "ingredients" => [ "1 egg" ] } ]

    with_fixture_file(recipes) { |path| described_class.new(file: path).call }
    with_fixture_file(recipes) { |path| described_class.new(file: path).call }

    expect(Recipe.where(title: "Golden Sweet Cornbread").count).to eq(1)
    expect(Ingredient.where(name: "egg").count).to eq(1)
    expect(Category.where(name: "Bread").count).to eq(1)
  end

  it "rebuilds existing recipe joins when normalization changes" do
    recipes = [ { "title" => "Celery Soup", "ingredients" => [ "2 stalks celery" ] } ]

    with_fixture_file(recipes) do |path|
      described_class.new(file: path).call
      recipe = Recipe.find_by!(title: "Celery Soup")
      legacy_ingredient = create(:ingredient, name: "2 stalks celery")
      create(:recipe_ingredient, recipe:, ingredient: legacy_ingredient, raw_text: "2 stalks celery")

      described_class.new(file: path).call
    end

    expect(Recipe.find_by!(title: "Celery Soup").ingredients.pluck(:name)).to eq([ "celery" ])
  end

  it "does not put quantities, units, or percentage prefixes in the catalog" do
    recipes = [
      {
        "title" => "Clean Catalog",
        "ingredients" => [ "2 stalks celery", "2% milk cheddar cheese", "8- to 10-inch flour tortillas" ]
      }
    ]

    with_fixture_file(recipes) { |path| described_class.new(file: path).call }

    expect(Recipe.find_by!(title: "Clean Catalog").ingredients.pluck(:name))
      .to contain_exactly("celery", "milk cheddar cheese", "flour tortillas")
  end

  it "skips unparseable ingredient lines without failing the whole recipe" do
    recipes = [ { "title" => "Recipe C", "ingredients" => [ "1 egg", nil ] } ]

    with_fixture_file(recipes) { |path| expect { described_class.new(file: path).call }.not_to raise_error }

    expect(Recipe.find_by!(title: "Recipe C").ingredients.map(&:name)).to include("egg")
    error = IngredientParseError.order(:created_at).last
    expect([ error.recipe.title, error.original_text, error.parser_version, error.error ])
      .to eq([ "Recipe C", "", described_class::PARSER_VERSION, "ingredient line is blank" ])
  end

  it "reads the source once and reuses it for both the catalog and persistence passes" do
    payload = [ { "title" => "Streamed", "ingredients" => [ "1 egg" ] } ].to_json
    openings = 0
    io_factory = lambda do |&block|
      openings += 1
      StringIO.new(payload).then(&block)
    end

    described_class.new(source_url: "https://example.test/recipes.json.gz", source_fingerprint: "fixture", io_factory:).call

    expect(openings).to eq(1)
    expect(Recipe.find_by!(title: "Streamed").ingredients.pluck(:name)).to eq([ "egg" ])
  end

  it "rejects a source that exceeds the in-memory limit" do
    stub_const("RecipeImport::Importer::MAX_SOURCE_BYTES", 5)
    io_factory = ->(&block) { StringIO.new("123456").then(&block) }

    expect {
      described_class.new(source_url: "https://example.test/recipes.json.gz", source_fingerprint: "fixture", io_factory:).call
    }.to raise_error(ArgumentError, "source exceeds 5 bytes")
  end
end
