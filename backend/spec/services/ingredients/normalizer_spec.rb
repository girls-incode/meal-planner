require "rails_helper"

RSpec.describe Ingredients::Normalizer do
  describe ".call" do
    {
      # plain names pass through unchanged
      "sugar" => "sugar",
      "egg" => "egg",

      # case and whitespace
      "  All-Purpose   Flour " => "all-purpose flour",

      # leading prep/cosmetic descriptors, including ones the unit regex
      # doesn't catch (containers, sprigs, packets, servings, sizes)
      "chopped fresh spinach" => "spinach",
      "fresh ground beef" => "ground beef",
      "large onion" => "onion",
      "medium onions" => "onions",
      "stalk celery" => "celery",
      "bag frozen peas" => "frozen peas",
      "sprigs cilantro" => "cilantro",
      "packets dry brown gravy mix" => "dry brown gravy mix",
      "serving cooking spray" => "cooking spray",

      # a leading segment of pure descriptors is dropped, not mistaken for the
      # ingredient — cutting at the first comma would yield "skinless" and
      # merge chicken breast with chicken thigh
      "skinless, boneless chicken thighs" => "chicken thighs",
      "skinless, boneless chicken breast halves, pounded to an even thickness" => "chicken breast halves",

      # trailing prep/serving notes after a comma or " - "
      "persian cucumbers, sliced" => "persian cucumbers",
      "orange, juiced and zested" => "orange",
      "celery rib, finely diced" => "celery rib",
      "delicata squash - ends trimmed, halved lengthwise, seeded" => "delicata squash",
      "olive oil, plus more for brushing" => "olive oil",

      # trailing qualifiers with no comma
      "salt and ground black pepper to taste" => "salt and ground black pepper",
      "ground ginger, or to taste" => "ginger",

      # parentheticals anywhere, plus trademark symbols
      "frozen boneless turkey breast (such as butterball®)" => "frozen boneless turkey breast",
      "processed cheese food (such as Velveeta®), cut into 1 1/2-inch chunks" => "processed cheese food",

      # Fat/health percentages are stripped as product descriptors, not ingredient names
      "100% pure pumpkin" => "pure pumpkin",       # Package-quality claim, stripped
      "libby's 100% pure pumpkin" => "libby's pure pumpkin",
      "10% cream" => "cream",                       # Fat percentage, stripped
      "2% milk" => "milk",                          # Fat percentage, stripped
      "35% cream" => "cream",                       # Fat percentage, stripped
      "1% buttermilk" => "buttermilk",              # Fat percentage, stripped
      "25%-less-sodium chicken broth" => "chicken broth",  # Health descriptor, stripped
      "1/3-less-fat cream cheese" => "cream cheese",       # Fraction descriptor, stripped
      "20%-reduced-sugar jam" => "jam",                    # Other degree/attribute combo, stripped
      "1/2-low-calorie soda" => "soda",                    # Fraction, other degree/attribute, stripped
      "less-fat milk" => "less-fat milk",                  # No leading number, left untouched
      "2 inch thick ham steak" => "ham steak",      # Size descriptor, stripped
      "1/2-inch thick pork chops" => "pork chops",  # Size descriptor, stripped
      "8- to 10-inch flour tortillas" => "flour tortillas", # Size range, stripped
      "2x3 inch brownies" => "brownies",            # Dimension-style size, stripped
      "5 grain crackers" => "crackers",             # Grain size unit, stripped
      "3 cm ginger" => "ginger",                    # Metric size unit, stripped
      "10 mm cucumber" => "cucumber",               # Metric size unit, stripped
      "93%-lean ground beef" => "ground beef",      # Lean percentage, stripped
      "93% lean ground beef" => "ground beef",      # Lean percentage with space, stripped
      "93%-extra-lean ground beef" => "ground beef", # Extra-lean percentage, stripped
      "reduced-fat cheese" => "cheese",             # Leading reduced-fat descriptor, stripped
      "low fat yogurt" => "yogurt",                 # Leading low fat descriptor, stripped
      "reduced fat sour cream" => "sour cream",     # Leading reduced fat descriptor, stripped
      "shredded reduced-fat cheddar cheese" => "cheddar cheese", # Fat claim exposed after prep cleanup
      "1/2 cup sugar" => "sugar",                   # Fraction quantity + unit, stripped
      "3 tbsp olive oil" => "olive oil",            # Quantity + unit, stripped
      "2 stalks celery" => "celery",                # Count unit, stripped
      "2 stalks celery, chopped" => "celery",       # Repeated count unit, stripped
      "shredded 2% milk cheddar cheese" => "milk cheddar cheese", # Descriptor then percentage
      "11⁄16 cups warm water" => "warm water",      # Fraction slash, stripped
      "⁄16 cups warm water" => "warm water",        # Unicode fraction, stripped
      "⁄16 cup toasted pecans" => "toasted pecans", # Unicode fraction, stripped
      "1.5 cups flour" => "flour",                  # Decimal quantity, stripped
      "1 1/2 cups flour" => "flour",                # Mixed number quantity, stripped
      "3 cloves garlic" => "garlic",                # Count unit (cloves), stripped
      "2 cans black beans" => "black beans",        # Count unit (cans), stripped
      "4 sheets phyllo dough" => "phyllo dough",    # Count unit (sheets), stripped
      "2 pinches salt" => "salt",                   # Count unit (pinches), stripped
      "cups sugar" => "cups sugar",                 # No leading quantity, left untouched

      # blank/nil input never raises
      "" => "",
      nil => ""
    }.each do |raw_name, expected|
      it "normalizes #{raw_name.inspect} to #{expected.inspect}" do
        expect(described_class.call(raw_name)).to eq(expected)
      end
    end
  end
end
