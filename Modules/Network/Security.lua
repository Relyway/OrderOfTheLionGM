-- Inbound protocol gate. Claimed authors/ranks are never treated as authority;
-- every packet is tied to the actual CHAT_MSG_ADDON sender first.

local RATE_WINDOW = tonumber(OTLGM.networkRateWindow180) or 10
local RATE_MAXIMUM = tonumber(OTLGM.networkInboundMaximum180) or 90
local AUTHORITY_QUARANTINE_TTL_RC5 = 10
local AUTHORITY_QUARANTINE_LIMIT_RC5 = 24
local AUTHORITY_TRACK_LIMIT_R14 = 64
local AUTHORITY_VALIDATION_TTL_R14 = 60
local TARGET_ENVELOPE = "T1^"
local CRAFT_TRANSFER_WINDOW = 120

local function Reject(self, reason, sender, detail)
    self.runtime = self.runtime or {}
    self.runtime.metrics = self.runtime.metrics or {}
    self.runtime.metrics.network = self.runtime.metrics.network or { queued = 0, sent = 0, retried = 0, dropped = 0, rejected = 0 }
    local metrics = self.runtime.metrics.network
    metrics.rejected = (metrics.rejected or 0) + 1
    metrics.lastRejectReason = reason
    metrics.lastRejectSender = sender
    metrics.rejectReasons180 = metrics.rejectReasons180 or {}
    metrics.rejectReasons180[tostring(reason or "unknown")] = (tonumber(metrics.rejectReasons180[tostring(reason or "unknown")]) or 0) + 1
    self.runtime.networkRejectLog180 = self.runtime.networkRejectLog180 or {}
    detail = type(detail) == "table" and detail or {}
    local now = self.Now and self:Now() or (time and time() or 0)
    local signature = tostring(reason or "unknown") .. "|" .. tostring(sender or "unknown") .. "|" .. tostring(detail.subtype or "")
    local latest = self.runtime.networkRejectLog180[1]
    if latest and latest.signature180 == signature and now - (tonumber(latest.ts) or 0) <= 15 then
        latest.ts = now
        latest.count = (tonumber(latest.count) or 1) + 1
    else
        table.insert(self.runtime.networkRejectLog180, 1, {
            ts = now, reason = tostring(reason or "unknown"), sender = tostring(sender or "unknown"),
            protocol = tostring(detail.protocol or ""), subtype = tostring(detail.subtype or ""),
            channel = tostring(detail.channel or ""), owner = tostring(detail.owner or ""),
            professionKey = tostring(detail.professionKey or ""), signature180 = signature, count = 1,
        })
    end
    while table.getn(self.runtime.networkRejectLog180) > 20 do table.remove(self.runtime.networkRejectLog180) end
    return false
end

function OTLGM.__impl180.RefreshSenderRosterCache__impl1(self, force)
    self.runtime = self.runtime or {}
    local cache = self.runtime.senderRoster
    local now = self:Now()
    if cache and not force and now - (cache.builtAt or 0) < 30 then return cache end

    local db = self:GetGuildDB()
    local lookup = self.runtime.rosterMemberLookup180
    if not lookup or lookup.roster ~= (db and db.roster) or lookup.lastScan ~= (db and db.lastScan)
        or type(lookup.byKey) ~= "table" then
        if not force then
            -- Never allocate/normalize an 800+ member allow-list from the packet
            -- receive path. The bounded roster reader will publish it atomically.
            -- Until then, fail closed for other senders; the player itself remains
            -- known and authority validation can request fresh roster data.
            self.runtime.senderRosterDeferredR26 = (tonumber(self.runtime.senderRosterDeferredR26) or 0) + 1
            cache = { builtAt = now, members = {} }
            local player = UnitName and UnitName("player") or ""
            if player ~= "" then cache.selfKey = self:NormalizeName(player) end
            self.runtime.senderRoster = cache
            return cache
        end
        -- Explicit fallback only (unusual direct Scan/load ordering). Normal
        -- sliced commits should make this counter stay at zero in live tests.
        local started = self.BeginPerformanceSample180 and self:BeginPerformanceSample180() or nil
        lookup = { roster = db and db.roster, lastScan = db and db.lastScan, byKey = {} }
        local name, member, key
        for name, member in pairs(db and db.roster or {}) do
            key = self:NormalizeName(name)
            if key ~= "" then lookup.byKey[key] = member end
            key = self:NormalizeName(member and member.name)
            if key ~= "" then lookup.byKey[key] = member end
        end
        self.runtime.rosterMemberLookup180 = lookup
        self.runtime.senderRosterFallbackBuildsR26 = (tonumber(self.runtime.senderRosterFallbackBuildsR26) or 0) + 1
        if started and self.EndPerformanceSample180 then self:EndPerformanceSample180("sender roster fallback rebuild", started) end
    end

    cache = { builtAt = now, members = lookup.byKey }
    local player = UnitName and UnitName("player") or ""
    if player ~= "" then cache.selfKey = self:NormalizeName(player) end

    -- The committed roster database is the only sender allow-list. Never walk
    -- 780+ live guild rows from the packet receive path; login/stale-on-open
    -- scans populate this cache asynchronously through the bounded roster reader.
    -- Security and GetMember share the same normalized index, so a cache refresh
    -- does not allocate and normalize a second copy of a 700+ member roster.
    self.runtime.senderRoster = cache
    return cache
end

local function PruneAuthorityTrackingR14(self, now)
    self.runtime = self.runtime or {}
    local validation = self.runtime.authorityValidationRC4
    local pending = self.runtime.authorityPendingRC5
    local rows = {}
    local key, value
    if type(validation) == "table" then
        for key, value in pairs(validation) do
            local stamp = tonumber(value) or 0
            if stamp <= 0 or now - stamp > AUTHORITY_VALIDATION_TTL_R14 then
                validation[key] = nil
            else
                table.insert(rows, { key = key, stamp = stamp })
            end
        end
        if table.getn(rows) > AUTHORITY_TRACK_LIMIT_R14 then
            table.sort(rows, function(left, right) return left.stamp < right.stamp end)
            local index
            for index = 1, table.getn(rows) - AUTHORITY_TRACK_LIMIT_R14 do validation[rows[index].key] = nil end
        end
    end
    rows = {}
    if type(pending) == "table" then
        for key, value in pairs(pending) do
            local expires = tonumber(value) or 0
            if expires <= now then
                pending[key] = nil
            else
                table.insert(rows, { key = key, expires = expires })
            end
        end
        if table.getn(rows) > AUTHORITY_TRACK_LIMIT_R14 then
            table.sort(rows, function(left, right) return left.expires < right.expires end)
            local index
            for index = 1, table.getn(rows) - AUTHORITY_TRACK_LIMIT_R14 do pending[rows[index].key] = nil end
        end
    end
end

local function RequestAuthorityValidationRC4(self, sender, reason)
    self.runtime = self.runtime or {}
    local now = self:Now()
    local key = self:NormalizeName(sender or "")
    self.runtime.authorityValidationRC4 = self.runtime.authorityValidationRC4 or {}
    self.runtime.authorityPendingRC5 = self.runtime.authorityPendingRC5 or {}
    PruneAuthorityTrackingR14(self, now)
    local last = tonumber(self.runtime.authorityValidationRC4[key]) or 0
    if now - last < 15 then return false end
    self.runtime.authorityValidationRC4[key] = now
    self.runtime.authorityPendingRC5[key] = now + AUTHORITY_QUARANTINE_TTL_RC5
    PruneAuthorityTrackingR14(self, now)
    self.runtime.authorityValidationRequestsRC4 = (tonumber(self.runtime.authorityValidationRequestsRC4) or 0) + 1
    -- One bounded roster read validates all waiting senders. Do not start a
    -- fresh 788-member scan for every newly heard peer in a busy guild.
    local globalLast = tonumber(self.runtime.lastAuthorityRosterRequestR2) or 0
    if self.RequestScan and not self.pendingScan and not self.runtime.rosterRead180 and now - globalLast >= 45 then
        self.runtime.lastAuthorityRosterRequestR2 = now
        self:RequestScan("AUTHORITY:" .. tostring(reason or "sender"))
    end
    return true
end

function OTLGM:IsKnownGuildSender(sender)
    if not sender or sender == "" or not GetGuildInfo or not GetGuildInfo("player") then return false end
    local cache = self:RefreshSenderRosterCache(false)
    local key = self:NormalizeName(sender)
    local known = key == cache.selfKey or cache.members[key] ~= nil
    if not known then RequestAuthorityValidationRC4(self, sender, "unknown") end
    return known
end

function OTLGM:IsLeadershipSender(sender)
    if not sender or sender == "" or not GetGuildInfo or not GetGuildInfo("player") then return false end
    self.runtime = self.runtime or {}
    local cache = self:RefreshSenderRosterCache(false)
    local member = cache.members[self:NormalizeName(sender)]
    local db = self:GetGuildDB()
    local age = self:Now() - (tonumber(db and db.lastScan) or 0)
    if not member or age > 120 or self.runtime.rosterDataDirty180 or self.pendingScan or self.runtime.rosterRead180 then
        RequestAuthorityValidationRC4(self, sender, "leadership")
        return false
    end
    local key = self:NormalizeName(sender or "")
    if self.runtime.authorityPendingRC5 then self.runtime.authorityPendingRC5[key] = nil end
    return self:IsLeadership(member) and true or false
end

function OTLGM:CheckInboundRate(sender)
    self.runtime = self.runtime or {}
    self.runtime.receivedRate = self.runtime.receivedRate or {}
    local key = self:NormalizeName(sender)
    local now = self:Now()
    local entry = self.runtime.receivedRate[key]
    if not entry or now - (entry.started or 0) >= RATE_WINDOW then
        entry = { started = now, count = 0 }
        self.runtime.receivedRate[key] = entry
    end
    entry.count = entry.count + 1
    return entry.count <= RATE_MAXIMUM
end


local authorityKindsRC5 = {
    A3 = { DEL=true, META=true, BODY=true },
    B1 = { GOAL=true, DEL=true, END=true, CONTRIB=true, DONOR=true },
    P1 = { RAID=true, RDMETA=true, NOTICE=true, RAIDDEL=true, RTEAM1=true, RTMEM1=true, RTDEL1=true, RMETA1=true, RRMEM1=true, RRDEL1=true },
    M1 = {
        RACK=true, RSTATUS=true, RREPLY=true, WARNING=true, WCLEAR=true,
        MSUM=true, MREQ=true, MIDX=true, MWARN=true, MWTEXT=true,
        MCASE=true, MCTEXT=true, MACK=true,
    },
}

local function AuthorityPayloadKindRC5(self, message, channel)
    local payload = tostring(message or "")
    local logicalChannel = channel
    if logicalChannel == "GUILD" and string.sub(payload, 1, string.len(TARGET_ENVELOPE)) == TARGET_ENVELOPE then
        local separator = string.find(payload, "^", string.len(TARGET_ENVELOPE) + 1, true)
        if not separator then return nil end
        local target = string.sub(payload, string.len(TARGET_ENVELOPE) + 1, separator - 1)
        if self:NormalizeName(target) ~= self:NormalizeName(UnitName("player") or "") then return nil end
        payload = string.sub(payload, separator + 1)
        logicalChannel = "WHISPER"
    end
    local fields = self:Split(payload, "^")
    local protocol, kind = fields[1] or "", fields[2] or ""
    return authorityKindsRC5[protocol] and authorityKindsRC5[protocol][kind] and true or false, protocol, kind, logicalChannel
end

function OTLGM:IsAuthorityValidationPendingRC5(sender)
    self.runtime = self.runtime or {}
    PruneAuthorityTrackingR14(self, self:Now())
    local key = self:NormalizeName(sender or "")
    local expires = self.runtime.authorityPendingRC5 and tonumber(self.runtime.authorityPendingRC5[key]) or 0
    if expires <= self:Now() then
        if self.runtime.authorityPendingRC5 then self.runtime.authorityPendingRC5[key] = nil end
        return false
    end
    return true
end

function OTLGM:QueueAuthorityPacketRC5(prefix, message, channel, sender, rateCounted)
    if not self:IsAuthorityValidationPendingRC5(sender) then return false end
    local sensitive = AuthorityPayloadKindRC5(self, message, channel)
    if not sensitive then return false end
    self.runtime = self.runtime or {}
    self.runtime.authorityQuarantineRC5 = self.runtime.authorityQuarantineRC5 or {}
    local queue = self.runtime.authorityQuarantineRC5
    local key = self:NormalizeName(sender or "") .. "|" .. tostring(channel or "") .. "|" .. tostring(message or "")
    local index, packet
    for index = 1, table.getn(queue) do
        packet = queue[index]
        if type(packet) == "table" and packet.key == key then
            packet.expires = self:Now() + AUTHORITY_QUARANTINE_TTL_RC5
            return true
        end
    end
    table.insert(queue, {
        key = key, prefix = prefix, message = message, channel = channel, sender = sender,
        rateCounted = rateCounted and true or false,
        queuedAt = self:Now(), expires = self:Now() + AUTHORITY_QUARANTINE_TTL_RC5,
    })
    while table.getn(queue) > AUTHORITY_QUARANTINE_LIMIT_RC5 do table.remove(queue, 1) end
    local metrics = self.runtime.metrics and self.runtime.metrics.network
    if metrics then metrics.authorityDeferredRC5 = (tonumber(metrics.authorityDeferredRC5) or 0) + 1 end
    return true
end

function OTLGM:ReplayAuthorityPacketsRC5()
    self.runtime = self.runtime or {}
    local queue = self.runtime.authorityQuarantineRC5
    if type(queue) ~= "table" or table.getn(queue) == 0 then return 0 end
    self.runtime.authorityQuarantineRC5 = {}
    local replayed = 0
    local index, packet
    self.runtime.authorityReplayRC5 = true
    for index = 1, table.getn(queue) do
        packet = queue[index]
        if type(packet) == "table" and (tonumber(packet.expires) or 0) >= self:Now() then
            self.runtime.authorityReplaySkipRateRC5 = packet.rateCounted and true or nil
            if self:HandleAddonMessage(packet.prefix, packet.message, packet.channel, packet.sender) then replayed = replayed + 1 end
            self.runtime.authorityReplaySkipRateRC5 = nil
        end
    end
    self.runtime.authorityReplaySkipRateRC5 = nil
    self.runtime.authorityReplayRC5 = nil
    local metrics = self.runtime.metrics and self.runtime.metrics.network
    if metrics then metrics.authorityReplayedRC5 = (tonumber(metrics.authorityReplayedRC5) or 0) + replayed end
    return replayed
end

function OTLGM:InvalidateSenderRosterCache180()
    self.runtime = self.runtime or {}
    self.runtime.senderRoster = nil
end

function OTLGM:RegisterExpectedCraftingTransfer180(sender, owner, professionKey, hash, ttl)
    self.runtime = self.runtime or {}
    self.runtime.expectedCraftingTransfers180 = self.runtime.expectedCraftingTransfers180 or {}
    local key = self:NormalizeName(sender or "") .. ":" .. self:NormalizeName(owner or "") .. ":" .. tostring(professionKey or "")
    if key == "::" then return false end
    self.runtime.expectedCraftingTransfers180[key] = {
        sender = sender, owner = owner, professionKey = professionKey, hash = hash,
        createdAt = self:Now(), expiresAt = self:Now() + math.max(30, math.min(240, tonumber(ttl) or 120)),
    }
    local count, storedKey, entry, oldestKey, oldestAt = 0, nil, nil, nil, nil
    for storedKey, entry in pairs(self.runtime.expectedCraftingTransfers180) do
        if (tonumber(entry.expiresAt) or 0) < self:Now() then self.runtime.expectedCraftingTransfers180[storedKey] = nil
        else
            count = count + 1
            if not oldestAt or (tonumber(entry.createdAt) or 0) < oldestAt then oldestKey, oldestAt = storedKey, tonumber(entry.createdAt) or 0 end
        end
    end
    if count > 120 and oldestKey then self.runtime.expectedCraftingTransfers180[oldestKey] = nil end
    return true
end

function OTLGM:IsExpectedCraftingTransfer(sender, owner, professionKey, channel)
    if self:NormalizeName(sender) == self:NormalizeName(owner) then return true, "owner-direct" end
    if channel ~= "WHISPER" then return false, "wrong-channel" end
    self.runtime = self.runtime or {}
    local key = self:NormalizeName(sender or "") .. ":" .. self:NormalizeName(owner or "") .. ":" .. tostring(professionKey or "")
    local expected = self.runtime.expectedCraftingTransfers180 and self.runtime.expectedCraftingTransfers180[key]
    if expected then
        if self:Now() <= (tonumber(expected.expiresAt) or 0) then
            expected.lastProgress = self:Now()
            return true, "explicit-session"
        end
        self.runtime.expectedCraftingTransfers180[key] = nil
    end
    local craft = self:EnsureCraftingDB()
    local state = craft and craft.syncState
    if not state or not state.active then return false, expected and "expired-session" or "no-explicit-session" end
    if self:Now() - (state.started or 0) > CRAFT_TRANSFER_WINDOW then return false, "expired-sync-window" end
    local _, wanted
    for _, wanted in pairs(state.wanted157 or {}) do
        if wanted and self:NormalizeName(wanted.sender) == self:NormalizeName(sender)
            and self:NormalizeName(wanted.owner) == self:NormalizeName(owner)
            and tostring(wanted.professionKey or "") == tostring(professionKey or "") then return true, "active-wanted" end
    end
    if state.legacyFallback157 then return true, "legacy-fallback" end
    return false, "unsolicited-transfer"
end

local function IsRecentPveSync(self)
    local now = self:Now()
    local pending = self.pveSyncPending180
    if type(pending) == "table" and now - (tonumber(pending.startedAt) or 0) <= 30 then return true end
    local pve = self:EnsurePveDB()
    return pve and now - (tonumber(pve.lastSync) or 0) <= 30
end

local function IsRecentAnnouncementSync(self)
    local db = self:GetGuildDB()
    local requested = db and db.announcementSync and tonumber(db.announcementSync.requested) or 0
    return requested > 0 and self:Now() - requested <= 30
end

local function IsAssignedRaidInviteSender175(self, raidId, sender)
    if not self.GetRaidById156 then return false end
    local record = self:GetRaidById156(raidId)
    if not record then return false end
    local wanted = self:NormalizeName(sender or "")
    if wanted == "" then return false end
    if self:NormalizeName(record.raidLeader or record.author or "") == wanted then return true end
    if self:NormalizeName(record.inviteContact or "") == wanted then return true end
    local helpers = string.gsub(tostring(record.inviteHelpers or ""), ";", ",")
    local parts = self:Split(helpers, ",")
    local index, part
    for index = 1, table.getn(parts) do
        part = parts[index]
        if self:NormalizeName(part) == wanted then return true end
    end
    return false
end


local function RaidMetaUnescape175(text)
    text=tostring(text or "")
    text=string.gsub(text,"%%0A","\n")
    text=string.gsub(text,"%%2C",",")
    text=string.gsub(text,"%%7E","~")
    text=string.gsub(text,"%%7C","|")
    text=string.gsub(text,"%%5E","^")
    text=string.gsub(text,"%%25","%%")
    return text
end

local function NormalizeRaidHelpers175(self,text)
    local names={}
    local parts,index,part
    text=string.gsub(tostring(text or ""),";",",")
    parts=self:Split(text,",")
    for index=1,table.getn(parts) do
        part=self:NormalizeName(parts[index])
        if part~="" then table.insert(names,part) end
    end
    table.sort(names)
    return table.concat(names,",")
end

local function AssignedRaidMetaIsInviteOnly175(self,fields,sender)
    local record=self.GetRaidById156 and self:GetRaidById156(fields[3] or "") or nil
    if not record or not IsAssignedRaidInviteSender175(self,fields[3],sender) then return false end
    local sameFeatured=(fields[5]=="1")==(record.featured and true or false)
    local sameCancel=RaidMetaUnescape175(fields[6] or "")==tostring(record.cancelReason or "")
    local incomingLeader=self:NormalizeName(RaidMetaUnescape175(fields[7] or ""))
    local incomingContact=self:NormalizeName(RaidMetaUnescape175(fields[8] or ""))
    local incomingHelpers=NormalizeRaidHelpers175(self,RaidMetaUnescape175(fields[9] or ""))
    local currentLeader=self:NormalizeName(record.raidLeader or record.author or "")
    local currentContact=self:NormalizeName(record.inviteContact or record.raidLeader or record.author or "")
    local currentHelpers=NormalizeRaidHelpers175(self,record.inviteHelpers or "")
    local inviteRevision=tonumber(fields[10]) or -1
    local currentInviteRevision=tonumber(record.inviteRevision) or 0
    local inviteTs=tonumber(fields[12]) or 0
    return sameFeatured and sameCancel and incomingLeader==currentLeader and incomingContact==currentContact
        and incomingHelpers==currentHelpers and inviteRevision>=currentInviteRevision
        and inviteRevision<=currentInviteRevision+1 and inviteTs>0 and math.abs(self:Now()-inviteTs)<=600
end

local function IsRecentSharedActivitySync(self)
    local db = self:GetGuildDB()
    local shared = db and db.sharedActivity156
    return shared and self:Now() - (tonumber(shared.lastSync) or 0) <= 30
end

local function WireUnescape(text)
    text = tostring(text or "")
    text = string.gsub(text, "%%0A", "\n")
    text = string.gsub(text, "%%2C", ",")
    text = string.gsub(text, "%%7E", "~")
    text = string.gsub(text, "%%7C", "|")
    text = string.gsub(text, "%%5E", "^")
    text = string.gsub(text, "%%25", "%%")
    return text
end

local function ValidRevision(value)
    value = tonumber(value)
    return value and value >= 1 and value <= 1000000
end

local function ValidShortField(value, maximum)
    value = tostring(value or "")
    return value ~= "" and string.len(value) <= (tonumber(maximum) or 64)
end

local function ValidIdentityPeers184(value, role)
    value = tostring(value or "")
    if role == "N" then return value == "" end
    if value == "" or string.len(value) > 77 or string.find(value, "[|%^%c%s]") then return false end
    local count = 0
    local token
    for token in string.gfind(value, "[^,]+") do
        if string.len(token) < 1 or string.len(token) > 12 then return false end
        count = count + 1
        if count > 6 then return false end
    end
    if role == "A" then return count == 1 and not string.find(value, ",", 1, true) end
    return role == "M" and count >= 1 and count <= 6
end

local MODERATION_TYPES_183 = { PLAYER=true, GUILD=true, ADDON=true, SUGGESTION=true }
local MODERATION_CATEGORIES_183 = {
    HARASSMENT=true, SPAM=true, CHAT=true, LOOT=true, GROUP=true, RULES=true, SCAM=true, CONTENT=true,
    ORGANIZATION=true, RANK=true, RAID=true, RECRUITMENT=true,
    FPS=true, UI=true, FEATURE=true, DATA=true, SYNC=true, PROFESSION=true, ACHIEVEMENT=true,
    ADDON=true, GUILD=true, EVENT=true, OTHER=true,
    BEHAVIOUR=true, TRADE=true,
}
local MODERATION_REPORT_CATEGORIES_183 = {
    PLAYER = { HARASSMENT=true, SPAM=true, CHAT=true, LOOT=true, GROUP=true, RULES=true, SCAM=true, CONTENT=true, OTHER=true },
    GUILD = { ORGANIZATION=true, RANK=true, RAID=true, RECRUITMENT=true, RULES=true, OTHER=true },
    ADDON = { FPS=true, UI=true, FEATURE=true, DATA=true, SYNC=true, PROFESSION=true, ACHIEVEMENT=true, OTHER=true },
    SUGGESTION = { ADDON=true, GUILD=true, EVENT=true, OTHER=true },
}
local MODERATION_STATUSES_183 = {
    NEW=true, SEEN=true, REVIEW=true, WAITING=true, HOLD=true, ACTION=true,
    RESOLVED=true, NO_ACTION=true, REJECTED=true, DUPLICATE=true, ARCHIVED=true, WITHDRAWN=true,
}
local MODERATION_CLEAR_REASONS_183 = { EXPIRED=true, RESOLVED=true, MISTAKE=true, DECISION=true }
local MODERATION_RECONCILIATION_KINDS_183 = {
    MSUM=true, MREQ=true, MIDX=true, MWARN=true, MWTEXT=true,
    MCASE=true, MCTEXT=true, MACK=true,
}

local function ValidModerationTimestamp183(self, value)
    value = tonumber(value) or 0
    return value > 0 and value <= self:Now() + 86400
end

local function ValidModerationText183(value, maximum, allowEmpty)
    value = tostring(value or "")
    if not allowEmpty and value == "" then return false end
    return string.len(value) <= (tonumber(maximum) or 120) and not string.find(value, "[%c]")
end

local function ValidModerationName183(value, allowEmpty)
    value = tostring(value or "")
    if allowEmpty and value == "" then return true end
    return value ~= "" and string.len(value) <= 32 and not string.find(value, "[%c%^]")
end

local function ValidModerationBucketText183(self, value)
    local buckets = self:Split(tostring(value or ""), ",")
    if table.getn(buckets) ~= 6 then return false end
    local index, separator, count, hash
    for index = 1, table.getn(buckets) do
        separator = string.find(buckets[index], ".", 1, true)
        if not separator then return false end
        count = tonumber(string.sub(buckets[index], 1, separator - 1)) or -1
        hash = tonumber(string.sub(buckets[index], separator + 1)) or -1
        if count < 0 or count > 120 or hash < 0 or hash > 99990 then return false end
    end
    return true
end

local function ValidModerationIndexEntries183(self, value, recordType)
    value = tostring(value or "")
    if value == "" then return true end
    local entries = self:Split(value, "~")
    if table.getn(entries) > 2 then return false end
    local index, fields, revision, state, updatedAt, digest
    for index = 1, table.getn(entries) do
        fields = self:Split(entries[index], ",")
        revision, state = tonumber(fields[2]) or 0, fields[3] or ""
        updatedAt, digest = tonumber(fields[4]) or -1, tonumber(fields[5]) or -1
        if table.getn(fields) ~= 5 or not self:IsValidID(fields[1] or "", 24)
            or revision < 1 or revision > 1000000 or updatedAt < 0
            or digest < 0 or digest > 99990 then return false end
        if recordType == "W" and state ~= "0" and state ~= "1" then return false end
        if recordType == "C" and not MODERATION_STATUSES_183[state] then return false end
    end
    return true
end

local function CanRelayPve(self, channel, sender, leadershipOnly)
    if channel ~= "WHISPER" or not IsRecentPveSync(self) then return false end
    return not leadershipOnly or self:IsLeadershipSender(sender)
end

local function CanApplyPveDelete(self, kind, id, sender, channel)
    if not self:IsValidID(id, 64) then return false end
    local pve = self:EnsurePveDB()
    local record = kind == "REQDEL" and pve and pve.requests and pve.requests[id]
        or (kind == "BOARDDEL" and pve and pve.board and pve.board[id])
        or (kind == "RAIDDEL" and pve and ((pve.raids and pve.raids[id]) or (pve.cancelledRaids156 and pve.cancelledRaids156[id])))
    if kind == "RAIDDEL" then return self:IsLeadershipSender(sender) or CanRelayPve(self, channel, sender, true) end
    if record and self:NormalizeName(record.author) == self:NormalizeName(sender) then return true end
    return self:IsLeadershipSender(sender) or (not record and CanRelayPve(self, channel, sender, false))
end

local function CanApplyCraftDelete(self, id, sender)
    if not self:IsValidID(id, 64) then return false end
    local craft = self:EnsureCraftingDB()
    local record = craft and craft.requests and craft.requests[id]
    if record and self:NormalizeName(record.author) == self:NormalizeName(sender) then return true end
    return self:IsLeadershipSender(sender)
end

local function CanApplyCraftState(self, fields, sender)
    if fields[13] ~= "STATE1" then return true end
    local status = fields[14] or ""
    if (status ~= "CLAIMED" and status ~= "COMPLETED") or not ValidRevision(fields[15]) then return false end
    local craft = self:EnsureCraftingDB()
    local request = craft and craft.requests and craft.requests[fields[4] or ""]
    -- A state response may arrive before the request during a targeted sync.
    -- It remains a normal, directly-authored CRES packet and is revalidated
    -- against the request before the state is applied.
    if not request then return true end
    if status == "CLAIMED" then
        return self:NormalizeName(request.author) ~= self:NormalizeName(sender)
    end
    return self:NormalizeName(request.author) == self:NormalizeName(sender)
        or self:NormalizeName(request.claimedBy) == self:NormalizeName(sender)
        or self:IsLeadershipSender(sender)
end

local function DirectOrExpectedPve(self, fields, sender, channel, authorField)
    local author = fields[authorField] or ""
    if self:NormalizeName(author) == self:NormalizeName(sender) then return true end
    return channel == "WHISPER" and IsRecentPveSync(self)
end

local function DirectOrExpectedCraft(self, fields, sender, channel, authorField)
    local author = fields[authorField] or ""
    if self:NormalizeName(author) == self:NormalizeName(sender) then return true end
    local craft = self:EnsureCraftingDB()
    return channel == "WHISPER" and craft and craft.syncState and craft.syncState.active
        and self:Now() - (craft.syncState.started or 0) <= CRAFT_TRANSFER_WINDOW
end

local function CanApplyCraftRequestMeta180(self, fields, sender, channel)
    local requestId = fields[3] or ""
    local revision = tonumber(fields[4]) or 0
    local source = string.upper(tostring(fields[5] or ""))
    if not self:IsValidID(requestId, 64) or revision < 1 or revision > 1000000 then return false end
    if source ~= "RECIPE" and source ~= "GENERIC" then return false end
    if string.len(fields[6] or "") > 120 or string.len(fields[8] or "") > 40
        or string.len(fields[10] or "") > 140 or string.len(fields[11] or "") > 140 then return false end
    local itemId = tonumber(fields[7]) or 0
    local quality = tonumber(fields[9]) or -1
    if itemId < 0 or itemId > 100000000 or quality < -1 or quality > 7 then return false end
    local craft = self:EnsureCraftingDB()
    local request = craft and craft.requests and craft.requests[requestId]
    if request then return self:IsCraftingRequestMetaSenderAllowed180(request, sender, channel) end
    if channel == "GUILD" then return true end
    return channel == "WHISPER" and craft and craft.syncState and craft.syncState.active
        and self:Now() - (tonumber(craft.syncState.started) or 0) <= CRAFT_TRANSFER_WINDOW
end

-- R44 city-stutter fast path. Vanilla targeted addon traffic is physically
-- broadcast through GUILD, so every compatible guild client receives packets
-- addressed to somebody else. In large guilds this can be thousands of events
-- in a few minutes. Discard no-op packets before diagnostics, pcall closure
-- creation and scheduler recomputation; the full security handler still owns
-- malformed/self-addressed/real packets.
function OTLGM:FastDiscardAddonPacketR44(prefix, message, channel, sender)
    if prefix ~= "OTLGM" or type(message) ~= "string" or type(sender) ~= "string" then return false end
    self.runtime = self.runtime or {}
    local player = UnitName and (UnitName("player") or "") or ""
    local playerKey = self.runtime.fastAddonPlayerKeyR44
    if self.runtime.fastAddonPlayerRawR44 ~= player or not playerKey then
        self.runtime.fastAddonPlayerRawR44 = player
        playerKey = self:NormalizeName(player)
        self.runtime.fastAddonPlayerKeyR44 = playerKey
    end

    -- The canonical handler already ignores our own echo. Doing it here avoids
    -- allocating packet diagnostics and walking CompatibilityDue180 afterwards.
    if playerKey ~= "" and self:NormalizeName(sender) == playerKey then
        self.runtime.metrics = self.runtime.metrics or {}
        self.runtime.metrics.network = self.runtime.metrics.network or { queued = 0, sent = 0, retried = 0, dropped = 0, rejected = 0 }
        self.runtime.metrics.network.selfEchoFastSkippedR44 = (tonumber(self.runtime.metrics.network.selfEchoFastSkippedR44) or 0) + 1
        return true
    end

    if channel ~= "GUILD" or string.sub(message, 1, string.len(TARGET_ENVELOPE)) ~= TARGET_ENVELOPE then return false end
    local separator = string.find(message, "^", string.len(TARGET_ENVELOPE) + 1, true)
    if not separator then return false end
    local target = string.sub(message, string.len(TARGET_ENVELOPE) + 1, separator - 1)
    -- Let the canonical handler reject malformed envelopes so diagnostics and
    -- abuse accounting remain authoritative.
    if target == "" or string.len(target) > 48 or string.find(target, "[%c]") then return false end
    if self:NormalizeName(target) == playerKey then return false end

    self.runtime.metrics = self.runtime.metrics or {}
    self.runtime.metrics.network = self.runtime.metrics.network or { queued = 0, sent = 0, retried = 0, dropped = 0, rejected = 0 }
    local metrics = self.runtime.metrics.network
    metrics.targetedSkipped = (tonumber(metrics.targetedSkipped or metrics.targetedIgnored) or 0) + 1
    metrics.targetedFastSkippedR44 = (tonumber(metrics.targetedFastSkippedR44) or 0) + 1
    return true
end

function OTLGM.__impl180.HandleAddonMessage__impl1(self, prefix, message, channel, sender)
    if prefix ~= "OTLGM" or type(message) ~= "string" or type(sender) ~= "string" then return false end
    if string.len(message) == 0 or string.len(message) > 250 then return Reject(self, "invalid-size", sender) end

    -- Point-to-point addon traffic is transported through GUILD on Vanilla.
    -- Filter packets for other recipients before roster lookup/rate accounting;
    -- a large guild should not pay parsing or rate-limit cost for traffic that
    -- was never addressed to this client.
    if channel == "GUILD" and string.sub(message, 1, string.len(TARGET_ENVELOPE)) == TARGET_ENVELOPE then
        local separator = string.find(message, "^", string.len(TARGET_ENVELOPE) + 1, true)
        if not separator then return Reject(self, "target-envelope-shape", sender) end
        local target = string.sub(message, string.len(TARGET_ENVELOPE) + 1, separator - 1)
        if target == "" or string.len(target) > 48 or string.find(target, "[%c]") then return Reject(self, "target-envelope-address", sender) end
        if self:NormalizeName(target) ~= self:NormalizeName(UnitName("player") or "") then
            self.runtime = self.runtime or {}
            self.runtime.metrics = self.runtime.metrics or {}
            self.runtime.metrics.network = self.runtime.metrics.network or { queued = 0, sent = 0, retried = 0, dropped = 0, rejected = 0 }
            self.runtime.metrics.network.targetedSkipped = (self.runtime.metrics.network.targetedSkipped or self.runtime.metrics.network.targetedIgnored or 0) + 1
            return true
        end
        message = string.sub(message, separator + 1)
        channel = "WHISPER"
        if message == "" then return Reject(self, "target-envelope-empty", sender) end
        self.runtime = self.runtime or {}
        self.runtime.metrics = self.runtime.metrics or {}
        self.runtime.metrics.network = self.runtime.metrics.network or { queued = 0, sent = 0, retried = 0, dropped = 0, rejected = 0 }
        self.runtime.metrics.network.targetedReceived = (self.runtime.metrics.network.targetedReceived or 0) + 1
    end
    if self:NormalizeName(sender) == self:NormalizeName(UnitName("player") or "") then return true end

    local fields = self:Split(message, "^")
    local protocol = fields[1] or ""
    local kind = fields[2] or ""
    -- No persistent peer/version state may be mutated until the actual addon
    -- sender is present in the committed guild roster and has passed the shared
    -- inbound rate limit. This also prevents spoofed legacy-sync packets from
    -- being accepted as harmless before sender validation.
    if not self:IsKnownGuildSender(sender) then return Reject(self, "unknown-sender", sender) end
    if not (self.runtime and self.runtime.authorityReplaySkipRateRC5) and not self:CheckInboundRate(sender) then return Reject(self, "rate-limit", sender) end

    local advertisedVersion = nil
    if protocol == "P1" and kind == "SYNC" then advertisedVersion = fields[4] end
    if protocol == "C1" and kind == "SYNC157" then advertisedVersion = fields[3] end
    if self.RememberAddonUser and advertisedVersion then self:RememberAddonUser(sender, advertisedVersion) end

    -- RC5-R2: mixed 1.7/1.8 guilds must not create a recipe-transfer storm.
    -- Advanced full-state crafting packets from a peer that has not advertised
    -- the 1.8 explicit-session contract are intentionally ignored before rate
    -- accounting. Compact requests/responses remain backward compatible.
    if protocol == "C1" and (kind == "SYNC" or kind == "SYNC157" or kind == "CMAN" or kind == "CMEND" or kind == "CWANT" or kind == "CCHG" or kind == "RC3" or kind == "RC2" or kind == "RCP") then
        local modern = self.IsModernSyncPeerR2 and self:IsModernSyncPeerR2(sender, advertisedVersion)
        if not modern then
            self.runtime = self.runtime or {}
            self.runtime.metrics = self.runtime.metrics or {}
            self.runtime.metrics.network = self.runtime.metrics.network or { queued = 0, sent = 0, retried = 0, dropped = 0, rejected = 0 }
            self.runtime.metrics.network.legacyCraftIgnoredR2 = (tonumber(self.runtime.metrics.network.legacyCraftIgnoredR2) or 0) + 1
            return true
        end
    end
    -- Old PvE clients can still publish ordinary records, but their broad SYNC
    -- request is not answered with a modern full-state replay.
    if protocol == "P1" and kind == "SYNC" and self.IsModernSyncPeerR2 and not self:IsModernSyncPeerR2(sender, advertisedVersion) then
        self.runtime = self.runtime or {}
        self.runtime.legacyPveSyncIgnoredR2 = (tonumber(self.runtime.legacyPveSyncIgnoredR2) or 0) + 1
        return true
    end

    if protocol == "F1" then
        if kind == "STATE" then
            if channel ~= "WHISPER" then return Reject(self, "release175-channel", sender) end
            if not ValidShortField(fields[3] or "", 16) or string.len(fields[4] or "") > 12
                or string.len(fields[5] or "") > 180 or string.len(fields[6] or "") > 80
                or not tonumber(fields[7]) then return Reject(self, "release175-state-shape", sender) end
        elseif kind == "REVIVE" then
            if channel ~= "WHISPER" then return Reject(self, "release175-channel", sender) end
            if not ValidShortField(fields[3] or "", 48) or string.len(fields[4] or "") > 80
                or not tonumber(fields[5]) or string.len(fields[6] or "") > 80 then return Reject(self, "release175-revive-shape", sender) end
        elseif kind == "LEVEL" then
            local level, timestamp = tonumber(fields[4]) or 0, tonumber(fields[6]) or 0
            if channel ~= "WHISPER" or not ValidShortField(fields[3] or "", 48)
                or level < 1 or level > 255 or string.len(fields[5] or "") > 180 or timestamp <= 0 then
                return Reject(self, "release175-level-shape", sender)
            end
        elseif kind == "REQ" then
            if channel ~= "WHISPER" or not ValidShortField(fields[3] or "", 32) then
                return Reject(self, "profile-request-shape", sender)
            end
        elseif kind == "PROFILE" then
            local revision = tonumber(fields[3]) or 0
            local completed, total = tonumber(fields[4]) or -1, tonumber(fields[5]) or -1
            local timestamp = tonumber(fields[6]) or 0
            local recent = fields[7] or ""
            local fieldCount = table.getn(fields)
            if (channel ~= "GUILD" and channel ~= "WHISPER") or revision < 1 or revision > 1000000000
                or completed < 0 or completed > 500 or total < 1 or total > 500 or completed > total
                or timestamp <= 0 or string.len(recent) > 120 or string.find(recent, "[%c]")
                or (fieldCount ~= 7 and fieldCount ~= 11) then
                return Reject(self, "profile-summary-shape", sender)
            end
            -- r34 optional Main/Alt identity extension. Old clients safely
            -- ignore fields 8..11; r34 validates them here before feature code.
            if fieldCount == 11 then
                local identityRole = fields[8] or ""
                local identityPeers = fields[9] or ""
                local identityRevision = tonumber(fields[10]) or 0
                local identityUpdatedAt = tonumber(fields[11]) or 0
                if (identityRole ~= "A" and identityRole ~= "M" and identityRole ~= "N")
                    or not ValidIdentityPeers184(identityPeers, identityRole)
                    or identityRevision < 1 or identityRevision > 1000000000 or identityUpdatedAt <= 0 then
                    return Reject(self, "profile-identity-shape", sender)
                end
            end
        elseif kind == "ACHREQ" then
            local requestAt = tonumber(fields[3]) or 0
            local catalogRevision = tonumber(fields[4]) or 0
            if channel ~= "WHISPER" or table.getn(fields) ~= 4 or requestAt <= 0
                or catalogRevision < 1 or catalogRevision > 1000000000 then
                return Reject(self, "profile-achievement-request-shape", sender)
            end
        elseif kind == "ACHMAP" then
            local revision = tonumber(fields[3]) or 0
            local catalogRevision = tonumber(fields[4]) or 0
            local completed, total = tonumber(fields[5]) or -1, tonumber(fields[6]) or -1
            local timestamp = tonumber(fields[7]) or 0
            local bitmap = fields[8] or ""
            if channel ~= "WHISPER" or table.getn(fields) ~= 8 or revision < 1 or revision > 1000000000
                or catalogRevision < 1 or catalogRevision > 1000000000
                or completed < 0 or total < 1 or total > 500 or completed > total or timestamp <= 0
                or string.len(bitmap) ~= math.ceil(total / 4) or string.len(bitmap) > 128 or string.find(bitmap, "[^0-9A-Fa-f]") then
                return Reject(self, "profile-achievement-map-shape", sender)
            end
        elseif kind == "ABOUT" then
            local revision, timestamp = tonumber(fields[3]) or 0, tonumber(fields[4]) or 0
            local about = fields[5] or ""
            if (channel ~= "GUILD" and channel ~= "WHISPER") or revision < 1 or revision > 1000000000
                or timestamp <= 0 or string.len(about) > 180 or string.find(about, "[%c]") then
                return Reject(self, "profile-about-shape", sender)
            end
        elseif kind == "IDREQ" or kind == "IDACK" or kind == "IDREJ" or kind == "IDUNLINK" then
            local identityName = fields[3] or ""
            local requestRevision = tonumber(fields[4]) or 0
            local identityTimestamp = tonumber(fields[5]) or 0
            if channel ~= "WHISPER" or table.getn(fields) ~= 5
                or not ValidShortField(identityName, 12) or string.find(identityName, "[,|]")
                or requestRevision < 1 or requestRevision > 1000000000 or identityTimestamp <= 0 then
                return Reject(self, "character-identity-shape", sender)
            end
        else
            return Reject(self, "unknown-release175-kind", sender)
        end
        return self.HandleRelease175Message and self:HandleRelease175Message(message, channel, sender) or false
    end

    if protocol == "M1" then
        if channel ~= "WHISPER" then return Reject(self, "moderation-channel", sender) end
        local reportId = fields[3] or ""
        local revision = tonumber(fields[4]) or 0
        if not self:IsValidID(reportId, 24) or revision < 1 or revision > 1000000 then
            return Reject(self, "moderation-id-revision", sender)
        end

        if MODERATION_RECONCILIATION_KINDS_183[kind] then
            if not self:IsOfficerMode() then return Reject(self, "moderation-reconcile-recipient", sender) end
            if not self:IsLeadershipSender(sender) then return Reject(self, "moderation-authority", sender) end
            local expectedFields = kind == "MSUM" and 12 or kind == "MREQ" and 8 or kind == "MIDX" and 9
                or kind == "MWARN" and 19 or kind == "MCASE" and 24
                or (kind == "MWTEXT" or kind == "MCTEXT") and 9 or kind == "MACK" and 8 or 0
            if table.getn(fields) ~= expectedFields then
                return Reject(self, "moderation-reconcile-field-count", sender)
            end
            if kind == "MSUM" then
                local activeWarnings, warningCount, warningHash = tonumber(fields[5]) or -1,
                    tonumber(fields[6]) or -1, tonumber(fields[7]) or -1
                local openCases, caseCount, caseHash = tonumber(fields[8]) or -1,
                    tonumber(fields[9]) or -1, tonumber(fields[10]) or -1
                if activeWarnings < 0 or activeWarnings > warningCount or warningCount > 120
                    or warningHash < 0 or warningHash > 99990 or openCases < 0 or openCases > caseCount
                    or caseCount > 120 or caseHash < 0 or caseHash > 99990
                    or not ValidModerationBucketText183(self, fields[11])
                    or not ValidModerationBucketText183(self, fields[12]) then
                    return Reject(self, "moderation-summary-shape", sender)
                end
            elseif kind == "MREQ" then
                local mode, recordType = fields[5] or "", fields[6] or ""
                if (mode ~= "I" and mode ~= "R") or (recordType ~= "W" and recordType ~= "C") then
                    return Reject(self, "moderation-request-shape", sender)
                end
                if mode == "I" then
                    local bucket, offset = tonumber(fields[7]) or 0, tonumber(fields[8]) or 0
                    if bucket < 1 or bucket > 6 or offset < 1 or offset > 121 then
                        return Reject(self, "moderation-request-shape", sender)
                    end
                else
                    local ids = self:Split(fields[7] or "", ",")
                    local index
                    if table.getn(ids) < 1 or table.getn(ids) > 2 or tostring(fields[8] or "") ~= "0" then
                        return Reject(self, "moderation-request-shape", sender)
                    end
                    for index = 1, table.getn(ids) do
                        if not self:IsValidID(ids[index], 24) then return Reject(self, "moderation-request-shape", sender) end
                    end
                end
            elseif kind == "MIDX" then
                local recordType = fields[5] or ""
                local bucket, offset, nextOffset = tonumber(fields[6]) or 0, tonumber(fields[7]) or 0, tonumber(fields[8]) or -1
                if (recordType ~= "W" and recordType ~= "C") or bucket < 1 or bucket > 6
                    or offset < 1 or offset > 121 or nextOffset < 0 or nextOffset > 121
                    or (nextOffset > 0 and nextOffset <= offset)
                    or not ValidModerationIndexEntries183(self, fields[9], recordType) then
                    return Reject(self, "moderation-index-shape", sender)
                end
            elseif kind == "MWARN" then
                if self:NormalizeName(fields[8] or "") == self:NormalizeName(UnitName("player") or "") then
                    return Reject(self, "moderation-warning-private-recipient", sender)
                end
                local active, announced, acknowledged = fields[11] or "", tonumber(fields[12]) or 0, fields[13] or ""
                local acknowledgedAt, clearReason, clearedAt = tonumber(fields[14]) or 0, fields[15] or "", tonumber(fields[16]) or 0
                local relatedCaseId = fields[17] or ""
                local reasonParts, commentParts = tonumber(fields[18]) or -1, tonumber(fields[19]) or -1
                if not self:IsValidID(fields[5] or "", 24) or not ValidModerationTimestamp183(self, fields[6])
                    or not ValidModerationTimestamp183(self, fields[7]) or not ValidModerationName183(fields[8], false)
                    or not ValidModerationName183(fields[9], false) or not MODERATION_CATEGORIES_183[fields[10] or ""]
                    or (relatedCaseId ~= "" and not self:IsValidID(relatedCaseId, 24))
                    or (active ~= "0" and active ~= "1") or announced < 1 or announced > 2
                    or (acknowledged ~= "0" and acknowledged ~= "1")
                    or (acknowledgedAt > 0 and not ValidModerationTimestamp183(self, acknowledgedAt))
                    or reasonParts < 0 or reasonParts > 1 or commentParts < 0 or commentParts > 2
                    or (active == "1" and (reasonParts < 1 or clearReason ~= "" or clearedAt ~= 0))
                    or (active == "0" and (not MODERATION_CLEAR_REASONS_183[clearReason]
                        or not ValidModerationTimestamp183(self, clearedAt) or reasonParts ~= 0 or commentParts ~= 0)) then
                    return Reject(self, "moderation-warning-record-shape", sender)
                end
            elseif kind == "MCASE" then
                local sourceRevision = tonumber(fields[6]) or 0
                local reportType, category, status = fields[11] or "", fields[12] or "", fields[13] or ""
                local privacyScope = fields[14] or ""
                local assignedTo, relatedCaseId, caseKind = fields[15] or "", fields[16] or "", fields[17] or ""
                local textParts, diagnosticParts = tonumber(fields[18]) or -1, tonumber(fields[19]) or -1
                local responseParts, followupParts, commentParts = tonumber(fields[20]) or -1,
                    tonumber(fields[21]) or -1, tonumber(fields[22]) or -1
                local reasonParts, timelineParts = tonumber(fields[23]) or -1, tonumber(fields[24]) or -1
                local terminal = status == "RESOLVED" or status == "NO_ACTION" or status == "REJECTED"
                    or status == "DUPLICATE" or status == "ARCHIVED" or status == "WITHDRAWN"
                if not self:IsValidID(fields[5] or "", 24) or sourceRevision < 1 or sourceRevision > 1000000
                    or not ValidModerationTimestamp183(self, fields[7]) or not ValidModerationTimestamp183(self, fields[8])
                    or not ValidModerationName183(fields[9], false) or not ValidModerationName183(fields[10], true)
                    or (assignedTo ~= "" and not ValidModerationName183(assignedTo, false))
                    or (relatedCaseId ~= "" and not self:IsValidID(relatedCaseId, 24))
                    or (caseKind ~= "REPORT" and caseKind ~= "ESCALATION")
                    or (privacyScope ~= "LEADERSHIP" and privacyScope ~= "GUILD_LEADER")
                    or self:NormalizeName(fields[10] or "") == self:NormalizeName(UnitName("player") or "")
                    or (privacyScope == "GUILD_LEADER" and (not self.IsGuildLeader170 or not self:IsGuildLeader170()))
                    or not MODERATION_TYPES_183[reportType] or not MODERATION_REPORT_CATEGORIES_183[reportType]
                    or not MODERATION_REPORT_CATEGORIES_183[reportType][category] or not MODERATION_STATUSES_183[status]
                    or textParts < 0 or textParts > 3 or diagnosticParts < 0 or diagnosticParts > 2
                    or responseParts < 0 or responseParts > 2 or followupParts < 0 or followupParts > 2
                    or commentParts < 0 or commentParts > 2 or reasonParts < 0 or reasonParts > 1
                    or timelineParts < 0 or timelineParts > 8
                    or (not terminal and textParts < 1)
                    or (terminal and (textParts ~= 0 or diagnosticParts ~= 0 or responseParts ~= 0
                        or followupParts ~= 0 or commentParts ~= 0))
                    or (reportType ~= "ADDON" and diagnosticParts ~= 0) then
                    return Reject(self, "moderation-case-record-shape", sender)
                end
            elseif kind == "MWTEXT" or kind == "MCTEXT" then
                local code, sequence, total = fields[6] or "", tonumber(fields[7]) or 0, tonumber(fields[8]) or 0
                local maximum = code == "T" and 3 or code == "D" and 2 or code == "R" and 2
                    or code == "F" and 2 or code == "P" and 2 or code == "S" and 1 or code == "L" and 8 or 0
                if kind == "MWTEXT" and code ~= "R" and code ~= "P" then maximum = 0 end
                if kind == "MCTEXT" and code ~= "T" and code ~= "D" and code ~= "R" and code ~= "F"
                    and code ~= "P" and code ~= "S" and code ~= "L" then maximum = 0 end
                if not self:IsValidID(fields[5] or "", 24) or maximum == 0 or sequence < 1 or total < 1
                    or sequence > total or total > maximum or not ValidModerationText183(fields[9] or "", 84, false) then
                    return Reject(self, "moderation-record-chunk-shape", sender)
                end
            elseif kind == "MACK" then
                local recordType, result = fields[5] or "", fields[8] or ""
                if (recordType ~= "S" and recordType ~= "W" and recordType ~= "C")
                    or not self:IsValidID(fields[6] or "", 24) or not ValidRevision(fields[7])
                    or (result ~= "OK" and result ~= "BUSY") then
                    return Reject(self, "moderation-reconcile-ack-shape", sender)
                end
            end
        elseif kind == "REPORT" then
            local timestamp = fields[5]
            local reportType, category, target = fields[6] or "", fields[7] or "", fields[8] or ""
            local textParts, diagnosticParts = tonumber(fields[9]) or 0, tonumber(fields[10]) or -1
            local privacyScope = fields[11] or ""
            if not self:IsOfficerMode() then return Reject(self, "moderation-officer-recipient", sender) end
            local targetMember = reportType == "PLAYER" and self.GetMember and self:GetMember(target) or nil
            local targetIsLeadership = targetMember and self.IsLeadership and self:IsLeadership(targetMember) and true or false
            local canonicalLeaderR30 = self.GetCanonicalGuildLeaderName180 and self:GetCanonicalGuildLeaderName180() or ""
            local senderIsGuildLeaderR30 = canonicalLeaderR30 ~= "" and self:NormalizeName(sender) == self:NormalizeName(canonicalLeaderR30)
            if privacyScope == "" then privacyScope = targetIsLeadership and "GUILD_LEADER" or "LEADERSHIP" end
            if not ValidModerationTimestamp183(self, timestamp) or not MODERATION_TYPES_183[reportType]
                or not MODERATION_REPORT_CATEGORIES_183[reportType] or not MODERATION_REPORT_CATEGORIES_183[reportType][category]
                or not ValidModerationName183(target, true)
                or (reportType == "PLAYER" and not targetMember)
                or self:NormalizeName(target) == self:NormalizeName(UnitName("player") or "")
                or (privacyScope ~= "LEADERSHIP" and privacyScope ~= "GUILD_LEADER")
                or (targetIsLeadership and privacyScope ~= "GUILD_LEADER" and not (privacyScope == "LEADERSHIP" and senderIsGuildLeaderR30))
                or (privacyScope == "GUILD_LEADER" and (not self.IsGuildLeader170 or not self:IsGuildLeader170()))
                or textParts < 1 or textParts > 3 or diagnosticParts < 0 or diagnosticParts > 2
                or (reportType ~= "ADDON" and diagnosticParts ~= 0) then
                return Reject(self, "moderation-report-shape", sender)
            end
        elseif kind == "RTEXT" or kind == "RDIAG" then
            local sequence, total = tonumber(fields[5]) or 0, tonumber(fields[6]) or 0
            local maximumParts = kind == "RTEXT" and 3 or 2
            if not self:IsOfficerMode() then return Reject(self, "moderation-officer-recipient", sender) end
            if sequence < 1 or total < 1 or sequence > total or total > maximumParts
                or not ValidModerationText183(fields[7] or "", 84, false) then
                return Reject(self, "moderation-chunk-shape", sender)
            end
        elseif kind == "RFOLLOW" then
            if not self:IsOfficerMode() then return Reject(self, "moderation-officer-recipient", sender) end
            if not ValidModerationTimestamp183(self, fields[5])
                or not ValidModerationText183(fields[6] or "", 120, false) then
                return Reject(self, "moderation-followup-shape", sender)
            end
        elseif kind == "RWITH" then
            if not self:IsOfficerMode() then return Reject(self, "moderation-officer-recipient", sender) end
            if not ValidModerationTimestamp183(self, fields[5]) then return Reject(self, "moderation-withdraw-shape", sender) end
        elseif kind == "WACK" then
            if not self:IsOfficerMode() then return Reject(self, "moderation-officer-recipient", sender) end
            if not ValidModerationTimestamp183(self, fields[5]) then return Reject(self, "moderation-warning-ack-shape", sender) end
        elseif kind == "RACK" then
            if not ValidModerationTimestamp183(self, fields[5]) then return Reject(self, "moderation-ack-shape", sender) end
            if not self:IsLeadershipSender(sender) then return Reject(self, "moderation-authority", sender) end
        elseif kind == "RSTATUS" then
            if not MODERATION_STATUSES_183[fields[5] or ""] or not ValidModerationTimestamp183(self, fields[6])
                or not ValidModerationText183(fields[7] or "", 72, true) then
                return Reject(self, "moderation-status-shape", sender)
            end
            if not self:IsLeadershipSender(sender) then return Reject(self, "moderation-authority", sender) end
        elseif kind == "RREPLY" then
            if not ValidModerationTimestamp183(self, fields[5])
                or not ValidModerationText183(fields[6] or "", 120, false) then
                return Reject(self, "moderation-reply-shape", sender)
            end
            if not self:IsLeadershipSender(sender) then return Reject(self, "moderation-authority", sender) end
        elseif kind == "WARNING" then
            local target, category = fields[6] or "", fields[7] or ""
            local activeCount = tonumber(fields[8]) or 0
            if not ValidModerationTimestamp183(self, fields[5]) or not ValidModerationName183(target, false)
                or not MODERATION_CATEGORIES_183[category] or activeCount < 1 or activeCount > 2
                or not ValidModerationText183(fields[9] or "", 72, false) then
                return Reject(self, "moderation-warning-shape", sender)
            end
            if self:NormalizeName(target) ~= self:NormalizeName(UnitName("player") or "") and not self:IsOfficerMode() then
                return Reject(self, "moderation-warning-recipient", sender)
            end
            if not self:IsLeadershipSender(sender) then return Reject(self, "moderation-authority", sender) end
        elseif kind == "WCLEAR" then
            local target, clearReason = fields[6] or "", fields[7] or ""
            if not ValidModerationTimestamp183(self, fields[5]) or not ValidModerationName183(target, false)
                or not MODERATION_CLEAR_REASONS_183[clearReason] then
                return Reject(self, "moderation-warning-clear-shape", sender)
            end
            if self:NormalizeName(target) ~= self:NormalizeName(UnitName("player") or "") and not self:IsOfficerMode() then
                return Reject(self, "moderation-warning-recipient", sender)
            end
            if not self:IsLeadershipSender(sender) then return Reject(self, "moderation-authority", sender) end
        else
            return Reject(self, "unknown-moderation-kind", sender)
        end
        return self.HandleModerationMessage183 and self:HandleModerationMessage183(fields, channel, sender) or false
    end

    if protocol == "P1" then
        if kind == "SYNC" then
            if channel ~= "GUILD" and channel ~= "WHISPER" then return Reject(self, "pve-sync-channel", sender) end
        elseif kind == "RAID" then
            if not self:IsValidID(fields[3], 64) or not ValidRevision(fields[4]) then return Reject(self, "pve-raid-shape", sender) end
            local author = fields[7] or ""
            if not self:IsLeadershipSender(author) then return Reject(self, "pve-raid-author", sender) end
            local direct = self:IsLeadershipSender(sender) and self:NormalizeName(author) == self:NormalizeName(sender)
            local relay = CanRelayPve(self, channel, sender, true)
            if not direct and not relay then return Reject(self, "pve-leadership", sender) end
        elseif kind == "RDMETA" then
            if not self:IsValidID(fields[3], 64) or not ValidRevision(fields[4]) then return Reject(self, "pve-meta-shape", sender) end
            if not self:IsLeadershipSender(sender) and not CanRelayPve(self, channel, sender, true) then
                if not AssignedRaidMetaIsInviteOnly175(self, fields, sender) then return Reject(self, "pve-meta-authority", sender) end
            end
        elseif kind == "NOTICE" then
            if not self:IsLeadershipSender(sender) then return Reject(self, "pve-notice-leadership", sender) end
        elseif kind == "REQ" and not DirectOrExpectedPve(self, fields, sender, channel, 7) then
            return Reject(self, "pve-request-author", sender)
        elseif kind == "BOARD" and not DirectOrExpectedPve(self, fields, sender, channel, 7) then
            return Reject(self, "pve-board-author", sender)
        elseif kind == "APP" then
            local status = fields[13] or ""
            local expected = (status == "PENDING" or status == "CANCELLED") and fields[9] or fields[8]
            if self:NormalizeName(expected or "") ~= self:NormalizeName(sender) then return Reject(self, "pve-application-author", sender) end
        elseif kind == "APPACK" then
            local pve = self:EnsurePveDB()
            local application = pve and pve.applications and pve.applications[fields[3] or ""]
            if not application or self:NormalizeName(application.leader) ~= self:NormalizeName(sender) then return Reject(self, "pve-ack-author", sender) end
        elseif kind == "REQDEL" or kind == "BOARDDEL" or kind == "RAIDDEL" then
            if not ValidRevision(fields[4]) or not CanApplyPveDelete(self, kind, fields[3] or "", sender, channel) then return Reject(self, "pve-delete-authority", sender) end
        elseif self.IsStageCPveMessageKind180 and self:IsStageCPveMessageKind180(kind) then
            if not self.ValidateStageCPveMessage180 or not self:ValidateStageCPveMessage180(kind, fields, sender, channel) then
                return Reject(self, "stage-c-pve-authority", sender)
            end
        elseif kind ~= "REQ" and kind ~= "BOARD" then
            return Reject(self, "unknown-pve-kind", sender)
        end
        return self.HandlePveAddonMessage and self:HandlePveAddonMessage(message, channel, sender) or false
    end

    if protocol == "C1" then
        if kind == "SYNC" or kind == "SYNC157" then
            if channel ~= "GUILD" and channel ~= "WHISPER" then return Reject(self, "craft-sync-channel", sender) end
        elseif kind == "RC3" or kind == "RC2" or kind == "RCP" then
            local owner = fields[3] or ""
            local professionKey = fields[4] or ""
            local expected, transferReason = self:IsExpectedCraftingTransfer(sender, owner, professionKey, channel)
            if not expected then
                return Reject(self, "craft-transfer:" .. tostring(transferReason or "rejected"), sender, { protocol = "C1", subtype = kind, channel = channel, owner = owner, professionKey = professionKey })
            end
        elseif kind == "CCHG" then
            local manifest = self:Split(fields[3] or "", ",")
            local owner = WireUnescape(manifest[1] or "")
            if self:NormalizeName(owner) ~= self:NormalizeName(sender) then return Reject(self, "craft-change-author", sender) end
        elseif kind == "CMAN" or kind == "CMEND" then
            local craft = self:EnsureCraftingDB()
            if channel ~= "WHISPER" then return Reject(self, "craft-manifest-channel", sender) end
            local state = craft and craft.syncState
            local attempted = state and state.peerAttemptedKeysR26
            local senderKey = self:NormalizeName(sender or "")
            if not state or not state.active or self:Now() - (state.started or 0) > CRAFT_TRANSFER_WINDOW
                or (type(attempted) == "table" and next(attempted) and not attempted[senderKey]) then
                -- A delayed CMAN/CMEND from a previously valid peer is stale
                -- transport, not a hostile packet. Ignoring it avoids turning a
                -- harmless mixed-latency response into rejection/backoff noise.
                self.runtime = self.runtime or {}
                self.runtime.craftingStaleManifestIgnoredR26 = (tonumber(self.runtime.craftingStaleManifestIgnoredR26) or 0) + 1
                return true
            end
        elseif kind == "CWANT" then
            if channel ~= "WHISPER" or not ValidShortField(WireUnescape(fields[3]), 42) or not ValidShortField(WireUnescape(fields[4]), 24) then return Reject(self, "craft-request-shape", sender) end
        elseif kind == "CREQ" and not DirectOrExpectedCraft(self, fields, sender, channel, 7) then
            return Reject(self, "craft-request-author", sender)
        elseif kind == "CMETA1" and not CanApplyCraftRequestMeta180(self, fields, sender, channel) then
            return Reject(self, "craft-request-meta", sender)
        elseif kind == "CRES" then
            if not DirectOrExpectedCraft(self, fields, sender, channel, 8) then return Reject(self, "craft-response-author", sender) end
            if not CanApplyCraftState(self, fields, sender) then return Reject(self, "craft-state-authority", sender) end
        elseif kind == "REACT" and not DirectOrExpectedCraft(self, fields, sender, channel, 5) then
            return Reject(self, "reaction-author", sender)
        elseif kind == "CDEL" then
            if not ValidRevision(fields[4]) or not CanApplyCraftDelete(self, fields[3] or "", sender) then return Reject(self, "craft-delete-authority", sender) end
        elseif kind ~= "CREQ" and kind ~= "CMETA1" and kind ~= "CRES" and kind ~= "REACT" then
            return Reject(self, "unknown-craft-kind", sender)
        end
        return self.HandleCommunityAddonMessage and self:HandleCommunityAddonMessage(message, channel, sender) or false
    end

    if protocol == "A3" then
        if kind == "SYNC" then
            if channel ~= "GUILD" and channel ~= "WHISPER" then return Reject(self, "announcement-sync-channel", sender) end
        elseif kind == "DEL" then
            if not self:IsValidID(fields[3], 56) or not ValidRevision(fields[4]) then return Reject(self, "announcement-delete-shape", sender) end
            if not self:IsLeadershipSender(sender) then return Reject(self, "announcement-delete-authority", sender) end
        elseif kind == "META" then
            local total = tonumber(fields[12]) or 0
            if not self:IsValidID(fields[3], 56) or not ValidRevision(fields[4]) or total < 1 or total > 32 then return Reject(self, "announcement-meta-shape", sender) end
            local author = WireUnescape(fields[7] or "")
            local direct = self:IsLeadershipSender(sender) and self:NormalizeName(author) == self:NormalizeName(sender)
            local relay = channel == "WHISPER" and IsRecentAnnouncementSync(self)
                and self:IsLeadershipSender(sender) and self:IsLeadershipSender(author)
            if not direct and not relay then return Reject(self, "announcement-authority", sender) end
        elseif kind == "BODY" then
            local sequence, total = tonumber(fields[5]) or 0, tonumber(fields[6]) or 0
            if not self:IsValidID(fields[3], 56) or not ValidRevision(fields[4]) or sequence < 1 or total < 1 or sequence > total or total > 32 then return Reject(self, "announcement-body-shape", sender) end
            if not self:IsLeadershipSender(sender) then return Reject(self, "announcement-body-authority", sender) end
            if channel == "WHISPER" and not IsRecentAnnouncementSync(self) then return Reject(self, "announcement-body-window", sender) end
            if channel ~= "GUILD" and channel ~= "WHISPER" then return Reject(self, "announcement-body-channel", sender) end
        else
            return Reject(self, "unknown-announcement-kind", sender)
        end
        return self.HandleAnnouncementMessage152 and self:HandleAnnouncementMessage152(message, channel, sender) or false
    end

    if protocol == "B1" then
        if kind == "SYNC" then
            if channel ~= "GUILD" and channel ~= "WHISPER" then return Reject(self, "treasury-sync-channel", sender) end
        elseif kind == "GOAL" or kind == "DEL" or kind == "END" or kind == "CONTRIB" or kind == "DONOR" then
            if channel ~= "GUILD" and channel ~= "WHISPER" then return Reject(self, "treasury-channel", sender) end
            -- Validate the wire shape before consulting mutable roster authority.
            -- This prevents malformed privileged packets from occupying the
            -- bounded RC5 authority quarantine while a roster refresh is pending.
            if kind == "CONTRIB" then
                local amount, current = tonumber(fields[8]) or 0, tonumber(fields[10]) or 0
                if not self:IsValidID(fields[3], 32) or not self:IsValidID(fields[4], 48) or not tonumber(fields[5])
                    or string.len(fields[6] or "") > 28 or string.len(fields[7] or "") > 28 or amount <= 0 or amount > 2000000000
                    or string.len(fields[9] or "") > 64 or current < 0 or current > 2000000000 then
                    return Reject(self, "treasury-contribution-shape", sender)
                end
            elseif kind == "DONOR" then
                local total = tonumber(fields[4]) or -1
                if fields[3] == "" or string.len(fields[3] or "") > 28 or total < 0 or total > 2000000000
                    or not tonumber(fields[5]) or string.len(fields[6] or "") > 28 then
                    return Reject(self, "treasury-donor-shape", sender)
                end
            elseif kind ~= "END" then
                if not self:IsValidID(fields[3], 32) then return Reject(self, "treasury-id", sender) end
                if not ValidRevision(fields[4]) then return Reject(self, "treasury-revision", sender) end
            end
            if not self:IsLeadershipSender(sender) then return Reject(self, "treasury-authority", sender) end
        else
            return Reject(self, "unknown-treasury-kind", sender)
        end
        return self.HandleTreasuryMessage170 and self:HandleTreasuryMessage170(message, channel, sender) or false
    end

    if protocol == "H1" then
        if kind ~= "SECRET" or channel ~= "WHISPER" then return Reject(self, "achievement-secret-channel", sender) end
        local id = fields[3] or ""
        local emoteKind = fields[4] or ""
        local zone = fields[5] or ""
        local timestamp = tonumber(fields[6]) or 0
        local eventKey = fields[7] or ""
        if (id ~= "A081" and id ~= "A082" and id ~= "A083")
            or (emoteKind ~= "roar" and emoteKind ~= "dance" and emoteKind ~= "kneel")
            or not ValidShortField(zone, 80) or not ValidShortField(eventKey, 80)
            or timestamp <= 0 or math.abs(self:Now() - timestamp) > 45 then
            return Reject(self, "achievement-secret-shape", sender)
        end
        return self.HandleAchievementSecretMessage174 and self:HandleAchievementSecretMessage174(fields, sender, channel) or false
    end

    if protocol == "S1" or protocol == "S2" then
        if kind == "ACT" and channel ~= "GUILD" then return Reject(self, "activity-live-channel", sender) end
        if kind == "DAY" and (channel ~= "WHISPER" or not IsRecentSharedActivitySync(self)) then return Reject(self, "activity-sync-window", sender) end
        if kind == "SYNC" and channel ~= "GUILD" then return Reject(self, "activity-sync-channel", sender) end
        if kind ~= "ACT" and kind ~= "DAY" and kind ~= "SYNC" then return Reject(self, "unknown-activity-kind", sender) end
        return self.HandleSharedActivityMessage156 and self:HandleSharedActivityMessage156(message, channel, sender) or false
    end

    if protocol == "V" or protocol == "Q" then
        if channel ~= "GUILD" and channel ~= "WHISPER" then return Reject(self, "presence-channel", sender) end
        if not string.find(fields[2] or "", "^%d+%.%d+%.%d+") or string.len(fields[2] or "") > 24 then return Reject(self, "presence-version", sender) end
        if string.len(fields[3] or "") > 48 then return Reject(self, "presence-build", sender) end
        local presenceFaction180 = fields[4] or ""
        if presenceFaction180 ~= "" and presenceFaction180 ~= "Alliance" and presenceFaction180 ~= "Horde" then
            return Reject(self, "presence-faction", sender)
        end
        return self.HandlePresenceAddonMessageLegacy and self:HandlePresenceAddonMessageLegacy(prefix, message, channel, sender) or false
    end
    if string.sub(message, 1, 2) == "V|" or string.sub(message, 1, 2) == "Q|" then
        return self.HandlePresenceAddonMessageLegacy and self:HandlePresenceAddonMessageLegacy(prefix, message, channel, sender) or false
    end

    return Reject(self, "unknown-protocol", sender)
end

local authorityRejectReasonsRC5 = {
    ["unknown-sender"] = true,
    ["pve-raid-author"] = true, ["pve-leadership"] = true, ["pve-meta-authority"] = true,
    ["pve-notice-leadership"] = true, ["pve-delete-authority"] = true, ["stage-c-pve-authority"] = true,
    ["announcement-delete-authority"] = true, ["announcement-authority"] = true, ["announcement-body-authority"] = true,
    ["treasury-authority"] = true,
    ["moderation-authority"] = true,
}

function OTLGM:HandleAddonMessage(prefix, message, channel, sender)
    local handled = self.__impl180.HandleAddonMessage__impl1(self, prefix, message, channel, sender)
    if handled then return handled end
    if self.runtime and not self.runtime.authorityReplayRC5 and self:IsAuthorityValidationPendingRC5(sender) then
        local metrics = self.runtime.metrics and self.runtime.metrics.network
        local reason = metrics and metrics.lastRejectReason or nil
        -- Only authority uncertainty is eligible for delayed replay. Malformed,
        -- rate-limited and otherwise invalid packets stay rejected and can never
        -- use the quarantine as a validation/rate-limit bypass.
        if authorityRejectReasonsRC5[reason] then
            local rateCounted = reason ~= "unknown-sender"
            if self:QueueAuthorityPacketRC5(prefix, message, channel, sender, rateCounted) then return true end
        end
    end
    return false
end

OTLGM:RegisterModule("Security", {
    rateWindow = RATE_WINDOW,
    rateMaximum = RATE_MAXIMUM,
    authorityQuarantineTTL = AUTHORITY_QUARANTINE_TTL_RC5,
    authorityQuarantineLimit = AUTHORITY_QUARANTINE_LIMIT_RC5,
    authorityTrackingLimit = AUTHORITY_TRACK_LIMIT_R14,
    validatesRoster = true,
    validatesLeadership = true,
})
