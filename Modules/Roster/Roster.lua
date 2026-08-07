-- Order of the Lion Guild Manager
-- Roster, history, analytics, presence and recruitment domain stages.

OTLGM.confirmScanAt = nil
OTLGM.scanReason = nil

local function ATrim(text)
    if not text then return "" end
    return string.gsub(text, "^%s*(.-)%s*$", "%1")
end

local function ANormalizeName(name)
    name = ATrim(name or "")
    name = string.gsub(name, "%-.*$", "")
    return string.lower(name)
end

local function TableCount(tbl)
    local count = 0
    local key
    for key in pairs(tbl or {}) do count = count + 1 end
    return count
end

local function CopySimpleTable(source)
    local target = {}
    local key, value
    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            target[key] = CopySimpleTable(value)
        else
            target[key] = value
        end
    end
    return target
end

-- Rich profession dictionary. Short ambiguous aliases are checked as whole words
-- and usually require a compact note or an adjacent skill number.
OTLGM.professionDefinitions = {
    {
        key = "ALCHEMY", label = "Alchemy",
        terms = { "alchemy", "alchemist", "potion maker", "potionmaster", "master of potions" },
        shortTerms = { "alch", "alchy", "alchi", "alc", "pots", "potions", "pot", "flasks", "flask", "transmute", "transmuter" },
        typos = { "alchemi", "alchemie", "alchimy", "alcemist", "alchemyst" },
    },
    {
        key = "BLACKSMITHING", label = "Blacksmithing",
        terms = { "blacksmithing", "blacksmith", "weapon smith", "weaponsmith", "armor smith", "armorsmith", "smithing" },
        shortTerms = { "bsmith", "smith", "weaponsmith", "armorsmith", "weapon smith", "armor smith" },
        strictTerms = { "bs" },
        typos = { "blacksmithng", "blacksmitting", "blacksmth", "blacksmiting" },
    },
    {
        key = "ENCHANTING", label = "Enchanting",
        terms = { "enchanting", "enchanter", "enchantments", "disenchanting", "disenchanter" },
        shortTerms = { "ench", "enchant", "disenchant", "disenchanting", "deing", "chant", "chants" },
        strictTerms = { "de", "d/e", "d e" },
        typos = { "enchantng", "enchaning", "enchating", "enchenter" },
    },
    {
        key = "ENGINEERING", label = "Engineering",
        terms = { "engineering", "engineer", "gnomish engineering", "goblin engineering" },
        shortTerms = { "engi", "engy", "engine", "gnomish", "goblin engi", "gob engi", "gnome engi" },
        strictTerms = { "eng" },
        typos = { "enginering", "engeneering", "enginearing", "engeneer" },
    },
    {
        key = "JEWELCRAFTING", label = "Jewelcrafting",
        terms = { "jewelcrafting", "jewelcrafter", "jewel crafter", "gemcutter", "gem cutter", "prospector", "prospecting", "jeweler", "jeweller", "jc" },
        shortTerms = { "jewel", "jewels", "gemcut", "gem cutter", "gems", "prospect", "prospecting", "jcraft", "jwc" },
        strictTerms = { "jc" },
        typos = { "jewelcraftng", "jewelcrafring", "jewelcrft", "jewelcrating" },
    },
    {
        key = "HERBALISM", label = "Herbalism",
        terms = { "herbalism", "herbalist", "herb gathering" },
        shortTerms = { "herb", "herbs", "herbing", "herba", "herbal", "gather herbs" },
        typos = { "herbalizm", "herbalim", "herbalistm" },
    },
    {
        key = "LEATHERWORKING", label = "Leatherworking",
        terms = { "leatherworking", "leatherworker", "tribal leatherworking", "dragonscale leatherworking", "elemental leatherworking" },
        shortTerms = { "leather", "lworker", "tribal lw", "dragonscale lw", "elemental lw", "leath" },
        strictTerms = { "lw" },
        typos = { "leatherwoking", "leatherworkng", "letherworking", "leatherwoker" },
    },
    {
        key = "MINING", label = "Mining",
        terms = { "mining", "miner", "ore gathering" },
        shortTerms = { "mine", "mines", "ores", "ore", "smelt", "smelting", "smelter" },
        strictTerms = { "min" },
        typos = { "minning", "mineing", "mning" },
    },
    {
        key = "SKINNING", label = "Skinning",
        terms = { "skinning", "skinner", "hide gathering" },
        shortTerms = { "skin", "skins", "hides", "hide", "skn" },
        typos = { "skining", "skinnig", "skinnng" },
    },
    {
        key = "TAILORING", label = "Tailoring",
        terms = { "tailoring", "tailor", "mooncloth tailor", "cloth crafting" },
        shortTerms = { "tailor", "sewing", "cloth", "tail", "mooncloth", "seamstress" },
        typos = { "tailorng", "tayloring", "tailering", "taloring" },
    },
    {
        key = "FIRSTAID", label = "First Aid",
        terms = { "first aid", "firstaid", "bandage maker" },
        shortTerms = { "bandage", "bandages", "medic", "healer bandages" },
        strictTerms = { "fa" },
        typos = { "firstiad", "frist aid", "first ade" },
    },
}

OTLGM.rankInformation = {
    {
        number = "!", name = "Muted", kind = "Restricted",
        aliases = { "muted", "mute", "tormented", "punished", "restricted", "warning" },
        receive = "Assigned temporarily by leadership after a serious warning, rule violation or refusal to follow guild decisions.",
        access = "Restricted disciplinary status. Normal guild privileges remain limited until leadership reviews the situation."
    },
    {
        number = "1", name = "Guest", kind = "Visitor",
        aliases = { "guest", "1 - guest" },
        receive = "Join the guild as a newcomer or visitor.",
        access = "Introductory rank while learning the guild. Join Discord to become a full community member."
    },
    {
        number = "2", name = "Lion", kind = "Social",
        aliases = { "lion", "2 - lion", "member" },
        receive = "Join the guild Discord using your in-game character name.",
        access = "Full guild membership and access to the main community information and activities."
    },
    {
        number = "3", name = "Loyal", kind = "Social",
        aliases = { "loyal", "3 - loyal", "active", "veteran" },
        receive = "Be consistently active, helpful, trustworthy and involved in guild life.",
        access = "Recognized trusted member with a stronger standing inside the community."
    },
    {
        number = "4", name = "Raider", kind = "Raiding",
        aliases = { "raider", "4 - raider", "community raider", "trial raider" },
        receive = "Receive raid approval, follow preparation rules and take part reliably in guild runs.",
        access = "Guild raider status and access to raid organization appropriate to the current team."
    },
    {
        number = "5", name = "Core Raider", kind = "Raiding",
        aliases = { "core raider", "5 - core raider", "the devoted" },
        receive = "Earn a stable place in the main roster through preparation, attendance, reliability and teamwork.",
        access = "Main raid-roster recognition and priority involvement in organized guild progression."
    },
    {
        number = "6", name = "Helper", kind = "Leadership",
        aliases = { "helper", "6 - helper" },
        receive = "Apply through the Helper application and prove reliable, calm and genuinely useful to members.",
        access = "First staff rank: helps members, Discord organization, guidance and daily guild support."
    },
    {
        number = "7", name = "Officer", kind = "Leadership",
        aliases = { "officer", "7 - officer", "- officer -", "manager" },
        receive = "Chosen through trust, merit and proven service. Officer is not a direct application rank.",
        access = "Guild management, moderation, recruitment, member assistance and disciplinary decisions."
    },
    {
        number = "8", name = "Lionheart", kind = "Leadership",
        aliases = { "lionheart", "8 - lionheart" },
        receive = "Granted only to senior leadership with exceptional long-term trust and responsibility.",
        access = "Senior leadership status with broad responsibility for the guild and its officers."
    },
    {
        number = "9", name = "Lucky Luck", displayName = "Lucky Luck", kind = "Leadership",
        aliases = { "lucky luck", "guild leader", "guild master", "gm" },
        receive = "Guild Leader position.",
        access = "Overall guild direction, final responsibility and the last decision on guild-wide matters."
    },
}

local PreviousEnsureDB = OTLGM.ApplyCoreDefaults
local PreviousGetGuildDB = OTLGM.GetOrCreateGuildDB
local PreviousMigrateGuildDB = OTLGM.MigrateLegacySchema2

function OTLGM:ApplyAdvancedDefaults()
    PreviousEnsureDB(self)
    local settings = OTLGM_DB.settings

    if not settings.v100Migrated then
        -- v0.7 used ten minutes as its default. Move unchanged installations
        -- to the new twenty-minute standard.
        if settings.scanInterval == 600 then settings.scanInterval = 1200 end
        if settings.lastPage == "overview" then settings.lastPage = "home" end
        settings.v100Migrated = true
    end

    if settings.autoScan == nil then settings.autoScan = true end
    if settings.scanInterval == nil then settings.scanInterval = 1200 end
    if tonumber(settings.scanInterval or 0) < 600 then settings.scanInterval = 1200 end
    if settings.scanChat == nil then settings.scanChat = true end
    if settings.uiMode == nil then settings.uiMode = "AUTO" end
    if settings.uiScale == nil then settings.uiScale = 1 end
    if settings.windowLocked == nil then settings.windowLocked = false end
    if settings.showHelp == nil then settings.showHelp = true end
    if settings.openHome == nil then settings.openHome = true end
    if settings.confirmRecruitment == nil then settings.confirmRecruitment = true end
    if settings.firstRunComplete == nil then settings.firstRunComplete = false end
    if settings.historySearch == nil then settings.historySearch = "" end
    if settings.historyUnreadOnly == nil then settings.historyUnreadOnly = false end
    if settings.inactiveThreshold == nil then settings.inactiveThreshold = 30 end
    if settings.inactiveStatus == nil then settings.inactiveStatus = "ALL" end
    if settings.savedRosterViews == nil then settings.savedRosterViews = {} end
    if settings.nextRecruitIndex == nil then settings.nextRecruitIndex = 1 end
    if settings.latestDetectedVersion == nil then settings.latestDetectedVersion = self.version end
    if settings.customMessageNames == nil then settings.customMessageNames = { "Custom 1", "Custom 2", "Custom 3" } end
    if settings.guildSectionExpanded == nil then settings.guildSectionExpanded = true end
    if settings.officerSectionExpanded == nil then settings.officerSectionExpanded = true end
    if settings.globalSearch == nil then settings.globalSearch = "" end
    if settings.updateWarningDismissed == nil then settings.updateWarningDismissed = "" end
    if settings.lowLevelAddonCutoff == nil then settings.lowLevelAddonCutoff = 10 end

    OTLGM_DB.version = self.version
end

function OTLGM:MigrateLegacySchema6(db)
    PreviousMigrateGuildDB(self, db)
    if not db then return end
    if (db.schemaVersion or 0) >= self.schemaVersion then return end

    db.activity = db.activity or { days = {}, allTimePeak = 0, allTimePeakAt = nil, totalScans = 0 }
    db.snapshots = db.snapshots or {}
    db.scans = db.scans or {}
    db.memberFlags = db.memberFlags or {}
    db.detectedVersions = db.detectedVersions or {}
    db.unread = db.unread or 0
    db.crafting = db.crafting or {}
    db.weeklySnapshots = db.weeklySnapshots or {}

    local remainingUnread = db.unread or 0
    local i, eventInfo
    for i = 1, table.getn(db.log or {}) do
        eventInfo = db.log[i]
        if eventInfo.kind == "LEVEL" then
            local beforeLevel = tonumber(eventInfo.levelBefore) or 0
            local afterLevel = tonumber(eventInfo.levelAfter) or 0
            local chosen = nil
            local milestoneList = { 20, 40, 60 }
            local index, levelMark
            for index = 1, table.getn(milestoneList) do
                levelMark = milestoneList[index]
                if beforeLevel < levelMark and afterLevel >= levelMark then
                    chosen = levelMark
                    break
                end
            end
            if chosen then
                eventInfo.milestone = chosen
                eventInfo.detail = chosen == 60 and "Reached maximum level 60" or ("Reached level " .. tostring(chosen))
                eventInfo.hiddenLegacyLevel = nil
            else
                eventInfo.hiddenLegacyLevel = true
                eventInfo.reviewed = true
            end
        end
        if eventInfo.reviewed == nil then
            if remainingUnread > 0 and (eventInfo.kind == "JOIN" or eventInfo.kind == "LEAVE" or eventInfo.kind == "RANK") then
                eventInfo.reviewed = false
                remainingUnread = remainingUnread - 1
            else
                eventInfo.reviewed = true
            end
        end
    end

    local now = self:Now()
    local name, member
    for name, member in pairs(db.roster or {}) do
        member.trackedSince = member.trackedSince or member.seen or now
    end

    db.schemaVersion = self.schemaVersion
end

-- Chat is intentionally reserved for successful roster update lines.
-- All other feedback goes to the status bar or an in-addon notice.
function OTLGM:Chat(message)
    if self.chatOutputAllowed and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(self.colors.gold .. "[Lion GM] " .. self.colors.reset .. message)
    elseif self.SetStatus then
        self:SetStatus(message)
    end
end

function OTLGM:ScanChat(message)
    self.chatOutputAllowed = true
    self:Chat(message)
    self.chatOutputAllowed = nil
end

function OTLGM:Notify(title, body)
    if self.ShowNotice then
        self:ShowNotice(title or "Order of the Lion", body or "")
    elseif self.SetStatus then
        self:SetStatus((title or "") .. ": " .. (body or ""))
    end
end

function OTLGM:AddLog(db, kind, name, detail, actor, source, meta)
    local eventInfo = {
        ts = self:Now(),
        kind = kind,
        name = name or "",
        detail = detail or "",
        actor = actor or "",
        source = source or "",
        reviewed = kind == "BASELINE",
    }
    if meta then
        eventInfo.class = meta.class or ""
        eventInfo.rank = meta.rank or ""
        eventInfo.rankBefore = meta.rankBefore or ""
        eventInfo.rankAfter = meta.rankAfter or ""
        eventInfo.levelBefore = meta.levelBefore
        eventInfo.levelAfter = meta.levelAfter
        eventInfo.milestone = meta.milestone
        eventInfo.absenceDays = meta.absenceDays
        eventInfo.publicNoteBefore = meta.publicNoteBefore
        eventInfo.publicNoteAfter = meta.publicNoteAfter
        eventInfo.officerNoteBefore = meta.officerNoteBefore
        eventInfo.officerNoteAfter = meta.officerNoteAfter
    end

    table.insert(db.log, 1, eventInfo)
    if not eventInfo.reviewed then db.unread = (db.unread or 0) + 1 end
    while table.getn(db.log) > 500 do table.remove(db.log) end
    return eventInfo
end

function OTLGM:GetUnreadCount()
    local db = self:GetGuildDB()
    return db and (db.unread or 0) or 0
end

function OTLGM:MarkHistoryRead()
    local db = self:GetGuildDB()
    if not db then return end
    local i
    for i = 1, table.getn(db.log or {}) do
        if db.log[i] then db.log[i].reviewed = true end
    end
    db.unread = 0
    if self.UpdateMinimapBadge then self:UpdateMinimapBadge() end
    if self.RefreshNavigation then self:RefreshNavigation() end
    if self.RefreshHomePage then self:RefreshHomePage() end
    if self.RefreshHistoryPage then self:RefreshHistoryPage() end
end

local function ProfessionLower(text)
    return string.lower(text or "")
end

local function EscapeProfessionPattern(text)
    return string.gsub(text or "", "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
end

function OTLGM:GetProfessionNormalizedText(member)
    local text = ProfessionLower((member and member.note or "") .. " " .. (member and member.officerNote or ""))
    text = string.gsub(text, "[%c\r\n\t]", " ")
    text = string.gsub(text, "[,;:/\\|%+%-%_%(%){%}%[%]%.]", " ")
    text = string.gsub(text, "%s+", " ")
    return " " .. ATrim(text) .. " "
end

local function ContainsPlain(text, term)
    return term and term ~= "" and string.find(text, string.lower(term), 1, true) ~= nil
end

local function ContainsWhole(text, term)
    term = ProfessionLower(term or "")
    if term == "" then return false end
    local needle = " " .. term .. " "
    if string.find(text, needle, 1, true) then return true end
    local skillPattern = " " .. EscapeProfessionPattern(term) .. "%s*%d+ "
    return string.find(text, skillPattern) ~= nil
end

local function ContainsStrict(text, term)
    term = ProfessionLower(term or "")
    if term == "" then return false end
    local trimmed = ATrim(text)
    if trimmed == term then return true end
    if string.find(text, " " .. term .. " 300 ", 1, true) then return true end
    if string.find(text, " 300 " .. term .. " ", 1, true) then return true end
    if string.find(text, " " .. term .. " max ", 1, true) then return true end
    if string.find(text, " max " .. term .. " ", 1, true) then return true end
    if string.find(text, " " .. EscapeProfessionPattern(term) .. "%s*%d+ ") then return true end
    return false
end

function OTLGM:GetMemberProfessionKeys(member)
    local result = {}
    if not member then return result end
    local text = self:GetProfessionNormalizedText(member)
    local i, j, definition
    for i = 1, table.getn(self.professionDefinitions) do
        definition = self.professionDefinitions[i]
        local matched = false
        for j = 1, table.getn(definition.terms or {}) do
            if ContainsPlain(text, definition.terms[j]) then matched = true break end
        end
        if not matched then
            for j = 1, table.getn(definition.shortTerms or {}) do
                if ContainsWhole(text, definition.shortTerms[j]) then matched = true break end
            end
        end
        if not matched then
            for j = 1, table.getn(definition.strictTerms or {}) do
                if ContainsStrict(text, definition.strictTerms[j]) then matched = true break end
            end
        end
        if not matched then
            for j = 1, table.getn(definition.typos or {}) do
                if ContainsPlain(text, definition.typos[j]) then matched = true break end
            end
        end
        if matched then table.insert(result, definition.key) end
    end
    return result
end

local professionSpecializationMap = {
    BLACKSMITHING = {
        { terms = { "armorsmith", "armor smith" }, label = "Armorsmith" },
        { terms = { "weaponsmith", "weapon smith" }, label = "Weaponsmith" },
        { terms = { "hammersmith", "hammer smith" }, label = "Hammersmith" },
        { terms = { "swordsmith", "sword smith" }, label = "Swordsmith" },
        { terms = { "axesmith", "axe smith" }, label = "Axesmith" },
    },
    ENGINEERING = {
        { terms = { "gnomish engineering", "gnomish engi", "gnome engi", "gnomish" }, label = "Gnomish" },
        { terms = { "goblin engineering", "goblin engi", "gob engi", "goblin" }, label = "Goblin" },
    },
    LEATHERWORKING = {
        { terms = { "tribal leatherworking", "tribal lw", "tribal" }, label = "Tribal" },
        { terms = { "dragonscale leatherworking", "dragonscale lw", "dragonscale" }, label = "Dragonscale" },
        { terms = { "elemental leatherworking", "elemental lw", "elemental" }, label = "Elemental" },
    },
    TAILORING = {
        { terms = { "mooncloth", "mooncloth tailor" }, label = "Mooncloth" },
        { terms = { "shadoweave", "shadow weave" }, label = "Shadoweave" },
        { terms = { "spellfire", "spell fire" }, label = "Spellfire" },
    },
    ALCHEMY = {
        { terms = { "transmute", "transmuter", "transmute master" }, label = "Transmute" },
        { terms = { "elixir master", "elixir" }, label = "Elixir" },
        { terms = { "potion master", "pot master" }, label = "Potion" },
    },
}

function OTLGM:GetProfessionSpecializationLabel(member, professionKey)
    local text = self:GetProfessionNormalizedText(member)
    local options = professionSpecializationMap[professionKey]
    if not options then return nil end
    local i, j
    for i = 1, table.getn(options) do
        for j = 1, table.getn(options[i].terms or {}) do
            if ContainsPlain(text, options[i].terms[j]) then return options[i].label end
        end
    end
    return nil
end

function OTLGM:GetMemberProfessionLabels(member)
    local labels = {}
    local keys = self:GetMemberProfessionKeys(member)
    local i, j, baseLabel, specialization
    for i = 1, table.getn(keys) do
        baseLabel = nil
        for j = 1, table.getn(self.professionDefinitions) do
            if self.professionDefinitions[j].key == keys[i] then
                baseLabel = self.professionDefinitions[j].label
                break
            end
        end
        if baseLabel then
            specialization = self:GetProfessionSpecializationLabel(member, keys[i])
            if specialization then
                table.insert(labels, baseLabel .. " (" .. specialization .. ")")
            else
                table.insert(labels, baseLabel)
            end
        end
    end
    return labels
end

function OTLGM:MemberMatchesProfession(member, professionKey)
    if not professionKey or professionKey == "" then return true end
    local keys = self:GetMemberProfessionKeys(member)
    local i
    for i = 1, table.getn(keys) do
        if keys[i] == professionKey then return true end
    end
    return false
end

function OTLGM:GetLeadershipRole(member)
    if not member then return nil, nil end
    local index = tonumber(member.rankIndex) or 99
    local rankLabel = member.rank and member.rank ~= "" and member.rank or "Leadership"
    local canonicalLeader = self.IsCanonicalGuildLeaderName180 and self:IsCanonicalGuildLeaderName180(member.name)

    -- For Order of the Lion the visible Guild Leader identity is deliberately
    -- fixed to Morrow/Lucks.  Live rank indexes still drive permissions, but a
    -- stale rank-0 snapshot must never give another character the crown badge.
    if canonicalLeader then
        return "Interface\\Icons\\INV_Crown_01", rankLabel, 1.0, 0.76, 0.18
    end
    if index == 0 or index == 1 then
        return "Interface\\Icons\\INV_Shield_06", rankLabel, 1.0, 0.50, 0.12
    end
    if index == 2 then
        return "Interface\\Icons\\Spell_Holy_Heal", rankLabel, 0.95, 0.62, 0.18
    end

    -- Defensive compatibility for old snapshots that predate rank indexes.
    local rank = string.lower(member.rank or "")
    if string.find(rank, "officer", 1, true) or string.find(rank, "helper", 1, true)
        or string.find(rank, "guild leader", 1, true) or string.find(rank, "guild master", 1, true) then
        return "Interface\\Icons\\INV_Shield_06", rankLabel, 1.0, 0.50, 0.12
    end
    return nil, nil
end

function OTLGM:GetMemberBadge(member)
    if not member then return nil, nil end
    local iconPath, label, r, g, b = self:GetLeadershipRole(member)
    if iconPath then return iconPath, label, r, g, b, "LEADERSHIP" end
    local rank = string.lower(member.rank or "")
    if string.find(rank, "core raider", 1, true) or string.find(rank, "the devoted", 1, true) then
        return "Interface\\Icons\\Ability_DualWield", member.rank or "Core Raider", 0.70, 0.34, 0.98, "CORE"
    end
    if rank == "raider" or string.find(rank, "4 - raider", 1, true) then
        return "Interface\\Icons\\INV_Sword_04", member.rank or "Raider", 0.62, 0.36, 0.88, "RAIDER"
    end
    if string.find(rank, "muted", 1, true)
        or string.find(rank, "mute", 1, true)
        or string.find(rank, "tormented", 1, true)
        or string.find(rank, "punished", 1, true)
        or string.find(rank, "restricted", 1, true) then
        return "Interface\\Icons\\Spell_Shadow_CurseOfTounges", member.rank or "Muted", 0.90, 0.18, 0.18, "RESTRICTED"
    end
    return nil, nil
end

function OTLGM:GetGuildRoleSnapshot()
    local db = self:GetGuildDB()
    local result = {
        level60 = 0, level60Online = 0,
        core = 0, coreOnline = 0,
        leadership = 0, leadershipOnline = 0,
        restricted = 0,
    }
    if not db then return result end
    local name, member, rank
    for name, member in pairs(db.roster or {}) do
        rank = string.lower(member.rank or "")
        if (member.level or 0) >= 60 then
            result.level60 = result.level60 + 1
            if member.online then result.level60Online = result.level60Online + 1 end
        end
        if string.find(rank, "core raider", 1, true) or string.find(rank, "the devoted", 1, true) then
            result.core = result.core + 1
            if member.online then result.coreOnline = result.coreOnline + 1 end
        end
        if self:IsLeadership(member) then
            result.leadership = result.leadership + 1
            if member.online then result.leadershipOnline = result.leadershipOnline + 1 end
        end
        if string.find(rank, "muted", 1, true)
            or string.find(rank, "mute", 1, true)
            or string.find(rank, "tormented", 1, true)
            or string.find(rank, "punished", 1, true)
            or string.find(rank, "restricted", 1, true) then
            result.restricted = result.restricted + 1
        end
    end
    return result
end

function OTLGM:IsOfficerMode()
    self:EnsureDB()
    local hasRights = self:CanEditPublicNotes() or self:CanEditOfficerNotes() or self:CanPromoteMembers() or self:CanDemoteMembers() or self:CanRemoveMembers()
    if OTLGM_DB.settings.uiMode == "MEMBER" then return false end
    if OTLGM_DB.settings.uiMode == "OFFICER" then return hasRights end
    return hasRights
end

function OTLGM:SetUIMode(mode)
    self:EnsureDB()
    if mode ~= "AUTO" and mode ~= "MEMBER" and mode ~= "OFFICER" then return end
    if mode == "OFFICER" and not (self:CanEditPublicNotes() or self:CanPromoteMembers() or self:CanRemoveMembers()) then
        self:Notify("Officer Mode Unavailable", "Your current guild rank does not expose officer permissions to the addon.")
        return
    end
    OTLGM_DB.settings.uiMode = mode
    if self.RefreshNavigation then self:RefreshNavigation() end
    if self.ShowPage then self:ShowPage("home") end
    if self.RefreshVisiblePage then self:RefreshVisiblePage() elseif self.RefreshAll then self:RefreshAll() end
end

function OTLGM.__impl180.Stage_Advanced_RequestScan_2__impl1(self, reason)
    local mode = reason
    if reason == true then mode = "INTERNAL" end
    if reason == false or reason == nil then mode = "MANUAL" end
    if not GetGuildInfo("player") then
        self:Notify("Guild Roster Unavailable", "This character is not currently in a guild.")
        return
    end

    local now = self:Now()
    local minGap = 12
    if mode == "MANUAL" then minGap = 2 end
    if mode == "CONFIRM" then minGap = 2 end

    if self.pendingScan and mode ~= "MANUAL" then return end
    if self.lastScanRequestAt and (now - self.lastScanRequestAt) < minGap then
        if mode == "MANUAL" and self.SetStatus then
            self:SetStatus("A roster request is already in progress. Please wait a moment.")
        end
        return
    end

    self.lastScanRequestAt = now
    self.lastScanRequestReason = mode
    if SetGuildRosterShowOffline then SetGuildRosterShowOffline(true) end
    self.pendingScan = true
    self.pendingScanReason = mode
    GuildRoster()
    if self.SetStatus then
        if mode == "CONFIRM" then
            self:SetStatus("Confirming roster completeness...")
        else
            self:SetStatus("Requesting guild roster...")
        end
    end
end

function OTLGM:GetSnapshotSignature(snapshot)
    local names = {}
    local name
    for name in pairs(snapshot or {}) do table.insert(names, name) end
    table.sort(names)
    return table.concat(names, "\031")
end

function OTLGM:PushSnapshot(db, roster, total, online)
    db.snapshots = db.snapshots or {}
    table.insert(db.snapshots, 1, {
        ts = self:Now(),
        total = total or TableCount(roster),
        online = online or 0,
        roster = CopySimpleTable(roster),
    })
    while table.getn(db.snapshots) > 3 do table.remove(db.snapshots) end
end

function OTLGM:ScheduleConfirmScan()
    self.confirmScanAt = self:Now() + 3
    if self.WakeScheduler180 then self:WakeScheduler180("roster-confirm-scan") end
end

function OTLGM:IsSuspiciousSnapshot(db, current, total)
    if not db.initialized then return false end
    local previousTotal = db.lastTotal or TableCount(db.roster)
    if previousTotal < 20 then return false end
    local missing, added = 0, 0
    local name
    for name in pairs(db.roster or {}) do
        if not current[name] then missing = missing + 1 end
    end
    for name in pairs(current or {}) do
        if not (db.roster and db.roster[name]) then added = added + 1 end
    end
    local shrinkThreshold = math.max(10, math.floor(previousTotal * 0.12))
    if total < math.floor(previousTotal * 0.85) and missing >= shrinkThreshold then
        return true, previousTotal, missing, "SHRINK"
    end
    -- A large upward jump usually means that the previous accepted roster was
    -- incomplete. Confirm it, then re-baseline without generating hundreds of
    -- false JOIN records.
    local expansionThreshold = math.max(25, math.floor(previousTotal * 0.15))
    if total > math.floor(previousTotal * 1.15) and added >= expansionThreshold then
        return true, previousTotal, added, "EXPANSION"
    end
    return false, previousTotal, 0, nil
end

local function ActivityDayParts180(key)
    local _, _, year, month, day = string.find(tostring(key or ""), "^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    return tonumber(year), tonumber(month), tonumber(day)
end

local function ActivityServerOffset180(self, now)
    if self and self.GetServerOffsetSeconds180 then
        local ok, value = pcall(self.GetServerOffsetSeconds180, self, now)
        if ok then return tonumber(value) or 0 end
    end
    return 0
end

-- Activity was historically bucketed through the operating-system clock while
-- the page labels its heatmap as ST.  Convert the durable legacy buckets once,
-- then record all new samples in server-time calendar buckets.  The conversion
-- only reshuffles already stored sums/counts; it never requests a roster scan.
function OTLGM:EnsureActivityServerTimeBasis180(db)
    db = db or self:GetGuildDB()
    if not db then return false end
    db.activity = db.activity or { days = {}, allTimePeak = 0, allTimePeakAt = nil, totalScans = 0 }
    local activity = db.activity
    if activity.timeBasis180 == "ST" then return false end

    local offset = ActivityServerOffset180(self, self:Now())
    local migrated = {}
    local oldKey, oldDay
    for oldKey, oldDay in pairs(activity.days or {}) do
        if type(oldDay) == "table" then
            local year, month, dayNumber = ActivityDayParts180(oldKey)
            local movedAny = false
            if year and month and dayNumber and time and date then
                local oldHour, bucket
                for oldHour, bucket in pairs(oldDay.hours or {}) do
                    oldHour = tonumber(oldHour)
                    if oldHour and oldHour >= 0 and oldHour <= 23 and type(bucket) == "table" then
                        local localTs = time({ year=year, month=month, day=dayNumber, hour=oldHour, min=0, sec=0 })
                        local shifted = (tonumber(localTs) or 0) + offset
                        local newKey = date("%Y-%m-%d", shifted)
                        local newHour = tonumber(date("%H", shifted)) or 0
                        local newWeekday = tonumber(date("%w", shifted)) or 0
                        local target = migrated[newKey]
                        if not target then
                            target = { ts = tonumber(localTs) or 0, weekday = newWeekday, peak = 0, peakAt = nil, sum = 0, count = 0, hours = {}, timeBasis180 = "ST" }
                            migrated[newKey] = target
                        elseif (tonumber(localTs) or 0) > 0 and ((tonumber(target.ts) or 0) <= 0 or localTs < target.ts) then
                            -- Keep ts as a real absolute timestamp for retention / period cutoffs.
                            -- Only the calendar key/hour is shifted into ST.
                            target.ts = localTs
                        end
                        local targetBucket = target.hours[newHour]
                        if not targetBucket then targetBucket = { sum = 0, count = 0, max = 0 } target.hours[newHour] = targetBucket end
                        targetBucket.sum = (tonumber(targetBucket.sum) or 0) + (tonumber(bucket.sum) or 0)
                        targetBucket.count = (tonumber(targetBucket.count) or 0) + (tonumber(bucket.count) or 0)
                        targetBucket.max = math.max(tonumber(targetBucket.max) or 0, tonumber(bucket.max) or 0)
                        target.sum = target.sum + (tonumber(bucket.sum) or 0)
                        target.count = target.count + (tonumber(bucket.count) or 0)
                        movedAny = true
                    end
                end
            end

            local sampleTs = tonumber(oldDay.lastSampleAt) or tonumber(oldDay.ts) or 0
            local sampleShifted = sampleTs > 0 and (sampleTs + offset) or 0
            local sampleKey = sampleShifted > 0 and date and date("%Y-%m-%d", sampleShifted) or oldKey
            local sampleWeekday = sampleShifted > 0 and date and (tonumber(date("%w", sampleShifted)) or 0) or (tonumber(oldDay.weekday) or 0)
            local target = migrated[sampleKey]
            if not target then
                target = { ts = sampleTs > 0 and sampleTs or (tonumber(oldDay.ts) or self:Now()), weekday = sampleWeekday, peak = 0, peakAt = nil, sum = 0, count = 0, hours = {}, timeBasis180 = "ST" }
                migrated[sampleKey] = target
            elseif sampleTs > 0 and ((tonumber(target.ts) or 0) <= 0 or sampleTs < target.ts) then
                target.ts = sampleTs
            end
            if not movedAny then
                target.sum = target.sum + (tonumber(oldDay.sum) or 0)
                target.count = target.count + (tonumber(oldDay.count) or 0)
            end
            -- A legacy local-calendar day can split across two ST dates. Place
            -- its recorded peak on the ST date containing the real peakAt rather
            -- than blindly attaching it to the last-sample date.
            local peakTs = tonumber(oldDay.peakAt) or 0
            local peakShifted = peakTs > 0 and (peakTs + offset) or 0
            local peakKey = peakShifted > 0 and date and date("%Y-%m-%d", peakShifted) or sampleKey
            local peakWeekday = peakShifted > 0 and date and (tonumber(date("%w", peakShifted)) or sampleWeekday) or sampleWeekday
            local peakTarget = migrated[peakKey]
            if not peakTarget then
                peakTarget = { ts = peakTs > 0 and peakTs or (tonumber(target.ts) or self:Now()), weekday = peakWeekday, peak = 0, peakAt = nil, sum = 0, count = 0, hours = {}, timeBasis180 = "ST" }
                migrated[peakKey] = peakTarget
            end
            if (tonumber(oldDay.peak) or 0) >= (tonumber(peakTarget.peak) or 0) then
                peakTarget.peak = tonumber(oldDay.peak) or 0
                peakTarget.peakAt = peakTs > 0 and peakTs or peakTarget.peakAt
            end
            if sampleTs >= (tonumber(target.lastSampleAtLocal180) or 0) then
                target.lastSampleAtLocal180 = sampleTs
                target.lastSampleAt = tonumber(oldDay.lastSampleAt) or tonumber(oldDay.ts) or target.lastSampleAt
                target.total = tonumber(oldDay.total) or target.total
                target.online = tonumber(oldDay.online) or target.online
                target.level60 = tonumber(oldDay.level60) or target.level60
                target.active7 = tonumber(oldDay.active7) or target.active7
            end
        end
    end
    for _, migratedDay in pairs(migrated) do migratedDay.lastSampleAtLocal180 = nil end
    activity.days = migrated
    activity.timeBasis180 = "ST"
    activity.timeBasisMigratedAt180 = self:Now()
    activity.timeBasisOffset180 = offset
    return true
end

function OTLGM:RecordActivitySample(db, total, online)
    db.activity = db.activity or { days = {}, allTimePeak = 0, allTimePeakAt = nil, totalScans = 0 }
    self:EnsureActivityServerTimeBasis180(db)
    local activity = db.activity
    local now = self:Now()
    local serverNow = now + ActivityServerOffset180(self, now)
    local dayKey = date("%Y-%m-%d", serverNow)
    local hour = tonumber(date("%H", serverNow)) or 0
    local weekday = tonumber(date("%w", serverNow)) or 0
    local day = activity.days[dayKey]
    if not day then
        day = { ts = now, weekday = weekday, peak = 0, peakAt = nil, sum = 0, count = 0, hours = {}, timeBasis180 = "ST" }
        activity.days[dayKey] = day
    end
    day.sum = (day.sum or 0) + online
    day.count = (day.count or 0) + 1
    if online >= (day.peak or 0) then day.peak = online day.peakAt = now end
    local bucket = day.hours[hour]
    if not bucket then bucket = { sum = 0, count = 0, max = 0 } day.hours[hour] = bucket end
    bucket.sum = bucket.sum + online
    bucket.count = bucket.count + 1
    if online > bucket.max then bucket.max = online end

    activity.totalScans = (activity.totalScans or 0) + 1
    if online >= (activity.allTimePeak or 0) then
        activity.allTimePeak = online
        activity.allTimePeakAt = now
    end

    local level60, active7 = 0, 0
    local memberName, memberInfo
    for memberName, memberInfo in pairs(db.roster or {}) do
        if (tonumber(memberInfo.level) or 0) >= 60 then level60 = level60 + 1 end
        if memberInfo.online or (tonumber(memberInfo.offlineDays) or 9999) <= 7 then active7 = active7 + 1 end
    end
    day.total = total or day.total or 0
    day.online = online or day.online or 0
    day.level60 = level60
    day.active7 = active7
    day.lastSampleAt = now
    db.weeklySnapshots = db.weeklySnapshots or {}
    db.weeklySnapshots[dayKey] = {
        ts = now, total = total or 0, online = online or 0, peak = day.peak or online or 0,
        level60 = level60, active7 = active7,
    }

    local cutoff = now - (90 * 86400)
    local key, item
    for key, item in pairs(activity.days) do
        -- Retain a boundary day until its newest real sample falls outside the
        -- 90-day window. Using the first sample (day.ts) could discard almost
        -- a full day of still-valid activity after the ST migration.
        local activityAt = tonumber(item.lastSampleAt) or tonumber(item.ts) or 0
        if activityAt > 0 and activityAt < cutoff then activity.days[key] = nil end
    end
    for key, item in pairs(db.weeklySnapshots or {}) do
        if item.ts and item.ts < cutoff then db.weeklySnapshots[key] = nil end
    end
end

function OTLGM:RecordScan(db, total, online, changes, valid, reason)
    db.scans = db.scans or {}
    table.insert(db.scans, 1, {
        ts = self:Now(),
        total = total or 0,
        online = online or 0,
        changes = changes or 0,
        valid = valid and true or false,
        reason = reason or "",
    })
    while table.getn(db.scans) > 100 do table.remove(db.scans) end
end

local metadataFields = {
    "trackedSince", "joinedAt", "promotedAt", "rankChangedAt", "returnedAt",
    "returnAfterDays", "lastMilestoneAt", "lastMilestone",
    "faction180", "factionSeenAt180", "factionSource180", "race180",
}

function OTLGM:CarryMemberMetadata(old, current)
    if not old or not current then return end
    local i, field
    for i = 1, table.getn(metadataFields) do
        field = metadataFields[i]
        -- A fresh roster read can now provide explicit faction/race evidence
        -- (extended client tuple or the established officer-note race code).
        -- Never replace that newer evidence with an older cached observation.
        if (field == "faction180" or field == "factionSeenAt180" or field == "factionSource180" or field == "race180") then
            if current[field] == nil or current[field] == "" then current[field] = old[field] end
        else
            current[field] = old[field]
        end
    end
end

function OTLGM.__impl180.Stage_Advanced_Scan_2__impl1(self, reason)
    local db = self:GetGuildDB()
    if not db then return end
    reason = reason or "INTERNAL"

    local current, total, online = self:ReadRoster()
    if total == 0 then
        self.zeroScanAttempts = (self.zeroScanAttempts or 0) + 1
        self:RecordScan(db, total, online, 0, false, reason)
        if reason ~= "CONFIRM" then self.confirmOriginReason = reason end
        if self.zeroScanAttempts < 3 then
            self:ScheduleConfirmScan()
            if self.SetStatus then self:SetStatus("Roster returned no members. Confirmation attempt " .. tostring(self.zeroScanAttempts) .. " of 3 was scheduled.") end
        else
            local failedOrigin = self.confirmOriginReason or reason
            self.confirmScanAt = nil
            self.confirmOriginReason = nil
            if self.SetStatus then self:SetStatus("Roster could not be loaded after three attempts. No database changes were recorded.") end
            if failedOrigin == "AUTO" then self.elapsed = 0 end
            if failedOrigin == "MANUAL" then
                self:Notify("Roster Update Failed", "The client returned an empty guild roster three times. No leave events or database changes were recorded. Try a manual update later.")
            end
        end
        return
    end
    self.zeroScanAttempts = 0

    local suspicious, previousTotal, difference, suspiciousDirection = self:IsSuspiciousSnapshot(db, current, total)
    local confirmedExpansion = false
    if suspicious then
        local signature = self:GetSnapshotSignature(current)
        local candidate = db.suspiciousCandidate
        if candidate and candidate.signature == signature and (self:Now() - (candidate.ts or 0)) <= 45 then
            if suspiciousDirection == "EXPANSION" then confirmedExpansion = true end
            db.suspiciousCandidate = nil
            self.suspiciousScanAttempts = 0
        else
            if reason ~= "CONFIRM" then self.confirmOriginReason = reason end
            self.suspiciousScanAttempts = (self.suspiciousScanAttempts or 0) + 1
            db.suspiciousCandidate = { signature = signature, ts = self:Now(), total = total, previousTotal = previousTotal, difference = difference, direction = suspiciousDirection, reason = reason }
            self:RecordScan(db, total, online, 0, false, "SUSPICIOUS")
            if self.suspiciousScanAttempts < 3 then
                self:ScheduleConfirmScan()
                if self.SetStatus then
                    if suspiciousDirection == "EXPANSION" then
                        self:SetStatus("Large roster restoration suspected: " .. tostring(previousTotal) .. " -> " .. tostring(total) .. ". Confirming before recording changes...")
                    else
                        self:SetStatus("Incomplete roster suspected: " .. tostring(total) .. " of " .. tostring(previousTotal) .. ". No leave events recorded; confirmation " .. tostring(self.suspiciousScanAttempts) .. " of 3...")
                    end
                end
            else
                local failedOrigin = self.confirmOriginReason or reason
                self.confirmScanAt = nil
                self.confirmOriginReason = nil
                self.suspiciousScanAttempts = 0
                db.suspiciousCandidate = nil
                if failedOrigin == "AUTO" then self.elapsed = 0 end
                if self.SetStatus then self:SetStatus("Roster remained incomplete. The saved database was preserved without recording departures.") end
                if failedOrigin == "MANUAL" then
                    self:Notify("Incomplete Roster Preserved", "Three inconsistent partial rosters were received. The previous valid database and backup snapshots were kept, and no leave events were recorded.")
                end
            end
            return
        end
    else
        db.suspiciousCandidate = nil
        self.suspiciousScanAttempts = 0
    end

    local outputReason = reason
    if reason == "CONFIRM" and self.confirmOriginReason then outputReason = self.confirmOriginReason end
    self.confirmOriginReason = nil

    if confirmedExpansion then
        local baselineNow = self:Now()
        local memberName, memberInfo
        for memberName, memberInfo in pairs(current) do
            local oldInfo = db.roster and db.roster[memberName]
            if oldInfo then
                self:CarryMemberMetadata(oldInfo, memberInfo)
            else
                memberInfo.trackedSince = baselineNow
                memberInfo.joinedAt = nil
            end
        end
        self:PushSnapshot(db, current, total, online)
        db.roster = current
        db.lastScan = baselineNow
        db.lastTotal = total
        db.lastOnline = online
        db.lastScanReason = outputReason
        self:AddLog(db, "BASELINE", "Guild", "Confirmed full roster restoration: " .. tostring(total) .. " members; mass JOIN events suppressed")
        if outputReason == "MANUAL" or outputReason == "AUTO" then self:RecordActivitySample(db, total, online) end
        self:RecordScan(db, total, online, 0, true, "REBASELINE")
        if outputReason == "MANUAL" or outputReason == "AUTO" then self.elapsed = 0 end
        if self.RefreshVisiblePage then self:RefreshVisiblePage() elseif self.RefreshAll then self:RefreshAll() end
        if self.UpdateMinimapBadge then self:UpdateMinimapBadge() end
        if self.RefreshNavigation then self:RefreshNavigation() end
        if self.SetStatus then self:SetStatus("Roster baseline safely refreshed at " .. date("%H:%M", baselineNow) .. "; mass false joins were not recorded.") end
        return
    end

    self:CleanupPendingInvites(db)
    self:CleanupPendingActions(db)

    local now = self:Now()
    local joined, left, rankChanged, milestones, notesChanged, returned = 0, 0, 0, 0, 0, 0
    local name, info

    if db.initialized then
        for name, info in pairs(current) do
            local old = db.roster[name]
            if old then
                self:CarryMemberMetadata(old, info)
            else
                info.trackedSince = now
                info.joinedAt = now
            end
        end

        for name, info in pairs(current) do
            local old = db.roster[name]
            if not old then
                joined = joined + 1
                local detail = "Joined the guild"
                local actor, source = "", ""
                local invite = self:ConsumeInvite(name)
                if invite and invite.inviter then
                    actor = invite.inviter
                    source = "local invite"
                    detail = "Joined after a locally tracked invite"
                end
                self:AddLog(db, "JOIN", name, detail, actor, source, {
                    class = info.class, rank = info.rank, rankAfter = info.rank, levelAfter = info.level,
                })
            else
                if not old.online and info.online and (old.offlineDays or 0) >= 14 then
                    returned = returned + 1
                    info.returnedAt = now
                    info.returnAfterDays = old.offlineDays or 0
                    self:AddLog(db, "RETURN", name, "Returned after " .. tostring(old.offlineDays or 0) .. " days offline", "", "", {
                        class = info.class, rank = info.rank, levelAfter = info.level, absenceDays = old.offlineDays or 0,
                    })
                end

                if old.rank ~= info.rank then
                    rankChanged = rankChanged + 1
                    local actionKind = "PROMOTE"
                    if (info.rankIndex or 99) > (old.rankIndex or 99) then actionKind = "DEMOTE" end
                    local action = self:ConsumeGuildAction(name, actionKind)
                    info.rankChangedAt = now
                    if actionKind == "PROMOTE" then info.promotedAt = now end
                    self:AddLog(db, "RANK", name, (old.rank or "?") .. " -> " .. (info.rank or "?"), action and action.actor or "", action and action.source or "", {
                        class = info.class, rank = info.rank, rankBefore = old.rank, rankAfter = info.rank, levelAfter = info.level,
                    })
                end

                if old.level and info.level and info.level > old.level then
                    local milestoneList = { 20, 40, 60 }
                    local markerIndex, milestone
                    for markerIndex = 1, table.getn(milestoneList) do
                        milestone = milestoneList[markerIndex]
                        if (old.level or 0) < milestone and info.level >= milestone then
                            milestones = milestones + 1
                            info.lastMilestone = milestone
                            info.lastMilestoneAt = now
                            local detail = milestone == 60 and "Reached maximum level 60" or ("Reached level " .. tostring(milestone))
                            self:AddLog(db, "LEVEL", name, detail, "", "", {
                                class = info.class, rank = info.rank, levelBefore = old.level, levelAfter = info.level, milestone = milestone,
                            })
                        end
                    end
                end

                local publicChanged = old.note ~= info.note
                local officerChanged = old.officerNote ~= info.officerNote
                if publicChanged or officerChanged then
                    notesChanged = notesChanged + 1
                    local noteParts = {}
                    local oldPublic, newPublic = old.note or "", info.note or ""
                    local oldOfficer, newOfficer = old.officerNote or "", info.officerNote or ""
                    if publicChanged then
                        table.insert(noteParts, 'Public: "' .. (oldPublic ~= "" and oldPublic or "(empty)") .. '" > "' .. (newPublic ~= "" and newPublic or "(empty)") .. '"')
                    end
                    if officerChanged then
                        table.insert(noteParts, 'Officer: "' .. (oldOfficer ~= "" and oldOfficer or "(empty)") .. '" > "' .. (newOfficer ~= "" and newOfficer or "(empty)") .. '"')
                    end
                    local noteAction = self:ConsumeGuildAction(name, "NOTE")
                    self:AddLog(db, "NOTE", name, table.concat(noteParts, " | "), noteAction and noteAction.actor or "", noteAction and noteAction.source or "", {
                        class = info.class, rank = info.rank, levelAfter = info.level,
                        publicNoteBefore = oldPublic, publicNoteAfter = newPublic,
                        officerNoteBefore = oldOfficer, officerNoteAfter = newOfficer,
                    })
                end
            end
        end

        for name, info in pairs(db.roster or {}) do
            if not current[name] then
                left = left + 1
                local action = self:ConsumeGuildAction(name, "REMOVE")
                self:AddLog(db, "LEAVE", name, action and "Removed from the guild" or "Left or was removed; actor unavailable", action and action.actor or "", action and action.source or "", {
                    class = info.class, rank = info.rank, rankBefore = info.rank, levelBefore = info.level,
                })
            end
        end
    else
        for name, info in pairs(current) do info.trackedSince = now end
        self:AddLog(db, "BASELINE", "Guild", "Initial roster saved: " .. tostring(total) .. " members")
        db.initialized = true
    end

    self:PushSnapshot(db, current, total, online)
    db.roster = current
    db.lastScan = now
    db.lastTotal = total
    db.lastOnline = online
    db.lastScanReason = outputReason

    local day = self:TodayKey()
    if not db.daily[day] then
        db.daily[day] = { first = total, min = total, max = total, last = total, scans = 1 }
    else
        local daily = db.daily[day]
        if total < daily.min then daily.min = total end
        if total > daily.max then daily.max = total end
        daily.last = total
        daily.scans = (daily.scans or 0) + 1
    end

    if outputReason == "MANUAL" or outputReason == "AUTO" then
        self:RecordActivitySample(db, total, online)
    end
    local changes = joined + left + rankChanged + milestones + notesChanged + returned
    self:RecordScan(db, total, online, changes, true, outputReason)
    if outputReason == "MANUAL" or outputReason == "AUTO" then self.elapsed = 0 end

    if (outputReason == "MANUAL" or outputReason == "AUTO") and OTLGM_DB.settings.scanChat then
        self:ScanChat("Roster updated: " .. self.colors.green .. tostring(online) .. self.colors.reset ..
            " online / " .. self.colors.white .. tostring(total) .. self.colors.reset .. " members.")
    end

    if self.RefreshVisiblePage then self:RefreshVisiblePage() elseif self.RefreshAll then self:RefreshAll() end
    if self.UpdateMinimapBadge then self:UpdateMinimapBadge() end
    if self.RefreshNavigation then self:RefreshNavigation() end
    if self.SetStatus then self:SetStatus("Roster database updated at " .. date("%H:%M", now) .. ".") end
end

function OTLGM.__impl180.GetStats__impl1(self, days)
    local db = self:GetGuildDB()
    local stats = { joins = 0, leaves = 0, ranks = 0, levels = 0, level60 = 0, notes = 0, returns = 0, net = 0, inactive30 = 0, unread = 0 }
    if not db then return stats end
    local cutoff = self:Now() - ((days or 7) * 86400)
    local i, eventInfo
    for i = 1, table.getn(db.log or {}) do
        eventInfo = db.log[i]
        if eventInfo.ts and eventInfo.ts >= cutoff and not eventInfo.hiddenLegacyLevel then
            if eventInfo.kind == "JOIN" then stats.joins = stats.joins + 1 end
            if eventInfo.kind == "LEAVE" then stats.leaves = stats.leaves + 1 end
            if eventInfo.kind == "RANK" then stats.ranks = stats.ranks + 1 end
            if eventInfo.kind == "LEVEL" then
                stats.levels = stats.levels + 1
                if eventInfo.milestone == 60 then stats.level60 = stats.level60 + 1 end
            end
            if eventInfo.kind == "NOTE" then stats.notes = stats.notes + 1 end
            if eventInfo.kind == "RETURN" then stats.returns = stats.returns + 1 end
        end
        if not eventInfo.reviewed then stats.unread = stats.unread + 1 end
    end
    local name, member
    for name, member in pairs(db.roster or {}) do
        if not member.online and (member.offlineDays or 0) >= 30 then stats.inactive30 = stats.inactive30 + 1 end
    end
    stats.net = stats.joins - stats.leaves
    return stats
end

function OTLGM.__impl180.Stage_Advanced_GetActivitySummary_1__impl1(self, days)
    local db = self:GetGuildDB()
    local result = {
        todayPeak = 0, todayPeakAt = nil, periodPeak = 0, periodPeakAt = nil,
        allTimePeak = 0, allTimePeakAt = nil, average = 0, samples = 0,
    }
    if not db or not db.activity then return result end
    if self.EnsureActivityServerTimeBasis180 then self:EnsureActivityServerTimeBasis180(db) end
    local now = self:Now()
    local cutoff = now - ((days or 7) * 86400)
    local serverNow = now + ActivityServerOffset180(self, now)
    local todayKey = date("%Y-%m-%d", serverNow)
    local sum, count = 0, 0
    local key, day
    for key, day in pairs(db.activity.days or {}) do
        if key == todayKey then
            result.todayPeak = day.peak or 0
            result.todayPeakAt = day.peakAt
        end
        -- A retained day spans multiple samples. Use the newest real sample to
        -- decide whether the day overlaps the requested window, and the exact
        -- peak timestamp for the peak itself. The former day.ts-only check could
        -- drop the newest part of the boundary day up to ~24 hours too early.
        local activityAt = tonumber(day.lastSampleAt) or tonumber(day.ts) or 0
        local peakAt = tonumber(day.peakAt) or activityAt
        if peakAt >= cutoff and (day.peak or 0) > result.periodPeak then
            result.periodPeak = day.peak or 0
            result.periodPeakAt = day.peakAt
        end
        if activityAt >= cutoff then
            sum = sum + (day.sum or 0)
            count = count + (day.count or 0)
        end
    end
    result.allTimePeak = db.activity.allTimePeak or 0
    result.allTimePeakAt = db.activity.allTimePeakAt
    result.samples = count
    if count > 0 then result.average = sum / count end
    return result
end

function OTLGM.__impl180.Stage_Advanced_GetActivityHeatmap_1__impl1(self)
    local db = self:GetGuildDB()
    if db and self.EnsureActivityServerTimeBasis180 then self:EnsureActivityServerTimeBasis180(db) end
    local matrix = {}
    local counts = {}
    local weekday, slot
    for weekday = 0, 6 do
        matrix[weekday] = {}
        counts[weekday] = {}
        for slot = 0, 7 do matrix[weekday][slot] = 0 counts[weekday][slot] = 0 end
    end
    local maxValue = 0
    if db and db.activity then
        local key, day, hour, bucket
        for key, day in pairs(db.activity.days or {}) do
            weekday = day.weekday or 0
            for hour, bucket in pairs(day.hours or {}) do
                slot = math.floor((tonumber(hour) or 0) / 3)
                matrix[weekday][slot] = matrix[weekday][slot] + (bucket.sum or 0)
                counts[weekday][slot] = counts[weekday][slot] + (bucket.count or 0)
            end
        end
    end
    for weekday = 0, 6 do
        for slot = 0, 7 do
            if counts[weekday][slot] > 0 then matrix[weekday][slot] = matrix[weekday][slot] / counts[weekday][slot] end
            if matrix[weekday][slot] > maxValue then maxValue = matrix[weekday][slot] end
        end
    end
    return matrix, maxValue
end

local function NormalizeObservedFaction180(value)
    value = string.upper(ATrim(tostring(value or "")))
    if value == "ALLIANCE" then return "Alliance" end
    if value == "HORDE" then return "Horde" end
    return nil
end

function OTLGM:RememberRosterFaction180(name, faction, source)
    faction = NormalizeObservedFaction180(faction)
    if not faction or not name or name == "" then return false end
    local member = self:GetMember(name)
    if not member then return false end
    local changed = member.faction180 ~= faction
    member.faction180 = faction
    member.factionSeenAt180 = self:Now()
    if source and source ~= "" then member.factionSource180 = self:SafeText(tostring(source), 24, false, false) end
    if changed then
        self.runtime = self.runtime or {}
        self.runtime.factionObservationRevision180 = (tonumber(self.runtime.factionObservationRevision180) or 0) + 1
    end
    return changed
end

-- Opportunistically add direct unit-token faction evidence. The committed
-- roster can also carry explicit faction/race evidence from a compatible
-- extended guild tuple or a structured officer-note race code. This pass is
-- intentionally bounded (player + at most 4 party + 40 raid units), event-
-- driven, and never starts a roster scan or network request.
function OTLGM:RefreshObservedGuildFactions180(reason)
    if not UnitName or not UnitFactionGroup then return 0 end
    local changed = 0
    local seen = {}
    local function Observe(unit)
        if UnitExists and not UnitExists(unit) then return end
        local okName, name = pcall(UnitName, unit)
        if not okName or not name or name == "" then return end
        local key = ANormalizeName(name)
        if key == "" or seen[key] then return end
        seen[key] = true
        if not self:GetMember(name) then return end
        local okFaction, faction = pcall(UnitFactionGroup, unit)
        if okFaction and self:RememberRosterFaction180(name, faction, "unit") then changed = changed + 1 end
    end

    Observe("player")
    local index
    for index = 1, 4 do Observe("party" .. tostring(index)) end
    for index = 1, 40 do Observe("raid" .. tostring(index)) end
    self.runtime = self.runtime or {}
    self.runtime.lastFactionObservationAt180 = self:Now()
    self.runtime.lastFactionObservationReason180 = tostring(reason or "visible")
    return changed
end

local function EmptyComposition180()
    return {
        classes = {}, levels = { low = 0, mid = 0, high = 0, max = 0 }, total = 0,
        factions = { Alliance = 0, Horde = 0, Unknown = 0 }, factionKnown = 0,
    }
end

local function AddCompositionMember180(result, member)
    result.total = result.total + 1
    local class = member.class or "Unknown"
    result.classes[class] = (result.classes[class] or 0) + 1
    local faction = NormalizeObservedFaction180(member.faction180)
    if faction then
        result.factions[faction] = (result.factions[faction] or 0) + 1
        result.factionKnown = result.factionKnown + 1
    else
        result.factions.Unknown = result.factions.Unknown + 1
    end
    if (member.level or 0) >= 60 then result.levels.max = result.levels.max + 1
    elseif (member.level or 0) >= 40 then result.levels.high = result.levels.high + 1
    elseif (member.level or 0) >= 20 then result.levels.mid = result.levels.mid + 1
    else result.levels.low = result.levels.low + 1 end
end

-- Activity asks for total and online composition together. Build both snapshots in
-- one roster pass and reuse them until either the committed roster or directly
-- observed faction evidence changes. This keeps the new statistics effectively
-- free while the page is merely being repainted.
function OTLGM:GetComposition(onlineOnly)
    local db = self:GetGuildDB()
    if not db then return EmptyComposition180() end
    self.runtime = self.runtime or {}
    local revision = tostring(tonumber(db.lastScan) or 0) .. ":" .. tostring(tonumber(self.runtime.factionObservationRevision180) or 0)
    local cache = self.runtime.compositionCache180
    if not cache or cache.revision ~= revision then
        local total = EmptyComposition180()
        local online = EmptyComposition180()
        local _, member
        for _, member in pairs(db.roster or {}) do
            AddCompositionMember180(total, member)
            if member.online then AddCompositionMember180(online, member) end
        end
        cache = { revision = revision, total = total, online = online }
        self.runtime.compositionCache180 = cache
    end
    return onlineOnly and cache.online or cache.total
end

function OTLGM:GetSortedRoster(searchText, filter, rankFilter, professionFilter)
    local db = self:GetGuildDB()
    -- Presence evidence is an officer workflow. A stale SavedVariables filter
    -- from an officer character must not expose that view after logging an
    -- ordinary member on the same installation.
    if string.sub(tostring(filter or ""), 1, 6) == "ADDON_" and not self:IsOfficerMode() then filter = "ALL" end
    local list = {}
    if not db then return list end
    self:EnsureDB()

    professionFilter = professionFilter or OTLGM_DB.settings.rosterProfessionFilter or ""
    local playerZone = GetZoneText and (GetZoneText() or "") or ""
    local playerLevel = UnitLevel and (UnitLevel("player") or 0) or 0
    local search = string.lower(ATrim(searchText or ""))
    local now = self:Now()
    local recentCutoff = now - (14 * 86400)
    local name, member

    for name, member in pairs(db.roster or {}) do
        local allowed = true
        if filter == "ONLINE" and not member.online then allowed = false end
        if filter == "LEADERSHIP" and not self:IsLeadership(member) then allowed = false end
        if filter == "SAMEZONE" and (not member.online or playerZone == "" or member.zone ~= playerZone) then allowed = false end
        if filter == "NEARLEVEL" and (not member.online or math.abs((member.level or 0) - playerLevel) > 5) then allowed = false end
        if filter == "LEVEL60" and (member.level or 0) ~= 60 then allowed = false end
        if filter == "NEW14" and not (member.joinedAt and member.joinedAt >= recentCutoff) then allowed = false end
        if filter == "RETURNED14" and not (member.returnedAt and member.returnedAt >= recentCutoff) then allowed = false end
        if filter == "PROMOTED14" and not (member.promotedAt and member.promotedAt >= recentCutoff) then allowed = false end
        if filter == "INACTIVE14" and (member.online or (member.offlineDays or 0) < 14) then allowed = false end
        if filter == "INACTIVE30" and (member.online or (member.offlineDays or 0) < 30) then allowed = false end
        if filter == "INACTIVE60" and (member.online or (member.offlineDays or 0) < 60) then allowed = false end
        if filter == "INACTIVE90" and (member.online or (member.offlineDays or 0) < 90) then allowed = false end
        if filter == "LEVEL1_19" and ((member.level or 0) < 1 or (member.level or 0) > 19) then allowed = false end
        if filter == "LEVEL20_39" and ((member.level or 0) < 20 or (member.level or 0) > 39) then allowed = false end
        if filter == "LEVEL40_59" and ((member.level or 0) < 40 or (member.level or 0) > 59) then allowed = false end
        if filter == "ADDON_ACTIVE" and self:GetAddonDetection170(member.name).state ~= "ACTIVE" then allowed = false end
        if filter == "ADDON_SEEN" and self:GetAddonDetection170(member.name).state == "UNDETECTED" then allowed = false end
        if filter == "ADDON_UNDETECTED" and self:GetAddonDetection170(member.name).state ~= "UNDETECTED" then allowed = false end
        if rankFilter and rankFilter ~= "" and member.rank ~= rankFilter then allowed = false end
        if allowed and professionFilter ~= "" and not self:MemberMatchesProfession(member, professionFilter) then allowed = false end

        if allowed and search ~= "" then
            local haystack = string.lower((member.name or "") .. " " .. (member.rank or "") .. " " .. (member.class or "") .. " " ..
                (member.zone or "") .. " " .. (member.note or "") .. " " .. (member.officerNote or ""))
            if not string.find(haystack, search, 1, true) then allowed = false end
        end
        if allowed then table.insert(list, member) end
    end

    local sortKey = OTLGM_DB.settings.rosterSortKey or "RANK"
    local ascending = OTLGM_DB.settings.rosterSortAsc and true or false
    local function Text(value) return string.lower(value or "") end
    local function CompareValue(a, b)
        if sortKey == "NAME" then return Text(a.name), Text(b.name) end
        if sortKey == "LEVEL" then return a.level or 0, b.level or 0 end
        if sortKey == "CLASS" then return Text(a.class), Text(b.class) end
        if sortKey == "LASTONLINE" then
            return a.online and -1 or (a.offlineHours or 0), b.online and -1 or (b.offlineHours or 0)
        end
        return a.rankIndex or 99, b.rankIndex or 99
    end

    table.sort(list, function(a, b)
        if filter == "LEADERSHIP" and a.online ~= b.online then return a.online end
        local av, bv = CompareValue(a, b)
        if av ~= bv then
            if ascending then return av < bv else return av > bv end
        end
        if sortKey ~= "RANK" and (a.rankIndex or 99) ~= (b.rankIndex or 99) then return (a.rankIndex or 99) < (b.rankIndex or 99) end
        if a.online ~= b.online then return a.online end
        if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) > (b.level or 0) end
        return Text(a.name) < Text(b.name)
    end)
    return list
end

function OTLGM:GetAddonDetection170(name)
    name = string.gsub(tostring(name or ""), "%-.*$", "")
    if self:NormalizeName(name) == self:NormalizeName(UnitName("player") or "") then
        return { state = "ACTIVE", label = "Active now", version = self.version, ts = self:Now(), self = true }
    end
    local db = self:GetGuildDB()
    local info = db and db.detectedVersions and db.detectedVersions[name]
    if type(info) ~= "table" then info = nil end
    if not info then
        local storedName, stored
        for storedName, stored in pairs(db and db.detectedVersions or {}) do
            if type(stored) == "table" and self:NormalizeName(storedName) == self:NormalizeName(name) then info = stored break end
        end
    end
    if not info or not tonumber(info.ts) then return { state = "UNDETECTED", label = "Not detected", version = nil, ts = 0 } end
    local age = math.max(0, self:Now() - info.ts)
    if age <= 300 then return { state = "ACTIVE", label = "Active now", version = info.version, ts = info.ts } end
    if age <= 86400 then return { state = "RECENT", label = "Seen in 24h", version = info.version, ts = info.ts } end
    return { state = "SEEN", label = "Detected before", version = info.version, ts = info.ts }
end

function OTLGM:PruneDetectedAddonUsers170()
    local db = self:GetGuildDB()
    local now = self:Now()
    local name, info
    local entries = {}
    for name, info in pairs(db and db.detectedVersions or {}) do
        local timestamp = type(info) == "table" and tonumber(info.ts) or nil
        -- Keep durable evidence for current guild members. Old entries for
        -- characters no longer in the roster expire, and the hard cap below
        -- still bounds renamed/transferred-character residue.
        if not timestamp or (not self:GetMember(name) and now - timestamp > (180 * 86400)) then db.detectedVersions[name] = nil
        else table.insert(entries, { name = name, ts = timestamp }) end
    end
    if table.getn(entries) > 1000 then
        table.sort(entries, function(left, right) return left.ts < right.ts end)
        local index
        for index = 1, table.getn(entries) - 1000 do db.detectedVersions[entries[index].name] = nil end
    end
end

function OTLGM:SaveRosterView(slot)
    self:EnsureDB()
    slot = tonumber(slot)
    if not slot or slot < 1 or slot > 3 then return end
    OTLGM_DB.settings.savedRosterViews[slot] = {
        search = self.ui and self.ui.rosterSearch and self.ui.rosterSearch:GetText() or OTLGM_DB.settings.rosterSearch or "",
        filter = self.ui and self.ui.rosterFilter or OTLGM_DB.settings.rosterFilter or "ALL",
        rank = self.ui and self.ui.rosterRankFilter or OTLGM_DB.settings.rosterRankFilter or "",
        profession = self.ui and self.ui.rosterProfessionFilter or OTLGM_DB.settings.rosterProfessionFilter or "",
        sortKey = OTLGM_DB.settings.rosterSortKey or "RANK",
        sortAsc = OTLGM_DB.settings.rosterSortAsc and true or false,
    }
    if self.SetStatus then self:SetStatus("Saved current roster filters to View " .. tostring(slot) .. ".") end
end

function OTLGM:LoadRosterView(slot)
    self:EnsureDB()
    slot = tonumber(slot)
    local view = slot and OTLGM_DB.settings.savedRosterViews[slot]
    if not view then
        self:Notify("Saved View Empty", "View " .. tostring(slot or "?") .. " has not been saved yet.")
        return
    end
    OTLGM_DB.settings.rosterSearch = view.search or ""
    OTLGM_DB.settings.rosterFilter = view.filter or "ALL"
    OTLGM_DB.settings.rosterRankFilter = view.rank or ""
    OTLGM_DB.settings.rosterProfessionFilter = view.profession or ""
    OTLGM_DB.settings.rosterSortKey = view.sortKey or "RANK"
    OTLGM_DB.settings.rosterSortAsc = view.sortAsc and true or false
    if self.ui then
        self.ui.rosterFilter = OTLGM_DB.settings.rosterFilter
        self.ui.rosterRankFilter = OTLGM_DB.settings.rosterRankFilter ~= "" and OTLGM_DB.settings.rosterRankFilter or nil
        self.ui.rosterProfessionFilter = OTLGM_DB.settings.rosterProfessionFilter ~= "" and OTLGM_DB.settings.rosterProfessionFilter or nil
        self.ui.rosterOffset = 0
        if self.ui.rosterSearch then self.ui.rosterSearch:SetText(OTLGM_DB.settings.rosterSearch) end
    end
    if self.RefreshRosterPage then self:RefreshRosterPage() end
end

function OTLGM.__impl180.GetFilteredHistory__impl1(self, filter, search)
    local db = self:GetGuildDB()
    local list = {}
    if not db then return list end
    search = string.lower(ATrim(search or OTLGM_DB.settings.historySearch or ""))
    local i, eventInfo, allowed
    for i = 1, table.getn(db.log or {}) do
        eventInfo = db.log[i]
        allowed = false
        if eventInfo.hiddenLegacyLevel then
            allowed = false
        else
        if not filter or filter == "ALL" then allowed = true end
        if filter == "UNREAD" and not eventInfo.reviewed then allowed = true end
        if filter == "MEMBERS" and (eventInfo.kind == "JOIN" or eventInfo.kind == "LEAVE") then allowed = true end
        if filter == "MILESTONE" and eventInfo.kind == "LEVEL" then allowed = true end
        if filter == "LEVEL60" and eventInfo.kind == "LEVEL" and eventInfo.milestone == 60 then allowed = true end
        if filter == eventInfo.kind then allowed = true end
        if allowed and search ~= "" then
            local haystack = string.lower((eventInfo.name or "") .. " " .. (eventInfo.actor or "") .. " " .. (eventInfo.detail or "") .. " " .. (eventInfo.rank or ""))
            if not string.find(haystack, search, 1, true) then allowed = false end
        end
        end
        if allowed then table.insert(list, eventInfo) end
    end
    return list
end

function OTLGM:GetHistoryDisplayList(filter, search)
    local events = self:GetFilteredHistory(filter, search)
    local list = {}
    local previousDay = nil
    local today = date("%Y-%m-%d", self:Now())
    local yesterday = date("%Y-%m-%d", self:Now() - 86400)
    local i, eventInfo, dayKey, label
    for i = 1, table.getn(events) do
        eventInfo = events[i]
        dayKey = date("%Y-%m-%d", eventInfo.ts or self:Now())
        if dayKey ~= previousDay then
            if dayKey == today then label = "TODAY - " .. date("%d/%m", eventInfo.ts)
            elseif dayKey == yesterday then label = "YESTERDAY - " .. date("%d/%m", eventInfo.ts)
            else label = date("%A - %d/%m", eventInfo.ts) end
            table.insert(list, { header = true, label = string.upper(label), dayKey = dayKey })
            previousDay = dayKey
        end
        table.insert(list, eventInfo)
    end
    return list
end

function OTLGM:GetMemberRecentHistory(name, limit)
    local db = self:GetGuildDB()
    local result = {}
    if not db or not name then return result end
    local normalized = ANormalizeName(name)
    local i, eventInfo
    for i = 1, table.getn(db.log or {}) do
        eventInfo = db.log[i]
        if ANormalizeName(eventInfo.name) == normalized then
            table.insert(result, eventInfo)
            if table.getn(result) >= (limit or 3) then break end
        end
    end
    return result
end

function OTLGM:SetInactiveStatus(name, status)
    local db = self:GetGuildDB()
    if not db or not name then return end
    db.memberFlags[name] = db.memberFlags[name] or {}
    db.memberFlags[name].inactiveStatus = status or ""
    db.memberFlags[name].inactiveStatusAt = self:Now()
    db.memberFlags[name].inactiveStatusBy = UnitName("player") or ""
    if self.RefreshInactivePage then self:RefreshInactivePage() end
    if self.RefreshRosterPage then self:RefreshRosterPage() end
end

function OTLGM:GetInactiveStatus(name)
    local db = self:GetGuildDB()
    local flags = db and db.memberFlags and db.memberFlags[name]
    return flags and flags.inactiveStatus or ""
end

function OTLGM:GetInactiveList(threshold, statusFilter)
    local db = self:GetGuildDB()
    local result = {}
    if not db then return result end
    threshold = tonumber(threshold) or 30
    statusFilter = statusFilter or "ALL"
    local name, member, status
    for name, member in pairs(db.roster or {}) do
        status = self:GetInactiveStatus(name)
        if not member.online and (member.offlineDays or 0) >= threshold and (statusFilter == "ALL" or status == statusFilter) then
            table.insert(result, member)
        end
    end
    table.sort(result, function(a, b)
        if (a.offlineDays or 0) ~= (b.offlineDays or 0) then return (a.offlineDays or 0) > (b.offlineDays or 0) end
        if (a.rankIndex or 99) ~= (b.rankIndex or 99) then return (a.rankIndex or 99) < (b.rankIndex or 99) end
        return string.lower(a.name or "") < string.lower(b.name or "")
    end)
    return result
end

function OTLGM:GetGuildRankCount170()
    if GuildControlGetNumRanks then
        local ok, count = pcall(GuildControlGetNumRanks)
        count = ok and tonumber(count) or nil
        if count and count > 0 then return count end
    end
    local db = self:GetGuildDB()
    local maximum = -1
    local name, member, rankIndex
    for name, member in pairs(db and db.roster or {}) do
        rankIndex = tonumber(member and member.rankIndex)
        if rankIndex and rankIndex > maximum then maximum = rankIndex end
    end
    if maximum >= 0 then return maximum + 1 end
    return nil
end

function OTLGM:CanUseOfficerActionForMember170(action, memberOrName)
    local member = type(memberOrName) == "table" and memberOrName or self:GetMember(memberOrName)
    if action == "NOTE" then
        if self:CanEditPublicNotes() or self:CanEditOfficerNotes() then return true end
        return false, "Your guild rank cannot edit guild notes."
    end
    if action == "PROMOTE" and not self:CanPromoteMembers() then return false, "Your guild rank cannot promote members." end
    if action == "DEMOTE" and not self:CanDemoteMembers() then return false, "Your guild rank cannot demote members." end
    if action == "REMOVE" and not self:CanRemoveMembers() then return false, "Your guild rank cannot remove members." end
    if not member then return false, "Select a valid guild member first." end

    local playerName = UnitName and UnitName("player") or ""
    if ANormalizeName(member.name) == ANormalizeName(playerName) then return false, "You cannot use this action on your own character." end
    local playerRank = self.GetPlayerGuildRankIndex170 and self:GetPlayerGuildRankIndex170() or nil
    local targetRank = tonumber(member.rankIndex)
    if playerRank ~= nil and targetRank ~= nil then
        if targetRank <= playerRank then return false, "You cannot manage a member at an equal or higher guild rank." end
        if action == "PROMOTE" and targetRank <= playerRank + 1 then
            return false, "This member is already at the highest rank you can promote to."
        end
        if action == "DEMOTE" then
            local rankCount = self:GetGuildRankCount170()
            if rankCount and targetRank >= rankCount - 1 then return false, "This member is already at the lowest guild rank." end
        end
    end
    return true
end

function OTLGM:CanUseOfficerAction(action)
    if action == "PROMOTE" then return self:CanPromoteMembers() end
    if action == "DEMOTE" then return self:CanDemoteMembers() end
    if action == "REMOVE" then return self:CanRemoveMembers() end
    if action == "NOTE" then return self:CanEditPublicNotes() or self:CanEditOfficerNotes() end
    return false
end

function OTLGM:ShowPermissionNotice(action)
    local descriptions = {
        PROMOTE = "Your current guild rank does not have permission to promote members.",
        DEMOTE = "Your current guild rank does not have permission to demote members.",
        REMOVE = "Your current guild rank does not have permission to remove members.",
        NOTE = "Your current guild rank does not have permission to edit guild notes.",
    }
    self:Notify((action or "Action") .. " Unavailable", descriptions[action] or "This action is not available for your guild rank.")
end

function OTLGM:SaveMemberNotes(name, publicNote, officerNote)
    if not self:CanUseOfficerAction("NOTE") then self:ShowPermissionNotice("NOTE") return false end
    local index = self:FindRosterIndex(name)
    if not index then self:Notify("Member Not Found", "Scan the live roster and try again.") return false end
    local changed = false
    if self:CanEditPublicNotes() and GuildRosterSetPublicNote then GuildRosterSetPublicNote(index, publicNote or "") changed = true end
    if self:CanEditOfficerNotes() and GuildRosterSetOfficerNote then GuildRosterSetOfficerNote(index, officerNote or "") changed = true end
    if changed then
        self:RememberGuildAction("NOTE", name, UnitName("player") or "You", "local action")
        if self.SetStatus then self:SetStatus("Notes submitted for " .. tostring(name) .. ".") end
        local live = self.GetLiveRosterEntry180 and self:GetLiveRosterEntry180(name, index) or nil
        if self.BeginRosterAction180 and not self.rosterActionPending180 then
            self:BeginRosterAction180("NOTE", name, publicNote, officerNote, live)
        end
        if self.RequestTargetedRosterRefresh180 and self.rosterActionPending180 then
            self:RequestTargetedRosterRefresh180(true)
        elseif GuildRoster then
            pcall(GuildRoster)
        end
        return true
    end
    return false
end

function OTLGM:ExecuteGuildRankApi180(kind, name, options)
    kind = tostring(kind or "")
    options = type(options) == "table" and options or {}
    local action = kind == "DEMOTE" and "DEMOTE" or "PROMOTE"
    local permissionTarget = options.verifiedMember180 or name
    local allowed, reason = self:CanUseOfficerActionForMember170(action, permissionTarget)
    if not allowed then
        self:Notify(action == "PROMOTE" and "Promotion Unavailable" or "Demotion Unavailable",
            reason or (action == "PROMOTE" and "This member cannot be promoted." or "This member cannot be demoted."))
        return false
    end
    local fn
    if action == "PROMOTE" then fn = GuildPromote or GuildPromoteByName or PromoteByName
    else fn = GuildDemote or GuildDemoteByName or DemoteByName end
    if not fn then
        self:Notify(action == "PROMOTE" and "Promotion Unavailable" or "Demotion Unavailable",
            action == "PROMOTE" and "This client does not expose a promotion function." or "This client does not expose a demotion function.")
        return false
    end
    local ok, errorText = pcall(fn, name)
    if not ok then
        self:Notify(action == "PROMOTE" and "Promotion Failed" or "Demotion Failed",
            tostring(errorText or "The game client rejected the guild rank request."))
        return false
    end
    if self.SetStatus then
        self:SetStatus((action == "PROMOTE" and "Promotion" or "Demotion") .. " requested for " .. tostring(name) .. ".")
    end
    return true
end

function OTLGM:PromoteMember(name, options)
    if type(options) == "table" and options.raw180 then return self:ExecuteGuildRankApi180("PROMOTE", name, options) end
    if self.StartRosterRankAction180 then return self:StartRosterRankAction180("PROMOTE", name) end
    local ok = self:ExecuteGuildRankApi180("PROMOTE", name)
    if ok then
        self:RememberGuildAction("PROMOTE", name, UnitName("player") or "You", "local action")
        if GuildRoster then pcall(GuildRoster) end
    end
    return ok
end

function OTLGM:DemoteMember(name, options)
    if type(options) == "table" and options.raw180 then return self:ExecuteGuildRankApi180("DEMOTE", name, options) end
    if self.StartRosterRankAction180 then return self:StartRosterRankAction180("DEMOTE", name) end
    local ok = self:ExecuteGuildRankApi180("DEMOTE", name)
    if ok then
        self:RememberGuildAction("DEMOTE", name, UnitName("player") or "You", "local action")
        if GuildRoster then pcall(GuildRoster) end
    end
    return ok
end

function OTLGM:FinalizeRosterRemoval180(success, reason)
    local pending = self.rosterRemovalPending180
    if not pending then return false end
    self.rosterRemovalPending180 = nil
    if success then
        local db = self:GetGuildDB()
        local storedName
        if db and db.roster then
            if db.roster[pending.name] then storedName = pending.name
            else
                local candidate
                for candidate in pairs(db.roster) do
                    if self:NormalizeName(candidate) == self:NormalizeName(pending.name) then storedName = candidate break end
                end
            end
            if storedName then db.roster[storedName] = nil end
            db.lastTotal = math.max(0, (tonumber(db.lastTotal) or 1) - (storedName and 1 or 0))
            -- The exact mutation is applied immediately; a later stale-on-open
            -- scan reconciles any unrelated roster changes without blocking this action.
            db.lastScan = 0
            db.lastScanReason = "TARGETED_REMOVE"
        end
        self:RememberGuildAction("REMOVE", pending.name, UnitName("player") or "You", "live targeted confirmation")
        if self.ui and self.ui.rosterSelectedName and self:NormalizeName(self.ui.rosterSelectedName) == self:NormalizeName(pending.name) then
            self.ui.rosterSelectedName = nil
        end
        if self.ShowToast then self:ShowToast(tostring(pending.name) .. " was removed from the guild roster.", "success") end
        if self.ui and self.ui.currentPage == "roster" and self.RefreshRosterPage then self:RefreshRosterPage()
        elseif self.runtime then
            self.runtime.pageDirtyR5 = self.runtime.pageDirtyR5 or {}
            self.runtime.pageDirtyR5.roster = true
        end
        return true
    end
    if self.SetStatus then self:SetStatus(reason or "The removal was not confirmed by the live guild roster.") end
    return false
end

function OTLGM:ProcessRosterRemoval180(force)
    local pending = self.rosterRemovalPending180
    if not pending then return false end
    local now = self:Now()
    if not force and now < (tonumber(pending.nextCheckAt) or 0) then return false end
    local live = self.GetLiveRosterEntry180 and self:GetLiveRosterEntry180(pending.name, pending.rosterIndex) or nil
    if not live then return self:FinalizeRosterRemoval180(true) end
    if now - (tonumber(pending.startedAt) or now) >= 15 then
        return self:FinalizeRosterRemoval180(false, "Removal was not confirmed within 15 seconds; verify the member in the live guild roster before retrying.")
    end
    pending.nextCheckAt = now + 1
    if force or not pending.lastRosterRequestAt or now - pending.lastRosterRequestAt >= 1 then
        pending.lastRosterRequestAt = now
        if SetGuildRosterShowOffline then pcall(SetGuildRosterShowOffline, true) end
        if GuildRoster then pcall(GuildRoster) end
    end
    if self.WakeScheduler180 then self:WakeScheduler180("roster-removal-wait") end
    return false
end

function OTLGM:RemoveMember(name)
    local allowed, reason = self:CanUseOfficerActionForMember170("REMOVE", name)
    if not allowed then self:Notify("Removal Unavailable", reason or "This member cannot be removed.") return false end
    if self.rosterRemovalPending180 or self.rosterActionPending180 then
        if self.SetStatus then self:SetStatus("Another roster action is already waiting for server confirmation.") end
        return false
    end
    local fn = GuildUninvite or GuildUninviteByName or GuildRemove
    if not fn then self:Notify("Removal Unavailable", "This client does not expose a remove-member function.") return false end
    local live = self.GetLiveRosterEntry180 and self:GetLiveRosterEntry180(name) or nil
    local ok, errorText = pcall(fn, name)
    if not ok then self:Notify("Removal Failed", tostring(errorText or "The game client rejected the removal request.")) return false end
    self.rosterRemovalPending180 = {
        name = tostring(live and live.name or name), rosterIndex = live and live.rosterIndex or nil,
        startedAt = self:Now(), nextCheckAt = self:Now() + 1,
    }
    if self.SetStatus then self:SetStatus("Removal requested for " .. tostring(name) .. "; waiting for live confirmation.") end
    if GuildRoster then pcall(GuildRoster) end
    if self.WakeScheduler180 then self:WakeScheduler180("roster-removal") end
    return true
end

function OTLGM:GetLeadershipOnline()
    local db = self:GetGuildDB()
    local list = {}
    if not db then return list end
    local name, member
    for name, member in pairs(db.roster or {}) do
        if member.online and self:IsLeadership(member) then table.insert(list, member) end
    end
    table.sort(list, function(a, b)
        local ar = tonumber(a and a.rankIndex) or 99
        local br = tonumber(b and b.rankIndex) or 99
        if ar ~= br then return ar < br end
        return string.lower((a and a.name) or "") < string.lower((b and b.name) or "")
    end)
    return list
end

function OTLGM:GetPeriodActivityPeak(daysAgoStart, daysAgoEnd)
    local db = self:GetGuildDB()
    if not db or not db.activity then return 0 end
    if self.EnsureActivityServerTimeBasis180 then self:EnsureActivityServerTimeBasis180(db) end
    local now = self:Now()
    local newer = now - ((daysAgoStart or 0) * 86400)
    local older = now - ((daysAgoEnd or 7) * 86400)
    local peak = 0
    local key, day
    for key, day in pairs(db.activity.days or {}) do
        -- Peak windows should be decided by the peak's real timestamp rather
        -- than the day's first sample; otherwise a peak just inside a 7-day
        -- boundary can be excluded because the same day began before it.
        local ts = tonumber(day.peakAt) or tonumber(day.lastSampleAt) or tonumber(day.ts) or 0
        if ts <= newer and ts > older and (day.peak or 0) > peak then peak = day.peak or 0 end
    end
    return peak
end

function OTLGM:GetWeeklyComparison()
    local db = self:GetGuildDB()
    local result = { available = false, current = {}, previous = {}, delta = {}, joins = 0, leaves = 0, net = 0, currentPeak = 0, previousPeak = 0 }
    if not db then return result end
    local roles = self:GetGuildRoleSnapshot()
    local active7 = 0
    local name, member
    for name, member in pairs(db.roster or {}) do
        if member.online or (tonumber(member.offlineDays) or 9999) <= 7 then active7 = active7 + 1 end
    end
    result.current = { total = db.lastTotal or 0, level60 = roles.level60 or 0, active7 = active7 }
    result.currentPeak = self:GetPeriodActivityPeak(0, 7)
    result.previousPeak = self:GetPeriodActivityPeak(7, 14)
    local stats = self:GetStats(7)
    result.joins, result.leaves, result.net = stats.joins or 0, stats.leaves or 0, stats.net or 0
    local target = self:Now() - (7 * 86400)
    local best, bestDistance
    local key, snapshot
    for key, snapshot in pairs(db.weeklySnapshots or {}) do
        local distance = math.abs((snapshot.ts or 0) - target)
        if distance <= (2 * 86400) and (not bestDistance or distance < bestDistance) then best, bestDistance = snapshot, distance end
    end
    if best then
        result.available = true
        result.previous = { total = best.total or 0, level60 = best.level60 or 0, active7 = best.active7 or 0, ts = best.ts }
        result.delta = { total = result.current.total - result.previous.total, level60 = result.current.level60 - result.previous.level60, active7 = result.current.active7 - result.previous.active7, peak = result.currentPeak - result.previousPeak }
    end
    return result
end

function OTLGM:GenerateWeeklySummary()
    local db = self:GetGuildDB()
    if not db then return "No guild data is available." end
    local stats = self:GetStats(7)
    local activity = self:GetActivitySummary(7)
    return "Order of the Lion - Weekly Summary\n\n" ..
        "Members: " .. tostring(db.lastTotal or 0) .. "\n" ..
        "Online now: " .. tostring(db.lastOnline or 0) .. "\n" ..
        "Peak online: " .. tostring(math.floor(activity.periodPeak or 0)) .. "\n" ..
        "Joined: " .. tostring(stats.joins) .. "\n" ..
        "Left: " .. tostring(stats.leaves) .. "\n" ..
        "Net growth: " .. (stats.net >= 0 and "+" or "") .. tostring(stats.net) .. "\n" ..
        "Returned players: " .. tostring(stats.returns) .. "\n" ..
        "Milestone levels: " .. tostring(stats.levels) .. "\n" ..
        "Reached level 60: " .. tostring(stats.level60) .. "\n" ..
        "Rank changes: " .. tostring(stats.ranks) .. "\n" ..
        "Generated: " .. self:Stamp(self:Now())
end

function OTLGM:GetFreshnessText(timestamp)
    if not timestamp then return "NO DATA", self.colors.red end
    local elapsed = self:Now() - timestamp
    if elapsed < 1800 then return "LIVE - " .. self:FormatElapsedShort(elapsed), self.colors.green end
    if elapsed < 7200 then return "SAVED - " .. self:FormatElapsedShort(elapsed), self.colors.gold end
    return "STALE - " .. self:FormatElapsedShort(elapsed), self.colors.red
end

function OTLGM.__impl180.Stage_Advanced_GetDiagnosticsText_1__impl1(self)
    local db = self:GetGuildDB()
    if not db then return "No guild database is available for this character." end
    local apiRoster = GetGuildRosterInfo and "Available" or "Missing"
    local apiLastOnline = GetGuildRosterLastOnline and "Available" or "Missing"
    local apiAddon = SendAddonMessage and "Available" or "Missing"
    local versionUsers, latestVersion, versionOnline = self:GetDetectedAddonUsers(86400)
    local networkTotal, networkCritical, networkNormal, networkBulk = 0, 0, 0, 0
    if self.GetNetworkQueueDepth then networkTotal, networkCritical, networkNormal, networkBulk = self:GetNetworkQueueDepth() end
    local permissionFlags = self.GetGuildPermissionFlags170 and self:GetGuildPermissionFlags170(true) or {}
    local permissionSummary = tostring(permissionFlags.source or "unavailable") .. " / P:" .. (permissionFlags.promote and "yes" or "no") ..
        " D:" .. (permissionFlags.demote and "yes" or "no") .. " R:" .. (permissionFlags.remove and "yes" or "no")
    return "Addon version: " .. self.version .. "\n" ..
        "Build: " .. tostring(self.build or "unknown") .. "\n" ..
        "Interface target: 11200\n" ..
        "Current mode: " .. (self:IsOfficerMode() and "Officer" or "Member") .. "\n" ..
        "Roster API: " .. apiRoster .. "\n" ..
        "Last-online API: " .. apiLastOnline .. "\n" ..
        "Addon messages: " .. apiAddon .. "\n" ..
        "Guild action permissions: " .. permissionSummary .. "\n" ..
        "Player guild rank index: " .. tostring(self.GetPlayerGuildRankIndex170 and self:GetPlayerGuildRankIndex170() or "unknown") .. "\n" ..
        "Roster entries: " .. tostring(TableCount(db.roster)) .. "\n" ..
        "History entries: " .. tostring(table.getn(db.log or {})) .. "\n" ..
        "Unread events: " .. tostring(db.unread or 0) .. "\n" ..
        "Valid backup snapshots: " .. tostring(table.getn(db.snapshots or {})) .. "\n" ..
        "Stored scan records: " .. tostring(table.getn(db.scans or {})) .. "\n" ..
        "Activity days: " .. tostring(TableCount(db.activity and db.activity.days or {})) .. "\n" ..
        "Other addon users seen in 24h: " .. tostring(versionUsers) .. " (" .. tostring(versionOnline) .. " online)\n" ..
        "Network queue total (critical/normal/bulk): " .. tostring(networkTotal) .. " (" .. tostring(networkCritical) .. "/" .. tostring(networkNormal) .. "/" .. tostring(networkBulk) .. ")\n" ..
        "Crafting characters: " .. tostring(self.GetCraftingSummary and self:GetCraftingSummary().characters or 0) .. "\n" ..
        "Shared unique recipes: " .. tostring(self.GetCraftingSummary and self:GetCraftingSummary().uniqueRecipes or 0) .. "\n" ..
        "Crafting requests: " .. tostring(self.GetCraftingSummary and self:GetCraftingSummary().requests or 0) .. "\n" ..
        "Last successful scan: " .. self:Stamp(db.lastScan)
end

function OTLGM.__impl180.BroadcastVersion__impl1(self, target)
    if not SendAddonMessage or not GetGuildInfo("player") then return false end
    self.lastVersionBroadcastAt = self:Now()
    local ownFaction180 = UnitFactionGroup and UnitFactionGroup("player") or ""
    local payload = table.concat({ "V", tostring(self.version or "Detected"), tostring(self.build or "unknown"), tostring(ownFaction180 or "") }, "^")
    if target and target ~= "" then
        return self:QueueNetworkPayload(payload, "WHISPER", target, 2, "presence")
    else
        return self:QueueNetworkPayload(payload, "GUILD", nil, 2, "presence", "presence:version")
    end
end

function OTLGM:RequestAddonUserPing()
    if not SendAddonMessage or not GetGuildInfo("player") then return false end
    local now = self:Now()
    if self.lastAddonUserPingAt and (now - self.lastAddonUserPingAt) < 10 then
        if self.RefreshAddonUsersIndicator then self:RefreshAddonUsersIndicator() end
        return false
    end
    self.lastAddonUserPingAt = now
    local ownFaction180 = UnitFactionGroup and UnitFactionGroup("player") or ""
    self:QueueNetworkPayload(table.concat({ "Q", tostring(self.version or "Detected"), tostring(self.build or "unknown"), tostring(ownFaction180 or "") }, "^"), "GUILD", nil, 2, "presence", "presence:query")
    -- PvE synchronization uses the same hidden addon channel. Triggering both paths
    -- makes presence detection reliable even on servers that handle guild pings oddly.
    if self.RequestPveSync then self:RequestPveSync(true) end
    if self.SetStatus then self:SetStatus("Checking for other Order of the Lion addon users...") end
    return true
end

function OTLGM:RememberAddonUser(sender, version, build, faction)
    self:EnsureDB()
    local db = self:GetGuildDB()
    if not db or not sender or sender == "" then return end
    local playerName = UnitName("player") or ""
    if ANormalizeName(sender) == ANormalizeName(playerName) then return end
    db.detectedVersions = db.detectedVersions or {}
    local key = string.gsub(sender, "%-.*$", "")
    local existing = db.detectedVersions[key] or db.detectedVersions[sender]
    if type(existing) ~= "table" then existing = nil end
    local storedVersion = version
    if not storedVersion or storedVersion == "" or storedVersion == "Detected" then
        storedVersion = existing and existing.version or "Detected"
    end
    local storedBuild = self:SafeText(build or "", 48, false, false)
    if storedBuild == "" then storedBuild = existing and existing.build or nil end
    local storedFaction180 = existing and existing.faction180 or nil
    if faction and faction ~= "" and self.RememberRosterFaction180 then
        self:RememberRosterFaction180(sender, faction, "presence")
        local member180 = self:GetMember(sender)
        if member180 and (member180.faction180 == "Alliance" or member180.faction180 == "Horde") then storedFaction180 = member180.faction180 end
    end
    db.detectedVersions[key] = { version = storedVersion, build = storedBuild, faction180 = storedFaction180, ts = self:Now(), sender = sender }
    if sender ~= key then db.detectedVersions[sender] = nil end
    if storedVersion ~= "Detected" and self:IsVersionNewer(storedVersion, OTLGM_DB.settings.latestDetectedVersion or self.version) then
        OTLGM_DB.settings.latestDetectedVersion = storedVersion
    end
end

function OTLGM:HandlePresenceAddonMessageLegacy(prefix, message, channel, sender)
    if prefix ~= "OTLGM" or not message or not sender then return false end
    if ANormalizeName(sender) == ANormalizeName(UnitName("player") or "") then return true end

    -- Every valid message proves that the sender is currently running the addon.
    -- Presence V/Q packets are parsed below and must only touch detectedVersions
    -- once; older code wrote the same sender twice for every ping/reply.
    local prefix2 = string.sub(message, 1, 2)
    local directPresence180 = prefix2 == "V^" or prefix2 == "Q^" or prefix2 == "V|" or prefix2 == "Q|"
    if not directPresence180 then
        local detectedVersion = nil
        if string.sub(message, 1, 3) == "P1^" then
            local _, _, syncVersion = string.find(message, "^P1%^SYNC%^[^^]*%^([^%^]+)")
            detectedVersion = syncVersion
        end
        self:RememberAddonUser(sender, detectedVersion)
    end

    if self.HandleCommunityAddonMessage and string.sub(message, 1, 3) == "C1^" then
        local handled = self:HandleCommunityAddonMessage(message, channel, sender)
        if self.RefreshAddonUsersIndicator then self:RefreshAddonUsersIndicator() end
        return handled
    end

    if self.HandlePveAddonMessage and string.sub(message, 1, 3) == "P1^" then
        local handled = self:HandlePveAddonMessage(message, channel, sender)
        if self.RefreshAddonUsersIndicator then self:RefreshAddonUsersIndicator() end
        return handled
    end

    local presenceFields = self:Split(message, "^")
    local presenceKind = presenceFields[1] or ""
    local version, build, faction180
    if presenceKind == "V" or presenceKind == "Q" then
        version = presenceFields[2]
        build = presenceFields[3]
        faction180 = presenceFields[4]
    else
        -- Compatibility with 1.7.1 and older copies. These packets may contain
        -- raw pipes, but 1.7.2 never sends them itself.
        local _, _, legacyKind, legacyVersion = string.find(message, "^([VQ])|(.+)$")
        presenceKind = legacyKind or ""
        version = legacyVersion
    end
    if (presenceKind == "V" or presenceKind == "Q") and version and version ~= "" then
        self:RememberAddonUser(sender, version, build, faction180)
        local uiVisible = self.ui and self.ui.main and self.ui.main:IsVisible()
        if presenceKind == "Q" then
            local now = self:Now()
            self.addonReplyTimes = self.addonReplyTimes or {}
            local normalized = ANormalizeName(sender)
            if not self.addonReplyTimes[normalized] or (now - self.addonReplyTimes[normalized]) >= 5 then
                self.addonReplyTimes[normalized] = now
                self:BroadcastVersion(sender)
            end
        end
        if uiVisible and self.RefreshAddonUsersIndicator then self:RefreshAddonUsersIndicator() end
        if uiVisible and self.ui.currentPage == "overview" and self.RefreshOverviewPage then self:RefreshOverviewPage() end
        if uiVisible and self.ui.currentPage == "settings" and self.RefreshSettingsPage then self:RefreshSettingsPage() end
        return true
    end
    return false
end

function OTLGM:GetDetectedAddonUserList(maxAge)
    local db = self:GetGuildDB()
    local list = {}
    if not db then return list end
    local now = self:Now()
    local cutoff = now - (maxAge or 86400)
    local sender, info
    for sender, info in pairs(db.detectedVersions or {}) do
        if type(info) == "table" and tonumber(info.ts) and info.ts >= cutoff then
            local shortName = string.gsub(sender, "%-.*$", "")
            local member = self:GetMember(shortName)
            -- A packet received in the last five minutes is itself proof that the
            -- character is online, even if the local roster snapshot is older.
            local recentlySeen = (now - (info.ts or 0)) <= 300
            table.insert(list, {
                sender = info.sender or sender,
                name = shortName,
                version = info.version or "Detected",
                build = info.build,
                ts = info.ts,
                online = recentlySeen or (member and member.online and true or false),
                class = member and member.class or "",
                rank = member and member.rank or "",
                level = member and member.level or 0,
                leadership = member and self:IsLeadership(member) or false,
            })
        end
    end
    table.sort(list, function(a, b)
        if a.online ~= b.online then return a.online and true or false end
        if (a.ts or 0) ~= (b.ts or 0) then return (a.ts or 0) > (b.ts or 0) end
        return string.lower(a.name or "") < string.lower(b.name or "")
    end)
    return list
end

function OTLGM:GetDetectedAddonUsers(maxAge)
    local list = self:GetDetectedAddonUserList(maxAge or 86400)
    local latest = self.version
    local online = 0
    local i, info
    for i = 1, table.getn(list) do
        info = list[i]
        if info.online then online = online + 1 end
        if info.version ~= "Detected" and self:IsVersionNewer(info.version, latest) then latest = info.version end
    end
    return table.getn(list), latest, online
end

local function UnescapeField(value)
    value = tostring(value or "")
    value = string.gsub(value, "%%0A", "\n")
    value = string.gsub(value, "%%0D", "\r")
    value = string.gsub(value, "%%7C", "|")
    value = string.gsub(value, "%%25", "%%")
    return value
end

function OTLGM:_Legacy_ImportBackupV1(text)
    text = text or ""
    if not string.find(text, "^OTLGM_BACKUP_V1") then return false, "The text is not an Order of the Lion v1 backup." end
    local db = self:GetGuildDB()
    if not db then return false, "No current guild database is available." end

    local importedLog = {}
    local importedFlags = {}
    local importedSettings = {}
    local line
    for line in string.gfind(text, "[^\n]+") do
        local fields = {}
        local field
        for field in string.gfind(line .. "|", "(.-)|") do table.insert(fields, field) end
        if fields[1] == "S" and fields[2] then importedSettings[fields[2]] = UnescapeField(fields[3]) end
        if fields[1] == "F" and fields[2] then
            importedFlags[UnescapeField(fields[2])] = {
                inactiveStatus = UnescapeField(fields[3]),
                inactiveStatusAt = tonumber(fields[4]) or 0,
                inactiveStatusBy = UnescapeField(fields[5]),
            }
        end
        if fields[1] == "E" then
            table.insert(importedLog, 1, {
                ts = tonumber(fields[2]) or self:Now(),
                kind = UnescapeField(fields[3]),
                name = UnescapeField(fields[4]),
                detail = UnescapeField(fields[5]),
                actor = UnescapeField(fields[6]),
                source = UnescapeField(fields[7]),
                class = UnescapeField(fields[8]),
                rank = UnescapeField(fields[9]),
                rankBefore = UnescapeField(fields[10]),
                rankAfter = UnescapeField(fields[11]),
                levelBefore = tonumber(fields[12]),
                levelAfter = tonumber(fields[13]),
                milestone = tonumber(fields[14]),
                reviewed = fields[15] == "1",
            })
        end
    end

    if table.getn(importedLog) == 0 then return false, "The backup contains no history entries." end
    db.log = importedLog
    db.memberFlags = importedFlags
    db.unread = 0
    local i
    for i = 1, table.getn(db.log) do if not db.log[i].reviewed then db.unread = db.unread + 1 end end

    local key, value
    for key, value in pairs(importedSettings) do
        if value == "true" then OTLGM_DB.settings[key] = true
        elseif value == "false" then OTLGM_DB.settings[key] = false
        elseif tonumber(value) then OTLGM_DB.settings[key] = tonumber(value)
        else OTLGM_DB.settings[key] = value end
    end
    if self.RefreshVisiblePage then self:RefreshVisiblePage() elseif self.RefreshAll then self:RefreshAll() end
    return true, "Imported " .. tostring(table.getn(importedLog)) .. " history entries."
end

function OTLGM:RenameCustomMessage(index, newName)
    self:EnsureDB()
    index = tonumber(index)
    newName = ATrim(newName or "")
    if not index or index < 1 or index > 3 then return end
    if newName == "" then newName = "Custom " .. tostring(index) end
    OTLGM_DB.settings.customMessageNames[index] = newName
    if self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
end

local function ANormalizeRecruitmentText180(value)
    value = tostring(value or "")
    value = string.gsub(value, "|c%x%x%x%x%x%x%x%x", "")
    value = string.gsub(value, "|r", "")
    value = string.gsub(value, "|T.-|t", "")
    value = string.gsub(value, "|H.-|h(.-)|h", "%1")
    value = string.gsub(value, "[%c]+", " ")
    value = string.gsub(value, "%s+", " ")
    return string.lower(ATrim(value))
end

local function ANormalizeRecruitmentSender180(value)
    value = tostring(value or "")
    value = string.gsub(value, "|c%x%x%x%x%x%x%x%x", "")
    value = string.gsub(value, "|r", "")
    value = string.gsub(value, "^%[", "")
    value = string.gsub(value, "%]$", "")
    return ANormalizeName(value)
end

function OTLGM:RecordRecruitmentDiagnostic180(eventName, pending, details, result)
    self.runtime = self.runtime or {}
    self.runtime.recruitmentDiagnostics180 = self.runtime.recruitmentDiagnostics180 or {}
    OTLGM_DB.settings.recruitmentDiagnostics180 = OTLGM_DB.settings.recruitmentDiagnostics180 or {}
    local row = {
        ts = self:Now(),
        event = tostring(eventName or "UNKNOWN"),
        sender = details and tostring(details.sender or "") or "",
        channelId = details and tonumber(details.channelId) or nil,
        channelName = details and tostring(details.channelName or "") or "",
        textMatched = details and details.textMatched and true or false,
        senderMatched = details and details.senderMatched and true or false,
        channelMatched = details and details.channelMatched and true or false,
        result = tostring(result or "pending"),
        eventClock = details and tonumber(details.eventClock) or nil,
        evidenceSlot = details and tostring(details.evidenceSlot or "") or "",
        awaitingEcho = pending and pending.awaitingEcho and true or false,
        target = pending and pending.target or nil,
        label = pending and pending.label or nil,
    }
    table.insert(self.runtime.recruitmentDiagnostics180, 1, row)
    table.insert(OTLGM_DB.settings.recruitmentDiagnostics180, 1, CopySimpleTable(row))
    while table.getn(self.runtime.recruitmentDiagnostics180) > 30 do table.remove(self.runtime.recruitmentDiagnostics180) end
    while table.getn(OTLGM_DB.settings.recruitmentDiagnostics180) > 20 do table.remove(OTLGM_DB.settings.recruitmentDiagnostics180) end
    return row
end

function OTLGM:BeginRecruitmentDelivery180(message, target, key, label, rotateAfter)
    message = ATrim(message or "")
    target = target == "GUILD" and "GUILD" or "WORLD"
    if message == "" then self:Notify("Message Empty", "Enter or select a message before sending.") return false end
    if self.recruitmentDeliveryPending180 then
        self:Notify("Delivery Pending", "Wait for the current recruitment message to be confirmed or time out before sending another one.")
        return false
    end

    local chatType, channelId, channelName
    if target == "GUILD" then
        if not GetGuildInfo or not GetGuildInfo("player") then
            self:Notify("Guild Message Failed", "You are not currently in a guild.")
            return false
        end
        chatType = "GUILD"
        channelName = "Guild"
    else
        local timing = self.GetWorldRecruitmentInfo and self:GetWorldRecruitmentInfo() or nil
        if timing and timing.state == "WAIT" then
            self:Notify("World Recruitment Cooldown", timing.detail or "Wait before posting another recruitment message.")
            if self.SetStatus then self:SetStatus("World recruitment cooldown is still active.") end
            self:RecordRecruitmentDiagnostic180("SEND_BLOCKED", nil, { channelName = "World" }, "cooldown")
            return false
        end
        local requested = self:GetWorldChannelNumber()
        if not requested or not GetChannelName then
            self:Notify("World Channel Not Found", "Join the World channel or enter its real channel number before sending.")
            if self.SetStatus then self:SetStatus("Channel unavailable. Message was not sent.") end
            return false
        end
        local ok, resolvedId, resolvedName = pcall(GetChannelName, requested)
        resolvedId = ok and tonumber(resolvedId) or nil
        if not resolvedId or resolvedId <= 0 then
            self:Notify("World Channel Not Found", "The selected channel is not joined. The recruitment timer and A/B rotation were not changed.")
            if self.SetStatus then self:SetStatus("Channel unavailable. Message was not sent.") end
            self:RecordRecruitmentDiagnostic180("SEND_BLOCKED", nil, { channelId = resolvedId, channelName = resolvedName }, "channel-missing")
            return false
        end
        channelId = math.floor(resolvedId)
        channelName = tostring(resolvedName or OTLGM_DB.settings.worldChannelName153 or "World")
        chatType = "CHANNEL"
        OTLGM_DB.settings.worldChannel = tostring(channelId)
        if channelName ~= "" then OTLGM_DB.settings.worldChannelName153 = channelName end
    end

    local pending = {
        message = message,
        normalizedMessage = ANormalizeRecruitmentText180(message),
        target = target,
        channelId = channelId,
        channelName = channelName,
        key = key or "WORKING",
        label = label or "Recruitment",
        rotateAfter = rotateAfter and true or false,
        startedAt = self:Now(),
        startedClock = GetTime and GetTime() or nil,
        timeoutAt = self:Now() + 18,
        awaitingEcho = false,
    }
    self.recruitmentDeliveryPending180 = pending
    if self.WakeScheduler180 then self:WakeScheduler180("recruitment-delivery") end
    if self.SetStatus then self:SetStatus("Sending…") end
    if self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
    self:RecordRecruitmentDiagnostic180("SEND_REQUEST", pending, { channelId = channelId, channelName = channelName }, "sending")

    local ok, errorText
    if chatType == "GUILD" then ok, errorText = pcall(SendChatMessage, message, "GUILD")
    else ok, errorText = pcall(SendChatMessage, message, "CHANNEL", nil, channelId) end
    if not ok then
        self.recruitmentDeliveryPending180 = nil
        self:Notify("Recruitment Send Failed", tostring(errorText or "The game client rejected the message."))
        if self.SetStatus then self:SetStatus("Unable to send recruitment message.") end
        self:RecordRecruitmentDiagnostic180("SEND_ERROR", pending, { channelId = channelId, channelName = channelName }, tostring(errorText or "rejected"))
        return false
    end
    pending.sentAt = self:Now()
    pending.sentClock = GetTime and GetTime() or pending.startedClock
    pending.awaitingEcho = true
    pending.timeoutAt = pending.sentAt + 18
    if self.SetStatus then self:SetStatus(target == "WORLD" and "Waiting for World echo…" or "Waiting for Guild echo…") end
    if self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
    return true
end

local function ANormalizeRecruitmentChannel180(value)
    value = tostring(value or "")
    value = string.gsub(value, "|c%x%x%x%x%x%x%x%x", "")
    value = string.gsub(value, "|r", "")
    value = string.gsub(value, "^%s*%d+%.%s*", "")
    value = string.gsub(value, "^%[", "")
    value = string.gsub(value, "%]$", "")
    value = string.gsub(value, "%s+", " ")
    return string.lower(ATrim(value))
end

local function AExtractRecruitmentChannelEvidence180(pending, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    local values = {
        { slot = "arg8", value = arg8, kind = "id" },
        { slot = "arg9", value = arg9, kind = "name" },
        { slot = "arg4", value = arg4, kind = "name" },
        { slot = "arg3", value = arg3, kind = "either" },
        { slot = "arg5", value = arg5, kind = "either" },
        { slot = "arg6", value = arg6, kind = "either" },
        { slot = "arg7", value = arg7, kind = "either" },
    }
    local expectedId = tonumber(pending and pending.channelId)
    local expectedName = ANormalizeRecruitmentChannel180(pending and pending.channelName or "World")
    local details = { channelMatched = false }
    local index, evidence, numeric, normalized
    for index = 1, table.getn(values) do
        evidence = values[index]
        numeric = tonumber(evidence.value)
        if numeric and numeric > 0 and evidence.kind ~= "name" then
            if expectedId and math.floor(numeric) == math.floor(expectedId) then
                details.channelMatched = true
                details.channelId = math.floor(numeric)
                details.evidenceSlot = evidence.slot
                return details
            end
        elseif type(evidence.value) == "string" and evidence.value ~= "" and evidence.kind ~= "id" then
            normalized = ANormalizeRecruitmentChannel180(evidence.value)
            if normalized ~= "" and expectedName ~= ""
                and (normalized == expectedName
                    or string.find(normalized, expectedName, 1, true)
                    or string.find(expectedName, normalized, 1, true)) then
                details.channelMatched = true
                details.channelName = tostring(evidence.value)
                details.evidenceSlot = evidence.slot
                return details
            end
        end
    end
    return details
end

function OTLGM:HandleRecruitmentDeliveryEcho180(channel, message, sender, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    local pending = self.recruitmentDeliveryPending180
    if not pending then return false end
    channel = channel == "GUILD" and "GUILD" or "WORLD"
    if pending.target ~= channel or not pending.awaitingEcho then return false end

    local currentClock = GetTime and GetTime() or nil
    local details = {
        sender = sender,
        textMatched = ANormalizeRecruitmentText180(message) == pending.normalizedMessage,
        senderMatched = ANormalizeRecruitmentSender180(sender) == ANormalizeRecruitmentSender180(UnitName("player") or ""),
        channelMatched = channel == "GUILD",
        eventClock = currentClock,
        evidenceSlot = channel == "GUILD" and "CHAT_MSG_GUILD" or "",
    }
    if channel == "WORLD" then
        local channelDetails = AExtractRecruitmentChannelEvidence180(pending, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        details.channelMatched = channelDetails.channelMatched
        details.channelId = channelDetails.channelId
        details.channelName = channelDetails.channelName
        details.evidenceSlot = channelDetails.evidenceSlot
    end

    -- Only a chat event observed after SendChatMessage returned can confirm
    -- delivery. This prevents an old history line or a synchronous stale event
    -- from starting the cooldown or rotating A/B.
    local fresh = not pending.sentClock or not currentClock or currentClock >= pending.sentClock
    local matched = fresh and details.textMatched and details.senderMatched and details.channelMatched
    self:RecordRecruitmentDiagnostic180(channel == "WORLD" and "CHAT_MSG_CHANNEL" or "CHAT_MSG_GUILD", pending, details, matched and "matched" or "ignored")
    if not matched then return false end

    self.recruitmentDeliveryPending180 = nil
    self:MarkRecruitmentSent(pending.key, pending.target, pending.label)
    if pending.rotateAfter then
        OTLGM_DB.settings.nextRecruitIndex = (OTLGM_DB.settings.nextRecruitIndex or 1) == 1 and 2 or 1
    end
    if self.SetStatus then self:SetStatus("Delivered — confirmed by a new chat echo.") end
    if self.ShowToast then self:ShowToast("Recruitment message delivered.", "success") end
    if self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
    return true
end

function OTLGM:ProcessRecruitmentDelivery180()
    local pending = self.recruitmentDeliveryPending180
    if not pending then return end
    if self:Now() < (tonumber(pending.timeoutAt) or ((tonumber(pending.startedAt) or self:Now()) + 18)) then return end
    self.recruitmentDeliveryPending180 = nil
    if self.SetStatus then self:SetStatus("Delivery not confirmed.") end
    self:RecordRecruitmentDiagnostic180("DELIVERY_TIMEOUT", pending, { channelId = pending.channelId, channelName = pending.channelName }, "timeout")
    self:Notify("Delivery Not Confirmed", "No matching new self-echo arrived from chat. The timer, cooldown and A/B rotation were not changed. Use Open in Chat if the server blocks reliable confirmation.")
    if self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
end

function OTLGM:OpenRecruitmentInChat180(message, target)
    message = ATrim(message or "")
    if message == "" then self:Notify("Message Empty", "Enter or select a message before opening chat.") return false end
    target = target == "GUILD" and "GUILD" or "WORLD"
    local prefix
    if target == "GUILD" then prefix = "/g "
    else
        local channelId = self:GetWorldChannelNumber()
        if not channelId then
            self:Notify("World Channel Not Found", "Join the World channel before opening this message in chat.")
            return false
        end
        prefix = "/" .. tostring(channelId) .. " "
    end
    local text = prefix .. message
    if ChatFrame_OpenChat then ChatFrame_OpenChat(text)
    elseif ChatFrameEditBox then ChatFrameEditBox:Show() ChatFrameEditBox:SetText(text) ChatFrameEditBox:SetFocus()
    else return false end
    if self.SetStatus then self:SetStatus("Prepared in the standard chat input. Press Enter to send.") end
    return true
end

function OTLGM:SendMessageText(message, target)
    return self:BeginRecruitmentDelivery180(message, target, "WORKING", "Working Copy", false)
end

OTLGM:RegisterModule("Roster", { layer = "feature", owns = { "RequestScan", "Scan", "GetSortedRoster" } })
