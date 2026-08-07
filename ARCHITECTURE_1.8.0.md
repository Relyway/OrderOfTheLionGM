# Architecture — OrderOfTheLionGM 1.8.0

## Release identity

- Version: 1.8.0
- Build: final-public-20260808
- Interface: 11200
- SavedVariables schema: 15
- Network protocol: 3

## Runtime principles

### Sleeping keyed scheduler
`Modules/Core/Events.lua` owns the shared keyed scheduler. Its frame `OnUpdate` is attached only while scheduled work is pending and is removed when the task set becomes empty. Features schedule keyed work instead of adding permanent heartbeat frames.

### Foreground-only UI clock
`Modules/UI/Shell.lua` owns one `page-clock` task while the addon window is visible. The ST header is refreshed on every page. Recruitment/Guild Chat/Professions/Treasury use the same pulse for their small recovery checks. Quiet pages use a 30-second cadence because the header only displays minutes. Closing or parking the main window cancels the task; reopen/unpark explicitly re-arm it.

### Hidden-page dirty state
Late runtime coordination prevents expensive hidden-page rebuilds. Hidden pages become dirty and rebuild when shown.

### Bounded list rendering
Roster/History/Inactive/Search/Professions/Raid Team paths use reusable rows or explicit visible capacities. The Roster correctness boundary is its calculated viewport capacity; child clipping, when exposed by the client, is only defence-in-depth.

## Activity and ST time basis

Activity calendar keys and heatmap hours use server time. A one-time compatibility conversion moves legacy local-calendar buckets into ST keys while retaining real timestamps.

Retention and period boundaries use real sample timestamps:
- 90-day pruning uses `lastSampleAt` where available;
- period overlap uses the newest sample rather than the first sample of the day;
- peak-window membership uses the exact `peakAt` timestamp.

This prevents a day that straddles a cutoff from disappearing nearly 24 hours early.

Total and online guild composition are generated together in one roster pass and cached by committed-roster + faction-observation revision.

Faction metadata is optional roster metadata (`faction180`, `factionSeenAt180`, `factionSource180`). Evidence can come from exposed player/party/raid units, from a target only while an already-required achievement tracker is active, or from a compatible peer reporting its own faction in existing V/Q presence traffic. Invalid faction values are rejected and unknown members stay Unknown.

## Achievement event ownership

Older feature layers remain in the tree for migration/runtime compatibility. `Performance176.lua` removes duplicated or unnecessarily broad event ownership and provides the final ownership layer.

Ownership is recalculated on login/group/zone transitions, immediately after achievement completion and after backup import/undo/rollback.

Examples:
- mail/money/loot/system/guild-chat trackers exist only while their corresponding final achievements need them;
- A027 trade UI events and B079 craft-confirm events retire when complete;
- tabard, duel, rabbit and ambient-emote listeners retire when their achievements are complete;
- the legacy instance-boss frame only receives boss-victory combat text inside a known supported instance while a relevant achievement is incomplete;
- target/combat/death encounter bookkeeping inside that frame is enabled only for achievements that require encounter death history;
- a one-shot deferred ownership recheck after `PLAYER_ENTERING_WORLD` handles clients whose zone text is not settled at the first callback.

The design avoids using cosmetic Activity statistics as justification for high-frequency gameplay listeners.

## Networking

Protocol 3 is retained. Presence V/Q packets accept one optional faction field (`Alliance` or `Horde`). Older clients may omit it. No new protocol family or background faction query is introduced.

## Release boundary

Final audit 2 adds no permanent `OnUpdate`, background faction scanner, new polling framework, schema bump or protocol bump.
