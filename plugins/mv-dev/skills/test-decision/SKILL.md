---
name: test-decision
description: Decide QUÉ test crear y CUÁNDO (y cuándo NO) para un cambio en un repo MV — clasificador BUG/BET/RESUME + matriz change-type x superficie + mock-vs-real. Fuente única; mv-testing sigue siendo el "cómo".
---

# Test Decision Rubric (MV)

> Esta skill decide **qué/cuándo testear**. Para **cómo** escribir el test → `/mv-dev:mv-testing`.

## 1. Clasificación del cambio (BUG / BET / RESUME)

- **BUG** — restaura comportamiento definido, o cambio trivial/determinista sin decisión de producto (copy/color/config).
- **BET** — capacidad nueva.
- **RESUME** — delta sobre algo en proceso.

## 2. Matriz change-type × superficie → test

| Change-type | Superficie | Test a crear |
|---|---|---|
| BUG (defecto) | cualquiera | **Test de regresión del defecto puntual** (reproduce→fix→green). Si la superficie es flujo crítico → reproducción Playwright. NADA de tests de feature nueva. |
| BUG trivial | copy/color/style/config/doc | **Ninguno** (excepción legítima). |
| BET / RESUME | flujo crítico (pago/pedido/registro/login) | **Playwright E2E happy + 1 sad path** (+ staging/sandbox, ver mock-vs-real). |
| BET / RESUME | función pura / util / Zod | **Jest unit.** |
| BET / RESUME | Componente React con comportamiento (props que cambian el render, estados, condicionales, interacción del usuario) | **RTL** (+ MSW si hace fetch). |
| BET / RESUME | Componente puramente presentacional (markup estático desde props, sin estados ni ramas) | **Ninguno** (o snapshot ligero opcional). |
| BET / RESUME | endpoint Express | **supertest integration** (+ E2E si participa de un flujo de pago/pedido). |
| cualquiera | copy / color / estilo / config / doc | **Ninguno.** |

## 3. Mock vs real

| Flujo | Backend | Auth | PSP | Razón |
|---|---|---|---|---|
| Pago/checkout | staging real | seed user PE/MX/CO, login programático | **sandbox del PSP** (nunca prod) | validar integración sin costo |
| Registro | staging real | **bypass OTP** (env) | n/a | matar el SMS manual |
| Pedido | staging real | seed user con plan activo | n/a | no tocar checkout |
| Endpoint solo | supertest/fetch | bearer JWT seed | postear `payment_id` sandbox | más rápido |
| Componente presentacional | mock total (MSW/`page.route`) | mock | mock | no pegarle a staging por un componente sin comportamiento |
| Función pura | n/a | n/a | n/a | unit puro |

**Regla de oro:** *"Si el bug aparecería SOLO con backend/PSP real → el test habla con backend/PSP real (staging+sandbox). Si aparecería igual con mock → mockear es válido."*

## 4. Cobertura primero

Antes de escribir, `grep` en `tests/ __tests__/ *.spec.ts *.test.ts *.feature` por la superficie afectada; correr baseline verde; **solo escribir lo que falta**. No duplicar.

## 5. Cuándo NO testear

- Copy/estilo fuera de flujo crítico.
- Doc-only.
- Cuando Carlos diga explícito *"no agregues test, solo el fix"* (reportar traza en el resumen).
