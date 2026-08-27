# Changelog — mv-ops

## [1.6.2] - 2026-08-27

Se corrio contra el espejo comparando con el metodo que Ops usa de verdad: reales de la semana
pasada -> precantidades de esta. Eso hizo medible el resultado, y lo medido no es bueno.

### Fixed
- **El Paso 3 contaba pedidos anulados.** Armaba la serie historica con 182 requests —uno por dia—
  contando filas de `orders` con `Prefer: count=exact`, sin filtrar el estado. Los estados son
  1 ingresado, 2 **anular**, 3 en camino, 4 **facturado**, 5 devuelto
  (`src/mixins/OrdersMixins.js` del BackOffice). Medido en las 7 cocinas de Lima: 712/688,
  790/748, 781/738, 810/767 — un **5.5% de inflacion sistematica** en la linea base, sobre la que
  despues se aplican la tendencia y el margen. Ahora la serie sale de
  `catering_daily_metrics.orders`, que cuenta solo facturados: **un request en vez de 182**, y
  viene desagregada por cocina. Verificado que `orders` + `status_id=neq.2` da 738 el 25-ago,
  exactamente lo mismo.
- **El Paso 7 repartia el total por participacion historica**, o sea suponiendo que todas las
  cocinas se mueven juntas. No se mueven: el 25-ago Los Olivos - Mercurio vino **+30%** sobre su
  precantidad y Miraflores - Arica **-20%**, el mismo dia. Ahora cada cocina se proyecta sobre su
  propia serie. Se conserva el reparto proporcional solo para una cocina con menos de 4 semanas de
  historia propia, y marcado en el reporte.

### Added
- **El reporte mide su propio error, y contra una referencia.** La seccion de acierto comparaba la
  proyeccion de la skill contra el real. Ahora van tres columnas: proyeccion, **precantidad que Ops
  uso de verdad** (el numero que costo plata), y **el mismo dia de la semana anterior sin ajuste**.
  Con una sola columna no se distingue "el modelo es bueno" de "esta semana fue facil". Medido en la
  semana 35 de Lima, el ajuste **pierde** contra no hacer nada: 8.5% de error contra 3.5%.
- **Freno nuevo en el Paso 9:** si el metodo erra mas que el predictor de referencia, se dice en
  Alertas con las dos cifras. No bloquea la entrega, pero no puede quedar callado.
- **Diagnostico de tabla atrasada en `proyeccion-insumos`.** El contraste platos/pedidos ya existia
  y estaba bien planteado, pero diagnosticaba mal. La razon es estable (1.68, 1.70, 1.74, 1.68) y se
  desploma a 0.74 el 25-ago y 0.41 el 26 porque `meal_orders_daily` dejo de cargarse mientras
  `catering_daily_metrics` siguio normal. Un cambio real de demanda mueve las dos series juntas;
  que caiga una sola es una falla de carga. Se agregan los tres casos, que hacer en cada uno, y
  revisar la ultima fecha de cada tabla antes de calcular nada.

### Changed
- La ventana historica **ya no se declara como 26 semanas por inercia**.
  `catering_daily_metrics` arranca el 2026-04-16 (~19 semanas): el reporte informa la ventana real
  usada, y queda documentada la vuelta a `orders` —que arranca en 2018— para cuando hagan falta mas,
  siempre CON el filtro de estado.
- El registro historico pasa de 4 columnas a 8, para poder ver si el metodo se degrada o si
  simplemente nunca le gano a la referencia.
- La redaccion sobre el margen: un colchon deliberado es legitimo (quedarse corto cuesta mas que
  sobrar). Lo que no es legitimo es que este horneado en la formula sin que nadie lo haya elegido.

### Pendiente, fuera de esta skill
- **`meal_orders_daily` sigue cortada** desde el 2026-08-25. Es del datalake
  (`scripts/backfill-menudiario-platos.mjs`), no de aca.
- Las precantidades **ya son un modulo del BackOffice** (`src/views/precantidades/`,
  `GET prequantities/get_prequantities_matrix?date=`). Falta saber si la hoja de calculo de Ops
  alimenta ese modulo o corre en paralelo — si es lo segundo, hay dos verdades sobre la misma semana.

## [1.6.1] - 2026-08-24


Primera version validada contra los datos reales del espejo. La 1.6.0 corrigio el metodo pero nunca
se corrio: era un documento de instrucciones sin comprobar. Esto es lo que apareció al ejecutarlo.

### Fixed
- **El factor de feriado contradecia a las tablas medidas.** `proyeccion-demanda` fijaba
  `factor_feriado = 0.25` en el Paso 5, pero sus propias tablas de calendario —medidas en la 1.3.0—
  dicen 0.30 en Peru y Colombia y 0.45 en Mexico. Seguir el 0.25 al pie de la letra subestimaba la
  demanda de un feriado mexicano en un 44%. `proyeccion-insumos` copiaba el mismo 0.25. Ahora las
  dos apuntan al calendario por pais como fuente de verdad.
- **El guard del Paso 6b vigilaba la columna equivocada.** El paso de frecuencia se omitia si
  `customers` venia vacia o `customer_id` nulo. Ninguna de las dos cosas pasa: la tabla tiene
  708.910 filas y `customer_id` esta al 100%. Lo que si esta vacio, en las 708.910 filas, es
  `plan_actual` — la columna con la que la skill prometia abrir por tipo de plan. El guard nunca se
  disparaba y el paso intentaba una segmentacion imposible. Se corrigio el guard, se elimino la
  promesa de apertura por plan, y la contradiccion interna entre las lineas 221 y 517 quedo resuelta
  a favor de la 517, que era la que tenia razon.

### Added
- **Minimo de dias de exposicion por plato.** El divisor de exposicion no tenia piso: un plato con
  un solo dia extrapolaba su tasa semanal desde una unica observacion. Medido: ocho platos de un dia
  saltaron unos 275 puestos en el ranking de compra. Ahora hay tramos declarados en la columna
  `Base` — 3+ dias usa historia propia, 2 dias la usa marcada como delgada, 1 dia o ningun dia caen
  a la mediana de su `protein_type`, y lo que no tiene familia no se proyecta.
- Reparto real de las unidades por tramo, para que se sepa cuanto del reporte descansa en historia
  propia: 68.5% con 3+ dias, 13.2% con 2, 11.2% con 1, y 7.1% de platos que no estan en
  `daily_menu`. Alrededor de un 18% se proyecta por familia.

### Changed
- README: se dejo de prometer que la skill "solo pregunta si el menu no esta cargado".
  `daily_menu` no trae fechas futuras, asi que preguntar que platos van es el camino normal.

### Validado contra datos (24/08/2026)
- `meal_orders_daily` **existe y esta poblada**: 22.832 filas, 26,4 semanas. El hallazgo central de
  la 1.6.0 queda confirmado.
- **El divisor de exposicion estaba bien pensado.** Los dias de exposicion por plato en 12 semanas
  van de 1 a 29 y normalizar cambia el ranking por completo: solo 1 de los 10 platos mas vendidos
  sigue en el top 10. Aclaracion para quien repita la prueba: el divisor corrige el **nivel**, no la
  varianza — la variacion semanal queda igual (69% con divisor, 70% sin).
- La participacion por plato varia una mediana de **69%** semana a semana. La mediana de 12 semanas
  es el estimador correcto por robusto, pero ningun numero por plato y semana va a ser preciso.

## [1.6.0] - 2026-08-22

### Fixed
- **`proyeccion-insumos` ya no pide el mix de platos: lo deriva del histórico.** La skill afirmaba,
  bajo el titulo "Restriccion fundamental", que el espejo "no tiene ninguna tabla que enlace pedidos
  con platos" y que se habia verificado que no existian `order_details` ni equivalentes. Es falso.
  El lake tiene **`meal_orders_daily`** (`order_date` x `meal_id` x `store_id`, con `unidades`),
  creada en la migracion 006 del datalake y descrita ahi textualmente como "ventas diarias por
  plato x tienda (reemplaza order_details raw)". Sobre esa premisa equivocada, la skill le pedia a
  Ops que tipeara porcentajes a mano y multiplicaba: el numero clave lo ponia la persona, no el
  historico. Ahora la participacion de cada plato sale de sus ventas reales, contando solo los dias
  en que estuvo ofrecido segun `daily_menu`.

### Added
- **Dias de exposicion como divisor.** La participacion de un plato se calcula sobre los dias en que
  estuvo en el menu de su sede, no sobre todos los dias. Sin ese filtro, todo plato ocasional se
  proyecta bajisimo.
- **Rendimiento historico de cocina**, via `catering_daily_metrics`: contraste de volumen contra
  `orders` y alerta por `rating_average` en caida. Entra como **contraste y alerta, nunca como
  multiplicador** — no hay elasticidad medida entre calificacion y volumen, y aplicar un factor
  inventado mueve los kilos de compra con un numero que nadie validó. `incident_ratio` y
  `percentage_late_routes` estan NULL a proposito en origen y no se rellenan.
- **Frecuencia de pedidos** en `proyeccion-demanda` (Paso 6b): pedidos por cliente por semana, via
  `orders.customer_id` + `customers.plan_actual`. Tambien como contraste, no multiplicador — la
  mediana de 26 semanas ya contiene la frecuencia, y aplicar ambos cuenta dos veces el mismo efecto.
  El valor es anticipar el quiebre antes de que la mediana lo absorba.
- **Columna `Base` obligatoria en el reporte de platos**: dice si cada cantidad salio del historico
  del plato o fue estimada por familia de proteina (platos nuevos, sin historico propio).
- Documentado el **cruce de llaves** que las tablas no comparten: `meal_orders_daily.store_id` y
  `catering_daily_metrics.catering_id` son cocina (`stores.store_id`), pero `daily_menu` y
  `meal_feedbacks` van por **sede** (`branch_office_id`). Una sede tiene varias cocinas.

### Changed
- `proyeccion-demanda`: la tabla de fuentes decia que el mix de platos salia de `meals`. `meals` es
  solo el catalogo; el mix esta en `meal_orders_daily`.
- Si el historico de ventas por plato trae menos de 4 semanas, la skill **para y no entrega
  numeros**, en vez de caer en un supuesto silencioso.

### Known limits
- La calificacion de plato (`meal_feedbacks`) es por sede, no por cocina: no se puede atribuir un
  plato mal calificado a una cocina puntual.
- La merma sigue siendo la estandar de la receta, igual para todas las cocinas.


## [1.3.0] - 2026-08-21

### Added
- **Factores de caída por feriado medidos para los tres paises**, sobre los feriados de 2026 y
  contra la linea base de su propio dia de semana: Peru 0.30 (7 feriados), Colombia 0.30 (12),
  Mexico 0.45 (4). Antes solo Peru estaba medido y los otros dos salian marcados como estimados.
  Hallazgo: **el feriado mexicano pega bastante menos** — usar alla el factor peruano subestimaria
  la demanda del feriado en un 50%.
- Dos feriados "flojos" con factor propio, porque caen la mitad de lo normal: 6 de agosto en
  Peru (0.60) y Batalla de Boyaca en Colombia (0.56).
- **Amortiguacion de la tendencia por pais**, elegida por backtest de 6 semanas: Peru y Mexico a
  la mitad del cambio observado, Colombia completa. Colombia crece sostenido y amortiguarla dejaba
  la proyeccion corta entre 5% y 8%.
- Error del metodo medido por pais: Colombia 2.6%, Mexico 4.5%, Peru 11.2%. Peru queda marcado
  como el menos preciso, con instruccion de entregarlo como referencia a revisar y no como
  numero para cargar a ciegas.
- Instrucciones para recalcular los factores y para excluir los feriados que caen domingo.

## [1.2.0] - 2026-08-20

### Added
- Las skills ahora resuelven las credenciales del espejo solas, en orden: variables de entorno
  → `./.env` → `~/Projects/.env` → `~/.env`. Antes solo miraban las variables de entorno, asi que
  quien guardaba las credenciales en un `.env` recibia "faltan credenciales" y no habia forma de
  usarlas sin reiniciar Claude Code. Bloque de carga incluido y probado.
- README: las dos opciones de configuracion (`.env` primero, variables de entorno despues), con el
  aviso de que en Windows un `$PROFILE` dentro de OneDrive sincroniza la llave a la nube.

### Changed
- Las skills tienen instruccion explicita de **no pedir las credenciales por chat** y de no
  repetirlas en ninguna respuesta ni reporte.

## [1.1.0] - 2026-08-20

### Added
- Calendario de feriados de **Colombia** (2026 y 2027, 19 por año) con marca de cuales se
  trasladan al lunes por la Ley Emiliani, y aviso de que once de diecinueve caen en lunes:
  la linea base de los lunes de Bogota queda contaminada si no se excluyen de la ventana.
- Calendario de feriados de **Mexico** (2026 y 2027) derivado de la regla del articulo 74 de la
  LFT, con los tres lunes moviles calculados y el caso del 1 de diciembre cada seis anios.
  Se agregan aparte los dias no obligatorios que si mueven la demanda: Semana Santa,
  2 de noviembre y 12 de diciembre.

### Notes
- Los **factores de caida** de Mexico y Colombia siguen SIN medir. El 0.25 de Peru salio de medir
  los feriados peruanos y no se puede copiar. La skill ahora dice como calcularlos desde la
  historia y exige marcar el factor como estimado hasta que se midan.

## [1.0.0] - 2026-08-20

### Added
- Primer release. Plugin de skills de Operaciones, independiente de `mv-dev`
  (no trae hooks ni servidores MCP).
- `proyeccion-demanda`: pedidos esperados por dia y por cocina, con linea base por dia
  de semana sobre 26 semanas, factor de feriado, tendencia y registro historico de acierto.
  Incluye el calendario de feriados de Peru.
- `proyeccion-insumos`: platos a preparar por cocina y dia, explosion de recetas a kilos
  por ingrediente, merma, empaques y costo estimado de compra. El menu planificado de la
  semana es un input obligatorio de Operaciones.
- README con instalacion, las dos variables de entorno del espejo de datos
  (`MV_MIRROR_URL`, `MV_MIRROR_ANON_KEY`), mantenimiento del calendario y limites conocidos.
