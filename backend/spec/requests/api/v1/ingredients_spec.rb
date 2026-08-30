# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/v1/ingredients', type: :request do
  it 'searches only catalog ingredients' do
    recipe = create(:recipe)
    ingredient = create(:ingredient, name: 'tomato')
    create(:recipe_ingredient, recipe:, ingredient:, raw_text: '1 tomato')

    get '/api/v1/ingredients', params: { q: 'tom' }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      'data' => [ { 'id' => ingredient.id, 'name' => 'tomato' } ],
      'nextCursor' => nil
    )
  end

  it 'rejects an invalid cursor' do
    get '/api/v1/ingredients', params: { q: 'tom', cursor: 'invalid' }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig('error', 'code')).to eq('INVALID_ARGUMENT')
    expect(response.parsed_body.dig('error', 'message')).to eq('cursor is invalid')
  end

  it 'caps ingredient search pages at 20 items' do
    get '/api/v1/ingredients', params: { limit: 21 }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig('error', 'message')).to eq('limit must be between 1 and 20')
  end

  path '/api/v1/ingredients' do
    get 'Search ingredients' do
      tags 'Ingredients'
      produces 'application/json'
      parameter name: :q, in: :query, type: :string, required: false,
                description: 'Search term to filter ingredients by name'
      parameter name: :limit, in: :query, type: :integer, required: false,
                description: 'Number of ingredients to return (1-20; default 20)'
      parameter name: :cursor, in: :query, type: :string, required: false,
                description: 'Opaque cursor from the prior response'

      response '200', 'ingredients found' do
        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :string },
                       name: { type: :string }
                     },
                     required: %w[id name]
                   }
                 },
                 nextCursor: { type: :string, nullable: true }
               },
               required: %w[data nextCursor]

        let(:q) { '' }
        run_test!
      end

      response '200', 'only ingredients in the current recipe catalog are returned' do
        before do
          recipe = create(:recipe)
          catalog_ingredient = create(:ingredient, name: 'celery')
          create(:recipe_ingredient, recipe:, ingredient: catalog_ingredient, raw_text: '2 stalks celery')
          create(:ingredient, name: '2 stalks celery')
          legacy_percentage = create(:ingredient, name: '100% pure pumpkin')
          create(:recipe_ingredient, recipe:, ingredient: legacy_percentage, raw_text: '1 can 100% pure pumpkin')
        end

        let(:q) { 'celery' }

        run_test! do |response|
          expect(JSON.parse(response.body).fetch('data').map { |ingredient| ingredient.fetch('name') }).to eq([ 'celery' ])
        end
      end

      response '200', 'legacy percentage-prefixed ingredients are not returned' do
        before do
          recipe = create(:recipe)
          legacy_ingredient = create(:ingredient, name: '100% pure pumpkin')
          create(:recipe_ingredient, recipe:, ingredient: legacy_ingredient, raw_text: '1 can 100% pure pumpkin')
        end

        let(:q) { 'pumpkin' }

        run_test! do |response|
          expect(JSON.parse(response.body).fetch('data')).to be_empty
        end
      end
    end
  end
end
