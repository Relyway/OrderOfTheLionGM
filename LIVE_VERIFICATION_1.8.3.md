# Live Verification — OrderOfTheLionGM 1.8.3

Runtime: `1.8.3`  
Build: `release-1.8.3-20260827`  
Schema / Protocol: `15 / 3`

This is the short final smoke checklist for the exact packaged release.

## Upgrade / persistence

- [ ] Install over the existing schema-15 SavedVariables without deleting WTF.
- [ ] `/reload`, relog, zone change and main→alt→main preserve settings, profiles and completed achievements.
- [ ] Existing **Under the Banner**, **First Fortune** and **Master of the Trade** produce **0** duplicate popups and **0** duplicate guild announcements.

## Roster / History

- [ ] Header Online, Roster Online and Shown agree after presence refresh.
- [ ] A real login/logout refreshes presence quickly.
- [ ] A real level/rank/note/member change safely triggers the authoritative full scan.
- [ ] The one-time 1.8.3 History repair removes only the known synthetic mass JOIN/LEAVE burst; ordinary RANK/LEVEL/RETURN history remains.
- [ ] History does not immediately refill with a new JOIN/LEAVE burst.

## Professions / Recruitment

- [ ] Enchanting displays the real skill rank (for example 300/300), exact effect and reagents.
- [ ] Social 1/2 show Sunday 20:00 ST, 2SR > MS > OS and `Former Lion's Pride` unless Leadership intentionally customized them.
- [ ] Share Discord uses the full 235/240 message and contains `https://discord.gg/UNacDPrGt2` plus the first-rank-promotion note.
- [ ] Social 1 → Raid 1 → Social 2 → Raid 2 advances only after confirmed World echo; <8m waits, 8–10m amber, 10m+ green.

## Support / performance

- [ ] Normal ping/FPS/bulk-sync fluctuations do not create red support alerts.
- [ ] Self Check reports PASS when no real addon failure exists.
- [ ] Start Clean Test, play/open Roster/Search/Professions/Achievements for 10–15 minutes, then copy Full Report.
- [ ] No reproducible addon operation repeatedly exceeds 100 ms; critical/normal network queues recover instead of remaining stuck.

## Officer / package

- [ ] At least one real Guild Admin write (MOTD/info/rank or member action) succeeds and can be reverted as intended.
- [ ] The installed path is exactly `Interface/AddOns/OrderOfTheLionGM/OrderOfTheLionGM.toc`.
- [ ] About/Support reports `1.8.3 / release-1.8.3-20260827`.
