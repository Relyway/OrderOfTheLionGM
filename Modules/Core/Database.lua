-- Canonical SavedVariables owner and migration entry point.
-- Older modules expose named, idempotent migration stages; only this file owns
-- the public EnsureDB, GetGuildDB and MigrateGuildDB methods.

local ROOT_SCHEMA = 15
local C0_LIMITS = {
    migrationReport = 60,
    craftingMatchSeen = 400,
    characterProfiles = 20,
    groupMatchSeenPerCharacter = 400,
    raidAccessSeenPerCharacter = 400,
    raidTeams = 24,
    raidTeamDeleted = 120,
}

local function MigrationNow180()
    if time then return time() end
    return 0
end

local function RecordMigrationRepair180(scope, path, foundType, action)
    if type(OTLGM_DB) ~= "table" then return end
    if type(OTLGM_DB.migrationReport180) ~= "table" then OTLGM_DB.migrationReport180 = {} end
    local report = OTLGM_DB.migrationReport180
    local id = tostring(scope or "root") .. ":" .. tostring(path or "unknown") .. ":schema15"
    local index, entry
    for index = 1, table.getn(report) do
        entry = report[index]
        if type(entry) == "table" and entry.id == id then return end
    end
    table.insert(report, 1, {
        id = id,
        ts = MigrationNow180(),
        scope = tostring(scope or "root"),
        path = tostring(path or "unknown"),
        foundType = tostring(foundType or "unknown"),
        action = action or "replaced malformed scalar with an empty table",
    })
    while table.getn(report) > C0_LIMITS.migrationReport do table.remove(report) end
end

local function EnsureTable180(parent, key, scope, path)
    if type(parent[key]) ~= "table" then
        if parent[key] ~= nil then RecordMigrationRepair180(scope, path or key, type(parent[key])) end
        parent[key] = {}
    end
    return parent[key]
end

local function EnsureRootShape170()
    if type(OTLGM_DB) ~= "table" then OTLGM_DB = {} end
    if type(OTLGM_DB.migrationReport180) ~= "table" then OTLGM_DB.migrationReport180 = {} end
    if type(OTLGM_DB.guilds) ~= "table" then
        if OTLGM_DB.guilds ~= nil then RecordMigrationRepair180("account", "guilds", type(OTLGM_DB.guilds)) end
        OTLGM_DB.guilds = {}
    end
    if type(OTLGM_DB.settings) ~= "table" then
        if OTLGM_DB.settings ~= nil then RecordMigrationRepair180("account", "settings", type(OTLGM_DB.settings)) end
        OTLGM_DB.settings = {}
    end

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

local function EnsureAccountFoundation180()
    local accountPve = EnsureTable180(OTLGM_DB, "pve", "account", "pve")
    local profiles = EnsureTable180(accountPve, "characterProfiles180", "account", "pve.characterProfiles180")
    local groupSeen = EnsureTable180(accountPve, "groupMatchSeen180", "account", "pve.groupMatchSeen180")
    local raidSeen = EnsureTable180(accountPve, "raidAccessSeen180", "account", "pve.raidAccessSeen180")
    local key, value
    for key, value in pairs(profiles) do
        if type(value) ~= "table" then
            RecordMigrationRepair180("account", "pve.characterProfiles180." .. tostring(key), type(value))
            profiles[key] = {}
        end
    end
    for key, value in pairs(groupSeen) do
        if type(value) ~= "table" then
            RecordMigrationRepair180("account", "pve.groupMatchSeen180." .. tostring(key), type(value))
            groupSeen[key] = {}
        end
    end
    for key, value in pairs(raidSeen) do
        if type(value) ~= "table" then
            RecordMigrationRepair180("account", "pve.raidAccessSeen180." .. tostring(key), type(value))
            raidSeen[key] = {}
        end
    end
    return accountPve
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
        if type(db[key]) ~= "table" then
            if db[key] ~= nil then RecordMigrationRepair180("guild", key, type(db[key])) end
            db[key] = {}
        end
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
    -- RC5 fast path: the overwhelming steady-state case is already within its
    -- bound. Count first and avoid allocating one temporary row table per entry
    -- unless an actual prune is necessary.
    local count, countKey = 0, nil
    for countKey in pairs(map) do
        count = count + 1
        if count > maximum then break end
    end
    if count <= maximum then return end

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
    table.sort(rows, function(left, right)
        if left.ts ~= right.ts then return left.ts < right.ts end
        return tostring(left.key) < tostring(right.key)
    end)
    local index
    for index = 1, table.getn(rows) - maximum do map[rows[index].key] = nil end
end

local function PruneNestedTimestampMaps180(container, perCharacterMaximum, characterMaximum)
    if type(container) ~= "table" then return end
    local character, seen
    for character, seen in pairs(container) do
        if type(seen) ~= "table" then
            container[character] = nil
        else
            PruneTimestampMap(seen, perCharacterMaximum)
        end
    end
    PruneTimestampMap(container, characterMaximum)
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

local function NormalizeInboxRoutes180(db)
    local index, entry
    for index = table.getn(db.inbox170 or {}), 1, -1 do
        entry = db.inbox170[index]
        if type(entry) == "table" then
            if entry.objectType == nil and entry.targetType ~= nil then entry.objectType = entry.targetType end
            if entry.objectId == nil and entry.targetId ~= nil then entry.objectId = entry.targetId end
            if entry.section ~= nil then entry.section = tostring(entry.section) end
            if entry.actionKey ~= nil then entry.actionKey = tostring(entry.actionKey) end
            -- Frames and other runtime objects must never be retained by the
            -- canonical inbox route fields.
            if type(entry.objectType) ~= "string" then entry.objectType = nil end
            if type(entry.objectId) ~= "string" and type(entry.objectId) ~= "number" then entry.objectId = nil end
            if type(entry.section) ~= "string" then entry.section = nil end
            if type(entry.actionKey) ~= "string" then entry.actionKey = nil end
        end
    end
end

local function RecountNotificationUnread180(db)
    if type(db) ~= "table" then return end
    if type(db.notificationUnread) ~= "table" then db.notificationUnread = {} end

    -- Schema 14/R9 already stores the authoritative read state on inbox170
    -- entries. Rebuild aggregate counters from those records instead of
    -- clearing them during the schema 15 migration. This preserves real
    -- unread badges while also removing stale/ghost aggregate counts.
    local counts = {}
    local category
    for category in pairs(db.notificationUnread) do counts[category] = 0 end

    local index, entry
    for index = 1, table.getn(db.inbox170 or {}) do
        entry = db.inbox170[index]
        if type(entry) == "table" and entry.read ~= true then
            category = type(entry.category) == "string" and entry.category ~= "" and entry.category or "background"
            counts[category] = (tonumber(counts[category]) or 0) + 1
        end
    end

    for category in pairs(db.notificationUnread) do db.notificationUnread[category] = nil end
    for category, index in pairs(counts) do db.notificationUnread[category] = tonumber(index) or 0 end
end

local function EnsureStageC0GuildFoundation180(db)
    local craft = EnsureTable180(db, "crafting", "guild", "crafting")
    local craftFields = { "characters", "requests", "responses", "reactions", "deleted", "events", "details" }
    local index, key
    for index = 1, table.getn(craftFields) do
        key = craftFields[index]
        EnsureTable180(craft, key, "guild", "crafting." .. key)
    end
    EnsureTable180(craft, "requestMatchSeen180", "guild", "crafting.requestMatchSeen180")
    -- CMETA delivery-order reconciliation is runtime-only. A hand-edited or
    -- experimental persisted table is deliberately removed during migration.
    if craft.pendingRequestMeta180 ~= nil then
        RecordMigrationRepair180("guild", "crafting.pendingRequestMeta180", type(craft.pendingRequestMeta180), "removed persisted runtime-only cache")
        craft.pendingRequestMeta180 = nil
    end

    local pve = EnsureTable180(db, "pve", "guild", "pve")
    local pveFields = { "requests", "board", "applications", "deleted", "unread", "reminded", "raids", "applicationRetries" }
    for index = 1, table.getn(pveFields) do
        key = pveFields[index]
        EnsureTable180(pve, key, "guild", "pve." .. key)
    end
    local teams = EnsureTable180(pve, "raidTeams180", "guild", "pve.raidTeams180")
    local teamDeleted = EnsureTable180(pve, "raidTeamDeleted180", "guild", "pve.raidTeamDeleted180")
    local eventId, event
    for eventId, event in pairs(pve.raids) do
        if type(event) ~= "table" then
            RecordMigrationRepair180("guild", "pve.raids." .. tostring(eventId), type(event), "removed malformed event record")
            pve.raids[eventId] = nil
        else
            EnsureTable180(event, "roster180", "guild", "pve.raids." .. tostring(eventId) .. ".roster180")
        end
    end
    local teamId, team, primaryId
    for teamId, team in pairs(teams) do
        if type(team) ~= "table" then
            RecordMigrationRepair180("guild", "pve.raidTeams180." .. tostring(teamId), type(team), "removed malformed team record")
            teams[teamId] = nil
        else
            EnsureTable180(team, "members", "guild", "pve.raidTeams180." .. tostring(teamId) .. ".members")
            team.primary180 = team.primary180 == true and team.status ~= "ARCHIVED" or false
            if team.primary180 then
                if primaryId then
                    team.primary180 = false
                    RecordMigrationRepair180("guild", "pve.raidTeams180." .. tostring(teamId) .. ".primary180", "duplicate", "kept only one active Primary Raid Team")
                else primaryId = teamId end
            end
        end
    end
    local deletedId, tombstone
    for deletedId, tombstone in pairs(teamDeleted) do
        if type(tombstone) ~= "table" then
            RecordMigrationRepair180("guild", "pve.raidTeamDeleted180." .. tostring(deletedId), type(tombstone), "removed malformed team tombstone")
            teamDeleted[deletedId] = nil
        end
    end
    if pve.raidInviteSession180 ~= nil then
        RecordMigrationRepair180("guild", "pve.raidInviteSession180", type(pve.raidInviteSession180), "removed persisted runtime-only cache")
        pve.raidInviteSession180 = nil
    end

    NormalizeInboxRoutes180(db)
    PruneTimestampMap(craft.requestMatchSeen180, C0_LIMITS.craftingMatchSeen)
    PruneTimestampMap(teams, C0_LIMITS.raidTeams)
    PruneTimestampMap(teamDeleted, C0_LIMITS.raidTeamDeleted)
end

local function PruneAccountFoundation180(accountPve)
    if type(accountPve) ~= "table" then return end
    PruneTimestampMap(accountPve.characterProfiles180, C0_LIMITS.characterProfiles)
    PruneNestedTimestampMaps180(accountPve.groupMatchSeen180, C0_LIMITS.groupMatchSeenPerCharacter, C0_LIMITS.characterProfiles)
    PruneNestedTimestampMaps180(accountPve.raidAccessSeen180, C0_LIMITS.raidAccessSeenPerCharacter, C0_LIMITS.characterProfiles)
end

function OTLGM:EnsureDB()
    EnsureRootShape170()
    local accountPve = EnsureAccountFoundation180()
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
    ApplyDefault(settings, "networkPacketBudget", tonumber(self.networkPacketBudget180) or 2)
    ApplyDefault(settings, "motionMode170", "FULL")
    ApplyDefault(settings, "craftingLevelBasis170", "ITEM")
    ApplyDefault(settings, "recruitmentRotation170", {})
    ApplyDefault(settings, "nextRecruitIndex", 1)

    settings.uiScale = math.max(0.75, math.min(1.50, tonumber(settings.uiScale) or 1))
    if settings.uiScaleModeR2 ~= "FIT" then settings.uiScaleModeR2 = "FIXED" end
    settings.windowWidth180 = math.max(1000, math.min(2600, tonumber(settings.windowWidth180) or 1160))
    settings.windowHeight180 = math.max(700, math.min(1600, tonumber(settings.windowHeight180) or 740))
    if settings.windowSizePreset180 ~= "COMPACT" and settings.windowSizePreset180 ~= "NORMAL" and settings.windowSizePreset180 ~= "LARGE" and settings.windowSizePreset180 ~= "XL" and settings.windowSizePreset180 ~= "MAX" and settings.windowSizePreset180 ~= "CUSTOM" then
        settings.windowSizePreset180 = "NORMAL"
    end
    -- RC5: the queue budget is an internal transport contract, not a free
    -- user knob. Keep old SavedVariables compatible but normalize them to the
    -- same canonical value used by RuntimeCoordination and Transport.
    settings.networkPacketBudget = tonumber(self.networkPacketBudget180) or 2
    if settings.motionMode170 ~= "FULL" and settings.motionMode170 ~= "REDUCED" and settings.motionMode170 ~= "OFF" then settings.motionMode170 = "FULL" end
    if settings.craftingLevelBasis170 ~= "ITEM" and settings.craftingLevelBasis170 ~= "REQUIRED" and settings.craftingLevelBasis170 ~= "SKILL" then settings.craftingLevelBasis170 = "ITEM" end
    if type(settings.recruitmentRotation170) ~= "table" then settings.recruitmentRotation170 = {} end
    if tonumber(settings.nextRecruitIndex) ~= 1 and tonumber(settings.nextRecruitIndex) ~= 2 then settings.nextRecruitIndex = 1 else settings.nextRecruitIndex = tonumber(settings.nextRecruitIndex) end

    -- RC5: account PvE maps are already bounded at their write sites. The
    -- expensive full nested prune is therefore a migration/session maintenance
    -- task, not something every read-path EnsureDB call should repeat. Keep the
    -- one-shot flag on the addon object (not self.runtime) so ResetSessionData
    -- cannot accidentally make startup prune the same maps twice.
    if not self.accountFoundationPrunedRC5 then
        PruneAccountFoundation180(accountPve)
        self.accountFoundationPrunedRC5 = true
    end
    OTLGM_DB.version = self.version
    OTLGM_DB.schemaVersion = ROOT_SCHEMA
    return OTLGM_DB
end

function OTLGM:MigrateGuildDB(db)
    if type(db) ~= "table" then return nil end
    EnsureGuildContainers170(db)
    -- Repair nested canonical containers before any historical migration
    -- stage indexes them. This is what makes schema 15 safe for partially
    -- written or hand-edited R9 SavedVariables.
    EnsureStageC0GuildFoundation180(db)
    local before = tonumber(db.schemaVersion) or 0

    -- Normal reads use this constant-time path. Expensive legacy migration and
    -- pruning run only once when an older database is first opened.
    if before >= ROOT_SCHEMA and type(db.migration) == "table" and db.migration.stageC0Foundation180 then
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
        EnsureStageC0GuildFoundation180(db)
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
    -- Aggregate notification counters are derived from the authoritative
    -- inbox170 read flags. Recounting preserves R9 unread state during 14 -> 15
    -- while removing stale counters that no longer correspond to an entry.
    if before < ROOT_SCHEMA then RecountNotificationUnread180(db) end

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

    EnsureStageC0GuildFoundation180(db)

    if type(db.migration) ~= "table" then db.migration = {} end
    if before < ROOT_SCHEMA then
        db.migration.lastFrom = before
        db.migration.lastAt = self:Now()
        db.migration.architecture160 = true
    end
    db.migration.architecture160 = true
    db.migration.foundation170 = true
    db.migration.stageC0Foundation180 = true
    PruneTimestampMap(db.detectedVersions, 1000)
    db.schemaVersion = ROOT_SCHEMA
    return db
end

function OTLGM.__impl180.GetGuildDB__impl1(self)
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

function OTLGM:GetAccountPveDB180()
    self:EnsureDB()
    return EnsureAccountFoundation180()
end

function OTLGM:GetMigrationReport180()
    self:EnsureDB()
    return OTLGM_DB.migrationReport180
end

function OTLGM:PruneStageCFoundation180(db)
    local guildDb = db or self:GetGuildDB()
    if guildDb then EnsureStageC0GuildFoundation180(guildDb) end
    local accountPve = EnsureAccountFoundation180()
    PruneAccountFoundation180(accountPve)
    self.accountFoundationPrunedRC5 = true
    return guildDb, accountPve
end

function OTLGM:ResetSessionData()
    self.runtime = {
        startedAt = self:Now(),
        craftingCacheQueue = {},
        craftingCacheHead = 1,
        receivedRate = {},
        dirtyPages = {},
        crafting = {
            pendingRequestMeta180 = {},
        },
        pve = {
            pendingGroupMeta180 = {},
            pendingTeamPackets180 = {},
        },
        raidInviteSession180 = {},
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
    owns = { "EnsureDB", "GetGuildDB", "MigrateGuildDB", "GetAccountPveDB180", "PruneStageCFoundation180" },
})
