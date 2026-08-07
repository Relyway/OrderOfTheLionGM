-- Order of the Lion Guild Manager
-- Core systems for Vanilla WoW / OctoWoW (Interface 11200)

OTLGM = OTLGM or {}
OTLGM.pendingScan = false
OTLGM.pendingSilent = true
OTLGM.elapsed = 0
OTLGM.ui = OTLGM.ui or {}

OTLGM.colors = OTLGM.colors or {
    gold = "|cffffd36b",
    green = "|cff69cc73",
    red = "|cffff7777",
    grey = "|cffaaaaaa",
    darkGrey = "|cff777777",
    white = "|cffffffff",
    blue = "|cff69a8ff",
    purple = "|cffb06cff",
    reset = "|r",
}

OTLGM.classHex = {
    warrior = "|cffc79c6e",
    mage = "|cff69ccf0",
    rogue = "|cfffff569",
    druid = "|cffff7d0a",
    hunter = "|cffabd473",
    shaman = "|cff0070de",
    priest = "|cffffffff",
    warlock = "|cff9482c9",
    paladin = "|cfff58cba",
}


OTLGM.professionDefinitions = {
    { key = "ALCHEMY", label = "Alchemy", terms = { "alchemy", "alchemist" } },
    { key = "COOKING", label = "Cooking", terms = { "cooking", "cook" } },
    { key = "BLACKSMITHING", label = "Blacksmithing", terms = { "blacksmith", "blacksmithing" } },
    { key = "ENCHANTING", label = "Enchanting", terms = { "enchanting", "enchanter" } },
    { key = "ENGINEERING", label = "Engineering", terms = { "engineering", "engineer" } },
    { key = "JEWELCRAFTING", label = "Jewelcrafting", terms = { "jewelcrafting", "jewelcrafter", "jc" } },
    { key = "HERBALISM", label = "Herbalism", terms = { "herbalism", "herbalist" } },
    { key = "LEATHERWORKING", label = "Leatherworking", terms = { "leatherworking", "leatherworker" } },
    { key = "MINING", label = "Mining", terms = { "mining", "miner" } },
    { key = "SKINNING", label = "Skinning", terms = { "skinning", "skinner" } },
    { key = "TAILORING", label = "Tailoring", terms = { "tailoring", "tailor" } },
}



OTLGM.recruitmentPresets = {
    BASE1 = {
        label = "Recruit 1",
        target = "WORLD",
        text = "[ENG/EU] <Order of the Lion> is looking for new, returning and casual players for relaxed PvE, leveling, dungeons, professions and future raids. Active Discord. Formed guild Lions Pride",
    },
    BASE2 = {
        label = "Recruit 2",
        target = "WORLD",
        text = "No one has to level alone. Looking for players who want a calm guild, dungeons, farm, professions and future PvE plans. Formed \"Lion's Pride\", <Order of the Lion> [ENG/EU]",
    },
    GUILDINFO = {
        label = "Guild Info",
        target = "GUILD",
        text = "[G-Info] Join Discord for news, help, groups & future raids. No mic needed. Discord join = first promotion from starter rank: https://discord.gg/UNacDPrGt2",
    },
    ADDONINFO = {
        label = "Share Addon",
        target = "GUILD",
        text = "[Guild Addon] Install OrderOfTheLionGM for improved Guild Chat, member and profession search, Crafting Network, Group Finder, raid alerts and achievements. More users improve shared data. Download: https://github.com/Relyway/OrderOfTheLionGM",
    },
}

local function Trim(text)
    if not text then return "" end
    local trimmed = string.gsub(text, "^%s*(.-)%s*$", "%1")
    return trimmed
end

local function NormalizeName(name)
    name = Trim(name or "")
    local normalized = string.gsub(name, "%-.*$", "")
    return string.lower(normalized)
end

-- Canonical guild-leader identity for guild-specific presentation and
-- achievements.  Server permission checks intentionally remain separate: they
-- still use the live guild APIs/rank flags below and are never granted merely
-- because a character name matches this list.
local CANONICAL_GUILD_LEADERS180 = {
    morrow = true,
    lucks = true,
}

function OTLGM:IsCanonicalGuildLeaderName180(name)
    return CANONICAL_GUILD_LEADERS180[NormalizeName(name)] and true or false
end

function OTLGM:GetCanonicalGuildLeaderName180()
    -- Prefer whichever canonical character is currently represented by the
    -- committed roster as rank 0.  If rank data is stale/missing, prefer an
    -- online canonical character, then any present canonical character.
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local roster = db and db.roster or nil
    local onlineName, storedName
    local key, member
    for key, member in pairs(roster or {}) do
        local name = member and member.name or key
        if self:IsCanonicalGuildLeaderName180(name) then
            if tonumber(member and (member.rankIndex or member.guildRankIndex)) == 0 then return name end
            if member and member.online and not onlineName then onlineName = name end
            if not storedName then storedName = name end
        end
    end
    if onlineName then return onlineName end
    if storedName then return storedName end
    local player = UnitName and UnitName("player") or ""
    if self:IsCanonicalGuildLeaderName180(player) then return player end
    -- Even before the first committed roster arrives, a user-facing leader
    -- target must stay inside the canonical pair rather than falling back to an
    -- unrelated rank-0 cache row. Morrow is the stable default contact.
    return "Morrow"
end

local function SafeBooleanFunction(fn)
    if not fn then return false end
    local ok, result = pcall(fn)
    if not ok then return false end
    return result and true or false
end

function OTLGM:Now()
    return time()
end

function OTLGM:Stamp(timestamp)
    if not timestamp then return "Never" end
    return date("%d/%m/%Y %H:%M", timestamp)
end

function OTLGM:TodayKey()
    return date("%Y-%m-%d")
end

function OTLGM:ApplyCoreDefaults()
    if not OTLGM_DB then OTLGM_DB = {} end
    if not OTLGM_DB.guilds then OTLGM_DB.guilds = {} end
    if not OTLGM_DB.settings then OTLGM_DB.settings = {} end

    local settings = OTLGM_DB.settings
    if settings.autoScan == nil then settings.autoScan = true end
    if settings.chatNotices == nil then settings.chatNotices = true end
    if settings.showMinimap == nil then settings.showMinimap = true end
    if settings.classColors == nil then settings.classColors = true end
    if settings.highlightLeadership == nil then settings.highlightLeadership = true end
    if settings.scanInterval == nil then settings.scanInterval = 600 end
    if settings.minimapX == nil then settings.minimapX = -70 end
    if settings.minimapY == nil then settings.minimapY = -52 end
    if settings.worldChannel == nil or settings.worldChannel == "" or settings.worldChannel == "World" then settings.worldChannel = "6" end
    if settings.customTarget == nil then settings.customTarget = "WORLD" end
    if settings.rosterSortKey == nil then settings.rosterSortKey = "RANK" end
    if settings.rosterSortAsc == nil then settings.rosterSortAsc = true end
    if settings.rosterFilter == nil then settings.rosterFilter = "ALL" end
    if settings.rosterRankFilter == nil then settings.rosterRankFilter = "" end
    if settings.rosterProfessionFilter == nil then settings.rosterProfessionFilter = "" end
    if settings.rosterSearch == nil then settings.rosterSearch = "" end
    if settings.lastPage == nil then settings.lastPage = "overview" end
    if settings.historyFilter == nil then settings.historyFilter = "ALL" end
    if settings.windowX == nil then settings.windowX = 0 end
    if settings.windowY == nil then settings.windowY = 10 end
    if settings.windowWidth180 == nil then settings.windowWidth180 = 1160 end
    if settings.windowHeight180 == nil then settings.windowHeight180 = 740 end
    if settings.windowSizePreset180 == nil then
        -- Existing 1.8 test installs may already contain a manually resized
        -- window but no preset marker. Preserve that geometry as Custom rather
        -- than falsely labelling a 1000x700 window as Normal.
        local savedWidth = tonumber(settings.windowWidth180) or 1160
        local savedHeight = tonumber(settings.windowHeight180) or 740
        if math.abs(savedWidth - 1160) <= 2 and math.abs(savedHeight - 740) <= 2 then
            settings.windowSizePreset180 = "NORMAL"
        else
            settings.windowSizePreset180 = "CUSTOM"
        end
    end
    if settings.keepWindowInsideScreen180 == nil then settings.keepWindowInsideScreen180 = false end
    if settings.customMessageNames == nil then settings.customMessageNames = { "Custom 1", "Custom 2", "Custom 3" } end
    if settings.recruitmentLastSent == nil then settings.recruitmentLastSent = {} end
    if settings.recruitmentReminderSeconds == nil then settings.recruitmentReminderSeconds = 300 end
    if settings.worldRecruitmentMinSeconds == nil then settings.worldRecruitmentMinSeconds = 600 end
    if settings.worldRecruitmentRecommendedSeconds == nil then settings.worldRecruitmentRecommendedSeconds = 900 end
    if settings.guildChatChannel == nil then settings.guildChatChannel = "GUILD" end
    if settings.guildChatDrafts == nil then settings.guildChatDrafts = { GUILD = "", OFFICER = "" } end
    if settings.guildChatDrafts.GUILD == nil then settings.guildChatDrafts.GUILD = "" end
    if settings.guildChatDrafts.OFFICER == nil then settings.guildChatDrafts.OFFICER = "" end
    if settings.chatHighlightMentions == nil then settings.chatHighlightMentions = true end
    if settings.chatTimeSeparators == nil then settings.chatTimeSeparators = true end
    if settings.chatShowRanks == nil then settings.chatShowRanks = true end
    if settings.settingsSection == nil then settings.settingsSection = "GENERAL" end
    if settings.worldRecruitmentTimerMigrated == nil then
        if settings.lastWorldRecruitmentAt == nil then
            local baseOne = tonumber(settings.recruitmentLastSent.BASE1) or 0
            local baseTwo = tonumber(settings.recruitmentLastSent.BASE2) or 0
            if baseOne > 0 or baseTwo > 0 then
                if baseOne >= baseTwo then
                    settings.lastWorldRecruitmentAt = baseOne
                    settings.lastWorldRecruitmentLabel = "Recruit 1"
                else
                    settings.lastWorldRecruitmentAt = baseTwo
                    settings.lastWorldRecruitmentLabel = "Recruit 2"
                end
                settings.lastWorldRecruitmentChannel = tostring(settings.worldChannel or "6")
            end
        end
        settings.worldRecruitmentTimerMigrated = true
    end
    if not settings.customMessageNames[1] then settings.customMessageNames[1] = "Custom 1" end
    if not settings.customMessageNames[2] then settings.customMessageNames[2] = "Custom 2" end
    if not settings.customMessageNames[3] then settings.customMessageNames[3] = "Custom 3" end

    if not settings.customMessages then
        settings.customMessages = { "", "", "" }
        if settings.recruitmentMessage and settings.recruitmentMessage ~= "" then
            settings.customMessages[1] = settings.recruitmentMessage
            settings.selectedRecruitment = "CUSTOM1"
        end
    end
    if not settings.customMessages[1] then settings.customMessages[1] = "" end
    if not settings.customMessages[2] then settings.customMessages[2] = "" end
    if not settings.customMessages[3] then settings.customMessages[3] = "" end

    if not settings.selectedRecruitment then settings.selectedRecruitment = "BASE1" end
    if not settings.recruitmentMessage or settings.recruitmentMessage == "" then
        settings.recruitmentMessage = self:GetRecruitmentText(settings.selectedRecruitment)
        if settings.recruitmentMessage == "" then
            settings.selectedRecruitment = "BASE1"
            settings.recruitmentMessage = self.recruitmentPresets.BASE1.text
        end
    end

    OTLGM_DB.version = self.version
end

function OTLGM:EnsureRecruitmentRotation170()
    OTLGM_DB = OTLGM_DB or {}
    OTLGM_DB.settings = OTLGM_DB.settings or {}
    local settings = OTLGM_DB.settings
    if type(settings.recruitmentRotation170) ~= "table" then settings.recruitmentRotation170 = {} end
    local index
    for index = 1, 2 do
        local key = index == 1 and "BASE1" or "BASE2"
        local original = self.recruitmentPresets[key]
        local slot = settings.recruitmentRotation170[index]
        if type(slot) ~= "table" or type(slot.text) ~= "string" or slot.text == "" then
            settings.recruitmentRotation170[index] = {
                key = key, label = index == 1 and "Recruit A" or "Recruit B", target = "WORLD",
                text = original and original.text or "", updatedAt = 0, revision = 1,
            }
        else
            slot.key = key
            slot.label = slot.label or (index == 1 and "Recruit A" or "Recruit B")
            slot.target = "WORLD"
            slot.revision = tonumber(slot.revision) or 1
        end
    end
    return settings.recruitmentRotation170
end

function OTLGM.__impl180.GetRecruitmentPreset170__impl1(self, key)
    if key == "BASE1" or key == "BASE2" then
        local rotation = self:EnsureRecruitmentRotation170()
        return rotation[key == "BASE1" and 1 or 2]
    end
    return self.recruitmentPresets[key]
end

function OTLGM:ReplaceRecruitmentRotation170(index, text)
    self:EnsureDB()
    if not ((self.CanPublishAnnouncement152 and self:CanPublishAnnouncement152()) or (self.CanEditOfficerNotes and self:CanEditOfficerNotes())) then
        return false, "Only guild leadership can change the recruitment rotation."
    end
    index = tonumber(index)
    if index ~= 1 and index ~= 2 then return false, "Choose rotation A or B." end
    text = self:SafeText(text, 240, false, false)
    if text == "" then return false, "The recruitment message cannot be empty." end
    local rotation = self:EnsureRecruitmentRotation170()
    local old = rotation[index]
    rotation[index] = {
        key = index == 1 and "BASE1" or "BASE2", label = index == 1 and "Recruit A" or "Recruit B", target = "WORLD",
        text = text, updatedAt = self:Now(), updatedBy = string.gsub(UnitName("player") or "Leadership", "%-.*$", ""),
        revision = (tonumber(old and old.revision) or 0) + 1,
    }
    OTLGM_DB.settings.selectedRecruitment = rotation[index].key
    OTLGM_DB.settings.recruitmentMessage = text
    OTLGM_DB.settings.customTarget = "WORLD"
    if self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
    return true, rotation[index]
end

function OTLGM:GetRecruitmentText(key)
    local preset = self:GetRecruitmentPreset170(key)
    if preset then return preset.text or "" end

    local customText = string.gsub(key or "", "^CUSTOM", "")
    local index = tonumber(customText)
    if index and OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.customMessages then
        return OTLGM_DB.settings.customMessages[index] or ""
    end
    return ""
end

function OTLGM:SelectRecruitment(key)
    self:EnsureDB()
    local customText = string.gsub(key or "", "^CUSTOM", "")
    local customIndex = tonumber(customText)
    if not self.recruitmentPresets[key] and not (customIndex and customIndex >= 1 and customIndex <= 3 and key == "CUSTOM" .. tostring(customIndex)) then return end

    OTLGM_DB.settings.selectedRecruitment = key
    OTLGM_DB.settings.recruitmentMessage = self:GetRecruitmentText(key)
    self.pendingCustomSaveIndex = nil
    self.pendingCustomSaveTime = nil
    self.pendingCustomClearIndex = nil
    self.pendingCustomClearTime = nil
    local selectedPreset = self:GetRecruitmentPreset170(key)
    if selectedPreset then OTLGM_DB.settings.customTarget = selectedPreset.target or "WORLD" end
    if self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
end

function OTLGM:SaveSelectedCustom()
    self:EnsureDB()
    local key = OTLGM_DB.settings.selectedRecruitment or ""
    local customText = string.gsub(key, "^CUSTOM", "")
    local index = tonumber(customText)
    if not index then
        self:SetStatus("Pinned messages are protected. Select Custom 1, 2 or 3 before saving.")
        return
    end

    local current = OTLGM_DB.settings.recruitmentMessage or ""
    local saved = OTLGM_DB.settings.customMessages[index] or ""
    local now = self:Now()
    if saved ~= "" and saved ~= current then
        if self.pendingCustomSaveIndex ~= index or not self.pendingCustomSaveTime or (now - self.pendingCustomSaveTime) > 5 then
            self.pendingCustomSaveIndex = index
            self.pendingCustomSaveTime = now
            self:SetStatus("Custom " .. tostring(index) .. " already contains a message. Click Confirm Save within 5 seconds to overwrite it.")
            if self.RefreshRecruitmentButtons then self:RefreshRecruitmentButtons() end
            return
        end
    end

    OTLGM_DB.settings.customMessages[index] = current
    self.pendingCustomSaveIndex = nil
    self.pendingCustomSaveTime = nil
    self:SetStatus("Saved current text to Custom " .. tostring(index) .. ".")
    if self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
end

function OTLGM:SaveCurrentToCustom(index)
    self:EnsureDB()
    index = tonumber(index)
    if not index or index < 1 or index > 3 then return end

    local current = OTLGM_DB.settings.recruitmentMessage or ""
    local saved = OTLGM_DB.settings.customMessages[index] or ""
    local now = self:Now()
    if saved ~= "" and saved ~= current then
        if self.pendingCustomSaveIndex ~= index or not self.pendingCustomSaveTime or (now - self.pendingCustomSaveTime) > 5 then
            self.pendingCustomSaveIndex = index
            self.pendingCustomSaveTime = now
            self:SetStatus("Custom " .. tostring(index) .. " already contains a message. Click the same numbered save button again within 5 seconds.")
            if self.RefreshRecruitmentButtons then self:RefreshRecruitmentButtons() end
            return
        end
    end

    OTLGM_DB.settings.customMessages[index] = current
    OTLGM_DB.settings.selectedRecruitment = "CUSTOM" .. tostring(index)
    self.pendingCustomSaveIndex = nil
    self.pendingCustomSaveTime = nil
    self:SetStatus("Working copy saved to Custom " .. tostring(index) .. ".")
    if self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
end

function OTLGM:ClearSelectedCustom()
    self:EnsureDB()
    local key = OTLGM_DB.settings.selectedRecruitment or ""
    local customText = string.gsub(key, "^CUSTOM", "")
    local index = tonumber(customText)
    if not index then
        self:SetStatus("Select a custom slot before clearing it.")
        return
    end

    local now = self:Now()
    if (OTLGM_DB.settings.customMessages[index] or "") ~= "" then
        if self.pendingCustomClearIndex ~= index or not self.pendingCustomClearTime or (now - self.pendingCustomClearTime) > 5 then
            self.pendingCustomClearIndex = index
            self.pendingCustomClearTime = now
            self:SetStatus("Click Confirm Clear within 5 seconds to erase Custom " .. tostring(index) .. ".")
            if self.RefreshRecruitmentButtons then self:RefreshRecruitmentButtons() end
            return
        end
    end

    OTLGM_DB.settings.customMessages[index] = ""
    OTLGM_DB.settings.recruitmentMessage = ""
    self.pendingCustomClearIndex = nil
    self.pendingCustomClearTime = nil
    self:SetStatus("Custom " .. tostring(index) .. " cleared.")
    if self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
end

function OTLGM:GetRecruitmentPreview(text, maxLength)
    text = Trim(text or "")
    text = string.gsub(text, "[\r\n]+", " ")
    maxLength = maxLength or 34
    if string.len(text) > maxLength then return string.sub(text, 1, maxLength - 3) .. "..." end
    if text == "" then return "Empty" end
    return text
end

function OTLGM:GuildKey()
    local guildName = GetGuildInfo("player")
    local realm = GetCVar("realmName") or "UnknownRealm"
    if not guildName then return nil end
    return realm .. "::" .. guildName
end

function OTLGM:GetOrCreateGuildDB()
    self:EnsureDB()
    local key = self:GuildKey()
    if not key then return nil end

    if not OTLGM_DB.guilds[key] then
        OTLGM_DB.guilds[key] = {
            name = GetGuildInfo("player"),
            realm = GetCVar("realmName") or "UnknownRealm",
            created = self:Now(),
            roster = {},
            log = {},
            daily = {},
            pendingInvites = {},
            pendingActions = {},
            initialized = false,
            lastScan = nil,
            lastTotal = 0,
            lastOnline = 0,
            unread = 0,
            schemaVersion = 2,
        }
    end

    local db = OTLGM_DB.guilds[key]
    if not db.roster then db.roster = {} end
    if not db.log then db.log = {} end
    if not db.daily then db.daily = {} end
    if not db.pendingInvites then db.pendingInvites = {} end
    if not db.pendingActions then db.pendingActions = {} end
    if db.unread == nil then db.unread = 0 end
    self:MigrateGuildDB(db)
    return db
end

function OTLGM:MigrateLegacySchema2(db)
    if not db then return end
    if (db.schemaVersion or 0) >= 2 then return end

    local i, eventInfo, member, beforeRank, afterRank
    for i = 1, table.getn(db.log or {}) do
        eventInfo = db.log[i]
        if eventInfo then
            member = db.roster and db.roster[eventInfo.name] or nil
            if member then
                if not eventInfo.class or eventInfo.class == "" then eventInfo.class = member.class or "" end
                if not eventInfo.rank or eventInfo.rank == "" then eventInfo.rank = member.rank or "" end
            end
            if eventInfo.kind == "RANK" and (not eventInfo.rankBefore or not eventInfo.rankAfter) and eventInfo.detail then
                local startPos, endPos, foundBefore, foundAfter = string.find(eventInfo.detail, "^(.-)%s*%-%>%s*(.-)$")
                beforeRank = foundBefore
                afterRank = foundAfter
                if beforeRank and afterRank then
                    eventInfo.rankBefore = eventInfo.rankBefore or beforeRank
                    eventInfo.rankAfter = eventInfo.rankAfter or afterRank
                end
            end
            if eventInfo.kind == "LEVEL" and (not eventInfo.levelBefore or not eventInfo.levelAfter) and eventInfo.detail then
                local levelStart, levelEnd, oldLevel, newLevel = string.find(eventInfo.detail, "^(%d+)%s*%-%>%s*(%d+)$")
                if oldLevel and newLevel then
                    eventInfo.levelBefore = tonumber(oldLevel)
                    eventInfo.levelAfter = tonumber(newLevel)
                end
            end
        end
    end
    db.schemaVersion = 2
end

function OTLGM:RememberInvite(name)
    local db = self:GetGuildDB()
    if not db or not name or name == "" then return end
    db.pendingInvites[NormalizeName(name)] = {
        inviter = UnitName("player") or "You",
        ts = self:Now(),
    }
end

function OTLGM:ConsumeInvite(name)
    local db = self:GetGuildDB()
    if not db then return nil end
    local key = NormalizeName(name)
    local invite = db.pendingInvites[key]
    db.pendingInvites[key] = nil
    if invite and invite.ts and (self:Now() - invite.ts) <= 3600 then return invite end
    return nil
end

function OTLGM:CleanupPendingInvites(db)
    if not db or not db.pendingInvites then return end
    local key, invite
    for key, invite in pairs(db.pendingInvites) do
        if not invite.ts or (self:Now() - invite.ts) > 3600 then db.pendingInvites[key] = nil end
    end
end

function OTLGM:InstallInviteHook()
    if self.inviteHookInstalled or not GuildInvite then return end

    self.originalGuildInvite = GuildInvite
    GuildInvite = function(name)
        if OTLGM and name then OTLGM:RememberInvite(name) end
        return OTLGM.originalGuildInvite(name)
    end
    self.inviteHookInstalled = true
end

local function EscapeLuaPattern(text)
    if not text then return "" end
    text = string.gsub(text, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    return text
end

local function FormatStringToPattern(formatText)
    if not formatText or formatText == "" then return nil end
    local marker = "__OTLGM_PERCENT__"
    local pattern = string.gsub(formatText, "%%%%", marker)
    pattern = EscapeLuaPattern(pattern)
    pattern = string.gsub(pattern, "%%%%%d+%$s", "(.+)")
    pattern = string.gsub(pattern, "%%%%s", "(.+)")
    pattern = string.gsub(pattern, "%%%%%d+%$d", "(%%d+)")
    pattern = string.gsub(pattern, "%%%%d", "(%%d+)")
    pattern = string.gsub(pattern, marker, "%%%%")
    return "^" .. pattern .. "$"
end

function OTLGM:RememberGuildAction(kind, target, actor, source)
    local db = self:GetGuildDB()
    if not db or not target or target == "" then return end
    local key = NormalizeName(target)
    db.pendingActions[key] = {
        kind = kind or "",
        target = target,
        actor = actor or UnitName("player") or "",
        source = source or "local",
        ts = self:Now(),
    }
end

function OTLGM:ConsumeGuildAction(target, expectedKind)
    local db = self:GetGuildDB()
    if not db or not target then return nil end
    local key = NormalizeName(target)
    local action = db.pendingActions[key]
    if not action then return nil end
    if not action.ts or (self:Now() - action.ts) > 300 then
        db.pendingActions[key] = nil
        return nil
    end
    if expectedKind and action.kind ~= expectedKind then return nil end
    db.pendingActions[key] = nil
    return action
end

function OTLGM:CleanupPendingActions(db)
    if not db or not db.pendingActions then return end
    local key, action
    for key, action in pairs(db.pendingActions) do
        if not action.ts or (self:Now() - action.ts) > 300 then db.pendingActions[key] = nil end
    end
end

function OTLGM:HookGuildActionFunction(functionName, kind)
    self.guildActionHooks = self.guildActionHooks or {}
    if self.guildActionHooks[functionName] then return end
    local original = _G and _G[functionName]
    if type(original) ~= "function" then return end

    self.guildActionHooks[functionName] = original
    _G[functionName] = function(target)
        if OTLGM and target then OTLGM:RememberGuildAction(kind, target, UnitName("player") or "You", "local action") end
        return OTLGM.guildActionHooks[functionName](target)
    end
end

function OTLGM:InstallGuildActionHooks()
    if self.guildActionHooksInstalled then return end
    self:HookGuildActionFunction("GuildPromote", "PROMOTE")
    self:HookGuildActionFunction("GuildPromoteByName", "PROMOTE")
    self:HookGuildActionFunction("PromoteByName", "PROMOTE")
    self:HookGuildActionFunction("GuildDemote", "DEMOTE")
    self:HookGuildActionFunction("GuildDemoteByName", "DEMOTE")
    self:HookGuildActionFunction("DemoteByName", "DEMOTE")
    self:HookGuildActionFunction("GuildUninvite", "REMOVE")
    self:HookGuildActionFunction("GuildUninviteByName", "REMOVE")
    self:HookGuildActionFunction("GuildRemove", "REMOVE")
    self.guildActionHooksInstalled = true
end

function OTLGM:ApplyActorToRecentLog(actionKind, target, actor, source)
    local db = self:GetGuildDB()
    if not db or not target or not actor then return false end
    local expectedLogKind = actionKind == "REMOVE" and "LEAVE" or "RANK"
    local normalizedTarget = NormalizeName(target)
    local now = self:Now()
    local i, eventInfo
    for i = 1, math.min(20, table.getn(db.log)) do
        eventInfo = db.log[i]
        if eventInfo and eventInfo.ts and (now - eventInfo.ts) <= 30 and eventInfo.kind == expectedLogKind and NormalizeName(eventInfo.name) == normalizedTarget then
            if not eventInfo.actor or eventInfo.actor == "" then
                eventInfo.actor = actor
                eventInfo.source = source or "server message"
                if actionKind == "REMOVE" then eventInfo.detail = "Removed from the guild" end
            end
            return true
        end
    end
    return false
end

function OTLGM:TryCaptureSystemGuildAction(message)
    if not message or message == "" then return false end
    local patterns = {
        { kind = "PROMOTE", format = ERR_GUILD_PROMOTE_SSS, fallback = "^(.+) has promoted (.+) to (.+)%.$", actorPos = 1, targetPos = 2 },
        { kind = "DEMOTE", format = ERR_GUILD_DEMOTE_SSS, fallback = "^(.+) has demoted (.+) to (.+)%.$", actorPos = 1, targetPos = 2 },
        { kind = "REMOVE", format = ERR_GUILD_REMOVE_SS, fallback = "^(.+) has been kicked out of the guild by (.+)%.$", actorPos = 2, targetPos = 1 },
    }

    local i, item
    for i = 1, table.getn(patterns) do
        item = patterns[i]
        local pattern = FormatStringToPattern(item.format) or item.fallback
        local startPos, endPos, first, second, third = string.find(message, pattern)
        if not first then startPos, endPos, first, second, third = string.find(message, item.fallback) end
        if first and second then
            local values = { first, second, third }
            local target = values[item.targetPos]
            local actor = values[item.actorPos]
            if not self:ApplyActorToRecentLog(item.kind, target, actor, "server message") then
                self:RememberGuildAction(item.kind, target, actor, "server message")
            end
            if self.RefreshAll then self:RefreshAll() end
            return true
        end
    end
    return false
end

function OTLGM:BuildOfflineInfo(index, isOnline)
    if isOnline then return 0, "Online" end
    if not GetGuildRosterLastOnline then return 0, "Offline" end

    local years, months, days, hours = GetGuildRosterLastOnline(index)
    years = years or 0
    months = months or 0
    days = days or 0
    hours = hours or 0
    local totalHours = (((years * 12) + months) * 30 * 24) + (days * 24) + hours
    local text = "Offline"

    if years > 0 then
        text = tostring(years) .. "y " .. tostring(months) .. "mo"
    elseif months > 0 then
        text = tostring(months) .. "mo " .. tostring(days) .. "d"
    elseif days > 0 then
        text = tostring(days) .. "d " .. tostring(hours) .. "h"
    else
        text = tostring(hours) .. "h"
    end
    return totalHours, text
end

-- OctoWoW itself does not document a faction field in the stock 1.12 guild
-- tuple. Some compatible clients/extensions append useful strings, while the
-- popular Improved Guild Window convention stores a short race code at the
-- start of the officer note (for example Hu-, NE-, Ta-, Go-). Accept both
-- sources when they are explicit, but never infer faction from a character
-- name, zone or a non-exclusive class.
local ROSTER_RACE_FACTION_180 = {
    HUMAN = "Alliance", DWARF = "Alliance", NIGHTELF = "Alliance", GNOME = "Alliance", HIGHELF = "Alliance",
    ORC = "Horde", UNDEAD = "Horde", SCOURGE = "Horde", TAUREN = "Horde", TROLL = "Horde", GOBLIN = "Horde",
}

local ROSTER_RACE_DISPLAY_180 = {
    HUMAN = "Human", DWARF = "Dwarf", NIGHTELF = "Night Elf", GNOME = "Gnome", HIGHELF = "High Elf",
    ORC = "Orc", UNDEAD = "Undead", SCOURGE = "Undead", TAUREN = "Tauren", TROLL = "Troll", GOBLIN = "Goblin",
}

local OFFICER_RACE_CODES_180 = {
    HU = "HUMAN", DW = "DWARF", NE = "NIGHTELF", GN = "GNOME", HE = "HIGHELF",
    OR = "ORC", UN = "UNDEAD", TA = "TAUREN", TR = "TROLL", GO = "GOBLIN",
}

local function NormalizeRaceCandidate180(value)
    local text = string.upper(tostring(value or ""))
    text = string.gsub(text, "[%s_%-]", "")
    if text == "NIGHTELF" or text == "HIGHELF" or text == "HUMAN" or text == "DWARF" or text == "GNOME"
        or text == "ORC" or text == "UNDEAD" or text == "SCOURGE" or text == "TAUREN" or text == "TROLL" or text == "GOBLIN" then
        return text
    end
    return nil
end

local OFFICER_RACE_CODES_SHORT_180 = {
    H = "HUMAN", D = "DWARF", N = "NIGHTELF", G = "GNOME",
    O = "ORC", U = "UNDEAD", T = "TROLL",
}

local function FactionFromOfficerNote180(note)
    note = tostring(note or "")
    -- Current convention: two-letter race code, e.g. Hu-, NE-, Ta-, Go-.
    if string.len(note) >= 3 and string.sub(note, 3, 3) == "-" then
        local code = string.upper(string.sub(note, 1, 2))
        local race = OFFICER_RACE_CODES_180[code]
        if race then return ROSTER_RACE_FACTION_180[race], race end
    end
    -- Backward-compatible convention used by older guild notes: H-, N-, O-,
    -- etc. T- historically means Troll; Tauren requires Ta- so it is never
    -- guessed ambiguously.
    if string.len(note) >= 2 and string.sub(note, 2, 2) == "-" then
        local code = string.upper(string.sub(note, 1, 1))
        local race = OFFICER_RACE_CODES_SHORT_180[code]
        if race then return ROSTER_RACE_FACTION_180[race], race end
    end
    return nil, nil
end

local function FactionFromRosterExtraValue180(value)
    if type(value) ~= "string" then return nil, nil end
    local upper = string.upper(value)
    if upper == "ALLIANCE" then return "Alliance", nil end
    if upper == "HORDE" then return "Horde", nil end
    local race = NormalizeRaceCandidate180(value)
    if race and ROSTER_RACE_FACTION_180[race] then
        return ROSTER_RACE_FACTION_180[race], race
    end
    return nil, nil
end

local function FactionFromRosterExtras180(officerNote, extra1, extra2, extra3, extra4, extra5, extra6, extra7)
    local faction, race
    faction, race = FactionFromRosterExtraValue180(extra1) if faction then return faction, race, race and "roster-race" or "roster-api" end
    faction, race = FactionFromRosterExtraValue180(extra2) if faction then return faction, race, race and "roster-race" or "roster-api" end
    faction, race = FactionFromRosterExtraValue180(extra3) if faction then return faction, race, race and "roster-race" or "roster-api" end
    faction, race = FactionFromRosterExtraValue180(extra4) if faction then return faction, race, race and "roster-race" or "roster-api" end
    faction, race = FactionFromRosterExtraValue180(extra5) if faction then return faction, race, race and "roster-race" or "roster-api" end
    faction, race = FactionFromRosterExtraValue180(extra6) if faction then return faction, race, race and "roster-race" or "roster-api" end
    faction, race = FactionFromRosterExtraValue180(extra7) if faction then return faction, race, race and "roster-race" or "roster-api" end
    faction, race = FactionFromOfficerNote180(officerNote)
    if faction then return faction, race, "officer-race-code" end
    return nil, nil, nil
end

local function ReadRosterMember180(owner, index, now)
    local name, rank, rankIndex, level, class, zone, note, officerNote, isOnline, extra1, extra2, extra3, extra4, extra5, extra6, extra7 = GetGuildRosterInfo(index)
    if not name then return nil, false end
    local offlineHours, lastOnlineText = owner:BuildOfflineInfo(index, isOnline)
    local faction180, raceToken180, factionSource180 = FactionFromRosterExtras180(officerNote, extra1, extra2, extra3, extra4, extra5, extra6, extra7)
    return {
        name = name,
        rank = rank or "",
        rankIndex = rankIndex or 99,
        level = level or 0,
        class = class or "",
        zone = zone or "",
        note = note or "",
        officerNote = officerNote or "",
        online = isOnline and true or false,
        offlineHours = offlineHours or 0,
        offlineDays = math.floor((offlineHours or 0) / 24),
        lastOnlineText = lastOnlineText or "Offline",
        rosterIndex = index,
        seen = now,
        faction180 = faction180,
        factionSeenAt180 = faction180 and now or nil,
        factionSource180 = factionSource180,
        race180 = raceToken180 and ROSTER_RACE_DISPLAY_180[raceToken180] or nil,
    }, isOnline and true or false
end

function OTLGM:ReadRoster()
    local override = self.runtime and self.runtime.rosterReadOverride180
    if override then return override.snapshot or {}, tonumber(override.total) or 0, tonumber(override.online) or 0 end

    local snapshot = {}
    local total = GetNumGuildMembers(true) or 0
    local online = 0
    local now = self:Now()
    local i
    for i = 1, total do
        local member, isOnline = ReadRosterMember180(self, i, now)
        if member then
            snapshot[member.name] = member
            if isOnline then online = online + 1 end
        end
    end
    return snapshot, total, online
end

-- Full guild rosters on OctoWoW can exceed 780 characters. Reading every
-- roster API row and its last-online tuple in one event callback is a visible
-- freeze risk, so the canonical full-scan path reads bounded slices and only
-- commits after the snapshot is complete. Domain data is never partially
-- replaced.
local function ScheduleRosterScanSliceSafe180(owner, delay)
    if not owner or not owner.ScheduleAfter180 then return false end
    return owner:ScheduleAfter180("roster-scan-slice", math.max(0, tonumber(delay) or 0), function(current)
        local ok, problem = pcall(current.ProcessRosterScanSlice180, current)
        current.runtime = current.runtime or {}
        if ok then
            current.runtime.rosterSliceDispatchFailures180 = 0
            return
        end
        local failures = math.min(3, (tonumber(current.runtime.rosterSliceDispatchFailures180) or 0) + 1)
        current.runtime.rosterSliceDispatchFailures180 = failures
        if current.RecordInternalIssueRC3 then pcall(current.RecordInternalIssueRC3, current, "Roster/SLICE_DISPATCH", problem) end
        if current.runtime.rosterRead180 and failures < 3 and current.ScheduleAfter180 then
            ScheduleRosterScanSliceSafe180(current, 0.5)
            return
        end
        -- An unexpected outer failure must not leave the bounded-reader lock
        -- set forever. Preserve the last committed roster and fail closed.
        current.runtime.rosterRead180 = nil
        current.runtime.rosterReadOverride180 = nil
        if current.SetOperationState156 then pcall(current.SetOperationState156, current, "ROSTER", "ERROR", "Roster scan stopped after an internal error", 6) end
        if current.SetStatus then pcall(current.SetStatus, current, "Roster scan stopped safely: " .. tostring(problem or "unknown error")) end
    end, 70)
end
function OTLGM:BeginRosterScan180(reason)
    self.runtime = self.runtime or {}
    if self.runtime.rosterRead180 then return false end
    local total = GetNumGuildMembers and (tonumber(GetNumGuildMembers(true)) or 0) or 0
    self.runtime.rosterRead180 = {
        reason = tostring(reason or "INTERNAL"), total = total, index = 1,
        online = 0, snapshot = {}, startedAt = self:Now(), restarts = 0,
    }
    self.runtime.rosterMetrics180 = self.runtime.rosterMetrics180 or { fullScans = 0, targetedRefreshes = 0, reasons = {} }
    if self.ScheduleAfter180 then
        ScheduleRosterScanSliceSafe180(self, 0)
        return true
    end
    -- Never fall back to a synchronous 780+ member scan. Without the shared
    -- scheduler the safe behavior is an explicit error and no partial commit.
    self.runtime.rosterRead180 = nil
    if self.SetOperationState156 then self:SetOperationState156("ROSTER", "ERROR", "Bounded roster scheduler is unavailable", 6) end
    return false
end

function OTLGM:ProcessRosterScanSlice180(forceAll)
    local state = self.runtime and self.runtime.rosterRead180
    if not state then return false end
    if self.InCombat and self:InCombat() and state.reason ~= "MANUAL" then
        if self.ScheduleAfter180 then ScheduleRosterScanSliceSafe180(self, 1) end
        return false
    end

    local liveTotal = 0
    if GetNumGuildMembers then
        local countOk, countValue = pcall(GetNumGuildMembers, true)
        if countOk then
            liveTotal = tonumber(countValue) or 0
        else
            state.failures180 = (tonumber(state.failures180) or 0) + 1
            if self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Roster/SLICE_COUNT", countValue) end
            if state.failures180 <= 2 and self.ScheduleAfter180 then
                ScheduleRosterScanSliceSafe180(self, 0.5)
                return false
            end
            self.runtime.rosterRead180 = nil
            self.runtime.rosterReadOverride180 = nil
            if self.SetOperationState156 then self:SetOperationState156("ROSTER", "ERROR", "Roster API could not be read safely", 6) end
            return false
        end
    end
    state.failures180 = 0
    if liveTotal ~= state.total and state.index > 1 and (tonumber(state.restarts) or 0) < 2 then
        state.total = liveTotal
        state.index = 1
        state.online = 0
        state.snapshot = {}
        state.restarts = (tonumber(state.restarts) or 0) + 1
    else
        state.total = liveTotal
    end

    local startedProfile
    if debugprofilestop then
        local ok, value = pcall(debugprofilestop)
        if ok then startedProfile = tonumber(value) end
    end
    local processed = 0
    -- A 788+ member OctoWoW guild must never monopolize one rendered frame.
    -- Spread the scan over smaller slices; total scan latency grows slightly,
    -- but foreground frame-time spikes are materially lower.
    local maximum = forceAll and math.max(1, state.total) or 50
    state.snapshot = type(state.snapshot) == "table" and state.snapshot or {}
    state.online = tonumber(state.online) or 0
    state.index = math.max(1, tonumber(state.index) or 1)
    while state.index <= state.total and processed < maximum do
        local rowOk, member, isOnline = pcall(ReadRosterMember180, self, state.index, self:Now())
        if not rowOk then
            state.rowFailures180 = (tonumber(state.rowFailures180) or 0) + 1
            if self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Roster/SLICE_ROW", member) end
            if state.rowFailures180 <= 2 and self.ScheduleAfter180 then
                ScheduleRosterScanSliceSafe180(self, 0.5)
                return false
            end
            -- Do not leave rosterRead180 set after a persistent API/helper
            -- failure: that state gates future scans, confirmation work and
            -- several transition paths. Fail closed with the last committed
            -- roster still intact rather than making the addon look inactive.
            self.runtime.rosterRead180 = nil
            self.runtime.rosterReadOverride180 = nil
            if self.SetOperationState156 then self:SetOperationState156("ROSTER", "ERROR", "Roster row could not be read safely", 6) end
            return false
        end
        state.rowFailures180 = 0
        if member then
            state.snapshot[member.name] = member
            if isOnline then state.online = state.online + 1 end
        end
        state.index = state.index + 1
        processed = processed + 1
        if not forceAll and startedProfile and debugprofilestop and processed >= 16 then
            local ok, current = pcall(debugprofilestop)
            if ok and tonumber(current) and (tonumber(current) - startedProfile) >= 4 then break end
        end
    end

    local metrics = self.runtime.rosterMetrics180
    if type(metrics) ~= "table" then
        metrics = { fullScans = 0, targetedRefreshes = 0, reasons = {} }
        self.runtime.rosterMetrics180 = metrics
    end
    metrics.readSlices = (tonumber(metrics.readSlices) or 0) + 1
    metrics.rowsRead = (tonumber(metrics.rowsRead) or 0) + processed
    metrics.lastSliceRows = processed
    if startedProfile and debugprofilestop then
        local ok, current = pcall(debugprofilestop)
        if ok and tonumber(current) then metrics.lastSliceMs = math.max(0, tonumber(current) - startedProfile) end
    end

    if state.index <= state.total then
        if self.ScheduleAfter180 then ScheduleRosterScanSliceSafe180(self, 0.02) end
        return false
    end

    self.runtime.rosterRead180 = nil
    self.runtime.rosterDataDirty180 = nil
    self.runtime.rosterReadOverride180 = { snapshot = state.snapshot, total = state.total, online = state.online }
    local ok, problem = pcall(function() self:Scan(state.reason) end)
    self.runtime.rosterReadOverride180 = nil
    if self.RefreshSenderRosterCache then self:RefreshSenderRosterCache(true) end
    if not ok then
        if self.SetOperationState156 then self:SetOperationState156("ROSTER", "ERROR", tostring(problem or "Roster commit failed"), 6) end
        if self.SetStatus then self:SetStatus("Roster snapshot could not be committed: " .. tostring(problem or "unknown error")) end
        return false
    end
    -- RC5: privileged packets deferred while authority was stale are replayed
    -- only after a successful committed roster snapshot refreshed the allow-list.
    if self.ReplayAuthorityPacketsRC5 then self:ReplayAuthorityPacketsRC5() end
    return true
end

function OTLGM:IsLeadership(member)
    if not member then return false end
    local rank = string.lower(member.rank or "")
    if (member.rankIndex or 99) <= 2 then return true end
    if string.find(rank, "officer", 1, true) then return true end
    if string.find(rank, "helper", 1, true) then return true end
    if string.find(rank, "leader", 1, true) then return true end
    if string.find(rank, "manager", 1, true) then return true end
    if string.find(rank, "inn keeper", 1, true) then return true end
    return false
end

function OTLGM:GetClassColor(className)
    if not OTLGM_DB or not OTLGM_DB.settings or not OTLGM_DB.settings.classColors then return self.colors.white end
    return self.classHex[string.lower(className or "")] or self.colors.white
end

function OTLGM:GetRosterRanks()
    local db = self:GetGuildDB()
    local result = {}
    local seen = {}
    if not db then return result end

    local name, member
    for name, member in pairs(db.roster) do
        local rank = member.rank or ""
        if rank ~= "" and not seen[rank] then
            seen[rank] = true
            table.insert(result, { name = rank, index = member.rankIndex or 99 })
        end
    end

    table.sort(result, function(a, b)
        if a.index ~= b.index then return a.index < b.index end
        return string.lower(a.name) < string.lower(b.name)
    end)
    return result
end

function OTLGM:SetRosterSort(sortKey)
    self:EnsureDB()
    local settings = OTLGM_DB.settings
    if settings.rosterSortKey == sortKey then
        settings.rosterSortAsc = not settings.rosterSortAsc
    else
        settings.rosterSortKey = sortKey
        if sortKey == "LEVEL" or sortKey == "LASTONLINE" then settings.rosterSortAsc = false else settings.rosterSortAsc = true end
    end
    if self.ui then self.ui.rosterOffset = 0 end
    if self.RefreshRosterPage then self:RefreshRosterPage() end
end

function OTLGM:GetMember(name)
    local db = self:GetGuildDB()
    if not db or not name then return nil end
    if db.roster[name] then return db.roster[name] end
    self.runtime = self.runtime or {}
    local lookup = self.runtime.rosterMemberLookup180
    if not lookup or lookup.roster ~= db.roster or lookup.lastScan ~= db.lastScan then
        lookup = { roster = db.roster, lastScan = db.lastScan, byKey = {} }
        local storedName, member, key
        for storedName, member in pairs(db.roster or {}) do
            key = NormalizeName(storedName)
            if key ~= "" then lookup.byKey[key] = member end
            key = NormalizeName(member and member.name)
            if key ~= "" then lookup.byKey[key] = member end
        end
        self.runtime.rosterMemberLookup180 = lookup
    end
    return lookup.byKey[NormalizeName(name)]
end

function OTLGM:FindRosterIndex(name)
    if not name then return nil end
    local total = GetNumGuildMembers(true) or 0
    local target = NormalizeName(name)
    local i
    for i = 1, total do
        local rosterName = GetGuildRosterInfo(i)
        if rosterName == name or NormalizeName(rosterName) == target then return i end
    end
    return nil
end

function OTLGM:GetPlayerGuildRankIndex170()
    local guildName, rankName, rankIndex
    if GetGuildInfo then guildName, rankName, rankIndex = GetGuildInfo("player") end
    rankIndex = tonumber(rankIndex)
    if rankIndex ~= nil then return rankIndex end
    local playerName = UnitName and UnitName("player")
    local member = playerName and self.GetMember and self:GetMember(playerName) or nil
    return member and tonumber(member.rankIndex) or nil
end

function OTLGM:IsGuildLeader170()
    -- Guild-leader identity is guild-specific and must never be inferred for an
    -- unrelated character merely because a stale/custom-server API reports
    -- rank index 0.  Morrow/Lucks still have to pass the live server leader
    -- signal before this *permission* helper grants leader-level capabilities.
    -- Other officers continue through the normal live rank-flag checks below.
    local playerName = UnitName and UnitName("player") or ""
    if self.IsCanonicalGuildLeaderName180 and not self:IsCanonicalGuildLeaderName180(playerName) then return false end
    if IsGuildLeader then
        local ok, result = pcall(IsGuildLeader, playerName)
        if ok and result then return true end
        ok, result = pcall(IsGuildLeader)
        if ok and result then return true end
    end
    local guildName, rankName, rankIndex
    if GetGuildInfo then guildName, rankName, rankIndex = GetGuildInfo("player") end
    if tonumber(rankIndex) == 0 then return true end
    rankName = string.lower(tostring(rankName or ""))
    return string.find(rankName, "guild leader", 1, true) ~= nil
        or string.find(rankName, "guild master", 1, true) ~= nil
        or string.find(rankName, "guildmaster", 1, true) ~= nil
end

function OTLGM:GetGuildPermissionFlags170(force)
    self.runtime = self.runtime or {}
    local now = GetTime and GetTime() or self:Now()
    local cached = self.runtime.guildPermissionFlags170
    if not force and cached and cached.checkedAt and now - cached.checkedAt < 3 then return cached end

    local flags = {
        checkedAt = now,
        promote = false, demote = false, remove = false,
        editPublic = false, viewOfficer = false, editOfficer = false,
        source = "unavailable",
    }
    if self:IsGuildLeader170() then
        flags.promote, flags.demote, flags.remove = true, true, true
        flags.editPublic, flags.viewOfficer, flags.editOfficer = true, true, true
        flags.source = "guild-leader"
        self.runtime.guildPermissionFlags170 = flags
        return flags
    end

    local rankIndex = self:GetPlayerGuildRankIndex170()
    if rankIndex ~= nil and GuildControlSetRank and GuildControlGetRankFlags then
        local selected = pcall(GuildControlSetRank, rankIndex + 1)
        if selected then
            local ok, guildListen, guildSpeak, officerListen, officerSpeak,
                promote, demote, inviteMember, removeMember, setMotd,
                editPublic, viewOfficer, editOfficer = pcall(GuildControlGetRankFlags)
            if ok then
                flags.promote = promote and true or false
                flags.demote = demote and true or false
                flags.remove = removeMember and true or false
                flags.editPublic = editPublic and true or false
                flags.viewOfficer = viewOfficer and true or false
                flags.editOfficer = editOfficer and true or false
                flags.source = "rank-flags"
            end
        end
    end
    self.runtime.guildPermissionFlags170 = flags
    return flags
end

function OTLGM:CanEditPublicNotes()
    if SafeBooleanFunction(CanEditPublicNote) then return true end
    return self:GetGuildPermissionFlags170().editPublic
end

function OTLGM:CanEditOfficerNotes()
    if SafeBooleanFunction(CanEditOfficerNote) then return true end
    return self:GetGuildPermissionFlags170().editOfficer
end

function OTLGM:CanViewOfficerNotes()
    if SafeBooleanFunction(CanViewOfficerNote) then return true end
    local flags = self:GetGuildPermissionFlags170()
    return flags.viewOfficer or flags.editOfficer
end

function OTLGM:CanPromoteMembers()
    if SafeBooleanFunction(CanGuildPromote) then return true end
    return self:GetGuildPermissionFlags170().promote
end

function OTLGM:CanDemoteMembers()
    if SafeBooleanFunction(CanGuildDemote) then return true end
    return self:GetGuildPermissionFlags170().demote
end

function OTLGM:CanRemoveMembers()
    if SafeBooleanFunction(CanGuildRemove) then return true end
    return self:GetGuildPermissionFlags170().remove
end

function OTLGM:ResetGuildData()
    local key = self:GuildKey()
    if key and OTLGM_DB and OTLGM_DB.guilds then
        OTLGM_DB.guilds[key] = nil
        self:Chat("Local history for the current guild has been reset. The next scan will create a new baseline.")
        self:RequestScan("MANUAL")
        if self.RefreshAll then self:RefreshAll() end
    end
end

function OTLGM:DetectWorldChannel153(force)
    self:EnsureDB()
    local now = self:Now()
    if not force and self.worldChannelDetectedAt153 and now - self.worldChannelDetectedAt153 < 10 then
        local cached = tonumber(OTLGM_DB.settings.worldChannelDetected153)
        if cached and cached > 0 then return cached, OTLGM_DB.settings.worldChannelName153 or "World", true end
    end
    self.worldChannelDetectedAt153 = now

    local function IsWorldName(name)
        name = string.lower(Trim(name or ""))
        name = string.gsub(name, "[%s%-%_]", "")
        if name == "world" or name == "worldchat" or name == "global" or name == "globalchat" then return true end
        if string.find(name, "world", 1, true) and not string.find(name, "defense", 1, true) then return true end
        return false
    end

    local candidates = { "World", "world", "WORLD", "World Chat", "Global", "Global Chat" }
    local i, id, channelName
    if GetChannelName then
        for i = 1, table.getn(candidates) do
            local ok, resolvedId, resolvedName = pcall(GetChannelName, candidates[i])
            if ok and tonumber(resolvedId) and tonumber(resolvedId) > 0 then
                id = math.floor(tonumber(resolvedId))
                channelName = resolvedName or candidates[i]
                if IsWorldName(channelName) or IsWorldName(candidates[i]) then
                    OTLGM_DB.settings.worldChannelDetected153 = tostring(id)
                    OTLGM_DB.settings.worldChannelName153 = tostring(channelName or "World")
                    OTLGM_DB.settings.worldChannelAuto153 = true
                    OTLGM_DB.settings.worldChannel = tostring(id)
                    return id, channelName, true
                end
            end
        end
    end

    if GetChannelList then
        local values = { GetChannelList() }
        i = 1
        while i <= table.getn(values) do
            id = tonumber(values[i])
            channelName = values[i + 1]
            if id and id > 0 and IsWorldName(channelName) then
                id = math.floor(id)
                OTLGM_DB.settings.worldChannelDetected153 = tostring(id)
                OTLGM_DB.settings.worldChannelName153 = tostring(channelName or "World")
                OTLGM_DB.settings.worldChannelAuto153 = true
                OTLGM_DB.settings.worldChannel = tostring(id)
                return id, channelName, true
            end
            i = i + 3
        end
    end

    OTLGM_DB.settings.worldChannelDetected153 = nil
    OTLGM_DB.settings.worldChannelName153 = nil
    OTLGM_DB.settings.worldChannelAuto153 = false
    return nil, nil, false
end

function OTLGM:GetWorldChannelNumber()
    self:EnsureDB()
    local detected = self:DetectWorldChannel153(false)
    if detected then return detected end

    local text = OTLGM_DB.settings.worldChannel or "6"
    if self.ui and self.ui.channelEdit and self.ui.channelEdit.GetText then
        local liveText = self.ui.channelEdit:GetText() or ""
        if liveText ~= "" then text = liveText end
    end
    text = Trim(text)
    local number = tonumber(text)
    if not number or number < 1 or number > 99 then return nil end
    number = math.floor(number)
    OTLGM_DB.settings.worldChannel = tostring(number)
    return number
end

function OTLGM:GetWorldChannelDisplay153()
    local channel, name, automatic = self:DetectWorldChannel153(false)
    if channel then return "/" .. tostring(channel), name or "World", automatic end
    local fallback = tonumber(OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.worldChannel)
    if fallback and fallback > 0 then return "/" .. tostring(math.floor(fallback)), "Manual", false end
    return "Not joined", "World", false
end

function OTLGM:FormatElapsedShort(seconds)
    seconds = math.max(0, seconds or 0)
    if seconds < 60 then return tostring(math.floor(seconds)) .. "s ago" end
    if seconds < 3600 then return tostring(math.floor(seconds / 60)) .. "m ago" end
    if seconds < 86400 then return tostring(math.floor(seconds / 3600)) .. "h ago" end
    return tostring(math.floor(seconds / 86400)) .. "d ago"
end

function OTLGM:FormatWorldRecruitmentElapsed(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)
    if seconds < 60 then return "<1m ago" end
    if seconds < 3600 then return tostring(math.floor(seconds / 60)) .. "m ago" end
    if seconds < 86400 then
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor(math.mod(seconds, 3600) / 60)
        if minutes > 0 then return tostring(hours) .. "h " .. tostring(minutes) .. "m ago" end
        return tostring(hours) .. "h ago"
    end
    return tostring(math.floor(seconds / 86400)) .. "d ago"
end

function OTLGM:GetWorldRecruitmentInfo()
    self:EnsureDB()
    local settings = OTLGM_DB.settings
    local timestamp = tonumber(settings.lastWorldRecruitmentAt)
    local info = {
        timestamp = timestamp,
        label = settings.lastWorldRecruitmentLabel or "World recruitment",
        channel = settings.lastWorldRecruitmentChannel or tostring(settings.worldChannel or "6"),
        value = "NEVER",
        detail = "No world recruitment post recorded yet.",
        state = "NEVER",
        elapsed = nil,
    }
    if not timestamp then return info end

    local elapsed = self:Now() - timestamp
    if elapsed < 0 then elapsed = 0 end
    local minimum = tonumber(settings.worldRecruitmentMinSeconds) or 600
    local recommended = tonumber(settings.worldRecruitmentRecommendedSeconds) or 900
    if recommended < minimum then recommended = minimum end

    info.elapsed = elapsed
    info.value = self:FormatWorldRecruitmentElapsed(elapsed)
    if elapsed < minimum then
        local waitMinutes = math.ceil((minimum - elapsed) / 60)
        if waitMinutes < 1 then waitMinutes = 1 end
        info.state = "WAIT"
        info.detail = "Wait " .. tostring(waitMinutes) .. "m before posting again."
    elseif elapsed < recommended then
        info.state = "WINDOW"
        info.detail = "Recommended 10-15 min window."
    else
        info.state = "READY"
        info.detail = "Safe to post in world again."
    end
    return info
end

function OTLGM:MarkRecruitmentSent(key, target, label)
    self:EnsureDB()
    if target ~= "WORLD" then return end
    if not key or key == "" then key = "WORKING" end
    local now = self:Now()
    OTLGM_DB.settings.recruitmentLastSent[key] = now
    OTLGM_DB.settings.lastWorldRecruitmentAt = now
    OTLGM_DB.settings.lastWorldRecruitmentLabel = label or key
    OTLGM_DB.settings.lastWorldRecruitmentChannel = tostring(self:GetWorldChannelNumber() or OTLGM_DB.settings.worldChannel or "6")
    if self.RefreshWorldRecruitmentIndicator then self:RefreshWorldRecruitmentIndicator() end
    if self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
end

function OTLGM:GetGuildChatMessages(channel)
    channel = channel == "OFFICER" and "OFFICER" or "GUILD"
    if channel == "OFFICER" then
        self.officerChatMessages = self.officerChatMessages or {}
        return self.officerChatMessages
    end

    local db = self:GetGuildDB()
    if not db then
        self.pendingGuildChatMessages = self.pendingGuildChatMessages or {}
        return self.pendingGuildChatMessages
    end
    db.guildChatMessages = db.guildChatMessages or {}
    if self.pendingGuildChatMessages and table.getn(self.pendingGuildChatMessages) > 0 then
        local i
        for i = 1, table.getn(self.pendingGuildChatMessages) do
            table.insert(db.guildChatMessages, self.pendingGuildChatMessages[i])
        end
        while table.getn(db.guildChatMessages) > 150 do table.remove(db.guildChatMessages, 1) end
        self.pendingGuildChatMessages = {}
        db.guildChatUnread = (db.guildChatUnread or 0) + (self.pendingGuildChatUnread or 0)
        self.pendingGuildChatUnread = 0
    end
    return db.guildChatMessages
end

function OTLGM:GetGuildChatChannel()
    self:EnsureDB()
    local channel = OTLGM_DB.settings.guildChatChannel or "GUILD"
    if channel == "OFFICER" and self.IsOfficerMode and not self:IsOfficerMode() then
        channel = "GUILD"
        OTLGM_DB.settings.guildChatChannel = channel
    end
    return channel
end

function OTLGM:GetGuildChatUnread(channel)
    channel = channel == "OFFICER" and "OFFICER" or "GUILD"
    if channel == "OFFICER" then return self.officerChatUnread or 0 end
    local db = self:GetGuildDB()
    if db then return db.guildChatUnread or 0 end
    return self.pendingGuildChatUnread or 0
end

function OTLGM:SetGuildChatUnread(channel, count)
    channel = channel == "OFFICER" and "OFFICER" or "GUILD"
    count = math.max(0, tonumber(count) or 0)
    if channel == "OFFICER" then
        self.officerChatUnread = count
    else
        local db = self:GetGuildDB()
        if db then db.guildChatUnread = count else self.pendingGuildChatUnread = count end
    end
end

function OTLGM:IsGuildChatChannelBeingRead(channel)
    if not self.ui or not self.ui.main or not self.ui.main:IsVisible() then return false end
    if self.ui.currentPage ~= "guildchat" then return false end
    if self:GetGuildChatChannel() ~= channel then return false end
    local offset = self.ui.chatOffsets and (self.ui.chatOffsets[channel] or 0) or 0
    return offset == 0
end

function OTLGM:SetGuildChatChannel(channel)
    local previousChannel180 = self.GetGuildChatChannel and self:GetGuildChatChannel() or "GUILD"
    if self.SaveGuildChatDraft and previousChannel180 then self:SaveGuildChatDraft(previousChannel180) end
    channel = channel == "OFFICER" and "OFFICER" or "GUILD"
    if channel == "OFFICER" and (not self.IsOfficerMode or not self:IsOfficerMode()) then
        if self.Notify then self:Notify("Officer Chat Unavailable", "Your current guild rank does not expose officer tools to the addon.") end
        channel = "GUILD"
    end
    self:EnsureDB()
    OTLGM_DB.settings.guildChatChannel = channel
    self.ui.chatOffsets = self.ui.chatOffsets or { GUILD = 0, OFFICER = 0 }
    self.ui.chatOffsets[channel] = 0
    self:SetGuildChatUnread(channel, 0)
    if self.RefreshGuildChatPage then self:RefreshGuildChatPage() end
    if self.RefreshGuildChatNavigationBadge then self:RefreshGuildChatNavigationBadge() elseif self.RefreshNavigation then self:RefreshNavigation() end
end

function OTLGM.__impl180.CaptureGuildChatMessage__impl1(self, channel, message, sender)
    channel = channel == "OFFICER" and "OFFICER" or "GUILD"
    message = Trim(message or "")
    sender = Trim(sender or "Unknown")
    if message == "" then return end
    message = string.gsub(message, "[\r\n]", " ")

    local messages = self:GetGuildChatMessages(channel)
    local messageTime = self:Now()
    if self.ui and self.ui.chatOffsets and (self.ui.chatOffsets[channel] or 0) > 0 then
        self.ui.chatOffsets[channel] = (self.ui.chatOffsets[channel] or 0) + 1
    end
    table.insert(messages, {
        ts = messageTime,
        sender = sender,
        text = message,
        channel = channel,
    })
    while table.getn(messages) > 150 do table.remove(messages, 1) end

    local playerName = UnitName and UnitName("player") or ""
    local ownMessage = NormalizeName(sender) == NormalizeName(playerName)
    local channelBeingRead = self:IsGuildChatChannelBeingRead(channel)
    if channelBeingRead then
        self:SetGuildChatUnread(channel, 0)
    elseif not ownMessage then
        local previousUnread = self:GetGuildChatUnread(channel)
        self.guildChatNewMarker = self.guildChatNewMarker or {}
        if previousUnread <= 0 or not self.guildChatNewMarker[channel] then
            self.guildChatNewMarker[channel] = messageTime
        end
        self:SetGuildChatUnread(channel, previousUnread + 1)
    end

    if not ownMessage and not channelBeingRead and OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.chatHighlightMentions ~= false
        and self.GuildChatTextMentionsPlayer and self:GuildChatTextMentionsPlayer(message) and self.NotifyEvent152 then
        local shortSender = string.gsub(sender or "Unknown", "%-.*$", "")
        local preview = self:Utf8Truncate(message, 120)
        local fingerprint = self:NormalizeText(shortSender .. ":" .. preview)
        self.runtime = self.runtime or {}
        self.runtime.pendingMentionTarget174 = { channel = channel, ts = messageTime, sender = shortSender, text = message }
        self:NotifyEvent152("mention", "MENTION:" .. channel .. ":" .. tostring(messageTime) .. ":" .. fingerprint,
            shortSender .. (channel == "OFFICER" and " mentioned you in officer chat" or " mentioned you in guild chat"),
            preview, "ACTION", true, "guildchat", {
                objectType = "CHAT_MESSAGE", objectId = channel .. ":" .. tostring(messageTime) .. ":" .. fingerprint,
                section = channel, actionKey = "MENTION", messageChannel = channel, messageTs = messageTime,
                messageSender = shortSender, messageText = message,
            })
        self.runtime.pendingMentionTarget174 = nil
    end

    if self.ui and self.ui.main and self.ui.main:IsVisible() and self.ui.currentPage == "guildchat" and self.RefreshGuildChatPage then
        self:RefreshGuildChatPage()
    end
    if self.RefreshGuildChatNavigationBadge then self:RefreshGuildChatNavigationBadge() elseif self.RefreshNavigation then self:RefreshNavigation() end
    return true
end

function OTLGM:ClearGuildChatHistory(channel)
    channel = channel == "OFFICER" and "OFFICER" or "GUILD"
    self.guildChatNewMarker = self.guildChatNewMarker or {}
    self.guildChatNewMarker[channel] = nil
    if channel == "OFFICER" then
        self.officerChatMessages = {}
        self.officerChatUnread = 0
    else
        self.pendingGuildChatMessages = {}
        self.pendingGuildChatUnread = 0
        local db = self:GetGuildDB()
        if db then
            db.guildChatMessages = {}
            db.guildChatUnread = 0
        end
    end
    if self.ui and self.ui.chatOffsets then self.ui.chatOffsets[channel] = 0 end
    if self.RefreshGuildChatPage then self:RefreshGuildChatPage() end
    if self.RefreshGuildChatNavigationBadge then self:RefreshGuildChatNavigationBadge() elseif self.RefreshNavigation then self:RefreshNavigation() end
end

function OTLGM:ClearGuildChatNewMarkers()
    self.guildChatNewMarker = {}
end

function OTLGM:SendGuildChatMessage(message, channel)
    message = Trim(message or "")
    channel = channel == "OFFICER" and "OFFICER" or "GUILD"
    if message == "" then
        if self.Notify then self:Notify("Message Empty", "Write a message before sending.") end
        return false
    end
    if channel == "OFFICER" and (not self.IsOfficerMode or not self:IsOfficerMode()) then
        if self.Notify then self:Notify("Officer Chat Unavailable", "Your current guild rank cannot use the officer chat page.") end
        return false
    end

    local ok, err = pcall(SendChatMessage, message, channel)
    if not ok then
        if self.Notify then self:Notify("Chat Message Failed", tostring(err)) end
        return false
    end
    if self.SetStatus then
        self:SetStatus(channel == "OFFICER" and "Message sent to officer chat." or "Message sent to guild chat.")
    end
    return true
end

OTLGM:RegisterModule("Guild", { layer = "core", owns = { "GuildKey", "Now", "ApplyCoreDefaults" } })
