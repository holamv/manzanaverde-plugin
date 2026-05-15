# 🚀 Workflow: Deployar a Staging

Guía para desplegar cambios a staging con validaciones automáticas.

## ⏱️ Duración: 5-15 minutos

## 📋 Requisitos

- `VERCEL_TOKEN` configurado (para proyectos Next.js)
- `RAILWAY_TOKEN` configurado (para proyectos Express)
- Todos los tests pasando
- Branch diferente a `main`

---

## ⚠️ Reglas de Deployment

1. **NUNCA** deployar directo a producción sin code review
2. **NUNCA** mergear a `main` sin PR aprobado
3. **SIEMPRE** probar en staging antes de producción
4. **SIEMPRE** usar branches: `feature/`, `fix/`, `hotfix/`

---

## 📍 Paso 1: Pre-flight Checks (automáticos)

El plugin valida automáticamente antes de deployar:

```
/mv-dev:deploy-staging
```

**El skill ejecuta:**
```bash
# 1. TypeScript
npm run type-check

# 2. Linting
npm run lint

# 3. Tests con coverage
npm test -- --coverage

# 4. Detección de secrets
grep -r "password\|api_key\|secret" --include="*.ts" .

# 5. Build
npm run build
```

**Si alguno falla, el deploy se detiene y se muestra el error.**

---

## 📍 Paso 2: Verificar Manualmente (antes del skill)

Antes de ejecutar el skill, verifica localmente:

```bash
# TypeScript sin errores
npm run type-check

# Linting limpio
npm run lint

# Tests pasan con >= 80% coverage
npm test -- --coverage

# Build exitoso
npm run build
```

Todos deben pasar. Si alguno falla, arreglar primero.

---

## 📍 Paso 3: Crear PR y Abrir para Review

Staging deploy va de la mano con un PR:

```bash
# 1. Asegúrate de estar en tu branch
git status

# 2. Commit y push
git add -p   # revisar cada cambio antes de agregar
git commit -m "feat: descripción corta del cambio"
git push origin feature/nombre-de-tu-feature

# 3. Abrir PR en GitHub
# Usar el template de PR en plugins/mv-dev/templates/pr-template.md
```

**PR title format:** `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`

---

## 📍 Paso 4: Deploy Automático en Vercel (Frontend)

Cada push a cualquier rama dispara un **Preview Deploy** automático en Vercel.

**URL del preview:**
```
https://mv-app-nombre-git-feature-nombre.vercel.app
```

**Vercel Dashboard:** Buscar tu proyecto → Deployments → ver el último.

Si el deploy falla, revisar los logs en el Vercel Dashboard.

---

## 📍 Paso 5: Deploy Manual en Railway (Backend)

Para proyectos Express, deployar manualmente:

```bash
# Con el skill
/mv-dev:deploy-staging

# O manualmente con Railway CLI
railway up --service mv-backend-service
```

**Verificar el deploy:**
```bash
# Health check
curl https://staging-api.manzanaverde.la/health

# Respuesta esperada
{"status": "ok", "version": "1.2.3"}
```

---

## 📍 Paso 6: Smoke Test en Staging

Después del deploy, verifica las funcionalidades principales:

```bash
# Ejecutar E2E contra staging
PLAYWRIGHT_BASE_URL=https://staging.manzanaverde.la npm run test:e2e

# O manualmente en el navegador:
# 1. Login
# 2. Ver dashboard
# 3. Ver órdenes
# 4. La feature que deployaste
```

---

## 📍 Paso 7: Compartir para Review

Una vez que staging está ok:

1. Agregar la URL de staging al PR
2. Notificar al reviewer
3. Esperar aprobación antes de mergear a `main`

---

## ✅ Checklist de Deploy

- [ ] ¿Branch diferente a `main`?
- [ ] ¿TypeScript compila sin errores?
- [ ] ¿ESLint pasa?
- [ ] ¿Tests pasan con >= 80% coverage?
- [ ] ¿Build exitoso?
- [ ] ¿No hay secrets en el código?
- [ ] ¿PR abierto en GitHub?
- [ ] ¿Smoke test en staging?
- [ ] ¿URL de staging en el PR?

---

## 🚨 Troubleshooting

### "Vercel deploy falla"
- Revisar logs en Vercel Dashboard → Deployments
- Verificar que `npm run build` pasa localmente
- Revisar variables de entorno en Vercel (pueden faltar)

### "Railway deploy falla"
- Revisar logs: `railway logs --service mv-backend-service`
- Verificar que el `PORT` está configurado como variable de entorno en Railway
- Verificar que el `start` script en `package.json` es correcto

### "Tests fallan en CI pero pasan localmente"
- Revisar que todas las variables de entorno están en el secreto de GitHub Actions
- Verificar que no hay dependencia de orden en los tests
- Ejecutar: `npm test -- --runInBand` para reproducir el orden de CI

### "Coverage < 80% bloquea el push"
- El hook pre-push es intencional
- Ejecutar: `npm test -- --coverage --verbose` para ver qué falta
- Agregar tests para los casos faltantes
- No usar `--no-verify` para saltarse el hook

---

## 📚 Referencias

- [Skill deploy-staging](10-SKILLS.md#deploy-staging)
- [Skill mv-deployment](10-SKILLS.md#mv-deployment)
- [Variables de Entorno](ENVIRONMENT_VARS.md)
- [Hooks de Validación](30-HOOKS.md)
