# Fase 6 — La web pasa a usar `shared` (Kotlin/JS)

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que la web (`rpg/`) use el núcleo Kotlin mediante un paquete npm generado por Kotlin/JS, borrar su dominio/datos/ViewModels en TypeScript y mantener el juego idéntico y desplegado en GitHub Pages.

**Architecture:** En `shared/src/jsMain` una fachada `ForestWebController` (`@JsExport`) envuelve al `ForestViewModel` compartido y expone tipos planos (`WebState`, `WebWorld`, `WebEffect`…) aptos para TypeScript. La web queda solo con vistas: `ForestScene` (Phaser), `PlayerView`, vistas del mundo, `Hud` (DOM) y `PreloadScene`.

**Tech Stack:** Kotlin/JS (IR, ES modules, `.d.ts`), Vite, Phaser 4, Vitest (solo test de arquitectura), Playwright (e2e manual).

## Global Constraints

Las de [`README.md`](README.md#global-constraints). En esta fase: solo `ForestWebController` y sus tipos `Web*` llevan `@JsExport`; nada de `Long` ni colecciones Kotlin en la API exportada (solo `Array`, `String`, `Double`, `Boolean`, clases exportadas); la web no contiene reglas de juego ni textos de juego; el juego publicado debe comportarse igual que antes (partida de referencia: 5 árboles talados → 16 de madera, casa construida, 3/3 misiones, sin errores de consola).

## File Structure

```
shared/build.gradle.kts                                     (js: useEsModules)
shared/src/jsMain/kotlin/com/apergas/rpg/web/
  ForestWebController.kt      fachada exportada
  WebModels.kt                tipos exportados (WebState, WebWorld, WebEffect, ...)
  WebMappers.kt               ForestState/WorldSnapshot/ForestEffect → Web*
rpg/
  package.json                dependencia "rpg-shared": "file:../shared/build/dist/js/productionLibrary"
  src/main.ts                 monta ForestWebController + Hud + escenas
  src/presentation/common/seededRandom.ts        (movido desde src/shared/)
  src/presentation/screens/forest/ForestScene.ts (habla con el controller)
  src/presentation/screens/forest/hud/Hud.ts     (render(WebHud) + showMessage)
  src/presentation/screens/forest/player/PlayerView.ts (render(WebPlayer))
  src/presentation/screens/forest/world/*.ts     (tipos WebPoint)
  BORRADOS: src/domain/, src/data/, src/shared/, src/presentation/common/labels.ts,
            src/presentation/screens/forest/{ForestViewModel,hud/HudViewModel,player/PlayerViewModel}.ts,
            tests/domain/, tests/data/, tests/presentation/, tests/fixtures.ts
  tests/architecture.test.ts  reglas nuevas
.github/workflows/deploy.yml  build: Java + Gradle generan rpg-shared antes de npm; filtro de rutas
kotlin-js-store/yarn.lock     lock de dependencias npm de Kotlin/JS (se versiona)
```

---

### Task 1: Fachada `ForestWebController` exportada a TypeScript

**Files:**
- Modify: `shared/build.gradle.kts`
- Create: `shared/src/jsMain/kotlin/com/apergas/rpg/web/WebModels.kt`, `WebMappers.kt`, `ForestWebController.kt`
- Test: `shared/src/jsTest/kotlin/com/apergas/rpg/web/ForestWebControllerTests.kt`

**Interfaces:**
- Consumes: `GameContainer.makeForestViewModel()`, `ForestState`, `ForestEffect`, `WorldSnapshot`, `ForestLabels` (fases 4–5).
- Produces (TypeScript los verá en `rpg-shared.d.ts`):
```
class ForestWebController {
  tick(deltaMs: number): void
  mapClicked(x: number, y: number, treeId: string | null, isSecondary: boolean): void
  pointerMoved(x: number, y: number): void
  requestBuild(blueprint: string): void          // "House"
  cancelPlacement(): void
  state(): WebState
  world(): WebWorld
  takeEffects(): WebEffect[]                     // efectos desde la última llamada
  labels(): WebLabels
}
WebState { player: WebPlayer; hud: WebHud; placement: WebPlacement | null }
WebPlayer { position: WebPoint; facing: string /*up|left|down|right*/; pose: string /*idle|walk|work*/; withAxe: boolean; tool: string | null /*axe|hammer*/; swingProgress: number }
WebHud { wood: number; hasAxe: boolean; questBadge: string; quests: WebQuestItem[]; buildItems: WebBuildItem[]; isBuildLocked: boolean }
WebQuestItem { title: string; progressText: string; status: string /*done|current|pending*/ }
WebBuildItem { blueprint: string; name: string; costText: string; missingText: string | null; isEnabled: boolean }
WebPlacement { blueprint: string; position: WebPoint; isValid: boolean }
WebWorld { width: number; height: number; trees: WebTree[]; items: WebItem[]; buildings: WebBuilding[] }
WebTree { id: string; position: WebPoint }   WebItem { id: string; kind: string; position: WebPoint }
WebBuilding { id: string; blueprint: string; position: WebPoint; progress: number }
WebEffect { kind: string; id: string | null; fromX: number; progress: number; text: string | null; building: WebBuilding | null }
  // kind ∈ item-picked-up | tree-hit | tree-felled | building-placed | building-hammered | building-completed | message
WebLabels { wood: string; axe: string; build: string; quests: string }
WebPoint { x: number; y: number }
```

- [ ] **Step 1: Salida en ES modules**

En `shared/build.gradle.kts`, dentro de `js(IR) { ... }`, añadir `useEsModules()` justo después de `binaries.library()`. Y en `sourceSets` añadir:
```kotlin
        jsTest.dependencies {
            implementation(kotlin("test"))
        }
```

- [ ] **Step 2: Test de la fachada**

```kotlin
package com.apergas.rpg.web

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ForestWebControllerTests {
    @Test
    fun testWhenTickingThenStateAndWelcomeEffectAreExposedAsPlainValues() {
        // given
        val sut = ForestWebController()

        // when
        sut.tick(16.0)
        val effects = sut.takeEffects()
        val state = sut.state()

        // then
        assertEquals("message", effects.first().kind)
        assertEquals("0/3", state.hud.questBadge)
        assertEquals("idle", state.player.pose)
        assertEquals(800.0, state.player.position.x)
        assertTrue(sut.takeEffects().isEmpty())
    }

    @Test
    fun testWhenAskingForTheWorldThenTreesAndAxeAreExposed() {
        // given
        val sut = ForestWebController()

        // when
        val world = sut.world()

        // then
        assertEquals(70, world.trees.size)
        assertEquals("axe", world.items.single().kind)
    }
}
```

- [ ] **Step 3: Ejecutar y ver que falla**

Run: `./gradlew :shared:jsBrowserTest`
Expected: FAIL — `Unresolved reference: ForestWebController`.

- [ ] **Step 4: Tipos exportados**

`WebModels.kt`:
```kotlin
@file:OptIn(ExperimentalJsExport::class)

package com.apergas.rpg.web

@JsExport class WebPoint(val x: Double, val y: Double)

@JsExport class WebState(val player: WebPlayer, val hud: WebHud, val placement: WebPlacement?)

@JsExport class WebPlayer(
    val position: WebPoint,
    val facing: String,
    val pose: String,
    val withAxe: Boolean,
    val tool: String?,
    val swingProgress: Double,
)

@JsExport class WebHud(
    val wood: Int,
    val hasAxe: Boolean,
    val questBadge: String,
    val quests: Array<WebQuestItem>,
    val buildItems: Array<WebBuildItem>,
    val isBuildLocked: Boolean,
)

@JsExport class WebQuestItem(val title: String, val progressText: String, val status: String)

@JsExport class WebBuildItem(
    val blueprint: String,
    val name: String,
    val costText: String,
    val missingText: String?,
    val isEnabled: Boolean,
)

@JsExport class WebPlacement(val blueprint: String, val position: WebPoint, val isValid: Boolean)

@JsExport class WebWorld(
    val width: Double,
    val height: Double,
    val trees: Array<WebTree>,
    val items: Array<WebItem>,
    val buildings: Array<WebBuilding>,
)

@JsExport class WebTree(val id: String, val position: WebPoint)

@JsExport class WebItem(val id: String, val kind: String, val position: WebPoint)

@JsExport class WebBuilding(val id: String, val blueprint: String, val position: WebPoint, val progress: Double)

@JsExport class WebEffect(
    val kind: String,
    val id: String?,
    val fromX: Double,
    val progress: Double,
    val text: String?,
    val building: WebBuilding?,
)

@JsExport class WebLabels(val wood: String, val axe: String, val build: String, val quests: String)
```

`WebMappers.kt`:
```kotlin
package com.apergas.rpg.web

import com.apergas.rpg.domain.entities.building.Building
import com.apergas.rpg.domain.entities.game.WorldSnapshot
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.presentation.forest.ForestEffect
import com.apergas.rpg.presentation.forest.ForestState
import com.apergas.rpg.presentation.forest.PlayerPose
import com.apergas.rpg.presentation.forest.QuestItemStatus
import com.apergas.rpg.presentation.forest.WorkTool

internal fun Position.toWeb() = WebPoint(x, y)

internal fun Building.toWeb() = WebBuilding(id, blueprint.id.name, position.toWeb(), progress)

internal fun WorldSnapshot.toWeb() = WebWorld(
    width = width,
    height = height,
    trees = trees.map { WebTree(it.id, it.position.toWeb()) }.toTypedArray(),
    items = items.map { WebItem(it.id, it.kind.name.lowercase(), it.position.toWeb()) }.toTypedArray(),
    buildings = buildings.map { it.toWeb() }.toTypedArray(),
)

internal fun ForestState.toWeb(): WebState {
    val pose = player.pose
    return WebState(
        player = WebPlayer(
            position = player.position.toWeb(),
            facing = player.facing.name.lowercase(),
            pose = when (pose) {
                is PlayerPose.Idle -> "idle"
                is PlayerPose.Walk -> "walk"
                is PlayerPose.Work -> "work"
            },
            withAxe = when (pose) {
                is PlayerPose.Idle -> pose.withAxe
                is PlayerPose.Walk -> pose.withAxe
                is PlayerPose.Work -> pose.tool == WorkTool.Axe
            },
            tool = (pose as? PlayerPose.Work)?.tool?.name?.lowercase(),
            swingProgress = (pose as? PlayerPose.Work)?.swingProgress ?: 0.0,
        ),
        hud = WebHud(
            wood = hud.wood,
            hasAxe = hud.hasAxe,
            questBadge = hud.questBadge,
            quests = hud.quests.map {
                WebQuestItem(it.title, it.progressText, when (it.status) {
                    QuestItemStatus.Done -> "done"
                    QuestItemStatus.Current -> "current"
                    QuestItemStatus.Pending -> "pending"
                })
            }.toTypedArray(),
            buildItems = hud.buildItems.map {
                WebBuildItem(it.blueprint.name, it.name, it.costText, it.missingText, it.isEnabled)
            }.toTypedArray(),
            isBuildLocked = hud.isBuildLocked,
        ),
        placement = placement?.let { WebPlacement(it.blueprint.name, it.position.toWeb(), it.isValid) },
    )
}

internal fun ForestEffect.toWeb(): WebEffect = when (this) {
    is ForestEffect.ItemPickedUp -> WebEffect("item-picked-up", itemId, 0.0, 0.0, null, null)
    is ForestEffect.TreeHit -> WebEffect("tree-hit", treeId, fromX, 0.0, null, null)
    is ForestEffect.TreeFelled -> WebEffect("tree-felled", treeId, fromX, 0.0, null, null)
    is ForestEffect.BuildingPlaced -> WebEffect("building-placed", building.id, 0.0, building.progress, null, building.toWeb())
    is ForestEffect.BuildingHammered -> WebEffect("building-hammered", buildingId, 0.0, progress, null, null)
    is ForestEffect.BuildingCompleted -> WebEffect("building-completed", buildingId, 0.0, 1.0, null, null)
    is ForestEffect.ShowMessage -> WebEffect("message", null, 0.0, 0.0, text, null)
}
```

- [ ] **Step 5: La fachada**

`ForestWebController.kt`:
```kotlin
@file:OptIn(ExperimentalJsExport::class)

package com.apergas.rpg.web

import com.apergas.rpg.di.GameContainer
import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.presentation.forest.ForestEffect
import com.apergas.rpg.presentation.forest.ForestIntent
import com.apergas.rpg.presentation.forest.ForestLabels
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * The shared ForestViewModel, exposed to the web with plain JS types. The Phaser scene calls it every
 * frame: `tick`, then `takeEffects` to play animations, then `state` to draw.
 */
@JsExport
class ForestWebController {
    private val viewModel = GameContainer.makeForestViewModel()
    private val pendingEffects = mutableListOf<ForestEffect>()

    init {
        // Unconfined: effects are collected synchronously, in the same call that emits them.
        CoroutineScope(Dispatchers.Unconfined).launch { viewModel.uiEffect.collect { pendingEffects += it } }
    }

    fun tick(deltaMs: Double) = viewModel.onIntent(ForestIntent.Tick(deltaMs))

    fun mapClicked(x: Double, y: Double, treeId: String?, isSecondary: Boolean) =
        viewModel.onIntent(ForestIntent.MapClicked(Position(x, y), treeId, isSecondary))

    fun pointerMoved(x: Double, y: Double) = viewModel.onIntent(ForestIntent.PointerMoved(Position(x, y)))

    fun requestBuild(blueprint: String) = viewModel.onIntent(ForestIntent.BuildRequested(BlueprintId.valueOf(blueprint)))

    fun cancelPlacement() = viewModel.onIntent(ForestIntent.PlacementCancelled)

    fun state(): WebState = viewModel.uiState.value.toWeb()

    fun world(): WebWorld = viewModel.worldSnapshot().toWeb()

    /** Effects emitted since the previous call, oldest first. */
    fun takeEffects(): Array<WebEffect> {
        val effects = pendingEffects.map { it.toWeb() }.toTypedArray()
        pendingEffects.clear()
        return effects
    }

    fun labels(): WebLabels = WebLabels(ForestLabels.WOOD, ForestLabels.AXE, ForestLabels.BUILD, ForestLabels.QUESTS)
}
```

- [ ] **Step 6: Ejecutar tests y generar el paquete**

Run: `./gradlew :shared:allTests :shared:jsBrowserProductionLibraryDistribution && sed -n 1,40p shared/build/dist/js/productionLibrary/rpg-shared.d.mts 2>/dev/null || sed -n 1,40p shared/build/dist/js/productionLibrary/rpg-shared.d.ts`
Expected: tests PASS; el `.d.ts`/`.d.mts` declara `export declare class ForestWebController` y las clases `Web*` **en el nivel superior**. Anotar el nombre exacto del fichero `.mjs`/`.js` principal y el del `.d.ts` (Task 2 los usa en `package.json` si el generado no trae `"types"`). Si las clases aparecen anidadas en `namespace com.apergas.rpg.web`, la importación en la Task 2 será `import { com } from 'rpg-shared'` y `const { ForestWebController } = com.apergas.rpg.web;`.

- [ ] **Step 7: Versionar el lock de Kotlin/JS**

Kotlin/JS descarga sus propias dependencias npm (webpack, karma…) y fija sus versiones en `kotlin-js-store/yarn.lock`, en la raíz. Se versiona para que el despliegue en GitHub resuelva exactamente las mismas.

Run: `ls kotlin-js-store/yarn.lock`
Expected: existe. Si un build futuro avisa de que el lock cambió, actualizarlo con `./gradlew kotlinUpgradeYarnLock` y subirlo en un commit aparte.

- [ ] **Step 8: Commit**

```bash
git add shared/ kotlin-js-store/
git commit -m "[PROJECT-X]: Export a web controller over the shared ForestViewModel"
```

---

### Task 2: La web consume `rpg-shared` y borra su lógica TypeScript

**Files:**
- Modify: `rpg/package.json`, `rpg/src/main.ts`, `rpg/src/presentation/screens/forest/ForestScene.ts`, `hud/Hud.ts`, `player/PlayerView.ts`, `world/TreeView.ts`, `world/ItemView.ts`, `world/BuildingView.ts`, `rpg/tests/architecture.test.ts`
- Move: `rpg/src/shared/seededRandom.ts` → `rpg/src/presentation/common/seededRandom.ts`
- Delete: `rpg/src/domain/`, `rpg/src/data/`, `rpg/src/presentation/common/labels.ts`, `rpg/src/presentation/screens/forest/ForestViewModel.ts`, `hud/HudViewModel.ts`, `player/PlayerViewModel.ts`, `rpg/tests/domain/`, `rpg/tests/data/`, `rpg/tests/presentation/`, `rpg/tests/fixtures.ts`

**Interfaces:**
- Consumes: `ForestWebController` y tipos `Web*` (Task 1).
- Produces: web funcional idéntica; `window.__rpg = { game, controller }` en desarrollo.

- [ ] **Step 1: Dependencia del paquete generado**

En `rpg/package.json`, `dependencies`:
```json
"rpg-shared": "file:../shared/build/dist/js/productionLibrary"
```
Run: `./gradlew :shared:jsBrowserProductionLibraryDistribution && cd rpg && npm install && ls node_modules/rpg-shared`
Expected: el paquete enlazado con su `.d.ts`.

- [ ] **Step 2: Borrar la lógica que ya vive en Kotlin**

```bash
cd rpg
git rm -r -q src/domain src/data tests/domain tests/data tests/presentation tests/fixtures.ts
git rm -q src/presentation/common/labels.ts src/presentation/screens/forest/ForestViewModel.ts \
  src/presentation/screens/forest/hud/HudViewModel.ts src/presentation/screens/forest/player/PlayerViewModel.ts
git mv src/shared/seededRandom.ts src/presentation/common/seededRandom.ts
```

- [ ] **Step 3: `main.ts`**

```ts
import * as Phaser from 'phaser';
import { ForestWebController } from 'rpg-shared';
import { ForestScene } from './presentation/screens/forest/ForestScene';
import { Hud } from './presentation/screens/forest/hud/Hud';
import { PreloadScene } from './presentation/screens/preload/PreloadScene';

// Composition root: game logic comes from the shared Kotlin module; this app only draws.
const controller = new ForestWebController();

const app = document.querySelector<HTMLElement>('#app');
if (!app) throw new Error('Missing #app container');

const hud = new Hud(app, controller.labels(), { build: (blueprint) => controller.requestBuild(blueprint) });
const forestScene = new ForestScene({ controller, hud });

const game = new Phaser.Game({
  type: Phaser.AUTO,
  backgroundColor: '#0e150e',
  pixelArt: true,
  scale: { mode: Phaser.Scale.RESIZE, parent: app, width: '100%', height: '100%' },
  scene: [new PreloadScene(ForestScene.KEY), forestScene],
});

// Dev-only handle for browser automation (e2e checks); stripped from production builds.
if (import.meta.env.DEV) {
  Object.assign(window, { __rpg: { game, controller } });
}
```

- [ ] **Step 4: `ForestScene.ts`** (sustituye entero el fichero)

```ts
import * as Phaser from 'phaser';
import type { ForestWebController, WebEffect } from 'rpg-shared';
import { CAMERA_ZOOM, ForestAtlas } from '../../common/assets';
import { Depth } from '../../common/depth';
import { seededRandom } from '../../common/seededRandom';
import type { Hud } from './hud/Hud';
import { PlayerView } from './player/PlayerView';
import { BuildingView, addHouseImage, placeHouseImage } from './world/BuildingView';
import { GroundView } from './world/GroundView';
import { ItemView } from './world/ItemView';
import { TreeView } from './world/TreeView';

export interface ForestSceneDependencies {
  readonly controller: ForestWebController;
  readonly hud: Hud;
}

const CAMERA_LERP = 0.1;
const TREE_VARIANT_SEED = 7;
/** Area around the spawn point kept clear of decor so the player does not start on top of it. */
const SPAWN_CLEARANCE = 48;
const GHOST_ALPHA = 0.6;
const GHOST_VALID_TINT = 0xb8ffb8;
const GHOST_INVALID_TINT = 0xff8080;

/**
 * Passive Phaser view of the game. Each frame: advance the shared view model, play the effects it
 * returns, draw its state. It only decides engine matters: sprites, hit-testing, camera and tweens.
 */
export class ForestScene extends Phaser.Scene {
  static readonly KEY = 'ForestScene';

  private readonly controller: ForestWebController;
  private readonly hud: Hud;
  private playerView!: PlayerView;
  private ghost: Phaser.GameObjects.Image | null = null;
  private readonly trees = new Map<string, TreeView>();
  private readonly items = new Map<string, ItemView>();
  private readonly buildings = new Map<string, BuildingView>();
  /** Non-solid ground sprites (decor, stumps) that a new building should clear away. */
  private clutter: Phaser.GameObjects.Image[] = [];

  constructor(deps: ForestSceneDependencies) {
    super(ForestScene.KEY);
    this.controller = deps.controller;
    this.hud = deps.hud;
  }

  create(): void {
    const world = this.controller.world();
    const spawn = this.controller.state().player.position;

    const random = seededRandom(TREE_VARIANT_SEED);
    for (const tree of world.trees) {
      const frame = ForestAtlas.TREES[Math.floor(random() * ForestAtlas.TREES.length)];
      this.trees.set(tree.id, new TreeView(this, tree.position, frame));
    }
    for (const item of world.items) this.items.set(item.id, new ItemView(this, item.position));
    for (const building of world.buildings) {
      this.buildings.set(building.id, new BuildingView(this, building.position, building.progress));
    }

    const spawnArea = new Phaser.Geom.Rectangle(
      spawn.x - SPAWN_CLEARANCE,
      spawn.y - SPAWN_CLEARANCE * 2,
      SPAWN_CLEARANCE * 2,
      SPAWN_CLEARANCE * 3,
    );
    const occupied = [spawnArea, ...[...this.trees.values(), ...this.items.values()].map((view) => view.bounds)];
    this.clutter = [...new GroundView(this, world.width, world.height, occupied).decor];
    this.playerView = new PlayerView(this, spawn);

    this.setUpCamera(world.width, world.height);
    this.setUpInput();
  }

  update(_time: number, delta: number): void {
    if (this.controller.state().placement) {
      const pointer = this.pointerInWorld();
      this.controller.pointerMoved(pointer.x, pointer.y);
    }
    this.controller.tick(delta);
    this.controller.takeEffects().forEach((effect) => this.play(effect));

    const state = this.controller.state();
    this.playerView.render(state.player);
    this.hud.render(state.hud);
    this.renderGhost(state.placement);
  }

  private play(effect: WebEffect): void {
    switch (effect.kind) {
      case 'message':
        if (effect.text) this.hud.showMessage(effect.text);
        break;
      case 'item-picked-up':
        this.items.get(effect.id ?? '')?.pickUp();
        this.items.delete(effect.id ?? '');
        break;
      case 'tree-hit':
        this.trees.get(effect.id ?? '')?.hit(effect.fromX);
        break;
      case 'tree-felled': {
        const stump = this.trees.get(effect.id ?? '')?.fell(effect.fromX);
        if (stump) this.clutter.push(stump);
        this.trees.delete(effect.id ?? '');
        break;
      }
      case 'building-placed': {
        if (!effect.building) break;
        const view = new BuildingView(this, effect.building.position, effect.building.progress);
        this.buildings.set(effect.building.id, view);
        this.clearClutterUnder(view.bounds);
        break;
      }
      case 'building-hammered':
        this.buildings.get(effect.id ?? '')?.hammered(effect.progress);
        break;
      case 'building-completed':
        this.buildings.get(effect.id ?? '')?.complete();
        break;
    }
  }

  private setUpInput(): void {
    this.input.mouse?.disableContextMenu();
    this.input.keyboard?.on('keydown-ESC', () => this.controller.cancelPlacement());

    this.input.on(Phaser.Input.Events.POINTER_DOWN, (pointer: Phaser.Input.Pointer) => {
      const { worldX: x, worldY: y } = pointer;
      this.controller.mapClicked(x, y, this.treeAt(x, y), pointer.rightButtonDown());
      this.controller.takeEffects().forEach((effect) => this.play(effect));
    });
  }

  /** Draws the placement preview, creating or removing it as needed. */
  private renderGhost(placement: { position: { x: number; y: number }; isValid: boolean } | null): void {
    if (!placement) {
      this.ghost?.destroy();
      this.ghost = null;
      return;
    }
    this.ghost ??= addHouseImage(this, placement.position).setAlpha(GHOST_ALPHA);
    placeHouseImage(this.ghost, placement.position)
      .setTint(placement.isValid ? GHOST_VALID_TINT : GHOST_INVALID_TINT)
      .setDepth(Depth.OVERLAY);
  }

  private pointerInWorld(): { x: number; y: number } {
    const pointer = this.input.activePointer;
    const point = this.cameras.main.getWorldPoint(pointer.x, pointer.y);
    return { x: point.x, y: point.y };
  }

  /** The tree drawn on top at this point, so overlapping canopies resolve to the front one. */
  private treeAt(x: number, y: number): string | null {
    let best: { id: string; depth: number } | null = null;
    for (const [id, view] of this.trees) {
      if (view.containsPoint(x, y) && (!best || view.depth > best.depth)) best = { id, depth: view.depth };
    }
    return best?.id ?? null;
  }

  private clearClutterUnder(area: Phaser.Geom.Rectangle): void {
    this.clutter = this.clutter.filter((sprite) => {
      if (!area.contains(sprite.x, sprite.y)) return true;
      sprite.destroy();
      return false;
    });
  }

  private setUpCamera(worldWidth: number, worldHeight: number): void {
    const camera = this.cameras.main;
    camera.setZoom(CAMERA_ZOOM);
    camera.startFollow(this.playerView.followTarget, true, CAMERA_LERP, CAMERA_LERP);

    // Keeps the camera inside the world; a world smaller than the window stays centred.
    const fitBounds = () => {
      const viewWidth = this.scale.gameSize.width / CAMERA_ZOOM;
      const viewHeight = this.scale.gameSize.height / CAMERA_ZOOM;
      camera.setBounds(
        Math.min(0, (worldWidth - viewWidth) / 2),
        Math.min(0, (worldHeight - viewHeight) / 2),
        Math.max(worldWidth, viewWidth),
        Math.max(worldHeight, viewHeight),
      );
    };
    fitBounds();
    this.scale.on(Phaser.Scale.Events.RESIZE, fitBounds);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => this.scale.off(Phaser.Scale.Events.RESIZE, fitBounds));
  }
}
```

- [ ] **Step 5: `PlayerView.ts`** — sustituir el método `render` y sus tipos:

```ts
import type * as Phaser from 'phaser';
import type { WebPlayer, WebPoint } from 'rpg-shared';
import { CHARACTER_ORIGIN_Y, FACING_DIRECTIONS, type FacingDirection, WorkSheet, WorkSheets } from '../../../common/assets';
import { Depth } from '../../../common/depth';

export function heroAnimationKey(state: 'walk' | 'idle', direction: FacingDirection, withAxe: boolean): string {
  return `hero-${state}-${direction}${withAxe ? '-axe' : ''}`;
}

/** Draws the player from the shared view model's state; only maps it to LPC sheets. */
export class PlayerView {
  private readonly shadow: Phaser.GameObjects.Ellipse;
  private readonly sprite: Phaser.GameObjects.Sprite;

  constructor(scene: Phaser.Scene, initial: WebPoint) {
    this.shadow = scene.add.ellipse(0, 0, 22, 7, 0x000000, 0.3).setDepth(Depth.SHADOW);
    this.sprite = scene.add.sprite(initial.x, initial.y, WorkSheets.CHOP.key);
  }

  get followTarget(): Phaser.GameObjects.Sprite {
    return this.sprite;
  }

  render(player: WebPlayer): void {
    const facing = player.facing as FacingDirection;
    if (player.pose === 'work') {
      const [sheet, sequence] =
        player.tool === 'axe' ? [WorkSheets.CHOP, WorkSheet.CHOP_SEQUENCE] : [WorkSheets.HAMMER, WorkSheet.HAMMER_SEQUENCE];
      const step = Math.min(sequence.length - 1, Math.floor(player.swingProgress * sequence.length));
      this.sprite.anims.stop();
      this.sprite.setTexture(sheet.key, FACING_DIRECTIONS.indexOf(facing) * WorkSheet.COLUMNS + sequence[step]);
      this.sprite.setOrigin(0.5, WorkSheet.ORIGIN_Y);
    } else {
      this.sprite.setOrigin(0.5, CHARACTER_ORIGIN_Y);
      this.sprite.anims.play(heroAnimationKey(player.pose === 'walk' ? 'walk' : 'idle', facing, player.withAxe), true);
    }

    const { x, y } = player.position;
    this.shadow.setPosition(x, y - 1);
    this.sprite.setPosition(x, y).setDepth(Depth.bySortY(y));
  }
}
```

- [ ] **Step 6: `Hud.ts`** — cambios exactos:
  1. Imports: sustituir los de `../../../../domain/...`, `../../../common/labels` y `./HudViewModel` por `import type { WebHud, WebLabels } from 'rpg-shared';`.
  2. `HudActions.build(blueprint: string)`.
  3. Constructor: `constructor(parent: HTMLElement, labels: WebLabels, actions: HudActions)`; en la plantilla sustituir `${Labels.wood}` → `${labels.wood}`, `${Labels.axe}` → `${labels.axe}`, `${Labels.quests}` → `${labels.quests}` (dos sitios), `${Labels.build}` → `${labels.build}`.
  4. `render(state: WebHud)`: borrar la línea del `message`/`serial`; `buildLocked` → `isBuildLocked`; en `renderQuests` usar `state.quests` tal cual (mismos campos); en `renderBuildItems`, `item.enabled` → `item.isEnabled`.
  5. `showMessage(text: string)` pasa de `private` a público (la escena la llama con los efectos `message`).
  6. `lastRendered: WebHud | null`; como `state()` crea objetos nuevos en cada fotograma, comparar por contenido: `const key = JSON.stringify(state); if (key === this.lastKey) return; this.lastKey = key;` sustituyendo la comparación por referencia.

- [ ] **Step 7: Vistas del mundo** — en `TreeView.ts`, `ItemView.ts` y `BuildingView.ts` sustituir el import de `Point` del dominio por `import type { WebPoint } from 'rpg-shared';` y renombrar el tipo `Point` → `WebPoint` en sus firmas.

- [ ] **Step 8: Test de arquitectura de la web** — sustituir `rpg/tests/architecture.test.ts` por:

```ts
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
```

- [ ] **Step 9: Comprobar tipos, tests y build**

Run: `cd rpg && npm run typecheck && npm test && npm run build`
Expected: sin errores; 2 tests; build generado.

- [ ] **Step 10: Partida e2e en navegador** — con `npm run dev -- --port 5179`, ejecutar el script Playwright de referencia adaptado: sustituir `window.__rpg.gameState.player()` por `window.__rpg.controller.state().player` (campos `position`, `pose`; `wood`/`hasAxe` ahora en `state().hud`), `gameState.snapshot()` por `controller.world()`, `gameState.quests()` por `controller.state().hud.quests` y la comprobación de sitio libre por `controller.pointerMoved(x, y); controller.state().placement.isValid`. Clicar el botón de casa con el selector `button[data-blueprint="House"]`.
Expected: hacha recogida; madera 5 → 10 → 16 tras los mismos árboles que antes; casa construida; misiones 3/3; `errors: none`. Revisar capturas: hachazo, árbol cayendo, fantasma verde/rojo, casa terminada, panel de misiones.

- [ ] **Step 11: Commit**

```bash
git add -A rpg shared
git commit -m "[PROJECT-X]: Switch the web app to the shared Kotlin core"
```

---

### Task 3: Despliegue a GitHub Pages con el paquete Kotlin

**Qué no cambia:** se sigue publicando con GitHub Actions (`actions/upload-pages-artifact` + `actions/deploy-pages`), en la misma URL, con el mismo `base: './'` de Vite y la misma configuración de Pages en el repositorio (origen "GitHub Actions"). Lo que se publica sigue siendo `rpg/dist`: HTML + JS + assets estáticos, ahora con el núcleo Kotlin compilado a JavaScript dentro del bundle.

**Qué cambia:**
1. `npm ci` necesita que exista el paquete `rpg-shared` (dependencia `file:../shared/build/dist/js/productionLibrary`), así que **antes** hay que instalar Java y generarlo con Gradle.
2. Antes de publicar se ejecutan los tests de `shared` que importan a la web (JVM y JS) en el mismo job Linux. Los de iOS se ejecutan solo en local (`./gradlew :shared:allTests`): el despliegue no necesita macOS.
3. Filtro de rutas: el despliegue solo se lanza si cambia algo que afecta a la web (`shared/`, `rpg/`, assets, Gradle o el propio workflow). Un commit que solo toca `androidApp/` o `iosApp/` no republica la web.
4. Tamaño: el bundle crece con el núcleo Kotlin/JS (la build de producción elimina el código no usado). Se mide antes y después para tenerlo controlado.

**Files:**
- Modify: `.github/workflows/deploy.yml` (se sustituye entero)

- [ ] **Step 1: Medir el bundle actual** (con el código anterior a la Task 2, para comparar)

Run: `git stash && (cd rpg && npm run build | grep -E "\.js ") ; git stash pop`
Anotar el tamaño de `assets/index-*.js` (sin y con gzip).

- [ ] **Step 2: Sustituir `.github/workflows/deploy.yml`**

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [main]
    paths:
      - 'shared/**'
      - 'rpg/**'
      - 'asset-packs/**'
      - 'kotlin-js-store/**'
      - 'gradle/**'
      - '*.gradle.kts'
      - 'gradle.properties'
      - '.github/workflows/deploy.yml'
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7

      # 1. Shared Kotlin core: the tests that matter for the web, then the npm package the web depends on.
      - uses: actions/setup-java@v5
        with:
          distribution: temurin
          java-version: 21
      - uses: gradle/actions/setup-gradle@v5
      - run: ./gradlew :shared:testDebugUnitTest :shared:jsBrowserTest :shared:jsBrowserProductionLibraryDistribution

      # 2. Web app: same steps as before the migration.
      - uses: actions/setup-node@v7
        with:
          node-version: 24
          cache: npm
          cache-dependency-path: rpg/package-lock.json
      - run: npm ci
        working-directory: rpg
      - run: npm run typecheck
        working-directory: rpg
      - run: npm test
        working-directory: rpg
      - run: npm run build
        working-directory: rpg

      - uses: actions/configure-pages@v6
      - uses: actions/upload-pages-artifact@v5
        with:
          path: rpg/dist

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v5
```

(Se quita `defaults.run.working-directory: rpg` porque Gradle corre en la raíz; cada paso de npm declara su `working-directory`.)

- [ ] **Step 3: Comprobar que `npm ci` funciona desde cero con el paquete local**

Run: `rm -rf rpg/node_modules shared/build && ./gradlew :shared:jsBrowserProductionLibraryDistribution && cd rpg && npm ci && npm run build`
Expected: instala y compila. Si `npm ci` avisa de que `package-lock.json` no coincide, regenerarlo con `npm install` y subirlo junto a este cambio.

- [ ] **Step 4: Push y verificación del despliegue**

```bash
git add .github/workflows/deploy.yml rpg/package-lock.json
git commit -m "[PROJECT-X]: Build the shared Kotlin package before deploying the web app"
git push
gh run list --limit 3
gh run watch --exit-status
```
Expected: `Deploy to GitHub Pages` en verde. Comprobar en la URL publicada (Playwright contra la URL de Pages) que carga sin errores de consola y que se completa la partida de referencia.

- [ ] **Step 5: Comparar el bundle**

Run: `cd rpg && npm run build | grep -E "\.js "`
Expected: anotar el nuevo tamaño frente al del Step 1. Si el JS con gzip crece más de unos cientos de KB, comprobar que se usa `jsBrowserProductionLibraryDistribution` (y no la de desarrollo) antes de seguir.

- [ ] **Step 6: Comprobar el filtro de rutas** — tras la fase 7, un commit que solo toque `androidApp/` **no** debe lanzar `Deploy to GitHub Pages` (`gh run list --workflow deploy.yml --limit 1` no muestra un run nuevo).

---

## Self-review de la fase

- [ ] `rpg/src` no contiene `domain/`, `data/`, ni ficheros `*ViewModel.ts`.
- [ ] Ningún texto de juego en TypeScript (`grep -rn "madera\|hacha\|Misión" rpg/src` solo encuentra comentarios o nada).
- [ ] La partida de referencia da los mismos números que antes de la migración.
