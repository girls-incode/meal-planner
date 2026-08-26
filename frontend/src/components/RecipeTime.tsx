import { ChefHat, Clock, Timer } from "lucide-react";
import { cn } from "@/lib/utils";

interface RecipeTimeProps {
  prepTimeMinutes: number | null;
  cookTimeMinutes: number | null;
  size?: "sm" | "md";
  className?: string;
}

export function RecipeTime({
  prepTimeMinutes,
  cookTimeMinutes,
  size = "sm",
  className,
}: RecipeTimeProps) {
  const totalTime = (prepTimeMinutes ?? 0) + (cookTimeMinutes ?? 0);
  const iconClassName = size === "md" ? "size-4" : "size-3.5";
  const textClassName = size === "md" ? "text-sm" : "text-xs";
  const totalTimeLabel = totalTime > 0 ? `${totalTime} min` : "Instant";

  return (
    <div
      className={cn(
        "flex flex-wrap items-center gap-x-4 gap-y-2 text-foreground",
        textClassName,
        className,
      )}
    >
      {!!prepTimeMinutes && (
        <span className="inline-flex items-center gap-1">
          <Timer className={cn(iconClassName, "text-primary")} />
          <span>Prep: {prepTimeMinutes} min</span>
        </span>
      )}
      {!!cookTimeMinutes && (
        <span className="inline-flex items-center gap-1">
          <ChefHat className={cn(iconClassName, "text-primary")} />
          <span>Cook: {cookTimeMinutes} min</span>
        </span>
      )}
      {totalTimeLabel && (
        <span className="inline-flex items-center gap-1 font-medium">
          <Clock className={cn(iconClassName, "text-primary")} />
          <span>Total:</span>
          <span>{totalTimeLabel}</span>
        </span>
      )}
    </div>
  );
}
