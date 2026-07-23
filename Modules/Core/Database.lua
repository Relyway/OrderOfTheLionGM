-- Canonical SavedVariables owner and migration entry point.
-- Older modules expose named, idempotent migration stages; only this file owns
-- the public EnsureDB, GetGuildDB and MigrateGuildDB methods.

local ROOT_SCHEMA = 14

local function EnsureRootShape170()
    if type(OTLGM_DB) ~= "table" then OTLGM_DB = {} end
    if type(OTLGM_DB.guilds) ~= "table" then OTLGM_DB.guilds = {} end
    if type(OTLGM_DB.settings) ~= "table" then OTLGM_DB.settings = {} end

    -- Legacy or hand-edited SavedVariables can contain a scalar where older
    -- default layers expect a table and immediately index it. Repair those
    -- containers before invoking any historical migration stage.
    local settings = OTLGM_DB.settings
    local tableSettings = {
        "customMessageNames", "recruitmentLastSent", "guildChatDrafts",
        "customMessages", "savedRosterViews", "notifications",
        "recruitmentRotation170",
    }
    local index, key
    for index = 1, table.getn(tableSettings) do
        key = tableSettings[index]
        if type(settings[key]) ~= "table" then settings[key] = nil end
    end
    if type(settings.notifications) == "table" then
        local categories = { "raid", "announcement", "group", "response", "crafting", "reaction", "mention", "background" }
        for index = 1, table.getn(categories) do
            key = categories[index]
            if settings.notifications[key] ~= nil and type(settings.notifications[key]) ~= "table" then settings.notifications[key] = nil end
        end
    end
end

local function EnsureGuildContainers170(db)
    local fields = {
        "roster", "log", "daily", "pendingInvites", "pendingActions",
        "memberFlags", "detectedVersions", "snapshots", "scans", "crafting",
        "weeklySnapshots", "announcements", "announcementDeleted",
        "pendingAnnouncements", "announcementRead", "notificationSeen",
        "notificationUnread", "recentUsefulActivity", "pve", "achievements174",
    }
    local index, key
    for index = 1, table.getn(fields) do
        key = fields[index]
        if type(db[key]) ~= "table" then db[key] = {} end
    end
    if type(db.activity) ~= "table" then db.activity = { days = {}, allTimePeak = 0, totalScans = 0 } end
    if type(db.activity.days) ~= "table" then db.activity.days = {} end
    db.activity.allTimePeak = tonumber(db.activity.allTimePeak) or 0
    db.activity.totalScans = tonumber(db.activity.totalScans) or 0
    if type(db.announcementSync) ~= "table" then db.announcementSync = { requested = 0, received = 0, rejected = 0, completed = 0 } end
    db.announcementSync.requested = tonumber(db.announcementSync.requested) or 0
    db.announcementSync.received = tonumber(db.announcementSync.received) or 0
    db.announcementSync.rejected = tonumber(db.announcementSync.rejected) or 0
    db.announcementSync.completed = tonumber(db.announcementSync.completed) or 0
end

local function ApplyDefault(tableValue, key, value)
    if tableValue[key] == nil then tableValue[key] = value end
end

local function PruneTimestampMap(map, maximum)
    if type(map) ~= "table" then return end
    local rows = {}
    local key, value, timestamp
    for key, value in pairs(map) do
        if type(value) == "table" then
            timestamp = tonumber(value.ts or value.updatedAt or value.updated or value.lastSeen or value.lastUsed or value.created) or 0
        else
            -- A malformed or very old scalar entry must be prunable without
            -- indexing it as a table and aborting the whole guild migration.
            timestamp = tonumber(value) or 0
        end
        table.insert(rows, { key = key, ts = timestamp })
    end
    if table.getn(rows) <= maximum then return end
    table.sort(rows, function(left, right)
        if left.ts ~= right.ts then return left.ts < right.ts end
        return tostring(left.key) < tostring(right.key)
    end)
    local index
    for index = 1, table.getn(rows) - maximum do map[rows[index].key] = nil end
end

local function EnsureFoundation170(db)
    if type(db.inbox170) ~= "table" then db.inbox170 = {} end
    if type(db.announcementAcknowledged170) ~= "table" then db.announcementAcknowledged170 = {} end
    if type(db.chatPins170) ~= "table" then db.chatPins170 = {} end
    if type(db.treasury170) ~= "table" then db.treasury170 = {} end
    if type(db.treasury170.goals) ~= "table" then db.treasury170.goals = {} end
    if type(db.treasury170.deleted) ~= "table" then db.treasury170.deleted = {} end
    if type(db.treasury170.history) ~= "table" then db.treasury170.history = {} end
    db.treasury170.revision = tonumber(db.treasury170.revision) or 0
    db.treasury170.mode = db.treasury170.mode or "PREVIEW"
    while table.getn(db.inbox170) > 80 do table.remove(db.inbox170) end
    while table.getn(db.chatPins170) > 30 do table.remove(db.chatPins170) end
    while table.getn(db.treasury170.history) > 40 do table.remove(db.treasury170.history) end
    if type(db.crafting) == "table" then
        if type(db.crafting.favorites170) ~= "table" then db.crafting.favorites170 = {} end
    end
end

function OTLGM:EnsureDB()
    EnsureRootShape170()
    if self.ApplySystemsDefaults then self:ApplySystemsDefaults()
    elseif self.ApplyAdvancedDefaults then self:ApplyAdvancedDefaults()
    elseif self.ApplyCoreDefaults then self:ApplyCoreDefaults()
    else
        OTLGM_DB = OTLGM_DB or {}
        OTLGM_DB.guilds = OTLGM_DB.guilds or {}
        OTLGM_DB.settings = OTLGM_DB.settings or {}
    end

    OTLGM_DB.guilds = OTLGM_DB.guilds or {}
    OTLGM_DB.settings = OTLGM_DB.settings or {}
    local settings = OTLGM_DB.settings

    ApplyDefault(settings, "pauseBulkSyncInCombat", true)
    ApplyDefault(settings, "networkPacketBudget", 5)
    ApplyDefault(settings, "motionMode170", "FULL")
    ApplyDefault(settings, "craftingLevelBasis170", "ITEM")
    ApplyDefault(settings, "recruitmentRotation170", {})
    ApplyDefault(settings, "nextRecruitIndex", 1)

    settings.uiScale = math.max(0.75, math.min(1.20, tonumber(settings.uiScale) or 1))
    settings.networkPacketBudget = math.max(2, math.min(8, tonumber(settings.networkPacketBudget) or 5))
    if settings.motionMode170 ~= "FULL" and settings.motionMode170 ~= "REDUCED" and settings.motionMode170 ~= "OFF" then settings.motionMode170 = "FULL" end
    if settings.craftingLevelBasis170 ~= "ITEM" and settings.craftingLevelBasis170 ~= "REQUIRED" and settings.craftingLevelBasis170 ~= "SKILL" then settings.craftingLevelBasis170 = "ITEM" end
    if type(settings.recruitmentRotation170) ~= "table" then settings.recruitmentRotation170 = {} end
    if tonumber(settings.nextRecruitIndex) ~= 1 and tonumber(settings.nextRecruitIndex) ~= 2 then settings.nextRecruitIndex = 1 else settings.nextRecruitIndex = tonumber(settings.nextRecruitIndex) end

    OTLGM_DB.version = self.version
    OTLGM_DB.schemaVersion = ROOT_SCHEMA
    return OTLGM_DB
end

function OTLGM:MigrateGuildDB(db)
    if type(db) ~= "table" then return nil end
    EnsureGuildContainers170(db)
    local before = tonumber(db.schemaVersion) or 0

    -- Normal reads use this constant-time path. Expensive legacy migration and
    -- pruning run only once when an older database is first opened.
    if before >= ROOT_SCHEMA and type(db.migration) == "table" and db.migration.foundation170 then
        db.roster = db.roster or {}
        db.log = db.log or {}
        db.daily = db.daily or {}
        db.pendingInvites = db.pendingInvites or {}
        db.pendingActions = db.pendingActions or {}
        if type(db.crafting) == "table" then
            if type(db.crafting.characters) ~= "table" then db.crafting.characters = {} end
            if type(db.crafting.details) ~= "table" then db.crafting.details = {} end
        end
        EnsureFoundation170(db)
        return db
    end

    if self.MigrateLegacySchema11 then self:MigrateLegacySchema11(db)
    elseif self.MigrateLegacySchema6 then self:MigrateLegacySchema6(db)
    elseif self.MigrateLegacySchema2 then self:MigrateLegacySchema2(db) end

    db.roster = db.roster or {}
    db.log = db.log or {}
    db.daily = db.daily or {}
    db.pendingInvites = db.pendingInvites or {}
    db.pendingActions = db.pendingActions or {}
    db.memberFlags = db.memberFlags or {}
    db.detectedVersions = db.detectedVersions or {}
    EnsureFoundation170(db)
    -- Pre-1.7 counters were detached from the underlying records and could
    -- leave permanent ghost badges. Content read-state is preserved; only the
    -- obsolete aggregate counters are cleared once during migration.
    if before < ROOT_SCHEMA and type(db.notificationUnread) == "table" then
        local notificationCategory
        for notificationCategory in pairs(db.notificationUnread) do db.notificationUnread[notificationCategory] = 0 end
    end

    if type(db.crafting) == "table" then
        local craft = db.crafting
        if type(craft.characters) ~= "table" then craft.characters = {} end
        if type(craft.requests) ~= "table" then craft.requests = {} end
        if type(craft.responses) ~= "table" then craft.responses = {} end
        if type(craft.reactions) ~= "table" then craft.reactions = {} end
        if type(craft.deleted) ~= "table" then craft.deleted = {} end
        if type(craft.events) ~= "table" then craft.events = {} end
        if type(craft.details) ~= "table" then craft.details = {} end
        if type(craft.favorites170) ~= "table" then craft.favorites170 = {} end

        -- Work queues contain session-only object references/chunks and must
        -- never be serialized into SavedVariables.
        craft.cacheQueue = nil
        craft.pendingRecipes = {}
        craft.syncState = { active = false, started = 0, completed = 0, received = 0 }

        local cache = craft.iconCache157
        if type(cache) == "table" then
            if type(cache.items) ~= "table" then cache.items = {} end
            if type(cache.names) ~= "table" then cache.names = {} end
            PruneTimestampMap(cache.items, 2000)
            PruneTimestampMap(cache.names, 2500)
        end
        PruneTimestampMap(craft.details, 1200)
        PruneTimestampMap(craft.favorites170, 400)
    end

    if type(db.pve) == "table" then
        db.pve.applicationRetries = {}
        db.pve.lastMaintenance = nil
    end

    if type(db.migration) ~= "table" then db.migration = {} end
    if before < ROOT_SCHEMA then
        db.migration.lastFrom = before
        db.migration.lastAt = self:Now()
        db.migration.architecture160 = true
    end
    db.migration.architecture160 = true
    db.migration.foundation170 = true
    PruneTimestampMap(db.detectedVersions, 1000)
    db.schemaVersion = ROOT_SCHEMA
    return db
end

function OTLGM:GetGuildDB()
    self:EnsureDB()
    local key = self:GuildKey()
    if not key then return nil end

    local db = OTLGM_DB.guilds[key]
    if type(db) ~= "table" then
        db = {
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
            schemaVersion = ROOT_SCHEMA,
        }
        OTLGM_DB.guilds[key] = db
    end

    self:MigrateGuildDB(db)
    return db
end

function OTLGM:ResetSessionData()
    self.runtime = {
        startedAt = self:Now(),
        craftingCacheQueue = {},
        craftingCacheHead = 1,
        receivedRate = {},
        dirtyPages = {},
        metrics = {
            refreshes = {},
            network = { queued = 0, sent = 0, retried = 0, dropped = 0, rejected = 0 },
        },
    }

    local db = self:GetGuildDB()
    if db and db.crafting then
        db.crafting.cacheQueue = nil
        db.crafting.pendingRecipes = {}
        db.crafting.syncState = { active = false, started = 0, completed = 0, received = 0 }
    end
    return self.runtime
end

OTLGM:RegisterModule("Database", {
    schema = ROOT_SCHEMA,
    owns = { "EnsureDB", "GetGuildDB", "MigrateGuildDB" },
})
