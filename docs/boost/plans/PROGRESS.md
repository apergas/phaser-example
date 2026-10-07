# Progreso del desarrollo

> Resumen de las dos hojas de ruta. El detalle de cada fase está en su plan:
> - Aldea: [`2026-10-04-game-design/`](2026-10-04-game-design/README.md)
> - Héroe y arena: [`2026-10-06-hero-arena/`](2026-10-06-hero-arena/README.md)
>
> Última actualización: 2026-10-07. Se actualiza al cerrar cada fase (`/cerrar-tarea`) y al pasar un plan de ficha a detallado.

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
| F1 Árboles con personalidad | 🟢 plan listo | — | Rama `feature/PROJECT-X-f1-…` desde `feature/PROJECT-X-town`. |
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
| C2 Pantalla de la arena | 🟢 plan listo | — | En paralelo con C3. Decisiones provisionales a revisar en la fase de pruebas. |
| C3 Herrería y Armería | 🟢 plan listo | — | En paralelo con C2. |
| C4 Lobos y oso | 📝 ficha | — | Necesita arte nuevo. Después de C2. |
| C5 Torre de magia | 📝 ficha | — | Después de C3. |
| C6 Bárbaros y jefe | 📝 ficha | — | Después de C4. |
| C7 Misiones y equilibrado | 📝 ficha | — | Al final (después de C1, C3 y C5). |

## Siguiente paso

- **Arena:** crear `feature/PROJECT-X-c2-arena-screen` y `feature/PROJECT-X-c3-forge-armory` desde `feature/PROJECT-X-arena` e implementarlas.
- **Aldea:** implementar F1 desde `feature/PROJECT-X-town`.
