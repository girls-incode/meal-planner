class ApplicationController < ActionController::API
  include ApiErrorHandler

  private

  # Anonymous pantry persistence: the client generates a UUID session token
  # and sends it on every request; no user accounts.
  def current_pantry
    @current_pantry ||= Pantry.find_or_create_by!(session_token: pantry_session_token)
  end

  def require_pantry_session
    return true if uuid?(pantry_session_token)

    message = pantry_session_token.present? ? "X-Pantry-Session must be a valid UUID" : "Missing X-Pantry-Session header"
    raise Api::BadRequest, message
  end

  def pantry_session_token
    request.headers["X-Pantry-Session"]
  end

  def uuid?(value)
    value.is_a?(String) && value.match?(Pantry::SESSION_TOKEN_FORMAT)
  end

  # Parses a query param as an Integer within [minimum, maximum], raising
  # Api::InvalidRequest on anything else (missing/non-numeric/out-of-range).
  # String input is parsed with an explicit base 10, so "010" means ten and
  # a hexadecimal prefix such as "0x10" is rejected.
  def bounded_integer(key, default:, minimum: 1, maximum:)
    raw_value = params.fetch(key, default)
    value = raw_value.is_a?(String) ? Integer(raw_value, 10) : Integer(raw_value)
    raise Api::InvalidRequest, "#{key} must be between #{minimum} and #{maximum}" if value < minimum || value > maximum

    value
  rescue TypeError, ArgumentError
    raise Api::InvalidRequest, "#{key} must be an integer"
  end
end
