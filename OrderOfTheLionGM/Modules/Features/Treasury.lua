-- Guild treasury planning and a conservative read-only guild-bank adapter.
-- Manual goals are shared between addon users, but only verified leadership
-- senders can change them. No code in this module deposits, withdraws or moves
-- an item, and server APIs are touched only on explicit page refresh.

OTLGM.treasuryProtocol170 = "B1"

local TREASURY_MAX_GOALS = 8
local TREASURY_MAX_HISTORY = 40
local TREASURY_MAX_DELETED = 16
local TREASURY_MAX_COPPER = 2000000000

local function TTrim(value)
    value = tostring(value or "")
    return string.gsub(value, "^%s*(.-)%s*$", "%1")
end

local function TEscape(value, maximum, wireMaximum)
    value = OTLGM:SafeText(value, maximum or 80, false, false)
    local result = {}
    local wireLength, index = 0, 1
    while index <= string.len(value) do
        local byteValue = string.byte(value, index) or 0
        local characterLength = byteValue >= 240 and 4 or byteValue >= 224 and 3 or byteValue >= 192 and 2 or 1
        if index + characterLength - 1 > string.len(value) then characterLength = 1 end
        local character = string.sub(value, index, index + characterLength - 1)
        local encoded = character == "%" and "%25" or character == "^" and "%5E" or character
        if wireMaximum and wireLength + string.len(encoded) > wireMaximum then break end
        table.insert(result, encoded)
        wireLength = wireLength + string.len(encoded)
        index = index + characterLength
    end
    return table.concat(result)
end

local function TUnescape(value)
    value = tostring(value or "")
    value = string.gsub(value, "%%5E", "^")
    value = string.gsub(value, "%%25", "%%")
    return value
end

local function TClampCopper(value)
    return math.max(0, math.min(TREASURY_MAX_COPPER, math.floor(tonumber(value) or 0)))
end

local function TGoalCount(goals)
    local count = 0
    local key
    for key in pairs(goals or {}) do count = count + 1 end
    return count
end

local function TSortedGoals(goals)
    local result = {}
    local id, goal
    for id, goal in pairs(goals or {}) do
        goal.id = goal.id or id
        table.insert(result, goal)
    end
    table.sort(result, function(left, right)
        local lo = tonumber(left.order) or 99
        local ro = tonumber(right.order) or 99
        if lo ~= ro then return lo < ro end
        if (tonumber(left.updatedAt) or 0) ~= (tonumber(right.updatedAt) or 0) then return (tonumber(left.updatedAt) or 0) > (tonumber(right.updatedAt) or 0) end
        return tostring(left.id or "") < tostring(right.id or "")
    end)
    return result
end

local function TPruneDeleted(treasury)
    local rows = {}
    local id, record
    for id, record in pairs(treasury and treasury.deleted or {}) do
        table.insert(rows, { id = id, ts = tonumber(record and record.ts) or 0 })
    end
    if table.getn(rows) <= TREASURY_MAX_DELETED then return end
    table.sort(rows, function(left, right)
        if left.ts ~= right.ts then return left.ts < right.ts end
        return tostring(left.id) < tostring(right.id)
    end)
    local index
    for index = 1, table.getn(rows) - TREASURY_MAX_DELETED do treasury.deleted[rows[index].id] = nil end
end

local function TIsNewer(revision, updatedAt, actor, current)
    if not current then return true end
    local incomingRevision = tonumber(revision) or 0
    local currentRevision = tonumber(current.revision) or 0
    if incomingRevision ~= currentRevision then return incomingRevision > currentRevision end
    local incomingAt = tonumber(updatedAt) or 0
    local currentAt = tonumber(current.updatedAt or current.ts) or 0
    if incomingAt ~= currentAt then return incomingAt > currentAt end
    return tostring(actor or "") > tostring(current.updatedBy or current.actor or "")
end

local function TAddHistory(treasury, entry)
    if not treasury or not entry then return end
    local first = treasury.history and treasury.history[1]
    if first and first.id == entry.id and first.kind == entry.kind and tonumber(first.ts) == tonumber(entry.ts) and first.actor == entry.actor then return end
    table.insert(treasury.history, 1, entry)
    while table.getn(treasury.history) > TREASURY_MAX_HISTORY do table.remove(treasury.history) end
end

local function TDefaultGoals(now)
    return {
        BANK = { id = "BANK", name = "Guild Bank Purchase", category = "BANK", current = 0, target = 0, revision = 1, updatedAt = now, updatedBy = "Planning", order = 1 },
        TAB1 = { id = "TAB1", name = "First Bank Tab", category = "TAB", current = 0, target = 0, revision = 1, updatedAt = now, updatedBy = "Planning", order = 2 },
        TABARD = { id = "TABARD", name = "Guild Tabard", category = "TABARD", current = 0, target = 0, revision = 1, updatedAt = now, updatedBy = "Planning", order = 3 },
        HOUSE = { id = "HOUSE", name = "Guild House / Teleport", category = "HOUSE", current = 0, target = 0, revision = 1, updatedAt = now, updatedBy = "Planning", order = 4 },
    }
end

function OTLGM:EnsureTreasury170()
    local db = self:GetGuildDB()
    if not db then return nil end
    if type(db.treasury170) ~= "table" then db.treasury170 = {} end
    local treasury = db.treasury170
    if type(treasury.goals) ~= "table" then treasury.goals = {} end
    if type(treasury.deleted) ~= "table" then treasury.deleted = {} end
    if type(treasury.history) ~= "table" then treasury.history = {} end
    treasury.revision = math.max(0, math.min(1000000, math.floor(tonumber(treasury.revision) or 0)))
    treasury.mode = treasury.mode == "READ_ONLY" and "READ_ONLY" or "PREVIEW"

    -- Backups and SavedVariables are user-editable. Normalize this small data
    -- set before any UI or synchronization code indexes it.
    local safeGoals = {}
    local rawId, goal
    for rawId, goal in pairs(treasury.goals) do
        local id = tostring(rawId or "")
        if type(goal) == "table" and self:IsValidID(id, 32) then
            goal.id = id
            goal.name = self:SafeText(goal.name or "", 42, false, false)
            if goal.name ~= "" then
                goal.current = TClampCopper(goal.current)
                goal.target = TClampCopper(goal.target)
                goal.category = self:SafeText(goal.category or "CUSTOM", 16, false, false)
                goal.revision = math.max(1, math.min(1000000, math.floor(tonumber(goal.revision) or 1)))
                goal.updatedAt = math.max(0, math.floor(tonumber(goal.updatedAt) or 0))
                goal.updatedBy = self:SafeText(goal.updatedBy or "Leadership", 28, false, false)
                goal.order = math.max(1, math.min(TREASURY_MAX_GOALS, math.floor(tonumber(goal.order) or TREASURY_MAX_GOALS)))
                safeGoals[id] = goal
            end
        end
    end
    treasury.goals = safeGoals

    local safeDeleted = {}
    local tombstone
    for rawId, tombstone in pairs(treasury.deleted) do
        local id = tostring(rawId or "")
        if type(tombstone) == "table" and self:IsValidID(id, 32) and (tonumber(tombstone.revision) or 0) >= 1 then
            safeDeleted[id] = {
                revision = math.min(1000000, math.floor(tonumber(tombstone.revision) or 1)),
                ts = math.max(0, math.floor(tonumber(tombstone.ts) or 0)),
                actor = self:SafeText(tombstone.actor or "Leadership", 28, false, false),
            }
        end
    end
    treasury.deleted = safeDeleted

    local safeHistory = {}
    local index, entry
    for index = 1, math.min(TREASURY_MAX_HISTORY, table.getn(treasury.history)) do
        entry = treasury.history[index]
        if type(entry) == "table" then
            table.insert(safeHistory, {
                ts = math.max(0, math.floor(tonumber(entry.ts) or 0)), id = self:SafeText(entry.id or "", 32, false, false),
                name = self:SafeText(entry.name or "", 42, false, false), actor = self:SafeText(entry.actor or "Leadership", 28, false, false),
                kind = self:SafeText(entry.kind or "UPDATE", 16, false, false), current = TClampCopper(entry.current), target = TClampCopper(entry.target),
            })
        end
    end
    treasury.history = safeHistory
    if not treasury.seeded170 and TGoalCount(treasury.goals) == 0 then
        treasury.goals = TDefaultGoals(self:Now())
        treasury.seeded170 = true
        treasury.revision = math.max(1, treasury.revision)
    end
    local id
    for id, tombstone in pairs(treasury.deleted) do
        if treasury.goals[id] then
            if TIsNewer(treasury.goals[id].revision, treasury.goals[id].updatedAt, treasury.goals[id].updatedBy, tombstone) then treasury.deleted[id] = nil
            else treasury.goals[id] = nil end
        end
    end
    if TGoalCount(treasury.goals) > TREASURY_MAX_GOALS then
        local ordered = TSortedGoals(treasury.goals)
        local keep = {}
        local index
        for index = 1, TREASURY_MAX_GOALS do if ordered[index] then keep[ordered[index].id] = ordered[index] end end
        treasury.goals = keep
    end
    TPruneDeleted(treasury)
    while table.getn(treasury.history) > TREASURY_MAX_HISTORY do table.remove(treasury.history) end
    return treasury
end

function OTLGM:GetTreasuryGoals170()
    local treasury = self:EnsureTreasury170()
    return TSortedGoals(treasury and treasury.goals or {})
end

function OTLGM:GetTreasuryGoal170(id)
    local treasury = self:EnsureTreasury170()
    return treasury and treasury.goals and treasury.goals[id]
end

function OTLGM:CanEditTreasury170()
    if self.CanPublishAnnouncement152 and self:CanPublishAnnouncement152() then return true end
    return self.CanEditOfficerNotes and self:CanEditOfficerNotes() and true or false
end

function OTLGM:GetGuildBankCapability170()
    local hasMoney = type(GetGuildBankMoney) == "function"
    local hasTabs = type(GetNumGuildBankTabs) == "function"
    local hasTabInfo = type(GetGuildBankTabInfo) == "function"
    local hasItems = type(GetGuildBankItemInfo) == "function"
    local hasHistory = type(GetGuildBankTransaction) == "function"
    return {
        available = hasMoney or hasTabs or hasTabInfo or hasItems or hasHistory,
        money = hasMoney, tabs = hasTabs, tabInfo = hasTabInfo, items = hasItems, history = hasHistory,
        mode = (hasMoney or hasTabs or hasTabInfo or hasItems or hasHistory) and "READ_ONLY" or "PREVIEW",
    }
end

function OTLGM:RefreshGuildBankAdapter170()
    self.runtime = self.runtime or {}
    local capability = self:GetGuildBankCapability170()
    local snapshot = { capability = capability, refreshedAt = self:Now(), mode = capability.mode }
    if self:InCombat() then snapshot.deferred = true self.runtime.guildBank170 = snapshot return snapshot end
    if capability.money then
        local ok, value = pcall(GetGuildBankMoney)
        if ok then snapshot.money = TClampCopper(value) else snapshot.moneyError = self:SafeText(value, 120, false, false) end
    end
    if capability.tabs then
        local ok, value = pcall(GetNumGuildBankTabs)
        if ok then snapshot.tabCount = math.max(0, math.min(20, tonumber(value) or 0)) else snapshot.tabsError = self:SafeText(value, 120, false, false) end
    end
    self.runtime.guildBank170 = snapshot
    local treasury = self:EnsureTreasury170()
    if treasury then treasury.mode = capability.mode end
    return snapshot
end

local function TQueueGoal(self, goal, target)
    if not goal then return false end
    local payload = table.concat({
        self.treasuryProtocol170, "GOAL", goal.id or "", tostring(goal.revision or 1), tostring(goal.updatedAt or self:Now()),
        TEscape(goal.updatedBy or "Leadership", 28, 32), TEscape(goal.name or "Guild Goal", 42, 64),
        tostring(TClampCopper(goal.current)), tostring(TClampCopper(goal.target)), TEscape(goal.category or "CUSTOM", 16, 16), tostring(goal.order or 99),
    }, "^")
    local limit = self.GetNetworkPayloadLimit and self:GetNetworkPayloadLimit(target and "WHISPER" or "GUILD", target) or 250
    if string.len(payload) > limit then return false end
    return self:QueueNetworkPayload(payload, target and "WHISPER" or "GUILD", target, target and 2 or 3, "treasury", "treasury:" .. tostring(target or "guild") .. ":" .. tostring(goal.id))
end

local function TQueueDelete(self, id, record, target)
    if not record or not self:IsValidID(id, 32) then return false end
    local payload = table.concat({
        self.treasuryProtocol170, "DEL", id, tostring(record.revision or 1), tostring(record.ts or self:Now()), TEscape(record.actor or "Leadership", 28, 32),
    }, "^")
    local limit = self.GetNetworkPayloadLimit and self:GetNetworkPayloadLimit(target and "WHISPER" or "GUILD", target) or 250
    if string.len(payload) > limit then return false end
    return self:QueueNetworkPayload(payload, target and "WHISPER" or "GUILD", target, target and 2 or 3, "treasury", "treasury:" .. tostring(target or "guild") .. ":deleted:" .. tostring(id))
end

function OTLGM:SetTreasuryGoal170(id, name, current, target, category)
    if not self:CanEditTreasury170() then return false, "Only guild leadership can edit treasury goals." end
    id = string.upper(TTrim(id))
    if not self:IsValidID(id, 32) then return false, "The goal ID is invalid." end
    name = self:SafeText(name, 42, false, false)
    if name == "" then return false, "A goal name is required." end
    local treasury = self:EnsureTreasury170()
    if not treasury.goals[id] and TGoalCount(treasury.goals) >= TREASURY_MAX_GOALS then return false, "The treasury supports up to eight active goals." end
    local old = treasury.goals[id]
    local now = self:Now()
    local goal = old or { id = id, order = TGoalCount(treasury.goals) + 1 }
    local deletedRevision = tonumber(treasury.deleted[id] and treasury.deleted[id].revision) or 0
    treasury.revision = math.max(tonumber(treasury.revision) or 0, tonumber(goal.revision) or 0, deletedRevision) + 1
    goal.name = name
    goal.current = TClampCopper(current)
    goal.target = TClampCopper(target)
    goal.category = self:SafeText(category or goal.category or "CUSTOM", 16, false, false)
    goal.revision = treasury.revision
    goal.updatedAt = now
    goal.updatedBy = string.gsub(UnitName("player") or "Leadership", "%-.*$", "")
    treasury.goals[id] = goal
    treasury.deleted[id] = nil
    TAddHistory(treasury, { ts = now, id = id, name = name, current = goal.current, target = goal.target, actor = goal.updatedBy, kind = old and "UPDATE" or "CREATE" })
    TQueueGoal(self, goal)
    if self.RefreshTreasuryPage170 then self:RefreshTreasuryPage170() end
    return true, goal
end

function OTLGM:DeleteTreasuryGoal170(id)
    if not self:CanEditTreasury170() then return false, "Only guild leadership can delete treasury goals." end
    local treasury = self:EnsureTreasury170()
    local old = treasury and treasury.goals and treasury.goals[id]
    if not old then return false, "That goal no longer exists." end
    treasury.revision = (tonumber(treasury.revision) or 0) + 1
    treasury.goals[id] = nil
    local now = self:Now()
    local actor = string.gsub(UnitName("player") or "Leadership", "%-.*$", "")
    treasury.deleted[id] = { revision = treasury.revision, ts = now, actor = actor }
    TPruneDeleted(treasury)
    TAddHistory(treasury, { ts = now, id = id, name = old.name, actor = actor, kind = "DELETE" })
    TQueueDelete(self, id, treasury.deleted[id])
    if self.RefreshTreasuryPage170 then self:RefreshTreasuryPage170() end
    return true
end

function OTLGM:QueueTreasuryState170(target)
    if not target or target == "" or not self:CanEditTreasury170() then return false end
    local goals = self:GetTreasuryGoals170()
    local treasury = self:EnsureTreasury170()
    local deletedCount = TGoalCount(treasury.deleted)
    if self.CanQueueNetworkPayloads and not self:CanQueueNetworkPayloads(table.getn(goals) + deletedCount + 1, 16) then return false end
    local deletedRows = {}
    local deletedId, deleted
    for deletedId, deleted in pairs(treasury.deleted) do table.insert(deletedRows, { id = deletedId, record = deleted }) end
    table.sort(deletedRows, function(left, right) return tostring(left.id) < tostring(right.id) end)
    for index = 1, table.getn(deletedRows) do
        if not TQueueDelete(self, deletedRows[index].id, deletedRows[index].record, target) then return false end
    end
    for index = 1, math.min(TREASURY_MAX_GOALS, table.getn(goals)) do
        if not TQueueGoal(self, goals[index], target) then return false end
    end
    local ended = self:QueueNetworkPayload(table.concat({ self.treasuryProtocol170, "END", tostring(treasury.revision or 0), tostring(table.getn(goals)) }, "^"), "WHISPER", target, 2, "treasury")
    return ended and true or false
end

function OTLGM:RequestTreasurySync170(force)
    local now = self:Now()
    if not force and self.lastTreasurySync170 and now - self.lastTreasurySync170 < 60 then return false end
    local queued = self:QueueNetworkPayload(table.concat({ self.treasuryProtocol170, "SYNC", self.version, tostring(now) }, "^"), "GUILD", nil, 2, "treasury", "treasury:sync")
    if not queued then return false end
    self.lastTreasurySync170 = now
    self.runtime = self.runtime or {}
    self.runtime.treasurySync170 = { active = true, started = now, received = 0 }
    return true
end

function OTLGM:ScheduleTreasuryState170(target)
    if not target or target == "" or self:NormalizeName(target) == self:NormalizeName(UnitName("player") or "") then return false end
    self.treasuryShareTargets170 = self.treasuryShareTargets170 or {}
    local name = UnitName("player") or "Player"
    local score = 0
    local index
    for index = 1, string.len(name) do score = score + string.byte(name, index) end
    local key = self:NormalizeName(target)
    local due = self:Now() + 1 + math.mod(score, 5)
    local old = self.treasuryShareTargets170[key]
    if not old or due < (old.due or due) then self.treasuryShareTargets170[key] = { name = target, due = due } end
    return true
end

function OTLGM:ProcessTreasuryTimers170()
    local key, pending
    for key, pending in pairs(self.treasuryShareTargets170 or {}) do
        if pending and self:Now() >= (pending.due or 0) then
            self.treasuryShareTargets170[key] = nil
            self:QueueTreasuryState170(pending.name)
            break
        end
    end
    local sync = self.runtime and self.runtime.treasurySync170
    if sync and sync.active and self:Now() - (tonumber(sync.started) or self:Now()) > 15 then
        sync.active = false
        sync.completed = self:Now()
    end
end

function OTLGM:HandleTreasuryMessage170(message, channel, sender)
    local fields = self:Split(message, "^")
    local kind = fields[2] or ""
    if kind == "SYNC" then
        if self:NormalizeName(sender) ~= self:NormalizeName(UnitName("player") or "") and self:CanEditTreasury170() then self:ScheduleTreasuryState170(sender) end
        return true
    end
    local treasury = self:EnsureTreasury170()
    if kind == "GOAL" then
        local id = fields[3] or ""
        local revision = tonumber(fields[4]) or 0
        if not self:IsValidID(id, 32) or revision < 1 then return false end
        local old = treasury.goals[id]
        local updatedAt = tonumber(fields[5]) or self:Now()
        local updatedBy = self:SafeText(TUnescape(fields[6] or ""), 28, false, false)
        if updatedBy == "" then updatedBy = self:SafeText(sender or "Leadership", 28, false, false) end
        local tombstone = treasury.deleted[id]
        if tombstone and not TIsNewer(revision, updatedAt, updatedBy, tombstone) then return true end
        if old and not TIsNewer(revision, updatedAt, updatedBy, old) then return true end
        if not old and TGoalCount(treasury.goals) >= TREASURY_MAX_GOALS then return false end
        local name = self:SafeText(TUnescape(fields[7] or ""), 42, false, false)
        if name == "" then return false end
        treasury.goals[id] = {
            id = id, revision = revision, updatedAt = updatedAt, updatedBy = updatedBy,
            name = name, current = TClampCopper(fields[8]), target = TClampCopper(fields[9]), category = self:SafeText(TUnescape(fields[10] or "CUSTOM"), 16, false, false),
            order = math.max(1, math.min(TREASURY_MAX_GOALS, tonumber(fields[11]) or 99)), verified = true,
        }
        treasury.deleted[id] = nil
        treasury.revision = math.max(treasury.revision or 0, revision)
        TAddHistory(treasury, { ts = updatedAt, id = id, name = name, actor = updatedBy, kind = old and "SYNC UPDATE" or "SYNC ADD" })
        self.runtime.treasurySync170 = self.runtime.treasurySync170 or { active = true, started = self:Now(), received = 0 }
        self.runtime.treasurySync170.received = (tonumber(self.runtime.treasurySync170.received) or 0) + 1
        if self.RefreshTreasuryPage170 and self.ui and self.ui.currentPage == "treasury" then self:RefreshTreasuryPage170() end
        return true
    end
    if kind == "DEL" then
        local id, revision = fields[3] or "", tonumber(fields[4]) or 0
        if not self:IsValidID(id, 32) or revision < 1 then return false end
        local deletedAt = tonumber(fields[5]) or self:Now()
        local actor = self:SafeText(TUnescape(fields[6] or ""), 28, false, false)
        if actor == "" then actor = self:SafeText(sender or "Leadership", 28, false, false) end
        local old = treasury.goals[id]
        local tombstone = treasury.deleted[id]
        if old and not TIsNewer(revision, deletedAt, actor, old) then return true end
        if tombstone and not TIsNewer(revision, deletedAt, actor, tombstone) then return true end
        treasury.goals[id] = nil
        treasury.deleted[id] = { revision = revision, ts = deletedAt, actor = actor }
        treasury.revision = math.max(tonumber(treasury.revision) or 0, revision)
        TPruneDeleted(treasury)
        if old then TAddHistory(treasury, { ts = deletedAt, id = id, name = old.name, actor = actor, kind = "SYNC DELETE" }) end
        if self.RefreshTreasuryPage170 and self.ui and self.ui.currentPage == "treasury" then self:RefreshTreasuryPage170() end
        return true
    end
    if kind == "END" then
        self.runtime.treasurySync170 = self.runtime.treasurySync170 or {}
        self.runtime.treasurySync170.active = false
        self.runtime.treasurySync170.completed = self:Now()
        if self.RefreshTreasuryPage170 and self.ui and self.ui.currentPage == "treasury" then self:RefreshTreasuryPage170() end
        return true
    end
    return false
end

OTLGM:RegisterModule("Treasury", {
    layer = "feature",
    protocol = OTLGM.treasuryProtocol170,
    mode = "read-only-adapter",
    maximumGoals = TREASURY_MAX_GOALS,
})
