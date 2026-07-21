-- Shared outbound transport. All feature protocols use one packet budget,
-- priority model, retry policy and set of diagnostics.

local PRIORITY_CRITICAL = 3
local PRIORITY_NORMAL = 2
local PRIORITY_BULK = 1
local MAX_PAYLOAD = 250
local MAX_QUEUED = 420
local MAX_RETRIES = 4
local RETRY_DELAYS = { 2, 4, 8, 16 }
local TARGET_ENVELOPE = "T1^"

-- TurtleRP embeds an old ChatThrottleLib that validates chat escape codes even
-- for addon traffic. A raw pipe byte can therefore abort SendAddonMessage with
-- "Invalid escape code in chat message". Feature serializers already percent-
-- escape human fields; this final transport boundary also removes control bytes
-- and encodes any accidental raw pipe before packet sizing and retry handling.
local function NormalizeWirePayload172(payload)
    payload = tostring(payload or "")
    local parts = {}
    local changed = false
    local index, byteValue, character
    for index = 1, string.len(payload) do
        byteValue = string.byte(payload, index)
        character = string.sub(payload, index, index)
        if byteValue == 124 then
            table.insert(parts, "%7C")
            changed = true
        elseif byteValue < 32 or byteValue == 127 then
            table.insert(parts, " ")
            changed = true
        else
            table.insert(parts, character)
        end
    end
    return table.concat(parts), changed
end

-- Vanilla 1.12 does not support WHISPER as an addon-message distribution
-- type. Logical point-to-point traffic is therefore carried in a compact
-- guild envelope and discarded by every client except the named recipient.
-- Keeping this translation in the transport means feature protocols can keep
-- their strict WHISPER authority/window checks without depending on a client
-- API that did not exist until later expansions.
local function NormalizeTarget(target)
    target = tostring(target or "")
    target = string.gsub(target, "^%s*(.-)%s*$", "%1")
    target = string.gsub(target, "%-.*$", "")
    if target == "" or string.len(target) > 48 or string.find(target, "^", 1, true) or string.find(target, "[%c]") then return nil end
    return target
end

local function WirePacket(payload, channel, target)
    if channel ~= "WHISPER" then return payload, channel end
    target = NormalizeTarget(target)
    if not target then return nil end
    return TARGET_ENVELOPE .. target .. "^" .. payload, "GUILD"
end

local function SplitWireFields(payload)
    local fields = {}
    local startAt = 1
    while true do
        local position = string.find(payload, "^", startAt, true)
        if not position then table.insert(fields, string.sub(payload, startAt)) break end
        table.insert(fields, string.sub(payload, startAt, position - 1))
        startAt = position + 1
    end
    return fields
end

-- A few legacy serializers were originally sized for a 250-byte guild packet.
-- Target envelopes need a small address reserve. Only human-readable tail
-- fields are shortened here; IDs, revisions, authors and state are immutable.
local function FitTargetPayload(self, payload, channel, target)
    if channel ~= "WHISPER" then return payload, false end
    local normalizedTarget = NormalizeTarget(target)
    if not normalizedTarget then return payload, false end
    local limit = MAX_PAYLOAD - string.len(TARGET_ENVELOPE) - string.len(normalizedTarget) - 1
    if string.len(payload) <= limit then return payload, false end
    local fields = SplitWireFields(payload)
    local protocol, kind = fields[1] or "", fields[2] or ""
    local shrink
    if protocol == "P1" and kind == "REQ" then shrink = { 13, 12 }
    elseif protocol == "P1" and kind == "APP" then shrink = { 14 }
    elseif protocol == "P1" and kind == "BOARD" then shrink = { 10 }
    elseif protocol == "P1" and kind == "RAID" then shrink = { 11, 9, 8 }
    elseif protocol == "P1" and kind == "RDMETA" then shrink = { 6 }
    elseif protocol == "C1" and kind == "CREQ" then shrink = { 13, 12 }
    elseif protocol == "C1" and kind == "CRES" then shrink = { 12 }
    else return payload, false end

    local index, fieldIndex, excess, desired, shortened
    for index = 1, table.getn(shrink) do
        if string.len(payload) <= limit then break end
        fieldIndex = shrink[index]
        if fields[fieldIndex] and fields[fieldIndex] ~= "" then
            excess = string.len(payload) - limit
            desired = math.max(0, string.len(fields[fieldIndex]) - excess)
            shortened = self:Utf8Truncate(fields[fieldIndex], desired)
            -- Do not leave an incomplete percent escape in C1 fields.
            shortened = string.gsub(shortened, "%%[0-9A-Fa-f]?$", "")
            fields[fieldIndex] = shortened
            payload = table.concat(fields, "^")
        end
    end
    return payload, string.len(payload) <= limit
end

local function NewQueue()
    return { items = {}, head = 1, count = 0 }
end

local function EnsureTransport(self)
    self.runtime = self.runtime or {}
    if not self.runtime.transport then
        self.runtime.transport = {
            critical = NewQueue(),
            normal = NewQueue(),
            bulk = NewQueue(),
            coalesced = {},
            sequence = 0,
            lastError = nil,
            highWater = 0,
        }
    end
    self.runtime.metrics = self.runtime.metrics or {}
    self.runtime.metrics.network = self.runtime.metrics.network or { queued = 0, sent = 0, retried = 0, dropped = 0, rejected = 0 }
    return self.runtime.transport, self.runtime.metrics.network
end

local function QueueFor(transport, priority)
    if priority >= PRIORITY_CRITICAL then return transport.critical end
    if priority >= PRIORITY_NORMAL then return transport.normal end
    return transport.bulk
end

local function Compact(queue)
    if queue.head < 80 or queue.head < table.getn(queue.items) / 2 then return end
    local compacted = {}
    local index
    for index = queue.head, table.getn(queue.items) do
        if queue.items[index] then table.insert(compacted, queue.items[index]) end
    end
    queue.items = compacted
    queue.head = 1
end

local function Pop(queue, now)
    local index = queue.head
    while index <= table.getn(queue.items) do
        local item = queue.items[index]
        if not item then
            if index == queue.head then queue.head = index + 1 end
        elseif not item.due or item.due <= now then
            queue.items[index] = false
            if index == queue.head then
                queue.head = index + 1
                while queue.head <= table.getn(queue.items) and not queue.items[queue.head] do queue.head = queue.head + 1 end
            end
            queue.count = math.max(0, queue.count - 1)
            Compact(queue)
            return item
        end
        index = index + 1
    end
    Compact(queue)
    return nil
end

local function Push(queue, item)
    table.insert(queue.items, item)
    queue.count = queue.count + 1
end

local function TotalCount(transport)
    return transport.critical.count + transport.normal.count + transport.bulk.count
end

local function DropOldestBulk(transport)
    local item = Pop(transport.bulk, math.huge)
    if item and item.coalesceKey then transport.coalesced[item.coalesceKey] = nil end
    return item ~= nil
end

local function ClassifyPve(payload)
    local _, _, kind = string.find(payload or "", "^P1%^([^%^]+)")
    kind = kind or ""
    if kind == "APP" or kind == "APPACK" or kind == "REQDEL" or kind == "BOARDDEL" or kind == "RAIDDEL" then return PRIORITY_CRITICAL end
    if kind == "REQ" or kind == "BOARD" or kind == "RAID" or kind == "RDMETA" or kind == "NOTICE" then return PRIORITY_NORMAL end
    return PRIORITY_BULK
end

local function ClassifyCommunity(payload, legacyPriority)
    local _, _, protocol, kind = string.find(payload or "", "^([^%^]+)%^([^%^]+)")
    if protocol == "A3" then return PRIORITY_NORMAL end
    if protocol == "B1" then return PRIORITY_NORMAL end
    if protocol == "C1" then
        if kind == "CREQ" or kind == "CRES" or kind == "CDEL" or kind == "REACT" then return PRIORITY_CRITICAL end
        if kind == "CWANT" or kind == "CMAN" or kind == "CMEND" or kind == "CCHG" or kind == "SYNC" or kind == "SYNC157" then return PRIORITY_NORMAL end
        if kind == "RC3" or kind == "RC2" or kind == "RCP" then return PRIORITY_BULK end
    end
    if tonumber(legacyPriority) and tonumber(legacyPriority) >= 2 then return PRIORITY_CRITICAL end
    if tonumber(legacyPriority) and tonumber(legacyPriority) > 0 then return PRIORITY_NORMAL end
    return PRIORITY_BULK
end

function OTLGM:QueueNetworkPayload(payload, channel, target, priority, source, coalesceKey)
    payload = tostring(payload or "")
    channel = channel or "GUILD"
    priority = tonumber(priority) or PRIORITY_NORMAL
    source = source or "unknown"
    local originalPayload = payload
    local sanitized
    payload, sanitized = NormalizeWirePayload172(payload)
    local fitted
    payload, fitted = FitTargetPayload(self, payload, channel, target)
    local wirePayload, physicalChannel = WirePacket(payload, channel, target)
    if payload == "" or not wirePayload or string.len(wirePayload) > MAX_PAYLOAD then
        local _, metrics = EnsureTransport(self)
        metrics.rejected = metrics.rejected + 1
        metrics.lastRejectedSize = wirePayload and string.len(wirePayload) or string.len(payload)
        metrics.lastRejectChannel = channel
        return false
    end
    if channel ~= "GUILD" and channel ~= "WHISPER" and channel ~= "OFFICER" then return false end
    if channel == "WHISPER" and (not target or target == "") then return false end

    local transport, metrics = EnsureTransport(self)
    if sanitized then
        metrics.outboundSanitized172 = (metrics.outboundSanitized172 or 0) + 1
        metrics.lastSanitizedSource172 = source
    end
    if fitted and payload ~= originalPayload then metrics.targetedTrimmed = (metrics.targetedTrimmed or 0) + 1 end
    if coalesceKey and transport.coalesced[coalesceKey] then
        local existing = transport.coalesced[coalesceKey]
        existing.payload = payload
        existing.target = target
        existing.channel = channel
        existing.wirePayload = wirePayload
        existing.physicalChannel = physicalChannel
        existing.updatedAt = self:Now()
        return true
    end

    while TotalCount(transport) >= MAX_QUEUED do
        if not DropOldestBulk(transport) then
            metrics.dropped = metrics.dropped + 1
            return false
        end
        metrics.dropped = metrics.dropped + 1
    end

    transport.sequence = transport.sequence + 1
    local item = {
        payload = payload,
        channel = channel,
        target = target,
        wirePayload = wirePayload,
        physicalChannel = physicalChannel,
        priority = priority,
        source = source,
        retries = 0,
        queuedAt = self:Now(),
        sequence = transport.sequence,
        coalesceKey = coalesceKey,
    }
    Push(QueueFor(transport, priority), item)
    if coalesceKey then transport.coalesced[coalesceKey] = item end
    metrics.queued = metrics.queued + 1
    if channel == "WHISPER" then metrics.targetedQueued = (metrics.targetedQueued or 0) + 1 end
    transport.highWater = math.max(transport.highWater or 0, TotalCount(transport))
    return true
end

function OTLGM:GetNetworkPayloadLimit(channel, target)
    if channel ~= "WHISPER" then return MAX_PAYLOAD end
    target = NormalizeTarget(target)
    if not target then return 0 end
    return math.max(0, MAX_PAYLOAD - string.len(TARGET_ENVELOPE) - string.len(target) - 1)
end

function OTLGM:GetNetworkQueueDepth()
    local transport = EnsureTransport(self)
    return TotalCount(transport), transport.critical.count, transport.normal.count, transport.bulk.count
end

function OTLGM:CanQueueNetworkPayloads(amount, reserve)
    local transport = EnsureTransport(self)
    amount = math.max(0, tonumber(amount) or 0)
    reserve = math.max(0, tonumber(reserve) or 12)
    return TotalCount(transport) + amount <= MAX_QUEUED - reserve
end

function OTLGM:ProcessNetworkQueue(maximum)
    if not SendAddonMessage then return 0 end
    local transport, metrics = EnsureTransport(self)
    local settings = OTLGM_DB and OTLGM_DB.settings or {}
    maximum = tonumber(maximum) or tonumber(settings.networkPacketBudget) or 5
    maximum = math.max(1, math.min(8, maximum))
    local pauseBulk = settings.pauseBulkSyncInCombat ~= false and self:InCombat()
    local sent = 0
    local now = self:Now()
    if (tonumber(transport.nextAttemptAt) or 0) > now then return 0 end

    while sent < maximum do
        local item = Pop(transport.critical, now)
        if not item then item = Pop(transport.normal, now) end
        if not item and not pauseBulk then item = Pop(transport.bulk, now) end
        if not item then break end

        if item.coalesceKey then transport.coalesced[item.coalesceKey] = nil end
        local wirePayload = item.wirePayload
        local physicalChannel = item.physicalChannel
        if not wirePayload then wirePayload, physicalChannel = WirePacket(item.payload, item.channel, item.target) end
        local ok, problem = pcall(SendAddonMessage, "OTLGM", wirePayload, physicalChannel or item.channel)
        if ok then
            metrics.sent = metrics.sent + 1
            if item.channel == "WHISPER" then metrics.targetedRouted = (metrics.targetedRouted or 0) + 1 end
            if metrics.lastError then
                metrics.recovered = (metrics.recovered or 0) + 1
                metrics.lastRecoveredError = metrics.lastError
                metrics.lastRecoveredAt = now
                metrics.lastError = nil
                metrics.lastErrorAt = nil
                metrics.lastErrorChannel = nil
                metrics.lastErrorSource = nil
            end
            transport.consecutiveFailures = 0
            transport.nextAttemptAt = nil
            sent = sent + 1
        else
            item.retries = (item.retries or 0) + 1
            transport.consecutiveFailures = (tonumber(transport.consecutiveFailures) or 0) + 1
            local delay = RETRY_DELAYS[item.retries] or RETRY_DELAYS[table.getn(RETRY_DELAYS)]
            transport.nextAttemptAt = now + delay
            metrics.lastError = self:Utf8Truncate(tostring(problem or "unknown transport error"), 180)
            metrics.lastErrorAt = now
            metrics.lastErrorChannel = item.channel
            metrics.lastErrorSource = item.source
            if item.retries <= MAX_RETRIES then
                item.due = now + delay
                Push(QueueFor(transport, item.priority), item)
                if item.coalesceKey then transport.coalesced[item.coalesceKey] = item end
                metrics.retried = metrics.retried + 1
            else
                metrics.dropped = metrics.dropped + 1
            end
            sent = sent + 1
            -- One failing C API call is enough for this heartbeat. Continuing
            -- through the queue only amplifies a throttle or compatibility
            -- error and used to generate hundreds of retries in a few minutes.
            break
        end
    end
    return sent
end

-- Compatibility entry points used by existing feature code. They no longer own
-- independent queues, so PvE and professions cannot exceed a shared budget.
function OTLGM:QueuePvePayload(payload, channel, target, coalesceKey)
    return self:QueueNetworkPayload(payload, channel, target, ClassifyPve(payload), "pve", coalesceKey)
end

function OTLGM:QueueCommunityPayload(payload, channel, target, priority, coalesceKey)
    return self:QueueNetworkPayload(payload, channel, target, ClassifyCommunity(payload, priority), "community", coalesceKey)
end

OTLGM:RegisterModule("Transport", {
    payloadLimit = MAX_PAYLOAD,
    targetedEnvelope = TARGET_ENVELOPE,
    queueLimit = MAX_QUEUED,
    priorities = { critical = PRIORITY_CRITICAL, normal = PRIORITY_NORMAL, bulk = PRIORITY_BULK },
})
