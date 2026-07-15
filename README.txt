ORDER OF THE LION GUILD MANAGER v1.0.9
OctoWoW / Vanilla-style client (Interface 11200)

INSTALLATION
1. Close the game completely.
2. Delete the old Interface\AddOns\OrderOfTheLionGM folder.
3. Copy the new OrderOfTheLionGM folder into Interface\AddOns\.
4. Do not delete the WTF folder. Existing OTLGM_DB history and settings are preserved.

OPENING
- Left-click the lion minimap icon.
- Right-click the minimap icon to update the roster.
- Shift-drag the minimap icon to move it.
- Slash command: /otl
- Diagnostic command: /otltest

MAIN PAGES
HOME
- Members, online count, unread changes and database freshness.
- Online leadership with quick whisper buttons.
- Addon-user indicator in the left sidebar.

OVERVIEW
- Members, online players, seven-day joins/leaves, inactivity and unread events.
- Level 60, Core Raider, Leadership and addon-user statistics.
- Recent important guild activity and copyable weekly summary.

GUILD INFO
- Compact MOTD and full guild information panels.
- Getting-started guide and online leadership.
- Color-grouped rank handbook with numbered rows and clear columns.
- Rank groups: Restricted, Visitor, Social, Raiding and Leadership.
- Current in-game rank is highlighted.

ROSTER
- Online members use class colors; offline members are grey.
- Rank-first default sorting and sortable columns.
- Search, rank, profession, zone, level, activity and inactivity filters.
- Core Raiders display a purple raid icon.
- Leadership and restricted ranks display their own role icons.
- Member card includes notes, dates, profession tags and recent history.

HISTORY
- Joined, left, rank, note, return and milestone events.
- Only milestone levels 10/20/30/40/50/60 are recorded.
- Date grouping, search, filters and unread state.
- Mark Reviewed and Copy Weekly use separate action styling.

ACTIVITY
- Daily, seven-day and all-time online peaks.
- Weekday/hour activity heatmap.
- Class and level composition.

INACTIVE
- Officer review for 14/30/60/90+ day inactivity.
- Local Review, Keep and Exempt states.

RECRUITMENT
- Protected pinned messages.
- Three named custom slots.
- Last-sent timestamps, confirmation and Recruit 1/Recruit 2 rotation.

ADDON USER DETECTION
- The sidebar shows how many OTHER guildmates were detected using this addon.
- Hover the button to see character names, versions, online state and last-seen time.
- Click the button to ping currently online addon users.
- Detection is not an installation census: offline users cannot answer until their addon sends a message.
- Detection uses small hidden addon messages and does not write to normal guild chat.

GUILD RANK HANDBOOK
- Tormented: temporary restricted disciplinary rank.
- Guest: visitor/newcomer.
- Lion: full social member.
- Loyal: trusted active social member.
- Raider: approved guild raider.
- Core Raider: main raid roster.
- Helper: first staff rank.
- Officer: guild management.
- Lionheart: senior leadership.
- Lucky Luck: Guild Leader.

PERFORMANCE
- Roster wheel scrolling does not request new server data.
- Additional online refresh runs only while the Roster page is visible.
- A stale Roster may refresh on entry, then no more than once every five minutes.
- Background database interval remains configurable: Off/10/20/30/60 minutes.
- Hidden pages are not rebuilt after every roster event.

CHAT POLICY
The addon writes one short line only after a successful manual or timed database update:
[Lion GM] Roster updated: 43 online / 378 members.

Detected joins, leaves, ranks, notes, milestone levels, returns and addon users stay inside the addon.

DATA
SavedVariables table: OTLGM_DB
- roster and three valid backup snapshots;
- history and unread state;
- activity samples;
- inactive review labels;
- recruitment messages and last-sent times;
- detected addon users and versions;
- interface and filter settings.

SLASH COMMANDS
/otl
/otl scan
/otl minimap
/otl wizard
/otl backup
/otl help
/otltest
Shift + /otl reset
