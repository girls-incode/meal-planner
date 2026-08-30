# typed: true
# frozen_string_literal: true

module Ingredients
  class UnresolvedInput < StandardError
    extend T::Sig

    sig { returns(T::Array[String]) }
    attr_reader :values

    sig { params(values: T::Array[String]).void }
    def initialize(values)
      @values = values
      super("Unresolved ingredients: #{values.join(', ')}")
    end
  end
end
