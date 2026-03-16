# 🔌 MCP Servers del Plugin MV Dev

El plugin incluye **7 MCP Servers** que extienden las capacidades de Claude Code. Entiende qué son y cómo usarlos.

## ¿Qué es un MCP Server?

**MCP** = Model Context Protocol (Protocolo de Contexto del Modelo)

Es un protocolo que permite a Claude Code acceder a herramientas y datos externos de forma segura:
- 🔑 Noción de autenticación mediante tokens
- 📡 Comunicación entre procesos
- 🛡️ Validación y límites de seguridad

**Analogía:** Es como un enchufe (MCP) que conecta Claude Code a un servicio externo (Database, Notion, etc.).

---

## 7 MCP Servers Disponibles

### Externos (5 - Incluidos por defecto)

#### 1. Context7
**Qué es:** Documentación actualizada de librerías de programación (React, TypeScript, Jest, etc.).

**Cuándo usarlo:**
- Necesitas ver ejemplos actualizados de una librería
- Tienes dudas sobre la sintaxis correcta
- Quieres aprender cómo usar un framework

**Requisitos:**
- `CONTEXT7_API_KEY` (opcional, funciona sin key pero con limitaciones)

**Ejemplo:**
```
Pregunta: "¿Cómo hacer un hook personalizado en React 18?"
Claude busca en Context7 y devuelve ejemplos actualizados
```

**Ventajas:**
- ✅ Documentación siempre actualizada
- ✅ Ejemplos de código reales
- ✅ Soporta 100+ librerías

---

#### 2. Memory Keeper
**Qué es:** Memoria persistente entre sesiones de Claude Code. Guarda decisiones, checkpoints y contexto.

**Cuándo usarlo:**
- Automático: se usa en background
- Útil para proyectos largos donde necesitas recordar decisiones anteriores

**Requisitos:**
- Ninguno (incluido por defecto)

**Ejemplo:**
```
Sesión 1: Decides usar Redux para state management
Sesión 2: Memory Keeper recuerda y aplica la misma arquitectura
```

**Ventajas:**
- ✅ Continuidad entre sesiones
- ✅ No repites decisiones
- ✅ Guardar benchmarks y resultados

---

#### 3. Playwright
**Qué es:** Automatización de navegador para testing E2E y validación visual.

**Cuándo usarlo:**
- Escribir tests E2E (Playwright)
- Validar componentes visualmente
- Testing de flujos completos en la app

**Requisitos:**
- Ninguno (incluido por defecto)
- Proyecto Next.js o React

**Ejemplo:**
```
Test E2E:
1. Navega a /login
2. Completa formulario
3. Valida que aparece dashboard
4. Comprueba que se guarda estado
```

**Herramientas:**
- Inspector visual
- Grabación de tests
- Modo headless/headed

---

#### 4. Notion
**Qué es:** Acceso a Notion para leer y crear documentación de APIs, tablas y proyectos.

**Cuándo usarlo:**
- Buscar documentación de APIs (via `/mv-dev:mv-docs`)
- Crear documentación de un proyecto nuevo
- Actualizar documentación existente

**Requisitos:**
- `NOTION_TOKEN` (necesario para funcionar)
- Notion debe estar integrado en tu workspace

**Permisos necesarios:**
- ✅ Read (leer documentación)
- ✅ Update (actualizar docs)
- ✅ Insert (crear new pages)

**Ejemplo:**
```
Buscar: "API de Pagos"
Notion devuelve:
- Endpoint
- Parámetros
- Response format
- Ejemplos de uso
```

---

#### 5. Supabase MCP
**Qué es:** Acceso completo a Supabase para crear tablas, ejecutar migraciones y queries.

**Cuándo usarlo:**
- Crear/modificar tablas en Supabase
- Ejecutar migraciones
- Hacer queries directas a la BD
- Configurar autenticación

**Requisitos:**
- `SUPABASE_ACCESS_TOKEN` (necesario)
- Proyecto Supabase existente

**Capacidades:**
- ✅ Crear tablas con tipos
- ✅ Migraciones SQL
- ✅ Queries (SELECT, INSERT, UPDATE)
- ✅ Edge functions
- ✅ Auth configuration

**Ejemplo:**
```
Crear tabla:
CREATE TABLE orders (
  id UUID PRIMARY KEY,
  user_id UUID,
  created_at TIMESTAMP
);
```

---

### Custom de Manzana Verde (2)

#### 6. mv-db-query
**Qué es:** Server MCP custom de MV para queries seguras a MySQL/PostgreSQL.

**Cuándo usarlo:**
- Hacer queries a la BD de staging
- Consultar estructura de tablas
- Validar datos para debugging

**Requisitos:**
- `DB_ACCESS_*` variables configuradas:
  ```
  DB_ACCESS_TYPE=mysql       # mysql | postgres
  DB_ACCESS_HOST=...
  DB_ACCESS_PORT=3306
  DB_ACCESS_USER=...
  DB_ACCESS_PASSWORD=...
  DB_ACCESS_NAME=...
  ```

**Limitaciones de Seguridad:**
- ⛔ SOLO lectura (SELECT permitido)
- ⛔ LIMIT obligatorio (no sin LIMIT)
- ⛔ Tablas bloqueadas: payments, user_payment_methods, api_keys, etc.
- ⛔ Sin DELETE, UPDATE, DROP, ALTER, TRUNCATE

**Ejemplo seguro:**
```sql
✅ SELECT id, name FROM products LIMIT 10;
❌ SELECT * FROM orders;              (sin LIMIT)
❌ UPDATE products SET name = 'x';    (no permitido)
❌ SELECT * FROM payments;            (tabla bloqueada)
```

---

#### 7. mv-component-analyzer
**Qué es:** Analizador de componentes React/Next.js para validar cumplimiento del design system de MV.

**Cuándo usarlo:**
- Validar que un componente siga el design system
- Encontrar inconsistencias de diseño
- Auditar colores, tipografía, spacing

**Requisitos:**
- Ninguno especial
- Componente React/Next.js

**Analiza:**
- ✅ Colores (usa mv-green, mv-orange, etc.)
- ✅ Tipografía (Inter, Nunito)
- ✅ Spacing (múltiplos de 4px)
- ✅ Border radius (12px, 8px, 4px)
- ✅ Accesibilidad
- ✅ Naming conventions

**Ejemplo:**
```
Analiza: components/Button.tsx
Reporte:
✅ Color primario correcto (mv-green-500)
✅ Tipografía correcta (Nunito)
⚠️ Spacing inconsistente (5px vs 4px base)
✅ Border radius estándar
⚠️ Falta atributo alt en icono
```

---

## 📊 Cuadro Resumen

| Server | Tipo | Requiere Token | Caso de Uso | Estado |
|--------|------|----------------|-----------|--------|
| **Context7** | Externo | Opcional | Documentación de librerías | ✅ Online |
| **Memory Keeper** | Externo | No | Memoria persistente | ✅ Online |
| **Playwright** | Externo | No | Testing E2E | ✅ Online |
| **Notion** | Externo | `NOTION_TOKEN` | Documentación de MV | ✅ Online |
| **Supabase** | Externo | `SUPABASE_ACCESS_TOKEN` | BD Supabase | ✅ Online |
| **mv-db-query** | Custom | `DB_ACCESS_*` | Queries staging | ✅ Online |
| **mv-component-analyzer** | Custom | No | Validar componentes | ✅ Online |

---

## 🔧 Cómo Usar Cada Server

### Para Context7 (Documentación)

```
Pregunta: "¿Cómo hacer un observable en RxJS?"
Claude busca en Context7 y devuelve ejemplos
```

**Sin invocar explícitamente** - Claude lo usa automáticamente cuando detecta pregunta sobre una librería.

---

### Para Memory Keeper (Memoria)

**Automático** - No necesitas hacer nada especial. El server:
- Guarda decisiones arquitectónicas
- Recuerda checkpoints
- Mantiene contexto entre sesiones

---

### Para Playwright (Testing E2E)

```
// Test example
test('user can login', async ({ page }) => {
  await page.goto('http://localhost:3000/login');
  await page.fill('input[name="email"]', 'user@example.com');
  await page.fill('input[name="password"]', 'pass123');
  await page.click('button:has-text("Login")');
  await expect(page).toHaveURL('/dashboard');
});
```

**Invocar:** Directamente en tests con Playwright API

---

### Para Notion (Documentación MV)

```
Usar skill: /mv-dev:mv-docs
Buscar: "Payments API"
Notion devuelve documentación completa
```

---

### Para Supabase (BD Supabase)

```
// Crear tabla
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  price INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);

// Insertar datos
INSERT INTO products (name, price) VALUES ('Apple', 500);

// Query
SELECT * FROM products WHERE price > 100 LIMIT 10;
```

---

### Para mv-db-query (BD Staging MySQL/PostgreSQL)

```
// Query segura a staging
SELECT id, name, price
FROM products
WHERE category = 'fruits'
LIMIT 100;

// ❌ NUNCA sin LIMIT
// ❌ NUNCA en tablas bloqueadas (payments, etc.)
```

**Invocar:** Skill `/mv-dev:mv-db-queries` o directamente en prompts

---

### Para mv-component-analyzer (Análisis)

```
"Analiza el componente ProductCard.tsx
para validar que cumple el design system"

Claude analiza y devuelve reporte
```

---

## ⚙️ Configuración

### Verificar que MCP Servers están cargados

Después de instalar el plugin, verifica en Claude Code que ves:
```
Available MCP Servers:
- context7
- memory-keeper
- playwright
- notion
- supabase-mcp
- mv-db-query
- mv-component-analyzer
```

Si alguno no aparece:
1. Reinicia Claude Code
2. Verifica que los tokens están en variables de entorno
3. Ejecuta: `claude plugin list`

---

## 🔐 Seguridad y Tokens

### Dónde NO guardar tokens
- ❌ Código fuente
- ❌ .env.local commitado
- ❌ Archivos de configuración públicos

### Dónde SÍ guardar
- ✅ Variables de entorno (`~/.zshrc`, `$PROFILE`)
- ✅ `.env.local` en gitignore
- ✅ Gestor de secretos del sistema

### Tokens necesarios por servidor

| Server | Token | Cómo obtener |
|--------|-------|-------------|
| Context7 | `CONTEXT7_API_KEY` | https://context7.com/dashboard |
| Notion | `NOTION_TOKEN` | https://notion.so/my-integrations |
| Supabase | `SUPABASE_ACCESS_TOKEN` | https://supabase.com/dashboard |
| BD MV | `DB_ACCESS_*` | Pedir al Tech Lead |

---

## 🚨 Troubleshooting

### "MCP Server no responde"
- Reinicia Claude Code
- Verifica conexión a internet
- Algunos servers descargan paquetes el primer uso

### "Token inválido"
- Verifica que copiaste el token completo
- Recarga terminal: `source ~/.zshrc`
- Reinicia Claude Code

### "Permission denied"
- Asegúrate de que el token tiene los permisos correctos
- En Notion: verifica que tiene Read, Update, Insert
- En Supabase: verifica access level

---

**Siguiente:** [Leer sobre Hooks de Validación →](30-HOOKS.md)
