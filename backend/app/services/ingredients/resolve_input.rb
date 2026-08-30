# typed: true
# frozen_string_literal: true

module Ingredients
  class ResolveInput
    extend T::Sig

    sig { params(values: T::Array[T.untyped]).returns(T::Array[String]) }
    def self.call(values:)
      new(values:).call
    end

    sig { params(values: T::Array[T.untyped]).void }
    def initialize(values:)
      @values = Array(values).filter_map { |value| value.to_s.strip.downcase.presence }.uniq
    end

    sig { returns(T::Array[String]) }
    def call
      return [] if @values.empty?

      canonical = Ingredient.where(name: @values).pluck(:name, :id).to_h
      remaining = @values - canonical.keys.map(&:downcase)
      raise UnresolvedInput, remaining unless remaining.empty?

      canonical.values.uniq
    end
  end
end
