#!/bin/bash
# context-bootstrap.sh
# SessionStart hook: refresca el mirror del OS de Manzana Verde si esta viejo,
# o lo clona si no existe. El stdout se inyecta como contexto para Claude.
# FAIL-SOFT: cualquier error de red/git sale con exit 0 para no bloquear la sesion.

MIRROR_DIR="$HOME/Projects/manzana-verde-os"
MIRROR_REPO="https://github.com/holamv/manzana-verde-os"
LAST_SYNCED_FILE="$MIRROR_DIR/.last_synced"
TTL=3600  # 1 hora, alineado al sync horario de Notion→Git

# Funcion de exit limpio: nunca bloquea la sesion
fail_soft() {
  echo "[MV Plugin] context-bootstrap: $1 (continuando sin mirror)"
  exit 0
}

# Caso 1: el mirror no existe → clonar
if [ ! -d "$MIRROR_DIR" ]; then
  echo "[MV Plugin] Clonando mirror del OS de MV en $MIRROR_DIR ..."
  if git clone --depth=1 "$MIRROR_REPO" "$MIRROR_DIR" 2>/dev/null; then
    date +%s > "$LAST_SYNCED_FILE" 2>/dev/null || true
    echo "[MV Plugin] Mirror clonado correctamente. Contexto disponible en $MIRROR_DIR"
  else
    fail_soft "no se pudo clonar $MIRROR_REPO (sin red o repo privado)"
  fi
  exit 0
fi

# Caso 2: el mirror existe → verificar frescura
NOW=$(date +%s)
LAST_SYNCED=0

if [ -f "$LAST_SYNCED_FILE" ]; then
  LAST_SYNCED=$(cat "$LAST_SYNCED_FILE" 2>/dev/null || echo 0)
fi

AGE=$(( NOW - LAST_SYNCED ))

if [ "$AGE" -lt "$TTL" ]; then
  # Mirror fresco, no hace falta pull
  exit 0
fi

# Mirror viejo (> TTL) → pull --ff-only
if git -C "$MIRROR_DIR" pull --ff-only --quiet 2>/dev/null; then
  date +%s > "$LAST_SYNCED_FILE" 2>/dev/null || true
  echo "[MV Plugin] Mirror actualizado ($MIRROR_DIR). Contexto fresco disponible."
else
  # pull fallo (sin red, conflicto, etc.) → fail-soft: no bloquear
  # Aun actualizamos el timestamp para no reintentar cada sesion sin red
  date +%s > "$LAST_SYNCED_FILE" 2>/dev/null || true
  fail_soft "git pull fallo en $MIRROR_DIR (sin red o conflicto); usando mirror existente"
fi

exit 0
