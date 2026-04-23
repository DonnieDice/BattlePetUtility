# Workflow Files

This directory contains GitHub Actions workflows for PetBuddy2.

## Current Workflow

- `release.yml` - Packages the addon, updates GitHub releases, posts Discord notifications, and publishes to configured packager targets.

## Operational Notes

- Tag pushes like `v2.0.2` are the normal feature-release path.
- Manual `workflow_dispatch` runs are for reruns, notification fixes, and packager retries.
- Manual runs can target an existing tag while still using the current workflow logic from `main`.

## Maintenance Rules

- Keep changelog extraction limited to the newest version section for Discord.
- Keep release links aligned with the canonical repository location: `DonnieDice/PetBuddy2`.
