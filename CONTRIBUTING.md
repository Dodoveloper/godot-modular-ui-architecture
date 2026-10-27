# Contributing

Thanks for your interest in contributing to Modular UI Architecture.

## Start here

This project maintains its architecture, conventions, and rationale under
[`AGENTS.md`](AGENTS.md) and the [`.agents/`](.agents/) tree — originally written for AI coding
agents, but equally useful as onboarding material for human contributors. Read
[`AGENTS.md`](AGENTS.md) first; it routes to everything else (folder layout, glossary,
architecture walkthrough, style guide, step-by-step recipes for common changes, and the
reasoning behind non-obvious past decisions).

## Before opening a PR

- Follow the conventions in [`.agents/architecture/style-guide.md`](.agents/architecture/style-guide.md).
- If you're adding a new module/View/Popup/Tooltip/Binding, check
  [`.agents/architecture/patterns.md`](.agents/architecture/patterns.md) for the established
  shape first.
- If your change touches something documented in `.agents/`, update the relevant doc in the
  same PR — see [`.agents/PRINCIPLES.md`](.agents/PRINCIPLES.md) for how that documentation is
  meant to stay accurate over time.

## Testing

Unit tests use [GUT](https://github.com/bitwes/Gut) and live under
[`tests/unit/`](tests/unit/). See [`tests/README.md`](tests/README.md) for how to run them and how
to add one.

## Branching / PR process

_TODO: fill in once the project's contribution workflow (branch naming, review process, CI, if
any) is finalized ahead of open-sourcing._
