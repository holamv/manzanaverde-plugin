---
description: Genera el reporte de proyección de demanda para el equipo de Ops - pedidos esperados por día y por cocina, con ajuste por feriados y registro histórico de acierto. Entrega todo en Markdown. Usar cuando pidan "proyección de pedidos", "cuántos pedidos esperamos", "precantidades", "demanda de la próxima semana" o planificación de producción.
---

# Proyección de Demanda — Reporte para Ops

Genera un reporte en **Markdown** con los pedidos esperados por día y por cocina para las próximas semanas. Está pensado para que el equipo de Operaciones planifique producción sin depender de nadie técnico.

## Cuándo usar

- **Planificación semanal de producción** — cuántos platos preparar por cocina
- **Antes de un feriado** — la demanda cae hasta 75%, hay que anticiparlo
- **Revisión de acierto** — comparar lo proyectado contra lo que realmente pasó

## Qué entrega

Siempre archivos **Markdown**, nunca dashboards ni código:

| Archivo | Contenido |
|---|---|
| `proyecciones/YYYY-MM-DD-proyeccion.md` | El reporte de la semana (entregable principal) |
| `proyecciones/HISTORIAL.md` | Acumulado de proyectado, precantidad usada y real, con los tres errores |

Si la carpeta `proyecciones/` no existe, crearla.

---

## Fuente de datos

Espejo de datos de MV en Supabase (**solo lectura**, no requiere VPN).

```bash
MV_MIRROR_URL       # https://<proyecto>.supabase.co/rest/v1
MV_MIRROR_ANON_KEY  # anon key (rol anónimo, solo SELECT)
```

### Cómo obtener las credenciales — en este orden

**No pedirle las credenciales al usuario por chat.** Buscarlas así, y usar la primera que aparezca:

1. **Variables de entorno** `MV_MIRROR_URL` y `MV_MIRROR_ANON_KEY`.
2. **Archivo `.env`**, en este orden: `./.env` (directorio de trabajo) → `%USERPROFILE%/Projects/.env`
   → `%USERPROFILE%/.env`. En macOS/Linux, `~/Projects/.env` → `~/.env`.

Cargarlo con este bloque, que resuelve las dos fuentes y no imprime nunca el valor:

```js
import fs from 'fs';
import os from 'os';
import path from 'path';

function credenciales() {
  let url = process.env.MV_MIRROR_URL;
  let key = process.env.MV_MIRROR_ANON_KEY;
  const candidatos = [
    path.join(process.cwd(), '.env'),
    path.join(os.homedir(), 'Projects', '.env'),
    path.join(os.homedir(), '.env'),
  ];
  for (const f of candidatos) {
    if (url && key) break;
    if (!fs.existsSync(f)) continue;
    for (const linea of fs.readFileSync(f, 'utf8').split(/\r?\n/)) {
      const m = linea.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);
      if (!m) continue;
      const v = m[2].trim().replace(/^["']|["']$/g, '');
      if (m[1] === 'MV_MIRROR_URL' && !url) url = v;
      if (m[1] === 'MV_MIRROR_ANON_KEY' && !key) key = v;
    }
  }
  if (!url || !key) {
    throw new Error('Faltan MV_MIRROR_URL / MV_MIRROR_ANON_KEY. Pedirlas al Tech Lead y guardarlas en .env o en el entorno.');
  }
  return { url: url.replace(/\/$/, ''), headers: { apikey: key, Authorization: `Bearer ${key}` } };
}
```

Solo si ninguna de las dos fuentes las tiene: decirle al usuario que las pida al Tech Lead y que
las guarde **él mismo** en un `.env` o en su perfil de shell. Nunca aceptarlas pegadas en el chat;
si el usuario las pega igual, avisarle y no repetirlas en ninguna respuesta.

**Nunca escribir estas credenciales en el reporte, en un archivo del repo, ni en la conversación.**

### Tablas disponibles

| Tabla | Campos | Uso |
|---|---|---|
| `orders` | `id, customer_id, fecha, monto, catering_id, status_id, synced_at` | Serie histórica de pedidos |
| `stores` | `store_id, store_name, city, country, country_id, cocina_id, branch_office_id, catering_level, is_active, business_type` | Cocinas / tiendas |
| `customers` | `id, nombre, email, telefono, pais, plan_actual, created_at` | Frecuencia por cliente (ver Paso 7) |
| `meal_orders_daily` | `order_date, meal_id, store_id, country_id, unidades` | **Ventas reales por plato y cocina** |
| `daily_menu` | `date, branch_office_id, meal_id, meal_type` | Qué platos van cada día, por sede |
| `catering_daily_metrics` | `catering_id, day_date, orders, rating_average` | **La serie de demanda** (ver Paso 3). `orders` = pedidos facturados por cocina y día |
| `meals` | `meal_id, meal_name, protein_type, is_star, full_recipe, food_cost_local, calories, ...` | Catálogo y recetas |

> **El mix de platos NO sale de `meals`.** `meals` es solo el catálogo. El mix real está en
> `meal_orders_daily` (unidades por plato, cocina y día) cruzado con `daily_menu` (los días en que
> el plato estuvo ofrecido). Eso lo hace `proyeccion-insumos`; esta skill proyecta el volumen.

### ⚠️ Trampas conocidas

1. **`orders.catering_id` corresponde a `stores.store_id`** — no existe tabla `caterings`. Este es el join correcto.
1b. **`orders` NO trae el estado filtrado.** Contar sus filas mete los pedidos anulados (status 2) en la serie: +5.5% medido. Ver Paso 3 — para la base histórica se usa `catering_daily_metrics`, que cuenta solo facturados.
2. **`monto` está en moneda local** (PEN en Perú, MXN en México, COP en Colombia). **Nunca sumar montos de distintos países.**
3. **`fecha` es timestamptz** a medianoche local convertida a UTC (`05:00Z` en Perú).
4. **PostgREST no permite funciones de agregación** (`sum()`, `count()` en `select`). Para contar usar cabeceras:
   ```
   Prefer: count=exact
   Range: 0-0
   ```
   y leer el total desde la cabecera `Content-Range` (`0-0/12345`).
5. **`synced_at`** indica cuándo se sincronizó la fila. Si el espejo lleva días sin sincronizar, avisarlo en el reporte.

---

## Proceso

### Paso 1 — Delimitar el alcance

Preguntar solo si no está claro:
- **País** (por defecto: Perú)
- **Semanas a proyectar** (por defecto: 1)

### Paso 2 — Obtener las cocinas del país

```
GET {MV_MIRROR_URL}/stores?select=store_id,store_name,city,country,is_active&country=ilike.*Per*
```

Guardar la lista de `store_id`. **Incluir también las inactivas** para el histórico (una cocina cerrada hace 3 meses igual aportó pedidos entonces).

### Paso 3 — Traer la serie diaria (últimas 26 semanas)

Una sola consulta a `catering_daily_metrics`, que ya viene agregada por cocina y día:

```
GET {MV_MIRROR_URL}/catering_daily_metrics?catering_id=in.(id1,id2,...)&day_date=gte.{hace 26 semanas}&select=day_date,catering_id,orders&limit=10000
```

`orders` es el conteo de pedidos **facturados** de esa cocina ese día. Es la serie de demanda.

#### ⚠️ NO contar filas de la tabla `orders` para esto

Hasta la 1.6.1 este paso hacía 182 requests —uno por día— contando filas de `orders` con
`Prefer: count=exact`. Eso tenía un error de fondo: **no filtraba el estado del pedido**, así que
metía los anulados en la base histórica.

Medido el 2026-08-27 sobre las 7 cocinas de Lima:

| Día medido | Anulados que se colaban, sobre el total facturado |
|---|--:|
| 1 | 3.5% |
| 2 | 5.6% |
| 3 | 5.8% |
| 4 | 5.6% |

Un **5.5% de inflación sistemática** en la línea base, sobre la que después se aplica la tendencia
y el margen. Los estados son: 1 ingresado · 2 **anular** · 3 en camino · 4 **facturado** ·
5 devuelto (`src/mixins/OrdersMixins.js` del BackOffice). `catering_daily_metrics.orders` cuenta
solo el 4, y para una semana ya cerrada eso es exactamente lo que se produjo y se cobró.

#### Ojo: la historia de esta tabla es más corta de lo que pide el método

`catering_daily_metrics` **arranca el 2026-04-16** (verificado 2026-08-27), o sea unas **19 semanas**,
no 26. Son 19 observaciones por día de semana: alcanza de sobra para una mediana, pero el reporte
tiene que decir la ventana **real** usada y no "26 semanas" por inercia. Verificar la primera fecha
disponible en cada corrida y ajustar la ventana; si quedan menos de 8 semanas, aplica el freno del
Paso 9.

#### Si hacen falta más de 19 semanas

Ahí sí se vuelve a `orders`, que arranca en **2018-12-11**, pero **con el estado filtrado**:

```
GET {MV_MIRROR_URL}/orders?select=fecha,catering_id&catering_id=in.(id1,...)&status_id=neq.2
    &fecha=gte.{lunes}&fecha=lt.{lunes siguiente}&limit=10000
```

Un request por semana y agregar del lado del cliente por fecha y cocina. Verificado: con
`status_id=neq.2` da **exactamente el mismo número** que `catering_daily_metrics`. Sin el filtro da
~5.5% más.

Usar esta vía solo cuando la ventana corta sea un problema real —estacionalidad anual, por ejemplo—.
Para la proyección semanal, la tabla agregada es un request contra 26 y da lo mismo.

#### Cuándo `orders` sí es la fuente correcta

Para saber **qué hay que cocinar hoy** —no para la base histórica— la vista operativa cuenta los
*ingresados*, incluidos los que todavía pueden cancelarse — la columna CANTIDAD de la pantalla de
mapa del BackOffice, que corre unos puntos por encima de lo facturado. Las dos cifras son legítimas
y miden cosas distintas: una es el compromiso de producción del día, la otra es el resultado.
**Esta skill proyecta a partir del resultado.**

#### Ventaja lateral

La serie viene desagregada **por cocina**, no solo el total. Eso hace innecesaria la aproximación
del Paso 7 (repartir el total por participación histórica): cada cocina tiene su propia serie.

### Paso 4 — Calcular la línea base por día de semana

Para cada día de la semana, sacar la **mediana** de las últimas 26 semanas
(mediana, no promedio: resiste feriados y outliers).

#### ⚠️ Obligatorio: excluir los feriados de la ventana ANTES de sacar la mediana

No alcanza con que la mediana sea robusta. Hay que **filtrar los días feriados de la ventana
histórica** antes de calcular, para los tres países:

```js
const base = {};
for (let d = 0; d < 7; d++) {
  const valores = ventana26sem
    .filter(f => diaDeSemana(f) === d && !esFeriado(f, pais))   // <- el filtro que importa
    .map(f => pedidos[f]);
  base[d] = mediana(valores);
}
```

Medido el 21-08-2026 sobre 26 semanas reales, esto es lo que cambia si se omite el filtro:

| País y día | Excluyendo feriados | Sin excluir | Error si se omite |
|---|--:|--:|--:|
| **Colombia, lunes** | **507** | **481** | **−5.0%** |
| Colombia, resto de días | — | — | entre 0% y −0.4% |
| Perú, todos los días | — | — | entre 0% y −1.2% |
| México, todos los días | — | — | entre 0% y −0.8% |

**El caso grave es Colombia: 8 de los 26 lunes de la ventana son festivos** (San José, Ascensión,
Corpus Christi, Sagrado Corazón, San Pedro y San Pablo, Virgen del Carmen, Independencia,
Asunción). Casi un tercio. Sin el filtro, **todos** los lunes de Bogotá se proyectan 5% bajos —
no solo los feriados.

Y es un riesgo que puede empeorar: si en algún año más de la mitad de los lunes de la ventana
caen festivos, la mediana deja de resistir y la línea base se derrumba. El filtro no es una
optimización, es lo que evita que eso pase.

**Referencia validada Perú (feb–ago 2026)** — usar como control de sanidad, no como valor fijo:

| Día | Mediana | Nota |
|---|--:|---|
| Lunes | ~649 | |
| Martes | ~749 | pico |
| Miércoles | ~748 | pico |
| Jueves | ~726 | |
| Viernes | ~643 | |
| Sábado | ~209 | ⅓ de un día laboral |
| **Domingo** | **0** | **no hay reparto — siempre 0** |

Si algún valor se desvía >30% de esta referencia, revisar los datos antes de reportar.

### Paso 5 — Aplicar factor de feriado

Los feriados son la mayor fuente de error: **duplican el error del modelo** (7.6% → 19%).

```
# NO existe un factor único. Se midieron por país sobre los feriados de 2026
# (ver 1.3.0). Usar el del país que se está proyectando:
factor_feriado = 0.30   # Perú y Colombia
factor_feriado = 0.45   # México — el feriado mexicano pega bastante menos
factor_puente  = 0.60   # día laboral pegado a un feriado (los tres países)
```

Ver el calendario más abajo.

### Paso 6 — Aplicar tendencia

Comparar el promedio de las últimas 4 semanas **sin feriados** contra las 4 anteriores.
Aplicar el delta de forma suave. Referencia Perú: **−5.3% semestral** (declive leve).

### Paso 6b — Frecuencia de pedidos (contraste, no multiplicador)

La mediana histórica ya contiene la frecuencia de forma implícita: si la gente pide menos seguido,
caen los pedidos por día y la mediana lo recoge. El valor de mirar la frecuencia aparte es
**detectar el quiebre antes de que la mediana lo absorba**, porque la mediana de 26 semanas tarda
semanas en reaccionar.

```
pedidos_por_cliente(semana) = pedidos(semana) ÷ clientes_distintos(semana)
```

`orders.customer_id` da los clientes distintos por semana. Comparar las últimas 4 semanas contra
las 4 anteriores.

**La apertura por tipo de plan NO está disponible.** `customers.plan_actual` existe como columna
pero está **vacía en las 708.910 filas** (verificado el 24/08/2026). No intentar segmentar por plan:
no hay dato, y rellenarlo con un supuesto es exactamente lo que esta skill no hace.

**Antes de usar el paso, verificar que `orders.customer_id` venga poblado** (`Prefer: count=exact`).
Al 24/08/2026 viene al 100%. Si en el futuro viniera nulo en la mayoría de las filas, **omitir este
paso y decirlo en el reporte** — no sustituirlo por un supuesto.

Reglas de uso, iguales a las del rendimiento de cocina:

- **Sí:** avisar en el reporte si los pedidos por cliente se movieron más de 10%, porque anticipa
  hacia dónde va la mediana.
- **No:** abrir por tipo de plan. `plan_actual` está vacía; ver arriba.
- **No:** multiplicar la proyección por el cambio de frecuencia. Estaría contando dos veces el mismo
  efecto: ya está dentro de la mediana. Aplicar ambos infla o deprime la proyección sin fundamento.

### Paso 7 — Proyectar por cocina

Correr los pasos 4 a 6 **por cocina**, sobre su propia serie: el Paso 3 ya la trae desagregada.

No repartir el total por participación histórica. Eso era lo que hacía falta cuando la serie venía
del conteo global de `orders`, y arrastra un supuesto falso: que todas las cocinas crecen y caen
juntas. No lo hacen. Medido el 2026-08-25 contra la precantidad de esa semana, Los Olivos - Mercurio
vino **+30%** por encima de lo planeado y Miraflores - Arica **−20%** por debajo, el mismo día.
Un reparto proporcional no puede ver eso, y es justo la señal que Ops necesita.

Si una cocina tiene `is_active = false`, excluirla de la proyección futura y decirlo en el reporte.

Si una cocina tiene menos de 4 semanas de historia propia, su mediana no es confiable: caer al
reparto por participación **solo para ella**, y marcarlo en el reporte.

### Paso 8 — Medir la semana que acaba de cerrar

Antes de proyectar, cerrar la anterior. Llena la sección "Qué tan bien le fue a la semana pasada"
del reporte, y hace falta para el Paso 9.

Traer tres series de la semana ya cerrada, por día y por cocina:

1. **El real** — `catering_daily_metrics.orders` (Paso 3).
2. **La precantidad que Ops usó de verdad** — no la que proyectó esta skill. Si no se consigue,
   dejarla en "sin dato"; no sustituirla por la proyección propia, que es otra cosa.
3. **El real de la semana anterior a esa**, sin ajuste — el predictor de referencia.

Calcular el error de 2 y de 3 contra 1, **con signo**, por día y por cocina.

### Paso 9 — Validar el método antes de entregar

Backtest de las últimas 4 semanas con este mismo método, comparado con lo real.

Dos frenos, no uno:

- **Si el MAPE supera 15%**, no entregar el reporte sin una advertencia explícita de que el modelo
  está fuera de rango.
- **Si el método pierde contra el predictor de referencia** del Paso 8 —el mismo día de la semana
  anterior, sin ajuste— decirlo en Alertas con las dos cifras. Un modelo que erra más que "lo mismo
  que la semana pasada" no está aportando; está agregando error. Esto no bloquea la entrega, pero no
  puede quedar callado.

Si el backtest no se puede correr (menos de 8 semanas de historia), escribirlo como limitación en
vez de omitirlo.

---

## Calendario de feriados — Perú

| Fecha | Feriado | Factor |
|---|---|--:|
| 1 ene | Año Nuevo | 0.30 |
| Jueves y Viernes Santo | Semana Santa (móvil) | 0.30 |
| 1 may | Día del Trabajo | 0.30 |
| 29 jun | San Pedro y San Pablo | 0.30 |
| **23 jul** | **Ley 32083** | **0.47** |
| 28–29 jul | Fiestas Patrias | 0.30 |
| **6 ago** | **Ley 32083** | **0.60** |
| 30 ago | Santa Rosa de Lima | 0.30 |
| 8 oct | Combate de Angamos | 0.30 |
| 1 nov | Todos los Santos | 0.30 |
| **9 dic** | **Ley 32083** | 0.30 *(sin medir)* |
| 8 dic | Inmaculada Concepción | 0.30 |
| 25 dic | Navidad | 0.30 |

**Los tres feriados de la Ley 32083** (23 jul, 6 ago, 9 dic) se agregaron por ley y son fáciles de
pasar por alto. Verificado sobre 2026: el **23 de julio** cayó a 339 pedidos contra una base de 727
(factor 0.47) y el **6 de agosto** a 435 (factor 0.60) — los dos pegan **menos** que un feriado
normal, así que llevan factor propio y no el del país. El **9 de diciembre** todavía no ocurrió:
usar 0.30 provisional y medirlo cuando pase.

**Verificar cada año.** Los feriados peruanos cambian por ley con más frecuencia que en los otros
dos países.

**Efecto puente:** los días laborales adyacentes a un feriado también caen. En Fiestas Patrias 2026 toda la semana estuvo deprimida, no solo el 28 y 29. Aplicar `factor_puente` a los días pegados.

---

## Calendario de feriados — Colombia

Colombia tiene 19 feriados al año. La mayoría se rige por la **Ley Emiliani** (Ley 51 de 1983): el
feriado se corre al lunes siguiente. Por eso casi todos los lunes marcados abajo son festivos
trasladados, no fechas fijas — **hay que recalcularlos cada año, no copiarlos**.

| 2026 | Día | Feriado | Ley Emiliani |
|---|---|---|:--:|
| 1 ene | jue | Año Nuevo | — |
| 12 ene | lun | Reyes Magos | sí |
| 23 mar | lun | San José | sí |
| 2 abr | jue | Jueves Santo | — |
| 3 abr | vie | Viernes Santo | — |
| 1 may | vie | Día del Trabajo | — |
| 18 may | lun | Ascensión del Señor | sí |
| 8 jun | lun | Corpus Christi | sí |
| 15 jun | lun | Sagrado Corazón | sí |
| 29 jun | lun | San Pedro y San Pablo | sí |
| 13 jul | lun | Virgen del Carmen | sí |
| 20 jul | lun | Independencia | — |
| 7 ago | vie | Batalla de Boyacá | — |
| 17 ago | lun | Asunción de la Virgen | sí |
| 12 oct | lun | Día de la Raza | sí |
| 2 nov | lun | Todos los Santos | sí |
| 16 nov | lun | Independencia de Cartagena | sí |
| 8 dic | mar | Inmaculada Concepción | — |
| 25 dic | vie | Navidad | — |

| 2027 | Día | Feriado | Ley Emiliani |
|---|---|---|:--:|
| 1 ene | vie | Año Nuevo | — |
| 11 ene | lun | Reyes Magos | sí |
| 22 mar | lun | San José | sí |
| 25 mar | jue | Jueves Santo | — |
| 26 mar | vie | Viernes Santo | — |
| 1 may | sáb | Día del Trabajo | — |
| 10 may | lun | Ascensión del Señor | sí |
| 31 may | lun | Corpus Christi | sí |
| 7 jun | lun | Sagrado Corazón | sí |
| 5 jul | lun | San Pedro y San Pablo | sí |
| 12 jul | lun | Virgen del Carmen | sí |
| 20 jul | mar | Independencia | — |
| 7 ago | sáb | Batalla de Boyacá | — |
| 16 ago | lun | Asunción de la Virgen | sí |
| 18 oct | lun | Día de la Raza | sí |
| 1 nov | lun | Todos los Santos | sí |
| 15 nov | lun | Independencia de Cartagena | sí |
| 8 dic | mié | Inmaculada Concepción | — |
| 25 dic | sáb | Navidad | — |

**Ojo con Colombia:** once de los diecinueve feriados caen en lunes. Un lunes cualquiera en Bogotá
tiene alta probabilidad de ser festivo, así que la mediana de lunes de las últimas 26 semanas
**viene contaminada** por esos festivos. Antes de calcular la línea base de lunes, excluir los
lunes festivos de la ventana histórica; si no, la proyección de todos los lunes sale baja.

---

## Calendario de feriados — México

Siete días de descanso obligatorio, fijados por el **artículo 74 de la Ley Federal del Trabajo**.
Tres son "lunes móvil" y por eso cambian de fecha cada año: se calculan con la regla, no se copian.

| Regla (art. 74) | 2026 | 2027 |
|---|---|---|
| 1 de enero | 1 ene (jue) | 1 ene (vie) |
| Primer lunes de febrero (por el 5 feb, Constitución) | 2 feb (lun) | 1 feb (lun) |
| Tercer lunes de marzo (por el 21 mar, Benito Juárez) | 16 mar (lun) | 15 mar (lun) |
| 1 de mayo — Día del Trabajo | 1 may (vie) | 1 may (sáb) |
| 16 de septiembre — Independencia | 16 sep (mié) | 16 sep (jue) |
| Tercer lunes de noviembre (por el 20 nov, Revolución) | 16 nov (lun) | 15 nov (lun) |
| 25 de diciembre — Navidad | 25 dic (vie) | 25 dic (sáb) |

Existe un octavo caso: **1 de diciembre cada seis años**, cuando hay transmisión del Poder
Ejecutivo. El último fue 2024; el próximo, 2030. No aplica a 2026 ni 2027.

**No son de descanso obligatorio pero sí afectan la demanda** (oficinas y colegios cierran, que es
donde come el cliente de Menú Diario). Tratarlos como feriado con su propio factor:

| Día | 2026 | 2027 |
|---|---|---|
| Jueves y Viernes Santo | 2–3 abr | 25–26 mar |
| 2 de noviembre — Día de Muertos | 2 nov (lun) | 2 nov (mar) |
| 12 de diciembre — Virgen de Guadalupe | 12 dic (sáb) | 12 dic (dom) |

---

## Factores de caída por feriado — medidos por país

Medidos el 21-08-2026 sobre los feriados de 2026 de cada país, uno por uno:
`factor = pedidos_reales_del_feriado ÷ mediana_de_ese_día_de_semana` (mediana de los factores).

| País | Factor | Feriados medidos | Lectura |
|---|--:|--:|---|
| Perú | **0.30** | 7 | Cae ~70%. Coincide con el 0.25 que estaba documentado |
| Colombia | **0.30** | 12 | Cae ~70%, igual que Perú |
| México | **0.45** | 4 | **Cae solo ~55% — el feriado mexicano pega bastante menos** |

**No copiar el factor de un país a otro.** México lo demuestra: usar el 0.30 de Perú allá
subestimaría la demanda de un feriado en un 50%.

### Feriados "flojos" — tratar aparte

Tres feriados caen la mitad de lo normal. Usar su propio factor, no el del país:

| Feriado | País | Factor medido |
|---|---|--:|
| 23 de julio (Ley 32083) | Perú | 0.47 |
| 6 de agosto (Ley 32083) | Perú | 0.60 |
| Batalla de Boyacá (7 ago) | Colombia | 0.56 |

### Cómo actualizar estos factores

Recalcular una vez al año, o cuando el error del feriado en `HISTORIAL.md` se salga de rango:
tomar los feriados del país en las últimas 26 semanas, sacar el factor de cada uno contra la
línea base de su día de semana, y guardar acá la **mediana** más el número de observaciones.

Excluir los feriados que caen domingo: no hay reparto, el factor no significa nada.

Un feriado con factor inventado es peor que un feriado sin factor: el reporte se ve preciso y no lo es.

### Amortiguación de la tendencia — también por país

Validado por backtest sobre las 6 últimas semanas completas (21-08-2026):

| País | Tendencia a aplicar | Error del método | Sesgo |
|---|---|--:|--:|
| Perú | mitad del cambio observado | 11.2% | +1.1% |
| México | mitad del cambio observado | 4.5% | +0.1% |
| Colombia | **completa** | 2.6% | −2.3% |

Colombia viene creciendo de forma sostenida: amortiguar su tendencia dejaba la proyección
sistemáticamente corta (−5% a −8%). Perú es el menos preciso de los tres porque sus semanas
oscilan más — sobre 4 semanas su error llega a 15.2%, así que **para Perú siempre entregar la
cifra como referencia a revisar el lunes, no como número para cargar a ciegas**.

---

Para otros países, construir el calendario equivalente antes de proyectar.

---

## Modelo

```
proyección(día) = mediana_día_semana(últimas 26 sem)
                × factor_feriado      (si aplica)
                × factor_tendencia
```

**Precisión esperada: 7–8% de error** (validado sobre 26 semanas de Perú).

**No usar ARIMA, Prophet ni machine learning.** La demanda tiene un coeficiente de variación de 12% — es estable y este modelo simple ya alcanza el error mencionado. Un modelo complejo agrega opacidad sin ganar precisión, y Ops necesita poder explicar de dónde sale cada número.

---

## Plantilla del reporte

Escribir exactamente esta estructura en `proyecciones/YYYY-MM-DD-proyeccion.md`:

````markdown
# Proyección de Demanda — {País}
**Semana:** {lunes} al {domingo}
**Generado:** {fecha} · **Datos hasta:** {max(synced_at)}

## Resumen

**Se esperan {TOTAL} pedidos esta semana** ({±X}% vs. la semana pasada).

{Una línea de contexto: si hay feriado, si hay una cocina cerrada, si la tendencia cambió.}

## Pedidos esperados por día

| Día | Fecha | Proyección | Semana pasada | Nota |
|-----|-------|-----------:|--------------:|------|
| Lunes | 10 ago | 650 | 659 | |
| Martes | 11 ago | 765 | 768 | |
| ... | | | | |
| Domingo | 16 ago | 0 | 0 | Sin reparto |
| **Total** | | **3,540** | **3,601** | |

## Pedidos esperados por cocina

| Cocina | Ciudad | Proyección semanal | Participación |
|--------|--------|-------------------:|--------------:|
| ... | | | |

## ⚠️ Alertas

- {Feriados de la semana y su impacto esperado}
- {Cocinas inactivas o recién abiertas}
- {Desviaciones que Ops debe revisar}

*(Si no hay alertas, escribir "Sin alertas para esta semana.")*

## Qué tan bien le fue a la semana pasada

| Día | Precantidad usada | Real | Error | Real de la semana anterior | Error si se hubiera usado ese |
|---|--:|--:|--:|--:|--:|
| lunes | 114 | 100 | **+14.3%** | 101 | +1.2% |
| martes | 103 | 100 | +3.0% | 93 | −6.8% |
| miércoles | 108 | 100 | +8.2% | 98 | −2.5% |
| **Error promedio** | | | **8.5%** | | **3.5%** |

*(Valores indexados: el real de cada día = 100. Los porcentajes son los medidos.)*

**Las dos últimas columnas son el punto de esta tabla.** No alcanza con decir cuánto erró el plan:
hay que decir si el ajuste que se le aplicó lo mejoró o lo empeoró. La comparación es contra el
predictor más tonto posible —el mismo día de la semana anterior, sin ajuste ninguno— porque si el
método no le gana a eso, el ajuste está agregando error en vez de quitarlo.

En el ejemplo de arriba (semana 35, Lima, medido el 2026-08-27) no le gana: la precantidad llevaba
+12.5% sobre el real de la semana previa y erró 8.5%, mientras el real crudo erraba 3.5%.

### Cómo llenarla

- **Precantidad usada**: lo que Ops fijó de verdad, no lo que esta skill proyectó. Si Ops la pega
  en el chat, usar eso. Si no, `GET prequantities/get_prequantities_matrix?date={YYYY-MM-DD}` del
  BackOffice (campo `platos`; `total_food` es el real que ese módulo ya calcula). Esa API pide
  credenciales del BackOffice, que esta skill **no** tiene: si no están, dejar la columna en
  "sin dato" y llenar solo la comparación contra la semana anterior. **No inventarla.**
- **Real**: `catering_daily_metrics.orders` de la semana ya cerrada (Paso 3).
- **Error**: `(plan − real) / real`, con signo. El signo importa: `+` es sobreproducción y `−` es
  quiebre de stock, y no cuestan lo mismo. Nunca reportar solo el valor absoluto.
- **Error promedio**: media de los valores absolutos, solo sobre los días con reparto.

### Qué decir cuando el ajuste pierde

Si el error del plan supera al de la semana anterior cruda, escribirlo explícito en Alertas, con la
cifra. No es un detalle técnico: es sobreproducción sistemática que alguien está pagando.

Y decirlo con cuidado — la precantidad **no es solo un pronóstico**, es también un compromiso de
producción, y quedarse corto cuesta más que sobrar. Un colchón deliberado es legítimo. Lo que no es
legítimo es que esté horneado en la fórmula sin que nadie lo haya elegido. La redacción correcta es
"el margen cuesta X% de sobreproducción, ¿lo queremos?", no "el método está mal".

### Por cocina, no solo el total

El total puede cerrar bien y estar mal repartido. En la semana 35 el margen agregado dio +8.7% y el
real vino +9.3% —casi perfecto— pero cocina por cocina estaba invertido: Miraflores - Arica recibió
+20% de margen y le sobró 20%, Los Olivos - Mercurio recibió +6% y le faltó 30%. **Siempre incluir
el desglose por cocina**, ordenado por error absoluto descendente, y marcar las que se pasan de 15%.

## Cómo se calculó

Mediana de las últimas 26 semanas por día de semana, por cocina, ajustada por feriados y tendencia.
Precisión del método en las últimas 4 semanas: {MAPE del backtest}% de error.
Fuente: espejo de datos MV (solo lectura), pedidos facturados, sincronizado al {synced_at}.
````

### Reglas del reporte

1. **Escribir para Ops, no para técnicos** — sin SQL, sin nombres de tablas, sin jerga. "Pedidos esperados", no "proyección de la serie temporal".
2. **Números redondeados a entero.** Nadie prepara 3,540.7 platos.
3. **Domingo siempre 0** y marcado como "Sin reparto".
4. **Toda alerta debe ser accionable** — decir qué hacer, no solo que algo pasa.
5. **Nunca inventar datos.** Si algo no se pudo calcular, escribirlo como "sin datos" y explicar por qué.

---

## Registro histórico

Después de generar cada reporte, agregar una fila a `proyecciones/HISTORIAL.md`:

```markdown
| Semana | Proyectado | Precantidad usada | Real | Error proyección | Error precantidad | Error semana anterior | Notas |
|--------|-----------:|------------------:|-----:|-----------------:|------------------:|----------------------:|-------|
| 2026-08-24 | 3,640 | 4,040 | — | — | — | — | Pendiente de cierre |
```

Al generar el reporte de la semana siguiente, **completar el `Real` y los tres errores de la fila
anterior**.

Las tres columnas de error responden preguntas distintas, y hacen falta las tres:

- **Error proyección** — ¿sirve esta skill?
- **Error precantidad** — ¿sirve lo que Ops usó de verdad? Es el número que costó plata.
- **Error semana anterior** — ¿le gana alguno de los dos a no hacer nada?

Con una sola columna no se puede distinguir "el modelo es bueno" de "esta semana fue fácil". Si el
error de la proyección sube consistentemente por encima del 15%, revisar los factores. Si queda por
debajo del 15% pero **por encima** del error de la semana anterior cruda, el problema no son los
factores: es que el ajuste no está aportando.

---

## Limitaciones conocidas

Decirlas en el reporte cuando apliquen:

1. **El espejo no tiene performance operativo de cocinas** (incidencias, rutas tardías, rating). Eso vive en la BD MySQL de producción y requiere VPN. Desde el espejo solo se ve `stores.catering_level` como foto actual, sin histórico semanal.
2. **`status_id` no está documentado** en el espejo — no se sabe con certeza qué estados corresponden a pedidos cancelados. Las proyecciones cuentan **todos** los pedidos. Validar con el Tech Lead si hay que excluir algún estado.
3. **La frecuencia por cliente** se puede calcular con `orders.customer_id`, pero el espejo no trae suscripciones, así que no distingue entre cliente de plan y cliente ocasional.
4. **El modelo no conoce promociones ni campañas de marketing.** Si Marketing lanza algo grande, la proyección se va a quedar corta — conviene preguntarles antes de semanas clave.

---

## Después de entregar

1. Decir al usuario dónde quedó el archivo y **resumir en una línea** el número principal.
2. Recordar que el reporte es un `.md` — se puede pegar directo en Notion o Slack.
3. Si el backtest salió sobre 15% de error, **decirlo explícitamente** en vez de entregar el número sin contexto.
