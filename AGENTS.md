# Agent Guide

This repo is a Godot 4.7 addon — **Modular UI Architecture** — an opinionated set of runtime
systems for building modular, reusable, extensible UI in Godot, built on top of
[Godular](addons/godular/README.md) (a DI/module framework) and
[GdbPromise](addons/gdb_promise/README.md) (a promise library). It ships alongside a `demo/`
project that exercises every system with a small playable scene.

This file is a router, not the documentation itself. Read the linked file(s) relevant to your
task **before** exploring the codebase — they exist specifically so you don't have to rediscover
the same structure and gotchas every session.

## Where to go

| I need to...                                              | Read                                                |
|-------------------------------------------------------------|------------------------------------------------------|
| Know how `.agents/` docs should be written/maintained        | [`.agents/PRINCIPLES.md`](.agents/PRINCIPLES.md)     |
| Find where something lives / understand folder layout       | [`.agents/navigation.md`](.agents/navigation.md)     |
| Understand a term (Module, Capability, View, Attachment...) | [`.agents/architecture/glossary.md`](.agents/architecture/glossary.md) |
| Understand how the systems fit together                     | [`.agents/architecture/core.md`](.agents/architecture/core.md) |
| Follow naming/file conventions, avoid tooling pitfalls       | [`.agents/architecture/style-guide.md`](.agents/architecture/style-guide.md) |
| Add a module/View/Popup/Tooltip/Binding — step by step       | [`.agents/architecture/patterns.md`](.agents/architecture/patterns.md) |
| Understand *why* a non-obvious decision was made             | [`.agents/adrs/`](.agents/adrs/)                     |

## Non-negotiable rules

1. **Read `navigation.md` and the relevant `patterns.md` recipe before adding or moving files.**
   This project has a strict, repeated folder shape per module; don't improvise a new one.
2. **Use the Godot MCP tools (or the Godot editor) for `.tscn`/node changes when available.**
   Hand-editing scene files is error-prone (see the style guide's note on UID stripping) and
   should be a fallback, not the default.
3. **Check `.agents/adrs/` before "fixing" something that looks wrong in the input/UI-layer
   pipeline or in the Popups/Views/Tooltips split.** Both have been the source of subtle,
   already-debugged bugs — re-reverting them will reintroduce those bugs.
4. **Ask before assuming**, especially around Godot's input pipeline (`_input` vs. GUI focus
   phase vs. `_unhandled_input`) and Godular's DI resolution order — both have non-obvious
   behavior that has already caused real regressions in this project.
5. **Follow [`.agents/PRINCIPLES.md`](.agents/PRINCIPLES.md) whenever creating or editing
   anything under `.agents/`** (or under `docs/`) — evidence before guidance, one fact one
   owner, no session-specific phrasing outside of ADRs.
6. **Update the docs in the same change as the behaviour.** A feature or behaviour change updates
   the matching page in `docs/` (user-facing), and any affected `.agents/` page (architecture,
   conventions, structure). Follow [`.agents/PRINCIPLES.md`](.agents/PRINCIPLES.md#docs-ship-with-the-change).
