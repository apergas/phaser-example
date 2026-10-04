---
name: siguiente-tarea
description: Use at the start of a work session on the gameplay roadmap (docs/boost/plans/2026-10-04-game-design) to pick, claim and start the next task of your stream, with minimal context loading. Triggers on "siguiente tarea", "qué hago ahora", "next task", "empieza la fase".
---

# Siguiente tarea

Protocolo común para los dos desarrolladores (y sus IAs) de la hoja de ruta de jugabilidad. El objetivo es empezar a trabajar **sin leer el proyecto entero**.

## 1. Cargar el contexto mínimo (y nada más)

1. `CLAUDE.md`, que ya está en contexto.
2. `docs/boost/plans/2026-10-04-game-design/README.md`, secciones 2 (fases) y 3 (reglas de paralelo).
3. El estado en GitHub:

   ```bash
   gh issue list --repo apergas/phaser-example --state open --label "phase:F0,phase:F1,phase:F2,phase:F3,phase:F4,phase:F5,phase:F6,phase:F7,phase:F8" --json number,title,labels,assignees,milestone --limit 100
   gh issue list --repo apergas/phaser-example --state open --assignee @me --json number,title,labels
   ```

   Si `gh` no está instalado o autenticado, para y pide al usuario `! gh auth login`. No se puede asignar una tarea sin tracker.

No abras código todavía.

## 2. Elegir la tarea

1. Si ya tienes un issue asignado y abierto, **retómalo**: es tu tarea.
2. Si no, pregunta al usuario su flujo (`stream:A` o `stream:B`), salvo que ya lo haya dicho, y elige el primer issue abierto que cumpla todo esto:
   - es de su flujo (o de F0, que es de ambos);
   - no tiene asignado a nadie;
   - todas sus dependencias están cerradas: la columna *Depende de* de la tabla de fases y la línea `Depende de: #n` del issue;
   - no tiene la etiqueta `blocked`.
3. Si no hay ninguna disponible, dilo, explica qué la bloquea y propón:
   - (a) escribir el plan detallado de la siguiente fase del flujo, o
   - (b) coger una tarea libre del otro flujo.

Confirma la elección con el usuario antes de asignarla.

## 3. Reclamarla

```bash
gh issue edit <n> --repo apergas/phaser-example --add-assignee @me
gh issue comment <n> --repo apergas/phaser-example --body "En curso: rama feature/PROJECT-X-<fase>-<tarea>"
git switch develop && git pull && git switch -c feature/PROJECT-X-<fase>-<tarea>
```

Si existe el Project *Gameplay roadmap*, mueve la tarjeta a *In progress* con `gh project item-edit`.

## 4. ¿Hay plan detallado?

Abre el fichero de la fase (`F<n>-*.md`):

- **Plan detallado** (cabecera *For agentic workers*): lee **sólo la sección de tu tarea**. Sus *Files* e *Interfaces* son todo el contexto de código que necesitas.
- **Ficha** (aviso "Plan detallado: pendiente"):
  1. Usa `boost:writing-plans` para convertir la ficha en un plan con tareas T<n>.x. Lee sólo los ficheros que lista la ficha.
  2. Respeta las *Global Constraints* del README.
  3. Haz un commit del plan en una rama `feature/PROJECT-X-f<n>-plan`. Con la confirmación del usuario, abre un PR de documentación y crea un issue por tarea (labels `phase:F<n>`, `stream:*`, `platform:*`; milestone de la fase; cuerpo con enlace a la sección del plan y `Depende de: #n`).
  4. Cierra el issue de la ficha, o conviértelo en el issue de la primera tarea.
  5. Vuelve al paso 2.

## 5. Ejecutar

Usa `boost:subagent-driven-development` (recomendado) o `boost:executing-plans` sobre **tu tarea**, siguiendo TDD (`boost:test-driven-development`).

Reglas:
- Marca los checkboxes del plan según avances.
- Los ficheros calientes y el atlas siguen las reglas de la sección 3 del README.
- Commits `[PROJECT-X]: Imperative description`, **sin ninguna atribución a IA**.

Al terminar, usa `/cerrar-tarea`.
