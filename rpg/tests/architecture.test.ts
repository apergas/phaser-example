import { readdirSync, readFileSync } from 'node:fs';
import { join, relative } from 'node:path';
import { describe, expect, it } from 'vitest';

const SRC = join(__dirname, '..', 'src');

/** Every import specifier in each .ts file under `folder`. */
function importsUnder(folder: string): { file: string; specifier: string }[] {
  const files = readdirSync(join(SRC, folder), { recursive: true, encoding: 'utf8' }).filter((name) =>
    name.endsWith('.ts'),
  );
  return files.flatMap((name) => {
    const file = join(SRC, folder, name);
    const source = readFileSync(file, 'utf8');
    return [...source.matchAll(/from\s+'([^']+)'|import\s+'([^']+)'/g)].map((match) => ({
      file: relative(SRC, file),
      specifier: match[1] ?? match[2],
    }));
  });
}

function violations(folder: string, forbidden: RegExp): string[] {
  return importsUnder(folder)
    .filter(({ specifier }) => forbidden.test(specifier))
    .map(({ file, specifier }) => `${file} -> ${specifier}`);
}

describe('Dependency rule', () => {
  it('domain depends on nothing outside itself (no data, presentation, shared helpers or Phaser)', () => {
    expect(violations('domain', /\/(data|presentation|shared)\/|^phaser$/)).toEqual([]);
  });

  it('the domain core (entities, world, quests) does not know about use cases or repositories', () => {
    const core = ['domain/entities', 'domain/world', 'domain/quests', 'domain/value-objects'];
    expect(core.flatMap((folder) => violations(folder, /\/(usecases|repositories)\//))).toEqual([]);
  });

  it('data implements domain repositories without touching presentation', () => {
    expect(violations('data', /\/presentation\/|^phaser$/)).toEqual([]);
  });

  it('presentation only reaches the domain through use cases and their models, never data', () => {
    const outsideUseCases = /\/domain\/(?!usecases\/)/;
    expect(violations('presentation', /\/data\//)).toEqual([]);
    expect(violations('presentation', outsideUseCases)).toEqual([]);
  });

  it('view models are plain TypeScript: no Phaser, no views', () => {
    const viewModelImports = importsUnder('presentation').filter(({ file }) => file.endsWith('ViewModel.ts'));
    const forbidden = viewModelImports.filter(
      ({ specifier }) => specifier === 'phaser' || /(Scene|View)$/.test(specifier) || specifier.endsWith('.css'),
    );
    expect(forbidden.map(({ file, specifier }) => `${file} -> ${specifier}`)).toEqual([]);
    expect(viewModelImports.length).toBeGreaterThan(0);
  });
});
