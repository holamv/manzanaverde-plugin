---
description: Crear una nueva pagina Next.js siguiendo los patrones de Manzana Verde con metadata, loading y error states
---

# Nueva Pagina Next.js de Manzana Verde

Crea una pagina Next.js completa con metadata SEO, loading states y error boundaries.

## Paso 1: Preguntar al usuario

1. **Ruta de la pagina** - Ej: `/meals`, `/plans/[id]`, `/dashboard/orders`
2. **Titulo** - Titulo de la pagina para SEO
3. **Descripcion** - Descripcion meta para SEO
4. **Tipo de componente:**
   - **Server Component** (default) - Para paginas con data fetching server-side
   - **Client Component** - Solo si necesita interactividad pesada (formularios complejos, animaciones)
5. **Necesita data fetching?** - Si/No
6. **Necesita autenticacion?** - Si/No
7. **Tiene parametros dinamicos?** - Ej: `[id]`, `[slug]`

## Paso 2: Crear archivos

Para una ruta como `/meals/[id]`, crear:

```
src/app/meals/[id]/
├── page.tsx          # Pagina principal
├── loading.tsx       # Loading skeleton
├── error.tsx         # Error boundary
└── layout.tsx        # Layout (solo si necesario)
```

## Paso 3: Implementar page.tsx

### Server Component (Default)

```tsx
import type { Metadata } from 'next';
import Image from 'next/image';

// Tipos
interface PageProps {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}

// Metadata dinamica
export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { id } = await params;
  // Fetch data para metadata si necesario
  return {
    title: `[TITULO] | Manzana Verde`,
    description: '[DESCRIPCION]',
    openGraph: {
      title: '[TITULO] | Manzana Verde',
      description: '[DESCRIPCION]',
      type: 'website',
    },
  };
}

// Pagina
export default async function [PageName]Page({ params, searchParams }: PageProps) {
  const { id } = await params;

  // Data fetching (server-side)
  // const data = await fetchData(id);

  return (
    <main className="min-h-screen bg-background">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-8">
        <h1 className="font-heading text-[28px] font-bold text-foreground">
          [TITULO]
        </h1>

        {/* Contenido */}
      </div>
    </main>
  );
}
```

### Client Component (Solo si necesario)

```tsx
'use client';

import { useState, useEffect } from 'react';

interface PageProps {
  params: Promise<{ id: string }>;
}

export default function [PageName]Page({ params }: PageProps) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  // Client-side data fetching solo si absolutamente necesario
  // Preferir Server Components con data fetching en el server

  return (
    <main className="min-h-screen bg-background">
      {/* ... */}
    </main>
  );
}
```

## Paso 4: Loading state

```tsx
// loading.tsx
export default function Loading() {
  return (
    <main className="min-h-screen bg-background">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-8">
        {/* Skeleton del heading */}
        <div className="h-8 w-64 rounded-lg bg-mv-gray-200 animate-pulse mb-6" />

        {/* Skeleton del contenido */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <div
              key={i}
              className="bg-white rounded-2xl border border-mv-gray-200 p-4 space-y-3"
            >
              <div className="h-40 rounded-xl bg-mv-gray-200 animate-pulse" />
              <div className="h-4 w-3/4 rounded bg-mv-gray-200 animate-pulse" />
              <div className="h-3 w-1/2 rounded bg-mv-gray-200 animate-pulse" />
            </div>
          ))}
        </div>
      </div>
    </main>
  );
}
```

## Paso 5: Error boundary

```tsx
// error.tsx
'use client';

import { useEffect } from 'react';
import { AlertCircle, RefreshCw } from 'lucide-react';

interface ErrorProps {
  error: Error & { digest?: string };
  reset: () => void;
}

export default function Error({ error, reset }: ErrorProps) {
  useEffect(() => {
    console.error('[PageName] Error:', error);
  }, [error]);

  return (
    <main className="min-h-screen bg-background flex items-center justify-center">
      <div className="text-center max-w-md px-4">
        <div className="mx-auto w-12 h-12 rounded-full bg-red-50 flex items-center justify-center mb-4">
          <AlertCircle className="w-6 h-6 text-red-600" />
        </div>
        <h2 className="font-heading text-xl font-semibold text-foreground mb-2">
          Algo salio mal
        </h2>
        <p className="font-body text-[15px] text-mv-gray-500 mb-6">
          Hubo un error al cargar la pagina. Por favor intenta de nuevo.
        </p>
        <button
          onClick={reset}
          className="inline-flex items-center gap-2 bg-gradient-to-b from-[#227A4B] to-[#1D6A41] text-white font-body font-semibold px-6 py-3 rounded-xl shadow-[0_4px_14px_0_rgb(34_122_75/0.25)] hover:shadow-[0_8px_25px_0_rgb(34_122_75/0.3)] transition-all duration-200"
        >
          <RefreshCw className="w-4 h-4" />
          Intentar de nuevo
        </button>
      </div>
    </main>
  );
}
```

## Paso 0 — Clasificar y consultar la rubrica (antes de scaffoldear tests)

Antes de crear tests, clasificá el cambio (BUG / BET / RESUME) y consultá **`/mv-dev:test-decision`**:
- **BUG / trivial** (copy, color, config) → solo test de regresion del defecto, o **ninguno** si es trivial. NO scaffoldees tests de feature nueva.
- **BET (capacidad nueva)** → seguí el flujo TDD de abajo, eligiendo el tipo de test por superficie segun la rubrica.
- **RESUME (delta en progreso)** → mismo flujo que BET por superficie, pero testeá solo el delta nuevo.
- **Chequeá cobertura existente** (grep tests/__tests__/*.spec/*.test) antes de escribir; no dupliques.

## Paso 0b — Leé contexto antes de construir

Antes de scaffoldear la pagina, leé el contexto relevante para el area que vas a tocar:

1. **docs/ del proyecto** (si existe): leé `COMPONENTS.md`, `ARCHITECTURE.md`, `BUSINESS_LOGIC.md`. Si `docs/` no existe, lo crearás al final (create-once; no re-docs ahora).
2. **Cerebro del mirror** (`~/Projects/manzana-verde-os/`): leé `producto/ingenieria/data-dictionary.md` y `CONVENTIONS.md` para el area de la pagina. El SessionStart hook ya lo mantuvo fresco.
3. **NO re-fetchees Notion** para lo que ya esté en el mirror local — es redundante y quema tokens.
4. Con este contexto, confirmá rutas existentes, design tokens, patrones de layout MV antes de escribir codigo.

## Paso 6: Test de la pagina (para BET/capacidad nueva; ver Paso 0)

```tsx
// __tests__/[pageName].test.tsx
import { render, screen } from '@testing-library/react';
import Page from '../page';

describe('[PageName] Page', () => {
  it('renderiza el titulo de la pagina', async () => {
    const page = await Page({ params: Promise.resolve({ id: '1' }), searchParams: Promise.resolve({}) });
    render(page);
    expect(screen.getByRole('heading', { level: 1 })).toBeInTheDocument();
  });
});
```

## Paso 7: Actualizar docs/ — Append del DELTA (OBLIGATORIO para BET)

**Regla**: NO reescribas el archivo entero. Agregá o editá SOLO las secciones que tu cambio tocó.

- **BUG / trivial**: doc mínima (una línea en CHANGELOG.md) o ninguna si es cosmético.
- **BET / capacidad nueva**: append del delta — entradas nuevas en los archivos afectados, nada más.
- **RESUME (delta en progreso)**: solo documenta el delta nuevo, no lo que ya estaba.

1. **Si `docs/` no existe**: crearlo completo ahora (create-once; ver doc-agent). A partir de aquí siempre existirá.
2. **Si `docs/` ya existe**: editá SOLO las secciones afectadas (no el archivo entero):

```markdown
# Agregar en docs/COMPONENTS.md (solo la entrada nueva en la seccion "Paginas"):
- `/[ruta]` - [PageName]: [descripcion de la pagina]
  - Tipo: Server Component | Client Component
  - Data fetching: [si/no, de donde]
  - Auth: [requerida/publica]

# Agregar en docs/CHANGELOG.md (solo la entrada nueva):
## [fecha] - Claude
- ✅ Pagina [ruta]: [descripcion corta]
```

3. Marcar el estado: ✅ si esta completa, 🚧 si es WIP

4. **Actualizar `docs/PROJECT_SCOPE.md`** — SOLO las lineas que cambiaron:
   - Incrementar version y actualizar fecha
   - Agregar la pagina en funcionalidades (✅/🚧)
   - Actualizar estructura de archivos con la nueva ruta

## Checklist de la Pagina

Antes de terminar, verificar:

- [ ] `page.tsx` con metadata export (title, description, OG)
- [ ] `loading.tsx` con skeleton que refleja la estructura real
- [ ] `error.tsx` con boton de retry y mensaje en espanol
- [ ] Server Component por defecto (no `'use client'` innecesario)
- [ ] Usa `next/image` para imagenes (no `<img>`)
- [ ] Usa design tokens de MV (no colores hardcodeados)
- [ ] Mobile-first responsive (`px-4 sm:px-6 lg:px-8`)
- [ ] Tipografia correcta (font-heading para h1-h4, font-body para body)
- [ ] Test basico creado
- [ ] `docs/` actualizado con la nueva pagina
