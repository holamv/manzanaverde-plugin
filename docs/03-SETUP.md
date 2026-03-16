# ⚙️ Configuración Completa del Plugin MV Dev

Guía paso a paso para configurar todos los tokens y variables de entorno.

## 📋 Resumen de lo Que Necesitas

| Componente | Token/Variable | Requerido | URL |
|------------|----------------|-----------|-----|
| **Context7** | `CONTEXT7_API_KEY` | ⭐ Recomendado | https://context7.com/dashboard |
| **Notion** | `NOTION_TOKEN` | ⭐ Para docs | https://notion.so/my-integrations |
| **Supabase** | `SUPABASE_ACCESS_TOKEN` | ⭐ Para BD | https://supabase.com/dashboard |
| **Base de datos MV** | `DB_ACCESS_*` | ⭐ Para queries | Pedir al Tech Lead |

---

## 🔑 Obtener Tokens

### 1. Context7 API Key

**Usar para:** Documentación actualizada de librerías (React, TypeScript, Jest, etc.)

**Pasos:**

1. Ve a https://context7.com/dashboard
2. Crea una cuenta (gratuita o paga)
3. Navega a "API Keys"
4. Haz clic en "Generate New Key"
5. Copia el token (formato: `ctx7sk-...`)

**Token obtenido:** `ctx7sk-abc123xyz...`

---

### 2. Notion Integration Token

**Usar para:** Buscar documentación de APIs y tablas en Notion (`/mv-dev:mv-docs`)

**Pasos:**

1. Ve a https://www.notion.so/my-integrations
2. Haz clic en "New integration"
3. Nombre: "MV Claude Code"
4. Selecciona permisos:
   - ✅ Read (leer documentación)
   - ✅ Update (actualizar documentación)
   - ✅ Insert (crear nuevas páginas)
5. Haz clic en "Submit"
6. Copia el token bajo "Internal Integration Token" (formato: `ntn_...`)

**Token obtenido:** `ntn_abc123xyz...`

**Próximo paso:** Comparte el token con el Tech Lead para que agregue permiso al workspace de Notion.

---

### 3. Supabase Access Token

**Usar para:** Crear/modificar tablas, migraciones, edge functions en Supabase

**Pasos:**

1. Ve a https://supabase.com/dashboard
2. Inicia sesión en tu cuenta
3. Navega a tu avatar → "Account Preferences"
4. Sección "Access Tokens"
5. Haz clic en "Generate New Token"
6. Nombra el token: "Claude Code"
7. Selecciona expiración (30-90 días recomendado)
8. Copia el token (formato: `sbp_...`)

**Token obtenido:** `sbp_abc123xyz...`

---

### 4. Base de Datos MV (DB_ACCESS_*)

**Usar para:** Hacer queries a la base de datos de staging

**Pasos:**

1. **Contacta al Tech Lead** con tu usuario
2. Solicita credenciales de acceso staging:
   - `DB_ACCESS_TYPE` (mysql o postgres)
   - `DB_ACCESS_HOST` (dirección del servidor)
   - `DB_ACCESS_PORT` (3306 para MySQL, 5432 PostgreSQL)
   - `DB_ACCESS_USER` (usuario de solo lectura)
   - `DB_ACCESS_PASSWORD` (contraseña)
   - `DB_ACCESS_NAME` (nombre de la base de datos)

3. **Guarda en lugar seguro** (NO en código)

---

## 🖥️ Agregar Variables de Entorno

### Mac / Linux

#### Opción A: Archivo de shell profile (Recomendado)

1. Abre la terminal
2. Abre tu archivo de perfil:
   ```bash
   # Si usas zsh (default en Mac M1+)
   nano ~/.zshrc

   # Si usas bash
   nano ~/.bashrc
   ```

3. Desplázate al final del archivo

4. Agrega estas líneas:
   ```bash
   # MCP Servers - MV Dev Plugin
   export CONTEXT7_API_KEY="ctx7sk-tu-token-aqui"
   export NOTION_TOKEN="ntn_tu-token-aqui"
   export SUPABASE_ACCESS_TOKEN="sbp_tu-token-aqui"

   # Base de datos MV Staging
   export DB_ACCESS_TYPE="mysql"           # mysql | postgres
   export DB_ACCESS_HOST="host.example.com"
   export DB_ACCESS_PORT="3306"
   export DB_ACCESS_USER="staging_read"
   export DB_ACCESS_PASSWORD="tu-password-aqui"
   export DB_ACCESS_NAME="mv_staging"
   ```

5. Guarda:
   - Presiona `Ctrl+O` (write out)
   - Presiona `Enter` (confirmar)
   - Presiona `Ctrl+X` (exit nano)

6. Recarga la configuración:
   ```bash
   source ~/.zshrc    # Si usas zsh
   # o
   source ~/.bashrc   # Si usas bash
   ```

7. Verifica que funcionó:
   ```bash
   echo $CONTEXT7_API_KEY
   # Debería mostrar: ctx7sk-...
   ```

#### Opción B: Archivo .env.local (Proyecto específico)

Si solo necesitas las variables en un proyecto:

1. En la raíz del proyecto, crea `.env.local`:
   ```bash
   CONTEXT7_API_KEY=ctx7sk-...
   NOTION_TOKEN=ntn_...
   SUPABASE_ACCESS_TOKEN=sbp_...
   ```

2. Agrega `.env.local` al `.gitignore`:
   ```bash
   echo ".env.local" >> .gitignore
   ```

**⚠️ Nota:** `.env.local` debe estar en `.gitignore` SIEMPRE. NUNCA commitear.

---

### Windows (PowerShell)

#### Opción A: Profile de PowerShell (Recomendado)

1. Abre PowerShell

2. Abre tu profile:
   ```powershell
   notepad $PROFILE
   ```
   (Si el archivo no existe, PowerShell lo creará)

3. Agrega estas líneas:
   ```powershell
   # MCP Servers - MV Dev Plugin
   $env:CONTEXT7_API_KEY = "ctx7sk-tu-token-aqui"
   $env:NOTION_TOKEN = "ntn_tu-token-aqui"
   $env:SUPABASE_ACCESS_TOKEN = "sbp_tu-token-aqui"

   # Base de datos MV Staging
   $env:DB_ACCESS_TYPE = "mysql"
   $env:DB_ACCESS_HOST = "host.example.com"
   $env:DB_ACCESS_PORT = "3306"
   $env:DB_ACCESS_USER = "staging_read"
   $env:DB_ACCESS_PASSWORD = "tu-password-aqui"
   $env:DB_ACCESS_NAME = "mv_staging"
   ```

4. Guarda y cierra el archivo

5. Recarga PowerShell (cierra y abre una ventana nueva)

6. Verifica:
   ```powershell
   echo $env:CONTEXT7_API_KEY
   # Debería mostrar: ctx7sk-...
   ```

#### Opción B: Variables de Entorno del Sistema

Si prefieres GUI:

1. Abre "Configuración" (Settings)
2. Busca "Variables de entorno"
3. Haz clic en "Editar las variables de entorno del sistema"
4. Haz clic en "Variables de entorno..."
5. Bajo "Variables de usuario", haz clic en "Nueva..."
6. Agrega cada variable:
   - Nombre: `CONTEXT7_API_KEY`
   - Valor: `ctx7sk-...`
7. Repite para cada variable
8. Haz clic en "Aceptar"
9. Reinicia cualquier terminal abierta

---

## ✅ Verificación

Después de agregar las variables, verifica que todo funciona:

### 1. Verificar Variables se Cargaron
```bash
# Mac/Linux
echo $CONTEXT7_API_KEY

# Windows PowerShell
echo $env:CONTEXT7_API_KEY
```

Debería mostrar el token (ej: `ctx7sk-abc...`)

### 2. Reiniciar Claude Code
- Cierra Claude Code completamente
- Abre Claude Code de nuevo
- Debería cargar los tokens automáticamente

### 3. Verificar MCP Servers
En Claude Code, deberías ver los MCP servers disponibles:
```
Available MCP Servers:
✅ context7
✅ memory-keeper
✅ playwright
✅ notion
✅ supabase-mcp
✅ mv-db-query
✅ mv-component-analyzer
```

### 4. Prueba Rápida
```
/mv-dev:discovery
```

Si se ejecuta sin errores de token, está todo configurado correctamente.

---

## 🔐 Checklist de Seguridad

- [ ] ¿Guardé los tokens en variables de entorno, NO en código?
- [ ] ¿Está `.env.local` en `.gitignore`?
- [ ] ¿Nunca commitear archivos `.env` con tokens?
- [ ] ¿Las credenciales de BD están seguras?
- [ ] ¿Los tokens tienen expiración configurada?

---

## 🚨 Troubleshooting

### "Token not found" / "NOTION_TOKEN is undefined"

**Causa:** La variable no se cargó correctamente

**Soluciones:**
1. Verifica que guardaste el archivo de perfil
2. Ejecuta: `source ~/.zshrc` (Mac/Linux)
3. Reinicia Claude Code (completamente)
4. Verifica con: `echo $NOTION_TOKEN`

---

### "Invalid token" / "Authentication failed"

**Causa:** Token incorrecto o expirado

**Soluciones:**
1. Copia el token nuevamente desde la página
2. Asegúrate de no tener espacios extras
3. Si es muy antiguo, genera uno nuevo
4. Verifica que tiene los permisos correctos (ej: Notion debe tener Read, Update, Insert)

---

### "Connection refused" (Base de datos)

**Causa:** Variables DB_ACCESS_* son incorrectas

**Soluciones:**
1. Verifica con el Tech Lead que los datos son correctos
2. Prueba la conexión con un cliente MySQL/PostgreSQL directo
3. Verifica que estás en VPN (si es necesario)

---

### MCP Server no aparece

**Causa:** El servidor no se inició correctamente

**Soluciones:**
1. Reinicia Claude Code
2. Algunos servidores descargan paquetes la primera vez
3. Espera 1-2 minutos
4. Si persiste, contata al Tech Lead

---

## 📝 Resumen

| Paso | Acción | Ubicación |
|------|--------|-----------|
| 1 | Obtener `CONTEXT7_API_KEY` | https://context7.com/dashboard |
| 2 | Obtener `NOTION_TOKEN` | https://notion.so/my-integrations |
| 3 | Obtener `SUPABASE_ACCESS_TOKEN` | https://supabase.com/dashboard |
| 4 | Pedir BD credentials al Tech Lead | Tech Lead |
| 5 | Agregar a `~/.zshrc` o `$PROFILE` | Tu terminal |
| 6 | `source ~/.zshrc` o reiniciar terminal | Tu terminal |
| 7 | Reiniciar Claude Code | Claude Code |
| 8 | Verificar con `/mv-dev:discovery` | Claude Code |

---

**¿Listo?** → [Ir a Guía de Inicio Rápido](01-QUICK_START.md)
