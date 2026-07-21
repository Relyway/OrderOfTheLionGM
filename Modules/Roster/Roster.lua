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

local BaseEnsureDB = OTLGM.ApplyCoreDefaults
local BaseGetGuildDB = OTLGM.GetOrCreateGuildDB
local BaseMigrateGuildDB = OTLGM.MigrateLegacySchema2

function OTLGM:ApplyAdvancedDefaults()
    BaseEnsureDB(self)
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
    BaseMigrateGuildDB(self, db)
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

    -- Guild ranks are authoritative. Names may be changed by the guild without
    -- breaking icons or ordering. Rank index 0 is always the guild leader.
    if index == 0 then
        return "Interface\\Icons\\INV_Crown_01", rankLabel, 1.0, 0.76, 0.18
    end
    if index == 1 then
        return "Interface\\Icons\\INV_Shield_06", rankLabel, 1.0, 0.50, 0.12
    end
    if index == 2 then
        return "Interface\\Icons\\Spell_Holy_Heal", rankLabel, 0.95, 0.62, 0.18
    end

    -- Defensive compatibility for old snapshots that predate rank indexes.
    local rank = string.lower(member.rank or "")
    if string.find(rank, "guild leader", 1, true) or string.find(rank, "guild master", 1, true) then
        return "Interface\\Icons\\INV_Crown_01", rankLabel, 1.0, 0.76, 0.18
    end
    if string.find(rank, "officer", 1, true) or string.find(rank, "helper", 1, true) then
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

function OTLGM:_Stage_Advanced_RequestScan_2(reason)
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
end

function OTLGM:IsSuspiciousSnapshot(db, current, total)
    if not db.initialized then return false end
    local previousTotal = db.lastTotal or TableCount(db.roster)
    if previousTotal < 20 then return false end
    local missing = 0
    local name
    for name in pairs(db.roster or {}) do
        if not current[name] then missing = missing + 1 end
    end
    local threshold = math.max(10, math.floor(previousTotal * 0.12))
    return total < math.floor(previousTotal * 0.85) and missing >= threshold, previousTotal, missing
end

function OTLGM:RecordActivitySample(db, total, online)
    db.activity = db.activity or { days = {}, allTimePeak = 0, allTimePeakAt = nil, totalScans = 0 }
    local activity = db.activity
    local now = self:Now()
    local dayKey = date("%Y-%m-%d", now)
    local hour = tonumber(date("%H", now)) or 0
    local weekday = tonumber(date("%w", now)) or 0
    local day = activity.days[dayKey]
    if not day then
        day = { ts = now, weekday = weekday, peak = 0, peakAt = nil, sum = 0, count = 0, hours = {} }
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
        if item.ts and item.ts < cutoff then activity.days[key] = nil end
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
}

function OTLGM:CarryMemberMetadata(old, current)
    if not old or not current then return end
    local i, field
    for i = 1, table.getn(metadataFields) do
        field = metadataFields[i]
        current[field] = old[field]
    end
end

function OTLGM:_Stage_Advanced_Scan_2(reason)
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

    local suspicious, previousTotal, missing = self:IsSuspiciousSnapshot(db, current, total)
    if suspicious then
        local signature = self:GetSnapshotSignature(current)
        local candidate = db.suspiciousCandidate
        if candidate and candidate.signature == signature and (self:Now() - (candidate.ts or 0)) <= 45 then
            db.suspiciousCandidate = nil
            self.suspiciousScanAttempts = 0
        else
            if reason ~= "CONFIRM" then self.confirmOriginReason = reason end
            self.suspiciousScanAttempts = (self.suspiciousScanAttempts or 0) + 1
            db.suspiciousCandidate = { signature = signature, ts = self:Now(), total = total, previousTotal = previousTotal, missing = missing, reason = reason }
            self:RecordScan(db, total, online, 0, false, "SUSPICIOUS")
            if self.suspiciousScanAttempts < 3 then
                self:ScheduleConfirmScan()
                if self.SetStatus then
                    self:SetStatus("Incomplete roster suspected: " .. tostring(total) .. " of " .. tostring(previousTotal) .. ". No leave events recorded; confirmation " .. tostring(self.suspiciousScanAttempts) .. " of 3...")
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

function OTLGM:GetStats(days)
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

function OTLGM:_Stage_Advanced_GetActivitySummary_1(days)
    local db = self:GetGuildDB()
    local result = {
        todayPeak = 0, todayPeakAt = nil, periodPeak = 0, periodPeakAt = nil,
        allTimePeak = 0, allTimePeakAt = nil, average = 0, samples = 0,
    }
    if not db or not db.activity then return result end
    local now = self:Now()
    local cutoff = now - ((days or 7) * 86400)
    local todayKey = date("%Y-%m-%d", now)
    local sum, count = 0, 0
    local key, day
    for key, day in pairs(db.activity.days or {}) do
        if key == todayKey then
            result.todayPeak = day.peak or 0
            result.todayPeakAt = day.peakAt
        end
        if (day.ts or 0) >= cutoff then
            if (day.peak or 0) > result.periodPeak then
                result.periodPeak = day.peak or 0
                result.periodPeakAt = day.peakAt
            end
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

function OTLGM:_Stage_Advanced_GetActivityHeatmap_1()
    local db = self:GetGuildDB()
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

function OTLGM:GetComposition(onlineOnly)
    local db = self:GetGuildDB()
    local result = { classes = {}, levels = { low = 0, mid = 0, high = 0, max = 0 }, total = 0 }
    if not db then return result end
    local name, member, class
    for name, member in pairs(db.roster or {}) do
        if not onlineOnly or member.online then
            result.total = result.total + 1
            class = member.class or "Unknown"
            result.classes[class] = (result.classes[class] or 0) + 1
            if (member.level or 0) >= 60 then result.levels.max = result.levels.max + 1
            elseif (member.level or 0) >= 40 then result.levels.high = result.levels.high + 1
            elseif (member.level or 0) >= 20 then result.levels.mid = result.levels.mid + 1
            else result.levels.low = result.levels.low + 1 end
        end
    end
    return result
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

function OTLGM:GetFilteredHistory(filter, search)
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
    if not self:CanUseOfficerAction("NOTE") then self:ShowPermissionNotice("NOTE") return end
    local index = self:FindRosterIndex(name)
    if not index then self:Notify("Member Not Found", "Scan the live roster and try again.") return end
    local changed = false
    if self:CanEditPublicNotes() and GuildRosterSetPublicNote then GuildRosterSetPublicNote(index, publicNote or "") changed = true end
    if self:CanEditOfficerNotes() and GuildRosterSetOfficerNote then GuildRosterSetOfficerNote(index, officerNote or "") changed = true end
    if changed then
        self:RememberGuildAction("NOTE", name, UnitName("player") or "You", "local action")
        if self.SetStatus then self:SetStatus("Notes saved for " .. tostring(name) .. ".") end
        self:RequestScan("INTERNAL")
    end
end

function OTLGM:PromoteMember(name)
    local allowed, reason = self:CanUseOfficerActionForMember170("PROMOTE", name)
    if not allowed then self:Notify("Promotion Unavailable", reason or "This member cannot be promoted.") return end
    local fn = GuildPromote or GuildPromoteByName or PromoteByName
    if not fn then self:Notify("Promotion Unavailable", "This client does not expose a promotion function.") return end
    local ok, errorText = pcall(fn, name)
    if not ok then self:Notify("Promotion Failed", tostring(errorText or "The game client rejected the promotion request.")) return end
    self:RememberGuildAction("PROMOTE", name, UnitName("player") or "You", "local action")
    if self.SetStatus then self:SetStatus("Promotion requested for " .. tostring(name) .. ".") end
    self:RequestScan("INTERNAL")
end

function OTLGM:DemoteMember(name)
    local allowed, reason = self:CanUseOfficerActionForMember170("DEMOTE", name)
    if not allowed then self:Notify("Demotion Unavailable", reason or "This member cannot be demoted.") return end
    local fn = GuildDemote or GuildDemoteByName or DemoteByName
    if not fn then self:Notify("Demotion Unavailable", "This client does not expose a demotion function.") return end
    local ok, errorText = pcall(fn, name)
    if not ok then self:Notify("Demotion Failed", tostring(errorText or "The game client rejected the demotion request.")) return end
    self:RememberGuildAction("DEMOTE", name, UnitName("player") or "You", "local action")
    if self.SetStatus then self:SetStatus("Demotion requested for " .. tostring(name) .. ".") end
    self:RequestScan("INTERNAL")
end

function OTLGM:RemoveMember(name)
    local allowed, reason = self:CanUseOfficerActionForMember170("REMOVE", name)
    if not allowed then self:Notify("Removal Unavailable", reason or "This member cannot be removed.") return end
    local fn = GuildUninvite or GuildUninviteByName or GuildRemove
    if not fn then self:Notify("Removal Unavailable", "This client does not expose a remove-member function.") return end
    local ok, errorText = pcall(fn, name)
    if not ok then self:Notify("Removal Failed", tostring(errorText or "The game client rejected the removal request.")) return end
    self:RememberGuildAction("REMOVE", name, UnitName("player") or "You", "local action")
    if self.SetStatus then self:SetStatus("Removal requested for " .. tostring(name) .. ".") end
    self:RequestScan("INTERNAL")
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
    local now = self:Now()
    local newer = now - ((daysAgoStart or 0) * 86400)
    local older = now - ((daysAgoEnd or 7) * 86400)
    local peak = 0
    local key, day
    for key, day in pairs(db.activity.days or {}) do
        local ts = day.ts or 0
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

function OTLGM:_Stage_Advanced_GetDiagnosticsText_1()
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

function OTLGM:BroadcastVersion(target)
    if not SendAddonMessage or not GetGuildInfo("player") then return false end
    self.lastVersionBroadcastAt = self:Now()
    local payload = table.concat({ "V", tostring(self.version or "Detected"), tostring(self.build or "unknown") }, "^")
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
    self:QueueNetworkPayload(table.concat({ "Q", tostring(self.version or "Detected"), tostring(self.build or "unknown") }, "^"), "GUILD", nil, 2, "presence", "presence:query")
    -- PvE synchronization uses the same hidden addon channel. Triggering both paths
    -- makes presence detection reliable even on servers that handle guild pings oddly.
    if self.RequestPveSync then self:RequestPveSync(true) end
    if self.SetStatus then self:SetStatus("Checking for other Order of the Lion addon users...") end
    return true
end

function OTLGM:RememberAddonUser(sender, version, build)
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
    db.detectedVersions[key] = { version = storedVersion, build = storedBuild, ts = self:Now(), sender = sender }
    if sender ~= key then db.detectedVersions[sender] = nil end
    if storedVersion ~= "Detected" and self:IsVersionNewer(storedVersion, OTLGM_DB.settings.latestDetectedVersion or self.version) then
        OTLGM_DB.settings.latestDetectedVersion = storedVersion
    end
end

function OTLGM:HandlePresenceAddonMessageLegacy(prefix, message, channel, sender)
    if prefix ~= "OTLGM" or not message or not sender then return false end
    if ANormalizeName(sender) == ANormalizeName(UnitName("player") or "") then return true end

    -- Every valid message proves that the sender is currently running the addon.
    -- PvE SYNC packets also carry a precise version in field four.
    local detectedVersion = nil
    if string.sub(message, 1, 3) == "P1^" then
        local _, _, syncVersion = string.find(message, "^P1%^SYNC%^[^^]*%^([^%^]+)")
        detectedVersion = syncVersion
    end
    self:RememberAddonUser(sender, detectedVersion)

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
    local version, build
    if presenceKind == "V" or presenceKind == "Q" then
        version = presenceFields[2]
        build = presenceFields[3]
    else
        -- Compatibility with 1.7.1 and older copies. These packets may contain
        -- raw pipes, but 1.7.2 never sends them itself.
        local _, _, legacyKind, legacyVersion = string.find(message, "^([VQ])|(.+)$")
        presenceKind = legacyKind or ""
        version = legacyVersion
    end
    if (presenceKind == "V" or presenceKind == "Q") and version and version ~= "" then
        self:RememberAddonUser(sender, version, build)
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

function OTLGM:SendMessageText(message, target)
    message = ATrim(message or "")
    if message == "" then self:Notify("Message Empty", "Enter or select a message before sending.") return false end
    if target == "GUILD" then
        local ok, err = pcall(SendChatMessage, message, "GUILD")
        if not ok then self:Notify("Guild Message Failed", tostring(err)) return false end
        if self.SetStatus then self:SetStatus("Message sent to guild chat.") end
        return true
    end

    local channel = self:GetWorldChannelNumber()
    if not channel then self:Notify("Channel Required", "Enter a numeric channel such as 5 or 6.") return false end
    local channelId = channel
    if GetChannelName then
        local resolvedId = GetChannelName(channel)
        if resolvedId and resolvedId > 0 then channelId = resolvedId end
    end
    local ok, err = pcall(SendChatMessage, message, "CHANNEL", nil, channelId)
    if not ok then
        if ChatFrameEditBox then
            ChatFrameEditBox:Show()
            ChatFrameEditBox:SetText("/" .. tostring(channel) .. " " .. message)
            ChatFrameEditBox:SetFocus()
            self:SetStatus("Message placed in chat input. Press Enter to send.")
        else
            self:Notify("World Message Failed", tostring(err))
        end
        return false
    end
    if self.SetStatus then self:SetStatus("Message sent to /" .. tostring(channel) .. ".") end
    return true
end

OTLGM:RegisterModule("Roster", { layer = "feature", owns = { "RequestScan", "Scan", "GetSortedRoster" } })
