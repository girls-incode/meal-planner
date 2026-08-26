import { render } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import type { ReactElement, ReactNode } from "react";

/** A QueryClient with retries off, so failure tests don't wait on backoff. */
export function createTestQueryClient(): QueryClient {
  return new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });
}

/**
 * Wrapper for `renderHook` on hooks that need React Query. Pass a client
 * explicitly when the test needs to inspect it (e.g. spying on invalidateQueries).
 */
export function queryWrapper(queryClient: QueryClient = createTestQueryClient()) {
  return function Wrapper({ children }: { children: ReactNode }) {
    return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
  };
}

interface RenderWithProvidersOptions {
  queryClient?: QueryClient;
  /** Initial URL. Combine with `path` to exercise route params. */
  route?: string;
  /** Route pattern to mount `ui` under, e.g. "/recipes/:id". */
  path?: string;
}

/**
 * Renders a component inside React Query and a MemoryRouter. Returns the
 * usual render result plus the QueryClient in use.
 */
export function renderWithProviders(
  ui: ReactElement,
  { queryClient = createTestQueryClient(), route = "/", path }: RenderWithProvidersOptions = {},
) {
  return {
    queryClient,
    ...render(
      <QueryClientProvider client={queryClient}>
        <MemoryRouter initialEntries={[route]}>
          {path ? (
            <Routes>
              <Route path={path} element={ui} />
            </Routes>
          ) : (
            ui
          )}
        </MemoryRouter>
      </QueryClientProvider>,
    ),
  };
}
