## v1.2.0 (2026-03-20)
* Fixed `compat.lua` crash: `C_Spell.GetSpellCooldown` returns `isEnabled` as a protected secret boolean in WoW 11.x; wrapped the boolean test in `pcall` to prevent the taint error and the cascade that was blocking pet summoning.
* Fixed auto-summon not firing reliably after combat: added a 0.5s delay in `PLAYER_REGEN_ENABLED` before calling `UpdateAutoResummon` so `InCombatLockdown()` has fully released before the attempt.
* Fixed `Dismount` hook setting the summon-block timer during combat (forced dismounts from combat mechanics no longer delay post-combat pet resummon).
* Rebranded accent color from green (`#58be81`) to purple (`#b07fff`) across all in-game text, TOC title, and notes.
* Button bar order confirmed: title → charms → expand/minimize → X (close).

## v1.1.0 (2026-03-10)
* Added a dedicated minimize button that collapses the PetBuddy2 HUD to just the header, keeping the close button for hide/toggle duties.
* Updated the frame title to `RGX | PetBuddy2` and added right-click support on the title bar to open the context menu without hunting for the main frame.
* Documented a BLU-style release workflow (including tagging/push steps) so future releases stay consistent.

## v1.0.0 (2026-03-03)
* Reset PetBuddy2 release baseline versioning to `v1.0.0`.
* Reworked project layout into structured folders (`data/`, `ui/`, `media/`, `docs/`).
* Removed embedded external `libs/` dependency requirement.
* Updated slash command messaging and welcome text formatting to RGX suite style.
* Added Retail API compatibility guards for spell, aura, gossip, and dropdown usage.
* Fixed multiple Midnight runtime/UI issues in templates, action button handling, and menu behavior.
* Made PetBuddy native loadouts work independently of Rematch.
* Added Rematch save-dialog support as an optional helper path (`Shift-Click` on Save).
* Cleaned up utility options structure and submenu behavior.
* Refreshed TOC metadata and documentation styling to align with BLU/CCU/SQP presentation patterns.

## v4.2.3 (2026-03-03)
* Fixed `securecall` nil crash during addon enable by adding safe `LoadAddOn` fallback logic.
* Made addon event registration robust against removed/unknown events (guards around `RegisterEvent`/`UnregisterEvent`).
* Added cursor-event fallback (`CURSOR_UPDATE` -> `CURSOR_CHANGED`) for Midnight API differences.
* Added `GetPetTypeTexture` compatibility shim for clients where Blizzard removed the global function.
* Removed unsupported XML backdrop block and set backdrop at runtime in `OnLoad` to stop parser warnings.

## v4.2.2 (2026-03-03)
* Fixed Midnight runtime error in `PetBuddyTemplates.xml` by adding safe backdrop guards and `BackdropTemplate` inheritance for pet frames.
* Reworked item/flyout button visual handling for modern ActionButtonTemplate fields:
  * Added compatibility fallback from `FlyoutArrow` to `Arrow`.
  * Added safe flyout border/arrow creation when template fields are absent.
  * Prevented template `OnLoad` initialization from running with nil action type.
* Updated backdrop XML sizing syntax to remove the `AbsValue` parser warning on line 159.

## v4.2.1 (2026-03-03)
* Added RGX-style two-line login welcome message (welcome + version) with colored prefix.
* Added slash subcommands:
  * `/petbuddy2 help`
  * `/petbuddy2 welcome`
  * `/petbuddy2 version`
* Added `ShowWelcomeMessage` setting and options-menu toggle.
* Restyled `README.md` to match the presentation pattern used by BLU/CCU/SQP.

## v4.2.0 (2026-03-03)
* Removed Ace/LibStub/LibDataBroker/LibSharedMedia hard dependencies.
* Replaced Ace lifecycle/events/timers with native WoW frame event dispatch and `C_Timer`.
* Replaced AceDB with internal saved-variable defaults merge for `PetBuddyDB`.
* Replaced LibSharedMedia dependency with built-in media registry (with optional external media import when available).
* Databroker initialization now gracefully skips when `LibDataBroker-1.1` is not present.
* Removed embedded `libs` loading from `PetBuddy2.toc`.

## v4.1.1 (2026-03-03)
* Updated TOC interface targets to `120000,120001` for Midnight compatibility metadata.
* Bumped addon version to `v4.1.1`.
* Standardized docs/release structure to use `docs/CHANGES.md` as the manual changelog source.
* Added `docs/README.md` and `docs/ROADMAP.md`.

## 4.1.0
* Added Rematch loadout integration.
* PetBuddy loadout list now reads Rematch teams when Rematch is enabled.
* Loading a loadout now routes through Rematch for full team compatibility.
* PetBuddy local save/rename/delete loadout actions are disabled while Rematch is active.

## 4.0.0
* Rebranded addon to PetBuddy2.
* Updated TOC for WoW Retail Midnight (120001).
* Added compatibility shims for namespaced spell and gossip APIs.
* Added safer Pet Journal refresh and search-box handling for modern Blizzard UI.
* Added release automation scaffolding (.pkgmeta + GitHub Actions workflow).

## 3.0.2
* Fixed pet charms indicator.

## 3.0.1
* Fixed incorrect call to nonexistent function.

## 3.0.0
* Updated for Battle for Azeroth.
* Fixed PlaySound issue from forever ago. Oops.

## 2.0.2
* TOC bump for patch 7.2.5.
* Disabled auto resummon of pet in Winterspring and Un'Goro Crater if doing the mount quest daily.

## 2.0.1
* Fixed changed Blizzard dependency name.

## 2.0.0
* Updated for Legion.
* Some visual tweaks.

## 1.3.0
* Fixed a major bug that caused displayed pet info to be incorrect if a pet was dead when starting a pet battle.
* Disabled toggling pet utility menu while in pet battle.
* Pet healing utility buttons are now painted dark red when they're unusable (e.g. in Celestial Tournament.)

## 1.2.2
* More bug fixes and tweaks.

## 1.2.1
* Minor bug fixes.

## 1.2.0
* Added two new options for auto companion resummon: random favorite pet and any random pet.
* Changed number of wounded pets display Data Broker module to count all pets instead of only active pets. Also applies to automatic pet healing.
* The loadouts search box will now lose focus after restoring a saved loadout.

## 1.1.2
* Removed the debug text when changing fonts.
* Attempted fix to fonts and textures not properly updating on frame.
* Fixed experience text not changing fonts.
* Added way to hide Pet Buddy when entering pet battle.

## 1.1.1
* Added options to change font face and bar textures from the pool of SharedMedia and font size.
* Added cuteness.

## 1.1.0
* First public release.
