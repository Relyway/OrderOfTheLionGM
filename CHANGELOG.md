# Changelog


All notable changes to OrderOfTheLionGM are documented here.


## 1.7.3 — 2026-07-21

### Launcher compatibility

- Moved the live addon TOC, Assets and Modules to the repository root.
- Added direct OctoLauncher Git installation support.
- Enabled future one-click updates through Update and Update All.
- Updated validation and release packaging for the new repository layout.
- SavedVariables schema 14 and network protocol 3 remain unchanged.



## [1.7.2] - 2026-07-20

### Added
- Revision-specific announcement read receipts for leadership.
- Exact build identifiers in version discovery and diagnostics.
- Shared Vanilla interaction audit for buttons and edit boxes.

### Changed
- Rebuilt the addon around the modular 1.7.x foundation.
- Restored the compact Guild Chat layout.
- Improved Roster, Professions, Group Finder, Raid Alerts, Treasury, Recruitment, Home, and officer workflows.
- Preserved schema 14 and protocol 3 for compatible upgrades.

### Fixed
- Non-interactive controls caused by missing mouse registration or stale native disabled state.
- Roster promotion, demotion, removal, and note editing.
- Treasury goal editing and deletion.
- Group Finder create, share, join, cancel, whisper, accept, invite, decline, and close actions.
- TurtleRP ChatThrottleLib invalid escape errors caused by unsafe transport payloads.
- Profession cache, favorites, filtering, counters, item details, and migration edge cases.
- Old and malformed SavedVariables recovery without requiring a reset.

Full details: [`docs/RELEASE_NOTES_1.7.2.md`](docs/RELEASE_NOTES_1.7.2.md)

## [1.5.7] - 2026-07

Last legacy release before the modular 1.7.x rebuild.
