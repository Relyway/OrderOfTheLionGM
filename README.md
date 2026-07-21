# Order of the Lion Guild Manager 1.7.3

OrderOfTheLionGM is the guild companion for Order of the Lion on OctoWoW. It targets the Vanilla client (`Interface 11200`) and combines guild communication, roster history, leadership announcements, professions, crafting requests, PvE coordination, recruitment, activity, treasury planning, and officer tools.

This package is the stable 1.7.2 baseline. Its build identifier is `stable-r3-20260720`. It keeps schema 14 and protocol 3, so existing SavedVariables and compatible 1.7.x guild data are retained.

## Stable interaction foundation

The live failure was not caused by missing guild permissions. Bare script-created controls were displayed by OctoWoW but were not consistently registered for mouse input. Several retained UI generations also stored enabled state in different fields, allowing a button to look active while its native Button state remained disabled.

The stable foundation now:

- explicitly prepares every Button, CheckButton, EditBox, and Slider for the Vanilla client;
- registers left-click input for every actionable control while preserving intentional right-click registrations;
- uses one enabled-state function across the base UI and all later UI modules;
- reconciles logical and native enabled states whenever a page opens;
- repairs a page only on open or refresh, with no new polling or permanent `OnUpdate` work;
- reports the last interaction audit in `/otltest`.

This applies to Roster actions and notes, Treasury controls, Group Finder actions, raid and board controls, Guild Chat, Professions, Recruitment, Settings, dialogs, navigation, and all other retained pages.

## 1.7.2 additions

- Presence/version packets no longer use raw pipe delimiters that can trigger TurtleRP ChatThrottleLib escape errors.
- The transport boundary strips control bytes and safely encodes accidental raw pipes before transmission.
- Version discovery now carries the exact build identifier while still accepting legacy 1.7.1 packets.
- Opening the full announcement records a revision-specific read receipt. Leadership can inspect names through the `Read by N` button.
- Read receipts do not replace Like, Acknowledge/Seen, or Support reactions.

## Other 1.7.x improvements

- Schema-14 migration repairs old, partial, and malformed SavedVariables without requiring a reset.
- Profession data survives rescans, cold item-cache states, favorites, filters, and sorting changes.
- Item level, required use level, required profession skill, effects, materials, and quality are displayed from native data without guessing.
- Guild Chat uses the compact column layout rather than the rejected large author-card redesign.
- Group Finder opens as a list first and provides working create, share, join, cancel, whisper, accept, decline, invite, and close actions.
- Roster officer actions validate both the acting player and the selected target rank.
- Treasury uses consistent gold units and safe manual shared-goal editing.
- Network synchronization coalesces duplicate requests and safely skips packets addressed to other players.
- Quick Lion Menu remains removed; actions live in their relevant pages.
- Text and icons avoid unsupported Vanilla Unicode glyphs.

## Installation or update

1. Close World of Warcraft completely.
2. Back up the `WTF` folder.
3. Delete only the old `Interface\AddOns\OrderOfTheLionGM` folder.
4. Extract the install archive into `Interface\AddOns`.
5. Confirm this file exists:
   `Interface\AddOns\OrderOfTheLionGM\OrderOfTheLionGM.toc`
6. Start the game and run `/otltest`.

The diagnostic output must include:

- `Addon version: 1.7.2`
- `Build: stable-r3-20260720`
- `UI interactive controls (buttons/editboxes/repaired): ...`

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

## Verification status

The source and final install package are checked with:

- Lua 5.1 parsing for all 21 TOC-loaded Lua files;
- 40 static packaging and Vanilla-compatibility checks;
- duplicate-definition analysis;
- 172 deterministic runtime scenarios;
- an interaction-tree audit covering 654 buttons and 39 edit boxes;
- real click-gate simulation that rejects hidden, mouse-disabled, unregistered, or natively disabled controls;
- explicit Roster, Treasury, remote Group Finder, leader applicant, whisper, share, accept, and invite scenarios;
- clean ZIP extraction and byte-for-byte comparison.

A mock cannot replace the real OctoWoW client. Use the supplied live checklist on the Guild Leader and a second guild character before a guild-wide rollout.

## License

MIT. See `LICENSE`.
