import { useState } from "react";
import { Link } from "react-router-dom";
import { ImageOff } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { MatchBadge } from "@/components/MatchBadge";
import type { RecipeMatch } from "@/api/types";

interface RecipeCardProps {
  recipe: RecipeMatch;
}

export function RecipeCard({ recipe }: RecipeCardProps) {
  const [imageLoadError, setImageLoadError] = useState(false);
  const totalTime = (recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0);
  const hasValidImage = recipe.imageUrl && !imageLoadError;

  return (
    <Link to={`/recipes/${recipe.id}`} className="block">
      <Card className="overflow-hidden rounded-2xl border-border py-0 shadow-sm transition-shadow hover:shadow-md">
        <div className="aspect-[4/3] w-full overflow-hidden bg-muted">
          {hasValidImage ? (
            <img
              src={recipe.imageUrl!}
              alt={recipe.title}
              loading="lazy"
              className="size-full object-cover"
              onError={() => setImageLoadError(true)}
            />
          ) : (
            <div className="flex size-full flex-col items-center justify-center gap-1 text-muted-foreground">
              <ImageOff className="size-6" />
              <span className="text-xs">No image</span>
            </div>
          )}
        </div>
        <CardContent className="flex flex-col gap-2 px-4 pb-4">
          <h3 className="text-base font-semibold leading-tight text-foreground">{recipe.title}</h3>
          <MatchBadge matchPercentage={recipe.matchPercentage} />
          <div className="flex items-center justify-between text-sm text-muted-foreground">
            <span>{totalTime > 0 ? `${totalTime} min` : "—"}</span>
            {recipe.missingCount > 0 && (
              <span>Missing {recipe.missingCount} ingredient{recipe.missingCount === 1 ? "" : "s"}</span>
            )}
          </div>
        </CardContent>
      </Card>
    </Link>
  );
}
