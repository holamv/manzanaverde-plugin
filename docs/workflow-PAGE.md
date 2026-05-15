# 📄 Workflow: Nueva Página Next.js

Guía para crear una página completa en Next.js con App Router, todos los estados y tests.

## ⏱️ Duración: 5-10 minutos

## 📋 Requisitos

- Proyecto Next.js con App Router (`app/` directory)
- Plugin MV Dev instalado

---

## 📍 Paso 1: Generar la Estructura

```
/mv-dev:new-page
```

**El skill te preguntará:**

1. **¿Cuál es la ruta?** (ej: `/orders/history`, `/profile`, `/dashboard/reports`)
2. **¿Qué muestra esta página?** (ej: "Lista de órdenes del usuario con filtros")
3. **¿Requiere autenticación?** (sí/no)
4. **¿Tiene filtros o parámetros de URL?** (sí/no)

**Lo que genera:**
```
app/
  orders/
    history/
      page.tsx        ← Página principal
      loading.tsx     ← Skeleton de carga
      error.tsx       ← Error boundary
      layout.tsx      ← Layout (si aplica)
      __tests__/
        page.test.tsx ← Tests RTL
```

---

## 📍 Paso 2: Estructura Estándar de una Página

### page.tsx

```tsx
// app/orders/history/page.tsx
import { Metadata } from 'next';
import { cookies } from 'next/headers';
import { getOrderHistory } from '@/services/ordersService';
import { OrderList } from '@/components/orders/OrderList';

export const metadata: Metadata = {
  title: 'Historial de Órdenes | Manzana Verde',
  description: 'Ver todas tus órdenes pasadas',
};

export default async function OrderHistoryPage() {
  const token = cookies().get('auth-token')?.value ?? '';
  const { success, data: orders, error } = await getOrderHistory(token, { limit: 20 });

  return (
    <main className="mx-auto max-w-3xl px-4 py-8">
      <h1 className="mb-6 text-2xl font-bold text-mv-gray-900 font-inter">
        Historial de Órdenes
      </h1>

      {!success && (
        <div className="rounded-xl bg-red-50 p-4 text-red-600">
          {error ?? 'Error al cargar tus órdenes'}
        </div>
      )}

      {success && <OrderList orders={orders ?? []} />}
    </main>
  );
}
```

### loading.tsx

```tsx
// app/orders/history/loading.tsx
export default function OrderHistoryLoading() {
  return (
    <main className="mx-auto max-w-3xl px-4 py-8">
      <div className="mb-6 h-8 w-48 animate-pulse rounded-lg bg-mv-gray-200" />
      <div className="space-y-4">
        {Array.from({ length: 5 }).map((_, i) => (
          <div key={i} className="h-24 animate-pulse rounded-xl bg-mv-gray-200" />
        ))}
      </div>
    </main>
  );
}
```

### error.tsx

```tsx
// app/orders/history/error.tsx
'use client';

interface Props {
  error: Error & { digest?: string };
  reset: () => void;
}

export default function OrderHistoryError({ error, reset }: Props) {
  return (
    <main className="mx-auto max-w-3xl px-4 py-8">
      <div className="rounded-xl border border-red-200 bg-red-50 p-6 text-center">
        <h2 className="mb-2 text-lg font-semibold text-red-700">
          Error al cargar la página
        </h2>
        <p className="mb-4 text-sm text-red-500">{error.message}</p>
        <button
          onClick={reset}
          className="rounded-xl bg-gradient-to-b from-mv-green-500 to-mv-green-600 px-6 py-2 text-white"
        >
          Intentar de nuevo
        </button>
      </div>
    </main>
  );
}
```

---

## 📍 Paso 3: Componentes de la Página

Separar la lógica de UI en componentes en `components/`:

```tsx
// components/orders/OrderList.tsx
import { Order } from '@/types/orders';
import { formatMoney, formatDate } from '@/lib/formatters';

interface Props {
  orders: Order[];
}

export function OrderList({ orders }: Props) {
  if (orders.length === 0) {
    return (
      <div className="rounded-xl border border-mv-gray-200 bg-mv-gray-50 p-8 text-center">
        <p className="text-mv-gray-500 font-nunito">No tienes órdenes aún</p>
      </div>
    );
  }

  return (
    <ul className="space-y-4">
      {orders.map((order) => (
        <li
          key={order.id}
          className="rounded-xl border border-mv-gray-200 bg-white p-4 shadow-sm"
        >
          <div className="flex items-center justify-between">
            <span className="text-sm text-mv-gray-500 font-nunito">
              {formatDate(order.createdAt)}
            </span>
            <span className="font-semibold text-mv-gray-900 font-inter">
              {formatMoney(order.total)}
            </span>
          </div>
          <StatusBadge status={order.status} />
        </li>
      ))}
    </ul>
  );
}

function StatusBadge({ status }: { status: Order['status'] }) {
  const styles = {
    active: 'bg-mv-green-50 text-mv-green-500',
    completed: 'bg-mv-gray-50 text-mv-gray-500',
    cancelled: 'bg-red-50 text-red-600',
  };

  return (
    <span className={`mt-1 inline-block rounded-full px-2 py-0.5 text-xs ${styles[status]}`}>
      {status}
    </span>
  );
}
```

---

## 📍 Paso 4: Tests de la Página

```typescript
// app/orders/history/__tests__/page.test.tsx
import { render, screen } from '@testing-library/react';
import OrderHistoryPage from '../page';
import * as service from '@/services/ordersService';

// Next.js cookies mock
jest.mock('next/headers', () => ({
  cookies: () => ({ get: () => ({ value: 'mock-token' }) }),
}));
jest.mock('@/services/ordersService');

describe('OrderHistoryPage', () => {
  it('muestra el heading de la página', async () => {
    (service.getOrderHistory as jest.Mock).mockResolvedValue({ success: true, data: [] });
    render(await OrderHistoryPage());
    expect(screen.getByRole('heading', { name: /historial/i })).toBeInTheDocument();
  });

  it('muestra error cuando falla el servicio', async () => {
    (service.getOrderHistory as jest.Mock).mockResolvedValue({
      success: false, data: null, error: 'Error al cargar',
    });
    render(await OrderHistoryPage());
    expect(screen.getByText(/error al cargar/i)).toBeInTheDocument();
  });
});
```

---

## 📍 Paso 5: Agregar la Ruta a la Navegación (si aplica)

Si la página necesita un link en el menú o sidebar, agregar en el componente de navegación del proyecto.

---

## ✅ Checklist

- [ ] ¿`page.tsx` creado con metadata?
- [ ] ¿`loading.tsx` con skeleton apropiado?
- [ ] ¿`error.tsx` con botón de reintentar?
- [ ] ¿Componentes separados en `components/`?
- [ ] ¿Estados: loading, error, empty, datos?
- [ ] ¿Tests de la página escritos?
- [ ] ¿Design tokens de MV (no hex hardcodeados)?
- [ ] ¿TypeScript estricto (sin `any`)?

---

## 🚨 Troubleshooting

### "cookies() is not available in Client Components"
- `cookies()` solo funciona en Server Components
- Para Client Components, pasar el token como prop desde el Server Component

### "Hydration mismatch"
- Verificar que el renderizado server y client son idénticos
- Evitar `Math.random()`, `Date.now()` sin seed en el render inicial

### "La página no aparece en el router"
- Verificar que el archivo se llama exactamente `page.tsx` (minúsculas)
- Verificar que está dentro de la carpeta correcta en `app/`

---

## 📚 Referencias

- [Skill new-page](10-SKILLS.md#new-page)
- [Design System (colores, tipografía)](DESIGN_SYSTEM.md)
- [Consumir APIs](workflow-API.md)
- [Escribir Tests](workflow-TESTS.md)
