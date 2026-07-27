<!--
  TEMPLATE único de PRD para trabajo de código en MV.
  Fuente única: la skill `crear-prd` llena este template. Ningún otro skill
  debe redefinir el formato de un PRD — si necesitás uno, referenciá este archivo.

  Dos modos de salida:
    - PRD ligero  (BUG defecto): bloques 1, 3, 4, 5, 8.
    - PRD completo (BET / RESUME): los 8 bloques.
  Borrá los bloques que no apliquen al modo y borrá estos comentarios al generar.

  Placeholders entre <...>. La clasificación (bloque 3) se transcribe de
  `/mv-dev:test-decision`, NO se re-decide acá.
-->

# PRD — <título corto del trabajo>

> Modo: **<ligero | completo>** · Generado por `/mv-dev:crear-prd` · Fecha: <YYYY-MM-DD>

---

## 1. Identidad y trazabilidad

| Campo | Valor |
|---|---|
| `cr_id` | <CR-xxxx> |
| `exp_id` | <exp_id o n/a> |
| `kpi_definition_id` | <id o n/a> |
| Notion task | <link o n/a> |
| Discord thread | <link o n/a> |
| Repo | <owner/repo> |
| Branch | `cr/<cr_id>-<slug>` |

<!-- El branch sigue la convención de docs/TRACEABILITY.md. El commit lleva el
     trailer `CR: <cr_id>` (+ opcional `Exp: <exp_id>`). -->

---

## 2. Problema y alcance
<!-- Bloque completo. En PRD ligero se omite. -->

### Problema
<Conversacional: qué está roto o qué falta, y por qué importa. HECHO vs HIPÓTESIS.>

### Alcance
<Qué entra en este trabajo. Bullets concretos.>

### Qué NO cambia — restricciones duras
<!-- OBLIGATORIO. Un PRD sin esta subsección está incompleto. -->

| Restricción | Razón |
|---|---|
| <no tocar X> | <por qué> |

---

## 3. Clasificación

<!-- Transcribir de /mv-dev:test-decision. NO re-decidir acá. test-decision es
     la fuente única de clasificación (BUG/BET/RESUME + matriz). -->

- **Change-type:** <BUG defecto | BUG trivial | BET | RESUME>
- **Superficie:** <función pura | componente | endpoint | flujo crítico | copy/config | ...>
- **Test a crear (según la matriz de test-decision):** <p. ej. Jest unit | RTL | supertest | Playwright E2E | ninguno>
- **Mock vs real:** <según la Regla de oro de test-decision>

---

## 4. Discovery — archivos verificados

<!-- Discovery interno estilo mv-instruction-generator: grep real, no asunciones.
     Verificar rutas contra la rama base antes de escribir. -->

| Archivo | Rol en este trabajo |
|---|---|
| `<ruta>` | <qué papel cumple / se modifica / se lee> |

### Dependencias y riesgos de regresión

| Riesgo | Mitigación |
|---|---|
| <qué podría romperse> | <cómo se evita> |

<!-- ¿Toca algún archivo "sagrado" de pago? Si sí → STOP, confirmación explícita.
     Guards de pago: checkout/PagoForm/payment/od-order/dailyfood/foodcourt/wallet/card-add/api/payment -->

---

## 5. Plan de tests

<!-- Derivado de la matriz de test-decision, no inventado acá. -->

**Cobertura primero:** antes de escribir, `grep` en `tests/ __tests__/ *.spec.ts *.test.ts *.feature`
por la superficie afectada y correr el baseline verde. Solo escribir lo que falta.

| Componente | Superficie | Test | Estado |
|---|---|---|---|
| `<archivo>` | <superficie> | <test> | <existe / falta> |

---

## 6. Observabilidad y logs
<!-- Bloque nuevo (no existe en otros skills). En PRD ligero se omite. -->

Qué queda medible cuando esto llegue a prod:

| Señal | Dónde se lee | Cómo se sabe que funcionó |
|---|---|---|
| <evento/log emitido> | <dónde: tabla, GitHub API, salida del hook, dashboard> | <criterio de éxito> |

<!-- Emitir con prefijo consistente para poder grepear. No construir dashboard acá. -->

---

## 7. Documentación a actualizar
<!-- Bloque completo. En PRD ligero se omite. -->

| Doc | Qué |
|---|---|
| `docs/<...>` | <qué se agrega/cambia> |
| Notion (vía `doc-agent`) | <qué página, qué delta> |

---

## 8. Definition of Done

- [ ] Tests correctos por change-type en verde (ver bloque 5)
- [ ] Build pasa (`tsc --noEmit` + build del proyecto)
- [ ] Cobertura del área afectada sin regresión
- [ ] Documentación actualizada (bloque 7, si aplica)
- [ ] Branch `cr/<cr_id>-<slug>`, commits con trailer `CR: <cr_id>`
- [ ] PR con bloque de trazabilidad completo y link a este PRD
- [ ] <criterios específicos del trabajo>
