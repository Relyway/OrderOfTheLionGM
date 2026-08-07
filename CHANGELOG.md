# Changelog

## 1.8.0 — 2026-08-08

### Final audit 2
- Fixed a subtle **foreground clock lifecycle** gap: the shared ST header now updates on every visible page, resumes after close/reopen and Park/unpark, and remains fully cancelled while the main addon window is hidden.
- Reduced quiet-page foreground work: pages that only need the `HH:MM` ST header now pulse every 30 seconds instead of every 5 seconds. Recruitment/Guild Chat and the bounded Professions/Treasury recovery checks keep their shorter dedicated cadence.
- Corrected legacy Activity conversion to **server-time calendar buckets** while preserving real absolute timestamps for retention and period math.
- Fixed Activity boundary handling: 90-day retention now uses the newest sample, period averages use the newest sample to decide overlap, and weekly/period peaks use the exact `peakAt` timestamp. A boundary day can no longer disappear almost a day early.
- Fixed raid displays that could pair a server-time clock with a local-OS date; raid date and clock now share the same ST formatter.
- Added one-pass cached total + online guild composition. Activity can show Alliance/Horde/Unknown, known coverage, A:H ratio, online population, online level-60 population, class distribution and level distribution without a new scan loop.
- Presence `V/Q` packets accept an optional validated Alliance/Horde field without a protocol bump; old clients remain compatible. Duplicate detected-version writes on those packets were removed.
- Backup import/undo/rollback now immediately recalculates dynamic achievement-event ownership after SavedVariables replacement.
- Achievement ownership now releases listeners at the exact completion point and can re-enable them after restoring incomplete progress.
- Restored ten published achievements that an older anti-stutter layer had effectively paused, while keeping mailbox work bounded to four headers per scheduler slice and money tracking self-disabling when finished.
- Rabbit combat/death parsing remains dormant unless the rabbit tracker is actually active; its target listener disappears after B085.
- Ambient text-emote parsing disappears after the coordinated roar/dance/kneel secrets are complete.
- Both duplicate tabard equipment listeners disappear after `UNDER_BANNER` is complete.
- Local trade UI listeners disappear after A027 is complete; release-layer craft confirmation listeners disappear after B079 is complete.
- The original boss-achievement frame no longer parses high-frequency target/combat-death traffic in the open world. Boss-victory traffic is enabled only inside a known supported instance while a relevant achievement remains incomplete; encounter bookkeeping is narrower still and stays on only for achievements that need death history. A one-shot post-world-entry recheck covers clients whose zone text settles late.
- Corrected achievement catalogue metadata to **146 unique definitions** and removed confusing final-facing old 1.7.6/C5 identity from module diagnostics.

### Earlier final fixes retained
- Roster pooled-row overflow after Normal/Compact/Fit transitions fixed with hard visible capacity plus optional child clipping as defence-in-depth.
- Park/window positioning corrected for real visible bounds and UI scale; screen dimensions are no longer divided by effective scale twice.
- Recruitment Compact/Fit layout and live elapsed-time label paths corrected.
- User-facing Guild Leader identity restricted to **Morrow / Lucks** while actual guild actions still depend on live server permissions.
- Same-base prerelease version ordering treats final `1.8.0` as newer than `1.8.0-rc*`, beta and alpha builds.

### Release identity
- Version: `1.8.0`
- Build: `final-public-20260808`
- Interface: `11200`
- Schema: `15`
- Protocol: `3`
- No destructive SavedVariables migration and no protocol bump.

### Final public polish
- Added a native **Invite to Guild** action to the Roster toolbar with a simple name-entry modal, Enter-to-submit, permission checks and the standard guild invitation API.
- Reworked Activity faction balance: Alliance/Horde are now presented as a two-sided balance; unidentified members no longer appear as a fake third faction in the main UI.
- Added extra reliable faction discovery from compatible extended roster fields plus current and backward-compatible officer-note race codes (Hu-/H-, NE-/N-, Ta-, Go-, etc.), while retaining direct unit/addon evidence.
- Faction percentages are explicitly based on identified members. The main card now shows a quality label (`Roster coverage`, `Partial coverage`, or `Learning factions`) instead of pretending incomplete data is complete.
- Corrected the responsive Activity layout for the new Alliance/Horde icons so Fit/Compact reflow cannot place text on top of the faction emblems.
- Kept the faction card visually neutral rather than tinting the whole panel toward either faction.

