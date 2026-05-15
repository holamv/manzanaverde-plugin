# 🚀 Workflow: Crear una Feature Nueva

Guía paso a paso para agregar funcionalidad a un proyecto MV existente.

## ⏱️ Duración: 5-30 minutos (según complejidad)

## 📋 Requisitos

- Plugin MV Dev instalado
- Estar dentro de un proyecto MV existente
- Tener claro el objetivo de la feature

## 🎯 Objetivo

Al final de este workflow tendrás:
- ✅ Componentes/servicios con estructura correcta
- ✅ Tests escritos (cobertura >= 80%)
- ✅ Tipos TypeScript definidos
- ✅ Documentación de la feature
- ✅ Listo para PR

---

## 📍 Paso 1: Descubrir qué Existe (3-5 min)

Antes de escribir código, verifica qué APIs, tablas y servicios ya existen:

```
/mv-dev:discovery
```

**Responde:**
- ¿Qué quieres construir?
- ¿Qué usuarios lo usan?
- ¿Hay filtros, paginación, acciones?

**Resultado esperado:**
```
🔍 APIs encontradas:
✅ GET /api/orders - ya existe
✅ OrderService en services/orders.ts

📊 Tablas relevantes:
- orders (id, user_id, status, total)
- order_items (order_id, product_id, qty)

⚠️ Reutilizar OrderService existente, no crear uno nuevo
```

---

## 📍 Paso 2: Leer la Documentación (2-3 min)

Si la feature depende de una API, leer su documentación:

```
/mv-dev:mv-docs
```

**Busca:** nombre de la API o tabla que necesitas.

**Output:**
```
📌 Orders API (v2.0)
GET /api/orders?status=active&limit=20
Auth: Bearer token requerido
Response: { success: true, data: Order[], meta: { total, page } }
```

---

## 📍 Paso 3: Generar el Scaffold (2-5 min)

Crea la estructura base de la feature:

```
/mv-dev:new-feature
```

**El plugin te preguntará:**

1. **¿Nombre de la feature?**
   - Ej: `OrderHistory`, `PaymentIntegration`, `SearchFilters`

2. **¿Descripción?**
   - Ej: "Mostrar historial de órdenes con filtros por estado y fecha"

3. **¿Scope?**
   - `Frontend` - Solo componentes React
   - `Backend` - Solo servicios/API
   - `Ambos` - Componentes + API

**Lo que genera:**

```
components/
  OrderHistory/
    OrderHistory.tsx        ← Componente principal
    OrderHistoryItem.tsx    ← Subcomponente
    __tests__/
      OrderHistory.test.tsx ← Tests esqueleto
services/
  orderHistoryService.ts    ← Lógica de negocio
types/
  orderHistory.ts           ← Tipos TypeScript
docs/
  FEATURE_ORDER_HISTORY.md  ← Documentación
```

---

## 📍 Paso 4: Implementar la Lógica

Completa el código generado siguiendo los patrones de MV.

### Tipos primero (types/orderHistory.ts)

```typescript
export interface Order {
  id: string;
  status: 'active' | 'completed' | 'cancelled';
  total: number; // en centavos
  createdAt: string; // ISO 8601 UTC
  items: OrderItem[];
}

export interface OrderHistoryFilters {
  status?: Order['status'];
  dateFrom?: string;
  dateTo?: string;
}
```

### Servicio (services/orderHistoryService.ts)

```typescript
import { ApiResponse } from '@/types/api';
import { Order, OrderHistoryFilters } from '@/types/orderHistory';

export async function getOrderHistory(
  token: string,
  filters: OrderHistoryFilters = {}
): Promise<ApiResponse<Order[]>> {
  try {
    const params = new URLSearchParams(filters as Record<string, string>);
    const res = await fetch(`/api/orders?${params}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const data = await res.json();
    return { success: true, data: data.data };
  } catch (error) {
    console.error('[OrderHistoryService] Error fetching orders:', error);
    return { success: false, data: [], error: 'Error al cargar órdenes' };
  }
}
```

### Componente (components/OrderHistory/OrderHistory.tsx)

```tsx
'use client';
import { useEffect, useState } from 'react';
import { Order } from '@/types/orderHistory';
import { getOrderHistory } from '@/services/orderHistoryService';

interface Props {
  token: string;
}

export function OrderHistory({ token }: Props) {
  const [orders, setOrders] = useState<Order[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getOrderHistory(token).then(({ success, data, error }) => {
      if (success) setOrders(data);
      else setError(error ?? 'Error desconocido');
      setIsLoading(false);
    });
  }, [token]);

  if (isLoading) return <div className="animate-pulse">Cargando...</div>;
  if (error) return <div className="text-red-600">{error}</div>;
  if (orders.length === 0) return <div>No tienes órdenes aún</div>;

  return (
    <ul className="space-y-4">
      {orders.map((order) => (
        <li key={order.id} className="rounded-xl border border-mv-gray-200 bg-white p-4 shadow-sm">
          {/* contenido */}
        </li>
      ))}
    </ul>
  );
}
```

---

## 📍 Paso 5: Escribir Tests

Completa los tests esqueleto generados:

```typescript
// components/OrderHistory/__tests__/OrderHistory.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import { OrderHistory } from '../OrderHistory';
import * as service from '@/services/orderHistoryService';

jest.mock('@/services/orderHistoryService');

const mockOrders = [
  { id: '1', status: 'completed', total: 2500, createdAt: '2026-01-01T00:00:00Z', items: [] },
];

describe('OrderHistory', () => {
  it('muestra lista de órdenes', async () => {
    (service.getOrderHistory as jest.Mock).mockResolvedValue({ success: true, data: mockOrders });
    render(<OrderHistory token="mock-token" />);
    await waitFor(() => expect(screen.queryByText(/cargando/i)).not.toBeInTheDocument());
    expect(screen.getByText('1')).toBeInTheDocument();
  });

  it('muestra mensaje cuando no hay órdenes', async () => {
    (service.getOrderHistory as jest.Mock).mockResolvedValue({ success: true, data: [] });
    render(<OrderHistory token="mock-token" />);
    await waitFor(() => expect(screen.getByText(/no tienes órdenes/i)).toBeInTheDocument());
  });

  it('muestra error si falla la API', async () => {
    (service.getOrderHistory as jest.Mock).mockResolvedValue({ success: false, data: [], error: 'Error al cargar órdenes' });
    render(<OrderHistory token="mock-token" />);
    await waitFor(() => expect(screen.getByText(/error al cargar/i)).toBeInTheDocument());
  });
});
```

**Ejecuta los tests:**
```bash
npm test -- --coverage
```

**Objetivo:** >= 80% de cobertura.

---

## 📍 Paso 6: Validar Calidad

```bash
# TypeScript
npm run type-check

# Linting
npm run lint

# Tests con coverage
npm test -- --coverage
```

Todo debe pasar antes de abrir el PR.

---

## ✅ Checklist de Finalización

- [ ] ¿Tipos definidos en `types/`?
- [ ] ¿Servicio con manejo de errores correcto?
- [ ] ¿Componente con estados loading/error/empty/data?
- [ ] ¿Tests con cobertura >= 80%?
- [ ] ¿TypeScript compila sin errores (`any` prohibido)?
- [ ] ¿ESLint pasa?
- [ ] ¿Documentación actualizada en `docs/`?

---

## 🚨 Troubleshooting

### "No encuentro la API que necesito"
- Ejecuta `/mv-dev:mv-docs` y busca por funcionalidad
- Pregunta al tech lead si la API existe en staging

### "El tipo `any` aparece en el código generado"
- Nunca dejar `any`. Reemplazar con el tipo correcto o `unknown`
- Usa `/mv-dev:mv-docs` para ver los DTOs reales de la API

### "Los tests fallan por timeouts"
- Agregar `jest.setTimeout(10000)` al inicio del test
- Verificar que los mocks están bien configurados

---

## 📚 Referencias

- [Todos los Skills](10-SKILLS.md)
- [Consumir APIs de MV](workflow-API.md)
- [Escribir Tests](workflow-TESTS.md)
- [Design System](DESIGN_SYSTEM.md)
- [Estandares de Código](CODE_STANDARDS.md)

---

**Siguiente:** Cuando la feature esté lista, [deployar a staging →](workflow-DEPLOY.md)
