---
name: informe-resultados
description: |
  Cierra la línea de datos de un experimento. En la fecha de evaluación, lee resultado del datalake,
  calcula impacto + significancia (t-test/z-test según diseño), genera informe markdown,
  publica a Discord + Notion + repo cache, y UPDATE en `experiments` con `estado='Medido'`.
  Auto-trigger vía cron Supabase o invocación manual `/informe-resultados exp-2026-NNN`.
trigger_phrases:
  - "/informe-resultados"
  - "informe experimento"
  - "cerrar experimento"
  - "resultado de exp-"
version: 1.0.0
owner: Julio Mori
based_on:
  - producto/estrategia/iniciativa-ai-native-dev/05-skill-informe-resultados.md
---

# Skill `informe-resultados` v1.0.0

> Skill del Sprint Company Brain que cierra el loop del experimento creado por `exp-iniciativa`. Es la parte que vuelve "iniciativa con apuesta" en **aprendizaje compartido** para el Company Brain.

## Cuándo se activa

- **Manual:** `/informe-resultados exp-2026-014`.
- **Auto (cron Supabase):** detecta experimentos con `fecha_evaluacion <= today() AND estado IN ('En curso', 'Propuesta')` → dispara cada 12h.
- **Re-medir:** usuario pasa `--remedicion` → re-corre aunque `estado='Medido'`.

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

**Publicación (3 destinos, paralelo):**

1. **Discord:** canal área + `#datos-okrs` (resumen embed).
2. **Notion:** comentario en row "Features a Medir" + update DB row con campos `resultado`, `impacto_pct`, `conclusion`.
3. **Repo:** snapshot en `notion-cache/_experimentos/{id}.md` → próximo sync horario lo recoge al Brain.

---

## Edge cases

| Caso | Comportamiento |
|------|----------------|
| `n < muestra_min` | **NO** marca Medido. Veredicto `⏸️ Extender`. UPDATE `fecha_evaluacion += extend_days`. |
| KPI cambió definición mid-experiment | Warning + usa `baseline_valor` original. Documentar en `insight`. |
| `impacto_pct > 200%` | Sanity check → no auto-cerrar. Pedir confirmación humana. |
| Hermes experiment (`hermes_proposal_id NOT NULL`) | Cruzar con `hermes_learnings`; si row vacía, llenarla con insight. |
| Veredicto manual override (`--veredicto X`) | Usuario fuerza. Guardar con flag `_manual=true` en `insight`. |
| Re-medición (`estado='Medido'` y user pide remedir) | Confirma → re-corre + actualiza con `_remedicion_count++` en `insight`. |
| Sin datos en datalake (endpoint devuelve null) | Veredicto `⏸️ Extender` + instrucción a Julio para arreglar endpoint. |
| `baseline_valor IS NULL` | ABORT con mensaje claro: "experimento sin baseline, ejecutar `/exp-iniciativa --re-baseline` antes". |
| Cron auto-trigger encuentra 10+ experimentos vencidos | Procesar en batch + reportar resumen a `#datos-okrs`. |

---

## Inputs requeridos

| Input | Fuente |
|-------|--------|
| `exp_id` | Argumento CLI o cron query |
| Acceso Supabase write | `SUPABASE_SERVICE_ROLE_KEY` |
| Endpoint North Star o Silver query | `data-lake-mv.manzanaverde.la` |
| Catálogo KPI | View `experiments_with_kpi` (ya hace LEFT JOIN) |
| `NOTION_TOKEN` para publicar comentario | Config |
| Discord webhooks por área | Config (mismo mapping que `crear-cr`) |

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
       └── cron Supabase / invocación manual
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

## Cron Supabase (auto-trigger)

```sql
-- Edge Function programada cada 12h vía pg_cron
SELECT cron.schedule(
  'informe-resultados-daily',
  '0 8,20 * * *',  -- 8am y 8pm
  $$
    SELECT net.http_post(
      url := 'https://hzpycmczwkwbfrqzvfyz.supabase.co/functions/v1/informe-resultados-batch',
      headers := jsonb_build_object('Authorization', 'Bearer ' || current_setting('app.service_role_key')),
      body := jsonb_build_object()
    );
  $$
);
```

Edge Function `informe-resultados-batch`:
```typescript
const due = await sb.from('experiments')
  .select('id')
  .lte('fecha_evaluacion', new Date().toISOString().slice(0, 10))
  .in('estado', ['En curso', 'Propuesta']);

for (const exp of due.data) {
  await invokeSkillInformeResultados(exp.id);
}
```

---

## Stub Python (mínimo viable)

```python
import os, datetime, requests, json
from supabase import create_client
from scipy import stats
import numpy as np

SUPABASE_URL = "https://hzpycmczwkwbfrqzvfyz.supabase.co"
sb = create_client(SUPABASE_URL, os.environ["SUPABASE_SERVICE_ROLE_KEY"])
DATALAKE = "https://data-lake-mv.manzanaverde.la"

def informe_resultados_skill(exp_id, force_remedicion=False):
    # 1. Recuperar
    exp = sb.table("experiments_with_kpi").select("*").eq("id", exp_id).single().execute().data

    if exp["estado"] == "Medido" and not force_remedicion:
        return {"error": "already medido, use --remedicion to re-run"}

    if not exp.get("baseline_valor"):
        return {"error": "sin baseline, abort"}

    # 2. Leer resultado
    if exp.get("endpoint_north_star"):
        resp = requests.get(f"{DATALAKE}{exp['endpoint_north_star']}", params={"weeks": "current-2:current"})
        data = resp.json()
        resultado_valor = data["latest"]
        n_actual = sum(w.get("n", 0) for w in data.get("weekly", []))
    elif exp.get("silver_path"):
        result = sb.rpc("query_silver", {"path": exp["silver_path"], "from_week": isoweek(exp["fecha_launch"]), "to_week": isoweek(exp["fecha_evaluacion"])}).execute()
        resultado_valor = result.data[0]["resultado"]
        n_actual = result.data[0]["n_actual"]
    else:
        return {"error": "sin endpoint ni silver_path"}

    impacto_pct = (resultado_valor - exp["baseline_valor"]) / exp["baseline_valor"] * 100

    # 3. Test estadístico
    diseno = exp.get("diseno_estadistico", {})
    n_min = diseno.get("muestra_min", 30)
    target_mde_pct = diseno.get("mde_pct", 5)

    if n_actual < n_min:
        # Extender
        extend_days = max(7, int(diseno.get("duracion_dias", 14) * 0.5))
        new_eval = (datetime.date.fromisoformat(exp["fecha_evaluacion"]) + datetime.timedelta(days=extend_days)).isoformat()
        sb.table("experiments").update({"fecha_evaluacion": new_eval}).eq("id", exp_id).execute()
        return {"id": exp_id, "veredicto": "⏸️ Extender", "razon": f"n={n_actual} < muestra_min={n_min}", "nueva_fecha_evaluacion": new_eval}

    # Veredicto
    if abs(impacto_pct) > 200:
        veredicto_text = "⚠️ Sanity check"
        conclusion = f"Impacto {impacto_pct:.1f}% fuera de rango. Revisar antes de cerrar."
    elif impacto_pct >= target_mde_pct:
        veredicto_text = "✅ Funcionó"
        conclusion = f"Impacto +{impacto_pct:.1f}% supera target +{target_mde_pct}%. Escalar."
    elif impacto_pct < 0:
        veredicto_text = "🟥 Falló"
        conclusion = f"Impacto {impacto_pct:.1f}%. Revertir cambio."
    else:
        veredicto_text = "⚠️ Parcial"
        conclusion = f"Impacto +{impacto_pct:.1f}% bajo target. Iterar."

    insight = generar_insight(exp, resultado_valor, impacto_pct, veredicto_text)
    next_steps = generar_next_steps(exp, veredicto_text, resultado_valor)

    # 5. UPDATE
    sb.table("experiments").update({
        "resultado": str(resultado_valor),
        "impacto_pct": round(impacto_pct, 2),
        "insight": insight,
        "conclusion": conclusion,
        "estado": "Medido",
    }).eq("id", exp_id).execute()

    # 6. Publicar
    informe_md = render_informe(exp, resultado_valor, impacto_pct, n_actual, n_min, conclusion, insight, next_steps)
    publicar_discord(exp["area"], informe_md)
    publicar_notion(exp["notion_id"], informe_md)
    publicar_repo(exp_id, informe_md)

    return {"id": exp_id, "veredicto": veredicto_text, "impacto_pct": impacto_pct, "informe_md": informe_md}
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
- ⬜ Endpoints North Star completos (Julio: `frequency`, `funnel-cvr`, `new-subscribers v2`).
- ⬜ Edge Function/endpoint UPDATE via service_role.
- ⬜ Discord webhooks por área (mismo set que `crear-cr`).
- ⬜ Cron Supabase `pg_cron` configurado para auto-trigger.
- ⬜ Función Postgres `query_silver(path, from_week, to_week)` para fallback Opción B.

---

## Changelog

- **v1.0.0 (2026-06-30)** — Build inicial post-skeleton
  - 6 pasos completos
  - Test estadístico multi-método (continuo, proporción, pre/post)
  - Veredicto soft con sanity check
  - Auto-trigger cron Supabase
  - Stub Python listo
  - 10 escenarios de testing

---

**FIN.** Spec completa: `producto/estrategia/iniciativa-ai-native-dev/05-skill-informe-resultados.md`.
