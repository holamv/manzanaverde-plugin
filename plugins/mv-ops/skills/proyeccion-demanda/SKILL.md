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
| `proyecciones/HISTORIAL.md` | Acumulado de proyectado vs. real, con % de error |

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
| `stores` | `store_id, store_name, city, country, country_id, cocina_id, catering_level, is_active, business_type` | Cocinas / tiendas |
| `customers` | `id, nombre, email, telefono, pais, plan_actual, created_at` | Frecuencia por cliente |
| `meals` | `meal_id, meal_name, protein_type, is_star, food_cost_local, calories, ...` | Mix de platos |

### ⚠️ Trampas conocidas

1. **`orders.catering_id` corresponde a `stores.store_id`** — no existe tabla `caterings`. Este es el join correcto.
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

Un request por día, en paralelo (8 hilos), leyendo `Content-Range`:

```
GET {MV_MIRROR_URL}/orders?select=id&catering_id=in.(id1,id2,...)&fecha=gte.2026-01-01&fecha=lt.2026-01-02
Headers: Prefer: count=exact | Range: 0-0
```

26 semanas = 182 requests. Es rápido y es la forma correcta dado el límite de agregaciones.

### Paso 4 — Calcular la línea base por día de semana

Para cada día de la semana, sacar la **mediana** de las últimas 26 semanas
(mediana, no promedio: resiste feriados y outliers).

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
factor_feriado = 0.25   # feriado nacional (caída ~75%)
factor_puente  = 0.60   # día laboral pegado a un feriado
```

Ver el calendario más abajo.

### Paso 6 — Aplicar tendencia

Comparar el promedio de las últimas 4 semanas **sin feriados** contra las 4 anteriores.
Aplicar el delta de forma suave. Referencia Perú: **−5.3% semestral** (declive leve).

### Paso 7 — Proyectar por cocina

Repartir el total proyectado según la participación de cada cocina en las últimas 4 semanas.
Si una cocina tiene `is_active = false`, excluirla de la proyección futura y decirlo en el reporte.

### Paso 8 — Validar antes de entregar

Correr un backtest rápido: proyectar las últimas 4 semanas con este mismo método y comparar con lo real.
**Si el MAPE supera 15%, no entregar el reporte sin una advertencia explícita** de que el modelo está fuera de rango.

---

## Calendario de feriados — Perú

| Fecha | Feriado | Factor |
|---|---|--:|
| 1 ene | Año Nuevo | 0.25 |
| Jueves y Viernes Santo | Semana Santa (móvil) | 0.25 |
| 1 may | Día del Trabajo | 0.25 |
| 29 jun | San Pedro y San Pablo | 0.25 |
| 28–29 jul | Fiestas Patrias | 0.25 |
| 30 ago | Santa Rosa de Lima | 0.25 |
| 8 oct | Combate de Angamos | 0.25 |
| 1 nov | Todos los Santos | 0.25 |
| 8 dic | Inmaculada Concepción | 0.25 |
| 25 dic | Navidad | 0.25 |

**Verificar cada año** (hay feriados que se agregan por ley, como 6 ago y 9 dic; en 2026 el 6 de agosto mostró una caída de 40%).

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

## ⚠️ Los factores de caída de México y Colombia todavía NO están medidos

El `0.25` de la tabla de Perú **no se puede copiar a los otros dos países**: salió de medir los
feriados peruanos contra su propia línea base. Aplicarlo a Bogotá o CDMX sería inventar.

Mientras no estén medidos, para México y Colombia:

1. Marcar el día como feriado en el reporte y **decir explícitamente que el factor es estimado**.
2. Sacar el factor de la propia historia, feriado por feriado:
   `factor = pedidos_reales_del_feriado ÷ mediana_de_ese_día_de_semana`
   sobre los feriados de 2026 que ya pasaron. En Colombia hay doce; en México, cuatro.
3. Guardar el factor medido en esta tabla y anotar sobre cuántas observaciones se calculó.

Un feriado con factor inventado es peor que un feriado sin factor: el reporte se ve preciso y no lo es.

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

## Acierto de la proyección anterior

| Semana | Proyectado | Real | Error |
|--------|-----------:|-----:|------:|
| {semana previa} | 3,601 | 3,540 | 1.7% |

## Cómo se calculó

Mediana de las últimas 26 semanas por día de semana, ajustada por feriados y tendencia.
Precisión histórica del método: ~7% de error.
Fuente: espejo de datos MV (solo lectura), sincronizado al {synced_at}.
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
| Semana | Proyectado | Real | Error | Notas |
|--------|-----------:|-----:|------:|-------|
| 2026-08-10 | 3,540 | — | — | Pendiente de cierre |
```

Al generar el reporte de la semana siguiente, **completar el `Real` y el `Error` de la fila anterior**.
Este historial es lo que permite saber si el modelo se está degradando: si el error sube consistentemente por encima del 15%, hay que revisar los factores.

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
