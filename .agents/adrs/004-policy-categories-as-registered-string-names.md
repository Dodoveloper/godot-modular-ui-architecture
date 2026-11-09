# ADR-004: Policy Categories Are Registered `StringName` Tokens, Not An Enum

## Status

Accepted. This is a breaking change, shipped in addon version 2.0.0.

## Context

Policy Store categories were a GDScript enum, `PolicyStoreTypes.Category`, defined in the addon's
`types.gd`. A project that needed its own category had to edit that file. The edit was lost on an
addon upgrade, and the category couldn't be declared by the project's own module.

GDScript enum members are fixed at compile time in the script that declares them. Another script
can't add members to an existing enum. So any design that keeps an enum either leaves projects
editing the addon, or needs a placeholder value such as `CUSTOM + n`. A placeholder gives no name
and no protection against a wrong number.

Alternatives considered:

- **A project setting or a Resource listing categories.** This centralizes categories in one place
  that is not owned by a module. Removing a module would leave its category behind, which goes
  against how the addon treats module contributions everywhere else. It also needs an editor plugin
  script, since the addon's `plugin.cfg` had none.
- **One `PolicyCategory` Resource per category.** This needs a resource reference at every call
  site and is heavier than a token. It also brings in Resource identity questions for no gain over
  a name.
- **An enum with a catch-all offset.** This is unreadable and unsafe, as described above.

The addon already has the pattern this change reuses. A module contributes Views, Attachments and
Input Bindings through a registry capability (`CapViewsRegistry`, `CapUiAttachmentsRegistry`,
`CapInputBindingsRegistry`), in `register()`. Godular runs every module's `register()` before any
`enable()`, so a category registered there exists before any module blocks or checks it.

## Decision

- A category is a `StringName` token. The addon ships no categories. A project declares each one from
  one of its own modules. The demo's `policies` module declares `OPEN_GAMEPLAY_POPUP_UI`.
- `CapPolicyCategoriesRegistry` stores the registered tokens. A module registers its categories in
  `register()`, the same way it registers Views.
- `CapPolicyStore` validates each category against the registry. An unregistered category pushes an
  error. `block()` and `unblock()` then do nothing, `is_allowed()` returns `true`, and
  `get_blockers()` returns an empty array.
- Duplicate and empty tokens are rejected with an error when registered.

The unregistered-category rule is deliberate. A `StringName` can't be checked at compile time, so a
typo could otherwise block nothing and fail silently. An error makes the typo visible at its first
use.

## Consequences

- **Typos are caught at runtime, not compile time.** The enum gave autocomplete and a parse-time
  error for an unknown member. A project's token holder can be a `const` dictionary, which fails at
  runtime on a typo, or module-level `const` tokens, which fail to parse. Either way, a raw string
  literal at a call site still needs review.
- **Don't revert to an enum to get back compile-time checks.** That would reintroduce the
  "edit the addon" limitation this change removed.
- **Keep the registry as the only source of truth for categories.** Don't add a second, hardcoded
  list of valid categories in the service. `is_allowed()` depends on the registry being the one
  place that answers "is this registered?".
- **Unregistering drops blocks through a signal, not a sweep.** `CapPolicyCategoriesRegistry` emits
  `category_unregistered`, and the service erases that category's blockers. A lazy check on the next call
  would miss a category that is unregistered and registered again before any call. The test
  `test_unregister_without_a_store_call_still_drops_blockers_on_reregister` covers that case.
- **A declarative layer is a possible future step, not built.** A project-wide list of categories,
  for example from a Resource or a project setting, could be added on top of the registry without
  changing this design. It was deferred, because modules are how the addon already contributes
  things.
- **The addon stays category-free.** Categories belong to the project, so a category never goes into
  the addon. `PolicyStoreModule` registers nothing.
