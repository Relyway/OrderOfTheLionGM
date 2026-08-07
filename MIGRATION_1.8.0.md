# Migration Notes — 1.8.0

## Supported upgrade path

Version 1.8.0 keeps `OTLGM_DB` and database schema **15** used by the late RC line. Do not delete SavedVariables for a normal upgrade.

Compatibility handling remains for older 1.7.x data and the earlier 1.8 schema transition. Roster history, posts/read state, achievement progress, crafting data, PvE data, Treasury data, backups and settings are retained when their records validate successfully.

## Optional faction metadata

Roster entries may gain:
- `faction180`
- `factionSeenAt180`
- `factionSource180`

These fields are optional and require no schema bump. Missing evidence remains Unknown.

## Activity time-basis compatibility

Older Activity records were keyed through the local operating-system calendar even though the UI labelled the heatmap as ST. 1.8 performs a one-time in-place conversion to ST calendar keys/hours.

Real timestamps remain absolute. Final audit 2 also uses the newest sample for retention/overlap boundaries and the exact `peakAt` for peak-window membership, preventing boundary days from being removed or excluded early.

The conversion performs no server query and starts no extra roster scan.

## Backup restore behavior

Import/undo still replaces only validated local data. After successful restore or rollback, runtime-only achievement event ownership is recalculated so an achievement restored from complete to incomplete becomes trackable without waiting for the next login.

## Upgrade procedure

1. Optionally back up `WTF`.
2. Replace `Interface/AddOns/OrderOfTheLionGM` with the 1.8.0 folder.
3. Keep SavedVariables intact.
4. Login and run `/otltest`.
5. Open Roster, Activity, Recruitment and PvE Hub once to exercise final layout/data paths.
