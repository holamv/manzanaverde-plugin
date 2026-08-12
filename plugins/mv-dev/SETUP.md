# Guia de Configuracion - Plugin MV Dev

Esta guia explica paso a paso como configurar los tokens necesarios para que todos los MCP servers del plugin funcionen correctamente.

---

## Requisitos previos

- **Node.js 18+** instalado
- **Claude Code** instalado y configurado
- Acceso a las cuentas de los servicios (te los da el Tech Lead)

## Nota sobre sistemas operativos

Esta guia muestra comandos para **Mac/Linux** y **Windows**. Busca el bloque correspondiente a tu sistema:

| Sistema | Archivo de perfil | Comando para recargar |
|---------|-------------------|----------------------|
| **Mac** | `~/.zshrc` | `source ~/.zshrc` |
| **Linux** | `~/.bashrc` | `source ~/.bashrc` |
| **Windows (PowerShell)** | `$PROFILE` | Reiniciar terminal |
| **Windows (alternativa)** | Variables de entorno del sistema | Reiniciar terminal |

**Windows - crear perfil de PowerShell (solo la primera vez):**

Si `$PROFILE` no existe, crearlo:

```powershell
# Verificar si existe
Test-Path $PROFILE

# Si retorna False, crearlo:
New-Item -Path $PROFILE -Type File -Force

# Abrir para editar:
notepad $PROFILE
```

---

## 1. Context7 (Documentacion de librerias)

Context7 trae documentacion actualizada de cualquier libreria directo al contexto de Claude. Funciona sin API key pero con rate limits bajos. Con API key es gratuito y sin limites practicos.

### Paso a paso

1. Ir a **https://context7.com/dashboard**
2. Crear cuenta gratuita (puedes usar GitHub o Google)
3. En el dashboard, click en **"Create API Key"**
4. Copiar el API key (formato: `ctx7sk-...`)
5. Agregar a tu shell profile:

**Mac / Linux:**
```bash
# Agregar al final de ~/.zshrc (Mac) o ~/.bashrc (Linux)
export CONTEXT7_API_KEY="ctx7sk-tu-api-key-aqui"
```

**Windows (PowerShell):**
```powershell
# Agregar al perfil: notepad $PROFILE
$env:CONTEXT7_API_KEY = "ctx7sk-tu-api-key-aqui"
```

6. Recargar el terminal:

**Mac / Linux:** `source ~/.zshrc`
**Windows:** Cerrar y abrir una nueva terminal PowerShell

**Verificar:**
- Mac/Linux: `echo $CONTEXT7_API_KEY`
- Windows: `echo $env:CONTEXT7_API_KEY`

---

## 2. Notion (Documentacion de proyectos)

Notion se usa como **hub central de documentacion**. Cada proyecto de MV tiene su propia pagina en Notion, identificada por el link de GitHub. Esto permite que multiples personas trabajen en el mismo proyecto y cualquiera pueda retomarlo leyendo la doc.

Claude necesita permisos de **lectura y escritura** para crear y actualizar la documentacion automaticamente.

### Paso a paso

1. Ir a **https://www.notion.so/my-integrations**
2. Click en **"New integration"**
3. Configurar:
   - **Name:** `MV Claude Code`
   - **Associated workspace:** Seleccionar el workspace de Manzana Verde
   - **Capabilities:** Marcar **Read content**, **Update content**, **Insert content** y **Read comments**
4. Click en **"Submit"**
5. Copiar el **"Internal Integration Secret"** (formato: `ntn_...`)
6. **IMPORTANTE:** Compartir la pagina raiz de proyectos con la integracion:
   - Crear (o abrir) una pagina en Notion llamada **"MV Projects"** (aqui se crearan las paginas de cada proyecto)
   - Click en **"..."** (tres puntos) → **"Connections"** → **"Connect to"**
   - Buscar y seleccionar **"MV Claude Code"**
   - Esto da acceso a la pagina y todas sus sub-paginas
7. Agregar a tu shell profile:

**Mac / Linux:**
```bash
# Agregar al final de ~/.zshrc (Mac) o ~/.bashrc (Linux)
export NOTION_TOKEN="ntn_tu-token-aqui"
```

**Windows (PowerShell):**
```powershell
# Agregar al perfil: notepad $PROFILE
$env:NOTION_TOKEN = "ntn_tu-token-aqui"
```

8. Recargar el terminal:

**Mac / Linux:** `source ~/.zshrc`
**Windows:** Cerrar y abrir una nueva terminal PowerShell

**Verificar:**
- Mac/Linux: `echo $NOTION_TOKEN`
- Windows: `echo $env:NOTION_TOKEN`

### Como funciona la documentacion

- Al crear un proyecto con `/mv-dev:start-project`, Claude crea automaticamente una pagina en Notion con: Overview, Business Logic, API Docs, Components, Architecture y Changelog
- El **link de GitHub** del repo es el identificador unico de cada proyecto
- Si otra persona abre el mismo proyecto, Claude lee la documentacion existente en Notion y continua desde ahi
- Puedes pedir a Claude que actualice la documentacion en cualquier momento

### Nota sobre permisos

La integracion solo puede acceder a las paginas que le compartas explicitamente. Comparte la pagina raiz **"MV Projects"** y todas las sub-paginas heredaran el acceso automaticamente.

---

## 3. MV Brain (Data Lake / Company Brain)

`MV_BRAIN_TOKEN` es tu token **personal** para los skills que consultan y escriben en el Company Brain: `crear-cr`, `exp-iniciativa`, `editar-experimento`, `informe-resultados`, `kpi-context`, `research-mv`, `proponer-campana`, `ejecutar-campana`, `generar-lista-manychat`.

Es distinto a los demas tokens de esta guia: no conecta un MCP server, es el header `x-api-key` que autentica cada llamada de estos skills contra el endpoint `data-lake-mv.manzanaverde.la`. Sin el configurado, cualquiera de esos skills se detiene con error 401 en su primer paso — no hay fallback.

### Como funciona (por que no necesitas Notion/Discord/Supabase para esto)

Antes cada persona tenia credenciales de Notion, Discord y Supabase en su laptop para que los skills publicaran directo. Ahora el servidor hace ese trabajo por ti — tu laptop solo necesita `MV_BRAIN_TOKEN`:

```
Tu laptop (skill)                Servidor del Brain (data-lake-mv)

  MV_BRAIN_TOKEN   -- 1 llamada -->  verifica quien eres
  (lo unico tuyo)                    y publica por ti en:
                                        - Notion (tasks/issues)
                                        - Discord (threads)
                                        - Datalake (registros)
```

En la practica: usas `/crear-cr`, `/exp-iniciativa`, `/informe-resultados` o `/editar-experimento` como cualquier otro skill, y el servidor crea la task en Notion, publica el thread en Discord con la mencion al responsable y registra todo en el datalake — con tu nombre (el token te identifica, asi se llena solo el owner).

> El `NOTION_TOKEN` de la seccion 2 es para otra cosa (documentacion general de proyectos via `start-project`) — no sustituye a `MV_BRAIN_TOKEN` ni viceversa.

### Paso a paso

1. Solicitar tu token personal a **BizOps (Julio)** por canal privado (Slack DM o correo), indicando tu perfil (lectura / dri / dri-growth / finanzas / tech / exec). No se comparte por Discord ni se publica en ningun repo.
2. El token se entrega **una sola vez** (formato `mvb_...`) — guardalo en tu gestor de contrasenas.
3. Agregar a tu shell profile:

**Mac / Linux:**
```bash
export MV_BRAIN_TOKEN="mvb_tu-token-aqui"
```

**Windows (PowerShell):**
```powershell
$env:MV_BRAIN_TOKEN = "mvb_tu-token-aqui"
```

4. Recargar el terminal y verificar con `echo $MV_BRAIN_TOKEN` (Mac/Linux) o `echo $env:MV_BRAIN_TOKEN` (Windows).
5. Si acabas de instalar el plugin o vienes de una version anterior a v1.9.0, corre `/plugin update mv-dev` — versiones viejas del skill usan un contrato distinto y fallan aunque el token este bien configurado.

### Preguntas frecuentes

- **"El skill me dice 403"** — tu perfil no incluye ese dato (ej. KPIs financieros o de RR.HH. requieren scope adicional). Pide a Julio que ajuste tu perfil si lo necesitas para tu trabajo.
- **"Me dice token expirado"** — los tokens duran 180 dias. Pide renovacion a BizOps.
- **"Ya configure el token y sigue fallando"** — revisa el paso 5 (version del plugin); si el token es correcto y el plugin esta actualizado, avisa a BizOps.

### Nota sobre seguridad

- El token es personal e identifica tus consultas. **Nunca** lo compartas ni lo pegues en un repo, Notion o Discord.
- Expira a los 180 dias — pedir renovacion a BizOps.
- Si se compromete, avisar a BizOps para revocarlo de inmediato.

---

## 4. Supabase (Base de datos) — SOLO perfil Tech

> ⚠️ Este token solo lo necesita el equipo Tech. Si no haces desarrollo sobre la base de datos, **no lo configures** — los skills del Brain ya no lo usan.

Supabase permite a Claude gestionar la base de datos completa: crear tablas, ejecutar migraciones, queries, edge functions, y mas. Tambien puede obtener automaticamente la URL y anon key del proyecto para el `.env`.

### Paso a paso

1. Ir a **https://supabase.com/dashboard**
2. Iniciar sesion con la cuenta de MV (pedir acceso al Tech Lead si no tienes)
3. Click en tu **avatar/icono** (esquina superior derecha) → **"Account Preferences"**
4. En el menu lateral, ir a **"Access Tokens"**
5. Click en **"Generate New Token"**
6. Configurar:
   - **Name:** `MV Claude Code - [tu nombre]`
   - **Expiration:** 90 dias (o lo que permita)
7. Click en **"Generate Token"**
8. **Copiar el token inmediatamente** (no se muestra de nuevo)
9. Agregar a tu shell profile:

**Mac / Linux:**
```bash
# Agregar al final de ~/.zshrc (Mac) o ~/.bashrc (Linux)
export SUPABASE_ACCESS_TOKEN="sbp_tu-token-aqui"
```

**Windows (PowerShell):**
```powershell
# Agregar al perfil: notepad $PROFILE
$env:SUPABASE_ACCESS_TOKEN = "sbp_tu-token-aqui"
```

10. Recargar el terminal:

**Mac / Linux:** `source ~/.zshrc`
**Windows:** Cerrar y abrir una nueva terminal PowerShell

**Verificar:**
- Mac/Linux: `echo $SUPABASE_ACCESS_TOKEN`
- Windows: `echo $env:SUPABASE_ACCESS_TOKEN`

### Nota sobre seguridad

- El token da acceso a **todos** los proyectos de tu cuenta Supabase
- Claude tiene acceso completo a los proyectos de tu cuenta (crear tablas, migraciones, etc.)
- **Nunca** compartas tu token con nadie
- Si tu token se compromete, revocalo inmediatamente en Supabase dashboard

---

## Configuracion rapida (todo junto)

Si ya tienes los tokens, agrega todo de una vez (`SUPABASE_ACCESS_TOKEN` solo perfil Tech):

**Mac / Linux** - agregar a `~/.zshrc` o `~/.bashrc`:

```bash
# ============================================
# MV Plugin - Tokens para MCP Servers
# ============================================

# Context7 - Documentacion de librerias
# Obtener en: https://context7.com/dashboard
export CONTEXT7_API_KEY="ctx7sk-..."

# Notion - Documentacion de MV
# Obtener en: https://notion.so/my-integrations
export NOTION_TOKEN="ntn_..."

# MV Brain - Company Brain / Data Lake (token personal)
# Obtener: pedir a BizOps (Julio) por canal privado
export MV_BRAIN_TOKEN="..."

# Supabase - Base de datos (SOLO perfil Tech)
# Obtener en: https://supabase.com/dashboard → Account → Access Tokens
export SUPABASE_ACCESS_TOKEN="sbp_..."
```

Luego: `source ~/.zshrc`

**Windows (PowerShell)** - agregar a `$PROFILE` (`notepad $PROFILE`):

```powershell
# ============================================
# MV Plugin - Tokens para MCP Servers
# ============================================

# Context7 - Documentacion de librerias
# Obtener en: https://context7.com/dashboard
$env:CONTEXT7_API_KEY = "ctx7sk-..."

# Notion - Documentacion de MV
# Obtener en: https://notion.so/my-integrations
$env:NOTION_TOKEN = "ntn_..."

# MV Brain - Company Brain / Data Lake (token personal)
# Obtener: pedir a BizOps (Julio) por canal privado
$env:MV_BRAIN_TOKEN = "..."

# Supabase - Base de datos (SOLO perfil Tech)
# Obtener en: https://supabase.com/dashboard → Account → Access Tokens
$env:SUPABASE_ACCESS_TOKEN = "sbp_..."
```

Luego cerrar y abrir una nueva terminal PowerShell.

**Windows (alternativa sin PowerShell):** Agregar como variables de entorno del sistema:
1. `Win + R` → `sysdm.cpl` → Enter
2. Pestana **"Opciones avanzadas"** → **"Variables de entorno"**
3. En **"Variables de usuario"**, click **"Nueva"** para cada token
4. Poner el nombre (ej: `CONTEXT7_API_KEY`) y el valor (ej: `ctx7sk-...`)
5. Aceptar todo y reiniciar la terminal

---

## Verificar que todo funciona

Despues de configurar los tokens, reiniciar Claude Code y verificar:

**Mac / Linux:**
```bash
# 1. Verificar que las variables estan cargadas
echo $CONTEXT7_API_KEY
echo $NOTION_TOKEN
echo $SUPABASE_ACCESS_TOKEN
```

**Windows (PowerShell):**
```powershell
# 1. Verificar que las variables estan cargadas
echo $env:CONTEXT7_API_KEY
echo $env:NOTION_TOKEN
echo $env:SUPABASE_ACCESS_TOKEN
```

**Luego en cualquier sistema:**
```bash
# 2. Abrir Claude Code en cualquier proyecto
claude

# 3. Dentro de Claude Code, probar cada server:
# - Pedir documentacion de una libreria (usa Context7)
# - Preguntar sobre documentacion en Notion
# - Pedir info sobre tablas en Supabase
```

---

## Servidores que NO necesitan configuracion

Estos MCP servers funcionan sin tokens adicionales:

| Server | Descripcion |
|--------|-------------|
| **memory-keeper** | Memoria persistente entre sesiones. Funciona automaticamente. |
| **playwright** | Automatizacion de browser. Funciona automaticamente. |
| **mv-component-analyzer** | Analisis de componentes. Funciona automaticamente. |

---

## Servidores custom de MV (configuracion adicional)

### mv-db-query (MySQL / PostgreSQL)

Si necesitas acceso directo a una base de datos, agrega estas variables:

**Mac / Linux** - agregar a `~/.zshrc` o `~/.bashrc`:

```bash
# Tipo de base de datos: mysql | postgres (default: mysql)
export DB_ACCESS_TYPE="mysql"

# Credenciales de acceso (pedir al Tech Lead)
export DB_ACCESS_HOST="..."
export DB_ACCESS_PORT="3306"       # 3306 para MySQL, 5432 para PostgreSQL
export DB_ACCESS_USER="..."
export DB_ACCESS_PASSWORD="..."
export DB_ACCESS_NAME="..."
```

**Windows (PowerShell)** - agregar a `$PROFILE`:

```powershell
$env:DB_ACCESS_TYPE = "mysql"
$env:DB_ACCESS_HOST = "..."
$env:DB_ACCESS_PORT = "3306"
$env:DB_ACCESS_USER = "..."
$env:DB_ACCESS_PASSWORD = "..."
$env:DB_ACCESS_NAME = "..."
```

Tambien se pueden agregar en un archivo `.env` en la raiz del proyecto (aplica a todos los sistemas).

---

## Troubleshooting

### "MCP server failed to start"

- Verificar que Node.js 18+ esta instalado: `node --version`
- Verificar que las variables de entorno estan cargadas: `echo $VARIABLE`
- Reiniciar Claude Code completamente

### "Unauthorized" en Context7

- Verificar que el API key es correcto y no ha expirado
- Regenerar en https://context7.com/dashboard si es necesario

### "Unauthorized" en Notion

- Verificar que el token es correcto
- Verificar que las paginas estan compartidas con la integracion
- El token no expira, pero la integracion puede ser desactivada por un admin

### "Unauthorized" en Supabase

- Los tokens de Supabase expiran. Regenerar en el dashboard.
- Verificar que tienes acceso al proyecto correcto

### Un MCP server funciona pero otro no

Cada server es independiente. Si uno falla, los demas siguen funcionando. Puedes usar Claude Code normalmente mientras configuras los que faltan.

---

## Soporte

Si tienes problemas con la configuracion:
1. Consulta con el Tech Lead
2. Revisa los logs de Claude Code (aparecen errores de conexion de MCP servers al iniciar)
3. Abre un issue en el repositorio del plugin
