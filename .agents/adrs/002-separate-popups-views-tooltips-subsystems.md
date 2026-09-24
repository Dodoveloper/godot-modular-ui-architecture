# ADR-002: Views, Popups, And Tooltips Are Separate Subsystems, Not One Unified "Modal" Concept

## Status

Accepted.

## Context

Views (`CapGameUi`), Popups (`CapPopups`), and Tooltips (`CapTooltips`) all "put a `Control` on
top of the game" and could plausibly be collapsed into a single "modal"/"overlay" capability
with mode flags (exclusive vs. stacking vs. anchor-tracked). Evaluating that alternative against
each subsystem's actual guarantees:

- **Views** are addressed by a stable token, are guaranteed exactly one active instance per
  token, own a `context` property that's polled and diffed to notify their own Attachments, and
  compose with Attachment Slots — none of which Popups or Tooltips need.
- **Popups** support parent/child hierarchy, "blocking" children that veto an ancestor's close,
  an optional FIFO queue for popups that shouldn't visually overlap, and dismissal via
  click-outside or `ui_cancel` — none of which apply to a View (a View doesn't have a
  "background" to click outside of) or a Tooltip (never dismissed by input at all).
- **Tooltips** are strictly single-slot (only one shown at a time, enforced by
  `TooltipUiLayer._can_mount_scene`), anchor-tracked with automatic corner/edge placement
  against the available screen rect, and never participate in Context/Attachments/Slots at all.

Each system's mounting rules, dismissal rules, and registries are different enough that a
unified capability would need mode-dependent branches for nearly every method, and any consumer
would still need to know which mode it was really using to call it correctly — the abstraction
wouldn't remove real duplication, it would just relocate the three concerns into one file.

## Decision

Keep `CapGameUi`, `CapPopups`, and `CapTooltips` as three separate capabilities, each with its
own registry (where applicable) and its own service, sharing only the underlying `CapUiLayers`
system for *where* they mount and *how* input reaches them. A consumer picks the capability
that matches the guarantee it actually needs (exclusive-by-token → View; dismissable/stacking
overlay → Popup; anchor-tracked hover → Tooltip) rather than one generic "open modal" call with
mode flags.

## Consequences

- Adding a new UI need should start by asking *which* of the three guarantees it actually
  requires (see [`patterns.md`](../architecture/patterns.md) recipes for each), not by
  defaulting to whichever one was used last.
- Don't add a fourth parallel system for a new set of guarantees without first checking whether
  it's a genuine variant of one of the three (e.g. "a Popup that also has a Slot" is a red flag
  that the request is actually two separate needs, not evidence Popups need Slots).
- Don't attempt to unify these three into one capability "for consistency" — the analysis above
  showed that consolidation increases coupling rather than reducing it. If a real, repeated need
  for shared behavior across all three emerges (e.g. a common "which UI currently has exclusive
  focus" query), extract that specific shared behavior into its own small capability instead of
  merging the three wholesale.
