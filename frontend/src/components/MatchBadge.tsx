import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

interface MatchBadgeProps {
  matchPercentage: number;
}

function tierFor(matchPercentage: number): { label: string; tone: string } {
  if (matchPercentage >= 100) return { label: "Ready to cook", tone: "bg-primary text-primary-foreground" };
  if (matchPercentage >= 90) return { label: "Almost ready", tone: "bg-primary/80 text-primary-foreground" };
  if (matchPercentage >= 70) return { label: "Missing a couple ingredients", tone: "bg-accent text-accent-foreground" };
  return { label: "Needs more ingredients", tone: "bg-muted text-muted-foreground" };
}

export function MatchBadge({ matchPercentage }: MatchBadgeProps) {
  const { label, tone } = tierFor(matchPercentage);

  return (
    <Badge className={cn("rounded-full px-3 py-1 text-xs font-medium", tone)}>
      {label}
    </Badge>
  );
}
