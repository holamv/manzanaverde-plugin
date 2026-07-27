---
description: Workflow de implementacion tecnica para MV - orquesta Discovery, Fix puntual, Sprint o PRD segun el tipo de request. Usarlo ante cualquier tarea tecnica en repos de MV.
---

# MV Instruction Generator (v2)

Workflow de trabajo técnico para Manzana Verde basado en la metodología consolidada. Se usa principalmente **dentro de Claude Code** (con acceso al filesystem). Hace discovery interno automático antes de proponer cambios — no asume estructura del código.

## Contexto MV

**Empresa:** Comida saludable con delivery + suscripción semanal
**Países:** Perú (PE, principal), México (MX), Colombia (CO)
**Ciudades:** Lima, Piura, CDMX, Guadalajara, Monterrey, Bogotá

**Repos típicos del proyecto web:**
- Frontend: Next.js 14+ App Router, TypeScript, Tailwind, Zustand (Vercel)
- Dashboard: React + Vite + TypeScript, lee Supabase Data Lake
- Backend: extrae `customer_id` del JWT cookie, persiste eventos en `events_mobile` (MySQL, columna `params` JSON)

**Pagos sagrados (NUNCA tocar sin instrucción explícita y específica):**
- `src/checkout/*`, `checkout-utils.ts`
- `src/PagoForm*`
- `src/components/payment/*`, `payment-errors.ts`
- `src/od-order`, `src/dailyfood`, `src/foodcourt`
- `src/wallet`, `src/card-add`
- `src/api/payment/*`

## Filosofía

Tres principios inmutables:

1. **Discovery siempre primero** — investigar antes de tocar código, nunca asumir
2. **Cambios surgical, NO rewrites** — preferir fix puntual sobre refactor
3. **Guards de pago obligatorios** — verificar `git diff` antes de cada commit

## Modo de operación: detección automática

Al recibir un request, detecta cuál de los 4 modos aplica:

### Modo A — Idea de negocio nueva (PRD)

**Trigger:** request vago, ideación, "quiero hacer X", sin especificación técnica.
- "Quiero un dashboard de pedidos por día"
- "Necesitamos una funcionalidad para que el equipo de ops vea X"

**Comportamiento:** Modelo conversacional con preguntas de negocio.

Ver sección **"Modo A: PRD generator"** abajo.

### Modo B — Fix puntual (ejecución directa)

**Trigger:** request técnico concreto, alcance claro (1-3 archivos), sin decisiones de arquitectura.
- "Quita el console.log de tracking.ts"
- "Cambia el copy del botón a 'Pagar ahora'"
- "Agrega try/catch al fetch de auth-check"

**Comportamiento:**
1. Discovery interno (grep/cat para confirmar qué archivos tocar)
2. Si todo está claro → ejecuta directo
3. Si hay 1 ambigüedad bloqueante → 1 pregunta concreta con tu recomendación
4. Genera resumen breve en chat (NO archivo .md formal)

### Modo C — Sprint mediano/grande

**Trigger:** múltiples archivos, decisiones de arquitectura, riesgo de regresión.
- "Sprint 4 - optimizar INP en mobile"
- "Implementa funnel tracking completo con anonymous_id"
- "Agrega soporte de A/B testing en planes"

**Comportamiento:**
1. Discovery interno completo (grep de patrones, lectura de archivos clave, identificación de dependencias)
2. Hacer 1-2 preguntas si hay ambigüedad bloqueante (con opciones + tu recomendación)
3. **Generar plan en `/home/claude/output/INSTRUCCION_*.md`** con fases, STOPs, criterios de aceptación
4. **PARAR**: presentar el plan al developer y esperar aprobación
5. Si aprueba → ejecutar con STOPs intermedios
6. Al final → generar `/home/claude/output/[NOMBRE]_RESULTADOS.md` con lo hecho

### Modo D — Discovery puro

**Trigger:** explícito ("investiga por qué X", "discovery primero", "solo entender") o cuando hay incertidumbre técnica fuerte sin hipótesis claras.
- "Investiga por qué tenemos 138 errores 5xx"
- "Discovery del componente de planes antes de tocarlo"

**Comportamiento:**
1. Solo investigación read-only (grep, cat, curl, network requests)
2. Genera reporte `/home/claude/output/DISCOVERY_*.md` con hallazgos + plan propuesto
3. NO toca código
4. Termina con "PAUSAR — espera instrucción de fix"

## Detección automática del modo

Aplica esta heurística en orden:

```
1. ¿El developer dice "discovery", "investiga", "solo entender"?
   → Modo D (Discovery puro)

2. ¿El request es vago/ideación sin especificación técnica?
   → Modo A (PRD)

3. ¿El request tiene alcance amplio (sprint, refactor, feature nueva, multi-archivo)?
   → Modo C (Sprint mediano/grande)

4. En todos los demás casos:
   → Modo B (Fix puntual con discovery interno)
```

**Override:** Si el developer explicita "solo dame el plan, no ejecutes" → tratar como Modo C aunque sea fix puntual. Si dice "ejecuta directo" → tratar como Modo B aunque sea sprint grande (a riesgo propio).

## Discovery interno (todos los modos excepto A)

**Antes de proponer cualquier cambio**, hacer discovery interno con estos pasos:

### Step 1: Identificar archivos relevantes

```bash
# Buscar por keyword del request
grep -rn "PATTERN_DEL_REQUEST" src/ --include="*.tsx" --include="*.ts"

# Buscar por funcionalidad (tracking, payment, checkout, etc.)
find src/ -path "*RELEVANT_PATH*" -type f
```

### Step 2: Leer archivos clave

Usar `view` o `cat` en los 3-5 archivos más relevantes encontrados. NO asumir estructura.

### Step 3: Identificar dependencias y riesgos

- ¿Hay otros archivos que importen lo que vamos a tocar?
- ¿Hay tests existentes?
- ¿Toca algún archivo "sagrado" (pagos)? Si sí → STOP, requerir confirmación explícita

### Step 4: Decidir modo final

Con la info del discovery, confirmar el modo detectado o ajustar:
- Discovery reveló que el cambio toca 5 archivos en lugar de 1 → escalar a Modo C
- Discovery reveló que el problema no es lo que parecía → preguntar al developer antes de seguir

**El discovery interno NO se muestra al usuario en detalle** (sería ruidoso). Solo se reporta lo necesario:
- Modo B: "Encontré X en archivo Y, voy a hacer Z"
- Modo C: incluir hallazgos en la sección "Contexto" del .md plan
- Modo D: el discovery ES el entregable

## Guards globales (aplican a Modos B, C, D cuando hay implementación)

Cada vez que vayas a hacer un commit/cambio:

```bash
# Guard 1: archivos de pago
git diff --name-only | grep -E "checkout-utils|payment-errors|od-order|dailyfood|foodcourt|wallet|card-add|src/api/payment"
# Esperado: VACÍO. Si aparece algo, ABORTAR y reportar al developer.

# Guard 2: PagoForm solo si la instrucción lo justifica
git diff --name-only | grep "PagoForm"
# Si aparece, verificar que el cambio es:
# - Mínimo (1-2 líneas)
# - Justificado en el contexto
# - No toca lógica de pago

# Guard 3: Build pasa
npx tsc --noEmit
npx next build
```

Si **algún guard falla** → revertir cambios, reportar al developer.

## Modo A: PRD generator (idea de negocio nueva)

Para requests vagos/ideación. NO ejecuta código — modelo conversacional.

> **PRD formal de código → `/mv-dev:crear-prd`.** Modo A genera un *Brief de
> Negocio* (el "qué/para qué") y luego pasa a Modo C. Cuando el trabajo gradúa a
> **código** y amerita un PRD estructurado (trazabilidad, plan de tests,
> observabilidad, DoD), el formato único es `/mv-dev:crear-prd` (8 bloques,
> `docs/prd/CR-<cr_id>.md`). No inventar un formato de PRD inline: hay un solo
> template. El Brief de Negocio y el `INSTRUCCION_*.md` de Modo C siguen igual.

### Fase 1: Preguntas de negocio (máximo 4)

Hacer SOLO las preguntas que NO podés deducir del contexto:

1. ¿Quién va a usar esto? (Ops, Finance, Marketing, Producto, Customer Service, etc.)
2. ¿Qué información necesita ver/procesar?
3. ¿Con qué frecuencia se usará? (diario, semanal, ad-hoc)
4. ¿Hay referencia visual o ejemplo similar?

NO preguntes nada técnico en esta fase. Solo el "qué" y el "para qué".

### Fase 2: Generar Brief de Negocio

```markdown
## BRIEF DE NEGOCIO

**Proyecto:** [Nombre descriptivo]
**Objetivo:** [Qué problema resuelve]
**Usuario final:** [Rol + área en MV]
**Funcionalidades principales:**
- [...]
**Frecuencia de uso:** [...]
**Métricas de éxito:** [...]
```

Confirmar con el developer: "¿Este brief refleja lo que necesitas?"

### Fase 3: Si confirma → cambiar a Modo C

El Brief se vuelve el "Contexto del problema" de la instrucción técnica. Continuar con Discovery interno + plan + ejecución.

Si el trabajo es de código y amerita un PRD formal (BET/RESUME sobre repo/app), generar ese PRD con `/mv-dev:crear-prd` (formato único de 8 bloques) en vez de redactarlo inline. El `INSTRUCCION_*.md` de Modo C sigue siendo el plan de ejecución con STOPs; el PRD de `crear-prd` es la especificación versionada en `docs/prd/`.

## Modo B: Fix puntual (ejecución directa)

Para fixes claros, 1-3 archivos.

### Workflow

```
1. Discovery interno silencioso
       ↓
2. ¿Hay ambigüedad bloqueante? → 1 pregunta concreta con tu recomendación
   ¿No hay ambigüedad? → continuar
       ↓
3. Reportar brevemente lo que vas a hacer:
   "Voy a modificar X en archivo Y para lograr Z"
       ↓
4. Ejecutar cambios (Edit/Write tools)
       ↓
5. Verificar guards
   git diff --name-only | grep -E "..."
   npx tsc --noEmit
       ↓
6. Resumen breve en chat:
   - Archivos modificados
   - Qué hace ahora
   - Comando de verificación si aplica
       ↓
7. Sugerir siguiente paso (commit, deploy, test manual)
```

**NO generar archivo .md formal** en Modo B. El chat es suficiente.

## Modo C: Sprint mediano/grande

Para cambios multi-archivo, decisiones de arquitectura.

### Workflow

```
1. Discovery interno completo
       ↓
2. 1-2 preguntas de aclaración si hay ambigüedad bloqueante
       ↓
3. Generar /home/claude/output/INSTRUCCION_[NOMBRE]_[FECHA].md
   con estructura completa (ver template abajo)
       ↓
4. Presentar el plan al developer:
   "Plan generado en [path]. Resumen: [3-5 bullets]. ¿Apruebo y ejecuto?"
       ↓
5. Si aprueba → ejecutar fase por fase
   Si pide cambios → ajustar plan, repetir paso 4
       ↓
6. Cada fase termina con STOP automático:
   - Reportar lo hecho
   - Ejecutar verificaciones de la fase
   - Esperar OK para siguiente fase
       ↓
7. Al final → /home/claude/output/[NOMBRE]_RESULTADOS.md
   con todo lo ejecutado, archivos modificados, issues encontrados
```

### Template de instrucción Modo C

```markdown
# INSTRUCCIÓN: [Nombre descriptivo]

**Fecha:** [YYYY-MM-DD]
**Repositorio:** [nombre del repo]
**Tiempo estimado:** [X-Y horas]
**Modo:** Implementación con STOPs

---

## 🚨 Contexto del problema
[3-5 párrafos. Distinguir HECHO vs HIPÓTESIS.
Incluir hallazgos del discovery interno.]

### Lo que SÍ funciona (no tocar)
- [...]

### Lo que NO funciona (este sprint resuelve)
- [...]

## 🎯 Objetivo
[3-6 bullets concretos]

**No-goals (fuera de alcance):**
- [...]

## 📋 Orden de ejecución (N fases con STOPs)

\`\`\`
FASE 1 → [Nombre] (Xh)
   🛑 STOP → [verificación]
FASE 2 → [Nombre] (Xh)
   🛑 STOP
FASE N → Verificación E2E
\`\`\`

## 🛡️ GUARDS GLOBALES
[Lista de archivos prohibidos + comando grep]

## FASE 1 → [Nombre]

### 1.1 [Subtarea]

**Archivo:** `path/exacto.tsx`

**ANTES (verificar con grep):**
\`\`\`bash
grep -n "PATTERN" path/exacto.tsx
\`\`\`

\`\`\`tsx
[Código actual]
\`\`\`

**DESPUÉS:**
\`\`\`tsx
[Código nuevo]
\`\`\`

**Justificación:** [por qué]

### 1.X 🛑 STOP DE FASE 1 → Validación

\`\`\`bash
[comandos de verificación]
\`\`\`

[Repetir para cada fase]

## ✅ Criterios de aceptación globales
- [ ] [...]

## 📊 Reporte final esperado
Generar /home/claude/output/[NOMBRE]_RESULTADOS.md con:
- Estado por fase
- Archivos modificados
- Issues encontrados
- Verificaciones ejecutadas
- Pendientes para próximo sprint
```

### Template de reporte Modo C

```markdown
# [Nombre del Sprint] — Resultados

**Fecha:** [YYYY-MM-DD]
**Tiempo real:** [Xh] (vs [Yh] estimado)
**Branch:** [nombre]

## Resumen ejecutivo
| Fase | Estado | Verificación |
|---|---|---|
| 1 | ✅ done / ⚠️ partial / ❌ skipped | [link/curl/grep] |

## FASE N → [Nombre]
### Cambios
- [archivo]: [descripción]

### Verificación
\`\`\`bash
[comandos ejecutados con outputs]
\`\`\`

## Lista de archivos modificados
| # | Archivo | Tipo (NEW/MOD) | Cambios |
|---|---|---|---|

## Issues encontrados
1. [...]

## Tareas POST-deploy
A. [Verificación post-deploy]
B. [Coordinación con otros equipos si aplica]

## Pendientes para próximo sprint
1. [...]
```

## Modo D: Discovery puro

Para investigación read-only sin tocar código.

### Workflow

```
1. Investigación con grep/cat/find/curl/web_fetch
       ↓
2. Generar /home/claude/output/DISCOVERY_[CONTEXT]_[FECHA].md
       ↓
3. NO tocar código bajo NINGUNA circunstancia
       ↓
4. Reportar al developer:
   "Discovery completo en [path]. Hallazgos clave: [3-5 bullets].
   Plan propuesto: [alto nivel]. ¿Genero instrucción de fix o ajustamos plan?"
```

### Template de discovery

```markdown
# Discovery: [Tema] — [YYYY-MM-DD]

## Resumen ejecutivo
[5-8 bullets con hallazgos principales]

## Investigación realizada
- Comandos ejecutados: [lista]
- Archivos consultados: [lista]
- URLs verificadas: [lista]

## Hallazgos por área

### [Área 1]
- Estado actual: [evidencia concreta]
- Causa raíz determinada: [explicación]
- Snippets relevantes:
\`\`\`tsx
[código]
\`\`\`

## Causa raíz determinada
[Explicación clara en 3-5 oraciones]

## Plan propuesto de fix (alto nivel — sin código)

### Opciones disponibles
1. [Opción A] — esfuerzo: [bajo/medio/alto]
2. [Opción B] — esfuerzo: [bajo/medio/alto]

### Recomendación
[Cuál y por qué]

## Decisiones que requieren input del developer
- [ ] [Decisión 1 con tu recomendación]

## Archivos consultados (read-only)
- [lista]

---
**Estado:** PAUSADO — esperar instrucción de fix
```

## Reglas de generación

### Tiempos estimados realistas

Con Claude Code eficiente, suele tomarse **20-50% del tiempo estimado**. Estima basado en:

| Complejidad | Tiempo estimado |
|-------------|-----------------|
| 1-2 archivos, cambios aditivos | 30 min - 1h |
| 3-5 archivos, lógica nueva | 1-3h |
| 5-10 archivos, multi-sistema | 3-6h |
| Discovery + multi-fase con STOPs | 6-10h |

**Mejor sobreestimar 20-30%** que subestimar.

### Decisiones razonables cuando dice "decide tú"

Patrones ganadores:
- **localStorage vs Cookie:** localStorage por simplicidad
- **Sprint MÍNIMO vs COMPLETO:** MÍNIMO si toca código crítico, COMPLETO si fixes son aditivos
- **301 vs 410 vs 404:** 410 si el recurso fue retirado, 301 si hay equivalente
- **Refactor vs Fix puntual:** SIEMPRE fix puntual (si no se pidió refactor, no lo hagas)
- **Framework code vs custom:** Preferir helpers existentes del repo sobre crear nuevos

### Cuando preguntar (máximo 1-2 preguntas)

Solo preguntar si la decisión:
1. **Cambia significativamente** la implementación (ej: client-side vs server-side)
2. **Tiene riesgo de regresión** que afecta usuarios reales (ej: tocar middleware de auth)
3. **Requiere coordinación** con otros equipos (backend, data)

NO preguntar:
- Detalles que se pueden deducir leyendo el código
- Preferencias de estilo (usar helpers del repo)
- Cosas que tu recomendación cubre razonablemente

### Tono y formato

- **Español** (equipo hispanohablante)
- Emojis con moderación: 🚨 crítico, 🎯 objetivo, ✅ done, ❌ no, ⚠️ precaución, 🛑 STOP, 📋 lista, 📊 datos
- Bloques de código copy-paste-listos
- Tablas para comparaciones (antes/después, opciones, estados)
- Sin jerga innecesaria — el equipo sabe pero valora claridad

### Naming convention de archivos

```
INSTRUCCION_[CONTEXT]_[FECHA].md     # Plan de Modo C
[NOMBRE]_RESULTADOS.md                # Reporte post-ejecución
DISCOVERY_[CONTEXT]_[FECHA].md        # Discovery puro Modo D
```

## Anti-patterns

❌ **Asumir estructura del código sin grep/cat.** Siempre Discovery interno primero.

❌ **Refactorizar sin que se pida.** Si no se pidió refactor, no lo hagas.

❌ **Tocar archivos de pago sin justificación específica.** Verificar guards SIEMPRE.

❌ **Generar .md cuando un fix puntual no lo necesita.** Modo B = chat, no archivo.

❌ **Generar fix gigante sin STOPs en sprints grandes.** Modo C = STOPs obligatorios.

❌ **Tiempos optimistas.** Mejor "1-2h" que toma 30 min, que "30 min" que toma 3h.

❌ **Hacer >2 preguntas de aclaración.** Si necesitás más, leé el código.

❌ **Ignorar reportes/discoveries previos** que el developer comparte. Usarlos como contexto autoritativo.

## Cuando dudes

Recuerda los 3 pilares:

1. **Discovery primero** — nunca asumas
2. **Cambios surgical, NO rewrites** — preservar lo que funciona
3. **Guards de pago** — verificar antes de cada commit

Si una propuesta rompe alguno de estos, está mal diseñada. Reescribir.

---

**FIN del SKILL.md.** Cualquier ambigüedad sobre cómo aplicar este skill, preguntar al developer antes de generar/ejecutar.
