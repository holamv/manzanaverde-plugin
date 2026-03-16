# 🎣 Hooks de Validación del Plugin MV Dev

Los **hooks** son validaciones automáticas que se ejecutan cuando escribes o editas código. Detectan problemas sin que tengas que hacer nada.

## ¿Qué es un Hook?

Un hook es un script que se ejecuta automáticamente en ciertos momentos:
- Cuando guardas un archivo (PostToolUse)
- Antes de hacer commit (pre-commit)
- Antes de hacer push (pre-push)
- En control de calidad (quality-gate)

**Objetivo:** Mantener la calidad y seguridad automáticamente.

---

## 6 Hooks Disponibles

### 1. validate-secrets.sh
**Cuándo se ejecuta:** Al escribir/editar archivos `.ts`, `.tsx`, `.js`, `.jsx`

**Qué detecta:**
- ✅ API keys expuestas (CONTEXT7_API_KEY, NOTION_TOKEN, etc.)
- ✅ Passwords en código
- ✅ Connection strings
- ✅ Tokens JWT hardcodeados
- ✅ AWS, Google Cloud, Firebase credentials

**Ejemplo de detección:**
```typescript
// ❌ DETECTADO - Secret hardcodeado
const apiKey = "ctx7sk-abc123xyz";
export const notionToken = "ntn_secret123";
```

**Acción:** El hook bloquea la escritura y muestra qué línea tiene el problema.

**Cómo arreglarlo:**
```typescript
// ✅ CORRECTO - Usar variable de entorno
const apiKey = process.env.CONTEXT7_API_KEY;
const notionToken = process.env.NOTION_TOKEN;
```

---

### 2. validate-pre-commit.sh
**Cuándo se ejecuta:** Antes de hacer `git commit`

**Qué valida:**
- ✅ ESLint (style y reglas)
- ✅ Prettier (formato de código)
- ✅ No hay secrets

**Ejemplo:**
```
$ git commit -m "Add login feature"

Running pre-commit hooks...
✅ ESLint pass
✅ Prettier pass
✅ No secrets detected
✅ Commit successful
```

Si hay errores ESLint:
```
❌ ESLint error in src/pages/login.tsx:
  Line 42: Unused variable 'userId'

Fix it and try again
```

---

### 3. validate-pre-push.sh
**Cuándo se ejecuta:** Antes de hacer `git push`

**Qué valida:**
- ✅ TypeScript compila sin errores
- ✅ Tests pasan
- ✅ Build es exitoso

**Ejemplo:**
```
$ git push origin feat/advanced-search

Running pre-push validation...
✅ TypeScript check
✅ Tests pass (92% coverage)
✅ Build success
✅ Ready to push
```

Si hay errores:
```
❌ TypeScript error in src/services/orders.ts:
  Type 'string' is not assignable to type 'number'

Fix errors and try again
```

---

### 4. validate-quality-gate.sh
**Cuándo se ejecuta:** Quality gate antes de merge

**Qué valida:**
- ✅ Cobertura de tests >= 80%
- ✅ Build exitoso
- ✅ No hay warnings críticos

**Ejemplo:**
```
$ git push --set-upstream origin feat/new-feature

Quality Gate Check:
✅ Test coverage: 92% (target: 80%)
✅ Build: SUCCESS
✅ Warnings: 0 critical
✅ Ready for merge
```

Si falla:
```
❌ Test coverage: 65% (target: 80%)
  Missing coverage in:
  - components/Modal.tsx: 45%
  - services/api.ts: 70%

Add tests and try again
```

---

### 5. validate-nextjs-patterns.sh
**Cuándo se ejecuta:** Al escribir/editar archivos `.tsx` en `app/`, `src/app/`, o `pages/`

**Qué valida:**
- ✅ Metadata exportado correctamente
- ✅ next/image usado en lugar de <img>
- ✅ Design tokens de MV (no hex hardcodeados)
- ✅ 'use client' solo si necesario
- ✅ Componentes client/server correctamente etiquetados

**Ejemplos de validación:**

```typescript
// ❌ DETECTADO - Falta metadata
export default function OrdersPage() {
  return <div>Orders</div>;
}

// ✅ CORRECTO
export const metadata: Metadata = {
  title: 'Orders',
  description: 'User order history'
};

export default function OrdersPage() {
  return <div>Orders</div>;
}
```

```typescript
// ❌ DETECTADO - Usar <img> en lugar de next/image
<img src="/product.jpg" alt="product" />

// ✅ CORRECTO
import Image from 'next/image';
<Image src="/product.jpg" alt="product" width={300} height={300} />
```

```typescript
// ❌ DETECTADO - Color hex hardcodeado
<button className="bg-[#227A4B]">Buy</button>

// ✅ CORRECTO - Usar token MV
<button className="bg-mv-green-500">Buy</button>
```

---

### 6. validate-api-patterns.sh
**Cuándo se ejecuta:** Al escribir/editar archivos `.ts` en `routes/`, `controllers/`, `services/`

**Qué valida:**
- ✅ Response format estándar (success, data, error)
- ✅ Try/catch en operaciones
- ✅ Validación Zod en inputs
- ✅ Auth middleware en rutas protegidas
- ✅ Manejo de errores consistente

**Ejemplos:**

```typescript
// ❌ DETECTADO - Response format incorrecto
export async function GET(req: Request) {
  const data = await getOrders();
  return new Response(JSON.stringify(data));
}

// ✅ CORRECTO
export async function GET(req: Request) {
  try {
    const data = await getOrders();
    return new Response(
      JSON.stringify({ success: true, data }),
      { status: 200 }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: 'Error fetching orders' }),
      { status: 500 }
    );
  }
}
```

```typescript
// ❌ DETECTADO - Sin validación Zod
export async function POST(req: Request) {
  const { name, email } = await req.json();
  // ... usar name, email sin validar
}

// ✅ CORRECTO
const createOrderSchema = z.object({
  items: z.array(z.object({ id: z.string(), qty: z.number() })),
  delivery_date: z.string().datetime()
});

export async function POST(req: Request) {
  const body = await req.json();
  const validated = createOrderSchema.parse(body);
  // ... usar validated
}
```

---

## 📊 Cuadro Resumen de Hooks

| Hook | Cuándo | Qué valida | Detiene |
|------|--------|-----------|---------|
| **validate-secrets** | Save/Edit | Secrets expuestos | ✅ Sí |
| **validate-pre-commit** | git commit | ESLint, Prettier | ✅ Sí |
| **validate-pre-push** | git push | TS, tests, build | ✅ Sí |
| **validate-quality-gate** | Quality gate | Coverage, build | ✅ Sí |
| **validate-nextjs-patterns** | Save .tsx en app/ | Metadata, images, tokens | ⚠️ Warning |
| **validate-api-patterns** | Save .ts en routes/ | Response format, Zod, auth | ⚠️ Warning |

---

## 🛠️ Cómo Funcionan en la Práctica

### Scenario 1: Hardcodear un Secret

```typescript
// Escribes esto en src/config.ts
const apiKey = "ctx7sk-super-secret-key";

// Al guardar:
// ❌ Hook detects secret
// ❌ Archivo NO se guarda
// ⚠️ Mensaje: "Secret detected: CONTEXT7_API_KEY"
// 💡 Sugerencia: Usar process.env.CONTEXT7_API_KEY
```

### Scenario 2: Olvidar Metadata en Página

```typescript
// Escribes esto en app/products/page.tsx
export default function ProductsPage() {
  return <div>Products</div>;
}

// Al guardar:
// ⚠️ Hook sugiere: "Add metadata export"
// ✅ Archivo SÍ se guarda
// 💡 Sugerencia: Agregar metadata antes de deploy
```

### Scenario 3: Push sin Tests Pasando

```
$ git push origin my-feature

✅ ESLint pass
✅ Prettier pass
❌ Tests failed (3 failed, 1 skipped)

Push aborted. Fix tests and try again.
```

---

## ✅ Checklist: Validaciones Automáticas

Cuando guardas código:
- [ ] ¿Hay secrets hardcodeados? → validate-secrets bloquea
- [ ] ¿Sigue patrones de Next.js? → validate-nextjs-patterns sugiere
- [ ] ¿Sigue patrones de API? → validate-api-patterns sugiere

Cuando haces commit:
- [ ] ¿ESLint pasa? → validate-pre-commit valida
- [ ] ¿Prettier está OK? → validate-pre-commit valida
- [ ] ¿Hay secrets? → validate-pre-commit bloquea

Cuando haces push:
- [ ] ¿TypeScript compila? → validate-pre-push valida
- [ ] ¿Tests pasan? → validate-pre-push valida
- [ ] ¿Build funciona? → validate-pre-push valida

---

## 🚨 Si un Hook Falla

### "Secret detected"
```
❌ Secret detected in src/config.ts line 5
   Type: API_KEY
   Pattern: ctx7sk-*

❌ Archivo NO se guardó
```

**Arreglo:**
1. Elimina el secret del código
2. Agrega como variable de entorno: `export VAR_NAME="value"`
3. Usa en código: `process.env.VAR_NAME`
4. Intenta guardar de nuevo

---

### "ESLint error"
```
❌ ESLint errors in src/pages/login.tsx:
   Line 42: Unused variable 'unused_var'
   Line 89: 'any' type used instead of specific type
```

**Arreglo:**
1. Elimina variables no usadas
2. Reemplaza `any` con tipos específicos
3. Corre: `npm run lint -- --fix` para auto-fixes
4. Commit de nuevo

---

### "Test coverage too low"
```
❌ Coverage: 65% (required: 80%)
   Missing coverage in:
   - services/api.ts: 45%
   - components/Modal.tsx: 60%
```

**Arreglo:**
1. Escribe tests para áreas con baja cobertura
2. Ejecuta: `npm test -- --coverage`
3. Verifica que >= 80%
4. Push de nuevo

---

## 📝 Notas

- Los hooks NO ralentizan - todo ocurre en background
- Si necesitas pushear código temporal, usa `--no-verify` **solo en dev**
- Los hooks pueden personalizarse en `plugin.json` si lo necesitas

---

**Siguiente:** [Leer sobre Agentes →](40-AGENTS.md)
