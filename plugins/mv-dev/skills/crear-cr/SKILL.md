---
name: crear-cr
description: |
  Crea Change Requests (CRs) e Iniciativas vía endpoint server-side del datalake
  (POST /api/crear-cr — fanout datalake → Notion → Discord). Routing v1.8:
  tarea de reunión semanal → #weekly-exec-okrs; issue/iniciativa tech → #iniciativas-tech;
  issue no-tech → #issues-líderes/#issues-general; CR cross-equipos → canales crs-* específicos.
  Tag obligatorio del responsable con <@id>.
  El skill decide (routing, granularidad, naming, gate de PRD) y el server publica.
trigger_phrases:
  - "/crear-cr"
  - "crear CR"
  - "crear iniciativa discord"
  - "nuevo change request"
  - "abrir CR para"
version: 1.12.0
owner: Julio Mori
based_on:
  - producto/estrategia/iniciativa-ai-native-dev/04-skill-crear-cr.md
  - api/crear-cr/index.js (repo manzana-verde-okr — contrato canónico del endpoint)
  - n8n workflow q9K38OEiEju9eazK (MV - Issues a Discord)
  - memoria proyecto Discord: reference_discord_mv, project_mv_cr_workflow, feedback_discord_workflow, feedback_cr_tag_responsable, reference_notion_mv_databases
---

# Skill `crear-cr` v1.12.0

> Sprint Company Brain — cable iniciativa/issue → datalake + Discord + Notion.
>
> **Reglas clave:**
> 1. **🔥 REGLA CRÍTICA — 1 tarea = 1 CR = 1 Notion task = 1 Discord thread.** Aplica a weekly (`es_weekly`) y cross-equipos (`cr_pair`): si hay N acciones, hay que crear N CRs separados (no 1 thread con todas las acciones dentro). Cada CR es atómico: tiene su propia Notion page, su propio responsable, su propio deadline, su propio DoD. Excepciones: (a) `#iniciativas-tech` consolida 1 hilo por OWNER (lo aplica el server automáticamente); (b) **`tipo='iniciativa'` = exactamente 2 CRs canónicos** derivados del experiment ("Ejecución" + "Medición y conclusiones") — el detalle de tareas vive en el PRD, los CRs son puntos de control (ver "Modo INICIATIVA").
> 2. **Reunión semanal** — tarea que sale de una Weekly Exec (`es_weekly=true`) → `#weekly-exec-okrs`. Se crean con `crear-cr` directo cuando hay contexto de la reunión.
> 3. **Issue/iniciativa tech** (software · Producto/Tech/Growth-Tech) → `#iniciativas-tech`.
> 4. **Issue no-tech** → `#issues-líderes` (owner líder o estratégico) o `#issues-general` (equipo).
> 5. **CR interno cross-equipos** con acuerdo previo → canal `#crs-*` específico (6 canales, ver mapping).
> 6. **Publicación 100% server-side (Fase 3 seguridad Brain):** el skill arma el payload y hace **UNA** llamada a `POST /api/crear-cr`. El server hace el fanout completo (INSERT en `public.crs` → página Notion → thread Discord type 11 + mensaje → cross-links). El skill **nunca** llama a las APIs de Discord/Notion directamente ni maneja tokens de servicio.

## Server + bot

- **Guild:** `manzanaverde` — ID `619991595613290496`
- **Bot publicador:** `CRS#6481` — ID `1493662108431417354`. Su token vive **solo server-side** (Vercel `data-lake-mv`) — el skill nunca maneja tokens de servicio.
- **Acceso del bot:** Send Messages + Create Threads + Read Message History en todas las categorías relevantes.

## Endpoint canónico — `POST /api/crear-cr`

```
POST https://data-lake-mv.manzanaverde.la/api/crear-cr
Headers:
  x-api-key: $MV_BRAIN_TOKEN
  Content-Type: application/json
```

> ⚠️ **Auth:** header `x-api-key: $MV_BRAIN_TOKEN` (scope `write:cr`). Si `MV_BRAIN_TOKEN` no está definida, DETENTE y pide al usuario solicitar su token a BizOps (Julio). Sin fallback.

**Orden de escritura server-side** (el CR nace en el datalake y desde ahí se publica):

1. `INSERT` en `public.crs` ← **fuente de verdad**, ID `cr-YYYY-NNN` autogenerado (max+1 sobre formato canónico). Si falla, no hay CR.
2. Página en Notion Tasks DB ← best-effort, status en `sync_status.notion`.
3. Hilo Discord (thread directo type 11, auto-archive 10080 min) + mensaje ← best-effort, status en `sync_status.discord`.
4. Cross-link (permalink Discord → Notion) + `PATCH crs` con permalinks y `sync_status`.

Ningún fallo de (2) o (3) tumba la request: el CR queda registrado y se puede reintentar salteando destinos ok (ver `sync_status` en `public.crs`).

### Contrato del body (verificado contra `api/crear-cr/index.js`)

```jsonc
{
  "owner_dri": "Larissa Arias",            // ✅ REQUERIDO (400 si falta)
  "owner_notion_id": "uuid",               // opcional — si falta, lookup server-side en LEADERS
  "owner_discord_id": "id",                // opcional — idem

  "acciones_array": [                      // ✅ REQUERIDO (400 si falta o vacío) — 1 item = 1 CR = 1 Notion = 1 hilo.
                                           //    EXCEPCIÓN: tipo='iniciativa' NO lo exige (puede omitirse; el server lo IGNORA
                                           //    y deriva 2 CRs canónicos del experiment — si mandas acciones, se colapsan)
    {
      "nombre_corto": "Piloto 200 clientes",   // título del CR
      "descripcion": "…",
      "deadline": "2026-08-15",                // ISO — opcional; fallback: `deadline` top-level
      "dod": ["evidencia 1", "evidencia 2"],   // opcional — checklist DoD (Notion to_do; Discord postea máx 8)
      "contexto": "…",                         // opcional — sección 🎯 Contexto
      "refs": ["link o nota"],                 // opcional — sección 🔗 Refs
      "sub_owner": "Nombre",                   // opcional — owner distinto para ESTA tarea
      "sub_owner_notion_id": "uuid",           // opcional
      "sub_owner_discord_id": "id",            // opcional
      "es_rat": true,                          // marca RAT — blocker de las demás tareas
      "kpi_numbers": [27]                      // opcional — override de KPIs por acción
    }
  ],

  "tipo": "BET | iniciativa | issue | issue-legacy | weekly-cr | cross-equipos",  // opcional
  "area": "Producto | Tech | Growth - Producto | Growth - Tech | Growth | Operaciones | MKT | Reconsumos | Finanzas | DK | CX",
  "cr_pair": "atc-ops-daily | atc-ops-foodcourt | finanzas-ops-daily | finanzas-ops-foodcourt | finanzas-ventas-atc-mkt | ops-interno",
  "es_weekly": true,                       // tarea de reunión semanal → #weekly-exec-okrs
  "estrategico": true,                     // fuerza #issues-líderes para no-líderes
  "weekly_sem": 32,                        // número de semana para naming weekly
  "deadline": "2026-08-15",                // fallback global si la acción no trae deadline

  "exp_id": "exp-2026-014",                // vincula al experimento: refs + naming iniciativa + AUTO-LINK server-side de experiments.link_cr con el permalink del thread/Notion (solo si estaba vacío) — SIEMPRE pasarlo cuando el CR corresponde a un experiment del datalake. ✅ REQUERIDO si tipo='iniciativa' (400 sin él)
  "issue_page_id": "notion-page-id",       // relation `Issue Inventory (Tasks)` en la task
  "kpi_numbers": [27, 64],                 // NÚMEROS del catálogo dris_definitions (no strings)
  "sin_prd_rationale": "…",                // se graba junto al CR (bypass gate PRD)

  "dry_run": false                         // true → resuelve routing/naming/body y NO escribe nada
}
```

### Modo comentario (desde 2026-08-10 — BRAIN-CICLO-COMPLETO Fase 3)

Para postear en un hilo Discord **YA existente** sin crear ningún CR (caso típico: avisar al dueño que su CR se cerró):

```json
POST /api/crear-cr
{ "thread_id": "1532854276349493349", "mensaje": "<@discord_id> ✅ CR cerrado — …", "dry_run": true }
```

- `thread_id` = snowflake numérico del hilo (está en `crs.discord_thread_id` o en el permalink).
- NO crea fila en `crs`, NO toca Notion — solo postea el mensaje (tope 1900 chars).
- Respuesta: `{ok, mode:'comment', thread_id, discord:{message_id}}`. Usa `dry_run:true` primero para preview.
- Incluye el tag `<@discord_id>` del dueño en el mensaje — sin tag no hay notificación.

### Modo INICIATIVA (desde 2026-08-11 — DOCS-BRAIN Fase 3): 2 CRs + 1 hilo + 1 mensaje

`tipo='iniciativa'` desvía a la rama `handleIniciativa` del server. La regla 1-tarea-1-CR **no aplica acá**: el detalle de tareas vive en el PRD, los CRs son puntos de control.

- **`exp_id` es REQUERIDO** → 400 sin él ("los 2 CRs canónicos se derivan del experiment") · 404 si el experiment no existe en el datalake.
- **`acciones_array` se IGNORA** (puede omitirse — es la forma recomendada). Si mandas acciones igual, el server las **COLAPSA** en los 2 CRs canónicos y lo avisa en `next_steps` ("Las N acciones enviadas se colapsaron en 2 CRs canónicos — el detalle de tareas va al PRD").
- El server crea **exactamente 2 CRs canónicos** derivados del experiment:

| # | Título | Deadline | DoD |
|---|--------|----------|-----|
| 1 | `Ejecución — {nombre}` | `experiments.fecha_launch` (fallback `deadline` top-level) | PRD ejecutado hasta el launch · Piloto en marcha |
| 2 | `Medición y conclusiones — {nombre}` | `experiments.fecha_evaluacion` | /informe-resultados corrido · Gate decidido · insight y conclusion escritos |

**Flujo two-pass server-side:**

1. **1ª pasada — datalake + Notion por CR** (sin Discord): por cada uno de los 2 CRs → `INSERT cr-YYYY-NNN` en `public.crs` (`tipo='iniciativa'`, `es_weekly=false`, `kpi_numbers=[kpi_definition_id]` heredado del experiment, `exp_id`) + página en Notion Tasks DB.
2. **2ª pasada — UN hilo con UN mensaje**: crea un solo hilo (naming `Iniciativa - {owner} - {DD/MM/YYYY} - {exp_id}`) y postea un solo mensaje (`buildIniciativaBody`) con:
   - tag `<@owner_discord_id>`;
   - `🧪 **Iniciativa — {nombre}** · experiments/{exp_id}`;
   - la **apuesta** del experiment escrita en el hilo (se trunca al presupuesto de 1990 chars; la lista de CRs nunca se trunca);
   - `📄 PRD:` link al **espejo Notion** de la DB "📄 Docs de Proyecto (Git)" (`a45556da-0f43-4939-961c-ef2db22349ac`, query por prop `exp_id`) — fallback: texto `doc_repo/doc_path`, o `sin puntero (correr /crear-prd)` si el experiment no tiene punteros;
   - `📎 Notion iniciativa:` (el Issue del experiment, `experiments.notion_id`);
   - `🎯 KPI:` **verbatim** `#id nombre` del catálogo `dris_definitions` · `📅 Launch` y `Evaluación`;
   - lista `**CRs:**` con nombre + link Notion de cada uno de los 2 CRs.

Después, PATCH de permalinks + `sync_status` en ambas filas de `crs` (ambas apuntan al MISMO hilo) y cross-link del permalink a las 2 páginas Notion.

- **`experiments.link_cr` = permalink del HILO** (cambio de semántica intencional: el hilo ES la conversación de la iniciativa — `/sync` y `/informe-resultados` postean ahí). Solo se escribe si `link_cr` estaba vacío.
- **Routing sin cambios:** la iniciativa se enruta con el `routeChannel()` v1.8.0 normal (tech → `#iniciativas-tech`, no-tech → líderes/general, etc.).

**Respuesta** — 201 (todos los destinos ok) / 207 (parcial):

```jsonc
{
  "ok": true,
  "mode": "iniciativa",
  "exp_id": "exp-2026-014",
  "canal": "#issues-líderes",
  "thread_name": "[cr-2026-033/034] Iniciativa - Julio Mori - 15/08/2026 - exp-2026-014",
  "thread_permalink": "https://discord.com/channels/619991595613290496/…",
  "discord": { "thread_ok": true, "message_ok": true },
  "created": [ /* 2 items: {cr_id, titulo, datalake, notion_url, notion_page_id, notion_ok} */ ],
  "link_cr": "https://discord.com/channels/…",       // = thread_permalink
  "next_steps": ["…colapso de acciones si aplicó…", "El detalle del plan vive en el PRD; editarlo ahí, no en los CRs."]
}
```

`dry_run:true` soportado → 200 con `crs_preview` (título/deadline/DoD de los 2 CRs), `discord_body_preview` (preview completo del mensaje del hilo), `collapsed_actions` y `thread_name`, sin escrituras.

**Reglas de validación server-side:**
- Falta `owner_dri` → 400.
- Falta `acciones_array` (o vacío) → 400 con recordatorio "1 tarea = 1 CR = 1 Notion = 1 hilo" — **salvo `tipo='iniciativa'`**, que NO lo exige (lo ignora/colapsa).
- `tipo='iniciativa'` sin `exp_id` → 400 · `exp_id` inexistente → 404.
- `tipo='cross-equipos'` sin `cr_pair` → 400.
- `thread_id` sin `mensaje` → 400 · `thread_id` no-snowflake → 400.
- `tipo` default si se omite: `'weekly-cr'` si `es_weekly=true`, sino `'issue'`. **El skill debe pasar `tipo` explícito** (p.ej. `'iniciativa'` cuando hay `exp_id`) para obtener el naming correcto.

### Respuesta

```jsonc
// 201 (escritura) · 200 (dry_run)
{
  "ok": true,                    // true solo si TODOS los destinos ok en TODOS los CRs
  "dry_run": false,
  "canal": "#weekly-exec-okrs",
  "canal_id": "1407016069503258674",
  "consolidated": false,         // true si #iniciativas-tech con >1 acción (1 hilo por owner)
  "count": 3,
  "created": [
    {
      "cr_id": "cr-2026-042",
      "titulo": "…",
      "canal": "#weekly-exec-okrs",
      "thread_name": "[cr-2026-042] CR - Julio Mori - 15/08/2026 - Tarea 1 …",
      "datalake": { "ok": true },
      "notion":   { "ok": true, "url": "https://notion.so/…", "responsable_ok": true, "detail": null },
      "discord":  { "ok": true, "permalink": "https://discord.com/channels/619991595613290496/…", "detail": null },
      "tagged": "<@1348675309024837714>",
      "warning": null             // p.ej. "X no tiene discord id — se publicó sin ping."
    }
  ],
  "next_steps": ["…"]            // en dry_run: revisar y re-invocar con dry_run:false
}
```

En `dry_run:true` cada item trae además `thread_name`, `discord_body_preview`, `kpi_numbers`, `deadline` — úsalo para validar con el usuario antes de publicar.

### ⚠️ Contrato viejo vs endpoint real — campos que cambiaron

| Antes (skill ≤v1.8.2, escritura directa) | Ahora (endpoint) |
|---|---|
| `acciones` string legacy parseado en cualquier punto | El server **solo** acepta `acciones_array`. El split del string numerado lo hace el skill (Paso 2.5) ANTES de llamar |
| `issue_id` | `issue_page_id` |
| `kpi_numbers: ['27','64']` (strings) | `kpi_numbers: [27, 64]` (números; el server descarta no-numéricos) |
| `fecha_evaluacion` como deadline | `deadline` (por acción o top-level) |
| `texto_libre`, `decision_type`, `legacy_issue`, `publish_now`, `nombre_corto` top-level, `kpi_nombre`, `target_mde`, `notion_id`, `es_blocker_de` | **No existen** server-side. `nombre_corto`/`descripcion` van dentro de cada item de `acciones_array` |
| Default `tipo='iniciativa'` si `exp_id` presente | Default server = `'issue'` (o `'weekly-cr'` si `es_weekly`) — pasar `tipo` explícito |
| Routing v1.3.0: `exp_id`/`issue_id` forzaban `#weekly-exec-okrs` | Routing v1.8.0 server-side: `exp_id` NO altera el routing |
| KPI nombres armados por el cliente | El server resuelve nombres verbatim de `dris_definitions` para la línea 🎯 KPI |

## Routing v1.8.0 — flujo de decisión (ajuste Julio 2026-07-21)

El server ejecuta este routing (es la autoridad). El skill lo replica **solo para predecir el canal** y confirmarlo con el usuario (o vía `dry_run`).

**Prioridad — primer match gana:**

```
1. Tarea de REUNIÓN SEMANAL  (es_weekly=true / tipo='weekly-cr')
       ──► #weekly-exec-okrs

2. Issue/iniciativa TECH  (area ∈ {Producto, Tech, Growth - Producto, Growth - Tech})
       ──► #iniciativas-tech

3. CR interno cross-equipos con acuerdo previo  (cr_pair válido)
       ──► #crs-<par> correspondiente

4. Issue NO-tech (default):
       owner ∈ líderes  o  estrategico=true  ──► #issues-líderes
       resto (equipo)                        ──► #issues-general
```

**Resumen narrativo:**
- **Tareas que salen de una reunión semanal** (Weekly Exec) → `#weekly-exec-okrs`. Se crean con `crear-cr` directo cuando hay contexto de la reunión (`es_weekly=true`).
- **Issue/iniciativa que va por tech** (software) → `#iniciativas-tech`.
- **Issue no-tech** → `#issues-líderes` (owner es líder o estratégico) o `#issues-general` (equipo).
- **CR interno cross-equipos** con acuerdo previo → `#crs-*` correspondiente.

> ⚠️ Weekly YA NO es el default de toda iniciativa/issue. `#weekly-exec-okrs` es **solo** para tareas que salen de una reunión semanal. Las iniciativas/issues se enrutan por su naturaleza: **tech → iniciativas-tech**, **no-tech → issues-líderes/general**.

Réplica exacta de la lógica server-side (referencia de decisión, NO se ejecuta para publicar):

```javascript
function routeChannel({ tipo, area, owner_dri, owner_notion_id, cr_pair, es_weekly, estrategico }) {
  if (es_weekly || tipo === 'weekly-cr') return CHANNELS.weekly_exec;
  if (SOFTWARE_AREAS.has(area)) return CHANNELS.iniciativas_tech;
  if (cr_pair && CRS_PAIR_MAP[cr_pair]) return CRS_PAIR_MAP[cr_pair];

  const isLeader = Boolean(estrategico)
    || Boolean(owner_notion_id && Object.values(LEADERS).some((l) => l.notion === owner_notion_id))
    || Object.prototype.hasOwnProperty.call(LEADERS, owner_dri);
  return isLeader ? CHANNELS.issues_lideres : CHANNELS.issues_general;
}
```

## Mapping canales — REAL

### Canal de reunión semanal

| Canal | ID | Cuándo |
|-------|----|--------|
| **`#weekly-exec-okrs`** | `1407016069503258674` | **Solo** tareas que salen de una reunión semanal (Weekly Exec), `es_weekly=true` |

### Canal tech (issue/iniciativa software)

| Canal | ID | Categoría |
|-------|----|-----------|
| **`#iniciativas-tech`** | `959484680137211964` | 🛠️ Tech y Producto — issue/iniciativa que va por tech (software · area Producto/Tech/Growth-Tech) |

### Issues NO-tech (default para issues que no van por tech)

| Canal | ID | Cuándo |
|-------|----|--------|
| `#issues-líderes` | `1504224713038368788` | Issue no-tech · owner ∈ líderes o `estrategico=true` |
| `#issues-general` | `1506685505872461856` | Issue no-tech · equipo general |

### CRs cross-equipos internos (uso interno entre personas — override `cr_pair`)

| `cr_pair` | Canal | ID | Uso |
|-----------|-------|----|----|
| `atc-ops-daily` | `#crs-atc-ops-daily` | `1504608667063029820` | Coordinación ATC↔Ops Daily |
| `atc-ops-foodcourt` | `#crs-atc-ops-food-court` | `1504608691427479773` | Coordinación ATC↔Ops Food Court |
| `finanzas-ops-daily` | `#crs-finanzas-ops-daily` | `1504608708087517266` | Coordinación Finanzas↔Ops Daily |
| `finanzas-ops-foodcourt` | `#crs-finanzas-ops-food-court` | `1504608716186583050` | Coordinación Finanzas↔Ops FC |
| `finanzas-ventas-atc-mkt` | `#crs-finanzas-ventas-atc-marketing` | `1504608724386447480` | Coordinación cross-funcional |
| `ops-interno` | `#crs-operaciones-interno` | `1506689003267690526` | Ops interno |

> **Solo usar `#crs-*` cuando el CR es coordinación específica entre equipos con acuerdo previo.** Una tarea de reunión semanal va a `#weekly-exec-okrs`; un issue tech a `#iniciativas-tech`; un issue no-tech a `#issues-líderes`/`#issues-general`.

## Líderes — UUID Notion + Discord ID

El server tiene este mismo mapping y resuelve IDs cuando el payload no los trae. El skill lo usa para validar/predecir el tag.

```javascript
const LEADERS = {
  'Carlos Andrade':   { notion: '1c70a5ae-72d3-4dbb-8961-5268c150d0fe', discord: '689153159356350533' },
  'Julio Mori':       { notion: '1b2d872b-594c-8122-8cc3-0002af438bb0', discord: '1348675309024837714' },
  'Larissa Arias':    { notion: '2797b08b-7dbf-4730-a264-dfd9202a683d', discord: '752683102836490322' },
  'Adin Garcia':      { notion: '9d5550fb-0233-4143-a394-889fb45ffd0b', discord: '393973271529259008' },
  'Humberto Gomez':   { notion: '8d66ae05-ac2b-490a-a678-1bcca76f8b87', discord: '717914309081956353' },
  'Carolina Andrade': { notion: '58e1729b-ef4c-4e5c-8057-3766d184b499', discord: '973237730219794502' },
  'Cristhian Mayo':   { notion: '14bd872b-594c-8114-9fca-0002c9281d03', discord: '1337531659431710750' },
  'Alejandra Rincones': { notion: 'cd83bab4-e8f9-40c0-93f3-22132f7db5f4', discord: '735662405014519839' },
};
```

## Notion DBs destino (las escribe el SERVER)

| DB | **Database ID** | Usado para |
|----|-----------------|-----------|
| **Tasks** | `95684528-9b3a-440e-91c7-f12ca1e15de4` | BETs/Iniciativas + CRs (1 row por task) — destino del endpoint |
| **Issue Inventory** | `202fb2dd-5c7e-407c-8e48-aa1c5b02fb75` | Issue paraguas del experimento (lo crea `exp-iniciativa` server-side) |
| **Feedback archive - MV** | `eca0b04f-d20a-40cc-86b7-56b83c40cd47` | Resumenes de meetings (relation `👥 Feedback archive - MV`) |

> Nota: para lecturas vía Notion MCP, Tasks tiene data_source_id `f63d7df1-435e-43da-9013-456d2083efc8` e Issue Inventory `9b170e57-48a9-4df0-8825-7f4f729ec9d4` (cada DB tiene 2 IDs, no intercambiables). Las **escrituras** de este flujo son 100% server-side — el skill no crea páginas Notion.

**Decisión:** el endpoint escribe a **Tasks DB**. La task de una iniciativa se **adjunta al Issue** vía relation `Issue Inventory (Tasks)` pasando `issue_page_id`. CR libre → task standalone sin issue.

## Schema Tasks DB (lo setea el server por cada CR)

| Property | Tipo | Valor |
|----------|------|-------|
| `Tasks` (title) | text | `nombre_corto` de la acción |
| `Responsable` | person | owner resuelto (PATCH separado — si la integración Notion no tiene la capability "Read user information", la página se crea igual y `responsable_ok=false`) |
| `Status` | status (`To Do`/`Doing`/`Waiting For`/`Done`) | `To Do` inicial |
| `Fecha Deadline` | date | `deadline` de la acción (o global) |
| `KPI number` | multi-select | `kpi_numbers` |
| `Company Brain` | checkbox | **siempre `true`** — marca para las vistas filtradas del sub-mundo Brain en el HUB |
| `Issue Inventory (Tasks)` | relation → Issue Inventory `202fb2dd` | `[issue_page_id]` si viene; CR libre: vacío |

Body de la página (bloques que arma el server): callout `👤 Responsable · Deadline [· Weekly Sem N]` → `🎯 Contexto` (si hay) → `📋 Tarea` → `📍 DoD` (to_do checklist) → `🔗 Refs` (+ `Experimento: experiments/{exp_id}` si hay `exp_id`; + nota ⚡ RAT si `es_rat`).

---

## Cuándo se activa

- **Sub-llamada desde `exp-iniciativa` paso 5** — con `tipo:'iniciativa'` + `exp_id` (sin `acciones_array`). Crea **2 CRs canónicos** + 1 hilo único (ver "Modo INICIATIVA").
- **Sub-llamada desde `mv-instruction-generator` Fase 0.B** — BET dev con PRD generado.
- **Standalone** — Carlos pega transcript de weekly + owner + acciones.
- Trigger phrases: "crear CR para X", "/crear-cr", "crear iniciativa discord".

## ⚠️ Granularidad por canal (REGLA CRÍTICA descubierta E2E)

**Validación real (2026-06-30):** inspeccionando threads existentes en `#weekly-exec-okrs` se observó el patrón canónico:
- `CR - Julio - 26/06/2026 - Tarea 1 - Weekly Sem 26`
- `CR - Julio - 26/06/2026 - Tarea 2 - Weekly Sem 26`
- `CR - Julio - 26/06/2026 - Tarea 3 - Weekly Sem 26`
- `CR - Julio - 26/06/2026 - Tarea 4 - Weekly Sem 26`

**4 acciones de Julio = 4 threads separados.** No 1 thread con todas dentro.

> Nota: ejemplos históricos de la validación E2E — desde 2026-08-12 cada nombre lleva además el prefijo `[cr-YYYY-NNN]` (ver "Naming de threads" arriba).

| Canal | Granularidad | Razón |
|-------|--------------|-------|
| `#weekly-exec-okrs` | **1 thread por TAREA** | Cada CR es ejecutable atómico: 1 responsable + 1 deadline + 1 DoD. Permite seguimiento independiente. |
| `#iniciativas-tech` | **1 thread por OWNER** (consolida proyectos) | Planning Producto: el owner define alcance/métrica de sus N proyectos en un solo lugar. **El server lo aplica automáticamente** (`consolidated:true` cuando el canal es iniciativas-tech y hay >1 acción). |
| `#issues-líderes` / `#issues-general` | **1 thread por ISSUE** | El n8n cron lo crea automáticamente desde Notion DB Issues. |
| `#crs-*` cross-equipos | **1 thread por CR** | Cada CR es coordinación entre 2 áreas específicas. |

> ⚠️ Esta tabla de granularidad aplica a weekly/issues/cross-equipos. **`tipo='iniciativa'` tiene su propia regla** (2 CRs canónicos + 1 hilo + 1 mensaje, sin split de acciones) — ver "Modo INICIATIVA".

**Implicación para el flujo `exp-iniciativa → crear-cr` (flujo legacy con split — hoy `exp-iniciativa` llama con `tipo='iniciativa'` y SIN acciones):**

```
exp-iniciativa recibe acciones: "1. X\n2. Y\n3. Z\n4. W\n5. V"
                ↓
crear-cr SPLIT por línea → 5 items en acciones_array
                ↓
UNA llamada POST /api/crear-cr — el server, por cada item:
  1. INSERT cr-YYYY-NNN en public.crs
  2. Crea Notion page en Tasks DB
  3. Crea Discord thread (o reusa el consolidado en iniciativas-tech) + postea mensaje con tag + Notion URL
  4. Cross-linkea y guarda permalinks + sync_status
                ↓
Si el payload trae exp_id → el server AUTO-VINCULA experiments.link_cr con el
permalink del thread/Notion (solo si link_cr estaba vacío — Fase 4.2).
El caller ya no necesita PATCHear link_cr; solo verificar que quedó seteado.
```

## Flujo (6 pasos)

### Paso 1 — Contexto y armado del payload

Recolectar del caller/usuario: `owner_dri` (obligatorio), acciones (array o string numerado), `tipo`, `area`, `cr_pair`, `es_weekly`, `estrategico`, `weekly_sem`, `deadline`/deadlines por tarea, `exp_id`, `issue_page_id`, `kpi_numbers` (números), DoD/contexto/refs por tarea.

**Decisiones que toma el skill (no el server):**
- `tipo` explícito: `'iniciativa'` si hay `exp_id`; `'weekly-cr'` si la tarea sale de una weekly; `'cross-equipos'` + `cr_pair` si es coordinación interna; `'issue'` resto.
- Si el CR nace de un experimento: resolver `issue_page_id` (page del Issue paraguas, desde `experiments.notion_id`) y heredar `kpi_numbers = [kpi_definition_id]`.
- Deadlines por tarea cuando difieren; si no, `deadline` global.

### Paso 2 — Routing canal (predicción, regla v1.8.0)

Aplicar `routeChannel()` (réplica arriba) para anticipar el canal y confirmarlo con el usuario. La autoridad final es el server — `dry_run:true` devuelve `canal`/`canal_id` resueltos.

### Paso 2.5 — Parse acciones a array

El server NO parsea strings — este paso es responsabilidad del skill:

```javascript
function parseAccionesToArray(input) {
  // Si ya es array → return
  if (Array.isArray(input.acciones_array)) return input.acciones_array;

  // Si es string → split por líneas numeradas "1. X\n2. Y\n..."
  if (typeof input.acciones === 'string') {
    const lines = input.acciones.split('\n')
      .map((l) => l.trim())
      .filter((l) => /^\d+\.\s+/.test(l));  // solo líneas que empiezan con "N. "

    return lines.map((line, i) => {
      const text = line.replace(/^\d+\.\s+/, '');
      const titulo = text.split('—')[0].split(':')[0].slice(0, 80);
      return {
        nombre_corto: titulo.trim(),
        descripcion: text,
        deadline: input.deadline || null,  // default = deadline iniciativa
        es_rat: /^(rat|piloto|prueba barata)/i.test(text),
      };
    });
  }

  return [];
}
```

**Si no se pueden split (no hay formato numerado claro):**
- ABORT con warning: "Acciones no parseable como array. Pasa `acciones_array` explícito o numera con `1. X\\n2. Y\\n...`"
- NO crear 1 thread con todo dentro (anti-pattern v1.4.0).

### Paso 3 — Tag responsable (CRÍTICO)

> **Memoria:** "El mensaje del hilo SIEMPRE debe incluir `<@discord_id>` del responsable. Sin el tag, la persona no se entera de la tarea."

El server resuelve el tag: `sub_owner_discord_id` → `owner_discord_id` → lookup en LEADERS. Si el owner no está en LEADERS y no viene `owner_discord_id`, el server publica **sin ping** y devuelve `warning` por CR. El skill debe:
1. Verificar antes de llamar: ¿el owner está en LEADERS o tenemos su discord id? Si no → pedirlo al usuario o avisar que no habrá notificación.
2. Después de llamar: propagar cualquier `warning` de la respuesta al usuario.

### Paso 4 — Dry-run y confirmación

Llamar al endpoint con `dry_run: true`. Revisar con el usuario: `canal`, `thread_name` por tarea, `discord_body_preview`, `tagged`, deadlines. Ajustar payload si algo no cierra.

```bash
curl -sS -X POST "https://data-lake-mv.manzanaverde.la/api/crear-cr" \
  -H "x-api-key: $MV_BRAIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d @payload.json          # con "dry_run": true
```

### Paso 5 — Publicar (UNA llamada, dry_run: false)

Mismo payload con `dry_run: false`. El server ejecuta el fanout completo (datalake → Notion → Discord → cross-links). No hay pasos de publicación client-side.

#### Naming de threads (canónico — lo aplica el server)

> 🆕 **2026-08-12: el nombre lleva el código del CR como prefijo** `[cr-YYYY-NNN]` — para citar/ubicar un hilo sin copiar el link de Discord (basta buscar el código). En modo iniciativa (2 CRs → 1 hilo) van ambos códigos, el segundo abreviado si comparte prefijo: `[cr-2026-033/034]`.

| Contexto | Formato |
|----------|---------|
| Weekly (`es_weekly` / `tipo='weekly-cr'`) | `[cr-YYYY-NNN] CR - {owner} - {DD/MM/YYYY} - Tarea {N}[ RAT] {tema} - Weekly Sem {weekly_sem}` |
| `tipo='BET'` o `'iniciativa'` | `[cr-YYYY-NNN/NNN] Iniciativa - {owner} - {DD/MM/YYYY}[ - {exp_id}]` |
| `tipo='issue'` / `'issue-legacy'` | `[cr-YYYY-NNN] Issue - {tema} - {DD/MM/YYYY}` |
| Resto (default) | `[cr-YYYY-NNN] CR - {owner} - {DD/MM/YYYY} - {tema}` |

`{tema}` = `nombre_corto` truncado a 40 chars; nombre total (con prefijo) truncado a 100. Fecha = deadline de la acción (o global) en DD/MM/YYYY.

#### Body del mensaje Discord (canónico — lo postea el server, ≤1990 chars)

```
<@discord_id>

📌 **CR — {nombre_corto}**

**Contexto:** {contexto}            ← solo si viene

**Tarea:** {descripcion}

**Evidencia / DoD:**                ← solo si viene dod[]
- {item 1..8}

📅 **Entrega:** {DD/MM/YYYY}  [⚡ BLOCKER de las demás tareas si es_rat]
🎯 **KPI:** #27 {nombre verbatim del catálogo} · …   ← si kpi_numbers
🧪 **Experimento:** experiments/{exp_id}             ← si exp_id
📎 **Notion:** {notion_url}

Por favor, confirma recepción y acuerdo con la fecha límite planteada.
```

En `#iniciativas-tech` con >1 acción el server **reusa el mismo hilo** (1 por owner) y postea un mensaje por acción con este mismo formato.

> **Nota histórica:** los templates "📌 Acuerdos Sesión Iniciativa", el header KPI de issues legacy y los templates v1.2 (🚀 / :red_circle:) que vivían en versiones ≤v1.8.2 quedaron **legacy — ahora el body lo arma el server** con el formato canónico de arriba. Si se requiere cambiar el formato, el cambio va en `api/crear-cr/index.js`, no acá.

### Paso 5.5 — Gate de PRD (Fase 3)

Después de crear el CR, decidir si requiere un **PRD** antes de implementar. **Gate proporcional**: solo bloquea en flujo crítico; el resto es sugerencia. No reemplaza la clasificación — la delega a `test-decision` (fuente única).

```
1. ¿El CR toca repo o app?
   Señales: area ∈ {Producto, Tech, Growth-Producto, Growth-Tech},
   canal destino = #iniciativas-tech, tipo='BET' software,
   o la acción menciona repo/branch/deploy/endpoint/componente.
   → No: fin. CR normal, sin PRD.

2. ¿El CR ya tiene PRD? (vino de mv-instruction-generator Fase 0.B,
   o ya existe docs/prd/CR-<cr_id>.md en el repo destino)
   → Sí: linkear el PRD al CR y salir. NO regenerar (idempotencia).

3. Clasificar vía /mv-dev:test-decision (transcribir, no re-decidir):
   - BUG trivial (copy/color/config/doc) → sin PRD.
   - BUG defecto                         → /mv-dev:crear-prd modo ligero.
   - BET / RESUME                        → /mv-dev:crear-prd modo completo.
```

**Alcance del gate en Fase 3 — bloqueante vs sugerencia:**

- **Bloqueante SOLO** para **BET/RESUME sobre flujo crítico** (pago, pedido, registro, login). Ahí el PRD es requisito antes de implementar.
- Todo lo demás (BET/RESUME no crítico, BUG defecto) → `crear-prd` se **sugiere**, no bloquea. Se extiende con datos de uso en fases posteriores.

**Bypass `--sin-prd`** (mismo patrón que `allow_no_kpi` de `exp-iniciativa`):

- Exige `rationale` explícito. Sin `rationale` → **rechazado**.
- Marcado *discouraged*: solo cuando el PRD genuinamente no aplica.
- Se graba junto al CR (`sin_prd_rationale` en el payload → col en `public.crs`), consultable después.
- Documentado acá y —pendiente— en la página del Company Brain en Notion (junto con `allow_no_kpi` y `force`).

```
if gate_bloqueante && !existe_prd && !sin_prd:
  → PARAR: pedir /mv-dev:crear-prd (o --sin-prd con rationale)
if --sin-prd && !rationale:
  → RECHAZAR: "--sin-prd exige rationale"
if --sin-prd && rationale:
  → grabar sin_prd_rationale junto al CR y continuar
```

### Paso 6 — Reportar

Del response del endpoint, reportar al usuario por cada CR: `cr_id`, canal, `thread_name`, permalink Discord, URL Notion, tag aplicado y warnings. Si `ok:false` global:
- Revisar `created[].datalake/notion/discord.ok` — el CR con `datalake.ok=true` **existe** aunque un destino haya fallado.
- `sync_status` queda en `public.crs` para reintentar solo lo pendiente (server-side).
- Si `notion.responsable_ok=false`: la página existe pero sin Responsable (capability "Read user information" de la integración server-side) — avisar, no re-crear.

---

## Edge cases

| Caso | Comportamiento |
|------|----------------|
| `es_weekly=true` o `tipo='weekly-cr'` | `#weekly-exec-okrs` (gana sobre area y cr_pair) |
| `area` ∈ software (Producto/Tech/Growth-*) | `#iniciativas-tech`, hilo consolidado por owner si >1 acción |
| `cr_pair` válido (sin es_weekly ni area software) | Canal `#crs-*` correspondiente |
| `tipo='cross-equipos'` sin `cr_pair` | 400 del endpoint: "cr_pair requerido" |
| `tipo='iniciativa'` sin `exp_id` | 400 del endpoint: los 2 CRs canónicos se derivan del experiment |
| `tipo='iniciativa'` con `acciones_array` | El server las COLAPSA en 2 CRs canónicos + aviso en `next_steps` (el detalle va al PRD) |
| Issue no-tech, owner ∈ LEADERS o `estrategico=true` | `#issues-líderes` |
| Issue no-tech, owner de equipo | `#issues-general` |
| Owner sin `owner_discord_id` y no en LEADERS | El server publica sin ping + `warning` en el item — propagar al usuario |
| 401 del endpoint | `MV_BRAIN_TOKEN` inválida/ausente — DETENTE y pide al usuario solicitar su token a BizOps (Julio). Sin fallback |
| INSERT datalake falla | El item viene con `datalake.ok=false` y NO se publica nada para esa acción |
| Notion o Discord fallan (best-effort) | CR queda en `public.crs` con `sync_status` — reportar y reintentar server-side, NO duplicar |
| `nombre_corto > 100 chars` | El server trunca (título 500 en datalake, 200 en Notion, 100 en thread name) |
| Multi-task para mismo owner (fuera de iniciativas-tech) | N items → N CRs + N pages + N threads (1 por tarea) |

---

## Inputs requeridos

| Input | Obligatorio | Fuente |
|-------|-------------|--------|
| `owner_dri` | ✅ | Caller |
| `acciones_array` (o string numerado a parsear en Paso 2.5) | ✅ | Caller |
| `tipo` | recomendado (default server: `issue`/`weekly-cr`) | Skill (Paso 1) |
| `area` | requerido para routear a tech | Caller / exp-iniciativa |
| `cr_pair` | requerido si `tipo='cross-equipos'` | Caller |
| `owner_discord_id` | recomendado para ping (o owner ∈ LEADERS) | Caller / lookup LEADERS |
| `owner_notion_id` | recomendado | Caller / lookup |
| `kpi_numbers` (números), `deadline`, `exp_id`, `issue_page_id`, `weekly_sem` | opcional | exp-iniciativa / caller |
| Env `MV_BRAIN_TOKEN` | ✅ | Usuario (la entrega BizOps/Julio) |

## Outputs

| Output | Destino |
|--------|---------|
| Fila(s) `cr-YYYY-NNN` | `public.crs` (datalake — fuente de verdad, lo escribe el server) |
| Page(s) Notion | Tasks DB (server-side) |
| Thread(s) + mensaje(s) Discord | Canal según routing (server-side) |
| Permalinks + `cr_id`s | Devueltos al caller en `created[]` |
| UPDATE `experiments.link_cr` | **Automático server-side** cuando el payload trae `exp_id` (solo si `link_cr` estaba vacío). El caller solo verifica |

---

## Vinculación con otros skills

```
exp-iniciativa (Julio, genérico)
  ├── Paso 0 si area=software → bifurca a mv-instruction-generator
  └── Paso 5 invoca crear-cr ──► POST /api/crear-cr ──► return created[] (Notion+Discord links)

mv-instruction-generator v1.8.0 (Carlos, dev)
  ├── Fase 0.B genera PRD-para-Claude
  └── Después invoca crear-cr con tipo='BET' + area='Producto'/'Tech'
       → routea a #iniciativas-tech (NO a #issues-líderes)

informe-resultados
  └── Veredicto 🟥 Falló → invoca crear-cr con tipo='issue' para acción de reversión
```

---

## Decisión técnica: publicación server-side (Fase 3 seguridad Brain)

**≤v1.8.2:** el skill escribía directo a Notion y a la API de Discord desde el cliente, con tokens de servicio en el entorno local. Problemas: (a) tokens de servicio distribuidos en máquinas cliente; (b) dos escrituras independientes sin fuente de verdad — un fallo parcial dejaba el CR a medias y sin registro; (c) webhooks por canal como fallback (también secretos).

**v1.9.0 (esta):** el CR nace en el datalake (`public.crs`) y el server hace el fanout. El cliente solo necesita `MV_BRAIN_TOKEN` (scope `write:cr`). Pros:
- Cero tokens de servicio ni webhooks en el cliente.
- Fuente de verdad + `sync_status` por destino → reintentos idempotentes.
- `dry_run` para previsualizar routing/naming/body sin efectos.
- Routing/naming/templates canónicos en UN solo lugar (`api/crear-cr/index.js`).

---

## Invocación mínima (referencia)

```bash
# 1. Guardar payload (ver contrato arriba)
cat > payload.json <<'EOF'
{
  "owner_dri": "Julio Mori",
  "es_weekly": true,
  "weekly_sem": 32,
  "kpi_numbers": [27],
  "acciones_array": [
    { "nombre_corto": "Piloto 200 clientes", "descripcion": "Correr piloto antes del rollout",
      "deadline": "2026-08-15", "dod": ["Reporte con CVR piloto"], "es_rat": true }
  ],
  "dry_run": true
}
EOF

# 2. Dry-run → validar canal/naming/body con el usuario
curl -sS -X POST "https://data-lake-mv.manzanaverde.la/api/crear-cr" \
  -H "x-api-key: $MV_BRAIN_TOKEN" -H "Content-Type: application/json" \
  -d @payload.json

# 3. Publicar: mismo payload con "dry_run": false
```

> Si `MV_BRAIN_TOKEN` no está definida, DETENTE y pide al usuario solicitar su token a BizOps (Julio). Sin fallback.

---

## Testing

| # | Escenario | Esperado |
|---|-----------|----------|
| T1 | `tipo='BET'` + area=Producto | `#iniciativas-tech`, tag responsable, Tasks DB, `consolidated` si >1 acción |
| T2 | `es_weekly=true` + 4 acciones | `#weekly-exec-okrs`, 4 CRs + 4 threads `Tarea N - Weekly Sem X` |
| T3 | `tipo='iniciativa'` + exp_id, area no-software, owner líder | `#issues-líderes` (v1.8.0: exp_id NO fuerza weekly) + modo iniciativa: 2 CRs + 1 hilo |
| T4 | `cr_pair=atc-ops-daily`, sin es_weekly ni area software | `#crs-atc-ops-daily` |
| T5 | `es_weekly=true` + `cr_pair` presente | `#weekly-exec-okrs` gana (prioridad 1) |
| T6 | area=Tech + `cr_pair` presente | `#iniciativas-tech` gana (prioridad 2) |
| T7 | Issue no-tech owner=Carlos | `#issues-líderes` |
| T8 | Issue no-tech owner de equipo, sin `estrategico` | `#issues-general` |
| T9 | `tipo='cross-equipos'` sin `cr_pair` | 400 explícito del endpoint |
| T10 | Owner sin discord_id ni en LEADERS | Publica sin ping + `warning` en el item |
| T11 | `MV_BRAIN_TOKEN` ausente/inválida (401) | DETENTE — pedir token a BizOps (Julio), sin fallback |
| T12 | Destino Notion o Discord falla | `datalake.ok=true`, destino `ok=false` con `detail`, `sync_status` en `public.crs` |
| T13 | Multi-task mismo owner en weekly | N CRs + N pages + N threads (1 por tarea) |
| T14 | `dry_run:true` | 200, `created[]` con previews, sin escrituras |
| T15 | `tipo='BET'` desde mv-instruction-generator Fase 0.B | `#iniciativas-tech` + thread `Iniciativa - ...` |

---

## Auth y variables

```bash
# ÚNICA variable client-side:
MV_BRAIN_TOKEN=<token personal Brain — lo entrega BizOps (Julio)>
```

- Header: `x-api-key: $MV_BRAIN_TOKEN`.
- Si `MV_BRAIN_TOKEN` no está definida, DETENTE y pide al usuario solicitar su token a BizOps (Julio). Sin fallback.
- Los tokens de servicio (bot Discord, integración Notion, llave datalake) viven **solo** en Vercel `data-lake-mv` — nunca en el cliente ni en este skill.

---

## Métrica de éxito

- **100%** CRs creados via skill llegan a Discord con tag `<@id>` del responsable.
- **0** CRs huérfanos (sin Responsable o sin Fecha Deadline).
- **100%** BETs con area∈software van a `#iniciativas-tech` (no a issues genérico).
- **100%** CRs sub-llamados desde `exp-iniciativa` resultan en `experiments.link_cr IS NOT NULL`.
- **100%** CRs con fila en `public.crs` (fuente de verdad) aunque un destino best-effort falle.
- **0** tokens de servicio en cliente (Fase 3).

---

## Dependencias

- ✅ Endpoint `POST /api/crear-cr` deployado en `data-lake-mv` (fanout datalake → Notion → Discord, `dry_run`, `sync_status`).
- ✅ Server Discord `manzanaverde` con 10 canales relevantes mapeados; bot CRS#6481 con permisos (server-side).
- ✅ Notion DBs Tasks (`95684528-...`) + Issue Inventory (`202fb2dd-...`) operativas (integración server-side RW verificada 2026-07-18).
- ✅ Tabla `public.crs` + `experiments` (link_cr UPDATE desde `exp-iniciativa`).
- ⬜ `MV_BRAIN_TOKEN` personal del usuario (scope `write:cr`) — lo entrega BizOps (Julio).

---

## Vinculación al Issue de la iniciativa (v1.7 — Carlos 2026-07-17)

- **CR de una iniciativa** (`exp_id` presente): las tasks/CRs se **vinculan al Issue** del experimento (el Issue que creó `exp-iniciativa` en "Issue Inventory"). La task queda colgada del issue paraguas → trazabilidad iniciativa → sus CRs.
  - Resolver el page id del issue desde `experiments.notion_id` por `exp_id`.
  - Pasar `issue_page_id` en el payload — el server setea la relation `Issue Inventory (Tasks)`.
- **CR libre** (standalone, sin `exp_id`): se crea **solo la task libre** en Tasks DB, sin issue paraguas.

```
crear-cr con exp_id + issue_page_id → task(s) con relation Issue Inventory (Tasks) = issue del experimento
crear-cr standalone                 → task libre (relation vacía)
```

> ✅ **Schema confirmado live 2026-07-18:** la relation Task↔Issue es bidireccional — Tasks DB (`95684528`) prop `Issue Inventory (Tasks)` → Issue Inventory (`202fb2dd`); e inversa `Tasks ` en el Issue.

## Changelog

- **v1.12.0 (2026-08-12): el nombre del hilo lleva el código del CR.** Prefijo `[cr-YYYY-NNN]` (o `[cr-YYYY-NNN/NNN]` en modo iniciativa, 2 CRs → 1 hilo) antepuesto al naming de siempre — para citar/ubicar un hilo buscando el código en Discord, sin copiar el link. `nextCrId()` se genera antes del naming en vez de después (server); sin cambios en el contrato del skill, solo en el `thread_name` que devuelve la respuesta.
- **v1.11.0 (2026-08-11): Modo INICIATIVA (DOCS-BRAIN Fase 3).** `tipo='iniciativa'` desvía a `handleIniciativa` server-side: exactamente **2 CRs canónicos** ("Ejecución" deadline=fecha_launch · "Medición y conclusiones" deadline=fecha_evaluacion) derivados del experiment — `acciones_array` ya no se exige (se ignora/colapsa si viene) — y **1 hilo con 1 solo mensaje** (`buildIniciativaBody`: apuesta escrita, links a PRD/Issue/2 CRs, KPI y fechas verbatim) vía flujo two-pass. `experiments.link_cr` pasa a apuntar al **hilo** (antes: al primer CR). Regla 1-tarea-1-CR gana esta segunda excepción (la primera sigue siendo `#iniciativas-tech`). `exp_id` ahora requerido (400 sin él) cuando `tipo='iniciativa'`.
- **v1.9.0 (2026-08-07): publicación migrada a server-side (Fase 3 seguridad Brain) — sin tokens de servicio en cliente.** El skill conserva la lógica de decisión (routing v1.8.0, granularidad 1-tarea-1-CR, naming, gate PRD) y publica con UNA llamada a `POST /api/crear-cr` (`x-api-key: $MV_BRAIN_TOKEN`). Eliminados: escritura directa a Discord/Notion, stub Python de publicación, webhooks fallback y ejemplos de tokens. Documentado el contrato real del endpoint (acciones_array obligatorio, `issue_page_id`, `kpi_numbers` numéricos, `deadline`, `dry_run`, `exp_id` con auto-link de `experiments.link_cr` server-side, respuesta con `sync_status` por destino) y las diferencias vs el contrato viejo. Routing/testing/edge-cases actualizados a la semántica v1.8.0 del server (exp_id ya no fuerza weekly).
- **v1.8.2 (2026-07-22)** — Restaura **Paso 5.5 — Gate de PRD (Fase 3)** que el PR de v1.8.1 había borrado por accidente (mi rama no lo tenía; el gate venía de PR#14 del equipo). Mantiene los fixes de IDs/formatos MCP de v1.8.1. cloud/skills ahora incluye el gate como canónico.
- **v1.8.1 (2026-07-22)** — Fix IDs database vs data_source + formatos MCP. Cada DB tiene 2 ids: `database_id` (raw REST API) y `data_source_id` (Notion MCP). Tasks: db `95684528` / ds `f63d7df1`. Issue Inventory: db `202fb2dd` / ds `9b170e57`. Corregido el bug del Paso 4 (MCP usaba el database_id como data_source_id → 404). Corrige la nota "phantom" errónea de v1.7.1.
- **v1.8.0 (2026-07-21)** — Routing ajustado (Julio). Weekly YA NO es el default de toda iniciativa/issue: (1) tarea de reunión semanal `es_weekly` → #weekly-exec-okrs; (2) issue/iniciativa tech (software) → #iniciativas-tech; (3) CR cross-equipos con `cr_pair` → #crs-*; (4) issue no-tech → #issues-líderes (líder/estratégico) o #issues-general. `route_channel()` reescrito + params `es_weekly`/`estrategico`. Los 6 canales #crs-* siguen mapeados.
- **v1.7.2 (2026-07-18)** — Sub-mundo Brain: task setea `Company Brain=true` (para vistas filtradas del HUB) + param `issue_page_id` para relation a Issue de iniciativa.
- **v1.7.1 (2026-07-18)** — Fix IDs verificados live + relation confirmada. Issue DB = "Issue Inventory" `202fb2dd`. Relation Task→Issue resuelta: `Issue Inventory (Tasks)` = `[{id: issue_page_id}]`.
- **v1.7.0 (2026-07-17)** — Vinculación al Issue de iniciativa (Carlos v2). CR con exp_id → task vinculada al Issue paraguas; CR libre → task suelta.
- **v1.6.0 (2026-07-11)** — KPI/input propagation (regla auto-link): herencia de `kpi_definition_id` desde `experiments_with_kpi`, `KPI number` multi_select auto, línea `🎯 KPI:` en body Discord.
- **v1.5.0 (2026-06-30, post-E2E)** — Granularidad real: 1 tarea = 1 CR = 1 Notion = 1 thread. `acciones_array` param; legacy `acciones` string auto-parseado por líneas numeradas; excepción `#iniciativas-tech` consolidado por owner. Smoke E2E: 5 acciones de exp-2026-008 → 5 threads + 5 tasks.
- **v1.4.0 (2026-06-30)** — Formato real de threads (thread directo type 11, naming por ritual, template Acuerdos, 1 thread por OWNER en planning / por TAREA en weekly).
- **v1.3.0 (2026-06-30)** — Regla weekly de visibilidad ejecutiva (superseded por v1.8.0).
- **v1.2.0 (2026-06-30)** — Routing real descubierto vía bot Discord MCP; canal `#iniciativas-tech`; 6 canales `#crs-*`; tag `<@discord_id>` obligatorio; 8 líderes mapeados.
- **v1.1.0 (2026-06-30)** — Alineado con n8n workflow q9K38OEiEju9eazK (líderes/general).
- **v1.0.0 (2026-06-30)** — Build inicial post-skeleton.

---

**FIN.** Spec base: `producto/estrategia/iniciativa-ai-native-dev/04-skill-crear-cr.md`. Contrato canónico: `api/crear-cr/index.js` (repo `manzana-verde-okr`). Routing real: descubierto vía Discord MCP + memoria proyecto Discord (`~/.claude/projects/c--Proyectos-Discord/memory/`).
