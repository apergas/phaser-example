# Rayas negras en el suelo de la arena — ficha

> Arreglo o mejora sin fase propia: commits `[PROJECT-X]: …`. Antes de implementarla, `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Rama** | `bugfix/PROJECT-X-arena-ground-seams`, desde `feature/PROJECT-X-arena` |
| **Estado** | Hecho (#61) |

**Qué pasa:** el suelo de la arena se ve con rayas negras horizontales entre las baldosas de hierba.

**Por qué:** `ArenaGroundComponent.render` (`features/arena/game/components/arena_ground_component.dart`) pinta la hierba como un mosaico de sprites `arena-grass` de 32 px, uno por baldosa, sacados del atlas `arena.png`. La cámara de la arena usa un zoom de cobertura entre 1 y 3 que casi nunca es entero. Con un zoom fraccionario, los bordes de cada baldosa caen entre píxeles de la pantalla: quedan huecos de un píxel donde se ve el fondo, y el muestreo también puede coger la fila vecina del atlas.

**Cómo se arregló en la aldea** (`d6e932d`, `[PROJECT-X]: Draw the ground as one repeated tile so no seams show between tiles`): `GroundComponent` dejó de pintar baldosa a baldosa. Ahora pinta **un solo rectángulo** del tamaño del mundo con un `Paint` cuyo `shader` es un `ImageShader(tile, TileMode.repeated, TileMode.repeated, identidad, filterQuality: FilterQuality.none)`, con `isAntiAlias = false`. La GPU repite la textura sin costuras a cualquier zoom. Para eso la baldosa tiene que ser una **imagen propia** (`lpc/ground.png`, que carga `LpcAssetsLoader`), no un trozo de un atlas: el shader repetiría el atlas entero.

**Arreglo** (hecho el 2026-10-17 en `37017c3`, #61; al final `ArenaGroundComponent` extiende `GroundComponent` en vez de copiar su `Paint`, y `arena-grass` salió del atlas):
- La hierba de la arena es la misma que la del bosque (`ARENA_GRASS` en `build_assets.py` toma la misma celda de `terrain_atlas.png`). `ArenaAssetsLoader` carga también `lpc/ground.png`, y `ArenaAssets` la expone como `ground` (`Image`).
- `ArenaGroundComponent` pinta la hierba con un `drawRect` del tamaño del escenario y el mismo `Paint` con `ImageShader` repetido que `GroundComponent`; la valla sigue igual. Si sale limpio, se puede compartir el `Paint` entre los dos componentes.
- Si `arena-grass` ya no se usa, sale de `ArenaSpriteNames` y del atlas (`build_assets.py` regenera `arena.png`/`arena.json`). El test del atlas de la arena y `ArenaAssetsMock` cambian con él.
- **Tests:** `arena_ground_component_test.dart` comprueba que la hierba se pinta con un solo rectángulo y shader, como `ground_component_test.dart` en el bosque.
- **Prueba manual:** la arena en Chrome con la ventana a varios tamaños (zoom no entero) y en Android: sin rayas.
