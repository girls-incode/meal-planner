# typed: true
# frozen_string_literal: true

# Backward-compatible entry point for the original seed task. Import behavior
# lives in RecipeImport::Importer; new code should use that service directly.
class RecipeSeeder
  extend T::Sig
  BATCH_SIZE = RecipeImport::Importer::BATCH_SIZE
  PARSER_VERSION = RecipeImport::Importer::PARSER_VERSION

  sig do
    params(file: T.untyped, source_url: T.nilable(String), io_factory: T.untyped,
      source_fingerprint: T.nilable(String)).returns(T::Hash[Symbol, Integer])
  end
  def self.call(file: nil, source_url: nil, io_factory: nil, source_fingerprint: nil)
    RecipeImport::Importer.new(file:, source_url:, io_factory:, source_fingerprint:).call
  end

  sig do
    params(file: T.untyped, source_url: T.nilable(String), io_factory: T.untyped,
      source_fingerprint: T.nilable(String)).void
  end
  def initialize(file: nil, source_url: nil, io_factory: nil, source_fingerprint: nil)
    @importer = RecipeImport::Importer.new(file:, source_url:, io_factory:, source_fingerprint:)
  end

  sig { returns(T::Hash[Symbol, Integer]) }
  def call
    @importer.call
  end

  private

  # Retained temporarily for callers/tests that exercised the old private
  # method. Parsing ownership now belongs to Ingredients::Normalizer.
  sig { params(value: T.untyped).returns(String) }
  def normalize(value)
    Ingredients::Normalizer.call(value)
  end
end
