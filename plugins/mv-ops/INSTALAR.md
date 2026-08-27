# Instalar mv-ops

Skills de Operaciones para Claude Code: **proyección de demanda** (pedidos esperados por día y por
cocina) y **proyección de insumos** (platos a preparar, kilos por ingrediente, empaques y costo).
Entregan reportes en Markdown, no dashboards.

Versión actual: **1.6.2**.

---

## Antes de empezar: lo que sí y lo que no

**Necesitás dos cosas** y sin cualquiera de las dos las skills no operan:

1. Claude Code instalado.
2. Las credenciales del **espejo de datos** (`MV_MIRROR_URL` y `MV_MIRROR_ANON_KEY`). Son de lectura
   solamente. Pedíselas a José Luis o a quien mantenga el datalake — **no están en ningún repo**, y
   con razón.

**No hace falta** ningún acceso al BackOffice ni a la base de producción. Las skills solo leen el
espejo.

---

## ⚠️ Leé esto si ya tenés mv-dev instalado

Los dos plugins viven en repos distintos que **declaran el mismo nombre de marketplace**
(`manzanaverde-plugins`):

| Repo | Trae | Versión de mv-dev |
|---|---|---|
| `manzanaverdelatam/manzanaverde-plugin` | mv-dev | **1.15.0** ← la buena |
| `holamv/manzanaverde-plugin` | **mv-ops** + mv-dev | 1.7.0 ← vieja |

Si agregás el segundo tal cual, pasan dos cosas malas: choca con el nombre del que ya tenés, y te
ofrece un mv-dev **ocho versiones atrasado**.

**La solución es registrarlo con otro nombre.** Está en el Paso 1 de las dos rutas de abajo. Y en
ningún caso instales `mv-dev` desde el repo de `holamv`: si querés mv-dev, va desde
`manzanaverdelatam`.

---

## Ruta A — Claude Code en la terminal

Es la corta. Si usás Claude Code desde la consola, `/plugin` existe y hace todo.

```
/plugin marketplace add holamv/manzanaverde-plugin --name mv-ops-marketplace
/plugin install mv-ops@mv-ops-marketplace
```

Si tu versión de `/plugin marketplace add` no acepta `--name`, usá la Ruta B: no vale la pena pelear
con el nombre desde la interfaz.

Después de instalar, reiniciá Claude Code y seguí en **[Las credenciales del espejo](#las-credenciales-del-espejo)**.

---

## Ruta B — Claude Code dentro de VS Code

Acá `/plugin` **no existe** (responde "isn't available in this environment"), y el reconciliador de
arranque **no instala solo** aunque declares el plugin en `settings.json`: crea la carpeta y no
registra nada, sin avisar. Hay que registrarlo a mano. Son cinco minutos.

### Paso 1 — Clonar el repo con otro nombre de marketplace

```bash
cd ~/.claude/plugins/marketplaces
git clone --depth 1 https://github.com/holamv/manzanaverde-plugin.git mv-ops-marketplace
```

> **`--depth 1` no es opcional.** Sin eso el clone se cuelga en estos repos: crea el `.git`, nunca
> hace checkout y muere a los 2 minutos. Un clone superficial igual acepta `git pull` después.

Ahora editá `mv-ops-marketplace/.claude-plugin/marketplace.json` y cambiale el nombre, para que no
choque con el marketplace de mv-dev:

```json
{
  "name": "mv-ops-marketplace",
  ...
}
```

Y en ese mismo archivo **borrá la entrada de `mv-dev`** de la lista `plugins`, dejando solo `mv-ops`.
Así no hay forma de instalar por accidente el mv-dev viejo.

> Los dos cambios son sobre un archivo versionado, así que **se revierten con cada `git pull`**. Si
> actualizás el marketplace, hay que volver a aplicarlos.

### Paso 2 — Registrarlo

Copiá el plugin a la carpeta de versiones que Claude Code lee:

```bash
mkdir -p ~/.claude/plugins/cache/mv-ops-marketplace/mv-ops/1.6.2
cp -r ~/.claude/plugins/marketplaces/mv-ops-marketplace/plugins/mv-ops/. \
      ~/.claude/plugins/cache/mv-ops-marketplace/mv-ops/1.6.2/
```

Agregá el marketplace en `~/.claude/plugins/known_marketplaces.json`. **Las entradas van en la raíz
del archivo**, no anidadas:

```json
"mv-ops-marketplace": {
  "source": { "source": "github", "repo": "holamv/manzanaverde-plugin" },
  "installLocation": "C:\\Users\\TU_USUARIO\\.claude\\plugins\\marketplaces\\mv-ops-marketplace",
  "lastUpdated": "2026-08-27T00:00:00.000Z"
}
```

Y el plugin en `~/.claude/plugins/installed_plugins.json`. Ojo, este anida distinto: la entrada va
**dentro de la clave `plugins`** (el archivo tiene `version` y `plugins` en la raíz):

```json
"mv-ops@mv-ops-marketplace": [
  {
    "scope": "user",
    "installPath": "C:\\Users\\TU_USUARIO\\.claude\\plugins\\cache\\mv-ops-marketplace\\mv-ops\\1.6.2",
    "version": "1.6.2",
    "installedAt": "2026-08-27T00:00:00.000Z",
    "lastUpdated": "2026-08-27T00:00:00.000Z"
  }
]
```

> En Windows las rutas van con **barras invertidas dobles** (`\\`). Y no edites estos archivos con
> un script de una línea desde la terminal: la shell se come las barras y `\0` se convierte en un
> byte nulo que rompe el JSON en silencio. Editalos con el editor.

Por último, habilitá el plugin en el bloque `enabledPlugins` de `~/.claude/settings.json`:

```json
"mv-ops@mv-ops-marketplace": true
```

**Sin esta línea el plugin queda instalado pero inerte** — no falla, simplemente las skills no
aparecen. Es el olvido más común.

### Paso 3 — Reiniciar

Cerrá y abrí Claude Code. Los plugins se leen al arrancar; no hay recarga en caliente.

---

## Las credenciales del espejo

Hace falta en las dos rutas.

Creá un archivo `.env` en la carpeta desde la que vas a trabajar:

```
MV_MIRROR_URL=<la URL del espejo>
MV_MIRROR_ANON_KEY=<la llave>
```

Las dos te las da José Luis. **No están en este repo a propósito**: es público (es un fork de
`solrac97gr/manzanaverde-plugin`), así que acá no va ni la llave ni la URL del proyecto.

Una variable por línea, **sin comillas** y sin espacios alrededor del `=`. El error más frecuente es
pegar adentro del `.env` la línea completa de PowerShell (`$env:MV_MIRROR_URL = "..."`), que no es
formato `.env`.

---

## Comprobar que quedó bien

```
/proyeccion-demanda Perú
```

Tiene que producir un reporte en `proyecciones/`. Si en cambio decís que sí y no pasa nada, o dice
que no encuentra las credenciales, mirá la tabla de abajo.

| Síntoma | Causa | Qué hacer |
|---|---|---|
| Las skills no aparecen en la lista | Falta la línea en `enabledPlugins` | Paso 2, último bloque, y reiniciar |
| "Falta MV_MIRROR_URL" | El `.env` no está donde corrés Claude, o tiene formato de PowerShell | Ver credenciales del espejo |
| El `git clone` se queda colgado | Falta `--depth 1` | Borrá la carpeta y cloná de nuevo |
| Choca el nombre del marketplace | Ya tenés `manzanaverde-plugins` de mv-dev | Registrá este con otro nombre (Paso 1) |
| mv-dev bajó de versión | Instalaste mv-dev desde el repo de `holamv` | Reinstalá mv-dev desde `manzanaverdelatam` |
| El reporte dice que el histórico no alcanza | El espejo tiene ~19 semanas, no 26 | Es esperado: el reporte informa la ventana real |

---

## Qué esperar del reporte

Dos cosas que conviene saber antes de leerlo, para que no sorprendan:

**Compara contra lo que Ops usó de verdad.** El reporte no solo dice cuánto erró su propia
proyección: también compara la **precantidad que se usó** y el **mismo día de la semana anterior sin
ajuste**. Esa última columna es una referencia a propósito — si el método no le gana a "lo mismo que
la semana pasada", está agregando error en vez de quitarlo, y el reporte lo dice.

**Avisa cuando los datos están incompletos.** Si una de las tablas del espejo deja de cargarse, la
skill lo detecta por la razón platos/pedidos y **para** en vez de proyectar sobre datos parciales.
Si ves ese aviso no es un error de la skill: es el espejo, y hay que avisarle a quien mantenga el
datalake.

---

## Actualizar más adelante

```bash
git -C ~/.claude/plugins/marketplaces/mv-ops-marketplace fetch --depth 1 origin
git -C ~/.claude/plugins/marketplaces/mv-ops-marketplace checkout -B main FETCH_HEAD
```

Después copiá a una carpeta nueva en `cache/mv-ops-marketplace/mv-ops/<versión nueva>/`, actualizá
`version` e `installPath` en `installed_plugins.json`, **volvé a aplicar los dos cambios del
`marketplace.json`** del Paso 1 (el `git pull` los revierte) y reiniciá.

> `git reset --hard` no hace falta y en algunos entornos está bloqueado. `git checkout -B main
> FETCH_HEAD` hace lo mismo y conserva lo que no está versionado.
