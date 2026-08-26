const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? "http://localhost:3000";
const PANTRY_TOKEN_KEY = "pantry_session_token";

function getPantryToken(): string {
  let token = localStorage.getItem(PANTRY_TOKEN_KEY);
  if (!token) {
    token = crypto.randomUUID();
    localStorage.setItem(PANTRY_TOKEN_KEY, token);
  }
  return token;
}

export class ApiError extends Error {
  status: number;

  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const response = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      "X-Pantry-Session": getPantryToken(),
      ...options.headers,
    },
  });

  if (!response.ok) {
    let message = `Request to ${path} failed with ${response.status}`;
    try {
      const body = (await response.json()) as { error?: string };
      if (body.error) {
        message = body.error;
      }
    } catch {
      // Fallback to generic message if response body is not JSON or doesn't contain error field
    }
    throw new ApiError(response.status, message);
  }

  if (response.status === 204) {
    return undefined as T;
  }

  return (await response.json()) as T;
}

export const apiClient = {
  get: <T>(path: string) => request<T>(path),
  post: <T>(path: string, body?: unknown) =>
    request<T>(path, { method: "POST", body: body ? JSON.stringify(body) : undefined }),
  delete: <T>(path: string) => request<T>(path, { method: "DELETE" }),
};
