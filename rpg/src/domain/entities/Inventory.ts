export type ToolKind = 'axe';

/** What the player carries: stored wood and the tools it has picked up. */
export class Inventory {
  private woodCount = 0;
  private readonly tools = new Set<ToolKind>();

  get wood(): number {
    return this.woodCount;
  }

  addWood(amount: number): void {
    if (amount < 0) throw new Error('Cannot add a negative amount of wood');
    this.woodCount += amount;
  }

  /** Removes `amount` wood if there is enough; returns whether it was spent. */
  spendWood(amount: number): boolean {
    if (amount > this.woodCount) return false;
    this.woodCount -= amount;
    return true;
  }

  addTool(tool: ToolKind): void {
    this.tools.add(tool);
  }

  hasTool(tool: ToolKind): boolean {
    return this.tools.has(tool);
  }
}
