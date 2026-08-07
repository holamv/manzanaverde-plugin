---
name: proponer-campana
description: Propone una campaña COMPLETA a partir de inputs simples (género + tema). Devuelve público óptimo, volumen, horario por país, ratio +20%, Y redacta el copy sugerido (nombre, descripción, botón/CTA) inspirado en campañas pasadas que mejor convirtieron. Úsala cuando quieran planear una campaña desde cero.
---

# Proponer campaña (con copy sugerido)

## Paso 0 — Inputs simples (pídelos si faltan)
- **género**: `hombre` | `mujer` | `ambos`
- **tema**: texto libre (ej. "mundial", "nuevos clientes", "motivar pedidos en la carta", "reactivación")
- Opcionales (con defaults): **meta** (100), **canal** (`whatsapp`|`correo`|`modal`|`banner`|`push`), **pais** (`PE`|`CO`|`MX`), **objetivo** (venta/reconsumo/reactivacion/referidos/primer-pedido-foodcourt…).
- Soporta los 5 formatos: WhatsApp, Correo (ManyChat) + Banner, Modal, Push (backoffice). Para banner/modal/push devuelve además prompt de imagen.

## Paso 1 — Llamar al endpoint
> ⚠️ Auth: requiere env var `MV_BRAIN_TOKEN`. Si no está definida, DETENTE y pide al usuario solicitar su token a BizOps (Julio). Sin fallback.
```bash
curl -s -H "x-api-key: $MV_BRAIN_TOKEN" \
  "https://data-lake-mv.manzanaverde.la/api/planner/propose?meta=300&canal=modal&pais=PE&genero=hombre&tema=mundial&objetivo=reactivacion"
```
Canales válidos: `whatsapp`, `correo`, `banner`, `modal`, `push`. Si mandas `canal=banner|modal|push`, la respuesta trae `imagen_sugerida.prompt` (prompt listo para generar la imagen).

## Paso 2 — Redactar el copy (TÚ, con base en los datos)
Con `ejemplos_copy` (campañas pasadas top por conversión) + `tema` + `publico_sugerido.persona` + país, **escribe**:
- **nombre**: corto, estilo de los ejemplos que mejor convirtieron.
- **descripcion**: 1-2 frases, mensaje de WhatsApp/push, tono MV (saludable, cercano), enganchado al **tema**. Ej. tema "mundial" → "Vive el mundial comiendo rico y saludable 🍏⚽".
- **botones** (CTA): redacta TANTOS como diga `cta_insights.botones_recomendados` (1-3). Usa `cta_insights.top_ctas` (click_rate + conversión dado click histórico) como inspiración del texto y `cta_insights.razon` para explicar por qué 1 o varios. Imperativo corto (ej. "Quiero mi descuento", "Empezar hoy"). Si recomiendas 2-3, el principal va en `boton`, los extra en `boton2`/`boton3`.
Respeta el tema y la persona; usa los ejemplos como referencia de estilo, NO los copies literal.

## Paso 3 — Presentar la propuesta completa
- **Público**: `publico_sugerido.persona` + razón · `persona_prioridad_analisis` · `nota_pais`
- **Baseline → Target**: `baseline_pct`% → `target_pct`% (+20%)
- **Volumen**: `volumen_necesario.al_baseline` · **Alcanzable**: `alcanzable` (si `factible=false`, muestra `nota`)
- **Horario (país)**: `horario_recomendado` (día · semana · franjas) · hora dato-vivo `hora_sugerida`
- **Copy propuesto**: nombre · descripción · botón (los que escribiste)
- **Imagen** (solo banner/modal/push): si `imagen_sugerida.requiere_imagen`, muestra `imagen_sugerida.prompt` para que genere la imagen.

## Paso 4 — Ofrecer ejecutar
"¿La ejecuto?" → usa **ejecutar-campana** (pregunta el canal y ejecuta: ManyChat → insumos; Banner/Modal/Push → crea en backoffice). Pásale `generar_con` (category, pais, limit, **objetivo_campana**) + el copy propuesto (nombre, descripcion, boton) + la hora. `objetivo_campana` va al campo `campana.objetivo` (NO a filtros). Para solo la lista ManyChat sirve también **generar-lista-manychat**.

Notas:
- Persona = edad×género: cat_1=25-34 mujer, cat_2=25-34 hombre, cat_3=35-44 mujer, cat_4=35-44 hombre, cat_5=Otros.
- Baseline real de `experiment_segments_best`; target +20%. Anti-repetición ya aplicada en alcanzable/lista.
- `ok=false` → sin baseline para ese canal/género: prueba `genero=ambos`, otro canal, o `&minc=50`.
