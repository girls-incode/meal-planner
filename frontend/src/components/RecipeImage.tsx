import { useState } from "react";
import { Image, ImageOff } from "lucide-react";

interface RecipeImageProps {
  src: string | null;
  alt: string;
  className?: string;
}

export function RecipeImage({ src, alt, className = "" }: RecipeImageProps) {
  const [failedImageSrc, setFailedImageSrc] = useState<string | null>(null);
  const [loadedImageSrc, setLoadedImageSrc] = useState<string | null>(null);

  if (src && failedImageSrc !== src) {
    const isLoading = loadedImageSrc !== src;

    return (
      <div className={`relative size-full overflow-hidden bg-muted ${className}`}>
        {isLoading && (
          <div
            className="absolute inset-0 flex flex-col items-center justify-center gap-3 bg-secondary text-muted-foreground"
            aria-label="Loading recipe image"
            role="status"
          >
            <Image className="size-9 animate-pulse" aria-hidden="true" />
            <div className="h-2 w-24 animate-pulse rounded-full bg-foreground/10" />
          </div>
        )}
        <img
          src={src}
          alt={alt}
          className={`size-full object-cover transition-opacity duration-200 ${isLoading ? "opacity-0" : "opacity-100"}`}
          onLoad={() => window.setTimeout(() => setLoadedImageSrc(src), 350)}
          onError={() => setFailedImageSrc(src)}
          loading="lazy"
        />
      </div>
    );
  }

  return (
    <div className={`flex size-full flex-col items-center justify-center gap-2 bg-secondary text-muted-foreground ${className}`}>
      <ImageOff className="size-8" />
      <span className="text-sm">Image unavailable</span>
    </div>
  );
}
