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
    QUANTITY_PREFIX = /\A\s*[\d.\/½⅓⅔¼¾⅕⅙⅛⅜⅝⅞]+\s+/.freeze
    LEADING_COMMENT = /\A\([^)]+\)\s*/.freeze
    QUANTITY_PATTERN = /[\d.\/⁄\s½⅓⅔¼¾⅕⅙⅛⅜⅝⅞]+/.freeze
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
      (?:\((?<comment>[^)]+)\)\s*)?
      (?<unit>#{UNIT_PATTERN})?(?:of\s+)?(?<name>.+)\z
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
          next
        end

        if text.length > MAX_LENGTH
          issues << { original_text: text.first(MAX_LENGTH), error: "ingredient line exceeds #{MAX_LENGTH} characters" }
          next
        end

        line = parse(text)
        name = @normalizer.call(line[:name])
        if name.blank?
          issues << { original_text: text, error: "ingredient name is blank" }
          next
        end

        lines << line.merge(name:, raw_text: text)
      end
    end

    private

    sig { params(text: String).returns(T::Hash[Symbol, T.untyped]) }
    def parse(text)
      match = INGREDIENT_LINE.match(text)
      return { quantity: nil, unit: nil, preparation: nil, qualifier: nil, name: text } unless match

      unit = match[:unit].to_s.downcase.singularize.presence
      name = unit.present? || text.match?(QUANTITY_PREFIX) ? match[:name].to_s.strip.sub(LEADING_COMMENT, "") : text
      { quantity: unit && parse_quantity(match[:quantity]), unit:, name:, **extract_modifiers(name) }
    end

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

    sig { params(text: T.nilable(String)).returns(T.nilable(Float)) }
    def parse_quantity(text)
      return nil if text.blank?

      text.strip.split(/\s+/).sum do |part|
        part = part.tr("⁄", "/")
        next UNICODE_FRACTIONS[part] if UNICODE_FRACTIONS.key?(part)
        next part.to_f unless part.include?("/")

        fraction = part.split("/").map(&:to_f)
        denominator = fraction.fetch(1)
        denominator.zero? ? 0.0 : fraction.fetch(0) / denominator
      end
    end
  end
end
