import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import { CheckCircle, AlertCircle, AlertTriangle, ShoppingCart } from "lucide-react";

interface MatchBadgeProps {
  matchPercentage: number;
}

function tierFor(matchPercentage: number): {
  label: string;
  tone: string;
  icon: React.ReactNode;
} {
  if (matchPercentage >= 100) {
    return {
      label: "Ready to cook",
      tone: "bg-primary text-primary-foreground",
      icon: <CheckCircle className="size-3.5" />
    };
  }
  if (matchPercentage >= 90) {
    return {
      label: "Almost ready",
      tone: "bg-primary/80 text-primary-foreground",
      icon: <AlertCircle className="size-3.5" />
    };
  }
  if (matchPercentage >= 70) {
    return {
      label: "Missing a couple ingredients",
      tone: "bg-accent text-accent-foreground",
      icon: <AlertTriangle className="size-3.5" />
    };
  }
  return {
    label: "Needs more ingredients",
    tone: "bg-muted text-muted-foreground",
    icon: <ShoppingCart className="size-3.5" />
  };
}

export function MatchBadge({ matchPercentage }: MatchBadgeProps) {
  const { label, tone, icon } = tierFor(matchPercentage);

  return (
    <Badge className={cn("rounded-full px-3 py-1 text-xs font-medium inline-flex items-center gap-1.5", tone)}>
      {icon}
      {label}
    </Badge>
  );
}
