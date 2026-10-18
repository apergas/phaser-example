# Botones del HUD en el móvil — ficha

> Arreglo o mejora sin fase propia: commits `[PROJECT-X]: …`.

| | |
|---|---|
| **Rama** | `feature/PROJECT-X-compact-hud-buttons`, desde `develop` |
| **Estado** | Hecho |

**Qué se quiere:** que los seis botones del HUD (*Misiones*, *Construir*, *Taller*, *Héroe*, *Arena*, *Partida*) se lean en un móvil apaisado (640×360).

**Por qué:** con texto miden unos 767 px; en 640 px el `FittedBox` los reducía hasta que el texto no se podía leer.

**Qué cambia:**
- `HudOverlay.compactButtonsWidth` (820 px, medido con Roboto como los demás umbrales: la fila con texto + 2 × 12 de margen + 24 de holgura, redondeado a la decena): por debajo, los botones solo llevan el icono (y la insignia de misiones).
- `HudButton.isCompact`: sin texto, relleno lateral de 10 y el nombre en un `Tooltip`.
- Dos iconos nuevos, `quests.svg` (pergamino) y `build.svg` (martillo), también visibles en el modo con texto. Eso ensancha la fila con texto de 714,7 a 766,7 px, así que `buttonsBelowWidth` pasa de 1570 a 1620.
- Los tests que buscaban los botones por texto en tamaños de móvil buscan por `Tooltip`.

**Prueba manual:** en Chrome con la ventana estrecha (< 820 px) los botones son iconos con su nombre al pasar el ratón; en el móvil apaisado caben sin reducirse; a partir de 820 px vuelven los textos.
