# 🥗 Instalación del plugin de Manzana Verde en Claude Code

Este repositorio es **privado**. Para instalar el plugin necesitas dos cosas:

1. Acceso al repositorio `manzanaverdelatam/manzanaverde-plugin` en GitHub (pídelo a tu líder si no lo tienes).
2. Credenciales de git configuradas en tu máquina (paso 1 abajo).

Claude Code usa tus credenciales de git existentes para clonar repos privados, así que una vez configurado git, todo funciona igual que con un repo público.

---

## 1. Configura tu autenticación con GitHub (solo la primera vez)

**Opción A — GitHub CLI (recomendada):**

```bash
# Instala gh si no lo tienes: https://cli.github.com
gh auth login
gh auth setup-git
```

> `gh auth setup-git` es importante: configura el credential helper para que Claude Code pueda autenticarse también en las actualizaciones automáticas en segundo plano.

**Opción B — SSH:**

Si ya usas SSH con GitHub (`git clone git@github.com:...` te funciona), no necesitas nada más. Verifica con:

```bash
ssh -T git@github.com
# Debe responder: "Hi <tu-usuario>! You've successfully authenticated..."
```

---

## 2. Variables de entorno recomendadas

Agrega esto a tu `~/.zshrc` o `~/.bashrc`:

```bash
# Evita que el plugin deje de funcionar si falla una actualización en segundo plano
export CLAUDE_CODE_PLUGIN_KEEP_MARKETPLACE_ON_FAILURE=1

# Solo si usas HTTPS (Opción A) y NO tienes SSH configurado:
export CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1
```

Recarga tu shell después (`source ~/.zshrc`).

> **¿Por qué?** El shorthand `owner/repo` clona por SSH por defecto. Si solo tienes HTTPS configurado, sin `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1` el clone puede fallar. Y como el repo es privado, las actualizaciones automáticas en segundo plano pueden fallar intermitentemente — `KEEP_MARKETPLACE_ON_FAILURE` hace que el plugin siga funcionando con la última versión sincronizada.

---

## 3. Agrega el marketplace e instala el plugin

Dentro de Claude Code:

```
/plugin marketplace add manzanaverdelatam/manzanaverde-plugin
```

O desde la terminal:

```bash
claude plugin marketplace add manzanaverdelatam/manzanaverde-plugin
```

Luego instala el plugin:

```
/plugin install manzanaverde@manzanaverde-plugin
```

> Si el nombre del plugin o del marketplace difiere, corre `/plugin` para ver el listado disponible después de agregar el marketplace.

---

## 4. Verifica la instalación

```
/plugin
```

Deberías ver el marketplace `manzanaverde-plugin` y el plugin instalado y habilitado. Los comandos y skills del plugin ya estarán disponibles en tu sesión.

---

## Actualizar el plugin

Las actualizaciones se sincronizan automáticamente, pero puedes forzarlas manualmente:

```
/plugin marketplace update manzanaverde-plugin
/plugin update manzanaverde@manzanaverde-plugin
```

---

## Solución de problemas

| Problema | Solución |
|---|---|
| `Authentication failed` al agregar el marketplace | Verifica acceso al repo en GitHub y corre `gh auth setup-git` (HTTPS) o revisa tu `ssh-agent` (SSH) |
| El clone falla y solo tienes HTTPS | Exporta `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1` y reintenta |
| El plugin desaparece o falla tras un tiempo | Asegúrate de tener `CLAUDE_CODE_PLUGIN_KEEP_MARKETPLACE_ON_FAILURE=1` y corre `/plugin marketplace update` manualmente |
| `Repository not found` | No tienes acceso al repo privado — pide que te agreguen a la organización `manzanaverdelatam` |

---

📚 Documentación oficial: https://code.claude.com/docs/en/plugin-marketplaces
