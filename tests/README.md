# Tests

Unit tests for `addons/modular_ui_architecture/`, written with
GUT 9.7.1 ([docs](https://gut.readthedocs.io/en/latest/index.html)). Tests cover the addon's logic and its node behaviour;
they do not cover visuals, animation or real window focus (the `demo/` project covers those).

## Run the tests

Requires Godot 4.7 on the command line. From the repo root:

```sh
godot --headless --path . -s addons/gut/gut_cmdln.gd
```

The configuration is in [`.gutconfig.json`](../.gutconfig.json): it discovers every `test_*.gd`
under `res://tests/unit/`. The run prints a summary and exits non-zero on failure.

To run a single file:

```sh
godot --headless --path . -s addons/gut/gut_cmdln.gd -gselect=test_popups_service -gexit
```

## Layout

```
tests/
├── unit/                 # test scripts, mirroring addons/modular_ui_architecture/
│   ├── shared/           # shared/classes helpers
│   └── modules/<name>/   # one folder per module
├── fixtures/             # reusable scenes and scripts used by tests (not tests themselves)
│   ├── scenes/
│   ├── scripts/
│   └── input_bindings/
└── README.md
```

## Conventions

- File names: `test_<thing>.gd`, extending `GutTest`. Test function names:
  `test_<behaviour>_<condition>`.
- Preload dependencies as PascalCase constants, as the addon does (see the style guide).
- Share scene and script fixtures from `tests/fixtures/` rather than creating them inline.
- Create nodes with `add_child_autofree()` / `autofree()`, and let `RefCounted` objects go out
  of scope. Services get `enable()`/`disable()` in `before_each`/`after_each`.
- Tests that create a `UiLayersService` must `await wait_process_frames(2)` after `enable()`,
  because the layer container is added to the root with `call_deferred`.
- Prefer real addon objects (registries, `UiLayersService`) over doubles. Use a fake only to
  observe a hook, as `fake_binding.gd` does.

### Asserting errors and warnings

GUT only consumes an expected error recorded **before** the assertion runs, so put
`assert_push_error`, `assert_push_warning` or `assert_engine_error*` **after** the code under test.

Godot reports some failures with more than one engine error. For example, a missing scene
produces two engine errors. Count them with `assert_engine_error_count(n)`.

## Engine pitfalls found by the tests

These were addon defects the tests surfaced. They are fixed, but the rules they reveal are easy to
re-break, so they are recorded here.

- **Predelete cannot call script methods.** `UiAttachment` is a destructor via
  `NOTIFICATION_PREDELETE`. By that point Godot has detached the script instance, so calling any
  script method on `self` fails with "base 'null instance'". Member variables are still readable,
  and freeing plain objects works. Keep predelete cleanup data-only.
- **A freed object reference compares equal to `null` in Godot 4.** A check such as
  `anchor != null and not is_instance_valid(anchor)` is therefore always false once the anchor is
  freed. `WorldAnchorInfo` records `has_anchor` at construction for this reason.
- **Typed arrays reject `has()` for the wrong element type.** `Array[Control].has(node)` with a
  non-`Control` `node` errors and returns `false`. `UiLayersService` compares by iteration instead.

## Open items

None of the defects found so far are open. The tests in `unit/` contain no `pending()` calls.

## Not covered yet

- Tooltip positioning in `TooltipUiLayer._reposition()`, which needs a laid-out tooltip.
- Godular module-graph integration (`ViewRequester`, `WorldUiPortal`, `AttachmentSlotsController`
  resolving capabilities through `GdlrModuleManager`).
- Popup close-transition timeout (5 seconds, not injectable).
- `GameUiUserStore`, which writes to `user://`.
