# v2.3.17 - 2026-04-29

## Changes

- Fixed: PB2 Text Styles font selection now uses an explicit `pb2_fonts`
  submenu key so legacy `UIDropDownMenu` initializes the font rows at the
  correct submenu level.

# v2.3.16 - 2026-04-29

## Changes

- Fixed: Removed the separate PB2 font picker window path. Font selection is
  again handled only inside PB2's existing Text Styles dropdown menu.
- Fixed: Added explicit submenu value/menuList compatibility for legacy
  `UIDropDownMenu` so RGX font submenu rows can render correctly.

# v2.3.15 - 2026-04-29

## Changes

- Fixed: PB2 Text Styles now offers an “Open font picker” action that launches
  the shared RGX visible paged font picker, bypassing the native dropdown row
  rendering issue that hid font selections.

# v2.3.14 - 2026-04-29

## Changes

- Fixed: PB2 Text styles now renders RGX font choices directly inside the Text
  Styles submenu instead of relying on a second nested UIDropDownMenu level that
  was not displaying font rows in-game.

# v2.3.13 - 2026-04-29

## Changes

- Added: PB2 Text styles now prints RGX font menu diagnostics to chat, including
  menu item count, total registered fonts, available fonts, and default font.
  This tells us whether the framework returned an empty font list or the native
  menu failed to render received items.

# v2.3.12 - 2026-04-29

## Changes

- Fixed: PB2 Text styles font selection now receives a flat RGX font list so
  fonts appear in the right-click menu instead of being lost in nested menu
  conversion.
- Changed: Removed the “Open full editor” entry from PB2 Text styles as
  requested; the menu now focuses on the shared font selection only.

# v2.3.11 - 2026-04-29

## Changes

- Fixed: PB2 full text-style editor now inherits RGX's native shared font picker
  so font choices are populated from the framework without relying on Blizzard
  dropdown construction.
- Fixed: Removed the remaining `securecall`/`securecallfunction` startup path
  around loading Blizzard Collections to reduce protected-action attribution.
- Fixed: PB2 item buttons now skip secure attribute mutation during XML load and
  defer their first item-button refresh until the addon is enabled.

# v2.3.10 - 2026-04-29

## Changes

- Fixed: PB2 Text styles now exposes one shared Font submenu using RGX's flatter
  family-based font list, instead of stacking separate title/normal/small font
  dropdowns in the context menu.
- Changed: Selecting a font from the PB2 menu applies it to title, normal, and
  small text together; the full editor remains available for size/style tuning.

# v2.3.9 - 2026-04-29

## Changes

- Fixed: Restored PB2 context menu opening/refreshing to the native
  UIDropDownMenu path with `pcall` guards, matching the BLU-style implementation
  and avoiding the broken RGX safe-wrapper menu path during testing.
- Confirmed: PB2 still uses RGX for shared font/style dropdown data while the
  right-click context menu itself stays on the stable native menu API.

# v2.3.8 - 2026-04-28

## Changes

- Changed: PB2 context menu refresh/open paths now use the RGX safe dropdown
  wrappers instead of calling Blizzard dropdown APIs directly.
- Fixed: PB2 minimap button now declares the canonical RGX `onRightClick` and
  `onCtrlRight` callbacks, keeping right-click options and ctrl-right hide
  behavior attached through the framework helper.

# v2.3.7 - 2026-04-28

## Changes

- Changed: New/default PB2 profiles now load with both the pet items menu and
  loadouts menu visible.
- Changed: PB2 applies a one-time test-profile migration so profiles created with
  the previous loadout-hidden default switch to the new combined utility menu.
- Changed: The PB2 context menu now exposes Text styles as nested RGX-powered
  font/style/size selections, with the full editor still available from the same
  submenu.
- Fixed: Removed an unused secure frame toggler from PB2 startup to reduce
  load-time taint/protected-action risk.
- Confirmed: Zone tracker defaults remain enabled for fresh profiles, including
  the missing-pets list.

# v2.3.6 - 2026-04-28

## Changes

- Fixed: PB2 now registers the Retail cursor-change event directly instead of
  probing the removed `CURSOR_UPDATE` event at login.

# v2.3.5 - 2026-04-28

## Changes

- Fixed: Added Retail-safe item/spell API shims for PB2 item buttons and pet
  charm helpers so missing globals like legacy `GetItemInfo()`/`GetSpellInfo()`
  do not crash `PLAYER_LOGIN` or `BAG_UPDATE_DELAYED` handlers.
- Changed: PB2 text style outline selection now benefits from the RGX framework
  nested dropdown implementation instead of the older custom style menu.

# v2.3.4 - 2026-04-28

## Changes

- Fixed: Removed direct event registration from PB2 secure action buttons. Item
  button cooldown/count refreshes now route through the shared RGX event bus,
  avoiding Blizzard `ADDON FORBIDDEN: Frame:RegisterEvent()` blocks during init.
- Fixed: PB2's `RegisterEvent()` wrapper now returns the actual RGX registration
  result, so fallback event registration works correctly if Blizzard rejects an
  event name.

# v2.3.3 - 2026-04-28

## Changes

- Added: PB2 minimap button now uses the shared RGX-Framework minimap helper.
- Added: Right-click minimap menu support, including quick options/actions from
  the button.
- Added: Options panel toggle for showing or hiding the minimap button; the
  minimap icon defaults to enabled for new profiles.
- Fixed: Minimap icon visibility is reapplied after login/reload so an enabled
  saved setting displays immediately without needing disable/enable.

# v2.3.2 - 2026-04-26

## Changes
- Fixed: Pet team now auto-saves and restores on login/reload. Previously, pets would not persist because the addon only displayed the current game state without saving the team configuration. Added `SaveCurrentTeam()`, `RestoreLastTeam()`, and `ShouldRestoreLastTeam()` functions with automatic restoration during `PLAYER_ENTERING_WORLD`.
- Fixed: Zone pet tracker displaying "unavailable" for many zones. Expanded `ZoneSpeciesByMap` database with:
  - The War Within zones (Isle of Dorn, The Ringing Deeps, Hallowfall, Azj-Kahet, subzones)
  - Complete Dragon Isles coverage (Waking Shores, Ohn'ahran Plains, Azure Span, Thaldraszus, Zaralek Cavern, Emerald Dream)
  - Full Shadowlands coverage (all 4 covenant zones + Zereth Mortis + The Maw)
  - Complete BFA coverage (Kul Tiras, Zandalar, Nazjatar, Mechagon)
  - Full Legion coverage (Broken Isles + Argus zones)
  - Complete Draenor coverage (all zones + Tanaan + Ashran)
  - Complete Pandaria coverage (all zones)
  - Full Cataclysm coverage (Hyjal, Deepholm, Twilight Highlands, Uldum)
  - Major cities and capital zones
  - Classic Kalimdor/Eastern Kingdoms zone coverage
- Fixed: Zone pet tracker "unavailable" by adding `MAP_ALIASES` to redirect cities and subzones to their outdoor parent zones (Orgrimmar, Stormwind, Ironforge, Dalaran, Dornogal, Valdrakken, etc.)
- Changed: `data/core.lua` - Added team persistence functions and auto-save on pet updates
- Changed: `data/options.lua` - Added `LastActiveTeam` and `LastSavedMapID` to character database defaults
- Changed: `data/zonespecies.lua` - Added 100+ new zone mappings for modern expansions
- Changed: `data/zonetracking.lua` - Expanded `MAP_ALIASES` with 50+ redirects for cities, instances, and subzones

# v2.3.1 - 2026-04-25

## Changes
- Fixed: `SetCooldown` now wrapped in `pcall` — WoW rejects tainted "secret" values from `GetItemCooldown` in some execution contexts, causing `[RGX:timer]` errors.
- Fixed: `RegisterEvent` / `UnregisterEvent` on item button frames wrapped in `pcall` — these frames are in a forbidden execution context in some states, causing `ADDON FORBIDDEN` errors.
