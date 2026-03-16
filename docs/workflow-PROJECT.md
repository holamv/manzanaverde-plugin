# 🚀 Workflow: Crear un Proyecto Nuevo

Guía paso a paso para crear un nuevo proyecto web o backend con el plugin.

## ⏱️ Duración: 10-15 minutos

## 📋 Requisitos

- Plugin MV Dev instalado
- Tokens configurados (al menos `CONTEXT7_API_KEY`)
- Carpeta donde quieras crear el proyecto

## 🎯 Objetivo

Al final de este workflow tendrás:
- ✅ Proyecto Next.js o Express listo para codificar
- ✅ TypeScript configurado (strict mode)
- ✅ Tailwind CSS integrado
- ✅ ESLint y Prettier configurados
- ✅ Estructura de testing (Jest, RTL, Playwright)
- ✅ Documentación base
- ✅ Primer commit inicial

---

## 📍 Paso 1: Entender qué Existe (5 min)

Antes de crear nada, descubre qué ya existe en MV:

```
/mv-dev:discovery
```

**Responde las preguntas:**
- ¿Cuál es el objetivo del proyecto?
- ¿Necesita integración con APIs existentes?
- ¿Hay funcionalidad similar ya hecha?

**Resultado esperado:**
```
📋 Análisis:
- Servicios existentes que puedes reutilizar
- APIs disponibles
- Tablas de BD relevantes
- Patrones a seguir
```

**Nota:** Si es un proyecto muy diferente, puedes saltar este paso.

---

## 📍 Paso 2: Crear el Proyecto (3-5 min)

Crea la estructura base:

```
/mv-dev:start-project
```

**El plugin te preguntará:**

1. **¿Qué tipo de proyecto?**
   - `Next.js (Frontend)` - Si necesitas UI (web app, landing, admin)
   - `Express (Backend)` - Si necesitas API REST
   - `Monorepo` - Si necesitas frontend + backend en uno

2. **¿Nombre del proyecto?**
   - Recomendación: `mv-nombre-app` o `mv-nombre-service`
   - Ej: `mv-reports-dashboard`, `mv-payment-service`

3. **¿Descripción?**
   - Breve descripción (2-3 palabras)
   - Ej: "Dashboard de reportes en tiempo real"

4. **¿Incluir ejemplos?**
   - Sí: Genera componentes/endpoints de ejemplo
   - No: Estructura vacía lista para tu código

**Lo que genera:**

### Para Next.js:
```
mv-reports-app/
├── app/
│   ├── layout.tsx
│   ├── page.tsx
│   └── api/
├── components/
├── lib/
├── __tests__/
├── public/
├── package.json
├── tsconfig.json
├── tailwind.config.ts
├── .eslintrc.json
├── .prettierrc
└── README.md
```

### Para Express:
```
mv-payment-service/
├── src/
│   ├── routes/
│   ├── controllers/
│   ├── services/
│   ├── middleware/
│   ├── types/
│   └── index.ts
├── __tests__/
├── package.json
├── tsconfig.json
├── .eslintrc.json
└── README.md
```

---

## 📍 Paso 3: Instalar Dependencias

El plugin genera `package.json` pero necesitas instalar:

```bash
cd mv-reports-app
npm install
```

**¿Qué instala?**
- React, Next.js, TypeScript, Tailwind
- Testing: Jest, React Testing Library, Playwright
- ESLint, Prettier
- Utilidades: Zod para validación

**Duración:** 2-5 minutos (depende de tu conexión)

---

## 📍 Paso 4: Explorar la Estructura

Abre el proyecto en tu editor y familiarízate:

```
/mv-reports-app
```

**Archivos importantes:**

- `package.json` - Dependencias y scripts
- `tsconfig.json` - Configuración TypeScript (strict mode)
- `tailwind.config.ts` - Configuración de Tailwind con tokens MV
- `.eslintrc.json` - Reglas de código
- `README.md` - Documentación del proyecto
- `app/page.tsx` - Página principal

**Verifica que todo está ahí:**
```bash
# Compilar TypeScript
npm run build

# Linter
npm run lint

# Tests
npm test
```

Deberían todos pasar (algunos tests estarán vacíos, eso está bien).

---

## 📍 Paso 5: Crear Primer Componente o Endpoint

### Si es Next.js - Crear página:
```
/mv-dev:new-page
```

Ej: Página de "Orders"
- Ruta: `/orders`
- Tipo: Mostrar lista de órdenes
- Con filtros: Sí

### Si es Express - Crear endpoint:
```
/mv-dev:create-api
```

Ej: Endpoint de pagos
- Método: POST
- Ruta: `/api/payments`
- Parámetros: order_id, amount, method

---

## 📍 Paso 6: Hacer Primer Commit

Guarda los cambios:

```bash
git add .
git commit -m "chore: initial project setup"
```

**El hook pre-commit validará:**
- ✅ ESLint
- ✅ Prettier
- ✅ No hay secrets

Si todo pasa:
```
✅ Commit successful
```

---

## 📍 Paso 7: Crear Rama para Tu Feature (Opcional)

Si vas a trabajar en una feature:

```bash
git checkout -b feature/nombre-corto
```

Ej: `feature/orders-list`

---

## ✅ Checklist de Finalización

- [ ] ¿Se creó la carpeta del proyecto?
- [ ] ¿Se instalaron dependencias (`npm install`)?
- [ ] ¿Se ejecutó `npm run build` exitosamente?
- [ ] ¿Se ejecutó `npm test` sin errores?
- [ ] ¿Se hizo primer commit?
- [ ] ¿Está la rama principal en `main`?

---

## 🚀 Siguientes Pasos

1. **Si necesitas agregar features:**
   ```
   /mv-dev:new-feature
   ```

2. **Si necesitas crear más páginas:**
   ```
   /mv-dev:new-page
   ```

3. **Si necesitas crear endpoints:**
   ```
   /mv-dev:create-api
   ```

4. **Cuando estés listo para probar:**
   ```
   /mv-dev:deploy-staging
   ```

---

## 🚨 Troubleshooting

### "npm install falla"
- Verifica que tienes Node.js 20 LTS
- Ejecuta: `npm cache clean --force`
- Intenta de nuevo

### "TypeScript errores"
- Verifica que `tsconfig.json` tiene `"strict": true`
- Algunos errores son por propósito (aprender tipos)
- Si necesitas debug: `npm run type-check`

### "Tests fallan"
- Algunos tests esqueleto pueden fallar
- Eso es normal en estructura nueva
- Los completarás según necesidad

### "ESLint errores"
- Ejecuta: `npm run lint -- --fix`
- Auto-fixes algunas cosas
- Otras necesitas arreglar manualmente

---

## 📚 Referencias

- [Guía Rápida](01-QUICK_START.md)
- [Crear Feature](workflow-FEATURE.md)
- [Estandares de Código](CODE_STANDARDS.md)
- [Design System](DESIGN_SYSTEM.md)

---

**¿Listo?** Ahora crea tu primer feature con `/mv-dev:new-feature`
