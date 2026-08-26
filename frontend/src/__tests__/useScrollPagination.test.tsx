import { render } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useScrollPagination } from "@/hooks/useScrollPagination";

type ScrollPaginationOptions = Parameters<typeof useScrollPagination>[0];

let observers: MockIntersectionObserver[] = [];

class MockIntersectionObserver {
  readonly disconnect = vi.fn();
  readonly observe = vi.fn();
  private readonly callback: IntersectionObserverCallback;
  readonly options?: IntersectionObserverInit;

  constructor(
    callback: IntersectionObserverCallback,
    options?: IntersectionObserverInit,
  ) {
    this.callback = callback;
    this.options = options;
    observers.push(this);
  }

  trigger(isIntersecting: boolean) {
    this.callback(
      [{ isIntersecting } as IntersectionObserverEntry],
      this as unknown as IntersectionObserver,
    );
  }
}

function ScrollPaginationHarness(options: ScrollPaginationOptions) {
  const loadMoreRef = useScrollPagination(options);

  return <div ref={loadMoreRef} />;
}

function renderHook(options: Partial<ScrollPaginationOptions> = {}) {
  const fetchNextPage = vi.fn();
  const result = render(
    <ScrollPaginationHarness
      fetchNextPage={fetchNextPage}
      hasNextPage
      isFetchingNextPage={false}
      isFetchNextPageError={false}
      {...options}
    />,
  );

  return { ...result, fetchNextPage };
}

afterEach(() => {
  observers = [];
  vi.unstubAllGlobals();
});

describe("useScrollPagination", () => {
  it("fetches the next page when the sentinel enters the viewport", () => {
    vi.stubGlobal("IntersectionObserver", MockIntersectionObserver);
    const { fetchNextPage } = renderHook();

    expect(observers).toHaveLength(1);
    expect(observers[0].observe).toHaveBeenCalledWith(expect.any(HTMLDivElement));
    expect(observers[0].options).toEqual({ rootMargin: "200px" });

    observers[0].trigger(false);
    expect(fetchNextPage).not.toHaveBeenCalled();

    observers[0].trigger(true);
    expect(fetchNextPage).toHaveBeenCalledOnce();
  });

  it("disconnects the observer when unmounted", () => {
    vi.stubGlobal("IntersectionObserver", MockIntersectionObserver);
    const { unmount } = renderHook();

    unmount();

    expect(observers[0].disconnect).toHaveBeenCalledOnce();
  });

  it("does not create an observer when the browser does not support it", () => {
    Reflect.deleteProperty(window, "IntersectionObserver");

    renderHook();

    expect(observers).toHaveLength(0);
  });

  it.each([
    ["there is no next page", { hasNextPage: false }],
    ["the next page is already loading", { isFetchingNextPage: true }],
    ["the previous next-page request failed", { isFetchNextPageError: true }],
  ] as const)("does not create an observer when %s", (_, options) => {
    vi.stubGlobal("IntersectionObserver", MockIntersectionObserver);

    renderHook(options);

    expect(observers).toHaveLength(0);
  });
});
