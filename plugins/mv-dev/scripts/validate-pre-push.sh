#!/bin/bash
# validate-pre-push.sh
# Validaciones pre-push: TypeScript types y tests.
# Puede usarse como git pre-push hook o ejecutarse manualmente.
#
# Exit 0 = OK
# Exit 1 = FAIL

ERRORS=0

echo "Pre-push checks..."
echo ""

# --- Fase 1: trazabilidad codigo->CR (warning, nunca falla) ---
# Detecta el trailer 'CR: <id>' en los commits que se van a pushear.
# En Fase 1 solo avisa; el endurecimiento a fallo (solo ramas cr/*) es Fase 3.
# Ver docs/TRACEABILITY.md.
COMMITS_BODY="$(git log --format=%B "@{upstream}"..HEAD 2>/dev/null || git log --format=%B -5 2>/dev/null)"
if [ -n "$COMMITS_BODY" ] && ! printf '%s\n' "$COMMITS_BODY" | grep -qE '^CR: *[A-Za-z0-9][A-Za-z0-9-]*'; then
  echo "⚠️  [trazabilidad] Ningún commit declara 'CR: <id>'. Cadena código→CR incompleta." >&2
  echo "   Convención: rama cr/<cr_id>-<slug> + trailer 'CR: <cr_id>' en el cuerpo del commit." >&2
  echo "   Ver docs/TRACEABILITY.md" >&2
  # Fase 1: warning only, NO exit 1.
fi
# --- fin trazabilidad Fase 1 ---

# 1. TypeScript type checking
echo "[1/3] Checking TypeScript types..."
if command -v npx &> /dev/null && [ -f "tsconfig.json" ]; then
  if npx tsc --noEmit 2>/dev/null; then
    echo "  OK - Types correctos"
  else
    echo "  FAIL - Errores de TypeScript"
    npx tsc --noEmit 2>&1 | head -20
    ERRORS=1
  fi
else
  echo "  SKIP - TypeScript no configurado"
fi
echo ""

# --- SP5: gate tiered de flujo critico ---
CRITICAL_RE='checkout|PagoForm|payment|od-order|dailyfood|foodcourt|wallet|card-add|api/payment|auth|login|registro|membership_charges'
CHANGED="$(git diff --name-only "@{upstream}"..HEAD 2>/dev/null || git diff --name-only HEAD~1..HEAD 2>/dev/null || git diff --name-only)"
CRIT="$(printf '%s\n' "$CHANGED" | grep -Ei "$CRITICAL_RE" | grep -Ev '\.(spec|test)\.|\.feature$' || true)"
if [ -n "$CRIT" ]; then
  COV=""
  # heuristica (no analisis real): test cambiado en el push...
  printf '%s\n' "$CHANGED" | grep -Eiq '\.(spec|test)\.|\.feature$' && COV=1
  # ...o existe un test cuyo nombre matchea el modulo critico cambiado
  if [ -z "$COV" ]; then
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      base="$(basename "$f" | sed -E 's/\.(tsx?|jsx?)$//')"
      if find . -path ./node_modules -prune -o -type f \( -name "*${base}*.spec.*" -o -name "*${base}*.test.*" \) -print 2>/dev/null | grep -q .; then COV=1; break; fi
    done <<EOF
$CRIT
EOF
  fi
  if [ -z "$COV" ]; then
    echo "❌ Cambio en flujo critico sin test que lo cubra:"
    printf '%s\n' "$CRIT" | while IFS= read -r _f; do [ -n "$_f" ] && printf '   %s\n' "$_f"; done
    echo "   Agregá/tocá un test (ver /mv-dev:test-decision) o justificá el skip explicitamente."
    exit 1
  fi
fi
# --- fin gate tiered; cambios no criticos siguen el flujo permisivo de abajo ---

# --- SP2: doc-gate tiered ---
# Reusa $CHANGED detectado arriba.
# Codigo de producto no-trivial: src/** excluyendo tests/specs/md/config
PROD_CODE="$(printf '%s\n' "$CHANGED" | grep -E '^src/' | grep -Ev '\.(test|spec)\.|\.test\.|\.spec\.|\.md$|\.json$|\.yaml$|\.yml$|\.env' || true)"
# Cambios en docs/
DOCS_CHANGED="$(printf '%s\n' "$CHANGED" | grep -E '^docs/' || true)"

if [ -n "$PROD_CODE" ] && [ -z "$DOCS_CHANGED" ]; then
  # Heuristica de "nueva capacidad": algun archivo de src/ es nuevo en este push
  NEW_FILES="$(git diff --name-status "@{upstream}"..HEAD 2>/dev/null || git diff --name-status HEAD~1..HEAD 2>/dev/null || git diff --name-status)"
  NEW_SRC="$(printf '%s\n' "$NEW_FILES" | awk '$1=="A"{print $2}' | grep -E '^src/' | grep -Ev '\.(test|spec)\.|\.test\.|\.spec\.|\.md$' || true)"

  # Heuristica BUG: si todos los archivos modificados son de fix/patch (sin nuevos archivos de src)
  if [ -n "$NEW_SRC" ]; then
    # Capacidad nueva sin delta en docs/ → BLOQUEAR
    echo ""
    echo "📄 Doc-gate: cambio en capacidad nueva sin delta en docs/"
    echo "   Archivos de producto nuevos sin docs/ actualizado:"
    printf '%s\n' "$NEW_SRC" | while IFS= read -r _f; do [ -n "$_f" ] && printf '   %s\n' "$_f"; done
    echo ""
    echo "   Agregá el delta a docs/ (ver /mv-dev:new-feature Paso 5) antes de hacer push."
    echo "   Si es realmente una BUG/trivial sin doc necesaria, bypasseá con:"
    echo "     git push --no-verify"
    echo "   (Si omitís el gate con --no-verify, el hook no corre y nada queda registrado.)"
    exit 1
  else
    # Refactor/modificacion sin archivos nuevos → solo avisar, no bloquear
    echo ""
    echo "⚠️  Doc-gate: refactor/modificacion en src/ sin cambios en docs/."
    echo "   Si agregaste comportamiento nuevo, considera un delta en docs/ antes del PR."
    echo "   (Continuando — no bloquea para cambios internos/refactor.)"
    echo ""
  fi
fi
# --- fin doc-gate SP2 ---

# 2. Run tests
echo "[2/3] Running tests..."
if [ -f "package.json" ]; then
  if grep -q '"test"' package.json 2>/dev/null; then
    if npm test -- --passWithNoTests --silent 2>/dev/null; then
      echo "  OK - Tests pasan"
    else
      echo "  FAIL - Tests fallaron"
      ERRORS=1
    fi
  else
    echo "  SKIP - No hay script de test"
  fi
else
  echo "  SKIP - No hay package.json"
fi
echo ""

# 3. Check for 'any' type in non-test TypeScript files
echo "[3/3] Checking for 'any' type usage..."
ANY_FOUND=""
for file in $(find . -name "*.ts" -o -name "*.tsx" 2>/dev/null | grep -v node_modules | grep -v '.test.' | grep -v '.spec.' | grep -v '.d.ts' | grep -v 'dist/'); do
  matches=$(grep -n ': any\b\|: any;\|: any,\|: any)\|<any>' "$file" 2>/dev/null | grep -v '// @allow-any' | grep -v '@ts-ignore')
  if [ -n "$matches" ]; then
    ANY_FOUND="$ANY_FOUND\n  $file:\n$matches"
  fi
done

if [ -n "$ANY_FOUND" ]; then
  echo "  WARN - Uso de 'any' detectado (reemplazar con tipos especificos):"
  echo -e "$ANY_FOUND" | head -20
else
  echo "  OK - Sin uso de 'any'"
fi
echo ""

# Resultado final
echo "========================================="
if [ $ERRORS -eq 0 ]; then
  echo "Pre-push: PASSED"
  exit 0
else
  echo "Pre-push: FAILED"
  echo "Corrige los errores antes de hacer push."
  exit 1
fi
