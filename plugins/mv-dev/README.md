# MV Dev - Plugin de Claude Code para Manzana Verde

Plugin completo de desarrollo que permite a cualquier miembro del equipo de Manzana Verde crear proyectos de software de forma segura, consistente y alineada con los estandares de la empresa.

## Instalacion

```bash
claude plugin add https://github.com/manzanaverdelatam/manzanaverde-plugin
```

## Que incluye

### Skills (32)

**Core:**
- `/mv-dev:discovery` - **Descubrimiento tecnico: analiza brief y encuentra APIs, tablas y servicios existentes**
- `/mv-dev:mv-docs` - **Buscar documentacion de APIs y tablas SQL en Notion (fuente de verdad)**
- `/mv-dev:mv-instruction-generator` - Orquesta el workflow tecnico (Discovery, Fix, Sprint o PRD) segun el tipo de request
- `/mv-dev:crear-prd` - Genera un PRD estructurado (8 bloques) para trabajo de código en `docs/prd/CR-<id>.md`; consulta test-decision, no ejecuta código

**Conocimiento:**
- `/mv-dev:mv-api-consumer` - Como consumir APIs de MV correctamente
- `/mv-dev:mv-db-queries` - Queries seguros a la base de datos staging
- `/mv-dev:mv-design-system` - Design system, colores, tipografia, componentes
- `/mv-dev:mv-testing` - Como escribir tests en nuestro stack
- `/mv-dev:mv-deployment` - Procedimientos de deployment

**Accion:**
- `/mv-dev:start-project` - Iniciar nuevo proyecto (Next.js, Express, monorepo)
- `/mv-dev:new-feature` - Scaffold completo de feature
- `/mv-dev:new-page` - Nueva pagina Next.js con metadata y loading states
- `/mv-dev:create-api` - Nuevo endpoint Express con validacion
- `/mv-dev:deploy-staging` - Deploy a staging con verificaciones

**Company Brain (BizOps) — uso estandar para iniciativas medibles:**
> Regla: toda iniciativa/experimento se convierte en fila estructurada del datalake, **siempre vinculada a un KPI o input** del catalogo (`dris_definitions` / `dris_inputs`). No crear iniciativas sueltas fuera de este flujo.
- `/mv-dev:exp-iniciativa` - Crea iniciativa/experimento estructurado + baseline + diseno estadistico; persiste en `experiments` (Supabase) y crea/vincula el Issue en Notion
- `/mv-dev:crear-cr` - Crea Change Requests / tareas con routing a canales Discord reales
- `/mv-dev:editar-experimento` - Edita un experimento existente (link Notion o exp_id) sin re-crearlo; sync tri-destino datalake + Notion + Discord
- `/mv-dev:informe-resultados` - Cierra el ciclo de medicion en la fecha de evaluacion (resultado, impacto, insight)
- `/mv-dev:kpi-context` - Vista 360 de un KPI o input (valores reales, tendencia, feeds cross-KPI). Consultar antes de crear/editar

**Campañas CRM (Growth) — proponer → ejecutar → medir:**
- `/mv-dev:proponer-campana` - Propone campaña completa (público, volumen, horario, copy) desde género + tema
- `/mv-dev:ejecutar-campana` - Ejecuta la campaña (ManyChat WhatsApp/Correo o BackOffice Banner/Modal/Card/Push) y registra el experimento con objetivo explícito
- `/mv-dev:generar-lista-manychat` - Genera insumos ManyChat (CSV opt-in/dedup + JSON con CTA + hora sugerida)

**Testing y BDD (Gherkin):**
- `/mv-dev:notion-gherkin` - Obtiene requerimientos de Notion y genera archivos Gherkin (.feature)
- `/mv-dev:create-feature-file` - Genera un archivo Gherkin BDD desde una feature documentada en Notion
- `/mv-dev:gherkin-to-tests` - Lee archivos .feature y genera tests ejecutables (Jest, RTL, Playwright)
- `/mv-dev:test-decision` - Decide QUE test crear y CUANDO (y cuando no) para un cambio

**Flutter (App Movil):**
- `/mv-dev:flutter-architecture` - Define o revisa la arquitectura del proyecto Flutter
- `/mv-dev:flutter-visual-style` - Configura y valida design tokens, tipografia, colores y estilos
- `/mv-dev:flutter-brand-identity` - Revisa identidad de marca: logo, iconografia, tono, animaciones
- `/mv-dev:flutter-new-feature` - Scaffold completo de una nueva feature Flutter
- `/mv-dev:flutter-new-screen` - Nueva pantalla Flutter con estados de carga/error y widget tests
- `/mv-dev:flutter-component` - Widget reutilizable con design tokens, variantes y tests

### Agentes (4)

- **QA Agent** - Genera tests, valida cobertura, identifica edge cases
- **Frontend Agent** - Verifica cumplimiento del design system, patrones Next.js, accesibilidad
- **Backend Agent** - Valida patrones de API, queries seguras, logica de negocio
- **Doc Agent** - Gestiona documentacion, conexion a Notion

### Hooks de Validacion (6)

Ejecutados automaticamente al escribir/editar archivos:

- `validate-secrets.sh` - Detecta secrets expuestos
- `validate-pre-commit.sh` - Lint y formateo
- `validate-pre-push.sh` - Tests y tipos
- `validate-quality-gate.sh` - Cobertura y build
- `validate-nextjs-patterns.sh` - Patrones Next.js
- `validate-api-patterns.sh` - Patrones Express

### MCP Servers (7)

**Externos (incluidos por defecto):**
- **context7** - Documentacion actualizada de librerias (requiere `CONTEXT7_API_KEY`)
- **memory-keeper** - Memoria persistente entre sesiones de Claude Code
- **playwright** - Automatizacion de browser para testing E2E
- **notion** - Crea, lee y actualiza documentacion de proyectos en Notion (requiere `NOTION_TOKEN`)
- **supabase-mcp** - Gestion completa de Supabase: tablas, migraciones, queries (requiere `SUPABASE_ACCESS_TOKEN`)

**Custom de MV:**
- **mv-db-query** - Queries SQL de solo lectura, MySQL/PostgreSQL (LIMIT obligatorio)
- **mv-component-analyzer** - Analisis de componentes React/Next.js

## Configuracion

**Lee [SETUP.md](SETUP.md) para la guia completa paso a paso.**

Resumen rapido:

1. Obtener tokens de Context7, Notion y Supabase (ver SETUP.md)
2. Agregar las variables a tu `~/.zshrc`:
   ```bash
   export CONTEXT7_API_KEY="ctx7sk-..."
   export NOTION_TOKEN="ntn_..."
   export SUPABASE_ACCESS_TOKEN="sbp_..."
   ```
3. Reiniciar terminal y Claude Code

## Primer uso

```
# Crear un nuevo proyecto frontend
/mv-dev:start-project

# Crear una nueva feature
/mv-dev:new-feature

# Deployar a staging
/mv-dev:deploy-staging
```

## Soporte

Si tienes problemas, contacta al Tech Lead o abre un issue en este repositorio.
