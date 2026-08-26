-- Order of the Lion Guild Manager 1.8.3
-- Private, bounded reports and official warning workflow.
-- All private traffic is targeted through the canonical transport. This file
-- creates no event frame, timer, permanent OnUpdate, roster scan or polling.

if not OTLGM or not OTLGM.UI then return end

local UI = OTLGM.UI
local C = UI.colors
local MIN_MODERATION_VERSION_183 = "1.8.3-rc2"
local MIN_RECONCILIATION_VERSION_183 = "1.8.3-rc4"
local MIN_AUTHOR_CONTROL_VERSION_R30 = "1.8.3-rc4-r30"
local MAX_OWN_REPORTS_183 = 60
local MAX_OFFICER_CASES_183 = 120
local MAX_OFFICER_WARNINGS_183 = 120
local MAX_OWN_WARNINGS_183 = 40
local MAX_ESCALATIONS_183 = 40
local MAX_TIMELINE_183 = 12
local MAX_REPORT_TEXT_183 = 240
local MAX_DIAGNOSTICS_183 = 360
local MAX_RESPONSE_183 = 120
local MAX_WARNING_REASON_183 = 72
local MAX_PRIVATE_COMMENT_183 = 120
local MAX_STATUS_REASON_183 = 72
local MAX_SHARED_TIMELINE_183 = 8
local REPORT_CHUNK_183 = 84
local DIAGNOSTIC_CHUNK_183 = 84
local MAX_REPORT_PEERS_183 = 3
local PENDING_RETRY_COOLDOWN_183 = 300
local RECONCILIATION_BUCKETS_183 = 6
local RECONCILIATION_PAGE_183 = 2
local RECONCILIATION_TTL_183 = 300
local RECONCILIATION_FLOW_TTL_183 = 1800
local MAX_RECONCILIATION_PEERS_183 = 8
local MAX_RECONCILIATION_TRANSFERS_183 = 24
local RECONCILIATION_MESSAGE_KINDS_183 = {
    MSUM = true, MREQ = true, MIDX = true, MWARN = true, MWTEXT = true,
    MCASE = true, MCTEXT = true, MACK = true,
}

local CASE_SCOPE_LEADERSHIP_183 = "LEADERSHIP"
local CASE_SCOPE_GUILD_LEADER_183 = "GUILD_LEADER"
local CASE_SCOPE_EXTERNAL_183 = "EXTERNAL"

local CLASS_COORDS_MOD183 = {
    WARRIOR = { 0, 0.25, 0, 0.25 }, MAGE = { 0.25, 0.496, 0, 0.25 },
    ROGUE = { 0.496, 0.742, 0, 0.25 }, DRUID = { 0.742, 0.988, 0, 0.25 },
    HUNTER = { 0, 0.25, 0.25, 0.5 }, SHAMAN = { 0.25, 0.496, 0.25, 0.5 },
    PRIEST = { 0.496, 0.742, 0.25, 0.5 }, WARLOCK = { 0.742, 0.988, 0.25, 0.5 },
    PALADIN = { 0, 0.25, 0.5, 0.75 },
}

local function ApplyModerationClassIcon183(texture, className)
    if not texture then return end
    local coordinates = CLASS_COORDS_MOD183[string.upper(tostring(className or ""))]
    if coordinates then
        texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
        texture:SetTexCoord(coordinates[1], coordinates[2], coordinates[3], coordinates[4])
    else
        texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        texture:SetTexCoord(0, 1, 0, 1)
    end
end

local REPORT_TYPES_183 = {
    { key = "PLAYER", label = "Player Report", categories = {
        { "HARASSMENT", "Harassment / insults" }, { "SPAM", "Spam" }, { "CHAT", "Guild chat behaviour" },
        { "LOOT", "Loot dispute" }, { "GROUP", "Dungeon / Raid behaviour" }, { "RULES", "Breaking guild rules" },
        { "SCAM", "Scamming / suspicious trade" }, { "CONTENT", "Inappropriate content" }, { "OTHER", "Other" },
    } },
    { key = "GUILD", label = "Guild / Leadership Issue", categories = {
        { "ORGANIZATION", "Guild organization" }, { "RANK", "Rank / permissions" }, { "RAID", "Raid organization" },
        { "RECRUITMENT", "Recruitment" }, { "RULES", "Guild rule concern" }, { "OTHER", "Other" },
    } },
    { key = "ADDON", label = "Addon Problem", categories = {
        { "FPS", "FPS / stuttering" }, { "UI", "UI problem" }, { "FEATURE", "Feature not working" },
        { "DATA", "Incorrect data" }, { "SYNC", "Sync / communication" }, { "PROFESSION", "Profession / recipe" },
        { "ACHIEVEMENT", "Achievement" }, { "OTHER", "Other" },
    } },
    { key = "SUGGESTION", label = "Suggestion", categories = {
        { "ADDON", "Addon suggestion" }, { "GUILD", "Guild suggestion" },
        { "EVENT", "Event / Raid suggestion" }, { "OTHER", "Other idea" },
    } },
}

local REPORT_STATUSES_183 = {
    { "NEW", "New" }, { "SEEN", "Seen" }, { "REVIEW", "Assigned / In Review" }, { "WAITING", "Waiting for Player" },
    { "HOLD", "Waiting for Officer" }, { "ACTION", "Action Planned" }, { "RESOLVED", "Resolved" },
    { "NO_ACTION", "Closed — No Action" }, { "REJECTED", "Rejected" }, { "DUPLICATE", "Duplicate" },
    { "ARCHIVED", "Closed" }, { "WITHDRAWN", "Withdrawn by author" },
}

local WARNING_CATEGORIES_183 = {
    { "BEHAVIOUR", "Behaviour" }, { "CHAT", "Guild chat" }, { "RULES", "Guild rules" },
    { "LOOT", "Loot" }, { "RAID", "Dungeon / Raid" }, { "TRADE", "Trade" }, { "OTHER", "Other" },
}

local WARNING_CLEAR_REASONS_183 = {
    { "EXPIRED", "Expired" }, { "RESOLVED", "Resolved" },
    { "MISTAKE", "Issued by mistake" }, { "DECISION", "Leadership decision" },
}

local TERMINAL_REPORT_STATUSES_183 = {
    RESOLVED=true, NO_ACTION=true, REJECTED=true, DUPLICATE=true, ARCHIVED=true, WITHDRAWN=true,
}

local function ShortName183(name)
    local short = string.gsub(tostring(name or ""), "%-.*$", "")
    return short
end

local function PlayerName183()
    return ShortName183(UnitName and UnitName("player") or "")
end

local function Normalize183(owner, name)
    if owner.NormalizeName then return owner:NormalizeName(name or "") end
    return string.lower(ShortName183(name))
end

local function IsSelf183(owner, name)
    local player = Normalize183(owner, PlayerName183())
    return player ~= "" and player == Normalize183(owner, name)
end

local function Short183(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or 60
    if string.len(value) <= maximum then return value end
    return string.sub(value, 1, math.max(1, maximum - 3)) .. "..."
end

local function SafeWireText183(owner, value, maximum)
    value = owner.SafeText and owner:SafeText(value or "", maximum, false, false) or tostring(value or "")
    value = string.gsub(value, "%^", "/")
    value = string.gsub(value, "[\r\n\t]", " ")
    value = string.gsub(value, "%s+", " ")
    value = owner.Trim and owner:Trim(value) or value
    return owner.Utf8Truncate and owner:Utf8Truncate(value, maximum) or string.sub(value, 1, maximum)
end

local function DefinitionLabel183(definitions, key, fallback)
    local index
    for index = 1, table.getn(definitions or {}) do
        if definitions[index][1] == key or definitions[index].key == key then
            return definitions[index][2] or definitions[index].label or fallback or key
        end
    end
    return fallback or tostring(key or "Unknown")
end

local function ReportTypeDefinition183(key)
    local index
    for index = 1, table.getn(REPORT_TYPES_183) do
        if REPORT_TYPES_183[index].key == key then return REPORT_TYPES_183[index], index end
    end
    return REPORT_TYPES_183[1], 1
end

local function ReportCategoryValid183(reportType, category)
    local definition = ReportTypeDefinition183(reportType)
    local index
    for index = 1, table.getn(definition.categories) do
        if definition.categories[index][1] == category then return true end
    end
    return false
end

local function ReportTypeLabel183(key)
    local definition = ReportTypeDefinition183(key)
    return definition.label
end

local function ReportCategoryLabel183(reportType, category)
    local definition = ReportTypeDefinition183(reportType)
    return DefinitionLabel183(definition.categories, category, category)
end

local function ReportStatusLabel183(status)
    return DefinitionLabel183(REPORT_STATUSES_183, status, status)
end

local function WarningCategoryLabel183(category)
    return DefinitionLabel183(WARNING_CATEGORIES_183, category, category)
end

local function WarningClearLabel183(reason)
    return DefinitionLabel183(WARNING_CLEAR_REASONS_183, reason, reason)
end

function OTLGM:ResolveModerationReportTarget183(reportType, target)
    target = SafeWireText183(self, target or "", 32)
    if reportType ~= "PLAYER" then return true, target end
    if target == "" then
        return false, "Choose a current guild member for a Player Report."
    end
    local member = self.GetMember and self:GetMember(target) or nil
    if not member or not member.name or member.name == "" then
        return false, "That player is not in the current guild list. Choose a member shown in Roster."
    end
    return true, ShortName183(member.name)
end

function OTLGM:GetModerationTargetMatches183(query, maximum)
    maximum = math.max(1, math.min(5, tonumber(maximum) or 3))
    query = self.Trim and self:Trim(query or "") or tostring(query or "")
    local normalizedQuery = Normalize183(self, query)
    if normalizedQuery == "" then return {} end
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local roster = db and db.roster or {}

    -- Cache the normalized roster names once per successful roster snapshot.
    -- Typing in the target picker must not repeatedly normalize ~800 names.
    self.runtime = self.runtime or {}
    local revision = tostring(tonumber(db and db.lastScan) or 0) .. ":" .. tostring(tonumber(db and db.lastTotal) or 0)
    local indexState = self.runtime.moderationTargetRosterIndex183
    if not indexState or indexState.revision ~= revision or indexState.roster ~= roster then
        indexState = { revision = revision, roster = roster, rows = {} }
        local key, member, normalizedName
        for key, member in pairs(roster or {}) do
            if type(member) == "table" and member.name and member.name ~= "" then
                normalizedName = Normalize183(self, member.name)
                if normalizedName ~= "" then
                    table.insert(indexState.rows, { member = member, normalizedName = normalizedName })
                end
            end
        end
        self.runtime.moderationTargetRosterIndex183 = indexState
    end

    local exact, prefix, contains = {}, {}, {}
    local index, indexed, normalizedName
    for index = 1, table.getn(indexState.rows or {}) do
        indexed = indexState.rows[index]
        normalizedName = indexed.normalizedName or ""
        if normalizedName == normalizedQuery then
            table.insert(exact, indexed.member)
        elseif string.sub(normalizedName, 1, string.len(normalizedQuery)) == normalizedQuery then
            if table.getn(prefix) < maximum then table.insert(prefix, indexed.member) end
        elseif table.getn(exact) + table.getn(prefix) < maximum
            and string.find(normalizedName, normalizedQuery, 1, true) then
            if table.getn(contains) < maximum then table.insert(contains, indexed.member) end
        end
    end
    local result, groupIndex = {}, nil
    local groups = { exact, prefix, contains }
    for groupIndex = 1, table.getn(groups) do
        for index = 1, table.getn(groups[groupIndex]) do
            table.insert(result, groups[groupIndex][index])
            if table.getn(result) >= maximum then return result end
        end
    end
    return result
end

local function CountMap183(map)
    local count, key = 0, nil
    for key in pairs(map or {}) do count = count + 1 end
    return count
end

local function PruneMap183(map, maximum, protected)
    if type(map) ~= "table" then return 0 end
    local count, key, record = 0, nil, nil
    for key, record in pairs(map) do
        if type(record) ~= "table" then map[key] = nil else count = count + 1 end
    end
    if count <= maximum then return 0 end
    local rows = {}
    for key, record in pairs(map) do
        table.insert(rows, {
            key = key,
            protected = protected and protected(record) and true or false,
            ts = tonumber(record.updatedAt or record.createdAt or record.issuedAt or record.ts) or 0,
        })
    end
    table.sort(rows, function(left, right)
        if left.protected ~= right.protected then return not left.protected end
        if left.ts ~= right.ts then return left.ts < right.ts end
        return tostring(left.key) < tostring(right.key)
    end)
    local removed, index = 0, 1
    while count > maximum and index <= table.getn(rows) do
        map[rows[index].key] = nil
        count = count - 1
        removed = removed + 1
        index = index + 1
    end
    return removed
end

local function EnsureTimeline183(record)
    if type(record.timeline) ~= "table" then record.timeline = {} end
    local index
    for index = table.getn(record.timeline), 1, -1 do
        if type(record.timeline[index]) ~= "table" then table.remove(record.timeline, index) end
    end
    while table.getn(record.timeline) > MAX_TIMELINE_183 do table.remove(record.timeline, 1) end
    return record.timeline
end

local function AppendTimeline183(owner, record, kind, actor, text, timestamp, eventKey)
    local timeline = EnsureTimeline183(record)
    eventKey = tostring(eventKey or (kind .. ":" .. tostring(timestamp or owner:Now()) .. ":" .. tostring(actor or "")))
    local index, entry
    for index = 1, table.getn(timeline) do
        entry = timeline[index]
        if tostring(entry.eventKey or "") == eventKey then return false end
    end
    table.insert(timeline, {
        ts = tonumber(timestamp) or owner:Now(), kind = tostring(kind or "UPDATE"),
        actor = SafeWireText183(owner, actor or "", 32), text = SafeWireText183(owner, text or "", MAX_RESPONSE_183),
        eventKey = SafeWireText183(owner, eventKey, 80),
    })
    while table.getn(timeline) > MAX_TIMELINE_183 do table.remove(timeline, 1) end
    return true
end

local function TimelineToken183(value, maximum)
    value = tostring(value or "")
    value = string.gsub(value, "[;|^]", "/")
    value = string.gsub(value, "[\r\n\t]", " ")
    value = string.gsub(value, "%s+", " ")
    return string.sub(value, 1, maximum or 48)
end

local function SerializeCaseTimeline183(record)
    local timeline = type(record) == "table" and type(record.timeline) == "table" and record.timeline or {}
    local shared = {}
    local index, entry
    for index = 1, table.getn(timeline) do
        entry = timeline[index]
        -- Transport/reconciliation events are local diagnostics, never part of
        -- canonical moderation history or its digest. Including them would make
        -- two otherwise-equal Officer clients diverge after every sync.
        if type(entry) == "table" and tostring(entry.kind or "") ~= "RECONCILED" then
            table.insert(shared, entry)
        end
    end
    local result, startIndex = {}, math.max(1, table.getn(shared) - MAX_SHARED_TIMELINE_183 + 1)
    for index = startIndex, table.getn(shared) do
        entry = shared[index]
        table.insert(result, table.concat({
            tostring(math.max(0, tonumber(entry.ts) or 0)),
            TimelineToken183(entry.kind, 16), TimelineToken183(entry.actor, 24),
            TimelineToken183(entry.text, 56), TimelineToken183(entry.eventKey, 56),
        }, "|"))
    end
    return table.concat(result, ";")
end

local function ParseCaseTimeline183(owner, value)
    local result = {}
    local entries = owner:Split(tostring(value or ""), ";")
    local index, fields
    for index = 1, math.min(MAX_SHARED_TIMELINE_183, table.getn(entries)) do
        if entries[index] and entries[index] ~= "" then
            fields = owner:Split(entries[index], "|")
            if table.getn(fields) >= 4 then
                table.insert(result, {
                    ts = tonumber(fields[1]) or owner:Now(), kind = tostring(fields[2] or "UPDATE"),
                    actor = tostring(fields[3] or ""), text = tostring(fields[4] or ""),
                    eventKey = tostring(fields[5] or (fields[2] or "UPDATE") .. ":" .. tostring(fields[1] or "0")),
                })
            end
        end
    end
    return result
end

local function InferStoredCaseScope183(owner, reportType, target)
    if tostring(reportType or "") ~= "PLAYER" or not target or target == "" then
        return CASE_SCOPE_LEADERSHIP_183
    end
    local member = owner.GetMember and owner:GetMember(target) or nil
    if not member or not owner.IsLeadership or not owner:IsLeadership(member) then
        return CASE_SCOPE_LEADERSHIP_183
    end
    local canonical = owner.GetCanonicalGuildLeaderName180 and owner:GetCanonicalGuildLeaderName180() or ""
    if Normalize183(owner, canonical) ~= "" and Normalize183(owner, canonical) == Normalize183(owner, member.name or target) then
        return CASE_SCOPE_EXTERNAL_183
    end
    return CASE_SCOPE_GUILD_LEADER_183
end

local function PruneModerationState183(owner, state)
    local removed = 0
    removed = removed + PruneMap183(state.ownReports, MAX_OWN_REPORTS_183, function(record)
        return record.delivery ~= "SUBMITTED" or not TERMINAL_REPORT_STATUSES_183[record.status or "NEW"]
    end)
    removed = removed + PruneMap183(state.officerCases, MAX_OFFICER_CASES_183, function(record)
        return not TERMINAL_REPORT_STATUSES_183[record.status or "NEW"]
    end)
    removed = removed + PruneMap183(state.officerWarnings, MAX_OFFICER_WARNINGS_183, function(record) return record.active == true end)
    removed = removed + PruneMap183(state.ownWarnings, MAX_OWN_WARNINGS_183, function(record) return record.active == true end)
    removed = removed + PruneMap183(state.escalations, MAX_ESCALATIONS_183, function(record) return record.status ~= "CLOSED" end)
    if removed > 0 then
        owner.runtime = owner.runtime or {}
        owner.runtime.moderationPruned183 = (tonumber(owner.runtime.moderationPruned183) or 0) + removed
    end
    return removed
end

function OTLGM:EnsureModeration183()
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    if not db then return nil end
    if type(db.moderation183) ~= "table" then db.moderation183 = {} end
    local state = db.moderation183
    if type(state.ownReports) ~= "table" then state.ownReports = {} end
    if type(state.officerCases) ~= "table" then state.officerCases = {} end
    if type(state.officerWarnings) ~= "table" then state.officerWarnings = {} end
    if type(state.ownWarnings) ~= "table" then state.ownWarnings = {} end
    if type(state.escalations) ~= "table" then state.escalations = {} end
    state.sequence = math.max(0, math.floor(tonumber(state.sequence) or 0))
    state.startedAt = tonumber(state.startedAt) or self:Now()

    -- SavedVariables are repaired and bounded once when their table is first seen.
    -- Every internal insertion is bounded at the mutation site, so steady-state UI
    -- refreshes stay O(1) instead of walking all five private stores repeatedly.
    self.runtime = self.runtime or {}
    if self.runtime.moderationPrivacyMigratedRC4 ~= state then
        local id, record
        local playerIsGuildLeader = self.IsGuildLeader170 and self:IsGuildLeader170() and true or false
        local canonicalLeader = self.GetCanonicalGuildLeaderName180 and self:GetCanonicalGuildLeaderName180() or ""
        for id, record in pairs(state.ownReports or {}) do
            -- r30 repairs the old self-ack path from r25-r29. Those builds could
            -- mark an Officer author's own report as SUBMITTED locally without
            -- another Leadership client ever acknowledging it. A real remote ACK
            -- stores the officer character name instead, so only the legacy
            -- synthetic labels are reverted to pending delivery.
            if type(record) == "table" and record.delivery == "SUBMITTED"
                and (record.acknowledgedBy == "Local Leadership" or record.acknowledgedBy == "Guild Leader") then
                record.delivery = "PENDING"
                record.acknowledgedAt = nil
                record.acknowledgedBy = nil
                record.updatedAt = self:Now()
                AppendTimeline183(self, record, "REPAIRED", "Addon", "Self-ack removed; waiting for another Leadership client", record.updatedAt, "r30-self-ack-repair")
                self.runtime.moderationSelfAckRepairsR30 = (tonumber(self.runtime.moderationSelfAckRepairsR30) or 0) + 1
            end
            if type(record) == "table" and not record.privacyScope then
                record.privacyScope = InferStoredCaseScope183(self, record.reportType, record.target)
                if record.privacyScope == CASE_SCOPE_GUILD_LEADER_183 and not playerIsGuildLeader then
                    local deliveredToLeader = false
                    local key, recipient
                    for key, recipient in pairs(record.deliveryRecipients or {}) do
                        if Normalize183(self, recipient) == Normalize183(self, canonicalLeader) then
                            deliveredToLeader = true
                            break
                        end
                    end
                    if not deliveredToLeader then
                        record.delivery = "PENDING"
                        record.acknowledgedAt = nil
                        record.acknowledgedBy = nil
                    end
                end
            end
        end
        for id, record in pairs(state.officerCases or {}) do
            if type(record) == "table" and not record.privacyScope then
                record.privacyScope = InferStoredCaseScope183(self, record.reportType, record.target)
            end
            -- OTLGM_DB is shared by characters on the same installation. Do not
            -- destructively delete a Guild-Leader-only case merely because an
            -- Officer alt is currently logged in; the Guild Leader would lose
            -- the record on the next character switch. EXTERNAL cases are never
            -- valid officer records and can still be discarded. Runtime/UI access
            -- is filtered by CanCurrentClientAccessModerationRecord183 instead.
            if type(record) == "table" and record.privacyScope == CASE_SCOPE_EXTERNAL_183 then
                state.officerCases[id] = nil
            end
        end
        -- For the same shared-SavedVariables reason, keep officer warning records
        -- intact even when the current character is their target. The target UI
        -- receives only ownWarnings; officer-view access is denied at read/action
        -- boundaries so private comments are never exposed.
        self.runtime.moderationPrivacyMigratedRC4 = state
    end
    if self.runtime.moderationEnsuredState183 ~= state then
        PruneModerationState183(self, state)
        self.runtime.moderationEnsuredState183 = state
    end
    return state
end

function OTLGM:PruneModerationStorage183()
    local state = self:EnsureModeration183()
    if not state then return 0 end
    return PruneModerationState183(self, state)
end

local function NameHash183(name)
    local hash, index = 0, 1
    name = string.lower(tostring(name or ""))
    for index = 1, string.len(name) do hash = math.mod((hash * 33) + (string.byte(name, index) or 0), 99991) end
    return hash
end

function OTLGM:NextModerationId183(prefix)
    local state = self:EnsureModeration183()
    if not state then return nil end
    state.sequence = math.mod((tonumber(state.sequence) or 0) + 1, 9999)
    if state.sequence == 0 then state.sequence = 1 end
    return tostring(prefix or "R") .. tostring(math.floor(self:Now())) .. "-"
        .. tostring(NameHash183(PlayerName183())) .. "-" .. tostring(state.sequence)
end

function OTLGM:IsModerationPeer183(version)
    version = tostring(version or "")
    if version == "" or version == "Detected" then return false end
    if self.IsVersionNewer then return not self:IsVersionNewer(MIN_MODERATION_VERSION_183, version) end
    return string.find(version, "^1%.8%.3") ~= nil
end

function OTLGM:IsModerationReconciliationPeer183(name, version)
    if not self:IsValidatedModerationLeader183(name, version) then return false end
    version = version or (self.GetDetectedAddonVersion183 and self:GetDetectedAddonVersion183(name)) or ""
    if self.IsVersionNewer then return not self:IsVersionNewer(MIN_RECONCILIATION_VERSION_183, version) end
    return string.find(tostring(version or ""), "^1%.8%.3%-rc[4-9]") ~= nil
end

function OTLGM:IsModerationAuthorControlPeerR30(name, version)
    if not name or name == "" or IsSelf183(self, name) then return false end
    if not version and self.GetDetectedAddonVersion183 then version = self:GetDetectedAddonVersion183(name) end
    if not self:IsValidatedModerationLeader183(name, version) then return false end
    version = tostring(version or "")
    if self.IsVersionNewer then return not self:IsVersionNewer(MIN_AUTHOR_CONTROL_VERSION_R30, version) end
    local _, _, revision = string.find(version, "^1%.8%.3%-rc4%-r(%d+)")
    return (tonumber(revision) or 0) >= 30
end

function OTLGM:IsValidatedModerationLeader183(name, version)
    if not name or name == "" or IsSelf183(self, name) then return false end
    local member = self.GetMember and self:GetMember(name) or nil
    if not member or not self.IsLeadership or not self:IsLeadership(member) then return false end
    if not version and self.GetDetectedAddonVersion183 then version = self:GetDetectedAddonVersion183(name) end
    if not self:IsModerationPeer183(version) then return false end
    return true
end

function OTLGM:GetModerationLeadershipPeers183(limit, exclude, excludeSecond)
    local result, seen = {}, {}
    limit = math.max(1, math.min(MAX_REPORT_PEERS_183, tonumber(limit) or MAX_REPORT_PEERS_183))
    local list = self.GetDetectedAddonUserList and self:GetDetectedAddonUserList(1800) or {}
    local index, peer, normalized
    for index = 1, table.getn(list) do
        peer = list[index]
        normalized = Normalize183(self, peer and (peer.sender or peer.name) or "")
        if peer and peer.online and normalized ~= "" and normalized ~= Normalize183(self, exclude or "")
            and normalized ~= Normalize183(self, excludeSecond or "")
            and not seen[normalized] and self:IsValidatedModerationLeader183(peer.sender or peer.name, peer.version) then
            seen[normalized] = true
            table.insert(result, ShortName183(peer.sender or peer.name))
            if table.getn(result) >= limit then break end
        end
    end
    return result
end

function OTLGM:IsModerationGuildLeaderPeer183(name, version)
    if not name or name == "" or IsSelf183(self, name) then return false end
    if not self:IsModerationReconciliationPeer183(name, version) then return false end
    local canonical = self.GetCanonicalGuildLeaderName180 and self:GetCanonicalGuildLeaderName180() or ""
    return Normalize183(self, canonical) ~= "" and Normalize183(self, canonical) == Normalize183(self, name)
end

function OTLGM:ResolveModerationReportScope183(reportType, target)
    if tostring(reportType or "") ~= "PLAYER" or not target or target == "" then
        return CASE_SCOPE_LEADERSHIP_183
    end
    local member = self.GetMember and self:GetMember(target) or nil
    if not member then return CASE_SCOPE_LEADERSHIP_183 end
    if self.IsLeadership and self:IsLeadership(member) then
        local canonical = self.GetCanonicalGuildLeaderName180 and self:GetCanonicalGuildLeaderName180() or ""
        if Normalize183(self, canonical) ~= "" and Normalize183(self, canonical) == Normalize183(self, member.name or target) then
            return CASE_SCOPE_EXTERNAL_183
        end
        return CASE_SCOPE_GUILD_LEADER_183
    end
    return CASE_SCOPE_LEADERSHIP_183
end

function OTLGM:GetModerationGuildLeaderPeers183(limit)
    local result = {}
    limit = math.max(1, math.min(1, tonumber(limit) or 1))
    local canonical = self.GetCanonicalGuildLeaderName180 and self:GetCanonicalGuildLeaderName180() or ""
    if canonical == "" then return result end
    local list = self.GetDetectedAddonUserList and self:GetDetectedAddonUserList(1800) or {}
    local index, peer
    for index = 1, table.getn(list) do
        peer = list[index]
        if peer and peer.online and Normalize183(self, peer.sender or peer.name) == Normalize183(self, canonical)
            and self:IsModerationGuildLeaderPeer183(peer.sender or peer.name, peer.version) then
            table.insert(result, ShortName183(peer.sender or peer.name))
            break
        end
    end
    return result
end

function OTLGM:CanPeerReceiveModerationRecord183(peerName, recordType, record)
    if type(record) ~= "table" or not peerName or peerName == "" then return false end
    if not self:IsModerationReconciliationPeer183(peerName) then return false end
    if Normalize183(self, peerName) == Normalize183(self, record.target or "") then return false end
    if recordType == "W" then return true end
    local scope = tostring(record.privacyScope or CASE_SCOPE_LEADERSHIP_183)
    if scope == CASE_SCOPE_GUILD_LEADER_183 then return self:IsModerationGuildLeaderPeer183(peerName) end
    if scope == CASE_SCOPE_EXTERNAL_183 then return false end
    return true
end

function OTLGM:CanCurrentClientAccessModerationRecord183(recordType, record)
    if type(record) ~= "table" or not self:IsOfficerMode() then return false end
    if Normalize183(self, record.target or "") == Normalize183(self, PlayerName183()) then return false end
    if recordType == "W" then return true end
    local scope = tostring(record.privacyScope or CASE_SCOPE_LEADERSHIP_183)
    if scope == CASE_SCOPE_EXTERNAL_183 then return false end
    if scope == CASE_SCOPE_GUILD_LEADER_183 then
        return self.IsGuildLeader170 and self:IsGuildLeader170() and true or false
    end
    return true
end

local function ChunkText183(owner, text, maximum)
    local result = {}
    text = tostring(text or "")
    maximum = tonumber(maximum) or REPORT_CHUNK_183
    while text ~= "" do
        local part = owner.Utf8Truncate and owner:Utf8Truncate(text, maximum) or string.sub(text, 1, maximum)
        if part == "" then break end
        table.insert(result, part)
        text = string.sub(text, string.len(part) + 1)
    end
    return result
end

function OTLGM:GetCompactModerationDiagnostics183()
    local fps = nil
    if GetFramerate then local ok, value = pcall(GetFramerate) if ok then fps = tonumber(value) end end
    local zone, subzone, instance = "unknown", "", "world"
    if GetRealZoneText then local ok, value = pcall(GetRealZoneText) if ok then zone = tostring(value or "unknown") end end
    if GetSubZoneText then local ok, value = pcall(GetSubZoneText) if ok then subzone = tostring(value or "") end end
    if GetInstanceInfo then
        local ok, name, instanceType = pcall(GetInstanceInfo)
        if ok then instance = Short183(tostring(name or instanceType or "instance"), 28) end
    elseif IsInInstance then
        local ok, inside, instanceType = pcall(IsInInstance)
        if ok and inside then instance = tostring(instanceType or "instance") end
    end
    local latency = nil
    if GetNetStats then
        local ok, _, _, latencyHome, latencyWorld = pcall(GetNetStats)
        if ok then latency = tonumber(latencyWorld) or tonumber(latencyHome) end
    end
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local rosterCount = 0
    local _
    for _ in pairs(db and db.roster or {}) do rosterCount = rosterCount + 1 end
    local rosterAge = db and db.lastScan and math.max(0, self:Now() - (tonumber(db.lastScan) or self:Now())) or nil
    local queueTotal, queueCritical, queueNormal, queueBulk = 0, 0, 0, 0
    if self.GetNetworkQueueDepth then queueTotal, queueCritical, queueNormal, queueBulk = self:GetNetworkQueueDepth() end
    local scheduler = self.GetSchedulerDiagnostics180 and self:GetSchedulerDiagnostics180() or {}
    local pressure = self.GetClientPressure181 and self:GetClientPressure181() or {}
    local crafting = self.runtime and self.runtime.craftingMetrics180 or {}
    local search = self.runtime and self.runtime.globalSearchMetrics185 or {}
    local enchState = self.runtime and self.runtime.enchantDiagnosticsR24 or nil
    local enchEntries = enchState and table.getn(enchState.entries or {}) or 0
    local incident = self.runtime and self.runtime.lastAutoIncident181 or nil
    local errorInfo = self.runtime and self.runtime.errorHistoryRC3 and self.runtime.errorHistoryRC3[1] or nil
    local fields = {
        "v=" .. tostring(self.version or "unknown"), "b=" .. tostring(self.build or "unknown"),
        "zone=" .. Short183(zone, 28), "subzone=" .. Short183(subzone, 24), "instance=" .. Short183(instance, 28),
        "fps=" .. tostring(fps and math.floor(fps + 0.5) or "n/a"), "latency=" .. tostring(latency and math.floor(latency + 0.5) or "n/a"),
        "page=" .. tostring(self.ui and self.ui.currentPage or "closed"),
        "roster=" .. tostring(rosterCount) .. "/" .. tostring(rosterAge and (math.floor(rosterAge) .. "s") or "n/a"),
        "net=" .. tostring(queueCritical) .. "/" .. tostring(queueNormal) .. "/" .. tostring(queueBulk),
        "scheduler=" .. tostring(scheduler.taskCount or 0) .. "/" .. tostring(math.floor((tonumber(scheduler.lastSliceMs181) or 0) + 0.5)) .. "ms/p" .. tostring(pressure.level or 0),
        "craft=" .. tostring(crafting.scans or 0) .. "/" .. tostring(crafting.commits or 0),
        "search=" .. tostring(search.hits or 0) .. "/" .. tostring(search.builds or 0),
        "enchant=" .. tostring(crafting.selectedEnchantEffectCapturesR24 or 0) .. "/" .. tostring(crafting.selectedEnchantEffectMissesR24 or 0) .. "/d" .. tostring(enchEntries),
        "spike=" .. tostring(incident and (Short183(incident.operation, 22) .. ":" .. tostring(math.floor((tonumber(incident.ms) or 0) + 0.5)) .. "ms") or "none"),
        "error=" .. tostring(errorInfo and (Short183(errorInfo.source, 24) .. " x" .. tostring(errorInfo.count or 1)) or "none"),
    }
    return SafeWireText183(self, table.concat(fields, "; "), MAX_DIAGNOSTICS_183)
end

local function QueueModerationPacket183(owner, payload, target, key)
    if not owner.QueueNetworkPayload or not target or target == "" then return false end
    return owner:QueueNetworkPayload(payload, "WHISPER", ShortName183(target), 3, "moderation", key) and true or false
end

-- RC3 officer reconciliation is deliberately event-driven.  Presence and real
-- moderation mutations enqueue compact bulk packets through the existing
-- transport; there is no timer, heartbeat, roster walk or OnUpdate here.
local function QueueModerationReconciliationPacket183(owner, payload, target, key)
    if not owner.QueueNetworkPayload or not target or target == "" then return false end
    return owner:QueueNetworkPayload(payload, "WHISPER", ShortName183(target), 1,
        "moderation-reconcile", key) and true or false
end

local function ReconciliationRuntime183(owner)
    owner.runtime = owner.runtime or {}
    if type(owner.runtime.moderationReconciliation183) ~= "table" then
        owner.runtime.moderationReconciliation183 = { peers = {}, flows = {}, transfers = {}, indexes = {} }
    end
    local runtime = owner.runtime.moderationReconciliation183
    if type(runtime.peers) ~= "table" then runtime.peers = {} end
    if type(runtime.flows) ~= "table" then runtime.flows = {} end
    if type(runtime.transfers) ~= "table" then runtime.transfers = {} end
    if type(runtime.indexes) ~= "table" then runtime.indexes = {} end
    local now, key, flow = owner:Now(), nil, nil
    for key, flow in pairs(runtime.flows) do
        if type(flow) ~= "table" or now - (tonumber(flow.updatedAt or flow.startedAt) or 0) > RECONCILIATION_FLOW_TTL_183 then
            runtime.flows[key] = nil
            if type(runtime.peers[key]) == "table" and runtime.peers[key].state ~= "READY" then
                runtime.peers[key].state = "STALE"
            end
        end
    end
    local indexState
    for key, indexState in pairs(runtime.indexes) do
        if type(indexState) ~= "table" or now - (tonumber(indexState.updatedAt) or 0) > RECONCILIATION_TTL_183 then
            runtime.indexes[key] = nil
        end
    end
    return runtime
end

local function ReconciliationPeer183(owner, runtime, key)
    local peer = runtime.peers[key]
    if type(peer) ~= "table" then peer = {} runtime.peers[key] = peer end
    peer.lastRuntimeUseAt = owner:Now()
    local count, storedKey, candidate, oldestKey, oldestAt = 0, nil, nil, nil, nil
    for storedKey, candidate in pairs(runtime.peers) do
        count = count + 1
        if storedKey ~= key then
            local timestamp = tonumber(candidate and (candidate.lastRuntimeUseAt or candidate.lastRemoteSummaryAt
                or candidate.lastSummaryQueuedAt or candidate.lastPresenceAt)) or 0
            if not oldestAt or timestamp < oldestAt then oldestKey, oldestAt = storedKey, timestamp end
        end
    end
    if count > MAX_RECONCILIATION_PEERS_183 and oldestKey then
        runtime.peers[oldestKey] = nil
        runtime.flows[oldestKey] = nil
        runtime.indexes[oldestKey] = nil
    end
    return peer
end

local function CaseLatestText183(record, kind, field)
    if type(record) ~= "table" then return "" end
    if tostring(record[field] or "") ~= "" then return tostring(record[field]) end
    local timeline = type(record.timeline) == "table" and record.timeline or {}
    local index
    for index = table.getn(timeline), 1, -1 do
        if type(timeline[index]) == "table" and timeline[index].kind == kind then
            return tostring(timeline[index].text or "")
        end
    end
    return ""
end

local function WarningState183(record)
    return type(record) == "table" and record.active == true and "1" or "0"
end

local function CaseState183(record)
    return tostring(type(record) == "table" and record.status or "NEW")
end

local function ModerationRecordDigest183(recordType, record)
    if type(record) ~= "table" then return 0 end
    local text
    if recordType == "W" then
        local active = record.active == true
        text = table.concat({
            tostring(record.id or ""), tostring(record.revision or 1), WarningState183(record),
            tostring(record.issuedAt or 0), tostring(record.updatedAt or 0), tostring(record.target or ""),
            tostring(record.issuer or ""), tostring(record.category or "OTHER"), tostring(record.announcedCount or 1),
            tostring(record.acknowledged and 1 or 0), tostring(record.acknowledgedAt or 0),
            tostring(record.clearReason or ""), tostring(record.clearedAt or 0), tostring(record.relatedCaseId183 or ""),
            active and tostring(record.reason or "") or "",
            active and tostring(record.privateComment or "") or "",
        }, "~")
    else
        local terminal = TERMINAL_REPORT_STATUSES_183[record.status or "NEW"] and true or false
        text = table.concat({
            tostring(record.id or ""), tostring(record.revision or 1), tostring(record.sourceRevision or 1),
            tostring(record.createdAt or 0), tostring(record.updatedAt or 0), tostring(record.author or ""),
            tostring(record.target or ""), tostring(record.reportType or "PLAYER"), tostring(record.category or "OTHER"),
            CaseState183(record), tostring(record.privacyScope or CASE_SCOPE_LEADERSHIP_183),
            tostring(record.assignedTo183 or ""), tostring(record.statusReason183 or ""),
            tostring(record.relatedCaseId183 or ""), tostring(record.caseKind183 or "REPORT"), SerializeCaseTimeline183(record),
            terminal and "" or tostring(record.text or ""), terminal and "" or tostring(record.diagnostics or ""),
            terminal and "" or CaseLatestText183(record, "REPLY", "latestResponse183"),
            terminal and "" or CaseLatestText183(record, "FOLLOWUP", "latestFollowup183"),
            terminal and "" or tostring(record.privateComment or ""),
        }, "~")
    end
    return NameHash183(text)
end

local function EmptyReconciliationBuckets183()
    local buckets, index = {}, 1
    for index = 1, RECONCILIATION_BUCKETS_183 do buckets[index] = { count = 0, hash = 0 } end
    return buckets
end

local function AddReconciliationDigest183(buckets, recordType, id, record)
    local bucket = math.mod(NameHash183(id), RECONCILIATION_BUCKETS_183) + 1
    local state = recordType == "W" and WarningState183(record) or CaseState183(record)
    local digest = ModerationRecordDigest183(recordType, record)
    local entryHash = NameHash183(table.concat({ tostring(id), tostring(record.revision or 1), state,
        tostring(record.updatedAt or 0), tostring(digest) }, ","))
    buckets[bucket].count = buckets[bucket].count + 1
    buckets[bucket].hash = math.mod(buckets[bucket].hash + entryHash, 99991)
end

local function SerializeReconciliationBuckets183(buckets)
    local parts, index = {}, 1
    for index = 1, RECONCILIATION_BUCKETS_183 do
        table.insert(parts, tostring(buckets[index].count) .. "." .. tostring(buckets[index].hash))
    end
    return table.concat(parts, ",")
end

local function ParseReconciliationBuckets183(owner, value)
    local parts = owner:Split(tostring(value or ""), ",")
    local result, index = {}, 1
    for index = 1, RECONCILIATION_BUCKETS_183 do result[index] = tostring(parts[index] or "0.0") end
    return result
end

local function BuildModerationSummary183(owner, peerName)
    local state = owner:EnsureModeration183()
    local warningBuckets, caseBuckets = EmptyReconciliationBuckets183(), EmptyReconciliationBuckets183()
    local warningCount, activeWarnings, caseCount, openCases = 0, 0, 0, 0
    local id, record
    for id, record in pairs(state and state.officerWarnings or {}) do
        if type(record) == "table" and (not peerName or owner:CanPeerReceiveModerationRecord183(peerName, "W", record)) then
            warningCount = warningCount + 1
            if record.active == true then activeWarnings = activeWarnings + 1 end
            AddReconciliationDigest183(warningBuckets, "W", id, record)
        end
    end
    for id, record in pairs(state and state.officerCases or {}) do
        if type(record) == "table" and (not peerName or owner:CanPeerReceiveModerationRecord183(peerName, "C", record)) then
            caseCount = caseCount + 1
            if not TERMINAL_REPORT_STATUSES_183[record.status or "NEW"] then openCases = openCases + 1 end
            AddReconciliationDigest183(caseBuckets, "C", id, record)
        end
    end
    local warningHash, caseHash, index = 0, 0, 1
    for index = 1, RECONCILIATION_BUCKETS_183 do
        warningHash = math.mod(warningHash + warningBuckets[index].hash, 99991)
        caseHash = math.mod(caseHash + caseBuckets[index].hash, 99991)
    end
    return {
        activeWarnings = activeWarnings, warningCount = warningCount, warningHash = warningHash,
        openCases = openCases, caseCount = caseCount, caseHash = caseHash,
        warningBuckets = warningBuckets, caseBuckets = caseBuckets,
        warningBucketText = SerializeReconciliationBuckets183(warningBuckets),
        caseBucketText = SerializeReconciliationBuckets183(caseBuckets),
    }
end

local function SummaryMatches183(localSummary, remote)
    if tonumber(localSummary.warningCount) ~= tonumber(remote.warningCount)
        or tonumber(localSummary.warningHash) ~= tonumber(remote.warningHash)
        or tonumber(localSummary.caseCount) ~= tonumber(remote.caseCount)
        or tonumber(localSummary.caseHash) ~= tonumber(remote.caseHash) then return false end
    local index
    for index = 1, RECONCILIATION_BUCKETS_183 do
        if tostring(localSummary.warningBuckets[index].count) .. "." .. tostring(localSummary.warningBuckets[index].hash)
                ~= tostring(remote.warningBuckets[index])
            or tostring(localSummary.caseBuckets[index].count) .. "." .. tostring(localSummary.caseBuckets[index].hash)
                ~= tostring(remote.caseBuckets[index]) then return false end
    end
    return true
end

function OTLGM:GetModerationReconciliationPeers183(maximum)
    local result, seen = {}, {}
    maximum = math.max(1, math.min(MAX_RECONCILIATION_PEERS_183,
        tonumber(maximum) or MAX_RECONCILIATION_PEERS_183))
    local list = self.GetDetectedAddonUserList and self:GetDetectedAddonUserList(1800) or {}
    local index, peer, normalized
    for index = 1, table.getn(list) do
        peer = list[index]
        normalized = Normalize183(self, peer and (peer.sender or peer.name) or "")
        if peer and peer.online and normalized ~= "" and not seen[normalized]
            and self:IsModerationReconciliationPeer183(peer.sender or peer.name, peer.version) then
            seen[normalized] = true
            table.insert(result, ShortName183(peer.sender or peer.name))
            if table.getn(result) >= maximum then break end
        end
    end
    return result
end

function OTLGM:QueueModerationSummary183(target, reason, preparedSummary)
    if not self:IsOfficerMode() or not self:IsModerationReconciliationPeer183(target) then return false end
    local runtime = ReconciliationRuntime183(self)
    local key = Normalize183(self, target)
    local peer = ReconciliationPeer183(self, runtime, key)
    local session = self:NextModerationId183("S")
    local summary = type(preparedSummary) == "table" and preparedSummary or BuildModerationSummary183(self, target)
    local payload = table.concat({
        "M1", "MSUM", session, "1", tostring(summary.activeWarnings), tostring(summary.warningCount),
        tostring(summary.warningHash), tostring(summary.openCases), tostring(summary.caseCount), tostring(summary.caseHash),
        summary.warningBucketText, summary.caseBucketText,
    }, "^")
    peer.state = "SYNCING"
    peer.localSession = session
    peer.lastSummaryQueuedAt = self:Now()
    peer.lastSummaryReason = tostring(reason or "state")
    peer.localSummary = summary
    return QueueModerationReconciliationPacket183(self, payload, target,
        "moderation:reconcile:summary:" .. key)
end

function OTLGM:ModerationStateChanged183(reason)
    if not self:IsOfficerMode() then return 0 end
    local peers = self:GetModerationReconciliationPeers183(MAX_RECONCILIATION_PEERS_183)
    if table.getn(peers) == 0 then return 0 end
    -- RC4 privacy: each Leadership peer receives only the moderation state
    -- that peer is permitted to know about. Moderation mutations are rare, so
    -- privacy/correctness takes priority over one universal shared summary.
    local index, queued = 1, 0
    for index = 1, table.getn(peers) do
        if self:QueueModerationSummary183(peers[index], reason) then queued = queued + 1 end
    end
    return queued
end

function OTLGM:GetModerationReconciliationState183()
    if not self:IsOfficerMode() then return "MEMBER", 0 end
    local peers = self:GetModerationReconciliationPeers183(MAX_RECONCILIATION_PEERS_183)
    if table.getn(peers) == 0 then return "LOCAL", 0 end
    local runtime = ReconciliationRuntime183(self)
    local index, peer
    for index = 1, table.getn(peers) do
        peer = runtime.peers[Normalize183(self, peers[index])]
        if type(peer) ~= "table" or peer.state ~= "READY" then return "SYNCING", table.getn(peers) end
    end
    return "READY", table.getn(peers)
end

function OTLGM:BeginModerationReconciliation183(sender, version)
    if not self:IsOfficerMode() or not self:IsModerationReconciliationPeer183(sender, version) then return false end
    local runtime = ReconciliationRuntime183(self)
    local key, now = Normalize183(self, sender), self:Now()
    local peer = ReconciliationPeer183(self, runtime, key)
    if now - (tonumber(peer.lastPresenceAt) or 0) < 5 then return false end
    peer.lastPresenceAt = now
    peer.state = "SYNCING"
    return self:QueueModerationSummary183(sender, "leadership-presence")
end

local function ReconciliationEntry183(recordType, id, record)
    local state = recordType == "W" and WarningState183(record) or CaseState183(record)
    return table.concat({ tostring(id), tostring(math.max(1, tonumber(record.revision) or 1)), state,
        tostring(math.max(0, tonumber(record.updatedAt) or 0)), tostring(ModerationRecordDigest183(recordType, record)) }, ",")
end

local function ReconciliationBucketRows183(owner, recordType, bucket, target)
    local state = owner:EnsureModeration183()
    local map = recordType == "W" and state and state.officerWarnings or state and state.officerCases
    local rows, id, record = {}, nil, nil
    for id, record in pairs(map or {}) do
        if type(record) == "table" and math.mod(NameHash183(id), RECONCILIATION_BUCKETS_183) + 1 == bucket
            and owner:CanPeerReceiveModerationRecord183(target, recordType, record) then
            table.insert(rows, { id = id, record = record,
                priority = recordType == "W" and (record.active == true and 0 or 1)
                    or (not TERMINAL_REPORT_STATUSES_183[record.status or "NEW"] and 0 or 1) })
        end
    end
    table.sort(rows, function(left, right)
        if left.priority ~= right.priority then return left.priority < right.priority end
        local leftUpdated, rightUpdated = tonumber(left.record.updatedAt) or 0, tonumber(right.record.updatedAt) or 0
        if leftUpdated ~= rightUpdated then return leftUpdated > rightUpdated end
        return tostring(left.id) < tostring(right.id)
    end)
    return rows
end

local function QueueReconciliationIndex183(owner, target, session, recordType, bucket, offset)
    local runtime, peerKey = ReconciliationRuntime183(owner), Normalize183(owner, target)
    offset = math.max(1, tonumber(offset) or 1)
    local indexState = runtime.indexes[peerKey]
    if offset == 1 or type(indexState) ~= "table" or indexState.session ~= session
        or indexState.recordType ~= recordType or indexState.bucket ~= bucket then
        indexState = { session = session, recordType = recordType, bucket = bucket,
            rows = ReconciliationBucketRows183(owner, recordType, bucket, target), updatedAt = owner:Now() }
        runtime.indexes[peerKey] = indexState
    else
        indexState.updatedAt = owner:Now()
    end
    local rows = indexState.rows
    local entries, index = {}, offset
    for index = offset, math.min(table.getn(rows), offset + RECONCILIATION_PAGE_183 - 1) do
        table.insert(entries, ReconciliationEntry183(recordType, rows[index].id, rows[index].record))
    end
    local nextOffset = offset + table.getn(entries)
    if nextOffset > table.getn(rows) then nextOffset = 0 end
    local payload = table.concat({ "M1", "MIDX", session, "1", recordType, tostring(bucket),
        tostring(offset), tostring(nextOffset), table.concat(entries, "~") }, "^")
    local queued = QueueModerationReconciliationPacket183(owner, payload, target,
        "moderation:reconcile:index:" .. Normalize183(owner, target) .. ":" .. session .. ":"
            .. recordType .. ":" .. tostring(bucket) .. ":" .. tostring(offset))
    if nextOffset == 0 then runtime.indexes[peerKey] = nil end
    return queued
end

local function QueueReconciliationAck183(owner, target, session, recordType, id, revision, result)
    local payload = table.concat({ "M1", "MACK", session, "1", recordType, tostring(id or "ALL"),
        tostring(math.max(1, tonumber(revision) or 1)), tostring(result or "OK") }, "^")
    return QueueModerationReconciliationPacket183(owner, payload, target,
        "moderation:reconcile:ack:" .. Normalize183(owner, target) .. ":" .. session .. ":"
            .. recordType .. ":" .. tostring(id or "ALL"))
end

local function QueueWarningReconciliationRecord183(owner, warning, target, session)
    if type(warning) ~= "table" then return false end
    local active = warning.active == true
    local reasonParts = active and ChunkText183(owner,
        SafeWireText183(owner, warning.reason or "", MAX_WARNING_REASON_183), REPORT_CHUNK_183) or {}
    local commentParts = active and ChunkText183(owner,
        SafeWireText183(owner, warning.privateComment or "", MAX_PRIVATE_COMMENT_183), REPORT_CHUNK_183) or {}
    local packetCount = 1 + table.getn(reasonParts) + table.getn(commentParts)
    if owner.CanQueueNetworkPayloads and not owner:CanQueueNetworkPayloads(packetCount, 24) then return false end
    local id, revision = tostring(warning.id), math.max(1, tonumber(warning.revision) or 1)
    local baseKey = "moderation:reconcile:warning:" .. Normalize183(owner, target) .. ":" .. id .. ":" .. tostring(revision)
    local header = table.concat({ "M1", "MWARN", id, tostring(revision), session,
        tostring(math.max(1, tonumber(warning.issuedAt) or owner:Now())),
        tostring(math.max(1, tonumber(warning.updatedAt) or owner:Now())),
        SafeWireText183(owner, warning.target or "", 32), SafeWireText183(owner, warning.issuer or "Leadership", 32),
        tostring(warning.category or "OTHER"), active and "1" or "0",
        tostring(math.max(1, math.min(2, tonumber(warning.announcedCount) or 1))),
        warning.acknowledged and "1" or "0", tostring(math.max(0, tonumber(warning.acknowledgedAt) or 0)),
        tostring(warning.clearReason or ""), tostring(math.max(0, tonumber(warning.clearedAt) or 0)),
        SafeWireText183(owner, warning.relatedCaseId183 or "", 24),
        tostring(table.getn(reasonParts)), tostring(table.getn(commentParts)),
    }, "^")
    if not QueueModerationReconciliationPacket183(owner, header, target, baseKey .. ":header") then return false end
    local index, payload
    for index = 1, table.getn(reasonParts) do
        payload = table.concat({ "M1", "MWTEXT", id, tostring(revision), session, "R", tostring(index),
            tostring(table.getn(reasonParts)), reasonParts[index] }, "^")
        if not QueueModerationReconciliationPacket183(owner, payload, target, baseKey .. ":reason:" .. tostring(index)) then return false end
    end
    for index = 1, table.getn(commentParts) do
        payload = table.concat({ "M1", "MWTEXT", id, tostring(revision), session, "P", tostring(index),
            tostring(table.getn(commentParts)), commentParts[index] }, "^")
        if not QueueModerationReconciliationPacket183(owner, payload, target, baseKey .. ":comment:" .. tostring(index)) then return false end
    end
    return true
end

local function QueueCaseReconciliationRecord183(owner, case, target, session)
    if type(case) ~= "table" or not owner:CanPeerReceiveModerationRecord183(target, "C", case) then return false end
    local open = not TERMINAL_REPORT_STATUSES_183[case.status or "NEW"]
    local textParts = open and ChunkText183(owner, SafeWireText183(owner, case.text or "", MAX_REPORT_TEXT_183), REPORT_CHUNK_183) or {}
    local diagnosticParts = open and ChunkText183(owner, SafeWireText183(owner, case.diagnostics or "", MAX_DIAGNOSTICS_183), DIAGNOSTIC_CHUNK_183) or {}
    local responseParts = open and ChunkText183(owner, SafeWireText183(owner,
        CaseLatestText183(case, "REPLY", "latestResponse183"), MAX_RESPONSE_183), REPORT_CHUNK_183) or {}
    local followupParts = open and ChunkText183(owner, SafeWireText183(owner,
        CaseLatestText183(case, "FOLLOWUP", "latestFollowup183"), MAX_RESPONSE_183), REPORT_CHUNK_183) or {}
    local commentParts = open and ChunkText183(owner, SafeWireText183(owner,
        case.privateComment or "", MAX_PRIVATE_COMMENT_183), REPORT_CHUNK_183) or {}
    local reasonParts = ChunkText183(owner, SafeWireText183(owner, case.statusReason183 or "", MAX_STATUS_REASON_183), REPORT_CHUNK_183)
    local timelineText = SerializeCaseTimeline183(case)
    local timelineParts = timelineText ~= "" and ChunkText183(owner, timelineText, REPORT_CHUNK_183) or {}
    local packetCount = 1 + table.getn(textParts) + table.getn(diagnosticParts) + table.getn(responseParts)
        + table.getn(followupParts) + table.getn(commentParts) + table.getn(reasonParts) + table.getn(timelineParts)
    if owner.CanQueueNetworkPayloads and not owner:CanQueueNetworkPayloads(packetCount, 24) then return false end
    local id, revision = tostring(case.id), math.max(1, tonumber(case.revision) or 1)
    local baseKey = "moderation:reconcile:case:" .. Normalize183(owner, target) .. ":" .. id .. ":" .. tostring(revision)
    local header = table.concat({ "M1", "MCASE", id, tostring(revision), session,
        tostring(math.max(1, tonumber(case.sourceRevision) or 1)), tostring(math.max(1, tonumber(case.createdAt) or owner:Now())),
        tostring(math.max(1, tonumber(case.updatedAt) or owner:Now())), SafeWireText183(owner, case.author or "", 32),
        SafeWireText183(owner, case.target or "", 32), tostring(case.reportType or "PLAYER"),
        tostring(case.category or "OTHER"), tostring(case.status or "NEW"),
        tostring(case.privacyScope or CASE_SCOPE_LEADERSHIP_183), SafeWireText183(owner, case.assignedTo183 or "", 32),
        SafeWireText183(owner, case.relatedCaseId183 or "", 24), SafeWireText183(owner, case.caseKind183 or "REPORT", 16),
        tostring(table.getn(textParts)), tostring(table.getn(diagnosticParts)), tostring(table.getn(responseParts)),
        tostring(table.getn(followupParts)), tostring(table.getn(commentParts)), tostring(table.getn(reasonParts)),
        tostring(table.getn(timelineParts)),
    }, "^")
    if not QueueModerationReconciliationPacket183(owner, header, target, baseKey .. ":header") then return false end
    local groups = { { "T", textParts }, { "D", diagnosticParts }, { "R", responseParts },
        { "F", followupParts }, { "P", commentParts }, { "S", reasonParts }, { "L", timelineParts } }
    local groupIndex, index, payload, group
    for groupIndex = 1, table.getn(groups) do
        group = groups[groupIndex]
        for index = 1, table.getn(group[2]) do
            payload = table.concat({ "M1", "MCTEXT", id, tostring(revision), session, group[1], tostring(index),
                tostring(table.getn(group[2])), group[2][index] }, "^")
            if not QueueModerationReconciliationPacket183(owner, payload, target,
                baseKey .. ":" .. group[1] .. ":" .. tostring(index)) then return false end
        end
    end
    return true
end

local function ShouldRequestReconciliationRecord183(owner, recordType, incoming)
    local state = owner:EnsureModeration183()
    local map = recordType == "W" and state and state.officerWarnings or state and state.officerCases
    local current = map and map[incoming.id]
    if type(current) ~= "table" then return true end
    local incomingRevision, currentRevision = tonumber(incoming.revision) or 0, tonumber(current.revision) or 0
    if incomingRevision ~= currentRevision then return incomingRevision > currentRevision end
    if recordType == "W" then
        if incoming.state == "0" and current.active == true then return true end
        if incoming.state == "1" and current.active ~= true then return false end
    end
    local incomingUpdated, currentUpdated = tonumber(incoming.updatedAt) or 0, tonumber(current.updatedAt) or 0
    if incomingUpdated ~= currentUpdated then return incomingUpdated > currentUpdated end
    return (tonumber(incoming.digest) or 0) > ModerationRecordDigest183(recordType, current)
end

local function RequestNextReconciliationBucket183(owner, sender, flow)
    if type(flow) ~= "table" or flow.current or table.getn(flow.queue or {}) == 0 then return false end
    flow.current = table.remove(flow.queue, 1)
    local request = flow.current
    local payload = table.concat({ "M1", "MREQ", flow.session, "1", "I", request.recordType,
        tostring(request.bucket), "1" }, "^")
    return QueueModerationReconciliationPacket183(owner, payload, sender,
        "moderation:reconcile:request-index:" .. Normalize183(owner, sender) .. ":" .. flow.session .. ":"
            .. request.recordType .. ":" .. tostring(request.bucket))
end

local function ReconciliationPendingCount183(flow)
    local count, key = 0, nil
    for key in pairs(type(flow) == "table" and flow.pending or {}) do count = count + 1 end
    return count
end

local function FlushModerationReconciliationViews183(owner, runtime, reason)
    runtime = runtime or ReconciliationRuntime183(owner)
    if not runtime.viewsDirty183 then return false end
    runtime.viewsDirty183 = nil
    if owner.RefreshModerationViews183 then owner:RefreshModerationViews183(reason or "leadership-records-reconciled") end
    return true
end

local function MaybeCompleteReconciliationFlow183(owner, sender, flow)
    if type(flow) ~= "table" or flow.current or table.getn(flow.queue or {}) > 0 or ReconciliationPendingCount183(flow) > 0 then return false end
    local runtime = ReconciliationRuntime183(owner)
    runtime.flows[Normalize183(owner, sender)] = nil
    FlushModerationReconciliationViews183(owner, runtime, "leadership-records-reconciled")
    owner:QueueModerationSummary183(sender, "diff-applied")
    return true
end

local function HandleModerationSummary183(owner, fields, sender)
    local session = fields[3]
    local remote = {
        activeWarnings = tonumber(fields[5]) or 0, warningCount = tonumber(fields[6]) or 0,
        warningHash = tonumber(fields[7]) or 0, openCases = tonumber(fields[8]) or 0,
        caseCount = tonumber(fields[9]) or 0, caseHash = tonumber(fields[10]) or 0,
        warningBuckets = ParseReconciliationBuckets183(owner, fields[11]),
        caseBuckets = ParseReconciliationBuckets183(owner, fields[12]),
    }
    local runtime, key = ReconciliationRuntime183(owner), Normalize183(owner, sender)
    local peer = ReconciliationPeer183(owner, runtime, key)
    peer.remoteSummary, peer.remoteSession, peer.lastRemoteSummaryAt = remote, session, owner:Now()
    local localSummary = BuildModerationSummary183(owner, sender)
    if SummaryMatches183(localSummary, remote) then
        peer.state = "READY"
        peer.lastReconciledAt = owner:Now()
        runtime.flows[key] = nil
        QueueReconciliationAck183(owner, sender, session, "S", "ALL", 1, "OK")
        runtime.viewsDirty183 = nil
        if owner.RefreshModerationViews183 then owner:RefreshModerationViews183("leadership-reconciled") end
        return true
    end
    peer.state = "SYNCING"
    local flow = { session = session, queue = {}, pending = {}, startedAt = owner:Now(), updatedAt = owner:Now() }
    local localWarningBuckets = ParseReconciliationBuckets183(owner, localSummary.warningBucketText)
    local localCaseBuckets = ParseReconciliationBuckets183(owner, localSummary.caseBucketText)
    local index
    if localSummary.warningCount ~= remote.warningCount or localSummary.warningHash ~= remote.warningHash then
        for index = 1, RECONCILIATION_BUCKETS_183 do
            if localWarningBuckets[index] ~= remote.warningBuckets[index] then
                table.insert(flow.queue, { recordType = "W", bucket = index })
            end
        end
    end
    if localSummary.caseCount ~= remote.caseCount or localSummary.caseHash ~= remote.caseHash then
        for index = 1, RECONCILIATION_BUCKETS_183 do
            if localCaseBuckets[index] ~= remote.caseBuckets[index] then
                table.insert(flow.queue, { recordType = "C", bucket = index })
            end
        end
    end
    runtime.flows[key] = flow
    if table.getn(flow.queue) == 0 then
        -- Extremely unlikely aggregate-hash collision: request every bucket so
        -- the deterministic record rule can still converge.
        for index = 1, RECONCILIATION_BUCKETS_183 do
            table.insert(flow.queue, { recordType = "W", bucket = index })
            table.insert(flow.queue, { recordType = "C", bucket = index })
        end
    end
    RequestNextReconciliationBucket183(owner, sender, flow)
    return true
end

local function HandleModerationReconciliationRequest183(owner, fields, sender)
    local session, mode, recordType = fields[3], fields[5], fields[6]
    if mode == "I" then
        return QueueReconciliationIndex183(owner, sender, session, recordType, tonumber(fields[7]), tonumber(fields[8]))
    end
    local ids = owner:Split(tostring(fields[7] or ""), ",")
    local state, index, id, record = owner:EnsureModeration183(), 1, nil, nil
    for index = 1, math.min(RECONCILIATION_PAGE_183, table.getn(ids)) do
        id = ids[index]
        record = recordType == "W" and state and state.officerWarnings[id] or state and state.officerCases[id]
        if type(record) ~= "table" or not owner:CanPeerReceiveModerationRecord183(sender, recordType, record) then
            -- A pruned or privacy-excluded row is never disclosed.
            QueueReconciliationAck183(owner, sender, session, recordType, id, 1, "OK")
        else
            local queued = recordType == "W" and QueueWarningReconciliationRecord183(owner, record, sender, session)
                or QueueCaseReconciliationRecord183(owner, record, sender, session)
            if not queued then QueueReconciliationAck183(owner, sender, session, recordType, id,
                record.revision or 1, "BUSY") end
        end
    end
    return true
end

local function HandleModerationReconciliationIndex183(owner, fields, sender)
    local runtime, key = ReconciliationRuntime183(owner), Normalize183(owner, sender)
    local flow = runtime.flows[key]
    local session, recordType, bucket = fields[3], fields[5], tonumber(fields[6])
    local offset, nextOffset = tonumber(fields[7]) or 1, tonumber(fields[8]) or 0
    if type(flow) ~= "table" or flow.session ~= session or type(flow.current) ~= "table"
        or flow.current.recordType ~= recordType or flow.current.bucket ~= bucket then return true end
    flow.updatedAt = owner:Now()
    local entries = fields[9] ~= "" and owner:Split(fields[9], "~") or {}
    local requested, index, values, incoming = {}, 1, nil, nil
    for index = 1, table.getn(entries) do
        values = owner:Split(entries[index], ",")
        incoming = { id = values[1], revision = tonumber(values[2]), state = values[3],
            updatedAt = tonumber(values[4]), digest = tonumber(values[5]) }
        if ShouldRequestReconciliationRecord183(owner, recordType, incoming) then
            table.insert(requested, incoming.id)
            flow.pending[recordType .. ":" .. incoming.id] = true
        end
    end
    if table.getn(requested) > 0 then
        local payload = table.concat({ "M1", "MREQ", session, "1", "R", recordType,
            table.concat(requested, ","), "0" }, "^")
        QueueModerationReconciliationPacket183(owner, payload, sender,
            "moderation:reconcile:request-record:" .. key .. ":" .. session .. ":" .. recordType .. ":" .. tostring(offset))
    end
    if nextOffset > 0 then
        local payload = table.concat({ "M1", "MREQ", session, "1", "I", recordType,
            tostring(bucket), tostring(nextOffset) }, "^")
        QueueModerationReconciliationPacket183(owner, payload, sender,
            "moderation:reconcile:request-index:" .. key .. ":" .. session .. ":" .. recordType .. ":"
                .. tostring(bucket) .. ":" .. tostring(nextOffset))
    else
        flow.current = nil
        RequestNextReconciliationBucket183(owner, sender, flow)
        MaybeCompleteReconciliationFlow183(owner, sender, flow)
    end
    return true
end

local function ReconciliationTransfer183(owner, sender, recordType, id, revision, session)
    local runtime = ReconciliationRuntime183(owner)
    local count, transferKey, candidate = 0, nil, nil
    for transferKey, candidate in pairs(runtime.transfers) do
        if type(candidate) ~= "table" or owner:Now() - (tonumber(candidate.updatedAt) or 0) > RECONCILIATION_TTL_183 then
            runtime.transfers[transferKey] = nil
        else count = count + 1 end
    end
    while count >= MAX_RECONCILIATION_TRANSFERS_183 do
        local oldestKey, oldestAt = nil, nil
        for transferKey, candidate in pairs(runtime.transfers) do
            local timestamp = tonumber(candidate.updatedAt) or 0
            if not oldestAt or timestamp < oldestAt then oldestKey, oldestAt = transferKey, timestamp end
        end
        if not oldestKey then break end
        runtime.transfers[oldestKey] = nil
        count = count - 1
    end
    local key = Normalize183(owner, sender) .. ":" .. recordType .. ":" .. tostring(id)
    local transfer = runtime.transfers[key]
    if type(transfer) ~= "table" or tonumber(transfer.revision) ~= tonumber(revision) or transfer.session ~= session then
        transfer = { recordType = recordType, id = id, revision = revision, session = session,
            parts = { T = {}, D = {}, R = {}, F = {}, P = {}, S = {}, L = {} }, createdAt = owner:Now() }
        runtime.transfers[key] = transfer
    end
    transfer.updatedAt = owner:Now()
    return transfer, key, runtime
end

local function HasReconciliationParts183(parts, total)
    local index
    for index = 1, tonumber(total) or 0 do if type(parts[index]) ~= "string" then return false end end
    return true
end

local function IncomingReconciliationWins183(recordType, current, revision, updatedAt, incomingState, incomingDigest)
    if type(current) ~= "table" then return true end
    local currentRevision = tonumber(current.revision) or 0
    if tonumber(revision) ~= currentRevision then return tonumber(revision) > currentRevision end
    if recordType == "W" then
        if incomingState == "0" and current.active == true then return true end
        if incomingState == "1" and current.active ~= true then return false end
    end
    local currentUpdated = tonumber(current.updatedAt) or 0
    if tonumber(updatedAt) ~= currentUpdated then return tonumber(updatedAt) > currentUpdated end
    return (tonumber(incomingDigest) or 0) > ModerationRecordDigest183(recordType, current)
end

local function FinishReconciliationRecord183(owner, transfer, key, runtime, sender)
    if not transfer.header then return false end
    local codes, index = { "T", "D", "R", "F", "P", "S", "L" }, 1
    for index = 1, table.getn(codes) do
        if not HasReconciliationParts183(transfer.parts[codes[index]], transfer.totals[codes[index]] or 0) then return false end
    end
    local state = owner:EnsureModeration183()
    local map = transfer.recordType == "W" and state.officerWarnings or state.officerCases
    local current = map[transfer.id]
    local applied = false
    if transfer.recordType == "W" then
        local incoming = {
            id = transfer.id, revision = transfer.revision, issuedAt = transfer.issuedAt, updatedAt = transfer.recordUpdatedAt,
            target = transfer.target, issuer = transfer.issuer, category = transfer.category,
            active = transfer.active == "1", announcedCount = transfer.announcedCount,
            acknowledged = transfer.acknowledged == "1", acknowledgedAt = transfer.acknowledgedAt > 0 and transfer.acknowledgedAt or nil,
            clearReason = transfer.clearReason ~= "" and transfer.clearReason or nil,
            clearedAt = transfer.clearedAt > 0 and transfer.clearedAt or nil, relatedCaseId183 = transfer.relatedCaseId183 or "",
            reason = table.concat(transfer.parts.R, ""), privateComment = table.concat(transfer.parts.P, ""),
        }
        local digest = ModerationRecordDigest183("W", incoming)
        if IncomingReconciliationWins183("W", current, incoming.revision, incoming.updatedAt,
            incoming.active and "1" or "0", digest) then
            if type(current) == "table" and not incoming.active then
                if incoming.reason == "" then incoming.reason = current.reason end
                if incoming.privateComment == "" then incoming.privateComment = current.privateComment end
            end
            map[transfer.id] = incoming
            applied = true
        end
    else
        local incoming = {
            id = transfer.id, revision = transfer.revision, sourceRevision = transfer.sourceRevision,
            createdAt = transfer.recordCreatedAt, updatedAt = transfer.recordUpdatedAt,
            author = transfer.author, target = transfer.target, reportType = transfer.reportType,
            category = transfer.category, status = transfer.status,
            privacyScope = transfer.privacyScope or CASE_SCOPE_LEADERSHIP_183,
            assignedTo183 = transfer.assignedTo183 or "", relatedCaseId183 = transfer.relatedCaseId183 or "",
            caseKind183 = transfer.caseKind183 or "REPORT", statusReason183 = table.concat(transfer.parts.S, ""),
            text = table.concat(transfer.parts.T, ""), diagnostics = table.concat(transfer.parts.D, ""),
            latestResponse183 = table.concat(transfer.parts.R, ""), latestFollowup183 = table.concat(transfer.parts.F, ""),
            privateComment = table.concat(transfer.parts.P, ""), timeline = ParseCaseTimeline183(owner, table.concat(transfer.parts.L, "")),
        }
        local digest = ModerationRecordDigest183("C", incoming)
        local currentWithdrawnR30 = type(current) == "table" and current.status == "WITHDRAWN"
        local incomingWithdrawnR30 = incoming.status == "WITHDRAWN"
        local reconciliationWinsR30 = (incomingWithdrawnR30 and not currentWithdrawnR30)
            or ((not currentWithdrawnR30 or incomingWithdrawnR30)
                and IncomingReconciliationWins183("C", current, incoming.revision, incoming.updatedAt, incoming.status, digest))
        if reconciliationWinsR30 then
            if type(current) == "table" and TERMINAL_REPORT_STATUSES_183[incoming.status] then
                if incoming.text == "" then incoming.text = current.text end
                if incoming.diagnostics == "" then incoming.diagnostics = current.diagnostics end
                if incoming.latestResponse183 == "" then incoming.latestResponse183 = CaseLatestText183(current, "REPLY", "latestResponse183") end
                if incoming.latestFollowup183 == "" then incoming.latestFollowup183 = CaseLatestText183(current, "FOLLOWUP", "latestFollowup183") end
                if incoming.privateComment == "" then incoming.privateComment = current.privateComment end
                if table.getn(incoming.timeline or {}) == 0 then incoming.timeline = type(current.timeline) == "table" and current.timeline or {} end
            end
            -- Do not append a technical reconciliation event to the shared
            -- timeline. The received canonical record must remain byte-logically
            -- equivalent to the sender after convergence.
            map[transfer.id] = incoming
            applied = true
        end
    end
    runtime.transfers[key] = nil
    if applied then runtime.viewsDirty183 = true end
    PruneModerationState183(owner, state)
    QueueReconciliationAck183(owner, sender, transfer.session, transfer.recordType, transfer.id, transfer.revision, "OK")
    local flow = runtime.flows[Normalize183(owner, sender)]
    if type(flow) == "table" and flow.session == transfer.session then
        flow.pending[transfer.recordType .. ":" .. transfer.id] = nil
        MaybeCompleteReconciliationFlow183(owner, sender, flow)
    elseif applied then
        FlushModerationReconciliationViews183(owner, runtime, "leadership-record-reconciled")
    end
    return true
end

local function HandleModerationWarningRecord183(owner, fields, sender)
    if Normalize183(owner, fields[8] or "") == Normalize183(owner, PlayerName183()) then return true end
    local transfer, key, runtime = ReconciliationTransfer183(owner, sender, "W", fields[3], tonumber(fields[4]), fields[5])
    local flow = runtime.flows[Normalize183(owner, sender)]
    if type(flow) == "table" and flow.session == fields[5] then flow.updatedAt = owner:Now() end
    transfer.header = true
    transfer.issuedAt, transfer.recordUpdatedAt = tonumber(fields[6]) or owner:Now(), tonumber(fields[7]) or owner:Now()
    transfer.target, transfer.issuer, transfer.category = fields[8] or "", fields[9] or "Leadership", fields[10] or "OTHER"
    transfer.active, transfer.announcedCount = fields[11] or "0", tonumber(fields[12]) or 1
    transfer.acknowledged, transfer.acknowledgedAt = fields[13] or "0", tonumber(fields[14]) or 0
    transfer.clearReason, transfer.clearedAt = fields[15] or "", tonumber(fields[16]) or 0
    transfer.relatedCaseId183 = fields[17] or ""
    transfer.totals = { R = tonumber(fields[18]) or 0, P = tonumber(fields[19]) or 0, T = 0, D = 0, F = 0, S = 0, L = 0 }
    return FinishReconciliationRecord183(owner, transfer, key, runtime, sender) or true
end

local function HandleModerationCaseRecord183(owner, fields, sender)
    local incomingScope = fields[14] or CASE_SCOPE_LEADERSHIP_183
    if Normalize183(owner, fields[10] or "") == Normalize183(owner, PlayerName183()) then return true end
    if incomingScope == CASE_SCOPE_GUILD_LEADER_183 and (not owner.IsGuildLeader170 or not owner:IsGuildLeader170()) then return true end
    if incomingScope == CASE_SCOPE_EXTERNAL_183 then return true end
    local transfer, key, runtime = ReconciliationTransfer183(owner, sender, "C", fields[3], tonumber(fields[4]), fields[5])
    local flow = runtime.flows[Normalize183(owner, sender)]
    if type(flow) == "table" and flow.session == fields[5] then flow.updatedAt = owner:Now() end
    transfer.header = true
    transfer.sourceRevision, transfer.recordCreatedAt, transfer.recordUpdatedAt = tonumber(fields[6]) or 1,
        tonumber(fields[7]) or owner:Now(), tonumber(fields[8]) or owner:Now()
    transfer.author, transfer.target, transfer.reportType = fields[9] or "", fields[10] or "", fields[11] or "PLAYER"
    transfer.category, transfer.status = fields[12] or "OTHER", fields[13] or "NEW"
    transfer.privacyScope = fields[14] or CASE_SCOPE_LEADERSHIP_183
    transfer.assignedTo183, transfer.relatedCaseId183, transfer.caseKind183 = fields[15] or "", fields[16] or "", fields[17] or "REPORT"
    transfer.totals = { T = tonumber(fields[18]) or 0, D = tonumber(fields[19]) or 0,
        R = tonumber(fields[20]) or 0, F = tonumber(fields[21]) or 0, P = tonumber(fields[22]) or 0,
        S = tonumber(fields[23]) or 0, L = tonumber(fields[24]) or 0 }
    return FinishReconciliationRecord183(owner, transfer, key, runtime, sender) or true
end

local function HandleModerationRecordText183(owner, fields, sender, recordType)
    local runtime = ReconciliationRuntime183(owner)
    local key = Normalize183(owner, sender) .. ":" .. recordType .. ":" .. tostring(fields[3])
    local transfer = runtime.transfers[key]
    if type(transfer) ~= "table" or not transfer.header or tonumber(transfer.revision) ~= tonumber(fields[4])
        or transfer.session ~= fields[5] then return true end
    transfer.updatedAt = owner:Now()
    local flow = runtime.flows[Normalize183(owner, sender)]
    if type(flow) == "table" and flow.session == fields[5] then flow.updatedAt = owner:Now() end
    local code, sequence, total = fields[6], tonumber(fields[7]), tonumber(fields[8])
    transfer.parts[code][sequence] = fields[9] or ""
    transfer.totals = transfer.totals or {}
    transfer.totals[code] = transfer.totals[code] or total
    return FinishReconciliationRecord183(owner, transfer, key, runtime, sender) or true
end

local function HandleModerationReconciliationAck183(owner, fields, sender)
    local runtime, key = ReconciliationRuntime183(owner), Normalize183(owner, sender)
    local session, recordType, id, result = fields[3], fields[5], fields[6], fields[8]
    local flow = runtime.flows[key]
    local peer = runtime.peers[key]
    if recordType == "S" and result == "OK" and type(peer) == "table" and peer.localSession == session then
        peer.state = "READY"
        peer.lastReconciledAt = owner:Now()
        runtime.viewsDirty183 = nil
        if owner.RefreshModerationViews183 then owner:RefreshModerationViews183("leadership-reconciled-ack") end
    end
    if type(flow) == "table" and flow.session == session and recordType ~= "S" then
        flow.pending[recordType .. ":" .. id] = nil
        flow.updatedAt = owner:Now()
        if result == "BUSY" then
            -- Avoid an immediate request/response loop against a full queue.
            -- Presence, a state mutation, or the next blocked warning attempt
            -- starts a fresh low-priority summary through the existing guard.
            runtime.flows[key] = nil
            if type(peer) == "table" then peer.state = "STALE" peer.lastBusyAt = owner:Now() end
            FlushModerationReconciliationViews183(owner, runtime, "leadership-reconciliation-deferred")
        else
            MaybeCompleteReconciliationFlow183(owner, sender, flow)
        end
    end
    runtime.lastAck183 = { sender = ShortName183(sender), session = session, recordType = recordType,
        id = id, result = result, ts = owner:Now() }
    return true
end

function OTLGM:QueueReportToPeer183(report, target, reason)
    if type(report) ~= "table" or not target or target == "" then return false end
    local textParts = ChunkText183(self, SafeWireText183(self, report.text or "", MAX_REPORT_TEXT_183), REPORT_CHUNK_183)
    local diagnosticText = SafeWireText183(self, report.diagnostics or "", MAX_DIAGNOSTICS_183)
    local diagnosticParts = diagnosticText ~= "" and ChunkText183(self, diagnosticText, DIAGNOSTIC_CHUNK_183) or {}
    local packetCount = 1 + table.getn(textParts) + table.getn(diagnosticParts)
    if self.CanQueueNetworkPayloads and not self:CanQueueNetworkPayloads(packetCount, 12) then return false end
    local baseKey = "moderation:report:" .. tostring(report.id) .. ":" .. Normalize183(self, target)
    local header = table.concat({
        "M1", "REPORT", tostring(report.id), tostring(math.max(1, tonumber(report.sourceRevision or report.revision) or 1)),
        tostring(math.max(1, tonumber(report.createdAt) or self:Now())), tostring(report.reportType or "PLAYER"),
        tostring(report.category or "OTHER"), SafeWireText183(self, report.target or "", 32),
        tostring(table.getn(textParts)), tostring(table.getn(diagnosticParts)),
        tostring(report.privacyScope or CASE_SCOPE_LEADERSHIP_183),
    }, "^")
    if not QueueModerationPacket183(self, header, target, baseKey .. ":header") then return false end
    local index, payload
    for index = 1, table.getn(textParts) do
        payload = table.concat({ "M1", "RTEXT", tostring(report.id), tostring(math.max(1, tonumber(report.sourceRevision or report.revision) or 1)),
            tostring(index), tostring(table.getn(textParts)), textParts[index] }, "^")
        if not QueueModerationPacket183(self, payload, target, baseKey .. ":text:" .. tostring(index)) then return false end
    end
    for index = 1, table.getn(diagnosticParts) do
        payload = table.concat({ "M1", "RDIAG", tostring(report.id), tostring(math.max(1, tonumber(report.sourceRevision or report.revision) or 1)),
            tostring(index), tostring(table.getn(diagnosticParts)), diagnosticParts[index] }, "^")
        if not QueueModerationPacket183(self, payload, target, baseKey .. ":diag:" .. tostring(index)) then return false end
    end
    report.deliveryRecipients = type(report.deliveryRecipients) == "table" and report.deliveryRecipients or {}
    report.deliveryAttempts = type(report.deliveryAttempts) == "table" and report.deliveryAttempts or {}
    local normalized = Normalize183(self, target)
    report.deliveryRecipients[normalized] = ShortName183(target)
    report.deliveryAttempts[normalized] = self:Now()
    report.lastAttemptAt = self:Now()
    report.delivery = "SENDING"
    report.updatedAt = self:Now()
    self.runtime = self.runtime or {}
    self.runtime.moderationPacketsQueued183 = (tonumber(self.runtime.moderationPacketsQueued183) or 0) + packetCount
    self.runtime.moderationLastQueueReason183 = tostring(reason or "submit")
    return true
end

local function StoreOfficerCase183(owner, report, author)
    local state = owner:EnsureModeration183()
    if not state or not owner:IsOfficerMode() then return nil, false end
    local existing = state.officerCases[report.id]
    if type(existing) == "table" then
        local incomingRevision = math.max(1, tonumber(report.sourceRevision or report.revision) or 1)
        local storedRevision = math.max(1, tonumber(existing.sourceRevision) or 1)
        local sameAuthor = Normalize183(owner, existing.author) == Normalize183(owner, author)
        local editable = (existing.status == "NEW" or existing.status == "SEEN")
        if sameAuthor and incomingRevision > storedRevision and editable then
            existing.sourceRevision = incomingRevision
            existing.reportType = report.reportType
            existing.category = report.category
            existing.target = SafeWireText183(owner, report.target or "", 32)
            existing.privacyScope = tostring(report.privacyScope or existing.privacyScope or CASE_SCOPE_LEADERSHIP_183)
            existing.text = SafeWireText183(owner, report.text or "", MAX_REPORT_TEXT_183)
            existing.diagnostics = SafeWireText183(owner, report.diagnostics or "", MAX_DIAGNOSTICS_183)
            existing.updatedAt = owner:Now()
            AppendTimeline183(owner, existing, "EDITED", ShortName183(author), "Report updated by author", existing.updatedAt,
                "edited:" .. tostring(incomingRevision))
            if owner.ModerationStateChanged183 then owner:ModerationStateChanged183("case-edited") end
            return existing, false
        end
        return existing, false
    end
    local case = {
        id = report.id, sourceRevision = math.max(1, tonumber(report.sourceRevision or report.revision) or 1), revision = 1,
        author = ShortName183(author), target = SafeWireText183(owner, report.target or "", 32),
        reportType = report.reportType, category = report.category,
        privacyScope = tostring(report.privacyScope or CASE_SCOPE_LEADERSHIP_183),
        text = SafeWireText183(owner, report.text or "", MAX_REPORT_TEXT_183),
        diagnostics = SafeWireText183(owner, report.diagnostics or "", MAX_DIAGNOSTICS_183),
        status = "NEW", statusReason183 = "", assignedTo183 = "", relatedCaseId183 = "", caseKind183 = "REPORT",
        createdAt = tonumber(report.createdAt) or owner:Now(), updatedAt = owner:Now(),
    }
    AppendTimeline183(owner, case, "CREATED", case.author, "Report submitted", case.createdAt, "created:" .. tostring(case.sourceRevision))
    state.officerCases[case.id] = case
    PruneMap183(state.officerCases, MAX_OFFICER_CASES_183, function(record)
        return not TERMINAL_REPORT_STATUSES_183[record.status or "NEW"]
    end)
    if owner.ModerationStateChanged183 then owner:ModerationStateChanged183("case-created") end
    return case, true
end

function OTLGM:CreateModerationReport183(reportType, category, target, text, attachDiagnostics)
    local definition = ReportTypeDefinition183(reportType)
    reportType = definition.key
    if not ReportCategoryValid183(reportType, category) then category = definition.categories[1][1] end
    local targetValid, resolvedTarget = self:ResolveModerationReportTarget183(reportType, target)
    if not targetValid then return false, resolvedTarget end
    target = resolvedTarget
    local privacyScope = self:ResolveModerationReportScope183(reportType, target)
    if privacyScope == CASE_SCOPE_GUILD_LEADER_183 and self.IsGuildLeader170 and self:IsGuildLeader170() then
        -- r30: when the Guild Leader is the author, a report about another
        -- Officer cannot be delivered to "the Guild Leader" because that would
        -- self-route. Send it to other validated Leadership, excluding the target.
        privacyScope = CASE_SCOPE_LEADERSHIP_183
    end
    if privacyScope == CASE_SCOPE_EXTERNAL_183 then
        return false, "A report against the Guild Leader cannot be delivered privately through the in-addon Officer system. Please use the guild's external leadership/contact channel."
    end
    text = SafeWireText183(self, text or "", MAX_REPORT_TEXT_183)
    if text == "" then return false, "Please describe the issue or suggestion." end
    local state = self:EnsureModeration183()
    if not state then return false, "Guild storage is unavailable." end
    local id = self:NextModerationId183("R")
    local now = self:Now()
    local report = {
        id = id, sourceRevision = 1, revision = 1, author = PlayerName183(), reportType = reportType,
        category = category, target = target, text = text, privacyScope = privacyScope,
        diagnostics = attachDiagnostics and reportType == "ADDON" and self:GetCompactModerationDiagnostics183() or "",
        status = "NEW", delivery = "PENDING", createdAt = now, updatedAt = now,
        deliveryRecipients = {}, deliveryAttempts = {},
    }
    AppendTimeline183(self, report, "CREATED", report.author, "Report saved locally", now, "created:1")
    state.ownReports[id] = report
    PruneMap183(state.ownReports, MAX_OWN_REPORTS_183, function(record)
        return record.delivery ~= "SUBMITTED" or not TERMINAL_REPORT_STATUSES_183[record.status or "NEW"]
    end)

    -- r30: the author never acknowledges their own report, even if this
    -- character is an Officer or Guild Leader. Delivery becomes SUBMITTED
    -- only after another validated Leadership client sends RACK.

    local peers = privacyScope == CASE_SCOPE_GUILD_LEADER_183
        and self:GetModerationGuildLeaderPeers183(1)
        or self:GetModerationLeadershipPeers183(MAX_REPORT_PEERS_183, report.target)
    local index, queued = 1, 0
    for index = 1, table.getn(peers) do
        if self:QueueReportToPeer183(report, peers[index], "new-report") then queued = queued + 1 end
    end
    if queued == 0 then report.delivery = "PENDING" end
    if self.RefreshModerationViews183 then self:RefreshModerationViews183("report-created") end
    if self.ShowToast then
        if report.delivery == "SUBMITTED" then self:ShowToast("Report submitted to Leadership.", "success")
        elseif queued > 0 then self:ShowToast("Report queued securely; waiting for Leadership acknowledgement.", "pending")
        else self:ShowToast("No compatible Leadership member is online. Your report was saved and will be delivered later.", "pending") end
    end
    return true, report
end

function OTLGM:TryDeliverPendingReports183(peerName, version)
    if not self:IsValidatedModerationLeader183(peerName, version) then return 0 end
    local state = self:EnsureModeration183()
    local now, queued, id, report = self:Now(), 0, nil, nil
    for id, report in pairs(state and state.ownReports or {}) do
        local scope = type(report) == "table" and tostring(report.privacyScope or CASE_SCOPE_LEADERSHIP_183) or ""
        local eligible = scope == CASE_SCOPE_GUILD_LEADER_183
            and self:IsModerationGuildLeaderPeer183(peerName, version)
            or (scope == CASE_SCOPE_LEADERSHIP_183 and self:IsValidatedModerationLeader183(peerName, version))
        if eligible and ((tonumber(report and report.sourceRevision) or 1) > 1 or (report and report.withdrawPendingR30))
            and not self:IsModerationAuthorControlPeerR30(peerName, version) then eligible = false end
        if type(report) == "table" and IsSelf183(self, report.author) and eligible
            and Normalize183(self, report.target) ~= Normalize183(self, peerName) then
            if report.withdrawPendingR30 then
                local payload = table.concat({ "M1", "RWITH", tostring(report.id),
                    tostring(math.max(1, tonumber(report.sourceRevision or report.revision) or 1)), tostring(now) }, "^")
                if QueueModerationPacket183(self, payload, peerName, "moderation:rwith:" .. tostring(report.id) .. ":" .. Normalize183(self, peerName)) then
                    report.withdrawPendingR30 = nil
                    queued = queued + 1
                end
            elseif not TERMINAL_REPORT_STATUSES_183[report.status or "NEW"] and report.delivery ~= "SUBMITTED" then
                report.deliveryAttempts = type(report.deliveryAttempts) == "table" and report.deliveryAttempts or {}
                local last = tonumber(report.deliveryAttempts[Normalize183(self, peerName)]) or 0
                if now - last >= PENDING_RETRY_COOLDOWN_183 and self:QueueReportToPeer183(report, peerName, "presence-retry") then
                    queued = queued + 1
                end
            end
            if queued >= 2 then break end
        end
    end
    return queued
end

local function PruneInboundAssemblies183(owner)
    owner.runtime = owner.runtime or {}
    if type(owner.runtime.moderationInbound183) ~= "table" then owner.runtime.moderationInbound183 = {} end
    local assemblies, now, count, key, transfer = owner.runtime.moderationInbound183, owner:Now(), 0, nil, nil
    for key, transfer in pairs(assemblies) do
        if type(transfer) ~= "table" or now - (tonumber(transfer.updatedAt) or 0) > 300 then assemblies[key] = nil
        else count = count + 1 end
    end
    while count >= 24 do
        local oldestKey, oldestAt = nil, nil
        for key, transfer in pairs(assemblies) do
            local timestamp = tonumber(transfer.updatedAt) or 0
            if not oldestAt or timestamp < oldestAt then oldestKey, oldestAt = key, timestamp end
        end
        if not oldestKey then break end
        assemblies[oldestKey] = nil
        count = count - 1
    end
    return assemblies
end

local function GetInboundAssembly183(owner, sender, id, revision)
    local assemblies = PruneInboundAssemblies183(owner)
    local key = Normalize183(owner, sender) .. ":" .. tostring(id)
    local transfer = assemblies[key]
    if type(transfer) ~= "table" or tonumber(transfer.sourceRevision) ~= tonumber(revision) then
        transfer = { id = id, sourceRevision = revision, sender = ShortName183(sender), text = {}, diagnostics = {}, createdAt = owner:Now() }
        assemblies[key] = transfer
    end
    transfer.updatedAt = owner:Now()
    return transfer, key, assemblies
end

local function HasAllParts183(parts, total)
    local index
    for index = 1, tonumber(total) or 0 do if type(parts[index]) ~= "string" then return false end end
    return true
end

local function QueueReportAck183(owner, case, target)
    local payload = table.concat({ "M1", "RACK", tostring(case.id), tostring(math.max(1, tonumber(case.sourceRevision) or 1)), tostring(owner:Now()) }, "^")
    return QueueModerationPacket183(owner, payload, target, "moderation:rack:" .. tostring(case.id) .. ":" .. Normalize183(owner, target))
end

local function TryFinalizeInboundReport183(owner, transfer, key, assemblies)
    if not transfer.header or not transfer.textTotal or not HasAllParts183(transfer.text, transfer.textTotal) then return false end
    if (tonumber(transfer.diagnosticTotal) or 0) > 0 and not HasAllParts183(transfer.diagnostics, transfer.diagnosticTotal) then return false end
    local report = {
        id = transfer.id, sourceRevision = transfer.sourceRevision, reportType = transfer.reportType,
        category = transfer.category, target = transfer.target, createdAt = transfer.reportCreatedAt,
        privacyScope = transfer.privacyScope or CASE_SCOPE_LEADERSHIP_183,
        text = table.concat(transfer.text, ""), diagnostics = table.concat(transfer.diagnostics, ""),
    }
    local case, created = StoreOfficerCase183(owner, report, transfer.sender)
    assemblies[key] = nil
    if case then QueueReportAck183(owner, case, transfer.sender) end
    if created then
        if owner.NotifyEvent152 then owner:NotifyEvent152("response", "MOD_REPORT:" .. tostring(case.id), "New Leadership report", "A private report is waiting for review.", "ACTION", true, "home", {
            objectType = "MOD_REPORT", objectId = case.id, section = "CASES", actionKey = "REPORT_REVIEW",
        })
        elseif owner.ShowToast then owner:ShowToast("A new private report is waiting for review.", "pending") end
    end
    return case ~= nil
end

local function HandleInboundReport183(owner, fields, sender)
    local id, revision = fields[3], tonumber(fields[4])
    local transfer, key, assemblies = GetInboundAssembly183(owner, sender, id, revision)
    transfer.header = true
    transfer.reportCreatedAt = tonumber(fields[5]) or owner:Now()
    transfer.reportType, transfer.category = fields[6], fields[7]
    transfer.target = SafeWireText183(owner, fields[8] or "", 32)
    transfer.textTotal, transfer.diagnosticTotal = tonumber(fields[9]) or 0, tonumber(fields[10]) or 0
    transfer.privacyScope = fields[11] or owner:ResolveModerationReportScope183(transfer.reportType, transfer.target)
    return TryFinalizeInboundReport183(owner, transfer, key, assemblies) or true
end

local function HandleInboundChunk183(owner, fields, sender, diagnostic)
    local id, revision = fields[3], tonumber(fields[4])
    local sequence, total = tonumber(fields[5]), tonumber(fields[6])
    local assemblies = PruneInboundAssemblies183(owner)
    local key = Normalize183(owner, sender) .. ":" .. tostring(id)
    local transfer = assemblies[key]
    if type(transfer) ~= "table" or not transfer.header or tonumber(transfer.sourceRevision) ~= tonumber(revision) then
        return true
    end
    transfer.updatedAt = owner:Now()
    local parts = diagnostic and transfer.diagnostics or transfer.text
    parts[sequence] = fields[7] or ""
    if diagnostic then transfer.diagnosticTotal = transfer.diagnosticTotal or total else transfer.textTotal = transfer.textTotal or total end
    return TryFinalizeInboundReport183(owner, transfer, key, assemblies) or true
end

local function ApplyOwnReportAck183(owner, fields, sender)
    local state = owner:EnsureModeration183()
    local report = state and state.ownReports[fields[3] or ""]
    if type(report) ~= "table" or not IsSelf183(owner, report.author) then return true end
    if IsSelf183(owner, sender) then return true end
    local ackRevision = math.max(1, tonumber(fields[4]) or 1)
    if ackRevision < math.max(1, tonumber(report.sourceRevision or report.revision) or 1) then return true end
    report.delivery = "SUBMITTED"
    report.acknowledgedAt = tonumber(fields[5]) or owner:Now()
    report.acknowledgedBy = ShortName183(sender)
    report.updatedAt = owner:Now()
    AppendTimeline183(owner, report, "ACK", "Leadership", "Submitted to Leadership", report.acknowledgedAt,
        "ack:" .. Normalize183(owner, sender) .. ":" .. tostring(fields[4]))
    return true
end

local function ApplyReportStatus183(owner, fields, sender)
    local state, id, revision = owner:EnsureModeration183(), fields[3] or "", tonumber(fields[4]) or 1
    local status, timestamp = fields[5] or "NEW", tonumber(fields[6]) or owner:Now()
    local statusReason = SafeWireText183(owner, fields[7] or "", MAX_STATUS_REASON_183)
    local report = state and state.ownReports[id]
    if type(report) == "table" and IsSelf183(owner, report.author) and report.status == "WITHDRAWN" and status ~= "WITHDRAWN" then
        return true
    end
    if type(report) == "table" and IsSelf183(owner, report.author) and revision >= (tonumber(report.remoteRevision) or 0) then
        report.remoteRevision = revision
        report.status = status
        report.statusReason183 = statusReason
        report.delivery = "SUBMITTED"
        report.updatedAt = timestamp
        local publicStatusText = ReportStatusLabel183(status)
        if statusReason ~= "" then publicStatusText = publicStatusText .. " — " .. statusReason end
        AppendTimeline183(owner, report, "STATUS", "Leadership", publicStatusText, timestamp, "status:" .. tostring(revision) .. ":" .. status)
        if owner.NotifyEvent152 then owner:NotifyEvent152("response", "MOD_STATUS:" .. id .. ":" .. tostring(revision), "Report updated", ReportStatusLabel183(status), status == "WAITING" and "ACTION" or "NORMAL", true, "home", {
            objectType = "MOD_REPORT", objectId = id, section = "REPORTS", actionKey = status == "WAITING" and "REPORT_FOLLOWUP" or "REPORT_UPDATE",
        }) end
    end
    local case = state and state.officerCases[id]
    if type(case) == "table" and revision >= (tonumber(case.revision) or 0) then
        case.revision, case.status, case.updatedAt = revision, status, timestamp
        case.statusReason183 = statusReason
        local peerStatusText = ReportStatusLabel183(status)
        if statusReason ~= "" then peerStatusText = peerStatusText .. " — " .. statusReason end
        AppendTimeline183(owner, case, "STATUS", ShortName183(sender), peerStatusText, timestamp,
            "status:" .. tostring(revision) .. ":" .. status)
        if owner.ModerationStateChanged183 then owner:ModerationStateChanged183("peer-case-status") end
    end
    return true
end

local function ApplyReportReply183(owner, fields, sender)
    local state, id, revision = owner:EnsureModeration183(), fields[3] or "", tonumber(fields[4]) or 1
    local timestamp, response = tonumber(fields[5]) or owner:Now(), SafeWireText183(owner, fields[6] or "", MAX_RESPONSE_183)
    local eventKey = "reply:" .. tostring(revision) .. ":" .. tostring(timestamp) .. ":" .. Normalize183(owner, sender)
    local report = state and state.ownReports[id]
    if type(report) == "table" and IsSelf183(owner, report.author) then
        report.remoteRevision = math.max(tonumber(report.remoteRevision) or 0, revision)
        report.delivery = "SUBMITTED" report.updatedAt = timestamp
        AppendTimeline183(owner, report, "REPLY", "Leadership", response, timestamp, eventKey)
        if owner.NotifyEvent152 then owner:NotifyEvent152("response", "MOD_REPLY:" .. id .. ":" .. tostring(revision), "Leadership replied to your report", "Open Reports to read the private response.", "ACTION", true, "home", {
            objectType = "MOD_REPORT", objectId = id, section = "REPORTS", actionKey = "REPORT_UPDATE",
        }) end
    end
    local case = state and state.officerCases[id]
    if type(case) == "table" then
        case.revision = math.max(tonumber(case.revision) or 0, revision) case.updatedAt = timestamp
        case.latestResponse183 = response
        AppendTimeline183(owner, case, "REPLY", ShortName183(sender), response, timestamp, eventKey)
        if owner.ModerationStateChanged183 then owner:ModerationStateChanged183("peer-case-reply") end
    end
    return true
end

local function ApplyReportFollowup183(owner, fields, sender)
    local state, id = owner:EnsureModeration183(), fields[3] or ""
    local case = state and state.officerCases[id]
    if type(case) ~= "table" or Normalize183(owner, case.author) ~= Normalize183(owner, sender) then return true end
    local timestamp, text = tonumber(fields[5]) or owner:Now(), SafeWireText183(owner, fields[6] or "", MAX_RESPONSE_183)
    case.updatedAt = timestamp
    AppendTimeline183(owner, case, "FOLLOWUP", case.author, text, timestamp,
        "followup:" .. tostring(fields[4]) .. ":" .. tostring(timestamp))
    if case.status == "WAITING" then case.status = "REVIEW" case.revision = math.max(tonumber(case.revision) or 1, tonumber(fields[4]) or 1) + 1 end
    case.latestFollowup183 = text
    if owner.ModerationStateChanged183 then owner:ModerationStateChanged183("case-followup") end
    return true
end

local function ApplyReportWithdrawR30(owner, fields, sender)
    local state = owner:EnsureModeration183()
    local id, revision = fields[3] or "", math.max(1, tonumber(fields[4]) or 1)
    local timestamp = tonumber(fields[5]) or owner:Now()
    local case = state and state.officerCases[id]
    if type(case) ~= "table" or Normalize183(owner, case.author) ~= Normalize183(owner, sender) then return true end
    if revision < math.max(1, tonumber(case.sourceRevision) or 1) then return true end
    if TERMINAL_REPORT_STATUSES_183[case.status or "NEW"] then return true end
    case.sourceRevision = math.max(math.max(1, tonumber(case.sourceRevision) or 1), revision)
    case.revision = math.max(1, tonumber(case.revision) or 1) + 1
    case.status = "WITHDRAWN"
    case.statusReason183 = "Withdrawn by author"
    case.updatedAt = timestamp
    case.assignedTo183 = ""
    AppendTimeline183(owner, case, "WITHDRAWN", case.author, "Report withdrawn by author", timestamp,
        "withdrawn:" .. tostring(revision))
    if owner.ModerationStateChanged183 then owner:ModerationStateChanged183("case-withdrawn") end
    return true
end

local function ActiveWarningCount183(map, target)
    local count, id, warning = 0, nil, nil
    local normalized = string.lower(ShortName183(target))
    for id, warning in pairs(map or {}) do
        if type(warning) == "table" and warning.active == true and string.lower(ShortName183(warning.target)) == normalized then count = count + 1 end
    end
    return count
end

function OTLGM:GetActiveWarningCount183(target, officerStore)
    local state = self:EnsureModeration183()
    local map = officerStore and state and state.officerWarnings or state and state.ownWarnings
    return ActiveWarningCount183(map, target)
end

local function StoreIncomingWarning183(owner, fields, sender)
    local state, id = owner:EnsureModeration183(), fields[3] or ""
    local revision, timestamp = tonumber(fields[4]) or 1, tonumber(fields[5]) or owner:Now()
    local target, category = SafeWireText183(owner, fields[6] or "", 32), fields[7] or "OTHER"
    local activeCount, reason = tonumber(fields[8]) or 1, SafeWireText183(owner, fields[9] or "", MAX_WARNING_REASON_183)
    local record = {
        id = id, revision = revision, issuedAt = timestamp, updatedAt = timestamp, target = target,
        issuer = ShortName183(sender), category = category, reason = reason, active = true,
        announcedCount = activeCount, acknowledged = false,
    }
    if IsSelf183(owner, target) then
        local existing = state.ownWarnings[id]
        if type(existing) == "table" and tonumber(existing.revision) > revision then return true end
        if type(existing) == "table" then record.acknowledged = existing.acknowledged record.acknowledgedAt = existing.acknowledgedAt end
        state.ownWarnings[id] = record
        PruneMap183(state.ownWarnings, MAX_OWN_WARNINGS_183, function(value) return value.active == true end)
        if owner.NotifyEvent152 then owner:NotifyEvent152("response", "MOD_WARNING:" .. id .. ":" .. tostring(revision), "Official Guild Warning", "Active warnings: " .. tostring(ActiveWarningCount183(state.ownWarnings, target)) .. "/2. Open Reports for details.", "ACTION", true, "home", {
            objectType = "MOD_WARNING", objectId = id, section = "WARNINGS", actionKey = "WARNING_ACK",
        }) end
    end
    -- RC3 Leadership peers exchange the complete officer record (including the
    -- private comment) through reconciliation.  The legacy WARNING packet is
    -- still used for the target and RC2 compatibility, but must not create a
    -- deliberately incomplete officer copy on an RC3 peer.
    if owner:IsOfficerMode() and not owner:IsModerationReconciliationPeer183(sender) then
        local existing = state.officerWarnings[id]
        if type(existing) == "table" and tonumber(existing.revision) > revision then return true end
        if type(existing) == "table" then
            record.privateComment = existing.privateComment
            record.acknowledged = existing.acknowledged record.acknowledgedAt = existing.acknowledgedAt
        end
        state.officerWarnings[id] = record
        PruneMap183(state.officerWarnings, MAX_OFFICER_WARNINGS_183, function(value) return value.active == true end)
        if owner.ModerationStateChanged183 then owner:ModerationStateChanged183("peer-warning") end
    end
    return true
end

local function ApplyWarningClear183(owner, fields, sender)
    local state, id, revision = owner:EnsureModeration183(), fields[3] or "", tonumber(fields[4]) or 1
    local timestamp, target, reason = tonumber(fields[5]) or owner:Now(), fields[6] or "", fields[7] or "DECISION"
    local maps = {}
    if IsSelf183(owner, target) then table.insert(maps, state and state.ownWarnings) end
    if owner:IsOfficerMode() and (type(state.officerWarnings[id]) == "table"
        or not owner:IsModerationReconciliationPeer183(sender)) then
        table.insert(maps, state and state.officerWarnings)
    end
    local index, warning
    for index = 1, table.getn(maps) do
        warning = maps[index] and maps[index][id]
        if type(warning) ~= "table" then
            warning = {
                id = id, revision = revision, target = SafeWireText183(owner, target, 32), issuer = ShortName183(sender or "Leadership"),
                active = false, clearReason = reason, clearedAt = timestamp, updatedAt = timestamp,
            }
            maps[index][id] = warning
        elseif Normalize183(owner, warning.target) == Normalize183(owner, target)
            and revision >= (tonumber(warning.revision) or 0) then
            warning.revision = revision warning.active = false warning.clearedAt = timestamp
            warning.clearReason = reason warning.updatedAt = timestamp
        end
        if maps[index] == state.ownWarnings then
            PruneMap183(maps[index], MAX_OWN_WARNINGS_183, function(value) return value.active == true end)
        else
            PruneMap183(maps[index], MAX_OFFICER_WARNINGS_183, function(value) return value.active == true end)
        end
    end
    if owner:IsOfficerMode() and owner.ModerationStateChanged183 then owner:ModerationStateChanged183("peer-warning-clear") end
    return true
end

local function ApplyWarningAck183(owner, fields, sender)
    local state, id = owner:EnsureModeration183(), fields[3] or ""
    local warning = state and state.officerWarnings[id]
    if type(warning) == "table" and Normalize183(owner, warning.target) == Normalize183(owner, sender)
        and not warning.acknowledged then
        warning.revision = math.max(tonumber(warning.revision) or 1, tonumber(fields[4]) or 1) + 1
        warning.acknowledged = true warning.acknowledgedAt = tonumber(fields[5]) or owner:Now()
        warning.updatedAt = warning.acknowledgedAt
        if owner.ModerationStateChanged183 then owner:ModerationStateChanged183("warning-acknowledged") end
    end
    return true
end

local function RefreshModerationAfterMessage183(owner, reason)
    owner.runtime = owner.runtime or {}
    owner.runtime.moderationMessages183 = (tonumber(owner.runtime.moderationMessages183) or 0) + 1
    if owner.RefreshModerationViews183 then owner:RefreshModerationViews183(reason) end
end

function OTLGM:HandleModerationMessage183(fields, channel, sender)
    local kind = fields and fields[2] or ""
    local handled = false
    if kind == "REPORT" then handled = HandleInboundReport183(self, fields, sender)
    elseif kind == "RTEXT" then handled = HandleInboundChunk183(self, fields, sender, false)
    elseif kind == "RDIAG" then handled = HandleInboundChunk183(self, fields, sender, true)
    elseif kind == "RACK" then handled = ApplyOwnReportAck183(self, fields, sender)
    elseif kind == "RSTATUS" then handled = ApplyReportStatus183(self, fields, sender)
    elseif kind == "RREPLY" then handled = ApplyReportReply183(self, fields, sender)
    elseif kind == "RFOLLOW" then handled = ApplyReportFollowup183(self, fields, sender)
    elseif kind == "RWITH" then handled = ApplyReportWithdrawR30(self, fields, sender)
    elseif kind == "WARNING" then handled = StoreIncomingWarning183(self, fields, sender)
    elseif kind == "WCLEAR" then handled = ApplyWarningClear183(self, fields, sender)
    elseif kind == "WACK" then handled = ApplyWarningAck183(self, fields, sender)
    elseif kind == "MSUM" then handled = HandleModerationSummary183(self, fields, sender)
    elseif kind == "MREQ" then handled = HandleModerationReconciliationRequest183(self, fields, sender)
    elseif kind == "MIDX" then handled = HandleModerationReconciliationIndex183(self, fields, sender)
    elseif kind == "MWARN" then handled = HandleModerationWarningRecord183(self, fields, sender)
    elseif kind == "MWTEXT" then handled = HandleModerationRecordText183(self, fields, sender, "W")
    elseif kind == "MCASE" then handled = HandleModerationCaseRecord183(self, fields, sender)
    elseif kind == "MCTEXT" then handled = HandleModerationRecordText183(self, fields, sender, "C")
    elseif kind == "MACK" then handled = HandleModerationReconciliationAck183(self, fields, sender) end
    if handled then
        if RECONCILIATION_MESSAGE_KINDS_183[kind] then
            self.runtime = self.runtime or {}
            self.runtime.moderationMessages183 = (tonumber(self.runtime.moderationMessages183) or 0) + 1
        else
            RefreshModerationAfterMessage183(self, "network-" .. string.lower(kind))
        end
    end
    return handled and true or false
end

local function QueueCasePacketTo183(owner, case, target, response)
    if not target or target == "" then return 0 end
    local queued = 0
    local statusPayload = table.concat({ "M1", "RSTATUS", tostring(case.id), tostring(case.revision), tostring(case.status), tostring(case.updatedAt or owner:Now()),
        SafeWireText183(owner, case.statusReason183 or "", MAX_STATUS_REASON_183) }, "^")
    if QueueModerationPacket183(owner, statusPayload, target,
        "moderation:rstatus:" .. tostring(case.id) .. ":" .. Normalize183(owner, target)) then queued = queued + 1 end
    if response and response ~= "" then
        local replyPayload = table.concat({ "M1", "RREPLY", tostring(case.id), tostring(case.revision), tostring(case.updatedAt or owner:Now()), response }, "^")
        if QueueModerationPacket183(owner, replyPayload, target,
            "moderation:rreply:" .. tostring(case.id) .. ":" .. tostring(case.revision) .. ":" .. Normalize183(owner, target)) then queued = queued + 1 end
    end
    return queued
end

function OTLGM:UpdateOfficerCase183(id, status, response, privateComment, statusReason)
    if not self:IsOfficerMode() then return false, "Officer permissions are required." end
    local state = self:EnsureModeration183()
    local case = state and state.officerCases[tostring(id or "")]
    if type(case) ~= "table" or not self:CanCurrentClientAccessModerationRecord183("C", case) then return false, "Case not found or not available on this character." end
    if case.status == "WITHDRAWN" then return false, "This report was withdrawn by its author and is read-only." end
    local validStatus = false
    local index
    for index = 1, table.getn(REPORT_STATUSES_183) do if REPORT_STATUSES_183[index][1] == status then validStatus = true break end end
    if not validStatus then status = case.status or "NEW" end
    response = SafeWireText183(self, response or "", MAX_RESPONSE_183)
    privateComment = SafeWireText183(self, privateComment or "", MAX_PRIVATE_COMMENT_183)
    local statusReasonSupplied183 = statusReason ~= nil
    statusReason = statusReasonSupplied183 and SafeWireText183(self, statusReason or "", MAX_STATUS_REASON_183)
        or tostring(case.statusReason183 or "")
    local statusChanged = status ~= (case.status or "NEW")
    local commentChanged = privateComment ~= tostring(case.privateComment or "")
    local reasonChanged = statusReasonSupplied183 and statusReason ~= tostring(case.statusReason183 or "")
    if statusChanged and status == "HOLD" and statusReason == "" then return false, "On Hold requires a short reason." end
    if statusChanged and status == "WAITING" and response == "" then return false, "Waiting for Player requires a short question or request." end
    if not statusChanged and response == "" and not commentChanged and not reasonChanged then return false, "Nothing changed." end
    case.revision = math.max(1, tonumber(case.revision) or 1) + 1
    case.updatedAt = self:Now()
    if statusChanged then
        case.status = status
        case.statusReason183 = statusReason
        local statusText = ReportStatusLabel183(status)
        if statusReason ~= "" then statusText = statusText .. " — " .. statusReason end
        AppendTimeline183(self, case, "STATUS", PlayerName183(), statusText, case.updatedAt,
            "status:" .. tostring(case.revision) .. ":" .. status)
    elseif reasonChanged then
        case.statusReason183 = statusReason
        AppendTimeline183(self, case, "STATUS_NOTE", PlayerName183(), statusReason, case.updatedAt,
            "status-note:" .. tostring(case.revision))
    end
    if response ~= "" then
        case.latestResponse183 = response
        AppendTimeline183(self, case, "REPLY", PlayerName183(), response, case.updatedAt,
            "reply:" .. tostring(case.revision) .. ":" .. tostring(case.updatedAt))
    end
    case.privateComment = privateComment

    local authorDetection = self.GetAddonDetection170 and self:GetAddonDetection170(case.author) or nil
    if authorDetection and authorDetection.state == "ACTIVE" and self:IsModerationPeer183(authorDetection.version) then
        QueueCasePacketTo183(self, case, case.author, response)
        case.authorDeliveryPending = nil case.pendingResponse183 = nil
    else
        case.authorDeliveryPending = true
        if response ~= "" then case.pendingResponse183 = { text = response, revision = case.revision, ts = case.updatedAt } end
        state.hasPendingOutbound183 = true
    end
    -- RC4 Officer-to-Officer state uses canonical reconciliation only. Direct
    -- RSTATUS/RREPLY packets are reserved for the report author; duplicating
    -- them to Leadership peers can create different local timeline keys before
    -- the canonical case record arrives.
    if self.ModerationStateChanged183 then self:ModerationStateChanged183("case-updated") end
    if self.RefreshModerationViews183 then self:RefreshModerationViews183("case-updated") end
    if self.ShowToast then self:ShowToast("Case updated. Private delivery remains targeted.", "success") end
    return true, case
end

function OTLGM:AssignOfficerCase183(id, assignee)
    if not self:IsOfficerMode() then return false, "Officer permissions are required." end
    local state = self:EnsureModeration183()
    local case = state and state.officerCases[tostring(id or "")]
    if type(case) ~= "table" or not self:CanCurrentClientAccessModerationRecord183("C", case) then return false, "Case not found or not available on this character." end
    if case.status == "WITHDRAWN" then return false, "This report was withdrawn by its author and cannot be assigned." end
    assignee = SafeWireText183(self, assignee or "", 32)
    if assignee ~= "" then
        local member = self.GetMember and self:GetMember(assignee) or nil
        if not member or not self.IsLeadership or not self:IsLeadership(member) then return false, "The selected officer is not currently available as a Leadership recipient." end
        assignee = ShortName183(member.name or assignee)
        if tostring(case.privacyScope or CASE_SCOPE_LEADERSHIP_183) == CASE_SCOPE_GUILD_LEADER_183 then
            local canonical = self.GetCanonicalGuildLeaderName180 and self:GetCanonicalGuildLeaderName180() or ""
            if canonical == "" or Normalize183(self, assignee) ~= Normalize183(self, canonical) then
                return false, "Private Officer reports can only be assigned to the Guild Leader."
            end
        end
    end
    if Normalize183(self, case.assignedTo183 or "") == Normalize183(self, assignee) then return false, "Assignment is unchanged." end
    case.revision = math.max(1, tonumber(case.revision) or 1) + 1
    case.updatedAt = self:Now()
    case.assignedTo183 = assignee
    AppendTimeline183(self, case, assignee ~= "" and "ASSIGNED" or "UNASSIGNED", PlayerName183(),
        assignee ~= "" and ("Assigned to " .. assignee) or "Case returned to the Leadership queue", case.updatedAt,
        "assignment:" .. tostring(case.revision))
    if self.ModerationStateChanged183 then self:ModerationStateChanged183("case-assigned") end
    if self.RefreshModerationViews183 then self:RefreshModerationViews183("case-assigned") end
    return true, case
end

function OTLGM:MarkOfficerCaseSeen183(case)
    if type(case) ~= "table" or case.status ~= "NEW" or not self:IsOfficerMode() then return false end
    return self:UpdateOfficerCase183(case.id, "SEEN", "", case.privateComment or "", "")
end

function OTLGM:SubmitReportFollowup183(id, text)
    local state = self:EnsureModeration183()
    local report = state and state.ownReports[tostring(id or "")]
    if type(report) ~= "table" or not IsSelf183(self, report.author) then return false, "Report not found." end
    if report.status ~= "WAITING" then return false, "Leadership is not waiting for a follow-up on this report." end
    text = SafeWireText183(self, text or "", MAX_RESPONSE_183)
    if text == "" then return false, "Enter a short follow-up." end
    local reportScope = tostring(report.privacyScope or CASE_SCOPE_LEADERSHIP_183)
    local peers = reportScope == CASE_SCOPE_GUILD_LEADER_183
        and self:GetModerationGuildLeaderPeers183(1)
        or self:GetModerationLeadershipPeers183(MAX_REPORT_PEERS_183, report.target)
    local recipients, seen = {}, {}
    local key, name
    for key, name in pairs(report.deliveryRecipients or {}) do
        local eligible = reportScope == CASE_SCOPE_GUILD_LEADER_183
            and self:IsModerationGuildLeaderPeer183(name)
            or (reportScope == CASE_SCOPE_LEADERSHIP_183 and self:IsValidatedModerationLeader183(name))
        if name and eligible and not seen[Normalize183(self, name)] then
            seen[Normalize183(self, name)] = true table.insert(recipients, name)
        end
    end
    local index
    for index = 1, table.getn(peers) do
        if not seen[Normalize183(self, peers[index])] then seen[Normalize183(self, peers[index])] = true table.insert(recipients, peers[index]) end
    end
    local revision = math.max(1, tonumber(report.remoteRevision or report.revision) or 1)
    local timestamp, queued = self:Now(), 0
    local payload = table.concat({ "M1", "RFOLLOW", tostring(report.id), tostring(revision), tostring(timestamp), text }, "^")
    for index = 1, math.min(MAX_REPORT_PEERS_183, table.getn(recipients)) do
        if QueueModerationPacket183(self, payload, recipients[index],
            "moderation:followup:" .. tostring(report.id) .. ":" .. tostring(timestamp) .. ":" .. Normalize183(self, recipients[index])) then queued = queued + 1 end
    end
    if queued == 0 then
        if reportScope == CASE_SCOPE_GUILD_LEADER_183 then
            return false, "The Guild Leader is not currently available through the addon. Your follow-up was not sent to other Officers."
        end
        return false, "No compatible Leadership member is online right now. Try again when an officer is online."
    end
    AppendTimeline183(self, report, "FOLLOWUP", report.author, text, timestamp, "followup:" .. tostring(timestamp))
    report.status = "REVIEW" report.updatedAt = timestamp
    if self.RefreshModerationViews183 then self:RefreshModerationViews183("followup") end
    return true
end

local function QueueWarningPacket183(owner, warning, target)
    local payload = table.concat({
        "M1", "WARNING", tostring(warning.id), tostring(warning.revision), tostring(warning.issuedAt),
        SafeWireText183(owner, warning.target, 32), tostring(warning.category),
        tostring(math.max(1, math.min(2, tonumber(warning.announcedCount) or 1))),
        SafeWireText183(owner, warning.reason, MAX_WARNING_REASON_183),
    }, "^")
    return QueueModerationPacket183(owner, payload, target,
        "moderation:warning:" .. tostring(warning.id) .. ":" .. tostring(warning.revision) .. ":" .. Normalize183(owner, target))
end

local function EscalationCaseId183(owner, state, target)
    local ids, id, warning = {}, nil, nil
    local normalized = Normalize183(owner, target)
    for id, warning in pairs(state and state.officerWarnings or {}) do
        if type(warning) == "table" and warning.active == true and Normalize183(owner, warning.target) == normalized then
            table.insert(ids, tostring(id))
        end
    end
    table.sort(ids)
    return "E" .. tostring(NameHash183(normalized)) .. "-" .. tostring(NameHash183(table.concat(ids, ",")))
end

local function EnsureEscalationCase183(owner, state, target, category, reason, privateComment, relatedCaseId)
    local id = EscalationCaseId183(owner, state, target)
    local existing = state and state.officerCases and state.officerCases[id]
    if type(existing) == "table" then return existing, false end
    local now = owner:Now()
    local case = {
        id = id, sourceRevision = 1, revision = 1, author = "Leadership", target = ShortName183(target),
        reportType = "GUILD", category = "RULES", privacyScope = CASE_SCOPE_LEADERSHIP_183,
        text = "Active warning limit reached. Manual Leadership review is required; no automatic punishment was applied.",
        diagnostics = "", status = "REVIEW", statusReason183 = "Warning limit reached",
        assignedTo183 = "", relatedCaseId183 = SafeWireText183(owner, relatedCaseId or "", 24), caseKind183 = "ESCALATION",
        privateComment = SafeWireText183(owner, privateComment or "", MAX_PRIVATE_COMMENT_183),
        createdAt = now, updatedAt = now, timeline = {},
    }
    AppendTimeline183(owner, case, "ESCALATION", PlayerName183(), "Warning limit reached — Leadership review required", now,
        "escalation:" .. tostring(id))
    state.officerCases[id] = case
    PruneMap183(state.officerCases, MAX_OFFICER_CASES_183, function(record)
        return not TERMINAL_REPORT_STATUSES_183[record.status or "NEW"]
    end)
    return case, true
end

local function MigrateLegacyEscalationsRC4(owner, state)
    if not state or type(state.escalations) ~= "table" then return 0 end
    local migrated, id, legacy = 0, nil, nil
    for id, legacy in pairs(state.escalations) do
        if type(legacy) == "table" and not legacy.migratedTo183 and tostring(legacy.status or "OPEN") ~= "CLOSED"
            and legacy.target and legacy.target ~= "" and ActiveWarningCount183(state.officerWarnings, legacy.target) >= 2 then
            local canonical, created = EnsureEscalationCase183(owner, state, legacy.target, legacy.category or "OTHER",
                legacy.reason or "Leadership review required", legacy.privateComment or "", legacy.relatedCaseId183 or "")
            if canonical then
                legacy.migratedTo183 = canonical.id
                legacy.status = "CLOSED"
                legacy.updatedAt = owner:Now()
                if created then
                    AppendTimeline183(owner, canonical, "MIGRATED", "System", "Recovered from legacy escalation state", canonical.updatedAt or owner:Now(),
                        "legacy-escalation:" .. tostring(id))
                end
                migrated = migrated + 1
            end
        end
    end
    if migrated > 0 then
        owner.runtime = owner.runtime or {}
        owner.runtime.moderationLegacyEscalationsMigratedRC4 = (tonumber(owner.runtime.moderationLegacyEscalationsMigratedRC4) or 0) + migrated
        if owner.ModerationStateChanged183 then owner:ModerationStateChanged183("legacy-escalation-migrated") end
    end
    return migrated
end

local function SendExplicitGuildLine183(text, channel, target)
    if not SendChatMessage then return false end
    local ok = pcall(SendChatMessage, tostring(text or ""), channel or "GUILD", nil, target)
    return ok and true or false
end

function OTLGM:IssueWarning183(target, category, reason, privateComment, announceGuild, fallbackWhisper, relatedCaseId)
    if not self:IsOfficerMode() then return false, "Officer permissions are required." end
    local reconciliationState, reconciliationPeers = self:GetModerationReconciliationState183()
    if reconciliationPeers > 0 and reconciliationState ~= "READY" then
        self:ModerationStateChanged183("warning-gate-retry")
        return false, "Leadership warning data is updating. Try again in a moment."
    end
    local member = self.GetMember and self:GetMember(target) or nil
    if not member then return false, "Select a current guild member from Roster." end
    target = ShortName183(member.name or target)
    local validCategory = false
    local index
    for index = 1, table.getn(WARNING_CATEGORIES_183) do if WARNING_CATEGORIES_183[index][1] == category then validCategory = true break end end
    if not validCategory then category = "OTHER" end
    reason = SafeWireText183(self, reason or "", MAX_WARNING_REASON_183)
    privateComment = SafeWireText183(self, privateComment or "", MAX_PRIVATE_COMMENT_183)
    if reason == "" then return false, "Enter the official warning reason." end
    local state = self:EnsureModeration183()
    local sourceCase = relatedCaseId and relatedCaseId ~= "" and state.officerCases[relatedCaseId] or nil
    local sourceCaseIsGuildLeaderOnly = type(sourceCase) == "table"
        and tostring(sourceCase.privacyScope or CASE_SCOPE_LEADERSHIP_183) == CASE_SCOPE_GUILD_LEADER_183
    -- A warning is an official outcome that Leadership may know about, but a
    -- Guild-Leader-only complaint must remain secret. Do not let its case ID or
    -- private case comment escape through the shared warning/escalation record.
    local sharedRelatedCaseId = sourceCaseIsGuildLeaderOnly and "" or SafeWireText183(self, relatedCaseId or "", 24)
    local sharedPrivateComment = sourceCaseIsGuildLeaderOnly and "" or privateComment
    local current = ActiveWarningCount183(state.officerWarnings, target)
    if current >= 2 then
        local escalation, created = EnsureEscalationCase183(self, state, target, category, reason, sharedPrivateComment, sharedRelatedCaseId)
        if created and self.ModerationStateChanged183 then self:ModerationStateChanged183("escalation-case-created") end
        if announceGuild and created then SendExplicitGuildLine183("[Guild Notice] " .. target .. " has reached the warning limit. Further action requires Leadership review.", "GUILD") end
        if self.RefreshModerationViews183 then self:RefreshModerationViews183("escalation") end
        if self.ShowToast then self:ShowToast("Escalation Required — no automatic guild action was taken.", "error") end
        return false, "ESCALATION", escalation
    end

    local warning = {
        id = self:NextModerationId183("W"), revision = 1, issuedAt = self:Now(), updatedAt = self:Now(),
        target = target, issuer = PlayerName183(), category = category, reason = reason,
        privateComment = sharedPrivateComment, relatedCaseId183 = sharedRelatedCaseId,
        active = true, acknowledged = false, announcedCount = current + 1,
    }
    state.officerWarnings[warning.id] = warning
    PruneMap183(state.officerWarnings, MAX_OFFICER_WARNINGS_183, function(record) return record.active == true end)
    if relatedCaseId and relatedCaseId ~= "" and type(state.officerCases[relatedCaseId]) == "table" then
        local related = state.officerCases[relatedCaseId]
        related.revision = math.max(1, tonumber(related.revision) or 1) + 1
        related.updatedAt = self:Now()
        AppendTimeline183(self, related, "WARNING", PlayerName183(), "Official warning " .. tostring(current + 1) .. "/2 issued (" .. tostring(warning.id) .. ")",
            related.updatedAt, "warning:" .. tostring(warning.id))
    end

    local detection = self.GetAddonDetection170 and self:GetAddonDetection170(target) or nil
    local targetQueued = detection and detection.state == "ACTIVE" and self:IsModerationPeer183(detection.version)
        and QueueWarningPacket183(self, warning, target) or false
    warning.targetDeliveryPending = not targetQueued
    if warning.targetDeliveryPending then state.hasPendingOutbound183 = true end
    -- The target receives the sanitized WARNING packet. Leadership peers receive
    -- the canonical Officer copy through RC4 reconciliation. If the warning came
    -- from a Guild-Leader-only complaint, its secret case link/private comment
    -- were stripped above so the official outcome cannot reveal the complaint.
    if self.ModerationStateChanged183 then self:ModerationStateChanged183("warning-issued") end
    if not targetQueued and fallbackWhisper then
        SendExplicitGuildLine183("[Guild Notice] You have received an official guild warning (" .. tostring(current + 1) .. "/2). Please contact Leadership if you need clarification.", "WHISPER", target)
        warning.fallbackWhisperAt = self:Now()
    end
    if announceGuild then
        local suffix = current + 1 >= 2 and " Further violations require Leadership review." or ""
        SendExplicitGuildLine183("[Guild Notice] " .. target .. " has received an official guild warning (" .. tostring(current + 1) .. "/2)." .. suffix, "GUILD")
        warning.announcedAt = self:Now()
    end
    if self.RefreshModerationViews183 then self:RefreshModerationViews183("warning-issued") end
    if self.ShowToast then self:ShowToast("Official warning recorded (" .. tostring(current + 1) .. "/2).", "success") end
    return true, warning
end

function OTLGM:ClearWarning183(id, clearReason)
    if not self:IsOfficerMode() then return false, "Officer permissions are required." end
    local state = self:EnsureModeration183()
    local warning = state and state.officerWarnings[tostring(id or "")]
    if type(warning) ~= "table" or not self:CanCurrentClientAccessModerationRecord183("W", warning) or warning.active ~= true then
        return false, "Active warning not found or not available on this character."
    end
    local valid = false
    local index
    for index = 1, table.getn(WARNING_CLEAR_REASONS_183) do if WARNING_CLEAR_REASONS_183[index][1] == clearReason then valid = true break end end
    if not valid then clearReason = "DECISION" end
    warning.revision = math.max(1, tonumber(warning.revision) or 1) + 1
    warning.active = false warning.clearReason = clearReason warning.clearedAt = self:Now() warning.updatedAt = warning.clearedAt
    local payload = table.concat({ "M1", "WCLEAR", tostring(warning.id), tostring(warning.revision), tostring(warning.clearedAt),
        SafeWireText183(self, warning.target, 32), clearReason }, "^")
    local detection = self.GetAddonDetection170 and self:GetAddonDetection170(warning.target) or nil
    if detection and detection.state == "ACTIVE" and self:IsModerationPeer183(detection.version) then
        QueueModerationPacket183(self, payload, warning.target,
            "moderation:wclear:" .. warning.id .. ":" .. Normalize183(self, warning.target))
        warning.targetClearPending = nil
    else warning.targetClearPending = true state.hasPendingOutbound183 = true end
    -- Leadership copies are cleared through canonical reconciliation. The direct
    -- WCLEAR packet is only for the warning target, so an Officer who missed the
    -- original warning cannot manufacture a partial tombstone record.
    if self.ModerationStateChanged183 then self:ModerationStateChanged183("warning-cleared") end
    if self.RefreshModerationViews183 then self:RefreshModerationViews183("warning-cleared") end
    if self.ShowToast then self:ShowToast("Warning cleared and retained as inactive history.", "success") end
    return true, warning
end

function OTLGM:AcknowledgeOwnWarning183(id)
    local state = self:EnsureModeration183()
    local warning = state and state.ownWarnings[tostring(id or "")]
    if type(warning) ~= "table" or not IsSelf183(self, warning.target) then return false, "Warning not found." end
    if warning.acknowledged then return true, warning end
    warning.acknowledged = true warning.acknowledgedAt = self:Now() warning.updatedAt = warning.acknowledgedAt
    local payload = table.concat({ "M1", "WACK", tostring(warning.id), tostring(warning.revision), tostring(warning.acknowledgedAt) }, "^")
    local recipients, seen = {}, {}
    if warning.issuer and warning.issuer ~= "" and self:IsValidatedModerationLeader183(warning.issuer) then
        seen[Normalize183(self, warning.issuer)] = true table.insert(recipients, warning.issuer)
    end
    local peers = self:GetModerationLeadershipPeers183(MAX_REPORT_PEERS_183)
    local index
    for index = 1, table.getn(peers) do
        if not seen[Normalize183(self, peers[index])] then seen[Normalize183(self, peers[index])] = true table.insert(recipients, peers[index]) end
    end
    for index = 1, math.min(MAX_REPORT_PEERS_183, table.getn(recipients)) do
        QueueModerationPacket183(self, payload, recipients[index],
            "moderation:wack:" .. warning.id .. ":" .. Normalize183(self, recipients[index]))
    end
    if self.RefreshModerationViews183 then self:RefreshModerationViews183("warning-acknowledged") end
    if self.ShowToast then self:ShowToast("Warning marked as seen. This does not mean agreement.", "success") end
    return true, warning
end

function OTLGM:RetryModerationForPresence183(sender, version)
    local queued = self:TryDeliverPendingReports183(sender, version)
    local state = self:EnsureModeration183()
    local now, id, case, warning = self:Now(), nil, nil, nil
    if self:IsOfficerMode() and self:IsModerationPeer183(version) and state and state.hasPendingOutbound183 then
        local delivered = 0
        for id, case in pairs(state and state.officerCases or {}) do
            if type(case) == "table" and case.authorDeliveryPending and Normalize183(self, case.author) == Normalize183(self, sender)
                and now - (tonumber(case.lastAuthorRetry183) or 0) >= PENDING_RETRY_COOLDOWN_183 then
                local pendingResponse = type(case.pendingResponse183) == "table" and case.pendingResponse183.text or nil
                if QueueCasePacketTo183(self, case, sender, pendingResponse) > 0 then
                    case.authorDeliveryPending = nil case.pendingResponse183 = nil case.lastAuthorRetry183 = now
                    delivered = delivered + 1 queued = queued + 1
                    if delivered >= 2 then break end
                end
            end
        end
        local warningDeliveries = 0
        for id, warning in pairs(state and state.officerWarnings or {}) do
            if type(warning) == "table" and Normalize183(self, warning.target) == Normalize183(self, sender)
                and (warning.targetDeliveryPending or warning.targetClearPending)
                and now - (tonumber(warning.lastTargetRetry183) or 0) >= PENDING_RETRY_COOLDOWN_183 then
                local ok = false
                if warning.active then ok = QueueWarningPacket183(self, warning, sender)
                else
                    local payload = table.concat({ "M1", "WCLEAR", warning.id, tostring(warning.revision), tostring(warning.clearedAt or warning.updatedAt or now), warning.target, warning.clearReason or "DECISION" }, "^")
                    ok = QueueModerationPacket183(self, payload, sender, "moderation:wclear:" .. warning.id .. ":" .. Normalize183(self, sender))
                end
                if ok then
                    warning.targetDeliveryPending = nil warning.targetClearPending = nil warning.lastTargetRetry183 = now
                    warningDeliveries = warningDeliveries + 1 queued = queued + 1
                    if warningDeliveries >= 2 then break end
                end
            end
        end
        local remains = false
        for id, case in pairs(state.officerCases or {}) do
            if type(case) == "table" and case.authorDeliveryPending then remains = true break end
        end
        if not remains then
            for id, warning in pairs(state.officerWarnings or {}) do
                if type(warning) == "table" and (warning.targetDeliveryPending or warning.targetClearPending) then remains = true break end
            end
        end
        state.hasPendingOutbound183 = remains and true or nil
    end
    if self:BeginModerationReconciliation183(sender, version) then queued = queued + 1 end
    return queued
end

function OTLGM:GetNeedsAttention183()
    local result = { newReports = 0, unassigned = 0, waiting = 0, warningLimit = 0, escalations = 0, total = 0 }
    if not self:IsOfficerMode() then return result end
    local state = self:EnsureModeration183()
    MigrateLegacyEscalationsRC4(self, state)
    local actionableCases, escalationTargets = 0, {}
    local id, record
    for id, record in pairs(state and state.officerCases or {}) do
        if type(record) == "table" and self:CanCurrentClientAccessModerationRecord183("C", record)
            and not TERMINAL_REPORT_STATUSES_183[record.status or "NEW"] then
            local isEscalation = tostring(record.caseKind183 or "REPORT") == "ESCALATION"
            local isActionable = false
            if isEscalation then
                result.escalations = result.escalations + 1
                escalationTargets[Normalize183(self, record.target or "")] = true
                isActionable = true
            else
                if record.status == "NEW" then result.newReports = result.newReports + 1 isActionable = true end
                if record.status == "WAITING" then result.waiting = result.waiting + 1 isActionable = true end
                if tostring(record.assignedTo183 or "") == "" then result.unassigned = result.unassigned + 1 isActionable = true end
            end
            if isActionable then actionableCases = actionableCases + 1 end
        end
    end
    local counts, normalized = {}, nil
    for id, record in pairs(state and state.officerWarnings or {}) do
        if type(record) == "table" and self:CanCurrentClientAccessModerationRecord183("W", record) and record.active == true then
            normalized = Normalize183(self, record.target)
            counts[normalized] = (tonumber(counts[normalized]) or 0) + 1
        end
    end
    for normalized in pairs(counts) do
        if counts[normalized] >= 2 and not escalationTargets[normalized] then result.warningLimit = result.warningLimit + 1 end
    end
    result.total = actionableCases + result.warningLimit
    return result
end

function OTLGM:GetModerationCaseCountForMember183(name)
    if not self:IsOfficerMode() then return 0 end
    local state, count, id, case = self:EnsureModeration183(), 0, nil, nil
    local normalized = Normalize183(self, name)
    for id, case in pairs(state and state.officerCases or {}) do
        if type(case) == "table" and self:CanCurrentClientAccessModerationRecord183("C", case)
            and (Normalize183(self, case.author) == normalized or Normalize183(self, case.target) == normalized) then count = count + 1 end
    end
    return count
end

local function CollectRecords183(map, predicate)
    local result, id, record = {}, nil, nil
    for id, record in pairs(map or {}) do
        if type(record) == "table" and (not predicate or predicate(record)) then table.insert(result, record) end
    end
    table.sort(result, function(left, right)
        local leftTime = tonumber(left.updatedAt or left.createdAt or left.issuedAt) or 0
        local rightTime = tonumber(right.updatedAt or right.createdAt or right.issuedAt) or 0
        if leftTime ~= rightTime then return leftTime > rightTime end
        return tostring(left.id or "") > tostring(right.id or "")
    end)
    return result
end

function OTLGM:GetOwnModerationReports183()
    local state = self:EnsureModeration183()
    return CollectRecords183(state and state.ownReports, function(record) return IsSelf183(self, record.author) end)
end

function OTLGM:GetOwnModerationWarnings183()
    local state = self:EnsureModeration183()
    return CollectRecords183(state and state.ownWarnings, function(record) return IsSelf183(self, record.target) end)
end

function OTLGM:GetOfficerCases183(target, status)
    if not self:IsOfficerMode() then return {} end
    local state, normalized = self:EnsureModeration183(), Normalize183(self, target or "")
    return CollectRecords183(state and state.officerCases, function(record)
        if not self:CanCurrentClientAccessModerationRecord183("C", record) then return false end
        if tostring(record.caseKind183 or "REPORT") == "REPORT" and IsSelf183(self, record.author) then return false end
        local targetMatch = normalized == "" or Normalize183(self, record.author) == normalized or Normalize183(self, record.target) == normalized
        return targetMatch and (not status or status == "" or record.status == status)
    end)
end

function OTLGM:GetOfficerWarnings183(target, limitOnly)
    if not self:IsOfficerMode() then return {} end
    local state, normalized = self:EnsureModeration183(), Normalize183(self, target or "")
    local atLimit = {}
    if limitOnly then
        local id, warning, key
        for id, warning in pairs(state and state.officerWarnings or {}) do
            if type(warning) == "table" and self:CanCurrentClientAccessModerationRecord183("W", warning) and warning.active == true then
                key = Normalize183(self, warning.target)
                atLimit[key] = (tonumber(atLimit[key]) or 0) + 1
            end
        end
    end
    return CollectRecords183(state and state.officerWarnings, function(record)
        if not self:CanCurrentClientAccessModerationRecord183("W", record) then return false end
        local key = Normalize183(self, record.target)
        return (normalized == "" or key == normalized) and (not limitOnly or (tonumber(atLimit[key]) or 0) >= 2)
    end)
end

local function SetShown183(frame, shown)
    if not frame then return end
    if shown then frame:Show() else frame:Hide() end
end

local function SetEditText183(edit, value)
    if not edit then return end
    edit.otlSilent = true edit:SetText(tostring(value or "")) edit.otlSilent = nil
end

local function FormatModerationDate183(owner, timestamp)
    if date then return date("%d %b %Y %H:%M", tonumber(timestamp) or owner:Now()) end
    return tostring(timestamp or "")
end

local function CycleDefinition183(definitions, current)
    local selected, index = 1, 1
    for index = 1, table.getn(definitions) do
        local key = definitions[index].key or definitions[index][1]
        if key == current then selected = index break end
    end
    selected = selected + 1
    if selected > table.getn(definitions) then selected = 1 end
    return definitions[selected]
end

local function BuildChoiceMenu183(parent, width, maximumRows)
    local menu = UI:Card(parent, width, 40, "")
    menu:SetFrameLevel((parent.GetFrameLevel and parent:GetFrameLevel() or 1) + 30)
    menu.rows183 = {}
    local index
    for index = 1, maximumRows do
        local row = UI:Button(menu, "", width - 10, 24, function(button)
            local current = button and button.otlChoiceMenu183
            if not current or not button.otlChoiceKey183 then return end
            local callback = current.otlChoiceHandler183
            current:Hide()
            if callback then callback(button.otlChoiceKey183) end
        end, "filter")
        row:SetPoint("TOPLEFT", menu, "TOPLEFT", 5, -5 - ((index - 1) * 25))
        row.otlChoiceMenu183 = menu
        row:Hide()
        menu.rows183[index] = row
    end
    menu:Hide()
    return menu
end

local function HideChoiceMenus183(modal, except)
    if not modal then return end
    local menus = { modal.typeMenu183, modal.categoryMenu183, modal.warningCategoryMenu183 }
    local index
    for index = 1, table.getn(menus) do
        if menus[index] and menus[index] ~= except then menus[index]:Hide() end
    end
end

local function ToggleChoiceMenu183(modal, menu, definitions, selected, handler)
    if not menu then return false end
    local wasVisible = menu:IsVisible()
    HideChoiceMenus183(modal, menu)
    if wasVisible then menu:Hide() return false end
    definitions = definitions or {}
    local count = math.min(table.getn(definitions), table.getn(menu.rows183 or {}))
    local index
    for index = 1, table.getn(menu.rows183 or {}) do
        local row = menu.rows183[index]
        local definition = definitions[index]
        if definition and index <= count then
            local key = definition.key or definition[1]
            local label = definition.label or definition[2] or tostring(key or "Option")
            row.otlChoiceKey183 = key
            UI:SetText(row, label)
            UI:SetSelected(row, key == selected)
            row:Show()
        else
            row.otlChoiceKey183 = nil
            row:Hide()
        end
    end
    menu.otlChoiceHandler183 = handler
    menu:SetHeight(10 + (count * 25))
    menu:Show()
    return true
end

function OTLGM:BuildNewReportModal183()
    self.ui = self.ui or {}
    if self.ui.newReportModal183 then return self.ui.newReportModal183 end
    if not self.ui.modalHost then return nil end
    local modal = UI:Modal(self.ui.modalHost, 620, 548)
    modal:SetPoint("CENTER", self.ui.modalHost, "CENTER", 0, 0)
    modal.otlDiagnosticName180 = "New Private Report"
    modal.title = UI.Text(modal, "Report / Help", "GameFontNormalLarge", "LEFT")
    modal.title:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -18) modal.title:SetWidth(490)
    modal.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    modal.privacy = UI.Text(modal, "Private to validated Leadership. Other members and the reported player do not see the author.", "GameFontNormalSmall", "LEFT")
    modal.privacy:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -48) modal.privacy:SetWidth(575) modal.privacy:SetHeight(30)
    modal.privacy:SetJustifyV("TOP") modal.privacy:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.reportType183 = REPORT_TYPES_183[1].key
    modal.category183 = REPORT_TYPES_183[1].categories[1][1]
    modal.selectedTargetName183 = nil
    modal.typeButton = UI:Button(modal, "", 284, 30, function()
        ToggleChoiceMenu183(modal, modal.typeMenu183, REPORT_TYPES_183, modal.reportType183, function(key)
            local definition = ReportTypeDefinition183(key)
            modal.reportType183 = definition.key
            modal.category183 = definition.categories[1][1]
            modal.selectedTargetName183 = nil
            OTLGM:RefreshNewReportModal183()
        end)
    end, "filter")
    modal.typeButton:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -84)
    modal.categoryButton = UI:Button(modal, "", 284, 30, function()
        local definition = ReportTypeDefinition183(modal.reportType183)
        ToggleChoiceMenu183(modal, modal.categoryMenu183, definition.categories, modal.category183, function(key)
            modal.category183 = key
            OTLGM:RefreshNewReportModal183()
        end)
    end, "filter")
    modal.categoryButton:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -20, -84)
    modal.typeMenu183 = BuildChoiceMenu183(modal, 284, table.getn(REPORT_TYPES_183))
    modal.typeMenu183:SetPoint("TOPLEFT", modal.typeButton, "BOTTOMLEFT", 0, -2)
    modal.categoryMenu183 = BuildChoiceMenu183(modal, 284, 9)
    modal.categoryMenu183:SetPoint("TOPRIGHT", modal.categoryButton, "BOTTOMRIGHT", 0, -2)

    modal.targetLabel = UI.Text(modal, "GUILD MEMBER", "GameFontNormalSmall", "LEFT")
    modal.targetLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -124) modal.targetLabel:SetWidth(300)
    modal.targetLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    modal.target = UI:EditBox(modal, 580, 30, { maxLetters = 32, placeholder = "Start typing a guild member name...",
        changed = function(value)
            local current = OTLGM.ui and OTLGM.ui.newReportModal183
            if current and current.selectedTargetName183 and Normalize183(OTLGM, value or "") ~= Normalize183(OTLGM, current.selectedTargetName183) then
                current.selectedTargetName183 = nil
            end
            if OTLGM.RefreshNewReportTarget183 then OTLGM:RefreshNewReportTarget183() end
        end })
    modal.target:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -140)

    -- Reserved opaque target area. It never changes the modal height or moves the description/buttons.
    modal.targetPanel183 = UI:Card(modal, 580, 116)
    modal.targetPanel183:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -176)
    modal.targetStatus183 = UI.Text(modal.targetPanel183, "", "GameFontNormalSmall", "LEFT")
    modal.targetStatus183:SetPoint("TOPLEFT", modal.targetPanel183, "TOPLEFT", 10, -7) modal.targetStatus183:SetWidth(558)
    modal.targetStatus183:SetHeight(22) modal.targetStatus183:SetJustifyV("TOP")
    modal.targetRows183 = {}
    local rowIndex
    for rowIndex = 1, 3 do
        local row = UI:TableRow(modal.targetPanel183, 558, 25, function(button)
            if not button.memberName183 then return end
            modal.selectedTargetName183 = button.memberName183
            SetEditText183(modal.target, button.memberName183)
            OTLGM:RefreshNewReportTarget183()
        end)
        row:SetPoint("TOPLEFT", modal.targetPanel183, "TOPLEFT", 10, -33 - ((rowIndex - 1) * 26))
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetWidth(18) row.icon:SetHeight(18) row.icon:SetPoint("LEFT", row, "LEFT", 7, 0)
        row.nameText = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.nameText:SetPoint("LEFT", row.icon, "RIGHT", 7, 0) row.nameText:SetWidth(140)
        row.metaText = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.metaText:SetPoint("LEFT", row.nameText, "RIGHT", 6, 0) row.metaText:SetWidth(285)
        row.metaText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        row.onlineText = UI.Text(row, "", "GameFontNormalSmall", "RIGHT")
        row.onlineText:SetPoint("RIGHT", row, "RIGHT", -7, 0) row.onlineText:SetWidth(82)
        row:Hide()
        modal.targetRows183[rowIndex] = row
    end

    modal.bodyLabel = UI.Text(modal, "DESCRIPTION", "GameFontNormalSmall", "LEFT")
    modal.bodyLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -300) modal.bodyLabel:SetWidth(180)
    modal.bodyLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    modal.count = UI.Text(modal, "0 / " .. tostring(MAX_REPORT_TEXT_183), "GameFontNormalSmall", "RIGHT")
    modal.count:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -20, -300) modal.count:SetWidth(100)
    modal.count:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.body = UI:EditBox(modal, 580, 92, { multiline = true, maxLetters = MAX_REPORT_TEXT_183,
        placeholder = "Describe what happened, what is broken, or what you suggest...", changed = function(value)
            if OTLGM.ui and OTLGM.ui.newReportModal183 then
                OTLGM.ui.newReportModal183.count:SetText(tostring(string.len(tostring(value or ""))) .. " / " .. tostring(MAX_REPORT_TEXT_183))
            end
        end })
    modal.body:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -317)
    modal.diagnostics = UI:Check(modal, "Include troubleshooting details", 290, function() end)
    modal.diagnostics:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -414)
    modal.diagnostics.otlTooltipTitle = "Troubleshooting details"
    modal.diagnostics.otlTooltip = "Adds basic addon, performance and error information that can help diagnose a problem. It never includes private notes or report contents."
    modal.deliveryNote = UI.Text(modal, "If no Leadership recipient is online, the report stays saved and will be delivered automatically when an eligible officer is available.", "GameFontNormalSmall", "LEFT")
    modal.deliveryNote:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -446) modal.deliveryNote:SetWidth(580) modal.deliveryNote:SetHeight(38)
    modal.deliveryNote:SetJustifyV("TOP") modal.deliveryNote:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.cancel = UI:Button(modal, "Cancel", 94, 30, function() OTLGM:CloseModal180(modal, "report-cancel") end, "secondary")
    modal.cancel:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -136, 16)
    modal.submit = UI:Button(modal, "Submit Privately", 128, 30, function()
        local target = modal.reportType183 == "PLAYER" and (modal.selectedTargetName183 or "") or (modal.target:GetText() or "")
        local ok, result
        if modal.editingReportIdR30 then
            ok, result = OTLGM:EditOwnModerationReportR30(modal.editingReportIdR30, modal.reportType183, modal.category183,
                target, modal.body:GetText() or "", modal.diagnostics:GetChecked() and true or false)
        else
            ok, result = OTLGM:CreateModerationReport183(modal.reportType183, modal.category183,
                target, modal.body:GetText() or "", modal.diagnostics:GetChecked() and true or false)
        end
        if ok then OTLGM:CloseModal180(modal, "save-success") OTLGM:OpenMemberModerationDrawer183("REPORTS")
        elseif OTLGM.ShowToast then OTLGM:ShowToast(tostring(result or "Report could not be saved."), "error") end
    end, "primary")
    modal.submit:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -20, 16)
    self.ui.newReportModal183 = modal
    return modal
end

function OTLGM:RefreshNewReportTarget183()
    local modal = self.ui and self.ui.newReportModal183
    if not modal then return false end
    local playerReport = modal.reportType183 == "PLAYER"
    modal.targetLabel:SetText(playerReport and "GUILD MEMBER" or "TARGET (OPTIONAL)")
    local value = modal.target and modal.target:GetText() or ""
    local rowIndex, row
    for rowIndex = 1, table.getn(modal.targetRows183 or {}) do
        row = modal.targetRows183[rowIndex]
        row.memberName183 = nil row:Hide() UI:SetSelected(row, false)
    end

    if not playerReport then
        modal.selectedTargetName183 = nil
        modal.targetStatus183:SetText("Optional for this report type. You can leave this field blank.")
        modal.targetStatus183:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        UI:SetEnabled(modal.submit, true)
        return true
    end

    local trimmed = self.Trim and self:Trim(value or "") or tostring(value or "")
    local exact = trimmed ~= "" and self.GetMember and self:GetMember(trimmed) or nil
    if exact and exact.name and exact.name ~= "" then
        modal.selectedTargetName183 = ShortName183(exact.name)
    elseif modal.selectedTargetName183 and Normalize183(self, modal.selectedTargetName183) ~= Normalize183(self, value) then
        modal.selectedTargetName183 = nil
    end

    local selectedMember = modal.selectedTargetName183 and self.GetMember and self:GetMember(modal.selectedTargetName183) or nil
    local matches = trimmed ~= "" and self:GetModerationTargetMatches183(trimmed, 3) or {}
    if selectedMember then
        -- Put the selected exact member first, then only distinct alternatives.
        local ordered = { selectedMember }
        local index, candidate
        for index = 1, table.getn(matches) do
            candidate = matches[index]
            if Normalize183(self, candidate and candidate.name or "") ~= Normalize183(self, selectedMember.name or "") and table.getn(ordered) < 3 then
                table.insert(ordered, candidate)
            end
        end
        matches = ordered
    end

    if trimmed == "" then
        modal.targetStatus183:SetText("Start typing a guild member name, then choose the correct person from the matches below.")
        modal.targetStatus183:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    elseif selectedMember then
        local officerTarget = self.IsLeadership and self:IsLeadership(selectedMember) or false
        local canonical = self.GetCanonicalGuildLeaderName180 and self:GetCanonicalGuildLeaderName180() or ""
        local guildLeaderTarget = canonical ~= "" and Normalize183(self, canonical) == Normalize183(self, selectedMember.name or "")
        if guildLeaderTarget then
            modal.targetStatus183:SetText("GUILD LEADER TARGET — this cannot be submitted privately in-addon; use the external guild contact channel.")
            modal.targetStatus183:SetTextColor(C.red[1], C.red[2], C.red[3])
        elseif officerTarget then
            if self.IsGuildLeader170 and self:IsGuildLeader170() then
                modal.targetStatus183:SetText("OFFICER REPORT — as Guild Leader, this is delivered to other validated Leadership except the reported player.")
            else
                modal.targetStatus183:SetText("OFFICER REPORT — delivered only to the Guild Leader. Other Officers do not receive it.")
            end
            modal.targetStatus183:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
        else
            modal.targetStatus183:SetText("SELECTED GUILD MEMBER — confirm the class, level and rank below before submitting.")
            modal.targetStatus183:SetTextColor(C.green[1], C.green[2], C.green[3])
        end
    elseif table.getn(matches) > 0 then
        modal.targetStatus183:SetText("Choose the correct guild member from the matches below.")
        modal.targetStatus183:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    else
        modal.targetStatus183:SetText("No matching guild member was found. Check the name or open Roster and update it first.")
        modal.targetStatus183:SetTextColor(C.red[1], C.red[2], C.red[3])
    end

    for rowIndex = 1, math.min(3, table.getn(matches)) do
        local member = matches[rowIndex]
        row = modal.targetRows183[rowIndex]
        row.memberName183 = ShortName183(member.name or "")
        ApplyModerationClassIcon183(row.icon, member.class)
        row.nameText:SetText(self:GetClassColor(member.class or "") .. tostring(row.memberName183) .. self.colors.reset)
        row.metaText:SetText("Level " .. tostring(member.level or 0) .. "  •  " .. tostring(member.class or "Unknown") .. "  •  " .. tostring(member.rank or "Guild member"))
        row.onlineText:SetText(member.online and "Online" or "Offline")
        row.onlineText:SetTextColor(member.online and C.green[1] or C.grey[1], member.online and C.green[2] or C.grey[2], member.online and C.green[3] or C.grey[3])
        UI:SetSelected(row, selectedMember and Normalize183(self, member.name or "") == Normalize183(self, selectedMember.name or ""))
        row:Show()
    end

    local valid = selectedMember ~= nil
    if valid then
        local canonical = self.GetCanonicalGuildLeaderName180 and self:GetCanonicalGuildLeaderName180() or ""
        if canonical ~= "" and Normalize183(self, canonical) == Normalize183(self, selectedMember.name or "") then valid = false end
    end
    UI:SetEnabled(modal.submit, valid, valid and nil or "Choose a valid guild member first.")
    return true
end

function OTLGM:RefreshNewReportModal183()
    local modal = self.ui and self.ui.newReportModal183
    if not modal then return false end
    local definition = ReportTypeDefinition183(modal.reportType183)
    if not ReportCategoryValid183(definition.key, modal.category183) then modal.category183 = definition.categories[1][1] end
    UI:SetText(modal.typeButton, "Type: " .. definition.label .. "  v")
    UI:SetText(modal.categoryButton, "Category: " .. ReportCategoryLabel183(definition.key, modal.category183) .. "  v")
    local diagnosticVisible = definition.key == "ADDON"
    SetShown183(modal.diagnostics, diagnosticVisible)
    if not diagnosticVisible then UI:SetChecked(modal.diagnostics, false) end
    self:RefreshNewReportTarget183()
    return true
end

function OTLGM:OpenNewReportModal183(prefillTarget)
    if not self.ui or not self.ui.main then self:BuildUI() end
    local modal = self:BuildNewReportModal183()
    if not modal then return false end
    HideChoiceMenus183(modal)
    modal.editingReportIdR30 = nil
    modal.title:SetText("Report / Help")
    UI:SetText(modal.submit, "Submit Privately")
    modal.reportType183 = "PLAYER" modal.category183 = "HARASSMENT"
    local selected = prefillTarget
    if (not selected or selected == "") and self.ui.rosterSelectedName then
        local selectedMember = self.GetMember and self:GetMember(self.ui.rosterSelectedName) or nil
        if selectedMember then selected = selectedMember.name end
    end
    modal.selectedTargetName183 = selected and ShortName183(selected) or nil
    SetEditText183(modal.target, selected or "") SetEditText183(modal.body, "") UI:SetChecked(modal.diagnostics, false)
    modal.count:SetText("0 / " .. tostring(MAX_REPORT_TEXT_183))
    self:RefreshNewReportModal183()
    self:ShowShellModal(modal)
    return true
end

local function CanEditOwnReportR30(report)
    if type(report) ~= "table" or TERMINAL_REPORT_STATUSES_183[report.status or "NEW"] then return false end
    return report.status == "NEW" or report.status == "SEEN"
end

function OTLGM:EditOwnModerationReportR30(id, reportType, category, target, text, attachDiagnostics)
    local state = self:EnsureModeration183()
    local report = state and state.ownReports[tostring(id or "")]
    if type(report) ~= "table" or not IsSelf183(self, report.author) then return false, "Report not found." end
    if not CanEditOwnReportR30(report) then return false, "This report is already being reviewed. Add a follow-up instead of rewriting the original report." end
    local definition = ReportTypeDefinition183(reportType)
    reportType = definition.key
    if not ReportCategoryValid183(reportType, category) then category = definition.categories[1][1] end
    local targetValid, resolvedTarget = self:ResolveModerationReportTarget183(reportType, target)
    if not targetValid then return false, resolvedTarget end
    local privacyScope = self:ResolveModerationReportScope183(reportType, resolvedTarget)
    if privacyScope == CASE_SCOPE_GUILD_LEADER_183 and self.IsGuildLeader170 and self:IsGuildLeader170() then privacyScope = CASE_SCOPE_LEADERSHIP_183 end
    if privacyScope == CASE_SCOPE_EXTERNAL_183 then return false, "This target cannot be delivered privately through the in-addon Officer system." end
    text = SafeWireText183(self, text or "", MAX_REPORT_TEXT_183)
    if text == "" then return false, "Please describe the issue or suggestion." end
    report.sourceRevision = math.max(1, tonumber(report.sourceRevision or report.revision) or 1) + 1
    report.revision = math.max(tonumber(report.revision) or 1, report.sourceRevision)
    report.reportType, report.category, report.target = reportType, category, resolvedTarget
    report.privacyScope, report.text = privacyScope, text
    report.diagnostics = attachDiagnostics and reportType == "ADDON" and self:GetCompactModerationDiagnostics183() or ""
    report.delivery = "PENDING"
    report.acknowledgedAt, report.acknowledgedBy = nil, nil
    report.updatedAt = self:Now()
    AppendTimeline183(self, report, "EDITED", report.author, "Report edited; waiting for Leadership acknowledgement", report.updatedAt,
        "edit-local:" .. tostring(report.sourceRevision))
    local peers = privacyScope == CASE_SCOPE_GUILD_LEADER_183 and self:GetModerationGuildLeaderPeers183(1)
        or self:GetModerationLeadershipPeers183(MAX_REPORT_PEERS_183, report.target)
    local queued, index = 0, 1
    for index = 1, table.getn(peers) do
        if self:IsModerationAuthorControlPeerR30(peers[index]) and self:QueueReportToPeer183(report, peers[index], "report-edit") then queued = queued + 1 end
    end
    if self.RefreshModerationViews183 then self:RefreshModerationViews183("report-edited") end
    if self.ShowToast then
        if queued > 0 then self:ShowToast("Report update queued; waiting for Leadership acknowledgement.", "pending")
        else self:ShowToast("Report updated locally; a newer compatible Leadership client is required to receive the edit.", "pending") end
    end
    return true, report
end

function OTLGM:OpenEditOwnReportR30(id)
    local state = self:EnsureModeration183()
    local report = state and state.ownReports[tostring(id or "")]
    if type(report) ~= "table" or not IsSelf183(self, report.author) or not CanEditOwnReportR30(report) then return false end
    local modal = self:BuildNewReportModal183()
    if not modal then return false end
    HideChoiceMenus183(modal)
    modal.editingReportIdR30 = report.id
    modal.title:SetText("Edit My Report")
    UI:SetText(modal.submit, "Save Changes")
    modal.reportType183, modal.category183 = report.reportType or "PLAYER", report.category or "OTHER"
    modal.selectedTargetName183 = report.target and report.target ~= "" and ShortName183(report.target) or nil
    SetEditText183(modal.target, report.target or "")
    SetEditText183(modal.body, report.text or "")
    UI:SetChecked(modal.diagnostics, report.reportType == "ADDON" and tostring(report.diagnostics or "") ~= "")
    modal.count:SetText(tostring(string.len(tostring(report.text or ""))) .. " / " .. tostring(MAX_REPORT_TEXT_183))
    self:RefreshNewReportModal183()
    self:ShowShellModal(modal)
    return true
end

function OTLGM:WithdrawOwnModerationReportR30(id)
    local state = self:EnsureModeration183()
    local report = state and state.ownReports[tostring(id or "")]
    if type(report) ~= "table" or not IsSelf183(self, report.author) then return false, "Report not found." end
    if TERMINAL_REPORT_STATUSES_183[report.status or "NEW"] then return false, "This report is already closed." end
    report.status = "WITHDRAWN"
    report.statusReason183 = "Withdrawn by author"
    report.updatedAt = self:Now()
    AppendTimeline183(self, report, "WITHDRAWN", report.author, "Report withdrawn by author", report.updatedAt,
        "withdraw-local:" .. tostring(report.sourceRevision or 1))
    local recipients, seen, key, name = {}, {}, nil, nil
    for key, name in pairs(report.deliveryRecipients or {}) do
        if name and name ~= "" and not IsSelf183(self, name) and self:IsModerationAuthorControlPeerR30(name) then
            seen[Normalize183(self, name)] = true table.insert(recipients, name)
        end
    end
    local peers = report.privacyScope == CASE_SCOPE_GUILD_LEADER_183 and self:GetModerationGuildLeaderPeers183(1)
        or self:GetModerationLeadershipPeers183(MAX_REPORT_PEERS_183, report.target)
    local index
    for index = 1, table.getn(peers) do
        name = peers[index] key = Normalize183(self, name)
        if key ~= "" and not seen[key] and self:IsModerationAuthorControlPeerR30(name) then seen[key] = true table.insert(recipients, name) end
    end
    local payload = table.concat({ "M1", "RWITH", tostring(report.id),
        tostring(math.max(1, tonumber(report.sourceRevision or report.revision) or 1)), tostring(report.updatedAt) }, "^")
    local queued = 0
    for index = 1, table.getn(recipients) do
        if QueueModerationPacket183(self, payload, recipients[index], "moderation:rwith:" .. tostring(report.id) .. ":" .. Normalize183(self, recipients[index])) then queued = queued + 1 end
    end
    report.withdrawPendingR30 = queued == 0 and true or nil
    if self.RefreshModerationViews183 then self:RefreshModerationViews183("report-withdrawn") end
    if self.ShowToast then self:ShowToast(queued > 0 and "Report withdrawn and Leadership was notified." or "Report withdrawn locally; a newer compatible Leadership client is required to receive the withdrawal.", queued > 0 and "success" or "pending") end
    return true, report
end

function OTLGM:BuildMemberModerationDrawer183()
    self.ui = self.ui or {}
    if self.ui.memberModerationDrawer183 then return self.ui.memberModerationDrawer183 end
    if not self.ui.drawerHost then return nil end
    local drawer = UI:Drawer(self.ui.drawerHost, 470, 536)
    drawer:SetPoint("TOPRIGHT", self.ui.drawerHost, "TOPRIGHT", -10, -10)
    drawer.title = UI.Text(drawer, "Reports & Warnings", "GameFontNormalLarge", "LEFT")
    drawer.title:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -18) drawer.title:SetWidth(330)
    drawer.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    drawer.close = UI:IconButton(drawer, "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 28, 28,
        function() OTLGM:CloseShellDrawer() end, "Close", "utility")
    drawer.close:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -12, -12)
    drawer.reportsTab = UI:Tab(drawer, "My Reports", 112, function() drawer.mode183 = "REPORTS" drawer.offset183 = 0 OTLGM:RefreshMemberModerationDrawer183() end)
    drawer.reportsTab:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -52)
    drawer.warningsTab = UI:Tab(drawer, "My Warnings", 118, function() drawer.mode183 = "WARNINGS" drawer.offset183 = 0 OTLGM:RefreshMemberModerationDrawer183() end)
    drawer.warningsTab:SetPoint("LEFT", drawer.reportsTab, "RIGHT", 8, 0)
    drawer.newReport = UI:Button(drawer, "New Report", 104, 28, function() OTLGM:OpenNewReportModal183() end, "primary")
    drawer.newReport:SetPoint("LEFT", drawer.warningsTab, "RIGHT", 8, 0)
    drawer.subtitle = UI.Text(drawer, "", "GameFontNormalSmall", "LEFT")
    drawer.subtitle:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -90) drawer.subtitle:SetWidth(420) drawer.subtitle:SetHeight(30)
    drawer.subtitle:SetJustifyV("TOP") drawer.subtitle:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    drawer.rows = {}
    local index
    for index = 1, 7 do
        local row = UI:TableRow(drawer, 416, 50, function(button)
            if button.otlKind183 == "REPORT" then OTLGM:OpenOwnReportDetail183(button.otlRecordId183)
            elseif button.otlKind183 == "WARNING" then OTLGM:OpenOwnWarningDetail183(button.otlRecordId183) end
        end)
        row:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -122 - ((index - 1) * 54))
        row.title = UI.Text(row, "", "GameFontNormal", "LEFT")
        row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -7) row.title:SetWidth(292)
        row.meta = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.meta:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -28) row.meta:SetWidth(306)
        row.meta:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        row.status = UI.Text(row, "", "GameFontNormalSmall", "RIGHT")
        row.status:SetPoint("RIGHT", row, "RIGHT", -10, 0) row.status:SetWidth(102)
        row:Hide() drawer.rows[index] = row
    end
    drawer.scrollbar = UI:Scrollbar(drawer, 370, function(value)
        if drawer.scrollSilent183 then return end
        drawer.offset183 = math.floor((tonumber(value) or 0) + 0.5)
        OTLGM:RefreshMemberModerationDrawer183()
    end)
    drawer.scrollbar:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -7, -121)
    drawer.empty = UI:EmptyState(drawer, 414, 120, "Nothing here yet", "Create a private report or wait for an official warning.")
    drawer.empty:SetPoint("CENTER", drawer, "CENTER", 0, -10) drawer.empty:Hide()
    drawer.footer = UI.Text(drawer, "", "GameFontNormalSmall", "LEFT")
    drawer.footer:SetPoint("BOTTOMLEFT", drawer, "BOTTOMLEFT", 18, 15) drawer.footer:SetWidth(420)
    drawer.footer:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    drawer.mode183, drawer.offset183 = "REPORTS", 0
    self.ui.memberModerationDrawer183 = drawer
    return drawer
end

function OTLGM:RefreshMemberModerationDrawer183()
    local drawer = self.ui and self.ui.memberModerationDrawer183
    if not drawer then return false end
    local reportsMode = drawer.mode183 ~= "WARNINGS"
    local list = reportsMode and self:GetOwnModerationReports183() or self:GetOwnModerationWarnings183()
    UI:SetSelected(drawer.reportsTab, reportsMode) UI:SetSelected(drawer.warningsTab, not reportsMode)
    drawer.subtitle:SetText(reportsMode
        and "Only reports authored by this character are shown. Submitted means a validated Leadership client acknowledged receipt."
        or "Acknowledge means only that you saw the warning; it does not mean agreement.")
    local capacity, maximum = table.getn(drawer.rows), math.max(0, table.getn(list) - table.getn(drawer.rows))
    drawer.offset183 = math.max(0, math.min(maximum, tonumber(drawer.offset183) or 0))
    drawer.scrollSilent183 = true
    if drawer.scrollbar.SetScrollMetrics180 then drawer.scrollbar:SetScrollMetrics180(table.getn(list), capacity, drawer.offset183)
    else drawer.scrollbar:SetMinMaxValues(0, maximum) drawer.scrollbar:SetValue(drawer.offset183) end
    drawer.scrollSilent183 = nil
    local index, row, record
    for index = 1, table.getn(drawer.rows) do
        row, record = drawer.rows[index], list[drawer.offset183 + index]
        if record then
            row.otlRecordId183, row.otlKind183 = record.id, reportsMode and "REPORT" or "WARNING"
            if reportsMode then
                row.title:SetText(Short183(ReportTypeLabel183(record.reportType) .. " — " .. ReportCategoryLabel183(record.reportType, record.category), 54))
                row.meta:SetText(FormatModerationDate183(self, record.createdAt) .. (record.target and record.target ~= "" and ("  •  Target: " .. ShortName183(record.target)) or ""))
                if record.status == "WITHDRAWN" then
                    -- CP7: withdrawal is already authoritative locally. `delivery=PENDING`
                    -- only means no compatible Leadership peer has received the control
                    -- packet yet; presenting both words looked like the report itself was
                    -- still pending. Keep transport state as-is and fix only the UI label.
                    row.status:SetText("Withdrawn by author\n" .. (record.withdrawPendingR30 and "Local only" or "Withdrawal queued"))
                    row.status:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
                else
                    row.status:SetText(ReportStatusLabel183(record.status or "NEW") .. "\n" .. tostring(record.delivery or "PENDING"))
                    if record.delivery == "SUBMITTED" then row.status:SetTextColor(C.green[1], C.green[2], C.green[3])
                    elseif record.delivery == "SENDING" then row.status:SetTextColor(C.orange[1], C.orange[2], C.orange[3])
                    else row.status:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3]) end
                end
            else
                row.title:SetText(Short183(WarningCategoryLabel183(record.category) .. " — " .. tostring(record.reason or "Official warning"), 58))
                row.meta:SetText(FormatModerationDate183(self, record.issuedAt) .. (record.acknowledged and "  •  Seen" or "  •  Not acknowledged"))
                row.status:SetText(record.active and ("Active\n" .. tostring(self:GetActiveWarningCount183(PlayerName183(), false)) .. "/2")
                    or ("Inactive\n" .. WarningClearLabel183(record.clearReason or "DECISION")))
                if record.active then row.status:SetTextColor(C.red[1], C.red[2], C.red[3]) else row.status:SetTextColor(C.grey[1], C.grey[2], C.grey[3]) end
            end
            row:Show()
        else row.otlRecordId183 = nil row.otlKind183 = nil row:Hide() end
    end
    SetShown183(drawer.empty, table.getn(list) == 0)
    drawer.empty.titleText:SetText(reportsMode and "No reports yet" or "No warnings")
    drawer.empty.bodyText:SetText(reportsMode and "Use New Report to contact validated Leadership privately." or "Official warnings for this character will appear here.")
    drawer.footer:SetText(tostring(table.getn(list)) .. (reportsMode and " own report(s)  •  bounded storage " .. tostring(MAX_OWN_REPORTS_183)
        or " warning record(s)  •  inactive records remain in history"))
    return true
end

function OTLGM:OpenMemberModerationDrawer183(mode)
    if not self.ui or not self.ui.main then self:BuildUI() end
    local drawer = self:BuildMemberModerationDrawer183()
    if not drawer then return false end
    drawer.mode183 = mode == "WARNINGS" and "WARNINGS" or "REPORTS" drawer.offset183 = 0
    self:RefreshMemberModerationDrawer183()
    return self:ShowShellDrawer(drawer)
end

function OTLGM:BuildOwnReportDetail183()
    self.ui = self.ui or {}
    if self.ui.ownReportDetail183 then return self.ui.ownReportDetail183 end
    if not self.ui.modalHost then return nil end
    local modal = UI:Modal(self.ui.modalHost, 610, 488)
    modal:SetPoint("CENTER", self.ui.modalHost, "CENTER", 0, 0) modal.otlDiagnosticName180 = "Own Report Detail"
    modal.title = UI.Text(modal, "My Report", "GameFontNormalLarge", "LEFT")
    modal.title:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -18) modal.title:SetWidth(470) modal.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    modal.close = UI:IconButton(modal, "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 28, 28, function() OTLGM:CloseModal180(modal, "report-detail-close") end, "Close", "utility")
    modal.close:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -14, -13)
    modal.meta = UI.Text(modal, "", "GameFontNormalSmall", "LEFT")
    modal.meta:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -53) modal.meta:SetWidth(570) modal.meta:SetHeight(38) modal.meta:SetJustifyV("TOP")
    modal.meta:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.bodyCard = UI:Card(modal, 570, 96, "Your message") modal.bodyCard:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -92)
    modal.body = UI.Text(modal.bodyCard, "", "GameFontNormalSmall", "LEFT")
    modal.body:SetPoint("TOPLEFT", modal.bodyCard, "TOPLEFT", 12, -31) modal.body:SetWidth(546) modal.body:SetHeight(56) modal.body:SetJustifyV("TOP")
    modal.timelineTitle = UI.Text(modal, "TIMELINE", "GameFontNormalSmall", "LEFT")
    modal.timelineTitle:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -201) modal.timelineTitle:SetWidth(200)
    modal.timelineTitle:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    modal.timeline = {}
    local index
    for index = 1, 5 do
        local line = UI.Text(modal, "", "GameFontNormalSmall", "LEFT")
        line:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -220 - ((index - 1) * 24)) line:SetWidth(570) line:SetHeight(22)
        line:SetTextColor(C.grey[1], C.grey[2], C.grey[3]) line:Hide() modal.timeline[index] = line
    end
    modal.followLabel = UI.Text(modal, "LEADERSHIP IS WAITING FOR A SHORT FOLLOW-UP", "GameFontNormalSmall", "LEFT")
    modal.followLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -348) modal.followLabel:SetWidth(420)
    modal.followLabel:SetTextColor(C.orange[1], C.orange[2], C.orange[3])
    modal.follow = UI:EditBox(modal, 452, 64, { multiline = true, maxLetters = MAX_RESPONSE_183, placeholder = "Add the requested clarification..." })
    modal.follow:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -366)
    modal.sendFollow = UI:Button(modal, "Send", 108, 30, function()
        local ok, message = OTLGM:SubmitReportFollowup183(modal.otlReportId183, modal.follow:GetText() or "")
        if ok then SetEditText183(modal.follow, "") OTLGM:RefreshOwnReportDetail183()
            if OTLGM.ShowToast then OTLGM:ShowToast("Follow-up sent privately.", "success") end
        elseif OTLGM.ShowToast then OTLGM:ShowToast(tostring(message or "Follow-up could not be sent."), "error") end
    end, "primary")
    modal.sendFollow:SetPoint("LEFT", modal.follow, "RIGHT", 10, 0)
    modal.edit = UI:Button(modal, "Edit", 96, 30, function()
        local id = modal.otlReportId183
        OTLGM:CloseModal180(modal, "report-detail-edit")
        OTLGM:OpenEditOwnReportR30(id)
    end, "primary")
    modal.edit:SetPoint("BOTTOMLEFT", modal, "BOTTOMLEFT", 20, 16)
    modal.withdraw = UI:Button(modal, "Withdraw", 108, 30, function()
        local id = modal.otlReportId183
        OTLGM:ShowConfirm("Withdraw report?", "The original report will remain in the moderation audit history, but Leadership will see it as withdrawn by the author.",
            "Withdraw", function()
                local ok, message = OTLGM:WithdrawOwnModerationReportR30(id)
                if ok then OTLGM:RefreshOwnReportDetail183()
                elseif OTLGM.ShowToast then OTLGM:ShowToast(tostring(message or "Report could not be withdrawn."), "error") end
            end)
    end, "danger")
    modal.withdraw:SetPoint("LEFT", modal.edit, "RIGHT", 10, 0)
    modal.done = UI:Button(modal, "Close", 96, 30, function() OTLGM:CloseModal180(modal, "report-detail-close") end, "secondary")
    modal.done:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -20, 16)
    self.ui.ownReportDetail183 = modal
    return modal
end

function OTLGM:RefreshOwnReportDetail183()
    local modal = self.ui and self.ui.ownReportDetail183
    local state = self:EnsureModeration183()
    local report = modal and state and state.ownReports[modal.otlReportId183 or ""] or nil
    if type(report) ~= "table" or not IsSelf183(self, report.author) then return false end
    modal.title:SetText(ReportTypeLabel183(report.reportType) .. "  •  " .. ReportStatusLabel183(report.status or "NEW"))
    modal.meta:SetText(ReportCategoryLabel183(report.reportType, report.category)
        .. (report.target and report.target ~= "" and ("  •  Target: " .. ShortName183(report.target)) or "")
        .. "\n" .. FormatModerationDate183(self, report.createdAt) .. "  •  Delivery: " .. tostring(report.delivery or "PENDING"))
    modal.body:SetText(tostring(report.text or ""))
    local timeline = EnsureTimeline183(report)
    local index, sourceIndex, entry
    for index = 1, table.getn(modal.timeline) do
        sourceIndex = table.getn(timeline) - index + 1 entry = timeline[sourceIndex]
        if entry then
            modal.timeline[index]:SetText(FormatModerationDate183(self, entry.ts) .. "  •  " .. tostring(entry.kind or "UPDATE")
                .. "  •  " .. Short183(entry.text or "", 72))
            modal.timeline[index]:Show()
        else modal.timeline[index]:Hide() end
    end
    local waiting = report.status == "WAITING"
    local terminal = TERMINAL_REPORT_STATUSES_183[report.status or "NEW"] and true or false
    SetShown183(modal.followLabel, waiting) SetShown183(modal.follow, waiting) SetShown183(modal.sendFollow, waiting)
    SetShown183(modal.edit, CanEditOwnReportR30(report))
    SetShown183(modal.withdraw, not terminal)
    return true
end

function OTLGM:OpenOwnReportDetail183(id)
    local state = self:EnsureModeration183()
    local report = state and state.ownReports[tostring(id or "")]
    if type(report) ~= "table" or not IsSelf183(self, report.author) then return false end
    local modal = self:BuildOwnReportDetail183()
    if not modal then return false end
    modal.otlReportId183 = report.id SetEditText183(modal.follow, "")
    self:RefreshOwnReportDetail183()
    return self:ShowShellModal(modal)
end

function OTLGM:BuildOwnWarningDetail183()
    self.ui = self.ui or {}
    if self.ui.ownWarningDetail183 then return self.ui.ownWarningDetail183 end
    if not self.ui.modalHost then return nil end
    local modal = UI:Modal(self.ui.modalHost, 580, 388)
    modal:SetPoint("CENTER", self.ui.modalHost, "CENTER", 0, 0) modal.otlDiagnosticName180 = "Official Guild Warning"
    modal.title = UI.Text(modal, "Official Guild Warning", "GameFontNormalLarge", "LEFT")
    modal.title:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -18) modal.title:SetWidth(440) modal.title:SetTextColor(C.red[1], C.red[2], C.red[3])
    modal.close = UI:IconButton(modal, "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 28, 28, function() OTLGM:CloseModal180(modal, "warning-detail-close") end, "Close", "utility")
    modal.close:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -14, -13)
    modal.meta = UI.Text(modal, "", "GameFontNormalSmall", "LEFT")
    modal.meta:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -56) modal.meta:SetWidth(540) modal.meta:SetHeight(44) modal.meta:SetJustifyV("TOP")
    modal.meta:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.reasonCard = UI:Card(modal, 540, 110, "Official reason") modal.reasonCard:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -108)
    modal.reason = UI.Text(modal.reasonCard, "", "GameFontNormal", "LEFT")
    modal.reason:SetPoint("TOPLEFT", modal.reasonCard, "TOPLEFT", 12, -34) modal.reason:SetWidth(516) modal.reason:SetHeight(64) modal.reason:SetJustifyV("TOP")
    modal.notice = UI.Text(modal, "Acknowledging means only “I saw this warning”. It does not mean that you agree with it.", "GameFontNormalSmall", "LEFT")
    modal.notice:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -235) modal.notice:SetWidth(540) modal.notice:SetHeight(42)
    modal.notice:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.ack = UI:Button(modal, "Acknowledge — Seen", 166, 30, function()
        local ok, message = OTLGM:AcknowledgeOwnWarning183(modal.otlWarningId183)
        if ok then OTLGM:RefreshOwnWarningDetail183()
        elseif OTLGM.ShowToast then OTLGM:ShowToast(tostring(message or "Could not acknowledge warning."), "error") end
    end, "primary")
    modal.ack:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -124, 16)
    modal.done = UI:Button(modal, "Close", 96, 30, function() OTLGM:CloseModal180(modal, "warning-detail-close") end, "secondary")
    modal.done:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -20, 16)
    self.ui.ownWarningDetail183 = modal
    return modal
end

function OTLGM:RefreshOwnWarningDetail183()
    local modal = self.ui and self.ui.ownWarningDetail183
    local state = self:EnsureModeration183()
    local warning = modal and state and state.ownWarnings[modal.otlWarningId183 or ""] or nil
    if type(warning) ~= "table" or not IsSelf183(self, warning.target) then return false end
    local activeCount = ActiveWarningCount183(state.ownWarnings, warning.target)
    modal.meta:SetText(WarningCategoryLabel183(warning.category) .. "  •  " .. FormatModerationDate183(self, warning.issuedAt)
        .. "\n" .. (warning.active and ("Active warnings: " .. tostring(activeCount) .. "/2")
            or ("Inactive  •  " .. WarningClearLabel183(warning.clearReason or "DECISION"))))
    modal.reason:SetText(tostring(warning.reason or "Official warning"))
    SetShown183(modal.ack, warning.active and not warning.acknowledged)
    if warning.acknowledged then modal.notice:SetText("Seen on " .. FormatModerationDate183(self, warning.acknowledgedAt) .. ". Acknowledgement is stored separately from agreement.")
    else modal.notice:SetText("Acknowledging means only “I saw this warning”. It does not mean that you agree with it.") end
    return true
end

function OTLGM:OpenOwnWarningDetail183(id)
    local state = self:EnsureModeration183()
    local warning = state and state.ownWarnings[tostring(id or "")]
    if type(warning) ~= "table" or not IsSelf183(self, warning.target) then return false end
    local modal = self:BuildOwnWarningDetail183()
    if not modal then return false end
    modal.otlWarningId183 = warning.id self:RefreshOwnWarningDetail183()
    return self:ShowShellModal(modal)
end

function OTLGM:GetOfficerEscalations183(target)
    if not self:IsOfficerMode() then return {} end
    local state, normalized = self:EnsureModeration183(), Normalize183(self, target or "")
    MigrateLegacyEscalationsRC4(self, state)
    return CollectRecords183(state and state.officerCases, function(record)
        return self:CanCurrentClientAccessModerationRecord183("C", record)
            and tostring(record.caseKind183 or "REPORT") == "ESCALATION"
            and not TERMINAL_REPORT_STATUSES_183[record.status or "NEW"]
            and (normalized == "" or Normalize183(self, record.target) == normalized)
    end)
end

function OTLGM:CloseEscalation183(id)
    if not self:IsOfficerMode() then return false end
    local state = self:EnsureModeration183()
    local record = state and state.officerCases[tostring(id or "")]
    if type(record) ~= "table" or tostring(record.caseKind183 or "") ~= "ESCALATION" then return false end
    return self:UpdateOfficerCase183(record.id, "RESOLVED", "", record.privateComment or "", "Leadership escalation reviewed")
end

function OTLGM:BuildOfficerCasesDrawer183()
    self.ui = self.ui or {}
    if self.ui.officerCasesDrawer183 then return self.ui.officerCasesDrawer183 end
    if not self.ui.drawerHost then return nil end
    local drawer = UI:Drawer(self.ui.drawerHost, 530, 536)
    drawer:SetPoint("TOPRIGHT", self.ui.drawerHost, "TOPRIGHT", -10, -10)
    drawer.title = UI.Text(drawer, "Officer Cases", "GameFontNormalLarge", "LEFT")
    drawer.title:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -18) drawer.title:SetWidth(380)
    drawer.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    drawer.close = UI:IconButton(drawer, "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 28, 28,
        function() OTLGM:CloseShellDrawer() end, "Close", "utility")
    drawer.close:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -12, -12)
    drawer.casesTab = UI:Tab(drawer, "Cases", 94, function()
        drawer.mode183 = "CASES" drawer.statusFilter183 = nil drawer.limitOnly183 = nil drawer.unassignedOnly183 = nil drawer.offset183 = 0 OTLGM:RefreshOfficerCasesDrawer183()
    end)
    drawer.casesTab:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -52)
    drawer.warningsTab = UI:Tab(drawer, "Warnings", 102, function()
        drawer.mode183 = "WARNINGS" drawer.statusFilter183 = nil drawer.limitOnly183 = nil drawer.unassignedOnly183 = nil drawer.offset183 = 0 OTLGM:RefreshOfficerCasesDrawer183()
    end)
    drawer.warningsTab:SetPoint("LEFT", drawer.casesTab, "RIGHT", 8, 0)
    drawer.attentionTab = UI:Tab(drawer, "Needs Attention", 132, function()
        drawer.mode183 = "ATTENTION" drawer.statusFilter183 = nil drawer.limitOnly183 = nil drawer.unassignedOnly183 = nil drawer.offset183 = 0 OTLGM:RefreshOfficerCasesDrawer183()
    end)
    drawer.attentionTab:SetPoint("LEFT", drawer.warningsTab, "RIGHT", 8, 0)
    drawer.filterText = UI.Text(drawer, "All members", "GameFontNormalSmall", "LEFT")
    drawer.filterText:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -91) drawer.filterText:SetWidth(330)
    drawer.filterText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    drawer.clearFilter = UI:Button(drawer, "Clear Filter", 96, 24, function()
        drawer.target183 = nil drawer.statusFilter183 = nil drawer.limitOnly183 = nil drawer.unassignedOnly183 = nil drawer.offset183 = 0 OTLGM:RefreshOfficerCasesDrawer183()
    end, "utility")
    drawer.clearFilter:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -18, -85)
    drawer.rows = {}
    local index
    for index = 1, 6 do
        local row = UI:TableRow(drawer, 476, 51, function(button)
            if button.otlKind183 == "CASE" then OTLGM:OpenOfficerCaseDetail183(button.otlRecordId183)
            elseif button.otlKind183 == "WARNING" then OTLGM:OpenOfficerWarningDetail183(button.otlRecordId183)
            elseif button.otlKind183 == "ESCALATION" then OTLGM:OpenOfficerCaseDetail183(button.otlRecordId183)
            elseif button.otlKind183 == "ATTENTION_NEW" then
                drawer.mode183 = "CASES" drawer.statusFilter183 = "NEW" drawer.offset183 = 0 OTLGM:RefreshOfficerCasesDrawer183()
            elseif button.otlKind183 == "ATTENTION_UNASSIGNED" then
                drawer.mode183 = "CASES" drawer.statusFilter183 = nil drawer.unassignedOnly183 = true drawer.offset183 = 0 OTLGM:RefreshOfficerCasesDrawer183()
            elseif button.otlKind183 == "ATTENTION_WAITING" then
                drawer.mode183 = "CASES" drawer.statusFilter183 = "WAITING" drawer.offset183 = 0 OTLGM:RefreshOfficerCasesDrawer183()
            elseif button.otlKind183 == "ATTENTION_LIMIT" then
                drawer.mode183 = "WARNINGS" drawer.limitOnly183 = true drawer.offset183 = 0 OTLGM:RefreshOfficerCasesDrawer183()
            elseif button.otlKind183 == "ATTENTION_ESCALATION" then
                drawer.mode183 = "ESCALATIONS" drawer.offset183 = 0 OTLGM:RefreshOfficerCasesDrawer183()
            end
        end)
        row:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -119 - ((index - 1) * 55))
        row.title = UI.Text(row, "", "GameFontNormal", "LEFT")
        row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -7) row.title:SetWidth(336)
        row.meta = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.meta:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -29) row.meta:SetWidth(350)
        row.meta:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        row.status = UI.Text(row, "", "GameFontNormalSmall", "RIGHT")
        row.status:SetPoint("RIGHT", row, "RIGHT", -10, 0) row.status:SetWidth(112)
        row:Hide() drawer.rows[index] = row
    end
    drawer.scrollbar = UI:Scrollbar(drawer, 321, function(value)
        if drawer.scrollSilent183 then return end
        drawer.offset183 = math.floor((tonumber(value) or 0) + 0.5) OTLGM:RefreshOfficerCasesDrawer183()
    end)
    drawer.scrollbar:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -7, -118)
    drawer.empty = UI:EmptyState(drawer, 470, 120, "No matching records", "There are no cases or warnings for this filter.")
    drawer.empty:SetPoint("CENTER", drawer, "CENTER", 0, -8) drawer.empty:Hide()
    drawer.issue = UI:Button(drawer, "Issue Warning", 116, 28, function()
        if drawer.target183 then OTLGM:OpenWarningEditor183(drawer.target183) end
    end, "danger")
    drawer.issue:SetPoint("BOTTOMLEFT", drawer, "BOTTOMLEFT", 18, 14)
    drawer.footer = UI.Text(drawer, "", "GameFontNormalSmall", "RIGHT")
    drawer.footer:SetPoint("BOTTOMRIGHT", drawer, "BOTTOMRIGHT", -18, 20) drawer.footer:SetWidth(350)
    drawer.footer:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    drawer.mode183, drawer.offset183 = "CASES", 0
    self.ui.officerCasesDrawer183 = drawer
    return drawer
end

function OTLGM:RefreshOfficerCasesDrawer183()
    local drawer = self.ui and self.ui.officerCasesDrawer183
    if not drawer or not self:IsOfficerMode() then return false end
    local mode = drawer.mode183 or "CASES"
    local moderationState = self:EnsureModeration183()
    UI:SetSelected(drawer.casesTab, mode == "CASES") UI:SetSelected(drawer.warningsTab, mode == "WARNINGS")
    UI:SetSelected(drawer.attentionTab, mode == "ATTENTION" or mode == "ESCALATIONS")
    drawer.filterText:SetText(drawer.target183 and ("Member filter: " .. ShortName183(drawer.target183))
        or (drawer.statusFilter183 and ("Status filter: " .. ReportStatusLabel183(drawer.statusFilter183))
            or (drawer.unassignedOnly183 and "Unassigned active cases"
                or (drawer.limitOnly183 and "Players at warning limit" or "All private Leadership records"))))
    SetShown183(drawer.clearFilter, drawer.target183 or drawer.statusFilter183 or drawer.limitOnly183 or drawer.unassignedOnly183)
    SetShown183(drawer.issue, drawer.target183 and mode ~= "ATTENTION" and mode ~= "ESCALATIONS")

    local list, activeWarningCounts = {}, nil
    if mode == "CASES" then
        list = self:GetOfficerCases183(drawer.target183, drawer.statusFilter183)
        if drawer.unassignedOnly183 then
            local filtered, filterIndex = {}, nil
            for filterIndex = 1, table.getn(list) do
                if tostring(list[filterIndex].assignedTo183 or "") == "" and not TERMINAL_REPORT_STATUSES_183[list[filterIndex].status or "NEW"] then
                    table.insert(filtered, list[filterIndex])
                end
            end
            list = filtered
        end
    elseif mode == "WARNINGS" then
        list = self:GetOfficerWarnings183(drawer.target183, drawer.limitOnly183)
        activeWarningCounts = {}
        local warningKey, warningRecord, normalizedTarget
        for warningKey, warningRecord in pairs(moderationState and moderationState.officerWarnings or {}) do
            if type(warningRecord) == "table" and warningRecord.active == true then
                normalizedTarget = Normalize183(self, warningRecord.target)
                activeWarningCounts[normalizedTarget] = (tonumber(activeWarningCounts[normalizedTarget]) or 0) + 1
            end
        end
    elseif mode == "ESCALATIONS" then list = self:GetOfficerEscalations183(drawer.target183)
    else
        local attention = self:GetNeedsAttention183()
        list = {
            { attentionKind = "ATTENTION_ESCALATION", title = "Escalation Required", meta = "Manual Leadership decision — no automatic punishment", value = attention.escalations },
            { attentionKind = "ATTENTION_UNASSIGNED", title = "New / Unassigned Cases", meta = "Active cases that no Officer has taken yet", value = attention.unassigned },
            { attentionKind = "ATTENTION_WAITING", title = "Waiting for Player", meta = "Authors owe a requested clarification", value = attention.waiting },
            { attentionKind = "ATTENTION_LIMIT", title = "Players at Warning Limit", meta = "Two active warnings without a resolved Leadership decision", value = attention.warningLimit },
        }
    end
    local capacity, maximum = table.getn(drawer.rows), math.max(0, table.getn(list) - table.getn(drawer.rows))
    drawer.offset183 = math.max(0, math.min(maximum, tonumber(drawer.offset183) or 0))
    drawer.scrollSilent183 = true
    if drawer.scrollbar.SetScrollMetrics180 then drawer.scrollbar:SetScrollMetrics180(table.getn(list), capacity, drawer.offset183)
    else drawer.scrollbar:SetMinMaxValues(0, maximum) drawer.scrollbar:SetValue(drawer.offset183) end
    drawer.scrollSilent183 = nil
    local index, row, record
    for index = 1, table.getn(drawer.rows) do
        row, record = drawer.rows[index], list[drawer.offset183 + index]
        if record then
            row.otlRecordId183 = record.id row.otlKind183 = nil
            if mode == "CASES" then
                row.otlKind183 = "CASE"
                row.title:SetText(Short183(tostring(record.author or "Unknown") .. (record.target and record.target ~= "" and (" -> " .. record.target) or "")
                    .. "  •  " .. ReportTypeLabel183(record.reportType), 62))
                local assignmentText = record.assignedTo183 and record.assignedTo183 ~= "" and ("Assigned: " .. tostring(record.assignedTo183)) or "Unassigned"
                row.meta:SetText(Short183(ReportCategoryLabel183(record.reportType, record.category) .. "  •  " .. assignmentText
                    .. "  •  " .. FormatModerationDate183(self, record.createdAt), 76))
                row.status:SetText(ReportStatusLabel183(record.status or "NEW"))
                if record.status == "NEW" or record.status == "WAITING" then row.status:SetTextColor(C.orange[1], C.orange[2], C.orange[3])
                else row.status:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3]) end
            elseif mode == "WARNINGS" then
                row.otlKind183 = "WARNING"
                row.title:SetText(Short183(tostring(record.target or "Unknown") .. "  •  " .. WarningCategoryLabel183(record.category), 62))
                row.meta:SetText(Short183(tostring(record.reason or "Official warning"), 68))
                row.status:SetText(record.active and ("Active " .. tostring(activeWarningCounts[Normalize183(self, record.target)] or 0) .. "/2")
                    or ("Inactive\n" .. WarningClearLabel183(record.clearReason or "DECISION")))
                if record.active then row.status:SetTextColor(C.red[1], C.red[2], C.red[3]) else row.status:SetTextColor(C.grey[1], C.grey[2], C.grey[3]) end
            elseif mode == "ESCALATIONS" then
                row.otlKind183 = "ESCALATION"
                row.title:SetText("Escalation  •  " .. tostring(record.target or "Unknown"))
                row.meta:SetText(Short183(tostring(record.statusReason183 or record.text or "Leadership review required"), 68))
                row.status:SetText(ReportStatusLabel183(record.status or "REVIEW"))
                if TERMINAL_REPORT_STATUSES_183[record.status or "REVIEW"] then row.status:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
                else row.status:SetTextColor(C.red[1], C.red[2], C.red[3]) end
            else
                row.otlKind183 = record.attentionKind row.otlRecordId183 = nil
                row.title:SetText(tostring(record.title)) row.meta:SetText(tostring(record.meta))
                row.status:SetText(tostring(record.value or 0))
                if (tonumber(record.value) or 0) > 0 then row.status:SetTextColor(C.orange[1], C.orange[2], C.orange[3])
                else row.status:SetTextColor(C.grey[1], C.grey[2], C.grey[3]) end
            end
            row:Show()
        else row.otlRecordId183 = nil row.otlKind183 = nil row:Hide() end
    end
    SetShown183(drawer.empty, table.getn(list) == 0)
    drawer.footer:SetText(mode == "ATTENTION" and "Only reports and warning tasks that need Leadership attention"
        or (tostring(table.getn(list)) .. " record(s)  •  private / targeted"))
    return true
end

function OTLGM:OpenOfficerCases183(target, mode)
    if not self:IsOfficerMode() then
        if self.ShowToast then self:ShowToast("Officer permissions are required.", "error") end
        return false
    end
    if not self.ui or not self.ui.main then self:BuildUI() end
    local drawer = self:BuildOfficerCasesDrawer183()
    if not drawer then return false end
    drawer.target183 = target and ShortName183(target) or nil
    drawer.mode183 = mode == "WARNINGS" and "WARNINGS" or (mode == "ATTENTION" and "ATTENTION" or "CASES")
    drawer.statusFilter183 = nil drawer.limitOnly183 = nil drawer.unassignedOnly183 = nil drawer.offset183 = 0
    self:RefreshOfficerCasesDrawer183()
    return self:ShowShellDrawer(drawer)
end

function OTLGM:BuildOfficerCaseDetail183()
    self.ui = self.ui or {}
    if self.ui.officerCaseDetail183 then return self.ui.officerCaseDetail183 end
    if not self.ui.drawerHost then return nil end
    local drawer = UI:Drawer(self.ui.drawerHost, 620, 536)
    drawer:SetPoint("TOPRIGHT", self.ui.drawerHost, "TOPRIGHT", -10, -10)
    drawer.otlDiagnosticName180 = "Officer Case Detail"
    drawer.back = UI:Button(drawer, "< Cases", 78, 26, function() OTLGM:OpenOfficerCases183(nil, "CASES") end, "utility")
    drawer.back:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -14)
    drawer.title = UI.Text(drawer, "Officer Case", "GameFontNormalLarge", "LEFT")
    drawer.title:SetPoint("TOPLEFT", drawer, "TOPLEFT", 108, -18) drawer.title:SetWidth(400)
    drawer.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    drawer.close = UI:IconButton(drawer, "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 28, 28, function() OTLGM:CloseShellDrawer() end, "Close", "utility")
    drawer.close:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -12, -12)
    drawer.meta = UI.Text(drawer, "", "GameFontNormalSmall", "LEFT")
    drawer.meta:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -54) drawer.meta:SetWidth(584) drawer.meta:SetHeight(34)
    drawer.meta:SetJustifyV("TOP") drawer.meta:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    drawer.assignment = UI.Text(drawer, "", "GameFontNormalSmall", "LEFT")
    drawer.assignment:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -91) drawer.assignment:SetWidth(420)
    drawer.assignment:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    drawer.assign = UI:Button(drawer, "Take Case", 130, 26, function()
        local state = OTLGM:EnsureModeration183()
        local case = state and state.officerCases[drawer.otlCaseId183 or ""]
        if not case then return end
        local current, player = ShortName183(case.assignedTo183 or ""), PlayerName183()
        if current == "" then
            local ok, message = OTLGM:AssignOfficerCase183(case.id, player)
            if not ok and OTLGM.ShowToast then OTLGM:ShowToast(tostring(message or "Could not take case."), "error") end
            OTLGM:RefreshOfficerCaseDetail183(false)
        elseif Normalize183(OTLGM, current) == Normalize183(OTLGM, player) then
            local ok, message = OTLGM:AssignOfficerCase183(case.id, "")
            if not ok and OTLGM.ShowToast then OTLGM:ShowToast(tostring(message or "Could not release case."), "error") end
            OTLGM:RefreshOfficerCaseDetail183(false)
        else
            local caseId = case.id
            OTLGM:ShowConfirm("Take Over Case?", "This case is currently assigned to " .. current .. ". Take responsibility for it?", "Take Over", function()
                local ok, message = OTLGM:AssignOfficerCase183(caseId, player)
                if not ok and OTLGM.ShowToast then OTLGM:ShowToast(tostring(message or "Could not take over case."), "error") end
                OTLGM:OpenOfficerCaseDetail183(caseId)
            end, function() OTLGM:OpenOfficerCaseDetail183(caseId) end)
        end
    end, "secondary")
    drawer.assign:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -18, -84)
    drawer.bodyCard = UI:Card(drawer, 584, 76, "Report text")
    drawer.bodyCard:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -118)
    drawer.body = UI.Text(drawer.bodyCard, "", "GameFontNormalSmall", "LEFT")
    drawer.body:SetPoint("TOPLEFT", drawer.bodyCard, "TOPLEFT", 12, -30) drawer.body:SetWidth(560) drawer.body:SetHeight(38) drawer.body:SetJustifyV("TOP")
    drawer.diagnosticsCard183 = UI:Card(drawer, 584, 24)
    drawer.diagnosticsCard183:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -201)
    drawer.diagnosticsCard183:EnableMouse(true)
    drawer.diagnostics = UI.Text(drawer.diagnosticsCard183, "", "GameFontNormalSmall", "LEFT")
    drawer.diagnostics:SetPoint("LEFT", drawer.diagnosticsCard183, "LEFT", 8, 0) drawer.diagnostics:SetWidth(568) drawer.diagnostics:SetHeight(18)
    drawer.diagnostics:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    drawer.diagnosticsCard183:SetScript("OnEnter", function()
        if not GameTooltip or not this.otlFullDiagnostics183 or this.otlFullDiagnostics183 == "" then return end
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:AddLine("Troubleshooting details", 1, 0.82, 0.35)
        GameTooltip:AddLine(this.otlFullDiagnostics183, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    drawer.diagnosticsCard183:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    drawer.status = UI:Button(drawer, "", 194, 28, function()
        local nextStatus = CycleDefinition183(REPORT_STATUSES_183, drawer.status183)
        drawer.status183 = nextStatus[1] OTLGM:RefreshOfficerCaseDetail183(true)
    end, "filter")
    drawer.status:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -232)
    drawer.statusReason = UI:EditBox(drawer, 380, 28, { maxLetters = MAX_STATUS_REASON_183, placeholder = "Status reason (required for On Hold)" })
    drawer.statusReason:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -18, -232)
    drawer.responseLabel = UI.Text(drawer, "LEADERSHIP RESPONSE / QUESTION TO AUTHOR", "GameFontNormalSmall", "LEFT")
    drawer.responseLabel:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -268) drawer.responseLabel:SetWidth(450)
    drawer.responseLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    drawer.response = UI:EditBox(drawer, 584, 44, { multiline = true, maxLetters = MAX_RESPONSE_183, placeholder = "Optional response. Required for Waiting for Player..." })
    drawer.response:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -285)
    drawer.commentLabel = UI.Text(drawer, "PRIVATE CASE COMMENT — LEADERSHIP ONLY", "GameFontNormalSmall", "LEFT")
    drawer.commentLabel:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -337) drawer.commentLabel:SetWidth(450)
    drawer.commentLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    drawer.comment = UI:EditBox(drawer, 584, 38, { multiline = true, maxLetters = MAX_PRIVATE_COMMENT_183, placeholder = "Optional private context; never sent to ordinary members..." })
    drawer.comment:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -354)
    drawer.timelineTitle = UI.Text(drawer, "STATUS HISTORY", "GameFontNormalSmall", "LEFT")
    drawer.timelineTitle:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -400) drawer.timelineTitle:SetWidth(200)
    drawer.timelineTitle:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    drawer.timelineRows183 = {}
    local index
    for index = 1, 4 do
        local line = UI.Text(drawer, "", "GameFontNormalSmall", "LEFT")
        line:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -418 - ((index - 1) * 17)) line:SetWidth(584) line:SetHeight(16)
        line:SetTextColor(C.grey[1], C.grey[2], C.grey[3]) drawer.timelineRows183[index] = line
    end
    drawer.warning = UI:Button(drawer, "Issue Warning", 126, 28, function()
        local state = OTLGM:EnsureModeration183() local case = state and state.officerCases[drawer.otlCaseId183 or ""]
        if case and case.target and case.target ~= "" then OTLGM:OpenWarningEditor183(case.target, case.id) end
    end, "danger")
    drawer.warning:SetPoint("BOTTOMLEFT", drawer, "BOTTOMLEFT", 18, 14)
    drawer.save = UI:Button(drawer, "Save Update", 116, 28, function()
        local ok, message = OTLGM:UpdateOfficerCase183(drawer.otlCaseId183, drawer.status183, drawer.response:GetText() or "",
            drawer.comment:GetText() or "", drawer.statusReason:GetText() or "")
        if ok then SetEditText183(drawer.response, "") OTLGM:RefreshOfficerCaseDetail183(false)
        elseif OTLGM.ShowToast then OTLGM:ShowToast(tostring(message or "Case could not be updated."), "error") end
    end, "primary")
    drawer.save:SetPoint("BOTTOMRIGHT", drawer, "BOTTOMRIGHT", -18, 14)
    self.ui.officerCaseDetail183 = drawer
    return drawer
end

function OTLGM:RefreshOfficerCaseDetail183(keepDraft)
    local drawer = self.ui and self.ui.officerCaseDetail183
    local state = self:EnsureModeration183()
    local case = drawer and state and state.officerCases[drawer.otlCaseId183 or ""] or nil
    if type(case) ~= "table" or not self:IsOfficerMode() then return false end
    if not keepDraft then
        drawer.status183 = case.status or "NEW"
        SetEditText183(drawer.comment, case.privateComment or "")
        SetEditText183(drawer.statusReason, case.statusReason183 or "")
    end
    local escalation = tostring(case.caseKind183 or "REPORT") == "ESCALATION"
    drawer.title:SetText((escalation and "Escalation Case" or "Case") .. "  •  " .. ReportStatusLabel183(drawer.status183 or case.status or "NEW"))
    local targetMember = case.target and case.target ~= "" and self.GetMember and self:GetMember(case.target) or nil
    local targetText = case.target and case.target ~= "" and (self:GetClassColor(targetMember and targetMember.class or "") .. tostring(case.target) .. self.colors.reset) or "None"
    drawer.meta:SetText("Author: " .. tostring(case.author or "Unknown") .. "  •  Target: " .. targetText
        .. "\n" .. ReportTypeLabel183(case.reportType) .. "  •  " .. ReportCategoryLabel183(case.reportType, case.category)
        .. (case.relatedCaseId183 and case.relatedCaseId183 ~= "" and ("  •  Related: " .. tostring(case.relatedCaseId183)) or ""))
    drawer.assignment:SetText(case.assignedTo183 and case.assignedTo183 ~= "" and ("Assigned to: " .. tostring(case.assignedTo183)) or "Assigned to: Unassigned")
    local assigned = ShortName183(case.assignedTo183 or "")
    if assigned == "" then UI:SetText(drawer.assign, "Take Case")
    elseif Normalize183(self, assigned) == Normalize183(self, PlayerName183()) then UI:SetText(drawer.assign, "Release")
    else UI:SetText(drawer.assign, "Take Over") end
    drawer.body:SetText(tostring(case.text or ""))
    local fullDiagnostics183 = case.diagnostics and case.diagnostics ~= "" and tostring(case.diagnostics) or ""
    drawer.diagnosticsCard183.otlFullDiagnostics183 = fullDiagnostics183
    drawer.diagnostics:SetText(fullDiagnostics183 ~= "" and ("Troubleshooting: " .. Short183(fullDiagnostics183, 104)) or "No troubleshooting details attached.")
    UI:SetText(drawer.status, "Status: " .. ReportStatusLabel183(drawer.status183 or case.status or "NEW"))
    UI:SetEnabled(drawer.warning, not escalation and case.target and case.target ~= "", escalation and "Escalation already represents the warning-limit review." or "This report has no target player.")
    local timeline = EnsureTimeline183(case)
    local index, sourceIndex, entry = 1, table.getn(timeline), nil
    while index <= table.getn(drawer.timelineRows183) do
        entry = nil
        while sourceIndex >= 1 and not entry do
            local candidate = timeline[sourceIndex]
            sourceIndex = sourceIndex - 1
            if type(candidate) == "table" and tostring(candidate.kind or "") ~= "RECONCILED" then entry = candidate end
        end
        if entry then
            drawer.timelineRows183[index]:SetText(FormatModerationDate183(self, entry.ts) .. "  •  " .. tostring(entry.kind or "UPDATE")
                .. (entry.actor and entry.actor ~= "" and ("  •  " .. tostring(entry.actor)) or "") .. "  —  " .. Short183(entry.text, 68))
            drawer.timelineRows183[index]:Show()
        else drawer.timelineRows183[index]:SetText("") drawer.timelineRows183[index]:Hide() end
        index = index + 1
    end
    return true
end

function OTLGM:OpenOfficerCaseDetail183(id)
    if not self:IsOfficerMode() then return false end
    local state = self:EnsureModeration183()
    local case = state and state.officerCases[tostring(id or "")]
    if type(case) ~= "table" or not self:CanCurrentClientAccessModerationRecord183("C", case) then return false end
    local drawer = self:BuildOfficerCaseDetail183()
    if not drawer then return false end
    drawer.otlCaseId183 = case.id SetEditText183(drawer.response, "") SetEditText183(drawer.comment, case.privateComment or "")
    SetEditText183(drawer.statusReason, case.statusReason183 or "")
    if case.status == "NEW" then self:MarkOfficerCaseSeen183(case) end
    drawer.status183 = case.status or "SEEN" self:RefreshOfficerCaseDetail183(false)
    return self:ShowShellDrawer(drawer)
end

function OTLGM:BuildWarningEditor183()
    self.ui = self.ui or {}
    if self.ui.warningEditor183 then return self.ui.warningEditor183 end
    if not self.ui.modalHost then return nil end
    local modal = UI:Modal(self.ui.modalHost, 600, 470)
    modal:SetPoint("CENTER", self.ui.modalHost, "CENTER", 0, 0) modal.otlDiagnosticName180 = "Issue Official Warning"
    modal.title = UI.Text(modal, "Issue Official Warning", "GameFontNormalLarge", "LEFT")
    modal.title:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -18) modal.title:SetWidth(470) modal.title:SetTextColor(C.red[1], C.red[2], C.red[3])
    modal.target = UI.Text(modal, "", "GameFontNormal", "LEFT")
    modal.target:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -58) modal.target:SetWidth(560)
    modal.category183 = WARNING_CATEGORIES_183[1][1]
    modal.category = UI:Button(modal, "", 270, 28, function()
        ToggleChoiceMenu183(modal, modal.warningCategoryMenu183, WARNING_CATEGORIES_183, modal.category183, function(key)
            modal.category183 = key
            OTLGM:RefreshWarningEditor183()
        end)
    end, "filter")
    modal.category:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -86)
    modal.warningCategoryMenu183 = BuildChoiceMenu183(modal, 270, table.getn(WARNING_CATEGORIES_183))
    modal.warningCategoryMenu183:SetPoint("TOPLEFT", modal.category, "BOTTOMLEFT", 0, -2)
    modal.count = UI.Text(modal, "", "GameFontNormalSmall", "RIGHT")
    modal.count:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -20, -92) modal.count:SetWidth(180)
    modal.count:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    modal.reasonLabel = UI.Text(modal, "OFFICIAL REASON (VISIBLE TO TARGET)", "GameFontNormalSmall", "LEFT")
    modal.reasonLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -128) modal.reasonLabel:SetWidth(360)
    modal.reasonLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    modal.reason = UI:EditBox(modal, 560, 72, { multiline = true, maxLetters = MAX_WARNING_REASON_183, placeholder = "Short factual reason..." })
    modal.reason:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -146)
    modal.commentLabel = UI.Text(modal, "PRIVATE OFFICER COMMENT (LEADERSHIP ONLY)", "GameFontNormalSmall", "LEFT")
    modal.commentLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -229) modal.commentLabel:SetWidth(360)
    modal.commentLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    modal.comment = UI:EditBox(modal, 560, 58, { multiline = true, maxLetters = MAX_PRIVATE_COMMENT_183, placeholder = "Optional context; never sent to ordinary members..." })
    modal.comment:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -247)
    modal.announce = UI:Check(modal, "Announce generic notice in Guild Chat", 310, function() end)
    modal.announce:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -318)
    modal.announce.otlTooltip = "Explicit action only. The notice contains the target and warning count, never report author, evidence, private comment or full reason."
    modal.fallback = UI:Check(modal, "Fallback whisper if addon is unavailable", 310, function() end)
    modal.fallback:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -346)
    modal.fallback.otlTooltip = "Sends only the generic official 1/2 or 2/2 notice as a normal whisper."
    modal.safety = UI.Text(modal, "At 2/2 the next attempt creates Escalation Required. The addon never kicks, demotes, mutes or removes anyone automatically.", "GameFontNormalSmall", "LEFT")
    modal.safety:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -378) modal.safety:SetWidth(560) modal.safety:SetHeight(28)
    modal.safety:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.cancel = UI:Button(modal, "Cancel", 94, 30, function()
        local returnCase = modal.relatedCaseId183
        OTLGM:CloseModal180(modal, "warning-cancel")
        if returnCase and returnCase ~= "" then OTLGM:OpenOfficerCaseDetail183(returnCase) end
    end, "secondary")
    modal.cancel:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -142, 16)
    modal.issue = UI:Button(modal, "Issue Warning", 114, 30, function()
        local ok, message = OTLGM:IssueWarning183(modal.target183, modal.category183, modal.reason:GetText() or "",
            modal.comment:GetText() or "", modal.announce:GetChecked() and true or false, modal.fallback:GetChecked() and true or false,
            modal.relatedCaseId183 or "")
        if ok or message == "ESCALATION" then
            local returnCase = modal.relatedCaseId183
            OTLGM:CloseModal180(modal, "save-success")
            if returnCase and returnCase ~= "" then OTLGM:OpenOfficerCaseDetail183(returnCase) end
        elseif OTLGM.ShowToast then OTLGM:ShowToast(tostring(message or "Warning could not be issued."), "error") end
    end, "danger")
    modal.issue:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -20, 16)
    self.ui.warningEditor183 = modal
    return modal
end

function OTLGM:RefreshWarningEditor183()
    local modal = self.ui and self.ui.warningEditor183
    if not modal then return false end
    local active = self:GetActiveWarningCount183(modal.target183, true)
    modal.target:SetText("Target: " .. tostring(modal.target183 or "Unknown")
        .. (modal.relatedCaseId183 and modal.relatedCaseId183 ~= "" and ("  •  Related Case " .. tostring(modal.relatedCaseId183)) or ""))
    modal.count:SetText(active >= 2 and "2/2  •  next = escalation" or (tostring(active) .. "/2 active"))
    UI:SetText(modal.category, "Category: " .. WarningCategoryLabel183(modal.category183) .. "  v")
    UI:SetText(modal.issue, active >= 2 and "Create Escalation" or "Issue Warning")
    return true
end

function OTLGM:OpenWarningEditor183(target, relatedCaseId)
    if not self:IsOfficerMode() then return false end
    local member = self.GetMember and self:GetMember(target) or nil
    if not member then if self.ShowToast then self:ShowToast("Select a current guild member from Roster.", "error") end return false end
    local modal = self:BuildWarningEditor183()
    if not modal then return false end
    HideChoiceMenus183(modal)
    modal.target183 = ShortName183(member.name or target) modal.relatedCaseId183 = SafeWireText183(self, relatedCaseId or "", 24)
    modal.category183 = WARNING_CATEGORIES_183[1][1]
    SetEditText183(modal.reason, "") SetEditText183(modal.comment, "")
    UI:SetChecked(modal.announce, false) UI:SetChecked(modal.fallback, true)
    self:RefreshWarningEditor183()
    self:ShowShellModal(modal, true)
    return true
end

function OTLGM:BuildOfficerWarningDetail183()
    self.ui = self.ui or {}
    if self.ui.officerWarningDetail183 then return self.ui.officerWarningDetail183 end
    if not self.ui.modalHost then return nil end
    local modal = UI:Modal(self.ui.modalHost, 600, 410)
    modal:SetPoint("CENTER", self.ui.modalHost, "CENTER", 0, 0) modal.otlDiagnosticName180 = "Officer Warning Detail"
    modal.title = UI.Text(modal, "Official Warning Record", "GameFontNormalLarge", "LEFT")
    modal.title:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -18) modal.title:SetWidth(450) modal.title:SetTextColor(C.red[1], C.red[2], C.red[3])
    modal.close = UI:IconButton(modal, "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 28, 28, function() OTLGM:CloseModal180(modal, "officer-warning-close") end, "Close", "utility")
    modal.close:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -14, -13)
    modal.meta = UI.Text(modal, "", "GameFontNormalSmall", "LEFT")
    modal.meta:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -55) modal.meta:SetWidth(560) modal.meta:SetHeight(42) modal.meta:SetJustifyV("TOP")
    modal.meta:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.reasonCard = UI:Card(modal, 560, 92, "Official reason") modal.reasonCard:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -106)
    modal.reason = UI.Text(modal.reasonCard, "", "GameFontNormalSmall", "LEFT")
    modal.reason:SetPoint("TOPLEFT", modal.reasonCard, "TOPLEFT", 12, -31) modal.reason:SetWidth(536) modal.reason:SetHeight(50) modal.reason:SetJustifyV("TOP")
    modal.commentCard = UI:Card(modal, 560, 72, "Private officer comment") modal.commentCard:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -207)
    modal.comment = UI.Text(modal.commentCard, "", "GameFontNormalSmall", "LEFT")
    modal.comment:SetPoint("TOPLEFT", modal.commentCard, "TOPLEFT", 12, -31) modal.comment:SetWidth(536) modal.comment:SetHeight(32) modal.comment:SetJustifyV("TOP")
    modal.clearReason183 = WARNING_CLEAR_REASONS_183[1][1]
    modal.clearReason = UI:Button(modal, "", 210, 28, function()
        local nextReason = CycleDefinition183(WARNING_CLEAR_REASONS_183, modal.clearReason183)
        modal.clearReason183 = nextReason[1] OTLGM:RefreshOfficerWarningDetail183()
    end, "filter")
    modal.clearReason:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -292)
    modal.clear = UI:Button(modal, "Clear Warning", 120, 28, function()
        OTLGM:ShowConfirm("Clear Official Warning?", "The warning becomes inactive and remains in history. No guild rank action is performed.", "Clear", function()
            local ok, message = OTLGM:ClearWarning183(modal.otlWarningId183, modal.clearReason183)
            if ok then OTLGM:RefreshOfficerWarningDetail183()
            elseif OTLGM.ShowToast then OTLGM:ShowToast(tostring(message or "Warning could not be cleared."), "error") end
        end)
    end, "danger")
    modal.clear:SetPoint("LEFT", modal.clearReason, "RIGHT", 10, 0)
    modal.done = UI:Button(modal, "Close", 96, 30, function() OTLGM:CloseModal180(modal, "officer-warning-close") end, "secondary")
    modal.done:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -20, 16)
    self.ui.officerWarningDetail183 = modal
    return modal
end

function OTLGM:RefreshOfficerWarningDetail183()
    local modal = self.ui and self.ui.officerWarningDetail183
    local state = self:EnsureModeration183()
    local warning = modal and state and state.officerWarnings[modal.otlWarningId183 or ""] or nil
    if type(warning) ~= "table" or not self:IsOfficerMode() then return false end
    local active = ActiveWarningCount183(state.officerWarnings, warning.target)
    modal.meta:SetText("Target: " .. tostring(warning.target) .. "  •  " .. WarningCategoryLabel183(warning.category)
        .. "  •  " .. (warning.active and ("Active " .. tostring(active) .. "/2") or "Inactive")
        .. "\nIssued by " .. tostring(warning.issuer or "Leadership") .. "  •  " .. FormatModerationDate183(self, warning.issuedAt)
        .. "  •  " .. (warning.acknowledged and "Seen" or "Not acknowledged")
        .. (warning.relatedCaseId183 and warning.relatedCaseId183 ~= "" and ("  •  Related " .. tostring(warning.relatedCaseId183)) or ""))
    modal.reason:SetText(tostring(warning.reason or ""))
    modal.comment:SetText(warning.privateComment and warning.privateComment ~= "" and tostring(warning.privateComment) or "No private comment.")
    UI:SetText(modal.clearReason, "Clear as: " .. WarningClearLabel183(modal.clearReason183))
    SetShown183(modal.clearReason, warning.active) SetShown183(modal.clear, warning.active)
    return true
end

function OTLGM:OpenOfficerWarningDetail183(id)
    if not self:IsOfficerMode() then return false end
    local state = self:EnsureModeration183()
    local warning = state and state.officerWarnings[tostring(id or "")]
    if type(warning) ~= "table" or not self:CanCurrentClientAccessModerationRecord183("W", warning) then return false end
    local modal = self:BuildOfficerWarningDetail183()
    if not modal then return false end
    modal.otlWarningId183 = warning.id modal.clearReason183 = WARNING_CLEAR_REASONS_183[1][1]
    self:RefreshOfficerWarningDetail183()
    return self:ShowShellModal(modal)
end

function OTLGM:BuildEscalationDetail183()
    -- RC4: escalation is a canonical Officer Case, not a second moderation UI/data path.
    return self:BuildOfficerCaseDetail183()
end

function OTLGM:OpenEscalationDetail183(id)
    return self:OpenOfficerCaseDetail183(id)
end

function OTLGM:GetOwnModerationPendingCount183()
    local state, count, id, report = self:EnsureModeration183(), 0, nil, nil
    for id, report in pairs(state and state.ownReports or {}) do
        if type(report) == "table" and IsSelf183(self, report.author) and report.delivery ~= "SUBMITTED" then count = count + 1 end
    end
    return count
end

function OTLGM:AttachHomeModeration183(page)
    if not page or page.otlModeration183 then return end
    page.otlModeration183 = true
    self.ui.homeModeration183 = UI:Button(page, "Report / Help", 104, 28, function(button)
        OTLGM:OpenMemberModerationDrawer183(button.otlOpenMode183 or "REPORTS")
    end, "utility")
    self.ui.homeModeration183.otlTooltipTitle = "Private Reports & Warnings"
    self.ui.homeModeration183.otlTooltip = "Contact validated Leadership privately, review your own statuses, or acknowledge an official warning. Opening this does not request a sync."
end

function OTLGM:LayoutHomeModeration183()
    local button = self.ui and self.ui.homeModeration183
    local since = self.ui and self.ui.homeSinceVisit183
    local page = self.ui and self.ui.pages and self.ui.pages.home
    if not button then return end
    button:ClearAllPoints()
    -- Report / Help is the stable left edge of Home's utility row. Since Last
    -- Visit anchors to its right; this avoids circular/stale anchors after Fit.
    if page then button:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -40)
    else button:SetPoint("TOPLEFT", self.ui.contentHost, "TOPLEFT", 0, -40) end
    button:SetWidth(104) button:SetHeight(28)
    -- Also repair the neighbour here so layout order between optional feature
    -- modules cannot leave both controls on the same anchor for one frame.
    if since then
        since:ClearAllPoints()
        since:SetPoint("LEFT", button, "RIGHT", 8, 0)
        since:SetWidth(154) since:SetHeight(28)
    end
end

function OTLGM:RefreshHomeModeration183()
    local button = self.ui and self.ui.homeModeration183
    if not button then return false end
    local pending = self:GetOwnModerationPendingCount183()
    local warnings = self:GetActiveWarningCount183(PlayerName183(), false)
    if warnings > 0 then UI:SetText(button, "Warnings  •  " .. tostring(warnings)) button.otlOpenMode183 = "WARNINGS"
    elseif pending > 0 then UI:SetText(button, "Reports  •  " .. tostring(pending)) button.otlOpenMode183 = "REPORTS"
    else UI:SetText(button, "Report / Help") button.otlOpenMode183 = "REPORTS" end
    UI:SetSelected(button, warnings > 0 or pending > 0)
    return true
end

function OTLGM:AttachRosterModeration183(page)
    local details = self.ui and self.ui.rosterDetails
    if not details or details.moderation183 then return end
    details.moderation183 = UI:Button(details, "Officer Tools", 300, 25, function()
        if details.otlMember then OTLGM:OpenOfficerCases183(details.otlMember.name, "CASES") end
    end, "utility")
    details.moderation183.otlTooltipTitle = "Officer Tools"
    details.moderation183.otlTooltip = "Opens private cases and official warnings for the selected member. Existing rank and note controls are unchanged."
    details.moderation183:Hide()
end

function OTLGM:LayoutRosterModeration183()
    local details = self.ui and self.ui.rosterDetails
    local button = details and details.moderation183
    if not button then return end
    local width = math.max(210, (tonumber(details:GetWidth()) or 300) - 28)
    button:ClearAllPoints() button:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -462)
    button:SetWidth(width) button:SetHeight(25)
    if button.text then button.text:SetWidth(math.max(180, width - 10)) end
end

function OTLGM:RefreshRosterModeration183()
    local details = self.ui and self.ui.rosterDetails
    local button, member = details and details.moderation183, details and details.otlMember
    if not button then return false end
    local pendingText = details.pendingText and tostring(details.pendingText:GetText() or "") or ""
    local shown = member and self:IsOfficerMode() and not self.rosterActionPending180 and pendingText == ""
    if shown then
        local warnings = self:GetActiveWarningCount183(member.name, true)
        local cases = self:GetModerationCaseCountForMember183(member.name)
        UI:SetText(button, "Officer Tools  •  Warnings " .. tostring(math.min(2, warnings)) .. "/2  •  Cases " .. tostring(cases))
        button:Show()
        if details.pendingText then details.pendingText:Hide() end
    else button:Hide() end
    return shown and true or false
end

function OTLGM:AttachOverviewModeration183(page)
    if not page or page.otlModeration183 then return end
    page.otlModeration183 = true
    self.ui.overviewNeedsAttention183 = UI:Button(page, "Needs Attention  •  0", 166, 30,
        function() OTLGM:OpenOfficerCases183(nil, "ATTENTION") end, "utility")
    self.ui.overviewNeedsAttention183.otlTooltipTitle = "Needs Attention"
    self.ui.overviewNeedsAttention183.otlTooltip = "Only real moderation tasks: New reports, Waiting for Player, warning limits and escalations."
end

function OTLGM:LayoutOverviewModeration183(page, width, height)
    local button = self.ui and self.ui.overviewNeedsAttention183
    if not button then return end
    width, height = tonumber(width) or 720, tonumber(height) or 520
    local left = 392
    local available = math.max(132, (width - 166) - left - 10)
    button:ClearAllPoints() button:SetPoint("TOPLEFT", page, "TOPLEFT", left, -(height - 30))
    button:SetWidth(math.min(190, available)) button:SetHeight(30)
    if button.text then button.text:SetWidth(math.max(110, button:GetWidth() - 8)) end
end

function OTLGM:RefreshOverviewModeration183()
    local button = self.ui and self.ui.overviewNeedsAttention183
    if not button then return false end
    if not self:IsOfficerMode() then button:Hide() return false end
    local attention = self:GetNeedsAttention183()
    UI:SetText(button, "Needs Attention  •  " .. tostring(attention.total))
    UI:SetSelected(button, attention.total > 0)
    button:Show()
    return true
end

local function WrapModerationPage183(key, attach, layout, refresh)
    local module = OTLGM.shellPageModules and OTLGM.shellPageModules[key]
    if not module or module.otlModerationWrapped183 then return end
    module.otlModerationWrapped183 = true
    local PreviousBuild, PreviousLayout, PreviousRefresh = module.Build, module.Layout, module.Refresh
    function module:Build(contentHost)
        local root = PreviousBuild(self, contentHost)
        if attach then attach(self.owner, root) end
        return root
    end
    function module:Layout(width, height)
        PreviousLayout(self, width, height)
        if layout then layout(self.owner, self.root, width, height) end
    end
    function module:Refresh(reason)
        PreviousRefresh(self, reason)
        if refresh then refresh(self.owner, self.root, reason) end
    end
end

WrapModerationPage183("home",
    function(owner, page) owner:AttachHomeModeration183(page) end,
    function(owner) owner:LayoutHomeModeration183() end,
    function(owner) owner:RefreshHomeModeration183() end)

WrapModerationPage183("roster",
    function(owner, page) owner:AttachRosterModeration183(page) end,
    function(owner) owner:LayoutRosterModeration183() end,
    function(owner) owner:RefreshRosterModeration183() end)

WrapModerationPage183("overview",
    function(owner, page) owner:AttachOverviewModeration183(page) end,
    function(owner, page, width, height) owner:LayoutOverviewModeration183(page, width, height) end,
    function(owner) owner:RefreshOverviewModeration183() end)

function OTLGM:RefreshModerationViews183(reason)
    local ui = self.ui or {}
    if ui.homeModeration183 then self:RefreshHomeModeration183() end
    if ui.rosterDetails and ui.rosterDetails.moderation183 then self:RefreshRosterModeration183() end
    if ui.overviewNeedsAttention183 then self:RefreshOverviewModeration183() end
    if ui.memberModerationDrawer183 and ui.memberModerationDrawer183:IsVisible() then self:RefreshMemberModerationDrawer183() end
    if ui.officerCasesDrawer183 and ui.officerCasesDrawer183:IsVisible() then self:RefreshOfficerCasesDrawer183() end
    if ui.officerCasesPageR25 and ui.currentPage == "cases" and self.RefreshOfficerCasesPageR25 then self:RefreshOfficerCasesPageR25(reason or "moderation") end
    if ui.ownReportDetail183 and ui.ownReportDetail183:IsVisible() then self:RefreshOwnReportDetail183() end
    if ui.ownWarningDetail183 and ui.ownWarningDetail183:IsVisible() then self:RefreshOwnWarningDetail183() end
    if ui.officerCaseDetail183 and ui.officerCaseDetail183:IsVisible() then self:RefreshOfficerCaseDetail183(true) end
    if ui.officerWarningDetail183 and ui.officerWarningDetail183:IsVisible() then self:RefreshOfficerWarningDetail183() end
    self.runtime = self.runtime or {} self.runtime.moderationLastRefreshReason183 = tostring(reason or "refresh")
    return true
end

local PreviousRememberAddonUserModeration183 = OTLGM.RememberAddonUser
function OTLGM:RememberAddonUser(sender, version, build, faction)
    if PreviousRememberAddonUserModeration183 then PreviousRememberAddonUserModeration183(self, sender, version, build, faction) end
    if not sender or sender == "" or IsSelf183(self, sender) then return end
    local effectiveVersion = version
    if not effectiveVersion or effectiveVersion == "" or effectiveVersion == "Detected" then
        effectiveVersion = self.GetDetectedAddonVersion183 and self:GetDetectedAddonVersion183(sender) or nil
    end
    if effectiveVersion then self:RetryModerationForPresence183(sender, effectiveVersion) end
end

local PreviousOpenGuildObjectModeration183 = OTLGM.OpenGuildObject180
function OTLGM:OpenGuildObject180(objectType, objectId, options)
    local normalized = string.upper(tostring(objectType or ""))
    normalized = string.gsub(normalized, "[%s%-]+", "_")
    if normalized == "MOD_REPORT" then
        local state = self:EnsureModeration183()
        local own = state and state.ownReports[tostring(objectId or "")]
        if type(own) == "table" and IsSelf183(self, own.author) then return self:OpenOwnReportDetail183(objectId) end
        local officerCase = state and state.officerCases[tostring(objectId or "")]
        if type(officerCase) == "table" and self:CanCurrentClientAccessModerationRecord183("C", officerCase) then
            self.ui = self.ui or {}
            self.ui.officerCaseSelectedR25 = tostring(objectId or "")
            if not self.ui.main then self:BuildUI() end
            self:ShowPage("cases")
            if self.RefreshOfficerCasesPageR25 then self:RefreshOfficerCasesPageR25("object-route") end
            return true
        end
        return false
    end
    if normalized == "MOD_WARNING" then
        local state = self:EnsureModeration183()
        local own = state and state.ownWarnings[tostring(objectId or "")]
        if type(own) == "table" and IsSelf183(self, own.target) then return self:OpenOwnWarningDetail183(objectId) end
        local officerWarning = state and state.officerWarnings[tostring(objectId or "")]
        if type(officerWarning) == "table" and self:CanCurrentClientAccessModerationRecord183("W", officerWarning) then return self:OpenOfficerWarningDetail183(objectId) end
        return false
    end
    return PreviousOpenGuildObjectModeration183 and PreviousOpenGuildObjectModeration183(self, objectType, objectId, options) or false
end

local function ModerationInboxVisibility183(owner, entry)
    if type(entry) ~= "table" then return false, false end
    local objectType = string.upper(tostring(entry.objectType or ""))
    if objectType ~= "MOD_REPORT" and objectType ~= "MOD_WARNING" then return true, true end
    local state = owner:EnsureModeration183()
    local id = tostring(entry.objectId or "")
    if id == "" then return false, false end
    if objectType == "MOD_REPORT" then
        local own = state and state.ownReports[id]
        if type(own) == "table" and IsSelf183(owner, own.author) then return true, true end
        local officerCase = state and state.officerCases[id]
        if type(officerCase) == "table" then
            return owner:CanCurrentClientAccessModerationRecord183("C", officerCase) and true or false, true
        end
        return false, false
    end
    local ownWarning = state and state.ownWarnings[id]
    if type(ownWarning) == "table" and IsSelf183(owner, ownWarning.target) then return true, true end
    local officerWarning = state and state.officerWarnings[id]
    if type(officerWarning) == "table" then
        return owner:CanCurrentClientAccessModerationRecord183("W", officerWarning) and true or false, true
    end
    return false, false
end

function OTLGM:IsModerationInboxEntryVisible183(entry)
    local visible = ModerationInboxVisibility183(self, entry)
    return visible and true or false
end

local PreviousQuickDockRelevantModeration183 = OTLGM.IsQuickDockNotificationRelevant183
if PreviousQuickDockRelevantModeration183 then
    function OTLGM:IsQuickDockNotificationRelevant183(entry)
        local objectType = string.upper(tostring(entry and entry.objectType or ""))
        if (objectType == "MOD_REPORT" or objectType == "MOD_WARNING")
            and not self:IsModerationInboxEntryVisible183(entry) then return false end
        return PreviousQuickDockRelevantModeration183(self, entry)
    end
end

local PreviousInboxActionableModeration183 = OTLGM.IsInboxEntryActionable180
function OTLGM:IsInboxEntryActionable180(entry)
    local objectType = string.upper(tostring(entry and entry.objectType or ""))
    if objectType == "MOD_REPORT" or objectType == "MOD_WARNING" then
        local visible, exists = ModerationInboxVisibility183(self, entry)
        return exists and visible and true or false
    end
    return PreviousInboxActionableModeration183 and PreviousInboxActionableModeration183(self, entry) or false
end

local PreviousInboxStaleModeration183 = OTLGM.IsInboxEntryStale180
function OTLGM:IsInboxEntryStale180(entry)
    local objectType = string.upper(tostring(entry and entry.objectType or ""))
    if objectType == "MOD_REPORT" or objectType == "MOD_WARNING" then
        local visible, exists = ModerationInboxVisibility183(self, entry)
        if not exists then return true end
        -- OTLGM_DB is shared across account characters. A Guild-Leader-only
        -- notification that is hidden on an Officer alt is not stale and must
        -- remain stored for the Guild Leader character. Visibility is filtered
        -- at read/count/action boundaries instead of destructive pruning.
        if not visible then return false end
        return not self:IsInboxEntryActionable180(entry)
    end
    return PreviousInboxStaleModeration183 and PreviousInboxStaleModeration183(self, entry) or false
end

local function RecountSharedInbox183(db)
    if not db then return end
    db.notificationUnread = type(db.notificationUnread) == "table" and db.notificationUnread or {}
    local category
    for category in pairs(db.notificationUnread) do db.notificationUnread[category] = 0 end
    local index, entry
    for index = 1, table.getn(db.inbox170 or {}) do
        entry = db.inbox170[index]
        if type(entry) == "table" and not entry.read then
            category = type(entry.category) == "string" and entry.category ~= "" and entry.category or "background"
            db.notificationUnread[category] = (tonumber(db.notificationUnread[category]) or 0) + 1
        end
    end
end

local function RefreshInboxAfterModerationVisibility183(owner)
    if owner.RefreshNavigation then owner:RefreshNavigation() end
    if owner.UpdateMinimapBadge then owner:UpdateMinimapBadge() end
    if owner.MarkQuickDockDirty182 then owner:MarkQuickDockDirty182("notifications") end
    if owner.RefreshInbox170 and owner.ui and owner.ui.inbox170 and owner.ui.inbox170:IsVisible() then owner:RefreshInbox170() end
end

local PreviousGetInboxEntriesModeration183 = OTLGM.GetInboxEntries170
function OTLGM:GetInboxEntries170(mode)
    local raw = PreviousGetInboxEntriesModeration183 and PreviousGetInboxEntriesModeration183(self, mode) or {}
    local result, index, entry = {}, 1, nil
    for index = 1, table.getn(raw) do
        entry = raw[index]
        if type(entry) == "table" and self:IsModerationInboxEntryVisible183(entry) then table.insert(result, entry) end
    end
    return result
end

local PreviousGetInboxUnreadCountModeration183 = OTLGM.GetInboxUnreadCount170
function OTLGM:GetInboxUnreadCount170(category)
    local db = self:GetGuildDB()
    local count, index, entry = 0, 1, nil
    for index = 1, table.getn(db and db.inbox170 or {}) do
        entry = db.inbox170[index]
        if type(entry) == "table" and not entry.read and (not category or entry.category == category)
            and self:IsModerationInboxEntryVisible183(entry) then count = count + 1 end
    end
    return count
end

local PreviousGetNotificationUnreadModeration183 = OTLGM.GetNotificationUnread152
function OTLGM:GetNotificationUnread152(category)
    return self:GetInboxUnreadCount170(category)
end

local PreviousMarkInboxReadModeration183 = OTLGM.MarkInboxRead170
function OTLGM:MarkInboxRead170(id)
    local db = self:GetGuildDB()
    local index, entry
    for index = 1, table.getn(db and db.inbox170 or {}) do
        entry = db.inbox170[index]
        if type(entry) == "table" and entry.id == id then
            if not self:IsModerationInboxEntryVisible183(entry) then return false end
            break
        end
    end
    return PreviousMarkInboxReadModeration183 and PreviousMarkInboxReadModeration183(self, id) or false
end

local function MarkVisibleInboxEntries183(owner, matcher)
    local db = owner:GetGuildDB()
    local changed, index, entry = false, 1, nil
    for index = 1, table.getn(db and db.inbox170 or {}) do
        entry = db.inbox170[index]
        if type(entry) == "table" and not entry.read and owner:IsModerationInboxEntryVisible183(entry) and matcher(entry) then
            entry.read = true
            changed = true
        end
    end
    if changed then
        RecountSharedInbox183(db)
        RefreshInboxAfterModerationVisibility183(owner)
    end
    return changed
end

local PreviousMarkInboxCategoryReadModeration183 = OTLGM.MarkInboxCategoryRead170
function OTLGM:MarkInboxCategoryRead170(category)
    return MarkVisibleInboxEntries183(self, function(entry) return not category or entry.category == category end)
end

local PreviousMarkInboxPageReadModeration183 = OTLGM.MarkInboxPageRead170
function OTLGM:MarkInboxPageRead170(targetPage)
    targetPage = tostring(targetPage or "")
    if targetPage == "" then return false end
    return MarkVisibleInboxEntries183(self, function(entry) return entry.targetPage == targetPage end)
end

local PreviousMarkInboxMatchingModeration183 = OTLGM.MarkInboxMatching170
function OTLGM:MarkInboxMatching170(prefix)
    prefix = tostring(prefix or "")
    if prefix == "" then return false end
    return MarkVisibleInboxEntries183(self, function(entry)
        return string.sub(tostring(entry.id or ""), 1, string.len(prefix)) == prefix
    end)
end

local PreviousPruneInboxActionsModeration183 = OTLGM.PruneInboxActions180
function OTLGM:PruneInboxActions180()
    local db = self:GetGuildDB()
    local changed, index, entry = false, nil, nil
    for index = table.getn(db and db.inbox170 or {}), 1, -1 do
        entry = db.inbox170[index]
        if type(entry) ~= "table" then
            table.remove(db.inbox170, index)
            changed = true
        else
            local objectType = string.upper(tostring(entry.objectType or ""))
            if objectType == "MOD_REPORT" or objectType == "MOD_WARNING" then
                local visible, exists = ModerationInboxVisibility183(self, entry)
                if not exists or (visible and self:IsInboxEntryStale180(entry)) then
                    table.remove(db.inbox170, index)
                    changed = true
                end
                -- Existing-but-hidden moderation entries are intentionally kept:
                -- the shared SavedVariables may belong to another character.
            elseif entry.objectType and self:IsInboxEntryStale180(entry) then
                table.remove(db.inbox170, index)
                changed = true
            end
        end
    end
    if changed then
        RecountSharedInbox183(db)
        RefreshInboxAfterModerationVisibility183(self)
    end
    return changed
end


-- r25 Officer Cases page ---------------------------------------------------
-- The moderation backend above already owns privacy, authority, reconciliation,
-- warnings and canonical timelines. This page is presentation/workflow only;
-- it never duplicates or broadcasts private case state.
local OFFICER_CASE_FILTERS_R25 = {
    { "OPEN", "Open" }, { "ASSIGNED", "Assigned" }, { "WAITING", "Waiting" },
    { "RESOLVED", "Resolved" }, { "CLOSED", "Closed" }, { "ALL", "All" },
}
-- Keep the canonical backend status keys for mixed-version compatibility, but
-- present the smaller working vocabulary specified for the new cases page.
local OFFICER_CASE_STATUSES_R25 = {
    { "NEW", "New" }, { "SEEN", "Seen" }, { "REVIEW", "Assigned" },
    { "WAITING", "Waiting for Player" }, { "HOLD", "Waiting for Officer" },
    { "RESOLVED", "Resolved" }, { "ARCHIVED", "Closed" },
}
local OFFICER_RESOLUTION_PRESETS_R25 = {
    { "", "No preset" },
    { "Reviewed — no further action", "No further action" },
    { "Player contacted", "Player contacted" },
    { "Warning issued", "Warning issued" },
    { "Resolved with guidance", "Guidance given" },
    { "Insufficient information", "Insufficient information" },
    { "Duplicate report", "Duplicate report" },
}

local function OfficerCaseFilterMatchR25(record, filterKey)
    filterKey = tostring(filterKey or "OPEN")
    local status = tostring(record and record.status or "NEW")
    local terminal = TERMINAL_REPORT_STATUSES_183[status] and true or false
    if filterKey == "OPEN" then return not terminal end
    if filterKey == "ASSIGNED" then return not terminal and tostring(record.assignedTo183 or "") ~= "" end
    if filterKey == "WAITING" then return not terminal and (status == "WAITING" or status == "HOLD") end
    if filterKey == "RESOLVED" then return status == "RESOLVED" end
    if filterKey == "CLOSED" then return terminal and status ~= "RESOLVED" end
    return true
end

local function OfficerCaseListR25(owner, filterKey)
    local source = owner:GetOfficerCases183(nil, nil)
    local result, index, record = {}, nil, nil
    for index = 1, table.getn(source) do
        record = source[index]
        if OfficerCaseFilterMatchR25(record, filterKey) then table.insert(result, record) end
    end
    return result
end

local function CaseSemanticColorR25(status)
    status = tostring(status or "NEW")
    if status == "NEW" then return C.red end
    if status == "WAITING" or status == "HOLD" then return C.orange end
    if status == "RESOLVED" then return C.green end
    if TERMINAL_REPORT_STATUSES_183[status] then return C.grey end
    return C.blue
end

local function ParsedCaseDiagnosticsR25(text)
    local result, part, key, value = {}, nil, nil, nil
    if not string.gfind then return result end
    for part in string.gfind(tostring(text or ""), "([^;]+)") do
        local _, _, capturedKey, capturedValue = string.find(part, "^%s*([^=]+)=(.*)$")
        key, value = capturedKey, capturedValue
        if key then
            key = string.lower(tostring(key or ""))
            result[key] = tostring(value or "")
        end
    end
    return result
end

local function BuildCaseTroubleshootingTextR25(owner, record)
    local parsed = ParsedCaseDiagnosticsR25(record and record.diagnostics or "")
    local lines = {
        "Version / build: " .. Short183(tostring(parsed.v or owner.version or "unknown"), 32) .. " / " .. Short183(tostring(parsed.b or owner.build or "unknown"), 42),
        "Zone: " .. Short183(tostring(parsed.zone or parsed.z or "not captured"), 26) .. "  •  Subzone: " .. Short183(tostring(parsed.subzone or parsed.sz or "n/a"), 22) .. "  •  Instance: " .. Short183(tostring(parsed.instance or parsed.inst or "n/a"), 22),
        "FPS/latency: " .. Short183(tostring(parsed.fps or "n/a"), 8) .. "/" .. Short183(tostring(parsed.latency or parsed.lat or "n/a"), 12) .. "  •  Page: " .. Short183(tostring(parsed.page or "unknown"), 18) .. "  •  Roster: " .. Short183(tostring(parsed.roster or parsed.rost or "n/a"), 24),
        "Network C/N/B: " .. Short183(tostring(parsed.net or "n/a"), 20) .. "  •  Scheduler: " .. Short183(tostring(parsed.scheduler or parsed.sched or parsed.guard or "n/a"), 34),
        "Craft/Search/Enchant: " .. Short183(tostring(parsed.craft or "n/a"), 16) .. "/" .. Short183(tostring(parsed.search or "n/a"), 16) .. "/" .. Short183(tostring(parsed.enchant or parsed.ench or "n/a"), 16) .. "  •  Slow: " .. Short183(tostring(parsed.spike or "none"), 24) .. "  •  Error: " .. Short183(tostring(parsed.error or "none"), 24),
    }
    return table.concat(lines, "\n")
end

local function CaseDisplayTextR30(value)
    value = tostring(value or "")
    local output, line, token = {}, "", ""
    if not string.gfind then return value end
    for token in string.gfind(value, "[^%s]+") do
        while string.len(token) > 76 do
            local part = string.sub(token, 1, 76) token = string.sub(token, 77)
            if line ~= "" then table.insert(output, line) line = "" end
            table.insert(output, part)
        end
        if token ~= "" then
            if line == "" then line = token
            elseif string.len(line) + 1 + string.len(token) <= 76 then line = line .. " " .. token
            else table.insert(output, line) line = token end
        end
    end
    if line ~= "" then table.insert(output, line) end
    if table.getn(output) == 0 then return value end
    return table.concat(output, "\n")
end

local function BuildCaseHistoryTextR25(owner, record)
    if type(record) ~= "table" then return "No case selected." end
    local lines = {
        "Case " .. tostring(record.id or "") .. "  •  " .. tostring(record.author or "Unknown")
            .. (record.target and record.target ~= "" and (" -> " .. tostring(record.target)) or ""),
        "Created: " .. FormatModerationDate183(owner, record.createdAt) .. "  •  Current: " .. ReportStatusLabel183(record.status or "NEW"),
        "",
    }
    local timeline = EnsureTimeline183(record)
    local index, entry
    for index = 1, table.getn(timeline) do
        entry = timeline[index]
        if type(entry) == "table" and tostring(entry.kind or "") ~= "RECONCILED" then
            table.insert(lines, FormatModerationDate183(owner, entry.ts) .. "  •  " .. tostring(entry.kind or "UPDATE")
                .. "  •  " .. tostring(entry.actor or "Leadership") .. "  —  " .. tostring(entry.text or ""))
        end
    end
    if table.getn(lines) == 3 then table.insert(lines, "No timeline entries recorded.") end
    return table.concat(lines, "\n")
end

local function BuildOfficerCasesPageR25(owner, page)
    owner.ui = owner.ui or {}
    local ui = { filterKey = owner.ui.officerCasesFilterR25 or "OPEN", offset = 0, selectedId = owner.ui.officerCaseSelectedR25 }
    owner.ui.officerCasesPageR25 = ui
    if UI.HelpIcon then
        ui.helpR32 = UI:ContextHelpIcon(page, "OFFICER_CASES")
        ui.helpR32:SetPoint("TOPRIGHT", page, "TOPRIGHT", -8, -6)
    end

    ui.filters = {}
    local index, definition
    for index = 1, table.getn(OFFICER_CASE_FILTERS_R25) do
        definition = OFFICER_CASE_FILTERS_R25[index]
        local button = UI:Tab(page, definition[2], 92, function(control)
            local target = control and control.otlCaseFilterR25 or "OPEN"
            ui.filterKey, ui.offset = target, 0
            owner.ui.officerCasesFilterR25 = target
            owner:RefreshOfficerCasesPageR25("filter")
        end)
        button.otlCaseFilterR25 = definition[1]
        ui.filters[index] = button
    end
    ui.count = UI.Text(page, "", "GameFontNormalSmall", "RIGHT")
    ui.count:SetTextColor(C.grey[1], C.grey[2], C.grey[3])

    ui.queue = UI:Card(page, 330, 470, "Case Queue")
    ui.rows = {}
    for index = 1, 8 do
        local row = UI:TableRow(ui.queue, 300, 58, function(control)
            if not control or not control.otlCaseIdR25 then return end
            ui.selectedId = control.otlCaseIdR25
            owner.ui.officerCaseSelectedR25 = ui.selectedId
            if page.otlCasesNarrowR25 and owner.OpenOfficerCaseDetail183 then
                owner:OpenOfficerCaseDetail183(ui.selectedId)
            else
                local selected = owner:GetOfficerCaseByIdR25(ui.selectedId)
                if selected and selected.status == "NEW" and owner.MarkOfficerCaseSeen183 then owner:MarkOfficerCaseSeen183(selected) end
                owner:RefreshOfficerCasesPageR25("select")
            end
        end)
        row.otlStyle = "filter"
        row.statusDotR25 = row:CreateTexture(nil, "ARTWORK")
        row.statusDotR25:SetTexture(0.45, 0.45, 0.45, 0.9)
        row.statusDotR25:SetWidth(5) row.statusDotR25:SetHeight(42)
        row.statusDotR25:SetPoint("LEFT", row, "LEFT", 5, 0)
        row.title = UI.Text(row, "", "GameFontNormal", "LEFT")
        row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 14, -6)
        row.status = UI.Text(row, "", "GameFontNormalSmall", "RIGHT")
        row.status:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -7)
        row.status:SetWidth(92)
        row.meta = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.meta:SetPoint("TOPLEFT", row, "TOPLEFT", 14, -25)
        row.meta:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        row.summary = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.summary:SetPoint("TOPLEFT", row, "TOPLEFT", 14, -41)
        row.summary:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
        row:Hide()
        ui.rows[index] = row
    end
    ui.scrollbar = UI:Scrollbar(ui.queue, 360, function(value)
        if ui.scrollSilent then return end
        ui.offset = math.floor((tonumber(value) or 0) + 0.5)
        owner:RefreshOfficerCasesPageR25("scroll")
    end)
    ui.empty = UI:EmptyState(ui.queue, 280, 110, "No cases in this view", "Change the filter to review other case history.")
    ui.empty:Hide()

    ui.detail = UI:Card(page, 560, 470, "Selected Case")
    ui.detailEmpty = UI:EmptyState(ui.detail, 360, 118, "No case selected", "Choose a case from the current filter, or switch filters to review case history.")
    ui.detailEmpty:Hide()
    ui.detailTitle = UI.Text(ui.detail, "Select a case", "GameFontNormalLarge", "LEFT")
    ui.detailTitle:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    ui.detailMeta = UI.Text(ui.detail, "", "GameFontNormalSmall", "LEFT")
    ui.detailMeta:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    ui.detailSummary = UI.Text(ui.detail, "", "GameFontNormalSmall", "LEFT")
    ui.detailSummary:SetHeight(36)
    ui.detailSummary:SetJustifyV("TOP")

    ui.assign = UI:Button(ui.detail, "Take Case", 104, 26, function()
        local record = owner:GetOfficerCaseByIdR25(ui.selectedId)
        if not record then return end
        local player = PlayerName183()
        local current = ShortName183(record.assignedTo183 or "")
        if current ~= "" and Normalize183(owner, current) ~= Normalize183(owner, player) then
            local caseId = record.id
            if owner.ShowConfirm then
                owner:ShowConfirm("Take Over Case?", "This case is currently assigned to " .. current .. ". Take responsibility for it?", "Take Over", function()
                    local ok, message = owner:AssignOfficerCase183(caseId, player)
                    if not ok and owner.ShowToast then owner:ShowToast(tostring(message or "Could not take over case."), "error") end
                    owner:RefreshOfficerCasesPageR25("assign-takeover")
                end)
            end
            return
        end
        local assignee = Normalize183(owner, current) == Normalize183(owner, player) and "" or player
        local ok, message = owner:AssignOfficerCase183(record.id, assignee)
        if not ok and owner.ShowToast then owner:ShowToast(tostring(message or "Assignment could not be changed."), "error") end
        owner:RefreshOfficerCasesPageR25("assign")
    end, "secondary")
    ui.status = UI:Button(ui.detail, "Status", 164, 26, function()
        local record = owner:GetOfficerCaseByIdR25(ui.selectedId)
        if not record then return end
        if ui.resolutionMenu then ui.resolutionMenu:Hide() end
        ToggleChoiceMenu183(page, ui.statusMenu, OFFICER_CASE_STATUSES_R25, ui.pendingStatusR25 or record.status or "NEW", function(key)
            ui.pendingStatusR25 = key
            UI:SetText(ui.status, "Status: " .. ReportStatusLabel183(key))
        end)
    end, "filter")
    ui.statusMenu = BuildChoiceMenu183(page, 214, table.getn(OFFICER_CASE_STATUSES_R25))

    ui.resolution = UI:Button(ui.detail, "Resolution", 164, 26, function()
        if ui.statusMenu then ui.statusMenu:Hide() end
        ToggleChoiceMenu183(page, ui.resolutionMenu, OFFICER_RESOLUTION_PRESETS_R25, ui.pendingResolutionR25 or "", function(key)
            ui.pendingResolutionR25 = key
            local label = DefinitionLabel183(OFFICER_RESOLUTION_PRESETS_R25, key, "No preset")
            UI:SetText(ui.resolution, "Reason: " .. Short183(label, 20))
            if key ~= "" then SetEditText183(ui.reason, key) end
        end)
    end, "filter")
    ui.resolutionMenu = BuildChoiceMenu183(page, 220, table.getn(OFFICER_RESOLUTION_PRESETS_R25))
    ui.reason = UI:EditBox(ui.detail, 300, 26, { maxLetters = MAX_STATUS_REASON_183, placeholder = "Status / resolution reason" })
    ui.response = UI:EditBox(ui.detail, 500, 42, { multiline = true, maxLetters = MAX_RESPONSE_183, placeholder = "Optional player-facing response; required when waiting for the player..." })
    ui.comment = UI:EditBox(ui.detail, 500, 38, { multiline = true, maxLetters = MAX_PRIVATE_COMMENT_183, placeholder = "Private officer context; never sent to ordinary guild members..." })
    ui.save = UI:Button(ui.detail, "Save Update", 112, 28, function()
        local record = owner:GetOfficerCaseByIdR25(ui.selectedId)
        if not record then return end
        local ok, message = owner:UpdateOfficerCase183(record.id, ui.pendingStatusR25 or record.status or "NEW",
            ui.response:GetText() or "", ui.comment:GetText() or "", ui.reason:GetText() or "")
        if not ok and owner.ShowToast then owner:ShowToast(tostring(message or "Case update failed."), "error") end
        owner:RefreshOfficerCasesPageR25("save")
    end, "primary")
    ui.warning = UI:Button(ui.detail, "Issue Warning", 112, 28, function()
        local record = owner:GetOfficerCaseByIdR25(ui.selectedId)
        if record and record.target and record.target ~= "" then owner:OpenWarningEditor183(record.target, record.id) end
    end, "danger")

    ui.timelineTitle = UI.Text(ui.detail, "Case History", "GameFontNormal", "LEFT")
    ui.timeline = {}
    for index = 1, 3 do
        ui.timeline[index] = UI.Text(ui.detail, "", "GameFontNormalSmall", "LEFT")
        ui.timeline[index]:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    end

    ui.troubleTitle = UI.Text(ui.detail, "Troubleshooting", "GameFontNormal", "LEFT")
    ui.trouble = UI.Text(ui.detail, "", "GameFontNormalSmall", "LEFT")
    ui.trouble:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    ui.copyTrouble = UI:Button(ui.detail, "Report Issue", 116, 24, function()
        if owner.OpenSupportCenterR59 then owner:OpenSupportCenterR59(false)
        else
            if owner.ShowPage then owner:ShowPage("settings") end
            if owner.SetSettingsShellTab then owner:SetSettingsShellTab("SUPPORT") end
        end
    end, "danger")
    ui.copyTrouble.otlTooltipTitle = "Central diagnostics"
    ui.copyTrouble.otlTooltip = "Quick and Full technical reports are centralized in Settings > Support & Report. Case text and private officer notes are intentionally excluded from technical reports."
    ui.fullHistory = UI:Button(ui.detail, "Full History", 92, 22, function()
        local record = owner:GetOfficerCaseByIdR25(ui.selectedId)
        if not record then return end
        local text = BuildCaseHistoryTextR25(owner, record)
        if owner.ShowCopyDialog then owner:ShowCopyDialog("Case History", text)
        elseif owner.ShowTextModal then owner:ShowTextModal("Case History", text) end
    end, "utility")
end

function OTLGM:GetOfficerCaseByIdR25(id)
    if not id or not self:IsOfficerMode() then return nil end
    local state = self:EnsureModeration183()
    local record = state and state.officerCases and state.officerCases[tostring(id)] or nil
    if type(record) ~= "table" or not self:CanCurrentClientAccessModerationRecord183("C", record) then return nil end
    if tostring(record.caseKind183 or "REPORT") == "REPORT" and IsSelf183(self, record.author) then return nil end
    return record
end

function OTLGM:GetOfficerCaseHomePreviewR28(id)
    local record = self:GetOfficerCaseByIdR25(id)
    if not record then return nil end
    local category = ReportCategoryLabel183(record.reportType, record.category)
    local reportType = ReportTypeLabel183(record.reportType)
    local target = ShortName183(record.target or "")
    local created = tonumber(record.createdAt) or self:Now()
    local parts = { reportType, category }
    if target ~= "" then table.insert(parts, "Target: " .. target) end
    table.insert(parts, date("%H:%M", created))
    return Short183(table.concat(parts, " • "), 112)
end

local function LayoutOfficerCasesPageR25(owner, page, width, height)
    local ui = owner.ui and owner.ui.officerCasesPageR25
    if not ui then return end
    local margin, filterGap = 8, 6
    local filterWidth = math.max(64, math.min(92, math.floor((width - 180 - (filterGap * 5)) / 6)))
    local index
    for index = 1, table.getn(ui.filters) do
        ui.filters[index]:ClearAllPoints()
        ui.filters[index]:SetPoint("TOPLEFT", page, "TOPLEFT", margin + ((index - 1) * (filterWidth + filterGap)), -2)
        ui.filters[index]:SetWidth(filterWidth)
    end
    ui.count:ClearAllPoints(); ui.count:SetPoint("TOPRIGHT", page, "TOPRIGHT", -8, -9); ui.count:SetWidth(140)

    local top, bodyHeight = 36, math.max(260, height - 42)
    local wide = width >= 860
    page.otlCasesNarrowR25 = not wide
    if not wide then
        ui.queue:ClearAllPoints(); ui.queue:SetPoint("TOPLEFT", page, "TOPLEFT", margin, -top)
        ui.queue:SetWidth(width - (margin * 2)); ui.queue:SetHeight(bodyHeight)
        ui.detail:Hide()
    else
        local queueWidth = math.max(310, math.min(380, math.floor(width * 0.37)))
        ui.queue:ClearAllPoints(); ui.queue:SetPoint("TOPLEFT", page, "TOPLEFT", margin, -top)
        ui.queue:SetWidth(queueWidth); ui.queue:SetHeight(bodyHeight)
        ui.detail:ClearAllPoints(); ui.detail:SetPoint("TOPLEFT", ui.queue, "TOPRIGHT", 10, 0)
        ui.detail:SetWidth(math.max(420, width - queueWidth - 26)); ui.detail:SetHeight(bodyHeight); ui.detail:Show()
    end

    local queueWidth = ui.queue:GetWidth()
    local capacity = math.max(3, math.min(8, math.floor((bodyHeight - 58) / 62)))
    ui.visibleRowsR25 = capacity
    for index = 1, table.getn(ui.rows) do
        local row = ui.rows[index]
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", ui.queue, "TOPLEFT", 10, -34 - ((index - 1) * 62))
        row:SetWidth(math.max(220, queueWidth - 32)); row:SetHeight(58)
        row.title:SetWidth(math.max(110, queueWidth - 150))
        row.meta:SetWidth(math.max(160, queueWidth - 52))
        row.summary:SetWidth(math.max(160, queueWidth - 52))
        if index > capacity then row:Hide() end
    end
    ui.scrollbar:ClearAllPoints(); ui.scrollbar:SetPoint("TOPRIGHT", ui.queue, "TOPRIGHT", -6, -34)
    ui.scrollbar:SetHeight(math.max(80, bodyHeight - 50))
    ui.empty:ClearAllPoints(); ui.empty:SetPoint("CENTER", ui.queue, "CENTER", 0, -10)

    if wide then
        local detailWidth = ui.detail:GetWidth()
        ui.detailEmpty:ClearAllPoints(); ui.detailEmpty:SetPoint("CENTER", ui.detail, "CENTER", 0, -6)
        ui.detailEmpty:SetWidth(math.max(280, math.min(420, detailWidth - 56)))
        ui.detailTitle:ClearAllPoints(); ui.detailTitle:SetPoint("TOPLEFT", ui.detail, "TOPLEFT", 14, -32); ui.detailTitle:SetWidth(detailWidth - 28)
        ui.detailMeta:ClearAllPoints(); ui.detailMeta:SetPoint("TOPLEFT", ui.detail, "TOPLEFT", 14, -57); ui.detailMeta:SetWidth(detailWidth - 28)
        ui.detailSummary:ClearAllPoints(); ui.detailSummary:SetPoint("TOPLEFT", ui.detail, "TOPLEFT", 14, -77); ui.detailSummary:SetWidth(detailWidth - 28)
        ui.assign:ClearAllPoints(); ui.assign:SetPoint("TOPLEFT", ui.detail, "TOPLEFT", 14, -120)
        ui.status:ClearAllPoints(); ui.status:SetPoint("LEFT", ui.assign, "RIGHT", 8, 0)
        ui.resolution:ClearAllPoints(); ui.resolution:SetPoint("TOPLEFT", ui.detail, "TOPLEFT", 14, -152)
        ui.reason:ClearAllPoints(); ui.reason:SetPoint("LEFT", ui.resolution, "RIGHT", 8, 0); ui.reason:SetWidth(math.max(150, detailWidth - 206))
        ui.response:ClearAllPoints(); ui.response:SetPoint("TOPLEFT", ui.detail, "TOPLEFT", 14, -184); ui.response:SetWidth(detailWidth - 28)
        ui.comment:ClearAllPoints(); ui.comment:SetPoint("TOPLEFT", ui.detail, "TOPLEFT", 14, -231); ui.comment:SetWidth(detailWidth - 28)
        ui.save:ClearAllPoints(); ui.save:SetPoint("TOPLEFT", ui.detail, "TOPLEFT", 14, -274)
        ui.warning:ClearAllPoints(); ui.warning:SetPoint("LEFT", ui.save, "RIGHT", 10, 0)
        ui.timelineTitle:ClearAllPoints(); ui.timelineTitle:SetPoint("TOPLEFT", ui.detail, "TOPLEFT", 14, -306)
        ui.fullHistory:ClearAllPoints(); ui.fullHistory:SetPoint("TOPRIGHT", ui.detail, "TOPRIGHT", -14, -301)
        for index = 1, table.getn(ui.timeline) do
            ui.timeline[index]:ClearAllPoints(); ui.timeline[index]:SetPoint("TOPLEFT", ui.detail, "TOPLEFT", 14, -325 - ((index - 1) * 15)); ui.timeline[index]:SetWidth(detailWidth - 28)
        end
        ui.troubleTitle:ClearAllPoints(); ui.troubleTitle:SetPoint("TOPLEFT", ui.detail, "TOPLEFT", 14, -371)
        ui.copyTrouble:ClearAllPoints(); ui.copyTrouble:SetPoint("TOPRIGHT", ui.detail, "TOPRIGHT", -14, -365)
        ui.trouble:ClearAllPoints(); ui.trouble:SetPoint("TOPLEFT", ui.detail, "TOPLEFT", 14, -391); ui.trouble:SetWidth(detailWidth - 28)
        -- Choice menus live on the page so they can safely overlap their card.
        ui.statusMenu:ClearAllPoints(); ui.statusMenu:SetPoint("TOPLEFT", ui.status, "BOTTOMLEFT", 0, -2)
        ui.resolutionMenu:ClearAllPoints(); ui.resolutionMenu:SetPoint("TOPLEFT", ui.resolution, "BOTTOMLEFT", 0, -2)
    end
end

local function SetOfficerCaseDetailVisibleR28(ui, shown)
    if not ui then return end
    SetShown183(ui.detailEmpty, not shown)
    local controls = {
        ui.detailTitle, ui.detailMeta, ui.detailSummary, ui.assign, ui.status, ui.resolution,
        ui.reason, ui.response, ui.comment, ui.save, ui.warning, ui.timelineTitle,
        ui.fullHistory, ui.troubleTitle, ui.copyTrouble, ui.trouble,
    }
    local index
    for index = 1, table.getn(controls) do SetShown183(controls[index], shown) end
    for index = 1, table.getn(ui.timeline or {}) do SetShown183(ui.timeline[index], shown) end
    if not shown then
        if ui.statusMenu then ui.statusMenu:Hide() end
        if ui.resolutionMenu then ui.resolutionMenu:Hide() end
    end
end

function OTLGM:RefreshOfficerCasesPageR25(reason)
    local ui = self.ui and self.ui.officerCasesPageR25
    if not ui or not self:IsOfficerMode() then return false end
    local list = OfficerCaseListR25(self, ui.filterKey)
    local capacity = tonumber(ui.visibleRowsR25) or 6
    local maximum = math.max(0, table.getn(list) - capacity)
    ui.offset = math.max(0, math.min(maximum, tonumber(ui.offset) or 0))
    ui.scrollSilent = true
    if ui.scrollbar.SetScrollMetrics180 then ui.scrollbar:SetScrollMetrics180(table.getn(list), capacity, ui.offset)
    else ui.scrollbar:SetMinMaxValues(0, maximum) ui.scrollbar:SetValue(ui.offset) end
    ui.scrollSilent = nil
    ui.count:SetText(tostring(table.getn(list)) .. " case(s)")

    -- r28: selection is owned by the current filter. A terminal case may not
    -- remain visible in the detail pane while Open/Waiting has zero rows.
    local selected = self:GetOfficerCaseByIdR25(ui.selectedId)
    if selected and not OfficerCaseFilterMatchR25(selected, ui.filterKey) then selected = nil end
    if not selected and list[1] then
        selected = list[1]
        ui.selectedId = selected.id
        self.ui.officerCaseSelectedR25 = selected.id
    elseif not selected then
        ui.selectedId = nil
        self.ui.officerCaseSelectedR25 = nil
    end

    local index, row, record, color
    for index = 1, table.getn(ui.filters) do UI:SetSelected(ui.filters[index], ui.filters[index].otlCaseFilterR25 == ui.filterKey) end
    for index = 1, table.getn(ui.rows) do
        row = ui.rows[index]
        record = index <= capacity and list[ui.offset + index] or nil
        if record then
            row.otlCaseIdR25 = record.id
            row.title:SetText(Short183(tostring(record.author or "Unknown") .. (record.target and record.target ~= "" and (" -> " .. record.target) or ""), 44))
            row.meta:SetText(Short183(FormatModerationDate183(self, record.createdAt) .. "  •  " .. ReportTypeLabel183(record.reportType)
                .. "/" .. ReportCategoryLabel183(record.reportType, record.category) .. "  •  "
                .. (record.assignedTo183 and record.assignedTo183 ~= "" and ("@" .. record.assignedTo183) or "Unassigned"), 72))
            row.summary:SetText(Short183(tostring(record.text or "No summary"), 42))
            row.status:SetText(Short183(ReportStatusLabel183(record.status or "NEW"), 18))
            color = CaseSemanticColorR25(record.status)
            row.status:SetTextColor(color[1], color[2], color[3])
            row.statusDotR25:SetTexture(color[1], color[2], color[3], 0.92)
            UI:SetSelected(row, selected and tostring(record.id) == tostring(selected.id) or false)
            row:Show()
        else row.otlCaseIdR25 = nil row:Hide() end
    end
    SetShown183(ui.empty, table.getn(list) == 0)

    if not selected then
        ui.pendingStatusR25, ui.pendingResolutionR25 = nil, nil
        SetEditText183(ui.reason, "") SetEditText183(ui.response, "") SetEditText183(ui.comment, "")
        for index = 1, table.getn(ui.timeline) do ui.timeline[index]:SetText("") end
        ui.trouble:SetText("")
        SetOfficerCaseDetailVisibleR28(ui, false)
        return true
    end
    SetOfficerCaseDetailVisibleR28(ui, true)
    ui.detailTitle:SetText(Short183(tostring(selected.author or "Unknown") .. (selected.target and selected.target ~= "" and (" -> " .. selected.target) or "") .. "  •  " .. ReportTypeLabel183(selected.reportType), 66))
    ui.detailMeta:SetText(ReportCategoryLabel183(selected.reportType, selected.category) .. "  •  " .. FormatModerationDate183(self, selected.createdAt)
        .. "  •  " .. (selected.assignedTo183 and selected.assignedTo183 ~= "" and ("Assigned to " .. selected.assignedTo183) or "Unassigned"))
    ui.detailSummary:SetText("Report text: " .. CaseDisplayTextR30(Short183(tostring(selected.text or "No submitted text"), 228)))
    ui.pendingStatusR25, ui.pendingResolutionR25 = selected.status or "NEW", nil
    UI:SetText(ui.status, "Status: " .. ReportStatusLabel183(ui.pendingStatusR25))
    UI:SetText(ui.resolution, "Reason: " .. Short183(tostring(selected.statusReason183 or "No preset"), 20))
    local player = PlayerName183()
    UI:SetText(ui.assign, Normalize183(self, selected.assignedTo183 or "") == Normalize183(self, player) and "Release Case" or "Take Case")
    SetEditText183(ui.reason, selected.statusReason183 or "")
    SetEditText183(ui.response, "")
    SetEditText183(ui.comment, selected.privateComment or "")
    local timeline = EnsureTimeline183(selected)
    for index = 1, table.getn(ui.timeline) do
        local entry = timeline[index]
        if entry then
            ui.timeline[index]:SetText(Short183(FormatModerationDate183(self, entry.ts) .. "  •  " .. tostring(entry.kind or "UPDATE")
                .. "  •  " .. tostring(entry.actor or "Leadership") .. "  •  " .. tostring(entry.text or ""), 100))
        else ui.timeline[index]:SetText("") end
    end
    ui.trouble:SetText(BuildCaseTroubleshootingTextR25(self, selected))
    local authorWithdrawnR30 = selected.status == "WITHDRAWN"
    UI:SetEnabled(ui.assign, not authorWithdrawnR30, authorWithdrawnR30 and "Withdrawn reports are read-only." or nil)
    UI:SetEnabled(ui.status, not authorWithdrawnR30, authorWithdrawnR30 and "Withdrawn reports are read-only." or nil)
    UI:SetEnabled(ui.resolution, not authorWithdrawnR30, authorWithdrawnR30 and "Withdrawn reports are read-only." or nil)
    UI:SetEnabled(ui.save, not authorWithdrawnR30, authorWithdrawnR30 and "Withdrawn reports are read-only." or nil)
    SetShown183(ui.warning, (not authorWithdrawnR30) and selected.target and selected.target ~= "")
    return true
end

local function RegisterOfficerCasesPageR25(owner)
    if not owner.CreateShellPageModule180 then return false end
    if owner.shellPageModules and owner.shellPageModules.cases then return true end
    owner:CreateShellPageModule180("cases", BuildOfficerCasesPageR25, function(current, reason)
        current:RefreshOfficerCasesPageR25(reason)
    end, LayoutOfficerCasesPageR25, nil, { width = 720, height = 500 })
    return true
end
RegisterOfficerCasesPageR25(OTLGM)

-- Prefer the full page for case work while preserving the old warning drawer.
local PreviousOpenOfficerCasesR25 = OTLGM.OpenOfficerCases183
function OTLGM:OpenOfficerCases183(target, mode)
    if not self:IsOfficerMode() then
        if self.ShowToast then self:ShowToast("Officer permissions are required.", "error") end
        return false
    end
    if tostring(mode or "CASES") == "WARNINGS" then return PreviousOpenOfficerCasesR25(self, target, mode) end
    if not self.ui or not self.ui.main then self:BuildUI() end
    self.ui.officerCasesFilterR25 = tostring(mode or "") == "ATTENTION" and "OPEN" or (self.ui.officerCasesFilterR25 or "OPEN")
    if target and target ~= "" then
        local list = self:GetOfficerCases183(target, nil)
        if list[1] then self.ui.officerCaseSelectedR25 = list[1].id end
    end
    self:ShowPage("cases")
    if self.RefreshOfficerCasesPageR25 then self:RefreshOfficerCasesPageR25("open") end
    return true
end

local PreviousDiagnosticsModeration183 = OTLGM.GetDiagnosticsText
if PreviousDiagnosticsModeration183 then
    function OTLGM:GetDiagnosticsText()
        local text = tostring(PreviousDiagnosticsModeration183(self) or "")
        local state = self:EnsureModeration183()
        local pending = self:GetOwnModerationPendingCount183()
        local reconciliationState, reconciliationPeers = self:GetModerationReconciliationState183()
        local reconciliationRuntime = ReconciliationRuntime183(self)
        local officerCases, officerWarnings, escalations = 0, 0, 0
        if self:IsOfficerMode() then
            local recordId, record
            for recordId, record in pairs(state and state.officerCases or {}) do
                if type(record) == "table" and self:CanCurrentClientAccessModerationRecord183("C", record) then
                    officerCases = officerCases + 1
                    if tostring(record.caseKind183 or "REPORT") == "ESCALATION"
                        and not TERMINAL_REPORT_STATUSES_183[record.status or "NEW"] then escalations = escalations + 1 end
                end
            end
            for recordId, record in pairs(state and state.officerWarnings or {}) do
                if type(record) == "table" and self:CanCurrentClientAccessModerationRecord183("W", record) then
                    officerWarnings = officerWarnings + 1
                end
            end
        end
        return text .. "\nModeration: own pending " .. tostring(pending)
            .. " / officer cases-warnings-escalations " .. tostring(officerCases) .. "/" .. tostring(officerWarnings) .. "/" .. tostring(escalations)
            .. " / inbound assemblies " .. tostring(CountMap183(self.runtime and self.runtime.moderationInbound183))
            .. " / queued packets " .. tostring(self.runtime and self.runtime.moderationPacketsQueued183 or 0)
            .. " / leadership reconciliation " .. tostring(reconciliationState) .. "(" .. tostring(reconciliationPeers) .. ")"
            .. " flows-transfers " .. tostring(CountMap183(reconciliationRuntime.flows))
            .. "/" .. tostring(CountMap183(reconciliationRuntime.transfers))
            .. " / private content and identities excluded"
    end
end

OTLGM:RegisterModule("Moderation183", {
    stage = "G", revision = 2, protocol = "M1", minimumPeer = MIN_MODERATION_VERSION_183,
    reconciliationMinimumPeer = MIN_RECONCILIATION_VERSION_183,
    reconciliationBuckets = RECONCILIATION_BUCKETS_183, reconciliationPage = RECONCILIATION_PAGE_183,
    reconciliationPeers = MAX_RECONCILIATION_PEERS_183,
    reconciliationTransfers = MAX_RECONCILIATION_TRANSFERS_183, reconciliationTTL = RECONCILIATION_TTL_183,
    reconciliationFlowTTL = RECONCILIATION_FLOW_TTL_183,
    ownReportLimit = MAX_OWN_REPORTS_183, officerCaseLimit = MAX_OFFICER_CASES_183,
    officerWarningLimit = MAX_OFFICER_WARNINGS_183, ownWarningLimit = MAX_OWN_WARNINGS_183,
    escalationLimit = MAX_ESCALATIONS_183, timelineLimit = MAX_TIMELINE_183,
    senderBoundReports = true, authorityCheckedOfficerMessages = true, targetedOnly = true,
    pendingOfflineDelivery = true, eventualOfficerState = true, pressureAwareBulk = true,
    noAutomaticPunishment = true, noPrivateDiagnostics = true,
    noOnUpdate = true, noPolling = true, noRosterRequest = true, noHistoryScan = true,
})
