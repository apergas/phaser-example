import type { ToolKey } from '../dto';

/**
 * A level as plain data. Positions are the base (feet / trunk) of each element, in world units.
 * Implemented by infrastructure: a procedural generator today, a Tiled map loader later.
 */
export interface LevelDefinition {
  readonly width: number;
  readonly height: number;
  readonly playerStart: { readonly x: number; readonly y: number };
  readonly trees: readonly { readonly id: string; readonly x: number; readonly y: number; readonly wood: number }[];
  readonly items: readonly { readonly id: string; readonly kind: ToolKey; readonly x: number; readonly y: number }[];
}

export interface LevelSource {
  load(): LevelDefinition;
}
