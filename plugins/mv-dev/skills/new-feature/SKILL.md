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

## Paso 0b — Leé contexto antes de construir

Antes de scaffoldear, leé el contexto relevante para el area que vas a tocar:

1. **docs/ del proyecto** (si existe): leé los archivos afectados (`COMPONENTS.md`, `API.md`, `ARCHITECTURE.md`, `BUSINESS_LOGIC.md`). Si `docs/` no existe, lo crearás al final (create-once; no re-docs ahora).
2. **Cerebro del mirror** (`~/Projects/manzana-verde-os/`): leé `producto/ingenieria/data-dictionary.md` y `CONVENTIONS.md` para el area que tocás. El SessionStart hook ya lo mantuvo fresco.
3. **NO re-fetchees Notion** para lo que ya esté en el mirror local — es redundante y quema tokens.
4. Con este contexto, ajustá la estructura de la feature (nombres, patrones, convenciones MV) antes de escribir codigo.

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

## Paso 5: Actualizar docs/ — Append del DELTA (OBLIGATORIO para BET)

**Regla**: NO reescribas el archivo entero. Agregá o editá SOLO las secciones que tu cambio tocó.

- **BUG / trivial**: doc mínima (una línea en CHANGELOG.md) o ninguna si es cosmético.
- **BET / capacidad nueva**: append del delta de lo que construiste — entradas nuevas en los archivos afectados, nada más.
- **RESUME (delta en progreso)**: solo documenta el delta nuevo, no lo que ya estaba.

1. **Si `docs/` no existe**: crearlo completo ahora (create-once; ver doc-agent). A partir de aquí siempre existirá.
2. **Si `docs/` ya existe**: editá SOLO las secciones afectadas (no el archivo entero):

**Frontend feature — delta:**
```markdown
# Agregar en docs/COMPONENTS.md (solo la seccion nueva):
## [FeatureName]
- Ubicacion: `src/features/[feature-name]/`
- Componentes: [FeatureName], [SubComponents]
- Hooks: use[FeatureName]
- APIs que consume: [listar endpoints]

# Agregar en docs/CHANGELOG.md (solo la entrada nueva):
## [fecha] - Claude
- ✅ Feature [FeatureName]: [descripcion corta]
```

**Backend feature — delta:**
```markdown
# Agregar en docs/API.md (solo el recurso nuevo):
## [FeatureName]
### GET /api/v1/[feature-name]
- Auth: Required
- Query: page, limit, search
- Response: { success, data: [...], meta }

### POST /api/v1/[feature-name]
- Auth: Required
- Body: { campo1, campo2 }
- Response 201: { success, data }

# Agregar en docs/TABLES.md (solo si hay tablas nuevas):
## [tabla]
| Columna | Tipo | Descripcion |
...

# Agregar en docs/CHANGELOG.md (solo la entrada nueva):
## [fecha] - Claude
- ✅ Feature [FeatureName]: [descripcion corta]
```

**Full-stack feature:** delta en `COMPONENTS.md` + `API.md` + `TABLES.md` (si aplica) + `CHANGELOG.md`

3. **Marcar estado de funcionalidades** en el archivo correspondiente (solo la linea nueva o cambiada):
   - ✅ Funcionalidad completada y con tests
   - 🚧 Funcionalidad parcialmente implementada (WIP)
   - ❌ Funcionalidad pendiente

4. **Actualizar `docs/PROJECT_SCOPE.md`** — SOLO las lineas que cambiaron:
   - Incrementar version y actualizar fecha
   - Agregar/mover la feature en funcionalidades (✅/🚧/❌)
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
