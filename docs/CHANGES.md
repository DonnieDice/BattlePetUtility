# v2.2.3 - 2026-04-24

## Changes
- Replaced LibStub / LibDataBroker-1.1 with native `RGXDataBroker` framework module. No external library dependency. Data object proxy behaviour is identical — `addon.databroker.text = ...` still fires display callbacks automatically. If LibDataBroker-1.1 is loaded by another addon, the object is mirrored to it for display addon compatibility.

# v2.2.2 - 2026-04-23

## Changes
- Merged origin/main into dev with resolved conflicts.
- Added RGX-Framework as RequiredDep.
- Hardened RGX module resolution for compatibility.

# v2.2.1 - 2026-04-23

## Changes
- Corrected the TOC bump to interface 120005.

# v2.2.0
- Added `/pb2 icon on|off` slash command to show or hide the minimap icon.
- Added Ctrl+Right-click on the minimap icon to hide it (use `/pb2 icon on` to show again).
- Updated minimap tooltip and options menu to reflect the new icon toggle functionality.
