import { afterEach, describe, expect, it, vi } from "vitest";
import { ApiError, apiClient } from "@/api/client";

describe("apiClient error handling", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("throws an ApiError with the response status when the request fails", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: false, status: 500, json: async () => ({}) }),
    );

    await expect(apiClient.get("/api/v1/recipes/matches")).rejects.toBeInstanceOf(ApiError);
    await expect(apiClient.get("/api/v1/recipes/matches")).rejects.toMatchObject({ status: 500 });
  });

  it("uses the backend's error message from the response body when present", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: false,
        status: 422,
        json: async () => ({ error: "ingredient already in pantry" }),
      }),
    );

    const error = (await apiClient.post("/api/v1/pantry_items", { ingredient_id: "i1" }).catch((e) => e)) as ApiError;
    expect(error).toBeInstanceOf(ApiError);
    expect(error.message).toBe("ingredient already in pantry");
  });

  it("falls back to a generic message when the response body doesn't contain an error field", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: false, status: 422, json: async () => ({ some: "data" }) }),
    );

    const error = (await apiClient.post("/api/v1/pantry_items", { ingredient_id: "i1" }).catch((e) => e)) as ApiError;
    expect(error).toBeInstanceOf(ApiError);
    expect(error.message).toMatch(/Request to .* failed with 422/);
  });

  it("resolves with parsed JSON on success", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: true, status: 200, json: async () => ({ hello: "world" }) }),
    );

    await expect(apiClient.get("/api/v1/ingredients")).resolves.toEqual({ hello: "world" });
  });
});
