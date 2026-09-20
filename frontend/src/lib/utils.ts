import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

/*
 * Combines conditional/array/object class inputs via clsx, then resolves
 * conflicting Tailwind classes (e.g. "px-2 px-4") via twMerge, keeping the
 * last one. Lets components accept a `className` override without producing
 * duplicate/conflicting utility classes.
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
