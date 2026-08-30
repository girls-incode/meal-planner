import { EmptyState } from "@/components/EmptyState";

interface RecipeEmptyStateProps {
  title: string;
  description: string;
}

export function RecipeEmptyState({
  title,
  description,
}: RecipeEmptyStateProps) {
  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <EmptyState title={title} description={description} />
    </div>
  );
}
