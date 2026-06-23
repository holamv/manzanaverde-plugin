# MV Dev - Plugin de Claude Code para Manzana Verde 

Plugin de Claude Code que permite a cualquier miembro del equipo de Manzana Verde crear proyectos de software de forma segura, consistente y alineada con los estandares de la empresa, sin necesidad de experiencia en programacion.

## Que hace este plugin

- **Genera proyectos completos** con un solo comando (`/mv-dev:start-project`)
- **Aplica automaticamente** los estandares de codigo, design system y patrones de MV
- **Valida en tiempo real** que no se expongan secrets, se sigan patrones correctos y se mantenga calidad
- **Conecta herramientas** como Notion, Supabase, base de datos staging y documentacion de librerias
- **Incluye agentes especializados** en QA, frontend, backend y documentacion

## Instalacion

```bash
claude plugin add https://github.com/manzanaverde/manzanaverde-plugin
```

## Configuracion de tokens

Algunos MCP servers requieren tokens. Sigue la guia completa en [SETUP.md](plugins/mv-dev/SETUP.md).

Resumen rapido:

**Mac / Linux** - agregar a tu `~/.zshrc` o `~/.bashrc`:

```bash
# MCP Servers
export CONTEXT7_API_KEY="ctx7sk-..."    # context7.com/dashboard
export NOTION_TOKEN="ntn_..."           # notion.so/my-integrations
export SUPABASE_ACCESS_TOKEN="sbp_..."  # supabase.com/dashboard

# Base de datos (pedir al Tech Lead)
export DB_ACCESS_TYPE="mysql"      # mysql | postgres
export DB_ACCESS_HOST="..."
export DB_ACCESS_PORT="3306"       # 3306 para MySQL, 5432 para PostgreSQL
export DB_ACCESS_USER="..."
export DB_ACCESS_PASSWORD="..."
export DB_ACCESS_NAME="..."
```

Luego `source ~/.zshrc` y reiniciar Claude Code.

**Windows (PowerShell)** - agregar a tu perfil de PowerShell (`$PROFILE`):

```powershell
# MCP Servers
$env:CONTEXT7_API_KEY = "ctx7sk-..."
$env:NOTION_TOKEN = "ntn_..."
$env:SUPABASE_ACCESS_TOKEN = "sbp_..."

# Base de datos (pedir al Tech Lead)
$env:DB_ACCESS_TYPE = "mysql"
$env:DB_ACCESS_HOST = "..."
$env:DB_ACCESS_PORT = "3306"
$env:DB_ACCESS_USER = "..."
$env:DB_ACCESS_PASSWORD = "..."
$env:DB_ACCESS_NAME = "..."
```

Para que persistan, agregar al archivo de perfil: `notepad $PROFILE` (crear si no existe), pegar las lineas, guardar y reiniciar la terminal.

**Alternativa Windows:** Usar variables de entorno del sistema: `Configuracion` > `Sistema` > `Acerca de` > `Configuracion avanzada del sistema` > `Variables de entorno` > `Nueva` (en Variables de usuario).

## Uso rapido

```
# Descubrir APIs y tablas existentes antes de empezar
/mv-dev:discovery

# Crear un nuevo proyecto MV
/mv-dev:start-project

# Crear una nueva feature con TDD
/mv-dev:new-feature

# Crear una pagina Next.js
/mv-dev:new-page

# Crear un endpoint Express
/mv-dev:create-api

# Deployar a staging
/mv-dev:deploy-staging
```

## Que incluye

### Skills (12)

| Comando | Tipo | Descripcion |
|---------|------|-------------|
| `/mv-dev:discovery` | **Core** | **Descubrimiento tecnico: analiza brief y encuentra APIs, tablas y servicios existentes** |
| `/mv-dev:mv-docs` | **Core** | **Buscar documentacion de APIs y tablas SQL en Notion (fuente de verdad)** |
| `/mv-dev:start-project` | Accion | Iniciar proyecto Next.js, Express o monorepo |
| `/mv-dev:new-feature` | Accion | Scaffold completo de feature con TDD |
| `/mv-dev:new-page` | Accion | Nueva pagina Next.js con metadata y loading states |
| `/mv-dev:create-api` | Accion | Nuevo endpoint Express con validacion Zod |
| `/mv-dev:deploy-staging` | Accion | Deploy a staging con pre-flight checks |
| `/mv-dev:mv-api-consumer` | Conocimiento | Como consumir APIs de MV correctamente |
| `/mv-dev:mv-db-queries` | Conocimiento | Queries seguros a la base de datos staging |
| `/mv-dev:mv-design-system` | Conocimiento | Design system, colores, tipografia, componentes |
| `/mv-dev:mv-testing` | Conocimiento | Como escribir tests en nuestro stack |
| `/mv-dev:mv-deployment` | Conocimiento | Procedimientos de deployment |

### Agentes (4)

| Agente | Funcion |
|--------|---------|
| **QA Agent** | Genera tests, valida cobertura >= 80%, identifica edge cases |
| **Frontend Agent** | Verifica design system, patrones Next.js, accesibilidad |
| **Backend Agent** | Valida patrones de API, queries seguras, logica de negocio |
| **Doc Agent** | Gestiona documentacion local y conexion a Notion |

### Hooks de Validacion (6)

Se ejecutan automaticamente al escribir o editar archivos:

| Hook | Trigger | Que valida |
|------|---------|------------|
| `validate-secrets.sh` | `.ts/.tsx/.js/.jsx` | API keys, passwords, tokens, connection strings |
| `validate-pre-commit.sh` | Pre-commit | ESLint, Prettier, secrets |
| `validate-pre-push.sh` | Pre-push | TypeScript types, tests |
| `validate-quality-gate.sh` | Quality gate | Cobertura >= 80%, build exitoso |
| `validate-nextjs-patterns.sh` | Paginas `.tsx` | Metadata, next/image, design tokens, 'use client' |
| `validate-api-patterns.sh` | Routes/controllers `.ts` | Response format, try/catch, Zod, auth middleware |

### MCP Servers (7)

**Externos (incluidos por defecto):**

| Server | Requiere token | Descripcion |
|--------|---------------|-------------|
| Context7 | `CONTEXT7_API_KEY` | Documentacion actualizada de librerias |
| Memory Keeper | No | Memoria persistente entre sesiones |
| Playwright | No | Automatizacion de browser para E2E |
| Notion | `NOTION_TOKEN` | Crea, lee y actualiza documentacion de proyectos en Notion |
| Supabase | `SUPABASE_ACCESS_TOKEN` | Gestion completa de Supabase (tablas, migraciones, queries) |

**Custom de MV:**

| Server | Descripcion |
|--------|-------------|
| mv-db-query | Queries SQL de solo lectura (MySQL/PostgreSQL, LIMIT obligatorio) |
| mv-component-analyzer | Analisis de componentes React/Next.js |

## Estructura del proyecto

```
manzanaverde-plugin/
├── .claude-plugin/
│   └── marketplace.json           # Registro en marketplace
├── CLAUDE.md                      # Contexto global MV (auto-cargado)
├── DESIGN_TOKENS.md               # Design system completo
├── README.md                      # Este archivo
│
└── plugins/mv-dev/
    ├── .claude-plugin/
    │   └── plugin.json            # Metadata, hooks, MCP servers
    ├── README.md                  # Documentacion del plugin
    ├── SETUP.md                   # Guia de configuracion de tokens
    ├── ARCHITECTURE.md            # Arquitectura del plugin
    ├── CODE_STANDARDS.md          # Estandares de codigo MV
    │
    ├── skills/                    # 12 skills invocables
    │   ├── discovery/             # Core: descubrimiento tecnico pre-proyecto
    │   ├── start-project/
    │   ├── new-feature/
    │   ├── new-page/
    │   ├── create-api/
    │   ├── deploy-staging/
    │   ├── mv-docs/               # Core: lookup de APIs y tablas en Notion
    │   ├── mv-api-consumer/
    │   ├── mv-db-queries/
    │   ├── mv-design-system/
    │   ├── mv-testing/
    │   └── mv-deployment/
    │
    ├── agents/                    # 4 agentes especializados
    │   ├── qa-agent.md
    │   ├── frontend-agent.md
    │   ├── backend-agent.md
    │   └── doc-agent.md
    │
    ├── scripts/                   # 6 scripts de validacion (bash)
    │   ├── validate-secrets.sh
    │   ├── validate-pre-commit.sh
    │   ├── validate-pre-push.sh
    │   ├── validate-quality-gate.sh
    │   ├── validate-nextjs-patterns.sh
    │   └── validate-api-patterns.sh
    │
    ├── servers/                   # 2 MCP servers custom (TypeScript)
    │   ├── mv-db-query-server/
    │   └── mv-component-analyzer/
    │
    └── templates/
        └── pr-template.md         # Template estandar de PR
```

## Stack soportado

| Tecnologia | Version |
|------------|---------|
| Next.js | 14+ (App Router) |
| React | 18+ |
| TypeScript | 5+ (strict mode) |
| Tailwind CSS | v4 |
| Node.js | 20 LTS |
| Express | 4.x |
| MySQL/MariaDB | 8.0 |

## Documentacion

| Documento | Contenido |
|-----------|-----------|
| [SETUP.md](plugins/mv-dev/SETUP.md) | Configuracion de tokens paso a paso |
| [ARCHITECTURE.md](plugins/mv-dev/ARCHITECTURE.md) | Arquitectura del plugin |
| [CODE_STANDARDS.md](plugins/mv-dev/CODE_STANDARDS.md) | Estandares de codigo de MV |
| [DESIGN_TOKENS.md](DESIGN_TOKENS.md) | Design system completo |
| [CLAUDE.md](CLAUDE.md) | Contexto global (auto-cargado por Claude Code) |

## Seguridad

- Los hooks detectan **automaticamente** secrets expuestos y bloquean la operacion
- Las queries a base de datos son **solo lectura** con LIMIT obligatorio
- Las tablas sensibles (`payments`, `user_payment_methods`, etc.) estan **bloqueadas**
- Supabase tiene acceso completo pero los tokens nunca se exponen en el codigo
- Los tokens nunca se commitean: se cargan desde variables de entorno

## Soporte

Si tienes problemas con la configuracion o el plugin:

1. Lee [SETUP.md](plugins/mv-dev/SETUP.md) para la guia de configuracion
2. Consulta con el Tech Lead
3. Abre un issue en este repositorio
