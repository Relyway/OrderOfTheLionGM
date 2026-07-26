# OrderOfTheLionGM 1.7.6 Performance R5 Hotfix 1

Build: `performance-r5-hotfix1-20260726`

R5 Hotfix 1 keeps the stability-first runtime and fixes the modal, Treasury and donor-credit problems reported from the live R5 screenshots. It remains a full install release.

## Performance and stability

- Keeps one shared heartbeat and adds no new `OnUpdate` handler.
- Removes achievement work from `UNIT_HEALTH`.
- Coalesces duplicate world-entry, zone, group, and raid updates.
- Ignores same-zone minimap/subzone noise for full achievement/group work.
- Defers cold-login tasks and processes them in bounded steps.
- Keeps the old full login/BAG_UPDATE scans detached.
- Processes incremental bag work no more than one slice every two seconds and outside combat.
- Pauses mailbox/AH-result achievement scanning instead of iterating inbox headers during mailbox loading.
- Caps network queue processing to two packets per heartbeat.
- Skips hidden-page rebuilds and collapses `RefreshAll` to the visible page.
- Leaves broad combat/system-message achievement trackers paused when their reliability does not justify their cost.

## Treasury completion

- Adds a dedicated Treasury Activity modal with All, Contributions, and Goal Changes filters.
- Adds a per-goal Ledger modal with totals, remaining amount, every contributor aggregate, and paginated individual entries.
- Migrates existing contribution/history records once and keeps the activity stream bounded.
- Adds **Ledger** and **+ Gold** actions directly to every funding-goal row.
- Shows contributor class, current guild rank, level and class color from the already-cached guild roster.
- Limits modal shading to the addon window, or to the dialog bounds when the main window is hidden.
- Recursively raises every dialog input and button above the shade, fixing controls that looked visible but could not be clicked.
- Uses fully opaque near-black dialog surfaces and stronger hover/border feedback.

## Treasury donor achievements

- Adds one cumulative donor series at 5, 25, 50 and 100 gold.
- The achievement owner is the named contributor, never the officer who records another member's payment.
- Existing contribution ledgers migrate into bounded donor totals once without double-counting.
- Donor totals synchronize only from explicit contribution/state-sync events; no polling, roster scan or additional heartbeat is added.

## Recruitment completion

- Fixes Recent Whispers Invite so each button targets its own current row.
- Uses the guild invitation API with permission, self, invalid-name, and existing-member checks.
- Shows Invite, Sent, or Member state without background polling.

## Interface fixes

- Makes the parked OTL edge tab smaller and lower.
- Reflows the World Recruitment status card and moves Recent Whispers away from it.
- Reduces Guild Chat pin-button noise.
- Removes visible `actor unavailable` technical text.
- Preserves safe recovery with `/otl center`.

## Compatibility

- Interface: `11200`
- SavedVariables schema: `14`
- Network protocol: `3`
- Existing 1.7.x data remains compatible.
- Adds four lightweight, event-driven Treasury donor achievements; risky continuous trackers remain paused.
