# 📚 Índice de Guías del Plugin MV Dev

Acceso rápido a todos los workflows y guías disponibles.

## 🚀 Guías de Workflows

### Crear un Proyecto Nuevo
**Cuando:** Necesitas un proyecto Next.js, Express o monorepo nuevo

**Duración:** 10-15 minutos

**Pasos principales:**
1. Ejecutar `/mv-dev:discovery` - entender qué existe
2. Ejecutar `/mv-dev:start-project` - generar proyecto base
3. Personalizar según necesidades
4. Deployar a staging

**Ir a:** [Crear un Proyecto](workflow-PROJECT.md)

---

### Crear una Feature Nueva
**Cuando:** Necesitas agregar funcionalidad a un proyecto existente

**Duración:** 5-30 minutos (según complejidad)

**Pasos principales:**
1. Ejecutar `/mv-dev:discovery` - buscar APIs/tablas existentes
2. Ejecutar `/mv-dev:mv-docs` - leer documentación
3. Ejecutar `/mv-dev:new-feature` - generar scaffold
4. Implementar según la guía
5. Tests automáticos validarán

**Ir a:** [Crear una Feature](workflow-FEATURE.md)

---

### Consumir una API de MV
**Cuando:** Necesitas integrar una API existente de Manzana Verde

**Duración:** 5-10 minutos

**Pasos principales:**
1. Ejecutar `/mv-dev:mv-docs` - buscar documentación de la API
2. Ejecutar `/mv-dev:mv-api-consumer` - referencia de patrones
3. Implementar consumo siguiendo patrón

**Ir a:** [Consumir APIs](workflow-API.md)

---

### Hacer Queries a la Base de Datos
**Cuando:** Necesitas explorar/debuguear datos en staging

**Duración:** 2-5 minutos

**Pasos principales:**
1. Asegurarte que DB_ACCESS_* está configurado
2. Escribir query (SELECT con LIMIT obligatorio)
3. Ejecutar contra staging
4. Validar datos

**Ir a:** [Hacer Queries](workflow-DATABASE.md)

---

### Escribir Tests
**Cuando:** Necesitas testear un componente, servicio o flujo

**Duración:** Variable (depende de cobertura)

**Pasos principales:**
1. Ejecutar `/mv-dev:mv-testing` - referencia de estrategia
2. Escribir tests (Jest, RTL, Playwright)
3. Ejecutar: `npm test`
4. Validar cobertura >= 80%

**Ir a:** [Escribir Tests](workflow-TESTS.md)

---

### Deployar a Staging
**Cuando:** Quieres probar cambios en un ambiente real

**Duración:** 5-15 minutos (+ validaciones automáticas)

**Pasos principales:**
1. Ejecutar `/mv-dev:deploy-staging`
2. Responder preguntas (rama, descripción)
3. Plugin valida (TS, tests, build)
4. Deploy automático a Vercel/Railway

**Ir a:** [Deployar a Staging](workflow-DEPLOY.md)

---

### Escribir una Nueva Página Next.js
**Cuando:** Necesitas una página con estructura completa

**Duración:** 5-10 minutos

**Pasos principales:**
1. Ejecutar `/mv-dev:new-page`
2. Indicar ruta y tipo
3. Plugin genera estructura con:
   - page.tsx
   - loading.tsx
   - error.tsx
   - Tests

**Ir a:** [Nueva Página Next.js](workflow-PAGE.md)

---

### Crear un Endpoint Express
**Cuando:** Necesitas un nuevo endpoint de API en backend

**Duración:** 5-15 minutos

**Pasos principales:**
1. Ejecutar `/mv-dev:create-api`
2. Indicar método HTTP, path, parámetros
3. Plugin genera:
   - Route con validación Zod
   - Controller
   - Service
   - Tests

**Ir a:** [Crear API Endpoint](workflow-API_ENDPOINT.md)

---

## 📖 Guías de Referencia

### Configuración Inicial
- [Guía Rápida de 5 Minutos](01-QUICK_START.md)
- [Configuración Completa de Tokens](03-SETUP.md)

### Componentes del Plugin
- [Todos los 12 Skills](10-SKILLS.md)
- [Los 7 MCP Servers](20-MCP_SERVERS.md)
- [Los 6 Hooks de Validación](30-HOOKS.md)
- [Los 4 Agentes Especializados](40-AGENTS.md)

### Estándares y Diseño
- [Design System Completo](DESIGN_SYSTEM.md)
- [Estandares de Código](CODE_STANDARDS.md)
- [Variables de Entorno](ENVIRONMENT_VARS.md)

### Arquitectura e Internals
- [Arquitectura del Plugin](02-ARCHITECTURE.md)
- [Glosario de Términos](GLOSSARY.md)

---

## 🎯 Por Caso de Uso

### Soy nuevo en MV, ¿por dónde empiezo?
1. **Primero:** [Guía Rápida de 5 Minutos](01-QUICK_START.md)
2. **Luego:** [Configuración Completa](03-SETUP.md)
3. **Finalmente:** [Crear tu Primer Proyecto](workflow-PROJECT.md)

### Necesito entender cómo funciona el plugin
1. **Arquitectura:** [Cómo está estructurado](02-ARCHITECTURE.md)
2. **Skills:** [Los 12 skills disponibles](10-SKILLS.md)
3. **MCP Servers:** [Qué son y cómo se usan](20-MCP_SERVERS.md)

### Necesito crear algo ahora
- **Proyecto nuevo:** [Crear un Proyecto](workflow-PROJECT.md)
- **Feature nueva:** [Crear una Feature](workflow-FEATURE.md)
- **Página Next.js:** [Nueva Página](workflow-PAGE.md)
- **Endpoint API:** [Crear API](workflow-API_ENDPOINT.md)

### Necesito validar algo
- **Design System:** [Ver colores, tipografía](DESIGN_SYSTEM.md)
- **Estandares de código:** [Patrones y convenciones](CODE_STANDARDS.md)
- **Testing:** [Estrategia de testing](workflow-TESTS.md)

### Necesito deployar
1. **Primero:** [Estrategia de deployment](workflow-DEPLOY.md)
2. **Luego:** Ejecuta `/mv-dev:deploy-staging`

---

## 🔍 Búsqueda Rápida

### Por Topic

**APIs**
- [Consumir APIs de MV](workflow-API.md)
- [Crear Endpoint Express](workflow-API_ENDPOINT.md)
- [MCP Servers (para conectarse a servicios)](20-MCP_SERVERS.md)

**Diseño**
- [Design System (colores, tipografía)](DESIGN_SYSTEM.md)
- [Frontend Agent (validaciones de diseño)](40-AGENTS.md)

**Testing**
- [Escribir Tests](workflow-TESTS.md)
- [QA Agent (validación de cobertura)](40-AGENTS.md)
- [Playwright MCP (E2E testing)](20-MCP_SERVERS.md)

**Base de Datos**
- [Hacer Queries a BD](workflow-DATABASE.md)
- [mv-db-query MCP Server](20-MCP_SERVERS.md)
- [Supabase MCP Server](20-MCP_SERVERS.md)

**Documentación**
- [Doc Agent (genera automáticamente)](40-AGENTS.md)
- [mv-docs Skill (buscar en Notion)](10-SKILLS.md)
- [Notion MCP Server](20-MCP_SERVERS.md)

**Deployment**
- [Deployar a Staging](workflow-DEPLOY.md)
- [Procedimientos de Deployment](workflow-DEPLOY.md)

---

## 📞 Si Tienes Preguntas

| Pregunta | Ver |
|----------|-----|
| ¿Cómo instalo el plugin? | [Quick Start](01-QUICK_START.md) |
| ¿Cómo configuro tokens? | [Setup Completo](03-SETUP.md) |
| ¿Qué es un MCP Server? | [MCP Servers](20-MCP_SERVERS.md) |
| ¿Qué es un Skill? | [Skills](10-SKILLS.md) |
| ¿Qué colores uso? | [Design System](DESIGN_SYSTEM.md) |
| ¿Cómo escribo tests? | [Workflow de Tests](workflow-TESTS.md) |
| ¿Cómo deployo? | [Workflow de Deploy](workflow-DEPLOY.md) |
| ¿Qué significa...? | [Glosario](GLOSSARY.md) |

---

## 🎓 Aprendizaje Progresivo

### Nivel Principiante (Primera semana)
1. [Quick Start](01-QUICK_START.md)
2. [Setup Completo](03-SETUP.md)
3. [Crear tu Primer Proyecto](workflow-PROJECT.md)
4. [Design System](DESIGN_SYSTEM.md)

### Nivel Intermedio (Primera/ segunda semana)
1. [Arquitectura del Plugin](02-ARCHITECTURE.md)
2. [Todos los Skills](10-SKILLS.md)
3. [MCP Servers](20-MCP_SERVERS.md)
4. [Workflows completos](workflow-PROJECT.md)

### Nivel Avanzado (Cuando contribuyas al plugin)
1. [Arquitectura Profunda](02-ARCHITECTURE.md)
2. [Code Standards](CODE_STANDARDS.md)
3. [Hooks de Validación](30-HOOKS.md)
4. [Agentes Especializados](40-AGENTS.md)

---

**Última actualización:** 2026-03-16
