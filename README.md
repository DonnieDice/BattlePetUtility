<div align="center">

# <span style="color:#58be81">PetBuddy2</span>
### <span style="color:#4ecdc4">Battle Pet HUD and Utility Panel for WoW Retail Midnight</span>

[![WoW Retail](https://img.shields.io/badge/WoW-Retail%20Midnight-58be81?style=for-the-badge&logo=worldofwarcraft)](https://worldofwarcraft.com)
[![Interface](https://img.shields.io/badge/Interface-120000%2C120001-4ecdc4?style=for-the-badge)](#compatibility)
[![Version](https://img.shields.io/badge/Version-v1.0.0-7598b6?style=for-the-badge)](./docs/CHANGES.md)
[![Discord](https://img.shields.io/badge/Discord-RGX%20Mods-7289da?style=for-the-badge&logo=discord)](https://discord.gg/rgxmods)

[![GitHub release](https://img.shields.io/github/v/release/donniedice/PetBuddy2?style=flat-square&logo=github)](https://github.com/donniedice/PetBuddy2/releases)
[![GitHub stars](https://img.shields.io/github/stars/donniedice/PetBuddy2?style=flat-square&logo=github)](https://github.com/donniedice/PetBuddy2/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/donniedice/PetBuddy2?style=flat-square&logo=github)](https://github.com/donniedice/PetBuddy2/issues)
[![License](https://img.shields.io/github/license/donniedice/PetBuddy2?style=flat-square&logo=github)](./LICENSE)

[Features](#features) | [Quick Start](#quick-start) | [Commands](#command-reference) | [Installation](#installation) | [Compatibility](#compatibility) | [Support](#support)

</div>

## Support RGX Mods

<div align="center">

Your support helps keep RGX addons maintained and updated.

[![Donate](https://img.shields.io/badge/Donate-CashApp-00C853?style=for-the-badge&logo=cash-app&logoColor=white)](https://bit.ly/3fyxxSU)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-Support-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/donniedice)
[![GitHub Sponsor](https://img.shields.io/badge/Sponsor-GitHub-ff69b4?style=for-the-badge&logo=github-sponsors&logoColor=white)](https://github.com/sponsors/donniedice)

</div>

## What is PetBuddy2?

PetBuddy2 is a battle pet control HUD for Retail Midnight that keeps team status, pet utility actions, and loadouts in one compact frame.

It is built to stay usable during normal pet content without requiring external embedded libraries.

## Features

<div align="center">

| Feature | Description |
|---------|-------------|
| Team HUD | Shows active team slots with health and XP bars |
| Drag and Drop | Move pets between battle slots quickly |
| Ability Controls | Swap active pet abilities directly from the frame |
| Utility Quick Buttons | Heal, bandage, currencies, stones, rewards, and pet consumables |
| Native Loadouts | Save, rename, overwrite, restore, and delete loadouts without Rematch |
| Optional Rematch Helper | Shift-click Save to open Rematch save flow when installed |
| Auto Heal | Stable-master automation support |
| Auto Resummon | Companion resummon with trigger handling for common state transitions |
| Charms Display | Aggregates pet charm item and currency counts |
| UI Controls | Scale, font, texture, and visibility options |

</div>

## Quick Start

1. Install the addon to your Retail AddOns folder.
2. Enter game and run `/petbuddy`.
3. Right-click the frame to open options.
4. Enable the utility/loadout sections you want visible.
5. Save your first loadout from the loadout save button.

## Command Reference

<div align="center">

| Command | Description |
|---------|-------------|
| `/petbuddy` | Toggle PetBuddy2 frame |
| `/petbuddy help` | Show command help |
| `/petbuddy welcome` | Toggle login welcome message |
| `/petbuddy version` | Print installed addon version |

</div>

Additional aliases currently available:
- `/pb`
- `/bpb`

## Compatibility

| Target | Value |
|--------|-------|
| WoW Client | Retail Midnight |
| Interface | `120000,120001` |
| Addon Version | `v1.0.0` |
| Required External Libraries | None |
| Optional Addons | `Rematch`, `BattlePetBreedID`, `LibDataBroker-1.1` |

## Installation

1. Copy `PetBuddy2` to `World of Warcraft/_retail_/Interface/AddOns`.
2. Confirm folder name is exactly `PetBuddy2`.
3. Restart or reload the client.
4. Enable PetBuddy2 in the AddOns list.

## Troubleshooting

If behavior looks stale after updates:
- Run `/reload`.
- Ensure you do not have multiple `PetBuddy2` copies in AddOns.
- Confirm the version in chat with `/petbuddy version`.
- Check `docs/CHANGES.md` for the latest expected behavior.

## Documentation

- Changelog: [docs/CHANGES.md](./docs/CHANGES.md)
- Docs Index: [docs/README.md](./docs/README.md)
- Roadmap: [docs/ROADMAP.md](./docs/ROADMAP.md)

## Support

- Discord: [discord.gg/rgxmods](https://discord.gg/rgxmods)
- Issues: [GitHub Issues](https://github.com/donniedice/PetBuddy2/issues)

---

<div align="center">

### Part of the RGX Mods Collection

[BLU](https://github.com/donniedice/BLU) |
[CCU](https://github.com/donniedice/CoordinationCloakUtility) |
[SQP](https://github.com/donniedice/SimpleQuestPlates) |
[FFLU](https://github.com/donniedice/FFLU) |
[SRLU](https://github.com/donniedice/SRLU)

Made by DonnieDice and the RGX community.

</div>
