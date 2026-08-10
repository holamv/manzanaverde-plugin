---
name: research-mv
description: |
  Investigación de SOLO LECTURA del Company Brain ANTES de crear un experimento/iniciativa/CR
  cuando la información no está clara (qué KPI mueve, baseline, qué se intentó antes, contexto
  de negocio). Junta en un solo brief: KPI + inputs (kpi-context), experiments previos con sus
  conclusiones, docs del Brain (datalake, Notion, proyectos) y datos gold. NO escribe nada —
  el output es un brief organizado listo para pasar a /exp-iniciativa o /crear-cr.
trigger_phrases:
  - "/research-mv"
  - "investiga antes de crear"
  - "no sé qué KPI mueve esto"
  - "qué se ha intentado sobre"
  - "contexto para una iniciativa"
  - "research del brain"
version: 1.0.0
owner: Julio Mori
---

# Skill `research-mv` v1.0.0 — Investigación previa (solo lectura)

> Úsalo cuando alguien quiere crear un experimento/iniciativa pero la información está difusa:
> no sabe qué KPI mueve, cuál es el baseline, si ya se intentó algo parecido, o le falta contexto.
> Este skill **NADA por todo el Brain** (datalake + Notion + docs de repos) y entrega un
> **brief de investigación** organizado. Después de eso, los skills de escritura
> (`/exp-iniciativa`, `/crear-cr`, `/proponer-campana`) reciben datos limpios.

## 🔒 Regla dura: SOLO LECTURA

Este skill **NUNCA escribe**: ni POST/PATCH al datalake, ni páginas en Notion, ni mensajes
en Discord, ni archivos fuera de la sesión. Si durante la investigación el usuario pide crear
algo, DETENTE y deriva al skill correspondiente con el brief ya armado. Funciona con cualquier
perfil de token (incluido `lectura`).

> ⚠️ Auth: requiere env var `MV_BRAIN_TOKEN`. Si no está definida, DETENTE y pide al usuario
> solicitar su token a BizOps (Julio). Sin fallback.

Base API: `https://data-lake-mv.manzanaverde.la` · header `x-api-key: $MV_BRAIN_TOKEN`

## Cuándo se activa

- "Quiero hacer algo con la retención de franquicias pero no sé qué KPI es"
- "¿Ya se intentó algo de reactivación por push en MX?"
- "Dame contexto para proponerle una iniciativa a Carlos sobre reclamos de reparto"
- ANTES de `/exp-iniciativa` cuando falten: KPI claro, baseline, o historial de intentos

## Flujo (5 pasos, en orden)

### Paso 1 — Afinar la pregunta

Del pedido del usuario extrae: **tema** (ej. "reconsumo MX"), **área probable**, y qué le
falta saber (¿KPI? ¿baseline? ¿historial? ¿contexto de negocio?). Si el tema es demasiado
amplio ("mejorar ventas"), pide UNA precisión antes de quemar llamadas.

### Paso 2 — Localizar el KPI y su contexto vivo (datalake API)

```bash
# Buscar KPI/inputs candidatos por texto
GET /api/dris/lookup?q={tema}&limit=5&search_inputs=true

# Con el mejor match → vista 360 (definición, inputs CON valores, experiments, metas)
GET /api/kpi-context?id={kpi_id}
# (o modo input: /api/kpi-context?input_q={texto} para ver qué KPIs alimenta un input)
```

- El lookup puede devolver `kpis_omitidos_por_scope` — significa que existen KPIs que tu
  perfil no ve (finance/HR). Dilo explícito en el brief: "hay N KPIs restringidos que
  podrían ser relevantes; pedir acceso si corresponde".
- Si no hay match razonable (score bajo): el KPI probablemente NO existe en el catálogo →
  anótalo como gap (definirlo con Carlos es prerequisito de la iniciativa).

### Paso 3 — Historial: qué se intentó antes y qué se aprendió

```bash
GET /api/experiments?area={area}&limit=50
GET /api/experiments?estado=Medido&area={area}    # cerrados con conclusión
```

Filtra por relevancia al tema y extrae por cada experiment relevante: `id`, `nombre`,
`estado`, `resultado`, `impacto_pct`, `conclusion`, `owner_dri`, `link_cr`.
**Objetivo doble:** aprender de intentos previos Y evitar duplicados (el endpoint rechaza
duplicados de 30 días — mejor descubrirlo aquí que en el 409).

### Paso 4 — Contexto documental del Brain (según acceso)

**Opción A — con el repo `manzana-verde-os` clonado local** (mirror del Brain):
navega `notion-cache/` con grep/lectura. Rutas de mayor señal:

| Ruta | Qué hay |
|---|---|
| `notion-cache/_datalake/docs/` | Docs técnicos del datalake (APIs, integración KPIs) |
| `notion-cache/_datalake/_data/experiments.md` | Snapshot de experiments (sync horario) |
| `notion-cache/wiki-how-to/` | Procedimientos por rol |
| `notion-cache/proyectos/` | Docs de los repos de dev (API.md, BUSINESS_LOGIC.md…) |
| `notion-cache/areas/` | Taxonomía de áreas y sub-áreas |
| `notion-cache/engineering/` | Producto & Tech, API docs, wiki de ingeniería |

**Opción B — sin el repo** (mismo contenido, fuente original):
usa el conector de Notion de Claude — busca en el workspace: página "Company Brain — HUB",
DB "📁 Proyectos (Git)" (docs por repo como páginas hijas), Wiki How-to, y las guías de
skills. Todo lo del mirror vive primero en Notion.

De cualquiera de las dos fuentes: extrae solo lo que responde la pregunta del Paso 1
(definiciones de negocio, decisiones previas, restricciones conocidas). No pegues páginas
enteras al brief — cita ruta/link + 1-3 líneas de por qué importa.

### Paso 5 — Datos crudos si el baseline no salió del kpi-context

```bash
# Gold KPIs de una semana (WWYYYY)
GET /api/public/datalake/{semana}?kpis={ids}&include=gold
```

Solo si el Paso 2 no dio `valor_actual`/`ultima_medicion` utilizable.

## 📋 Output — Brief de investigación (template)

```markdown
# Research: {tema} — {fecha}

## KPI candidato
- **{nombre}** (id {N}) · área {área} · DRI: {dri_name} · unidad {unidad}
- Baseline actual: **{valor}** ({periodo}, fuente: dris_input_actuals/gold)
- Metas: {targets si hay}
- ⚠️ KPIs restringidos por scope: {N o "ninguno"}

## Inputs que lo componen (los que importan al tema)
- {cod_short}: {valor_actual} ({ciudad}, {source})

## Qué se intentó antes
| Exp | Estado | Resultado | Conclusión (resumen) |
|---|---|---|---|
| {id} | {estado} | {impacto}% | {1 línea} |
- Riesgo de duplicado: {sí/no — cuál}

## Contexto de negocio relevante
- {doc/página}: {por qué importa, 1-3 líneas} → {link o ruta}

## Gaps (lo que NO se pudo responder)
- {ej.: KPI no existe en catálogo → definir con Carlos ANTES de crear}

## Siguiente paso sugerido
/exp-iniciativa con: brief="{...}", kpi_definition_id={N}, baseline_valor={X},
owner_dri={quien}, paises=[...]
(o /proponer-campana si es campaña CRM, o /crear-cr si es tarea sin hipótesis)
```

## Reglas de eficiencia

- Máximo ~6 llamadas API + lecturas dirigidas. Si a la tercera búsqueda documental no hay
  señal, repórtalo como gap — no sigas nadando.
- `403` en un KPI = restringido por perfil (finance/HR). Regístralo, no lo reintentes.
- Si TODO lo que pedía el usuario ya salió en el Paso 2 (kpi-context lo tenía), corta ahí
  y entrega el brief — no completes pasos por ritual.

## Vinculación con otros skills

```
research-mv (investiga, read-only)
   → exp-iniciativa (crea el experimento con datos limpios)
   → proponer-campana / ejecutar-campana (si es campaña CRM)
   → crear-cr (si es tarea concreta sin hipótesis)
kpi-context = la herramienta puntual; research-mv = la sesión completa de contexto
```

## Changelog

- v1.0.0 (2026-08-07): versión inicial. Read-only, doble fuente (mirror local o Notion),
  brief estructurado con gaps y anti-duplicados.
