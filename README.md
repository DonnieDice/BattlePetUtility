# Better Pet Buddy
Modern maintenance fork of PetBuddy for World of Warcraft Retail (Midnight).

## What It Does
Better Pet Buddy is a battle pet utility panel focused on fast team management while questing and pet battling.

Core features:
- Team HUD with pet health and experience bars
- Drag-and-drop battle pet slot swapping
- Active ability swapping directly in the HUD
- Utility items flyout (bandages, stones, treats, charms)
- Rematch-integrated loadout browsing and loading (when Rematch is enabled)
- Built-in PetBuddy loadouts as fallback when Rematch is not enabled
- Auto-heal at stable masters
- Auto-resummon companion pets
- LibDataBroker launcher with wounded-pet and charms info

## Commands
- `/pb`
- `/petbuddy`
- `/betterpetbuddy`
- `/bpb`

## Compatibility
- WoW Retail interface: `120001` (Midnight)
- Includes compatibility shims for modern namespaced spell and gossip APIs
- Optional integration with `Rematch` for cross-compatible team loadouts

## Installation
1. Copy the addon folder into `World of Warcraft/_retail_/Interface/AddOns`.
2. Ensure the folder name is `BetterPetBuddy`.
3. Launch/reload WoW and enable **Better Pet Buddy**.

## Packaging and Releases
This repository includes:
- `.pkgmeta` for BigWigs packager configuration
- `.github/workflows/release.yml` for tagged release packaging

To publish to CurseForge/WoWInterface from CI, add the required project IDs/tokens in your TOC/secrets before tagging releases.

