import { Link } from "react-router-dom";
import { Card, CardContent } from "@/components/ui/card";
import { MatchBadge } from "@/features/recipes/components/MatchBadge";
import { Rating } from "@/features/recipes/components/Rating";
import { RecipeTime } from "@/features/recipes/components/RecipeTime";
import { MissingIngredients } from "@/features/recipes/components/MissingIngredients";
import { RecipeImage } from "@/features/recipes/components/RecipeImage";
import { RecipeMetadata } from "@/features/recipes/components/RecipeMetadata";
import type { RecipeMatch } from "@/api/types";

interface RecipeCardProps {
  recipe: RecipeMatch;
}

export function RecipeCard({ recipe }: RecipeCardProps) {

  return (
    <Link to={`/recipes/${recipe.id}`} className="block h-full">
      <Card className="flex h-full flex-col overflow-hidden rounded-2xl border-border py-0 shadow-sm transition-shadow hover:shadow-md">
        <div className="aspect-[4/3] w-full overflow-hidden bg-muted">
          <RecipeImage src={recipe.imageUrl} alt={recipe.title} />
        </div>
        <CardContent className="flex flex-1 flex-col gap-3 px-4 pb-4 pt-4">
          <h3 className="text-base font-semibold leading-tight text-foreground line-clamp-2">{recipe.title}</h3>
          <RecipeMetadata
            cuisine={recipe.cuisine}
            category={recipe.category?.name ?? null}
            author={recipe.author?.name ?? null}
            className="flex flex-wrap gap-x-3 gap-y-1 text-xs text-muted-foreground"
          />
          <Rating value={recipe.ratings} />
          <RecipeTime
            prepTimeMinutes={recipe.prepTimeMinutes}
            cookTimeMinutes={recipe.cookTimeMinutes}
          />
          <div className="mt-auto space-y-2">
            <MatchBadge matchPercentage={recipe.matchPercentage} />
            <MissingIngredients ingredients={recipe.missingIngredients} count={recipe.missingCount} />
          </div>
        </CardContent>
      </Card>
    </Link>
  );
}
