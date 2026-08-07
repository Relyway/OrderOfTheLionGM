# Test Report — OrderOfTheLionGM 1.8.0

Build: `final-public-20260808`  
Interface: `11200`  
Schema: `15`  
Protocol: `3`

## Checks performed in this build environment

| Check | Result | What was actually checked |
|---|---|---|
| TOC integrity | PASS | 37 Lua paths, 37 unique; every path exists. |
| Lua parser syntax | PASS | All 37 TOC Lua files were parsed with the available Lua 5.4 parser library without syntax error. This is a syntax check, not an OctoWoW runtime execution claim. |
| Conservative Vanilla/Lua compatibility scan | PASS | No code use of Lua 5.1+/modern constructs such as `#` length operator, floor division, goto/labels, `table.unpack`, `string.gmatch`, `rawlen`, `bit32` or `math.fmod`. Apparent `//`/`~` matches were URLs, strings or comments. |
| Achievement catalogue | PASS | 146 unique definitions: A=46, B=40, C=34, D=21, E=4, plus `UNDER_BANNER`; no duplicate IDs found. |
| Final identity | PASS | TOC/core/shell agree on version `1.8.0` and build `final-public-20260808`; Interface remains 11200. |
| OnUpdate source-count regression | PASS | 13 `SetScript("OnUpdate"...)` sites, unchanged from the pre-audit2 tree; no new permanent frame loop was added. |
| Roster overflow invariant | PASS (source invariant) | Roster render capacity remains a hard row boundary; extra pooled rows are hidden and optional child clipping remains defence-in-depth. |
| Page-clock lifecycle invariant | PASS (source invariant) | Any visible page schedules the keyed page clock; main-frame hide cancels it; reopen/unpark explicitly re-arm it; quiet-page delay is 30s. |
| Activity ST migration invariant | PASS (source invariant) | New samples use ST date/hour keys; legacy conversion preserves real timestamps; period/retention decisions use latest sample / exact peak timestamp. |
| Faction observation invariant | PASS (source invariant) | Unknown remains the fallback; direct observations require an existing roster member; optional presence faction is validated; compatible extended roster strings and structured officer-note race codes are accepted; no faction polling loop was introduced. |
| Faction-source targeted test | PASS | Local harness verified Alliance/Horde from two-letter officer-note race codes, legacy one-letter codes, explicit extended-roster faction strings and extended-roster race strings. |
| Manual guild invite targeted test | PASS | Local runtime harness verified trim/submit, existing-member rejection, self-invite rejection and invocation of the normal guild invite API. |
| Faction responsive layout invariant | PASS (source invariant) | Alliance/Horde icons are repositioned from effective composition width and the two value fields are laid out beside, not over, the icons. |
| Dynamic achievement ownership invariant | PASS (source invariant) | Completion refreshes ownership; backup import/undo/rollback refresh it; trade/craft/tabard/duel/rabbit/emote/boss ownership is conditional rather than permanently broad. |
| Boss-context ownership invariant | PASS (source invariant) | Base boss target/combat listeners are enabled only in a known supported instance and only while relevant incomplete achievements require them; world-entry gets a one-shot deferred recheck. |

## Static performance observations

- The shared scheduler is keyed and is intended to detach its `OnUpdate` when no tasks remain.
- Shell interaction `OnUpdate` paths are temporary drag/resize/Park interaction handlers and explicitly clear themselves.
- Activity faction composition adds no recurring timer, roster poll or protocol family.
- Total + online composition are built together and cached.
- Mailbox sender processing remains capped at four headers per scheduler slice.
- Quiet visible pages no longer wake every five seconds solely to repaint a minute-resolution header.

## What this report does **not** claim

This environment did **not** run the final tree inside OctoWoW and did not execute a complete WoW API mock runtime. Therefore this report does not claim live proof for:

- exact pixel clipping/scale under third-party UI replacements;
- actual server chat/combat text variants for every achievement;
- guild promote/demote/mute permissions;
- real cross-client Treasury/Crafting/PvE synchronization;
- live FPS/memory behavior over a long session.

Those checks remain in `LIVE_VERIFICATION_1.8.0.md`.

## Package checks

The final package cycle was performed after the report/manifest content was frozen:

- source tree: **53 files**;
- install ZIP: CRC/integrity test PASS; exactly one top-level `OrderOfTheLionGM` folder;
- Git-ready ZIP: CRC/integrity test PASS; `OrderOfTheLionGM.toc` at archive root;
- extracted install tree vs source: **53/53 byte-identical files**;
- extracted Git-ready tree vs source: **53/53 byte-identical files**;
- build manifest: **52/52 SHA-256 entries** verified against the extracted install tree (the manifest intentionally excludes its own hash);
- extracted install TOC: **37/37 paths present and unique**;
- extracted install Lua syntax: **37/37 files parsed successfully** by the same local Lua 5.4 syntax check.
