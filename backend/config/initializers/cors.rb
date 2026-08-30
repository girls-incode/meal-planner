# Frontend and backend are deployed as two separate Fly apps (see README /
# deployment docs), so the SPA calls the API cross-origin and needs an
# explicit CORS policy. Restricted to /api/v1/* and the methods/headers the
# frontend actually uses.
#
# In development we also allow the Swagger UI's own origin(s), since
# "Try it out" issues a same-machine but cross-origin fetch whenever the
# page is loaded from a host/port ({defaultHost} in swagger.yaml) that
# differs from whatever host the browser used to open /api-docs
# (localhost vs 127.0.0.1 count as different origins).
default_dev_origins = %w[http://localhost:3000 http://127.0.0.1:3000 http://localhost:5173]
frontend_origin = ENV["FRONTEND_ORIGIN"]
if Rails.env.production? && frontend_origin.blank?
  raise "FRONTEND_ORIGIN must be configured in production"
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins frontend_origin || default_dev_origins

    resource "/api/v1/*",
      headers: :any,
      expose: %w[X-Pantry-Session],
      methods: %i[get post delete options]
  end
end
