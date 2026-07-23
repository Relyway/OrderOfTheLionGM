## 1.7.5 stable-r7 (2026-07-23)

- Fixed Guild Chat page-level keyboard capture that blocked movement, jumping and normal gameplay keys while the page was merely open.
- Guild Chat now captures keyboard input only while its EditBox is actually focused.
- Opening Guild Chat or switching channels no longer forces typing mode.
- After sending a message, the input remains focused for rapid follow-up messages.
- Pressing Escape while typing now saves the draft, releases input focus and immediately restores character controls without closing the addon.
- No new OnUpdate handlers, schema changes or protocol changes.

# Changelog
## 1.7.5 stable-r6 (2026-07-23)
- Fixed the Overview card nil-field error and separated the Activity insight panel from the heatmap.
- Added 21 previously missing approved achievements, bringing the catalog to 142.
- Grouped related achievement tiers through shared series metadata while preserving published names.
- Added event-driven money, bag, mail, level, loot-roll, trade, world-boss and fall-death trackers.
- Filtered implausible bulk roster deltas from summaries and the default History view.
- Moved Activity to the bottom of the Guild navigation section.


All notable changes to OrderOfTheLionGM are documented here.

## 1.7.5 hotfix r5 — 2026-07-23

- Fixed remaining achievement category-counter wrapping and made general tabard achievements use neutral lion artwork instead of Horde or Alliance banners.
- Kept the Guild Chat input focused after send and made Enter focus the addon chat while the Guild Chat page is active, without stealing focus from modals or other edit boxes.
- Tightened wrapped-message measurement and continuation grouping, and resized the separate Guild, Officer, and Board badges so they do not cover the navigation label.
- Reflowed Guild Activity, Overview, Home, raid details, and the Guild Board composer to prevent text, counters, and actions from escaping their panels.
- Preserved the proven Treasury geometry while improving unsupported-server wording and readable goal-history entries.
- Corrected roster empty-state control handling, crafting synchronization state reporting, Guild Board delete confirmation, and Group Finder create/update wording.
- Preserved version 1.7.5, the 121-achievement catalog, SavedVariables schema 14, network protocol 3, and the single shared heartbeat.

## 1.7.5 hotfix r4 — 2026-07-23

- Rebuilt raid editing and raid details into non-overlapping Basic Information, Raid Team, Notifications, and action sections.
- Replaced approximate Guild Chat row sizing with measured text height and restored compact grouping for consecutive messages from one sender.
- Added separate Guild, Officer, and Guild Board unread badges, with mention highlighting that does not erase channel counts.
- Moved Guild Activity guidance into a dedicated strip above its action buttons.
- Removed achievement-page rebuilds from hover handlers, preventing flicker, disappearing cards, and cursor-triggered stalls.
- Added robust custom-tabard detection for **Under the Banner** while preserving its permanent achievement ID.
- Added 34 lightweight threshold achievements that reuse existing counters and bounded sets, bringing the catalog to 121.
- Added an officer-confirmed Darkmoon Faire status on Home without pretending the Vanilla client exposes a reliable world-wide location API.
- Added editable Guild Info and Share Addon recruitment presets with reset-to-default controls.
- Preserved public version 1.7.5, schema 14, protocol 3, and backward-compatible SavedVariables.

## 1.7.5 hotfix r3 — 2026-07-22

- Restored Vanilla/Lua 5.0 compatibility by removing the Lua 5.1 vararg expression from the emote hook.
- Moved the 1.7.5 extension back into its own module and loaded the stable core Events module first, so slash commands and the minimap button remain available even if an optional release extension fails.
- Preserved the full 1.7.5 achievement catalog and SavedVariables compatibility.

## 1.7.5 hotfix r2 — 2026-07-22

### Fixed

- Removed all `string.match` and `string.gmatch` calls that are unavailable in the live Vanilla-style runtime and caused repeated `Security.lua` failures.
- Embedded the 1.7.5 runtime in the already-existing Events module so the update still loads when a folder merge accidentally retains the older 1.7.4 TOC.
- Restored **Under the Banner** with its original permanent ID and migration of earlier completion data.
- Updated the catalog total to 87 achievements and added login/equipment checks for the guild tabard.
- Bumped the internal build identifier to `stable-r2-20260722`; public version remains 1.7.5.

## 1.7.5 — 2026-07-22

### Added

- Added 40 approved achievements to the existing 46 and restored Under the Banner, for a total catalog of 87 permanent achievements.
- Added social composition, long-session, reunion, duel, Guild Leader, dungeon, survival, resurrection, raid-class, fishing, epic-loot, meta, crafting, riding, and secret achievement conditions.
- Added Raid Leader, Invite Contact, and Invite Helpers fields to raid creation and editing.
- Added Start Invites / Announce Again workflow with authenticated metadata, a five-minute repeat guard, Inbox persistence, compact popup, and direct Whisper action.
- Added a full 1.7.5 achievement catalog, release notes, test report, and live verification checklist.

### Changed

- Reworked achievement Overview ordering to show completed entries first, then in-progress entries, then locked entries.
- Reworked achievement pagination so every page contains only its own rows.
- Reworked raid cards and raid details into distinct status, date, time, countdown, meeting, briefing, leader, contact, and helper sections.
- Improved Enchanting result presentation and recipe detail behavior.
- Increased safe Guild Chat wrapping capacity and retained author/time context for consecutive messages.
- Moved Guild Activity guidance away from bottom action buttons.
- Updated diagnostics to report 23/23 modules.

### Fixed

- Fixed recycled achievement rows inheriting incorrect or question-mark icons.
- Fixed duplicate reaction notifications across Inbox, popups, and Recent Activity.
- Fixed duplicate Guild Chat capture and wrapped messages overlapping following rows.
- Fixed stale raid metadata being able to close or rewind a newer invite state.
- Fixed unknown profession-level cells displaying a permanent `U?` marker.
- Fixed profession tooltips opening over the detail card when there is room on the opposite side.
- Fixed hostile-capital achievement checks so noisy health events are constant-time outside relevant zones.
- Preserved version 1.7.4 achievement progress, schema 14, protocol 3, and compatible SavedVariables without requiring a reset.

## 1.7.4 — 2026-07-22

### Added

- Added 46 permanent Guild Achievements across Social, Group Finder, Professions, Dungeons, Raids, Legacy, and Secrets.
- Added a separate Raids achievement category, search, All / Completed / In Progress / Locked filters, category counters, completion dates, and visible secret titles.
- Added clickable achievement links, Shift-click insertion into the active Blizzard chat box, compact closable toasts, and guild-chat announcements enabled by default.
- Added Guild Chat mention notifications with Inbox persistence and message targeting.
- Added Treasury contribution guidance for mailing gold or items to Morrow with the intended goal stated.
- Added visible plus/minus recipe favorite controls.

### Changed

- Rebuilt the sidebar as fixed primary navigation, a scrollable guild/officer section, and a fixed utility footer.
- Reworked Home to give more space to announcements and the important or next raid, including date, server time, countdown, leader, location, and note.
- Moved Guild Inbox into a centered modal overlay instead of covering Home content.
- Changed achievement chat output to `[Guild Achievement] Player earned [Achievement].` with only the achievement title linked.
- Simplified Addon Users display to public versions only; exact builds remain in diagnostics.
- Updated the protected recruitment addon preset with the full download URL and concise functional benefits.
- Kept only Side by Side and Five as One as ordinary group-composition achievements; dungeon boss credit requires at least three guild members.

### Fixed

- Prevented left-navigation section labels, Treasury, officer tools, and utility controls from overlapping as pages are added.
- Fixed achievement icons being reused by recycled rows.
- Fixed profession achievement reevaluation after scans and migrations.
- Fixed secret cards to hide conditions while retaining their clue titles.
- Added bounded progress sets, event deduplication, membership-period handling, and safer same-zone group presence checks.
- Preserved schema 14, protocol 3, and backward-compatible SavedVariables migration.

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
