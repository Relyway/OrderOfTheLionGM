-- Order of the Lion Guild Manager
-- Safe events, diagnostics and controlled roster refresh - v1.5.4

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
        PrintLine("UI.lua did not load. Type /otltest for the module report.", true)
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
    PrintLine("Diagnostic: TOC=" .. tostring(loaded) .. ", reason=" .. tostring(reason))
    PrintLine("Core=" .. tostring(OTLGM and OTLGM.EnsureDB ~= nil) .. ", Advanced=" .. tostring(OTLGM and OTLGM.GetGuildDB ~= nil))
    PrintLine("UI marker=" .. tostring(OTLGM and OTLGM.fullUILoaded) .. ", BuildUI=" .. tostring(OTLGM and OTLGM.BuildUI ~= nil) .. ", ToggleUI=" .. tostring(OTLGM and OTLGM.ToggleUI ~= nil))
    PrintLine("Minimap=" .. tostring(OTLGM and OTLGM.BuildMinimapButton ~= nil) .. ", RequestScan=" .. tostring(OTLGM and OTLGM.RequestScan ~= nil))
    PrintLine("Guild chat=" .. tostring(OTLGM and OTLGM.CaptureGuildChatMessage ~= nil) .. ", World timer=" .. tostring(OTLGM and OTLGM.GetWorldRecruitmentInfo ~= nil) .. ", PvE sync=" .. tostring(OTLGM and OTLGM.HandlePveAddonMessage ~= nil))
    PrintLine("Crafting=" .. tostring(OTLGM and OTLGM.ScanCurrentProfession ~= nil) .. ", Community sync=" .. tostring(OTLGM and OTLGM.HandleCommunityAddonMessage ~= nil))
    PrintLine("Systems 1.5.4=" .. tostring(OTLGM and OTLGM.systems152Loaded) .. ", Announcements=" .. tostring(OTLGM and OTLGM.PublishAnnouncement152 ~= nil) .. ", UI module 1.5.4=" .. tostring(OTLGM and OTLGM.nextUILoaded))
    PrintLine("UI built 1.5.4=" .. tostring(OTLGM and OTLGM.ui153Loaded) .. ", Home 1.5.4=" .. tostring(OTLGM and OTLGM.ui and OTLGM.ui.home152DirectLayout))
    PrintLine("World auto-detect=" .. tostring(OTLGM and OTLGM.DetectWorldChannel153 ~= nil) .. ", Activity dialogs=" .. tostring(OTLGM and OTLGM.BuildActivityDialogs153 ~= nil) .. ", Profession filters=" .. tostring(OTLGM and OTLGM.GetCraftingCategory153 ~= nil))
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

eventFrame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        if OTLGM and OTLGM.EnsureDB then OTLGM:EnsureDB() end
    elseif event == "PLAYER_LOGIN" then
        if not OTLGM then
            PrintLine("Core.lua did not load.", true)
            return
        end
        if OTLGM.EnsureDB then OTLGM:EnsureDB() end
        if OTLGM.InstallInviteHook then OTLGM:InstallInviteHook() end
        if OTLGM.InstallGuildActionHooks then OTLGM:InstallGuildActionHooks() end
        if OTLGM.BuildMinimapButton then
            local ok, err = pcall(function() OTLGM:BuildMinimapButton() end)
            if not ok then PrintLine("Minimap runtime error: " .. tostring(err), true) end
        end
        if OTLGM.BroadcastVersion then OTLGM:BroadcastVersion() end
        if OTLGM.InitializePveSync then OTLGM:InitializePveSync() end
        if OTLGM.EnsureCraftingDB then OTLGM:EnsureCraftingDB() end
        if OTLGM.RequestCraftingSync then OTLGM.craftingInitialSyncAt = OTLGM:Now() + 12 end
        if OTLGM.RequestAnnouncementSync152 then OTLGM.announcementInitialSyncAt = OTLGM:Now() + 16 end
        if OTLGM.DetectWorldChannel153 then OTLGM:DetectWorldChannel153(true) end
        if not OTLGM.systems152Loaded then PrintLine("Systems152.lua did not load; 1.5.4 features are unavailable.", true) end
        if not OTLGM.fullUILoaded or not OTLGM.ToggleUI then
            PrintLine("Full UI did not load. Type /otltest for details.", true)
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "CHANNEL_NOTICE" then
        if OTLGM and OTLGM.DetectWorldChannel153 then OTLGM:DetectWorldChannel153(true) end
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
        if OTLGM and OTLGM.ScanCurrentProfession then OTLGM:ScanCurrentProfession("TRADE") end
    elseif event == "CRAFT_SHOW" then
        if OTLGM and OTLGM.ScanCurrentProfession then OTLGM:ScanCurrentProfession("CRAFT") end
    elseif event == "PLAYER_GUILD_UPDATE" then
        if OTLGM and OTLGM.BroadcastVersion then OTLGM:BroadcastVersion() end
        if OTLGM and OTLGM.RequestPveSync then OTLGM:RequestPveSync(true) end
        if OTLGM and OTLGM.RequestCraftingSync then OTLGM:RequestCraftingSync(true) end
        if OTLGM and OTLGM.RequestAnnouncementSync152 then OTLGM:RequestAnnouncementSync152(true) end
        if OTLGM and OTLGM.RefreshNavigation then OTLGM:RefreshNavigation() end
    elseif event == "GUILD_ROSTER_UPDATE" then
        if OTLGM and OTLGM.pendingScan then
            local reason = OTLGM.pendingScanReason or "INTERNAL"
            OTLGM.pendingScan = false
            OTLGM.pendingScanReason = nil
            OTLGM:Scan(reason)
        end
    end
end)

eventFrame:SetScript("OnUpdate", function()
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

    if OTLGM.ProcessPveSendQueue then OTLGM:ProcessPveSendQueue() end
    if OTLGM.ProcessCommunitySendQueue then OTLGM:ProcessCommunitySendQueue() end
    if OTLGM.ProcessCraftingTimers then OTLGM:ProcessCraftingTimers() end
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
    if OTLGM.pveMaintenanceElapsed >= 30 then
        OTLGM.pveMaintenanceElapsed = 0
        if OTLGM.PurgePveData then OTLGM:PurgePveData(false) end
        if OTLGM.CheckPveRaidReminders then OTLGM:CheckPveRaidReminders() end
        if OTLGM.PurgeCraftingData then OTLGM:PurgeCraftingData(false) end
        if OTLGM.RefreshDateIndicator then OTLGM:RefreshDateIndicator() end
        if OTLGM.ui and OTLGM.ui.main and OTLGM.ui.main:IsVisible() and OTLGM.ui.currentPage == "pve" and OTLGM.RefreshPvePage then OTLGM:RefreshPvePage() end
        if OTLGM.ui and OTLGM.ui.main and OTLGM.ui.main:IsVisible() and OTLGM.ui.currentPage == "professions" and OTLGM.RefreshProfessionsPage then OTLGM:RefreshProfessionsPage() end
        if OTLGM.ui and OTLGM.ui.main and OTLGM.ui.main:IsVisible() and OTLGM.ui.currentPage == "home" and OTLGM.RefreshHomePage then OTLGM:RefreshHomePage() end
    end

    local visible = OTLGM.ui and OTLGM.ui.main and OTLGM.ui.main:IsVisible()
    if not visible then return end

    if OTLGM.MaybeRefreshVisibleRoster then OTLGM:MaybeRefreshVisibleRoster() end

    if OTLGM.ui.currentPage == "recruitment" then
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
