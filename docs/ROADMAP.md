# PetBuddy2 Roadmap

PetBuddy2 is currently in a stability and UX-polish phase for Retail Midnight.

## Active Focus

1. Midnight compatibility upkeep
- Track Retail API changes and keep compatibility shims current.
- Validate frame XML and template behavior each interface bump.

2. Loadout reliability
- Keep native PetBuddy loadouts dependable in all common UI states.
- Maintain optional Rematch interoperability without making it required.
- Keep account-wide saved loadouts realtime and consistent across characters.

3. Utility and layout polish
- Continue refining utility menu behavior and button presentation.
- Improve long-list usability for players with many saved loadouts.
- Reorganized options menu with Frame Options at the bottom and proper item category submenu.
- Continue polishing the zone tracker layout and glanceability without regressing the shared HUD alignment.

4. Automation confidence
- Maintain auto-summon and auto-heal trigger reliability.
- Reduce edge-case regressions from state transitions (zoning, death, vehicle, combat).
- Keep startup refresh behavior cheap and reliable so pets, loadouts, and the zone tracker all restore cleanly after reload.

5. Release hygiene
- Keep TOC metadata, README, and docs synchronized per release.
- Keep changelog entries concise and behavior-focused.
- Replaced the placeholder addon icon with a proper PetBuddy2 icon asset and updated TOC metadata to use it.

## v3 Candidates

- **Custom dropdown with on-hover live previews.** Replace `EasyMenu`/`UIDropDownMenu` with a self-contained custom dropdown frame (no external libraries — PB2 must remain dependency-free) so font / bar-texture / tracker-background entries can render real-time previews on hover (font-name rows rendered in their own typeface, status bar texture previewed at full width, background color/opacity previewed on the tracker itself). This will also fix the nested menu dropdown arrow vertical alignment issue inherent to Blizzard's UIDropDownMenu template.
- **Global font color option.** ColorPickerFrame-driven font color applied to all PB2 FontStrings, excluding information-bearing quality colors (zone tracker species rows, tooltip rarity text).
