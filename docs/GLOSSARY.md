# 📖 Glosario de Términos del Plugin MV Dev

Definiciones de términos técnicos usados en el plugin y la documentación.

## A

**Agent (Agente)**
Asistente especializado que se activa automáticamente para validar o generar código. El plugin tiene 4 agentes: QA, Frontend, Backend y Doc.

**API (Application Programming Interface)**
Interfaz que permite que dos programas se comuniquen. Ej: La API de pagos de MV permite que la app web solicite procesar pagos.

**Aria Label**
Atributo HTML que proporciona etiquetas accesibles para lectores de pantalla. Ej: `<button aria-label="Close menu">×</button>`

## B

**Backend**
Código que corre en el servidor (Node.js, Express). Maneja lógica de negocio, base de datos, autenticación.

**BDD (Behavior-Driven Development)**
Metodología de desarrollo donde escribes tests que describen el comportamiento esperado antes de implementar.

**Border Radius**
Propiedad CSS que redondea los bordes de un elemento. Ej: `border-radius: 12px;`

## C

**CI/CD (Continuous Integration/Continuous Deployment)**
Práctica de automatically probar y deployar código cuando haces push.

**Component (Componente)**
Pieza reutilizable de UI. En React: función que retorna JSX. Ej: `<Button>`, `<Card>`, `<ProductCard>`

**Context7**
Servicio MCP que proporciona documentación actualizada de librerías de programación (React, Jest, etc.).

**Coverage (Cobertura)**
Porcentaje de código que está cubierto por tests. MV requiere >= 80%.

## D

**Design Tokens**
Variables de diseño (colores, tipografía, espaciado) que mantienen consistencia visual. Ej: `mv-green-500`, `rounded-xl`

**Design System**
Conjunto de reglas y componentes que definen cómo se ve y funciona la UI. El design system de MV incluye colores, tipografía, componentes base.

**Deploy**
Acción de llevar código de tu máquina a un servidor en internet (staging o production).

## E

**Edge Cases**
Situaciones extremas o inesperadas que puede manejar tu código. Ej: usuario sin perfil, conexión perdida, datos vacíos.

**ESLint**
Herramienta que valida que el código sigue reglas de estilo y quality (no usa `any`, declara variables, etc.).

## F

**Feature (Funcionalidad)**
Conjunto de cambios que agrega capacidad nueva. Ej: "agregar carrito de compras" es una feature.

**Frontend**
Código que corre en el navegador del usuario (Next.js, React, CSS). Lo que ves y usas en la app.

**Fixture**
Datos predefinidos que usas en tests. Ej: un usuario de prueba con email y password.

## G

**Git**
Sistema de control de versiones. Tracks cambios en código y permite colaboración.

**GitHub**
Plataforma web que hospeda repositorios Git.

**Gherkin**
Lenguaje para escribir tests en términos que entienden business y devs. Ej:
```
Given un usuario logged in
When hace clic en "Buy"
Then se procesa el pago
```

## H

**Hook**
Script que se ejecuta automáticamente en ciertos momentos (guardar archivo, commit, push). El plugin tiene 6 hooks de validación.

**Hosting**
Servicio que mantiene tu aplicación en internet. MV usa Vercel (frontend) y Railway (backend).

## I

**Integration Test (Test de Integración)**
Test que verifica que múltiples componentes trabajan juntos correctamente. Ej: form → API → BD.

## J

**Jest**
Framework de testing para JavaScript/TypeScript. Se usa para unit tests y integration tests.

**JWT (JSON Web Token)**
Formato seguro de autenticación. Tokens que prueba que un usuario está logueado.

## L

**LIMIT**
Cláusula SQL que restringe número de resultados. Ej: `SELECT * FROM users LIMIT 10`. En MV es OBLIGATORIO.

**Loading State**
Estado de UI que muestra que algo se está cargando. Ej: spinner, skeleton loader.

## M

**MCP (Model Context Protocol)**
Protocolo que permite a Claude Code conectarse a herramientas externas (BD, APIs, etc.).

**MCP Server**
Proceso separado que implementa MCP. Ej: `mv-db-query` es un MCP server que permite queries a BD.

**Meta Tags**
Etiquetas HTML en `<head>` que dan información sobre la página. Ej: `<meta name="description" ... >`

**Migration**
Cambio en la estructura de base de datos (crear tabla, agregar columna, etc.).

## N

**Next.js**
Framework de React para web. Proporciona enrutamiento, SSR, API routes.

**Notion**
Herramienta de documentación que MV usa como "fuente de verdad" para APIs, tablas, procesos.

## O

**Optimistic Update**
Actualizar UI inmediatamente sin esperar respuesta del servidor (mejora UX).

## P

**Playwright**
Framework para testing E2E (automatizar un navegador real).

**Prettier**
Herramienta que formatea código automáticamente (indentación, espacios, etc.).

**Pre-commit Hook**
Script que valida código ANTES de hacer commit (ESLint, Prettier, secrets).

**Pre-push Hook**
Script que valida código ANTES de hacer push (TypeScript, tests, build).

**Preview Deploy**
Deployment automático de cada branch a una URL temporal para testing.

## Q

**Query**
Solicitud a la base de datos. Ej: `SELECT * FROM orders WHERE user_id = 123`

## R

**React Testing Library**
Framework para testear componentes React desde la perspectiva del usuario (no de implementación).

**REST API**
Tipo de API que usa HTTP (GET, POST, PUT, DELETE) y JSON.

**Retry Logic**
Código que reintenta una operación si falla (ej: reintentar llamada API con backoff exponencial).

## S

**Schema**
Definición de la estructura de datos. Ej: tabla de DB tiene schema (id, nombre, email).

**Semantic HTML**
Usar etiquetas HTML que describen significado (ej: `<button>` en lugar de `<div>`) para accesibilidad.

**Skeleton**
Placeholder visual que muestra estructura de contenido mientras carga. Ej: líneas grises en lugar de texto real.

**Skill**
Workflow invocable (como `/mv-dev:start-project`). El plugin tiene 12 skills.

**State**
Datos que cambian en tiempo de ejecución. En React: `useState`. Ej: formulario con `email` state.

**Supabase**
Servicio de base de datos y backend. MV lo usa para algunas aplicaciones.

**SVG**
Formato de gráficos vectoriales. Ideal para iconos y logos.

## T

**Tailwind CSS**
Framework CSS utility-first. Usas clases predefinidas en lugar de escribir CSS custom.

**Test Coverage**
Porcentaje de código ejecutado durante tests.

**TypeScript**
JavaScript con tipos. MV requiere strict mode (`"strict": true`).

## U

**Unit Test**
Test que verifica que una función individual funciona correctamente.

**User Story**
Descripción de feature desde perspectiva del usuario. Ej: "Como usuario, quiero poder filtrar productos"

## V

**Validation**
Verificar que datos cumplen requisitos. Ej: email válido, edad >= 18, password suficientemente fuerte.

**Vercel**
Plataforma de hosting para Next.js. MV deployea frontends aquí.

## W

**Wrapper**
Función/componente que envuelve otro para agregarle funcionalidad. Ej: error boundary que envuelve un componente.

## X

**XSS (Cross-Site Scripting)**
Vulnerabilidad de seguridad donde código malicioso ejecuta en el navegador del usuario.

## Z

**Zod**
Librería de TypeScript para validación de esquemas. Ej: validar que un formulario tiene email y password válidos.

---

## Acrónimos Comunes

| Acrónimo | Significado |
|----------|-------------|
| **API** | Application Programming Interface |
| **BD** | Base de Datos |
| **BDD** | Behavior-Driven Development |
| **CSS** | Cascading Style Sheets |
| **CI/CD** | Continuous Integration/Deployment |
| **DB** | Database |
| **DTOs** | Data Transfer Objects |
| **E2E** | End-to-End (testing) |
| **ESLint** | ECMAScript Linter |
| **FE** | Frontend |
| **HTML** | HyperText Markup Language |
| **HTTP** | HyperText Transfer Protocol |
| **HTTPS** | HTTP Secure |
| **JS** | JavaScript |
| **JWT** | JSON Web Token |
| **MCP** | Model Context Protocol |
| **REST** | Representational State Transfer |
| **SQL** | Structured Query Language |
| **TS** | TypeScript |
| **UI** | User Interface |
| **UX** | User Experience |
| **VPN** | Virtual Private Network |
| **JSON** | JavaScript Object Notation |
| **XML** | eXtensible Markup Language |

---

## Patrones Comunes en MV

| Término | Significado en MV |
|---------|------------------|
| **staging** | Ambiente de prueba (casi igual a producción) |
| **production** | Ambiente real (usuarios reales) |
| **Design Tokens** | Colores, tipografía, espaciado oficiales de MV |
| **Design System** | Sistema de diseño completo de MV |
| **Tablas bloqueadas** | Tablas sensibles que no se pueden queryar (payments, user_payment_methods) |
| **CLAUDE.md** | Contexto global de MV que se carga automáticamente |
| **Tech Lead** | Líder técnico del equipo |

---

¿No encuentras un término? Abre un issue o consulta con el Tech Lead.
