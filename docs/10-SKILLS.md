# 🎯 Skills del Plugin MV Dev

El plugin incluye **12 skills** organizados en 3 categorías: Core, Acción y Conocimiento.

## 📍 Mapa de Skills

### Core (2) - Comienza aquí
- [`/mv-dev:discovery`](#discovery) - Descubrimiento técnico pre-proyecto
- [`/mv-dev:mv-docs`](#mv-docs) - Buscar documentación en Notion

### Acción (5) - Crear cosas
- [`/mv-dev:start-project`](#start-project) - Nuevo proyecto
- [`/mv-dev:new-feature`](#new-feature) - Nueva feature
- [`/mv-dev:new-page`](#new-page) - Nueva página Next.js
- [`/mv-dev:create-api`](#create-api) - Nuevo endpoint Express
- [`/mv-dev:deploy-staging`](#deploy-staging) - Deploy a staging

### Conocimiento (5) - Referencia
- [`/mv-dev:mv-api-consumer`](#mv-api-consumer) - Cómo consumir APIs
- [`/mv-dev:mv-db-queries`](#mv-db-queries) - Queries a base de datos
- [`/mv-dev:mv-design-system`](#mv-design-system) - Design system
- [`/mv-dev:mv-testing`](#mv-testing) - Estrategia de testing
- [`/mv-dev:mv-deployment`](#mv-deployment) - Procedimientos de deployment

---

## Core Skills

### discovery
**Descripción:** Analiza un brief de negocio y descubre APIs, tablas, servicios y patrones existentes antes de empezar a codificar.

**Cuándo usarlo:**
- Antes de crear un proyecto nuevo
- Cuando necesitas entender qué servicios existen
- Para evitar duplicar funcionalidad

**Requisitos:**
- `NOTION_TOKEN` (recomendado para acceder a docs)

**Ejemplo:**
```
Quiero crear una página que muestre el historial de pedidos del usuario.
Ejecuto: /mv-dev:discovery
```

El skill:
1. Analiza tu brief
2. Busca APIs relacionadas en Notion
3. Identifica tablas de base de datos
4. Lista servicios y endpoints existentes
5. Te muestra patrones de cómo se hace en el código actual

**Output típico:**
```
📋 Análisis de Requerimientos:
- Mostrar pedidos pasados del usuario
- Filtrar por estado, fecha, rango de precio
- Integración con API /orders/history

🔍 Servicios Existentes:
✅ OrderService en packages/backend/services/orders.ts
✅ Endpoint GET /api/orders/history
✅ OrderDTO en packages/shared/types/orders.ts

📊 Tablas BD:
- orders (id, user_id, status, created_at, total)
- order_items (id, order_id, product_id, quantity)

⚠️ Consideraciones:
- La API ya existe, solo necesitas una página
- Usa el OrderService existente
- Sigue el patrón en pages/orders.tsx
```

---

### mv-docs
**Descripción:** Busca documentación de APIs y tablas SQL en Notion, la fuente de verdad de Manzana Verde.

**Cuándo usarlo:**
- Necesitas entender una API existente
- Necesitas ver la estructura de una tabla
- Buscas ejemplos de cómo usar un servicio

**Requisitos:**
- `NOTION_TOKEN` configurado
- Notion debe estar actualizado

**Ejemplo:**
```
¿Cómo se usa la API de pagos?
Ejecuto: /mv-dev:mv-docs
Busco: "payments API"
```

**Output típico:**
```
🔍 Resultados en Notion:

📌 Payments API (v2.1)
Endpoint: POST /api/payments
Auth: Bearer token
Body: {
  order_id: string,
  method: "card" | "upi",
  amount: number (centavos)
}
Response: {
  success: boolean,
  transaction_id: string,
  status: "pending" | "success" | "failed"
}

Ejemplos: [link a Notion]
```

---

## Skills de Acción

### start-project
**Descripción:** Crea un nuevo proyecto MV completo (Next.js frontend, Express backend, o monorepo).

**Cuándo usarlo:**
- Crear un nuevo proyecto web
- Crear un nuevo servicio backend
- Crear un monorepo con múltiples paquetes

**Requisitos:**
- Ninguno especial
- Recomendado: haber corrido `/mv-dev:discovery` primero

**Workflow:**
1. Responde qué tipo de proyecto (frontend/backend/monorepo)
2. Define el nombre del proyecto
3. El skill crea:
   - Estructura de carpetas
   - package.json con dependencias MV
   - TypeScript config (strict mode)
   - Tailwind CSS config
   - ESLint y Prettier configurados
   - Archivos README y documentación
   - Estructura de tests (Jest, RTL, Playwright)

**Ejemplo:**
```
Quiero crear una app web para reportes
/mv-dev:start-project
  → Tipo: Next.js (frontend)
  → Nombre: mv-reports-app
  → Descripción: Dashboard de reportes en tiempo real

El plugin crea mv-reports-app/ con:
- app/ (App Router Next.js)
- components/ (UI components)
- __tests__/ (Jest + RTL)
- tailwind.config.ts
- types.ts (tipos globales)
```

---

### new-feature
**Descripción:** Crea una nueva feature con estructura completa: componentes, servicios, tests, tipos.

**Cuándo usarlo:**
- Implementar una feature nueva
- Agregar funcionalidad existente
- Escalar una feature a más complejidad

**Requisitos:**
- Estar dentro de un proyecto MV
- Feature debe tener un objetivo claro

**Workflow:**
1. Define el nombre de la feature
2. Define la descripción (qué hace)
3. Selecciona el scope (frontend/backend/ambos)
4. El skill genera:
   - Componentes React con tests
   - Servicios/lógica de negocio
   - API endpoints si es necesario
   - Tests con cobertura >= 80%
   - Documentación

**Ejemplo:**
```
Quiero agregar filtros avanzados de búsqueda
/mv-dev:new-feature
  → Nombre: Advanced Search
  → Descripción: Filtrar productos por múltiples criterios
  → Scope: Frontend (componentes + servicios)

Genera:
- components/SearchFilters.tsx
- components/__tests__/SearchFilters.test.tsx
- services/searchService.ts
- types/search.ts
- docs/FEATURE.md
```

---

### new-page
**Descripción:** Crea una página Next.js nueva con todos los estados (carga, error, datos, vacío).

**Cuándo usarlo:**
- Crear una página nueva en Next.js
- Agregar ruta nueva con metadata y loading

**Requisitos:**
- Proyecto Next.js con App Router

**Genera:**
- `app/[nombre]/page.tsx` con componentes
- `app/[nombre]/loading.tsx` (skeleton/loader)
- `app/[nombre]/error.tsx` (error boundary)
- `app/[nombre]/layout.tsx` si es necesario
- Tests con RTL
- Metadata dinámico

**Ejemplo:**
```
/mv-dev:new-page
  → Ruta: /orders/history
  → Tipo: Cliente (mostrar órdenes del usuario)
  → Con filtros: sí

Genera:
- app/orders/history/page.tsx
- app/orders/history/loading.tsx
- app/orders/history/error.tsx
- __tests__/OrdersHistory.test.tsx
```

---

### create-api
**Descripción:** Crea un nuevo endpoint Express con validación Zod, autenticación y manejo de errores.

**Cuándo usarlo:**
- Crear un nuevo endpoint REST
- Exponer una funcionalidad backend

**Requisitos:**
- Proyecto Express backend
- Método HTTP claro (GET, POST, etc.)

**Genera:**
- Ruta en `routes/` con validación Zod
- Controlador en `controllers/`
- Servicio en `services/` con lógica
- Tipos en `types/`
- Tests con Jest
- Error handling estándar

**Ejemplo:**
```
/mv-dev:create-api
  → Endpoint: POST /api/orders
  → Descripción: Crear una nueva orden
  → Auth: Requerido
  → Query params: order_items[], delivery_date

Genera:
- routes/orders.ts
- controllers/ordersController.ts
- services/ordersService.ts
- types/order.ts
- __tests__/orders.test.ts
```

---

### deploy-staging
**Descripción:** Prepara y despliega cambios a staging con validaciones automáticas.

**Cuándo usarlo:**
- Deployar cambios a ambiente de staging
- Antes de deployar a producción
- Para testing en un ambiente real

**Validaciones automáticas:**
- ✅ TypeScript compila sin errores
- ✅ Tests pasan (cobertura >= 80%)
- ✅ ESLint pasa
- ✅ No hay secrets expuestos
- ✅ Build es exitoso

**Ejemplo:**
```
/mv-dev:deploy-staging
  → Rama: feat/advanced-search
  → Descripción: Agregar filtros avanzados

Checks:
✅ TypeScript compile
✅ Tests pass (92% coverage)
✅ ESLint pass
✅ Build success
✅ No secrets detected

Desplegando a Vercel/Railway...
✅ Deployed! URL: https://staging-xyz.vercel.app
```

---

## Skills de Conocimiento

Estos skills son **referencia**, no ejecutan acciones:

### mv-api-consumer
**Qué enseña:** Cómo consumir APIs de MV correctamente desde el frontend.

**Temas:**
- Autenticación con Bearer token
- Manejo de errores
- Interceptores HTTP
- Retry logic
- Rate limiting
- Ejemplos con fetch y axios

---

### mv-db-queries
**Qué enseña:** Cómo hacer queries seguros a la base de datos de staging.

**Temas:**
- Conexión segura a staging
- LIMIT obligatorio
- Evitar SELECT *
- Tablas bloqueadas
- Ejemplos con MySQL y PostgreSQL

---

### mv-design-system
**Qué enseña:** Colores, tipografía, espaciado, componentes del design system.

**Incluye:**
- Paleta de colores completa
- Tipografía (Inter, Nunito)
- Border radius
- Spacing base
- Componentes base (botones, inputs, cards)
- Ejemplos de uso en Tailwind

---

### mv-testing
**Qué enseña:** Estrategia de testing en el stack de MV.

**Cubre:**
- Jest para unit tests
- React Testing Library para componentes
- Playwright para E2E
- Fixtures y mocks
- Strategies para cobertura >= 80%

---

### mv-deployment
**Qué enseña:** Procedimientos de deployment.

**Cubre:**
- Deployment a Vercel (frontend)
- Deployment a Railway (backend)
- Environment variables
- Preview deploys
- CI/CD basics

---

## 🚀 Patrones de Uso

### Flujo de Proyecto Nuevo
```
1. /mv-dev:discovery           ← Entender qué existe
2. /mv-dev:start-project       ← Crear proyecto base
3. /mv-dev:new-page            ← Primera página
4. /mv-dev:new-feature         ← Features adicionales
5. /mv-dev:deploy-staging      ← Deploar
```

### Flujo de Feature en Proyecto Existente
```
1. /mv-dev:discovery           ← Buscar APIs/tablas
2. /mv-dev:mv-docs             ← Entender la API
3. /mv-dev:new-feature         ← Crear feature
4. /mv-dev:mv-testing          ← Referencia testing
5. /mv-dev:deploy-staging      ← Deploar
```

### Cuando Necesitas Aprender
```
/mv-dev:mv-design-system      ← Qué colores/tipografía usar
/mv-dev:mv-api-consumer       ← Cómo consumir APIs
/mv-dev:mv-db-queries         ← Cómo hacer queries
/mv-dev:mv-testing            ← Cómo testear
/mv-dev:mv-deployment         ← Cómo deployar
```

---

**Siguiente:** [Leer sobre MCP Servers →](20-MCP_SERVERS.md)
