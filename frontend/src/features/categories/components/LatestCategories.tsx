import { useCategories } from "@/features/categories/hooks/useCategories";

export function LatestCategories() {
  const { data, isLoading, isError } = useCategories(10);

  return (
    <section
      className="mt-6 rounded-2xl border border-border bg-card p-4"
      aria-labelledby="latest-categories-title"
    >
      <h2
        id="latest-categories-title"
        className="text-sm font-medium text-foreground"
      >
        Latest categories
      </h2>
      {isLoading && (
        <p className="mt-2 text-sm text-muted-foreground">
          Loading categories…
        </p>
      )}
      {isError && (
        <p className="mt-2 text-sm text-muted-foreground">
          Categories are unavailable right now.
        </p>
      )}
      {data && (
        <div className="mt-3 flex flex-wrap gap-2">
          {data.data.map((category) => (
            <span
              key={category.id}
              className="rounded-full border border-border bg-secondary px-3 py-1.5 text-sm text-foreground"
            >
              {category.name}
            </span>
          ))}
        </div>
      )}
    </section>
  );
}
