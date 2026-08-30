# syntax=docker/dockerfile:1

# Multi-stage build: compile a React/TypeScript/Vite SPA, then serve it from
# unprivileged Nginx. The API URL is baked into the bundle at build time.
#
# The app is organized by feature (src/features/{categories,pantry,recipes}),
# with shared components, API client, routing, and error handling at the top
# level. Each feature owns its own API, hooks, components, and pages.

FROM node:22-alpine AS build
  WORKDIR /app

  # Install dependencies
  COPY package.json pnpm-lock.yaml ./
  RUN corepack enable && pnpm install --frozen-lockfile

  # Copy source (organized by feature: src/features/{categories,pantry,recipes})
  COPY . .

  # Vite bakes environment variables into the bundle at build time.
  # VITE_API_BASE_URL must be set; it defaults to http://localhost:3000.
  # Override with --build-arg VITE_API_BASE_URL=<your-api-url> when building
  # for production.
  ARG VITE_API_BASE_URL=http://localhost:3000
  ENV VITE_API_BASE_URL=$VITE_API_BASE_URL

  # Build the Vite bundle (dist/ folder with fingerprinted assets)
  RUN pnpm build

FROM nginxinc/nginx-unprivileged:1.27-alpine AS production
  # Copy Nginx config: handles asset caching (1 year for fingerprinted assets),
  # no-cache for index.html, and SPA routing (unknown paths → index.html for
  # React Router to handle client-side routes like /recipes/:id).
  COPY nginx.conf /etc/nginx/conf.d/default.conf

  # Copy compiled Vite bundle from build stage
  COPY --from=build /app/dist /usr/share/nginx/html

  EXPOSE 8080

  CMD ["nginx", "-g", "daemon off;"]
