# 🤖 Agentes Especializados del Plugin MV Dev

El plugin incluye **4 agentes especializados** que automatizan tareas de QA, Frontend, Backend y Documentación.

## ¿Qué es un Agente?

Un agente es un **asistente especializado** que actúa de forma autónoma dentro de Claude Code:
- 🔍 Analiza código y estructura
- ✅ Valida cumplimiento de estándares
- 📝 Genera reportes y recomendaciones
- 🔧 Puede hacer cambios automáticos

**Diferencia con Skills:**
- **Skill:** Tú lo invocas (`/mv-dev:start-project`) y sigue un workflow
- **Agente:** Se activa automáticamente o lo invocas para análisis profundo

---

## 4 Agentes Disponibles

### 1. QA Agent (Agente de Calidad)
**Especialidad:** Garantizar que el código está correctamente testeado.

**Responsabilidades:**
- ✅ Generar tests (Jest, React Testing Library, Playwright)
- ✅ Validar cobertura >= 80%
- ✅ Identificar edge cases no testeados
- ✅ Sugerir estrategias de testing
- ✅ Crear fixtures y mocks

**Cuándo se activa:**
- Automáticamente cuando crear un archivo nuevo
- Cuando ejecutas `/mv-dev:new-feature`
- Cuando hacer push sin suficiente cobertura

**Ejemplo de uso:**

```
Usuario: Escribe nuevo archivo services/paymentService.ts

🤖 QA Agent se activa automáticamente:
1. Analiza el código
2. Genera tests esqueleto
3. Identifica edge cases (error handling, retries)
4. Crea __tests__/paymentService.test.ts
5. Muestra cobertura esperada: 92%

Sugerencias:
- Agregar tests para timeout en pagos fallidos
- Mocker la API externa de pagos
- Validar reintentos exponenciales
```

**Análisis que hace:**
- Código que espera ser testeado
- Funciones puras vs con side-effects
- Dependencias externas
- Manejo de errores

---

### 2. Frontend Agent (Agente de Frontend)
**Especialidad:** Validar que los componentes siguen el design system de MV.

**Responsabilidades:**
- ✅ Verificar uso correcto de colores (design tokens)
- ✅ Validar tipografía (Inter, Nunito)
- ✅ Revisar accesibilidad (alt texts, aria labels)
- ✅ Cumplimiento de patrones Next.js
- ✅ Responsive design
- ✅ Estados del componente (loading, error, empty)

**Cuándo se activa:**
- Al crear archivo `.tsx` en `app/` o `components/`
- Cuando ejecutas `/mv-dev:new-page`
- Cuando escribes un componente nuevo

**Ejemplo de uso:**

```
Usuario: Crea components/ProductCard.tsx

🤖 Frontend Agent se activa:
1. Analiza el componente
2. Valida design tokens

Reporte:
✅ Colores: Usa mv-green-500 correcto
✅ Tipografía: Font family Nunito para body
⚠️ Accesibilidad: Falta alt text en imagen
✅ Responsive: Media queries correctas
⚠️ Estados: Falta state loading

Sugerencias:
- Agregar: alt={`Product: ${product.name}`}
- Agregar: {isLoading && <Skeleton />}
- Agregar: Aria-label para botón de compra
```

**Validaciones:**
- Colores hardcodeados en lugar de tokens
- Tipografía incorrecta
- Imágenes sin alt text
- Botones sin proper contrast ratio
- Breakpoints responsive correctos

---

### 3. Backend Agent (Agente de Backend)
**Especialidad:** Validar que APIs siguen patrones de MV.

**Responsabilidades:**
- ✅ Response format estándar (success, data, error)
- ✅ Validación con Zod
- ✅ Autenticación en rutas protegidas
- ✅ Manejo de errores
- ✅ Queries SQL seguros (LIMIT, no SELECT *)
- ✅ Logging adecuado

**Cuándo se activa:**
- Al crear archivo `.ts` en `routes/`, `controllers/`, `services/`
- Cuando ejecutas `/mv-dev:create-api`
- Cuando escribes un servicio nuevo

**Ejemplo de uso:**

```
Usuario: Crea routes/orders.ts

🤖 Backend Agent se activa:
1. Analiza el endpoint
2. Valida patrones de API

Reporte:
✅ Response format: success, data, error ✓
✅ Try/catch: Presente ✓
⚠️ Validación: Sin Zod schema
✅ Auth middleware: Bearer token ✓
⚠️ Error logging: Mensaje genérico

Sugerencias:
- Agregar: const schema = z.object({...})
- Validar entrada: orderSchema.parse(body)
- Error logging específico: [Orders] Error creating order: {error}
```

**Validaciones:**
- Response format incorrecto
- Sin validación de entrada
- Sin try/catch
- Sin autenticación
- Queries sin LIMIT
- SELECT * en base de datos
- Errores no logueados

---

### 4. Doc Agent (Agente de Documentación)
**Especialidad:** Crear y mantener documentación actualizada.

**Responsabilidades:**
- ✅ Generar documentación de APIs
- ✅ Actualizar README automáticamente
- ✅ Crear guías de features
- ✅ Sincronizar con Notion
- ✅ Mantener CHANGELOG actualizado
- ✅ Generar diagramas de arquitectura

**Cuándo se activa:**
- Automáticamente después de crear un proyecto
- Cuando ejecutas `/mv-dev:new-feature`
- Cuando haces merge a main

**Ejemplo de uso:**

```
Usuario: Ejecuta /mv-dev:new-feature para "Payment Integration"

🤖 Doc Agent se activa:
1. Crea documentación automática

Genera:
- docs/FEATURE_PAYMENT_INTEGRATION.md
  - Descripción
  - Endpoints API
  - Base de datos
  - Flujo de usuario
  - Ejemplos de uso

- Actualiza: README.md (sección Features)
- Actualiza: CHANGELOG.md (nueva entrada)
- Sincroniza a Notion (si NOTION_TOKEN)

Output:
📄 Created: docs/FEATURE_PAYMENT_INTEGRATION.md
✅ Updated: README.md
✅ Updated: CHANGELOG.md
✅ Synced to Notion
```

**Documentación generada:**
- Descripción de feature
- Endpoints/funciones expuestas
- Tipos y interfaces
- Ejemplos de uso
- Flujos de usuario
- Decisiones arquitectónicas

---

## 🚀 Cómo Usar los Agentes

### Activación Automática
Los agentes se activan automáticamente en ciertos eventos:

```
Evento                          → Agente activado
Crear archivo .tsx             → Frontend Agent
Crear archivo .ts routes/      → Backend Agent
Crear archivo .ts services/    → Backend Agent + QA Agent
Ejecutar /mv-dev:new-feature   → Todos los agentes
Ejecutar /mv-dev:start-project → Todos los agentes
Push a rama                     → QA Agent (validar coverage)
```

### Invocación Manual
Puedes pedir análisis profundo directamente:

```
"QA Agent: analiza si tenemos suficiente coverage en paymentService.ts"
Claude invoca el QA Agent automáticamente

"Frontend Agent: revisa si cumplimos design system en estas 3 páginas"
Claude invoca el Frontend Agent automáticamente
```

### Reportes Generados

Cada agente genera reportes estructurados:

**QA Report:**
```
Coverage Analysis for src/services/orders.ts:
- Overall: 85%
- Statements: 92%
- Branches: 78%
- Functions: 88%
- Lines: 90%

Missing:
- Error handling for timeout (2 cases)
- Edge case: empty items array

Recommendations:
1. Add tests for timeout scenario
2. Add tests for validation errors
```

**Frontend Report:**
```
Design System Compliance for components/OrderCard.tsx:
- Colors: ✅ 100% compliant
- Typography: ✅ 100% compliant
- Spacing: ⚠️ 2 inconsistencies
- Accessibility: ⚠️ Missing alt texts

Issues:
1. Image without alt: line 42
2. Button without aria-label: line 88

Auto-fixes applied: 0
Manual fixes needed: 2
```

---

## 📊 Matriz de Responsabilidades

| Aspecto | QA Agent | Frontend | Backend | Doc Agent |
|---------|----------|----------|---------|-----------|
| **Testing** | ✅ | - | - | - |
| **Coverage** | ✅ | - | - | - |
| **Design System** | - | ✅ | - | - |
| **Accessibility** | - | ✅ | - | - |
| **API Patterns** | - | - | ✅ | - |
| **Security** | ⚠️ | - | ✅ | - |
| **Documentation** | - | - | - | ✅ |
| **Changelog** | - | - | - | ✅ |

---

## 🎯 Workflow con Agentes

### Crear un Feature Nuevo
```
1. Usuario: /mv-dev:new-feature
2. Agentes se activan todos:
   - Doc Agent: Crea estructura de docs
   - Frontend Agent: Estructura de componentes
   - Backend Agent: Estructura de APIs
   - QA Agent: Genera tests esqueleto
3. Usuario completa la implementación
4. QA Agent valida cobertura
5. Otros agentes validan patrones
6. Listo para push
```

### Verificar Calidad Antes de Push
```
1. Usuario corre: npm test
2. Si coverage < 80%, QA Agent sugiere qué testear
3. Frontend Agent valida design tokens
4. Backend Agent valida APIs
5. Doc Agent verifica que documentación está actualizada
6. Todo pasa → Push safe
```

---

## 🔧 Configuración de Agentes

Los agentes se configuran en `plugins/mv-dev/.claude-plugin/plugin.json`:

```json
"agents": {
  "qa-agent": {
    "enabled": true,
    "triggers": ["test-validation", "coverage-check"]
  },
  "frontend-agent": {
    "enabled": true,
    "triggers": ["tsx-file-create", "design-audit"]
  },
  "backend-agent": {
    "enabled": true,
    "triggers": ["api-route-create", "service-create"]
  },
  "doc-agent": {
    "enabled": true,
    "triggers": ["feature-create", "merge-to-main"]
  }
}
```

---

## 📝 Notas

- Los agentes NO hacen cambios sin aprobación
- Siempre sugieren, nunca obligan
- Generan reportes detallados de sus análisis
- Se pueden ejecutar en paralelo (no interfieren)

---

**Siguiente:** [Leer sobre Design System →](DESIGN_SYSTEM.md)
