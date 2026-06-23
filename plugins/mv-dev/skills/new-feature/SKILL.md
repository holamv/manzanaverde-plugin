---
description: Scaffold completo de una nueva feature en un proyecto de Manzana Verde con enfoque TDD
---

# Nueva Feature en Manzana Verde

Crea una feature completa siguiendo el patron TDD de MV: tipos primero, luego tests, luego implementacion.

## Paso 1: Preguntar al usuario

1. **Nombre de la feature** - Ej: `meal-selector`, `delivery-tracker`, `plan-comparison`
2. **Descripcion** - Que hace esta feature
3. **Tipo:**
   - **Frontend** - Solo componentes UI, hooks, servicios
   - **Backend** - Solo endpoints API, servicios, modelos
   - **Full-stack** - Ambos + tipos compartidos
4. **Necesita API?** - Si necesita consumir o crear endpoints
5. **Necesita base de datos?** - Si necesita nuevas tablas o queries

## Paso 2: Crear estructura de la feature

### Frontend Feature

```
src/features/[feature-name]/
├── components/
│   ├── [FeatureName].tsx         # Componente principal
│   ├── [FeatureName].test.tsx    # Tests del componente
│   └── [SubComponent].tsx        # Sub-componentes si necesario
├── hooks/
│   ├── use[FeatureName].ts       # Hook principal
│   └── use[FeatureName].test.ts  # Tests del hook
├── services/
│   ├── [featureName]Service.ts   # Llamadas API
│   └── [featureName]Service.test.ts
├── types/
│   └── index.ts                  # Tipos de la feature
└── index.ts                      # Public API (re-exports)
```

### Backend Feature

```
src/features/[feature-name]/
├── routes/
│   └── [featureName]Routes.ts    # Definicion de rutas
├── controllers/
│   ├── [featureName]Controller.ts
│   └── [featureName]Controller.test.ts
├── services/
│   ├── [featureName]Service.ts
│   └── [featureName]Service.test.ts
├── models/
│   └── [featureName]Model.ts     # Si necesita BD
├── schemas/
│   └── [featureName]Schema.ts    # Validacion con Zod
├── types/
│   └── index.ts
└── index.ts
```

## Paso 0 — Clasificar y consultar la rubrica (antes de scaffoldear tests)

Antes de crear tests, clasificá el cambio (BUG / BET / RESUME) y consultá **`/mv-dev:test-decision`**:
- **BUG / trivial** (copy, color, config) → solo test de regresion del defecto, o **ninguno** si es trivial. NO scaffoldees tests de feature nueva.
- **BET (capacidad nueva)** → seguí el flujo TDD de abajo, eligiendo el tipo de test por superficie segun la rubrica.
- **RESUME (delta en progreso)** → mismo flujo que BET por superficie, pero testeá solo el delta nuevo.
- **Chequeá cobertura existente** (grep tests/__tests__/*.spec/*.test) antes de escribir; no dupliques.

## Paso 3: Flujo TDD (para BET/capacidad nueva; ver Paso 0)

### 3.1 Tipos primero

Crear los tipos TypeScript de la feature:

```typescript
// types/index.ts
export interface [FeatureName]Props {
  // props del componente principal
}

export interface [FeatureName]Data {
  // datos que maneja la feature
}

export interface [FeatureName]State {
  data: [FeatureName]Data | null;
  loading: boolean;
  error: string | null;
}
```

### 3.2 Tests primero (RED) (para BET/capacidad nueva; ver Paso 0)

Escribir tests que fallen:

```typescript
// components/[FeatureName].test.tsx
import { render, screen } from '@testing-library/react';
import { [FeatureName] } from './[FeatureName]';

describe('[FeatureName]', () => {
  it('renderiza el estado de carga', () => {
    render(<[FeatureName] />);
    expect(screen.getByText(/cargando/i)).toBeInTheDocument();
  });

  it('muestra los datos correctamente', () => {
    // Test con datos mock
  });

  it('muestra error cuando falla', () => {
    // Test de error
  });

  // Edge cases de MV
  it('maneja session expirada', () => {});
  it('maneja datos vacios', () => {});
});
```

### 3.3 Implementacion (GREEN)

Implementar el minimo codigo para que los tests pasen.

### 3.4 Refactor (BLUE)

Mejorar el codigo manteniendo los tests verdes.

## Paso 4: Integrar la feature

### Frontend

1. Agregar ruta en `src/app/` si es una pagina nueva
2. O importar componente donde se necesite
3. Actualizar el `index.ts` de la feature con todos los exports

### Backend

1. Registrar rutas en `src/routes/index.ts`:
```typescript
import { [featureName]Routes } from '@/features/[feature-name]';
router.use('/api/v1/[feature-name]', [featureName]Routes);
```

## Paso 5: Actualizar docs/ (OBLIGATORIO)

Despues de completar la feature, SIEMPRE actualizar la documentacion del proyecto:

1. **Si `docs/` no existe**: crearlo con la estructura completa (ver doc-agent)
2. **Si `docs/` ya existe**: actualizar los archivos afectados:

**Frontend feature:**
```markdown
# En docs/COMPONENTS.md agregar:
## [FeatureName]
- Ubicacion: `src/features/[feature-name]/`
- Componentes: [FeatureName], [SubComponents]
- Hooks: use[FeatureName]
- APIs que consume: [listar endpoints]

# En docs/CHANGELOG.md agregar:
## [fecha] - Claude
- ✅ Feature [FeatureName]: [descripcion corta]
```

**Backend feature:**
```markdown
# En docs/API.md agregar:
## [FeatureName]
### GET /api/v1/[feature-name]
- Auth: Required
- Query: page, limit, search
- Response: { success, data: [...], meta }

### POST /api/v1/[feature-name]
- Auth: Required
- Body: { campo1, campo2 }
- Response 201: { success, data }

# En docs/TABLES.md agregar (si aplica):
## [tabla]
| Columna | Tipo | Descripcion |
...

# En docs/CHANGELOG.md agregar:
## [fecha] - Claude
- ✅ Feature [FeatureName]: [descripcion corta]
```

**Full-stack feature:** actualizar `COMPONENTS.md` + `API.md` + `TABLES.md` + `CHANGELOG.md`

3. **Marcar estado de funcionalidades** en el archivo correspondiente:
   - ✅ Funcionalidad completada y con tests
   - 🚧 Funcionalidad parcialmente implementada (WIP)
   - ❌ Funcionalidad pendiente

4. **Actualizar `docs/PROJECT_SCOPE.md`** (SIEMPRE):
   - Incrementar version
   - Actualizar fecha
   - Agregar/mover la feature en la seccion de funcionalidades (✅/🚧/❌)
   - Actualizar estructura de archivos si cambio

## Paso 6: PR Description

Generar template de PR:

```markdown
## Feature: [FeatureName]

### Que hace
[Descripcion]

### Archivos creados/modificados
- `src/features/[feature-name]/...`

### Testing
- [ ] Unit tests pasan
- [ ] Coverage >= 80%
- [ ] Tests de edge cases MV incluidos

### Screenshots (si UI)
[Agregar screenshots]
```
