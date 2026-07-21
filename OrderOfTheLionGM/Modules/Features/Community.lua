-- Order of the Lion Guild Manager
-- Announcements, notification preferences and community-domain migration.
-- Vanilla WoW / OctoWoW (Interface 11200)

OTLGM.systems152Loaded = true
OTLGM.systems152Version = OTLGM.version
OTLGM.announcementProtocol = "A3"

-- The worst legal post can expand substantially after delimiter escaping.
-- Keep this bound shared by sender and receiver so targeted recovery remains
-- safe even for a maximum-length character name and announcement ID.
local ANNOUNCEMENT_MAX_CHUNKS = 32

local BaseEnsureDB152 = OTLGM.ApplyAdvancedDefaults
local BaseMigrateGuildDB152 = OTLGM.MigrateLegacySchema6
local BaseHandleAddonMessage152 = OTLGM.HandlePresenceAddonMessageLegacy
local BaseGetDiagnosticsText152 = OTLGM._Stage_Advanced_GetDiagnosticsText_1
local BaseOnPveDataChanged152 = OTLGM._Stage_PVE_OnPveDataChanged_1
local BaseOnCraftingDataChanged152 = OTLGM._Stage_Crafting_OnCraftingDataChanged_1

local BaseCreatePveRequest152 = OTLGM._Stage_PVE_CreatePveRequest_1
local BaseApplyRemotePveRequest152 = OTLGM._Stage_PVE_ApplyRemotePveRequest_1
local BaseApplyRemotePveApplication152 = OTLGM._Stage_PVE_ApplyRemotePveApplication_1
local BaseApplyRemotePveRaid152 = OTLGM._Stage_PVE_ApplyRemotePveRaid_1
local BaseCreateCraftingRequest152 = OTLGM._Stage_Crafting_CreateCraftingRequest_1
local BaseApplyRemoteCraftingRequest152 = OTLGM._Stage_Crafting_ApplyRemoteCraftingRequest_1
local BaseApplyRemoteCraftingResponse152 = OTLGM._Stage_Crafting_ApplyRemoteCraftingResponse_1
local BaseApplyRemoteReaction152 = OTLGM._Stage_Crafting_ApplyRemoteReaction_1

local function S152Trim(text)
    text = tostring(text or "")
    return string.gsub(text, "^%s*(.-)%s*$", "%1")
end

local function S152NormalizeName(name)
    name = S152Trim(name)
    name = string.gsub(name, "%-.*$", "")
    return string.lower(name)
end

local function S152Safe(text, maximum, multiline)
    text = tostring(text or "")
    -- Avoid Lua-version-specific %z handling. Vanilla uses an old Lua runtime,
    -- so strip control bytes explicitly while keeping tab/newline/carriage return
    -- for the normalization directly below.
    local cleaned = {}
    local index, byteValue, character
    for index = 1, string.len(text) do
        byteValue = string.byte(text, index)
        character = string.sub(text, index, index)
        if byteValue >= 32 or byteValue == 9 or byteValue == 10 or byteValue == 13 then table.insert(cleaned, character) end
    end
    text = table.concat(cleaned)
    if multiline then
        text = string.gsub(text, "\r\n", "\n")
        text = string.gsub(text, "\r", "\n")
        text = string.gsub(text, "\t", " ")
        text = string.gsub(text, "\n\n\n+", "\n\n")
    else
        text = string.gsub(text, "[\r\n\t]", " ")
        text = string.gsub(text, "%s+", " ")
    end
    text = S152Trim(text)
    if maximum then text = OTLGM:Utf8Truncate(text, maximum) end
    return text
end

local function S152Escape(text, maximum, multiline, wireMaximum)
    text = S152Safe(text, maximum, multiline)
    local result = {}
    local wireLength = 0
    local index, character, encoded
    for index = 1, string.len(text) do
        character = string.sub(text, index, index)
        if character == "%" then encoded = "%25"
        elseif character == "^" then encoded = "%5E"
        elseif character == "|" then encoded = "%7C"
        elseif character == "~" then encoded = "%7E"
        elseif character == "\n" then encoded = "%0A"
        else encoded = character end
        if wireMaximum and wireLength + string.len(encoded) > wireMaximum then break end
        table.insert(result, encoded)
        wireLength = wireLength + string.len(encoded)
    end
    return table.concat(result)
end

local function S152Unescape(text)
    text = tostring(text or "")
    text = string.gsub(text, "%%0A", "\n")
    text = string.gsub(text, "%%7E", "~")
    text = string.gsub(text, "%%7C", "|")
    text = string.gsub(text, "%%5E", "^")
    text = string.gsub(text, "%%25", "%%")
    return text
end

local function S152ValidID(id)
    id = tostring(id or "")
    if id == "" or string.len(id) > 56 then return false end
    return string.find(id, "^[A-Za-z0-9_%-]+$") ~= nil
end

local function S152Split(text, delimiter)
    local result = {}
    local startAt = 1
    delimiter = delimiter or "^"
    while true do
        local found = string.find(text or "", delimiter, startAt, true)
        if not found then
            table.insert(result, string.sub(text or "", startAt))
            break
        end
        table.insert(result, string.sub(text or "", startAt, found - 1))
        startAt = found + string.len(delimiter)
    end
    return result
end

local function S152Count(tbl)
    local count = 0
    local key
    for key in pairs(tbl or {}) do count = count + 1 end
    return count
end

local function S152PruneMap(map, maximum)
    if type(map) ~= "table" then return end
    local entries = {}
    local key, value, timestamp
    for key, value in pairs(map or {}) do
        timestamp = type(value) == "table" and tonumber(value.ts) or tonumber(value)
        table.insert(entries, { key = key, ts = timestamp or 0 })
    end
    if table.getn(entries) <= maximum then return end
    table.sort(entries, function(a, b) return a.ts < b.ts end)
    local removeCount = table.getn(entries) - maximum
    local i
    for i = 1, removeCount do map[entries[i].key] = nil end
end

local function S152PruneAnnouncements(db)
    if not db then return end
    if type(db.announcements) ~= "table" then db.announcements = {} return end
    local entries = {}
    local id, record
    for id, record in pairs(db.announcements) do
        if type(record) == "table" and S152ValidID(id) then
            table.insert(entries, { id = id, ts = tonumber(record.updatedAt) or tonumber(record.createdAt) or 0, pinned = record.pinned and true or false, archived = record.archived and true or false })
        else
            -- Announcements are shared authoritative records. Invalid manual
            -- SavedVariables edits are discarded rather than reaching the UI.
            db.announcements[id] = nil
        end
    end
    if table.getn(entries) > 80 then
        table.sort(entries, function(a, b)
            if a.pinned ~= b.pinned then return not a.pinned end
            if a.archived ~= b.archived then return a.archived end
            return a.ts < b.ts
        end)
        local removeCount = table.getn(entries) - 80
        local i
        for i = 1, removeCount do db.announcements[entries[i].id] = nil end
    end

    -- Read and acknowledgement revisions are meaningful only while the post
    -- itself exists. Keeping them tied to the bounded announcement set avoids
    -- a slow SavedVariables leak after years of edits and deletions.
    local id
    for id in pairs(db.announcementRead or {}) do
        if not db.announcements[id] then db.announcementRead[id] = nil end
    end
    for id in pairs(db.announcementAcknowledged170 or {}) do
        if not db.announcements[id] then db.announcementAcknowledged170[id] = nil end
    end
end

local function S152PrunePendingAnnouncements(db, now)
    if not db then return end
    if type(db.pendingAnnouncements) ~= "table" then db.pendingAnnouncements = {} return end
    now = tonumber(now) or time()
    local key, pending
    for key, pending in pairs(db.pendingAnnouncements) do
        if type(pending) ~= "table" or not tonumber(pending.created) or tonumber(pending.created) + 300 < now then db.pendingAnnouncements[key] = nil end
    end
    S152PruneMap(db.pendingAnnouncements, 80)
end

local notificationDefaults152 = {
    raid = { visual = true, sound = true, soundName = "RaidWarning" },
    announcement = { visual = true, sound = true, soundName = "TellMessage" },
    group = { visual = true, sound = false, soundName = "MapPing" },
    response = { visual = true, sound = true, soundName = "TellMessage" },
    crafting = { visual = true, sound = false, soundName = "MapPing" },
    reaction = { visual = true, sound = false, soundName = "MapPing" },
    background = { visual = false, sound = false, soundName = "MapPing" },
}

OTLGM.notificationSoundChoices152 = {
    { key = "TellMessage", label = "Message" },
    { key = "RaidWarning", label = "Raid Warning" },
    { key = "MapPing", label = "Map Ping" },
}

function OTLGM:ApplySystemsDefaults()
    BaseEnsureDB152(self)
    OTLGM_DB.settings = OTLGM_DB.settings or {}
    local settings = OTLGM_DB.settings
    settings.notifications = settings.notifications or {}
    local category, defaults
    for category, defaults in pairs(notificationDefaults152) do
        settings.notifications[category] = settings.notifications[category] or {}
        if settings.notifications[category].visual == nil then settings.notifications[category].visual = defaults.visual end
        if settings.notifications[category].sound == nil then settings.notifications[category].sound = defaults.sound end
        if not settings.notifications[category].soundName or settings.notifications[category].soundName == "" then settings.notifications[category].soundName = defaults.soundName end
    end
    if settings.guildChatView == nil then settings.guildChatView = "GUILD" end
    if settings.announcementArchiveVisible == nil then settings.announcementArchiveVisible = false end
    if settings.onboarding152Complete == nil then settings.onboarding152Complete = false end
    if settings.announcementDraftTitle153 == nil then settings.announcementDraftTitle153 = "" end
    if settings.announcementDraftBody153 == nil then settings.announcementDraftBody153 = "" end
    if settings.craftingCategory153 == nil then settings.craftingCategory153 = "ALL" end
    if settings.craftingLevelFilter153 == nil then settings.craftingLevelFilter153 = "ANY" end
    if settings.craftingRarityFilter153 == nil then settings.craftingRarityFilter153 = "ANY" end
    if settings.craftingSort153 == nil then settings.craftingSort153 = "ONLINE" end
    if settings.craftingOnlineOnly153 == nil then settings.craftingOnlineOnly153 = false end
    OTLGM_DB.version = self.version
end

function OTLGM:MigrateLegacySchema11(db)
    BaseMigrateGuildDB152(self, db)
    if not db then return end
    db.announcements = db.announcements or {}
    db.announcementDeleted = db.announcementDeleted or {}
    db.pendingAnnouncements = db.pendingAnnouncements or {}
    db.announcementRead = db.announcementRead or {}
    db.notificationSeen = db.notificationSeen or {}
    db.notificationUnread = db.notificationUnread or {}
    db.recentUsefulActivity = db.recentUsefulActivity or {}
    db.announcementSync = db.announcementSync or { requested = 0, received = 0, rejected = 0, completed = 0 }
    local category
    for category in pairs(notificationDefaults152) do
        if db.notificationUnread[category] == nil then db.notificationUnread[category] = 0 end
    end
    while table.getn(db.recentUsefulActivity) > 30 do table.remove(db.recentUsefulActivity) end
    S152PruneMap(db.notificationSeen, 600)
    S152PruneMap(db.announcementDeleted, 160)
    S152PrunePendingAnnouncements(db, self:Now())
    S152PruneAnnouncements(db)
    db.schemaVersion = self.schemaVersion
end

function OTLGM:GetNotificationPreference152(category)
    self:EnsureDB()
    local pref = OTLGM_DB.settings.notifications[category]
    if not pref then
        pref = { visual = true, sound = false, soundName = "MapPing" }
        OTLGM_DB.settings.notifications[category] = pref
    end
    return pref
end

function OTLGM:CycleNotificationSound152(category)
    local pref = self:GetNotificationPreference152(category)
    local choices = self.notificationSoundChoices152 or {}
    local current = 1
    local i
    for i = 1, table.getn(choices) do
        if choices[i].key == pref.soundName then current = i break end
    end
    current = current + 1
    if current > table.getn(choices) then current = 1 end
    if choices[current] then pref.soundName = choices[current].key end
    if pref.sound and PlaySound and pref.soundName then pcall(PlaySound, pref.soundName) end
    return pref.soundName
end

function OTLGM:GetNotificationSoundLabel152(category)
    local pref = self:GetNotificationPreference152(category)
    local choices = self.notificationSoundChoices152 or {}
    local i
    for i = 1, table.getn(choices) do if choices[i].key == pref.soundName then return choices[i].label end end
    return "Message"
end

function OTLGM:GetNotificationUnread152(category)
    local db = self:GetGuildDB()
    return db and tonumber(db.notificationUnread and db.notificationUnread[category]) or 0
end

local function S152InboxTarget(category)
    if category == "announcement" or category == "reaction" then return "home" end
    if category == "crafting" or category == "response" then return "professions" end
    if category == "raid" or category == "group" then return "pve" end
    return "home"
end

local function S152RecountInbox(db)
    if not db then return end
    db.notificationUnread = db.notificationUnread or {}
    local category
    for category in pairs(notificationDefaults152) do db.notificationUnread[category] = 0 end
    local index, entry
    for index = table.getn(db.inbox170 or {}), 1, -1 do
        entry = db.inbox170[index]
        if type(entry) ~= "table" or tostring(entry.id or "") == "" then
            table.remove(db.inbox170, index)
        elseif not entry.read then
            db.notificationUnread[entry.category or "background"] = (tonumber(db.notificationUnread[entry.category or "background"]) or 0) + 1
        end
    end
end

function OTLGM:AddInboxNotification170(category, eventKey, title, body, priority, targetPage)
    local db = self:GetGuildDB()
    if not db then return false end
    db.inbox170 = db.inbox170 or {}
    eventKey = S152Safe(eventKey, 120, false)
    if eventKey == "" then return false end
    local index, old
    for index = 1, table.getn(db.inbox170) do
        old = db.inbox170[index]
        if type(old) == "table" and old.id == eventKey then return false end
    end
    local entry = {
        id = eventKey,
        ts = self:Now(),
        category = S152Safe(category, 20, false),
        title = S152Safe(title or "Guild update", 80, false),
        body = S152Safe(body or "", 180, false),
        priority = priority == "CRITICAL" and "CRITICAL" or priority == "ACTION" and "ACTION" or "NORMAL",
        targetPage = S152Safe(targetPage or S152InboxTarget(category), 20, false),
        read = false,
    }
    table.insert(db.inbox170, 1, entry)
    while table.getn(db.inbox170) > 80 do table.remove(db.inbox170) end
    S152RecountInbox(db)
    return true
end

function OTLGM:GetInboxEntries170(mode)
    local db = self:GetGuildDB()
    local result = {}
    local index, entry
    mode = mode or "ALL"
    for index = 1, table.getn(db and db.inbox170 or {}) do
        entry = db.inbox170[index]
        if type(entry) == "table" and (mode == "ALL" or (mode == "UNREAD" and not entry.read)
            or (mode == "ACTION" and (entry.priority == "ACTION" or entry.priority == "CRITICAL"))) then table.insert(result, entry) end
    end
    return result
end

function OTLGM:GetInboxUnreadCount170(category)
    local db = self:GetGuildDB()
    local count = 0
    local index, entry
    for index = 1, table.getn(db and db.inbox170 or {}) do
        entry = db.inbox170[index]
        if type(entry) == "table" and not entry.read and (not category or entry.category == category) then count = count + 1 end
    end
    return count
end

function OTLGM:MarkInboxRead170(id)
    local db = self:GetGuildDB()
    local index, entry
    for index = 1, table.getn(db and db.inbox170 or {}) do
        entry = db.inbox170[index]
        if type(entry) == "table" and entry.id == id then entry.read = true S152RecountInbox(db) if self.RefreshNavigation then self:RefreshNavigation() end return true end
    end
    return false
end

function OTLGM:MarkInboxCategoryRead170(category)
    local db = self:GetGuildDB()
    local changed = false
    local index, entry
    for index = 1, table.getn(db and db.inbox170 or {}) do
        entry = db.inbox170[index]
        if type(entry) == "table" and not entry.read and (not category or entry.category == category) then entry.read = true changed = true end
    end
    if changed then S152RecountInbox(db) if self.RefreshNavigation then self:RefreshNavigation() end end
    return changed
end

function OTLGM:MarkInboxPageRead170(targetPage)
    targetPage = S152Safe(targetPage, 20, false)
    if targetPage == "" then return false end
    local db = self:GetGuildDB()
    local changed = false
    local index, entry
    for index = 1, table.getn(db and db.inbox170 or {}) do
        entry = db.inbox170[index]
        if type(entry) == "table" and not entry.read and entry.targetPage == targetPage then entry.read = true changed = true end
    end
    if changed then S152RecountInbox(db) if self.RefreshNavigation then self:RefreshNavigation() end end
    return changed
end

function OTLGM:MarkInboxMatching170(prefix)
    prefix = tostring(prefix or "")
    if prefix == "" then return false end
    local db = self:GetGuildDB()
    local changed = false
    local index, entry
    for index = 1, table.getn(db and db.inbox170 or {}) do
        entry = db.inbox170[index]
        if type(entry) == "table" and not entry.read and string.sub(tostring(entry.id or ""), 1, string.len(prefix)) == prefix then entry.read = true changed = true end
    end
    if changed then S152RecountInbox(db) if self.RefreshNavigation then self:RefreshNavigation() end end
    return changed
end

function OTLGM:NotifyEvent152(category, eventKey, title, body, priority, remote, targetPage)
    if not remote then return false end
    local db = self:GetGuildDB()
    if not db then return false end
    eventKey = S152Safe(eventKey, 120, false)
    if eventKey == "" then return false end
    if db.notificationSeen[eventKey] then return false end
    db.notificationSeen[eventKey] = { ts = self:Now(), category = category }
    S152PruneMap(db.notificationSeen, 600)
    self:AddInboxNotification170(category, eventKey, title, body, priority, targetPage or S152InboxTarget(category))
    local pref = self:GetNotificationPreference152(category)
    if pref.visual then
        if priority == "CRITICAL" or priority == "ACTION" then
            if self.ShowNotice then self:ShowNotice(title or "Order of the Lion", body or "") end
        elseif self.SetStatus then
            self:SetStatus((title or "Guild update") .. (body and body ~= "" and (": " .. body) or ""))
        end
    end
    if pref.sound and PlaySound and pref.soundName then pcall(PlaySound, pref.soundName) end
    if self.RefreshNavigation then self:RefreshNavigation() end
    if self.UpdateMinimapBadge then self:UpdateMinimapBadge() end
    return true
end

function OTLGM:AddUsefulActivity152(kind, title, detail, targetPage, timestamp)
    local db = self:GetGuildDB()
    if not db then return end
    if type(db.recentUsefulActivity) ~= "table" then db.recentUsefulActivity = {} end
    local repairIndex
    for repairIndex = table.getn(db.recentUsefulActivity), 1, -1 do
        if type(db.recentUsefulActivity[repairIndex]) ~= "table" then table.remove(db.recentUsefulActivity, repairIndex) end
    end
    local entry = {
        ts = tonumber(timestamp) or self:Now(),
        kind = S152Safe(kind, 20, false),
        title = S152Safe(title, 80, false),
        detail = S152Safe(detail, 120, false),
        targetPage = S152Safe(targetPage, 20, false),
    }
    entry.fingerprint170 = self:NormalizeText(entry.kind .. "|" .. entry.title .. "|" .. entry.detail .. "|" .. entry.targetPage)
    local index, existing
    for index = 1, math.min(12, table.getn(db.recentUsefulActivity)) do
        existing = db.recentUsefulActivity[index]
        local fingerprint = existing.fingerprint170 or self:NormalizeText((existing.kind or "") .. "|" .. (existing.title or "") .. "|" .. (existing.detail or "") .. "|" .. (existing.targetPage or ""))
        if fingerprint == entry.fingerprint170 and math.abs((tonumber(existing.ts) or 0) - entry.ts) <= 60 then
            existing.ts = math.max(tonumber(existing.ts) or 0, entry.ts)
            existing.duplicateCount170 = (tonumber(existing.duplicateCount170) or 1) + 1
            existing.fingerprint170 = fingerprint
            if index > 1 then
                table.remove(db.recentUsefulActivity, index)
                table.insert(db.recentUsefulActivity, 1, existing)
            end
            return existing
        end
    end
    table.insert(db.recentUsefulActivity, 1, entry)
    while table.getn(db.recentUsefulActivity) > 30 do table.remove(db.recentUsefulActivity) end
    return entry
end

function OTLGM:GetUsefulActivity152(limit)
    local db = self:GetGuildDB()
    local result = {}
    local maximum = tonumber(limit) or 4
    local seen = {}
    local i, entry, fingerprint, previousTimestamp
    local activity = db and type(db.recentUsefulActivity) == "table" and db.recentUsefulActivity or {}
    for i = 1, table.getn(activity) do
        entry = activity[i]
        if type(entry) == "table" then
            fingerprint = entry.fingerprint170 or self:NormalizeText((entry.kind or "") .. "|" .. (entry.title or "") .. "|" .. (entry.detail or "") .. "|" .. (entry.targetPage or ""))
            previousTimestamp = seen[fingerprint]
        end
        if type(entry) == "table" and (not previousTimestamp or math.abs((tonumber(entry.ts) or 0) - previousTimestamp) > 60) then
            table.insert(result, entry)
            seen[fingerprint] = tonumber(entry.ts) or 0
            if table.getn(result) >= maximum then break end
        end
    end
    return result
end

function OTLGM:CanPublishAnnouncement152()
    local player = string.gsub(UnitName("player") or "", "%-.*$", "")
    local member = self.GetMember and self:GetMember(player) or nil
    if member and self.IsLeadership and self:IsLeadership(member) then return true end
    if self.CanEditOfficerNotes and self:CanEditOfficerNotes() then return true end
    return false
end

function OTLGM:IsAnnouncementSenderAllowed152(sender)
    if not sender or sender == "" then return false end
    if self.IsPveLeadershipName and self:IsPveLeadershipName(sender) then return true end
    local member = self.GetMember and self:GetMember(string.gsub(sender, "%-.*$", "")) or nil
    return member and self.IsLeadership and self:IsLeadership(member) and true or false
end

function OTLGM:GetAnnouncementList152(includeArchived)
    local db = self:GetGuildDB()
    local result = {}
    local id, record
    for id, record in pairs(db and db.announcements or {}) do
        if type(record) == "table" and (includeArchived or not record.archived) then table.insert(result, record) end
    end
    table.sort(result, function(a, b)
        local ap = a.pinned and 1 or 0
        local bp = b.pinned and 1 or 0
        if ap ~= bp then return ap > bp end
        if (tonumber(a.updatedAt) or tonumber(a.createdAt) or 0) ~= (tonumber(b.updatedAt) or tonumber(b.createdAt) or 0) then
            return (tonumber(a.updatedAt) or tonumber(a.createdAt) or 0) > (tonumber(b.updatedAt) or tonumber(b.createdAt) or 0)
        end
        return tostring(a.id or "") > tostring(b.id or "")
    end)
    return result
end

function OTLGM:GetAnnouncement152(id)
    local db = self:GetGuildDB()
    return db and db.announcements and db.announcements[id]
end

function OTLGM:IsAnnouncementUnread154(id)
    local db = self:GetGuildDB()
    local record = db and db.announcements and db.announcements[id]
    if type(record) ~= "table" then return false end
    local readRevision = tonumber(db.announcementRead and db.announcementRead[id]) or 0
    return readRevision < (tonumber(record.revision) or 1)
end

function OTLGM:MarkAnnouncementRead154(id)
    local db = self:GetGuildDB()
    local record = db and db.announcements and db.announcements[id]
    if type(record) ~= "table" then return false end
    db.announcementRead = db.announcementRead or {}
    db.announcementRead[id] = tonumber(record.revision) or 1
    if self.RefreshNavigation then self:RefreshNavigation() end
    return true
end

function OTLGM:GetAnnouncementUnreadCount154()
    local db = self:GetGuildDB()
    local count = 0
    local id, record
    for id, record in pairs(db and db.announcements or {}) do
        if type(record) == "table" and not record.archived and self:IsAnnouncementUnread154(id) then count = count + 1 end
    end
    return count
end

function OTLGM:QueueAnnouncementRecord152(record, target)
    if not record or not self.QueueCommunityPayload or not S152ValidID(record.id) then return false end
    local contentWire = S152Escape(record.title, 80, false) .. "~" .. S152Escape(record.body, 900, true)
    local networkLimit = self.GetNetworkPayloadLimit and self:GetNetworkPayloadLimit(target and "WHISPER" or "GUILD", target) or 250
    -- Reserve the exact BODY header, not a historical approximation. IDs and
    -- targeted-envelope address bytes are variable, while content chunks are
    -- the only field that may be split without changing meaning.
    local bodyHeader = table.concat({
        self.announcementProtocol, "BODY", record.id, tostring(record.revision or 1),
        tostring(ANNOUNCEMENT_MAX_CHUNKS), tostring(ANNOUNCEMENT_MAX_CHUNKS), "",
    }, "^")
    local chunkSize = math.min(155, networkLimit - string.len(bodyHeader))
    if chunkSize < 32 then return false end
    local chunks, at = {}, 1
    while at <= string.len(contentWire) do table.insert(chunks, string.sub(contentWire, at, at + chunkSize - 1)) at = at + chunkSize end
    if table.getn(chunks) == 0 then table.insert(chunks, "~") end
    if table.getn(chunks) > ANNOUNCEMENT_MAX_CHUNKS then return false end
    local payloads = {}
    local meta = table.concat({
        self.announcementProtocol, "META", record.id, tostring(record.revision or 1),
        tostring(record.createdAt or self:Now()), tostring(record.updatedAt or record.createdAt or self:Now()),
        S152Escape(record.author, 28, false, 72), S152Escape(record.importance, 12, false, 24),
        record.notifyFlag and "1" or "0", record.pinned and "1" or "0", record.archived and "1" or "0", tostring(table.getn(chunks)), tostring(record.authorRankIndex or 99),
        S152Escape(record.category, 16, false, 32), record.requiresAck and "1" or "0"
    }, "^")
    if string.len(meta) > networkLimit then return false end
    table.insert(payloads, meta)
    local i
    for i=1,table.getn(chunks) do
        local payload=table.concat({self.announcementProtocol,"BODY",record.id,tostring(record.revision or 1),tostring(i),tostring(table.getn(chunks)),chunks[i] or ""},"^")
        if string.len(payload)>networkLimit then return false end
        table.insert(payloads,payload)
    end
    if self.CanQueueNetworkPayloads and not self:CanQueueNetworkPayloads(table.getn(payloads), 18) then return false end
    for i=1,table.getn(payloads) do
        if not self:QueueCommunityPayload(payloads[i],target and "WHISPER" or "GUILD",target,target and 2 or 1) then return false end
    end
    return true
end

function OTLGM:PublishAnnouncement152(title, body, importance, notifyFlag, pinned, existingId)
    if not self:CanPublishAnnouncement152() then return false, "Only guild leadership can publish official announcements." end
    title = S152Safe(title, 80, false)
    body = S152Safe(body, 900, true)
    if title == "" or body == "" then return false, "A title and message are required." end
    importance = importance == "CRITICAL" and "CRITICAL" or (importance == "IMPORTANT" and "IMPORTANT" or "NORMAL")
    local db = self:GetGuildDB()
    local now = self:Now()
    local author = string.gsub(UnitName("player") or "Leadership", "%-.*$", "")
    if existingId and not S152ValidID(existingId) then return false, "The announcement ID is invalid." end
    local record = existingId and db.announcements[existingId] or nil
    if record and S152NormalizeName(record.author) ~= S152NormalizeName(author) and not self:CanPublishAnnouncement152() then return false, "This announcement cannot be edited." end
    if not record then
        local id = string.lower(author) .. "-" .. tostring(now) .. "-" .. tostring(math.random(100, 999))
        local authorMember = self.GetMember and self:GetMember(author) or nil
        record = { id = id, revision = 0, createdAt = now, author = author, authorRankIndex = authorMember and authorMember.rankIndex or 99, reactions = {}, verified = true }
    end
    record.revision = (tonumber(record.revision) or 0) + 1
    record.updatedAt = now
    record.title = title
    record.body = body
    record.importance = importance
    -- Importance also provides a consistent visual state on every client.
    -- These are metadata only; old clients safely ignore the appended fields.
    record.category = importance == "CRITICAL" and "URGENT" or (importance == "IMPORTANT" and "IMPORTANT" or "GUILD POST")
    record.requiresAck = importance == "CRITICAL"
    record.notifyFlag = notifyFlag and true or false
    record.pinned = pinned and true or false
    record.archived = false
    record.author = record.author or author
    local currentAuthorMember = self.GetMember and self:GetMember(record.author) or nil
    if currentAuthorMember then record.authorRankIndex = currentAuthorMember.rankIndex end
    record.verified = true
    db.announcements[record.id] = record
    db.announcementSync = db.announcementSync or {}
    db.announcementSync.received = (tonumber(db.announcementSync.received) or 0) + 1
    db.announcementSync.completed = self:Now()
    db.announcementRead = db.announcementRead or {}
    db.announcementRead[record.id] = tonumber(record.revision) or 1
    S152PruneAnnouncements(db)
    local queued = self:QueueAnnouncementRecord152(record)
    if not queued and self.SetStatus then self:SetStatus("Announcement saved locally, but its network packets could not be queued safely.") end
    self:AddUsefulActivity152("ANNOUNCEMENT", "Leadership published: " .. title, author, "home", now)
    if self.OnAnnouncementDataChanged152 then self:OnAnnouncementDataChanged152(false) end
    return true, record
end

function OTLGM:SetAnnouncementArchived152(id, archived)
    local db = self:GetGuildDB()
    local record = db and db.announcements and db.announcements[id]
    if not record or not self:CanPublishAnnouncement152() then return false end
    record.archived = archived and true or false
    record.revision = (tonumber(record.revision) or 0) + 1
    record.updatedAt = self:Now()
    self:QueueAnnouncementRecord152(record)
    if self.OnAnnouncementDataChanged152 then self:OnAnnouncementDataChanged152(false) end
    return true
end

function OTLGM:DeleteAnnouncement152(id)
    if not S152ValidID(id) then return false end
    local db = self:GetGuildDB()
    local record = db and db.announcements and db.announcements[id]
    if not record or not self:CanPublishAnnouncement152() then return false end
    local revision = (tonumber(record.revision) or 0) + 1
    db.announcements[id] = nil
    db.announcementDeleted[id] = { revision = revision, ts = self:Now() }
    S152PruneAnnouncements(db)
    self:QueueCommunityPayload(table.concat({ self.announcementProtocol, "DEL", id, tostring(revision), S152Escape(UnitName("player") or "", 28, false) }, "^"), "GUILD")
    if self.OnAnnouncementDataChanged152 then self:OnAnnouncementDataChanged152(false) end
    return true
end

function OTLGM:ReactToAnnouncement152(id, reaction)
    if not id or not self.SetCommunityReaction then return false end
    if reaction ~= "LIKE" and reaction ~= "SEEN" and reaction ~= "SUPPORT" then return false end
    local record = self:GetAnnouncement152(id)
    -- A required acknowledgement is revision-scoped and intentionally cannot
    -- be toggled back off by clicking the already-acknowledged button again.
    local force = record and record.requiresAck and reaction == "SEEN"
    local result = self:SetCommunityReaction("ANN", id, reaction, force and true or false)
    if result and reaction == "SEEN" then
        local db = self:GetGuildDB()
        if db and record then
            db.announcementAcknowledged170 = db.announcementAcknowledged170 or {}
            db.announcementAcknowledged170[id] = tonumber(record.revision) or 1
        end
    end
    if result then
        if self.MarkAnnouncementRead154 then self:MarkAnnouncementRead154(id) end
        if self.MarkInboxMatching170 then self:MarkInboxMatching170("ANN:" .. tostring(id) .. ":") end
    end
    return result
end

function OTLGM:IsAnnouncementAcknowledged170(id)
    local db = self:GetGuildDB()
    local record = db and db.announcements and db.announcements[id]
    if type(record) ~= "table" then return false end
    return (tonumber(db.announcementAcknowledged170 and db.announcementAcknowledged170[id]) or 0) >= (tonumber(record.revision) or 1)
end

function OTLGM:GetAnnouncementReadTarget172(id, revision)
    id = tostring(id or "")
    revision = tonumber(revision) or 0
    if not S152ValidID(id) or revision < 1 then return nil end
    return id .. ":" .. tostring(revision)
end

function OTLGM:RecordAnnouncementReadReceipt172(id)
    local record = self:GetAnnouncement152(id)
    local target = record and self:GetAnnouncementReadTarget172(id, record.revision) or nil
    if not target or not self.SetCommunityReaction then return false end
    local player = string.gsub(UnitName("player") or "Unknown", "%-.*$", "")
    local craft = self.EnsureCraftingDB and self:EnsureCraftingDB() or nil
    local existing = craft and craft.reactions and craft.reactions["ANNREAD:" .. target] and craft.reactions["ANNREAD:" .. target][player]
    if existing and existing.reaction == "READ" then return false end
    return self:SetCommunityReaction("ANNREAD", target, "READ", true)
end

function OTLGM:GetAnnouncementReaders172(id)
    local record = self:GetAnnouncement152(id)
    local target = record and self:GetAnnouncementReadTarget172(id, record.revision) or nil
    if not target or not self.GetCommunityReactors then return {} end
    return self:GetCommunityReactors("ANNREAD", target, "READ")
end

function OTLGM:GetAnnouncementReactionSummary152(id)
    if not self.GetCommunityReactionSummary then return {} end
    return self:GetCommunityReactionSummary("ANN", id)
end

function OTLGM:RequestAnnouncementSync152(force)
    if not self.QueueCommunityPayload or not GetGuildInfo("player") then return false end
    local now=self:Now()
    if not force and self.lastAnnouncementSync152 and now-self.lastAnnouncementSync152<60 then return false end
    self.lastAnnouncementSync152=now
    local db=self:GetGuildDB()
    if db and db.announcementSync then db.announcementSync.requested=now end
    self:QueueCommunityPayload(table.concat({self.announcementProtocol,"SYNC",self.version,tostring(now)},"^"),"GUILD",nil,3,"announcements:sync")
    return true
end

function OTLGM:ScheduleAnnouncementState155(target)
    if not target or target == "" or S152NormalizeName(target)==S152NormalizeName(UnitName("player") or "") then return false end
    local db=self:GetGuildDB()
    local hasVerified=false
    local _,record
    for _,record in pairs(db and db.announcements or {}) do if type(record) == "table" and (record.verified or self:IsAnnouncementSenderAllowed152(record.author)) then hasVerified=true break end end
    if not hasVerified then return false end
    self.announcementShareTargets155=self.announcementShareTargets155 or {}
    local score=0
    local name=UnitName("player") or "Player"
    local i
    for i=1,string.len(name) do score=score+string.byte(name,i) end
    local due=self:Now()+2+math.mod(score,9)
    local key=S152NormalizeName(target)
    local old=self.announcementShareTargets155[key]
    if not old or due<(old.due or due) then self.announcementShareTargets155[key]={name=target,due=due} end
    return true
end

function OTLGM:ProcessAnnouncementTimers155()
    local key,pending
    for key,pending in pairs(self.announcementShareTargets155 or {}) do
        if pending and self:Now()>=(pending.due or 0) then
            self.announcementShareTargets155[key]=nil
            self:QueueAnnouncementState152(pending.name)
            break
        end
    end
end

function OTLGM:QueueAnnouncementState152(target)
    if not target or target == "" then return false end
    -- Official posts may outlive their author, but only another current
    -- leadership member is allowed to relay them as authoritative data.
    if self.IsLeadershipSender and not self:IsLeadershipSender(UnitName("player") or "") then return false end
    local list=self:GetAnnouncementList152(true)
    local i,queued=0,false
    for i=1,math.min(12,table.getn(list)) do
        local record=list[i]
        if record and (record.verified or self:IsAnnouncementSenderAllowed152(record.author)) then
            if not self:QueueAnnouncementRecord152(record,target) then break end
            queued=true
        end
    end
    return queued
end

function OTLGM:TryFinishAnnouncement152(pendingKey)
    local db = self:GetGuildDB()
    local pending = db and db.pendingAnnouncements and db.pendingAnnouncements[pendingKey]
    if type(pending) ~= "table" or type(pending.meta) ~= "table" or type(pending.chunks) ~= "table" then return false end
    local i
    for i = 1, pending.total do if pending.chunks[i] == nil then return false end end
    local contentWire = ""
    for i = 1, pending.total do contentWire = contentWire .. (pending.chunks[i] or "") end
    local separator = string.find(contentWire, "~", 1, true)
    if not separator then db.pendingAnnouncements[pendingKey] = nil return false end
    local record = pending.meta
    record.title = S152Safe(S152Unescape(string.sub(contentWire, 1, separator - 1)), 80, false)
    record.body = S152Safe(S152Unescape(string.sub(contentWire, separator + 1)), 900, true)
    if record.title == "" or record.body == "" then db.pendingAnnouncements[pendingKey] = nil return false end
    local deleted = db.announcementDeleted[record.id]
    if deleted and (tonumber(deleted.revision) or 0) >= (tonumber(record.revision) or 0) then db.pendingAnnouncements[pendingKey] = nil return true end
    local old = db.announcements[record.id]
    if old and (tonumber(old.revision) or 0) >= (tonumber(record.revision) or 0) then db.pendingAnnouncements[pendingKey] = nil return true end
    record.reactions = old and old.reactions or {}
    record.verified = true
    db.announcements[record.id] = record
    S152PruneAnnouncements(db)
    db.pendingAnnouncements[pendingKey] = nil
    self:AddUsefulActivity152("ANNOUNCEMENT", "New leadership post: " .. record.title, record.author, "home", record.updatedAt)
    if record.notifyFlag then
        local priority = record.importance == "CRITICAL" and "CRITICAL" or "IMPORTANT"
        self:NotifyEvent152("announcement", "ANN:" .. record.id .. ":" .. tostring(record.revision), record.title, "New post from " .. (record.author or "Leadership"), priority, true)
    end
    if self.OnAnnouncementDataChanged152 then self:OnAnnouncementDataChanged152(true) end
    return true
end

function OTLGM:HandleAnnouncementMessage152(message, channel, sender)
    if string.sub(message or "",1,3)~=self.announcementProtocol.."^" then return false end
    local fields=S152Split(message,"^")
    local kind=fields[2]
    local cleanupDB=self:GetGuildDB()
    S152PrunePendingAnnouncements(cleanupDB,self:Now())
    if kind=="SYNC" then
        if sender and S152NormalizeName(sender)~=S152NormalizeName(UnitName("player") or "") then self:ScheduleAnnouncementState155(sender) end
        return true
    end
    if kind=="DEL" then
        if not self:IsAnnouncementSenderAllowed152(sender) then
            if cleanupDB and cleanupDB.announcementSync then cleanupDB.announcementSync.rejected=(cleanupDB.announcementSync.rejected or 0)+1 end
            return false
        end
        local id,revision=fields[3] or "",tonumber(fields[4]) or 0
        if not S152ValidID(id) then return false end
        local db=self:GetGuildDB(); local old=db.announcements[id]
        if old and (tonumber(old.revision) or 0)>revision then return true end
        db.announcements[id]=nil; db.announcementDeleted[id]={revision=revision,ts=self:Now()}
        if self.OnAnnouncementDataChanged152 then self:OnAnnouncementDataChanged152(true) end
        return true
    end
    if kind~="META" and kind~="BODY" then return false end
    local id,revision=fields[3] or "",tonumber(fields[4]) or 0
    if not S152ValidID(id) or revision<1 then return false end
    local pendingKey=S152NormalizeName(sender)..":"..id..":"..tostring(revision)
    local db=self:GetGuildDB(); local pending=db.pendingAnnouncements[pendingKey]
    if not pending then pending={id=id,revision=revision,sender=sender,created=self:Now(),ts=self:Now(),chunks={},total=0} db.pendingAnnouncements[pendingKey]=pending end
    if kind=="META" then
        local author=S152Unescape(fields[7] or "")
        local total=tonumber(fields[12]) or 0
        if author=="" or total<1 or total>ANNOUNCEMENT_MAX_CHUNKS then return false end
        -- Relays are allowed, but the original author still has to be a known
        -- leadership member. This keeps announcements available when the author
        -- logs out without tying delivery to rank names on the relay character.
        local authorAllowed=self:IsAnnouncementSenderAllowed152(author)
        local senderAllowed=self:IsAnnouncementSenderAllowed152(sender)
        local transmittedRankIndex=tonumber(fields[13]) or 99
        if authorAllowed~=true and senderAllowed~=true and transmittedRankIndex>2 then
            db.pendingAnnouncements[pendingKey]=nil
            db.announcementSync=db.announcementSync or {}; db.announcementSync.rejected=(db.announcementSync.rejected or 0)+1
            return false
        end
        pending.total=total
        local importance=S152Unescape(fields[8] or "NORMAL")
        pending.meta={id=id,revision=revision,createdAt=tonumber(fields[5]) or self:Now(),updatedAt=tonumber(fields[6]) or self:Now(),
            author=S152Safe(author,28,false),authorRankIndex=transmittedRankIndex,importance=importance,notifyFlag=fields[9]=="1",pinned=fields[10]=="1",archived=fields[11]=="1",
            category=S152Safe(S152Unescape(fields[14] or ""),16,false),requiresAck=fields[15]=="1",verified=true}
        if pending.meta.category=="" then pending.meta.category=importance=="CRITICAL" and "URGENT" or (importance=="IMPORTANT" and "IMPORTANT" or "GUILD POST") end
        if fields[15]==nil then pending.meta.requiresAck=importance=="CRITICAL" end
    else
        local sequence,total=tonumber(fields[5]) or 0,tonumber(fields[6]) or 0
        if sequence<1 or total<1 or sequence>total or total>ANNOUNCEMENT_MAX_CHUNKS then return false end
        if pending.total~=0 and pending.total~=total then return false end
        pending.total=total; pending.chunks[sequence]=fields[7] or ""
    end
    self:TryFinishAnnouncement152(pendingKey)
    return true
end

function OTLGM:OnAnnouncementDataChanged152(remote)
    if self.ui and self.ui.main and self.ui.main:IsVisible() then
        if self.ui.currentPage == "home" and self.RefreshHomePage then self:RefreshHomePage() end
        if self.ui.currentPage == "search" and self.RefreshSearchPage then self:RefreshSearchPage(true) end
        if self.RefreshNavigation then self:RefreshNavigation() end
    end
end

function OTLGM:HandleAnnouncementsAddonMessageLegacy(prefix, message, channel, sender)
    if prefix == "OTLGM" and string.sub(message or "", 1, 3) == self.announcementProtocol .. "^" then
        if self.RememberAddonUser then self:RememberAddonUser(sender, nil) end
        return self:HandleAnnouncementMessage152(message, channel, sender)
    end
    return BaseHandleAddonMessage152(self, prefix, message, channel, sender)
end

function OTLGM:CreatePveRequest(kind, role, activity, note, maxSize, needTank, needHeal, needDps)
    local ok, result = BaseCreatePveRequest152(self, kind, role, activity, note, maxSize, needTank, needHeal, needDps)
    if ok and result then self:AddUsefulActivity152("GROUP", "New group: " .. (result.activity or "Guild group"), "Leader: " .. (result.author or UnitName("player") or "Unknown"), "pve", result.ts) end
    return ok, result
end

function OTLGM:ApplyRemotePveRequest(fields)
    local pve = self:EnsurePveDB()
    local id = fields and fields[3] or ""
    local old = pve and pve.requests and pve.requests[id]
    local result = BaseApplyRemotePveRequest152(self, fields)
    local record = pve and pve.requests and pve.requests[id]
    if result and record and not old then
        self:AddUsefulActivity152("GROUP", "New group: " .. (record.activity or "Guild group"), "Leader: " .. (record.author or "Unknown"), "pve", record.ts)
        self:NotifyEvent152("group", "GROUP:" .. id .. ":" .. tostring(record.rev or 1), "New guild group", (record.activity or "Group") .. " - " .. (record.author or "Unknown"), "IMPORTANT", true)
    end
    return result
end

function OTLGM:ApplyRemotePveApplication(fields, sender)
    local pve = self:EnsurePveDB()
    local id = fields and fields[3] or ""
    local old = pve and pve.applications and pve.applications[id]
    local result = BaseApplyRemotePveApplication152(self, fields, sender)
    local record = pve and pve.applications and pve.applications[id]
    if result and record and (not old or old.status ~= record.status) then
        local player = S152NormalizeName(UnitName("player") or "")
        local group = pve.requests and pve.requests[record.groupId]
        local relevant = S152NormalizeName(record.author) == player or (group and S152NormalizeName(group.author) == player)
        if relevant then self:NotifyEvent152("response", "APP:" .. id .. ":" .. tostring(record.rev or 1), "Group Finder response", (record.author or "A guild member") .. " - " .. (record.status or "PENDING"), "ACTION", true, "pve") end
    end
    return result
end

function OTLGM:_Stage_Systems152_ApplyRemotePveRaid_2(fields)
    local pve = self:EnsurePveDB()
    local oldRev = pve and pve.raid and tonumber(pve.raid.rev) or 0
    local result = BaseApplyRemotePveRaid152(self, fields)
    local raid = pve and pve.raid
    if result and raid and (tonumber(raid.rev) or 0) > oldRev then
        self:AddUsefulActivity152("RAID", "Raid notice: " .. (raid.name or "Guild raid"), raid.serverTime or "Time TBA", "pve", raid.ts)
        self:NotifyEvent152("raid", "RAID:" .. tostring(raid.id) .. ":" .. tostring(raid.rev or 1), raid.name or "Guild raid", (raid.serverTime or "Time TBA") .. " - official sign-up remains in Discord.", "IMPORTANT", true)
    end
    return result
end

function OTLGM:CreateCraftingRequest(kind, item, materials, note)
    local ok, result = BaseCreateCraftingRequest152(self, kind, item, materials, note)
    if ok and result then self:AddUsefulActivity152("CRAFT", "Crafting request: " .. (result.item or "Guild service"), "Posted by " .. (result.author or UnitName("player") or "Unknown"), "professions", result.ts) end
    return ok, result
end

function OTLGM:ApplyRemoteCraftingRequest(fields, sender, channel)
    local craft = self:EnsureCraftingDB()
    local id = fields and fields[3] or ""
    local old = craft and craft.requests and craft.requests[id]
    local result = BaseApplyRemoteCraftingRequest152(self, fields, sender, channel)
    local record = craft and craft.requests and craft.requests[id]
    if result and record and not old then
        self:AddUsefulActivity152("CRAFT", "Crafting request: " .. (record.item or "Guild service"), "Posted by " .. (record.author or "Unknown"), "professions", record.ts)
        self:NotifyEvent152("crafting", "CRAFT:" .. id .. ":" .. tostring(record.rev or 1), "New crafting request", (record.item or "Guild service") .. " - " .. (record.author or "Unknown"), "INFO", true)
    end
    return result
end

function OTLGM:ApplyRemoteCraftingResponse(fields, sender, channel)
    local craft = self:EnsureCraftingDB()
    local id = fields and fields[3] or ""
    local old = craft and craft.responses and craft.responses[id]
    local result = BaseApplyRemoteCraftingResponse152(self, fields, sender, channel)
    local record = craft and craft.responses and craft.responses[id]
    if result and record and not old then
        local request = craft.requests and craft.requests[record.requestId]
        self:AddUsefulActivity152("RESPONSE", (record.author or "A guild member") .. (record.canHelp and " can help" or " replied"), request and request.item or record.text, "professions", record.ts)
        if request and S152NormalizeName(request.author) == S152NormalizeName(UnitName("player") or "") then
            self:NotifyEvent152("response", "CRES:" .. id .. ":" .. tostring(record.rev or 1), "Response to your crafting request", (record.author or "A guild member") .. (record.canHelp and " can help." or " replied."), "ACTION", true, "professions")
        end
    end
    return result
end

local function S152ReactionOwner(self, targetType, targetId)
    if targetType == "ANN" then local record = self:GetAnnouncement152(targetId) return record and record.author end
    if targetType == "CRAFT" then local record = self:GetCraftingRequestByID(targetId) return record and record.author end
    if targetType == "BOARD" then local pve = self:EnsurePveDB() local record = pve and pve.board and pve.board[targetId] return record and record.author end
    return nil
end

function OTLGM:ApplyRemoteReaction(fields, sender, channel)
    local targetType = fields and S152Unescape(fields[3] or "") or ""
    local targetId = fields and S152Unescape(fields[4] or "") or ""
    local author = fields and S152Unescape(fields[5] or "") or ""
    local result = BaseApplyRemoteReaction152(self, fields, sender, channel)
    if result and targetId ~= "" and author ~= "" then
        local owner = S152ReactionOwner(self, targetType, targetId)
        if owner and S152NormalizeName(owner) == S152NormalizeName(UnitName("player") or "") and S152NormalizeName(author) ~= S152NormalizeName(owner) then
            local reactionPage = targetType == "CRAFT" and "professions" or targetType == "RAID" and "pve" or "home"
            self:NotifyEvent152("reaction", "REACT:" .. targetType .. ":" .. targetId .. ":" .. S152NormalizeName(author) .. ":" .. tostring(fields[7] or "0"), "New reaction", author .. " reacted to your post.", "INFO", true, reactionPage)
            self:AddUsefulActivity152("REACTION", author .. " reacted to your post", targetType .. " reaction", targetType == "CRAFT" and "professions" or "home", self:Now())
        end
    end
    return result
end

function OTLGM:OnPveDataChanged(section, remote)
    if BaseOnPveDataChanged152 then BaseOnPveDataChanged152(self, section, remote) end
end

function OTLGM:_Stage_Systems152_OnCraftingDataChanged_2(section, remote)
    if BaseOnCraftingDataChanged152 then BaseOnCraftingDataChanged152(self, section, remote) end
end

function OTLGM:_Stage_Systems152_GetDiagnosticsText_2()
    local base = BaseGetDiagnosticsText152 and BaseGetDiagnosticsText152(self) or ""
    local db = self:GetGuildDB()
    local worldDisplay = self.GetWorldChannelDisplay153 and self:GetWorldChannelDisplay153() or "Unavailable"
    local activityCount = db and db.recentUsefulActivity and table.getn(db.recentUsefulActivity) or 0
    local settings = OTLGM_DB and OTLGM_DB.settings or {}
    local pve = self.EnsurePveDB and self:EnsurePveDB() or nil
    local craft = self.EnsureCraftingDB and self:EnsureCraftingDB() or nil
    local raidCount = 0
    local _
    for _ in pairs(pve and pve.raids or {}) do raidCount = raidCount + 1 end
    return base ..
        "\nSchema version: " .. tostring(db and db.schemaVersion or 0) ..
        "\nAnnouncements: " .. tostring(S152Count(db and db.announcements)) ..
        "\nAnnouncement unread: " .. tostring(self:GetAnnouncementUnreadCount154()) ..
        "\nAnnouncement sync received/rejected: " .. tostring(db and db.announcementSync and db.announcementSync.received or 0) .. "/" .. tostring(db and db.announcementSync and db.announcementSync.rejected or 0) ..
        "\nNotification records: " .. tostring(S152Count(db and db.notificationSeen)) ..
        "\nUseful activity records: " .. tostring(activityCount) ..
        "\nScheduled raid events: " .. tostring(raidCount) ..
        "\nCrafting sync active/received: " .. tostring(craft and craft.syncState and craft.syncState.active and "yes" or "no") .. "/" .. tostring(craft and craft.syncState and craft.syncState.received or 0) ..
        "\nWorld channel: " .. tostring(worldDisplay) ..
        "\nProfession category filter: " .. tostring(settings.craftingCategory153 or "ALL") ..
        "\nProfession level filter: " .. tostring(settings.craftingLevelFilter153 or "ANY") ..
        "\nProfession rarity filter: " .. tostring(settings.craftingRarityFilter153 or "ANY") ..
        "\nSystems layer: Loaded" ..
        "\nUI layer: " .. tostring(self.ui153Loaded and "Loaded" or "Not built yet")
end

OTLGM:RegisterModule("Community", { layer = "feature", protocol = OTLGM.announcementProtocol })
