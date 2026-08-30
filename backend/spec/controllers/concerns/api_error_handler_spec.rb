# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApiErrorHandler, type: :controller do
  controller(ApplicationController) do
    def index
      request.set_header("action_dispatch.request_id", "controller-request-id")

      case params.fetch(:error)
      when "not_found"
        raise ActiveRecord::RecordNotFound, "internal model details"
      when "record_invalid"
        record = Recipe.new
        record.errors.add(:title, "is unavailable")
        raise ActiveRecord::RecordInvalid, record
      when "invalid_request"
        raise Api::InvalidRequest, "parameter is invalid"
      when "invalid_cursor"
        raise Cursor::InvalidCursor, "cursor is invalid"
      when "unresolved_input"
        raise Ingredients::UnresolvedInput.new([ "dragon fruit" ])
      when "argument_error"
        raise ArgumentError, "unexpected bug"
      end

      head :no_content
    end
  end

  it "sanitizes record-not-found errors" do
    get :index, params: { error: "not_found" }

    expect(response).to have_http_status(:not_found)
    expect(error_payload).to include(
      "code" => "NOT_FOUND",
      "message" => "The requested resource was not found",
      "requestId" => "controller-request-id"
    )
  end

  it "renders validation errors" do
    get :index, params: { error: "record_invalid" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_payload).to include(
      "code" => "INVALID_ARGUMENT",
      "message" => "Title is unavailable",
      "requestId" => "controller-request-id"
    )
  end

  {
    "invalid_request" => "parameter is invalid",
    "invalid_cursor" => "cursor is invalid",
    "unresolved_input" => "Unresolved ingredients: dragon fruit"
  }.each do |error, message|
    it "renders #{error.tr('_', ' ')} errors" do
      get :index, params: { error: }

      expect(response).to have_http_status(:unprocessable_content)
      expect(error_payload).to include(
        "code" => "INVALID_ARGUMENT",
        "message" => message,
        "requestId" => "controller-request-id"
      )
    end
  end

  it "does not convert unexpected argument errors into client errors" do
    expect { get :index, params: { error: "argument_error" } }
      .to raise_error(ArgumentError, "unexpected bug")
  end

  def error_payload
    response.parsed_body.fetch("error")
  end
end
