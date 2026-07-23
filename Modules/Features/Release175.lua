-- Order of the Lion Guild Manager v1.7.5
-- Standalone release runtime for Vanilla/OctoWoW.
-- Order of the Lion Guild Manager v1.7.5
-- Release-wide polish, approved achievement additions and raid invite contacts.
-- This module intentionally adds no OnUpdate handler.

local R175 = {
    revision = 1,
    registered = false,
    eventDedupe = {},
}
OTLGM.release175 = R175

local A175 = OTLGM.achievements174
local GROUP_TICK_175 = 60
local MAX_NAMES_175 = 2200
local BASE_CLASSES_175 = {
    WARRIOR=true, PALADIN=true, HUNTER=true, ROGUE=true, PRIEST=true,
    SHAMAN=true, MAGE=true, WARLOCK=true, DRUID=true,
}
local FINAL_DUNGEON_BOSSES_175 = {
    bazilthredd=true, arugalfinal=true, archmagearugal=true, mutanus=true,
    akumaifinal=true, akumai=true, charlgarazorflank=true, princesstheradras=true,
    emperorandagranthaurissan=true, generaldrakkisath=true, darkmastergandling=true,
    baronrivendare=true, kinggordok=true, alzzinthewiildshaper=true,
    highinquisitorwhitemane=true, mutanusdevourer=true, vanefist=true,
}
local HOSTILE_CAPITALS_175 = {
    ALLIANCE = { orgrimmar=true, thunderbluff=true, undercity=true },
    HORDE = { stormwindcity=true, ironforge=true, darnassus=true },
}
local RABBIT_NAMES_175 = {
    rabbit=true, hare=true, snowshoehare=true, prairiehare=true,
}
local DRAGON_TARGETS_175 = {
    ladykatranaprestor=true, onyxia=true,
}
local FISHING_POLE_TYPES_175 = {
    fishingpole=true, fishingpoles=true,
}
local SAFE_ICON_175 = "Interface\\Icons\\INV_Misc_Book_09"

local function Trim175(text)
    text = tostring(text or "")
    return string.gsub(text, "^%s*(.-)%s*$", "%1")
end

local function ShortName175(name)
    return string.gsub(Trim175(name), "%-.*$", "")
end

local function NameKey175(name)
    return string.lower(ShortName175(name or ""))
end

local function Key175(text)
    text = string.lower(Trim175(text))
    return string.gsub(text, "[^%w]", "")
end

local function Count175(tbl)
    local total = 0
    local key
    for key in pairs(tbl or {}) do total = total + 1 end
    return total
end

local function Clamp175(value, low, high)
    value = tonumber(value) or 0
    if low and value < low then value = low end
    if high and value > high then value = high end
    return value
end

local function AddSet175(self, key, value, maximum)
    value = Key175(value)
    if value == "" then return false end
    local set = self:GetAchievementSet174(key)
    if set[value] then return false end
    if Count175(set) >= (maximum or MAX_NAMES_175) then return false end
    set[value] = true
    return true
end

local function EnsureMap175(db, key)
    if type(db[key]) ~= "table" then db[key] = {} end
    return db[key]
end

local function PlayerName175()
    return ShortName175(UnitName and UnitName("player") or "")
end

local function IsPlayer175(name)
    return NameKey175(name) == NameKey175(PlayerName175())
end

local function IsGuildMember175(self, name)
    if not name or name == "" then return false end
    local cache = self.RefreshAchievementRosterCache174 and self:RefreshAchievementRosterCache174(false)
    return cache and cache.members and cache.members[NameKey175(name)] ~= nil
end

local function GetGuildLeader175(self)
    self.runtime = self.runtime or {}
    local cache = self.runtime.guildLeader175
    if cache and self:Now() - (cache.ts or 0) < 30 then return cache.name end
    local leader = ""
    local db = self:GetGuildDB()
    local name, member
    for name, member in pairs(db and db.roster or {}) do
        if type(member) == "table" and tonumber(member.rankIndex) == 0 then leader = ShortName175(member.name or name) break end
    end
    if leader == "" and GetNumGuildMembers and GetGuildRosterInfo then
        local total = tonumber(GetNumGuildMembers(true)) or 0
        local index, rosterName, _, rankIndex
        for index=1,total do
            rosterName, _, rankIndex = GetGuildRosterInfo(index)
            if rosterName and tonumber(rankIndex) == 0 then leader = ShortName175(rosterName) break end
        end
    end
    self.runtime.guildLeader175 = { name=leader, ts=self:Now() }
    return leader
end

local function FullGuildParty175(self)
    local group = self:GetGroupSnapshot174()
    return group, group and group.isParty and group.total == 5 and group.guild == 5
end

local function PartySignature175(group)
    local names = {}
    local index, member
    for index=1,table.getn(group and group.guildMembers or {}) do
        member = group.guildMembers[index]
        table.insert(names, member.key or NameKey175(member.name))
    end
    table.sort(names)
    return table.concat(names, ",")
end

local function GroupRaceData175(group)
    local races = {}
    local first = nil
    local same = true
    local index, member, raceName, raceToken
    for index=1,table.getn(group and group.guildMembers or {}) do
        member = group.guildMembers[index]
        raceName, raceToken = UnitRace and UnitRace(member.unit)
        raceToken = string.upper(tostring(raceToken or raceName or ""))
        if raceToken ~= "" then
            races[raceToken] = true
            if not first then first = raceToken elseif first ~= raceToken then same = false end
        else same = false end
    end
    return races, same and first ~= nil
end

local function CurrentZone175(self)
    local zone, subzone = self:GetLocation174()
    return zone ~= "" and zone or subzone
end

local function CurrentSubzone175(self)
    local _, subzone = self:GetLocation174()
    return subzone or ""
end

local function CurrentPlace175(self)
    local zone, subzone = self:GetLocation174()
    if zone == "" then return subzone end
    if subzone == "" then return zone end
    return zone .. "@" .. subzone
end

local function IsLocation175(self, wanted)
    wanted = Key175(wanted)
    local zone, subzone = self:GetLocation174()
    return Key175(zone) == wanted or Key175(subzone) == wanted
end

local function IsDungeon175(self)
    local rule, zone = self:GetCurrentInstanceRule174()
    return rule and rule.kind == "DUNGEON", rule, zone
end

local function IsRaid175(self)
    local rule, zone = self:GetCurrentInstanceRule174()
    return rule and rule.kind == "RAID", rule, zone
end

local function SetTexture175(region, path)
    if not region then return end
    region:SetTexture(nil)
    region:SetTexCoord(0.08,0.92,0.08,0.92)
    region:SetVertexColor(1,1,1)
    region:SetAlpha(1)
    region:SetTexture(path and path ~= "" and path or SAFE_ICON_175)
end

local function Text175(parent, template, text, x, y, width, justify)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then label:SetWidth(width) end
    label:SetJustifyH(justify or "LEFT")
    label:SetText(text or "")
    return label
end

local function Panel175(parent, x, y, width, height, kind)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:SetWidth(width) frame:SetHeight(height)
    if OTLGM.ApplyPanelSkin then OTLGM:ApplyPanelSkin(frame, kind or "surface") end
    return frame
end

local function Button175(parent, text, x, y, width, height, callback, style)
    local button = CreateFrame("Button", nil, parent)
    if OTLGM.PrepareInteractiveControl170 then OTLGM:PrepareInteractiveControl170(button, "button") end
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetWidth(width) button:SetHeight(height)
    button:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=9, insets={left=2,right=2,top=2,bottom=2} })
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.text:SetWidth(width - 8)
    button.text:SetText(text or "")
    button.actionStyle = style or "normal"
    button.callback175 = callback
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function() if not this.disabled and this.callback175 then this.callback175(this) end end)
    button:SetScript("OnEnter", function() this.hovered=true if OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(this) end end)
    button:SetScript("OnLeave", function() this.hovered=nil if OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(this) end if GameTooltip then GameTooltip:Hide() end end)
    if OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(button) end
    return button
end

local function AddAchievement175(def)
    if not A175 or not def or not def.id or A175.byId[def.id] then return false end
    table.insert(A175.catalog, def)
    A175.byId[def.id] = def
    return true
end

-- Approved additions. B-prefixed IDs avoid collisions with published A IDs.
local ADDITIONS_175 = {
    { id="UNDER_BANNER", category="SOCIAL", name="Under the Banner", description="Equip the Order of the Lion guild tabard.", icon="Interface\\Icons\\INV_BannerPVP_01", progress="underBanner", required=1 },
    { id="B047", category="SOCIAL", name="No Two Alike", description="Form a full guild party made up of five different classes.", icon="Interface\\Icons\\INV_Misc_Book_09", progress="fullFiveClasses", required=5 },
    { id="B048", category="SOCIAL", name="Rank and File", description="Form a full guild party with five different guild ranks represented.", icon="Interface\\Icons\\INV_Misc_Note_02", progress="fullFiveRanks", required=5 },
    { id="B049", category="SOCIAL", name="Long Watch", description="Spend two uninterrupted hours grouped with the same guild member.", icon="Interface\\Icons\\INV_Misc_PocketWatch_01", progress="longWatchSeconds", required=7200 },
    { id="B050", category="SOCIAL", name="Reunion Tour", description="Group with a guild member again after at least ninety days apart.", icon="Interface\\Icons\\INV_Misc_PocketWatch_02", progress="reunion", required=1 },
    { id="B051", category="SOCIAL", name="Many Peoples, One Banner", description="Form a full guild party made up of five different races.", icon="Interface\\Icons\\INV_BannerPVP_01", progress="fullFiveRaces", required=5 },
    { id="B052", category="SOCIAL", name="Family Resemblance", description="Form a full guild party where every member is the same race.", icon="Interface\\Icons\\Spell_Holy_PrayerOfSpirit", progress="sameRaceParty", required=5 },
    { id="B053", category="SOCIAL", name="The Regular Table", description="Spend ten uninterrupted minutes at the same inn with four other guild members.", icon="Interface\\Icons\\INV_Drink_03", progress="regularTableSeconds", required=600 },
    { id="B054", category="DUNGEONS", name="Level Bridge", description="Defeat a dungeon boss with a level gap of at least twenty among the guild members present.", icon="Interface\\Icons\\INV_Misc_Map_01", progress="levelBridge", required=1 },
    { id="B055", category="SECRETS", name="Proper Respect", description="The title is your clue.", revealed="Target the current Guild Leader and use /salute.", icon="Interface\\Icons\\Ability_Warrior_Salute", progress="properRespect", required=1, secret=true },
    { id="B056", category="SOCIAL", name="Trial by Combat", description="Defeat the Guild Leader in a friendly duel.", icon="Interface\\Icons\\Ability_DualWield", progress="leaderDuelWin", required=1 },
    { id="B057", category="SECRETS", name="Know Your Place", description="The title is your clue.", revealed="Lose a friendly duel to the current Guild Leader.", icon="Interface\\Icons\\INV_Shield_05", progress="leaderDuelLoss", required=1, secret=true },
    { id="B058", category="DUNGEONS", name="Royal Escort", description="Defeat a dungeon boss while grouped with the Guild Leader.", icon="Interface\\Icons\\Spell_Holy_DevotionAura", progress="royalEscort", required=1 },
    { id="B059", category="SOCIAL", name="Friendly Rivalry", description="Win and lose a duel against the same guild member.", icon="Interface\\Icons\\Ability_Warrior_Challange", progress="friendlyRivalry", required=1 },
    { id="B060", category="SOCIAL", name="Class Challenger", description="Defeat a guild member of every supported class in a duel.", icon="Interface\\Icons\\INV_Sword_04", progress="duelClasses", required=9 },
    { id="B061", category="DUNGEONS", name="Clean Comeback", description="After a failed attempt, defeat the same boss on the very next pull without losing a guild member.", icon="Interface\\Icons\\Spell_Holy_Renew", progress="cleanComeback", required=1 },
    { id="B062", category="DUNGEONS", name="Same Crew, New Dungeon", description="Complete three different dungeons with the same full guild party.", icon="Interface\\Icons\\INV_Misc_Key_03", progress="sameCrewDungeons", required=3 },
    { id="B063", category="DUNGEONS", name="In Uniform", description="Defeat a dungeon boss with every member of the full guild party wearing a guild tabard.", icon="Interface\\Icons\\INV_BannerPVP_02", progress="uniformBoss", required=1 },
    { id="B064", category="SECRETS", name="Wrong Tool for the Job", description="The title is your clue.", revealed="Defeat a dungeon boss while holding a fishing pole.", icon="Interface\\Icons\\INV_Fishingpole_02", progress="fishingPoleBoss", required=1, secret=true },
    { id="B065", category="SECRETS", name="Bag Space Is a Myth", description="The title is your clue.", revealed="Defeat a dungeon boss with no free bag slots.", icon="Interface\\Icons\\INV_Misc_Bag_10", progress="fullBagsBoss", required=1, secret=true },
    { id="B066", category="DUNGEONS", name="Broken but Unbowed", description="Defeat a dungeon boss while at least one equipped item is completely broken.", icon="Interface\\Icons\\INV_Hammer_20", progress="brokenBoss", required=1 },
    { id="B067", category="DUNGEONS", name="Third Time's the Charm", description="Defeat a dungeon boss on exactly the third attempt.", icon="Interface\\Icons\\INV_Misc_Dice_02", progress="thirdAttempt", required=1 },
    { id="B068", category="SOCIAL", name="Undertaker", description="Successfully resurrect twenty-five different guild members.", icon="Interface\\Icons\\Spell_Holy_Resurrection", progress="resurrectedGuild", required=25 },
    { id="B069", category="DUNGEONS", name="Back on Your Feet", description="Be resurrected by a guild member and survive until the next dungeon boss falls.", icon="Interface\\Icons\\Spell_Holy_LayOnHands", progress="revivedSurvival", required=1 },
    { id="B070", category="DUNGEONS", name="Together, Stronger!", description="Complete five dungeons with a full guild party.", icon="Interface\\Icons\\Ability_Warrior_RallyingCry", progress="fullGuildDungeonCompletions", required=5 },
    { id="B071", category="DUNGEONS", name="Stronger Than Ever!", description="Complete fifteen dungeons with a full guild party.", icon="Interface\\Icons\\Spell_Holy_DevotionAura", progress="fullGuildDungeonCompletions", required=15 },
    { id="B072", category="DUNGEONS", name="Lion's Might!", description="Complete thirty dungeons with a full guild party.", icon="Interface\\Icons\\Ability_Warrior_BattleShout", progress="fullGuildDungeonCompletions", required=30 },
    { id="B073", category="RAIDS", name="All Nine Answer", description="Defeat a raid boss with all nine classes represented among the guild members present.", icon="Interface\\Icons\\INV_BannerPVP_02", progress="allNineRaid", required=9 },
    { id="B074", category="SOCIAL", name="Gone Fishing", description="Have every member of a full guild party fishing at the same time.", icon="Interface\\Icons\\INV_Misc_Fish_02", progress="fullPartyFishing", required=5 },
    { id="B075", category="SECRETS", name="Diplomatic Incident", description="The title is your clue.", revealed="Have a full guild party fall in an enemy capital.", icon="Interface\\Icons\\Spell_Shadow_DeathCoil", progress="diplomaticIncident", required=1, secret=true },
    { id="B076", category="SOCIAL", name="Fortune Favors the Guild", description="Receive an epic item while adventuring in a full guild party.", icon="Interface\\Icons\\INV_Misc_Gem_01", progress="epicGuildLoot", required=1 },
    { id="B077", category="LEGACY", name="A Little of Everything", description="Unlock at least one achievement in every main category.", icon="Interface\\Icons\\INV_Misc_Book_09", progress="categoryCoverage", required=7 },
    { id="B078", category="LEGACY", name="Decorated Member", description="Unlock twenty-five achievements.", icon="Interface\\Icons\\INV_Jewelry_Talisman_07", progress="achievementCount", required=25 },
    { id="B079", category="PROFESSIONS", name="Master Craftsman", description="Complete five hundred successful crafting actions.", icon="Interface\\Icons\\Trade_BlackSmithing", progress="craftActions", required=500 },
    { id="B080", category="LEGACY", name="First Ride", description="Learn your first riding skill.", icon="Interface\\Icons\\Ability_Mount_RidingHorse", progress="ridingSkill", required=1 },
    { id="B081", category="LEGACY", name="Speed Without Limits", description="Reach the highest riding skill currently supported by the server.", icon="Interface\\Icons\\Ability_Mount_WhiteTiger", progress="ridingSkill", required=300 },
    { id="B082", category="SECRETS", name="What a Beautiful Moon...", description="The title is your clue.", revealed="Use /moon between 22:00 and 04:00 server time while grouped with a guild member.", icon="Interface\\Icons\\Spell_Arcane_StarFire", progress="beautifulMoon", required=1, secret=true },
    { id="B083", category="SECRETS", name="Proud Lion", description="The title is your clue.", revealed="Have a full guild party salute in Goldshire.", icon="Interface\\Icons\\Ability_Warrior_Salute", progress="proudLion", required=5, secret=true },
    { id="B084", category="SECRETS", name="Dragon's Bane", description="The title is your clue.", revealed="Use /joke or /rude while targeting Lady Katrana Prestor or Onyxia.", icon="Interface\\Icons\\INV_Misc_Head_Dragon_01", progress="dragonsBane", required=1, secret=true },
    { id="B085", category="SECRETS", name="Run, Rabbit, Run!", description="The title is your clue.", revealed="Personally defeat a rabbit or hare critter.", icon="Interface\\Icons\\INV_Misc_Food_54", progress="rabbitRun", required=1, secret=true },
    { id="B086", category="SECRETS", name="This Was a Mistake", description="The title is your clue.", revealed="Target the current Guild Leader and use /bonk.", icon="Interface\\Icons\\INV_Hammer_04", progress="leaderBonk", required=1, secret=true },
}

local function RegisterAchievements175()
    if R175.registered or not A175 then return end
    local index
    for index=1,table.getn(ADDITIONS_175) do AddAchievement175(ADDITIONS_175[index]) end
    A175.catalogRevision = math.max(tonumber(A175.catalogRevision) or 0, 10)
    R175.registered = true
end

RegisterAchievements175()

-- ---------------------------------------------------------------------------
-- Achievement progress and release-safe presentation
-- ---------------------------------------------------------------------------

local BaseProgress175 = OTLGM.GetAchievementProgress174
local BasePresentation175 = OTLGM.GetAchievementPresentation174
local SAFE_CATEGORY_ICONS_175 = {
    SOCIAL="Interface\\Icons\\Spell_Holy_PrayerOfSpirit",
    GROUP_FINDER="Interface\\Icons\\INV_Sword_04",
    PROFESSIONS="Interface\\Icons\\Trade_BlackSmithing",
    DUNGEONS="Interface\\Icons\\INV_Misc_Key_03",
    RAIDS="Interface\\Icons\\INV_BannerPVP_02",
    LEGACY="Interface\\Icons\\INV_Misc_PocketWatch_01",
    SECRETS="Interface\\Icons\\INV_Misc_Book_09",
}
local SAFE_ICON_PATHS_175 = {
    ["Interface\\Icons\\INV_Misc_Book_09"]=true,
    ["Interface\\Icons\\Spell_Holy_PrayerOfSpirit"]=true,
    ["Interface\\Icons\\INV_Sword_04"]=true,
    ["Interface\\Icons\\Ability_DualWield"]=true,
    ["Interface\\Icons\\Spell_Holy_BlessingOfProtection"]=true,
    ["Interface\\Icons\\INV_BannerPVP_01"]=true,
    ["Interface\\Icons\\INV_Misc_Note_02"]=true,
    ["Interface\\Icons\\INV_Misc_PocketWatch_01"]=true,
    ["Interface\\Icons\\INV_Misc_Map_01"]=true,
    ["Interface\\Icons\\INV_Letter_15"]=true,
    ["Interface\\Icons\\Ability_Rogue_Sprint"]=true,
    ["Interface\\Icons\\Spell_Holy_SealOfSalvation"]=true,
    ["Interface\\Icons\\INV_Misc_PocketWatch_02"]=true,
    ["Interface\\Icons\\Trade_BlackSmithing"]=true,
    ["Interface\\Icons\\INV_Misc_Key_03"]=true,
    ["Interface\\Icons\\INV_BannerPVP_02"]=true,
    ["Interface\\Icons\\Spell_Holy_DevotionAura"]=true,
    ["Interface\\Icons\\INV_Shield_05"]=true,
    ["Interface\\Icons\\Spell_Holy_Resurrection"]=true,
    ["Interface\\Icons\\Ability_Druid_ChallangingRoar"]=true,
    ["Interface\\Icons\\INV_Crown_01"]=true,
    ["Interface\\Icons\\INV_Hammer_04"]=true,
    ["Interface\\Icons\\INV_Helmet_06"]=true,
    ["Interface\\Icons\\INV_Misc_Bag_10"]=true,
    ["Interface\\Icons\\INV_Misc_Gear_01"]=true,
    ["Interface\\Icons\\INV_Misc_Head_Dragon_01"]=true,
    ["Interface\\Icons\\INV_Misc_Herb_07"]=true,
    ["Interface\\Icons\\INV_Misc_Note_01"]=true,
    ["Interface\\Icons\\INV_Misc_Rune_01"]=true,
    ["Interface\\Icons\\INV_Pick_02"]=true,
    ["Interface\\Icons\\INV_Scroll_03"]=true,
    ["Interface\\Icons\\INV_Shield_06"]=true,
    ["Interface\\Icons\\Spell_Holy_DivineIntervention"]=true,
    ["Interface\\Icons\\Spell_Holy_Renew"]=true,
    ["Interface\\Icons\\Spell_Holy_SealOfSacrifice"]=true,
    ["Interface\\Icons\\Spell_Shadow_Twilight"]=true,
}

local ICON_OVERRIDES_175 = {
    B047="Interface\\Icons\\INV_Sword_04", B048="Interface\\Icons\\INV_Misc_Note_02",
    B049="Interface\\Icons\\INV_Misc_PocketWatch_01", B050="Interface\\Icons\\INV_Misc_Map_01",
    B051="Interface\\Icons\\INV_BannerPVP_01", B052="Interface\\Icons\\Spell_Holy_PrayerOfSpirit",
    B053="Interface\\Icons\\INV_Misc_Book_09", B054="Interface\\Icons\\INV_Misc_Map_01",
    B055="Interface\\Icons\\INV_Crown_01", B056="Interface\\Icons\\Ability_DualWield",
    B057="Interface\\Icons\\INV_Shield_05", B058="Interface\\Icons\\Spell_Holy_DevotionAura",
    B059="Interface\\Icons\\INV_Sword_04", B060="Interface\\Icons\\INV_BannerPVP_02",
    B061="Interface\\Icons\\Spell_Holy_Renew", B062="Interface\\Icons\\INV_Misc_Key_03",
    B063="Interface\\Icons\\INV_BannerPVP_01", B064="Interface\\Icons\\INV_Pick_02",
    B065="Interface\\Icons\\INV_Misc_Bag_10", B066="Interface\\Icons\\INV_Hammer_04",
    B067="Interface\\Icons\\INV_Misc_PocketWatch_01", B068="Interface\\Icons\\Spell_Holy_Resurrection",
    B069="Interface\\Icons\\Spell_Holy_DivineIntervention", B070="Interface\\Icons\\INV_Shield_06",
    B071="Interface\\Icons\\Spell_Holy_DevotionAura", B072="Interface\\Icons\\INV_Crown_01",
    B073="Interface\\Icons\\INV_BannerPVP_02", B074="Interface\\Icons\\INV_Misc_Herb_07",
    B075="Interface\\Icons\\Spell_Shadow_Twilight", B076="Interface\\Icons\\INV_Misc_Rune_01",
    B077="Interface\\Icons\\INV_Misc_Book_09", B078="Interface\\Icons\\INV_Misc_Note_01",
    B079="Interface\\Icons\\Trade_BlackSmithing", B080="Interface\\Icons\\Ability_Rogue_Sprint",
    B081="Interface\\Icons\\Spell_Holy_SealOfSalvation", B082="Interface\\Icons\\Spell_Shadow_Twilight",
    B083="Interface\\Icons\\INV_BannerPVP_01", B084="Interface\\Icons\\INV_Misc_Head_Dragon_01",
    B085="Interface\\Icons\\INV_Misc_Herb_07", B086="Interface\\Icons\\INV_Hammer_04",
    UNDER_BANNER="Interface\\Icons\\INV_BannerPVP_01",
}

local function SafeAchievementIcon175(def)
    if not def then return SAFE_ICON_175 end
    local override = ICON_OVERRIDES_175[def.id or ""]
    if override and SAFE_ICON_PATHS_175[override] then return override end
    if def.icon == "Interface\\Icons\\INV_Misc_QuestionMark" then return SAFE_CATEGORY_ICONS_175[def.category] or SAFE_ICON_175 end
    if SAFE_ICON_PATHS_175[def.icon or ""] then return def.icon end
    return SAFE_CATEGORY_ICONS_175[def.category] or SAFE_ICON_175
end

-- Normalize all catalog icons once. Invalid texture paths in Vanilla otherwise
-- leave the red client question mark and can inherit a recycled row texture.
local function RepairAchievementIcons175()
    local index, def
    for index=1,table.getn(A175 and A175.catalog or {}) do
        def = A175.catalog[index]
        def.icon = SafeAchievementIcon175(def)
    end
end
RepairAchievementIcons175()

function OTLGM:GetAchievementProgress174(def)
    if not def then return 0, 1 end
    if def.id == "UNDER_BANNER" then
        return self:IsAchievementComplete174("UNDER_BANNER") and 1 or 0, 1
    end
    if string.sub(tostring(def.id),1,1) ~= "B" then return BaseProgress175(self, def) end
    local db = self:EnsureAchievements174()
    if def.id == "B081" then
        local current = tonumber(db.counters.ridingSkill175) or 0
        local cap = math.max(1, tonumber(db.counters.ridingCap175) or tonumber(def.required) or 1)
        if db.completed[def.id] then return cap, cap end
        return math.min(current, cap), cap
    end
    if db.completed[def.id] then return def.required or 1, def.required or 1 end
    local progress = def.progress
    local current = 0
    if progress == "fullFiveClasses" then
        local group, full = FullGuildParty175(self)
        current = full and Count175(group.classes) or 0
    elseif progress == "fullFiveRanks" then
        local group, full = FullGuildParty175(self)
        local ranks, index, member = {}, 0, nil
        if full then for index=1,table.getn(group.guildMembers) do member=group.guildMembers[index] ranks[Key175(member.rank)] = true end end
        current = Count175(ranks)
    elseif progress == "fullFiveRaces" then
        local group, full = FullGuildParty175(self)
        local races = full and GroupRaceData175(group) or {}
        current = Count175(races)
    elseif progress == "sameRaceParty" then
        local group, full = FullGuildParty175(self)
        local _, same = GroupRaceData175(group)
        current = full and same and 5 or 0
    elseif progress == "duelClasses" or progress == "resurrectedGuild" then
        current = Count175(self:GetAchievementSet174(progress))
    elseif progress == "sameCrewDungeons" then
        current = tonumber(db.counters.sameCrewBest175) or 0
    elseif progress == "categoryCoverage" then
        current = tonumber(db.counters.categoryCoverage175) or 0
    elseif progress == "achievementCount" then
        current = self:GetAchievementCount174()
    elseif progress == "ridingSkill" then
        current = tonumber(db.counters.ridingSkill175) or 0
    elseif progress == "fullPartyFishing" then
        current = tonumber(db.counters.fishingPartyNow175) or 0
    else
        current = tonumber(db.counters[progress]) or 0
    end
    return math.min(def.required or 1, current), def.required or 1
end

function OTLGM:GetAchievementPresentation174(def, complete)
    if not def then return "Achievement", "", SAFE_ICON_175, false end
    if def.secret and not complete then return def.name, "The title is your clue.", SafeAchievementIcon175(def), true end
    local name, description, _, secret = BasePresentation175(self, def, complete)
    return name, description, SafeAchievementIcon175(def), secret
end

local function SelectButton175(button, selected)
    if not button then return end
    button.selected = selected and true or false
    button.selected156 = selected and true or false
    if OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(button) end
end

local function SetButtonText175(button, text)
    if not button then return end
    if button.text and button.text.SetText then button.text:SetText(text or "")
    elseif button.label156 and button.label156.SetText then button.label156:SetText(text or "") end
end

function OTLGM:GetAchievementDisplayList174()
    local category = OTLGM_DB.settings.achievementCategory174 or "OVERVIEW"
    local filter = OTLGM_DB.settings.achievementFilter174 or "ALL"
    local search = string.lower(Trim175(OTLGM_DB.settings.achievementSearch174 or ""))
    local result = {}
    local index, def, complete, current, required, matches
    for index=1,table.getn(A175.catalog) do
        def = A175.catalog[index]
        complete = self:IsAchievementComplete174(def.id)
        current, required = self:GetAchievementProgress174(def)
        matches = search == "" or string.find(string.lower(def.name or ""),search,1,true) or string.find(string.lower(def.description or ""),search,1,true)
        if matches and (category == "OVERVIEW" or def.category == category) then
            if filter == "ALL" or (filter == "COMPLETE" and complete) or (filter == "PROGRESS" and not complete and current > 0 and not def.secret) or (filter == "LOCKED" and not complete and (def.secret or current <= 0)) then
                table.insert(result, def)
            end
        end
    end
    if category == "OVERVIEW" then
        table.sort(result, function(left,right)
            local lc, rc = OTLGM:IsAchievementComplete174(left.id), OTLGM:IsAchievementComplete174(right.id)
            if lc ~= rc then return lc end
            if lc and rc then
                local lt = tonumber(OTLGM:GetAchievementCompletedAt174(left.id)) or 0
                local rt = tonumber(OTLGM:GetAchievementCompletedAt174(right.id)) or 0
                if lt ~= rt then return lt > rt end
            else
                local la, lb = OTLGM:GetAchievementProgress174(left)
                local ra, rb = OTLGM:GetAchievementProgress174(right)
                local lp = lb > 0 and la/lb or 0
                local rp = rb > 0 and ra/rb or 0
                if (lp > 0) ~= (rp > 0) then return lp > 0 end
                if lp ~= rp then return lp > rp end
            end
            return tostring(left.name) < tostring(right.name)
        end)
    end
    return result
end

function OTLGM:BuildAchievementsPage174(page)
    self.ui.achievementTitleIcon174 = page:CreateTexture(nil,"OVERLAY")
    self.ui.achievementTitleIcon174:SetPoint("TOPLEFT",page,"TOPLEFT",0,-2)
    self.ui.achievementTitleIcon174:SetWidth(28) self.ui.achievementTitleIcon174:SetHeight(28)
    SetTexture175(self.ui.achievementTitleIcon174,SAFE_ICON_175)
    Text175(page,"GameFontNormalLarge","Guild Achievements",38,-2,430,"LEFT")
    self.ui.achievementCount174 = Text175(page,"GameFontNormal","0 / 87",574,-4,144,"RIGHT")
    self.ui.achievementCount174:SetTextColor(1,0.82,0.35)
    Text175(page,"GameFontNormalSmall","Shared adventures, reliable milestones and personal guild history.",38,-29,540,"LEFT"):SetTextColor(0.66,0.66,0.63)

    local progress = Panel175(page,38,-51,500,13,"background")
    self.ui.achievementProgressFill174 = progress:CreateTexture(nil,"ARTWORK")
    self.ui.achievementProgressFill174:SetPoint("LEFT",progress,"LEFT",3,0)
    self.ui.achievementProgressFill174:SetHeight(7)
    self.ui.achievementProgressFill174:SetTexture(0.92,0.58,0.12,0.95)
    self.ui.achievementProgressText174 = Text175(page,"GameFontNormalSmall","",550,-51,168,"RIGHT")
    self.ui.achievementProgressText174:SetTextColor(0.76,0.70,0.60)

    self.ui.achievementSearch174 = CreateFrame("EditBox","OTLGM_AchievementSearch175",page)
    if self.PrepareInteractiveControl170 then self:PrepareInteractiveControl170(self.ui.achievementSearch174,"editbox") end
    self.ui.achievementSearch174:SetPoint("TOPLEFT",page,"TOPLEFT",0,-76)
    self.ui.achievementSearch174:SetWidth(310) self.ui.achievementSearch174:SetHeight(25)
    self.ui.achievementSearch174:SetAutoFocus(false) self.ui.achievementSearch174:SetMaxLetters(60)
    self.ui.achievementSearch174:SetFontObject("GameFontHighlightSmall")
    self.ui.achievementSearch174:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=9,insets={left=7,right=5,top=4,bottom=4}})
    self.ui.achievementSearch174:SetBackdropColor(0.018,0.018,0.018,1)
    self.ui.achievementSearch174:SetBackdropBorderColor(0.30,0.26,0.20,1)
    self.ui.achievementSearchPlaceholder175 = Text175(page,"GameFontNormalSmall","Search achievements...",10,-82,280,"LEFT")
    self.ui.achievementSearchPlaceholder175:SetTextColor(0.42,0.42,0.40)
    self.ui.achievementSearch174:SetText(OTLGM_DB.settings.achievementSearch174 or "")
    self.ui.achievementSearch174:SetScript("OnTextChanged",function()
        OTLGM_DB.settings.achievementSearch174=this:GetText() or ""
        if OTLGM.ui.achievementSearchPlaceholder175 then if this:GetText()=="" then OTLGM.ui.achievementSearchPlaceholder175:Show() else OTLGM.ui.achievementSearchPlaceholder175:Hide() end end
        OTLGM.ui.achievementOffset174=0
        OTLGM:RefreshAchievements174()
    end)
    self.ui.achievementSearch174:SetScript("OnEditFocusGained",function() if OTLGM.ui.achievementSearchPlaceholder175 then OTLGM.ui.achievementSearchPlaceholder175:Hide() end end)
    self.ui.achievementSearch174:SetScript("OnEditFocusLost",function() if this:GetText()=="" and OTLGM.ui.achievementSearchPlaceholder175 then OTLGM.ui.achievementSearchPlaceholder175:Show() end end)
    self.ui.achievementSearch174:SetScript("OnEscapePressed",function() if this:GetText()~="" then this:SetText("") else this:ClearFocus() end end)

    self.ui.achievementFilterButtons174 = {}
    local filters={{"ALL","All"},{"COMPLETE","Completed"},{"PROGRESS","In Progress"},{"LOCKED","Locked"}}
    local index
    for index=1,4 do
        local key=filters[index][1]
        self.ui.achievementFilterButtons174[key]=Button175(page,filters[index][2],320+((index-1)*100),-76,94,25,function()
            OTLGM_DB.settings.achievementFilter174=key
            OTLGM.ui.achievementOffset174=0
            OTLGM.ui.achievementFocus174=nil
            OTLGM:RefreshAchievements174()
        end,"utility")
    end

    local categories=Panel175(page,0,-111,170,407,"background")
    Text175(categories,"GameFontNormalSmall","CATEGORIES",10,-9,150,"LEFT"):SetTextColor(1,0.78,0.20)
    self.ui.achievementCategoryButtons174={}
    for index=1,table.getn(A175.categories) do
        local info=A175.categories[index]
        local key=info.key
        local button=Button175(categories,info.label,8,-28-((index-1)*29),154,25,function()
            OTLGM_DB.settings.achievementCategory174=key
            OTLGM.ui.achievementOffset174=0
            OTLGM.ui.achievementFocus174=nil
            OTLGM:RefreshAchievements174()
        end,"normal")
        button.icon175=button:CreateTexture(nil,"OVERLAY")
        button.icon175:SetPoint("LEFT",button,"LEFT",7,0) button.icon175:SetWidth(14) button.icon175:SetHeight(14)
        SetTexture175(button.icon175,info.icon)
        button.text:ClearAllPoints() button.text:SetPoint("LEFT",button,"LEFT",27,0) button.text:SetWidth(84) button.text:SetJustifyH("LEFT")
        button.countText174=Text175(button,"GameFontNormalSmall","",116,-7,30,"RIGHT")
        self.ui.achievementCategoryButtons174[key]=button
    end
    Text175(categories,"GameFontNormalSmall","OPTIONS",10,-269,150,"LEFT"):SetTextColor(1,0.78,0.20)
    self.ui.achievementPopupButton174=Button175(categories,"Popups: On",8,-289,154,25,function()
        OTLGM_DB.settings.achievementPopups174=not OTLGM_DB.settings.achievementPopups174 OTLGM:RefreshAchievements174()
    end,"utility")
    self.ui.achievementChatButton174=Button175(categories,"Guild chat: On",8,-318,154,25,function()
        OTLGM_DB.settings.achievementGuildChat174=not OTLGM_DB.settings.achievementGuildChat174 OTLGM:RefreshAchievements174()
    end,"utility")
    Text175(categories,"GameFontNormalSmall","Shift-click a card to place its link in the open WoW chat box.",10,-352,148,"LEFT"):SetTextColor(0.54,0.54,0.52)

    local list=Panel175(page,180,-111,538,407,"surface")
    self.ui.achievementRows174={}
    for index=1,6 do
        local row=CreateFrame("Button",nil,list)
        if self.PrepareInteractiveControl170 then self:PrepareInteractiveControl170(row,"button") end
        row:SetPoint("TOPLEFT",list,"TOPLEFT",8,-8-((index-1)*61))
        row:SetWidth(522) row:SetHeight(57)
        row:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=9,insets={left=2,right=2,top=2,bottom=2}})
        row.icon174=row:CreateTexture(nil,"OVERLAY")
        row.icon174:SetPoint("LEFT",row,"LEFT",8,0) row.icon174:SetWidth(41) row.icon174:SetHeight(41)
        row.name174=Text175(row,"GameFontNormal","",58,-7,324,"LEFT")
        row.description174=Text175(row,"GameFontNormalSmall","",58,-27,335,"LEFT")
        row.description174:SetTextColor(0.66,0.66,0.63)
        row.status174=Text175(row,"GameFontNormalSmall","",399,-9,111,"RIGHT")
        row.date174=Text175(row,"GameFontNormalSmall","",399,-31,111,"RIGHT")
        row:SetScript("OnClick",function()
            if not this.achievement174 then return end
            if IsShiftKeyDown and IsShiftKeyDown() then
                if OTLGM:InsertAchievementLinkInBlizzardChat174(this.achievement174) then return end
                if OTLGM.InsertGuildChatLink then OTLGM:InsertGuildChatLink(OTLGM:GetAchievementLink174(this.achievement174),true) return end
            end
            OTLGM:FocusAchievement174(this.achievement174.id)
        end)
        row:SetScript("OnEnter",function()
            if not this.achievement174 then return end
            this:SetBackdropBorderColor(0.34,0.70,1,1)
            local complete=OTLGM:IsAchievementComplete174(this.achievement174.id)
            local name,description=OTLGM:GetAchievementPresentation174(this.achievement174,complete)
            GameTooltip:SetOwner(this,"ANCHOR_CURSOR") GameTooltip:AddLine(name,1,0.82,0.35) GameTooltip:AddLine(description,1,1,1,true) GameTooltip:AddLine("Shift-click to link",0.52,0.72,1) GameTooltip:Show()
        end)
        row:SetScript("OnLeave",function() GameTooltip:Hide() OTLGM:RefreshAchievements174() end)
        self.ui.achievementRows174[index]=row
    end
    self.ui.achievementPrev174=Button175(list,"Previous",8,-376,82,23,function() OTLGM.ui.achievementOffset174=math.max(0,(OTLGM.ui.achievementOffset174 or 0)-6) OTLGM:RefreshAchievements174() end,"utility")
    self.ui.achievementStatus174=Text175(list,"GameFontNormalSmall","",100,-382,324,"CENTER")
    self.ui.achievementNext174=Button175(list,"Next",432,-376,82,23,function() OTLGM.ui.achievementOffset174=(OTLGM.ui.achievementOffset174 or 0)+6 OTLGM:RefreshAchievements174() end,"utility")
    self.ui.achievementOffset174=0
end

function OTLGM:RefreshAchievements174()
    if not self.ui or not self.ui.achievementRows174 then return end
    local completed,total=self:GetAchievementCount174()
    self.ui.achievementCount174:SetText(tostring(completed).." / "..tostring(total))
    local ratio=total>0 and completed/total or 0
    self.ui.achievementProgressFill174:SetWidth(math.max(1,math.floor(494*ratio)))
    self.ui.achievementProgressText174:SetText(tostring(math.floor(ratio*100)).."% complete")
    local category=OTLGM_DB.settings.achievementCategory174 or "OVERVIEW"
    local filter=OTLGM_DB.settings.achievementFilter174 or "ALL"
    local key,button,index,def
    for key,button in pairs(self.ui.achievementCategoryButtons174 or {}) do
        SelectButton175(button,key==category)
        local cc,ct=0,0
        for index=1,table.getn(A175.catalog) do def=A175.catalog[index] if key=="OVERVIEW" or def.category==key then ct=ct+1 if self:IsAchievementComplete174(def.id) then cc=cc+1 end end end
        if button.countText174 then button.countText174:SetText(tostring(cc).."/"..tostring(ct)) end
    end
    for key,button in pairs(self.ui.achievementFilterButtons174 or {}) do SelectButton175(button,key==filter) end
    SetButtonText175(self.ui.achievementPopupButton174,"Popups: "..(OTLGM_DB.settings.achievementPopups174 and "On" or "Off"))
    SetButtonText175(self.ui.achievementChatButton174,"Guild chat: "..(OTLGM_DB.settings.achievementGuildChat174 and "On" or "Off"))
    SelectButton175(self.ui.achievementPopupButton174,OTLGM_DB.settings.achievementPopups174)
    SelectButton175(self.ui.achievementChatButton174,OTLGM_DB.settings.achievementGuildChat174)

    local list=self:GetAchievementDisplayList174()
    local pageSize=6
    local totalRows=table.getn(list)
    local maximum=math.max(0,math.floor(math.max(0,totalRows-1)/pageSize)*pageSize)
    local offset=math.max(0,math.min(maximum,tonumber(self.ui.achievementOffset174) or 0))
    self.ui.achievementOffset174=offset
    local row,complete,name,description,icon,secret,current,required,when
    -- Reset every recycled row first. This prevents the old page from remaining
    -- below a shorter page or inheriting another achievement's icon.
    for index=1,pageSize do
        row=self.ui.achievementRows174[index]
        row.achievement174=nil
        row.name174:SetText("") row.description174:SetText("") row.status174:SetText("") row.date174:SetText("")
        SetTexture175(row.icon174,SAFE_ICON_175)
        row:Hide()
    end
    for index=1,pageSize do
        row=self.ui.achievementRows174[index]
        def=list[offset+index]
        if def then
            complete=self:IsAchievementComplete174(def.id)
            name,description,icon,secret=self:GetAchievementPresentation174(def,complete)
            current,required=self:GetAchievementProgress174(def)
            when=self:GetAchievementCompletedAt174(def.id)
            row.achievement174=def
            SetTexture175(row.icon174,icon)
            row.name174:SetText(name) row.description174:SetText(description)
            if complete then
                row:SetBackdropColor(0.075,0.052,0.020,0.98) row:SetBackdropBorderColor(0.68,0.44,0.12,1)
                row.icon174:SetVertexColor(1,1,1) row.name174:SetTextColor(1,0.82,0.35)
                row.status174:SetText("COMPLETE") row.status174:SetTextColor(0.35,0.95,0.42)
                row.date174:SetText(when and date("%d %b %Y",when) or "") row.date174:SetTextColor(0.62,0.62,0.60)
            elseif secret then
                row:SetBackdropColor(0.035,0.020,0.050,0.98) row:SetBackdropBorderColor(0.38,0.18,0.52,1)
                row.icon174:SetVertexColor(0.72,0.45,0.94) row.name174:SetTextColor(0.78,0.46,1)
                row.status174:SetText("SECRET") row.status174:SetTextColor(0.78,0.46,1) row.date174:SetText("")
            else
                row:SetBackdropColor(0.025,0.023,0.020,0.98) row:SetBackdropBorderColor(0.24,0.22,0.19,1)
                row.icon174:SetVertexColor(0.40,0.40,0.40) row.name174:SetTextColor(0.72,0.72,0.70)
                row.status174:SetText(required>1 and (tostring(math.floor(current)).." / "..tostring(math.floor(required))) or "LOCKED")
                row.status174:SetTextColor(current>0 and 1 or 0.72,current>0 and 0.78 or 0.72,current>0 and 0.18 or 0.68)
                row.date174:SetText("")
            end
            if self.ui.achievementFocus174==def.id then row:SetBackdropBorderColor(0.30,0.72,1,1) end
            row:Show()
        end
    end
    if totalRows==0 then self.ui.achievementStatus174:SetText("No achievements match this view.")
    else self.ui.achievementStatus174:SetText(tostring(offset+1).."-"..tostring(math.min(offset+pageSize,totalRows)).." of "..tostring(totalRows)) end
    if self.SetControlEnabled170 then
        self:SetControlEnabled170(self.ui.achievementPrev174,offset>0,"This is the first page.")
        self:SetControlEnabled170(self.ui.achievementNext174,offset+pageSize<totalRows,"There are no more achievements.")
        if self.ApplyButtonSkin then self:ApplyButtonSkin(self.ui.achievementPrev174) self:ApplyButtonSkin(self.ui.achievementNext174) end
    end
end

-- ---------------------------------------------------------------------------
-- Completion meta and low-cost progress trackers
-- ---------------------------------------------------------------------------

local BaseComplete175 = OTLGM.CompleteAchievement174
local metaGuard175 = false

local function CheckMetaAchievements175(self, silent)
    if metaGuard175 then return end
    metaGuard175 = true
    local db = self:EnsureAchievements174()
    local total = self:GetAchievementCount174()
    db.counters.achievementCount = total
    if total >= 25 then BaseComplete175(self,"B078",silent) end
    local needed = { SOCIAL=true, GROUP_FINDER=true, PROFESSIONS=true, DUNGEONS=true, RAIDS=true, LEGACY=true, SECRETS=true }
    local covered = {}
    local id, record, def
    for id,record in pairs(db.completed or {}) do
        def=A175.byId[id]
        if def and id~="B077" and needed[def.category] then covered[def.category]=true end
    end
    local count=0 local key
    for key in pairs(needed) do if covered[key] then count=count+1 end end
    db.counters.categoryCoverage175=count
    if count>=7 then BaseComplete175(self,"B077",silent) end
    metaGuard175=false
end

function OTLGM:CompleteAchievement174(id,silent)
    local changed=BaseComplete175(self,id,silent)
    if changed then CheckMetaAchievements175(self,silent) end
    return changed
end

local function CheckFullPartyComposition175(self,silent)
    local group,full=FullGuildParty175(self)
    if not full then
        self:SetAchievementCounter174("fullFiveClasses",0)
        self:SetAchievementCounter174("fullFiveRanks",0)
        self:SetAchievementCounter174("fullFiveRaces",0)
        self:SetAchievementCounter174("sameRaceParty",0)
        return group,false
    end
    local classes=Count175(group.classes)
    local ranks={}
    local index,member
    for index=1,table.getn(group.guildMembers) do member=group.guildMembers[index] ranks[Key175(member.rank)]=true end
    local races,same=GroupRaceData175(group)
    self:SetAchievementCounter174("fullFiveClasses",classes)
    self:SetAchievementCounter174("fullFiveRanks",Count175(ranks))
    self:SetAchievementCounter174("fullFiveRaces",Count175(races))
    self:SetAchievementCounter174("sameRaceParty",same and 5 or 0)
    if classes>=5 then self:CompleteAchievement174("B047",silent) end
    if Count175(ranks)>=5 then self:CompleteAchievement174("B048",silent) end
    if Count175(races)>=5 then self:CompleteAchievement174("B051",silent) end
    if same then self:CompleteAchievement174("B052",silent) end
    return group,true
end

local function PresentPartners175(self,group)
    local result={}
    local player=NameKey175(PlayerName175())
    local index,member
    -- Long Watch and Reunion Tour are group-membership achievements, not
    -- proximity achievements. A synchronized zone transition must not reset them.
    for index=1,table.getn(group and group.guildMembers or {}) do
        member=group.guildMembers[index]
        if member.key~=player and (not UnitIsConnected or UnitIsConnected(member.unit)) then result[member.key]=member end
    end
    return result
end

local function UpdateLongWatch175(self,group,silent)
    self.runtime=self.runtime or {}
    local now=self:Now()
    local partners=PresentPartners175(self,group)
    local watches=self.runtime.longWatch175 or {}
    self.runtime.longWatch175=watches
    local key,member
    for key,member in pairs(partners) do
        if not watches[key] then watches[key]={started=now,name=member.name} end
        local elapsed=now-(watches[key].started or now)
        local achievementDB=self:EnsureAchievements174()
        if elapsed>(tonumber(achievementDB.counters.longWatchSeconds) or 0) then self:SetAchievementCounter174("longWatchSeconds",elapsed) end
        if elapsed>=7200 then self:CompleteAchievement174("B049",silent) end
    end
    for key in pairs(watches) do if not partners[key] then watches[key]=nil end end
end

local function UpdateReunion175(self,group,silent)
    self.runtime=self.runtime or {}
    local signature=PartySignature175(group)
    if self.runtime.reunionSignature175==signature then return end
    self.runtime.reunionSignature175=signature
    local db=self:EnsureAchievements174()
    local last=EnsureMap175(db.dates,"partnerLastSession175")
    local now=self:Now()
    local partners=PresentPartners175(self,group)
    local key
    for key in pairs(partners) do
        local previous=tonumber(last[key]) or 0
        if previous>0 and now-previous>=90*86400 then self:CompleteAchievement174("B050",silent) end
        last[key]=now
    end
    -- Bound the map to the roster size plus a small safety margin.
    if Count175(last)>MAX_NAMES_175 then
        local rows={} local value
        for key,value in pairs(last) do table.insert(rows,{key=key,ts=tonumber(value) or 0}) end
        table.sort(rows,function(a,b) return a.ts>b.ts end)
        local i for i=MAX_NAMES_175+1,table.getn(rows) do last[rows[i].key]=nil end
    end
end

local function LocalGroupState175(self,group)
    local state={ fishing=self.runtime and self.runtime.fishing175 and true or false, resting=IsResting and IsResting() and true or false, tabard=false, zone=CurrentPlace175(self), signature=PartySignature175(group) }
    if GetInventoryItemLink and GetInventoryItemLink("player",19) then state.tabard=true
    elseif GetInventoryItemTexture and GetInventoryItemTexture("player",19) then state.tabard=true end
    return state
end

function OTLGM:QueueReleaseState175(kind,value,signature,zone,target)
    if not self.QueueNetworkPayload or not target or target=="" then return false end
    local payload=table.concat({"F1","STATE",tostring(kind or ""),tostring(value or "0"),tostring(signature or ""),tostring(zone or ""),tostring(self:Now())},"^")
    return self:QueueNetworkPayload(payload,"WHISPER",target,1,"release175","F1STATE:"..NameKey175(target)..":"..tostring(kind))
end

local function BroadcastGroupState175(self,group,force)
    if not group or not group.isParty then return end
    self.runtime=self.runtime or {}
    local state=LocalGroupState175(self,group)
    local encoded=(state.fishing and "1" or "0")..(state.resting and "1" or "0")..(state.tabard and "1" or "0")..":"..state.signature..":"..state.zone
    if not force and self.runtime.lastLocalState175==encoded then return end
    self.runtime.lastLocalState175=encoded
    local index,member
    for index=1,table.getn(group.guildMembers or {}) do
        member=group.guildMembers[index]
        if not IsPlayer175(member.name) then
            self:QueueReleaseState175("GROUP",(state.fishing and "F" or "-")..(state.resting and "R" or "-")..(state.tabard and "T" or "-"),state.signature,state.zone,member.name)
        end
    end
end

local function CheckFullPartySharedStates175(self,group,silent)
    local _,full=FullGuildParty175(self)
    if not full then
        self:SetAchievementCounter174("fishingPartyNow175",0)
        self.runtime.regularTable175=nil
        return
    end
    local now=self:Now()
    local signature=PartySignature175(group)
    local zone=CurrentPlace175(self)
    local localState=LocalGroupState175(self,group)
    local stateMap=self.runtime and self.runtime.groupStates175 or {}
    local fishing=localState.fishing and 1 or 0
    local resting=localState.resting and 1 or 0
    local tabards=localState.tabard and 1 or 0
    local index,member,remote
    for index=1,table.getn(group.guildMembers) do
        member=group.guildMembers[index]
        if not IsPlayer175(member.name) then
            remote=stateMap[member.key]
            if remote and now-(remote.ts or 0)<=120 and remote.signature==signature and remote.zone==zone then
                if remote.fishing then fishing=fishing+1 end
                if remote.resting then resting=resting+1 end
                if remote.tabard then tabards=tabards+1 end
            end
        end
    end
    self:SetAchievementCounter174("fishingPartyNow175",fishing)
    self:SetAchievementCounter174("uniformPartyNow175",tabards)
    if fishing>=5 then self:CompleteAchievement174("B074",silent) end
    if resting>=5 then
        local state=self.runtime.regularTable175
        if not state or state.signature~=signature or state.zone~=zone then state={signature=signature,zone=zone,started=now} self.runtime.regularTable175=state end
        local elapsed=now-(state.started or now)
        self:SetAchievementCounter174("regularTableSeconds",elapsed)
        if elapsed>=600 then self:CompleteAchievement174("B053",silent) end
    else self.runtime.regularTable175=nil self:SetAchievementCounter174("regularTableSeconds",0) end
end

local function CheckDiplomaticIncident175(self,silent)
    -- UNIT_HEALTH can be noisy. Outside an enemy capital this path must stay a
    -- constant-time no-op and must not rebuild the party snapshot.
    if self:IsAchievementComplete174("B075") then return end
    local faction=UnitFactionGroup and UnitFactionGroup("player") or ""
    local hostile=HOSTILE_CAPITALS_175[faction]
    if not hostile then return end
    local zone=CurrentZone175(self)
    local subzone=CurrentSubzone175(self)
    if not hostile[zone] and not hostile[subzone] then return end
    local group,full=FullGuildParty175(self)
    if not full then return end
    local index,member
    for index=1,table.getn(group.guildMembers) do
        member=group.guildMembers[index]
        if not UnitIsDeadOrGhost or not UnitIsDeadOrGhost(member.unit) then return end
    end
    self:CompleteAchievement174("B075",silent)
end

local BaseUpdateGroupSession175=OTLGM.UpdateGroupSession174
function OTLGM:UpdateGroupSession174(silent)
    local group=BaseUpdateGroupSession175(self,silent)
    CheckFullPartyComposition175(self,silent)
    UpdateLongWatch175(self,group,silent)
    UpdateReunion175(self,group,silent)
    BroadcastGroupState175(self,group,false)
    CheckFullPartySharedStates175(self,group,silent)
    CheckDiplomaticIncident175(self,silent)
    return group
end

function OTLGM:HandleRelease175Message(message,channel,sender)
    local fields=self:Split(message or "","^")
    if fields[1]~="F1" then return false end
    local kind=fields[2]
    if kind=="STATE" then
        local stateKind=fields[3] or ""
        local value=fields[4] or ""
        local signature=fields[5] or ""
        local zone=fields[6] or ""
        local ts=tonumber(fields[7]) or 0
        if stateKind=="GROUP" and ts>0 and math.abs(self:Now()-ts)<=180 and self:IsKnownGuildSender(sender) then
            local group=self:GetGroupSnapshot174()
            local memberFound=false local index,member
            for index=1,table.getn(group.guildMembers or {}) do member=group.guildMembers[index] if member.key==NameKey175(sender) then memberFound=true break end end
            if not memberFound then return false end
            self.runtime=self.runtime or {} self.runtime.groupStates175=self.runtime.groupStates175 or {}
            self.runtime.groupStates175[NameKey175(sender)]={fishing=string.find(value,"F",1,true)~=nil,resting=string.find(value,"R",1,true)~=nil,tabard=string.find(value,"T",1,true)~=nil,signature=signature,zone=zone,ts=ts}
            CheckFullPartySharedStates175(self,group,false)
            return true
        elseif stateKind=="SALUTE" and ts>0 and math.abs(self:Now()-ts)<=300 then
            self:RecordProudLionSalute175(sender,signature,zone,ts)
            return true
        end
    elseif kind=="REVIVE" then
        local target=ShortName175(fields[3] or "")
        local zone=fields[4] or ""
        local ts=tonumber(fields[5]) or 0
        if IsPlayer175(target) and math.abs(self:Now()-ts)<=180 and self:IsKnownGuildSender(sender) then
            local dungeon=IsDungeon175(self)
            if dungeon and CurrentZone175(self)==zone then
                self.runtime=self.runtime or {}
                self.runtime.revivedByGuild175={sender=ShortName175(sender),ts=ts,zone=zone}
            end
            return true
        end
    end
    return false
end

function OTLGM:RecordProudLionSalute175(sender,signature,zone,ts)
    local group,full=FullGuildParty175(self)
    if not full or not IsLocation175(self,"goldshire") or signature~=PartySignature175(group) or zone~="goldshire" then return false end
    self.runtime=self.runtime or {}
    local state=self.runtime.proudLion175
    if not state or state.signature~=signature or state.zone~=zone then state={signature=signature,zone=zone,names={}} self.runtime.proudLion175=state end
    local key=NameKey175(sender)
    local valid=false local index,member
    for index=1,table.getn(group.guildMembers) do member=group.guildMembers[index] if member.key==key then valid=true break end end
    if valid then state.names[key]=true end
    self:SetAchievementCounter174("proudLion",Count175(state.names))
    if Count175(state.names)>=5 then self:CompleteAchievement174("B083",false) end
    return valid
end

-- ---------------------------------------------------------------------------
-- Shared boss tracker consumers
-- ---------------------------------------------------------------------------

local BaseStartBoss175=OTLGM.StartBossEncounter174
local BaseMarkBossDeath175=OTLGM.MarkBossEncounterDeath174
local BaseBossVictory175=OTLGM.HandleBossVictory174

local function EncounterKey175(self,bossName)
    return CurrentZone175(self)..":"..Key175(bossName)
end

function OTLGM:StartBossEncounter174(bossName)
    local accepted=BaseStartBoss175(self,bossName)
    if not accepted then return false end
    self.runtime=self.runtime or {}
    self.runtime.bossAttempts175=self.runtime.bossAttempts175 or {}
    local key=EncounterKey175(self,bossName)
    local attempts=self.runtime.bossAttempts175[key] or {count=0,failedPrevious=false,last=0}
    local now=self:Now()
    local active=self.runtime.bossEncounter175
    if not active or active.key~=key or not active.active then
        attempts.count=(tonumber(attempts.count) or 0)+1
        attempts.last=now
        self.runtime.bossAttempts175[key]=attempts
        self.runtime.bossEncounter175={key=key,boss=Key175(bossName),zone=CurrentZone175(self),started=now,active=true,deaths={},deathCount=0,attempt=attempts.count,failedPrevious=attempts.failedPrevious,group=self:GetGroupSnapshot174()}
    end
    return true
end

function OTLGM:MarkBossEncounterDeath174(name)
    BaseMarkBossDeath175(self,name)
    local state=self.runtime and self.runtime.bossEncounter175
    if not state or not state.active then return end
    local key=NameKey175(name)
    if key~="" and not state.deaths[key] then state.deaths[key]=true state.deathCount=(state.deathCount or 0)+1 end
end

function OTLGM:MarkBossAttemptFailed175()
    local state=self.runtime and self.runtime.bossEncounter175
    if not state or not state.active then return false end
    if self:Now()-(state.started or self:Now())<5 then state.active=false return false end
    local attempts=self.runtime.bossAttempts175 and self.runtime.bossAttempts175[state.key]
    if attempts then attempts.failedPrevious=true attempts.last=self:Now() end
    state.active=false
    return true
end

local function GetPresentMembers175(self,group)
    if self.GetPresentGuildMembers174 then return self:GetPresentGuildMembers174(group) end
    return group and group.guildMembers or {}
end

local function LevelGap175(self,group)
    local members=GetPresentMembers175(self,group)
    local low,high=nil,nil
    local index,member,level
    for index=1,table.getn(members) do
        member=members[index] level=tonumber(UnitLevel and UnitLevel(member.unit)) or tonumber(member.level) or 0
        if level>0 then if not low or level<low then low=level end if not high or level>high then high=level end end
    end
    return low and high and high-low or 0
end

local function GroupHasLeader175(self,group)
    local leader=NameKey175(GetGuildLeader175(self))
    if leader=="" then return false end
    local members=GetPresentMembers175(self,group)
    local index
    for index=1,table.getn(members) do if members[index].key==leader then return true end end
    return false
end

local function LocalTabard175()
    if GetInventoryItemLink and GetInventoryItemLink("player",19) then return true end
    if GetInventoryItemTexture and GetInventoryItemTexture("player",19) then return true end
    return false
end

local function FullPartyTabards175(self,group)
    if not group or not group.isParty or group.total~=5 or group.guild~=5 then return false end
    local count=LocalTabard175() and 1 or 0
    local signature=PartySignature175(group)
    local zone=CurrentPlace175(self)
    local now=self:Now()
    local states=self.runtime and self.runtime.groupStates175 or {}
    local index,member,state,link
    for index=1,table.getn(group.guildMembers) do
        member=group.guildMembers[index]
        if not IsPlayer175(member.name) then
            link=GetInventoryItemLink and GetInventoryItemLink(member.unit,19)
            if not link and GetInventoryItemTexture then link=GetInventoryItemTexture(member.unit,19) end
            if link then count=count+1 else
                state=states[member.key]
                if state and state.tabard and state.signature==signature and state.zone==zone and now-(state.ts or 0)<=120 then count=count+1 end
            end
        end
    end
    return count>=5
end

local function HoldingFishingPole175()
    if not GetInventoryItemLink then return false end
    local link=GetInventoryItemLink("player",16)
    if not link then return false end
    if GetItemInfo then
        local _,_,_,_,_,itemType,itemSubType=GetItemInfo(link)
        local key=Key175(itemSubType or itemType)
        if FISHING_POLE_TYPES_175[key] or string.find(key,"fishingpole",1,true) then return true end
    end
    return string.find(string.lower(link),"fishing",1,true)~=nil
end

local function FreeBagSlots175()
    local free=0
    local bag,slots,index
    for bag=0,4 do
        if GetContainerNumFreeSlots then
            local ok,value=pcall(GetContainerNumFreeSlots,bag)
            if ok and tonumber(value) then free=free+tonumber(value) end
        elseif GetContainerNumSlots and GetContainerItemLink then
            slots=tonumber(GetContainerNumSlots(bag)) or 0
            for index=1,slots do if not GetContainerItemLink(bag,index) then free=free+1 end end
        end
    end
    return free
end

local function HasBrokenEquipment175()
    if not GetInventoryItemDurability then return false end
    local slot,current,maximum
    for slot=1,19 do
        current,maximum=GetInventoryItemDurability(slot)
        if tonumber(maximum) and maximum>0 and tonumber(current)==0 then return true end
    end
    return false
end

local function IsFinalDungeonBoss175(bossKey)
    if FINAL_DUNGEON_BOSSES_175[bossKey] then return true end
    local endings={"vancleef","rivendare","gandling","drakkisath","theradras","whitemane","arugal","mutanus","akumai","gordok","thaurissan"}
    local index
    for index=1,table.getn(endings) do if string.find(bossKey,endings[index],1,true) then return true end end
    return false
end

local function RecordSameCrewDungeon175(self,group,zone)
    local db=self:EnsureAchievements174()
    local signatures=EnsureMap175(db,"sameCrewDungeons175")
    local updated=EnsureMap175(db.dates,"sameCrewUpdated175")
    local signature=PartySignature175(group)
    if signature=="" then return 0 end
    local now=self:Now()
    if updated[signature] and now-(tonumber(updated[signature]) or 0)>30*86400 then signatures[signature]={} end
    if type(signatures[signature])~="table" then signatures[signature]={} end
    signatures[signature][zone]=true
    updated[signature]=now
    local count=Count175(signatures[signature])
    if count>(tonumber(db.counters.sameCrewBest175) or 0) then db.counters.sameCrewBest175=count end
    if count>=3 then self:CompleteAchievement174("B062",false) end
    return count
end

function OTLGM:HandleBossVictory174(bossName)
    local releaseState=self.runtime and self.runtime.bossEncounter175
    local group=releaseState and releaseState.group or self:GetGroupSnapshot174()
    local bossKey=Key175(bossName)
    local dungeon,_,zone=IsDungeon175(self)
    local raid=IsRaid175(self)
    local accepted=BaseBossVictory175(self,bossName)
    if not accepted then return false end
    local db=self:EnsureAchievements174()
    if dungeon then
        if LevelGap175(self,group)>=20 then self:CompleteAchievement174("B054",false) end
        if GroupHasLeader175(self,group) then self:CompleteAchievement174("B058",false) end
        if releaseState and releaseState.attempt==2 and releaseState.failedPrevious and (releaseState.deathCount or 0)==0 then self:CompleteAchievement174("B061",false) end
        if releaseState and releaseState.attempt==3 then self:CompleteAchievement174("B067",false) end
        if group.isParty and group.total==5 and group.guild==5 then
            if FullPartyTabards175(self,group) then self:CompleteAchievement174("B063",false) end
            if IsFinalDungeonBoss175(bossKey) then
                local completions=self:AddAchievementCounter174("fullGuildDungeonCompletions",1)
                if completions>=5 then self:CompleteAchievement174("B070",false) end
                if completions>=15 then self:CompleteAchievement174("B071",false) end
                if completions>=30 then self:CompleteAchievement174("B072",false) end
                RecordSameCrewDungeon175(self,group,zone or CurrentZone175(self))
            end
        end
        if HoldingFishingPole175() then self:CompleteAchievement174("B064",false) end
        if FreeBagSlots175()==0 then self:CompleteAchievement174("B065",false) end
        if HasBrokenEquipment175() then self:CompleteAchievement174("B066",false) end
        if self.runtime and self.runtime.revivedByGuild175 and not (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")) then self:CompleteAchievement174("B069",false) end
        if self.runtime then self.runtime.revivedByGuild175=nil end
    elseif raid then
        local classes={}
        local members=GetPresentMembers175(self,group)
        local index,member
        for index=1,table.getn(members) do member=members[index] if BASE_CLASSES_175[string.upper(member.class or "")] then classes[string.upper(member.class)]=true end end
        self:SetAchievementCounter174("allNineRaid",Count175(classes))
        if Count175(classes)>=9 then self:CompleteAchievement174("B073",false) end
    end
    if releaseState then
        local attempts=self.runtime.bossAttempts175 and self.runtime.bossAttempts175[releaseState.key]
        if attempts then attempts.failedPrevious=false attempts.count=0 attempts.last=self:Now() end
    end
    if self.runtime then self.runtime.bossEncounter175=nil end
    return true
end

-- ---------------------------------------------------------------------------
-- Duels, emotes, crafting, riding, loot and resurrection
-- ---------------------------------------------------------------------------

local function FindGroupUnitByName175(name)
    local wanted=NameKey175(name)
    if wanted==NameKey175(PlayerName175()) then return "player" end
    local raid=GetNumRaidMembers and (tonumber(GetNumRaidMembers()) or 0) or 0
    local party=GetNumPartyMembers and (tonumber(GetNumPartyMembers()) or 0) or 0
    local index,unit
    if raid>0 then
        for index=1,raid do unit="raid"..tostring(index) if NameKey175(UnitName(unit))==wanted then return unit end end
    else
        for index=1,party do unit="party"..tostring(index) if NameKey175(UnitName(unit))==wanted then return unit end end
    end
    if UnitName and NameKey175(UnitName("target"))==wanted then return "target" end
    return nil
end

function OTLGM:BeginDuel175(opponent)
    opponent=ShortName175(opponent or (UnitName and UnitName("target")) or "")
    if opponent=="" then return end
    local unit=FindGroupUnitByName175(opponent) or "target"
    local _,classToken=UnitClass and UnitClass(unit)
    self.runtime=self.runtime or {}
    self.runtime.duel175={opponent=opponent,key=NameKey175(opponent),guild=IsGuildMember175(self,opponent),leader=NameKey175(opponent)==NameKey175(GetGuildLeader175(self)),class=string.upper(tostring(classToken or "")),started=self:Now(),cancelled=false}
end

function OTLGM:FinishDuel175(cancelled)
    local duel=self.runtime and self.runtime.duel175
    if not duel then return false end
    self.runtime.duel175=nil
    if cancelled or duel.cancelled or not duel.guild or not IsGuildMember175(self,duel.opponent) then return false end
    local health=UnitHealth and tonumber(UnitHealth("player")) or 1
    local maximum=UnitHealthMax and tonumber(UnitHealthMax("player")) or 1
    local lost=maximum>0 and health/maximum<=0.025
    local won=not lost
    local db=self:EnsureAchievements174()
    local records=EnsureMap175(db,"duels175")
    if type(records[duel.key])~="table" then records[duel.key]={} end
    if won then records[duel.key].won=true else records[duel.key].lost=true end
    if won and duel.leader then self:CompleteAchievement174("B056",false) end
    if lost and duel.leader then self:CompleteAchievement174("B057",false) end
    if records[duel.key].won and records[duel.key].lost then self:CompleteAchievement174("B059",false) end
    if won and BASE_CLASSES_175[duel.class] then
        AddSet175(self,"duelClasses",duel.class,16)
        if Count175(self:GetAchievementSet174("duelClasses"))>=9 then self:CompleteAchievement174("B060",false) end
    end
    return true
end

local function HandleLocalEmote175(self,token)
    token=string.upper(tostring(token or ""))
    local target=ShortName175(UnitName and UnitName("target") or "")
    local leader=GetGuildLeader175(self)
    if token=="SALUTE" and target~="" and NameKey175(target)==NameKey175(leader) then self:CompleteAchievement174("B055",false) end
    if token=="BONK" and target~="" and NameKey175(target)==NameKey175(leader) then self:CompleteAchievement174("B086",false) end
    if token=="MOON" then
        local hour=0
        if GetGameTime then hour=tonumber((GetGameTime())) or 0 else hour=tonumber(date("%H")) or 0 end
        local group=self:GetGroupSnapshot174()
        if (hour>=22 or hour<4) and group.guild>=2 then self:CompleteAchievement174("B082",false) end
    end
    if (token=="JOKE" or token=="RUDE") and DRAGON_TARGETS_175[Key175(target)] then self:CompleteAchievement174("B084",false) end
    if token=="SALUTE" then
        local group,full=FullGuildParty175(self)
        if full and IsLocation175(self,"goldshire") then
            local signature=PartySignature175(group)
            self:RecordProudLionSalute175(PlayerName175(),signature,"goldshire",self:Now())
            local index,member
            for index=1,table.getn(group.guildMembers) do member=group.guildMembers[index] if not IsPlayer175(member.name) then self:QueueReleaseState175("SALUTE","1",signature,"goldshire",member.name) end end
        end
    end
end

function OTLGM:InstallEmoteHook175()
    if R175.emoteHooked or type(DoEmote)~="function" then return end
    R175.emoteHooked=true
    local original=DoEmote
    DoEmote=function(token, target)
        local result=original(token, target)
        if OTLGM and OTLGM.release175 then pcall(HandleLocalEmote175,OTLGM,token) end
        return result
    end
end

local function IsGuildTabardEquipped175(self)
    if not GetInventoryItemLink or not GetGuildInfo or not GetGuildInfo("player") then return false end
    local link=GetInventoryItemLink("player",19)
    if not link or link=="" then return false end
    local _,_,itemId=string.find(link,"item:(%d+)")
    if tonumber(itemId)==5976 then return true end
    if GetItemInfo then
        local name=GetItemInfo(link)
        local lowered=string.lower(tostring(name or ""))
        if string.find(lowered,"guild tabard",1,true) or string.find(lowered,"guildtabard",1,true) then return true end
    end
    return false
end

local function CheckUnderBanner175(self,silent)
    if self:IsAchievementComplete174("UNDER_BANNER") then return true end
    if IsGuildTabardEquipped175(self) then return self:CompleteAchievement174("UNDER_BANNER",silent) end
    return false
end

local function ScanRiding175(self,silent)
    local best,cap=0,0
    if GetNumSkillLines and GetSkillLineInfo then
        local total=tonumber(GetNumSkillLines()) or 0
        local index,name,_,_,rank,_,maximum
        for index=1,total do
            name,_,_,rank,_,maximum=GetSkillLineInfo(index)
            if string.find(string.lower(tostring(name or "")),"riding",1,true) then
                best=math.max(best,tonumber(rank) or 0)
                cap=math.max(cap,tonumber(maximum) or 0)
            end
        end
    end
    -- Fallback spell checks for Vanilla clients that expose riding only as spells.
    if best==0 and GetSpellName then
        local bookIndex=1 local spellName,spellRank
        while bookIndex<=500 do
            spellName,spellRank=GetSpellName(bookIndex,BOOKTYPE_SPELL)
            if not spellName then break end
            if string.find(string.lower(spellName),"riding",1,true) then
                local _, _, digits=string.find(tostring(spellRank or ""),"(%d+)")
                local numeric=tonumber(digits) or 1
                best=math.max(best,numeric) cap=math.max(cap,numeric)
            end
            bookIndex=bookIndex+1
        end
    end
    local db=self:EnsureAchievements174()
    db.counters.ridingSkill175=best
    db.counters.ridingCap175=cap
    if best>0 then self:CompleteAchievement174("B080",silent) end
    if best>0 and cap>0 and best>=cap then self:CompleteAchievement174("B081",silent) end
end

function OTLGM:InstallCraftHooks175()
    if R175.craftHooked then return end
    R175.craftHooked=true
    if type(DoTradeSkill)=="function" then
        local original=DoTradeSkill
        DoTradeSkill=function(index,count)
            if OTLGM then OTLGM.runtime=OTLGM.runtime or {} OTLGM.runtime.pendingCraft175={ts=OTLGM:Now(),kind="TRADE"} end
            return original(index,count)
        end
    end
    if type(Craft)=="function" then
        local original=Craft
        Craft=function(index)
            if OTLGM then OTLGM.runtime=OTLGM.runtime or {} OTLGM.runtime.pendingCraft175={ts=OTLGM:Now(),kind="CRAFT"} end
            return original(index)
        end
    end
end

function OTLGM:ConfirmCraftAction175(kind)
    local pending=self.runtime and self.runtime.pendingCraft175
    if not pending or pending.kind~=kind or self:Now()-(pending.ts or 0)>10 then return false end
    self.runtime.pendingCraft175=nil
    local count=self:AddAchievementCounter174("craftActions",1)
    if count>=500 then self:CompleteAchievement174("B079",false) end
    return true
end

local RESURRECTION_NAMES_175={resurrection=true,redemption=true,ancestralspirit=true,rebirth=true}
function OTLGM:BeginResurrection175(spellName)
    if not RESURRECTION_NAMES_175[Key175(spellName)] then return end
    local target=ShortName175(UnitName and UnitName("target") or "")
    if target=="" or not IsGuildMember175(self,target) or not UnitIsDeadOrGhost or not UnitIsDeadOrGhost("target") then return end
    self.runtime=self.runtime or {}
    self.runtime.resurrection175={target=target,key=NameKey175(target),started=self:Now(),zone=CurrentZone175(self)}
end

function OTLGM:CheckResurrection175()
    local state=self.runtime and self.runtime.resurrection175
    if not state or self:Now()-(state.started or 0)>20 then if self.runtime then self.runtime.resurrection175=nil end return false end
    local unit=FindGroupUnitByName175(state.target)
    if not unit or (UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit)) then return false end
    self.runtime.resurrection175=nil
    AddSet175(self,"resurrectedGuild",state.key,MAX_NAMES_175)
    if Count175(self:GetAchievementSet174("resurrectedGuild"))>=25 then self:CompleteAchievement174("B068",false) end
    if self.QueueNetworkPayload then
        local payload=table.concat({"F1","REVIVE",state.target,state.zone,tostring(self:Now()),tostring(self:Now())..":"..state.key},"^")
        self:QueueNetworkPayload(payload,"WHISPER",state.target,1,"release175","F1REVIVE:"..state.key)
    end
    return true
end

local function LootFormatMatches175(message, formatText)
    if type(formatText)~="string" or formatText=="" then return false end
    local pattern=string.gsub(formatText,"([%(%)%.%%%+%-%*%?%[%]%^%$])","%%%1")
    pattern=string.gsub(pattern,"%%%%s",".-")
    pattern=string.gsub(pattern,"%%%%d","%%d+")
    return string.find(message,"^"..pattern.."$")~=nil
end

local function IsSelfLootMessage175(message)
    message=tostring(message or "")
    local formats={
        getglobal and getglobal("LOOT_ITEM_SELF") or nil,
        getglobal and getglobal("LOOT_ITEM_SELF_MULTIPLE") or nil,
        getglobal and getglobal("LOOT_ITEM_CREATED_SELF") or nil,
        getglobal and getglobal("LOOT_ITEM_CREATED_SELF_MULTIPLE") or nil,
    }
    local index
    for index=1,table.getn(formats) do if LootFormatMatches175(message,formats[index]) then return true end end
    local lowered=string.lower(message)
    return string.find(lowered,"you receive loot:",1,true)==1
        or string.find(lowered,"you receive item:",1,true)==1
        or string.find(lowered,"you receive:",1,true)==1
        or string.find(lowered,"you loot ",1,true)==1
end

local function ExtractItemLink175(message)
    message=tostring(message or "")
    local startAt=string.find(message,"|Hitem:",1,true)
    if not startAt then return nil end
    local firstEnd=string.find(message,"|h",startAt,true)
    if not firstEnd then return nil end
    local secondEnd=string.find(message,"|h",firstEnd+2,true)
    if not secondEnd then return nil end
    return string.sub(message,startAt,secondEnd+1)
end

local function CheckEpicLoot175(self,message)
    local group,full=FullGuildParty175(self)
    if not full or not IsSelfLootMessage175(message) then return end
    local link=ExtractItemLink175(message)
    if not link or not GetItemInfo then return end
    local _,_,quality=GetItemInfo(link)
    if tonumber(quality)==4 then self:CompleteAchievement174("B076",false) end
end

local function TrackRabbitTarget175(self)
    self.runtime=self.runtime or {}
    local name=UnitName and UnitName("target") or ""
    local creature=UnitCreatureType and UnitCreatureType("target") or ""
    local key=Key175(name)
    if RABBIT_NAMES_175[key] or (string.lower(tostring(creature))=="critter" and (string.find(key,"rabbit",1,true) or string.find(key,"hare",1,true))) then
        self.runtime.rabbitTarget175={name=name,key=key,ts=self:Now(),hit=false}
    else self.runtime.rabbitTarget175=nil end
end

local function MarkRabbitHit175(self,text)
    local state=self.runtime and self.runtime.rabbitTarget175
    if not state or self:Now()-(state.ts or 0)>30 then return end
    if string.find(string.lower(tostring(text or "")),string.lower(state.name),1,true) then state.hit=true state.hitAt=self:Now() end
end

local function CheckRabbitDeath175(self,text)
    local state=self.runtime and self.runtime.rabbitTarget175
    if not state or not state.hit or self:Now()-(state.hitAt or 0)>15 then return end
    if string.find(string.lower(tostring(text or "")),string.lower(state.name),1,true) then self:CompleteAchievement174("B085",false) self.runtime.rabbitTarget175=nil end
end

-- ---------------------------------------------------------------------------
-- Guild Chat layout, reaction dedupe and page polish
-- ---------------------------------------------------------------------------

local BaseCaptureGuildChat175=OTLGM.CaptureGuildChatMessage
local function Utf8Length175(text)
    text=tostring(text or "")
    local count=0 local index=1 local byte
    while index<=string.len(text) do
        byte=string.byte(text,index) or 0
        if byte<128 then index=index+1 elseif byte<224 then index=index+2 elseif byte<240 then index=index+3 else index=index+4 end
        count=count+1
    end
    return count
end

function OTLGM:GetGuildChatLineCount(text)
    local visible=self:GetGuildChatVisibleText(text)
    local length=Utf8Length175(visible)
    local perLine=self:GetGuildChatChannel()=="OFFICER" and 24 or 38
    local lines=math.ceil(length/perLine)
    if lines<1 then lines=1 end
    -- Do not truncate layout accounting. Long messages may use additional rows,
    -- but the list still renders only the currently visible slice.
    if lines>12 then lines=12 end
    return lines
end

function OTLGM:GetGuildChatRowMetrics(messages,index,markerIndex)
    local info=messages[index]
    if not info then return 27,1,nil,false end
    local lines=self:GetGuildChatLineCount(info.text or "")
    local separator=self:GetGuildChatTimeSeparator(messages,index)
    local marker=markerIndex and markerIndex==index
    local height=11+(lines*17)
    if separator then height=height+18 end
    if marker then height=height+10 end
    if height<29 then height=29 end
    return height,lines,separator,marker
end

function OTLGM:CaptureGuildChatMessage(channel,message,sender)
    channel=channel=="OFFICER" and "OFFICER" or "GUILD"
    local clean=Trim175(string.gsub(tostring(message or ""),"[\r\n]"," "))
    local from=Trim175(sender or "Unknown")
    if clean=="" then return end
    self.runtime=self.runtime or {}
    self.runtime.recentGuildCapture175=self.runtime.recentGuildCapture175 or {}
    local key=channel.."|"..NameKey175(from).."|"..self:NormalizeText(clean)
    local now=self:Now()
    local previous=tonumber(self.runtime.recentGuildCapture175[key]) or 0
    if now-previous<=3 then return end
    self.runtime.recentGuildCapture175[key]=now
    local oldKey,oldTs,count=nil,nil,0
    for oldKey,oldTs in pairs(self.runtime.recentGuildCapture175) do
        count=count+1
        if now-(tonumber(oldTs) or 0)>12 then self.runtime.recentGuildCapture175[oldKey]=nil end
    end
    if count>80 then self.runtime.recentGuildCapture175={} self.runtime.recentGuildCapture175[key]=now end
    return BaseCaptureGuildChat175(self,channel,clean,from)
end

local BaseUsefulActivity175=OTLGM.AddUsefulActivity152
function OTLGM:AddUsefulActivity152(kind,title,detail,targetPage,timestamp,eventKey)
    if tostring(kind)=="REACTION" then
        local db=self:GetGuildDB()
        local canonical=tostring(eventKey or "")
        if db and type(db.recentUsefulActivity)=="table" then
            local fallback=self:NormalizeText(tostring(kind).."|"..tostring(title).."|"..tostring(detail).."|"..tostring(targetPage))
            local index,entry,oldFingerprint
            for index=1,table.getn(db.recentUsefulActivity) do
                entry=db.recentUsefulActivity[index]
                if type(entry)=="table" and entry.kind=="REACTION" then
                    oldFingerprint=entry.eventKey175 or self:NormalizeText(tostring(entry.kind).."|"..tostring(entry.title).."|"..tostring(entry.detail).."|"..tostring(entry.targetPage))
                    if (canonical~="" and oldFingerprint==canonical) or (canonical=="" and oldFingerprint==fallback) then
                        entry.ts=tonumber(timestamp) or self:Now()
                        entry.detail=detail or entry.detail
                        entry.eventKey175=canonical~="" and canonical or entry.eventKey175
                        entry.duplicateCount170=nil
                        if index>1 then table.remove(db.recentUsefulActivity,index) table.insert(db.recentUsefulActivity,1,entry) end
                        return entry
                    end
                end
            end
        end
        local created=BaseUsefulActivity175(self,kind,title,detail,targetPage,timestamp)
        if created and canonical~="" then created.eventKey175=canonical end
        return created
    end
    return BaseUsefulActivity175(self,kind,title,detail,targetPage,timestamp)
end

function OTLGM:CleanupDuplicateNotifications175()
    local db=self:GetGuildDB()
    if not db then return end
    if type(db.inbox170)=="table" then
        local seen={} local index,entry,key
        for index=table.getn(db.inbox170),1,-1 do
            entry=db.inbox170[index]
            if type(entry)~="table" then table.remove(db.inbox170,index)
            else
                key=tostring(entry.id or "")
                if string.sub(key,1,6)=="REACT:" then
                    local parts=self:Split(key,":")
                    key=table.concat({parts[1] or "REACT",parts[2] or "",parts[3] or "",parts[4] or ""},":")
                end
                if seen[key] then
                    if not entry.read then seen[key].read=false end
                    table.remove(db.inbox170,index)
                else seen[key]=entry entry.id=key end
            end
        end
    end
    if type(db.notificationSeen)=="table" then
        local cleaned={} local key,value,parts,canonical
        for key,value in pairs(db.notificationSeen) do
            canonical=key
            if string.sub(tostring(key),1,6)=="REACT:" then
                parts=self:Split(key,":")
                canonical=table.concat({parts[1] or "REACT",parts[2] or "",parts[3] or "",parts[4] or ""},":")
            end
            if not cleaned[canonical] or (tonumber(value and value.ts) or 0)>(tonumber(cleaned[canonical] and cleaned[canonical].ts) or 0) then cleaned[canonical]=value end
        end
        db.notificationSeen=cleaned
    end
    if self.RefreshNavigation then self:RefreshNavigation() end
end

local BaseBuildActivity175=OTLGM.BuildActivityPage
function OTLGM:BuildActivityPage(page)
    BaseBuildActivity175(self,page)
    if self.ui.activityInsightText170 then
        self.ui.activityInsightText170:ClearAllPoints()
        self.ui.activityInsightText170:SetPoint("TOPLEFT",page,"TOPLEFT",0,-458)
        self.ui.activityInsightText170:SetWidth(710)
        self.ui.activityInsightText170:SetHeight(22)
    end
    if self.ui.activitySync156 then
        self.ui.activitySync156:ClearAllPoints()
        self.ui.activitySync156:SetPoint("TOPLEFT",page,"TOPLEFT",342,-492)
    end
    if self.ui.activitySummaryButton then
        self.ui.activitySummaryButton:ClearAllPoints()
        self.ui.activitySummaryButton:SetPoint("TOPLEFT",page,"TOPLEFT",526,-492)
    end
end

local BaseCraftPanel175=OTLGM.RefreshCraftingRecipesPanel
function OTLGM:RefreshCraftingRecipesPanel(summary)
    BaseCraftPanel175(self,summary)
    local index,row,result,online
    local basis=OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.craftingLevelBasis170 or "ITEM"
    for index=1,table.getn(self.ui and self.ui.craftingRecipeRows or {}) do
        row=self.ui.craftingRecipeRows[index]
        result=row and row.recipeData
        if row and result then
            online=0 local j
            for j=1,table.getn(result.crafters or {}) do if result.crafters[j].online then online=online+1 end end
            row.countText:SetText((online>0 and self.colors.green or self.colors.grey)..tostring(table.getn(result.crafters or {})).." crafter"..(table.getn(result.crafters or {})==1 and "" or "s")..self.colors.reset)
            if row.levelText170 then
                local recipe=result.recipe or {}
                local value=0
                if basis=="REQUIRED" then value=tonumber(result.filterRequiredLevel153) or tonumber(recipe.requiredLevel) or 0
                elseif basis=="SKILL" then value=tonumber(result.filterRequiredSkill170) or tonumber(recipe.requiredSkill) or 0
                else value=tonumber(result.filterItemLevel153) or tonumber(recipe.itemLevel) or 0 end
                if value>0 then
                    local prefix=basis=="SKILL" and "S" or basis=="REQUIRED" and "L" or "i"
                    row.levelText170:SetText(prefix..tostring(math.floor(value)))
                else row.levelText170:SetText("") end
            end
        elseif row and row.levelText170 then row.levelText170:SetText("") end
    end
    result=self.ui and self.ui.craftingSelectedRecipeData
    if result and result.recipe and string.upper(tostring(result.professionKey or ""))=="ENCHANTING" then
        -- Enchants have no ordinary result item. The recipe name is the effect
        -- and is therefore the primary detail rather than an empty item card.
        if self.ui.craftingRecipeTitle then self.ui.craftingRecipeTitle:SetText(self.colors.gold..tostring(result.recipe.name or "Enchanting recipe")..self.colors.reset) end
        if self.ui.craftingRecipeMeta then self.ui.craftingRecipeMeta:SetText("Enchanting effect  |  "..tostring(table.getn(result.crafters or {})).." crafter(s)") end
        if self.ui.craftingMaterialsEmpty152 and table.getn(result.recipe.reagents or {})==0 then
            self.ui.craftingMaterialsEmpty152:SetText("Effect details are carried by the enchant recipe. Reopen Enchanting to refresh reagent data.")
        end
    end
end

-- ---------------------------------------------------------------------------
-- Raid leader, invite contacts and invite-start workflow
-- ---------------------------------------------------------------------------

local function Edit175(parent,name,x,y,width,maxLetters)
    local edit=CreateFrame("EditBox",name,parent)
    if OTLGM.PrepareInteractiveControl170 then OTLGM:PrepareInteractiveControl170(edit,"editbox") end
    edit:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    edit:SetWidth(width) edit:SetHeight(30) edit:SetAutoFocus(false) edit:SetMaxLetters(maxLetters or 48)
    edit:SetFontObject("GameFontHighlightSmall")
    edit:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=9,insets={left=6,right=5,top=4,bottom=4}})
    edit:SetBackdropColor(0.018,0.018,0.018,1) edit:SetBackdropBorderColor(0.30,0.26,0.20,1)
    edit:SetScript("OnEscapePressed",function() this:ClearFocus() end)
    return edit
end

local function WireEscape175(text,maximum)
    text=tostring(text or "")
    if maximum and string.len(text)>maximum then text=string.sub(text,1,maximum) end
    text=string.gsub(text,"%%","%%25")
    text=string.gsub(text,"%^","%%5E")
    text=string.gsub(text,"|","%%7C")
    text=string.gsub(text,"[\r\n]"," ")
    return text
end

local function WireUnescape175(text)
    text=tostring(text or "")
    text=string.gsub(text,"%%7C","|")
    text=string.gsub(text,"%%5E","^")
    text=string.gsub(text,"%%25","%%")
    return text
end

local function NormalizeContactList175(text)
    local names,seen={},{}
    text=string.gsub(tostring(text or ""),";",",")
    local parts=OTLGM:Split(text,",")
    local index,part,key
    for index=1,table.getn(parts) do
        part=ShortName175(parts[index])
        key=NameKey175(part)
        if part~="" and not seen[key] and table.getn(names)<3 then seen[key]=true table.insert(names,part) end
    end
    return table.concat(names,", ")
end

local function ContactListContains175(text,name)
    local wanted=NameKey175(name)
    if wanted=="" then return false end
    local parts=OTLGM:Split(string.gsub(tostring(text or ""),";",","),",")
    local index
    for index=1,table.getn(parts) do
        if NameKey175(parts[index])==wanted then return true end
    end
    return false
end

local BaseBuildRaidEditor175=OTLGM.BuildRaidEditor156
function OTLGM:BuildRaidEditor156()
    BaseBuildRaidEditor175(self)
    local dialog=self.ui and self.ui.raidEditor156
    if not dialog or self.ui.raidInviteContact175 then return end
    Text175(dialog,"GameFontNormalSmall","RAID LEADER",232,-250,132,"LEFT")
    Text175(dialog,"GameFontNormalSmall","INVITE CONTACT",374,-250,132,"LEFT")
    Text175(dialog,"GameFontNormalSmall","INVITE HELPERS",516,-250,142,"LEFT")
    self.ui.raidLeader175=Edit175(dialog,"OTLGM_RaidLeader175",232,-268,132,24)
    self.ui.raidInviteContact175=Edit175(dialog,"OTLGM_RaidInviteContact175",374,-268,132,24)
    self.ui.raidInviteHelpers175=Edit175(dialog,"OTLGM_RaidInviteHelpers175",516,-268,142,60)
end

local BaseOpenRaidEditor175=OTLGM.OpenRaidEditor156
function OTLGM:OpenRaidEditor156(raid,duplicate)
    BaseOpenRaidEditor175(self,raid,duplicate)
    local player=PlayerName175()
    if self.ui.raidLeader175 then self.ui.raidLeader175:SetText(raid and raid.raidLeader or raid and raid.author or player) end
    if self.ui.raidInviteContact175 then self.ui.raidInviteContact175:SetText(raid and raid.inviteContact or raid and raid.raidLeader or raid and raid.author or player) end
    if self.ui.raidInviteHelpers175 then self.ui.raidInviteHelpers175:SetText(raid and raid.inviteHelpers or "") end
end

local BasePublishRaid175=OTLGM.PublishPveRaidEvent156
function OTLGM:PublishPveRaidEvent156(data,existingId)
    local ok,record=BasePublishRaid175(self,data,existingId)
    if not ok or not record then return ok,record end
    local leader=ShortName175(data and data.raidLeader or record.raidLeader or record.author or PlayerName175())
    local contact=ShortName175(data and data.inviteContact or record.inviteContact or leader)
    local helpers=NormalizeContactList175(data and data.inviteHelpers or record.inviteHelpers or "")
    local changed=record.raidLeader~=leader or record.inviteContact~=contact or record.inviteHelpers~=helpers
    record.raidLeader=leader record.inviteContact=contact~="" and contact or leader record.inviteHelpers=helpers
    record.inviteRevision=tonumber(record.inviteRevision) or 0
    record.invitesOpen=record.invitesOpen and true or false
    if changed then record.rev=(tonumber(record.rev) or 1)+1 record.ts=self:Now() end
    self:QueueRaidMeta157(record)
    return true,record
end

function OTLGM:SaveRaidEditor156()
    local data={
        name=self.ui.raidName156:GetText(),location=self.ui.raidLocation156:GetText(),note=self.ui.raidNote156:GetText(),
        dayOffset=self.ui.raidDay156:GetText(),hour=self.ui.raidHour156:GetText(),minute=self.ui.raidMinute156:GetText(),
        gatherHour=self.ui.raidGatherHour156:GetText(),gatherMinute=self.ui.raidGatherMinute156:GetText(),
        recurring=self.ui.raidRecurring156,reminderMinutes=self.ui.raidReminder156:GetText(),featured=self.ui.raidFeatured157,
        raidLeader=self.ui.raidLeader175 and self.ui.raidLeader175:GetText() or PlayerName175(),
        inviteContact=self.ui.raidInviteContact175 and self.ui.raidInviteContact175:GetText() or PlayerName175(),
        inviteHelpers=self.ui.raidInviteHelpers175 and self.ui.raidInviteHelpers175:GetText() or "",
    }
    local editId=self.ui.raidEditor156.editId156
    local ok,result=self:PublishPveRaidEvent156(data,editId)
    if ok then
        self.ui.raidEditor156:Hide() self.ui.raidFilter156="UPCOMING" self.ui.raidSelected156=result.id self:RefreshRaidPlanner156()
        self:SetStatus(editId and "Raid event updated." or "New raid event created.")
    else self:ShowNotice("Raid Event",result or "The raid event could not be saved.") end
end

function OTLGM:QueueRaidMeta157(record,target)
    if not record or not record.id then return false end
    local payload=table.concat({
        self.pveProtocol,"RDMETA",tostring(record.id),tostring(record.rev or 1),record.featured and "1" or "0",WireEscape175(record.cancelReason or "",40),
        WireEscape175(record.raidLeader or record.author or "",24),WireEscape175(record.inviteContact or record.raidLeader or record.author or "",24),
        WireEscape175(record.inviteHelpers or "",64),tostring(record.inviteRevision or 0),record.invitesOpen and "1" or "0",tostring(record.inviteTs or 0)
    },"^")
    return self:QueuePvePayload(payload,target and "WHISPER" or "GUILD",target)
end

local function RaidInviteEventKey175(record)
    return "RAIDINV:"..tostring(record.id or "")..":"..tostring(record.inviteRevision or 0)
end

function OTLGM:NotifyRaidInvites175(record,remote)
    if not record or not record.id or not record.invitesOpen then return false end
    local db=self:GetGuildDB()
    local key=RaidInviteEventKey175(record)
    if db.notificationSeen[key] then return false end
    db.notificationSeen[key]={ts=self:Now(),category="raid"}
    local contact=ShortName175(record.inviteContact or record.raidLeader or record.author or "")
    local body="Whisper "..(contact~="" and contact or "the raid leader").." for an invitation."
    if self.AddInboxNotification170 then self:AddInboxNotification170("raid",key,"Raid invites have started",tostring(record.name or "Guild Raid").." - "..body,"ACTION","pve") end
    if self.QueueGuildToast174 then self:QueueGuildToast174({category="raid",header="Raid Invites Open",title=record.name or "Guild Raid",body=body,icon="Interface\\Icons\\INV_BannerPVP_02",targetPage="pve",whisperTarget=contact,raidId=record.id,priority="ACTION",duration=10}) end
    if PlaySound then pcall(PlaySound,"TellMessage") end
    if self.RefreshNavigation then self:RefreshNavigation() end
    return true
end

function OTLGM:ApplyRaidMeta157(fields)
    local id=fields[3] or ""
    local revision=tonumber(fields[4]) or 0
    if id=="" then return false end
    local pve=self:EnsureRaid156DB()
    if not pve then return false end
    pve.raidMeta157=pve.raidMeta157 or {}
    local meta={
        rev=revision,featured=fields[5]=="1",cancelReason=WireUnescape175(fields[6] or ""),
        raidLeader=ShortName175(WireUnescape175(fields[7] or "")),inviteContact=ShortName175(WireUnescape175(fields[8] or "")),
        inviteHelpers=NormalizeContactList175(WireUnescape175(fields[9] or "")),inviteRevision=tonumber(fields[10]) or 0,
        invitesOpen=fields[11]=="1",inviteTs=tonumber(fields[12]) or 0,ts=self:Now(),
    }
    local record=self:GetRaidById156(id)
    local oldInviteRevision=record and tonumber(record.inviteRevision) or 0
    if record and revision>=(tonumber(record.rev) or 0) then
        record.featured=meta.featured record.cancelReason=meta.cancelReason
        record.raidLeader=meta.raidLeader~="" and meta.raidLeader or record.raidLeader or record.author
        record.inviteContact=meta.inviteContact~="" and meta.inviteContact or record.inviteContact or record.raidLeader
        record.inviteHelpers=meta.inviteHelpers
        -- A delayed metadata packet may have a newer raid revision but an older
        -- invite state. Never close invitations or rewind their dedupe revision.
        if meta.inviteRevision>=oldInviteRevision then
            record.inviteRevision=meta.inviteRevision
            record.invitesOpen=meta.invitesOpen
            record.inviteTs=meta.inviteTs
            if meta.invitesOpen and meta.inviteRevision>oldInviteRevision then self:NotifyRaidInvites175(record,true) end
        end
    else
        local old=pve.raidMeta157[id]
        if not old or revision>=(tonumber(old.rev) or 0) then pve.raidMeta157[id]=meta end
    end
    return true
end

function OTLGM:StartRaidInvites175(id)
    local record=self:GetRaidById156(id)
    if not record or record.status=="CANCELLED" then return false end
    local player=PlayerName175()
    local authorized=self:IsOfficerMode() or NameKey175(record.raidLeader)==NameKey175(player) or NameKey175(record.inviteContact)==NameKey175(player) or ContactListContains175(record.inviteHelpers,player)
    if not authorized then return false end
    local now=self:Now()
    if record.invitesOpen and now-(tonumber(record.inviteTs) or 0)<300 then
        if self.SetStatus then self:SetStatus("Raid invites were already announced recently.") end
        return false
    end
    record.invitesOpen=true
    record.inviteRevision=(tonumber(record.inviteRevision) or 0)+1
    record.inviteTs=now
    record.rev=(tonumber(record.rev) or 1)+1
    record.ts=self:Now()
    self:QueueRaidMeta157(record)
    self:NotifyRaidInvites175(record,false)
    self:RefreshRaidPlanner156()
    return true
end

local BaseRaidEnhancements175=OTLGM.BuildRaidEnhancements157
function OTLGM:BuildRaidEnhancements157()
    BaseRaidEnhancements175(self)
    if not self.ui or not self.ui.raidSeen156 or self.ui.raidWhisperInvite175 then return end
    local detail=self.ui.raidSeen156:GetParent()
    self.ui.raidWhisperInvite175=Button175(detail,"Whisper for Invite",16,-310,150,28,function()
        local raid=OTLGM:GetRaidById156(OTLGM.ui.raidSelected156)
        local target=raid and ShortName175(raid.inviteContact or raid.raidLeader or raid.author or "")
        if target~="" then OTLGM:OpenGuildChatWhisper(target) end
    end,"confirm")
    self.ui.raidStartInvites175=Button175(detail,"Start Invites",174,-310,124,28,function()
        OTLGM:StartRaidInvites175(OTLGM.ui.raidSelected156)
    end,"utility")
    if self.ui.raidNoRole156 then
        self.ui.raidNoRole156:ClearAllPoints()
        self.ui.raidNoRole156:SetPoint("TOPLEFT",detail,"TOPLEFT",16,-344)
        self.ui.raidNoRole156:SetWidth(396) self.ui.raidNoRole156:SetHeight(36)
        self.ui.raidNoRole156:SetText("Raid participation role may be required for Ready. Invite contact remains available to every guild member.")
    end
end

local BaseRefreshRaid175=OTLGM.RefreshRaidPlanner156
function OTLGM:RefreshRaidPlanner156()
    BaseRefreshRaid175(self)
    if not self.ui or not self.ui.raidDetailAuthor156 then return end
    local raid=self:GetRaidById156(self.ui.raidSelected156)
    if raid then
        local leader=ShortName175(raid.raidLeader or raid.author or "Leadership")
        local contact=ShortName175(raid.inviteContact or leader)
        local helpers=raid.inviteHelpers and raid.inviteHelpers~="" and raid.inviteHelpers or "None assigned"
        local start=tonumber(raid.startTs) or 0
        local dateLabel=start>0 and date("%A, %d %B",start) or "Date to be announced"
        local timeLabel=self.GetPveRaidServerTime155 and self:GetPveRaidServerTime155(raid) or string.format("%02d:%02d ST",tonumber(raid.stHour) or 0,tonumber(raid.stMinute) or 0)
        local remaining=self.GetPveRaidRemainingText and self:GetPveRaidRemainingText(raid) or ""
        local gather=string.format("%02d:%02d ST",tonumber(raid.gatherHour) or tonumber(raid.stHour) or 0,tonumber(raid.gatherMinute) or tonumber(raid.stMinute) or 0)
        local status=raid.invitesOpen and "|cff5fd9ffINVITES OPEN|r" or raid.featured and "|cffff5b3dIMPORTANT RAID|r" or "|cffffcc44SCHEDULED|r"
        self.ui.raidDetailTitle156:SetText("|cffffd36b"..tostring(raid.name or "Guild Raid").."|r")
        self.ui.raidDetailTime156:SetText(status.."   |cffffffff"..dateLabel.."|r   |cff69b7ff"..timeLabel.."|r")
        self.ui.raidDetailGather156:SetText("|cffb8b8b8Gather:|r "..gather..(remaining~="" and ("   |cff78d67b"..remaining.."|r") or ""))
        self.ui.raidDetailLocation156:SetText("|cffb8b8b8Meeting:|r "..(raid.location and raid.location~="" and raid.location or "Not specified"))
        local note=tostring(raid.note or "")
        if note=="" then note="No additional briefing." end
        self.ui.raidDetailNote156:SetText("|cffffcc66BRIEFING|r\n"..self:Utf8Truncate(note,260))
        self.ui.raidDetailAuthor156:ClearAllPoints()
        self.ui.raidDetailAuthor156:SetPoint("TOPLEFT",self.ui.raidDetailAuthor156:GetParent(),"TOPLEFT",16,-236)
        self.ui.raidDetailAuthor156:SetWidth(396) self.ui.raidDetailAuthor156:SetHeight(38)
        self.ui.raidDetailAuthor156:SetJustifyV("TOP")
        self.ui.raidDetailAuthor156:SetText("|cffb8b8b8Raid Leader:|r "..leader.."   |cffb8b8b8Invite Contact:|r "..contact.."\n|cffb8b8b8Invite Helpers:|r "..helpers)
        SetButtonText175(self.ui.raidWhisperInvite175,raid.invitesOpen and "Whisper for Invite" or "Whisper Contact")
        if self.SetControlEnabled170 then
            self:SetControlEnabled170(self.ui.raidWhisperInvite175,contact~="","No invite contact is assigned.")
            local player=PlayerName175()
            local canStart=self:IsOfficerMode() or NameKey175(leader)==NameKey175(player) or NameKey175(contact)==NameKey175(player) or ContactListContains175(raid.inviteHelpers,player)
            local cooling=raid.invitesOpen and self:Now()-(tonumber(raid.inviteTs) or 0)<300
            self:SetControlEnabled170(self.ui.raidStartInvites175,canStart and raid.status~="CANCELLED" and not cooling,cooling and "Invites were announced less than five minutes ago." or "Only leadership or an assigned invite helper can start invites.")
        end
        local cooling=raid.invitesOpen and self:Now()-(tonumber(raid.inviteTs) or 0)<300
        SetButtonText175(self.ui.raidStartInvites175,not raid.invitesOpen and "Start Invites" or cooling and "Invites Open" or "Announce Again")
    else
        if self.SetControlEnabled170 then self:SetControlEnabled170(self.ui.raidWhisperInvite175,false,"Select a raid first.") self:SetControlEnabled170(self.ui.raidStartInvites175,false,"Select a raid first.") end
    end
end

local BaseHomeRaid175=OTLGM.RefreshHomePveSummary155
function OTLGM:RefreshHomePveSummary155()
    BaseHomeRaid175(self)
    if not self.ui or not self.ui.homeRaidText then return end
    local raids=self:GetRaidList156("UPCOMING")
    local selected=nil local index,record
    for index=1,table.getn(raids) do record=raids[index] if record.status~="CANCELLED" and (tonumber(record.startTs) or 0)>=self:Now()-60 then selected=record break end end
    if not selected then return end
    local start=tonumber(selected.startTs) or 0
    local day=start>0 and date("%A, %d %b",start) or "Date TBA"
    local time=self.GetPveRaidServerTime155 and self:GetPveRaidServerTime155(selected) or selected.serverTime or "Time TBA"
    local remaining=self.GetPveRaidRemainingText and self:GetPveRaidRemainingText(selected) or ""
    local leader=ShortName175(selected.raidLeader or selected.author or "Leadership")
    local contact=ShortName175(selected.inviteContact or leader)
    local location=selected.location and selected.location~="" and selected.location or "Meeting point TBA"
    local status=selected.invitesOpen and "|cff5fd9ffINVITES OPEN|r" or (selected.featured and "|cffff5b3dIMPORTANT RAID|r" or "|cffffcc44NEXT RAID|r")
    local displayName=self:Utf8Truncate(tostring(selected.name or "Guild Raid"),28)
    local remainingLine=remaining~="" and ("|cff78d67b"..remaining.."|r") or "|cff8f8f8fCountdown unavailable|r"
    self.ui.homeRaidText:SetText(status.."  |cffffffff"..displayName.."|r\n"..
        "|cffffd36b"..day.."|r  |cff69b7ff"..time.."|r\n"..remainingLine.."\n"..
        "|cffb8b8b8Leader:|r "..leader.."  |cffb8b8b8Invites:|r "..contact.."\n"..
        "|cffb8b8b8Meeting:|r "..self:Utf8Truncate(location,31))
    if self.ui.homeRaidButton then self.ui.homeRaidButton.raidId170=selected.id end
end

local BaseBuildToast175=OTLGM.BuildAchievementToast174
function OTLGM:BuildAchievementToast174()
    BaseBuildToast175(self)
    local index,toast
    for index=1,table.getn(self.ui and self.ui.guildToasts174 or {}) do
        toast=self.ui.guildToasts174[index]
        if toast and not toast.releaseClick175 then
            toast.releaseClick175=true
            toast:SetScript("OnClick",function()
                if arg1=="RightButton" then OTLGM:DismissGuildToast174(this.toastIndex174) return end
                local data=this.toastData174
                if not data then return end
                if data.whisperTarget and data.whisperTarget~="" then OTLGM:OpenGuildChatWhisper(data.whisperTarget)
                elseif data.achievementId then OTLGM:OpenAchievement174(data.achievementId)
                elseif data.category=="mention" and OTLGM.OpenGuildChatMention174 then OTLGM:OpenGuildChatMention174(data)
                elseif data.targetPage and OTLGM.ShowPage then if OTLGM.ui.main and not OTLGM.ui.main:IsVisible() then OTLGM.ui.main:Show() end OTLGM:ShowPage(data.targetPage) end
                OTLGM:DismissGuildToast174(this.toastIndex174)
            end)
        end
    end
end

local BaseShowToast175=OTLGM.ShowGuildToastNow174
function OTLGM:ShowGuildToastNow174(data,preferredIndex)
    local result=BaseShowToast175(self,data,preferredIndex)
    if result and data and data.whisperTarget then
        local index,toast
        for index=1,table.getn(self.ui.guildToasts174 or {}) do toast=self.ui.guildToasts174[index] if toast:IsVisible() and toast.toastData174==data then toast.hintText:SetText("Whisper") break end end
    end
    return result
end

local BaseApplyRemoteRaid175=OTLGM.ApplyRemotePveRaid
function OTLGM:ApplyRemotePveRaid(fields)
    local result=BaseApplyRemoteRaid175(self,fields)
    if result then
        local id=fields and fields[3]
        local pve=self:EnsureRaid156DB()
        local record=id and self:GetRaidById156(id)
        local meta=pve and pve.raidMeta157 and pve.raidMeta157[id]
        if record and meta and (tonumber(meta.rev) or 0)>=(tonumber(record.rev) or 0) then
            record.featured=meta.featured record.cancelReason=meta.cancelReason
            record.raidLeader=meta.raidLeader~="" and meta.raidLeader or record.author
            record.inviteContact=meta.inviteContact~="" and meta.inviteContact or record.raidLeader
            record.inviteHelpers=meta.inviteHelpers or ""
            local currentInviteRevision=tonumber(record.inviteRevision) or 0
            if (tonumber(meta.inviteRevision) or 0)>=currentInviteRevision then
                record.inviteRevision=tonumber(meta.inviteRevision) or currentInviteRevision
                record.invitesOpen=meta.invitesOpen
                record.inviteTs=tonumber(meta.inviteTs) or 0
                if record.invitesOpen and record.inviteRevision>currentInviteRevision then self:NotifyRaidInvites175(record,true) end
            end
            pve.raidMeta157[id]=nil
        end
    end
    return result
end

-- ---------------------------------------------------------------------------
-- Release timers and event bridge
-- ---------------------------------------------------------------------------

function OTLGM:ProcessRelease175Timers()
    self.runtime=self.runtime or {}
    local now=self:Now()
    if self.runtime.resurrection175 then self:CheckResurrection175() end
    if self.runtime.pendingCraft175 and now-(self.runtime.pendingCraft175.ts or 0)>10 then self.runtime.pendingCraft175=nil end
    if self.runtime.rabbitTarget175 and now-(self.runtime.rabbitTarget175.ts or 0)>45 then self.runtime.rabbitTarget175=nil end
    if self.runtime.bossEncounter175 and now-(self.runtime.bossEncounter175.started or now)>600 then self.runtime.bossEncounter175=nil end
    local key,state
    for key,state in pairs(self.runtime.groupStates175 or {}) do if now-(state.ts or 0)>180 then self.runtime.groupStates175[key]=nil end end
end

local BaseQualityTimers175=OTLGM.ProcessQuality156Timers
function OTLGM:ProcessQuality156Timers()
    if BaseQualityTimers175 then BaseQualityTimers175(self) end
    self:ProcessRelease175Timers()
end

local releaseEventFrame175=CreateFrame("Frame","OTLGM_ReleaseEvent175")
local releaseEvents175={
    "PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_LOGOUT","PARTY_MEMBERS_CHANGED","RAID_ROSTER_UPDATE","GUILD_ROSTER_UPDATE","PLAYER_GUILD_UPDATE",
    "ZONE_CHANGED_NEW_AREA","MINIMAP_ZONE_CHANGED","PLAYER_REGEN_ENABLED","PLAYER_DEAD","UNIT_HEALTH","PLAYER_TARGET_CHANGED",
    "DUEL_REQUESTED","DUEL_FINISHED","DUEL_OUTOFBOUNDS","CHAT_MSG_SYSTEM","CHAT_MSG_LOOT","CHAT_MSG_COMBAT_SELF_HITS","CHAT_MSG_SPELL_SELF_DAMAGE","CHAT_MSG_COMBAT_HOSTILE_DEATH",
    "SPELLCAST_START","SPELLCAST_STOP","SPELLCAST_FAILED","SPELLCAST_INTERRUPTED","SPELLCAST_CHANNEL_START","SPELLCAST_CHANNEL_STOP",
    "TRADE_SKILL_UPDATE","CRAFT_UPDATE","SKILL_LINES_CHANGED","PLAYER_EQUIPMENT_CHANGED",
}
local eventIndex175
for eventIndex175=1,table.getn(releaseEvents175) do pcall(releaseEventFrame175.RegisterEvent,releaseEventFrame175,releaseEvents175[eventIndex175]) end
releaseEventFrame175:SetScript("OnEvent",function()
    if not OTLGM then return end
    OTLGM.runtime=OTLGM.runtime or {}
    if event=="PLAYER_LOGIN" then
        OTLGM:InstallEmoteHook175()
        OTLGM:InstallCraftHooks175()
        OTLGM:CleanupDuplicateNotifications175()
        local db=OTLGM:EnsureAchievements174()
        local silent=not db.releaseBaseline175
        ScanRiding175(OTLGM,silent)
        CheckUnderBanner175(OTLGM,silent)
        OTLGM:UpdateGroupSession174(silent)
        CheckMetaAchievements175(OTLGM,silent)
        db.releaseBaseline175=true
    elseif event=="PLAYER_ENTERING_WORLD" then
        ScanRiding175(OTLGM,false)
        CheckUnderBanner175(OTLGM,false)
        OTLGM:UpdateGroupSession174(false)
        OTLGM.runtime.revivedByGuild175=nil
    elseif event=="PLAYER_LOGOUT" then
        OTLGM.runtime.longWatch175=nil OTLGM.runtime.regularTable175=nil OTLGM.runtime.bossEncounter175=nil
    elseif event=="PARTY_MEMBERS_CHANGED" or event=="RAID_ROSTER_UPDATE" then
        OTLGM.runtime.reunionSignature175=nil
        OTLGM.runtime.proudLion175=nil
        OTLGM:UpdateGroupSession174(false)
        BroadcastGroupState175(OTLGM,OTLGM:GetGroupSnapshot174(),true)
        CheckDiplomaticIncident175(OTLGM,false)
    elseif event=="GUILD_ROSTER_UPDATE" or event=="PLAYER_GUILD_UPDATE" then
        OTLGM.runtime.guildLeader175=nil
        if OTLGM.RefreshAchievementRosterCache174 then OTLGM:RefreshAchievementRosterCache174(true) end
    elseif event=="ZONE_CHANGED_NEW_AREA" or event=="MINIMAP_ZONE_CHANGED" then
        OTLGM.runtime.proudLion175=nil OTLGM.runtime.regularTable175=nil OTLGM.runtime.groupStates175={}
        OTLGM.runtime.bossEncounter175=nil OTLGM.runtime.bossAttempts175={}
        OTLGM:UpdateGroupSession174(false)
        BroadcastGroupState175(OTLGM,OTLGM:GetGroupSnapshot174(),true)
        CheckDiplomaticIncident175(OTLGM,false)
    elseif event=="PLAYER_REGEN_ENABLED" then
        OTLGM:MarkBossAttemptFailed175()
    elseif event=="PLAYER_DEAD" then
        OTLGM.runtime.revivedByGuild175=nil
        CheckDiplomaticIncident175(OTLGM,false)
    elseif event=="UNIT_HEALTH" then
        if OTLGM.runtime.resurrection175 then OTLGM:CheckResurrection175() end
        if arg1=="player" or string.find(tostring(arg1 or ""),"party",1,true) then CheckDiplomaticIncident175(OTLGM,false) end
    elseif event=="PLAYER_TARGET_CHANGED" then
        TrackRabbitTarget175(OTLGM)
    elseif event=="DUEL_REQUESTED" then
        OTLGM:BeginDuel175(arg1)
    elseif event=="DUEL_FINISHED" then
        OTLGM:FinishDuel175(false)
    elseif event=="DUEL_OUTOFBOUNDS" then
        -- This is a warning event. The final DUEL_FINISHED health state decides
        -- victory or defeat; the warning itself is not treated as a result.
    elseif event=="CHAT_MSG_SYSTEM" then
        local text=string.lower(tostring(arg1 or ""))
        if OTLGM.runtime.duel175 and (string.find(text,"cancel",1,true) or string.find(text,"declin",1,true)) then OTLGM.runtime.duel175.cancelled=true end
    elseif event=="SPELLCAST_START" then
        OTLGM:BeginResurrection175(arg1)
        if Key175(arg1)=="fishing" then OTLGM.runtime.fishing175=true BroadcastGroupState175(OTLGM,OTLGM:GetGroupSnapshot174(),true) end
    elseif event=="SPELLCAST_CHANNEL_START" then
        if Key175(arg1)=="fishing" then OTLGM.runtime.fishing175=true BroadcastGroupState175(OTLGM,OTLGM:GetGroupSnapshot174(),true) end
    elseif event=="SPELLCAST_STOP" then
        if OTLGM.runtime.resurrection175 then OTLGM:CheckResurrection175() end
    elseif event=="SPELLCAST_FAILED" or event=="SPELLCAST_INTERRUPTED" then
        OTLGM.runtime.resurrection175=nil
        if OTLGM.runtime.fishing175 then OTLGM.runtime.fishing175=nil BroadcastGroupState175(OTLGM,OTLGM:GetGroupSnapshot174(),true) end
    elseif event=="SPELLCAST_CHANNEL_STOP" then
        if OTLGM.runtime.fishing175 then OTLGM.runtime.fishing175=nil BroadcastGroupState175(OTLGM,OTLGM:GetGroupSnapshot174(),true) end
    elseif event=="TRADE_SKILL_UPDATE" then
        OTLGM:ConfirmCraftAction175("TRADE")
    elseif event=="CRAFT_UPDATE" then
        OTLGM:ConfirmCraftAction175("CRAFT")
    elseif event=="SKILL_LINES_CHANGED" then
        ScanRiding175(OTLGM,false)
    elseif event=="PLAYER_EQUIPMENT_CHANGED" then
        if tonumber(arg1)==19 or arg1==nil then CheckUnderBanner175(OTLGM,false) end
    elseif event=="CHAT_MSG_LOOT" then
        CheckEpicLoot175(OTLGM,arg1)
    elseif event=="CHAT_MSG_COMBAT_SELF_HITS" or event=="CHAT_MSG_SPELL_SELF_DAMAGE" then
        MarkRabbitHit175(OTLGM,arg1)
    elseif event=="CHAT_MSG_COMBAT_HOSTILE_DEATH" then
        CheckRabbitDeath175(OTLGM,arg1)
    end
end)

OTLGM:RegisterModule("Release175",{layer="feature",catalogAdditions=41,totalAchievements=87,eventDriven=true,noOnUpdate=true})

-- END EMBEDDED RELEASE 1.7.5 RUNTIME
