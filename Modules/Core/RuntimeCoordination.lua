-- Order of the Lion Guild Manager v1.7.6 R5
-- Stability, performance and completed officer workflows.
-- Loaded after Performance176.lua. Vanilla / OctoWoW / Lua 5.0 compatible.
-- This module adds no OnUpdate handler and performs no background roster/mail scans.

if not OTLGM then return end

OTLGM.legacyVersionRelease176R5 = "1.7.6"
OTLGM.legacyBuildRelease176R5 = "performance-r5-hotfix1-20260726"

local R5 = {
    revision = 5,
    hiddenRefreshesSkipped = 0,
    refreshAllCollapsed = 0,
    mailboxScansSuppressed = 0,
    bagSlicesDeferred = 0,
    networkPacketsLimited = 0,
    modalOpens = 0,
    modalReplacements = 0,
    treasuryActivities = 0,
    treasuryLedgersOpened = 0,
    whisperInvitesSent = 0,
    whisperInviteRejected = 0,
    uiFixPasses = 0,
}
OTLGM.release176r5 = R5

local MAX_TREASURY_ACTIVITY_R5 = 160
local MAX_TREASURY_ACTIVITY_ROWS_R5 = 11
local MAX_LEDGER_SUMMARY_ROWS_R5 = 7
local MAX_LEDGER_ENTRY_ROWS_R5 = 9
local BAG_SLICE_GAP_R5 = 2
local NETWORK_BUDGET_R5 = tonumber(OTLGM.networkPacketBudget180) or 2
local PARK_TAB_WIDTH_R5 = 30
local PARK_TAB_HEIGHT_R5 = 38
local PARK_TAB_Y_R5 = -176

local function TrimR5(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function ShortNameR5(value)
    value = TrimR5(value)
    local dash = string.find(value, "-", 1, true)
    if dash then value = string.sub(value, 1, dash - 1) end
    return value
end

local function NameKeyR5(value)
    return string.lower(ShortNameR5(value or ""))
end

local function SafeR5(value, maximum)
    if OTLGM.SafeText then return OTLGM:SafeText(value, maximum or 80, false, false) end
    value = TrimR5(value)
    value = string.gsub(value, "[%c]", " ")
    if maximum and string.len(value) > maximum then value = string.sub(value, 1, maximum) end
    return value
end

local function CountR5(tbl)
    local count = 0
    local key
    for key in pairs(tbl or {}) do count = count + 1 end
    return count
end

local function MoneyR5(copper, preferGold)
    copper = math.max(0, math.floor(tonumber(copper) or 0))
    local gold = math.floor(copper / 10000)
    local silver = math.floor(math.mod(copper, 10000) / 100)
    local coin = math.mod(copper, 100)
    if gold > 0 or preferGold then
        local value = tostring(gold) .. "g"
        if silver > 0 then value = value .. " " .. tostring(silver) .. "s" end
        if coin > 0 and gold == 0 then value = value .. " " .. tostring(coin) .. "c" end
        return value
    end
    if silver > 0 then return tostring(silver) .. "s" .. (coin > 0 and (" " .. tostring(coin) .. "c") or "") end
    return tostring(coin) .. "c"
end

local function SetTextR5(button, text)
    if not button then return end
    button.labelText = text or ""
    if button.text then button.text:SetText(text or "") end
end

local function SkinButtonR5(button, style)
    if not button then return end
    button.actionStyle = style or button.actionStyle or "utility"
    if OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(button) end
end

local function SetEnabledR5(button, enabled, reason)
    if not button then return end
    button.disabled = not enabled
    button.disabledReason = enabled and nil or reason
    if OTLGM.SetControlEnabled170 then OTLGM:SetControlEnabled170(button, enabled, reason)
    elseif button.Enable and button.Disable then if enabled then button:Enable() else button:Disable() end end
    SkinButtonR5(button, button.actionStyle)
end

local function BackdropR5(frame, edge)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = edge or 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
end

local function TextR5(parent, template, text, x, y, width, justify)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then label:SetWidth(width) end
    label:SetJustifyH(justify or "LEFT")
    if label.SetJustifyV then label:SetJustifyV("TOP") end
    label:SetText(text or "")
    return label
end

local function ButtonR5(parent, text, x, y, width, height, handler, style)
    local button = CreateFrame("Button", nil, parent)
    if OTLGM.PrepareInteractiveControl170 then OTLGM:PrepareInteractiveControl170(button, "button") end
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetWidth(width)
    button:SetHeight(height)
    BackdropR5(button, 9)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.text:SetWidth(math.max(8, width - 8))
    button.text:SetText(text or "")
    button.actionStyle = style or "utility"
    button.handlerR5 = handler
    button:SetScript("OnEnter", function()
        this.hovered = true
        SkinButtonR5(this, this.actionStyle)
        if this.disabled and this.disabledReason and GameTooltip then
            GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
            GameTooltip:AddLine("Unavailable", 1, 0.72, 0.28)
            GameTooltip:AddLine(this.disabledReason, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function()
        this.hovered = nil
        SkinButtonR5(this, this.actionStyle)
        if GameTooltip then GameTooltip:Hide() end
    end)
    button:SetScript("OnClick", function()
        if this.disabled then return end
        if this.handlerR5 then this.handlerR5(this) end
    end)
    SkinButtonR5(button, style)
    return button
end

local function EditR5(parent, name, x, y, width, height, maximum)
    local edit = CreateFrame("EditBox", name, parent)
    if OTLGM.PrepareInteractiveControl170 then OTLGM:PrepareInteractiveControl170(edit, "editbox") end
    edit:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    edit:SetWidth(width)
    edit:SetHeight(height)
    edit:SetAutoFocus(false)
    edit:SetFontObject("GameFontHighlightSmall")
    edit:SetTextInsets(7, 7, 4, 4)
    if maximum then edit:SetMaxLetters(maximum) end
    BackdropR5(edit, 9)
    edit:SetBackdropColor(0.015, 0.015, 0.015, 1)
    edit:SetBackdropBorderColor(0.34, 0.28, 0.18, 1)
    edit:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    return edit
end

local function IsMainVisibleR5(self)
    return self.ui and self.ui.main and self.ui.main:IsVisible()
end

-- ---------------------------------------------------------------------------
-- Performance pass: the true idle path does not touch hidden pages or mailbox.
-- ---------------------------------------------------------------------------

local PreviousScheduleMailboxR5 = OTLGM.__impl180.ScheduleMailboxScan176__impl1
function OTLGM:ScheduleMailboxScan176(reason)
    -- Mailbox work is allowed only after MAIL_SHOW / MAIL_INBOX_UPDATE and is
    -- already bounded by the canonical Performance176 implementation. Keep the
    -- feature event-driven instead of disabling it or polling outside mailbox UI.
    if not PreviousScheduleMailboxR5 then return false end
    return PreviousScheduleMailboxR5(self, reason)
end

local PreviousProcessMailboxR5 = OTLGM.__impl180.ProcessMailboxScan176__impl1
function OTLGM:ProcessMailboxScan176()
    if not (self.runtime and self.runtime.mailScan176) then return false end
    if not PreviousProcessMailboxR5 then self.runtime.mailScan176 = nil return false end
    return PreviousProcessMailboxR5(self)
end

local PreviousBagSliceR5 = OTLGM.__impl180.ProcessIncrementalBagScan176__impl1
if PreviousBagSliceR5 then
    function OTLGM:ProcessIncrementalBagScan176()
        self.runtime = self.runtime or {}
        local active = self.runtime.incrementalBagScan176 and true or false
        local dueAt = tonumber(self.runtime.incrementalBagDue176)
        if not active and not dueAt then
            self.runtime.nextBagSliceR5 = nil
            return false
        end
        local now = self:Now()
        local preciseNow = self.GetPreciseTime180 and self:GetPreciseTime180() or now
        if self.InCombat and self:InCombat() then
            R5.bagSlicesDeferred = R5.bagSlicesDeferred + 1
            return false
        end
        -- nextBagSliceR5 belongs only to an already-started incremental scan.
        -- A new BAG_UPDATE request must not inherit a stale slice deadline from
        -- an older completed/cancelled scan and wake the scheduler pointlessly.
        if not active then
            if dueAt and now < dueAt then return false end
            self.runtime.nextBagSliceR5 = nil
        elseif tonumber(self.runtime.nextBagSliceR5 or 0) > preciseNow then
            R5.bagSlicesDeferred = R5.bagSlicesDeferred + 1
            return false
        end

        local ok, result = pcall(PreviousBagSliceR5, self)
        if not ok then
            -- Never leave a failed slice permanently overdue, but also do not
            -- discard a whole achievement/bag refresh because of one transient
            -- API/addon-hook failure. Restart the bounded scan at most twice; a
            -- persistent defect then sleeps until a genuine future bag event.
            local failures = math.min(3, (tonumber(self.runtime.incrementalBagFailuresR6) or 0) + 1)
            self.runtime.incrementalBagFailuresR6 = failures
            self.runtime.incrementalBagScan176 = nil
            self.runtime.nextBagSliceR5 = nil
            if failures < 3 then
                self.runtime.incrementalBagDue176 = self:Now() + 2
            else
                self.runtime.incrementalBagDue176 = nil
            end
            if self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Quality/INCREMENTAL_BAG_SCAN", result) end
            return false
        end
        if self.runtime.incrementalBagScan176 then
            self.runtime.nextBagSliceR5 = preciseNow + BAG_SLICE_GAP_R5
        else
            self.runtime.nextBagSliceR5 = nil
            self.runtime.incrementalBagFailuresR6 = 0
        end
        return result
    end
end

local PreviousNetworkQueueR5 = OTLGM.__impl180.ProcessNetworkQueue__impl3
if PreviousNetworkQueueR5 then
    function OTLGM:ProcessNetworkQueue(maximum)
        local requested = tonumber(maximum) or NETWORK_BUDGET_R5
        local limited = math.max(1, math.min(NETWORK_BUDGET_R5, requested))
        if requested > limited then R5.networkPacketsLimited = R5.networkPacketsLimited + (requested - limited) end
        return PreviousNetworkQueueR5(self, limited)
    end
end

local refreshDirtyMapR5 = {
    home = "home", overview = "overview", roster = "roster", professions = "professions",
    pve = "pve", guildchat = "guildchat", activity = "activity", recruitment = "recruitment",
    history = "history", inactive = "inactive", achievements = "achievements", treasury = "treasury",
}

local function MarkPageDirtyR5(self, page)
    self.runtime = self.runtime or {}
    self.runtime.pageDirtyR5 = self.runtime.pageDirtyR5 or {}
    self.runtime.pageDirtyR5[page] = true
    R5.hiddenRefreshesSkipped = R5.hiddenRefreshesSkipped + 1
end

local function CanRefreshPageR5(self, page)
    if not self.ui or not self.ui.main then return true end
    if not self.ui.main:IsVisible() then MarkPageDirtyR5(self, page) return false end
    if self.ui.currentPage ~= page then MarkPageDirtyR5(self, page) return false end
    if self.runtime and self.runtime.pageDirtyR5 then self.runtime.pageDirtyR5[page] = nil end
    return true
end

local function GuardNoArgRefreshR5(methodName, page)
    local base = OTLGM[methodName]
    if type(base) ~= "function" then return end
    OTLGM[methodName] = function(self)
        if not CanRefreshPageR5(self, page) then return false end
        return base(self)
    end
end

GuardNoArgRefreshR5("RefreshHomePage", "home")
GuardNoArgRefreshR5("RefreshOverviewPage", "overview")
GuardNoArgRefreshR5("RefreshRosterPage", "roster")
GuardNoArgRefreshR5("RefreshProfessionsPage", "professions")
GuardNoArgRefreshR5("RefreshPvePage", "pve")
GuardNoArgRefreshR5("RefreshGuildChatPage", "guildchat")
GuardNoArgRefreshR5("RefreshActivityPage", "activity")
GuardNoArgRefreshR5("RefreshRecruitmentPage", "recruitment")
GuardNoArgRefreshR5("RefreshHistoryPage", "history")
GuardNoArgRefreshR5("RefreshInactivePage", "inactive")

local PreviousRefreshAchievementsR5 = OTLGM.__impl180.RefreshAchievements174__impl6
if PreviousRefreshAchievementsR5 then
    function OTLGM:RefreshAchievements174()
        if not CanRefreshPageR5(self, "achievements") then return false end
        return PreviousRefreshAchievementsR5(self)
    end
end

local PreviousRefreshTreasuryR5 = OTLGM.__impl180.RefreshTreasuryPage170__impl3
if PreviousRefreshTreasuryR5 then
    function OTLGM.__impl180.RefreshTreasuryPage170__impl4(self, forceEditor)
        if not CanRefreshPageR5(self, "treasury") then return false end
        return PreviousRefreshTreasuryR5(self, forceEditor)
    end
end

local PreviousRefreshAllR5 = OTLGM.__impl180.RefreshAll__impl2

-- ---------------------------------------------------------------------------
-- One exclusive modal layer for Treasury and recruitment dialogs.
-- ---------------------------------------------------------------------------

function OTLGM:BuildExclusiveModalOverlayR5()
    self.ui = self.ui or {}
    if self.ui.exclusiveModalOverlayR5 then return end
    local overlay = CreateFrame("Button", "OTLGM_ExclusiveModalOverlayR5", UIParent)
    if self.PrepareInteractiveControl170 then self:PrepareInteractiveControl170(overlay, "button") end
    overlay:SetAllPoints(UIParent)
    overlay:SetFrameStrata("DIALOG")
    overlay:SetFrameLevel(180)
    BackdropR5(overlay, 0)
    overlay:SetBackdropColor(0, 0, 0, 0.78)
    overlay:SetBackdropBorderColor(0, 0, 0, 0)
    overlay:SetScript("OnClick", function() if OTLGM and OTLGM.CloseExclusiveModalR5 then OTLGM:CloseExclusiveModalR5() end end)
    overlay:Hide()
    self.ui.exclusiveModalOverlayR5 = overlay
end

function OTLGM:AttachExclusiveModalR5(frame)
    if not frame or frame.exclusiveAttachedR5 then return end
    frame.exclusiveAttachedR5 = true
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(202)
    local previousOnHideR5 = frame.GetScript and frame:GetScript("OnHide") or nil
    frame:SetScript("OnHide", function()
        if previousOnHideR5 then previousOnHideR5() end
        if OTLGM and OTLGM.ui and OTLGM.ui.exclusiveModalR5 == this then
            OTLGM.ui.exclusiveModalR5 = nil
            if OTLGM.ui.exclusiveModalOverlayR5 then OTLGM.ui.exclusiveModalOverlayR5:Hide() end
        end
    end)
end

function OTLGM.__impl180.OpenExclusiveModalR5__impl1(self, frame)
    if not frame then return false end
    self:BuildExclusiveModalOverlayR5()
    self:AttachExclusiveModalR5(frame)
    local old = self.ui.exclusiveModalR5
    if old and old ~= frame and old:IsVisible() then
        R5.modalReplacements = R5.modalReplacements + 1
        old:Hide()
    end
    self.ui.exclusiveModalR5 = frame
    self.ui.exclusiveModalOverlayR5:Show()
    frame:SetFrameLevel(self.ui.exclusiveModalOverlayR5:GetFrameLevel() + 2)
    frame:Show()
    R5.modalOpens = R5.modalOpens + 1
    return true
end

local PreviousOpenRecentWhispersR5 = OTLGM.__impl180.OpenRecentWhispers176__impl1
if PreviousOpenRecentWhispersR5 then
    function OTLGM.__impl180.OpenRecentWhispers176__impl2(self)
        PreviousOpenRecentWhispersR5(self)
        local dialog = self.ui and self.ui.recentWhisperDialog176
        if dialog then self:OpenExclusiveModalR5(dialog) end
    end
end

local PreviousOpenContributionR5 = OTLGM.__impl180.OpenTreasuryContributionDialog176__impl1
if PreviousOpenContributionR5 then
    function OTLGM.__impl180.OpenTreasuryContributionDialog176__impl2(self)
        PreviousOpenContributionR5(self)
        local dialog = self.ui and self.ui.treasuryContributionDialog176
        if dialog and dialog:IsVisible() then self:OpenExclusiveModalR5(dialog) end
    end
end

local PreviousShowPageR5 = OTLGM.__impl180.ShowPage__impl1
if PreviousShowPageR5 then
end

-- ---------------------------------------------------------------------------
-- Functional recent-whisper invitation flow.
-- ---------------------------------------------------------------------------

function OTLGM:IsGuildMemberNameR5(name)
    name = ShortNameR5(name)
    if name == "" then return false end
    if self.GetMember and self:GetMember(name) then return true end
    if self.GetGuildMemberSet174 then
        local members = self:GetGuildMemberSet174()
        if members and members[NameKeyR5(name)] then return true end
    end
    return false
end

function OTLGM:CanInviteGuildMembersR5(force)
    if self.IsGuildLeader170 and self:IsGuildLeader170() then return true, "guild-leader" end
    if type(CanGuildInvite) == "function" then
        local ok, allowed = pcall(CanGuildInvite)
        if ok then return allowed and true or false, "client-api" end
    end
    self.runtime = self.runtime or {}
    local now = GetTime and GetTime() or self:Now()
    local cached = self.runtime.invitePermissionR5
    if not force and cached and now - (tonumber(cached.checkedAt) or 0) < 5 then return cached.allowed, cached.source end
    local allowed = false
    local source = "unavailable"
    local rankIndex = self.GetPlayerGuildRankIndex170 and self:GetPlayerGuildRankIndex170() or nil
    if rankIndex ~= nil and type(GuildControlSetRank) == "function" and type(GuildControlGetRankFlags) == "function" then
        local selected = pcall(GuildControlSetRank, rankIndex + 1)
        if selected then
            local ok, guildListen, guildSpeak, officerListen, officerSpeak, promote, demote, inviteMember = pcall(GuildControlGetRankFlags)
            if ok then allowed = inviteMember and true or false source = "rank-flags" end
        end
    end
    if source == "unavailable" and self.IsOfficerMode then allowed = self:IsOfficerMode() and true or false source = "officer-fallback" end
    self.runtime.invitePermissionR5 = { allowed = allowed, source = source, checkedAt = now }
    return allowed, source
end

function OTLGM:InviteGuildCandidate180(name, source)
    name = ShortNameR5(name)
    if name == "" then return false, "Enter a character name." end
    local player = ShortNameR5(UnitName and UnitName("player") or "")
    if NameKeyR5(name) == NameKeyR5(player) then return false, "You cannot invite yourself." end
    if self:IsGuildMemberNameR5(name) then
        if self.ShowNotice then self:ShowNotice("Guild Invite", name .. " is already in the guild.") end
        return false, "Already in guild."
    end
    local allowed = self:CanInviteGuildMembersR5(true)
    if not allowed then
        if self.ShowNotice then self:ShowNotice("Guild Invite", "Your current guild rank cannot invite members.") end
        return false, "Your guild rank cannot invite members."
    end
    local inviteFunction = nil
    if type(GuildInvite) == "function" then inviteFunction = GuildInvite
    elseif type(GuildInviteByName) == "function" then inviteFunction = GuildInviteByName end
    if not inviteFunction then
        if self.ShowNotice then self:ShowNotice("Guild Invite", "Guild invitation API is unavailable on this client.") end
        return false, "Guild invitation API is unavailable."
    end
    local ok, problem = pcall(inviteFunction, name)
    if not ok then
        if self.ShowNotice then self:ShowNotice("Guild Invite", tostring(problem or "Invite failed.")) end
        return false, tostring(problem or "Invite failed.")
    end
    self.runtime = self.runtime or {}
    self.runtime.lastManualGuildInvite180 = { name = name, source = tostring(source or "manual"), ts = self:Now() }
    if self.SetStatus then self:SetStatus("Guild invite sent to " .. name .. ".") end
    return true, "Invite sent."
end

function OTLGM:InviteRecentWhisper176(name)
    name = ShortNameR5(name)
    if name == "" then R5.whisperInviteRejected = R5.whisperInviteRejected + 1 return false, "Invalid player name." end
    local player = ShortNameR5(UnitName and UnitName("player") or "")
    if NameKeyR5(name) == NameKeyR5(player) then R5.whisperInviteRejected = R5.whisperInviteRejected + 1 return false, "You cannot invite yourself." end
    if self:IsGuildMemberNameR5(name) then
        R5.whisperInviteRejected = R5.whisperInviteRejected + 1
        self.runtime = self.runtime or {}
        self.runtime.recentWhisperInviteStateR5 = self.runtime.recentWhisperInviteStateR5 or {}
        self.runtime.recentWhisperInviteStateR5[NameKeyR5(name)] = { state = "MEMBER", ts = self:Now() }
        if self.ShowNotice then self:ShowNotice("Guild Invite", name .. " is already in the guild.") end
        if self.RefreshRecentWhispers176 then self:RefreshRecentWhispers176() end
        return false, "Already in guild."
    end
    local allowed = self:CanInviteGuildMembersR5(true)
    if not allowed then
        R5.whisperInviteRejected = R5.whisperInviteRejected + 1
        if self.ShowNotice then self:ShowNotice("Guild Invite", "Your current guild rank cannot invite members.") end
        return false, "No invite permission."
    end
    local inviteFunction = nil
    if type(GuildInvite) == "function" then inviteFunction = GuildInvite
    elseif type(GuildInviteByName) == "function" then inviteFunction = GuildInviteByName end
    if not inviteFunction then
        R5.whisperInviteRejected = R5.whisperInviteRejected + 1
        if self.ShowNotice then self:ShowNotice("Guild Invite", "Guild invitation API is unavailable on this client.") end
        return false, "Invite API unavailable."
    end
    local ok, problem = pcall(inviteFunction, name)
    if not ok then
        R5.whisperInviteRejected = R5.whisperInviteRejected + 1
        if self.ShowNotice then self:ShowNotice("Guild Invite", tostring(problem or "Invite failed.")) end
        return false, tostring(problem or "Invite failed.")
    end
    self.runtime = self.runtime or {}
    self.runtime.recentWhisperInviteStateR5 = self.runtime.recentWhisperInviteStateR5 or {}
    self.runtime.recentWhisperInviteStateR5[NameKeyR5(name)] = { state = "SENT", ts = self:Now() }
    R5.whisperInvitesSent = R5.whisperInvitesSent + 1
    if self.SetStatus then self:SetStatus("Guild invite sent to " .. name .. ".") end
    if self.RefreshRecentWhispers176 then self:RefreshRecentWhispers176() end
    return true, "Invite sent."
end

local PreviousBuildWhispersR5 = OTLGM.__impl180.BuildRecentWhisperDialog176__impl1
if PreviousBuildWhispersR5 then
    function OTLGM.__impl180.BuildRecentWhisperDialog176__impl2(self)
        PreviousBuildWhispersR5(self)
        local dialog = self.ui and self.ui.recentWhisperDialog176
        if not dialog or dialog.repairedR5 then return end
        dialog.repairedR5 = true
        self:AttachExclusiveModalR5(dialog)
        local index, row
        for index = 1, table.getn(dialog.rows176 or {}) do
            row = dialog.rows176[index]
            if row and row.invite176 then
                row.invite176:SetScript("OnClick", function()
                    local entry = this.entryR5
                    if not entry then return end
                    OTLGM:InviteRecentWhisper176(entry.name)
                end)
            end
        end
    end
end

local PreviousRefreshWhispersR5 = OTLGM.__impl180.RefreshRecentWhispers176__impl1
if PreviousRefreshWhispersR5 then
end

-- ---------------------------------------------------------------------------
-- Treasury event stream and per-goal ledger.
-- ---------------------------------------------------------------------------

local function TreasuryActivityIdR5(prefix, id, revision)
    return SafeR5(prefix, 12) .. ":" .. SafeR5(id, 48) .. ":" .. tostring(math.floor(tonumber(revision) or 0))
end

function OTLGM:EnsureTreasuryActivityR5()
    local treasury = self:EnsureTreasury170()
    if not treasury then return nil end
    if type(treasury.activityR5) ~= "table" then treasury.activityR5 = {} end
    if type(treasury.activitySeenR5) ~= "table" then treasury.activitySeenR5 = {} end
    if not treasury.activityMigratedR5 then
        local rows = {}
        local goalId, entries, index, entry, history
        for goalId, entries in pairs(treasury.contributions176 or {}) do
            for index = 1, table.getn(entries or {}) do
                entry = entries[index]
                if type(entry) == "table" and entry.id then
                    table.insert(rows, {
                        id = "CONTRIB:" .. tostring(entry.id), kind = "CONTRIBUTION", goalId = goalId,
                        ts = tonumber(entry.ts) or 0, actor = SafeR5(entry.actor or "Leadership", 28),
                        contributor = SafeR5(entry.contributor or "Anonymous", 28), amount = math.max(0, tonumber(entry.amount) or 0),
                        note = SafeR5(entry.note or "", 64), current = math.max(0, tonumber(entry.current) or 0),
                    })
                end
            end
        end
        for index = 1, table.getn(treasury.history or {}) do
            history = treasury.history[index]
            if type(history) == "table" then
                table.insert(rows, {
                    id = TreasuryActivityIdR5("LEGACY", history.id or "GOAL", (history.ts or 0) + index),
                    kind = string.find(string.upper(tostring(history.kind or "")), "DELETE", 1, true) and "GOAL_DELETE" or "GOAL_CHANGE",
                    goalId = SafeR5(history.id or "", 32), goalName = SafeR5(history.name or "Guild Goal", 42),
                    ts = tonumber(history.ts) or 0, actor = SafeR5(history.actor or "Leadership", 28),
                    current = math.max(0, tonumber(history.current) or 0), target = math.max(0, tonumber(history.target) or 0),
                })
            end
        end
        table.sort(rows, function(left, right)
            if (tonumber(left.ts) or 0) ~= (tonumber(right.ts) or 0) then return (tonumber(left.ts) or 0) > (tonumber(right.ts) or 0) end
            return tostring(left.id or "") < tostring(right.id or "")
        end)
        for index = 1, math.min(MAX_TREASURY_ACTIVITY_R5, table.getn(rows)) do
            entry = rows[index]
            if entry.id and not treasury.activitySeenR5[entry.id] then
                treasury.activitySeenR5[entry.id] = entry.ts or 0
                table.insert(treasury.activityR5, entry)
            end
        end
        treasury.activityMigratedR5 = true
    end
    while table.getn(treasury.activityR5) > MAX_TREASURY_ACTIVITY_R5 do table.remove(treasury.activityR5) end
    if CountR5(treasury.activitySeenR5) > MAX_TREASURY_ACTIVITY_R5 * 2 then
        local keep = {}
        local index, entry
        for index = 1, table.getn(treasury.activityR5) do
            entry = treasury.activityR5[index]
            if entry and entry.id then keep[entry.id] = entry.ts or 0 end
        end
        treasury.activitySeenR5 = keep
    end
    return treasury
end

function OTLGM:AddTreasuryActivityR5(entry)
    if type(entry) ~= "table" then return false end
    local treasury = self:EnsureTreasuryActivityR5()
    if not treasury then return false end
    entry.id = SafeR5(entry.id, 72)
    if entry.id == "" or treasury.activitySeenR5[entry.id] then return false end
    entry.kind = SafeR5(entry.kind or "GOAL_CHANGE", 20)
    entry.goalId = SafeR5(entry.goalId or "", 32)
    entry.goalName = SafeR5(entry.goalName or "", 42)
    entry.ts = math.max(0, math.floor(tonumber(entry.ts) or self:Now()))
    entry.actor = SafeR5(entry.actor or "Leadership", 28)
    entry.contributor = SafeR5(entry.contributor or "", 28)
    entry.amount = math.max(0, math.floor(tonumber(entry.amount) or 0))
    entry.current = math.max(0, math.floor(tonumber(entry.current) or 0))
    entry.target = math.max(0, math.floor(tonumber(entry.target) or 0))
    entry.note = SafeR5(entry.note or "", 64)
    treasury.activitySeenR5[entry.id] = entry.ts
    table.insert(treasury.activityR5, 1, entry)
    while table.getn(treasury.activityR5) > MAX_TREASURY_ACTIVITY_R5 do
        local removed = table.remove(treasury.activityR5)
        if removed and removed.id then treasury.activitySeenR5[removed.id] = nil end
    end
    R5.treasuryActivities = R5.treasuryActivities + 1
    if self.ui and self.ui.treasuryActivityDialogR5 and self.ui.treasuryActivityDialogR5:IsVisible() then self:RefreshTreasuryActivityR5() end
    if self.ui and self.ui.treasuryLedgerDialogR5 and self.ui.treasuryLedgerDialogR5:IsVisible() then self:RefreshTreasuryGoalLedgerR5() end
    return true
end

function OTLGM:GetTreasuryActivityR5(mode)
    local treasury = self:EnsureTreasuryActivityR5()
    local result = {}
    local index, entry
    mode = mode or "ALL"
    for index = 1, table.getn(treasury and treasury.activityR5 or {}) do
        entry = treasury.activityR5[index]
        if mode == "ALL"
            or (mode == "CONTRIBUTIONS" and entry.kind == "CONTRIBUTION")
            or (mode == "GOALS" and entry.kind ~= "CONTRIBUTION") then table.insert(result, entry) end
    end
    return result
end

local PreviousSetTreasuryGoalR5 = OTLGM.__impl180.SetTreasuryGoal170__impl1
if PreviousSetTreasuryGoalR5 then
    function OTLGM:SetTreasuryGoal170(id, name, current, target, category)
        local old = self.GetTreasuryGoal170 and self:GetTreasuryGoal170(id) or nil
        local oldRevision = old and tonumber(old.revision) or 0
        local ok, result = PreviousSetTreasuryGoalR5(self, id, name, current, target, category)
        if ok and not (self.runtime and self.runtime.recordingContributionR5) then
            local goal = self:GetTreasuryGoal170(id)
            self:AddTreasuryActivityR5({
                id = TreasuryActivityIdR5(old and "GOAL_UPDATE" or "GOAL_CREATE", id, goal and goal.revision or oldRevision + 1),
                kind = old and "GOAL_UPDATE" or "GOAL_CREATE", goalId = id, goalName = goal and goal.name or name,
                ts = goal and goal.updatedAt or self:Now(), actor = goal and goal.updatedBy or ShortNameR5(UnitName and UnitName("player") or "Leadership"),
                current = goal and goal.current or current, target = goal and goal.target or target,
            })
        end
        return ok, result
    end
end

local PreviousDeleteTreasuryGoalR5 = OTLGM.__impl180.DeleteTreasuryGoal170__impl1
if PreviousDeleteTreasuryGoalR5 then
    function OTLGM:DeleteTreasuryGoal170(id)
        local old = self.GetTreasuryGoal170 and self:GetTreasuryGoal170(id) or nil
        local ok, result = PreviousDeleteTreasuryGoalR5(self, id)
        if ok then
            self:AddTreasuryActivityR5({
                id = TreasuryActivityIdR5("GOAL_DELETE", id, self:Now()), kind = "GOAL_DELETE", goalId = id,
                goalName = old and old.name or "Guild Goal", ts = self:Now(),
                actor = ShortNameR5(UnitName and UnitName("player") or "Leadership"),
                current = old and old.current or 0, target = old and old.target or 0,
            })
        end
        return ok, result
    end
end

local PreviousAddTreasuryContributionR5 = OTLGM.__impl180.AddTreasuryContribution176__impl1
if PreviousAddTreasuryContributionR5 then
    function OTLGM.__impl180.AddTreasuryContribution176__impl2(self, goalId, contributor, amountCopper, note)
        self.runtime = self.runtime or {}
        self.runtime.recordingContributionR5 = true
        local ok, result = PreviousAddTreasuryContributionR5(self, goalId, contributor, amountCopper, note)
        self.runtime.recordingContributionR5 = nil
        if ok and result then
            local goal = self:GetTreasuryGoal170(goalId)
            self:AddTreasuryActivityR5({
                id = "CONTRIB:" .. tostring(result.id or ""), kind = "CONTRIBUTION", goalId = goalId,
                goalName = goal and goal.name or "Guild Goal", ts = result.ts, actor = result.actor,
                contributor = result.contributor, amount = result.amount, current = result.current,
                target = goal and goal.target or 0, note = result.note,
            })
        end
        return ok, result
    end
end

local PreviousHandleTreasuryR5 = OTLGM.__impl180.HandleTreasuryMessage170__impl2
if PreviousHandleTreasuryR5 then
    function OTLGM.__impl180.HandleTreasuryMessage170__impl3(self, message, channel, sender)
        local fields = self:Split(message or "", "^")
        local kind = fields[2] or ""
        local oldGoal = nil
        if kind == "DEL" and self.GetTreasuryGoal170 then oldGoal = self:GetTreasuryGoal170(fields[3] or "") end
        local handled = PreviousHandleTreasuryR5(self, message, channel, sender)
        if handled and kind == "CONTRIB" then
            local goalId = SafeR5(fields[3] or "", 32)
            local entryId = SafeR5(fields[4] or "", 48)
            local entries = self.GetTreasuryContributions176 and self:GetTreasuryContributions176(goalId) or {}
            local index, entry
            for index = 1, table.getn(entries) do if entries[index].id == entryId then entry = entries[index] break end end
            local goal = self.GetTreasuryGoal170 and self:GetTreasuryGoal170(goalId) or nil
            if entry then
                self:AddTreasuryActivityR5({
                    id = "CONTRIB:" .. entryId, kind = "CONTRIBUTION", goalId = goalId,
                    goalName = goal and goal.name or "Guild Goal", ts = entry.ts, actor = entry.actor,
                    contributor = entry.contributor, amount = entry.amount, current = entry.current,
                    target = goal and goal.target or 0, note = entry.note,
                })
            end
        elseif handled and kind == "GOAL" then
            local goalId = SafeR5(fields[3] or "", 32)
            local goal = self.GetTreasuryGoal170 and self:GetTreasuryGoal170(goalId) or nil
            if goal then
                self:AddTreasuryActivityR5({
                    id = TreasuryActivityIdR5("NET_GOAL", goalId, goal.revision), kind = "GOAL_CHANGE",
                    goalId = goalId, goalName = goal.name, ts = goal.updatedAt,
                    actor = goal.updatedBy or sender, current = goal.current, target = goal.target,
                })
            end
        elseif handled and kind == "DEL" then
            local goalId = SafeR5(fields[3] or "", 32)
            self:AddTreasuryActivityR5({
                id = TreasuryActivityIdR5("NET_DELETE", goalId, fields[4]), kind = "GOAL_DELETE",
                goalId = goalId, goalName = oldGoal and oldGoal.name or "Guild Goal",
                ts = tonumber(fields[5]) or self:Now(), actor = sender or "Leadership",
                current = oldGoal and oldGoal.current or 0, target = oldGoal and oldGoal.target or 0,
            })
        end
        return handled
    end
end

function OTLGM:GetTreasuryGoalLedgerR5(goalId)
    local goal = self.GetTreasuryGoal170 and self:GetTreasuryGoal170(goalId) or nil
    local entries = self.GetTreasuryContributions176 and self:GetTreasuryContributions176(goalId) or {}
    local aggregate = {}
    local sum = 0
    local index, entry, key, row
    for index = 1, table.getn(entries) do
        entry = entries[index]
        key = NameKeyR5(entry.contributor or "Anonymous")
        if key == "" then key = "anonymous" end
        row = aggregate[key]
        if not row then row = { name = SafeR5(entry.contributor or "Anonymous", 28), amount = 0, count = 0, lastAt = 0 } aggregate[key] = row end
        row.amount = row.amount + math.max(0, tonumber(entry.amount) or 0)
        row.count = row.count + 1
        row.lastAt = math.max(row.lastAt, tonumber(entry.ts) or 0)
        sum = sum + math.max(0, tonumber(entry.amount) or 0)
    end
    local contributors = {}
    for key, row in pairs(aggregate) do table.insert(contributors, row) end
    table.sort(contributors, function(left, right)
        if left.amount ~= right.amount then return left.amount > right.amount end
        return string.lower(left.name or "") < string.lower(right.name or "")
    end)
    return { goal = goal, entries = entries, contributors = contributors, recorded = sum }
end

local function ActivityLineR5(self, entry)
    local stamp = date("%d %b %H:%M", entry.ts or self:Now())
    local goalName = entry.goalName ~= "" and entry.goalName or entry.goalId
    if entry.kind == "CONTRIBUTION" then
        local note = entry.note and entry.note ~= "" and (" - " .. entry.note) or ""
        return stamp .. "  " .. tostring(entry.contributor or "Anonymous") .. "  +" .. MoneyR5(entry.amount) .. "  -> " .. tostring(goalName or "Goal") .. "  by " .. tostring(entry.actor or "Leadership") .. note
    end
    if entry.kind == "GOAL_DELETE" then return stamp .. "  " .. tostring(entry.actor or "Leadership") .. " removed " .. tostring(goalName or "Guild Goal") end
    if entry.kind == "GOAL_CREATE" then return stamp .. "  " .. tostring(entry.actor or "Leadership") .. " created " .. tostring(goalName or "Guild Goal") end
    return stamp .. "  " .. tostring(entry.actor or "Leadership") .. " updated " .. tostring(goalName or "Guild Goal") .. "  " .. MoneyR5(entry.current, true) .. " / " .. MoneyR5(entry.target, true)
end

function OTLGM.__impl180.BuildTreasuryActivityR5__impl1(self)
    self.ui = self.ui or {}
    if self.ui.treasuryActivityDialogR5 then return end
    local dialog = CreateFrame("Frame", "OTLGM_TreasuryActivityR5", UIParent)
    dialog:SetWidth(720) dialog:SetHeight(510)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
    BackdropR5(dialog, 14)
    dialog:SetBackdropColor(0.012, 0.013, 0.015, 0.998)
    dialog:SetBackdropBorderColor(0.72, 0.48, 0.16, 1)
    dialog:EnableMouse(true) dialog:SetMovable(true) dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", function() this:StartMoving() end)
    dialog:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    dialog:Hide()
    self.ui.treasuryActivityDialogR5 = dialog
    self:AttachExclusiveModalR5(dialog)
    TextR5(dialog, "GameFontNormalLarge", "Treasury Activity", 18, -16, 420, "LEFT")
    local subtitle = TextR5(dialog, "GameFontNormalSmall", "Contributions and goal changes. The list is built only while this window is open.", 18, -44, 620, "LEFT")
    subtitle:SetTextColor(0.64, 0.64, 0.61)
    ButtonR5(dialog, "X", 674, -12, 28, 26, function() OTLGM:CloseExclusiveModalR5(dialog) end, "danger")
    dialog.modeR5 = "ALL"
    dialog.offsetR5 = 0
    dialog.tabsR5 = {}
    local definitions = { {"ALL", "All"}, {"CONTRIBUTIONS", "Contributions"}, {"GOALS", "Goal changes"} }
    local index, mode
    for index = 1, table.getn(definitions) do
        mode = definitions[index][1]
        dialog.tabsR5[mode] = ButtonR5(dialog, definitions[index][2], 18 + ((index - 1) * 142), -70, 132, 28, function(button)
            dialog.modeR5 = button.modeR5
            dialog.offsetR5 = 0
            OTLGM:RefreshTreasuryActivityR5()
        end, "utility")
        dialog.tabsR5[mode].modeR5 = mode
    end
    dialog.rowsR5 = {}
    for index = 1, MAX_TREASURY_ACTIVITY_ROWS_R5 do
        local row = CreateFrame("Frame", nil, dialog)
        row:SetPoint("TOPLEFT", dialog, "TOPLEFT", 18, -110 - ((index - 1) * 31))
        row:SetWidth(684) row:SetHeight(27)
        BackdropR5(row, 6)
        row:SetBackdropColor(0.025, 0.024, 0.022, index / 2 == math.floor(index / 2) and 0.94 or 0.72)
        row:SetBackdropBorderColor(0.22, 0.20, 0.16, 1)
        row.textR5 = TextR5(row, "GameFontNormalSmall", "", 8, -7, 648, "LEFT")
        dialog.rowsR5[index] = row
    end
    if OTLGM.UI and OTLGM.UI.Scrollbar then
        dialog.scrollR6 = OTLGM.UI:Scrollbar(dialog, 350, function(value)
            dialog.offsetR5 = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
            OTLGM:RefreshTreasuryActivityR5()
        end)
        dialog.scrollR6:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -10, -106)
        dialog:EnableMouseWheel(true)
        dialog:SetScript("OnMouseWheel", function()
            local maximum = tonumber(this.maximumOffsetR6) or 0
            local value = math.max(0, math.min(maximum, (tonumber(this.offsetR5) or 0) - ((tonumber(arg1) or 0) * 3)))
            this.offsetR5 = value
            OTLGM:RefreshTreasuryActivityR5()
        end)
    end
    dialog.prevR5 = ButtonR5(dialog, "<", 18, -466, 42, 26, function() dialog.offsetR5 = math.max(0, (dialog.offsetR5 or 0) - MAX_TREASURY_ACTIVITY_ROWS_R5) OTLGM:RefreshTreasuryActivityR5() end, "utility")
    dialog.nextR5 = ButtonR5(dialog, ">", 66, -466, 42, 26, function() dialog.offsetR5 = (dialog.offsetR5 or 0) + MAX_TREASURY_ACTIVITY_ROWS_R5 OTLGM:RefreshTreasuryActivityR5() end, "utility")
    dialog.statusR5 = TextR5(dialog, "GameFontNormalSmall", "", 118, -473, 280, "LEFT")
end

function OTLGM:RefreshTreasuryActivityR5()
    self:BuildTreasuryActivityR5()
    local dialog = self.ui and self.ui.treasuryActivityDialogR5
    if not dialog then return end
    local entries = self:GetTreasuryActivityR5(dialog.modeR5)
    local maximum = math.max(0, table.getn(entries) - MAX_TREASURY_ACTIVITY_ROWS_R5)
    dialog.offsetR5 = math.max(0, math.min(maximum, tonumber(dialog.offsetR5) or 0))
    local index, entry, row
    for index = 1, MAX_TREASURY_ACTIVITY_ROWS_R5 do
        row = dialog.rowsR5[index]
        entry = entries[dialog.offsetR5 + index]
        if entry then row.textR5:SetText(ActivityLineR5(self, entry)) row:Show() else row:Hide() end
    end
    for index, row in pairs(dialog.tabsR5) do row.selected = index == dialog.modeR5 SkinButtonR5(row, "utility") end
    dialog.maximumOffsetR6 = maximum
    if dialog.scrollR6 and dialog.scrollR6.SetScrollMetrics180 then
        dialog.scrollR6:SetScrollMetrics180(table.getn(entries), MAX_TREASURY_ACTIVITY_ROWS_R5, dialog.offsetR5)
    end
    if dialog.prevR5 then dialog.prevR5:Hide() end
    if dialog.nextR5 then dialog.nextR5:Hide() end
    if table.getn(entries) == 0 then dialog.statusR5:SetText("No treasury activity recorded yet.")
    else dialog.statusR5:SetText(tostring(dialog.offsetR5 + 1) .. "-" .. tostring(math.min(dialog.offsetR5 + MAX_TREASURY_ACTIVITY_ROWS_R5, table.getn(entries))) .. " / " .. tostring(table.getn(entries))) end
end

function OTLGM.__impl180.OpenTreasuryActivityR5__impl1(self)
    self:BuildTreasuryActivityR5()
    self:RefreshTreasuryActivityR5()
    return self:OpenExclusiveModalR5(self.ui.treasuryActivityDialogR5)
end

function OTLGM.__impl180.BuildTreasuryGoalLedgerR5__impl1(self)
    self.ui = self.ui or {}
    if self.ui.treasuryLedgerDialogR5 then return end
    local dialog = CreateFrame("Frame", "OTLGM_TreasuryLedgerR5", UIParent)
    dialog:SetWidth(760) dialog:SetHeight(540)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
    BackdropR5(dialog, 14)
    dialog:SetBackdropColor(0.012, 0.013, 0.015, 0.998)
    dialog:SetBackdropBorderColor(0.72, 0.48, 0.16, 1)
    dialog:EnableMouse(true) dialog:SetMovable(true) dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", function() this:StartMoving() end)
    dialog:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    dialog:Hide()
    self.ui.treasuryLedgerDialogR5 = dialog
    self:AttachExclusiveModalR5(dialog)
    dialog.titleR5 = TextR5(dialog, "GameFontNormalLarge", "Goal Ledger", 18, -16, 540, "LEFT")
    dialog.totalR5 = TextR5(dialog, "GameFontNormal", "", 18, -48, 690, "LEFT")
    dialog.metaR5 = TextR5(dialog, "GameFontNormalSmall", "", 18, -72, 690, "LEFT")
    dialog.metaR5:SetTextColor(0.64, 0.64, 0.61)
    ButtonR5(dialog, "X", 714, -12, 28, 26, function() OTLGM:CloseExclusiveModalR5(dialog) end, "danger")

    local summary = CreateFrame("Frame", nil, dialog)
    summary:SetPoint("TOPLEFT", dialog, "TOPLEFT", 18, -104)
    summary:SetWidth(250) summary:SetHeight(382)
    BackdropR5(summary, 10)
    summary:SetBackdropColor(0.022, 0.021, 0.019, 0.98)
    summary:SetBackdropBorderColor(0.30, 0.25, 0.16, 1)
    TextR5(summary, "GameFontNormal", "CONTRIBUTORS", 12, -12, 220, "LEFT")
    dialog.summaryRowsR5 = {}
    local index
    for index = 1, MAX_LEDGER_SUMMARY_ROWS_R5 do
        local row = CreateFrame("Frame", nil, summary)
        row:SetPoint("TOPLEFT", summary, "TOPLEFT", 10, -42 - ((index - 1) * 43))
        row:SetWidth(210) row:SetHeight(37)
        BackdropR5(row, 6)
        row:SetBackdropColor(0.028, 0.027, 0.024, index / 2 == math.floor(index / 2) and 0.96 or 0.76)
        row:SetBackdropBorderColor(0.22, 0.20, 0.16, 1)
        row.nameR5 = TextR5(row, "GameFontNormalSmall", "", 8, -6, 118, "LEFT")
        row.amountR5 = TextR5(row, "GameFontNormalSmall", "", 128, -6, 72, "RIGHT")
        row.countR5 = TextR5(row, "GameFontNormalSmall", "", 8, -21, 192, "LEFT")
        row.countR5:SetTextColor(0.56, 0.56, 0.53)
        dialog.summaryRowsR5[index] = row
    end
    if OTLGM.UI and OTLGM.UI.Scrollbar then
        dialog.summaryScrollR6 = OTLGM.UI:Scrollbar(summary, 300, function(value)
            dialog.summaryOffsetR5 = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
            OTLGM:RefreshTreasuryGoalLedgerR5()
        end)
        dialog.summaryScrollR6:SetPoint("TOPRIGHT", summary, "TOPRIGHT", -8, -42)
        summary:EnableMouseWheel(true)
        summary:SetScript("OnMouseWheel", function()
            local maximum = tonumber(dialog.summaryMaximumOffsetR6) or 0
            dialog.summaryOffsetR5 = math.max(0, math.min(maximum, (tonumber(dialog.summaryOffsetR5) or 0) - ((tonumber(arg1) or 0) * 2)))
            OTLGM:RefreshTreasuryGoalLedgerR5()
        end)
    end
    dialog.summaryPrevR5 = ButtonR5(summary, "<", 10, -348, 42, 24, function()
        dialog.summaryOffsetR5 = math.max(0, (dialog.summaryOffsetR5 or 0) - MAX_LEDGER_SUMMARY_ROWS_R5)
        OTLGM:RefreshTreasuryGoalLedgerR5()
    end, "utility")
    dialog.summaryNextR5 = ButtonR5(summary, ">", 58, -348, 42, 24, function()
        dialog.summaryOffsetR5 = (dialog.summaryOffsetR5 or 0) + MAX_LEDGER_SUMMARY_ROWS_R5
        OTLGM:RefreshTreasuryGoalLedgerR5()
    end, "utility")
    dialog.summaryStatusR5 = TextR5(summary, "GameFontNormalSmall", "", 110, -354, 126, "LEFT")

    local history = CreateFrame("Frame", nil, dialog)
    history:SetPoint("TOPLEFT", dialog, "TOPLEFT", 278, -104)
    history:SetWidth(464) history:SetHeight(382)
    BackdropR5(history, 10)
    history:SetBackdropColor(0.022, 0.021, 0.019, 0.98)
    history:SetBackdropBorderColor(0.30, 0.25, 0.16, 1)
    TextR5(history, "GameFontNormal", "INDIVIDUAL CONTRIBUTIONS", 12, -12, 330, "LEFT")
    dialog.entryRowsR5 = {}
    for index = 1, MAX_LEDGER_ENTRY_ROWS_R5 do
        local row = CreateFrame("Frame", nil, history)
        row:SetPoint("TOPLEFT", history, "TOPLEFT", 10, -42 - ((index - 1) * 34))
        row:SetWidth(424) row:SetHeight(29)
        BackdropR5(row, 6)
        row:SetBackdropColor(0.028, 0.027, 0.024, index / 2 == math.floor(index / 2) and 0.96 or 0.76)
        row:SetBackdropBorderColor(0.22, 0.20, 0.16, 1)
        row.textR5 = TextR5(row, "GameFontNormalSmall", "", 8, -7, 408, "LEFT")
        dialog.entryRowsR5[index] = row
    end
    if OTLGM.UI and OTLGM.UI.Scrollbar then
        dialog.entryScrollR6 = OTLGM.UI:Scrollbar(history, 300, function(value)
            dialog.offsetR5 = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
            OTLGM:RefreshTreasuryGoalLedgerR5()
        end)
        dialog.entryScrollR6:SetPoint("TOPRIGHT", history, "TOPRIGHT", -8, -42)
        history:EnableMouseWheel(true)
        history:SetScript("OnMouseWheel", function()
            local maximum = tonumber(dialog.entryMaximumOffsetR6) or 0
            dialog.offsetR5 = math.max(0, math.min(maximum, (tonumber(dialog.offsetR5) or 0) - ((tonumber(arg1) or 0) * 3)))
            OTLGM:RefreshTreasuryGoalLedgerR5()
        end)
    end
    dialog.prevR5 = ButtonR5(history, "<", 10, -348, 42, 24, function() dialog.offsetR5 = math.max(0, (dialog.offsetR5 or 0) - MAX_LEDGER_ENTRY_ROWS_R5) OTLGM:RefreshTreasuryGoalLedgerR5() end, "utility")
    dialog.nextR5 = ButtonR5(history, ">", 58, -348, 42, 24, function() dialog.offsetR5 = (dialog.offsetR5 or 0) + MAX_LEDGER_ENTRY_ROWS_R5 OTLGM:RefreshTreasuryGoalLedgerR5() end, "utility")
    dialog.statusR5 = TextR5(history, "GameFontNormalSmall", "", 110, -354, 280, "LEFT")
    dialog.recordR5 = ButtonR5(dialog, "Record Contribution", 560, -498, 182, 28, function()
        if OTLGM.ui and OTLGM.ui.treasury170 then OTLGM.ui.treasury170.selected = dialog.goalIdR5 end
        OTLGM:CloseExclusiveModalR5(dialog)
        OTLGM:OpenTreasuryContributionDialog176()
    end, "confirm")
end

function OTLGM.__impl180.RefreshTreasuryGoalLedgerR5__impl1(self)
    self:BuildTreasuryGoalLedgerR5()
    local dialog = self.ui and self.ui.treasuryLedgerDialogR5
    if not dialog then return end
    local goalId = dialog.goalIdR5
    local ledger = self:GetTreasuryGoalLedgerR5(goalId)
    local goal = ledger.goal
    if not goal then
        dialog.titleR5:SetText("Goal Ledger")
        dialog.totalR5:SetText("The selected goal no longer exists.")
        dialog.metaR5:SetText("")
    else
        dialog.titleR5:SetText(tostring(goal.name or "Goal Ledger"))
        dialog.totalR5:SetText(MoneyR5(goal.current, true) .. " raised / " .. MoneyR5(goal.target, true) .. " target")
        local remaining = math.max(0, (tonumber(goal.target) or 0) - (tonumber(goal.current) or 0))
        dialog.metaR5:SetText(tostring(table.getn(ledger.contributors)) .. " contributor" .. (table.getn(ledger.contributors) == 1 and "" or "s") .. "  -  recorded entries " .. MoneyR5(ledger.recorded, true) .. "  -  remaining " .. MoneyR5(remaining, true))
    end
    local index, row, contributor, entry, note
    local summaryMaximum = math.max(0, table.getn(ledger.contributors) - MAX_LEDGER_SUMMARY_ROWS_R5)
    dialog.summaryOffsetR5 = math.max(0, math.min(summaryMaximum, tonumber(dialog.summaryOffsetR5) or 0))
    for index = 1, MAX_LEDGER_SUMMARY_ROWS_R5 do
        row = dialog.summaryRowsR5[index]
        contributor = ledger.contributors[dialog.summaryOffsetR5 + index]
        if contributor then
            row.nameR5:SetText(contributor.name)
            row.amountR5:SetText(MoneyR5(contributor.amount))
            row.countR5:SetText(tostring(contributor.count) .. " contribution" .. (contributor.count == 1 and "" or "s"))
            row:Show()
        else row:Hide() end
    end
    dialog.summaryMaximumOffsetR6 = summaryMaximum
    if dialog.summaryScrollR6 and dialog.summaryScrollR6.SetScrollMetrics180 then
        dialog.summaryScrollR6:SetScrollMetrics180(table.getn(ledger.contributors), MAX_LEDGER_SUMMARY_ROWS_R5, dialog.summaryOffsetR5)
    end
    if dialog.summaryPrevR5 then dialog.summaryPrevR5:Hide() end
    if dialog.summaryNextR5 then dialog.summaryNextR5:Hide() end
    if table.getn(ledger.contributors) == 0 then dialog.summaryStatusR5:SetText("No contributors")
    else dialog.summaryStatusR5:SetText(tostring(dialog.summaryOffsetR5 + 1) .. "-" .. tostring(math.min(dialog.summaryOffsetR5 + MAX_LEDGER_SUMMARY_ROWS_R5, table.getn(ledger.contributors))) .. "/" .. tostring(table.getn(ledger.contributors))) end
    local maximum = math.max(0, table.getn(ledger.entries) - MAX_LEDGER_ENTRY_ROWS_R5)
    dialog.offsetR5 = math.max(0, math.min(maximum, tonumber(dialog.offsetR5) or 0))
    for index = 1, MAX_LEDGER_ENTRY_ROWS_R5 do
        row = dialog.entryRowsR5[index]
        entry = ledger.entries[dialog.offsetR5 + index]
        if entry then
            note = entry.note and entry.note ~= "" and (" - " .. entry.note) or ""
            row.textR5:SetText(date("%d %b %H:%M", entry.ts or self:Now()) .. "  " .. tostring(entry.contributor or "Anonymous") .. "  +" .. MoneyR5(entry.amount) .. "  by " .. tostring(entry.actor or "Leadership") .. note)
            row:Show()
        else row:Hide() end
    end
    dialog.entryMaximumOffsetR6 = maximum
    if dialog.entryScrollR6 and dialog.entryScrollR6.SetScrollMetrics180 then
        dialog.entryScrollR6:SetScrollMetrics180(table.getn(ledger.entries), MAX_LEDGER_ENTRY_ROWS_R5, dialog.offsetR5)
    end
    if dialog.prevR5 then dialog.prevR5:Hide() end
    if dialog.nextR5 then dialog.nextR5:Hide() end
    if table.getn(ledger.entries) == 0 then dialog.statusR5:SetText("No contributions recorded for this goal.")
    else dialog.statusR5:SetText(tostring(dialog.offsetR5 + 1) .. "-" .. tostring(math.min(dialog.offsetR5 + MAX_LEDGER_ENTRY_ROWS_R5, table.getn(ledger.entries))) .. " / " .. tostring(table.getn(ledger.entries))) end
    local canEdit = self.CanEditTreasury170 and self:CanEditTreasury170()
    SetEnabledR5(dialog.recordR5, canEdit and goal ~= nil, "Only guild leadership can record contributions.")
end

function OTLGM.__impl180.OpenTreasuryGoalLedgerR5__impl1(self, goalId)
    goalId = goalId or (self.ui and self.ui.treasury170 and self.ui.treasury170.selected)
    if not goalId or not self:GetTreasuryGoal170(goalId) then
        if self.ShowNotice then self:ShowNotice("Treasury Ledger", "Select a funding goal first.") end
        return false
    end
    self:BuildTreasuryGoalLedgerR5()
    local dialog = self.ui.treasuryLedgerDialogR5
    dialog.goalIdR5 = goalId
    dialog.offsetR5 = 0
    dialog.summaryOffsetR5 = 0
    self:RefreshTreasuryGoalLedgerR5()
    self:OpenExclusiveModalR5(dialog)
    R5.treasuryLedgersOpened = R5.treasuryLedgersOpened + 1
    return true
end

local PreviousBuildTreasuryPageR5 = OTLGM.__impl180.BuildTreasuryPage170__impl3
if PreviousBuildTreasuryPageR5 then
    function OTLGM.__impl180.BuildTreasuryPage170__impl4(self, page)
        local result = PreviousBuildTreasuryPageR5(self, page)
        local ui = self.ui and self.ui.treasury170
        if ui and ui.page and not ui.activityButtonR5 then
            ui.activityButtonR5 = ButtonR5(ui.page, "Activity", 340, -2, 96, 26, function() OTLGM:OpenTreasuryActivityR5() end, "utility")
            ui.ledgerButtonR5 = ButtonR5(ui.page, "View Ledger", 442, -2, 100, 26, function() OTLGM:OpenTreasuryGoalLedgerR5() end, "utility")
            if ui.contributionButton176 then
                ui.contributionButton176:ClearAllPoints()
                ui.contributionButton176:SetPoint("TOPLEFT", ui.page, "TOPLEFT", 548, -2)
                ui.contributionButton176:SetWidth(170)
            end
        end
        return result
    end
end

local PreviousRefreshTreasuryButtonsR5 = OTLGM.__impl180.RefreshTreasuryPage170__impl4
function OTLGM.__impl180.RefreshTreasuryPage170__impl5(self, forceEditor)
    if not CanRefreshPageR5(self, "treasury") then return false end
    local result = PreviousRefreshTreasuryButtonsR5(self, forceEditor)
    local ui = self.ui and self.ui.treasury170
    if ui and ui.ledgerButtonR5 then
        SetEnabledR5(ui.ledgerButtonR5, ui.selected and self:GetTreasuryGoal170(ui.selected) ~= nil, "Select a funding goal first.")
        SetEnabledR5(ui.activityButtonR5, true)
    end
    return result
end

-- ---------------------------------------------------------------------------
-- Screenshot fixes: compact lower edge tab, recruitment card, chat actions,
-- clean activity text and non-overlapping Treasury/recruitment dialogs.
-- ---------------------------------------------------------------------------

function OTLGM:ApplyWindowTabLayoutR5()
    local tab = self.ui and self.ui.windowParkTab176
    local frame = self.ui and self.ui.main
    if self.disableLegacyWindowPark176 or self.shellVersion then
        if tab then tab:Hide() end
        return
    end
    if not tab or not frame then return end
    tab:SetWidth(PARK_TAB_WIDTH_R5)
    tab:SetHeight(PARK_TAB_HEIGHT_R5)
    if tab.text then
        tab.text:SetFontObject("GameFontNormalSmall")
        tab.text:SetText("OTL")
        tab.text:SetWidth(PARK_TAB_WIDTH_R5 - 4)
    end
    tab:ClearAllPoints()
    local side = OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.windowParkSide176 or "RIGHT"
    local parked = OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.windowParked176
    if parked and side == "LEFT" then tab:SetPoint("RIGHT", frame, "RIGHT", 0, PARK_TAB_Y_R5)
    else tab:SetPoint("LEFT", frame, "LEFT", 0, PARK_TAB_Y_R5) end
end

local PreviousBuildUIR5 = OTLGM.__impl180.BuildUI__impl2
if PreviousBuildUIR5 then
    function OTLGM.__impl180.BuildUI__impl3(self)
        local result = PreviousBuildUIR5(self)
        self:ApplyWindowTabLayoutR5()
        if self.ui and self.ui.recentWhisperDialog176 then self:AttachExclusiveModalR5(self.ui.recentWhisperDialog176) end
        if self.ui and self.ui.treasuryContributionDialog176 then self:AttachExclusiveModalR5(self.ui.treasuryContributionDialog176) end
        return result
    end
end

local PreviousParkR5 = OTLGM.__impl180.ParkWindow176__impl1
if PreviousParkR5 then
end

local PreviousUnparkR5 = OTLGM.__impl180.UnparkWindow176__impl1
if PreviousUnparkR5 then
end

function OTLGM:ApplyRecruitmentCardLayoutR5()
    local card = self.ui and self.ui.worldRecruitmentCard
    if not card or card.layoutR5 then return end
    card.layoutR5 = true
    if card.label then card.label:SetWidth(178) end
    if card.value then card.value:SetWidth(98) end
    if card.detail then
        card.detail:ClearAllPoints()
        card.detail:SetPoint("TOPLEFT", card, "TOPLEFT", 112, -25)
        card.detail:SetWidth(120)
    end
    if card.meta then
        card.meta:ClearAllPoints()
        card.meta:SetPoint("TOPLEFT", card, "TOPLEFT", 112, -44)
        card.meta:SetWidth(134)
    end
    if card.autoText then
        card.autoText:ClearAllPoints()
        card.autoText:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -42)
        card.autoText:SetWidth(62)
        card.autoText:SetJustifyH("RIGHT")
    end
    if self.ui.channelEdit then
        self.ui.channelEdit:ClearAllPoints()
        self.ui.channelEdit:SetPoint("TOPRIGHT", card, "TOPRIGHT", -6, -5)
        self.ui.channelEdit:SetWidth(34)
    end
end

local PreviousBuildRecruitmentR5 = OTLGM.__impl180.BuildRecruitmentPage__impl3
if PreviousBuildRecruitmentR5 then
    function OTLGM:BuildRecruitmentPage(page)
        local result = PreviousBuildRecruitmentR5(self, page)
        self:ApplyRecruitmentCardLayoutR5()
        if self.ui and self.ui.recentWhisperButton176 and page then
            self.ui.recentWhisperButton176:ClearAllPoints()
            self.ui.recentWhisperButton176:SetPoint("TOPLEFT", page, "TOPLEFT", 270, -54)
            self.ui.recentWhisperButton176:SetWidth(130)
            SetTextR5(self.ui.recentWhisperButton176, "Recent Whispers")
        end
        return result
    end
end

local PreviousRefreshRecruitmentLayoutR5 = OTLGM.__impl180.RefreshRecruitmentPage__impl2
if PreviousRefreshRecruitmentLayoutR5 then
    function OTLGM:RefreshRecruitmentPage()
        if not CanRefreshPageR5(self, "recruitment") then return false end
        local result = PreviousRefreshRecruitmentLayoutR5(self)
        self:ApplyRecruitmentCardLayoutR5()
        return result
    end
end

function OTLGM:ApplyGuildChatPolishR5()
    if not self.ui or not self.ui.chatRows then return end
    local index, row
    for index = 1, table.getn(self.ui.chatRows) do
        row = self.ui.chatRows[index]
        if row.pinButton170 then
            row.pinButton170:SetWidth(16)
            row.pinButton170:SetHeight(16)
            row.pinButton170:SetAlpha(row.pinButton170.pinned170 and 0.95 or 0.42)
            row.pinButton170:ClearAllPoints()
            row.pinButton170:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -4)
            if row.pinButton170.text then row.pinButton170.text:SetFontObject("GameFontNormalSmall") end
        end
        if row.messageFrame and row.chatData then
            local achievement = string.find(tostring(row.chatData.text or ""), "^%[Guild Achievement%]") ~= nil
            local measuredWidth
            if achievement then
                measuredWidth = tonumber(self.ui.chatAchievementWidth180) or 590
            else
                measuredWidth = tonumber(self.ui.chatMessageWidth180) or 426
            end
            row.messageFrame:SetWidth(math.max(180, measuredWidth))
        end
    end
end

local PreviousRefreshGuildChatPolishR5 = OTLGM.__impl180.RefreshGuildChatPage__impl3
if PreviousRefreshGuildChatPolishR5 then
    function OTLGM:RefreshGuildChatPage()
        if not CanRefreshPageR5(self, "guildchat") then return false end
        local result = PreviousRefreshGuildChatPolishR5(self)
        self:ApplyGuildChatPolishR5()
        return result
    end
end

local PreviousRefreshHistoryRowsR5 = OTLGM.__impl180.RefreshHistoryRowsOnly__impl2
if PreviousRefreshHistoryRowsR5 then
    function OTLGM:RefreshHistoryRowsOnly()
        local result = PreviousRefreshHistoryRowsR5(self)
        local index, row, item, detail
        for index = 1, table.getn(self.ui and self.ui.historyRows or {}) do
            row = self.ui.historyRows[index]
            item = row and row.eventInfo
            if item and not item.header and item.kind == "LEAVE" then
                detail = tostring(item.detail or "")
                if string.find(string.lower(detail), "actor unavailable", 1, true) then
                    item.detail = "Left or was removed"
                    if row.detail then row.detail:SetText("Left or was removed") end
                    if row.actor then row.actor:SetText("") end
                end
            end
        end
        return result
    end
end

local PreviousRefreshOverviewCleanupR5 = OTLGM.__impl180.RefreshOverviewPage__impl3
if PreviousRefreshOverviewCleanupR5 then
    function OTLGM:RefreshOverviewPage()
        if not CanRefreshPageR5(self, "overview") then return false end
        local result = PreviousRefreshOverviewCleanupR5(self)
        local index, line, text
        for index = 1, table.getn(self.ui and self.ui.overviewEvents or {}) do
            line = self.ui.overviewEvents[index]
            text = line and line.GetText and line:GetText() or ""
            if text ~= "" and string.find(string.lower(text), "actor unavailable", 1, true) then
                text = string.gsub(text, "[Aa]ctor unavailable", "")
                text = string.gsub(text, ";%s*$", "")
                text = string.gsub(text, "%s+$", "")
                line:SetText(text)
            end
        end
        return result
    end
end

function OTLGM:ApplyR5UIFixes()
    if not self.ui or not self.ui.main then return end
    if self.disableLegacyWindowPark176 or self.shellVersion then
        if self.ui.windowParkTab176 then self.ui.windowParkTab176:Hide() end
    else
        self:ApplyWindowTabLayoutR5()
    end
    self:ApplyRecruitmentCardLayoutR5()
    if self.ui.currentPage == "guildchat" then self:ApplyGuildChatPolishR5() end
    R5.uiFixPasses = R5.uiFixPasses + 1
end

-- Do not add visual maintenance to the shared heartbeat. Every R5 layout fix
-- is applied during build, page refresh, park or unpark instead of once per second.
local PreviousQualityTimersR5 = OTLGM.__impl180.ProcessQuality156Timers__impl7
function OTLGM:ProcessQuality156Timers()
    if not PreviousQualityTimersR5 then return false end
    self.runtime = self.runtime or {}
    local serialBefore = tonumber(self.runtime.qualityFaultSerialR6) or 0
    local ok, result = pcall(PreviousQualityTimersR5, self)
    if not ok then
        local failures = math.min(5, (tonumber(self.runtime.qualityFailuresR6) or 0) + 1)
        self.runtime.qualityFailuresR6 = failures
        self.runtime.qualityFaultSerialR6 = serialBefore + 1
        local preciseNow = self.GetPreciseTime180 and self:GetPreciseTime180() or self:Now()
        self.runtime.qualityBackoffUntilR6 = preciseNow + math.min(16, 0.5 * (2 ^ math.max(0, failures - 1)))
        if self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Quality/FINAL_DISPATCH", result) end
        return false
    end
    if (tonumber(self.runtime.qualityFaultSerialR6) or 0) == serialBefore then
        self.runtime.qualityFailuresR6 = 0
        self.runtime.qualityBackoffUntilR6 = nil
    end
    return result
end

-- Diagnostics preserve /otlperf while exposing final runtime coordination counters.
local PreviousPerfSlashR5 = SlashCmdList and SlashCmdList["OTLGMPERF"]
if SlashCmdList then
    SlashCmdList["OTLGMPERF"] = function(message)
        message = string.lower(TrimR5(message or ""))
        if message == "reset" then
            local key, value
            for key, value in pairs(R5) do if type(value) == "number" then R5[key] = 0 end end
            if PreviousPerfSlashR5 then PreviousPerfSlashR5(message) end
            return
        end
        if PreviousPerfSlashR5 then PreviousPerfSlashR5(message) end
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffcc33[Lion GM Runtime]|r hidden refresh skips " .. tostring(R5.hiddenRefreshesSkipped) .. "; RefreshAll collapsed " .. tostring(R5.refreshAllCollapsed) .. "; mailbox scans delegated " .. tostring(R5.mailboxScansSuppressed))
            DEFAULT_CHAT_FRAME:AddMessage("Bag slices deferred " .. tostring(R5.bagSlicesDeferred) .. "; network packet budget reductions " .. tostring(R5.networkPacketsLimited) .. "; modal opens/replacements " .. tostring(R5.modalOpens) .. "/" .. tostring(R5.modalReplacements))
            DEFAULT_CHAT_FRAME:AddMessage("Treasury activities/ledgers " .. tostring(R5.treasuryActivities) .. "/" .. tostring(R5.treasuryLedgersOpened) .. "; whisper invites sent/rejected " .. tostring(R5.whisperInvitesSent) .. "/" .. tostring(R5.whisperInviteRejected))
        end
    end
end

if OTLGM.RegisterModule then
    OTLGM:RegisterModule("RuntimeCoordination", {
        layer = "stability", revision = 6, version = "1.8.0", noOnUpdate = true,
        treasuryLedger = true, treasuryActivity = true, whisperInvite = true,
    })
end
