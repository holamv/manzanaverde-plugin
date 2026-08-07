---
name: informe-resultados
description: |
  Cierra la línea de datos de un experimento. En la fecha de evaluación, lee resultado del datalake,
  calcula impacto + significancia (t-test/z-test según diseño), genera informe markdown,
  publica a Discord + Notion + repo cache, y UPDATE en `experiments` con `estado='Medido'`.
  Medición + UPDATE + publicación corren server-side vía `POST /api/informe-resultados`
  (auth `x-api-key: $MV_BRAIN_TOKEN`) — sin tokens de servicio en cliente.
  Auto-trigger vía cron server-side o invocación manual `/informe-resultados exp-2026-NNN`.
trigger_phrases:
  - "/informe-resultados"
  - "informe experimento"
  - "cerrar experimento"
  - "resultado de exp-"
version: 1.1.0
owner: Julio Mori
based_on:
  - producto/estrategia/iniciativa-ai-native-dev/05-skill-informe-resultados.md
---

# Skill `informe-resultados` v1.1.0

> Skill del Sprint Company Brain que cierra el loop del experimento creado por `exp-iniciativa`. Es la parte que vuelve "iniciativa con apuesta" en **aprendizaje compartido** para el Company Brain.

## Ejecución — `POST /api/informe-resultados` (ÚNICO camino)

> ⚠️ **Auth:** header `x-api-key: $MV_BRAIN_TOKEN`. Si `MV_BRAIN_TOKEN` no está definida, DETENTE y pide al usuario solicitar su token a BizOps (Julio). Sin fallback. Los caminos de escritura directa al datalake con token de servicio (≤v1.0.0) fueron **eliminados** — Fase 3 seguridad Brain.

```bash
POST https://data-lake-mv.manzanaverde.la/api/informe-resultados
Headers: x-api-key: $MV_BRAIN_TOKEN · Content-Type: application/json
Body: {
  "exp_id": "exp-2026-014",       # ✅ REQUERIDO — el param se llama exp_id, NO id
  "resultado_override": "…",      # opcional — veredicto/resultado manual (flag --veredicto)
  "force_remedir": true           # opcional — re-corre aunque estado='Medido' (flag --remedicion)
}
```

El server ejecuta los 6 pasos de abajo (medición → test estadístico → veredicto → UPDATE `experiments` → publicación a los 3 destinos) y devuelve `{id, veredicto, impacto_pct, informe_md, ...}`. Los pasos del "Flujo" documentan **lo que hace el server** — el skill solo arma la llamada, interpreta la respuesta y presenta el informe.

## Cuándo se activa

- **Manual:** `/informe-resultados exp-2026-014`.
- **Auto (cron server-side):** detecta experimentos con `fecha_evaluacion <= today() AND estado IN ('En curso', 'Propuesta')` → dispara cada 12h (infra del datalake, sin credenciales en cliente).
- **Re-medir:** usuario pasa `--remedicion` → `force_remedir: true` re-corre aunque `estado='Medido'`.

## Flujo (6 pasos)

### Paso 1 — Recuperar experimento

```sql
SELECT
  id, nombre, apuesta, owner_dri, area, tipo,
  kpi_definition_id, metrica_target, baseline_valor, baseline_fecha,
  fecha_launch, fecha_evaluacion, target_mde, diseno_estadistico,
  estado, fuente, link_cr, link_pr, notion_id, hermes_proposal_id,
  -- JOIN dris_definitions via experiments_with_kpi
  kpi_nombre, silver_path, endpoint_north_star
FROM experiments_with_kpi
WHERE id = $1;
```

**Validaciones:**
- `estado IN ('En curso', 'Propuesta')` → OK, continuar.
- `estado='Medido'` → confirmar re-medir con usuario (a menos que `--remedicion`).
- `baseline_valor IS NULL` → ABORT con mensaje "experimento sin baseline, no se puede medir impacto".
- `kpi_definition_id IS NULL AND metrica_target IS NULL` → ABORT idem.

### Paso 2 — Leer resultado actual desde datalake

**Opción A: endpoint North Star (preferido si KPI expuesto):**

```javascript
const baseline_week = isoweek(experiment.fecha_launch);
const eval_week = isoweek(experiment.fecha_evaluacion);

const resp = await fetch(
  `https://data-lake-mv.manzanaverde.la/api/public/datalake/north-star/${experiment.endpoint_north_star}?from_week=${baseline_week}&to_week=${eval_week}`
);
const data = await resp.json();
// { weekly: [{week_id, value, n}, ...], avg: 0.234, latest: 0.245 }

const resultado_valor = data.latest;
const n_actual = data.weekly.reduce((sum, w) => sum + (w.n || 0), 0);
```

**Opción B: query Silver directo (si solo `silver_path` disponible):**

```sql
SELECT AVG(valor) AS resultado, SUM(n) AS n_actual
FROM <silver_path>
WHERE semana_id BETWEEN $launch_week AND $eval_week;
```

**Opción C: Hermes link** (si `hermes_proposal_id IS NOT NULL`):

```sql
SELECT roas, cpa, conversion_rate, n
FROM hermes_campaign_metrics
WHERE proposal_id = $hermes_id;
```

### Paso 3 — Test estadístico

```python
from scipy import stats
import numpy as np

def evaluar(experiment, resultado_data):
    diseno = experiment["diseno_estadistico"]
    method = diseno.get("method", "two_sample_continuous")
    n_actual = resultado_data["n"]
    n_min = diseno.get("muestra_min", 30)
    alpha = diseno.get("alpha", 0.05)

    # Hard check: ¿tenemos n suficiente?
    if n_actual < n_min:
        return {
            "significativo": False,
            "p_value": None,
            "reason": f"n={n_actual} < muestra_min={n_min}",
            "extend": True,
            "recomendacion_extender_dias": estimate_extension_days(experiment, n_actual, n_min),
        }

    # A/B continuo
    if method == "two_sample_continuous":
        t_stat, p_val = stats.ttest_ind(resultado_data["carril_a"], resultado_data["carril_b"])
        ci_lo, ci_hi = stats.t.interval(
            1 - alpha,
            len(resultado_data["carril_b"]) - 1,
            loc=np.mean(resultado_data["carril_b"]),
            scale=stats.sem(resultado_data["carril_b"]),
        )
        return {
            "p_value": p_val,
            "t_stat": t_stat,
            "significativo": p_val < alpha,
            "ci_95": [ci_lo, ci_hi],
            "n_actual": n_actual,
        }

    # Proporción (z-test)
    if method == "two_sample_proportion":
        # statsmodels.proportions_ztest
        from statsmodels.stats.proportion import proportions_ztest
        counts = [resultado_data["success_a"], resultado_data["success_b"]]
        nobs = [resultado_data["n_a"], resultado_data["n_b"]]
        z_stat, p_val = proportions_ztest(counts, nobs)
        return {"p_value": p_val, "z_stat": z_stat, "significativo": p_val < alpha, "n_actual": n_actual}

    # Pre/post o observacional → comparación simple vs baseline
    if method in ("pre_post", "observational"):
        delta = resultado_data["mean"] - experiment["baseline_valor"]
        std = resultado_data["std"]
        z = delta / (std / np.sqrt(n_actual))
        p_val = 2 * (1 - stats.norm.cdf(abs(z)))
        return {"p_value": p_val, "z_stat": z, "significativo": p_val < alpha, "n_actual": n_actual}

    raise ValueError(f"Method desconocido: {method}")
```

### Paso 4 — Veredicto + insight

```python
def veredicto(impacto_pct, test_result, target_mde_pct, hard_limit_pct=200):
    # Sanity check
    if abs(impacto_pct) > hard_limit_pct:
        return ("⚠️ Sanity check", f"Impacto {impacto_pct:.1f}% fuera de rango esperado. Revisar antes de cerrar.")

    # Sin significancia
    if not test_result["significativo"]:
        if test_result.get("extend"):
            return ("⏸️ Extender", f"n={test_result['n_actual']} insuficiente. Extender +{test_result['recomendacion_extender_dias']}d.")
        return ("⚠️ Neutro", f"Resultado no significativo (p={test_result['p_value']:.3f}). No escalar todavía.")

    # Con significancia, evaluar magnitud
    if impacto_pct >= target_mde_pct:
        return ("✅ Funcionó", f"Impacto +{impacto_pct:.1f}% supera target +{target_mde_pct}%. Significativo (p={test_result['p_value']:.3f}). Escalar.")

    if impacto_pct > 0:
        return ("⚠️ Parcial", f"Impacto +{impacto_pct:.1f}% bajo target +{target_mde_pct}%. Significativo. Iterar.")

    return ("🟥 Falló", f"Impacto {impacto_pct:.1f}% (negativo o nulo). Significativo. Revertir cambio.")
```

**Insight (1-2 líneas):** aprendizaje + qué supuesto se validó/invalidó.
**Próximos pasos:** propone siguiente iniciativa (con baseline = resultado actual) o cierre.

### Paso 5 — UPDATE `experiments`

```sql
UPDATE experiments
SET
  resultado = $1,
  impacto_pct = $2,
  insight = $3,
  conclusion = $4,
  estado = 'Medido',
  updated_at = now()
WHERE id = $5;
```

**Excepción:** si veredicto = `⏸️ Extender`:
```sql
UPDATE experiments
SET
  fecha_evaluacion = fecha_evaluacion + INTERVAL '$extend_days days',
  updated_at = now()
WHERE id = $1;
-- estado queda 'En curso', NO se marca 'Medido'.
```

### Paso 6 — Generar + publicar informe

**Template markdown:**

```markdown
# Informe Experimento — {nombre}

**ID:** {id} · **Área:** {area} · **Owner:** {owner_dri}
**Periodo:** {fecha_launch} → {fecha_evaluacion} ({duracion_dias}d)
**Tipo:** {tipo} · **Fuente:** {fuente}

## 🎯 La Apuesta original

> {apuesta}

## 📊 Resultado

| Métrica | Valor |
|---------|-------|
| Baseline | **{baseline_valor}** ({baseline_fecha}) |
| Resultado | **{resultado_valor}** ({eval_fecha}) |
| Impacto | **{impacto_pct}%** |
| Target MDE | +{target_mde_pct}% |
| Significancia | p={p_value:.3f}, IC95%=[{ci_lo:.2f}, {ci_hi:.2f}] |
| Muestra | n_actual={n_actual} / muestra_min={muestra_min} |

## 🏁 Veredicto

{conclusion}

## 💡 Insight

{insight}

## ➡️ Próximos pasos

{next_steps}

## 🔗 Refs

- Notion borrador: [{notion_id}]({notion_id})
- CR Discord: [{link_cr}]({link_cr})
- PR código: [{link_pr}]({link_pr})
- Hermes proposal: {hermes_proposal_id}
- Brain query: `SELECT * FROM experiments WHERE id = '{id}';`
- Brain snapshot: `notion-cache/_datalake/_data/experiments.md`

---

*Informe generado por skill `informe-resultados` v1.0.0 · {timestamp}*
```

**Publicación (3 destinos, paralelo — la ejecuta el SERVER):**

1. **Discord:** canal área + `#datos-okrs` (resumen embed) — el server publica con sus credenciales; el skill no llama a Discord.
2. **Notion:** comentario en row "Features a Medir" + update DB row con campos `resultado`, `impacto_pct`, `conclusion` — server-side.
3. **Repo:** snapshot en `notion-cache/_experimentos/{id}.md` → próximo sync horario lo recoge al Brain.

---

## Edge cases

| Caso | Comportamiento |
|------|----------------|
| `n < muestra_min` | **NO** marca Medido. Veredicto `⏸️ Extender`. UPDATE `fecha_evaluacion += extend_days`. |
| KPI cambió definición mid-experiment | Warning + usa `baseline_valor` original. Documentar en `insight`. |
| `impacto_pct > 200%` | Sanity check → no auto-cerrar. Pedir confirmación humana. |
| Hermes experiment (`hermes_proposal_id NOT NULL`) | Cruzar con `hermes_learnings`; si row vacía, llenarla con insight. |
| Veredicto manual override (`--veredicto X`) | Usuario fuerza → param `resultado_override` del endpoint. Guardar con flag `_manual=true` en `insight`. |
| Re-medición (`estado='Medido'` y user pide remedir) | Confirma → param `force_remedir: true` re-corre + actualiza con `_remedicion_count++` en `insight`. |
| Sin datos en datalake (endpoint devuelve null) | Veredicto `⏸️ Extender` + instrucción a Julio para arreglar endpoint. |
| `baseline_valor IS NULL` | ABORT con mensaje claro: "experimento sin baseline, ejecutar `/exp-iniciativa --re-baseline` antes". |
| Cron auto-trigger encuentra 10+ experimentos vencidos | Procesar en batch + reportar resumen a `#datos-okrs`. |

---

## Inputs requeridos

| Input | Fuente |
|-------|--------|
| `exp_id` | Argumento CLI o cron query (param del endpoint: `exp_id`, NO `id`) |
| Auth endpoints Brain | Env `MV_BRAIN_TOKEN` (header `x-api-key`). Si no está definida, DETENTE y pide al usuario solicitar su token a BizOps (Julio). Sin fallback |
| Medición (North Star / Silver) | Resuelta server-side por el endpoint |
| Catálogo KPI | View `experiments_with_kpi` (server-side, ya hace LEFT JOIN) |
| Publicación Notion + Discord | Server-side — credenciales solo en Vercel `data-lake-mv` |

## Outputs

| Output | Destino |
|--------|---------|
| UPDATE experiments | Supabase |
| Informe markdown | Chat + Discord (canal área + #datos-okrs) + Notion DB + repo snapshot |
| Sugerencia próximo experimento | Inline al usuario + opcionalmente abre `exp-iniciativa` con baseline pre-cargado |

---

## Vinculación con otros skills

```
exp-iniciativa (paso 8)
  └── calendariza informe-resultados en fecha_evaluacion
       └── cron server-side / invocación manual
            └── informe-resultados
                 ├── UPDATE experiments
                 ├── publica Discord + Notion + repo
                 └── propone próximo experimento → opcionalmente invoca exp-iniciativa
```

| Skill | Cuándo se llama | Qué devuelve |
|-------|----------------|--------------|
| `exp-iniciativa` (re-entrada) | Si veredicto `✅ Funcionó` → propone iniciativa siguiente con resultado como baseline | Nueva fila `experiments` linkeada a la anterior |
| `crear-cr` | Si veredicto `🟥 Falló` → propone CR de reversión | Permalinks |

---

## Cron (auto-trigger — infra server-side)

El batch corre **server-side** en la infra del datalake (cron cada 12h, 8am/8pm): selecciona experimentos con `fecha_evaluacion <= today()` y `estado IN ('En curso','Propuesta')` y llama internamente la misma lógica de `POST /api/informe-resultados` por cada uno. La configuración del cron y sus credenciales viven en el server — **nada de esto se ejecuta ni se configura desde el cliente/skill**. Desde el cliente, el equivalente manual es un `POST /api/informe-resultados` por `exp_id` vencido.

---

## Stub Python (mínimo viable — solo endpoint Brain)

```python
import os, sys, requests

DATALAKE = "https://data-lake-mv.manzanaverde.la"
TOKEN = os.environ.get("MV_BRAIN_TOKEN")
if not TOKEN:
    sys.exit("MV_BRAIN_TOKEN no definida. DETENTE y pide al usuario solicitar su token a BizOps (Julio). Sin fallback.")
HEADERS = {"x-api-key": TOKEN, "Content-Type": "application/json"}

def informe_resultados_skill(exp_id, force_remedir=False, resultado_override=None):
    body = {"exp_id": exp_id}                       # ⚠️ el param es exp_id, NO id
    if force_remedir: body["force_remedir"] = True  # --remedicion
    if resultado_override: body["resultado_override"] = resultado_override  # --veredicto X

    r = requests.post(f"{DATALAKE}/api/informe-resultados", headers=HEADERS, json=body, timeout=60)
    r.raise_for_status()
    out = r.json()
    # El server hizo: medición → test estadístico → veredicto → UPDATE experiments
    # → publicación Discord + Notion + snapshot. El skill presenta el informe:
    return out   # {id, veredicto, impacto_pct, informe_md, ...}
```

---

## Testing

| # | Escenario | Esperado |
|---|-----------|----------|
| T1 | exp `✅ Funcionó` (impacto > target, p < 0.05) | UPDATE estado=Medido, conclusion "Escalar", publicar 3 destinos |
| T2 | exp `⚠️ Neutro` (no significativo) | UPDATE Medido, conclusion "No escalar", insight con razón |
| T3 | exp `🟥 Falló` (impacto negativo significativo) | UPDATE Medido, propone CR de reversión |
| T4 | `n < muestra_min` | NO marca Medido, UPDATE `fecha_evaluacion += extend_days` |
| T5 | `impacto_pct > 200%` | Sanity check, NO auto-cerrar, pide confirmación humana |
| T6 | Hermes experiment | Cruza con `hermes_learnings`, llena row si vacía |
| T7 | Re-medición (estado=Medido) | Confirma con usuario, re-corre con `_remedicion_count` |
| T8 | Sin datos datalake | Veredicto Extender + instrucción Julio para fix endpoint |
| T9 | `baseline_valor IS NULL` | ABORT con mensaje "ejecutar /exp-iniciativa --re-baseline" |
| T10 | Cron batch (10 experimentos vencidos) | Procesar todos, resumen consolidado a `#datos-okrs` |

---

## Métrica de éxito

- **100%** experimentos con `fecha_evaluacion` pasada → `estado='Medido'` o veredicto `⏸️ Extender` documentado.
- **0** experimentos huérfanos (en curso >30d post fecha_evaluacion).
- **<48h** desde `fecha_evaluacion` hasta informe publicado (auto-cron objetivo).
- **100%** informes con `insight` no vacío (no template placeholder).

---

## Dependencias

- ✅ Tabla `experiments` + vista `experiments_with_kpi`.
- ✅ Endpoint `POST /api/informe-resultados` deployado en `data-lake-mv` (medición + UPDATE + publicación server-side, auth `x-api-key`).
- ✅ Publicación Discord + Notion server-side — credenciales solo en Vercel `data-lake-mv`.
- ⬜ Endpoints North Star completos (Julio: `frequency`, `funnel-cvr`, `new-subscribers v2`).
- ⬜ Cron server-side configurado para auto-trigger batch.
- ⬜ Función Postgres `query_silver(path, from_week, to_week)` para fallback Opción B (server-side).

---

## Changelog

- **v1.1.0 (2026-08-07): publicación migrada a server-side (Fase 3 seguridad Brain) — sin tokens de servicio en cliente.** Eliminados los caminos de escritura directa al datalake con token de servicio (inputs, cron client-side, stub). Único camino: `POST /api/informe-resultados` con `x-api-key: $MV_BRAIN_TOKEN` — params `exp_id` (NO `id`), `resultado_override` (--veredicto), `force_remedir` (--remedicion). Medición, UPDATE `experiments` y publicación a 3 destinos corren server-side.
- **v1.0.0 (2026-06-30)** — Build inicial post-skeleton
  - 6 pasos completos
  - Test estadístico multi-método (continuo, proporción, pre/post)
  - Veredicto soft con sanity check
  - Auto-trigger cron Supabase
  - Stub Python listo
  - 10 escenarios de testing

---

**FIN.** Spec completa: `producto/estrategia/iniciativa-ai-native-dev/05-skill-informe-resultados.md`.
