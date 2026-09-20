# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/v1/recipes', type: :request do
  let(:pantry_session) { SecureRandom.uuid }

  describe 'POST /api/v1/recipe-matches' do
    it 'renders malformed JSON as a structured bad request' do
      post '/api/v1/recipe-matches', params: '{', headers: {
        'CONTENT_TYPE' => 'application/json',
        'X-Request-Id' => 'malformed-json-request'
      }

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to eq(
        'error' => {
          'code' => 'BAD_REQUEST',
          'message' => 'Request body must be valid JSON',
          'requestId' => 'malformed-json-request'
        }
      )
      expect(response.headers['X-Request-Id']).to eq('malformed-json-request')
    end

    it 'returns matching recipes and pagination metadata' do
      ingredient = create(:ingredient)
      recipe = create(:recipe, canonical_ingredient_ids: [ ingredient.id ], required_ingredient_count: 1)
      create(:recipe_ingredient, recipe:, ingredient:, raw_text: '1 ingredient')

      post '/api/v1/recipe-matches',
        headers: { 'CONTENT_TYPE' => 'application/json' },
        params: { ingredients: [ ingredient.id ], limit: 1 }.to_json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch('data').first).to include(
        'id' => recipe.id, 'missingCount' => 0,
        'cuisine' => recipe.cuisine,
        'author' => { 'id' => recipe.author.id, 'name' => recipe.author.name },
        'category' => { 'id' => recipe.category.id, 'name' => recipe.category.name }
      )
      expect(response.parsed_body).to include('nextCursor' => nil)
    end

    it 'returns 20 matching recipes by default' do
      ingredient = create(:ingredient)
      create_list(:recipe, 21, canonical_ingredient_ids: [ ingredient.id ], required_ingredient_count: 1).each do |recipe|
        create(:recipe_ingredient, recipe:, ingredient:, raw_text: '1 ingredient')
      end

      post '/api/v1/recipe-matches',
        headers: { 'CONTENT_TYPE' => 'application/json' },
        params: { ingredients: [ ingredient.id ] }.to_json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch('data').size).to eq(20)
      expect(response.parsed_body.fetch('nextCursor')).to be_present
    end

    it 'requires selected canonical ingredient IDs' do
      post '/api/v1/recipe-matches', headers: { 'CONTENT_TYPE' => 'application/json' }, params: {}.to_json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig('error', 'message')).to eq('ingredients must be a non-empty array of at most 50 ingredient IDs')
    end

    it 'rejects non-UUID ingredient IDs and names the invalid ones' do
      post '/api/v1/recipe-matches',
        headers: { 'CONTENT_TYPE' => 'application/json' },
        params: { ingredients: [ 'not-a-uuid', SecureRandom.uuid, '123' ] }.to_json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig('error', 'message')).to eq('ingredients must contain UUIDs, got invalid: not-a-uuid, 123')
    end

    it 'rejects more than 50 ingredient IDs' do
      ingredients = create_list(:ingredient, 51).map(&:id)

      post '/api/v1/recipe-matches',
        headers: { 'CONTENT_TYPE' => 'application/json' },
        params: { ingredients: }.to_json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig('error', 'message')).to eq('ingredients must be a non-empty array of at most 50 ingredient IDs')
    end

    it 'rejects page-based pagination' do
      ingredient = create(:ingredient)
      post '/api/v1/recipe-matches',
        headers: { 'CONTENT_TYPE' => 'application/json' },
        params: { ingredients: [ ingredient.id ], page: 2 }.to_json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig('error', 'message')).to eq('page is not supported; use cursor')
    end
  end

  path '/api/v1/recipe-matches' do
    post 'Match recipes against selected ingredients' do
      tags 'Recipes'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :match_request, in: :body, schema: {
        type: :object,
        required: [ 'ingredients' ],
        properties: {
          ingredients: { type: :array, items: { type: :string, format: :uuid }, minItems: 1, maxItems: 50 },
          maxMissing: { type: :integer, minimum: 0, maximum: 100 },
          limit: { type: :integer, minimum: 1, maximum: 100 },
          cursor: { type: :string, nullable: true }
        }
      }

      response '200', 'matching recipes returned' do
        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :string },
                       title: { type: :string },
                       imageUrl: { type: :string, nullable: true },
                       ratings: { type: :number, nullable: true },
                       cookTimeMinutes: { type: :integer, nullable: true },
                       prepTimeMinutes: { type: :integer, nullable: true },
                       cuisine: { type: :string, nullable: true },
                       category: {
                         type: :object,
                         nullable: true,
                         properties: {
                           id: { type: :string, format: :uuid },
                           name: { type: :string }
                         }
                       },
                       author: {
                         type: :object,
                         nullable: true,
                         properties: {
                           id: { type: :string, format: :uuid },
                           name: { type: :string }
                         }
                       },
                       matchedIngredients: { type: :integer },
                       requiredIngredientCount: { type: :integer },
                       missingCount: { type: :integer },
                       matchPercentage: { type: :number },
                       missingIngredients: {
                         type: :array,
                         items: {
                           type: :object,
                           properties: {
                             id: { type: :string },
                             name: { type: :string }
                           }
                         }
                       }
                     }
                   }
                 },
                 nextCursor: { type: :string, nullable: true }
               }

        let(:match_request) { { ingredients: [ create(:ingredient).id ], maxMissing: 5 } }
        run_test!
      end

      response '422', 'invalid argument' do
        schema '$ref' => '#/components/schemas/Error'

        let(:match_request) { {} }
        run_test!
      end
    end
  end

  path '/api/v1/recipes/{id}' do
    get 'Show a recipe with its ingredients' do
      tags 'Recipes'
      produces 'application/json'
      parameter name: 'X-Pantry-Session', in: :header, type: :string, required: true,
                description: 'Client-generated UUID identifying the anonymous pantry session'
      parameter name: :id, in: :path, type: :string, required: true, description: 'Recipe ID'

      response '200', 'recipe found' do
        schema type: :object,
               properties: {
                 id: { type: :string },
                 title: { type: :string },
                 imageUrl: { type: :string, nullable: true },
                 ratings: { type: :number, nullable: true },
                 cookTimeMinutes: { type: :integer, nullable: true },
                 prepTimeMinutes: { type: :integer, nullable: true },
                 cuisine: { type: :string, nullable: true },
                 category: {
                   type: :object,
                   nullable: true,
                   properties: {
                     id: { type: :string, format: :uuid },
                     name: { type: :string }
                   }
                 },
                 author: { type: :string, nullable: true },
                 requiredIngredientCount: { type: :integer },
                 ingredients: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       ingredient: {
                         type: :object,
                         properties: {
                           id: { type: :string },
                           name: { type: :string }
                         }
                       },
                       rawText: { type: :string, nullable: true },
                       owned: { type: :boolean }
                     }
                   }
                 },
                 missingIngredients: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :string },
                       name: { type: :string }
                     }
                   }
                 }
               }

        let(:'X-Pantry-Session') { pantry_session }
        let(:id) { create(:recipe).id }
        run_test!
      end

      response '404', 'recipe not found' do
        schema '$ref' => '#/components/schemas/Error'

        let(:'X-Pantry-Session') { pantry_session }
        let(:id) { SecureRandom.uuid }
        run_test!
      end
    end
  end

  it 'marks recipe ingredients as owned by the pantry session' do
    ingredient = create(:ingredient)
    recipe = create(:recipe, canonical_ingredient_ids: [ ingredient.id ], required_ingredient_count: 1)
    create(:recipe_ingredient, recipe:, ingredient:, raw_text: '1 ingredient')

    get "/api/v1/recipes/#{recipe.id}", headers: { 'X-Pantry-Session' => pantry_session }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('ingredients').first).to include('owned' => false)

    create(:pantry_item, pantry: Pantry.find_by!(session_token: pantry_session), ingredient:)
    get "/api/v1/recipes/#{recipe.id}", headers: { 'X-Pantry-Session' => pantry_session }

    expect(response.parsed_body.fetch('ingredients').first).to include('owned' => true)
  end

  describe 'compound ingredient lines' do
    let(:salt) { create(:ingredient, name: 'salt') }
    let(:black_pepper) { create(:ingredient, name: 'black pepper') }
    let(:raw_text) { 'salt and ground black pepper to taste' }
    let(:recipe) do
      create(
        :recipe,
        canonical_ingredient_ids: [ salt.id, black_pepper.id ].sort,
        required_ingredient_count: 2
      )
    end

    before do
      create(:recipe_ingredient, recipe:, ingredient: salt, raw_text:)
      create(:recipe_ingredient, recipe:, ingredient: black_pepper, raw_text:)
    end

    it 'returns one display line' do
      get "/api/v1/recipes/#{recipe.id}", headers: { 'X-Pantry-Session' => pantry_session }

      compound_lines = response.parsed_body.fetch('ingredients').select { |line| line.fetch('rawText') == raw_text }
      expect(compound_lines).to contain_exactly(a_hash_including('owned' => false))
    end

    it 'marks the line owned only when every ingredient is in the pantry' do
      pantry = create(:pantry, session_token: pantry_session)
      create(:pantry_item, pantry:, ingredient: salt)

      get "/api/v1/recipes/#{recipe.id}", headers: { 'X-Pantry-Session' => pantry_session }
      expect(response.parsed_body.fetch('ingredients')).to contain_exactly(a_hash_including('owned' => false))

      create(:pantry_item, pantry:, ingredient: black_pepper)
      get "/api/v1/recipes/#{recipe.id}", headers: { 'X-Pantry-Session' => pantry_session }

      expect(response.parsed_body.fetch('ingredients')).to contain_exactly(a_hash_including('owned' => true))
    end
  end

  it 'returns missing ingredients for the pantry session' do
    available = create(:ingredient, name: 'available ingredient')
    missing = create(:ingredient, name: 'missing ingredient')
    recipe = create(:recipe, canonical_ingredient_ids: [ available.id, missing.id ].sort, required_ingredient_count: 2)
    create(:recipe_ingredient, recipe:, ingredient: available)
    create(:recipe_ingredient, recipe:, ingredient: missing)
    pantry = create(:pantry, session_token: pantry_session)
    create(:pantry_item, pantry:, ingredient: available)

    get "/api/v1/recipes/#{recipe.id}", headers: { 'X-Pantry-Session' => pantry_session }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('missingIngredients')).to contain_exactly(
      a_hash_including('id' => missing.id, 'name' => 'missing ingredient')
    )
  end
end
