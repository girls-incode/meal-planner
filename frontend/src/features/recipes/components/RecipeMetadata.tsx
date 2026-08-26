import { ChefHat, Tag, UserRound } from "lucide-react";

type MetadataItem = {
  icon: typeof ChefHat;
  label: string;
  value: string;
};

interface RecipeMetadataProps {
  cuisine: string | null;
  category: string | null;
  author: string | null;
  className?: string;
}

export function RecipeMetadata({
  cuisine,
  category,
  author,
  className,
}: RecipeMetadataProps) {
  const metadata = [
    { icon: ChefHat, label: "Cuisine", value: cuisine },
    { icon: Tag, label: "Category", value: category },
    { icon: UserRound, label: "Author", value: author },
  ].filter((item): item is MetadataItem => item.value !== null);

  if (!metadata.length) return null;

  return (
    <div className={className}>
      {metadata.map(({ icon: Icon, label, value }) => (
        <span key={label} className="inline-flex items-center gap-1">
          <Icon className="size-3.5 text-primary" aria-hidden="true" />
          <span className="sr-only">{label}: </span>
          {value}
        </span>
      ))}
    </div>
  );
}
