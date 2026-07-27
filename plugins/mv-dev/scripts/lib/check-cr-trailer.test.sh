#!/bin/bash
# check-cr-trailer.test.sh
# Casos ejecutables para check-cr-trailer.sh (DoD Fases 1 y 3 del PRD crear-prd).
#
# Uso: bash plugins/mv-dev/scripts/lib/check-cr-trailer.test.sh
# Exit 0 = todos verdes · Exit 1 = alguno falla

set -u

SUT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/check-cr-trailer.sh"
PASS=0
FAIL=0

# Crea un repo git temporal con una rama y un commit, corre el SUT, devuelve
# exit code y stderr.
run_case() {
  local branch="$1" msg="$2"
  local tmp
  tmp="$(mktemp -d)"
  (
    cd "$tmp" || exit 99
    git init -q .
    git config user.email t@t.t
    git config user.name t
    git config commit.gpgsign false
    git checkout -q -b "$branch"
    echo x > f.txt
    git add f.txt
    git commit -q -m "$msg"
    bash "$SUT" 2>/tmp/_stderr_out
  )
  local code=$?
  STDERR="$(cat /tmp/_stderr_out 2>/dev/null)"
  rm -rf "$tmp"
  return $code
}

check() {
  local name="$1" expected_code="$2" expected_grep="$3" branch="$4" msg="$5"
  run_case "$branch" "$msg"
  local code=$?
  local ok=1
  [ "$code" -eq "$expected_code" ] || ok=0
  if [ -n "$expected_grep" ]; then
    printf '%s\n' "$STDERR" | grep -q "$expected_grep" || ok=0
  else
    [ -z "$STDERR" ] || ok=0
  fi
  if [ "$ok" -eq 1 ]; then
    echo "  ✅ $name"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $name (exit=$code esperado=$expected_code)"
    [ -n "$STDERR" ] && echo "     stderr: $STDERR"
    FAIL=$((FAIL + 1))
  fi
}

echo "check-cr-trailer.sh"
echo ""

# 1. Rama cr/* CON trailer -> pasa, sin ruido
check "cr/* con trailer -> exit 0 sin output" 0 "" \
  "cr/CR-0421-fix" "$(printf 'fix: algo\n\nCR: CR-0421')"

# 2. Rama cr/* SIN trailer -> falla (Fase 3)
check "cr/* sin trailer -> exit 1" 1 "❌" \
  "cr/CR-0421-fix" "fix: algo sin trailer"

# 3. Rama normal SIN trailer -> warning, no bloquea (Fase 1)
check "feat/* sin trailer -> exit 0 con warning" 0 "⚠️" \
  "feat/loquesea" "feat: algo sin trailer"

# 4. Rama normal CON trailer -> pasa, sin ruido
check "feat/* con trailer -> exit 0 sin output" 0 "" \
  "feat/loquesea" "$(printf 'feat: algo\n\nCR: CR-0099')"

# 5. Trailer malformado (sin id) en cr/* -> falla
check "cr/* con 'CR:' vacío -> exit 1" 1 "❌" \
  "cr/CR-0421-fix" "$(printf 'fix: algo\n\nCR:')"

# 6. Trailer en minúscula no cuenta (el regex exige 'CR:')
check "cr/* con 'cr:' minúscula -> exit 1" 1 "❌" \
  "cr/CR-0421-fix" "$(printf 'fix: algo\n\ncr: CR-0421')"

# 7. Trailer que no está al inicio de línea no cuenta
check "cr/* con 'ver CR: x' inline -> exit 1" 1 "❌" \
  "cr/CR-0421-fix" "$(printf 'fix: algo\n\nver CR: CR-0421')"

# 8. Sin upstream configurado: cae al fallback 'git log -5' sin romper
check "sin upstream -> no crashea (fallback)" 0 "" \
  "main" "$(printf 'chore: inicial\n\nCR: CR-0001')"

echo ""
echo "  $PASS verde · $FAIL rojo"
[ "$FAIL" -eq 0 ] || exit 1
