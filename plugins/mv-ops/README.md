# mv-ops — Skills de Operaciones

Plugin para el equipo de Operaciones de Manzana Verde. No trae hooks ni servidores MCP:
son skills que producen **reportes en Markdown**, listos para pegar en Notion o Discord.

## Skills

| Skill | Para qué sirve | Cómo se pide |
|---|---|---|
| `proyeccion-demanda` | Pedidos esperados por día y por cocina, con ajuste por feriados y registro de acierto | "proyección de pedidos", "cuántos pedidos esperamos", "precantidades" |
| `proyeccion-insumos` | Cuántos platos preparar y cuántos kilos de cada ingrediente comprar, con merma, empaques y costo | "cuánto comprar", "lista de compras", "explosión de recetas" |

`proyeccion-insumos` necesita el **menú planificado de la semana** como entrada: el espejo
de datos no relaciona pedidos con platos, así que ese dato lo aporta Operaciones.

## Instalación

```
/plugin marketplace add holamv/manzanaverde-plugin
/plugin install mv-ops
```

## Configuración — obligatoria antes del primer uso

Las dos skills leen del espejo de datos de MV en Supabase, en **solo lectura**. Hacen falta
dos variables de entorno. Pídeselas al Tech Lead.

Windows (PowerShell) — `notepad $PROFILE` y agregar:

```powershell
$env:MV_MIRROR_URL      = "https://<proyecto>.supabase.co/rest/v1"
$env:MV_MIRROR_ANON_KEY = "<anon key>"
```

macOS / Linux — en `~/.zshrc` o `~/.bashrc`:

```bash
export MV_MIRROR_URL="https://<proyecto>.supabase.co/rest/v1"
export MV_MIRROR_ANON_KEY="<anon key>"
```

Después hay que **reiniciar Claude Code**: las variables se leen al arrancar.

> Nunca pegues estas credenciales en el chat ni las escribas dentro de un reporte.

## Mantenimiento

El **calendario de feriados** es lo único que hay que mantener a mano. Feriados nuevos,
puentes decretados y cierres programados se agregan a la sección de calendario de
`skills/proyeccion-demanda/SKILL.md` en cuanto se conocen. Es la única información que la
proyección no puede deducir de los datos, y es donde el proceso manual perdió por más margen.

## Límites conocidos

- Las ciudades de volumen chico (Piura, Monterrey, Guadalajara) no bajan del 10% de error:
  con 20-80 platos por día el azar pesa demasiado. Salen marcadas en amarillo y se revisan
  antes de cargar.
- Un evento operativo no registrado (un cierre imprevisto, un corporativo que se cae) no lo
  anticipa ninguna proyección.
