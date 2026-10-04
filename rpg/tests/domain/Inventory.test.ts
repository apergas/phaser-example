import { describe, expect, it } from 'vitest';
import { Inventory } from '../../src/domain/entities/Inventory';

describe('Inventory', () => {
  it('stores and spends wood', () => {
    const inventory = new Inventory();
    inventory.addWood(6);

    expect(inventory.spendWood(4)).toBe(true);
    expect(inventory.wood).toBe(2);
  });

  it('refuses to spend more wood than it has', () => {
    const inventory = new Inventory();
    inventory.addWood(3);

    expect(inventory.spendWood(5)).toBe(false);
    expect(inventory.wood).toBe(3);
  });

  it('remembers picked up tools', () => {
    const inventory = new Inventory();
    expect(inventory.hasTool('axe')).toBe(false);

    inventory.addTool('axe');
    expect(inventory.hasTool('axe')).toBe(true);
  });
});
