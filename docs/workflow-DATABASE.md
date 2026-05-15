# 🗄️ Workflow: Hacer Queries a la Base de Datos

Guía para explorar y debuguear datos en la base de datos de staging de MV.

## ⏱️ Duración: 2-5 minutos

## ⚠️ Reglas Críticas

1. **SOLO staging** — nunca producción
2. **SOLO SELECT** — nunca DELETE, UPDATE, INSERT, DROP, ALTER, TRUNCATE
3. **SIEMPRE LIMIT** — nunca sin límite de filas
4. **NUNCA SELECT \*** — especificar columnas siempre

---

## 📋 Requisitos

Las variables `DB_ACCESS_*` deben estar configuradas en tu entorno:

```bash
# Verificar que están configuradas
echo $DB_ACCESS_HOST
echo $DB_ACCESS_NAME
```

Si no están configuradas, ver [Variables de Entorno](ENVIRONMENT_VARS.md).

---

## 📍 Paso 1: Abrir el Skill de Queries

```
/mv-dev:mv-db-queries
```

Este skill configura la conexión segura al MCP server de base de datos y te guía en cómo hacer queries.

---

## 📍 Paso 2: Explorar las Tablas

Antes de escribir un query, explora qué tablas existen:

```
Listar tablas disponibles
```

El MCP server `mv-db-query` responde con la lista de tablas accesibles.

**Ver la estructura de una tabla:**
```sql
-- El MCP describe la tabla
DESCRIBE orders;
-- o
SHOW COLUMNS FROM order_items;
```

---

## 📍 Paso 3: Escribir Queries Seguros

### Patrón básico

```sql
SELECT id, user_id, status, total, created_at
FROM orders
WHERE status = 'active'
ORDER BY created_at DESC
LIMIT 20;
```

### Con JOINs

```sql
SELECT
  o.id AS order_id,
  o.status,
  o.total,
  oi.product_id,
  oi.quantity
FROM orders o
INNER JOIN order_items oi ON oi.order_id = o.id
WHERE o.user_id = 'uuid-del-usuario'
ORDER BY o.created_at DESC
LIMIT 50;
```

### Conteos y agregados

```sql
SELECT
  status,
  COUNT(*) AS total_orders,
  SUM(total) AS revenue_centavos
FROM orders
WHERE created_at >= '2026-01-01'
GROUP BY status
LIMIT 10;
```

### Búsqueda por rango de fechas

```sql
SELECT id, user_id, status, total, created_at
FROM orders
WHERE created_at BETWEEN '2026-01-01 00:00:00' AND '2026-01-31 23:59:59'
ORDER BY created_at DESC
LIMIT 100;
```

---

## 📍 Paso 4: Tablas Principales de MV

| Tabla | Descripción | Columnas clave |
|-------|-------------|----------------|
| `users` | Usuarios registrados | `id`, `email`, `country`, `created_at` |
| `subscriptions` | Suscripciones activas | `id`, `user_id`, `plan_id`, `status`, `expires_at` |
| `orders` | Pedidos/órdenes | `id`, `user_id`, `status`, `total`, `delivery_date` |
| `order_items` | Items de cada orden | `id`, `order_id`, `product_id`, `quantity`, `unit_price` |
| `products` | Catálogo de comidas | `id`, `name`, `category`, `price`, `country` |
| `plans` | Planes de suscripción | `id`, `name`, `country`, `meals_per_week`, `price` |
| `deliveries` | Entregas programadas | `id`, `order_id`, `scheduled_at`, `status` |

Para ver la estructura completa: `/mv-dev:mv-docs` → buscar el nombre de la tabla.

---

## 📍 Paso 5: Casos de Uso Comunes

### "¿Cuántos usuarios activos hay en Peru?"
```sql
SELECT COUNT(*) AS total_activos
FROM subscriptions
WHERE status = 'active'
  AND country = 'PE'
LIMIT 1;
```

### "¿Qué órdenes tiene un usuario específico?"
```sql
SELECT id, status, total, created_at
FROM orders
WHERE user_id = 'el-uuid-del-usuario'
ORDER BY created_at DESC
LIMIT 20;
```

### "¿Cuáles son los productos más pedidos hoy?"
```sql
SELECT
  p.name,
  SUM(oi.quantity) AS total_pedidos
FROM order_items oi
INNER JOIN products p ON p.id = oi.product_id
INNER JOIN orders o ON o.id = oi.order_id
WHERE DATE(o.created_at) = CURDATE()
GROUP BY p.id, p.name
ORDER BY total_pedidos DESC
LIMIT 10;
```

### "¿Cuántas suscripciones vencen esta semana?"
```sql
SELECT COUNT(*) AS vencen_esta_semana
FROM subscriptions
WHERE status = 'active'
  AND expires_at BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 7 DAY)
LIMIT 1;
```

---

## ✅ Checklist de Query Seguro

- [ ] ¿Tiene `LIMIT`?
- [ ] ¿Especifica columnas (no `SELECT *`)?
- [ ] ¿Es solo `SELECT` (no modifica datos)?
- [ ] ¿Está apuntando a staging, no producción?
- [ ] ¿Tiene `WHERE` para no traer toda la tabla?

---

## 🚨 Troubleshooting

### "Connection refused"
- Verificar que `DB_ACCESS_HOST` y `DB_ACCESS_PORT` están correctos
- Pedir VPN al DevOps si la BD no es pública

### "Access denied for user"
- Las credenciales de solo lectura solo tienen permiso `SELECT`
- Si necesitas datos que no puedes leer, pedir al tech lead

### "Query muy lenta"
- Agregar índices en el `WHERE` — usar columnas indexadas (`id`, `user_id`, `created_at`)
- Reducir el `LIMIT`
- Evitar `JOIN` sin condición o con demasiadas tablas

### "Resultado vacío inesperado"
- Verificar que los valores de filtro son correctos (UUID, status exacto)
- La BD de staging puede no tener todos los datos de producción

---

## 📚 Referencias

- [Skill mv-db-queries](10-SKILLS.md#mv-db-queries)
- [Variables de Entorno](ENVIRONMENT_VARS.md)
- [MCP Servers (mv-db-query, supabase)](20-MCP_SERVERS.md)
