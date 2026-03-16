# 📋 Estándares de Código de Manzana Verde

Convenciones y patrones obligatorios en todos los proyectos de MV.

---

## 📝 Convenciones de Nombrado

### Archivos

| Tipo | Patrón | Ejemplo |
|------|--------|---------|
| Componente React | PascalCase | `ProductCard.tsx` |
| Página Next.js | lowercase/ruta | `app/products/page.tsx` |
| Servicio | camelCase | `orderService.ts` |
| Tipo/Interface | PascalCase | `Product.ts`, `User.ts` |
| Utilidad | camelCase | `formatPrice.ts`, `calculateTotal.ts` |
| Hook custom | camelCase + "use" | `useAuth.ts`, `useOrders.ts` |
| Test | same + ".test.ts" | `orderService.test.ts` |

### Variables y Funciones

```typescript
// ✅ CORRECTO
const userId = "123";
const isActive = true;
const calculateTotal = (items: Item[]): number => {...}

// ❌ INCORRECTO
const user_id = "123";     // snake_case (no)
const userId123 = "123";   // números en el medio (no)
const CalculateTotal = () => {}; // PascalCase en función (no)
```

### Constantes

```typescript
// ✅ CORRECTO
const MAX_ITEMS_PER_PAGE = 10;
const DEFAULT_CURRENCY = 'PEN';
const API_TIMEOUT_MS = 5000;

// ❌ INCORRECTO
const maxItems = 10;        // debería ser SCREAMING_SNAKE_CASE
const max_items_per_page = 10;  // debería ser camelCase o SCREAMING
```

---

## 🎨 TypeScript

### Strict Mode - OBLIGATORIO

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true
  }
}
```

### Tipos Específicos - NUNCA `any`

```typescript
// ❌ PROHIBIDO
const data: any = response.data;

// ✅ CORRECTO
interface OrderResponse {
  id: string;
  total: number;
  items: OrderItem[];
}
const data: OrderResponse = response.data;
```

### Imports

```typescript
// ✅ CORRECTO - Ordenar por: external, internal, relative
import React from 'react';
import { useState } from 'react';

import { OrderService } from '@/services';
import { Order } from '@/types';

import { formatPrice } from './utils';

// ❌ INCORRECTO - Desordenados
import { formatPrice } from './utils';
import { OrderService } from '@/services';
import React from 'react';
```

---

## 🔐 Seguridad

### NUNCA hardcodear secrets

```typescript
// ❌ PROHIBIDO
const apiKey = "ctx7sk-abc123xyz";
const dbPassword = "admin123";

// ✅ CORRECTO
const apiKey = process.env.CONTEXT7_API_KEY;
const dbPassword = process.env.DB_PASSWORD;
```

### NUNCA hacer queries sin LIMIT

```sql
-- ❌ PROHIBIDO
SELECT * FROM orders;
SELECT * FROM users WHERE active = true;

-- ✅ CORRECTO
SELECT * FROM orders LIMIT 100;
SELECT * FROM users WHERE active = true LIMIT 50;
```

### NUNCA hacer operaciones destructivas en BD

```sql
-- ❌ PROHIBIDO (nunca permitido en código)
DELETE FROM orders;
UPDATE users SET password = 'hack';
DROP TABLE payments;

-- ✅ Si necesitas actualizar (muy raro):
-- 1. Consulta con Tech Lead
-- 2. Usa migraciones (Supabase)
-- 3. Nunca en scripts de aplicación
```

---

## 🎯 React / Next.js

### Componentes Funcionales

```typescript
// ✅ CORRECTO
export interface ProductCardProps {
  product: Product;
  onBuy?: () => void;
}

export function ProductCard({ product, onBuy }: ProductCardProps) {
  return (
    <div className="bg-white rounded-xl p-4">
      <h3>{product.name}</h3>
      <p className="text-mv-gray-500">{product.description}</p>
      <button onClick={onBuy}>Buy</button>
    </div>
  );
}

// ❌ INCORRECTO
export default function ProductCard(props: any) {
  return <div>...</div>;
}
```

### Metadata en Páginas

```typescript
// ✅ CORRECTO
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Products - Manzana Verde',
  description: 'Browse our healthy meal plans',
  openGraph: {
    title: 'Products',
    description: 'Browse our healthy meal plans',
    type: 'website'
  }
};

export default function ProductsPage() {
  return <div>Products</div>;
}

// ❌ INCORRECTO - Sin metadata
export default function ProductsPage() {
  return <div>Products</div>;
}
```

### next/image OBLIGATORIO

```typescript
// ❌ INCORRECTO
<img src="/product.jpg" alt="product" />

// ✅ CORRECTO
import Image from 'next/image';

<Image
  src="/product.jpg"
  alt="Product image"
  width={300}
  height={300}
  priority={false}
/>
```

### "use client" solo cuando sea necesario

```typescript
// ✅ CORRECTO
// app/products/page.tsx (Server Component por default)
export default function ProductsPage() {
  const products = await getProducts(); // Server-side fetch
  return <ProductsList products={products} />;
}

// app/components/ProductsList.tsx (Client Component si necesita interactividad)
'use client';
import { useState } from 'react';
export function ProductsList({ products }) {
  const [filtered, setFiltered] = useState(products);
  return ...;
}

// ❌ INCORRECTO - Marcar todo como 'use client'
'use client';
export default function EntireApp() {
  return ...;
}
```

---

## 🔌 API / Backend

### Response Format Estándar

```typescript
// ✅ CORRECTO - Formato MV estándar
interface ApiResponse<T> {
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

export async function GET(req: Request) {
  try {
    const orders = await getOrders();
    return Response.json({
      success: true,
      data: orders,
      meta: { total: orders.length }
    });
  } catch (error) {
    return Response.json(
      { success: false, error: 'Failed to fetch orders' },
      { status: 500 }
    );
  }
}

// ❌ INCORRECTO - Response format incorrecto
export async function GET(req: Request) {
  const orders = await getOrders();
  return Response.json(orders);
}
```

### Validación con Zod

```typescript
// ✅ CORRECTO
import { z } from 'zod';

const createOrderSchema = z.object({
  items: z.array(z.object({
    product_id: z.string().min(1),
    quantity: z.number().int().min(1)
  })),
  delivery_date: z.string().datetime(),
  notes: z.string().optional()
});

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const validated = createOrderSchema.parse(body);
    const order = await createOrder(validated);
    return Response.json({ success: true, data: order });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return Response.json(
        { success: false, error: 'Invalid input', details: error.errors },
        { status: 400 }
      );
    }
    return Response.json(
      { success: false, error: 'Server error' },
      { status: 500 }
    );
  }
}

// ❌ INCORRECTO - Sin validación
export async function POST(req: Request) {
  const { items, delivery_date } = await req.json();
  // usar sin validar...
}
```

### Try/Catch en operaciones

```typescript
// ✅ CORRECTO
export async function findOrderById(id: string) {
  try {
    const order = await db.orders.findUnique({ where: { id } });
    if (!order) {
      throw new Error(`Order not found: ${id}`);
    }
    return order;
  } catch (error) {
    console.error('[Orders] Error finding order:', error);
    throw error;
  }
}

// ❌ INCORRECTO - Sin error handling
export async function findOrderById(id: string) {
  const order = await db.orders.findUnique({ where: { id } });
  return order;
}
```

---

## 🧪 Testing

### Cobertura >= 80%

```bash
# Ejecutar tests con cobertura
npm test -- --coverage

# Resultado esperado:
# ✅ Lines: 85%
# ✅ Statements: 88%
# ✅ Branches: 82%
# ✅ Functions: 90%
```

### Estructura de Tests

```typescript
// ✅ CORRECTO
import { calculateTotal } from './calculateTotal';

describe('calculateTotal', () => {
  describe('when items have prices', () => {
    it('should sum all prices', () => {
      const items = [{ price: 100 }, { price: 200 }];
      expect(calculateTotal(items)).toBe(300);
    });

    it('should apply discount if provided', () => {
      const items = [{ price: 100 }];
      expect(calculateTotal(items, 0.1)).toBe(90);
    });
  });

  describe('edge cases', () => {
    it('should return 0 for empty items', () => {
      expect(calculateTotal([])).toBe(0);
    });

    it('should handle negative prices', () => {
      // Test para comportamiento esperado con valores negativos
    });
  });
});

// ❌ INCORRECTO
it('tests everything', () => {
  expect(calculateTotal([{ price: 100 }])).toBe(100);
  expect(calculateTotal([])).toBe(0);
  expect(calculateTotal([{ price: 100 }], 0.1)).toBe(90);
});
```

---

## 🎨 Tailwind / CSS

### NUNCA hardcodear colores hex

```jsx
// ❌ PROHIBIDO
<button className="bg-[#227A4B] text-white">
  Buy
</button>

// ✅ CORRECTO - Usar tokens MV
<button className="bg-mv-green-500 text-white hover:bg-mv-green-600">
  Buy
</button>
```

### Spacing base 4px

```jsx
// ✅ CORRECTO - Múltiplos de 4px
<div className="p-4 mb-8 mt-6">    // 16px, 32px, 24px
  <h2 className="mb-4">Title</h2>   // 16px abajo
  <p className="mb-2">Desc</p>      // 8px abajo
</div>

// ❌ INCORRECTO - Valores arbitrarios
<div className="p-5 mb-7 mt-9">     // 20px, 28px, 36px (no base 4)
  ...
</div>
```

### Border Radius Estándar

```jsx
// ✅ CORRECTO
<div className="rounded-lg">       // 8px (inputs)
<div className="rounded-xl">       // 12px (cards, default)
<section className="rounded-2xl">  // 16px (containers grandes)

// ❌ INCORRECTO
<div className="rounded-[7px]">    // valores arbitrarios
<div className="rounded-[15px]">
```

---

## 📝 Comments y Documentación

### Solo comentarios necesarios

```typescript
// ✅ CORRECTO - Comenta el "por qué", no el "qué"
// Retry con backoff exponencial porque el servicio de pagos
// tiene latencia variable (100ms-5s)
const delay = Math.min(1000 * Math.pow(2, attempt), 10000);

// ❌ INCORRECTO - Comenta lo obvio
// Incrementar attempt
attempt++;

// Esperar delay
await new Promise(resolve => setTimeout(resolve, delay));
```

### JSDoc para funciones públicas

```typescript
// ✅ CORRECTO
/**
 * Calcula el total de una orden incluyendo impuestos y descuentos
 * @param items - Array de items de la orden
 * @param discount - Descuento como decimal (0.1 = 10%)
 * @returns Total en centavos (entero)
 */
export function calculateTotal(
  items: OrderItem[],
  discount: number = 0
): number {
  // implementación...
}

// ❌ INCORRECTO - Sin documentación
export function calculateTotal(items: any[], discount: any) {
  // ...
}
```

---

## 🚀 Patrones Recomendados

### Async/Await en lugar de .then()

```typescript
// ✅ CORRECTO
async function processOrder(orderId: string) {
  try {
    const order = await getOrder(orderId);
    const payment = await processPayment(order);
    await saveOrder(order, payment);
    return { success: true, data: order };
  } catch (error) {
    console.error('[Orders] Error processing:', error);
    return { success: false, error: 'Processing failed' };
  }
}

// ❌ INCORRECTO - .then() chains
function processOrder(orderId: string) {
  return getOrder(orderId)
    .then(order => processPayment(order).then(payment => ({ order, payment })))
    .then(({ order, payment }) => saveOrder(order, payment))
    .catch(error => console.log(error));
}
```

---

## ✅ Pre-commit Checklist

Antes de hacer commit, verifica:

- [ ] ¿Eliminé `console.log()` de debug?
- [ ] ¿No hay `any` types?
- [ ] ¿Funciones tienen JSDoc?
- [ ] ¿Tests cubren funcionalidad principal?
- [ ] ¿Design tokens en lugar de hex?
- [ ] ¿No hay secrets en código?
- [ ] ¿ESLint pasa?
- [ ] ¿Prettier formateado?

---

## 📚 Referencias

- [Design System](DESIGN_SYSTEM.md)
- [Hooks de Validación](30-HOOKS.md)
- [Glosario](GLOSSARY.md)

