# Core Principles

These principles govern how durable documentation under `.agents/` is written and maintained.
User-facing documentation under `docs/` is written for humans, and follows the same evidence rules
where it states behaviour. They apply to every file in this tree — individual
docs should link here instead of restating them.

## Evidence Before Guidance

Do not add or change durable guidance unless the need is proven by current repo evidence
(source code, config, tool output, official upstream docs) or explicit human direction.

Verify hard claims before writing them into guidance: paths, class/method names, behavior of
Godot/Godular/this addon's own systems, and status of in-progress work. If a claim rests on a
file name, a partial read, or an older design doc rather than a full inspection, say so
explicitly (e.g. "design doc says X; current code does Y").

## Durable Docs Must Stand Alone

Write for a future reader who was not in the conversation that produced the doc. Avoid phrases
like "this session", "we just decided", "for now", or "the old version" unless the doc defines
that context itself. An ADR is the one place session-specific narrative belongs — see
[`adrs/`](adrs/).

## Keep Guidance Small And Routed

`AGENTS.md` and `navigation.md` are maps, not manuals — they route to detail, they don't contain
it. Put local detail in the scoped doc that owns it (`core.md`, `style-guide.md`,
`patterns.md`, an ADR), only once that scope has a proven, repeated need for it.

## One Durable Fact, One Owner

Don't duplicate the same fact across docs. Put it in the narrowest correct owner and link to it
from anywhere else it's relevant (as this file is linked from every doc's "when to update"
section, instead of each restating these rules).

## Prefer Current Behavior, Preserve Intended Policy

Code shows current behavior. ADRs and explicit human confirmation show intended policy. The
project's design docs (`Modular UI Component Types`, `Modular UI System Implementation`) show
*original* intended policy, which is not always current — they're discovery context, not
authoritative on their own (see below).

Don't treat existing code as a best-practice template just because it exists. When current
code and a design doc/ADR disagree, don't silently pick one — record the gap explicitly (see
`glossary.md`'s `Context` entry and `core.md`'s Element/Widget note for examples of this done
correctly) so a future agent can resolve it deliberately instead of re-discovering the
discrepancy from scratch.

## Historical Material Is Discovery Context, Not Authority

The two design PDFs referenced across this tree, superseded ADR entries, and old plans can help
locate claims to verify — they are not themselves sources of truth. Re-verify anything they say
against current code, current config, or explicit human confirmation before writing it into
guidance as fact.

## Advice Must Change Future Behavior

Only keep a doc, rule, or checklist entry if a future human or agent will make a measurably
better decision because it exists. If a section wouldn't change what anyone does differently,
cut it rather than let it accumulate.

## Humans Are Not Responsible For Agent Artifacts

Humans may work in this repo normally without maintaining `.agents/`. Agents should repair
agent-facing guidance opportunistically when they notice it's gone stale, as part of whatever
task surfaced the staleness — not as a favor asked of the human.
