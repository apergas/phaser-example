/**
 * Draw order for the 3/4 top-down view. Ground and shadows sit under everything; sprites are
 * sorted by the y of their base, so whatever stands lower on screen is drawn in front.
 * Overlays (placement previews) go above the whole world.
 */
export const Depth = {
  GROUND: -2,
  SHADOW: -1,
  bySortY: (baseY: number): number => baseY,
  OVERLAY: 1_000_000,
} as const;
