# 📚 Orden de Lectura Recomendado

Guía de qué documentación leer y en qué orden, según tu perfil.

---

## 👤 Perfil 1: Soy Nuevo en el Plugin (Primer Día)

### Mañana (30-45 min)
1. **[README.md](README.md)** (5 min)
   - Entiende qué es el plugin en general

2. **[01-QUICK_START.md](01-QUICK_START.md)** (15 min)
   - Instala y configura en 5 minutos
   - Verifica que funciona

3. **[03-SETUP.md](03-SETUP.md)** (15-20 min)
   - Configura todos los tokens correctamente
   - Verifica cada uno

### Tarde (30-45 min)
4. **[GLOSSARY.md](GLOSSARY.md)** (10 min)
   - Entiende términos técnicos nuevos
   - Consulta cuando veas palabra desconocida

5. **[INDEX.md](INDEX.md)** (10 min)
   - Mapeo de todo lo disponible
   - Cómo encontrar lo que necesitas

6. **[workflow-PROJECT.md](workflow-PROJECT.md)** (15-20 min)
   - Crea tu primer proyecto
   - Siente cómo funciona el plugin

### ✅ Al Final del Día
- [ ] Plugin instalado
- [ ] Tokens configurados
- [ ] Primer proyecto creado
- [ ] `/mv-dev:discovery` funcionando

---

## 👨‍💼 Perfil 2: Necesito Crear Algo YA

### Ahora (10 min)
1. **[01-QUICK_START.md](01-QUICK_START.md)** (5 min)
   - Setup rápido

2. **Ejecuta el skill que necesites:**
   - `/mv-dev:start-project` → [workflow-PROJECT.md](workflow-PROJECT.md)
   - `/mv-dev:new-feature` → Busca `new-feature` en [10-SKILLS.md](10-SKILLS.md)
   - `/mv-dev:new-page` → Busca `new-page` en [10-SKILLS.md](10-SKILLS.md)

### Mientras Trabajas
3. Consulta según necesites:
   - **¿Qué colores uso?** → [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)
   - **¿Cómo hago queries?** → [workflow-DATABASE.md](workflow-DATABASE.md) (no creado aún, pero ver ENVIRONMENT_VARS.md)
   - **¿Cómo escribo tests?** → [workflow-TESTS.md](workflow-TESTS.md) (no creado aún, pero buscar en 10-SKILLS.md)
   - **¿Qué significa...?** → [GLOSSARY.md](GLOSSARY.md)

### Cuando Estés Listo a Deployar
4. **[workflow-DEPLOY.md](workflow-DEPLOY.md)** (10 min)
   - Deploy a staging

---

## 🏗️ Perfil 3: Entiendo el Stack, Necesito Entender el Plugin

### Semana 1 (2-3 horas)
1. **[02-ARCHITECTURE.md](02-ARCHITECTURE.md)** (30 min)
   - Entiende estructura interna
   - Cómo interactúan componentes

2. **[10-SKILLS.md](10-SKILLS.md)** (45 min)
   - Todos los 12 skills
   - Cuándo usar cada uno
   - Ejemplos completos

3. **[20-MCP_SERVERS.md](20-MCP_SERVERS.md)** (45 min)
   - Qué son MCP servers
   - Los 7 disponibles
   - Cómo funcionan internamente

### Semana 2 (2-3 horas)
4. **[30-HOOKS.md](30-HOOKS.md)** (45 min)
   - Los 6 hooks de validación
   - Cómo se ejecutan
   - Casos de uso

5. **[40-AGENTS.md](40-AGENTS.md)** (45 min)
   - Los 4 agentes
   - Cuándo se activan
   - Qué reportes generan

6. **[CODE_STANDARDS.md](CODE_STANDARDS.md)** (45 min)
   - Estandares de código MV
   - Patrones obligatorios
   - Validaciones automáticas

---

## 🎨 Perfil 4: Soy Designer/Product - Necesito Entender Design System

### Primera Lectura (30 min)
1. **[README.md](README.md)** (5 min) - Contexto general
2. **[DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)** (25 min)
   - Paleta completa de colores
   - Tipografía y sizing
   - Componentes base
   - Estados (hover, active, disabled)

### Cuando Revises Código (10 min)
3. **[CODE_STANDARDS.md](CODE_STANDARDS.md)** - Sección "Tailwind/CSS"
   - Cómo se aplican los tokens en código

### Referencia Rápida
- **¿Qué color es el botón primario?** → [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) Sección "Colores"
- **¿Cuál es el spacing entre elementos?** → [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) Sección "Espaciado"
- **¿Cómo se ve el hover de un botón?** → [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) Sección "Componentes"

---

## 👨‍🔧 Perfil 5: Voy a Contribuir al Plugin Mismo

### Fase 1: Fundamentos (3-4 horas)
1. [02-ARCHITECTURE.md](02-ARCHITECTURE.md) (30 min)
2. [10-SKILLS.md](10-SKILLS.md) (45 min)
3. [20-MCP_SERVERS.md](20-MCP_SERVERS.md) (45 min)
4. [30-HOOKS.md](30-HOOKS.md) (45 min)
5. [40-AGENTS.md](40-AGENTS.md) (45 min)

### Fase 2: Estandares (2-3 horas)
6. [CODE_STANDARDS.md](CODE_STANDARDS.md) (45 min)
7. [ENVIRONMENT_VARS.md](ENVIRONMENT_VARS.md) (30 min)
8. Lee el código en `plugins/mv-dev/skills/`, `servers/`, `scripts/` (1 hora)

### Fase 3: Profundo (2-3 horas)
9. Estudia un skill completo (ej: `skills/start-project/`)
10. Estudia un MCP server (ej: `servers/mv-db-query-server/`)
11. Estudia un hook (ej: `scripts/validate-secrets.sh`)

---

## 🎓 Por Tecnología

### Si Usas Next.js
1. [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) - Colores y componentes
2. [CODE_STANDARDS.md](CODE_STANDARDS.md) - Sección "React/Next.js"
3. [workflow-PROJECT.md](workflow-PROJECT.md) - Crear proyecto
4. [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) - Tailwind

### Si Usas Express
1. [CODE_STANDARDS.md](CODE_STANDARDS.md) - Sección "API/Backend"
2. [workflow-PROJECT.md](workflow-PROJECT.md) - Crear proyecto
3. [10-SKILLS.md](10-SKILLS.md) - Skill `create-api`
4. [20-MCP_SERVERS.md](20-MCP_SERVERS.md) - Sección `mv-db-query`

### Si Haces Testing
1. [CODE_STANDARDS.md](CODE_STANDARDS.md) - Sección "Testing"
2. [40-AGENTS.md](40-AGENTS.md) - QA Agent
3. [10-SKILLS.md](10-SKILLS.md) - Skill `mv-testing`

### Si Haces Diseño/Frontend
1. [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) - Todo
2. [CODE_STANDARDS.md](CODE_STANDARDS.md) - Sección "Tailwind/CSS"
3. [40-AGENTS.md](40-AGENTS.md) - Frontend Agent

---

## ⏱️ Resumen de Tiempos

| Perfil | Total | Recomendación |
|--------|-------|---|
| Nuevo (Día 1) | 1.5-2 horas | Mañana + tarde |
| Necesito crear | 15-30 min | Enfoque práctico |
| Entender plugin | 4-6 horas | A lo largo de 2 semanas |
| Designer | 30-45 min | Enfoque en diseño |
| Contribuir | 8-12 horas | Semana de estudio |

---

## 📌 Lectura Siempre Disponible

Estos documentos son referencia permanente, no necesitas leerlos completos:

- 📖 [GLOSSARY.md](GLOSSARY.md) - Consulta cuando veas término desconocido
- 🔑 [ENVIRONMENT_VARS.md](ENVIRONMENT_VARS.md) - Consulta cuando configures variables
- 📋 [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) - Consulta cuando diseñes componentes
- 📝 [CODE_STANDARDS.md](CODE_STANDARDS.md) - Consulta antes de hacer commit

---

## ✅ Checklist: Qué Deberías Saber

Después de leer la documentación:

- [ ] ¿Qué es un Skill?
- [ ] ¿Qué es un MCP Server?
- [ ] ¿Qué es un Hook?
- [ ] ¿Qué es un Agente?
- [ ] ¿Cuándo usar cada skill?
- [ ] ¿Cómo instalar el plugin?
- [ ] ¿Cómo configurar tokens?
- [ ] ¿Cuáles son los colores de MV?
- [ ] ¿Cuál es el formato de response de API?
- [ ] ¿Cómo escribir tests?

Si respondiste "sí" a todo, estás listo. Si no, vuelve a leer la sección correspondiente.

---

## 🚀 Siguiente Paso

**Una vez que hayas leído según tu perfil:**

- **Perfil 1 (Nuevo):** Crea tu primer proyecto con `/mv-dev:start-project`
- **Perfil 2 (Necesito crear):** Ejecuta el skill que necesites
- **Perfil 3 (Entender plugin):** Explora el código en `plugins/mv-dev/`
- **Perfil 4 (Designer):** Revisa componentes con el design system
- **Perfil 5 (Contribuir):** Abre un PR con tu mejora

---

**¿Tienes preguntas?** Consulta el [GLOSSARY.md](GLOSSARY.md) o contacta al Tech Lead.

