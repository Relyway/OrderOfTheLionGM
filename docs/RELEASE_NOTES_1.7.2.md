# OrderOfTheLionGM 1.7.2

Build: `stable-r3-20260720`  
Interface: `11200`  
Schema: `14`  
Protocol: `3`

## Fixed

- Removed the raw pipe delimiter from new presence/version packets. This closes the `TurtleRP/ChatThrottleLib: Invalid escape code in chat message` failure reported for the `presence` source.
- Added a final outbound transport guard that replaces control bytes and percent-encodes accidental raw pipe characters before packet sizing and retry handling.
- Version presence now includes both the public version and the exact build identifier. Incoming legacy `V|...` and `Q|...` packets from 1.7.1 and older copies remain accepted.
- The public version is now 1.7.2, so clients that previously saw the private 1.7.1 test build no longer report a false newer-version warning.

## Added

- Opening an announcement now records one revision-specific read receipt for that character.
- Leadership sees a `Read by N` button at the bottom of the full announcement reader.
- Hovering or clicking `Read by N` shows the names and guild ranks of characters that opened the current revision.
- Read receipts use the existing reaction transport under a separate `ANNREAD` target, so they do not replace Like, Seen/Acknowledge, or Support reactions.
- Addon-user tooltips retain the exact 1.7.2 build identifier when it is available.
- `/otltest` now reports how many outbound payloads were sanitized for chat compatibility.

## Compatibility

- Existing schema-14 SavedVariables are preserved.
- The network protocol remains version 3.
- Read statistics only include openings made with 1.7.2 or newer; old clients cannot retrospectively report earlier reads.
- A read receipt means the player opened the full announcement inside the addon. It does not prove how long the text was read.

## Offline verification

- 21/21 Lua files parse as Lua 5.1.
- 0 duplicate function definitions.
- 40/40 static release checks pass.
- 172/172 deterministic runtime scenarios pass.
- Interaction audit: 654 buttons and 39 edit boxes, with 0 missing mouse handlers, 0 missing click registrations, and 0 native/logical state mismatches.
