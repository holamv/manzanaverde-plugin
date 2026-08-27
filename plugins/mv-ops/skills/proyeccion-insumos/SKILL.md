---
description: Genera el reporte de proyección de insumos y platos para Ops y Compras - cuántos platos preparar y cuántos kilos de cada ingrediente comprar por cocina y por día, derivado del histórico real de ventas por plato, con merma, empaques y costo estimado. Entrega todo en Markdown. Usar cuando pidan "cuánto comprar", "proyección de insumos", "lista de compras", "precantidades de producción", "cuántos platos preparar" o "explosión de recetas".
---

# Proyección de Insumos y Platos

Proyecta **cuántos platos preparar por cocina y por día** a partir del histórico real de ventas
por plato, y los convierte en una **lista concreta de compras**: kilos por ingrediente, empaques y
costo estimado.

Entrega siempre **Markdown**, para que Ops y Compras lo peguen en Notion o Slack.

## Cuándo usar

- **Planificación de producción y compras semanal** — cuántos platos y qué pedir a proveedores
- **Antes de un feriado o campaña** — ajustar producción cuando la demanda cambia
- **Costeo previo** — estimar cuánto costará producir la semana

## Qué entrega

| Archivo | Contenido |
|---|---|
| `proyecciones/YYYY-MM-DD-platos.md` | Platos a preparar por cocina y día |
| `proyecciones/YYYY-MM-DD-insumos.md` | Insumos a comprar (entregable de Compras) |

Si la carpeta `proyecciones/` no existe, crearla.

---

## Fuente de datos

Espejo de MV en Supabase (**solo lectura**). Es el proyecto del **data lake**.

```bash
MV_MIRROR_URL       # https://<proyecto>.supabase.co/rest/v1
MV_MIRROR_ANON_KEY  # anon key
```

**Cómo obtenerlas:** igual que en `proyeccion-demanda` — primero las variables de entorno, y si no
están, un archivo `.env` en `./.env` → `~/Projects/.env` → `~/.env`. El bloque de carga está en la
sección *Fuente de datos* de esa skill; usar el mismo. **No pedirle las credenciales al usuario por
chat**, y nunca escribirlas en un reporte ni en la conversación.

### Las cinco tablas que usa esta skill

| Tabla | Grano | Para qué |
|---|---|---|
| `meal_orders_daily` | `order_date` × `meal_id` × `store_id` | **Ventas reales por plato.** `unidades` = platos vendidos. Es el histórico que manda. |
| `daily_menu` | `date` × `branch_office_id` × `meal_id` × `meal_type` | Qué platos van (o fueron) cada día, por sede |
| `catering_daily_metrics` | `catering_id` × `day_date` | Rendimiento de cocina: `orders`, `rating_average` |
| `meals` | `meal_id` | Catálogo + `full_recipe` (JSON) + `food_cost_local` |
| `meal_feedbacks` | `meal_id` × `branch_office_id` | Calificación del plato (0-5) |

### ⚠️ El cruce de llaves que hay que hacer bien

Las tablas **no comparten la misma llave de cocina**. Es el error más fácil de cometer:

```
meal_orders_daily.store_id      = stores.store_id      (una cocina / catering)
catering_daily_metrics.catering_id = stores.store_id   (misma llave)
daily_menu.branch_office_id     = stores.branch_office_id   ← ¡SEDE, no cocina!
meal_feedbacks.branch_office_id = stores.branch_office_id   ← ¡SEDE, no cocina!
```

Una sede tiene **varias cocinas**. El menú y la calificación del plato viven a nivel sede, así que
son iguales para todas las cocinas de esa sede. Traer `stores` primero y armar el mapa
`store_id → branch_office_id` antes de cualquier otra consulta.

---

## De dónde sale el mix de platos

**Del histórico, no de un supuesto.** Para cada plato se calcula qué proporción de los platos de esa
cocina se lleva, contando **solo los días en que ese plato estuvo en el menú** de su sede:

```
participacion(plato, cocina, díaSemana) =
      unidades(plato, cocina)  ÷  platos_totales(cocina)
      ... sobre los días en que el plato estuvo en `daily_menu` de esa sede
```

Dividir sobre los días de exposición y no sobre todos los días es lo que hace comparable a un plato
que va todas las semanas con uno que va una vez al mes. Sin ese filtro, todo plato ocasional se
proyecta bajísimo.

Usar **mediana de las últimas 12 semanas** por día de semana, y **excluir feriados** de la ventana
antes de calcular (mismo criterio que `proyeccion-demanda`, por la misma razón: en Colombia 8 de
26 lunes son festivos y arrastran la mediana).

> **Dos ventanas distintas, a propósito.** El **volumen** total por cocina usa **26 semanas**, la
> misma que `proyeccion-demanda`, para que las dos skills no se contradigan. La **participación de
> cada plato** usa **12 semanas**, porque la carta rota: un mix de hace seis meses ya no describe lo
> que se pide hoy. Si se usara la misma ventana para las dos cosas, o el volumen se vuelve
> inestable, o el mix queda viejo.

### Platos sin histórico

Un plato nuevo no tiene participación propia. **No inventarle una.** Usar la mediana de
participación de los platos del mismo `protein_type` en esa cocina, y **marcarlo en el reporte
como estimado por familia**. Si tampoco hay platos de esa familia, decir que no se puede proyectar
y pedir el dato a Ops para ese plato puntual.

---

## Rendimiento histórico de cocinas — qué se puede y qué no

`catering_daily_metrics` trae cuatro columnas, pero **solo dos tienen datos**:

| Columna | Estado | Uso permitido |
|---|---|---|
| `orders` | Poblada | Contraste de volumen: validar la proyección |
| `rating_average` | Poblada | Alerta de calidad |
| `incident_ratio` | **NULL a propósito** | Ninguno |
| `percentage_late_routes` | **NULL a propósito** | Ninguno |

Las dos últimas están vacías por decisión explícita de quien construyó la tabla: reconstruirlas dio
números que no calzaban con el histórico real y no las poblaron con un valor adivinado. **No
rellenarlas ni derivarlas.**

**El rendimiento de cocina entra como contraste y alerta, NO como multiplicador.** Es decir:

- **Sí:** contrastar el total proyectado por cocina contra `orders` de las últimas semanas, y avisar
  si se despega más de 15%.
- **Sí:** marcar en el reporte las cocinas con `rating_average` en caída sostenida, para que Ops
  decida.
- **No:** multiplicar la proyección por un factor derivado del rating. No hay ninguna elasticidad
  medida entre calificación y volumen en estos datos. Inventar el factor mueve los kilos de compra
  con un número que nadie validó.

Si alguien pide que el rating ajuste la proyección, lo que hace falta primero es medir esa relación
sobre el histórico y escribirla acá. Hasta entonces, contraste y alerta.

---

## ⚠️ Trampas verificadas

1. **El subgrupo `Empaque` se cuenta en UNIDADES, no gramos.** Sus ingredientes (CT5, salseros,
   cubiertos, servilletas, bolsa) tienen `porcion = 1` = una unidad por plato. **Nunca sumarlos como
   kilos.** Detectarlo por el nombre del subgrupo.

2. **`porcion` del ingrediente ya es peso crudo.** El `weight` del subgrupo es el peso *cocido*:
   `porcion × reduction% = weight`. Verificado: pollo 110g × 65% = 71.5g. **Para comprar se usa
   `porcion`, no `weight`.**

3. **La suma de ingredientes ≠ `porcion` del subgrupo.** El subgrupo reporta solo el componente
   principal; el resto (agua, sal, marinada) va aparte. Consolidar siempre a nivel **ingrediente**,
   nunca de subgrupo.

4. **`daily_menu` no trae la receta.** Está así a propósito: duplicar el JSON de receta por fila
   reventaba el tiempo de consulta. Hacer **un lookup a `meals.full_recipe` por `meal_id`**.

5. **`meal_feedbacks` es por sede, no por cocina.** No se puede afirmar "este plato sale mal en la
   cocina X". Si el reporte lo insinúa, está mintiendo.

6. **Nunca mezclar países.** `food_cost_local` está en moneda local y `country_id` es 1=PE, 2=MX,
   3=CO.

7. **PostgREST no permite agregaciones.** Para contar usar `Prefer: count=exact` + `Range: 0-0` y
   leer `Content-Range`. Para sumar `unidades`, traer las filas y sumar en memoria: el grano diario
   por plato y cocina es chico.

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

---

## Proceso

### Paso 1 — Alcance y mapa de cocinas

Preguntar solo si no está claro: **país** (por defecto Perú) y **semanas a proyectar** (por
defecto 1).

```
GET {MV_MIRROR_URL}/stores?select=store_id,store_name,city,branch_office_id,catering_level,is_active,country_id
```

Guardar el mapa `store_id → branch_office_id`. Incluir las inactivas para el histórico.

### Paso 2 — Traer el histórico de ventas por plato (26 semanas)

```
GET {MV_MIRROR_URL}/meal_orders_daily?select=order_date,meal_id,store_id,unidades
    &order_date=gte.{hace 26 semanas}&store_id=in.({ids del país})
```

Y los días de exposición de cada plato, en la misma ventana:

```
GET {MV_MIRROR_URL}/daily_menu?select=date,branch_office_id,meal_id
    &date=gte.{hace 26 semanas}&branch_office_id=in.({sedes del país})
```

De esas 26 semanas, el **volumen** usa todas y la **participación por plato** solo las **últimas
12** (ver arriba por qué). Paginar si hace falta: `Range` en cabecera, no `limit` en el query.

**Si `meal_orders_daily` viene vacía o con menos de 4 semanas**, parar: decir que el histórico no
alcanza para proyectar y no entregar números. No caer en un supuesto silencioso.

### Paso 3 — Proyectar los platos totales por cocina y día

Mismo método que `proyeccion-demanda`, pero sobre **platos** en vez de pedidos: mediana por día de
semana de las últimas 26 semanas, excluyendo feriados, por cocina.

```
platos_totales(cocina, día) = mediana( Σ unidades(cocina, fecha) )   por día de semana, sin feriados
```

Aplicar los mismos factores de `proyeccion-demanda`: `0.25` en feriado nacional, `0.60` en día
puente, y el ajuste de tendencia de las últimas 4 semanas sin feriados.

**Contrastar contra `catering_daily_metrics.orders`** de esas mismas semanas. Un plato por pedido no
es la relación real (un pedido puede llevar varios platos), así que lo que se compara es la
*estabilidad de la razón* platos/pedidos, no los valores. Si esa razón se movió más de 15% respecto
al histórico, avisarlo como alerta.

### Paso 4 — Saber qué platos van esta semana

```
GET {MV_MIRROR_URL}/daily_menu?select=date,branch_office_id,meal_id,meal_type
    &date=gte.{lunes}&date=lte.{domingo}
```

- **Si viene cargada:** usarla. La skill no pregunta nada.
- **Si viene vacía** (el menú aún no se publicó): pedirle a Ops solo **qué platos van cada día** —
  no los porcentajes. La participación la calcula la skill del histórico. Decirlo así:

  > El menú de esa semana todavía no está cargado. Pasame solo qué platos van cada día y yo saco
  > las cantidades del histórico.

### Paso 5 — Repartir entre los platos del día

```
platos(plato, cocina, día) = platos_totales(cocina, día) × participacion_normalizada(plato, cocina, díaSemana)
```

Normalizar las participaciones de los platos de ese día para que sumen 1. Redondear **hacia
arriba**: es preferible que sobre a que falte.

### Paso 6 — Traer las recetas

```
GET {MV_MIRROR_URL}/meals?select=meal_id,meal_name,protein_type,full_recipe,food_cost_local&meal_id=in.(...)
```

Si un plato no tiene `full_recipe`, **no estimarlo**: listarlo en alertas como "sin receta cargada"
y excluirlo del consolidado de insumos (pero dejarlo en el reporte de platos).

### Paso 7 — Explotar a ingredientes

```
cantidad_neta(g)   = porcion × n_platos
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

### Paso 8 — Consolidar

Agrupar por `ingredient_id` (no por `NOMALIM`, que tiene variantes de escritura). Sumar por cocina
y por día. Convertir a **kilogramos** cuando supere 1,000 g.

### Paso 9 — Estimar el costo

Preferir `food_cost_local × n_platos` cuando el plato lo tenga (más confiable). Si falta, sumar
`cantidad_compra_kg × price_level` de cada ingrediente y marcarlo como **estimado**.

**Nunca sumar costos de distintos países.**

### Paso 10 — Generar los reportes

Escribir los dos `.md` con las plantillas de abajo.

---

## Plantilla — Reporte de platos

Escribir en `proyecciones/YYYY-MM-DD-platos.md`:

````markdown
# Platos a Preparar — {País}
**Semana:** {lunes} al {domingo}
**Generado:** {fecha}

## Total por día

| Día | Fecha | Platos | Nota |
|-----|-------|-------:|------|
| Lunes | 10 ago | 650 | |
| Domingo | 16 ago | 0 | Sin producción |
| **Total** | | **3,540** | |

## Detalle por cocina y plato

### {Nombre de cocina}

| Plato | Lun | Mar | Mié | Jue | Vie | Sáb | Total | Base |
|-------|----:|----:|----:|----:|----:|----:|------:|------|
| Pollo saltado | 120 | 140 | 138 | 134 | 118 | 38 | 688 | histórico |
| Lomo nuevo | 40 | — | — | 44 | — | — | 84 | estimado por familia |

La columna **Base** dice de dónde salió la cantidad: `histórico` (ventas reales del plato) o
`estimado por familia` (plato nuevo, se usó el promedio de su tipo de proteína).

## Contraste con el histórico de cocinas

| Cocina | Platos proyectados | Pedidos histórico | Razón platos/pedido | Estado |
|--------|------------------:|-----------------:|--------------------:|--------|
| {Cocina} | 688 | 512 | 1.34 | normal |
| {Cocina} | 402 | 180 | 2.23 | ⚠ revisar |
````

## Plantilla — Reporte de insumos

Escribir en `proyecciones/YYYY-MM-DD-insumos.md`:

````markdown
# Proyección de Insumos — {País}
**Semana:** {lunes} al {domingo}
**Generado:** {fecha}

## Resumen

Para **{N} platos** proyectados se necesitan **{M} insumos distintos**,
con un costo estimado de **{MONEDA} {MONTO}**.

{Una línea de contexto: feriados, cambios de menú, cocinas fuera de servicio.}

## Insumos a comprar — consolidado

| Insumo | Cantidad | Unidad | Costo estimado |
|--------|---------:|--------|---------------:|
| Pechuga de pollo fresca | 145.8 | kg | S/ 2,752 |
| Lechuga americana | 62.3 | kg | S/ 311 |
| **Total** | | | **S/ 12,480** |

## Desglose por cocina

### {Nombre de cocina} — {ciudad}

| Insumo | Cantidad | Unidad |
|--------|---------:|--------|

## Empaques y descartables

| Artículo | Cantidad | Unidad |
|----------|---------:|--------|
| CT5 | 3,540 | unidades |

## ⚠️ Alertas

- {Platos sin receta cargada — excluidos del cálculo de insumos}
- {Platos nuevos estimados por familia — cuántos y cuánto peso representan}
- {Cocinas cuya razón platos/pedido se movió >15%}
- {Cocinas con calificación en caída sostenida}
- {Insumos con merma alta (>30%) donde conviene revisar el proveedor}

*(Si no hay alertas: "Sin alertas para esta semana.")*

## Supuestos usados

- Ventas históricas: {N} semanas de `meal_orders_daily`, hasta {fecha}
- Menú de la semana: {leído del sistema / entregado por Ops el {fecha}}
- Participación por plato: mediana por día de semana, feriados excluidos
- Platos nuevos: {N} estimados por tipo de proteína
- Merma: convención "dividir por (1 − merma)" — {validada / pendiente de validar} con Chef
- Costos: {N} platos con costo oficial, {M} estimados desde ingredientes
````

### Reglas de los reportes

1. **Escribir para Ops y Compras, no para técnicos.** Sin nombres de tablas, sin JSON, sin SQL.
2. **Kilos con 1 decimal, unidades enteras.** Nadie compra 145.8347 kg.
3. **Redondear platos hacia arriba.** Que sobre, no que falte.
4. **Toda alerta debe decir qué hacer**, no solo qué pasó.
5. **Siempre incluir la sección de supuestos.** Si alguien cuestiona un número, debe poder
   rastrear de dónde salió.
6. **Nunca inventar un dato faltante.** Marcarlo como "sin datos" y explicarlo.
7. **Decir siempre de dónde salió cada cantidad** — la columna `Base` no es opcional.

---

## Limitaciones conocidas

Mencionarlas en el reporte cuando apliquen:

1. **La frecuencia que usa esta skill es por plato, no por cliente.** Es decir: cuántas veces se
   ofrece un plato y cuánto vende cuando se ofrece. Eso es lo que reparte el volumen entre los
   platos del día, y es lo correcto para el mix.
   La frecuencia **por cliente** (cada cuántos días vuelve a pedir una persona) es computable —
   `orders.customer_id` cruzado con `customers.plan_actual` — pero pertenece a la proyección de
   **volumen**, no a la del mix: cambia cuántos platos salen en total, no cuál se lleva cada uno.
   Ese trabajo va en `proyeccion-demanda`. Hoy esa skill todavía no la usa.

2. **El rendimiento de cocina es parcial.** De `catering_daily_metrics` solo sirven `orders` y
   `rating_average`; el ratio de incidencias y el porcentaje de rutas tardías están vacíos a
   propósito. Y la merma usada es la **estándar de la receta**, igual para todas las cocinas: si una
   cocina tiene merma sistemáticamente distinta, este reporte no lo captura.

3. **La calificación del plato es por sede, no por cocina.** No se puede atribuir un plato mal
   calificado a una cocina puntual.

4. **`price_level` es un precio referencial de la receta**, no el precio de compra vigente. Los
   costos son estimaciones de orden de magnitud, no cotizaciones.

5. **No considera inventario existente.** El reporte dice cuánto se necesita, no cuánto hay que
   comprar descontando stock. Ops debe restar lo que ya tiene en cámara.

6. **No considera promociones ni campañas.** Si Marketing lanza algo grande, el mix real puede
   desviarse mucho. Preguntarles antes de una semana clave.

---

## Después de entregar

1. Decir dónde quedaron los archivos y **resumir en una línea** lo principal (total de platos y
   costo estimado).
2. Recordar que son `.md` — se pegan directo en Notion o Slack.
3. Si hubo platos sin receta, platos estimados por familia, o cocinas con contraste fuera de rango,
   **decirlo explícitamente** en vez de entregar los números sin contexto.
