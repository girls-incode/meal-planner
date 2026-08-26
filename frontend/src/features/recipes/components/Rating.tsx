import { Star } from "lucide-react";
import { cn } from "@/lib/utils";

interface RatingProps {
  value: number | null;
  size?: "sm" | "md";
  className?: string;
}

export function Rating({ value, size = "sm", className }: RatingProps) {
  if (value === null || value <= 0) return null;

  const starClassName = size === "md" ? "size-4" : "size-3.5";
  const textClassName = size === "md" ? "text-sm" : "text-xs";

  return (
    <div className={cn("flex items-center gap-1", className)}>
      <div className="flex items-center gap-0.5">
        {[...Array(5)].map((_, index) => (
          <Star
            key={index}
            className={cn(
              starClassName,
              index < Math.round(value) ? "fill-yellow-400 text-yellow-400" : "text-muted-foreground",
            )}
          />
        ))}
      </div>
      <span className={cn(textClassName, "text-muted-foreground")}>({value.toFixed(1)})</span>
    </div>
  );
}
