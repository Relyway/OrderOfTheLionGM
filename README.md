# Order of the Lion Guild Manager v1.0.9

Officer-ready guild companion addon for **Order of the Lion** on **OctoWoW**, targeting the Vanilla-style `Interface 11200` client.

## Highlights

- Stable v1.0.8 interface-loading foundation.
- Member Tools and Officer Tools navigation.
- Addon-user detection with names, versions, online state and last-seen time on hover.
- Expanded Overview with guild growth, Level 60, Core Raider, Leadership and addon-adoption statistics.
- Color-grouped rank handbook:
  - Tormented
  - Guest
  - Lion
  - Loyal
  - Raider
  - Core Raider
  - Helper
  - Officer
  - Lionheart
  - Lucky Luck
- Purple Core Raider and Raider role icons.
- Distinct History actions for **Mark Reviewed** and **Copy Weekly**.
- Safe, controlled roster refreshes without scroll-triggered scanning.

## Installation

Close the game and replace the entire folder:

```text
Interface\AddOns\OrderOfTheLionGM
```

Do not delete the `WTF` folder. Saved data is stored in `OTLGM_DB`.

## Commands

```text
/otl
/otl scan
/otl minimap
/otl wizard
/otl backup
/otl help
/otltest
Shift + /otl reset
```

## Addon-user detection

The counter shows other guild characters detected using compatible addon versions. Hover for names and details; click to ping online users.

This is not a complete installation census: offline players cannot answer until their addon sends a hidden addon message.
