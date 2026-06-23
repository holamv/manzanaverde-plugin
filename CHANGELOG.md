# Changelog

Todos los cambios notables del plugin mv-dev se documentan aqui.

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
