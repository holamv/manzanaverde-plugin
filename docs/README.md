# Documentación del Plugin MV Dev

Bienvenido a la documentación completa del **Plugin MV Dev** para Claude Code. Este plugin automatiza el desarrollo de software en Manzana Verde, aplicando automáticamente estándares de código, design system y patrones empresariales.

## 📚 Contenido de la Documentación

### Guías principales
- **[GUÍA DE INICIO RÁPIDO](01-QUICK_START.md)** - Cómo instalar y configurar el plugin en 5 minutos
- **[ARQUITECTURA](02-ARCHITECTURE.md)** - Estructura interna del plugin, componentes y cómo funcionan juntos
- **[CONFIGURACIÓN](03-SETUP.md)** - Paso a paso para configurar todos los tokens requeridos

### Referencia de Componentes
- **[Skills](10-SKILLS.md)** - Todos los 12 skills disponibles con ejemplos de uso
- **[MCP Servers](20-MCP_SERVERS.md)** - Los 7 servidores de protocolo MCP: qué son, cómo usarlos, requisitos
- **[Hooks de Validación](30-HOOKS.md)** - Cómo funcionan las validaciones automáticas
- **[Agentes](40-AGENTS.md)** - Los 4 agentes especializados (QA, Frontend, Backend, Docs)

### Guías de Uso
- **[Crear un Proyecto](workflow-PROJECT.md)** - Paso a paso para iniciar un nuevo proyecto
- **[Crear una Feature](workflow-FEATURE.md)** - Workflow completo de desarrollo de una feature
- **[Consumir APIs de MV](workflow-API.md)** - Cómo integrar APIs de Manzana Verde
- **[Hacer Queries a BD](workflow-DATABASE.md)** - Consultar la base de datos de staging
- **[Deployar a Staging](workflow-DEPLOY.md)** - Cómo deployar cambios a staging
- **[Escribir Tests](workflow-TESTS.md)** - Estrategia de testing con Jest, RTL y Playwright

### Referencia Técnica
- **[Design System](DESIGN_SYSTEM.md)** - Colores, tipografía, componentes, espaciado
- **[Estandares de Código](CODE_STANDARDS.md)** - Convenciones de nombrado, patrones, estructura
- **[Variables de Entorno](ENVIRONMENT_VARS.md)** - Todas las variables disponibles y cómo usarlas
- **[Glosario](GLOSSARY.md)** - Definiciones de términos técnicos usados en el plugin

## 🚀 Comencemos

### Si eres nuevo en el plugin
1. Empieza con **[GUÍA DE INICIO RÁPIDO](01-QUICK_START.md)**
2. Configura tus tokens en **[CONFIGURACIÓN](03-SETUP.md)**
3. Lee **[Crear un Proyecto](workflow-PROJECT.md)** para tu primer proyecto

### Si necesitas usar un skill específico
Cada skill tiene su propia documentación en **[Skills](10-SKILLS.md)** con:
- Descripción de qué hace
- Cuándo usarlo
- Requisitos (tokens, configuración)
- Ejemplo paso a paso
- Troubleshooting común

### Si necesitas entender cómo funciona
- **[ARQUITECTURA](02-ARCHITECTURE.md)** - Cómo están organizados los componentes
- **[MCP Servers](20-MCP_SERVERS.md)** - Qué son y por qué los necesitamos

## 🎯 Casos de Uso Comunes

### Quiero crear un nuevo proyecto web
→ [Crear un Proyecto](workflow-PROJECT.md) + [/mv-dev:start-project](10-SKILLS.md#start-project)

### Necesito implementar una feature nueva
→ [Crear una Feature](workflow-FEATURE.md) + [/mv-dev:new-feature](10-SKILLS.md#new-feature)

### Necesito entender las APIs disponibles
→ [/mv-dev:discovery](10-SKILLS.md#discovery) + [/mv-dev:mv-docs](10-SKILLS.md#mv-docs)

### Necesito hacer queries a la base de datos
→ [Hacer Queries a BD](workflow-DATABASE.md) + [mv-db-query MCP](20-MCP_SERVERS.md#mv-db-query)

### Necesito deployar cambios
→ [Deployar a Staging](workflow-DEPLOY.md) + [/mv-dev:deploy-staging](10-SKILLS.md#deploy-staging)

## 📋 Checklist Inicial

- [ ] Instalé el plugin: `claude plugin add https://github.com/manzanaverdelatam/manzanaverde-plugin`
- [ ] Configuré `CONTEXT7_API_KEY` (ver [CONFIGURACIÓN](03-SETUP.md))
- [ ] Configuré `NOTION_TOKEN` (ver [CONFIGURACIÓN](03-SETUP.md))
- [ ] Configuré `SUPABASE_ACCESS_TOKEN` (ver [CONFIGURACIÓN](03-SETUP.md))
- [ ] Configuré `DB_ACCESS_*` variables (ver [CONFIGURACIÓN](03-SETUP.md))
- [ ] Reinicié Claude Code y verifiqué que los MCP servers aparezcan

## ❓ Preguntas Frecuentes

**¿Qué es un MCP Server?**
→ Ver [MCP Servers](20-MCP_SERVERS.md#qué-es-mcp)

**¿Cómo obtengo los tokens?**
→ Ver [CONFIGURACIÓN](03-SETUP.md)

**¿Qué significa "de solo lectura"?**
→ Ver [Hacer Queries a BD](workflow-DATABASE.md#limitaciones)

**¿Cómo reviso el diseño system?**
→ Ver [Design System](DESIGN_SYSTEM.md)

**¿Qué validaciones se ejecutan automáticamente?**
→ Ver [Hooks de Validación](30-HOOKS.md)

## 📞 Soporte

Si tienes preguntas que esta documentación no responda:
1. Revisa el **[Glosario](GLOSSARY.md)** por si es un término desconocido
2. Consulta con el **Tech Lead** de tu equipo
3. Abre un **issue** en el repositorio del plugin

---

**Última actualización:** 2026-03-16
**Plugin versión:** 1.6.0
