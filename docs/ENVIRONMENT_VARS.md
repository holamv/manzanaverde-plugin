# 🔑 Variables de Entorno del Plugin MV Dev

Referencia completa de todas las variables de entorno soportadas.

---

## 📋 Resumen

| Variable | Requiere Token | Obligatorio | Sección |
|----------|---|---|---|
| `CONTEXT7_API_KEY` | Sí | ⭐ Recomendado | [Context7](#context7) |
| `NOTION_TOKEN` | Sí | ⭐ Para docs | [Notion](#notion) |
| `SUPABASE_ACCESS_TOKEN` | Sí | ⭐ Para BD Supabase | [Supabase](#supabase) |
| `DB_ACCESS_TYPE` | No | Para BD custom | [Base de Datos Custom](#base-de-datos-custom) |
| `DB_ACCESS_HOST` | No | Para BD custom | [Base de Datos Custom](#base-de-datos-custom) |
| `DB_ACCESS_PORT` | No | Para BD custom | [Base de Datos Custom](#base-de-datos-custom) |
| `DB_ACCESS_USER` | No | Para BD custom | [Base de Datos Custom](#base-de-datos-custom) |
| `DB_ACCESS_PASSWORD` | No | Para BD custom | [Base de Datos Custom](#base-de-datos-custom) |
| `DB_ACCESS_NAME` | No | Para BD custom | [Base de Datos Custom](#base-de-datos-custom) |
| `VERCEL_TOKEN` | No | Para deploy | [Deployment](#deployment) |
| `RAILWAY_TOKEN` | No | Para deploy | [Deployment](#deployment) |

---

## 🔌 MCP Server Variables

### Context7

**Variable:** `CONTEXT7_API_KEY`

**Formato:** `ctx7sk-...` (30+ caracteres)

**Para qué:** Documentación actualizada de librerías (React, Jest, TypeScript, etc.)

**Obligatorio:** ⭐ Muy recomendado (funciona sin clave pero limitado)

**Cómo obtener:**
1. Ve a https://context7.com/dashboard
2. Crea cuenta (gratuita)
3. Navega a "API Keys"
4. Genera nueva clave
5. Copia el token

**Ejemplo:**
```bash
export CONTEXT7_API_KEY="ctx7sk-abc123def456ghi789jkl"
```

**Verificación:**
```bash
curl -H "Authorization: Bearer $CONTEXT7_API_KEY" \
  https://api.context7.com/v1/health
# Debería retornar: { "status": "ok" }
```

---

### Notion

**Variable:** `NOTION_TOKEN`

**Formato:** `ntn_...` (40+ caracteres)

**Para qué:** Leer y escribir documentación de APIs y tablas en Notion

**Obligatorio:** ⭐ Necesario para `/mv-dev:mv-docs`

**Cómo obtener:**
1. Ve a https://notion.so/my-integrations
2. Haz clic en "New integration"
3. Nombre: "MV Claude Code"
4. Permisos: Read, Update, Insert
5. Copia el Internal Integration Token

**Ejemplo:**
```bash
export NOTION_TOKEN="ntn_123abc456def789ghi"
```

**Permisos requeridos:**
- ✅ Read - Leer documentación
- ✅ Update - Actualizar documentación
- ✅ Insert - Crear nuevas páginas
- ❌ Delete - NO requerido

**Verificación:**
```
Ejecuta: /mv-dev:mv-docs
Si funciona sin errores, el token es válido
```

---

### Supabase

**Variable:** `SUPABASE_ACCESS_TOKEN`

**Formato:** `sbp_...` (50+ caracteres)

**Para qué:** Crear/modificar tablas, migraciones, edge functions en Supabase

**Obligatorio:** ⭐ Necesario si usas Supabase

**Cómo obtener:**
1. Ve a https://supabase.com/dashboard
2. Tu avatar → Account Preferences
3. Sección "Access Tokens"
4. Generate New Token
5. Nombra: "Claude Code"
6. Selecciona expiración: 30-90 días
7. Copia el token

**Ejemplo:**
```bash
export SUPABASE_ACCESS_TOKEN="sbp_abc123def456ghi789jkl"
```

**Niveles de acceso:**
- `Admin` - Control total (recomendado)
- `User` - Acceso limitado
- Selecciona la que tenga permiso de lectura/escritura

**Verificación:**
```
Crear una tabla en Supabase vía Claude Code:

CREATE TABLE test_table (
  id UUID PRIMARY KEY,
  created_at TIMESTAMP DEFAULT NOW()
);

Si funciona, el token es válido
```

---

## 🗄️ Base de Datos Custom

Para conectarte a MySQL o PostgreSQL de staging.

### DB_ACCESS_TYPE

**Variable:** `DB_ACCESS_TYPE`

**Valores:** `mysql` | `postgres`

**Ejemplo:**
```bash
export DB_ACCESS_TYPE="mysql"
```

---

### DB_ACCESS_HOST

**Variable:** `DB_ACCESS_HOST`

**Formato:** IP o dominio del servidor

**Ejemplos:**
```bash
export DB_ACCESS_HOST="db.staging.manzanaverde.io"
export DB_ACCESS_HOST="192.168.1.100"
export DB_ACCESS_HOST="localhost"  # local dev
```

**Nota:** Si estás remoto, puede necesitar VPN

---

### DB_ACCESS_PORT

**Variable:** `DB_ACCESS_PORT`

**Valores por default:**
- MySQL: `3306`
- PostgreSQL: `5432`

**Ejemplos:**
```bash
export DB_ACCESS_PORT="3306"      # MySQL
export DB_ACCESS_PORT="5432"      # PostgreSQL
export DB_ACCESS_PORT="3307"      # Custom port
```

---

### DB_ACCESS_USER

**Variable:** `DB_ACCESS_USER`

**Formato:** Usuario de base de datos (debe ser read-only)

**Ejemplo:**
```bash
export DB_ACCESS_USER="staging_read"
export DB_ACCESS_USER="mv_developer"
```

**Seguridad:**
- Usuario debe tener permisos de SOLO LECTURA
- Nunca uses usuario admin
- El plugin valida que no seas admin

---

### DB_ACCESS_PASSWORD

**Variable:** `DB_ACCESS_PASSWORD`

**Formato:** Contraseña del usuario

**Ejemplo:**
```bash
export DB_ACCESS_PASSWORD="tu-password-segura"
```

**Seguridad:**
- ⚠️ NUNCA commitees contraseñas
- Guarda en variables de entorno SOLAMENTE
- Si se expone, contacta al Tech Lead para cambiarla

---

### DB_ACCESS_NAME

**Variable:** `DB_ACCESS_NAME`

**Formato:** Nombre de la base de datos

**Ejemplos:**
```bash
export DB_ACCESS_NAME="mv_staging"
export DB_ACCESS_NAME="manzana_verde_db"
```

---

## 🚀 Deployment Variables

### Vercel

**Variable:** `VERCEL_TOKEN`

**Para qué:** Deploy automático de Next.js a Vercel

**Obligatorio:** Opcional (si usas `/mv-dev:deploy-staging`)

**Cómo obtener:**
1. Ve a https://vercel.com/account/tokens
2. Create token
3. Nombra: "Claude Code"
4. Scope: Full Account
5. Copia el token

**Ejemplo:**
```bash
export VERCEL_TOKEN="vercel_abc123..."
```

---

### Railway

**Variable:** `RAILWAY_TOKEN`

**Para qué:** Deploy automático de Express a Railway

**Obligatorio:** Opcional (si usas `/mv-dev:deploy-staging`)

**Cómo obtener:**
1. Ve a https://railway.app/account/tokens
2. Create new token
3. Copia el token

**Ejemplo:**
```bash
export RAILWAY_TOKEN="railway_abc123..."
```

---

## 🔐 Dónde Guardar Variables

### ✅ Lugares Seguros

1. **Archivo de Shell Profile (Recomendado)**
   ```bash
   # ~/.zshrc o ~/.bashrc
   export CONTEXT7_API_KEY="ctx7sk-..."
   ```

2. **Variables de Sistema (Windows)**
   ```
   Settings → System → Environment Variables
   ```

3. **Gestor de Secrets**
   ```bash
   # 1Password, LastPass, Vault, etc.
   # Copia token en variable de entorno cuando lo necesites
   ```

### ❌ Lugares INSEGUROS

- ❌ Código fuente (`.ts`, `.js`, `.tsx`)
- ❌ Archivos `.env` que se commitean
- ❌ Documentación o wikis públicas
- ❌ Chat o mensajería sin encriptación
- ❌ Archivos compartidos en Google Drive/Dropbox

---

## 🚨 Seguridad

### Nunca Exponer Tokens

```
Las variables de entorno son privadas.
Si se exponen:
1. Contacta inmediatamente al Tech Lead
2. Genera nuevos tokens
3. Invalida los anteriores
```

### .gitignore

Asegúrate de que `.env.local` está en `.gitignore`:

```bash
# .gitignore
.env.local
.env*.local
.secrets
```

Verifica:
```bash
git check-ignore .env.local
# Debería retornar: .env.local
```

---

## ✅ Checklist de Configuración

- [ ] `CONTEXT7_API_KEY` configurada
- [ ] `NOTION_TOKEN` configurada
- [ ] `SUPABASE_ACCESS_TOKEN` configurada (si necesario)
- [ ] `DB_ACCESS_*` configuradas (si necesario)
- [ ] Variables cargadas: `echo $CONTEXT7_API_KEY` muestra valor
- [ ] Reinicié Claude Code
- [ ] `/mv-dev:discovery` funciona sin errores

---

## 🔍 Verificar Configuración

```bash
# Verificar que todas están cargadas
echo "Context7: $CONTEXT7_API_KEY"
echo "Notion: $NOTION_TOKEN"
echo "Supabase: $SUPABASE_ACCESS_TOKEN"

# O verificar una específica
echo $CONTEXT7_API_KEY    # Debería mostrar: ctx7sk-...
```

---

## 🆘 Troubleshooting

### "Variable not found"

**Solución:**
```bash
# 1. Verifica que la agregaste
nano ~/.zshrc

# 2. Recarga
source ~/.zshrc

# 3. Verifica de nuevo
echo $CONTEXT7_API_KEY
```

---

### "Invalid token"

**Solución:**
1. Copia el token nuevamente desde el dashboard
2. Asegúrate de no tener espacios extras
3. Si es muy antiguo, genera uno nuevo

---

### "Connection refused" (BD)

**Solución:**
1. Verifica `DB_ACCESS_HOST` y `DB_ACCESS_PORT` con Tech Lead
2. Prueba con cliente MySQL/PostgreSQL directo
3. Verifica que estás en VPN (si es necesario)

---

## 📚 Referencias

- [Setup Completo](03-SETUP.md)
- [Guía Rápida](01-QUICK_START.md)
- [MCP Servers](20-MCP_SERVERS.md)

