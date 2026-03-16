# 🚀 Guía de Inicio Rápido

Instala y configura el plugin MV Dev en **5 minutos**.

## Instalación

```bash
claude plugin add https://github.com/manzanaverde/manzanaverde-plugin
```

## Configuración (3 pasos)

### Paso 1: Obtener tokens

Necesitas tokens de 4 servicios:

| Servicio | URL | Formato | Requerido |
|----------|-----|---------|-----------|
| **Context7** | https://context7.com/dashboard | `ctx7sk-...` | Muy recomendado |
| **Notion** | https://notion.so/my-integrations | `ntn_...` | Para documentación |
| **Supabase** | https://supabase.com/dashboard | `sbp_...` | Para bases de datos |
| **Base de datos MV** | Pedir al Tech Lead | Variables `DB_ACCESS_*` | Para queries |

### Paso 2: Agregar variables de entorno

**Mac/Linux** - Abre tu shell profile (`~/.zshrc` o `~/.bashrc`):

```bash
# Abre el archivo
nano ~/.zshrc

# Agrega estas líneas al final
export CONTEXT7_API_KEY="ctx7sk-tu-key-aqui"
export NOTION_TOKEN="ntn_tu-token-aqui"
export SUPABASE_ACCESS_TOKEN="sbp_tu-token-aqui"

# Guardar: Ctrl+O, Enter, Ctrl+X
```

**Windows (PowerShell)** - Abre tu perfil:

```powershell
# Abre el editor del perfil
notepad $PROFILE

# Agrega estas líneas
$env:CONTEXT7_API_KEY = "ctx7sk-tu-key-aqui"
$env:NOTION_TOKEN = "ntn_tu-token-aqui"
$env:SUPABASE_ACCESS_TOKEN = "sbp_tu-token-aqui"

# Guardar y cierra
```

### Paso 3: Recargar y verificar

```bash
# Mac/Linux
source ~/.zshrc

# Windows PowerShell
. $PROFILE
```

Reinicia Claude Code. Deberías ver los MCP servers en la interfaz.

## ✅ Verificación

Una vez configurado, verifica que todo funciona:

```
/mv-dev:discovery
```

Deberías ver el skill ejecutándose sin errores de tokens.

## 🎯 Primer Uso

### Crear un proyecto nuevo
```
/mv-dev:start-project
```
Responde las preguntas y tendrás un proyecto Next.js o Express listo.

### Crear una feature
```
/mv-dev:new-feature
```
Define el nombre y la descripción, y el plugin genera toda la estructura.

### Ver documentación de APIs
```
/mv-dev:mv-docs
```
Busca cualquier API o tabla en la documentación de Notion.

## 📚 Próximos Pasos

- Lee **[ARQUITECTURA](02-ARCHITECTURE.md)** para entender cómo funciona
- Ve a **[Skills](10-SKILLS.md)** para ver todos los 12 skills disponibles
- Consulta **[MCP Servers](20-MCP_SERVERS.md)** para entender los servidores

## ❓ Problemas Comunes

### Error: "Token no configurado"
- Verifica que agregaste la variable de entorno correctamente
- Ejecuta `echo $CONTEXT7_API_KEY` para confirmar que se ve
- Reinicia Claude Code (completamente, no solo pestaña)

### Error: "Cannot find module..."
- Algunos MCP servers descargan paquetes el primer uso
- Espera 1-2 minutos y reinicia Claude Code
- Si persiste, contacta al Tech Lead

### No aparecen los MCP servers
- Reinicia Claude Code completamente
- Verifica que el archivo `plugin.json` esté en lugar correcto
- Ejecuta `claude plugin list` para ver plugins instalados

---

**¿Listo?** → [Crear tu primer proyecto](workflow-PROJECT.md)
