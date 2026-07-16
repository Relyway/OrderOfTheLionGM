-- Order of the Lion Guild Manager
-- Lightweight guild-to-guild PvE synchronization for Vanilla WoW / OctoWoW - v1.4.1

OTLGM.pveProtocol = "P1"
OTLGM.pveRequestLifetime = 3600
OTLGM.pveBoardLifetime = 172800

local function PveTrim(text)
    text = text or ""
    return string.gsub(text, "^%s*(.-)%s*$", "%1")
end

local function PveNormalizeName(name)
    name = PveTrim(name or "")
    name = string.gsub(name, "%-.*$", "")
    return string.lower(name)
end

local function PveSafeText(text, maxLength)
    text = PveTrim(text or "")
    text = string.gsub(text, "[\r\n\t]", " ")
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "%^", "'")
    text = string.gsub(text, "|", "/")
    if maxLength and string.len(text) > maxLength then text = string.sub(text, 1, maxLength) end
    return text
end

local function PveSplit(text)
    local fields = {}
    local startAt = 1
    while true do
        local delimiter = string.find(text, "^", startAt, true)
        if not delimiter then
            table.insert(fields, string.sub(text, startAt))
            break
        end
        table.insert(fields, string.sub(text, startAt, delimiter - 1))
        startAt = delimiter + 1
    end
    return fields
end

local function PveCopyRecord(record)
    local copy = {}
    local key, value
    for key, value in pairs(record or {}) do copy[key] = value end
    return copy
end

local function PveSortedValues(map, comparator)
    local list = {}
    local key, value
    for key, value in pairs(map or {}) do table.insert(list, value) end
    table.sort(list, comparator)
    return list
end

function OTLGM:EnsurePveDB()
    self:EnsureDB()
    local db = self:GetGuildDB()
    if not db then return nil end
    db.pve = db.pve or {}
    db.pve.requests = db.pve.requests or {}
    db.pve.board = db.pve.board or {}
    db.pve.applications = db.pve.applications or {}
    db.pve.deleted = db.pve.deleted or {}
    db.pve.unread = db.pve.unread or { RAIDS = 0, GROUPS = 0, BOARD = 0 }
    db.pve.reminded = db.pve.reminded or {}
    db.pve.lastSync = db.pve.lastSync or 0

    OTLGM_DB.settings.pveSection = OTLGM_DB.settings.pveSection or "RAIDS"
    OTLGM_DB.settings.pveRequestKind = OTLGM_DB.settings.pveRequestKind or "DUNGEON"
    OTLGM_DB.settings.pveRequestRole = OTLGM_DB.settings.pveRequestRole or "ANY"
    OTLGM_DB.settings.pveJoinRole = OTLGM_DB.settings.pveJoinRole or "DPS"
    OTLGM_DB.settings.pveGroupSize = OTLGM_DB.settings.pveGroupSize or "5"
    OTLGM_DB.settings.pveNeedTank = OTLGM_DB.settings.pveNeedTank or "1"
    OTLGM_DB.settings.pveNeedHeal = OTLGM_DB.settings.pveNeedHeal or "1"
    OTLGM_DB.settings.pveNeedDps = OTLGM_DB.settings.pveNeedDps or "3"
    if OTLGM_DB.settings.pveRaidPopups == nil then OTLGM_DB.settings.pveRaidPopups = true end
    if OTLGM_DB.settings.pveRaidChatLine == nil then OTLGM_DB.settings.pveRaidChatLine = true end
    return db.pve
end

function OTLGM:PurgePveData(silent)
    local pve = self:EnsurePveDB()
    if not pve then return false end
    local now = self:Now()
    local changed = false
    local id, record
    for id, record in pairs(pve.requests) do
        if not record.expires or record.expires <= now then
            pve.requests[id] = nil
            changed = true
        end
    end
    for id, record in pairs(pve.board) do
        if not record.expires or record.expires <= now then
            pve.board[id] = nil
            changed = true
        end
    end
    for id, record in pairs(pve.applications or {}) do
        if not record.expires or record.expires <= now or (record.groupId and not pve.requests[record.groupId] and record.status == "PENDING") then
            pve.applications[id] = nil
            changed = true
        end
    end
    if pve.raid and pve.raid.startTs and pve.raid.startTs + 14400 <= now then
        pve.raid = nil
        changed = true
    end
    for id, record in pairs(pve.deleted) do
        if not record.ts or record.ts + 86400 <= now then pve.deleted[id] = nil end
    end
    if changed and not silent then self:OnPveDataChanged(nil, false) end
    return changed
end

function OTLGM:GetPveRequests()
    local pve = self:EnsurePveDB()
    if not pve then return {} end
    self:PurgePveData(true)
    return PveSortedValues(pve.requests, function(a, b)
        local at = tonumber(a.ts) or 0
        local bt = tonumber(b.ts) or 0
        if at ~= bt then return at > bt end
        return string.lower(a.author or "") < string.lower(b.author or "")
    end)
end

function OTLGM:GetPveApplications(groupId, pendingOnly)
    local pve = self:EnsurePveDB()
    if not pve then return {} end
    self:PurgePveData(true)
    local result = {}
    local id, record
    for id, record in pairs(pve.applications or {}) do
        if (not groupId or record.groupId == groupId) and (not pendingOnly or record.status == "PENDING") then
            table.insert(result, record)
        end
    end
    table.sort(result, function(a, b)
        local at = tonumber(a.ts) or 0
        local bt = tonumber(b.ts) or 0
        if at ~= bt then return at > bt end
        return string.lower(a.author or "") < string.lower(b.author or "")
    end)
    return result
end

function OTLGM:GetPveApplicationByID(id)
    local pve = self:EnsurePveDB()
    return pve and pve.applications and pve.applications[id] or nil
end

function OTLGM:GetOwnPveApplication(groupId)
    local player = PveNormalizeName(UnitName("player") or "")
    local list = self:GetPveApplications(groupId, false)
    local i
    for i = 1, table.getn(list) do
        if PveNormalizeName(list[i].author) == player then return list[i] end
    end
    return nil
end

function OTLGM:GetPendingPveApplicationCount()
    local player = PveNormalizeName(UnitName("player") or "")
    local total = 0
    local requests = self:GetPveRequests()
    local ownGroups = {}
    local i
    for i = 1, table.getn(requests) do
        if PveNormalizeName(requests[i].author) == player then ownGroups[requests[i].id] = true end
    end
    local apps = self:GetPveApplications(nil, true)
    for i = 1, table.getn(apps) do
        if ownGroups[apps[i].groupId] then total = total + 1 end
    end
    return total
end

function OTLGM:IsOwnPveGroup(record)
    if not record then return false end
    return PveNormalizeName(record.author) == PveNormalizeName(UnitName("player") or "")
end

function OTLGM:GetPveGroupStatus(record)
    if not record then return "CLOSED" end
    if record.status == "CLOSED" then return "CLOSED" end
    local maxSize = math.max(2, tonumber(record.maxSize) or 5)
    local current = math.max(1, tonumber(record.current) or 1)
    local needed = math.max(0, tonumber(record.needTank) or 0) + math.max(0, tonumber(record.needHeal) or 0) + math.max(0, tonumber(record.needDps) or 0)
    if current >= maxSize or needed <= 0 then return "FULL" end
    return record.status or "OPEN"
end

function OTLGM:GetPveBoardPosts()
    local pve = self:EnsurePveDB()
    if not pve then return {} end
    self:PurgePveData(true)
    return PveSortedValues(pve.board, function(a, b)
        local at = tonumber(a.ts) or 0
        local bt = tonumber(b.ts) or 0
        if at ~= bt then return at > bt end
        return string.lower(a.author or "") < string.lower(b.author or "")
    end)
end

function OTLGM:GetPveActiveRaid()
    local pve = self:EnsurePveDB()
    if not pve then return nil end
    self:PurgePveData(true)
    return pve.raid
end

function OTLGM:GetPveSummary()
    local requests = self:GetPveRequests()
    local board = self:GetPveBoardPosts()
    local raid = self:GetPveActiveRaid()
    local kinds = { DUNGEON = 0, QUEST = 0, FARM = 0, ATTUNE = 0, OTHER = 0 }
    local i, request
    for i = 1, table.getn(requests) do
        request = requests[i]
        kinds[request.kind or "OTHER"] = (kinds[request.kind or "OTHER"] or 0) + 1
    end
    return {
        requests = table.getn(requests),
        board = table.getn(board),
        raid = raid,
        kinds = kinds,
        pending = self:GetPendingPveApplicationCount(),
    }
end

function OTLGM:GetPveUnread(section)
    local pve = self:EnsurePveDB()
    if not pve then return 0 end
    return tonumber(pve.unread[section or "RAIDS"]) or 0
end

function OTLGM:GetPveUnreadTotal()
    return self:GetPveUnread("RAIDS") + self:GetPveUnread("GROUPS") + self:GetPveUnread("BOARD")
end

function OTLGM:IsPveSectionVisible(section)
    if not self.ui or not self.ui.main or not self.ui.main:IsVisible() then return false end
    if self.ui.currentPage ~= "pve" then return false end
    return (OTLGM_DB.settings.pveSection or "RAIDS") == section
end

function OTLGM:MarkPveSectionRead(section)
    local pve = self:EnsurePveDB()
    if not pve then return end
    pve.unread[section] = 0
    if self.RefreshPveNavigationBadge then self:RefreshPveNavigationBadge() end
end

function OTLGM:IncrementPveUnread(section)
    local pve = self:EnsurePveDB()
    if not pve or self:IsPveSectionVisible(section) then return end
    pve.unread[section] = (tonumber(pve.unread[section]) or 0) + 1
end

function OTLGM:MakePveID(prefix)
    self.pveSequence = (self.pveSequence or 0) + 1
    local player = UnitName("player") or "Player"
    player = string.gsub(player, "[^%a%d]", "")
    if player == "" then player = "Player" end
    return (prefix or "X") .. tostring(self:Now()) .. tostring(self.pveSequence) .. player
end

function OTLGM:QueuePvePayload(payload, channel, target)
    if not payload or payload == "" then return false end
    self.pveSendQueue = self.pveSendQueue or {}
    if table.getn(self.pveSendQueue) >= 80 then table.remove(self.pveSendQueue, 1) end
    table.insert(self.pveSendQueue, { payload = payload, channel = channel or "GUILD", target = target })
    return true
end

function OTLGM:ProcessPveSendQueue()
    if not SendAddonMessage or not self.pveSendQueue or table.getn(self.pveSendQueue) == 0 then return end
    local item = table.remove(self.pveSendQueue, 1)
    if not item then return end
    pcall(SendAddonMessage, "OTLGM", item.payload, item.channel or "GUILD", item.target)
end

function OTLGM:SerializePveRequest(record)
    return table.concat({
        self.pveProtocol, "REQ", record.id, tostring(record.rev or 1), tostring(record.ts or 0), tostring(record.expires or 0),
        PveSafeText(record.author, 20), tostring(record.level or 0), PveSafeText(record.class, 16), PveSafeText(record.kind, 10),
        PveSafeText(record.role, 10), PveSafeText(record.activity, 36), PveSafeText(record.note, 52),
        tostring(record.maxSize or 5), tostring(record.current or 1), tostring(record.needTank or 0), tostring(record.needHeal or 0),
        tostring(record.needDps or 0), PveSafeText(record.status or "OPEN", 8)
    }, "^")
end

function OTLGM:SerializePveApplication(record)
    return table.concat({
        self.pveProtocol, "APP", record.id, PveSafeText(record.groupId, 36), tostring(record.rev or 1),
        tostring(record.ts or 0), tostring(record.expires or 0), PveSafeText(record.leader, 20), PveSafeText(record.author, 20),
        tostring(record.level or 0), PveSafeText(record.class, 16), PveSafeText(record.role, 10),
        PveSafeText(record.status or "PENDING", 10), PveSafeText(record.note, 44)
    }, "^")
end

function OTLGM:SerializePveBoard(record)
    return table.concat({ self.pveProtocol, "BOARD", record.id, tostring(record.rev or 1), tostring(record.ts or 0), tostring(record.expires or 0), PveSafeText(record.author, 20), tostring(record.level or 0), PveSafeText(record.class, 16), PveSafeText(record.text, 130) }, "^")
end

function OTLGM:SerializePveRaid(record)
    return table.concat({ self.pveProtocol, "RAID", record.id, tostring(record.rev or 1), tostring(record.ts or 0), tostring(record.startTs or 0), PveSafeText(record.author, 20), PveSafeText(record.name, 36), PveSafeText(record.location, 32), PveSafeText(record.serverTime, 28), PveSafeText(record.note, 72) }, "^")
end

function OTLGM:GetPveRecordRevision(id)
    local pve = self:EnsurePveDB()
    if not pve then return 0 end
    if pve.requests[id] then return tonumber(pve.requests[id].rev) or 0 end
    if pve.board[id] then return tonumber(pve.board[id].rev) or 0 end
    if pve.raid and pve.raid.id == id then return tonumber(pve.raid.rev) or 0 end
    if pve.deleted[id] then return tonumber(pve.deleted[id].rev) or 0 end
    return 0
end

function OTLGM:IsPveLeadershipName(name)
    if not name or name == "" then return false end
    local member = self:GetMember(name)
    if not member then return nil end
    return self:IsLeadership(member)
end

function OTLGM:CanModifyPveRecord(record)
    if not record then return false end
    local player = UnitName("player") or ""
    if PveNormalizeName(record.author) == PveNormalizeName(player) then return true end
    return self.IsOfficerMode and self:IsOfficerMode()
end

function OTLGM:CreatePveRequest(kind, role, activity, note, maxSize, needTank, needHeal, needDps)
    local pve = self:EnsurePveDB()
    if not pve then return false, "Guild data is not ready." end
    activity = PveSafeText(activity, 36)
    note = PveSafeText(note, 52)
    kind = PveSafeText(kind or "DUNGEON", 10)
    role = PveSafeText(role or "ANY", 10)
    if activity == "" then return false, "Enter a dungeon, quest or activity." end

    maxSize = math.max(2, math.min(40, tonumber(maxSize) or 5))
    needTank = math.max(0, math.min(maxSize, tonumber(needTank) or 0))
    needHeal = math.max(0, math.min(maxSize, tonumber(needHeal) or 0))
    needDps = math.max(0, math.min(maxSize, tonumber(needDps) or 0))
    local openSlots = math.max(1, maxSize - 1)
    if needTank + needHeal + needDps <= 0 then
        if role == "TANK" then needTank, needHeal, needDps = 0, 1, math.max(0, openSlots - 1)
        elseif role == "HEAL" then needTank, needHeal, needDps = 1, 0, math.max(0, openSlots - 1)
        elseif role == "DPS" then needTank, needHeal, needDps = 1, 1, math.max(0, openSlots - 2)
        else needTank, needHeal, needDps = 1, 1, math.max(0, openSlots - 2) end
    end
    while needTank + needHeal + needDps > openSlots do
        if needDps > 0 then needDps = needDps - 1
        elseif needHeal > 0 then needHeal = needHeal - 1
        elseif needTank > 0 then needTank = needTank - 1 end
    end

    local player = UnitName("player") or "Unknown"
    local existing = self:GetPveRequests()
    local i
    for i = 1, table.getn(existing) do
        if PveNormalizeName(existing[i].author) == PveNormalizeName(player) then self:DeletePveRequest(existing[i].id, true) end
    end

    local _, classToken = UnitClass("player")
    local record = {
        id = self:MakePveID("Q"), rev = 1, ts = self:Now(), expires = self:Now() + self.pveRequestLifetime,
        author = player, level = UnitLevel("player") or 0, class = classToken or "",
        kind = kind, role = role, activity = activity, note = note,
        maxSize = maxSize, current = 1, needTank = needTank, needHeal = needHeal, needDps = needDps, status = "OPEN",
    }
    pve.requests[record.id] = record
    self:QueuePvePayload(self:SerializePveRequest(record), "GUILD")
    self:OnPveDataChanged("GROUPS", false)
    return true, record
end

function OTLGM:ApplyToPveGroup(groupId, role, note)
    local pve = self:EnsurePveDB()
    local group = pve and pve.requests[groupId]
    if not group then return false, "This group request is no longer available." end
    if self:IsOwnPveGroup(group) then return false, "You are the leader of this group." end
    if self:GetPveGroupStatus(group) ~= "OPEN" then return false, "This group is no longer open." end
    role = PveSafeText(role or "DPS", 10)
    note = PveSafeText(note, 44)
    local player = UnitName("player") or "Unknown"
    local existing = self:GetOwnPveApplication(groupId)
    if existing and existing.status == "PENDING" then return false, "Your request is already waiting for the leader." end
    if existing and existing.status == "ACCEPTED" then return false, "You were already accepted into this group." end
    local _, classToken = UnitClass("player")
    local record = {
        id = existing and existing.id or self:MakePveID("A"), groupId = groupId,
        rev = existing and ((tonumber(existing.rev) or 0) + 1) or 1,
        ts = self:Now(), expires = math.min(group.expires or (self:Now() + self.pveRequestLifetime), self:Now() + self.pveRequestLifetime),
        leader = group.author, author = player, level = UnitLevel("player") or 0, class = classToken or "",
        role = role, note = note, status = "PENDING",
    }
    pve.applications[record.id] = record
    self:QueuePvePayload(self:SerializePveApplication(record), "WHISPER", group.author)
    self:OnPveDataChanged("GROUPS", false)
    return true, record
end

function OTLGM:UpdatePveApplication(applicationId, status)
    local pve = self:EnsurePveDB()
    local application = pve and pve.applications[applicationId]
    if not application then return false, "Application not found." end
    local group = pve.requests[application.groupId]
    if not group or not self:IsOwnPveGroup(group) then return false, "Only the group leader can manage this application." end
    if application.status ~= "PENDING" then return false, "This application was already handled." end
    status = status == "ACCEPTED" and "ACCEPTED" or "DECLINED"
    application.status = status
    application.rev = (tonumber(application.rev) or 0) + 1
    application.ts = self:Now()

    if status == "ACCEPTED" then
        group.current = math.min(tonumber(group.maxSize) or 5, (tonumber(group.current) or 1) + 1)
        if application.role == "TANK" and (tonumber(group.needTank) or 0) > 0 then group.needTank = group.needTank - 1
        elseif application.role == "HEAL" and (tonumber(group.needHeal) or 0) > 0 then group.needHeal = group.needHeal - 1
        elseif application.role == "DPS" and (tonumber(group.needDps) or 0) > 0 then group.needDps = group.needDps - 1
        elseif (tonumber(group.needDps) or 0) > 0 then group.needDps = group.needDps - 1
        elseif (tonumber(group.needHeal) or 0) > 0 then group.needHeal = group.needHeal - 1
        elseif (tonumber(group.needTank) or 0) > 0 then group.needTank = group.needTank - 1 end
        group.status = self:GetPveGroupStatus(group)
        group.rev = (tonumber(group.rev) or 0) + 1
        group.ts = self:Now()
        self:QueuePvePayload(self:SerializePveRequest(group), "GUILD")
        if InviteByName then pcall(InviteByName, string.gsub(application.author or "", "%-.*$", "")) end
    end

    self:QueuePvePayload(self:SerializePveApplication(application), "WHISPER", application.author)
    self:OnPveDataChanged("GROUPS", false)
    return true, application
end

function OTLGM:CancelPveApplication(applicationId)
    local pve = self:EnsurePveDB()
    local application = pve and pve.applications[applicationId]
    if not application then return false end
    if PveNormalizeName(application.author) ~= PveNormalizeName(UnitName("player") or "") then return false end
    application.status = "CANCELLED"
    application.rev = (tonumber(application.rev) or 0) + 1
    application.ts = self:Now()
    self:QueuePvePayload(self:SerializePveApplication(application), "WHISPER", application.leader)
    self:OnPveDataChanged("GROUPS", false)
    return true
end

function OTLGM:DeletePveRequest(id, quiet)
    local pve = self:EnsurePveDB()
    local record = pve and pve.requests[id]
    if not record then return false end
    if not self:CanModifyPveRecord(record) then return false end
    local rev = (tonumber(record.rev) or 0) + 1
    pve.requests[id] = nil
    local appId, application
    for appId, application in pairs(pve.applications or {}) do
        if application.groupId == id then pve.applications[appId] = nil end
    end
    pve.deleted[id] = { rev = rev, ts = self:Now() }
    self:QueuePvePayload(table.concat({ self.pveProtocol, "REQDEL", id, tostring(rev) }, "^"), "GUILD")
    if not quiet then self:OnPveDataChanged("GROUPS", false) end
    return true
end

function OTLGM:CreatePveBoardPost(text)
    local pve = self:EnsurePveDB()
    if not pve then return false, "Guild data is not ready." end
    text = PveSafeText(text, 130)
    if text == "" then return false, "Write a short message first." end
    if self.lastPveBoardPostAt and self:Now() - self.lastPveBoardPostAt < 20 then return false, "Please wait before posting again." end

    local player = UnitName("player") or "Unknown"
    local own = {}
    local id, post
    for id, post in pairs(pve.board) do
        if PveNormalizeName(post.author) == PveNormalizeName(player) then table.insert(own, post) end
    end
    table.sort(own, function(a, b) return (a.ts or 0) < (b.ts or 0) end)
    while table.getn(own) >= 3 do
        self:DeletePveBoardPost(own[1].id, true)
        table.remove(own, 1)
    end

    local _, classToken = UnitClass("player")
    local record = {
        id = self:MakePveID("B"), rev = 1, ts = self:Now(), expires = self:Now() + self.pveBoardLifetime,
        author = player, level = UnitLevel("player") or 0, class = classToken or "", text = text,
    }
    pve.board[record.id] = record
    self.lastPveBoardPostAt = self:Now()
    self:QueuePvePayload(self:SerializePveBoard(record), "GUILD")
    self:OnPveDataChanged("BOARD", false)
    return true, record
end

function OTLGM:DeletePveBoardPost(id, quiet)
    local pve = self:EnsurePveDB()
    local record = pve and pve.board[id]
    if not record then return false end
    if not self:CanModifyPveRecord(record) then return false end
    local rev = (tonumber(record.rev) or 0) + 1
    pve.board[id] = nil
    pve.deleted[id] = { rev = rev, ts = self:Now() }
    self:QueuePvePayload(table.concat({ self.pveProtocol, "BOARDDEL", id, tostring(rev) }, "^"), "GUILD")
    if not quiet then self:OnPveDataChanged("BOARD", false) end
    return true
end

function OTLGM:GetPveServerTimeLabel(minutes)
    minutes = math.max(0, tonumber(minutes) or 0)
    local hour, minute
    if GetGameTime then hour, minute = GetGameTime() end
    if not hour then
        hour = tonumber(date("%H", self:Now())) or 0
        minute = tonumber(date("%M", self:Now())) or 0
    end
    local total = (hour * 60) + minute + minutes
    local dayOffset = math.floor(total / 1440)
    total = math.mod(total, 1440)
    local h = math.floor(total / 60)
    local m = math.mod(total, 60)
    local prefix = dayOffset == 0 and "Today" or (dayOffset == 1 and "Tomorrow" or ("+" .. tostring(dayOffset) .. "d"))
    return prefix .. " " .. string.format("%02d:%02d", h, m) .. " ST"
end

function OTLGM:PublishPveRaid(name, location, minutes, note)
    if not self.IsOfficerMode or not self:IsOfficerMode() then return false, "Only leadership can publish guild raid notices." end
    local pve = self:EnsurePveDB()
    if not pve then return false, "Guild data is not ready." end
    name = PveSafeText(name, 36)
    location = PveSafeText(location, 32)
    note = PveSafeText(note, 72)
    minutes = tonumber(minutes) or 60
    if minutes < 0 then minutes = 0 end
    if minutes > 10080 then minutes = 10080 end
    if name == "" then return false, "Enter the raid name." end

    local player = UnitName("player") or "Unknown"
    local existing = pve.raid
    local record = {
        id = existing and existing.id or self:MakePveID("R"),
        rev = existing and ((tonumber(existing.rev) or 0) + 1) or 1,
        ts = self:Now(), startTs = self:Now() + (minutes * 60), author = player,
        name = name, location = location, note = note, serverTime = self:GetPveServerTimeLabel(minutes),
    }
    pve.raid = record
    pve.reminded[record.id] = {}
    self:QueuePvePayload(self:SerializePveRaid(record), "GUILD")
    self:OnPveDataChanged("RAIDS", false)
    return true, record
end

function OTLGM:ClearPveRaid()
    if not self.IsOfficerMode or not self:IsOfficerMode() then return false end
    local pve = self:EnsurePveDB()
    local raid = pve and pve.raid
    if not raid then return false end
    local rev = (tonumber(raid.rev) or 0) + 1
    local id = raid.id
    pve.raid = nil
    pve.deleted[id] = { rev = rev, ts = self:Now() }
    self:QueuePvePayload(table.concat({ self.pveProtocol, "RAIDDEL", id, tostring(rev) }, "^"), "GUILD")
    self:OnPveDataChanged("RAIDS", false)
    return true
end

function OTLGM:SendPveRaidNotice(minutes)
    if not self.IsOfficerMode or not self:IsOfficerMode() then return false end
    local raid = self:GetPveActiveRaid()
    if not raid then return false end
    minutes = tonumber(minutes) or 0
    local label = minutes <= 0 and "Raid is starting now" or ("Raid begins in " .. tostring(minutes) .. " minutes")
    local payload = table.concat({ self.pveProtocol, "NOTICE", raid.id or "", tostring(minutes), PveSafeText(raid.name, 36), PveSafeText(raid.serverTime, 28), PveSafeText(label, 48) }, "^")
    self:QueuePvePayload(payload, "GUILD")
    self:ShowPveRaidNotice(raid.name, label .. " - " .. (raid.serverTime or ""), false)
    return true
end

function OTLGM:PostPveRaidToGuildChat()
    local raid = self:GetPveActiveRaid()
    if not raid then return false end
    local text = "[Guild Raid] " .. (raid.name or "Raid") .. " - " .. (raid.serverTime or "time TBA")
    if raid.location and raid.location ~= "" then text = text .. " - " .. raid.location end
    if raid.note and raid.note ~= "" then text = text .. ". " .. raid.note end
    text = text .. " Sign-ups are in Discord."
    if SendChatMessage then pcall(SendChatMessage, text, "GUILD") return true end
    return false
end

function OTLGM:IsRaidNoticeEligible()
    local player = UnitName("player") or ""
    local member = self:GetMember(player)
    local rank = string.lower((member and member.rank) or select(2, GetGuildInfo("player")) or "")
    if string.find(rank, "core raider", 1, true) or string.find(rank, "the devoted", 1, true) then return true end
    if rank == "raider" or string.find(rank, "4 - raider", 1, true) then return true end
    return false
end

function OTLGM:ShowPveRaidNotice(title, body, remote)
    if not self:IsRaidNoticeEligible() then return end
    if OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.pveRaidPopups == false then return end
    if self.Notify then self:Notify("Raid Notice: " .. (title or "Guild Raid"), body or "") end
    if OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.pveRaidChatLine and self.Chat then
        self:Chat(self.colors.gold .. "[Raid Notice] " .. self.colors.reset .. (title or "Guild Raid") .. " - " .. (body or ""))
    end
end

function OTLGM:GetPveRaidRemainingText(raid)
    if not raid or not raid.startTs then return "No active raid notice" end
    local remaining = raid.startTs - self:Now()
    if remaining <= 0 then return "Starting now" end
    local hours = math.floor(remaining / 3600)
    local minutes = math.floor(math.mod(remaining, 3600) / 60)
    if hours > 0 then return tostring(hours) .. "h " .. tostring(minutes) .. "m remaining" end
    return tostring(math.max(1, minutes)) .. "m remaining"
end

function OTLGM:CheckPveRaidReminders()
    local pve = self:EnsurePveDB()
    local raid = pve and pve.raid
    if not raid or not raid.startTs then return end
    if raid.startTs + 300 < self:Now() then return end
    local remaining = raid.startTs - self:Now()
    local window
    if remaining <= 0 then window = 0
    elseif remaining <= 300 then window = 300
    elseif remaining <= 900 then window = 900
    elseif remaining <= 1800 then window = 1800
    elseif remaining <= 3600 then window = 3600
    else return end
    pve.reminded[raid.id] = pve.reminded[raid.id] or {}
    if pve.reminded[raid.id][window] then return end
    pve.reminded[raid.id][window] = true
    local label
    if window == 0 then label = "Raid is starting now"
    elseif window == 300 then label = "Raid begins in about 5 minutes"
    elseif window == 900 then label = "Raid begins in about 15 minutes"
    elseif window == 1800 then label = "Raid begins in about 30 minutes"
    else label = "Raid begins in about 1 hour" end
    self:ShowPveRaidNotice(raid.name, label .. " - " .. (raid.serverTime or ""), false)
end

function OTLGM:RequestPveSync(force)
    if not SendAddonMessage or not GetGuildInfo("player") then return false end
    local now = self:Now()
    if not force and self.lastPveSyncRequestAt and now - self.lastPveSyncRequestAt < 30 then return false end
    self.lastPveSyncRequestAt = now
    local nonce = tostring(now) .. tostring(self.pveSequence or 0)
    self:QueuePvePayload(table.concat({ self.pveProtocol, "SYNC", nonce, self.version or "?" }, "^"), "GUILD")
    local pve = self:EnsurePveDB()
    if pve then pve.lastSync = now end
    return true
end

function OTLGM:QueuePveSyncResponse(target)
    local pve = self:EnsurePveDB()
    if not pve then return end
    self:PurgePveData(true)
    local id, record
    for id, record in pairs(pve.requests) do self:QueuePvePayload(self:SerializePveRequest(record), "WHISPER", target) end
    if pve.raid then self:QueuePvePayload(self:SerializePveRaid(pve.raid), "WHISPER", target) end
    for id, record in pairs(pve.board) do self:QueuePvePayload(self:SerializePveBoard(record), "WHISPER", target) end
    local normalizedTarget = PveNormalizeName(target)
    for id, record in pairs(pve.applications or {}) do
        if PveNormalizeName(record.leader) == normalizedTarget or PveNormalizeName(record.author) == normalizedTarget then
            self:QueuePvePayload(self:SerializePveApplication(record), "WHISPER", target)
        end
    end
end

function OTLGM:InitializePveSync()
    self:EnsurePveDB()
    if RegisterAddonMessagePrefix then pcall(RegisterAddonMessagePrefix, "OTLGM") end
    self.pveSyncAt = self:Now() + 4
end

function OTLGM:ApplyRemotePveRequest(fields)
    local pve = self:EnsurePveDB()
    local record = {
        id = fields[3] or "", rev = tonumber(fields[4]) or 0, ts = tonumber(fields[5]) or 0, expires = tonumber(fields[6]) or 0,
        author = fields[7] or "Unknown", level = tonumber(fields[8]) or 0, class = fields[9] or "",
        kind = fields[10] or "OTHER", role = fields[11] or "ANY", activity = fields[12] or "", note = fields[13] or "",
        maxSize = tonumber(fields[14]) or 5, current = tonumber(fields[15]) or 1,
        needTank = tonumber(fields[16]) or 0, needHeal = tonumber(fields[17]) or 0, needDps = tonumber(fields[18]) or 0,
        status = fields[19] or "OPEN",
    }
    if record.id == "" or record.expires <= self:Now() then return end
    if not fields[14] or fields[14] == "" then
        local slots = math.max(1, (record.maxSize or 5) - 1)
        if record.role == "TANK" then record.needTank, record.needHeal, record.needDps = 0, 1, math.max(0, slots - 1)
        elseif record.role == "HEAL" then record.needTank, record.needHeal, record.needDps = 1, 0, math.max(0, slots - 1)
        else record.needTank, record.needHeal, record.needDps = 1, 1, math.max(0, slots - 2) end
    end
    if self:GetPveRecordRevision(record.id) >= record.rev then return end
    record.status = self:GetPveGroupStatus(record)
    pve.requests[record.id] = record
    pve.deleted[record.id] = nil
    self:IncrementPveUnread("GROUPS")
    self:OnPveDataChanged("GROUPS", true)
end

function OTLGM:ApplyRemotePveApplication(fields, sender)
    local pve = self:EnsurePveDB()
    local record = {
        id = fields[3] or "", groupId = fields[4] or "", rev = tonumber(fields[5]) or 0,
        ts = tonumber(fields[6]) or 0, expires = tonumber(fields[7]) or 0,
        leader = fields[8] or "", author = fields[9] or "Unknown", level = tonumber(fields[10]) or 0,
        class = fields[11] or "", role = fields[12] or "DPS", status = fields[13] or "PENDING", note = fields[14] or "",
    }
    if record.id == "" or record.groupId == "" or record.expires <= self:Now() then return end
    local normalizedSender = PveNormalizeName(sender or "")
    if record.status == "PENDING" or record.status == "CANCELLED" then
        if normalizedSender ~= PveNormalizeName(record.author) then return end
    elseif record.status == "ACCEPTED" or record.status == "DECLINED" then
        if normalizedSender ~= PveNormalizeName(record.leader) then return end
    end
    local player = PveNormalizeName(UnitName("player") or "")
    local isLeader = PveNormalizeName(record.leader) == player
    local isApplicant = PveNormalizeName(record.author) == player
    if not isLeader and not isApplicant then return end
    local existing = pve.applications[record.id]
    if existing and (tonumber(existing.rev) or 0) >= record.rev then return end
    pve.applications[record.id] = record
    if isLeader and record.status == "PENDING" then
        self:IncrementPveUnread("GROUPS")
        if self.Notify then self:Notify("New Group Application", (record.author or "Unknown") .. " wants to join as " .. (record.role or "Any") .. ".") end
    elseif isApplicant and record.status == "ACCEPTED" then
        if self.Notify then self:Notify("Group Request Accepted", (record.leader or "The leader") .. " accepted your request and sent an invite.") end
    elseif isApplicant and record.status == "DECLINED" then
        if self.Notify then self:Notify("Group Request Declined", (record.leader or "The leader") .. " declined your request.") end
    end
    self:OnPveDataChanged("GROUPS", true)
end

function OTLGM:ApplyRemotePveBoard(fields)
    local pve = self:EnsurePveDB()
    local record = {
        id = fields[3] or "", rev = tonumber(fields[4]) or 0, ts = tonumber(fields[5]) or 0, expires = tonumber(fields[6]) or 0,
        author = fields[7] or "Unknown", level = tonumber(fields[8]) or 0, class = fields[9] or "", text = fields[10] or "",
    }
    if record.id == "" or record.expires <= self:Now() then return end
    if self:GetPveRecordRevision(record.id) >= record.rev then return end
    pve.board[record.id] = record
    pve.deleted[record.id] = nil
    self:IncrementPveUnread("BOARD")
    self:OnPveDataChanged("BOARD", true)
end

function OTLGM:ApplyRemotePveRaid(fields)
    local pve = self:EnsurePveDB()
    local record = {
        id = fields[3] or "", rev = tonumber(fields[4]) or 0, ts = tonumber(fields[5]) or 0, startTs = tonumber(fields[6]) or 0,
        author = fields[7] or "Unknown", name = fields[8] or "Guild Raid", location = fields[9] or "", serverTime = fields[10] or "", note = fields[11] or "",
    }
    if record.id == "" or record.startTs + 14400 <= self:Now() then return end
    local leadership = self:IsPveLeadershipName(record.author)
    if leadership == false then return end
    if self:GetPveRecordRevision(record.id) >= record.rev then return end
    pve.raid = record
    pve.deleted[record.id] = nil
    pve.reminded[record.id] = pve.reminded[record.id] or {}
    if self:IsRaidNoticeEligible() then self:IncrementPveUnread("RAIDS") end
    self:OnPveDataChanged("RAIDS", true)
    local player = UnitName("player") or ""
    if PveNormalizeName(record.author) ~= PveNormalizeName(player) then
        self:ShowPveRaidNotice(record.name, (record.serverTime or "") .. (record.location ~= "" and (" - " .. record.location) or ""), true)
    end
end

function OTLGM:ApplyRemotePveDelete(kind, id, rev)
    local pve = self:EnsurePveDB()
    rev = tonumber(rev) or 0
    if id == "" or self:GetPveRecordRevision(id) >= rev then return end
    if kind == "REQDEL" then
        pve.requests[id] = nil
        local appId, application
        for appId, application in pairs(pve.applications or {}) do if application.groupId == id then pve.applications[appId] = nil end end
    end
    if kind == "BOARDDEL" then pve.board[id] = nil end
    if kind == "RAIDDEL" and pve.raid and pve.raid.id == id then pve.raid = nil end
    pve.deleted[id] = { rev = rev, ts = self:Now() }
    local section = kind == "REQDEL" and "GROUPS" or (kind == "BOARDDEL" and "BOARD" or "RAIDS")
    self:OnPveDataChanged(section, true)
end

function OTLGM:HandlePveAddonMessage(message, channel, sender)
    if not message or string.sub(message, 1, 3) ~= self.pveProtocol .. "^" then return false end
    if sender and PveNormalizeName(sender) == PveNormalizeName(UnitName("player") or "") then return true end
    local fields = PveSplit(message)
    local kind = fields[2] or ""
    if kind == "SYNC" then
        if sender and PveNormalizeName(sender) ~= PveNormalizeName(UnitName("player") or "") then self:QueuePveSyncResponse(sender) end
        return true
    end
    if kind == "REQ" then self:ApplyRemotePveRequest(fields) return true end
    if kind == "APP" then self:ApplyRemotePveApplication(fields, sender) return true end
    if kind == "BOARD" then self:ApplyRemotePveBoard(fields) return true end
    if kind == "RAID" then self:ApplyRemotePveRaid(fields) return true end
    if kind == "REQDEL" or kind == "BOARDDEL" or kind == "RAIDDEL" then
        local id = fields[3] or ""
        local pve = self:EnsurePveDB()
        local record = kind == "REQDEL" and pve.requests[id] or (kind == "BOARDDEL" and pve.board[id] or pve.raid)
        local senderLeadership = self:IsPveLeadershipName(sender)
        local senderOwns = record and PveNormalizeName(record.author) == PveNormalizeName(sender)
        if senderOwns or senderLeadership == true or not record then self:ApplyRemotePveDelete(kind, id, fields[4] or "0") end
        return true
    end
    if kind == "NOTICE" then
        local senderLeadership = self:IsPveLeadershipName(sender)
        if senderLeadership == false then return true end
        local raidName = fields[5] or "Guild Raid"
        local serverTime = fields[6] or ""
        local label = fields[7] or "Raid notice"
        if self:IsRaidNoticeEligible() then self:IncrementPveUnread("RAIDS") end
        self:ShowPveRaidNotice(raidName, label .. (serverTime ~= "" and (" - " .. serverTime) or ""), true)
        self:OnPveDataChanged("RAIDS", true)
        return true
    end
    return true
end

function OTLGM:OnPveDataChanged(section, remote)
    if self.RefreshPveNavigationBadge then self:RefreshPveNavigationBadge() end
    if self.ui and self.ui.main and self.ui.main:IsVisible() then
        if self.ui.currentPage == "pve" and self.RefreshPvePage then self:RefreshPvePage() end
        if self.ui.currentPage == "home" and self.RefreshHomePage then self:RefreshHomePage() end
        if self.ui.currentPage == "overview" and self.RefreshOverviewPage then self:RefreshOverviewPage() end
    end
end
