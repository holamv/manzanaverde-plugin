# 🔌 Workflow: Consumir una API de MV

Guía para integrar correctamente una API existente de Manzana Verde en el frontend.

## ⏱️ Duración: 5-10 minutos

## 📋 Requisitos

- `MV_STAGING_API_URL` configurado en `.env.local`
- `MV_API_KEY` configurado en `.env.local`
- `NOTION_TOKEN` recomendado para leer la documentación

---

## 📍 Paso 1: Encontrar la Documentación de la API

```
/mv-dev:mv-docs
```

Busca por el nombre de la funcionalidad o el endpoint:

```
Busco: "orders history"
Busco: "payments"
Busco: "subscriptions"
```

**Output esperado:**
```
📌 Orders History API (v2.0)
Endpoint: GET /api/orders/history
Auth: Bearer token (requerido)
Query params:
  - status: "active" | "completed" | "cancelled" (opcional)
  - page: number (default: 1)
  - limit: number (default: 20, max: 100)
Response: ApiResponse<Order[]>
```

Si no está en Notion, pregunta al tech lead.

---

## 📍 Paso 2: Definir los Tipos

Crea los tipos en `types/` antes de hacer nada más:

```typescript
// types/orders.ts

// Siempre usar el formato ApiResponse<T> estándar de MV
export interface ApiResponse<T> {
  success: boolean;
  data: T;
  error?: string;
  meta?: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}

export type OrderStatus = 'active' | 'completed' | 'cancelled';

export interface Order {
  id: string;
  userId: string;
  status: OrderStatus;
  total: number;       // centavos (ej: 2500 = S/25.00)
  createdAt: string;   // ISO 8601 UTC
  items: OrderItem[];
}

export interface OrderItem {
  productId: string;
  name: string;
  quantity: number;
  unitPrice: number;   // centavos
}

export interface OrderFilters {
  status?: OrderStatus;
  page?: number;
  limit?: number;
}
```

---

## 📍 Paso 3: Crear el Servicio

Crea un servicio dedicado para cada dominio de API:

```typescript
// services/ordersService.ts
import { ApiResponse, Order, OrderFilters } from '@/types/orders';

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? '';

async function apiFetch<T>(
  path: string,
  token: string,
  options: RequestInit = {}
): Promise<ApiResponse<T>> {
  try {
    const res = await fetch(`${API_BASE}${path}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
        ...options.headers,
      },
    });

    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      return { success: false, data: null as T, error: err.error ?? `HTTP ${res.status}` };
    }

    return await res.json();
  } catch (error) {
    console.error(`[API] Error calling ${path}:`, error);
    return { success: false, data: null as T, error: 'Error de conexión' };
  }
}

export async function getOrderHistory(
  token: string,
  filters: OrderFilters = {}
): Promise<ApiResponse<Order[]>> {
  const params = new URLSearchParams(
    Object.entries(filters)
      .filter(([, v]) => v !== undefined)
      .map(([k, v]) => [k, String(v)])
  );
  return apiFetch<Order[]>(`/api/orders/history?${params}`, token);
}

export async function getOrderById(
  token: string,
  orderId: string
): Promise<ApiResponse<Order>> {
  return apiFetch<Order>(`/api/orders/${orderId}`, token);
}
```

---

## 📍 Paso 4: Usar el Servicio en Componentes

### Server Component (recomendado para datos iniciales)

```tsx
// app/orders/page.tsx
import { getOrderHistory } from '@/services/ordersService';
import { cookies } from 'next/headers';

export default async function OrdersPage() {
  const token = cookies().get('auth-token')?.value ?? '';
  const { success, data: orders, error } = await getOrderHistory(token, { limit: 20 });

  if (!success) return <div className="text-red-600">{error}</div>;
  if (!orders?.length) return <div>No tienes órdenes</div>;

  return (
    <ul>
      {orders.map((order) => (
        <li key={order.id}>{order.id} - {order.status}</li>
      ))}
    </ul>
  );
}
```

### Client Component (con estado local)

```tsx
// components/OrderList.tsx
'use client';
import { useEffect, useState } from 'react';
import { Order } from '@/types/orders';
import { getOrderHistory } from '@/services/ordersService';

export function OrderList({ token }: { token: string }) {
  const [orders, setOrders] = useState<Order[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getOrderHistory(token).then(({ success, data, error }) => {
      if (success) setOrders(data ?? []);
      else setError(error ?? 'Error');
      setIsLoading(false);
    });
  }, [token]);

  if (isLoading) return <OrderListSkeleton />;
  if (error) return <div className="text-red-600">{error}</div>;
  if (!orders.length) return <div className="text-mv-gray-500">Sin órdenes</div>;

  return <ul>{orders.map((o) => <OrderItem key={o.id} order={o} />)}</ul>;
}
```

---

## 📍 Paso 5: Formatear Datos para Display

```typescript
// lib/formatters.ts

// Dinero: almacenado en centavos, mostrar en la moneda del país
export function formatMoney(centavos: number, locale = 'es-PE', currency = 'PEN'): string {
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
  }).format(centavos / 100);
}

// Fechas: almacenadas en UTC, mostrar en timezone del usuario
export function formatDate(isoString: string): string {
  return new Date(isoString).toLocaleDateString('es-PE', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
  });
}
```

---

## ✅ Checklist

- [ ] ¿Tipos definidos en `types/` (sin `any`)?
- [ ] ¿Servicio con manejo de errores (`try/catch`)?
- [ ] ¿Bearer token pasado en header Authorization?
- [ ] ¿Dinero almacenado/procesado en centavos?
- [ ] ¿Fechas en UTC, formateadas en display?
- [ ] ¿Tests del servicio escritos?

---

## 🚨 Troubleshooting

### "401 Unauthorized"
- Verificar que el token está incluido en el header `Authorization: Bearer <token>`
- El token puede haber expirado — implementar refresh token

### "API no responde en staging"
- Verificar `MV_STAGING_API_URL` en `.env.local`
- Ejecutar `/mv-dev:mv-docs` para confirmar que el endpoint existe

### "Datos vienen como null"
- Revisar la estructura del `ApiResponse<T>` — acceder a `.data`, no al root
- Verificar que el tipo `T` coincide con lo que devuelve la API

---

## 📚 Referencias

- [Skills de Conocimiento: mv-api-consumer](10-SKILLS.md#mv-api-consumer)
- [Crear Feature completa](workflow-FEATURE.md)
- [Queries a base de datos](workflow-DATABASE.md)
- [Estandares de Código](CODE_STANDARDS.md)
