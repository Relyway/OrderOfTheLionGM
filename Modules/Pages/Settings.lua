-- Order of the Lion Guild Manager 1.8.0 alpha2 shell r8
-- Native Settings with 1.7.6 functional parity inside the Stage B shell.

if not OTLGM or not OTLGM.UI then return end

local UI = OTLGM.UI
local C = UI.colors

local SETTINGS_TABS = {
    { "INTERFACE", "Interface", 100 },
    { "CHAT", "Guild Chat", 104 },
    { "NOTIFICATIONS", "Notifications", 116 },
    { "PVE", "PvE Hub", 92 },
    { "NETWORK", "Network", 94 },
    { "RECOVERY", "Backup", 92 },
    { "ABOUT", "About", 82 },
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
    modal.help = Label(modal, "Paste a complete OTLGM backup below. Guild, realm, schema and checksum checks run before any stored data is replaced.", "GameFontNormalSmall", 20, -50, 680, "LEFT")
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
    self.ui.settingsImportModal.edit:SetFocus()
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

    local behavior = UI:Card(panel, 468, 330, "Workspace and Roster")
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
    behavior.visibilityText = Label(behavior, "Park creates the crest restore control only while parked. Window geometry and clamping survive /reload.", "GameFontNormalSmall", 14, -210, 430, "LEFT")
    behavior.visibilityText:SetHeight(42) behavior.visibilityText:SetJustifyV("TOP") behavior.visibilityText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    behavior.home = UI:Button(behavior, "Open Home", 122, 30, function() owner:ShowPage("home") end, "primary")
    behavior.home:SetPoint("BOTTOMLEFT", behavior, "BOTTOMLEFT", 14, 16)
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
    card.intro = Label(card, "Visual alerts and sounds are controlled independently. Background sync and ordinary cache refreshes stay quiet.", "GameFontNormalSmall", 14, -38, 900, "LEFT")
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
    network.info = Label(network, "Groups, applications and raid alerts travel between online guildmates with the addon. Sync success is shown only after an acknowledgement or actual data response.", "GameFontNormalSmall", 14, -44, 438, "LEFT")
    network.info:SetHeight(92) network.info:SetJustifyV("TOP") network.info:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    network.sync = UI:Button(network, "Sync PvE Hub Now", 166, 30, function()
        if owner:RequestPveSync(true) then owner:ShowToast("PvE synchronization requested.", "pending") end
    end, "utility")
    network.sync:SetPoint("TOPLEFT", network, "TOPLEFT", 14, -160)
    network.clear = UI:Button(network, "Clear Local PvE Cache", 174, 30, function()
        owner:ShowConfirm("Clear Local PvE Cache", "Remove locally stored groups, applications, raid alerts and board cache? Current data can be requested again from online addon users.", "Clear", function()
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
    local health = UI:Card(panel, 932, 350, "Network and Diagnostics")
    health:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    health.summary = Label(health, "", "GameFontNormalSmall", 14, -42, 900, "LEFT")
    health.summary:SetHeight(210) health.summary:SetJustifyV("TOP") health.summary:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    health.copy = UI:Button(health, "Copy Diagnostics", 148, 30, function() owner:ShowCopyDialog("Order of the Lion Diagnostics", owner:GetDiagnosticsText()) end, "primary")
    health.copy:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT", 14, 18)
    health.users = UI:Button(health, "Check Addon Users", 154, 30, function() owner:ToggleAddonUsersDrawer() end, "secondary")
    health.users:SetPoint("LEFT", health.copy, "RIGHT", 8, 0)
    health.version = UI:Button(health, "Broadcast Version", 148, 30, function() if owner.BroadcastVersion then owner:BroadcastVersion() end end, "utility")
    health.version:SetPoint("LEFT", health.users, "RIGHT", 8, 0)

    local sync = UI:Card(panel, 932, 140, "Manual Synchronization")
    sync:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -362)
    sync.pve = UI:Button(sync, "PvE Hub", 126, 30, function() owner:RequestPveSync(true) end, "utility")
    sync.pve:SetPoint("TOPLEFT", sync, "TOPLEFT", 14, -48)
    sync.crafting = UI:Button(sync, "Professions", 126, 30, function()
        if owner:RequestCraftingSync(true, true) and owner.ShowToast then owner:ShowToast("Synchronizing professions…", "pending") end
    end, "utility")
    sync.crafting:SetPoint("LEFT", sync.pve, "RIGHT", 8, 0)
    sync.posts = UI:Button(sync, "Guild Posts", 126, 30, function() owner:RequestAnnouncementSync152(true) end, "utility")
    sync.posts:SetPoint("LEFT", sync.crafting, "RIGHT", 8, 0)
    sync.info = Label(sync, "Manual sync is available for recovery and testing; normal page switching does not start network requests.", "GameFontNormalSmall", 14, -94, 900, "LEFT")
    sync.info:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    owner.ui.settingsNetworkHealthCard = health
    owner.ui.settingsNetworkSyncCard = sync
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
    backup.weekly = UI:Button(backup, "Copy Weekly Summary", 166, 32, function() owner:ShowCopyDialog("Weekly Guild Summary", owner:GenerateWeeklySummary()) end, "utility")
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
    reset.text = Label(reset, "These actions affect only SavedVariables. They never change the guild or server data directly.", "GameFontNormal", 14, -42, 440, "LEFT")
    reset.text:SetHeight(60) reset.text:SetJustifyV("TOP")
    reset.window = UI:Button(reset, "Reset Window", 132, 32, function() owner:CenterWindow176() owner:ShowToast("Window position reset.", "success") end, "utility")
    reset.window:SetPoint("TOPLEFT", reset, "TOPLEFT", 14, -124)
    reset.clean = UI:Button(reset, "Compact Local Data", 152, 32, function()
        local preview = owner.GetLocalMaintenancePreviewRC4 and owner:GetLocalMaintenancePreviewRC4() or nil
        local detail = preview and preview.summary or "Prune old presence records and expired local caches. Current guild records and known recipes are preserved."
        owner:ShowConfirm("Compact Local Data?", detail, "Compact", function()
            local summary = owner.RunLocalMaintenanceRC3 and owner:RunLocalMaintenanceRC3() or nil
            if summary then
                owner:ShowToast("Local data compacted. Removed " .. tostring(summary.presence or 0) .. " old presence records and pruned expired caches.", "success")
            else
                owner:ShowToast("Local maintenance completed.", "success")
            end
            if owner.RefreshSettingsPage then owner:RefreshSettingsPage() end
        end)
    end, "utility")
    reset.clean:SetPoint("LEFT", reset.window, "RIGHT", 8, 0)
    reset.data = UI:Button(reset, "Reset Guild Data", 152, 32, function()
        owner:ShowConfirm("Reset Local Guild Data?", "This removes local roster history, cached shared data and analytics for the current guild. Export a backup first if you may need the data later.", "Reset Data", function() owner:ResetGuildData() owner:ShowToast("Local guild data reset.", "success") end)
    end, "danger")
    reset.data:SetPoint("TOPLEFT", reset, "TOPLEFT", 14, -178)
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
    about.author = Label(about, "Created by Hikol • in game: Lucks / Morrow", "GameFontNormal", 92, -78, 810, "LEFT")
    about.author:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    about.summary = Label(about, "A guild utility for roster work, native guild chat, professions, achievements, PvE coordination, treasury, activity and leadership tools on OctoWoW.", "GameFontNormal", 18, -132, 896, "LEFT")
    about.summary:SetHeight(72) about.summary:SetJustifyV("TOP")
    about.version = Label(about, "", "GameFontNormalSmall", 18, -224, 896, "LEFT")
    about.version:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    about.about = UI:Button(about, "Project Information", 154, 30, function()
        owner:ShowNotice("About Order of the Lion", "Author: Hikol (Lucks / Morrow)\nGuild: Order of the Lion\nRepository: Relyway/OrderOfTheLionGM\nVersion: " .. tostring(owner:GetPublicVersion180()))
    end, "secondary")
    about.about:SetPoint("TOPLEFT", about, "TOPLEFT", 18, -282)
    about.diagnostics = UI:Button(about, "Copy Diagnostics", 148, 30, function() owner:ShowCopyDialog("Order of the Lion Diagnostics", owner:GetDiagnosticsText()) end, "utility")
    about.diagnostics:SetPoint("LEFT", about.about, "RIGHT", 8, 0)
    owner.ui.settingsAboutCard = about
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
        button:SetPoint("TOPLEFT", page, "TOPLEFT", x, -4)
        owner.ui.settingsTabs180[definition[1]] = button
        x = x + definition[3] + 6
    end
    owner.ui.settingsInterfaceTab = owner.ui.settingsTabs180.INTERFACE
    owner.ui.settingsRecoveryTab = owner.ui.settingsTabs180.RECOVERY
    BuildInterface(owner, page)
    BuildChat(owner, page)
    BuildNotifications(owner, page)
    BuildPve(owner, page)
    BuildNetwork(owner, page)
    BuildRecovery(owner, page)
    BuildAbout(owner, page)
    owner.ui.settingsShellTab = OTLGM_DB.settings.settingsShellTab or "INTERFACE"
    owner:SetSettingsShellTab(owner.ui.settingsShellTab)
end

local function RefreshCheck(check)
    if check and check.otlGetter180 then UI:SetChecked(check, check.otlGetter180() and true or false) end
end

function OTLGM:RefreshSettingsPage()
    if not self.ui or not self.ui.settingsPanels180 then return end
    local tab = self.ui.settingsShellTab or "INTERFACE"
    local index
    for index = 1, table.getn(SETTINGS_TABS) do
        local key = SETTINGS_TABS[index][1]
        local panel = self.ui.settingsPanels180[key]
        if panel then if key == tab then panel:Show() else panel:Hide() end end
        UI:SetSelected(self.ui.settingsTabs180[key], key == tab)
    end
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
        local limitedReason = self.runtime and self.runtime.uiScaleLimitedReason180
        local scaleText = fitMode and ("Fit to Screen: " .. tostring(effective) .. "%") or ("Preferred " .. tostring(requested) .. "% / effective " .. tostring(effective) .. "%")
        if limited then
            scaleText = scaleText .. " (limited by Fit mode)"
        end
        self.ui.settingsScaleCard.status:SetText(scaleText .. ". Window: " .. tostring(frameWidth) .. "x" .. tostring(frameHeight) .. " (" .. string.lower(tostring(windowPreset)) .. ").")
    end
    local options = self.ui.settingsOptionsCard
    if options then
        RefreshCheck(options.minimap) RefreshCheck(options.lock) RefreshCheck(options.home) RefreshCheck(options.help)
        RefreshCheck(options.keepInside) RefreshCheck(options.classColors) RefreshCheck(options.leadership)
        self.ui.settingsBehaviorCard.openText:SetText(OTLGM_DB.settings.openHome and "The addon opens Home each time. Disable this to return to the most recently used page." or "The addon returns to the most recently used page. Enable this to always start on Home.")
        local behavior = self.ui.settingsBehaviorCard
        local mode = OTLGM_DB.settings.uiMode or "AUTO"
        for index = 1, table.getn(behavior.modeButtons or {}) do UI:SetSelected(behavior.modeButtons[index], behavior.modeButtons[index].otlMode180 == mode) end
        local interval = OTLGM_DB.settings.autoScan and (tonumber(OTLGM_DB.settings.scanInterval) or 1200) or 0
        for index = 1, table.getn(behavior.scanButtons or {}) do UI:SetSelected(behavior.scanButtons[index], behavior.scanButtons[index].otlInterval180 == interval) end
    end
    if self.ui.settingsChatCard then
        RefreshCheck(self.ui.settingsChatCard.mentions) RefreshCheck(self.ui.settingsChatCard.separators)
        RefreshCheck(self.ui.settingsChatCard.ranks) RefreshCheck(self.ui.settingsChatCard.classColors)
        RefreshCheck(self.ui.settingsChatCard.leadership) RefreshCheck(self.ui.settingsSendingCard.scan)
        RefreshCheck(self.ui.settingsSendingCard.confirm)
    end
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
    if self.ui.settingsPveOptionsCard then
        RefreshCheck(self.ui.settingsPveOptionsCard.popups) RefreshCheck(self.ui.settingsPveOptionsCard.chat)
        RefreshCheck(self.ui.settingsPveOptionsCard.matching) RefreshCheck(self.ui.settingsPveOptionsCard.craftable)
        RefreshCheck(self.ui.settingsPveOptionsCard.assignedRaid) RefreshCheck(self.ui.settingsPveOptionsCard.inviteStart)
    end
    if self.ui.settingsNetworkHealthCard then
        local diagnostics
        if self.GetPreFinalHealthSummaryRC3 then
            local health, healthDetail = "Unknown", ""
            if self.GetSystemHealthRC4 then health, healthDetail = self:GetSystemHealthRC4() end
            diagnostics = "SYSTEM HEALTH: " .. tostring(health) .. (healthDetail ~= "" and (" • " .. tostring(healthDetail)) or "") .. "\n" .. self:GetPreFinalHealthSummaryRC3()
        else
            diagnostics = self.GetDiagnosticsText and self:GetDiagnosticsText() or "Diagnostics unavailable."
        end
        self.ui.settingsNetworkHealthCard.summary:SetText(string.sub(tostring(diagnostics), 1, 1800))
    end
    if self.ui.settingsBackupCard and self.ui.settingsBackupCard.status then
        local estimate = self.EstimateLocalDataRC3 and self:EstimateLocalDataRC3(false) or nil
        if estimate then
            local bytes = tonumber(estimate.bytes) or 0
            local kb = math.floor(bytes / 1024)
            local pct = math.floor((bytes / 2000000) * 100 + 0.5)
            local warning = pct >= 85 and "  |cffffaa33Backup headroom is getting low.|r" or ""
            if estimate.capped then warning = warning .. "  |cffffaa33Estimate capped; Export Backup is the authoritative check.|r" end
            self.ui.settingsBackupCard.status:SetText("Approx. local data: " .. tostring(kb) .. " KB (" .. tostring(pct) .. "% of safe copy limit), " .. tostring(estimate.entries or 0) .. " entries." .. warning)
        else
            self.ui.settingsBackupCard.status:SetText("Restore copies are exported backups; they are never applied without validation and confirmation.")
        end
        if self.ui.settingsBackupCard.undo then UI:SetEnabled(self.ui.settingsBackupCard.undo, self.CanUndoLastImportRC4 and self:CanUndoLastImportRC4() or false, "No successful import has been performed during this login session.") end
    end
    if self.ui.settingsAboutCard then
        self.ui.settingsAboutCard.version:SetText("Version " .. tostring(self:GetPublicVersion180()) .. "  •  Build " .. tostring(self.build or "") .. "  •  Local schema " .. tostring(self.schemaVersion or ""))
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
    owner.ui.settingsBehaviorCard.visibilityText:SetWidth(rightWidth - 28)
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

    owner.ui.settingsBackupCard:SetWidth(leftWidth)
    owner.ui.settingsBackupCard.text:SetWidth(leftWidth - 28)
    owner.ui.settingsBackupCard.status:SetWidth(math.max(120, leftWidth - 188))
    owner.ui.settingsResetCard:ClearAllPoints()
    owner.ui.settingsResetCard:SetPoint("TOPRIGHT", owner.ui.settingsRecoveryPanel, "TOPRIGHT", 0, 0)
    owner.ui.settingsResetCard:SetWidth(rightWidth)
    owner.ui.settingsResetCard.text:SetWidth(rightWidth - 28)

    owner.ui.settingsAboutCard:SetWidth(width)
    owner.ui.settingsAboutCard.title:SetWidth(width - 110)
    owner.ui.settingsAboutCard.author:SetWidth(width - 110)
    owner.ui.settingsAboutCard.summary:SetWidth(width - 36)
    owner.ui.settingsAboutCard.version:SetWidth(width - 36)
    page.otlNativeLayout = true
end

OTLGM:CreateShellPageModule180("settings", BuildSettings,
    function(owner) owner:RefreshSettingsPage() end,
    LayoutSettings, { "interface", "guild-chat", "notifications", "pve", "network", "backup", "about" }, { width = 760, height = 520 })

OTLGM:RegisterModule("SettingsPage180", {
    stage = "B",
    revision = 9,
    lazy = true,
    migrated = true,
    nativeContentHost = true,
    pageContract = true,
    parity176 = true,
    noOnUpdate = true,
})
