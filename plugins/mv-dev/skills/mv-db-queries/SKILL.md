---
description: Como hacer queries seguros de solo lectura a la base de datos de Manzana Verde (MySQL o PostgreSQL)
---

# Queries Seguros a Base de Datos

Guia para consultar la base de datos de forma segura usando el MCP server `mv-db-query`. Soporta MySQL y PostgreSQL (configurado via `DB_ACCESS_TYPE`).

## Reglas de Seguridad CRITICAS

1. **Solo SELECT** - Nunca ejecutar DELETE, UPDATE, INSERT, DROP, ALTER, TRUNCATE
2. **Siempre LIMIT** - Toda query debe incluir LIMIT (maximo 100 filas)
3. **Solo staging** - Nunca conectarse a la base de datos de produccion
4. **Queries parametrizados** - Nunca concatenar strings. Usar placeholders `?`
5. **Tablas bloqueadas** - No acceder a: `user_credentials`, `payment_methods`, `payments`, `user_payment_methods`, `stripe_tokens`, `admin_sessions` (default de `DB_BLOCKED_TABLES`, sobrescribible por cada dev)

## Usando el MCP Server mv-db-query

El plugin incluye un MCP server que expone 4 herramientas:

### 1. `query_db` - Ejecutar query

```
Herramienta: query_db
Input: { sql: "SELECT id, name, price_cents FROM meals WHERE active = ? LIMIT 20", params: [true] }
```

> Nota: Para PostgreSQL, los placeholders `?` se convierten automaticamente a `$1`, `$2`, etc.

### 2. `list_tables` - Ver tablas disponibles

```
Herramienta: list_tables
Input: {}
```

### 3. `describe_table` - Ver estructura de una tabla

```
Herramienta: describe_table
Input: { table: "meals" }
```

### 4. `get_sample_data` - Ver datos de ejemplo

```
Herramienta: get_sample_data
Input: { table: "orders", limit: 5 }
```

## Documentacion de Tablas en Notion (Fuente de Verdad)

**IMPORTANTE:** La documentacion completa y actualizada de las tablas SQL de MV esta en Notion. Antes de asumir columnas, tipos o relaciones, **usar `/mv-dev:mv-docs` para buscar el schema real** en Notion. Las tablas documentadas abajo son una referencia general, pero Notion siempre tiene la version mas actualizada.

## Schema de la Base de Datos (Referencia General)

### meals
| Columna | Tipo | Descripcion |
|---------|------|-------------|
| id | INT | ID unico |
| name | VARCHAR | Nombre del plato |
| description | TEXT | Descripcion |
| category | ENUM | breakfast, lunch, dinner, snack |
| calories | INT | Calorias |
| protein_grams | DECIMAL | Proteina en gramos |
| carbs_grams | DECIMAL | Carbohidratos en gramos |
| fat_grams | DECIMAL | Grasa en gramos |
| price_cents | INT | Precio en centavos |
| image_url | VARCHAR | URL de imagen |
| active | BOOLEAN | Si esta disponible |
| country_code | VARCHAR | PE, CO, MX, CL |
| created_at | DATETIME | Fecha de creacion |

### orders
| Columna | Tipo | Descripcion |
|---------|------|-------------|
| id | INT | ID unico |
| user_id | INT | ID del usuario |
| plan_id | INT | ID del plan |
| status | ENUM | pending, confirmed, preparing, delivering, delivered, cancelled |
| total_cents | INT | Total en centavos |
| delivery_date | DATE | Fecha de entrega |
| delivery_address_id | INT | ID de direccion |
| country_code | VARCHAR | PE, CO, MX, CL |
| created_at | DATETIME | Fecha de creacion |

### users (campos visibles)
| Columna | Tipo | Descripcion |
|---------|------|-------------|
| id | INT | ID unico |
| name | VARCHAR | Nombre completo |
| email | VARCHAR | Email |
| phone | VARCHAR | Telefono |
| country_code | VARCHAR | PE, CO, MX, CL |
| plan_id | INT | Plan actual |
| subscription_status | ENUM | active, paused, cancelled |
| created_at | DATETIME | Fecha de registro |

### plans
| Columna | Tipo | Descripcion |
|---------|------|-------------|
| id | INT | ID unico |
| name | VARCHAR | Nombre del plan |
| meals_per_day | INT | Comidas por dia |
| days_per_week | INT | Dias por semana |
| price_cents | INT | Precio mensual en centavos |
| country_code | VARCHAR | PE, CO, MX, CL |
| active | BOOLEAN | Si esta disponible |

### deliveries
| Columna | Tipo | Descripcion |
|---------|------|-------------|
| id | INT | ID unico |
| order_id | INT | ID del pedido |
| driver_id | INT | ID del repartidor |
| status | ENUM | assigned, picked_up, in_transit, delivered, failed |
| estimated_arrival | DATETIME | Hora estimada |
| actual_arrival | DATETIME | Hora real |
| latitude | DECIMAL | Ubicacion lat |
| longitude | DECIMAL | Ubicacion lng |

### addresses
| Columna | Tipo | Descripcion |
|---------|------|-------------|
| id | INT | ID unico |
| user_id | INT | ID del usuario |
| label | VARCHAR | "Casa", "Oficina" |
| address_line | VARCHAR | Direccion completa |
| city | VARCHAR | Ciudad |
| district | VARCHAR | Distrito/zona |
| latitude | DECIMAL | Lat |
| longitude | DECIMAL | Lng |
| delivery_zone_id | INT | Zona de cobertura |

## Queries de Ejemplo

### Pedidos por fecha
```sql
SELECT o.id, o.status, o.total_cents, o.delivery_date, u.name AS user_name
FROM orders o
JOIN users u ON u.id = o.user_id
WHERE o.delivery_date = '2026-01-30'
  AND o.country_code = 'PE'
ORDER BY o.created_at DESC
LIMIT 50
```

### Comidas mas populares
```sql
SELECT m.name, m.category, COUNT(om.id) AS order_count
FROM meals m
JOIN order_meals om ON om.meal_id = m.id
JOIN orders o ON o.id = om.order_id
WHERE o.created_at >= '2026-01-01'
GROUP BY m.id, m.name, m.category
ORDER BY order_count DESC
LIMIT 20
```

### Estado de entregas del dia
```sql
SELECT d.status, COUNT(*) AS count
FROM deliveries d
JOIN orders o ON o.id = d.order_id
WHERE o.delivery_date = CURDATE()
GROUP BY d.status
LIMIT 10
```

### Usuarios activos por pais
```sql
SELECT country_code, subscription_status, COUNT(*) AS user_count
FROM users
WHERE subscription_status IN ('active', 'paused')
GROUP BY country_code, subscription_status
ORDER BY country_code, user_count DESC
LIMIT 20
```

### Ingresos por plan
```sql
SELECT p.name AS plan_name, p.country_code,
       COUNT(o.id) AS total_orders,
       SUM(o.total_cents) / 100 AS total_revenue
FROM orders o
JOIN plans p ON p.id = o.plan_id
WHERE o.status = 'delivered'
  AND o.created_at >= '2026-01-01'
GROUP BY p.id, p.name, p.country_code
ORDER BY total_revenue DESC
LIMIT 20
```

## Tips de Performance

- Siempre incluir condiciones en `WHERE` para filtrar datos
- Usar `LIMIT` lo mas bajo posible para tu necesidad
- Evitar `SELECT *` - especificar columnas necesarias
- Los JOINs son costosos: limitar a 2-3 tablas por query
- Usar indices existentes: filtrar por `id`, `user_id`, `country_code`, `created_at`
- Para queries de conteo grande, usar `COUNT(*)` con filtros adecuados

## Skill relacionado

- `/mv-dev:mv-docs` - Buscar documentacion actualizada de APIs y tablas en Notion (fuente de verdad)

## Manejo de Fechas

- La BD almacena en UTC
- Para filtrar por fecha local, considerar el offset del pais:
  - Peru (PE): UTC-5
  - Colombia (CO): UTC-5
  - Mexico (MX): UTC-6
  - Chile (CL): UTC-3 / UTC-4

```sql
-- Pedidos de hoy en Peru (UTC-5)
WHERE o.delivery_date = DATE(CONVERT_TZ(NOW(), '+00:00', '-05:00'))
```
