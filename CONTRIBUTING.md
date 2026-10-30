# Contributing

Thanks for your interest in contributing to Modular UI Architecture! This document covers how to
propose a change, what a good change looks like, and what to check before opening a pull request.

## Before you start

**Discuss substantial changes first.** Open an issue (or a discussion) before working on:

- a new module, capability, or registry, or a change to an existing one's public API;
- a change to the input pipeline, UI Layers, or the Popups/Views/Tooltips split;
- anything that contradicts an [ADR](.agents/adrs/) or a documented rule.

**Small fixes don't need an issue.** Typos, documentation corrections, and minor bug fixes can go
straight to a pull request.

## Pull requests

- All changes go through a pull request. Nothing is pushed directly to the main branch.
- Branch names are free. `type/short-description` (for example `fix/popup-close-timeout`) is a
  convenient default, but not required.
- Keep a PR focused on one problem or need. Don't mix in unrelated refactors or formatting changes.
- Fill in the [PR template](.github/PULL_REQUEST_TEMPLATE.md).

### Scope

A change should:

- address a clearly defined problem or need;
- follow the architecture: consumers depend on `Cap*` contracts, not services or registries, and
  new behaviour follows the [patterns](.agents/architecture/patterns.md) recipes;
- leave unrelated code alone.

Don't modify `addons/godular` or `addons/gdb_promise` in a feature PR. They are vendored
dependencies. Upgrades are a separate change.

## Commit messages

It is not mandatory, but recommended to use
[Conventional Commits](https://www.conventionalcommits.org/) with one of these prefixes:

| Prefix | Use for |
|--------|---------|
| `feat` | A new feature or user-visible capability. |
| `fix` | A bug fix. |
| `improvement` | A refactor, tidy-up, or behaviour tweak that isn't a bug fix. |
| `docs` | Documentation only. |
| `test` | Tests only. |
| `chore` | Project files, tooling, or maintenance. |
| `wip` | Work in progress. Squash or reword before the PR is merged. |

A scope is optional, for example `fix(popups): ...`. Keep the subject short and in the imperative.

## Conventions

Follow the coding and naming conventions in these documents:

- [Project conventions](docs/reference/conventions.md): file suffixes, folder layout, and naming.
- [Style guide](.agents/architecture/style-guide.md): GDScript rules, imports, and tooling pitfalls.
- [Patterns](.agents/architecture/patterns.md): step-by-step recipes for modules, Views, Popups,
  Tooltips, Bindings, and Attachments.

## Documentation

Behaviour changes ship with their documentation, in the same pull request:

- User-facing behaviour: update the relevant page under [`docs/`](docs/README.md), such as a guide,
  a reference page, the cookbook, or the FAQ. If you add a demo module, update the
  [demo tour](docs/getting-started/04-demo-tour.md).
- Architecture, structure, or conventions: update the relevant page under
  [`.agents/`](.agents/PRINCIPLES.md).
- A non-obvious decision: add or update an [ADR](.agents/adrs/).

See [`.agents/PRINCIPLES.md`](.agents/PRINCIPLES.md) for how this documentation is kept accurate.

## Tests and the demo

- Add or update [GUT](https://github.com/bitwes/Gut) tests under [`tests/unit/`](tests/unit/) for
  any logic you change. See [`tests/README.md`](tests/README.md) for how to run them and how to write
  one.
- Run the full suite and make sure it passes:

  ```sh
  godot --headless --path . -s addons/gut/gut_cmdln.gd
  ```

- Run the demo (`demo/content/levels/main.tscn`) and check the parts your change touches. The demo is
  the integration check for the addon, so a change that breaks it isn't ready.

## License

By contributing, you agree that your contribution is licensed under the project's [MIT License](LICENSE).

## AI-assisted contributions

AI tools are welcome, as they are in this project. You are responsible for the code you submit: read
it, understand it, and test it before you open a PR. Say in the PR if a substantial part was
AI-generated.
