# 🔧 Workflow: Crear un Endpoint Express

Guía para crear un nuevo endpoint REST en el backend de MV con validación, autenticación y tests.

## ⏱️ Duración: 5-15 minutos

## 📋 Requisitos

- Proyecto Express backend de MV
- Tener claro: método HTTP, ruta, parámetros, autenticación

---

## 📍 Paso 1: Generar el Scaffold

```
/mv-dev:create-api
```

**El skill te preguntará:**

1. **¿Método HTTP?** (GET, POST, PUT, PATCH, DELETE)
2. **¿Ruta?** (ej: `/api/orders`, `/api/users/:id/subscription`)
3. **¿Descripción?** (ej: "Crear una nueva orden de delivery")
4. **¿Requiere autenticación?** (sí/no — casi siempre sí)
5. **¿Parámetros?** (body, query, path params)

**Lo que genera:**
```
src/
  routes/
    orders.ts          ← Router con la ruta
  controllers/
    ordersController.ts ← Lógica del endpoint
  services/
    ordersService.ts   ← Lógica de negocio
  types/
    orders.ts          ← Tipos TypeScript
  __tests__/
    orders.test.ts     ← Tests Jest
```

---

## 📍 Paso 2: Estructura Estándar de un Endpoint

### Tipos (types/orders.ts)

```typescript
export interface CreateOrderBody {
  deliveryDate: string;   // ISO 8601
  items: OrderItemInput[];
  addressId: string;
}

export interface OrderItemInput {
  productId: string;
  quantity: number;
}

export interface Order {
  id: string;
  userId: string;
  status: 'pending' | 'confirmed' | 'cancelled';
  total: number;          // centavos
  deliveryDate: string;
  items: OrderItemInput[];
  createdAt: string;
}
```

### Ruta (routes/orders.ts)

```typescript
import { Router } from 'express';
import { requireAuth } from '@/middleware/auth';
import { createOrder, getOrders } from '@/controllers/ordersController';

const router = Router();

// GET /api/orders - Listar órdenes del usuario
router.get('/', requireAuth, getOrders);

// POST /api/orders - Crear una orden
router.post('/', requireAuth, createOrder);

export default router;
```

### Controlador (controllers/ordersController.ts)

```typescript
import { Request, Response } from 'express';
import { z } from 'zod';
import { createOrderService, getOrdersService } from '@/services/ordersService';

// Schema de validación con Zod
const createOrderSchema = z.object({
  deliveryDate: z.string().datetime({ message: 'Fecha inválida, usar formato ISO 8601' }),
  addressId: z.string().uuid({ message: 'addressId debe ser un UUID válido' }),
  items: z.array(
    z.object({
      productId: z.string().uuid(),
      quantity: z.number().int().min(1).max(10),
    })
  ).min(1, 'Debe haber al menos 1 item'),
});

export async function createOrder(req: Request, res: Response) {
  try {
    const parsed = createOrderSchema.safeParse(req.body);

    if (!parsed.success) {
      return res.status(400).json({
        success: false,
        data: null,
        error: parsed.error.errors.map((e) => e.message).join(', '),
      });
    }

    const userId = req.user!.id; // seteado por requireAuth middleware
    const result = await createOrderService(userId, parsed.data);

    return res.status(201).json({ success: true, data: result });
  } catch (error) {
    console.error('[OrdersController] Error creating order:', error);
    return res.status(500).json({
      success: false,
      data: null,
      error: 'Error al crear la orden',
    });
  }
}

export async function getOrders(req: Request, res: Response) {
  try {
    const userId = req.user!.id;
    const page = Number(req.query.page ?? 1);
    const limit = Math.min(Number(req.query.limit ?? 20), 100);

    const result = await getOrdersService(userId, { page, limit });

    return res.json({
      success: true,
      data: result.orders,
      meta: {
        total: result.total,
        page,
        limit,
        totalPages: Math.ceil(result.total / limit),
      },
    });
  } catch (error) {
    console.error('[OrdersController] Error fetching orders:', error);
    return res.status(500).json({
      success: false,
      data: null,
      error: 'Error al obtener las órdenes',
    });
  }
}
```

### Servicio (services/ordersService.ts)

```typescript
import { db } from '@/lib/db';
import { CreateOrderBody, Order } from '@/types/orders';

export async function createOrderService(
  userId: string,
  data: CreateOrderBody
): Promise<Order> {
  // Calcular total
  const productIds = data.items.map((i) => i.productId);
  const products = await db.query<{ id: string; price: number }[]>(
    `SELECT id, price FROM products WHERE id IN (?) LIMIT ?`,
    [productIds, productIds.length]
  );

  const total = data.items.reduce((sum, item) => {
    const product = products.find((p) => p.id === item.productId);
    return sum + (product?.price ?? 0) * item.quantity;
  }, 0);

  // Insertar orden
  const orderId = crypto.randomUUID();
  await db.query(
    `INSERT INTO orders (id, user_id, status, total, delivery_date) VALUES (?, ?, 'pending', ?, ?)`,
    [orderId, userId, total, data.deliveryDate]
  );

  // Insertar items
  for (const item of data.items) {
    await db.query(
      `INSERT INTO order_items (order_id, product_id, quantity) VALUES (?, ?, ?)`,
      [orderId, item.productId, item.quantity]
    );
  }

  return { id: orderId, userId, status: 'pending', total, deliveryDate: data.deliveryDate, items: data.items, createdAt: new Date().toISOString() };
}

export async function getOrdersService(
  userId: string,
  { page, limit }: { page: number; limit: number }
): Promise<{ orders: Order[]; total: number }> {
  const offset = (page - 1) * limit;

  const [orders, [{ total }]] = await Promise.all([
    db.query<Order[]>(
      `SELECT id, user_id AS userId, status, total, delivery_date AS deliveryDate, created_at AS createdAt
       FROM orders WHERE user_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?`,
      [userId, limit, offset]
    ),
    db.query<[{ total: number }]>(
      `SELECT COUNT(*) AS total FROM orders WHERE user_id = ?`,
      [userId]
    ),
  ]);

  return { orders, total };
}
```

---

## 📍 Paso 3: Registrar la Ruta en el App Principal

```typescript
// src/index.ts o src/app.ts
import ordersRouter from './routes/orders';

app.use('/api/orders', ordersRouter);
```

---

## 📍 Paso 4: Tests del Endpoint

```typescript
// __tests__/orders.test.ts
import request from 'supertest';
import app from '../src/app';
import * as service from '../src/services/ordersService';

jest.mock('../src/services/ordersService');
jest.mock('../src/middleware/auth', () => ({
  requireAuth: (req: any, _res: any, next: any) => {
    req.user = { id: 'user-123' };
    next();
  },
}));

describe('POST /api/orders', () => {
  const validBody = {
    deliveryDate: '2026-06-01T12:00:00Z',
    addressId: '550e8400-e29b-41d4-a716-446655440000',
    items: [{ productId: '550e8400-e29b-41d4-a716-446655440001', quantity: 2 }],
  };

  it('crea una orden exitosamente', async () => {
    (service.createOrderService as jest.Mock).mockResolvedValue({ id: 'order-1', status: 'pending' });
    const res = await request(app).post('/api/orders').send(validBody);
    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.id).toBe('order-1');
  });

  it('retorna 400 con body inválido', async () => {
    const res = await request(app).post('/api/orders').send({ items: [] });
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error).toBeDefined();
  });

  it('retorna 500 si el servicio falla', async () => {
    (service.createOrderService as jest.Mock).mockRejectedValue(new Error('DB error'));
    const res = await request(app).post('/api/orders').send(validBody);
    expect(res.status).toBe(500);
    expect(res.body.success).toBe(false);
  });
});

describe('GET /api/orders', () => {
  it('retorna lista de órdenes con meta', async () => {
    (service.getOrdersService as jest.Mock).mockResolvedValue({
      orders: [{ id: 'o1' }],
      total: 1,
    });
    const res = await request(app).get('/api/orders');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.meta.total).toBe(1);
  });
});
```

---

## ✅ Checklist

- [ ] ¿Response format estándar (`success`, `data`, `error`, `meta`)?
- [ ] ¿Validación con Zod en el body?
- [ ] ¿Middleware `requireAuth` en rutas protegidas?
- [ ] ¿`try/catch` con logging específico?
- [ ] ¿Queries SQL con `LIMIT` y sin `SELECT *`?
- [ ] ¿Tests para: éxito, validación fallida, error de servidor?
- [ ] ¿Ruta registrada en `app.ts`/`index.ts`?

---

## 🚨 Troubleshooting

### "Zod parse error inesperado"
- Usar `safeParse` (no `parse`) para manejar errores sin throw
- Revisar el schema con `z.object({}).safeParse({}).error?.errors`

### "401 en todos los requests"
- Verificar que el token JWT está en el header `Authorization: Bearer <token>`
- Verificar que `requireAuth` está configurado correctamente

### "Tipos de Zod no coinciden con TypeScript"
- Usar `z.infer<typeof schema>` para derivar tipos desde el schema Zod

---

## 📚 Referencias

- [Skill create-api](10-SKILLS.md#create-api)
- [Estandares de Código](CODE_STANDARDS.md)
- [Escribir Tests](workflow-TESTS.md)
- [Variables de Entorno](ENVIRONMENT_VARS.md)
