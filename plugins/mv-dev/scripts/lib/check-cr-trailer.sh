#!/bin/bash
# check-cr-trailer.sh
# Trazabilidad codigo->CR: detecta el trailer 'CR: <id>' en los commits a pushear.
#
# Ramas cr/*  -> fallo (exit 1) si falta el trailer.
# Otras ramas -> warning permisivo (exit 0).
# Ver docs/TRACEABILITY.md
#
# Extraido de validate-pre-push.sh para poder testearlo en aislamiento.
# Comportamiento identico al inline original.
#
# Exit 0 = OK (o warning no bloqueante)
# Exit 1 = FAIL (rama cr/* sin trailer)

COMMITS_BODY="$(git log --format=%B "@{upstream}"..HEAD 2>/dev/null || git log --format=%B -5 2>/dev/null)"
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"

if [ -n "$COMMITS_BODY" ] && ! printf '%s\n' "$COMMITS_BODY" | grep -qE '^CR: *[A-Za-z0-9][A-Za-z0-9-]*'; then
  case "$CURRENT_BRANCH" in
    cr/*)
      echo "❌ [trazabilidad] Rama '$CURRENT_BRANCH' (cr/*) sin trailer 'CR: <id>' en los commits a pushear." >&2
      echo "   Agregá 'CR: <cr_id>' al cuerpo del commit. Ver docs/TRACEABILITY.md" >&2
      exit 1
      ;;
    *)
      echo "⚠️  [trazabilidad] Ningún commit declara 'CR: <id>'. Cadena código→CR incompleta." >&2
      echo "   Convención: rama cr/<cr_id>-<slug> + trailer 'CR: <cr_id>' en el cuerpo del commit." >&2
      echo "   Ver docs/TRACEABILITY.md" >&2
      # Rama no-cr/*: warning only, NO exit 1.
      ;;
  esac
fi

exit 0
