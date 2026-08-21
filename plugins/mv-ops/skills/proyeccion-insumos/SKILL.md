---
description: Genera el reporte de proyección de insumos y platos para Ops y Compras - cuántos platos preparar y cuántos kilos de cada ingrediente comprar por cocina y por día, con merma, empaques y costo estimado. Entrega todo en Markdown. Usar cuando pidan "cuánto comprar", "proyección de insumos", "lista de compras", "precantidades de producción", "explosión de recetas" o "cuántos platos preparar".
---

# Proyección de Insumos y Platos

Convierte una proyección de pedidos en una **lista concreta de compras**: cuántos platos preparar por cocina y cuántos kilos de cada ingrediente se necesitan, considerando merma y empaques.

Entrega siempre **Markdown**, para que Ops y Compras lo peguen en Notion o Slack.

## Cuándo usar

- **Planificación de compras semanal** — qué pedir a proveedores
- **Antes de un feriado o campaña** — ajustar producción cuando la demanda cambia
- **Costeo previo** — estimar cuánto costará producir la semana

## Qué entrega

| Archivo | Contenido |
|---|---|
| `proyecciones/YYYY-MM-DD-insumos.md` | Reporte de insumos (entregable principal) |
| `proyecciones/YYYY-MM-DD-platos.md` | Platos a preparar por cocina y día |

Si la carpeta `proyecciones/` no existe, crearla.

---

## ⚠️ Restricción fundamental: el mix de platos NO está en los datos

El espejo de datos **no tiene ninguna tabla que enlace pedidos con platos**. Se verificó: no existen `order_details`, `order_items`, `menus`, `sale_items` ni equivalentes. `orders` solo llega hasta `catering_id` y `monto`.

**Consecuencia:** esta skill no puede adivinar qué platos se van a pedir. El **menú planificado es un input obligatorio** que aporta Ops.

Esto no es un problema en la práctica: **Ops ya planifica el menú de la semana**. La skill toma ese plan y hace el trabajo pesado (explotar recetas, consolidar insumos, calcular merma y costo).

**Nunca inventar un mix de platos.** Si el usuario no lo da, pedirlo. Si insiste en no tenerlo, decir claramente que el reporte no se puede generar y por qué.

---

## Fuente de datos

Espejo de MV en Supabase (**solo lectura**).

```bash
MV_MIRROR_URL       # https://<proyecto>.supabase.co/rest/v1
MV_MIRROR_ANON_KEY  # anon key
```

**Cómo obtenerlas:** igual que en `proyeccion-demanda` — primero las variables de entorno, y si no
están, un archivo `.env` en `./.env` → `~/Projects/.env` → `~/.env`. El bloque de carga está en la
sección *Fuente de datos* de esa skill; usar el mismo. **No pedirle las credenciales al usuario por
chat**, y nunca escribirlas en un reporte ni en la conversación.

### Tabla `meals` — el corazón de esta skill

| Campo | Uso |
|---|---|
| `meal_id`, `meal_name` | Identificación del plato |
| `full_recipe` (JSON) | **Receta completa con ingredientes** |
| `protein_type`, `is_star`, `is_active` | Filtros |
| `country`, `country_id` | Separar por país |
| `food_cost_local` | Costo por plato (moneda local) |
| `weight_gr`, `calories` | Referencia nutricional |

**Cobertura verificada (ago 2026):** 1,402 de 1,409 platos tienen receta (99.5%). En Perú, 539 de 541 platos activos (99.6%). `food_cost_local` solo está en 654 platos (46%) — para el resto hay que costear desde los ingredientes.

### Estructura de `full_recipe`

```
full_recipe
├── name, cook_minutes, presentation
└── subgroups[]                      ← "Pollo", "Verduras", "Aliño", "Empaque"
    ├── name, porcion, weight, reduction
    └── ingredients[]
        ├── NOMALIM            nombre del insumo
        ├── ingredient_id      id para consolidar
        ├── porcion            gramos NETOS por plato
        ├── merma_porcentaje   % que se pierde al limpiar/pelar
        ├── performance        rendimiento de cocción (%)
        ├── price_level        precio referencial por kg
        └── cut_name           tipo de corte
```

### ⚠️ Trampas verificadas

1. **El subgrupo `Empaque` se cuenta en UNIDADES, no gramos.** Sus ingredientes (CT5, salseros, cubiertos, servilletas, bolsa) tienen `porcion = 1` = una unidad por plato. **Nunca sumarlos como kilos.** Detectarlo por el nombre del subgrupo.

2. **`porcion` del ingrediente ya es peso crudo.** El `weight` del subgrupo es el peso *cocido*: `porcion × reduction% = weight`. Verificado: pollo 110g × 65% = 71.5g. **Para comprar se usa `porcion`, no `weight`.**

3. **La suma de ingredientes ≠ `porcion` del subgrupo.** El subgrupo reporta solo el componente principal; el resto (agua, sal, marinada) va aparte. Consolidar siempre a nivel **ingrediente**, nunca de subgrupo.

4. **`monto` de `orders` está en moneda local** — nunca mezclar países.

5. **PostgREST no permite agregaciones.** Para contar usar `Prefer: count=exact` + `Range: 0-0` y leer `Content-Range`.

---

## Proceso

### Paso 1 — Obtener la proyección de pedidos

Usar la skill `proyeccion-demanda` (pedidos esperados por día y por cocina).
Si ya existe un reporte reciente en `proyecciones/`, reutilizarlo en vez de recalcular.

### Paso 2 — Pedir el menú planificado

Preguntar a Ops, en el formato más simple posible:

> ¿Qué platos van esta semana y qué porcentaje de los pedidos esperas de cada uno?
> Ejemplo: Lunes — Pollo saltado 40%, Ensalada surimi 35%, Lomo 25%

Aceptar también un archivo o una tabla pegada. Si Ops da cantidades absolutas en vez de porcentajes, usarlas directamente.

**Validar que los porcentajes sumen ~100% por día.** Si no, avisar antes de continuar.

### Paso 3 — Calcular platos por cocina y día

```
platos(plato, cocina, día) = pedidos_proyectados(cocina, día) × participación(plato, día)
```

Redondear hacia arriba: es preferible que sobre a que falte.

### Paso 4 — Traer las recetas

```
GET {MV_MIRROR_URL}/meals?select=meal_id,meal_name,full_recipe,food_cost_local&meal_id=in.(...)
```

Si un plato no tiene `full_recipe`, **no estimarlo**: listarlo en la sección de alertas como "sin receta cargada" y excluirlo del consolidado.

### Paso 5 — Explotar a ingredientes

Para cada ingrediente de cada plato:

```
cantidad_neta(g)  = porcion × n_platos
cantidad_compra(g) = cantidad_neta / (1 - merma_porcentaje/100)
```

**Los empaques van aparte, en unidades:**
```
unidades = porcion × n_platos      # subgrupo "Empaque"
```

> ⚠️ **Validar la fórmula de merma con el Chef antes del primer uso real.**
> Se usa la convención culinaria estándar (dividir por `1 - merma`), que asume que
> `porcion` es peso neto aprovechable. La otra convención posible sería multiplicar
> por `1 + merma`. En un insumo con 25% de merma la diferencia es ~7% de la compra.
> Dejar anotado en el reporte qué convención se usó.

### Paso 6 — Consolidar

Agrupar por `ingredient_id` (no por `NOMALIM`, que puede tener variantes de escritura).
Sumar por cocina y por día. Convertir a **kilogramos** cuando supere 1,000 g.

### Paso 7 — Estimar el costo

Preferir `food_cost_local × n_platos` cuando el plato lo tenga (más confiable).
Si falta, sumar `cantidad_compra_kg × price_level` de cada ingrediente y marcarlo como **estimado**.

**Nunca sumar costos de distintos países.**

### Paso 8 — Generar los reportes

Escribir los dos `.md` con las plantillas de abajo.

---

## Plantilla — Reporte de insumos

Escribir en `proyecciones/YYYY-MM-DD-insumos.md`:

````markdown
# Proyección de Insumos — {País}
**Semana:** {lunes} al {domingo}
**Generado:** {fecha}

## Resumen

Para **{TOTAL} pedidos** proyectados se necesitan **{N} insumos distintos**,
con un costo estimado de **{MONEDA} {MONTO}**.

{Una línea de contexto: feriados, cambios de menú, cocinas fuera de servicio.}

## Insumos a comprar — consolidado

| Insumo | Cantidad | Unidad | Costo estimado |
|--------|---------:|--------|---------------:|
| Pechuga de pollo fresca | 145.8 | kg | S/ 2,752 |
| Lechuga americana | 62.3 | kg | S/ 311 |
| ... | | | |
| **Total** | | | **S/ 12,480** |

## Desglose por cocina

### {Nombre de cocina} — {ciudad}

| Insumo | Cantidad | Unidad |
|--------|---------:|--------|
| ... | | |

## Empaques y descartables

| Artículo | Cantidad | Unidad |
|----------|---------:|--------|
| CT5 | 3,540 | unidades |
| Kit de cubiertos | 3,540 | unidades |
| ... | | |

## ⚠️ Alertas

- {Platos sin receta cargada — excluidos del cálculo}
- {Insumos con merma alta (>30%) donde conviene revisar el proveedor}
- {Cambios fuertes vs. la semana pasada}

*(Si no hay alertas: "Sin alertas para esta semana.")*

## Supuestos usados

- Pedidos proyectados: {fuente y fecha}
- Mix de platos: {quién lo entregó y cuándo}
- Merma: convención "dividir por (1 − merma)" — {validada / pendiente de validar} con Chef
- Costos: {N} platos con costo oficial, {M} estimados desde ingredientes
````

## Plantilla — Reporte de platos

Escribir en `proyecciones/YYYY-MM-DD-platos.md`:

````markdown
# Platos a Preparar — {País}
**Semana:** {lunes} al {domingo}

## Total por día

| Día | Fecha | Platos | Nota |
|-----|-------|-------:|------|
| Lunes | 10 ago | 650 | |
| Domingo | 16 ago | 0 | Sin producción |
| **Total** | | **3,540** | |

## Detalle por cocina y plato

### {Nombre de cocina}

| Plato | Lun | Mar | Mié | Jue | Vie | Sáb | Total |
|-------|----:|----:|----:|----:|----:|----:|------:|
| Pollo saltado | 120 | 140 | 138 | 134 | 118 | 38 | 688 |
| ... | | | | | | | |
````

### Reglas de los reportes

1. **Escribir para Ops y Compras, no para técnicos.** Sin nombres de tablas, sin JSON, sin SQL.
2. **Kilos con 1 decimal, unidades enteras.** Nadie compra 145.8347 kg.
3. **Redondear platos hacia arriba.** Que sobre, no que falte.
4. **Toda alerta debe decir qué hacer**, no solo qué pasó.
5. **Siempre incluir la sección de supuestos.** Si alguien cuestiona un número, debe poder rastrear de dónde salió.
6. **Nunca inventar un dato faltante.** Marcarlo como "sin datos" y explicarlo.

---

## Limitaciones conocidas

Mencionarlas en el reporte cuando apliquen:

1. **El mix de platos es un supuesto de Ops, no un dato histórico.** El espejo no enlaza pedidos con platos, así que la precisión del reporte depende de qué tan bueno sea el plan de menú. Si Ops se equivoca en el mix, los insumos se equivocan proporcionalmente.

2. **No hay rendimiento histórico por cocina.** El espejo solo trae `stores.catering_level` como foto actual, sin histórico semanal. Las mermas usadas son las **estándar de la receta**, iguales para todas las cocinas. Si una cocina tiene merma sistemáticamente distinta, este reporte no lo captura — eso vive en la BD MySQL de producción y requiere VPN.

3. **`price_level` es un precio referencial de la receta**, no el precio de compra vigente. Los costos son estimaciones de orden de magnitud, no cotizaciones.

4. **No considera inventario existente.** El reporte dice cuánto se necesita, no cuánto hay que comprar descontando stock. Ops debe restar lo que ya tiene en cámara.

5. **No considera promociones ni campañas.** Si Marketing lanza algo, el mix real puede desviarse mucho.

---

## Después de entregar

1. Decir dónde quedaron los archivos y **resumir en una línea** lo principal (total de platos y costo estimado).
2. Recordar que son `.md` — se pegan directo en Notion o Slack.
3. Si algún plato quedó sin receta o el mix no sumaba 100%, **decirlo explícitamente** en vez de entregar los números sin contexto.
