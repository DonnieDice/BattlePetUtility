# CLAUDE.md — BattlePetUtility

Agent guidance for this repository.

## Project Overview

BattlePetUtility (BPU, formerly PetBuddy2) is a Retail WoW addon for managing battle pets: HUD frame with pet loadouts, item buttons for pet-related consumables, pet healing, auto-summon, tooltips, and a tabbed options panel.

- **Version:** `v2.3.20` (see `docs/CHANGES.md` for unreleased work on `main`)
- **Interface:** `120007` (WoW Retail Midnight 12.0.7)
- **TOC:** `BattlePetUtility.toc`
- Part of the RGX Mods suite (`DonnieDice/BattlePetUtility` on GitHub — repo was renamed from PetBuddy2)

## Structure

```
BattlePetUtility.toc   — metadata, SavedVariables, load list
data/                  — runtime modules (core, itembuttons, pethealer, petloadouts,
                         minimapicon, databroker, compat, options_*)
ui/                    — XML frame templates
docs/                  — CHANGES.md (canonical changelog), README, RELEASING, ROADMAP
media/                 — icons, textures
```

## RGX-Framework Dependency (~65% integrated)

BPU declares `## RequiredDeps: RGX-Framework` and uses the shared `_G.RGXFramework` instance for: events (`RGX:RegisterEvent`), timers (`RGX:After`/`RGX:Every`), hooks, slash commands, database (`RGX:NewDatabase` in `options_database.lua`), minimap button (`RGX:CreateMinimapButton` in `minimapicon.lua`), and debug output (`RGX:Debug`).

Rules (framework thesis: make the bug unrepresentable — see `../RGX-Framework/CLAUDE.md`):

- No manual event frames, no raw `C_Timer`, no raw `SLASH_X` — route through RGX.
- **Secure buttons:** `data/itembuttons.lua` sets action attributes on secure buttons. `SafeSetButtonAttribute` refuses `SetAttribute` during combat lockdown and sets `pendingItemButtonAttributeRefresh`; the event bridge rebuilds buttons on `PLAYER_REGEN_ENABLED`. Preserve this pattern — never call `SetAttribute` in combat, and `pcall` does NOT prevent taint.
- Aura checks use `C_UnitAuras.GetPlayerAuraBySpellID` (taint-safe) — never index aura slots or compare secret aura fields.

### Planned wiring (framework roadmap Tier 2)

- **BPU → RGXPetBattles** (#6): replace raw `C_PetBattles.*` calls with the framework module.
- **BPU → RGXDropdowns** (#8): replace `EasyMenu`/`UIDropDownMenu` usage in options.
- When RGXAuras ships (Tier 3), BPU's `PlayerHasAuraSpellID` pattern migrates to it.

## Conventions

- Tabs for indentation, `;`-terminated statements in `data/` files — match surrounding style.
- Keep `docs/CHANGES.md` as the canonical changelog; add an `Unreleased` section for landed-but-untagged work; matching file in `docs/changelogs/` per release.
- Release: tag `vX.Y.Z` on main triggers the GitHub Actions Package and Release workflow (BigWigsMods packager). Keep TOC version aligned with the tag.
- Local testing: robocopy the repo (minus `.git`, `graphify-out`, `docs`) to `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\BattlePetUtility`, then `/reload`.
