import "@testing-library/jest-dom/vitest";
import { afterEach, vi } from "vitest";

// Every suite here mocks via vi.spyOn; restoring globally keeps each test file
// from repeating the same afterEach hook.
afterEach(() => {
  vi.restoreAllMocks();
});

// jsdom in this Vitest setup doesn't provide a working localStorage by
// default; a minimal in-memory shim is enough for the API client's
// pantry-session-token storage in tests.
class MemoryStorage implements Storage {
  private store = new Map<string, string>();

  get length() {
    return this.store.size;
  }

  clear(): void {
    this.store.clear();
  }

  getItem(key: string): string | null {
    return this.store.get(key) ?? null;
  }

  key(index: number): string | null {
    return Array.from(this.store.keys())[index] ?? null;
  }

  removeItem(key: string): void {
    this.store.delete(key);
  }

  setItem(key: string, value: string): void {
    this.store.set(key, value);
  }
}

Object.defineProperty(globalThis, "localStorage", {
  value: new MemoryStorage(),
  writable: true,
});
