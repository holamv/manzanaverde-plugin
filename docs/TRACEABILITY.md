# Trazabilidad código → CR → experiment → KPI

> Fase 1 del PRD `crear-prd` (mv-dev). Esta es la convención; el gate que la
> endurece llega en fases posteriores. Hoy es una **convención con warning**, no
> un bloqueo.

## Por qué existe

El Company Brain sincroniza cuatro capas: **datalake ↔ Notion ↔ Discord**. El
Brain sabe qué iniciativa se creó y qué KPI declaró, pero **el repo no está en el
bucle**: no sabe qué código implementó esa iniciativa. La correlación "qué acción
movió qué métrica" se corta antes del commit.

Esta convención cierra ese bucle hasta el repo. Con el trailer `CR:` en los
commits, un PR mergeado puede vincularse al Change Request, al experiment y, por
transitividad, al KPI que declaró — de modo que `informe-resultados` puede
reportar no solo "el KPI se movió 2pp" sino **qué PRs lo causaron**.

## La convención

| Pieza | Formato | Ejemplo |
|---|---|---|
| Branch | `cr/<cr_id>-<slug>` | `cr/CR-0421-fix-checkout-mx` |
| Commit trailer | `CR: <cr_id>` (y opcional `Exp: <exp_id>`) | `CR: CR-0421` |
| PR body | bloque de trazabilidad con `CR`, `Experiment`, `PRD`, `KPI` | ver template de PR |

### Branch

Prefijo `cr/` seguido del `cr_id` y un slug corto y descriptivo en kebab-case:

```
cr/CR-0421-fix-checkout-mx
cr/CR-0388-nuevo-endpoint-planner
```

El prefijo `cr/` es el que, a partir de la Fase 3, hará que el hook pase de
warning a fallo. Un branch **sin** ese prefijo sigue siendo permisivo.

### Commit trailer

El trailer va en el **cuerpo** del commit, con formato de
[Git trailer estándar](https://git-scm.com/docs/git-interpret-trailers): última
línea (o últimas líneas), `Clave: valor`, separadas del cuerpo por una línea en
blanco.

```
fix: corrige el redondeo del total en el checkout de MX

El total mostraba centavos de más por un floor mal ubicado.

CR: CR-0421
Exp: EXP-0198
```

`CR:` es obligatorio para cerrar la cadena. `Exp:` es opcional y solo aplica
cuando el trabajo está vinculado a un experiment.

### PR body

El template de PR (tanto `.github/pull_request_template.md` como
`plugins/mv-dev/templates/pr-template.md`) incluye un bloque de trazabilidad al
inicio. Completá cada campo o marcá `n/a` con la razón:

```markdown
## Trazabilidad

- **CR:** CR-0421
- **Experiment:** EXP-0198
- **PRD:** docs/prd/CR-0421.md
- **KPI:** kpi_def_delivery_speed
```

## Ejemplos: commit bien y mal formado

**Bien formado** — el trailer está en su propia línea, con la clave correcta:

```
feat: agrega banner de promo en la home

CR: CR-0512
```

```
fix: evita doble cobro en membership_charges

CR: CR-0477
Exp: EXP-0210
```

**Mal formado** — no lo detecta el hook:

```
fix: evita doble cobro (CR-0477)        ← el id va en el subject, no como trailer
```

```
CR CR-0477                              ← falta el ':' del trailer
```

```
Ref: CR-0477                            ← clave equivocada; debe ser 'CR:'
```

## Qué valida el hook hoy (Fase 1)

`plugins/mv-dev/scripts/validate-pre-push.sh` inspecciona los commits que se van a
pushear (`@{upstream}..HEAD`) y busca al menos un trailer `CR: <id>`. Si no lo
encuentra, emite un **warning** a stderr con el prefijo `[trazabilidad]` y
continúa: en Fase 1 **nunca bloquea el push**.

El endurecimiento a fallo —y solo para ramas con prefijo `cr/*`— es parte de una
fase posterior del PRD, una vez validado el estándar en uso.
