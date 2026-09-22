# Recipe Finder — Backend

Rails API-only backend for the recipe-matching prototype. It imports and normalizes a recipe catalogue, keeps an anonymous pantry, and ranks recipes by the share of each recipe's required ingredients that are selected.

## Requirements

- Ruby 3.3.8
- Rails 8.1.3
- PostgreSQL 16 with the `pg_trgm` extension

## Setup

```bash
cd backend
gem install bundler
bundle install

# Configure environment variables (see .env.example)
cp .env.example .env

# Create and migrate the development database
bin/rails db:create db:migrate

# Prepare the test database before running the test suite
RAILS_ENV=test bin/rails db:prepare

bin/rails db:seed
```

`db:seed` downloads the gzip JSON source configured by `RECIPES_SOURCE_URL` (see `.env.example`). The importer verifies HTTPS and gzip content, limits the compressed download to 20 MB, then parses the expanded JSON payload (limited to 25 MB) once, buffering validated recipe documents while it builds catalogs before persisting those documents in batches.
Each run records an `ImportRun`.

To run the same import directly:

```bash
bin/rails runner 'ImportRecipesJob.perform_now'
```

## Running the server

```bash
bin/rails server
```

The API is served at `http://localhost:3000/api/v1`. A pantry is identified by an `X-Pantry-Session` request header containing a client-generated UUID. There are no user accounts; sessions are anonymous.

### Docker development

From the repository root, start the backend and the frontend:

```bash
docker compose up --build
```

### Docker image

The production Dockerfile builds a multi-stage Rails image with only runtime gems and packages. Build it from this directory:

```bash
docker build -t backend .
docker run -d --name backend -p 80:80 \
  -e RAILS_MASTER_KEY=<value from config/master.key> \
  -e DATABASE_URL=<production postgres URL> \
  backend
```

### Endpoints

| Method | Path | Description |
|---|---|---|
| `GET`    | `/api/v1/ingredients?q=&limit=&cursor=` | Cursor-paginated canonical ingredient catalog (pantry picker) |
| `GET`    | `/api/v1/categories?limit=&cursor=` | Cursor-paginated recipe categories |
| `GET`    | `/api/v1/pantry-items?limit=&cursor=` | Cursor-paginated current pantry items (resolved via `X-Pantry-Session`) |
| `POST`   | `/api/v1/pantry-items` | Add an ingredient to the pantry (`{ "ingredientId": "..." }`) |
| `DELETE` | `/api/v1/pantry-items/:id` | Remove an ingredient from the pantry |
| `POST`   | `/api/v1/recipe-matches` | Recipes ranked by selected canonical ingredient IDs |
| `GET`    | `/api/v1/recipes/:id` | Recipe detail with owned/missing ingredient indicators |

Example:

```bash
curl -H "X-Pantry-Session: 00000000-0000-0000-0000-000000000001" \
  -X POST -H "Content-Type: application/json" \
  -d '{"ingredientId":"<uuid from /ingredients search>"}' \
  http://localhost:3000/api/v1/pantry-items

curl -X POST -H "Content-Type: application/json" \
  -d '{"ingredients":["<uuid from /ingredients search>"],"limit":20}' \
  http://localhost:3000/api/v1/recipe-matches
```

`X-Pantry-Session` must be a UUID. Recipe matching does not require a pantry session because ingredient IDs can be submitted directly. It identifies an anonymous pantry rather than an account; treat it as a bearer capability. The first valid pantry request creates that session's empty pantry when needed.

### Recipe matching pagination

`POST /api/v1/recipe-matches` accepts:

```json
{
  "ingredients": ["<ingredient UUID>"],
  "maxMissing": 5,
  "limit": 20,
  "cursor": "<opaque cursor from the previous response>"
}
```

`limit` defaults to 20 and may be set from 1 to 100. `maxMissing` defaults to 4 and may be set from 0 to 100. The response is an object rather than a bare array:

```json
{
  "data": [],
  "nextCursor": "<opaque cursor>"
}
```

The `ingredients` array must contain 1 to 50 UUIDs; duplicate IDs are ignored and unknown IDs are rejected.

`GET /api/v1/categories` and `GET /api/v1/pantry-items` use the same `{ data, nextCursor }` cursor response shape; their `limit` defaults to 20 and is capped at 100.
Ingredient search also defaults to 20 and is capped at 20. 
`POST /api/v1/recipe-matches` uses that response shape as well. Match results include category and author objects, match counts and percentage, and the missing ingredients for each returned recipe. Recipe detail returns the author name, parsed ingredient-line metadata, `owned` flags, and missing ingredients for the pantry session.

Client errors use `{ "error": { "code", "message", "requestId" } }`. The API returns `400` for malformed JSON, invalid request parameters, or a missing or malformed pantry-session header; `404` for a resource outside the requested scope; and `422` for invalid match inputs or duplicate pantry items.

### Pagination cursors

The three cursor-paginated `GET` endpoints and `POST /api/v1/recipe-matches` share one base class, `Cursor` (`app/services/cursor.rb`). Each cursor is a payload signed with a purpose-scoped `Rails.application.message_verifier`, so a client cannot forge a cursor, edit one, or replay one minted for a different endpoint — each purpose string derives a distinct signing key.

`decode` validates only what signing cannot:

- **version** — a cursor signed by a previous deploy, whose payload shape has since changed, is still validly signed; `VERSION` is what rejects it.
- **scope** — a cursor is only meaningful inside the result set it was minted from.

A cursor that fails either check — or whose signature does not verify — raises `Cursor::InvalidCursor`, rescued once in `ApplicationController` into a `422` with the message `cursor is invalid`.

Subclasses therefore carry only a purpose and a payload builder:

```ruby
class IngredientCursor < Cursor
  purpose "ingredients-cursor"

  def self.encode(ingredient, query:)
    super({ "name" => ingredient.name, "id" => ingredient.id }, scope: query)
  end

  def self.decode(value, query:)
    super(value, scope: query)
  end
end
```

Changing a cursor's payload shape invalidates cursors issued by the previously running version. In-flight paginators receive one `422` and restart from the first page.

### API docs (Swagger/OpenAPI)

Generated from the request specs via `rswag`:

```bash
bundle exec rails rswag:specs:swaggerize
bin/rails server
# http://localhost:3000/api-docs
```

### Request workflow

The normal user journey is: choose ingredients, find matching recipes, then open a recipe to see which ingredients are owned or missing.

```mermaid
flowchart TD
  C[Client]
  I["GET /ingredients?q=...\nSearch canonical ingredients"]
  P["POST /pantry-items\nSave selected ingredient"]
  M["POST /recipe-matches\nValidate, rank, filter, paginate\nLoad missing ingredients in one batch"]
  D["GET /recipes/:id\nRecipe details with owned/missing indicators"]

  C --> I
  I --> P
  I --> M
  P --> D
  M --> D
```

`/recipe-matches` accepts selected ingredient IDs directly, so saving them to the pantry is optional for matching. A pantry session is required for pantry endpoints and recipe details.

## Architecture

This is a Rails 8.1 API-only modular monolith. A single application owns the HTTP API, domain services, background jobs, and PostgreSQL persistence. There is no user authentication or external message broker: an anonymous pantry is created on demand from the client-supplied `X-Pantry-Session` UUID, and pantry events are in-process `ActiveSupport::Notifications` events.

```mermaid
flowchart LR
  Client[Web client]

  subgraph Rails["Rails API application"]
    API["/api/v1 controllers\nvalidation, HTTP status, JSON response"]
    Session["ApplicationController\nanonymous pantry-session guard"]
    Services["Domain services\nmatching, pantry mutations, cursors, import, normalization"]
    Serializers["Serializers\ncamelCase API representations"]
    Jobs["ActiveJob jobs\nimport"]
    Events["pantry.updated\nActiveSupport::Notifications subscriber"]
  end

  Database[("PostgreSQL\nnormalized catalog")]
  Source["Configured gzip JSON source"]

  Client --> API
  API --> Session
  API --> Services
  Services --> Serializers
  Services <--> Database
  Services --> Events
  Jobs --> Services
  Jobs --> Source
```

Controllers remain thin: they validate request shape, establish the current pantry when required, call a service or query scope, and serialize the result. 
The domain layer contains the substantial work: ingredient parsing and canonicalization, bounded/batched import, pantry mutations, signed cursor handling, and recipe matching. 
Active Record models express associations and integrity rules; PostgreSQL enforces the corresponding foreign keys and unique indexes.

Recipe matching is relational and explainable. `recipe_ingredients` is the source of truth; `recipes.canonical_ingredient_ids` is a transactionally maintained `uuid[]` projection with a GIN index for complete matches. 
Partial matches use the normalized join table. There is no search-document table, embedding runtime, vector index, external search service, or result cache.

The current event subscriber logs `pantry.updated`; it is an extension seam for cache invalidation or asynchronous side effects, not a message queue.

### Database schema

```mermaid
erDiagram
  PANTRIES ||--o{ PANTRY_ITEMS : "1:N"
  INGREDIENTS ||--o{ PANTRY_ITEMS : "1:N"

  RECIPES ||--o{ RECIPE_INGREDIENTS : "1:N"
  INGREDIENTS ||--o{ RECIPE_INGREDIENTS : "1:N"
  AUTHORS o|--o{ RECIPES : "1:N"
  CATEGORIES o|--o{ RECIPES : "1:N"

  IMPORT_RUNS ||--o{ INGREDIENT_PARSE_ERRORS : "1:N"
  RECIPES o|--o{ INGREDIENT_PARSE_ERRORS : "1:N"

  PANTRIES {
    UUID id PK
    VARCHAR session_token UK
    TIMESTAMP created_at
    TIMESTAMP updated_at
  }

  PANTRY_ITEMS {
    UUID id PK
    UUID pantry_id FK
    UUID ingredient_id FK
    DECIMAL quantity
    VARCHAR unit
    TIMESTAMP created_at
    TIMESTAMP updated_at
  }

  AUTHORS {
    UUID id PK
    VARCHAR name UK
    TIMESTAMP created_at
    TIMESTAMP updated_at
  }

  CATEGORIES {
    UUID id PK
    VARCHAR name UK
    TIMESTAMP created_at
    TIMESTAMP updated_at
  }

  RECIPES {
    UUID id PK
    VARCHAR title
    INTEGER prep_time_minutes
    INTEGER cook_time_minutes
    FLOAT ratings
    VARCHAR cuisine
    UUID category_id FK "nullable"
    UUID author_id FK "nullable"
    VARCHAR image_url
    INTEGER required_ingredient_count
    UUID_ARRAY canonical_ingredient_ids
    TIMESTAMP created_at
    TIMESTAMP updated_at
  }

  INGREDIENTS {
    UUID id PK
    VARCHAR name UK "lowercase canonical form"
    TIMESTAMP created_at
    TIMESTAMP updated_at
  }

  RECIPE_INGREDIENTS {
    UUID id PK
    UUID recipe_id FK
    UUID ingredient_id FK
    DECIMAL quantity
    VARCHAR unit
    TEXT preparation
    TEXT qualifier
    TEXT raw_text
    TIMESTAMP created_at
    TIMESTAMP updated_at
  }

  IMPORT_RUNS {
    UUID id PK
    VARCHAR source_url
    VARCHAR source_fingerprint
    VARCHAR parser_version
    VARCHAR status
    INTEGER recipes_seen
    INTEGER recipes_imported
    INTEGER ingredients_created
    INTEGER ingredients_normalized
    INTEGER parse_errors
    TEXT error_message
    TIMESTAMP started_at
    TIMESTAMP finished_at
    TIMESTAMP created_at
    TIMESTAMP updated_at
  }

  INGREDIENT_PARSE_ERRORS {
    UUID id PK
    UUID import_run_id FK
    UUID recipe_id FK "nullable"
    VARCHAR original_text
    VARCHAR parser_version
    TEXT error
    TIMESTAMP created_at
    TIMESTAMP updated_at
  }
```

`IMPORT_RUNS` and `INGREDIENT_PARSE_ERRORS` are audit tables. Each error is always attached to one import run and may be attached to the recipe whose line failed parsing; malformed source data does not abort the whole import.

- **`required_ingredient_count` on Recipe** (denormalized): Updated whenever the shared recipe-ingredient writer replaces a recipe's ingredients. Enables filtering "recipes missing ≤ 2 ingredients" without subqueries.
- **Lowercase ingredient names**: Import and model writes canonicalize names to lowercase; the trigram GIN index on `(name::text)` enables case-insensitive ILIKE search.
- **Pantry cursor index**: `pantry_items(pantry_id, created_at, id)` supports scoped keyset pagination in stable creation order without offset scans.
- **Recipe-backed picker catalog**: `/ingredients` returns only ingredients referenced by the current recipe import, keeping stale orphaned rows out of the pantry picker.
- **Two-phase matching read path**: `RecipeMatcher` finds complete matches through the GIN-indexed `recipes.canonical_ingredient_ids` projection, then falls back to the normalized `(ingredient_id, recipe_id)` index only when the page still needs partial matches.
- **Cursor-based pagination**: `GET /api/v1/ingredients`, `GET /api/v1/categories`, `GET /api/v1/pantry-items`, and `POST /api/v1/recipe-matches` return `{ data, nextCursor }`. Pass the opaque `nextCursor` as `cursor` to fetch the next page; `page` is not supported for matching. Cursors are signed and scoped to the search they were minted from — see [Pagination cursors](#pagination-cursors).
- **PostgreSQL UUIDs**: model and bulk-import writes use PostgreSQL's `gen_random_uuid()` defaults consistently; bulk operations do not depend on model callbacks.

## Data ingestion

`RecipeImport::Importer` owns the import workflow. It reads and parses the bounded JSON array once, buffers validated documents while building catalogs, and persists those documents in batches of 500 rather than issuing a query per ingredient line. Re-running it replaces each imported recipe's join rows and refreshes the canonical-ID projection, so parsing and normalization changes repair existing imports.

### Ingestion pipeline

```mermaid
flowchart TD
  S["Configured .json.gz source"]
  D["ImportRecipesJob\nHTTPS download to binary tempfile"]

  subgraph PASS1["Parse bounded JSON once and build catalogs"]
    V[Validate recipe]
    L["Ingredients::LineParser\nExtract quantity, unit, and name"]
    N["Ingredients::Normalizer\nCreate canonical ingredient names"]
    U["Upsert ingredients, categories, and authors"]
    V --> L --> N --> U
  end

  subgraph PASS2["Persist buffered documents in batches"]
    R["Upsert recipes"]
    RI["Replace recipe_ingredients\nand canonical projection"]
    R --> RI
  end

  S --> D --> V
  U --> R
```

### Normalization pipeline

`Ingredients::Normalizer` is a series of syntactic transformations. It **never merges ingredients** — "almond flour" stays separate from "flour".

```mermaid
flowchart TD
  A["Input: 1 pound (1/2-inch thick) pork chops, sliced"]
  B["Downcase and strip"]
  C["Remove parentheticals\n1 pound pork chops, sliced"]
  D["Remove quantity and known unit\npork chops, sliced"]
  E["Keep ingredient segment before comma or dash\npork chops"]
  F["Remove trailing qualifiers\nto taste, as needed"]
  G["Remove leading descriptors\nfresh, chopped, diced"]
  H["Remove package percentage claims\n100% pure pumpkin → pure pumpkin"]
  Z["Canonical ingredient: pork chops"]

  A --> B --> C --> D --> E --> F --> G --> H --> Z
```

**Compound splitting** ("salt and black pepper"): Only splits if **both halves already exist as ingredients** in the corpus. This prevents false splits like "garlic and herb seasoning" (where "herb seasoning" isn't an ingredient by itself).

### Deliberate current boundaries

- `recipe_ingredients` remains the normalized source of truth. The
  GIN-indexed `canonical_ingredient_ids` projection is maintained in the same transaction by `RecipeIngredients::Replace`; direct association writes are not supported.
- The importer is idempotent and bulk-oriented. It makes one bounded JSON
  parsing pass, buffers validated documents for catalog construction, then persists them in batches of 500 while recording import-run audit data and parser versioning. The remote-import job downloads the gzip source to a binary temporary file before the importer reads it.
- `recipe_ingredients` is intentionally distinct by `(recipe_id,
  ingredient_id)` because matching is availability-based rather than quantity-based. If preserving duplicate source lines becomes a product requirement, introduce a separate ordered ingredient-line model while retaining the distinct relation as the matching projection.

## Recipe matching algorithm (RecipeMatcher)

The `POST /api/v1/recipe-matches` endpoint ranks recipes by the **percentage of each recipe's required canonical ingredients that are selected**, then by fewer missing ingredients, then by rating. The complete-match phase uses an indexed per-recipe projection.
Only when that phase cannot fill the requested page does the matcher count normalized `recipe_ingredients` rows for partial matches.

### Matching workflow

After the controller validates the submitted UUIDs, matching finds complete matches first and queries normalized rows only for the remaining partial slots:

```mermaid
flowchart TD
  A[Selected ingredient IDs]
  B[Validate IDs exist]
  C["GIN: canonical_ingredient_ids <@ selected IDs\nRank complete matches"]
  D{Complete matches fill page?}
  E["Join recipe_ingredients\n(ingredient_id, recipe_id) index"]
  F["Count matched ingredients\nFilter and rank partial matches"]
  G["Combine and paginate"]
  H[Page of recipe IDs]
  I["One batched query\nfor missing ingredients"]
  J[JSON recipe matches]

  A --> B --> C --> D
  D -- No --> E --> F --> G
  D -- Yes --> G
  G --> H --> I --> J
```

The endpoint validates the submitted ingredient IDs, finds and ranks up to `limit + 1` recipes, and loads missing ingredients for the returned page in a single batch. The last step does not issue one query per recipe (no N+1 query). The opaque cursor records whether it ended in the complete or partial phase, so a transition between the two cannot skip or repeat results and avoids offset scans.

### Scaling options

`recipes.canonical_ingredient_ids` is a sorted, distinct `uuid[]` projection kept transactionally in sync with `recipe_ingredients`. Its GIN index serves the complete-match phase (recipes whose full canonical ingredient set is contained in the selected IDs). 
Partial matching remains normalized and uses the ingredient-leading `recipe_ingredients` index, because exact partial-match ranking still has to count the selected ingredients for every candidate.

The current workload does not use a materialized view, cache table, external search service, or vector store. Add one only after production query profiling shows that the relational path is not meeting the required latency.

### Match percentage calculation

For each recipe in the result set:

- **matched** = count of recipe ingredients included in the selected IDs
- **required** = `recipe.required_ingredient_count` (stored at seed time)
- **match %** = `matched / required × 100`
- **missing** = `required - matched` (must be ≤ the `max_missing` threshold to include recipe)

**Example**: Recipe requires 8 ingredients, pantry has 6 of them:
- matched = 6
- required = 8
- match % = 75%
- missing = 2

This recipe is included if the threshold allows ≥ 2 missing ingredients.

## Testing

```bash
bundle exec rspec
```

`spec/services/cursor_spec.rb` exercises the shared cursor layer once — round-trip, tampering, scope mismatch, and replay across cursor classes — rather than repeating those cases per endpoint.

## Linting & static typing

```bash
bundle exec rubocop        # style (rubocop-rails-omakase base + rspec/performance cops)
bundle exec rubocop -A     # auto-fix
bundle exec srb tc         # Sorbet typecheck (scoped to app/services)
```

Sorbet RBIs are generated via [Tapioca](https://github.com/Shopify/tapioca) and are committed with the code they describe:

```bash
bundle exec tapioca gems  # after Gemfile.lock changes
bundle exec tapioca dsl   # after model, association, or schema changes
bundle exec srb tc        # verify the generated RBIs and service types
```

## Domain events

Pantry mutations publish an `ActiveSupport::Notifications` event (`pantry.updated`) that `app/events/pantry_subscriber.rb` logs — an in-process seam for future cache invalidation, no external broker.

## Further improvements

### Semantic recipe discovery

The current matcher is intentionally exact and explainable: recipes are ranked by canonical ingredient coverage. A future semantic-discovery feature could also support intent-based searches such as “quick vegetarian comfort food” and surface recipes whose wording does not exactly match the user’s query.

That capability should be a separate candidate-generation stage: embed recipe content and the user query, retrieve a bounded candidate set with a vector index, then apply the existing exact ingredient and dietary filters before ranking. Exact ingredient coverage should remain the explanation shown to the user and the source of truth for match ranking.

This is not part of the current runtime. It would require an embedding provider, a vector-capable PostgreSQL extension and table, background generation/backfill jobs, and a product decision about how semantic candidates interact with exact-match pagination.

### Multi-language ingredient parsing

`Ingredients::LineParser` and `Ingredients::Normalizer` are English-only today. `UNIT_PATTERN`, `PREPARATION_WORDS`, `LEADING_DESCRIPTORS`, and the English connective word "of" are hardcoded class constants, and unit singularization relies on Rails' English inflector (`String#singularize`).

Supporting other languages would require:

- **Locale as an explicit pipeline input.**
Threading a `locale` through `Importer` → `LineParser.new(locale:)` → `Normalizer.new(locale:)`, driven by the import source rather than inferred from ingredient text — language detection on short ingredient strings is unreliable and adds a failure mode that isn't needed if the source already implies its language.
- **Locale-keyed vocabulary instead of Ruby constants.** 
Unit names, preparation words, and connectors are finite per language. Move them from hardcoded Ruby constants into per-locale config files (e.g. `config/locales/ingredient_units.<locale>.yml`), loaded and cached per locale:
  - **Closed-class vocabulary** — ~50 units per language, bounded and static (unlike ingredients, which scale with the catalog)
  - **Scales to multiple languages** — adding Spanish is just a new YAML file; no code changes or parser subclasses needed
  - **Single upfront load** — no runtime language detection or guessing; the import job declares `locale: :en` and the config loads once for the batch
- **Avoiding runtime singularization entirely.** 
Rails' `String#singularize` has bugs (e.g., "cloves" → "clofe"), fixed case-by-case in `config/initializers/inflections.rb`. Don't derive singular forms at parse time; instead, store both singular and plural forms explicitly in per-locale config. This avoids the fragile inflection engine entirely and works for all languages:

```ruby
# Rather than:
"cups".singularize  # Risky, language-specific

# Store forms directly:
EN_UNITS = { singular: "cup", plural: "cups" }
ES_UNITS = { singular: "taza", plural: "tazas" }
# Parser looks up whichever form it needs
```
- **Locale-specific structural parsing.** 
English drops the connector "of" ("1 cup of flour" → parse as "1 cup flour"), but other languages differ: Spanish/French use "de", German omits it. Instead of building separate parsers per language, create one shared `LineParser` class that accepts locale-keyed configuration for vocabulary, unit names, and connectors. Only fork into per-language strategies if a language's ingredient grammar is fundamentally incompatible (unlikely). Example:

```ruby
# One class, swappable config — not three separate parsers
LineParser.new(locale: :en, vocabulary: EN_UNITS, connectors: ["of"])
LineParser.new(locale: :es, vocabulary: ES_UNITS, connectors: ["de"])
LineParser.new(locale: :de, vocabulary: DE_UNITS, connectors: [])
```

### Production deployment

The checked-in `config/deploy.yml` is a Kamal template. Before deploying, replace its server, registry, and proxy values, then provide secrets through your deployment environment:

- `RAILS_MASTER_KEY`
- `DATABASE_URL`
- `FRONTEND_ORIGIN`
- `RECIPES_SOURCE_URL`

## Project structure

```
app/
  controllers/api/v1/      # thin controllers: ingredients, categories,
                           # pantry items, recipe matches, recipe detail
  errors/api/              # Api::InvalidRequest and Api::BadRequest
  events/                  # PantrySubscriber — ActiveSupport::Notifications
  jobs/                    # ImportRecipesJob
  models/                  # Recipe, Ingredient, RecipeIngredient, Author,
                           # Category, Pantry, PantryItem, ImportRun,
                           # IngredientParseError
  serializers/             # lightweight camelCase JSON modules
  services/
    ingredients/           # LineParser and Normalizer
    recipe_import/         # Importer, BatchWriter, RecipeValidator
    pantry_items/          # Create, Destroy (publish `pantry.updated`)
    recipe_matcher.rb      # matching algorithm
    cursor.rb              # signed-cursor base: verify, version, scope
    ingredient_cursor.rb, category_cursor.rb,
    pantry_item_cursor.rb, recipe_match_cursor.rb
                           # Cursor subclasses: a purpose + a payload builder
config/
  initializers/pantry_events.rb   # subscribes PantrySubscriber in to_prepare
  initializers/cors.rb            # /api/v1/* only, FRONTEND_ORIGIN in prod
  deploy.yml                      # Kamal deployment template
  ci.rb                           # pipeline run by bin/ci
db/
  migrate/
  schema.rb
  seeds.rb
spec/
  models/                  # Recipe, Ingredient, Author, Category
  services/                # matcher, cursor, ingredients/, recipe_import/
  requests/api/v1/         # every endpoint, written in the rswag DSL
  factories/, support/     # FactoryBot factories, QueryCounter for N+1 asserts
sorbet/                    # Sorbet config and Tapioca-generated RBIs
swagger/                   # generated OpenAPI document served at /api-docs
```
