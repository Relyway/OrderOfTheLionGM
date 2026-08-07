# OrderOfTheLionGM 1.8.0 — Release Notes

Version **1.8.0** is the final native-interface, stability and performance release for Order of the Lion on OctoWoW / Interface 11200.

The release keeps the full 1.8 feature set but closes the project around a strict boundary: responsive UI, consistent server-time presentation, reliable existing workflows, bounded synchronization and as little work as possible while the addon is not being used.

## Final highlights

- Native Guild/Officer shell with Normal, Compact and Fit layouts.
- Roster row pooling with a hard viewport capacity, preventing pooled rows from reappearing outside the window after resize transitions.
- Park/window coordinates based on the real visible positioning viewport rather than a double-scaled UIParent calculation.
- One keyed foreground page clock. It exists only while the addon is visible, resumes after reopen/unpark and uses a slower 30-second cadence on quiet pages.
- Activity uses ST calendar buckets and preserves real timestamps for retention/period logic. Boundary-day peak and retention math was corrected in the final audit.
- Activity composition includes class, level and faction balance with honest coverage. Alliance/Horde evidence can come from visible units, addon presence, compatible extended roster fields or an explicit structured race code already stored in the officer note. It is never guessed from name, zone or a non-exclusive class.
- Raid date and raid time use the same ST basis.
- 146 unique achievement definitions.
- Previously paused published achievements are restored through filtered, dynamic ownership rather than broad permanent listeners.
- High-frequency achievement listeners are context-owned: rabbit tracking only while needed; ambient emotes only while their secrets remain; boss target/combat tracking only inside supported instances while relevant achievements remain incomplete.
- Mailbox sender scanning is sliced to at most four headers per scheduler pass.
- Backup import/undo re-evaluates event ownership immediately, so restored incomplete achievements do not require `/reload` to become trackable again.
- Guild Leader presentation remains limited to Morrow/Lucks; guild-action authorization still follows live server permissions.

## Upgrade

Replace the addon folder with the 1.8.0 folder and keep existing `OTLGM_DB` SavedVariables. Schema 15 and protocol 3 remain unchanged.

## Verification boundary

The packaged tree is checked for Lua syntax, TOC integrity/order, conservative Vanilla/Lua compatibility hazards, achievement-catalog consistency, manifest hashes and ZIP extraction equivalence. Real OctoWoW behavior that depends on the client/server is deliberately left as **live pending**, not described as automated proof. See `LIVE_VERIFICATION_1.8.0.md`.

## Final public polish

- Roster now includes a direct **+ Invite** action: enter a character name and send the normal guild invite without opening Blizzard's guild panel.
- Guild Composition now treats faction as a real Alliance-vs-Horde balance with faction icons, counts, identified-member percentages, A:H ratio and an explicit coverage quality label. Unknown members remain only in tooltip diagnostics instead of being shown as a third faction.
- Faction detection can consume direct unit/addon evidence, compatible extended roster values, and both current two-letter and older one-letter officer-note race codes when present.
- Roster now includes a permission-aware **+ Invite** button. Enter a character name and press Enter or **Invite**; the addon uses the client's normal guild invitation API.
