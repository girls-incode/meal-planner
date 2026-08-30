import { useCategories } from "@/features/categories/hooks/useCategories";
import { Badge } from "@/components/ui/badge";

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
            <Badge key={category.id} variant="outline" className="h-auto px-3 py-1.5 text-sm">
              {category.name}
            </Badge>
          ))}
        </div>
      )}
    </section>
  );
}
