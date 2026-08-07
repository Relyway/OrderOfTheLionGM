# Live Verification — OrderOfTheLionGM 1.8.0

Build: `final-public-20260808`

The packaged release has static/parser/archive coverage. The following items depend on the real OctoWoW client/server and should be smoke-tested before the public GitHub tag.

## Required final smoke

1. **Roster / responsive geometry**
   - Open Roster with enough members to fill the viewport.
   - Run Normal -> Compact -> Fit -> Normal and resize where available.
   - Scroll at every size.
   - PASS: no pooled row, text, member card or action control renders outside the visible addon content area.

2. **Park / real screen bounds**
   - Use the UI-scale configuration that previously restricted Park movement.
   - Drag the parked crest near all four visible edges, especially top-right.
   - `/reload`, then unpark/park again.
   - PASS: Park can approach the real visible edge, never becomes unreachable and restores consistently.

3. **Foreground ST clock lifecycle**
   - Open Roster or Settings and leave it visible across a minute change.
   - Close `/otl`, wait, reopen the same page.
   - Park, wait, unpark.
   - PASS: ST header resumes each time; no page switch is needed to restart it.

4. **Recruitment elapsed time**
   - Open Recruitment in Compact/Fit and remain there at least 10–15 seconds.
   - Close/reopen and Park/unpark while staying on Recruitment.
   - PASS: Last World Recruitment elapsed text keeps updating and no compact controls overlap.

5. **Activity ST boundary / composition**
   - Open Activity with known mixed-faction guild members in party/raid where practical.
   - PASS: direct observations move members from Unknown to Alliance/Horde, coverage/ratio update and opening the page itself does not trigger a new roster/network scan.
   - If testing near server midnight is practical, confirm Today/heatmap day follows ST rather than the local PC calendar.

6. **Raid date + clock**
   - Inspect a raid event whose ST date differs from local time/date if possible.
   - PASS: date and `HH:MM ST` describe the same server-time day.

7. **Dynamic achievement ownership**
   - Confirm restored published achievements do not show the old performance-paused message.
   - Naturally verify available paths such as Mail Call, money thresholds, loot roll, guild legendary link and rabbit tracking.
   - If a backup is available, restore/undo a state where one such achievement changes from complete back to incomplete and verify it becomes trackable without `/reload`.

8. **Boss listener context regression**
   - In the open world, play normally and change targets frequently; no achievement error should appear.
   - Enter a supported dungeon/raid with an incomplete boss achievement and kill a qualifying boss.
   - PASS: boss progress still records in-instance while no broad open-world target/combat parser is required.

## Preserved regression checks

- Guild / Officer Chat: Highlights -> Mentions/Pinned; Clear Local remains explicit.
- Search: member/recipe/group/post results open the concrete native target.
- Raid Teams: filters, Clear Filters, selection clearing, role actions, Ask for Invite, contacts.
- Roster: Guest -> Lion workflow with real permissions; first-seen/join date; online/rank sorting.
- Treasury: donor/history visibility on a second compatible client when real contribution data exists.
- Professions: recipe/enchanting data and manual sync with a compatible peer.
- 45–60 minute normal session: no growing queue, repeated Lua error, runaway refresh or recurring FPS spike.

Any reproducible live-only failure should be fixed before tagging 1.8.0 rather than hidden as a documentation limitation.


## Final public checks

- **Faction balance:** open Activity after a roster refresh. Confirm Alliance/Horde icons and counts are readable in Normal, Compact and Fit. Hover the card and verify coverage/unknown diagnostics are sensible.
- **Manual guild invite:** on a rank with invite permission, Roster -> **+ Invite**, enter a valid non-member name, press Enter, and confirm the normal guild invitation is sent. Repeat on a rank without permission and confirm the action is disabled/rejected.
