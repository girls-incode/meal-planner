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

  it("resolves with parsed JSON on success", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: true, status: 200, json: async () => ({ hello: "world" }) }),
    );

    await expect(apiClient.get("/api/v1/ingredients")).resolves.toEqual({ hello: "world" });
  });
});
