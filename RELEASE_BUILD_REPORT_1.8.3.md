# OrderOfTheLionGM 1.8.3 — Release Build Report

Release identity: `1.8.3`  
Build: `release-1.8.3-20260827`  
Interface: `11200`  
Schema / Protocol: `15 / 3`

## Final changes after CP7

- Promoted runtime and TOC identity to plain 1.8.3.
- Restored the dedicated 235/240-character Share Discord guild message with guides, raid info, announcements, help, events, off-game contact, the first guild rank promotion and the current invite URL.
- Migrates only the exact old addon-owned Guild Info/Discord default; real Leadership edits remain untouched.
- Added the one-time conservative History recovery for the live-confirmed retained 248 JOIN / 248 LEAVE synthetic burst pattern. The repair only activates on a large History overwhelmingly dominated by near-balanced JOIN/LEAVE rows, removes only dense short-window JOIN/LEAVE clusters, inserts one reviewed BASELINE row and preserves other history kinds.
- The repair is also applied after backup restore/undo and legacy History import when the restored data has not already been repaired.
- Updated What's New and all release-facing documentation/filenames to plain 1.8.3.

## Static acceptance

- TOC Lua paths: 45 / 45 present.
- Lua syntax parse: 45 / 45 PASS (`texluac -p`).
- Permanent owner counts remain: 13 `OnUpdate` sites / 31 `RegisterEvent` calls / 211 `CreateFrame` calls.
- Runtime/TOC identity: 1.8.3 / release-1.8.3-20260827.
- Old r59 runtime identity hits: 0.
- Merge-conflict markers: 0.
- Achievement runtime files are byte-identical to the accepted CP7 build; the 147-achievement catalogue was not edited in the final pass.
- Social 1 / Social 2 / Raid 1 / Raid 2 lengths: 235 / 232 / 187 / 193.
- Share Discord length: 235 / 240.
- Synthetic History repair harness: 248 JOIN + 248 LEAVE + 4 legitimate rows -> 496 removed, one reviewed BASELINE added, four legitimate unread rows retained; ordinary non-burst History -> no-op.

## Final live smoke

Use `LIVE_VERIFICATION_1.8.3.md` against the exact packaged ZIP. Normal upgrade testing keeps WTF/SavedVariables intact.
