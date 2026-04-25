# v2.3.1 - 2026-04-25

## Changes
- Fixed: `SetCooldown` now wrapped in `pcall` — WoW rejects tainted "secret" values from `GetItemCooldown` in some execution contexts, causing `[RGX:timer]` errors.
- Fixed: `RegisterEvent` / `UnregisterEvent` on item button frames wrapped in `pcall` — these frames are in a forbidden execution context in some states, causing `ADDON FORBIDDEN` errors.
