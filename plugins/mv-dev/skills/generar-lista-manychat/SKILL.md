---
name: generar-lista-manychat
description: Genera los insumos listos para ManyChat — lista CSV (opt-in, dedup, anti-repetición), plantilla JSON con el campo `boton` (CTA), y hora sugerida. Úsala para armar el envío de una campaña de WhatsApp/Correo a partir de filtros de público (o del resultado de proponer-campana).
---

# Generar insumos ManyChat

Cuando el usuario quiera armar/enviar una campaña de ManyChat (o tras usar **proponer-campana**):

1. Reúne:
   - **filtros de público**: `category` (1-5, persona) o `edad_min`/`edad_max`, `tenure_min_meses`, `pais`, `objetivo` (=objetivo NUTRICIONAL bajar/mantener/aumentar), `limit`. (Si vienes de proponer-campana, usa su `generar_con` — **pero `generar_con.objetivo_campana` va en `campana.objetivo`, NO en filtros**.)
   - **campaña**: `nombre`, `descripcion`, `boton` (CTA principal), `boton2`/`boton3` (CTA extra opcionales — un mensaje puede tener varios botones), `hora`, `objetivo` (=objetivo de CAMPAÑA: venta/reconsumo/reactivacion/referidos/primer-pedido-foodcourt). El objetivo se escribe EXPLÍCITO en el JSON (`objetivo_campana`) para no inferirlo.

2. Llama al endpoint:
   ```bash
   curl -s -X POST -H "x-api-key: okr-mv-2026" -H "content-type: application/json" \
     "https://data-lake-mv.manzanaverde.la/api/planner/manychat-list" \
     -d '{
       "filtros": { "category": 3, "pais": "PE", "limit": 1637 },
       "campana": { "nombre": "promo rc 200 dscto", "descripcion": "PROMO EXPRESS: $200 de descuento...", "boton": "Quiero mi descuento", "hora": "15:00", "objetivo": "reconsumo" }
     }'
   ```

3. De la respuesta:
   - Guarda `csv` en un archivo **lista.csv** (columnas: Telefono,Nombre,Pais).
   - Guarda `plantilla` en **plantilla.json** — este es el cuerpo a pegar en ManyChat (incluye `boton`, `objetivo_campana` y el merge-tag `{{subscriber_data|to_json:true}}` literal). ManyChat debe tener mapeada la columna `objetivo_campana` en la Sheet (igual que `Call To Action`).
   - Muestra `count` (cuántos entraron) y `hora_sugerida`.

4. Entrega a Carolina: "Pega `plantilla.json` como cuerpo de la campaña en ManyChat y sube `lista.csv` como audiencia. Hora sugerida: {hora}."

Notas:
- La lista ya viene **opt-in only**, dedup por teléfono y **sin los contactados <7d / convertidos <30d** (anti-repetición vía `contact_history`).
- `anti_repeticion: false` en filtros lo desactiva si necesitas toda la base.
- Si `count` es bajo, es porque el público quedó chico tras filtros + anti-repetición; amplía edad/tenure o quita anti-repetición.
