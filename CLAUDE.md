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
| `modules/EK_Tracker.xml` | Tracks Erfahrungspunkte/Kampfpunkte (experience/combat points) |
| `modules/HintRegistry.xml` | In-game hint and tips registry |
| `modules/ObjectRegistry.xml` | Registry for game objects (items, NPCs) |
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

## Morgengrauen Game Context

- Morgengrauen is a German-language MUD. In-game text, variable names, and comments are often in German.
- Game information: https://mg.mud.de/information/index.shtml
- Triggers match against raw MUD output text (ANSI-stripped or with color codes depending on configuration).
- Common game concepts: EP (Erfahrungspunkte = XP), KP (Kampfpunkte = HP), LP (Lebenspunkte = HP alternative), Gilde (guild), Zauber (spells), Weg (path/route).

## Code Review Focus Areas

- **Global namespace pollution**: every top-level variable is global. Prefer namespaced tables (`MYMODULE.helper = ...`) over bare globals.
- **Re-initialization safety**: plain assignments at script top-level overwrite state on module reload — flag these.
- **Trigger pattern correctness**: regex or substring patterns in `<regexCode>` / `<pattern>` should be verified against the game's output format.
- **Event handler leaks**: `registerAnonymousEventHandler` calls inside script blocks that run on every reload will register duplicate handlers — flag if not guarded.
- **`transformer.py` extensibility**: if new extraction logic is needed for a review (e.g. extracting timer intervals), note that `transformer.py` can be extended for that purpose.
