# 1.8.3 — Final Release (2026-08-27)

- Promoted the runtime/TOC identity from the r59 pre-final line to plain `1.8.3` / `release-1.8.3-20260827` without changing schema 15 or protocol 3.
- Restored a useful **Share Discord** guild message (235/240 characters) covering guides, raid info, announcements, help, events, off-game contact and the first guild rank promotion, including `https://discord.gg/UNacDPrGt2`. Exact old addon-owned Discord text migrates; Leadership edits remain untouched.
- Added a strict one-time repair for the live-confirmed retained History dominated by a synthetic near-balanced mass JOIN/LEAVE burst. Ordinary history kinds are preserved and removed bursts become one reviewed BASELINE record.
- Kept the CP5 achievement idempotence/cold-baseline protections, CP7 roster-presence/cache coherence, mass roster rebaseline safeguards, quiet Support behavior, Enchanting correction and active Sunday recruitment defaults intact.
- Replaced RC-named release documents in the clean package with `RELEASE_NOTES_1.8.3.md` and `LIVE_VERIFICATION_1.8.3.md`; README is now the concise final release guide.

---

# 1.8.3-rc4-r59 — Pre-Final Correction Candidate (2026-08-26)

## 1.8.3-rc4-r59 CP7 — Live State Corrections (2026-08-26)
- Migrates the exact CP6-era addon-owned Social 1/2 strings seen in live SavedVariables to the active Sunday 20:00 ST / 2SR wording even when old builds stamped `updatedAt`; arbitrary Leadership-written copy remains untouched.
- Publishes a volatile Presence revision and invalidates only online-dependent Roster caches so Header / Online / Shown no longer display different presence snapshots.
- Uses sender-matching branded achievement guild lines as version-unknown addon-presence evidence only; no capability, trust or permissions are inferred.
- Confirms mass same-total identity/durable roster churn and safely re-baselines it as one reviewed BASELINE record instead of hundreds of unread member History rows; existing retained History is not silently deleted.
- Restores the intended automatic backup snapshot for real roster changes by calculating `changes` before deciding whether to snapshot.
- Keeps bulk-only network queue pressure as `Syncing`, reduces Adaptive Guard false activation for ordinary 8–12 ms samples at healthy FPS, adds aggregate History/presence diagnostics, and clarifies withdrawn-report status.
- Schema/protocol remain 15/3; CP5 achievement runtime files are unchanged.

## 1.8.3-rc4-r59 CP5 — Achievement Regression Hardening (2026-08-26)
- Preserves `releaseBaselineR6` and the small threshold-baseline marker when cold no-guild achievement storage merges into the real guild SavedVariables store.
- Makes tabard, money and profession-cap current-state discovery intrinsically silent until that character's first durable baseline, preventing fresh-login retrospective state from looking newly earned.
- Keeps `db.completed[id]` as the hard idempotence gate and records blocked duplicate completion attempts only for diagnostics.
- Refuses stale guild-achievement queue entries if restore/undo/repair has removed the corresponding authoritative completion.
- Adds `R59 achievement regression` evidence to Full Support Report for Under the Banner / First Fortune / Master of the Trade acceptance.
- Adds no schema/protocol bump, polling loop or new network stream.

## 1.8.3-rc4-r59 CP4 — Live Corrections (2026-08-26)
- Corrected Home Main Raid Leader inference: rank index alone no longer assigns the raid-leader card.
- Calibrated Support so bulk-only sync and one-off moderate timing samples do not look like failures.
- Removed false Enchanting WAIT from non-Enchanting profession probes.
- Added precise Presence escalation and network priority diagnostics.
- Updated Social 1/2 recruitment copy for active Sunday 20:00 ST raids, 2SR > MS > OS, and `Former Lion's Pride`.


- CP3 correctness hardening wires the History unread repair into the actual canonical `Database.lua` guild-DB access path and backup restore/undo, preventing old `1094 unread / 500 retained` style drift from surviving an in-place upgrade.
- CP3 preserves a valid Enchanting rank across transient CraftFrame `0/max` states, keeps first-occurrence evidence for repeated Support incidents, prevents amber issues from hiding an unacknowledged red hard error, and bounds the runtime signature tracker.
- Recruitment status wording now follows the actual preserved min/recommended settings while the normal r59 default remains 8–10 minutes with 10m+ green-ready.
- CP2 roster hardening: Presence refresh now stages online/zone/index data and publishes it atomically only after every roster row validates; rank/note/member/count changes discard the staged pass and fail closed into the authoritative full scan. Coalesced roster events discard/restart rather than briefly publishing stale presence.
- CP2 diagnostics expose Presence restarts and the last escalation reason in Full Support Report for live verification.
- Fixed Vanilla Enchanting skill-line tuple handling so a real rank is no longer stored/displayed as `0/300` while recipe/effect capture remains intact.
- Repaired bounded History unread accounting and added one-time r59 recount of the actual retained log, preserving schema-15 SavedVariables.
- Added a lightweight, pressure-bounded Roster Presence lane for ordinary online/offline freshness; structural membership/rank/level/note differences fail closed into the existing authoritative full scan.
- Recruitment timing now treats 8–10 minutes as the safe sending window and 10m+ as the preferred green-ready point; exact old 10/15 defaults migrate while custom intervals are preserved.
- Added one canonical **Support & Report** flow with incident-time snapshot + Full Support Report. It never auto-opens or auto-sends; transient FPS/ping/network/one-off slow operations remain silent, repeated same-signature internal issues are deduplicated, and hard page failures can surface once through Action Center.
- Fresh installs keep the main window inside the screen by default; existing explicit settings are preserved.
- Normal compatibility labels now say `current`, `older build` or `newer build` instead of exposing internal rXX checkpoint identifiers; exact runtime/build remains in About/Support.
- Refreshed the final release gate and r59 live-verification/recovery documentation. Schema/protocol remain 15/3 and the build is still not plain `1.8.3`.

# 1.8.3-rc4-r58 — Final Live Handoff Candidate (2026-08-26)

- Added a session-only **X / dismiss** action to Recruitment → Recent Contacts so unrelated whispers can be removed immediately.
- Dismissed names stay suppressed for the remainder of the existing two-hour recruitment-contact window and are never written to SavedVariables.
- Preserved r57 achievement cold-open deep-link focus, r56 four-step Social 1 → Raid 1 → Social 2 → Raid 2 recruitment queue, r54 mention deep-link hardening, and all r42–r56 performance/correctness work.
- Re-ran the complete achievement catalogue audit after all extension modules: **147 total, 147 unique IDs, 147 unique names, 0 broken achievement links**.
- Re-ran static performance-owner audit: **13 OnUpdate script sites / 31 RegisterEvent sites / 211 CreateFrame sites**, unchanged from r57.
- No schema or protocol change: **15 / 3**.
- r58 is intended as the full handoff/live-test candidate before plain **1.8.3 Final**; final release identity remains gated by the OctoWoW live matrix.

## 1.8.3-rc4-r57 Achievement Deep-Link Focus — 2026-08-25

- Achievement chat hyperlinks now use a two-phase cold-open focus: immediate selection plus one one-shot post-layout confirmation.
- Fixes the case where the first click opened Achievements and selected the target in blue but left the list at the previous/top offset until a second click.
- Manual achievement interaction cancels any pending link confirmation, preventing delayed snap-back.
- No new permanent OnUpdate, polling, network traffic, schema or protocol changes.

## 1.8.3-rc4-r56 Dual Raid Recruitment Queue — 2026-08-25

- Recruitment queue is now exactly `Recruit 1 -> Raid 1 -> Recruit 2 -> Raid 2 -> repeat`.
- The two existing social World messages are preserved.
- Raid 1: Sunday 20:00 ST, 2SR > MS > OS, Rogue/Mage plus 1-2 healer priority with Hpala/Rdruid called out.
- Raid 2: a distinct roster-filling line with healer priority and room for Rogue/Mage.
- Raid recruitment contains no Discord link and avoids redundant level/endgame wording.
- r55 `RAID` selection migrates safely to `RAID1`; the four-step queue index keeps its position across upgrade.
- Recruitment layouts now account for six fixed presets without adding background work.

## 1.8.3-rc4-r55 Alternating Recruitment Queue — 2026-08-25

- `Send Next` now alternates the two existing social recruitment messages with raid recruitment: Recruit 1 -> Raid -> Recruit 2 -> Raid.
- Preserves Leadership-edited Recruit 1/2 text and migrates the old two-step queue without losing which social message was next.
- Raid recruitment was rewritten around useful raid facts only: Sunday 20:00 ST, steady roster, 2SR > MS > OS, Discord sign-ups/info.
- Quick Dock and Recruitment page now show the same four-step queue state.
- No new polling, scheduler task, frame owner or network protocol was added.

## 1.8.3-rc4-r54 Chat Deep-Link & Raid Recruitment — 2026-08-25

- Fixes a lazy Guild Chat deep-link race where opening a mention notification could lay out `chatChannelButtons` before the chat page had been built.
- Expired mention notifications now open Guild Chat safely and report that the original message is no longer in local history; retained mentions still focus/highlight their message.
- Adds a defensive Guild Chat geometry readiness guard so pre-build refreshes cannot reproduce the nil-button error through another route.
- Restores the two established general World recruitment messages and keeps `Send Next` limited to those two messages.
- Adds a separate concise `Raid Recruitment` World preset for level-60/endgame-oriented recruiting without changing the normal rotation.
- Preserves Leadership-edited recruitment text; only untouched r53 defaults are migrated back to the established two-message rotation.
- Keeps short `[Lion Addon] <player> earned [achievement]` announcements and the real `otlgmachievement` hyperlink path introduced in r53.

## 1.8.3-rc4-r53 Communication & Content Integrity — 2026-08-25

- Shortens guild achievement announcements to `[Lion Addon] <player> earned <achievement>` and sends the achievement title as a real OrderOfTheLionGM hyperlink.
- Keeps legacy achievement-announcement tags readable/clickable in the addon Guild Chat fallback.
- Replaces the old second general World message with a concise raid recruitment message for Sundays 20:00 ST; untouched historical defaults migrate safely, custom leadership edits are preserved.
- Shortens the protected Guild Info and Share Addon messages while making the addon branding explicit.
- Updates current Guild Info rank presentation from Lionheart/Lucky Luck to Raid Leader/Guild Leader, keeps historical aliases only for compatibility, and uses exact normalized rank matching.
- Removes the named `Rangark` Raid Leader fallback from Home; the card now follows the actual Raid Leader role.
- Refreshes onboarding and Guild Info getting-started/contact wording without adding background work, polling or protocol changes.

## 1.8.3-rc4-r52 Final Live Candidate Audit — 2026-08-24

- Runs the broad pre-live static/deterministic audit across TOC load order, all native pages, network/security, backup integrity, version trust, achievements, Main/Alt, Profile Identity, professions lifecycle, Treasury and Support.
- Removes a redundant deep schema-15 guild-foundation repair from the current-schema database cache-miss path while keeping one canonical repair pass.
- Finishes Treasury Server Time consistency across the main page, contribution dialog and legacy history presentation.
- Replaces remaining user-facing raid `revision` wording with `version`.
- Refreshes README/release-gate metadata and records explicit live-only acceptance boundaries.
- Schema 15 / protocol 3 and permanent owner counts remain unchanged.

## 1.8.3-rc4-r51 Cross-Addon UX / Correctness Checkpoint — 2026-08-24

- Adds cached Search category buckets/counts and human-readable result labels.
- Replaces raw PvE internal state labels and remaining technical compatibility wording in ordinary UI.
- Standardizes inactive-crafter wording and fixes Recruitment's last World-post clock to Server Time.
- Keeps the existing feature/protocol behavior and background-owner counts unchanged.

## 1.8.3-rc4-r50 Treasury / Support Finishing Checkpoint — 2026-08-24

- Improves Treasury contributor/history readability and adds revision-keyed derived-ledger reuse.
- Adds a compact user-facing Support health summary while retaining full engineering diagnostics below it.
- Keeps detailed network/performance state out of ordinary UI unless the user opens Full Report.
- Adds no polling, packet stream, SavedVariables branch or schema/protocol change.

## 1.8.3-rc4-r49 Guild Journey / Achievement Presentation Checkpoint — 2026-08-24

- Adds derived Guild Journey milestones from existing roster and verified achievement data without a new tracker or background sync.
- Keeps overall X/147 achievement progress and adds exact per-category progress only when a verified completion map exists.
- Keeps recent return context visible for a limited period using already tracked RETURN metadata.
- Gives completed Secret achievements and Secret Profile Showcase badges restrained special presentation.
- Reuses one exact achievement-detail snapshot during profile refresh; no schema/protocol, polling, event-owner or packet-stream change.
- Fixes TOC X-Build identity consistency.

## 1.8.3-rc4-r48 Profile Identity Checkpoint — 2026-08-24

- Adds up to three completed achievements to a compact Profile Showcase while preserving the overall completion count.
- Adds curated earned profile titles backed by existing achievement completion.
- Adds restrained automatic Leadership/Guild Leader prestige while keeping class colour readable.
- Reuses the existing ABOUT profile-content path; no new background packet stream, polling, schema or protocol bump.

## 1.8.3-rc4-r47 Version Awareness / Compatibility UX Checkpoint — 2026-08-24

- Adds trusted update detection using existing presence/version evidence only: a fresh Guild Leader confirmation or matching reports from multiple guild clients.
- Prevents one random/test peer version from creating a guild-wide Update Available warning.
- Persists a confirmed newer version locally until the installed client catches up.
- Reworks Update Available into a quiet gold action that opens Settings → About instead of a danger-style warning.
- Adds one deduplicated Action Center update action; superseded/installed update entries become stale automatically.
- Adds a one-time, non-modal What's New hint after an upgrade plus an always-available What's New button in Settings → About.
- Adds clear About/Support version status and trusted-evidence wording to Sharing Status.
- Simplifies peer feature-compatibility messages in Profiles/Achievements; exact minimum versions remain available in Full Support Report.
- Adds R47 version-awareness diagnostics without new version packets, polling, events, OnUpdate owners or schema/protocol changes.

## 1.8.3-rc4-r46 Data Maintenance / Performance Checkpoint — 2026-08-24

- Added soft crafter availability lifecycle: online/recent crafters stay primary; long-offline guild crafters remain stored but are dimmed and sorted lower.
- Added stable roster-activity token and per-crafter activity snapshot reuse for profession results.
- Separated heavy recipe revision from general crafting/request revision so commissions do not rebuild the recipe aggregate.
- Cached heavyweight crafting summary counts while keeping request/unread counters live.
- Fixed silent departed-crafter maintenance invalidation so removed owners cannot survive in aggregate/search caches.
- No schema/protocol bump, no hard age purge, no new polling/OnUpdate.

## 1.8.3-rc4-r45 Profile Achievement / Profession UX Checkpoint — 2026-08-23

- Profile -> Professions now clears stale profession/search/category/level/rarity/online/favorites filters so the first member-scoped view represents all known shareable recipes for that character.
- Added mouse-wheel scrolling to the foreign/member achievement browser.
- Completed achievement rows are active; exact missing rows are dimmed/grey; unknown old-client state remains Not verified.
- Local stored characters expose exact completion dates; r45 peers can exchange completion timestamps in bounded on-demand ACHTS chunks without passive history broadcast.
- Main/Alt direct profile rows color linked character names by class.
- Retains r44 targeted-message fast-path and r43 Enchanting hardening; schema 15 / protocol 3 and permanent owner counts remain unchanged.

## 1.8.3-rc4-r44 City Stutter / Network Fast Path Checkpoint — 2026-08-23

- Fast-discards unrelated addon prefixes, foreign targeted envelopes and self echo before full OTLGM dispatch/scheduler recompute.
- Saturates packet diagnostics at the existing display cap instead of repeated append/prune allocation churn.
- Removes per-packet anonymous callback allocation in the legitimate CHAT_MSG_ADDON path.
- Preserves r43 Enchanting capture and adds recipe-name fallback hardening.
- Schema 15 / protocol 3 and permanent owner counts unchanged; live acceptance remained pending.

## 1.8.3-rc4-r43 Enchanting CraftFrame Hardening Checkpoint — 2026-08-23

- Fixed a self-disabling Professions Enchanting probe: the user-facing `Exact effect pending...` placeholder was incorrectly treated as if a real effect had already been captured. The page probe now skips only genuinely trusted native effect data.
- Added a bounded Vanilla `CraftFrame` Enchanting capture path for `CRAFT_SHOW`, `CRAFT_UPDATE` and craft selection changes; no permanent polling or new OnUpdate owner was added.
- Added direct native description capture through `GetCraftDescription(index)` when CraftFrame Enchanting is active, with `GetTradeSkillDescription(index)` as an optional TradeSkill-side native source when a custom client exposes it.
- Preserved the existing hidden native tooltip scanner as fallback when the description API is unavailable or empty.
- Professions page probe now resolves the selected enchant against either CraftFrame or TradeSkillFrame and keeps the correct native mode through fallback capture.
- Added r43 Support/Full Report counters for CraftFrame events, API availability and native-description attempts/captures/misses.
- Preserved previous native detail lines when a direct description is captured; no synthetic recipe-name fallback is promoted to trusted native data.
- Runtime identity is `1.8.3-rc4-r43 / rc4-r43-enchanting-craftframe-hardening-20260823`; schema 15 and protocol 3 remain unchanged.
- Static source-owner counts remain 13 OnUpdate / 31 RegisterEvent / 210 CreateFrame.

## 1.8.3-rc4-r42 Live Profile & Performance Checkpoint — 2026-08-23

- Fixed repeated `Settings.lua:618 bad argument #2 to tonumber (base out of range)` errors by capturing only the first return value of `GetNetworkQueueDepth()`.
- Hardened targeted Crafting transfers: one-recipe PREPARE slices, early oversized abort, no whole-profession encoded-wire cache, and no forced 20 ms re-wake after each PREPARE step.
- Reduced `roster-post-commit-small` work by building one unread Action Center snapshot per navigation refresh instead of rebuilding it for every page badge.
- Added a full foreign achievement browser with search and Completed / Not Completed filters. Exact per-achievement status is sender-bound and requested only from r42+ peers; same-account stored characters can be verified locally.
- Foreign Professions opens the real Professions page filtered to recipes shared by that member.
- Guild Profile shows linked alts directly for Main characters and lets each visible related character open its own profile.
- Enchanting selection/tooltip capture no longer requires the stock Blizzard TradeSkillFrame to be visible on custom 1.12 UI replacements.
- r41 achievement definitions/runtime are retained unchanged; schema 15 / protocol 3 / permanent owner counts unchanged.

## 1.8.3-rc4-r40 Dungeon Achievement Detection Checkpoint — 2026-08-23

## 1.8.3-rc4-r41 — Achievement Integrity Checkpoint
- Full 147-definition catalogue/runtime-path audit.
- Fixed stranded C-series Group Finder/resurrection thresholds and direct set-count cache invalidation.
- Added local D001 level transition and Vanilla incoming resurrection evidence for B069.
- Corrected Need/Greed/pass/winner ownership to CHAT_MSG_LOOT and made Diplomatic Incident UNIT_HEALTH ownership contextual.
- Enforced strict Lucks-only published conditions, added exact Survival recognition, Proud Lion text-emote evidence and accurate Full Connection progress.
- Extended bounded current Octo/Turtle custom encounter coverage while retaining r40 dungeon-death parsing diagnostics.

- Fixed The Black Morass missing from the dungeon boss catalogue, which made its boss kills incapable of incrementing dungeon achievement progress.
- Fixed the hostile-death format parser searching for literal `%%s` instead of Vanilla `%s`, which could silently suppress catalogued boss deaths.
- Hardened instance-name resolution across RealZone/Zone/SubZone/Minimap labels for custom 1.12 cores.
- Hardened hostile-death parsing with bounded known-boss fallbacks; generic elite/trash units are never accepted as bosses.
- Expanded Stratholme boss recognition while retaining legacy final-boss aliases.
- Added runtime-only `R40 boss tracking` Support diagnostics and an applicable listener Self Check.
- Dungeon requirement remains 3+ guild members; no addon/officer requirement was added.
- Schema 15 / protocol 3 / source-owner counts unchanged.

## 1.8.3-rc4-r39 Interface Finishing Checkpoint — 2026-08-23

- Replaced user-facing sync/network/editor implementation language with clearer Sharing / Check Updates / Message Editor wording.
- Sidebar now presents a compact sharing state and a quieter manual roster refresh action.
- Roster saved views are presented as Quick Favorites with descriptive filter/search summaries and Save/Replace actions.
- Recruitment keeps the existing safe two-message self-echo rotation but presents it as World Message 1 / 2 and Send Next; saved-message actions now use normal Save/Delete visual semantics.
- PvE Hub, Guild Board, Professions and Treasury use consistent update language instead of visible Sync buttons.
- Settings presents Shared Data / Connection language; developer-only polling/OnUpdate wording was removed from normal Support copy.
- Weekly summary actions use consistent user-facing names while preserving the same copy/export behavior.
- No protocol, schema, Transport/Security, Guild Admin, achievement, crafting/enchanting or Main/Alt logic changes.

## 1.8.3-rc4-r38 Guild Admin UX Polish Checkpoint — 2026-08-22

- Polished Officer > Guild Admin without changing the r37 server-backed guild-control contract.
- Added Saved / Unsaved / Read-only states and Revert for MOTD and Guild Information.
- Save buttons now activate only for real changes; ordinary refreshes preserve unsaved text.
- Grouped the 12 rank permissions into clear Chat, Member Actions, and Guild Settings / Notes sections.
- Added rank draft dirty-state, Revert, and discard confirmation when switching/adding ranks.
- Simplified Members into Invite + Roster Management + Your Live Access; Classic Guild remains a compatibility fallback.
- Kept OnUpdate/RegisterEvent/CreateFrame source-owner counts unchanged.

## 1.8.3-rc4-r37 Guild Administration Checkpoint — 2026-08-22

- Added `Officer Tools > Guild Admin` so the Social > Guild redirect no longer hides routine native guild management.
- `Guild Text` edits the real Guild MOTD (128 chars) and long Guild Information (500 chars) with live permission gating.
- `Ranks & Permissions` exposes the live hierarchy, rank name and all 12 Vanilla guild rank flags in clearer Chat / Member Actions / Guild Settings groups. Changes stay in a local draft until `Save Rank Changes`.
- Guild Leader can add a bottom rank up to the Vanilla 10-rank limit and delete only an empty lowest rank while at least five ranks remain; deletion requires confirmation.
- `Members` supports invite-by-name and routes selected-member promote/demote/remove/public/officer-note work to the existing Roster rather than duplicating destructive controls.
- Added an explicit `Classic Guild Window` one-shot fallback that bypasses the configured Social > Guild redirect only for that request, preserving access to rare server-specific native actions.
- Responsive minimum-width layout; no new OnUpdate/RegisterEvent/direct CreateFrame owner, network traffic, schema bump or protocol bump.

## 1.8.3-rc4-r36 Main / Alt UX Polish Checkpoint — 2026-08-22

- Reworked the single lazy Main/Alt modal into context-sensitive layouts for unlinked self, Main, Alt and foreign-member browsing instead of showing irrelevant disabled controls.
- Confirmed links now expose `Open Main / Open Alt` next to `Unlink`; pending incoming links remain `Confirm / Decline`.
- Foreign related-character browsing is shorter and uses `Set as My Main`; the player menu now says `Main / Alt` and the Roster filter says `Main / Alts`.
- Simplified everyday Main/Alt wording and shortened Guild Profile state lines so compatibility/debug terminology stays out of normal UI and text is less likely to wrap under buttons.
- Kept one modal rather than adding another window. Identity storage/wire format, schema 15, protocol 3, Recruitment A/B and Guild Chat row geometry are unchanged.

## 1.8.3-rc4-r35 Main / Alt UX Checkpoint — 2026-08-22

- Made Main/Alt identity discoverable from Home, Guild Profile, Roster and the common player context menu.
- Character Identity now doubles as a read-only related-character browser for other guild members.
- Added `Request as My Main` from another eligible member's Characters view so users do not need to retype the name.
- Added Home pending-confirmation count, `Review N` in the self Characters card, and confirmation dialogs for confirmed Unlink / incoming Decline.
- Roster gains compact M/A context and an explicit `Linked characters` filter; the full-roster identity check only runs while that filter is selected.
- Identity storage, wire format, schema 15, protocol 3 and r34 compatibility are unchanged. Guild Chat geometry and Recruitment A/B are unchanged.

## 1.8.3-rc4-r34 Main / Alt Identity Checkpoint — 2026-08-22

- Added voluntary Main/Alt linking in Guild Profile: Alt requests, Main confirms/declines, either side can cancel/unlink.
- Foreign clients require reciprocal r34+ profile claims from both real character senders before a relationship is labelled verified; pending requests are never published.
- Added protection against self-links, multiple mains, Main/Alt role chains, stale unlink/reject/ack ordering and more than six active/pending Alts per Main.
- If a counterpart leaves the current guild, the owner's local relationship is retained but shared identity degrades to neutral/unverified until the guild context is valid again.
- Confirmed identity uses an optional backward-compatible tail on the existing `F1^PROFILE`; targeted PROFILE drops only the optional identity tail if envelope budget is unusually small.
- Added strict central Security validation for r34 identity control kinds and the optional PROFILE identity tail.
- Added Main/Alt context to Guild Profile plus Roster/Guild Chat tooltips without changing Guild Chat row geometry.
- Schema remains 15 and protocol remains 3. No new OnUpdate/RegisterEvent owner or periodic sync loop; one lazy manager frame site raises the static CreateFrame owner count from 209 to 210.
- Recruitment A/B messages and rotation remain unchanged.

## 1.8.3-rc4-r33 Support Guidance Checkpoint — 2026-08-22

- Settings > Support now exposes **Run Self Check** as an explicit bounded action instead of hiding self-check behind Full Report generation.
- Added a lightweight **Current Status & Compatibility** summary for Enchanting exact-effect evidence, own-report external ACK state, current network/performance evidence and the latest self-check result.
- Current Status is computed only while Support refreshes; no polling, event owner, permanent OnUpdate or protocol traffic was added.
- Centralized the existing Professions, Achievements, Recruitment and Officer Cases `?` help copy in one UI registry so future workflow changes cannot silently leave contradictory help text.
- Corrected current README achievement metadata from 142 to the audited 147 definitions.
- No SavedVariables schema or network protocol bump. Recruitment A/B content/rotation and Main/Alt identity remain deliberately unchanged.

## 1.8.3-rc4-r32 UX & Compatibility Checkpoint — 2026-08-22

- Other-player profile shortcuts now stay inside that member profile and jump to their shared Achievements/Professions sections instead of opening the local player pages.
- Added lightweight contextual `?` help to Professions, Achievements, Recruitment and Officer Cases.
- Added a feature capability registry with explicit detected-version/minimum-version messages for peer-dependent features.
- Tracked incomplete achievements are pinned above ordinary results and visibly marked `MY GOAL` in the list.
- Added a one-click `Welcome!` guild-chat button to full Recruitment and the Quick Dock recruitment popover; it does not touch A/B rotation or cooldowns.
- Centralized technical copy actions under a red Settings > Support tab with Quick Report and Full Report; old diagnostic-copy buttons now open the central Support page.
- Full Support Report now appends the registered feature compatibility contract; technical reports intentionally exclude private report text/officer notes.
- Re-audited the complete 147-achievement catalog: unique IDs/names, categories, required/progress/icon structure, direct completion references and tracker evidence pass static audit. Live event behavior still requires representative Octo smoke tests.
- No SavedVariables schema or network protocol bump.

## 1.8.3-rc4-r31 Hotpath Hardening Checkpoint — 2026-08-22

- Bounded crafting outbound work to one small prepare/send unit per scheduler pass and reuse the already encoded recipe wire instead of serializing it twice.
- Reused stable item/reagent metadata during unchanged profession scans and added a structural scan signature so unchanged windows can reuse the canonical profession hash.
- Removed stock `TradeSkillFrame:IsShown()` as an Enchanting capture prerequisite; native TradeSkill APIs are now authoritative on custom OctoWoW UI paths.
- Replaced double/expensive achievement sorting with one progress evaluation per catalog entry and O(1) sort metadata.
- Added a conservative Activity repaint revision gate for duplicate refreshes with unchanged data.
- Migrated legacy/invalid `craftingLevelFilter153=UNKNOWN` to `ANY`.
- Added r31 diagnostics for outbound work, scan metadata/hash reuse, achievement evaluations and Activity repaint skips.

## 1.8.3-rc4-r30 Live Correction Checkpoint — 2026-08-22

- Reports: Officer/Leadership authors no longer self-acknowledge their own report. Delivery is confirmed only by another validated Leadership client.
- My Reports: added safe Edit (before active review) and Withdraw workflows; withdrawal is an auditable terminal state instead of destructive deletion.
- Officer Cases: self-authored reports are not presented to the author as cases to investigate; withdrawn cases are read-only; long unbroken report text is wrapped safely.
- Professions: recipe aggregation moved to a revisioned, bounded scheduler-built index instead of rebuilding the complete shared recipe graph during each visible refresh.
- Roster backup: snapshot rows use a scalar whitelist-style copy in much smaller slices and unchanged scans skip redundant backup creation.
- Enchanting: Professions now has a deterministic one-shot native recipe probe when an Enchanting recipe has no effect text, independent of Octo firing the expected Blizzard selection hook.
- Diagnostics: support reports include r30 Enchant runtime path counters, aggregate-index state, skipped unchanged roster snapshots and recent slow operations. Self-check now warns on a >50 ms rolling performance spike.

## 1.8.3-rc4-r29 Visual Consistency Checkpoint — 2026-08-22

- Reduced ordinary card-title brightness and header-rule contrast so page titles remain the strongest hierarchy level.
- Settings uses quieter inactive tabs while preserving the existing selected/hover semantics.
- Standard empty states now share one muted card treatment with a small gold divider and calmer explanatory text.
- Live Performance State is formatted as CLIENT / SCHEDULER / ROSTER / NETWORK lines for faster scanning without changing diagnostics.
- Guild Chat service chrome was softened slightly: the channel accent is thinner/less bright and timestamps are quieter; message content and runtime geometry are unchanged.
- No schema, protocol, gameplay logic, achievement rules, crafting behavior, synchronization behavior or background scheduling changes.

## 1.8.3-rc4-r28 UI Consistency & Final-Gate Checkpoint — 2026-08-22

### Guild Chat final geometry
- The physical chat history viewport now has one canonical 30px header inset plus a 3px bottom inset; visible-window calculations use the same geometry.
- Newest on a longer history bottom-aligns the selected whole-row window by consuming pagination remainder above the first row, eliminating the live empty strip below the last message without partially clipping another message.
- Short histories stay top-aligned. Any nonzero scroll offset keeps the top anchor, so incoming/refresh work does not force a scrolled-up reader to the bottom.
- `/otl chatdiag dump` reports the final bottom slack, whether newest anchoring is active, and the canonical inset.

### Officer Cases / Home actions
- Officer Cases selection is now constrained to the active Open/Assigned/Waiting/Resolved/Closed/All filter. If a filter has zero cases, the old case is cleared and the detail pane shows an explicit empty state.
- Submitted case text is labelled `Report text:` instead of appearing as an unexplained raw/numeric line.
- Home `For You` keeps different report IDs as separate actions, but displays safe case type/category/target/time metadata when available so simultaneous private reports are visually distinguishable.

### Release gate
- r26 performance/network and r27 crafting/achievement paths are preserved without a schema/protocol bump or new permanent background owner.
- The build remains RC until the complete OctoWoW live matrix passes; it is not renamed to final 1.8.3 by static checks alone.

## 1.8.3-rc4-r27 Crafting & Achievement Correctness Checkpoint — 2026-08-22

### Enchanting native effect capture
- Exact Enchanting capture is now triggered from the existing `TRADE_SKILL_SHOW` / `TRADE_SKILL_UPDATE` flow and from actual TradeSkill selection/update paths instead of depending on one stock selection function.
- Each selected enchant gets at most three keyed attempts. The first path uses the real `GameTooltip:SetTradeSkillItem`; if Octo leaves that path empty, r27 runs the existing hidden native scanner against that exact selected recipe. No polling or permanent `OnUpdate` was added.
- Early exits now have explicit diagnostics (`frame-hidden`, `profession-empty`, `not-enchanting`, `no-selection`, `recipe-unresolved`, `api-missing`, `probe-miss`, `hidden-no-effect`) so a live failure can no longer remain an opaque 0/0 counter.
- Successful hidden fallback captures are rehashed and shared through the existing trailing-edge crafting commit path. Synthetic name-derived enchant text remains forbidden as verified native data.

### Personal-only craft results
- Native result tooltips classify actual crafted outputs marked Bind on Pickup as `personalOnlyR27`. Enchant services with no crafted output item are not classified this way.
- Personal-only recipes stay in the local character snapshot for knowledge/debugging but are excluded from guild recipe hashes, manifests, full transfers, profession completeness, search results, shared recipe totals, request identity, crafter matching and recipe-count achievements.
- Existing cached classification survives a profession rescan; a new classification dirties the existing crafting hash/share/search pipeline so peers converge without a schema or protocol bump.
- Survival now uses a guaranteed classic hunter icon instead of the missing texture seen in live r25.

### Crafting request achievement
- Added `A041 First Commission`: complete the first claimed guild crafting request as its crafter.
- Progress is recorded only on a real non-COMPLETED -> COMPLETED reconciliation transition, only for the winning claimed crafter, and once per bounded request-id set. Login/reload of an already completed request cannot award it again.

### Shared achievement profiles / PvE UX
- Opening a profile with missing achievement data can request a fresh summary directly from an r27+ compatible peer by one cooldown-bounded `F1 REQ` whisper. Security accepts only the short shaped WHISPER request; older clients are never sent the new request kind.
- Compatible older profile-sharing clients remain readable through passive presence sharing; the profile distinguishes update-required, passive-waiting and r27 targeted-waiting states instead of pretending missing data exists.
- Expected PvE refresh timeouts with no compatible responder are now neutral/cached-data states rather than a red `ERROR`.

### Compatibility / load
- r26 performance/network hardening is preserved. No new permanent `OnUpdate`, no new event subscription, no SavedVariables schema change and no network protocol-version change.

## 1.8.3-rc4-r26 Performance & Shared-Data Transport Checkpoint — 2026-08-22

### Measured UI / activity work
- Settings refresh now repaints only the currently visible settings tab. Hidden Network diagnostics and Backup size estimation are no longer rebuilt while the player is viewing Performance or another unrelated tab.
- Network summary and backup estimate have short foreground-only caches; explicit tab refreshes can still force a rebuild.
- Shell layout skips repeat `show/chrome` geometry when the content-host size/revision is unchanged.
- Activity shared-bucket medians are cached per changed bucket, and Activity summary/heatmap results are cached against roster/shared revisions and bounded time epochs instead of repeatedly sorting the same samples.
- Performance labels identify the actual visible page/tab (`visible-page refresh:settings-performance`, etc.) instead of aggregating every refresh under one ambiguous name.

### Roster / inbound validation
- The normalized guild-member lookup is constructed inside the existing sliced roster reader and published atomically with the committed roster snapshot.
- Normal addon-message receive paths no longer rebuild an 800+ member sender allow-list synchronously; rare explicit fallback rebuilds are separately counted and timed.
- The old `sender validation` timing label was corrected to `addon-message dispatch` because it enclosed the entire protocol handler, not only validation.

### Shared-data transport
- Crafting full-recovery no longer asks four peers at once. It contacts one compatible peer, uses a small controlled fallback only when that peer does not answer, and rotates peers across later recovery attempts.
- Crafting manifests/full targeted snapshots advertise authoritative local-owner characters/alts only; cached remote professions remain available locally but are not recursively re-broadcast as ownership.
- Repeated passive Crafting recovery is coarser (300s gate; 600s visible-page pulse), while live compact change manifests and manual Refresh remain available.
- Crafting compatibility work is split into independently measured/preemptible outbound, icon-hydration, deferred-scan, sync-control, base-timer and detail stages. Outbound transfers produce at most one chunk per scheduler pass.
- Late CMAN/CMEND packets from an already expired recovery window are treated as stale transport and ignored instead of becoming security/backoff incidents; unsolicited full RC3 snapshots remain blocked.
- Official Guild Post recovery now targets one compatible Leadership peer by whisper instead of broadcasting a SYNC that could make multiple leaders send the same META/BODY set. Repeated full responses to one requester are coalesced for 180s.
- No SavedVariables schema or protocol-version change. No new permanent `OnUpdate`, event listener or polling loop.

## 1.8.3-rc4-r25 Consolidated Pre-Live Candidate — 2026-08-22

### UI workflow polish
- Recruitment keeps the accepted responsive two-column upper area and turns the lower half into one bounded **Recruitment Composer** with Working Copy, character count, custom-slot controls, destination and send/open actions in one visual hierarchy.
- Guild Profile docking is deterministic: remembered right/left external dock when it fits, alternate side when needed, inside-edge fallback when neither side fits, drag-detach plus an explicit snap zone, and recalculation after main-window move/resize/UI-scale changes.
- Treasury Top Contributors expands to Top 5 with enough vertical space and Top 3 in compact space; amounts remain right-aligned, goal/progress stays separated from donor rows, and Recent Changes is visually separated from the editor. Existing revision/stale-write protection and `<1% funded` semantics are unchanged.
- Quick Dock can appear immediately after login when enabled without constructing the full shell. All full-page actions now lazily build the shell on first use; the login path has at most one keyed retry and no polling.

### Officer Cases / Reports
- Added a dedicated Leadership **Officer Cases** page with Open, Assigned, Waiting, Resolved, Closed and All views, responsive queue/detail composition and narrow-mode drawer fallback.
- Added selected-case assignment/takeover, compact working statuses, resolution presets, player-facing response, private comment, a separate danger-styled Issue Warning action, full copyable case history and structured troubleshooting details.
- Troubleshooting attachments can include version/build, zone/subzone/instance, FPS/latency, page, roster freshness, network queue, scheduler pressure, crafting/search/enchant metrics, latest slow operation and safe internal error source without report/chat/note leakage.
- The existing moderation privacy, canonical reconciliation, warning and case-storage backend remains authoritative; no new broadcast path or protocol version was introduced.

### Performance / release gate
- Added opt-in `/otl perftrace on|dump|off`. It records only measured operations crossing a 10 ms threshold into a 40-entry in-memory ring buffer with trigger, count context, C/N/B queue, scheduler task and current page. It is disabled by default and adds no event frame, timer or OnUpdate.
- Existing zone-transition coalescing, phased scheduler work, incremental bag scans and hidden-page refresh protection remain intact; no speculative global frequency reduction was added.
- Permanent-owner comparison against r24 remains unchanged: `OnUpdate 13→13`, `RegisterEvent 31→31`, `CreateFrame 209→209`. Schema remains 15 and protocol remains 3.
- r22 Achievement Integrity, r23 Guild Chat Runtime Geometry and r24 Enchanting Native Capture changes are consolidated unchanged into this pre-live candidate.

### Release status
- This is deliberately an RC/pre-live candidate. The final `1.8.3` identity is blocked until the consolidated live matrix passes, including dungeon achievements, Guild Chat geometry, native Enchanting effects, profile/recruitment/treasury/Quick Dock visual smoke, Officer Cases multi-officer behavior and the city-transition freeze reproduction gate.

## 1.8.3-rc4-r24 Enchanting Native Capture Checkpoint — 2026-08-21

- Reworked Enchanting effect capture around the native Vanilla/Octo TradeSkill tooltip path instead of treating recipe selection alone as proof that a native description exists.
- Added a one-shot selected-recipe probe through `GameTooltip:SetTradeSkillItem` when the tooltip is otherwise unused; rapid selections coalesce into one keyed task and add no polling loop.
- Preserved the real visible GameTooltip after capture; the previous reader could hide the tooltip immediately after the player hovered a TradeSkill result.
- Correctly ignores reagent `SetTradeSkillItem(recipeIndex, reagentIndex)` calls so reagent text cannot be stored as a recipe effect.
- Normalized effect provenance to `LOCAL_NATIVE`, `REMOTE_NATIVE`, `LEGACY_NATIVE` and `UNKNOWN`, while reading old `NATIVE_TOOLTIP` / `REMOTE_LEGACY` values compatibly.
- Local native capture has highest priority. RC3 and legacy RC2 mixed-version merge paths preserve richer verified native effect text against weaker/older snapshots.
- Synthetic name-derived enchant phrases remain detection-only and are neither presented nor broadcast as verified native descriptions.
- Added bounded session-only `/otl enchantdiag on|dump|off` diagnostics recording recipe index/name, native tooltip method, line count, first useful description text, provenance and result.
- Added selected-probe capture/miss counters to the existing support/performance report.
- No SavedVariables schema or network protocol change. No permanent `OnUpdate`, polling loop or new event listener.

## 1.8.3-rc4-r23 Guild Chat Runtime Geometry Checkpoint — 2026-08-21

- Replaced bottom-anchored short chat history with deterministic top alignment; short histories no longer intentionally stick to the lower edge of the viewport.
- Unified Guild Chat measurement around one canonical FontString using the same compatible chat font and responsive width as the real ScrollingMessageFrame renderer.
- Row height now derives from actual `GetStringHeight`; UTF-8 character estimation is retained only as a bounded fallback when the client returns no usable native height.
- Removed the late legacy R4 row re-measure that overwrote message-frame height using fixed 718px-era widths.
- Passed canonical measured text height through the base visible-item renderer, eliminating the old line-count-to-height reconstruction mismatch.
- Continuation grouping now changes repeated sender/time presentation and the inter-group gap without changing the base text box height.
- Removed the extra unowned 1px gap from `LayoutChatRows180`, so visible-item capacity and actual row placement use the same vertical budget.
- Preserved existing scroll-up anchoring: incoming Guild/Officer messages increment the bottom offset while the reader is above newest.
- Added centralized recognition for both the new `[Order of the Lion Addon] ... earned [...]` announcement and legacy `[Guild Achievement] ...` history across all Guild Chat presentation layers.
- Added session-only `/otl chatdiag on|dump|off` instrumentation reporting width, measured text height, row height, y-range, line count, continuation/separator/NEW state, total content height and scroll range. It is disabled by default and adds no SavedVariables or background loop.
- No SavedVariables schema or network protocol change. No permanent `OnUpdate`, polling loop or new event listener.

## 1.8.3-rc4-r22 Achievement Integrity Checkpoint — 2026-08-21

- Branded guild achievement announcements as `[Order of the Lion Addon] ...` so the source is immediately clear without opaque abbreviations.
- Changed the server-bound achievement announcement to plain text; local addon Guild Chat reconstructs the clickable achievement link, preserving a clean fallback for players without the addon.
- Kept legacy `[Guild Achievement] ...` recognition for cached/mixed-version chat history.
- Strengthened the focused achievement-card state with a blue border, left accent rail and subtle wash while preserving completion/secret colors.
- Unified boss-start and boss-victory classification through the same catalogue/custom-instance resolver, so B-series dungeon/raid checks no longer disappear when Octo reports a non-canonical zone label.
- Extended the same custom-instance handling to raid-presence and the guild-revive latch, while keeping final revive completion dungeon-boss gated.
- Added a static known-boss fast gate so ordinary target changes do not pay for fallback group/catalogue resolution.
- Tightened explicitly Lucks-named achievement conditions to normalized `Lucks` instead of the broader canonical-leader alias.
- Added no schema/protocol change, event listener, timer or permanent frame loop.

## 1.8.3-rc4-r21 Achievement Hardening Candidate — 2026-08-21

- Re-audited the complete achievement catalogue and corrected release metadata from an incorrect 146 count to the actual **142 unique definitions** (46 A + 41 B/UNDER_BANNER + 34 C + 21 D). No achievement definitions were removed by this correction; every archived r12-r20 candidate already contained the same 142 definitions.
- Added a one-time achievement catalogue/link integrity audit at achievement-hook installation. It checks required fields, duplicate IDs/names, ID safety and hyperlink ID round-trips without adding a background loop.
- Hardened Guild Chat achievement links: if OctoWoW/server transport returns an achievement announcement as readable plain text instead of preserving the custom hyperlink payload, OrderOfTheLionGM reconstructs the achievement title into a local clickable link in the addon Guild Chat. Existing preserved hyperlinks are left untouched.
- No achievement trigger/progress thresholds, SavedVariables completion state, guild announcements, Roster, Crafting, PvE, Treasury or network protocol behavior was intentionally changed.

# Changelog

## 1.8.3-rc4-r21 Release Hardening Candidate — 2026-08-21

- Prevented stale Treasury editors from silently overwriting a newer shared-goal revision from another leadership client.
- Treasury editor now protects all three edit fields (name, raised, target), reloads the winning revision after a stale save, and does not recreate a goal that was deleted remotely.
- Hardened mixed-version Crafting sync: legacy RC2 snapshots preserve trusted native enchant effect metadata for matching recipes and indirect legacy relays cannot replace an already trusted direct profession snapshot.
- Added live diagnostics for Global Search cache hits/builds/invalidations and visible Enchant tooltip capture/batch-commit counts.
- No new pages, protocols, SavedVariables schema changes, permanent OnUpdate handlers or background scan loops.

## 1.8.3-rc4-r19 Publication / Performance Candidate — 2026-08-21

### Performance corrections
- Global Search now caches one complete active-query result set against roster/data revisions for a bounded eight-second freshness window. Scrolling and filter changes reuse the same immutable source table instead of walking roster, crafting, PvE, requests and announcements again.
- Native Search is now the only Search refresh owner. The legacy Search renderer no longer builds/sorts the same result set immediately before the native renderer.
- Search category filtering keeps a tiny source-identity cache, so repeated scrolls are reduced to visible-row rebinding rather than re-filtering the full result set.
- Crafting, PvE and announcement change hooks invalidate the global Search cache immediately; committed roster revisions invalidate it without an extra polling path.
- Exact visible Enchanting tooltip captures are trailing-edge batched. A burst of newly captured descriptions performs one profession rehash, one compact manifest attempt, one Search-cache invalidation and one Professions repaint instead of repeating that work per hovered recipe.
- A dirty-profession hash guard prevents a compact crafting manifest from being sent with a stale hash if another share path runs before the tooltip batch commits.

### Regression boundary
- No permanent `OnUpdate`, event listener, network protocol, database schema or new background polling path was added.
- r18 Search icon/click ownership, complete result sets, Guild Chat spacing, Recruitment breakpoint, Treasury progress, achievement progress bars and exact-title native Enchanting capture remain unchanged.
- Roster, transport, scheduler and backup architecture were intentionally left untouched because the performance audit found their current bounded/sliced behavior safer than another pre-release rewrite.

## 1.8.3-rc4-r18 Search / Chat / Crafting Live Correction — 2026-08-21

- Fixed broken MEMBER icons in Search at the row-pool root cause: layout/capacity passes no longer reset already-bound rows back to a full class-atlas crop or erase their click target.
- Search no longer truncates recipes to 20 or the mixed source set to 50 before filters; the native viewport owns scrolling over the complete match set.
- Guild Chat keeps r17's removal of oversized gaps but restores readable breathing room for single/multiline rows and uses UTF-8 character length in fallback wrapping; long time separators use compact hour/minute wording.
- Recruitment wide composition now uses ContentHost-aware breakpoints so it actually activates at normal live sizes instead of falling back to the stretched legacy layout.
- Achievement progress tracks are slightly thicker without changing progress semantics.
- Treasury shows `<1% funded` for real non-zero contributions below one percent instead of visually reporting zero progress.
- Enchanting adds a conservative live-tooltip capture path: when the real TradeSkill tooltip is shown, its exact native descriptive sentence can replace the pending placeholder. Deferred captures are title-guarded so one recipe can never inherit another recipe's effect.
- No new permanent `OnUpdate`; Interface 11200, schema 15 and protocol 3 remain unchanged.

## 1.8.3-rc4-r17 Root-Cause Live Correction — 2026-08-21

- Rebuilt responsive Achievement and Search row pools around one native row contract, fixing the progress-strip-only-on-bottom-row and permanently dark bottom-two search results.
- Reworked Guild Chat row measurement/grouping to remove oversized vertical gaps while keeping real multiline/date/NEW spacing; restored the approved r15 Share Addon wording.
- Header now spells out `Server Time (ST)`.
- Enchanting no longer treats generated name-based text as an exact effect. Native TradeSkill/recipe tooltip text is captured with provenance and old generated r16 effects are retried/replaced; rank parsing supports Octo four-value `GetTradeSkillLine()` returns.
- Treasury funding goals and Top Contributors received separated card geometry; responsive progress width survives later data refresh.
- Wide Recruitment received a balanced two-column upper layout and bounded composer while compact/medium keeps the prior layout.
- No new permanent `OnUpdate`; Interface 11200, schema 15 and protocol 3 remain unchanged.

## 1.8.3-rc4-r16 Live Correction — 2026-08-21

- Home Latest Important Posts is content-sized for zero/one/two recent posts; `View all posts` moves to the heading and one-post previews use the freed body space.
- Header online freshness uses a real Texture marker instead of a Unicode bullet, fixing the missing green-dot presentation on 1.12 fonts.
- Enchanting persists a conservative effect summary from canonical recipe names when native hidden-tooltip lines are unavailable; details and hover now share the same effect source.
- The built-in Share Addon Guild Chat promo is shorter, and the official repository renders as `[Addon GitHub]` while preserving the full URL for click/copy.
- Whole-tree stale-method audit fixed `GetPveDB`, `EnsureSharedActivityDB156`, `GetSelectedRaid156`, and added the missing `MarkPageDirty180` helper.
- No new permanent `OnUpdate` workload; Interface 11200, schema 15 and protocol 3 remain unchanged.

## 1.8.3-rc4-r15 Social / Achievement Livefix — 2026-08-20

- Social no longer reopens into the addon just because Blizzard remembered Guild as the last Social tab. An explicit Guild click still routes to the addon Online Roster, but the native Social frame is reset to Friends before it closes; stale Guild selection from older builds is also repaired on the next Social open.
- Achievement time-series rows now keep human-readable hours/minutes in the native/recycled scrolling path instead of falling back to raw seconds.
- Recycled achievement-row tooltips are cleared before rebinding so a tooltip cannot remain attached to the achievement that previously occupied a scrolled row.
- Guild Profile recent achievements now show each achievement icon, a compact age, hover details, and are clickable to open that achievement.

## 1.8.3-rc4-r14 Live Test Candidate — 2026-08-20

### Live fixes from r13 testing
- Blizzard Social no longer auto-redirects merely because Guild was the remembered native tab. Friends / Who / Raid remain usable; only an explicit Guild-tab click opens the addon Online Roster.
- Minimap/slash toggle now follows the same close policy as the main X. By default the main window closes into Quick Dock; an obvious Interface setting can opt into full hide, and right-click on the parked Lion remains an explicit hard hide.
- Recruitment Quick Send now shows up to three recent external whisper candidates with direct Whisper and Invite actions. Message text remains runtime-private and is not written to SavedVariables.
- Crafting data now removes departed guild crafters immediately after an authoritative committed roster scan. Partial/empty startup roster states keep the conservative 60-day fallback so they cannot wipe profession data.
- Profession capture no longer loses the first explicitly opened TradeSkill/Craft window to soft performance pressure. Empty/transient profession windows are retried and never overwrite a valid snapshot; this directly targets Enchanting on custom 1.12 clients.
- Crafting diagnostics now expose empty-window retries, deferred-window drops and departed-crafter purges for live verification.
- The header includes the r14 green-dot online roster indicator backed only by the latest successful roster snapshot.

### Technical hardening retained from the r14 audit
- Backup/import/undo uses a strict lossless clone and rejects cycles, unsupported values, invalid keys, excessive depth and oversized text instead of silently dropping data.
- Sender/version state is mutated only after guild-sender and inbound-rate validation; authority pending/validation maps are TTL-pruned and capped at 64 entries.
- Network coalescing is scoped by channel, whisper target and priority so unrelated delivery domains cannot overwrite each other.
- Canonical Vanilla `CHAT_MSG_CHANNEL_NOTICE` and `UNIT_INVENTORY_CHANGED` paths are used, with custom-client aliases/events kept optional via safe registration.
- Fixed the deferred sender-roster cache return path (`senderRoster`, not the obsolete `senderRosterCache`).

### Regression boundary
- Preserves all r13 achievement migration/tabard evidence, Social panel ownership, Guild Chat URL wrapping, Home minimum-fit, PvE confirmation and Treasury confirmation fixes.
- No new permanent `OnUpdate` workload was introduced. Interface 11200, schema 15 and protocol 3 remain unchanged.

## 1.8.3-rc4-r13 Final Candidate — 2026-08-20

### Achievement state correctness
- Reworked legacy achievement migration so root progress is migrated per `character@realm` instead of being controlled by one account/guild-wide first-login marker.
- Old unattributed account-wide completions for `Under the Banner`, `Side by Side` and `Five as One` are archived and are no longer projected onto whichever character happens to log in first. Known r12 projections are conservatively removed only when their stored timestamp/evidence ties them to that migration.
- Guild-tabard achievements now require a real TabardSlot item link and verified Guild Tabard identity. Texture/count placeholders can no longer award `Under the Banner`.
- `In Uniform` adds backwards-compatible verified-tabard evidence; a bare `tabard=true` claim from an older client is not accepted by r13 as proof.
- Bulk/login equipment restoration stays silent; a genuine later TabardSlot equip can still award normally.

### Social, Guild Chat and Home
- Closing OrderOfTheLionGM no longer releases an independently opened Blizzard Social/Friends/Who panel. Social -> Guild redirect still closes the managed Social panel through the intended redirect path.
- Long Guild Chat URLs keep the full copy/open payload but render a compact label; row measurement uses the same display representation as rendering.
- Home now reserves the `View all posts` action when sizing Latest Important Posts. Compact/minimum geometry shows one readable row; two rows return only when there is enough vertical room.

### Sync confirmation hardening
- PvE refresh confirmation is accepted only from a peer this client actually selected and requested. Existing nonce and age checks remain.
- Treasury no-response timeouts no longer create a false `completed` timestamp. Unsolicited or wrong-channel `END` packets cannot manufacture success, and a completed request is closed against duplicate late `END` packets.
- A timely late WHISPER `END` from an actually requested Treasury peer can still complete a timed-out request; cache updates from unrelated packets do not masquerade as sync confirmation.

### Regression / performance boundary
- Preserved the r12/r11/r10/r9 fixes for Roster `RefreshDetails`, the single canonical `GuildRoster()` request path, achievement hyperlink opacity, Riding login silence, recycled Track/Untrack rows, WASD/focus safety, low-strata Quick Dock/minimap, Enchanting effect fallback, Morrow -> Lucks display normalization and r9 roster caches/indexes.
- 42/42 TOC Lua files compile. TOC contains 42 unique Lua entries and has zero missing/extra Lua files.
- `__impl180`: 271 unique targets, zero missing implementations.
- Permanent workload surface remains 13 `OnUpdate` scripts and 31 `RegisterEvent` calls, unchanged from r12.
- Interface 11200, schema 15, protocol 3 and SavedVariables name remain unchanged.

## 1.8.3-rc4-r12 Final Candidate — 2026-08-20

### Social/Guild panel ownership and Escape cleanup
- Social > Guild no longer runs Blizzard's Guild-tab click and then raw-hides the managed Social frame. The addon now takes ownership before the native Guild panel is shown.
- When an already-open Social frame must be dismissed, it is released through `HideUIPanel` when available and UI panel positions are recalculated. This prevents a hidden Social/Guild panel from reserving the left UI slot and shifting profession/trade windows to the right.
- Reopening Social while Guild is still the remembered tab now routes directly back to the addon Online Roster; the player no longer has to switch to another Social tab and click Guild again. Selecting another native Social tab clears that remembered Guild intent.
- Hiding the main addon now explicitly closes the detached Guild Profile, Quick Dock popover and Raid Team selection catcher so invisible-but-still-shown `UISpecialFrames` cannot consume extra Escape presses.
- Preserved the r11 Home/Guild Chat/Profile/Treasury visual corrections.

### Build identity
- Corrected the internal version/build identity so the candidate now reports RC4-r12 consistently in Bootstrap, TOC, README and release documents.

## 1.8.3-rc4-r10 Final Candidate — 2026-08-20

### PvE feedback isolation and cold-start load reduction
- Removed the global PvE timeout toast path entirely. A manual PvE refresh that receives no peer response now reports only inside PvE Hub; it can no longer appear over Achievements, Treasury or Home after the player navigates away.
- Page-scoped Roster/Crafting/PvE status toasts are cleared when navigation leaves their owning page, covering older/legacy status paths as well.
- Expected network non-response no longer enters the internal-issue log. A missing peer is normal network state, not an addon error.
- Background PvE operation changes no longer repaint operation controls while the player is on an unrelated page.
- Automatic PvE full-state refresh now contacts one compatible peer instead of three. Manual refresh retains two-peer redundancy.
- Initial PvE synchronization moved out of the first cold-login burst to 18–24 seconds after initialization, with jitter across clients. This keeps it away from the initial roster/version work and lowers simultaneous guild-client traffic.
- Successful PvE acknowledgements now preserve whether the request was manual/background, so page-scoped feedback remains correctly classified end-to-end.

### Regression confirmation
- Riding milestones remain state-reconstructed and silent; login cannot replay the earned popup.
- Achievement hyperlinks still cancel shell motion and force full opacity before routing.
- Roster member selection still uses a local forward-declared `RefreshDetails`; the old global nil-call path is absent.
- Achievement Track/Untrack remains rebound after recycled-row refresh.
- No new permanent `OnUpdate`, `RegisterEvent`, schema, protocol or SavedVariables migration was introduced.

## 1.8.3-rc4-r9 Final Candidate — 2026-08-20

### Whole-addon optimization pass
- Removed duplicate large-Roster work from the visible path. Wheel scrolling now reuses the already-painted list count; the page no longer sorts a second all-members list for summary chips; selected/focused member lookup uses a position index attached to the cached view.
- Extended the revision-aware Roster view cache to a conservative four-second reuse window and keyed it by the committed roster table, scan, filters, sorting, player context, Crafting revision and Addon-presence revision. Targeted rank/note changes still invalidate immediately.
- Cached profession-filter inference per member/crafting revision and explicitly release roster-derived caches when a full roster commits, avoiding repeated note/alias parsing and preventing old 800-member tables from being retained by runtime indexes.
- Converted Addon Users count/online/latest-version callers to a direct presence-map pass. Ordered/decorated peer lists are still built only for UI surfaces that actually display rows.
- Removed a hidden full PvE summary calculation from the generic navigation badge; the badge now asks only for unread and pending-application counts.
- Coalesced visible Guild Chat bursts and remote Crafting/PvE sync bursts into short keyed presentation refreshes. Data/unread state commits immediately; only redundant page rendering is delayed by 50–80 ms.
- Replaced the outbound protocol sanitizer's per-byte temporary table with a clean-payload fast path and bounded replacements only when a raw pipe/control byte is actually present.
- Reduced achievement safe-event overhead by relying on the existing exact-completion ownership release instead of recalculating every dynamic achievement listener after every money/roll/chat/death event. Group/zone ownership refresh remains event-driven.
- Made Fit/custom resize reflow pressure-aware: normal clients retain the existing responsive cadence, while low-FPS/transition pressure reduces expensive reflows until mouse-up.
- Presence maintenance now invalidates its normalized compatibility index when records are actually removed, preventing a pruned peer from surviving only in a derived Roster cache.

### Release boundary
- Interface 11200, schema 15, protocol 3 and the 142-achievement catalogue are unchanged.
- `OnUpdate` surface remains 13 and `RegisterEvent` surface remains 31 versus RC4-r8. No new polling loop, event owner, roster request or protocol traffic was added.

## 1.8.3-rc4-r8 Final Candidate — 2026-08-20

### Live UI and feedback corrections
- Riding milestones (`First Ride` / `Speed Without Limits`) are now recorded silently from current skill state. The 1.12/Octo client emits `SKILL_LINES_CHANGED` during login and does not provide a reliable one-shot purchase event, so these state-reconstructed achievements can no longer replay a translucent “earned” popup on login.
- Home uses a deterministic two-row toolbar on every layout pass: Overview / Guild Posts / My Profile / Guild Info remain on the primary row, while Report / Help and Since Last Visit occupy a separate utility row. Optional layout order can no longer stack the buttons.
- Official Guild Post presentation now gives the title two lines, reserves an independent badge column and reflows metadata/body below it. Guild Posts list titles also keep a dedicated badge lane.
- Achievement row recycling now refreshes Track/Untrack after native scroll/category refresh, raises the action control above recycled row surfaces and keeps the progress strip in a separate text lane.
- Automatic roster `CONFIRM` passes are background work everywhere, including timeout handling, so they no longer surface “Updating guild roster…” on unrelated pages.
- Addon-user presence checks are presence-only and no longer start PvE synchronization as a side effect of ordinary UI opens.
- PvE force/manual semantics are separated end-to-end. Automatic/guild-context PvE refreshes stay silent; delayed manual timeouts are shown only while the player is still on PvE Hub or Settings.
- Historical Treasury actor values saved as `Morrow` are displayed as **Lucks** while the old stored key remains compatible for SavedVariables/reconciliation.

### Release boundary
- Interface 11200, schema 15 and protocol 3 are unchanged.
- Permanent workload remains 13 literal `OnUpdate` script assignments and 31 `RegisterEvent` calls; no new polling loop, event registration or network protocol was added.

## 1.8.3-rc4-r7 Final Candidate — 2026-08-20

### Defensive achievement/performance hardening
- Active party/raid snapshots no longer rebuild the normalized 700+ member achievement roster set just to classify the current group; they use direct keyed roster data, the already-built scoped cache and live unit guild APIs.
- Achievement roster cache now carries the current guild identity, preventing a short-lived cache from a previous guild context from being trusted after a guild switch.
- When the client can name both guilds for a live unit, that live identity overrides stale saved roster membership in both directions.
- Presence checks prefer a positive live `UnitIsVisible` result before saved zone data, fixing portal/teleport windows where a nearby guildmate could be rejected because the roster still reported the previous zone.
- Present-member counts no longer allocate a temporary member table on event-ownership/boss paths.
- Boss listener ownership now avoids the group-snapshot fallback entirely once all relevant boss achievements are complete, and also skips that fallback when the client already confirms a tracked instance.

### Small UI polish
- Partially completed achievement rows now show a thin static progress strip beneath their status. No animation or new `OnUpdate` is used.
- Page headers received a restrained dark-gold icon plate so sections are easier to distinguish without changing the black/gold visual language.

### Release boundary
- Interface 11200, schema 15 and protocol 3 are unchanged.
- No new permanent `OnUpdate`, event registration, roster request, network poll or background loop was added.

## 1.8.3-rc4-r6 Final Candidate — 2026-08-20

- Fixed dungeon/raid achievement tracking that could be silenced after entering an instance because dynamic boss-event ownership was not refreshed for every stable zone transition.
- Added Vanilla/custom zone resilience for Blackrock Spire and Ahn'Qiraj, plus a bounded 3+ guild-group fallback for exact known boss deaths when a custom instance label cannot be resolved.
- Active party/raid guild detection now falls back to direct unit guild information instead of depending entirely on the saved roster cache.
- Blackrock Spire boss identity separates LBRS/UBRS progress when the broad zone label is used.
- Clarified First Expedition, Full Connection and shared-session achievement descriptions so their actual requirements are visible to players.
- Replaced the misleading zero-progress display `LOCKED` with `Not Started` while preserving the internal filter key for SavedVariables compatibility.
- Hardened guild-tabard detection for custom tabards through resolved slot/link/texture/count checks.
- Fixed achievement hyperlinks leaving the addon dim/translucent: UI motion now owns a scheduler deadline, and achievement deep links cancel any old shell fade and open at full opacity.
- Added targeted achievement harness coverage for 3-guild-member boss kills, broad/custom instance labels, 3/5 vs 5/5 party rules and the addonless-member distinction between Five as One and Full Connection.
- Interface remains 11200, schema 15 and protocol 3; no new permanent `OnUpdate`, polling loop or migration was introduced.

## 1.8.3-rc4-r5 Final Candidate — 2026-08-20

- Added a quiet UI-polish pass across the modern shell without changing the feature scope: subtle window cap/corner accents, contextual page icons and small title markers on standard cards.
- Replaced the flat Roster summary sentence with four compact visual counters for Online, Leadership, Level 60 and Shown results; the counters resize with Compact/Normal/XL/Fit layouts.
- Made Guild Profile more useful at a glance: your own profile receives a small **YOU** badge, other members receive a direct **Whisper** footer action, while self-profile retains **Edit About**.
- Made **My Profile** on Home more discoverable with an icon while preserving the existing Roster-first profile route and automatic right-side companion behavior.
- Added a small coin emblem to Treasury Top Contributors and kept the contributor/ledger presentation player-focused rather than exposing server-adapter internals.
- Simplified freshness wording used by Roster and Professions: old information now shows a calm age (for example `20h ago`) instead of a red `STALE` warning; recent data uses `Live` / `Updated` labels.
- Simplified Quick Dock recruitment wording: a never-used timer now reads **READY**, pending delivery reads **SENDING**, and player-facing text describes waiting for the message to appear in World chat instead of referring to a technical self-echo.
- Reworded a few remaining player-facing status strings around Addon Users, Professions, Treasury and roster updates to describe what the player is waiting for rather than implementation details.
- Static pre-release audit remains clean: 42/42 Lua modules compile, TOC has 42 unique Lua entries with 0 missing/extra modules, 41 named frames have 0 duplicate names, and only the canonical roster request path calls `GuildRoster()`.
- Permanent workload is unchanged from RC4-r4: 13 literal `OnUpdate` scripts and 31 `RegisterEvent` calls. No new polling loop, event frame, roster request, profession scan, network protocol, schema or SavedVariables migration was added.

## 1.8.3-rc4-r4 Final Candidate — 2026-08-20

- Made Guild Profile a first-class Roster companion: opening Roster automatically selects the player's visible row (or the first visible member) and opens the profile by default; the behavior can be disabled in Settings.
- Made Guild Profile prefer the right side of the main window. On slightly tight viewports it may reduce its scale modestly before falling back left/float, while retaining the existing low-viewport Fit protection.
- Promoted **My Profile** to a visible Home top tab and enlarged the Roster member action to **Open Profile** with a discovery tooltip.
- Reworked Guild Profile presentation with the Order of the Lion crest, class-colored header accent/icon border, rank badge, section icons, stronger card borders and clearer colored metadata.
- Improved Roster readability with a compact member hero area, class accent, clearer Level/Class/Rank hierarchy, colored result summary and subtle alternating rows.
- Added one consistent divider under titled cards throughout the modern UI so Home, Treasury, Profile and other card-based surfaces read as deliberate sections rather than flat text blocks.
- Avoided a duplicate profile rebuild when **My Profile** routes through Roster and the automatic Roster companion already opened the same character.
- Removed the redundant Shell runtime version/build assignment left in RC4-r3. Core/Bootstrap.lua is again the only release-identity owner, preventing diagnostics/presence identity drift.
- Current user-facing guild-leader/contact naming remains **Lucks**. The lowercase `morrow` key is retained only as a historical SavedVariables/achievement compatibility alias and is not displayed as the current leader.
- No new roster request, profession scan, network request, event registration or permanent `OnUpdate` was introduced by the profile/discovery/visual pass. Interface remains 11200, schema 15 and protocol 3.

## 1.8.3-rc4-r3 Final Candidate — 2026-08-20

- Replaced current guild contact/default leader display references to Morrow with **Lucks** while retaining the old name only as an internal compatibility alias for historical data.
- Fixed Enchanting recipe details: combine native trade/craft and recipe-link tooltips, rescan stale blank effect records, and provide a readable recipe-name fallback so enchant effects no longer render as an empty section.
- Made addon forms movement-safe: transient click-catchers no longer own the keyboard, edit boxes never autofocus when a window opens, and common form open paths no longer force text focus.
- Added physical-pixel snapping to main-window drag, resize and restore paths to prevent thin border textures from shimmering between half-pixel positions.
- Reworked Treasury presentation with goal icons, a selected-goal Top Contributors card, direct donor totals and a one-click Full Ledger view; technical guild-bank adapter UI is no longer exposed as the primary player-facing panel.
- Reworded Treasury and profile/help text around player actions instead of implementation details.
- Revalidated Fit/Compact/Normal/XL geometry across low and high viewports and preserved fixed/Fit switching semantics.
- Fixed the live Roster member-click error caused by `RefreshRosterSelection183` calling `RefreshDetails` before its local declaration was bound.
- Fixed a broader navigation bug found during the audit: the Achievements `ShowPage` wrapper discarded the previous route result, causing successful routes to look like failures to Social->Roster, achievement/profile navigation and other guarded callers.
- Fixed a PvE no-guild/guild-data-not-ready nil path found during negative testing and guarded remote request/application/board/raid/delete plus Raid Team packet handling until a real guild store exists.
- Replaced report Type/Category and Warning Category click-to-cycle controls with bounded direct popup selectors showing all available choices at once.
- Reworked the Roster filter drawer into six Quick Views plus direct Member View, Rank and Profession selectors and Saved Views.
- Added optional Social > Guild -> Online Roster integration, installed lightly at login/world entry and disableable in Settings.
- Made Escape/direct `UISpecialFrames` hide restore Quick Dock when close-to-dock is enabled, while explicit hard-hide paths remain suppressed correctly.
- Lowered Quick Dock, its popovers and the minimap button to `LOW` strata so normal bags/higher Blizzard UI can remain above them.
- Improved Guild Profile readability with colored card accents, tinted borders and clearer journey/information emphasis while retaining low-viewport scaling.
- Rewrote ordinary player-facing API/cache/snapshot/SavedVariables-style wording into action-oriented language; Diagnostics remains technical intentionally.
- Retained and re-tested RC4-r1 achievement login silence, exact achievement deep-link focus and transient-overlay cleanup.
- Interface remains 11200, SavedVariables schema 15, protocol 3 and moderation reconciliation wire compatibility remains `1.8.3-rc4+`. No permanent `OnUpdate`/polling loop was added.

## 1.8.3-rc4-r1 Final Candidate — 2026-08-19

- Fixed retrospective Riding/tabard achievement checks so relog/world entry cannot replay an already-earned toast; genuine live skill/equipment progress still notifies normally.
- Preserved achievement progress discovered before the real guild SavedVariables store is available by safely merging the temporary cold-login store into the authoritative guild store.
- Fixed Guild Chat achievement deep links losing their selected row after the search EditBox fired its delayed `OnTextChanged` debounce; programmatic focus now clears stale search state atomically.
- Cleared stale pending achievement-link targets when page opening is vetoed or fails, preventing a later unrelated Achievements visit from jumping unexpectedly.
- Hardened shell transient cleanup: nested modern modals drain as a stack, dirty-editor vetoes block navigation instead of opening a page behind the modal, forced main-hide cleanup cannot leave orphan modal children, and legacy full-page mouse shields are retired on route changes.
- Added cleanup coverage for legacy Guild Chat/crafter context shields, Action Inbox, Highlights, Group Finder composer and legacy modal overlays to prevent an invisible mouse-catching layer from surviving navigation.
- Removed the duplicate full Roster refresh from My Profile and Achievement Ranking. Focus/selection is set before the page's canonical single refresh and restored if navigation is vetoed.
- Made Guild Profile cap its own scale against the actual viewport so the 400x680 companion frame remains reachable on low-height/small Fit layouts.
- Tightened Warning editor vertical spacing for Small/Fit without changing its workflow or feature surface.
- Fixed a duplicate shell-level build identity assignment so runtime diagnostics cannot silently overwrite the Bootstrap version/build.
- Re-ran shared-SavedVariables / character-switch / multi-Officer privacy-reconciliation harnesses and retained schema `15`, protocol `3` and the existing RC4-compatible moderation wire floor.
- No new feature set, migration, permanent `OnUpdate`, polling loop or protocol change was introduced.

## 1.8.3-rc4 Final Candidate — 2026-08-19

### Moderation privacy and multi-officer consistency
- Reports against an Officer / Leadership target are now **Guild-Leader-only**. They remain Pending while the verified Guild Leader is offline and never fall back to ordinary Officers.
- Reports against the Guild Leader are not falsely submitted inside the addon; the user is directed to the external guild contact path instead.
- Leadership reconciliation is peer-scoped: hidden cases are excluded from summary counts, bucket hashes, indexes, records and chunks for peers that are not allowed to know they exist.
- Guild-Leader-only cases remain stored safely in shared SavedVariables when another Officer character logs in, but are filtered from that character's lists, actions, diagnostics and Inbox.
- Shared Inbox filtering is non-destructive: private Guild-Leader notifications survive an Officer-alt login without appearing in Inbox/Quick Dock counts or being consumed by Mark All / prune.
- Closed Cases and cleared Warnings now use wire-canonical digests so a newly synchronized Officer converges once instead of repeatedly re-requesting omitted archive/private payloads.
- A warning issued from a Guild-Leader-only complaint strips the secret Case ID and private case comment before the official warning is shared with other Leadership peers.
- Warning state is gated on ready Leadership reconciliation; the third warning attempt creates/reuses one canonical Escalation Case and never performs an automatic guild action.

### Reports and Officer workflow
- Player Report target selection uses the existing cached guild roster only and shows class-colored name, class icon, level, guild rank and online state before submission.
- Player Reports cannot be submitted until a real cached guild member is selected; editing the name after selection invalidates the target.
- Officer targets visibly switch the form to Guild-Leader-only delivery before Submit.
- Added bounded case assignment (`Take Case`, `Release`, guarded takeover), status reasons and a shared status timeline.
- `On Hold` requires a reason; `Waiting for Player` requires the question/follow-up text.
- Warnings can retain a Related Case link for ordinary Leadership cases; private Guild-Leader-only relations remain only inside the private Case timeline.
- Needs Attention uses real moderation tasks only: Escalations, New/Unassigned Cases, Waiting for Player and players at the active warning limit.

### OctoWoW professions and profiles
- Roster profession matching now uses the canonical Crafting Network cache first, so custom OctoWoW professions such as Survival work in Roster filters without free-text guessing.
- Legacy note inference remains only as fallback and deliberately does not infer Survival from arbitrary text, avoiding Hunter Survival false positives.
- Jewelcrafting remains on the same canonical profession path.
- Guild Profile keeps cache-only data semantics and honest unknown/freshness presentation; opening/switching profiles does not trigger roster/profession scans or network work.

### UI hardening
- Reduced new modal/drawer heights to fit the minimum shell workspace and hardened fixed bottom action areas.
- Officer Case detail uses the existing opaque Case drawer rather than creating an additional competing top-level window.
- New Report keeps a fixed opaque target-selection area so validation results do not move the description or Submit/Cancel buttons.
- Achievement community ranking drawer was reduced to the safe workspace height while retaining ten rows.
- Existing Roster rank actions, Promote to 2-Lion, Guild Note and Officer Note remain in their established management area.

### Performance / compatibility
- No new permanent `OnUpdate`; count remains 13.
- No new event registration; `RegisterEvent` call count remains 31.
- Reconciliation remains event/presence-driven and uses the existing pressure-aware network queue; no moderation polling loop was added.
- SavedVariables schema remains `15`; global network protocol remains `3`. RC4-specific reconciliation is version-gated to compatible `1.8.3-rc4+` peers.

## 1.8.3-rc3 pre-final — 2026-08-18

- Added bounded, event-driven Leadership reconciliation for cases and warnings. Compatible officers compare compact hash-bucket summaries, request only differing cached pages and reuse the existing pressure-aware bulk queue. A state event is hashed once for all peers and UI refresh is coalesced to batch completion; no polling, timer, roster scan or permanent `OnUpdate` was added.
- Preserved cleared-warning tombstones and terminal case state, prioritized active/open records, retained private Leadership comments during reconciliation and blocked new warnings only while an available compatible Leadership peer is still synchronizing.
- Changed cached Roster selection to repaint only the old/new visible rows plus details/profile. Selection no longer re-sorts or rebuilds the full roster.
- Expanded Guild Profile to show every profession in the canonical registry inside its existing shared scroll, including Survival and Jewelcrafting, with explicit cache/source/freshness and missing-recipe status.
- Unified Quick Dock badge, list and Mark Dock Read behind one actionable notification filter. Background refresh/sync/detection noise no longer inflates the Dock, and full Inbox read state is untouched.
- Increased report text to 240 characters (three bounded chunks) and made Player Report targets resolve exactly against the existing cached roster without a roster request.
- Kept Interface 11200, SavedVariables schema 15 and network protocol 3. This is a pre-final release candidate and remains gated on live verification with two Leadership clients and one Member client.

## 1.8.3-rc2 — 2026-08-18

- Completed the cache-only Guild Profile companion without moving or hiding the existing Roster management controls and full Guild/Officer Note text.
- Added automatic profile opening on normal member selection, bounded scroll content, responsive right/left/compact attachment, My Profile and canonical profile routing from achievement ranking.
- Added sender-bound social profile summaries, a 160-byte About Me field, honest achievement-ranking coverage and up to three local My Goals. Sharing is dirty-checked, bounded and event/user-action driven.
- Added a static Welcome / Start Here surface and a five-line Since Your Last Visit summary driven only by existing accepted events; no History replay or polling was introduced.
- Added private Feedback & Reports, officer-only Cases, targeted status/reply/follow-up delivery, official Warnings, acknowledgement, inactive history and manual Escalation Required at the 2/2 warning limit.
- Added strict M1 moderation validation to the existing security boundary: actual-sender binding for reports, cached Leadership authority for officer actions, targeted-only transport, target-officer exclusion and bounded packet/chunk validation.
- Added Home Report / Help, Roster Officer Tools and Overview Needs Attention entry points while preserving the established layouts and rank-action slot priority.
- Bounded all new durable stores and made moderation SavedVariables pruning one-time on load plus mutation-local, avoiding repeated multi-map walks during Home/list refreshes.
- Added only lazy reusable UI surfaces. Source `OnUpdate` sites remain 13 (the same as 1.8.2), event-registration sites remain 31 and the four new modules own no events, timers, scans or scheduler loops.
- Kept Interface 11200, schema 15 and network protocol 3. This remains a release candidate until the included OctoWoW live checklist passes.

## 1.8.3-rc1 — 2026-08-18

- Added configurable Close-to-Quick-Dock behaviour without changing the explicit Park action.
- Added a separate right-click hard-hide action to the parked Lion.
- Added a compact header Online indicator backed only by the last committed roster snapshot.
- Unified Crafting UI/detection labels behind one reused profession registry instead of allocating a new table per refresh.
- Added exact-context OctoWoW Survival scanning and retained Jewelcrafting through the same snapshot/recipe pipeline.
- Replaced broad Riding substring/cap matching with conservative exact skill/spell evidence and an explicit 300 threshold.
- Kept schema 15 and protocol 3; no SavedVariables migration or new permanent `OnUpdate` was introduced.

## 1.8.2 — 2026-08-18

- Final build identity is `performance-hardening-20260818` (`Interface 11200`, schema 15, protocol 3).
- Completed a full low-FPS/transition audit across login, world/zone events, scheduler deadlines, guild roster, bag events, PvE access, memory and diagnostics.
- Added graduated scheduler polling for far deadlines while retaining immediate wake-up for new urgent work and physical `OnUpdate` removal when empty.
- Installed the cold-start fence before `PLAYER_LOGIN`, removed duplicate performance/achievement login ownership and verified the legacy synchronous R6 login bag scan stays detached.
- Made the delayed retrospective login-achievement baseline yield to actual low-FPS pressure as well as combat/transition state, with a bounded wait.
- Split base and release retrospective catalogs into separate keyed tasks one second apart so both passes cannot stack in one rendered frame.
- Consolidated world/group/guild-roster event ownership and corrected the old `OTLGM_Release175R4Event` frame-name mismatch that prevented intended listener removal.
- Coalesced secondary PvE/faction/invite work and sliced automatic all-raid access recovery (four records normally, one under pressure).
- Made bag scans burst-coalesced, pressure-aware through the final runtime wrapper and self-aborting after bounded sustained severe pressure.
- Fixed deferred synchronization remaining due-now under pressure; retries now use real deadlines and recoverable requests release after a bounded pressure window instead of waking forever during city/weather FPS drops.
- Added bounded release windows for automatic login fan-out, mailbox observation and deferred profession observation; a persistently slow client no longer retains their short retry timers for the session.
- Changed severe-pressure bulk-only transport from due-now polling to a coarse two-second compatibility deadline while preserving queued packets.
- Removed repeated per-row time/FPS probes from roster slices; added bounded commit pressure waits and cancelled obsolete in-progress backup generations.
- Severe-pressure roster backup copying now waits first and then resumes in four-member, widely spaced slices.
- Amortized performance sample pruning, capped packet diagnostic kinds at 48 with O(1) membership and reserved global addon-memory recounts for explicit support actions.
- Weekly maintenance now skips a busy login attempt instead of retaining a five-minute retry task through a raid/session.
- Retired resurrection/fishing spellcast listeners by actual remaining consumer and made trade/boss ownership wrapper-aware, so optimization cannot silence D-series trade/resurrection or B-series boss progress.
- Retired the achievement-only profession event set and minute raid-presence checkpoint after their final consumers complete.
- Replaced the parked crest-only presentation with a lightweight **Quick Dock** while preserving an opt-out crest-only mode.
- Members receive Lion, Guild Chat and Notifications controls; officers additionally receive Recruitment. Permission changes update the parked layout without requiring a reload.
- Kept the saved Park coordinate anchored to the Lion and made the dock expand inward on the left/right screen half, with full-dock edge clamping.
- Added three lazy, reusable, mutually exclusive popovers. Escape uses the normal special-frame/transient path.
- Recruitment consumes canonical A/B presets, World-channel detection, cooldown and delivery echo confirmation. Inline confirmation avoids opening a hidden full-shell modal, and rotation still occurs only after a matching new self-echo.
- Guild Chat consumes only the existing `GUILD` cache, reuses eight rows, preserves unread state on open, exposes explicit Mark Read and waits for normal chat capture after sending.
- Notifications consumes the canonical bounded inbox, shows at most five unread entries, and reuses the existing Action Center route after restoring the full addon.
- Added `Settings -> Interface -> Use Quick Dock when parked`, default on, with a 44px crest-only fallback.
- Added a compact Quick Dock section to the full support report.
- Quick Dock starts no roster/profession/PvE/crafting/search/achievement/activity/sync/network work, adds no permanent `OnUpdate`, and uses one keyed minute task only while the officer Recruitment control is actually parked and visible.
- SavedVariables schema remains `15`; network protocol remains `3`; no destructive migration is performed.

## 1.8.1-rc4 — 2026-08-10

- Added one shared **client-pressure state** used by scheduler, roster, networking, profession scans, stale-on-open refreshes and deferred background work. Low FPS, active transitions, the four-second post-transition quiet window and the adaptive guard now produce consistent back-pressure across the addon.
- Added a four-second **post-transition quiet window**. Finishing the logical zone transition no longer means background sync/roster work immediately competes with the renderer while a city or weather scene is still settling.
- Initial PvE / profession / announcement / activity synchronization now defers **queue construction itself** during pressure instead of building large queues and only slowing their packet transmission afterward.
- `PLAYER_GUILD_UPDATE` shared-data work is generation-guarded, staggered and only performs a full PvE/posts/professions resync when the actual guild identity changes; ordinary rank/permission changes only refresh the cheap local state they need.
- `GUILD_ROSTER_UPDATE` secondary work is coalesced into one delayed pass rather than repeatedly refreshing raid invites, observed factions and recruitment state during an event burst.
- Automatic visible-page roster refresh now also waits for general low-FPS pressure, not only an explicit zone transition/adaptive guard.
- Roster backup snapshots are now copied **incrementally** after a valid commit. The old final-frame deep copy of hundreds of member records was removed. A snapshot becomes durable only after its bounded copy completes, preserving the previous valid backups if the client closes mid-copy.
- Full-guild sender authority-cache rebuilding and quarantined-packet replay are moved out of the final roster reader slice and wait for a calm frame.
- Roster presentation work is split from the database commit: navigation/minimap state and the heavier visible-page repaint are scheduled separately, with page repaint yielding under pressure.
- Added roster commit timing and snapshot-pipeline diagnostics so a support report can distinguish an API-read slice from database commit/UI/snapshot work.
- Bounded bag-achievement scans now reduce their per-slice work under pressure and pause at the highest pressure level.
- Heavy-work deferral wrappers now honor the central pressure state, so old background sync paths cannot wake immediately after the newer transition guards have deliberately yielded.
- Added delayed **memory baseline capture** and loaded-addon memory/latency/graphics CVar context to the one-click support report; memory recounting is performed only once per report.
- Added an automatic **one-click support self-check** for release identity, schema/protocol, required modules, roster/message APIs, scheduler errors, page circuit breakers, network backlog, recent internal issues, transition health and roster-backup progress.
- Added optional **weekly local maintenance**. It only runs when the addon UI is closed, the player is solo/out of combat and client pressure is zero; busy sessions back off for five minutes instead of waking every minute.
- Renamed the support action to **Copy Full Support Report**. `Start Clean Test -> reproduce -> Copy Full Support Report` is now the intended single support workflow.
- No new permanent `OnUpdate`, schema bump or network protocol bump.

## 1.8.1-rc3 — 2026-08-09

- Added an adaptive stutter guard that temporarily lowers scheduler, roster, network and cosmetic UI pressure after a measured addon spike or very low client FPS.
- The shared compatibility callback now has cooperative yield points, preventing network, crafting, PvE, UI and achievement work from accidentally stacking inside one Lua callback even when the outer scheduler is budgeted.
- Automatic roster refreshes now wait until zone/city transitions have settled instead of answering transition-time roster events with an immediate GuildRoster request.
- Active non-manual roster scans pause during world transitions and use smaller slices while the adaptive guard is active.
- Bulk network sync now pauses during transitions/adaptive-guard windows and network slices are paced more conservatively under pressure.
- Visible-page recovery pulses automatically slow on Smooth/low-FPS/guarded clients; automatic profession/Treasury recovery sync waits until combat/transition pressure has cleared.
- Cosmetic motion is suppressed while the adaptive guard is active.
- Full profession-window scans are deferred while combat, zone loading or the adaptive guard is active instead of competing with an already stressed frame.
- Performance diagnostics now retain the latest meaningful incident for the whole login session.
- Added Settings -> Performance toggle for Adaptive Stutter Guard and a Start Clean Test button for controlled support reproduction.
- Support Report now includes guard state, activation reason and the last auto-captured incident.

## 1.8.1-rc2 — 2026-08-09

### Quality-of-life + performance controls
- Added a dedicated **Performance** settings page with three practical profiles: Auto, Smooth and Fast Updates.
- Auto keeps the adaptive 1.8.1 behavior; Smooth uses smaller scheduler/roster slices and gentler transition pacing; Fast Updates favors faster refreshes while retaining emergency protection below low FPS.
- Added a one-click **Use Recommended** preset (Auto + Reduced motion + bulk-sync pause in combat).
- Exposed interface motion control (Full / Reduced / Off) in the native 1.8 Settings UI instead of leaving it hidden in an old compatibility path.
- Interface fades are now automatically suppressed when the client is already under heavy graphical load in Auto/Smooth profiles.
- Exposed the existing **Pause bulk addon synchronization while in combat** protection as a real user setting.
- Added **Live Performance State** in Settings: current FPS, scheduler slice timing, roster slice timing, transition state and network queue can be checked without commands.
- Added **Sync All** to Network settings. One click refreshes shared PvE, professions and guild posts with staggered scheduler work instead of three separate manual buttons.
- Extended the one-click Support Report with the selected performance profile, motion mode and combat-sync preference.
- Kept all RC1 transition smoothing, adaptive roster scanning, scheduler frame budgeting and rolling diagnostics.
- No new permanent OnUpdate, schema bump or network protocol bump.

### Release-candidate identity
- Version: `1.8.1-rc2`
- Build: `rc2-qol-performance-20260809`
- Interface: `11200`
- Schema: `15`
- Protocol: `3`

## 1.8.1-rc1 — 2026-08-09

### Performance smoothing & one-click support
- Split world/zone transition work into small keyed scheduler phases instead of running membership, group/raid, achievements, UI compatibility and other checks in one Lua callback.
- Transition phase spacing adapts conservatively when the client is already below 45/30 FPS; stale phases from an older zone transition are ignored by generation guards.
- Moved the already-bounded world-entry inventory scan farther away from city/zone loading (4 seconds) because those achievements are not latency-sensitive.
- Added a cooperative scheduler frame-time budget. Ready tasks are still priority ordered, but the scheduler yields to the next frame when its small Lua budget is spent; the budget becomes tighter under low FPS and during zone transitions.
- Added per-task scheduler timing so future reports can identify a heavy task instead of guessing from screenshots.
- Made large guild roster slices adaptive to current FPS: fewer rows and a smaller millisecond budget are used while the client is under graphical pressure.
- Extended rolling performance evidence from 60 to 180 seconds and now records FPS/zone context for addon-side spikes.
- Added **Copy Support Report** in Settings -> Network. One click creates a copy-ready report containing version/API state, current FPS, addon memory when exposed by the client, window/UI state, zone/combat/group context, scheduler/transition/roster timing, network/crafting state, recent internal issues, page circuit breakers and selected high-frequency listener ownership.
- Added conservative automatic flags to the support report (recent addon spike, scheduler errors, blocked page refreshes, unusually long scheduler/roster slices, large queue, stuck transition).
- No new permanent OnUpdate loop, schema migration or network protocol change.

### Release-candidate identity
- Version: `1.8.1-rc1`
- Build: `rc1-performance-support-20260809`
- Interface: `11200`
- Schema: `15`
- Protocol: `3`

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
- Corrected achievement catalogue metadata to **142 unique definitions** and removed confusing final-facing old 1.7.6/C5 identity from module diagnostics.

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
