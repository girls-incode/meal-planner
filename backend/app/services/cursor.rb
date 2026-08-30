# typed: true
# frozen_string_literal: true

# Base for the opaque pagination cursors the API hands back as `nextCursor`.
#
# Payloads are signed with a purpose-scoped MessageVerifier, so a client can
# neither forge a cursor, edit one, nor replay one minted for another endpoint
# (each purpose string derives a different key). Decode therefore only checks
# what signing cannot: that the payload shape still belongs to this deploy
# (VERSION), and that the cursor was minted for the same result set it is being
# replayed into (scope). Field-level type checks would only re-validate values
# the app itself wrote one request earlier.
class Cursor
  extend T::Sig

  VERSION = 1

  class InvalidCursor < StandardError; end

  sig { params(value: T.nilable(String)).returns(String) }
  def self.purpose(value = nil)
    @purpose = value if value
    @purpose || raise(NotImplementedError, "#{name} must declare a purpose")
  end

  # These helpers deliberately do not share the public `encode`/`decode`
  # names used by concrete cursors. Each cursor has a different input
  # contract, and Sorbet correctly rejects narrowing an inherited method
  # signature. Keeping the shared signing implementation private lets every
  # public cursor API remain fully typed without an invalid override.
  sig { params(payload: T::Hash[String, T.untyped], scope: T.untyped).returns(String) }
  private_class_method def self.encode_signed(payload, scope: nil)
    verifier.generate(payload.merge("v" => VERSION, "scope" => scope))
  end

  sig { params(value: T.untyped, scope: T.untyped).returns(T::Hash[String, T.untyped]) }
  private_class_method def self.decode_signed(value, scope: nil)
    raise InvalidCursor, "cursor is invalid" unless value.is_a?(String)

    payload = verifier.verify(value)
    raise InvalidCursor, "cursor is invalid" unless payload.is_a?(Hash) && payload["v"] == VERSION && payload["scope"] == scope

    payload
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    raise InvalidCursor, "cursor is invalid"
  end

  # Compatibility entry points for direct subclasses of Cursor. They cannot
  # have signatures: concrete cursor classes intentionally expose narrower
  # public APIs (for example, `IngredientCursor.encode(ingredient, query:)`),
  # and Sorbet runtime validates that an override accepts every base argument.
  # The shared signing and verification boundary remains typed above.
  def self.encode(payload, scope: nil)
    encode_signed(payload, scope:)
  end

  def self.decode(value, scope: nil)
    decode_signed(value, scope:)
  end

  sig { returns(ActiveSupport::MessageVerifier) }
  private_class_method def self.verifier
    Rails.application.message_verifier(purpose)
  end
end
