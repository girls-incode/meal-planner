# typed: true
# frozen_string_literal: true

module Ingredients
  class LineParser
    extend T::Sig
    MAX_LENGTH = 2_000
    PREPARATION_WORDS = %w[
      chopped diced sliced minced crushed grated shredded cubed halved quartered
      peeled seeded pitted cored trimmed softened melted beaten sifted drained
      rinsed cooked raw frozen thawed dried toasted roasted mashed
    ].freeze
    UNICODE_FRACTIONS = {
      "½" => 0.5, "⅓" => 1.0 / 3, "⅔" => 2.0 / 3, "¼" => 0.25, "¾" => 0.75,
      "⅕" => 0.2, "⅙" => 1.0 / 6, "⅛" => 0.125, "⅜" => 0.375, "⅝" => 0.625, "⅞" => 0.875
    }.freeze
    FRACTION_CHARS = UNICODE_FRACTIONS.keys.join.freeze
    QUANTITY_CHARACTERS = "\\d.\\/⁄#{FRACTION_CHARS}".freeze
    # Matches a parenthetical aside at the start of a name, e.g. "(packed) brown sugar", so it can be stripped.
    LEADING_COMMENT = /\A\([^)]+\)\s*/.freeze
    QUANTITY_PATTERN = /[#{QUANTITY_CHARACTERS}\s]+/.freeze
    QUANTITY_WITH_SEPARATOR = /\A\s*[#{QUANTITY_CHARACTERS}\s]+\s\z/.freeze
    UNIT_PATTERN = %r{
      cups?|tablespoons?|tbsp|teaspoons?|tsp|ounces?|oz|pounds?|lbs?|packages?|cans?
      |grams?|g|kilograms?|kg|milligrams?|mg|milliliters?|ml|liters?|cloves?
      |pinch(?:es)?|dashes?|drops?|splash(?:es)?|handfuls?|sheets?|slices?|stalks?|bunches?
      |sprigs?|leaves?|leafs?|spears?|crowns?|ears?|heads?|loaves?|wedges?|fillets?|strips?
      |wrappers?|cakes?|bricks?|blocks?|sticks?|bars?|pieces?|packs?|boxes?|bags?|bottles?|jars?
      |bundles?|hanks?|servings?|each|whole|florets?|kernels?|grains?
    }xi.freeze
    INGREDIENT_LINE = %r{
      \A\s*(?<quantity>#{QUANTITY_PATTERN})?\s*
      (?:\([^)]+\)\s*)?
      (?:(?<unit>#{UNIT_PATTERN})(?=\s|\z))?\s*(?:of\s+)?(?<name>.+)\z
    }xi.freeze

    sig { params(raw_lines: T::Array[T.untyped]).returns(T.untyped) }
    def self.call(raw_lines)
      new.call(raw_lines)
    end

    sig { params(normalizer: Normalizer).void }
    def initialize(normalizer: Normalizer.new)
      @normalizer = normalizer
    end

    sig { params(raw_lines: T::Array[T.untyped]).returns(T.untyped) }
    def call(raw_lines)
      Array(raw_lines).each_with_object([ [], [] ]) do |raw_text, (lines, issues)|
        text = raw_text.to_s

        if raw_text.blank?
          issues << { original_text: text, error: "ingredient line is blank" }
        elsif text.length > MAX_LENGTH
          issues << { original_text: text.first(MAX_LENGTH), error: "ingredient line exceeds #{MAX_LENGTH} characters" }
        else
          line = parse(text)
          name = @normalizer.call(line[:name])
          if name.blank?
            issues << { original_text: text, error: "ingredient name is blank" }
          else
            lines << line.merge(name:, raw_text: text)
          end
        end
      end
    end

    private

    # Splits a raw line into quantity, unit, name, preparation, and qualifier.
    # Measurements must be whitespace-delimited, so plain names such as
    # "garlic" are not mistaken for the "g" unit. Final catalog-name
    # normalization happens in #call after this structural parsing.
    sig { params(text: String).returns(T::Hash[Symbol, T.untyped]) }
    def parse(text)
      match = INGREDIENT_LINE.match(text)
      return { quantity: nil, unit: nil, preparation: nil, qualifier: nil, name: text } unless match

      unit = match[:unit].to_s.downcase.singularize.presence
      has_measurement = unit.present? || match[:quantity].to_s.match?(QUANTITY_WITH_SEPARATOR)
      name = has_measurement ? match[:name].to_s.strip.sub(LEADING_COMMENT, "") : text
      { quantity: unit && parse_quantity(match[:quantity]), unit:, name:, **extract_modifiers(name) }
    end

    # Extracts preparation and qualifier metadata from name segments.
    sig { params(name: String).returns(T::Hash[Symbol, T.nilable(String)]) }
    def extract_modifiers(name)
      segments = name.downcase.split(Normalizer::SEGMENT_SEPARATOR).reject(&:blank?)
      return { preparation: nil, qualifier: nil } if segments.empty?

      index = segments.index { |segment| !@normalizer.descriptor_only?(segment) } || 0
      preparation = segments.fetch(index).split.take_while { |word| PREPARATION_WORDS.include?(word) }.presence&.join(" ")
      qualifier = segments[(index + 1)..]&.join(", ").presence
      if qualifier && qualifier.split(/[ ,]+/).all? { |word| PREPARATION_WORDS.include?(word) }
        preparation, qualifier = [ preparation, qualifier ].compact.join(", "), nil
      end
      { preparation:, qualifier: }
    end

    # Sums mixed-number parts (e.g. "1 1/2" or "1 ½") into a single Float.
    sig { params(text: T.nilable(String)).returns(T.nilable(Float)) }
    def parse_quantity(text)
      return nil if text.blank?

      text.strip.split(/\s+/).sum do |part|
        part = part.tr("⁄", "/")
        next UNICODE_FRACTIONS[part] if UNICODE_FRACTIONS.key?(part)
        next part.to_f unless part.include?("/")

        numerator, denominator = part.split("/").map(&:to_f)
        denominator.zero? ? 0.0 : numerator / denominator
      end
    end
  end
end
