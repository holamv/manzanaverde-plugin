# 🧪 Workflow: Escribir Tests

Guía para testear componentes, servicios y flujos E2E en el stack de MV.

## ⏱️ Duración: Variable (depende de cobertura)

## 📋 Stack de Testing

| Herramienta | Uso | Ejecutar |
|-------------|-----|----------|
| **Jest** | Unit tests (funciones, servicios, hooks) | `npm test` |
| **React Testing Library** | Tests de componentes React | `npm test` |
| **Playwright** | E2E (flujos de usuario completos) | `npm run test:e2e` |

## 🎯 Objetivo de Cobertura

**Mínimo requerido: >= 80%** en statements, branches, functions y lines.

El hook de pre-push bloquea el push si la cobertura es inferior.

---

## 📍 Paso 1: Ver la Referencia de Testing

```
/mv-dev:mv-testing
```

Este skill muestra la estrategia completa y ejemplos específicos para el stack de MV.

---

## 📍 Paso 2: Tests Unitarios con Jest

Para funciones puras, servicios, utilidades y lógica de negocio.

### Estructura de un test unitario

```typescript
// lib/__tests__/formatters.test.ts
import { formatMoney, formatDate } from '../formatters';

describe('formatMoney', () => {
  it('formatea centavos a soles peruanos', () => {
    expect(formatMoney(2500, 'es-PE', 'PEN')).toBe('S/ 25.00');
  });

  it('maneja cero correctamente', () => {
    expect(formatMoney(0, 'es-PE', 'PEN')).toBe('S/ 0.00');
  });

  it('maneja valores grandes', () => {
    expect(formatMoney(100000, 'es-PE', 'PEN')).toBe('S/ 1,000.00');
  });
});
```

### Test de un servicio con fetch mock

```typescript
// services/__tests__/ordersService.test.ts
import { getOrderHistory } from '../ordersService';

global.fetch = jest.fn();

beforeEach(() => {
  (fetch as jest.Mock).mockClear();
});

describe('getOrderHistory', () => {
  it('retorna órdenes exitosamente', async () => {
    (fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      json: async () => ({ success: true, data: [{ id: '1', status: 'active' }] }),
    });

    const result = await getOrderHistory('token-123');
    expect(result.success).toBe(true);
    expect(result.data).toHaveLength(1);
    expect(fetch).toHaveBeenCalledWith(
      expect.stringContaining('/api/orders/history'),
      expect.objectContaining({ headers: expect.objectContaining({ Authorization: 'Bearer token-123' }) })
    );
  });

  it('retorna error cuando la API falla', async () => {
    (fetch as jest.Mock).mockResolvedValueOnce({
      ok: false,
      json: async () => ({ error: 'Unauthorized' }),
    });

    const result = await getOrderHistory('bad-token');
    expect(result.success).toBe(false);
    expect(result.error).toBeDefined();
  });

  it('maneja errores de red', async () => {
    (fetch as jest.Mock).mockRejectedValueOnce(new Error('Network error'));

    const result = await getOrderHistory('token-123');
    expect(result.success).toBe(false);
    expect(result.error).toBe('Error de conexión');
  });
});
```

---

## 📍 Paso 3: Tests de Componentes con RTL

Para componentes React: renderizado, interacciones, estados.

### Patrón base

```typescript
// components/__tests__/OrderCard.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { OrderCard } from '../OrderCard';

const mockOrder = {
  id: 'order-123',
  status: 'active' as const,
  total: 2500,
  createdAt: '2026-01-15T12:00:00Z',
  items: [{ productId: 'p1', name: 'Ensalada', quantity: 1, unitPrice: 2500 }],
};

describe('OrderCard', () => {
  it('renderiza el ID y estado de la orden', () => {
    render(<OrderCard order={mockOrder} />);
    expect(screen.getByText('order-123')).toBeInTheDocument();
    expect(screen.getByText(/active/i)).toBeInTheDocument();
  });

  it('muestra el precio formateado', () => {
    render(<OrderCard order={mockOrder} />);
    expect(screen.getByText(/S\/ 25\.00/)).toBeInTheDocument();
  });

  it('llama onCancel al hacer click en cancelar', async () => {
    const onCancel = jest.fn();
    render(<OrderCard order={mockOrder} onCancel={onCancel} />);
    await userEvent.click(screen.getByRole('button', { name: /cancelar/i }));
    expect(onCancel).toHaveBeenCalledWith('order-123');
  });
});
```

### Componente con llamada async

```typescript
// components/__tests__/OrderList.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import { OrderList } from '../OrderList';
import * as service from '@/services/ordersService';

jest.mock('@/services/ordersService');

describe('OrderList', () => {
  it('muestra skeleton mientras carga', () => {
    (service.getOrderHistory as jest.Mock).mockReturnValue(new Promise(() => {}));
    render(<OrderList token="tok" />);
    expect(screen.getByRole('status')).toBeInTheDocument(); // skeleton
  });

  it('muestra las órdenes cuando carga', async () => {
    (service.getOrderHistory as jest.Mock).mockResolvedValue({
      success: true,
      data: [{ id: 'o1', status: 'active', total: 1500 }],
    });
    render(<OrderList token="tok" />);
    await waitFor(() => expect(screen.getByText('o1')).toBeInTheDocument());
  });

  it('muestra estado vacío', async () => {
    (service.getOrderHistory as jest.Mock).mockResolvedValue({ success: true, data: [] });
    render(<OrderList token="tok" />);
    await waitFor(() => expect(screen.getByText(/sin órdenes/i)).toBeInTheDocument());
  });

  it('muestra error si la API falla', async () => {
    (service.getOrderHistory as jest.Mock).mockResolvedValue({
      success: false, data: [], error: 'Error al cargar',
    });
    render(<OrderList token="tok" />);
    await waitFor(() => expect(screen.getByText(/error al cargar/i)).toBeInTheDocument());
  });
});
```

---

## 📍 Paso 4: Tests E2E con Playwright

Para flujos completos de usuario: navegación, formularios, integraciones.

```typescript
// e2e/orders.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Historial de órdenes', () => {
  test.beforeEach(async ({ page }) => {
    // Login
    await page.goto('/login');
    await page.fill('[name=email]', 'test@manzanaverde.la');
    await page.fill('[name=password]', 'password123');
    await page.click('button[type=submit]');
    await expect(page).toHaveURL('/dashboard');
  });

  test('el usuario puede ver su historial de órdenes', async ({ page }) => {
    await page.goto('/orders/history');
    await expect(page.getByRole('heading', { name: /historial/i })).toBeVisible();
    await expect(page.getByRole('list')).toBeVisible();
  });

  test('el filtro por estado funciona', async ({ page }) => {
    await page.goto('/orders/history');
    await page.selectOption('[data-testid=status-filter]', 'completed');
    await expect(page.getByText(/completada/i).first()).toBeVisible();
  });
});
```

---

## 📍 Paso 5: Ejecutar y Verificar Cobertura

```bash
# Todos los tests
npm test

# Con reporte de cobertura
npm test -- --coverage

# Un solo archivo
npm test -- OrderCard

# E2E
npm run test:e2e
```

**Reporte de cobertura:**
```
File           | % Stmts | % Branch | % Funcs | % Lines
OrderCard.tsx  |   95.00 |    88.00 |  100.00 |   95.00
ordersService  |   90.00 |    83.00 |   87.50 |   89.00
formatters.ts  |  100.00 |   100.00 |  100.00 |  100.00
```

Si algún archivo está por debajo del 80%, agregar tests para los casos faltantes.

---

## ✅ Checklist de Testing

- [ ] ¿Tests unitarios para funciones/servicios?
- [ ] ¿Tests de componentes con todos los estados (loading, error, empty, data)?
- [ ] ¿Tests de interacciones de usuario (clicks, inputs)?
- [ ] ¿E2E para flujos críticos?
- [ ] ¿Cobertura >= 80% en todos los archivos?
- [ ] ¿Todos los tests pasan (`npm test`)?

---

## 🚨 Troubleshooting

### "Cannot find module '@testing-library/react'"
```bash
npm install -D @testing-library/react @testing-library/user-event @testing-library/jest-dom
```

### "fetch is not defined"
```typescript
// jest.setup.ts
import 'whatwg-fetch';
// o
global.fetch = jest.fn();
```

### "Unable to find an element with the text..."
- Usar `screen.debug()` para ver el DOM actual
- Verificar que el elemento existe y está visible
- Usar `waitFor()` si el elemento aparece de forma asíncrona

### "Test pasa localmente pero falla en CI"
- Verificar que no hay dependencia de orden en los tests
- Limpiar mocks en `beforeEach`: `jest.clearAllMocks()`
- Verificar variables de entorno en CI

---

## 📚 Referencias

- [Skill mv-testing](10-SKILLS.md#mv-testing)
- [QA Agent (validación automática)](40-AGENTS.md)
- [Playwright MCP Server](20-MCP_SERVERS.md)
- [Estandares de Código](CODE_STANDARDS.md)
