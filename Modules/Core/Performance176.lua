-- Order of the Lion Guild Manager v1.7.6
-- Performance, stability and low-cost quality-of-life layer.
-- Loaded after the 1.7.5 release layers so it can collapse duplicated work
-- without changing schema 14 or network protocol 3.
-- Vanilla / OctoWoW / Lua 5.0 compatible. No additional OnUpdate handler.

if not OTLGM then return end

OTLGM.legacyVersionPerformance176 = "1.7.6"
OTLGM.legacyBuildPerformance176 = "performance-r4-ultrasafe-20260725"

local P176 = {
    revision = 4,
    achievementDbHits = 0,
    achievementDbMisses = 0,
    duplicateGroupEvents = 0,
    blockedRaidNotices = 0,
    deferredGroupUpdates = 0,
    whisperInvites = 0,
    disabledTrackers = {},
    guildDbHits = 0,
    guildDbMisses = 0,
    domainCacheHits = 0,
    domainCacheMisses = 0,
    groupSnapshotHits = 0,
    groupSnapshotMisses = 0,
    duplicateGroupCalls = 0,
    uiDebounceCalls = 0,
    uiDebounceSkipped = 0,
    emptyNetworkTicks = 0,
    emptyCraftingTicks = 0,
    emptyCraftCacheTicks = 0,
    emptyTreasuryTicks = 0,
    maintenanceSkipped = 0,
    transitionWorldEntries = 0,
    transitionZoneEvents = 0,
    transitionEventsCoalesced = 0,
    transitionStablePasses = 0,
    transitionWorkDeferred = 0,
    sameZoneMinimapIgnored = 0,
    subzoneStateResets = 0,
    incrementalBagRequests = 0,
    incrementalBagScans = 0,
    incrementalBagSlots = 0,
    incrementalBagColdRetries = 0,
    incrementalBagRestarts = 0,
}
OTLGM.performance176 = P176

local MAX_SET_176 = 2200
local MAX_RECENT_WHISPERS_176 = 20
local MAX_CONTRIBUTIONS_PER_GOAL_176 = 50
local MAX_SYNC_CONTRIBUTIONS_176 = 120
local GROUP_CHECKPOINT_176 = 120
local RAID_NOTICE_GLOBAL_GUARD_176 = 180
local RAID_NOTICE_SAME_GUARD_176 = 1800
local COPPER_PER_GOLD_176 = 10000
local UI_DEBOUNCE_VISIBLE_176 = 0.05
local UI_DEBOUNCE_HIDDEN_176 = 0.50
local BACKGROUND_MAINTENANCE_176 = 300
local DUPLICATE_GROUP_WINDOW_176 = 1

local function Trim176(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function ShortName176(value)
    value = Trim176(value)
    local dash = string.find(value, "-", 1, true)
    if dash then value = string.sub(value, 1, dash - 1) end
    return value
end

local function NameKey176(value)
    return string.lower(ShortName176(value or ""))
end

local function ProgressKey176(value)
    value = string.lower(Trim176(value))
    value = string.gsub(value, "[%s%p%c]", "")
    return value
end

local function Clamp176(value, minimum, maximum)
    value = tonumber(value) or 0
    if minimum and value < minimum then value = minimum end
    if maximum and value > maximum then value = maximum end
    return value
end

local function Count176(tbl)
    local count = 0
    local key
    for key in pairs(tbl or {}) do count = count + 1 end
    return count
end

local function HasEntries176(tbl)
    if type(tbl) ~= "table" then return false end
    return next(tbl) ~= nil
end

local function SafeText176(value, maximum)
    if OTLGM.SafeText then return OTLGM:SafeText(value, maximum or 80, false, false) end
    value = Trim176(value)
    value = string.gsub(value, "[%c]", " ")
    if maximum and string.len(value) > maximum then value = string.sub(value, 1, maximum) end
    return value
end

local function Wire176(value, maximum)
    value = SafeText176(value, maximum)
    value = string.gsub(value, "^", "'")
    return value
end

local function Money176(copper)
    copper = math.max(0, math.floor(tonumber(copper) or 0))
    local gold = math.floor(copper / 10000)
    local silver = math.floor(math.mod(copper, 10000) / 100)
    local bronze = math.mod(copper, 100)
    if gold > 0 then return tostring(gold) .. "g " .. tostring(silver) .. "s" end
    if silver > 0 then return tostring(silver) .. "s " .. tostring(bronze) .. "c" end
    return tostring(bronze) .. "c"
end

local function ApplySimpleButton176(button, style)
    if not button then return end
    local disabled = button.disabled or button.otlDisabled
    local background = disabled and {0.08,0.08,0.08,0.92} or (style == "danger" and {0.30,0.06,0.04,0.96} or (style == "confirm" and {0.20,0.13,0.04,0.96} or {0.10,0.09,0.07,0.96}))
    local border = disabled and {0.22,0.22,0.22,1} or (style == "danger" and {0.82,0.20,0.12,1} or {0.58,0.42,0.16,1})
    if button.SetBackdrop then
        button:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=8,insets={left=1,right=1,top=1,bottom=1}})
        button:SetBackdropColor(background[1],background[2],background[3],background[4])
        button:SetBackdropBorderColor(border[1],border[2],border[3],border[4])
    end
    if button.text then button.text:SetTextColor(disabled and 0.45 or 1, disabled and 0.45 or 0.82, disabled and 0.45 or 0.34) end
end

local function SimpleText176(parent, fontObject, text, x, y, width, justify)
    local label = parent:CreateFontString(nil, "OVERLAY", fontObject or "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 0, y or 0)
    label:SetWidth(width or 200) label:SetJustifyH(justify or "LEFT") label:SetText(text or "")
    return label
end

local function SimpleButton176(parent, label, x, y, width, height, handler, style)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width or 100) button:SetHeight(height or 26)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 0, y or 0)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.text:SetPoint("CENTER", button, "CENTER", 0, 0) button.text:SetText(label or "")
    button:SetScript("OnClick", function() if not this.disabled and not this.otlDisabled and handler then handler(this) end end)
    ApplySimpleButton176(button, style)
    return button
end

local function IsVisibleAchievementPage176(self)
    return self.ui and self.ui.main and self.ui.main:IsVisible()
        and self.ui.currentPage == "achievements"
        and self.ui.achievementRows174
end

-- ---------------------------------------------------------------------------
-- Core database and feature-domain caches.
-- 1.7.5 repeatedly called EnsureDB/GetGuildDB from every timer branch. The
-- SavedVariables tables are stable for the whole guild session, so keep direct
-- runtime pointers and invalidate them only when the guild context changes.
-- ---------------------------------------------------------------------------

local PreviousGetGuildDB176 = OTLGM.__impl180.GetGuildDB__impl1

function OTLGM:InvalidatePerformanceDataCaches176()
    self.runtime = self.runtime or {}
    self.runtime.guildDbCache176 = nil
    self.runtime.featureDbCache176 = nil
    self.runtime.achievementDbCache176 = nil
    self.runtime.achievementSetCounts176 = nil
    self.runtime.groupSnapshot176 = nil
    self.runtime.groupSnapshotDirty176 = true
end

if PreviousGetGuildDB176 then
    function OTLGM:GetGuildDB()
        self.runtime = self.runtime or {}
        local key = self.GuildKey and self:GuildKey() or nil
        local cache = self.runtime.guildDbCache176
        local current = key and type(OTLGM_DB) == "table" and type(OTLGM_DB.guilds) == "table" and OTLGM_DB.guilds[key] or nil
        if key and cache and cache.key == key and type(cache.db) == "table" and current == cache.db then
            P176.guildDbHits = P176.guildDbHits + 1
            return cache.db
        end
        P176.guildDbMisses = P176.guildDbMisses + 1
        local db = PreviousGetGuildDB176(self)
        if key and type(db) == "table" then self.runtime.guildDbCache176 = { key=key, db=db } end
        return db
    end
end

local function InstallDomainCache176(methodName, cacheKey)
    local base = OTLGM[methodName]
    if type(base) ~= "function" then return end
    OTLGM[methodName] = function(self)
        self.runtime = self.runtime or {}
        self.runtime.featureDbCache176 = self.runtime.featureDbCache176 or {}
        local guildKey = self.GuildKey and self:GuildKey() or "noguild"
        local cached = self.runtime.featureDbCache176[cacheKey]
        local guildDb = type(OTLGM_DB) == "table" and type(OTLGM_DB.guilds) == "table" and OTLGM_DB.guilds[guildKey] or nil
        if cached and cached.guildKey == guildKey and cached.guildDb == guildDb and type(cached.db) == "table" then
            P176.domainCacheHits = P176.domainCacheHits + 1
            return cached.db
        end
        P176.domainCacheMisses = P176.domainCacheMisses + 1
        local db = base(self)
        guildDb = type(OTLGM_DB) == "table" and type(OTLGM_DB.guilds) == "table" and OTLGM_DB.guilds[guildKey] or nil
        if type(db) == "table" then self.runtime.featureDbCache176[cacheKey] = { guildKey=guildKey, guildDb=guildDb, db=db } end
        return db
    end
end

InstallDomainCache176("EnsureCraftingDB", "crafting")
InstallDomainCache176("EnsurePveDB", "pve")

-- ---------------------------------------------------------------------------
-- Achievement database cache.
-- The 1.7.5 path repeatedly revalidated the whole SavedVariables structure from
-- noisy events. Cache the already-migrated character table and invalidate only
-- when the character/guild context can actually change.
-- ---------------------------------------------------------------------------

local PreviousEnsureAchievements176 = OTLGM.__impl180.EnsureAchievements174__impl1

function OTLGM:InvalidateAchievementCache176()
    self.runtime = self.runtime or {}
    self.runtime.achievementDbCache176 = nil
    self.runtime.achievementSetCounts176 = nil
end

function OTLGM:EnsureAchievements174()
    self.runtime = self.runtime or {}
    local characterKey = self.GetAchievementCharacterKey174 and self:GetAchievementCharacterKey174() or "unknown"
    local guildKey = self.GuildKey and self:GuildKey() or "noguild"
    local catalogRevision = self.achievements174 and tonumber(self.achievements174.catalogRevision) or 0
    local cache = self.runtime.achievementDbCache176
    local liveGuild = type(OTLGM_DB) == "table" and type(OTLGM_DB.guilds) == "table" and OTLGM_DB.guilds[guildKey] or nil
    local liveStore = liveGuild and liveGuild.achievements174 and liveGuild.achievements174.characters and liveGuild.achievements174.characters[characterKey] or nil
    if cache and cache.db and cache.characterKey == characterKey and cache.guildKey == guildKey
        and tonumber(cache.catalogRevision) == catalogRevision and liveStore == cache.db then
        P176.achievementDbHits = P176.achievementDbHits + 1
        return cache.db
    end

    P176.achievementDbMisses = P176.achievementDbMisses + 1
    local db = PreviousEnsureAchievements176 and PreviousEnsureAchievements176(self) or nil
    if type(db) == "table" then
        self.runtime.achievementDbCache176 = {
            db = db,
            characterKey = characterKey,
            guildKey = guildKey,
            catalogRevision = catalogRevision,
        }
        self.runtime.achievementSetCounts176 = nil
    end
    return db
end

function OTLGM:IsAchievementComplete174(id)
    local db = self:EnsureAchievements174()
    return db and db.completed and db.completed[id] ~= nil
end

function OTLGM:GetAchievementCompletedAt174(id)
    local db = self:EnsureAchievements174()
    local record = db and db.completed and db.completed[id]
    if type(record) == "table" then return tonumber(record.unlockedAt) end
    return tonumber(record)
end

function OTLGM:GetAchievementCount174()
    local db = self:EnsureAchievements174()
    local count = 0
    local id
    local byId = self.achievements174 and self.achievements174.byId or {}
    for id in pairs(db and db.completed or {}) do if byId[id] then count = count + 1 end end
    return count, table.getn(self.achievements174 and self.achievements174.catalog or {})
end

function OTLGM:GetAchievementSet174(key)
    local db = self:EnsureAchievements174()
    if not db then return {} end
    db.sets = type(db.sets) == "table" and db.sets or {}
    if type(db.sets[key]) ~= "table" then db.sets[key] = {} end
    return db.sets[key]
end

local function GetSetCount176(self, key, set)
    self.runtime = self.runtime or {}
    self.runtime.achievementSetCounts176 = self.runtime.achievementSetCounts176 or {}
    local cached = self.runtime.achievementSetCounts176[key]
    if cached ~= nil then return cached end
    cached = Count176(set)
    self.runtime.achievementSetCounts176[key] = cached
    return cached
end

local function SetSetCount176(self, key, value)
    self.runtime = self.runtime or {}
    self.runtime.achievementSetCounts176 = self.runtime.achievementSetCounts176 or {}
    self.runtime.achievementSetCounts176[key] = math.max(0, tonumber(value) or 0)
end

-- Build a direct progress-key index for C-series thresholds. Instead of scanning
-- every threshold after any counter change, only the 1-5 definitions that share
-- the changed counter are evaluated.
local THRESHOLDS_176 = {}

local function RebuildThresholdIndex176()
    THRESHOLDS_176 = {}
    local catalog = OTLGM.achievements174 and OTLGM.achievements174.catalog or {}
    local index, def, key
    for index = 1, table.getn(catalog) do
        def = catalog[index]
        if def and string.sub(tostring(def.id or ""), 1, 1) == "C" and def.progress then
            key = tostring(def.progress)
            THRESHOLDS_176[key] = THRESHOLDS_176[key] or {}
            table.insert(THRESHOLDS_176[key], def)
        end
    end
end
RebuildThresholdIndex176()

local SET_PROGRESS_176 = {
    resurrectedGuild = true,
    sharedPartners = true,
    crafterContacts = true,
    announcementReactions = true,
}

local thresholdGuard176 = false
local function EvaluateThresholdProgress176(self, progress, silent)
    if thresholdGuard176 then return end
    local definitions = THRESHOLDS_176[progress]
    if not definitions then return end
    thresholdGuard176 = true
    local db = self:EnsureAchievements174()
    local value
    if SET_PROGRESS_176[progress] then
        local set = self:GetAchievementSet174(progress)
        value = GetSetCount176(self, progress, set)
    else
        value = tonumber(db and db.counters and db.counters[progress]) or 0
    end
    local index, def
    for index = 1, table.getn(definitions) do
        def = definitions[index]
        if not self:IsAchievementComplete174(def.id) and value >= (tonumber(def.required) or 1) then
            self:CompleteAchievement174(def.id, silent and true or false)
        end
    end
    thresholdGuard176 = false
end

function OTLGM:AddAchievementSetValue174(key, value)
    value = ProgressKey176(value)
    if value == "" then return false end
    local set = self:GetAchievementSet174(key)
    if set[value] then return false end
    local count = GetSetCount176(self, key, set)
    if count >= MAX_SET_176 then return false end
    set[value] = true
    SetSetCount176(self, key, count + 1)
    EvaluateThresholdProgress176(self, key, false)
    return true
end

function OTLGM:AddAchievementCounter174(key, amount)
    local db = self:EnsureAchievements174()
    if not db then return 0 end
    db.counters = type(db.counters) == "table" and db.counters or {}
    local old = Clamp176(db.counters[key], 0, 1000000000)
    local value = math.min(1000000000, old + Clamp176(amount, 0, 1000000000))
    if value == old then return old end
    db.counters[key] = value
    EvaluateThresholdProgress176(self, key, false)
    return value
end

function OTLGM:SetAchievementCounter174(key, value)
    local db = self:EnsureAchievements174()
    if not db then return 0 end
    db.counters = type(db.counters) == "table" and db.counters or {}
    value = Clamp176(value, 0, 1000000000)
    local old = Clamp176(db.counters[key], 0, 1000000000)
    if old == value then return old end
    db.counters[key] = value
    EvaluateThresholdProgress176(self, key, false)
    return value
end

-- R4 installed broad post-action threshold scans. Keep the underlying action but
-- hold its public guard while our direct progress-key evaluator handles changes.
local function WithLegacyThresholdGuard176(callback)
    local r4 = OTLGM.release175r4
    local previous = r4 and r4.thresholdGuard
    if r4 then r4.thresholdGuard = true end
    local ok, a, b, c, d = pcall(callback)
    if r4 then r4.thresholdGuard = previous end
    if not ok then error(a) end
    return a, b, c, d
end

local PreviousGetGroupSnapshot176 = OTLGM.__impl180.GetGroupSnapshot174__impl1
if PreviousGetGroupSnapshot176 then
    function OTLGM:GetGroupSnapshot174()
        self.runtime = self.runtime or {}
        local now = self:Now()
        local cached = self.runtime.groupSnapshot176
        if cached and not self.runtime.groupSnapshotDirty176 and tonumber(cached.ts) == now and cached.value then
            P176.groupSnapshotHits = P176.groupSnapshotHits + 1
            return cached.value
        end
        P176.groupSnapshotMisses = P176.groupSnapshotMisses + 1
        local value = PreviousGetGroupSnapshot176(self)
        self.runtime.groupSnapshot176 = { ts=now, value=value }
        self.runtime.groupSnapshotDirty176 = nil
        return value
    end
end

local PreviousUpdateGroupSession176 = OTLGM.__impl180.UpdateGroupSession174__impl3
if PreviousUpdateGroupSession176 then
    function OTLGM.__impl180.UpdateGroupSession174__impl4(self, silent)
        self.runtime = self.runtime or {}
        local now = self:Now()
        if self.runtime.groupUpdateRunning176 then
            P176.duplicateGroupCalls = P176.duplicateGroupCalls + 1
            return self.runtime.achievementGroup174
        end
        if self.runtime.lastGroupUpdate176 and now - self.runtime.lastGroupUpdate176 < DUPLICATE_GROUP_WINDOW_176
            and self.runtime.achievementGroup174 then
            P176.duplicateGroupCalls = P176.duplicateGroupCalls + 1
            return self.runtime.achievementGroup174
        end
        self.runtime.groupUpdateRunning176 = true
        local ok, result = pcall(function()
            return WithLegacyThresholdGuard176(function() return PreviousUpdateGroupSession176(self, silent) end)
        end)
        self.runtime.groupUpdateRunning176 = nil
        self.runtime.lastGroupUpdate176 = now
        if not ok then error(result) end
        EvaluateThresholdProgress176(self, "groupSeconds", silent and true or false)
        if self.runtime.groupSession174 then self.runtime.achievementGroupTickAt174 = now + GROUP_CHECKPOINT_176 end
        return result
    end
end

local PreviousRecordGroupApplication176 = OTLGM.__impl180.RecordGroupApplication174__impl2
if PreviousRecordGroupApplication176 then
    function OTLGM:RecordGroupApplication174(group, record)
        return WithLegacyThresholdGuard176(function() return PreviousRecordGroupApplication176(self, group, record) end)
    end
end

local PreviousCheckResurrection176 = OTLGM.__impl180.CheckResurrection175__impl3
if PreviousCheckResurrection176 then
    function OTLGM:CheckResurrection175()
        return WithLegacyThresholdGuard176(function() return PreviousCheckResurrection176(self) end)
    end
end

-- Do not rebuild a hidden 146-entry page when an achievement unlocks in combat.
local PreviousRefreshAchievements176 = OTLGM.__impl180.RefreshAchievements174__impl5
if PreviousRefreshAchievements176 then
    function OTLGM.__impl180.RefreshAchievements174__impl6(self)
        self.runtime = self.runtime or {}
        if not IsVisibleAchievementPage176(self) then
            self.runtime.achievementUiDirty176 = true
            return
        end
        self.runtime.achievementUiDirty176 = nil
        return PreviousRefreshAchievements176(self)
    end
end

-- Avoid entering the database path every heartbeat when there is no queued guild
-- achievement announcement.
local PreviousProcessAchievementAnnouncements176 = OTLGM.__impl180.ProcessAchievementGuildAnnouncements174__impl1
if PreviousProcessAchievementAnnouncements176 then
    function OTLGM:ProcessAchievementGuildAnnouncements174()
        local queue = self.runtime and self.runtime.achievementGuildQueue174
        if not queue or table.getn(queue) == 0 then return end
        return PreviousProcessAchievementAnnouncements176(self)
    end
end

-- Roster cache refreshes can be requested by several frames for the same server
-- event. Rebuild at most once per two seconds and otherwise mark it dirty.
local PreviousRefreshAchievementRoster176 = OTLGM.__impl180.RefreshAchievementRosterCache174__impl1
if PreviousRefreshAchievementRoster176 then
    function OTLGM:RefreshAchievementRosterCache174(force)
        self.runtime = self.runtime or {}
        local cache = self.runtime.achievementRosterCache174
        local now = self:Now()
        if force then self.runtime.achievementRosterDirty176 = true end
        if cache and self.runtime.achievementRosterDirty176 and now - (tonumber(cache.builtAt) or 0) < 2 then
            return cache
        end
        if cache and not self.runtime.achievementRosterDirty176 then return cache end
        local rebuilt = PreviousRefreshAchievementRoster176(self, true)
        self.runtime.achievementRosterDirty176 = nil
        return rebuilt
    end
end

-- ---------------------------------------------------------------------------
-- Event consolidation.
-- Remove the single worst high-frequency listener and collapse duplicated group,
-- zone and guild-roster work into one deferred pass on the existing heartbeat.
-- ---------------------------------------------------------------------------

local function Unregister176(frameName, eventName)
    local frame = getglobal and getglobal(frameName) or nil
    if frame and frame.UnregisterEvent then pcall(frame.UnregisterEvent, frame, eventName) return true end
    return false
end

-- UNIT_HEALTH was unnecessary for resurrection because ProcessRelease175Timers
-- already checks active resurrection state once per heartbeat. Diplomatic Incident
-- remains checked on death/group/zone transitions.
if Unregister176("OTLGM_ReleaseEvent175", "UNIT_HEALTH") then
    P176.disabledTrackers.unitHealth = true
end
-- Login-wide achievement scans are deferred until the cold loading window has
-- settled. Core/Events schedules the two canonical baseline methods once.
if Unregister176("OTLGM_AchievementsEvent174", "PLAYER_LOGIN") then
    P176.disabledTrackers.immediateAchievementLogin = true
end
if Unregister176("OTLGM_ReleaseEvent175", "PLAYER_LOGIN") then
    P176.disabledTrackers.immediateReleaseLogin = true
end

-- Achievements174 remains the single canonical world-entry achievement pass.
-- Release175 repeated the same group update immediately after it.
if Unregister176("OTLGM_ReleaseEvent175", "PLAYER_ENTERING_WORLD") then
    P176.disabledTrackers.duplicateWorldEntry = true
end

local duplicatedEvents176 = {
    "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE", "GUILD_ROSTER_UPDATE",
    "PLAYER_GUILD_UPDATE", "ZONE_CHANGED_NEW_AREA", "MINIMAP_ZONE_CHANGED",
}
local index176, eventName176
for index176 = 1, table.getn(duplicatedEvents176) do
    eventName176 = duplicatedEvents176[index176]
    Unregister176("OTLGM_AchievementsEvent174", eventName176)
    Unregister176("OTLGM_ReleaseEvent175", eventName176)
end

-- Bag achievements are now checked on login/world entry instead of rescanning all
-- bags after every loot/use/move burst. Fall-death tracking is paused because it
-- required parsing every self-damage combat line.
Unregister176("OTLGM_ReleaseEvent175R6", "BAG_UPDATE")
Unregister176("OTLGM_ReleaseEvent175R6", "CHAT_MSG_COMBAT_SELF_HITS")
Unregister176("OTLGM_ReleaseEvent175R6", "CHAT_MSG_SPELL_SELF_DAMAGE")
-- RC3: keep GUILD_ROSTER_UPDATE ownership bounded. Core/Events owns roster
-- workflow and Performance176 owns achievement cache invalidation. Legacy frames
-- only duplicated tiny side effects, now handled by the canonical owners.
Unregister176("OTLGM_ReleaseEvent175R6", "GUILD_ROSTER_UPDATE")
Unregister176("OTLGM_Release175R4Event", "GUILD_ROSTER_UPDATE")
Unregister176("OTLGM_PveProfileEvent180", "GUILD_ROSTER_UPDATE")
P176.disabledTrackers.liveBagScan = true
P176.disabledTrackers.gravityWins = true

local risky = OTLGM.achievements174 and OTLGM.achievements174.byId and OTLGM.achievements174.byId.D021
if risky and not OTLGM:IsAchievementComplete174("D021") then
    risky.performancePaused176 = true
    risky.description = "Tracking paused in 1.7.6 because continuous fall-damage combat-log parsing could cause stutter."
    risky.revealed = risky.description
end

local PreviousCompleteAchievement176 = OTLGM.__impl180.CompleteAchievement174__impl2
if PreviousCompleteAchievement176 then
    function OTLGM:CompleteAchievement174(id, silent)
        local def = self.achievements174 and self.achievements174.byId and self.achievements174.byId[id]
        if def and def.performancePaused176 and not self:IsAchievementComplete174(id) then return false end
        local changed = PreviousCompleteAchievement176(self, id, silent)
        -- The final bridge owns several listeners only while their achievement
        -- is incomplete. Release that ownership at the exact completion point,
        -- regardless of which legacy/runtime frame awarded it. The bridge is
        -- declared later in this file, so the conditional also stays safe during
        -- addon construction.
        if changed and self.UpdateFinalAchievementOwnership180 then self:UpdateFinalAchievementOwnership180() end
        return changed
    end
end

local PreviousAchievementPresentation176 = OTLGM.__impl180.GetAchievementPresentation174__impl2
if PreviousAchievementPresentation176 then
    function OTLGM:GetAchievementPresentation174(def, complete)
        if def and def.performancePaused176 and not complete then
            return def.name, def.description, def.icon or "Interface\\Icons\\INV_Misc_QuestionMark", true
        end
        return PreviousAchievementPresentation176(self, def, complete)
    end
end

function OTLGM:ScheduleAchievementGroupRefresh176(reason)
    self.runtime = self.runtime or {}
    self.runtime.groupSnapshotDirty176 = true
    local due = self:Now() + 1
    if self.runtime.performanceGroupDue176 and self.runtime.performanceGroupDue176 <= due then
        P176.duplicateGroupEvents = P176.duplicateGroupEvents + 1
        return
    end
    self.runtime.performanceGroupDue176 = due
    self.runtime.performanceGroupReason176 = reason or "event"
    P176.deferredGroupUpdates = P176.deferredGroupUpdates + 1
    if self.WakeScheduler180 then self:WakeScheduler180("achievement-group") end
end

local eventFrame176 = CreateFrame("Frame", "OTLGM_PerformanceEvent176")
for index176 = 1, table.getn(duplicatedEvents176) do eventFrame176:RegisterEvent(duplicatedEvents176[index176]) end
eventFrame176:RegisterEvent("CHAT_MSG_WHISPER")
eventFrame176:RegisterEvent("VARIABLES_LOADED")
eventFrame176:RegisterEvent("PLAYER_LOGIN")

eventFrame176:SetScript("OnEvent", function()
    if not OTLGM then return end
    OTLGM.runtime = OTLGM.runtime or {}
    if event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        OTLGM.runtime.reunionSignature175 = nil
        OTLGM.runtime.proudLion175 = nil
        OTLGM:ScheduleAchievementGroupRefresh176(event)
    elseif event == "GUILD_ROSTER_UPDATE" then
        OTLGM.runtime.achievementRosterDirty176 = true
        OTLGM.runtime.groupSnapshotDirty176 = true
        OTLGM.runtime.guildLeader175 = nil
        OTLGM.runtime.guildLeaderR6 = nil
        OTLGM.runtime.guildLeader176 = nil
    elseif event == "PLAYER_GUILD_UPDATE" then
        OTLGM:InvalidatePerformanceDataCaches176()
        OTLGM.runtime.achievementRosterDirty176 = true
        if OTLGM.UpdateMembershipPeriod174 then OTLGM:UpdateMembershipPeriod174() end
        OTLGM:ScheduleAchievementGroupRefresh176(event)
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "MINIMAP_ZONE_CHANGED" then
        OTLGM.runtime.proudLion175 = nil
        OTLGM.runtime.regularTable175 = nil
        OTLGM.runtime.groupStates175 = {}
        OTLGM.runtime.bossEncounter174 = nil
        OTLGM.runtime.bossEncounter175 = nil
        OTLGM.runtime.bossAttempts175 = {}
        OTLGM.runtime.roarWindow174 = nil
        OTLGM.runtime.kneelWindow174 = nil
        OTLGM.runtime.danceWindow174 = nil
        OTLGM:ScheduleAchievementGroupRefresh176(event)
        -- Boss-combat listeners are now context-owned. Re-evaluate them on a
        -- zone transition so high-frequency target/combat text stays detached
        -- everywhere it cannot possibly contribute to an instance achievement.
        if OTLGM.UpdateFinalAchievementOwnership180 then OTLGM:UpdateFinalAchievementOwnership180() end
    elseif event == "CHAT_MSG_WHISPER" then
        if OTLGM.CaptureRecentWhisper176 then OTLGM:CaptureRecentWhisper176(arg2, arg1) end
    elseif event == "VARIABLES_LOADED" or event == "PLAYER_LOGIN" then
        OTLGM:InvalidatePerformanceDataCaches176()
        RebuildThresholdIndex176()
    end
end)

-- ---------------------------------------------------------------------------
-- Raid-notification storm guard.
-- One identical notice per 30 minutes and no more than one visual/sound notice
-- every three minutes. Unread counters and raid data still update normally.
-- ---------------------------------------------------------------------------

local function RaidFingerprint176(title, body)
    local text = string.lower(Trim176(tostring(title or "") .. "|" .. tostring(body or "")))
    text = string.gsub(text, "%s+", " ")
    return text
end

local PreviousShowPveRaidNotice176 = OTLGM.__impl180.ShowPveRaidNotice__impl1
if PreviousShowPveRaidNotice176 then
    function OTLGM:ShowPveRaidNotice(title, body, remote)
        self.runtime = self.runtime or {}
        local now = self:Now()
        local fingerprint = RaidFingerprint176(title, body)
        self.runtime.raidNoticeSeen176 = self.runtime.raidNoticeSeen176 or {}
        local sameAt = tonumber(self.runtime.raidNoticeSeen176[fingerprint]) or 0
        local globalAt = tonumber(self.runtime.lastRaidNotice176) or 0
        if (sameAt > 0 and now - sameAt < RAID_NOTICE_SAME_GUARD_176)
            or (globalAt > 0 and now - globalAt < RAID_NOTICE_GLOBAL_GUARD_176) then
            P176.blockedRaidNotices = P176.blockedRaidNotices + 1
            return false
        end
        self.runtime.raidNoticeSeen176[fingerprint] = now
        self.runtime.lastRaidNotice176 = now
        return PreviousShowPveRaidNotice176(self, title, body, remote)
    end
end

-- ---------------------------------------------------------------------------
-- Recent whisper invite helper. Runtime-only: no chat text is written to saved
-- variables. The recruitment page gets one compact button that opens five recent
-- senders and lets an authorized member issue GuildInvite directly.
-- ---------------------------------------------------------------------------

function OTLGM:CaptureRecentWhisper176(sender, message)
    sender = ShortName176(sender)
    if sender == "" or NameKey176(sender) == NameKey176(UnitName and UnitName("player") or "") then return end
    -- Capture starts with an external candidate.  Existing entries are retained
    -- through the external -> joined transition for this session, without text.
    if self.GetMember and self:GetMember(sender) then return end
    self.runtime = self.runtime or {}
    local old = self.runtime.recentWhispers176 or {}
    local nextList = { { name = sender, ts = self:Now(), state180 = "EXTERNAL" } }
    local index, row
    for index = 1, table.getn(old) do
        row = old[index]
        if row and NameKey176(row.name) ~= NameKey176(sender)
            and table.getn(nextList) < MAX_RECENT_WHISPERS_176 then
            table.insert(nextList, {
                name = row.name, ts = row.ts, inviteSentAt176 = row.inviteSentAt176,
                welcomedAt176 = row.welcomedAt176, state180 = row.state180,
            })
        end
    end
    self.runtime.recentWhispers176 = nextList
    if self.ui and ((self.ui.recentWhisperDialog176 and self.ui.recentWhisperDialog176:IsVisible())
        or (self.ui.recentWhispersDrawer180 and self.ui.recentWhispersDrawer180:IsVisible())) then self:RefreshRecentWhispers176() end
end

function OTLGM.__impl180.BuildRecentWhisperDialog176__impl1(self)
    self.ui = self.ui or {}
    if self.ui.recentWhisperDialog176 or not UIParent then return end
    local dialog = CreateFrame("Frame", "OTLGM_RecentWhispers176", UIParent)
    dialog:SetWidth(520) dialog:SetHeight(330)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetFrameLevel(120)
    dialog:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=14, insets={left=5,right=5,top=5,bottom=5} })
    dialog:SetBackdropColor(0.015,0.016,0.018,0.995)
    dialog:SetBackdropBorderColor(0.72,0.48,0.16,1)
    dialog:EnableMouse(true)
    dialog:SetMovable(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", function() this:StartMoving() end)
    dialog:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    dialog:Hide()
    self.ui.recentWhisperDialog176 = dialog

    SimpleText176(dialog, "GameFontNormalLarge", "Recent Recruitment Whispers", 18, -16, 380, "LEFT")
    local subtitle = SimpleText176(dialog, "GameFontNormalSmall", "The five latest unique whisper senders from this session. Message text is not saved.", 18, -44, 470, "LEFT")
    subtitle:SetTextColor(0.66,0.66,0.63)
    SimpleButton176(dialog, "X", 474, -12, 28, 26, function() dialog:Hide() end, "danger")
    dialog.rows176 = {}
    local index
    for index = 1, MAX_RECENT_WHISPERS_176 do
        local row = CreateFrame("Frame", nil, dialog)
        row:SetPoint("TOPLEFT", dialog, "TOPLEFT", 18, -76 - ((index - 1) * 46))
        row:SetWidth(484) row:SetHeight(40)
        row:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=8, insets={left=2,right=2,top=2,bottom=2} })
        row:SetBackdropColor(0.028,0.028,0.028,0.98)
        row:SetBackdropBorderColor(0.24,0.22,0.18,1)
        row.name176 = SimpleText176(row, "GameFontNormal", "", 10, -6, 150, "LEFT")
        row.snippet176 = SimpleText176(row, "GameFontNormalSmall", "", 160, -7, 220, "LEFT")
        row.snippet176:SetTextColor(0.62,0.62,0.60)
        local capturedIndex = index
        row.invite176 = SimpleButton176(row, "Invite", 390, -6, 82, 27, function()
            local entries = OTLGM.runtime and OTLGM.runtime.recentWhispers176 or {}
            local entry = entries[capturedIndex]
            if entry and OTLGM:InviteRecentWhisper176(entry.name) then dialog:Hide() end
        end, "confirm")
        dialog.rows176[index] = row
    end
end

function OTLGM.__impl180.RefreshRecentWhispers176__impl1(self)
    self:BuildRecentWhisperDialog176()
    local dialog = self.ui and self.ui.recentWhisperDialog176
    if not dialog then return end
    local entries = self.runtime and self.runtime.recentWhispers176 or {}
    local index, row, entry, age
    for index = 1, MAX_RECENT_WHISPERS_176 do
        row = dialog.rows176[index]
        entry = entries[index]
        if entry then
            age = math.max(0, math.floor((self:Now() - (tonumber(entry.ts) or self:Now())) / 60))
            row.name176:SetText(entry.name .. (age > 0 and ("  |cff777777" .. tostring(age) .. "m|r") or ""))
            row.snippet176:SetText("External candidate")
            row.invite176.disabled = nil
            if row.invite176.Enable then row.invite176:Enable() end
            ApplySimpleButton176(row.invite176, "confirm")
            row:Show()
        else
            row.name176:SetText("No recent whisper")
            row.snippet176:SetText("")
            row.invite176.disabled = true
            if row.invite176.Disable then row.invite176:Disable() end
            ApplySimpleButton176(row.invite176, "confirm")
            row:Show()
        end
    end
end

function OTLGM.__impl180.OpenRecentWhispers176__impl1(self)
    self:BuildRecentWhisperDialog176()
    self:RefreshRecentWhispers176()
    if self.ui and self.ui.recentWhisperDialog176 then self.ui.recentWhisperDialog176:Show() end
end

local PreviousBuildRecruitment176 = OTLGM.__impl180.BuildRecruitmentPage__impl2
if PreviousBuildRecruitment176 then
    function OTLGM.__impl180.BuildRecruitmentPage__impl3(self, page)
        local result = PreviousBuildRecruitment176(self, page)
        if page and not self.ui.recentWhisperButton176 then
            self.ui.recentWhisperButton176 = SimpleButton176(page, "Recent Whispers", 584, -2, 134, 26, function() OTLGM:OpenRecentWhispers176() end, "utility")
        end
        return result
    end
end

-- Also expose the helper without requiring the page to be open.
local PreviousSlashOTL176 = SlashCmdList and SlashCmdList["OTLGM"]
if SlashCmdList and PreviousSlashOTL176 then
    SlashCmdList["OTLGM"] = function(message)
        local lowered = string.lower(Trim176(message or ""))
        if lowered == "whispers" or lowered == "recent" then OTLGM:OpenRecentWhispers176() return end
        return PreviousSlashOTL176(message)
    end
end

-- ---------------------------------------------------------------------------
-- Treasury contribution ledger.
-- A contribution is an explicit leadership action: contributor + amount + goal.
-- It increments the shared total, records a bounded per-goal ledger and syncs the
-- latest entries. It never reads mail or moves currency/items.
-- ---------------------------------------------------------------------------

local PreviousEnsureTreasury176 = OTLGM.__impl180.EnsureTreasury170__impl1
if PreviousEnsureTreasury176 then
    function OTLGM:EnsureTreasury170()
        local treasury = PreviousEnsureTreasury176(self)
        if not treasury then return nil end
        if type(treasury.contributions176) ~= "table" then treasury.contributions176 = {} end
        if type(treasury.contributionSeen176) ~= "table" then treasury.contributionSeen176 = {} end
        if not treasury.contributionsSanitized176 then
            local goalId, entries, safe, index, entry
            for goalId, entries in pairs(treasury.contributions176) do
                safe = {}
                if type(entries) == "table" then
                    for index = 1, math.min(MAX_CONTRIBUTIONS_PER_GOAL_176, table.getn(entries)) do
                        entry = entries[index]
                        if type(entry) == "table" and SafeText176(entry.id, 48) ~= "" and (tonumber(entry.amount) or 0) > 0 then
                            table.insert(safe, {
                                id = SafeText176(entry.id, 48),
                                ts = math.max(0, tonumber(entry.ts) or 0),
                                actor = SafeText176(entry.actor or "Leadership", 28),
                                contributor = SafeText176(entry.contributor or "Anonymous", 28),
                                amount = math.max(1, math.floor(tonumber(entry.amount) or 0)),
                                note = SafeText176(entry.note or "", 64),
                                current = math.max(0, math.floor(tonumber(entry.current) or 0)),
                            })
                        end
                    end
                end
                treasury.contributions176[goalId] = safe
            end
            treasury.contributionsSanitized176 = true
        end
        return treasury
    end
end

function OTLGM:GetTreasuryContributions176(goalId)
    local treasury = self:EnsureTreasury170()
    if not treasury then return {} end
    local entries = treasury.contributions176[goalId]
    if type(entries) ~= "table" then entries = {} treasury.contributions176[goalId] = entries end
    return entries
end

local function ContributionPayload176(self, goalId, entry, target)
    if not self.QueueNetworkPayload or not entry then return false end
    local payload = table.concat({
        self.treasuryProtocol170 or "B1", "CONTRIB", Wire176(goalId, 32), Wire176(entry.id, 48),
        tostring(math.floor(entry.ts or self:Now())), Wire176(entry.actor, 28), Wire176(entry.contributor, 28),
        tostring(math.floor(entry.amount or 0)), Wire176(entry.note, 64), tostring(math.floor(entry.current or 0)),
    }, "^")
    local channel = target and "WHISPER" or "GUILD"
    return self:QueueNetworkPayload(payload, channel, target, target and 3 or 2, "treasury", "treasury:contribution:" .. tostring(entry.id))
end

local function InsertContribution176(self, goalId, entry)
    local treasury = self:EnsureTreasury170()
    if not treasury or not entry or not entry.id then return false end
    if treasury.contributionSeen176[entry.id] then return false end
    treasury.contributionSeen176[entry.id] = entry.ts or self:Now()
    if Count176(treasury.contributionSeen176) > 400 then
        local oldestId, oldestTs
        local seenId, seenTs
        for seenId, seenTs in pairs(treasury.contributionSeen176) do
            if not oldestTs or (tonumber(seenTs) or 0) < oldestTs then oldestId = seenId oldestTs = tonumber(seenTs) or 0 end
        end
        if oldestId then treasury.contributionSeen176[oldestId] = nil end
    end
    local entries = self:GetTreasuryContributions176(goalId)
    table.insert(entries, 1, entry)
    while table.getn(entries) > MAX_CONTRIBUTIONS_PER_GOAL_176 do table.remove(entries) end
    local goal = treasury.goals and treasury.goals[goalId]
    if goal and (tonumber(entry.current) or 0) > (tonumber(goal.current) or 0) then
        goal.current = tonumber(entry.current) or goal.current
        goal.updatedAt = math.max(tonumber(goal.updatedAt) or 0, tonumber(entry.ts) or 0)
        goal.updatedBy = entry.actor or goal.updatedBy
    end
    self.runtime = self.runtime or {}
    self.runtime.treasuryDataRevisionRC5R3 = (tonumber(self.runtime.treasuryDataRevisionRC5R3) or 0) + 1
    return true
end

function OTLGM.__impl180.AddTreasuryContribution176__impl1(self, goalId, contributor, amountCopper, note)
    if not self.CanEditTreasury170 or not self:CanEditTreasury170() then return false, "Only guild leadership can record contributions." end
    local treasury = self:EnsureTreasury170()
    local goal = treasury and treasury.goals and treasury.goals[goalId]
    if not goal then return false, "Select an active treasury goal first." end
    contributor = SafeText176(contributor, 28)
    if contributor == "" then return false, "Enter the contributor name." end
    amountCopper = math.max(0, math.floor(tonumber(amountCopper) or 0))
    if amountCopper <= 0 then return false, "Enter a positive contribution amount." end
    local actor = ShortName176(UnitName and UnitName("player") or "Leadership")
    local now = self:Now()
    local newCurrent = math.min(2000000000, (tonumber(goal.current) or 0) + amountCopper)
    local ok, updated = self:SetTreasuryGoal170(goalId, goal.name, newCurrent, goal.target, goal.category)
    if not ok then return false, updated end
    local entry = {
        id = tostring(now) .. "-" .. NameKey176(actor) .. "-" .. tostring(math.random(1000,9999)),
        ts = now, actor = actor, contributor = contributor, amount = amountCopper,
        note = SafeText176(note, 64), current = newCurrent,
    }
    InsertContribution176(self, goalId, entry)
    ContributionPayload176(self, goalId, entry, nil)
    if self.RefreshTreasuryContributionDialog176 then self:RefreshTreasuryContributionDialog176() end
    return true, entry
end

local PreviousTreasuryMessage176 = OTLGM.__impl180.HandleTreasuryMessage170__impl1
if PreviousTreasuryMessage176 then
    function OTLGM.__impl180.HandleTreasuryMessage170__impl2(self, message, channel, sender)
        local fields = self:Split(message or "", "^")
        if fields[1] == (self.treasuryProtocol170 or "B1") and fields[2] == "CONTRIB" then
            if self.IsPveLeadershipName and self:IsPveLeadershipName(sender) == false then return true end
            local goalId = SafeText176(fields[3] or "", 32)
            local entry = {
                id = SafeText176(fields[4] or "", 48), ts = tonumber(fields[5]) or self:Now(),
                actor = SafeText176(fields[6] or sender or "Leadership", 28), contributor = SafeText176(fields[7] or "Anonymous", 28),
                amount = math.max(0, math.floor(tonumber(fields[8]) or 0)), note = SafeText176(fields[9] or "", 64),
                current = math.max(0, math.floor(tonumber(fields[10]) or 0)),
            }
            if goalId ~= "" and entry.id ~= "" and entry.amount > 0 and InsertContribution176(self, goalId, entry) then
                self.runtime = self.runtime or {}
                self.runtime.treasurySync170 = self.runtime.treasurySync170 or { active = true, started = self:Now(), received = 0 }
                self.runtime.treasurySync170.ledgerReceivedR2 = (tonumber(self.runtime.treasurySync170.ledgerReceivedR2) or 0) + 1
                if self.RefreshTreasuryPage170 and self.ui and self.ui.currentPage == "treasury" then self:RefreshTreasuryPage170() end
                if self.RefreshTreasuryContributionDialog176 then self:RefreshTreasuryContributionDialog176() end
            end
            return true
        end
        return PreviousTreasuryMessage176(self, message, channel, sender)
    end
end

local PreviousQueueTreasuryState176 = OTLGM.__impl180.QueueTreasuryState170__impl1
if PreviousQueueTreasuryState176 then
    function OTLGM.__impl180.QueueTreasuryState170__impl2(self, target)
        self.runtime = self.runtime or {}
        self.runtime.deferTreasuryEndR2 = true
        local result = PreviousQueueTreasuryState176(self, target)
        self.runtime.deferTreasuryEndR2 = nil
        if not result or not target or target == "" then return result end
        local treasury = self:EnsureTreasury170()
        local rows = {}
        local goalId, entries, index, entry
        for goalId, entries in pairs(treasury and treasury.contributions176 or {}) do
            for index = 1, table.getn(entries or {}) do
                entry = entries[index]
                table.insert(rows, { goalId = goalId, entry = entry })
            end
        end
        table.sort(rows, function(left, right) return (tonumber(left.entry.ts) or 0) > (tonumber(right.entry.ts) or 0) end)
        local sent = 0
        for index = 1, math.min(MAX_SYNC_CONTRIBUTIONS_176, table.getn(rows)) do
            if ContributionPayload176(self, rows[index].goalId, rows[index].entry, target) then sent = sent + 1 end
        end
        self.runtime.treasuryLedgerRowsSentR2 = sent
        self.runtime.treasuryLedgerRowsAvailableR2 = table.getn(rows)
        -- A single final END now means goals, tombstones and the bounded retained
        -- contribution history have all been queued for this peer.
        return self:QueueNetworkPayload(table.concat({ self.treasuryProtocol170 or "B1", "END", tostring(treasury.revision or 0), tostring(table.getn(self:GetTreasuryGoals170() or {})), tostring(sent) }, "^"), "WHISPER", target, 2, "treasury", "treasury:end:" .. tostring(target)) and true or false
    end
end

function OTLGM.__impl180.BuildTreasuryContributionDialog176__impl1(self)
    self.ui = self.ui or {}
    if self.ui.treasuryContributionDialog176 or not UIParent then return end
    local dialog = CreateFrame("Frame", "OTLGM_TreasuryContribution176", UIParent)
    dialog:SetWidth(560) dialog:SetHeight(420)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
    dialog:SetFrameStrata("DIALOG") dialog:SetFrameLevel(121)
    dialog:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=14, insets={left=5,right=5,top=5,bottom=5} })
    dialog:SetBackdropColor(0.015,0.016,0.018,0.995) dialog:SetBackdropBorderColor(0.72,0.48,0.16,1)
    dialog:EnableMouse(true) dialog:SetMovable(true) dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", function() this:StartMoving() end)
    dialog:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    dialog:Hide()
    self.ui.treasuryContributionDialog176 = dialog

    dialog.title176 = SimpleText176(dialog, "GameFontNormalLarge", "Record Treasury Contribution", 18, -16, 430, "LEFT")
    dialog.goal176 = SimpleText176(dialog, "GameFontNormal", "", 18, -46, 500, "LEFT")
    SimpleButton176(dialog, "X", 514, -12, 28, 26, function() dialog:Hide() end, "danger")

    SimpleText176(dialog, "GameFontNormalSmall", "Contributor", 18, -78, 120, "LEFT")
    dialog.contributor176 = CreateFrame("EditBox", "OTLGM_TreasuryContributor176", dialog)
    if OTLGM.PrepareInteractiveControl170 then OTLGM:PrepareInteractiveControl170(dialog.contributor176, "editbox") end
    dialog.contributor176:SetPoint("TOPLEFT", dialog, "TOPLEFT", 18, -96)
    dialog.contributor176:SetWidth(210) dialog.contributor176:SetHeight(28)
    dialog.contributor176:SetAutoFocus(false) dialog.contributor176:SetFontObject("GameFontHighlightSmall")
    dialog.contributor176:SetTextInsets(7,7,4,4) dialog.contributor176:SetMaxLetters(28)
    dialog.contributor176:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=9, insets={left=3,right=3,top=3,bottom=3} })
    dialog.contributor176:SetBackdropColor(0.02,0.02,0.02,1) dialog.contributor176:SetBackdropBorderColor(0.34,0.28,0.18,1)
    dialog.contributor176:SetScript("OnEscapePressed", function() this:ClearFocus() end)

    SimpleText176(dialog, "GameFontNormalSmall", "Amount (gold)", 246, -78, 120, "LEFT")
    dialog.amount176 = CreateFrame("EditBox", "OTLGM_TreasuryAmount176", dialog)
    if OTLGM.PrepareInteractiveControl170 then OTLGM:PrepareInteractiveControl170(dialog.amount176, "editbox") end
    dialog.amount176:SetPoint("TOPLEFT", dialog, "TOPLEFT", 246, -96)
    dialog.amount176:SetWidth(118) dialog.amount176:SetHeight(28)
    dialog.amount176:SetAutoFocus(false) dialog.amount176:SetFontObject("GameFontHighlightSmall")
    dialog.amount176:SetTextInsets(7,7,4,4) dialog.amount176:SetMaxLetters(12)
    dialog.amount176:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=9, insets={left=3,right=3,top=3,bottom=3} })
    dialog.amount176:SetBackdropColor(0.02,0.02,0.02,1) dialog.amount176:SetBackdropBorderColor(0.34,0.28,0.18,1)
    dialog.amount176:SetScript("OnEscapePressed", function() this:ClearFocus() end)

    SimpleText176(dialog, "GameFontNormalSmall", "Note", 18, -134, 120, "LEFT")
    dialog.note176 = CreateFrame("EditBox", "OTLGM_TreasuryNote176", dialog)
    if OTLGM.PrepareInteractiveControl170 then OTLGM:PrepareInteractiveControl170(dialog.note176, "editbox") end
    dialog.note176:SetPoint("TOPLEFT", dialog, "TOPLEFT", 18, -152)
    dialog.note176:SetWidth(346) dialog.note176:SetHeight(28)
    dialog.note176:SetAutoFocus(false) dialog.note176:SetFontObject("GameFontHighlightSmall")
    dialog.note176:SetTextInsets(7,7,4,4) dialog.note176:SetMaxLetters(64)
    dialog.note176:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=9, insets={left=3,right=3,top=3,bottom=3} })
    dialog.note176:SetBackdropColor(0.02,0.02,0.02,1) dialog.note176:SetBackdropBorderColor(0.34,0.28,0.18,1)
    dialog.note176:SetScript("OnEscapePressed", function() this:ClearFocus() end)

    dialog.add176 = SimpleButton176(dialog, "Add Contribution", 382, -96, 158, 84, function()
        local ui = OTLGM.ui and OTLGM.ui.treasury170
        local goalId = ui and ui.selected
        local gold = tonumber(dialog.amount176:GetText()) or 0
        local ok, problem = OTLGM:AddTreasuryContribution176(goalId, dialog.contributor176:GetText(), math.floor(gold * COPPER_PER_GOLD_176), dialog.note176:GetText())
        if not ok then
            if OTLGM.__impl180.ShowNotice__impl1 then OTLGM:ShowNotice("Treasury Contribution", problem) end
        else
            dialog.amount176:SetText("") dialog.note176:SetText("")
            OTLGM:RefreshTreasuryPage170(true)
            OTLGM:RefreshTreasuryContributionDialog176()
        end
    end, "confirm")

    SimpleText176(dialog, "GameFontNormal", "CONTRIBUTION HISTORY", 18, -202, 400, "LEFT")
    dialog.rows176 = {}
    local index
    for index = 1, 7 do
        dialog.rows176[index] = SimpleText176(dialog, "GameFontNormalSmall", "", 18, -228 - ((index - 1) * 24), 520, "LEFT")
        dialog.rows176[index]:SetTextColor(0.72,0.72,0.69)
    end
end

function OTLGM.__impl180.RefreshTreasuryContributionDialog176__impl1(self)
    self:BuildTreasuryContributionDialog176()
    local dialog = self.ui and self.ui.treasuryContributionDialog176
    local ui = self.ui and self.ui.treasury170
    if not dialog then return end
    local goalId = ui and ui.selected
    local goal = goalId and self:GetTreasuryGoal170(goalId) or nil
    dialog.goal176:SetText(goal and (self.colors.gold .. tostring(goal.name) .. self.colors.reset .. "  " .. Money176(goal.current) .. " / " .. Money176(goal.target)) or "Select a treasury goal before recording a contribution.")
    local entries = goalId and self:GetTreasuryContributions176(goalId) or {}
    local index, entry, note
    for index = 1, 7 do
        entry = entries[index]
        if entry then
            note = entry.note and entry.note ~= "" and ("  -  " .. entry.note) or ""
            dialog.rows176[index]:SetText(date("%d %b %H:%M", entry.ts or self:Now()) .. "  " .. tostring(entry.contributor or "Anonymous") .. "  +" .. Money176(entry.amount) .. "  by " .. tostring(entry.actor or "Leadership") .. note)
        else dialog.rows176[index]:SetText(index == 1 and "No recorded contributions for this goal." or "") end
    end
    local canEdit = self.CanEditTreasury170 and self:CanEditTreasury170()
    dialog.add176.disabled = not canEdit or not goal
    if dialog.add176.Enable and dialog.add176.Disable then if dialog.add176.disabled then dialog.add176:Disable() else dialog.add176:Enable() end end
    ApplySimpleButton176(dialog.add176, "confirm")
end

function OTLGM.__impl180.OpenTreasuryContributionDialog176__impl1(self)
    local ui = self.ui and self.ui.treasury170
    if not ui or not ui.selected then
        if self.ShowNotice then self:ShowNotice("Treasury Contribution", "Select a funding goal first.") end
        return
    end
    self:BuildTreasuryContributionDialog176()
    self:RefreshTreasuryContributionDialog176()
    self.ui.treasuryContributionDialog176:Show()
end

local PreviousBuildTreasuryPage176 = OTLGM.__impl180.BuildTreasuryPage170__impl2
if PreviousBuildTreasuryPage176 then
    function OTLGM.__impl180.BuildTreasuryPage170__impl3(self, page)
        local result = PreviousBuildTreasuryPage176(self, page)
        local ui = self.ui and self.ui.treasury170
        if ui and ui.page and not ui.contributionButton176 then
            ui.contributionButton176 = SimpleButton176(ui.page, "Record Contribution", 548, -2, 170, 26, function() OTLGM:OpenTreasuryContributionDialog176() end, "confirm")
        end
        return result
    end
end

local PreviousRefreshTreasuryPage176 = OTLGM.__impl180.RefreshTreasuryPage170__impl2
if PreviousRefreshTreasuryPage176 then
    function OTLGM.__impl180.RefreshTreasuryPage170__impl3(self, forceEditor)
        local result = PreviousRefreshTreasuryPage176(self, forceEditor)
        local ui = self.ui and self.ui.treasury170
        if ui and ui.contributionButton176 then
            local selected = ui.selected and self:GetTreasuryGoal170(ui.selected)
            local enabled = selected and self.CanEditTreasury170 and self:CanEditTreasury170()
            ui.contributionButton176.disabled = not enabled
            if ui.contributionButton176.Enable and ui.contributionButton176.Disable then if enabled then ui.contributionButton176:Enable() else ui.contributionButton176:Disable() end end
            ApplySimpleButton176(ui.contributionButton176, "confirm")
        end
        return result
    end
end

-- ---------------------------------------------------------------------------
-- Idle-path and per-frame guards.
-- The original heartbeat called several database-backed functions every second,
-- and ProcessUIDebounce was called literally every rendered frame. Preserve all
-- pending work while making the true idle path almost allocation-free.
-- ---------------------------------------------------------------------------

local PreviousProcessUIDebounce176 = OTLGM.__impl180.ProcessUIDebounce__impl1
if PreviousProcessUIDebounce176 then
    function OTLGM:ProcessUIDebounce(elapsed)
        self.runtime = self.runtime or {}
        elapsed = tonumber(elapsed) or 0
        self.runtime.uiDebounceElapsed176 = (tonumber(self.runtime.uiDebounceElapsed176) or 0) + elapsed
        local visible = self.ui and self.ui.main and self.ui.main.IsVisible and self.ui.main:IsVisible()
        local interval = visible and UI_DEBOUNCE_VISIBLE_176 or UI_DEBOUNCE_HIDDEN_176
        if self.runtime.uiDebounceElapsed176 < interval then
            P176.uiDebounceSkipped = P176.uiDebounceSkipped + 1
            return
        end
        local accumulated = self.runtime.uiDebounceElapsed176
        self.runtime.uiDebounceElapsed176 = 0
        P176.uiDebounceCalls = P176.uiDebounceCalls + 1
        return PreviousProcessUIDebounce176(self, accumulated)
    end
end

local PreviousProcessNetworkQueue176 = OTLGM.__impl180.ProcessNetworkQueue__impl1
if PreviousProcessNetworkQueue176 then
    function OTLGM.__impl180.ProcessNetworkQueue__impl2(self, maximum)
        local transport = self.runtime and self.runtime.transport
        if not transport then P176.emptyNetworkTicks = P176.emptyNetworkTicks + 1 return 0 end
        local total = 0
        if transport.critical then total = total + (tonumber(transport.critical.count) or 0) end
        if transport.normal then total = total + (tonumber(transport.normal.count) or 0) end
        if transport.bulk then total = total + (tonumber(transport.bulk.count) or 0) end
        if total <= 0 then P176.emptyNetworkTicks = P176.emptyNetworkTicks + 1 return 0 end
        return PreviousProcessNetworkQueue176(self, maximum)
    end
end

local PreviousProcessCraftingCacheQueue176 = OTLGM.__impl180.ProcessCraftingCacheQueue__impl1
if PreviousProcessCraftingCacheQueue176 then
    function OTLGM:ProcessCraftingCacheQueue()
        local queue = self.runtime and self.runtime.craftingCacheQueue
        if not HasEntries176(queue) then P176.emptyCraftCacheTicks = P176.emptyCraftCacheTicks + 1 return false end
        return PreviousProcessCraftingCacheQueue176(self)
    end
end

local PreviousProcessCraftingTimers176 = OTLGM.__impl180.ProcessCraftingTimers__impl1
if PreviousProcessCraftingTimers176 then
    function OTLGM.__impl180.ProcessCraftingTimers__impl2(self)
        local runtime = self.runtime or {}
        local cache = runtime.featureDbCache176 and runtime.featureDbCache176.crafting
        local craft = cache and cache.db
        if not craft and self.EnsureCraftingDB then
            local dbOk, dbValue = pcall(self.EnsureCraftingDB, self)
            if dbOk then craft = dbValue
            elseif self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Crafting/TIMER_DB", dbValue) end
        end
        local detailQueue = runtime.craftingDetailQueue
        local detailPending = type(detailQueue) == "table" and type(detailQueue.items) == "table"
            and (tonumber(detailQueue.head) or 1) <= table.getn(detailQueue.items)
        local pending = HasEntries176(self.craftingShareTargets)
            or HasEntries176(self.craftingManifestTargets157)
            or self.craftingRescan ~= nil
            or HasEntries176(runtime.craftingCacheQueue)
            or HasEntries176(runtime.craftingIconHydration180)
            or HasEntries176(runtime.craftingOutboundTransferStates180)
            or detailPending
            or runtime.deferredProfessionScanPack3_180 ~= nil
            or (craft and craft.syncState and craft.syncState.active)
        if not pending and craft then P176.emptyCraftingTicks = P176.emptyCraftingTicks + 1 return end
        return PreviousProcessCraftingTimers176(self)
    end
end

local PreviousProcessTreasuryTimers176 = OTLGM.__impl180.ProcessTreasuryTimers170__impl1
if PreviousProcessTreasuryTimers176 then
    function OTLGM.__impl180.ProcessTreasuryTimers170__impl2(self)
        local sync = self.runtime and self.runtime.treasurySync170
        if not HasEntries176(self.treasuryShareTargets170) and not (sync and sync.active) then
            P176.emptyTreasuryTicks = P176.emptyTreasuryTicks + 1
            return
        end
        return PreviousProcessTreasuryTimers176(self)
    end
end

local PreviousPurgePveData176 = OTLGM.__impl180.PurgePveData__impl1
if PreviousPurgePveData176 then
    function OTLGM:PurgePveData(silent)
        self.runtime = self.runtime or {}
        local now = self:Now()
        local visible = self.ui and self.ui.main and self.ui.main:IsVisible() and self.ui.currentPage == "pve"
        if not silent and not visible and self.runtime.lastPveMaintenance176
            and now - self.runtime.lastPveMaintenance176 < BACKGROUND_MAINTENANCE_176 then
            P176.maintenanceSkipped = P176.maintenanceSkipped + 1
            return false
        end
        if not silent then self.runtime.lastPveMaintenance176 = now end
        return PreviousPurgePveData176(self, silent)
    end
end

local PreviousPurgeCraftingData176 = OTLGM.__impl180.PurgeCraftingData__impl1
if PreviousPurgeCraftingData176 then
    function OTLGM:PurgeCraftingData(silent)
        self.runtime = self.runtime or {}
        local now = self:Now()
        local visible = self.ui and self.ui.main and self.ui.main:IsVisible() and self.ui.currentPage == "professions"
        if not silent and not visible and self.runtime.lastCraftMaintenance176
            and now - self.runtime.lastCraftMaintenance176 < BACKGROUND_MAINTENANCE_176 then
            P176.maintenanceSkipped = P176.maintenanceSkipped + 1
            return false
        end
        if not silent then self.runtime.lastCraftMaintenance176 = now end
        return PreviousPurgeCraftingData176(self, silent)
    end
end

-- ---------------------------------------------------------------------------
-- Shared heartbeat extension. No new frame-level OnUpdate.
-- ---------------------------------------------------------------------------

local function SafeQualityLayer176(self, source, callback)
    if type(callback) ~= "function" then return true end
    local ok, problem = pcall(callback, self)
    if not ok then
        self.runtime = self.runtime or {}
        local failures = math.min(5, (tonumber(self.runtime.qualityFailuresR6) or 0) + 1)
        self.runtime.qualityFailuresR6 = failures
        self.runtime.qualityFaultSerialR6 = (tonumber(self.runtime.qualityFaultSerialR6) or 0) + 1
        local preciseNow = self.GetPreciseTime180 and self:GetPreciseTime180() or self:Now()
        self.runtime.qualityBackoffUntilR6 = preciseNow + math.min(16, 0.5 * (2 ^ math.max(0, failures - 1)))
        if self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, source, problem) end
    end
    return ok
end

local PreviousQualityTimers176 = OTLGM.__impl180.ProcessQuality156Timers__impl3
function OTLGM.__impl180.ProcessQuality156Timers__impl4(self)
    SafeQualityLayer176(self, "Quality/PERFORMANCE_BASE", PreviousQualityTimers176)
    self.runtime = self.runtime or {}
    local now = self:Now()

    if self.runtime.performanceGroupDue176 and now >= self.runtime.performanceGroupDue176 then
        if self.InCombat and self:InCombat() and now - self.runtime.performanceGroupDue176 < 8 then
            self.runtime.performanceGroupDue176 = now + 2
        else
            self.runtime.performanceGroupDue176 = nil
            if self.UpdateGroupSession174 then self:UpdateGroupSession174(false) end
            if self.UpdateRaidPresence174 then self:UpdateRaidPresence174(false) end
        end
    end

    if self.runtime.achievementUiDirty176 and IsVisibleAchievementPage176(self) and PreviousRefreshAchievements176 then
        self.runtime.achievementUiDirty176 = nil
        PreviousRefreshAchievements176(self)
    end

    local fingerprint, timestamp
    for fingerprint, timestamp in pairs(self.runtime.raidNoticeSeen176 or {}) do
        if now - (tonumber(timestamp) or 0) > 7200 then self.runtime.raidNoticeSeen176[fingerprint] = nil end
    end

    local recent = self.runtime.recentWhispers176 or {}
    local keep = {}
    local index, entry
    for index = 1, table.getn(recent) do
        entry = recent[index]
        if entry and entry.name and now - (tonumber(entry.ts) or 0) <= 7200 and table.getn(keep) < MAX_RECENT_WHISPERS_176 then
            table.insert(keep, { name = entry.name, ts = entry.ts, inviteSentAt176 = entry.inviteSentAt176, welcomedAt176 = entry.welcomedAt176, state180 = entry.state180 })
        end
    end
    self.runtime.recentWhispers176 = keep
end

-- ---------------------------------------------------------------------------
-- Diagnostics.
-- ---------------------------------------------------------------------------

SLASH_OTLGMPERF1 = "/otlperf"
SlashCmdList["OTLGMPERF"] = function(message)
    if not DEFAULT_CHAT_FRAME then return end
    message = string.lower(Trim176(message or ""))
    if message == "reset" then
        local key, value
        for key, value in pairs(P176) do if type(value) == "number" then P176[key] = 0 end end
        DEFAULT_CHAT_FRAME:AddMessage("|cffffcc33[Lion GM Performance]|r counters reset.")
        return
    end
    local runtime = OTLGM.runtime or {}
    local recent = runtime.recentWhispers176 or {}
    local line1 = "|cffffcc33[Lion GM Performance]|r v" .. tostring(OTLGM.version) .. " / " .. tostring(OTLGM.build)
    local line2 = "Achievement cache H/M " .. tostring(P176.achievementDbHits) .. "/" .. tostring(P176.achievementDbMisses)
        .. "; guild DB H/M " .. tostring(P176.guildDbHits) .. "/" .. tostring(P176.guildDbMisses)
        .. "; domain H/M " .. tostring(P176.domainCacheHits) .. "/" .. tostring(P176.domainCacheMisses)
    local line3 = "Group deferred/coalesced/direct-skip " .. tostring(P176.deferredGroupUpdates) .. "/" .. tostring(P176.duplicateGroupEvents) .. "/" .. tostring(P176.duplicateGroupCalls)
        .. "; snapshot H/M " .. tostring(P176.groupSnapshotHits) .. "/" .. tostring(P176.groupSnapshotMisses)
    local line4 = "Idle skips UI/network/crafting/cache/treasury " .. tostring(P176.uiDebounceSkipped) .. "/" .. tostring(P176.emptyNetworkTicks) .. "/" .. tostring(P176.emptyCraftingTicks) .. "/" .. tostring(P176.emptyCraftCacheTicks) .. "/" .. tostring(P176.emptyTreasuryTicks)
    local line5 = "Maintenance deferred " .. tostring(P176.maintenanceSkipped) .. "; blocked raid notices " .. tostring(P176.blockedRaidNotices) .. "; recent whispers " .. tostring(table.getn(recent))
    local line6 = "Bag scans are incremental; published money/mail/loot/roll/world-boss/chat/fall achievements use the filtered 1.8 event bridge. /otlperf reset clears counters."
    DEFAULT_CHAT_FRAME:AddMessage(line1)
    DEFAULT_CHAT_FRAME:AddMessage(line2)
    DEFAULT_CHAT_FRAME:AddMessage(line3)
    DEFAULT_CHAT_FRAME:AddMessage(line4)
    DEFAULT_CHAT_FRAME:AddMessage(line5)
    DEFAULT_CHAT_FRAME:AddMessage(line6)
end

-- Keep the registry count stable for the existing /otltest output. The layer is
-- exposed through OTLGM.performance176 and /otlperf instead of adding another
-- registry entry to the hard-coded 1.7.5 module count.


-- ---------------------------------------------------------------------------
-- R3 transition guard: Thunder Bluff / city subzones and world transitions.
--
-- MINIMAP_ZONE_CHANGED fires for harmless subzone changes (for example moving
-- between Thunder Bluff rises). R2 treated it like a full zone load, resetting
-- encounter state and rebuilding all group achievements. R3 only performs the
-- lightweight subzone invalidation there. Real-zone and world-entry storms are
-- coalesced into one stable pass after the client has settled.
-- ---------------------------------------------------------------------------

local TRANSITION_SETTLE_176 = 3
local BAG_SCAN_SLOTS_PER_TICK_176 = 10
local BAG_SCAN_COLD_PER_TICK_176 = 6
local BAG_SCAN_MAX_COLD_PASSES_176 = 2
local CAPITALS_176 = {
    stormwind=true, stormwindcity=true, ironforge=true, darnassus=true,
    orgrimmar=true, undercity=true, thunderbluff=true,
    silvermooncity=true, exodar=true, theexodar=true,
}
local CORE_CLOTH_176 = { [2589]=20, [2592]=20, [4306]=20, [4338]=20, [14047]=20 }

local function Location176()
    local real = GetRealZoneText and GetRealZoneText() or (GetZoneText and GetZoneText() or "")
    local sub = GetSubZoneText and GetSubZoneText() or ""
    return string.lower(Trim176(real)), string.lower(Trim176(sub)), real, sub
end

local function ResetSubzoneState176(self)
    self.runtime = self.runtime or {}
    self.runtime.proudLion175 = nil
    self.runtime.regularTable175 = nil
    P176.subzoneStateResets = P176.subzoneStateResets + 1
end

local function ResetRealZoneState176(self)
    self.runtime = self.runtime or {}
    self.runtime.proudLion175 = nil
    self.runtime.regularTable175 = nil
    self.runtime.groupStates175 = {}
    self.runtime.bossEncounter174 = nil
    self.runtime.bossEncounter175 = nil
    self.runtime.bossAttempts175 = {}
    self.runtime.roarWindow174 = nil
    self.runtime.kneelWindow174 = nil
    self.runtime.danceWindow174 = nil
end

local function CheckMoneyCapital176(self, silent)
    if not GetMoney then return end
    local money = math.max(0, tonumber(GetMoney()) or 0)
    if self.SetAchievementCounter174 then self:SetAchievementCounter174("moneyCopperR6", money) end
    if money >= 100 * COPPER_PER_GOLD_176 and self.CompleteAchievement174 then self:CompleteAchievement174("D014", silent and true or false) end
    local zone = Location176()
    zone = ProgressKey176(zone)
    if money == 0 and CAPITALS_176[zone] and self.CompleteAchievement174 then self:CompleteAchievement174("D019", silent and true or false) end
end

local function ScheduleTransition176(self, reason, worldEntry)
    self.runtime = self.runtime or {}
    local now = self:Now()
    if self.runtime.transitionActive176 then P176.transitionEventsCoalesced = P176.transitionEventsCoalesced + 1 end
    self.runtime.transitionActive176 = true
    self.runtime.transitionDue176 = now + TRANSITION_SETTLE_176
    self.runtime.transitionReason176 = reason or "transition"
    self.runtime.transitionWorldEntry176 = self.runtime.transitionWorldEntry176 or (worldEntry and true or false)
    self.runtime.groupSnapshotDirty176 = true
    self.runtime.performanceGroupDue176 = nil
    -- R6 scheduled a synchronous full bag scan one second after every world
    -- entry. The incremental scanner below owns that work now.
    self.runtime.bagScanDueR6 = nil
    if worldEntry then P176.transitionWorldEntries = P176.transitionWorldEntries + 1
    else P176.transitionZoneEvents = P176.transitionZoneEvents + 1 end
    if self.WakeScheduler180 then self:WakeScheduler180("world-transition") end
end

local function ItemIdFromLink176(link)
    local _, _, id = string.find(tostring(link or ""), "item:(%d+)")
    return tonumber(id)
end

local function ClassifyBagItem176(state, link, id, count, allowCold)
    if not state or not link then return end
    if id and CORE_CLOTH_176[id] and (tonumber(count) or 0) > 0 then state.cloth[id] = (tonumber(state.cloth[id]) or 0) + math.max(1, tonumber(count) or 1) end
    if not GetItemInfo then return end
    local name, _, _, _, _, itemType, itemSubType = GetItemInfo(link)
    if not name then
        if allowCold and id and not state.coldSeen[id] then
            state.coldSeen[id] = true
            table.insert(state.cold, { link=link, id=id })
        end
        return
    end
    local typeKey = string.lower(tostring(itemType or ""))
    local subKey = string.lower(tostring(itemSubType or ""))
    local nameKey = string.lower(tostring(name or ""))
    if id and (string.find(subKey,"food",1,true)
        or (string.find(typeKey,"consumable",1,true)
            and (string.find(nameKey,"bread",1,true) or string.find(nameKey,"meat",1,true)
                or string.find(nameKey,"fish",1,true) or string.find(nameKey,"cheese",1,true)
                or string.find(nameKey,"fruit",1,true)))) then state.food[id]=true end
    if id and (string.find(subKey,"potion",1,true) or string.find(subKey,"elixir",1,true)
        or string.find(subKey,"flask",1,true) or string.find(nameKey,"potion",1,true)
        or string.find(nameKey,"elixir",1,true) or string.find(nameKey,"flask",1,true)) then state.potions[id]=true end
end

local function NewBagScan176(self)
    P176.incrementalBagScans = P176.incrementalBagScans + 1
    return {
        bag=0, slot=1, phase="bags", cloth={}, food={}, potions={}, cold={}, coldSeen={},
        coldIndex=1, coldPass=1, started=self:Now(),
    }
end

local function NeedsIncrementalBagTracking180(self)
    if not self or not self.IsAchievementComplete174 then return true end
    return not self:IsAchievementComplete174("D015")
        or not self:IsAchievementComplete174("D016")
        or not self:IsAchievementComplete174("D017")
end

function OTLGM:ScheduleIncrementalBagScan176(reason, delay)
    self.runtime = self.runtime or {}
    if not NeedsIncrementalBagTracking180(self) then
        self.runtime.incrementalBagScan176 = nil
        self.runtime.incrementalBagDue176 = nil
        self.runtime.nextBagSliceR5 = nil
        return false
    end
    if self.runtime.incrementalBagScan176 then
        self.runtime.incrementalBagScan176 = nil
        P176.incrementalBagRestarts = P176.incrementalBagRestarts + 1
    end
    -- A real BAG_UPDATE/world-entry request starts a fresh bounded scan. Do not
    -- inherit an inter-slice deadline or a failure budget from an older pass.
    self.runtime.nextBagSliceR5 = nil
    self.runtime.incrementalBagFailuresR6 = 0
    self.runtime.incrementalBagDue176 = self:Now() + math.max(1, tonumber(delay) or 1)
    self.runtime.incrementalBagReason176 = reason or "bag"
    P176.incrementalBagRequests = P176.incrementalBagRequests + 1
    if self.WakeScheduler180 then self:WakeScheduler180("bag-scan") end
end

local function FinalizeBagScan176(self, state)
    local clothReady = 0
    local id, count
    for id, count in pairs(state.cloth or {}) do if count >= (CORE_CLOTH_176[id] or 20) then clothReady = clothReady + 1 end end
    local foodCount = Count176(state.food)
    local potionCount = Count176(state.potions)
    self:SetAchievementCounter174("coreClothStacksR6", clothReady)
    self:SetAchievementCounter174("uniqueFoodR6", foodCount)
    self:SetAchievementCounter174("uniquePotionsR6", potionCount)
    if clothReady >= 5 then self:CompleteAchievement174("D015", false) end
    if foodCount >= 20 then self:CompleteAchievement174("D016", false) end
    if potionCount >= 10 then self:CompleteAchievement174("D017", false) end
    if self.UpdateFinalAchievementOwnership180 then pcall(self.UpdateFinalAchievementOwnership180, self) end
end

function OTLGM.__impl180.ProcessIncrementalBagScan176__impl1(self)
    self.runtime = self.runtime or {}
    local now = self:Now()
    if not self.runtime.incrementalBagScan176 then
        if not self.runtime.incrementalBagDue176 or now < self.runtime.incrementalBagDue176 then return false end
        if self.runtime.transitionActive176 then
            self.runtime.incrementalBagDue176 = now + 1
            return false
        end
        self.runtime.incrementalBagDue176 = nil
        self.runtime.incrementalBagScan176 = NewBagScan176(self)
    end
    local state = self.runtime.incrementalBagScan176
    local processed = 0
    if state.phase == "bags" then
        while processed < BAG_SCAN_SLOTS_PER_TICK_176 and state.bag <= 4 do
            local slots = GetContainerNumSlots and math.max(0, tonumber(GetContainerNumSlots(state.bag)) or 0) or 0
            if state.slot > slots then
                state.bag = state.bag + 1
                state.slot = 1
            else
                local link = GetContainerItemLink and GetContainerItemLink(state.bag, state.slot) or nil
                if link then
                    local id = ItemIdFromLink176(link)
                    local itemCount = 1
                    if GetContainerItemInfo then
                        local texture176, count176 = GetContainerItemInfo(state.bag, state.slot)
                        itemCount = tonumber(count176) or 1
                    end
                    ClassifyBagItem176(state, link, id, itemCount, true)
                end
                state.slot = state.slot + 1
                processed = processed + 1
                P176.incrementalBagSlots = P176.incrementalBagSlots + 1
            end
        end
        if state.bag > 4 then
            if table.getn(state.cold) > 0 then state.phase = "cold" else state.phase = "done" end
        end
    elseif state.phase == "cold" then
        while processed < BAG_SCAN_COLD_PER_TICK_176 and state.coldIndex <= table.getn(state.cold) do
            local item = state.cold[state.coldIndex]
            ClassifyBagItem176(state, item.link, item.id, 0, false)
            state.coldIndex = state.coldIndex + 1
            processed = processed + 1
            P176.incrementalBagColdRetries = P176.incrementalBagColdRetries + 1
        end
        if state.coldIndex > table.getn(state.cold) then
            if state.coldPass < BAG_SCAN_MAX_COLD_PASSES_176 then
                state.coldPass = state.coldPass + 1
                state.coldIndex = 1
            else state.phase = "done" end
        end
    end
    if state.phase == "done" then
        FinalizeBagScan176(self, state)
        self.runtime.incrementalBagScan176 = nil
        return true
    end
    return false
end

local PreviousTransitionGroup176 = OTLGM.__impl180.UpdateGroupSession174__impl4
if PreviousTransitionGroup176 then
    function OTLGM:UpdateGroupSession174(silent)
        self.runtime = self.runtime or {}
        if self.runtime.transitionActive176 and not self.runtime.transitionStablePass176 then
            P176.transitionWorkDeferred = P176.transitionWorkDeferred + 1
            return self.runtime.achievementGroup174 or (self.runtime.groupSnapshot176 and self.runtime.groupSnapshot176.value)
        end
        return PreviousTransitionGroup176(self, silent)
    end
end

local PreviousTransitionRaid176 = OTLGM.__impl180.UpdateRaidPresence174__impl1
if PreviousTransitionRaid176 then
    function OTLGM:UpdateRaidPresence174(silent)
        self.runtime = self.runtime or {}
        if self.runtime.transitionActive176 and not self.runtime.transitionStablePass176 then
            P176.transitionWorkDeferred = P176.transitionWorkDeferred + 1
            return false
        end
        return PreviousTransitionRaid176(self, silent)
    end
end

local function RunStableTransition176(self)
    self.runtime = self.runtime or {}
    local runtime = self.runtime
    local worldEntry = runtime.transitionWorldEntry176 and true or false
    local firstProblem

    local function SafeTransitionStep176(label, callback)
        if type(callback) ~= "function" then return true end
        local ok, problem = pcall(callback)
        if not ok then
            firstProblem = firstProblem or tostring(problem or "transition step failed")
            if self.RecordInternalIssueRC3 then
                pcall(self.RecordInternalIssueRC3, self, "Transition/" .. tostring(label or "STEP"), problem)
            end
        end
        return ok
    end

    -- A transition is a coordination barrier for network/crafting work.  Never
    -- leave transitionActive176 set because one optional achievement/UI hook
    -- failed: that would make the addon look permanently inactive after a zone
    -- change.  Run independent steps in isolation and always release the barrier.
    runtime.transitionDue176 = nil
    runtime.transitionStablePass176 = true
    SafeTransitionStep176("RESET_ZONE", function() ResetRealZoneState176(self) end)
    runtime.groupSnapshotDirty176 = true
    SafeTransitionStep176("MEMBERSHIP", function() if self.UpdateMembershipPeriod174 then self:UpdateMembershipPeriod174() end end)
    SafeTransitionStep176("GROUP", function() if self.UpdateGroupSession174 then self:UpdateGroupSession174(false) end end)
    SafeTransitionStep176("RAID", function() if self.UpdateRaidPresence174 then self:UpdateRaidPresence174(false) end end)
    SafeTransitionStep176("LEGACY_ACHIEVEMENTS", function() if self.CheckLegacyAchievements174 then self:CheckLegacyAchievements174(false, false) end end)
    SafeTransitionStep176("UNDER_BANNER", function() if self.CheckUnderBanner175R4 then self:CheckUnderBanner175R4(false) end end)
    SafeTransitionStep176("MONEY", function() CheckMoneyCapital176(self, false) end)

    if worldEntry then
        SafeTransitionStep176("TOOLTIP", function() if self.InstallTooltipCompatibility160 then self:InstallTooltipCompatibility160() end end)
        SafeTransitionStep176("WORLD_CHANNEL", function() if self.DetectWorldChannel153 then self:DetectWorldChannel153(true) end end)
        SafeTransitionStep176("UI_SCALE", function()
            if self.ui and self.ui.main then
                -- Shell already remembers the host geometry. A normal zone
                -- change must not force another full scale/layout transaction;
                -- only rebase when DFUI/UIParent/resolution actually changed.
                if self.RebaseUIParentGeometry180 then
                    self:RebaseUIParentGeometry180("transition-stable", false)
                elseif self.ApplyUIScale then
                    local settings = OTLGM_DB and OTLGM_DB.settings or {}
                    local request = settings.uiScaleModeR2 == "FIT" and "FIT" or (settings.uiScale or 1)
                    self:ApplyUIScale(request)
                end
            end
        end)
        SafeTransitionStep176("RECRUITMENT", function()
            if self.ui and self.ui.currentPage == "recruitment" and self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
        end)
        SafeTransitionStep176("BAG_SCAN", function()
            if self.ScheduleIncrementalBagScan176 then self:ScheduleIncrementalBagScan176("world-entry", 1) end
        end)
    end

    SafeTransitionStep176("LOCATION", function()
        local real, sub = Location176()
        runtime.lastRealZone176 = real
        runtime.lastSubZone176 = sub
    end)

    runtime.transitionWorldEntry176 = nil
    runtime.transitionReason176 = nil
    runtime.transitionStablePass176 = nil
    runtime.transitionActive176 = nil
    P176.transitionStablePasses = P176.transitionStablePasses + 1
    return firstProblem == nil
end

-- Detach every old world-entry / zone path that performed overlapping work.
-- Their required effects are reproduced once in RunStableTransition176.
Unregister176("OTLGM_AchievementsEvent174", "PLAYER_ENTERING_WORLD")
Unregister176("OTLGM_ReleaseEvent175R4", "PLAYER_ENTERING_WORLD")
Unregister176("OTLGM_ReleaseEvent175R6", "PLAYER_ENTERING_WORLD")
Unregister176("OTLGM_ReleaseEvent175R6", "ZONE_CHANGED_NEW_AREA")
Unregister176("OTLGM_EventFrame", "PLAYER_ENTERING_WORLD")
P176.disabledTrackers.liveBagScan = nil
P176.disabledTrackers.incrementalBagScan = false

-- Replace R2's event script with the zone-aware R3 bridge.
eventFrame176:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame176:RegisterEvent("BAG_UPDATE")
eventFrame176:SetScript("OnEvent", function()
    if not OTLGM then return end
    OTLGM.runtime = OTLGM.runtime or {}
    if event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        OTLGM.runtime.reunionSignature175 = nil
        OTLGM.runtime.proudLion175 = nil
        if OTLGM.runtime.transitionActive176 then
            OTLGM.runtime.groupSnapshotDirty176 = true
            P176.transitionEventsCoalesced = P176.transitionEventsCoalesced + 1
        else OTLGM:ScheduleAchievementGroupRefresh176(event) end
    elseif event == "GUILD_ROSTER_UPDATE" then
        OTLGM.runtime.achievementRosterDirty176 = true
        OTLGM.runtime.groupSnapshotDirty176 = true
        OTLGM.runtime.guildLeader175 = nil
        OTLGM.runtime.guildLeaderR6 = nil
        OTLGM.runtime.guildLeader176 = nil
    elseif event == "PLAYER_GUILD_UPDATE" then
        OTLGM:InvalidatePerformanceDataCaches176()
        OTLGM.runtime.achievementRosterDirty176 = true
        if OTLGM.UpdateMembershipPeriod174 then OTLGM:UpdateMembershipPeriod174() end
        if OTLGM.runtime.transitionActive176 then P176.transitionEventsCoalesced = P176.transitionEventsCoalesced + 1
        else OTLGM:ScheduleAchievementGroupRefresh176(event) end
    elseif event == "PLAYER_ENTERING_WORLD" then
        ScheduleTransition176(OTLGM, event, true)
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        ScheduleTransition176(OTLGM, event, false)
    elseif event == "MINIMAP_ZONE_CHANGED" then
        local real, sub = Location176()
        local lastReal = OTLGM.runtime.lastRealZone176 or real
        local lastSub = OTLGM.runtime.lastSubZone176 or sub
        if real == lastReal then
            P176.sameZoneMinimapIgnored = P176.sameZoneMinimapIgnored + 1
            if sub ~= lastSub then ResetSubzoneState176(OTLGM) end
            OTLGM.runtime.lastRealZone176 = real
            OTLGM.runtime.lastSubZone176 = sub
        else ScheduleTransition176(OTLGM, event, false) end
    elseif event == "BAG_UPDATE" then
        OTLGM:ScheduleIncrementalBagScan176("bag-update", 1)
    elseif event == "CHAT_MSG_WHISPER" then
        if OTLGM.CaptureRecentWhisper176 then OTLGM:CaptureRecentWhisper176(arg2, arg1) end
    elseif event == "VARIABLES_LOADED" or event == "PLAYER_LOGIN" then
        OTLGM:InvalidatePerformanceDataCaches176()
        RebuildThresholdIndex176()
        local real, sub = Location176()
        OTLGM.runtime.lastRealZone176 = real
        OTLGM.runtime.lastSubZone176 = sub
    end
    if OTLGM.UpdateSchedulerState180 then OTLGM:UpdateSchedulerState180("performance-event:" .. tostring(event or "unknown")) end
end)

-- During the short transition settling window, keep queued work intact and let it
-- resume automatically after the stable pass instead of competing with loading.
local PreviousTransitionNetwork176 = OTLGM.__impl180.ProcessNetworkQueue__impl2
if PreviousTransitionNetwork176 then
    function OTLGM.__impl180.ProcessNetworkQueue__impl3(self, maximum)
        if self.runtime and self.runtime.transitionActive176 then P176.transitionWorkDeferred = P176.transitionWorkDeferred + 1 return 0 end
        return PreviousTransitionNetwork176(self, maximum)
    end
end
local PreviousTransitionCrafting176 = OTLGM.__impl180.ProcessCraftingTimers__impl2
if PreviousTransitionCrafting176 then
    function OTLGM:ProcessCraftingTimers()
        if self.runtime and self.runtime.transitionActive176 then P176.transitionWorkDeferred = P176.transitionWorkDeferred + 1 return end
        return PreviousTransitionCrafting176(self)
    end
end
local PreviousTransitionTreasury176 = OTLGM.__impl180.ProcessTreasuryTimers170__impl2
if PreviousTransitionTreasury176 then
    function OTLGM:ProcessTreasuryTimers170()
        if self.runtime and self.runtime.transitionActive176 then P176.transitionWorkDeferred = P176.transitionWorkDeferred + 1 return end
        return PreviousTransitionTreasury176(self)
    end
end

local PreviousQualityTimersR3_176 = OTLGM.__impl180.ProcessQuality156Timers__impl4
function OTLGM.__impl180.ProcessQuality156Timers__impl5(self)
    SafeQualityLayer176(self, "Quality/PERFORMANCE_R3", PreviousQualityTimersR3_176)
    self.runtime = self.runtime or {}
    local now = self:Now()
    if self.runtime.transitionDue176 and now >= self.runtime.transitionDue176 then
        if self.InCombat and self:InCombat() and now - self.runtime.transitionDue176 < 8 then
            self.runtime.transitionDue176 = now + 2
        else RunStableTransition176(self) end
    end
    self:ProcessIncrementalBagScan176()
end

-- R3 diagnostics replace the R2 wording: bag achievements are active again, but
-- scanned in bounded slices rather than one large frame.
SlashCmdList["OTLGMPERF"] = function(message)
    if not DEFAULT_CHAT_FRAME then return end
    message = string.lower(Trim176(message or ""))
    if message == "reset" then
        local key, value
        for key, value in pairs(P176) do if type(value) == "number" then P176[key] = 0 end end
        DEFAULT_CHAT_FRAME:AddMessage("|cffffcc33[Lion GM Performance]|r counters reset.")
        return
    end
    local runtime = OTLGM.runtime or {}
    local recent = runtime.recentWhispers176 or {}
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc33[Lion GM Performance]|r v" .. tostring(OTLGM.version) .. " / " .. tostring(OTLGM.build))
    DEFAULT_CHAT_FRAME:AddMessage("Cache achievement H/M "..tostring(P176.achievementDbHits).."/"..tostring(P176.achievementDbMisses).."; guild "..tostring(P176.guildDbHits).."/"..tostring(P176.guildDbMisses).."; domain "..tostring(P176.domainCacheHits).."/"..tostring(P176.domainCacheMisses))
    DEFAULT_CHAT_FRAME:AddMessage("Group deferred/coalesced/direct-skip "..tostring(P176.deferredGroupUpdates).."/"..tostring(P176.duplicateGroupEvents).."/"..tostring(P176.duplicateGroupCalls).."; snapshot H/M "..tostring(P176.groupSnapshotHits).."/"..tostring(P176.groupSnapshotMisses))
    DEFAULT_CHAT_FRAME:AddMessage("Transitions world/zone/coalesced/stable "..tostring(P176.transitionWorldEntries).."/"..tostring(P176.transitionZoneEvents).."/"..tostring(P176.transitionEventsCoalesced).."/"..tostring(P176.transitionStablePasses).."; same-zone minimap ignored "..tostring(P176.sameZoneMinimapIgnored))
    DEFAULT_CHAT_FRAME:AddMessage("Incremental bags requests/scans/slots/cold/restarts "..tostring(P176.incrementalBagRequests).."/"..tostring(P176.incrementalBagScans).."/"..tostring(P176.incrementalBagSlots).."/"..tostring(P176.incrementalBagColdRetries).."/"..tostring(P176.incrementalBagRestarts))
    DEFAULT_CHAT_FRAME:AddMessage("Idle skips UI/network/crafting/cache/treasury "..tostring(P176.uiDebounceSkipped).."/"..tostring(P176.emptyNetworkTicks).."/"..tostring(P176.emptyCraftingTicks).."/"..tostring(P176.emptyCraftCacheTicks).."/"..tostring(P176.emptyTreasuryTicks).."; transition work deferred "..tostring(P176.transitionWorkDeferred))
    DEFAULT_CHAT_FRAME:AddMessage("Blocked raid notices "..tostring(P176.blockedRaidNotices).."; recent whispers "..tostring(table.getn(recent))..". Broad legacy combat listeners are detached; filtered achievement events are owned only while needed.")
end


-- ---------------------------------------------------------------------------
-- R4 ultra-safe pass: cold login, mailbox, risky trackers and edge parking.
--
-- Feedback after R3 showed three remaining stutter clusters: first login, first
-- UI open and mailbox/AH-result access. This legacy pass temporarily deferred several
-- achievement trackers so the addon would not perform wide scans while the client
-- was loading, opening mailbox data or building the interface. Final 1.8 restores
-- those trackers below through filtered and dynamically-owned events.
-- ---------------------------------------------------------------------------

P176.revision = 4
P176.loginTasksDeferred = P176.loginTasksDeferred or 0
P176.loginTasksFlushed = P176.loginTasksFlushed or 0
P176.senderRosterDeferred = P176.senderRosterDeferred or 0
P176.mailScansQueued = P176.mailScansQueued or 0
P176.mailHeadersScanned = P176.mailHeadersScanned or 0
P176.mailHooksInstalled = P176.mailHooksInstalled or 0
P176.uiBuildDeferredRefresh = P176.uiBuildDeferredRefresh or 0
P176.windowParkActions = P176.windowParkActions or 0
P176.riskyEventsDetached = P176.riskyEventsDetached or 0
P176.disabledTrackers = P176.disabledTrackers or {}

local COLD_LOGIN_WINDOW_176 = 30
local MAIL_SCAN_DELAY_176 = 2
local MAIL_HEADERS_PER_TICK_176 = 4
local DEFERRED_SYNC_GAP_176 = 2
local PARK_VISIBLE_PIXELS_176 = 44

local RISKY_R6_EVENTS_176 = {
    "PLAYER_LOGIN", "PLAYER_MONEY", "MAIL_SHOW", "MAIL_INBOX_UPDATE", "MAIL_SEND_SUCCESS",
    "START_LOOT_ROLL", "CANCEL_LOOT_ROLL", "CHAT_MSG_SYSTEM", "CHAT_MSG_GUILD",
    "CHAT_MSG_COMBAT_HOSTILE_DEATH", "PLAYER_DEAD",
}
local r4EventIndex176, r4EventName176
for r4EventIndex176 = 1, table.getn(RISKY_R6_EVENTS_176) do
    r4EventName176 = RISKY_R6_EVENTS_176[r4EventIndex176]
    if Unregister176("OTLGM_ReleaseEvent175R6", r4EventName176) then
        P176.riskyEventsDetached = P176.riskyEventsDetached + 1
    end
end
Unregister176("OTLGM_ReleaseEvent175R4", "PLAYER_LOGIN")
Unregister176("OTLGM_Release175R4Event", "GUILD_ROSTER_UPDATE")
Unregister176("OTLGM_ReleaseEvent175R4", "PLAYER_GUILD_UPDATE")

local function PauseAchievementTracker176(id, label)
    local def = OTLGM.achievements174 and OTLGM.achievements174.byId and OTLGM.achievements174.byId[id]
    if not def then return end
    if OTLGM.IsAchievementComplete174 and OTLGM:IsAchievementComplete174(id) then return end
    def.performancePaused176 = true
    def.description = "Tracking paused in 1.7.6 R4 for performance safety: " .. tostring(label or "risky tracker") .. "."
    def.revealed = def.description
end

-- These trackers depended on mailbox bursts, loot/system spam, guild-chat link
-- ownership scans or frequent death messages. Completed achievements are kept;
-- final 1.8 restores new unlocks below through a filtered event-safe implementation.
local PAUSED_R4_176 = {
    {"D003", "loot roll parsing"}, {"D004", "loot roll parsing"},
    {"D005", "loot roll hook"}, {"D006", "loot roll pass counting"},
    {"D008", "mail send hook"}, {"D009", "mailbox sender scan"},
    {"D010", "system roll parsing"}, {"D012", "hostile death stream"},
    {"D018", "guild-chat inventory ownership scan"}, {"D021", "combat-log fall parsing"},
}
for r4EventIndex176 = 1, table.getn(PAUSED_R4_176) do
    PauseAchievementTracker176(PAUSED_R4_176[r4EventIndex176][1], PAUSED_R4_176[r4EventIndex176][2])
end
P176.disabledTrackers.mailAchievements = true
P176.disabledTrackers.lootRollAchievements = true
P176.disabledTrackers.systemRollAchievement = true
P176.disabledTrackers.guildChatInventoryAchievement = true
P176.disabledTrackers.worldBossR6DeathStream = true

local function InColdStart176(self)
    local now = self.Now and self:Now() or 0
    return self.runtime and tonumber(self.runtime.loginColdUntil176 or 0) > now
end

local function ShouldDeferHeavyWork176(self)
    if not self or not self.runtime then return false end
    if self.runtime.transitionActive176 then return true end
    if InColdStart176(self) then return true end
    if self.InCombat and self:InCombat() then return true end
    return false
end

local deferredOps176 = {}
local function MarkDeferred176(self, key)
    self.runtime = self.runtime or {}
    self.runtime.deferredOps176 = self.runtime.deferredOps176 or {}
    self.runtime.deferredOps176[key] = true
    P176.loginTasksDeferred = P176.loginTasksDeferred + 1
    if self.WakeScheduler180 then self:WakeScheduler180("deferred:" .. tostring(key)) end
end

local PreviousRequestScanR4_176 = OTLGM.__impl180.RequestScan__impl1
if PreviousRequestScanR4_176 then
    deferredOps176.scan = function(self)
        return PreviousRequestScanR4_176(self, self.runtime and self.runtime.deferredScanReason176 or "DEFERRED")
    end
    function OTLGM.__impl180.RequestScan__impl2(self, reason)
        reason = tostring(reason or "INTERNAL")
        if ShouldDeferHeavyWork176(self) and reason ~= "MANUAL" then
            self.runtime = self.runtime or {}
            self.runtime.deferredScanReason176 = reason
            MarkDeferred176(self, "scan")
            return false
        end
        return PreviousRequestScanR4_176(self, reason)
    end
end

local PreviousRefreshSenderRosterR4_176 = OTLGM.__impl180.RefreshSenderRosterCache__impl1
if PreviousRefreshSenderRosterR4_176 then
    deferredOps176.senderRoster = function(self) return PreviousRefreshSenderRosterR4_176(self, true) end
    function OTLGM:RefreshSenderRosterCache(force)
        if force and ShouldDeferHeavyWork176(self) then
            P176.senderRosterDeferred = P176.senderRosterDeferred + 1
            MarkDeferred176(self, "senderRoster")
            return self.runtime and self.runtime.senderRosterCache
        end
        return PreviousRefreshSenderRosterR4_176(self, force)
    end
end

local function WrapDeferredNoArg176(methodName, key)
    local base = OTLGM[methodName]
    if type(base) ~= "function" then return end
    deferredOps176[key] = function(self) return base(self, false) end
    OTLGM[methodName] = function(self, force, context)
        if ShouldDeferHeavyWork176(self) and force ~= true then
            MarkDeferred176(self, key)
            return false
        end
        return base(self, force, context)
    end
end
WrapDeferredNoArg176("RequestCraftingSync", "craftingSync")
WrapDeferredNoArg176("RequestAnnouncementSync152", "announcementSync")
WrapDeferredNoArg176("RequestSharedActivitySync156", "activitySync")
WrapDeferredNoArg176("RequestPveSync", "pveSync")

local PreviousBroadcastVersionR4_176 = OTLGM.__impl180.BroadcastVersion__impl1
if PreviousBroadcastVersionR4_176 then
    deferredOps176.version = function(self) return PreviousBroadcastVersionR4_176(self) end
    function OTLGM:BroadcastVersion()
        if ShouldDeferHeavyWork176(self) then MarkDeferred176(self, "version") return false end
        return PreviousBroadcastVersionR4_176(self)
    end
end

function OTLGM:ProcessDeferredColdStartWork176()
    self.runtime = self.runtime or {}
    if ShouldDeferHeavyWork176(self) then return end
    local ops = self.runtime.deferredOps176
    if not ops or not next(ops) then return end
    local now = self:Now()
    if tonumber(self.runtime.nextDeferredOp176 or 0) > now then return end
    local order = { "version", "senderRoster", "scan", "announcementSync", "pveSync", "activitySync", "craftingSync" }
    local index, key, handler
    for index = 1, table.getn(order) do
        key = order[index]
        if ops[key] then
            ops[key] = nil
            handler = deferredOps176[key]
            if handler then pcall(handler, self) end
            self.runtime.nextDeferredOp176 = now + DEFERRED_SYNC_GAP_176
            P176.loginTasksFlushed = P176.loginTasksFlushed + 1
            return
        end
    end
    self.runtime.deferredOps176 = nil
end

-- Mailbox safety: old R6 scanned every visible mailbox header immediately. R4
-- only samples a tiny batch after the mailbox settles. The final 1.8 bridge
-- reuses those bounded slices for Pen Pals; there is still no full mailbox burst.
local function HasOutgoingMailAttachment176()
    if GetSendMailItem then
        local index
        for index = 1, 12 do
            local ok, name = pcall(GetSendMailItem, index)
            if ok and name then return true end
        end
    end
    if SendMailItemButton and SendMailItemButton.icon and SendMailItemButton.icon.GetTexture
        and SendMailItemButton.icon:GetTexture() then return true end
    return false
end

local function IsGuildMemberName176(self, name)
    name = ShortName176(name)
    if name == "" or not self.GetGuildMemberSet174 then return false end
    local members = self:GetGuildMemberSet174()
    return members and members[NameKey176(name)] ~= nil
end

function OTLGM:InstallSafeMailHook176()
    if self.mailHook176 or type(SendMail) ~= "function" then return false end
    self.mailHook176 = true
    P176.mailHooksInstalled = P176.mailHooksInstalled + 1
    local baseSendMail176 = SendMail
    SendMail = function(recipient, subject, body)
        if OTLGM and OTLGM.runtime then
            local needsMailCall180 = not (OTLGM.IsAchievementComplete174 and OTLGM:IsAchievementComplete174("D008"))
            if needsMailCall180 then
                OTLGM.runtime.pendingMail176 = {
                    recipient = ShortName176(recipient),
                    hasItem = HasOutgoingMailAttachment176(),
                    ts = OTLGM:Now(),
                }
            else
                OTLGM.runtime.pendingMail176 = nil
            end
        end
        return baseSendMail176(recipient, subject, body)
    end
    return true
end

function OTLGM.__impl180.ScheduleMailboxScan176__impl1(self, reason)
    self.runtime = self.runtime or {}
    if self.IsAchievementComplete174 and self:IsAchievementComplete174("D009") then
        self.runtime.mailScan176 = nil
        return false
    end
    self.runtime.mailScan176 = { due = self:Now() + MAIL_SCAN_DELAY_176, index = 1, reason = reason or "mail" }
    P176.mailScansQueued = P176.mailScansQueued + 1
    if self.WakeScheduler180 then self:WakeScheduler180("mail-scan") end
    return true
end

function OTLGM.__impl180.ProcessMailboxScan176__impl1(self)
    local state = self.runtime and self.runtime.mailScan176
    if not state then return end
    if self.IsAchievementComplete174 and self:IsAchievementComplete174("D009") then
        self.runtime.mailScan176 = nil
        if self.UpdateFinalAchievementOwnership180 then pcall(self.UpdateFinalAchievementOwnership180, self) end
        return false
    end
    local now = self:Now()
    if now < (tonumber(state.due) or 0) then return end
    if ShouldDeferHeavyWork176(self) then state.due = now + 2 return end
    if not GetInboxNumItems or not GetInboxHeaderInfo then self.runtime.mailScan176 = nil return end
    local count = tonumber(GetInboxNumItems()) or 0
    local scanned = 0
    local index = tonumber(state.index) or 1
    while index <= count and scanned < MAIL_HEADERS_PER_TICK_176 do
        local packageIcon, stationeryIcon, sender = GetInboxHeaderInfo(index)
        sender = ShortName176(sender)
        if sender ~= "" and self.GetGuildMemberSet174 then
            local members = self:GetGuildMemberSet174()
            if members and members[NameKey176(sender)] and self.AddAchievementSetValue174
                and not (self.IsAchievementComplete174 and self:IsAchievementComplete174("D009")) then
                self:AddAchievementSetValue174("mailGuildSendersR6", sender)
            end
        end
        scanned = scanned + 1
        index = index + 1
    end
    P176.mailHeadersScanned = P176.mailHeadersScanned + scanned
    if index > count then
        self.runtime.mailScan176 = nil
        if self.GetAchievementSet174 and self.CompleteAchievement174
            and not (self.IsAchievementComplete174 and self:IsAchievementComplete174("D009")) then
            local senders = self:GetAchievementSet174("mailGuildSendersR6")
            if Count176(senders) >= 10 then self:CompleteAchievement174("D009", false) end
        end
        if self.UpdateFinalAchievementOwnership180 then pcall(self.UpdateFinalAchievementOwnership180, self) end
    else
        state.index = index
        state.due = now + 1
    end
end

-- First UI open safety. The base UI still creates all pages, but the heaviest
-- first visible refresh is delayed by one heartbeat and the window can now be
-- safely parked to the edge without being lost.
local function InstallWindowParking176(self)
    if self.disableLegacyWindowPark176 or self.shellVersion then
        if self.ui and self.ui.windowParkTab176 then self.ui.windowParkTab176:Hide() end
        return
    end
    if not self.ui or not self.ui.main then return end
    local frame = self.ui.main
    if frame.SetClampedToScreen then frame:SetClampedToScreen(false) end
    if self.ui.windowParkTab176 then return end
    local tab = CreateFrame("Button", "OTLGM_WindowParkTab176", frame)
    if self.PrepareInteractiveControl170 then self:PrepareInteractiveControl170(tab, "button") end
    tab:SetWidth(44) tab:SetHeight(58)
    tab:SetPoint("LEFT", frame, "LEFT", 0, 0)
    tab:SetFrameLevel(frame:GetFrameLevel() + 8)
    tab:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=10, insets={left=2,right=2,top=2,bottom=2} })
    tab:SetBackdropColor(0.04,0.025,0.01,0.98)
    tab:SetBackdropBorderColor(0.92,0.62,0.18,1)
    tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tab.text:SetPoint("CENTER", tab, "CENTER", 0, 0)
    tab.text:SetText("OTL")
    tab:SetScript("OnClick", function()
        if OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.windowParked176 then OTLGM:UnparkWindow176() else OTLGM:ParkWindow176("RIGHT") end
    end)
    tab:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:AddLine("Park window", 1, 0.82, 0.35)
        GameTooltip:AddLine("Click to tuck the addon to the screen edge. Use /otl center if it is lost.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    tab:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.ui.windowParkTab176 = tab
end

local function ApplyWindowPosition176(self)
    if self.disableLegacyWindowPark176 or self.shellVersion then
        if OTLGM_DB and OTLGM_DB.settings then OTLGM_DB.settings.windowParked176 = nil end
        if self.ui and self.ui.windowParkTab176 then self.ui.windowParkTab176:Hide() end
        return
    end
    if not self.ui or not self.ui.main or not OTLGM_DB or not OTLGM_DB.settings then return end
    local frame = self.ui.main
    if frame.SetClampedToScreen then frame:SetClampedToScreen(false) end
    local parked = OTLGM_DB.settings.windowParked176
    if not parked then return end
    local side = OTLGM_DB.settings.windowParkSide176 or "RIGHT"
    local parentW = UIParent and UIParent.GetWidth and UIParent:GetWidth() or 1024
    local parentH = UIParent and UIParent.GetHeight and UIParent:GetHeight() or 768
    local frameW = frame.GetWidth and frame:GetWidth() or 1000
    local frameH = frame.GetHeight and frame:GetHeight() or 710
    local x
    if side == "LEFT" then x = -parentW / 2 - frameW / 2 + PARK_VISIBLE_PIXELS_176 else x = parentW / 2 + frameW / 2 - PARK_VISIBLE_PIXELS_176 end
    local y = math.max(-parentH / 2 + 80, math.min(parentH / 2 - 80, tonumber(OTLGM_DB.settings.windowY) or 10))
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    if self.ui.windowParkTab176 then
        self.ui.windowParkTab176:ClearAllPoints()
        if side == "LEFT" then self.ui.windowParkTab176:SetPoint("RIGHT", frame, "RIGHT", 0, 0) else self.ui.windowParkTab176:SetPoint("LEFT", frame, "LEFT", 0, 0) end
    end
end

function OTLGM.__impl180.ParkWindow176__impl1(self, side)
    if not self.ui or not self.ui.main then if self.BuildUI then self:BuildUI() end end
    OTLGM_DB.settings.windowParked176 = true
    OTLGM_DB.settings.windowParkSide176 = side or "RIGHT"
    P176.windowParkActions = P176.windowParkActions + 1
    InstallWindowParking176(self)
    ApplyWindowPosition176(self)
end

function OTLGM.__impl180.UnparkWindow176__impl1(self)
    if not self.ui or not self.ui.main then if self.BuildUI then self:BuildUI() end end
    OTLGM_DB.settings.windowParked176 = nil
    P176.windowParkActions = P176.windowParkActions + 1
    local frame = self.ui and self.ui.main
    if frame then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", tonumber(OTLGM_DB.settings.windowX) or 0, tonumber(OTLGM_DB.settings.windowY) or 10)
        if frame.SetClampedToScreen then frame:SetClampedToScreen(false) end
    end
    if self.ui and self.ui.windowParkTab176 then self.ui.windowParkTab176:SetPoint("LEFT", self.ui.main, "LEFT", 0, 0) end
end

function OTLGM.__impl180.CenterWindow176__impl1(self)
    if not self.ui or not self.ui.main then if self.BuildUI then self:BuildUI() end end
    OTLGM_DB.settings.windowParked176 = nil
    OTLGM_DB.settings.windowX = 0
    OTLGM_DB.settings.windowY = 10
    local frame = self.ui and self.ui.main
    if frame then frame:ClearAllPoints() frame:SetPoint("CENTER", UIParent, "CENTER", 0, 10) if frame.SetClampedToScreen then frame:SetClampedToScreen(false) end end
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffcc33[Lion GM]|r Window returned to center.") end
end

local PreviousBuildUIR4_176 = OTLGM.__impl180.BuildUI__impl1
if PreviousBuildUIR4_176 then
    function OTLGM.__impl180.BuildUI__impl2(self)
        self.runtime = self.runtime or {}
        local first = not (self.ui and self.ui.main)
        if first then self.runtime.uiColdBuild176 = true end
        local oldRefresh = self.RefreshVisiblePage
        if first and type(oldRefresh) == "function" then
            self.RefreshVisiblePage = function(inner)
                inner.runtime = inner.runtime or {}
                inner.runtime.uiRefreshDue176 = inner:Now() + 1
                P176.uiBuildDeferredRefresh = P176.uiBuildDeferredRefresh + 1
                if inner.WakeScheduler180 then inner:WakeScheduler180("ui-build-refresh") end
            end
        end
        local ok, result = pcall(function() return PreviousBuildUIR4_176(self) end)
        if first and type(oldRefresh) == "function" then self.RefreshVisiblePage = oldRefresh end
        self.runtime.uiColdBuild176 = nil
        if ok then
            InstallWindowParking176(self)
            ApplyWindowPosition176(self)
            if first then
                self.runtime.uiRefreshDue176 = self:Now() + 1
                if self.WakeScheduler180 then self:WakeScheduler180("ui-build-finished") end
            end
            return result
        end
        error(result)
    end
end

function OTLGM:ProcessDeferredUIRefresh176()
    local due = self.runtime and tonumber(self.runtime.uiRefreshDue176) or nil
    if not due or self:Now() < due then return end
    self.runtime.uiRefreshDue176 = nil
    if self.ui and self.ui.main and self.ui.main:IsVisible() and self.RefreshVisiblePage then self:RefreshVisiblePage() end
end

local PreviousSlashOTLR4_176 = SlashCmdList and SlashCmdList["OTLGM"]
if SlashCmdList then
    SlashCmdList["OTLGM"] = function(message)
        local msg = string.lower(Trim176(message or ""))
        if msg == "center" or msg == "resetpos" then if OTLGM and OTLGM.__impl180.CenterWindow176__impl1 then OTLGM:CenterWindow176() end return end
        if msg == "park" or msg == "park right" then if OTLGM and OTLGM.__impl180.ParkWindow176__impl1 then OTLGM:ParkWindow176("RIGHT") end return end
        if msg == "park left" then if OTLGM and OTLGM.__impl180.ParkWindow176__impl1 then OTLGM:ParkWindow176("LEFT") end return end
        if msg == "unpark" then if OTLGM and OTLGM.__impl180.UnparkWindow176__impl1 then OTLGM:UnparkWindow176() end return end
        if PreviousSlashOTLR4_176 then return PreviousSlashOTLR4_176(message) end
    end
end

local r4Frame176 = CreateFrame("Frame", "OTLGM_PerformanceR4Event176")
r4Frame176:RegisterEvent("PLAYER_LOGIN")
r4Frame176:RegisterEvent("MAIL_SHOW")
r4Frame176:RegisterEvent("MAIL_INBOX_UPDATE")
r4Frame176:RegisterEvent("MAIL_SEND_SUCCESS")
r4Frame176:SetScript("OnEvent", function()
    if not OTLGM then return end
    OTLGM.runtime = OTLGM.runtime or {}
    if event == "PLAYER_LOGIN" then
        OTLGM.runtime.loginColdUntil176 = OTLGM:Now() + COLD_LOGIN_WINDOW_176
        if not (OTLGM.IsAchievementComplete174 and OTLGM:IsAchievementComplete174("D008")) then OTLGM:InstallSafeMailHook176() end
        if OTLGM.ScheduleIncrementalBagScan176 then OTLGM:ScheduleIncrementalBagScan176("safe-login", 6) end
    elseif event == "MAIL_SHOW" or event == "MAIL_INBOX_UPDATE" then
        OTLGM:InstallSafeMailHook176()
        OTLGM:ScheduleMailboxScan176(event)
    elseif event == "MAIL_SEND_SUCCESS" then
        local pending = OTLGM.runtime.pendingMail176
        if pending and OTLGM:Now() - (tonumber(pending.ts) or 0) < 30 then
            if pending.hasItem and IsGuildMemberName176(OTLGM, pending.recipient)
                and OTLGM.SetAchievementCounter174 and OTLGM.CompleteAchievement174 then
                OTLGM:SetAchievementCounter174("mailCallR6", 1)
                OTLGM:CompleteAchievement174("D008", false)
            end
            OTLGM.runtime.pendingMail176 = nil
        end
    end
    if OTLGM.UpdateFinalAchievementOwnership180 then pcall(OTLGM.UpdateFinalAchievementOwnership180, OTLGM) end
    if OTLGM.UpdateSchedulerState180 then OTLGM:UpdateSchedulerState180("performance-r4-event:" .. tostring(event or "unknown")) end
end)

local PreviousQualityTimersR4_176 = OTLGM.__impl180.ProcessQuality156Timers__impl5
function OTLGM.__impl180.ProcessQuality156Timers__impl6(self)
    SafeQualityLayer176(self, "Quality/PERFORMANCE_R4", PreviousQualityTimersR4_176)
    SafeQualityLayer176(self, "Quality/DEFERRED_COLD_START", self.ProcessDeferredColdStartWork176)
    SafeQualityLayer176(self, "Quality/MAILBOX", self.ProcessMailboxScan176)
    SafeQualityLayer176(self, "Quality/DEFERRED_UI", self.ProcessDeferredUIRefresh176)
    if not (self.disableLegacyWindowPark176 or self.shellVersion)
        and self.ui and self.ui.main and self.ui.main:IsVisible() then
        InstallWindowParking176(self)
        ApplyWindowPosition176(self)
    elseif self.ui and self.ui.windowParkTab176 then
        self.ui.windowParkTab176:Hide()
    end
end

-- Final R4 diagnostics.
SlashCmdList["OTLGMPERF"] = function(message)
    if not DEFAULT_CHAT_FRAME then return end
    message = string.lower(Trim176(message or ""))
    if message == "reset" then
        local key, value
        for key, value in pairs(P176) do if type(value) == "number" then P176[key] = 0 end end
        DEFAULT_CHAT_FRAME:AddMessage("|cffffcc33[Lion GM Performance]|r counters reset.")
        return
    end
    local runtime = OTLGM.runtime or {}
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc33[Lion GM Performance]|r v" .. tostring(OTLGM.version) .. " / " .. tostring(OTLGM.build))
    DEFAULT_CHAT_FRAME:AddMessage("Cold login deferred/flushed/sender " .. tostring(P176.loginTasksDeferred) .. "/" .. tostring(P176.loginTasksFlushed) .. "/" .. tostring(P176.senderRosterDeferred) .. "; risky events detached " .. tostring(P176.riskyEventsDetached))
    DEFAULT_CHAT_FRAME:AddMessage("Transitions stable/coalesced/deferred " .. tostring(P176.transitionStablePasses) .. "/" .. tostring(P176.transitionEventsCoalesced) .. "/" .. tostring(P176.transitionWorkDeferred) .. "; same-zone minimap ignored " .. tostring(P176.sameZoneMinimapIgnored))
    DEFAULT_CHAT_FRAME:AddMessage("Incremental bags requests/scans/slots/cold " .. tostring(P176.incrementalBagRequests) .. "/" .. tostring(P176.incrementalBagScans) .. "/" .. tostring(P176.incrementalBagSlots) .. "/" .. tostring(P176.incrementalBagColdRetries))
    DEFAULT_CHAT_FRAME:AddMessage("Mailbox queued/headers " .. tostring(P176.mailScansQueued) .. "/" .. tostring(P176.mailHeadersScanned) .. "; UI deferred refresh " .. tostring(P176.uiBuildDeferredRefresh) .. "; park actions " .. tostring(P176.windowParkActions))
    DEFAULT_CHAT_FRAME:AddMessage("Achievement bridge: mailbox sliced, loot/system event-driven, guild chat link-filtered, world-boss name-filtered, Gravity Wins group-gated. Use /otl center if the window is lost; /otl park to tuck it to the edge.")
end

-- ---------------------------------------------------------------------------
-- C5-R2 PACK 3: rolling 60-second performance diagnostics and quiet deferred
-- profession work. Final C5-R4 dispatches this only through the keyed sleeping
-- scheduler; no feature-owned OnUpdate or second scheduler is added.
-- ---------------------------------------------------------------------------

local PACK3_PERF_WINDOW_180 = 60
local PACK3_MAX_OPERATION_SAMPLES_180 = 180
local PACK3_MAX_SPIKES_180 = 30
local PACK3_SPIKE_MS_180 = 8
local PACK3_MAX_PACKET_TIMES_180 = 240

local function Pack3Now180(self)
    return self and self.Now and self:Now() or (time and time() or 0)
end

local function Pack3ProfileClock180()
    if not debugprofilestop then return nil end
    local ok, value = pcall(debugprofilestop)
    if ok then return tonumber(value) end
    return nil
end

local function EnsurePack3Performance180(self)
    if type(self.runtime) ~= "table" then self.runtime = {} end
    if type(self.runtime.performanceRolling180) ~= "table" then
        self.runtime.performanceRolling180 = {}
    end
    local state = self.runtime.performanceRolling180
    if type(state.operations) ~= "table" then state.operations = {} end
    if type(state.spikes) ~= "table" then state.spikes = {} end
    if type(state.packets) ~= "table" then state.packets = {} end
    if type(state.packetOrder) ~= "table" then state.packetOrder = {} end
    state.lastPrune = tonumber(state.lastPrune) or 0
    return state
end

local function PrunePack3Times180(values, cutoff, maximum)
    values = values or {}
    local kept = {}
    local index, row
    for index = 1, table.getn(values) do
        row = values[index]
        local timestamp = type(row) == "table" and tonumber(row.ts) or tonumber(row)
        if timestamp and timestamp >= cutoff then table.insert(kept, row) end
    end
    while table.getn(kept) > (tonumber(maximum) or PACK3_MAX_OPERATION_SAMPLES_180) do table.remove(kept, 1) end
    return kept
end

function OTLGM:BeginPerformanceSample180()
    return Pack3ProfileClock180()
end

function OTLGM:RecordPerformanceSample180(operation, duration)
    operation = tostring(operation or "unknown")
    duration = tonumber(duration)
    if not duration or duration < 0 then return false end
    local state = EnsurePack3Performance180(self)
    local now = Pack3Now180(self)
    local cutoff = now - PACK3_PERF_WINDOW_180
    local samples = PrunePack3Times180(state.operations[operation], cutoff, PACK3_MAX_OPERATION_SAMPLES_180)
    table.insert(samples, { ts = now, ms = duration })
    state.operations[operation] = samples
    if duration >= PACK3_SPIKE_MS_180 then
        table.insert(state.spikes, 1, {
            ts = now, operation = operation, ms = duration,
            combat = self.InCombat and self:InCombat() and true or false,
            addonOpen = self.ui and self.ui.main and self.ui.main:IsVisible() and true or false,
            page = self.ui and self.ui.currentPage or "closed",
        })
        while table.getn(state.spikes) > PACK3_MAX_SPIKES_180 do table.remove(state.spikes) end
    end
    return true
end

function OTLGM:EndPerformanceSample180(operation, started)
    if not started then return false end
    local finished = Pack3ProfileClock180()
    if not finished then return false end
    -- Instrumentation must never change the success/failure of the operation it
    -- observes. Malformed runtime diagnostics or third-party UI hooks are kept
    -- behind pcall and simply drop this one sample.
    local ok, result = pcall(self.RecordPerformanceSample180, self, operation, math.max(0, finished - started))
    if not ok then
        if self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Diagnostics/PERFORMANCE_SAMPLE", result) end
        return false
    end
    return result
end

local function PacketKindPack3_180(payload)
    payload = tostring(payload or "")
    if string.sub(payload, 1, 3) == "T1^" then
        local first = string.find(payload, "^", 4, true)
        if first then payload = string.sub(payload, first + 1) end
    end
    local first = string.find(payload, "^", 1, true)
    if not first then return string.sub(payload, 1, 28) end
    local second = string.find(payload, "^", first + 1, true)
    local protocol = string.sub(payload, 1, first - 1)
    local kind = second and string.sub(payload, first + 1, second - 1) or string.sub(payload, first + 1)
    return string.sub(protocol .. ":" .. kind, 1, 42)
end

function OTLGM:RecordPerformancePacket180(direction, payload)
    local state = EnsurePack3Performance180(self)
    local key = tostring(direction or "?") .. " " .. PacketKindPack3_180(payload)
    local now = Pack3Now180(self)
    local list = PrunePack3Times180(state.packets[key], now - PACK3_PERF_WINDOW_180, PACK3_MAX_PACKET_TIMES_180)
    table.insert(list, now)
    state.packets[key] = list
    local seen = false
    local index
    for index = 1, table.getn(state.packetOrder) do if state.packetOrder[index] == key then seen = true break end end
    if not seen then table.insert(state.packetOrder, key) end
    return true
end

function OTLGM:PrunePerformanceDiagnostics180(force)
    local state = EnsurePack3Performance180(self)
    local now = Pack3Now180(self)
    if not force and now - (tonumber(state.lastPrune) or 0) < 5 then return state end
    state.lastPrune = now
    local cutoff = now - PACK3_PERF_WINDOW_180
    local operation, samples
    for operation, samples in pairs(state.operations or {}) do
        state.operations[operation] = PrunePack3Times180(samples, cutoff, PACK3_MAX_OPERATION_SAMPLES_180)
    end
    local key, list
    for key, list in pairs(state.packets or {}) do
        state.packets[key] = PrunePack3Times180(list, cutoff, PACK3_MAX_PACKET_TIMES_180)
        if table.getn(state.packets[key]) == 0 then state.packets[key] = nil end
    end
    local keptSpikes = {}
    local index, spike
    for index = 1, table.getn(state.spikes or {}) do
        spike = state.spikes[index]
        if spike and (tonumber(spike.ts) or 0) >= cutoff then table.insert(keptSpikes, spike) end
    end
    state.spikes = keptSpikes
    return state
end

local function OperationSummaryPack3_180(samples)
    local count = table.getn(samples or {})
    local total, maximum = 0, 0
    local index, value
    for index = 1, count do
        value = tonumber(samples[index] and samples[index].ms) or 0
        total = total + value
        if value > maximum then maximum = value end
    end
    return count, count > 0 and (total / count) or 0, maximum
end

function OTLGM:GetPerformanceDiagnostics180()
    local state = self:PrunePerformanceDiagnostics180(true)
    local operations = {}
    local operation, samples
    for operation, samples in pairs(state.operations or {}) do table.insert(operations, operation) end
    table.sort(operations)
    local lines = { "Performance rolling window: 60 seconds" }
    local scheduler = self.GetSchedulerDiagnostics180 and self:GetSchedulerDiagnostics180() or {}
    table.insert(lines, "Scheduler: " .. tostring(scheduler.active and "ACTIVE" or "IDLE")
        .. "; tasks " .. tostring(scheduler.taskCount or 0)
        .. "; nearest " .. tostring(scheduler.nearestKey or "none")
        .. "; wakes/sleeps " .. tostring(scheduler.wakeCount or 0) .. "/" .. tostring(scheduler.sleepCount or 0))
    local index, calls, average, maximum
    for index = 1, table.getn(operations) do
        operation = operations[index]
        calls, average, maximum = OperationSummaryPack3_180(state.operations[operation])
        table.insert(lines, operation .. ": calls " .. tostring(calls) .. ", avg " .. string.format("%.2f", average) .. " ms, max " .. string.format("%.2f", maximum) .. " ms")
    end
    local packetRows = {}
    local key, list
    for key, list in pairs(state.packets or {}) do table.insert(packetRows, { key = key, count = table.getn(list) }) end
    table.sort(packetRows, function(left, right)
        if left.count == right.count then return left.key < right.key end
        return left.count > right.count
    end)
    local packetText = {}
    for index = 1, math.min(5, table.getn(packetRows)) do table.insert(packetText, packetRows[index].key .. "=" .. tostring(packetRows[index].count)) end
    table.insert(lines, "Top packet types: " .. (table.getn(packetText) > 0 and table.concat(packetText, ", ") or "none"))
    local queueTotal, queueCritical, queueNormal, queueBulk = 0, 0, 0, 0
    if self.GetNetworkQueueDepth then queueTotal, queueCritical, queueNormal, queueBulk = self:GetNetworkQueueDepth() end
    local networkMetrics = self.runtime and self.runtime.metrics and self.runtime.metrics.network or {}
    table.insert(lines, "Network queue: total " .. tostring(queueTotal or 0) .. "; critical " .. tostring(queueCritical or 0) .. "; normal " .. tostring(queueNormal or 0) .. "; bulk " .. tostring(queueBulk or 0)
        .. "; high-water " .. tostring(networkMetrics.highWater or 0)
        .. "; sent/retried/dropped/coalesced " .. tostring(networkMetrics.sent or 0) .. "/" .. tostring(networkMetrics.retried or 0) .. "/" .. tostring(networkMetrics.dropped or 0) .. "/" .. tostring(networkMetrics.coalesced or 0))
    local rosterMetrics = self.runtime and self.runtime.rosterMetrics180 or {}
    table.insert(lines, "Roster scans: full " .. tostring(rosterMetrics.fullScans or 0) .. " (last " .. tostring(rosterMetrics.lastFullScanReason or "none") .. "); targeted " .. tostring(rosterMetrics.targetedRefreshes or 0))
    local uiMetrics = self.runtime and self.runtime.uiRefreshMetrics180 or {}
    table.insert(lines, "UI refreshes: total " .. tostring(uiMetrics.total or 0) .. "; last " .. tostring(uiMetrics.lastPage or "none") .. "/" .. tostring(uiMetrics.lastReason or "none"))
    local background = self.runtime and self.runtime.craftingBackground180 or {}
    local craftingMetrics = self.runtime and self.runtime.craftingMetrics180 or {}
    local transferCount = 0
    local _
    for _ in pairs(self.runtime and self.runtime.craftingOutboundTransferStates180 or {}) do transferCount = transferCount + 1 end
    table.insert(lines, "Crafting scans/unchanged/commits: " .. tostring(craftingMetrics.scans or 0) .. "/" .. tostring(craftingMetrics.noChangeSkips or 0) .. "/" .. tostring(craftingMetrics.commits or 0)
        .. "; transfers active/created/completed/chunks: " .. tostring(transferCount) .. "/" .. tostring(craftingMetrics.transfersCreated or 0) .. "/" .. tostring(craftingMetrics.transfersCompleted or 0) .. "/" .. tostring(craftingMetrics.chunksProduced or 0)
        .. "; queue waits/coalesced sync: " .. tostring(craftingMetrics.queueWaits or background.queueWaitCount or 0) .. "/" .. tostring(self.runtime and self.runtime.craftingSyncCoalesced180 or 0))
    table.insert(lines, "Last visible status source: " .. tostring(self.runtime and self.runtime.lastVisibleStatusSource180 or "none")
        .. "; last background source: " .. tostring(self.runtime and self.runtime.lastBackgroundStatusSource180 or "none"))
    local compatibility = self.GetAddonCompatibilityWarningRC4 and self:GetAddonCompatibilityWarningRC4() or nil
    table.insert(lines, "Compatibility: " .. tostring(compatibility or "no known version mismatch"))
    local authority = self.runtime and self.runtime.senderRoster or nil
    table.insert(lines, "Authority cache: " .. (authority and (tostring(math.max(0, self:Now() - (tonumber(authority.builtAt) or self:Now()))) .. "s old") or "empty")
        .. "; validation requests " .. tostring(self.runtime and self.runtime.authorityValidationRequestsRC4 or 0))
    local reject = self.runtime and self.runtime.networkRejectLog180 and self.runtime.networkRejectLog180[1]
    if reject then
        table.insert(lines, "Last rejected packet: " .. tostring(reject.protocol ~= "" and reject.protocol or "unknown") .. "/" .. tostring(reject.subtype ~= "" and reject.subtype or "unknown") .. " from " .. tostring(reject.sender or "unknown") .. "; reason " .. tostring(reject.reason or "unknown") .. "; count " .. tostring(reject.count or 1))
    else
        table.insert(lines, "Last rejected packet: none")
    end
    local latest = state.spikes and state.spikes[1]
    if latest then
        table.insert(lines, "Latest spike: " .. tostring(latest.operation) .. " " .. string.format("%.2f", tonumber(latest.ms) or 0)
            .. " ms; combat=" .. tostring(latest.combat and "yes" or "no")
            .. "; addon=" .. tostring(latest.addonOpen and "open" or "closed")
            .. "; page=" .. tostring(latest.page or "closed"))
    else table.insert(lines, "Latest spike: none in rolling window") end
    return table.concat(lines, "\n")
end

local PreviousDiagnosticsPack3_180 = OTLGM.__impl180.GetDiagnosticsText__impl1
if PreviousDiagnosticsPack3_180 then
    function OTLGM:GetDiagnosticsText()
        local text = tostring(PreviousDiagnosticsPack3_180(self) or "") .. "\n" .. self:GetPerformanceDiagnostics180()
        if self.GetPreFinalHealthDiagnosticsRC3 then text = text .. "\n" .. self:GetPreFinalHealthDiagnosticsRC3() end
        return text
    end
end

local PreviousQueuePayloadPack3_180 = OTLGM.__impl180.QueueNetworkPayload__impl1
if PreviousQueuePayloadPack3_180 then
    function OTLGM:QueueNetworkPayload(payload, channel, target, priority, source, coalesceKey)
        local result = PreviousQueuePayloadPack3_180(self, payload, channel, target, priority, source, coalesceKey)
        if result and self.RecordPerformancePacket180 then pcall(self.RecordPerformancePacket180, self, "OUT", payload) end
        return result
    end
end

local PreviousScanProfessionPack3_180 = OTLGM.__impl180.ScanCurrentProfession__impl1
if PreviousScanProfessionPack3_180 then
    function OTLGM:ScanCurrentProfession(mode, attempt)
        self.runtime = self.runtime or {}
        if self.InCombat and self:InCombat() then
            self.runtime.deferredProfessionScanPack3_180 = { mode = mode, attempt = attempt, requestedAt = self:Now() }
            return false
        end
        local started
        if self.BeginPerformanceSample180 then
            local beginOk, beginValue = pcall(self.BeginPerformanceSample180, self)
            if beginOk then started = beginValue
            elseif self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Diagnostics/PROFESSION_PERF_BEGIN", beginValue) end
        end
        -- Diagnostic timing is strictly observational.  A profiling failure must
        -- never turn a successful profession scan into a failed scan.
        local result, changed, count, missing = PreviousScanProfessionPack3_180(self, mode, attempt)
        if started and self.EndPerformanceSample180 then
            local endOk, endProblem = pcall(self.EndPerformanceSample180, self, "crafting sync", started)
            if not endOk and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Diagnostics/PROFESSION_PERF_END", endProblem) end
        end
        return result, changed, count, missing
    end
end

function OTLGM:ProcessDeferredProfessionScanPack3_180()
    local deferred = self.runtime and self.runtime.deferredProfessionScanPack3_180
    if not deferred or (self.InCombat and self:InCombat()) then return false end
    local frameOpen = (deferred.mode == "TRADE" and TradeSkillFrame and TradeSkillFrame.IsShown and TradeSkillFrame:IsShown())
        or (deferred.mode == "CRAFT" and CraftFrame and CraftFrame.IsShown and CraftFrame:IsShown())
    self.runtime.deferredProfessionScanPack3_180 = nil
    if not frameOpen then
        self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
        self.runtime.craftingMetrics180.closedWindowDeferredDrops = (tonumber(self.runtime.craftingMetrics180.closedWindowDeferredDrops) or 0) + 1
        return false
    end
    return self:ScanCurrentProfession(deferred.mode, deferred.attempt)
end

local PreviousQualityTimersPack3_180 = OTLGM.__impl180.ProcessQuality156Timers__impl6
function OTLGM.__impl180.ProcessQuality156Timers__impl7(self)
    SafeQualityLayer176(self, "Quality/PERFORMANCE_PACK3", PreviousQualityTimersPack3_180)
    SafeQualityLayer176(self, "Quality/DEFERRED_PROFESSION", self.ProcessDeferredProfessionScanPack3_180)
    local pruneOk, pruneProblem = pcall(self.PrunePerformanceDiagnostics180, self, false)
    if not pruneOk and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Quality/PERFORMANCE_PRUNE", pruneProblem) end
end

-- ---------------------------------------------------------------------------
-- 1.8 final achievement safety bridge.
--
-- R4 correctly removed several broad legacy listeners to eliminate login/mailbox
-- stutter, but it also left ten published achievements permanently paused.  The
-- handlers themselves are event-driven and can be restored safely when each
-- noisy source is filtered or bounded.  This bridge keeps the R4 detach in
-- place, reuses the four-header mailbox slicer above and owns only the minimal
-- events needed by incomplete achievements.
-- ---------------------------------------------------------------------------

local SAFE_ACHIEVEMENT_TEXT_180 = {
    D003 = { "Win an item with a perfect 100 Need or Greed roll." },
    D004 = { "Lose an item with a roll of 99 to a guild member who rolled 100." },
    D005 = { "Pass on an epic item in a full guild party." },
    D006 = { "Have every member of a full guild party pass on the same item." },
    D008 = { "Send an item to a guild member through the in-game mail." },
    D009 = { "Receive mail from ten different guild members." },
    D010 = { "Roll 100 with /roll while in a full guild party." },
    D012 = { "Defeat a world boss with at least ten guild members present." },
    D018 = { "Link a legendary item you own in guild chat." },
    D021 = { "The title is your clue.", "Die from falling damage while grouped with a guild member." },
}

local safeAchievementId180, safeAchievementText180
for safeAchievementId180, safeAchievementText180 in pairs(SAFE_ACHIEVEMENT_TEXT_180) do
    local safeDef180 = OTLGM.achievements174 and OTLGM.achievements174.byId and OTLGM.achievements174.byId[safeAchievementId180]
    if safeDef180 then
        safeDef180.performancePaused176 = nil
        safeDef180.description = safeAchievementText180[1]
        if safeAchievementText180[2] then safeDef180.revealed = safeAchievementText180[2] end
    end
end
P176.disabledTrackers.mailAchievements = nil
P176.disabledTrackers.lootRollAchievements = nil
P176.disabledTrackers.systemRollAchievement = nil
P176.disabledTrackers.guildChatInventoryAchievement = nil
P176.disabledTrackers.worldBossR6DeathStream = nil
P176.disabledTrackers.gravityWins = nil

local finalAchievementFrame180 = CreateFrame("Frame", "OTLGM_FinalAchievementEvent180")
local FINAL_CONTROL_EVENTS_180 = {
    "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE",
}
local finalEventIndex180
for finalEventIndex180 = 1, table.getn(FINAL_CONTROL_EVENTS_180) do
    pcall(finalAchievementFrame180.RegisterEvent, finalAchievementFrame180, FINAL_CONTROL_EVENTS_180[finalEventIndex180])
end

local function IncompleteAchievement180(self, id)
    return not (self and self.IsAchievementComplete174 and self:IsAchievementComplete174(id))
end

local function AnyIncompleteAchievement180(self, ids)
    local index
    for index = 1, table.getn(ids) do if IncompleteAchievement180(self, ids[index]) then return true end end
    return false
end

local function SetFinalAchievementEvent180(eventName, enabled)
    finalAchievementFrame180.ownedEvents180 = finalAchievementFrame180.ownedEvents180 or {}
    local active = finalAchievementFrame180.ownedEvents180[eventName]
    if enabled and not active then
        pcall(finalAchievementFrame180.RegisterEvent, finalAchievementFrame180, eventName)
        finalAchievementFrame180.ownedEvents180[eventName] = true
    elseif not enabled and active then
        pcall(finalAchievementFrame180.UnregisterEvent, finalAchievementFrame180, eventName)
        finalAchievementFrame180.ownedEvents180[eventName] = nil
    end
end

local function SetNamedLegacyEvent180(frameName, eventName, enabled)
    local frame = getglobal and getglobal(frameName) or nil
    if not frame then return false end
    if enabled then
        if frame.RegisterEvent then pcall(frame.RegisterEvent, frame, eventName) end
    else
        if frame.UnregisterEvent then pcall(frame.UnregisterEvent, frame, eventName) end
    end
    return true
end

local function SetLegacyReleaseEvent180(eventName, enabled)
    return SetNamedLegacyEvent180("OTLGM_ReleaseEvent175", eventName, enabled)
end

local function UpdateSafeAchievementEventOwnership180(self)
    -- R4 detached PLAYER_MONEY together with the old R6 frame. The replacement
    -- capital/world transition path catches eventual state, but without this
    -- cheap dynamic listener D014/D019 could stay stale for an entire zone.
    SetFinalAchievementEvent180("PLAYER_MONEY", AnyIncompleteAchievement180(self, { "D014", "D019" }))

    -- Mail and bag work are useful only while their achievements remain open.
    -- The SendMail hook cannot be removed safely once installed, but it becomes
    -- a constant-time no-op after D008. Mailbox listeners and BAG_UPDATE can be
    -- detached completely and re-enabled after a backup restore through the
    -- public ownership refresh below.
    local mailSendNeeded180 = IncompleteAchievement180(self, "D008")
    local mailInboxNeeded180 = IncompleteAchievement180(self, "D009")
    if r4Frame176 then
        if mailInboxNeeded180 then
            pcall(r4Frame176.RegisterEvent, r4Frame176, "MAIL_SHOW")
            pcall(r4Frame176.RegisterEvent, r4Frame176, "MAIL_INBOX_UPDATE")
        else
            pcall(r4Frame176.UnregisterEvent, r4Frame176, "MAIL_SHOW")
            pcall(r4Frame176.UnregisterEvent, r4Frame176, "MAIL_INBOX_UPDATE")
            if self.runtime then self.runtime.mailScan176 = nil end
        end
        if mailSendNeeded180 then pcall(r4Frame176.RegisterEvent, r4Frame176, "MAIL_SEND_SUCCESS")
        else
            pcall(r4Frame176.UnregisterEvent, r4Frame176, "MAIL_SEND_SUCCESS")
            if self.runtime then self.runtime.pendingMail176 = nil end
        end
    end
    if mailSendNeeded180 and self.InstallSafeMailHook176 then pcall(self.InstallSafeMailHook176, self) end

    local bagNeeded180 = AnyIncompleteAchievement180(self, { "D015", "D016", "D017" })
    if eventFrame176 then
        if bagNeeded180 then pcall(eventFrame176.RegisterEvent, eventFrame176, "BAG_UPDATE")
        else pcall(eventFrame176.UnregisterEvent, eventFrame176, "BAG_UPDATE") end
    end
    if not bagNeeded180 and self.runtime then
        self.runtime.incrementalBagScan176 = nil
        self.runtime.incrementalBagDue176 = nil
        self.runtime.nextBagSliceR5 = nil
    end

    local lootNeeded = AnyIncompleteAchievement180(self, { "D003", "D004", "D005", "D006" })
    local systemNeeded = lootNeeded or IncompleteAchievement180(self, "D010")
    SetFinalAchievementEvent180("START_LOOT_ROLL", lootNeeded)
    SetFinalAchievementEvent180("CANCEL_LOOT_ROLL", lootNeeded)
    SetFinalAchievementEvent180("CHAT_MSG_SYSTEM", systemNeeded)
    SetFinalAchievementEvent180("CHAT_MSG_GUILD", IncompleteAchievement180(self, "D018"))
    SetFinalAchievementEvent180("CHAT_MSG_COMBAT_HOSTILE_DEATH", IncompleteAchievement180(self, "D012"))

    -- Retire several older, low-frequency release listeners once their complete
    -- published feature has nothing left to track. Backup import/undo calls this
    -- same ownership refresh, so restoring an incomplete achievement re-enables
    -- the event immediately without requiring /reload. Rabbit hostile-death text
    -- is owned separately by SetRabbitCombatTracking175 only while a rabbit is
    -- actually targeted.
    SetLegacyReleaseEvent180("CHAT_MSG_LOOT", IncompleteAchievement180(self, "B076"))
    SetLegacyReleaseEvent180("SKILL_LINES_CHANGED", AnyIncompleteAchievement180(self, { "B080", "B081" }))
    local underBannerNeeded180 = IncompleteAchievement180(self, "UNDER_BANNER")
    SetLegacyReleaseEvent180("PLAYER_EQUIPMENT_CHANGED", underBannerNeeded180)
    -- CommunityEnhancements carried a second equipment listener for the same
    -- achievement. Retire/re-enable both owners together so a completed tabard
    -- achievement really becomes silent, including after backup import/undo.
    SetNamedLegacyEvent180("OTLGM_Release175R4Event", "PLAYER_EQUIPMENT_CHANGED", underBannerNeeded180)

    -- PLAYER_TARGET_CHANGED used to remain attached forever even after the
    -- rabbit achievement was complete. It is a high-frequency gameplay event;
    -- faction observation may piggyback while the tracker is legitimately open,
    -- but cosmetic statistics never justify a permanent target listener.
    SetLegacyReleaseEvent180("PLAYER_TARGET_CHANGED", IncompleteAchievement180(self, "B085"))

    local duelNeeded180 = AnyIncompleteAchievement180(self, { "B056", "B057", "B059", "B060" })
    SetLegacyReleaseEvent180("DUEL_REQUESTED", duelNeeded180)
    SetLegacyReleaseEvent180("DUEL_FINISHED", duelNeeded180)
    SetLegacyReleaseEvent180("DUEL_OUTOFBOUNDS", duelNeeded180)
    SetLegacyReleaseEvent180("CHAT_MSG_SYSTEM", duelNeeded180)

    -- The base achievements frame listens to every nearby text emote solely for
    -- the three coordinated roar/dance/kneel secrets. Once all three are earned
    -- there is no reason to parse ambient emote traffic for the rest of the
    -- session. Backup restore can re-enable it through this same ownership pass.
    SetNamedLegacyEvent180("OTLGM_AchievementsEvent174", "CHAT_MSG_TEXT_EMOTE",
        AnyIncompleteAchievement180(self, { "A081", "A082", "A083" }))

    -- A027 is purely local trade-partner progress. Its four trade UI events can
    -- disappear completely once the achievement is complete. This is also
    -- restore-safe because import/undo runs the same ownership pass.
    local tradePartnerNeeded180 = IncompleteAchievement180(self, "A027")
    SetNamedLegacyEvent180("OTLGM_AchievementsEvent174", "TRADE_SHOW", tradePartnerNeeded180)
    SetNamedLegacyEvent180("OTLGM_AchievementsEvent174", "TRADE_ACCEPT_UPDATE", tradePartnerNeeded180)
    SetNamedLegacyEvent180("OTLGM_AchievementsEvent174", "TRADE_CLOSED", tradePartnerNeeded180)
    SetNamedLegacyEvent180("OTLGM_AchievementsEvent174", "TRADE_REQUEST_CANCEL", tradePartnerNeeded180)

    -- The release-layer craft confirmations exist only for B079. The base
    -- profession listeners remain untouched for their own skill/recipe goals.
    local craftCountNeeded180 = IncompleteAchievement180(self, "B079")
    SetLegacyReleaseEvent180("TRADE_SKILL_UPDATE", craftCountNeeded180)
    SetLegacyReleaseEvent180("CRAFT_UPDATE", craftCountNeeded180)
    if not craftCountNeeded180 and self.runtime then self.runtime.pendingCraft175 = nil end

    -- The original 1.7.4 boss frame parsed target changes and combat-death text
    -- in the open world even though GetCurrentInstanceRule174() would reject
    -- every one of those events. Keep the victory stream only inside a known
    -- supported instance, and keep encounter/death bookkeeping only while the
    -- two achievements that require an encounter history are still incomplete.
    -- A082 also needs boss victory to open its post-kill dance window.
    local inTrackedInstance180 = false
    if self and self.GetCurrentInstanceRule174 then
        local instanceOk180, instanceRule180 = pcall(self.GetCurrentInstanceRule174, self)
        inTrackedInstance180 = instanceOk180 and instanceRule180 and true or false
    end
    local bossVictoryNeeded180 = inTrackedInstance180 and AnyIncompleteAchievement180(self, {
        "A043", "A044", "A047", "A049", "A050", "A051", "A052",
        "A054", "A055", "A059", "A064", "A084", "A082",
    })
    local bossEncounterNeeded180 = inTrackedInstance180 and AnyIncompleteAchievement180(self, { "A047", "A059" })
    SetNamedLegacyEvent180("OTLGM_AchievementsEvent174", "CHAT_MSG_COMBAT_HOSTILE_DEATH", bossVictoryNeeded180)
    SetNamedLegacyEvent180("OTLGM_AchievementsEvent174", "PLAYER_TARGET_CHANGED", bossEncounterNeeded180)
    SetNamedLegacyEvent180("OTLGM_AchievementsEvent174", "PLAYER_REGEN_DISABLED", bossEncounterNeeded180)
    SetNamedLegacyEvent180("OTLGM_AchievementsEvent174", "PLAYER_REGEN_ENABLED", bossEncounterNeeded180)
    SetNamedLegacyEvent180("OTLGM_AchievementsEvent174", "CHAT_MSG_COMBAT_FRIENDLY_DEATH", bossEncounterNeeded180)
    if not bossEncounterNeeded180 and self.runtime then self.runtime.bossEncounter174 = nil end

    local gravityNeeded = IncompleteAchievement180(self, "D021")
        and self and self.NeedsGravityTracking180 and self:NeedsGravityTracking180() or false
    SetFinalAchievementEvent180("PLAYER_DEAD", gravityNeeded)
    SetFinalAchievementEvent180("CHAT_MSG_COMBAT_SELF_HITS", gravityNeeded)
    SetFinalAchievementEvent180("CHAT_MSG_SPELL_SELF_DAMAGE", gravityNeeded)
    if not gravityNeeded and self and self.runtime then self.runtime.pendingFallR6 = nil end
end

function OTLGM:UpdateFinalAchievementOwnership180()
    UpdateSafeAchievementEventOwnership180(self)
    return true
end

finalAchievementFrame180:SetScript("OnEvent", function()
    if not OTLGM then return end
    local currentEvent180 = event
    if currentEvent180 == "PLAYER_LOGIN" or currentEvent180 == "PLAYER_ENTERING_WORLD" then
        if OTLGM.EnsureSafeActivityHooks180 then pcall(OTLGM.EnsureSafeActivityHooks180, OTLGM) end
        if OTLGM.RefreshObservedGuildFactions180 then pcall(OTLGM.RefreshObservedGuildFactions180, OTLGM, currentEvent180) end
        UpdateSafeAchievementEventOwnership180(OTLGM)
        -- Some Vanilla-derived clients settle GetRealZoneText a moment after
        -- PLAYER_ENTERING_WORLD. Recheck context ownership once after the cold
        -- transition so instance boss listeners cannot remain incorrectly off
        -- merely because the zone name was temporarily empty.
        if currentEvent180 == "PLAYER_ENTERING_WORLD" and OTLGM.ScheduleAfter180 then
            OTLGM:ScheduleAfter180("achievement-instance-ownership", 1, function(owner)
                if owner and owner.UpdateFinalAchievementOwnership180 then owner:UpdateFinalAchievementOwnership180() end
            end, -1)
        end
        return
    elseif currentEvent180 == "PARTY_MEMBERS_CHANGED" or currentEvent180 == "RAID_ROSTER_UPDATE" then
        if OTLGM.RefreshObservedGuildFactions180 then pcall(OTLGM.RefreshObservedGuildFactions180, OTLGM, currentEvent180) end
        UpdateSafeAchievementEventOwnership180(OTLGM)
        return
    end

    if OTLGM.HandleSafeActivityEvent180 then
        local ok180, problem180 = pcall(OTLGM.HandleSafeActivityEvent180, OTLGM, currentEvent180, arg1, arg2)
        if not ok180 and OTLGM.RecordInternalIssueRC3 then
            pcall(OTLGM.RecordInternalIssueRC3, OTLGM, "ACHIEVEMENT/SAFE_EVENT_" .. tostring(currentEvent180 or "UNKNOWN"), problem180)
        end
    end
    -- Successful completion immediately releases event ownership; completed
    -- trackers therefore add no permanent idle listeners for the rest of the
    -- session.
    UpdateSafeAchievementEventOwnership180(OTLGM)
end)

OTLGM.performance176.finalAchievementBridge180 = true
