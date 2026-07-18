ORDER OF THE LION GUILD MANAGER v1.5.7
OctoWoW / Vanilla interface 11200
Created for Order of the Lion by Hikol
Discord: mrhikol | In-game: Lucks

PURPOSE
-------
OrderOfTheLionGM is the official guild companion for roster management, guild
communication, leadership announcements, PvE coordination, professions,
crafting requests, activity and officer tools.

VERSION 1.5.7 HIGHLIGHTS
------------------------
1.5.7 focuses on reliable shared profession data, persistent icons, a cleaner
raid planner, readable activity and predictable player interaction.

CRAFTING RELIABILITY AND ICONS
------------------------------
- Local profession scans read recipe and reagent textures directly from the
  open Trade Skill or Craft window.
- Valid textures are stored on the recipe and in a bounded fallback cache.
- RC3 transfers recipe icons, reagent icons, links, quality and materials.
- The new manifest sync compares each profession by owner, profession, hash,
  recipe count and data completeness before requesting a full snapshot.
- Only missing, changed or more complete professions are transferred.
- A complete cached profession may be relayed to a late client when the
  original crafter is offline.
- Incomplete snapshots never replace an existing complete profession.
- Existing recipe data stays visible while synchronization is running.
- Old incomplete records may need one fresh scan by a current-version client;
  once received, their real textures remain stored instead of reverting to red
  squares or disappearing with a cold item cache.

PROFESSIONS INTERACTION
-----------------------
- Left-click a specific crafter to whisper that exact character.
- Right-click a crafter for Whisper, Invite to Group and View in Roster.
- Invite is disabled for offline crafters.
- The general recipe menu no longer duplicates the crafter whisper action.
- Recipe/item links, qualities, materials, filters, categories, Cooking and
  Crafting Requests from earlier versions remain available.

RAID PLANNER
------------
- The legacy Publish Raid Notice controls are fully hidden under the planner.
- Multiple independent raid events remain supported.
- Creation, editing, duplication, cancellation and permanent deletion remain
  separate actions.
- The editor shows a live weekday, full date and [HH:MM ST] preview.
- Leadership may mark a raid as MAIN RAID.
- Main raids use a distinct icon, gold treatment and pinned schedule position.
- Home still lists the next three active raids in chronological order.
- Cancelled raids remain visibly marked in Upcoming until their scheduled time
  has passed, then remain available in the cancelled history.
- Everyone may read raids and mark Seen. Ready is limited to approved raid
  guild ranks and explains the Discord registration requirement.

ANNOUNCEMENTS AND ACTIVITY
--------------------------
- New Announcement always opens with empty Title and Message fields.
- Editing an existing announcement still loads its current content.
- Guild Activity includes Important and Publications filters.
- Raid, announcement, group, crafting, reply and reaction entries use distinct
  prefixes and colors for faster scanning.

GUILD CHAT MENUS
----------------
- Incoming messages no longer close the player context menu.
- Right-clicking the same player again closes it.
- Right-clicking another player switches the menu target.
- Click outside, Escape, an action, or a tab change closes the menu.
- The outside-click shield stays active even after the message list refreshes.

OPTIMIZATION
------------
- No new permanent OnUpdate loop was added.
- UI refreshes remain event-driven and affect only the relevant open page.
- Manifest exchange is compact; full recipe snapshots are requested only when
  required.
- Network queues and packet sizes remain bounded for Vanilla addon messages.
- Icon-cache cleanup runs through the existing heartbeat only once per six
  hours and trims only the fallback index, never the icons stored on recipes.
- Raid metadata travels in a separate compact packet so core raid packets stay
  below the 250-byte addon-message limit.

INSTALLATION
------------
1. Close World of Warcraft completely.
2. Delete the old Interface\AddOns\OrderOfTheLionGM folder.
3. Extract the install archive into Interface\AddOns.
4. Confirm this path exists:
   Interface\AddOns\OrderOfTheLionGM\OrderOfTheLionGM.toc
5. Do not delete the WTF folder when updating.

COMMANDS
--------
/otl          Open or close the addon
/otl scan     Update the guild roster
/otl minimap  Show or hide the minimap button
/otl wizard   Open the first-run guide
/otl backup   Export a backup
/otltest      Print module diagnostics

LIVE ACCEPTANCE
---------------
The build environment validates Lua syntax, module load order, full UI
construction and isolated multi-client data transfer. It cannot launch the
real OctoWoW client. Use TEST_CHECKLIST_1.5.7.txt for final in-game acceptance,
preferably with two accounts using the current version.
