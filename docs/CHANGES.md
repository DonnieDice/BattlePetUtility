# Changes

## v2.0.1

- Normalized non-documentation asset and UI file paths to lower case, including the `media/` directory and XML layout filenames, while intentionally leaving documentation files and the addon manifest naming alone.
- Updated in-repo asset references to match the lower-case path cleanup so TOC, XML, Lua media registration, and button/icon paths stay in sync.
- Hardened the release workflow Discord notification path so webhook responses are awaited and validated instead of failing silently.
- Added `workflow_dispatch` support plus manual release inputs to the release workflow so Discord notifications and packager runs can be retried without cutting a new feature tag.
- Updated release workflow notifications to include the CurseForge download link directly in Discord.
- Polished README / changelog / releasing docs so they reflect the current Rematch flow, rerun workflow, and post-release troubleshooting guidance more accurately.
