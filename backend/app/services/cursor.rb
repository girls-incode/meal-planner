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

  # Bump this whenever a cursor's payload shape changes — for example, a new
  # sort column is added and a subclass's encode/decode must carry it too.
  # An old cursor minted before the bump still passes signature verification
  # (signing doesn't know about payload shape), so decode_signed compares
  # this value separately and rejects the mismatch cleanly instead of the
  # caller crashing on a field that no longer exists.
  VERSION = 1

  class InvalidCursor < StandardError; end

  sig { params(value: T.nilable(String)).returns(String) }
  def self.purpose(value = nil)
    @purpose = value if value
    @purpose || raise(NotImplementedError, "#{name} must declare a purpose")
  end

  # `scope` ties a cursor to the exact result set it was minted for, not just
  # the row to resume from — e.g. IngredientCursor scopes to the search
  # query string, PantryItemCursor to a pantry id. decode_signed requires the
  # scope passed in at decode time to match what's embedded in the cursor, so
  # a cursor from one search can't be replayed against a different one (which
  # would otherwise skip or repeat rows). Subclasses with an unfiltered
  # result set, like CategoryCursor, just leave scope as the nil default.
  sig { params(payload: T::Hash[String, T.untyped], scope: T.untyped).returns(String) }
  private_class_method def self.encode_signed(payload, scope: nil)
    verifier.generate(payload.merge("v" => VERSION, "scope" => scope))
  end

  sig { params(value: T.untyped, scope: T.untyped).returns(T::Hash[String, T.untyped]) }
  private_class_method def self.decode_signed(value, scope: nil)
    raise InvalidCursor, "cursor is invalid" unless value.is_a?(String)

    # Checks the signature and, if valid, deserializes back into the original
    # hash; raises InvalidSignature (rescued below) if it was tampered with.
    payload = verifier.verify(value)
    raise InvalidCursor, "cursor is invalid" unless payload.is_a?(Hash) && payload["v"] == VERSION && payload["scope"] == scope

    payload
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    raise InvalidCursor, "cursor is invalid"
  end

  # A MessageVerifier keyed off this subclass's purpose string (e.g.
  # "categories-cursor"). Rails derives a distinct signing key per purpose,
  # so a cursor signed for one endpoint fails signature verification if
  # presented to another subclass's decode — a cursor can't be replayed
  # across endpoints even if a client managed to send it there.
  sig { returns(ActiveSupport::MessageVerifier) }
  private_class_method def self.verifier
    Rails.application.message_verifier(purpose)
  end
end
