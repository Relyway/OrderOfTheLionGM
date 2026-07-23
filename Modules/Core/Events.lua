-- Order of the Lion Guild Manager
-- Safe events, diagnostics and controlled roster refresh.

SLASH_OTLGM1 = "/otl"
SLASH_OTLGM2 = "/liongm"
SLASH_OTLGMTEST1 = "/otltest"

local function PrintLine(message, errorLine)
    if not DEFAULT_CHAT_FRAME then return end
    local color = errorLine and "|cffff3333" or "|cffffcc33"
    DEFAULT_CHAT_FRAME:AddMessage(color .. "[Lion GM]|r " .. tostring(message or ""))
end

local function ToggleSafely()
    if not OTLGM or not OTLGM.ToggleUI then
        PrintLine("The UI module did not load. Type /otltest for the module report.", true)
        return
    end
    local ok, err = pcall(function() OTLGM:ToggleUI() end)
    if not ok then PrintLine("UI runtime error: " .. tostring(err), true) end
end

SlashCmdList["OTLGM"] = function(message)
    message = string.lower(message or "")
    if message == "scan" then
        if OTLGM and OTLGM.RequestScan then OTLGM:RequestScan("MANUAL") end
    elseif message == "reset" then
        if IsShiftKeyDown() and OTLGM and OTLGM.ResetGuildData then
            OTLGM:ResetGuildData()
        else
            PrintLine("Hold Shift while entering /otl reset, or use Settings.")
        end
    elseif message == "minimap" then
        if OTLGM and OTLGM.EnsureDB then
            OTLGM:EnsureDB()
            OTLGM_DB.settings.showMinimap = not OTLGM_DB.settings.showMinimap
            if OTLGM.ApplyMinimapVisibility then OTLGM:ApplyMinimapVisibility() end
        end
    elseif message == "wizard" then
        if OTLGM and OTLGM.OpenFirstRunWizard then OTLGM:OpenFirstRunWizard() else ToggleSafely() end
    elseif message == "backup" then
        if OTLGM and OTLGM.ShowCopyDialog and OTLGM.ExportBackup then
            OTLGM:ShowCopyDialog("Order of the Lion Addon Backup", OTLGM:ExportBackup())
        else
            ToggleSafely()
        end
    elseif message == "help" then
        PrintLine("/otl - open | /otl scan - manual update | /otl minimap | /otltest - diagnostics")
    else
        ToggleSafely()
    end
end

SlashCmdList["OTLGMTEST"] = function()
    local loaded, reason = IsAddOnLoaded("OrderOfTheLionGM"), ""
    if GetAddOnInfo then
        local name, title, notes, enabled, loadable, loadReason = GetAddOnInfo("OrderOfTheLionGM")
        reason = tostring(loadReason)
    end
    if not OTLGM then PrintLine("Diagnostic: bootstrap is missing; TOC=" .. tostring(loaded) .. ", reason=" .. tostring(reason), true) return end
    local moduleCount = OTLGM.Count and OTLGM:Count(OTLGM.modules) or 0
    local registryReady = OTLGM.GetModule and OTLGM:GetModule("Transport") and OTLGM:GetModule("Security") and true or false
    local db = OTLGM.GetGuildDB and OTLGM:GetGuildDB() or nil
    local craft = OTLGM.EnsureCraftingDB and OTLGM:EnsureCraftingDB() or nil
    local queueTotal, queueCritical, queueNormal, queueBulk = 0, 0, 0, 0
    if OTLGM.GetNetworkQueueDepth then queueTotal, queueCritical, queueNormal, queueBulk = OTLGM:GetNetworkQueueDepth() end
    local metrics = OTLGM.runtime and OTLGM.runtime.metrics and OTLGM.runtime.metrics.network or {}
    local transport = OTLGM.runtime and OTLGM.runtime.transport or {}
    local backoff = math.max(0, (tonumber(transport.nextAttemptAt) or 0) - OTLGM:Now())
    local tooltipCompatibility = GameTooltip and GameTooltip.otlTooltipCompatibility160 or {}
    PrintLine("Runtime v" .. tostring(OTLGM.version) .. " / schema " .. tostring(OTLGM.schemaVersion) .. " / protocol " .. tostring(OTLGM.protocolVersion) .. "; TOC=" .. tostring(loaded) .. ", reason=" .. tostring(reason))
    PrintLine("Modules=" .. tostring(moduleCount) .. "/26; registry=" .. tostring(registryReady and "ready" or "incomplete") .. "; database=" .. tostring(db and "ready" or "unavailable") .. "; migration=" .. tostring(db and db.migration and db.migration.foundation170 and "1.7" or "pending"))
    PrintLine("UI=" .. tostring(OTLGM.ui and OTLGM.ui.v15Built and "built" or "not built") .. "; minimap=" .. tostring(OTLGM.ui and OTLGM.ui.minimapButton and "built" or "not built") .. "; effective scale=" .. tostring(OTLGM.runtime and OTLGM.runtime.effectiveUIScale or "default"))
    PrintLine("Network queue total/critical/normal/bulk=" .. tostring(queueTotal) .. "/" .. tostring(queueCritical) .. "/" .. tostring(queueNormal) .. "/" .. tostring(queueBulk))
    PrintLine("Network sent/retried/dropped/rejected=" .. tostring(metrics.sent or 0) .. "/" .. tostring(metrics.retried or 0) .. "/" .. tostring(metrics.dropped or 0) .. "/" .. tostring(metrics.rejected or 0) .. "; sender validation=" .. tostring(OTLGM.IsKnownGuildSender and "enabled" or "missing"))
    PrintLine("Targeted routed/received/skipped (non-recipient packets are normal)=" .. tostring(metrics.targetedRouted or 0) .. "/" .. tostring(metrics.targetedReceived or 0) .. "/" .. tostring(metrics.targetedSkipped or metrics.targetedIgnored or 0) .. "; safely shortened=" .. tostring(metrics.targetedTrimmed or 0) .. "; backoff=" .. tostring(backoff) .. "s; TurtleRP tooltip guard=" .. tostring(tooltipCompatibility.wrapper and "active" or "not needed"))
    PrintLine("Crafting characters/details=" .. tostring(OTLGM.Count and OTLGM:Count(craft and craft.characters) or 0) .. "/" .. tostring(OTLGM.Count and OTLGM:Count(craft and craft.details) or 0) .. "; manifest=" .. tostring(OTLGM.HandleCraftingManifest157 and "ready" or "missing") .. "; result tooltips=" .. tostring(OTLGM.ShowCraftingResultTooltip and "ready" or "missing"))
    if metrics.lastError then PrintLine("Last network error (" .. tostring(metrics.lastErrorChannel or "?") .. "/" .. tostring(metrics.lastErrorSource or "?") .. "): " .. tostring(metrics.lastError), true) end
    if metrics.lastRejectReason then PrintLine("Last rejected packet: " .. tostring(metrics.lastRejectReason) .. " from " .. tostring(metrics.lastRejectSender or "unknown")) end
end

local eventFrame = CreateFrame("Frame", "OTLGM_EventFrame")
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CHANNEL_NOTICE")
eventFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("CHAT_MSG_GUILD")
eventFrame:RegisterEvent("CHAT_MSG_OFFICER")
eventFrame:RegisterEvent("TRADE_SKILL_SHOW")
eventFrame:RegisterEvent("CRAFT_SHOW")
eventFrame:RegisterEvent("TRADE_SKILL_UPDATE")
eventFrame:RegisterEvent("CRAFT_UPDATE")

eventFrame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        if OTLGM and OTLGM.EnsureDB then OTLGM:EnsureDB() end
        if OTLGM and OTLGM.ResetSessionData then OTLGM:ResetSessionData() end
    elseif event == "PLAYER_LOGIN" then
        if not OTLGM then
            PrintLine("The addon bootstrap did not load.", true)
            return
        end
        if OTLGM.EnsureDB then OTLGM:EnsureDB() end
        if OTLGM.InstallTooltipCompatibility160 then OTLGM:InstallTooltipCompatibility160() end
        if OTLGM.InstallInviteHook then OTLGM:InstallInviteHook() end
        if OTLGM.InstallGuildActionHooks then OTLGM:InstallGuildActionHooks() end
        if OTLGM.BuildMinimapButton then
            local ok, err = pcall(function() OTLGM:BuildMinimapButton() end)
            if not ok then PrintLine("Minimap runtime error: " .. tostring(err), true) end
        end
        if OTLGM.BroadcastVersion then OTLGM:BroadcastVersion() end
        if OTLGM.InitializePveSync then OTLGM:InitializePveSync() end
        if OTLGM.EnsureCraftingDB then OTLGM:EnsureCraftingDB() end
        if OTLGM.RequestCraftingSync then OTLGM.craftingInitialSyncAt = OTLGM:Now() + 10 end
        if OTLGM.RequestAnnouncementSync152 then OTLGM.announcementInitialSyncAt = OTLGM:Now() + 7 end
        if OTLGM.DetectWorldChannel153 then OTLGM:DetectWorldChannel153(true) end
        if OTLGM.RequestSharedActivitySync156 then OTLGM.sharedActivityInitialSync156 = OTLGM:Now() + 12 end
        if OTLGM.RefreshSenderRosterCache then OTLGM:RefreshSenderRosterCache(true) end
        if OTLGM.RequestScan and GetGuildInfo("player") then OTLGM:RequestScan("LOGIN") end
        if not OTLGM.systems152Loaded then PrintLine("The community module did not load; shared-data features are unavailable.", true) end
        if not OTLGM.fullUILoaded or not OTLGM.ToggleUI then
            PrintLine("Full UI did not load. Type /otltest for details.", true)
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "CHANNEL_NOTICE" then
        if event == "PLAYER_ENTERING_WORLD" and OTLGM and OTLGM.InstallTooltipCompatibility160 then
            OTLGM:InstallTooltipCompatibility160()
        end
        if OTLGM and OTLGM.DetectWorldChannel153 then OTLGM:DetectWorldChannel153(true) end
        if event == "PLAYER_ENTERING_WORLD" and OTLGM and OTLGM.ApplyUIScale and OTLGM.ui and OTLGM.ui.main then
            OTLGM:ApplyUIScale(OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.uiScale or 1)
        end
        if OTLGM and OTLGM.ui and OTLGM.ui.currentPage == "recruitment" and OTLGM.RefreshRecruitmentPage then OTLGM:RefreshRecruitmentPage() end
    elseif event == "CHAT_MSG_SYSTEM" then
        if OTLGM and OTLGM.TryCaptureSystemGuildAction then OTLGM:TryCaptureSystemGuildAction(arg1) end
    elseif event == "CHAT_MSG_ADDON" then
        if OTLGM and OTLGM.HandleAddonMessage then OTLGM:HandleAddonMessage(arg1, arg2, arg3, arg4) end
    elseif event == "CHAT_MSG_GUILD" then
        if OTLGM and OTLGM.CaptureGuildChatMessage then OTLGM:CaptureGuildChatMessage("GUILD", arg1, arg2) end
    elseif event == "CHAT_MSG_OFFICER" then
        if OTLGM and OTLGM.CaptureGuildChatMessage then OTLGM:CaptureGuildChatMessage("OFFICER", arg1, arg2) end
    elseif event == "TRADE_SKILL_SHOW" then
        if OTLGM and OTLGM.ScanCurrentProfession then OTLGM:ScanCurrentProfession("TRADE", 0) end
    elseif event == "CRAFT_SHOW" then
        if OTLGM and OTLGM.ScanCurrentProfession then OTLGM:ScanCurrentProfession("CRAFT", 0) end
    elseif event == "TRADE_SKILL_UPDATE" then
        if OTLGM and OTLGM.ScheduleProfessionRescan then OTLGM:ScheduleProfessionRescan("TRADE", 2, 0.6) end
    elseif event == "CRAFT_UPDATE" then
        if OTLGM and OTLGM.ScheduleProfessionRescan then OTLGM:ScheduleProfessionRescan("CRAFT", 2, 0.6) end
    elseif event == "PLAYER_GUILD_UPDATE" then
        if OTLGM and OTLGM.runtime then OTLGM.runtime.guildPermissionFlags170 = nil end
        if OTLGM and OTLGM.RefreshSenderRosterCache then OTLGM:RefreshSenderRosterCache(true) end
        if OTLGM and OTLGM.BroadcastVersion then OTLGM:BroadcastVersion() end
        if OTLGM and OTLGM.RequestPveSync then OTLGM:RequestPveSync(true) end
        if OTLGM and OTLGM.RequestCraftingSync then OTLGM:RequestCraftingSync(true) end
        if OTLGM and OTLGM.RequestAnnouncementSync152 then OTLGM:RequestAnnouncementSync152(true) end
        if OTLGM and OTLGM.RefreshNavigation then OTLGM:RefreshNavigation() end
    elseif event == "GUILD_ROSTER_UPDATE" then
        if OTLGM and OTLGM.runtime then OTLGM.runtime.guildPermissionFlags170 = nil end
        if OTLGM and OTLGM.RefreshSenderRosterCache then OTLGM:RefreshSenderRosterCache(true) end
        if OTLGM and OTLGM.pendingScan then
            local reason = OTLGM.pendingScanReason or "INTERNAL"
            OTLGM.pendingScan = false
            OTLGM.pendingScanReason = nil
            OTLGM:Scan(reason)
        end
    end
end)

eventFrame:SetScript("OnUpdate", function()
    if OTLGM and OTLGM.ProcessUIDebounce then OTLGM:ProcessUIDebounce(arg1 or 0) end
    OTLGM.heartbeatElapsed = (OTLGM.heartbeatElapsed or 0) + (arg1 or 0)
    if OTLGM.heartbeatElapsed < 1 then return end

    local elapsed = OTLGM.heartbeatElapsed
    OTLGM.heartbeatElapsed = 0
    OTLGM.elapsed = (OTLGM.elapsed or 0) + elapsed
    OTLGM.versionElapsed = (OTLGM.versionElapsed or 0) + elapsed

    if OTLGM.confirmScanAt and OTLGM:Now() >= OTLGM.confirmScanAt and not OTLGM.pendingScan then
        OTLGM.confirmScanAt = nil
        OTLGM:RequestScan("CONFIRM")
    end

    if OTLGM.versionElapsed >= 900 then
        OTLGM.versionElapsed = 0
        if OTLGM.BroadcastVersion then OTLGM:BroadcastVersion() end
    end

    if OTLGM.ProcessStatus170 then OTLGM:ProcessStatus170() end
    if OTLGM.ProcessNetworkQueue then OTLGM:ProcessNetworkQueue() end
    if OTLGM.ProcessCraftingTimers then OTLGM:ProcessCraftingTimers() end
    if OTLGM.ProcessAnnouncementTimers155 then OTLGM:ProcessAnnouncementTimers155() end
    if OTLGM.ProcessTreasuryTimers170 then OTLGM:ProcessTreasuryTimers170() end
    if OTLGM.ProcessPveApplicationRetries155 then OTLGM:ProcessPveApplicationRetries155() end
    if OTLGM.ProcessQuality156Timers then OTLGM:ProcessQuality156Timers() end
    if OTLGM.sharedActivityInitialSync156 and OTLGM:Now() >= OTLGM.sharedActivityInitialSync156 then
        OTLGM.sharedActivityInitialSync156 = nil
        if OTLGM.RequestSharedActivitySync156 then OTLGM:RequestSharedActivitySync156(false) end
    end
    if OTLGM.craftingInitialSyncAt and OTLGM:Now() >= OTLGM.craftingInitialSyncAt then
        OTLGM.craftingInitialSyncAt = nil
        if OTLGM.RequestCraftingSync then OTLGM:RequestCraftingSync(false) end
    end
    if OTLGM.announcementInitialSyncAt and OTLGM:Now() >= OTLGM.announcementInitialSyncAt then
        OTLGM.announcementInitialSyncAt = nil
        if OTLGM.RequestAnnouncementSync152 then OTLGM:RequestAnnouncementSync152(false) end
    end
    if OTLGM.pveSyncAt and OTLGM:Now() >= OTLGM.pveSyncAt then
        OTLGM.pveSyncAt = nil
        if OTLGM.RequestPveSync then OTLGM:RequestPveSync(true) end
    end
    OTLGM.pveMaintenanceElapsed = (OTLGM.pveMaintenanceElapsed or 0) + elapsed
    if OTLGM.pveMaintenanceElapsed >= 60 and not (OTLGM.InCombat and OTLGM:InCombat()) then
        OTLGM.pveMaintenanceElapsed = 0
        if OTLGM.PurgePveData then OTLGM:PurgePveData(false) end
        if OTLGM.CheckPveRaidReminders then OTLGM:CheckPveRaidReminders() end
        if OTLGM.PurgeCraftingData then OTLGM:PurgeCraftingData(false) end
        if OTLGM.RefreshDateIndicator then OTLGM:RefreshDateIndicator() end
        -- Data pages are refreshed by their own change events. Do not rebuild
        -- large lists every 30 seconds while the player is idle.
    end

    OTLGM.liveClockElapsed155 = (OTLGM.liveClockElapsed155 or 0) + elapsed
    if OTLGM.liveClockElapsed155 >= 5 then
        OTLGM.liveClockElapsed155 = 0
        if OTLGM.ui and OTLGM.ui.main and OTLGM.ui.main:IsVisible() then
            if OTLGM.ui.currentPage == "home" and OTLGM.RefreshHomePveSummary155 then OTLGM:RefreshHomePveSummary155() end
            if OTLGM.ui.currentPage == "pve" and OTLGM.RefreshPveRaidTimes155 then OTLGM:RefreshPveRaidTimes155() end
        end
    end

    local visible = OTLGM.ui and OTLGM.ui.main and OTLGM.ui.main:IsVisible()
    if visible and OTLGM.MaybeRefreshVisibleRoster then OTLGM:MaybeRefreshVisibleRoster() end

    if visible and OTLGM.ui.currentPage == "recruitment" then
        OTLGM.worldRecruitmentIndicatorElapsed = (OTLGM.worldRecruitmentIndicatorElapsed or 0) + elapsed
        if OTLGM.worldRecruitmentIndicatorElapsed >= 30 then
            OTLGM.worldRecruitmentIndicatorElapsed = 0
            if OTLGM.RefreshWorldRecruitmentIndicator then OTLGM:RefreshWorldRecruitmentIndicator() end
        end
    else
        OTLGM.worldRecruitmentIndicatorElapsed = 0
    end

    if not OTLGM_DB or not OTLGM_DB.settings or not OTLGM_DB.settings.autoScan then return end
    if not GetGuildInfo("player") then return end
    local interval = OTLGM_DB.settings.scanInterval or 1200
    if interval < 600 then interval = 1200 end
    if OTLGM.elapsed >= interval and not OTLGM.pendingScan and not OTLGM.confirmScanAt then
        OTLGM.elapsed = 0
        OTLGM:RequestScan("AUTO")
    end
end)

OTLGM:RegisterModule("Events", { layer = "core", heartbeatSeconds = 1 })
