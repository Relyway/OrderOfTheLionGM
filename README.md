# Order of the Lion Guild Manager 1.7.5

OrderOfTheLionGM is the cross-faction guild companion for Order of the Lion on OctoWoW. It targets the Vanilla client (`Interface 11200`) and combines Guild Chat, Guild Achievements, roster history, leadership announcements, professions, crafting requests, raid and group coordination, recruitment, activity, treasury planning, and officer tools.

Current public build: `stable-r7-20260723`. SavedVariables schema remains `14` and network protocol remains `3`, so compatible 1.7.x data is retained without deleting the `WTF` folder.

## 1.7.5 highlights

- **Corrective r6 integration pass:** achievement counters no longer wrap, Activity and Overview keep text above their buttons, Home panels fit within the content area, and the Guild Board composer keeps its counter inside the panel.
- Guild Chat retains keyboard focus after sending, supports Enter-to-focus while its page is active, groups consecutive messages, measures wrapped text, and shows separate channel badges without covering the navigation label.
- Neutral lion artwork replaces faction banners on general guild/tabard achievements.
- Roster empty-state actions stay disabled until a member is selected, crafting synchronization uses the real shared sync state, and destructive Guild Board deletion requires confirmation.
- **142 Guild Achievements** across Social, Group Finder, Professions, Dungeons, Raids, Legacy, and Secrets. The existing achievements remain intact, all 61 achievements from the latest approved implementation pack are represented, with 21 previously missing definitions added using collision-free IDs; threshold chains reuse the same stored counters and bounded sets.
- Correct achievement pagination: changing pages replaces the visible rows instead of appending them. Overview prioritizes completed achievements, then active progress, then locked entries.
- Stable achievement icons with curated Vanilla-safe fallbacks; recycled rows cannot inherit another achievement's texture.
- Secret titles remain visible while exact conditions and numeric progress stay hidden until unlock.
- Guild Chat layout now measures wrapped rows, preserves consecutive messages, suppresses duplicate capture, and uses a dedicated system-row presentation for achievement links.
- Reaction, popup, Inbox, and Recent Activity notifications share canonical deduplication keys, preventing one reaction or network replay from creating multiple entries.
- Professions now present Enchanting effects more clearly, hide the meaningless unknown-level marker, and show visible `+` / `-` favorite controls.
- Guild Activity recommendations no longer overlap the action buttons.
- Raid cards and details separate status, title, date, server time, countdown, meeting point, briefing, Raid Leader, Invite Contact, and Invite Helpers.
- Raid planners can assign a Raid Leader, a main Invite Contact, and helpers. Authorized contacts can use **Start Invites**; guild members receive a compact popup whose Whisper action targets the assigned contact.
- The sidebar keeps fixed primary navigation and utilities around a scrollable guild/officer section, so additional pages do not overlap Treasury or officer controls.
- Home, Treasury, recruitment, Inbox, mention notifications, Addon Users, and version presentation retain the 1.7.4 visual and usability improvements.

## Performance and compatibility

- The addon has one shared heartbeat and no achievement-owned `OnUpdate` handler.
- Group timers use coarse checkpoints no more frequently than once per 60 seconds while relevant.
- No full roster, bag, equipment, party-health, or profession scan runs continuously.
- Boss, duel, resurrection, fishing, emote, and raid-invite state is temporary, bounded, deduplicated, and cleared by timeout or state changes.
- Intermediate personal achievement progress is not broadcast to the guild.
- Existing schema-14 SavedVariables migrate in place; protocol remains 3.

## Installation or update

1. Close World of Warcraft completely.
2. Back up the `WTF` folder.
3. Delete only the old `Interface\AddOns\OrderOfTheLionGM` folder.
4. Extract the install archive into `Interface\AddOns`.
5. Confirm this file exists: `Interface\AddOns\OrderOfTheLionGM\OrderOfTheLionGM.toc`.
6. Start the game and run `/otltest`.

Expected identity:

- Addon version: `1.7.5`
- Build: `stable-r7-20260723`
- Interface: `11200`
- Schema: `14`
- Protocol: `3`
- Modules: `27/27`

Do not delete SavedVariables during a normal update.

## Commands

| Command | Action |
| --- | --- |
| `/otl` | Open or close the manager |
| `/otl scan` | Request a roster update |
| `/otl minimap` | Show or hide the minimap launcher |
| `/otl wizard` | Open the first-run guide |
| `/otl backup` | Export a full local backup |
| `/otltest` | Print module, database, permission, interaction, and network diagnostics |

## Verification

The release tree is checked with static publication rules, Vanilla-compatible Lua parsing for every TOC-loaded module, deterministic Vanilla-oriented runtime scenarios, interaction-tree checks, achievement catalog and threshold checks, notification deduplication, raid invite state protection, and clean install-ZIP extraction.

Offline mocks cannot prove behavior inside the real OctoWoW executable, third-party addon hooks, localized combat/emote text, or a live multi-client dungeon/raid. Complete the supplied live checklist before guild-wide publication, especially boss rules, duel outcomes, resurrection, fishing state, loot messages, text-emote localization, raid invitation delivery, and several UI scales.

## License

MIT. See `LICENSE`.
