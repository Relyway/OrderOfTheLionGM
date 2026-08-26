-- Order of the Lion Guild Manager 1.8.2 Quick Dock.
-- Park-only, cache-backed controls for recruitment, Guild Chat and notifications.
-- Vanilla / OctoWoW / Lua 5.0 compatible. This module adds no OnUpdate.

if not OTLGM or not OTLGM.UI then return end

local UI = OTLGM.UI
local C = UI.colors

local QD_HEIGHT182 = 44
local QD_MARGIN182 = 2
local QD_GAP182 = 2
local QD_LION_WIDTH182 = 40
local QD_ACTION_WIDTH182 = 40
local QD_RECRUIT_WIDTH182 = 94
local QD_RECRUIT_TASK182 = "quickdock:recruit-clock"

local function QDLabel182(parent, value, template, x, y, width, justify)
    local label = UI.Text(parent, value or "", template or "GameFontNormalSmall", justify or "LEFT")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then label:SetWidth(width) end
    return label
end

local function QDSanitize182(value, maximum)
    value = tostring(value or "")
    value = string.gsub(value, "|c%x%x%x%x%x%x%x%x", "")
    value = string.gsub(value, "|r", "")
    value = string.gsub(value, "|T.-|t", "")
    value = string.gsub(value, "|H.-|h(.-)|h", "%1")
    value = string.gsub(value, "[%c]+", " ")
    value = string.gsub(value, "%s+", " ")
    value = OTLGM:Trim(value)
    if maximum and string.len(value) > maximum then
        value = OTLGM:Utf8Truncate(value, math.max(1, maximum - 3)) .. "..."
    end
    return value
end

local function QDBadgeText182(count)
    count = math.max(0, tonumber(count) or 0)
    if count > 99 then return "99+" end
    return tostring(count)
end

local function QDNameKey182(name)
    name = tostring(name or "")
    name = string.gsub(name, "%-.*$", "")
    return string.lower(name)
end

local function QDSetLocalStatus182(frame, value, tone)
    if not frame or not frame.status then return end
    frame.status:SetText(tostring(value or ""))
    if tone == "error" then frame.status:SetTextColor(C.red[1], C.red[2], C.red[3])
    elseif tone == "success" then frame.status:SetTextColor(C.green[1], C.green[2], C.green[3])
    elseif tone == "warning" then frame.status:SetTextColor(C.orange[1], C.orange[2], C.orange[3])
    else frame.status:SetTextColor(C.grey[1], C.grey[2], C.grey[3]) end
end

-- r25: Quick Dock can be constructed at login before the full shell exists.
-- Any action that needs a normal addon page must lazily build that shell first.
-- Keeping this in one helper prevents the individual popovers from silently
-- calling UnparkWindow176() against a nil ui.main.
local function QDEnsureFullShellR25()
    if not OTLGM then return false end
    OTLGM.ui = OTLGM.ui or {}
    if not OTLGM.ui.main and OTLGM.BuildUI then OTLGM:BuildUI() end
    return OTLGM.ui and OTLGM.ui.main and true or false
end

function OTLGM:GetQuickDockDirection182(x)
    x = tonumber(x)
    if x == nil then x = tonumber(OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.parkX180) or 0 end
    return x > 0 and "LEFT" or "RIGHT"
end

function OTLGM:GetClampedQuickDockAnchor182(x, y)
    local parentWidth, parentHeight = self:GetPositionViewportMetrics180()
    local dock = self.ui and self.ui.shellParkTab
    local scale = dock and self:GetFrameScaleRelativeToUIParent180(dock) or 1
    local totalWidth = (dock and dock:GetWidth() or QD_HEIGHT182) * scale
    local totalHeight = (dock and dock:GetHeight() or QD_HEIGHT182) * scale
    local lionHalf = (QD_LION_WIDTH182 / 2) * scale
    local innerMargin = QD_MARGIN182 * scale
    local outsideMargin = 2
    local direction = self:GetQuickDockDirection182(x)
    local leftExtent = lionHalf + innerMargin
    local rightExtent = math.max(leftExtent, totalWidth - leftExtent)
    if direction == "LEFT" then leftExtent, rightExtent = rightExtent, leftExtent end
    local minimumX = (-parentWidth / 2) + leftExtent + outsideMargin
    local maximumX = (parentWidth / 2) - rightExtent - outsideMargin
    if minimumX > maximumX then
        minimumX, maximumX = 0, 0
    end
    local halfHeight = totalHeight / 2
    local maximumY = math.max(0, (parentHeight / 2) - halfHeight - outsideMargin)
    return math.max(minimumX, math.min(maximumX, tonumber(x) or 0)),
        math.max(-maximumY, math.min(maximumY, tonumber(y) or 0))
end

function OTLGM:AnchorQuickDockButtons182(direction)
    local dock = self.ui and self.ui.shellParkTab
    local lion = self.ui and self.ui.quickDockLion182
    if not dock or not lion then return false end
    local buttons = { lion }
    if dock.otlOfficer182 then table.insert(buttons, self.ui.quickDockRecruit182) end
    if dock.otlEnabled182 then
        table.insert(buttons, self.ui.quickDockChat182)
        table.insert(buttons, self.ui.quickDockNotify182)
    end
    lion:ClearAllPoints()
    if direction == "LEFT" then lion:SetPoint("RIGHT", dock, "RIGHT", -QD_MARGIN182, 0)
    else lion:SetPoint("LEFT", dock, "LEFT", QD_MARGIN182, 0) end
    local previous = lion
    local index
    for index = 2, table.getn(buttons) do
        local button = buttons[index]
        button:ClearAllPoints()
        if direction == "LEFT" then button:SetPoint("RIGHT", previous, "LEFT", -QD_GAP182, 0)
        else button:SetPoint("LEFT", previous, "RIGHT", QD_GAP182, 0) end
        previous = button
    end
    return true
end

function OTLGM:PositionQuickDock182(x, y)
    local dock = self.ui and self.ui.shellParkTab
    if not dock or not UIParent then return false end
    x, y = self:GetClampedQuickDockAnchor182(x, y)
    local direction = self:GetQuickDockDirection182(x)
    if dock.otlDirection182 ~= direction then self:AnchorQuickDockButtons182(direction) end
    dock:ClearAllPoints()
    if direction == "LEFT" then
        dock:SetPoint("RIGHT", UIParent, "CENTER", x + (QD_LION_WIDTH182 / 2) + QD_MARGIN182, y)
    else
        dock:SetPoint("LEFT", UIParent, "CENTER", x - (QD_LION_WIDTH182 / 2) - QD_MARGIN182, y)
    end
    dock.otlParkAnchorX182 = x
    dock.otlParkAnchorY182 = y
    dock.otlDirection182 = direction
    return true
end

function OTLGM:IsQuickDockEnabled182()
    return OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.useQuickDockWhenParked182 ~= false
end

function OTLGM:CancelQuickDockRecruitClock182()
    self.runtime = self.runtime or {}
    if self.runtime.quickDockRecruitClockArmed182 and self.CancelTask180 then self:CancelTask180(QD_RECRUIT_TASK182) end
    self.runtime.quickDockRecruitClockArmed182 = nil
end

function OTLGM:ShouldRunQuickDockRecruitClock182()
    local dock = self.ui and self.ui.shellParkTab
    return dock and dock.IsVisible and dock:IsVisible() and self:IsQuickDockEnabled182()
        and self.IsOfficerMode and self:IsOfficerMode()
        and self.ui.quickDockRecruit182 and self.ui.quickDockRecruit182:IsVisible()
end

function OTLGM:ArmQuickDockRecruitClock182()
    if not self:ShouldRunQuickDockRecruitClock182() or not self.ScheduleAfter180 then
        self:CancelQuickDockRecruitClock182()
        return false
    end
    if self.runtime and self.runtime.quickDockRecruitClockArmed182 then return true end
    local now = tonumber(self:Now()) or 0
    local delay = 60 - math.mod(math.floor(now), 60)
    if delay < 1 then delay = 60 end
    self:ScheduleAfter180(QD_RECRUIT_TASK182, delay + 0.05, function()
        if not OTLGM then return end
        OTLGM.runtime = OTLGM.runtime or {}
        OTLGM.runtime.quickDockRecruitClockArmed182 = nil
        if OTLGM:ShouldRunQuickDockRecruitClock182() then
            OTLGM:RefreshQuickDockRecruitment182("minute")
            OTLGM:ArmQuickDockRecruitClock182()
        end
    end, 8)
    self.runtime = self.runtime or {}
    self.runtime.quickDockRecruitClockArmed182 = true
    return true
end

function OTLGM:LayoutQuickDock182(reason, officerOverride)
    local dock = self.ui and self.ui.shellParkTab
    if not dock then return false end
    local enabled = self:IsQuickDockEnabled182()
    local officer = false
    if enabled then
        if officerOverride ~= nil then officer = officerOverride and true or false
        else officer = self.IsOfficerMode and self:IsOfficerMode() or false end
    end
    dock.otlEnabled182 = enabled and true or false
    dock.otlOfficer182 = officer and true or false
    if self.ui.quickDockRecruit182 then if officer then self.ui.quickDockRecruit182:Show() else self.ui.quickDockRecruit182:Hide() end end
    if self.ui.quickDockChat182 then if enabled then self.ui.quickDockChat182:Show() else self.ui.quickDockChat182:Hide() end end
    if self.ui.quickDockNotify182 then if enabled then self.ui.quickDockNotify182:Show() else self.ui.quickDockNotify182:Hide() end end

    local width = (QD_MARGIN182 * 2) + QD_LION_WIDTH182
    if officer then width = width + QD_GAP182 + QD_RECRUIT_WIDTH182 end
    if enabled then width = width + (QD_GAP182 * 2) + (QD_ACTION_WIDTH182 * 2) end
    dock:SetWidth(width)
    dock:SetHeight(QD_HEIGHT182)

    local x = tonumber(dock.otlParkAnchorX182)
    local y = tonumber(dock.otlParkAnchorY182)
    if x == nil then x = tonumber(OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.parkX180) or 0 end
    if y == nil then y = tonumber(OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.parkY180) or -176 end
    x, y = self:GetClampedQuickDockAnchor182(x, y)
    local direction = self:GetQuickDockDirection182(x)

    self:AnchorQuickDockButtons182(direction)
    self:PositionQuickDock182(x, y)

    if not enabled or not officer then
        if self.ui.quickDockPopover182 == "recruitment" then self:CloseQuickDockPopover182() end
        self:CancelQuickDockRecruitClock182()
    elseif dock:IsVisible() then
        self:ArmQuickDockRecruitClock182()
    end
    if not enabled then self:CloseQuickDockPopover182() end
    return true
end

function OTLGM:RefreshQuickDockChatBadge182()
    if not self.ui or not self.ui.shellParkTab then return end
    local chatCount = self.GetGuildChatUnread and self:GetGuildChatUnread("GUILD") or 0
    local chatBadge = self.ui.quickDockChatBadge182
    if chatBadge then
        if chatCount > 0 then chatBadge.text:SetText(QDBadgeText182(chatCount)) chatBadge:Show() else chatBadge:Hide() end
    end
    if self.ui.quickDockChat182 then
        self.ui.quickDockChat182.otlTooltip = chatCount > 0 and (tostring(chatCount) .. " unread Guild Chat message(s). Click to open the compact chat view.")
            or "Open recent Guild Chat messages. Opening them does not mark messages read."
    end
end

local QUICK_DOCK_TECHNICAL_TEXT_183 = {
    "roster refreshed", "roster updated", "sync complete", "synchronization complete",
    "addon detection", "addon detected", "cache refreshed", "background refresh",
}

local QUICK_DOCK_ACTION_KEYS_183 = {
    CLAIM=true, MATCH=true, APPLICATION=true, RESPONSE=true, CLAIMED=true,
    ASSIGNED_UPDATE=true, RAID_INVITE_START=true, ACKNOWLEDGE=true, MENTION=true,
    COMPLETED=true, MEMBERSHIP=true, GROUP_RESPONSE=true,
    REPORT_REVIEW=true, REPORT_UPDATE=true, REPORT_FOLLOWUP=true, WARNING_ACK=true,
}

function OTLGM:IsQuickDockNotificationRelevant183(entry)
    if type(entry) ~= "table" then return false end
    local category = string.lower(tostring(entry.category or ""))
    if category == "background" then return false end
    local objectType = string.upper(tostring(entry.objectType or ""))
    local actionKey = string.upper(tostring(entry.actionKey or ""))
    local priority = string.upper(tostring(entry.priority or ""))
    if entry.objectType and self.IsInboxEntryStale180 and self:IsInboxEntryStale180(entry) then return false end
    if objectType == "MOD_REPORT" or objectType == "MOD_WARNING" then return true end
    if objectType == "GUILD_POST" then
        local post = self.GetAnnouncement152 and self:GetAnnouncement152(entry.objectId) or nil
        return actionKey == "ACKNOWLEDGE" or priority == "CRITICAL"
            or (post and (post.importance == "IMPORTANT" or post.importance == "CRITICAL")) and true or false
    end
    local searchable = string.lower(tostring(entry.title or "") .. " " .. tostring(entry.body or ""))
    local index
    for index = 1, table.getn(QUICK_DOCK_TECHNICAL_TEXT_183) do
        if string.find(searchable, QUICK_DOCK_TECHNICAL_TEXT_183[index], 1, true) then return false end
    end
    if self.IsInboxEntryActionable180 and self:IsInboxEntryActionable180(entry) then return true end
    if self.IsInboxEntryPersonal180 and self:IsInboxEntryPersonal180(entry) then return true end
    if QUICK_DOCK_ACTION_KEYS_183[actionKey]
        and (objectType == "CRAFT_REQUEST" or objectType == "GROUP" or objectType == "RAID_EVENT"
            or objectType == "RAID_TEAM" or category == "raid" or category == "group"
            or category == "crafting" or category == "response" or category == "mention") then return true end
    return (priority == "ACTION" or priority == "CRITICAL")
        and (category == "announcement" or category == "raid" or category == "group"
            or category == "crafting" or category == "response") and true or false
end

function OTLGM:GetQuickDockNotificationCount183()
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local count, index, entry = 0, 1, nil
    for index = 1, table.getn(db and db.inbox170 or {}) do
        entry = db.inbox170[index]
        if type(entry) == "table" and not entry.read and self:IsQuickDockNotificationRelevant183(entry) then count = count + 1 end
    end
    return count
end

function OTLGM:RefreshQuickDockNotificationBadge182()
    if not self.ui or not self.ui.shellParkTab then return end
    local inboxCount = self:GetQuickDockNotificationCount183()
    local notifyBadge = self.ui.quickDockNotifyBadge182
    if notifyBadge then
        if inboxCount > 0 then notifyBadge.text:SetText(QDBadgeText182(inboxCount)) notifyBadge:Show() else notifyBadge:Hide() end
    end
    if self.ui.quickDockNotify182 then
        self.ui.quickDockNotify182.otlTooltip = inboxCount > 0 and (tostring(inboxCount) .. " actionable unread notification(s). Click for the newest five.")
            or "No actionable unread notifications. The full Inbox remains available in the addon."
    end
end

function OTLGM:RefreshQuickDockBadges182()
    self:RefreshQuickDockChatBadge182()
    self:RefreshQuickDockNotificationBadge182()
end

function OTLGM:RefreshQuickDockRecruitment182(reason)
    local button = self.ui and self.ui.quickDockRecruit182
    if not button then return end
    local info = self.GetWorldRecruitmentInfo and self:GetWorldRecruitmentInfo() or { state = "NEVER", value = "NEVER", detail = "No timer data." }
    local nextIndex = tonumber(OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.nextRecruitIndex) or 1
    local nextKey, nextLetter = "BASE1", "S1"
    if self.GetRecruitmentQueueStepR56 then
        local ignoredIndexR56
        nextKey, ignoredIndexR56, nextLetter = self:GetRecruitmentQueueStepR56(nextIndex)
    end
    local compact = string.gsub(tostring(info.value or "NEVER"), " ago", "")
    if info.state == "NEVER" then compact = "READY" end
    if self.recruitmentDeliveryPending180 then compact = "SENDING" end
    UI:SetText(button, nextLetter .. "  " .. compact)
    local channelDisplay, channelName = "?", "World"
    if self.GetWorldChannelDisplay153 then channelDisplay, channelName = self:GetWorldChannelDisplay153() end
    local nextPresetR56 = self.GetRecruitmentPreset170 and self:GetRecruitmentPreset170(nextKey) or nil
    button.otlTooltipTitle = "Recruitment - " .. tostring(nextPresetR56 and nextPresetR56.label or nextLetter)
    button.otlTooltip = tostring(info.detail or "") .. "\nChannel: " .. tostring(channelDisplay or "?") .. " " .. tostring(channelName or "World")
        .. "\nClick to review and send the next World message. Send Next advances only after your message appears in World chat."
    local border = C.goldMuted
    if self.recruitmentDeliveryPending180 then border = C.blue
    elseif info.state == "WAIT" then border = C.red
    elseif info.state == "WINDOW" then border = C.orange
    elseif info.state == "READY" then border = C.green end
    if button.SetBackdropBorderColor then button:SetBackdropBorderColor(border[1], border[2], border[3], 1) end
    if self.ui.quickDockPopover182 == "recruitment" then self:RefreshQuickDockRecruitmentPopover182(reason) end
end

function OTLGM:RefreshQuickDock182(kind, officerOverride)
    local dock = self.ui and self.ui.shellParkTab
    if not dock then return false end
    kind = tostring(kind or "all")
    if kind == "all" or kind == "show" or kind == "permissions" or kind == "settings" or kind == "world" then
        self:LayoutQuickDock182(kind, officerOverride)
    end
    if not dock.IsVisible or not dock:IsVisible() then return true end
    if not self:IsQuickDockEnabled182() then return true end
    if kind == "all" or kind == "show" or kind == "permissions" or kind == "settings" or kind == "recruitment" or kind == "world" then
        self:RefreshQuickDockRecruitment182(kind)
    end
    if kind == "all" or kind == "show" or kind == "permissions" or kind == "settings" then
        self:RefreshQuickDockBadges182()
    elseif kind == "chat" then
        self:RefreshQuickDockChatBadge182()
    elseif kind == "notifications" then
        self:RefreshQuickDockNotificationBadge182()
    end
    if kind == "chat" and self.ui.quickDockPopover182 == "chat" then self:RefreshQuickDockChatPopover182() end
    if kind == "notifications" and self.ui.quickDockPopover182 == "notifications" then self:RefreshQuickDockNotificationsPopover182() end
    return true
end

function OTLGM:MarkQuickDockDirty182(kind, officerOverride)
    local dock = self.ui and self.ui.shellParkTab
    if not dock or not dock.IsVisible or not dock:IsVisible() then return false end
    return self:RefreshQuickDock182(kind, officerOverride)
end

function OTLGM:RefreshQuickDockPermissions182(officerAllowed)
    return self:MarkQuickDockDirty182("permissions", officerAllowed)
end

function OTLGM:RefreshQuickDockSettings182()
    if not self.ui or not self.ui.shellParkTab then return false end
    self:LayoutQuickDock182("settings")
    if self.ui.shellParkTab:IsVisible() then self:RefreshQuickDock182("settings") end
    return true
end

function OTLGM:CreateQuickDockPopover182(key, width, height, title, name)
    local frame = UI:Surface(UIParent, "raised", width, height, name)
    frame:SetFrameStrata("LOW")
    frame:SetFrameLevel(18)
    frame:EnableMouse(true)
    if frame.SetToplevel then frame:SetToplevel(true) end
    if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
    frame.otlQuickDockKey182 = key
    frame.title = QDLabel182(frame, string.upper(title or key), "GameFontNormal", 14, -14, width - 60, "LEFT")
    frame.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    frame.close = UI:Button(frame, "x", 28, 24, function() OTLGM:CloseQuickDockPopover182() end, "danger")
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
    frame:SetScript("OnHide", function()
        if OTLGM and OTLGM.ui and OTLGM.ui.quickDockPopover182 == this.otlQuickDockKey182 then
            OTLGM.ui.quickDockPopover182 = nil
        end
        if this.otlQuickDockKey182 == "recruitment" then this.otlConfirmRecruit182 = nil end
    end)
    UISpecialFrames = UISpecialFrames or {}
    table.insert(UISpecialFrames, name)
    frame:Hide()
    return frame
end

function OTLGM:PlaceQuickDockPopover182(frame)
    local dock = self.ui and self.ui.shellParkTab
    if not frame or not dock then return false end
    local x = tonumber(dock.otlParkAnchorX182) or 0
    local y = tonumber(dock.otlParkAnchorY182) or 0
    local direction = self:GetQuickDockDirection182(x)
    frame:ClearAllPoints()
    if y > 0 then
        if direction == "LEFT" then frame:SetPoint("TOPRIGHT", dock, "BOTTOMRIGHT", 0, -6)
        else frame:SetPoint("TOPLEFT", dock, "BOTTOMLEFT", 0, -6) end
    else
        if direction == "LEFT" then frame:SetPoint("BOTTOMRIGHT", dock, "TOPRIGHT", 0, 6)
        else frame:SetPoint("BOTTOMLEFT", dock, "TOPLEFT", 0, 6) end
    end
    return true
end

function OTLGM:CloseQuickDockPopover182()
    if not self.ui then return false end
    local key = self.ui.quickDockPopover182
    local frames = self.ui.quickDockPopovers182 or {}
    local frame = key and frames[key] or nil
    self.ui.quickDockPopover182 = nil
    if frame and frame.Hide then frame:Hide() return true end
    return false
end

function OTLGM:ToggleQuickDockPopover182(key)
    if not self:IsQuickDockEnabled182() then return false end
    if self.ui.quickDockPopover182 == key then return self:CloseQuickDockPopover182() end
    self:CloseQuickDockPopover182()
    local frame
    if key == "recruitment" then frame = self:BuildQuickDockRecruitmentPopover182()
    elseif key == "chat" then frame = self:BuildQuickDockChatPopover182()
    elseif key == "notifications" then frame = self:BuildQuickDockNotificationsPopover182() end
    if not frame then return false end
    self.ui.quickDockPopover182 = key
    self:PlaceQuickDockPopover182(frame)
    if key == "recruitment" then self:RefreshQuickDockRecruitmentPopover182("open")
    elseif key == "chat" then self:RefreshQuickDockChatPopover182()
    elseif key == "notifications" then self:RefreshQuickDockNotificationsPopover182() end
    frame:Show()
    return true
end

function OTLGM:SetQuickDockRecruitmentStatus182(value, tone)
    self.runtime = self.runtime or {}
    self.runtime.quickDockRecruitmentStatus182 = { text = tostring(value or ""), tone = tone or "normal", ts = self:Now() }
    if self.ui and self.ui.quickDockPopover182 == "recruitment" then self:RefreshQuickDockRecruitmentPopover182("status") end
end

function OTLGM:BuildQuickDockRecruitmentPopover182()
    self.ui.quickDockPopovers182 = self.ui.quickDockPopovers182 or {}
    if self.ui.quickDockPopovers182.recruitment then return self.ui.quickDockPopovers182.recruitment end
    local frame = self:CreateQuickDockPopover182("recruitment", 410, 390, "Recruitment Quick Send", "OTLGM_QuickDockRecruitment182")
    frame.summary = QDLabel182(frame, "", "GameFontNormal", 14, -48, 382, "LEFT")
    frame.detail = QDLabel182(frame, "", "GameFontNormalSmall", 14, -76, 382, "LEFT")
    frame.detail:SetHeight(36) frame.detail:SetJustifyV("TOP") frame.detail:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    frame.preview = QDLabel182(frame, "", "GameFontNormalSmall", 14, -112, 382, "LEFT")
    frame.preview:SetHeight(58) frame.preview:SetJustifyV("TOP") frame.preview:SetTextColor(C.white[1], C.white[2], C.white[3])
    frame.status = QDLabel182(frame, "", "GameFontNormalSmall", 14, -178, 382, "LEFT")
    frame.status:SetHeight(30) frame.status:SetJustifyV("TOP")
    frame.candidateTitle = QDLabel182(frame, "RECENT CANDIDATES", "GameFontNormalSmall", 14, -216, 382, "LEFT")
    frame.candidateTitle:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    frame.candidateEmpty = QDLabel182(frame, "No recent external whisper candidates.", "GameFontNormalSmall", 16, -246, 368, "LEFT")
    frame.candidateEmpty:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    frame.candidateRows = {}
    local candidateIndex
    for candidateIndex = 1, 3 do
        local row = CreateFrame("Frame", nil, frame)
        row:SetWidth(382) row:SetHeight(32)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -236 - ((candidateIndex - 1) * 34))
        row.name = QDLabel182(row, "", "GameFontNormalSmall", 2, -8, 176, "LEFT")
        row.whisper = UI:Button(row, "Whisper", 76, 26, function(button)
            if button and button.otlCandidateName182 and OTLGM and OTLGM.OpenGuildChatWhisper then
                OTLGM:OpenGuildChatWhisper(button.otlCandidateName182)
            end
        end, "secondary")
        row.whisper:SetPoint("RIGHT", row, "RIGHT", -84, 0)
        row.invite = UI:Button(row, "Invite", 76, 26, function(button)
            if button and button.otlCandidateName182 and OTLGM and OTLGM.InviteRecentWhisper176 then
                OTLGM:InviteRecentWhisper176(button.otlCandidateName182)
                OTLGM:RefreshQuickDockRecruitmentPopover182("candidate-invite")
            end
        end, "primary")
        row.invite:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        frame.candidateRows[candidateIndex] = row
    end
    frame.send = UI:Button(frame, "Send Next", 126, 30, function() OTLGM:QuickDockRequestRecruitment182() end, "primary")
    frame.send:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 14)
    frame.cancelConfirm = UI:Button(frame, "Cancel Preview", 112, 30, function()
        frame.otlConfirmRecruit182 = nil
        OTLGM:RefreshQuickDockRecruitmentPopover182("cancel-confirm")
    end, "secondary")
    frame.cancelConfirm:SetPoint("LEFT", frame.send, "RIGHT", 8, 0)
    frame.welcomeR32 = UI:Button(frame, "Welcome!", 90, 30, function()
        if SendChatMessage then
            local ok, problem = pcall(SendChatMessage, "Welcome!", "GUILD")
            if ok then OTLGM:SetQuickDockRecruitmentStatus182("Welcome! sent to guild chat.", "success")
            else OTLGM:SetQuickDockRecruitmentStatus182("Welcome message failed: " .. tostring(problem or "client rejected it"), "error") end
        else
            OTLGM:SetQuickDockRecruitmentStatus182("Guild chat is unavailable on this client.", "error")
        end
        OTLGM:RefreshQuickDockRecruitmentPopover182("welcome")
    end, "utility")
    frame.welcomeR32.otlTooltipTitle = "Quick guild welcome"
    frame.welcomeR32.otlTooltip = "Sends exactly: Welcome! to guild chat. Recruitment cooldown and the Send Next order are not changed."
    frame.welcomeR32:SetPoint("LEFT", frame.send, "RIGHT", 8, 0)
    frame.openFull = UI:Button(frame, "Open Recruitment", 136, 30, function()
        OTLGM:CloseQuickDockPopover182()
        if not QDEnsureFullShellR25() then return end
        OTLGM:UnparkWindow176()
        OTLGM:ShowPage("recruitment")
    end, "utility")
    frame.openFull:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 14)
    self.ui.quickDockPopovers182.recruitment = frame
    return frame
end

function OTLGM:RefreshQuickDockRecruitmentPopover182(reason)
    local frame = self.ui and self.ui.quickDockPopovers182 and self.ui.quickDockPopovers182.recruitment
    if not frame then return end
    local info = self.GetWorldRecruitmentInfo and self:GetWorldRecruitmentInfo() or { state = "NEVER", value = "NEVER", detail = "No timer data." }
    local nextIndex = tonumber(OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.nextRecruitIndex) or 1
    local key, letter = "BASE1", "S1"
    if self.GetRecruitmentQueueStepR56 then
        local ignoredIndexR56
        key, ignoredIndexR56, letter = self:GetRecruitmentQueueStepR56(nextIndex)
    end
    local preset = self.GetRecruitmentPreset170 and self:GetRecruitmentPreset170(key) or nil
    local channelDisplay, channelName = "?", "World"
    if self.GetWorldChannelDisplay153 then channelDisplay, channelName = self:GetWorldChannelDisplay153() end
    local displayValue = info.state == "NEVER" and "Ready now" or tostring(info.value or "Ready")
    frame.summary:SetText("Next: " .. tostring(preset and preset.label or letter) .. "  /  " .. displayValue .. "  /  " .. tostring(channelDisplay or "?") .. " " .. tostring(channelName or "World"))
    frame.detail:SetText(tostring(info.detail or ""))
    frame.preview:SetText(QDSanitize182(preset and preset.text or "Recruitment preset is unavailable.", 230))

    local candidates = {}
    local recent = self.runtime and self.runtime.recentWhispers176 or {}
    local recentIndex, entry
    for recentIndex = 1, table.getn(recent) do
        entry = recent[recentIndex]
        if entry and entry.name and entry.name ~= "" and (not self.GetMember or not self:GetMember(entry.name)) then
            table.insert(candidates, entry)
            if table.getn(candidates) >= 3 then break end
        end
    end
    local candidateIndex, row, age, state
    for candidateIndex = 1, 3 do
        row = frame.candidateRows and frame.candidateRows[candidateIndex]
        entry = candidates[candidateIndex]
        if row and entry then
            age = math.max(0, self:Now() - (tonumber(entry.ts) or self:Now()))
            if age < 60 then age = tostring(math.floor(age)) .. "s"
            elseif age < 3600 then age = tostring(math.floor(age / 60)) .. "m"
            else age = tostring(math.floor(age / 3600)) .. "h" end
            state = self.runtime and self.runtime.recentWhisperInviteStateR5
                and self.runtime.recentWhisperInviteStateR5[QDNameKey182(entry.name)] or nil
            row.name:SetText(QDSanitize182(entry.name, 20) .. "  |cff777777" .. age .. "|r")
            row.whisper.otlCandidateName182 = entry.name
            row.invite.otlCandidateName182 = entry.name
            UI:SetText(row.invite, state and state.state == "SENT" and "Invited" or "Invite")
            UI:SetEnabled(row.invite, not state or state.state ~= "SENT", state and state.state == "SENT" and "A guild invite was already sent this session." or nil)
            row:Show()
        elseif row then
            row.whisper.otlCandidateName182 = nil
            row.invite.otlCandidateName182 = nil
            row:Hide()
        end
    end
    if frame.candidateEmpty then
        if table.getn(candidates) == 0 then frame.candidateEmpty:Show() else frame.candidateEmpty:Hide() end
    end

    local pending = self.recruitmentDeliveryPending180
    local canSend = not pending and info.state ~= "WAIT" and preset and QDSanitize182(preset.text, 240) ~= ""
    if frame.otlConfirmRecruit182 then
        UI:SetText(frame.send, "Confirm Send")
        if frame.welcomeR32 then frame.welcomeR32:Hide() end
        frame.cancelConfirm:Show()
        QDSetLocalStatus182(frame, "Confirm " .. tostring(frame.otlConfirmRecruit182.label or letter) .. " to World. Cooldown and Send Next advance only after the message appears in chat.", "warning")
    else
        UI:SetText(frame.send, "Send Next (" .. letter .. ")")
        frame.cancelConfirm:Hide()
        if frame.welcomeR32 then frame.welcomeR32:Show() end
        local status = self.runtime and self.runtime.quickDockRecruitmentStatus182 or nil
        if pending then QDSetLocalStatus182(frame, "Waiting for your message to appear in World chat; Send Next has not advanced yet.", "normal")
        elseif status and self:Now() - (tonumber(status.ts) or 0) <= 90 then QDSetLocalStatus182(frame, status.text, status.tone)
        else QDSetLocalStatus182(frame, info.detail or "", info.state == "WAIT" and "error" or info.state == "WINDOW" and "warning" or "normal") end
    end
    local confirmReady = frame.otlConfirmRecruit182 and not pending and info.state ~= "WAIT"
    UI:SetEnabled(frame.send, canSend or confirmReady, pending and "A recruitment delivery is already awaiting confirmation."
        or info.state == "WAIT" and tostring(info.detail or "Cooldown is active.") or "The next recruitment preset is unavailable.")
end

function OTLGM:QuickDockRequestRecruitment182()
    local frame = self.ui and self.ui.quickDockPopovers182 and self.ui.quickDockPopovers182.recruitment
    if not frame then return false end
    if frame.otlConfirmRecruit182 then
        local request = frame.otlConfirmRecruit182
        frame.otlConfirmRecruit182 = nil
        return self:QuickDockDeliverRecruitment182(request)
    end
    local info = self:GetWorldRecruitmentInfo()
    if info.state == "WAIT" then QDSetLocalStatus182(frame, info.detail, "error") return false end
    local nextIndex = tonumber(OTLGM_DB.settings.nextRecruitIndex) or 1
    local key = self.GetRecruitmentQueueStepR56 and self:GetRecruitmentQueueStepR56(nextIndex) or "BASE1"
    local preset = self:GetRecruitmentPreset170(key)
    if not preset or self:Trim(preset.text or "") == "" then QDSetLocalStatus182(frame, "The next World recruitment message is empty or unavailable.", "error") return false end
    local request = { message = preset.text, target = "WORLD", key = key, label = preset.label or "Recruitment" }
    if OTLGM_DB.settings.confirmRecruitment ~= false then
        frame.otlConfirmRecruit182 = request
        self:RefreshQuickDockRecruitmentPopover182("confirm")
        return true
    end
    return self:QuickDockDeliverRecruitment182(request)
end

function OTLGM:QuickDockDeliverRecruitment182(request)
    local frame = self.ui and self.ui.quickDockPopovers182 and self.ui.quickDockPopovers182.recruitment
    if not request or not self.BeginRecruitmentDelivery180 then return false end
    local ok, detail = self:BeginRecruitmentDelivery180(request.message, "WORLD", request.key, request.label, true, true)
    if ok then
        self:SetQuickDockRecruitmentStatus182("Sent. Waiting for your message to appear in World chat.", "normal")
    else
        self:SetQuickDockRecruitmentStatus182(detail or "The recruitment message was not sent.", "error")
    end
    if frame then frame.otlConfirmRecruit182 = nil end
    self:RefreshQuickDockRecruitment182("send")
    return ok
end

function OTLGM:BuildQuickDockChatPopover182()
    self.ui.quickDockPopovers182 = self.ui.quickDockPopovers182 or {}
    if self.ui.quickDockPopovers182.chat then return self.ui.quickDockPopovers182.chat end
    local frame = self:CreateQuickDockPopover182("chat", 500, 350, "Guild Chat", "OTLGM_QuickDockChat182")
    frame.rows = {}
    local index
    for index = 1, 8 do
        local row = CreateFrame("Frame", nil, frame)
        row:SetWidth(472) row:SetHeight(24)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -44 - ((index - 1) * 24))
        row.text = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.text:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.text:SetWidth(468)
        row.text:SetTextColor(index == 1 and C.white[1] or C.grey[1], index == 1 and C.white[2] or C.grey[2], index == 1 and C.white[3] or C.grey[3])
        frame.rows[index] = row
    end
    frame.empty = QDLabel182(frame, "No recent Guild Chat messages are available yet.", "GameFontNormalSmall", 16, -72, 468, "CENTER")
    frame.empty:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    frame.status = QDLabel182(frame, "", "GameFontNormalSmall", 14, -241, 472, "LEFT")
    frame.composer = UI:EditBox(frame, 472, 30, { placeholder = "Message Guild Chat...", maxLetters = 255 })
    frame.composer:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -261)
    frame.composer:SetScript("OnEnterPressed", function() OTLGM:QuickDockSendGuildChat182() end)
    frame.markRead = UI:Button(frame, "Mark Read", 104, 30, function() OTLGM:MarkGuildChatRead182("GUILD") end, "secondary")
    frame.markRead:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 14)
    frame.openFull = UI:Button(frame, "Open Full Chat", 126, 30, function()
        OTLGM:CloseQuickDockPopover182()
        if not QDEnsureFullShellR25() then return end
        OTLGM:UnparkWindow176()
        OTLGM:SetGuildChatChannel("GUILD")
        OTLGM:ShowPage("guildchat")
    end, "utility")
    frame.openFull:SetPoint("LEFT", frame.markRead, "RIGHT", 8, 0)
    frame.send = UI:Button(frame, "Send", 82, 30, function() OTLGM:QuickDockSendGuildChat182() end, "primary")
    frame.send:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 14)
    self.ui.quickDockPopovers182.chat = frame
    return frame
end

function OTLGM:RefreshQuickDockChatPopover182()
    local frame = self.ui and self.ui.quickDockPopovers182 and self.ui.quickDockPopovers182.chat
    if not frame then return end
    local messages = self.GetGuildChatMessages and self:GetGuildChatMessages("GUILD") or {}
    local count = table.getn(messages)
    local visible = math.min(8, count)
    local start = count - visible + 1
    local index, message, clock
    for index = 1, 8 do
        local row = frame.rows[index]
        if index <= visible then
            message = messages[start + index - 1]
            clock = tonumber(message and message.ts)
            row.text:SetText((clock and date("%H:%M", clock) or "--:--") .. "  "
                .. QDSanitize182(message and message.sender or "Unknown", 24) .. ": " .. QDSanitize182(message and message.text or "", 92))
            row:Show()
        else row:Hide() end
    end
    if visible == 0 then frame.empty:Show() else frame.empty:Hide() end
    local unread = self.GetGuildChatUnread and self:GetGuildChatUnread("GUILD") or 0
    UI:SetText(frame.markRead, unread > 0 and ("Mark Read (" .. QDBadgeText182(unread) .. ")") or "All Read")
    UI:SetEnabled(frame.markRead, unread > 0, "There are no unread Guild Chat messages.")
    self:RefreshQuickDockChatBadge182()
end

function OTLGM:MarkGuildChatRead182(channel)
    channel = channel == "OFFICER" and "OFFICER" or "GUILD"
    self:SetGuildChatUnread(channel, 0)
    self.guildChatNewMarker = self.guildChatNewMarker or {}
    self.guildChatNewMarker[channel] = nil
    if self.RefreshGuildChatNavigationBadge then self:RefreshGuildChatNavigationBadge()
    elseif self.RefreshNavigation then self:RefreshNavigation() end
    self:MarkQuickDockDirty182("chat")
    return true
end

function OTLGM:QuickDockSendGuildChat182()
    local frame = self.ui and self.ui.quickDockPopovers182 and self.ui.quickDockPopovers182.chat
    if not frame then return false end
    local message = self:Trim(frame.composer:GetText() or "")
    if message == "" then QDSetLocalStatus182(frame, "Write a Guild Chat message first.", "error") return false end
    local ok, detail = self:SendGuildChatMessage(message, "GUILD", true)
    if not ok then QDSetLocalStatus182(frame, detail or "Guild Chat rejected the message.", "error") return false end
    frame.composer:SetText("")
    QDSetLocalStatus182(frame, "Sent; waiting for the normal CHAT_MSG_GUILD capture (no local fake echo).", "success")
    return true
end

function OTLGM:BuildQuickDockNotificationsPopover182()
    self.ui.quickDockPopovers182 = self.ui.quickDockPopovers182 or {}
    if self.ui.quickDockPopovers182.notifications then return self.ui.quickDockPopovers182.notifications end
    local frame = self:CreateQuickDockPopover182("notifications", 440, 318, "Notifications", "OTLGM_QuickDockNotifications182")
    frame.rows = {}
    local index
    for index = 1, 5 do
        local row = UI:Button(frame, "", 412, 43, function(button) OTLGM:OpenQuickDockNotification182(button.otlEntry182) end, "inline")
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -43 - ((index - 1) * 45))
        row.text:Hide()
        row.title = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 9, -6)
        row.title:SetWidth(310)
        row.age = UI.Text(row, "", "GameFontNormalSmall", "RIGHT")
        row.age:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -6)
        row.age:SetWidth(78) row.age:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        row.body = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.body:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 9, 6)
        row.body:SetWidth(394) row.body:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        frame.rows[index] = row
    end
    frame.empty = QDLabel182(frame, "No unread notifications.", "GameFontNormalSmall", 16, -92, 408, "CENTER")
    frame.empty:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    frame.status = QDLabel182(frame, "Newest five actionable entries; unrelated Inbox items stay unread.", "GameFontNormalSmall", 14, -274, 275, "LEFT")
    frame.status:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    frame.markAll = UI:Button(frame, "Mark Dock Read", 120, 30, function()
        OTLGM:MarkQuickDockNotificationsRead183()
    end, "secondary")
    frame.markAll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 12)
    self.ui.quickDockPopovers182.notifications = frame
    return frame
end

function OTLGM:GetQuickDockUnreadEntries182(maximum)
    maximum = math.max(1, math.min(5, tonumber(maximum) or 5))
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local result = {}
    local index, entry
    for index = 1, table.getn(db and db.inbox170 or {}) do
        entry = db.inbox170[index]
        if type(entry) == "table" and not entry.read and self:IsQuickDockNotificationRelevant183(entry) then
            table.insert(result, entry)
            if table.getn(result) >= maximum then break end
        end
    end
    return result
end

function OTLGM:MarkQuickDockNotificationsRead183()
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    if not db then return false end
    local changed, index, entry = false, 1, nil
    for index = 1, table.getn(db.inbox170 or {}) do
        entry = db.inbox170[index]
        if type(entry) == "table" and not entry.read and self:IsQuickDockNotificationRelevant183(entry) then
            entry.read = true
            changed = true
        end
    end
    if changed then
        db.notificationUnread = type(db.notificationUnread) == "table" and db.notificationUnread or {}
        local category
        for category in pairs(db.notificationUnread) do db.notificationUnread[category] = 0 end
        for index = 1, table.getn(db.inbox170 or {}) do
            entry = db.inbox170[index]
            if type(entry) == "table" and not entry.read then
                category = type(entry.category) == "string" and entry.category ~= "" and entry.category or "background"
                db.notificationUnread[category] = (tonumber(db.notificationUnread[category]) or 0) + 1
            end
        end
        if self.RefreshNavigation then self:RefreshNavigation() end
        if self.UpdateMinimapBadge then self:UpdateMinimapBadge() end
    end
    self:MarkQuickDockDirty182("notifications")
    return changed
end

function OTLGM:RefreshQuickDockNotificationsPopover182()
    local frame = self.ui and self.ui.quickDockPopovers182 and self.ui.quickDockPopovers182.notifications
    if not frame then return end
    local entries = self:GetQuickDockUnreadEntries182(5)
    local index, row, entry, elapsed
    for index = 1, 5 do
        row = frame.rows[index]
        entry = entries[index]
        if entry then
            row.otlEntry182 = entry
            row.title:SetText((entry.priority == "CRITICAL" and "! " or entry.priority == "ACTION" and "> " or "") .. QDSanitize182(entry.title or "Guild update", 48))
            row.body:SetText(QDSanitize182(entry.body or "", 64))
            elapsed = math.max(0, self:Now() - (tonumber(entry.ts) or self:Now()))
            row.age:SetText(self.FormatElapsedShort and self:FormatElapsedShort(elapsed) or "")
            row:Show()
        else
            row.otlEntry182 = nil
            row:Hide()
        end
    end
    if table.getn(entries) == 0 then frame.empty:Show() else frame.empty:Hide() end
    UI:SetEnabled(frame.markAll, table.getn(entries) > 0, "There are no unread notifications.")
    self:RefreshQuickDockNotificationBadge182()
end

function OTLGM:OpenQuickDockNotification182(entry)
    if type(entry) ~= "table" then return false end
    if entry.id and self.MarkInboxRead170 then self:MarkInboxRead170(entry.id) end
    self:CloseQuickDockPopover182()
    if not QDEnsureFullShellR25() then return false end
    self:UnparkWindow176()
    if self.OpenActionCenterEntry180 then return self:OpenActionCenterEntry180(entry) end
    if entry.targetPage and self.ShowPage then self:ShowPage(entry.targetPage) return true end
    return false
end

function OTLGM:BuildQuickDock182()
    self.ui = self.ui or {}
    if self.ui.shellParkTab then return self.ui.shellParkTab end
    local dock = UI:Surface(UIParent, "surface", QD_HEIGHT182, QD_HEIGHT182)
    dock:SetFrameStrata("LOW")
    dock:SetFrameLevel(8)
    dock:SetMovable(true)
    dock:EnableMouse(true)
    if dock.SetClampedToScreen then dock:SetClampedToScreen(false) end
    self.ui.shellParkTab = dock

    local lion = UI:IconButton(dock, "Interface\\AddOns\\OrderOfTheLionGM\\Assets\\LionCrest", QD_LION_WIDTH182, QD_LION_WIDTH182, function()
        if arg1 == "RightButton" then
            if OTLGM.HideQuickDock183 then OTLGM:HideQuickDock183("lion-right-click") end
            return
        end
        local suppressUntil = tonumber(dock.otlSuppressClickUntil180)
        if suppressUntil and GetTime and GetTime() <= suppressUntil then return end
        dock.otlSuppressClickUntil180 = nil
        OTLGM:CloseQuickDockPopover182()
        -- r25: Quick Dock can exist from login before the heavy shell is ever
        -- opened. Build the full UI only on the first restore click.
        if not QDEnsureFullShellR25() then return end
        OTLGM:UnparkWindow176()
    end, "Restore Order of the Lion", "primary")
    lion.otlTooltipTitle = "Order of the Lion"
    lion.otlTooltip = "Left-click to restore the full addon. Drag to move Quick Dock. Right-click to hide the Dock completely."
    if lion.RegisterForClicks then lion:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
    lion:RegisterForDrag("LeftButton")
    lion:SetScript("OnDragStart", function() if OTLGM then OTLGM:CloseQuickDockPopover182() OTLGM:BeginParkDrag180() end end)
    lion:SetScript("OnDragStop", function() if OTLGM then OTLGM:EndParkDrag180() end end)
    self.ui.quickDockLion182 = lion

    local recruit = UI:Button(dock, "A  NEVER", QD_RECRUIT_WIDTH182, QD_LION_WIDTH182, function() OTLGM:ToggleQuickDockPopover182("recruitment") end, "secondary")
    recruit.otlTooltipTitle = "Recruitment"
    self.ui.quickDockRecruit182 = recruit

    local chat = UI:IconButton(dock, "Interface\\Icons\\INV_Letter_15", QD_ACTION_WIDTH182, QD_LION_WIDTH182, function() OTLGM:ToggleQuickDockPopover182("chat") end, "Guild Chat", "utility")
    chat.otlTooltipTitle = "Guild Chat"
    local chatBadge = UI:Badge(chat, 25, 16)
    chatBadge:SetPoint("TOPRIGHT", chat, "TOPRIGHT", 2, 2)
    chatBadge:SetFrameLevel(chat:GetFrameLevel() + 4)
    self.ui.quickDockChat182 = chat
    self.ui.quickDockChatBadge182 = chatBadge

    local notify = UI:IconButton(dock, "Interface\\Icons\\INV_Misc_Bell_01", QD_ACTION_WIDTH182, QD_LION_WIDTH182, function() OTLGM:ToggleQuickDockPopover182("notifications") end, "Notifications", "utility")
    notify.otlTooltipTitle = "Notifications"
    local notifyBadge = UI:Badge(notify, 25, 16)
    notifyBadge:SetPoint("TOPRIGHT", notify, "TOPRIGHT", 2, 2)
    notifyBadge:SetFrameLevel(notify:GetFrameLevel() + 4)
    self.ui.quickDockNotify182 = notify
    self.ui.quickDockNotifyBadge182 = notifyBadge

    local recruitEnter = recruit:GetScript("OnEnter")
    recruit:SetScript("OnEnter", function() OTLGM:RefreshQuickDockRecruitment182("tooltip") if recruitEnter then recruitEnter() end end)
    local recruitLeave = recruit:GetScript("OnLeave")
    recruit:SetScript("OnLeave", function() if recruitLeave then recruitLeave() end OTLGM:RefreshQuickDockRecruitment182("leave") end)
    local chatEnter = chat:GetScript("OnEnter")
    chat:SetScript("OnEnter", function() OTLGM:RefreshQuickDockChatBadge182() if chatEnter then chatEnter() end end)
    local notifyEnter = notify:GetScript("OnEnter")
    notify:SetScript("OnEnter", function() OTLGM:RefreshQuickDockNotificationBadge182() if notifyEnter then notifyEnter() end end)

    dock:SetScript("OnShow", function() if OTLGM then OTLGM:RefreshQuickDock182("show") end end)
    dock:SetScript("OnHide", function()
        if this.otlParkDrag180 and OTLGM then OTLGM:EndParkDrag180() end
        if OTLGM then OTLGM:CloseQuickDockPopover182() OTLGM:CancelQuickDockRecruitClock182() end
    end)
    dock:Hide()
    self:LayoutQuickDock182("build")
    return dock
end

function OTLGM:GetQuickDockSupportSummary182()
    local dock = self.ui and self.ui.shellParkTab
    local enabled = self:IsQuickDockEnabled182()
    local visible = dock and dock.IsVisible and dock:IsVisible() or false
    local officer = self.IsOfficerMode and self:IsOfficerMode() or false
    local chat = self.GetGuildChatUnread and self:GetGuildChatUnread("GUILD") or 0
    local notifications = self:GetQuickDockNotificationCount183()
    local recruitment = self.GetWorldRecruitmentInfo and self:GetWorldRecruitmentInfo() or { state = "unavailable" }
    return "Quick Dock: " .. (enabled and "enabled" or "crest-only") .. " / " .. (visible and "visible" or "hidden")
        .. " / main X " .. tostring(OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.closeToQuickDock183 ~= false and "parks" or "hides")
        .. " / role " .. (officer and "officer" or "member") .. " / popover " .. tostring(self.ui and self.ui.quickDockPopover182 or "none")
        .. " / unread chat " .. tostring(chat) .. " / notifications " .. tostring(notifications)
        .. " / recruitment " .. tostring(recruitment.state or "unknown")
        .. " / minute clock " .. tostring(self.runtime and self.runtime.quickDockRecruitClockArmed182 and "armed" or "sleeping")
end

OTLGM:RegisterModule("QuickDock182", {
    layer = "ui", revision = 3, parkOnly = true, noOnUpdate = true, cacheConsumer = true,
    actionableNotifications183 = true,
})
