# 🎯 Skills del Plugin MV Dev

El plugin incluye **22 skills** organizados en 5 categorías: Orquestación, Core, Acción, Conocimiento y Flutter/BDD.

## 📍 Mapa de Skills

### Orquestación (1) - Empieza aquí ante cualquier tarea técnica
- [`/mv-dev:mv-instruction-generator`](#mv-instruction-generator) - Workflow técnico: Discovery → Fix / Sprint / PRD

### Core (2) - Descubrimiento y documentación
- [`/mv-dev:discovery`](#discovery) - Descubrimiento técnico pre-proyecto
- [`/mv-dev:mv-docs`](#mv-docs) - Buscar documentación en Notion

### Acción (5) - Crear cosas (web)
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

### Flutter (6) - App móvil de MV
- [`/mv-dev:flutter-architecture`](#flutter-architecture) - Arquitectura del proyecto Flutter
- [`/mv-dev:flutter-visual-style`](#flutter-visual-style) - Design system en Flutter
- [`/mv-dev:flutter-brand-identity`](#flutter-brand-identity) - Identidad de marca en Flutter
- [`/mv-dev:flutter-new-feature`](#flutter-new-feature) - Nueva feature en Flutter
- [`/mv-dev:flutter-new-screen`](#flutter-new-screen) - Nueva pantalla Flutter
- [`/mv-dev:flutter-component`](#flutter-component) - Widget reutilizable Flutter

### BDD / Gherkin (3) - Tests de aceptación
- [`/mv-dev:notion-gherkin`](#notion-gherkin) - Notion → archivos Gherkin
- [`/mv-dev:gherkin-to-tests`](#gherkin-to-tests) - Gherkin → tests ejecutables
- [`/mv-dev:create-feature-file`](#create-feature-file) - Crear `.feature` desde Notion

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

---

## Skill de Orquestación

### mv-instruction-generator
**Descripción:** Skill de entrada para cualquier tarea técnica en MV. Detecta automáticamente el modo correcto según el tipo de request y orquesta el ciclo Discovery→Plan→Ejecución→Reporte.

**Cuándo usarlo:** Ante cualquier bug, feature, sprint, fix, refactor, instrumentación o problema técnico en repos de MV. También cuando se comparten reportes/logs/screenshots de problemas.

**Los 4 modos que detecta automáticamente:**

| Modo | Trigger | Comportamiento |
|------|---------|---------------|
| **A — PRD** | Request vago, ideación sin spec técnica | Preguntas de negocio → Brief → Modo C |
| **B — Fix puntual** | 1-3 archivos, alcance claro | Discovery interno silencioso → ejecuta directo |
| **C — Sprint** | Multi-archivo, arquitectura, riesgo de regresión | Discovery → Plan en .md → STOPs intermedios |
| **D — Discovery puro** | "Investiga", "solo entender", incertidumbre fuerte | Solo read-only → reporte → pausa |

**Filosofía inmutable:**
1. Discovery siempre primero — nunca asumir estructura del código
2. Cambios surgical, NO rewrites — fix puntual sobre refactor
3. Guards de pago obligatorios — `git diff` antes de cada commit

**Guards que verifica en cada commit:**
```bash
git diff --name-only | grep -E "checkout-utils|payment-errors|od-order|dailyfood|foodcourt|wallet|card-add|src/api/payment"
# Esperado: VACÍO. Si aparece → ABORT.
```

**Ejemplo de uso:**
```
"Hay 138 errores 5xx en prod, investiga"
→ Detecta Modo D (discovery puro)
→ Genera DISCOVERY_5XX_ERRORS_2026-05-15.md con hallazgos

"Cambia el copy del botón de pago a 'Confirmar pedido'"
→ Detecta Modo B (fix puntual)
→ Discovery interno → ejecuta → resumen en chat

"Sprint: implementar funnel tracking completo"
→ Detecta Modo C (sprint grande)
→ Discovery + plan INSTRUCCION_FUNNEL_TRACKING.md + STOPs → ejecuta con aprobación
```

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

### Flujo Flutter (App Móvil)
```
1. /mv-dev:flutter-architecture    ← Definir/revisar arquitectura
2. /mv-dev:flutter-visual-style    ← Configurar design system
3. /mv-dev:flutter-new-screen      ← Crear pantallas
4. /mv-dev:flutter-component       ← Crear widgets reutilizables
5. /mv-dev:flutter-new-feature     ← Scaffold de feature completa
```

### Flujo BDD (Tests de Aceptación)
```
1. /mv-dev:notion-gherkin          ← Notion → archivos .feature
2. /mv-dev:gherkin-to-tests        ← .feature → tests ejecutables
```

---

## Skills de Flutter

### flutter-architecture
**Descripción:** Define o revisa la arquitectura de un proyecto Flutter de MV. Presenta opciones con ventajas y desventajas para que el equipo pueda decidir.

**Cuándo usarlo:**
- Al iniciar un nuevo proyecto Flutter
- Cuando el proyecto crece y se vuelve difícil de mantener
- Cuando hay dudas sobre dónde poner un archivo
- Para revisar inconsistencias en la organización del código

**Opciones que evalúa:**
- Feature-first vs Layer-first
- BLoC vs Riverpod vs GetX
- Mono-repo vs multi-repo

**Output típico:**
```
📐 Arquitectura Recomendada: Feature-first + BLoC

lib/
  core/
    theme/       ← Design tokens MV
    navigation/  ← Router
    network/     ← Dio client
  features/
    auth/
      data/      ← API calls
      domain/    ← Business logic
      presentation/ ← Screens + BLoC
    orders/
      ...
```

---

### flutter-visual-style
**Descripción:** Configura y audita el design system de MV en Flutter — colores, tipografía, spacing, border radius.

**Cuándo usarlo:**
- Al iniciar un proyecto Flutter
- Para verificar que los tokens de MV están bien configurados
- Cuando hay inconsistencias visuales

**Qué verifica:**
- Paleta de colores (`mv-green-500` = `#227A4B`)
- Tipografía (Inter para headings, Nunito para body)
- Border radius (12px base = `Radius.circular(12)`)
- Spacing (múltiplos de 4px)

**Genera:**
```dart
// lib/core/theme/mv_colors.dart
class MVColors {
  static const green500 = Color(0xFF227A4B);
  static const green600 = Color(0xFF1D6A41);
  static const orange500 = Color(0xFFE85D04);
  // ...
}
```

---

### flutter-brand-identity
**Descripción:** Revisa identidad de marca en Flutter — logo, íconos, tono del texto, animaciones, splash screen.

**Cuándo usarlo:**
- Al configurar una nueva app Flutter de MV
- Para auditar que la app sigue los lineamientos de marca
- Cuando cambia la identidad visual de MV

**Qué verifica:**
- Splash screen con logo MV
- Ícono de app correcto
- Tono del copy (amigable, motivador, saludable)
- Animaciones sutiles (no exageradas)
- Fuentes correctas cargadas en `pubspec.yaml`

---

### flutter-new-feature
**Descripción:** Scaffold completo de una nueva feature en Flutter siguiendo la arquitectura del proyecto existente.

**Cuándo usarlo:**
- Agregar funcionalidad nueva a la app móvil
- Necesitas estructura completa: data + domain + presentation

**Lo que genera:**
```
features/
  [nombre]/
    data/
      [nombre]_api.dart           ← Llamadas HTTP
      [nombre]_repository_impl.dart
    domain/
      [nombre]_repository.dart    ← Interface
      models/[nombre]_model.dart
      usecases/get_[nombre].dart
    presentation/
      screens/[nombre]_screen.dart
      bloc/[nombre]_bloc.dart
      widgets/
    test/
      [nombre]_test.dart
```

---

### flutter-new-screen
**Descripción:** Crea una pantalla Flutter completa con navegación correcta, design tokens de MV, todos los estados visuales y widget tests.

**Cuándo usarlo:**
- Agregar una pantalla nueva a la app
- Recibir un diseño de Figma para implementar
- Refactorizar una pantalla existente

**Estados que implementa:**
- Loading (shimmer/skeleton)
- Error (con botón de reintentar)
- Empty (estado vacío)
- Data (contenido real)

**Genera:**
```dart
class OrdersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        return switch (state) {
          OrdersLoading() => const OrdersShimmer(),
          OrdersError(:final message) => ErrorView(message: message, onRetry: ...),
          OrdersEmpty() => const EmptyOrders(),
          OrdersLoaded(:final orders) => OrdersList(orders: orders),
        };
      },
    );
  }
}
```

---

### flutter-component
**Descripción:** Crea un widget reutilizable con design tokens de MV, variantes y widget tests.

**Cuándo usarlo:**
- Crear un botón, card, badge, input reutilizable
- Extraer UI repetida en un widget compartido

**Convenciones:**
- Ubicar en `lib/core/widgets/` si es compartido por múltiples features
- Ubicar en `lib/features/[nombre]/presentation/widgets/` si es específico de la feature
- Siempre incluir widget tests

---

## Skills de BDD / Gherkin

### notion-gherkin
**Descripción:** Obtiene requerimientos de Notion (o `docs/BUSINESS_LOGIC.md`) y genera archivos `.feature` en formato Gherkin con edge cases específicos del negocio de MV.

**Cuándo usarlo:**
- Definir criterios de aceptación para una feature nueva
- Traducir un PRD o user story de Notion a tests de aceptación
- El equipo de QA necesita `.feature` files para BDD

**Requisitos:**
- `NOTION_TOKEN` configurado (si la fuente es Notion)

**Edge cases que incluye automáticamente:**
- Multi-país (PE, CO, MX, CL) con diferencias de comportamiento
- Plan vencido / sin suscripción activa
- Sin cobertura de delivery en la zona
- Sin stock del producto

**Output:**
```gherkin
# features/orders/create-order.feature
Feature: Crear una orden de delivery
  Como usuario con suscripción activa
  Quiero crear una orden de comida
  Para recibirla en mi domicilio

  Scenario: Orden creada exitosamente
    Given el usuario tiene suscripción activa en "PE"
    And hay stock disponible del producto
    When el usuario crea una orden con 2 items
    Then la orden queda en estado "pending"
    And se programa la entrega

  Scenario: Error por plan vencido
    Given el usuario tiene suscripción vencida
    When el usuario intenta crear una orden
    Then se muestra "Tu plan ha vencido. Renueva para continuar"
```

---

### gherkin-to-tests
**Descripción:** Lee archivos `.feature` en `features/` y genera tests ejecutables (Jest, RTL, Playwright) según el tipo de escenario.

**Cuándo usarlo:**
- Después de `/mv-dev:notion-gherkin`
- Cuando tienes `.feature` files sin implementación de tests
- Para convertir BDD en código ejecutable

**Clasificación automática:**
| Tipo de escenario | Framework |
|-------------------|-----------|
| Flujo completo de usuario | Playwright E2E |
| Interacción UI / estados de componente | React Testing Library |
| Carga de datos / errores de red | RTL + MSW |
| Funciones puras / hooks / cálculos | Jest / Vitest Unit |

**Requisitos:**
- Archivos `.feature` en `features/` (creados con `/mv-dev:notion-gherkin`)

---

### create-feature-file
**Descripción:** Busca una feature en Notion, extrae los requerimientos y genera un archivo `.feature` Gherkin listo para BDD.

**Cuándo usarlo:**
- Cuando conoces el nombre de la feature en Notion y quieres un `.feature` directo
- Similar a `notion-gherkin` pero más directo: busca en Notion y genera el archivo

**Diferencia con `notion-gherkin`:**
- `notion-gherkin`: guía interactiva paso a paso, con preguntas
- `create-feature-file`: más automatizado, busca en Notion y genera directamente

---

**Siguiente:** [Leer sobre MCP Servers →](20-MCP_SERVERS.md)
