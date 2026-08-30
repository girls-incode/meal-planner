# typed: true
# frozen_string_literal: true

require "set"

module Ingredients
  # Deterministic, syntactic normalization only. It deliberately never maps
  # one food to a different food: matching aliases and substitutions belong to
  # explicit reviewed policies.
  class Normalizer
    extend T::Sig
    LEADING_DESCRIPTORS = %w[
      fresh chopped sliced minced diced ground crushed grated shredded
      packed large small medium thin thinly thick roughly coarsely finely
      freshly lightly firmly evenly stalk stalks bag bags bottle bottles jar
      jars box boxes container containers bunch bunches head heads slice
      slices piece pieces sprig sprigs packet packets serving servings skinless
      boneless
    ].freeze
    GROUND_MEATS = %w[beef turkey chicken pork lamb veal].freeze
    SEGMENT_DESCRIPTORS = (LEADING_DESCRIPTORS + %w[
      bone-in skin-on peeled unpeeled seeded pitted cored halved quartered
      trimmed cubed softened melted beaten sifted drained rinsed cooked
      uncooked raw frozen thawed dried divided optional
    ]).to_set.freeze
    SEGMENT_SEPARATOR = /\s*(?:,| - )\s*/.freeze
    TRAILING_QUALIFIER = /\s+(?:or\s+more\s+)?(?:to\s+taste|as\s+needed|if\s+desired)\z/.freeze

    sig { params(value: T.untyped).returns(String) }
    def self.call(value)
      new.call(value)
    end

    sig { params(value: T.untyped).returns(String) }
    def call(value)
      name = value.to_s.downcase.strip
      name = name.gsub(/\([^)]*\)/, " ").gsub(/[®™]/, "")
      name = name.sub(/\A[\d\s.\/x½⅓⅔¼¾⅕⅙⅛⅜⅝⅞⁄]+(?:\s*-\s*to\s*[\d\s.\/x½⅓⅔¼¾⅕⅙⅛⅜⅝⅞⁄]+)?\s*-?(?:inch(?:es)?|grain|cm|mm)\b[\s\-]*(?:cut|diced|cubed|thick|thin|long|wide|sliced|pieces?|chunks?|strips?|whole)?\s+/, "").strip
      name = name.sub(/\A[\d.\/⁄\s½⅓⅔¼¾⅕⅙⅛⅜⅝⅞]+\s*(?:grams?|g|kg|mg|ml|l|ounces?|oz|pounds?|lbs?|cups?|tablespoons?|tbsp|teaspoons?|tsp|pinches?|dashes?|drops?|spears?|stalks?|bunches?|sprigs?|leaves?|sheets?|slices?|heads?|pieces?|cloves?|cans?|packages?|packs?|boxes?|bags?|bottles?|jars?|wrappers?|each|whole)\s+/, "").strip
      name = name.sub(/\A[⁄\/]+[\d\s.]*(?:cups?|tablespoons?|tbsp|teaspoons?|tsp|ounces?|oz|pounds?|lbs?|ml|grams?)\s+/, "").strip
      name = name.sub(/\A\d+%-(?:less|reduced|low)-(?:fat|sodium|sugar|calorie)\s+/, "").strip
      name = name.sub(/\A[\d\/]+\s*-(?:less|reduced|low)-(?:fat|sodium|sugar|calorie)\s+/, "").strip
      name = remove_percentage_descriptors(name)
      name = ingredient_segment(name).sub(TRAILING_QUALIFIER, "").squish
      name = remove_leading_descriptors(name)
      remove_percentage_descriptors(name).gsub(/\s+/, " ").strip.sub(/[\s\-]+\z/, "")
    end

    sig { params(segment: String).returns(T::Boolean) }
    def descriptor_only?(segment)
      words = segment.split(/\s+/)
      words.any? && words.all? { |word| SEGMENT_DESCRIPTORS.include?(word) }
    end

    private

    sig { params(name: String).returns(String) }
    def remove_percentage_descriptors(name)
      name.sub(/\A\d+%\s*-?\s*(?:extra-)?lean\s+/, "").gsub(/\b\d+%\s*/, "")
        .sub(/\A(?:reduced|low)[ -]fat\s+/, "").strip
    end

    sig { params(name: String).returns(String) }
    def ingredient_segment(name)
      segments = name.split(SEGMENT_SEPARATOR).reject(&:blank?)
      segments.find { |segment| !descriptor_only?(segment) } || segments.first || name
    end

    sig { params(name: String).returns(String) }
    def remove_leading_descriptors(name)
      loop do
        descriptors = name.match?(/\Aground (?:#{GROUND_MEATS.join("|")})\b/) ? LEADING_DESCRIPTORS - [ "ground" ] : LEADING_DESCRIPTORS
        stripped = descriptors.reduce(name) { |result, word| result.sub(/\A#{word}\s+/, "") }
        return name if stripped == name

        name = stripped
      end
    end
  end
end
