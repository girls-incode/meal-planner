import { Link } from "react-router-dom";
import { EmptyState } from "@/components/EmptyState";

interface RecipeEmptyStateProps {
  title: string;
  description: string;
  actionLabel?: string;
}

export function RecipeEmptyState({ title, description, actionLabel }: RecipeEmptyStateProps) {
  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <EmptyState
        title={title}
        description={description}
        action={
          actionLabel ? (
            <Link
              to="/"
              className="mt-2 inline-flex items-center justify-center rounded-full bg-primary px-6 py-2.5 text-sm font-semibold text-primary-foreground transition-colors hover:bg-primary-hover"
            >
              {actionLabel}
            </Link>
          ) : undefined
        }
      />
    </div>
  );
}
