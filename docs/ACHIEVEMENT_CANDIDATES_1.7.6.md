# Achievement Candidate Review — performance-first

No candidate below is enabled in 1.7.6. The purpose of this review is to prevent a second performance regression while preserving good ideas for later releases.

## Safe candidates for a later event-driven pack

These can be implemented from infrequent or already-consumed events without permanent polling:

- **First Friend / Three Voices / Five Banners** — evaluate on faction reputation update, with one debounced faction-list scan.
- **Inventory Tetris** — increment from the specific bag-full UI error and never scan bags.
- **A Bag for Every Occasion** — inspect four equipped bag slots only on bag equipment change/login.
- **Fisherman’s Patience** — count confirmed fishing loot and reset only on zone change.
- **Rising Through the Ranks** — derive from the existing roster rank-change history; no new event frame required.
- **These Hands Are Weapons** — inspect the Unarmed skill only on `SKILL_LINES_CHANGED` and login.
- **Wrong Place to Sleep** — store dungeon state on logout and confirm it at the next login.
- **Mailbox Zero** — record the highest inbox count while the mailbox is open and award when it reaches zero after starting at 20+.

## Possible, but only with strict limits

- **Full Schedule** — `QUEST_LOG_UPDATE` can be noisy. Use a 2–3 second debounce and count quest-log entries once.
- **Old Business** — requires reliable quest completion and difficulty information on this custom client. Do not scan the full quest log continuously.
- **Grave Return** — possible from death/repop/world events, but spirit-healer exclusion must be proven on OctoWoW.
- **Silent Professionals** — track only local outgoing group/raid chat during a confirmed dungeon run. Dungeon completion detection must reuse the boss system.
- **Old Reliable** — count only confirmed successful mount casts, never every action-bar press.
- **Taste of Azeroth** — count confirmed food consumption through a narrow aura/spell result, not inventory scans.

## Rejected or paused for performance/reliability

- **Deep Breath** — exact “under five seconds” detection normally requires continuous breath-bar timing or frequent polling.
- **Oops, Wrong Button** — intercepting every attempted mount action/cast is too broad for one secret achievement.
- **Still Not Ready** — intercepting every Hearthstone attempt/action and cooldown failure is too broad and localization-sensitive.
- **Tuition Fees** — no proven reliable Vanilla/OctoWoW event exposes the exact money spent specifically at class trainers.

## Existing achievement temporarily paused

- **Gravity Wins (D021)** — its broad self-damage combat-log parser is disabled in 1.7.6. Existing completion data is retained; new completion is blocked until a low-cost reliable signal is found.

## Rule for all future achievements

An achievement may ship only when it satisfies all of the following:

1. No new permanent `OnUpdate`.
2. No broad `UNIT_HEALTH`/combat-log/action-hook path for a rare condition.
3. No full bag, roster, profession or quest-log scan more than once per debounced state change.
4. No network broadcast of intermediate personal progress.
5. Bounded SavedVariables maps and dedupe state.
6. A live OctoWoW verification procedure exists before guild-wide release.
