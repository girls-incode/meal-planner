import { useEffect, useRef } from "react";

type ScrollPaginationOptions = {
  fetchNextPage: () => void;
  hasNextPage: boolean;
  isFetchingNextPage: boolean;
  isFetchNextPageError: boolean;
};

/*
 * Infinite scroll: attach `loadMoreRef` to a sentinel element at the end of
 * the list. An IntersectionObserver watches that sentinel, and once it
 * scrolls within 200px of the viewport, fetchNextPage() is called. No
 * observer is created (or an existing one is torn down) while there's
 * nothing left to fetch, a fetch is already in flight, the previous fetch
 * failed, or the browser doesn't support IntersectionObserver.
 */
export function useScrollPagination({
  fetchNextPage,
  hasNextPage,
  isFetchingNextPage,
  isFetchNextPageError,
}: ScrollPaginationOptions) {
  const loadMoreRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const sentinel = loadMoreRef.current;
    if (
      !sentinel ||
      !hasNextPage ||
      isFetchingNextPage ||
      isFetchNextPageError ||
      !("IntersectionObserver" in window)
    ) {
      return;
    }

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          fetchNextPage();
        }
      },
      { rootMargin: "200px" },
    );

    observer.observe(sentinel);
    return () => observer.disconnect();
  }, [fetchNextPage, hasNextPage, isFetchingNextPage, isFetchNextPageError]);

  return loadMoreRef;
}
