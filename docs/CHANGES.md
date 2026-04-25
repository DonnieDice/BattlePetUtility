# v2.3.0 - 2026-04-25

## Changes
- Full RGX-Framework native migration: removed custom event frame and `_eventHandlers` table. All events, timers, and slash commands now delegated to `RGX:RegisterEvent`, `RGX:After`, `RGX:Every`, and `RGX:RegisterSlashCommand`.
- `RequiredDeps: RGX-Framework` declared in TOC — deterministic load order guaranteed.
