-- Inbound protocol gate. Claimed authors/ranks are never treated as authority;
-- every packet is tied to the actual CHAT_MSG_ADDON sender first.

local RATE_WINDOW = tonumber(OTLGM.networkRateWindow180) or 10
local RATE_MAXIMUM = tonumber(OTLGM.networkInboundMaximum180) or 90
local AUTHORITY_QUARANTINE_TTL_RC5 = 10
local AUTHORITY_QUARANTINE_LIMIT_RC5 = 24
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

local function FindStoredMember(self, sender)
    local db = self:GetGuildDB()
    local normalized = self:NormalizeName(sender)
    local name, member
    for name, member in pairs(db and db.roster or {}) do
        if self:NormalizeName(name) == normalized then return member end
    end
    return nil
end

function OTLGM.__impl180.RefreshSenderRosterCache__impl1(self, force)
    self.runtime = self.runtime or {}
    local cache = self.runtime.senderRoster
    local now = self:Now()
    if cache and not force and now - (cache.builtAt or 0) < 30 then return cache end

    cache = { builtAt = now, members = {} }
    local player = UnitName and UnitName("player") or ""
    if player ~= "" then cache.members[self:NormalizeName(player)] = { name = player, self = true } end

    local db = self:GetGuildDB()
    local name, member
    for name, member in pairs(db and db.roster or {}) do
        cache.members[self:NormalizeName(name)] = member
    end

    -- The committed roster database is the only sender allow-list. Never walk
    -- 780+ live guild rows from the packet receive path; login/stale-on-open
    -- scans populate this cache asynchronously through the bounded roster reader.
    self.runtime.senderRoster = cache
    return cache
end

local function RequestAuthorityValidationRC4(self, sender, reason)
    self.runtime = self.runtime or {}
    local now = self:Now()
    local key = self:NormalizeName(sender or "")
    self.runtime.authorityValidationRC4 = self.runtime.authorityValidationRC4 or {}
    local last = tonumber(self.runtime.authorityValidationRC4[key]) or 0
    if now - last < 15 then return false end
    self.runtime.authorityValidationRC4[key] = now
    self.runtime.authorityPendingRC5 = self.runtime.authorityPendingRC5 or {}
    self.runtime.authorityPendingRC5[key] = now + AUTHORITY_QUARANTINE_TTL_RC5
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
    local known = cache.members[self:NormalizeName(sender)] ~= nil
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

    if not self:IsKnownGuildSender(sender) then return Reject(self, "unknown-sender", sender) end
    if not (self.runtime and self.runtime.authorityReplaySkipRateRC5) and not self:CheckInboundRate(sender) then return Reject(self, "rate-limit", sender) end

    if protocol == "F1" then
        if channel ~= "WHISPER" then return Reject(self, "release175-channel", sender) end
        if kind == "STATE" then
            if not ValidShortField(fields[3] or "", 16) or string.len(fields[4] or "") > 12
                or string.len(fields[5] or "") > 180 or string.len(fields[6] or "") > 80
                or not tonumber(fields[7]) then return Reject(self, "release175-state-shape", sender) end
        elseif kind == "REVIVE" then
            if not ValidShortField(fields[3] or "", 48) or string.len(fields[4] or "") > 80
                or not tonumber(fields[5]) or string.len(fields[6] or "") > 80 then return Reject(self, "release175-revive-shape", sender) end
        else
            return Reject(self, "unknown-release175-kind", sender)
        end
        return self.HandleRelease175Message and self:HandleRelease175Message(message, channel, sender) or false
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
            if channel ~= "WHISPER" or not craft or not craft.syncState or not craft.syncState.active or self:Now() - (craft.syncState.started or 0) > CRAFT_TRANSFER_WINDOW then
                return Reject(self, "craft-manifest-window", sender)
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
            if channel ~= "GUILD" then return Reject(self, "announcement-sync-channel", sender) end
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
    validatesRoster = true,
    validatesLeadership = true,
})
