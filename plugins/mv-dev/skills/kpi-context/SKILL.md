---
name: kpi-context
description: |
  Vista 360° de cualquier KPI o input del datalake MV. Consolida definición canónica,
  inputs desagregados CON valores reales, experiments/iniciativas que lo mueven, medición
  histórica y metas. Modo INPUT: consulta inputs valiosos por sí mismos (serie temporal +
  qué KPIs alimentan cross-KPI). Regla auto-link: toda info MV se maneja en base a KPIs/inputs.
trigger_phrases:
  - "/kpi-context"
  - "contexto del kpi"
  - "qué KPI mueve"
  - "info del input"
  - "browse kpi"
  - "detalle kpi"
version: 1.1.0
owner: Julio Mori
based_on:
  - Regla auto-link KPI/input (Julio 2026-07-11)
  - Taxonomía dris (145 KPIs / 662 inputs / 18,807 valores semanales)
---

# Skill `kpi-context` v1.0.0

> Vista 360° de KPIs e inputs del datalake. Complementa `/api/dris/lookup` (búsqueda) con **detalle completo + valores reales**. Aplica la regla auto-link: toda información MV se maneja en base a KPIs o inputs.

## Cuándo se activa

- Consultar todo sobre un KPI: "dame el contexto del KPI 121", "info completa de margen bruto franquicia"
- Consultar un input específico: "qué mide lima-orders-scheduled orders", "qué KPIs alimenta el input de reclamos"
- Antes de crear iniciativa: para entender qué KPI/input mueve realmente
- En Weekly: para ver estado + iniciativas activas + valores de un KPI

## Arquitectura datalake (verificado 2026-07-16)

| Tabla | Rows | Qué guarda |
|-------|-----:|-----------|
| `dris_definitions` | 145 | KPIs activos (id, nombre, area, dri, metas, silver_path) |
| `dris_inputs` | 662 | Catálogo canónico de inputs (input_key, nombre, unidad, source, metas) |
| `dris_kpi_inputs` | 572 | Mapeo KPI ↔ input (kpi_id, cod_short, ciudad) |
| `dris_input_actuals` | 18,807 | **Valores semanales de inputs** (input_id=cod_short, period `2026-W29`, value) |
| `dris_manual_inputs` | 6,003 | Valores manuales cargados por DRI (kpi_id, period, value, evidence_url) |

**Insight clave:** `dris_input_actuals` está MÁS FRESCO (2026-W29) que `datalake_gold` (W9). Para valores actuales usar actuals, no gold.

**Cross-KPI:** un mismo input alimenta hasta 5 KPIs. Ej. `lima-orders-scheduled orders` → KPIs 31, 51, 52, 55, 56. Cambios en ese input impactan las 5 métricas.

## Endpoint

Base: `https://data-lake-mv.manzanaverde.la` · Auth: header `x-api-key: $MV_BRAIN_TOKEN`

> ⚠️ `MV_BRAIN_TOKEN` es una variable de entorno. Si no está definida, DETENTE e indica al usuario que solicite su token personal a BizOps (Julio). NO uses ningún valor por defecto ni key hardcodeada.

### MODO KPI

```bash
GET /api/kpi-context?id=121
GET /api/kpi-context?q=reconsumo    # resuelve por nombre → top match
```

Devuelve:
- `kpi` — definición canónica completa (objetivo, KR, nivel, dri, unidad, metas, tolerancia)
- `inputs[]` — desagregados CON `valor_actual` + `periodo` (batch dris_input_actuals)
- `inputs_by_ciudad`, `inputs_by_source` — agrupación
- `experiments[]` — iniciativas que mueven este KPI (id, estado, baseline, resultado, impacto)
- `ultima_medicion` + `historico[]` — datalake_gold (puede estar stale)
- `metas` — targets por mes del catálogo

### MODO INPUT (inputs valiosos por sí mismos)

```bash
GET /api/kpi-context?input=lima-orders-scheduled orders
GET /api/kpi-context?input_q=lima+orders    # busca por tokens
```

Devuelve:
- `input` — detalle (cod_short, ciudad, concepto, unidad, source, owner)
- `valor_actual` + `historico[]` (8 sem) + `tendencia` (↗↘→ con delta_pct)
- `feeds_kpis[]` — **TODOS los KPIs que alimenta** (cross-KPI)
- `same_concepto_otras_ciudades[]` — mismo input en otras ciudades

## Ejemplos reales

### KPI 4 — Margen bruto franquicia M1
```
inputs=12 · experiments=2 (exp-2026-014, exp-2026-007)
bogota-margen bruto-franchises = 240643.07 (2026-W27)
bogota-venta bruta total-franchises = 723200 (2026-W27)
```

### Input lima-orders-scheduled orders
```
valor_actual: 2648 (2026-W29)
tendencia: ↘ -24.2% (vs W28 3493)
feeds_kpis (5): 31 Frecuencia pedidos · 51 % Reclamos menu · 52 · 55 · 56
otras ciudades: 13 (bogota, cdmx, guadalajara, monterrey, piura...)
```

## Cómo invocar desde Claude Code

```
Dame el contexto completo del KPI 121
→ Claude llama GET /api/kpi-context?id=121
→ presenta: definición + inputs con valores + experiments + medición

Qué mide el input de reclamos en Lima y qué KPIs afecta
→ Claude llama GET /api/kpi-context?input_q=lima+reclamos
→ presenta: valor actual + tendencia + los N KPIs que alimenta
```

## Flujo de presentación recomendado

Cuando devuelvas contexto al usuario:

**Para KPI:**
1. Título: `KPI {id} — {nombre}` + area + DRI
2. Estado: última medición + tendencia si hay
3. Inputs: tabla con valor_actual por ciudad (destacar los que tienen datos vs None)
4. Iniciativas activas: experiments en curso apuntando al KPI
5. Metas: target del mes actual

**Para input:**
1. Título: `Input {cod_short}` + concepto + ciudad
2. Valor actual + tendencia (↗↘→) + histórico corto
3. **Cross-KPI:** "Este input alimenta N KPIs: [lista]" — enfatizar impacto múltiple
4. Otras ciudades con el mismo concepto (para comparar)

## Casos de uso en el Sprint Company Brain

- **Antes de crear iniciativa:** consultar KPI para ver baseline real + iniciativas existentes (evitar duplicados)
- **En Weekly Exec:** browse KPI rojo → ver qué inputs lo componen + cuáles están sin datos
- **Análisis cross-KPI:** un input cae → ver qué KPIs se afectan → priorizar fix
- **Auditoría de cobertura:** inputs con `valor_actual=None` → gaps de datos a llenar

## Dependencias

- ✅ `/api/kpi-context` endpoint (deployado)
- ✅ Tablas dris_* pobladas (145 KPIs / 662 inputs / 18,807 valores)
- ✅ `/api/dris/lookup` para búsqueda previa (search_inputs + include_inputs)
- ⚠️ `datalake_gold` stale (W9) — para valores frescos el endpoint usa `dris_input_actuals`

## Rol en Company Brain v2 (Carlos 2026-07-21) — capa RAG por KPI

En el marco de 4 capas, **`kpi-context` ES la recuperación de contexto por KPI (≈RAG) de la Capa 2**: al arrancar, un agente recupera del brain el contexto ligado al KPI (definición + inputs con valores reales + experiments previos que lo mueven + medición histórica) **antes** de crear o editar. Es el **Paso 0** del resto de skills.

**Contrato Paso 0 (RAG por KPI):**
```
exp-iniciativa / editar-experimento / crear-cr
   → Paso 0: kpi-context(kpi_id | input) recupera contexto del brain
   → luego estructuran y escriben (evita duplicar + trae baseline)
```
No re-crea data: solo recupera. La verdad de los números vive en el datalake (Capa 1).

## Vinculación con otros skills

```
kpi-context (Paso 0 · RAG por KPI)
  ├── exp-iniciativa (paso 2) usa la misma taxonomía para hard-gate KPI
  ├── crear-cr hereda kpi_definition_id
  └── informe-resultados lee experiments del KPI
```

## Changelog

- **v1.1.0 (2026-07-21)** — Company Brain v2 (Carlos): documentado el rol como capa RAG por KPI (Capa 2) + contrato Paso 0 que consumen los otros skills. Sin cambios de endpoint (la función ya era la recuperación por KPI).
- **v1.0.0 (2026-07-16)** — Build inicial P2 Sprint
  - Modo KPI: definición + inputs con valores + experiments + medición
  - Modo INPUT: serie temporal + cross-KPI feeds + otras ciudades
  - Valores reales desde dris_input_actuals (más fresco que gold)
  - Regla auto-link KPI/input aplicada

---

**FIN.** Endpoint: `api/kpi-context/index.js` en repo `manzana-verde-datalake`.
