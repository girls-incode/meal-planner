# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/categories", type: :request do
  it "lists only categories used by recipes in name order" do
    dinner = create(:category, name: "Dinner")
    breakfast = create(:category, name: "Breakfast")
    unused = create(:category, name: "Unused")
    create(:recipe, category: dinner)
    create(:recipe, category: breakfast)

    get "/api/v1/categories"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "data" => [
        { "id" => breakfast.id, "name" => "Breakfast" },
        { "id" => dinner.id, "name" => "Dinner" }
      ],
      "nextCursor" => nil
    )
    expect(response.parsed_body.fetch("data")).not_to include(a_hash_including("id" => unused.id))
  end

  it "paginates categories with a default limit of 20" do
    categories = 21.times.map do |index|
      category = create(:category, name: format("Category %02d", index))
      create(:recipe, category:)
      category
    end

    get "/api/v1/categories"

    expect(response).to have_http_status(:ok)
    first_page = response.parsed_body
    expect(first_page.fetch("data").size).to eq(20)
    expect(first_page.fetch("data").map { |category| category.fetch("id") }).to eq(categories.first(20).map(&:id))
    expect(first_page.fetch("nextCursor")).to be_present

    get "/api/v1/categories", params: { cursor: first_page.fetch("nextCursor") }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "data" => [ { "id" => categories.last.id, "name" => categories.last.name } ],
      "nextCursor" => nil
    )
  end

  it "rejects an invalid cursor" do
    get "/api/v1/categories", params: { cursor: "invalid" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "code")).to eq("INVALID_ARGUMENT")
    expect(response.parsed_body.dig("error", "message")).to eq("cursor is invalid")
  end

  path "/api/v1/categories" do
    get "List recipe categories" do
      tags "Categories"
      produces "application/json"
      parameter name: :limit, in: :query, required: false, schema: { type: :integer, minimum: 1, maximum: 100, default: 20 }
      parameter name: :cursor, in: :query, required: false, schema: { type: :string }

      response "200", "categories found" do
        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :string, format: :uuid },
                       name: { type: :string }
                     },
                     required: %w[id name]
                   }
                 },
                 nextCursor: { type: :string, nullable: true }
               },
               required: %w[data nextCursor]

        run_test!
      end
    end
  end
end
