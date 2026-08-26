-- Order of the Lion Guild Manager 1.8.3
-- Lightweight social profile sharing, honest achievement ranking and My Goals.
-- This module is event-driven: it creates no event frame, timer or OnUpdate.

if not OTLGM or not OTLGM.UI then return end

local UI = OTLGM.UI
local C = UI.colors
local MIN_SOCIAL_VERSION_183 = "1.8.3-rc2"
local MIN_TARGETED_SOCIAL_VERSION_R27 = "1.8.3-rc4-r27"
local MIN_ACHIEVEMENT_DETAIL_VERSION_R42 = "1.8.3-rc4-r42"
local MIN_ACHIEVEMENT_TIME_VERSION_R45 = "1.8.3-rc4-r45"
local MAX_PROFILE_RECORDS_183 = 900
local MAX_GOALS_183 = 3
local MAX_ABOUT_BYTES_183 = 160
local PROFILE_PEER_COOLDOWN_183 = 300

-- r48 profile identity deliberately reuses the existing ABOUT/profile-content
-- packet instead of creating a second background stream.  The only shared
-- values are a curated earned title key and up to three achievement IDs.
local MIN_PROFILE_IDENTITY_VERSION_R48 = "1.8.3-rc4-r48"
local MAX_SHOWCASE_R48 = 3
local PROFILE_TITLES_R48 = {
    { key="NONE", label="No title" },
    { key="MASTER_CRAFTER", label="Master Crafter", achievement="A039" },
    { key="VETERAN_DELVER", label="Veteran Delver", achievement="A050" },
    { key="RAID_VETERAN", label="Raid Veteran", achievement="A064" },
    { key="SECRET_KEEPER", label="Secret Keeper", achievement="A090" },
    { key="OLD_GUARD", label="Old Guard", achievement="A087" },
    { key="YEAR_UNDER_LION", label="Year Under the Lion", achievement="A094" },
    { key="PILLAR", label="Pillar of the Order", achievement="A095" },
    { key="CHRONICLE", label="Living Chronicle", achievement="A096" },
}
local PROFILE_TITLE_BY_KEY_R48 = {}
local profileTitleIndexR48
for profileTitleIndexR48 = 1, table.getn(PROFILE_TITLES_R48) do
    PROFILE_TITLE_BY_KEY_R48[PROFILE_TITLES_R48[profileTitleIndexR48].key] = PROFILE_TITLES_R48[profileTitleIndexR48]
end

local function Normalize183(owner, name)
    if owner.NormalizeName then return owner:NormalizeName(name or "") end
    name = string.gsub(tostring(name or ""), "%-.*$", "")
    return string.lower(name)
end

local function ShortName183(name)
    return string.gsub(tostring(name or ""), "%-.*$", "")
end

local function Short183(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or 60
    if string.len(value) <= maximum then return value end
    return string.sub(value, 1, math.max(1, maximum - 3)) .. "..."
end

local function PlayerName183()
    return ShortName183(UnitName and UnitName("player") or "")
end

local function IsSelf183(owner, name)
    local player = Normalize183(owner, PlayerName183())
    return player ~= "" and player == Normalize183(owner, name)
end

local function MarkSocialRevision183(owner, reason)
    owner.runtime = owner.runtime or {}
    owner.runtime.socialProfileRevision183 = (tonumber(owner.runtime.socialProfileRevision183) or 0) + 1
    owner.runtime.socialProfileLastReason183 = tostring(reason or "change")
    owner.runtime.achievementRankingCache183 = nil
end

local function CountRecords183(store)
    local count, key, record = 0, nil, nil
    for key, record in pairs(store or {}) do
        if type(key) == "string" and string.sub(key, 1, 2) ~= "__" and type(record) == "table" then count = count + 1 end
    end
    return count
end

local function PruneProfileStore183(owner, store)
    local count = CountRecords183(store)
    if count <= MAX_PROFILE_RECORDS_183 then return 0 end
    local candidates = {}
    local key, record
    for key, record in pairs(store) do
        if type(key) == "string" and string.sub(key, 1, 2) ~= "__" and type(record) == "table" then
            table.insert(candidates, {
                key = key,
                roster = owner.GetMember and owner:GetMember(record.name or key) and true or false,
                updatedAt = tonumber(record.updatedAt) or 0,
            })
        end
    end
    table.sort(candidates, function(left, right)
        if left.roster ~= right.roster then return not left.roster end
        if left.updatedAt ~= right.updatedAt then return left.updatedAt < right.updatedAt end
        return tostring(left.key) < tostring(right.key)
    end)
    local removed, index = 0, 1
    while count > MAX_PROFILE_RECORDS_183 and index <= table.getn(candidates) do
        store[candidates[index].key] = nil
        count = count - 1
        removed = removed + 1
        index = index + 1
    end
    return removed
end

function OTLGM:EnsureGuildProfiles183()
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    if not db then return nil end
    if type(db.guildProfiles183) ~= "table" then db.guildProfiles183 = {} end
    return db.guildProfiles183
end

local function EnsureRecord183(owner, name)
    local store = owner:EnsureGuildProfiles183()
    local key = Normalize183(owner, name)
    if not store or key == "" then return nil, nil, nil end
    local record = store[key]
    if type(record) ~= "table" then record = {} store[key] = record end
    record.name = ShortName183(name)
    return record, key, store
end

local function BuildLocalAchievementSummary183(owner)
    local db = owner.EnsureAchievements174 and owner:EnsureAchievements174() or nil
    local byId = owner.achievements174 and owner.achievements174.byId or {}
    local catalog = owner.achievements174 and owner.achievements174.catalog or {}
    local completed, recent = 0, {}
    local id, value
    for id, value in pairs(db and db.completed or {}) do
        if byId[id] then
            completed = completed + 1
            table.insert(recent, {
                id = id,
                name = tostring(byId[id].name or id),
                ts = type(value) == "table" and tonumber(value.unlockedAt) or tonumber(value),
            })
        end
    end
    table.sort(recent, function(left, right)
        local leftTime, rightTime = tonumber(left.ts) or 0, tonumber(right.ts) or 0
        if leftTime ~= rightTime then return leftTime > rightTime end
        return tostring(left.id or "") < tostring(right.id or "")
    end)
    while table.getn(recent) > 3 do table.remove(recent) end
    return completed, table.getn(catalog), recent
end

function OTLGM:EnsureSelfGuildProfile183(refreshAchievements)
    local player = PlayerName183()
    if player == "" then return nil end
    local record, key, store = EnsureRecord183(self, player)
    if not record then return nil end
    local total = table.getn(self.achievements174 and self.achievements174.catalog or {})
    local current = type(record.achievements) == "table" and record.achievements or nil
    if refreshAchievements or not current or tonumber(current.total) ~= total then
        local completed, knownTotal, recent = BuildLocalAchievementSummary183(self)
        local revision = math.max(0, tonumber(current and current.revision) or 0) + 1
        record.achievements = {
            revision = revision,
            completed = completed,
            total = math.max(1, knownTotal),
            recent = recent,
            updatedAt = self:Now(),
        }
        record.updatedAt = math.max(tonumber(record.updatedAt) or 0, record.achievements.updatedAt)
        MarkSocialRevision183(self, refreshAchievements and "local-achievement" or "local-profile")
    end
    local removed = PruneProfileStore183(self, store)
    if removed > 0 then
        self.runtime = self.runtime or {}
        self.runtime.socialProfilesPruned183 = (tonumber(self.runtime.socialProfilesPruned183) or 0) + removed
    end
    return record, key
end

local function RecentWire183(recent)
    local fields = {}
    local index, entry, id, timestamp
    for index = 1, math.min(3, table.getn(recent or {})) do
        entry = recent[index]
        id = tostring(entry and entry.id or "")
        timestamp = math.max(0, math.floor(tonumber(entry and entry.ts) or 0))
        if string.find(id, "^[A-Za-z0-9_%-]+$") and string.len(id) <= 16 then
            table.insert(fields, id .. "@" .. tostring(timestamp))
        end
    end
    return string.sub(table.concat(fields, ","), 1, 120)
end

local function ParseRecentWire183(owner, value)
    local result = {}
    local tokens = owner.Split and owner:Split(tostring(value or ""), ",") or {}
    local index, token
    for index = 1, table.getn(tokens) do
        token = tokens[index]
        local _, _, id, timestamp = string.find(token, "^([A-Za-z0-9_%-]+)@(%d+)$")
        local definition = id and owner.achievements174 and owner.achievements174.byId and owner.achievements174.byId[id] or nil
        if definition and table.getn(result) < 3 then
            table.insert(result, { id = id, name = tostring(definition.name or id), ts = tonumber(timestamp) })
        end
    end
    return result
end

function OTLGM:SanitizeGuildProfileAbout183(value)
    value = self.SafeText and self:SafeText(value or "", MAX_ABOUT_BYTES_183, false, false) or tostring(value or "")
    value = string.gsub(value, "%^", "/")
    return self.Utf8Truncate and self:Utf8Truncate(value, MAX_ABOUT_BYTES_183) or string.sub(value, 1, MAX_ABOUT_BYTES_183)
end

local function LocalAchievementCompletedR48(owner, id)
    if not id or id == "" then return false end
    local db = owner.EnsureAchievements174 and owner:EnsureAchievements174() or nil
    return db and type(db.completed) == "table" and db.completed[id] and true or false
end

function OTLGM:GetGuildProfileTitleOptionsR48()
    local result, index, definition = {}, nil, nil
    for index = 1, table.getn(PROFILE_TITLES_R48) do
        definition = PROFILE_TITLES_R48[index]
        if not definition.achievement or LocalAchievementCompletedR48(self, definition.achievement) then
            table.insert(result, { key=definition.key, label=definition.label, achievement=definition.achievement })
        end
    end
    return result
end

function OTLGM:SanitizeGuildProfileTitleR48(value, requireEarned)
    local key = string.upper(tostring(value or "NONE"))
    local definition = PROFILE_TITLE_BY_KEY_R48[key]
    if not definition then return "NONE" end
    if requireEarned and definition.achievement and not LocalAchievementCompletedR48(self, definition.achievement) then return "NONE" end
    return definition.key
end

function OTLGM:GetGuildProfileTitleLabelR48(value, requireEarned)
    local key = self:SanitizeGuildProfileTitleR48(value, requireEarned)
    local definition = PROFILE_TITLE_BY_KEY_R48[key]
    return definition and definition.label or "No title", key
end

function OTLGM:CycleGuildProfileTitleR48(current)
    local options = self:GetGuildProfileTitleOptionsR48()
    if table.getn(options) < 1 then return "NONE", "No title" end
    local currentKey = self:SanitizeGuildProfileTitleR48(current, true)
    local index
    for index = 1, table.getn(options) do
        if options[index].key == currentKey then
            local nextIndex = index + 1
            if nextIndex > table.getn(options) then nextIndex = 1 end
            return options[nextIndex].key, options[nextIndex].label
        end
    end
    return options[1].key, options[1].label
end

local function NormalizeShowcaseR48(owner, value, requireEarned)
    local raw = {}
    if type(value) == "table" then
        local index
        for index = 1, table.getn(value) do raw[index] = value[index] end
    else
        local wire = tostring(value or "")
        if wire ~= "" and wire ~= "-" then raw = owner.Split and owner:Split(wire, ",") or {} end
    end
    local result, seen, index, id = {}, {}, nil, nil
    for index = 1, table.getn(raw) do
        id = tostring(raw[index] or "")
        if string.find(id, "^[A-Za-z0-9_%-]+$") and string.len(id) <= 16
            and not seen[id] and owner.achievements174 and owner.achievements174.byId and owner.achievements174.byId[id]
            and (not requireEarned or LocalAchievementCompletedR48(owner, id)) then
            seen[id] = true
            table.insert(result, id)
            if table.getn(result) >= MAX_SHOWCASE_R48 then break end
        end
    end
    return result
end

function OTLGM:GetGuildProfileShowcaseWireR48(value, requireEarned)
    local ids = NormalizeShowcaseR48(self, value, requireEarned)
    return table.getn(ids) > 0 and table.concat(ids, ",") or "-", ids
end

function OTLGM:GetGuildProfileIdentityR48(name, detailOverrideR49)
    local record = self.GetGuildProfileRecord183 and self:GetGuildProfileRecord183(name) or nil
    if not record and IsSelf183(self, name) then record = self:EnsureSelfGuildProfile183(false) end
    if type(record) ~= "table" then return { titleKey="NONE", titleLabel=nil, showcase={} } end
    local selfProfile = IsSelf183(self, name)
    local titleKey = self:SanitizeGuildProfileTitleR48(record.profileTitleR48 or "NONE", selfProfile)
    local titleDefinition = PROFILE_TITLE_BY_KEY_R48[titleKey]
    local ids = NormalizeShowcaseR48(self, record.showcaseR48, selfProfile)
    local detail = detailOverrideR49 or (not selfProfile and self.GetGuildAchievementDetailsR42 and self:GetGuildAchievementDetailsR42(name) or nil)
    if titleDefinition and titleDefinition.achievement and detail and type(detail.completedMap) == "table"
        and not detail.completedMap[titleDefinition.achievement] then
        titleKey = "NONE"
        titleDefinition = PROFILE_TITLE_BY_KEY_R48.NONE
    end
    local result, index, id, definition = {}, nil, nil, nil
    for index = 1, table.getn(ids) do
        id = ids[index]
        definition = self.achievements174 and self.achievements174.byId and self.achievements174.byId[id] or nil
        -- If exact remote achievement data is already available, never display
        -- a showcase claim that contradicts that verified map.  Older peers
        -- simply keep the lightweight claimed selection until exact data exists.
        if definition and (not detail or type(detail.completedMap) ~= "table" or detail.completedMap[id]) then
            table.insert(result, { id=id, name=tostring(definition.name or id), icon=definition.icon, secret=definition.secret and true or false })
        end
    end
    return {
        titleKey = titleKey,
        titleLabel = titleDefinition and titleDefinition.key ~= "NONE" and titleDefinition.label or nil,
        showcase = result,
        supported = record.profileIdentityR48 and true or selfProfile,
        updatedAt = tonumber(record.profileIdentityUpdatedAtR48) or tonumber(record.aboutUpdatedAt) or tonumber(record.updatedAt),
    }
end

local function CommitProfileContentR48(owner, record, reason)
    if not record then return false end
    local now = owner:Now()
    record.aboutRevision = math.max(0, tonumber(record.aboutRevision) or 0) + 1
    record.aboutUpdatedAt = now
    record.profileIdentityUpdatedAtR48 = now
    record.profileIdentityR48 = true
    record.updatedAt = math.max(tonumber(record.updatedAt) or 0, now)
    MarkSocialRevision183(owner, reason or "profile-customization")
    owner:QueueGuildProfileAbout183("GUILD", nil, reason or "profile-customization")
    local profile = owner.ui and owner.ui.guildProfile183
    if profile and profile:IsVisible() and IsSelf183(owner, profile.otlMemberName183) then owner:RefreshGuildProfile183(reason or "profile-customization") end
    return true
end

function OTLGM:IsAchievementShowcasedR48(id)
    local record = self:EnsureSelfGuildProfile183(false)
    local ids = NormalizeShowcaseR48(self, record and record.showcaseR48 or nil, true)
    local index
    for index = 1, table.getn(ids) do if ids[index] == id then return true end end
    return false
end

function OTLGM:ToggleAchievementShowcaseR48(id)
    id = tostring(id or "")
    local definition = self.achievements174 and self.achievements174.byId and self.achievements174.byId[id] or nil
    if not definition then return false, "unknown" end
    if not self:IsAchievementComplete174(id) then
        if self.ShowToast then self:ShowToast("Only completed achievements can be added to your Profile Showcase.", "pending", 5) end
        return false, "incomplete"
    end
    local record = self:EnsureSelfGuildProfile183(false)
    if not record then return false, "profile" end
    local ids = NormalizeShowcaseR48(self, record.showcaseR48, true)
    local index
    for index = 1, table.getn(ids) do
        if ids[index] == id then
            table.remove(ids, index)
            record.showcaseR48 = ids
            CommitProfileContentR48(self, record, "showcase-remove")
            if self.RefreshAchievementTrackingButtons183 then self:RefreshAchievementTrackingButtons183() end
            if self.ShowToast then self:ShowToast("Achievement removed from Profile Showcase.", "success") end
            return true, "removed"
        end
    end
    if table.getn(ids) >= MAX_SHOWCASE_R48 then
        if self.ShowToast then self:ShowToast("Profile Showcase can contain up to 3 achievements. Remove one first.", "pending", 6) end
        return false, "limit"
    end
    table.insert(ids, id)
    record.showcaseR48 = ids
    CommitProfileContentR48(self, record, "showcase-add")
    if self.RefreshAchievementTrackingButtons183 then self:RefreshAchievementTrackingButtons183() end
    if self.ShowToast then self:ShowToast("Achievement added to Profile Showcase.", "success") end
    return true, "added"
end

local ACH_HEX_R42 = "0123456789ABCDEF"

local function AchievementCatalogRevisionR42(owner)
    return math.max(1, tonumber(owner.achievements174 and owner.achievements174.catalogRevision) or 1)
end

local function BuildAchievementBitmapR42(owner)
    local catalog = owner.achievements174 and owner.achievements174.catalog or {}
    local db = owner.EnsureAchievements174 and owner:EnsureAchievements174() or nil
    local completedMap = db and db.completed or {}
    local chars, completed = {}, 0
    local index = 1
    while index <= table.getn(catalog) do
        local nibble, bit = 0, 0
        while bit < 4 and index + bit <= table.getn(catalog) do
            local def = catalog[index + bit]
            if def and completedMap[def.id] then nibble = nibble + (2 ^ bit) completed = completed + 1 end
            bit = bit + 1
        end
        table.insert(chars, string.sub(ACH_HEX_R42, nibble + 1, nibble + 1))
        index = index + 4
    end
    return table.concat(chars), completed, table.getn(catalog)
end

local function DecodeAchievementBitmapR42(owner, bitmap, total)
    local catalog = owner.achievements174 and owner.achievements174.catalog or {}
    total = math.min(table.getn(catalog), math.max(0, tonumber(total) or 0))
    bitmap = tostring(bitmap or "")
    local expectedLength = math.ceil(total / 4)
    if total < 1 or string.len(bitmap) ~= expectedLength then return nil, 0 end
    local map, count, index = {}, 0, 1
    local charIndex
    for charIndex = 1, string.len(tostring(bitmap or "")) do
        local ch = string.upper(string.sub(bitmap, charIndex, charIndex))
        local pos = string.find(ACH_HEX_R42, ch, 1, true)
        if not pos then return nil, 0 end
        local value = pos - 1
        local bit
        for bit = 0, 3 do
            if index > total then break end
            if math.mod(math.floor(value / (2 ^ bit)), 2) == 1 then
                local def = catalog[index]
                if def then map[def.id] = true count = count + 1 end
            end
            index = index + 1
        end
        if index > total then break end
    end
    if index <= total then return nil, 0 end
    return map, count
end

local ACH_TIME_BASE36_R45 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

local function ToBase36R45(value)
    value = math.max(0, math.floor(tonumber(value) or 0))
    if value == 0 then return "0" end
    local result = ""
    while value > 0 do
        local digit = math.mod(value, 36)
        result = string.sub(ACH_TIME_BASE36_R45, digit + 1, digit + 1) .. result
        value = math.floor(value / 36)
    end
    return result
end

local function FromBase36R45(value)
    value = string.upper(tostring(value or ""))
    if value == "" or string.len(value) > 8 then return nil end
    local result, index = 0, nil
    for index = 1, string.len(value) do
        local ch = string.sub(value, index, index)
        local pos = string.find(ACH_TIME_BASE36_R45, ch, 1, true)
        if not pos then return nil end
        result = (result * 36) + (pos - 1)
    end
    return result
end

local function BuildAchievementTimeEntriesR45(owner)
    local catalog = owner.achievements174 and owner.achievements174.catalog or {}
    local db = owner.EnsureAchievements174 and owner:EnsureAchievements174() or nil
    local completedMap = db and db.completed or {}
    local entries, index, def, value, timestamp = {}, nil, nil, nil, nil
    for index = 1, table.getn(catalog) do
        def = catalog[index]
        value = def and completedMap[def.id] or nil
        timestamp = type(value) == "table" and tonumber(value.unlockedAt) or tonumber(value)
        if timestamp and timestamp > 0 then
            table.insert(entries, ToBase36R45(index) .. "." .. ToBase36R45(timestamp))
        end
    end
    return entries
end

local function DecodeAchievementTimesR45(owner, wire)
    local catalog = owner.achievements174 and owner.achievements174.catalog or {}
    local map, count = {}, 0
    local entries = owner.Split and owner:Split(tostring(wire or ""), ",") or {}
    local i, token, _, _, indexWire, timeWire, catalogIndex, timestamp, def
    for i = 1, table.getn(entries) do
        token = entries[i]
        _, _, indexWire, timeWire = string.find(token or "", "^([0-9A-Z]+)%.([0-9A-Z]+)$")
        catalogIndex, timestamp = FromBase36R45(indexWire), FromBase36R45(timeWire)
        def = catalogIndex and catalog[catalogIndex] or nil
        if not def or not timestamp or timestamp <= 0 then return nil, 0 end
        if not map[def.id] then map[def.id] = timestamp count = count + 1 end
    end
    return map, count
end

function OTLGM:IsDetailedAchievementPeerR42(version)
    version = tostring(version or "")
    if version == "" or version == "Detected" then return false end
    if self.IsVersionNewer then return not self:IsVersionNewer(MIN_ACHIEVEMENT_DETAIL_VERSION_R42, version) end
    return string.find(version, "^1%.8%.3%-rc4%-r4[2-9]") ~= nil
end

function OTLGM:IsAchievementTimestampPeerR45(version)
    version = tostring(version or "")
    if version == "" or version == "Detected" then return false end
    if self.IsVersionNewer then return not self:IsVersionNewer(MIN_ACHIEVEMENT_TIME_VERSION_R45, version) end
    return string.find(version, "^1%.8%.3%-rc4%-r4[5-9]") ~= nil
end

function OTLGM:QueueGuildAchievementDetailRequestR42(target, reason)
    if not target or target == "" or not self.QueueNetworkPayload then return false end
    local version = self.GetDetectedAddonVersion183 and self:GetDetectedAddonVersion183(target) or nil
    if not self:IsDetailedAchievementPeerR42(version) then return false end
    self.runtime = self.runtime or {}
    self.runtime.achievementDetailRequestAtR42 = self.runtime.achievementDetailRequestAtR42 or {}
    local key = Normalize183(self, target)
    local now = self:Now()
    if now - (tonumber(self.runtime.achievementDetailRequestAtR42[key]) or 0) < 5 then return true end
    self.runtime.achievementDetailRequestAtR42[key] = now
    local requestFields = {"F1","ACHREQ",tostring(now),tostring(AchievementCatalogRevisionR42(self))}
    if self:IsAchievementTimestampPeerR45(version) then table.insert(requestFields, "TS1") end
    return self:QueueNetworkPayload(table.concat(requestFields, "^"), "WHISPER", target, 1,
        "social-achievement-detail", "social:achreq:" .. key) and true or false
end

function OTLGM:QueueGuildAchievementTimesR45(target, revision, catalogRevision, reason)
    if not target or target == "" or not self.QueueNetworkPayload then return false end
    local entries = BuildAchievementTimeEntriesR45(self)
    if table.getn(entries) < 1 then return true end
    local limit = self.GetNetworkPayloadLimit and tonumber(self:GetNetworkPayloadLimit("WHISPER", target)) or 220
    limit = math.max(96, math.min(240, limit))
    local chunks, current, index = {}, "", nil
    -- Reserve enough bytes for F1^ACHTS^revision^catalog^seq^total^timestamp^.
    local wireBudget = math.max(40, limit - 72)
    for index = 1, table.getn(entries) do
        local entry = entries[index]
        local candidate = current == "" and entry or (current .. "," .. entry)
        if current ~= "" and string.len(candidate) > wireBudget then
            table.insert(chunks, current)
            current = entry
        else
            current = candidate
        end
    end
    if current ~= "" then table.insert(chunks, current) end
    if table.getn(chunks) > 16 then return false end
    local sentAt = self:Now()
    local queuedAny = false
    for index = 1, table.getn(chunks) do
        local payload = table.concat({"F1","ACHTS",tostring(revision),tostring(catalogRevision),tostring(index),tostring(table.getn(chunks)),tostring(sentAt),chunks[index]}, "^")
        if string.len(payload) > limit then return false end
        if self:QueueNetworkPayload(payload, "WHISPER", target, 1, "social-achievement-times",
            "social:achts:" .. Normalize183(self, target) .. ":" .. tostring(revision) .. ":" .. tostring(index)) then
            queuedAny = true
        else
            return false
        end
    end
    self.runtime = self.runtime or {}
    self.runtime.achievementTimeChunksSentR45 = (tonumber(self.runtime.achievementTimeChunksSentR45) or 0) + table.getn(chunks)
    return queuedAny
end

function OTLGM:QueueGuildAchievementDetailR42(target, reason, includeTimesR45)
    if not target or target == "" or not self.QueueNetworkPayload then return false end
    self.runtime = self.runtime or {}
    self.runtime.achievementDetailReplyAtR42 = self.runtime.achievementDetailReplyAtR42 or {}
    local targetKey = Normalize183(self, target)
    local now = self:Now()
    -- A broken/newer peer must not be able to turn an on-demand profile feature
    -- into repeated full-map replies. One response per sender every five seconds
    -- is enough for manual refresh while keeping the feature non-background.
    if now - (tonumber(self.runtime.achievementDetailReplyAtR42[targetKey]) or 0) < 5 then return true end
    local bitmap, completed, total = BuildAchievementBitmapR42(self)
    if total < 1 or bitmap == "" then return false end
    local record = self:EnsureSelfGuildProfile183(false)
    local revision = math.max(1, tonumber(record and record.achievements and record.achievements.revision) or 1)
    local catalogRevision = AchievementCatalogRevisionR42(self)
    local payload = table.concat({"F1","ACHMAP",tostring(revision),tostring(catalogRevision),tostring(completed),tostring(total),tostring(now),bitmap}, "^")
    local queued = self:QueueNetworkPayload(payload, "WHISPER", target, 1, "social-achievement-detail",
        "social:achmap:" .. targetKey) and true or false
    if queued then
        self.runtime.achievementDetailReplyAtR42[targetKey] = now
        if includeTimesR45 then self:QueueGuildAchievementTimesR45(target, revision, catalogRevision, reason) end
    end
    return queued
end

function OTLGM:GetGuildAchievementDetailsR42(name)
    -- Account-local character history is already authoritative for characters
    -- that have been played with this SavedVariables file. This lets a player's
    -- own alts be inspected immediately without pretending a network round-trip
    -- is required. Remote guild members still use the sender-bound ACHMAP path.
    local guild = self.GetGuildDB and self:GetGuildDB() or nil
    local store = guild and guild.achievements174 and guild.achievements174.characters or nil
    if type(store) == "table" then
        local realm = GetCVar and (GetCVar("realmName") or "UnknownRealm") or "UnknownRealm"
        local localKey = Normalize183(self, name) .. "@" .. string.lower(tostring(realm))
        local character = store[localKey]
        if type(character) == "table" and type(character.completed) == "table" then
            local map, completedAtMap, count, id, value = {}, {}, 0, nil, nil
            for id, value in pairs(character.completed) do
                if self.achievements174 and self.achievements174.byId and self.achievements174.byId[id] then
                    map[id] = true count = count + 1
                    local unlockedAtR45 = type(value) == "table" and tonumber(value.unlockedAt) or tonumber(value)
                    if unlockedAtR45 and unlockedAtR45 > 0 then completedAtMap[id] = unlockedAtR45 end
                end
            end
            return { revision = tonumber(character.catalogRevision) or 1, completed = count,
                total = table.getn(self.achievements174 and self.achievements174.catalog or {}), updatedAt = 0,
                completedMap = map, completedAtMap = completedAtMap, localStoredR42 = true }
        end
    end
    local record = self.GetGuildProfileRecord183 and self:GetGuildProfileRecord183(name) or nil
    local detail = record and record.achievementDetailsR42 or nil
    if type(detail) ~= "table" then return nil end
    local currentCatalogRevision = AchievementCatalogRevisionR42(self)
    local currentTotal = table.getn(self.achievements174 and self.achievements174.catalog or {})
    if tonumber(detail.catalogRevision) ~= currentCatalogRevision or tonumber(detail.total) ~= currentTotal then return nil end
    -- Persist only the compact bitmap. Expanding 147 booleans for every viewed
    -- guild member would unnecessarily inflate SavedVariables; decode only for
    -- the active read-only browser.
    if detail.bitmap then
        local map, decodedCount = DecodeAchievementBitmapR42(self, detail.bitmap, detail.total)
        if not map or decodedCount ~= (tonumber(detail.completed) or -1) then return nil end
        local completedAtMapR45 = nil
        local timeDetailR45 = record and record.achievementTimesR45 or nil
        if type(timeDetailR45) == "table" and tonumber(timeDetailR45.revision) == tonumber(detail.revision)
            and tonumber(timeDetailR45.catalogRevision) == tonumber(detail.catalogRevision) and timeDetailR45.wire then
            local decodedTimesR45 = DecodeAchievementTimesR45(self, timeDetailR45.wire)
            if decodedTimesR45 then completedAtMapR45 = decodedTimesR45 end
        end
        return { revision = detail.revision, catalogRevision = detail.catalogRevision, completed = detail.completed,
            total = detail.total, updatedAt = detail.updatedAt, completedMap = map, completedAtMap = completedAtMapR45 }
    end
    -- Compatibility with a pre-checkpoint r42 development copy, if one happened
    -- to write expanded data before the final package was installed.
    if type(detail.completedMap) == "table" then return detail end
    return nil
end

function OTLGM:GetGuildAchievementDetailStatusR42(name)
    local record = self.GetGuildProfileRecord183 and self:GetGuildProfileRecord183(name) or nil
    local status = record and record.achievementDetailStatusR42 or nil
    if type(status) == "table" then return status end
    local detail = record and record.achievementDetailsR42 or nil
    if type(detail) == "table" then
        local currentCatalogRevision = AchievementCatalogRevisionR42(self)
        local currentTotal = table.getn(self.achievements174 and self.achievements174.catalog or {})
        if tonumber(detail.catalogRevision) ~= currentCatalogRevision or tonumber(detail.total) ~= currentTotal then
            return { incompatibleCatalogR42 = true, catalogRevision = detail.catalogRevision, total = detail.total, updatedAt = detail.updatedAt }
        end
    end
    return nil
end

function OTLGM:QueueGuildProfileSummary183(channel, target, reason)
    if not self.QueueNetworkPayload or not GetGuildInfo or not GetGuildInfo("player") then return false end
    local record = self:EnsureSelfGuildProfile183(false)
    local achievement = record and record.achievements
    if type(achievement) ~= "table" then return false end
    local fields = {
        "F1", "PROFILE", tostring(math.max(1, tonumber(achievement.revision) or 1)),
        tostring(math.max(0, tonumber(achievement.completed) or 0)),
        tostring(math.max(1, tonumber(achievement.total) or 1)),
        tostring(math.max(1, tonumber(achievement.updatedAt) or self:Now())),
        RecentWire183(achievement.recent),
    }
    -- r34 Main/Alt identity is a backward-compatible PROFILE extension. r33
    -- and older parsers consume fields 1..7 and ignore these trailing fields,
    -- so the feature adds no new background packet stream or protocol bump.
    local identityTailR34 = false
    if self.GetCharacterIdentityWire184 then
        local role, peers, identityRevision, identityUpdatedAt = self:GetCharacterIdentityWire184()
        if role then
            table.insert(fields, tostring(role))
            table.insert(fields, tostring(peers or ""))
            table.insert(fields, tostring(math.max(1, tonumber(identityRevision) or 1)))
            table.insert(fields, tostring(math.max(1, tonumber(identityUpdatedAt) or self:Now())))
            identityTailR34 = true
        end
    end
    local payload = table.concat(fields, "^")
    -- Identity is optional metadata. Never let its tail cause a targeted PROFILE
    -- rejection if a non-standard/long target envelope leaves less room.
    if identityTailR34 and channel == "WHISPER" and self.GetNetworkPayloadLimit then
        local targetLimitR34 = tonumber(self:GetNetworkPayloadLimit("WHISPER", target)) or 0
        if targetLimitR34 > 0 and string.len(payload) > targetLimitR34 then
            while table.getn(fields) > 7 do table.remove(fields) end
            payload = table.concat(fields, "^")
            self.runtime = self.runtime or {}
            self.runtime.identityProfileTailDeferredR34 = (tonumber(self.runtime.identityProfileTailDeferredR34) or 0) + 1
        end
    end
    local key = channel == "WHISPER" and ("social:profile:" .. Normalize183(self, target)) or "social:profile:guild"
    local queued = self:QueueNetworkPayload(payload, channel or "GUILD", target, 1, "social-profile", key)
    if queued then
        self.runtime = self.runtime or {}
        self.runtime.socialProfilePackets183 = (tonumber(self.runtime.socialProfilePackets183) or 0) + 1
        self.runtime.socialProfileLastSendReason183 = tostring(reason or "share")
    end
    return queued and true or false
end

function OTLGM:QueueGuildProfileAbout183(channel, target, reason)
    if not self.QueueNetworkPayload or not GetGuildInfo or not GetGuildInfo("player") then return false end
    local record = self:EnsureSelfGuildProfile183(false)
    local revision = tonumber(record and record.aboutRevision) or 0
    if revision < 1 then return false end
    channel = channel or "GUILD"
    local updatedAt = math.max(1, tonumber(record.aboutUpdatedAt) or self:Now())
    local about = self:SanitizeGuildProfileAbout183(record.about or "")
    local titleKey = self:SanitizeGuildProfileTitleR48(record.profileTitleR48 or "NONE", true)
    local showcaseWire, cleanShowcase = self:GetGuildProfileShowcaseWireR48(record.showcaseR48, true)
    record.profileTitleR48 = titleKey
    record.showcaseR48 = cleanShowcase
    local fields = { "F1", "ABOUT", tostring(revision), tostring(updatedAt), about, titleKey, showcaseWire }
    local payload = table.concat(fields, "^")
    local limit = self.GetNetworkPayloadLimit and tonumber(self:GetNetworkPayloadLimit(channel, target)) or 240
    limit = math.max(96, math.min(240, limit or 240))
    if string.len(payload) > limit then
        -- Keep the identity tail because it is tiny and changes rarely.  Trim
        -- only the transmitted About copy to the current transport envelope;
        -- the full local 160-byte text remains stored for future/larger peers.
        local fixed = table.concat({ "F1", "ABOUT", tostring(revision), tostring(updatedAt), "", titleKey, showcaseWire }, "^")
        local room = math.max(0, limit - string.len(fixed))
        about = self.Utf8Truncate and self:Utf8Truncate(about, room) or string.sub(about, 1, room)
        fields[5] = about
        payload = table.concat(fields, "^")
    end
    if string.len(payload) > limit then
        -- Extremely small/non-standard envelopes keep the legacy ABOUT packet
        -- rather than failing the whole profile refresh.
        fields = { "F1", "ABOUT", tostring(revision), tostring(updatedAt), "" }
        local fixed = table.concat(fields, "^")
        local room = math.max(0, limit - string.len(fixed))
        fields[5] = self.Utf8Truncate and self:Utf8Truncate(about, room) or string.sub(about, 1, room)
        payload = table.concat(fields, "^")
        self.runtime = self.runtime or {}
        self.runtime.profileIdentityTailDeferredR48 = (tonumber(self.runtime.profileIdentityTailDeferredR48) or 0) + 1
    end
    local key = channel == "WHISPER" and ("social:about:" .. Normalize183(self, target)) or "social:about:guild"
    local queued = self:QueueNetworkPayload(payload, channel, target, 1, "social-profile", key)
    if queued then
        self.runtime = self.runtime or {}
        self.runtime.socialAboutPackets183 = (tonumber(self.runtime.socialAboutPackets183) or 0) + 1
        self.runtime.socialAboutLastSendReason183 = tostring(reason or "share")
        self.runtime.profileIdentityPacketsR48 = (tonumber(self.runtime.profileIdentityPacketsR48) or 0) + (table.getn(fields) >= 7 and 1 or 0)
    end
    return queued and true or false
end

local function RefreshSocialViews183(owner, name, reason)
    local frame = owner.ui and owner.ui.guildProfile183
    if frame and frame:IsVisible() and Normalize183(owner, frame.otlMemberName183) == Normalize183(owner, name) then
        owner:RefreshGuildProfile183(reason or "social-update")
    end
    local drawer = owner.ui and owner.ui.achievementCommunityDrawer183
    if drawer and drawer:IsVisible() and owner.RefreshAchievementCommunityDrawer183 then
        owner:RefreshAchievementCommunityDrawer183()
    end
end

function OTLGM:HandleSocialProfileMessage183(fields, channel, sender)
    if type(fields) ~= "table" or fields[1] ~= "F1" then return false end
    if channel ~= "GUILD" and channel ~= "WHISPER" then return false end
    if not sender or sender == "" or IsSelf183(self, sender) then return true end
    if self.GetMember and not self:GetMember(sender) then return false end
    local kind = fields[2]
    local record, key, store = EnsureRecord183(self, sender)
    if not record then return false end
    local timestamp
    if kind == "PROFILE" then timestamp = tonumber(fields[6])
    elseif kind == "ACHMAP" or kind == "ACHTS" then timestamp = tonumber(fields[7])
    elseif kind == "ACHREQ" then timestamp = tonumber(fields[3])
    else timestamp = tonumber(fields[4]) end
    if not timestamp or timestamp <= 0 or timestamp > self:Now() + 604800 then return false end
    local changed = false
    if kind == "ACHREQ" then
        return self:QueueGuildAchievementDetailR42(sender, "request", fields[5] == "TS1")
    elseif kind == "ACHMAP" then
        local revision = tonumber(fields[3]) or 0
        local remoteCatalogRevision = tonumber(fields[4]) or 0
        local completed, total = tonumber(fields[5]) or -1, tonumber(fields[6]) or -1
        local localCatalogRevision = AchievementCatalogRevisionR42(self)
        local localTotal = table.getn(self.achievements174 and self.achievements174.catalog or {})
        -- The bitmap is intentionally compact and indexed by catalogue order.
        -- Never apply it across catalogue revisions/totals: a future inserted ID
        -- would otherwise make every following bit look like another achievement.
        if remoteCatalogRevision ~= localCatalogRevision or total ~= localTotal then
            record.achievementDetailStatusR42 = { incompatibleCatalogR42 = true, catalogRevision = remoteCatalogRevision,
                total = total, updatedAt = timestamp }
            record.achievementDetailsR42 = nil
            record.achievementTimesR45 = nil
            record.updatedAt = math.max(tonumber(record.updatedAt) or 0, timestamp)
            changed = true
        else
            local detailMap, decodedCount = DecodeAchievementBitmapR42(self, fields[8] or "", total)
            if not detailMap or decodedCount ~= completed then return false end
            local old = type(record.achievementDetailsR42) == "table" and record.achievementDetailsR42 or nil
            local oldRevision, oldTime = tonumber(old and old.revision) or 0, tonumber(old and old.updatedAt) or 0
            if revision > oldRevision or (revision == oldRevision and timestamp > oldTime) then
                record.achievementDetailsR42 = { revision = revision, catalogRevision = remoteCatalogRevision, completed = completed, total = total,
                    updatedAt = timestamp, bitmap = tostring(fields[8] or "") }
                if type(record.achievementTimesR45) == "table" and tonumber(record.achievementTimesR45.revision) ~= revision then record.achievementTimesR45 = nil end
                record.achievementDetailStatusR42 = nil
                record.updatedAt = math.max(tonumber(record.updatedAt) or 0, timestamp)
                changed = true
            end
        end
    elseif kind == "ACHTS" then
        if channel ~= "WHISPER" then return false end
        local revision = tonumber(fields[3]) or 0
        local remoteCatalogRevision = tonumber(fields[4]) or 0
        local sequence, total = tonumber(fields[5]) or 0, tonumber(fields[6]) or 0
        local wire = tostring(fields[8] or "")
        local localCatalogRevision = AchievementCatalogRevisionR42(self)
        if revision < 1 or remoteCatalogRevision ~= localCatalogRevision or sequence < 1 or total < 1 or sequence > total or total > 16 or string.len(wire) > 190 then return false end
        self.runtime = self.runtime or {}
        self.runtime.achievementTimeAssembliesR45 = self.runtime.achievementTimeAssembliesR45 or {}
        local nowR45, assemblyKeyR45, keyR45, assemblyR45 = self:Now(), nil, nil, nil
        for keyR45, assemblyR45 in pairs(self.runtime.achievementTimeAssembliesR45) do
            if nowR45 - (tonumber(assemblyR45.createdAt) or 0) > 20 then self.runtime.achievementTimeAssembliesR45[keyR45] = nil end
        end
        assemblyKeyR45 = Normalize183(self, sender) .. ":" .. tostring(revision) .. ":" .. tostring(remoteCatalogRevision) .. ":" .. tostring(timestamp)
        assemblyR45 = self.runtime.achievementTimeAssembliesR45[assemblyKeyR45]
        if not assemblyR45 then
            assemblyR45 = { revision=revision, catalogRevision=remoteCatalogRevision, total=total, chunks={}, createdAt=nowR45, timestamp=timestamp }
            self.runtime.achievementTimeAssembliesR45[assemblyKeyR45] = assemblyR45
        end
        if assemblyR45.total ~= total then return false end
        assemblyR45.chunks[sequence] = wire
        local receivedR45, iR45 = 0, nil
        for iR45 = 1, total do if assemblyR45.chunks[iR45] ~= nil then receivedR45 = receivedR45 + 1 end end
        if receivedR45 < total then return true end
        local combinedR45 = ""
        for iR45 = 1, total do combinedR45 = combinedR45 .. (combinedR45 ~= "" and "," or "") .. tostring(assemblyR45.chunks[iR45] or "") end
        local decodedR45 = DecodeAchievementTimesR45(self, combinedR45)
        self.runtime.achievementTimeAssembliesR45[assemblyKeyR45] = nil
        if not decodedR45 then return false end
        record.achievementTimesR45 = { revision=revision, catalogRevision=remoteCatalogRevision, updatedAt=timestamp, wire=combinedR45 }
        self.runtime.achievementTimeChunksReceivedR45 = (tonumber(self.runtime.achievementTimeChunksReceivedR45) or 0) + total
        changed = true
    elseif kind == "PROFILE" then
        local revision = tonumber(fields[3]) or 0
        local completed, total = tonumber(fields[4]) or -1, tonumber(fields[5]) or -1
        local old = type(record.achievements) == "table" and record.achievements or nil
        local oldRevision, oldTime = tonumber(old and old.revision) or 0, tonumber(old and old.updatedAt) or 0
        if revision >= 1 and completed >= 0 and total >= 1 and completed <= total and total <= 500
            and (revision > oldRevision or (revision == oldRevision and timestamp > oldTime)) then
            record.achievements = {
                revision = revision, completed = completed, total = total,
                updatedAt = timestamp, recent = ParseRecentWire183(self, fields[7] or ""),
            }
            changed = true
        end
        -- Optional r34 trailing identity fields are sender-bound by the normal
        -- PROFILE handler. A malformed/older extension never invalidates the
        -- already-valid achievement summary above.
        if self.HandleCharacterIdentityProfileFields184 and fields[8] then
            if self:HandleCharacterIdentityProfileFields184(sender, fields, record) then changed = true end
        end
    elseif kind == "ABOUT" then
        local revision = tonumber(fields[3]) or 0
        local oldRevision, oldTime = tonumber(record.aboutRevision) or 0, tonumber(record.aboutUpdatedAt) or 0
        local about = self:SanitizeGuildProfileAbout183(fields[5] or "")
        if revision >= 1 and (revision > oldRevision or (revision == oldRevision and timestamp > oldTime)) then
            record.about = about
            record.aboutRevision = revision
            record.aboutUpdatedAt = timestamp
            -- r48 appends only compact cosmetic identity data to the existing
            -- ABOUT revision.  Pre-r48 senders omit the tail, so their normal
            -- About refresh never destroys a previously stored r48 selection.
            if fields[6] then
                record.profileTitleR48 = self:SanitizeGuildProfileTitleR48(fields[6], false)
                local showcaseWireR48 = tostring(fields[7] or "-")
                local _, showcaseIdsR48 = self:GetGuildProfileShowcaseWireR48(showcaseWireR48, false)
                record.showcaseR48 = showcaseIdsR48
                record.profileIdentityR48 = true
                record.profileIdentityUpdatedAtR48 = timestamp
                self.runtime = self.runtime or {}
                self.runtime.profileIdentityReceivedR48 = (tonumber(self.runtime.profileIdentityReceivedR48) or 0) + 1
            end
            changed = true
        end
    else
        return false
    end
    if changed then
        record.name = (self.GetMember and self:GetMember(sender) and self:GetMember(sender).name) or ShortName183(sender)
        record.updatedAt = math.max(tonumber(record.updatedAt) or 0, timestamp)
        MarkSocialRevision183(self, "remote-" .. string.lower(kind))
        local removed = PruneProfileStore183(self, store)
        if removed > 0 then self.runtime.socialProfilesPruned183 = (tonumber(self.runtime.socialProfilesPruned183) or 0) + removed end
        RefreshSocialViews183(self, record.name, "network-" .. string.lower(kind))
        local detailModalR42 = self.ui and self.ui.memberAchievementBrowserR42 or nil
        if (kind == "ACHMAP" or kind == "ACHTS") and detailModalR42 and detailModalR42:IsVisible()
            and Normalize183(self, detailModalR42.otlMemberNameR42) == Normalize183(self, record.name)
            and self.RefreshGuildMemberAchievementBrowserR42 then
            self:RefreshGuildMemberAchievementBrowserR42()
        end
    end
    return true
end

local PreviousReleaseMessage183 = OTLGM.HandleRelease175Message
function OTLGM:HandleRelease175Message(message, channel, sender)
    local fields = self:Split(message or "", "^")
    if fields[1] == "F1" and fields[2] == "REQ" then
        return self:HandleGuildProfileRequestR27(channel, sender, fields[3])
    elseif fields[1] == "F1" and (fields[2] == "PROFILE" or fields[2] == "ABOUT" or fields[2] == "ACHREQ" or fields[2] == "ACHMAP" or fields[2] == "ACHTS") then
        return self:HandleSocialProfileMessage183(fields, channel, sender)
    end
    return PreviousReleaseMessage183 and PreviousReleaseMessage183(self, message, channel, sender) or false
end

function OTLGM:IsSocialProfilePeer183(version)
    version = tostring(version or "")
    if version == "" or version == "Detected" then return false end
    if self.IsVersionNewer then return not self:IsVersionNewer(MIN_SOCIAL_VERSION_183, version) end
    return string.find(version, "^1%.8%.3") ~= nil
end

function OTLGM:IsTargetedSocialProfilePeerR27(version)
    version = tostring(version or "")
    if version == "" or version == "Detected" then return false end
    if self.IsVersionNewer then return not self:IsVersionNewer(MIN_TARGETED_SOCIAL_VERSION_R27, version) end
    return string.find(version, "^1%.8%.3%-rc4%-r2[7-9]") ~= nil
end

-- r32 capability registry. New shared features should register one minimum peer
-- version here and use GetFeatureCompatibilityMessageR32 before attempting a
-- peer-dependent action. This keeps old clients readable instead of producing
-- vague "sync error" states when a future packet/structure is unavailable.
local FEATURE_CAPABILITIES_R32 = {
    PROFILE_ACHIEVEMENTS = { label = "Shared achievements", minVersion = "1.8.3-rc2",
        hint = "They need a compatible Order of the Lion addon and must allow their achievement summary to be shared. Newer compatible clients can also answer a direct refresh request." },
    PROFILE_PROFESSIONS = { label = "Shared professions", minVersion = "1.8.0",
        hint = "They need a compatible addon and must open the profession window from the spellbook at least once so recipes can be learned locally." },
    PROFILE_ACHIEVEMENT_DETAILS = { label = "Detailed achievement list", minVersion = "1.8.3-rc4-r42",
        hint = "A newer compatible client can answer an on-demand request with exact per-achievement status. Older clients still expose their summary and recent achievements." },
    PROFILE_ACHIEVEMENT_DATES = { label = "Achievement completion dates", minVersion = "1.8.3-rc4-r45",
        hint = "Newer compatible clients can additionally share completion dates when the achievement browser is opened. Full achievement history is not broadcast in the background." },
    PROFILE_IDENTITY = { label = "Profile showcase and title", minVersion = "1.8.3-rc4-r48",
        hint = "Newer compatible clients can share an earned profile title and up to three showcased achievements. Older clients safely keep the basic profile." },
    REPORT_EDIT = { label = "Report editing", minVersion = "1.8.3-rc4-r30",
        hint = "Editing/withdrawing a submitted report requires another compatible Leadership client to acknowledge the change." },
}

function OTLGM:RegisterFeatureCapabilityR32(key, label, minVersion, hint)
    key = string.upper(tostring(key or ""))
    if key == "" then return false end
    FEATURE_CAPABILITIES_R32[key] = { label = tostring(label or key), minVersion = tostring(minVersion or self.version or "1.8.3"), hint = tostring(hint or "") }
    return true
end

function OTLGM:GetFeatureCompatibilityR32(name, key)
    key = string.upper(tostring(key or ""))
    local capability = FEATURE_CAPABILITIES_R32[key]
    if not capability then return true, "SUPPORTED", nil, nil end
    local version = self.GetDetectedAddonVersion183 and self:GetDetectedAddonVersion183(name) or nil
    if not version or version == "" or version == "Detected" then
        return false, "NOT_DETECTED", version, capability
    end
    local supported
    if self.IsVersionNewer then supported = not self:IsVersionNewer(capability.minVersion, version)
    else supported = tostring(version) == tostring(capability.minVersion) end
    if supported then return true, "SUPPORTED", version, capability end
    return false, "OUTDATED", version, capability
end

function OTLGM:GetFeatureCompatibilityMessageR32(name, key, onlyWhenBlocked)
    local ok, state, version, capability = self:GetFeatureCompatibilityR32(name, key)
    if ok then return onlyWhenBlocked and nil or ((capability and capability.label or tostring(key)) .. " is supported by " .. tostring(name or "this player") .. ".") end
    local who = tostring(name or "This player")
    local label = capability and capability.label or tostring(key or "This feature")
    local minimum = capability and capability.minVersion or "a newer addon version"
    local hint = capability and capability.hint or ""
    if state == "NOT_DETECTED" then
        return label .. " unavailable for " .. who .. ": a compatible addon was not detected. Requires " .. tostring(minimum) .. "." .. (hint ~= "" and (" " .. hint) or "")
    end
    return label .. " unavailable for " .. who .. ": detected " .. tostring(version or "unknown") .. ", requires " .. tostring(minimum) .. " or newer." .. (hint ~= "" and (" " .. hint) or "")
end

function OTLGM:RequirePeerFeatureR32(name, key, quiet)
    local ok = self:GetFeatureCompatibilityR32(name, key)
    if ok then return true end
    local message = self:GetFeatureCompatibilityMessageR32(name, key, false)
    if not quiet and self.ShowToast then self:ShowToast(message, "error", 7) end
    return false, message
end

function OTLGM:GetFeatureCapabilityDiagnosticsR32()
    local keys, key = {}, nil
    for key in pairs(FEATURE_CAPABILITIES_R32) do table.insert(keys, key) end
    table.sort(keys)
    local lines, index, capability = {}, nil, nil
    for index = 1, table.getn(keys) do
        key = keys[index]
        capability = FEATURE_CAPABILITIES_R32[key]
        table.insert(lines, tostring(key) .. "=" .. tostring(capability and capability.minVersion or "?") .. " (" .. tostring(capability and capability.label or key) .. ")")
    end
    return table.concat(lines, "; ")
end

-- Keep the authoritative Full Support Report as the single deep diagnostic
-- export, but append the feature capability contract so future version-specific
-- failures can be interpreted without guessing which packet generation was expected.
local PreviousSupportReportR32 = OTLGM.GetSupportReport181
if PreviousSupportReportR32 then
    function OTLGM:GetSupportReport181()
        local report = tostring(PreviousSupportReportR32(self) or "")
        local capabilityBlock = "--- FEATURE COMPATIBILITY REGISTRY ---\n"
            .. tostring(self:GetFeatureCapabilityDiagnosticsR32())
            .. "\n=== END FEATURE COMPATIBILITY REGISTRY ===\n"
        local marker = "=== END SUPPORT REPORT ==="
        local markerAt = string.find(report, marker, 1, true)
        if markerAt then
            return string.sub(report, 1, markerAt - 1) .. capabilityBlock .. marker
        end
        return report .. "\n\n" .. capabilityBlock
    end
end

function OTLGM:GetDetectedAddonVersion183(name)
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local normalized = Normalize183(self, name)
    local storedName, info
    for storedName, info in pairs(db and db.detectedVersions or {}) do
        if Normalize183(self, storedName) == normalized or Normalize183(self, info and info.sender) == normalized then
            return type(info) == "table" and info.version or nil
        end
    end
    return nil
end

function OTLGM:QueueGuildProfileRequestR27(target, reason)
    if not target or target == "" or IsSelf183(self, target) or not self.QueueNetworkPayload then return false end
    if self.GetMember and not self:GetMember(target) then return false end
    local version = self:GetDetectedAddonVersion183(target)
    if not self:IsTargetedSocialProfilePeerR27(version) then return false end
    self.runtime = self.runtime or {}
    self.runtime.socialProfileRequestsR27 = self.runtime.socialProfileRequestsR27 or {}
    local key, now = Normalize183(self, target), self:Now()
    if now - (tonumber(self.runtime.socialProfileRequestsR27[key]) or 0) < 60 then return false end
    local queued = self:QueueNetworkPayload("F1^REQ^" .. tostring(self.version or "1.8.3"), "WHISPER", target, 1, "social-profile", "social:req:" .. key)
    if queued then
        self.runtime.socialProfileRequestsR27[key] = now
        self.runtime.socialProfileRequestsSentR27 = (tonumber(self.runtime.socialProfileRequestsSentR27) or 0) + 1
        self.runtime.socialProfileLastRequestReasonR27 = tostring(reason or "profile-open")
    end
    return queued and true or false
end

function OTLGM:HandleGuildProfileRequestR27(channel, sender, requestVersion)
    if channel ~= "WHISPER" or not sender or sender == "" or IsSelf183(self, sender) then return false end
    if self.GetMember and not self:GetMember(sender) then return false end
    local version = self:GetDetectedAddonVersion183(sender)
    local effectiveVersion = version or requestVersion
    if not self:IsTargetedSocialProfilePeerR27(effectiveVersion) then return true end
    self.runtime = self.runtime or {}
    self.runtime.socialProfileRequestsReceivedR27 = (tonumber(self.runtime.socialProfileRequestsReceivedR27) or 0) + 1
    self:QueueGuildProfileSummary183("WHISPER", sender, "requested")
    self:QueueGuildProfileAbout183("WHISPER", sender, "requested")
    return true
end

local PreviousRememberAddonUser183 = OTLGM.RememberAddonUser
function OTLGM:RememberAddonUser(sender, version, build, faction)
    if PreviousRememberAddonUser183 then PreviousRememberAddonUser183(self, sender, version, build, faction) end
    if not sender or sender == "" or IsSelf183(self, sender) then return end
    local effectiveVersion = version
    if not effectiveVersion or effectiveVersion == "" or effectiveVersion == "Detected" then
        effectiveVersion = self:GetDetectedAddonVersion183(sender)
    end
    if not self:IsSocialProfilePeer183(effectiveVersion) then return end
    if self.GetMember and not self:GetMember(sender) then return end
    self.runtime = self.runtime or {}
    self.runtime.socialPeerShares183 = self.runtime.socialPeerShares183 or {}
    local key, now = Normalize183(self, sender), self:Now()
    if now - (tonumber(self.runtime.socialPeerShares183[key]) or 0) < PROFILE_PEER_COOLDOWN_183 then return end
    self.runtime.socialPeerShares183[key] = now
    self:QueueGuildProfileSummary183("WHISPER", sender, "presence")
    self:QueueGuildProfileAbout183("WHISPER", sender, "presence")
end

function OTLGM:GetGuildAchievementRanking183()
    self:EnsureSelfGuildProfile183(false)
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local store = db and db.guildProfiles183 or {}
    local revision = tonumber(self.runtime and self.runtime.socialProfileRevision183) or 0
    local rosterStamp = tonumber(db and db.lastScan) or 0
    local cache = self.runtime and self.runtime.achievementRankingCache183
    if cache and cache.revision == revision and cache.rosterStamp == rosterStamp and cache.store == store then return cache.list end
    local byName, key, record = {}, nil, nil
    for key, record in pairs(store or {}) do
        if type(record) == "table" and type(record.achievements) == "table" then
            local name = tostring(record.name or key)
            local normalized = Normalize183(self, name)
            local achievement = record.achievements
            local completed, total = tonumber(achievement.completed), tonumber(achievement.total)
            local member = normalized ~= "" and self.GetMember and self:GetMember(name) or nil
            local selfMember = normalized ~= "" and IsSelf183(self, name)
            if (member or selfMember) and completed and total and completed >= 0 and total >= 1 and completed <= total then
                local candidate = {
                    name = member and member.name or PlayerName183(),
                    completed = completed, total = total,
                    updatedAt = tonumber(achievement.updatedAt) or tonumber(record.updatedAt) or 0,
                }
                local old = byName[normalized]
                if not old or candidate.updatedAt > old.updatedAt then byName[normalized] = candidate end
            end
        end
    end
    local list = {}
    for key, record in pairs(byName) do table.insert(list, record) end
    table.sort(list, function(left, right)
        if left.completed ~= right.completed then return left.completed > right.completed end
        return string.lower(tostring(left.name or "")) < string.lower(tostring(right.name or ""))
    end)
    local index, previousCompleted, previousRank
    for index = 1, table.getn(list) do
        if previousCompleted ~= list[index].completed then previousRank = index previousCompleted = list[index].completed end
        list[index].rank = previousRank
        list[index].coverage = table.getn(list)
    end
    self.runtime = self.runtime or {}
    self.runtime.achievementRankingCache183 = { revision = revision, rosterStamp = rosterStamp, store = store, list = list }
    return list
end

function OTLGM:GetGuildAchievementRank183(name)
    local normalized = Normalize183(self, name)
    local ranking = self:GetGuildAchievementRanking183()
    local index
    for index = 1, table.getn(ranking) do
        if Normalize183(self, ranking[index].name) == normalized then return ranking[index].rank, table.getn(ranking) end
    end
    return nil, table.getn(ranking)
end

local PreviousProfileAchievementSnapshot183 = OTLGM.GetGuildProfileAchievementSnapshot183
if PreviousProfileAchievementSnapshot183 then
    function OTLGM:GetGuildProfileAchievementSnapshot183(name)
        if IsSelf183(self, name) then self:EnsureSelfGuildProfile183(false) end
        local snapshot = PreviousProfileAchievementSnapshot183(self, name)
        if snapshot and snapshot.known then
            snapshot.rank, snapshot.coverage = self:GetGuildAchievementRank183(name)
        elseif not IsSelf183(self, name) and self.QueueGuildProfileRequestR27 then
            self:QueueGuildProfileRequestR27(name, "profile-snapshot")
        end
        return snapshot
    end
end

local function EnsureTrackedIds183(owner)
    local db = owner.EnsureAchievements174 and owner:EnsureAchievements174() or nil
    if not db then return {}, nil end
    if type(db.tracked183) ~= "table" then db.tracked183 = {} end
    local cleaned, seen = {}, {}
    local index, id
    for index = 1, table.getn(db.tracked183) do
        id = tostring(db.tracked183[index] or "")
        if not seen[id] and owner.achievements174 and owner.achievements174.byId[id]
            and not (db.completed and db.completed[id]) and table.getn(cleaned) < MAX_GOALS_183 then
            seen[id] = true
            table.insert(cleaned, id)
        end
    end
    db.tracked183 = cleaned
    return cleaned, db
end

function OTLGM:IsAchievementTracked183(id)
    local ids = EnsureTrackedIds183(self)
    local index
    for index = 1, table.getn(ids) do if ids[index] == id then return true end end
    return false
end

function OTLGM:GetTrackedAchievementGoals183()
    local ids = EnsureTrackedIds183(self)
    local result = {}
    local index, id, definition, current, required, complete, name
    for index = 1, table.getn(ids) do
        id = ids[index]
        definition = self.achievements174 and self.achievements174.byId[id]
        if definition then
            complete = self:IsAchievementComplete174(id)
            current, required = self:GetAchievementProgress174(definition)
            name = self:GetAchievementPresentation174(definition, complete)
            table.insert(result, {
                id = id, name = tostring(name or definition.name or id),
                current = tonumber(current) or 0, required = math.max(1, tonumber(required) or 1),
                progressText = complete and "Complete" or (tostring(math.floor(tonumber(current) or 0)) .. " / " .. tostring(math.floor(math.max(1, tonumber(required) or 1)))),
            })
        end
    end
    return result
end

local function RefreshGoalViews183(owner)
    if owner.ui then owner.ui.achievementFilteredCache180 = nil end
    if owner.ui and owner.ui.currentPage == "achievements" and owner.RefreshAchievements174 then owner:RefreshAchievements174()
    elseif owner.RefreshAchievementTrackingButtons183 then owner:RefreshAchievementTrackingButtons183() end
    if owner.RefreshAchievementCommunityDrawer183 and owner.ui and owner.ui.achievementCommunityDrawer183
        and owner.ui.achievementCommunityDrawer183:IsVisible() then owner:RefreshAchievementCommunityDrawer183() end
    if owner.ui and owner.ui.main and owner.ui.main.IsVisible and owner.ui.main:IsVisible()
        and owner.ui.currentPage == "home" and owner.RefreshHomePage then
        owner:RefreshHomePage()
    end
    local profile = owner.ui and owner.ui.guildProfile183
    if profile and profile:IsVisible() and IsSelf183(owner, profile.otlMemberName183) then owner:RefreshGuildProfile183("goals") end
end

function OTLGM:ToggleAchievementGoal183(id)
    local definition = self.achievements174 and self.achievements174.byId[id]
    if not definition then return false, "unknown" end
    if self:IsAchievementComplete174(id) then
        if self.ShowToast then self:ShowToast("Completed achievements do not need tracking.", "pending") end
        return false, "complete"
    end
    local ids, db = EnsureTrackedIds183(self)
    local index
    for index = 1, table.getn(ids) do
        if ids[index] == id then
            table.remove(ids, index)
            db.tracked183 = ids
            RefreshGoalViews183(self)
            if self.ShowToast then self:ShowToast("Achievement removed from My Goals.", "success") end
            return true, "removed"
        end
    end
    if table.getn(ids) >= MAX_GOALS_183 then
        if self.ShowToast then self:ShowToast("My Goals can contain up to 3 achievements. Remove one before tracking another.", "pending", 6) end
        if self.OpenAchievementCommunityDrawer183 then self:OpenAchievementCommunityDrawer183("GOALS") end
        return false, "limit"
    end
    table.insert(ids, id)
    db.tracked183 = ids
    RefreshGoalViews183(self)
    if self.ShowToast then self:ShowToast("Achievement added to My Goals.", "success") end
    return true, "added"
end

local function RemoveCompletedGoal183(owner, id)
    local ids, db = EnsureTrackedIds183(owner)
    local changed, index = false, table.getn(ids)
    while index >= 1 do
        if ids[index] == id then table.remove(ids, index) changed = true end
        index = index - 1
    end
    if changed then db.tracked183 = ids RefreshGoalViews183(owner) end
end

local PreviousCompleteAchievement183 = OTLGM.CompleteAchievement174
if PreviousCompleteAchievement183 then
    function OTLGM:CompleteAchievement174(id, silent)
        local changed = PreviousCompleteAchievement183(self, id, silent)
        if changed then
            RemoveCompletedGoal183(self, id)
            self:EnsureSelfGuildProfile183(true)
            self:QueueGuildProfileSummary183("GUILD", nil, "achievement-complete")
        end
        return changed
    end
end

function OTLGM:OpenGuildProfileFromRanking183(name)
    local member = self.GetMember and self:GetMember(name) or nil
    if not member then
        if self.ShowToast then self:ShowToast("That member is not in the current guild list.", "error") end
        return false
    end
    local previousFocus, previousSelected = self.ui.rosterFocusMember180, self.ui.rosterSelectedName
    self.ui.rosterFocusMember180 = member.name
    self.ui.rosterSelectedName = member.name
    if not self:ShowPage("roster", { suppressRosterScan183 = true }) then
        self.ui.rosterFocusMember180, self.ui.rosterSelectedName = previousFocus, previousSelected
        return false
    end
    if self.PersistRosterPosition180 then self:PersistRosterPosition180() end
    return self:OpenGuildMemberProfile183(member.name, "achievement-ranking", false)
end

function OTLGM:BuildAchievementCommunityDrawer183()
    self.ui = self.ui or {}
    if self.ui.achievementCommunityDrawer183 then return self.ui.achievementCommunityDrawer183 end
    if not self.ui.drawerHost then return nil end
    local drawer = UI:Drawer(self.ui.drawerHost, 420, 536)
    drawer:SetPoint("TOPRIGHT", self.ui.drawerHost, "TOPRIGHT", -10, -10)
    drawer.title = UI.Text(drawer, "Guild Achievements", "GameFontNormalLarge", "LEFT")
    drawer.title:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -18) drawer.title:SetWidth(310)
    drawer.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    drawer.close = UI:IconButton(drawer, "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 28, 28, function() OTLGM:CloseShellDrawer() end, "Close", "utility")
    drawer.close:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -12, -12)
    drawer.rankTab = UI:Tab(drawer, "Guild Ranking", 142, function() drawer.otlMode183 = "RANKING" OTLGM:RefreshAchievementCommunityDrawer183() end)
    drawer.rankTab:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -56)
    drawer.goalsTab = UI:Tab(drawer, "My Goals", 112, function() drawer.otlMode183 = "GOALS" OTLGM:RefreshAchievementCommunityDrawer183() end)
    drawer.goalsTab:SetPoint("LEFT", drawer.rankTab, "RIGHT", 8, 0)
    drawer.subtitle = UI.Text(drawer, "", "GameFontNormalSmall", "LEFT")
    drawer.subtitle:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -94) drawer.subtitle:SetWidth(384) drawer.subtitle:SetHeight(34)
    drawer.subtitle:SetJustifyV("TOP") drawer.subtitle:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    drawer.rankRows = {}
    local index
    for index = 1, 10 do
        local row = UI:TableRow(drawer, 384, 32, function(button)
            if button.otlMemberName183 then OTLGM:CloseShellDrawer() OTLGM:OpenGuildProfileFromRanking183(button.otlMemberName183) end
        end)
        row:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -132 - ((index - 1) * 34))
        row.rank = UI.Text(row, "", "GameFontNormal", "CENTER")
        row.rank:SetPoint("LEFT", row, "LEFT", 8, 0) row.rank:SetWidth(38)
        row.name = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.name:SetPoint("LEFT", row, "LEFT", 52, 0) row.name:SetWidth(206)
        row.count = UI.Text(row, "", "GameFontNormalSmall", "RIGHT")
        row.count:SetPoint("RIGHT", row, "RIGHT", -10, 0) row.count:SetWidth(112)
        row:Hide() drawer.rankRows[index] = row
    end
    drawer.empty = UI.Text(drawer, "", "GameFontNormal", "CENTER")
    drawer.empty:SetPoint("TOPLEFT", drawer, "TOPLEFT", 24, -190) drawer.empty:SetWidth(372) drawer.empty:SetHeight(90)
    drawer.empty:SetTextColor(C.grey[1], C.grey[2], C.grey[3]) drawer.empty:Hide()
    drawer.goalRows = {}
    for index = 1, MAX_GOALS_183 do
        local row = UI:Card(drawer, 384, 76)
        row:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -134 - ((index - 1) * 84))
        row.name = UI.Text(row, "", "GameFontNormal", "LEFT")
        row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 12, -12) row.name:SetWidth(250)
        row.progress = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.progress:SetPoint("TOPLEFT", row, "TOPLEFT", 12, -38) row.progress:SetWidth(160) row.progress:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        row.open = UI:Button(row, "Open", 70, 24, function(button)
            if row.otlAchievementId183 then OTLGM:CloseShellDrawer() OTLGM:OpenAchievement174(row.otlAchievementId183) end
        end, "utility")
        row.open:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -82, 9)
        row.remove = UI:Button(row, "Remove", 70, 24, function()
            if row.otlAchievementId183 then OTLGM:ToggleAchievementGoal183(row.otlAchievementId183) end
        end, "secondary")
        row.remove:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, 9)
        row:Hide() drawer.goalRows[index] = row
    end
    drawer.footer = UI.Text(drawer, "Ranking includes only current guild members whose achievement progress has been shared with the addon.", "GameFontNormalSmall", "LEFT")
    drawer.footer:SetPoint("BOTTOMLEFT", drawer, "BOTTOMLEFT", 18, 18) drawer.footer:SetWidth(384) drawer.footer:SetHeight(34)
    drawer.footer:SetJustifyV("BOTTOM") drawer.footer:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    drawer.otlMode183 = "RANKING"
    drawer.otlUsesSharedDrawerHost = true
    self.ui.achievementCommunityDrawer183 = drawer
    return drawer
end

function OTLGM:RefreshAchievementCommunityDrawer183()
    local drawer = self.ui and self.ui.achievementCommunityDrawer183
    if not drawer then return false end
    local mode = drawer.otlMode183 == "GOALS" and "GOALS" or "RANKING"
    UI:SetSelected(drawer.rankTab, mode == "RANKING") UI:SetSelected(drawer.goalsTab, mode == "GOALS")
    local index
    if mode == "RANKING" then
        local ranking = self:GetGuildAchievementRanking183()
        local ownRank, coverage = self:GetGuildAchievementRank183(PlayerName183())
        drawer.subtitle:SetText(ownRank and ("#" .. tostring(ownRank) .. " among " .. tostring(coverage) .. " players with shared achievement data")
            or (tostring(coverage) .. " players are currently sharing achievement progress."))
        for index = 1, table.getn(drawer.rankRows) do
            local row, entry = drawer.rankRows[index], ranking[index]
            if entry then
                row.otlMemberName183 = entry.name
                row.rank:SetText("#" .. tostring(entry.rank))
                row.name:SetText(Short183(entry.name, 30))
                row.count:SetText(tostring(entry.completed) .. " / " .. tostring(entry.total))
                if entry.rank == 1 then row.rank:SetTextColor(1, 0.82, 0.35)
                elseif entry.rank == 2 then row.rank:SetTextColor(0.80, 0.82, 0.85)
                elseif entry.rank == 3 then row.rank:SetTextColor(0.78, 0.48, 0.24)
                else row.rank:SetTextColor(C.grey[1], C.grey[2], C.grey[3]) end
                row:Show()
            else row.otlMemberName183 = nil row:Hide() end
        end
        for index = 1, table.getn(drawer.goalRows) do drawer.goalRows[index]:Hide() end
        if table.getn(ranking) == 0 then drawer.empty:SetText("No compatible achievement summaries have been shared yet.") drawer.empty:Show() else drawer.empty:Hide() end
        drawer.footer:SetText("Ranking includes only current guild members whose achievement progress has been shared with the addon.")
    else
        local goals = self:GetTrackedAchievementGoals183()
        drawer.subtitle:SetText("Track up to 3 achievements. Goals stay inside Home and your Profile without adding extra screen clutter.")
        for index = 1, table.getn(drawer.rankRows) do drawer.rankRows[index]:Hide() end
        for index = 1, table.getn(drawer.goalRows) do
            local row, goal = drawer.goalRows[index], goals[index]
            if goal then
                row.otlAchievementId183 = goal.id
                row.name:SetText(Short183(goal.name, 42))
                row.progress:SetText("Progress  " .. tostring(goal.progressText))
                row:Show()
            else row.otlAchievementId183 = nil row:Hide() end
        end
        if table.getn(goals) == 0 then drawer.empty:SetText("No goals tracked yet. Use Track on an incomplete achievement.") drawer.empty:Show() else drawer.empty:Hide() end
        drawer.footer:SetText(tostring(table.getn(goals)) .. " / " .. tostring(MAX_GOALS_183) .. " goals tracked")
    end
    return true
end

function OTLGM:OpenAchievementCommunityDrawer183(mode)
    if not self.ui or not self.ui.main then self:BuildUI() end
    if not self.ui or not self.ui.main then return false end
    if self.ui.currentPage ~= "achievements" then
        if not self:ShowPage("achievements") then return false end
    end
    local drawer = self:BuildAchievementCommunityDrawer183()
    if not drawer then return false end
    drawer.otlMode183 = mode == "GOALS" and "GOALS" or "RANKING"
    self:RefreshAchievementCommunityDrawer183()
    return self:ShowShellDrawer(drawer)
end

function OTLGM:EnsureAchievementTrackingButtons183()
    local rows = self.ui and self.ui.achievementRows174 or {}
    local index, row
    for index = 1, table.getn(rows) do
        row = rows[index]
        if row and not row.otlGoalButton183 then
            local captured = row
            row.otlGoalButton183 = UI:Button(row, "Track", 68, 20, function()
                if not captured.achievement174 then return end
                local idR48 = captured.achievement174.id
                if OTLGM:IsAchievementComplete174(idR48) and OTLGM.ToggleAchievementShowcaseR48 then
                    OTLGM:ToggleAchievementShowcaseR48(idR48)
                else
                    OTLGM:ToggleAchievementGoal183(idR48)
                end
            end, "utility")
            row.otlGoalButton183:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, 6)
            if row.otlGoalButton183.SetFrameLevel and row.GetFrameLevel then
                row.otlGoalButton183:SetFrameLevel(row:GetFrameLevel() + 12)
            end
            row.otlGoalButton183.otlTooltipTitle = "My Goals"
            row.otlGoalButton183.otlTooltip = "Track up to three incomplete guild achievements."
            row.otlGoalButton183:Hide()
        end
    end
end

function OTLGM:RefreshAchievementTrackingButtons183()
    self:EnsureAchievementTrackingButtons183()
    local rows = self.ui and self.ui.achievementRows174 or {}
    -- One tiny showcase snapshot per visible achievement refresh; do not
    -- normalize the same three IDs once for every completed row.
    local showcaseSetR48 = {}
    local profileRecordR48 = self:EnsureSelfGuildProfile183(false)
    local showcaseIdsR48 = NormalizeShowcaseR48(self, profileRecordR48 and profileRecordR48.showcaseR48 or nil, true)
    local showcaseIndexR48
    for showcaseIndexR48 = 1, table.getn(showcaseIdsR48) do showcaseSetR48[showcaseIdsR48[showcaseIndexR48]] = true end
    local index, row, id, tracked
    for index = 1, table.getn(rows) do
        row = rows[index]
        id = row and row.achievement174 and row.achievement174.id or nil
        if row and row.otlGoalButton183 then
            row.otlGoalButton183:ClearAllPoints()
            row.otlGoalButton183:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, 5)
            row.otlGoalButton183:SetWidth(62) row.otlGoalButton183:SetHeight(20)
            if row.otlGoalButton183.SetFrameLevel and row.GetFrameLevel then
                row.otlGoalButton183:SetFrameLevel(row:GetFrameLevel() + 12)
            end
        end
        if row and row.otlGoalButton183 and row:IsVisible() and id then
            if self:IsAchievementComplete174(id) then
                local showcasedR48 = showcaseSetR48[id] and true or false
                row.otlGoalButton183:SetWidth(72)
                UI:SetText(row.otlGoalButton183, showcasedR48 and "Shown" or "Showcase")
                UI:SetSelected(row.otlGoalButton183, showcasedR48)
                row.otlGoalButton183.otlTooltipTitle = "Profile Showcase"
                row.otlGoalButton183.otlTooltip = showcasedR48
                    and "This completed achievement is featured in your Guild Profile. Click to remove it."
                    or "Feature up to three completed achievements in your Guild Profile."
                row.otlGoalButton183:Show()
            else
                tracked = self:IsAchievementTracked183(id)
                row.otlGoalButton183:SetWidth(62)
                UI:SetText(row.otlGoalButton183, tracked and "Untrack" or "Track")
                UI:SetSelected(row.otlGoalButton183, tracked)
                row.otlGoalButton183.otlTooltipTitle = "My Goals"
                row.otlGoalButton183.otlTooltip = "Track up to three incomplete guild achievements."
                row.otlGoalButton183:Show()
            end
        elseif row and row.otlGoalButton183 then row.otlGoalButton183:Hide() end
    end
end

function OTLGM:AttachAchievementCommunityControls183(page)
    if not page or page.otlSocialControls183 then return end
    page.otlSocialControls183 = true
    page.achievementCommunityButton183 = UI:Button(page, "Guild Ranking", 116, 25, function()
        OTLGM:OpenAchievementCommunityDrawer183("RANKING")
    end, "utility")
    page.achievementCommunityButton183.otlTooltipTitle = "Guild ranking"
    page.achievementCommunityButton183.otlTooltip = "Shows guild members who are sharing achievement progress."
    if UI.HelpIcon and not page.achievementHelpR32 then
        page.achievementHelpR32 = UI:ContextHelpIcon(page, "ACHIEVEMENTS")
    end
end

function OTLGM:LayoutAchievementCommunityControls183(page, width)
    if not page then return end
    self:AttachAchievementCommunityControls183(page)
    local button = page.achievementCommunityButton183
    if button then
        button:ClearAllPoints() button:SetPoint("TOPRIGHT", page, "TOPRIGHT", -154, -1)
        button:SetWidth(116) button:SetHeight(25)
    end
    if page.achievementHelpR32 then
        page.achievementHelpR32:ClearAllPoints()
        page.achievementHelpR32:SetPoint("RIGHT", button, "LEFT", -8, 0)
    end
    if self.ui and self.ui.achievementSummaryTitle174 then self.ui.achievementSummaryTitle174:SetWidth(math.max(180, (tonumber(width) or 720) - 380)) end
    if self.ui and self.ui.achievementSummarySubtitle174 then self.ui.achievementSummarySubtitle174:SetWidth(math.max(180, (tonumber(width) or 720) - 380)) end
    self:EnsureAchievementTrackingButtons183()
end

local achievementModule183 = OTLGM.shellPageModules and OTLGM.shellPageModules.achievements
if achievementModule183 and not achievementModule183.otlSocialWrapped183 then
    achievementModule183.otlSocialWrapped183 = true
    local PreviousBuild183, PreviousLayout183, PreviousRefresh183 = achievementModule183.Build, achievementModule183.Layout, achievementModule183.Refresh
    function achievementModule183:Build(contentHost)
        local root = PreviousBuild183(self, contentHost)
        self.owner:AttachAchievementCommunityControls183(root)
        return root
    end
    function achievementModule183:Layout(width, height)
        PreviousLayout183(self, width, height)
        self.owner:LayoutAchievementCommunityControls183(self.root, width)
        self.owner:RefreshAchievementTrackingButtons183()
    end
    function achievementModule183:Refresh(reason)
        PreviousRefresh183(self, reason)
        self.owner:RefreshAchievementTrackingButtons183()
    end
end

local PreviousPublicAchievementRefresh183 = OTLGM.RefreshAchievements174
if PreviousPublicAchievementRefresh183 then
    function OTLGM:RefreshAchievements174(value)
        local result = PreviousPublicAchievementRefresh183(self, value)
        self:RefreshAchievementTrackingButtons183()
        return result
    end
end

function OTLGM:BuildGuildProfileEditor183()
    self.ui = self.ui or {}
    if self.ui.guildProfileEditor183 then return self.ui.guildProfileEditor183 end
    if not self.ui.modalHost then return nil end
    local modal = UI:Modal(self.ui.modalHost, 520, 390)
    modal:SetPoint("CENTER", self.ui.modalHost, "CENTER", 0, 0)
    modal.otlDiagnosticName180 = "Guild Profile Customization"
    modal.title = UI.Text(modal, "Customize Guild Profile", "GameFontNormalLarge", "LEFT")
    modal.title:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -20) modal.title:SetWidth(420)
    modal.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    modal.help = UI.Text(modal, "Keep it personal without turning the profile into a dashboard. These choices are shared only when your profile is updated.", "GameFontNormalSmall", "LEFT")
    modal.help:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -50) modal.help:SetWidth(480) modal.help:SetHeight(30)
    modal.help:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.aboutLabel = UI.Text(modal, "ABOUT ME", "GameFontNormalSmall", "LEFT")
    modal.aboutLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -84) modal.aboutLabel:SetWidth(180)
    modal.aboutLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    modal.edit = UI:EditBox(modal, 480, 76, { multiline = true, maxLetters = MAX_ABOUT_BYTES_183, changed = function(value)
        if OTLGM.ui and OTLGM.ui.guildProfileEditor183 then
            OTLGM.ui.guildProfileEditor183.count:SetText(tostring(string.len(tostring(value or ""))) .. " / " .. tostring(MAX_ABOUT_BYTES_183))
        end
    end })
    modal.edit:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -102)
    modal.count = UI.Text(modal, "0 / 160", "GameFontNormalSmall", "RIGHT")
    modal.count:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -20, -182) modal.count:SetWidth(100)
    modal.count:SetTextColor(C.grey[1], C.grey[2], C.grey[3])

    modal.titleLabelR48 = UI.Text(modal, "PROFILE TITLE", "GameFontNormalSmall", "LEFT")
    modal.titleLabelR48:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -205) modal.titleLabelR48:SetWidth(180)
    modal.titleLabelR48:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    modal.titleButtonR48 = UI:Button(modal, "Title • No title", 300, 28, function()
        local editorR48 = OTLGM.ui and OTLGM.ui.guildProfileEditor183
        if not editorR48 then return end
        local nextKeyR48, nextLabelR48 = OTLGM:CycleGuildProfileTitleR48(editorR48.otlSelectedTitleR48)
        editorR48.otlSelectedTitleR48 = nextKeyR48
        UI:SetText(editorR48.titleButtonR48, "Title • " .. tostring(nextLabelR48))
    end, "utility")
    modal.titleButtonR48:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -222)
    modal.titleButtonR48.otlTooltipTitle = "Earned profile title"
    modal.titleButtonR48.otlTooltip = "Click to cycle through titles unlocked by your completed guild achievements."

    modal.showcaseLabelR48 = UI.Text(modal, "ACHIEVEMENT SHOWCASE", "GameFontNormalSmall", "LEFT")
    modal.showcaseLabelR48:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -263) modal.showcaseLabelR48:SetWidth(220)
    modal.showcaseLabelR48:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    modal.showcaseStateR48 = UI.Text(modal, "0 / 3 selected", "GameFontNormalSmall", "LEFT")
    modal.showcaseStateR48:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -282) modal.showcaseStateR48:SetWidth(250)
    modal.showcaseStateR48:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.openAchievementsR48 = UI:Button(modal, "Choose Achievements", 150, 28, function()
        -- Preserve staged About/title edits before leaving the editor. Showcase
        -- itself is changed from the existing Achievements page.
        OTLGM:SaveGuildProfileCustomizationR48(nil, true)
        OTLGM:ShowPage("achievements")
        if OTLGM.ShowToast then OTLGM:ShowToast("Completed achievements now have a Showcase button. Choose up to three.", "pending", 5) end
    end, "secondary")
    modal.openAchievementsR48:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -305)
    modal.clearShowcaseR48 = UI:Button(modal, "Clear Showcase", 122, 28, function()
        local recordR48 = OTLGM:EnsureSelfGuildProfile183(false)
        local _, idsR48 = OTLGM:GetGuildProfileShowcaseWireR48(recordR48 and recordR48.showcaseR48 or nil, true)
        if table.getn(idsR48) < 1 then return end
        recordR48.showcaseR48 = {}
        CommitProfileContentR48(OTLGM, recordR48, "showcase-clear")
        if OTLGM.RefreshAchievementTrackingButtons183 then OTLGM:RefreshAchievementTrackingButtons183() end
        local editorR48 = OTLGM.ui and OTLGM.ui.guildProfileEditor183
        if editorR48 then editorR48.showcaseStateR48:SetText("0 / 3 selected") end
    end, "utility")
    modal.clearShowcaseR48:SetPoint("LEFT", modal.openAchievementsR48, "RIGHT", 8, 0)

    modal.cancel = UI:Button(modal, "Cancel", 92, 30, function() OTLGM:CloseModal180(modal, "profile-cancel") end, "secondary")
    modal.cancel:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -124, 16)
    modal.save = UI:Button(modal, "Save", 96, 30, function() OTLGM:SaveGuildProfileCustomizationR48() end, "primary")
    modal.save:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -20, 16)
    self.ui.guildProfileEditor183 = modal
    return modal
end

function OTLGM:OpenGuildProfileEditor183()
    if not self.ui or not self.ui.main then self:BuildUI() end
    if not self.ui or not self.ui.main then return false end
    local record = self:EnsureSelfGuildProfile183(false)
    local modal = self:BuildGuildProfileEditor183()
    if not modal then return false end
    local about = tostring(record and record.about or "")
    local titleLabelR48, titleKeyR48 = self:GetGuildProfileTitleLabelR48(record and record.profileTitleR48 or "NONE", true)
    local _, showcaseIdsR48 = self:GetGuildProfileShowcaseWireR48(record and record.showcaseR48 or nil, true)
    modal.edit.otlSilent = true modal.edit:SetText(about) modal.edit.otlSilent = nil
    modal.count:SetText(tostring(string.len(about)) .. " / " .. tostring(MAX_ABOUT_BYTES_183))
    modal.otlSelectedTitleR48 = titleKeyR48
    UI:SetText(modal.titleButtonR48, "Title • " .. tostring(titleLabelR48))
    modal.showcaseStateR48:SetText(tostring(table.getn(showcaseIdsR48)) .. " / " .. tostring(MAX_SHOWCASE_R48) .. " selected")
    self:ShowShellModal(modal)
    return true
end

function OTLGM:SaveGuildProfileCustomizationR48(value, silent)
    local modal = self.ui and self.ui.guildProfileEditor183
    local incoming = value
    if incoming == nil and modal and modal.edit then incoming = modal.edit:GetText() end
    local about = self:SanitizeGuildProfileAbout183(incoming or "")
    local record = self:EnsureSelfGuildProfile183(false)
    if not record then return false end
    local titleKeyR48 = self:SanitizeGuildProfileTitleR48(modal and modal.otlSelectedTitleR48 or record.profileTitleR48 or "NONE", true)
    local _, showcaseIdsR48 = self:GetGuildProfileShowcaseWireR48(record.showcaseR48, true)
    local oldShowcaseWireR48 = self:GetGuildProfileShowcaseWireR48(record.showcaseR48, false)
    local newShowcaseWireR48 = table.getn(showcaseIdsR48) > 0 and table.concat(showcaseIdsR48, ",") or "-"
    local changedR48 = tostring(record.about or "") ~= about
        or tostring(record.profileTitleR48 or "NONE") ~= titleKeyR48
        or tostring(oldShowcaseWireR48 or "-") ~= tostring(newShowcaseWireR48)
    record.about = about
    record.profileTitleR48 = titleKeyR48
    record.showcaseR48 = showcaseIdsR48
    if changedR48 then CommitProfileContentR48(self, record, "profile-customization") end
    if modal and modal:IsVisible() then self:CloseModal180(modal, "save-success") end
    if not silent and self.ShowToast then self:ShowToast(changedR48 and "Guild Profile updated." or "Guild Profile already up to date.", changedR48 and "success" or "pending") end
    return changedR48
end

-- Compatibility wrapper retained for any older call site that still asks only
-- to save About Me.  r48 commits the whole compact profile-content revision.
function OTLGM:SaveGuildProfileAbout183(value)
    return self:SaveGuildProfileCustomizationR48(value)
end

local PreviousProfileSupport183 = OTLGM.GetGuildProfileSupportSummary183
if PreviousProfileSupport183 then
    function OTLGM:GetGuildProfileSupportSummary183()
        local base = tostring(PreviousProfileSupport183(self) or "")
        local store = self.GetGuildDB and self:GetGuildDB() or nil
        local records = store and store.guildProfiles183 or {}
        return base .. "\nSocial Profiles: records " .. tostring(CountRecords183(records))
            .. " / ranking cache " .. tostring(self.runtime and self.runtime.achievementRankingCache183 and "ready" or "cold")
            .. " / packets summary-about " .. tostring(self.runtime and self.runtime.socialProfilePackets183 or 0)
            .. "/" .. tostring(self.runtime and self.runtime.socialAboutPackets183 or 0)
            .. " / requests sent-received " .. tostring(self.runtime and self.runtime.socialProfileRequestsSentR27 or 0)
            .. "/" .. tostring(self.runtime and self.runtime.socialProfileRequestsReceivedR27 or 0)
            .. " / achievement date chunks sent-received " .. tostring(self.runtime and self.runtime.achievementTimeChunksSentR45 or 0)
            .. "/" .. tostring(self.runtime and self.runtime.achievementTimeChunksReceivedR45 or 0)
            .. " / profile identity sent-received-deferred " .. tostring(self.runtime and self.runtime.profileIdentityPacketsR48 or 0)
            .. "/" .. tostring(self.runtime and self.runtime.profileIdentityReceivedR48 or 0)
            .. "/" .. tostring(self.runtime and self.runtime.profileIdentityTailDeferredR48 or 0)
            .. " / content excluded"
    end
end


-- ---------------------------------------------------------------------------
-- r47: trusted version awareness and human-facing compatibility UX.
--
-- This layer intentionally sends no new packets. It derives update confidence
-- from the presence/version records the addon already receives. A single random
-- member cannot announce a guild-wide update: one recent Guild Leader signal or
-- two independent peers reporting the exact same version are required.
-- ---------------------------------------------------------------------------

local UPDATE_PEER_WINDOW_R47 = 86400
local UPDATE_GL_WINDOW_R47 = 7200
local UPDATE_CONSENSUS_FRESH_R47 = 1800

function OTLGM:GetFriendlyVersionLabelR47(version)
    version = tostring(version or self.version or "")
    local _, _, semantic = string.find(version, "(%d+%.%d+%.%d+)")
    semantic = semantic or version

    -- r59: ordinary members should not need engineering checkpoint names such
    -- as r42/r58 to understand compatibility.  Keep the exact runtime build in
    -- About/Support diagnostics, but make normal labels describe the useful
    -- relationship to this client instead.
    local current = tostring(self.version or "")
    local _, _, currentSemantic = string.find(current, "(%d+%.%d+%.%d+)")
    if current ~= "" and currentSemantic and tostring(currentSemantic) == tostring(semantic) then
        if version == current then return tostring(semantic) .. " • current" end
        if self.IsVersionNewer then
            if self:IsVersionNewer(current, version) then return tostring(semantic) .. " • older build" end
            if self:IsVersionNewer(version, current) then return tostring(semantic) .. " • newer build" end
        end
    end
    return tostring(semantic)
end

local function ValidVersionCandidateR47(owner, version)
    version = tostring(version or "")
    if version == "" or version == "Detected" or version == "unknown" or string.len(version) > 24 then return false end
    if not string.find(version, "^%d+%.%d+%.%d+") then return false end
    return owner.IsVersionNewer and owner:IsVersionNewer(version, owner.version) and true or false
end

function OTLGM:EvaluateTrustedUpdateR47(force)
    self.runtime = self.runtime or {}
    OTLGM_DB.settings = OTLGM_DB.settings or {}
    local now = self:Now()
    local revision = tonumber(self.runtime.addonDetectionRevision184) or 0
    local cached = self.runtime.versionAwarenessCacheR47
    if not force and cached and cached.revision == revision and now - (tonumber(cached.ts) or 0) < 10 then
        return cached.version, cached.evidence
    end

    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local groups = {}
    local senderKey, info
    for senderKey, info in pairs(db and db.detectedVersions or {}) do
        if type(info) == "table" then
            local version = tostring(info.version or "")
            local ts = tonumber(info.ts) or 0
            local age = math.max(0, now - ts)
            if age <= UPDATE_PEER_WINDOW_R47 and ValidVersionCandidateR47(self, version) then
                local sender = tostring(info.sender or senderKey or "")
                local normalized = Normalize183(self, sender)
                if normalized ~= "" then
                    local group = groups[version]
                    if not group then
                        group = { version = version, peers = 0, freshPeers = 0, onlinePeers = 0, guildLeader = false, names = {}, seen = {} }
                        groups[version] = group
                    end
                    if not group.seen[normalized] then
                        group.seen[normalized] = true
                        group.peers = group.peers + 1
                        local member = self.GetMember and self:GetMember(sender) or nil
                        local online = member and member.online and true or false
                        if online then group.onlinePeers = group.onlinePeers + 1 end
                        if online or age <= UPDATE_CONSENSUS_FRESH_R47 then group.freshPeers = group.freshPeers + 1 end
                        if member and tonumber(member.rankIndex) == 0
                            and self.IsCanonicalGuildLeaderName180 and self:IsCanonicalGuildLeaderName180(sender)
                            and (online or age <= UPDATE_GL_WINDOW_R47) then group.guildLeader = true end
                        if table.getn(group.names) < 4 then table.insert(group.names, sender) end
                    end
                end
            end
        end
    end

    local trustedVersion, trustedEvidence, candidateCount = nil, nil, 0
    local version, group
    for version, group in pairs(groups) do
        candidateCount = candidateCount + 1
        local trusted = group.guildLeader or (group.peers >= 2 and group.freshPeers >= 1)
        if trusted and (not trustedVersion or self:IsVersionNewer(version, trustedVersion)) then
            trustedVersion = version
            trustedEvidence = {
                peers = group.peers,
                freshPeers = group.freshPeers,
                onlinePeers = group.onlinePeers,
                guildLeader = group.guildLeader and true or false,
                source = group.guildLeader and "GUILD_LEADER" or "CONSENSUS",
                sourceLabel = group.guildLeader and "confirmed by Guild Leader" or ("confirmed by " .. tostring(group.peers) .. " guild clients"),
            }
        end
    end

    local settings = OTLGM_DB.settings
    local stored = tostring(settings.latestTrustedVersionR47 or "")
    if stored ~= "" and not ValidVersionCandidateR47(self, stored) then
        settings.latestTrustedVersionR47 = ""
        settings.latestTrustedVersionAtR47 = 0
        settings.latestTrustedVersionSourceR47 = ""
        stored = ""
    end
    if trustedVersion then
        if stored == "" or self:IsVersionNewer(trustedVersion, stored) then
            settings.latestTrustedVersionR47 = trustedVersion
            settings.latestTrustedVersionAtR47 = now
            settings.latestTrustedVersionSourceR47 = trustedEvidence.source
            stored = trustedVersion
        elseif stored == trustedVersion then
            settings.latestTrustedVersionSourceR47 = trustedEvidence.source
        end
    end

    if stored ~= "" and (not trustedVersion or self:IsVersionNewer(stored, trustedVersion)) then
        trustedVersion = stored
        trustedEvidence = {
            peers = 0, freshPeers = 0, onlinePeers = 0, guildLeader = false,
            source = "STORED_TRUST",
            sourceLabel = "previously confirmed by guild clients",
            confirmedAt = tonumber(settings.latestTrustedVersionAtR47) or 0,
        }
    end

    self.runtime.versionAwarenessCandidatesR47 = candidateCount
    self.runtime.versionAwarenessTrustedR47 = trustedVersion
    self.runtime.versionAwarenessSourceR47 = trustedEvidence and trustedEvidence.source or "NONE"
    self.runtime.versionAwarenessCacheR47 = { revision = revision, ts = now, version = trustedVersion, evidence = trustedEvidence }
    return trustedVersion, trustedEvidence
end

function OTLGM:GetTrustedUpdateVersionR47()
    return self:EvaluateTrustedUpdateR47(false)
end

function OTLGM:GetWhatsNewTextR47()
    return "• 1.8.3 final hardens achievement persistence so completed guild achievements cannot be re-awarded after reloads, relogs or character swaps."
        .. "\n• Roster online presence updates quickly while rank, note, history and membership changes still use the authoritative full scan."
        .. "\n• Recruitment rotates Social 1 → Raid 1 → Social 2 → Raid 2 with Sunday 20:00 ST / 2SR information and an 8-minute minimum, 10-minute preferred interval."
        .. "\n• Support & Report is easier to use, stays quiet for ordinary lag, and prepares one privacy-safe diagnostic report when help is actually needed."
end

function OTLGM:OpenVersionDetailsR47()
    local latest = self:GetTrustedUpdateVersionR47()
    if latest and self.MarkInboxMatching170 then self:MarkInboxMatching170("ADDON_UPDATE:" .. tostring(latest)) end
    if self.ShowPage then self:ShowPage("settings") end
    if self.SetSettingsShellTab then self:SetSettingsShellTab("ABOUT")
    elseif self.ShowSettingsSection then self:ShowSettingsSection("ABOUT") end
    return true
end

function OTLGM:EnsureTrustedUpdateActionR47(version, evidence)
    version = tostring(version or "")
    if version == "" or not ValidVersionCandidateR47(self, version) then return false end
    if not self.AddObjectInboxNotification180 then return false end
    self.runtime = self.runtime or {}
    if tostring(self.runtime.versionActionEnsuredR47 or "") == version then return false end
    local label = self:GetFriendlyVersionLabelR47(version)
    local source = evidence and evidence.sourceLabel or "confirmed by guild clients"
    local added = self:AddObjectInboxNotification180("background", "ADDON_UPDATE:" .. version,
        "Addon update available", label .. " is " .. tostring(source) .. ".",
        "ACTION", "ADDON_UPDATE", version, "ABOUT", "UPDATE", "settings")
    -- Even if the entry already existed from a previous session, avoid walking
    -- the bounded inbox again on every navigation refresh during this login.
    self.runtime.versionActionEnsuredR47 = version
    return added and true or false
end

function OTLGM:MaybeNotifyVersionAwarenessR47()
    self.runtime = self.runtime or {}
    if self.runtime.versionAwarenessBusyR47 then return false end
    self.runtime.versionAwarenessBusyR47 = true
    local version, evidence = self:GetTrustedUpdateVersionR47()
    if version then self:EnsureTrustedUpdateActionR47(version, evidence) end

    local settings = OTLGM_DB and OTLGM_DB.settings or nil
    local visible = self.IsUIVisible and self:IsUIVisible()
    local inCombat = self.InCombat and self:InCombat()
    if settings and visible and not inCombat then
        if version and tostring(settings.updateNoticeSeenVersionR47 or "") ~= tostring(version) then
            if self.ShowToast then
                self:ShowToast("Addon update available: " .. self:GetFriendlyVersionLabelR47(version) .. ". Open Settings → About for details.", "pending", 7)
            end
            settings.updateNoticeSeenVersionR47 = version
            -- Avoid stacking a second What's New toast underneath an update notice.
            settings.whatsNewSeenVersionR47 = tostring(self.version or "")
            self.runtime.versionUpdateToastsR47 = (tonumber(self.runtime.versionUpdateToastsR47) or 0) + 1
        elseif not version and settings.firstRunComplete and tostring(settings.whatsNewSeenVersionR47 or "") ~= tostring(self.version or "") then
            if self.ShowToast then
                self:ShowToast("Updated to " .. self:GetFriendlyVersionLabelR47(self.version) .. ". What's New is available in Settings → About.", "success", 6)
            end
            settings.whatsNewSeenVersionR47 = tostring(self.version or "")
            self.runtime.versionWhatsNewToastsR47 = (tonumber(self.runtime.versionWhatsNewToastsR47) or 0) + 1
        end
    end
    self.runtime.versionAwarenessBusyR47 = nil
    return version and true or false
end

-- Turn the existing peer capability contract into short user-facing guidance.
-- The detailed minimum-version registry remains intact in Full Support Report.
local PreviousFeatureCompatibilityMessageR47 = OTLGM.GetFeatureCompatibilityMessageR32
function OTLGM:GetFeatureCompatibilityMessageR32(name, key, onlyWhenBlocked)
    local ok, state, version, capability = self:GetFeatureCompatibilityR32(name, key)
    if ok then
        if onlyWhenBlocked then return nil end
        return tostring(capability and capability.label or key or "This feature") .. " is available for " .. tostring(name or "this player") .. "."
    end
    local who = tostring(name or "This player")
    local label = tostring(capability and capability.label or key or "This feature")
    local minimum = tostring(capability and capability.minVersion or "a newer version")
    local minimumLabel = self.GetFriendlyVersionLabelR47 and self:GetFriendlyVersionLabelR47(minimum) or minimum
    if state == "NOT_DETECTED" then
        return label .. " is not verified for " .. who .. ". Their addon is unavailable or has not shared a compatible version yet."
    end
    local detectedLabel = self.GetFriendlyVersionLabelR47 and self:GetFriendlyVersionLabelR47(version) or tostring(version or "unknown")
    return label .. " needs a newer addon on " .. who .. ". Detected " .. detectedLabel .. "; requires " .. minimumLabel .. " or newer."
end

-- Make the existing global compatibility summary aware of an update to this
-- client, while retaining the useful mixed-version guild count underneath.
local PreviousAddonCompatibilityWarningR47 = OTLGM.GetAddonCompatibilityWarningRC4
function OTLGM:GetAddonCompatibilityWarningRC4()
    local base = PreviousAddonCompatibilityWarningR47 and PreviousAddonCompatibilityWarningR47(self) or nil
    local latest, evidence = self:GetTrustedUpdateVersionR47()
    if latest then
        local lead = "Update available: " .. self:GetFriendlyVersionLabelR47(latest)
            .. " (" .. tostring(evidence and evidence.sourceLabel or "confirmed by guild clients") .. ")."
        return base and (lead .. " " .. tostring(base)) or lead
    end
    return base
end

local PreviousSupportCurrentStatusR47 = OTLGM.GetSupportCurrentStatusR33
if PreviousSupportCurrentStatusR47 then
    function OTLGM:GetSupportCurrentStatusR33()
        local latest, evidence = self:GetTrustedUpdateVersionR47()
        local versionLine
        if latest then
            versionLine = "|cffffcc55UPDATE|r  Newer addon version " .. self:GetFriendlyVersionLabelR47(latest)
                .. " is " .. tostring(evidence and evidence.sourceLabel or "confirmed by guild clients") .. "."
        else
            versionLine = "|cff55cc66OK|r  Addon version is up to date against trusted guild version evidence."
        end
        return versionLine .. "\n" .. tostring(PreviousSupportCurrentStatusR47(self) or "")
    end
end

-- One persistent Action Center entry represents the newest trusted update.
-- Older update entries disappear automatically once superseded or installed.
local PreviousInboxActionableR47 = OTLGM.IsInboxEntryActionable180
function OTLGM:IsInboxEntryActionable180(entry)
    if type(entry) == "table" and string.upper(tostring(entry.objectType or "")) == "ADDON_UPDATE" then
        local target = tostring(entry.objectId or "")
        local latest = self:GetTrustedUpdateVersionR47()
        return target ~= "" and target == tostring(latest or "") and ValidVersionCandidateR47(self, target)
    end
    return PreviousInboxActionableR47 and PreviousInboxActionableR47(self, entry) or false
end

local PreviousInboxStaleR47 = OTLGM.IsInboxEntryStale180
function OTLGM:IsInboxEntryStale180(entry)
    if type(entry) == "table" and string.upper(tostring(entry.objectType or "")) == "ADDON_UPDATE" then
        local target = tostring(entry.objectId or "")
        local latest = self:GetTrustedUpdateVersionR47()
        if not ValidVersionCandidateR47(self, target) then return true end
        return latest ~= nil and tostring(latest) ~= target
    end
    return PreviousInboxStaleR47 and PreviousInboxStaleR47(self, entry) or false
end

local PreviousOpenActionCenterEntryR47 = OTLGM.OpenActionCenterEntry180
if PreviousOpenActionCenterEntryR47 then
    function OTLGM:OpenActionCenterEntry180(entry)
        local isUpdate = type(entry) == "table" and string.upper(tostring(entry.objectType or "")) == "ADDON_UPDATE"
        local result = PreviousOpenActionCenterEntryR47(self, entry)
        if isUpdate then
            if self.ShowPage then self:ShowPage("settings") end
            if self.SetSettingsShellTab then self:SetSettingsShellTab("ABOUT") end
            return true
        end
        return result
    end
end

-- Existing presence/version packets are the only evidence source. No extra
-- broadcast is introduced for r47; burst traffic only dirties the derived cache.
local PreviousRememberAddonUserR47 = OTLGM.RememberAddonUser
function OTLGM:RememberAddonUser(sender, version, build, faction)
    if PreviousRememberAddonUserR47 then PreviousRememberAddonUserR47(self, sender, version, build, faction) end
    -- Presence can arrive in large guild bursts. Only mark the tiny derived
    -- trust cache dirty here; visible navigation/Settings/Sharing refreshes
    -- perform one consolidated evaluation after the burst.
    if self.runtime then self.runtime.versionAwarenessCacheR47 = nil end
end

local PreviousRefreshNavigationR47 = OTLGM.RefreshNavigation
if PreviousRefreshNavigationR47 then
    function OTLGM:RefreshNavigation()
        local result = PreviousRefreshNavigationR47(self)
        self:MaybeNotifyVersionAwarenessR47()
        return result
    end
end


local PreviousRefreshAddonUsersDrawerR47 = OTLGM.RefreshAddonUsersDrawer
if PreviousRefreshAddonUsersDrawerR47 then
    function OTLGM:RefreshAddonUsersDrawer()
        local result = PreviousRefreshAddonUsersDrawerR47(self)
        local drawer = self.ui and self.ui.addonUsersDrawer
        if drawer then
            local latest, evidence = self:GetTrustedUpdateVersionR47()
            if latest then
                drawer.subtitle:SetText("Update available: " .. self:GetFriendlyVersionLabelR47(latest)
                    .. " • " .. tostring(evidence and evidence.sourceLabel or "confirmed by guild clients"))
                if drawer.summary and drawer.summary.Current and drawer.summary.Current.label then
                    drawer.summary.Current.label:SetText("Same version\nonline")
                end
            elseif drawer.summary and drawer.summary.Current and drawer.summary.Current.label then
                drawer.summary.Current.label:SetText("Up to date\nonline")
            end
        end
        return result
    end
end

function OTLGM:GetVersionAwarenessDiagnosticsR47()
    local latest, evidence = self:GetTrustedUpdateVersionR47()
    local settings = OTLGM_DB and OTLGM_DB.settings or {}
    return "R47 version awareness: current " .. tostring(self.version or "?")
        .. "; trusted " .. tostring(latest or "none")
        .. "; source " .. tostring(evidence and evidence.source or "NONE")
        .. "; peers " .. tostring(evidence and evidence.peers or 0)
        .. "; candidates " .. tostring(self.runtime and self.runtime.versionAwarenessCandidatesR47 or 0)
        .. "; update/whats-new toasts " .. tostring(self.runtime and self.runtime.versionUpdateToastsR47 or 0)
        .. "/" .. tostring(self.runtime and self.runtime.versionWhatsNewToastsR47 or 0)
        .. "; stored " .. tostring(settings.latestTrustedVersionR47 or "none")
end

local PreviousSupportReportR47 = OTLGM.GetSupportReport181
if PreviousSupportReportR47 then
    function OTLGM:GetSupportReport181()
        local report = tostring(PreviousSupportReportR47(self) or "")
        local line = self:GetVersionAwarenessDiagnosticsR47() .. "\n"
        local marker = "=== END SUPPORT REPORT ==="
        local markerAt = string.find(report, marker, 1, true)
        if markerAt then return string.sub(report, 1, markerAt - 1) .. line .. marker end
        return report .. "\n" .. line
    end
end

OTLGM:RegisterModule("SocialProfiles183", {
    stage = "E",
    revision = 1,
    minimumPeer = MIN_SOCIAL_VERSION_183,
    profileRecordLimit = MAX_PROFILE_RECORDS_183,
    goalLimit = MAX_GOALS_183,
    aboutLimit = MAX_ABOUT_BYTES_183,
    showcaseLimitR48 = MAX_SHOWCASE_R48,
    profileIdentityMinPeerR48 = MIN_PROFILE_IDENTITY_VERSION_R48,
    senderBound = true,
    targetedPresenceShare = true,
    dirtyAbout = true,
    honestCoverage = true,
    noOnUpdate = true,
    noPolling = true,
    noRosterRequest = true,
    noProfessionScan = true,
})
