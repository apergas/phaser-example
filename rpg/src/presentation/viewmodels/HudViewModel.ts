import type { BlueprintKey, BuildOptionDto, PlayerStateDto, QuestDto } from '../../application/dto';
import { Labels } from '../labels';

export interface QuestItem {
  readonly title: string;
  /** "7/15", "Hecha", or empty for one-step quests still pending. */
  readonly progressText: string;
  readonly status: 'done' | 'current' | 'pending';
}

export interface BuildItem {
  readonly blueprint: BlueprintKey;
  readonly name: string;
  readonly costText: string;
  /** "Faltan 5" when it cannot be afforded yet. */
  readonly missingText: string | null;
  readonly enabled: boolean;
}

/** Display-ready HUD content: the view only copies it into the page. */
export interface HudState {
  readonly wood: number;
  readonly hasAxe: boolean;
  readonly questBadge: string;
  readonly quests: readonly QuestItem[];
  readonly buildItems: readonly BuildItem[];
  /** The build menu is locked while a building is being placed. */
  readonly buildLocked: boolean;
  /** Latest message; `serial` changes every time one is shown, even if the text repeats. */
  readonly message: { readonly text: string; readonly serial: number } | null;
}

export class HudViewModel {
  private current: HudState = {
    wood: 0,
    hasAxe: false,
    questBadge: '',
    quests: [],
    buildItems: [],
    buildLocked: false,
    message: null,
  };
  private messageSerial = 0;

  get state(): HudState {
    return this.current;
  }

  update(player: PlayerStateDto, buildOptions: readonly BuildOptionDto[], quests: readonly QuestDto[], placing: boolean): void {
    const done = quests.filter((quest) => quest.completed).length;
    this.current = {
      ...this.current,
      wood: player.wood,
      hasAxe: player.hasAxe,
      questBadge: `${done}/${quests.length}`,
      quests: quests.map(toQuestItem),
      buildItems: buildOptions.map((option) => toBuildItem(option, player.wood)),
      buildLocked: placing,
    };
  }

  showMessage(text: string): void {
    this.messageSerial += 1;
    this.current = { ...this.current, message: { text, serial: this.messageSerial } };
  }
}

function toQuestItem(quest: QuestDto): QuestItem {
  const progressText = quest.completed ? Labels.questDone : quest.target > 1 ? `${quest.progress}/${quest.target}` : '';
  return {
    title: Labels.questTitles[quest.id],
    progressText,
    status: quest.completed ? 'done' : quest.current ? 'current' : 'pending',
  };
}

function toBuildItem(option: BuildOptionDto, wood: number): BuildItem {
  return {
    blueprint: option.blueprintId,
    name: Labels.blueprints[option.blueprintId],
    costText: Labels.cost(option.woodCost),
    missingText: option.affordable ? null : Labels.missing(option.woodCost - wood),
    enabled: option.affordable,
  };
}
