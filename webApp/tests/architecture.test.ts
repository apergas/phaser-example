import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join, relative } from 'node:path';
import { describe, expect, it } from 'vitest';

const SRC = join(__dirname, '..', 'src');

function importsUnder(folder: string): { file: string; specifier: string }[] {
  const files = readdirSync(join(SRC, folder), { recursive: true, encoding: 'utf8' }).filter((name) => name.endsWith('.ts'));
  return files.flatMap((name) => {
    const file = join(SRC, folder, name);
    return [...readFileSync(file, 'utf8').matchAll(/from\s+'([^']+)'/g)].map((match) => ({
      file: relative(SRC, file),
      specifier: match[1],
    }));
  });
}

describe('Web app architecture', () => {
  it('has no game logic of its own: domain, data and view models live in the shared Kotlin module', () => {
    expect(existsSync(join(SRC, 'domain'))).toBe(false);
    expect(existsSync(join(SRC, 'data'))).toBe(false);
    expect(importsUnder('presentation').filter(({ file }) => file.endsWith('ViewModel.ts'))).toEqual([]);
  });

  it('presentation only depends on Phaser, the shared package and itself', () => {
    const external = importsUnder('presentation')
      .map(({ specifier }) => specifier)
      .filter((specifier) => !specifier.startsWith('.') && !specifier.endsWith('.css'));
    expect([...new Set(external)].sort()).toEqual(['phaser', 'rpg-shared']);
  });
});
