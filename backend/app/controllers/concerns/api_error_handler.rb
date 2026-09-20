# frozen_string_literal: true

module ApiErrorHandler
  extend ActiveSupport::Concern

  def self.payload(code:, message:, request_id:)
    {
      error: {
        code:,
        message:,
        requestId: request_id
      }
    }
  end

  # Renders the same error envelope as render_error, for use outside the
  # controller/rescue_from lifecycle (e.g. Rack middleware handling errors
  # before Rails dispatches to a controller).
  def self.rack_response(status:, code:, message:, request_id:)
    body = JSON.generate(payload(code:, message:, request_id:))
    [ Rack::Utils.status_code(status), { "content-type" => "application/json; charset=utf-8", "content-length" => body.bytesize.to_s }, [ body ] ]
  end

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
    rescue_from Api::InvalidRequest, Cursor::InvalidCursor, with: :render_invalid_argument
    rescue_from Api::BadRequest, with: :render_bad_request
  end

  private

  def render_not_found(_exception)
    render_error(status: :not_found, code: "NOT_FOUND", message: "The requested resource was not found")
  end

  def render_record_invalid(exception)
    render_error(
      status: :unprocessable_content,
      code: "INVALID_ARGUMENT",
      message: exception.record.errors.full_messages.join(", ")
    )
  end

  def render_bad_request(exception)
    render_error(status: :bad_request, code: "BAD_REQUEST", message: exception.message)
  end

  def render_invalid_argument(exception)
    render_error(status: :unprocessable_content, code: "INVALID_ARGUMENT", message: exception.message)
  end

  def render_error(status:, code:, message:)
    render json: ApiErrorHandler.payload(code:, message:, request_id: request.request_id), status:
  end
end
