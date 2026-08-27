# Changelog — mv-ops

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
