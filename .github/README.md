# GitHub Automation

This directory holds GitHub-specific project automation for PetBuddy2.

## Purpose

- Store workflow definitions used for packaging, releases, and notifications.
- Keep repository automation separate from addon runtime code.

## Contents

- `workflows/` - GitHub Actions workflows for packaging, release uploads, and Discord notifications.

## Notes

- Workflow-only changes should usually land on `main` without a new addon tag unless they are part of a real feature release.
- Release automation depends on repository secrets such as `DISCORD_WEBHOOK` and `CF_API_KEY`.
