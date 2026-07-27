---
name: crear-prd
description: |
  Genera un PRD estructurado (8 bloques) para trabajo de CÓDIGO en MV y lo escribe
  en `docs/prd/CR-<cr_id>.md` del repo destino — versionado con el código, revisable
  en el PR, y con `source_tier: alta` para el Company Brain. Consulta `test-decision`
  para la clasificación (no la re-decide) y `mv-instruction-generator` para el estilo
  de discovery interno. NO ejecuta código: especifica. Idempotente por `cr_id`.
trigger_phrases:
  - "/crear-prd"
  - "crear prd"
  - "generar prd"
  - "prd para este CR"
  - "prd de código"
  - "documentá el trabajo antes de implementar"
version: 1.0.0
owner: mv-dev
based_on:
  - PRD crear-prd (Fase 2) — 2026-07-27
  - test-decision (fuente única de clasificación)
  - docs/TRACEABILITY.md (convención código→CR)
---

# crear-prd — PRD estructurado para trabajo de código

Genera un **PRD** (Product Requirements Document técnico) de 8 bloques para trabajo
de código, a partir del template único `TEMPLATE.md` de esta misma skill.

> **Qué es y qué no es.**
> - **Especifica**, no ejecuta. La implementación es de `new-feature`, `create-api`,
>   `new-page`. Esta skill deja el documento y sale.
> - **No clasifica por su cuenta.** El bloque 3 se transcribe de
>   `/mv-dev:test-decision` (fuente única). No reimplementar el clasificador.
> - **Un PRD por CR.** Idempotente: si ya existe, linkea y sale.

## Cuándo se usa

- Un CR toca repo/app (área ∈ {Producto, Tech, Growth-Producto, Growth-Tech},
  destino `#iniciativas-tech`, tipo BET software, o la acción menciona
  repo/branch/deploy/endpoint/componente) y necesita spec antes de implementar.
- Standalone, cuando alguien quiere estructurar un trabajo de código antes de tocar
  nada.
- En Fase 2 esta skill **no bloquea nada**: genera el archivo y termina. El gate que
  la dispara automáticamente después de `crear-cr` es una fase posterior del PRD.

## Entradas

| Entrada | Requerido | Notas |
|---|---|---|
| `cr_id` | Sí | Formato `CR-xxxx`. Si no hay CR aún, crearlo con `/mv-dev:crear-cr` primero. |
| Repo destino | Sí | El PRD se escribe **ahí**, no en el repo del plugin ni en Notion. |
| `exp_id`, `kpi_definition_id` | No | Se completan si el trabajo está vinculado a un experiment/KPI. |
| Descripción del trabajo | Sí | Conversacional; alimenta los bloques 2 y 4. |

## Workflow

```
1. Resolver cr_id y repo destino.
       ↓
2. IDEMPOTENCIA (requisito duro):
   ¿existe docs/prd/CR-<cr_id>.md en el repo destino?
     → Sí: imprimir el path y SALIR sin escribir. Un PRD por CR.
     → No: continuar.
       ↓
3. Clasificar: invocar /mv-dev:test-decision con la descripción del cambio.
   Transcribir su veredicto (change-type + superficie + test + mock-vs-real)
   al bloque 3. NO re-decidir.
       ↓
4. Elegir modo de salida según el change-type de test-decision:
     - BUG defecto        → PRD ligero  (bloques 1, 3, 4, 5, 8)
     - BET / RESUME       → PRD completo (los 8 bloques)
     - BUG trivial        → no amerita PRD (avisar y salir; ver test-decision)
       ↓
5. Discovery interno (bloque 4), estilo mv-instruction-generator:
   grep real de los archivos afectados, dependencias, riesgos de regresión.
   Verificar rutas contra la rama base. Guards de pago: si toca archivo sagrado
   → marcarlo como STOP en el bloque 2 "qué NO cambia".
       ↓
6. Rellenar TEMPLATE.md con el contenido de cada bloque. Bloque 5 (plan de tests)
   respeta "cobertura primero": grep de tests existentes + baseline verde.
       ↓
7. Escribir docs/prd/CR-<cr_id>.md en el repo destino. Reportar el path.
   NO ejecutar código, NO abrir PR, NO tocar Notion.
```

### Los 8 bloques

| # | Bloque | Origen del contenido | Ligero |
|---|---|---|---|
| 1 | Identidad y trazabilidad | `cr_id`, `exp_id`, `kpi_definition_id`, Notion task, Discord thread, repo, branch | ✅ |
| 2 | Problema y alcance | Conversacional. **Obligatorio:** subsección "qué NO cambia" | — |
| 3 | Clasificación | Invocar `test-decision`. Transcribir, no re-decidir | ✅ |
| 4 | Discovery | Discovery interno estilo `mv-instruction-generator`: grep, dependencias, riesgos | ✅ |
| 5 | Plan de tests | Matriz de `test-decision` + "cobertura primero" | ✅ |
| 6 | Observabilidad | Qué evento/log se emite, dónde se lee, cómo se sabe que funcionó en prod. **Bloque nuevo** | — |
| 7 | Documentación | Qué doc se actualiza (`docs/` + Notion vía `doc-agent`) | — |
| 8 | DoD | Checklist verificable: tests, build, cobertura, doc, PR linkeado | ✅ |

Columna "Ligero": ✅ = presente también en el PRD ligero; — = solo en el completo.

## Idempotencia (requisito duro)

Antes de generar, chequear si ya existe `docs/prd/CR-<cr_id>.md`. Si existe:
imprimir el path y **salir sin escribir**. Nunca sobrescribir ni duplicar. Para
editar un PRD existente, editar el archivo a mano (se versiona con el código).

## Por qué en el repo destino y no en Notion

- Se versiona con el código: el diff del PRD es revisable en el PR.
- Entra al Company Brain con `source_tier: alta` (fuente de código, no de reunión).
- El PRD es el *contenido*; el estado vive en el datalake (fase posterior). El .md es
  la fuente del contenido, el datalake gana en estado.

## Restricciones

- **No reimplementa `test-decision`.** Lo invoca y transcribe.
- **No es un segundo generador de PRD.** Usa el único `TEMPLATE.md`. Ningún otro
  skill debe redefinir el formato del PRD.
- **No ejecuta, no commitea, no abre PR, no escribe en Notion.** Solo genera el .md.
- **Guards de pago:** si el discovery toca `checkout/PagoForm/payment/od-order/`
  `dailyfood/foodcourt/wallet/card-add/api/payment` → marcar STOP en el bloque 2.

## Relación con otras skills

- `/mv-dev:test-decision` — fuente única de clasificación (bloque 3) y del plan de tests (bloque 5).
- `/mv-dev:mv-instruction-generator` — referencia del estilo de discovery interno (bloque 4).
- `/mv-dev:crear-cr` — crea el CR que este PRD referencia (correr antes si no hay `cr_id`).
- `/mv-dev:mv-testing` — el "cómo" de escribir los tests que el bloque 5 declara.
- `new-feature` / `create-api` / `new-page` — implementan lo que este PRD especifica.
