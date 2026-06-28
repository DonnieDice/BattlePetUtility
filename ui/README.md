# UI Layout Files

This directory contains the XML layout files for the BattlePetUtility interface.

## Files

- `BattlePetUtilitytemplates.xml` - Shared templates, reusable widgets, and styling primitives.
- `BattlePetUtilityframe.xml` - Main HUD frame layout, title bar, pet slots, loadout area, and zone tracker frame.

## Purpose

- Define the static frame structure that the Lua modules populate and update at runtime.
- Keep layout concerns separate from behavioral logic in `data/`.

## Editing Notes

- Be careful with widget names and parent keys. Lua modules rely on exact frame names.
- If you add or rename XML widgets, update the matching Lua references in `data/core.lua`, `data/options.lua`, or `data/zonetracking.lua`.
