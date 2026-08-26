import { useState } from "react";
import { ImageOff } from "lucide-react";

interface RecipeImageProps {
  src: string | null;
  alt: string;
  className?: string;
}

export function RecipeImage({ src, alt, className = "" }: RecipeImageProps) {
  const [imageLoadError, setImageLoadError] = useState(false);
  const hasValidImage = src && !imageLoadError;

  if (hasValidImage) {
    return (
      <img
        src={src}
        alt={alt}
        className={`size-full object-cover ${className}`}
        onError={() => setImageLoadError(true)}
        loading="lazy"
      />
    );
  }

  return (
    <div className={`flex size-full flex-col items-center justify-center gap-2 bg-secondary text-muted-foreground ${className}`}>
      <ImageOff className="size-8" />
      <span className="text-sm">Image unavailable</span>
    </div>
  );
}
