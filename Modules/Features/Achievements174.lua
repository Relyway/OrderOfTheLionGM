-- Order of the Lion Guild Manager v1.7.4
-- Event-driven guild achievements. This module adds no OnUpdate handler.

local A174 = {
    installed = false,
    catalogRevision = 8,
    catalog = {},
    byId = {},
    categories = {
        { key = "OVERVIEW", label = "Overview", icon = "Interface\\Icons\\INV_Misc_Book_09" },
        { key = "SOCIAL", label = "Social", icon = "Interface\\Icons\\Spell_Holy_PrayerOfSpirit" },
        { key = "GROUP_FINDER", label = "Group Finder", icon = "Interface\\Icons\\INV_Sword_04" },
        { key = "PROFESSIONS", label = "Professions", icon = "Interface\\Icons\\Trade_BlackSmithing" },
        { key = "DUNGEONS", label = "Dungeons", icon = "Interface\\Icons\\INV_Misc_Key_03" },
        { key = "RAIDS", label = "Raids", icon = "Interface\\Icons\\INV_BannerPVP_02" },
        { key = "LEGACY", label = "Legacy", icon = "Interface\\Icons\\INV_Misc_PocketWatch_01" },
        { key = "SECRETS", label = "Secrets", icon = "Interface\\Icons\\INV_Misc_QuestionMark" },
    },
}
OTLGM.achievements174 = A174

local QUESTION_ICON_174 = "Interface\\Icons\\INV_Misc_QuestionMark"
local MAX_SET_174 = 2200
local GROUP_CHECKPOINT_174 = 60
local SHARED_SESSION_174 = 900
local SHARED_ZONE_174 = 300
local SHARED_REPEAT_174 = 3600
local RAID_PRESENCE_174 = 600

local function Trim174(text)
    text = tostring(text or "")
    return string.gsub(text, "^%s*(.-)%s*$", "%1")
end

local function ShortName174(name)
    return string.gsub(Trim174(name), "%-.*$", "")
end

local function NormalizeName174(name)
    return string.lower(ShortName174(name or ""))
end

local function NormalizeKey174(text)
    text = string.lower(Trim174(text))
    text = string.gsub(text, "[%s%p%c]", "")
    return text
end

local function TableCount174(tbl)
    local count = 0
    local key
    for key in pairs(tbl or {}) do count = count + 1 end
    return count
end

local function CopySet174(tbl)
    local result = {}
    local key, value
    for key, value in pairs(tbl or {}) do if value then result[key] = true end end
    return result
end

local function SanitizeBoundedMap174(map, maximum, numericValues)
    if type(map) ~= "table" then return {} end
    maximum = tonumber(maximum) or MAX_SET_174
    local count = 0
    local key, value
    for key, value in pairs(map) do
        local validKey = type(key) == "string" and key ~= "" and string.len(key) <= 96 and not string.find(key, "[%c]")
        local validValue = numericValues and tonumber(value) ~= nil or (not numericValues and value and true or false)
        if not validKey or not validValue then map[key] = nil
        else
            count = count + 1
            if numericValues then map[key] = math.max(0, tonumber(value) or 0) end
        end
    end
    if count > maximum then
        local keys = {}
        for key in pairs(map) do table.insert(keys, key) end
        table.sort(keys)
        local index
        for index=maximum + 1,table.getn(keys) do map[keys[index]] = nil end
    end
    return map
end

local function SafeNumber174(value, minimum, maximum)
    value = tonumber(value) or 0
    if minimum and value < minimum then value = minimum end
    if maximum and value > maximum then value = maximum end
    return value
end

local function SetText174(widget, value)
    if not widget then return end
    if widget.text and widget.text.SetText then widget.text:SetText(value or "")
    elseif widget.label156 and widget.label156.SetText then widget.label156:SetText(value or "") end
end

local function Panel174(parent, x, y, width, height, kind)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:SetWidth(width)
    frame:SetHeight(height)
    if OTLGM.ApplyPanelSkin then OTLGM:ApplyPanelSkin(frame, kind or "surface") end
    return frame
end

local function Text174(parent, template, value, x, y, width, justify)
    local text = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormalSmall")
    text:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then text:SetWidth(width) end
    text:SetJustifyH(justify or "LEFT")
    text:SetText(value or "")
    return text
end

local function Button174(parent, label, x, y, width, height, handler, style)
    local button = CreateFrame("Button", nil, parent)
    if OTLGM.PrepareInteractiveControl170 then OTLGM:PrepareInteractiveControl170(button, "button") end
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 9,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.text:SetWidth(width - 8)
    button.text:SetText(label or "")
    button.handler174 = handler
    button.actionStyle = style or "normal"
    button:SetScript("OnClick", function() if not this.disabled and this.handler174 then this.handler174(this) end end)
    button:SetScript("OnEnter", function() this.hovered = true if OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(this) end end)
    button:SetScript("OnLeave", function() this.hovered = false if OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(this) end if GameTooltip then GameTooltip:Hide() end end)
    if OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(button) end
    return button
end

local function Select174(button, selected)
    if not button then return end
    button.selected = selected and true or false
    if OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(button) end
end

local function SetTexture174(region, path)
    if not region then return end
    region:SetTexture(nil)
    region:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    region:SetVertexColor(1, 1, 1)
    region:SetAlpha(1)
    if path and path ~= "" then region:SetTexture(path) end
end

local function AddButtonIcon174(button, path, size)
    if not button then return end
    button.icon174 = button.icon174 or button:CreateTexture(nil, "OVERLAY")
    button.icon174:SetPoint("LEFT", button, "LEFT", 7, 0)
    button.icon174:SetWidth(size or 15)
    button.icon174:SetHeight(size or 15)
    SetTexture174(button.icon174, path or QUESTION_ICON_174)
    if button.text then
        button.text:ClearAllPoints()
        button.text:SetPoint("LEFT", button, "LEFT", 28, 0)
        button.text:SetWidth(math.max(20, (button:GetWidth() or 0) - 34))
        button.text:SetJustifyH("LEFT")
    end
end

local function Add174(def)
    table.insert(A174.catalog, def)
    A174.byId[def.id] = def
end

-- The 46 IDs below are permanent. Deferred IDs from the specification are not
-- reused for different meanings.
Add174({ id="A007", category="SOCIAL", name="A Voice in the Hall", description="Leave your first reaction on a leadership announcement.", icon="Interface\\Icons\\INV_Misc_Note_01", progress="reaction", required=1 })
Add174({ id="A091", category="SOCIAL", name="Side by Side", description="Join a group with another guild member.", icon="Interface\\Icons\\INV_Sword_04", progress="groupNow", required=2 })
Add174({ id="A011", category="SOCIAL", name="Five as One", description="Form a full five-player party made entirely of guild members.", icon="Interface\\Icons\\Ability_DualWield", progress="fullParty", required=5 })
Add174({ id="A012", category="SOCIAL", name="Familiar Faces", description="Complete ten shared sessions with the same guild member.", icon="Interface\\Icons\\Spell_Holy_BlessingOfProtection", progress="familiar", required=10 })
Add174({ id="A013", category="SOCIAL", name="Many Roads, One Banner", description="Group with twenty-five different guild members.", icon="Interface\\Icons\\INV_BannerPVP_01", progress="sharedPartners", required=25 })
Add174({ id="A014", category="SOCIAL", name="Across the Ranks", description="Adventure with members from five different guild ranks.", icon="Interface\\Icons\\INV_Misc_Note_02", progress="sharedRanks", required=5 })
Add174({ id="A015", category="SOCIAL", name="Class Council", description="Adventure with every class represented in the guild.", icon="Interface\\Icons\\INV_Misc_Book_09", progress="sharedClasses", required=1 })
Add174({ id="A018", category="SOCIAL", name="Long Road Together", description="Spend ten hours grouped with guild members.", icon="Interface\\Icons\\INV_Misc_PocketWatch_01", progress="groupSeconds", required=36000 })
Add174({ id="A019", category="SOCIAL", name="A Friend in Every Land", description="Share an adventure with guild members in ten different zones.", icon="Interface\\Icons\\INV_Misc_Map_01", progress="sharedZones", required=10 })
Add174({ id="A020", category="SOCIAL", name="Known Across the Hall", description="Group with fifty different guild members.", icon="Interface\\Icons\\INV_Misc_GroupNeedMore", progress="sharedPartners", required=50 })

Add174({ id="A021", category="GROUP_FINDER", name="Call Answered", description="Send ten applications through the Guild Group Finder.", icon="Interface\\Icons\\INV_Letter_15", progress="groupApplications", required=10 })
Add174({ id="A022", category="GROUP_FINDER", name="Quick Response", description="Apply to a new guild group within three minutes.", icon="Interface\\Icons\\Ability_Rogue_Sprint", progress="quickResponse", required=1 })
Add174({ id="A023", category="GROUP_FINDER", name="Trusted Companion", description="Have twenty-five Group Finder applications accepted.", icon="Interface\\Icons\\Spell_Holy_SealOfSalvation", progress="acceptedApplications", required=25 })
Add174({ id="A024", category="GROUP_FINDER", name="Before the Bell", description="Answer an unanswered group request in its final fifteen minutes.", icon="Interface\\Icons\\INV_Misc_PocketWatch_02", progress="beforeBell", required=1 })
Add174({ id="A027", category="GROUP_FINDER", name="Generous Claw", description="Complete meaningful trades with twenty-five different guild members.", icon="Interface\\Icons\\INV_Misc_Bag_10", progress="tradePartners", required=25 })
Add174({ id="A028", category="GROUP_FINDER", name="Reagent Runner", description="Respond to ten guild requests for materials or reagents.", icon="Interface\\Icons\\INV_Misc_Herb_07", progress="materialResponses", required=10 })
Add174({ id="A030", category="GROUP_FINDER", name="Always Available", description="Answer guild requests on seven consecutive days.", icon="Interface\\Icons\\Spell_Holy_Renew", progress="responseStreak", required=7 })

Add174({ id="A032", category="PROFESSIONS", name="Living Recipe Book", description="Publish one hundred unique recipes to the guild crafting network.", icon="Interface\\Icons\\INV_Scroll_03", progress="publishedRecipes", required=100 })
Add174({ id="A038", category="PROFESSIONS", name="One-Stop Workshop", description="Scan every supported crafting profession known by this character.", icon="Interface\\Icons\\INV_Misc_Gear_01", progress="professionScans", required=1 })
Add174({ id="A039", category="PROFESSIONS", name="Master of the Trade", description="Reach the current skill cap in a supported profession.", icon="Interface\\Icons\\INV_Hammer_04", progress="professionCap", required=1 })
Add174({ id="A040", category="PROFESSIONS", name="Crafter's Circle", description="Contact ten different guild crafters through the crafting network.", icon="Interface\\Icons\\INV_Misc_Rune_01", progress="crafterContacts", required=10 })

Add174({ id="A043", category="DUNGEONS", name="First Expedition", description="Complete your first guild dungeon expedition.", icon="Interface\\Icons\\INV_Misc_Key_03", progress="dungeonBosses", required=1 })
Add174({ id="A044", category="DUNGEONS", name="Five Under One Banner", description="Defeat a dungeon boss with a full guild party.", icon="Interface\\Icons\\INV_BannerPVP_02", progress="dungeonFullParty", required=1 })
Add174({ id="A047", category="DUNGEONS", name="Flawless Run", description="Defeat a dungeon boss without losing a guild member.", icon="Interface\\Icons\\Spell_Holy_DivineIntervention", progress="flawlessDungeon", required=1 })
Add174({ id="A049", category="DUNGEONS", name="Dungeon Cartographer", description="Defeat bosses in ten different dungeons with guild members.", icon="Interface\\Icons\\INV_Misc_Map_01", progress="dungeonZones", required=10 })
Add174({ id="A050", category="DUNGEONS", name="Veteran Delver", description="Defeat one hundred dungeon bosses alongside guild members.", icon="Interface\\Icons\\INV_Pick_02", progress="dungeonBosses", required=100 })
Add174({ id="A051", category="DUNGEONS", name="Last Lion Standing", description="Be the only surviving guild member when a dungeon boss falls.", icon="Interface\\Icons\\INV_Shield_05", progress="lastLion", required=1 })
Add174({ id="A052", category="DUNGEONS", name="From the Brink", description="Defeat a dungeon boss while three guild members are below twenty percent health.", icon="Interface\\Icons\\Spell_Holy_SealOfSacrifice", progress="fromBrink", required=1 })

Add174({ id="A053", category="RAIDS", name="The First Muster", description="Take part in your first guild raid.", icon="Interface\\Icons\\INV_Helmet_06", progress="raidPresence", required=600 })
Add174({ id="A054", category="RAIDS", name="Twenty Under One Banner", description="Defeat a raid boss with at least twenty guild members present.", icon="Interface\\Icons\\INV_BannerPVP_01", progress="raidTwenty", required=1 })
Add174({ id="A055", category="RAIDS", name="First Trophy", description="Defeat your first raid boss alongside the guild.", icon="Interface\\Icons\\INV_Misc_Head_Dragon_01", progress="raidBosses", required=1 })
Add174({ id="A059", category="RAIDS", name="Unbroken Line", description="Survive ten consecutive guild raid boss victories.", icon="Interface\\Icons\\Spell_Holy_DevotionAura", progress="raidSurviveStreak", required=10 })
Add174({ id="A064", category="RAIDS", name="Raid Veteran", description="Defeat one hundred raid bosses alongside the guild.", icon="Interface\\Icons\\INV_Misc_Head_Dragon_Black", progress="raidBosses", required=100 })

Add174({ id="A078", category="SOCIAL", name="Full Connection", description="Form a full party where every member is connected through the addon.", icon="Interface\\Icons\\INV_Misc_Rune_01", progress="fullConnection", required=5 })

Add174({ id="A081", category="SECRETS", name="Roar in Unison", description="The title is your clue.", revealed="Ten unique guild members used /roar nearby within ten seconds.", icon="Interface\\Icons\\Ability_Druid_ChallangingRoar", progress="secret", required=1, secret=true })
Add174({ id="A082", category="SECRETS", name="A Very Serious Order", description="The title is your clue.", revealed="Ten unique guild members danced nearby within thirty seconds after a boss victory.", icon="Interface\\Icons\\Ability_Rogue_Disguise", progress="secret", required=1, secret=true })
Add174({ id="A083", category="SECRETS", name="Not a Cult", description="The title is your clue.", revealed="Thirteen unique guild members knelt nearby within fifteen seconds.", icon="Interface\\Icons\\Spell_Shadow_Twilight", progress="secret", required=1, secret=true })
Add174({ id="A084", category="SECRETS", name="Saved by a Whisker", description="The title is your clue.", revealed="Survive a recognized boss victory at one percent health or less.", icon="Interface\\Icons\\Ability_Rogue_FeignDeath", progress="secret", required=1, secret=true })
Add174({ id="A090", category="SECRETS", name="Secret Keeper", description="Unlock three secret achievements.", icon="Interface\\Icons\\INV_Misc_Key_13", progress="secretCount", required=3 })

Add174({ id="A086", category="LEGACY", name="Return of the Lion", description="Return after thirty full days away while still belonging to the guild.", icon="Interface\\Icons\\Ability_Hunter_Pathfinding", progress="returnDays", required=30 })
Add174({ id="A092", category="LEGACY", name="One Month Under the Banner", description="Remain a member of the guild for thirty days.", icon="Interface\\Icons\\INV_BannerPVP_02", progress="tenureDays", required=30 })
Add174({ id="A093", category="LEGACY", name="Three Months in the Hall", description="Remain a member of the guild for ninety days.", icon="Interface\\Icons\\INV_Misc_PocketWatch_01", progress="tenureDays", required=90 })
Add174({ id="A087", category="LEGACY", name="Old Guard", description="Remain a member of the guild for one hundred and eighty days.", icon="Interface\\Icons\\INV_Shield_06", progress="tenureDays", required=180 })
Add174({ id="A094", category="LEGACY", name="A Year Under the Lion", description="Remain a member of the guild for one full year.", icon="Interface\\Icons\\INV_Crown_01", progress="tenureDays", required=365 })
Add174({ id="A095", category="LEGACY", name="Pillar of the Order", description="Remain a member of the guild for two full years.", icon="Interface\\Icons\\INV_Misc_StoneTablet_05", progress="tenureDays", required=730 })
Add174({ id="A096", category="LEGACY", name="Living Chronicle", description="Remain a member of the guild for three full years.", icon="Interface\\Icons\\INV_Misc_Book_11", progress="tenureDays", required=1095 })

local FACTION_RACES_174 = {
    HUMAN="ALLIANCE", DWARF="ALLIANCE", NIGHTELF="ALLIANCE", GNOME="ALLIANCE", HIGHELF="ALLIANCE",
    ORC="HORDE", SCOURGE="HORDE", UNDEAD="HORDE", TAUREN="HORDE", TROLL="HORDE", GOBLIN="HORDE",
}

-- Boss rules are data, not UI logic. Custom OctoWoW entries can be added with
-- RegisterAchievementBoss174 without touching the tracker.
local function BossSet174(names)
    local result = {}
    local index, name
    for index=1,table.getn(names or {}) do
        name = NormalizeKey174(names[index])
        if name ~= "" then result[name] = true end
    end
    return result
end

local function InstanceRule174(kind, names)
    return { kind=kind, bosses=BossSet174(names) }
end

local INSTANCE_RULES_174 = {
    ragefirechasm=InstanceRule174("DUNGEON", { "Taragaman the Hungerer", "Jergosh the Invoker", "Bazzalan" }),
    wailingcaverns=InstanceRule174("DUNGEON", { "Lady Anacondra", "Lord Cobrahn", "Kresh", "Lord Pythas", "Skum", "Lord Serpentis", "Verdan the Everliving", "Mutanus the Devourer" }),
    thedeadmines=InstanceRule174("DUNGEON", { "Rhahk'Zor", "Sneed", "Gilnid", "Mr. Smite", "Cookie", "Edwin VanCleef" }),
    shadowfangkeep=InstanceRule174("DUNGEON", { "Rethilgore", "Razorclaw the Butcher", "Baron Silverlaine", "Commander Springvale", "Odo the Blindwatcher", "Fenrus the Devourer", "Wolf Master Nandos", "Archmage Arugal" }),
    thestockade=InstanceRule174("DUNGEON", { "Targorr the Dread", "Kam Deepfury", "Hamhock", "Bazil Thredd", "Dextren Ward", "Bruegal Ironknuckle" }),
    stormwindstockade=InstanceRule174("DUNGEON", { "Targorr the Dread", "Kam Deepfury", "Hamhock", "Bazil Thredd", "Dextren Ward", "Bruegal Ironknuckle" }),
    blackfathomdeeps=InstanceRule174("DUNGEON", { "Ghamoo-ra", "Lady Sarevess", "Gelihast", "Lorgus Jett", "Baron Aquanis", "Twilight Lord Kelris", "Old Serra'kis", "Aku'mai" }),
    gnomeregan=InstanceRule174("DUNGEON", { "Grubbis", "Viscous Fallout", "Electrocutioner 6000", "Crowd Pummeler 9-60", "Dark Iron Ambassador", "Mekgineer Thermaplugg" }),
    razorfenkraul=InstanceRule174("DUNGEON", { "Roogug", "Aggem Thorncurse", "Death Speaker Jargba", "Overlord Ramtusk", "Agathelos the Raging", "Charlga Razorflank" }),
    scarletmonastery=InstanceRule174("DUNGEON", { "Houndmaster Loksey", "Arcanist Doan", "Herod", "High Inquisitor Fairbanks", "Scarlet Commander Mograine", "High Inquisitor Whitemane" }),
    razorfendowns=InstanceRule174("DUNGEON", { "Tuten'kash", "Mordresh Fire Eye", "Glutton", "Ragglesnout", "Amnennar the Coldbringer" }),
    uldaman=InstanceRule174("DUNGEON", { "Revelosh", "Ironaya", "Obsidian Sentinel", "Ancient Stone Keeper", "Galgann Firehammer", "Grimlok", "Archaedas" }),
    zulfarrak=InstanceRule174("DUNGEON", { "Antu'sul", "Theka the Martyr", "Witch Doctor Zum'rah", "Nekrum Gutchewer", "Shadowpriest Sezz'ziz", "Chief Ukorz Sandscalp", "Hydromancer Velratha" }),
    maraudon=InstanceRule174("DUNGEON", { "Noxxion", "Razorlash", "Lord Vyletongue", "Celebras the Cursed", "Landslide", "Rotgrip", "Princess Theradras" }),
    thetempleofatalhakkar=InstanceRule174("DUNGEON", { "Atal'alarion", "Jammal'an the Prophet", "Dreamscythe", "Weaver", "Morphaz", "Hazzas", "Shade of Eranikus" }),
    sunkentemple=InstanceRule174("DUNGEON", { "Atal'alarion", "Jammal'an the Prophet", "Dreamscythe", "Weaver", "Morphaz", "Hazzas", "Shade of Eranikus" }),
    blackrockdepths=InstanceRule174("DUNGEON", { "High Interrogator Gerstahn", "Lord Roccor", "Bael'Gar", "General Angerforge", "Golem Lord Argelmach", "Ambassador Flamelash", "The Seven", "Magmus", "Emperor Dagran Thaurissan" }),
    lowerblackrockspire=InstanceRule174("DUNGEON", { "Highlord Omokk", "Shadow Hunter Vosh'gajin", "War Master Voone", "Mother Smolderweb", "Urok Doomhowl", "Quartermaster Zigris", "Halycon", "Overlord Wyrmthalak" }),
    upperblackrockspire=InstanceRule174("DUNGEON", { "Pyroguard Emberseer", "Solakar Flamewreath", "Warchief Rend Blackhand", "The Beast", "General Drakkisath" }),
    diremaul=InstanceRule174("DUNGEON", { "Zevrim Thornhoof", "Alzzin the Wildshaper", "Hydrospawn", "Lethtendris", "Magister Kalendris", "Immol'thar", "Prince Tortheldrin", "Guard Mol'dar", "King Gordok" }),
    scholomance=InstanceRule174("DUNGEON", { "Kirtonos the Herald", "Jandice Barov", "Rattlegore", "Ras Frostwhisper", "Instructor Malicia", "The Ravenian", "Lady Illucia Barov", "Lord Alexei Barov", "Darkmaster Gandling" }),
    stratholme=InstanceRule174("DUNGEON", { "The Unforgiven", "Hearthsinger Forresten", "Timmy the Cruel", "Maleki the Pallid", "Baroness Anastari", "Nerub'enkan", "Ramstein the Gorger", "Baron Rivendare", "Balnazzar" }),
    moltencore=InstanceRule174("RAID", { "Lucifron", "Magmadar", "Gehennas", "Garr", "Baron Geddon", "Shazzrah", "Sulfuron Harbinger", "Golemagg the Incinerator", "Majordomo Executus", "Ragnaros" }),
    onyxiaslair=InstanceRule174("RAID", { "Onyxia" }),
    blackwinglair=InstanceRule174("RAID", { "Razorgore the Untamed", "Vaelastrasz the Corrupt", "Broodlord Lashlayer", "Firemaw", "Ebonroc", "Flamegor", "Chromaggus", "Nefarian" }),
    zulgurub=InstanceRule174("RAID", { "High Priestess Jeklik", "High Priest Venoxis", "High Priestess Mar'li", "Bloodlord Mandokir", "Gri'lek", "Hazza'rah", "Renataki", "Wushoolay", "High Priest Thekal", "Gahz'ranka", "High Priestess Arlokk", "Jin'do the Hexxer", "Hakkar" }),
    ruinsofahnqiraj=InstanceRule174("RAID", { "Kurinnaxx", "General Rajaxx", "Moam", "Buru the Gorger", "Ayamiss the Hunter", "Ossirian the Unscarred" }),
    templeofahnqiraj=InstanceRule174("RAID", { "The Prophet Skeram", "Battleguard Sartura", "Fankriss the Unyielding", "Viscidus", "Princess Huhuran", "Emperor Vek'lor", "Emperor Vek'nilash", "Ouro", "C'Thun" }),
    naxxramas=InstanceRule174("RAID", { "Anub'Rekhan", "Grand Widow Faerlina", "Maexxna", "Noth the Plaguebringer", "Heigan the Unclean", "Loatheb", "Instructor Razuvious", "Gothik the Harvester", "Highlord Mograine", "Thane Korth'azz", "Lady Blaumeux", "Sir Zeliek", "Patchwerk", "Grobbulus", "Gluth", "Thaddius", "Sapphiron", "Kel'Thuzad" }),
}

local function NormalizeBossTable174()
    local zone, rule, converted, name
    for zone, rule in pairs(INSTANCE_RULES_174) do
        converted = {}
        for name in pairs(rule.bosses or {}) do converted[NormalizeKey174(name)] = true end
        rule.bosses = converted
    end
end
NormalizeBossTable174()

function OTLGM:RegisterAchievementBoss174(zoneName, bossName, kind)
    local zone = NormalizeKey174(zoneName)
    local boss = NormalizeKey174(bossName)
    if zone == "" or boss == "" then return false end
    local rule = INSTANCE_RULES_174[zone] or { kind = kind == "RAID" and "RAID" or "DUNGEON", bosses = {} }
    rule.kind = kind == "RAID" and "RAID" or rule.kind or "DUNGEON"
    rule.bosses[boss] = true
    INSTANCE_RULES_174[zone] = rule
    return true
end

function OTLGM:GetAchievementCharacterKey174()
    local player = ShortName174(UnitName and UnitName("player") or "Unknown")
    local realm = GetCVar and (GetCVar("realmName") or "UnknownRealm") or "UnknownRealm"
    return NormalizeName174(player) .. "@" .. string.lower(tostring(realm))
end

function OTLGM:EnsureAchievements174()
    self:EnsureDB()
    OTLGM_DB.settings.achievementPopups174 = OTLGM_DB.settings.achievementPopups174 ~= false
    if OTLGM_DB.settings.achievementGuildChat174 == nil then OTLGM_DB.settings.achievementGuildChat174 = true end
    if not OTLGM_DB.settings.achievementCategory174 then OTLGM_DB.settings.achievementCategory174 = "OVERVIEW" end
    if not OTLGM_DB.settings.achievementFilter174 then OTLGM_DB.settings.achievementFilter174 = "ALL" end
    local guild = self:GetGuildDB()
    if not guild then
        -- This temporary container is used only before guild information becomes
        -- available; it is never treated as authoritative progress.
        self.runtime = self.runtime or {}
        self.runtime.achievementsPending174 = self.runtime.achievementsPending174 or { characters={} }
        guild = self.runtime.achievementsPending174
    end
    if type(guild.achievements174) ~= "table" then guild.achievements174 = {} end
    local store = guild.achievements174
    if type(store.characters) ~= "table" then store.characters = {} end
    local key = self:GetAchievementCharacterKey174()

    -- Migrate the first preview build, which stored character progress at the
    -- SavedVariables root and therefore excluded it from guild backups.
    local legacyRoot = OTLGM_DB and OTLGM_DB.achievements174
    if type(legacyRoot) == "table" and type(legacyRoot.characters) == "table" and not store.rootMigration174 then
        local legacyCharacter = legacyRoot.characters[key]
        if type(legacyCharacter) == "table" and type(store.characters[key]) ~= "table" then
            store.characters[key] = legacyCharacter
        end
        store.rootMigration174 = self:Now()
    end

    if type(store.characters[key]) ~= "table" then store.characters[key] = {} end
    local db = store.characters[key]
    db.completed = type(db.completed) == "table" and db.completed or {}
    db.counters = type(db.counters) == "table" and db.counters or {}
    db.sets = type(db.sets) == "table" and db.sets or {}
    db.dates = type(db.dates) == "table" and db.dates or {}
    db.familiar = type(db.familiar) == "table" and db.familiar or {}
    db.sessionCredits = type(db.sessionCredits) == "table" and db.sessionCredits or {}
    db.metrics = type(db.metrics) == "table" and db.metrics or { checks=0, completions=0 }
    db.catalogRevision = tonumber(db.catalogRevision) or 0

    -- Safe migration from the first 1.7.4 preview. Only semantic supersets are
    -- carried forward; unrelated old IDs remain stored but are not counted.
    local legacy = type(legacyRoot) == "table" and legacyRoot or nil
    if legacy and not store.legacyRootMigrated174 then
        if legacy.completed and legacy.completed.BROTHERS_ARMS then db.completed.A091 = { unlockedAt = tonumber(legacy.completed.BROTHERS_ARMS) or self:Now() } end
        if legacy.completed and legacy.completed.FULL_PRIDE then db.completed.A011 = { unlockedAt = tonumber(legacy.completed.FULL_PRIDE) or self:Now() } end
        if legacy.completed and legacy.completed.UNDER_BANNER then db.completed.UNDER_BANNER = { unlockedAt = tonumber(legacy.completed.UNDER_BANNER) or self:Now() } end
        store.legacyRootMigrated174 = self:Now()
    end
    local id, value
    for id, value in pairs(db.completed) do
        if type(value) == "number" then db.completed[id] = { unlockedAt = value }
        elseif type(value) ~= "table" then db.completed[id] = nil
        else value.unlockedAt = tonumber(value.unlockedAt) or self:Now() end
    end
    if db.catalogRevision < A174.catalogRevision then
        db.familiar = SanitizeBoundedMap174(db.familiar, MAX_SET_174, true)
        db.sessionCredits = SanitizeBoundedMap174(db.sessionCredits, MAX_SET_174, true)
        local setKey, setValue
        for setKey, setValue in pairs(db.sets) do db.sets[setKey] = SanitizeBoundedMap174(setValue, MAX_SET_174, false) end
    end
    db.catalogRevision = A174.catalogRevision
    return db
end

function OTLGM:IsAchievementComplete174(id)
    local db = self:EnsureAchievements174()
    return db.completed[id] ~= nil
end

function OTLGM:GetAchievementCompletedAt174(id)
    local db = self:EnsureAchievements174()
    local record = db.completed[id]
    if type(record) == "table" then return tonumber(record.unlockedAt) end
    return tonumber(record)
end

function OTLGM:GetAchievementCount174()
    local db = self:EnsureAchievements174()
    local count = 0
    local id
    for id in pairs(db.completed) do if A174.byId[id] then count = count + 1 end end
    return count, table.getn(A174.catalog)
end

function OTLGM:GetAchievementSet174(key)
    local db = self:EnsureAchievements174()
    if type(db.sets[key]) ~= "table" then db.sets[key] = {} end
    return db.sets[key]
end

function OTLGM:AddAchievementSetValue174(key, value)
    value = NormalizeKey174(value)
    if value == "" then return false end
    local set = self:GetAchievementSet174(key)
    if set[value] then return false end
    if TableCount174(set) >= MAX_SET_174 then return false end
    set[value] = true
    return true
end

function OTLGM:AddAchievementCounter174(key, amount)
    local db = self:EnsureAchievements174()
    local value = SafeNumber174(db.counters[key], 0, 1000000000) + SafeNumber174(amount, 0, 1000000000)
    db.counters[key] = math.min(1000000000, value)
    return db.counters[key]
end

function OTLGM:SetAchievementCounter174(key, value)
    local db = self:EnsureAchievements174()
    db.counters[key] = SafeNumber174(value, 0, 1000000000)
    return db.counters[key]
end

function OTLGM:RefreshAchievementRosterCache174(force)
    self.runtime = self.runtime or {}
    local cache = self.runtime.achievementRosterCache174
    if cache and not force then return cache end
    cache = { members = {}, classes = {}, builtAt = self:Now() }
    local db = self:GetGuildDB()
    local name, member, key, classToken
    for name, member in pairs(db and db.roster or {}) do
        key = NormalizeName174(name)
        if key ~= "" then cache.members[key] = member or true end
        if type(member) == "table" then
            if member.name and member.name ~= "" then cache.members[NormalizeName174(member.name)] = member end
            classToken = string.upper(tostring(member.classToken or member.class or ""))
            if classToken ~= "" and classToken ~= "UNKNOWN" then cache.classes[NormalizeKey174(classToken)] = true end
        end
    end
    local player = UnitName and UnitName("player")
    if player and GetGuildInfo and GetGuildInfo("player") then
        key = NormalizeName174(player)
        cache.members[key] = cache.members[key] or true
        local _, token = UnitClass and UnitClass("player")
        token = NormalizeKey174(token)
        if token ~= "" then cache.classes[token] = true end
    end
    self.runtime.achievementRosterCache174 = cache
    return cache
end

function OTLGM:GetGuildMemberSet174()
    return self:RefreshAchievementRosterCache174(false).members
end

function OTLGM:GetGroupSnapshot174()
    local members = self:GetGuildMemberSet174()
    local result = { total=0, guild=0, races={}, classes={}, factions={}, levels={}, guildMembers={}, isRaid=false, isParty=false }
    local units = {}
    local raidCount = GetNumRaidMembers and (GetNumRaidMembers() or 0) or 0
    local partyCount = GetNumPartyMembers and (GetNumPartyMembers() or 0) or 0
    local i
    if raidCount > 0 then
        result.isRaid = true
        for i=1,raidCount do table.insert(units, "raid" .. tostring(i)) end
    else
        result.isParty = partyCount > 0
        table.insert(units, "player")
        for i=1,partyCount do table.insert(units, "party" .. tostring(i)) end
    end
    for i=1,table.getn(units) do
        local unit = units[i]
        if UnitExists and UnitExists(unit) then
            result.total = result.total + 1
            local rawName = UnitName(unit)
            local normalized = NormalizeName174(rawName)
            local stored = members[normalized]
            if rawName and stored then
                result.guild = result.guild + 1
                local raceName, raceToken = UnitRace(unit)
                local className, classToken = UnitClass(unit)
                raceToken = string.upper(tostring(raceToken or raceName or ""))
                classToken = string.upper(tostring(classToken or className or ""))
                if raceToken ~= "" then result.races[raceToken] = true end
                if classToken ~= "" then result.classes[classToken] = true end
                local faction = FACTION_RACES_174[raceToken]
                if faction then result.factions[faction] = true end
                local info = type(stored) == "table" and stored or {}
                table.insert(result.guildMembers, {
                    unit=unit, name=ShortName174(rawName), key=normalized,
                    class=classToken ~= "" and classToken or string.upper(tostring(info.classToken or info.class or "")),
                    rank=tostring(info.rankIndex or info.rank or "UNKNOWN"),
                    level=tonumber(UnitLevel(unit)) or tonumber(info.level) or 0,
                    zone=tostring(info.zone or ""),
                })
            end
        end
    end
    result.raceCount = TableCount174(result.races)
    result.classCount = TableCount174(result.classes)
    result.factionCount = TableCount174(result.factions)
    return result
end

function OTLGM:IsGroupMemberPresent174(member)
    if not member then return false end
    if UnitIsConnected and not UnitIsConnected(member.unit) then return false end
    if member.unit == "player" then return true end
    -- Shared-session rules require the same zone, not merely the same party.
    -- Prefer the roster zone because UnitIsVisible may be false for a distant
    -- party member who is still in the same zone. Visibility is only a safe
    -- fallback when the client has no zone value for that member.
    local _, _, currentZone = self:GetLocation174()
    if member.zone and member.zone ~= "" and currentZone and currentZone ~= "" then
        return NormalizeKey174(member.zone) == NormalizeKey174(currentZone)
    end
    if UnitIsVisible then return UnitIsVisible(member.unit) and true or false end
    return false
end

function OTLGM:GetPresentGuildMembers174(group)
    group = group or self:GetGroupSnapshot174()
    local result = {}
    local index, member
    for index=1,table.getn(group.guildMembers or {}) do
        member = group.guildMembers[index]
        if self:IsGroupMemberPresent174(member) then table.insert(result, member) end
    end
    return result
end

function OTLGM:GetPresentGuildCount174(group)
    return table.getn(self:GetPresentGuildMembers174(group))
end

function OTLGM:GetLocation174()
    local zone = GetRealZoneText and GetRealZoneText() or ""
    local subzone = GetSubZoneText and GetSubZoneText() or ""
    return NormalizeKey174(zone), NormalizeKey174(subzone), zone, subzone
end

function OTLGM:GetCurrentInstanceRule174()
    local zone, subzone = self:GetLocation174()
    return INSTANCE_RULES_174[zone] or INSTANCE_RULES_174[subzone], zone ~= "" and zone or subzone
end

function OTLGM:GetAchievementLink174(def)
    if not def then return "[Guild Achievement]" end
    return "|cffffd36b|Hotlgmachievement:" .. tostring(def.id) .. "|h[" .. tostring(def.name) .. "]|h|r"
end

function OTLGM:InsertAchievementLinkInBlizzardChat174(def)
    if not def then return false end
    local edit = nil
    if ChatEdit_GetActiveWindow then
        local ok, active = pcall(ChatEdit_GetActiveWindow)
        if ok then edit = active end
    end
    if not edit then edit = ChatFrameEditBox end
    if not edit or not edit.IsVisible or not edit:IsVisible() then return false end
    local linkText = self:GetAchievementLink174(def)
    edit:SetFocus()
    local current = edit:GetText() or ""
    local prefix = (current ~= "" and string.sub(current, -1) ~= " ") and " " or ""
    if edit.Insert then edit:Insert(prefix .. linkText .. " ") else edit:SetText(current .. prefix .. linkText .. " ") end
    return true
end

function OTLGM:SendAchievementGuildAnnouncement174(def)
    if not def or not SendChatMessage or not GetGuildInfo("player") then return false end
    local player = UnitName("player") or "A guild member"
    SendChatMessage("[Guild Achievement] " .. player .. " earned " .. self:GetAchievementLink174(def) .. ".", "GUILD")
    local db = self:EnsureAchievements174()
    db.dates.lastGuildChatAt = self:Now()
    return true
end

function OTLGM:QueueAchievementGuildAnnouncement174(def)
    if not def or not OTLGM_DB.settings.achievementGuildChat174 then return false end
    local db = self:EnsureAchievements174()
    self.runtime = self.runtime or {}
    self.runtime.achievementGuildQueue174 = self.runtime.achievementGuildQueue174 or {}
    local queue = self.runtime.achievementGuildQueue174
    local index
    for index=1,table.getn(queue) do if queue[index] == def.id then return true end end
    local last = tonumber(db.dates.lastGuildChatAt) or 0
    if table.getn(queue) == 0 and self:Now() - last >= 2 then return self:SendAchievementGuildAnnouncement174(def) end
    table.insert(queue, def.id)
    while table.getn(queue) > 12 do table.remove(queue, 1) end
    return true
end

function OTLGM:ProcessAchievementGuildAnnouncements174()
    local db = self:EnsureAchievements174()
    local queue = self.runtime and self.runtime.achievementGuildQueue174
    if not queue or table.getn(queue) == 0 or not OTLGM_DB.settings.achievementGuildChat174 then return end
    if self:Now() - (tonumber(db.dates.lastGuildChatAt) or 0) < 2 then return end
    local id = table.remove(queue, 1)
    if A174.byId[id] then self:SendAchievementGuildAnnouncement174(A174.byId[id]) end
end

function OTLGM:CompleteAchievement174(id, silent)
    local def = A174.byId[id]
    local db = self:EnsureAchievements174()
    if not def or db.completed[id] then return false end
    db.completed[id] = { unlockedAt = self:Now() }
    db.metrics.completions = (db.metrics.completions or 0) + 1
    if not silent then
        if OTLGM_DB.settings.achievementPopups174 ~= false then self:ShowAchievementToast174(def) end
        self:QueueAchievementGuildAnnouncement174(def)
    end
    if def.secret then self:CheckSecretKeeper174(silent) end
    if self.RefreshAchievements174 then self:RefreshAchievements174() end
    return true
end

function OTLGM:CheckSecretKeeper174(silent)
    local db = self:EnsureAchievements174()
    local count = 0
    local id, record
    for id, record in pairs(db.completed) do if record and A174.byId[id] and A174.byId[id].secret then count = count + 1 end end
    db.counters.secretCount = count
    if count >= 3 then self:CompleteAchievement174("A090", silent) end
end

function OTLGM:GetGuildClassTarget174()
    return self:RefreshAchievementRosterCache174(false).classes
end

function OTLGM:IsAddonUserFresh174(name)
    local db = self:GetGuildDB()
    local now = self:Now()
    local wanted = NormalizeName174(name)
    local storedName, info
    if wanted == NormalizeName174(UnitName and UnitName("player") or "") then return true end
    for storedName, info in pairs(db and db.detectedVersions or {}) do
        if NormalizeName174(storedName) == wanted and type(info) == "table" and now - (tonumber(info.ts) or 0) <= 300 then return true end
    end
    return false
end

function OTLGM:CheckImmediateGroupAchievements174(silent, snapshot)
    local group = snapshot or self:GetGroupSnapshot174()
    self.runtime = self.runtime or {}
    self.runtime.achievementGroup174 = group
    if group.guild >= 2 then self:CompleteAchievement174("A091", silent) end
    if group.isParty and group.total == 5 and group.guild == 5 then
        self:CompleteAchievement174("A011", silent)
        local allConnected = true
        local index
        for index=1,table.getn(group.guildMembers) do
            if not self:IsAddonUserFresh174(group.guildMembers[index].name) then allConnected = false break end
        end
        if allConnected then self:CompleteAchievement174("A078", silent) end
    end
    return group
end

local function GroupSignature174(self, group)
    local names, members = {}, {}
    local player = NormalizeName174(UnitName and UnitName("player") or "")
    local present = self:GetPresentGuildMembers174(group)
    local index, member
    for index=1,table.getn(present) do
        member = present[index]
        if member.key ~= player then table.insert(names, member.key) table.insert(members, member) end
    end
    table.sort(names)
    return table.concat(names, ","), names, members
end

function OTLGM:FinalizeGroupSession174(now, silent)
    local session = self.runtime and self.runtime.groupSession174
    if not session then return end
    now = now or self:Now()
    local db = self:EnsureAchievements174()
    local elapsed = math.max(0, math.min(120, now - (session.lastCheckpoint or now)))
    if elapsed > 0 then
        db.counters.groupSeconds = (tonumber(db.counters.groupSeconds) or 0) + elapsed
        session.total = (session.total or 0) + elapsed
        session.zoneTotal = (session.zoneTotal or 0) + elapsed
    end
    if (session.total or 0) >= SHARED_SESSION_174 and (not session.lastCreditAt or now - session.lastCreditAt >= SHARED_REPEAT_174) then
        local index, member, lastAt, count
        for index=1,table.getn(session.members or {}) do
            member = session.members[index]
            lastAt = tonumber(db.sessionCredits[member.key]) or 0
            if now - lastAt >= SHARED_REPEAT_174 then
                local mayStoreCredit = db.sessionCredits[member.key] ~= nil or TableCount174(db.sessionCredits) < MAX_SET_174
                local mayStoreFamiliar = db.familiar[member.key] ~= nil or TableCount174(db.familiar) < MAX_SET_174
                if mayStoreCredit and mayStoreFamiliar then
                    db.sessionCredits[member.key] = now
                    count = (tonumber(db.familiar[member.key]) or 0) + 1
                    db.familiar[member.key] = math.min(100000, count)
                    self:AddAchievementSetValue174("sharedPartners", member.key)
                    self:AddAchievementSetValue174("sharedRanks", member.rank)
                    self:AddAchievementSetValue174("sharedClasses", member.class)
                end
            end
        end
        session.lastCreditAt = now
    end
    if (session.zoneTotal or 0) >= SHARED_ZONE_174 and session.zoneKey and session.zoneKey ~= "" then self:AddAchievementSetValue174("sharedZones", session.zoneKey) end
    if (tonumber(db.counters.groupSeconds) or 0) >= 36000 then self:CompleteAchievement174("A018", silent) end
    if TableCount174(self:GetAchievementSet174("sharedPartners")) >= 25 then self:CompleteAchievement174("A013", silent) end
    if TableCount174(self:GetAchievementSet174("sharedPartners")) >= 50 then self:CompleteAchievement174("A020", silent) end
    if TableCount174(self:GetAchievementSet174("sharedRanks")) >= 5 then self:CompleteAchievement174("A014", silent) end
    if TableCount174(self:GetAchievementSet174("sharedZones")) >= 10 then self:CompleteAchievement174("A019", silent) end
    local maxFamiliar = 0
    local name, familiarCount
    for name, familiarCount in pairs(db.familiar) do if tonumber(familiarCount) and familiarCount > maxFamiliar then maxFamiliar = familiarCount end end
    if maxFamiliar >= 10 then self:CompleteAchievement174("A012", silent) end
    local classTarget = self:GetGuildClassTarget174()
    local classSeen = self:GetAchievementSet174("sharedClasses")
    local targetCount, met = 0, true
    local classToken
    for classToken in pairs(classTarget) do targetCount = targetCount + 1 if not classSeen[NormalizeKey174(classToken)] then met = false end end
    if targetCount > 0 and met then self:CompleteAchievement174("A015", silent) end
end

function OTLGM:UpdateGroupSession174(silent)
    self.runtime = self.runtime or {}
    local now = self:Now()
    local group = self:CheckImmediateGroupAchievements174(silent)
    local signature, partnerKeys, presentMembers = GroupSignature174(self, group)
    local zone = self:GetLocation174()
    local session = self.runtime.groupSession174
    if table.getn(partnerKeys) == 0 then
        if session then self:FinalizeGroupSession174(now, silent) end
        self.runtime.groupSession174 = nil
        self.runtime.achievementGroupTickAt174 = nil
        return group
    end
    if not session or session.signature ~= signature then
        if session then self:FinalizeGroupSession174(now, silent) end
        session = { signature=signature, members=presentMembers, started=now, lastCheckpoint=now, total=0, zoneKey=zone, zoneTotal=0, lastCreditAt=nil }
        self.runtime.groupSession174 = session
    else
        self:FinalizeGroupSession174(now, silent)
        if session.zoneKey ~= zone then
            session.zoneKey = zone
            session.zoneTotal = 0
        end
        session.lastCheckpoint = now
    end
    self.runtime.achievementGroupTickAt174 = now + GROUP_CHECKPOINT_174
    return group
end

function OTLGM:UpdateRaidPresence174(silent)
    self.runtime = self.runtime or {}
    local rule = self:GetCurrentInstanceRule174()
    local group = self.runtime.achievementGroup174 or self:GetGroupSnapshot174()
    local now = self:Now()
    local presentGuild = self:GetPresentGuildCount174(group)
    if rule and rule.kind == "RAID" and group.isRaid and presentGuild >= 10 then
        local state = self.runtime.raidPresence174
        if not state then state = { started=now, last=now, total=0 } self.runtime.raidPresence174 = state end
        local elapsed = math.max(0, math.min(120, now - (state.last or now)))
        state.total = (state.total or 0) + elapsed
        state.last = now
        self:SetAchievementCounter174("raidPresence", state.total)
        if state.total >= RAID_PRESENCE_174 then self:CompleteAchievement174("A053", silent) end
        self.runtime.achievementRaidTickAt174 = now + GROUP_CHECKPOINT_174
    else
        self.runtime.raidPresence174 = nil
        self.runtime.achievementRaidTickAt174 = nil
        if not self:IsAchievementComplete174("A053") then self:SetAchievementCounter174("raidPresence", 0) end
    end
end

function OTLGM:RecordQualifyingResponseDay174()
    local db = self:EnsureAchievements174()
    local day = tonumber(date("%Y%m%d", self:Now())) or 0
    local previous = tonumber(db.dates.lastResponseDay) or 0
    if previous == day then return end
    local yesterday = tonumber(date("%Y%m%d", self:Now() - 86400)) or 0
    if previous == yesterday then db.counters.responseStreak = (tonumber(db.counters.responseStreak) or 0) + 1
    else db.counters.responseStreak = 1 end
    db.dates.lastResponseDay = day
    if db.counters.responseStreak >= 7 then self:CompleteAchievement174("A030", false) end
end

function OTLGM:RecordGroupApplication174(group, record)
    if not group or not record then return end
    local db = self:EnsureAchievements174()
    local dedupe = self:GetAchievementSet174("groupApplicationIds")
    local id = NormalizeKey174(record.id)
    if id ~= "" and not dedupe[id] then
        if TableCount174(dedupe) >= 500 then return end
        dedupe[id] = true
        db.counters.groupApplications = (tonumber(db.counters.groupApplications) or 0) + 1
        if db.counters.groupApplications >= 10 then self:CompleteAchievement174("A021", false) end
        local createdAt = tonumber(group.ts or group.createdAt) or 0
        local now = self:Now()
        if createdAt > 0 and now >= createdAt and now - createdAt <= 180 then self:CompleteAchievement174("A022", false) end
        local expires = tonumber(group.expires or group.expiresAt) or 0
        local applications = self.GetPveApplications and self:GetPveApplications(group.id, true) or {}
        if expires > now and expires - now <= 900 and table.getn(applications) <= 1 then self:CompleteAchievement174("A024", false) end
        self:RecordQualifyingResponseDay174()
    end
end

function OTLGM:RecordAcceptedApplication174(record)
    if not record then return end
    local player = NormalizeName174(UnitName and UnitName("player") or "")
    if NormalizeName174(record.author) ~= player or string.upper(tostring(record.status or "")) ~= "ACCEPTED" then return end
    local set = self:GetAchievementSet174("acceptedApplicationIds")
    local id = NormalizeKey174(record.id)
    if id ~= "" and not set[id] then
        if TableCount174(set) >= 500 then return end
        set[id] = true
        local value = self:AddAchievementCounter174("acceptedApplications", 1)
        if value >= 25 then self:CompleteAchievement174("A023", false) end
    end
end

function OTLGM:RecordCraftingResponse174(request, record)
    if not request or not record then return end
    local text = string.lower(tostring((request.item or "") .. " " .. (request.note or "") .. " " .. (request.kind or "")))
    local material = string.find(text, "material", 1, true) or string.find(text, "reagent", 1, true) or string.find(text, "mats", 1, true)
    if material then
        local set = self:GetAchievementSet174("materialResponseIds")
        local id = NormalizeKey174(record.id)
        if id ~= "" and not set[id] then
            if TableCount174(set) >= 500 then return end
            set[id] = true
            local value = self:AddAchievementCounter174("materialResponses", 1)
            if value >= 10 then self:CompleteAchievement174("A028", false) end
            self:RecordQualifyingResponseDay174()
        end
    end
end

function OTLGM:RecordCrafterContact174(name)
    if self:AddAchievementSetValue174("crafterContacts", NormalizeName174(name)) and TableCount174(self:GetAchievementSet174("crafterContacts")) >= 10 then self:CompleteAchievement174("A040", false) end
end

local PROFESSION_TERMS_174 = {
    ALCHEMY = { "alchemy" }, BLACKSMITHING = { "blacksmithing", "blacksmith" },
    COOKING = { "cooking" }, ENCHANTING = { "enchanting" }, ENGINEERING = { "engineering" },
    JEWELCRAFTING = { "jewelcrafting", "jewelcraft" }, LEATHERWORKING = { "leatherworking" },
    TAILORING = { "tailoring" }, MINING = { "mining", "smelting" },
}

function OTLGM:GetKnownProfessionKeys174()
    local known = {}
    if GetNumSkillLines and GetSkillLineInfo then
        local count = tonumber(GetNumSkillLines()) or 0
        local index, rawName, isHeader, normalized, key, terms, termIndex
        for index=1,count do
            rawName, isHeader = GetSkillLineInfo(index)
            if rawName and not isHeader then
                normalized = string.lower(tostring(rawName))
                for key, terms in pairs(PROFESSION_TERMS_174) do
                    for termIndex=1,table.getn(terms) do
                        if normalized == terms[termIndex] or string.find(normalized, terms[termIndex], 1, true) then
                            known[key] = true
                            break
                        end
                    end
                end
            end
        end
    end
    return known
end

function OTLGM:GetLocalProfessionSnapshot174()
    local result = { recipes=0, capped=false, known=0, scanned=0 }
    local craft = self.EnsureCraftingDB and self:EnsureCraftingDB()
    local player = ShortName174(UnitName and UnitName("player") or "")
    local character = craft and craft.characters and craft.characters[player]
    if not character then
        local name, candidate
        for name, candidate in pairs(craft and craft.characters or {}) do
            if candidate.localOwner and NormalizeName174(name) == NormalizeName174(player) then character = candidate break end
        end
    end
    local knownKeys = self:GetKnownProfessionKeys174()
    if TableCount174(knownKeys) == 0 then
        local scannedKey
        for scannedKey in pairs(character and character.professions or {}) do knownKeys[scannedKey] = true end
    end
    result.known = TableCount174(knownKeys)
    local key, profession
    for key, profession in pairs(character and character.professions or {}) do
        local recipeCount = TableCount174(profession.recipes)
        result.recipes = result.recipes + recipeCount
        if knownKeys[key] and (profession.ts or profession.lastScan or profession.updatedAt or recipeCount > 0) then result.scanned = result.scanned + 1 end
        local rank = tonumber(profession.rank) or 0
        local maximum = tonumber(profession.maxRank or profession.maxSkill or profession.skillMax) or 0
        if maximum > 0 and rank >= maximum then result.capped = true end
    end
    return result
end

function OTLGM:CheckStoredReactionAchievement174(silent)
    local craft = self.EnsureCraftingDB and self:EnsureCraftingDB()
    local player = NormalizeName174(UnitName and UnitName("player") or "")
    local key, reactions, name, info
    for key, reactions in pairs(craft and craft.reactions or {}) do
        if string.sub(tostring(key), 1, 4) == "ANN:" and type(reactions) == "table" then
            for name, info in pairs(reactions) do
                if NormalizeName174(name) == player and type(info) == "table" and info.reaction and info.reaction ~= "NONE" then
                    self:CompleteAchievement174("A007", silent)
                    return true
                end
            end
        end
    end
    return false
end

function OTLGM:CheckProfessionAchievements174(silent)
    local snapshot = self:GetLocalProfessionSnapshot174()
    self:SetAchievementCounter174("publishedRecipes", snapshot.recipes)
    if snapshot.recipes >= 100 then self:CompleteAchievement174("A032", silent) end
    if snapshot.known > 0 and snapshot.scanned >= snapshot.known then self:CompleteAchievement174("A038", silent) end
    if snapshot.capped then self:CompleteAchievement174("A039", silent) end
end

function OTLGM:UpdateMembershipPeriod174()
    local db = self:EnsureAchievements174()
    local now = self:Now()
    local inGuild = GetGuildInfo and GetGuildInfo("player") and true or false
    if not inGuild then
        if db.dates.memberSince and not db.dates.memberPeriodEndedAt then db.dates.memberPeriodEndedAt = now end
        db.dates.wasGuildMember = false
        return false
    end
    if db.dates.memberPeriodEndedAt or db.dates.wasGuildMember == false then
        db.dates.memberSince = now
        db.dates.memberPeriodEndedAt = nil
    end
    db.dates.wasGuildMember = true
    return true
end

function OTLGM:GetMemberSince174()
    if not GetGuildInfo or not GetGuildInfo("player") then return nil end
    local db = self:GetGuildDB()
    local player = NormalizeName174(UnitName and UnitName("player") or "")
    local name, member, earliest
    for name, member in pairs(db and db.roster or {}) do
        if NormalizeName174(name) == player or NormalizeName174(member and member.name) == player then
            local candidates = { member.joinedAt, member.trackedSince, member.seen, member.firstSeenAt }
            local index, value
            for index=1,table.getn(candidates) do value = tonumber(candidates[index]) if value and value > 0 and (not earliest or value < earliest) then earliest = value end end
            break
        end
    end
    local achievementDB = self:EnsureAchievements174()
    if not achievementDB.dates.memberSince and not achievementDB.dates.memberPeriodEndedAt and earliest then achievementDB.dates.memberSince = earliest end
    if not achievementDB.dates.memberSince and GetGuildInfo and GetGuildInfo("player") then achievementDB.dates.memberSince = self:Now() end
    return tonumber(achievementDB.dates.memberSince)
end

function OTLGM:CheckLegacyAchievements174(silent, loginCheck)
    local db = self:EnsureAchievements174()
    local now = self:Now()
    local memberSince = self:GetMemberSince174()
    if memberSince and now >= memberSince then
        local days = math.floor((now - memberSince) / 86400)
        db.counters.tenureDays = days
        if days >= 30 then self:CompleteAchievement174("A092", silent) end
        if days >= 90 then self:CompleteAchievement174("A093", silent) end
        if days >= 180 then self:CompleteAchievement174("A087", silent) end
        if days >= 365 then self:CompleteAchievement174("A094", silent) end
        if days >= 730 then self:CompleteAchievement174("A095", silent) end
        if days >= 1095 then self:CompleteAchievement174("A096", silent) end
    end
    if loginCheck then
        local previous = tonumber(db.dates.lastLoginAt) or 0
        if previous > 0 and now - previous >= 30 * 86400 and GetGuildInfo and GetGuildInfo("player") then self:CompleteAchievement174("A086", silent) end
        db.dates.lastLoginAt = now
    end
end

function OTLGM:BeginTradeTracking174()
    self.runtime = self.runtime or {}
    local name = TradeFrameRecipientNameText and TradeFrameRecipientNameText.GetText and TradeFrameRecipientNameText:GetText() or ""
    self.runtime.trade174 = { target=ShortName174(name), meaningful=false, accepted=false }
end

function OTLGM:UpdateTradeTracking174()
    local trade = self.runtime and self.runtime.trade174
    if not trade then return end
    local meaningful = false
    local index
    if GetPlayerTradeMoney and (tonumber(GetPlayerTradeMoney()) or 0) > 0 then meaningful = true end
    if GetTargetTradeMoney and (tonumber(GetTargetTradeMoney()) or 0) > 0 then meaningful = true end
    for index=1,6 do
        if GetTradePlayerItemLink and GetTradePlayerItemLink(index) then meaningful = true end
        if GetTradeTargetItemLink and GetTradeTargetItemLink(index) then meaningful = true end
    end
    trade.meaningful = meaningful
end

function OTLGM:FinishTradeTracking174(success)
    local trade = self.runtime and self.runtime.trade174
    self.runtime.trade174 = nil
    if not trade or not success or not trade.meaningful or trade.target == "" then return end
    local members = self:GetGuildMemberSet174()
    if not members[NormalizeName174(trade.target)] then return end
    if self:AddAchievementSetValue174("tradePartners", NormalizeName174(trade.target)) and TableCount174(self:GetAchievementSet174("tradePartners")) >= 25 then self:CompleteAchievement174("A027", false) end
end

function OTLGM:StartBossEncounter174(bossName)
    local rule, zoneKey = self:GetCurrentInstanceRule174()
    local bossKey = NormalizeKey174(bossName)
    if not rule or not rule.bosses[bossKey] then return false end
    local group = self:GetGroupSnapshot174()
    local presentGuild = self:GetPresentGuildCount174(group)
    group.presentGuild = presentGuild
    if rule.kind == "RAID" then
        if presentGuild < 10 then return false end
    elseif presentGuild < 3 then
        return false
    end
    self.runtime = self.runtime or {}
    self.runtime.bossEncounter174 = { boss=bossKey, zone=zoneKey, kind=rule.kind, group=group, guildDeath=false, playerDied=false, started=self:Now() }
    return true
end

function OTLGM:MarkBossEncounterDeath174(name)
    local encounter = self.runtime and self.runtime.bossEncounter174
    if not encounter then return end
    local normalized = NormalizeName174(name)
    local player = NormalizeName174(UnitName and UnitName("player") or "")
    if normalized == player then encounter.playerDied = true end
    local index, member
    for index=1,table.getn(encounter.group.guildMembers or {}) do
        member = encounter.group.guildMembers[index]
        if member.key == normalized then encounter.guildDeath = true break end
    end
end

function OTLGM:HandleBossVictory174(bossName)
    local rule, zoneKey = self:GetCurrentInstanceRule174()
    local bossKey = NormalizeKey174(bossName)
    if not rule or not rule.bosses[bossKey] then return false end
    local encounter = self.runtime and self.runtime.bossEncounter174
    local group = encounter and encounter.group or self:GetGroupSnapshot174()
    local presentGuild = self:GetPresentGuildCount174(group)
    group.presentGuild = presentGuild
    if rule.kind == "RAID" then
        if presentGuild < 10 then return false end
    elseif presentGuild < 3 then
        return false
    end
    local db = self:EnsureAchievements174()
    local now = self:Now()
    self.runtime = self.runtime or {}
    self.runtime.recentBossEvents174 = self.runtime.recentBossEvents174 or {}
    local eventKey = zoneKey .. ":" .. bossKey
    local recentAt = tonumber(self.runtime.recentBossEvents174[eventKey]) or 0
    if now - recentAt <= 45 then return false end
    self.runtime.recentBossEvents174[eventKey] = now
    local recentKey, recentValue
    for recentKey, recentValue in pairs(self.runtime.recentBossEvents174) do
        if now - (tonumber(recentValue) or 0) > 120 then self.runtime.recentBossEvents174[recentKey] = nil end
    end

    if rule.kind == "DUNGEON" then
        local kills = self:AddAchievementCounter174("dungeonBosses", 1)
        self:AddAchievementSetValue174("dungeonZones", zoneKey)
        self:CompleteAchievement174("A043", false)
        if group.isParty and group.total == 5 and presentGuild == 5 then self:CompleteAchievement174("A044", false) end
        if encounter and not encounter.guildDeath then self:CompleteAchievement174("A047", false) end
        if TableCount174(self:GetAchievementSet174("dungeonZones")) >= 10 then self:CompleteAchievement174("A049", false) end
        if kills >= 100 then self:CompleteAchievement174("A050", false) end
        local aliveGuild, playerAlive, low = 0, false, 0
        local index, member, health, maximum
        local presentMembers = self:GetPresentGuildMembers174(group)
        for index=1,table.getn(presentMembers) do
            member = presentMembers[index]
            local dead = UnitIsDeadOrGhost and UnitIsDeadOrGhost(member.unit)
            if not dead then
                aliveGuild = aliveGuild + 1
                if member.key == NormalizeName174(UnitName and UnitName("player") or "") then playerAlive = true end
                health = UnitHealth and tonumber(UnitHealth(member.unit)) or 0
                maximum = UnitHealthMax and tonumber(UnitHealthMax(member.unit)) or 0
                if maximum > 0 and health > 0 and health / maximum < 0.20 then low = low + 1 end
            end
        end
        if presentGuild >= 3 and aliveGuild == 1 and playerAlive then self:CompleteAchievement174("A051", false) end
        if low >= 3 then self:CompleteAchievement174("A052", false) end
    else
        if presentGuild >= 10 then
            local kills = self:AddAchievementCounter174("raidBosses", 1)
            self:CompleteAchievement174("A055", false)
            if presentGuild >= 20 then self:CompleteAchievement174("A054", false) end
            local playerDead = (encounter and encounter.playerDied) or (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player"))
            if playerDead then db.counters.raidSurviveStreak = 0
            else db.counters.raidSurviveStreak = (tonumber(db.counters.raidSurviveStreak) or 0) + 1 end
            if db.counters.raidSurviveStreak >= 10 then self:CompleteAchievement174("A059", false) end
            if kills >= 100 then self:CompleteAchievement174("A064", false) end
        end
    end
    local playerHealth = UnitHealth and tonumber(UnitHealth("player")) or 0
    local playerMax = UnitHealthMax and tonumber(UnitHealthMax("player")) or 0
    if playerMax > 0 and playerHealth > 0 and playerHealth / playerMax <= 0.01 then self:CompleteAchievement174("A084", false) end
    self.runtime.bossEncounter174 = nil
    self.runtime.lastBossVictory174 = { ts=self:Now(), zone=zoneKey, boss=bossKey }
    self.runtime.danceWindow174 = { started=self:Now(), expires=self:Now()+30, senders={}, originals={}, zone=zoneKey, kind="dance" }
    return true
end

local function MatchDeathName174(text)
    text = tostring(text or "")
    local formats = { getglobal and getglobal("UNITDIESOTHER") or nil, getglobal and getglobal("UNITDIESOTHER2") or nil, "%s dies." }
    local index, formatText, pattern
    for index=1,table.getn(formats) do
        formatText = formats[index]
        if type(formatText) == "string" and string.find(formatText, "%%s", 1, true) then
            pattern = string.gsub(formatText, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
            pattern = string.gsub(pattern, "%%%%s", "(.+)")
            local _, _, name = string.find(text, "^" .. pattern .. "$")
            if name and name ~= "" then return name end
        end
    end
    return nil
end

local EMOTE_PATTERNS_174 = {
    roar = { " roars", "roars!", "lets out a mighty roar" },
    dance = { " dances", "begins to dance", "bursts into dance" },
    kneel = { " kneels", "kneels before" },
}

function OTLGM:DetectEmoteType174(message)
    message = string.lower(tostring(message or ""))
    local kind, patterns, index
    for kind, patterns in pairs(EMOTE_PATTERNS_174) do
        for index=1,table.getn(patterns) do if string.find(message, patterns[index], 1, true) then return kind end end
    end
    return nil
end

function OTLGM:SendSecretConfirmation174(id, kind, state)
    if not state or not id or not kind then return false end
    local zone = state.zone or self:GetLocation174()
    local now = self:Now()
    local eventKey = NormalizeKey174(kind .. tostring(math.floor(now)) .. NormalizeName174(UnitName and UnitName("player") or ""))
    local payload = table.concat({ "H1", "SECRET", id, kind, zone or "", tostring(now), eventKey }, "^")
    local player = NormalizeName174(UnitName and UnitName("player") or "")
    local key, target
    for key in pairs(state.senders or {}) do
        target = state.originals and state.originals[key] or key
        if key ~= player and target and target ~= "" and self.QueueNetworkPayload then
            self:QueueNetworkPayload(payload, "WHISPER", target, 2, "achievements", "secret:" .. id .. ":" .. key)
        end
    end
    if state.senders and state.senders[player] then self:CompleteAchievement174(id, false) end
    return true
end

function OTLGM:HandleAchievementSecretMessage174(fields, sender, channel)
    if channel ~= "WHISPER" or type(fields) ~= "table" then return false end
    local id = tostring(fields[3] or "")
    local kind = tostring(fields[4] or "")
    local zone = NormalizeKey174(fields[5] or "")
    local timestamp = tonumber(fields[6]) or 0
    local eventKey = NormalizeKey174(fields[7] or "")
    local expected = { A081="roar", A082="dance", A083="kneel" }
    if expected[id] ~= kind or eventKey == "" then return false end
    local now = self:Now()
    local ttl = kind == "dance" and 35 or (kind == "kneel" and 20 or 15)
    if timestamp <= 0 or math.abs(now - timestamp) > ttl then return false end
    local currentZone = self:GetLocation174()
    if zone == "" or currentZone ~= zone then return false end
    self.runtime = self.runtime or {}
    local selfAt = tonumber(self.runtime.selfAchievementEmote174 and self.runtime.selfAchievementEmote174[kind]) or 0
    if now - selfAt > ttl then return false end
    if kind == "dance" then
        local victory = self.runtime.lastBossVictory174
        if not victory or now - (tonumber(victory.ts) or 0) > 35 or NormalizeKey174(victory.zone) ~= zone then return false end
    end
    self.runtime.secretConfirmSeen174 = self.runtime.secretConfirmSeen174 or {}
    if self.runtime.secretConfirmSeen174[eventKey] then return true end
    self.runtime.secretConfirmSeen174[eventKey] = now
    local key, value
    for key, value in pairs(self.runtime.secretConfirmSeen174) do
        if now - (tonumber(value) or 0) > 120 then self.runtime.secretConfirmSeen174[key] = nil end
    end
    return self:CompleteAchievement174(id, false) or true
end

function OTLGM:HandleAchievementEmote174(message, sender)
    local kind = self:DetectEmoteType174(message)
    if not kind then return end
    sender = ShortName174(sender or "")
    if sender == "" then
        local _, _, fallback = string.find(tostring(message or ""), "^([^%s]+)")
        sender = ShortName174(fallback or "")
    end
    local members = self:GetGuildMemberSet174()
    local name = NormalizeName174(sender)
    if name == "" or not members[name] then return end
    self.runtime = self.runtime or {}
    local now = self:Now()
    local player = NormalizeName174(UnitName and UnitName("player") or "")
    if name == player then
        self.runtime.selfAchievementEmote174 = self.runtime.selfAchievementEmote174 or {}
        self.runtime.selfAchievementEmote174[kind] = now
    end

    if kind == "dance" then
        local state = self.runtime.danceWindow174
        if not state or now > (state.expires or 0) then return end
        state.senders[name] = true
        state.originals = state.originals or {}
        state.originals[name] = sender
        if TableCount174(state.senders) >= 10 then
            self:SendSecretConfirmation174("A082", "dance", state)
            self.runtime.danceWindow174 = nil
        end
        return
    end

    local stateKey = kind .. "Window174"
    local state = self.runtime[stateKey]
    local ttl = kind == "kneel" and 15 or 10
    if not state or now > (state.expires or 0) then
        state = { started=now, expires=now+ttl, senders={}, originals={}, zone=self:GetLocation174(), kind=kind }
        self.runtime[stateKey] = state
    end
    state.senders[name] = true
    state.originals[name] = sender
    local count = TableCount174(state.senders)
    if kind == "roar" and count >= 10 then
        self:SendSecretConfirmation174("A081", "roar", state)
        self.runtime[stateKey] = nil
    elseif kind == "kneel" and count >= 13 then
        self:SendSecretConfirmation174("A083", "kneel", state)
        self.runtime[stateKey] = nil
    end
end

function OTLGM:GetAchievementProgress174(def)
    local db = self:EnsureAchievements174()
    if db.completed[def.id] then return def.required or 1, def.required or 1 end
    local key = def.progress
    if key == "groupNow" then return math.min(def.required, (self.runtime.achievementGroup174 and self.runtime.achievementGroup174.guild) or 0), def.required end
    if key == "fullParty" or key == "fullConnection" then
        local group = self.runtime.achievementGroup174
        if not group or not group.isParty then return 0, 5 end
        return math.min(5, group.guild or 0), 5
    end
    if key == "familiar" then
        local maximum = 0
        local name, value
        for name, value in pairs(db.familiar or {}) do if tonumber(value) and value > maximum then maximum = value end end
        return math.min(def.required, maximum), def.required
    end
    if key == "sharedPartners" or key == "sharedRanks" or key == "sharedZones" or key == "tradePartners" or key == "crafterContacts" or key == "dungeonZones" then return math.min(def.required, TableCount174(self:GetAchievementSet174(key))), def.required end
    if key == "sharedClasses" then
        local target = TableCount174(self:GetGuildClassTarget174())
        return math.min(target, TableCount174(self:GetAchievementSet174("sharedClasses"))), math.max(1, target)
    end
    if key == "professionScans" then
        local snapshot = self:GetLocalProfessionSnapshot174()
        return math.min(snapshot.scanned, snapshot.known), math.max(1, snapshot.known)
    end
    if key == "professionCap" then return 0, 1 end
    if key == "secretCount" then return math.min(3, tonumber(db.counters.secretCount) or 0), 3 end
    if key == "tenureDays" then return math.min(def.required, tonumber(db.counters.tenureDays) or 0), def.required end
    if key == "returnDays" then return 0, 30 end
    return math.min(def.required or 1, tonumber(db.counters[key]) or 0), def.required or 1
end

function OTLGM:GetAchievementPresentation174(def, complete)
    if def.secret and not complete then return def.name, "The title is your clue.", def.icon or QUESTION_ICON_174, true end
    return def.name, (def.secret and def.revealed or def.description), def.icon or QUESTION_ICON_174, false
end

function OTLGM:GetAchievementDisplayList174()
    local category = OTLGM_DB.settings.achievementCategory174 or "OVERVIEW"
    local filter = OTLGM_DB.settings.achievementFilter174 or "ALL"
    local search = string.lower(Trim174(OTLGM_DB.settings.achievementSearch174 or ""))
    local result = {}
    local index, def, complete, current, required, matches
    for index=1,table.getn(A174.catalog) do
        def = A174.catalog[index]
        complete = self:IsAchievementComplete174(def.id)
        current, required = self:GetAchievementProgress174(def)
        matches = search == "" or string.find(string.lower(def.name), search, 1, true) or string.find(string.lower(def.description), search, 1, true)
        if matches and (category == "OVERVIEW" or def.category == category) then
            if filter == "ALL" or (filter == "COMPLETE" and complete) or (filter == "PROGRESS" and not complete and current > 0 and not def.secret) or (filter == "LOCKED" and not complete and (def.secret or current <= 0)) then table.insert(result, def) end
        end
    end
    return result
end

function OTLGM:FocusAchievement174(id)
    local def = A174.byId[id]
    if not def then return false end
    OTLGM_DB.settings.achievementCategory174 = def.category
    OTLGM_DB.settings.achievementFilter174 = "ALL"
    OTLGM_DB.settings.achievementSearch174 = ""
    if self.ui.achievementSearch174 then self.ui.achievementSearch174:SetText("") end
    self.ui.achievementFocus174 = id
    local list = self:GetAchievementDisplayList174()
    local index
    for index=1,table.getn(list) do if list[index].id == id then self.ui.achievementOffset174 = math.floor((index - 1) / 6) * 6 break end end
    self:RefreshAchievements174()
    return true
end

function OTLGM:OpenAchievement174(id)
    if not A174.byId[id] then return false end
    if not self.ui or not self.ui.main then self:BuildUI() end
    if not self.ui or not self.ui.main then return false end
    if not self.ui.main:IsVisible() then if self.PrepareMainShow170 then self:PrepareMainShow170() end self.ui.main:Show() end
    self:ShowPage("achievements")
    return self:FocusAchievement174(id)
end

function OTLGM:BuildAchievementsPage174(page)
    self.ui.achievementTitleIcon174 = page:CreateTexture(nil, "OVERLAY")
    self.ui.achievementTitleIcon174:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -1)
    self.ui.achievementTitleIcon174:SetWidth(27) self.ui.achievementTitleIcon174:SetHeight(27)
    SetTexture174(self.ui.achievementTitleIcon174, "Interface\\Icons\\INV_Misc_Book_09")
    Text174(page, "GameFontNormalLarge", "Guild Achievements", 36, -2, 420, "LEFT")
    self.ui.achievementCount174 = Text174(page, "GameFontNormal", "0 / 87", 574, -4, 144, "RIGHT")
    self.ui.achievementCount174:SetTextColor(1.0, 0.82, 0.35)
    Text174(page, "GameFontNormalSmall", "Shared adventures, reliable milestones and personal guild history.", 36, -28, 520, "LEFT"):SetTextColor(0.65,0.65,0.62)

    local progressBack = Panel174(page, 36, -49, 510, 12, "background")
    self.ui.achievementProgressFill174 = progressBack:CreateTexture(nil, "ARTWORK")
    self.ui.achievementProgressFill174:SetPoint("LEFT", progressBack, "LEFT", 3, 0)
    self.ui.achievementProgressFill174:SetHeight(6)
    self.ui.achievementProgressFill174:SetTexture(0.92,0.58,0.12,0.95)
    self.ui.achievementProgressText174 = Text174(page, "GameFontNormalSmall", "", 556, -50, 162, "RIGHT")
    self.ui.achievementProgressText174:SetTextColor(0.72,0.67,0.58)

    self.ui.achievementFilterButtons174 = {}
    local filters = { {"ALL","All"}, {"COMPLETE","Completed"}, {"PROGRESS","In Progress"}, {"LOCKED","Locked"} }
    local index
    for index=1,4 do
        local key = filters[index][1]
        self.ui.achievementFilterButtons174[key] = Button174(page, filters[index][2], 338 + ((index-1)*96), -70, 90, 25, function()
            OTLGM_DB.settings.achievementFilter174 = key
            OTLGM.ui.achievementOffset174 = 0
            OTLGM.ui.achievementFocus174 = nil
            OTLGM:RefreshAchievements174()
        end, "utility")
    end

    self.ui.achievementSearch174 = CreateFrame("EditBox", "OTLGM_AchievementSearch174", page)
    if self.PrepareInteractiveControl170 then self:PrepareInteractiveControl170(self.ui.achievementSearch174, "editbox") end
    self.ui.achievementSearch174:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -70)
    self.ui.achievementSearch174:SetWidth(326) self.ui.achievementSearch174:SetHeight(25)
    self.ui.achievementSearch174:SetAutoFocus(false) self.ui.achievementSearch174:SetMaxLetters(60)
    self.ui.achievementSearch174:SetFontObject("GameFontHighlightSmall")
    self.ui.achievementSearch174:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=9, insets={left=5,right=5,top=4,bottom=4} })
    self.ui.achievementSearch174:SetBackdropColor(0.018,0.018,0.018,1) self.ui.achievementSearch174:SetBackdropBorderColor(0.30,0.26,0.20,1)
    self.ui.achievementSearch174:SetText(OTLGM_DB.settings.achievementSearch174 or "")
    self.ui.achievementSearch174:SetScript("OnTextChanged", function()
        OTLGM_DB.settings.achievementSearch174 = this:GetText() or ""
        OTLGM.ui.achievementOffset174 = 0
        OTLGM:RefreshAchievements174()
    end)
    self.ui.achievementSearch174:SetScript("OnEscapePressed", function() if this:GetText() ~= "" then this:SetText("") else this:ClearFocus() end end)

    local categories = Panel174(page, 0, -105, 170, 413, "background")
    Text174(categories, "GameFontNormalSmall", "CATEGORIES", 10, -10, 150, "LEFT"):SetTextColor(1,0.78,0.20)
    self.ui.achievementCategoryButtons174 = {}
    for index=1,table.getn(A174.categories) do
        local info = A174.categories[index]
        local key = info.key
        local button = Button174(categories, info.label, 8, -30 - ((index-1)*31), 154, 27, function()
            OTLGM_DB.settings.achievementCategory174 = key
            OTLGM.ui.achievementOffset174 = 0
            OTLGM.ui.achievementFocus174 = nil
            OTLGM:RefreshAchievements174()
        end, "normal")
        AddButtonIcon174(button, info.icon, 14)
        if button.text then button.text:SetWidth(82) end
        button.countText174 = Text174(button, "GameFontNormalSmall", "", 116, -8, 30, "RIGHT")
        self.ui.achievementCategoryButtons174[key] = button
    end
    Text174(categories, "GameFontNormalSmall", "OPTIONS", 10, -284, 150, "LEFT"):SetTextColor(1,0.78,0.20)
    self.ui.achievementPopupButton174 = Button174(categories, "Popups: On", 8, -306, 154, 27, function()
        OTLGM_DB.settings.achievementPopups174 = not OTLGM_DB.settings.achievementPopups174
        OTLGM:RefreshAchievements174()
    end, "utility")
    self.ui.achievementChatButton174 = Button174(categories, "Guild chat: On", 8, -337, 154, 27, function()
        OTLGM_DB.settings.achievementGuildChat174 = not OTLGM_DB.settings.achievementGuildChat174
        OTLGM:RefreshAchievements174()
    end, "utility")
    Text174(categories, "GameFontNormalSmall", "Shift-click an achievement to link it in the open WoW chat box.", 10, -372, 150, "LEFT"):SetTextColor(0.54,0.54,0.52)

    local list = Panel174(page, 180, -105, 538, 413, "surface")
    self.ui.achievementRows174 = {}
    for index=1,6 do
        local row = CreateFrame("Button", nil, list)
        if self.PrepareInteractiveControl170 then self:PrepareInteractiveControl170(row, "button") end
        row:SetPoint("TOPLEFT", list, "TOPLEFT", 8, -8 - ((index-1)*62))
        row:SetWidth(522) row:SetHeight(58)
        row:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=9, insets={left=2,right=2,top=2,bottom=2} })
        row.iconFallback174 = row:CreateTexture(nil, "ARTWORK")
        row.iconFallback174:SetPoint("LEFT", row, "LEFT", 8, 0) row.iconFallback174:SetWidth(42) row.iconFallback174:SetHeight(42) SetTexture174(row.iconFallback174, QUESTION_ICON_174)
        row.icon174 = row:CreateTexture(nil, "OVERLAY")
        row.icon174:SetPoint("LEFT", row, "LEFT", 8, 0) row.icon174:SetWidth(42) row.icon174:SetHeight(42)
        row.name174 = Text174(row, "GameFontNormal", "", 58, -8, 326, "LEFT")
        row.description174 = Text174(row, "GameFontNormalSmall", "", 58, -28, 340, "LEFT")
        row.description174:SetTextColor(0.64,0.64,0.61)
        row.status174 = Text174(row, "GameFontNormalSmall", "", 402, -10, 108, "RIGHT")
        row.date174 = Text174(row, "GameFontNormalSmall", "", 402, -32, 108, "RIGHT")
        row:SetScript("OnClick", function()
            if not this.achievement174 then return end
            if IsShiftKeyDown and IsShiftKeyDown() then
                if OTLGM:InsertAchievementLinkInBlizzardChat174(this.achievement174) then return end
                if OTLGM.InsertGuildChatLink then OTLGM:InsertGuildChatLink(OTLGM:GetAchievementLink174(this.achievement174), true) return end
            end
            OTLGM:FocusAchievement174(this.achievement174.id)
        end)
        row:SetScript("OnEnter", function()
            if not this.achievement174 then return end
            this:SetBackdropBorderColor(0.34,0.70,1.0,1)
            local complete = OTLGM:IsAchievementComplete174(this.achievement174.id)
            local name, description = OTLGM:GetAchievementPresentation174(this.achievement174, complete)
            GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
            GameTooltip:AddLine(name, 1,0.82,0.35)
            GameTooltip:AddLine(description, 1,1,1,true)
            GameTooltip:AddLine("Shift-click to link", 0.52,0.72,1.0)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() OTLGM:RefreshAchievements174() end)
        self.ui.achievementRows174[index] = row
    end
    self.ui.achievementPrev174 = Button174(list, "Previous", 8, -382, 82, 23, function() OTLGM.ui.achievementOffset174 = math.max(0,(OTLGM.ui.achievementOffset174 or 0)-6) OTLGM:RefreshAchievements174() end, "utility")
    self.ui.achievementStatus174 = Text174(list, "GameFontNormalSmall", "", 100, -388, 324, "CENTER")
    self.ui.achievementNext174 = Button174(list, "Next", 432, -382, 82, 23, function() OTLGM.ui.achievementOffset174 = (OTLGM.ui.achievementOffset174 or 0)+6 OTLGM:RefreshAchievements174() end, "utility")
    self.ui.achievementOffset174 = 0
end

function OTLGM:RefreshAchievements174()
    if not self.ui or not self.ui.achievementRows174 then return end
    local completeCount, total = self:GetAchievementCount174()
    self.ui.achievementCount174:SetText(tostring(completeCount) .. " / " .. tostring(total))
    local ratio = total > 0 and completeCount / total or 0
    self.ui.achievementProgressFill174:SetWidth(math.max(1, math.floor(504 * ratio)))
    self.ui.achievementProgressText174:SetText(tostring(math.floor(ratio * 100)) .. "% complete")
    local category = OTLGM_DB.settings.achievementCategory174 or "OVERVIEW"
    local filter = OTLGM_DB.settings.achievementFilter174 or "ALL"
    local key, button
    for key, button in pairs(self.ui.achievementCategoryButtons174 or {}) do
        Select174(button, key == category)
        local completed, categoryTotal = 0, 0
        local index, def
        for index=1,table.getn(A174.catalog) do
            def = A174.catalog[index]
            if key == "OVERVIEW" or def.category == key then categoryTotal = categoryTotal + 1 if self:IsAchievementComplete174(def.id) then completed = completed + 1 end end
        end
        if button.countText174 then button.countText174:SetText(tostring(completed) .. "/" .. tostring(categoryTotal)) end
    end
    for key, button in pairs(self.ui.achievementFilterButtons174 or {}) do Select174(button, key == filter) end
    SetText174(self.ui.achievementPopupButton174, "Popups: " .. (OTLGM_DB.settings.achievementPopups174 and "On" or "Off"))
    SetText174(self.ui.achievementChatButton174, "Guild chat: " .. (OTLGM_DB.settings.achievementGuildChat174 and "On" or "Off"))
    Select174(self.ui.achievementPopupButton174, OTLGM_DB.settings.achievementPopups174)
    Select174(self.ui.achievementChatButton174, OTLGM_DB.settings.achievementGuildChat174)

    local list = self:GetAchievementDisplayList174()
    local maximum = math.max(0, table.getn(list) - 6)
    local offset = math.max(0, math.min(maximum, self.ui.achievementOffset174 or 0))
    self.ui.achievementOffset174 = offset
    local index, row, def, complete, name, description, icon, secret, current, required, completedAt
    for index=1,6 do
        row = self.ui.achievementRows174[index]
        def = list[offset + index]
        if def then
            complete = self:IsAchievementComplete174(def.id)
            name, description, icon, secret = self:GetAchievementPresentation174(def, complete)
            current, required = self:GetAchievementProgress174(def)
            completedAt = self:GetAchievementCompletedAt174(def.id)
            row.achievement174 = def
            SetTexture174(row.icon174, icon)
            row.name174:SetText(name)
            row.description174:SetText(description)
            if complete then
                row:SetBackdropColor(0.075,0.052,0.020,0.98) row:SetBackdropBorderColor(0.68,0.44,0.12,1)
                row.icon174:SetVertexColor(1,1,1) row.name174:SetTextColor(1,0.82,0.35)
                row.status174:SetText("COMPLETE") row.status174:SetTextColor(0.35,0.95,0.42)
                row.date174:SetText(completedAt and date("%d %b %Y", completedAt) or "") row.date174:SetTextColor(0.62,0.62,0.60)
            elseif secret then
                row:SetBackdropColor(0.035,0.020,0.050,0.98) row:SetBackdropBorderColor(0.38,0.18,0.52,1)
                row.icon174:SetVertexColor(0.72,0.45,0.94) row.name174:SetTextColor(0.78,0.46,1.0)
                row.status174:SetText("SECRET") row.status174:SetTextColor(0.78,0.46,1.0) row.date174:SetText("")
            else
                row:SetBackdropColor(0.025,0.023,0.020,0.98) row:SetBackdropBorderColor(0.24,0.22,0.19,1)
                row.icon174:SetVertexColor(0.34,0.34,0.34) row.name174:SetTextColor(0.68,0.68,0.66)
                row.status174:SetText(required > 1 and (tostring(math.floor(current)) .. " / " .. tostring(math.floor(required))) or "LOCKED")
                row.status174:SetTextColor(current > 0 and 1.0 or 0.72, current > 0 and 0.78 or 0.72, current > 0 and 0.18 or 0.68)
                row.date174:SetText("")
            end
            if self.ui.achievementFocus174 == def.id then
                row:SetBackdropBorderColor(0.30,0.72,1.0,1)
            end
            row:Show()
        else row.achievement174 = nil row:Hide() end
    end
    self.ui.achievementStatus174:SetText(table.getn(list)==0 and "No achievements match this view." or (tostring(offset+1) .. "-" .. tostring(math.min(offset+6,table.getn(list))) .. " of " .. tostring(table.getn(list))))
    if self.SetControlEnabled170 then
        self:SetControlEnabled170(self.ui.achievementPrev174, offset > 0, "This is the first page.")
        self:SetControlEnabled170(self.ui.achievementNext174, offset < maximum, "There are no more achievements.")
        if self.ApplyButtonSkin then self:ApplyButtonSkin(self.ui.achievementPrev174) self:ApplyButtonSkin(self.ui.achievementNext174) end
    end
end

local TOAST_ICONS_174 = {
    achievement="Interface\\Icons\\INV_Misc_Book_09", raid="Interface\\Icons\\INV_BannerPVP_02",
    announcement="Interface\\Icons\\INV_Misc_Note_01", group="Interface\\Icons\\INV_Sword_04",
    response="Interface\\Icons\\INV_Letter_15", crafting="Interface\\Icons\\Trade_BlackSmithing",
    reaction="Interface\\Icons\\Spell_Holy_PrayerOfSpirit", mention="Interface\\Icons\\INV_Letter_15",
    background="Interface\\Icons\\INV_Misc_Rune_01",
}

function OTLGM:BuildAchievementToast174()
    if self.ui.guildToasts174 or not UIParent then return end
    self.ui.guildToasts174 = {}
    local toastIndex
    for toastIndex=1,3 do
        local toast = CreateFrame("Button", "OTLGM_GuildToast174_" .. tostring(toastIndex), UIParent)
        if self.PrepareInteractiveControl170 then self:PrepareInteractiveControl170(toast, "button") end
        toast.toastIndex174 = toastIndex
        toast:SetWidth(350) toast:SetHeight(64)
        toast:SetPoint("TOP", UIParent, "TOP", 0, -34 - ((toastIndex-1)*70))
        toast:SetFrameStrata("DIALOG")
        toast:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileSize=16, edgeSize=18, insets={left=6,right=6,top=6,bottom=6} })
        toast:SetBackdropColor(0.015,0.012,0.008,0.985) toast:SetBackdropBorderColor(0.95,0.65,0.18,1)
        toast.icon = toast:CreateTexture(nil,"OVERLAY")
        toast.icon:SetPoint("LEFT",toast,"LEFT",11,0) toast.icon:SetWidth(36) toast.icon:SetHeight(36)
        toast.title = Text174(toast,"GameFontNormalSmall","GUILD UPDATE",54,-7,250,"LEFT")
        toast.nameText = Text174(toast,"GameFontNormal","",54,-22,250,"LEFT")
        toast.bodyText = Text174(toast,"GameFontNormalSmall","",54,-40,252,"LEFT")
        toast.bodyText:SetTextColor(0.72,0.72,0.70)
        toast.hintText = Text174(toast,"GameFontNormalSmall","Open",294,-45,34,"RIGHT")
        toast.hintText:SetTextColor(0.45,0.62,0.82)
        toast.close174 = Button174(toast, "x", 321, -5, 21, 21, function(button)
            local parent = button and button:GetParent()
            OTLGM:DismissGuildToast174(parent and parent.toastIndex174 or 1)
        end, "utility")
        toast:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        toast:SetScript("OnClick", function()
            if arg1 == "RightButton" then OTLGM:DismissGuildToast174(this.toastIndex174) return end
            local data = this.toastData174
            if not data then return end
            local ok = pcall(function()
                if data.achievementId then OTLGM:OpenAchievement174(data.achievementId)
                elseif data.category == "mention" and OTLGM.OpenGuildChatMention174 then OTLGM:OpenGuildChatMention174(data)
                elseif data.targetPage and OTLGM.ShowPage then
                    if OTLGM.ui and OTLGM.ui.main and not OTLGM.ui.main:IsVisible() then OTLGM.ui.main:Show() end
                    OTLGM:ShowPage(data.targetPage)
                end
            end)
            OTLGM:DismissGuildToast174(this.toastIndex174)
            if not ok and OTLGM and OTLGM.SetStatus then OTLGM:SetStatus("Could not open this notification. The item remains available in Guild Inbox.") end
        end)
        toast:SetScript("OnEnter", function()
            this.hovered174 = true
            OTLGM.runtime.achievementToastHideAt174 = OTLGM.runtime.achievementToastHideAt174 or {}
            OTLGM.runtime.achievementToastHideAt174[this.toastIndex174] = nil
            this:SetBackdropBorderColor(0.35,0.72,1.0,1)
        end)
        toast:SetScript("OnLeave", function()
            this.hovered174 = nil
            local data = this.toastData174
            if data and data.priority == "CRITICAL" then this:SetBackdropBorderColor(1.0,0.24,0.14,1)
            elseif data and data.priority == "ACTION" then this:SetBackdropBorderColor(0.30,0.72,1.0,1)
            elseif data and data.category == "achievement" then this:SetBackdropBorderColor(0.95,0.65,0.18,1)
            else this:SetBackdropBorderColor(0.72,0.48,0.18,1) end
            if data then
                OTLGM.runtime.achievementToastHideAt174 = OTLGM.runtime.achievementToastHideAt174 or {}
                OTLGM.runtime.achievementToastHideAt174[this.toastIndex174] = OTLGM:Now() + (data.duration or 7)
            end
        end)
        toast:Hide()
        self.ui.guildToasts174[toastIndex] = toast
    end
    self.ui.achievementToast174 = self.ui.guildToasts174[1]
end

function OTLGM:ShowGuildToastNow174(data, preferredIndex)
    self:BuildAchievementToast174()
    local toasts = self.ui.guildToasts174 or {}
    local toast, index
    if preferredIndex and toasts[preferredIndex] and not toasts[preferredIndex]:IsVisible() then toast = toasts[preferredIndex] index = preferredIndex end
    if not toast then
        for index=1,table.getn(toasts) do if not toasts[index]:IsVisible() then toast = toasts[index] break end end
    end
    if not toast or not data then return false end
    toast.toastData174 = data
    SetTexture174(toast.icon, data.icon or TOAST_ICONS_174[data.category or "background"] or QUESTION_ICON_174)
    toast.title:SetText(string.upper(data.header or "GUILD UPDATE"))
    toast.nameText:SetText(data.title or "Order of the Lion")
    toast.bodyText:SetText(data.body or "")
    toast.hintText:SetText((data.achievementId or data.targetPage or data.category == "mention") and "Open" or "")
    if data.priority == "CRITICAL" then toast:SetBackdropBorderColor(1.0,0.24,0.14,1) toast.title:SetTextColor(1.0,0.38,0.22)
    elseif data.priority == "ACTION" then toast:SetBackdropBorderColor(0.30,0.72,1.0,1) toast.title:SetTextColor(0.48,0.80,1.0)
    elseif data.category == "achievement" then toast:SetBackdropBorderColor(0.95,0.65,0.18,1) toast.title:SetTextColor(1.0,0.72,0.20)
    else toast:SetBackdropBorderColor(0.72,0.48,0.18,1) toast.title:SetTextColor(1.0,0.78,0.30) end
    toast:Show()
    self.runtime.achievementToastHideAt174 = self.runtime.achievementToastHideAt174 or {}
    self.runtime.achievementToastHideAt174[toast.toastIndex174] = self:Now() + (data.duration or 7)
    if self.StartExperienceMotion170 then self:StartExperienceMotion170(toast, 0.35, 1, 0.10) end
    return true
end

function OTLGM:QueueGuildToast174(data)
    if not data then return false end
    self.runtime = self.runtime or {}
    self.runtime.guildToastQueue174 = self.runtime.guildToastQueue174 or {}
    self:BuildAchievementToast174()
    if self:ShowGuildToastNow174(data) then return true end
    table.insert(self.runtime.guildToastQueue174, data)
    while table.getn(self.runtime.guildToastQueue174) > 12 do table.remove(self.runtime.guildToastQueue174, 1) end
    return true
end

function OTLGM:DismissGuildToast174(index)
    index = tonumber(index) or 1
    local toast = self.ui and self.ui.guildToasts174 and self.ui.guildToasts174[index]
    if toast then toast.toastData174 = nil toast:Hide() end
    self.runtime.achievementToastHideAt174 = self.runtime.achievementToastHideAt174 or {}
    self.runtime.achievementToastHideAt174[index] = nil
    local queue = self.runtime.guildToastQueue174 or {}
    if table.getn(queue) > 0 then self:ShowGuildToastNow174(table.remove(queue, 1), index) end
end

function OTLGM:ShowAchievementToast174(def)
    if not def then return end
    self:QueueGuildToast174({ category="achievement", header="Guild Achievement Earned", title=def.name, body=def.secret and (def.revealed or def.description) or def.description, icon=def.icon, achievementId=def.id, targetPage="achievements", duration=7 })
    if PlaySound then pcall(PlaySound, "LevelUp") end
end

function OTLGM:OpenGuildChatMention174(data)
    if not self.ui or not self.ui.main then self:BuildUI() end
    if self.ui and self.ui.main and not self.ui.main:IsVisible() then self.ui.main:Show() end
    local channel = data and data.mentionChannel == "OFFICER" and "OFFICER" or "GUILD"
    if self.SetGuildChatChannel then self:SetGuildChatChannel(channel) end
    self:ShowPage("guildchat")
    local messages = self.GetGuildChatMessages and self:GetGuildChatMessages(channel) or {}
    local target = tonumber(data and data.mentionTs) or 0
    local wantedSender = NormalizeName174(data and data.mentionSender or "")
    local wantedText = tostring(data and data.mentionText or "")
    local matchedIndex = nil
    local index, message
    for index=1,table.getn(messages) do
        message = messages[index]
        if tonumber(message.ts) == target
            and (wantedSender == "" or NormalizeName174(message.sender) == wantedSender)
            and (wantedText == "" or tostring(message.text or "") == wantedText) then
            matchedIndex = index
            break
        end
    end
    if not matchedIndex and target > 0 then
        for index=table.getn(messages),1,-1 do
            message = messages[index]
            if tonumber(message.ts) == target then matchedIndex = index break end
        end
    end
    self.ui.chatOffsets = self.ui.chatOffsets or { GUILD=0, OFFICER=0 }
    if matchedIndex then
        local rows = 18
        self.ui.chatOffsets[channel] = math.max(0, table.getn(messages) - matchedIndex - math.floor(rows / 2))
        self.runtime.highlightChatTimestamp174 = target
    else
        self.ui.chatOffsets[channel] = 0
        if self.SetStatus then self:SetStatus("The mentioned message is no longer in the local chat history.") end
    end
    if self.RefreshGuildChatPage then self:RefreshGuildChatPage() end
end

function OTLGM:RefreshGuildChatOnline174()
    if not self.ui or not self.ui.guildChatOnline174 then return end
    local db = self:GetGuildDB()
    local online = tonumber(db and db.lastOnline) or 0
    self.ui.guildChatOnline174:SetText(self.colors.green .. tostring(online) .. " online now" .. self.colors.reset)
end

function OTLGM:InstallAchievementHyperlinks174()
    if self.achievementHyperlinksInstalled174 then return end
    self.achievementHyperlinksInstalled174 = true
    local baseSetItemRef = SetItemRef
    SetItemRef = function(link, text, mouseButton)
        local prefix = "otlgmachievement:"
        if string.sub(tostring(link or ""), 1, string.len(prefix)) == prefix then
            local id = string.sub(link, string.len(prefix) + 1)
            local _, _, safeId = string.find(id, "^([A-Z0-9_]+)")
            id = safeId or ""
            local def = A174.byId[id]
            if def and IsShiftKeyDown and IsShiftKeyDown() and OTLGM:InsertAchievementLinkInBlizzardChat174(def) then return end
            if id ~= "" then OTLGM:OpenAchievement174(id) end
            return
        end
        if baseSetItemRef then return baseSetItemRef(link, text, mouseButton) end
    end
    local baseGuildHyperlink = self.HandleGuildChatHyperlink
    if baseGuildHyperlink then
        self.HandleGuildChatHyperlink = function(owner, link, display, mouseButton)
            local prefix = "otlgmachievement:"
            if string.sub(tostring(link or ""), 1, string.len(prefix)) == prefix then
                local id = string.sub(link, string.len(prefix) + 1)
                local _, _, safeId = string.find(id, "^([A-Z0-9_]+)")
                id = safeId or ""
                local def = A174.byId[id]
                if def and IsShiftKeyDown and IsShiftKeyDown() and owner:InsertAchievementLinkInBlizzardChat174(def) then return end
                if id ~= "" then owner:OpenAchievement174(id) end
                return
            end
            return baseGuildHyperlink(owner, link, display, mouseButton)
        end
    end
end

function OTLGM:InstallAchievements174()
    if A174.installed then return end
    A174.installed = true
    self:EnsureAchievements174()
    self:InstallAchievementHyperlinks174()

    local BaseBuildUI = self.BuildUI
    self.BuildUI = function(owner)
        BaseBuildUI(owner)
        if owner.ui.pages and not owner.ui.pages.achievements then
            local page = CreateFrame("Frame", nil, owner.ui.content)
            page:SetPoint("TOPLEFT", owner.ui.content, "TOPLEFT", 14, -14)
            page:SetWidth(756) page:SetHeight(532) page:Hide()
            owner.ui.pages.achievements = page
            owner:BuildAchievementsPage174(page)
            local button = Button174(owner.ui.sidebar, "Guild Achievements", 12, -260, 142, 22, function() OTLGM:ShowPage("achievements") end, "normal")
            AddButtonIcon174(button, "Interface\\Icons\\INV_Misc_Book_09", 15)
            owner.ui.navButtons.achievements = button
            owner.ui.guildChatOnline174 = Text174(owner.ui.pages.guildchat, "GameFontNormalSmall", "", 548, -6, 170, "RIGHT")
            owner:BuildAchievementToast174()
            owner:RefreshNavigation()
        end
        if OTLGM_DB.settings.lastPage == "achievements" then owner:ShowPage("achievements") end
    end

    local BaseShowPage = self.ShowPage
    self.ShowPage = function(owner, pageKey)
        BaseShowPage(owner, pageKey)
        if pageKey == "achievements" then owner:RefreshAchievements174() end
    end

    local BaseRefreshVisible = self.RefreshVisiblePage
    self.RefreshVisiblePage = function(owner)
        BaseRefreshVisible(owner)
        if owner.ui and owner.ui.currentPage == "achievements" then owner:RefreshAchievements174() end
    end

    local BaseRefreshChat = self.RefreshGuildChatPage
    self.RefreshGuildChatPage = function(owner)
        local result = BaseRefreshChat(owner)
        owner:RefreshGuildChatOnline174()
        local target = tonumber(owner.runtime and owner.runtime.highlightChatTimestamp174) or 0
        local now = owner:Now()
        local index, row
        for index=1,table.getn(owner.ui and owner.ui.chatRows or {}) do
            row = owner.ui.chatRows[index]
            if not row.jumpHighlight174 then
                row.jumpHighlight174 = row:CreateTexture(nil, "BORDER")
                row.jumpHighlight174:SetAllPoints(row)
                row.jumpHighlight174:SetTexture(0.08, 0.36, 0.72, 0.30)
                row.jumpHighlight174:Hide()
            end
            if target > 0 and row.chatData and tonumber(row.chatData.ts) == target then
                row.jumpHighlight174:Show()
                owner.runtime.highlightChatUntil174 = now + 8
            else
                row.jumpHighlight174:Hide()
            end
        end
        return result
    end

    local BaseScanProfession = self.ScanCurrentProfession
    if BaseScanProfession then
        self.ScanCurrentProfession = function(owner, mode, attempt)
            local a,b,c,d = BaseScanProfession(owner, mode, attempt)
            owner.runtime = owner.runtime or {}
            owner.runtime.achievementProfessionDue174 = owner:Now() + 1
            return a,b,c,d
        end
    end

    local BaseReaction = self.SetCommunityReaction
    if BaseReaction then
        self.SetCommunityReaction = function(owner, targetType, targetId, reaction, force)
            local result = BaseReaction(owner, targetType, targetId, reaction, force)
            if result and targetType == "ANN" and reaction and reaction ~= "NONE" then owner:CompleteAchievement174("A007", false) end
            return result
        end
    end

    local BaseApplyGroup = self.ApplyToPveGroup
    if BaseApplyGroup then
        self.ApplyToPveGroup = function(owner, groupId, role, note)
            local group = owner.EnsurePveDB and owner:EnsurePveDB().requests[groupId]
            local ok, record = BaseApplyGroup(owner, groupId, role, note)
            if ok then owner:RecordGroupApplication174(group, record) end
            return ok, record
        end
    end

    local BaseRemoteApplication = self.ApplyRemotePveApplication
    if BaseRemoteApplication then
        self.ApplyRemotePveApplication = function(owner, fields, sender)
            local result = BaseRemoteApplication(owner, fields, sender)
            local pve = owner.EnsurePveDB and owner:EnsurePveDB()
            local id = fields and fields[3]
            if result and pve and id and pve.applications[id] then owner:RecordAcceptedApplication174(pve.applications[id]) end
            return result
        end
    end

    local BaseCraftResponse = self.AddCraftingResponse
    if BaseCraftResponse then
        self.AddCraftingResponse = function(owner, requestId, text, canHelp)
            local craft = owner.EnsureCraftingDB and owner:EnsureCraftingDB()
            local request = craft and craft.requests and craft.requests[requestId]
            local ok, record = BaseCraftResponse(owner, requestId, text, canHelp)
            if ok then owner:RecordCraftingResponse174(request, record) end
            return ok, record
        end
    end

    local BaseNotifyEvent = self.NotifyEvent152
    if BaseNotifyEvent then
        self.NotifyEvent152 = function(owner, category, eventKey, title, body, priority, remote, targetPage)
            local pref = owner.GetNotificationPreference152 and owner:GetNotificationPreference152(category)
            local showVisual = pref and pref.visual
            if pref and showVisual then pref.visual = false end
            local ok, result = pcall(BaseNotifyEvent, owner, category, eventKey, title, body, priority, remote, targetPage)
            if pref and showVisual then pref.visual = true end
            if not ok then error(result) end
            if result and showVisual and category ~= "background" then
                local headers = { raid="Raid Update", announcement="Guild Announcement", group="Group Finder", response="New Response", crafting="Crafting Network", reaction="Guild Reaction", mention="Guild Chat Mention" }
                local data = { category=category, header=headers[category] or "Guild Update", title=title or "Order of the Lion", body=body or "", priority=priority, targetPage=targetPage, duration=(priority == "CRITICAL" or priority == "ACTION") and 8 or 7 }
                if category == "mention" and owner.runtime and owner.runtime.pendingMentionTarget174 then
                    data.mentionChannel = owner.runtime.pendingMentionTarget174.channel
                    data.mentionTs = owner.runtime.pendingMentionTarget174.ts
                    data.mentionSender = owner.runtime.pendingMentionTarget174.sender
                    data.mentionText = owner.runtime.pendingMentionTarget174.text
                end
                owner:QueueGuildToast174(data)
            end
            return result
        end
    end

    local BaseTimers = self.ProcessQuality156Timers
    self.ProcessQuality156Timers = function(owner)
        if BaseTimers then BaseTimers(owner) end
        local now = owner:Now()
        owner:ProcessAchievementGuildAnnouncements174()
        if owner.runtime.achievementGroupTickAt174 and now >= owner.runtime.achievementGroupTickAt174 then owner:UpdateGroupSession174(false) end
        if owner.runtime.achievementRaidTickAt174 and now >= owner.runtime.achievementRaidTickAt174 then owner:UpdateRaidPresence174(false) end
        if owner.runtime.achievementEquipmentDue174 and now >= owner.runtime.achievementEquipmentDue174 then owner.runtime.achievementEquipmentDue174 = nil end
        if owner.runtime.achievementGroupDue174 and now >= owner.runtime.achievementGroupDue174 then owner.runtime.achievementGroupDue174 = nil owner:UpdateGroupSession174(false) owner:UpdateRaidPresence174(false) end
        if owner.runtime.achievementProfessionDue174 and now >= owner.runtime.achievementProfessionDue174 then owner.runtime.achievementProfessionDue174 = nil owner:CheckProfessionAchievements174(false) end
        local toastIndex, hideAt
        for toastIndex, hideAt in pairs(owner.runtime.achievementToastHideAt174 or {}) do
            if hideAt and now >= hideAt then owner:DismissGuildToast174(toastIndex) end
        end
        if owner.runtime.highlightChatUntil174 and now >= owner.runtime.highlightChatUntil174 then
            owner.runtime.highlightChatUntil174 = nil
            owner.runtime.highlightChatTimestamp174 = nil
            local rowIndex, chatRow
            for rowIndex=1,table.getn(owner.ui and owner.ui.chatRows or {}) do
                chatRow = owner.ui.chatRows[rowIndex]
                if chatRow.jumpHighlight174 then chatRow.jumpHighlight174:Hide() end
            end
        end
        if owner.runtime.bossEncounter174 and now - (owner.runtime.bossEncounter174.started or now) > 600 then owner.runtime.bossEncounter174 = nil end
        local keys = { "roarWindow174", "kneelWindow174", "danceWindow174" }
        local index, state
        for index=1,table.getn(keys) do state = owner.runtime[keys[index]] if state and now > (state.expires or 0) then owner.runtime[keys[index]] = nil end end
    end
end

local eventFrame174 = CreateFrame("Frame", "OTLGM_AchievementsEvent174")
local events174 = {
    "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LOGOUT", "ZONE_CHANGED_NEW_AREA", "MINIMAP_ZONE_CHANGED",
    "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE", "GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE", "CHAT_MSG_TEXT_EMOTE",
    "PLAYER_TARGET_CHANGED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "CHAT_MSG_COMBAT_HOSTILE_DEATH",
    "CHAT_MSG_COMBAT_FRIENDLY_DEATH", "TRADE_SHOW", "TRADE_ACCEPT_UPDATE", "TRADE_CLOSED", "TRADE_REQUEST_CANCEL",
    "TRADE_SKILL_SHOW", "CRAFT_SHOW", "TRADE_SKILL_UPDATE", "CRAFT_UPDATE", "SKILL_LINES_CHANGED",
}
local eventIndex174
for eventIndex174=1,table.getn(events174) do eventFrame174:RegisterEvent(events174[eventIndex174]) end
eventFrame174:SetScript("OnEvent", function()
    if not OTLGM then return end
    OTLGM.runtime = OTLGM.runtime or {}
    if event == "PLAYER_LOGIN" then
        OTLGM:InstallAchievements174()
        local db = OTLGM:EnsureAchievements174()
        OTLGM:UpdateMembershipPeriod174()
        local silent = not db.baseline174
        OTLGM:CheckStoredReactionAchievement174(silent)
        OTLGM:CheckProfessionAchievements174(silent)
        OTLGM:UpdateGroupSession174(silent)
        OTLGM:UpdateRaidPresence174(silent)
        OTLGM:CheckLegacyAchievements174(silent, true)
        OTLGM:CheckSecretKeeper174(silent)
        db.baseline174 = true
    elseif event == "PLAYER_ENTERING_WORLD" then
        OTLGM:UpdateMembershipPeriod174()
        OTLGM:UpdateGroupSession174(false)
        OTLGM:UpdateRaidPresence174(false)
        OTLGM:CheckLegacyAchievements174(false, false)
    elseif event == "PLAYER_LOGOUT" then
        OTLGM:FinalizeGroupSession174(OTLGM:Now(), true)
        local db = OTLGM:EnsureAchievements174()
        db.dates.lastLoginAt = OTLGM:Now()
    elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" or event == "GUILD_ROSTER_UPDATE" or event == "PLAYER_GUILD_UPDATE" then
        if (event == "GUILD_ROSTER_UPDATE" or event == "PLAYER_GUILD_UPDATE") and OTLGM.RefreshAchievementRosterCache174 then OTLGM:RefreshAchievementRosterCache174(true) end
        if event == "PLAYER_GUILD_UPDATE" then OTLGM:UpdateMembershipPeriod174() end
        OTLGM.runtime.achievementGroupDue174 = OTLGM:Now() + 1
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "MINIMAP_ZONE_CHANGED" then
        OTLGM:UpdateGroupSession174(false)
        OTLGM:UpdateRaidPresence174(false)
        OTLGM.runtime.bossEncounter174 = nil
        OTLGM.runtime.roarWindow174 = nil
        OTLGM.runtime.kneelWindow174 = nil
        OTLGM.runtime.danceWindow174 = nil
    elseif event == "CHAT_MSG_TEXT_EMOTE" then
        OTLGM:HandleAchievementEmote174(arg1, arg2)
    elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_REGEN_DISABLED" then
        local target = UnitName and UnitName("target")
        if target then OTLGM:StartBossEncounter174(target) end
    elseif event == "PLAYER_REGEN_ENABLED" then
        local encounter = OTLGM.runtime.bossEncounter174
        if encounter and OTLGM:Now() - (encounter.started or 0) > 20 then OTLGM.runtime.bossEncounter174 = nil end
    elseif event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
        local boss = MatchDeathName174(arg1)
        if boss then OTLGM:HandleBossVictory174(boss) end
    elseif event == "CHAT_MSG_COMBAT_FRIENDLY_DEATH" then
        local name = MatchDeathName174(arg1)
        if name then OTLGM:MarkBossEncounterDeath174(name) end
    elseif event == "TRADE_SKILL_SHOW" or event == "CRAFT_SHOW" or event == "TRADE_SKILL_UPDATE" or event == "CRAFT_UPDATE" or event == "SKILL_LINES_CHANGED" then
        OTLGM.runtime.achievementProfessionDue174 = OTLGM:Now() + 1
    elseif event == "TRADE_SHOW" then
        OTLGM:BeginTradeTracking174()
    elseif event == "TRADE_ACCEPT_UPDATE" then
        OTLGM:UpdateTradeTracking174()
        if OTLGM.runtime.trade174 and tonumber(arg1) == 1 and tonumber(arg2) == 1 then OTLGM.runtime.trade174.accepted = true end
    elseif event == "TRADE_CLOSED" then
        OTLGM:UpdateTradeTracking174()
        OTLGM:FinishTradeTracking174(OTLGM.runtime.trade174 and OTLGM.runtime.trade174.accepted)
    elseif event == "TRADE_REQUEST_CANCEL" then
        OTLGM:FinishTradeTracking174(false)
    end
end)

OTLGM:RegisterModule("Achievements174", { layer="feature", catalog=46, schema=14, eventDriven=true })
