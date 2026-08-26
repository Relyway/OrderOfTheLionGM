# OrderOfTheLionGM 1.8.3 — Final Release

Release build: `release-1.8.3-20260827`  
Interface: `11200`  
Schema / Protocol: `15 / 3`

## Highlights

Version 1.8.3 is the stability and usability release that closes the long RC cycle without adding another large subsystem.

- **Roster presence:** online state refreshes quickly without forcing every login/logout through the entire authoritative roster pipeline. Structural/rank/note/level changes still fall back to the safe sliced full scan.
- **Achievements:** 147 definitions remain intact. Completion is idempotent, cold-login baseline state survives SavedVariables merging, stale announcement entries are rejected, and old completed achievements do not re-fire after reload/relog/zone/profession/character transitions.
- **Professions:** Enchanting rank capture no longer produces the false `0/300` state; exact enchant effects/reagents continue to use the bounded native capture path.
- **Recruitment:** Social 1 → Raid 1 → Social 2 → Raid 2; Sunday 20:00 ST and 2SR > MS > OS are visible in Social defaults, with an 8-minute minimum and 10-minute preferred posting point.
- **Discord sharing:** the dedicated Share Discord message now explains guides, raid information, announcements, help, events, off-game communication and the first guild rank promotion, while staying inside the 240-character chat limit.
- **Support & Report:** one canonical diagnostic flow, privacy-safe Issue Report, deduplicated hard-error reporting and quieter handling of normal FPS/ping/bulk-sync fluctuations.
- **History:** unread accounting is bounded correctly; mass same-size roster churn is confirmed/re-baselined instead of producing hundreds of events; the final build adds a conservative one-time repair for the already-observed synthetic JOIN/LEAVE burst.
- **Profiles / Main-Alt:** foreign professions/achievements, voluntary linked characters, profile showcase/title and Guild Journey remain available with honest mixed-version fallbacks.
- **Performance:** roster/crafting/network work stays sliced/bounded; ordinary 8–12 ms samples at healthy FPS no longer force severe adaptive throttling.

## Upgrade

Install 1.8.3 over the existing addon and keep `WTF/SavedVariables` for the normal upgrade path. Schema remains 15 and protocol remains 3.

Do not delete `WTF` as a routine troubleshooting step: doing so destroys SavedVariables, including local addon history/settings.

## Discord message

The built-in Share Discord preset is:

`[Guild Discord] Join for guides, raid info, announcements, help, events and guild chat. Stay connected outside the game if the server is unavailable. Discord also counts as your first guild rank promotion. https://discord.gg/UNacDPrGt2`

Length: **235 / 240**.

## Final regression emphasis

For a character that already owns **Under the Banner**, **First Fortune** and **Master of the Trade**, `/reload`, relog, zone change, opening a profession and main→alt→main must produce zero duplicate completion popups and zero duplicate guild achievement announcements.

See `LIVE_VERIFICATION_1.8.3.md` and `FINAL_RELEASE_GATE_1.8.3.md`.
