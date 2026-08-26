import { LoaderCircle } from "lucide-react";
import { cn } from "@/lib/utils";

interface LoaderProps {
  label?: string;
  maxWidth?: "3xl" | "6xl";
}

export function Loader({ label = "Loading…", maxWidth = "6xl" }: LoaderProps) {
  return (
    <div
      role="status"
      aria-live="polite"
      className={cn(
        "mx-auto flex w-full items-center justify-center gap-2 px-4 py-10 text-muted-foreground",
        maxWidth === "3xl" ? "max-w-3xl" : "max-w-6xl",
      )}
    >
      <LoaderCircle className="size-4 animate-spin" aria-hidden="true" />
      <span>{label}</span>
    </div>
  );
}
