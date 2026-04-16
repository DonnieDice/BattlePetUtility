# Changes

## v2.1.2

- Fixed startup restoration so the pet team HUD, zone tracker, and saved loadout UI come back correctly after login or reload without needing to toggle the loadout menu off and on.
- Restored PetBuddy2's live runtime update events whenever the frame is shown again so pet team data and loadout visuals do not get stuck after hide/show flows.
- Wired the standalone minimap icon to the same shared PetBuddy2 logo texture used by chat and the main frame; it remains draggable around the minimap and left-click toggles the addon frame.

## v2.1.1

- Added a standalone PetBuddy2 minimap icon using the `logo.tga` asset. Left click toggles the PetBuddy2 frame, right click opens the options menu, and the icon can be dragged around the minimap edge with its position persisting across sessions.
- Added a "Show minimap icon" toggle to the options menu so the icon can be enabled or disabled without relying on external minimap-button managers.
- Implemented non-interfering PetTracker integration: when PetTracker is installed, PB2 defers to its live zone data and skips the native journal quality scan entirely, so it never mutates `C_PetJournal` filters or fires spurious `PET_JOURNAL_LIST_UPDATE` events that would thrash PetTracker's own listeners.
- Cached the native zone quality map and invalidated it on `PET_JOURNAL_LIST_UPDATE` so PetTracker-less users rebuild the quality scan at most once per collection change instead of once per zone refresh.
- Added PetTracker to `OptionalDeps` for deterministic load order when both addons are present.
- Added the missing `avatar_url` (pet logo) to all Discord release, beta, alpha, and failure notification embeds so notifications render with the proper PetBuddy2 branding.

## v2.0.1

- Normalized non-documentation asset and UI file paths to lower case, including the `media/` directory and XML layout filenames, while intentionally leaving documentation files and the addon manifest naming alone.
- Updated in-repo asset references to match the lower-case path cleanup so TOC, XML, Lua media registration, and button/icon paths stay in sync.
- Hardened the release workflow Discord notification path so webhook responses are awaited and validated instead of failing silently.
- Added `workflow_dispatch` support plus manual release inputs to the release workflow so Discord notifications and packager runs can be retried without cutting a new feature tag.
- Updated release workflow notifications to include the CurseForge download link directly in Discord.
- Polished README / changelog / releasing docs so they reflect the current Rematch flow, rerun workflow, and post-release troubleshooting guidance more accurately.
