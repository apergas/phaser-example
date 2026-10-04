import type { WebHud, WebLabels } from 'rpg-shared';
import './hud.css';

const MESSAGE_MS = 3500;

export interface HudActions {
  build(blueprint: string): void;
}

type PanelName = 'quests' | 'build';

/**
 * HTML overlay on top of the canvas. A passive view: it copies `WebHud` (already formatted by the
 * shared view model) into the page and reports clicks. Opening and closing its own panels is the only
 * state it keeps.
 */
export class Hud {
  private readonly wood: HTMLElement;
  private readonly axe: HTMLElement;
  private readonly panels: Record<PanelName, { button: HTMLButtonElement; panel: HTMLElement }>;
  private readonly buildOptions: HTMLElement;
  private readonly questList: HTMLElement;
  private readonly questBadge: HTMLElement;
  private readonly message: HTMLElement;
  private lastRendered: WebHud | null = null;
  private lastKey = '';
  private messageTimer: number | undefined;

  constructor(parent: HTMLElement, labels: WebLabels, actions: HudActions) {
    const root = element('div', 'hud');
    root.innerHTML = `
      <div class="hud__panel hud__resources">
        <span class="hud__resource" title="${labels.wood}">
          <span class="hud__icon hud__icon--wood" aria-hidden="true"></span>
          <span class="hud__label">${labels.wood}</span>
          <strong class="hud__value" data-ref="wood">0</strong>
        </span>
        <span class="hud__resource hud__tool" data-ref="axe" title="${labels.axe}">
          <span class="hud__icon hud__icon--axe" aria-hidden="true"></span>
          <span class="hud__label">${labels.axe}</span>
        </span>
      </div>
      <div class="hud__actions">
        <div class="hud__buttons">
          <button class="hud__panel hud__button" data-ref="quests-button" aria-expanded="false" aria-controls="hud-quests">
            ${labels.quests} <span class="hud__badge" data-ref="quest-badge"></span>
          </button>
          <button class="hud__panel hud__button" data-ref="build-button" aria-expanded="false" aria-controls="hud-build">
            ${labels.build}
          </button>
        </div>
        <div class="hud__panel hud__menu" id="hud-quests" data-ref="quests-panel" hidden>
          <h2 class="hud__menu-title">${labels.quests}</h2>
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
    this.questBadge = ref(root, 'quest-badge');
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
      actions.build(button.dataset.blueprint ?? '');
    });
  }

  /** Called every frame; touches the DOM only for the parts that changed. */
  render(state: WebHud): void {
    // state() builds new objects every frame, so compare by content.
    const key = JSON.stringify(state);
    if (key === this.lastKey) return;
    this.lastKey = key;
    const previous = this.lastRendered;
    this.lastRendered = state;

    if (previous?.wood !== state.wood) this.wood.textContent = String(state.wood);
    if (previous?.hasAxe !== state.hasAxe) this.axe.classList.toggle('hud__tool--owned', state.hasAxe);
    if (previous?.isBuildLocked !== state.isBuildLocked) this.panels.build.button.disabled = state.isBuildLocked;
    if (!previous || JSON.stringify(previous.quests) !== JSON.stringify(state.quests)) this.renderQuests(state);
    if (!previous || JSON.stringify(previous.buildItems) !== JSON.stringify(state.buildItems)) this.renderBuildItems(state);
  }

  private renderQuests(state: WebHud): void {
    this.questBadge.textContent = state.questBadge;
    this.questList.innerHTML = state.quests
      .map(
        (quest) => `
          <li class="hud__quest hud__quest--${quest.status}">
            <span class="hud__check" aria-hidden="true"></span>
            <span class="hud__quest-title">${quest.title}</span>
            <span class="hud__quest-progress">${quest.progressText}</span>
          </li>`,
      )
      .join('');
  }

  private renderBuildItems(state: WebHud): void {
    this.buildOptions.innerHTML = state.buildItems
      .map(
        (item) => `
          <button class="hud__option" data-blueprint="${item.blueprint}" ${item.isEnabled ? '' : 'disabled'}>
            <span class="hud__option-name">${item.name}</span>
            <span class="hud__option-cost">${item.costText}</span>
            <span class="hud__option-status">${item.missingText ?? ''}</span>
          </button>`,
      )
      .join('');
  }

  /** Shows a message for a few seconds; the scene calls it for every `message` effect. */
  showMessage(text: string): void {
    this.message.textContent = text;
    this.message.classList.add('hud__message--visible');
    window.clearTimeout(this.messageTimer);
    this.messageTimer = window.setTimeout(() => this.message.classList.remove('hud__message--visible'), MESSAGE_MS);
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
