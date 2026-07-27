---
name: crear-cr
description: |
  Crea Change Requests (CRs) e Iniciativas en Discord + Notion. Routing v1.8:
  tarea de reunión semanal → #weekly-exec-okrs; issue/iniciativa tech → #iniciativas-tech;
  issue no-tech → #issues-líderes/#issues-general; CR cross-equipos → canales crs-* específicos.
  Tag obligatorio del responsable con <@id>.
  Notion: Tasks DB para BETs, Issues a Discord DB para issues clásicos.
trigger_phrases:
  - "/crear-cr"
  - "crear CR"
  - "crear iniciativa discord"
  - "nuevo change request"
  - "abrir CR para"
version: 1.8.1
owner: Julio Mori
based_on:
  - producto/estrategia/iniciativa-ai-native-dev/04-skill-crear-cr.md
  - n8n workflow q9K38OEiEju9eazK (MV - Issues a Discord)
  - memoria proyecto Discord: reference_discord_mv, project_mv_cr_workflow, feedback_discord_workflow, feedback_cr_tag_responsable, reference_notion_mv_databases
---

# Skill `crear-cr` v1.5.0

> Sprint Company Brain — cable iniciativa/issue → Discord + Notion.
>
> **Reglas clave v1.8.0 (routing ajustado Julio 2026-07-21):**
> 1. **🔥 REGLA CRÍTICA — 1 tarea = 1 CR = 1 Notion task = 1 Discord thread.** Si la iniciativa tiene N acciones, hay que crear N threads separados (no 1 thread con todas las acciones dentro). Cada CR es atómico: tiene su propia Notion page, su propio responsable, su propio deadline, su propio DoD.
> 2. **Reunión semanal** — tarea que sale de una Weekly Exec (`es_weekly=true`) → `#weekly-exec-okrs`. Se crean con `crear-cr` directo cuando hay contexto de la reunión.
> 3. **Issue/iniciativa tech** (software · Producto/Tech/Growth-Tech) → `#iniciativas-tech`.
> 4. **Issue no-tech** → `#issues-líderes` (owner líder o estratégico) o `#issues-general` (equipo).
> 5. **CR interno cross-equipos** con acuerdo previo → canal `#crs-*` específico (6 canales, ver mapping).
> 6. **Thread directo** (sin parent message) — `POST /channels/{id}/threads` type=`11`. Naming MV exacto.

## Server + bot

- **Guild:** `manzanaverde` — ID `619991595613290496`
- **Bot:** `CRS#6481` — ID `1493662108431417354` — Token en `~/.claude.json` (MCP discord) o env `DISCORD_BOT_TOKEN`
- **Acceso del bot:** Send Messages + Create Threads + Read Message History en todas las categorías relevantes

## Routing v1.8.0 — flujo de decisión (ajuste Julio 2026-07-21)

**Prioridad — primer match gana:**

```
1. Tarea de REUNIÓN SEMANAL  (es_weekly=true / tipo='weekly-cr' / hay contexto de la weekly)
       ──► #weekly-exec-okrs

2. Issue/iniciativa TECH  (software · area ∈ {Producto, Tech, Growth-Tech} · tipo='BET' software)
       ──► #iniciativas-tech

3. CR interno cross-equipos con acuerdo previo  (cr_pair específico)
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

> ⚠️ **Cambio v1.4.0:** weekly YA NO es el default de toda iniciativa/issue. `#weekly-exec-okrs` es **solo** para tareas que salen de una reunión semanal. Las iniciativas/issues se enrutan por su naturaleza: **tech → iniciativas-tech**, **no-tech → issues-líderes/general**.

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

> **Solo usar `#crs-*` cuando el CR es coordinación específica entre equipos con acuerdo previo.** Los 6 canales `#crs-*` siguen vigentes (arriba). Una tarea de reunión semanal va a `#weekly-exec-okrs`; un issue tech a `#iniciativas-tech`; un issue no-tech a `#issues-líderes`/`#issues-general`.

## Mecanismo de publicación

**Default: bot REST API directo** (`POST /channels/{id}/messages`) con `Authorization: Bot <DISCORD_BOT_TOKEN>`. No requiere webhook por canal — el bot CRS tiene Send Messages en todos los canales relevantes.

**Fallback opcional:** webhook URLs para `#issues-líderes` y `#issues-general` (ya configurados en n8n workflow `q9K38OEiEju9eazK`). Solo si `DISCORD_BOT_TOKEN` no está disponible.

## Líderes — UUID Notion + Discord ID

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

## Notion DBs destino

| DB | **Database ID** (raw REST API) | **Data Source ID** (Notion MCP) | Usado para |
|----|--------------------------------|--------------------------------|-----------|
| **Tasks** | `95684528-9b3a-440e-91c7-f12ca1e15de4` | `f63d7df1-435e-43da-9013-456d2083efc8` | BETs/Iniciativas + CRs (1 row por task) |
| **Issue Inventory** | `202fb2dd-5c7e-407c-8e48-aa1c5b02fb75` | `9b170e57-48a9-4df0-8825-7f4f729ec9d4` | Issue paraguas del experimento (crea `exp-iniciativa`, cron n8n a Discord) |
| **Feedback archive - MV** | `eca0b04f-d20a-40cc-86b7-56b83c40cd47` | — | Resumenes de meetings (relation `👥 Feedback archive - MV`) |

> ⚠️ **CADA DB TIENE 2 IDs — NO intercambiables (corrige la nota errónea v1.7.1 "phantom"):**
> - **Raw REST API** (`fetch https://api.notion.com`, Python stub) → usa **`database_id`**: `{"parent":{"database_id":"95684528..."}}`. Nota: `GET /v1/databases/f63d7df1` da 404 en raw API — por eso pareció "phantom", pero NO lo es.
> - **Notion MCP** (`notion-create-pages` / `notion-update-page`) → usa **`data_source_id`** (collection): `parent:{type:"data_source_id","data_source_id":"f63d7df1..."}`.
> - `f63d7df1` = data_source_id de Tasks · `9b170e57` = data_source_id de Issue Inventory (verificado live con `notion-create-view` + fetch data sources).

**Decisión:** `crear-cr` por defecto escribe a **Tasks DB**. La task de una iniciativa se **adjunta al Issue** vía relation `Issue Inventory (Tasks)` (ver abajo). CR libre → task standalone sin issue.

## Schema Tasks DB

| Property | Tipo | Set por skill |
|----------|------|---------------|
| `Tasks` (title) | text | Nombre corto |
| `Responsable` | person | owner_notion_id |
| `Status` | status (`To Do`/`Doing`/`Waiting For`/`Done`) | `To Do` inicial |
| `Fecha Deadline` | date | fecha_evaluacion |
| `KPI number` | multi-select | `["27","64",...]` (strings) |
| `Company Brain` | checkbox | **siempre `true`** — marca para las vistas filtradas del sub-mundo Brain en el HUB |
| `Issue Inventory (Tasks)` | relation → Issue Inventory `202fb2dd` | **task de iniciativa: setear = `[issue_page_id]` del experimento.** CR libre: vacío |
| `👥 Feedback archive - MV` | relation → `eca0b04f` | opcional, link al resumen padre |

---

## Cuándo se activa

- **Sub-llamada desde `exp-iniciativa` paso 5** — con `acciones[]` array. Crea **N CRs** (1 por acción).
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

| Canal | Granularidad | Razón |
|-------|--------------|-------|
| `#weekly-exec-okrs` | **1 thread por TAREA** | Cada CR es ejecutable atómico: 1 responsable + 1 deadline + 1 DoD. Permite seguimiento independiente. |
| `#iniciativas-tech` | **1 thread por OWNER** (consolida proyectos) | Planning Producto: el owner define alcance/métrica de sus N proyectos en un solo lugar. |
| `#issues-líderes` / `#issues-general` | **1 thread por ISSUE** | El n8n cron lo crea automáticamente desde Notion DB Issues. |
| `#crs-*` cross-equipos | **1 thread por CR** | Cada CR es coordinación entre 2 áreas específicas. |

**Implicación para el flujo `exp-iniciativa → crear-cr`:**

```
exp-iniciativa recibe acciones: "1. X\n2. Y\n3. Z\n4. W\n5. V"
                ↓
crear-cr SPLIT por línea → 5 items
                ↓
Por cada item:
  1. Crear Notion page en Tasks DB
  2. Crear Discord thread en canal correspondiente
  3. Postear mensaje en thread con tag + Notion URL
  4. Devolver array de N permalinks
                ↓
exp-iniciativa actualiza experiments.link_cr con thread DEL CR principal
                (el RAT o el primero ejecutable)
```

## Flujo (6 pasos)

### Paso 1 — Contexto

```typescript
type CRInput = {
  // Modo 1: desde exp-iniciativa o mv-instruction-generator
  exp_id?: string;
  issue_id?: string;        // Notion page ID si el CR nace de un issue ya registrado

  // 🔥 ACCIONES — array de items (v1.5.0)
  // Cada item se convierte en 1 CR separado (1 Notion + 1 Discord thread)
  acciones_array?: Array<{
    nombre_corto: string;
    descripcion: string;
    deadline: string;       // ISO date — puede diferir por tarea
    sub_owner?: string;     // si difiere del owner_dri principal
    sub_owner_discord_id?: string;
    es_blocker_de?: number[]; // índices de otras tareas que bloquea
    es_rat?: boolean;       // marca esta tarea como Riskiest Assumption Test
  }>;
  // Legacy: si pasa `acciones` string, se split por línea numerada
  acciones?: string;

  kpi_nombre?: string;
  kpi_numbers?: string[];   // ['27','64']
  target_mde?: string;
  fecha_evaluacion?: string;

  // Modo 2: standalone
  texto_libre?: string;
  decision_type?: string;

  // Routing
  tipo?: 'BET' | 'iniciativa' | 'issue' | 'issue-legacy' | 'weekly-cr' | 'cross-equipos';  // default → si exp_id/issue_id presente: 'iniciativa'; sino: 'issue'
  area?: 'Producto' | 'Tech' | 'Growth - Producto' | 'Growth - Tech'
       | 'Growth' | 'Operaciones' | 'MKT' | 'Reconsumos' | 'Finanzas' | 'DK' | 'CX';
  cr_pair?: 'atc-ops-daily' | 'atc-ops-foodcourt' | 'finanzas-ops-daily'
          | 'finanzas-ops-foodcourt' | 'finanzas-ventas-atc-mkt' | 'ops-interno';

  // Comunes
  nombre_corto?: string;
  owner_dri: string;          // 'Carlos Andrade', 'Daniela Pérez', etc.
  owner_notion_id?: string;
  owner_discord_id?: string;  // <@id> para tag — REQUERIDO para notificar
  notion_id?: string;         // borrador padre opcional

  // Opciones
  legacy_issue?: boolean;     // si true → escribe a Issues a Discord DB (no Tasks)
  publish_now?: boolean;      // si false (default) → solo Notion + cron n8n procesa (legacy issues)
};
```

### Paso 2 — Routing canal (regla v1.3.0)

```javascript
const CHAN = {
  iniciativas_tech: { id: '959484680137211964',  name: '#iniciativas-tech' },
  weekly_exec:      { id: '1407016069503258674', name: '#weekly-exec-okrs' },
  issues_lideres:   { id: '1504224713038368788', name: '#issues-líderes'   },
  issues_general:   { id: '1506685505872461856', name: '#issues-general'   },
};

const CRS_PAIR_MAP = {
  'atc-ops-daily':           { id: '1504608667063029820', name: '#crs-atc-ops-daily' },
  'atc-ops-foodcourt':       { id: '1504608691427479773', name: '#crs-atc-ops-food-court' },
  'finanzas-ops-daily':      { id: '1504608708087517266', name: '#crs-finanzas-ops-daily' },
  'finanzas-ops-foodcourt':  { id: '1504608716186583050', name: '#crs-finanzas-ops-food-court' },
  'finanzas-ventas-atc-mkt': { id: '1504608724386447480', name: '#crs-finanzas-ventas-atc-marketing' },
  'ops-interno':             { id: '1506689003267690526', name: '#crs-operaciones-interno' },
};

const SOFTWARE_AREAS = new Set(['Producto', 'Tech', 'Growth - Producto', 'Growth - Tech']);

function routeChannel(input) {
  // 1. BET software → canal especializado dev
  if (input.tipo === 'BET' && SOFTWARE_AREAS.has(input.area)) {
    return CHAN.iniciativas_tech;
  }

  // 2. tipo='weekly-cr' explícito → weekly
  if (input.tipo === 'weekly-cr') return CHAN.weekly_exec;

  // 3. Vinculado a iniciativa o issue registrado → visibilidad ejecutiva en weekly
  const isLinked = Boolean(input.exp_id || input.issue_id);
  const isInitiativeOrIssue = ['BET', 'issue', 'iniciativa'].includes(input.tipo);
  if (isLinked || isInitiativeOrIssue) return CHAN.weekly_exec;

  // 4. CR específico interno entre equipos (sin iniciativa de fondo) → canal cross-equipos
  if (input.tipo === 'cross-equipos' && input.cr_pair && CRS_PAIR_MAP[input.cr_pair]) {
    return CRS_PAIR_MAP[input.cr_pair];
  }

  // 5. Issue standalone legacy (n8n flow) — solo cuando es claramente issue puro
  if (input.tipo === 'issue-legacy') {
    const leader = isLeader(input.owner_dri, input.owner_notion_id);
    return leader ? CHAN.issues_lideres : CHAN.issues_general;
  }

  // 6. Default fallback — visibilidad ejecutiva
  return CHAN.weekly_exec;
}
```

### Paso 2.5 — Parse acciones a array (v1.5.0)

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
        deadline: input.fecha_evaluacion || null,  // default = deadline iniciativa
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

```javascript
function resolveResponsableTag(input) {
  if (input.owner_discord_id) return `<@${input.owner_discord_id}>`;
  // Lookup en LEADERS por nombre
  const found = LEADERS[input.owner_dri];
  if (found) return `<@${found.discord}>`;
  // Sin Discord ID → texto plano + warning
  return input.owner_dri;
}
```

### Paso 4 — Crear N Notion tasks (loop por acción)

```javascript
// Tasks — DOS ids (ver tabla arriba). Elige según el camino de ejecución:
const NOTION_TASKS_DB = '95684528-9b3a-440e-91c7-f12ca1e15de4';   // database_id  → RAW REST API
const NOTION_TASKS_DS = 'f63d7df1-435e-43da-9013-456d2083efc8';   // data_source_id → NOTION MCP
const NOTION_ISSUES_DB = '202fb2dd-5c7e-407c-8e48-aa1c5b02fb75';  // database_id (Issue Inventory)
const NOTION_ISSUES_DS = '9b170e57-48a9-4df0-8825-7f4f729ec9d4';  // data_source_id (Issue Inventory)

// Task de iniciativa → adjuntar al issue vía relation `Issue Inventory (Tasks)`. CR libre → omitir.
// Schema editable de Tasks: Tasks(title) · Status(status) · Responsable/Asignee(people) ·
//   Fecha Deadline(date) · KPI number(multi_select) · Highest Priority(checkbox) ·
//   Project/Areas/Issue Inventory (Tasks)/Key Result/Context Area/etc. (relation/multi_select).

// ⚠️ FORMATOS DE PROPIEDADES — difieren según el camino:
//
//                    RAW REST API (api.notion.com)          NOTION MCP (notion-create-pages)
//   Title      →     { title:[{text:{content}}] }           "Tasks": "string"
//   Status     →     { status:{ name:"To Do" } }            "Status": "To Do"
//   Person     →     { people:[{ id:"uuid" }] }             "Responsable": ["uuid"]        (array de uuids)
//   Checkbox   →     { checkbox: true }                     "Highest Priority": "__YES__"  (o "__NO__")
//   Multi-sel  →     { multi_select:[{name:"27"}] }         "KPI number": ["27","64"]      (array de strings)
//   Date       →     { date:{ start:"YYYY-MM-DD" } }        "date:Fecha Deadline:start": "YYYY-MM-DD"
//   Relation   →     { relation:[{ id:"pageid" }] }         "Issue Inventory (Tasks)": ["pageid o url"]
//   Number     →     { number: 5 }                          "prop": 5 (número JS)
//   id/url     →     (nombre tal cual)                      prefijo "userDefined:" (ej. "userDefined:URL")

// --- Camino B: Notion MCP (notion-create-pages) — usa data_source_id + formatos MCP ---
const mcpPages = accionesArray.map((accion) => ({
  properties: {
    'Tasks': `CR: ${accion.nombre_corto} — ${experiment.nombre.slice(0, 40)}`,
    'Status': 'To Do',
    'Company Brain': '__YES__',
    'Responsable': [accion.sub_owner_notion_id || input.owner_notion_id],   // array
    'KPI number': (input.kpi_numbers || []).map(String),                    // array de strings
    'date:Fecha Deadline:start': accion.deadline || input.fecha_evaluacion,
    ...(input.issue_page_id ? { 'Issue Inventory (Tasks)': [input.issue_page_id] } : {}),
  },
  content: buildNotionTaskBody(accion, experiment),
}));
// notion-create-pages({ parent: { type:'data_source_id', data_source_id: NOTION_TASKS_DS }, pages: mcpPages })
```

Notion page body template:

```markdown
## 🎯 Iniciativa madre

**Experimento:** {experiment.id} — {experiment.nombre}
**Owner DRI:** {experiment.owner_dri}
**Baseline:** {experiment.baseline_valor} → Target {experiment.target_mde}
**Fecha evaluación iniciativa:** {experiment.fecha_evaluacion}

---

## 📋 Tarea específica

{accion.descripcion}

### Pasos
{accion.pasos_detallados}

### 📍 DoD (Definition of Done)
- {dod_item_1}
- {dod_item_2}

### 🔗 Refs
- experiments/{experiment.id}
- KPI: {experiment.kpi_nombre} ({experiment.baseline} → {experiment.target})
- Tareas hermanas: ver threads "Tarea N"
{accion.es_rat ? '- **Esta tarea es BLOCKER** de otras' : ''}
```

**Schema legacy (Issues a Discord DB):** mantenido solo si `legacy_issue=true`. Default v1.5.0 = Tasks DB.

### Paso 4.5 — Naming threads (v1.5.0 con Tarea N)

```javascript
function buildThreadNameMultiTask(experiment, accion, index, totalAcciones, sem) {
  const fecha = formatDDMMYYYY(accion.deadline || experiment.fecha_evaluacion);
  const persona = experiment.owner_dri;
  const tipoLabel = accion.es_rat ? `Tarea ${index+1} RAT` : `Tarea ${index+1}`;
  const tema = accion.nombre_corto.slice(0, 30);

  // Format real Weekly: "CR - {Persona} - DD/MM/YYYY - Tarea N - <descriptor>"
  return `CR - ${persona} - ${fecha} - ${tipoLabel} ${tema} - ${experiment.id}`.slice(0, 100);
}

// Para BET dev (iniciativas-tech) — 1 thread por OWNER (no por tarea):
function buildThreadNameInitiative(experiment) {
  const fecha = formatDDMMYYYY(experiment.fecha_evaluacion);
  return `Iniciativa - ${experiment.owner_dri} - ${fecha} - ${experiment.nombre.slice(0, 50)}`;
}
```

### Paso 5 — Publicar Discord (thread directo, sin parent message)

> **Cambio v1.4.0:** descubrimos vía inspección de threads reales en `#iniciativas-tech` que las iniciativas NO nacen de un mensaje en el canal padre + thread on message. Se crean como **thread directo** (`type: 11` PUBLIC_THREAD), y el primer mensaje va DENTRO del thread con formato `📌 Acuerdos Sesión`.

#### Paso 5a — Loop creación threads (1 por tarea cuando aplica)

```javascript
const channel = routeChannel(input);
const isInitiativeTechCanal = channel.id === '959484680137211964';

// REGLA: iniciativas-tech → 1 thread consolidado por OWNER
//        weekly-exec-okrs / crs-* / issues → 1 thread por tarea
const threadsToCreate = isInitiativeTechCanal
  ? [{ name: buildThreadNameInitiative(experiment), acciones: accionesArray, mode: 'consolidated' }]
  : accionesArray.map((accion, i) => ({
      name: buildThreadNameMultiTask(experiment, accion, i, accionesArray.length, weekSem),
      accion,
      notion_page: notionPages[i].page,
      mode: 'per-task',
    }));

const results = [];
for (const t of threadsToCreate) {
  // Crear thread
  const tResp = await fetch(`https://discord.com/api/v10/channels/${channel.id}/threads`, {
    method: 'POST',
    headers: { Authorization: `Bot ${process.env.DISCORD_BOT_TOKEN}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: t.name.slice(0, 100), type: 11, auto_archive_duration: 10080 }),
  });
  const thread = await tResp.json();

  // Postear mensaje según mode
  const body = t.mode === 'per-task'
    ? buildCRThreadBody(t.accion, t.notion_page, experiment, responsableTag)
    : buildInitiativeThreadBody(experiment, t.acciones, notionPages, responsableTag);

  await fetch(`https://discord.com/api/v10/channels/${thread.id}/messages`, {
    method: 'POST',
    headers: { Authorization: `Bot ${process.env.DISCORD_BOT_TOKEN}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ content: body.slice(0, 1900), allowed_mentions: { parse: ['users'] } }),
  });

  results.push({
    thread_id: thread.id,
    thread_permalink: `https://discord.com/channels/619991595613290496/${thread.id}`,
    notion_page_url: t.notion_page?.url || null,
    accion: t.accion?.nombre_corto || null,
  });
}
```

#### Paso 5b — Template body per-task CR (formato bot CRS real)

> Validado contra threads reales: `1520104297784807705`, `1520104327253856358`, `1520104390013227078`.

```javascript
function buildCRThreadBody(accion, notionPage, experiment, responsableTag) {
  return `${responsableTag}

📌 **CR — ${accion.nombre_corto}**

**Tarea:** ${accion.descripcion}
${accion.bullets ? accion.bullets.map(b => `- ${b}`).join('\n') : ''}

**Deadline:** ${formatDDMMYYYY(accion.deadline)}${accion.es_rat ? ' ⚡ BLOCKER de otras tareas' : ''}
**Evidencia:** ${accion.dod || 'pendiente — agregar DoD'}

📎 **Notion:** ${notionPage.url}
🧪 **Experimento:** experiments/${experiment.id}`;
}
```

#### Paso 5c — Template body consolidado (solo `#iniciativas-tech`)

```javascript
function buildInitiativeThreadBody(experiment, acciones, notionPages, tag) {
  const fecha = formatDDMMYYYY(experiment.fecha_evaluacion);
  const lines = [
    `📌 **Acuerdos Sesión Iniciativa ${fecha}** — ${tag}`,
    '',
    '**Próximos pasos:**',
    '',
  ];
  acciones.forEach((a, i) => {
    const np = notionPages[i]?.page?.url;
    lines.push(`${i + 1}. **${a.nombre_corto}** (vence ${formatDDMMYYYY(a.deadline)}): ${a.descripcion.slice(0, 200)}.${np ? ` [Notion](${np})` : ''}`);
  });
  lines.push('');
  lines.push(`🎯 **KPI:** ${experiment.kpi_nombre || 'TBD'}  |  Baseline: ${experiment.baseline_valor} → Target: ${experiment.target_mde}`);
  lines.push(`🧪 **Experimento:** experiments/${experiment.id}`);
  return lines.join('\n');
}
```

### Naming convention real (descubierto en threads existentes)

```javascript
function buildThreadName(input) {
  const fecha = formatDate(input.fecha_evaluacion);  // DD/MM/YYYY

  // Planning Producto → 1 thread por OWNER, consolida sus proyectos
  if (input.tipo === 'BET' || input.tipo === 'iniciativa') {
    const planning = input.planning_session ? ` - Planning S${input.planning_session}` : '';
    return `Iniciativa - ${input.owner_dri} - ${fecha}${planning}`;
  }

  // Weekly Exec CR → 1 thread por TAREA
  if (input.tipo === 'weekly-cr') {
    const tarea = input.tarea_n ? `Tarea ${input.tarea_n} - ` : '';
    const sem = input.weekly_sem ? `Weekly Sem ${input.weekly_sem}` : '';
    return `CR - ${input.owner_dri} - ${fecha} - ${tarea}${sem}`.trim();
  }

  // Performance
  if (input.tipo === 'performance') {
    const tarea = input.tarea_n ? ` - Tarea ${input.tarea_n}` : '';
    return `CR Perf ${input.owner_dri} - ${fecha}${tarea}`;
  }

  // Standalone CR ad-hoc
  if (input.tipo === 'cross-equipos' || !input.tipo) {
    const tema = (input.nombre_corto || '').slice(0, 40);
    return `CR - ${input.owner_dri} - ${fecha} - ${tema}`;
  }

  // Issue (legacy o not)
  return `Issue - ${(input.nombre_corto || '').slice(0, 55)} - ${fecha}`;
}
```

### Template thread body — Planning Iniciativa (formato real bot CRS)

```
📌 **Acuerdos Sesión Iniciativa {DD/MM/YYYY}** — {responsableTag}

**Próximos pasos — vence {fecha_evaluacion}:**

1. **{Accion 1 título}** ({owners 1}): {descripcion 1}.

2. **{Accion 2 título}** ({owners 2}): {descripcion 2}.
→ {Sub-accion adicional para otra persona}

3. **{Accion 3 título}**: {descripcion 3}.

**Próxima sesión: {fecha_proxima} — {hora}**
Para esa fecha: {entregables esperados}.

🔗 **Experimento:** experiments/{exp_id}
🔗 **Notion:** {notion_url}

cc: {stakeholders_tags}
```

### Template thread body — Issue (con KPI header obligatorio)

> Memoria: issue threads OBLIGATORIO header con KPI text verbatim del Notion DB Issues.

```
🎯 **KPI:** {nombre_kpis verbatim del Notion}
🎯 **Meta de éxito:** {meta_kpis verbatim}
📅 **Fecha ejecución:** {fecha_ejecucion}
📅 **Fecha resultados:** {fecha_resultados}
🔗 **Issue Notion:** {notion_url}

---

{responsableTag}

{descripcion_del_issue}

Por favor, confirma recepción y acuerdo con la fecha límite planteada.
```

### Template thread body — Weekly Exec CR

```
{responsableTag}

📋 **Tarea:** {nombre_corto}
🎯 **Contexto:** {contexto_breve}
📎 **Evidencia/DoD:** {entregable}
📅 **Fecha entrega:** {fecha_evaluacion}
🔗 **Notion:** {notion_url}

Por favor, confirma recepción y acuerdo con la fecha límite planteada.
```

### Paso 6 — Reportar

```json
{
  "notion_page_url": "https://notion.so/...",
  "notion_page_id": "abc-123",
  "discord_permalink": "https://discord.com/channels/619991595613290496/.../...",
  "discord_thread_id": "...",
  "channel": "#iniciativas-tech",
  "channel_id": "959484680137211964",
  "tagged_user": "<@689153159356350533>",
  "exp_id": "exp-2026-014",
  "status": "published"
}
```

> **Nota v1.4.0:** los templates inline (con 🚀 / `:red_circle:` / `:bust_in_silhouette:` / etc.) de v1.2.0–v1.3.0 NO reflejan el formato real del bot CRS. Templates reales están arriba en sección "Template thread body". Esta sección legacy se conserva solo como referencia histórica.

### Template legacy v1.2 (desuso — referencia)

<details>
<summary>Ver templates v1.2 (NO usar para iniciativas nuevas)</summary>

```
🚀 **Iniciativa: {nombre_corto}**
{responsableTag}
📋 **Acciones:** ...
🎯 **KPI a mover:** ...
```

```
:red_circle: **Issue: {nombre_corto}**
:bust_in_silhouette: **Propuesto por:** ...
:calendar: **Entrega:** ...
```

</details>

---

## Edge cases

| Caso | Comportamiento |
|------|----------------|
| `tipo='BET'` + area=Producto/Tech | `#iniciativas-tech` (especialización dev) |
| `tipo='BET'` + area no-software | `#weekly-exec-okrs` (visibilidad ejecutiva) |
| `tipo='iniciativa'` o `tipo='issue'` con `exp_id` o `issue_id` | `#weekly-exec-okrs` (regla v1.3.0) |
| `tipo='cross-equipos'` + cr_pair válido, SIN exp_id ni issue_id | Canal `#crs-*` correspondiente |
| `tipo='cross-equipos'` + cr_pair con exp_id presente | `#weekly-exec-okrs` gana (visibilidad > especificidad interna) |
| `tipo='issue-legacy'` | `#issues-líderes`/`#issues-general` según líder (compat con n8n cron) |
| Sin `tipo` y sin `exp_id`/`issue_id` | Default `#weekly-exec-okrs` |
| Owner sin `owner_discord_id` y no en LEADERS | Texto plano + warning "no se notificará via ping" |
| `tipo='cross-equipos'` sin `cr_pair` | Error "cr_pair requerido para cross-equipos" |
| Bot REST API 401 (token inválido) | Fallback a webhook (solo para issues-líderes/general) |
| Bot REST API 403 (canal sin permisos) | Error + reporta al usuario qué canal le falta permisos al bot |
| Notion DB Tasks no responde | ABORT — no se puede crear sin DB |
| `nombre_corto > 100 chars` | Truncar a 97 + "..." |
| Multi-task para mismo owner (1 thread por tarea según workflow MV) | Crear N pages Notion + N mensajes Discord (1 por tarea) |

---

## Inputs requeridos

| Input | Obligatorio | Fuente |
|-------|-------------|--------|
| `owner_dri` | ✅ | Caller |
| `acciones` o `texto_libre` | ✅ | Caller |
| `nombre_corto` | recomendado | Caller |
| `tipo` | default `'issue'` | Caller |
| `area` | requerido si `tipo='BET'` | Caller / exp-iniciativa |
| `cr_pair` | requerido si `tipo='cross-equipos'` | Caller |
| `owner_discord_id` | recomendado para ping | Caller / lookup LEADERS |
| `owner_notion_id` | recomendado | Caller / lookup |
| `kpi_nombre`, `kpi_numbers`, `target_mde`, `fecha_evaluacion` | opcional | exp-iniciativa |
| Env `DISCORD_BOT_TOKEN` | ✅ | Vercel/local (token bot CRS) |
| Env `NOTION_TOKEN` | ✅ | Vercel/local |

## Outputs

| Output | Destino |
|--------|---------|
| Page Notion | Tasks DB (default) o Issues a Discord DB (`legacy_issue`) |
| Mensaje Discord | Canal según routing |
| Thread Discord | Mismo canal, auto-archive 1440min |
| Permalinks | Devuelto al caller |
| UPDATE `experiments.link_cr` | Caller hace PATCH /api/experiments/:id |

---

## Vinculación con otros skills

```
exp-iniciativa (Julio, genérico)
  ├── Paso 0 si area=software → bifurca a mv-instruction-generator
  └── Paso 5 invoca crear-cr ──► routing por tipo+area ──► return Notion+Discord links

mv-instruction-generator v1.8.0 (Carlos, dev)
  ├── Fase 0.B genera PRD-para-Claude
  └── Después invoca crear-cr con tipo='BET' + area='Producto'/'Tech'
       → routea a #iniciativas-tech (NO a #issues-líderes)

informe-resultados
  └── Veredicto 🟥 Falló → invoca crear-cr con tipo='issue' para acción de reversión
```

---

## Decisión técnica: bot REST vs webhook

**v1.0.0–v1.1.0:** webhook URLs (2: leaders + general). Problema: `#iniciativas-tech` y `#crs-*` no tienen webhooks → necesitaríamos crear 7+ webhooks adicionales.

**v1.2.0 (esta):** bot CRS REST API directo. Pros:
- Funciona en TODOS los canales sin webhooks adicionales (bot ya tiene Send Messages).
- Devuelve message object completo (id + channel_id).
- Permite crear thread auto-archive en el mismo flow.
- Permite `allowed_mentions` (ping al responsable).

**Único trade-off:** requiere `DISCORD_BOT_TOKEN` en env. Webhook era anónimo (no requería token). Para Vercel ya tenemos NOTION_TOKEN — agregar uno más es trivial.

---

## Stub Python (mínimo viable)

```python
import os, requests, json
from datetime import datetime

DISCORD_BOT_TOKEN = os.environ["DISCORD_BOT_TOKEN"]
NOTION_TOKEN = os.environ["NOTION_TOKEN"]
GUILD_ID = "619991595613290496"

NOTION_DB_TASKS = "95684528-9b3a-440e-91c7-f12ca1e15de4"   # "Tasks " (verificado live 2026-07-18)
NOTION_DB_ISSUES = "202fb2dd-5c7e-407c-8e48-aa1c5b02fb75"  # "Issue Inventory" (issue paraguas del exp)

CHANNELS = {
    'iniciativas_tech':  '959484680137211964',
    'issues_lideres':    '1504224713038368788',
    'issues_general':    '1506685505872461856',
    'weekly_exec_okrs':  '1407016069503258674',
    'crs_atc_ops_daily': '1504608667063029820',
    'crs_atc_ops_fc':    '1504608691427479773',
    'crs_fin_ops_daily': '1504608708087517266',
    'crs_fin_ops_fc':    '1504608716186583050',
    'crs_fin_ventas':    '1504608724386447480',
    'crs_ops_interno':   '1506689003267690526',
}

LEADERS = {
    'Carlos Andrade':      {'notion': '1c70a5ae-72d3-4dbb-8961-5268c150d0fe', 'discord': '689153159356350533'},
    'Julio Mori':          {'notion': '1b2d872b-594c-8122-8cc3-0002af438bb0', 'discord': '1348675309024837714'},
    'Larissa Arias':       {'notion': '2797b08b-7dbf-4730-a264-dfd9202a683d', 'discord': '752683102836490322'},
    'Adin Garcia':         {'notion': '9d5550fb-0233-4143-a394-889fb45ffd0b', 'discord': '393973271529259008'},
    'Humberto Gomez':      {'notion': '8d66ae05-ac2b-490a-a678-1bcca76f8b87', 'discord': '717914309081956353'},
    'Carolina Andrade':    {'notion': '58e1729b-ef4c-4e5c-8057-3766d184b499', 'discord': '973237730219794502'},
    'Cristhian Mayo':      {'notion': '14bd872b-594c-8114-9fca-0002c9281d03', 'discord': '1337531659431710750'},
    'Alejandra Rincones':  {'notion': 'cd83bab4-e8f9-40c0-93f3-22132f7db5f4', 'discord': '735662405014519839'},
}

DISCORD_API = "https://discord.com/api/v10"
NOTION_API = "https://api.notion.com/v1"
DISCORD_HEADERS = {"Authorization": f"Bot {DISCORD_BOT_TOKEN}", "Content-Type": "application/json"}
NOTION_HEADERS = {
    "Authorization": f"Bearer {NOTION_TOKEN}",
    "Content-Type": "application/json",
    "Notion-Version": "2022-06-28",
}


SOFTWARE_AREAS = {'Producto', 'Tech', 'Growth - Producto', 'Growth - Tech'}

def route_channel(tipo, area, owner_dri, owner_notion_id=None, cr_pair=None,
                  es_weekly=False, estrategico=False, exp_id=None, issue_id=None):
    """Routing v1.4.0 (ajuste Julio 2026-07-21). Prioridad, primer match gana:
       1. tarea de reunion semanal -> #weekly-exec-okrs
       2. issue/iniciativa tech (software) -> #iniciativas-tech
       3. CR interno cross-equipos con acuerdo (cr_pair) -> #crs-*
       4. issue no-tech -> #issues-lideres (lider/estrategico) | #issues-general
       weekly YA NO es el default de toda iniciativa/issue."""
    # 1. Tarea de reunion semanal
    if es_weekly or tipo == 'weekly-cr':
        return CHANNELS['weekly_exec_okrs'], '#weekly-exec-okrs'

    # 2. Issue/iniciativa tech (software)
    if area in SOFTWARE_AREAS:
        return CHANNELS['iniciativas_tech'], '#iniciativas-tech'

    # 3. CR interno cross-equipos con acuerdo previo
    if cr_pair:
        key = 'crs_' + cr_pair.replace('-', '_').replace('foodcourt', 'fc').replace('ventas_atc_mkt', 'fin_ventas')
        if key in CHANNELS:
            return CHANNELS[key], f"#{key.replace('_', '-')}"

    # 4. Issue no-tech (default): lider/estrategico -> lideres, resto -> general
    is_leader = estrategico \
        or (owner_notion_id and any(L['notion'] == owner_notion_id for L in LEADERS.values())) \
        or owner_dri in LEADERS
    return (CHANNELS['issues_lideres'], '#issues-líderes') if is_leader \
        else (CHANNELS['issues_general'], '#issues-general')


def resolve_responsable_tag(owner_dri, owner_discord_id=None):
    if owner_discord_id:
        return f"<@{owner_discord_id}>"
    found = LEADERS.get(owner_dri)
    if found:
        return f"<@{found['discord']}>"
    return owner_dri


def crear_cr(owner_dri, acciones, *, tipo=None, area=None, cr_pair=None,
             nombre_corto=None, exp_id=None, issue_id=None, kpi_nombre=None, kpi_numbers=None,
             target_mde=None, fecha_evaluacion=None, decision_type=None,
             owner_notion_id=None, owner_discord_id=None, legacy_issue=False):

    # Default tipo: 'iniciativa' si vinculado a exp/issue, sino 'issue'
    if tipo is None:
        tipo = 'iniciativa' if (exp_id or issue_id) else 'issue'

    name = (nombre_corto or acciones.split("\n")[0])[:80]
    channel_id, channel_name = route_channel(tipo, area, owner_dri, owner_notion_id, cr_pair, exp_id, issue_id)
    tag = resolve_responsable_tag(owner_dri, owner_discord_id)

    # 1. Notion page
    db_id = NOTION_DB_ISSUES_LEGACY if legacy_issue else NOTION_DB_TASKS
    if legacy_issue:
        props = build_issue_legacy_props(name, owner_notion_id, fecha_evaluacion, kpi_nombre, target_mde, decision_type, acciones)
    else:
        props = build_tasks_props(name, owner_notion_id, fecha_evaluacion, kpi_numbers or [])

    r = requests.post(f"{NOTION_API}/pages", headers=NOTION_HEADERS,
                      json={"parent": {"database_id": db_id}, "properties": props}, timeout=15)
    if r.status_code >= 400:
        return {"error": f"notion {r.status_code}", "body": r.text}
    notion_page = r.json()

    # 2. Crear thread DIRECTO (type: 11, sin parent message) — formato MV real
    thread_name = build_thread_name(tipo, owner_dri, fecha_evaluacion, name,
                                     planning_session=None, weekly_sem=None, tarea_n=None)
    rt = requests.post(
        f"{DISCORD_API}/channels/{channel_id}/threads",
        headers=DISCORD_HEADERS,
        json={"name": thread_name[:100], "type": 11, "auto_archive_duration": 1440},
        timeout=15,
    )
    if rt.status_code >= 400:
        return {"notion_page_url": notion_page['url'], "error": f"discord thread {rt.status_code}", "body": rt.text}
    thread_id = rt.json()['id']
    thread_permalink = f"https://discord.com/channels/{GUILD_ID}/{thread_id}"

    # 3. Postear mensaje DENTRO del thread con formato Acuerdos
    content = render_thread_body(tipo, name, tag, owner_dri, acciones, kpi_nombre,
                                  target_mde, fecha_evaluacion, notion_page['url'], exp_id)
    rm = requests.post(
        f"{DISCORD_API}/channels/{thread_id}/messages",
        headers=DISCORD_HEADERS,
        json={"content": content[:1900], "allowed_mentions": {"parse": ["users"]}},
        timeout=15,
    )
    msg_id = rm.json().get('id') if rm.status_code < 400 else None

    return {
        "notion_page_url": notion_page['url'],
        "notion_page_id": notion_page['id'],
        "discord_thread_permalink": thread_permalink,
        "discord_thread_id": thread_id,
        "discord_message_id": msg_id,
        "channel": channel_name,
        "channel_id": channel_id,
        "thread_name": thread_name,
        "tagged_user": tag,
        "exp_id": exp_id,
        "status": "published",
    }


def build_thread_name(tipo, owner_dri, fecha_evaluacion, nombre_corto,
                     planning_session=None, weekly_sem=None, tarea_n=None):
    """Naming convention MV real."""
    fecha = format_date_ddmmyyyy(fecha_evaluacion) if fecha_evaluacion else 'TBD'

    if tipo in ('BET', 'iniciativa'):
        planning = f" - Planning S{planning_session}" if planning_session else ''
        return f"Iniciativa - {owner_dri} - {fecha}{planning}"

    if tipo == 'weekly-cr':
        tarea = f"Tarea {tarea_n} - " if tarea_n else ''
        sem = f"Weekly Sem {weekly_sem}" if weekly_sem else ''
        return f"CR - {owner_dri} - {fecha} - {tarea}{sem}".strip(' -')

    if tipo == 'performance':
        return f"CR Perf {owner_dri} - {fecha}" + (f" - Tarea {tarea_n}" if tarea_n else '')

    if tipo in ('cross-equipos',) or tipo is None:
        tema = (nombre_corto or '')[:40]
        return f"CR - {owner_dri} - {fecha} - {tema}"

    return f"Issue - {(nombre_corto or '')[:55]} - {fecha}"


def format_date_ddmmyyyy(iso_date):
    if not iso_date: return 'TBD'
    parts = iso_date.split('-')
    if len(parts) != 3: return iso_date
    y, m, d = parts
    return f"{d}/{m}/{y}"


def render_thread_body(tipo, name, tag, owner_dri, acciones, kpi, meta, fecha, notion_url, exp_id):
    """Formato real bot CRS observado en threads como 1517223107356524707."""
    fecha_str = format_date_ddmmyyyy(fecha) if fecha else 'TBD'

    if tipo in ('BET', 'iniciativa'):
        # Planning Iniciativa — 1 thread por OWNER con bullets
        lines = [
            f"📌 **Acuerdos Sesión Iniciativa {fecha_str}** — {tag}",
            "",
            "**Próximos pasos:**",
            "",
        ]
        # Acciones numeradas (split by newline si vienen como string)
        if isinstance(acciones, str):
            for i, line in enumerate([l.strip() for l in acciones.split('\n') if l.strip()][:5], 1):
                lines.append(f"{i}. **{line[:200]}**")
        lines.append("")
        if kpi:
            lines.append(f"🎯 **KPI:** {kpi}" + (f"  |  Meta: {meta}" if meta else ""))
        if fecha:
            lines.append(f"📅 **Fecha entrega:** {fecha_str}")
        if exp_id:
            lines.append(f"🔗 **Experimento:** experiments/{exp_id}")
        lines.append(f"🔗 **Notion:** {notion_url}")
        return "\n".join(lines)

    if tipo == 'issue-legacy':
        # Header KPI obligatorio (memoria feedback_issue_thread_kpi_header)
        lines = [
            f"🎯 **KPI:** {kpi or 'TBD'}",
            f"🎯 **Meta de éxito:** {meta or 'TBD'}",
            f"📅 **Fecha ejecución:** {fecha_str}",
            f"🔗 **Issue Notion:** {notion_url}",
            "",
            "---",
            "",
            tag,
            "",
            (acciones or '')[:400],
            "",
            "Por favor, confirma recepción y acuerdo con la fecha límite planteada.",
        ]
        return "\n".join(lines)

    # Weekly Exec CR o standalone — formato CR conciso
    lines = [
        tag,
        "",
        f"📋 **Tarea:** {name}",
    ]
    if kpi: lines.append(f"🎯 **KPI:** {kpi}" + (f"  |  Meta: {meta}" if meta else ""))
    if acciones: lines.append(f"📎 **Detalle:** {acciones[:400]}")
    if fecha: lines.append(f"📅 **Fecha entrega:** {fecha_str}")
    lines += ["", f"🔗 **Notion:** {notion_url}",
              "", "Por favor, confirma recepción y acuerdo con la fecha límite planteada."]
    return "\n".join(lines)


def build_tasks_props(name, owner_notion_id, fecha_evaluacion, kpi_numbers, issue_page_id=None):
    p = {
        "Tasks": {"title": [{"text": {"content": name}}]},
        "Status": {"status": {"name": "To Do"}},
        "Company Brain": {"checkbox": True},   # marca para vistas filtradas del sub-mundo Brain en el HUB
    }
    if owner_notion_id:
        p["Responsable"] = {"people": [{"id": owner_notion_id}]}
    if fecha_evaluacion:
        p["Fecha Deadline"] = {"date": {"start": fecha_evaluacion}}
    if kpi_numbers:
        p["KPI number"] = {"multi_select": [{"name": str(n)} for n in kpi_numbers]}
    if issue_page_id:  # task de iniciativa → adjuntar al Issue del experimento
        p["Issue Inventory (Tasks)"] = {"relation": [{"id": issue_page_id}]}
    return p


def build_issue_legacy_props(name, owner_notion_id, fecha_evaluacion, kpi_nombre, target_mde, decision_type, acciones):
    p = {
        "Issue Name": {"title": [{"text": {"content": name}}]},
        "Status": {"status": {"name": "Active"}},
        "Issue Description": {"rich_text": [{"text": {"content": (acciones or "")[:1900]}}]},
    }
    if owner_notion_id:
        p["Decision Maker"] = {"people": [{"id": owner_notion_id}]}
    if fecha_evaluacion:
        p["Fecha ejecucion"] = {"date": {"start": fecha_evaluacion}}
    if kpi_nombre:
        p["Nombre KPIs"] = {"rich_text": [{"text": {"content": kpi_nombre}}]}
    if target_mde:
        p["Meta KPIs"] = {"rich_text": [{"text": {"content": str(target_mde)}}]}
    if decision_type:
        p["Decision Type"] = {"select": {"name": decision_type}}
    return p


def render_body(tipo, name, tag, owner_dri, acciones, kpi, meta, fecha, notion_url, exp_id):
    if tipo == 'BET':
        lines = [
            f"🚀 **Iniciativa: {name}**",
            "",
            tag,
            "",
            "📋 **Acciones:**",
            acciones[:600] if acciones else "(sin acciones detalladas)",
        ]
        if kpi: lines.append(f"\n🎯 **KPI a mover:** {kpi}" + (f"  |  Meta: {meta}" if meta else ""))
        if fecha: lines.append(f"📅 **Fecha entrega:** {fecha}")
        if exp_id: lines.append(f"🧪 **Experimento:** experiments/{exp_id}")
        lines += ["", f"🔗 **Notion:** {notion_url}", "", "Por favor, confirma recepción y acuerdo con la fecha límite."]
        return "\n".join(lines)
    # Issue clásico
    lines = [
        f":red_circle: **Issue: {name}**",
        "",
        tag,
        "",
        f":bust_in_silhouette: **Decisor:** {owner_dri}",
        f":calendar: **Entrega: {fecha or 'No definida'}  |  Estado: Active**",
    ]
    if kpi: lines.append(f":chart_with_upwards_trend: **KPI:** {kpi}" + (f"  |  Meta: {meta}" if meta else ""))
    if acciones:
        d = acciones if len(acciones) <= 400 else acciones[:397] + "..."
        lines += ["", f":notepad_spiral: {d}"]
    lines += ["", f":link: **Notion:** {notion_url}"]
    return "\n".join(lines)
```

---

## Testing

| # | Escenario | Esperado |
|---|-----------|----------|
| T1 | `tipo='BET'` + area=Producto | `#iniciativas-tech`, tag responsable, Tasks DB |
| T2 | `tipo='BET'` + area=Growth (no software) | `#weekly-exec-okrs` (NO líderes — regla v1.3.0) |
| T3 | `tipo='iniciativa'` + exp_id=exp-2026-014 | `#weekly-exec-okrs` |
| T4 | `tipo='issue'` + issue_id=abc | `#weekly-exec-okrs` |
| T5 | `tipo='cross-equipos'` + cr_pair=atc-ops-daily, sin exp_id | `#crs-atc-ops-daily` |
| T6 | `tipo='cross-equipos'` + cr_pair=atc-ops-daily, **con exp_id** | `#weekly-exec-okrs` gana (regla v1.3.0) |
| T7 | `tipo='issue-legacy'` + owner=Carlos | `#issues-líderes` (compat n8n) |
| T8 | Sin `tipo` ni `exp_id` ni `issue_id` | `#weekly-exec-okrs` (default visibilidad) |
| T9 | `tipo='weekly-cr'` | `#weekly-exec-okrs` |
| T10 | Owner sin discord_id ni en LEADERS | Texto plano + warning, sin tag |
| T11 | Bot 401 (token bad) | Error explícito + sugerir verificar DISCORD_BOT_TOKEN |
| T12 | Bot 403 (sin permisos canal) | Error + reportar canal/permiso faltante |
| T13 | Multi-task mismo owner | N pages + N mensajes (1 por tarea) |
| T14 | `legacy_issue=true` (DB) | Escribe a Issues a Discord DB con schema legacy |
| T15 | `tipo='BET'` desde mv-instruction-generator Fase 0.B | `#iniciativas-tech` + thread "Iniciativa - ..." |

---

## Env vars Vercel

```bash
# Ya configurado
NOTION_TOKEN=ntn_...

# Nuevo (extraer del bot CRS Discord Developer Portal)
DISCORD_BOT_TOKEN=MTQ5MzY2MjEwODQzMTQx...  # Bot CRS#6481, ID 1493662108431417354

# Opcionales (fallback solo si bot token no disponible)
DISCORD_WEBHOOK_ISSUES_LEADERS=https://discord.com/api/webhooks/1506691812050604032/...
DISCORD_WEBHOOK_ISSUES_GENERAL=https://discord.com/api/webhooks/1506691377424236704/...
```

> El bot CRS ya está autenticado en n8n (credential `6UHwJBZ20k1JzCZ6`). Mismo token sirve acá. Julio lo extrae del Discord Developer Portal o de `~/.claude.json` local (MCP discord env).

---

## Métrica de éxito

- **100%** CRs creados via skill llegan a Discord con tag `<@id>` del responsable.
- **0** CRs huérfanos (sin Responsable o sin Fecha Deadline).
- **100%** BETs con area∈software van a `#iniciativas-tech` (no a issues genérico).
- **100%** CRs sub-llamados desde `exp-iniciativa` resultan en `experiments.link_cr IS NOT NULL`.
- **<3s** latencia P95 end-to-end (Notion + Discord + thread).

---

## Dependencias

- ✅ Server Discord `manzanaverde` con 10 canales relevantes mapeados.
- ✅ Bot CRS#6481 autenticado con Send Messages + Create Threads en todos los canales.
- ✅ Notion DBs Tasks (`95684528-...`) + Issue Inventory (`202fb2dd-...`) operativas (token "Token Brain" RW verificado 2026-07-18).
- ✅ Tabla `experiments` (link_cr UPDATE desde `exp-iniciativa`).
- ⬜ Env Vercel `DISCORD_BOT_TOKEN` (extraer del bot CRS).
- ⬜ Smoke test E2E desde `exp-iniciativa` con area=Producto → debe terminar en `#iniciativas-tech`.

---

## Vinculación al Issue de la iniciativa (v1.7 — Carlos 2026-07-17)

- **CR de una iniciativa** (`exp_id` presente): las tasks/CRs se **vinculan al Issue** del experimento (el Issue que creó `exp-iniciativa` en "Issue Inventory"). La task queda colgada del issue paraguas → trazabilidad iniciativa → sus CRs.
  - Resolver el `notion_id` (page id del issue) desde `experiments` por `exp_id`.
  - Setear la relation `Issue Inventory (Tasks)` = `[{id: issue_page_id}]` al crear la page en Tasks DB.
- **CR libre** (standalone, sin `exp_id` ni `issue_id`): se crea **solo la task libre** en Tasks DB, sin issue paraguas.

```
crear-cr con exp_id  → task(s) con relation Issue Inventory (Tasks) = issue del experimento
crear-cr standalone  → task libre (relation vacía)
```

> ✅ **Schema confirmado live 2026-07-18:** la relation Task↔Issue es bidireccional — Tasks DB (`95684528`) prop `Issue Inventory (Tasks)` → Issue Inventory (`202fb2dd`); e inversa `Tasks ` en el Issue. El Issue del experimento vive en Issue Inventory (`202fb2dd`), el mismo destino de la relation. Setear `Issue Inventory (Tasks)` = `[{id: issue_page_id}]`.

## Changelog

- **v1.8.1 (2026-07-22)** — Fix IDs database vs data_source + formatos MCP. Cada DB tiene 2 ids: `database_id` (raw REST API) y `data_source_id` (Notion MCP). Tasks: db `95684528` / ds `f63d7df1`. Issue Inventory: db `202fb2dd` / ds `9b170e57`. Corregido el bug del Paso 4 (MCP usaba el database_id como data_source_id → 404). Formatos MCP correctos: checkbox `"__YES__"`, person/multi-select = array de strings, relation = array de page ids/urls, id/url → prefijo `userDefined:`. Corrige la nota "phantom" errónea de v1.7.1.
- **v1.8.0 (2026-07-21)** — Routing ajustado (Julio). Weekly YA NO es el default de toda iniciativa/issue: (1) tarea de reunión semanal `es_weekly` → #weekly-exec-okrs; (2) issue/iniciativa tech (software) → #iniciativas-tech; (3) CR cross-equipos con `cr_pair` → #crs-*; (4) issue no-tech → #issues-líderes (líder/estratégico) o #issues-general. `route_channel()` reescrito + params `es_weekly`/`estrategico`. Los 6 canales #crs-* siguen mapeados.
- **v1.7.2 (2026-07-18)** — Sub-mundo Brain: task setea `Company Brain=true` (para vistas filtradas del HUB) + param `issue_page_id` para relation a Issue de iniciativa.
- **v1.7.1 (2026-07-18)** — Fix IDs verificados live + relation confirmada. ~~Tasks DB `f63d7df1` (phantom, 404) → real `95684528`~~ **(CORREGIDO en v1.8.1: `f63d7df1` NO es phantom — es el data_source_id de Tasks; `95684528` es el database_id).** Issue DB = "Issue Inventory" `202fb2dd`. Relation Task→Issue resuelta: `Issue Inventory (Tasks)` = `[{id: issue_page_id}]`. Token "Token Brain" RW verificado (workspace Manzana Verde).
- **v1.7.0 (2026-07-17)** — Vinculación al Issue de iniciativa (Carlos v2). CR con exp_id → task vinculada al Issue paraguas; CR libre → task suelta.
- **v1.6.0 (2026-07-11)** — KPI/input propagation (regla auto-link)
  - Si `exp_id` presente → **heredar automático** `kpi_definition_id` desde `experiments_with_kpi` view
  - Notion Tasks DB: poblar `KPI number` (multi_select) auto con `[kpi_definition_id]`
  - Recomendado (no obligatorio aún) pasar `kpi_numbers[]` cuando standalone
  - Body Discord thread: agregar línea `🎯 KPI:` con nombre canónico del catálogo si linkeado
  - Response array items agrega `kpi_definition_id` y `kpi_inputs_count` para trazabilidad

- **v1.5.0 (2026-06-30, post-E2E)** — Granularidad real: 1 tarea = 1 CR = 1 Notion = 1 thread
  - Validación E2E descubrió que `#weekly-exec-okrs` usa **1 thread por TAREA** (no por iniciativa)
  - `acciones_array` parameter: array de items con {nombre_corto, descripcion, deadline, sub_owner, es_rat}
  - Legacy `acciones` string se auto-parsea por líneas numeradas
  - Loop crear N Notion pages (1 por tarea) + N Discord threads (en weekly/crs/issues)
  - Excepción `#iniciativas-tech`: mantiene 1 thread consolidado por OWNER con bullets
  - **Notion API format expandido validado:** `date:Fecha Deadline:start` (no `Fecha Deadline` plano)
  - Schema editable real de Tasks DB confirmado vía error API:
    Tasks/Status/Responsable/Asignee/Fecha Deadline/KPI number/Highest Priority/Project/Areas/etc.
  - Templates separados: `buildCRThreadBody` (per-task) vs `buildInitiativeThreadBody` (consolidado)
  - Smoke E2E exitoso: 5 acciones de exp-2026-008 → 5 threads + 5 Notion tasks separados

- **v1.4.0 (2026-06-30)** — Formato real de threads (descubierto vía Discord MCP)
  - **Thread directo `type: 11`** (sin parent message en canal padre) — los threads de iniciativas en MV no nacen de un msg + thread-on-message
  - **Naming convention precisa** por ritual:
    - Planning: `Iniciativa - {Persona} - DD/MM/YYYY - Planning S<N>`
    - Weekly: `CR - {Persona} - DD/MM/YYYY - Tarea N - Weekly Sem N`
    - Performance: `CR Perf {Persona} - DD/MM/YYYY - Tarea N`
    - Standalone: `CR - {Persona} - DD/MM/YYYY - <tema>`
  - **Template `📌 Acuerdos Sesión Iniciativa DD/MM/YYYY`** para BETs/iniciativas (replica formato real del bot CRS observado en threads como `1521144145354293318`, `1517223107356524707`)
  - **Issue threads** con header KPI obligatorio (🎯 KPI / Meta / Fechas / Notion link) — verbatim del Notion DB Issues
  - **Planning Producto: 1 thread por OWNER** (consolidate sus proyectos), no 1 por proyecto
  - **Weekly Exec: 1 thread por TAREA** (no por persona), incluso si misma fecha
  - Smoke test exp-2026-004 → thread `1521582278176932004` validado en `#iniciativas-tech` con formato Acuerdos real

- **v1.3.0 (2026-06-30)** — Regla weekly de visibilidad ejecutiva
  - **Nueva regla:** CRs vinculados a iniciativa (exp_id) o issue (issue_id) → `#weekly-exec-okrs` SIEMPRE (visibilidad Carlos/Julio en weekly)
  - Excepción: BETs software siguen yendo a `#iniciativas-tech` (canal especializado dev)
  - Canales `#crs-*` solo para CRs específicos internos entre equipos SIN iniciativa de fondo
  - `tipo` ahora soporta `'iniciativa'` y `'issue-legacy'` (issues clásicos n8n)
  - Default fallback cuando no hay clasificación clara → `#weekly-exec-okrs`
  - Field `issue_id` agregado al input shape
  - 15 escenarios de testing (antes 10)

- **v1.2.0 (2026-06-30)** — Routing real descubierto vía bot Discord MCP
  - **Canal `#iniciativas-tech` (`959484680137211964`)** para BETs software (no `#issues-general`)
  - 6 canales `#crs-*` cross-equipos mapeados (ATC↔Ops, Finanzas↔*, Ops interno)
  - Bot REST API directo (no webhook) — funciona en TODOS los canales
  - Tag `<@discord_id>` obligatorio del responsable (memoria critical feedback)
  - Tasks DB (`f63d7df1-...`) como destino default; Issues a Discord como `legacy_issue=true`
  - Thread auto-creado con título "Iniciativa - ..." o "CR - ..." según tipo
  - 8 líderes mapeados con notion UUID + discord ID
  - Stub Python actualizado con todo el mapping
  - 10 escenarios de testing

- **v1.1.0 (2026-06-30)** — Alineado con n8n workflow q9K38OEiEju9eazK (líderes/general)
- **v1.0.0 (2026-06-30)** — Build inicial post-skeleton (8 canales asumidos, sobre-engineerizado)

---

**FIN.** Spec base: `producto/estrategia/iniciativa-ai-native-dev/04-skill-crear-cr.md`. Routing real: descubierto vía Discord MCP + memoria proyecto Discord (`~/.claude/projects/c--Proyectos-Discord/memory/`).
