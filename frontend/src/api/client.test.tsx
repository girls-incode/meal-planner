import { afterEach, describe, expect, it, vi } from "vitest";
import { ApiError, apiClient } from "@/api/client";

function mockFetchResponse(response: { ok: boolean; status: number; body?: unknown }) {
  vi.stubGlobal(
    "fetch",
    vi.fn().mockResolvedValue({
      ok: response.ok,
      status: response.status,
      json: async () => response.body ?? {},
    }),
  );
}

describe("apiClient error handling", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("throws an ApiError with the response status when the request fails", async () => {
    mockFetchResponse({ ok: false, status: 500 });

    await expect(apiClient.get("/api/v1/recipe-matches")).rejects.toBeInstanceOf(ApiError);
    await expect(apiClient.get("/api/v1/recipe-matches")).rejects.toMatchObject({ status: 500 });
  });

  it("uses the backend's error message from the response body when present", async () => {
    mockFetchResponse({
      ok: false,
      status: 422,
      body: {
        error: {
          code: "INVALID_ARGUMENT",
          message: "ingredient already in pantry",
          requestId: "request-123",
        },
      },
    });

    const error = (await apiClient.post("/api/v1/pantry-items", { ingredientId: "i1" }).catch((e) => e)) as ApiError;
    expect(error).toBeInstanceOf(ApiError);
    expect(error.message).toBe("ingredient already in pantry");
    expect(error).toMatchObject({ code: "INVALID_ARGUMENT", requestId: "request-123" });
  });

  it("falls back to a generic message when the response body doesn't contain an error field", async () => {
    mockFetchResponse({ ok: false, status: 422, body: { some: "data" } });

    const error = (await apiClient.post("/api/v1/pantry-items", { ingredientId: "i1" }).catch((e) => e)) as ApiError;
    expect(error).toBeInstanceOf(ApiError);
    expect(error.message).toMatch(/Request to .* failed with 422/);
  });

  it("resolves with parsed JSON on success", async () => {
    mockFetchResponse({ ok: true, status: 200, body: { hello: "world" } });

    await expect(apiClient.get("/api/v1/ingredients")).resolves.toEqual({ hello: "world" });
  });
});
