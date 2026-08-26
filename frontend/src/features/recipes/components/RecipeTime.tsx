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
  const [iconClassName, textClassName] =
    size === "md" ? ["size-4", "text-sm"] : ["size-3.5", "text-xs"];

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
      <span className="inline-flex items-center gap-1 font-medium">
        <Clock className={cn(iconClassName, "text-primary")} />
        <span>Total:</span>
        <span>{totalTime > 0 ? `${totalTime} min` : "Instant"}</span>
      </span>
    </div>
  );
}
