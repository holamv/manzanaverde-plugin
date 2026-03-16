# 🎨 Design System de Manzana Verde

Guía completa de colores, tipografía, componentes y espaciado del design system de MV.

## 📍 Introducción

Este es el design system oficial de **Manzana Verde**. Todos los proyectos deben usar estos tokens. El plugin valida automáticamente que los componentes los cumplan.

---

## 🎨 Paleta de Colores

### Colores Primarios

| Token | Hex | RGB | Uso |
|-------|-----|-----|-----|
| `mv-green-50` | `#E8F5EC` | 232, 245, 236 | Fondos sutiles |
| `mv-green-100` | `#D0EBD9` | 208, 235, 217 | Backgrounds light |
| `mv-green-500` | `#227A4B` | **34, 122, 75** | **Color primario (botones, links)** |
| `mv-green-600` | `#1D6A41` | 29, 106, 65 | Hover de botones |
| `mv-green-700` | `#185A37` | 24, 90, 55 | Active/pressed |

### Colores Secundarios

| Token | Hex | RGB | Uso |
|-------|-----|-----|-----|
| `mv-orange-500` | `#E85D04` | 232, 93, 4 | Badges, alerts, acciones secundarias |
| `mv-yellow-500` | `#E5B83C` | 229, 184, 60 | Promociones, highlights, tags |

### Colores Neutrales

| Token | Hex | RGB | Uso |
|-------|-----|-----|-----|
| `mv-gray-50` | `#FAFAFA` | 250, 250, 250 | Fondo de página |
| `mv-gray-100` | `#F3F3F3` | 243, 243, 243 | Fondo secundario |
| `mv-gray-200` | `#E8E8E8` | 232, 232, 232 | Bordes estándar |
| `mv-gray-300` | `#D9D9D9` | 217, 217, 217 | Bordes sutiles |
| `mv-gray-500` | `#737373` | 115, 115, 115 | Texto secundario/muted |
| `mv-gray-700` | `#414141` | 65, 65, 65 | Texto secundario fuerte |
| `mv-gray-900` | `#171717` | **23, 23, 23** | **Texto principal** |

### Colores Semánticos

| Estado | Hex | RGB | Uso |
|--------|-----|-----|-----|
| Success | `#227A4B` | 34, 122, 75 | ✅ Operaciones exitosas |
| Warning | `#E85D04` | 232, 93, 4 | ⚠️ Advertencias, atención |
| Error | `#DC2626` | 220, 38, 38 | ❌ Errores, acciones destructivas |
| Info | `#0EA5E9` | 14, 165, 233 | ℹ️ Información, tips |

---

## 🔤 Tipografía

### Fuentes

```css
/* Importar en _document.tsx o layout.tsx */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Nunito:wght@400;500;600;700&display=swap');
```

### Headings - Inter (400-800)
- **H1:** Inter, 48px, 700, line-height 1.2, letter-spacing -1px
- **H2:** Inter, 36px, 700, line-height 1.3, letter-spacing -0.5px
- **H3:** Inter, 28px, 600, line-height 1.4
- **H4:** Inter, 24px, 600, line-height 1.4
- **H5:** Inter, 20px, 600, line-height 1.5

### Body - Nunito (400-700)
- **Body Large:** Nunito, 18px, 400, line-height 1.6
- **Body Regular:** Nunito, 16px, 400, line-height 1.5 (default)
- **Body Small:** Nunito, 14px, 400, line-height 1.5
- **Label:** Nunito, 12px, 600, line-height 1.4
- **Button:** Nunito, 16px, 600, line-height 1.5

### Tailwind Config

```tailwind
/* tailwind.config.ts */
module.exports = {
  theme: {
    fontFamily: {
      'sans': ['Nunito', 'system-ui', 'sans-serif'],
      'heading': ['Inter', 'system-ui', 'sans-serif'],
    },
    fontSize: {
      'h1': ['48px', { lineHeight: '1.2' }],
      'h2': ['36px', { lineHeight: '1.3' }],
      'h3': ['28px', { lineHeight: '1.4' }],
      'h4': ['24px', { lineHeight: '1.4' }],
      'body-lg': ['18px', { lineHeight: '1.6' }],
      'base': ['16px', { lineHeight: '1.5' }],
      'body-sm': ['14px', { lineHeight: '1.5' }],
      'label': ['12px', { lineHeight: '1.4' }],
    }
  }
}
```

---

## 📏 Espaciado

Base: **4px**

Escala:
- `2px` (0.5 base) - espacios muy ajustados
- `4px` (1 base) - default
- `8px` (2 base)
- `12px` (3 base)
- `16px` (4 base) - default
- `24px` (6 base)
- `32px` (8 base)
- `48px` (12 base)
- `64px` (16 base)

### En Tailwind
```html
<!-- Padding/Margin -->
<div class="p-4">         <!-- padding: 16px -->
<div class="px-6">        <!-- padding horizontal: 24px -->
<div class="my-8">        <!-- margin vertical: 32px -->
<div class="mb-12">       <!-- margin bottom: 48px -->
```

---

## 🔘 Componentes Base

### Botones

**Primario** (bg-mv-green-500)
```html
<button class="
  px-6 py-3
  bg-mv-green-500 hover:bg-mv-green-600 active:bg-mv-green-700
  text-white
  rounded-xl
  font-semibold
  transition-colors
  shadow-md hover:shadow-lg
">
  Action
</button>
```

**Secundario** (border + text)
```html
<button class="
  px-6 py-3
  border-2 border-mv-green-500
  text-mv-green-500
  rounded-xl
  font-semibold
  hover:bg-mv-green-50
">
  Secondary
</button>
```

**Ghost** (sin fondo)
```html
<button class="
  px-6 py-3
  text-mv-green-500
  rounded-xl
  font-semibold
  hover:bg-mv-green-50
">
  Ghost
</button>
```

### Inputs

```html
<input class="
  w-full px-4 py-3
  border border-mv-gray-200
  rounded-lg
  focus:border-mv-green-500 focus:ring focus:ring-mv-green-50
  placeholder-mv-gray-500
  text-mv-gray-900
"
/>
```

### Cards

```html
<div class="
  bg-white
  rounded-2xl
  shadow-sm
  border border-mv-gray-200
  p-6
  hover:shadow-md
  transition-shadow
">
  Content
</div>
```

### Badge

```html
<!-- Success -->
<span class="
  px-3 py-1
  bg-mv-green-50
  text-mv-green-700
  rounded-full
  text-label
  font-medium
">
  Active
</span>

<!-- Warning -->
<span class="
  px-3 py-1
  bg-orange-50
  text-mv-orange-500
  rounded-full
  text-label
  font-medium
">
  Pending
</span>
```

---

## 🎭 Estados

### Hover
- Botones primarios: cambiar a `mv-green-600`
- Cards: aumentar shadow
- Links: underline

### Active/Pressed
- Botones: cambiar a `mv-green-700`
- Mantener visual feedback claro

### Disabled
```html
<button disabled class="
  opacity-50
  cursor-not-allowed
">
  Disabled
</button>
```

### Focus
- Ring de color: `focus:ring focus:ring-mv-green-100`
- Border: `focus:border-mv-green-500`

---

## 📐 Border Radius

| Tamaño | Valor | Uso |
|--------|-------|-----|
| XS | 4px | Pills, pequeños elementos |
| SM | 8px | Inputs, pequeños containers |
| MD | 12px (rounded-lg) | **Default para cards** |
| LG | 16px | Containers grandes |
| XL | 24px (rounded-2xl) | Hero sections, featured |

```html
<button class="rounded-lg">      <!-- 8px -->
<div class="rounded-xl">         <!-- 12px -->
<section class="rounded-2xl">    <!-- 16px, 24px -->
```

---

## ⚡ Sombras

### Tailwind Shadows

```html
<!-- Subtle shadow -->
<div class="shadow-sm">

<!-- Default shadow -->
<div class="shadow">

<!-- Hover shadow (tarjetas) -->
<div class="shadow-md hover:shadow-lg">

<!-- Elevated shadow -->
<div class="shadow-lg">

<!-- Heavy shadow (modales) -->
<div class="shadow-xl">
```

---

## 🌓 Dark Mode (Futuro)

*Actualmente no soportado, futuras versiones:*

```css
:root {
  --mv-green-500: #227A4B;
  --mv-gray-900: #171717;
}

@media (prefers-color-scheme: dark) {
  :root {
    --mv-green-500: #4CAF7F;
    --mv-gray-900: #FAFAFA;
  }
}
```

---

## ✅ Validación del Design System

El plugin valida automáticamente que los componentes cumplan:

```typescript
// ❌ DETECTADO - Color hex hardcodeado
<button className="bg-[#227A4B]">Buy</button>

// ✅ CORRECTO - Usar token MV
<button className="bg-mv-green-500">Buy</button>
```

### Checklist para Componentes

- [ ] ¿Usa colores de tokens (mv-green, mv-orange, etc.)?
- [ ] ¿Tipografía es Inter o Nunito?
- [ ] ¿Spacing es múltiplo de 4px?
- [ ] ¿Border radius es estándar (4, 8, 12, 16, 24px)?
- [ ] ¿Estados hover/active/disabled claros?
- [ ] ¿Sombras usan valores de Tailwind?

---

## 📚 Referencias

- **Figma:** [Design System en Figma](https://figma.com/...) (privado)
- **Notion:** [Design Tokens Documentation](https://notion.so/...) (privado)
- **Storybook:** [Component Library](https://storybook-mv.vercel.app) (en desarrollo)

---

## 🤖 Validación Automática

El plugin valida design system automáticamente:

```bash
# Ejecuta validación manual
/mv-dev:mv-design-system

# O en componentes:
# El plugin valida automáticamente al guardar
```

---

**¿Necesitas los colores exactos para Figma?** → Ver DESIGN_TOKENS.md en la raíz

