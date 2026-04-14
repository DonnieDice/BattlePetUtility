# Changes

## v2.0.1

- Normalized non-documentation asset and UI file paths to lower case, including the `media/` directory and XML layout filenames, while intentionally leaving documentation files and the addon manifest naming alone.
- Updated in-repo asset references to match the lower-case path cleanup so TOC, XML, Lua media registration, and button/icon paths stay in sync.
- Hardened the release workflow Discord notification path so webhook responses are awaited and validated instead of failing silently.
- Added `workflow_dispatch` support plus manual release inputs to the release workflow so Discord notifications and packager runs can be retried without cutting a new feature tag.
- Updated release workflow notifications to include the CurseForge download link directly in Discord.
- Polished README / changelog / releasing docs so they reflect the current Rematch flow, rerun workflow, and post-release troubleshooting guidance more accurately.

## v2.0.0

- Replaced `EasyMenu` with native `UIDropDownMenu` API for reliable dropdown behavior (same pattern used by BLU addon).
- Fixed dropdown menu not staying open after selecting options — all toggle options now properly keep the menu open via `keepShownOnClick = true`.
- Fixed font/texture/size selection showing multiple checkmarks — these menus now use proper radio button behavior (only one selected at a time) with automatic refresh after selection.
- Fixed zone pet tracker misalignment when "Show pet related items" or "Show pet loadouts menu" is enabled — zone tracker now dynamically anchors to the bottommost visible element (loadout scroll frame > loadout bar > pet item buttons > pet frames) so it always appears below all content.
- Fixed expanded frame height calculation — reverted to original calculation that worked correctly, preventing excessive gap between bottom row elements and zone pet tracker.
- Fixed "Hide main GUI body" not hiding the active pet team — `UpdatePets()` now respects the `HideMainGUI` flag and hides pet frames 1-3.
- Fixed "Show pet related items" submenu missing heading — added "Pet Items Options" title text.
- Fixed loadout context menu overlapping the zone tracker — context menu now opens above the loadout item row.
- Added "Hide main GUI body" toggle option under Zone Tracker — hides pet frames, pet team, pet item buttons, and loadouts while keeping the title bar and zone tracker visible in a compact layout.
- Fixed minimize behavior — minimizing now hides everything except the title bar (zone tracker is hidden when minimized, shown only when "Hide main GUI body" is enabled).
- Fixed "Hide main GUI body" not properly hiding pet item buttons and loadout dropdown — both are now correctly hidden along with pet frames.
- Fixed loadout scroll frame toggle to refresh zone tracker position and frame height when opened or closed.
- Moved "Show pet charms" from the pet items submenu to a standalone option in the Displays section.
- **CPU optimization**: Applied BLU's coalescing debounce pattern to UpdatePets and UpdateMinimizeState — first call executes immediately for responsive UI, subsequent calls within 0.15s window are coalesced into single execution.
- **CPU optimization**: Removed duplicate event registrations in OnShow() that caused handlers to fire 2x for every pet event.
- **CPU optimization**: PET_JOURNAL_LIST_UPDATE now skips expensive RefreshZoneTracker cascade.
- Fixed pets not displaying after reload — replaced deferred debounce with immediate execution + coalescing window for responsive UI.
- Fixed zone pet tracker spacing and anchoring so it stays visually locked under the bottom row while the main GUI is visible, only shifts when the entire bottom row is disabled or the main GUI body is hidden, and keeps the progress text on the bar.
- Added more font options (Arial Narrow, Morpheus, Skurri, Expressway) and bar texture options (Flat, Glamour, Minimalist, Perl, Smoother) to Frame Options menu.
- Moved "Lock PetBuddy2" to the top of the options menu.
- Moved "When starting pet battle" to the top of the Automation section.
- Fixed team selection not loading after reload by restoring the Blizzard loadout refresh path during startup without reintroducing the older intrusive hook behavior.
- Removed the empty "Other Options" section.
- Fixed "Show missing pets list" being greyed out — it is now always toggleable.
- Removed redundant "Hide PetBuddy2" / "Show PetBuddy2" dropdown option — the close (X) button already handles this.
- Removed the older intrusive `PetJournal_UpdatePetLoadOut` hook behavior that could interfere with the collections UI, keeping PB2 closer to BLU's safer read-only approach for normal updates.
- Replaced placeholder addon icon with a proper PetBuddy2 icon asset and updated TOC metadata.
- Fixed the in-game header branding so the title now shows the logo and purple `P`, `B`, and `2` styling consistently.
- Replaced the broken minimize and close art with explicit header buttons so the controls render reliably.
- Refined the header controls with smaller, cleaner minimize and close buttons plus updated chat prefix styling.
- Repositioned the animated bird and added a nested cuteness placement option for left or right header placement.
- Added a PB2 zone pet tracker frame with a real options toggle, enabled by default, promoted to the top of the options menu, and backed by native PB2 zone data.
- Improved the zone tracker data path so it prefers richer live data when available, falls back cleanly to PB2-native zone species data, and shows a proper zone pet list in the tooltip with Kaliel-style quality progress colors.
- Fixed startup restoration so pets populate on load even when the loadout menu is disabled.
- Synced the utility menu saved state more defensively so item/loadout visibility toggles restore correctly.
- Decoupled pet rendering from loadout list rebuilding so a loadout UI issue cannot blank the main pet display.
- Restored combat hide/show behavior after duplicate regen handlers accidentally overwrote it.
- Kept the improved combat and post-dismount auto-summon timing while merging it back into the main combat event flow.
- Hardened databroker and loadout UI code against empty slots, missing pets, and missing rarity data.
- Updated the loadout save flow so Rematch opens by default when it is installed instead of requiring Shift-click.
- Restored styled TOC title and notes formatting to match the presentation used across the rest of the addon suite.
- Reintroduced zone tracking in a safer PB2-native form with built-in zone data and cleaner compatibility behavior.
- Finalized the zone tracker release layout so it keeps a stable anchor under the bottom row when loadouts remain enabled, only repositions when the whole bottom row is gone or the main GUI body is hidden, and restores the progress text on the bar.
- Fixed tracker media registrations so named bar textures use real statusbar assets instead of placeholder-style fills.
