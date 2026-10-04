# phaser-example

Top-down (3/4 view) RPG prototype with one game core in **Kotlin Multiplatform** and three front ends:
web (**Phaser 4 + Vite**), Android (**Jetpack Compose**) and iOS (**SwiftUI + SpriteKit**). The core follows
Clean Architecture with the team's Android conventions; every app only draws.

```
shared/       Kotlin Multiplatform: domain, data, presentation (ForestViewModel), di (GameContainer)
androidApp/   Jetpack Compose + Hilt: only views
iosApp/       SwiftUI + SpriteKit: only views (Xcode project)
webApp/       Vite + Phaser 4: only views; consumes shared as the npm package rpg-shared
asset-packs/  LPC art sources and build_assets.py (feeds the three apps)
```

Layer rules are checked by `shared/src/androidHostTest/.../ArchitectureTests.kt` (Kotlin) and
`webApp/tests/architecture.test.ts` (web).

Gather-and-build loop: pick up the axe next to the spawn point, tap or click a tree to chop it (5 hits,
5–6 wood each), then use **Construir** to place a house (15 wood) and watch it being built. **Misiones** lists the
current goals and their progress.

## Run locally

```sh
./gradlew :shared:allTests                                 # shared tests on JVM, JS and iOS simulator
./gradlew :shared:jsBrowserProductionLibraryDistribution   # npm package for webApp
./gradlew :androidApp:installDebug                         # Android app on a running emulator
open iosApp/iosApp.xcodeproj                               # iOS app (Run builds the framework via Gradle)
cd webApp && npm install && npm run dev                    # web app (build the npm package first)
```

Needs a JDK 17+, the Android SDK (`local.properties` with `sdk.dir`) and Xcode for the iOS targets.

Every push to `main` that touches the web or the shared core runs the shared tests, builds the npm package and the
web app, and publishes `webApp/dist` to GitHub Pages (`.github/workflows/deploy.yml`).

## Art

- `asset-packs/lpc/` — Liberated Pixel Cup sources and `build_assets.py`, which generates the textures in
  `shared/assets/lpc/`, the single copy the web, Android and iOS apps all read (requires Pillow).

LPC art is licensed CC-BY-SA 3.0 / GPL 3.0 / OGA-BY 3.0 and requires attribution:
see [`shared/assets/lpc/CREDITS.md`](shared/assets/lpc/CREDITS.md).
