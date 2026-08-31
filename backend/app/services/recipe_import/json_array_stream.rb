# typed: true
# frozen_string_literal: true

require "json"

module RecipeImport
  # Yields one object at a time from a top-level JSON array. It tracks nesting
  # and quoted strings so braces inside JSON strings do not terminate a record.
  class JsonArrayStream
    extend T::Sig

    sig { params(io: T.untyped, block: T.nilable(T.proc.params(record: T.untyped).void)).returns(T.untyped) }
    def self.each(io, &block)
      return enum_for(T.must(__method__), io) unless block

      object = T.let(+"", T.untyped)
      depth = 0
      state = T.let(:before_array, Symbol)
      in_string = T.let(false, T::Boolean)
      escaped = T.let(false, T::Boolean)

      io.each_char do |char|
        if depth.zero?
          state = next_state(state, char)
          if state == :in_object
            depth = 1
            object = +char
          end
          next
        end

        object << char
        if in_string
          if escaped
            escaped = false
          elsif char == "\\"
            escaped = true
          elsif char == '"'
            in_string = false
          end
          next
        end

        case char
        when '"' then in_string = true
        when "{" then depth += 1
        when "}"
          depth -= 1
          if depth.zero?
            block.call(JSON.parse(object))
            object = +""
            state = :after_object
          end
        end
      end

      raise JSON::ParserError, "expected a complete top-level JSON array" unless state == :after_array
    end

    sig { params(state: Symbol, char: String).returns(Symbol) }
    def self.next_state(state, char)
      return state if char.match?(/\s/)

      case state
      when :before_array
        raise JSON::ParserError, "expected a top-level JSON array" unless char == "["

        :between_objects
      when :between_objects
        return :after_array if char == "]"
        raise JSON::ParserError, "expected a JSON object" unless char == "{"

        :in_object
      when :after_object
        return :between_objects if char == ","
        return :after_array if char == "]"

        raise JSON::ParserError, "expected a comma or closing array bracket"
      when :after_array
        raise JSON::ParserError, "unexpected content after top-level JSON array"
      else
        raise JSON::ParserError, "invalid JSON stream state"
      end
    end

    private_class_method :next_state
  end
end
