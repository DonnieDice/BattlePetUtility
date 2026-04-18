# Runtime Data Modules

This directory contains the Lua modules that drive PetBuddy2 at runtime.

## Purpose

- Register addon startup logic and event handling.
- Manage frame state, options, pet team updates, utilities, loadouts, and zone tracking.

## Main Files

- `core.lua` - Core addon bootstrap, event flow, HUD updates, and shared helpers.
- `options.lua` - Saved variable defaults, dropdown options, media selection, and frame settings.
- `petloadouts.lua` - Native loadout management and Rematch-aware team handling.
- `zonetracking.lua` - Zone pet tracker rendering and progress logic.
- `zonespecies.lua` - Built-in PB2 zone pet species data.
- `itembuttons.lua` - Pet-related utility item buttons and quick actions.
- `databroker.lua` - DataBroker launcher and tooltip support.
- `pethealer.lua` - Healing and stable-master support logic.
- `compat.lua` - Optional addon compatibility helpers.

## Editing Notes

- Keep realtime UI refresh behavior lightweight. Expensive pet journal work should stay guarded or coalesced.
- Changes here should be reflected in `docs/CHANGES.md` when they affect shipped behavior.
