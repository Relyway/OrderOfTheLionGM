# Technical audit - OrderOfTheLionGM 1.7.2

## Scope

This audit covers the 1.7.2 delta on top of the stable interaction foundation: TurtleRP transport compatibility, version/build discovery, and announcement read receipts.

## Root cause addressed

The reported transport failure was attached to source `presence`. The legacy presence payload used a raw pipe delimiter (`V|version` / `Q|version`). TurtleRP's embedded ChatThrottleLib can validate pipe escape sequences while processing outbound traffic and reject a raw pipe as an invalid chat escape.

1.7.2 uses delimiter-safe caret packets (`V^version^build`, `Q^version^build`) and retains inbound support for the old form. A transport-boundary sanitizer also strips control bytes and converts any accidental raw pipe to `%7C` before packet-size validation.

## Read receipt design

Read receipts are revision-specific and use the existing authenticated C1 reaction transport with target type `ANNREAD`. This avoids a protocol/schema bump and keeps ordinary announcement reactions independent. The sender identity remains checked against the actual addon-message sender by the existing security gate.

Leadership-only UI exposure is intentionally compact: one `Read by N` button in the full reader and a tooltip containing up to 18 names plus an overflow count.

## Data and compatibility

- Schema remains 14.
- Protocol remains 3.
- Existing SavedVariables require no reset.
- Existing Like/Seen/Support reaction data is unchanged.
- Old version packets are accepted inbound.
- Read counts start with 1.7.2 because older versions did not emit opening receipts.

## Automated results

- Static validator: 40 passed, 0 failed.
- Lua parser: 21 passed, 0 failed.
- Duplicate definitions: 0.
- Runtime scenarios: 172 passed, 0 failed.
- UI interaction tree: 654 buttons, 39 edit boxes, 0 missing mouse registration, 0 missing click registration, 0 state mismatch.

## Remaining live-only boundary

Offline mocks cannot prove behavior inside the real OctoWoW executable or third-party addon hooks. The supplied checklist specifically verifies that TurtleRP no longer raises the presence escape error and that read receipts propagate between two live clients.
