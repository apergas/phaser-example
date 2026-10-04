/**
 * Identifiers adapters use to name tools, blueprints and quests. They mirror the domain unions;
 * `mappers.ts` only compiles while both sides match.
 */
export type ToolKey = 'axe';
export type BlueprintKey = 'house';
export type QuestKey = 'pick-up-axe' | 'gather-wood' | 'build-house';
