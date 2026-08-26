# OrderOfTheLionGM 1.8.3 — Final Release Gate

Release identity: **1.8.3** / `release-1.8.3-20260827`  
Interface: **11200**  
Schema / Protocol: **15 / 3**

## Static/package gate

The release package must satisfy all of the following before upload:

- Lua parse: all TOC Lua files PASS.
- Every TOC path exists and filename case matches.
- No merge-conflict markers or temporary editor/cache files.
- Achievement catalogue remains 147 total with unique IDs and names.
- Social / Raid protected message lengths remain within the 240-character World limit.
- Share Discord remains within 240 characters including the invite URL.
- Runtime and TOC both report plain `1.8.3` and the same release build.
- Clean package round-trip has no missing/extra/byte-mismatched files.
- `PACKAGE_MANIFEST.txt` matches the packaged files.

## Live correctness gate

- Existing achievements cannot be awarded again after reload/relog/zone/profession/main-alt transitions.
- Fresh low-level alts do not inherit tabard/cloak/riding/profession achievements from another character.
- Roster presence is fast but never owns rank/note/history/first-seen authority.
- Header/Online/Shown counts agree.
- Enchanting rank/effect capture works in the live Vanilla CraftFrame.
- Recruitment uses the confirmed four-step queue and 8/10-minute cadence.
- Leadership-customized Social text is preserved; exact historical addon defaults migrate.
- Support remains quiet for ordinary client/server noise and produces one privacy-safe Issue Report for a real problem.
- Backup/restore works on the current large schema-15 database.
- Guild Administration write paths are verified against live guild permissions.

## 1.8.3 history repair gate

The final build includes one strict one-time repair for the live-confirmed retained History pattern dominated by a near-balanced short-window JOIN/LEAVE burst. It must:

- require a large retained history (>=300 rows) dominated by JOIN/LEAVE;
- require at least 100 JOIN and 100 LEAVE overall with a near-balanced total;
- remove only dense short-window JOIN/LEAVE clusters;
- keep rank/level/return/note/other legitimate history rows;
- replace a removed synthetic cluster with one reviewed BASELINE record;
- recount unread state afterward;
- store a per-guild completion marker so it never repeatedly rewrites History.

## Release packaging

GitHub/public upload should use the clean `OrderOfTheLionGM-1.8.3.zip` package. Historical CP/R recovery archives are development checkpoints and should not be mixed into the installable addon directory.
