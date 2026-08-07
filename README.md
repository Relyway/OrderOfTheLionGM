# Order of the Lion Guild Manager

**OrderOfTheLionGM 1.8.0** is a guild companion addon for **OctoWoW / Vanilla Interface 11200**. It combines guild communication, roster tools, professions, PvE coordination, achievements, activity information and leadership utilities in one Warcraft-style interface.

## Main features

- **Home** — guild posts, next raid, leadership availability and useful recent activity.
- **Guild Chat** — Guild / Officer / Guild Board views, mentions, pinned highlights and safe chat input handling.
- **Search** — members, recipes, groups and posts with native deep links to the selected result.
- **PvE Hub** — Group Finder, raid events, Raid Teams, roles, invite contacts and roster management.
- **Roster** — search, filters, rank/online state, member cards, first-seen/join tracking and permitted guild actions.
- **Professions / Crafting Network** — recipe search, reagents, crafters, requests and shared profession data.
- **Achievements** — 146 guild-oriented achievement definitions with event-driven progress tracking.
- **Treasury** — goals, contribution records and donor history where shared data is available.
- **Activity** — ST-based activity heatmap, class/level composition and observed Alliance/Horde guild composition.
- **Officer tools** — Overview, Recruitment, History and Inactive-member workflows.
- **Settings / diagnostics** — UI scale, window size, Fit/Compact modes, network/backup controls and diagnostics.

## Installation

1. Close World of Warcraft.
2. Extract the archive so the path is `Interface/AddOns/OrderOfTheLionGM/OrderOfTheLionGM.toc`.
3. Start OctoWoW and enable **Order of the Lion Guild Manager**.
4. For a normal upgrade, **do not delete SavedVariables/WTF**. Version 1.8.0 keeps `OTLGM_DB` and migrates compatible data in place.

## Commands

- `/otl` — open/close the addon.
- `/otl center` — recover the main window to the center.
- `/otl park` — park the addon and show the small restore crest.
- `/otl minimap` — toggle the minimap button.
- `/otl scan` — request a manual roster update when available.
- `/otltest` — diagnostics.
- `/otlperf` — performance diagnostics.

## UI sizing and foreground clocks

Interface-scale presets and window-size presets are independent. **Fit** keeps the shell inside the usable UI workspace, while **Compact** reduces the window layout. Window and Park positions are stored separately and are rebased when the screen/UI scale changes.

The shared **ST** header clock is driven by one keyed foreground task only while the addon window is visible. Closing or parking the window cancels it; reopening/unparking explicitly resumes it. Quiet pages use a 30-second cadence because the header displays minutes only. Recruitment/Guild Chat/Professions/Treasury add their small page-specific recovery work to the same foreground pulse instead of creating permanent timers.

## Faction composition

OctoWoW can place Alliance and Horde characters in the same guild, while the Vanilla guild-roster tuple does not expose faction for every roster entry. Activity therefore counts faction only from direct evidence: player/party/raid unit tokens, opportunistic target observation while its existing achievement tracker is active, or a compatible addon peer reporting its own faction in the existing presence packet. Unobserved characters remain **Unknown**. The addon never guesses faction from class, race, name or zone.

Total and online composition are calculated together in one roster pass and cached until the committed roster or observed faction evidence changes. No faction polling loop or new protocol version is used.

## Performance model

The addon is designed to stay quiet while not in use:

- one keyed scheduler sleeps when no task is due;
- hidden pages are marked dirty instead of being continuously rebuilt;
- large lists use bounded/reused rows and explicit visible capacities;
- roster, crafting and network queues are bounded and event-driven;
- no new permanent `OnUpdate` was added for final 1.8 fixes;
- noisy achievement sources are dynamically registered only while their corresponding achievement still needs them;
- completed loot/riding/tabard/duel/rabbit/emote/trade/craft trackers release their listeners and backup restore can re-enable them when needed;
- legacy boss target/combat tracking is context-owned and stays detached in the open world where supported-instance achievements cannot progress;
- mailbox achievement work is sliced to at most four headers per scheduler pass;
- Activity total/online composition is cached from one roster pass;
- Activity retention/weekly peak boundaries use real latest-sample / peak timestamps instead of a day's first sample.

## Compatibility

- Interface: **11200**
- Addon version: **1.8.0**
- Build: **final-public-20260808**
- Database schema: **15**
- Network protocol: **3**

Some OctoWoW-specific guild, Treasury, profession, multi-client and server-chat behavior can only be fully verified in the live client. See `LIVE_VERIFICATION_1.8.0.md`.

## Repository

GitHub: `Relyway/OrderOfTheLionGM`

Author: **Hikol** — in game: **Lucks / Morrow**
