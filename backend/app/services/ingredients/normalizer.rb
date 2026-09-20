# typed: true
# frozen_string_literal: true

require "set"

module Ingredients
  # Converts raw recipe-ingredient text into a stable catalog name for matching.
  # It removes measurements, dimensions, presentation/prep descriptors,
  # parenthetical notes, health claims, and trailing serving qualifiers.
  # It removes formatting and prep detail, but never treats different foods as
  # equivalent: for example, it does not normalize butter to margarine. Any
  # intentional aliases belong in explicit alias rules.
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
    FRACTION_CHARS = "½⅓⅔¼¾⅕⅙⅛⅜⅝⅞".freeze
    MEASUREMENT_UNITS = %w[
      grams? g kg mg ml l ounces? oz pounds? lbs? cups? tablespoons? tbsp
      teaspoons? tsp pinches? dashes? drops? spears? stalks? bunches? sprigs?
      leaves? sheets? slices? heads? pieces? cloves? cans? packages? packs?
      boxes? bags? bottles? jars? wrappers? each whole
    ].freeze
    SIZE_UNITS = %w[inch(?:es)? grain cm mm].freeze
    CUT_STYLES = %w[cut diced cubed thick thin long wide sliced pieces? chunks? strips? whole].freeze
    HEALTH_DEGREES = %w[less reduced low].freeze
    HEALTH_ATTRIBUTES = %w[fat sodium sugar calorie].freeze
    GROUND_MEAT_PREFIX = /\Aground (?:#{GROUND_MEATS.join("|")})\b/.freeze
    LEADING_DESCRIPTOR_PREFIX = /\A(?:#{LEADING_DESCRIPTORS.join("|")})\s+/.freeze

    sig { params(value: T.untyped).returns(String) }
    def self.call(value)
      new.call(value)
    end

    sig { params(value: T.untyped).returns(String) }
    def call(value)
      name = value.to_s.downcase.strip
      name = name.gsub(/\([^)]*\)/, " ").gsub(/[®™]/, "")
      name = remove_measurement_prefixes(name)
      name = remove_health_prefixes(name)
      name = remove_percentage_descriptors(name)
      name = remove_leading_fat_descriptor(name)
      name = ingredient_segment(name).sub(TRAILING_QUALIFIER, "").squish
      name = remove_leading_descriptors(name)
      remove_leading_fat_descriptor(name).gsub(/\s+/, " ").strip.sub(/[\s\-]+\z/, "")
    end

    # True if every word in the segment is a prep/cosmetic descriptor, with no
    # actual food word — e.g. "skinless" or "boneless" on their own. Used by
    # ingredient_segment to skip descriptor-only comma segments, so
    # "skinless, boneless chicken thighs" resolves to "chicken thighs" rather
    # than stopping at the first comma.
    sig { params(segment: String).returns(T::Boolean) }
    def descriptor_only?(segment)
      words = segment.split(/\s+/)
      words.any? && words.all? { |word| SEGMENT_DESCRIPTORS.include?(word) }
    end

    private

    # Strips a leading size prefix, e.g. "2 inch", "1/2-inch", or "8- to
    # 10-inch", along with an optional cut-style word right after it:
    #   "2 inch thick ham steak" -> "ham steak"
    #   "1/2-inch thick pork chops" -> "pork chops"
    #   "8- to 10-inch flour tortillas" -> "flour tortillas"
    sig { params(name: String).returns(String) }
    def remove_measurement_prefixes(name)
      name = name.sub(/\A[\d\s.\/x#{FRACTION_CHARS}⁄]+(?:\s*-\s*to\s*[\d\s.\/x#{FRACTION_CHARS}⁄]+)?\s*-?(?:#{SIZE_UNITS.join("|")})\b[\s\-]*(?:#{CUT_STYLES.join("|")})?\s+/, "").strip
      name.sub(/\A(?=[\d.\/⁄#{FRACTION_CHARS}])[\d.\/⁄\s#{FRACTION_CHARS}]*\s*(?:#{MEASUREMENT_UNITS.join("|")})\s+/, "").strip
    end

    # Strips a leading health-claim prefix like "25%-less-sodium" or
    # "1/3-less-fat", built from a quantity (percentage or fraction), a
    # degree word (less/reduced/low), and an attribute (fat/sodium/sugar/
    # calorie):
    #   "25%-less-sodium chicken broth" -> "chicken broth"
    #   "1/3-less-fat cream cheese" -> "cream cheese"
    #   "20%-reduced-sugar jam" -> "jam"
    sig { params(name: String).returns(String) }
    def remove_health_prefixes(name)
      name.sub(/\A[\d\/]+%?\s*-(?:#{HEALTH_DEGREES.join("|")})-(?:#{HEALTH_ATTRIBUTES.join("|")})\s+/, "").strip
    end

    # Strips percentage claims, which describe the product rather than the
    # ingredient itself:
    #   "93%-lean ground beef" -> "ground beef" (leading lean/extra-lean claim)
    #   "shredded 2% milk cheddar cheese" -> "shredded milk cheddar cheese" (any "N%" anywhere)
    sig { params(name: String).returns(String) }
    def remove_percentage_descriptors(name)
      name.sub(/\A\d+%\s*-?\s*(?:extra-)?lean\s+/, "").gsub(/\b\d+%\s*/, "").strip
    end

    # Leading prep descriptors can hide a fat claim, so this runs both before
    # and after remove_leading_descriptors.
    sig { params(name: String).returns(String) }
    def remove_leading_fat_descriptor(name)
      name.sub(/\A(?:reduced|low)[ -]fat\s+/, "").strip
    end

    # Splits name into segments on SEGMENT_SEPARATOR and returns the segment that
    # actually names the ingredient, e.g. for "skinless, boneless chicken
    # thighs" that's "boneless chicken thighs", not "skinless" — skipping
    # leading segments made up entirely of descriptor words (see
    # descriptor_only?) instead of naively taking the text before the first
    # comma. Falls back to the first segment if every segment is
    # descriptor-only, or to the original name if splitting found no segments
    # at all (e.g. name was blank).
    sig { params(name: String).returns(String) }
    def ingredient_segment(name)
      segments = name.split(SEGMENT_SEPARATOR).reject(&:blank?)
      return name if segments.empty?

      segments.find { |segment| !descriptor_only?(segment) } || segments.first
    end

    # Repeatedly strips one leading descriptor word at a time until none remain, re-checking after each strip
    # whether the name is now a ground meat (e.g. "ground beef") so "ground"
    # is preserved there but still stripped from something like "ground
    # ginger":
    #   "fresh ground beef" -> "ground beef" ("ground" kept, precedes a meat)
    #   "ground ginger" -> "ginger" ("ground" stripped, not a ground meat)
    sig { params(name: String).returns(String) }
    def remove_leading_descriptors(name)
      loop do
        return name if name.match?(GROUND_MEAT_PREFIX)

        stripped = name.sub(LEADING_DESCRIPTOR_PREFIX, "")
        return name if stripped == name

        name = stripped
      end
    end
  end
end
