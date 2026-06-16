# CLAUDE.md — Morgengrauen Tools

This repository contains Mudlet modules for the German MUD game **Morgengrauen** (https://mg.mud.de/information/index.shtml).

## Repository Structure

- `modules/*.xml` — Mudlet module files. These are the primary review targets.
- `Install_Mundron_Skripte.xml` — Top-level installer module that detects and installs missing modules via Mudlet's module manager.
- `transformer.py` — Utility script that extracts Lua code from the XML module files for inspection. It is **not** a review target, but may be extended if needed.
- `data/` — Player-specific runtime data. **Ignored in reviews.**
- `pictures/` — Image assets used by the GUI.

## Modules Overview

| File | Purpose |
|---|---|
| `modules/Mundron_Core.xml` | Core utilities and shared infrastructure |
| `modules/GUI.xml` | Geyser-based graphical user interface |
| `modules/Wegeskript.xml` | Pathfinding / movement automation ("Wegeskript" = route script) |
| `modules/EK_Tracker.xml` | Tracks NPCs |
| `modules/HintRegistry.xml` | In-game hint and tips registry |
| `modules/ObjectRegistry.xml` | Registry for different kinds of items (weapons, armor, herbs) |
| `modules/expandAlias_NumPad_Belegung.xml` | Numpad alias bindings |

## XML File Format

Mudlet exports its configuration as XML. Each module XML contains one or more of these element types:

- `<ScriptPackage>` / `<Script>` — Lua scripts (the main logic)
- `<TriggerPackage>` / `<Trigger>` — Patterns matched against game output, with Lua callbacks
- `<AliasPackage>` / `<Alias>` — Commands typed by the player, with Lua callbacks
- `<TimerPackage>` / `<Timer>` — Timed Lua callbacks
- `<KeyPackage>` / `<Key>` — Keyboard shortcut bindings
- `<ActionPackage>` / `<Action>` — Toolbar buttons

The actual Lua code lives inside `<script>` (for Scripts) or `<script>` child elements within Triggers/Aliases/Timers. When reviewing, extract and read the Lua from these tags — `transformer.py` can assist with bulk extraction.

## Global Scope and Safe Re-initialization

All modules are loaded into **Mudlet's single shared global Lua scope**. This applies to scripts, aliases, triggers, timers, keys, and buttons across all modules.

**Mudlet re-executes script blocks whenever a module is saved or reloaded.** To prevent destroying existing state (e.g. active GUI objects, accumulated data), objects and tables are initialized with the `X = X or <default>` idiom:

```lua
-- Safe: preserves existing object if already initialized
PLAYER = PLAYER or {}
PLAYER.hp = PLAYER.hp or 0

GUI = GUI or {}
GUI.mainWindow = GUI.mainWindow or Geyser.Window:new({...})
```

This is **intentional and correct** — do not flag it as redundant. Conversely, a plain assignment like `PLAYER = {}` at script top-level is a **bug** (wipes state on reload) and should be flagged.

## Class System: `MundronClassMethods` and Template Modules

All stateful modules in this repository are built on a small class system rooted in **`MundronClassMethods`** (defined in `modules/Mundron_Core.xml`). New modules and classes **must prefer these base classes** instead of re-implementing infrastructure (object state, persistence, events, logging, migrations, aliases) by hand. They define the basic classes every module is expected to build on. When reviewing, **flag code that hand-rolls functionality these classes already provide** — manual JSON read/write, bare `registerAnonymousEventHandler`, ad-hoc logging, custom migration logic, or manual alias creation.

### `MundronClassMethods` (the base class)

`MundronClassMethods` is the shared metatable for every module object. Create an object with `:new{...}` or define a subclass with `:extend{...}`:

```lua
-- A concrete module object — preferred way to declare a stateful module
PLAYER = PLAYER or MundronClassMethods:new{
  _name    = "PLAYER",          -- required: unique object name
  _module  = "GUI",             -- required: owning module (XML file name)
  _version = "1.1.0",           -- required: semantic version
  _fixed_version = { MundronClassMethods = "1.1.0" }, -- pin inherited class versions
  config   = {},
  data     = {},
  files    = { profile = { ... }, game = { ... } },   -- persisted fields of `data`
}
```

Required fields on every object: `_name`, `_version`, `_module`. Pin the versions of inherited classes via `_fixed_version` (omit it and the constructor warns).

What `:new{...}` provides for free — do **not** re-implement these:

- **Registration** with the global object registry `GOR`, including alias-group wiring.
- **State persistence** as JSON under `files = {profile = {...}, game = {...}}`. Each key is a field of `data`; persist with `:save_data()` / `:load_data()` (or the per-target `:save_profile()`, `:save_game()`, `:load_profile()`, `:load_game()` helpers). The `COMPACT` pseudo-field packs several fields into a single file.
- **Versioned migrations** via `_versions`, `:check_for_migrations()`, and the `:migrate_profile()` / `:migrate_game()` hooks. `_fixed_version` is verified on construction.
- **Event handling** via `:register_event(handler_name, event_name, fn)` and `:kill_event(handler_name)`. These track handler ids so reloads do **not** leak duplicate handlers — prefer them over bare `registerAnonymousEventHandler`.
- **Logging / diagnostics**: `:log()`, `:info()`, `:warn()`, `:error()`, `:assert()`, `:show_log()`. Follow the language convention (German for user-facing warnings, English for hard errors).
- **Aliases** declared as data via `self.alias_templates` and materialized by `:create_aliases()`.
- **Lifecycle hooks** you may define: `:init()` (build step), `:post_load_data()` (rebuild lookups after a load), `:reset()`.

### Template subclasses

Three reusable subclasses `:extend` the base class and add domain behavior. **Prefer extending the matching template** over `MundronClassMethods` directly whenever a new class fits one of these domains:

| Template | Module | Extend it when you need … |
|---|---|---|
| `GUITemplate` | `modules/GUI.xml` | A Geyser widget / window. Adds `:create_container()`, `:create_label()`, `:create_gauge()`, `:build_base()`, and manages the `containers` / `labels` / `gauges` tables. |
| `ObjectRegistryTemplate` | `modules/ObjectRegistry.xml` | An item registry (weapons, armor, herbs, …). Adds id-based lookups (`data._by_id`, `data._max_id`), `data_on_demand` lazy loading, and standard `finde` / `list` / `note` / `change` aliases. |
| `HintRegistryTemplate` | `modules/HintRegistry.xml` | A hint / tips registry keyed off a game trigger. Adds trigger wiring, history persistence, and hint ↔ target lookup maps. |

Declare a subclass object the same way, pinning the template's version too:

```lua
PotionRegistry = PotionRegistry or HintRegistryTemplate:new{
  _name    = "PotionRegistry",
  _module  = "HintRegistry",
  _version = "1.0.0",
  _fixed_version = { MundronClassMethods = "1.1.0", HintRegistryTemplate = "2.0.0" },
  config   = { ... },
}
```

To add a **brand-new template**, `:extend` `MundronClassMethods` (or an existing template), set `_name` / `_module` / `_version`, and provide a `:new` that delegates to `MundronClassMethods.new(self, spec)`.

## Mudlet Non-Standard Lua Functions

Mudlet provides many Lua functions beyond the standard library. If a function call is unrecognized, look it up before flagging it as undefined:

| Category | Reference URL |
|---|---|
| Core Mudlet Lua API | https://wiki.mudlet.org/w/Manual:Lua_Functions |
| Event engine (`raiseEvent`, `registerAnonymousEventHandler`, …) | https://wiki.mudlet.org/w/Manual:Event_Engine# |
| Geyser UI framework (base classes) | https://wiki.mudlet.org/w/Manual:Geyser |
| Geyser.Color | https://www.mudlet.org/geyser/files/geyser/Geyser.Color.html |
| Geyser.Container | https://www.mudlet.org/geyser/files/geyser/Geyser.Container.html |
| Geyser.Label | https://www.mudlet.org/geyser/files/geyser/Geyser.Label.html |
| Geyser.Gauge | https://www.mudlet.org/geyser/files/geyser/Geyser.Gauge.html |

Common Mudlet globals to be aware of: `send()`, `sendAll()`, `echo()`, `cecho()`, `decho()`, `hecho()`, `cechoLink()`, `selectString()`, `resetFormat()`, `setBold()`, `setFgColor()`, `createStopWatch()`, `startStopWatch()`, `getStopWatchTime()`, `enableAlias()`, `disableAlias()`, `enableTrigger()`, `disableTrigger()`, `enableTimer()`, `disableTimer()`, `tempTimer()`, `tempTrigger()`, `tempAlias()`, `raiseEvent()`, `registerAnonymousEventHandler()`.

## Mudlet Global Variables

Mudlet injects the following global variables into the Lua environment. These are **not** defined in user code — do not flag them as undefined or uninitialized.

Reference: https://wiki.mudlet.org/w/Manual:Lua_Functions

| Variable | Description |
|---|---|
| `command` | The current user command as typed, unchanged by any aliases or triggers. Typically used in alias scripts. |
| `line` | The content of the current line as being processed by the trigger engine. Set on each incoming line from the game. |
| `matches[n]` | Perl regex capture groups for the current trigger or alias. `matches[1]` is the entire match; `matches[2]` is the first capture group; `matches[n]` is the (n−1)-th capture group. If the trigger uses "match all" (like the Perl `/g` flag), subsequent full matches and their groups follow in the same table. Since Mudlet 4.11+, named capturing groups are also supported and accessible by name: `matches["target"]` / `matches.target`. Use `mudlet.supports.namedGroups` to check availability. |
| `multimatches[n][m]` | For multiline triggers using Perl regex. Holds the `matches` table for each condition line: `multimatches[n]` is the matches table for the n-th condition, so `multimatches[5][4]` is the 3rd capture group of the 5th regex condition. |
| `mudlet.translations` | Translations of common texts (currently exit directions) and the current UI language. Useful for portable scripts — see `translateTable()`. |
| `mudlet.key` | Maps key names to the numeric codes needed by `tempKey()` and similar functions. |
| `mudlet.keymodifier` | Maps modifier key names (Ctrl, Alt, etc.) to their numeric codes. |
| `mudlet.supports` | Feature-detection table. Currently documents `mudlet.supports.coroutines` and `mudlet.supports.namedGroups`. Use this to conditionally enable features based on the user's Mudlet version. |
| `color_table` | Color definitions used by Geyser, `cecho()`, and related functions. Profile ANSI color preferences are accessible under the `ansi_` keys. See `showColors()`. |

For variables holding MUD-protocol data (GMCP, MSDP, ATCP, …) see https://wiki.mudlet.org/w/Manual:Supported_Protocols.

### Usage notes

- `matches`, `multimatches`, `command`, and `line` are only meaningful inside trigger/alias callbacks. They are **not** available in plain script blocks or timer callbacks.
- `multimatches` must be used instead of `matches` when reading captures from multiline triggers.
- `line` reflects the raw MUD line; ANSI color codes may or may not be stripped depending on trigger configuration.

## Morgengrauen Game Context

- Morgengrauen is a German-language MUD. In-game text, variable names, and comments are often in German.
- Game information: https://mg.mud.de/information/index.shtml
- Triggers match against raw MUD output text (ANSI-stripped or with color codes depending on configuration).
- Common game concepts:
  - **SP** (Stufenpunkte) defines the player's level
  - **EP** (Erfahrungspunkte = XP) maps to SP
  - **EK** (ErstKill) are bonus points awarded once for first kills of hard NPCs; also map to SP
  - **KP** (Kampfpunkte) = spell / magic points
  - **LP** (Lebenspunkte) = health points
  - **Gilde** (guild), **Zauber** (spells), **Weg** (path/route)

## Code Review Focus Areas

- **Prefer the class system**: new stateful modules and classes should be created with `MundronClassMethods:new{...}` or by extending a Template (`GUITemplate`, `ObjectRegistryTemplate`, `HintRegistryTemplate`) — see "Class System" above. Flag code that hand-rolls state persistence (manual JSON read/write instead of `files` + `:save_data()`/`:load_data()`), event registration (bare `registerAnonymousEventHandler` instead of `:register_event`/`:kill_event`), logging, migrations, or alias creation when a base-class facility already covers it.
- **Variable scoping**:
  - Use `local` variables for function-scoped values — do not leak them into the global scope.
  - Use namespaced tables for values that belong to a module or class (e.g. `MYMODULE.value`).
  - Store instance/state data under a `data` field of the relevant class table.
  - Values that must persist beyond a single function, action, or session should be saved in the class configuration; flag if this is missing.
- **Re-initialization safety**: plain assignments at script top-level overwrite state on module reload — flag these.
- **Trigger pattern correctness**: regex or substring patterns in `<regexCode>` / `<pattern>` should be verified against the game's output format.
- **Event handler leaks**: `registerAnonymousEventHandler` calls inside script blocks that run on every reload will register duplicate handlers — flag if not guarded.
- **`transformer.py` extensibility**: if new extraction logic is needed for a review (e.g. extracting timer intervals), note that `transformer.py` can be extended for that purpose.

## Coding Conventions

- **User-facing messages**: if a user action results in bad input, an empty result set, or similar non-critical issues, output the feedback **in German** using the warning print (`cecho` with a yellow/warning color or equivalent Mudlet warning mechanism).
- **Hard errors**: internal errors and unexpected failures should use the error print and be written **in English**.
- **String formatting**: Mudlet supports Python-style f-strings, which should be preferred over both `string.format()` and string concatenation (`..`).
  ```lua
  -- preferred
  cecho(f"<yellow>Kein Eintrag für '{name}' gefunden.\n")
  -- avoid
  cecho(string.format("<yellow>Kein Eintrag für '%s' gefunden.\n", name))
  -- avoid
  cecho("<yellow>Kein Eintrag für '" .. name .. "' gefunden.\n")
  ```
- **Nested table access**: prefer the `table.get` / `table.set` helpers (`modules/Mundron_Core.xml`) over hand-written nil-checks and intermediate-table initialization. `table.get(tab, key, default)` returns `tab[key]`, and if it is missing **and** a `default` is given, it stores a (deep) copy of the default into `tab` and returns it — a fetch-or-initialize in one step. `table.set(tab, key, value)` deep-sets the value, creating any intermediate tables. Both accept a single key, a dotted path (`"a.b.c"`), or a key list (`{"a", "b", "c"}`) for nested access. Use them to simplify code wherever they fit.
  ```lua
  -- preferred: fetch-or-create in one step (room.notes is stored if absent)
  local notes = table.get(room, "notes", {})
  table.insert(notes, text)

  -- avoid: manual nil-check + separate initialization
  room.notes = room.notes or {}
  table.insert(room.notes, text)

  -- preferred: nested set creates intermediate tables
  table.set(self.data, {"seen_details", room_id, detail}, true)
  ```
- **Trigger and alias logic**: keep the Lua code inside `<Trigger>` and `<Alias>` script blocks as small as possible — ideally a single function call. Complex logic belongs in a `<Script>` item where it can be properly named, tested, and reused.
  ```lua
  -- preferred: trigger/alias script is a thin dispatcher
  MyModule.handleVitals(matches)

  -- avoid: non-trivial logic embedded directly in the trigger
  local hp = tonumber(matches[2])
  local hpMax = tonumber(matches[3])
  if hp < hpMax * 0.3 then
    cecho("<red>Achtung: LP niedrig!\n")
    send("heile")
  end
  ```
