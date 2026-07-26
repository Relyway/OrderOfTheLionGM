# Performance Audit 1.7.6 R5

R5 is the final stability pass over the earlier 1.7.6 performance layers. It keeps the R4 cold-login and transition protections, then removes the remaining unnecessary work observed in live reports and screenshot review.

## Live complaints covered

- frequent stutters in different locations and during combat;
- Thunder Bluff/subzone movement and new-zone transitions;
- first login and first addon open;
- mailbox/AH-result loading;
- bag updates and cold item-cache work;
- hidden achievement/UI refreshes;
- notification/network bursts;
- overlapping Treasury and Recruitment dialogs.

## Performance decisions

Performance is prioritized over achievement completeness. The following tracker families remain paused until a narrow and reliable event signal is proven on OctoWoW:

- mail sender and mailbox sender achievements;
- loot roll/pass and `/roll` parsing achievements;
- guild-chat legendary inventory scan;
- world-boss hostile-death stream tracker;
- Gravity Wins combat-log tracker.

Existing completions remain intact. Paused trackers do not run background work.

## R5 guarantees

- Exactly one shared `OnUpdate` heartbeat remains in the addon.
- R5 itself adds no `OnUpdate` handler.
- Achievement checks are detached from `UNIT_HEALTH`.
- Group/raid/world/zone event storms are coalesced.
- `MINIMAP_ZONE_CHANGED` does not trigger a full zone pass.
- Old full login and `BAG_UPDATE` scans remain detached.
- Incremental bag work is limited to one slice every two seconds and deferred in combat.
- Mailbox/AH-result achievement scanning is disabled.
- Network sending is capped to two packets per heartbeat.
- Hidden pages are marked dirty instead of rebuilt.
- `RefreshAll` refreshes only navigation and the visible page.
- Empty queues return before touching their databases.
- No visual maintenance task is added to the heartbeat.
- Saved-variable activity and contribution lists are bounded.

## UI work and cost control

Treasury Activity, per-goal ledgers, Recent Whispers, and the shared modal overlay are built only when their UI is requested. They do not poll, scan, or refresh in the background while closed.

## Validation gates

The release package must pass static validation, performance validation, Lua compilation, focused performance/R5 smoke tests, a full 29-module load and UI-build test, GitHub Actions workflow validation, and a clean extracted-ZIP validation.
