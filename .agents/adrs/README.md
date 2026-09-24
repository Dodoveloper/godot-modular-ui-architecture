# Architecture Decision Records

Each ADR here records a non-obvious decision, the concrete problem it solved, and the
consequences of reverting it — written so a future agent doesn't rediscover the same bug by
"simplifying" the code back to what looks more obvious. See
[`PRINCIPLES.md`](../PRINCIPLES.md#durable-docs-must-stand-alone) for how these differ from the
other docs in this tree: an ADR is allowed to carry session-specific incident narrative in its
Context section, because that narrative *is* the evidence for the decision.

| # | Title | Summary |
|---|-------|---------|
| [001](001-ui-layer-input-broadcast-ordering.md) | `UiLayerNode` input broadcast ordering | Why input broadcasting is split between `_input` (focus-nav-colliding actions only) and `_unhandled_input` (everything else), instead of using one phase for everything. |
| [002](002-separate-popups-views-tooltips-subsystems.md) | Separate Views/Popups/Tooltips subsystems | Why these three UI-mounting systems were kept independent instead of unified into one "modal" capability. |

## When To Add A New ADR

See [`PRINCIPLES.md`](../PRINCIPLES.md) for the general rules that apply to every doc in this
tree. Add a new ADR (numbered sequentially) when:

- a decision reverses or significantly narrows/widens something documented elsewhere in
  `.agents/` (e.g. `core.md`, `patterns.md`) and future agents need to know *why*, not just
  *what*, to avoid re-reverting it
- a bug was caused by "obvious" code that turned out to be wrong for a non-obvious reason (the
  fix alone, without the reasoning, invites the same mistake again)
- a design alternative was seriously considered and rejected for reasons that aren't visible
  from the code alone (e.g. ADR-002's "why not unify these three systems")

Don't write an ADR for a decision that's fully explained by reading the code, and don't use an
ADR as a substitute for updating `core.md`/`patterns.md`/`style-guide.md` themselves — link
between them instead of duplicating (update the index table above when adding one).
