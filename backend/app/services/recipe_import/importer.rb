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

    sig { returns(T::Array[T.untyped]) }
    def build_catalog
      names = Set.new
      category_names = Set.new
      author_names = Set.new
      each_record do |raw|
        @stats[:recipes_seen] += 1
        next unless RecipeValidator.valid?(raw)

        Ingredients::LineParser.call(raw["ingredients"]).first.each { |line| names << line[:name] }
        category_name = RecipeValidator.category_name(raw)
        category_names << category_name if category_name
        author_name = RecipeValidator.author_name(raw)
        author_names << author_name if author_name
      end
      @splits = names.to_h { |name| [ name, split(name, names) ] }
      ingredient_names = @splits.values.flatten.to_set
      catalog = Ingredient.where(name: ingredient_names.to_a).pluck(:name, :id).to_h
      (ingredient_names - catalog.keys).each_slice(BATCH_SIZE) do |slice|
        rows = slice.map { |name| { name: } }
        Ingredient.insert_all(rows, returning: %w[id name], unique_by: :index_ingredients_on_name,
          record_timestamps: true).each { |row| catalog[row["name"]] = row["id"] }
        @stats[:ingredients_created] += slice.size
      end
      [ catalog, build_category_catalog(category_names), build_author_catalog(author_names) ]
    end

    sig { params(names: T.untyped).returns(T.untyped) }
    def build_category_catalog(names)
      catalog = Category.where(name: names.to_a).pluck(:name, :id).to_h
      (names - catalog.keys).each_slice(BATCH_SIZE) do |slice|
        rows = slice.map { |name| { name: } }
        Category.insert_all(rows, returning: %w[id name], unique_by: :index_categories_on_name,
          record_timestamps: true).each { |row| catalog[row["name"]] = row["id"] }
      end
      catalog
    end

    sig { params(names: T.untyped).returns(T.untyped) }
    def build_author_catalog(names)
      catalog = Author.where(name: names.to_a).pluck(:name, :id).to_h
      (names - catalog.keys).each_slice(BATCH_SIZE) do |slice|
        rows = slice.map { |name| { name: } }
        Author.insert_all(rows, returning: %w[id name], unique_by: :index_authors_on_name,
          record_timestamps: true).each { |row| catalog[row["name"]] = row["id"] }
      end
      catalog
    end

    sig { params(name: String, names: T.untyped).returns(T::Array[String]) }
    def split(name, names)
      match = COMPOUND.match(name)
      return [ name ] unless match

      left, right = @normalizer.call(match[:left]), @normalizer.call(match[:right])
      names.include?(left) && names.include?(right) ? [ left, right ] : [ name ]
    end

    sig { params(ingredient_catalog: T.untyped, category_catalog: T.untyped, author_catalog: T.untyped).void }
    def persist(ingredient_catalog, category_catalog, author_catalog)
      writer = BatchWriter.new(catalog: ingredient_catalog, categories: category_catalog, authors: author_catalog, splits: @splits,
        import_run: @import_run, parser_version: PARSER_VERSION)
      each_batch do |batch|
        @stats[:recipe_ingredients] += writer.call(batch)
        @stats[:recipes] += batch.size
        @stats[:parse_failures] += batch.sum { |document| document[:issues].size }
      end
    end

    sig { params(block: T.proc.params(batch: T.untyped).void).void }
    def each_batch(&block)
      batch = []
      each_record do |raw|
        next unless RecipeValidator.valid?(raw)

        lines, issues = Ingredients::LineParser.call(raw["ingredients"])
        batch << { attributes: RecipeValidator.attributes(raw), category_name: RecipeValidator.category_name(raw),
          author_name: RecipeValidator.author_name(raw), lines:, issues: }
        if batch.size == BATCH_SIZE
          block.call(batch)
          batch = []
        end
      end
      block.call(batch) if batch.any?
    end

    sig { params(block: T.proc.params(record: T.untyped).void).returns(T.untyped) }
    def each_record(&block)
      @io_factory.call do |io|
        source = io.read(MAX_SOURCE_BYTES + 1)
        raise ArgumentError, "source exceeds #{MAX_SOURCE_BYTES} bytes" if source.bytesize > MAX_SOURCE_BYTES

        JSON.parse(source).each(&block)
      end
    end

    sig { void }
    def log_completed
      Rails.logger.info(event: "recipe_import.completed", import_run_id: @import_run.id, source_url: @source_url,
        duration_ms: ((@import_run.finished_at - @import_run.started_at) * 1_000).round, **@stats)
    end
  end
end
