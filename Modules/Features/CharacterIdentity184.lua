-- Order of the Lion Guild Manager 1.8.3
-- Voluntary Main/Alt identity for guild profiles.
--
-- Privacy/security contract:
--   * no account identifiers, heuristics or automatic name matching;
--   * an Alt requests a Main explicitly and the Main must confirm;
--   * other guild members see a relationship only after reciprocal r34 profile
--     attestations have been observed from both real character senders;
--   * pending requests are never published in shared profile summaries;
--   * no event frame, permanent timer, OnUpdate or periodic roster scan.

if not OTLGM or not OTLGM.UI then return end

local UI = OTLGM.UI
local C = UI.colors
local MIN_IDENTITY_VERSION_184 = "1.8.3-rc4-r34"
local MAX_ALTS_PER_MAIN_184 = 6
local MAX_RELATIONS_184 = 48
local PENDING_TTL_184 = 30 * 86400
local PEER_RETRY_COOLDOWN_184 = 300
local IDENTITY_ROLE_ALT_184 = "A"
local IDENTITY_ROLE_MAIN_184 = "M"
local IDENTITY_ROLE_NONE_184 = "N"

local function Normalize184(owner, name)
    if owner.NormalizeName then return owner:NormalizeName(name or "") end
    name = string.gsub(tostring(name or ""), "%-.*$", "")
    return string.lower(name)
end

local function ShortName184(name)
    name = tostring(name or "")
    name = string.gsub(name, "%-.*$", "")
    name = string.gsub(name, "^%s+", "")
    name = string.gsub(name, "%s+$", "")
    return name
end

local function PlayerName184()
    return ShortName184(UnitName and UnitName("player") or "")
end

local function IsSelf184(owner, name)
    local player = Normalize184(owner, PlayerName184())
    return player ~= "" and player == Normalize184(owner, name)
end

local function SafeIdentityName184(owner, name)
    name = ShortName184(name)
    if name == "" or string.len(name) > 12 then return nil end
    if string.find(name, "[%^,|%c%s]") then return nil end
    return name
end

local function CanonicalName184(owner, name)
    local member = owner.GetMember and owner:GetMember(name) or nil
    if member and member.name and member.name ~= "" then return ShortName184(member.name) end
    return ShortName184(name)
end

local function RelationKey184(owner, altName)
    return Normalize184(owner, altName)
end

local function Now184(owner)
    return owner.Now and owner:Now() or time()
end

local function MarkIdentityRevision184(owner, state, name)
    local key = Normalize184(owner, name)
    if key == "" then return 0 end
    state.characterRevision = type(state.characterRevision) == "table" and state.characterRevision or {}
    local record = state.characterRevision[key]
    if type(record) ~= "table" then record = {} state.characterRevision[key] = record end
    record.revision = math.max(0, tonumber(record.revision) or 0) + 1
    record.updatedAt = Now184(owner)
    record.name = CanonicalName184(owner, name)
    return record.revision
end

local function GetIdentityRevision184(owner, state, name)
    local key = Normalize184(owner, name)
    local record = state.characterRevision and state.characterRevision[key] or nil
    return math.max(0, tonumber(record and record.revision) or 0), tonumber(record and record.updatedAt) or 0
end

local function NextRequestRevision184(owner, state, name)
    local key = Normalize184(owner, name)
    if key == "" then return nil end
    state.requestRevision = type(state.requestRevision) == "table" and state.requestRevision or {}
    local previous = math.max(0, tonumber(state.requestRevision[key]) or 0)
    if previous >= 1000000000 then return nil end
    local revision = previous + 1
    state.requestRevision[key] = revision
    return revision
end

local function IsGuildMember184(owner, name)
    return owner.GetMember and owner:GetMember(name) and true or false
end

local function ActiveRelation184(relation)
    return type(relation) == "table" and (relation.state == "PENDING" or relation.state == "CONFIRMED")
end

local function ConfirmedRelation184(relation)
    return type(relation) == "table" and relation.state == "CONFIRMED"
end

local function SortRelations184(rows)
    table.sort(rows, function(left, right)
        if left.state ~= right.state then return left.state == "PENDING" end
        local ln = string.lower(tostring(left.alt or ""))
        local rn = string.lower(tostring(right.alt or ""))
        if ln ~= rn then return ln < rn end
        return (tonumber(left.updatedAt) or 0) > (tonumber(right.updatedAt) or 0)
    end)
end

local function TouchIdentityViewRevision184(owner)
    owner.runtime = owner.runtime or {}
    owner.runtime.characterIdentityViewRevision184 = (tonumber(owner.runtime.characterIdentityViewRevision184) or 0) + 1
end

function OTLGM:EnsureCharacterIdentityDB184()
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    if not db then return nil end
    if type(db.characterIdentity184) ~= "table" then db.characterIdentity184 = {} end
    local state = db.characterIdentity184
    if type(state.relations) ~= "table" then state.relations = {} end
    if type(state.characterRevision) ~= "table" then state.characterRevision = {} end
    if type(state.requestRevision) ~= "table" then state.requestRevision = {} end
    if type(state.lastWireSignature) ~= "table" then state.lastWireSignature = {} end
    if type(state.metrics) ~= "table" then state.metrics = {} end

    local now = Now184(self)
    if now - (tonumber(state.lastPruneAt) or 0) >= 86400 then
        local rows, key, relation = {}, nil, nil
        for key, relation in pairs(state.relations) do
            local malformed = type(relation) ~= "table" or not SafeIdentityName184(self, relation.alt) or not SafeIdentityName184(self, relation.main)
            local expired = type(relation) == "table" and relation.state == "PENDING"
                and now - (tonumber(relation.updatedAt) or tonumber(relation.createdAt) or 0) > PENDING_TTL_184
            if malformed or expired then
                state.relations[key] = nil
                state.metrics.pruned = (tonumber(state.metrics.pruned) or 0) + 1
            elseif type(relation) == "table" then
                table.insert(rows, { key = key, updatedAt = tonumber(relation.updatedAt) or 0, confirmed = relation.state == "CONFIRMED" })
            end
        end
        if table.getn(rows) > MAX_RELATIONS_184 then
            table.sort(rows, function(left, right)
                if left.confirmed ~= right.confirmed then return not left.confirmed end
                if left.updatedAt ~= right.updatedAt then return left.updatedAt < right.updatedAt end
                return tostring(left.key) < tostring(right.key)
            end)
            local index = 1
            while table.getn(rows) - index + 1 > MAX_RELATIONS_184 do
                state.relations[rows[index].key] = nil
                state.metrics.pruned = (tonumber(state.metrics.pruned) or 0) + 1
                index = index + 1
            end
        end
        state.lastPruneAt = now
    end
    return state
end

function OTLGM:GetCharacterIdentityRelations184(name, includePending)
    local state = self:EnsureCharacterIdentityDB184()
    if not state then return nil, {} end
    local wanted = Normalize184(self, name)
    local asAlt, asMain = nil, {}
    local _, relation
    for _, relation in pairs(state.relations or {}) do
        if type(relation) == "table" and (includePending and ActiveRelation184(relation) or ConfirmedRelation184(relation)) then
            if Normalize184(self, relation.alt) == wanted then asAlt = relation end
            if Normalize184(self, relation.main) == wanted then table.insert(asMain, relation) end
        end
    end
    SortRelations184(asMain)
    return asAlt, asMain
end

function OTLGM:GetCharacterIdentityWire184()
    local player = PlayerName184()
    if player == "" then return nil end
    local state = self:EnsureCharacterIdentityDB184()
    if not state then return nil end
    local asAlt, asMain = self:GetCharacterIdentityRelations184(player, false)
    local revision, updatedAt = GetIdentityRevision184(self, state, player)
    local role, peers = IDENTITY_ROLE_NONE_184, ""
    if asAlt and asMain and table.getn(asMain) > 0 then
        state.metrics.conflicts = (tonumber(state.metrics.conflicts) or 0) + 1
        return nil
    elseif asAlt and IsGuildMember184(self, asAlt.main) then
        role = IDENTITY_ROLE_ALT_184
        peers = SafeIdentityName184(self, asAlt.main) or ""
    elseif table.getn(asMain) > 0 then
        local names, index = {}, nil
        for index = 1, table.getn(asMain) do
            if table.getn(names) >= MAX_ALTS_PER_MAIN_184 then break end
            if IsGuildMember184(self, asMain[index].alt) then
                local value = SafeIdentityName184(self, asMain[index].alt)
                if value then table.insert(names, value) end
            end
        end
        if table.getn(names) > 0 then
            role = IDENTITY_ROLE_MAIN_184
            peers = table.concat(names, ",")
        end
    elseif revision <= 0 then
        return nil
    end

    -- A confirmed local relation can temporarily become non-shareable when the
    -- counterpart leaves this guild. Treat that as a real wire-state change so
    -- peers can clear the old claim without deleting the owner's local choice.
    local key = Normalize184(self, player)
    local signature = role .. "^" .. peers
    local previousSignature = state.lastWireSignature and state.lastWireSignature[key] or nil
    if revision <= 0 or (previousSignature and previousSignature ~= signature) then
        revision = MarkIdentityRevision184(self, state, player)
        updatedAt = Now184(self)
    end
    state.lastWireSignature[key] = signature
    updatedAt = math.max(1, tonumber(updatedAt) or Now184(self))
    return role, peers, revision, updatedAt
end

local function ParseIdentityPeerList184(owner, wire)
    local result, seen = {}, {}
    wire = tostring(wire or "")
    local token
    for token in string.gfind(wire, "[^,]+") do
        local name = SafeIdentityName184(owner, token)
        local key = name and Normalize184(owner, name) or ""
        if name and key ~= "" and not seen[key] and table.getn(result) < MAX_ALTS_PER_MAIN_184 then
            seen[key] = true
            table.insert(result, CanonicalName184(owner, name))
        end
    end
    return result
end

local function IdentityListContains184(owner, list, name)
    local wanted = Normalize184(owner, name)
    local index
    for index = 1, table.getn(list or {}) do
        if Normalize184(owner, list[index]) == wanted then return true end
    end
    return false
end

function OTLGM:HandleCharacterIdentityProfileFields184(sender, fields, profileRecord)
    if type(fields) ~= "table" or not profileRecord or not sender then return false end
    local role = tostring(fields[8] or "")
    if role ~= IDENTITY_ROLE_ALT_184 and role ~= IDENTITY_ROLE_MAIN_184 and role ~= IDENTITY_ROLE_NONE_184 then return false end
    local revision = tonumber(fields[10]) or 0
    local updatedAt = tonumber(fields[11]) or 0
    if revision < 1 or updatedAt <= 0 or updatedAt > Now184(self) + 604800 then return false end
    local previous = type(profileRecord.identity184) == "table" and profileRecord.identity184 or nil
    local previousRevision = tonumber(previous and previous.revision) or 0
    local previousTime = tonumber(previous and previous.updatedAt) or 0
    if revision < previousRevision or (revision == previousRevision and updatedAt <= previousTime) then return false end

    local identity = { role = role, revision = revision, updatedAt = updatedAt }
    if role == IDENTITY_ROLE_ALT_184 then
        local main = SafeIdentityName184(self, fields[9] or "")
        if not main or Normalize184(self, main) == Normalize184(self, sender) then return false end
        identity.main = CanonicalName184(self, main)
    elseif role == IDENTITY_ROLE_MAIN_184 then
        identity.alts = ParseIdentityPeerList184(self, fields[9] or "")
        if table.getn(identity.alts) < 1 then return false end
    else
        if tostring(fields[9] or "") ~= "" then return false end
        identity.alts = {}
    end
    profileRecord.identity184 = identity
    profileRecord.updatedAt = math.max(tonumber(profileRecord.updatedAt) or 0, updatedAt)

    local state = self:EnsureCharacterIdentityDB184()
    if state then state.metrics.profileClaimsReceived = (tonumber(state.metrics.profileClaimsReceived) or 0) + 1 end
    TouchIdentityViewRevision184(self)
    self:ReconcileCharacterIdentityFromPeer184(sender, identity)
    return true
end

local function IdentityPeerVersionAllowed184(owner, name)
    if not owner.GetDetectedAddonVersion183 then return true end
    local version = owner:GetDetectedAddonVersion183(name)
    if not version or version == "" or version == "Detected" then return true end
    return owner:IsCharacterIdentityPeer184(version)
end

function OTLGM:GetVerifiedCharacterIdentity184(name)
    local record = self.GetGuildProfileRecord183 and self:GetGuildProfileRecord183(name) or nil
    local identity = record and type(record.identity184) == "table" and record.identity184 or nil
    if not identity then return nil end
    local member = self.GetMember and self:GetMember(name) or nil
    if not member or not IdentityPeerVersionAllowed184(self, member.name) then return nil end

    if identity.role == IDENTITY_ROLE_ALT_184 and identity.main then
        local mainMember = self.GetMember and self:GetMember(identity.main) or nil
        if mainMember and not IdentityPeerVersionAllowed184(self, mainMember.name) then mainMember = nil end
        local mainRecord = mainMember and self.GetGuildProfileRecord183 and self:GetGuildProfileRecord183(mainMember.name) or nil
        local mainIdentity = mainRecord and type(mainRecord.identity184) == "table" and mainRecord.identity184 or nil
        if mainMember and mainIdentity and mainIdentity.role == IDENTITY_ROLE_MAIN_184
            and IdentityListContains184(self, mainIdentity.alts or {}, member.name) then
            return {
                verified = true, role = "ALT", main = mainMember.name,
                updatedAt = math.min(tonumber(identity.updatedAt) or 0, tonumber(mainIdentity.updatedAt) or 0),
            }
        end
        return nil
    end

    if identity.role == IDENTITY_ROLE_MAIN_184 then
        local verified = {}
        local index, altName
        for index = 1, table.getn(identity.alts or {}) do
            altName = identity.alts[index]
            local altMember = self.GetMember and self:GetMember(altName) or nil
            if altMember and not IdentityPeerVersionAllowed184(self, altMember.name) then altMember = nil end
            local altRecord = altMember and self.GetGuildProfileRecord183 and self:GetGuildProfileRecord183(altMember.name) or nil
            local altIdentity = altRecord and type(altRecord.identity184) == "table" and altRecord.identity184 or nil
            if altMember and altIdentity and altIdentity.role == IDENTITY_ROLE_ALT_184
                and Normalize184(self, altIdentity.main) == Normalize184(self, member.name) then
                table.insert(verified, altMember.name)
            end
        end
        if table.getn(verified) > 0 then
            table.sort(verified, function(left, right) return string.lower(left) < string.lower(right) end)
            return { verified = true, role = "MAIN", alts = verified, updatedAt = tonumber(identity.updatedAt) or 0 }
        end
    end
    return nil
end

function OTLGM:GetCharacterIdentityView184(name)
    local memberName = CanonicalName184(self, name)
    if IsSelf184(self, memberName) then
        local asAlt, asMain = self:GetCharacterIdentityRelations184(memberName, true)
        local pending, confirmed = {}, {}
        local index
        for index = 1, table.getn(asMain or {}) do
            if asMain[index].state == "PENDING" then table.insert(pending, asMain[index])
            elseif asMain[index].state == "CONFIRMED" then table.insert(confirmed, asMain[index]) end
        end
        if asAlt then
            return {
                selfProfile = true, role = "ALT", state = asAlt.state,
                main = CanonicalName184(self, asAlt.main), relation = asAlt,
                counterpartInGuild = IsGuildMember184(self, asAlt.main),
                pendingCount = table.getn(pending), confirmedCount = table.getn(confirmed),
            }
        end
        if table.getn(pending) > 0 or table.getn(confirmed) > 0 then
            local names, rosterAltCount = {}, 0
            for index = 1, table.getn(confirmed) do
                table.insert(names, CanonicalName184(self, confirmed[index].alt))
                if IsGuildMember184(self, confirmed[index].alt) then rosterAltCount = rosterAltCount + 1 end
            end
            return {
                selfProfile = true, role = "MAIN", state = table.getn(confirmed) > 0 and "CONFIRMED" or "PENDING",
                alts = names, pending = pending, confirmed = confirmed,
                pendingCount = table.getn(pending), confirmedCount = table.getn(confirmed),
                rosterAltCount = rosterAltCount,
            }
        end
        return { selfProfile = true, role = "NONE", state = "NONE", pendingCount = 0, confirmedCount = 0 }
    end
    local verified = self:GetVerifiedCharacterIdentity184(memberName)
    if verified then return verified end
    -- The two characters may share this account-wide SavedVariables file, or
    -- this client may be one side of a cross-account confirmation. Show that
    -- local knowledge to the owner without pretending third-party reciprocal
    -- verification has already happened.
    local localAlt, localMain = self:GetCharacterIdentityRelations184(memberName, false)
    if localAlt then
        return { localConfirmed = true, role = "ALT", main = CanonicalName184(self, localAlt.main),
            counterpartInGuild = IsGuildMember184(self, localAlt.main), updatedAt = tonumber(localAlt.updatedAt) or 0 }
    end
    if table.getn(localMain or {}) > 0 then
        local names, rosterCount, index = {}, 0, nil
        for index = 1, table.getn(localMain) do
            if IsGuildMember184(self, localMain[index].alt) then
                table.insert(names, CanonicalName184(self, localMain[index].alt))
                rosterCount = rosterCount + 1
            end
        end
        return { localConfirmed = true, role = "MAIN", alts = names, rosterAltCount = rosterCount,
            counterpartInGuild = rosterCount > 0, updatedAt = tonumber(localMain[1] and localMain[1].updatedAt) or 0 }
    end
    return nil
end

function OTLGM:GetCharacterIdentityTooltipLine184(name)
    local view = self:GetCharacterIdentityView184(name)
    if not view then return nil end
    if view.role == "ALT" and view.main then
        if view.counterpartInGuild == false then return "Main: " .. tostring(view.main) .. " (not currently in guild)" end
        if view.selfProfile and view.state == "PENDING" then return "Main: " .. tostring(view.main) .. " (pending confirmation)" end
        return "Main: " .. tostring(view.main)
    elseif view.role == "MAIN" then
        local alts = view.alts or {}
        if table.getn(alts) > 0 then
            local text = table.concat(alts, ", ")
            if string.len(text) > 62 then text = string.sub(text, 1, 59) .. "..." end
            return "Linked alts: " .. text
        elseif view.selfProfile and (tonumber(view.pendingCount) or 0) > 0 then
            return tostring(view.pendingCount) .. " pending alt link request(s)"
        end
    end
    return nil
end

function OTLGM:GetPendingCharacterIdentityCount184(name)
    local memberName = CanonicalName184(self, name or PlayerName184())
    local _, asMain = self:GetCharacterIdentityRelations184(memberName, true)
    local pending, index = 0, nil
    for index = 1, table.getn(asMain or {}) do
        if asMain[index] and asMain[index].state == "PENDING" then pending = pending + 1 end
    end
    return pending
end

function OTLGM:GetCharacterIdentityRosterBadge184(name)
    local view = self:GetCharacterIdentityView184(name)
    if not view then return nil end
    if view.role == "ALT" then
        if view.selfProfile and view.state == "PENDING" then
            return { label = "A?", color = self.colors and self.colors.orange or "|cffffaa33", title = "Alt link pending" }
        end
        return { label = "A", color = self.colors and self.colors.blue or "|cff55aaff", title = "Linked alt" }
    elseif view.role == "MAIN" then
        if view.selfProfile and (tonumber(view.confirmedCount) or 0) == 0 and (tonumber(view.pendingCount) or 0) > 0 then
            return { label = "M?", color = self.colors and self.colors.orange or "|cffffaa33", title = "Main with pending request" }
        end
        return { label = "M", color = self.colors and self.colors.gold or "|cffffcc66", title = "Main character" }
    end
    return nil
end

function OTLGM:GetCharacterIdentityCompactText184(name)
    local view = self:GetCharacterIdentityView184(name)
    if not view then return nil end
    if view.role == "ALT" and view.main then
        local suffix = view.selfProfile and view.state == "PENDING" and " (pending)" or ""
        return "Alt  •  Main: " .. tostring(view.main) .. suffix
    elseif view.role == "MAIN" then
        local count = table.getn(view.alts or {})
        if view.selfProfile then count = tonumber(view.confirmedCount) or count end
        local pending = view.selfProfile and (tonumber(view.pendingCount) or 0) or 0
        local text = "Main  •  " .. tostring(count) .. " linked alt" .. (count == 1 and "" or "s")
        if pending > 0 then text = text .. ", " .. tostring(pending) .. " pending" end
        return text
    end
    return nil
end

local function CountMainRelations184(owner, mainName)
    local _, asMain = owner:GetCharacterIdentityRelations184(mainName, true)
    return table.getn(asMain or {})
end

local function CurrentActsAsMain184(owner, name)
    local _, asMain = owner:GetCharacterIdentityRelations184(name, true)
    return table.getn(asMain or {}) > 0
end

local function CurrentActsAsAlt184(owner, name)
    local asAlt = owner:GetCharacterIdentityRelations184(name, true)
    return asAlt ~= nil
end

function OTLGM:IsCharacterIdentityPeer184(version)
    version = tostring(version or "")
    if version == "" or version == "Detected" then return false end
    if self.IsVersionNewer then return not self:IsVersionNewer(MIN_IDENTITY_VERSION_184, version) end
    return string.find(version, "^1%.8%.3%-rc4%-r3[4-9]") ~= nil
end

function OTLGM:QueueCharacterIdentityControl184(kind, target, relation, reason)
    if not self.QueueNetworkPayload or not target or target == "" or not relation then return false end
    local version = self.GetDetectedAddonVersion183 and self:GetDetectedAddonVersion183(target) or nil
    if not self:IsCharacterIdentityPeer184(version) then return false end
    local now = Now184(self)
    local payload
    if kind == "IDREQ" then
        payload = table.concat({ "F1", "IDREQ", tostring(relation.main or ""), tostring(math.max(1, tonumber(relation.requestRevision) or 1)), tostring(now) }, "^")
    elseif kind == "IDACK" or kind == "IDREJ" then
        payload = table.concat({ "F1", kind, tostring(relation.alt or ""), tostring(math.max(1, tonumber(relation.requestRevision) or 1)), tostring(now) }, "^")
    elseif kind == "IDUNLINK" then
        payload = table.concat({ "F1", "IDUNLINK", tostring(target), tostring(math.max(1, tonumber(relation.requestRevision) or 1)), tostring(now) }, "^")
    else
        return false
    end
    local key = "identity:" .. string.lower(kind) .. ":" .. Normalize184(self, target)
    local queued = self:QueueNetworkPayload(payload, "WHISPER", target, 1, "character-identity", key)
    if queued then
        local state = self:EnsureCharacterIdentityDB184()
        if state then
            state.metrics.controlSent = (tonumber(state.metrics.controlSent) or 0) + 1
            state.metrics.lastControlReason = tostring(reason or kind)
        end
    end
    return queued and true or false
end

local function RefreshIdentityViews184(owner, reason)
    TouchIdentityViewRevision184(owner)
    if owner.RefreshCharacterIdentityHomeIndicator184 then owner:RefreshCharacterIdentityHomeIndicator184() end
    if owner.ui and owner.ui.currentPage == "roster" and owner.ui.main and owner.ui.main.IsVisible and owner.ui.main:IsVisible() and owner.RefreshRosterPage then
        owner:RefreshRosterPage()
    elseif owner.MarkPageDirty180 then
        owner:MarkPageDirty180("roster")
    end
    local profile = owner.ui and owner.ui.guildProfile183
    if profile and profile.IsVisible and profile:IsVisible() and owner.RefreshGuildProfile183 then owner:RefreshGuildProfile183(reason or "identity") end
    local modal = owner.ui and owner.ui.characterIdentityManager184
    if modal and modal.IsVisible and modal:IsVisible() and owner.RefreshCharacterIdentityManager184 then owner:RefreshCharacterIdentityManager184() end
end

function OTLGM:CanRequestMainLink184(mainName)
    local player = PlayerName184()
    mainName = SafeIdentityName184(self, mainName)
    if player == "" or not mainName then return false, "Select a valid guild character." end
    if Normalize184(self, player) == Normalize184(self, mainName) then return false, "A character cannot be its own main." end
    local mainMember = self.GetMember and self:GetMember(mainName) or nil
    if not mainMember then return false, "The selected main must currently be in this guild." end
    mainName = CanonicalName184(self, mainMember.name)
    if CurrentActsAsMain184(self, player) then return false, "This character already has alt requests or linked alts. Resolve them first." end
    local existing = self:GetCharacterIdentityRelations184(player, true)
    if existing then
        if Normalize184(self, existing.main) == Normalize184(self, mainName) then return false, "This Main/Alt request already exists." end
        return false, "Unlink or cancel the current main relationship before choosing another main."
    end
    if CurrentActsAsAlt184(self, mainName) then return false, "That character is already linked locally as an alt and cannot be used as a main." end
    local verifiedMain = self:GetVerifiedCharacterIdentity184(mainName)
    if verifiedMain and verifiedMain.role == "ALT" then return false, "That character is verified as an alt and cannot be used as a main." end
    if CountMainRelations184(self, mainName) >= MAX_ALTS_PER_MAIN_184 then return false, "That main already has the maximum of " .. tostring(MAX_ALTS_PER_MAIN_184) .. " active alt links." end
    return true, nil, mainName
end

function OTLGM:RequestMainLink184(mainName)
    local player = PlayerName184()
    local allowed184, reason184, canonical184 = self:CanRequestMainLink184(mainName)
    if not allowed184 then return false, reason184 end
    mainName = canonical184

    local state = self:EnsureCharacterIdentityDB184()
    if not state then return false, "Guild identity storage is unavailable." end
    local key = RelationKey184(self, player)
    local now = Now184(self)
    local requestRevision = NextRequestRevision184(self, state, player)
    if not requestRevision then return false, "Too many historical link changes are stored for this character." end
    local relation = {
        alt = player, main = mainName, state = "PENDING",
        requestRevision = requestRevision, revision = 0, createdAt = now, updatedAt = now,
    }
    state.relations[key] = relation
    state.metrics.requestsCreated = (tonumber(state.metrics.requestsCreated) or 0) + 1
    self:QueueCharacterIdentityControl184("IDREQ", mainName, relation, "request")
    RefreshIdentityViews184(self, "identity-request")
    if self.ShowToast then
        local version = self.GetDetectedAddonVersion183 and self:GetDetectedAddonVersion183(mainName) or nil
        if self:IsCharacterIdentityPeer184(version) then
            self:ShowToast("Alt link requested from " .. tostring(mainName) .. ". The main must confirm it.", "pending", 6)
        else
            self:ShowToast("Alt link saved as pending. Log into " .. tostring(mainName) .. " to review and confirm it.", "pending", 7)
        end
    end
    return true
end

function OTLGM:ConfirmAltLink184(altName)
    local player = PlayerName184()
    local state = self:EnsureCharacterIdentityDB184()
    if not state then return false, "Guild identity storage is unavailable." end
    local key = RelationKey184(self, altName)
    local relation = state.relations[key]
    if not relation or relation.state ~= "PENDING" or Normalize184(self, relation.main) ~= Normalize184(self, player) then return false, "No pending alt request was found for this character." end
    if CurrentActsAsAlt184(self, player) then return false, "A character linked as an alt cannot also act as a main." end
    if CountMainRelations184(self, player) > MAX_ALTS_PER_MAIN_184 then return false, "Too many active alt links are stored for this main." end
    local altMember = self.GetMember and self:GetMember(relation.alt) or nil
    if not altMember then return false, "The alt is no longer in the current guild roster." end

    local now = Now184(self)
    relation.state = "CONFIRMED"
    relation.confirmedAt = now
    relation.updatedAt = now
    relation.revision = math.max(0, tonumber(relation.revision) or 0) + 1
    MarkIdentityRevision184(self, state, relation.alt)
    MarkIdentityRevision184(self, state, relation.main)
    state.metrics.confirmed = (tonumber(state.metrics.confirmed) or 0) + 1
    self:QueueCharacterIdentityControl184("IDACK", relation.alt, relation, "confirm")
    if self.QueueGuildProfileSummary183 then self:QueueGuildProfileSummary183("GUILD", nil, "identity-confirmed") end
    RefreshIdentityViews184(self, "identity-confirm")
    if self.ShowToast then self:ShowToast(tostring(relation.alt) .. " is now confirmed as an alt of " .. tostring(relation.main) .. ".", "success", 6) end
    return true
end

function OTLGM:DeclineAltLink184(altName)
    local player = PlayerName184()
    local state = self:EnsureCharacterIdentityDB184()
    if not state then return false end
    local key = RelationKey184(self, altName)
    local relation = state.relations[key]
    if not relation or relation.state ~= "PENDING" or Normalize184(self, relation.main) ~= Normalize184(self, player) then return false end
    self:QueueCharacterIdentityControl184("IDREJ", relation.alt, relation, "decline")
    state.relations[key] = nil
    state.metrics.declined = (tonumber(state.metrics.declined) or 0) + 1
    RefreshIdentityViews184(self, "identity-decline")
    if self.ShowToast then self:ShowToast("Alt link request declined.", "success", 4) end
    return true
end

function OTLGM:UnlinkCharacterIdentity184(otherName)
    local player = PlayerName184()
    local state = self:EnsureCharacterIdentityDB184()
    if not state then return false, "Guild identity storage is unavailable." end
    local relation, key = nil, nil
    local asAlt = self:GetCharacterIdentityRelations184(player, true)
    if asAlt then
        relation = asAlt
        key = RelationKey184(self, relation.alt)
        otherName = relation.main
    else
        local _, asMain = self:GetCharacterIdentityRelations184(player, true)
        local index
        for index = 1, table.getn(asMain or {}) do
            if Normalize184(self, asMain[index].alt) == Normalize184(self, otherName) then relation = asMain[index] key = RelationKey184(self, relation.alt) break end
        end
    end
    if not relation or not key then return false, "No matching Main/Alt relationship was found." end
    local wasConfirmed = relation.state == "CONFIRMED"
    relation.revision = math.max(0, tonumber(relation.revision) or 0) + 1
    local counterpart = Normalize184(self, player) == Normalize184(self, relation.alt) and relation.main or relation.alt
    if wasConfirmed then
        MarkIdentityRevision184(self, state, relation.alt)
        MarkIdentityRevision184(self, state, relation.main)
        self:QueueCharacterIdentityControl184("IDUNLINK", counterpart, relation, "unlink")
    elseif Normalize184(self, player) == Normalize184(self, relation.alt) then
        self:QueueCharacterIdentityControl184("IDUNLINK", counterpart, relation, "cancel")
    end
    state.relations[key] = nil
    state.metrics.unlinked = (tonumber(state.metrics.unlinked) or 0) + 1
    if self.QueueGuildProfileSummary183 and wasConfirmed then self:QueueGuildProfileSummary183("GUILD", nil, "identity-unlinked") end
    RefreshIdentityViews184(self, "identity-unlink")
    if self.ShowToast then self:ShowToast(wasConfirmed and "Character link removed." or "Pending alt request cancelled.", "success", 5) end
    return true
end

function OTLGM:HandleCharacterIdentityControl184(fields, channel, sender)
    if type(fields) ~= "table" or fields[1] ~= "F1" then return false end
    local kind = fields[2]
    if kind ~= "IDREQ" and kind ~= "IDACK" and kind ~= "IDREJ" and kind ~= "IDUNLINK" then return false end
    if channel ~= "WHISPER" or not sender or sender == "" or IsSelf184(self, sender) then return true end
    if self.GetMember and not self:GetMember(sender) then return false end
    local timestamp = tonumber(fields[5]) or 0
    local now = Now184(self)
    if timestamp <= 0 or timestamp > now + 604800 or now - timestamp > PENDING_TTL_184 then return true end
    local player = PlayerName184()
    local state = self:EnsureCharacterIdentityDB184()
    if not state then return true end
    state.metrics.controlReceived = (tonumber(state.metrics.controlReceived) or 0) + 1

    if kind == "IDREQ" then
        local requestedMain = SafeIdentityName184(self, fields[3] or "")
        local requestRevision = tonumber(fields[4]) or 0
        if not requestedMain or requestRevision < 1 or Normalize184(self, requestedMain) ~= Normalize184(self, player) then return true end
        if CurrentActsAsAlt184(self, player) or CurrentActsAsMain184(self, sender)
            or CountMainRelations184(self, player) >= MAX_ALTS_PER_MAIN_184 then
            local rejected = { alt = CanonicalName184(self, sender), main = player, requestRevision = requestRevision }
            self:QueueCharacterIdentityControl184("IDREJ", sender, rejected, "conflict")
            return true
        end
        local key = RelationKey184(self, sender)
        local relation = state.relations[key]
        if relation and relation.state == "CONFIRMED" and Normalize184(self, relation.main) == Normalize184(self, player) then
            self:QueueCharacterIdentityControl184("IDACK", sender, relation, "already-confirmed")
            return true
        end
        if relation and ActiveRelation184(relation) and Normalize184(self, relation.main) ~= Normalize184(self, player) then
            local rejected = { alt = CanonicalName184(self, sender), main = player, requestRevision = requestRevision }
            self:QueueCharacterIdentityControl184("IDREJ", sender, rejected, "existing-main")
            return true
        end
        local isNew = not relation or requestRevision > (tonumber(relation.requestRevision) or 0)
        relation = relation or {}
        relation.alt = CanonicalName184(self, sender)
        relation.main = player
        relation.state = "PENDING"
        relation.requestRevision = math.max(requestRevision, tonumber(relation.requestRevision) or 0)
        relation.createdAt = tonumber(relation.createdAt) or timestamp
        relation.updatedAt = timestamp
        relation.remoteRequest = true
        state.relations[key] = relation
        if isNew and self.ShowToast then self:ShowToast("Alt link request from " .. tostring(relation.alt) .. ". Open My Profile > Characters to confirm or decline.", "pending", 8) end
        RefreshIdentityViews184(self, "identity-request-received")
        return true
    end

    if kind == "IDACK" then
        local alt = SafeIdentityName184(self, fields[3] or "")
        local requestRevision = tonumber(fields[4]) or 0
        if not alt or Normalize184(self, alt) ~= Normalize184(self, player) or requestRevision < 1 then return true end
        local key = RelationKey184(self, player)
        local relation = state.relations[key]
        if not relation or Normalize184(self, relation.main) ~= Normalize184(self, sender) then return true end
        if requestRevision < (tonumber(relation.requestRevision) or 0) then return true end
        local changed = relation.state ~= "CONFIRMED"
        relation.state = "CONFIRMED"
        relation.confirmedAt = timestamp
        relation.updatedAt = timestamp
        relation.requestRevision = requestRevision
        relation.revision = math.max(0, tonumber(relation.revision) or 0) + (changed and 1 or 0)
        if changed then
            MarkIdentityRevision184(self, state, relation.alt)
            MarkIdentityRevision184(self, state, relation.main)
            state.metrics.acks = (tonumber(state.metrics.acks) or 0) + 1
            if self.QueueGuildProfileSummary183 then self:QueueGuildProfileSummary183("GUILD", nil, "identity-ack") end
            if self.ShowToast then self:ShowToast("Main/Alt link confirmed with " .. tostring(sender) .. ".", "success", 6) end
        end
        RefreshIdentityViews184(self, "identity-ack")
        return true
    end

    if kind == "IDREJ" then
        local alt = SafeIdentityName184(self, fields[3] or "")
        local requestRevision = tonumber(fields[4]) or 0
        if not alt or Normalize184(self, alt) ~= Normalize184(self, player) then return true end
        local key = RelationKey184(self, player)
        local relation = state.relations[key]
        if relation and relation.state == "PENDING" and Normalize184(self, relation.main) == Normalize184(self, sender)
            and requestRevision >= (tonumber(relation.requestRevision) or 0) then
            state.relations[key] = nil
            state.metrics.rejections = (tonumber(state.metrics.rejections) or 0) + 1
            RefreshIdentityViews184(self, "identity-rejected")
            if self.ShowToast then self:ShowToast(tostring(sender) .. " declined the alt link request.", "error", 6) end
        end
        return true
    end

    local other = SafeIdentityName184(self, fields[3] or "")
    local unlinkRequestRevision = tonumber(fields[4]) or 0
    if not other or Normalize184(self, other) ~= Normalize184(self, player) or unlinkRequestRevision < 1 then return true end
    local key = RelationKey184(self, sender)
    local relation = state.relations[key]
    if not relation then
        local selfRelation = state.relations[RelationKey184(self, player)]
        if selfRelation and Normalize184(self, selfRelation.main) == Normalize184(self, sender) then
            relation = selfRelation
            key = RelationKey184(self, player)
        end
    end
    if relation and unlinkRequestRevision >= (tonumber(relation.requestRevision) or 0)
        and ((Normalize184(self, relation.alt) == Normalize184(self, sender) and Normalize184(self, relation.main) == Normalize184(self, player))
        or (Normalize184(self, relation.alt) == Normalize184(self, player) and Normalize184(self, relation.main) == Normalize184(self, sender))) then
        local wasConfirmed = relation.state == "CONFIRMED"
        state.relations[key] = nil
        if wasConfirmed then
            MarkIdentityRevision184(self, state, relation.alt)
            MarkIdentityRevision184(self, state, relation.main)
            if self.QueueGuildProfileSummary183 then self:QueueGuildProfileSummary183("GUILD", nil, "identity-peer-unlink") end
        end
        state.metrics.peerUnlinks = (tonumber(state.metrics.peerUnlinks) or 0) + 1
        RefreshIdentityViews184(self, "identity-peer-unlink")
        if self.ShowToast then self:ShowToast("Character link with " .. tostring(sender) .. " was removed.", "pending", 6) end
    end
    return true
end

function OTLGM:ReconcileCharacterIdentityFromPeer184(sender, identity)
    local player = PlayerName184()
    if player == "" or not identity then return false end
    local state = self:EnsureCharacterIdentityDB184()
    if not state then return false end
    local changed, key, relation = false, nil, nil

    local asAlt = state.relations[RelationKey184(self, player)]
    if asAlt and asAlt.state == "CONFIRMED" and Normalize184(self, asAlt.main) == Normalize184(self, sender) then
        if identity.role ~= IDENTITY_ROLE_MAIN_184 or not IdentityListContains184(self, identity.alts or {}, player) then
            key, relation, changed = RelationKey184(self, player), asAlt, true
        end
    else
        local senderRelation = state.relations[RelationKey184(self, sender)]
        if senderRelation and senderRelation.state == "CONFIRMED"
            and Normalize184(self, senderRelation.main) == Normalize184(self, player) then
            if identity.role ~= IDENTITY_ROLE_ALT_184 or Normalize184(self, identity.main) ~= Normalize184(self, player) then
                key, relation, changed = RelationKey184(self, sender), senderRelation, true
            end
        end
    end

    if changed and key and relation then
        state.relations[key] = nil
        MarkIdentityRevision184(self, state, relation.alt)
        MarkIdentityRevision184(self, state, relation.main)
        state.metrics.reconciledUnlinks = (tonumber(state.metrics.reconciledUnlinks) or 0) + 1
        if self.QueueGuildProfileSummary183 then self:QueueGuildProfileSummary183("GUILD", nil, "identity-reconcile") end
        RefreshIdentityViews184(self, "identity-reconcile")
        return true
    end
    return false
end

function OTLGM:RetryCharacterIdentityForPresence184(sender, version)
    if not sender or sender == "" or IsSelf184(self, sender) or not self:IsCharacterIdentityPeer184(version) then return false end
    local player = PlayerName184()
    local state = self:EnsureCharacterIdentityDB184()
    if not state then return false end
    self.runtime = self.runtime or {}
    self.runtime.identityPresenceRetry184 = self.runtime.identityPresenceRetry184 or {}
    local retryKey = Normalize184(self, sender)
    local now = Now184(self)
    if now - (tonumber(self.runtime.identityPresenceRetry184[retryKey]) or 0) < PEER_RETRY_COOLDOWN_184 then return false end

    local relation = state.relations[RelationKey184(self, player)]
    if relation and relation.state == "PENDING" and Normalize184(self, relation.main) == Normalize184(self, sender) then
        self.runtime.identityPresenceRetry184[retryKey] = now
        return self:QueueCharacterIdentityControl184("IDREQ", sender, relation, "presence-request")
    end
    relation = state.relations[RelationKey184(self, sender)]
    if relation and relation.state == "CONFIRMED" and Normalize184(self, relation.main) == Normalize184(self, player) then
        self.runtime.identityPresenceRetry184[retryKey] = now
        return self:QueueCharacterIdentityControl184("IDACK", sender, relation, "presence-ack")
    end
    return false
end

local PreviousIdentityReleaseMessage184 = OTLGM.HandleRelease175Message
function OTLGM:HandleRelease175Message(message, channel, sender)
    local fields = self:Split(message or "", "^")
    if fields[1] == "F1" and (fields[2] == "IDREQ" or fields[2] == "IDACK" or fields[2] == "IDREJ" or fields[2] == "IDUNLINK") then
        return self:HandleCharacterIdentityControl184(fields, channel, sender)
    end
    return PreviousIdentityReleaseMessage184 and PreviousIdentityReleaseMessage184(self, message, channel, sender) or false
end

local PreviousRememberAddonUserIdentity184 = OTLGM.RememberAddonUser
function OTLGM:RememberAddonUser(sender, version, build, faction)
    if PreviousRememberAddonUserIdentity184 then PreviousRememberAddonUserIdentity184(self, sender, version, build, faction) end
    local effectiveVersion = version
    if not effectiveVersion or effectiveVersion == "" or effectiveVersion == "Detected" then
        effectiveVersion = self.GetDetectedAddonVersion183 and self:GetDetectedAddonVersion183(sender) or nil
    end
    self:RetryCharacterIdentityForPresence184(sender, effectiveVersion)
end

function OTLGM:OpenCharacterIdentityProfile184(name)
    local member = name and self.GetMember and self:GetMember(name) or nil
    if not member then
        if self.ShowToast then self:ShowToast("That linked character is not currently in the guild roster.", "error", 5) end
        return false
    end
    if self.ShowPage then self:ShowPage("roster", { suppressRosterScan183 = true }) end
    if self.SelectRosterMember then self:SelectRosterMember(member.name) end
    local profile184 = self.ui and self.ui.guildProfile183 or nil
    if profile184 and profile184.IsVisible and profile184:IsVisible() and Normalize184(self, profile184.otlMemberName183) == Normalize184(self, member.name) then return true end
    if self.OpenGuildMemberProfile183 then return self:OpenGuildMemberProfile183(member.name, "identity-related", false) end
    return true
end

local function SetIdentityActionButton184(button184, label184, style184, action184, enabled184, reason184)
    if not button184 then return end
    button184.otlIdentityAction184 = action184
    button184.otlStyle = style184 or "secondary"
    UI:SetText(button184, label184 or "")
    UI:SetEnabled(button184, enabled184 ~= false, reason184)
    UI:SetSelected(button184, false)
    if action184 then button184:Show() else button184:Hide() end
end

local function RunIdentityRowAction184(modal184, row184, action184)
    if not row184 or not action184 then return false end
    if action184 == "OPEN" then
        local target184 = row184.otlTarget184 or row184.otlCounterpart184
        if OTLGM.CloseModal180 then OTLGM:CloseModal180(modal184, "identity-open-related") else modal184:Hide() end
        if target184 then return OTLGM:OpenCharacterIdentityProfile184(target184) end
        return false
    end
    if action184 == "CONFIRM" then
        local ok184, message184 = OTLGM:ConfirmAltLink184(row184.otlAlt184)
        if not ok184 and message184 and OTLGM.ShowToast then OTLGM:ShowToast(message184, "error", 6) end
        OTLGM:RefreshCharacterIdentityManager184()
        return ok184
    end
    if action184 == "DECLINE" then
        local alt184 = row184.otlAlt184
        if not alt184 then return false end
        if OTLGM.ShowConfirm then
            OTLGM:ShowConfirm("Decline alt request?", "Decline the Main/Alt request from " .. tostring(alt184) .. "? The alt can send a new request later.", "Decline", function()
                OTLGM:DeclineAltLink184(alt184)
                OTLGM:RefreshCharacterIdentityManager184()
            end)
            return true
        end
        OTLGM:DeclineAltLink184(alt184)
        OTLGM:RefreshCharacterIdentityManager184()
        return true
    end
    if action184 == "UNLINK" then
        local counterpart184 = row184.otlCounterpart184 or row184.otlAlt184
        if OTLGM.ShowConfirm then
            OTLGM:ShowConfirm("Remove character link?", "Remove the confirmed Main/Alt link with " .. tostring(counterpart184) .. "? Both characters will stop showing this relationship after the change is shared.", "Unlink", function()
                local ok184, message184 = OTLGM:UnlinkCharacterIdentity184(row184.otlAlt184)
                if not ok184 and message184 and OTLGM.ShowToast then OTLGM:ShowToast(message184, "error", 6) end
                OTLGM:RefreshCharacterIdentityManager184()
            end)
            return true
        end
        local ok184, message184 = OTLGM:UnlinkCharacterIdentity184(row184.otlAlt184)
        if not ok184 and message184 and OTLGM.ShowToast then OTLGM:ShowToast(message184, "error", 6) end
        OTLGM:RefreshCharacterIdentityManager184()
        return ok184
    end
    if action184 == "CANCEL" then
        local counterpart184 = row184.otlCounterpart184 or "this main"
        if OTLGM.ShowConfirm then
            OTLGM:ShowConfirm("Cancel Main request?", "Cancel the pending Main/Alt request to " .. tostring(counterpart184) .. "? You can request it again later.", "Cancel request", function()
                local ok184, message184 = OTLGM:UnlinkCharacterIdentity184(row184.otlAlt184)
                if not ok184 and message184 and OTLGM.ShowToast then OTLGM:ShowToast(message184, "error", 6) end
                OTLGM:RefreshCharacterIdentityManager184()
            end)
            return true
        end
        local ok184, message184 = OTLGM:UnlinkCharacterIdentity184(row184.otlAlt184)
        if not ok184 and message184 and OTLGM.ShowToast then OTLGM:ShowToast(message184, "error", 6) end
        OTLGM:RefreshCharacterIdentityManager184()
        return ok184
    end
    return false
end

function OTLGM:BuildCharacterIdentityManager184()
    self.ui = self.ui or {}
    if self.ui.characterIdentityManager184 then return self.ui.characterIdentityManager184 end
    if not self.ui.modalHost then return nil end
    local modal = UI:Modal(self.ui.modalHost, 590, 535)
    modal:SetPoint("CENTER", self.ui.modalHost, "CENTER", 0, 0)
    modal.otlDiagnosticName180 = "Character Identity"
    modal.title = UI.Text(modal, "My Characters", "GameFontNormalLarge", "LEFT")
    modal.title:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -18) modal.title:SetWidth(520)
    modal.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    modal.help = UI.Text(modal, "Link your alts to one main. Links are voluntary, nothing is detected automatically, and you can remove them at any time.", "GameFontNormalSmall", "LEFT")
    modal.help:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -50) modal.help:SetWidth(550) modal.help:SetHeight(44) modal.help:SetJustifyV("TOP")
    modal.help:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.currentTitle = UI.Text(modal, "CURRENT CHARACTER", "GameFontNormalSmall", "LEFT")
    modal.currentTitle:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -100) modal.currentTitle:SetWidth(260)
    modal.currentTitle:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    modal.status = UI.Text(modal, "", "GameFontNormal", "LEFT")
    modal.status:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -120) modal.status:SetWidth(550) modal.status:SetHeight(40) modal.status:SetJustifyV("TOP")
    modal.rule = modal:CreateTexture(nil, "ARTWORK")
    modal.rule:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -160)
    modal.rule:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -20, -160)
    modal.rule:SetHeight(1)
    modal.rule:SetTexture(C.goldDark[1], C.goldDark[2], C.goldDark[3], 0.40)
    modal.mainLabel = UI.Text(modal, "LINK THIS CHARACTER AS AN ALT", "GameFontNormalSmall", "LEFT")
    modal.mainLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -178) modal.mainLabel:SetWidth(250)
    modal.mainLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    modal.mainEdit = UI:EditBox(modal, 310, 30, { maxLetters = 12 })
    modal.mainEdit:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -202)
    modal.request = UI:Button(modal, "Request Link", 118, 30, function()
        local target = modal.otlBrowseRequestTarget184 or (modal.mainEdit:GetText() or "")
        local ok, message = OTLGM:RequestMainLink184(target)
        if not ok and message and OTLGM.ShowToast then OTLGM:ShowToast(message, "error", 6) end
        if ok and modal.otlBrowseRequestTarget184 then modal.otlSubject184 = PlayerName184() end
        OTLGM:RefreshCharacterIdentityManager184()
    end, "primary")
    modal.request:SetPoint("LEFT", modal.mainEdit, "RIGHT", 10, 0)
    modal.compat = UI.Text(modal, "Tip: you can also open a guild member's profile, choose Main / Alt, and select Set as My Main. The main still has to confirm.", "GameFontNormalSmall", "LEFT")
    modal.compat:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -240) modal.compat:SetWidth(550) modal.compat:SetHeight(36) modal.compat:SetJustifyV("TOP")
    modal.compat:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.linksTitle = UI.Text(modal, "ALT REQUESTS & LINKED CHARACTERS", "GameFontNormalSmall", "LEFT")
    modal.linksTitle:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -286) modal.linksTitle:SetWidth(360)
    modal.linksTitle:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    modal.empty = UI.Text(modal, "No requests or linked characters.", "GameFontNormalSmall", "LEFT")
    modal.empty:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -312) modal.empty:SetWidth(520)
    modal.empty:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.rows = {}
    local index
    for index = 1, MAX_ALTS_PER_MAIN_184 do
        local row = CreateFrame("Frame", nil, modal)
        row:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -304 - ((index - 1) * 29))
        row:SetWidth(550) row:SetHeight(27)
        row.text = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.text:SetPoint("LEFT", row, "LEFT", 0, 0) row.text:SetWidth(305)
        row.primary = UI:Button(row, "Open", 92, 24, function(button)
            local parent = button:GetParent()
            if parent then RunIdentityRowAction184(modal, parent, button.otlIdentityAction184) end
        end, "secondary")
        row.primary:SetPoint("RIGHT", row, "RIGHT", -104, 0)
        row.secondary = UI:Button(row, "Remove", 92, 24, function(button)
            local parent = button:GetParent()
            if parent then RunIdentityRowAction184(modal, parent, button.otlIdentityAction184) end
        end, "danger")
        row.secondary:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        row:Hide()
        modal.rows[index] = row
    end
    modal.close = UI:Button(modal, "Close", 96, 30, function() OTLGM:CloseModal180(modal, "identity-close") end, "secondary")
    modal.close:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -20, 16)
    self.ui.characterIdentityManager184 = modal
    return modal
end

local function PositionIdentityRows184(modal, top184)
    local index
    for index = 1, table.getn(modal.rows or {}) do
        local row = modal.rows[index]
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -(top184 + ((index - 1) * 29)))
    end
end

function OTLGM:RefreshCharacterIdentityManager184()
    local modal = self.ui and self.ui.characterIdentityManager184
    if not modal then return false end
    local player = PlayerName184()
    local subject = CanonicalName184(self, modal.otlSubject184 or player)
    local selfMode184 = Normalize184(self, subject) == Normalize184(self, player)
    modal.otlBrowseRequestTarget184 = nil

    local function ResetRow184(row184)
        row184.otlAlt184 = nil
        row184.otlCounterpart184 = nil
        row184.otlTarget184 = nil
        row184.otlPrimaryAction184 = nil
        row184.otlSecondaryAction184 = nil
        row184.primary.otlIdentityAction184 = nil
        row184.secondary.otlIdentityAction184 = nil
        row184:Hide()
    end

    if not selfMode184 then
        local member184 = self.GetMember and self:GetMember(subject) or nil
        local view184 = member184 and self:GetCharacterIdentityView184(subject) or nil
        modal:SetHeight(405)
        modal.title:SetText("Related Characters - " .. tostring(subject))
        modal.help:SetText("Browse Main/Alt links for this guild member. Verified links are shared by both characters; nothing is guessed automatically.")
        modal.currentTitle:SetText("IDENTITY")
        modal.currentTitle:Show()
        modal.mainLabel:Hide() modal.mainEdit:Hide() modal.compat:Hide()
        modal.rule:ClearAllPoints()
        modal.rule:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -160)
        modal.rule:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -20, -160)

        local related184 = {}
        if not member184 then
            modal.status:SetText(self.colors.red .. "This character is no longer in the current guild roster." .. self.colors.reset)
        elseif view184 and view184.role == "ALT" and view184.main then
            local verifiedText184 = view184.verified and (self.colors.green .. "Verified by both characters" .. self.colors.reset)
                or (self.colors.grey .. "Confirmed here; waiting for the other character" .. self.colors.reset)
            modal.status:SetText(self.colors.blue .. "Alt" .. self.colors.reset .. " of " .. self.colors.gold .. tostring(view184.main) .. self.colors.reset .. "  -  " .. verifiedText184)
            table.insert(related184, { name = view184.main, label = "Main" })
        elseif view184 and view184.role == "MAIN" then
            local alts184 = view184.alts or {}
            local verifiedText184 = view184.verified and (self.colors.green .. "Verified by both characters" .. self.colors.reset)
                or (self.colors.grey .. "Confirmed here; waiting for the other character" .. self.colors.reset)
            modal.status:SetText(self.colors.gold .. "Main character" .. self.colors.reset .. "  -  " .. tostring(table.getn(alts184)) .. " linked alt(s)  -  " .. verifiedText184)
            local i184
            for i184 = 1, table.getn(alts184) do table.insert(related184, { name = alts184[i184], label = "Alt" }) end
        else
            modal.status:SetText("No verified Main/Alt relationship is currently shared for " .. tostring(subject) .. ".")
        end

        local canRequest184, requestReason184 = self:CanRequestMainLink184(subject)
        local requestShown184 = member184 and canRequest184 and true or false
        if requestShown184 then
            modal.request:ClearAllPoints() modal.request:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -178)
            modal.request:SetWidth(150)
            if modal.request.text then modal.request.text:SetWidth(140) end
            modal.request.otlStyle = "primary"
            UI:SetText(modal.request, "Set as My Main")
            modal.request.otlTooltipTitle = "Set as my main"
            modal.request.otlTooltip = "Send a voluntary Main/Alt request from your current character to " .. tostring(subject) .. ". This character must still confirm the request."
            modal.otlBrowseRequestTarget184 = subject
            UI:SetEnabled(modal.request, true)
            UI:SetSelected(modal.request, false)
            modal.request:Show()
        else
            modal.request.otlTooltipTitle = "Main / Alt link"
            modal.request.otlTooltip = requestReason184 or "This character cannot be selected as your main right now."
            modal.request:Hide()
        end

        local linksY184 = requestShown184 and 224 or 184
        modal.linksTitle:ClearAllPoints() modal.linksTitle:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -linksY184)
        modal.linksTitle:SetText("RELATED CHARACTERS")
        local rowsTop184 = linksY184 + 28
        modal.empty:ClearAllPoints() modal.empty:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -rowsTop184)
        PositionIdentityRows184(modal, rowsTop184 - 6)

        if table.getn(related184) == 0 then
            modal.empty:SetText("No linked guild characters to open from this profile.")
            modal.empty:Show()
        else modal.empty:Hide() end
        local index184
        for index184 = 1, table.getn(modal.rows) do
            local row184, relation184 = modal.rows[index184], related184[index184]
            if relation184 then
                row184.otlTarget184 = relation184.name
                row184.otlCounterpart184 = relation184.name
                local inGuild184 = IsGuildMember184(self, relation184.name)
                row184.text:SetText(tostring(relation184.label) .. ": " .. tostring(relation184.name)
                    .. (inGuild184 and "" or ("  " .. self.colors.grey .. "Not in guild" .. self.colors.reset)))
                row184.primary:ClearAllPoints() row184.primary:SetPoint("RIGHT", row184, "RIGHT", 0, 0)
                SetIdentityActionButton184(row184.primary, "Open Profile", "secondary", "OPEN", inGuild184, "The linked character is not currently in the guild roster.")
                SetIdentityActionButton184(row184.secondary, "", "danger", nil, true)
                row184:Show()
            else ResetRow184(row184) end
        end
        local relationRows184 = math.max(1, table.getn(related184))
        local desiredHeight184 = (requestShown184 and 320 or 280) + (relationRows184 * 29)
        modal:SetHeight(math.max(365, math.min(500, desiredHeight184)))
        return true
    end

    modal:SetWidth(590)
    modal.title:SetText("My Characters")
    modal.help:SetText("Link your alts to one main. Links are voluntary, nothing is detected automatically, and you can remove them at any time.")
    modal.currentTitle:SetText("CURRENT CHARACTER")
    modal.currentTitle:Show()
    modal.rule:ClearAllPoints()
    modal.rule:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -160)
    modal.rule:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -20, -160)
    modal.request.otlStyle = "primary"
    modal.request:SetWidth(118)
    if modal.request.text then modal.request.text:SetWidth(108) end
    UI:SetText(modal.request, "Request Main")
    modal.request.otlTooltipTitle = "Request Main/Alt link"
    modal.request.otlTooltip = "Enter the exact guild character name, or open that member's profile and use Main / Alt > Set as My Main."

    local view = self:GetCharacterIdentityView184(player)
    local asAlt, asMain = self:GetCharacterIdentityRelations184(player, true)
    local relationCount184 = table.getn(asMain or {})
    local canRequest = not asAlt and relationCount184 == 0

    if asAlt then
        local stateText = asAlt.state == "CONFIRMED" and (self.colors.green .. "Confirmed" .. self.colors.reset) or (self.colors.orange .. "Waiting for main confirmation" .. self.colors.reset)
        if relationCount184 > 0 then
            modal.status:SetText(self.colors.red .. "Identity conflict detected." .. self.colors.reset .. " Remove this character's Alt link first, then review its Main-side links.")
        else
            modal.status:SetText(self.colors.blue .. "Alt" .. self.colors.reset .. " of " .. self.colors.gold .. tostring(asAlt.main) .. self.colors.reset .. "  -  " .. stateText)
        end
    elseif relationCount184 > 0 then
        local pending, confirmed = 0, 0
        local index
        for index = 1, relationCount184 do if asMain[index].state == "CONFIRMED" then confirmed = confirmed + 1 else pending = pending + 1 end end
        modal.status:SetText(self.colors.gold .. "Main character" .. self.colors.reset .. "  -  " .. self.colors.green .. tostring(confirmed) .. " linked" .. self.colors.reset
            .. (pending > 0 and ("  -  " .. self.colors.orange .. tostring(pending) .. " waiting" .. self.colors.reset) or ""))
    else
        modal.status:SetText("This character is not linked yet. You can keep it standalone, or link it as an alt to one guild main.")
    end

    local rows = {}
    if asAlt then
        table.insert(rows, { alt = asAlt.alt, main = asAlt.main, state = asAlt.state, selfAlt = true })
    else
        local index
        for index = 1, relationCount184 do table.insert(rows, asMain[index]) end
        table.sort(rows, function(left184, right184)
            if left184.state ~= right184.state then return left184.state == "PENDING" end
            return string.lower(tostring(left184.alt or "")) < string.lower(tostring(right184.alt or ""))
        end)
    end

    if canRequest then
        modal:SetHeight(390)
        modal.mainLabel:Show() modal.mainEdit:Show() modal.compat:Show() modal.request:Show()
        modal.mainLabel:ClearAllPoints() modal.mainLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -178)
        modal.mainEdit:ClearAllPoints() modal.mainEdit:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -202)
        modal.request:ClearAllPoints() modal.request:SetPoint("LEFT", modal.mainEdit, "RIGHT", 10, 0)
        modal.compat:ClearAllPoints() modal.compat:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -240)
        modal.linksTitle:Hide()
        modal.empty:ClearAllPoints() modal.empty:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -292)
        modal.empty:SetText("No linked characters. Nothing changes until you send a request and the main confirms it.")
        modal.empty:Show()
        UI:SetEnabled(modal.request, true)
        if modal.mainEdit.Enable then modal.mainEdit:Enable() end
        local index184
        for index184 = 1, table.getn(modal.rows) do ResetRow184(modal.rows[index184]) end
        return true
    end

    modal.mainLabel:Hide() modal.mainEdit:Hide() modal.compat:Hide() modal.request:Hide()
    if asAlt then modal.linksTitle:SetText("CURRENT LINK")
    else modal.linksTitle:SetText("ALT REQUESTS & LINKED CHARACTERS") end
    modal.linksTitle:ClearAllPoints() modal.linksTitle:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -184)
    modal.linksTitle:Show()
    modal.empty:ClearAllPoints() modal.empty:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -212)
    PositionIdentityRows184(modal, 206)
    if table.getn(rows) == 0 then
        modal.empty:SetText("No requests or linked characters.")
        modal.empty:Show()
    else modal.empty:Hide() end

    local index
    for index = 1, table.getn(modal.rows) do
        local row, relation = modal.rows[index], rows[index]
        if relation then
            row.otlAlt184 = relation.alt
            if relation.selfAlt then
                row.otlCounterpart184 = relation.main
                row.otlTarget184 = relation.main
                local mainInGuild184 = IsGuildMember184(self, relation.main)
                row.text:SetText("Main: " .. tostring(relation.main) .. "  -  " .. (relation.state == "CONFIRMED"
                    and self.colors.green .. "Confirmed" .. self.colors.reset
                    or self.colors.orange .. "Waiting for confirmation" .. self.colors.reset))
                row.primary:ClearAllPoints() row.primary:SetPoint("RIGHT", row, "RIGHT", -104, 0)
                SetIdentityActionButton184(row.primary, "Open Main", "secondary", "OPEN", mainInGuild184, "The main is not currently in the guild roster.")
                SetIdentityActionButton184(row.secondary, relation.state == "CONFIRMED" and "Unlink" or "Cancel", "danger",
                    relation.state == "CONFIRMED" and "UNLINK" or "CANCEL", true)
            else
                row.otlCounterpart184 = relation.alt
                row.otlTarget184 = relation.alt
                local altInGuild = IsGuildMember184(self, relation.alt)
                row.text:SetText(tostring(relation.alt) .. "  -  " .. (not altInGuild and (self.colors.grey .. "Not in guild" .. self.colors.reset)
                    or relation.state == "CONFIRMED" and self.colors.green .. "Linked alt" .. self.colors.reset
                    or self.colors.orange .. "Waiting for your confirmation" .. self.colors.reset))
                row.primary:ClearAllPoints() row.primary:SetPoint("RIGHT", row, "RIGHT", -104, 0)
                if relation.state == "PENDING" then
                    SetIdentityActionButton184(row.primary, "Confirm", "primary", "CONFIRM", altInGuild, "The alt must be in the current guild before confirmation.")
                    SetIdentityActionButton184(row.secondary, "Decline", "danger", "DECLINE", true)
                else
                    SetIdentityActionButton184(row.primary, "Open Alt", "secondary", "OPEN", altInGuild, "The alt is not currently in the guild roster.")
                    SetIdentityActionButton184(row.secondary, "Unlink", "danger", "UNLINK", true)
                end
            end
            row:Show()
        else ResetRow184(row) end
    end
    local visibleRows184 = math.max(1, table.getn(rows))
    modal:SetHeight(math.max(330, math.min(495, 275 + (visibleRows184 * 29))))
    return true
end

function OTLGM:OpenCharacterIdentityManager184(subjectName184)
    if not self.ui or not self.ui.main then self:BuildUI() end
    local modal = self:BuildCharacterIdentityManager184()
    if not modal then return false end
    modal.otlSubject184 = CanonicalName184(self, subjectName184 or PlayerName184())
    modal.mainEdit.otlSilent = true modal.mainEdit:SetText("") modal.mainEdit.otlSilent = nil
    self:RefreshCharacterIdentityManager184()
    self:ShowShellModal(modal)
    return true
end

function OTLGM:OpenCharacterIdentityForMember184(name)
    return self:OpenCharacterIdentityManager184(name)
end

function OTLGM:RefreshCharacterIdentityHomeIndicator184()
    local button184 = self.ui and self.ui.homeMyProfile183 or nil
    if not button184 then return false end
    local pending184 = self:GetPendingCharacterIdentityCount184(PlayerName184())
    UI:SetText(button184, pending184 > 0 and ("My Profile (" .. tostring(pending184) .. ")") or "My Profile")
    button184.otlTooltipTitle = pending184 > 0 and "My Guild Profile - action needed" or "My Guild Profile"
    button184.otlTooltip = pending184 > 0
        and (tostring(pending184) .. " Main/Alt request(s) are waiting for your confirmation. Open My Profile, then Characters > Manage.")
        or "Open your member profile beside Roster. This is the quickest way to see your guild journey, achievements, professions, recent activity and voluntary Main/Alt links."
    if button184.icon184 and button184.icon184.SetVertexColor then
        if pending184 > 0 then button184.icon184:SetVertexColor(C.orange[1], C.orange[2], C.orange[3])
        else button184.icon184:SetVertexColor(1, 1, 1) end
    end
    return true
end

function OTLGM:GetCharacterIdentitySupportSummary184()
    local state = self:EnsureCharacterIdentityDB184()
    if not state then return "Character Identity: unavailable" end
    local pending, confirmed = 0, 0
    local _, relation
    for _, relation in pairs(state.relations or {}) do
        if relation and relation.state == "PENDING" then pending = pending + 1
        elseif relation and relation.state == "CONFIRMED" then confirmed = confirmed + 1 end
    end
    local verified = 0
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local name
    for name in pairs(db and db.roster or {}) do if self:GetVerifiedCharacterIdentity184(name) then verified = verified + 1 end end
    return "Character Identity: local confirmed/pending " .. tostring(confirmed) .. "/" .. tostring(pending)
        .. " / verified profiles " .. tostring(verified)
        .. " / control sent-received " .. tostring(state.metrics and state.metrics.controlSent or 0) .. "/" .. tostring(state.metrics and state.metrics.controlReceived or 0)
        .. " / profile claims " .. tostring(state.metrics and state.metrics.profileClaimsReceived or 0)
        .. " / conflicts " .. tostring(state.metrics and state.metrics.conflicts or 0)
end

local PreviousProfileSupportIdentity184 = OTLGM.GetGuildProfileSupportSummary183
if PreviousProfileSupportIdentity184 then
    function OTLGM:GetGuildProfileSupportSummary183()
        return tostring(PreviousProfileSupportIdentity184(self) or "") .. "\n" .. tostring(self:GetCharacterIdentitySupportSummary184())
    end
end

local PreviousRefreshHomeIdentityR35 = OTLGM.RefreshHomePage
if PreviousRefreshHomeIdentityR35 then
    function OTLGM:RefreshHomePage()
        local result184 = PreviousRefreshHomeIdentityR35(self)
        self:RefreshCharacterIdentityHomeIndicator184()
        return result184
    end
end

if OTLGM.RegisterFeatureCapabilityR32 then
    OTLGM:RegisterFeatureCapabilityR32("CHARACTER_IDENTITY", "Main/Alt identity", MIN_IDENTITY_VERSION_184,
        "Links are voluntary and require confirmation by the selected main. Other guild members only see a relationship after matching identity has been shared by both characters.")
end

OTLGM:RegisterModule("CharacterIdentity184", {
    stage = "F",
    revision = 2,
    minimumPeer = MIN_IDENTITY_VERSION_184,
    maxAltsPerMain = MAX_ALTS_PER_MAIN_184,
    senderBound = true,
    reciprocalVerification = true,
    accountHeuristics = false,
    pendingPublished = false,
    noOnUpdate = true,
    noEventFrame = true,
    noPolling = true,
    noRosterRequest = true,
    noProfessionScan = true,
})
