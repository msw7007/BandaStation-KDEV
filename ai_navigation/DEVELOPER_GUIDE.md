# Developer Guide

Generated 2026-05-21. For **humans** handing `BandaStation-Kagelite_DEV` to an AI agent. (Русская версия ниже.)

## What This Is

`ai_navigation/` is a routing layer for AI agents working on this repository. It lets an agent localise a task to the right files fast, instead of scanning the whole codebase. It is a routing aid, **not** a source of truth — the agent must still verify against `code/**` and `modular_bandastation/**`.

"AI navigation" here means these docs. It does **not** mean in-game maps (`_maps/`, `SSmapping`).

## Start Modes

| You want... | Tell the agent to start at |
|---|---|
| an ordinary task done | `ai_navigation/router.md` (Fast Start) |
| broad / risky / multi-system work | `ai_navigation/AGENTS.md` (Guided Start) |
| the navigation layer refreshed or migrated | `ai_navigation/update_policy.md` (Maintenance Start) |

## Minimum Handoff (2 messages)

1. **Message 1 — the goal.** What you want, plainly.
2. **Message 2 — the repo + entrypoint.** "This is BandaStation-Kagelite_DEV. Start at `ai_navigation/router.md`."

For risky work, add: "Classify the change with `ai_navigation/human_checking.md` and get my approval on the blast radius before editing."

## What The Agent Should Do

- Route via `ai_navigation/router.md` → one helper → 2-3 source files.
- Check `modular_bandastation/` for an override before concluding anything.
- Verify against source; if docs and code disagree, trust the code and tell you.
- Classify risk before edits; stop for approval on medium/high-risk changes.
- Not edit game code, `tgstation.dme`, or include lines unless that is the explicit task.

## Good Task Brief Pattern

State: the goal, the symptom or feature, any constraint (keep it local / no refactor), and whether you want to see a diff before it applies. Copy-paste templates: `ai_navigation/task_templates.md`.

---

# Руководство разработчика

Для **людей**, передающих репозиторий `BandaStation-Kagelite_DEV` ИИ-агенту.

## Что это

`ai_navigation/` — это слой маршрутизации для ИИ-агентов. Он помогает агенту быстро найти нужные файлы, не сканируя весь репозиторий. Это вспомогательный слой, **а не источник истины** — агент обязан сверяться с `code/**` и `modular_bandastation/**`.

«AI navigation» — это данные документы. Это **не** игровые карты (`_maps/`, `SSmapping`).

## Режимы старта

| Что нужно | С чего агент начинает |
|---|---|
| обычная задача | `ai_navigation/router.md` (Fast Start) |
| широкая / рискованная / многосистемная работа | `ai_navigation/AGENTS.md` (Guided Start) |
| обновление или миграция navigation-слоя | `ai_navigation/update_policy.md` (Maintenance Start) |

## Минимальная передача (2 сообщения)

1. **Сообщение 1 — цель.** Что нужно сделать.
2. **Сообщение 2 — репозиторий и точка входа.** «Это BandaStation-Kagelite_DEV. Начни с `ai_navigation/router.md`.»

Для рискованной работы добавьте: «Классифицируй изменение через `ai_navigation/human_checking.md` и получи моё подтверждение по объёму правок до редактирования».

## Что агент должен делать

- Маршрутизироваться через `ai_navigation/router.md` → один helper → 2-3 файла исходников.
- Проверять `modular_bandastation/` на наличие override перед выводами.
- Сверяться с кодом; при расхождении доверять коду и сообщать вам.
- Классифицировать риск до правок; останавливаться для подтверждения на medium/high-risk.
- Не менять игровой код, `tgstation.dme` и include-строки без явной задачи.

Шаблоны постановки задач: `ai_navigation/task_templates.md`.
