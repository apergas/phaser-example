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
  it('domain depends on nothing outside itself (no app, infrastructure, presentation or Phaser)', () => {
    expect(violations('domain', /\/(application|infrastructure|presentation|shared)\/|^phaser$/)).toEqual([]);
  });

  it('application depends only on the domain', () => {
    expect(violations('application', /\/(infrastructure|presentation)\/|^phaser$/)).toEqual([]);
  });

  it('presentation talks to the application layer only, never to the domain', () => {
    expect(violations('presentation', /\/(domain|infrastructure)\//)).toEqual([]);
  });

  it('view models are plain TypeScript: no Phaser, no DOM views', () => {
    expect(violations('presentation/viewmodels', /^phaser$|\/(phaser|dom)\//)).toEqual([]);
  });

  it('infrastructure implements application ports without touching presentation', () => {
    expect(violations('infrastructure', /\/presentation\/|^phaser$/)).toEqual([]);
  });
});
