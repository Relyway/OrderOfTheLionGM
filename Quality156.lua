-- Order of the Lion Guild Manager
-- v1.5.6 quality-of-life, raid planning, shared activity and interaction layer

OTLGM.version = "1.5.6"
OTLGM.quality156Loaded = true
OTLGM.schemaVersion = 11

local BaseHandleAddonMessage156 = OTLGM.HandleAddonMessage
local BaseEnsureCraftingDB156 = OTLGM.EnsureCraftingDB
local BaseGetCraftingSearchResults156 = OTLGM.GetCraftingSearchResults
local BaseBuildNextProfessionsPage156 = OTLGM.BuildNextProfessionsPage
local BaseRefreshCraftingRecipesPanel156 = OTLGM.RefreshCraftingRecipesPanel
local BaseBuildPvePage156 = OTLGM.BuildPvePage
local BaseRefreshPvePage156 = OTLGM.RefreshPvePage
local BaseRequestCraftingSync156 = OTLGM.RequestCraftingSync
local BaseRequestPveSync156 = OTLGM.RequestPveSync
local BaseRequestScan156 = OTLGM.RequestScan
local BaseScan156 = OTLGM.Scan
local BaseGetActivitySummary156 = OTLGM.GetActivitySummary
local BaseGetActivityHeatmap156 = OTLGM.GetActivityHeatmap
local BaseRefreshActivityPage156 = OTLGM.RefreshActivityPage
local BaseBuildActivityPage156 = OTLGM.BuildActivityPage
local BaseRefreshGuildChatPage156 = OTLGM.RefreshGuildChatPage
local BaseSerializePveRaid156 = OTLGM.SerializePveRaid
local BaseApplyRemotePveRaid156 = OTLGM.ApplyRemotePveRaid
local BasePurgePveData156 = OTLGM.PurgePveData
local BaseApplyRemotePveDelete156 = OTLGM.ApplyRemotePveDelete
local BaseQueuePveSyncResponse156 = OTLGM.QueuePveSyncResponse
local BaseGetPveRecordRevision156 = OTLGM.GetPveRecordRevision

local function QTrim(text)
    text = text or ""
    return string.gsub(text, "^%s*(.-)%s*$", "%1")
end

local function QNormalizeName(name)
    name = QTrim(name or "")
    name = string.gsub(name, "%-.*$", "")
    return string.lower(name)
end

-- Shared activity does not need to expose character names. A short stable
-- checksum is enough to de-duplicate samples from the same addon copy while
-- keeping packets compact and the statistics privacy-safe.
local function QActivitySourceId(name)
    name = QNormalizeName(name or "unknown")
    local hash = 17
    local i
    for i = 1, string.len(name) do hash = math.mod((hash * 33) + string.byte(name, i), 2176782336) end
    return string.format("%06x", math.mod(hash, 16777216))
end

local function QSplit156(text, delimiter)
    local result = {}
    text = tostring(text or "")
    delimiter = delimiter or ","
    local startAt = 1
    while true do
        local position = string.find(text, delimiter, startAt, true)
        if not position then table.insert(result, string.sub(text, startAt)) break end
        table.insert(result, string.sub(text, startAt, position - 1))
        startAt = position + string.len(delimiter)
    end
    return result
end

local function QSafe(text, maxLength)
    text = QTrim(text or "")
    text = string.gsub(text, "[\r\n\t]", " ")
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "%^", "'")
    if maxLength and string.len(text) > maxLength then text = string.sub(text, 1, maxLength) end
    return text
end

local function QPanel(parent, x, y, width, height)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.018, 0.016, 0.013, 0.98)
    frame:SetBackdropBorderColor(0.42, 0.30, 0.14, 1)
    return frame
end

local function QText(parent, template, text, x, y, width, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetWidth(width or 100)
    fs:SetJustifyH(justify or "LEFT")
    fs:SetText(text or "")
    return fs
end

local function QWrapped(parent, template, text, x, y, width, height)
    local fs = QText(parent, template or "GameFontNormalSmall", text, x, y, width, "LEFT")
    fs:SetHeight(height or 40)
    fs:SetJustifyV("TOP")
    return fs
end

local function QButton(parent, text, x, y, width, height, onclick, kind)
    local button = CreateFrame("Button", nil, parent)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    button.kind156 = kind or "normal"
    button.label156 = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.label156:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.label156:SetWidth(width - 8)
    button.label156:SetText(text or "")
    button:SetScript("OnClick", onclick)
    button:SetScript("OnEnter", function()
        this.hover156 = true
        if this.disabledReason156 and not this.enabled156 then
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:AddLine(this.disabledReason156, 1, 0.82, 0.35, true)
            GameTooltip:Show()
        end
        OTLGM:ApplyQButton156(this)
    end)
    button:SetScript("OnLeave", function()
        this.hover156 = nil
        GameTooltip:Hide()
        OTLGM:ApplyQButton156(this)
    end)
    button.enabled156 = true
    OTLGM:ApplyQButton156(button)
    return button
end

function OTLGM:ApplyQButton156(button)
    if not button then return end
    local enabled = button.enabled156 ~= false
    local selected = button.selected156 and true or false
    local r, g, b = 0.08, 0.045, 0.02
    local br, bg, bb = 0.52, 0.34, 0.13
    if button.kind156 == "confirm" then r, g, b = 0.015, 0.11, 0.035 br, bg, bb = 0.10, 0.58, 0.24 end
    if button.kind156 == "danger" then r, g, b = 0.12, 0.025, 0.018 br, bg, bb = 0.68, 0.18, 0.10 end
    if button.kind156 == "utility" then r, g, b = 0.018, 0.055, 0.10 br, bg, bb = 0.16, 0.45, 0.72 end
    if selected then r, g, b = 0.17, 0.10, 0.025 br, bg, bb = 0.92, 0.64, 0.20 end
    if button.hover156 and enabled then r, g, b = r + 0.04, g + 0.03, b + 0.02 end
    if not enabled then r, g, b, br, bg, bb = 0.018, 0.018, 0.018, 0.18, 0.18, 0.18 end
    button:SetBackdropColor(r, g, b, enabled and 0.98 or 0.70)
    button:SetBackdropBorderColor(br, bg, bb, 1)
    if button.label156 then
        if enabled then button.label156:SetTextColor(1, 0.82, 0.30) else button.label156:SetTextColor(0.38, 0.38, 0.38) end
    end
    if enabled then button:Enable() else button:Disable() end
end

local function QSetButton(button, text, enabled, reason, selected)
    if not button then return end
    if text and button.label156 then button.label156:SetText(text) end
    button.enabled156 = enabled ~= false
    button.disabledReason156 = reason
    button.selected156 = selected and true or false
    OTLGM:ApplyQButton156(button)
end

-- Base UI buttons and v1.5.x extension buttons use a different visual helper.
-- This common setter makes long operations unmistakable and prevents repeated
-- clicks even when the original button script only checks its `disabled` flag.
local function QSetOperationButton156(button, text, state, reason)
    if not button then return end
    state = state or "IDLE"
    if button.text then button.text:SetText(text or "") end
    if button.label156 then button.label156:SetText(text or "") end
    button.labelText = text or button.labelText
    button.disabled = state == "WORKING"
    button.enabled156 = state ~= "WORKING"
    button.disabledReason = reason
    button.disabledReason156 = reason
    if state == "WORKING" then
        button:Disable()
        if button.SetBackdropColor then button:SetBackdropColor(0.025, 0.085, 0.16, 1) button:SetBackdropBorderColor(0.30, 0.66, 1.0, 1) end
        if button.text then button.text:SetTextColor(0.70, 0.88, 1.0) end
    elseif state == "DONE" then
        button:Enable()
        if button.SetBackdropColor then button:SetBackdropColor(0.025, 0.16, 0.055, 1) button:SetBackdropBorderColor(0.25, 0.78, 0.36, 1) end
        if button.text then button.text:SetTextColor(0.66, 1.0, 0.70) end
    elseif state == "ERROR" then
        button:Enable()
        if button.SetBackdropColor then button:SetBackdropColor(0.20, 0.025, 0.020, 1) button:SetBackdropBorderColor(0.72, 0.18, 0.12, 1) end
        if button.text then button.text:SetTextColor(1.0, 0.58, 0.48) end
    else
        button:Enable()
        if button.label156 then OTLGM:ApplyQButton156(button)
        elseif button.SetBackdropColor then
            button:SetBackdropColor(0.022, 0.075, 0.15, 1)
            button:SetBackdropBorderColor(0.24, 0.45, 0.72, 1)
            if button.text then button.text:SetTextColor(0.61, 0.79, 1.0) end
        end
    end
end

local function QEdit(parent, name, x, y, width, height, maxLetters)
    local edit = CreateFrame("EditBox", name, parent)
    edit:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    edit:SetWidth(width)
    edit:SetHeight(height)
    edit:SetAutoFocus(false)
    edit:SetFontObject("GameFontHighlight")
    edit:SetTextInsets(8, 8, 0, 0)
    edit:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    edit:SetBackdropColor(0.01, 0.01, 0.01, 1)
    edit:SetBackdropBorderColor(0.45, 0.32, 0.15, 1)
    if maxLetters then edit:SetMaxLetters(maxLetters) end
    edit:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    return edit
end

local function QHide(frame)
    if frame then frame:Hide() end
end

-- ---------------------------------------------------------------------------
-- Unified operation feedback
-- ---------------------------------------------------------------------------

function OTLGM:EnsureOperationState156()
    self.operationState156 = self.operationState156 or {}
    return self.operationState156
end

function OTLGM:SetOperationState156(key, state, detail, duration)
    local states = self:EnsureOperationState156()
    states[key] = { state = state or "IDLE", detail = detail or "", ts = self:Now(), untilTs = duration and (self:Now() + duration) or nil }
    self:RefreshOperationButtons156()
end

function OTLGM:GetOperationState156(key)
    local states = self:EnsureOperationState156()
    local item = states[key]
    if item and item.untilTs and self:Now() >= item.untilTs then states[key] = nil item = nil end
    return item or { state = "IDLE", detail = "" }
end

function OTLGM:RefreshOperationButtons156()
    if not self.ui then return end
    local scan = self:GetOperationState156("ROSTER")
    if self.ui.scanButton then
        local label = "Update Roster"
        if scan.state == "WORKING" then label = "Updating..." elseif scan.state == "DONE" then label = "Roster Updated" elseif scan.state == "ERROR" then label = "Retry Roster" end
        QSetOperationButton156(self.ui.scanButton, label, scan.state, scan.detail ~= "" and scan.detail or "Roster update is already running. Please wait.")
    end
    local craft = self:GetOperationState156("CRAFTING")
    if self.ui.craftingSyncButton then
        local label = "Sync Now"
        if craft.state == "WORKING" then label = "Syncing..." elseif craft.state == "DONE" then label = "Sync Complete" elseif craft.state == "ERROR" then label = "Retry Sync" end
        QSetOperationButton156(self.ui.craftingSyncButton, label, craft.state, craft.detail ~= "" and craft.detail or "Crafting synchronization is already running.")
        if self.ui.craftingNetworkText and craft.state == "WORKING" then self.ui.craftingNetworkText:SetText(self.colors.gold .. (craft.detail ~= "" and craft.detail or "Synchronizing profession data...") .. self.colors.reset) end
        if self.ui.craftingNetworkText and craft.state == "DONE" then self.ui.craftingNetworkText:SetText(self.colors.green .. (craft.detail ~= "" and craft.detail or "Synchronization complete") .. self.colors.reset) end
        if self.ui.craftingNetworkText and craft.state == "ERROR" then self.ui.craftingNetworkText:SetText(self.colors.red .. (craft.detail ~= "" and craft.detail or "Synchronization failed") .. self.colors.reset) end
    end
    local pve = self:GetOperationState156("PVE")
    local buttons = { self.ui.pveSyncButton, self.ui.guildBoardSync152 }
    local i, button
    for i = 1, table.getn(buttons) do
        button = buttons[i]
        if button then
            local label = pve.state == "WORKING" and "Syncing..." or (pve.state == "DONE" and "Synced" or "Sync Now")
            QSetOperationButton156(button, label, pve.state, pve.detail ~= "" and pve.detail or "PvE synchronization is already running.")
        end
    end
    if self.ui.pveNetworkText and pve.state == "WORKING" then self.ui.pveNetworkText:SetText(self.colors.gold .. (pve.detail ~= "" and pve.detail or "Synchronizing PvE data...") .. self.colors.reset) end
    if self.ui.pveNetworkText and pve.state == "DONE" then self.ui.pveNetworkText:SetText(self.colors.green .. (pve.detail ~= "" and pve.detail or "PvE synchronization complete") .. self.colors.reset) end
    if self.ui.pveNetworkText and pve.state == "ERROR" then self.ui.pveNetworkText:SetText(self.colors.red .. (pve.detail ~= "" and pve.detail or "PvE synchronization failed") .. self.colors.reset) end

    local activity = self:GetOperationState156("ACTIVITY")
    if self.ui.activitySync156 then
        local label = "Sync Shared Activity"
        if activity.state == "WORKING" then label = "Syncing Activity..."
        elseif activity.state == "DONE" then label = "Activity Synced"
        elseif activity.state == "ERROR" then label = "Retry Activity Sync" end
        QSetOperationButton156(self.ui.activitySync156, label, activity.state, activity.detail ~= "" and activity.detail or "Shared activity synchronization is already running.")
    end
end

function OTLGM:RequestScan(reason)
    local state = self:GetOperationState156("ROSTER")
    if state.state == "WORKING" then if self.SetStatus then self:SetStatus("Roster update is already running. Please wait.") end return false end
    self:SetOperationState156("ROSTER", "WORKING", "Requesting guild roster")
    local result = BaseRequestScan156(self, reason)
    if not self.pendingScan then self:SetOperationState156("ROSTER", "ERROR", "Roster request could not start", 4) end
    return result
end

function OTLGM:Scan(reason)
    local ok, a, b, c = pcall(BaseScan156, self, reason)
    if not ok then
        self:SetOperationState156("ROSTER", "ERROR", tostring(a), 6)
        error(a)
    end
    local db = self:GetGuildDB()
    self:SetOperationState156("ROSTER", "DONE", "Roster updated: " .. tostring(db and db.lastTotal or 0), 4)
    if self.RecordSharedActivity156 then self:RecordSharedActivity156(true) end
    return a, b, c
end

function OTLGM:RequestCraftingSync(force)
    local state = self:GetOperationState156("CRAFTING")
    if state.state == "WORKING" then if self.SetStatus then self:SetStatus("Crafting synchronization is already running.") end return false end
    local ok = BaseRequestCraftingSync156(self, force)
    if ok then self:SetOperationState156("CRAFTING", "WORKING", "Waiting for profession snapshots")
    else self:SetOperationState156("CRAFTING", "ERROR", "No synchronization request was started", 4) end
    return ok
end

function OTLGM:RequestPveSync(force)
    local state = self:GetOperationState156("PVE")
    if state.state == "WORKING" then if self.SetStatus then self:SetStatus("PvE synchronization is already running.") end return false end
    local ok = BaseRequestPveSync156(self, force)
    if ok then self:SetOperationState156("PVE", "WORKING", "Requesting raid, group and application data")
    else self:SetOperationState156("PVE", "ERROR", "No synchronization request was started", 4) end
    return ok
end

-- ---------------------------------------------------------------------------
-- Shared, privacy-safe activity coverage
-- ---------------------------------------------------------------------------

function OTLGM:EnsureSharedActivity156()
    local db = self:GetGuildDB()
    if not db then return nil end
    db.sharedActivity156 = db.sharedActivity156 or { buckets = {}, sources = {}, lastBroadcast = 0, lastSync = 0 }
    return db.sharedActivity156
end

function OTLGM:ActivityBucket156(timestamp)
    timestamp = tonumber(timestamp) or self:Now()
    return math.floor(timestamp / 900) * 900
end

function OTLGM:StoreSharedActivity156(bucket, online, source, received, deferRefresh)
    local shared = self:EnsureSharedActivity156()
    if not shared then return false end
    bucket = tonumber(bucket) or 0
    online = math.max(0, math.min(999, tonumber(online) or 0))
    if bucket <= 0 or bucket < self:Now() - (30 * 86400) or bucket > self:Now() + 1800 then return false end
    source = QNormalizeName(source or "Unknown")
    local item = shared.buckets[bucket]
    if not item then item = { ts = bucket, values = {}, sum = 0, count = 0, max = 0 } shared.buckets[bucket] = item end
    if item.values[source] == online then return true end
    item.values[source] = online
    item.sum, item.count, item.max = 0, 0, 0
    local name, value
    for name, value in pairs(item.values) do
        item.sum = item.sum + (tonumber(value) or 0)
        item.count = item.count + 1
        if (tonumber(value) or 0) > item.max then item.max = tonumber(value) or 0 end
    end
    shared.sources[source] = self:Now()
    if received and not deferRefresh then
        self:SetOperationState156("ACTIVITY", "DONE", "Shared activity updated", 4)
        if self.ui and self.ui.currentPage == "activity" and self.RefreshActivityPage then self:RefreshActivityPage() end
    end
    return true
end

function OTLGM:RecordSharedActivity156(force)
    local db = self:GetGuildDB()
    local shared = self:EnsureSharedActivity156()
    if not db or not shared then return false end
    local bucket = self:ActivityBucket156(self:Now())
    local online = tonumber(db.lastOnline) or 0
    local sourceId = QActivitySourceId(UnitName("player") or "Unknown")
    shared.localSource156 = sourceId
    self:StoreSharedActivity156(bucket, online, sourceId, false)
    if force or bucket > (shared.lastBroadcast or 0) then
        shared.lastBroadcast = bucket
        if self.QueueCommunityPayload then
            self:QueueCommunityPayload(table.concat({ "S2", "ACT", tostring(bucket), tostring(online), sourceId, self.version or "?" }, "^"), "GUILD", nil, 1)
        end
    end
    local cutoff = self:Now() - (30 * 86400)
    local key
    for key in pairs(shared.buckets) do if tonumber(key) < cutoff then shared.buckets[key] = nil end end
    return true
end

function OTLGM:RequestSharedActivitySync156(force)
    local shared = self:EnsureSharedActivity156()
    if not shared or not self.QueueCommunityPayload then return false end
    if self:GetOperationState156("ACTIVITY").state == "WORKING" then
        if self.SetStatus then self:SetStatus("Shared activity synchronization is already running.") end
        return false
    end
    local now = self:Now()
    if not force and now - (shared.lastSync or 0) < 300 then return false end
    shared.lastSync = now
    shared.syncReceived156 = 0
    self:QueueCommunityPayload(table.concat({ "S2", "SYNC", tostring(now), self.version or "?" }, "^"), "GUILD", nil, 1)
    return true
end

function OTLGM:QueueSharedActivityTo156(target)
    local shared = self:EnsureSharedActivity156()
    if not shared or not target or not self.QueueCommunityPayload then return end
    -- A full 14-day reply used to require up to 1,344 tiny packets. v1.5.6
    -- sends one compact hourly summary per day (at most 14 packets per user).
    -- Live 15-minute ACT packets retain short-term detail between full syncs.
    local sourceId = shared.localSource156 or QActivitySourceId(UnitName("player") or "Unknown")
    shared.localSource156 = sourceId
    local today = math.floor(self:Now() / 86400) * 86400
    local dayOffset, hour, quarter, bucket, item, value
    for dayOffset = 13, 0, -1 do
        local dayStart = today - (dayOffset * 86400)
        local values = {}
        local hasData = false
        for hour = 0, 23 do
            local sum, count = 0, 0
            for quarter = 0, 3 do
                bucket = dayStart + (hour * 3600) + (quarter * 900)
                item = shared.buckets[bucket]
                value = item and item.values and item.values[sourceId]
                if value == nil and item and item.values then
                    -- Migration fallback for samples collected before the
                    -- anonymous source ID was introduced in this build.
                    value = item.values[QNormalizeName(UnitName("player") or "Unknown")]
                end
                if value ~= nil then sum = sum + (tonumber(value) or 0) count = count + 1 end
            end
            if count > 0 then values[hour + 1] = tostring(math.floor((sum / count) + 0.5)) hasData = true
            else values[hour + 1] = "-" end
        end
        if hasData then
            self:QueueCommunityPayload(table.concat({ "S2", "DAY", tostring(dayStart), sourceId, table.concat(values, ","), self.version or "?" }, "^"), "WHISPER", target, 0)
        end
    end
end

function OTLGM:HandleSharedActivityMessage156(message, channel, sender)
    local protocol = string.sub(message or "", 1, 2)
    if protocol ~= "S1" and protocol ~= "S2" then return false end
    local fields = {}
    local startAt = 1
    while true do
        local p = string.find(message, "^", startAt, true)
        if not p then table.insert(fields, string.sub(message, startAt)) break end
        table.insert(fields, string.sub(message, startAt, p - 1))
        startAt = p + 1
    end
    if fields[2] == "ACT" then return self:StoreSharedActivity156(fields[3], fields[4], fields[5] ~= "" and fields[5] or QActivitySourceId(sender), true) end
    if fields[2] == "DAY" and protocol == "S2" then
        local dayStart = tonumber(fields[3]) or 0
        local sourceId = fields[4] ~= "" and fields[4] or QActivitySourceId(sender)
        local values = QSplit156(fields[5] or "", ",")
        local shared = self:EnsureSharedActivity156()
        if shared then shared.syncReceived156 = (shared.syncReceived156 or 0) + 1 end
        local hour, quarter, number
        for hour = 0, math.min(23, table.getn(values) - 1) do
            number = tonumber(values[hour + 1])
            if number then
                for quarter = 0, 3 do self:StoreSharedActivity156(dayStart + (hour * 3600) + (quarter * 900), number, sourceId, true, true) end
            end
        end
        self:SetOperationState156("ACTIVITY", "DONE", "Shared activity updated", 4)
        if self.ui and self.ui.currentPage == "activity" and self.RefreshActivityPage then self:RefreshActivityPage() end
        return true
    end
    if fields[2] == "SYNC" and sender then self:QueueSharedActivityTo156(sender) return true end
    return true
end

function OTLGM:HandleAddonMessage(prefix, message, channel, sender)
    local activityPrefix = string.sub(message or "", 1, 3)
    if prefix == "OTLGM" and (activityPrefix == "S1^" or activityPrefix == "S2^") then
        if self.RememberAddonUser then self:RememberAddonUser(sender, nil) end
        return self:HandleSharedActivityMessage156(message, channel, sender)
    end
    return BaseHandleAddonMessage156(self, prefix, message, channel, sender)
end

function OTLGM:GetSharedActivityStats156(days)
    local shared = self:EnsureSharedActivity156()
    local result = { average = 0, peak = 0, samples = 0, coverage = 0, sources = 0 }
    if not shared then return result end
    local cutoff = self:Now() - ((days or 7) * 86400)
    local expected = math.max(1, math.floor(((days or 7) * 86400) / 900))
    local sum, count = 0, 0
    local ts, item
    for ts, item in pairs(shared.buckets or {}) do
        if tonumber(ts) >= cutoff and item.count and item.count > 0 then
            local value = item.sum / item.count
            sum = sum + value
            count = count + 1
            if value > result.peak then result.peak = value end
        end
    end
    local source
    for source, ts in pairs(shared.sources or {}) do if ts >= cutoff then result.sources = result.sources + 1 end end
    result.samples = count
    if count > 0 then result.average = sum / count end
    result.coverage = math.min(100, math.floor((count / expected) * 100 + 0.5))
    return result
end

function OTLGM:GetActivitySummary(days)
    local result = BaseGetActivitySummary156(self, days)
    local shared = self:GetSharedActivityStats156(days or 7)
    if shared.samples > 0 then
        result.average = shared.average
        result.samples = shared.samples
        if shared.peak > (result.periodPeak or 0) then result.periodPeak = shared.peak result.periodPeakAt = nil end
        result.sharedCoverage156 = shared.coverage
        result.sharedSources156 = shared.sources
    end
    return result
end

function OTLGM:GetActivityHeatmap()
    local matrix, maxValue = BaseGetActivityHeatmap156(self)
    local shared = self:EnsureSharedActivity156()
    if not shared then return matrix, maxValue end
    local sums, counts = {}, {}
    local d, s
    for d = 0, 6 do sums[d] = {} counts[d] = {} for s = 0, 7 do sums[d][s] = 0 counts[d][s] = 0 end end
    local ts, item, value, weekday, hour, slot
    for ts, item in pairs(shared.buckets or {}) do
        if tonumber(ts) >= self:Now() - (30 * 86400) and item.count and item.count > 0 then
            value = item.sum / item.count
            weekday = tonumber(date("%w", tonumber(ts))) or 0
            hour = tonumber(date("%H", tonumber(ts))) or 0
            slot = math.floor(hour / 3)
            sums[weekday][slot] = sums[weekday][slot] + value
            counts[weekday][slot] = counts[weekday][slot] + 1
        end
    end
    for d = 0, 6 do
        for s = 0, 7 do
            if counts[d][s] > 0 then matrix[d][s] = sums[d][s] / counts[d][s] end
            if matrix[d][s] > maxValue then maxValue = matrix[d][s] end
        end
    end
    return matrix, maxValue
end

function OTLGM:BuildActivityPage(page)
    BaseBuildActivityPage156(self, page)
    self.ui.activitySync156 = QButton(page, "Sync Shared Activity", 348, -502, 172, 28, function()
        if OTLGM:RequestSharedActivitySync156(true) then
            OTLGM:SetOperationState156("ACTIVITY", "WORKING", "Requesting shared online intervals")
            OTLGM:SetStatus("Requesting shared activity samples from online addon users...")
        end
    end, "utility")
    self.ui.activityCoverage156 = QText(page, "GameFontNormalSmall", "", 348, -476, 360, "LEFT")
    self.ui.activityCoverage156:SetTextColor(0.60, 0.60, 0.58)
end

function OTLGM:RefreshActivityPage()
    BaseRefreshActivityPage156(self)
    local summary = self:GetActivitySummary(7)
    if self.ui and self.ui.activityCards and self.ui.activityCards.average then
        local coverage = tonumber(summary.sharedCoverage156) or 0
        local sources = tonumber(summary.sharedSources156) or 0
        self.ui.activityCards.average.sub:SetText(tostring(summary.samples or 0) .. " shared intervals  •  " .. tostring(coverage) .. "% coverage  •  " .. tostring(sources) .. " sources")
        if self.ui.activityCoverage156 then self.ui.activityCoverage156:SetText("Shared coverage: " .. tostring(coverage) .. "%  •  Sources seen: " .. tostring(sources) .. "  •  No player names are shared") end
        if self.ui.activitySync156 then
            local state = self:GetOperationState156("ACTIVITY")
            QSetButton(self.ui.activitySync156, state.state == "WORKING" and "Syncing Activity..." or (state.state == "DONE" and "Activity Synced" or "Sync Shared Activity"), state.state ~= "WORKING", "A shared activity sync is already running.")
        end
    end
end

-- ---------------------------------------------------------------------------
-- Profession key repair and simplified controls
-- ---------------------------------------------------------------------------

function OTLGM:NormalizeProfessionKey156(key, label)
    local text = string.lower(tostring(key or "") .. " " .. tostring(label or ""))
    text = string.gsub(text, "[^a-z]", "")
    if string.find(text, "blacksmith", 1, true) then return "BLACKSMITHING" end
    if string.find(text, "alchemy", 1, true) then return "ALCHEMY" end
    if string.find(text, "cooking", 1, true) or string.find(text, "cook", 1, true) then return "COOKING" end
    if string.find(text, "enchant", 1, true) then return "ENCHANTING" end
    if string.find(text, "engineer", 1, true) then return "ENGINEERING" end
    if string.find(text, "jewel", 1, true) then return "JEWELCRAFTING" end
    if string.find(text, "leather", 1, true) then return "LEATHERWORKING" end
    if string.find(text, "tailor", 1, true) then return "TAILORING" end
    if string.find(text, "mining", 1, true) or string.find(text, "smelt", 1, true) then return "MINING" end
    if string.upper(key or "") == "ALL" then return "ALL" end
    return string.upper(key or "")
end

function OTLGM:RepairCraftingProfessionIndex156(craft)
    if not craft or not craft.characters then return end
    local characterName, character, oldKey, profession
    for characterName, character in pairs(craft.characters) do
        local rebuilt = {}
        for oldKey, profession in pairs(character.professions or {}) do
            local key = self:NormalizeProfessionKey156(oldKey, profession and profession.label)
            if key ~= "" then
                profession.key = key
                if rebuilt[key] and rebuilt[key] ~= profession then
                    local recipeKey, recipe
                    rebuilt[key].recipes = rebuilt[key].recipes or {}
                    for recipeKey, recipe in pairs(profession.recipes or {}) do rebuilt[key].recipes[recipeKey] = recipe end
                    if (profession.ts or 0) > (rebuilt[key].ts or 0) then rebuilt[key].ts = profession.ts end
                else rebuilt[key] = profession end
            end
        end
        character.professions = rebuilt
    end
    craft.professionIndexVersion156 = 1
end

function OTLGM:EnsureCraftingDB()
    local craft = BaseEnsureCraftingDB156(self)
    if craft and craft.professionIndexVersion156 ~= 1 then self:RepairCraftingProfessionIndex156(craft) end
    return craft
end

function OTLGM:GetCraftingSearchResults(query, professionFilter)
    local craft = self:EnsureCraftingDB()
    professionFilter = self:NormalizeProfessionKey156(professionFilter or "ALL")
    return BaseGetCraftingSearchResults156(self, query, professionFilter)
end

function OTLGM:BuildNextProfessionsPage(page)
    BaseBuildNextProfessionsPage156(self, page)
    self:BuildProfessionQOL156(page)
end

function OTLGM:BuildProfessionQOL156(page)
    if self.ui.professionQOL156 then return end
    self.ui.professionQOL156 = true
    if self.ui.craftingSearchClear then self.ui.craftingSearchClear:Hide() end
    if self.ui.craftingSearchEdit then self.ui.craftingSearchEdit:SetWidth(278) end
    local recipes = self.ui.craftingSearchEdit and self.ui.craftingSearchEdit:GetParent()
    if not recipes then return end
    self.ui.craftingSearchX156 = QButton(recipes, "X", 290, -10, 24, 30, function()
        OTLGM.ui.craftingSearchEdit:SetText("")
        OTLGM.ui.craftingSearchEdit:ClearFocus()
        OTLGM.ui.craftingRecipeOffset = 0
        OTLGM:RefreshProfessionsPage()
    end, "utility")

    QHide(self.ui.craftingCategoryPrev153)
    QHide(self.ui.craftingCategoryNext153)
    if self.ui.craftingCategoryButtons153 and self.ui.craftingCategoryButtons153[4] then self.ui.craftingCategoryButtons153[4]:Hide() end
    self.ui.craftingCategoryMore156 = QButton(recipes, "More", 218, -48, 96, 26, function()
        local panel = OTLGM.ui.craftingCategoryPanel156
        if panel:IsVisible() then panel:Hide() else OTLGM:RefreshCategoryMore156() panel:Show() end
    end, "utility")
    local categoryPanel = QPanel(recipes, 114, -78, 200, 164)
    categoryPanel:SetFrameLevel(recipes:GetFrameLevel() + 32)
    categoryPanel:Hide()
    self.ui.craftingCategoryPanel156 = categoryPanel
    self.ui.craftingCategoryMoreRows156 = {}
    local categoryRow
    for categoryRow = 1, 6 do
        local capturedCategoryRow = categoryRow
        self.ui.craftingCategoryMoreRows156[categoryRow] = QButton(categoryPanel, "", 8, -8 - ((categoryRow - 1) * 25), 184, 23, function()
            local row = OTLGM.ui.craftingCategoryMoreRows156[capturedCategoryRow]
            if row and row.categoryKey156 then
                OTLGM_DB.settings.craftingCategory153 = row.categoryKey156
                OTLGM.ui.craftingRecipeOffset = 0
                OTLGM.ui.craftingSelectedRecipe = nil
                OTLGM.ui.craftingCategoryPanel156:Hide()
                OTLGM:RefreshProfessionsPage()
            end
        end, "normal")
    end

    QHide(self.ui.craftingLevelFilter153)
    QHide(self.ui.craftingRarityFilter153)
    QHide(self.ui.craftingSortFilter153)
    QHide(self.ui.craftingOnlineFilter153)
    self.ui.craftingFiltersButton156 = QButton(recipes, "Filters", 10, -78, 94, 26, function()
        local panel = OTLGM.ui.craftingFiltersPanel156
        if panel:IsVisible() then panel:Hide() else panel:Show() end
    end, "utility")
    self.ui.craftingFilterSummary156 = QText(recipes, "GameFontNormalSmall", "Any level • Any rarity • Online first", 112, -84, 198, "LEFT")
    self.ui.craftingFilterSummary156:SetTextColor(0.62, 0.62, 0.60)

    local filterPanel = QPanel(recipes, 10, -108, 304, 128)
    filterPanel:SetFrameLevel(recipes:GetFrameLevel() + 30)
    filterPanel:Hide()
    self.ui.craftingFiltersPanel156 = filterPanel
    QText(filterPanel, "GameFontNormalSmall", "FILTERS", 10, -8, 280, "LEFT")
    local levelValues = { "ANY", "1_20", "21_40", "41_59", "60", "UNKNOWN" }
    local rarityValues = { "ANY", "COMMON", "UNCOMMON", "RARE", "EPIC", "UNKNOWN" }
    local sortValues = { "ONLINE", "RECENT", "NAME", "LEVEL", "RARITY", "CRAFTERS" }
    local function Cycle(setting, values)
        local current = OTLGM_DB.settings[setting]
        local i
        for i = 1, table.getn(values) do if values[i] == current then OTLGM_DB.settings[setting] = values[math.mod(i, table.getn(values)) + 1] OTLGM:RefreshProfessionsPage() return end end
        OTLGM_DB.settings[setting] = values[1]
        OTLGM:RefreshProfessionsPage()
    end
    self.ui.qLevel156 = QButton(filterPanel, "Level", 10, -34, 88, 26, function() Cycle("craftingLevelFilter153", levelValues) end, "utility")
    self.ui.qRarity156 = QButton(filterPanel, "Rarity", 106, -34, 88, 26, function() Cycle("craftingRarityFilter153", rarityValues) end, "utility")
    self.ui.qSort156 = QButton(filterPanel, "Sort", 202, -34, 88, 26, function() Cycle("craftingSort153", sortValues) end, "utility")
    self.ui.qOnline156 = QButton(filterPanel, "Online first", 10, -66, 136, 26, function()
        OTLGM_DB.settings.craftingOnlineOnly153 = not OTLGM_DB.settings.craftingOnlineOnly153
        OTLGM:RefreshProfessionsPage()
    end, "confirm")
    self.ui.qReset156 = QButton(filterPanel, "Reset", 154, -66, 136, 26, function()
        OTLGM_DB.settings.craftingLevelFilter153 = "ANY"
        OTLGM_DB.settings.craftingRarityFilter153 = "ANY"
        OTLGM_DB.settings.craftingSort153 = "ONLINE"
        OTLGM_DB.settings.craftingOnlineOnly153 = false
        OTLGM_DB.settings.craftingCategory153 = "ALL"
        OTLGM:RefreshProfessionsPage()
    end, "normal")
    QWrapped(filterPanel, "GameFontNormalSmall", "Filters work locally and never trigger network traffic.", 10, -98, 280, 22):SetTextColor(0.50, 0.50, 0.48)

    QHide(self.ui.craftingWhisperButton)
    QHide(self.ui.craftingLinkButton)
    QHide(self.ui.craftingRecipeLinkButton152)
    local crafters = self.ui.craftingRequestButton and self.ui.craftingRequestButton:GetParent()
    if crafters then
        self.ui.craftingMore156 = QButton(crafters, "More", 10, -354, 64, 26, function()
            local menu = OTLGM.ui.craftingMorePanel156
            if menu:IsVisible() then menu:Hide() else menu:Show() end
        end, "utility")
        self.ui.craftingRequestButton:ClearAllPoints()
        self.ui.craftingRequestButton:SetPoint("TOPLEFT", crafters, "TOPLEFT", 80, -354)
        self.ui.craftingRequestButton:SetWidth(130)
        local more = QPanel(crafters, 10, -244, 200, 104)
        more:SetFrameLevel(crafters:GetFrameLevel() + 30)
        more:Hide()
        self.ui.craftingMorePanel156 = more
        self.ui.craftingMoreWhisper156 = QButton(more, "Whisper Crafter", 8, -8, 184, 24, function()
            more:Hide()
            if OTLGM.ui.craftingSelectedCrafter then OTLGM:OpenGuildChatWhisper(OTLGM.ui.craftingSelectedCrafter) end
        end, "utility")
        self.ui.craftingMoreItem156 = QButton(more, "Link Item", 8, -38, 88, 24, function()
            more:Hide()
            local result = OTLGM.ui.craftingSelectedRecipeData
            local link = result and OTLGM:GetCraftingItemLink154(result.recipe)
            if link then OTLGM:OpenGuildChatWithLink154(link) else OTLGM:ShowNotice("Item Link", "The item link is not cached yet.") end
        end, "utility")
        self.ui.craftingMoreRecipe156 = QButton(more, "Link Recipe", 104, -38, 88, 24, function()
            more:Hide()
            local result = OTLGM.ui.craftingSelectedRecipeData
            local link = result and OTLGM:GetCraftingRecipeLink154(result.recipe)
            if link then OTLGM:OpenGuildChatWithLink154(link) else OTLGM:ShowNotice("Recipe Link", "The crafter must reopen this profession to share the recipe link.") end
        end, "utility")
        self.ui.craftingMoreActivity156 = QButton(more, "Crafting Activity", 8, -68, 184, 24, function() more:Hide() OTLGM:OpenActivityDialog153("CRAFTING", "ALL") end, "normal")
    end
end

function OTLGM:RefreshCategoryMore156()
    if not self.ui or not self.ui.craftingCategoryMoreRows156 then return end
    local profession = OTLGM_DB.settings.craftingProfession or "ALL"
    local definitions = self:GetCraftingCategoryDefinitions153(profession) or {}
    local rowIndex = 1
    local i, definition, row
    for i = 4, table.getn(definitions) do
        row = self.ui.craftingCategoryMoreRows156[rowIndex]
        if row then
            definition = definitions[i]
            row.categoryKey156 = definition[1]
            row.label156:SetText(definition[2])
            row.selected156 = OTLGM_DB.settings.craftingCategory153 == definition[1]
            self:ApplyQButton156(row)
            row:Show()
            rowIndex = rowIndex + 1
        end
    end
    while rowIndex <= table.getn(self.ui.craftingCategoryMoreRows156) do
        self.ui.craftingCategoryMoreRows156[rowIndex].categoryKey156 = nil
        self.ui.craftingCategoryMoreRows156[rowIndex]:Hide()
        rowIndex = rowIndex + 1
    end
    if table.getn(definitions) <= 3 then self.ui.craftingCategoryMore156:Hide() else self.ui.craftingCategoryMore156:Show() end
end

function OTLGM:RefreshProfessionQOL156()
    if not self.ui or not self.ui.professionQOL156 then return end
    local level = OTLGM_DB.settings.craftingLevelFilter153 or "ANY"
    local rarity = OTLGM_DB.settings.craftingRarityFilter153 or "ANY"
    local sort = OTLGM_DB.settings.craftingSort153 or "ONLINE"
    local online = OTLGM_DB.settings.craftingOnlineOnly153 and "Online only" or "Online first"
    local label = (level == "ANY" and "Any level" or string.gsub(level, "_", "-")) .. " • " .. (rarity == "ANY" and "Any rarity" or string.lower(rarity)) .. " • " .. online
    if self.ui.craftingFilterSummary156 then self.ui.craftingFilterSummary156:SetText(label) end
    QSetButton(self.ui.qLevel156, "Level: " .. level, true)
    QSetButton(self.ui.qRarity156, "Rarity: " .. rarity, true)
    QSetButton(self.ui.qSort156, "Sort: " .. sort, true)
    QSetButton(self.ui.qOnline156, online, true, nil, OTLGM_DB.settings.craftingOnlineOnly153)
    if self.ui.craftingSearchX156 then if (self.ui.craftingSearchEdit:GetText() or "") == "" then self.ui.craftingSearchX156:Hide() else self.ui.craftingSearchX156:Show() end end
    if self.ui.craftingCategoryPrev153 then self.ui.craftingCategoryPrev153:Hide() end
    if self.ui.craftingCategoryNext153 then self.ui.craftingCategoryNext153:Hide() end
    if self.ui.craftingCategoryButtons153 and self.ui.craftingCategoryButtons153[4] then self.ui.craftingCategoryButtons153[4]:Hide() end
    self:RefreshCategoryMore156()

    local selected = self.ui.craftingSelectedRecipeData
    local itemLink = selected and self.GetCraftingItemLink154 and self:GetCraftingItemLink154(selected.recipe)
    local recipeLink = selected and self.GetCraftingRecipeLink154 and self:GetCraftingRecipeLink154(selected.recipe)
    QSetButton(self.ui.craftingMore156, "More", selected ~= nil, "Select a recipe first.")
    QSetButton(self.ui.craftingMoreWhisper156, "Whisper Crafter", selected ~= nil and self.ui.craftingSelectedCrafter ~= nil, "No crafter is selected for this recipe.")
    QSetButton(self.ui.craftingMoreItem156, "Link Item", itemLink ~= nil, "The item link is not cached yet.")
    QSetButton(self.ui.craftingMoreRecipe156, "Link Recipe", recipeLink ~= nil, "The crafter must reopen this profession to share its recipe link.")
end

function OTLGM:RefreshCraftingRecipesPanel(summary)
    BaseRefreshCraftingRecipesPanel156(self, summary)
    self:RefreshProfessionQOL156()
    local craft = self:EnsureCraftingDB()
    if craft and craft.syncState and craft.syncState.active then
        self:SetOperationState156("CRAFTING", "WORKING", "Received " .. tostring(craft.syncState.received or 0) .. " snapshots")
    elseif self:GetOperationState156("CRAFTING").state == "WORKING" then
        self:SetOperationState156("CRAFTING", "DONE", "Received " .. tostring(craft and craft.syncState and craft.syncState.received or 0) .. " snapshots", 4)
    end
end

-- ---------------------------------------------------------------------------
-- Raid data improvements
-- ---------------------------------------------------------------------------

function OTLGM:EnsureRaid156DB()
    local pve = self:EnsurePveDB()
    if not pve then return nil end
    pve.pastRaids156 = pve.pastRaids156 or {}
    pve.cancelledRaids156 = pve.cancelledRaids156 or {}
    return pve
end

-- The legacy PvE schema keeps a convenience `pve.raid` pointer.  EnsurePveDB
-- imports that pointer back into `pve.raids`, so a cancelled/deleted event can
-- otherwise resurrect itself.  Rebuild the pointer only from real upcoming
-- records and move any stale cancelled record out of the active table.
function OTLGM:RefreshNearestRaid155()
    local pve = self:EnsurePveDB()
    if not pve then return nil end
    pve.cancelledRaids156 = pve.cancelledRaids156 or {}
    local now = self:Now()
    local nearest
    local id, raid
    for id, raid in pairs(pve.raids or {}) do
        if raid.status == "CANCELLED" then
            pve.cancelledRaids156[id] = raid
            pve.raids[id] = nil
        else
            if raid.recurring == "WEEKLY" then
                while raid.startTs and raid.startTs + 14400 <= now do raid.startTs = raid.startTs + (7 * 86400) end
            end
            if raid.startTs and raid.startTs + 14400 > now and (not nearest or raid.startTs < nearest.startTs) then nearest = raid end
        end
    end
    pve.raid = nearest
    return nearest
end

function OTLGM:SerializePveRaid(record)
    -- Compact enough for the Vanilla 250-byte addon-message limit.
    return table.concat({
        self.pveProtocol, "RAID", QSafe(record.id, 30), tostring(record.rev or 1), tostring(record.ts or 0), tostring(record.startTs or 0),
        QSafe(record.author, 16), QSafe(record.name, 30), QSafe(record.location, 24), QSafe(record.serverTime, 22), QSafe(record.note, 32),
        QSafe(record.recurring or "ONCE", 8), tostring(record.reminderMinutes or 60), tostring(record.stHour or -1), tostring(record.stMinute or -1),
        QSafe(record.status or "UPCOMING", 10), tostring(record.gatherHour or -1), tostring(record.gatherMinute or -1), tostring(record.cancelledAt or 0)
    }, "^")
end

function OTLGM:ApplyRemotePveRaid(fields)
    local ok = BaseApplyRemotePveRaid156(self, fields)
    if not ok then return ok end
    local pve = self:EnsureRaid156DB()
    local id = fields[3] or ""
    local record = pve and pve.raids and pve.raids[id]
    if record then
        record.status = fields[16] or record.status or "UPCOMING"
        record.gatherHour = tonumber(fields[17]) or record.gatherHour
        record.gatherMinute = tonumber(fields[18]) or record.gatherMinute
        record.cancelledAt = tonumber(fields[19]) or record.cancelledAt
        if record.status == "CANCELLED" then
            if pve.raid and pve.raid.id == id then pve.raid = nil end
            pve.cancelledRaids156[id] = record
            pve.raids[id] = nil
        end
    end
    self:RefreshNearestRaid155()
    return true
end

function OTLGM:PublishPveRaidEvent156(data, existingId)
    if not self:IsOfficerMode() then return false, "Only leadership can publish raid events." end
    local pve = self:EnsureRaid156DB()
    if not pve then return false, "Guild data is not ready." end
    data = data or {}
    local name = QSafe(data.name, 36)
    if name == "" then return false, "Enter a raid name." end
    local dayOffset = math.max(0, math.min(60, tonumber(data.dayOffset) or 0))
    local hour = math.max(0, math.min(23, tonumber(data.hour) or 20))
    local minute = math.max(0, math.min(59, tonumber(data.minute) or 0))
    local now = self:Now()
    local serverHour, serverMinute
    if GetGameTime then serverHour, serverMinute = GetGameTime() end
    serverHour = tonumber(serverHour) or tonumber(date("%H", now)) or 0
    serverMinute = tonumber(serverMinute) or tonumber(date("%M", now)) or 0
    local startTs = now - ((serverHour * 3600) + (serverMinute * 60)) + (dayOffset * 86400) + (hour * 3600) + (minute * 60)
    if startTs <= now and dayOffset == 0 then startTs = startTs + 86400 end
    local record = existingId and pve.raids[existingId] or nil
    if not record then record = { id = self:MakePveID("R"), rev = 0, createdAt = now } end
    record.rev = (tonumber(record.rev) or 0) + 1
    record.ts = now
    record.startTs = startTs
    record.author = UnitName("player") or "Unknown"
    record.name = name
    record.location = QSafe(data.location, 32)
    record.note = QSafe(data.note, 80)
    record.recurring = data.recurring == "WEEKLY" and "WEEKLY" or "ONCE"
    record.reminderMinutes = math.max(0, math.min(1440, tonumber(data.reminderMinutes) or 60))
    record.stHour, record.stMinute = hour, minute
    record.gatherHour = math.max(0, math.min(23, tonumber(data.gatherHour) or hour))
    record.gatherMinute = math.max(0, math.min(59, tonumber(data.gatherMinute) or minute))
    record.status = "UPCOMING"
    record.cancelledAt = nil
    record.serverTime = (dayOffset == 0 and "Today" or (dayOffset == 1 and "Tomorrow" or ("+" .. tostring(dayOffset) .. "d"))) .. " " .. string.format("%02d:%02d", hour, minute) .. " ST"
    pve.raids[record.id] = record
    pve.cancelledRaids156[record.id] = nil
    pve.reminded[record.id] = {}
    self:QueuePvePayload(self:SerializePveRaid(record), "GUILD")
    self:RefreshNearestRaid155()
    self:OnPveDataChanged("RAIDS", false)
    return true, record
end

function OTLGM:CancelPveRaid156(id)
    if not self:IsOfficerMode() then return false, "Only leadership can cancel a raid." end
    local pve = self:EnsureRaid156DB()
    local record = pve and pve.raids and pve.raids[id]
    if not record then return false, "Raid event not found." end
    record.rev = (tonumber(record.rev) or 0) + 1
    record.ts = self:Now()
    record.status = "CANCELLED"
    record.cancelledAt = self:Now()
    if pve.raid and pve.raid.id == id then pve.raid = nil end
    pve.cancelledRaids156[id] = record
    pve.raids[id] = nil
    self:QueuePvePayload(self:SerializePveRaid(record), "GUILD")
    self:RefreshNearestRaid155()
    self:OnPveDataChanged("RAIDS", false)
    return true
end

function OTLGM:DeletePveRaid156(id)
    local pve = self:EnsureRaid156DB()
    local record = pve and (pve.raids[id] or pve.cancelledRaids156[id] or pve.pastRaids156[id])
    if not record then return false, "Raid event not found." end
    if not self:IsOfficerMode() then return false, "Only leadership can delete a raid." end
    local rev = (tonumber(record.rev) or 0) + 1
    if pve.raid and pve.raid.id == id then pve.raid = nil end
    pve.raids[id] = nil
    pve.cancelledRaids156[id] = nil
    pve.pastRaids156[id] = nil
    pve.deleted[id] = { rev = rev, ts = self:Now(), kind = "RAID" }
    self:QueuePvePayload(table.concat({ self.pveProtocol, "RAIDDEL", id, tostring(rev) }, "^"), "GUILD")
    self:RefreshNearestRaid155()
    self:OnPveDataChanged("RAIDS", false)
    return true
end

function OTLGM:PurgePveData(silent)
    local pve = self:EnsureRaid156DB()
    if not pve then return false end
    local now = self:Now()
    local id, record
    for id, record in pairs(pve.raids or {}) do
        if record.recurring == "WEEKLY" then
            while record.startTs and record.startTs + 14400 <= now do record.startTs = record.startTs + (7 * 86400) end
        elseif record.startTs and record.startTs + 14400 <= now then
            record.status = "PAST"
            pve.pastRaids156[id] = record
            pve.raids[id] = nil
        end
    end
    for id, record in pairs(pve.cancelledRaids156 or {}) do if (record.cancelledAt or record.ts or 0) < now - (14 * 86400) then pve.cancelledRaids156[id] = nil end end
    for id, record in pairs(pve.pastRaids156 or {}) do if (record.startTs or 0) < now - (30 * 86400) then pve.pastRaids156[id] = nil end end
    local changed = BasePurgePveData156(self, silent)
    -- Base code may remove old tombstones too early. Keep raid tombstones for 30 days.
    for id, record in pairs(pve.deleted or {}) do if record.kind == "RAID" and record.ts and record.ts >= now - (30 * 86400) then pve.deleted[id] = record end end
    return changed
end

function OTLGM:GetRaidList156(filter)
    local pve = self:EnsureRaid156DB()
    local list = {}
    local source = filter == "CANCELLED" and pve.cancelledRaids156 or (filter == "PAST" and pve.pastRaids156 or pve.raids)
    local id, record
    for id, record in pairs(source or {}) do table.insert(list, record) end
    table.sort(list, function(a, b)
        if (a.startTs or 0) ~= (b.startTs or 0) then return filter == "PAST" and (a.startTs or 0) > (b.startTs or 0) or (a.startTs or 0) < (b.startTs or 0) end
        return tostring(a.id) < tostring(b.id)
    end)
    return list
end

local function QDateLabel156(self, raid)
    if not raid or not raid.startTs then return "Time TBA" end
    local label = date("%a %d %b", raid.startTs) .. " • " .. string.format("%02d:%02d", tonumber(raid.stHour) or 0, tonumber(raid.stMinute) or 0) .. " ST"
    if raid.recurring == "WEEKLY" then label = label .. " • Weekly" end
    return label
end

function OTLGM:GetPveRecordRevision(id)
    local pve = self:EnsureRaid156DB()
    if pve then
        if pve.cancelledRaids156[id] then return tonumber(pve.cancelledRaids156[id].rev) or 0 end
        if pve.pastRaids156[id] then return tonumber(pve.pastRaids156[id].rev) or 0 end
    end
    return BaseGetPveRecordRevision156(self, id)
end

function OTLGM:ApplyRemotePveDelete(kind, id, rev)
    local result = BaseApplyRemotePveDelete156(self, kind, id, rev)
    if kind == "RAIDDEL" then
        local pve = self:EnsureRaid156DB()
        if pve then
            if pve.raid and pve.raid.id == id then pve.raid = nil end
            pve.raids[id] = nil
            pve.cancelledRaids156[id] = nil
            pve.pastRaids156[id] = nil
            pve.deleted[id] = { rev = tonumber(rev) or 0, ts = self:Now(), kind = "RAID" }
        end
    end
    return result
end

function OTLGM:QueuePveSyncResponse(target)
    BaseQueuePveSyncResponse156(self, target)
    local pve = self:EnsureRaid156DB()
    local id, record
    for id, record in pairs(pve and pve.cancelledRaids156 or {}) do self:QueuePvePayload(self:SerializePveRaid(record), "WHISPER", target) end
    for id, record in pairs(pve and pve.deleted or {}) do
        if record.kind == "RAID" and record.ts and record.ts >= self:Now() - (30 * 86400) then
            self:QueuePvePayload(table.concat({ self.pveProtocol, "RAIDDEL", id, tostring(record.rev or 1) }, "^"), "WHISPER", target)
        end
    end
end

function OTLGM:BuildPvePage(page)
    BaseBuildPvePage156(self, page)
    self:BuildRaidPlanner156(page)
end

function OTLGM:BuildRaidPlanner156(page)
    if self.ui.raidPlanner156 then return end
    local oldPanel = self.ui.pvePanels and self.ui.pvePanels.RAIDS
    if not oldPanel then return end
    local children = { oldPanel:GetChildren() }
    local i
    for i = 1, table.getn(children) do children[i]:Hide() end
    local root = CreateFrame("Frame", nil, oldPanel)
    root:SetAllPoints(oldPanel)
    root:SetFrameLevel(oldPanel:GetFrameLevel() + 10)
    self.ui.raidPlanner156 = root
    self.ui.raidFilter156 = "UPCOMING"
    self.ui.raidSelected156 = nil

    self.ui.raidTabs156 = {}
    local filters = { {"UPCOMING", "Upcoming"}, {"CANCELLED", "Cancelled"}, {"PAST", "Past"} }
    for i = 1, 3 do
        local captured = filters[i][1]
        self.ui.raidTabs156[captured] = QButton(root, filters[i][2], (i - 1) * 96, 0, 90, 28, function()
            OTLGM.ui.raidFilter156 = captured
            OTLGM.ui.raidSelected156 = nil
            OTLGM.ui.raidOffset156 = 0
            OTLGM:RefreshRaidPlanner156()
        end, "utility")
    end
    self.ui.raidCreate156 = QButton(root, "+ Create Raid", 582, 0, 136, 28, function() OTLGM:OpenRaidEditor156(nil) end, "confirm")

    local list = QPanel(root, 0, -38, 276, 386)
    QText(list, "GameFontNormalSmall", "RAID SCHEDULE", 10, -10, 250, "LEFT")
    self.ui.raidRows156 = {}
    for i = 1, 7 do
        local row = QButton(list, "", 8, -32 - ((i - 1) * 42), 260, 38, function()
            if this.raid156 then OTLGM.ui.raidSelected156 = this.raid156.id OTLGM:RefreshRaidPlanner156() end
        end, "normal")
        row.label156:SetJustifyH("LEFT")
        row.meta156 = QText(row, "GameFontNormalSmall", "", 8, -23, 244, "LEFT")
        row.meta156:SetTextColor(0.60, 0.60, 0.58)
        self.ui.raidRows156[i] = row
    end
    self.ui.raidListEmpty156 = QWrapped(list, "GameFontNormal", "No upcoming raids.\n\nCreate the first event or synchronize with online guild members.", 18, -120, 240, 90)
    self.ui.raidListEmpty156:SetTextColor(0.58, 0.58, 0.56)
    self.ui.raidListStatus156 = QText(list, "GameFontNormalSmall", "", 10, -342, 134, "LEFT")
    self.ui.raidListStatus156:SetTextColor(0.66, 0.66, 0.62)
    self.ui.raidListPrev156 = QButton(list, "<", 180, -336, 36, 26, function()
        OTLGM.ui.raidOffset156 = math.max(0, (OTLGM.ui.raidOffset156 or 0) - 7)
        OTLGM.ui.raidSelected156 = nil
        OTLGM:RefreshRaidPlanner156()
    end, "utility")
    self.ui.raidListNext156 = QButton(list, ">", 224, -336, 36, 26, function()
        OTLGM.ui.raidOffset156 = (OTLGM.ui.raidOffset156 or 0) + 7
        OTLGM.ui.raidSelected156 = nil
        OTLGM:RefreshRaidPlanner156()
    end, "utility")
    list:EnableMouseWheel(1)
    list:SetScript("OnMouseWheel", function()
        if arg1 > 0 then OTLGM.ui.raidOffset156 = math.max(0, (OTLGM.ui.raidOffset156 or 0) - 7)
        else OTLGM.ui.raidOffset156 = (OTLGM.ui.raidOffset156 or 0) + 7 end
        OTLGM.ui.raidSelected156 = nil
        OTLGM:RefreshRaidPlanner156()
    end)

    local detail = QPanel(root, 286, -38, 432, 386)
    self.ui.raidDetailTitle156 = QWrapped(detail, "GameFontNormalLarge", "Select a raid", 16, -16, 396, 42)
    self.ui.raidDetailTime156 = QText(detail, "GameFontNormal", "", 16, -64, 396, "LEFT")
    self.ui.raidDetailGather156 = QText(detail, "GameFontNormalSmall", "", 16, -88, 396, "LEFT")
    self.ui.raidDetailLocation156 = QText(detail, "GameFontNormalSmall", "", 16, -110, 396, "LEFT")
    self.ui.raidDetailNote156 = QWrapped(detail, "GameFontHighlightSmall", "", 16, -142, 396, 92)
    self.ui.raidDetailAuthor156 = QText(detail, "GameFontNormalSmall", "", 16, -244, 396, "LEFT")
    self.ui.raidSeen156 = QButton(detail, "Seen", 16, -276, 92, 28, function()
        local id = OTLGM.ui.raidSelected156
        if id and OTLGM.SetCommunityReaction then OTLGM:SetCommunityReaction("RAID", id, "SEEN", false) OTLGM:RefreshRaidPlanner156() end
    end, "utility")
    self.ui.raidReady156 = QButton(detail, "Ready", 116, -276, 92, 28, function()
        local id = OTLGM.ui.raidSelected156
        if id and OTLGM.SetCommunityReaction then OTLGM:SetCommunityReaction("RAID", id, "READY", false) OTLGM:RefreshRaidPlanner156() end
    end, "confirm")
    self.ui.raidEdit156 = QButton(detail, "Edit", 224, -276, 86, 28, function()
        local raid = OTLGM:GetRaidById156(OTLGM.ui.raidSelected156)
        if raid then OTLGM:OpenRaidEditor156(raid) end
    end, "normal")
    self.ui.raidMore156 = QButton(detail, "More", 318, -276, 94, 28, function()
        local menu = OTLGM.ui.raidMorePanel156
        if menu:IsVisible() then menu:Hide() else menu:Show() end
    end, "utility")
    self.ui.raidMorePanel156 = QPanel(detail, 212, -188, 200, 82)
    self.ui.raidMorePanel156:SetFrameLevel(detail:GetFrameLevel() + 30)
    self.ui.raidMorePanel156:Hide()
    self.ui.raidDuplicate156 = QButton(self.ui.raidMorePanel156, "Duplicate", 8, -8, 88, 24, function()
        OTLGM.ui.raidMorePanel156:Hide()
        local raid = OTLGM:GetRaidById156(OTLGM.ui.raidSelected156)
        if raid then OTLGM:OpenRaidEditor156(raid, true) end
    end, "normal")
    self.ui.raidPost156 = QButton(self.ui.raidMorePanel156, "Post /g", 104, -8, 88, 24, function()
        OTLGM.ui.raidMorePanel156:Hide()
        OTLGM:PostPveRaidToGuildChat(OTLGM.ui.raidSelected156)
    end, "utility")
    self.ui.raidRemind156 = QButton(self.ui.raidMorePanel156, "Remind", 8, -38, 56, 24, function()
        OTLGM.ui.raidMorePanel156:Hide()
        OTLGM:SendPveRaidNotice(0, OTLGM.ui.raidSelected156)
    end, "utility")
    self.ui.raidCancel156 = QButton(self.ui.raidMorePanel156, "Cancel", 70, -38, 58, 24, function()
        OTLGM.ui.raidMorePanel156:Hide()
        local id = OTLGM.ui.raidSelected156
        if id then OTLGM:ShowConfirm("Cancel Raid", "Mark this raid as cancelled for all addon users?", "Cancel Raid", function() OTLGM:CancelPveRaid156(id) OTLGM:RefreshRaidPlanner156() end) end
    end, "danger")
    self.ui.raidDelete156 = QButton(self.ui.raidMorePanel156, "Delete", 134, -38, 58, 24, function()
        OTLGM.ui.raidMorePanel156:Hide()
        local id = OTLGM.ui.raidSelected156
        if id then OTLGM:ShowConfirm("Delete Raid", "Permanently remove this raid for all addon users?", "Delete", function() OTLGM:DeletePveRaid156(id) OTLGM.ui.raidSelected156 = nil OTLGM:RefreshRaidPlanner156() end) end
    end, "danger")
    self.ui.raidNoRole156 = QWrapped(detail, "GameFontNormal", "RAID POPUP REMINDERS LOCKED\nJoin the guild Discord and register under your in-game name to receive an approved raider role. You can still read all raid information here.", 16, -316, 396, 54)
    self.ui.raidNoRole156:SetTextColor(1, 0.60, 0.20)

    self:BuildRaidEditor156()
end

function OTLGM:GetRaidById156(id)
    local pve = self:EnsureRaid156DB()
    if not pve or not id then return nil end
    return pve.raids[id] or pve.cancelledRaids156[id] or pve.pastRaids156[id]
end

function OTLGM:BuildRaidEditor156()
    if self.ui.raidEditor156 then return end
    local dialog = QPanel(self.ui.main, 0, 0, 680, 500)
    dialog:ClearAllPoints()
    dialog:SetPoint("CENTER", self.ui.main, "CENTER", 0, 0)
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:Hide()
    self.ui.raidEditor156 = dialog
    self:RegisterModal152(dialog)
    self.ui.raidEditorTitle156 = QText(dialog, "GameFontNormalLarge", "CREATE RAID EVENT", 20, -18, 640, "CENTER")
    QText(dialog, "GameFontNormalSmall", "RAID NAME", 22, -58, 260, "LEFT")
    self.ui.raidName156 = QEdit(dialog, "OTLGM_RaidName156", 22, -76, 300, 30, 36)
    QText(dialog, "GameFontNormalSmall", "LOCATION / MEETING POINT", 338, -58, 300, "LEFT")
    self.ui.raidLocation156 = QEdit(dialog, "OTLGM_RaidLocation156", 338, -76, 320, 30, 32)
    QText(dialog, "GameFontNormalSmall", "DAY OFFSET", 22, -122, 100, "LEFT")
    self.ui.raidDay156 = QEdit(dialog, "OTLGM_RaidDay156", 22, -140, 54, 30, 2)
    self.ui.raidDay156:SetText("0")
    QButton(dialog, "Today", 84, -140, 68, 30, function() OTLGM.ui.raidDay156:SetText("0") end, "normal")
    QButton(dialog, "Tomorrow", 160, -140, 82, 30, function() OTLGM.ui.raidDay156:SetText("1") end, "normal")
    QButton(dialog, "+7 days", 250, -140, 76, 30, function() OTLGM.ui.raidDay156:SetText("7") end, "normal")
    QText(dialog, "GameFontNormalSmall", "START (ST)", 350, -122, 100, "LEFT")
    self.ui.raidHour156 = QEdit(dialog, "OTLGM_RaidHour156", 350, -140, 48, 30, 2)
    QText(dialog, "GameFontNormalLarge", ":", 404, -145, 16, "CENTER")
    self.ui.raidMinute156 = QEdit(dialog, "OTLGM_RaidMinute156", 422, -140, 48, 30, 2)
    QText(dialog, "GameFontNormalSmall", "GATHER (ST)", 490, -122, 110, "LEFT")
    self.ui.raidGatherHour156 = QEdit(dialog, "OTLGM_RaidGatherHour156", 490, -140, 48, 30, 2)
    QText(dialog, "GameFontNormalLarge", ":", 544, -145, 16, "CENTER")
    self.ui.raidGatherMinute156 = QEdit(dialog, "OTLGM_RaidGatherMinute156", 562, -140, 48, 30, 2)
    QText(dialog, "GameFontNormalSmall", "NOTE", 22, -186, 100, "LEFT")
    self.ui.raidNote156 = QEdit(dialog, "OTLGM_RaidNote156", 22, -204, 636, 30, 80)
    QText(dialog, "GameFontNormalSmall", "REMINDER MINUTES", 22, -250, 140, "LEFT")
    self.ui.raidReminder156 = QEdit(dialog, "OTLGM_RaidReminder156", 22, -268, 70, 30, 4)
    self.ui.raidReminder156:SetText("60")
    self.ui.raidRecurring156 = "ONCE"
    self.ui.raidRecurringButton156 = QButton(dialog, "One time", 110, -268, 110, 30, function()
        OTLGM.ui.raidRecurring156 = OTLGM.ui.raidRecurring156 == "WEEKLY" and "ONCE" or "WEEKLY"
        OTLGM.ui.raidRecurringButton156.label156:SetText(OTLGM.ui.raidRecurring156 == "WEEKLY" and "Weekly" or "One time")
        OTLGM.ui.raidRecurringButton156.selected156 = OTLGM.ui.raidRecurring156 == "WEEKLY"
        OTLGM:ApplyQButton156(OTLGM.ui.raidRecurringButton156)
    end, "utility")
    QWrapped(dialog, "GameFontNormalSmall", "Create always makes a new event. Edit changes only the selected event. Official sign-ups remain in Discord.", 22, -316, 636, 46):SetTextColor(0.58, 0.58, 0.56)
    self.ui.raidSave156 = QButton(dialog, "Create Event", 390, -438, 128, 34, function() OTLGM:SaveRaidEditor156() end, "confirm")
    self.ui.raidEditorCancel156 = QButton(dialog, "Cancel", 530, -438, 128, 34, function() dialog:Hide() end, "normal")
end

function OTLGM:OpenRaidEditor156(raid, duplicate)
    if not self.ui.raidEditor156 then return end
    local dialog = self.ui.raidEditor156
    local editing = raid and not duplicate
    dialog.editId156 = editing and raid.id or nil
    self.ui.raidEditorTitle156:SetText(editing and "EDIT RAID EVENT" or (duplicate and "DUPLICATE RAID EVENT" or "CREATE RAID EVENT"))
    self.ui.raidSave156.label156:SetText(editing and "Save Changes" or "Create Event")
    self.ui.raidName156:SetText(raid and raid.name or "")
    self.ui.raidLocation156:SetText(raid and raid.location or "")
    local dayOffset = 0
    if raid and raid.startTs then dayOffset = math.max(0, math.floor((raid.startTs - self:Now()) / 86400 + 0.5)) end
    self.ui.raidDay156:SetText(tostring(dayOffset))
    self.ui.raidHour156:SetText(string.format("%02d", raid and tonumber(raid.stHour) or 20))
    self.ui.raidMinute156:SetText(string.format("%02d", raid and tonumber(raid.stMinute) or 0))
    self.ui.raidGatherHour156:SetText(string.format("%02d", raid and tonumber(raid.gatherHour) or 19))
    self.ui.raidGatherMinute156:SetText(string.format("%02d", raid and tonumber(raid.gatherMinute) or 45))
    self.ui.raidNote156:SetText(raid and raid.note or "")
    self.ui.raidReminder156:SetText(tostring(raid and raid.reminderMinutes or 60))
    self.ui.raidRecurring156 = raid and raid.recurring == "WEEKLY" and "WEEKLY" or "ONCE"
    self.ui.raidRecurringButton156.label156:SetText(self.ui.raidRecurring156 == "WEEKLY" and "Weekly" or "One time")
    self:ShowModal152(dialog)
end

function OTLGM:SaveRaidEditor156()
    local data = {
        name = self.ui.raidName156:GetText(), location = self.ui.raidLocation156:GetText(), note = self.ui.raidNote156:GetText(),
        dayOffset = self.ui.raidDay156:GetText(), hour = self.ui.raidHour156:GetText(), minute = self.ui.raidMinute156:GetText(),
        gatherHour = self.ui.raidGatherHour156:GetText(), gatherMinute = self.ui.raidGatherMinute156:GetText(),
        recurring = self.ui.raidRecurring156, reminderMinutes = self.ui.raidReminder156:GetText(),
    }
    local ok, result = self:PublishPveRaidEvent156(data, self.ui.raidEditor156.editId156)
    if ok then
        self.ui.raidEditor156:Hide()
        self.ui.raidFilter156 = "UPCOMING"
        self.ui.raidSelected156 = result.id
        self:RefreshRaidPlanner156()
        self:SetStatus(self.ui.raidEditor156.editId156 and "Raid event updated." or "New raid event created.")
    else self:ShowNotice("Raid Event", result or "The raid event could not be saved.") end
end

function OTLGM:RefreshRaidPlanner156()
    if not self.ui or not self.ui.raidPlanner156 then return end
    local filter = self.ui.raidFilter156 or "UPCOMING"
    local list = self:GetRaidList156(filter)
    local rowCount = 7
    local offset = math.max(0, tonumber(self.ui.raidOffset156) or 0)
    if offset >= table.getn(list) and offset > 0 then offset = math.max(0, math.floor(math.max(0, table.getn(list) - 1) / rowCount) * rowCount) end
    self.ui.raidOffset156 = offset
    local selected
    local i, row, raid
    for i = 1, table.getn(list) do if list[i].id == self.ui.raidSelected156 then selected = list[i] break end end
    if not selected then selected = list[1] self.ui.raidSelected156 = selected and selected.id or nil end
    for i = 1, 3 do end
    QSetButton(self.ui.raidTabs156.UPCOMING, "Upcoming", true, nil, filter == "UPCOMING")
    QSetButton(self.ui.raidTabs156.CANCELLED, "Cancelled", true, nil, filter == "CANCELLED")
    QSetButton(self.ui.raidTabs156.PAST, "Past", true, nil, filter == "PAST")
    QSetButton(self.ui.raidCreate156, "+ Create Raid", self:IsOfficerMode(), "Only leadership can create raid events.")
    for i = 1, rowCount do
        row = self.ui.raidRows156[i]
        raid = list[offset + i]
        if raid then
            row.raid156 = raid
            row.label156:SetText((raid.status == "CANCELLED" and "CANCELLED • " or "") .. (raid.name or "Guild Raid"))
            row.meta156:SetText(QDateLabel156(self, raid))
            row.selected156 = selected and selected.id == raid.id
            self:ApplyQButton156(row)
            row:Show()
        else row.raid156 = nil row:Hide() end
    end
    if table.getn(list) == 0 then self.ui.raidListEmpty156:Show() else self.ui.raidListEmpty156:Hide() end
    local first = table.getn(list) > 0 and (offset + 1) or 0
    local last = math.min(table.getn(list), offset + rowCount)
    if self.ui.raidListStatus156 then self.ui.raidListStatus156:SetText(tostring(first) .. "-" .. tostring(last) .. " of " .. tostring(table.getn(list))) end
    QSetButton(self.ui.raidListPrev156, "<", offset > 0, "You are already on the first page.")
    QSetButton(self.ui.raidListNext156, ">", offset + rowCount < table.getn(list), "There are no more raid events.")
    if selected then
        self.ui.raidDetailTitle156:SetText(selected.name or "Guild Raid")
        self.ui.raidDetailTime156:SetText(QDateLabel156(self, selected) .. "  •  " .. self:GetPveRaidRemainingText(selected))
        self.ui.raidDetailGather156:SetText("Gathering: " .. string.format("%02d:%02d", tonumber(selected.gatherHour) or tonumber(selected.stHour) or 0, tonumber(selected.gatherMinute) or tonumber(selected.stMinute) or 0) .. " ST")
        self.ui.raidDetailLocation156:SetText(selected.location ~= "" and ("Meeting: " .. selected.location) or "Meeting point not specified")
        self.ui.raidDetailNote156:SetText(selected.note ~= "" and selected.note or "No additional notes.")
        self.ui.raidDetailAuthor156:SetText("Published by " .. (selected.author or "Leadership") .. "  •  revision " .. tostring(selected.rev or 1))
        local summary = self.GetCommunityReactionSummary and self:GetCommunityReactionSummary("RAID", selected.id) or {}
        QSetButton(self.ui.raidSeen156, "Seen " .. tostring(summary.SEEN or 0), filter == "UPCOMING")
        QSetButton(self.ui.raidReady156, "Ready " .. tostring(summary.READY or 0), filter == "UPCOMING")
        QSetButton(self.ui.raidEdit156, "Edit", self:IsOfficerMode() and filter == "UPCOMING", "Only upcoming raids can be edited by leadership.")
        QSetButton(self.ui.raidMore156, "More", self:IsOfficerMode(), "Only leadership can manage raid events.")
        QSetButton(self.ui.raidDuplicate156, "Duplicate", self:IsOfficerMode(), "Only leadership can duplicate raid events.")
        QSetButton(self.ui.raidPost156, "Post /g", self:IsOfficerMode(), "Only leadership can publish raid information.")
        QSetButton(self.ui.raidRemind156, "Remind", self:IsOfficerMode() and filter == "UPCOMING", "Only an upcoming raid can send a reminder.")
        QSetButton(self.ui.raidCancel156, "Cancel", self:IsOfficerMode() and filter == "UPCOMING", "Only an upcoming raid can be cancelled.")
        QSetButton(self.ui.raidDelete156, "Delete", self:IsOfficerMode(), "Only leadership can permanently delete raid events.")
    else
        self.ui.raidDetailTitle156:SetText("Select a raid")
        self.ui.raidDetailTime156:SetText("")
        self.ui.raidDetailGather156:SetText("")
        self.ui.raidDetailLocation156:SetText("")
        self.ui.raidDetailNote156:SetText("Choose an event from the schedule, or create the first raid.")
        self.ui.raidDetailAuthor156:SetText("")
        QSetButton(self.ui.raidSeen156, "Seen", false, "Select a raid first.")
        QSetButton(self.ui.raidReady156, "Ready", false, "Select a raid first.")
        QSetButton(self.ui.raidEdit156, "Edit", false, "Select a raid first.")
        QSetButton(self.ui.raidMore156, "More", false, "Select a raid first.")
        QSetButton(self.ui.raidDuplicate156, "Duplicate", false, "Select a raid first.")
        QSetButton(self.ui.raidPost156, "Post /g", false, "Select a raid first.")
        QSetButton(self.ui.raidRemind156, "Remind", false, "Select a raid first.")
        QSetButton(self.ui.raidCancel156, "Cancel", false, "Select a raid first.")
        QSetButton(self.ui.raidDelete156, "Delete", false, "Select a raid first.")
        if self.ui.raidMorePanel156 then self.ui.raidMorePanel156:Hide() end
    end
    if self:IsRaidNoticeEligible() then self.ui.raidNoRole156:Hide() else self.ui.raidNoRole156:Show() end
end

function OTLGM:RefreshPvePage()
    BaseRefreshPvePage156(self)
    self:RefreshRaidPlanner156()
    local pveState = self:GetOperationState156("PVE")
    if pveState.state == "WORKING" and self.lastPveSyncRequestAt and self:Now() - self.lastPveSyncRequestAt > 8 then self:SetOperationState156("PVE", "DONE", "PvE data synchronized", 4) end
end

-- ---------------------------------------------------------------------------
-- Guild chat context menu persistence
-- ---------------------------------------------------------------------------

function OTLGM:RefreshGuildChatPage()
    local menu = self.ui and self.ui.chatNameMenu
    local wasVisible = menu and menu:IsVisible()
    local target = menu and menu.targetName
    local ok = BaseRefreshGuildChatPage156(self)
    if wasVisible and menu and target and (OTLGM_DB.settings.guildChatView or "GUILD") ~= "BOARD" then
        menu.targetName = target
        menu:Show()
    end
    return ok
end

-- ---------------------------------------------------------------------------
-- Heartbeat hook called from Events.lua
-- ---------------------------------------------------------------------------

function OTLGM:ProcessQuality156Timers()
    self:RefreshOperationButtons156()
    local rosterState = self:GetOperationState156("ROSTER")
    if rosterState.state == "WORKING" and rosterState.ts and self:Now() - rosterState.ts > 15 then
        self.pendingScan = false
        self.pendingScanReason = nil
        self:SetOperationState156("ROSTER", "ERROR", "Roster update timed out. Try again.", 6)
    end
    local pveState = self:GetOperationState156("PVE")
    if pveState.state == "WORKING" and self.lastPveSyncRequestAt and self:Now() - self.lastPveSyncRequestAt > 8 then
        self:SetOperationState156("PVE", "DONE", "PvE synchronization completed", 4)
    end
    local activityState = self:GetOperationState156("ACTIVITY")
    local shared = self:EnsureSharedActivity156()
    if activityState.state == "WORKING" and shared and self:Now() - (shared.lastSync or 0) > 8 then
        local received = tonumber(shared.syncReceived156) or 0
        local detail = received > 0 and ("Activity sync complete: " .. tostring(received) .. " daily packet(s)") or "Activity sync complete — no new samples received"
        self:SetOperationState156("ACTIVITY", "DONE", detail, 4)
    end
    local craft = self:EnsureCraftingDB()
    local state = self:GetOperationState156("CRAFTING")
    if state.state == "WORKING" and craft and craft.syncState and not craft.syncState.active then
        self:SetOperationState156("CRAFTING", "DONE", "Received " .. tostring(craft.syncState.received or 0) .. " profession snapshots", 4)
    end
    self.activityTimer156 = (self.activityTimer156 or 0) + 1
    if self.activityTimer156 >= 60 then
        self.activityTimer156 = 0
        local shared = self:EnsureSharedActivity156()
        local bucket = self:ActivityBucket156(self:Now())
        if shared and bucket > (shared.lastBroadcast or 0) then self:RecordSharedActivity156(false) end
    end
end
