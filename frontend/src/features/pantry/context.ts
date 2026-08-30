import { useOutletContext } from "react-router-dom";

export interface PantryWorkspaceContext {
  ingredientIds: string[] | null;
  searchVersion: number;
  isAdding: boolean;
  onFindRecipes: () => void;
}

export function usePantryWorkspace() {
  return useOutletContext<PantryWorkspaceContext | null>();
}
