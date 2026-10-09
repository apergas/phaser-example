# Progreso del desarrollo

> Resumen de las dos hojas de ruta. El detalle de cada fase está en su plan:
> - Aldea: [`2026-10-04-game-design/`](2026-10-04-game-design/README.md)
> - Héroe y arena: [`2026-10-06-hero-arena/`](2026-10-06-hero-arena/README.md)
>
> Última actualización: 2026-10-09. Se actualiza al terminar cada tarea (`/cerrar-tarea`) y al pasar un plan de ficha a detallado, con un commit en la misma rama de la tarea. Cada rama de integración lleva su copia al día; `develop` la recibe cuando entra la rama.

**Leyenda:**
- ✅ terminada.
- 🟢 plan detallado, lista para implementar.
- 📝 ficha: hay que detallar el plan al empezar.
- 💭 esbozo: se replanifica más adelante.

## Ramas

| Rama | Contenido | Destino |
|---|---|---|
| `develop` | Lo integrado de las dos partes y todos los planes (`docs/`). | `main` (publicado en GitHub Pages) |
| `feature/PROJECT-X-town` | Integración de la aldea: las fases F terminadas. | `develop`, por bloques jugables (README de la aldea, sección 3.0) |
| `feature/PROJECT-X-arena` | Integración de la arena: todo `develop` más las fases C terminadas. | `develop`, una sola vez, cuando la arena esté completa (README de la arena, sección 3.0) |

**Bloques de la aldea** (cada uno pasa a `develop` cuando está completo):
- **Bloque 1:** F1–F4 (árboles, guardado, rebrote y misiones).
- **Bloque 2:** F5–F8 (piedra, almacén, cantera y taller).
- **Bloque 3 en adelante:** F9–F15, cuando se replanifiquen.

## Aldea

| Fase | Estado | Dónde está | Notas |
|---|---|---|---|
| F0 Generalizar recursos, herramientas y edificios | ✅ | `develop` (#6), anterior a `town` | Incluye el arreglo de las líneas del suelo. |
| F1 Árboles con personalidad | 🟢 plan listo | — | Ramas `feature/PROJECT-F1-…` desde `feature/PROJECT-X-town`. |
| F2 Guardado automático | 📝 ficha | — | Antes de empezar: decidir cómo queda la sesión en el datasource (entidad frente a DBO). |
| F3 Rebrote de árboles | 📝 ficha | — | Después de F1. |
| F4 Misiones, capítulo 1 | 📝 ficha | — | Después de F3. |
| F5 Piedra y pico | 📝 ficha | — | Después de F0. |
| F6 Almacén y capacidad de carga | 📝 ficha | — | Después de F2. |
| F7 Cantera | 📝 ficha | — | Después de F5 y F6. |
| F8 Taller y mejoras de herramientas | 📝 ficha | — | Después de F5 y F6. |
| F9–F15 Comida, aldeanos, granja, estaciones, eras, mercader | 💭 esbozo | — | Se replanifican al terminar F8. |

## Arena

| Fase | Estado | Dónde está | Notas |
|---|---|---|---|
| C0 Contrato común | ✅ | `feature/PROJECT-X-arena` (#9) | Oro, caja del `World`, héroe y entidades de combate. |
| C1 Motor y niveles | ✅ | `feature/PROJECT-X-arena` (#10) | Lógica sin pantalla; 418 tests en verde. |
| C2 Pantalla de la arena | ✅ | `feature/PROJECT-X-arena` (#42) | Lleva unida C3 y resuelve los cruces; HUD con botones bajo la barra en pantallas estrechas. Decisiones provisionales a revisar en la fase de pruebas. |
| C3 Herrería y Armería | ✅ | `feature/PROJECT-X-arena` (#41) | Herrería, Armería y panel *Héroe*; el oro llega con C2. |
| C4 Lobos y oso | ✅ | `feature/PROJECT-X-arena` (merge directo, sin PR) | Lobo de Redshrike y oso de tapatilorenzo (CC-BY / OGA-BY, aceptado); niveles de animales y salto hacia el objetivo. |
| C5 Torre de magia | ✅ | `feature/PROJECT-X-arena` (merge directo, sin PR) | Torre de magia, catálogo `Skills`, pestaña *Habilidades* y nombres de las habilidades en la arena. Unida tras C4 con dos conflictos aditivos; 612 tests en verde. |
| C6 Bárbaros y jefe | ✅ | `feature/PROJECT-X-arena` (#51) | Bárbaros y jefe con capas LPC reales (cuero, barba, casco; jefe con casco vikingo), hacha de siempre; anillo bajo el objetivo y caídos al 50 %; *Campeón de la arena* con confeti e insignia en el panel *Héroe*. 630 tests en verde; prueba manual en Chrome y Android. |
| C7 Misiones y equilibrado | 🟢 plan listo | `feature/PROJECT-C7-hero-quests-balance` | Tres tareas: TC7.1 daño por rangos, TC7.2 línea de misiones del héroe, TC7.3 equipo sólo con oro y test de equilibrado (números finales). Plan ensayado: 637 tests en verde. |

## Siguiente paso

- **Arena:** implementar C7 en `feature/PROJECT-C7-hero-quests-balance`; después, el pulido de `ARENA-FIXES.md` y la PR de `feature/PROJECT-X-arena` a `develop`. Cambios y mejoras para el final, en [`ARENA-FIXES.md`](2026-10-06-hero-arena/ARENA-FIXES.md).
- **Aldea:** implementar F1 desde `feature/PROJECT-X-town`.
