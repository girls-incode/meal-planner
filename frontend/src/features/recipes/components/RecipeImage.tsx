import { useState } from "react";
import { Image, ImageOff } from "lucide-react";
import { cn } from "@/lib/utils";

interface RecipeImageProps {
  src: string | null;
  alt: string;
  className?: string;
}

type ImageStatus = "loading" | "loaded" | "failed";

export function RecipeImage({ src, alt, className }: RecipeImageProps) {
  // Tracks status per src so navigating to a different image (e.g. a new
  // recipe) resets to "loading" instead of reusing a previous image's outcome.
  const [{ src: trackedSrc, status }, setState] = useState<{ src: string | null; status: ImageStatus }>({
    src,
    status: "loading",
  });

  if (trackedSrc !== src) {
    setState({ src, status: "loading" });
  }

  if (!src || status === "failed") {
    return (
      <div className={cn("flex size-full flex-col items-center justify-center gap-2 bg-secondary text-muted-foreground", className)}>
        <ImageOff className="size-8" />
        <span className="text-sm">Image unavailable</span>
      </div>
    );
  }

  const isLoading = status === "loading";

  return (
    <div className={cn("relative size-full overflow-hidden bg-muted", className)}>
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
        className={cn("size-full object-cover transition-opacity duration-200", isLoading ? "opacity-0" : "opacity-100")}
        onLoad={() => window.setTimeout(() => setState({ src, status: "loaded" }), 350)}
        onError={() => setState({ src, status: "failed" })}
        loading="lazy"
      />
    </div>
  );
}
