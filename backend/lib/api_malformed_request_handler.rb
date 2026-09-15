# frozen_string_literal: true

# Handles malformed request data before Rails can dispatch to a controller.
# This middleware sits inside Rails' exception middleware, so it preserves the
# API's normal error envelope without catching unrelated application bugs.
class ApiMalformedRequestHandler
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue ActionDispatch::Http::Parameters::ParseError
    bad_request(env, "Request body must be valid JSON")
  rescue ActionController::BadRequest
    bad_request(env, "Request parameters are invalid")
  end

  private

  def bad_request(env, message)
    ApiErrorHandler.rack_response(
      status: :bad_request,
      code: "BAD_REQUEST",
      message:,
      request_id: env["action_dispatch.request_id"]
    )
  end
end
