---
name: editar-experimento
description: |
  Edita un experimento ya creado sin re-crearlo. Input: link Notion o exp_id. Detecta etapa
  (Propuesta/En curso = editable · Medido = bloqueado salvo force). Edita KPIs, CRs, hipótesis,
  fechas, owner. Sincroniza los 3 destinos a la vez: datalake (experiments) + Notion (plantilla
  issue) + Discord (update al hilo del CR). Notion se mantiene como capa visual del datalake.
trigger_phrases:
  - "/editar-experimento"
  - "editar experimento"
  - "editar iniciativa"
  - "actualizar experimento"
  - "editar issue"
  - "cambiar KPI de exp"
version: 1.1.0
owner: Julio Mori
based_on:
  - Reqs Carlos 2026-07-17 (Company Brain v2)
  - producto/estrategia/iniciativa-ai-native-dev/08-company-brain-v2-carlos.md
---

# Skill `editar-experimento` v1.1.0

> Edita un experimento existente y sincroniza **datalake + Notion (plantilla issue) + Discord** en una sola operación. Sin re-crear desde cero. Notion queda como **capa visual estructurada** del datalake — no se edita prosa a mano.
>
> **Fase 3 seguridad Brain:** toda la publicación es server-side — `POST /api/experiments/sync` es tri-destino (datalake + Notion + Discord) y el server ya publica con sus propias credenciales. El skill nunca escribe a Notion/Discord directo ni maneja tokens de servicio.

## Regla arquitectural (Carlos 2026-07-17)

- El **experimento** vive en el datalake (`experiments`) — fuente de verdad.
- Su reflejo en Notion usa la **plantilla ISSUE** (DB "Issue Inventory" (`202fb2dd`)): Issue Name, Decision Maker, Fecha ejecucion, Nombre KPIs, Meta KPIs, Issue Description, Status.
- Las secciones **TASK/ISSUE de Notion se editan lo menos posible** → solo campos estructurados (tabla) + comentarios. Nunca prosa libre.
- Toda edición estructurada pasa por este skill → sincroniza los 3 destinos.

## Cuándo se activa

- "Edita el experimento exp-2026-014, cambia el KPI a X"
- "Pega esta acta de reunión al experimento [link Notion] y actualiza lo acordado"
- Tras una reunión: pegar acuerdos → el skill estructura los cambios (no editar Notion a mano).

## Input

- **link Notion** del experimento (issue) **o** `exp_id` (ej. `exp-2026-014`).
- Opcional: acta/acuerdos de reunión en texto → el skill extrae los cambios estructurados.

## Flujo (7 pasos)

```
1. Resolver exp_id (del link Notion o directo)
   ↓
2. GET /api/experiments/:id → estado + campos actuales
   ↓
3. Guard de etapa:
   - Propuesta / En curso → editable
   - Medido (cerrado) → BLOQUEADO. Pedir confirmación: "cerrado, ¿forzar? (force=true)"
   ↓
4. Determinar el diff (desde el input del usuario / acta):
   - KPI (re-valida hard-gate: score ≥0.15 o kpi_definition_id explícito)
   - CRs/acciones · hipótesis (apuesta) · diseño · fecha_evaluacion · owner · estado
   ↓
5. POST /api/experiments/sync — el SERVER aplica los 3 destinos:
   - datalake: PATCH experiments
   - Notion: update plantilla issue (campos estructurados)
   - Discord: 🔄 update al hilo del CR (link_cr)
   ↓
6. Si algún destino devuelve ok=false → reportar al usuario y reintentar vía /sync
   (NO completar el update con tokens de cliente — sin escrituras client-side)
   ↓
7. Reportar: qué cambió, en qué 3 destinos, links
```

## Campos editables

| Campo | Notion (plantilla issue) | Datalake |
|-------|--------------------------|----------|
| `kpi_definition_id` | Nombre KPIs (verbatim) | kpi_definition_id |
| `target_mde` | Meta KPIs | target_mde |
| `apuesta` (hipótesis) | Issue Description | apuesta |
| `acciones` (CRs) | Issue Description | acciones |
| `fecha_evaluacion` | Fecha ejecucion | fecha_evaluacion |
| `estado` | Status (Not started/In progress/Done) | estado |
| `owner_dri` | Decision Maker | owner_dri |
| `tipo` | Decision Type | tipo |
| `nombre` | Issue Name | nombre |
| `paises` | — | paises |

**NO editables** (los pone `informe-resultados` al cerrar): `resultado`, `impacto_pct`, `insight`, `conclusion`, `id`, `created_at`, `fuente`.

## Endpoint

> ⚠️ Auth: header `x-api-key: $MV_BRAIN_TOKEN`. Si `MV_BRAIN_TOKEN` no está definida, DETENTE y pide al usuario solicitar su token a BizOps (Julio). Sin fallback.

```bash
POST /api/experiments/sync
Headers: x-api-key: $MV_BRAIN_TOKEN
Body: {
  "id": "exp-2026-014",
  "cambios": { "kpi_definition_id": 27, "fecha_evaluacion": "2026-08-01", "apuesta": "..." },
  "force": false,               # true para editar experimento Medido
  "notion_page_id": "...",      # opcional (o se resuelve de experiments.notion_id)
  "resumen": "Cambié KPI a reconsumo y moví fecha por reunión Weekly Sem 30"
}
```

Respuesta:
```json
{
  "ok": true,
  "datalake": { "ok": true, "edited_fields": ["kpi_definition_id","fecha_evaluacion"] },
  "notion": { "ok": true, "fields_updated": ["Nombre KPIs","Fecha ejecucion"] },
  "discord": { "ok": true, "permalink": "https://discord.com/channels/..." }
}
```

### Guard de etapa

`PATCH /api/experiments/:id` y `/sync` devuelven **409** si `estado='Medido'` y no viene `force=true`. Para re-abrir un experimento cerrado: `force=true` + rationale en `resumen`.

## Manejo del write a Notion (100% server-side)

El token "Token Brain" de Notion tiene RW total en workspace "Manzana Verde" (verificado 2026-07-18: create+update+archive OK sobre Issue Inventory `202fb2dd` + Tasks `95684528`) y vive **solo en Vercel (data-lake-mv)**. El endpoint `/sync` actualiza los 3 destinos server-side.

Flujo: `/sync` → PATCH datalake + PATCH Issue Inventory (`202fb2dd`, campos estructurados de la plantilla issue, sin romper estructura) + update al hilo Discord. Si `notion.ok=false` en la respuesta → reportar y reintentar vía `/sync`; **NO completar el update con tokens de cliente** (Fase 3: sin escrituras client-side).

**Status es tipo `status`** (no select). Fecha ejecucion/resultados = date expandido.

## Ejemplo de uso (acta de reunión)

```
Usuario: "Edita exp-2026-014. En la reunión Weekly Sem 30 acordamos:
  - cambiar el KPI a reconsumo (KPI 27)
  - mover la evaluación al 1 de agosto
  - agregar acción: piloto 200 clientes antes del rollout"

Skill:
  1. Resuelve exp-2026-014, estado='En curso' → editable
  2. Diff: kpi_definition_id=27, fecha_evaluacion=2026-08-01, acciones+=piloto
  3. POST /sync → datalake + Notion issue + Discord update
  4. Reporta: "✅ 3 campos editados. Notion issue actualizado. Update posteado al hilo CR."
```

## Vinculación con otros skills

```
exp-iniciativa (crea) → editar-experimento (modifica) → informe-resultados (cierra)
                         ↑
              kpi-context (consulta antes de editar)
```

## Dependencias

- ✅ `PATCH /api/experiments/:id` con guard etapa + re-validar KPI (deployado)
- ✅ `POST /api/experiments/sync` tri-destino (deployado) — el server publica a datalake + Notion + Discord con sus propias credenciales (solo en Vercel `data-lake-mv`)
- ✅ Token "Token Brain" de Notion RW a Issue Inventory (`202fb2dd`) + Tasks (`95684528`) — workspace Manzana Verde, verificado 2026-07-18, server-side
- ✅ Update al hilo Discord: lo hace el server (bot CRS server-side, sin token de servicio en cliente)
- ✅ Env cliente: solo `MV_BRAIN_TOKEN` (header `x-api-key`)
- ✅ Conectado al plugin `mv-dev` v1.8.0 (skills/editar-experimento)

## Changelog

- **v1.1.0 (2026-08-07): publicación migrada a server-side (Fase 3 seguridad Brain) — sin tokens de servicio en cliente.** Eliminado el uso de token de servicio del bot Discord y el fallback de completar el update Notion con token de sesión. `POST /api/experiments/sync` (params: `id`, `cambios{}`, `force`, `notion_page_id`) es tri-destino y el server ya publica. Auth cliente: solo `x-api-key: $MV_BRAIN_TOKEN`.
- **v1.0.1 (2026-07-18)** — Token "Token Brain" válido (RW workspace Manzana Verde) reemplaza workaround MCP/401. IDs verificados: Issue Inventory `202fb2dd` + Tasks `95684528`. Status = tipo `status`.
- **v1.0.0 (2026-07-17)** — Build inicial (req Carlos Company Brain v2). Edición tri-destino, guard etapa, plantilla issue, re-validación KPI.

---

**FIN.** Endpoints: `api/experiments/sync.js` + `api/experiments/[id].js` en repo `manzana-verde-datalake`.
