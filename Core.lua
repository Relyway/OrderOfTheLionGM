-- Order of the Lion Guild Manager
-- Core systems for Vanilla WoW / OctoWoW (Interface 11200)

OTLGM = OTLGM or {}
OTLGM.version = "1.0.9"
OTLGM.addonName = "OrderOfTheLionGM"
OTLGM.pendingScan = false
OTLGM.pendingSilent = true
OTLGM.elapsed = 0
OTLGM.ui = OTLGM.ui or {}

OTLGM.colors = {
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
    { key = "BLACKSMITHING", label = "Blacksmithing", terms = { "blacksmith", "blacksmithing" } },
    { key = "ENCHANTING", label = "Enchanting", terms = { "enchanting", "enchanter" } },
    { key = "ENGINEERING", label = "Engineering", terms = { "engineering", "engineer" } },
    { key = "HERBALISM", label = "Herbalism", terms = { "herbalism", "herbalist" } },
    { key = "LEATHERWORKING", label = "Leatherworking", terms = { "leatherworking", "leatherworker" } },
    { key = "MINING", label = "Mining", terms = { "mining", "miner" } },
    { key = "SKINNING", label = "Skinning", terms = { "skinning", "skinner" } },
    { key = "TAILORING", label = "Tailoring", terms = { "tailoring", "tailor" } },
    { key = "COOKING", label = "Cooking", terms = { "cooking", "cook" } },
    { key = "FISHING", label = "Fishing", terms = { "fishing", "fisher" } },
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

local function SafeBooleanFunction(fn)
    if not fn then return false end
    local ok, result = pcall(fn)
    if not ok then return false end
    return result and true or false
end

function OTLGM:Chat(message)
    if self.SetStatus then self:SetStatus(message or "") end
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

function OTLGM:EnsureDB()
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
    if settings.customMessageNames == nil then settings.customMessageNames = { "Custom 1", "Custom 2", "Custom 3" } end
    if settings.recruitmentLastSent == nil then settings.recruitmentLastSent = {} end
    if settings.recruitmentReminderSeconds == nil then settings.recruitmentReminderSeconds = 300 end
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

function OTLGM:GetRecruitmentText(key)
    if self.recruitmentPresets[key] then return self.recruitmentPresets[key].text or "" end

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
    if self.recruitmentPresets[key] then OTLGM_DB.settings.customTarget = self.recruitmentPresets[key].target or "WORLD" end
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

function OTLGM:GetGuildDB()
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

function OTLGM:MigrateGuildDB(db)
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

function OTLGM:AddLog(db, kind, name, detail, actor, source, meta)
    local eventInfo = {
        ts = self:Now(),
        kind = kind,
        name = name or "",
        detail = detail or "",
        actor = actor or "",
        source = source or "",
    }
    if meta then
        eventInfo.class = meta.class or ""
        eventInfo.rank = meta.rank or ""
        eventInfo.rankBefore = meta.rankBefore or ""
        eventInfo.rankAfter = meta.rankAfter or ""
        eventInfo.levelBefore = meta.levelBefore
        eventInfo.levelAfter = meta.levelAfter
        eventInfo.publicNoteBefore = meta.publicNoteBefore
        eventInfo.publicNoteAfter = meta.publicNoteAfter
        eventInfo.officerNoteBefore = meta.officerNoteBefore
        eventInfo.officerNoteAfter = meta.officerNoteAfter
    end
    table.insert(db.log, 1, eventInfo)

    if kind == "JOIN" or kind == "LEAVE" or kind == "RANK" then db.unread = (db.unread or 0) + 1 end
    while table.getn(db.log) > 500 do table.remove(db.log) end
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

function OTLGM:ReadRoster()
    local snapshot = {}
    local total = GetNumGuildMembers(true) or 0
    local online = 0
    local now = self:Now()
    local i

    for i = 1, total do
        local name, rank, rankIndex, level, class, zone, note, officerNote, isOnline = GetGuildRosterInfo(i)
        if name then
            if isOnline then online = online + 1 end
            local offlineHours, lastOnlineText = self:BuildOfflineInfo(i, isOnline)
            snapshot[name] = {
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
                rosterIndex = i,
                seen = now,
            }
        end
    end

    return snapshot, total, online
end

function OTLGM:RequestScan(silent)
    if not GetGuildInfo("player") then
        if not silent then self:Chat(self.colors.red .. "You are not currently in a guild." .. self.colors.reset) end
        if self.SetStatus then self:SetStatus("You are not currently in a guild.") end
        return
    end

    if SetGuildRosterShowOffline then SetGuildRosterShowOffline(true) end
    self.pendingScan = true
    self.pendingSilent = silent and true or false
    GuildRoster()

    if not silent and self.SetStatus then self:SetStatus("Requesting guild roster...") end
end

function OTLGM:Scan(silent)
    local db = self:GetGuildDB()
    if not db then
        if not silent then self:Chat(self.colors.red .. "You are not currently in a guild." .. self.colors.reset) end
        return
    end

    local current, total, online = self:ReadRoster()
    if total == 0 then
        if not silent then self:Chat(self.colors.grey .. "The roster is not loaded yet. Trying again." .. self.colors.reset) end
        self.pendingScan = true
        self.pendingSilent = silent and true or false
        GuildRoster()
        return
    end

    self:CleanupPendingInvites(db)
    self:CleanupPendingActions(db)

    local joined = 0
    local left = 0
    local rankChanged = 0
    local leveled = 0
    local notesChanged = 0
    local name, info

    if db.initialized then
        for name, info in pairs(current) do
            local old = db.roster[name]
            if not old then
                joined = joined + 1
                local detail = "Joined the guild"
                local actor = ""
                local source = ""
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
                if old.rank ~= info.rank then
                    rankChanged = rankChanged + 1
                    local actionKind = "PROMOTE"
                    if (info.rankIndex or 99) > (old.rankIndex or 99) then actionKind = "DEMOTE" end
                    local action = self:ConsumeGuildAction(name, actionKind)
                    local detail = (old.rank or "?") .. " -> " .. (info.rank or "?")
                    self:AddLog(db, "RANK", name, detail, action and action.actor or "", action and action.source or "", {
                        class = info.class, rank = info.rank, rankBefore = old.rank, rankAfter = info.rank, levelAfter = info.level,
                    })
                end
                if old.level and info.level and info.level > old.level then
                    leveled = leveled + 1
                    self:AddLog(db, "LEVEL", name, tostring(old.level) .. " -> " .. tostring(info.level), "", "", {
                        class = info.class, rank = info.rank, levelBefore = old.level, levelAfter = info.level,
                    })
                end
                local publicChanged = old.note ~= info.note
                local officerChanged = old.officerNote ~= info.officerNote
                if publicChanged or officerChanged then
                    notesChanged = notesChanged + 1
                    local noteParts = {}
                    local oldPublic = old.note or ""
                    local newPublic = info.note or ""
                    local oldOfficer = old.officerNote or ""
                    local newOfficer = info.officerNote or ""
                    if publicChanged then
                        table.insert(noteParts, 'Public: "' .. (oldPublic ~= "" and oldPublic or "(empty)") .. '" > "' .. (newPublic ~= "" and newPublic or "(empty)") .. '"')
                    end
                    if officerChanged then
                        table.insert(noteParts, 'Officer: "' .. (oldOfficer ~= "" and oldOfficer or "(empty)") .. '" > "' .. (newOfficer ~= "" and newOfficer or "(empty)") .. '"')
                    end
                    local noteDetail = table.concat(noteParts, " | ")
                    local noteAction = self:ConsumeGuildAction(name, "NOTE")
                    self:AddLog(db, "NOTE", name, noteDetail, noteAction and noteAction.actor or "", noteAction and noteAction.source or "", {
                        class = info.class, rank = info.rank, levelAfter = info.level,
                        publicNoteBefore = oldPublic, publicNoteAfter = newPublic,
                        officerNoteBefore = oldOfficer, officerNoteAfter = newOfficer,
                    })
                end
            end
        end

        for name, info in pairs(db.roster) do
            if not current[name] then
                left = left + 1
                local action = self:ConsumeGuildAction(name, "REMOVE")
                if action then
                    self:AddLog(db, "LEAVE", name, "Removed from the guild", action.actor or "", action.source or "", {
                        class = info.class, rank = info.rank, rankBefore = info.rank, levelBefore = info.level,
                    })
                else
                    self:AddLog(db, "LEAVE", name, "Left or was removed; actor unavailable", "", "", {
                        class = info.class, rank = info.rank, rankBefore = info.rank, levelBefore = info.level,
                    })
                end
            end
        end
    else
        self:AddLog(db, "BASELINE", "Guild", "Initial roster saved: " .. total .. " members")
        db.initialized = true
    end

    db.roster = current
    db.lastScan = self:Now()
    db.lastTotal = total
    db.lastOnline = online

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

    local importantChanges = joined + left + rankChanged + leveled + notesChanged
    if not silent or (OTLGM_DB.settings.chatNotices and importantChanges > 0) then
        local message = "Roster scan complete: " .. self.colors.green .. tostring(online) .. self.colors.reset ..
            " online / " .. self.colors.white .. tostring(total) .. self.colors.reset .. " members."
        if importantChanges > 0 then
            local changes = {}
            if joined > 0 then table.insert(changes, self.colors.green .. "+" .. tostring(joined) .. " joined" .. self.colors.reset) end
            if left > 0 then table.insert(changes, self.colors.red .. "-" .. tostring(left) .. " left" .. self.colors.reset) end
            if rankChanged > 0 then table.insert(changes, self.colors.gold .. tostring(rankChanged) .. " rank" .. self.colors.reset) end
            if leveled > 0 then table.insert(changes, self.colors.blue .. tostring(leveled) .. " level-up" .. self.colors.reset) end
            if notesChanged > 0 then table.insert(changes, self.colors.grey .. tostring(notesChanged) .. " note" .. self.colors.reset) end
            message = message .. " Changes: " .. table.concat(changes, ", ") .. "."
        end
        self:Chat(message)
    end

    if self.RefreshAll then self:RefreshAll() end
    if self.UpdateMinimapBadge then self:UpdateMinimapBadge() end
    if self.SetStatus then self:SetStatus("Roster updated at " .. date("%H:%M", db.lastScan)) end
end

function OTLGM:GetStats(days)
    local db = self:GetGuildDB()
    local stats = { joins = 0, leaves = 0, ranks = 0, levels = 0, notes = 0, net = 0, inactive30 = 0 }
    if not db then return stats end

    local cutoff = self:Now() - ((days or 7) * 24 * 60 * 60)
    local i, eventInfo
    for i, eventInfo in ipairs(db.log) do
        if eventInfo.ts and eventInfo.ts >= cutoff then
            if eventInfo.kind == "JOIN" then stats.joins = stats.joins + 1 end
            if eventInfo.kind == "LEAVE" then stats.leaves = stats.leaves + 1 end
            if eventInfo.kind == "RANK" then stats.ranks = stats.ranks + 1 end
            if eventInfo.kind == "LEVEL" then stats.levels = stats.levels + 1 end
            if eventInfo.kind == "NOTE" then stats.notes = stats.notes + 1 end
        end
    end

    local name, member
    for name, member in pairs(db.roster) do
        if not member.online and (member.offlineDays or 0) >= 30 then stats.inactive30 = stats.inactive30 + 1 end
    end

    stats.net = stats.joins - stats.leaves
    return stats
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

function OTLGM:GetLeadershipRole(member)
    if not member then return nil, nil end
    local rank = string.lower(member.rank or "")
    if (member.rankIndex or 99) == 0 or string.find(rank, "guild leader", 1, true) then
        return "Interface\\Icons\\INV_Crown_01", "Guild Leader"
    end
    if string.find(rank, "raid leader", 1, true) then
        return "Interface\\Icons\\Ability_Warrior_BattleShout", "Raid Leader"
    end
    if string.find(rank, "officer", 1, true) or string.find(rank, "manager", 1, true) or string.find(rank, "inn keeper", 1, true) then
        return "Interface\\Icons\\INV_Shield_06", member.rank or "Officer"
    end
    if string.find(rank, "helper", 1, true) then
        return "Interface\\Icons\\Spell_Holy_Heal", member.rank or "Helper"
    end
    if string.find(rank, "leader", 1, true) then
        return "Interface\\Icons\\INV_Shield_06", member.rank or "Leadership"
    end
    return nil, nil
end

function OTLGM:GetMemberProfessionKeys(member)
    local result = {}
    if not member then return result end
    local text = string.lower((member.note or "") .. " " .. (member.officerNote or ""))
    local i, j, definition
    for i = 1, table.getn(self.professionDefinitions) do
        definition = self.professionDefinitions[i]
        local matched = false
        for j = 1, table.getn(definition.terms) do
            if string.find(text, definition.terms[j], 1, true) then
                matched = true
                break
            end
        end
        if matched then table.insert(result, definition.key) end
    end
    return result
end

function OTLGM:GetMemberProfessionLabels(member)
    local labels = {}
    local keys = self:GetMemberProfessionKeys(member)
    local i, j
    for i = 1, table.getn(keys) do
        for j = 1, table.getn(self.professionDefinitions) do
            if self.professionDefinitions[j].key == keys[i] then
                table.insert(labels, self.professionDefinitions[j].label)
                break
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

function OTLGM:GetSortedRoster(searchText, filter, rankFilter, professionFilter)
    local db = self:GetGuildDB()
    local list = {}
    if not db then return list end
    self:EnsureDB()

    professionFilter = professionFilter or OTLGM_DB.settings.rosterProfessionFilter or ""
    local playerZone = GetZoneText and (GetZoneText() or "") or ""
    local search = string.lower(Trim(searchText or ""))
    local name, member
    for name, member in pairs(db.roster) do
        local allowed = true
        if filter == "ONLINE" and not member.online then allowed = false end
        if filter == "LEADERSHIP" and not self:IsLeadership(member) then allowed = false end
        if filter == "INACTIVE30" and (member.online or (member.offlineDays or 0) < 30) then allowed = false end
        if filter == "LEVEL60" and (member.level or 0) ~= 60 then allowed = false end
        if filter == "SAMEZONE" and (not member.online or playerZone == "" or member.zone ~= playerZone) then allowed = false end
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
            local av = a.online and -1 or (a.offlineHours or 0)
            local bv = b.online and -1 or (b.offlineHours or 0)
            return av, bv
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

function OTLGM:GetFilteredHistory(filter)
    local db = self:GetGuildDB()
    local list = {}
    if not db then return list end

    local i, eventInfo
    for i, eventInfo in ipairs(db.log) do
        local allowed = false
        if not filter or filter == "ALL" then allowed = true end
        if filter == "MEMBERS" and (eventInfo.kind == "JOIN" or eventInfo.kind == "LEAVE") then allowed = true end
        if filter == eventInfo.kind then allowed = true end
        if allowed then table.insert(list, eventInfo) end
    end
    return list
end

function OTLGM:GetMember(name)
    local db = self:GetGuildDB()
    if not db or not name then return nil end
    return db.roster[name]
end

function OTLGM:FindRosterIndex(name)
    if not name then return nil end
    local total = GetNumGuildMembers(true) or 0
    local i
    for i = 1, total do
        local rosterName = GetGuildRosterInfo(i)
        if rosterName == name then return i end
    end
    return nil
end

function OTLGM:CanEditPublicNotes()
    return SafeBooleanFunction(CanEditPublicNote)
end

function OTLGM:CanEditOfficerNotes()
    return SafeBooleanFunction(CanEditOfficerNote)
end

function OTLGM:CanViewOfficerNotes()
    if CanViewOfficerNote then return CanViewOfficerNote() and true or false end
    return self:CanEditOfficerNotes()
end

function OTLGM:CanPromoteMembers()
    return SafeBooleanFunction(CanGuildPromote)
end

function OTLGM:CanDemoteMembers()
    return SafeBooleanFunction(CanGuildDemote)
end

function OTLGM:CanRemoveMembers()
    return SafeBooleanFunction(CanGuildRemove)
end

function OTLGM:SaveMemberNotes(name, publicNote, officerNote)
    local index = self:FindRosterIndex(name)
    if not index then
        self:SetStatus("Could not find " .. tostring(name) .. " in the live roster. Scan and try again.")
        return
    end

    local changed = false
    if self:CanEditPublicNotes() and GuildRosterSetPublicNote then
        GuildRosterSetPublicNote(index, publicNote or "")
        changed = true
    end
    if self:CanEditOfficerNotes() and GuildRosterSetOfficerNote then
        GuildRosterSetOfficerNote(index, officerNote or "")
        changed = true
    end

    if changed then
        self:RememberGuildAction("NOTE", name, UnitName("player") or "You", "local action")
        self:SetStatus("Notes saved for " .. tostring(name) .. ".")
        self:RequestScan(true)
    else
        self:SetStatus("Your guild rank cannot edit notes.")
    end
end

function OTLGM:PromoteMember(name)
    if not self:CanPromoteMembers() then
        self:SetStatus("Your guild rank cannot promote members.")
        return
    end

    local fn = GuildPromote or GuildPromoteByName or PromoteByName
    if not fn then
        self:SetStatus("Promotion function is not available in this client.")
        return
    end
    self:RememberGuildAction("PROMOTE", name, UnitName("player") or "You", "local action")
    fn(name)
    self:SetStatus("Promotion requested for " .. tostring(name) .. ". Updating roster...")
    self:RequestScan(true)
end

function OTLGM:DemoteMember(name)
    if not self:CanDemoteMembers() then
        self:SetStatus("Your guild rank cannot demote members.")
        return
    end

    local fn = GuildDemote or GuildDemoteByName or DemoteByName
    if not fn then
        self:SetStatus("Demotion function is not available in this client.")
        return
    end
    self:RememberGuildAction("DEMOTE", name, UnitName("player") or "You", "local action")
    fn(name)
    self:SetStatus("Demotion requested for " .. tostring(name) .. ". Updating roster...")
    self:RequestScan(true)
end

function OTLGM:RemoveMember(name)
    if not self:CanRemoveMembers() then
        self:SetStatus("Your guild rank cannot remove members.")
        return
    end

    local fn = GuildUninvite or GuildUninviteByName or GuildRemove
    if not fn then
        self:SetStatus("Remove-member function is not available in this client.")
        return
    end
    self:RememberGuildAction("REMOVE", name, UnitName("player") or "You", "local action")
    fn(name)
    self:SetStatus("Removal requested for " .. tostring(name) .. ". Updating roster...")
    self:RequestScan(true)
end

function OTLGM:MarkHistoryRead()
    local db = self:GetGuildDB()
    if db then db.unread = 0 end
    if self.UpdateMinimapBadge then self:UpdateMinimapBadge() end
end

function OTLGM:ResetGuildData()
    local key = self:GuildKey()
    if key and OTLGM_DB and OTLGM_DB.guilds then
        OTLGM_DB.guilds[key] = nil
        self:Chat("Local history for the current guild has been reset. The next scan will create a new baseline.")
        self:RequestScan(true)
        if self.RefreshAll then self:RefreshAll() end
    end
end

function OTLGM:GetWorldChannelNumber()
    self:EnsureDB()
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

function OTLGM:FormatElapsedShort(seconds)
    seconds = math.max(0, seconds or 0)
    if seconds < 60 then return tostring(math.floor(seconds)) .. "s ago" end
    if seconds < 3600 then return tostring(math.floor(seconds / 60)) .. "m ago" end
    if seconds < 86400 then return tostring(math.floor(seconds / 3600)) .. "h ago" end
    return tostring(math.floor(seconds / 86400)) .. "d ago"
end

function OTLGM:GetRecruitmentLastSentText(key, compact)
    self:EnsureDB()
    local ts = OTLGM_DB.settings.recruitmentLastSent[key or ""]
    if not ts then return compact and "Never sent" or "Last sent: never" end
    local elapsed = self:Now() - ts
    if elapsed < 0 then elapsed = 0 end
    if compact then return "Sent " .. self:FormatElapsedShort(elapsed) end
    local ready = elapsed >= (OTLGM_DB.settings.recruitmentReminderSeconds or 300) and " • ready" or ""
    return "Last sent: " .. date("%d/%m %H:%M", ts) .. " • " .. self:FormatElapsedShort(elapsed) .. ready
end

function OTLGM:MarkRecruitmentSent(key)
    self:EnsureDB()
    if not key or key == "" then key = "WORKING" end
    OTLGM_DB.settings.recruitmentLastSent[key] = self:Now()
    if self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
end

function OTLGM:SendMessageText(message, target)
    message = Trim(message or "")
    if message == "" then
        self:Chat(self.colors.red .. "Message is empty." .. self.colors.reset)
        return false
    end

    if target == "GUILD" then
        local ok, err = pcall(SendChatMessage, message, "GUILD")
        if not ok then
            self:Chat(self.colors.red .. "Could not send to guild chat: " .. tostring(err) .. self.colors.reset)
            return false
        end
        if self.SetStatus then self:SetStatus("Message sent to guild chat.") end
        return true
    end

    local channel = self:GetWorldChannelNumber()
    if not channel then
        self:Chat(self.colors.red .. "Enter a channel number, for example 5 or 6." .. self.colors.reset)
        return false
    end

    local channelId = channel
    local channelName = ""
    if GetChannelName then
        local resolvedId, resolvedName = GetChannelName(channel)
        if resolvedId and resolvedId > 0 then
            channelId = resolvedId
            channelName = resolvedName or ""
        end
    end

    local ok, err = pcall(SendChatMessage, message, "CHANNEL", nil, channelId)
    if not ok then
        self:Chat(self.colors.red .. "Could not send to /" .. tostring(channel) .. ": " .. tostring(err) .. self.colors.reset)
        if ChatFrameEditBox then
            ChatFrameEditBox:Show()
            ChatFrameEditBox:SetText("/" .. tostring(channel) .. " " .. message)
            ChatFrameEditBox:SetFocus()
            ChatFrameEditBox:HighlightText(0, 0)
            self:SetStatus("Message placed in chat input. Press Enter to send.")
        end
        return false
    end
    if self.SetStatus then
        local suffix = channelName ~= "" and " (" .. channelName .. ")" or ""
        self:SetStatus("Message sent to /" .. tostring(channel) .. suffix .. ".")
    end
    return true
end

function OTLGM:SendRecruitmentPreset(key)
    local preset = self.recruitmentPresets[key]
    if not preset then return end
    if self:SendMessageText(preset.text, preset.target) then self:MarkRecruitmentSent(key) end
end

function OTLGM:SendCurrentRecruitment()
    self:EnsureDB()
    local selected = OTLGM_DB.settings.selectedRecruitment or "WORKING"
    if self:SendMessageText(OTLGM_DB.settings.recruitmentMessage or "", OTLGM_DB.settings.customTarget or "WORLD") then
        self:MarkRecruitmentSent(selected)
    end
end

