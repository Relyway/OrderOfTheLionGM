# Order of the Lion Guild Manager

**OrderOfTheLionGM 1.8.3** is the Order of the Lion guild companion addon for **OctoWoW / Vanilla Interface 11200**. It combines guild communication, roster and member profiles, professions, PvE coordination, guild achievements, recruitment, activity, Treasury and leadership tools in one Warcraft-style interface.

## Version

- Addon: **1.8.3**
- Build: **release-1.8.3-20260827**
- Interface: **11200**
- Database schema: **15**
- Network protocol: **3**
- Author: **Hikol / Lucks**
- Repository: **Relyway/OrderOfTheLionGM**

## Installation / update

1. Close World of Warcraft.
2. Extract the archive so the file is located at `Interface/AddOns/OrderOfTheLionGM/OrderOfTheLionGM.toc`.
3. Start OctoWoW and enable **Order of the Lion Guild Manager**.
4. For a normal update, **do not delete WTF/SavedVariables**. Existing schema-15 data is upgraded in place.

Deleting WDB/cache files is a separate client troubleshooting step. Deleting `WTF` removes SavedVariables and therefore removes local addon history/settings that no addon can recover automatically.

## Main features

- **Home** — guild posts, next raid, leadership availability, recent activity and reports.
- **Guild Chat** — Guild / Officer / Board views, mentions, safe links and local unread state.
- **Search** — members, professions, recipes, groups and guild content.
- **PvE Hub** — Group Finder, raid events, teams, roles and invite contacts.
- **Roster** — fast online presence, filters, ranks, first-seen data, permitted actions and member details.
- **Guild Profile** — shared profile, Main/Alt links, achievement showcase, Guild Journey and professions.
- **Professions** — shared recipes, exact Enchanting effects where available, reagents, crafters and crafting requests.
- **Guild Achievements** — 147 guild-oriented achievements with protected persistence and shared progress.
- **Recruitment** — Social 1 → Raid 1 → Social 2 → Raid 2 World rotation; 8-minute hard minimum and 10-minute preferred point.
- **Treasury / Activity** — contribution history, goals and useful guild activity summaries.
- **Leadership** — Guild Administration, Recruitment, History, inactive-member tools and private reports/warnings.
- **Support & Report** — one privacy-safe diagnostic flow with Self Check, Full Report and prepared Issue Report.

## Discord

Guild Discord: `https://discord.gg/UNacDPrGt2`

Discord is used for guides, raid information, announcements, help, events and guild chat, and keeps members connected when the game/server is unavailable. Joining with the in-game character name also counts as the **first guild rank promotion** from Guest to full member.

The Recruitment page includes a separate **Share Discord** guild message. It is not part of the automatic Social/Raid World queue.

## Recruitment defaults

The built-in World rotation is:

`Social 1 → Raid 1 → Social 2 → Raid 2 → repeat`

The queue advances only after the player's World-chat echo confirms delivery. Social messages mention the active **Sunday 20:00 ST** raid schedule and **2SR > MS > OS**. Raid 1/2 remain the protected roster-focused messages.

Timing:

- before **8:00** — wait;
- **8:00–9:59** — allowed / amber;
- **10:00+** — preferred / green.

Leadership-edited Social messages are preserved during upgrades; only exact historical addon-owned defaults are migrated.

## Reliability notes for 1.8.3

- Completed achievements are idempotent: an existing `completed[id]` blocks duplicate completion, popup and guild announcement paths.
- Cold-login achievement baseline state is preserved across the temporary-to-guild SavedVariables merge.
- The release contains a one-time, conservative repair for the live-confirmed historical mass JOIN/LEAVE History burst. It only runs when retained History is overwhelmingly dominated by a near-balanced short-window JOIN/LEAVE burst; ordinary history is preserved.
- Online presence uses a lightweight runtime refresh. Membership/rank/level/note changes still escalate to the authoritative sliced roster scan.
- Bulk-only network work is treated as background syncing rather than a hard failure.
- Support does not open automatically and ordinary ping/FPS/network fluctuations do not create red error alerts.

## Support

If something behaves incorrectly:

1. Open **Settings → Support & Report** or **Action Center → Report Issue**.
2. Use **Copy Issue Report**.
3. Paste the generated report into the guild addon-support ticket and add one short sentence describing what you were doing.

The generated support export excludes guild-chat history, officer notes and private moderation/report text.

## Commands

- `/otl` — open/close the addon.
- `/otl center` — recover the main window to the center.
- `/otl park` — park the addon / Quick Dock.
- `/otl minimap` — toggle the minimap button.
- `/otl scan` — request a manual authoritative roster refresh.
- `/otltest` — diagnostics.
- `/otlperf` — performance diagnostics.
- `/otl chatdiag on|dump|off` — temporary Guild Chat geometry trace.
- `/otl enchantdiag on|dump|off` — temporary Enchanting capture trace.
- `/otl perftrace on|dump|off` — temporary bounded slow-operation trace.

## Privacy / sharing

OrderOfTheLionGM shares only data needed for its guild features through the WoW addon-message channel. Remote information is never guessed. Main/Alt identity is voluntary and reciprocal. Private Officer Cases/notes and private report text are not included in ordinary shared payloads or Support exports.

Mixed addon versions are expected. Features that require a newer peer show a calm compatibility message rather than failing or inventing remote data.

## Release documents

- `RELEASE_NOTES_1.8.3.md` — release summary.
- `LIVE_VERIFICATION_1.8.3.md` — short final/live smoke checklist.
- `FINAL_RELEASE_GATE_1.8.3.md` — release acceptance gates.
- `CHANGELOG.md` — development history.

## License

MIT. See `LICENSE`.
