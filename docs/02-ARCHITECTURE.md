# 🏗️ Arquitectura del Plugin MV Dev

Entendimiento profundo de cómo está estructurado y funciona internamente el plugin.

## 📐 Estructura General

```
manzanaverde-plugin/
├── plugins/mv-dev/
│   ├── .claude-plugin/plugin.json      # Configuración central
│   ├── skills/                         # 12 skills (invocables)
│   ├── agents/                         # 4 agentes (automáticos)
│   ├── servers/                        # 2 MCP servers custom
│   ├── scripts/                        # 6 validaciones (bash)
│   └── templates/                      # Templates de código
│
├── CLAUDE.md                           # Contexto global de MV (auto-loaded)
├── DESIGN_TOKENS.md                    # Design system
└── .claude-plugin/marketplace.json     # Registro en marketplace
```

---

## 🎛️ plugin.json - El Centro de Control

El archivo **`plugins/mv-dev/.claude-plugin/plugin.json`** es el corazón del plugin. Define:

### 1. Metadata
```json
{
  "name": "mv-dev",
  "version": "1.6.0",
  "description": "Plugin de desarrollo...",
  "author": { "name": "Manzana Verde" }
}
```

### 2. Hooks (Validaciones automáticas)
```json
"hooks": {
  "SessionStart": [
    { "command": "check-mcp-tokens.sh" }
  ],
  "PostToolUse": [
    { "matcher": "Write|Edit", "command": "validate-secrets.sh" },
    { "matcher": "*.tsx", "command": "validate-nextjs-patterns.sh" }
  ]
}
```

### 3. MCP Servers (7 conexiones externas)
```json
"mcpServers": {
  "context7": { "command": "context7-wrapper.sh" },
  "notion": { "command": "notion-wrapper.sh" },
  "mv-db-query": { "command": "db-wrapper.sh" },
  ...
}
```

---

## 🎯 Cómo se Carga el Plugin

```
1. Usuario instala: claude plugin add <url>
   ↓
2. Claude Code lee plugin.json
   ↓
3. Carga los 7 MCP servers
   ↓
4. Ejecuta SessionStart hooks (valida tokens)
   ↓
5. Skills están listos para invocar: /mv-dev:discovery
   ↓
6. Agentes esperan eventos (create file, push, etc.)
```

---

## 🎁 Skills - Invocables por el Usuario

**Qué son:** Workflows guiados que el usuario invoca manualmente.

**Cómo funcionan:**
```
Usuario escribe: /mv-dev:start-project
    ↓
Claude carga skill/start-project/SKILL.md
    ↓
Skill hace preguntas (tipo de proyecto, nombre, etc.)
    ↓
Skill ejecuta acciones (crea carpetas, instala dependencias, genera archivos)
    ↓
Resultado: Proyecto completo listo
```

**12 Skills disponibles:**

| Categoría | Skill | Archivo |
|-----------|-------|---------|
| Core | discovery | `skills/discovery/SKILL.md` |
| Core | mv-docs | `skills/mv-docs/SKILL.md` |
| Acción | start-project | `skills/start-project/SKILL.md` |
| Acción | new-feature | `skills/new-feature/SKILL.md` |
| Acción | new-page | `skills/new-page/SKILL.md` |
| Acción | create-api | `skills/create-api/SKILL.md` |
| Acción | deploy-staging | `skills/deploy-staging/SKILL.md` |
| Conocimiento | mv-api-consumer | `skills/mv-api-consumer/SKILL.md` |
| Conocimiento | mv-db-queries | `skills/mv-db-queries/SKILL.md` |
| Conocimiento | mv-design-system | `skills/mv-design-system/SKILL.md` |
| Conocimiento | mv-testing | `skills/mv-testing/SKILL.md` |
| Conocimiento | mv-deployment | `skills/mv-deployment/SKILL.md` |

---

## 🤖 Agentes - Automáticos y Especializados

**Qué son:** Asistentes que se activan automáticamente en ciertos eventos.

**Cómo funcionan:**
```
Usuario crea: components/Button.tsx
    ↓
Plugin detecta evento: "file created *.tsx"
    ↓
Frontend Agent se activa automáticamente
    ↓
Analiza el componente
    ↓
Valida colores, tipografía, accesibilidad
    ↓
Muestra reporte de cumplimiento
```

**4 Agentes:**

| Agente | Archivo | Se activa cuando |
|--------|---------|-----------------|
| QA Agent | `agents/qa-agent.md` | Nuevo archivo `.ts/.tsx`, push |
| Frontend Agent | `agents/frontend-agent.md` | Nuevo archivo `.tsx`, `app/` |
| Backend Agent | `agents/backend-agent.md` | Nuevo archivo `.ts`, `routes/` |
| Doc Agent | `agents/doc-agent.md` | Nueva feature, merge a main |

---

## 🔒 Hooks - Validaciones Automáticas

**Qué son:** Scripts bash que se ejecutan en ciertos momentos del workflow.

**Tipos de hooks:**

### SessionStart (al abrir Claude Code)
```bash
check-mcp-tokens.sh
  → Verifica que CONTEXT7_API_KEY, NOTION_TOKEN, etc. estén configurados
```

### PostToolUse (después de Write/Edit)
```bash
# Para archivos .ts/.tsx/.js/.jsx
validate-secrets.sh
  → Detecta API keys, passwords, tokens hardcodeados

# Para archivos .tsx en app/pages
validate-nextjs-patterns.sh
  → Verifica metadata, next/image, design tokens

# Para archivos .ts en routes/controllers/services
validate-api-patterns.sh
  → Verifica response format, Zod, auth, try/catch
```

### Pre-commit / Pre-push
```bash
validate-pre-commit.sh    → ESLint, Prettier, secrets
validate-pre-push.sh      → TypeScript, tests, build
validate-quality-gate.sh  → Coverage >= 80%
```

---

## 🔌 MCP Servers - Conexiones Externas

**Qué son:** Procesos separados que Claude Code puede invocar para tareas específicas.

**Arquitectura MCP:**
```
Claude Code
    ↓
MCP Client (en el plugin)
    ↓
[TCP/Socket comunicación]
    ↓
MCP Server (proceso separado)
    ↓
Servicio Externo (API, BD, etc.)
```

**5 MCP Servers Externos:**

| Server | Ejecuta | Comunica con |
|--------|---------|-------------|
| context7-wrapper.sh | Wrapper shell | API Context7 |
| notion-wrapper.sh | Wrapper shell | API Notion |
| supabase-wrapper.sh | Wrapper shell | API Supabase |
| @playwright/mcp | NPM package | Browser local |
| mcp-memory-keeper | NPM package | Sistema de archivos |

**2 MCP Servers Custom:**

| Server | Tipo | Ubicación | Comunica con |
|--------|------|----------|-------------|
| mv-db-query | Node.js | `servers/db-wrapper.sh` | MySQL/PostgreSQL |
| mv-component-analyzer | Node.js | `servers/mv-component-analyzer/` | Filesystem (analiza archivos) |

---

## 📦 Servidor MCP Custom: mv-db-query

**Estructura:**
```
servers/mv-component-analyzer/
├── src/index.ts          # Código fuente TypeScript
├── dist/index.js         # Compilado JavaScript
├── package.json
└── tsconfig.json

servers/mv-db-query-server/
├── src/index.ts
├── dist/index.js
├── package.json
└── tsconfig.json
```

**Cómo funciona:**
```
Usuario: SELECT * FROM users LIMIT 10;
    ↓
Claude invoca mv-db-query MCP
    ↓
MCP abre conexión a MySQL/PostgreSQL (vars: DB_ACCESS_*)
    ↓
Valida: ¿Tiene LIMIT? ¿No es tabla bloqueada?
    ↓
Ejecuta query
    ↓
Devuelve resultados
```

**Validaciones de Seguridad:**
- ✅ LIMIT obligatorio
- ✅ Sin DELETE, UPDATE, DROP, ALTER, TRUNCATE
- ✅ Tablas bloqueadas: payments, user_payment_methods, api_keys
- ✅ Log de todas las queries ejecutadas

---

## 📜 Contexto Global: CLAUDE.md

**Qué es:** Archivo de contexto que se carga automáticamente en TODAS las sesiones.

**Ubicación:** `/CLAUDE.md` en la raíz del repositorio

**Contiene:**
- Descripción de Manzana Verde
- Stack tecnológico
- Reglas críticas (NUNCA hacer esto)
- Patrones obligatorios (response format, error handling, auth)
- Design tokens
- Variables de entorno
- Contactos del equipo

**¿Por qué es importante?**
```
Cada vez que abres Claude Code en el repo:
    ↓
Lee CLAUDE.md automáticamente
    ↓
Claude tiene contexto de MV sin tener que preguntar
    ↓
Sigue reglas y patrones automáticamente
```

---

## 🔄 Ciclo de Vida de una Feature

```
1. Usuario: /mv-dev:discovery
   → Usa skill de discovery
   → Busca en Notion (MCP notion)

2. Usuario: /mv-dev:new-feature
   → Inicia skill new-feature
   → Crea estructura (frontend, backend, tests)
   → Agentes se activan automáticamente

3. Implementación
   → PostToolUse hooks validan archivos
   → Frontend Agent valida design system
   → Backend Agent valida APIs
   → QA Agent sugiere tests

4. Usuario: git push
   → Pre-push hooks validan
   → TypeScript compila
   → Tests pasan >= 80%
   → Push exitoso

5. Merge a main
   → Doc Agent actualiza documentación
   → Notion se sincroniza
   → CHANGELOG se actualiza
```

---

## 🛠️ Desarrollo del Plugin

### Agregar un Nuevo Skill

```
1. Crear carpeta: plugins/mv-dev/skills/mi-skill/
2. Crear: plugins/mv-dev/skills/mi-skill/SKILL.md
3. Escribir el skill (prompt, workflow, pasos)
4. Actualizar: .claude-plugin/plugin.json (si es necesario)
5. Probar: /mv-dev:mi-skill
```

### Agregar un Nuevo Hook

```
1. Crear script: plugins/mv-dev/scripts/validate-algo.sh
2. Agregar a plugin.json en la sección "hooks"
3. Definir: matcher (qué archivos), command, description
4. Probar escribiendo/editando un archivo
```

### Agregar un MCP Server Custom

```
1. Crear carpeta: plugins/mv-dev/servers/mi-server/
2. Crear: package.json, src/index.ts
3. Compilar: npm run build
4. Agregar a plugin.json en "mcpServers"
5. Crear wrapper: plugins/mv-dev/servers/mi-wrapper.sh
```

---

## 📊 Diagrama de Flujo General

```
Claude Code inicia
    ↓
SessionStart hooks (check-mcp-tokens.sh)
    ↓
7 MCP Servers se cargan
    ↓
CLAUDE.md se carga automáticamente
    ↓
Usuario listo para:
  ├─ Invocar skills: /mv-dev:*
  ├─ Escribir código (hooks validan)
  ├─ Crear features (agentes se activan)
  └─ Hacer push (validaciones pre-push)
    ↓
Todo sigue reglas de MV automáticamente
```

---

## 🔐 Seguridad

### Dónde se validan secrets?
- `validate-secrets.sh` → Al guardar archivos
- `validate-pre-commit.sh` → Antes de commit
- MCP servers → Nunca exponemos tokens en requests

### Dónde se validan queries?
- `mv-db-query` → Valida LIMIT, tabla bloqueadas
- Logs → Todas las queries se registran

### Dónde se validan patrones?
- `validate-nextjs-patterns.sh` → Rutas Next.js
- `validate-api-patterns.sh` → Endpoints Express
- Agentes → Validación adicional

---

## 📈 Escalabilidad

El plugin está diseñado para escalar:

### Agregar nuevos países
- Actualizar CLAUDE.md con nuevas configuraciones
- Agentes pueden validar por región

### Agregar nuevas tecnologías
- Crear nuevos skills (ej: `/mv-dev:mobile-app` para React Native)
- Crear nuevos agentes especializados
- Crear nuevos hooks de validación

### Agregar nuevas integraciones
- Crear wrappers para nuevos MCP servers
- Agregar conexiones a nuevas APIs

---

**Siguiente:** [Leer sobre Setup →](03-SETUP.md)
