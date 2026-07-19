---
name: ejecutar-campana
description: EJECUTA una campaña en el canal elegido — ManyChat (WhatsApp/Correo → insumos CSV+JSON) o BackOffice (Banner/Modal/Card → crea campaña; Push → crea notificación y la envía o programa). Registra el experimento automáticamente con objetivo explícito. Úsala DESPUÉS de proponer-campana (o con datos propios). Solo ejecuta; la propuesta la hace proponer-campana.
---

# Ejecutar campaña

Skill de EJECUCIÓN (Carlos: proponer y ejecutar son skills separados). La propuesta viene de **proponer-campana** o de datos que dé el usuario.

## Paso 0 — Pregunta el CANAL (siempre primero)
> ¿Por qué canal va la campaña?
> 1. **WhatsApp** (ManyChat) · 2. **Correo** (ManyChat) · 3. **Banner** (app/web) · 4. **Modal** (app/web) · 5. **Push** (notificación app)

## Paso 1 — Reúne los datos según canal

**Comunes:** `nombre`, `descripcion` (copy), `boton` (CTA), `objetivo` (venta/reconsumo/reactivacion/referidos/primer-pedido-foodcourt), `pais` (PE/MX/CO).

**El SEGMENTO:** si vienes de proponer-campana usa su `generar_con`. Si no:
- ManyChat → filtros de `generar-lista-manychat` (category/edad/tenure/objetivo nutricional/limit).
- Push → filtros BO: `gender` (todos/male/female), `ageStart/ageEnd`, `control_group` (%), `wallet_start/end`, `membership_start/end`.
- Banner/Modal → el segmento vive en la campaña misma; va en `filtros`: `wallet_start/end` (saldo), `membership_start/end` (nº membresía), `foodcourt_less_days` (días sin pedir), `status_foodcourt` (array).

**Extras por canal:**
- Banner/Modal/Card (en `campana`): `end` (fecha fin, YYYY-MM-DD — REQUERIDO), `link`, `promotion_id`, `time_start`/`time_end` (franja horaria), `number_view` (cant. vistas), `timer`, `type_id` (tipo de campaña), `disclaimer`, `colors`, `descripcion_secundaria`.
- ⚠️ La API del BO NO soporta (llenar manual en BO tras crear): **Ciudades, Vistas (pantallas), Audiencia, Slots, Imagen** — pedidos al chamo/Adin.
- ⚠️ BUG BO (verificado 2026-07-15, campaña 1694): el doc lista `number_view`, `wallet_start/end`, `membership_start/end`, `foodcourt_less_days`, `status_foodcourt` pero el backend NO los persiste (solo graban time_start/end y type_id). Hasta que Adin lo arregle, ese segmento se llena manual en el BO. Avisa al usuario cuando use esos filtros.
- Push: `deeplink_id` (default 8=dashboard; 5=RECONSUMO, 35=planes, 33=foodcourt), `tipo_notif` (organica/inorganica, default inorganica), y **cuándo**: enviar ya (`enviar:true`) o programar (`programar:{date,time}` — cron BO dispara entre 10:00-22:00).

## Paso 2 — Llama al endpoint
```bash
curl -s -X POST -H "x-api-key: okr-mv-2026" -H "content-type: application/json" \
  "https://data-lake-mv.manzanaverde.la/api/planner/execute" \
  -d '{
    "canal": "push",
    "pais": "PE",
    "campana": { "nombre": "Vuelve con 25 dscto", "descripcion": "Solo hoy...", "boton": "Lo quiero", "objetivo": "reactivacion", "deeplink_id": 5 },
    "filtros": { "gender": "todos", "ageStart": 25, "ageEnd": 44, "control_group": 10 },
    "programar": { "date": "2026-07-20", "time": "11:00" }
  }'
```
- ManyChat (`canal: whatsapp|correo`): responde `csv` + `plantilla` → guarda **lista.csv** y **plantilla.json**, entrégalos (igual que generar-lista-manychat).
- Banner/Modal: se crea **INACTIVA** (`status 0`). Pregunta "¿la activo?" → reenvía con `"activar": true` (o POST `/campaigns/{id}/activate`).
- Push: sin `enviar`/`programar` solo crea. **Confirma con el usuario antes de enviar** (`audience_size` viene en la respuesta).

## Paso 3 — Confirma el registro
La respuesta trae `experimento` (`exp-ce-{id}` / `exp-push-{id}`): stub creado en `experiments` con objetivo explícito, estado "En curso". Los crons de medición completan resultados solos sobre ese mismo id.

Repórtale al usuario: canal, id creado, estado (inactiva/encolada/programada), tamaño de audiencia si aplica, y el id del experimento.

## Reglas
- NUNCA actives banner/modal ni envíes push sin confirmación explícita del usuario en esta conversación.
- 422 audiencia vacía → afloja filtros (edad/wallet) y reintenta.
- `campana.end` faltante en banner/modal → pídela, no inventes fechas largas.
- Errores 401 → la key del Marketing API no está configurada en Vercel (avisar a Julio).
