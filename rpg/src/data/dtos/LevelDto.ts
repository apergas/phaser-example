/**
 * A level as it comes from its source (generator, Tiled map, JSON file): plain data, not trusted.
 * Positions are the base (feet / trunk) of each element, in world units. `kind` is a free string
 * because external data can contain anything; the mapper validates it.
 */
export interface LevelDto {
  readonly width: number;
  readonly height: number;
  readonly playerStart: PointDto;
  readonly trees: readonly (PointDto & { readonly id: string; readonly wood: number })[];
  readonly items: readonly (PointDto & { readonly id: string; readonly kind: string })[];
}

export interface PointDto {
  readonly x: number;
  readonly y: number;
}
