# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/v1/pantry_items', type: :request do
  let(:pantry_session) { SecureRandom.uuid }
  let(:ingredient) { create(:ingredient) }

  it "lists the current pantry's items in a cursor page" do
    pantry = create(:pantry, session_token: pantry_session)
    item = create(:pantry_item, pantry:, ingredient:)

    get '/api/v1/pantry-items', headers: { 'X-Pantry-Session' => pantry_session }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('nextCursor')).to be_nil
    expect(response.parsed_body.fetch('data')).to contain_exactly(
      a_hash_including('id' => item.id, 'ingredient' => { 'id' => ingredient.id, 'name' => ingredient.name })
    )
  end

  it 'creates and removes an item only in the current pantry' do
    post '/api/v1/pantry-items',
      params: { ingredientId: ingredient.id }, headers: { 'X-Pantry-Session' => pantry_session }

    item_id = response.parsed_body.fetch('id')
    expect(response).to have_http_status(:created)

    delete "/api/v1/pantry-items/#{item_id}", headers: { 'X-Pantry-Session' => pantry_session }

    expect(response).to have_http_status(:no_content)
    expect(PantryItem.exists?(item_id)).to be(false)
  end

  it 'rejects adding the same ingredient twice' do
    post '/api/v1/pantry-items', params: { ingredientId: ingredient.id }, headers: { 'X-Pantry-Session' => pantry_session }
    post '/api/v1/pantry-items', params: { ingredientId: ingredient.id }, headers: { 'X-Pantry-Session' => pantry_session }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig('error', 'code')).to eq('INVALID_ARGUMENT')
  end

  it 'requires a pantry session header and echoes the request ID' do
    get '/api/v1/pantry-items', headers: { 'X-Request-Id' => 'request-123' }

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body).to eq(
      'error' => {
        'code' => 'BAD_REQUEST',
        'message' => 'Missing X-Pantry-Session header',
        'requestId' => 'request-123'
      }
    )
    expect(response.headers['X-Request-Id']).to eq('request-123')
  end

  it 'rejects an invalid pantry session header' do
    get '/api/v1/pantry-items', headers: { 'X-Pantry-Session' => 'invalid' }

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body.dig('error', 'message')).to eq('X-Pantry-Session must be a valid UUID')
  end

  path '/api/v1/pantry-items' do
    get 'List the current pantry items' do
      tags 'Pantry Items'
      produces 'application/json'
      parameter name: 'X-Pantry-Session', in: :header, type: :string, required: true,
                description: 'Client-generated UUID identifying the anonymous pantry session'
      parameter name: :limit, in: :query, type: :integer, required: false,
                description: 'Number of items to return (1-100; default 20)'
      parameter name: :cursor, in: :query, type: :string, required: false,
                description: 'Opaque cursor from the prior response'

      response '200', 'pantry items returned' do
        schema type: :object,
               properties: {
                 data: { type: :array, items: { type: :object } },
                 nextCursor: { type: :string, nullable: true }
               },
               required: %w[data nextCursor]

        let(:'X-Pantry-Session') { pantry_session }
        run_test!
      end

      response '400', 'missing or invalid pantry session header' do
        schema '$ref' => '#/components/schemas/Error'

        let(:'X-Pantry-Session') { 'invalid' }
        run_test!
      end
    end

    post 'Add an ingredient to the pantry' do
      tags 'Pantry Items'
      consumes 'application/json'
      produces 'application/json'
      parameter name: 'X-Pantry-Session', in: :header, type: :string, required: true,
                description: 'Client-generated UUID identifying the anonymous pantry session'
      parameter name: :pantry_item, in: :body, required: true,
                description: 'Pantry item to create',
                schema: {
                  type: :object,
                  required: [ 'ingredientId' ],
                  properties: {
                    ingredientId: { type: :string, format: :uuid, description: 'ID of the ingredient to add' }
                  }
                }

      response '201', 'pantry item created' do
        schema type: :object,
               properties: {
                 id: { type: :string },
                 ingredient: {
                   type: :object,
                   properties: {
                     id: { type: :string },
                     name: { type: :string }
                   }
                 }
               }

        let(:'X-Pantry-Session') { pantry_session }
        let(:pantry_item) { { ingredientId: ingredient.id } }
        run_test!
      end

      response '422', 'ingredient already in pantry' do
        schema '$ref' => '#/components/schemas/Error'

        before { create(:pantry_item, pantry: create(:pantry, session_token: pantry_session), ingredient:) }

        let(:'X-Pantry-Session') { pantry_session }
        let(:pantry_item) { { ingredientId: ingredient.id } }
        run_test!
      end
    end
  end

  path '/api/v1/pantry-items/{id}' do
    delete 'Remove an ingredient from the pantry' do
      tags 'Pantry Items'
      parameter name: 'X-Pantry-Session', in: :header, type: :string, required: true,
                description: 'Client-generated UUID identifying the anonymous pantry session'
      parameter name: :id, in: :path, type: :string, required: true, description: 'Pantry item ID'

      response '204', 'pantry item removed' do
        let(:'X-Pantry-Session') { pantry_session }
        let(:pantry) { create(:pantry, session_token: pantry_session) }
        let(:id) { create(:pantry_item, pantry:, ingredient:).id }
        run_test!
      end

      response '404', 'pantry item not found' do
        schema '$ref' => '#/components/schemas/Error'

        let(:'X-Pantry-Session') { pantry_session }
        let(:id) { SecureRandom.uuid }
        run_test!
      end
    end
  end
end
