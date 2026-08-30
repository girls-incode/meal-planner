import { X } from "lucide-react";
import { Button } from "@/components/ui/button";

interface IngredientChipProps {
  label: string;
  onRemove: () => void;
  disabled?: boolean;
}

export function IngredientChip({ label, onRemove, disabled }: IngredientChipProps) {
  return (
    <span className="inline-flex items-center gap-1.5 rounded-full border border-border bg-secondary px-3 py-1.5 text-sm text-foreground">
      {label}
      <Button
        type="button"
        variant="ghost"
        size="icon-xs"
        aria-label={`Remove ${label}`}
        onClick={onRemove}
        disabled={disabled}
        className="rounded-full text-muted-foreground hover:text-foreground"
      >
        <X className="size-3.5" />
      </Button>
    </span>
  );
}
