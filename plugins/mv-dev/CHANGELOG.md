# Changelog

Todos los cambios notables del plugin mv-dev se documentan aqui.

## [Unreleased] — hacia 1.9.0

### Added
- **Gate de PRD en `crear-cr`** (Fase 3 del PRD `crear-prd`): tras crear el CR, un gate **proporcional** decide si requiere PRD — idempotente (si el CR ya tiene PRD, linkea y sale), clasifica vía `test-decision` (BUG trivial → sin PRD; BUG defecto → `crear-prd` ligero; BET/RESUME → completo). **Bloqueante solo para BET/RESUME sobre flujo crítico** (pago/pedido/registro/login); el resto se sugiere. Diff mínimo en `crear-cr` (nueva sección "Paso 5.5", sin refactor).
- **Bypass `--sin-prd`** (patrón `allow_no_kpi`): exige `rationale` explícito (sin él, rechazado), marcado *discouraged*, se graba junto al CR (`sin_prd_rationale`) y queda documentado en el SKILL. Pendiente documentarlo en la página del Company Brain en Notion junto con `allow_no_kpi` y `force`.
- **Skill `crear-prd`** (Fase 2 del PRD `crear-prd`, modo solo-lectura): genera un PRD estructurado de 8 bloques para trabajo de código en `docs/prd/CR-<cr_id>.md` del repo destino (versionado con el código, revisable en el PR). Dos modos de salida — ligero (BUG defecto: bloques 1,3,4,5,8) y completo (BET/RESUME: los 8). Consulta `test-decision` para la clasificación (no la reimplementa), usa el estilo de discovery de `mv-instruction-generator`, e **idempotente por `cr_id`** (si el PRD existe, linkea y sale). No ejecuta código, no abre PR, no escribe en Notion. Template único en `skills/crear-prd/TEMPLATE.md`. Registrada en los README (31→32 skills). genera un PRD estructurado de 8 bloques para trabajo de código en `docs/prd/CR-<cr_id>.md` del repo destino (versionado con el código, revisable en el PR). Dos modos de salida — ligero (BUG defecto: bloques 1,3,4,5,8) y completo (BET/RESUME: los 8). Consulta `test-decision` para la clasificación (no la reimplementa), usa el estilo de discovery de `mv-instruction-generator`, e **idempotente por `cr_id`** (si el PRD existe, linkea y sale). No ejecuta código, no abre PR, no escribe en Notion. Template único en `skills/crear-prd/TEMPLATE.md`. Registrada en los README (31→32 skills).
- **Convención de trazabilidad código→CR** (Fase 1 del PRD `crear-prd`): rama `cr/<cr_id>-<slug>`, trailer de commit `CR: <cr_id>` (+ opcional `Exp: <exp_id>`) y bloque de trazabilidad en el cuerpo del PR. Cierra el bucle de 4 capas del Company Brain (datalake ↔ Notion ↔ Discord) hasta el repo: registra qué código implementó cada iniciativa. Documentado en `docs/TRACEABILITY.md`, linkeado desde el README de la raíz.

### Changed
- **`mv-instruction-generator` (Modo A)**: puntero no-bloqueante a `crear-prd` como formato único de PRD para trabajo de código (envolver, no extraer — decisión §9.3). El *Brief de Negocio* de Modo A y el `INSTRUCCION_*.md` de Modo C quedan intactos; el flujo `exp-iniciativa → generator → crear-cr` no cambia.
- **Templates de PR** (`.github/pull_request_template.md` y `plugins/mv-dev/templates/pr-template.md`): nuevo bloque "Trazabilidad" (CR / Experiment / PRD / KPI) al inicio, sin borrar lo existente.
- **`validate-pre-push.sh`**: detecta el trailer `CR:` en los commits a pushear. **Fase 3**: en ramas `cr/*` **falla** (exit 1) si falta el trailer; en cualquier otra rama emite solo un *warning* (`[trazabilidad]` a stderr) y no bloquea. (Fase 1 había introducido el warning global.)

## [1.8.1] - 2026-07-27

### Fixed
- **URL de instalacion (404)**: el comando de instalacion apuntaba a `github.com/manzanaverde/manzanaverde-plugin`, un org inexistente. Corregido a `manzanaverdelatam/manzanaverde-plugin` en las 4 rutas de onboarding (README de la raiz, `plugins/mv-dev/README.md`, `docs/01-QUICK_START.md` y el checklist de `docs/README.md`).
- **`BLOCKED_TABLES` sin las tablas de pagos**: el README prometia bloquear `payments` y `user_payment_methods`, pero el default real no las incluia (`user_credentials,payment_methods,stripe_tokens,admin_sessions`). Se agregan al default de `DB_BLOCKED_TABLES` del `mv-db-query-server` (`src/index.ts` y el `dist/index.js` compilado) y a la doc de `mv-db-queries`.
- **README desactualizado (12 skills → 31)**: los README de la raiz y del plugin listaban 12 skills cuando hay 31 en `plugins/mv-dev/skills/`. Se listan las 31 agrupadas por suite (Core, Conocimiento, Accion, Gherkin/BDD, Company Brain, Campañas CRM, Flutter) y se corrige el conteo.

### Changed
- **`CHANGELOG.md` movido a `plugins/mv-dev/`**: el marketplace instala `./plugins/mv-dev`, no la raiz del repo, asi que el historial de versiones ahora viaja junto al `plugin.json` que versiona. Queda linkeado desde la tabla de documentacion del README de la raiz.
- **Seccion de seguridad (README de la raiz)**: el bloqueo de tablas se documenta explicitamente como *guardrail* sobrescribible por cada dev via `DB_BLOCKED_TABLES` (no un control de acceso), y se aclara que el MCP de Supabase no comparte esta lista.
- **`obra/superpowers` fijado a `v6.2.0`** en `marketplace.json`: la entrada no tenia `ref`, asi que cada `plugin add` del marketplace de MV traia lo que hubiera en la rama por defecto de un repo de terceros en ese momento. Fijarlo hace la instalacion determinista y auditable.

### Pendiente
- **Grants reales del usuario de DB de staging** sobre `payments` / `user_payment_methods`: el cambio de `BLOCKED_TABLES` evita el accidente, no el intento. Si esas tablas son consultables a nivel de permisos, la lista no protege nada. Confirmar los grants del usuario de solo lectura de staging.
- **`allow_no_kpi` y `force` sin documentar en Notion**: son bypasses legitimos y bien construidos de los hard-gates de `exp-iniciativa` y `editar-experimento` (`allow_no_kpi` exige `rationale` y esta marcado como discouraged; `force` devuelve 409 y exige rationale en el `resumen`), pero la pagina madre del Company Brain describe los gates sin mencionar que tienen puerta, asi que se leen como mas duros de lo que son. Es un fix de documentacion en Notion, no en el repo.

## [1.8.0] - 2026-07-18

### Added
- **Suite Company Brain** (5 skills nuevas): convierten toda iniciativa/experimento en fila estructurada del datalake, siempre vinculada a un KPI o input. Fuente: reqs Carlos 2026-07-17 (Company Brain v2).
  - `exp-iniciativa`: crea iniciativa/experimento estructurado, captura baseline del datalake, propone diseno estadistico, persiste en tabla `experiments` (Supabase `hzpycmczwkwbfrqzvfyz`) y crea/vincula el Issue en Notion (plantilla issue). Bifurca a `mv-instruction-generator` si area tech; co-llama `crear-cr`; cierra con `informe-resultados`.
  - `crear-cr`: crea Change Requests / tareas con routing a canales Discord reales (CR de iniciativa/issue -> #weekly-exec-okrs; CR interno cross-team -> #crs-*; BET software -> #iniciativas-tech).
  - `editar-experimento`: edita un experimento existente (link Notion o exp_id) sin re-crearlo, con guard de etapa (Propuesta/En curso editable, Medido bloqueado salvo force). Sincroniza tri-destino: datalake + Notion (plantilla issue) + Discord.
  - `informe-resultados`: cierra el ciclo de medicion en `fecha_evaluacion` (z-score, veredicto), escribe resultado/impacto/insight en el experiment.
  - `kpi-context`: vista 360 de un KPI o input (valores reales de `dris_input_actuals`, tendencia, feeds cross-KPI). Consulta antes de crear/editar.
- **Regla auto-link KPI/input**: toda entidad del Brain debe vincularse a un KPI o input del catalogo del datalake (`dris_definitions` 145 KPIs / `dris_inputs` 662 inputs). Hard-gate en creacion (score >=0.15 o kpi_definition_id explicito o allow_no_kpi=true).
- **Suite Campañas CRM (Growth)** (3 skills): `proponer-campana` (propone campaña completa + copy desde genero+tema), `ejecutar-campana` (ejecuta ManyChat o BackOffice y registra el experimento), `generar-lista-manychat` (insumos CSV+JSON para ManyChat). Se integran con el datalake (endpoints /api/planner) y registran experiments igual que el Brain.

### Changed
- README/CLAUDE del plugin: los skills del Company Brain quedan como parte del kit estandar de BizOps/Ops, uso recomendado para todo trabajo de iniciativas medibles.

## [1.7.0] - 2026-06-23

### Added
- **Test Decision Rubric** (`/mv-dev:test-decision`): nueva skill canonica que decide que/cuando testear — clasificador BUG/BET/RESUME, matriz change-type × superficie → artefacto de test, matriz mock-vs-real con Regla de oro, regla "cobertura primero" y lista "cuando NO testear". Fuente unica; todo lo demas la referencia.
- **Gate ligero en build skills** (`new-feature`, `create-api`, `new-page`): Paso 0 de clasificacion + consulta a `/mv-dev:test-decision` insertado antes del paso de creacion de tests en cada skill. TDD sigue siendo el default para BET; BUG/trivial dejan de recibir scaffold ciego.
- **Test Decision Gate en `qa-agent`**: seccion nueva que valida que existan los tests *correctos por change-type* (no solo "que haya tests"), con `skills: [test-decision]` en frontmatter.
- **Gate tiered en `validate-pre-push.sh`**: falla solo cuando un cambio de flujo critico (checkout/payment/auth/login/registro/etc.) no tiene cobertura detectable. Cambios no criticos mantienen el flujo permisivo (`--passWithNoTests`).

### Changed
- `skills/mv-testing/SKILL.md`: cross-link al inicio apuntando a `/mv-dev:test-decision` para la decision de que/cuando testear.

## [1.6.0] - 2026-02-24

### Added
- **Flutter Skills Suite**: Agente orquestador `flutter-orchestrator-agent` que coordina desarrollo de apps Flutter
  - `flutter-architecture`: Definir/revisar arquitectura con ventajas y desventajas
  - `flutter-visual-style`: Configurar design system de MV (colores, tipografia, spacing)
  - `flutter-brand-identity`: Revisar identidad de marca (logo, iconos, animaciones)
  - `flutter-new-feature`: Scaffold de features siguiendo arquitectura del proyecto
  - `flutter-new-screen`: Crear pantallas con estados (carga, error, vacio, datos) + widget tests
  - `flutter-component`: Widgets reutilizables con design tokens, variantes y tests
- **BDD Test Generation**: Agente `gherkin-test-generator-agent` para generar tests desde archivos Gherkin
  - `gherkin-to-tests`: Convertir archivos `.feature` a tests ejecutables (Jest, RTL, Playwright)
- Notion Gherkin Agent para obtener requerimientos de Notion y generar archivos `.feature` listos para BDD

### Changed
- Flutter skills activadas automaticamente cuando se detecta trabajo en proyectos Dart/Flutter
- Mejora en arquitectura del plugin para soportar orquestadores de agentes

## [1.5.0] - 2026-02-20

### Added
- Agente Notion Gherkin para extraer requerimientos de Notion y generar archivos Gherkin (.feature)
- Skill `notion-gherkin` para BDD con aceptacion tests

## [1.4.0] - 2026-02-06

### Added
- **SessionStart hook** para deteccion de tokens MCP faltantes al inicio de sesion (`check-mcp-tokens.sh`)
- Sync on demand: la sincronizacion docs/ → Notion ahora se ejecuta tambien cuando el usuario lo pide explicitamente, no solo en git push
- Mapeo explicito de archivos docs/*.md a sub-paginas de Notion
- CHANGELOG.md del plugin

### Changed
- Sync a Notion ahora replica contenido completo como bloques nativos (paragraph + bulleted_list_item) en vez de poner links a GitHub
- Procedimiento de sync reescrito con pasos exactos: get-children → delete-each → patch-new-children
- Incluye ejemplo real de JSON para `API-patch-block-children` con el formato correcto
- Reglas inquebrantables: nunca sugerir alternativas manuales, nunca rendirse, nunca poner links en vez de contenido
- Limite de 100 bloques por llamada documentado con instruccion de dividir en multiples llamadas
- Seccion de sync en `doc-agent.md` y `mv-docs/SKILL.md` completamente reescritas

## [1.3.0] - 2026-02-06

### Added
- MCP server **Notion** oficial para documentacion de proyectos
- MCP server **Supabase** para bases de datos y migraciones
- MCP server **mv-component-analyzer** para analisis de componentes React/Next.js
- Hook de validacion **validate-api-patterns.sh** para endpoints Express
- Hook de validacion **validate-nextjs-patterns.sh** para paginas y componentes
- Agente **doc-agent** con estrategia dual-write (docs/ + Notion)
- Skill **mv-docs** para consulta centralizada de documentacion

### Changed
- Skills actualizados con guias de desarrollo mas claras
- Configuracion de env vars documentada en CLAUDE.md con instrucciones por token

## [1.2.0] - 2026-02-05

### Added
- Variables de entorno para MCP servers (`DB_ACCESS_*`, `CONTEXT7_API_KEY`, `SUPABASE_ACCESS_TOKEN`, `NOTION_TOKEN`)
- Documentacion de setup en CLAUDE.md

## [1.1.0] - 2026-02-04

### Added
- Skills de conocimiento: `mv-api-consumer`, `mv-db-queries`, `mv-design-system`, `mv-testing`, `mv-deployment`
- Skill `start-project` para iniciar proyectos MV
- Skill `new-feature` para scaffold de features
- Skill `new-page` para paginas Next.js
- Skill `create-api` para endpoints Express
- Hook **validate-secrets.sh** para deteccion de credenciales en codigo

## [1.0.0] - 2026-02-04

### Added
- Estructura inicial del plugin mv-dev
- CLAUDE.md con contexto global de Manzana Verde (stack, design tokens, reglas)
- MCP servers: **context7**, **memory-keeper**, **playwright**
- MCP server custom **mv-db-query** para queries de solo lectura a staging
- Scripts de validacion: pre-commit, pre-push, quality-gate
