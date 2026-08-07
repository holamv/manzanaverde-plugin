---
name: exp-iniciativa
description: |
  Crea iniciativa/experimento estructurado, captura baseline del datalake, propone diseño estadístico,
  y lo persiste vía endpoint server-side `POST /api/exp-iniciativa` (data-lake-mv) que escribe la
  tabla `experiments` y crea el Issue Notion. Sin tokens de servicio en cliente.
  Genérico cross-area (Operaciones / Producto / Growth / Finanzas / MKT / Reconsumos / DK / CX).
  Bifurca a `mv-instruction-generator` v1.8.0 (Carlos) si area ∈ {Producto, Tech, Growth-Producto, Growth-Tech}.
  Co-llama a `crear-cr` para tareas clave. Cierra el ciclo con `informe-resultados` en fecha_evaluacion.
trigger_phrases:
  - "/exp-iniciativa"
  - "crear iniciativa"
  - "nuevo experimento"
  - "registrar BET"
  - "crear apuesta"
version: 1.4.0
owner: Julio Mori
based_on:
  - producto/estrategia/iniciativa-ai-native-dev/03-skill-exp-iniciativa.md
  - SP3 challenge gate (15/15 stress tests)
  - mv-instruction-generator v1.8.0 (Fase 0 + Sprint additions)
---

# Skill `exp-iniciativa` v1.4.0

> Skill genérico cross-area del Sprint Company Brain. Reemplaza el flujo "crear issue manual en Notion" con un flujo que **estructura + mide + persiste** en `experiments`. Vincula con `crear-cr` (Discord/tasks) e `informe-resultados` (cierre línea de datos).
>
> **Fase 3 seguridad Brain:** la persistencia es 100% server-side vía `POST /api/exp-iniciativa` con header `x-api-key: $MV_BRAIN_TOKEN`. Si `MV_BRAIN_TOKEN` no está definida, DETENTE y pide al usuario solicitar su token a BizOps (Julio). Sin fallback. El skill nunca escribe directo al datalake ni maneja tokens de servicio.

## Cuándo se activa

- Comando explícito: `/exp-iniciativa`.
- Usuario pega borrador Notion de issue con acciones decididas.
- Usuario escribe brief directo en chat ("quiero un programa de referidos para MX").

## Flujo (8 pasos)

### Paso 0 — Clasificar área + bifurcar dev

```pseudocode
area = clasificar_area(input)
# Heurística:
#  - Keywords explícitas: "Growth"/"Ops"/"Producto"/"Tech"/"Finanzas"/"MKT"/"Reconsumos"/"DK"/"CX"
#  - Owner DRI → área del Excel Mapa de DRIs
#  - 1 pregunta si ambiguo

if area in ['Producto', 'Tech', 'Growth - Producto', 'Growth - Tech']:
  # Bifurcación dev — delega a Carlos's skill
  return invocar('mv-instruction-generator', input, header='# exp-iniciativa-delegation')
  # Carlos's skill corre Fase 0 + 7Qs + La Apuesta + PRD-para-Claude + INSERT con fuente='dev'
```

**Contrato delegación:** ver `producto/estrategia/iniciativa-ai-native-dev/07-bifurcacion-dev-cable.md`.
**Header obligatorio** cuando delega: `# exp-iniciativa-delegation` + JSON con `{area, borrador_notion_id, owner_dri}`.

### Paso 1 — Challenge gate (7 Qs adaptativas, locked SP3)

> **Modo read-only.** No persiste hasta paso 7. Salta Q ya respondida en el brief.

| # | Pregunta | Framework |
|---|----------|-----------|
| 1 | ¿Qué métrica MV real mueve? (CAC, CVR, retención, reconsumo, ticket, churn, NPS) | Outcome |
| 2 | ¿De quién es el dolor + cómo sabemos que existe (dato/ticket/observación)? | Opportunity |
| 3 | Tamaño impacto (+2pp CVR ≈ X pedidos/mes) — ¿justifica vs cola? | RICE-lite |
| 4 | ¿Nuevo o ya existe en otra app/dashboard MV? | Anti-duplicación |
| 5 | Cómo se mide + baseline actual (lo sabemos o sale del datalake) | Measurability |
| 6 | Supuesto más riesgoso + prueba más barata antes | RAT |
| 7 | Usabilidad/Factibilidad (solo si no obvio) | Cagan |

Hard cap: 7. Idea afilada → 2 Qs.

### Paso 2 — Lookup KPI + captura baseline datalake (2 HARD GATES v1.1)

**Hard-gate #1 (nuevo v1.1) — KPI/input identificado obligatorio:**

Toda iniciativa debe vincularse a un KPI existente en `dris_definitions` (145 activos) o definir uno nuevo antes de persist. Sin match válido:

```
if (!kpi_match || score < 0.15) && !kpi_definition_id && !allow_no_kpi:
  → HTTP 400 con top_suggestion + instruccion_a_carlos
```

**Alternativas para superar:**
- `metric_hint` refinado (ej. "margen bruto franquicia" en vez de "márgenes")
- `kpi_definition_id: <id>` explícito del catálogo (ver `/api/dris/lookup`)
- `allow_no_kpi=true` con `rationale` explícito (discouraged — solo si KPI todavía no existe en catálogo)

**Búsqueda extendida (v1.1):** `/api/dris/lookup?q=lima+delivery&search_inputs=true` también busca por `dris_kpi_inputs.cod_short` — útil cuando el query menciona ciudad+operación específica.

**Hard-gate #2 (v1.0) — Baseline del datalake:**



Ambos hard-gates los **aplica el server** dentro de `POST /api/exp-iniciativa`. Para explorar/predecir el match antes de llamar, usar los endpoints de lectura del datalake (mismo header `x-api-key: $MV_BRAIN_TOKEN`):

```javascript
// 1. Match kpi_definition_id en el catálogo (server-side, sin acceso directo a la DB)
const lookup = await fetch(
  `https://data-lake-mv.manzanaverde.la/api/dris/lookup?q=${encodeURIComponent(input.metric_hint)}&search_inputs=true&include_inputs=true`,
  { headers: { 'x-api-key': process.env.MV_BRAIN_TOKEN } }
);
// → candidatos {id, nombre, score, endpoint_north_star, ...}

// 2a. Match con endpoint North Star → leer baseline
const baseline = await fetch(
  `https://data-lake-mv.manzanaverde.la${kpi.endpoint_north_star}?week_id=current`,
  { headers: { 'x-api-key': process.env.MV_BRAIN_TOKEN } }
);

// 2b. Sin endpoint expuesto → el server resuelve baseline vía silver_path
//     dentro de POST /api/exp-iniciativa (no hay query Silver client-side)

// 2c. NO match
// → opción A: pedir al usuario que defina el KPI (luego instrucción a Julio para agregarlo a dris_definitions)
// → opción B: metrica_target text libre + flag kpi_definition_id IS NULL + warning
// → opción C: override --no-metric / allow_no_kpi con justificación 1-línea (se graba en apuesta.rationale)

// 2d. Métrica existe pero NO expuesta en endpoints
// → generar instrucción markdown:
//   notion-cache/_instrucciones-julio/exp-{id}-expose-kpi.md
//   con: silver_path, fórmula, ventana, agregación
// → NO cierra el flujo (excepto override)
```

**Override:** `--no-metric "razón corta"` → permite proceder con `metrica_target` libre.

### Paso 3 — Diseño estadístico

```python
import math
from scipy.stats import norm

def calcular_muestra(baseline_mean, baseline_std, mde_pct, alpha=0.05, power=0.8):
    delta = baseline_mean * (mde_pct / 100)
    z_alpha = norm.ppf(1 - alpha/2)
    z_beta = norm.ppf(power)
    n = 2 * ((z_alpha + z_beta) ** 2) * (baseline_std ** 2) / (delta ** 2)
    return math.ceil(n)
```

Output `diseno_estadistico` (jsonb):
```json
{
  "duracion_dias": 14,
  "mde_pct": 5,
  "muestra_min": 1200,
  "power": 0.8,
  "alpha": 0.05,
  "method": "two_sample_continuous",
  "split_strategy": "50_50_AB"
}
```

Si baseline_std no disponible → estimar como `0.3 * baseline_mean` + warning.

### Paso 4 — Construir "La Apuesta" (artefacto SP3)

```
Creemos que <cambio> hará que <kpi_nombre> de <segmento PE/MX/CO|ops|growth>
pase de <baseline_valor> a <target_mde> para <fecha_evaluacion>.
Supuesto riesgoso: <X>. Prueba más barata antes de construir: <Y>.
Tipo: ▸ BET customer-facing  ▸ BET interno  ▸ BUG (n/a)
[Rationale (si veredicto 🟥): <por qué lo hacemos igual>]
```

Guarda en col `apuesta` (text).

### Paso 5 — Co-llama a `crear-cr` (si aplica)

Si hay tareas clave en `acciones`, invocar `crear-cr` (que publica vía `POST /api/crear-cr`). **Pasar SIEMPRE `exp_id`**: el server auto-vincula `experiments.link_cr` con el permalink del thread/Notion (solo si `link_cr` estaba vacío — Fase 4.2). Ya no hace falta PATCHear `link_cr` desde el cliente; solo verificar que quedó seteado.

```javascript
const cr_result = await invokeSkill('crear-cr', {
  acciones: experiment.acciones,            // string numerado — crear-cr lo splitea a acciones_array
  area: experiment.area,
  tipo: 'iniciativa',
  owner_dri: experiment.owner_dri,
  exp_id: experiment.id,                    // → auto-link server-side de experiments.link_cr
  issue_page_id: experiment.notion_id,      // relation al Issue paraguas
  kpi_numbers: [experiment.kpi_definition_id],
  deadline: experiment.fecha_evaluacion,
});
// experiment.link_cr lo llena el server (verificar en la respuesta / GET /api/experiments/:id)
```

### Paso 6 — Veredicto soft-gate

| Veredicto | Condición | Acción |
|-----------|-----------|--------|
| ✅ Apuesta clara | baseline + supuesto probable + diseño OK | Procede a INSERT (paso 7) |
| ⚠️ Difusa | sin métrica o supuesto no probado | Propone *prueba barata PRIMERO* antes de construir todo. Deja proceder |
| 🟥 Sin métrica + sin estratégico | No mueve nada + no es estratégico | Muestra **costo oportunidad** + pide UNA línea "por qué lo hacemos igual". Se graba en `apuesta` como rationale |

Nunca bloqueo duro — soft-gate.

### Paso 7 — Persistir vía `POST /api/exp-iniciativa` (server-side)

El INSERT en `experiments` + la creación del Issue Notion los hace el **server**. El skill arma el brief y hace UNA llamada (ver sección "Persistencia — endpoint" abajo). No hay SQL ni escritura directa client-side.

**ID generation (server-side):** `exp-{YYYY}-{secuencial-3-digit}` — max+1 filtrando el formato canónico `^exp-YYYY-NNN$` (evita colisión con variants).

**`fuente`:**
- `'manual'` — BET cross-area normal (este skill, no dev)
- `'dev'` — viene de bifurcación a `mv-instruction-generator`
- `'hermes'` — si hay `hermes_proposal_id` (link a propuesta Hermes existente)

**`estado` inicial:** `'Propuesta'` → pasa a `'En curso'` al kickoff (UPDATE manual del owner).

### Paso 8 — Reportar

```markdown
## 🧪 Experimento creado

**ID:** exp-2026-{NNN}
**Nombre:** {nombre}
**Área:** {area} · **Owner:** {owner_dri}
**Estado:** Propuesta

### 🎯 La Apuesta
{apuesta_text}

### 📊 Métricas
- KPI: {kpi_nombre} (id: {kpi_definition_id})
- Baseline: {baseline_valor} ({baseline_fecha})
- Target: {target_mde}
- Diseño: {duracion_dias}d · MDE {mde_pct}% · n_min {muestra_min}

### 🔗 Enlaces
- [Notion borrador]({notion_url})
- [CR Discord]({link_cr})
- Snapshot brain: `notion-cache/_datalake/_data/experiments.md` (próximo sync)

### 📅 Próximo paso
- Ejecutar acciones (owner: {owner_dri})
- **{fecha_evaluacion}** → correr `/informe-resultados exp-2026-{NNN}` para cierre
```

---

## Persistencia — endpoint (ÚNICO camino)

> ⚠️ **Auth:** header `x-api-key: $MV_BRAIN_TOKEN`. Si `MV_BRAIN_TOKEN` no está definida, DETENTE y pide al usuario solicitar su token a BizOps (Julio). Sin fallback. La escritura directa al datalake desde el cliente (camino con token de servicio, versiones ≤v1.3.0) fue **eliminada** — Fase 3 seguridad Brain.

```javascript
const resp = await fetch('https://data-lake-mv.manzanaverde.la/api/exp-iniciativa', {
  method: 'POST',
  headers: { 'x-api-key': process.env.MV_BRAIN_TOKEN, 'Content-Type': 'application/json' },
  body: JSON.stringify({
    brief: '…',                       // ✅ REQUERIDO — texto estructurado de la iniciativa
    owner_dri: 'Julio Mori',          // ✅ REQUERIDO
    paises: ['PE', 'MX'],             // array (default ['PE'])
    kpi_definition_id: 27,            // opcional — salta el hard-gate de KPI (id del catálogo)
    allow_no_kpi: false,              // discouraged — exige rationale
    skip_issue: false,                // true → no crea el Issue Notion
    notion_issue_id: null,            // vincular Issue existente (Caso B)
    source_notion_url: null,          // ingesta: página Notion cruda → enriquece el brief
  }),
});
// El server: hard-gates KPI/baseline → INSERT experiments (id exp-YYYY-NNN)
// → crea/vincula Issue en Issue Inventory (202fb2dd) → responde {id, kpi, baseline, issue, ingested_source, next_steps}
```

---

## Schema target (30 cols — resumen mínimos obligatorios)

| Col | Tipo | Obligatorio | Origen |
|-----|------|-------------|--------|
| `id` | varchar | ✅ | Auto `exp-{YYYY}-{NNN}` |
| `nombre` | text | ✅ | User |
| `apuesta` | text | ✅ | Paso 4 |
| `owner_dri` | text | ✅ | User (validar contra Mapa de DRIs) |
| `area` | text | ✅ | Paso 0 |
| `tipo` | text | ⚠️ | BET customer-facing / BET interno / BUG |
| `kpi_definition_id` | int FK | recomendado | Paso 2 (dris_definitions) |
| `metrica_target` | text | fallback si no kpi_definition_id | User |
| `paises` | text[] | opcional | Default ['PE'] |
| `acciones` | text | recomendado | User |
| `diseno_estadistico` | jsonb | ✅ excepto BUG | Paso 3 |
| `baseline_valor` | numeric | ✅ excepto --no-metric | Paso 2 |
| `baseline_fecha` | date | ✅ | now() |
| `target_mde` | numeric | recomendado | Paso 3 |
| `fecha_launch` | date | ✅ | User o today |
| `fecha_evaluacion` | date | ✅ | fecha_launch + duracion_dias |
| `estado` | text | ✅ | 'Propuesta' inicial |
| `fuente` | text | ✅ | 'manual' default |
| `link_cr` | text | opcional | Paso 5 |
| `notion_id` | text | opcional | URL Notion borrador |
| `hermes_proposal_id` | varchar | opcional | Si vincula a Hermes |
| `link_pr` | text | rellena después | Cuando exista PR |

Schema completo: `producto/estrategia/iniciativa-ai-native-dev/02-experiments-schema.md`.

---

## Edge cases

| Caso | Comportamiento |
|------|----------------|
| Área = Producto/Tech | **Bifurcación dev** → `mv-instruction-generator` v1.8.0 + plugin mv-dev → PRD-para-Claude → INSERT `fuente='dev'` |
| Métrica no en datalake | Genera instrucción markdown a Julio en `notion-cache/_instrucciones-julio/` + NO cierra (excepto `--no-metric`) |
| Experimento overlap con Hermes | Detecta por área + mercado → pregunta si vincular (`hermes_proposal_id`) o crear nuevo |
| Iniciativa duplicada (mismo nombre+área <30d) | Warning + opción reusar fila existente (SELECT previo) |
| BUG no BET | Skip challenge → INSERT directo `tipo='BUG'`, sin diseño estadístico |
| Usuario cancela mid-flow | Guarda `estado='Propuesta'` + flag `incompleto=true` |
| Baseline muy pequeño (n < umbral significancia) | Recomienda extender duración + recalcula muestra_min |
| Override `--no-metric` | Pide justificación 1-línea, guarda en `apuesta.rationale`, INSERT con flag |

---

## Inputs requeridos

| Input | Fuente |
|-------|--------|
| Borrador (texto o URL Notion) | Pegado por usuario, `notion-fetch`, o param `source_notion_url` (ingesta server-side) |
| Auth endpoints Brain | Env `MV_BRAIN_TOKEN` (header `x-api-key`). Si no está definida, DETENTE y pide al usuario solicitar su token a BizOps (Julio). Sin fallback |
| Catálogo KPI | `GET /api/dris/lookup` (server-side sobre `dris_definitions`) |
| Baseline | Endpoints North Star (`data-lake-mv.manzanaverde.la`) o resolución server-side vía `silver_path` |

## Outputs

| Output | Destino |
|--------|---------|
| Fila INSERT | `experiments` Supabase |
| CRs | Discord canal área + Notion tasks (via skill `crear-cr`) |
| Instrucción para Julio (si falta métrica) | `notion-cache/_instrucciones-julio/exp-{id}.md` |
| Mensaje de éxito | Chat al usuario + Discord canal área |
| Trigger informe | Cron Supabase / agenda mental: en `fecha_evaluacion` → invocar `/informe-resultados` |

---

## Testing (15 + 5 escenarios)

Reusa batería SP3 (E1-E15) + 5 nuevos del Sprint:

| # | Escenario | Esperado |
|---|-----------|----------|
| E16 | Iniciativa Growth sin baseline en datalake | Genera instrucción Julio + bloquea cierre |
| E17 | Iniciativa Reconsumos con KPI 117 (visibilidad) | Match en dris_definitions → baseline auto + INSERT |
| E18 | Iniciativa Producto/Tech | Bifurca a `mv-instruction-generator` + INSERT `fuente='dev'` |
| E19 | Iniciativa duplicada (mismo nombre+área <30d) | Warning + opción reusar fila existente |
| E20 | Sample size insuficiente | Recomienda extender duración + recalcula muestra_min |

---

## Vinculación con otros skills

```
exp-iniciativa
  ├── Paso 0 → bifurca a mv-instruction-generator (Carlos) si dev
  ├── Paso 5 → invoca crear-cr (CRs Discord + Notion tasks)
  └── Paso 8 → calendariza informe-resultados en fecha_evaluacion
```

| Skill | Cuándo se llama | Qué devuelve |
|-------|----------------|--------------|
| `mv-instruction-generator` | Paso 0 si area ∈ dev | PRD + INSERT propio con `fuente='dev'` |
| `crear-cr` | Paso 5 si hay acciones | `discord_permalink` + `notion_task_url` |
| `informe-resultados` | En `fecha_evaluacion` (cron o manual) | UPDATE row + informe markdown |

---

## Dependencias

- ✅ Tabla `experiments` (migration 011 aplicada 2026-06-29).
- ✅ Vista `experiments_with_kpi` (LEFT JOIN dris_definitions).
- ✅ `mv-instruction-generator` v1.8.0 (Carlos, en piloto 2 semanas).
- ✅ Endpoint `POST /api/exp-iniciativa` deployado en `data-lake-mv` (persistencia + Issue server-side, auth `x-api-key`).
- ⬜ Skill `crear-cr` (mismo build, paralelo).
- ⬜ Cron Supabase trigger para `informe-resultados` auto en `fecha_evaluacion`.
- ⚠️ Endpoints North Star parciales — `frequency`, `funnel-cvr`, `new-subscribers v2` pendientes.

---

## Stub Python (mínimo viable — solo endpoints Brain)

```python
import os, sys, requests

DATALAKE = "https://data-lake-mv.manzanaverde.la"
TOKEN = os.environ.get("MV_BRAIN_TOKEN")
if not TOKEN:
    sys.exit("MV_BRAIN_TOKEN no definida. DETENTE y pide al usuario solicitar su token a BizOps (Julio). Sin fallback.")
HEADERS = {"x-api-key": TOKEN, "Content-Type": "application/json"}

def exp_iniciativa_skill(brief, owner_dri, paises=None, kpi_definition_id=None,
                         skip_issue=False, notion_issue_id=None, source_notion_url=None):
    # 1-6. Clasificación de área, challenge gate, apuesta y diseño estadístico
    #      son razonamiento del skill (client-side, sin escrituras).
    #      Los hard-gates KPI/baseline + INSERT + Issue Notion los aplica el server.
    body = {"brief": brief, "owner_dri": owner_dri}
    if paises: body["paises"] = paises
    if kpi_definition_id: body["kpi_definition_id"] = kpi_definition_id   # salta hard-gate
    if skip_issue: body["skip_issue"] = True
    if notion_issue_id: body["notion_issue_id"] = notion_issue_id
    if source_notion_url: body["source_notion_url"] = source_notion_url  # ingesta cruda

    r = requests.post(f"{DATALAKE}/api/exp-iniciativa", headers=HEADERS, json=body, timeout=30)
    r.raise_for_status()
    exp = r.json()   # {id, kpi, baseline, issue, ingested_source, next_steps, ...}

    # Co-llama crear-cr (si hay acciones) — pasar exp_id: el server auto-vincula
    # experiments.link_cr con el permalink (solo si estaba vacío). Sin PATCH client-side.
    return exp
```

---

## Métrica de éxito v1.0.0

- **100%** experimentos creados via skill tienen `baseline_valor IS NOT NULL` (excepto override).
- **100%** tienen `diseno_estadistico IS NOT NULL` (excepto tipo=BUG).
- **`fuente`** distribuido entre áreas (no solo Growth).
- **≥80%** iniciativas junio-jul 2026 registradas via skill al 31-jul (target Sprint).
- **0** experimentos huérfanos (sin `fecha_evaluacion` o sin owner).

---

## Modelo Issue ↔ Experimento (v1.2 — Carlos 2026-07-17)

Cada experimento tiene un **Issue en Notion (plantilla issue)** como interfaz visual, vinculado al datalake:

```
exp-iniciativa
  ├── Caso A (desde cero): crea Issue nuevo (DB "Issue Inventory" `202fb2dd`) con estructura canónica
  │     Issue Name = [exp-2026-NNN] Nombre · header "🧪 experiments/exp-2026-NNN"
  │     + INSERT experiments + guarda notion_id (URL issue) ↔ vínculo bidireccional
  │
  └── Caso B (issue existente sin experimento): pasar `notion_issue_id`
        → lee el issue, lo estructura, genera exp_id + nombre, INSERT experiments,
          actualiza el issue con la estructura canónica (header exp_id)
```

**Estructura canónica del Issue** (ajustada para sincronizar con datalake — NO romper):
- `Issue Name`: `[exp_id] nombre`
- `Issue Description`: header `🧪 experiments/exp_id` + Apuesta + Acciones
- `Nombre KPIs` / `Meta KPIs`: KPI verbatim / target
- `Fecha ejecucion`: fecha_evaluacion · `Status`: estado · `Decision Type`: tipo

**Tareas/CRs de la iniciativa** → se vinculan a ESE Issue (via `crear-cr` con `exp_id`). **CR libre** (sin iniciativa) → task suelta sin issue paraguas.

**Editar después:** `editar-experimento` modifica el Issue en base a comentarios/acta sin romper la estructura + sincroniza datalake + Discord.

Params: `notion_issue_id` (vincular existente) · `skip_issue=true` (omitir creación issue).

### Creación del Issue — server-side (2026-07-18 — token válido)

El token **"Token Brain"** de Notion tiene **RW total en workspace "Manzana Verde"** (create+update+archive verificado) con acceso a Issue Inventory (`202fb2dd`) + Tasks (`95684528`). Vive **solo en Vercel (data-lake-mv)** — el endpoint crea el Issue server-side.

**Flujo primario (endpoint, sirve también para cron sin humano):**
1. `POST /api/exp-iniciativa` → INSERT experiment en datalake (fuente) + crea Issue en Issue Inventory (`202fb2dd`) server-side + guarda `notion_id` (page id) bidireccional.
2. Si el server devuelve `issue.ok=false` → **reportar al usuario y NO completar el Issue con tokens de cliente** (Fase 3: sin escrituras client-side). El reintento es server-side.

**Campos del Issue (Issue Inventory, `status` type para Status):**
`Issue Name` (title) · `Issue Description` (rich_text) · `Nombre KPIs`/`Meta KPIs` (rich_text) · `Fecha ejecucion` (date) · `Decision Type` (select) · `Decision Maker` (people) · `Status` (status).

## v2 (Carlos 2026-07-21) — RAG por KPI + ingesta cruda

**Paso 0 (RAG por KPI):** antes de crear, el agente recupera contexto del brain ligado al KPI —
consulta `/kpi-context?id=<kpi>` (o `kpi-context` skill) para traer definición, inputs con valores
reales, experiments previos que mueven ese KPI y su medición histórica. Evita duplicar y da baseline.

**Ingesta no-estructurado → estructurado:** param `source_notion_url` — pásale un link de una página
Notion **manual (cruda)** y el endpoint lee su texto para enriquecer el brief (clasificación de área +
detección de métrica). El agente **estructura**; la fuente cruda solo aporta contexto. La respuesta
incluye `ingested_source`. Ejemplo:

```bash
POST /api/exp-iniciativa
{ "brief":"...", "owner_dri":"...", "source_notion_url":"https://www.notion.so/<pagina-manual>" }
```

Marco: Company Brain v2 (4 capas). Ver Notion "🏛️ Arquitectura v2 — 4 capas (Carlos)".

## Changelog

- **v1.4.0 (2026-08-07): publicación migrada a server-side (Fase 3 seguridad Brain) — sin tokens de servicio en cliente.** Eliminada la rama de escritura directa al datalake (REST con token de servicio) y el fallback de completar el Issue con token de sesión. Único camino: `POST /api/exp-iniciativa` (`brief`+`owner_dri` requeridos, `paises` array, `kpi_definition_id` salta hard-gate, `skip_issue`, `notion_issue_id`, `source_notion_url`) con `x-api-key: $MV_BRAIN_TOKEN`. Lookup KPI vía `GET /api/dris/lookup`. Paso 5: pasar `exp_id` a `crear-cr` → el server auto-vincula `experiments.link_cr` (Fase 4.2).
- **v1.3.0 (2026-07-21)** — Carlos v2: Paso 0 RAG por KPI (consulta kpi-context al arrancar) + ingesta cruda `source_notion_url` (lee página Notion manual → enriquece brief). Respuesta agrega `ingested_source`.
- **v1.2.1 (2026-07-18)** — Token "Token Brain" válido (RW workspace Manzana Verde) reemplaza workaround MCP OAuth. Issue DB = "Issue Inventory" `202fb2dd`. Endpoint crea Issue server-side (requiere NOTION_TOKEN en Vercel).
- **v1.2.0 (2026-07-17)** — Modelo Issue↔Experimento (Carlos v2). Crea/vincula Issue Notion (plantilla) con estructura canónica + exp_id embebido. notion_id bidireccional. Params notion_issue_id + skip_issue.
- **v1.1.0 (2026-07-11)** — Hard-gate KPI/input auto-link (regla arquitectural Julio)
  - **HARD-GATE:** si no encuentra KPI con score ≥0.15 y no viene `kpi_definition_id` explícito ni `allow_no_kpi=true` → HTTP 400 con instrucción específica
  - Nuevo param `kpi_definition_id` (override directo del catálogo, valida contra `dris_definitions`)
  - Cargar inputs del KPI matched automático desde `dris_kpi_inputs` (top 50)
  - INSERT row: `input_north_star` agrega top 20 `cod_short` pipe-separated para contexto medición granular
  - Response: nuevo campo `kpi_inputs[]` con desagregación completa (ciudad, source, unidad)
  - `next_steps` sugiere pasar `kpi_numbers=[id]` a `crear-cr` para propagación
  - Endpoint `/api/dris/lookup` extendido con `search_inputs=true` (busca por `cod_short`) e `include_inputs=true`
  - Threshold mínimo score=0.15 evita bypass hard-gate con matches falsos de baja relevancia

- **v1.0.0 (2026-06-30)** — Build inicial post-skeleton
  - 8 pasos completos del flujo
  - Bifurcación dev a `mv-instruction-generator` v1.8.0
  - Hard-gate datalake con override `--no-metric`
  - Diseño estadístico con cálculo `muestra_min`
  - Stub Python listo
  - 20 stress tests (15 SP3 + 5 Sprint)

---

**FIN.** Para preguntas de implementación, ver specs en `producto/estrategia/iniciativa-ai-native-dev/03-skill-exp-iniciativa.md`.
