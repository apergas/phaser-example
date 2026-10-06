---
name: siguiente-tarea
description: Use at the start of a work session on the gameplay roadmaps (docs/boost/plans/2026-10-04-game-design and docs/boost/plans/2026-10-06-hero-arena) to pick, claim and start the next task of your stream, with minimal context loading. Triggers on "siguiente tarea", "qué hago ahora", "next task", "empieza la fase".
---

# Siguiente tarea

Protocolo común para los dos desarrolladores (y sus IAs) de las dos hojas de ruta de jugabilidad:

- **Aldea** (`docs/boost/plans/2026-10-04-game-design/`): fases `F*`, flujos `stream:A` y `stream:B`.
- **Héroe y arena** (`docs/boost/plans/2026-10-06-hero-arena/`): fases `C*`, flujos `stream:C` y `stream:D`.

En lo que sigue, "el README" es el del plan de la tarea; las reglas de paralelo (sección 3 del plan de la aldea) valen para los dos. El objetivo es empezar a trabajar **sin leer el proyecto entero**.

## 1. Cargar el contexto mínimo (y nada más)

1. `CLAUDE.md`, que ya está en contexto.
2. `docs/boost/plans/2026-10-04-game-design/README.md`, secciones 2 (fases), 3 (reglas de paralelo) y 6 (convivencia). Si el desarrollador trabaja en la arena (o la tarea elegida es `C*`), también `docs/boost/plans/2026-10-06-hero-arena/README.md`, secciones 2 y 3.
3. El estado en GitHub:

   ```bash
   gh issue list --repo apergas/phaser-example --state open --label "phase:F0,phase:F1,phase:F2,phase:F3,phase:F4,phase:F5,phase:F6,phase:F7,phase:F8,phase:C0,phase:C1,phase:C2,phase:C3,phase:C4,phase:C5,phase:C6,phase:C7" --json number,title,labels,assignees,milestone --limit 100
   gh issue list --repo apergas/phaser-example --state open --assignee @me --json number,title,labels
   ```

   - Si `gh` no está instalado o autenticado, para y pide al usuario `! gh auth login`. No se puede asignar una tarea sin tracker.
   - Si el tracker todavía no existe (no hay labels `phase:*`), propón crearlo según la sección 4 de cada README y, con la confirmación del usuario, crea labels, milestones, issues de F0 (T0.1, T0.2) y uno por fase para F1–F8.
   - Si faltan las labels `phase:C*` (plan de la arena), propón crearlas igual: issues de C0 (TC0.1, TC0.2) y uno por fase para C1–C7.

No abras código todavía.

## 2. Elegir la tarea

1. Si ya tienes un issue asignado y abierto, **retómalo**: es tu tarea.
2. Si no, pregunta al usuario su flujo (`stream:A`, `stream:B`, `stream:C` o `stream:D`), salvo que ya lo haya dicho, y elige el primer issue abierto que cumpla todo esto:
   - es de su flujo (o de F0 / C0, que son comunes);
   - no tiene asignado a nadie;
   - todas sus dependencias están cerradas: la columna *Depende de* de la tabla de fases de su plan (C0 depende de F0, del otro plan) y la línea `Depende de: #n` del issue;
   - no tiene la etiqueta `blocked`.
3. Si no hay ninguna disponible, dilo, explica qué la bloquea y propón:
   - (a) escribir el plan detallado de la siguiente fase del flujo, o
   - (b) coger una tarea libre del otro flujo, o
   - (c) coger una fase libre del otro plan (escenario *mixto*, sección 3.1 del README de la arena).

Confirma la elección con el usuario antes de asignarla.

## 3. Reclamarla

```bash
gh issue edit <n> --repo apergas/phaser-example --add-assignee @me
gh issue comment <n> --repo apergas/phaser-example --body "En curso: rama feature/PROJECT-X-<fase>-<tarea>"
git switch develop && git pull && git switch -c feature/PROJECT-X-<fase>-<tarea>
flutter pub get
```

Si existe el Project *Gameplay roadmap*, mueve la tarjeta a *In progress* con `gh project item-edit`.

## 4. ¿Hay plan detallado?

Abre el fichero de la fase (`F<n>-*.md` o `C<n>-*.md`):

- **Plan detallado** (cabecera *For agentic workers*): lee **sólo la sección de tu tarea**. Sus *Files* e *Interfaces* son todo el contexto de código que necesitas.
- **Ficha** (aviso "Plan detallado: pendiente"):
  1. Usa `boost:writing-plans` para convertir la ficha en un plan con tareas T<n>.x. Lee sólo los ficheros que lista la ficha.
  2. Respeta las *Global Constraints* del README y las convenciones del plugin `flutter-arch-conventions` (y sus skills de generación para entidades, DBOs, *mappers*, repositorios, casos de uso y BLoC).
  3. Haz un commit del plan en una rama `feature/PROJECT-X-<fase>-plan` (`f<n>` o `c<n>`). Con la confirmación del usuario, abre un PR de documentación y crea un issue por tarea (labels `phase:<fase>`, `stream:*`; milestone de la fase; cuerpo con enlace a la sección del plan y `Depende de: #n`).
  4. Al escribirlo, revisa la sección 6 del README de la aldea (o la 3 del de la arena): si alguna fase del otro plan ya está en `develop`, la nota *Si la arena ya está* / el cruce correspondiente forma parte de tu tarea.
  5. Cierra el issue de la ficha, o conviértelo en el issue de la primera tarea.
  6. Vuelve al paso 2.

## 5. Ejecutar

Usa `boost:subagent-driven-development` (recomendado) o `boost:executing-plans` sobre **tu tarea**, siguiendo TDD (`boost:test-driven-development`).

Reglas:
- Marca los checkboxes del plan según avances.
- Los ficheros calientes, los generados y el atlas siguen las reglas de la sección 3 del README.
- Revisa la arquitectura con el agente `flutter-arch-conventions:flutter-arch-reviewer` antes de cerrar.
- Commits `[PROJECT-X]: Imperative description`, **sin ninguna atribución a IA**.

Al terminar, usa `/cerrar-tarea`.
