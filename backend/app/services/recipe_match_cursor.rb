# typed: true
# frozen_string_literal: true

# Encodes and decodes the opaque `nextCursor` used to paginate RecipeMatcher's
# results, and builds the keyset-pagination SQL that resumes a search after a
# given recipe. RecipeMatcher runs two ranked queries — full matches, then
# partial matches — so every cursor carries a `phase` plus whichever sort
# columns that phase's ORDER BY needs, and RecipeMatcher decides which
# `*_after_sql` method applies based on that phase.
class RecipeMatchCursor < Cursor
  extend T::Sig

  FULL_PHASE = "full"
  PARTIAL_PHASE = "partial"
  PHASES = T.let([ FULL_PHASE, PARTIAL_PHASE ].freeze, T::Array[String])

  # Sentinel substituted for a NULL rating so `ratings` can be compared as a
  # plain, always-present number instead of needing NULL-aware branches in
  # the pagination SQL. Sound only because the `ratings_non_negative` check
  # constraint on recipes guarantees no real rating is ever below zero.
  RATINGS_FLOOR = -1

  purpose "recipe-matches-cursor"

  # Builds the signed cursor for the row a page ended on. Encodes only the
  # sort columns needed to resume after this exact row: `ratings`,
  # `required_ingredient_count`, and `id` for every phase (the shared
  # tiebreak chain used by rank_after_sql), plus `match_percentage` and
  # `missing_count` when the row is a partial match, since only that phase
  # sorts by them.
  #
  # recipe          - the last Recipe on the current page (must expose
  #                    match_phase, ratings, required_ingredient_count, id,
  #                    and, for partial matches, match_percentage and
  #                    missing_count)
  # ingredient_ids   - the searched ingredient ids, used to scope the cursor
  #                    to this exact search
  # max_missing      - the search's max_missing filter, also part of the scope
  #
  # Returns the signed, opaque cursor string.
  # Raises ArgumentError if the recipe's match_phase isn't a known phase.
  sig do
    params(recipe: T.untyped, ingredient_ids: T::Array[String], max_missing: Integer).returns(String)
  end
  def self.encode(recipe:, ingredient_ids:, max_missing:)
    phase = recipe.match_phase.to_s
    raise ArgumentError, "recipe match phase is invalid" unless PHASES.include?(phase)

    payload = {
      "phase" => phase,
      "ratings" => recipe.ratings&.to_f || RATINGS_FLOOR,
      "required_ingredient_count" => recipe.required_ingredient_count,
      "id" => recipe.id
    }
    if phase == PARTIAL_PHASE
      payload["match_percentage"] = recipe.match_percentage.to_f
      payload["missing_count"] = recipe.missing_count.to_i
    end

    encode_signed(payload, scope: scope_for(ingredient_ids:, max_missing:))
  end

  # Verifies and decodes a cursor string, scoped to the same search that must
  # have minted it. A cursor encoded for different ingredient_ids or
  # max_missing is rejected, so a client can't replay a cursor against a
  # different search than the one that produced it.
  #
  # value           - the cursor string returned by encode
  # ingredient_ids  - the current search's ingredient ids
  # max_missing     - the current search's max_missing filter
  #
  # Returns the decoded payload hash.
  # Raises Cursor::InvalidCursor if the signature, version, or scope doesn't match.
  sig do
    params(value: T.anything, ingredient_ids: T::Array[String], max_missing: Integer)
      .returns(T::Hash[String, T.untyped])
  end
  def self.decode(value, ingredient_ids:, max_missing:)
    decode_signed(value, scope: scope_for(ingredient_ids:, max_missing:))
  end

  # WHERE-clause fragment for resuming a full-match page: full matches are
  # all pinned at match_percentage = 100 and missing_count = 0, so the only
  # sort columns that vary between rows are the shared ratings /
  # required_ingredient_count / id tiebreak.
  #
  # cursor  - the decoded cursor payload from decode
  #
  # Returns a raw SQL boolean expression, true for rows that sort after cursor.
  sig { params(cursor: T::Hash[String, T.untyped]).returns(String) }
  def self.full_after_sql(cursor:)
    rank_after_sql(cursor:)
  end

  # WHERE-clause fragment for resuming a partial-match page. Partial matches
  # additionally sort by match_percentage DESC then missing_count ASC ahead
  # of the shared tiebreak, so this walks those two columns first — only
  # falling through to rank_after_sql once both are tied with the cursor —
  # mirroring RecipeMatcher's partial_order_sql column-for-column.
  #
  # cursor  - the decoded cursor payload from decode, including
  #           match_percentage and missing_count
  #
  # Returns a raw SQL boolean expression, true for rows that sort after cursor.
  sig { params(cursor: T::Hash[String, T.untyped]).returns(String) }
  def self.partial_after_sql(cursor:)
    match = quote(cursor["match_percentage"])
    missing = quote(cursor["missing_count"])

    <<~SQL.squish
      (recipes.match_percentage < #{match} OR
        (recipes.match_percentage = #{match} AND
          (recipes.missing_count > #{missing} OR
            (recipes.missing_count = #{missing} AND #{rank_after_sql(cursor:)}))))
    SQL
  end

  # The signature scope a cursor is bound to: re-encoding the same search
  # parameters must always produce the same scope, so a cursor from one
  # search can never be replayed against another.
  #
  # ingredient_ids  - the search's ingredient ids (sorted, for order-independence)
  # max_missing     - the search's max_missing filter
  #
  # Returns the scope hash passed to encode_signed/decode_signed.
  sig do
    params(ingredient_ids: T::Array[String], max_missing: Integer)
      .returns(T::Hash[String, T.untyped])
  end
  def self.scope_for(ingredient_ids:, max_missing:)
    { "ingredients" => ingredient_ids.to_a.sort, "max_missing" => max_missing }
  end

  # WHERE-clause fragment for the tiebreak chain shared by both phases:
  # ratings DESC, then required_ingredient_count ASC, then id ASC (id is the
  # final, always-unique tiebreak that keeps pagination stable when every
  # other column ties). Ratings sorts DESC while the other two sort ASC;
  # negating the (NULL-free, via RATINGS_FLOOR) ratings value turns "higher
  # rating first" into "lower negated value first", so all three columns
  # share one ascending direction and can be compared as a single Postgres
  # row tuple instead of three nested NULL-aware cases.
  #
  # cursor  - the decoded cursor payload from decode
  #
  # Returns a raw SQL boolean expression, true for rows that sort after cursor
  # on this tiebreak chain.
  sig { params(cursor: T::Hash[String, T.untyped]).returns(String) }
  def self.rank_after_sql(cursor:)
    ratings = quote(cursor["ratings"])
    required = quote(cursor["required_ingredient_count"])
    id = quote(cursor["id"])

    "(-#{ratings_expr}, recipes.required_ingredient_count, recipes.id) > (-#{ratings}, #{required}, #{id})"
  end

  # The recipes.ratings column, NULL-coalesced to RATINGS_FLOOR so it can be
  # used as a plain, always-present number in a SQL expression.
  #
  # Returns a raw SQL expression string.
  sig { returns(String) }
  def self.ratings_expr
    "COALESCE(recipes.ratings, #{RATINGS_FLOOR})"
  end

  # SQL-escapes a Ruby value for safe interpolation into the raw SQL
  # fragments built above.
  #
  # value  - the value to quote
  #
  # Returns the quoted SQL literal string.
  sig { params(value: T.untyped).returns(String) }
  def self.quote(value)
    ActiveRecord::Base.connection.quote(value)
  end

  private_class_method :quote, :ratings_expr
end
