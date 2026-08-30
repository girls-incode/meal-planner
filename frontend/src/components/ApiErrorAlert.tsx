import { ApiError } from "@/api/client";
import { cn } from "@/lib/utils";

interface ApiErrorAlertProps {
  error: unknown;
  className?: string;
}

export function ApiErrorAlert({ error, className }: ApiErrorAlertProps) {
  const message = error instanceof ApiError
    ? error.message
    : "Something went wrong. Please try again.";

  return (
    <p role="alert" className={cn("text-sm text-destructive", className)}>
      {message}
    </p>
  );
}
