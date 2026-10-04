import type { BlueprintKey, QuestKey } from '../application/dto';

/** Every player-facing text, in one place. */
export const Labels = {
  wood: 'Madera',
  axe: 'Hacha',
  build: 'Construir',
  quests: 'Misiones',
  questTitles: {
    'pick-up-axe': 'Recoge el hacha',
    'gather-wood': 'Consigue al menos 15 de madera',
    'build-house': 'Construye una casa',
  } satisfies Record<QuestKey, string>,
  questDone: 'Hecha',
  close: 'Cerrar',
  cost: (wood: number) => `${wood} de madera`,
  missing: (wood: number) => `Faltan ${wood}`,
  blueprints: { house: 'Casa' } satisfies Record<BlueprintKey, string>,
  messages: {
    welcome: 'Hay un hacha en el suelo, cerca de ti. Recógela pasando por encima.',
    needAxe: 'Necesitas un hacha para talar.',
    blockedPath: 'Hay algo en medio. Acércate por otro lado.',
    pickedUpAxe: '¡Hacha recogida! Haz clic en un árbol para talarlo.',
    woodGained: (wood: number) => `+${wood} de madera`,
    placing: (name: string) => `Elige dónde construir: ${name}. Clic derecho o Esc para cancelar.`,
    blocked: 'Ahí no cabe. Busca un sitio despejado.',
    notEnoughWood: 'No tienes madera suficiente.',
    buildingStarted: 'Manos a la obra…',
    buildingCompleted: (name: string) => `¡${name} construida!`,
    questCompleted: (title: string) => `Misión completada: ${title}`,
    allQuestsCompleted: '¡Has completado todas las misiones!',
  },
} as const;
