-- Order of the Lion Guild Manager 1.8.2 native settings.
-- Responsive Settings, recovery, diagnostics and performance controls.

if not OTLGM or not OTLGM.UI then return end

local UI = OTLGM.UI
local C = UI.colors

local SETTINGS_TABS = {
    { "INTERFACE", "Interface", 88 },
    { "CHAT", "Chat", 90 },
    { "NOTIFICATIONS", "Notifications", 102 },
    { "PVE", "PvE Hub", 74 },
    { "NETWORK", "Shared Data", 96 },
    { "PERFORMANCE", "Performance", 96 },
    { "SUPPORT", "Support & Report", 116 },
    { "RECOVERY", "Backup", 76 },
    { "ABOUT", "About", 68 },
}
local NOTIFICATION_CATEGORIES = {
    { "raid", "Raid alerts" },
    { "announcement", "Guild announcements" },
    { "group", "Group Finder" },
    { "response", "Applications and responses" },
    { "crafting", "Crafting requests" },
    { "reaction", "Post reactions" },
    { "mention", "Mentions" },
}

local function Label(parent, value, template, x, y, width, justify)
    local label = UI.Text(parent, value, template, justify)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then label:SetWidth(width) end
    return label
end

local function MakeImportEdit(parent, width, height)
    return UI:EditBox(parent, width, height, {
        multiline = true,
        maxLetters = 2000000,
        fontObject = "ChatFontNormal",
        placeholder = "Paste a complete OTLGM backup here...",
    })
end

local function NewPanel(owner, page, key)
    local panel = CreateFrame("Frame", nil, page)
    panel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -44)
    panel:SetWidth(932)
    panel:SetHeight(544)
    panel:Hide()
    owner.ui.settingsPanels180[key] = panel
    return panel
end

local function AddCheck(card, label, y, getter, setter)
    local check = UI:Check(card, label, math.max(200, (card:GetWidth() or 420) - 28), function(value)
        setter(value and true or false)
    end)
    check:SetPoint("TOPLEFT", card, "TOPLEFT", 14, y)
    check.otlGetter180 = getter
    return check
end

function OTLGM:SetSettingsShellTab(tab)
    local valid = false
    local index
    for index = 1, table.getn(SETTINGS_TABS) do if SETTINGS_TABS[index][1] == tab then valid = true break end end
    if not valid then tab = "INTERFACE" end
    self.ui.settingsShellTab = tab
    OTLGM_DB.settings.settingsShellTab = tab
    for index = 1, table.getn(SETTINGS_TABS) do
        local key = SETTINGS_TABS[index][1]
        local panel = self.ui.settingsPanels180 and self.ui.settingsPanels180[key]
        if panel then if key == tab then panel:Show() else panel:Hide() end end
        if self.ui.settingsTabs180 and self.ui.settingsTabs180[key] then UI:SetSelected(self.ui.settingsTabs180[key], key == tab) end
    end
    self:RefreshSettingsPage()
end

function OTLGM:BuildSettingsImportModal()
    if self.ui.settingsImportModal then return end
    local modal = UI:Modal(self.ui.modalHost, 720, 530)
    modal:SetPoint("CENTER", self.ui.modalHost, "CENTER", 0, 0)
    modal.title = Label(modal, "Import Local Backup", "GameFontNormalLarge", 20, -18, 600, "LEFT")
    modal.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    modal.help = Label(modal, "Paste a complete OTLGM backup below. The addon checks the guild, realm, version and file integrity before replacing any saved data.", "GameFontNormalSmall", 20, -50, 680, "LEFT")
    modal.help:SetHeight(38)
    modal.help:SetJustifyV("TOP")
    modal.help:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.edit = MakeImportEdit(modal, 680, 360)
    modal.edit:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -90)
    modal.validation = Label(modal, "", "GameFontNormalSmall", 20, -464, 450, "LEFT")
    modal.validation:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.cancel = UI:Button(modal, "Cancel", 100, 30, function() OTLGM:CloseShellModal() end, "secondary")
    modal.cancel:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -138, 18)
    modal.import = UI:Button(modal, "Import", 100, 30, function()
        local ok, problem = OTLGM:ImportBackup(modal.edit:GetText() or "")
        if not ok then
            modal.validation:SetText(tostring(problem or "The backup could not be imported."))
            modal.validation:SetTextColor(C.red[1], C.red[2], C.red[3])
            return
        end
        OTLGM:CloseShellModal()
        OTLGM:ShowToast("Backup imported successfully.", "success")
        OTLGM:RefreshAll()
    end, "primary")
    modal.import:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -18, 18)
    self.ui.settingsImportModal = modal
end

function OTLGM:OpenSettingsImport()
    self:BuildSettingsImportModal()
    self.ui.settingsImportModal.edit:SetText("")
    self.ui.settingsImportModal.validation:SetText("Nothing changes until Import succeeds.")
    self.ui.settingsImportModal.validation:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    self:ShowShellModal(self.ui.settingsImportModal)
end

local function BuildInterface(owner, page)
    local panel = NewPanel(owner, page, "INTERFACE")
    owner.ui.settingsInterfacePanel = panel

    local scale = UI:Card(panel, 932, 170, "UI Scale and Window Size")
    scale:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    scale.buttons = {}
    scale.scaleLabel = Label(scale, "INTERFACE SCALE", "GameFontNormalSmall", 14, -32, 900, "LEFT")
    scale.scaleLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    local values = { { 0.90, "Small" }, { 1.00, "Normal" }, { 1.25, "Large" }, { 1.50, "XL" }, { "FIT", "Fit" } }
    local index
    for index = 1, table.getn(values) do
        local captured = index
        local definition = values[captured]
        local button = UI:Button(scale, definition[2], 112, 28, function()
            if definition[1] == "FIT" then
                OTLGM_DB.settings.uiScaleModeR2 = "FIT"
            else
                OTLGM_DB.settings.uiScale = definition[1]
                OTLGM_DB.settings.uiScaleModeR2 = "FIXED"
            end
            -- Max is a viewport-filling window-size preset, not merely a large
            -- fixed frame. Recompute its logical dimensions when the interface
            -- scale changes; otherwise Max selected at 150% becomes a much
            -- smaller window after choosing 90%, while the UI still says Max.
            if owner.GetWindowSizePreset180 and owner:GetWindowSizePreset180() == "MAX" then
                owner:SetWindowSizePreset180("MAX", { preserveNormalized = true, skipSettingsRefresh = true, reason = "scale-max" })
            else
                owner:ApplyUIScale(definition[1])
            end
            owner:RefreshSettingsPage()
        end, "filter")
        button:SetPoint("TOPLEFT", scale, "TOPLEFT", 14 + ((captured - 1) * 120), -48)
        button.otlScale = definition[1]
        scale.buttons[captured] = button
    end
    scale.windowLabel = Label(scale, "WINDOW SIZE", "GameFontNormalSmall", 14, -88, 900, "LEFT")
    scale.windowLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    scale.windowButtons = {}
    local windowValues = { { "COMPACT", "Compact" }, { "NORMAL", "Normal" }, { "LARGE", "Large" }, { "XL", "XL" }, { "MAX", "Max" } }
    for index = 1, table.getn(windowValues) do
        local captured = index
        local definition = windowValues[captured]
        local button = UI:Button(scale, definition[2], 112, 28, function()
            owner:SetWindowSizePreset180(definition[1])
        end, "filter")
        button:SetPoint("TOPLEFT", scale, "TOPLEFT", 14 + ((captured - 1) * 120), -104)
        button.otlWindowPreset180 = definition[1]
        scale.windowButtons[captured] = button
    end
    scale.status = Label(scale, "", "GameFontNormalSmall", 14, -142, 900, "LEFT")
    scale.status:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    owner.ui.settingsScaleCard = scale

    local options = UI:Card(panel, 452, 330, "Interface Preferences")
    options:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -182)
    options.minimap = AddCheck(options, "Show minimap button", -36, function() return OTLGM_DB.settings.showMinimap end, function(value)
        OTLGM_DB.settings.showMinimap = value
        if owner.ApplyMinimapVisibility then owner:ApplyMinimapVisibility() end
    end)
    options.lock = AddCheck(options, "Lock main window position", -70, function() return OTLGM_DB.settings.windowLocked end, function(value) OTLGM_DB.settings.windowLocked = value end)
    options.home = AddCheck(options, "Always open Home instead of last page", -104, function() return OTLGM_DB.settings.openHome end, function(value) OTLGM_DB.settings.openHome = value end)
    options.help = AddCheck(options, "Show contextual tooltips", -138, function() return OTLGM_DB.settings.showHelp ~= false end, function(value) OTLGM_DB.settings.showHelp = value end)
    options.keepInside = AddCheck(options, "Keep window inside screen", -172, function() return OTLGM_DB.settings.keepWindowInsideScreen180 end, function(value)
        OTLGM_DB.settings.keepWindowInsideScreen180 = value
        if owner.UpdateWindowResizeBounds180 then owner:UpdateWindowResizeBounds180() end
        if owner.RestoreWindowPosition180 then owner:RestoreWindowPosition180("settings-toggle") end
        if owner.SaveWindowGeometry180 then owner:SaveWindowGeometry180("keep-inside-toggle") end
    end)
    options.classColors = AddCheck(options, "Use class colours for player names", -206, function() return OTLGM_DB.settings.classColors ~= false end, function(value)
        OTLGM_DB.settings.classColors = value owner:RefreshAll()
    end)
    options.leadership = AddCheck(options, "Show leadership and special-rank signals", -240, function() return OTLGM_DB.settings.highlightLeadership ~= false end, function(value)
        OTLGM_DB.settings.highlightLeadership = value owner:RefreshAll()
    end)
    options.reset = UI:Button(options, "Reset Window Position", 176, 30, function()
        owner:CenterWindow176()
        owner:ShowToast("Window position reset.", "success")
    end, "utility")
    options.reset:SetPoint("BOTTOMLEFT", options, "BOTTOMLEFT", 14, 16)
    owner.ui.settingsOptionsCard = options

    local behavior = UI:Card(panel, 468, 360, "Workspace and Roster")
    behavior:SetPoint("TOPLEFT", panel, "TOPLEFT", 464, -182)
    behavior.modeLabel = Label(behavior, "WORKSPACE MODE", "GameFontNormalSmall", 14, -36, 430, "LEFT")
    behavior.modeLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    behavior.modeButtons = {}
    local modeDefinitions = { { "AUTO", "Auto" }, { "MEMBER", "Member" }, { "OFFICER", "Officer" } }
    for index = 1, table.getn(modeDefinitions) do
        local captured = index
        local definition = modeDefinitions[captured]
        local button = UI:Button(behavior, definition[2], 104, 28, function()
            owner:SetUIMode(definition[1])
            owner:RefreshSettingsPage()
        end, "filter")
        button:SetPoint("TOPLEFT", behavior, "TOPLEFT", 14 + ((captured - 1) * 112), -58)
        button.otlMode180 = definition[1]
        behavior.modeButtons[captured] = button
    end
    behavior.scanLabel = Label(behavior, "ROSTER UPDATE INTERVAL", "GameFontNormalSmall", 14, -104, 430, "LEFT")
    behavior.scanLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    behavior.scanButtons = {}
    local intervalDefinitions = { { 0, "Off" }, { 600, "10m" }, { 1200, "20m" }, { 1800, "30m" }, { 3600, "60m" } }
    for index = 1, table.getn(intervalDefinitions) do
        local captured = index
        local definition = intervalDefinitions[captured]
        local button = UI:Button(behavior, definition[2], 62, 27, function()
            if definition[1] == 0 then OTLGM_DB.settings.autoScan = false
            else OTLGM_DB.settings.autoScan = true OTLGM_DB.settings.scanInterval = definition[1] end
            owner.elapsed = 0
            owner:RefreshSettingsPage()
        end, "filter")
        button:SetPoint("TOPLEFT", behavior, "TOPLEFT", 14 + ((captured - 1) * 68), -126)
        button.otlInterval180 = definition[1]
        behavior.scanButtons[captured] = button
    end
    behavior.openText = Label(behavior, "", "GameFontNormalSmall", 14, -166, 430, "LEFT")
    behavior.openText:SetHeight(38) behavior.openText:SetJustifyV("TOP") behavior.openText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    behavior.quickDock = AddCheck(behavior, "Use Quick Dock when parked", -204, function() return OTLGM_DB.settings.useQuickDockWhenParked182 ~= false end, function(value)
        OTLGM_DB.settings.useQuickDockWhenParked182 = value
        if owner.RefreshQuickDockSettings182 then owner:RefreshQuickDockSettings182() end
    end)
    behavior.quickDock.otlTooltipTitle = "Quick Dock"
    behavior.quickDock.otlTooltip = "Off keeps the small crest-only Park control. Your Dock position is remembered after reloading the UI."
    behavior.closeToDock = AddCheck(behavior, "Keep Quick Dock when addon closes", -234, function() return OTLGM_DB.settings.closeToQuickDock183 ~= false end, function(value)
        OTLGM_DB.settings.closeToQuickDock183 = value
    end)
    behavior.closeToDock.otlTooltipTitle = "Keep Quick Dock on close"
    behavior.closeToDock.otlTooltip = "Enabled by default: the X button and minimap/slash toggle close the main window into the compact Quick Dock. Turn this off for a complete hide. Right-click the parked Lion to hide the Dock explicitly."
    behavior.autoProfile183 = AddCheck(behavior, "Automatically open member profile in Roster", -264, function() return OTLGM_DB.settings.showGuildProfileOnRoster183 ~= false end, function(value)
        OTLGM_DB.settings.showGuildProfileOnRoster183 = value
        if not value and owner.CloseGuildProfile183 then owner:CloseGuildProfile183("setting-off") end
    end)
    behavior.autoProfile183.otlTooltipTitle = "Guild Profile"
    behavior.autoProfile183.otlTooltip = "When Roster opens, the addon selects a useful member and shows the Guild Profile beside the list. Selecting another row updates that profile. Turn this off if you prefer the details panel only."
    behavior.socialGuild183 = AddCheck(behavior, "Social > Guild opens Online Roster", -294, function() return OTLGM_DB.settings.socialGuildOpensRoster183 ~= false end, function(value)
        OTLGM_DB.settings.socialGuildOpensRoster183 = value
        if owner.InstallSocialGuildHook183 then owner:InstallSocialGuildHook183() end
    end)
    behavior.socialGuild183.otlTooltipTitle = "Social > Guild shortcut"
    behavior.socialGuild183.otlTooltip = "When enabled, explicitly clicking Guild in the normal Social window opens the addon Online Roster. Simply opening Social never redirects, even if Blizzard remembers Guild as the previous tab, so Friends / Who / Raid remain usable. Disable this to keep Blizzard Guild unchanged."
    behavior.home = UI:Button(behavior, "Open Home", 122, 30, function() owner:ShowPage("home") end, "primary")
    behavior.home:SetPoint("BOTTOMLEFT", behavior, "BOTTOMLEFT", 14, 4)
    behavior.last = UI:Button(behavior, "Open last page", 138, 30, function()
        local target = OTLGM_DB.settings.lastPage or "home"
        if target == "settings" then target = "home" end
        owner:ShowPage(target)
    end, "secondary")
    behavior.last:SetPoint("LEFT", behavior.home, "RIGHT", 8, 0)
    owner.ui.settingsBehaviorCard = behavior
end

local function BuildChat(owner, page)
    local panel = NewPanel(owner, page, "CHAT")
    owner.ui.settingsChatPanel = panel
    local display = UI:Card(panel, 452, 360, "Guild Chat Display")
    display:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    display.mentions = AddCheck(display, "Highlight when my character is mentioned", -42, function() return OTLGM_DB.settings.chatHighlightMentions ~= false end, function(value) OTLGM_DB.settings.chatHighlightMentions = value owner:RefreshGuildChatPage() end)
    display.separators = AddCheck(display, "Show date and long-gap separators", -78, function() return OTLGM_DB.settings.chatTimeSeparators ~= false end, function(value) OTLGM_DB.settings.chatTimeSeparators = value owner:RefreshGuildChatPage() end)
    display.ranks = AddCheck(display, "Show rank or leadership status in chat", -114, function() return OTLGM_DB.settings.chatShowRanks ~= false end, function(value) OTLGM_DB.settings.chatShowRanks = value owner:RefreshGuildChatPage() end)
    display.classColors = AddCheck(display, "Use class colours for player names", -150, function() return OTLGM_DB.settings.classColors ~= false end, function(value) OTLGM_DB.settings.classColors = value owner:RefreshAll() end)
    display.leadership = AddCheck(display, "Show leadership icons where useful", -186, function() return OTLGM_DB.settings.highlightLeadership ~= false end, function(value) OTLGM_DB.settings.highlightLeadership = value owner:RefreshAll() end)
    display.help = Label(display, "Guild and Officer unread counts remain separate. Shift-clicking an item or spell while the composer is focused inserts its link.", "GameFontNormalSmall", 14, -242, 422, "LEFT")
    display.help:SetHeight(72) display.help:SetJustifyV("TOP") display.help:SetTextColor(C.grey[1], C.grey[2], C.grey[3])

    local sending = UI:Card(panel, 468, 360, "Composer and Sending")
    sending:SetPoint("TOPLEFT", panel, "TOPLEFT", 464, 0)
    sending.scan = AddCheck(sending, "Show one normal-chat line after roster updates", -42, function() return OTLGM_DB.settings.scanChat and true or false end, function(value) OTLGM_DB.settings.scanChat = value end)
    sending.confirm = AddCheck(sending, "Preview recruitment messages before sending", -78, function() return OTLGM_DB.settings.confirmRecruitment ~= false end, function(value) OTLGM_DB.settings.confirmRecruitment = value end)
    sending.help = Label(sending, "The Guild Chat composer keeps a dedicated lower band. Escape clears active text first, then releases focus, then closes the window when no modal or drawer is open.", "GameFontNormalSmall", 14, -136, 438, "LEFT")
    sending.help:SetHeight(92) sending.help:SetJustifyV("TOP") sending.help:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    sending.open = UI:Button(sending, "Open Guild Chat", 148, 30, function() owner:ShowPage("guildchat") end, "primary")
    sending.open:SetPoint("BOTTOMLEFT", sending, "BOTTOMLEFT", 14, 18)
    owner.ui.settingsChatCard = display
    owner.ui.settingsSendingCard = sending
end

local function BuildNotifications(owner, page)
    local panel = NewPanel(owner, page, "NOTIFICATIONS")
    owner.ui.settingsNotificationsPanel = panel
    local card = UI:Card(panel, 932, 500, "Notifications")
    card:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    card.intro = Label(card, "Visual alerts and sounds are controlled independently. Routine background updates stay quiet.", "GameFontNormalSmall", 14, -38, 900, "LEFT")
    card.intro:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    card.rows = {}
    local index
    for index = 1, table.getn(NOTIFICATION_CATEGORIES) do
        local captured = index
        local definition = NOTIFICATION_CATEGORIES[captured]
        local row = UI:Card(card, 900, 50, "")
        row:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -68 - ((captured - 1) * 56))
        row.title = Label(row, definition[2], "GameFontNormalSmall", 12, -18, 310, "LEFT")
        row.visual = UI:Check(row, "Visual", 110, function(value)
            local pref = owner:GetNotificationPreference152(definition[1]) pref.visual = value and true or false
        end)
        row.visual:SetPoint("TOPLEFT", row, "TOPLEFT", 360, -10)
        row.sound = UI:Check(row, "Sound", 110, function(value)
            local pref = owner:GetNotificationPreference152(definition[1]) pref.sound = value and true or false
        end)
        row.sound:SetPoint("TOPLEFT", row, "TOPLEFT", 486, -10)
        row.choice = UI:Button(row, "Sound", 154, 26, function()
            owner:CycleNotificationSound152(definition[1]) owner:RefreshSettingsPage()
        end, "inline")
        row.choice:SetPoint("TOPRIGHT", row, "TOPRIGHT", -12, -12)
        row.otlCategory180 = definition[1]
        card.rows[captured] = row
    end
    owner.ui.settingsNotificationsCard = card
end

local function BuildPve(owner, page)
    local panel = NewPanel(owner, page, "PVE")
    owner.ui.settingsPvePanel = panel
    local options = UI:Card(panel, 452, 430, "Connected Action Notifications")
    options:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    options.popups = AddCheck(options, "Show popup notifications for eligible raid alerts", -44, function() return OTLGM_DB.settings.pveRaidPopups ~= false end, function(value) OTLGM_DB.settings.pveRaidPopups = value end)
    options.chat = AddCheck(options, "Also print raid notices in normal chat", -82, function() return OTLGM_DB.settings.pveRaidChatLine and true or false end, function(value) OTLGM_DB.settings.pveRaidChatLine = value end)
    options.matching = AddCheck(options, "Matching group notifications", -120, function() return OTLGM_DB.settings.pveMatchingGroupNotifications180 ~= false and OTLGM_DB.settings.c7MatchingGroups180 ~= false end, function(value)
        OTLGM_DB.settings.c7MatchingGroups180 = value and true or false
        OTLGM_DB.settings.pveMatchingGroupNotifications180 = value and true or false
        if owner.RefreshPveCharacterProfile180 then owner:RefreshPveCharacterProfile180() end
    end)
    options.craftable = AddCheck(options, "Craftable request notifications", -158, function() return OTLGM_DB.settings.c7CraftableRequests180 ~= false end, function(value)
        OTLGM_DB.settings.c7CraftableRequests180 = value and true or false
    end)
    options.assignedRaid = AddCheck(options, "Assigned raid update notifications", -196, function() return OTLGM_DB.settings.c7AssignedRaidUpdates180 ~= false end, function(value)
        OTLGM_DB.settings.c7AssignedRaidUpdates180 = value and true or false
    end)
    options.inviteStart = AddCheck(options, "Raid invite-start notifications", -234, function() return OTLGM_DB.settings.c7RaidInviteStart180 ~= false end, function(value)
        OTLGM_DB.settings.c7RaidInviteStart180 = value and true or false
    end)
    options.info = Label(options, "Global category Visual/Sound settings still control presentation. Matching groups also require this character's local profile and at least one selected role. No separate addon calendar is created.", "GameFontNormalSmall", 14, -278, 422, "LEFT")
    options.info:SetHeight(74) options.info:SetJustifyV("TOP") options.info:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    options.open = UI:Button(options, "Open PvE Hub", 132, 30, function() owner:ShowPage("pve") end, "primary")
    options.open:SetPoint("BOTTOMLEFT", options, "BOTTOMLEFT", 14, 18)

    local network = UI:Card(panel, 468, 430, "PvE Data")
    network:SetPoint("TOPLEFT", panel, "TOPLEFT", 464, 0)
    network.info = Label(network, "Groups, applications and raid alerts are shared with online guildmates using the addon. The page reports an update only after another client responds or new data arrives.", "GameFontNormalSmall", 14, -44, 438, "LEFT")
    network.info:SetHeight(92) network.info:SetJustifyV("TOP") network.info:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    network.sync = UI:Button(network, "Check PvE Updates", 166, 30, function()
        if owner:RequestPveSync(true, true) then owner:ShowToast("PvE refresh requested.", "pending") end
    end, "utility")
    network.sync:SetPoint("TOPLEFT", network, "TOPLEFT", 14, -160)
    network.clear = UI:Button(network, "Clear Saved PvE Data", 174, 30, function()
        owner:ShowConfirm("Clear Saved PvE Data", "Remove saved groups, applications, raid alerts and board posts? Current information can be requested again from online guildmates using the addon.", "Clear", function()
            local pve = owner:EnsurePveDB()
            if pve then pve.requests = {} pve.board = {} pve.raid = nil pve.deleted = {} pve.unread = { RAIDS = 0, GROUPS = 0, BOARD = 0 } owner:OnPveDataChanged(nil, false) end
        end)
    end, "danger")
    network.clear:SetPoint("TOPLEFT", network, "TOPLEFT", 14, -204)
    owner.ui.settingsPveOptionsCard = options
    owner.ui.settingsPveDataCard = network
end

local function BuildNetwork(owner, page)
    local panel = NewPanel(owner, page, "NETWORK")
    owner.ui.settingsNetworkPanel = panel
    local health = UI:Card(panel, 932, 350, "Connection & Shared Data")
    health:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    health.summary = Label(health, "", "GameFontNormalSmall", 14, -42, 900, "LEFT")
    health.summary:SetHeight(210) health.summary:SetJustifyV("TOP") health.summary:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    health.help = Label(health, "If something is broken, laggy or out of sync, use Support & Report. Copy Issue Report prepares the useful diagnostics in one place.", "GameFontNormalSmall", 14, -270, 900, "LEFT")
    health.help:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    health.support = UI:Button(health, "Report Issue", 132, 30, function() owner:SetSettingsShellTab("SUPPORT") end, "danger")
    health.support.otlTooltipTitle = "Support and diagnostics"
    health.support.otlTooltip = "Open the single Support & Report flow and prepare one ready-to-paste diagnostic ticket report."
    health.support:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT", 14, 18)
    health.users = UI:Button(health, "Sharing Status", 154, 30, function() owner:ToggleAddonUsersDrawer() end, "secondary")
    health.users:SetPoint("LEFT", health.support, "RIGHT", 8, 0)
    health.version = UI:Button(health, "Share Version", 148, 30, function() if owner.BroadcastVersion then owner:BroadcastVersion() end end, "utility")
    health.version:SetPoint("LEFT", health.users, "RIGHT", 8, 0)

    local sync = UI:Card(panel, 932, 140, "Update Shared Guild Data")
    sync:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -362)
    sync.pve = UI:Button(sync, "PvE Hub", 126, 30, function() owner:RequestPveSync(true, true) end, "utility")
    sync.pve:SetPoint("TOPLEFT", sync, "TOPLEFT", 14, -48)
    sync.crafting = UI:Button(sync, "Professions", 126, 30, function()
        if owner:RequestCraftingSync(true, true) and owner.ShowToast then owner:ShowToast("Refreshing profession information…", "pending") end
    end, "utility")
    sync.crafting:SetPoint("LEFT", sync.pve, "RIGHT", 8, 0)
    sync.posts = UI:Button(sync, "Guild Posts", 126, 30, function() owner:RequestAnnouncementSync152(true) end, "utility")
    sync.posts:SetPoint("LEFT", sync.crafting, "RIGHT", 8, 0)
    sync.all = UI:Button(sync, "Update All", 126, 30, function()
        if owner.ScheduleAfter180 then
            owner:ScheduleAfter180("manual-sync-all-pve181", 0, function(current) if current.RequestPveSync then current:RequestPveSync(true, true) end end, 55)
            owner:ScheduleAfter180("manual-sync-all-crafting181", 0.35, function(current) if current.RequestCraftingSync then current:RequestCraftingSync(true, true) end end, 45)
            owner:ScheduleAfter180("manual-sync-all-posts181", 0.70, function(current) if current.RequestAnnouncementSync152 then current:RequestAnnouncementSync152(true) end end, 40)
        else
            if owner.RequestPveSync then owner:RequestPveSync(true, true) end
            if owner.RequestCraftingSync then owner:RequestCraftingSync(true, true) end
            if owner.RequestAnnouncementSync152 then owner:RequestAnnouncementSync152(true) end
        end
        owner:ShowToast("Shared guild data refresh started.", "pending")
    end, "primary")
    sync.all:SetPoint("LEFT", sync.posts, "RIGHT", 8, 0)
    sync.info = Label(sync, "Use Update All when you want the latest shared PvE, profession and guild-post data right now. Normal page browsing does not send extra requests.", "GameFontNormalSmall", 14, -94, 900, "LEFT")
    sync.info:SetHeight(34) sync.info:SetJustifyV("TOP") sync.info:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    owner.ui.settingsNetworkHealthCard = health
    owner.ui.settingsNetworkSyncCard = sync
end

local function BuildPerformance(owner, page)
    local panel = NewPanel(owner, page, "PERFORMANCE")
    owner.ui.settingsPerformancePanel = panel

    local guard = UI:Card(panel, 932, 290, "Performance Guard")
    guard:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    guard.profileLabel = Label(guard, "PERFORMANCE PROFILE", "GameFontNormalSmall", 14, -36, 900, "LEFT")
    guard.profileLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    guard.profileButtons = {}
    local profiles = {
        { "AUTO", "Auto" },
        { "SMOOTH", "Smooth" },
        { "FRESH", "Fast Updates" },
    }
    local index
    for index = 1, table.getn(profiles) do
        local captured = index
        local definition = profiles[captured]
        local button = UI:Button(guard, definition[2], 144, 30, function()
            OTLGM_DB.settings.performanceProfile181 = definition[1]
            owner:RefreshSettingsPage()
            owner:ShowToast(definition[2] .. " performance profile enabled.", "success")
        end, "filter")
        button:SetPoint("TOPLEFT", guard, "TOPLEFT", 14 + ((captured - 1) * 154), -56)
        button.otlPerformanceProfile181 = definition[1]
        guard.profileButtons[captured] = button
    end
    guard.profileHelp = Label(guard, "Auto is recommended. Smooth uses smaller slices. Fast Updates favors quicker refreshes while keeping emergency FPS protection.", "GameFontNormalSmall", 486, -54, 424, "LEFT")
    guard.profileHelp:SetHeight(52) guard.profileHelp:SetJustifyV("TOP") guard.profileHelp:SetTextColor(C.grey[1], C.grey[2], C.grey[3])

    guard.motionLabel = Label(guard, "INTERFACE MOTION", "GameFontNormalSmall", 14, -112, 900, "LEFT")
    guard.motionLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    guard.motionButtons = {}
    local motions = { { "FULL", "Full" }, { "REDUCED", "Reduced" }, { "OFF", "Off" } }
    for index = 1, table.getn(motions) do
        local captured = index
        local definition = motions[captured]
        local button = UI:Button(guard, definition[2], 112, 28, function()
            OTLGM_DB.settings.motionMode170 = definition[1]
            owner:RefreshSettingsPage()
        end, "filter")
        button:SetPoint("TOPLEFT", guard, "TOPLEFT", 14 + ((captured - 1) * 122), -132)
        button.otlMotionMode170 = definition[1]
        guard.motionButtons[captured] = button
    end
    guard.motionHelp = Label(guard, "Reduced or Off helps when the client is already under graphical load. Combat suppresses non-essential motion.", "GameFontNormalSmall", 390, -132, 520, "LEFT")
    guard.motionHelp:SetHeight(40) guard.motionHelp:SetJustifyV("TOP") guard.motionHelp:SetTextColor(C.grey[1], C.grey[2], C.grey[3])

    guard.adaptive = AddCheck(guard, "Adaptive stutter guard (temporarily reduces background work after a detected spike)", -184, function() return OTLGM_DB.settings.adaptiveStutterGuard181 ~= false end, function(value)
        OTLGM_DB.settings.adaptiveStutterGuard181 = value
        if not value and owner.runtime then owner.runtime.performanceGuardUntil181 = nil end
    end)
    guard.combat = AddCheck(guard, "Reduce background addon updates while in combat", -216, function() return OTLGM_DB.settings.pauseBulkSyncInCombat ~= false end, function(value)
        OTLGM_DB.settings.pauseBulkSyncInCombat = value
    end)
    guard.note = Label(guard, "Recommended: Auto + Adaptive Guard + Reduced motion + fewer background updates in combat.", "GameFontNormalSmall", 14, -256, 650, "LEFT")
    guard.note:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    guard.recommended = UI:Button(guard, "Use Recommended", 156, 28, function()
        OTLGM_DB.settings.performanceProfile181 = "AUTO"
        OTLGM_DB.settings.adaptiveStutterGuard181 = true
        OTLGM_DB.settings.motionMode170 = "REDUCED"
        OTLGM_DB.settings.pauseBulkSyncInCombat = true
        owner:RefreshSettingsPage()
        owner:ShowToast("Recommended performance settings applied.", "success")
    end, "primary")
    guard.recommended:SetPoint("BOTTOMRIGHT", guard, "BOTTOMRIGHT", -14, 14)
    owner.ui.settingsPerformanceGuardCard = guard

    local live = UI:Card(panel, 932, 238, "Live Performance State")
    live:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -302)
    live.summary = Label(live, "", "GameFontNormalSmall", 14, -40, 900, "LEFT")
    live.summary:SetHeight(130) live.summary:SetJustifyV("TOP") live.summary:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    live.refresh = UI:Button(live, "Refresh Numbers", 140, 30, function() owner:RefreshSettingsPage() end, "secondary")
    live.refresh:SetPoint("BOTTOMLEFT", live, "BOTTOMLEFT", 14, 16)
    live.support = UI:Button(live, "Report Issue", 132, 30, function() owner:SetSettingsShellTab("SUPPORT") end, "danger")
    live.support.otlTooltipTitle = "Copy diagnostics"
    live.support.otlTooltip = "Quick and Full support reports are centralized in Settings > Support & Report."
    live.support:SetPoint("LEFT", live.refresh, "RIGHT", 8, 0)
    live.clean = UI:Button(live, "Start Clean Test", 142, 30, function()
        if owner.ResetPerformanceEvidence181 then owner:ResetPerformanceEvidence181() end
        owner:RefreshSettingsPage()
        owner:ShowToast("Performance history cleared. Reproduce the issue, then open Support & Report and copy the Issue Report.", "success")
    end, "utility")
    live.clean:SetPoint("LEFT", live.support, "RIGHT", 8, 0)
    owner.ui.settingsPerformanceLiveCard = live
end

function OTLGM:OpenSupportCenterR59(fromIncident)
    if self.ShowPage then self:ShowPage("settings") end
    if self.SetSettingsShellTab then self:SetSettingsShellTab("SUPPORT") end
    if self.RefreshSettingsPage then self:RefreshSettingsPage("SUPPORT") end
    return true
end

function OTLGM:GetPreparedIssueReportR59()
    self.runtime = self.runtime or {}
    local incident = self.runtime.supportIncidentR59
    local snapshot = incident and incident.snapshot or (self.CaptureSupportIncidentSnapshotR59 and self:CaptureSupportIncidentSnapshotR59("Manual report", "No automatic incident selected") or {})
    local report = nil
    if self.GetSupportReport181 then
        local ok, value = pcall(self.GetSupportReport181, self)
        if ok then report = value end
    end
    if not report and self.GetDiagnosticsText then
        local ok, value = pcall(self.GetDiagnosticsText, self)
        if ok then report = value end
    end
    report = report or "Full diagnostics unavailable in this runtime."
    local severity = incident and tostring(incident.severity or "ATTENTION") or "MANUAL"
    local occurrence = incident and math.max(1, tonumber(incident.count) or 1) or 0
    local incidentTs = tonumber(snapshot and snapshot.ts) or self:Now()
    local fpsText = snapshot and snapshot.fps and tostring(math.floor((tonumber(snapshot.fps) or 0) + 0.5)) or "n/a"
    local lines = {
        "=== ORDER OF THE LION ADDON ISSUE REPORT ===",
        "Paste this whole report into the addon-support ticket. Add one short sentence above it only if the problem needs human context.",
        "Severity/source: " .. severity .. " / " .. tostring(incident and incident.source or "manual"),
        "Occurrences this session: " .. tostring(occurrence),
        "Incident time: " .. (date and date("%d/%m/%Y %H:%M:%S", incidentTs) or tostring(incidentTs)),
        "At incident: page=" .. tostring(snapshot and snapshot.page or "unknown")
            .. " / zone=" .. tostring(snapshot and snapshot.zone or "unknown")
            .. ((snapshot and snapshot.subzone and snapshot.subzone ~= "") and (" / " .. tostring(snapshot.subzone)) or "")
            .. " / combat=" .. tostring(snapshot and snapshot.combat and "yes" or "no")
            .. " / FPS=" .. fpsText .. " / network queue=" .. tostring(snapshot and snapshot.queue or 0),
        "Detected detail: " .. tostring(incident and incident.message or "No automatic hard failure was selected; this is a manual report."),
        "Privacy: generated support export excludes guild-chat history, officer notes and private moderation/report text.",
        "",
        "--- FULL DIAGNOSTIC ATTACHMENT ---",
        report,
        "=== END ADDON ISSUE REPORT ===",
    }
    return table.concat(lines, "\n")
end

local function BuildSupport(owner, page)
    local panel = NewPanel(owner, page, "SUPPORT")
    owner.ui.settingsSupportPanelR32 = panel

    local reports = UI:Card(panel, 932, 270, "Support & Report")
    reports:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    reports.intro = Label(reports, "If the addon is not working correctly, use Copy Issue Report first. It automatically attaches the useful build, page, incident, network, performance, sync and compatibility evidence. Nothing is sent automatically.", "GameFontNormal", 18, -44, 896, "LEFT")
    reports.intro:SetHeight(58) reports.intro:SetJustifyV("TOP")
    reports.issueR59 = UI:Button(reports, "Copy Issue Report", 178, 34, function()
        local text = owner.GetPreparedIssueReportR59 and owner:GetPreparedIssueReportR59() or "Issue report unavailable."
        owner:ShowCopyDialog("Order of the Lion Addon Issue Report", text)
        owner:RefreshSettingsPage("SUPPORT")
    end, "primary")
    reports.issueR59:SetPoint("TOPLEFT", reports, "TOPLEFT", 18, -112)
    reports.issueR59.otlTooltipTitle = "Recommended support report"
    reports.issueR59.otlTooltip = "One ready-to-paste ticket report with the incident snapshot and full diagnostics attached."
    reports.quick = UI:Button(reports, "Quick Report", 142, 34, function()
        local text = owner.GetCompactSupportReportR32 and owner:GetCompactSupportReportR32() or (owner.GetDiagnosticsText and owner:GetDiagnosticsText() or "Diagnostics unavailable.")
        owner:ShowCopyDialog("Order of the Lion Quick Report", text)
    end, "secondary")
    reports.quick:SetPoint("LEFT", reports.issueR59, "RIGHT", 10, 0)
    reports.quick.otlTooltipTitle = "Quick Report"
    reports.quick.otlTooltip = "Short technical snapshot for a simple UI question."
    reports.full = UI:Button(reports, "Full Report", 142, 34, function()
        local report
        if owner.GetSupportReport181 then
            local ok, value = pcall(owner.GetSupportReport181, owner)
            if ok then report = value elseif owner.RecordInternalIssueRC3 then pcall(owner.RecordInternalIssueRC3, owner, "Diagnostics/SUPPORT_REPORT", value) end
        end
        if not report then
            local ok, value = pcall(owner.GetDiagnosticsText, owner)
            report = ok and value or ("Support report could not be generated: " .. tostring(value or "unknown error"))
        end
        owner:ShowCopyDialog("Order of the Lion Full Support Report", report)
        owner:RefreshSettingsPage("SUPPORT")
    end, "utility")
    reports.full:SetPoint("LEFT", reports.quick, "RIGHT", 10, 0)
    reports.full.otlTooltipTitle = "Full Report"
    reports.full.otlTooltip = "The raw engineering report. Copy Issue Report is normally easier for tickets."
    reports.selfCheckR33 = UI:Button(reports, "Run Self Check", 150, 34, function()
        local result = owner.RunSupportSelfCheck181 and owner:RunSupportSelfCheck181() or nil
        owner:RefreshSettingsPage("SUPPORT")
        if result and result.status == "PASS" then owner:ShowToast("Self Check: PASS. No structural problem detected.", "success")
        elseif result and result.status == "WARN" then owner:ShowToast("Self Check: WARN. Review Current Status or copy the Issue Report.", "pending")
        elseif result then owner:ShowToast("Self Check: FAIL. Copy the Issue Report before changing data or settings.", "error")
        else owner:ShowToast("Self Check is unavailable in this build.", "error") end
    end, "secondary")
    reports.selfCheckR33:SetPoint("LEFT", reports.full, "RIGHT", 10, 0)
    reports.selfCheckR33.otlTooltipTitle = "Run Self Check"
    reports.selfCheckR33.otlTooltip = "Runs bounded structural/network/performance checks now. It does not start background monitoring."
    reports.clean = UI:Button(reports, "Start Clean Test", 142, 30, function()
        if owner.ResetPerformanceEvidence181 then owner:ResetPerformanceEvidence181() end
        owner:RefreshSettingsPage("SUPPORT")
        owner:ShowToast("Clean Test started. Reproduce the problem, then return here and copy the Issue Report.", "success")
    end, "utility")
    reports.clean:SetPoint("TOPLEFT", reports, "TOPLEFT", 18, -164)
    reports.users = UI:Button(reports, "Sharing Status", 154, 30, function() owner:ToggleAddonUsersDrawer() end, "secondary")
    reports.users:SetPoint("LEFT", reports.clean, "RIGHT", 8, 0)
    reports.note = Label(reports, "Issue/Support reports exclude full guild-chat history, officer notes and private report text. Routine ping/FPS/network fluctuations stay silent; Support never opens itself and nothing is sent automatically.", "GameFontNormalSmall", 18, -214, 896, "LEFT")
    reports.note:SetHeight(42) reports.note:SetJustifyV("TOP") reports.note:SetTextColor(C.grey[1], C.grey[2], C.grey[3])

    local compatibility = UI:Card(panel, 932, 254, "Health & Compatibility")
    compatibility:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -282)
    compatibility.healthR50 = Label(compatibility, "", "GameFontNormal", 18, -42, 896, "LEFT")
    compatibility.healthR50:SetHeight(24)
    compatibility.statusR33 = Label(compatibility, "", "GameFontNormalSmall", 18, -72, 896, "LEFT")
    compatibility.statusR33:SetHeight(106) compatibility.statusR33:SetJustifyV("TOP")
    compatibility.guidanceR33 = Label(compatibility, "Shared features adapt automatically to the other player's addon version. If a newer version is needed, the page explains what is missing; older clients keep safe fallback views.", "GameFontNormalSmall", 18, -184, 896, "LEFT")
    compatibility.guidanceR33:SetHeight(30) compatibility.guidanceR33:SetJustifyV("TOP") compatibility.guidanceR33:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    compatibility.refreshR33 = UI:Button(compatibility, "Refresh Status", 132, 28, function() owner:RefreshSettingsPage("SUPPORT") end, "secondary")
    compatibility.refreshR33:SetPoint("BOTTOMLEFT", compatibility, "BOTTOMLEFT", 18, 12)
    compatibility.broadcast = UI:Button(compatibility, "Share Version", 148, 28, function() if owner.BroadcastVersion then owner:BroadcastVersion() end end, "utility")
    compatibility.broadcast:SetPoint("LEFT", compatibility.refreshR33, "RIGHT", 8, 0)
    owner.ui.settingsSupportReportsR32 = reports
    owner.ui.settingsSupportCompatibilityR32 = compatibility
end

local function SupportStatusLineR33(color, label, text)
    return tostring(color or "|cffaaaaaa") .. tostring(label or "INFO") .. "|r  " .. tostring(text or "")
end

function OTLGM:GetSupportHealthSnapshotR50(force)
    self.runtime = self.runtime or {}
    local now = self:Now()
    local cached = self.runtime.supportHealthSnapshotR50
    if not force and cached and now - (tonumber(cached.ts) or 0) < 1 then return cached end

    local queue, queueCritical, queueNormal, queueBulk = 0, 0, 0, 0
    if self.GetNetworkQueueDepth then
        queue, queueCritical, queueNormal, queueBulk = self:GetNetworkQueueDepth()
        queue, queueCritical, queueNormal, queueBulk = tonumber(queue) or 0, tonumber(queueCritical) or 0, tonumber(queueNormal) or 0, tonumber(queueBulk) or 0
    end
    local perf = self.PrunePerformanceDiagnostics180 and self:PrunePerformanceDiagnostics180(false) or {}
    local worst, worstName = 0, "none"
    local index, spike
    for index = 1, table.getn(perf.spikes or {}) do
        spike = perf.spikes[index]
        if spike and (tonumber(spike.ms) or 0) > worst then
            worst = tonumber(spike.ms) or 0
            worstName = tostring(spike.operation or "unknown")
        end
    end

    local addonOnline = 0
    local guild = self.GetGuildDB and self:GetGuildDB() or nil
    local name, info
    for name, info in pairs(guild and guild.detectedVersions or {}) do
        local age = now - (type(info) == "table" and (tonumber(info.ts) or 0) or 0)
        if age <= 7 * 86400 then
            local member = self.GetMember and self:GetMember(name) or nil
            if member and member.online then addonOnline = addonOnline + 1 end
        end
    end

    local latest = self.GetTrustedUpdateVersionR47 and self:GetTrustedUpdateVersionR47() or nil
    cached = { ts=now, queue=queue, queueCritical=queueCritical, queueNormal=queueNormal, queueBulk=queueBulk,
        perf=perf, worst=worst, worstName=worstName, addonOnline=addonOnline, updateVersion=latest }
    self.runtime.supportHealthSnapshotR50 = cached
    self.runtime.supportHealthBuildsR50 = (tonumber(self.runtime.supportHealthBuildsR50) or 0) + 1
    return cached
end

local function SupportHealthPieceR50(color, label, value)
    return tostring(color or "|cffaaaaaa") .. tostring(label or "") .. "|r  " .. tostring(value or "")
end

function OTLGM:GetSimpleSupportHealthR50()
    local snapshot = self:GetSupportHealthSnapshotR50(false)
    local performance, performanceColor = "Good", "|cff55cc66"
    if self.IsPerformanceGuardActive181 and self:IsPerformanceGuardActive181() then
        performance, performanceColor = "Protected", "|cffffcc55"
    elseif (tonumber(snapshot.worst) or 0) >= 150 then
        performance, performanceColor = "Watch", "|cffffcc55"
    elseif (tonumber(snapshot.worst) or 0) >= 50 then
        performance, performanceColor = "Observed", "|cffaaaaaa"
    end

    local criticalNormal = (tonumber(snapshot.queueCritical) or 0) + (tonumber(snapshot.queueNormal) or 0)
    local bulk = tonumber(snapshot.queueBulk) or 0
    local network, networkColor = "Healthy", "|cff55cc66"
    if criticalNormal > 0 then
        network, networkColor = "Busy", "|cffffcc55"
    elseif bulk > 0 then
        -- Bulk-only sharing is expected after roster/crafting/raid snapshots and
        -- must not look like a red connectivity failure to ordinary users.
        network, networkColor = "Syncing", bulk >= 100 and "|cffffcc55" or "|cffaaaaaa"
    end

    local version, versionColor = "Up to date", "|cff55cc66"
    if snapshot.updateVersion then version, versionColor = "Update available", "|cffffcc55" end
    return SupportHealthPieceR50(performanceColor, "Performance", performance)
        .. "    " .. SupportHealthPieceR50(networkColor, "Network", network)
        .. "    " .. SupportHealthPieceR50("|cff8fbbe8", "Sharing", tostring(snapshot.addonOnline or 0) .. " online")
        .. "    " .. SupportHealthPieceR50(versionColor, "Version", version)
end

function OTLGM:GetSupportCurrentStatusR33()
    self.runtime = self.runtime or {}
    local lines = {}
    local metrics = self.runtime.craftingMetrics180 or {}
    local captures = (tonumber(metrics.nativeEnchantEffectCaptures184) or 0)
        + (tonumber(metrics.visibleEnchantEffectCaptures184) or 0)
        + (tonumber(metrics.selectedEnchantEffectCapturesR24) or 0)
        + (tonumber(metrics.nativeEnchantDescriptionCapturesR43) or 0)
    -- Generic profession events legitimately probe the Craft/TradeSkill APIs
    -- while Cooking/Survival/etc. are open. Those "not-enchanting" exits are
    -- diagnostic noise, not a failed Enchanting verification. A native
    -- description attempt only occurs after a real Enchanting recipe resolves.
    local meaningfulEnchantAttempts = tonumber(metrics.nativeEnchantDescriptionAttemptsR43) or 0
    if captures > 0 then
        table.insert(lines, SupportStatusLineR33("|cff55cc66", "OK", "Enchanting exact-effect capture has succeeded this session (" .. tostring(captures) .. " capture signal(s))."))
    elseif meaningfulEnchantAttempts > 0 then
        local outcome = tostring(metrics.nativeEnchantDescriptionLastOutcomeR43 or "pending")
        table.insert(lines, SupportStatusLineR33("|cffffaa33", "WAIT", "Enchanting exact-effect capture was attempted " .. tostring(meaningfulEnchantAttempts) .. " time(s), but no exact effect was captured yet. Last result: " .. outcome .. "."))
    else
        table.insert(lines, SupportStatusLineR33("|cffaaaaaa", "CHECK", "Enchanting exact-effect capture has not been verified this session. Open native Enchanting, select an enchant, then open its OTL profession detail."))
    end

    local pendingReports = 0
    local guild = self.GetGuildDB and self:GetGuildDB() or nil
    local moderation = guild and guild.moderation183 or nil
    local ownReports = moderation and moderation.ownReports or nil
    if type(ownReports) == "table" then
        local terminal = { RESOLVED=true, NO_ACTION=true, REJECTED=true, DUPLICATE=true, ARCHIVED=true, WITHDRAWN=true }
        local _, report
        for _, report in pairs(ownReports) do
            if type(report) == "table" and not terminal[tostring(report.status or "NEW")]
                and (tostring(report.delivery or "PENDING") ~= "SUBMITTED" or report.withdrawPendingR30) then
                pendingReports = pendingReports + 1
            end
        end
    end
    if pendingReports > 0 then
        table.insert(lines, SupportStatusLineR33("|cffffaa33", "WAIT", tostring(pendingReports) .. " own report(s) are waiting for acknowledgement from another compatible Leadership client."))
    else
        table.insert(lines, SupportStatusLineR33("|cff55cc66", "OK", "No open own report is waiting for external Leadership acknowledgement."))
    end

    local healthR50 = self.GetSupportHealthSnapshotR50 and self:GetSupportHealthSnapshotR50(false) or {}
    local queue = tonumber(healthR50.queue) or 0
    local queueCritical = tonumber(healthR50.queueCritical) or 0
    local queueNormal = tonumber(healthR50.queueNormal) or 0
    local queueBulk = tonumber(healthR50.queueBulk) or 0
    local criticalNormal = queueCritical + queueNormal
    local worst = tonumber(healthR50.worst) or 0
    local worstName = tostring(healthR50.worstName or "none")
    if criticalNormal >= 50 or worst >= 150 then
        local detail = "Network queue " .. tostring(queue) .. " (" .. tostring(queueCritical) .. "/" .. tostring(queueNormal) .. "/" .. tostring(queueBulk) .. ")."
        if worst >= 150 then detail = detail .. " Recent severe addon operation: " .. worstName .. " " .. string.format("%.1f", worst) .. " ms." end
        table.insert(lines, SupportStatusLineR33("|cffffaa33", "WARN", detail .. " Use Clean Test if the problem is reproducible."))
    elseif queue > 0 or worst > 0 then
        local queueText = queueBulk > 0 and criticalNormal == 0 and ("bulk sync " .. tostring(queueBulk)) or ("queue " .. tostring(queue) .. " (" .. tostring(queueCritical) .. "/" .. tostring(queueNormal) .. "/" .. tostring(queueBulk) .. ")")
        table.insert(lines, SupportStatusLineR33("|cffaaaaaa", "INFO", "Network " .. queueText .. "; recent worst operation " .. (worst > 0 and (worstName .. " " .. string.format("%.1f", worst) .. " ms") or "none") .. "."))
    else
        table.insert(lines, SupportStatusLineR33("|cff55cc66", "OK", "Network queue is clear and no recent slow operation is recorded in the rolling window."))
    end

    local selfCheck = self.runtime.lastSupportSelfCheck181
    if selfCheck then
        local status = tostring(selfCheck.status or "?")
        local color = status == "PASS" and "|cff55cc66" or (status == "FAIL" and "|cffff6655" or "|cffffaa33")
        table.insert(lines, SupportStatusLineR33(color, status, "Self Check result: " .. tostring(selfCheck.fail or 0) .. " fail / " .. tostring(selfCheck.warn or 0) .. " warn. Run again after reproducing a problem."))
    else
        table.insert(lines, SupportStatusLineR33("|cffffcc55", "CHECK", "Self Check has not been run this login. Use Run Self Check for an immediate bounded health pass."))
    end
    return table.concat(lines, "\n")
end

function OTLGM:GetCompactSupportReportR32()
    local fps = "n/a"
    if GetFramerate then local ok, value = pcall(GetFramerate) if ok and tonumber(value) then fps = tostring(math.floor(tonumber(value) + 0.5)) end end
    local home, world = nil, nil
    if GetNetStats then local ok, bandwidthIn, bandwidthOut, h, w = pcall(GetNetStats) if ok then home, world = h, w end end
    local queueTotal, critical, normal, bulk = 0,0,0,0
    if self.GetNetworkQueueDepth then queueTotal, critical, normal, bulk = self:GetNetworkQueueDepth() end
    local rosterCount = 0
    if OTLGM_DB and OTLGM_DB.guilds then
        local guild = self.GetCurrentGuildDB and self:GetCurrentGuildDB() or nil
        if guild and guild.roster then for _ in pairs(guild.roster) do rosterCount = rosterCount + 1 end end
    end
    local compatibility = self.GetAddonCompatibilityWarningRC4 and self:GetAddonCompatibilityWarningRC4() or "no known version mismatch"
    local craftSummaryR32 = self.GetCraftingSummary and self:GetCraftingSummary() or {}
    local perf = self.PrunePerformanceDiagnostics180 and self:PrunePerformanceDiagnostics180(false) or {}
    local latest = perf and perf.latest or nil
    local zone = GetRealZoneText and GetRealZoneText() or (GetZoneText and GetZoneText() or "unknown")
    local subzone = GetSubZoneText and GetSubZoneText() or ""
    local lines = {
        "=== ORDER OF THE LION QUICK REPORT ===",
        "Version/build: " .. tostring(self.version or "?") .. " / " .. tostring(self.build or "?"),
        "Mode/page: " .. tostring(self.mode or "?") .. " / " .. tostring(self.ui and self.ui.currentPage or "closed"),
        "Zone: " .. tostring(zone or "unknown") .. (subzone ~= "" and (" / " .. tostring(subzone)) or ""),
        "FPS/latency: " .. tostring(fps) .. " / " .. tostring(home or "?") .. "/" .. tostring(world or "?") .. " ms",
        "Roster/network: " .. tostring(rosterCount) .. " members / queue " .. tostring(queueTotal) .. " (" .. tostring(critical) .. "/" .. tostring(normal) .. "/" .. tostring(bulk) .. ")",
        "Professions: " .. tostring(craftSummaryR32.characters or "?") .. " stored / " .. tostring(craftSummaryR32.recentCharacters or craftSummaryR32.characters or "?") .. " recent / " .. tostring(craftSummaryR32.uniqueRecipes or "?") .. " shared recipes",
        "Compatibility: " .. tostring(compatibility),
        "Self-check: " .. tostring(self.runtime and self.runtime.lastSupportSelfCheck181 and self.runtime.lastSupportSelfCheck181.status or "not run this login"),
        "Latest slow op: " .. tostring(latest and latest.label or "none") .. (latest and latest.ms and (" " .. string.format("%.1f", tonumber(latest.ms) or 0) .. " ms") or ""),
        "Schema/protocol: " .. tostring(self.schemaVersion or "?") .. "/" .. tostring(self.protocolVersion or "?"),
        "=== END QUICK REPORT ===",
    }
    return table.concat(lines, "\n")
end

local function BuildRecovery(owner, page)
    local panel = NewPanel(owner, page, "RECOVERY")
    owner.ui.settingsRecoveryPanel = panel
    local backup = UI:Card(panel, 452, 300, "Backup and Recovery")
    backup:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    backup.text = Label(backup, "Export a complete local backup before tests or recovery work. Import validates the payload before replacing stored data.", "GameFontNormal", 14, -42, 424, "LEFT")
    backup.text:SetHeight(70) backup.text:SetJustifyV("TOP")
    backup.export = UI:Button(backup, "Export Backup", 136, 32, function()
        local ok, value
        if owner.ExportBackupCheckedRC4 then ok, value = owner:ExportBackupCheckedRC4() else ok, value = true, owner:ExportBackup() end
        if ok then owner:ShowCopyDialog("Order of the Lion Backup", value) else owner:ShowToast("Backup export failed: " .. tostring(value), "error") end
    end, "primary")
    backup.export:SetPoint("TOPLEFT", backup, "TOPLEFT", 14, -130)
    backup.import = UI:Button(backup, "Import Backup", 136, 32, function() owner:OpenSettingsImport() end, "secondary")
    backup.import:SetPoint("LEFT", backup.export, "RIGHT", 8, 0)
    backup.weekly = UI:Button(backup, "Weekly Summary", 166, 32, function() owner:ShowCopyDialog("Weekly Guild Summary", owner:GenerateWeeklySummary()) end, "utility")
    backup.weekly:SetPoint("TOPLEFT", backup, "TOPLEFT", 14, -178)
    backup.restore = UI:Button(backup, "Create Restore Copy", 166, 32, function()
        local ok, value
        if owner.ExportBackupCheckedRC4 then ok, value = owner:ExportBackupCheckedRC4() else ok, value = true, owner:ExportBackup() end
        if ok then owner:ShowCopyDialog("Order of the Lion Restore Copy", value) else owner:ShowToast("Restore copy failed: " .. tostring(value), "error") end
    end, "utility")
    backup.restore:SetPoint("LEFT", backup.weekly, "RIGHT", 8, 0)
    backup.undo = UI:Button(backup, "Undo Last Import", 150, 28, function()
        owner:ShowConfirm("Undo Last Import?", "Restore the local data and settings that existed immediately before the most recent successful import in this login session?", "Undo Import", function()
            local ok, message = owner:UndoLastImportRC4()
            owner:ShowToast(message or (ok and "Import undone." or "Undo failed."), ok and "success" or "error")
            owner:RefreshSettingsPage()
        end)
    end, "utility")
    backup.undo:SetPoint("TOPLEFT", backup, "TOPLEFT", 14, -218)
    backup.status = Label(backup, "Restore copies are exported backups; imports can be undone during the same login session.", "GameFontNormalSmall", 174, -220, 264, "LEFT")
    backup.status:SetHeight(44) backup.status:SetJustifyV("TOP") backup.status:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    owner.ui.settingsBackupCard = backup

    local reset = UI:Card(panel, 468, 300, "Local Maintenance")
    reset:SetPoint("TOPLEFT", panel, "TOPLEFT", 464, 0)
    reset.text = Label(reset, "These actions affect only information saved by the addon on this computer. They never change the guild or server directly.", "GameFontNormal", 14, -42, 440, "LEFT")
    reset.text:SetHeight(60) reset.text:SetJustifyV("TOP")
    reset.window = UI:Button(reset, "Reset Window", 132, 32, function() owner:CenterWindow176() owner:ShowToast("Window position reset.", "success") end, "utility")
    reset.window:SetPoint("TOPLEFT", reset, "TOPLEFT", 14, -124)
    reset.clean = UI:Button(reset, "Compact Local Data", 152, 32, function()
        local preview = owner.GetLocalMaintenancePreviewRC4 and owner:GetLocalMaintenancePreviewRC4() or nil
        local detail = preview and preview.summary or "Remove old addon-user records and expired temporary data. Current guild records and known recipes are kept."
        owner:ShowConfirm("Compact Local Data?", detail, "Compact", function()
            local summary = owner.RunLocalMaintenanceRC3 and owner:RunLocalMaintenanceRC3() or nil
            if summary then
                owner:ShowToast("Local data cleaned. Removed " .. tostring(summary.presence or 0) .. " old addon-user records and cleared expired temporary data.", "success")
            else
                owner:ShowToast("Local maintenance completed.", "success")
            end
            if owner.RefreshSettingsPage then owner:RefreshSettingsPage() end
        end)
    end, "utility")
    reset.clean:SetPoint("LEFT", reset.window, "RIGHT", 8, 0)
    reset.data = UI:Button(reset, "Reset Guild Data", 152, 32, function()
        owner:ShowConfirm("Reset Local Guild Data?", "This removes saved roster history, shared addon information and analytics for the current guild. Export a backup first if you may need the data later.", "Reset Data", function() owner:ResetGuildData() owner:ShowToast("Local guild data reset.", "success") end)
    end, "danger")
    reset.data:SetPoint("TOPLEFT", reset, "TOPLEFT", 14, -178)
    reset.auto = AddCheck(reset, "Automatically clean old temporary addon data about once per week", -230, function() return OTLGM_DB.settings.autoMaintenance181 ~= false end, function(value)
        OTLGM_DB.settings.autoMaintenance181 = value
    end)
    owner.ui.settingsResetCard = reset
end

local function BuildAbout(owner, page)
    local panel = NewPanel(owner, page, "ABOUT")
    owner.ui.settingsAboutPanel = panel
    local about = UI:Card(panel, 932, 420, "About OrderOfTheLionGM")
    about:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    about.logo = about:CreateTexture(nil, "ARTWORK")
    about.logo:SetTexture("Interface\\Icons\\INV_Crown_01")
    about.logo:SetWidth(58) about.logo:SetHeight(58) about.logo:SetPoint("TOPLEFT", about, "TOPLEFT", 18, -44)
    about.title = Label(about, "Order of the Lion Guild Manager", "GameFontNormalLarge", 92, -48, 810, "LEFT")
    about.author = Label(about, "Created by Hikol • in game: Lucks", "GameFontNormal", 92, -78, 810, "LEFT")
    about.author:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    about.summary = Label(about, "A guild utility for roster work, native guild chat, professions, achievements, PvE coordination, treasury, activity and leadership tools on OctoWoW.", "GameFontNormal", 18, -132, 896, "LEFT")
    about.summary:SetHeight(72) about.summary:SetJustifyV("TOP")
    about.version = Label(about, "", "GameFontNormalSmall", 18, -218, 896, "LEFT")
    about.version:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    about.updateStatusR47 = Label(about, "", "GameFontNormalSmall", 18, -244, 896, "LEFT")
    about.updateStatusR47:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    about.about = UI:Button(about, "Project Information", 154, 30, function()
        owner:ShowNotice("About Order of the Lion", "Author: Hikol (Lucks)\nGuild: Order of the Lion\nRepository: Relyway/OrderOfTheLionGM\nVersion: " .. tostring(owner:GetPublicVersion180()))
    end, "secondary")
    about.about:SetPoint("TOPLEFT", about, "TOPLEFT", 18, -282)
    about.whatsNewR47 = UI:Button(about, "What's New", 124, 30, function()
        local title = "What's New"
        if owner.GetFriendlyVersionLabelR47 then title = title .. " — " .. tostring(owner:GetFriendlyVersionLabelR47(owner.version)) end
        local text = owner.GetWhatsNewTextR47 and owner:GetWhatsNewTextR47() or "Recent user-facing changes are included in the release notes."
        owner:ShowNotice(title, text)
        if OTLGM_DB and OTLGM_DB.settings then OTLGM_DB.settings.whatsNewSeenVersionR47 = tostring(owner.version or "") end
    end, "primary")
    about.whatsNewR47:SetPoint("LEFT", about.about, "RIGHT", 8, 0)
    about.diagnostics = UI:Button(about, "Support & Report", 142, 30, function() owner:OpenSupportCenterR59(false) end, "utility")
    about.diagnostics:SetPoint("LEFT", about.whatsNewR47, "RIGHT", 8, 0)
    owner.ui.settingsAboutCard = about
end

function OTLGM:GetR50FinishingDiagnostics()
    return "R50 finishing: treasury ledger builds/hits "
        .. tostring(self.runtime and self.runtime.treasuryLedgerBuildsR50 or 0) .. "/"
        .. tostring(self.runtime and self.runtime.treasuryLedgerCacheHitsR50 or 0)
        .. "; support health builds " .. tostring(self.runtime and self.runtime.supportHealthBuildsR50 or 0)
end

local PreviousSupportReportR50 = OTLGM.GetSupportReport181
if PreviousSupportReportR50 then
    function OTLGM:GetSupportReport181()
        local report = tostring(PreviousSupportReportR50(self) or "")
        local line = self:GetR50FinishingDiagnostics() .. "\n"
        local marker = "=== END SUPPORT REPORT ==="
        local markerAt = string.find(report, marker, 1, true)
        if markerAt then return string.sub(report, 1, markerAt - 1) .. line .. marker end
        return report .. "\n" .. line
    end
end

local function BuildSettings(owner, page)
    owner.ui.settingsPanels180 = {}
    owner.ui.settingsTabs180 = {}
    local x = 0
    local index
    for index = 1, table.getn(SETTINGS_TABS) do
        local captured = index
        local definition = SETTINGS_TABS[captured]
        local button = UI:Tab(page, definition[2], definition[3], function() owner:SetSettingsShellTab(definition[1]) end)
        button.otlQuietTabR29 = true
        button:SetPoint("TOPLEFT", page, "TOPLEFT", x, -4)
        owner.ui.settingsTabs180[definition[1]] = button
        x = x + definition[3] + 6
    end
    owner.ui.settingsInterfaceTab = owner.ui.settingsTabs180.INTERFACE
    owner.ui.settingsRecoveryTab = owner.ui.settingsTabs180.RECOVERY
    owner.ui.settingsSupportTabR32 = owner.ui.settingsTabs180.SUPPORT
    if owner.ui.settingsSupportTabR32 then owner.ui.settingsSupportTabR32.otlStyle = "tab" end
    BuildInterface(owner, page)
    BuildChat(owner, page)
    BuildNotifications(owner, page)
    BuildPve(owner, page)
    BuildNetwork(owner, page)
    BuildPerformance(owner, page)
    BuildSupport(owner, page)
    BuildRecovery(owner, page)
    BuildAbout(owner, page)
    owner.ui.settingsShellTab = OTLGM_DB.settings.settingsShellTab or "INTERFACE"
    owner:SetSettingsShellTab(owner.ui.settingsShellTab)
end

local function RefreshCheck(check)
    if check and check.otlGetter180 then UI:SetChecked(check, check.otlGetter180() and true or false) end
end

function OTLGM:RefreshSettingsPage(forceScopeR26)
    if not self.ui or not self.ui.settingsPanels180 then return end
    local tab = self.ui.settingsShellTab or "INTERFACE"
    local index
    for index = 1, table.getn(SETTINGS_TABS) do
        local key = SETTINGS_TABS[index][1]
        local panel = self.ui.settingsPanels180[key]
        if panel then if key == tab then panel:Show() else panel:Hide() end end
        UI:SetSelected(self.ui.settingsTabs180[key], key == tab)
    end

    -- r26: Settings used to repaint every hidden tab on every visible refresh.
    -- In a large guild the hidden Network diagnostics and Backup estimate are
    -- much more expensive than the Performance numbers the player is looking at.
    -- Refresh only the active tab; tab switches call this method after changing
    -- settingsShellTab, so hidden controls are still correct when they become visible.
    self.runtime = self.runtime or {}
    self.runtime.settingsRefreshMetricsR26 = self.runtime.settingsRefreshMetricsR26 or {}
    local refreshMetricsR26 = self.runtime.settingsRefreshMetricsR26
    refreshMetricsR26[tab] = (tonumber(refreshMetricsR26[tab]) or 0) + 1
    refreshMetricsR26.lastTab = tab
    refreshMetricsR26.lastAt = self:Now()

    if tab == "INTERFACE" then
        if self.ui.settingsScaleCard then
            local fitMode = OTLGM_DB.settings.uiScaleModeR2 == "FIT"
            for index = 1, table.getn(self.ui.settingsScaleCard.buttons) do
                local value = self.ui.settingsScaleCard.buttons[index].otlScale
                local selected = value == "FIT" and fitMode or (value ~= "FIT" and not fitMode and math.abs((OTLGM_DB.settings.uiScale or 1) - value) < 0.01)
                UI:SetSelected(self.ui.settingsScaleCard.buttons[index], selected)
            end
            local windowPreset = self.GetWindowSizePreset180 and self:GetWindowSizePreset180() or (OTLGM_DB.settings.windowSizePreset180 or "NORMAL")
            for index = 1, table.getn(self.ui.settingsScaleCard.windowButtons or {}) do
                UI:SetSelected(self.ui.settingsScaleCard.windowButtons[index], self.ui.settingsScaleCard.windowButtons[index].otlWindowPreset180 == windowPreset)
            end
            local requested = math.floor(((OTLGM_DB.settings.uiScale or 1) * 100) + 0.5)
            local effective = math.floor((((self.runtime and self.runtime.effectiveUIScale) or OTLGM_DB.settings.uiScale or 1) * 100) + 0.5)
            local frameWidth = self.ui.main and math.floor((self.ui.main:GetWidth() or 0) + 0.5) or 0
            local frameHeight = self.ui.main and math.floor((self.ui.main:GetHeight() or 0) + 0.5) or 0
            local limited = self.runtime and self.runtime.uiScaleLimited180
            local scaleText = fitMode and ("Fit to Screen: " .. tostring(effective) .. "%") or ("Preferred " .. tostring(requested) .. "% / effective " .. tostring(effective) .. "%")
            if limited then scaleText = scaleText .. " (limited by Fit mode)" end
            self.ui.settingsScaleCard.status:SetText(scaleText .. ". Window: " .. tostring(frameWidth) .. "x" .. tostring(frameHeight) .. " (" .. string.lower(tostring(windowPreset)) .. ").")
        end
        local options = self.ui.settingsOptionsCard
        if options then
            RefreshCheck(options.minimap) RefreshCheck(options.lock) RefreshCheck(options.home) RefreshCheck(options.help)
            RefreshCheck(options.keepInside) RefreshCheck(options.classColors) RefreshCheck(options.leadership)
            self.ui.settingsBehaviorCard.openText:SetText(OTLGM_DB.settings.openHome and "The addon opens Home each time. Disable this to return to the most recently used page." or "The addon returns to the most recently used page. Enable this to always start on Home.")
            local behavior = self.ui.settingsBehaviorCard
            RefreshCheck(behavior.quickDock) RefreshCheck(behavior.closeToDock) RefreshCheck(behavior.autoProfile183) RefreshCheck(behavior.socialGuild183)
            local mode = OTLGM_DB.settings.uiMode or "AUTO"
            for index = 1, table.getn(behavior.modeButtons or {}) do UI:SetSelected(behavior.modeButtons[index], behavior.modeButtons[index].otlMode180 == mode) end
            local interval = OTLGM_DB.settings.autoScan and (tonumber(OTLGM_DB.settings.scanInterval) or 1200) or 0
            for index = 1, table.getn(behavior.scanButtons or {}) do UI:SetSelected(behavior.scanButtons[index], behavior.scanButtons[index].otlInterval180 == interval) end
        end
        return
    end

    if tab == "CHAT" then
        if self.ui.settingsChatCard then
            RefreshCheck(self.ui.settingsChatCard.mentions) RefreshCheck(self.ui.settingsChatCard.separators)
            RefreshCheck(self.ui.settingsChatCard.ranks) RefreshCheck(self.ui.settingsChatCard.classColors)
            RefreshCheck(self.ui.settingsChatCard.leadership) RefreshCheck(self.ui.settingsSendingCard.scan)
            RefreshCheck(self.ui.settingsSendingCard.confirm)
        end
        return
    end

    if tab == "NOTIFICATIONS" then
        if self.ui.settingsNotificationsCard then
            for index = 1, table.getn(self.ui.settingsNotificationsCard.rows) do
                local row = self.ui.settingsNotificationsCard.rows[index]
                local pref = self:GetNotificationPreference152(row.otlCategory180)
                UI:SetChecked(row.visual, pref.visual and true or false)
                UI:SetChecked(row.sound, pref.sound and true or false)
                UI:SetText(row.choice, self:GetNotificationSoundLabel152(row.otlCategory180))
                UI:SetEnabled(row.choice, pref.sound and true or false, "Enable sound for this category first.")
            end
        end
        return
    end

    if tab == "PVE" then
        if self.ui.settingsPveOptionsCard then
            RefreshCheck(self.ui.settingsPveOptionsCard.popups) RefreshCheck(self.ui.settingsPveOptionsCard.chat)
            RefreshCheck(self.ui.settingsPveOptionsCard.matching) RefreshCheck(self.ui.settingsPveOptionsCard.craftable)
            RefreshCheck(self.ui.settingsPveOptionsCard.assignedRaid) RefreshCheck(self.ui.settingsPveOptionsCard.inviteStart)
        end
        return
    end

    if tab == "NETWORK" then
        if self.ui.settingsNetworkHealthCard then
            local nowR26 = self:Now()
            local cacheR26 = self.runtime.settingsNetworkSummaryR26
            local forceR26 = forceScopeR26 == "NETWORK" or forceScopeR26 == "ALL"
            if forceR26 or not cacheR26 or nowR26 - (tonumber(cacheR26.ts) or 0) >= 2 then
                local diagnostics
                if self.GetPreFinalHealthSummaryRC3 then
                    local health, healthDetail = "Unknown", ""
                    if self.GetSystemHealthRC4 then health, healthDetail = self:GetSystemHealthRC4() end
                    diagnostics = "SYSTEM HEALTH: " .. tostring(health) .. (healthDetail ~= "" and (" • " .. tostring(healthDetail)) or "") .. "\n" .. self:GetPreFinalHealthSummaryRC3()
                else
                    diagnostics = self.GetDiagnosticsText and self:GetDiagnosticsText() or "Diagnostics unavailable."
                end
                cacheR26 = { ts = nowR26, text = string.sub(tostring(diagnostics), 1, 1800) }
                self.runtime.settingsNetworkSummaryR26 = cacheR26
            end
            self.ui.settingsNetworkHealthCard.summary:SetText(cacheR26 and cacheR26.text or "Diagnostics unavailable.")
        end
        return
    end

    if tab == "PERFORMANCE" then
        if self.ui.settingsPerformanceGuardCard then
            local profile = OTLGM_DB.settings.performanceProfile181 or "AUTO"
            for index = 1, table.getn(self.ui.settingsPerformanceGuardCard.profileButtons or {}) do
                local button = self.ui.settingsPerformanceGuardCard.profileButtons[index]
                UI:SetSelected(button, button.otlPerformanceProfile181 == profile)
            end
            local motion = OTLGM_DB.settings.motionMode170 or "FULL"
            for index = 1, table.getn(self.ui.settingsPerformanceGuardCard.motionButtons or {}) do
                local button = self.ui.settingsPerformanceGuardCard.motionButtons[index]
                UI:SetSelected(button, button.otlMotionMode170 == motion)
            end
            RefreshCheck(self.ui.settingsPerformanceGuardCard.adaptive)
            RefreshCheck(self.ui.settingsPerformanceGuardCard.combat)
        end
        if self.ui.settingsPerformanceLiveCard then
            local scheduler = self.GetSchedulerDiagnostics180 and self:GetSchedulerDiagnostics180() or {}
            local roster = self.runtime and self.runtime.rosterMetrics180 or {}
            local fps
            if GetFramerate then local ok, value = pcall(GetFramerate) if ok then fps = tonumber(value) end end
            local transition = self.runtime and self.runtime.transitionActive176 and "active" or "idle"
            local pressure = self.GetClientPressure181 and self:GetClientPressure181() or { level=0, reason="normal", quietRemaining=0 }
            local guard = self.GetPerformanceGuardState181 and self:GetPerformanceGuardState181() or { active=false, remaining=0, count=0 }
            local queueTotal, critical, normal, bulk = 0, 0, 0, 0
            if self.GetNetworkQueueDepth then queueTotal, critical, normal, bulk = self:GetNetworkQueueDepth() end
            self.ui.settingsPerformanceLiveCard.summary:SetText(
                "CLIENT     FPS " .. tostring(fps and math.floor(fps + 0.5) or "n/a")
                .. "  •  profile " .. tostring(OTLGM_DB.settings.performanceProfile181 or "AUTO")
                .. "  •  guard " .. tostring(guard.active and ("ACTIVE " .. tostring(math.ceil(tonumber(guard.remaining) or 0)) .. "s") or "idle")
                .. "  •  pressure L" .. tostring(pressure.level or 0)
                .. (((tonumber(pressure.quietRemaining) or 0) > 0) and (" / quiet " .. tostring(math.ceil(pressure.quietRemaining)) .. "s") or "")
                .. "\nSCHEDULER  last/max " .. string.format("%.2f", tonumber(scheduler.lastSliceMs181) or 0) .. "/" .. string.format("%.2f", tonumber(scheduler.maxSliceMs181) or 0)
                .. " ms  •  yields " .. tostring(scheduler.budgetYields181 or 0)
                .. "  •  low-FPS/guard " .. tostring(scheduler.lowFpsSlices181 or 0) .. "/" .. tostring(scheduler.guardSlices181 or 0)
                .. "\nROSTER     last/max " .. string.format("%.2f", tonumber(roster.lastSliceMs) or 0) .. "/" .. string.format("%.2f", tonumber(roster.maxSliceMs181) or 0)
                .. " ms  •  rows " .. tostring(roster.lastSliceRows or 0)
                .. "  •  FPS " .. tostring(roster.lastSliceFps181 and math.floor(roster.lastSliceFps181 + 0.5) or "n/a")
                .. "\nNETWORK    queue " .. tostring(queueTotal or 0) .. " (" .. tostring(critical or 0) .. "/" .. tostring(normal or 0) .. "/" .. tostring(bulk or 0) .. ")"
                .. "  •  combat bulk " .. tostring(OTLGM_DB.settings.pauseBulkSyncInCombat ~= false and "paused" or "allowed")
                .. "  •  transition " .. tostring(transition)
            )
        end
        return
    end

    if tab == "SUPPORT" then
        if self.ui.settingsSupportReportsR32 and self.ui.settingsSupportReportsR32.intro then
            local incidentR59 = self.runtime and self.runtime.supportIncidentR59 or nil
            if incidentR59 then
                local countR59 = math.max(1, tonumber(incidentR59.count) or 1)
                self.ui.settingsSupportReportsR32.intro:SetText((incidentR59.severity == "ERROR" and "Addon problem detected" or "Repeated addon issue detected")
                    .. ": " .. tostring(incidentR59.source or "Addon") .. (countR59 > 1 and (" (x" .. tostring(countR59) .. ")") or "")
                    .. ". Copy Issue Report to prepare everything needed for a ticket; nothing is sent automatically.")
                if incidentR59.severity == "ERROR" then self.ui.settingsSupportReportsR32.intro:SetTextColor(C.red[1], C.red[2], C.red[3])
                else self.ui.settingsSupportReportsR32.intro:SetTextColor(C.orange[1], C.orange[2], C.orange[3]) end
            else
                self.ui.settingsSupportReportsR32.intro:SetText("If the addon is not working correctly, use Copy Issue Report first. It automatically attaches the useful build, page, incident, network, performance, sync and compatibility evidence. Nothing is sent automatically.")
                self.ui.settingsSupportReportsR32.intro:SetTextColor(C.white[1], C.white[2], C.white[3])
            end
        end
        if self.ui.settingsSupportCompatibilityR32 then
            if self.ui.settingsSupportCompatibilityR32.healthR50 and self.GetSimpleSupportHealthR50 then
                self.ui.settingsSupportCompatibilityR32.healthR50:SetText(self:GetSimpleSupportHealthR50())
            end
            if self.ui.settingsSupportCompatibilityR32.statusR33 and self.GetSupportCurrentStatusR33 then
                self.ui.settingsSupportCompatibilityR32.statusR33:SetText(self:GetSupportCurrentStatusR33())
            end
        end
        return
    end

    if tab == "RECOVERY" then
        if self.ui.settingsResetCard and self.ui.settingsResetCard.auto then RefreshCheck(self.ui.settingsResetCard.auto) end
        if self.ui.settingsBackupCard and self.ui.settingsBackupCard.status then
            local nowR26 = self:Now()
            local cacheR26 = self.runtime.settingsBackupEstimateR26
            local forceR26 = forceScopeR26 == "RECOVERY" or forceScopeR26 == "ALL"
            if forceR26 or not cacheR26 or nowR26 - (tonumber(cacheR26.ts) or 0) >= 5 then
                local estimate = self.EstimateLocalDataRC3 and self:EstimateLocalDataRC3(false) or nil
                local textR26 = "Restore copies are exported backups; they are never applied without validation and confirmation."
                if estimate then
                    local bytes = tonumber(estimate.bytes) or 0
                    local kb = math.floor(bytes / 1024)
                    local pct = math.floor((bytes / 2000000) * 100 + 0.5)
                    local warning = pct >= 85 and "  |cffffaa33Backup headroom is getting low.|r" or ""
                    if estimate.capped then warning = warning .. "  |cffffaa33Estimate capped; Export Backup is the authoritative check.|r" end
                    textR26 = "Approx. local data: " .. tostring(kb) .. " KB (" .. tostring(pct) .. "% of safe copy limit), " .. tostring(estimate.entries or 0) .. " entries." .. warning
                end
                cacheR26 = { ts = nowR26, text = textR26 }
                self.runtime.settingsBackupEstimateR26 = cacheR26
            end
            self.ui.settingsBackupCard.status:SetText(cacheR26.text)
            if self.ui.settingsBackupCard.undo then UI:SetEnabled(self.ui.settingsBackupCard.undo, self.CanUndoLastImportRC4 and self:CanUndoLastImportRC4() or false, "No successful import has been performed during this login session.") end
        end
        return
    end

    if tab == "ABOUT" and self.ui.settingsAboutCard then
        local about = self.ui.settingsAboutCard
        local currentLabel = self.GetFriendlyVersionLabelR47 and self:GetFriendlyVersionLabelR47(self.version) or tostring(self:GetPublicVersion180())
        about.version:SetText("Version " .. tostring(currentLabel) .. "  •  Build " .. tostring(self.build or ""))
        if about.updateStatusR47 then
            local latest, evidence = nil, nil
            if self.GetTrustedUpdateVersionR47 then latest, evidence = self:GetTrustedUpdateVersionR47() end
            if latest and self.IsVersionNewer and self:IsVersionNewer(latest, self.version) then
                local label = self.GetFriendlyVersionLabelR47 and self:GetFriendlyVersionLabelR47(latest) or tostring(latest)
                local source = evidence and evidence.sourceLabel or "confirmed by guild clients"
                about.updateStatusR47:SetText("|cffffcc55Update available: " .. tostring(label) .. "|r  •  " .. tostring(source))
            else
                about.updateStatusR47:SetText("|cff69cc73Up to date|r  •  No trusted newer guild version is currently known.")
            end
        end
    end
end

local function LayoutSettings(owner, page, width, height)
    local panelHeight = math.max(512, height - 44)
    local gap = 12
    local leftWidth = math.floor((width - gap) / 2)
    local rightWidth = width - leftWidth - gap
    local key, panel
    for key, panel in pairs(owner.ui.settingsPanels180 or {}) do panel:SetWidth(width) panel:SetHeight(panelHeight) end

    local scale = owner.ui.settingsScaleCard
    scale:SetWidth(width)
    scale.status:SetWidth(width - 28)
    if scale.scaleLabel then scale.scaleLabel:SetWidth(width - 28) end
    if scale.windowLabel then scale.windowLabel:SetWidth(width - 28) end
    local buttonGap = 8
    local buttonWidth = math.max(86, math.floor((width - 28 - (buttonGap * 4)) / 5))
    local index
    for index = 1, table.getn(scale.buttons or {}) do
        local button = scale.buttons[index]
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", scale, "TOPLEFT", 14 + ((index - 1) * (buttonWidth + buttonGap)), -48)
        button:SetWidth(buttonWidth)
        if button.text then button.text:SetWidth(math.max(40, buttonWidth - 10)) end
    end
    for index = 1, table.getn(scale.windowButtons or {}) do
        local button = scale.windowButtons[index]
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", scale, "TOPLEFT", 14 + ((index - 1) * (buttonWidth + buttonGap)), -104)
        button:SetWidth(buttonWidth)
        if button.text then button.text:SetWidth(math.max(40, buttonWidth - 10)) end
    end

    owner.ui.settingsOptionsCard:SetWidth(leftWidth)
    owner.ui.settingsOptionsCard:ClearAllPoints()
    owner.ui.settingsOptionsCard:SetPoint("TOPLEFT", owner.ui.settingsInterfacePanel, "TOPLEFT", 0, -182)
    owner.ui.settingsBehaviorCard:ClearAllPoints()
    owner.ui.settingsBehaviorCard:SetPoint("TOPRIGHT", owner.ui.settingsInterfacePanel, "TOPRIGHT", 0, -182)
    owner.ui.settingsBehaviorCard:SetWidth(rightWidth)
    local checks = {
        owner.ui.settingsOptionsCard.minimap, owner.ui.settingsOptionsCard.lock, owner.ui.settingsOptionsCard.home,
        owner.ui.settingsOptionsCard.help, owner.ui.settingsOptionsCard.keepInside, owner.ui.settingsOptionsCard.classColors,
        owner.ui.settingsOptionsCard.leadership,
    }
    for index = 1, table.getn(checks) do
        if checks[index] then
            checks[index]:SetWidth(math.max(200, leftWidth - 28))
            if checks[index].text then checks[index].text:SetWidth(math.max(150, leftWidth - 62)) end
        end
    end
    owner.ui.settingsBehaviorCard.modeLabel:SetWidth(rightWidth - 28)
    owner.ui.settingsBehaviorCard.scanLabel:SetWidth(rightWidth - 28)
    owner.ui.settingsBehaviorCard.openText:SetWidth(rightWidth - 28)
    if owner.ui.settingsBehaviorCard.visibilityText then owner.ui.settingsBehaviorCard.visibilityText:SetWidth(rightWidth - 28) end
    local behaviorChecks183 = {
        owner.ui.settingsBehaviorCard.quickDock, owner.ui.settingsBehaviorCard.closeToDock,
        owner.ui.settingsBehaviorCard.autoProfile183,
    }
    for index = 1, table.getn(behaviorChecks183) do
        local check = behaviorChecks183[index]
        if check then
            check:SetWidth(math.max(200, rightWidth - 28))
            if check.text then check.text:SetWidth(math.max(150, rightWidth - 62)) end
        end
    end
    local modeWidth = math.max(82, math.floor((rightWidth - 44) / 3))
    for index = 1, table.getn(owner.ui.settingsBehaviorCard.modeButtons or {}) do
        local button = owner.ui.settingsBehaviorCard.modeButtons[index]
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", owner.ui.settingsBehaviorCard, "TOPLEFT", 14 + ((index - 1) * (modeWidth + 8)), -58)
        button:SetWidth(modeWidth)
        if button.text then button.text:SetWidth(math.max(40, modeWidth - 10)) end
    end
    local scanWidth = math.max(48, math.floor((rightWidth - 60) / 5))
    for index = 1, table.getn(owner.ui.settingsBehaviorCard.scanButtons or {}) do
        local button = owner.ui.settingsBehaviorCard.scanButtons[index]
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", owner.ui.settingsBehaviorCard, "TOPLEFT", 14 + ((index - 1) * (scanWidth + 6)), -126)
        button:SetWidth(scanWidth)
        if button.text then button.text:SetWidth(math.max(28, scanWidth - 8)) end
    end

    owner.ui.settingsChatCard:SetWidth(leftWidth)
    owner.ui.settingsSendingCard:ClearAllPoints()
    owner.ui.settingsSendingCard:SetPoint("TOPRIGHT", owner.ui.settingsChatPanel, "TOPRIGHT", 0, 0)
    owner.ui.settingsSendingCard:SetWidth(rightWidth)
    local chatChecks = {
        owner.ui.settingsChatCard.mentions, owner.ui.settingsChatCard.separators, owner.ui.settingsChatCard.ranks,
        owner.ui.settingsChatCard.classColors, owner.ui.settingsChatCard.leadership,
    }
    for index = 1, table.getn(chatChecks) do
        if chatChecks[index] then
            chatChecks[index]:SetWidth(leftWidth - 28)
            if chatChecks[index].text then chatChecks[index].text:SetWidth(leftWidth - 62) end
        end
    end
    if owner.ui.settingsChatCard.help then owner.ui.settingsChatCard.help:SetWidth(leftWidth - 28) end
    local sendingChecks = { owner.ui.settingsSendingCard.scan, owner.ui.settingsSendingCard.confirm }
    for index = 1, table.getn(sendingChecks) do
        if sendingChecks[index] then
            sendingChecks[index]:SetWidth(rightWidth - 28)
            if sendingChecks[index].text then sendingChecks[index].text:SetWidth(rightWidth - 62) end
        end
    end
    if owner.ui.settingsSendingCard.help then owner.ui.settingsSendingCard.help:SetWidth(rightWidth - 28) end

    owner.ui.settingsNotificationsCard:SetWidth(width)
    owner.ui.settingsNotificationsCard.intro:SetWidth(width - 28)
    for index = 1, table.getn(owner.ui.settingsNotificationsCard.rows) do
        local row = owner.ui.settingsNotificationsCard.rows[index]
        local rowWidth = math.max(420, width - 28)
        row:SetWidth(rowWidth)
        -- Notification controls used fixed 1.7.x X offsets. At the compact
        -- 1.8 workspace those offsets made Sound overlap the selector. Keep
        -- the row semantic order but derive every region from available width.
        local choiceWidth = math.max(118, math.min(154, math.floor(rowWidth * 0.20)))
        local checkWidth = math.max(92, math.min(112, math.floor(rowWidth * 0.15)))
        local controlsWidth = choiceWidth + (checkWidth * 2) + 24
        local titleWidth = math.max(150, rowWidth - controlsWidth - 30)
        row.title:SetWidth(titleWidth)
        row.visual:ClearAllPoints()
        row.visual:SetPoint("TOPLEFT", row, "TOPLEFT", 18 + titleWidth, -10)
        row.visual:SetWidth(checkWidth)
        if row.visual.text then row.visual.text:SetWidth(math.max(54, checkWidth - 30)) end
        row.sound:ClearAllPoints()
        row.sound:SetPoint("LEFT", row.visual, "RIGHT", 6, 0)
        row.sound:SetWidth(checkWidth)
        if row.sound.text then row.sound.text:SetWidth(math.max(54, checkWidth - 30)) end
        row.choice:ClearAllPoints()
        row.choice:SetPoint("TOPRIGHT", row, "TOPRIGHT", -12, -12)
        row.choice:SetWidth(choiceWidth)
        if row.choice.text then row.choice.text:SetWidth(math.max(70, choiceWidth - 10)) end
    end

    owner.ui.settingsPveOptionsCard:SetWidth(leftWidth)
    owner.ui.settingsPveDataCard:ClearAllPoints()
    owner.ui.settingsPveDataCard:SetPoint("TOPRIGHT", owner.ui.settingsPvePanel, "TOPRIGHT", 0, 0)
    owner.ui.settingsPveDataCard:SetWidth(rightWidth)
    local pveChecks = {
        owner.ui.settingsPveOptionsCard.popups, owner.ui.settingsPveOptionsCard.chat, owner.ui.settingsPveOptionsCard.matching,
        owner.ui.settingsPveOptionsCard.craftable, owner.ui.settingsPveOptionsCard.assignedRaid, owner.ui.settingsPveOptionsCard.inviteStart,
    }
    for index = 1, table.getn(pveChecks) do
        if pveChecks[index] then
            pveChecks[index]:SetWidth(leftWidth - 28)
            if pveChecks[index].text then pveChecks[index].text:SetWidth(leftWidth - 62) end
        end
    end
    owner.ui.settingsPveOptionsCard.info:SetWidth(leftWidth - 28)
    owner.ui.settingsPveDataCard.info:SetWidth(rightWidth - 28)

    owner.ui.settingsNetworkHealthCard:SetWidth(width)
    owner.ui.settingsNetworkHealthCard.summary:SetWidth(width - 28)
    owner.ui.settingsNetworkSyncCard:SetWidth(width)
    owner.ui.settingsNetworkSyncCard.info:SetWidth(width - 28)

    if owner.ui.settingsPerformanceGuardCard then
        owner.ui.settingsPerformanceGuardCard:SetWidth(width)
        owner.ui.settingsPerformanceGuardCard.profileLabel:SetWidth(width - 28)
        owner.ui.settingsPerformanceGuardCard.motionLabel:SetWidth(width - 28)
        owner.ui.settingsPerformanceGuardCard.profileHelp:SetWidth(math.max(220, width - 500))
        owner.ui.settingsPerformanceGuardCard.motionHelp:SetWidth(math.max(260, width - 404))
        local performanceChecks = { owner.ui.settingsPerformanceGuardCard.adaptive, owner.ui.settingsPerformanceGuardCard.combat }
        for checkIndex = 1, table.getn(performanceChecks) do
            local check = performanceChecks[checkIndex]
            if check then
                check:SetWidth(width - 28)
                if check.text then check.text:SetWidth(math.max(200, width - 62)) end
            end
        end
        owner.ui.settingsPerformanceGuardCard.note:SetWidth(math.max(320, width - 210))
        owner.ui.settingsPerformanceLiveCard:SetWidth(width)
        owner.ui.settingsPerformanceLiveCard.summary:SetWidth(width - 28)
    end

    owner.ui.settingsBackupCard:SetWidth(leftWidth)
    owner.ui.settingsBackupCard.text:SetWidth(leftWidth - 28)
    owner.ui.settingsBackupCard.status:SetWidth(math.max(120, leftWidth - 188))
    owner.ui.settingsResetCard:ClearAllPoints()
    owner.ui.settingsResetCard:SetPoint("TOPRIGHT", owner.ui.settingsRecoveryPanel, "TOPRIGHT", 0, 0)
    owner.ui.settingsResetCard:SetWidth(rightWidth)
    owner.ui.settingsResetCard.text:SetWidth(rightWidth - 28)

    if owner.ui.settingsSupportReportsR32 then
        owner.ui.settingsSupportReportsR32:SetWidth(width)
        owner.ui.settingsSupportReportsR32.intro:SetWidth(width - 36)
        owner.ui.settingsSupportReportsR32.note:SetWidth(width - 36)
    end
    if owner.ui.settingsSupportCompatibilityR32 then
        owner.ui.settingsSupportCompatibilityR32:SetWidth(width)
        if owner.ui.settingsSupportCompatibilityR32.healthR50 then owner.ui.settingsSupportCompatibilityR32.healthR50:SetWidth(width - 36) end
        if owner.ui.settingsSupportCompatibilityR32.statusR33 then owner.ui.settingsSupportCompatibilityR32.statusR33:SetWidth(width - 36) end
        if owner.ui.settingsSupportCompatibilityR32.guidanceR33 then owner.ui.settingsSupportCompatibilityR32.guidanceR33:SetWidth(width - 36) end
    end

    owner.ui.settingsAboutCard:SetWidth(width)
    owner.ui.settingsAboutCard.title:SetWidth(width - 110)
    owner.ui.settingsAboutCard.author:SetWidth(width - 110)
    owner.ui.settingsAboutCard.summary:SetWidth(width - 36)
    owner.ui.settingsAboutCard.version:SetWidth(width - 36)
    page.otlNativeLayout = true
end

OTLGM:CreateShellPageModule180("settings", BuildSettings,
    function(owner) owner:RefreshSettingsPage() end,
    LayoutSettings, { "interface", "guild-chat", "notifications", "pve", "network", "performance", "backup", "about" }, { width = 760, height = 520 })

OTLGM:RegisterModule("SettingsPage180", {
    stage = "B",
    revision = 12,
    lazy = true,
    migrated = true,
    nativeContentHost = true,
    pageContract = true,
    parity176 = true,
    noOnUpdate = true,
})
