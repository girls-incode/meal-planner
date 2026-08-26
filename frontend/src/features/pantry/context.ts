import { useOutletContext } from "react-router-dom";

export interface PantryWorkspaceContext {
  ingredientIds: string[] | null;
  searchVersion: number;
  onFindRecipes: () => void;
}

export function usePantryWorkspace() {
  return useOutletContext<PantryWorkspaceContext | null>();
}
