# typed: true
# frozen_string_literal: true

require "digest"
require "json"
require "set"

module RecipeImport
  class Importer
    extend T::Sig
    BATCH_SIZE = 500
    MAX_SOURCE_BYTES = 25.megabytes
    PARSER_VERSION = "2.0.0"
    COMPOUND = /\A(?<left>[a-z][a-z ]*?) and (?<right>[a-z][a-z ]*)\z/.freeze

    sig do
      params(file: T.untyped, source_url: T.nilable(String), io_factory: T.untyped,
        source_fingerprint: T.nilable(String)).void
    end
    def initialize(file: nil, source_url: nil, io_factory: nil, source_fingerprint: nil)
      raise ArgumentError, "provide file or io_factory" if file.blank? && io_factory.nil?
      raise ArgumentError, "source_fingerprint is required with io_factory" if file.nil? && source_fingerprint.blank?

      @file, @source_url = file, source_url || file.to_s
      @io_factory = io_factory || ->(&block) { File.open(@file, &block) }
      # Fingerprint used to detect if this exact source was already imported. If not
      # given here, #fingerprint falls back to hashing @file's contents (SHA256) --
      # which only works when a real file is present, so io_factory-based imports
      # (no file on disk) must pass one in explicitly.
      @source_fingerprint = source_fingerprint
      @normalizer = Ingredients::Normalizer.new
      @stats = { recipes: 0, recipes_seen: 0, ingredients_created: 0, recipe_ingredients: 0, parse_failures: 0 }
    end

    sig { returns(T::Hash[Symbol, Integer]) }
    def call
      @import_run = ImportRun.create!(source_url: @source_url, source_fingerprint: fingerprint,
        parser_version: PARSER_VERSION, status: "running", started_at: Time.current)
      ingredient_catalog, category_catalog, author_catalog = build_catalog
      persist(ingredient_catalog, category_catalog, author_catalog)
      @import_run.update!(status: "completed", finished_at: Time.current, recipes_seen: @stats[:recipes_seen],
        recipes_imported: @stats[:recipes], ingredients_created: @stats[:ingredients_created],
        ingredients_normalized: ingredient_catalog.size, parse_errors: @stats[:parse_failures])
      log_completed
      @stats
    rescue StandardError => e
      @import_run&.update(status: "failed", finished_at: Time.current, error_message: e.message.to_s.first(2_000))
      Rails.logger.error(event: "recipe_import.failed", import_run_id: @import_run&.id, source_url: @source_url,
        parser_version: PARSER_VERSION, error_class: e.class.name, error: e.message)
      raise
    end

    private

    sig { returns(String) }
    def fingerprint = @source_fingerprint || Digest::SHA256.file(@file).hexdigest

    # Pass 1: parses and validates every raw record once, buffering the valid ones into
    # @documents for pass 2 (persist), while collecting every distinct ingredient/category/
    # author name seen. Resolves compound ingredient splits, then upserts every ingredient
    # (and, via the two catalog builders below, category/author) the recipes reference, so
    # pass 2 can bulk-write recipes with every foreign key already resolved.
    sig { returns(T::Array[T.untyped]) }
    def build_catalog
      names = Set.new
      category_names = Set.new
      author_names = Set.new
      @documents = []
      records.each do |raw|
        @stats[:recipes_seen] += 1
        next unless RecipeValidator.valid?(raw)

        lines, issues = Ingredients::LineParser.call(raw["ingredients"])
        lines.each { |line| names << line[:name] }
        category_name = RecipeValidator.category_name(raw)
        category_names << category_name if category_name
        author_name = RecipeValidator.author_name(raw)
        author_names << author_name if author_name
        @documents << { attributes: RecipeValidator.attributes(raw), category_name:, author_name:, lines:, issues: }
      end
      @splits = names.to_h { |name| [ name, split(name, names) ] }
      ingredient_names = @splits.values.flatten.to_set
      catalog, ingredients_created = catalog_for(Ingredient, ingredient_names, :index_ingredients_on_name)
      @stats[:ingredients_created] += ingredients_created
      category_catalog, = catalog_for(Category, category_names, :index_categories_on_name)
      author_catalog, = catalog_for(Author, author_names, :index_authors_on_name)
      [ catalog, category_catalog, author_catalog ]
    end

    # Looks up which of `names` already exist for `model`, bulk-creates the rest in bounded
    # batches, and merges the newly created ids back in, so the returned { name => id } map
    # covers every needed name (pre-existing and new) with no per-name queries. Also returns
    # how many rows were newly created.
    sig { params(model: T.untyped, names: T.untyped, unique_by: Symbol).returns(T.untyped) }
    def catalog_for(model, names, unique_by)
      catalog = model.where(name: names.to_a).pluck(:name, :id).to_h
      created = 0
      (names - catalog.keys).each_slice(BATCH_SIZE) do |slice|
        rows = slice.map { |name| { name: } }
        model.insert_all(rows, returning: %w[id name], unique_by:,
          record_timestamps: true).each { |row| catalog[row["name"]] = row["id"] }
        created += slice.size
      end
      [ catalog, created ]
    end

    # Splits a compound "X and Y" name into two ingredients only when both halves are
    # already known ingredient names elsewhere in this source's corpus, e.g. "salt and black
    # pepper" -> salt + black pepper. This corpus-derived check (rather than a hardcoded
    # conjunction list) avoids false splits like "garlic and herb seasoning", where "herb
    # seasoning" isn't a standalone ingredient on its own.
    sig { params(name: String, names: T.untyped).returns(T::Array[String]) }
    def split(name, names)
      match = COMPOUND.match(name)
      return [ name ] unless match

      left, right = @normalizer.call(match[:left]), @normalizer.call(match[:right])
      names.include?(left) && names.include?(right) ? [ left, right ] : [ name ]
    end

    # Pass 2: writes the buffered @documents in BATCH_SIZE slices via BatchWriter, one
    # transaction per batch, accumulating run stats (ingredients written, recipes imported,
    # parse failures) from each batch's result.
    sig { params(ingredient_catalog: T.untyped, category_catalog: T.untyped, author_catalog: T.untyped).void }
    def persist(ingredient_catalog, category_catalog, author_catalog)
      writer = BatchWriter.new(catalog: ingredient_catalog, categories: category_catalog, authors: author_catalog, splits: @splits,
        import_run: @import_run, parser_version: PARSER_VERSION)
      @documents.each_slice(BATCH_SIZE) do |batch|
        @stats[:recipe_ingredients] += writer.call(batch)
        @stats[:recipes] += batch.size
        @stats[:parse_failures] += batch.sum { |document| document[:issues].size }
      end
    end

    # Reads and parses the whole JSON source, memoized since build_catalog is the only
    # caller but iterates it once regardless. Reads one byte past MAX_SOURCE_BYTES so an
    # oversized source is rejected without needing to buffer the whole thing to find out.
    sig { returns(T::Array[T.untyped]) }
    def records
      @records ||= @io_factory.call do |io|
        source = io.read(MAX_SOURCE_BYTES + 1)
        raise ArgumentError, "source exceeds #{MAX_SOURCE_BYTES} bytes" if source.bytesize > MAX_SOURCE_BYTES

        JSON.parse(source)
      end
    end

    sig { void }
    def log_completed
      Rails.logger.info(event: "recipe_import.completed", import_run_id: @import_run.id, source_url: @source_url,
        duration_ms: ((@import_run.finished_at - @import_run.started_at) * 1_000).round, **@stats)
    end
  end
end
