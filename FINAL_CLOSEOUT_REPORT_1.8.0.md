# Final Closeout Report — OrderOfTheLionGM 1.8.0

Build: `final-public-20260808`

## Baseline and comparison

The final line was reconstructed from the supplied `OrderOfTheLionGM-1.8.0-rc5-r7-g.zip`. The supplied `rc5-r6-consistency-hardening` archive was used as a comparison point. R7-G was kept as the code baseline because it already contained later geometry, UI, Search/Highlights, leader-identity and consistency fixes.

## Major final fixes preserved

- Roster pooled-row overflow after Normal/Compact/Fit transitions: fixed through a hard visible-capacity boundary plus optional child clipping.
- Park/window positioning: uses a separate real positioning viewport and no longer divides screen dimensions by UI scale twice.
- Recruitment compact layout and elapsed-time update path.
- Activity faction composition: Alliance/Horde/Unknown, known coverage and A:H ratio without guessing or a polling scan.
- Final version ordering: `1.8.0` is newer than same-base RC/beta/alpha builds.
- Ten published achievements that had been left paused by an old anti-stutter layer were restored through filtered/dynamic ownership.
- Mailbox achievement processing is bounded to four headers per scheduler slice; money achievement ownership self-disables when complete.
- User-facing Guild Leader identity is canonical Morrow/Lucks while live guild actions remain permission-driven.

## Additional defects found in final audit 2

### 1. Shared ST header could freeze on quiet pages
The foreground page task had historically been armed only for pages with page-specific recovery work. Roster, Activity, History, Settings and other quiet pages could therefore show a frozen ST header while remaining open.

**Correction:** one keyed visible-page task now exists for every visible page. Hide/Park cancels it; reopen/unpark re-arms it. Quiet pages use a 30-second cadence rather than the previous unnecessary 5-second cadence.

### 2. Close/reopen and Park/unpark could lose the foreground clock
When the main frame was hidden, the page task was correctly cancelled, but reopening the already-built page did not always call the page show path that originally armed the task.

**Correction:** `ToggleUI()` reopen and `UnparkWindow176()` explicitly re-arm the current page clock.

### 3. Activity ST conversion needed stronger timestamp semantics
Legacy activity days were local-calendar buckets while the UI called the heatmap ST. A simple key shift was not enough: using a day's first timestamp for all retention/period decisions could remove a boundary day almost 24 hours early.

**Correction:**
- legacy hour buckets are re-keyed into ST calendar/hour buckets once;
- real timestamps remain absolute;
- a stored peak moves to the ST date containing its real `peakAt`;
- 90-day retention uses `lastSampleAt` where available;
- period overlap uses the newest sample;
- weekly/period peak membership uses exact `peakAt`.

### 4. Raid date and raid clock could use different time bases
Several raid surfaces formatted the clock through ST but left the date on local OS time.

**Correction:** relevant raid date labels now prefer the same canonical server-date formatter used with the ST clock.

### 5. Activity composition was doing avoidable duplicate roster work
Total composition and online composition were requested separately by the page.

**Correction:** both snapshots are generated in one roster pass and cached by roster/faction revision.

### 6. Faction presence needed compatibility and validation hardening
The guild roster tuple does not expose faction for every member, and cross-faction OctoWoW makes class/race inference unsafe.

**Correction:** faction remains evidence-only. Player/party/raid units are observed directly; compatible V/Q presence messages may carry one optional validated faction field. Target evidence is opportunistic only while an existing achievement target tracker is active. Unknown remains Unknown. No protocol bump or new network request was added.

### 7. Backup restore could leave achievement listeners in the old ownership state
A backup may restore an achievement from complete to incomplete after its listener had already been retired.

**Correction:** successful import, undo and rollback refresh dynamic achievement ownership, faction observation and scheduler state immediately.

### 8. Event ownership was released too late for some achievement paths
Some achievements could complete in older runtime layers without immediately refreshing the final dynamic ownership layer.

**Correction:** the final `CompleteAchievement174` wrapper refreshes ownership after any actual completion. Listener release therefore happens at the completion point regardless of which runtime layer awarded the achievement.

### 9. Several achievement listeners could remain alive after their work was finished
Final audit 2 additionally retires:
- A027 trade UI events after A027;
- B079 release craft-confirm events after B079;
- both tabard equipment owners after `UNDER_BANNER`;
- ambient text-emote parsing after A081/A082/A083;
- rabbit target/combat ownership when B085 no longer needs it.

All of these ownership decisions are restore-safe.

### 10. Legacy boss tracking parsed open-world target/combat traffic unnecessarily
The base achievement frame could receive `PLAYER_TARGET_CHANGED` and combat-death traffic everywhere even though `GetCurrentInstanceRule174()` would reject all open-world targets.

**Correction:**
- boss-victory combat text is owned only inside a known supported instance while a relevant boss achievement (or its post-kill dance secret) is incomplete;
- target/combat/death encounter bookkeeping is narrower and is owned only while an achievement that requires encounter death history remains incomplete;
- zone transitions re-evaluate ownership;
- a one-shot deferred recheck after `PLAYER_ENTERING_WORLD` covers Vanilla-derived clients whose zone text settles late.

This removes high-frequency gameplay parsing from the open world without adding a timer or polling loop.

### 11. Achievement catalogue metadata was inconsistent
Historical feature layers still advertised 87/121 as if they were the final catalogue size.

**Correction:** final-facing metadata now identifies 146 unique definitions while preserving historical `catalogAfterLayer` counts where useful for diagnostics.

## Performance boundary

Final audit 2 adds **no permanent `OnUpdate`**. Source audit still finds the same 13 `SetScript("OnUpdate"...)` sites as before this pass; those sites belong to the sleeping scheduler attachment/removal path and temporary drag/resize/scroll/Park interaction paths.

No schema bump, protocol bump, background faction scanner or new recurring roster scan was added.

## Verification boundary

The release tree is statically checked. The final package cycle verifies ZIP CRC, a one-folder install layout, Git-ready root layout, byte-for-byte equality after extraction, manifest hashes and syntax of the extracted TOC Lua set. Pixel geometry, actual OctoWoW event strings, server permission behavior and cross-client synchronization still require the real client/server and are listed separately in `LIVE_VERIFICATION_1.8.0.md`.


## Public release polish — 2026-08-08

- Replaced the confusing Alliance/Horde/Unknown presentation with a two-sided faction balance card. Unknown remains diagnostic coverage only.
- Added faction icons, known-member percentages, A:H ratio and coverage-quality wording.
- Added additional explicit faction sources from compatible roster return values and structured officer-note race codes, without class/name/zone guessing or polling.
- Added a native Roster **+ Invite** workflow using the normal WoW guild invite API, with rank-permission checks, empty/self/existing-member validation and Enter-to-submit.
- Corrected responsive positioning for the faction icons under Fit/Compact layouts.
- No schema or network protocol bump is required.
