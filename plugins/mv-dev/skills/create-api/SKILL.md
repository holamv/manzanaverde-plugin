---
description: Crear un nuevo endpoint de API Express siguiendo los patrones de Manzana Verde con validacion Zod y response wrapper
---

# Nuevo Endpoint API de Manzana Verde

Crea un endpoint Express completo con validacion, autenticacion y el formato de respuesta estandar de MV.

## Paso 1: Preguntar al usuario

1. **Recurso** - Ej: `meals`, `orders`, `deliveries`
2. **Operacion:**
   - GET (listar) - `GET /api/v1/[recurso]`
   - GET (detalle) - `GET /api/v1/[recurso]/:id`
   - POST (crear) - `POST /api/v1/[recurso]`
   - PATCH (actualizar) - `PATCH /api/v1/[recurso]/:id`
   - DELETE (eliminar) - `DELETE /api/v1/[recurso]/:id`
3. **Necesita autenticacion?** - Si/No
4. **Descripcion** - Que hace el endpoint
5. **Campos del body** (si POST/PATCH) - Nombre, tipo, requerido?

## Paso 2: Crear archivos

### Schema de validacion (Zod)

```typescript
// schemas/[recurso]Schema.ts
import { z } from 'zod';

export const create[Recurso]Schema = z.object({
  name: z.string().min(1, 'Nombre es requerido').max(200),
  description: z.string().optional(),
  // ... otros campos
});

export const update[Recurso]Schema = create[Recurso]Schema.partial();

export const query[Recurso]Schema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
  search: z.string().optional(),
  sort: z.enum(['created_at', 'name', 'price']).default('created_at'),
  order: z.enum(['asc', 'desc']).default('desc'),
});

export type Create[Recurso]Input = z.infer<typeof create[Recurso]Schema>;
export type Update[Recurso]Input = z.infer<typeof update[Recurso]Schema>;
export type Query[Recurso]Input = z.infer<typeof query[Recurso]Schema>;
```

### Types

```typescript
// types/[recurso].ts
export interface [Recurso] {
  id: string;
  // ... campos
  createdAt: string;
  updatedAt: string;
}
```

### Service

```typescript
// services/[recurso]Service.ts
import { db } from '@/config/database';
import type { Create[Recurso]Input, Query[Recurso]Input } from '@/schemas/[recurso]Schema';
import type { [Recurso] } from '@/types/[recurso]';

export const [recurso]Service = {
  async list(query: Query[Recurso]Input): Promise<{ data: [Recurso][]; total: number }> {
    const offset = (query.page - 1) * query.limit;

    const [rows] = await db.execute(
      `SELECT * FROM [recurso]s
       WHERE deleted_at IS NULL
       ORDER BY ?? ${query.order === 'asc' ? 'ASC' : 'DESC'}
       LIMIT ? OFFSET ?`,
      [query.sort, query.limit, offset]
    );

    const [[{ total }]] = await db.execute(
      'SELECT COUNT(*) as total FROM [recurso]s WHERE deleted_at IS NULL'
    );

    return { data: rows as [Recurso][], total: (total as { total: number }).total };
  },

  async getById(id: string): Promise<[Recurso] | null> {
    const [rows] = await db.execute(
      'SELECT * FROM [recurso]s WHERE id = ? AND deleted_at IS NULL LIMIT 1',
      [id]
    );
    const results = rows as [Recurso][];
    return results[0] ?? null;
  },

  async create(input: Create[Recurso]Input): Promise<[Recurso]> {
    const id = crypto.randomUUID();
    await db.execute(
      'INSERT INTO [recurso]s (id, name, created_at, updated_at) VALUES (?, ?, NOW(), NOW())',
      [id, input.name]
    );
    return this.getById(id) as Promise<[Recurso]>;
  },

  async update(id: string, input: Partial<Create[Recurso]Input>): Promise<[Recurso] | null> {
    const existing = await this.getById(id);
    if (!existing) return null;

    const fields = Object.entries(input)
      .filter(([, v]) => v !== undefined)
      .map(([k]) => `${k} = ?`);
    const values = Object.values(input).filter(v => v !== undefined);

    if (fields.length > 0) {
      await db.execute(
        `UPDATE [recurso]s SET ${fields.join(', ')}, updated_at = NOW() WHERE id = ?`,
        [...values, id]
      );
    }

    return this.getById(id);
  },
};
```

### Controller

```typescript
// controllers/[recurso]Controller.ts
import type { Request, Response } from 'express';
import { [recurso]Service } from '@/services/[recurso]Service';
import { create[Recurso]Schema, query[Recurso]Schema } from '@/schemas/[recurso]Schema';
import { ZodError } from 'zod';

export const [recurso]Controller = {
  async list(req: Request, res: Response): Promise<void> {
    try {
      const query = query[Recurso]Schema.parse(req.query);
      const { data, total } = await [recurso]Service.list(query);

      res.json({
        success: true,
        data,
        meta: {
          total,
          page: query.page,
          limit: query.limit,
          totalPages: Math.ceil(total / query.limit),
        },
      });
    } catch (error) {
      if (error instanceof ZodError) {
        res.status(400).json({
          success: false,
          data: null,
          error: 'Parametros de consulta invalidos',
        });
        return;
      }
      console.error('[${Recurso}Controller] Error listing:', error);
      res.status(500).json({ success: false, data: null, error: 'Error interno' });
    }
  },

  async getById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const item = await [recurso]Service.getById(id);

      if (!item) {
        res.status(404).json({ success: false, data: null, error: 'No encontrado' });
        return;
      }

      res.json({ success: true, data: item });
    } catch (error) {
      console.error('[${Recurso}Controller] Error getting by id:', error);
      res.status(500).json({ success: false, data: null, error: 'Error interno' });
    }
  },

  async create(req: Request, res: Response): Promise<void> {
    try {
      const input = create[Recurso]Schema.parse(req.body);
      const item = await [recurso]Service.create(input);

      res.status(201).json({ success: true, data: item });
    } catch (error) {
      if (error instanceof ZodError) {
        res.status(400).json({
          success: false,
          data: null,
          error: 'Datos invalidos: ' + error.errors.map(e => e.message).join(', '),
        });
        return;
      }
      console.error('[${Recurso}Controller] Error creating:', error);
      res.status(500).json({ success: false, data: null, error: 'Error interno' });
    }
  },
};
```

### Routes

```typescript
// routes/[recurso]Routes.ts
import { Router } from 'express';
import { [recurso]Controller } from '@/controllers/[recurso]Controller';
import { requireAuth } from '@/middleware/auth';

const router = Router();

// Rutas publicas (si aplica)
// router.get('/', [recurso]Controller.list);

// Rutas protegidas
router.get('/', requireAuth, [recurso]Controller.list);
router.get('/:id', requireAuth, [recurso]Controller.getById);
router.post('/', requireAuth, [recurso]Controller.create);

export const [recurso]Routes = router;
```

### Registrar en routes/index.ts

```typescript
import { [recurso]Routes } from './[recurso]Routes';

router.use('/api/v1/[recurso]s', [recurso]Routes);
```

## Paso 0 — Clasificar y consultar la rubrica (antes de scaffoldear tests)

Antes de crear tests, clasificá el cambio (BUG / BET / RESUME) y consultá **`/mv-dev:test-decision`**:
- **BUG / trivial** (copy, color, config) → solo test de regresion del defecto, o **ninguno** si es trivial. NO scaffoldees tests de feature nueva.
- **BET (capacidad nueva)** → seguí el flujo TDD de abajo, eligiendo el tipo de test por superficie segun la rubrica.
- **RESUME (delta en progreso)** → mismo flujo que BET por superficie, pero testeá solo el delta nuevo.
- **Chequeá cobertura existente** (grep tests/__tests__/*.spec/*.test) antes de escribir; no dupliques.

## Paso 0b — Leé contexto antes de construir

Antes de scaffoldear el endpoint, leé el contexto relevante para el area que vas a tocar:

1. **docs/ del proyecto** (si existe): leé `API.md`, `TABLES.md`, `BUSINESS_LOGIC.md`. Si `docs/` no existe, lo crearás al final (create-once; no re-docs ahora).
2. **Cerebro del mirror** (`~/Projects/manzana-verde-os/`): leé `producto/ingenieria/data-dictionary.md` y `CONVENTIONS.md` para el recurso que vas a exponer. El SessionStart hook ya lo mantuvo fresco.
3. **NO re-fetchees Notion** para lo que ya esté en el mirror local — es redundante y quema tokens.
4. Con este contexto, confirmá nombres de tablas, convenciones de respuesta y campos antes de escribir codigo.

## Paso 3: Tests (para BET/capacidad nueva; ver Paso 0)

```typescript
// controllers/[recurso]Controller.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import request from 'supertest';
import { app } from '@/app';

describe('[Recurso] API', () => {
  describe('GET /api/v1/[recurso]s', () => {
    it('retorna lista paginada con formato MV', async () => {
      const res = await request(app)
        .get('/api/v1/[recurso]s?page=1&limit=10')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body).toMatchObject({
        success: true,
        data: expect.any(Array),
        meta: {
          total: expect.any(Number),
          page: 1,
          limit: 10,
          totalPages: expect.any(Number),
        },
      });
    });

    it('retorna 401 sin token', async () => {
      const res = await request(app).get('/api/v1/[recurso]s');
      expect(res.status).toBe(401);
    });
  });

  describe('POST /api/v1/[recurso]s', () => {
    it('crea recurso con datos validos', async () => {
      const res = await request(app)
        .post('/api/v1/[recurso]s')
        .set('Authorization', 'Bearer test-token')
        .send({ name: 'Test item' });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
    });

    it('retorna 400 con datos invalidos', async () => {
      const res = await request(app)
        .post('/api/v1/[recurso]s')
        .set('Authorization', 'Bearer test-token')
        .send({});

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });
  });
});
```

## Paso 4: Actualizar docs/ — Append del DELTA (OBLIGATORIO para BET)

**Regla**: NO reescribas el archivo entero. Agregá o editá SOLO las secciones que tu cambio tocó.

- **BUG / trivial**: doc mínima (una línea en CHANGELOG.md) o ninguna si es cosmético.
- **BET / capacidad nueva**: append del delta — entradas nuevas en los archivos afectados, nada más.
- **RESUME (delta en progreso)**: solo documenta el delta nuevo, no lo que ya estaba.

1. **Si `docs/` no existe**: crearlo completo ahora (create-once; ver doc-agent). A partir de aquí siempre existirá.
2. **Si `docs/` ya existe**: editá SOLO las secciones afectadas (no el archivo entero):

```markdown
# Agregar en docs/API.md (solo el endpoint nuevo):
## [Recurso]

### [METHOD] /api/v1/[recurso]s
- **Auth**: Required | Public
- **Query/Body**: [parametros con tipos]
- **Validation**: Zod schema [recurso]Schema
- **Response [status]**: { success: true, data: ... }
- **Response [error status]**: { success: false, error: "..." }

# Agregar en docs/TABLES.md (solo si hay tablas nuevas):
## [tabla]
| Columna | Tipo | Descripcion |
...

# Agregar en docs/CHANGELOG.md (solo la entrada nueva):
## [fecha] - Claude
- ✅ Endpoint [METHOD] /api/v1/[recurso]s: [descripcion]
```

3. Marcar el estado: ✅ si esta completo con tests, 🚧 si falta algo

4. **Actualizar `docs/PROJECT_SCOPE.md`** — SOLO las lineas que cambiaron:
   - Incrementar version y actualizar fecha
   - Agregar el endpoint en funcionalidades (✅/🚧)
   - Actualizar seccion de APIs consumidas/expuestas

## Checklist del Endpoint

- [ ] Schema Zod para validacion de input
- [ ] Service con queries parametrizados (nunca concatenar strings)
- [ ] Controller con try/catch y formato de respuesta MV
- [ ] Middleware de auth en rutas protegidas
- [ ] Rutas registradas en el router principal
- [ ] Tests para happy path y error cases
- [ ] Paginacion en endpoints de listado
- [ ] No exponer datos sensibles en respuestas
- [ ] `docs/` actualizado con el nuevo endpoint
