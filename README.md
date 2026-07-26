# Order of the Lion Guild Manager 1.7.6

OrderOfTheLionGM is the cross-faction guild companion for **Order of the Lion** on OctoWoW. It targets the Vanilla client (`Interface 11200`) and combines Guild Chat, Guild Achievements, roster and activity history, leadership announcements, professions and crafting requests, PvE coordination, recruitment, Treasury planning, and officer tools.

Current build: `performance-r5-hotfix1-20260726`.

SavedVariables schema remains `14` and network protocol remains `3`. Normal updates preserve existing 1.7.x settings, achievement progress, roster data, profession data, Treasury goals, and PvE records.

## Performance and stability priorities

Version 1.7.6 R5 is a stability-first rebuild over the 1.7.5 release. Hotfix 1 adds only four event-driven Treasury donor achievements; it does not restore any risky continuous tracker. Several expensive trackers remain paused where reliable detection is not worth client stalls.

- The addon retains one shared `OnUpdate` heartbeat. R5 adds no second heartbeat.
- `UNIT_HEALTH` no longer drives achievement scans.
- Duplicate group, raid, world-entry, and zone callbacks are coalesced into bounded stable passes.
- Thunder Bluff and other same-zone subzone changes no longer trigger full group or achievement work.
- Cold-login work is deferred and released in small slices.
- Bag achievements use an incremental scanner, throttled outside combat. The old full `BAG_UPDATE` and login scans remain detached.
- Mailbox/AH-result achievement scanning is paused. Opening a mailbox does not walk the inbox for achievements.
- Hidden pages are marked dirty rather than rebuilt during gameplay.
- `RefreshAll` refreshes only navigation and the currently visible page.
- Network processing is capped to a small packet budget per heartbeat.
- Empty crafting, PvE, Treasury, icon, and announcement queues return immediately.
- Achievement UI refreshes only while the Achievements page is visible.
- Risky broad combat/system-message trackers remain paused for performance safety.

These changes reduce known Lua spikes but cannot guarantee that every client-side stutter comes from this addon. Live comparisons should disable only OrderOfTheLionGM and fully reload the client.

## Completed R5 workflows

### Treasury

- **Treasury Activity** shows a bounded history of contributions, goal changes, and deletions.
- **View Ledger** opens the selected funding goal in its own modal.
- The ledger shows raised, target, remaining, every contributor's total, contribution count, and the paginated individual payment history.
- Contribution records include contributor, amount, recorder, timestamp, and note.
- Existing 1.7.6 contribution records and earlier goal history migrate into the activity stream once, without duplication.
- Every goal row has direct **Ledger** and **+ Gold** actions.
- Ledger and contribution rows resolve the contributor's current class, guild rank, level, and class color from the already-cached guild roster. No background roster scan is added.
- Only one Treasury or Recruitment modal can be active at a time. The shade is limited to the addon window (or the dialog bounds when the main window is hidden), and every input/button is raised above it.

### Treasury donor achievements

The named donor receives cumulative local achievement progress; the officer who records somebody else's contribution receives nothing from that entry. Leadership broadcasts only the bounded donor total on an explicit contribution and can send the requesting donor's total during Treasury synchronization.

- **First Coin for the Pride** — 5 gold
- **Helping Paw** — 25 gold
- **Patron of the Lion** — 50 gold
- **Golden Benefactor** — 100 gold

### Recruitment

- Recent whisper rows bind the Invite action to the correct player.
- Guild invites validate the player name, self-invites, existing guild membership, client API availability, and rank permission.
- Recently sent invites show `Sent`; guild members show `Member`.
- The recent-whisper list remains session-only and does not grow SavedVariables.

### Interface corrections

- The parked `OTL` edge tab is smaller and positioned lower.
- `/otl center`, `/otl park`, `/otl park left`, and `/otl unpark` safely recover or park the main window.
- Recruitment status controls no longer share the same text area.
- Recent Whispers no longer overlaps the World Recruitment card.
- Guild Chat pin controls are smaller and quieter.
- Technical `actor unavailable` text is removed from visible activity/history rows.

## Installation

1. Close World of Warcraft completely.
2. Delete the old `Interface\AddOns\OrderOfTheLionGM` folder.
3. Extract the supplied ZIP into `Interface\AddOns`.
4. Confirm the resulting file exists:

   `Interface\AddOns\OrderOfTheLionGM\OrderOfTheLionGM.toc`

5. Start the game and run `/otltest`.

Do not delete SavedVariables or the `WTF` folder for a normal update.

Expected identity:

- Version: `1.7.6`
- Build: `performance-r5-hotfix1-20260726`
- Interface: `11200`
- Schema: `14`
- Protocol: `3`
- TOC Lua files: `30`
- Registered modules: `29`

## Commands

| Command | Action |
| --- | --- |
| `/otl` | Open or close the manager |
| `/otl scan` | Request a roster update |
| `/otl minimap` | Show or hide the minimap launcher |
| `/otl center` | Return the main window to the center |
| `/otl park` | Park the window at the right edge |
| `/otl park left` | Park the window at the left edge |
| `/otl unpark` | Restore the normal window position |
| `/otl backup` | Export a local backup |
| `/otltest` | Print module, database, permission, UI, and network diagnostics |
| `/otlperf` | Print performance counters |
| `/otlperf reset` | Reset performance counters |

## Release validation

The full package is checked with:

- TOC/file coverage and clean-install structure checks;
- UTF-8, BOM, ASCII/Vanilla-font, and absolute-path checks;
- raw UI-control interaction checks;
- unsupported API and syntax checks;
- one-heartbeat enforcement;
- Lua compilation for every TOC module;
- performance-layer static rules;
- focused R5 runtime scenarios;
- full 30-file load, complete UI build, page navigation, modal interaction, donor ownership, and refresh smoke tests;
- ZIP extraction and integrity verification before publication.

These offline checks cannot reproduce every behavior of the OctoWoW executable, third-party hooks, live guild synchronization, or every localized game message. They are release gates, not a substitute for a short live test.

## License

MIT. See `LICENSE`.
