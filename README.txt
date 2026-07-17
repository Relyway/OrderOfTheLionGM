Order of the Lion Guild Manager v1.5.4

Custom guild companion for Order of the Lion on OctoWoW.
Client target: Vanilla / Interface 11200.
Created by Hikol | Discord: mrhikol | In-game: Lucks

INSTALLATION
1. Close World of Warcraft completely.
2. Delete the old Interface\AddOns\OrderOfTheLionGM folder.
3. Extract the new OrderOfTheLionGM folder into Interface\AddOns.
4. Keep WTF / SavedVariables for the first normal upgrade test.
5. Log in and run /otltest.

IMPORTANT BASELINE NOTE
This build is the corrective 1.5.4 assembled from the verified 1.5.3 source. The earlier experimental 1.5.4 archive is not the basis of this package.

MAIN 1.5.4 CHANGES
- Rebuilt the shared modal stack so the dark overlay remains behind each open window while its text, fields and buttons stay readable and clickable.
- Added a visible X to every registered modal, preserved each window's normal action/Close/Cancel button, and made Escape close the top modal first.
- Fixed Leadership Online to use the existing authoritative guild-rank system and the same rank badges used by Roster.
- The real rank-index 0 guild leader is always shown first, while the actual in-game rank name is preserved. Renaming the rank does not break its order or icon.
- Added announcement read state, NEW labels, clearer publication dates, preserved paragraphs and a scrolling full-post reader.
- Reworked the announcement archive into Active and Archived views with real counts, paging and clear empty states.
- Made Link Item and Link Recipe perform real actions: they open the addon's Guild Chat and insert the selected hyperlink into the message field without sending it automatically.
- Added recipe-link synchronization to current RC2 profession snapshots while retaining compatibility with older data.
- Removed the unsafe remote TargetByName action that could produce the red client message "Unknown unit.".
- Kept the profession categories, filters, activity readers, Cooking support, World-channel detection, notifications, Guild Board and PvE features from 1.5.3.
- Advanced SavedVariables schema to version 9 with defensive migration of existing data.

LEADERSHIP ONLINE
Leadership Online no longer depends on hard-coded rank names such as "Lucky Luck".

It uses:
- the real guild rank index supplied by the roster;
- the existing GetMemberBadge / Roster badge mapping;
- the actual current in-game rank label;
- rank-index ordering before name ordering.

As a result, the rank-index 0 guild leader is first and has the same icon as in Roster. Future rank renames do not change that behavior.

MODAL WINDOWS
The shared modal system covers:
- Leadership Announcement composer;
- full announcement reader;
- announcement Active/Archived browser;
- New Crafting Request;
- Guild Activity and Crafting Activity;
- Group Templates;
- Notice, Copy, Import and Confirmation dialogs;
- first-run onboarding.

For every registered modal:
- the background page is darkened by a separate overlay;
- the modal and all child controls are raised above that overlay;
- a visible X is available;
- the normal semantic button remains available (Close, Cancel, OK, Start, Publish, Post, and so on);
- Escape closes the top modal before the main addon window.

HOME AND ANNOUNCEMENTS
Home is built around:
- Leadership Announcements;
- Next Raid / Important PvE;
- Leadership Online;
- Recent Useful Activity;
- Guild Information & Rules.

Leadership can publish official posts with:
- title and multi-line message;
- Normal / Important / Critical importance;
- optional Notify Members;
- optional Pin on Home;
- Like / Seen / Support reactions stored per post;
- full reader, editing, archive and deletion where permissions allow.

Announcement behavior in 1.5.4:
- blank lines and paragraphs are preserved locally and across addon synchronization;
- long unbroken text is made safe for display without altering the stored message;
- Home shows a bounded preview while Read full post opens the full scrolling text;
- date and time are displayed separately from the body;
- NEW is local to each player and each announcement revision;
- opening the full post marks that revision as read;
- Active and Archived records are separated and paged.

PROFESSIONS AND WORKING LINKS
A profession is attached to a character only after the addon successfully scans an opened profession window. Guild notes are not the source of truth.

The Recipes view retains:
- profession-specific categories;
- required-level filter;
- rarity filter;
- sort controls;
- Online: All / Only;
- reagent details and quantities;
- online-first crafters;
- full Crafting Activity.

Link Item:
1. Resolves the selected crafted item hyperlink from scanned/shared data or the local item cache.
2. Opens the addon's Guild Chat on the Guild tab.
3. Inserts the item hyperlink into the input field.
4. Leaves the message unsent so the player can add text.

Link Recipe:
1. Uses the actual recipe/enchant hyperlink captured by the profession scan or received through RC2.
2. Opens the addon's Guild Chat and inserts that hyperlink.
3. Is visibly disabled with an explanatory tooltip when no recipe link is available.

Current RC2 recipe records can carry both itemLink and recipeLink. Older RC2/RCP records still load defensively; links unavailable in older or uncached data are not fabricated.

SUPPORTED CRAFTING WINDOWS
- Alchemy
- Blacksmithing
- Cooking
- Enchanting
- Engineering
- Jewelcrafting when exposed by the server/client
- Leatherworking
- Tailoring
- Mining / Smelting

PROFESSION CATEGORIES AND FILTERS
Enchanting:
- Weapon, Chest, Bracers, Gloves, Boots, Cloak, Shield, Legs, Other

Alchemy:
- Potions, Elixirs, Flasks, Transmutes, Oils, Other

Blacksmithing:
- Weapons, Armor, Shields, Tools, Special

Tailoring:
- Armor, Bags, Shirts, Cloth, Special

Leatherworking:
- Leather Armor, Mail Armor, Armor Kits, Bags, Special

Engineering:
- Devices, Explosives, Goggles, Scopes, Ammo, Pets, Materials

Cooking:
- Food Buffs, Restoration, Drinks, Special

Jewelcrafting:
- Gems, Rings, Necklaces, Trinkets, Materials

Mining / Smelting:
- Bars, Alloys, Special

Additional controls:
- Required level: Any, 1-20, 21-40, 41-59, 60, Unknown
- Rarity: Any, Common, Uncommon, Rare, Epic, Unknown
- Sort: Online, Name, Level, Rarity, Recent, Crafter count
- Online: All / Only

When item information is not cached, the recipe remains visible under Unknown instead of disappearing.

FULL ACTIVITY READERS
Home -> Recent Useful Activity -> View All opens Guild Activity with filters for:
- All
- Groups
- Crafting
- Replies
- Reactions

Professions -> Recent Crafting -> Open Full Activity opens Crafting Activity with filters for:
- All
- Recipes
- Requests
- Replies
- Reactions

Both readers are paged, capped and show time, full useful text and a destination page where available.

WORLD CHANNEL DETECTION
Recruitment resolves the joined World / World Chat / Global channel from the current client channel list instead of assuming a permanent /5 or /6.

Examples:
- AUTO /5
- AUTO /6
- MANUAL /6 only when automatic detection is unavailable and a saved fallback exists

The send buttons use the currently resolved channel number.

NOTIFICATIONS
Each category has independent visual and sound settings:
- Raid Alerts
- Leadership Announcements
- Group Finder
- Applications / Responses
- Crafting Requests
- Reactions / Replies
- Background Activity

Notify Members remains an explicit leadership choice. Routine roster scans, joins and leaves remain quiet by default.

GUILD CHAT / BOARD / PVE
- Guild Chat top tabs: Guild, Officer, Guild Board.
- Guild Board supports community posts and per-post reactions.
- PvE Hub contains Raid Alerts and Group Finder.
- Raid reactions are not official Discord sign-ups.
- Official raid sign-ups remain in Discord.
- Ctrl-clicking a remote guild-chat name opens that member in Roster instead of calling TargetByName.

ESCAPE BEHAVIOR
- In normal supported chat/search fields, Escape clears non-empty text first.
- When a modal is open, Escape closes the top modal before the addon.
- Every modal also has a visible X, so mouse-only closing is always available.

COMMANDS
/otl - open or close the addon
/otl scan - request a manual roster update
/otl minimap - toggle the minimap button
/otl wizard - reopen onboarding
/otltest - print module and loading diagnostics

VALIDATION NOTE
The final source was loaded in exact TOC order in a mocked WoW API environment and completed 130 focused assertions. The suite covered every main page, authoritative rank ordering/badges, all registered modal layers and X buttons, multiline announcement transfer, NEW/read state, archive modes, working Item/Recipe link insertion, RC2 packet bounds/reassembly, Crafting Request validation, schema-8-to-9 migration and diagnostics.

The build environment cannot launch the real OctoWoW client. Complete TEST_CHECKLIST_1.5.4.txt during the first in-game acceptance test.
