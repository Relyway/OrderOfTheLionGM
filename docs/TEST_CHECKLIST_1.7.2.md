# OctoWoW live checklist - OrderOfTheLionGM 1.7.2

Test first on the Guild Leader and one ordinary guild member before guild-wide distribution.

## Installation

1. Close the game completely.
2. Back up `WTF`.
3. Replace only `Interface\\AddOns\\OrderOfTheLionGM`.
4. Keep existing SavedVariables.
5. Start the game and run `/otltest`.

Expected identity:

- `Addon version: 1.7.2`
- `Build: stable-r3-20260720`
- `Schema version: 14`
- `Runtime foundation 1.7.2: Loaded`

## Network/TurtleRP

1. Log in with TurtleRP enabled.
2. Run `/otltest`, wait one minute, then run it again.
3. Confirm no new `Invalid escape code in chat message` appears.
4. Confirm `Last network error (.../presence)` does not reappear.
5. `Outbound payloads sanitized for chat compatibility` may remain 0; a positive value means the safety guard repaired an unsafe packet.

## Version detection

1. Put 1.7.2 on two guild characters.
2. Open the Addon Users tooltip.
3. Confirm both show v1.7.2 and no `UPDATE v1.7.1` warning is displayed.
4. A character still running 1.7.1 may remain in the 24-hour list until its record ages out; it must not make 1.7.2 appear outdated.

## Announcement read receipts

1. Leadership publishes or opens an existing announcement.
2. Open the full post on the second character.
3. Return to the leadership character and reopen the post.
4. Confirm the bottom button says `Read by 1` or more.
5. Hover or click it and confirm the reader name appears.
6. Open the same revision repeatedly and confirm the count does not increase twice for the same character.
7. Edit the announcement, creating a new revision; the new revision should begin its own read count.
8. Confirm Like, Acknowledge/Seen, and Support still work independently.

## Regression smoke test

- Roster: notes, Promote, Demote, Remove, Whisper, Invite.
- Treasury: create, edit, save, delete, confirm delete.
- Group Finder member: Share /g, role, note, Request to Join, Cancel, Whisper.
- Group Finder leader: applicant Whisper, Accept + Invite, Decline, Close Group.
- Guild Chat: send, links, tabs, Highlights.
- Professions: filters, favorites, recipe details, crafter whisper.
- Home: announcement reader, raid card, Inbox.
