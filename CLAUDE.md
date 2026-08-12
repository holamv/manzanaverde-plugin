# Manzana Verde - Contexto Global para Claude Code

## Sobre Manzana Verde

Manzana Verde es una empresa de **delivery de comida saludable** por suscripcion. Operamos en **Peru, Colombia, Mexico y Chile**. Modelo B2C: los usuarios se suscriben a planes de alimentacion y reciben comidas preparadas en su domicilio.

**Producto principal:** Planes semanales de comidas saludables (desayuno, almuerzo, cena, snacks) con delivery diario.

**Canales:** App movil, web app, WhatsApp (pedidos rapidos), panel de administracion.

---

## Stack Tecnologico

| Tecnologia | Version | Uso |
|------------|---------|-----|
| **Next.js** | 14+ (App Router) | Frontend de todos los proyectos web |
| **React** | 18+ | UI components |
| **TypeScript** | 5+ | Lenguaje principal (strict mode obligatorio) |
| **Tailwind CSS** | v4 | Estilos con `@theme inline` y tokens MV |
| **Node.js** | 20 LTS | Runtime backend |
| **Express** | 4.x | Framework backend (cuando se requiere backend pesado) |
| **MySQL/MariaDB** | 8.0 | Base de datos |
| **Vercel** | — | Hosting frontend, preview deploys |
| **Railway** | — | Hosting backend |
| **GitHub** | — | Control de versiones |
| **Zod** | 3+ | Validacion de schemas |
| **Jest** | 29+ | Unit testing |
| **React Testing Library** | 14+ | Testing de componentes |
| **Playwright** | 1.40+ | E2E testing |
| **Lucide React** | latest | Iconografia |

### Patron de proyecto

- **Solo frontend:** Next.js + Vercel
- **Frontend + backend pesado:** Monorepo con `packages/frontend` (Next.js) + `packages/backend` (Express) + `packages/shared` (tipos)
- **Deployment:** Vercel para frontend, Railway para backend

---

## Repositorios

| Repo | Descripcion | Stack |
|------|-------------|-------|
| `mv-landing-pedidos` | Landing page de pedidos via WhatsApp | Next.js + Vercel |
| `mv-web-app` | App web principal (planes, pedidos, perfil) | Next.js + Vercel |
| `mv-admin-panel` | Panel de administracion interno | Next.js + Vercel |
| `mv-mobile-app` | App movil (futuro - excluido del plugin) | React Native + Expo |

---

## Reglas Criticas - NUNCA hacer esto

1. **NUNCA** hacer queries a la base de datos de **produccion**. Solo staging.
2. **NUNCA** exponer API keys, passwords, connection strings o secrets en el codigo.
3. **NUNCA** hacer push directo a la rama `main`. Siempre usar branches y PRs.
4. **NUNCA** deployar a produccion sin code review aprobado.
5. **NUNCA** usar el tipo `any` en TypeScript. Usar tipos especificos o `unknown`.
6. **NUNCA** commitear archivos `.env` o con credenciales.
7. **NUNCA** ejecutar `DELETE`, `UPDATE`, `DROP`, `ALTER`, `TRUNCATE` en ninguna base de datos.
8. **NUNCA** deshabilitar ESLint, TypeScript strict mode o checks de seguridad.
9. **NUNCA** hardcodear colores hex en componentes. Usar los design tokens de MV.
10. **NUNCA** hacer `SELECT *` sin `LIMIT` en queries a la base de datos.

---

## Patrones Obligatorios

### Respuestas de API

Todas las APIs de MV usan este formato estandar:

```typescript
interface ApiResponse<T> {
  success: boolean;
  data: T;
  error?: string;
  meta?: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}
```

### Manejo de Errores

```typescript
try {
  const result = await someOperation();
  return { success: true, data: result };
} catch (error) {
  console.error('[ModuleName] Error description:', error);
  return { success: false, data: null, error: 'User-friendly error message' };
}
```

### Autenticacion

- JWT con refresh tokens
- Header: `Authorization: Bearer <token>`
- Middleware `requireAuth` en todas las rutas protegidas

### Convenciones

- **Fechas:** Almacenar en UTC, mostrar en timezone del usuario
- **Dinero:** Almacenar en centavos (integer), formatear para display
- **Idioma:** Strings de UI en espanol, codigo y variables en ingles
- **Archivos:** camelCase para archivos, PascalCase para componentes React
- **Branches:** `feature/nombre-corto`, `fix/nombre-corto`, `hotfix/nombre-corto`
- **Docs auto-update:** Despues de cada tarea completada, SIEMPRE actualizar `docs/` con: nuevos componentes, APIs consumidas, estructura actual, estado de funcionalidades (✅ done, 🚧 WIP, ❌ pendiente). Si `docs/` no existe, crearlo. **`docs/PROJECT_SCOPE.md` se actualiza en CADA tarea** (version, estado, funcionalidades, estructura de archivos).
- **Docs sync:** Al hacer `git push`, sincronizar `docs/` a Notion automaticamente (si `NOTION_TOKEN` esta configurado)

---

## Design Tokens de MV

### Colores principales

| Token | Hex | Uso |
|-------|-----|-----|
| `mv-green-500` | `#227A4B` | **Color primario de marca** |
| `mv-green-600` | `#1D6A41` | Hover de botones primarios |
| `mv-green-700` | `#185A37` | Active/pressed |
| `mv-green-50` | `#E8F5EC` | Fondos sutiles primarios |
| `mv-orange-500` | `#E85D04` | **Color secundario** (badges, alerts) |
| `mv-yellow-500` | `#E5B83C` | **Color terciario** (promos, highlights) |
| `mv-gray-900` | `#171717` | **Texto principal** |
| `mv-gray-500` | `#737373` | Texto secundario/muted |
| `mv-gray-200` | `#E8E8E8` | Bordes estandar |
| `mv-gray-50` | `#FAFAFA` | Fondo de pagina |

### Colores semanticos

| Estado | Hex |
|--------|-----|
| Success | `#227A4B` (mv-green-500) |
| Warning | `#E85D04` (mv-orange-500) |
| Error | `#DC2626` |
| Info | `#0EA5E9` |

### Tipografia

- **Headings:** Inter (400-800)
- **Body/UI:** Nunito (400-700)
- **Import:** `https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Nunito:wght@400;500;600;700&display=swap`

### Tailwind v4 Theme

```css
@theme inline {
  --color-primary: var(--mv-green-500);
  --color-primary-hover: var(--mv-green-600);
  --color-primary-light: var(--mv-green-50);
  --color-mv-green: var(--mv-green-500);
  --color-mv-orange: var(--mv-orange-500);
  --color-mv-yellow: var(--mv-yellow-500);
}
```

### Componentes UI base

- **Botones:** `rounded-xl`, gradiente `from-[#227A4B] to-[#1D6A41]`, shadow-primary
- **Cards:** `rounded-2xl`, bg-white, shadow-sm, border mv-gray-200
- **Inputs:** `rounded-md`, border mv-gray-200, focus border-primary
- **Border radius base:** 12px (`rounded-xl`)
- **Spacing base:** 4px multiplos
- **Iconos:** Lucide React

---

## Variables de Entorno

Estas variables deben configurarse en `.env.local` (NUNCA commitear):

```bash
# Base de datos (solo lectura)
DB_ACCESS_TYPE=            # mysql | postgres (default: mysql)
DB_ACCESS_HOST=            # Host de la base de datos
DB_ACCESS_PORT=3306        # Puerto (3306 MySQL, 5432 PostgreSQL)
DB_ACCESS_USER=            # Usuario de solo lectura
DB_ACCESS_PASSWORD=        # Password
DB_ACCESS_NAME=            # Nombre de la base de datos

# APIs
MV_STAGING_API_URL=        # URL base de API staging
MV_API_KEY=                # API key para staging

# MCP Servers (ver SETUP.md para obtener estos tokens)
CONTEXT7_API_KEY=          # API key de Context7 (context7.com/dashboard)
NOTION_TOKEN=              # Token de integracion de Notion (notion.so/my-integrations)
SUPABASE_ACCESS_TOKEN=     # Access token de Supabase (supabase.com/dashboard)

# Deployment
VERCEL_TOKEN=              # Token de Vercel para deploys
RAILWAY_TOKEN=             # Token de Railway para deploys
```

---

## Contactos del Equipo

<!-- TODO: Llenar con contactos reales -->

| Area | Rol | Contacto |
|------|-----|----------|
| Arquitectura | Tech Lead | _por definir_ |
| Producto | Product Manager | _por definir_ |
| Diseno | UI/UX Lead | _por definir_ |
| Infraestructura | DevOps | _por definir_ |
| Backend | Backend Lead | _por definir_ |
| Frontend | Frontend Lead | _por definir_ |

---

## Tokens no configurados - Guia al usuario

Si el usuario intenta usar una funcionalidad que requiere un token no configurado, **NO fallar silenciosamente**. Explicar claramente que necesita y como configurarlo:

### Notion (`NOTION_TOKEN`)
Se necesita para: buscar documentacion de APIs y tablas (`/mv-dev:mv-docs`), documentar proyectos, sincronizar docs, leer documentacion existente.
```
Para usar Notion necesitas configurar el token:

1. Ir a https://www.notion.so/my-integrations
2. Crear integracion "MV Claude Code" con permisos de Read + Update + Insert
3. Copiar el token (formato: ntn_...)
4. Agregar la variable de entorno:
   Mac/Linux  → ~/.zshrc:    export NOTION_TOKEN="ntn_tu-token"
   Windows PS → $PROFILE:    $env:NOTION_TOKEN = "ntn_tu-token"
5. Recargar terminal (source ~/.zshrc | reiniciar PowerShell)
6. Reiniciar Claude Code

Guia completa: ver SETUP.md del plugin (seccion 2)
```

### MV Brain (`MV_BRAIN_TOKEN`)
Se necesita para: los skills del Company Brain (`/mv-dev:crear-cr`, `/mv-dev:exp-iniciativa`, `/mv-dev:kpi-context`, `/mv-dev:editar-experimento`, `/mv-dev:informe-resultados`, `/mv-dev:research-mv`, campanas). Sin este token, esos skills se detienen con 401 en el primer paso — no hay fallback.
```
Para usar los skills del Company Brain necesitas tu token personal:

1. Solicitarlo a BizOps (Julio) por canal privado (Slack DM o correo) —
   no se comparte por Discord ni se publica en ningun repo.
2. El token se entrega una sola vez (formato: mvb_...) — guardalo en tu
   gestor de contrasenas.
3. Agregar la variable de entorno:
   Mac/Linux  → ~/.zshrc:    export MV_BRAIN_TOKEN="mvb_tu-token"
   Windows PS → $PROFILE:    $env:MV_BRAIN_TOKEN = "mvb_tu-token"
4. Recargar terminal (source ~/.zshrc | reiniciar PowerShell)
5. Reiniciar Claude Code

Guia completa: ver SETUP.md del plugin (seccion 3)
```

### Supabase (`SUPABASE_ACCESS_TOKEN`)
Se necesita para: consultar bases de datos Supabase.
```
Para usar Supabase necesitas configurar el token:

1. Ir a https://supabase.com/dashboard
2. Click en tu avatar → Account Preferences → Access Tokens
3. Generar token y copiarlo (formato: sbp_...)
4. Agregar la variable de entorno:
   Mac/Linux  → ~/.zshrc:    export SUPABASE_ACCESS_TOKEN="sbp_tu-token"
   Windows PS → $PROFILE:    $env:SUPABASE_ACCESS_TOKEN = "sbp_tu-token"
5. Recargar terminal (source ~/.zshrc | reiniciar PowerShell)
6. Reiniciar Claude Code

Guia completa: ver SETUP.md del plugin (seccion 4)
```

### Base de datos (`DB_ACCESS_*`)
Se necesita para: queries directos a MySQL o PostgreSQL via el MCP server mv-db-query.
```
Para conectarte a una base de datos necesitas configurar las credenciales:

1. Pedir las credenciales al Tech Lead
2. Agregar las variables de entorno:

   Mac/Linux → ~/.zshrc o .env del proyecto:
     export DB_ACCESS_TYPE="mysql"   # mysql | postgres
     export DB_ACCESS_HOST="..."
     export DB_ACCESS_PORT="3306"    # 3306 MySQL, 5432 PostgreSQL
     export DB_ACCESS_USER="..."
     export DB_ACCESS_PASSWORD="..."
     export DB_ACCESS_NAME="..."

   Windows PS → $PROFILE:
     $env:DB_ACCESS_TYPE = "mysql"
     $env:DB_ACCESS_HOST = "..."
     $env:DB_ACCESS_PORT = "3306"
     $env:DB_ACCESS_USER = "..."
     $env:DB_ACCESS_PASSWORD = "..."
     $env:DB_ACCESS_NAME = "..."

3. Recargar terminal (source ~/.zshrc | reiniciar PowerShell)
4. Reiniciar Claude Code

Guia completa: ver SETUP.md del plugin (seccion Servidores custom)
```

### Context7 (`CONTEXT7_API_KEY`)
Se necesita para: documentacion actualizada de librerias (funciona sin key pero con rate limits).
```
Para usar Context7 sin limites:

1. Ir a https://context7.com/dashboard
2. Crear cuenta y generar API key (formato: ctx7sk-...)
3. Agregar la variable de entorno:
   Mac/Linux  → ~/.zshrc:    export CONTEXT7_API_KEY="ctx7sk-tu-key"
   Windows PS → $PROFILE:    $env:CONTEXT7_API_KEY = "ctx7sk-tu-key"
4. Recargar terminal (source ~/.zshrc | reiniciar PowerShell)
5. Reiniciar Claude Code

Guia completa: ver SETUP.md del plugin (seccion 1)
```

---

## Skills Disponibles del Plugin

| Comando | Descripcion |
|---------|-------------|
| `/mv-dev:discovery` | **Descubrimiento tecnico: analiza brief de negocio y encuentra APIs, tablas y servicios existentes** |
| `/mv-dev:mv-docs` | **Buscar documentacion de APIs y tablas SQL en Notion (fuente de verdad)** |
| `/mv-dev:start-project` | Iniciar un nuevo proyecto MV (Next.js, Express, o monorepo) |
| `/mv-dev:new-feature` | Scaffold completo de una nueva feature |
| `/mv-dev:new-page` | Crear una nueva pagina Next.js |
| `/mv-dev:create-api` | Crear un nuevo endpoint de API Express |
| `/mv-dev:deploy-staging` | Deployar a staging con pre-flight checks |
| `/mv-dev:mv-api-consumer` | Guia para consumir APIs de MV correctamente |
| `/mv-dev:mv-db-queries` | Guia para hacer queries seguros a staging |
| `/mv-dev:mv-design-system` | Referencia del design system de MV |
| `/mv-dev:mv-testing` | Guia para escribir tests en el stack de MV |
| `/mv-dev:mv-deployment` | Procedimientos de deployment |
| `/mv-dev:notion-gherkin` | **Obtener requerimientos de Notion y generar archivos Gherkin (.feature) listos para BDD** |
| `/mv-dev:gherkin-to-tests` | **Leer archivos Gherkin (.feature) de features/ y generar tests ejecutables (Jest, RTL, Playwright) por tipo de escenario** |

### Skills Flutter (App Movil)

> **Nota:** El agente `flutter-orchestrator-agent` se activa automaticamente cuando detecta trabajo en proyectos Flutter/Dart y coordina los siguientes skills.

| Comando | Descripcion |
|---------|-------------|
| `/mv-dev:flutter-architecture` | **Definir o revisar la arquitectura del proyecto Flutter - muestra opciones con ventajas y desventajas** |
| `/mv-dev:flutter-visual-style` | **Configurar y auditar el design system de MV en Flutter - colores, tipografia, spacing, border radius** |
| `/mv-dev:flutter-brand-identity` | **Revisar identidad de marca en Flutter - logo, iconos, tono del texto, animaciones, splash screen** |
| `/mv-dev:flutter-new-feature` | Scaffold completo de una nueva feature en Flutter siguiendo la arquitectura del proyecto |
| `/mv-dev:flutter-new-screen` | Crear una nueva pantalla Flutter con todos los estados (carga, error, vacio, datos) y widget tests |
| `/mv-dev:flutter-component` | Crear un widget reutilizable con design tokens de MV, variantes y tests |
