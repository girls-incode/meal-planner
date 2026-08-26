import { X } from "lucide-react";

interface IngredientChipProps {
  label: string;
  onRemove: () => void;
  disabled?: boolean;
}

export function IngredientChip({ label, onRemove, disabled }: IngredientChipProps) {
  return (
    <span className="inline-flex items-center gap-1.5 rounded-full border border-border bg-secondary px-3 py-1.5 text-sm text-foreground">
      {label}
      <button
        type="button"
        aria-label={`Remove ${label}`}
        onClick={onRemove}
        disabled={disabled}
        className="rounded-full p-0.5 text-muted-foreground transition-colors hover:bg-border hover:text-foreground disabled:opacity-50"
      >
        <X className="size-3.5" />
      </button>
    </span>
  );
}
