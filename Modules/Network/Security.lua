-- Inbound protocol gate. Claimed authors/ranks are never treated as authority;
-- every packet is tied to the actual CHAT_MSG_ADDON sender first.

local RATE_WINDOW = 10
local RATE_MAXIMUM = 70
local TARGET_ENVELOPE = "T1^"
local CRAFT_TRANSFER_WINDOW = 120

local function Reject(self, reason, sender)
    self.runtime = self.runtime or {}
    self.runtime.metrics = self.runtime.metrics or {}
    self.runtime.metrics.network = self.runtime.metrics.network or { queued = 0, sent = 0, retried = 0, dropped = 0, rejected = 0 }
    local metrics = self.runtime.metrics.network
    metrics.rejected = (metrics.rejected or 0) + 1
    metrics.lastRejectReason = reason
    metrics.lastRejectSender = sender
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

function OTLGM:RefreshSenderRosterCache(force)
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

    if GetNumGuildMembers and GetGuildRosterInfo then
        local ok, total = pcall(GetNumGuildMembers, true)
        total = ok and tonumber(total) or 0
        local index
        for index = 1, total do
            local rosterName, rank, rankIndex, level, className = GetGuildRosterInfo(index)
            if rosterName and rosterName ~= "" then
                local key = self:NormalizeName(rosterName)
                local existing = cache.members[key] or {}
                existing.name = rosterName
                existing.rank = rank or existing.rank or ""
                existing.rankIndex = tonumber(rankIndex) or existing.rankIndex or 99
                existing.level = tonumber(level) or existing.level or 0
                existing.class = className or existing.class or ""
                cache.members[key] = existing
            end
        end
    end
    self.runtime.senderRoster = cache
    return cache
end

function OTLGM:IsKnownGuildSender(sender)
    if not sender or sender == "" or not GetGuildInfo or not GetGuildInfo("player") then return false end
    local cache = self:RefreshSenderRosterCache(false)
    return cache.members[self:NormalizeName(sender)] ~= nil
end

function OTLGM:IsLeadershipSender(sender)
    if not self:IsKnownGuildSender(sender) then return false end
    local cache = self:RefreshSenderRosterCache(false)
    local member = cache.members[self:NormalizeName(sender)] or FindStoredMember(self, sender)
    return member and self:IsLeadership(member) and true or false
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

function OTLGM:IsExpectedCraftingTransfer(sender, owner, professionKey, channel)
    if self:NormalizeName(sender) == self:NormalizeName(owner) then return true end
    if channel ~= "WHISPER" then return false end
    local craft = self:EnsureCraftingDB()
    local state = craft and craft.syncState
    if not state or not state.active or self:Now() - (state.started or 0) > CRAFT_TRANSFER_WINDOW then return false end
    local _, wanted
    for _, wanted in pairs(state.wanted157 or {}) do
        if wanted and self:NormalizeName(wanted.sender) == self:NormalizeName(sender)
            and self:NormalizeName(wanted.owner) == self:NormalizeName(owner)
            and tostring(wanted.professionKey or "") == tostring(professionKey or "") then return true end
    end
    -- Compatibility window for a 1.5.x peer answering the explicit fallback sync.
    return state.legacyFallback157 and true or false
end

local function IsRecentPveSync(self)
    local pve = self:EnsurePveDB()
    return pve and self:Now() - (tonumber(pve.lastSync) or 0) <= 30
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

function OTLGM:HandleAddonMessage(prefix, message, channel, sender)
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
    if not self:IsKnownGuildSender(sender) then return Reject(self, "unknown-sender", sender) end
    if not self:CheckInboundRate(sender) then return Reject(self, "rate-limit", sender) end

    local fields = self:Split(message, "^")
    local protocol = fields[1] or ""
    local kind = fields[2] or ""

    if self.RememberAddonUser then
        local detectedVersion = nil
        if protocol == "P1" and kind == "SYNC" then detectedVersion = fields[4] end
        self:RememberAddonUser(sender, detectedVersion)
    end

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
            if channel ~= "GUILD" then return Reject(self, "pve-sync-channel", sender) end
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
        elseif kind ~= "REQ" and kind ~= "BOARD" then
            return Reject(self, "unknown-pve-kind", sender)
        end
        return self.HandlePveAddonMessage and self:HandlePveAddonMessage(message, channel, sender) or false
    end

    if protocol == "C1" then
        if kind == "SYNC" or kind == "SYNC157" then
            if channel ~= "GUILD" then return Reject(self, "craft-sync-channel", sender) end
        elseif kind == "RC3" or kind == "RC2" or kind == "RCP" then
            local owner = fields[3] or ""
            local professionKey = fields[4] or ""
            if not self:IsExpectedCraftingTransfer(sender, owner, professionKey, channel) then return Reject(self, "craft-transfer", sender) end
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
        elseif kind == "CRES" and not DirectOrExpectedCraft(self, fields, sender, channel, 8) then
            return Reject(self, "craft-response-author", sender)
        elseif kind == "REACT" and not DirectOrExpectedCraft(self, fields, sender, channel, 5) then
            return Reject(self, "reaction-author", sender)
        elseif kind == "CDEL" then
            if not ValidRevision(fields[4]) or not CanApplyCraftDelete(self, fields[3] or "", sender) then return Reject(self, "craft-delete-authority", sender) end
        elseif kind ~= "CREQ" and kind ~= "CRES" and kind ~= "REACT" then
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
            if channel ~= "GUILD" then return Reject(self, "treasury-sync-channel", sender) end
        elseif kind == "GOAL" or kind == "DEL" or kind == "END" then
            if channel ~= "GUILD" and channel ~= "WHISPER" then return Reject(self, "treasury-channel", sender) end
            if not self:IsLeadershipSender(sender) then return Reject(self, "treasury-authority", sender) end
            if kind ~= "END" and not self:IsValidID(fields[3], 32) then return Reject(self, "treasury-id", sender) end
            if kind ~= "END" and not ValidRevision(fields[4]) then return Reject(self, "treasury-revision", sender) end
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
        return self.HandlePresenceAddonMessageLegacy and self:HandlePresenceAddonMessageLegacy(prefix, message, channel, sender) or false
    end
    if string.sub(message, 1, 2) == "V|" or string.sub(message, 1, 2) == "Q|" then
        return self.HandlePresenceAddonMessageLegacy and self:HandlePresenceAddonMessageLegacy(prefix, message, channel, sender) or false
    end

    return Reject(self, "unknown-protocol", sender)
end

OTLGM:RegisterModule("Security", {
    rateWindow = RATE_WINDOW,
    rateMaximum = RATE_MAXIMUM,
    validatesRoster = true,
    validatesLeadership = true,
})
