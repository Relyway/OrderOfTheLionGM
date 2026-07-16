# Order of the Lion Guild Manager v1.4.1

Guild companion addon created specifically for **Order of the Lion** on **OctoWoW**, targeting the Vanilla-style `Interface 11200` client.

## Main features

- Prominent **Home**, **Guild Chat** and **PvE Hub** sections.
- Improved guild and officer chat with rank indicators, item/spell links, website-link copying and online officer information.
- Guild roster with filters, class colours, clearer member details, profession detection and officer actions.
- Expanded English profession dictionary, including `BS`, `JC`, Jewelcrafting and profession specializations.
- Live Group Finder with leader-created groups and Join Requests.
- Raid Alerts with Raider/Core Raider reminder filtering.
- Shared Guild Board and direct addon-to-addon synchronization.
- Recruitment presets with a World-only anti-spam timer.
- Guild Information, activity analytics, history, inactivity review and addon-user detection.

## PvE Hub

PvE data is exchanged through hidden in-game addon messages. GitHub and OctoLauncher are needed only to install new code, not to publish groups, raid notices or board posts.

### Group Finder

A player creates a group as its leader and chooses:

- activity category;
- dungeon, quest or activity name;
- leader role;
- maximum group size;
- open Tank, Healer and DPS positions;
- optional short note.

Other users can select a role and send a private Join Request. The leader can **Accept + Invite**, **Decline** or **Whisper** each candidate. Accepted candidates update the visible group composition. Groups and applications expire automatically after 60 minutes.

### Raid Alerts

- Leadership can publish one active raid notice with raid name, meeting point, note and start time.
- The active notice remains visible in PvE Hub.
- Popup and normal-chat reminders are shown only to characters with **Raider** or **Core Raider** ranks.
- Quick reminders: one hour, 30 minutes, 15 minutes and Starting Now.
- A separate `Post to /g` button reaches players without the addon.
- Official raid sign-ups remain strictly in Discord.

### Guild Board

- Short shared notes for casual coordination or guild humour.
- Up to three active posts per character.
- Posts expire after 48 hours.
- Authors and leadership can remove posts.

## Professions

Profession detection reads English abbreviations and profession names from guild notes. Current automatic detection focuses on core professions and includes:

- Alchemy;
- Blacksmithing (`BS`);
- Enchanting;
- Engineering;
- Herbalism;
- Jewelcrafting (`JC`);
- Leatherworking (`LW`);
- Mining;
- Skinning;
- Tailoring;
- First Aid.

Where the note contains a recognized specialization, the roster shows it alongside the base profession.

## Addon network and presence

- Every valid OrderOfTheLionGM packet refreshes the sender's presence.
- Manual Ping also requests current PvE data.
- Version replies are sent directly to the requester.
- A recently received packet counts as proof that the sender is online even if the local roster snapshot is older.
- The counter excludes the current character, so two connected accounts should each show one other online addon user.

## Performance

- No constant network broadcast.
- No additional roster polling for PvE features.
- Public records use revisions, expiration times and duplicate protection.
- Applications are sent privately between applicant and leader.
- Outbound messages use a paced queue.

## Commands

- `/otl` — open or close the addon.
- `/otl scan` — request a manual roster update.
- `/otl minimap` — toggle the minimap button.
- `/otltest` — diagnostic module report.
