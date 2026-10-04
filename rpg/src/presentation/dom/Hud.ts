import type { BuildOptionDto, PlayerStateDto, QuestDto } from '../../application/dto';
import type { BlueprintId } from '../../domain/entities/Blueprint';
import { Labels } from '../labels';
import './hud.css';

const MESSAGE_MS = 3500;

/** What the gameplay scene needs from the HUD. */
export interface HudPort {
  update(player: PlayerStateDto, buildOptions: readonly BuildOptionDto[], quests: readonly QuestDto[]): void;
  showMessage(text: string): void;
  setPlacing(blueprintId: BlueprintId | null): void;
}

type PanelName = 'quests' | 'build';

/**
 * HTML overlay on top of the canvas: resources, tools, the quest log, the build menu and short
 * messages. Plain DOM keeps text crisp at any zoom; it only reads DTOs and reports clicks through
 * callbacks.
 */
export class Hud implements HudPort {
  private readonly wood: HTMLElement;
  private readonly axe: HTMLElement;
  private readonly panels: Record<PanelName, { button: HTMLButtonElement; panel: HTMLElement }>;
  private readonly buildOptions: HTMLElement;
  private readonly questList: HTMLElement;
  private readonly questCount: HTMLElement;
  private readonly message: HTMLElement;
  private readonly onBuildRequested: (blueprintId: BlueprintId) => void;
  private lastRendered = '';
  private messageTimer: number | undefined;

  constructor(parent: HTMLElement, onBuildRequested: (blueprintId: BlueprintId) => void) {
    this.onBuildRequested = onBuildRequested;

    const root = element('div', 'hud');
    root.innerHTML = `
      <div class="hud__panel hud__resources">
        <span class="hud__resource" title="${Labels.wood}">
          <span class="hud__icon hud__icon--wood" aria-hidden="true"></span>
          <span class="hud__label">${Labels.wood}</span>
          <strong class="hud__value" data-ref="wood">0</strong>
        </span>
        <span class="hud__resource hud__tool" data-ref="axe" title="${Labels.axe}">
          <span class="hud__icon hud__icon--axe" aria-hidden="true"></span>
          <span class="hud__label">${Labels.axe}</span>
        </span>
      </div>
      <div class="hud__actions">
        <div class="hud__buttons">
          <button class="hud__panel hud__button" data-ref="quests-button" aria-expanded="false" aria-controls="hud-quests">
            ${Labels.quests} <span class="hud__badge" data-ref="quest-count"></span>
          </button>
          <button class="hud__panel hud__button" data-ref="build-button" aria-expanded="false" aria-controls="hud-build">
            ${Labels.build}
          </button>
        </div>
        <div class="hud__panel hud__menu" id="hud-quests" data-ref="quests-panel" hidden>
          <h2 class="hud__menu-title">${Labels.quests}</h2>
          <ol class="hud__quests" data-ref="quest-list"></ol>
        </div>
        <div class="hud__panel hud__menu" id="hud-build" data-ref="build-panel" hidden>
          <div data-ref="build-options"></div>
        </div>
      </div>
      <div class="hud__message" data-ref="message" role="status" aria-live="polite"></div>
    `;
    parent.appendChild(root);

    this.wood = ref(root, 'wood');
    this.axe = ref(root, 'axe');
    this.buildOptions = ref(root, 'build-options');
    this.questList = ref(root, 'quest-list');
    this.questCount = ref(root, 'quest-count');
    this.message = ref(root, 'message');
    this.panels = {
      quests: { button: ref(root, 'quests-button') as HTMLButtonElement, panel: ref(root, 'quests-panel') },
      build: { button: ref(root, 'build-button') as HTMLButtonElement, panel: ref(root, 'build-panel') },
    };

    for (const name of Object.keys(this.panels) as PanelName[]) {
      this.panels[name].button.addEventListener('click', () => this.toggle(name));
    }
    this.buildOptions.addEventListener('click', (event) => {
      const button = (event.target as HTMLElement).closest<HTMLButtonElement>('button[data-blueprint]');
      if (!button || button.disabled) return;
      this.closePanels();
      this.onBuildRequested(button.dataset.blueprint as BlueprintId);
    });
  }

  update(player: PlayerStateDto, buildOptions: readonly BuildOptionDto[], quests: readonly QuestDto[]): void {
    // Rendered every frame by the scene; touch the DOM only when something changed.
    const key = JSON.stringify([player.wood, player.hasAxe, buildOptions, quests]);
    if (key === this.lastRendered) return;
    this.lastRendered = key;

    this.wood.textContent = String(player.wood);
    this.axe.classList.toggle('hud__tool--owned', player.hasAxe);
    this.renderBuildOptions(player.wood, buildOptions);
    this.renderQuests(quests);
  }

  showMessage(text: string): void {
    this.message.textContent = text;
    this.message.classList.add('hud__message--visible');
    window.clearTimeout(this.messageTimer);
    this.messageTimer = window.setTimeout(() => this.message.classList.remove('hud__message--visible'), MESSAGE_MS);
  }

  setPlacing(blueprintId: BlueprintId | null): void {
    this.panels.build.button.disabled = blueprintId !== null;
  }

  private renderBuildOptions(wood: number, buildOptions: readonly BuildOptionDto[]): void {
    this.buildOptions.innerHTML = buildOptions
      .map((option) => {
        const missing = option.affordable ? '' : Labels.missing(option.woodCost - wood);
        return `
          <button class="hud__option" data-blueprint="${option.blueprintId}" ${option.affordable ? '' : 'disabled'}>
            <span class="hud__option-name">${Labels.blueprints[option.blueprintId]}</span>
            <span class="hud__option-cost">${Labels.cost(option.woodCost)}</span>
            <span class="hud__option-status">${missing}</span>
          </button>`;
      })
      .join('');
  }

  private renderQuests(quests: readonly QuestDto[]): void {
    const done = quests.filter((quest) => quest.completed).length;
    this.questCount.textContent = `${done}/${quests.length}`;
    this.questList.innerHTML = quests
      .map((quest) => {
        const state = quest.completed ? 'done' : quest.current ? 'current' : 'pending';
        const progress = quest.completed
          ? Labels.questDone
          : quest.target > 1
            ? `${quest.progress}/${quest.target}`
            : '';
        return `
          <li class="hud__quest hud__quest--${state}">
            <span class="hud__check" aria-hidden="true"></span>
            <span class="hud__quest-title">${Labels.questTitles[quest.id]}</span>
            <span class="hud__quest-progress">${progress}</span>
          </li>`;
      })
      .join('');
  }

  private toggle(name: PanelName): void {
    const opening = this.panels[name].panel.hidden;
    this.closePanels();
    if (!opening) return;
    this.panels[name].panel.hidden = false;
    this.panels[name].button.setAttribute('aria-expanded', 'true');
  }

  private closePanels(): void {
    for (const { button, panel } of Object.values(this.panels)) {
      panel.hidden = true;
      button.setAttribute('aria-expanded', 'false');
    }
  }
}

function element(tag: string, className: string): HTMLElement {
  const node = document.createElement(tag);
  node.className = className;
  return node;
}

function ref(root: HTMLElement, name: string): HTMLElement {
  const node = root.querySelector<HTMLElement>(`[data-ref="${name}"]`);
  if (!node) throw new Error(`HUD element "${name}" not found`);
  return node;
}
