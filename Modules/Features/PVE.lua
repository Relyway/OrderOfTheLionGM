-- Order of the Lion Guild Manager
-- Guild PvE groups, applications, board and raid-domain stages.

OTLGM.pveProtocol = "P1"
OTLGM.pveRequestLifetime = 3600
OTLGM.pveBoardLifetime = 172800

local PVE_C0_PENDING_TTL = 90
local PVE_C0_PENDING_OBJECT_LIMIT = 80
local PVE_C0_PENDING_PACKET_LIMIT = 80
local PVE_C0_TEAM_LIMIT = 24
local PVE_C0_TEAM_TOMBSTONE_LIMIT = 120
local PVE_C0_MEMBER_LIMIT = 60
local PVE_C0_INVITE_SESSION_LIMIT = 24

local function PveTrim(text)
    text = text or ""
    return string.gsub(text, "^%s*(.-)%s*$", "%1")
end

local function PveNormalizeName(name)
    name = PveTrim(name or "")
    name = string.gsub(name, "%-.*$", "")
    return string.lower(name)
end

local function PveMapTimestamp180(value)
    if type(value) ~= "table" then return tonumber(value) or 0 end
    return tonumber(value.ts or value.updatedAt or value.updated or value.created or value.expires) or 0
end

local function PvePruneOldestMap180(map, maximum)
    if type(map) ~= "table" then return false end
    local rows = {}
    local key, value
    for key, value in pairs(map) do table.insert(rows, { key = key, ts = PveMapTimestamp180(value) }) end
    if table.getn(rows) <= maximum then return false end
    table.sort(rows, function(left, right)
        if left.ts ~= right.ts then return left.ts < right.ts end
        return tostring(left.key) < tostring(right.key)
    end)
    local index
    for index = 1, table.getn(rows) - maximum do map[rows[index].key] = nil end
    return true
end

local function PveSafeText(text, maxLength)
    text = PveTrim(text or "")
    text = string.gsub(text, "[\r\n\t]", " ")
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "%^", "'")
    text = string.gsub(text, "|", "/")
    if maxLength then text = OTLGM:Utf8Truncate(text, maxLength) end
    return text
end

local function PveSafeUrl180(text, maxLength)
    text = PveSafeText(text or "", maxLength or 56)
    if text == "" then return "" end
    local lower = string.lower(text)
    if string.find(lower, "^https://") or string.find(lower, "^http://")
        or string.find(lower, "^discord%.gg/") or string.find(lower, "^www%.") then return text end
    -- Plain invite text is allowed, but anything that resembles an unapproved
    -- executable/custom URI scheme is discarded.
    if string.find(text, ":", 1, true) then return "" end
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

local function PveSortedValues(map, comparator)
    local list = {}
    local key, value
    for key, value in pairs(map or {}) do table.insert(list, value) end
    table.sort(list, comparator)
    return list
end

function OTLGM:EnsurePveDB()
    -- Runtime queues must exist even when the character is temporarily outside a guild.
    -- Saved guild PvE data remains unavailable until GetGuildDB() is valid.
    self.runtime = self.runtime or {}
    self.runtime.pve = self.runtime.pve or {}
    if type(self.runtime.pve.pendingGroupMeta180) ~= "table" then self.runtime.pve.pendingGroupMeta180 = {} end
    if type(self.runtime.pve.pendingTeamPackets180) ~= "table" then self.runtime.pve.pendingTeamPackets180 = {} end
    if type(self.runtime.pve.pendingGroupMatchEval180) ~= "table" then self.runtime.pve.pendingGroupMatchEval180 = {} end
    if type(self.runtime.raidInviteSession180) ~= "table" then self.runtime.raidInviteSession180 = {} end

    local db = self:GetGuildDB()
    if not db then return nil end
    if type(db.pve) ~= "table" then db.pve = {} end
    if type(db.pve.requests) ~= "table" then db.pve.requests = {} end
    if type(db.pve.board) ~= "table" then db.pve.board = {} end
    if type(db.pve.applications) ~= "table" then db.pve.applications = {} end
    if type(db.pve.deleted) ~= "table" then db.pve.deleted = {} end
    if type(db.pve.unread) ~= "table" then db.pve.unread = { RAIDS = 0, GROUPS = 0, BOARD = 0 } end
    if type(db.pve.reminded) ~= "table" then db.pve.reminded = {} end
    if type(db.pve.raids) ~= "table" then db.pve.raids = {} end
    if type(db.pve.raidTeams180) ~= "table" then db.pve.raidTeams180 = {} end
    if type(db.pve.raidTeamDeleted180) ~= "table" then db.pve.raidTeamDeleted180 = {} end
    if db.pve.raid and db.pve.raid.id then db.pve.raids[db.pve.raid.id] = db.pve.raid end
    if type(db.pve.applicationRetries) ~= "table" then db.pve.applicationRetries = {} end
    db.pve.lastSync = db.pve.lastSync or 0
    db.pve.lastConfirmedSync180 = db.pve.lastConfirmedSync180 or 0
    db.pve.raidInviteSession180 = nil
    local eventId, event
    for eventId, event in pairs(db.pve.raids) do
        if type(event) == "table" and type(event.roster180) ~= "table" then event.roster180 = {} end
    end

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
    if OTLGM_DB.settings.pveMatchingGroupNotifications180 == nil then OTLGM_DB.settings.pveMatchingGroupNotifications180 = true end
    if OTLGM_DB.settings.c7MatchingGroups180 == nil then OTLGM_DB.settings.c7MatchingGroups180 = true end
    if OTLGM_DB.settings.c7AssignedRaidUpdates180 == nil then OTLGM_DB.settings.c7AssignedRaidUpdates180 = true end
    if OTLGM_DB.settings.c7RaidInviteStart180 == nil then OTLGM_DB.settings.c7RaidInviteStart180 = true end
    OTLGM_DB.settings.pveMinLevel180 = OTLGM_DB.settings.pveMinLevel180 or ""
    OTLGM_DB.settings.pveMaxLevel180 = OTLGM_DB.settings.pveMaxLevel180 or ""
    return db.pve
end

function OTLGM:GetPveAccountState180()
    if self.GetAccountPveDB180 then return self:GetAccountPveDB180() end
    OTLGM_DB.pve = type(OTLGM_DB.pve) == "table" and OTLGM_DB.pve or {}
    OTLGM_DB.pve.characterProfiles180 = type(OTLGM_DB.pve.characterProfiles180) == "table" and OTLGM_DB.pve.characterProfiles180 or {}
    OTLGM_DB.pve.groupMatchSeen180 = type(OTLGM_DB.pve.groupMatchSeen180) == "table" and OTLGM_DB.pve.groupMatchSeen180 or {}
    OTLGM_DB.pve.raidAccessSeen180 = type(OTLGM_DB.pve.raidAccessSeen180) == "table" and OTLGM_DB.pve.raidAccessSeen180 or {}
    return OTLGM_DB.pve
end

local PVE_PROFILE_NOTE_LIMIT180 = 44
local PVE_PROFILE_LIMIT180 = 20
local PVE_PROFILE_ROLES180 = { "TANK", "HEAL", "DPS" }
local PVE_GROUP_MATCH_PER_CHARACTER_LIMIT180 = 240
local PVE_GROUP_MATCH_CHARACTER_LIMIT180 = 20
local PVE_GROUP_MATCH_EVAL_LIMIT180 = 80
local PVE_GROUP_LEVEL_CAP180 = 60

local function PveProfileRealm180()
    local realm = GetRealmName and GetRealmName() or nil
    if (not realm or realm == "") and GetCVar then realm = GetCVar("realmName") end
    realm = PveSafeText(realm or "UnknownRealm", 32)
    if realm == "" then realm = "UnknownRealm" end
    return realm
end

local function PveSuggestedRoles180(classToken)
    classToken = string.upper(tostring(classToken or ""))
    if classToken == "WARRIOR" then return { TANK = true, DPS = true } end
    if classToken == "PALADIN" or classToken == "DRUID" then return { TANK = true, HEAL = true, DPS = true } end
    if classToken == "PRIEST" or classToken == "SHAMAN" then return { HEAL = true, DPS = true } end
    if classToken == "MAGE" or classToken == "ROGUE" or classToken == "HUNTER" or classToken == "WARLOCK" then return { DPS = true } end
    return { DPS = true }
end

local function PveProfileHasRoles180(profile)
    if type(profile) ~= "table" or type(profile.roles) ~= "table" then return false end
    return profile.roles.TANK == true or profile.roles.HEAL == true or profile.roles.DPS == true
end

function OTLGM:GetPveCharacterProfileKey180()
    local realm = PveProfileRealm180()
    local name = PveSafeText(UnitName("player") or "Unknown", 28)
    name = string.gsub(name, "%-.*$", "")
    if name == "" then name = "Unknown" end
    return string.lower(realm) .. ":" .. string.lower(name), realm, name
end

function OTLGM:EnsurePveCharacterProfile180()
    local state = self:GetPveAccountState180()
    if not state then return nil end
    local key, realm, name = self:GetPveCharacterProfileKey180()
    local profile = state.characterProfiles180[key]
    local created = type(profile) ~= "table"
    if created then profile = {} state.characterProfiles180[key] = profile end
    if type(profile.roles) ~= "table" then profile.roles = {} end

    local localizedClass, classToken = UnitClass("player")
    classToken = string.upper(tostring(classToken or localizedClass or ""))
    localizedClass = PveSafeText(localizedClass or classToken or "Unknown", 24)
    local level = math.max(1, tonumber(UnitLevel("player")) or tonumber(profile.level) or 1)
    local now = self:Now()

    if not profile.suggestionsApplied180 then
        if not PveProfileHasRoles180(profile) then
            local suggested = PveSuggestedRoles180(classToken)
            local index, role
            for index = 1, table.getn(PVE_PROFILE_ROLES180) do
                role = PVE_PROFILE_ROLES180[index]
                profile.roles[role] = suggested[role] == true
            end
        end
        profile.suggestionsApplied180 = true
    end
    local index, role
    for index = 1, table.getn(PVE_PROFILE_ROLES180) do
        role = PVE_PROFILE_ROLES180[index]
        profile.roles[role] = profile.roles[role] == true
    end
    if profile.notify == nil then profile.notify = true end
    profile.notify = profile.notify == true
    profile.defaultNote = PveSafeText(profile.defaultNote or "", PVE_PROFILE_NOTE_LIMIT180)
    profile.key = key
    profile.realm = realm
    profile.name = name
    profile.class = classToken
    profile.className = localizedClass
    profile.level = level
    profile.createdAt = tonumber(profile.createdAt) or now
    profile.updatedAt = tonumber(profile.updatedAt) or now
    profile.lastSeen = now
    profile.ts = now
    PvePruneOldestMap180(state.characterProfiles180, PVE_PROFILE_LIMIT180)
    return profile, key, created
end

function OTLGM:SetPveCharacterProfileRole180(role, enabled)
    role = string.upper(tostring(role or ""))
    if role ~= "TANK" and role ~= "HEAL" and role ~= "DPS" then return false, "Unknown group role." end
    local profile = self:EnsurePveCharacterProfile180()
    if not profile then return false, "Character profile is unavailable." end
    profile.roles[role] = enabled and true or false
    profile.updatedAt = self:Now()
    profile.ts = profile.updatedAt
    return true, profile
end

function OTLGM:SetPveCharacterProfileNotify180(enabled)
    local profile = self:EnsurePveCharacterProfile180()
    if not profile then return false, "Character profile is unavailable." end
    profile.notify = enabled and true or false
    profile.updatedAt = self:Now()
    profile.ts = profile.updatedAt
    return true, profile
end

function OTLGM:SetPveCharacterProfileNote180(note)
    local profile = self:EnsurePveCharacterProfile180()
    if not profile then return false, "Character profile is unavailable." end
    profile.defaultNote = PveSafeText(note or "", PVE_PROFILE_NOTE_LIMIT180)
    profile.updatedAt = self:Now()
    profile.ts = profile.updatedAt
    return true, profile
end

function OTLGM:IsPveGroupMatchingEnabled180(profile)
    profile = profile or self:EnsurePveCharacterProfile180()
    if OTLGM_DB.settings.pveMatchingGroupNotifications180 == false or OTLGM_DB.settings.c7MatchingGroups180 == false then return false, "global-off" end
    if not profile or profile.notify ~= true then return false, "profile-off" end
    if not PveProfileHasRoles180(profile) then return false, "no-roles" end
    return true, "enabled"
end


local function PveGroupNormalizeLevelRange180(minLevel, maxLevel)
    local function normalize(value)
        value = PveTrim(tostring(value or ""))
        if value == "" then return nil end
        value = tonumber(value)
        if not value then return nil, "Preferred levels must be numbers." end
        value = math.floor(value)
        if value < 1 or value > PVE_GROUP_LEVEL_CAP180 then
            return nil, "Preferred levels must be between 1 and " .. tostring(PVE_GROUP_LEVEL_CAP180) .. "."
        end
        return value
    end
    local minimum, minError = normalize(minLevel)
    if minError then return nil, nil, minError end
    local maximum, maxError = normalize(maxLevel)
    if maxError then return nil, nil, maxError end
    if minimum and maximum and minimum > maximum then return nil, nil, "Minimum level cannot be higher than maximum level." end
    return minimum, maximum, nil
end

function OTLGM:NormalizePveGroupLevelRange180(minLevel, maxLevel)
    return PveGroupNormalizeLevelRange180(minLevel, maxLevel)
end

function OTLGM:GetPveGroupMatchSignature180(group)
    if type(group) ~= "table" then return "" end
    local minimum = tonumber(group.minLevel180 or group.minLevel) or 0
    local maximum = tonumber(group.maxLevel180 or group.maxLevel) or 0
    return table.concat({
        tostring(math.max(0, tonumber(group.needTank) or 0)),
        tostring(math.max(0, tonumber(group.needHeal) or 0)),
        tostring(math.max(0, tonumber(group.needDps) or 0)),
        tostring(minimum), tostring(maximum),
    }, ":")
end

function OTLGM:GetPveGroupMatchSeenMap180()
    local state = self:GetPveAccountState180()
    if not state then return nil end
    local characterKey = self:GetPveCharacterProfileKey180()
    local map = state.groupMatchSeen180[characterKey]
    if type(map) ~= "table" then map = {} state.groupMatchSeen180[characterKey] = map end
    PvePruneOldestMap180(map, PVE_GROUP_MATCH_PER_CHARACTER_LIMIT180)
    PvePruneOldestMap180(state.groupMatchSeen180, PVE_GROUP_MATCH_CHARACTER_LIMIT180)
    return map, characterKey
end

function OTLGM:GetPveGroupMatch180(group, profile)
    if type(group) ~= "table" then return false, "missing" end
    if self:IsOwnPveGroup(group) then return false, "own" end
    if self:GetPveGroupStatus(group) ~= "OPEN" then return false, "inactive" end
    profile = profile or self:EnsurePveCharacterProfile180()
    local enabled, disabledReason = self:IsPveGroupMatchingEnabled180(profile)
    if not enabled then return false, disabledReason end
    local roles = profile.roles or {}
    local matches = {
        TANK = roles.TANK == true and (tonumber(group.needTank) or 0) > 0,
        HEAL = roles.HEAL == true and (tonumber(group.needHeal) or 0) > 0,
        DPS = roles.DPS == true and (tonumber(group.needDps) or 0) > 0,
    }
    local role
    if matches.TANK then role = "TANK" elseif matches.HEAL then role = "HEAL" elseif matches.DPS then role = "DPS" end
    if not role then return false, "role" end
    local level = tonumber(profile.level) or tonumber(UnitLevel("player")) or 1
    local minimum = tonumber(group.minLevel180 or group.minLevel)
    local maximum = tonumber(group.maxLevel180 or group.maxLevel)
    if minimum and minimum > 0 and level < minimum then return false, "level-low", role end
    if maximum and maximum > 0 and level > maximum then return false, "level-high", role end
    return true, "match", role
end

function OTLGM:IsPveGroupColdSync180(channel)
    if channel ~= "WHISPER" then return false end
    local now = self:Now()
    local pending = self.pveSyncPending180
    if type(pending) == "table" and now - (tonumber(pending.startedAt) or 0) <= 30 then return true end
    local pve = self:EnsurePveDB()
    return pve and now - (tonumber(pve.lastSync) or 0) <= 30
end

function OTLGM:SchedulePveGroupMatchEvaluation180(groupId, channel, sender)
    self:EnsurePveDB()
    if channel ~= "GUILD" then return false end
    groupId = tostring(groupId or "")
    if groupId == "" then return false end
    local pending = self.runtime.pve.pendingGroupMatchEval180
    pending[groupId] = { due = self:Now() + 1, ts = self:Now(), channel = channel, sender = sender }
    PvePruneOldestMap180(pending, PVE_GROUP_MATCH_EVAL_LIMIT180)
    if self.WakeScheduler180 then self:WakeScheduler180("pve-group-match") end
    return true
end

function OTLGM:EvaluatePveGroupMatch180(group, remote, channel)
    if not remote or channel ~= "GUILD" or type(group) ~= "table" then return nil, "not-live" end
    local profile = self:EnsurePveCharacterProfile180()
    local match, reason, role = self:GetPveGroupMatch180(group, profile)
    local seen = self:GetPveGroupMatchSeenMap180()
    if not seen then return nil, "state" end
    local signature = self:GetPveGroupMatchSignature180(group)
    local previous = seen[group.id]
    if not match then
        -- Store only relevant-edit state. Count/note refreshes have the same
        -- signature and therefore never manufacture a later duplicate toast.
        seen[group.id] = { ts = self:Now(), signature = signature, matched = false, reason = reason }
        return nil, reason
    end
    if type(previous) == "table" and previous.matched == true then
        previous.ts = self:Now()
        previous.signature = signature
        return role, "seen"
    end
    seen[group.id] = { ts = self:Now(), signature = signature, matched = true, role = role }
    PvePruneOldestMap180(seen, PVE_GROUP_MATCH_PER_CHARACTER_LIMIT180)
    local level = tonumber(profile and profile.level) or tonumber(UnitLevel("player")) or 1
    local roleLabel = role == "TANK" and "Tank" or (role == "HEAL" and "Healer" or "Damage")
    local title = tostring(group.activity or "Guild group") .. " needs a level " .. tostring(level) .. " " .. roleLabel
    if self.NotifyEvent152 then
        self:NotifyEvent152("group", "GROUP_MATCH:" .. tostring(group.id) .. ":" .. signature,
            title, "Open the exact group to review or apply.", "ACTION", true, "pve", {
                objectType = "GROUP", objectId = group.id, section = "GROUPS", actionKey = "MATCH",
            })
    end
    return role, "notified"
end

function OTLGM:ProcessPveGroupMatching180()
    local pending = self.runtime and self.runtime.pve and self.runtime.pve.pendingGroupMatchEval180
    if type(pending) ~= "table" then return end
    local now = self:Now()
    local groupId, entry
    for groupId, entry in pairs(pending) do
        if type(entry) ~= "table" or (tonumber(entry.due) or 0) <= now then
            pending[groupId] = nil
            local group = self:GetPveRequestByID(groupId)
            if group then self:EvaluatePveGroupMatch180(group, true, entry and entry.channel or "GUILD") end
            break
        end
    end
end

function OTLGM:GetPveProfileJoinRole180(group)
    local profile = self:EnsurePveCharacterProfile180()
    if not profile or not PveProfileHasRoles180(profile) then return OTLGM_DB.settings.pveJoinRole or "DPS" end
    local needs = {
        TANK = not group or (tonumber(group.needTank) or 0) > 0,
        HEAL = not group or (tonumber(group.needHeal) or 0) > 0,
        DPS = not group or (tonumber(group.needDps) or 0) > 0,
    }
    local current = OTLGM_DB.settings.pveJoinRole or "DPS"
    if profile.roles[current] and needs[current] then return current end
    local order = { "TANK", "HEAL", "DPS" }
    local index, role
    for index = 1, table.getn(order) do role = order[index] if profile.roles[role] and needs[role] then return role end end
    for index = 1, table.getn(order) do role = order[index] if profile.roles[role] then return role end end
    return current
end

function OTLGM:PreparePveJoinDefaults180(groupId, force)
    if not self.ui then return false end
    groupId = tostring(groupId or "")
    if groupId == "" then return false end
    if not force and self.ui.pveJoinDefaultsGroup180 == groupId then return false end
    local group = self:GetPveRequestByID(groupId)
    local profile = self:EnsurePveCharacterProfile180()
    if not group or not profile then return false end
    OTLGM_DB.settings.pveJoinRole = self:GetPveProfileJoinRole180(group)
    if self.ui.pveJoinNoteEdit then
        self.ui.pveJoinNoteEdit.otlSilent = true
        self.ui.pveJoinNoteEdit:SetText(profile.defaultNote or "")
        self.ui.pveJoinNoteEdit.otlSilent = nil
    end
    self.ui.pveJoinDefaultsGroup180 = groupId
    return true
end

function OTLGM:RefreshCurrentPveCharacterProfile180(levelOverride)
    local profile = self:EnsurePveCharacterProfile180()
    if not profile then return false end
    local level = tonumber(levelOverride) or tonumber(UnitLevel("player")) or profile.level
    if level and level > 0 and profile.level ~= level then
        profile.level = level
        profile.updatedAt = self:Now()
        profile.ts = profile.updatedAt
    end
    if self.ui and self.ui.currentPage == "pve" and self.RefreshPveCharacterProfile180 then self:RefreshPveCharacterProfile180() end
    return true
end

function OTLGM:GetPendingPveGroupMeta180()
    self:EnsurePveDB()
    return self.runtime.pve.pendingGroupMeta180
end

function OTLGM:GetPendingPveTeamPackets180()
    self:EnsurePveDB()
    return self.runtime.pve.pendingTeamPackets180
end

local function PveNextWeeklyStart(startTs, now)
    startTs = tonumber(startTs) or 0
    now = tonumber(now) or time()
    if startTs <= 0 then return 0 end
    while startTs + 14400 <= now do startTs = startTs + (7 * 86400) end
    return startTs
end

function OTLGM:GetPveRaids()
    local pve=self:EnsurePveDB(); if not pve then return {} end
    self:PurgePveData(true)
    local list={}; local _,raid
    for _,raid in pairs(pve.raids or {}) do table.insert(list,raid) end
    table.sort(list,function(a,b) if (a.startTs or 0)~=(b.startTs or 0) then return (a.startTs or 0)<(b.startTs or 0) end return tostring(a.id)<tostring(b.id) end)
    return list
end

function OTLGM:NormalizePveGroupNeeds155(maxSize,leaderRole,needTank,needHeal,needDps)
    maxSize=math.max(2,math.min(40,tonumber(maxSize) or 5))
    local slots=maxSize-1
    needTank=math.max(0,math.min(slots,tonumber(needTank) or 0))
    needHeal=math.max(0,math.min(slots,tonumber(needHeal) or 0))
    needDps=math.max(0,math.min(slots,tonumber(needDps) or 0))
    if needTank+needHeal+needDps<=0 then
        if leaderRole=="TANK" then needTank,needHeal,needDps=0,1,math.max(0,slots-1)
        elseif leaderRole=="HEAL" then needTank,needHeal,needDps=1,0,math.max(0,slots-1)
        else needTank,needHeal,needDps=1,1,math.max(0,slots-2) end
    end
    while needTank+needHeal+needDps>slots do
        if needDps>0 then needDps=needDps-1 elseif needHeal>0 then needHeal=needHeal-1 elseif needTank>0 then needTank=needTank-1 end
    end
    return maxSize,needTank,needHeal,needDps
end

function OTLGM.__impl180.Stage_PVE_PurgePveData_1__impl1(self, silent)
    local pve=self:EnsurePveDB(); if not pve then return false end
    local now=self:Now(); local changed=false; local id,record
    for id,record in pairs(pve.requests) do if not record.expires or record.expires<=now then pve.requests[id]=nil changed=true end end
    for id,record in pairs(pve.board) do if not record.expires or record.expires<=now then pve.board[id]=nil changed=true end end
    for id,record in pairs(pve.applications or {}) do
        if not record.expires or record.expires<=now or (record.groupId and not pve.requests[record.groupId] and record.status=="PENDING") then pve.applications[id]=nil changed=true end
    end
    for id,record in pairs(pve.raids or {}) do
        if record.recurring=="WEEKLY" then record.startTs=PveNextWeeklyStart(record.startTs,now); if self.GetPveRaidServerTime155 then record.serverTime=self:GetPveRaidServerTime155(record) end
        elseif not record.startTs or record.startTs+14400<=now then pve.raids[id]=nil changed=true end
    end
    self:RefreshNearestRaid155()
    for id,record in pairs(pve.deleted) do if not record.ts or record.ts+(30*86400)<=now then pve.deleted[id]=nil end end
    for id,record in pairs(pve.applicationRetries or {}) do if not record.due or record.due+60<now then pve.applicationRetries[id]=nil end end

    -- C0 delivery-order buffers are short-lived and globally bounded. Cleanup
    -- runs only through existing maintenance/reads; no polling loop is added.
    local pendingGroup = self:GetPendingPveGroupMeta180()
    local bucketKey, bucket, entryKey, entry
    for bucketKey,bucket in pairs(pendingGroup or {}) do
        if type(bucket) ~= "table" or (tonumber(bucket.expires) or 0) <= now then
            pendingGroup[bucketKey] = nil
        elseif type(bucket.entries) == "table" then
            for entryKey,entry in pairs(bucket.entries) do
                if type(entry) ~= "table" or (tonumber(entry.expires) or 0) <= now then bucket.entries[entryKey] = nil end
            end
            local hasEntry=false
            for entryKey in pairs(bucket.entries) do hasEntry=true break end
            if not hasEntry then pendingGroup[bucketKey]=nil end
        end
    end
    PvePruneOldestMap180(pendingGroup, PVE_C0_PENDING_OBJECT_LIMIT)

    local pendingPackets = self:GetPendingPveTeamPackets180()
    for bucketKey,bucket in pairs(pendingPackets or {}) do
        if type(bucket) ~= "table" then
            pendingPackets[bucketKey]=nil
        else
            local kept={}
            local packetIndex,packet
            for packetIndex=1,table.getn(bucket) do
                packet=bucket[packetIndex]
                if type(packet)=="table" and (tonumber(packet.expires) or 0)>now then table.insert(kept,packet) end
            end
            kept.ts=tonumber(bucket.ts) or now
            if table.getn(kept)==0 then pendingPackets[bucketKey]=nil else pendingPackets[bucketKey]=kept end
        end
    end
    PvePruneOldestMap180(pendingPackets, PVE_C0_PENDING_OBJECT_LIMIT)

    local inviteSessions=self.runtime and self.runtime.raidInviteSession180
    for id,record in pairs(inviteSessions or {}) do
        if type(record)~="table" or not self:GetRaidEvent180(id) or (tonumber(record.ts) or 0)+(8*3600)<=now then inviteSessions[id]=nil end
    end
    PvePruneOldestMap180(inviteSessions, PVE_C0_INVITE_SESSION_LIMIT)

    PvePruneOldestMap180(pve.raidTeams180, PVE_C0_TEAM_LIMIT)
    PvePruneOldestMap180(pve.raidTeamDeleted180, PVE_C0_TEAM_TOMBSTONE_LIMIT)
    for id,record in pairs(pve.raidTeams180 or {}) do
        if type(record)=="table" then
            record.members=type(record.members)=="table" and record.members or {}
            PvePruneOldestMap180(record.members,PVE_C0_MEMBER_LIMIT)
        end
    end
    for id,record in pairs(pve.raids or {}) do
        if type(record)=="table" then
            record.roster180=type(record.roster180)=="table" and record.roster180 or {}
            PvePruneOldestMap180(record.roster180,PVE_C0_MEMBER_LIMIT)
        end
    end

    if changed and not silent then self:OnPveDataChanged(nil,false) end
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


function OTLGM:GetOwnPveGroup180()
    local player = PveNormalizeName(UnitName("player") or "")
    local requests = self:GetPveRequests()
    local index
    for index = 1, table.getn(requests) do
        if PveNormalizeName(requests[index].author) == player then return requests[index] end
    end
    return nil
end

function OTLGM:GetPveActualRoster180()
    local members = {}
    local count = 1
    local player = UnitName("player") or ""
    if player ~= "" then members[PveNormalizeName(player)] = true end
    local raidCount = GetNumRaidMembers and tonumber(GetNumRaidMembers()) or 0
    if raidCount and raidCount > 0 then
        count = raidCount
        local index, name
        for index = 1, raidCount do
            name = GetRaidRosterInfo and GetRaidRosterInfo(index) or nil
            if name and name ~= "" then members[PveNormalizeName(name)] = true end
        end
    else
        local partyCount = GetNumPartyMembers and tonumber(GetNumPartyMembers()) or 0
        count = math.max(1, (partyCount or 0) + 1)
        local index, name
        for index = 1, partyCount or 0 do
            name = UnitName and UnitName("party" .. tostring(index)) or nil
            if name and name ~= "" then members[PveNormalizeName(name)] = true end
        end
    end
    return count, members
end

function OTLGM:IsPveActualGroupLeader180()
    local raidCount = GetNumRaidMembers and tonumber(GetNumRaidMembers()) or 0
    if raidCount and raidCount > 0 then
        if IsRaidLeader then return IsRaidLeader() and true or false end
        local player = PveNormalizeName(UnitName("player") or "")
        local index, name, rank
        for index = 1, raidCount do
            name, rank = GetRaidRosterInfo(index)
            if PveNormalizeName(name) == player then return tonumber(rank) == 2 end
        end
        return false
    end
    local partyCount = GetNumPartyMembers and tonumber(GetNumPartyMembers()) or 0
    if not partyCount or partyCount <= 0 then return true end
    if IsPartyLeader then return IsPartyLeader() and true or false end
    return true
end

function OTLGM:GetPveAcceptedNotJoined180(groupId, actualMembers)
    local applications = self:GetPveApplications(groupId, false)
    if type(actualMembers) ~= "table" then local _, members = self:GetPveActualRoster180() actualMembers = members end
    local count = 0
    local index, application
    for index = 1, table.getn(applications) do
        application = applications[index]
        if application.status == "ACCEPTED" and not actualMembers[PveNormalizeName(application.author)] then count = count + 1 end
    end
    return count
end

function OTLGM:GetPveReservedRoles180(groupId, actualMembers)
    local applications = self:GetPveApplications(groupId, false)
    if type(actualMembers) ~= "table" then local _, members = self:GetPveActualRoster180() actualMembers = members end
    local result = { TANK = 0, HEAL = 0, DPS = 0, ANY = 0 }
    local index, application, role
    for index = 1, table.getn(applications) do
        application = applications[index]
        if application.status == "ACCEPTED" and not actualMembers[PveNormalizeName(application.author)] then
            role = application.role
            if result[role] ~= nil then result[role] = result[role] + 1 else result.ANY = result.ANY + 1 end
        end
    end
    return result
end

function OTLGM:GetPveLeaderApplications180(groupId)
    local applications = self:GetPveApplications(groupId, false)
    local _, actualMembers = self:GetPveActualRoster180()
    local result = {}
    local index, application
    for index = 1, table.getn(applications) do
        application = applications[index]
        if application.status == "PENDING" or (application.status == "ACCEPTED" and not actualMembers[PveNormalizeName(application.author)]) then
            table.insert(result, application)
        end
    end
    table.sort(result, function(left, right)
        if left.status ~= right.status then return left.status == "PENDING" end
        return (tonumber(left.ts) or 0) > (tonumber(right.ts) or 0)
    end)
    return result
end

function OTLGM:CancelAcceptedPveApplication180(applicationId)
    local pve = self:EnsurePveDB()
    local application = pve and pve.applications[applicationId]
    local group = application and pve.requests[application.groupId]
    if not application or not group or not self:IsOwnPveGroup(group) then return false, "Only the group leader can reopen this slot." end
    if application.status ~= "ACCEPTED" then return false, "This player does not hold an accepted reservation." end
    local _, members = self:GetPveActualRoster180()
    if members[PveNormalizeName(application.author)] then return false, "This player already joined the group." end
    application.status = "DECLINED"
    application.rev = (tonumber(application.rev) or 0) + 1
    application.ts = self:Now()
    application.joined180 = nil
    application.countedRole180 = nil
    self:QueuePvePayload(self:SerializePveApplication(application), "WHISPER", application.author)
    self:OnPveDataChanged("GROUPS", false)
    return true, application
end

local function PveAdjustNeedForRole180(group, role, delta)
    local field = role == "TANK" and "needTank" or (role == "HEAL" and "needHeal" or "needDps")
    local maximum = math.max(0, (tonumber(group.maxSize) or 5) - 1)
    group[field] = math.max(0, math.min(maximum, (tonumber(group[field]) or 0) + delta))
end

function OTLGM:RefreshOwnPveGroupLiveState180(reason)
    local group = self:GetOwnPveGroup180()
    if not group or self:GetPveGroupStatus(group) == "CLOSED" then return false, "none" end
    if not self:IsPveActualGroupLeader180() then return false, "not-leader" end
    local actualCount, members = self:GetPveActualRoster180()
    actualCount = math.max(1, math.min(40, actualCount or 1))
    local changed = tonumber(group.current) ~= actualCount
    group.current = actualCount
    local applications = self:GetPveApplications(group.id, false)
    local index, application, joined
    if group.liveState180 ~= true then
        -- Existing pre-C4 groups may already have had their role counts reduced
        -- by the old accept path. Establish a baseline without reducing twice.
        for index = 1, table.getn(applications) do
            application = applications[index]
            if application.status == "ACCEPTED" and members[PveNormalizeName(application.author)] then
                application.joined180 = true
                application.countedRole180 = true
            end
        end
        group.liveState180 = true
    else
        for index = 1, table.getn(applications) do
            application = applications[index]
            if application.status == "ACCEPTED" then
                joined = members[PveNormalizeName(application.author)] and true or false
                if joined and not application.joined180 then
                    application.joined180 = true
                    if not application.countedRole180 then
                        PveAdjustNeedForRole180(group, application.role, -1)
                        application.countedRole180 = true
                    end
                    changed = true
                elseif not joined and application.joined180 then
                    application.joined180 = nil
                    if application.countedRole180 then
                        PveAdjustNeedForRole180(group, application.role, 1)
                        application.countedRole180 = nil
                    end
                    changed = true
                end
            end
        end
    end
    group.acceptedNotJoined180 = self:GetPveAcceptedNotJoined180(group.id, members)
    local newStatus = self:GetPveGroupStatus(group)
    if group.status ~= newStatus then group.status = newStatus changed = true end
    if not changed then return false, "unchanged" end
    group.rev = (tonumber(group.rev) or 0) + 1
    group.ts = self:Now()
    self:QueuePveGroupRecord180(group, "GUILD")
    self:OnPveDataChanged("GROUPS", false)
    return true, reason or "roster"
end

function OTLGM:SchedulePveGroupLiveState180(reason)
    self:EnsurePveDB()
    self.runtime.pve.groupLiveStateDue180 = self:Now() + 1
    self.runtime.pve.groupLiveStateReason180 = reason or "roster"
    if self.WakeScheduler180 then self:WakeScheduler180("pve-live-state") end
    return true
end

function OTLGM:ProcessPveGroupLiveState180()
    local runtime = self.runtime and self.runtime.pve
    if not runtime or not runtime.groupLiveStateDue180 or self:Now() < runtime.groupLiveStateDue180 then return end
    local now = self:Now()
    local pressure = self.GetClientPressure181 and self:GetClientPressure181() or nil
    if self.runtime and self.runtime.transitionActive176 then
        -- Group state is durable bookkeeping, not frame-critical rendering work.
        -- Never compete with a zone load; transition recovery has its own
        -- fail-safe and will wake this exact deadline again.
        runtime.groupLiveStateDue180 = now + 3
        runtime.groupLiveStatePressureDeferrals181 = (tonumber(runtime.groupLiveStatePressureDeferrals181) or 0) + 1
        return false
    end
    if pressure and tonumber(pressure.level) >= 3 then
        runtime.groupLiveStatePressureStarted181 = tonumber(runtime.groupLiveStatePressureStarted181) or now
        if now - runtime.groupLiveStatePressureStarted181 < 30 then
            -- A bounded wait avoids both a weather/city hitch and an eternal
            -- two-second background wake on a permanently slow client.
            runtime.groupLiveStateDue180 = now + 3
            runtime.groupLiveStatePressureDeferrals181 = (tonumber(runtime.groupLiveStatePressureDeferrals181) or 0) + 1
            return false
        end
    end
    local reason = runtime.groupLiveStateReason180
    runtime.groupLiveStateDue180 = nil
    runtime.groupLiveStateReason180 = nil
    runtime.groupLiveStatePressureStarted181 = nil
    self:RefreshOwnPveGroupLiveState180(reason)
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
    return self:RefreshNearestRaid155()
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
    return self:GetPveUnread("RAIDS") + self:GetPveUnread("GROUPS")
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
    return table.concat({ self.pveProtocol, "BOARD", record.id, tostring(record.rev or 1), tostring(record.ts or 0), tostring(record.expires or 0), PveSafeText(record.author, 20), tostring(record.level or 0), PveSafeText(record.class, 16), PveSafeText(record.text, 240) }, "^")
end

function OTLGM.__impl180.Stage_PVE_SerializePveRaid_1__impl1(self, record)
    local displayTime = self.GetPveRaidServerTime155 and self:GetPveRaidServerTime155(record) or tostring(record.serverTime or "")
    return table.concat({self.pveProtocol,"RAID",record.id,tostring(record.rev or 1),tostring(record.ts or 0),tostring(record.startTs or 0),
        PveSafeText(record.author,20),PveSafeText(record.name,36),PveSafeText(record.location,32),PveSafeText(displayTime,28),PveSafeText(record.note,48),
        PveSafeText(record.recurring or "ONCE",8),tostring(record.reminderMinutes or 60),tostring(record.stHour or -1),tostring(record.stMinute or -1)},"^")
end

local stageCPveKinds180 = {
    GMETA1 = true,
    RTEAM1 = true,
    RTMEM1 = true,
    RTDEL1 = true,
    RMETA1 = true,
    RRMEM1 = true,
    RRDEL1 = true,
    RSTATUS1 = true,
    RINV1 = true,
}

local function PveStageCStatus180(value, allowed, fallback)
    value = string.upper(PveSafeText(value or fallback, 18))
    if allowed[value] then return value end
    return fallback
end

local function PveStageCRecentSync180(self, channel)
    if channel ~= "WHISPER" then return false end
    local now = self:Now()
    local pending = self.pveSyncPending180
    if type(pending) == "table" and now - (tonumber(pending.startedAt) or 0) <= 30 then return true end
    local pve = self:EnsurePveDB()
    return pve and now - (tonumber(pve.lastSync) or 0) <= 30
end

local function PveStageCCharacterKey180(value)
    value = PveSafeText(value or "", 48)
    return PveNormalizeName(value)
end

function OTLGM:IsStageCPveMessageKind180(kind)
    return stageCPveKinds180[tostring(kind or "")] and true or false
end

function OTLGM:IsPveGroupMetaSenderAllowed180(record, sender, channel)
    if not sender or sender == "" then return false end
    if record and PveNormalizeName(record.author) == PveNormalizeName(sender) then return true end
    return PveStageCRecentSync180(self, channel)
end

function OTLGM:SerializePveGroupMeta180(record)
    if not record or not record.id then return nil end
    local minLevel = tonumber(record.minLevel180 or record.minLevel)
    local maxLevel = tonumber(record.maxLevel180 or record.maxLevel)
    local flags = PveSafeText(record.matchingFlags180 or "", 24)
    if not minLevel and not maxLevel and flags == "" then return nil end
    minLevel = minLevel and math.max(1, math.min(255, math.floor(minLevel))) or 0
    maxLevel = maxLevel and math.max(1, math.min(255, math.floor(maxLevel))) or 0
    return table.concat({ self.pveProtocol, "GMETA1", record.id, tostring(record.rev or 1), tostring(minLevel), tostring(maxLevel), flags }, "^")
end

function OTLGM:MergePveGroupMeta180(record, meta)
    if not record or type(meta) ~= "table" or tostring(record.id or "") ~= tostring(meta.groupId or "") then return false, "identity" end
    local recordRev = tonumber(record.rev) or 0
    local metaRev = tonumber(meta.rev) or 0
    if recordRev ~= metaRev then return false, recordRev > metaRev and "stale" or "future" end
    if meta.sender and meta.sender ~= "" and not self:IsPveGroupMetaSenderAllowed180(record, meta.sender, meta.channel) then return false, "sender" end
    record.minLevel180 = tonumber(meta.minLevel) and tonumber(meta.minLevel) > 0 and tonumber(meta.minLevel) or nil
    record.maxLevel180 = tonumber(meta.maxLevel) and tonumber(meta.maxLevel) > 0 and tonumber(meta.maxLevel) or nil
    record.matchingFlags180 = PveSafeText(meta.flags or "", 24)
    record.groupMetaRev180 = metaRev
    return true, "merged"
end

local function PveStorePendingGroupMeta180(pending, meta)
    local bucket = pending[meta.groupId]
    if type(bucket) ~= "table" or type(bucket.entries) ~= "table" then
        local old = type(bucket) == "table" and bucket or nil
        bucket = { entries = {}, expires = 0, ts = 0 }
        if old and old.groupId then
            local oldKey = PveNormalizeName(old.sender) .. ":" .. tostring(old.rev or 0)
            bucket.entries[oldKey] = old
            bucket.expires = tonumber(old.expires) or 0
        end
        pending[meta.groupId] = bucket
    end
    local key = PveNormalizeName(meta.sender) .. ":" .. tostring(meta.rev or 0)
    local current = bucket.entries[key]
    if not current or (tonumber(current.ts) or 0) <= (tonumber(meta.ts) or 0) then bucket.entries[key] = meta end
    bucket.expires = math.max(tonumber(bucket.expires) or 0, tonumber(meta.expires) or 0)
    bucket.ts = math.max(tonumber(bucket.ts) or 0, tonumber(meta.ts) or 0)
    local rows = {}
    local entryKey, entry
    for entryKey, entry in pairs(bucket.entries) do table.insert(rows, { key = entryKey, ts = tonumber(entry.ts) or 0 }) end
    if table.getn(rows) > 8 then
        table.sort(rows, function(left, right) return left.ts < right.ts end)
        local index
        for index = 1, table.getn(rows) - 8 do bucket.entries[rows[index].key] = nil end
    end
    return bucket
end

function OTLGM:ApplyPendingPveGroupMeta180(groupId, record)
    local pending = self:GetPendingPveGroupMeta180()
    local bucket = pending[groupId]
    if not bucket then return false, "none" end
    local entries
    if type(bucket) == "table" and type(bucket.entries) == "table" then entries = bucket.entries
    elseif type(bucket) == "table" and bucket.groupId then entries = { legacy = bucket }
    else pending[groupId] = nil return false, "malformed" end
    local mergedAny, lastReason = false, "none"
    local key, meta
    for key, meta in pairs(entries) do
        if type(meta) ~= "table" or (tonumber(meta.expires) or 0) <= self:Now() then
            entries[key] = nil
            lastReason = "expired"
        else
            local merged, reason = self:MergePveGroupMeta180(record, meta)
            lastReason = reason
            if merged then
                mergedAny = true
                local otherKey, other
                for otherKey, other in pairs(entries) do
                    if (tonumber(other.rev) or 0) <= (tonumber(record and record.rev) or 0) then entries[otherKey] = nil end
                end
                break
            elseif reason == "stale" or reason == "sender" or reason == "identity" then
                entries[key] = nil
            end
        end
    end
    local hasEntries = false
    for key in pairs(entries) do hasEntries = true break end
    if not hasEntries then pending[groupId] = nil end
    return mergedAny, lastReason
end

function OTLGM:ApplyRemotePveGroupMeta180(fields, sender, channel)
    local pve = self:EnsurePveDB()
    if not pve then return false end
    local meta = {
        groupId = PveSafeText(fields[3] or "", 64),
        rev = tonumber(fields[4]) or 0,
        minLevel = tonumber(fields[5]) or 0,
        maxLevel = tonumber(fields[6]) or 0,
        flags = PveSafeText(fields[7] or "", 24),
        sender = sender,
        channel = channel,
        ts = self:Now(),
        expires = self:Now() + PVE_C0_PENDING_TTL,
    }
    if meta.groupId == "" or meta.rev < 1 then return false end
    if meta.minLevel < 0 or meta.maxLevel < 0 or meta.minLevel > 255 or meta.maxLevel > 255 then return false end
    if meta.minLevel > 0 and meta.maxLevel > 0 and meta.minLevel > meta.maxLevel then return false end
    local record = pve.requests[meta.groupId]
    if record then
        local recordRev = tonumber(record.rev) or 0
        if recordRev > meta.rev then return true end
        if recordRev == meta.rev then
            local before = self:GetPveGroupMatchSignature180(record)
            local merged, reason = self:MergePveGroupMeta180(record, meta)
            if merged and channel == "GUILD" and before ~= self:GetPveGroupMatchSignature180(record) then
                self:SchedulePveGroupMatchEvaluation180(record.id, channel, sender)
            elseif merged and channel == "GUILD" then
                self:SchedulePveGroupMatchEvaluation180(record.id, channel, sender)
            end
            return merged, reason
        end
    end
    local pending = self:GetPendingPveGroupMeta180()
    PveStorePendingGroupMeta180(pending, meta)
    PvePruneOldestMap180(pending, PVE_C0_PENDING_OBJECT_LIMIT)
    return true
end

function OTLGM:QueuePveGroupRecord180(record, channel, target)
    if not record then return false end
    self:QueuePvePayload(self:SerializePveRequest(record), channel or "GUILD", target)
    local meta = self:SerializePveGroupMeta180(record)
    if meta then self:QueuePvePayload(meta, channel or "GUILD", target) end
    return true
end

function OTLGM:SerializeRaidTeamHeader180(team)
    if not team or not team.id then return nil end
    -- Preserve the original C0 identity/contact field widths, then use only the
    -- remaining part of Transport.lua's 250-byte budget for optional C5 text.
    -- Helper names are fitted as whole comma-separated entries; membership is
    -- still carried independently through RTMEM1 records.
    local core = {
        self.pveProtocol, "RTEAM1", PveSafeText(team.id, 56), tostring(team.rev or 1), tostring(team.ts or self:Now()),
        PveSafeText(team.name, 36), PveSafeText(team.raidLeader, 40), PveSafeText(team.inviteContact, 40),
        PveStageCStatus180(team.status, { ACTIVE = true, ARCHIVED = true }, "ACTIVE"),
    }
    local base = table.concat(core, "^")
    local available = math.max(0, 250 - string.len(base) - 4)
    local helpers, used = {}, 0
    local parts = self:Split(string.gsub(tostring(team.inviteHelpers or ""), ";", ","), ",") or {}
    local index
    for index = 1, table.getn(parts) do
        local name = PveSafeText(parts[index] or "", 40)
        local extra = string.len(name) + (table.getn(helpers) > 0 and 2 or 0)
        if name ~= "" and used + extra <= math.min(62, available) then
            table.insert(helpers, name)
            used = used + extra
        end
    end
    local helperText = table.concat(helpers, ", ")
    local descriptionBudget = math.max(0, math.min(32, available - string.len(helperText)))
    local description = PveSafeText(team.description or "", descriptionBudget)
    return base .. "^" .. description .. "^" .. helperText .. "^" .. (team.primary180 and "1" or "0")
end

local PVE_C5_ROLES180 = { TANK = true, HEALER = true, DAMAGE = true, FLEXIBLE = true, UNASSIGNED = true }
local PVE_C5_MAIN_ROLES180 = { TANK = true, HEALER = true, DAMAGE = true }
local PVE_C5_OFFSPEC_ROLES180 = { NONE = true, TANK = true, HEALER = true, DAMAGE = true }
local PVE_C5_TIERS180 = { CORE = true, RESERVE = true, GUEST = true }
local PVE_C5_HELPER_LIMIT180 = 5

local function PveNormalizeMainRole180(member)
    if type(member) ~= "table" then return "UNASSIGNED" end
    local mainRole = string.upper(tostring(member.mainRole or member.role or ""))
    if PVE_C5_MAIN_ROLES180[mainRole] then
        member.mainRole = mainRole
        member.role = mainRole -- legacy readers keep seeing the main role.
        member.roleNeedsReview180 = nil
        return mainRole
    end
    member.mainRole = "UNASSIGNED"
    member.role = "FLEXIBLE" -- protocol-compatible representation for old clients.
    member.roleNeedsReview180 = true
    return "UNASSIGNED"
end

local function PveNormalizeOffspecRole180(member, mainRole)
    if type(member) ~= "table" then return "NONE" end
    mainRole = mainRole or PveNormalizeMainRole180(member)
    local offspec = string.upper(tostring(member.offspecRole or "NONE"))
    if not PVE_C5_OFFSPEC_ROLES180[offspec] or offspec == mainRole then offspec = "NONE" end
    member.offspecRole = offspec ~= "NONE" and offspec or nil
    return offspec
end

local function PveNormalizeRaidMemberRoles180(member)
    local mainRole = PveNormalizeMainRole180(member)
    local offspec = PveNormalizeOffspecRole180(member, mainRole)
    return mainRole, offspec
end

function OTLGM:NormalizeRaidMemberRoles180(member)
    return PveNormalizeRaidMemberRoles180(member)
end

local function PveC5DeepCopy180(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    local key, item
    for key, item in pairs(value) do copy[PveC5DeepCopy180(key, seen)] = PveC5DeepCopy180(item, seen) end
    return copy
end

local function PveC5CopyRosterMember180(member)
    if type(member) ~= "table" then return nil end
    local mainRole, offspec = PveNormalizeRaidMemberRoles180(member)
    return {
        character = member.character, class = member.class,
        mainRole = mainRole, role = mainRole == "UNASSIGNED" and "FLEXIBLE" or mainRole,
        offspecRole = offspec ~= "NONE" and offspec or nil,
        roleNeedsReview180 = mainRole == "UNASSIGNED" and true or nil,
        slotStatus = PveStageCStatus180(member.slotStatus, { ASSIGNED = true, RESERVE = true, GUEST = true }, "ASSIGNED"),
        sourceTeamId180 = member.sourceTeamId180, sourceTeamRev180 = member.sourceTeamRev180,
    }
end

local function PveC5CopyRoster180(roster)
    local result, key, member = {}, nil, nil
    for key, member in pairs(type(roster) == "table" and roster or {}) do
        local copy = PveC5CopyRosterMember180(member)
        if copy and copy.character then result[PveNormalizeName(copy.character) ~= "" and PveNormalizeName(copy.character) or key] = copy end
    end
    return result
end

function OTLGM:CopyRaidEventRosterDomain180(roster)
    return PveC5CopyRoster180(roster)
end

local function PveC5SplitNames180(self, text)
    local result, seen = {}, {}
    text = string.gsub(tostring(text or ""), ";", ",")
    local parts = self:Split(text, ",") or {}
    local index, name, key
    for index = 1, table.getn(parts) do
        name = PveSafeText(parts[index] or "", 40)
        key = PveNormalizeName(name)
        if key ~= "" and not seen[key] and table.getn(result) < PVE_C5_HELPER_LIMIT180 then
            seen[key] = true
            table.insert(result, name)
        end
    end
    return result
end

local function PveC5JoinNames180(names)
    local result, used, index = {}, 0, 1
    for index = 1, table.getn(names or {}) do
        local name = names[index]
        local extra = string.len(name) + (table.getn(result) > 0 and 2 or 0)
        if used + extra <= 62 then table.insert(result, name) used = used + extra end
    end
    return table.concat(result, ", ")
end


function OTLGM:SerializeRaidTeamMember180(teamId, teamRev, member)
    if not member or not teamId then return nil end
    local mainRole, offspec = PveNormalizeRaidMemberRoles180(member)
    local legacyRole = PVE_C5_MAIN_ROLES180[mainRole] and mainRole or "FLEXIBLE"
    return table.concat({
        self.pveProtocol, "RTMEM1", PveSafeText(teamId, 56), tostring(teamRev or 1), PveSafeText(member.character, 40),
        PveSafeText(member.class, 16), legacyRole,
        PveStageCStatus180(member.tier, { CORE = true, RESERVE = true, GUEST = true }, "GUEST"), PveSafeText(member.note, 36),
        PveSafeText(member.addedBy or "", 40), tostring(member.addedAt or 0), offspec, mainRole == "UNASSIGNED" and "1" or "0",
    }, "^")
end

function OTLGM:SerializeRaidTeamDelete180(teamId, rev, ts)
    return table.concat({ self.pveProtocol, "RTDEL1", PveSafeText(teamId, 56), tostring(rev or 1), tostring(ts or self:Now()) }, "^")
end

function OTLGM:SerializeRaidEventMeta180(event)
    if not event or not event.id then return nil end
    return table.concat({
        self.pveProtocol, "RMETA1", PveSafeText(event.id, 56), tostring(event.rev or 1), PveSafeText(event.teamId180 or "", 48),
        PveStageCStatus180(event.visibility180, { PRIVATE_TEAM = true, GUILD_VISIBLE = true, OPEN_GUILD = true }, "GUILD_VISIBLE"),
        PveStageCStatus180(event.notifyAudience180, { ASSIGNED = true, ASSIGNED_RESERVES = true, ENTIRE_TEAM = true, ALL_GUILD = true }, "ASSIGNED"),
        PveSafeUrl180(event.discordUrl180 or "", 56), PveSafeText(event.signUpNote180 or "", 30),
        tostring(event.participantStatusRevision180 or 1),
    }, "^")
end

function OTLGM:SerializeRaidRosterMember180(eventId, eventRev, member)
    if not member or not eventId then return nil end
    local mainRole, offspec = PveNormalizeRaidMemberRoles180(member)
    local legacyRole = PVE_C5_MAIN_ROLES180[mainRole] and mainRole or "FLEXIBLE"
    return table.concat({
        self.pveProtocol, "RRMEM1", PveSafeText(eventId, 56), tostring(eventRev or 1), PveSafeText(member.character, 40),
        PveSafeText(member.class, 16), legacyRole,
        PveStageCStatus180(member.slotStatus, { ASSIGNED = true, RESERVE = true, GUEST = true }, "ASSIGNED"),
        offspec, mainRole == "UNASSIGNED" and "1" or "0",
    }, "^")
end

function OTLGM:SerializeRaidRosterDelete180(eventId, eventRev, character)
    return table.concat({ self.pveProtocol, "RRDEL1", PveSafeText(eventId, 56), tostring(eventRev or 1), PveSafeText(character or "*", 40) }, "^")
end

function OTLGM:SerializeRaidParticipantStatus180(eventId, eventRev, character, seen, ready, ts, readyRevision)
    local event = self:GetRaidEvent180(eventId)
    readyRevision = tonumber(readyRevision) or tonumber(event and event.participantStatusRevision180) or 1
    return table.concat({ self.pveProtocol, "RSTATUS1", PveSafeText(eventId, 56), tostring(eventRev or 1), PveSafeText(character, 40), seen and "1" or "0", ready and "1" or "0", tostring(ts or self:Now()), tostring(readyRevision) }, "^")
end

function OTLGM:SerializeRaidInviteState180(eventId, eventRev, character, state, actor, ts, inviteRevision)
    return table.concat({
        self.pveProtocol, "RINV1", PveSafeText(eventId, 56), tostring(eventRev or 1), PveSafeText(character, 40),
        PveStageCStatus180(state, { WAITING = true, INVITED = true, JOINED = true, OFFLINE = true, OPEN = true }, "WAITING"),
        PveSafeText(actor, 40), tostring(ts or self:Now()), tostring(inviteRevision or 0),
    }, "^")
end

function OTLGM.__impl180.Stage_PVE_GetPveRecordRevision_1__impl1(self, id)
    local pve=self:EnsurePveDB(); if not pve then return 0 end
    if pve.requests[id] then return tonumber(pve.requests[id].rev) or 0 end
    if pve.board[id] then return tonumber(pve.board[id].rev) or 0 end
    if pve.raids and pve.raids[id] then return tonumber(pve.raids[id].rev) or 0 end
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

function OTLGM:GetRaidTeam180(teamId)
    local pve = self:EnsurePveDB()
    return pve and pve.raidTeams180 and pve.raidTeams180[teamId] or nil
end

function OTLGM:GetRaidEvent180(eventId)
    local pve = self:EnsurePveDB()
    if not pve then return nil end
    return (pve.raids and pve.raids[eventId]) or (pve.cancelledRaids156 and pve.cancelledRaids156[eventId]) or nil
end

function OTLGM:GetRaidRosterSourceEvent180(eventId)
    local event = self:GetRaidEvent180(eventId)
    if event then return event end
    -- GetPveDB never existed in the 1.8 tree.  The stale compatibility call
    -- made cancelled/archived raids disappear from "previous roster" sources
    -- even though their durable data was still present.
    local pve = self.EnsurePveDB and self:EnsurePveDB() or nil
    local source
    if pve and type(pve.cancelledRaids156) == "table" then source = pve.cancelledRaids156[eventId] end
    if not source and pve and type(pve.archivedRaids180) == "table" then source = pve.archivedRaids180[eventId] end
    if type(source) == "table" and type(source.roster180) == "table" and next(source.roster180) then return source end
    return nil
end

local function PveStageCManager180(self, record, sender, channel)
    if self:IsPveLeadershipName(sender) == true then return true end
    if record and PveNormalizeName(record.raidLeader or record.author) == PveNormalizeName(sender) then return true end
    return false
end

local function PveStageCInviteManager180(self, event, sender, channel)
    if PveStageCManager180(self, event, sender, channel) then return true end
    local wanted = PveNormalizeName(sender)
    if event and PveNormalizeName(event.inviteContact180 or event.inviteContact) == wanted then return true end
    local helpers = tostring(event and (event.inviteHelpers180 or event.inviteHelpers) or "")
    helpers = string.gsub(helpers, ";", ",")
    local parts = self:Split(helpers, ",")
    local index
    for index = 1, table.getn(parts) do if PveNormalizeName(parts[index]) == wanted then return true end end
    return false
end

local function PveStageCFieldsCopy180(fields)
    local copy = {}
    local index
    for index = 1, table.getn(fields or {}) do copy[index] = fields[index] end
    return copy
end

function OTLGM:QueuePendingStageCPvePacket180(objectId, kind, fields, sender, channel)
    if not objectId or objectId == "" then return false end
    local pending = self:GetPendingPveTeamPackets180()
    local bucket = pending[objectId]
    if type(bucket) ~= "table" then bucket = { ts = self:Now() } pending[objectId] = bucket end
    bucket.ts = self:Now()
    table.insert(bucket, {
        kind = kind,
        fields = PveStageCFieldsCopy180(fields),
        sender = sender,
        channel = channel,
        ts = self:Now(),
        expires = self:Now() + PVE_C0_PENDING_TTL,
    })
    while table.getn(bucket) > PVE_C0_PENDING_PACKET_LIMIT do table.remove(bucket, 1) end
    PvePruneOldestMap180(pending, PVE_C0_PENDING_OBJECT_LIMIT)
    return true
end

function OTLGM:DrainPendingStageCPvePackets180(objectId)
    local pending = self:GetPendingPveTeamPackets180()
    local bucket = pending[objectId]
    if type(bucket) ~= "table" then return 0 end
    pending[objectId] = nil
    local index, packet, count = 1, nil, 0
    for index = 1, table.getn(bucket) do
        packet = bucket[index]
        if type(packet) == "table" and (tonumber(packet.expires) or 0) > self:Now() then
            -- Packets staged before their parent record were shape-checked
            -- only. Re-run ownership validation now that the canonical team or
            -- event exists; a forged early packet must never become trusted by
            -- surviving in the short runtime queue.
            if self:HandleStageCPveMessage180(packet.fields, packet.sender, packet.channel, false) then count = count + 1 end
        end
    end
    return count
end

function OTLGM:ValidateStageCPveMessage180(kind, fields, sender, channel)
    if not self:IsStageCPveMessageKind180(kind) or not sender or sender == "" then return false end
    local id = fields[3] or ""
    local rev = tonumber(fields[4]) or 0
    if not self:IsValidID(id, 64) or rev < 1 or rev > 1000000 then return false end

    if kind == "GMETA1" then
        local pve = self:EnsurePveDB()
        local record = pve and pve.requests and pve.requests[id]
        local minLevel, maxLevel = tonumber(fields[5]) or 0, tonumber(fields[6]) or 0
        if minLevel < 0 or maxLevel < 0 or minLevel > 255 or maxLevel > 255 or (minLevel > 0 and maxLevel > 0 and minLevel > maxLevel) then return false end
        if record then return self:IsPveGroupMetaSenderAllowed180(record, sender, channel) end
        return channel == "GUILD" or PveStageCRecentSync180(self, channel)
    end

    if kind == "RTEAM1" then
        if string.len(fields[6] or "") > 40 or string.len(fields[7] or "") > 48 or string.len(fields[8] or "") > 48
            or string.len(fields[10] or "") > 32 or string.len(fields[11] or "") > 62 or string.len(fields[12] or "") > 48 then return false end
        if fields[9] ~= "ACTIVE" and fields[9] ~= "ARCHIVED" then return false end
        if fields[13] and fields[13] ~= "" and fields[13] ~= "0" and fields[13] ~= "1" then return false end
        local declaredLeader = PveSafeText(fields[7] or "", 48)
        if declaredLeader == "" then return false end
        local existing = self:GetRaidTeam180(id)
        if existing then return PveStageCManager180(self, existing, sender, channel) end
        -- Creating a new persistent team is an administrative action. The
        -- packet may name a different raid leader, but only the existing
        -- leadership permission model can create the canonical team.
        return self:IsPveLeadershipName(sender) == true
    end
    if kind == "RTMEM1" then
        if PveStageCCharacterKey180(fields[5]) == "" or string.len(fields[9] or "") > 52 or string.len(fields[10] or "") > 48 then return false end
        if fields[11] and fields[11] ~= "" and not tonumber(fields[11]) then return false end
        if fields[7] ~= "TANK" and fields[7] ~= "HEALER" and fields[7] ~= "DAMAGE" and fields[7] ~= "FLEXIBLE" then return false end
        if fields[8] ~= "CORE" and fields[8] ~= "RESERVE" and fields[8] ~= "GUEST" then return false end
        if fields[12] and fields[12] ~= "" and fields[12] ~= "NONE" and fields[12] ~= "TANK" and fields[12] ~= "HEALER" and fields[12] ~= "DAMAGE" then return false end
        if fields[13] and fields[13] ~= "" and fields[13] ~= "0" and fields[13] ~= "1" then return false end
        local team = self:GetRaidTeam180(id)
        if team then return PveStageCManager180(self, team, sender, channel) end
        -- Delivery order is not authority. An early membership packet is only
        -- staged; DrainPendingStageCPvePackets180 validates it again after the
        -- signed team header exists.
        return channel == "GUILD" or PveStageCRecentSync180(self, channel)
    end
    if kind == "RTDEL1" then
        if not tonumber(fields[5]) then return false end
        return PveStageCManager180(self, self:GetRaidTeam180(id), sender, channel)
    end

    local event = self:GetRaidEvent180(id)
    if kind == "RMETA1" then
        if string.len(fields[5] or "") > 56 or string.len(fields[8] or "") > 72 or string.len(fields[9] or "") > 42 then return false end
        if fields[6] ~= "PRIVATE_TEAM" and fields[6] ~= "GUILD_VISIBLE" and fields[6] ~= "OPEN_GUILD" then return false end
        if fields[7] ~= "ASSIGNED" and fields[7] ~= "ASSIGNED_RESERVES" and fields[7] ~= "ENTIRE_TEAM" and fields[7] ~= "ALL_GUILD" then return false end
        if fields[8] and fields[8] ~= "" and PveSafeUrl180(fields[8], 72) == "" then return false end
        if fields[10] and fields[10] ~= "" and not tonumber(fields[10]) then return false end
        if event then return PveStageCManager180(self, event, sender, channel) end
        return channel == "GUILD" or PveStageCRecentSync180(self, channel)
    end
    if kind == "RRMEM1" then
        if PveStageCCharacterKey180(fields[5]) == "" then return false end
        if fields[7] ~= "TANK" and fields[7] ~= "HEALER" and fields[7] ~= "DAMAGE" and fields[7] ~= "FLEXIBLE" then return false end
        if fields[8] ~= "ASSIGNED" and fields[8] ~= "RESERVE" and fields[8] ~= "GUEST" then return false end
        if fields[9] and fields[9] ~= "" and fields[9] ~= "NONE" and fields[9] ~= "TANK" and fields[9] ~= "HEALER" and fields[9] ~= "DAMAGE" then return false end
        if fields[10] and fields[10] ~= "" and fields[10] ~= "0" and fields[10] ~= "1" then return false end
        if event then return PveStageCManager180(self, event, sender, channel) end
        return channel == "GUILD" or PveStageCRecentSync180(self, channel)
    end
    if kind == "RRDEL1" then
        if fields[5] ~= "*" and PveStageCCharacterKey180(fields[5]) == "" then return false end
        if event then return PveStageCManager180(self, event, sender, channel) end
        return channel == "GUILD" or PveStageCRecentSync180(self, channel)
    end
    if kind == "RSTATUS1" then
        if (fields[6] ~= "0" and fields[6] ~= "1") or (fields[7] ~= "0" and fields[7] ~= "1") or not tonumber(fields[8]) then return false end
        if fields[9] and fields[9] ~= "" and not tonumber(fields[9]) then return false end
        if PveNormalizeName(fields[5] or "") ~= PveNormalizeName(sender) then return false end
        if event then
            local participant = self:GetRaidEventRosterMember180(event, fields[5])
            return participant and participant.slotStatus == "ASSIGNED" or false
        end
        return channel == "GUILD" or PveStageCRecentSync180(self, channel)
    end
    if kind == "RINV1" then
        local state = fields[6]
        if state ~= "WAITING" and state ~= "INVITED" and state ~= "JOINED" and state ~= "OFFLINE" and state ~= "OPEN" then return false end
        if state == "OPEN" then
            if fields[5] ~= "*" then return false end
        elseif PveStageCCharacterKey180(fields[5]) == "" then return false end
        if not tonumber(fields[8]) then return false end
        if fields[9] and fields[9] ~= "" and not tonumber(fields[9]) then return false end
        if PveNormalizeName(fields[7] or "") ~= PveNormalizeName(sender) then return false end
        if event then return PveStageCInviteManager180(self, event, sender, channel) end
        return channel == "GUILD" or PveStageCRecentSync180(self, channel)
    end
    return false
end

function OTLGM.__impl180.ApplyRemoteRaidTeamHeader180__impl1(self, fields, sender, channel)
    local pve = self:EnsurePveDB()
    if not pve then return false end
    local id, rev = fields[3] or "", tonumber(fields[4]) or 0
    local tombstone = pve.raidTeamDeleted180[id]
    if tombstone and (tonumber(tombstone.rev) or 0) >= rev then return true end
    local old = pve.raidTeams180[id]
    if old and (tonumber(old.rev) or 0) > rev then return true end
    local oldRev = old and (tonumber(old.rev) or 0) or 0
    local team = old or { id = id, members = {} }
    -- RTMEM1 is a complete membership snapshot for the matching team revision.
    -- A newer authoritative header therefore clears older membership rows before
    -- the new revision's bounded records are applied. Repeated same-revision
    -- headers keep already received children and remain idempotent.
    if rev > oldRev then team.members = {} end
    team.id = id
    team.rev = rev
    team.ts = tonumber(fields[5]) or self:Now()
    team.name = PveSafeText(fields[6] or "Raid Team", 40)
    team.raidLeader = PveSafeText(fields[7] or sender, 48)
    team.inviteContact = PveSafeText(fields[8] or team.raidLeader, 48)
    team.status = PveStageCStatus180(fields[9], { ACTIVE = true, ARCHIVED = true }, "ACTIVE")
    team.description = PveSafeText(fields[10] or team.description or "", 32)
    team.inviteHelpers = PveSafeText(fields[11] or team.inviteHelpers or "", 62)
    team.createdBy = PveSafeText(fields[12] or team.createdBy or "", 48)
    team.primary180 = fields[13] == "1" and team.status ~= "ARCHIVED" or false
    team.members = type(team.members) == "table" and team.members or {}
    if team.primary180 then
        local otherId, otherTeam
        for otherId, otherTeam in pairs(pve.raidTeams180 or {}) do
            if otherId ~= id and type(otherTeam) == "table" then otherTeam.primary180 = false end
        end
    end
    pve.raidTeams180[id] = team
    pve.raidTeamDeleted180[id] = nil
    PvePruneOldestMap180(pve.raidTeams180, PVE_C0_TEAM_LIMIT)
    self:DrainPendingStageCPvePackets180(id)
    return true
end

function OTLGM.__impl180.ApplyRemoteRaidTeamMember180__impl1(self, fields, sender, channel)
    local teamId, teamRev = fields[3] or "", tonumber(fields[4]) or 0
    local team = self:GetRaidTeam180(teamId)
    if not team or (tonumber(team.rev) or 0) < teamRev then return self:QueuePendingStageCPvePacket180(teamId, "RTMEM1", fields, sender, channel) end
    if (tonumber(team.rev) or 0) > teamRev then return true end
    local character = PveSafeText(fields[5] or "", 48)
    local key = PveStageCCharacterKey180(character)
    if key == "" then return false end
    local legacyRole = PveStageCStatus180(fields[7], { TANK = true, HEALER = true, DAMAGE = true, FLEXIBLE = true }, "FLEXIBLE")
    local member = {
        character = character,
        class = PveSafeText(fields[6] or "", 16),
        mainRole = legacyRole == "FLEXIBLE" and "UNASSIGNED" or legacyRole,
        role = legacyRole,
        offspecRole = PveStageCStatus180(fields[12], PVE_C5_OFFSPEC_ROLES180, "NONE"),
        tier = PveStageCStatus180(fields[8], { CORE = true, RESERVE = true, GUEST = true }, "GUEST"),
        note = PveSafeText(fields[9] or "", 52),
        addedBy = PveSafeText(fields[10] or "", 48),
        addedAt = tonumber(fields[11]) or 0,
        roleNeedsReview180 = legacyRole == "FLEXIBLE" or fields[13] == "1" or nil,
        teamRev = teamRev,
        updatedAt = self:Now(),
    }
    if member.offspecRole == "NONE" then member.offspecRole = nil end
    PveNormalizeRaidMemberRoles180(member)
    team.members = type(team.members) == "table" and team.members or {}
    team.members[key] = member
    PvePruneOldestMap180(team.members, PVE_C0_MEMBER_LIMIT)
    return true
end

function OTLGM.__impl180.ApplyRemoteRaidTeamDelete180__impl1(self, fields)
    local pve = self:EnsurePveDB()
    if not pve then return false end
    local id, rev = fields[3] or "", tonumber(fields[4]) or 0
    local old = pve.raidTeams180[id]
    local deleted = pve.raidTeamDeleted180[id]
    if old and (tonumber(old.rev) or 0) > rev then return true end
    if deleted and (tonumber(deleted.rev) or 0) >= rev then return true end
    pve.raidTeams180[id] = nil
    pve.raidTeamDeleted180[id] = { rev = rev, ts = tonumber(fields[5]) or self:Now() }
    PvePruneOldestMap180(pve.raidTeamDeleted180, PVE_C0_TEAM_TOMBSTONE_LIMIT)
    return true
end

function OTLGM:ApplyRemoteRaidEventMeta180(fields, sender, channel)
    local eventId, eventRev = fields[3] or "", tonumber(fields[4]) or 0
    local event = self:GetRaidEvent180(eventId)
    if not event or (tonumber(event.rev) or 0) < eventRev then return self:QueuePendingStageCPvePacket180(eventId, "RMETA1", fields, sender, channel) end
    if (tonumber(event.rev) or 0) > eventRev then return true end
    event.teamId180 = PveSafeText(fields[5] or "", 64)
    event.visibility180 = PveStageCStatus180(fields[6], { PRIVATE_TEAM = true, GUILD_VISIBLE = true, OPEN_GUILD = true }, "GUILD_VISIBLE")
    event.notifyAudience180 = PveStageCStatus180(fields[7], { ASSIGNED = true, ASSIGNED_RESERVES = true, ENTIRE_TEAM = true, ALL_GUILD = true }, "ASSIGNED")
    event.discordUrl180 = PveSafeUrl180(fields[8] or "", 72)
    event.signUpNote180 = PveSafeText(fields[9] or "", 120)
    event.participantStatusRevision180 = math.max(1, tonumber(fields[10]) or tonumber(event.participantStatusRevision180) or 1)
    event.roster180 = type(event.roster180) == "table" and event.roster180 or {}
    event.participantStatus180 = type(event.participantStatus180) == "table" and event.participantStatus180 or {}
    event.eventMetaRev180 = eventRev
    self:DrainPendingStageCPvePackets180(eventId)
    if self.ScheduleRaidEventAccessEvaluation180 then self:ScheduleRaidEventAccessEvaluation180(eventId, true) end
    return true
end

local function PveC6CanReceivePrivateDetail180(self, event, character, allowOpenForParticipant)
    if not event or event.visibility180 ~= "PRIVATE_TEAM" then return true end
    local player = PveSafeText(UnitName("player") or "", 48)
    if character and character ~= "*" and PveNormalizeName(character) == PveNormalizeName(player) then return true end
    local access = self.GetRaidEventAccess180 and self:GetRaidEventAccess180(event, player) or nil
    if access and (access.canManage or access.canInvite or access.isTeamMember) then return true end
    if character == "*" and allowOpenForParticipant and access and access.isParticipant then return true end
    return false
end

function OTLGM:ApplyRemoteRaidRosterMember180(fields, sender, channel)
    local eventId, eventRev = fields[3] or "", tonumber(fields[4]) or 0
    local event = self:GetRaidEvent180(eventId)
    if not event or (tonumber(event.rev) or 0) < eventRev then return self:QueuePendingStageCPvePacket180(eventId, "RRMEM1", fields, sender, channel) end
    if (tonumber(event.rev) or 0) > eventRev then return true end
    local character = PveSafeText(fields[5] or "", 48)
    local key = PveStageCCharacterKey180(character)
    if key == "" then return false end
    if event.visibility180 == "PRIVATE_TEAM" and not event.teamId180
        and PveNormalizeName(character) ~= PveNormalizeName(UnitName("player") or "")
        and not self:IsRaidEventManager180(event) and not self:IsRaidInviteManager180(event) then
        return self:QueuePendingStageCPvePacket180(eventId, "RRMEM1", fields, sender, channel)
    end
    if not PveC6CanReceivePrivateDetail180(self, event, character, false) then return true end
    local legacyRole = PveStageCStatus180(fields[7], { TANK = true, HEALER = true, DAMAGE = true, FLEXIBLE = true }, "FLEXIBLE")
    local member = {
        character = character,
        class = PveSafeText(fields[6] or "", 16),
        mainRole = legacyRole == "FLEXIBLE" and "UNASSIGNED" or legacyRole,
        role = legacyRole,
        offspecRole = PveStageCStatus180(fields[9], PVE_C5_OFFSPEC_ROLES180, "NONE"),
        slotStatus = PveStageCStatus180(fields[8], { ASSIGNED = true, RESERVE = true, GUEST = true }, "ASSIGNED"),
        roleNeedsReview180 = legacyRole == "FLEXIBLE" or fields[10] == "1" or nil,
        eventRev = eventRev,
        updatedAt = self:Now(),
    }
    if member.offspecRole == "NONE" then member.offspecRole = nil end
    PveNormalizeRaidMemberRoles180(member)
    event.roster180 = type(event.roster180) == "table" and event.roster180 or {}
    event.roster180[key] = member
    PvePruneOldestMap180(event.roster180, PVE_C0_MEMBER_LIMIT)
    if self.ScheduleRaidEventAccessEvaluation180 then self:ScheduleRaidEventAccessEvaluation180(eventId, true) end
    return true
end

function OTLGM:ApplyRemoteRaidRosterDelete180(fields, sender, channel)
    local eventId, eventRev = fields[3] or "", tonumber(fields[4]) or 0
    local event = self:GetRaidEvent180(eventId)
    if not event or (tonumber(event.rev) or 0) < eventRev then return self:QueuePendingStageCPvePacket180(eventId, "RRDEL1", fields, sender, channel) end
    if (tonumber(event.rev) or 0) > eventRev then return true end
    event.roster180 = type(event.roster180) == "table" and event.roster180 or {}
    local character = fields[5] or "*"
    if character == "*" or character == "" then event.roster180 = {}
    else event.roster180[PveStageCCharacterKey180(character)] = nil end
    if self.ScheduleRaidEventAccessEvaluation180 then self:ScheduleRaidEventAccessEvaluation180(eventId, true) end
    return true
end

function OTLGM:ApplyRemoteRaidParticipantStatus180(fields, sender, channel)
    local eventId, eventRev = fields[3] or "", tonumber(fields[4]) or 0
    local event = self:GetRaidEvent180(eventId)
    if not event or (tonumber(event.rev) or 0) < eventRev then return self:QueuePendingStageCPvePacket180(eventId, "RSTATUS1", fields, sender, channel) end
    local character = PveSafeText(fields[5] or "", 48)
    local key = PveStageCCharacterKey180(character)
    if key == "" then return false end
    event.participantStatus180 = type(event.participantStatus180) == "table" and event.participantStatus180 or {}
    local participant = self:GetRaidEventRosterMember180(event, character)
    if not participant or participant.slotStatus ~= "ASSIGNED" then return false end
    if not PveC6CanReceivePrivateDetail180(self, event, character, false) then return true end
    local readyRevision = tonumber(fields[9]) or tonumber(event.participantStatusRevision180) or 1
    local currentReadyRevision = tonumber(event.participantStatusRevision180) or 1
    event.participantStatus180[key] = {
        character = character, seen = fields[6] == "1",
        ready = fields[7] == "1" and readyRevision == currentReadyRevision,
        ts = tonumber(fields[8]) or self:Now(), eventRev = tonumber(event.rev) or eventRev, readyRev180 = readyRevision,
    }
    if self.OnPveDataChanged then self:OnPveDataChanged("RAIDS", true) end
    return true
end

function OTLGM:ApplyRemoteRaidInviteState180(fields, sender, channel)
    local eventId, eventRev = fields[3] or "", tonumber(fields[4]) or 0
    local event = self:GetRaidEvent180(eventId)
    if not event or (tonumber(event.rev) or 0) < eventRev then return self:QueuePendingStageCPvePacket180(eventId, "RINV1", fields, sender, channel) end
    if (tonumber(event.rev) or 0) > eventRev then return true end
    local character = PveSafeText(fields[5] or "", 48)
    local state = fields[6] or "WAITING"
    local timestamp = tonumber(fields[8]) or self:Now()
    if character == "*" and state == "OPEN" then
        if not PveC6CanReceivePrivateDetail180(self, event, "*", true) then return true end
        event.invitesOpen = true
        event.inviteRevision = math.max(tonumber(event.inviteRevision) or 0, tonumber(fields[9]) or 1)
        event.inviteTs = timestamp
        self:GetRaidInviteSession180(eventId)
        if self.ScheduleRaidEventAccessEvaluation180 then self:ScheduleRaidEventAccessEvaluation180(eventId, true) end
        if self.OnPveDataChanged then self:OnPveDataChanged("RAIDS", true) end
        return true
    end
    local key = PveStageCCharacterKey180(character)
    if key == "" then return false end
    if not PveC6CanReceivePrivateDetail180(self, event, character, false) then return true end
    local session = self.runtime.raidInviteSession180[eventId]
    if type(session) ~= "table" or tonumber(session.eventRev) ~= eventRev then session = { eventRev = eventRev, members = {}, ts = self:Now() } self.runtime.raidInviteSession180[eventId] = session end
    session.members[key] = {
        character = character,
        state = PveStageCStatus180(state, { WAITING = true, INVITED = true, JOINED = true, OFFLINE = true }, "WAITING"),
        actor = PveSafeText(fields[7] or sender, 48),
        ts = timestamp,
    }
    session.ts = self:Now()
    PvePruneOldestMap180(self.runtime.raidInviteSession180, PVE_C0_INVITE_SESSION_LIMIT)
    if self.OnPveDataChanged then self:OnPveDataChanged("RAIDS", true) end
    return true
end

function OTLGM:HandleStageCPveMessage180(fields, sender, channel, alreadyValidated)
    local kind = fields and fields[2] or ""
    if not self:IsStageCPveMessageKind180(kind) then return false end
    if not alreadyValidated and not self:ValidateStageCPveMessage180(kind, fields, sender, channel) then return false end
    if kind == "GMETA1" then return self:ApplyRemotePveGroupMeta180(fields, sender, channel) end
    if kind == "RTEAM1" then return self:ApplyRemoteRaidTeamHeader180(fields, sender, channel) end
    if kind == "RTMEM1" then return self:ApplyRemoteRaidTeamMember180(fields, sender, channel) end
    if kind == "RTDEL1" then return self:ApplyRemoteRaidTeamDelete180(fields) end
    if kind == "RMETA1" then return self:ApplyRemoteRaidEventMeta180(fields, sender, channel) end
    if kind == "RRMEM1" then return self:ApplyRemoteRaidRosterMember180(fields, sender, channel) end
    if kind == "RRDEL1" then return self:ApplyRemoteRaidRosterDelete180(fields, sender, channel) end
    if kind == "RSTATUS1" then return self:ApplyRemoteRaidParticipantStatus180(fields, sender, channel) end
    if kind == "RINV1" then return self:ApplyRemoteRaidInviteState180(fields, sender, channel) end
    return false
end

function OTLGM.__impl180.Stage_PVE_CreatePveRequest_1__impl1(self, kind,role,activity,note,maxSize,needTank,needHeal,needDps,minLevel,maxLevel)
    local pve=self:EnsurePveDB(); if not pve then return false,"Guild data is not ready." end
    activity=PveSafeText(activity,36); note=PveSafeText(note,52); kind=PveSafeText(kind or "DUNGEON",10); role=PveSafeText(role or "ANY",10)
    if activity=="" then return false,"Enter a dungeon, quest or activity." end
    local minimum, maximum, levelError = PveGroupNormalizeLevelRange180(minLevel, maxLevel)
    if levelError then return false, levelError end
    maxSize,needTank,needHeal,needDps=self:NormalizePveGroupNeeds155(maxSize,role,needTank,needHeal,needDps)
    local player=UnitName("player") or "Unknown"; local existing
    local _,candidate
    for _,candidate in pairs(pve.requests or {}) do if PveNormalizeName(candidate.author)==PveNormalizeName(player) then existing=candidate break end end
    local _,classToken=UnitClass("player")
    local record=existing or {id=self:MakePveID("Q"),rev=0,author=player,level=UnitLevel("player") or 0,class=classToken or "",current=1}
    record.rev=(tonumber(record.rev) or 0)+1; record.ts=self:Now(); record.expires=self:Now()+self.pveRequestLifetime
    record.author=player; record.level=UnitLevel("player") or 0; record.class=classToken or record.class or ""
    record.kind=kind; record.role=role; record.activity=activity; record.note=note; record.maxSize=maxSize
    record.current=math.max(1,tonumber(record.current) or 1); record.needTank=needTank; record.needHeal=needHeal; record.needDps=needDps; record.status="OPEN"
    record.minLevel180=minimum; record.maxLevel180=maximum; record.matchingFlags180="C4"; record.liveState180=true
    pve.requests[record.id]=record
    self:QueuePveGroupRecord180(record,"GUILD")
    self:SchedulePveGroupLiveState180(existing and "edit" or "create")
    self:OnPveDataChanged("GROUPS",false)
    return true,record
end

function OTLGM:ApplyToPveGroup(groupId,role,note)
    local pve=self:EnsurePveDB(); local group=pve and pve.requests[groupId]
    if not group then return false,"This group request is no longer available." end
    if self:IsOwnPveGroup(group) then return false,"You are the leader of this group." end
    if self:GetPveGroupStatus(group)~="OPEN" then return false,"This group is no longer open." end
    role=PveSafeText(role or "DPS",10)
    if note == nil then local profile = self:EnsurePveCharacterProfile180() note = profile and profile.defaultNote or "" end
    note=PveSafeText(note,44)
    local available=(role=="TANK" and (group.needTank or 0)>0) or (role=="HEAL" and (group.needHeal or 0)>0) or (role=="DPS" and (group.needDps or 0)>0) or (role=="ANY" and ((group.needTank or 0)+(group.needHeal or 0)+(group.needDps or 0))>0)
    if not available then return false,"This group no longer needs that role." end
    local player=UnitName("player") or "Unknown"; local existing=self:GetOwnPveApplication(groupId)
    if existing and existing.status=="PENDING" then return false,"Your request is already waiting for the leader." end
    if existing and existing.status=="ACCEPTED" then return false,"You were already accepted into this group." end
    local _,classToken=UnitClass("player")
    local record={id=existing and existing.id or self:MakePveID("A"),groupId=groupId,rev=existing and ((tonumber(existing.rev) or 0)+1) or 1,
        ts=self:Now(),expires=math.min(group.expires or (self:Now()+self.pveRequestLifetime),self:Now()+self.pveRequestLifetime),leader=group.author,author=player,
        level=UnitLevel("player") or 0,class=classToken or "",role=role,note=note,status="PENDING"}
    pve.applications[record.id]=record
    local payload=self:SerializePveApplication(record)
    self:QueuePvePayload(payload,"WHISPER",group.author)
    pve.applicationRetries[record.id]={payload=payload,leader=group.author,due=self:Now()+4,rev=record.rev}
    if self.WakeScheduler180 then self:WakeScheduler180("pve-application-retry") end
    self:OnPveDataChanged("GROUPS",false)
    return true,record
end

function OTLGM:UpdatePveApplication(applicationId, status)
    local pve=self:EnsurePveDB(); local application=pve and pve.applications[applicationId]
    if not application then return false,"Application not found." end
    local group=pve.requests[application.groupId]
    if not group or not self:IsOwnPveGroup(group) then return false,"Only the group leader can manage this application." end
    if application.status~="PENDING" then return false,"This application was already handled." end
    status=status=="ACCEPTED" and "ACCEPTED" or "DECLINED"
    if status=="ACCEPTED" then
        local canAccept,reasonOrGroup=self:CanAcceptPveApplication155(application)
        if not canAccept then return false,reasonOrGroup end
        group=reasonOrGroup
    end
    application.status=status; application.rev=(tonumber(application.rev) or 0)+1; application.ts=self:Now()
    if status=="ACCEPTED" then
        -- Acceptance is a reservation, not a party member. The authoritative
        -- current count changes only after a real PARTY/RAID roster event.
        application.acceptedAt180=self:Now(); application.joined180=nil; application.countedRole180=nil
        if InviteByName then pcall(InviteByName,string.gsub(application.author or "","%-.*$","")) end
    end
    self:QueuePvePayload(self:SerializePveApplication(application),"WHISPER",application.author)
    self:SchedulePveGroupLiveState180("application")
    self:OnPveDataChanged("GROUPS",false)
    return true,application
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
    local state = self:GetPveAccountState180()
    local characterKey, seenMap
    if state and type(state.groupMatchSeen180) == "table" then
        for characterKey, seenMap in pairs(state.groupMatchSeen180) do if type(seenMap) == "table" then seenMap[id] = nil end end
    end
    if self.runtime and self.runtime.pve and self.runtime.pve.pendingGroupMatchEval180 then self.runtime.pve.pendingGroupMatchEval180[id] = nil end
    if self.RemoveInboxObject180 then self:RemoveInboxObject180("GROUP", id) end
    self:QueuePvePayload(table.concat({ self.pveProtocol, "REQDEL", id, tostring(rev) }, "^"), "GUILD")
    if not quiet then self:OnPveDataChanged("GROUPS", false) end
    return true
end

function OTLGM:CanAcceptPveApplication155(application)
    local pve=self:EnsurePveDB(); local group=application and pve and pve.requests[application.groupId]
    if not application or not group then return false,"The group is no longer available." end
    if self:GetPveGroupStatus(group)~="OPEN" then return false,"The group is already full or closed." end
    local actualCount, members = self:GetPveActualRoster180()
    if not self:IsOwnPveGroup(group) then actualCount = tonumber(group.current) or 1 members = nil end
    local reserved = self:GetPveAcceptedNotJoined180(group.id, members)
    if actualCount + reserved >= (tonumber(group.maxSize) or 5) then return false,"All remaining places are already joined or reserved." end
    local reservedRoles = self:GetPveReservedRoles180(group.id, members)
    local role=application.role or "ANY"
    local tankOpen = math.max(0, (tonumber(group.needTank) or 0) - (reservedRoles.TANK or 0))
    local healOpen = math.max(0, (tonumber(group.needHeal) or 0) - (reservedRoles.HEAL or 0))
    local dpsOpen = math.max(0, (tonumber(group.needDps) or 0) - (reservedRoles.DPS or 0))
    if role=="TANK" and tankOpen<=0 then return false,"No unreserved Tank slot remains." end
    if role=="HEAL" and healOpen<=0 then return false,"No unreserved Healer slot remains." end
    if role=="DPS" and dpsOpen<=0 then return false,"No unreserved DPS slot remains." end
    if role=="ANY" and (tankOpen+healOpen+dpsOpen)<=0 then return false,"No unreserved role slot remains." end
    return true,group
end

function OTLGM:ProcessPveApplicationRetries155()
    local pve=self:EnsurePveDB(); if not pve then return end
    local id,retry
    for id,retry in pairs(pve.applicationRetries or {}) do
        if self:Now()>=(retry.due or 0) then
            pve.applicationRetries[id]=nil
            local app=pve.applications[id]
            if app and app.status=="PENDING" and (tonumber(app.rev) or 0)==(tonumber(retry.rev) or 0) then
                -- Guild fallback is safe: clients other than leader/applicant reject it.
                self:QueuePvePayload(retry.payload,"GUILD")
            end
            break
        end
    end
end

function OTLGM:CreatePveBoardPost(text)
    local pve = self:EnsurePveDB()
    if not pve then return false, "Guild data is not ready." end
    text = PveSafeText(text, 240)
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

function OTLGM:GetPveRaidServerTime155(raid)
    if not raid then return "Time TBA" end
    local startTs = tonumber(raid.startTs) or 0
    if startTs > 0 and self.FormatServerDayTime180 then return self:FormatServerDayTime180(startTs, raid.recurring) end
    local hour = tonumber(raid.stHour)
    local minute = tonumber(raid.stMinute)
    if not hour then
        local _, _, parsedHour, parsedMinute = string.find(raid.serverTime or "", "(%d%d):(%d%d)")
        hour = tonumber(parsedHour); minute = tonumber(parsedMinute)
    end
    local clock = hour and string.format("%02d:%02d", hour, minute or 0) or "--:--"
    return "Time " .. clock .. " ST" .. (raid.recurring == "WEEKLY" and "  -  Weekly" or "")
end

function OTLGM:PublishPveRaid(name,location,minutes,note)
    minutes=tonumber(minutes) or 60
    local hour, minute
    if GetGameTime then hour, minute = GetGameTime() end
    if not hour then hour=tonumber(date("%H",self:Now())) or 0; minute=tonumber(date("%M",self:Now())) or 0 end
    local total=hour*60+(minute or 0)+math.max(0,minutes)
    local dayOffset=math.floor(total/1440); total=math.mod(total,1440)
    return self:PublishPveRaidEvent155(name,location,dayOffset,math.floor(total/60),math.mod(total,60),note,"ONCE",60,nil)
end

function OTLGM:PublishPveRaidEvent155(name,location,dayOffset,hour,minute,note,recurring,reminderMinutes,existingId)
    if not self.IsOfficerMode or not self:IsOfficerMode() then return false,"Only leadership can publish guild raid notices." end
    local pve=self:EnsurePveDB(); if not pve then return false,"Guild data is not ready." end
    name=PveSafeText(name,36); location=PveSafeText(location,32); note=PveSafeText(note,48)
    if name=="" then return false,"Enter the raid name." end
    dayOffset=math.max(0,math.min(28,tonumber(dayOffset) or 0)); hour=math.max(0,math.min(23,tonumber(hour) or 0)); minute=math.max(0,math.min(59,tonumber(minute) or 0))
    recurring=recurring=="WEEKLY" and "WEEKLY" or "ONCE"; reminderMinutes=math.max(0,math.min(1440,tonumber(reminderMinutes) or 60))
    local now=self:Now()
    local startTs
    if self.GetServerDayStart180 then
        startTs = self:GetServerDayStart180(now, dayOffset) + (hour * 3600) + (minute * 60)
    else
        local currentHour, currentMinute
        if GetGameTime then currentHour, currentMinute = GetGameTime() end
        if not currentHour then currentHour=tonumber(date("%H",now)) or 0; currentMinute=tonumber(date("%M",now)) or 0 end
        local secondsToday=(currentHour*3600)+((currentMinute or 0)*60)
        startTs=now-secondsToday+(dayOffset*86400)+(hour*3600)+(minute*60)
    end
    if startTs<=now and dayOffset==0 then startTs=startTs+86400 end
    local player=UnitName("player") or "Unknown"; local record=existingId and pve.raids[existingId] or nil
    if not record then record={id=self:MakePveID("R"),rev=0,createdAt=now} end
    record.rev=(tonumber(record.rev) or 0)+1; record.ts=now; record.startTs=startTs; record.author=player; record.name=name; record.location=location; record.note=note
    record.recurring=recurring; record.reminderMinutes=reminderMinutes; record.stHour=hour; record.stMinute=minute
    record.serverTime=self.GetPveRaidServerTime155 and self:GetPveRaidServerTime155(record) or ((dayOffset==0 and "Today" or (dayOffset==1 and "Tomorrow" or ("+"..tostring(dayOffset).."d"))).." "..string.format("%02d:%02d",hour,minute).." ST")
    pve.raids[record.id]=record; pve.reminded[record.id]={}; self:RefreshNearestRaid155()
    self:QueuePvePayload(self:SerializePveRaid(record),"GUILD")
    self:OnPveDataChanged("RAIDS",false)
    return true,record
end

function OTLGM:ClearPveRaid(id)
    if not self.IsOfficerMode or not self:IsOfficerMode() then return false end
    local pve=self:EnsurePveDB(); if not pve then return false end
    local raid=id and pve.raids[id] or self:GetPveActiveRaid()
    if not raid then return false end
    local rev=(tonumber(raid.rev) or 0)+1; id=raid.id
    pve.raids[id]=nil; pve.deleted[id]={rev=rev,ts=self:Now(),kind="RAID"}; self:RefreshNearestRaid155()
    self:QueuePvePayload(table.concat({self.pveProtocol,"RAIDDEL",id,tostring(rev)},"^"),"GUILD")
    self:OnPveDataChanged("RAIDS",false)
    return true
end

function OTLGM:SendPveRaidNotice(minutes, raidId)
    if not self.IsOfficerMode or not self:IsOfficerMode() then return false end
    local pve = self:EnsurePveDB()
    local raid = raidId and pve and pve.raids and pve.raids[raidId] or self:GetPveActiveRaid()
    if not raid then return false end
    minutes = tonumber(minutes) or 0
    local label = minutes <= 0 and "Raid is starting now" or ("Raid begins in " .. tostring(minutes) .. " minutes")
    local noticeTime = self.GetPveRaidServerTime155 and self:GetPveRaidServerTime155(raid) or tostring(raid.serverTime or "")
    local payload = table.concat({ self.pveProtocol, "NOTICE", raid.id or "", tostring(minutes), PveSafeText(raid.name, 36), PveSafeText(noticeTime, 28), PveSafeText(label, 48) }, "^")
    self:QueuePvePayload(payload, "GUILD", nil, "raid-notice:" .. tostring(raid.id) .. ":" .. tostring(minutes))
    if self.ShowRaidEventNotice180 then
        self:ShowRaidEventNotice180(raid, raid.name, label .. " - " .. (self.GetPveRaidServerTime155 and self:GetPveRaidServerTime155(raid) or (raid.serverTime or "")), "manual:" .. tostring(minutes), true)
    end
    return true
end

function OTLGM:PostPveRaidToGuildChat(raidId)
    local pve = self:EnsurePveDB()
    local raid = raidId and pve and pve.raids and pve.raids[raidId] or self:GetPveActiveRaid()
    if not raid then return false end
    local raidTime = self.GetPveRaidServerTime155 and self:GetPveRaidServerTime155(raid) or (raid.serverTime or "time TBA")
    local text = "[OTLGM Raid] " .. (raid.name or "Raid") .. " — " .. raidTime
    if raid.location and raid.location ~= "" then text = text .. " — " .. raid.location end
    if raid.note and raid.note ~= "" then text = text .. ". " .. raid.note end
    text = text .. ". Official sign-up: Discord."
    if self.SendGuildObjectShare180 then return self:SendGuildObjectShare180("RAID_EVENT", raid.id, text) end
    if SendChatMessage then pcall(SendChatMessage, text, "GUILD") return true end
    return false
end

function OTLGM:IsRaidNoticeEligible()
    local player = UnitName("player") or ""
    local member = self:GetMember(player)
    local guildName, guildRankName = GetGuildInfo and GetGuildInfo("player")
    local rank = string.lower((member and member.rank) or guildRankName or "")
    if string.find(rank, "core raider", 1, true) or string.find(rank, "the devoted", 1, true) then return true end
    if rank == "raider" or string.find(rank, "4 - raider", 1, true) then return true end
    return false
end

function OTLGM.__impl180.ShowPveRaidNotice__impl1(self, title, body, remote)
    if not self:IsRaidNoticeEligible() then return end
    if OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.pveRaidPopups == false then return end
    if self.Notify then self:Notify("Raid Notice: " .. (title or "Guild Raid"), body or "") end
    if OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.pveRaidChatLine and self.Chat then
        self:Chat(self.colors.gold .. "[Raid Notice] " .. self.colors.reset .. (title or "Guild Raid") .. " - " .. (body or ""))
    end
end

function OTLGM:GetPveRaidRemainingText(raid)
    if not raid or not raid.startTs then return "No active raid notice" end
    local now = self:Now()
    local startTs = tonumber(raid.startTs) or 0
    if raid.recurring == "WEEKLY" and startTs > 0 then
        while startTs + 300 <= now do startTs = startTs + (7 * 86400) end
    end
    local remaining = startTs - now
    if remaining <= 0 then
        local elapsed = math.max(0, -remaining)
        if elapsed < 60 then return "Starting now" end
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor(math.mod(elapsed, 3600) / 60)
        if hours > 0 then return "Started " .. tostring(hours) .. "h " .. tostring(minutes) .. "m ago" end
        return "Started " .. tostring(math.max(1, minutes)) .. "m ago"
    end
    local hours = math.floor(remaining / 3600)
    local minutes = math.floor(math.mod(remaining, 3600) / 60)
    if hours > 0 then return tostring(hours) .. "h " .. tostring(minutes) .. "m remaining" end
    return tostring(math.max(1, minutes)) .. "m remaining"
end

function OTLGM:CheckPveRaidReminders()
    local pve=self:EnsurePveDB(); if not pve then return end
    local raids=self:GetPveRaids(); local i,raid
    for i=1,table.getn(raids) do
        raid=raids[i]
        local remaining=(raid.startTs or 0)-self:Now(); local reminder=tonumber(raid.reminderMinutes) or 60
        if remaining<=reminder*60 and remaining>=-300 then
            pve.reminded[raid.id]=pve.reminded[raid.id] or {}
            local key=tostring(raid.rev or 1)..":"..tostring(reminder)
            if not pve.reminded[raid.id][key] then
                pve.reminded[raid.id][key]=true
                local label=remaining<=0 and "Raid is starting now" or ("Raid begins in about "..tostring(reminder).." minutes")
                if self.ShowRaidEventNotice180 then
                    self:ShowRaidEventNotice180(raid, raid.name, label.." - "..(self.GetPveRaidServerTime155 and self:GetPveRaidServerTime155(raid) or (raid.serverTime or "")), "reminder:"..tostring(reminder), true)
                end
            end
        end
    end
end

function OTLGM.__impl180.Stage_PVE_RequestPveSync_1__impl1(self, force, manual)
    if not SendAddonMessage or not GetGuildInfo("player") then return false end
    local now = self:Now()
    local pve = self:EnsurePveDB()
    local backoffUntil = tonumber(pve and pve.syncBackoffUntilR2) or 0
    if not force and backoffUntil > now then return false end
    if not force and self.lastPveSyncRequestAt and now - self.lastPveSyncRequestAt < 90 then return false end
    local peers = self.GetCompatibleSyncPeersR2 and self:GetCompatibleSyncPeersR2(360) or {}
    if table.getn(peers) == 0 then
        if manual and self.SetStatus then
            self:SetStatus("No compatible guildmate is sharing PvE Hub updates right now; your saved information was kept.", 5, { source = "pve", manual = true })
        end
        return false
    end
    local nonce = tostring(now) .. ":" .. tostring(self.pveSequence or 0)
    local queued, index, target = 0, nil, nil
    local requestedPeerKeysR13 = {}
    -- One healthy peer is enough for an automatic full-state refresh.  Asking
    -- three guildmates at login made every one of them serialize the same PvE
    -- state back to us and could create a needless burst.  A deliberate manual
    -- refresh keeps a second peer for redundancy.
    local peerLimit = manual and 2 or 1
    for index = 1, math.min(peerLimit, table.getn(peers)) do
        target = peers[index]
        if self:QueuePvePayload(table.concat({ self.pveProtocol, "SYNC", nonce, self.version or "?" }, "^"), "WHISPER", target, "pve:sync:" .. PveNormalizeName(target)) then
            queued = queued + 1
            requestedPeerKeysR13[PveNormalizeName(target)] = true
        end
    end
    if queued <= 0 then return false end
    self.lastPveSyncRequestAt = now
    self.pveSyncPending180 = { nonce = nonce, startedAt = now, manualR2 = manual and true or false, peersR2 = queued, requestedPeerKeysR13 = requestedPeerKeysR13 }
    return true
end

function OTLGM:ConfirmPveSyncResponse180(sender, kind, nonce)
    local pending = self.pveSyncPending180
    if not pending then return false end
    if kind == "SYNCACK" and tostring(nonce or "") ~= tostring(pending.nonce or "") then return false end
    if not sender or PveNormalizeName(sender) == PveNormalizeName(UnitName("player") or "") then return false end
    local senderKey = PveNormalizeName(sender)
    if type(pending.requestedPeerKeysR13) == "table" and not pending.requestedPeerKeysR13[senderKey] then return false end
    local now = self:Now()
    if now - (tonumber(pending.startedAt) or now) > 20 then return false end
    local manual = pending.manualR2 and true or false
    self.pveSyncPending180 = nil
    local pve = self:EnsurePveDB()
    if pve then
        pve.lastSync = now
        pve.lastConfirmedSync180 = now
        pve.lastSyncPeer180 = sender
        pve.syncFailuresR2 = 0
        pve.syncBackoffUntilR2 = 0
    end
    if self.SetOperationState156 then self:SetOperationState156("PVE", "DONE", "PvE data updated at " .. (self.FormatServerClock180 and self:FormatServerClock180(now, false) or "--:--") .. " ST", 5, { source = "pve", manual = manual }) end
    if self.ui and self.ui.main and self.ui.main:IsVisible() and self.ui.currentPage == "pve" and self.RefreshPvePage then self:RefreshPvePage() end
    return true
end

function OTLGM:ProcessPveSyncState180()
    local pending = self.pveSyncPending180
    if not pending then return end
    local now = self:Now()
    if now - (tonumber(pending.startedAt) or now) < 18 then return end
    self.pveSyncPending180 = nil
    local pve = self:EnsurePveDB()
    if pve then
        pve.syncFailuresR2 = math.min(5, (tonumber(pve.syncFailuresR2) or 0) + 1)
        local delay = math.min(600, 30 * math.pow(2, math.max(0, pve.syncFailuresR2 - 1)))
        pve.syncBackoffUntilR2 = now + delay
    end
    local manual = pending.manualR2 and true or false
    if self.SetOperationState156 then
        if manual then
            -- A manual refresh timing out is reported inside PvE Hub only.  Do
            -- not create a global shell toast: the player may have left the page
            -- during the 18-second wait, which previously allowed this message
            -- to appear over Achievements/Treasury and look completely random.
            -- No expiry timer is needed either, so an unanswered peer does not
            -- keep the shared scheduler awake merely to remove a transient error.
            self:SetOperationState156("PVE", "IDLE", "No compatible guildmate responded; cached raid/group information was kept", nil, { source = "pve", manual = true, expected = true })
        else
            self:SetOperationState156("PVE", "IDLE", "No online guildmate answered; background refresh will wait before trying again", nil, { source = "pve", manual = false, expected = true })
        end
    end
    if self.ui and self.ui.main and self.ui.main:IsVisible() and self.ui.currentPage == "pve" and self.RefreshPvePage then self:RefreshPvePage() end
end

function OTLGM.__impl180.Stage_PVE_QueuePveSyncResponse_1__impl1(self, target)
    local pve=self:EnsurePveDB(); if not pve then return end
    self:PurgePveData(true)
    local id,record
    for id,record in pairs(pve.requests) do self:QueuePveGroupRecord180(record,"WHISPER",target) end
    for id,record in pairs(pve.raids or {}) do self:QueuePvePayload(self:SerializePveRaid(record),"WHISPER",target) end
    for id,record in pairs(pve.board) do self:QueuePvePayload(self:SerializePveBoard(record),"WHISPER",target) end
    local normalizedTarget=PveNormalizeName(target)
    for id,record in pairs(pve.applications or {}) do
        if PveNormalizeName(record.leader)==normalizedTarget or PveNormalizeName(record.author)==normalizedTarget then self:QueuePvePayload(self:SerializePveApplication(record),"WHISPER",target) end
    end
    local teamId, team, memberKey, member
    for teamId, team in pairs(pve.raidTeams180 or {}) do
        local header = self:SerializeRaidTeamHeader180(team)
        if header then self:QueuePvePayload(header, "WHISPER", target) end
        for memberKey, member in pairs(team.members or {}) do
            local payload = self:SerializeRaidTeamMember180(teamId, team.rev, member)
            if payload then self:QueuePvePayload(payload, "WHISPER", target) end
        end
    end
    for id, record in pairs(pve.raids or {}) do
        if record.eventMetaRev180 or record.teamId180 or record.visibility180 then
            local payload = self:SerializeRaidEventMeta180(record)
            if payload then self:QueuePvePayload(payload, "WHISPER", target) end
        end
        for memberKey, member in pairs(record.roster180 or {}) do
            local payload = self:SerializeRaidRosterMember180(id, record.rev, member)
            if payload then self:QueuePvePayload(payload, "WHISPER", target) end
        end
    end
end

function OTLGM:InitializePveSync()
    self:EnsurePveDB()
    if RegisterAddonMessagePrefix then pcall(RegisterAddonMessagePrefix, "OTLGM") end
    -- PvE full-state exchange is useful but not cold-start critical.  Keep it
    -- away from the first roster scan/version burst and spread guild clients by
    -- a few seconds so several logins do not all request large state together.
    local jitter = math.random and math.random(0, 6) or 3
    self.pveSyncAt = self:Now() + 18 + jitter
    if self.WakeScheduler180 then self:WakeScheduler180("pve-initial-sync") end
end

function OTLGM.__impl180.Stage_PVE_ApplyRemotePveRequest_1__impl1(self, fields, sender, channel)
    local pve = self:EnsurePveDB()
    if not pve then return false end
    local record = {
        id = fields[3] or "", rev = tonumber(fields[4]) or 0, ts = tonumber(fields[5]) or 0, expires = tonumber(fields[6]) or 0,
        author = fields[7] or "Unknown", level = tonumber(fields[8]) or 0, class = fields[9] or "",
        kind = fields[10] or "OTHER", role = fields[11] or "ANY", activity = fields[12] or "", note = fields[13] or "",
        maxSize = tonumber(fields[14]) or 5, current = tonumber(fields[15]) or 1,
        needTank = tonumber(fields[16]) or 0, needHeal = tonumber(fields[17]) or 0, needDps = tonumber(fields[18]) or 0,
        status = fields[19] or "OPEN",
    }
    if record.id == "" or record.expires <= self:Now() then return end
    if sender and sender ~= "" and PveNormalizeName(sender) ~= PveNormalizeName(record.author)
        and not PveStageCRecentSync180(self, channel) then return false end
    if not fields[14] or fields[14] == "" then
        local slots = math.max(1, (record.maxSize or 5) - 1)
        if record.role == "TANK" then record.needTank, record.needHeal, record.needDps = 0, 1, math.max(0, slots - 1)
        elseif record.role == "HEAL" then record.needTank, record.needHeal, record.needDps = 1, 0, math.max(0, slots - 1)
        else record.needTank, record.needHeal, record.needDps = 1, 1, math.max(0, slots - 2) end
    end
    local existing = pve.requests[record.id]
    if existing then
        record.minLevel180 = existing.minLevel180
        record.maxLevel180 = existing.maxLevel180
        record.matchingFlags180 = existing.matchingFlags180
        record.groupMetaRev180 = existing.groupMetaRev180
    end
    local beforeSignature = self:GetPveGroupMatchSignature180(existing)
    if self:GetPveRecordRevision(record.id) >= record.rev then
        if existing then self:ApplyPendingPveGroupMeta180(record.id, existing) end
        return
    end
    record.status = self:GetPveGroupStatus(record)
    pve.requests[record.id] = record
    self:ApplyPendingPveGroupMeta180(record.id, record)
    pve.deleted[record.id] = nil
    if not existing then self:IncrementPveUnread("GROUPS") end
    if channel == "GUILD" and (not existing or beforeSignature ~= self:GetPveGroupMatchSignature180(record)) then
        self:SchedulePveGroupMatchEvaluation180(record.id, channel, sender)
    end
    self:OnPveDataChanged("GROUPS", true)
    return true
end

function OTLGM.__impl180.Stage_PVE_ApplyRemotePveApplication_1__impl1(self, fields, sender)
    local pve = self:EnsurePveDB()
    if not pve then return false end
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
    return true
end

function OTLGM:ApplyRemotePveBoard(fields)
    local pve = self:EnsurePveDB()
    if not pve then return false end
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

function OTLGM.__impl180.Stage_PVE_ApplyRemotePveRaid_1__impl1(self, fields)
    local pve=self:EnsurePveDB(); if not pve then return false end
    local record={id=fields[3] or "",rev=tonumber(fields[4]) or 0,ts=tonumber(fields[5]) or 0,startTs=tonumber(fields[6]) or 0,
        author=fields[7] or "Unknown",name=fields[8] or "Guild Raid",location=fields[9] or "",serverTime=fields[10] or "",note=fields[11] or "",
        recurring=fields[12]=="WEEKLY" and "WEEKLY" or "ONCE",reminderMinutes=tonumber(fields[13]) or 60,
        stHour=tonumber(fields[14]) or nil,stMinute=tonumber(fields[15]) or nil}
    if record.recurring=="WEEKLY" then record.startTs=PveNextWeeklyStart(record.startTs,self:Now()) end
    if record.id=="" or record.startTs+14400<=self:Now() then return false end
    local leadership=self:IsPveLeadershipName(record.author); if leadership==false then return false end
    if self:GetPveRecordRevision(record.id)>=record.rev then return true end
    pve.raids[record.id]=record; pve.deleted[record.id]=nil; pve.reminded[record.id]=pve.reminded[record.id] or {}; self:RefreshNearestRaid155()
    self:DrainPendingStageCPvePackets180(record.id)
    self:OnPveDataChanged("RAIDS",true)
    if self.ScheduleRaidEventAccessEvaluation180 then self:ScheduleRaidEventAccessEvaluation180(record.id, true) end
    return true
end

function OTLGM.__impl180.Stage_PVE_ApplyRemotePveDelete_1__impl1(self, kind,id,rev)
    local pve=self:EnsurePveDB(); if not pve then return false end
    rev=tonumber(rev) or 0
    if id=="" or self:GetPveRecordRevision(id)>=rev then return end
    if kind=="REQDEL" then
        pve.requests[id]=nil
        local appId,application for appId,application in pairs(pve.applications or {}) do if application.groupId==id then pve.applications[appId]=nil end end
        local state=self:GetPveAccountState180(); local characterKey,seenMap
        for characterKey,seenMap in pairs(state and state.groupMatchSeen180 or {}) do if type(seenMap)=="table" then seenMap[id]=nil end end
        if self.RemoveInboxObject180 then self:RemoveInboxObject180("GROUP",id) end
    end
    if kind=="BOARDDEL" then pve.board[id]=nil end
    if kind=="RAIDDEL" then pve.raids[id]=nil self:RefreshNearestRaid155() end
    pve.deleted[id]={rev=rev,ts=self:Now()}
    self:OnPveDataChanged(kind=="REQDEL" and "GROUPS" or (kind=="BOARDDEL" and "BOARD" or "RAIDS"),true)
end

function OTLGM.__impl180.Stage_PVE_HandlePveAddonMessage_1__impl1(self, message, channel, sender)
    if not message or string.sub(message, 1, 3) ~= self.pveProtocol .. "^" then return false end
    if sender and PveNormalizeName(sender) == PveNormalizeName(UnitName("player") or "") then return true end
    local fields = PveSplit(message)
    local kind = fields[2] or ""
    if kind == "SYNC" then
        if sender and PveNormalizeName(sender) ~= PveNormalizeName(UnitName("player") or "") then
            self:QueuePvePayload(table.concat({ self.pveProtocol, "SYNCACK", fields[3] or "", self.version or "?" }, "^"), "WHISPER", sender)
            self:QueuePveSyncResponse(sender)
        end
        return true
    end
    if kind == "SYNCACK" then
        self:ConfirmPveSyncResponse180(sender, kind, fields[3])
        return true
    end
    -- A fresh record received during the confirmation window is also valid
    -- evidence for older R6 peers that do not yet send SYNCACK.
    self:ConfirmPveSyncResponse180(sender, kind, nil)
    if kind == "REQ" then self:ApplyRemotePveRequest(fields, sender, channel) return true end
    if kind == "APP" then
        self:ApplyRemotePveApplication(fields, sender)
        local appId=fields[3] or ""
        if appId~="" and sender then self:QueuePvePayload(table.concat({self.pveProtocol,"APPACK",appId,fields[5] or "0"},"^"),"WHISPER",sender) end
        return true
    end
    if kind == "APPACK" then local pve=self:EnsurePveDB() if pve and pve.applicationRetries then pve.applicationRetries[fields[3] or ""]=nil end return true end
    if kind == "BOARD" then self:ApplyRemotePveBoard(fields) return true end
    if kind == "RAID" then self:ApplyRemotePveRaid(fields) return true end
    if kind == "REQDEL" or kind == "BOARDDEL" or kind == "RAIDDEL" then
        local id = fields[3] or ""
        local pve = self:EnsurePveDB()
        if not pve then return true end
        local record = kind == "REQDEL" and pve.requests[id] or (kind == "BOARDDEL" and pve.board[id] or (pve.raids and pve.raids[id]))
        local senderLeadership = self:IsPveLeadershipName(sender)
        local senderOwns = record and PveNormalizeName(record.author) == PveNormalizeName(sender)
        if senderOwns or senderLeadership == true or not record then self:ApplyRemotePveDelete(kind, id, fields[4] or "0") end
        return true
    end
    if kind == "NOTICE" then
        local senderLeadership = self:IsPveLeadershipName(sender)
        if senderLeadership == false then return true end
        local eventId = fields[3] or ""
        local raid = self:GetRaidEvent180(eventId)
        local raidName = fields[5] or (raid and raid.name) or "Guild Raid"
        local serverTime = fields[6] or (raid and raid.serverTime) or ""
        local label = fields[7] or "Raid notice"
        if raid and self.ShowRaidEventNotice180 then
            self:ShowRaidEventNotice180(raid, raidName, label .. (serverTime ~= "" and (" - " .. serverTime) or ""), "remote:" .. tostring(fields[4] or "0"), true)
        end
        self:OnPveDataChanged("RAIDS", true)
        return true
    end
    if self:IsStageCPveMessageKind180(kind) then return self:HandleStageCPveMessage180(fields, sender, channel, true) end
    return true
end

function OTLGM.__impl180.Stage_PVE_OnPveDataChanged_1__impl1(self, section, remote)
    if not (self.ui and self.ui.main and self.ui.main:IsVisible()) then
        if self.RefreshPveNavigationBadge then self:RefreshPveNavigationBadge() end
        return
    end

    local function RefreshRelevantPvePage184(owner)
        if not owner then return end
        if owner.RefreshPveNavigationBadge then owner:RefreshPveNavigationBadge() end
        if not owner.ui or not owner.ui.main or not owner.ui.main:IsVisible() then return end
        if owner.ui.currentPage == "pve" and owner.RefreshPvePage then owner:RefreshPvePage() end
        if owner.ui.currentPage == "guildchat" and section == "BOARD" and owner.RefreshGuildChatPage then owner:RefreshGuildChatPage() end
        if owner.ui.currentPage == "home" and owner.RefreshHomePage then owner:RefreshHomePage() end
        if owner.ui.currentPage == "overview" and owner.RefreshOverviewPage then owner:RefreshOverviewPage() end
    end

    -- RC4-r9: an officer sync can apply many PvE records back-to-back.  Network
    -- data still commits immediately, but remote presentation is painted once at
    -- the end of the burst instead of rebuilding a complex PvE/Home page for
    -- every record. Local edits remain immediate.
    if remote and self.ScheduleAfter180 then
        self.runtime = self.runtime or {}
        self.runtime.pendingPveRefreshSections184 = self.runtime.pendingPveRefreshSections184 or {}
        if section then self.runtime.pendingPveRefreshSections184[section] = true end
        self:ScheduleAfter180("pve-visible-refresh-184", 0.08, function(owner)
            local sections184 = owner and owner.runtime and owner.runtime.pendingPveRefreshSections184 or {}
            if owner and owner.runtime then owner.runtime.pendingPveRefreshSections184 = {} end
            -- BOARD is the only section whose Guild Chat presentation differs.
            -- Preserve that signal even if a later packet in the same burst used
            -- a different section.
            if sections184.BOARD then section = "BOARD" end
            RefreshRelevantPvePage184(owner)
        end, 74)
    else
        RefreshRelevantPvePage184(self)
    end
end

if CreateFrame and not OTLGM.pveProfileEventFrame180 then
    local profileEvent = CreateFrame("Frame", "OTLGM_PveProfileEvent180")
    profileEvent:RegisterEvent("PLAYER_LEVEL_UP")
    profileEvent:RegisterEvent("PLAYER_ENTERING_WORLD")
    profileEvent:RegisterEvent("PARTY_MEMBERS_CHANGED")
    profileEvent:RegisterEvent("RAID_ROSTER_UPDATE")
    profileEvent:RegisterEvent("GUILD_ROSTER_UPDATE")
    profileEvent:SetScript("OnEvent", function()
        if event == "PLAYER_LEVEL_UP" then OTLGM:RefreshCurrentPveCharacterProfile180(arg1)
        elseif event == "PLAYER_ENTERING_WORLD" then
            OTLGM:RefreshCurrentPveCharacterProfile180()
            if OTLGM.RefreshObservedGuildFactions180 then OTLGM:RefreshObservedGuildFactions180("world") end
            OTLGM:SchedulePveGroupLiveState180("world")
            if OTLGM.ScheduleAllRaidAccessEvaluation180 then
                OTLGM:ScheduleAllRaidAccessEvaluation180(true, 2)
            elseif OTLGM.ScheduleAfter180 then
                OTLGM:ScheduleAfter180("raid-access-login", 2, function() OTLGM:EvaluateAllRaidAccess180(true) end, "NORMAL")
            else OTLGM:EvaluateAllRaidAccess180(true) end
        elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
            if OTLGM.RefreshObservedGuildFactions180 then OTLGM:RefreshObservedGuildFactions180(event) end
            OTLGM:SchedulePveGroupLiveState180(event)
            OTLGM:RefreshActiveRaidInviteSessions180(true)
        elseif event == "GUILD_ROSTER_UPDATE" then
            if OTLGM.RefreshObservedGuildFactions180 then OTLGM:RefreshObservedGuildFactions180("guild-roster") end
            OTLGM:RefreshActiveRaidInviteSessions180(true)
        end
    end)
    OTLGM.pveProfileEventFrame180 = profileEvent
end



-- ---------------------------------------------------------------------------
-- Stage C5: canonical Raid Teams and immutable event roster snapshots.
-- ---------------------------------------------------------------------------

local PVE_C5_ACTIVE_TEAM_LIMIT180 = 12
local PVE_C5_DESCRIPTION_LIMIT180 = 32
-- PVE_C5_HELPER_LIMIT180 is declared with the protocol role helpers above.
-- Role helpers are declared with the protocol serializers above.

function OTLGM:CanManageRaidTeams180(team)
    if self.IsOfficerMode and self:IsOfficerMode() then return true end
    if not team then return false end
    local player = PveNormalizeName(UnitName("player") or "")
    return player ~= "" and player == PveNormalizeName(team.raidLeader or "")
end

function OTLGM.__impl180.GetRaidTeamList180__impl1(self, includeArchived)
    local pve = self:EnsurePveDB()
    local list, id, team = {}, nil, nil
    for id, team in pairs(pve and pve.raidTeams180 or {}) do
        if type(team) == "table" and (includeArchived or team.status ~= "ARCHIVED") then table.insert(list, team) end
    end
    table.sort(list, function(left, right)
        if (left.status == "ACTIVE") ~= (right.status == "ACTIVE") then return left.status == "ACTIVE" end
        if (left.primary180 and true or false) ~= (right.primary180 and true or false) then return left.primary180 and true or false end
        local ln, rn = string.lower(left.name or ""), string.lower(right.name or "")
        if ln ~= rn then return ln < rn end
        return tostring(left.id or "") < tostring(right.id or "")
    end)
    return list
end

function OTLGM:GetRaidTeamMemberCount180(team)
    local total, core, reserve, guest = 0, 0, 0, 0
    local _, member
    for _, member in pairs(team and team.members or {}) do
        total = total + 1
        if member.tier == "CORE" then core = core + 1
        elseif member.tier == "RESERVE" then reserve = reserve + 1
        else guest = guest + 1 end
    end
    return total, core, reserve, guest
end

function OTLGM:ValidateRaidTeamName180(name, ignoreId)
    name = PveSafeText(name or "", 36)
    if name == "" then return nil, "Enter a Raid Team name." end
    local pve = self:EnsurePveDB()
    if not pve then return nil, "Guild data is not ready." end
    local normalized = string.lower(name)
    local _, team
    for _, team in pairs(pve.raidTeams180 or {}) do
        if team.id ~= ignoreId and string.lower(team.name or "") == normalized then return nil, "A Raid Team with this name already exists." end
    end
    return name
end

function OTLGM:QueueRaidTeamSnapshot180(team, channel, target)
    if not team or not team.id then return false end
    local header = self:SerializeRaidTeamHeader180(team)
    if not header then return false end
    local allQueued = self:QueuePvePayload(header, channel or "GUILD", target) and true or false
    local rows, _, member = {}, nil, nil
    for _, member in pairs(team.members or {}) do table.insert(rows, member) end
    table.sort(rows, function(left, right) return PveNormalizeName(left.character) < PveNormalizeName(right.character) end)
    local index, payload
    for index = 1, table.getn(rows) do
        payload = self:SerializeRaidTeamMember180(team.id, team.rev, rows[index])
        if payload and not self:QueuePvePayload(payload, channel or "GUILD", target) then allQueued = false end
    end
    return allQueued
end

function OTLGM:CreateRaidTeam180(data)
    if not (self.IsOfficerMode and self:IsOfficerMode()) then return false, "Only Leadership can create a permanent Raid Team." end
    local pve = self:EnsurePveDB()
    if not pve then return false, "Guild data is not ready." end
    data = type(data) == "table" and data or {}
    local name, errorText = self:ValidateRaidTeamName180(data.name)
    if not name then return false, errorText end
    local active = 0
    local _, candidate
    for _, candidate in pairs(pve.raidTeams180 or {}) do if candidate.status ~= "ARCHIVED" then active = active + 1 end end
    if active >= PVE_C5_ACTIVE_TEAM_LIMIT180 then return false, "The active Raid Team limit has been reached." end
    local player = PveSafeText(UnitName("player") or "Unknown", 40)
    local leader = PveSafeText(data.raidLeader or player, 40)
    if leader == "" then leader = player end
    local contact = PveSafeText(data.inviteContact or leader, 40)
    if contact == "" then contact = leader end
    local helpers = PveC5SplitNames180(self, data.inviteHelpers)
    local team = {
        id = self:MakePveID("T"), rev = 1, ts = self:Now(), status = "ACTIVE",
        name = name, raidLeader = leader, inviteContact = contact,
        inviteHelpers = PveC5JoinNames180(helpers), description = PveSafeText(data.description or "", PVE_C5_DESCRIPTION_LIMIT180),
        createdBy = player, createdAt = self:Now(), members = {}, primary180 = false,
    }
    pve.raidTeams180[team.id] = team
    pve.raidTeamDeleted180[team.id] = nil
    self:QueueRaidTeamSnapshot180(team, "GUILD")
    self:OnPveDataChanged("RAIDS", false)
    return true, team
end

function OTLGM:UpdateRaidTeam180(teamId, data)
    local team = self:GetRaidTeam180(teamId)
    if not team then return false, "Raid Team not found." end
    if not self:CanManageRaidTeams180(team) then return false, "You do not have permission to edit this Raid Team." end
    data = type(data) == "table" and data or {}
    if data.name ~= nil then
        local name, errorText = self:ValidateRaidTeamName180(data.name, teamId)
        if not name then return false, errorText end
        team.name = name
    end
    if data.raidLeader ~= nil then
        local leader = PveSafeText(data.raidLeader, 40)
        if leader == "" then return false, "Raid Leader is required." end
        team.raidLeader = leader
    end
    if data.inviteContact ~= nil then team.inviteContact = PveSafeText(data.inviteContact, 40) end
    if team.inviteContact == "" then team.inviteContact = team.raidLeader end
    if data.inviteHelpers ~= nil then team.inviteHelpers = PveC5JoinNames180(PveC5SplitNames180(self, data.inviteHelpers)) end
    if data.description ~= nil then team.description = PveSafeText(data.description, PVE_C5_DESCRIPTION_LIMIT180) end
    if data.status ~= nil then team.status = data.status == "ARCHIVED" and "ARCHIVED" or "ACTIVE" end
    if team.status == "ARCHIVED" then team.primary180 = false end
    local wantsPrimary = data.primary180 == true and team.status ~= "ARCHIVED"
    if data.primary180 ~= nil and not wantsPrimary then team.primary180 = false end
    team.rev = (tonumber(team.rev) or 0) + 1
    team.ts = self:Now()
    local _, member
    for _, member in pairs(team.members or {}) do member.teamRev = team.rev member.updatedAt = team.ts end
    if wantsPrimary then
        local pve = self:EnsurePveDB()
        if not pve then return false, "Guild data is not ready." end
        local otherId, otherTeam
        for otherId, otherTeam in pairs(pve.raidTeams180 or {}) do
            if otherId ~= team.id and type(otherTeam) == "table" and otherTeam.primary180 then
                otherTeam.primary180 = false
                otherTeam.rev = (tonumber(otherTeam.rev) or 0) + 1
                otherTeam.ts = self:Now()
                self:QueueRaidTeamSnapshot180(otherTeam, "GUILD")
            end
        end
        team.primary180 = true
    end
    self:QueueRaidTeamSnapshot180(team, "GUILD")
    self:OnPveDataChanged("RAIDS", false)
    return true, team
end

function OTLGM:SetPrimaryRaidTeam180(teamId)
    if not (self.IsOfficerMode and self:IsOfficerMode()) then return false, "Only Leadership can set the Primary Raid Team." end
    local team = self:GetRaidTeam180(teamId)
    if not team or team.status == "ARCHIVED" then return false, "Choose an active Raid Team." end
    return self:UpdateRaidTeam180(teamId, { primary180 = true })
end

function OTLGM:ArchiveRaidTeam180(teamId, archived)
    return self:UpdateRaidTeam180(teamId, { status = archived == false and "ACTIVE" or "ARCHIVED" })
end

function OTLGM:DeleteRaidTeam180(teamId)
    local pve = self:EnsurePveDB()
    local team = pve and pve.raidTeams180 and pve.raidTeams180[teamId]
    if not team then return false, "Raid Team not found." end
    if not self:CanManageRaidTeams180(team) then return false, "You do not have permission to delete this Raid Team." end
    local rev = (tonumber(team.rev) or 0) + 1
    local ts = self:Now()
    pve.raidTeams180[teamId] = nil
    pve.raidTeamDeleted180[teamId] = { rev = rev, ts = ts }
    PvePruneOldestMap180(pve.raidTeamDeleted180, PVE_C0_TEAM_TOMBSTONE_LIMIT)
    self:QueuePvePayload(self:SerializeRaidTeamDelete180(teamId, rev, ts), "GUILD")
    -- Published event.roster180 snapshots intentionally remain untouched.
    self:OnPveDataChanged("RAIDS", false)
    return true
end

function OTLGM:MutateRaidTeamMembers180(teamId, characters, action, value)
    local team = self:GetRaidTeam180(teamId)
    if not team then return false, "Raid Team not found." end
    if not self:CanManageRaidTeams180(team) then return false, "You do not have permission to manage this Raid Team." end
    characters = type(characters) == "table" and characters or {}
    action = string.upper(tostring(action or ""))
    if action == "ROLE" then action = "MAIN_ROLE" end -- old button/network callers.
    value = string.upper(tostring(value or ""))
    local changed, player, db = false, PveSafeText(UnitName("player") or "Unknown", 40), self:GetGuildDB()
    local _, character, key, member, rosterMember
    for _, character in pairs(characters) do
        character = type(character) == "table" and (character.character or character.name) or character
        character = PveSafeText(character or "", 40)
        key = PveNormalizeName(character)
        if key ~= "" then
            member = team.members and team.members[key]
            if action == "ADD" then
                if not member then
                    rosterMember = self:GetMember(character) or (db and db.roster and (db.roster[character] or db.roster[key]))
                    team.members[key] = {
                        character = rosterMember and rosterMember.name or character,
                        class = PveSafeText(rosterMember and (rosterMember.classFile or rosterMember.class) or "", 16),
                        mainRole = "UNASSIGNED", role = "FLEXIBLE", offspecRole = nil, roleNeedsReview180 = true,
                        tier = "GUEST", note = "", addedBy = player, addedAt = self:Now(),
                    }
                    changed = true
                end
            elseif action == "REMOVE" and member then
                team.members[key] = nil changed = true
            elseif action == "TIER" and member and PVE_C5_TIERS180[value] and member.tier ~= value then
                member.tier = value changed = true
            elseif action == "MAIN_ROLE" and member and PVE_C5_MAIN_ROLES180[value] then
                local current = PveNormalizeMainRole180(member)
                if current ~= value or member.roleNeedsReview180 then
                    member.mainRole = value member.role = value member.roleNeedsReview180 = nil
                    if string.upper(tostring(member.offspecRole or "NONE")) == value then member.offspecRole = nil end
                    changed = true
                end
            elseif action == "OFFSPEC_ROLE" and member and PVE_C5_OFFSPEC_ROLES180[value] then
                local mainRole = PveNormalizeMainRole180(member)
                local nextOffspec = value == "NONE" and nil or value
                if nextOffspec == mainRole then nextOffspec = nil end
                if tostring(member.offspecRole or "") ~= tostring(nextOffspec or "") then member.offspecRole = nextOffspec changed = true end
            end
        end
    end
    if not changed then return false, "No Raid Team membership changes were required." end
    team.rev = (tonumber(team.rev) or 0) + 1
    team.ts = self:Now()
    for _, member in pairs(team.members or {}) do
        PveNormalizeRaidMemberRoles180(member)
        member.teamRev = team.rev member.updatedAt = team.ts
    end
    PvePruneOldestMap180(team.members, PVE_C0_MEMBER_LIMIT)
    self:QueueRaidTeamSnapshot180(team, "GUILD")
    self:OnPveDataChanged("RAIDS", false)
    return true, team
end

function OTLGM:BuildRaidRosterSnapshotFromTeam180(teamId)
    local team = self:GetRaidTeam180(teamId)
    if not team then return nil, "Raid Team not found." end
    local roster, key, member = {}, nil, nil
    for key, member in pairs(team.members or {}) do
        local mainRole, offspec = PveNormalizeRaidMemberRoles180(member)
        roster[key] = {
            character = member.character, class = member.class,
            mainRole = mainRole, role = mainRole == "UNASSIGNED" and "FLEXIBLE" or mainRole,
            offspecRole = offspec ~= "NONE" and offspec or nil,
            roleNeedsReview180 = mainRole == "UNASSIGNED" and true or nil,
            slotStatus = member.tier == "CORE" and "ASSIGNED" or (member.tier == "RESERVE" and "RESERVE" or "GUEST"),
            sourceTeamId180 = team.id, sourceTeamRev180 = team.rev,
        }
    end
    return roster, team
end

function OTLGM:CloneRaidEventRoster180(eventId)
    local event = self:GetRaidRosterSourceEvent180(eventId)
    if not event then return nil, "Source raid event not found." end
    return PveC5CopyRoster180(event.roster180 or {}), event
end

function OTLGM:GetPreviousRaidRosterSources180(excludeId)
    local pve = self:EnsurePveDB()
    local list, id, event = {}, nil, nil
    for id, event in pairs(pve and pve.raids or {}) do
        if id ~= excludeId and type(event.roster180) == "table" and next(event.roster180) then table.insert(list, event) end
    end
    for id, event in pairs(pve and pve.cancelledRaids156 or {}) do
        if id ~= excludeId and type(event.roster180) == "table" and next(event.roster180) then table.insert(list, event) end
    end
    for id, event in pairs(pve and pve.archivedRaids180 or {}) do
        if id ~= excludeId and type(event.roster180) == "table" and next(event.roster180) then table.insert(list, event) end
    end
    table.sort(list, function(left, right) return (tonumber(left.startTs) or 0) > (tonumber(right.startTs) or 0) end)
    return list
end

function OTLGM:GetRaidRosterSummary180(roster)
    local result = { total = 0, assigned = 0, reserve = 0, guest = 0, TANK = 0, HEALER = 0, DAMAGE = 0, UNASSIGNED = 0 }
    local _, member
    for _, member in pairs(roster or {}) do
        result.total = result.total + 1
        if member.slotStatus == "RESERVE" then result.reserve = result.reserve + 1
        elseif member.slotStatus == "GUEST" then result.guest = result.guest + 1
        else result.assigned = result.assigned + 1 end
        local mainRole = PveNormalizeMainRole180(member)
        result[mainRole] = (result[mainRole] or 0) + 1
    end
    return result.total, result.assigned, result.reserve, result.guest, result
end

function OTLGM:QueueRaidEventSnapshot180(event, channel, target)
    if not event or not event.id then return false end
    local meta = self:SerializeRaidEventMeta180(event)
    local prefix = target and ("raid-target:" .. PveNormalizeName(target) .. ":") or "raid-guild:"
    local allQueued = meta and self:QueuePvePayload(meta, channel or "GUILD", target, prefix .. "meta:" .. tostring(event.id)) and true or false
    local rows, _, member = {}, nil, nil
    for _, member in pairs(event.roster180 or {}) do table.insert(rows, member) end
    table.sort(rows, function(left, right) return PveNormalizeName(left.character) < PveNormalizeName(right.character) end)
    local index, payload, key
    for index = 1, table.getn(rows) do
        payload = self:SerializeRaidRosterMember180(event.id, event.rev, rows[index])
        key = PveNormalizeName(rows[index].character)
        if payload and not self:QueuePvePayload(payload, channel or "GUILD", target, prefix .. "member:" .. tostring(event.id) .. ":" .. key) then allQueued = false end
    end
    return allQueued
end

function OTLGM:ApplyRaidRosterSourceAfterPublish180(event, data, existingId)
    if not event then return false end
    data = type(data) == "table" and data or {}
    local mode = string.upper(tostring(data.rosterMode180 or (existingId and "KEEP" or "CUSTOM")))
    local sourceId = data.rosterSourceId180
    local draft = type(data.eventRosterDraft180) == "table" and PveC5CopyRoster180(data.eventRosterDraft180) or nil
    local roster, source

    -- C5-R4: a team or previous event is only a template. The editor owns an
    -- independent draft immediately after import, and publishing stores that
    -- exact draft instead of rebuilding from a possibly changed source.
    if mode == "TEAM" then
        source = self:GetRaidTeam180(sourceId)
        if not source or source.status == "ARCHIVED" then return false, "Raid Team not found." end
        roster = draft
        if not roster then roster = self:BuildRaidRosterSnapshotFromTeam180(sourceId) end
        if not roster then return false, "Raid Team roster could not be copied." end
        event.roster180 = PveC5CopyRoster180(roster)
        event.teamId180 = source.id
        event.rosterSource180 = "RAID_TEAM"
        event.rosterSourceId180 = source.id
        event.rosterSourceRev180 = source.rev
    elseif mode == "CLONE_PREVIOUS" then
        source = self:GetRaidRosterSourceEvent180(sourceId)
        if not source or type(source.roster180) ~= "table" or not next(source.roster180) then return false, "Source raid event not found." end
        roster = draft or PveC5CopyRoster180(source.roster180)
        event.roster180 = PveC5CopyRoster180(roster)
        event.teamId180 = source.teamId180
        event.rosterSource180 = "CLONE_PREVIOUS"
        event.rosterSourceId180 = source.id
        event.rosterSourceRev180 = source.rev
    elseif mode == "CUSTOM" then
        if draft then event.roster180 = draft
        elseif type(data.customRoster180) == "table" then event.roster180 = PveC5CopyRoster180(data.customRoster180)
        elseif not existingId then event.roster180 = {}
        else event.roster180 = PveC5CopyRoster180(event.roster180 or {}) end
        event.teamId180 = nil
        event.rosterSource180 = "CUSTOM"
        event.rosterSourceId180 = nil
        event.rosterSourceRev180 = nil
    else
        event.roster180 = draft or PveC5CopyRoster180(event.roster180 or {})
        event.rosterSource180 = event.rosterSource180 or "CUSTOM"
    end
    local _, rosterMember
    for _, rosterMember in pairs(event.roster180 or {}) do PveNormalizeRaidMemberRoles180(rosterMember) end
    event.visibility180 = event.visibility180 or "GUILD_VISIBLE"
    event.notifyAudience180 = event.notifyAudience180 or "ASSIGNED"
    event.eventMetaRev180 = event.rev
    event.rosterSnapshotAt180 = self:Now()
    self:QueueRaidEventSnapshot180(event, "GUILD")
    return true, event
end

function OTLGM:RefreshRaidEventRosterFromTeam180(eventId)
    local event = self:GetRaidEvent180(eventId)
    if not event then return false, "Raid event not found." end
    if not self:CanModifyPveRecord(event) then return false, "You do not have permission to refresh this event roster." end
    if not event.teamId180 or event.teamId180 == "" then return false, "This event is not linked to a saved Raid Team roster." end
    local roster, team = self:BuildRaidRosterSnapshotFromTeam180(event.teamId180)
    if not roster then return false, team end
    event.rev = (tonumber(event.rev) or 0) + 1
    event.ts = self:Now()
    event.roster180 = roster
    event.rosterSource180 = "RAID_TEAM"
    event.rosterSourceId180 = team.id
    event.rosterSourceRev180 = team.rev
    event.rosterSnapshotAt180 = self:Now()
    event.eventMetaRev180 = event.rev
    self:QueuePvePayload(self:SerializePveRaid(event), "GUILD")
    if self.QueueRaidMeta157 then self:QueueRaidMeta157(event) end
    self:QueueRaidEventSnapshot180(event, "GUILD")
    self:OnPveDataChanged("RAIDS", false)
    return true, event
end


-- C5-R3 PACK B: compact Raid Team dashboard data. Calculated only on page
-- refresh or relevant data events; no polling or new OnUpdate is introduced.
local function PveRaidTeamDashboardSignature180(self, team, now)
    local parts, key, member = { tostring(team and team.id or ""), tostring(team and team.rev or 0), tostring(math.floor((tonumber(now) or 0) / 5)) }, nil, nil
    for key, member in pairs(team and team.members or {}) do
        local rosterMember = self:GetMember(member.character)
        table.insert(parts, tostring(key) .. ":" .. (rosterMember and rosterMember.online and "1" or "0"))
    end
    table.sort(parts)
    return table.concat(parts, "|")
end

function OTLGM:GetRaidTeamDashboard180(team)
    local result = {
        total = 0, online = 0, onlineNames = {}, offlineNames = {},
        tiers = { CORE = 0, RESERVE = 0, GUEST = 0 },
        roles = {
            TANK = { total = 0, online = 0, onlineNames = {}, offlineNames = {} },
            HEALER = { total = 0, online = 0, onlineNames = {}, offlineNames = {} },
            DAMAGE = { total = 0, online = 0, onlineNames = {}, offlineNames = {} },
            UNASSIGNED = { total = 0, online = 0, onlineNames = {}, offlineNames = {} },
        },
        nextRaid = nil,
    }
    if type(team) ~= "table" then return result end
    self.runtime = self.runtime or {}
    self.runtime.raidTeamDashboardCache180 = self.runtime.raidTeamDashboardCache180 or {}
    local now = self:Now()
    local signature = PveRaidTeamDashboardSignature180(self, team, now)
    local cached = self.runtime.raidTeamDashboardCache180[team.id]
    if cached and cached.signature == signature then
        self.runtime.raidTeamRefreshMetrics180 = self.runtime.raidTeamRefreshMetrics180 or {}
        self.runtime.raidTeamRefreshMetrics180.dashboardCacheHits = (tonumber(self.runtime.raidTeamRefreshMetrics180.dashboardCacheHits) or 0) + 1
        return cached.value
    end
    local _, member
    for _, member in pairs(team.members or {}) do
        local role = PveNormalizeMainRole180(member)
        local tier = member.tier == "CORE" and "CORE" or (member.tier == "RESERVE" and "RESERVE" or "GUEST")
        local rosterMember = self:GetMember(member.character)
        local online = rosterMember and rosterMember.online and true or false
        local roleInfo = result.roles[role] or result.roles.UNASSIGNED
        result.total = result.total + 1
        result.tiers[tier] = (result.tiers[tier] or 0) + 1
        roleInfo.total = roleInfo.total + 1
        if online then
            result.online = result.online + 1
            roleInfo.online = roleInfo.online + 1
            table.insert(result.onlineNames, member.character)
            table.insert(roleInfo.onlineNames, member.character)
        else
            table.insert(result.offlineNames, member.character)
            table.insert(roleInfo.offlineNames, member.character)
        end
    end
    local function sortNames(rows) table.sort(rows, function(a,b) return PveNormalizeName(a) < PveNormalizeName(b) end) end
    sortNames(result.onlineNames) sortNames(result.offlineNames)
    for _, member in pairs(result.roles) do sortNames(member.onlineNames) sortNames(member.offlineNames) end
    local pve = self:EnsurePveDB()
    local _, event
    for _, event in pairs(pve and pve.raids or {}) do
        if type(event) == "table" and event.teamId180 == team.id and not event.cancelled
            and (tonumber(event.startTs) or 0) >= now then
            if not result.nextRaid or (tonumber(event.startTs) or 0) < (tonumber(result.nextRaid.startTs) or 0) then result.nextRaid = event end
        end
    end
    self.runtime.raidTeamDashboardCache180[team.id] = { signature = signature, value = result }
    self.runtime.raidTeamRefreshMetrics180 = self.runtime.raidTeamRefreshMetrics180 or {}
    self.runtime.raidTeamRefreshMetrics180.dashboardBuilds = (tonumber(self.runtime.raidTeamRefreshMetrics180.dashboardBuilds) or 0) + 1
    return result
end

function OTLGM:GetPrimaryRaidTeam180()
    local teams = self:GetRaidTeamList180(false)
    local index
    for index = 1, table.getn(teams) do if teams[index].primary180 then return teams[index] end end
    return nil
end

OTLGM:RegisterModule("PVE", { layer = "feature", protocol = OTLGM.pveProtocol, release = "1.8.0" })


-- ---------------------------------------------------------------------------
-- C5-R2 PACK 2: Raid Team visibility, exact character membership UX,
-- targeted membership notifications and rank-aware roster picker data.
-- This extends the canonical PVE module without changing schema 15.
-- ---------------------------------------------------------------------------

local PVE_C5_R2_PICKER_CATEGORY_ORDER180 = {
    LEADERSHIP = 1,
    RAIDERS = 2,
    MEMBERS = 3,
    GUESTS = 4,
}

local function PveC5R2MemberCopy180(member)
    if type(member) ~= "table" then return nil end
    local copy = {}
    local key, value
    for key, value in pairs(member) do copy[key] = value end
    return copy
end

local function PveC5R2MembershipFingerprint180(member)
    if type(member) ~= "table" then return "REMOVED" end
    local mainRole, offspec = PveNormalizeRaidMemberRoles180(member)
    return tostring(member.tier or "GUEST") .. ":" .. tostring(mainRole) .. ":" .. tostring(offspec)
end

local function PveC5R2RosterCategory180(self, member)
    if type(member) ~= "table" then return "GUESTS" end
    if self.IsLeadership and self:IsLeadership(member) then return "LEADERSHIP" end
    local rankIndex = tonumber(member.rankIndex)
    if rankIndex == nil then rankIndex = 99 end
    if rankIndex <= 3 then return "LEADERSHIP" end
    if rankIndex <= 5 then return "RAIDERS" end
    if rankIndex <= 7 then return "MEMBERS" end
    return "GUESTS"
end

function OTLGM:GetRaidTeamRosterCategory180(member)
    return PveC5R2RosterCategory180(self, member)
end

function OTLGM:GetRaidTeamMembership180(team, character)
    if type(team) ~= "table" or type(team.members) ~= "table" then return nil end
    local key = PveNormalizeName(character or UnitName("player") or "")
    if key == "" then return nil end
    return team.members[key]
end

local PreviousGetRaidTeamListC5R2 = OTLGM.__impl180.GetRaidTeamList180__impl1
function OTLGM:GetRaidTeamList180(includeArchived, myTeamsOnly)
    local list = PreviousGetRaidTeamListC5R2(self, includeArchived)
    if not myTeamsOnly then return list end
    local player = UnitName("player") or ""
    local filtered, index = {}, 1
    for index = 1, table.getn(list) do
        if self:GetRaidTeamMembership180(list[index], player) then table.insert(filtered, list[index]) end
    end
    return filtered
end

function OTLGM:GetRaidTeamRosterCandidates180(searchText, classFilter, selectedOnly, selection, categoryFilter, onlineOnly, teamId)
    local db = self:GetGuildDB()
    local list, name, member = {}, nil, nil
    local search = string.lower(PveSafeText(searchText or "", 48))
    classFilter = string.upper(PveSafeText(classFilter or "ALL", 16))
    categoryFilter = string.upper(PveSafeText(categoryFilter or "MEMBERS", 16))
    selection = type(selection) == "table" and selection or {}
    local team = teamId and self:GetRaidTeam180(teamId) or nil
    for name, member in pairs(db and db.roster or {}) do
        local key = PveNormalizeName(member.name or name)
        local category = PveC5R2RosterCategory180(self, member)
        local allowed = not selectedOnly or selection[key] == true
        if allowed and onlineOnly and not member.online then allowed = false end
        if allowed and categoryFilter == "MEMBERS" and category == "GUESTS" then allowed = false
        elseif allowed and categoryFilter ~= "ALL" and categoryFilter ~= "MEMBERS" and category ~= categoryFilter then allowed = false end
        local classToken = string.upper(PveSafeText(member.classFile or member.class or "", 16))
        if allowed and classFilter ~= "ALL" and classToken ~= classFilter and string.upper(member.class or "") ~= classFilter then allowed = false end
        if allowed and search ~= "" then
            local haystack = string.lower((member.name or name or "") .. " " .. (member.class or "") .. " " .. (member.rank or ""))
            if not string.find(haystack, search, 1, true) then allowed = false end
        end
        if allowed then
            local row = PveC5R2MemberCopy180(member) or {}
            row.name = row.name or name
            row.raidTeamCategory180 = category
            row.raidTeamAlreadyIn180 = team and team.members and team.members[key] and true or false
            table.insert(list, row)
        end
    end
    table.sort(list, function(left, right)
        local leftCategory = PVE_C5_R2_PICKER_CATEGORY_ORDER180[left.raidTeamCategory180] or 9
        local rightCategory = PVE_C5_R2_PICKER_CATEGORY_ORDER180[right.raidTeamCategory180] or 9
        if leftCategory ~= rightCategory then return leftCategory < rightCategory end
        local leftOnline, rightOnline = left.online and true or false, right.online and true or false
        if leftOnline ~= rightOnline then return leftOnline end
        local leftLevel, rightLevel = tonumber(left.level) or 0, tonumber(right.level) or 0
        if leftLevel ~= rightLevel then return leftLevel > rightLevel end
        local leftRank, rightRank = tonumber(left.rankIndex) or 99, tonumber(right.rankIndex) or 99
        if leftRank ~= rightRank then return leftRank < rightRank end
        return PveNormalizeName(left.name) < PveNormalizeName(right.name)
    end)
    return list
end

function OTLGM:NotifyRaidTeamMembershipChange180(team, oldMember, newMember, remote)
    if not remote or not team or not team.id then return false end
    local oldFingerprint = PveC5R2MembershipFingerprint180(oldMember)
    local newFingerprint = PveC5R2MembershipFingerprint180(newMember)
    if oldFingerprint == newFingerprint then return false end
    local player = PveSafeText(UnitName("player") or "", 40)
    if player == "" then return false end
    local title, body
    if not oldMember and newMember then
        title = "Added to Raid Team"
        body = "You are " .. string.lower(tostring(newMember.tier or "Guest")) .. " in " .. tostring(team.name or "Raid Team") .. " as " .. tostring(newMember.role or "Flexible") .. "."
    elseif oldMember and not newMember then
        title = "Removed from Raid Team"
        body = "You are no longer listed in " .. tostring(team.name or "Raid Team") .. "."
    else
        title = "Raid Team assignment changed"
        body = tostring(team.name or "Raid Team") .. ": " .. tostring(newMember.tier or "Guest") .. " / " .. tostring(newMember.role or "Flexible") .. "."
    end
    local eventKey = "raid-team-membership:" .. tostring(team.id) .. ":" .. tostring(team.rev or 0) .. ":" .. newFingerprint
    if self.NotifyEvent152 then
        return self:NotifyEvent152("raid", eventKey, title, body, "ACTION", true, "pve", {
            objectType = "RAID_TEAM",
            objectId = team.id,
            section = "TEAMS",
            actionKey = "MEMBERSHIP",
        })
    end
    if self.AddObjectInboxNotification180 then
        return self:AddObjectInboxNotification180("raid", eventKey, title, body, "ACTION", "RAID_TEAM", team.id, "TEAMS", "MEMBERSHIP", "pve")
    end
    return false
end

local PreviousApplyRemoteRaidTeamHeaderC5R2 = OTLGM.__impl180.ApplyRemoteRaidTeamHeader180__impl1
function OTLGM:ApplyRemoteRaidTeamHeader180(fields, sender, channel)
    local teamId = fields and fields[3] or ""
    local incomingRev = tonumber(fields and fields[4]) or 0
    local oldTeam = self:GetRaidTeam180(teamId)
    local oldRev = oldTeam and (tonumber(oldTeam.rev) or 0) or 0
    local oldMember = oldTeam and PveC5R2MemberCopy180(self:GetRaidTeamMembership180(oldTeam)) or nil
    local result = PreviousApplyRemoteRaidTeamHeaderC5R2(self, fields, sender, channel)
    if result and oldMember and incomingRev > oldRev then
        self.runtime = self.runtime or {}
        self.runtime.raidTeamMembershipPending180 = self.runtime.raidTeamMembershipPending180 or {}
        self.runtime.raidTeamMembershipPending180[teamId] = {
            due = self:Now() + 2,
            rev = incomingRev,
            oldMember = oldMember,
        }
        if self.WakeScheduler180 then self:WakeScheduler180("raid-team-membership") end
    end
    if result and self.ReevaluateAnnouncementAudiences180 then self:ReevaluateAnnouncementAudiences180() end
    return result
end

local PreviousApplyRemoteRaidTeamMemberC5R2 = OTLGM.__impl180.ApplyRemoteRaidTeamMember180__impl1
function OTLGM:ApplyRemoteRaidTeamMember180(fields, sender, channel)
    local teamId = fields and fields[3] or ""
    local character = fields and fields[5] or ""
    local playerKey = PveNormalizeName(UnitName("player") or "")
    local characterKey = PveNormalizeName(character)
    local teamBefore = self:GetRaidTeam180(teamId)
    local oldMember = teamBefore and PveC5R2MemberCopy180(self:GetRaidTeamMembership180(teamBefore)) or nil
    self.runtime = self.runtime or {}
    local pending = self.runtime.raidTeamMembershipPending180 and self.runtime.raidTeamMembershipPending180[teamId]
    if pending and pending.oldMember then oldMember = PveC5R2MemberCopy180(pending.oldMember) end
    local result = PreviousApplyRemoteRaidTeamMemberC5R2(self, fields, sender, channel)
    if result and playerKey ~= "" and characterKey == playerKey then
        local teamAfter = self:GetRaidTeam180(teamId)
        local newMember = teamAfter and PveC5R2MemberCopy180(self:GetRaidTeamMembership180(teamAfter)) or nil
        if self.runtime.raidTeamMembershipPending180 then self.runtime.raidTeamMembershipPending180[teamId] = nil end
        self:NotifyRaidTeamMembershipChange180(teamAfter, oldMember, newMember, true)
    end
    if result and self.ReevaluateAnnouncementAudiences180 then self:ReevaluateAnnouncementAudiences180() end
    return result
end

local PreviousApplyRemoteRaidTeamDeleteC5R2 = OTLGM.__impl180.ApplyRemoteRaidTeamDelete180__impl1
function OTLGM:ApplyRemoteRaidTeamDelete180(fields)
    local teamId = fields and fields[3] or ""
    local oldTeam = self:GetRaidTeam180(teamId)
    local oldMember = oldTeam and PveC5R2MemberCopy180(self:GetRaidTeamMembership180(oldTeam)) or nil
    local snapshot = oldTeam and PveC5DeepCopy180(oldTeam) or nil
    local result = PreviousApplyRemoteRaidTeamDeleteC5R2(self, fields)
    if result and oldMember and snapshot then self:NotifyRaidTeamMembershipChange180(snapshot, oldMember, nil, true) end
    if self.runtime and self.runtime.raidTeamMembershipPending180 then self.runtime.raidTeamMembershipPending180[teamId] = nil end
    return result
end

function OTLGM:ProcessRaidTeamMembershipNotifications180()
    local pending = self.runtime and self.runtime.raidTeamMembershipPending180
    if type(pending) ~= "table" then return false end
    local now = self:Now()
    local teamId, entry
    for teamId, entry in pairs(pending) do
        if type(entry) ~= "table" or (tonumber(entry.due) or 0) <= now then
            pending[teamId] = nil
            local team = self:GetRaidTeam180(teamId)
            if team and (tonumber(team.rev) or 0) == (tonumber(entry and entry.rev) or 0)
                and not self:GetRaidTeamMembership180(team) and entry and entry.oldMember then
                self:NotifyRaidTeamMembershipChange180(team, entry.oldMember, nil, true)
            end
        end
    end
    return true
end

-- ---------------------------------------------------------------------------
-- Stage C6: targeted raid access, participant status, and manual Invite Mode.
-- Canonical domain logic only. UI ownership remains in NativePages.lua.
-- ---------------------------------------------------------------------------

local PVE_C6_ACCESS_PER_CHARACTER_LIMIT180 = 160
local PVE_C6_INVITE_SESSION_MEMBER_LIMIT180 = 60
local PVE_C6_ACCESS_EVAL_PER_SLICE180 = 4
local PVE_C6_INVITE_STATE180 = { WAITING = true, INVITED = true, JOINED = true, OFFLINE = true }
local PVE_C6_SLOT_ORDER180 = { ASSIGNED = 1, RESERVE = 2, GUEST = 3 }
local PVE_C6_ROLE_ORDER180 = { TANK = 1, HEALER = 2, DAMAGE = 3, UNASSIGNED = 4 }

local function PveC6ShortName180(name)
    name = PveSafeText(name or "", 40)
    return string.gsub(name, "%-.*$", "")
end

local function PveC6NameEquals180(left, right)
    return PveNormalizeName(left or "") ~= "" and PveNormalizeName(left or "") == PveNormalizeName(right or "")
end

local function PveC6EventStatus180(event)
    if not event then return "MISSING" end
    local status = string.upper(tostring(event.status or "UPCOMING"))
    if status == "CANCELLED" then return "CANCELLED" end
    if status == "DRAFT" then return "DRAFT" end
    local startTs = tonumber(event.startTs) or 0
    if startTs > 0 and startTs + 14400 < OTLGM:Now() then return "PAST" end
    return "UPCOMING"
end

local function PveC6NormalizeEvent180(event)
    if type(event) ~= "table" then return nil end
    event.visibility180 = PveStageCStatus180(event.visibility180,
        { PRIVATE_TEAM = true, GUILD_VISIBLE = true, OPEN_GUILD = true }, "GUILD_VISIBLE")
    event.notifyAudience180 = PveStageCStatus180(event.notifyAudience180,
        { ASSIGNED = true, ASSIGNED_RESERVES = true, ENTIRE_TEAM = true, ALL_GUILD = true }, "ASSIGNED")
    event.discordUrl180 = PveSafeUrl180(event.discordUrl180 or "", 96)
    event.signUpNote180 = PveSafeText(event.signUpNote180 or "", 120)
    event.roster180 = type(event.roster180) == "table" and event.roster180 or {}
    event.participantStatus180 = type(event.participantStatus180) == "table" and event.participantStatus180 or {}
    event.participantStatusRevision180 = math.max(1, tonumber(event.participantStatusRevision180) or 1)
    event.inviteRevision = tonumber(event.inviteRevision) or 0
    event.invitesOpen = event.invitesOpen and true or false
    return event
end

function OTLGM:NormalizeRaidEventC6(event)
    return PveC6NormalizeEvent180(event)
end

function OTLGM:GetRaidEventRosterMember180(event, character)
    if type(event) ~= "table" then return nil end
    local wanted = PveNormalizeName(character or UnitName("player") or "")
    if wanted == "" then return nil end
    local key, member
    for key, member in pairs(event.roster180 or {}) do
        if PveNormalizeName(member and member.character or key) == wanted then return member, key end
    end
    return nil
end

function OTLGM:IsRaidEventManager180(event, character)
    if not event then return false end
    character = character or UnitName("player") or ""
    if character == (UnitName("player") or "") and self.IsOfficerMode and self:IsOfficerMode() then return true end
    if self:IsPveLeadershipName(character) == true then return true end
    return PveC6NameEquals180(event.author, character) or PveC6NameEquals180(event.raidLeader, character)
end

function OTLGM:IsRaidInviteManager180(event, character)
    if not event then return false end
    character = character or UnitName("player") or ""
    if self:IsRaidEventManager180(event, character) then return true end
    if PveC6NameEquals180(event.inviteContact or event.raidLeader, character) then return true end
    local parts = self:Split(string.gsub(tostring(event.inviteHelpers or ""), ";", ","), ",") or {}
    local index
    for index = 1, table.getn(parts) do if PveC6NameEquals180(parts[index], character) then return true end end
    return false
end

function OTLGM:GetRaidEventLocalAlt180(event, excludeCharacter)
    if type(event) ~= "table" then return nil end
    local account = self:GetPveAccountState180()
    local exclude = PveNormalizeName(excludeCharacter or UnitName("player") or "")
    local profileKey, profile
    for profileKey, profile in pairs(account and account.characterProfiles180 or {}) do
        local name = type(profile) == "table" and profile.name or nil
        if name and PveNormalizeName(name) ~= exclude then
            local member = self:GetRaidEventRosterMember180(event, name)
            if member and member.slotStatus == "ASSIGNED" then return PveC6ShortName180(name), member end
        end
    end
    return nil
end

function OTLGM:GetRaidEventAccess180(event, character)
    event = PveC6NormalizeEvent180(event)
    character = PveC6ShortName180(character or UnitName("player") or "")
    local result = {
        state = "NOT_IN_TEAM", character = character, canView = false, canSeen = false, canReady = false,
        canManage = false, canInvite = false, isParticipant = false, isTeamMember = false,
        visibility = event and event.visibility180 or "GUILD_VISIBLE",
    }
    if not event then result.state = "MISSING" return result end
    local eventStatus = PveC6EventStatus180(event)
    result.eventStatus = eventStatus
    result.canManage = self:IsRaidEventManager180(event, character)
    result.canInvite = self:IsRaidInviteManager180(event, character)
    local member = self:GetRaidEventRosterMember180(event, character)
    result.member = member
    local team = event.teamId180 and self:GetRaidTeam180(event.teamId180) or nil
    local teamMember = team and self:GetRaidTeamMembership180(team, character) or nil
    result.isTeamMember = teamMember and true or false
    result.team = team

    if eventStatus == "CANCELLED" then result.state = "CANCELLED"
    elseif eventStatus == "PAST" then result.state = "PAST"
    elseif eventStatus == "DRAFT" then result.state = "DRAFT"
    elseif member then
        result.isParticipant = true
        if member.slotStatus == "RESERVE" then result.state = "RESERVE"
        elseif member.slotStatus == "GUEST" then result.state = "GUEST"
        else result.state = "ASSIGNED" end
    elseif result.isTeamMember then result.state = "TEAM_NOT_ASSIGNED"
    elseif event.visibility180 == "OPEN_GUILD" then result.state = "OPEN_GUILD"
    elseif result.canManage then result.state = "LEADERSHIP_NOT_PARTICIPANT"
    else
        local altName, altMember = self:GetRaidEventLocalAlt180(event, character)
        if altName then result.state = "ALT_ASSIGNED" result.altName = altName result.altMember = altMember end
    end

    if event.visibility180 == "OPEN_GUILD" or event.visibility180 == "GUILD_VISIBLE" then result.canView = true
    elseif event.visibility180 == "PRIVATE_TEAM" then
        result.canView = result.isParticipant or result.isTeamMember or result.canManage or result.canInvite
    end
    if eventStatus ~= "UPCOMING" then result.canSeen = false result.canReady = false
    elseif result.state == "ASSIGNED" then result.canSeen = true result.canReady = true end
    return result
end

function OTLGM:GetRaidEventParticipantStatus180(event, character)
    if type(event) ~= "table" then return { seen = false, ready = false, eventRev = 0 } end
    local key = PveStageCCharacterKey180(character or UnitName("player") or "")
    local status = type(event.participantStatus180) == "table" and event.participantStatus180[key] or nil
    if type(status) ~= "table" then return { seen = false, ready = false, eventRev = tonumber(event.rev) or 0 } end
    local currentRev = tonumber(event.rev) or 0
    return {
        character = status.character or character,
        seen = status.seen == true,
        ready = status.ready == true and (tonumber(status.readyRev180) or 1) == (tonumber(event.participantStatusRevision180) or 1),
        eventRev = tonumber(status.eventRev) or 0,
        readyRev180 = tonumber(status.readyRev180) or 1,
        ts = tonumber(status.ts) or 0,
    }
end

function OTLGM:SetRaidParticipantStatus180(eventId, action)
    local event = PveC6NormalizeEvent180(self:GetRaidEvent180(eventId))
    if not event then return false, "Raid event not found." end
    local player = PveC6ShortName180(UnitName("player") or "")
    local access = self:GetRaidEventAccess180(event, player)
    if not access.canSeen then return false, "Only an assigned character can update Seen or Ready for this raid." end
    local current = self:GetRaidEventParticipantStatus180(event, player)
    local seen, ready = current.seen, current.ready
    action = string.upper(tostring(action or "SEEN"))
    if action == "SEEN" then seen = true
    elseif action == "READY" then seen = true ready = not ready
    elseif action == "NOT_READY" then ready = false
    else return false, "Unknown participant status action." end
    local key = PveStageCCharacterKey180(player)
    local row = { character = player, seen = seen, ready = ready, ts = self:Now(), eventRev = tonumber(event.rev) or 0, readyRev180 = tonumber(event.participantStatusRevision180) or 1 }
    event.participantStatus180[key] = row
    local payload = self:SerializeRaidParticipantStatus180(event.id, event.rev, player, seen, ready, row.ts, row.readyRev180)
    if payload then self:QueuePvePayload(payload, "GUILD", nil, "raid-status:" .. tostring(event.id) .. ":" .. key) end
    self:OnPveDataChanged("RAIDS", false)
    return true, row
end

function OTLGM:IsRaidEventNotificationEligible180(event, access)
    event = PveC6NormalizeEvent180(event)
    access = access or self:GetRaidEventAccess180(event)
    if not event or not access or not access.canView then return false end
    local audience = event.notifyAudience180
    if audience == "ALL_GUILD" then return true end
    if audience == "ENTIRE_TEAM" then return access.isTeamMember or access.isParticipant end
    if audience == "ASSIGNED_RESERVES" then return access.state == "ASSIGNED" or access.state == "RESERVE" end
    return access.state == "ASSIGNED"
end

function OTLGM:ShowRaidEventNotice180(event, title, body, noticeKey, remote)
    event = PveC6NormalizeEvent180(event)
    if not event then return false end
    local access = self:GetRaidEventAccess180(event)
    if not self:IsRaidEventNotificationEligible180(event, access) then return false end
    local key = "raid-notice:" .. tostring(event.id or "") .. ":" .. tostring(event.rev or 0)
        .. ":" .. tostring(noticeKey or "update")
    if self.IncrementPveUnread then self:IncrementPveUnread("RAIDS") end
    if self.NotifyEvent152 then
        return self:NotifyEvent152("raid", key, title or (event.name or "Guild Raid"), body or "", "ACTION", remote ~= false, "pve", {
            objectType = "RAID_EVENT", objectId = event.id, section = "EVENTS", actionKey = "ASSIGNED_UPDATE",
        })
    end
    if self.AddObjectInboxNotification180 then
        return self:AddObjectInboxNotification180("raid", key, title or (event.name or "Guild Raid"), body or "", "ACTION",
            "RAID_EVENT", event.id, "EVENTS", "ASSIGNED_UPDATE", "pve")
    end
    return false
end

local function PveC6AccessBucket180(self)
    local account = self:GetPveAccountState180()
    local characterKey = self:GetPveCharacterProfileKey180()
    account.raidAccessSeen180 = type(account.raidAccessSeen180) == "table" and account.raidAccessSeen180 or {}
    local bucket = account.raidAccessSeen180[characterKey]
    if type(bucket) ~= "table" then bucket = {} account.raidAccessSeen180[characterKey] = bucket end
    PvePruneOldestMap180(account.raidAccessSeen180, 20)
    return bucket
end

local function PveC6NotificationText180(event, previous, access)
    local currentState = access.state
    if previous and previous.state and previous.state ~= currentState then
        if previous.state == "RESERVE" and currentState == "ASSIGNED" then
            return "Moved to Assigned", "You are now assigned to " .. tostring(event.name or "this raid") .. ".", "ASSIGNED_UPDATE"
        elseif previous.state == "ASSIGNED" and not access.isParticipant then
            return "Removed from Raid Roster", "Your character is no longer assigned to " .. tostring(event.name or "this raid") .. ".", "ASSIGNED_UPDATE"
        end
    end
    if previous and tonumber(previous.startTs) and tonumber(previous.startTs) ~= tonumber(event.startTs) then
        return "Raid Time Updated", tostring(event.name or "Raid") .. " is now scheduled for " .. tostring(OTLGM.GetPveRaidServerTime155 and OTLGM:GetPveRaidServerTime155(event) or event.serverTime or "a new time") .. ".", "ASSIGNED_UPDATE"
    end
    if previous and previous.status ~= "CANCELLED" and PveC6EventStatus180(event) == "CANCELLED" then
        return "Raid Cancelled", tostring(event.name or "Raid") .. " has been cancelled.", "ASSIGNED_UPDATE"
    end
    if previous and (tonumber(previous.inviteRevision) or 0) < (tonumber(event.inviteRevision) or 0) and event.invitesOpen then
        return "Raid Invites Started", tostring(event.name or "Raid") .. " is collecting invites now.", "RAID_INVITE_START"
    end
    if not previous then
        if currentState == "ASSIGNED" then return "Assigned to Raid", "You are assigned to " .. tostring(event.name or "this raid") .. ".", "ASSIGNED_UPDATE"
        elseif currentState == "RESERVE" then return "Raid Reserve", "You are listed as a reserve for " .. tostring(event.name or "this raid") .. ".", "ASSIGNED_UPDATE"
        elseif currentState == "GUEST" then return "Added to Raid", "You are listed as a guest for " .. tostring(event.name or "this raid") .. ".", "ASSIGNED_UPDATE" end
    end
    return nil
end

function OTLGM:EvaluateRaidEventAccess180(eventId, remote)
    local event = PveC6NormalizeEvent180(self:GetRaidEvent180(eventId))
    if not event then return false end
    local player = PveC6ShortName180(UnitName("player") or "")
    local access = self:GetRaidEventAccess180(event, player)
    local bucket = PveC6AccessBucket180(self)
    local previous = bucket[event.id]
    local title, body, actionKey = PveC6NotificationText180(event, previous, access)
    local eligible = self:IsRaidEventNotificationEligible180(event, access)
    local actionEnabled = actionKey ~= "RAID_INVITE_START" and OTLGM_DB.settings.c7AssignedRaidUpdates180 ~= false
        or actionKey == "RAID_INVITE_START" and OTLGM_DB.settings.c7RaidInviteStart180 ~= false
    local changed = not previous or previous.state ~= access.state or tonumber(previous.rev) ~= tonumber(event.rev)
        or tonumber(previous.startTs) ~= tonumber(event.startTs) or previous.status ~= PveC6EventStatus180(event)
        or tonumber(previous.inviteRevision) ~= tonumber(event.inviteRevision)
    if remote and changed and title and actionEnabled and (eligible or title == "Removed from Raid Roster" or title == "Raid Cancelled") then
        local eventKey = "raid-access:" .. tostring(event.id) .. ":" .. tostring(event.rev or 0) .. ":" .. tostring(access.state)
            .. ":" .. tostring(event.inviteRevision or 0) .. ":" .. string.lower(string.gsub(title, "%s+", "-"))
        local recent = self:Now() - (tonumber(event.ts) or 0) <= 180
        if recent and self.NotifyEvent152 then
            self:NotifyEvent152("raid", eventKey, title, body, "ACTION", true, "pve", {
                objectType = "RAID_EVENT", objectId = event.id, section = "EVENTS", actionKey = actionKey or "ASSIGNED_UPDATE",
            })
        elseif self.AddObjectInboxNotification180 then
            self:AddObjectInboxNotification180("raid", eventKey, title, body, "ACTION", "RAID_EVENT", event.id, "EVENTS", actionKey or "ASSIGNED_UPDATE", "pve")
        end
    end
    bucket[event.id] = {
        ts = self:Now(), rev = tonumber(event.rev) or 0, state = access.state,
        startTs = tonumber(event.startTs) or 0, status = PveC6EventStatus180(event),
        inviteRevision = tonumber(event.inviteRevision) or 0,
    }
    PvePruneOldestMap180(bucket, PVE_C6_ACCESS_PER_CHARACTER_LIMIT180)
    return true, access
end

function OTLGM:ScheduleRaidEventAccessEvaluation180(eventId, remote)
    if not eventId or eventId == "" then return false end
    if self.ScheduleAfter180 then
        return self:ScheduleAfter180("raid-access:" .. tostring(eventId), 0.25, function()
            OTLGM:EvaluateRaidEventAccess180(eventId, remote and true or false)
        end, "NORMAL")
    end
    return self:EvaluateRaidEventAccess180(eventId, remote)
end

function OTLGM:ApplyRaidEventTargetingAfterPublish180(event, data, oldStartTs)
    if not event then return false, "Raid event not found." end
    data = type(data) == "table" and data or {}
    local before = table.concat({ tostring(event.visibility180 or ""), tostring(event.notifyAudience180 or ""),
        tostring(event.discordUrl180 or ""), tostring(event.signUpNote180 or "") }, "|")
    event.visibility180 = PveStageCStatus180(data.visibility180,
        { PRIVATE_TEAM = true, GUILD_VISIBLE = true, OPEN_GUILD = true }, event.visibility180 or "GUILD_VISIBLE")
    event.notifyAudience180 = PveStageCStatus180(data.notifyAudience180,
        { ASSIGNED = true, ASSIGNED_RESERVES = true, ENTIRE_TEAM = true, ALL_GUILD = true }, event.notifyAudience180 or "ASSIGNED")
    event.discordUrl180 = PveSafeUrl180(data.discordUrl180 or event.discordUrl180 or "", 96)
    event.signUpNote180 = PveSafeText(data.signUpNote180 or event.signUpNote180 or "", 120)
    event.eventMetaRev180 = tonumber(event.rev) or 0
    event.participantStatus180 = type(event.participantStatus180) == "table" and event.participantStatus180 or {}
    event.participantStatusRevision180 = math.max(1, tonumber(event.participantStatusRevision180) or 1)
    if oldStartTs and tonumber(oldStartTs) ~= tonumber(event.startTs) then
        event.participantStatusRevision180 = event.participantStatusRevision180 + 1
        local key, status
        for key, status in pairs(event.participantStatus180) do
            if type(status) == "table" then status.ready = false status.readyRev180 = event.participantStatusRevision180 end
        end
    end
    local after = table.concat({ event.visibility180, event.notifyAudience180, event.discordUrl180, event.signUpNote180 }, "|")
    if before ~= after then event.ts = self:Now() end
    self:QueuePvePayload(self:SerializePveRaid(event), "GUILD", nil, "raid-core:" .. tostring(event.id))
    if self.QueueRaidMeta157 then self:QueueRaidMeta157(event) end
    self:QueueRaidEventSnapshot180(event, "GUILD")
    self:EvaluateRaidEventAccess180(event.id, false)
    return true, event
end

local function PveC6CurrentGroupNames180()
    local names = {}
    local count = GetNumRaidMembers and tonumber(GetNumRaidMembers()) or 0
    local index, name
    if count and count > 0 and GetRaidRosterInfo then
        for index = 1, count do name = GetRaidRosterInfo(index) if name then names[PveNormalizeName(name)] = true end end
    else
        local partyCount = GetNumPartyMembers and tonumber(GetNumPartyMembers()) or 0
        names[PveNormalizeName(UnitName("player") or "")] = true
        for index = 1, partyCount do name = UnitName("party" .. tostring(index)) if name then names[PveNormalizeName(name)] = true end end
    end
    return names
end

function OTLGM:GetRaidInviteSession180(eventId)
    local event = PveC6NormalizeEvent180(self:GetRaidEvent180(eventId))
    if not event then return nil end
    self.runtime = self.runtime or {}
    self.runtime.raidInviteSession180 = type(self.runtime.raidInviteSession180) == "table" and self.runtime.raidInviteSession180 or {}
    local session = self.runtime.raidInviteSession180[eventId]
    if type(session) ~= "table" or tonumber(session.eventRev) ~= tonumber(event.rev) then
        session = { eventRev = tonumber(event.rev) or 0, members = {}, ts = self:Now() }
        self.runtime.raidInviteSession180[eventId] = session
    end
    session.members = type(session.members) == "table" and session.members or {}
    return session
end

function OTLGM:RefreshRaidInviteLiveState180(eventId, broadcast)
    local event = PveC6NormalizeEvent180(self:GetRaidEvent180(eventId))
    if not event then return false end
    local session = self:GetRaidInviteSession180(eventId)
    local joined = PveC6CurrentGroupNames180()
    local key, member, guildMember, previous, state
    local canBroadcast = broadcast and self:IsRaidInviteManager180(event)
    for key, member in pairs(event.roster180 or {}) do
        key = PveStageCCharacterKey180(member.character or key)
        previous = session.members[key]
        guildMember = self:GetMember(member.character)
        if joined[key] then state = "JOINED"
        elseif guildMember and guildMember.online == false then state = "OFFLINE"
        elseif previous and previous.state == "INVITED" then state = "INVITED"
        else state = "WAITING" end
        if not previous or previous.state ~= state then
            session.members[key] = { character = member.character, state = state, actor = UnitName("player") or "", ts = self:Now() }
            if canBroadcast and previous and previous.state ~= state and (state == "JOINED" or previous.state == "INVITED") then
                local payload = self:SerializeRaidInviteState180(event.id, event.rev, member.character, state, UnitName("player") or "", self:Now(), event.inviteRevision)
                if payload then self:QueuePvePayload(payload, "GUILD", nil, "raid-invite:" .. tostring(event.id) .. ":" .. key) end
            end
        end
    end
    local storedKey
    for storedKey in pairs(session.members) do if not event.roster180[storedKey] and not self:GetRaidEventRosterMember180(event, storedKey) then session.members[storedKey] = nil end end
    session.ts = self:Now()
    PvePruneOldestMap180(session.members, PVE_C6_INVITE_SESSION_MEMBER_LIMIT180)
    return true, session
end

function OTLGM:GetRaidInviteState180(event, member)
    if not event or not member then return "WAITING" end
    local session = self:GetRaidInviteSession180(event.id)
    local key = PveStageCCharacterKey180(member.character)
    local row = session and session.members and session.members[key]
    return PveStageCStatus180(row and row.state, PVE_C6_INVITE_STATE180, "WAITING")
end

function OTLGM:SetRaidInviteState180(eventId, character, state, sendNetwork)
    local event = PveC6NormalizeEvent180(self:GetRaidEvent180(eventId))
    if not event then return false, "Raid event not found." end
    if not self:IsRaidInviteManager180(event) then return false, "Only the Raid Leader or Invite Team can update invite state." end
    local member = self:GetRaidEventRosterMember180(event, character)
    if not member then return false, "The character is not in this event roster." end
    state = PveStageCStatus180(state, PVE_C6_INVITE_STATE180, "WAITING")
    local session = self:GetRaidInviteSession180(eventId)
    local key = PveStageCCharacterKey180(member.character)
    session.members[key] = { character = member.character, state = state, actor = UnitName("player") or "", ts = self:Now() }
    session.ts = self:Now()
    if sendNetwork ~= false then
        local payload = self:SerializeRaidInviteState180(event.id, event.rev, member.character, state, UnitName("player") or "", self:Now(), event.inviteRevision)
        if payload then self:QueuePvePayload(payload, "GUILD", nil, "raid-invite:" .. tostring(event.id) .. ":" .. key) end
    end
    self:OnPveDataChanged("RAIDS", false)
    return true, session.members[key]
end

function OTLGM:InviteRaidParticipant180(eventId, character)
    local event = PveC6NormalizeEvent180(self:GetRaidEvent180(eventId))
    if not event then return false, "Raid event not found." end
    if not self:IsRaidInviteManager180(event) then return false, "Only the Raid Leader or Invite Team can invite participants." end
    local member = self:GetRaidEventRosterMember180(event, character)
    if not member or member.slotStatus ~= "ASSIGNED" then return false, "Only assigned participants can be invited from Invite Mode." end
    self:RefreshRaidInviteLiveState180(eventId, false)
    local state = self:GetRaidInviteState180(event, member)
    if state == "JOINED" then return false, "This character is already in the group." end
    if state == "OFFLINE" then return false, "This character is offline." end
    if state == "INVITED" then return false, "An invite has already been sent." end
    local name = PveC6ShortName180(member.character)
    local called, inviteError
    if InviteByName then called, inviteError = pcall(InviteByName, name)
    elseif InviteUnit then called, inviteError = pcall(InviteUnit, name)
    else return false, "This client does not expose a group invite function." end
    if not called then return false, "The client rejected the invite action: " .. tostring(inviteError or "unknown error") end
    local stateOk, stateError = self:SetRaidInviteState180(eventId, member.character, "INVITED", true)
    if not stateOk then return false, stateError or "Invite state could not be recorded." end
    return true, member
end

function OTLGM:InviteNextRaidParticipant180(eventId)
    local event = PveC6NormalizeEvent180(self:GetRaidEvent180(eventId))
    if not event then return false, "Raid event not found." end
    if not self:IsRaidInviteManager180(event) then return false, "Only the Raid Leader or Invite Team can invite participants." end
    self:RefreshRaidInviteLiveState180(eventId, false)
    local rows = {}
    local _, member
    for _, member in pairs(event.roster180 or {}) do
        if member.slotStatus == "ASSIGNED" and self:GetRaidInviteState180(event, member) == "WAITING" then table.insert(rows, member) end
    end
    table.sort(rows, function(left, right)
        local lr = PVE_C6_ROLE_ORDER180[PveNormalizeMainRole180(left)] or 9
        local rr = PVE_C6_ROLE_ORDER180[PveNormalizeMainRole180(right)] or 9
        if lr ~= rr then return lr < rr end
        return PveNormalizeName(left.character) < PveNormalizeName(right.character)
    end)
    if table.getn(rows) == 0 then return false, "No online waiting participant is available." end
    return self:InviteRaidParticipant180(eventId, rows[1].character)
end

function OTLGM:StartRaidInviteCollection180(eventId)
    local event = PveC6NormalizeEvent180(self:GetRaidEvent180(eventId))
    if not event or PveC6EventStatus180(event) ~= "UPCOMING" then return false, "Upcoming raid event not found." end
    if not self:IsRaidInviteManager180(event) then return false, "Only the Raid Leader or Invite Team can start Invite Mode." end
    local now = self:Now()
    if event.invitesOpen and now - (tonumber(event.inviteTs) or 0) < 60 then return false, "Invite collection was started less than one minute ago." end
    event.invitesOpen = true
    event.inviteRevision = (tonumber(event.inviteRevision) or 0) + 1
    event.inviteTs = now
    self:GetRaidInviteSession180(event.id)
    self:RefreshRaidInviteLiveState180(event.id, false)
    local payload = self:SerializeRaidInviteState180(event.id, event.rev, "*", "OPEN", UnitName("player") or "", now, event.inviteRevision)
    if payload then self:QueuePvePayload(payload, "GUILD", nil, "raid-invite-open:" .. tostring(event.id)) end
    self:EvaluateRaidEventAccess180(event.id, false)
    self:OnPveDataChanged("RAIDS", false)
    return true, event
end

function OTLGM:MoveRaidEventMember180(eventId, character, slotStatus)
    local event = PveC6NormalizeEvent180(self:GetRaidEvent180(eventId))
    if not event then return false, "Raid event not found." end
    if not self:IsRaidEventManager180(event) then return false, "Only the Raid Leader or Leadership can edit this event roster." end
    local member = self:GetRaidEventRosterMember180(event, character)
    if not member then return false, "The character is not in this event roster." end
    slotStatus = PveStageCStatus180(slotStatus, { ASSIGNED = true, RESERVE = true, GUEST = true }, member.slotStatus or "ASSIGNED")
    if member.slotStatus == slotStatus then return false, "The participant already has this roster status." end
    member.slotStatus = slotStatus
    event.rev = (tonumber(event.rev) or 0) + 1 event.ts = self:Now() event.eventMetaRev180 = event.rev
    local key = PveStageCCharacterKey180(member.character)
    event.participantStatus180[key] = { character = member.character, seen = false, ready = false, ts = self:Now(), eventRev = event.rev, readyRev180 = tonumber(event.participantStatusRevision180) or 1 }
    self.runtime.raidInviteSession180[eventId] = nil
    self:QueuePvePayload(self:SerializePveRaid(event), "GUILD", nil, "raid-core:" .. tostring(event.id))
    if self.QueueRaidMeta157 then self:QueueRaidMeta157(event) end
    self:QueueRaidEventSnapshot180(event, "GUILD")
    self:OnPveDataChanged("RAIDS", false)
    return true, event
end

function OTLGM:SetRaidEventMemberRole180(eventId, character, role)
    local event = PveC6NormalizeEvent180(self:GetRaidEvent180(eventId))
    if not event then return false, "Raid event not found." end
    if not self:IsRaidEventManager180(event) then return false, "Only the Raid Leader or Leadership can edit this event roster." end
    local member = self:GetRaidEventRosterMember180(event, character)
    if not member then return false, "The character is not in this event roster." end
    role = PveStageCStatus180(role, { TANK = true, HEALER = true, DAMAGE = true, UNASSIGNED = true }, "UNASSIGNED")
    member.mainRole = role member.role = role == "UNASSIGNED" and "FLEXIBLE" or role member.roleNeedsReview180 = role == "UNASSIGNED" and true or nil
    if member.offspecRole == role then member.offspecRole = nil end
    event.rev = (tonumber(event.rev) or 0) + 1 event.ts = self:Now() event.eventMetaRev180 = event.rev
    self.runtime.raidInviteSession180[eventId] = nil
    self:QueuePvePayload(self:SerializePveRaid(event), "GUILD", nil, "raid-core:" .. tostring(event.id))
    if self.QueueRaidMeta157 then self:QueueRaidMeta157(event) end
    self:QueueRaidEventSnapshot180(event, "GUILD")
    self:OnPveDataChanged("RAIDS", false)
    return true, event
end

function OTLGM:RemoveRaidEventMember180(eventId, character)
    local event = PveC6NormalizeEvent180(self:GetRaidEvent180(eventId))
    if not event then return false, "Raid event not found." end
    if not self:IsRaidEventManager180(event) then return false, "Only the Raid Leader or Leadership can edit this event roster." end
    local member, key = self:GetRaidEventRosterMember180(event, character)
    if not member then return false, "The character is not in this event roster." end
    event.roster180[key] = nil
    event.participantStatus180[key] = nil
    event.rev = (tonumber(event.rev) or 0) + 1 event.ts = self:Now() event.eventMetaRev180 = event.rev
    self.runtime.raidInviteSession180[eventId] = nil
    self:QueuePvePayload(self:SerializePveRaid(event), "GUILD", nil, "raid-core:" .. tostring(event.id))
    if self.QueueRaidMeta157 then self:QueueRaidMeta157(event) end
    self:QueueRaidEventSnapshot180(event, "GUILD")
    self:QueuePvePayload(self:SerializeRaidRosterDelete180(event.id, event.rev, member.character), "GUILD")
    self:OnPveDataChanged("RAIDS", false)
    return true, event
end

function OTLGM:GetRaidOrganizerRows180(event, mode)
    event = PveC6NormalizeEvent180(event)
    local rows, groups = {}, { ASSIGNED = {}, RESERVE = {}, GUEST = {} }
    if not event then return rows end
    self:RefreshRaidInviteLiveState180(event.id, false)
    local addonMap = {}
    if self.GetDetectedAddonUserList then
        local addonUsers = self:GetDetectedAddonUserList(7 * 86400) or {}
        local index, info
        for index = 1, table.getn(addonUsers) do addonMap[PveNormalizeName(addonUsers[index].name)] = addonUsers[index] end
    end
    local _, member
    for _, member in pairs(event.roster180 or {}) do
        local slot = PveStageCStatus180(member.slotStatus, { ASSIGNED = true, RESERVE = true, GUEST = true }, "ASSIGNED")
        if mode ~= "INVITES" or slot == "ASSIGNED" or slot == "RESERVE" then
            local guildMember = self:GetMember(member.character)
            local addon = addonMap[PveNormalizeName(member.character)]
            local status = self:GetRaidEventParticipantStatus180(event, member.character)
            local inviteState = self:GetRaidInviteState180(event, member)
            local row = {
                character = member.character, class = member.class, level = guildMember and guildMember.level or nil,
                mainRole = PveNormalizeMainRole180(member), slotStatus = slot, seen = status.seen, ready = status.ready,
                online = guildMember and guildMember.online == true or false, inviteState = inviteState,
                addonStatus = addon and (addon.version and addon.version ~= "Detected" and self.IsVersionNewer and self:IsVersionNewer(self.version, addon.version) and "Outdated" or "Online") or "Not detected",
                member = member,
            }
            table.insert(groups[slot], row)
        end
    end
    local order = mode == "INVITES" and { "ASSIGNED", "RESERVE" } or { "ASSIGNED", "RESERVE", "GUEST" }
    local index, slot, list
    for index = 1, table.getn(order) do
        slot = order[index] list = groups[slot]
        table.sort(list, function(left, right)
            if left.online ~= right.online then return left.online end
            local lr, rr = PVE_C6_ROLE_ORDER180[left.mainRole] or 9, PVE_C6_ROLE_ORDER180[right.mainRole] or 9
            if lr ~= rr then return lr < rr end
            return PveNormalizeName(left.character) < PveNormalizeName(right.character)
        end)
        if table.getn(list) > 0 then
            table.insert(rows, { header = true, slotStatus = slot, label = slot == "ASSIGNED" and "Assigned" or (slot == "RESERVE" and "Reserves" or "Guests"), count = table.getn(list) })
            local rowIndex
            for rowIndex = 1, table.getn(list) do table.insert(rows, list[rowIndex]) end
        end
    end
    return rows
end

function OTLGM:GetRaidEventGuildLeader180()
    -- User-facing Guild Leader identity is canonical for this guild.  Do not
    -- let stale rankIndex/rank-label snapshots redirect whispers to somebody
    -- other than the configured guild leader.
    if self.GetCanonicalGuildLeaderName180 then
        local name = PveC6ShortName180(self:GetCanonicalGuildLeaderName180() or "")
        if name ~= "" then return name end
    end
    return nil
end

function OTLGM:GetRaidEventContactTarget180(event)
    if not event then return nil end
    local player = PveNormalizeName(UnitName("player") or "")
    local targets = { event.raidLeader, event.inviteContact, event.author }
    local index, target
    for index = 1, table.getn(targets) do
        target = PveC6ShortName180(targets[index])
        if target ~= "" and PveNormalizeName(target) ~= player then return target end
    end
    return nil
end

function OTLGM:GetRaidEventSummaryText180(event)
    if not event then return "" end
    local text = tostring(event.name or "Guild Raid") .. " — " .. tostring(self.GetPveRaidServerTime155 and self:GetPveRaidServerTime155(event) or event.serverTime or "Time TBA")
    if event.location and event.location ~= "" then text = text .. " — " .. tostring(event.location) end
    local contact = self:GetRaidEventContactTarget180(event) or PveC6ShortName180(event.raidLeader or event.author)
    if contact and contact ~= "" then text = text .. ". Contact: " .. contact end
    if event.discordUrl180 and event.discordUrl180 ~= "" then text = text .. ". Discord: " .. event.discordUrl180 end
    if event.signUpNote180 and event.signUpNote180 ~= "" then text = text .. ". " .. event.signUpNote180 end
    return text
end

function OTLGM:RefreshActiveRaidInviteSessions180(broadcast)
    local sessions = self.runtime and self.runtime.raidInviteSession180
    if type(sessions) ~= "table" then return false end
    local eventId
    for eventId in pairs(sessions) do
        local event = self:GetRaidEvent180(eventId)
        if event and event.invitesOpen then self:RefreshRaidInviteLiveState180(eventId, broadcast and self:IsRaidInviteManager180(event))
        else sessions[eventId] = nil end
    end
    if self.ui and self.ui.raidC6Manager180 and self.ui.raidC6Manager180:IsVisible() and self.RefreshRaidPlanner156 then self:RefreshRaidPlanner156() end
    return true
end

function OTLGM:EvaluateAllRaidAccess180(remote)
    local pve = self:EnsurePveDB()
    local eventId, seen = nil, {}
    for eventId in pairs(pve and pve.raids or {}) do
        seen[eventId] = true
        self:EvaluateRaidEventAccess180(eventId, remote and true or false)
    end
    for eventId in pairs(pve and pve.cancelledRaids156 or {}) do
        if not seen[eventId] then self:EvaluateRaidEventAccess180(eventId, remote and true or false) end
    end
    return true
end

-- World entry used to evaluate every retained and cancelled raid in one callback
-- two seconds after loading began. Keep the public synchronous helper above for
-- explicit callers, but route automatic world recovery through a bounded queue.
function OTLGM:ScheduleAllRaidAccessEvaluation180(remote, delay)
    local pve = self:EnsurePveDB()
    self.runtime = self.runtime or {}
    self.runtime.raidAccessAllGeneration181 = (tonumber(self.runtime.raidAccessAllGeneration181) or 0) + 1
    local generation = self.runtime.raidAccessAllGeneration181
    local ids, seen = {}, {}
    local eventId
    for eventId in pairs(pve and pve.raids or {}) do
        if not seen[eventId] then seen[eventId] = true table.insert(ids, eventId) end
    end
    for eventId in pairs(pve and pve.cancelledRaids156 or {}) do
        if not seen[eventId] then seen[eventId] = true table.insert(ids, eventId) end
    end
    if table.getn(ids) == 0 then
        self.runtime.raidAccessAllState181 = nil
        if self.CancelTask180 then self:CancelTask180("raid-access-all-181") end
        return false
    end

    local state = {
        generation = generation, ids = ids, index = 1,
        remote = remote and true or false, startedAt = self:Now(), pressureDeferrals = 0,
    }
    self.runtime.raidAccessAllState181 = state
    local function Slice181(owner)
        local current = owner and owner.runtime and owner.runtime.raidAccessAllState181
        if not current or tonumber(current.generation) ~= generation then return end
        local pressure = owner.GetClientPressure181 and owner:GetClientPressure181() or nil
        local level = pressure and tonumber(pressure.level) or 0
        local age = owner:Now() - (tonumber(current.startedAt) or owner:Now())
        if ((owner.runtime and owner.runtime.transitionActive176) or level >= 3) and age < 30 then
            current.pressureDeferrals = (tonumber(current.pressureDeferrals) or 0) + 1
            owner:ScheduleAfter180("raid-access-all-181", 2, Slice181, 12)
            return
        end
        local maximum = level >= 2 and 1 or PVE_C6_ACCESS_EVAL_PER_SLICE180
        local processed = 0
        while current.index <= table.getn(current.ids) and processed < maximum do
            local id = current.ids[current.index]
            current.index = current.index + 1
            processed = processed + 1
            pcall(owner.EvaluateRaidEventAccess180, owner, id, current.remote)
        end
        owner.runtime.raidAccessEvaluationSlices181 = (tonumber(owner.runtime.raidAccessEvaluationSlices181) or 0) + 1
        if current.index <= table.getn(current.ids) then
            owner:ScheduleAfter180("raid-access-all-181", level >= 2 and 0.25 or 0.06, Slice181, 12)
        else
            owner.runtime.raidAccessAllState181 = nil
            owner.runtime.lastRaidAccessEvaluationCount181 = table.getn(current.ids)
            owner.runtime.lastRaidAccessEvaluationAt181 = owner:Now()
        end
    end

    if self.ScheduleAfter180 then
        self:ScheduleAfter180("raid-access-all-181", math.max(0, tonumber(delay) or 0), Slice181, 12)
        return true
    end
    self.runtime.raidAccessAllState181 = nil
    return self:EvaluateAllRaidAccess180(remote)
end
