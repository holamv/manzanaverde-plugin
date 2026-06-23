---
description: Como escribir tests en el stack de Manzana Verde - Jest, React Testing Library, Playwright y cobertura minima
---

# Testing en Manzana Verde

> Para DECIDIR que/cuando testear (y cuando NO) → `/mv-dev:test-decision`. Este doc cubre el **como** escribir cada test.

Guia para escribir tests correctos y mantener cobertura en el stack de MV.

## Piramide de Testing

```
    /‾‾‾‾‾‾‾‾\
   /   E2E    \      10% - Flujos criticos (Playwright)
  /   (pocos)   \
 /‾‾‾‾‾‾‾‾‾‾‾‾‾‾\
/  Integracion     \   20% - Componentes + API (RTL + MSW)
/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\
/    Unit (muchos)     \ 70% - Funciones, hooks, utilidades (Jest)
```

## Cobertura Minima

| Tipo | Cobertura |
|------|-----------|
| General | >= 80% |
| Hooks y utilidades | 100% |
| Componentes UI | >= 70% |
| Servicios/API | >= 90% |

## Configuracion

### Jest + React Testing Library

```typescript
// vitest.config.ts (o jest.config.ts)
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./tests/setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      exclude: ['node_modules/', 'tests/', '**/*.d.ts', '**/*.config.*'],
      thresholds: {
        global: { branches: 80, functions: 80, lines: 80, statements: 80 },
      },
    },
  },
});
```

### Setup file

```typescript
// tests/setup.ts
import '@testing-library/jest-dom';
import { cleanup } from '@testing-library/react';
import { afterEach } from 'vitest';

afterEach(() => {
  cleanup();
});
```

### Playwright

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  retries: 2,
  use: {
    baseURL: process.env.STAGING_URL ?? 'http://localhost:3000',
    screenshot: 'only-on-failure',
    trace: 'on-first-retry',
  },
  projects: [
    { name: 'Mobile', use: { ...devices['iPhone 14'] } },
    { name: 'Desktop', use: { ...devices['Desktop Chrome'] } },
  ],
});
```

## Estructura de Archivos

```
src/
├── components/
│   ├── MealCard.tsx
│   └── MealCard.test.tsx        # Test junto al componente
├── hooks/
│   ├── useMeals.ts
│   └── useMeals.test.ts
├── services/
│   ├── mealService.ts
│   └── mealService.test.ts
├── utils/
│   ├── formatPrice.ts
│   └── formatPrice.test.ts
tests/
├── e2e/
│   ├── order-flow.spec.ts      # E2E con Playwright
│   └── login.spec.ts
├── integration/
│   └── meal-list.test.tsx       # Componentes + API
└── setup.ts
```

## Unit Tests - Funciones y Utilidades

```typescript
// utils/formatPrice.test.ts
import { describe, it, expect } from 'vitest';
import { formatPrice } from './formatPrice';

describe('formatPrice', () => {
  it('formatea centavos a moneda con 2 decimales', () => {
    expect(formatPrice(1500, 'PE')).toBe('S/ 15.00');
    expect(formatPrice(2500, 'CO')).toBe('$25.000');
    expect(formatPrice(1000, 'MX')).toBe('$10.00');
  });

  it('maneja cero correctamente', () => {
    expect(formatPrice(0, 'PE')).toBe('S/ 0.00');
  });

  it('maneja valores negativos', () => {
    expect(formatPrice(-500, 'PE')).toBe('-S/ 5.00');
  });
});
```

## Unit Tests - Hooks

```typescript
// hooks/useMeals.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { useMeals } from './useMeals';
import { api } from '@/lib/api';

vi.mock('@/lib/api');

describe('useMeals', () => {
  it('carga meals exitosamente', async () => {
    const mockMeals = [
      { id: 1, name: 'Pollo Grillado', calories: 350 },
      { id: 2, name: 'Ensalada Caesar', calories: 280 },
    ];

    vi.mocked(api.get).mockResolvedValue({
      success: true,
      data: mockMeals,
      meta: { total: 2, page: 1, limit: 20, totalPages: 1 },
    });

    const { result } = renderHook(() => useMeals());

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.meals).toEqual(mockMeals);
    expect(result.current.error).toBeNull();
  });

  it('maneja errores de API', async () => {
    vi.mocked(api.get).mockResolvedValue({
      success: false,
      data: null,
      error: 'Error de conexion',
    });

    const { result } = renderHook(() => useMeals());

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.meals).toEqual([]);
    expect(result.current.error).toBe('Error de conexion');
  });
});
```

## Component Tests - React Testing Library

**Regla principal:** Testear como el usuario interactua, no detalles de implementacion.

### Queries priorizadas (de mejor a peor)

1. `getByRole` - Accesible para todos
2. `getByLabelText` - Para forms
3. `getByPlaceholderText` - Para inputs
4. `getByText` - Para contenido visible
5. `getByTestId` - Ultimo recurso

```typescript
// components/MealCard.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { MealCard } from './MealCard';

const mockMeal = {
  id: '1',
  name: 'Pollo Grillado',
  description: 'Pechuga de pollo con verduras',
  calories: 350,
  priceInCents: 1500,
  imageUrl: '/meals/pollo.jpg',
};

describe('MealCard', () => {
  it('muestra nombre, calorias y precio de la comida', () => {
    render(<MealCard meal={mockMeal} onSelect={vi.fn()} />);

    expect(screen.getByText('Pollo Grillado')).toBeInTheDocument();
    expect(screen.getByText('350 cal')).toBeInTheDocument();
    expect(screen.getByText('S/ 15.00')).toBeInTheDocument();
  });

  it('llama onSelect con el ID al hacer click', async () => {
    const onSelect = vi.fn();
    const user = userEvent.setup();

    render(<MealCard meal={mockMeal} onSelect={onSelect} />);

    await user.click(screen.getByRole('button', { name: /seleccionar/i }));

    expect(onSelect).toHaveBeenCalledWith('1');
  });

  it('muestra imagen con alt text descriptivo', () => {
    render(<MealCard meal={mockMeal} onSelect={vi.fn()} />);

    const image = screen.getByRole('img', { name: 'Pollo Grillado' });
    expect(image).toBeInTheDocument();
  });
});
```

## Integration Tests - Componente + API

```typescript
// tests/integration/meal-list.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import { http, HttpResponse } from 'msw';
import { setupServer } from 'msw/node';
import { MealList } from '@/components/MealList';

const server = setupServer(
  http.get('*/api/v1/meals', () => {
    return HttpResponse.json({
      success: true,
      data: [
        { id: 1, name: 'Pollo Grillado', calories: 350, priceInCents: 1500 },
        { id: 2, name: 'Ensalada Caesar', calories: 280, priceInCents: 1200 },
      ],
      meta: { total: 2, page: 1, limit: 20, totalPages: 1 },
    });
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

describe('MealList integration', () => {
  it('carga y muestra la lista de comidas', async () => {
    render(<MealList />);

    expect(screen.getByText(/cargando/i)).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('Pollo Grillado')).toBeInTheDocument();
      expect(screen.getByText('Ensalada Caesar')).toBeInTheDocument();
    });
  });

  it('muestra error cuando la API falla', async () => {
    server.use(
      http.get('*/api/v1/meals', () => {
        return HttpResponse.json(
          { success: false, data: null, error: 'Server error' },
          { status: 500 }
        );
      })
    );

    render(<MealList />);

    await waitFor(() => {
      expect(screen.getByText(/error/i)).toBeInTheDocument();
    });
  });
});
```

## E2E Tests - Playwright

```typescript
// tests/e2e/order-flow.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Flujo de pedido', () => {
  test.beforeEach(async ({ page }) => {
    // Login
    await page.goto('/login');
    await page.fill('[name="email"]', 'test@manzanaverde.com');
    await page.fill('[name="password"]', 'testpassword');
    await page.click('button[type="submit"]');
    await expect(page).toHaveURL('/dashboard');
  });

  test('usuario puede seleccionar comidas y hacer pedido', async ({ page }) => {
    await page.goto('/meals');

    // Seleccionar comida
    await page.click('text=Pollo Grillado');
    await page.click('button:has-text("Agregar")');

    // Verificar carrito
    await expect(page.locator('[data-testid="cart-count"]')).toHaveText('1');

    // Ir al checkout
    await page.click('text=Ver pedido');
    await expect(page).toHaveURL('/checkout');

    // Confirmar pedido
    await page.click('button:has-text("Confirmar pedido")');
    await expect(page.locator('text=Pedido confirmado')).toBeVisible();
  });
});
```

## Test Data Factories

Crear factories para datos de test consistentes:

```typescript
// tests/factories.ts
export function createMeal(overrides?: Partial<Meal>): Meal {
  return {
    id: crypto.randomUUID(),
    name: 'Pollo Grillado',
    description: 'Pechuga de pollo con verduras',
    category: 'lunch',
    calories: 350,
    proteinGrams: 35,
    carbsGrams: 20,
    fatGrams: 8,
    priceInCents: 1500,
    imageUrl: '/meals/default.jpg',
    active: true,
    countryCode: 'PE',
    createdAt: new Date().toISOString(),
    ...overrides,
  };
}

export function createOrder(overrides?: Partial<Order>): Order {
  return {
    id: crypto.randomUUID(),
    userId: crypto.randomUUID(),
    planId: crypto.randomUUID(),
    status: 'pending',
    totalCents: 4500,
    deliveryDate: '2026-02-01',
    countryCode: 'PE',
    createdAt: new Date().toISOString(),
    ...overrides,
  };
}
```

## Edge Cases para MV

Siempre testear estos escenarios especificos del negocio:

1. **Plan expirado** - Que pasa cuando un usuario tiene plan vencido
2. **Fuera de zona** - Direccion fuera de cobertura de delivery
3. **Deadline pasado** - Pedido despues de la hora limite
4. **Sin stock** - Comida agotada
5. **Cambio de plan** - Usuario cambia de plan mid-ciclo
6. **Multiples paises** - Formatos de moneda, zonas horarias
7. **Sin conexion** - Manejo offline/reconexion
8. **Session expirada** - JWT vencido durante uso

## Comandos de Test

```bash
# Unit + Integration
npm test                        # Correr todos los tests
npm test -- --coverage          # Con reporte de cobertura
npm test -- --watch             # Watch mode

# E2E
npx playwright test             # Todos los E2E
npx playwright test --ui        # Con UI interactiva
npx playwright test --project="Mobile"  # Solo mobile
```
