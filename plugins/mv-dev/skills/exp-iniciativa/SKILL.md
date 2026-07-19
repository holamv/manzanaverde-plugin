---
name: exp-iniciativa
description: |
  Crea iniciativa/experimento estructurado, captura baseline del datalake, propone diseño estadístico,
  y lo persiste en la tabla `experiments` de Supabase (proyecto `hzpycmczwkwbfrqzvfyz`).
  Genérico cross-area (Operaciones / Producto / Growth / Finanzas / MKT / Reconsumos / DK / CX).
  Bifurca a `mv-instruction-generator` v1.8.0 (Carlos) si area ∈ {Producto, Tech, Growth-Producto, Growth-Tech}.
  Co-llama a `crear-cr` para tareas clave. Cierra el ciclo con `informe-resultados` en fecha_evaluacion.
trigger_phrases:
  - "/exp-iniciativa"
  - "crear iniciativa"
  - "nuevo experimento"
  - "registrar BET"
  - "crear apuesta"
version: 1.2.1
owner: Julio Mori
based_on:
  - producto/estrategia/iniciativa-ai-native-dev/03-skill-exp-iniciativa.md
  - SP3 challenge gate (15/15 stress tests)
  - mv-instruction-generator v1.8.0 (Fase 0 + Sprint additions)
---

# Skill `exp-iniciativa` v1.0.0

> Skill genérico cross-area del Sprint Company Brain. Reemplaza el flujo "crear issue manual en Notion" con un flujo que **estructura + mide + persiste** en `experiments`. Vincula con `crear-cr` (Discord/tasks) e `informe-resultados` (cierre línea de datos).

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



```javascript
// 1. Match kpi_definition_id en dris_definitions
const kpi = await sb.from('dris_definitions')
  .select('id, nombre, silver_path, endpoint_north_star')
  .or(`nombre.ilike.%${input.metric_name}%,nombre.ilike.%${input.area}%`)
  .limit(5);

// 2a. Match → leer baseline
if (kpi && kpi.endpoint_north_star) {
  const baseline = await fetch(`https://data-lake-mv.manzanaverde.la${kpi.endpoint_north_star}?week_id=current`);
  return baseline.value;
}

// 2b. Sin endpoint → query Silver via silver_path
if (kpi && kpi.silver_path) {
  return await sb.rpc('exec_silver_query', { path: kpi.silver_path, week: 'current' });
}

// 2c. NO match
// → opción A: pedir al usuario que defina el KPI (luego instrucción a Julio para agregarlo a dris_definitions)
// → opción B: metrica_target text libre + flag kpi_definition_id IS NULL + warning
// → opción C: override --no-metric con justificación 1-línea (se graba en apuesta.rationale)

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

Si hay tareas clave en `acciones`:

```javascript
const cr_result = await invokeSkill('crear-cr', {
  contexto: experiment.acciones,
  area: experiment.area,
  owner_dri: experiment.owner_dri,
  exp_id: experiment.id,
  kpi: experiment.kpi_definition_id,
  baseline: experiment.baseline_valor,
  target: experiment.target_mde,
  fecha_evaluacion: experiment.fecha_evaluacion,
});

experiment.link_cr = cr_result.discord_permalink;
```

### Paso 6 — Veredicto soft-gate

| Veredicto | Condición | Acción |
|-----------|-----------|--------|
| ✅ Apuesta clara | baseline + supuesto probable + diseño OK | Procede a INSERT (paso 7) |
| ⚠️ Difusa | sin métrica o supuesto no probado | Propone *prueba barata PRIMERO* antes de construir todo. Deja proceder |
| 🟥 Sin métrica + sin estratégico | No mueve nada + no es estratégico | Muestra **costo oportunidad** + pide UNA línea "por qué lo hacemos igual". Se graba en `apuesta` como rationale |

Nunca bloqueo duro — soft-gate.

### Paso 7 — INSERT en `experiments`

```sql
INSERT INTO experiments (
  id, nombre, apuesta, owner_dri, tipo, input_north_star,
  area, kpi_definition_id, metrica_target, paises,
  acciones, diseno_estadistico,
  baseline_valor, baseline_fecha, target_mde,
  fecha_launch, fecha_evaluacion, estado, fuente,
  link_cr, notion_id, hermes_proposal_id
) VALUES (
  $1, $2, $3, $4, $5, $6,
  $7, $8, $9, $10,
  $11, $12::jsonb,
  $13, $14, $15,
  $16, $17, 'Propuesta', $18,
  $19, $20, $21
) RETURNING id;
```

**ID generation:** `exp-{YYYY}-{secuencial-3-digit}` → consultar `SELECT MAX(id) FROM experiments WHERE id LIKE 'exp-2026-%'` y +1.

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

## Persistencia — endpoint

**Mientras Edge Function no exista** (sprint pendiente):

```javascript
// Via REST con service_role (env var SUPABASE_SERVICE_ROLE_KEY)
const SUPABASE_URL = 'https://hzpycmczwkwbfrqzvfyz.supabase.co';
const headers = {
  'apikey': process.env.SUPABASE_SERVICE_ROLE_KEY,
  'Authorization': `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
  'Content-Type': 'application/json',
  'Prefer': 'return=representation'
};

const row = await fetch(`${SUPABASE_URL}/rest/v1/experiments`, {
  method: 'POST',
  headers,
  body: JSON.stringify(experimentRow)
});
```

**Cuando Edge Function exista** (Julio's build target ~04-jul):

```javascript
const row = await fetch('https://data-lake-mv.manzanaverde.la/api/experiments', {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${INTERNAL_TOKEN}`, 'Content-Type': 'application/json' },
  body: JSON.stringify(experimentRow)
});
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
| Borrador (texto o URL Notion) | Pegado por usuario o `notion-fetch` con URL |
| Acceso datalake | `SUPABASE_SERVICE_ROLE_KEY` |
| Catálogo KPI | Query a `dris_definitions` (cached 1h) |
| Baseline | Endpoints North Star (`data-lake-mv.manzanaverde.la`) o query Silver |

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
- ⬜ Edge Function `/api/experiments` (Julio, target 04-jul).
- ⬜ Skill `crear-cr` (mismo build, paralelo).
- ⬜ Cron Supabase trigger para `informe-resultados` auto en `fecha_evaluacion`.
- ⚠️ Endpoints North Star parciales — `frequency`, `funnel-cvr`, `new-subscribers v2` pendientes.

---

## Stub Python (día 1, mínimo viable)

```python
import os, datetime, requests, json
from supabase import create_client

SUPABASE_URL = "https://hzpycmczwkwbfrqzvfyz.supabase.co"
sb = create_client(SUPABASE_URL, os.environ["SUPABASE_SERVICE_ROLE_KEY"])

def exp_iniciativa_skill(input_text, notion_borrador_id=None):
    # 1. Clasificar área
    area = classify_area(input_text)

    # 2. Bifurcar dev
    if area in ("Producto", "Tech", "Growth - Producto", "Growth - Tech"):
        return delegate_to_mv_instruction_generator(input_text, area, notion_borrador_id)

    # 3. Challenge minimal (3 Qs core)
    apuesta_data = build_apuesta_from_qa(input_text)

    # 4. Baseline datalake
    baseline = fetch_north_star_baseline(area, apuesta_data["metric"]) or prompt_user_for_baseline()

    # 5. Diseño estadístico
    diseno = calcular_muestra(baseline, mde_pct=5, alpha=0.05, power=0.8)

    # 6. Generar ID
    last = sb.table("experiments").select("id").like("id", "exp-2026-%").order("id", desc=True).limit(1).execute()
    seq = int(last.data[0]["id"].split("-")[-1]) + 1 if last.data else 1
    exp_id = f"exp-2026-{seq:03d}"

    # 7. INSERT
    row = sb.table("experiments").insert({
        "id": exp_id,
        "nombre": apuesta_data["nombre"],
        "apuesta": apuesta_data["apuesta_text"],
        "owner_dri": apuesta_data["owner"],
        "area": area,
        "kpi_definition_id": apuesta_data.get("kpi_id"),
        "baseline_valor": baseline,
        "baseline_fecha": datetime.date.today().isoformat(),
        "target_mde": apuesta_data.get("target"),
        "diseno_estadistico": diseno,
        "acciones": apuesta_data.get("acciones"),
        "fuente": "manual",
        "estado": "Propuesta",
        "fecha_launch": datetime.date.today().isoformat(),
        "fecha_evaluacion": (datetime.date.today() + datetime.timedelta(days=diseno["duracion_dias"])).isoformat(),
        "notion_id": notion_borrador_id,
    }).execute()

    # 8. Co-llama crear-cr (si aplica)
    if apuesta_data.get("acciones"):
        cr = invoke_skill("crear-cr", {"contexto": apuesta_data["acciones"], "exp_id": exp_id, "area": area})
        sb.table("experiments").update({"link_cr": cr["permalink"]}).eq("id", exp_id).execute()

    return {"id": exp_id, "link": f"experiments/{exp_id}", "next": "informe-resultados en " + (datetime.date.today() + datetime.timedelta(days=diseno["duracion_dias"])).isoformat()}
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

### Creación del Issue via NOTION_TOKEN (2026-07-18 — token válido)

El token **"Token Brain"** (`NOTION_TOKEN`) tiene **RW total en workspace "Manzana Verde"** (create+update+archive verificado) con acceso a Issue Inventory (`202fb2dd`) + Tasks (`95684528`). El endpoint crea el Issue server-side.

**Flujo primario (endpoint, sirve también para cron sin humano):**
1. `POST /api/exp-iniciativa` → INSERT experiment en datalake (fuente) + crea Issue en Issue Inventory (`202fb2dd`) vía `NOTION_TOKEN` + guarda `notion_id` (page id) bidireccional.
2. Requiere `NOTION_TOKEN` seteado en Vercel (data-lake-mv) = token "Token Brain". Mientras no esté en Vercel, el endpoint devuelve `issue.ok=false` y el skill completa el Issue con el token de la sesión.

**Campos del Issue (Issue Inventory, `status` type para Status):**
`Issue Name` (title) · `Issue Description` (rich_text) · `Nombre KPIs`/`Meta KPIs` (rich_text) · `Fecha ejecucion` (date) · `Decision Type` (select) · `Decision Maker` (people) · `Status` (status).

## Changelog

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
