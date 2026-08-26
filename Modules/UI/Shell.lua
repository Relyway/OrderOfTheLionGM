-- Order of the Lion Guild Manager 1.8.3 native shell.
-- The final shell deliberately never calls the legacy full BuildUI.
-- Vanilla / OctoWoW / Lua 5.0 compatible. This module adds no permanent OnUpdate;
-- drag and resize own a temporary script only while the mouse is held.

if not OTLGM or not OTLGM.UI then return end

-- Runtime version/build are owned exclusively by Core/Bootstrap.lua.
-- Keeping shell presentation code from rewriting release identity prevents
-- load-order drift between TOC metadata, support reports and network presence.
OTLGM.shellVersion = 10
OTLGM.shellPageBuilders = OTLGM.shellPageBuilders or {}
OTLGM.shellPageRefreshers = OTLGM.shellPageRefreshers or {}
OTLGM.shellPageModules = OTLGM.shellPageModules or {}

local UI = OTLGM.UI
local C = UI.colors

-- Page-level 1.7.6 builders remain a source of controls and behaviour only.
-- Native page modules attach those child controls directly to ContentHost.
-- The old full BuildUI is deliberately not retained or reachable here.
OTLGM.nativePageSources = {
    BuildGuildChatPage = OTLGM.BuildGuildChatPage,
    BuildPvePage = OTLGM.BuildPvePage,
    BuildGuildInfoPage = OTLGM.BuildGuildInfoPage,
    BuildActivityPage = OTLGM.BuildActivityPage,
    BuildOverviewPage = OTLGM.BuildOverviewPage,
    BuildRecruitmentPage = OTLGM.BuildRecruitmentPage,
    BuildHistoryPage = OTLGM.BuildHistoryPage,
    BuildInactivePage = OTLGM.BuildInactivePage,
    BuildAchievementsPage = OTLGM.BuildAchievementsPage174,
    BuildTreasuryPage = OTLGM.BuildTreasuryPage170,
    BuildSearchPage = OTLGM.BuildNextSearchPage,
    RefreshGuildChatPage = OTLGM.RefreshGuildChatPage,
    RefreshPvePage = OTLGM.RefreshPvePage,
    RefreshGuildInfoPage = OTLGM.RefreshGuildInfoPage,
    RefreshActivityPage = OTLGM.RefreshActivityPage,
    RefreshOverviewPage = OTLGM.RefreshOverviewPage,
    RefreshRecruitmentPage = OTLGM.RefreshRecruitmentPage,
    RefreshHistoryPage = OTLGM.RefreshHistoryPage,
    RefreshInactivePage = OTLGM.RefreshInactivePage,
    RefreshAchievements = OTLGM.RefreshAchievements174,
    RefreshTreasuryPage = OTLGM.RefreshTreasuryPage170,
    RefreshSearchPage = OTLGM.RefreshSearchPage,
}

local PAGE_DEFS = {
    { key = "home", label = "Home", icon = "Interface\\Icons\\Ability_TownWatch", group = "primary" },
    { key = "guildchat", label = "Guild Chat", icon = "Interface\\Icons\\INV_Letter_15", group = "primary" },
    { key = "search", label = "Search", icon = "Interface\\Icons\\INV_Misc_Spyglass_03", group = "primary" },
    { key = "pve", label = "PvE Hub", icon = "Interface\\Icons\\INV_Helmet_06", group = "primary" },
    { key = "guildinfo", label = "Guild Info", icon = "Interface\\Icons\\INV_Scroll_03", group = "guild" },
    { key = "roster", label = "Roster", icon = "Interface\\Icons\\INV_Misc_Book_09", group = "guild" },
    { key = "professions", label = "Professions", icon = "Interface\\Icons\\Trade_Engineering", group = "guild" },
    { key = "achievements", label = "Achievements", icon = "Interface\\Icons\\INV_Misc_Note_06", group = "guild" },
    { key = "treasury", label = "Treasury", icon = "Interface\\Icons\\INV_Misc_Coin_01", group = "guild" },
    { key = "activity", label = "Activity", icon = "Interface\\Icons\\INV_Misc_PocketWatch_01", group = "guild" },
    { key = "overview", label = "Overview", icon = "Interface\\Icons\\INV_Misc_Map_01", group = "officer", officer = true },
    { key = "guildadmin", label = "Guild Admin", icon = "Interface\\Icons\\INV_Misc_Key_14", group = "officer", officer = true },
    { key = "cases", label = "Officer Cases", icon = "Interface\\Icons\\INV_Misc_Note_05", group = "officer", officer = true },
    { key = "recruitment", label = "Recruitment", icon = "Interface\\Icons\\INV_Misc_Horn_02", group = "officer", officer = true },
    { key = "history", label = "History", icon = "Interface\\Icons\\INV_Misc_Book_11", group = "officer", officer = true },
    { key = "inactive", label = "Inactive", icon = "Interface\\Icons\\Spell_Shadow_Cripple", group = "officer", officer = true },
    { key = "settings", label = "Settings", icon = "Interface\\Icons\\INV_Gizmo_02", group = "footer" },
}

local PAGE_TITLES = {
    home = { "Home", "Guild news, groups and people at a glance" },
    guildchat = { "Guild Chat", "Guild conversation and board" },
    search = { "Search", "Find guild members, recipes, groups and posts" },
    pve = { "PvE Hub", "Groups, raids and guild activities" },
    guildinfo = { "Guild Info", "Guild information and useful links" },
    roster = { "Roster", "Members, saved views and member details" },
    professions = { "Professions", "Guild recipes, crafters and requests" },
    achievements = { "Achievements", "Guild achievement catalogue and progress" },
    treasury = { "Treasury", "Guild goals and contribution history" },
    activity = { "Activity", "Useful recent guild activity" },
    overview = { "Officer Overview", "Management summary for guild leadership" },
    guildadmin = { "Guild Administration", "Message, ranks, permissions and member controls" },
    cases = { "Officer Cases", "Private report queue, decisions and troubleshooting" },
    recruitment = { "Recruitment", "Approved recruitment messages and timing" },
    history = { "History", "Roster and officer audit history" },
    inactive = { "Inactive Members", "Review and manage inactive members" },
    settings = { "Settings", "Interface preferences and local recovery" },
}

local function AddSpecialFrame(name)
    if not name or not UISpecialFrames then return end
    local index
    for index = 1, table.getn(UISpecialFrames) do
        if UISpecialFrames[index] == name then return end
    end
    table.insert(UISpecialFrames, name)
end

local function MakeLabel(parent, value, template, x, y, width, justify)
    local label = UI.Text(parent, value, template, justify)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then label:SetWidth(width) end
    return label
end

local function Short(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or 60
    if string.len(value) <= maximum then return value end
    return string.sub(value, 1, math.max(1, maximum - 3)) .. "..."
end

local function PublicVersion(value)
    value = tostring(value or "")
    local _, _, version = string.find(value, "(%d+%.%d+%.%d+)")
    return version or "1.8.0"
end

function OTLGM:GetPublicVersion180(value)
    return PublicVersion(value or self.version)
end

-- One native entry point owns every object selection used by Search, Home and
-- Action Center.  The Stage B shell must never open a legacy reader or write a
-- superseded selection field: doing so leaves the native page visible while a
-- different implementation owns the actual state.
local function NormalizeObjectType180(value)
    local objectType = string.upper(tostring(value or ""))
    objectType = string.gsub(objectType, "[%s%-]+", "_")
    local aliases = {
        CRAFT = "CRAFT_REQUEST",
        CRAFTREQUEST = "CRAFT_REQUEST",
        CRAFT_REQUEST = "CRAFT_REQUEST",
        ANN = "GUILD_POST",
        ANNOUNCEMENT = "GUILD_POST",
        GUILDPOST = "GUILD_POST",
        GUILD_POST = "GUILD_POST",
        BOARD = "BOARD_POST",
        BOARDPOST = "BOARD_POST",
        BOARD_POST = "BOARD_POST",
        RAID = "RAID_EVENT",
        RAIDEVENT = "RAID_EVENT",
        RAID_EVENT = "RAID_EVENT",
        RAIDTEAM = "RAID_TEAM",
        RAID_TEAM = "RAID_TEAM",
        CHAT = "CHAT_MESSAGE",
        MESSAGE = "CHAT_MESSAGE",
        CHATMESSAGE = "CHAT_MESSAGE",
        CHAT_MESSAGE = "CHAT_MESSAGE",
    }
    return aliases[objectType] or objectType
end

-- Canonical Stage C object route. Search, Home, Action Center and future
-- notifications call this helper instead of owning parallel selection logic.
-- C0 intentionally does not create the future Raid Teams UI; that route becomes
-- active when the existing PvE page gains its C5 view.
function OTLGM:OpenGuildObject180(objectType, objectId, options)
    if not self.ui then return false, "ui-not-ready" end
    options = type(options) == "table" and options or {}
    objectType = NormalizeObjectType180(objectType)
    local target = objectId

    if objectType == "MEMBER" then
        local searchText = tostring(options.title or target or "")
        if OTLGM_DB and OTLGM_DB.settings then OTLGM_DB.settings.rosterSearch = searchText end
        self.ui.selectedMember = target
        self:ShowPage("roster")
        if self.ui.rosterSearch then self.ui.rosterSearch:SetText(searchText) end
        if self.SelectRosterMember and target then self:SelectRosterMember(target) end
        self.ui.rosterFocusMember180 = target
        if self.RefreshRosterPage then self:RefreshRosterPage("object-route") end
        return true
    end

    if objectType == "RECIPE" then
        if OTLGM_DB and OTLGM_DB.settings then
            OTLGM_DB.settings.craftingSection = "RECIPES"
            OTLGM_DB.settings.craftingSearch = ""
            OTLGM_DB.settings.craftingProfession = "ALL"
            OTLGM_DB.settings.craftingCategory153 = "ALL"
            OTLGM_DB.settings.craftingLevelFilter153 = "ANY"
            OTLGM_DB.settings.craftingRarityFilter153 = "ANY"
            OTLGM_DB.settings.craftingOnlineOnly153 = false
            OTLGM_DB.settings.craftingFavoritesOnly170 = false
        end
        self.ui.craftingSelectedRecipeKey = target
        self.ui.craftingFocusRecipeKey180 = target
        self.ui.craftingRecipeOffset = 0
        self:ShowPage("professions")
        if self.SetProfessionsTab then self:SetProfessionsTab("RECIPES")
        elseif self.RefreshProfessionsPage then self:RefreshProfessionsPage("object-route") end
        return true
    end

    if objectType == "CRAFT_REQUEST" then
        if OTLGM_DB and OTLGM_DB.settings then OTLGM_DB.settings.craftingSection = "REQUESTS" end
        self.ui.craftingSelectedRequestShell = target
        self.ui.craftingFocusRequest180 = target
        self.ui.craftingRequestOffsetShell = 0
        self:ShowPage("professions")
        if self.SetProfessionsTab then self:SetProfessionsTab("REQUESTS")
        elseif self.RefreshProfessionsPage then self:RefreshProfessionsPage("object-route") end
        return true
    end

    if objectType == "GUILD_POST" then
        self:ShowPage("home")
        if self.SetHomeTab then self:SetHomeTab("POSTS") end
        self.ui.homeShowArchived = options.archived and true or false
        if self.SelectHomePost and target then self:SelectHomePost(target) end
        return true
    end

    if objectType == "BOARD_POST" then
        self.ui.guildBoardSelected152 = target
        self:ShowPage("guildchat")
        if self.SelectGuildChatView152 then self:SelectGuildChatView152("BOARD") end
        if self.RefreshGuildBoardChat152 then self:RefreshGuildBoardChat152() end
        return true
    end

    if objectType == "GROUP" then
        if OTLGM_DB and OTLGM_DB.settings then OTLGM_DB.settings.pveSection = "GROUPS" end
        self.ui.pveSelectedRequest = target
        if self.SetPveGroupRightTab180 then self:SetPveGroupRightTab180("DETAILS") end
        if self.PreparePveJoinDefaults180 then self:PreparePveJoinDefaults180(target, true) end
        self:ShowPage("pve")
        if self.ShowPveSection then self:ShowPveSection("GROUPS") end
        if self.RefreshPvePage then self:RefreshPvePage("object-route") end
        return true
    end

    if objectType == "RAID_EVENT" then
        if OTLGM_DB and OTLGM_DB.settings then OTLGM_DB.settings.pveSection = "RAIDS" end
        self.ui.pveRaidSelectedId155 = target
        self.ui.raidSelected156 = target
        self.ui.pveRaidAreaMode180 = "EVENTS"
        self:ShowPage("pve")
        if self.ShowPveSection then self:ShowPveSection("RAIDS") end
        if self.SetPveRaidAreaMode180 then self:SetPveRaidAreaMode180("EVENTS") end
        if self.RefreshPvePage then self:RefreshPvePage("object-route") end
        return true
    end

    if objectType == "RAID_TEAM" then
        self.ui.pveSelectedRaidTeam180 = target
        if self.OpenRaidTeamNative180 then return self:OpenRaidTeamNative180(target, options) end
        return false, "raid-team-ui-not-installed"
    end

    if objectType == "CHAT_MESSAGE" then
        if self.OpenGuildChatMention174 then
            local opened = self:OpenGuildChatMention174({
                mentionChannel = options.messageChannel or options.section,
                mentionTs = options.messageTs,
                mentionSender = options.messageSender,
                mentionText = options.messageText,
            })
            return opened ~= false
        end
        self:ShowPage("guildchat")
        return true
    end

    if options.page then
        self:ShowPage(options.page)
        return true
    end
    return false, "unknown-object-type"
end

function OTLGM:OpenNativeObject180(result)
    if not result then return false end
    local objectType = result.objectType or result.type or result.targetType
    local objectId = result.objectId or result.target or result.targetId
    local options = {
        page = result.page or result.targetPage,
        title = result.title,
        archived = result.archived,
        section = result.section,
        actionKey = result.actionKey,
        messageChannel = result.messageChannel,
        messageTs = result.messageTs,
        messageSender = result.messageSender,
        messageText = result.messageText,
    }
    return self:OpenGuildObject180(objectType, objectId, options)
end

function OTLGM:OpenGlobalSearchResult(result)
    return self:OpenNativeObject180(result)
end

local function IsTechnicalMessage(value)
    local text = string.lower(tostring(value or ""))
    if text == "" then return false end
    local terms = {
        "snapshot", "manifest", "queue", "protocol", "packet",
        "synchronization", "synchronizing", "sync complete", "sync finished",
        "already running",
        "requesting current", "requesting crafting", "requesting shared",
        "requesting treasury", "checking for other order of the lion addon users",
        "confirmation attempt", "incomplete roster suspected",
        "roster restoration suspected", "network payload",
    }
    local index
    for index = 1, table.getn(terms) do
        if string.find(text, terms[index], 1, true) then return true end
    end
    return false
end

function OTLGM:IsTechnicalShellMessage180(value)
    return IsTechnicalMessage(value)
end

local function RaiseShellTree(frame, baseLevel, depth)
    if not frame then return end
    depth = tonumber(depth) or 0
    if frame.SetFrameLevel then frame:SetFrameLevel(baseLevel + depth) end
    if not frame.GetChildren then return end
    local children = { frame:GetChildren() }
    local index
    for index = 1, table.getn(children) do
        if children[index] and children[index] ~= frame then RaiseShellTree(children[index], baseLevel, depth + 2) end
    end
end

function OTLGM:GetShellPageDefinition(pageKey)
    local index
    for index = 1, table.getn(PAGE_DEFS) do
        if PAGE_DEFS[index].key == pageKey then return PAGE_DEFS[index] end
    end
    return nil
end

local PAGE_CONTRACT = {
    "Build", "Layout", "Refresh", "OnShow", "OnHide",
    "GetPreferredToolbar", "GetMinimumSize",
}

function OTLGM:RegisterShellPageModule180(pageKey, module)
    if not pageKey or not module then return false end
    local index
    for index = 1, table.getn(PAGE_CONTRACT) do
        if type(module[PAGE_CONTRACT[index]]) ~= "function" then return false end
    end
    module.key = pageKey
    module.owner = self
    self.shellPageModules[pageKey] = module
    return true
end

function OTLGM:CreateShellPageModule180(pageKey, builder, refresher, layout, toolbar, minimum)
    local module = {}
    function module:Build(contentHost)
        local root = CreateFrame("Frame", nil, contentHost)
        root:SetPoint("TOPLEFT", contentHost, "TOPLEFT", 0, 0)
        root:SetPoint("BOTTOMRIGHT", contentHost, "BOTTOMRIGHT", 0, 0)
        root.otlPageRoot = true
        root.otlContentHostEdges = true
        root.otlNoPageBackdrop = true
        root.otlPageKey = self.key
        -- Defence-in-depth for clients that expose child clipping. A page may
        -- never paint pooled rows or resized controls outside ContentHost.
        if root.SetClipsChildren then root:SetClipsChildren(true) end
        root:Hide()
        self.root = root
        if builder then builder(self.owner, root) end
        return root
    end
    function module:Layout(width, height)
        width = math.max(1, tonumber(width) or 936)
        height = math.max(1, tonumber(height) or 596)
        self.lastWidth = width
        self.lastHeight = height
        self.layoutCount = (self.layoutCount or 0) + 1
        if layout then layout(self.owner, self.root, width, height) end
    end
    function module:Refresh(reason)
        self.lastRefreshReason = reason
        if refresher then refresher(self.owner, reason) end
    end
    function module:OnShow(context)
        self.visible = true
        self.context = context
    end
    function module:OnHide()
        self.visible = nil
    end
    function module:GetPreferredToolbar()
        if type(toolbar) == "function" then return toolbar(self.owner) end
        return toolbar
    end
    function module:GetMinimumSize()
        return minimum or { width = 720, height = 500 }
    end
    self:RegisterShellPageModule180(pageKey, module)
    return module
end

function OTLGM:CloseShellContextMenus()
    if not self.ui then return end
    if self.ui.playerMenu then self.ui.playerMenu:Hide() end
    if self.ui.playerOfficerMenu then self.ui.playerOfficerMenu:Hide() end
    if self.ui.contextMenuCatcher then self.ui.contextMenuCatcher:Hide() end
    -- 1.7 compatibility menus own full-page mouse shields. They are outside the
    -- shell context-menu catcher, so close them as part of every shell transient
    -- reset or an old shield can survive a programmatic page/deep-link route.
    if self.CloseChatNameMenu157 then self:CloseChatNameMenu157()
    elseif self.ui.chatMenuShield157 then self.ui.chatMenuShield157:Hide() end
    if self.CloseCrafterMenu157 then self:CloseCrafterMenu157()
    elseif self.ui.crafterShield157 then self.ui.crafterShield157:Hide() end
end

function OTLGM:CloseShellDrawer()
    if not self.ui or not self.ui.drawerHost then return end
    local active = self.ui.activeDrawer
    self.ui.activeDrawer = nil
    if active then active:Hide() end
    self.ui.drawerHost:Hide()
end

local function RemoveShellModalFromStack180(stack, frame)
    local index
    for index = table.getn(stack or {}), 1, -1 do
        if stack[index] == frame then table.remove(stack, index) end
    end
end

local function ClearModalFocus180(frame)
    if not frame then return end
    if frame.ClearFocus then pcall(frame.ClearFocus, frame) end
    if not frame.GetChildren then return end
    local children = { frame:GetChildren() }
    local index
    for index = 1, table.getn(children) do ClearModalFocus180(children[index]) end
end

function OTLGM:RefreshShellModalState180()
    if not self.ui or not self.ui.modalHost then return false end
    local stack = self.ui.modalStack180 or {}
    local visible = {}
    local index, frame
    for index = 1, table.getn(stack) do
        frame = stack[index]
        if frame and frame.IsVisible and frame:IsVisible() then table.insert(visible, frame) end
    end
    self.ui.modalStack180 = visible
    self.ui.activeModal = visible[table.getn(visible)]
    if self.ui.activeModal then
        self.ui.modalHost:Show()
        RaiseShellTree(self.ui.activeModal, self.ui.modalHost:GetFrameLevel() + 2 + (table.getn(visible) * 8), 0)
    else
        self.ui.modalHostClosing180 = true
        self.ui.modalHost:Hide()
        self.ui.modalHostClosing180 = nil
    end
    if self.RefreshModalOverlay152 then self:RefreshModalOverlay152() end
    return true
end

function OTLGM:CloseModal180(frame, reason)
    if not self.ui or not self.ui.modalHost then return false end
    local stack = self.ui.modalStack180 or {}
    local target = frame or self.ui.activeModal or stack[table.getn(stack)]
    if not target then
        self:RefreshShellModalState180()
        return false
    end
    reason = reason or "close"
    if target.otlBeforeClose180 and not target.otlForceClose180
        and reason ~= "save-success" and reason ~= "confirm-success" and reason ~= "discard-confirmed" then
        local allow = target.otlBeforeClose180(target, reason)
        if allow == false then return false end
    end
    local cancelHandler = reason ~= "confirm-success" and target.otlCancelHandler180 or nil
    target.otlCancelHandler180 = nil
    if reason ~= "confirm-success" then target.otlConfirmHandler = nil end
    target.otlForceClose180 = nil
    target.otlDiscardPrompt180 = nil
    ClearModalFocus180(target)
    RemoveShellModalFromStack180(stack, target)
    self.ui.modalStack180 = stack
    if self.ui.modalStack154 then RemoveShellModalFromStack180(self.ui.modalStack154, target) end
    if self.ui.activeModal == target then self.ui.activeModal = nil end
    target.otlLastCloseReason180 = reason
    target.otlClosing180 = true
    if target.Hide then target:Hide() end
    target.otlClosing180 = nil
    self:RefreshShellModalState180()
    self.runtime = self.runtime or {}
    self.runtime.uiDiagnostics180 = self.runtime.uiDiagnostics180 or {}
    self.runtime.uiDiagnostics180.lastModalCloseReason = reason
    self.runtime.uiDiagnostics180.lastModalName = target.GetName and target:GetName() or target.otlDiagnosticName180 or "unnamed modal"
    self.runtime.uiDiagnostics180.modalDepth = table.getn(self.ui.modalStack180 or {})
    if cancelHandler then cancelHandler(reason) end
    return true
end

function OTLGM:CloseShellModal()
    return self:CloseModal180(nil, "shell-close")
end

function OTLGM:CloseAllShellModals180(reason, force)
    if not self.ui or not self.ui.modalHost then return true end
    local guard = 0
    while guard < 32 do
        local stack = self.ui.modalStack180 or {}
        local target = self.ui.activeModal or stack[table.getn(stack)]
        if not target then break end
        guard = guard + 1
        if force then target.otlForceClose180 = true end
        if not self:CloseModal180(target, reason or "shell-transient") then
            self:RefreshShellModalState180()
            return false
        end
    end
    -- A hidden parent can make IsVisible() false before an OnHide callback runs,
    -- and older/legacy code can occasionally leave a shown direct child outside
    -- modalStack180. Once the tracked stack has closed successfully there is no
    -- valid reason for any child of the dedicated modal host to stay shown. Hide
    -- all direct children even on an ordinary page transition so an orphan cannot
    -- reappear and become an invisible input shield the next time the host opens.
    if self.ui.modalHost.GetChildren then
        local children = { self.ui.modalHost:GetChildren() }
        local index, child
        for index = 1, table.getn(children) do
            child = children[index]
            if child and child.Hide then
                child.otlClosing180 = true
                child:Hide()
                child.otlClosing180 = nil
            end
        end
        self.ui.modalStack180 = {}
        self.ui.activeModal = nil
    end
    self:RefreshShellModalState180()
    return not self.ui.activeModal
end

function OTLGM:CloseTopShellTransient180()
    if not self.ui then return false end
    if self.ui.quickDockPopover182 and self.CloseQuickDockPopover182 then
        self:CloseQuickDockPopover182()
        return true
    end
    if self.ui.activeModal then self:CloseShellModal() return true end
    if self.ui.activeDrawer then self:CloseShellDrawer() return true end
    if self.ui.contextMenuCatcher and self.ui.contextMenuCatcher.IsVisible and self.ui.contextMenuCatcher:IsVisible() then
        self:CloseShellContextMenus()
        return true
    end
    return false
end

function OTLGM:CloseShellTransient(includeToast, reason, force)
    self:CloseShellContextMenus()
    self:CloseShellDrawer()
    local closed = self:CloseAllShellModals180(reason or "shell-transient", force and true or false)
    if not closed and not force then return false end
    if self.ui and self.ui.modalStack154 then
        local index
        for index = 1, table.getn(self.ui.modalStack154) do
            local frame = self.ui.modalStack154[index]
            if frame and frame.Hide then frame:Hide() end
        end
        self.ui.modalStack154 = {}
    end
    if self.ui and self.ui.modalOverlay152 then self.ui.modalOverlay152:Hide() end

    -- Older Action Inbox/Highlights/exclusive-modal surfaces predate modalHost
    -- and own independent mouse-catching overlays. Deep links can call ShowPage
    -- without clicking those overlays first, so a page transition must retire
    -- them explicitly as part of the same atomic transient reset.
    if self.CloseInbox170 then self:CloseInbox170()
    elseif self.ui and self.ui.inboxOverlay170 then self.ui.inboxOverlay170:Hide() end
    if self.ui and self.ui.chatHighlights170 then self.ui.chatHighlights170:Hide() end
    if self.CloseGroupFinderComposer170 then self:CloseGroupFinderComposer170(false)
    elseif self.ui and self.ui.pveGroupFormShield170 then self.ui.pveGroupFormShield170:Hide() end
    if self.ui and self.ui.exclusiveModalR5 then
        if self.ui.exclusiveModalR5.Hide then self.ui.exclusiveModalR5:Hide() end
        self.ui.exclusiveModalR5 = nil
    end
    if self.ui and self.ui.exclusiveModalOverlayR5 then self.ui.exclusiveModalOverlayR5:Hide() end

    if includeToast and self.ui and self.ui.shellToast then self.ui.shellToast:Hide() end
    return true
end

function OTLGM:ShowShellDrawer(drawer)
    if not drawer or not self.ui or not self.ui.drawerHost then return false end
    if self.ui.activeModal and not self:CloseAllShellModals180("drawer-open", false) then return false end
    self:CloseShellContextMenus()
    if self.ui.activeDrawer and self.ui.activeDrawer ~= drawer then self.ui.activeDrawer:Hide() end
    self.ui.activeDrawer = drawer
    self.ui.drawerHost:Show()
    RaiseShellTree(drawer, self.ui.drawerHost:GetFrameLevel() + 2, 0)
    drawer:Show()
    return true
end

function OTLGM:ShowShellModal(modal, dangerous)
    if not modal or not self.ui or not self.ui.modalHost then return false end
    self:CloseShellDrawer()
    self:CloseShellContextMenus()
    if modal.GetParent and modal:GetParent() ~= self.ui.modalHost and modal.SetParent then
        modal:SetParent(self.ui.modalHost)
        modal:ClearAllPoints()
        modal:SetPoint("CENTER", self.ui.modalHost, "CENTER", 0, 0)
    end
    self.ui.modalStack180 = self.ui.modalStack180 or {}
    RemoveShellModalFromStack180(self.ui.modalStack180, modal)
    table.insert(self.ui.modalStack180, modal)
    self.ui.activeModal = modal
    if not modal.otlCloseLifecycle180 then
        modal.otlCloseLifecycle180 = true
        local oldHide = modal.GetScript and modal:GetScript("OnHide") or nil
        modal:SetScript("OnHide", function()
            if oldHide then oldHide() end
            if OTLGM and OTLGM.ui and not modal.otlClosing180 then
                RemoveShellModalFromStack180(OTLGM.ui.modalStack180 or {}, modal)
                if OTLGM.ui.activeModal == modal then OTLGM.ui.activeModal = nil end
                OTLGM:RefreshShellModalState180()
            end
        end)
    end
    if self.ui.modalShade and self.ui.modalShade.SetTexture then
        local alpha = dangerous and 0.25 or 0.18
        self.ui.modalShade:SetTexture(0, 0, 0, alpha)
        self.ui.modalHost.otlShadeAlpha = alpha
    end
    self.ui.modalHost:Show()
    RaiseShellTree(modal, self.ui.modalHost:GetFrameLevel() + 2 + (table.getn(self.ui.modalStack180) * 8), 0)
    modal:Show()
    return true
end

function OTLGM:BuildShellNoticeModal()
    if self.ui.shellNoticeModal then return end
    local modal = UI:Modal(self.ui.modalHost, 520, 250)
    modal:SetPoint("CENTER", self.ui.modalHost, "CENTER", 0, 0)
    modal.title = MakeLabel(modal, "", "GameFontNormalLarge", 20, -20, 438, "LEFT")
    modal.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    modal.body = MakeLabel(modal, "", "GameFontNormal", 20, -62, 480, "LEFT")
    modal.body:SetHeight(118)
    modal.body:SetJustifyV("TOP")
    modal.close = UI:Button(modal, "Close", 100, 30, function() OTLGM:CloseShellModal() end, "primary")
    modal.close:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -18, 16)
    self.ui.shellNoticeModal = modal
end

function OTLGM:ShowNotice(title, body)
    if not self.ui or not self.ui.main then self:BuildUI() end
    self:BuildShellNoticeModal()
    self.ui.shellNoticeModal.title:SetText(tostring(title or "Notice"))
    self.ui.shellNoticeModal.body:SetText(tostring(body or ""))
    self:ShowShellModal(self.ui.shellNoticeModal)
end

function OTLGM:BuildShellConfirmModal()
    if self.ui.shellConfirmModal then return end
    local modal = UI:Modal(self.ui.modalHost, 540, 270)
    modal:SetPoint("CENTER", self.ui.modalHost, "CENTER", 0, 0)
    modal.title = MakeLabel(modal, "", "GameFontNormalLarge", 20, -20, 458, "LEFT")
    modal.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    modal.body = MakeLabel(modal, "", "GameFontNormal", 20, -62, 500, "LEFT")
    modal.body:SetHeight(128)
    modal.body:SetJustifyV("TOP")
    modal.confirm = UI:Button(modal, "Confirm", 126, 30, function()
        local current = OTLGM.ui.shellConfirmModal
        local handler = current.otlConfirmHandler
        current.otlConfirmHandler = nil
        current.otlCancelHandler180 = nil
        OTLGM:CloseModal180(current, "confirm-success")
        if handler then handler() end
    end, "danger")
    modal.confirm:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -18, 16)
    modal.cancel = UI:Button(modal, "Cancel", 100, 30, function() OTLGM:CloseModal180(OTLGM.ui.shellConfirmModal, "confirm-cancel") end, "secondary")
    modal.cancel:SetPoint("RIGHT", modal.confirm, "LEFT", -8, 0)
    self.ui.shellConfirmModal = modal
end

function OTLGM:ShowConfirm(title, body, confirmLabel, handler, cancelHandler)
    if not self.ui or not self.ui.main then self:BuildUI() end
    self:BuildShellConfirmModal()
    local modal = self.ui.shellConfirmModal
    modal.title:SetText(tostring(title or "Confirm"))
    modal.body:SetText(tostring(body or ""))
    UI:SetText(modal.confirm, confirmLabel or "Confirm")
    modal.otlConfirmHandler = handler
    modal.otlCancelHandler180 = cancelHandler
    modal.otlDiagnosticName180 = tostring(title or "Confirm")
    self:ShowShellModal(modal, true)
end

function OTLGM:BuildShellCopyModal()
    if self.ui.shellCopyModal then return end
    local modal = UI:Modal(self.ui.modalHost, 700, 500)
    modal:SetPoint("CENTER", self.ui.modalHost, "CENTER", 0, 0)
    modal.title = MakeLabel(modal, "", "GameFontNormalLarge", 20, -18, 600, "LEFT")
    modal.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    modal.edit = CreateFrame("EditBox", nil, modal)
    if self.PrepareInteractiveControl170 then self:PrepareInteractiveControl170(modal.edit, "editbox") end
    modal.edit:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -58)
    modal.edit:SetWidth(660)
    modal.edit:SetHeight(378)
    modal.edit:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    modal.edit:SetBackdropColor(0.012, 0.011, 0.010, 1)
    modal.edit:SetBackdropBorderColor(C.goldDark[1], C.goldDark[2], C.goldDark[3], 1)
    UI:MakeOpaque(modal.edit, C.input, C.goldDark)
    modal.edit:SetMultiLine(true)
    modal.edit:SetAutoFocus(false)
    modal.edit:SetTextInsets(8, 8, 8, 8)
    modal.edit:SetFontObject("ChatFontNormal")
    UI:ApplyEditBox(modal.edit, {
        width = 660,
        height = 378,
        multiline = true,
        maxLetters = 2000000,
        fontObject = "ChatFontNormal",
    })
    modal.close = UI:Button(modal, "Close", 100, 30, function() OTLGM:CloseShellModal() end, "primary")
    modal.close:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -18, 16)
    self.ui.shellCopyModal = modal
end

function OTLGM:ShowCopyDialog(title, text)
    if not self.ui or not self.ui.main then self:BuildUI() end
    self:BuildShellCopyModal()
    self.ui.shellCopyModal.title:SetText(tostring(title or "Copy"))
    self.ui.shellCopyModal.edit:SetText(tostring(text or ""))
    self.ui.shellCopyModal.edit:HighlightText()
    self:ShowShellModal(self.ui.shellCopyModal)
    self.ui.shellCopyModal.edit:SetFocus()
end

function OTLGM:OpenFirstRunWizard()
    self:ShowNotice("Order of the Lion", "Use the sidebar to open guild tools. Interface scale, window preferences and recovery controls are available in Settings.")
end

function OTLGM:ShowToast(message, tone, duration)
    if not self.ui or not self.ui.shellToast then return end
    if IsTechnicalMessage(message) then return false end
    local toast = self.ui.shellToast
    toast.text:SetText(Short(message, 130))
    if tone == "error" then
        toast:SetBackdropBorderColor(C.red[1], C.red[2], C.red[3], 1)
    elseif tone == "success" then
        toast:SetBackdropBorderColor(C.green[1], C.green[2], C.green[3], 1)
    elseif tone == "pending" then
        toast:SetBackdropBorderColor(C.orange[1], C.orange[2], C.orange[3], 1)
    else
        toast:SetBackdropBorderColor(C.gold[1], C.gold[2], C.gold[3], 1)
    end
    toast:Show()
    self.runtime = self.runtime or {}
    self.runtime.shellToastUntil = self:Now() + math.max(2, tonumber(duration) or 5)
    if self.WakeScheduler180 then self:WakeScheduler180("status-expiry") end
    return true
end

function OTLGM:ShowOperationError(message, retryHandler)
    if self.RecordInternalIssueRC3 then self:RecordInternalIssueRC3("UI", message) end
    if not self.ui or not self.ui.operationHost then return end
    self.ui.operationText:SetText(Short(message or "The action could not be completed.", 105))
    self.ui.operationRetry.otlRetryHandler = retryHandler
    self.ui.operationHost:Show()
end

function OTLGM:ClearOperationError()
    if self.ui and self.ui.operationHost then self.ui.operationHost:Hide() end
end

function OTLGM:SetStatus(text, duration, context)
    text = tostring(text or "")
    self.runtime = self.runtime or {}
    if text == "" then
        self.runtime.shellToastUntil = nil
        if self.ui and self.ui.shellToast then self.ui.shellToast:Hide() end
        return
    end
    context = type(context) == "table" and context or nil
    local lower = string.lower(text)
    if context and context.source then
        self.runtime.lastStatusSource180 = tostring(context.source)
        self.runtime.lastStatusAt180 = self:Now()
        if context.source == "crafting" and not (context.manual and self.ui and self.ui.main and self.ui.main:IsVisible() and self.ui.currentPage == "professions") then
            self.runtime.lastBackgroundStatus180 = Short(text, 130)
            self.runtime.lastBackgroundStatusSource180 = "crafting"
            return false
        end
        if context.source == "pve" and not (context.manual and self.ui and self.ui.main and self.ui.main:IsVisible() and (self.ui.currentPage == "pve" or self.ui.currentPage == "settings")) then
            -- A manual request can finish many seconds after the player has left
            -- PvE Hub; an automatic request can originate from login/guild state.
            -- Keep either result local unless the user is actually viewing PvE.
            self.runtime.lastBackgroundStatus180 = Short(text, 130)
            self.runtime.lastBackgroundStatusSource180 = "pve"
            return false
        end
        if context.source == "roster" and not (context.manual and self.ui and self.ui.main and self.ui.main:IsVisible() and (self.ui.currentPage == "roster" or self.ui.currentPage == "settings")) then
            self.runtime.lastBackgroundStatus180 = Short(text, 130)
            self.runtime.lastBackgroundStatusSource180 = "roster"
            return false
        end
    end
    if string.find(lower, "crafting sync", 1, true) or string.find(lower, "profession manifest", 1, true)
        or string.find(lower, "profession snapshot", 1, true) or string.find(lower, "profession sharing", 1, true)
        or string.find(lower, "network capacity", 1, true) then
        local friendly
        if string.find(lower, "no current", 1, true) or string.find(lower, "could not", 1, true)
            or string.find(lower, "waiting", 1, true) then
            friendly = "Using local data • Guild update pending"
        elseif string.find(lower, "complete", 1, true) or string.find(lower, "finished", 1, true)
            or string.find(lower, "up to date", 1, true) then
            friendly = "Guild recipes updated"
        end
        if friendly then
            self.runtime.shellCraftingFriendlyStatus = friendly
            if self.runtime.shellCraftingManual and self.ui and self.ui.currentPage == "professions" then
                self:ShowToast(friendly, friendly == "Guild recipes updated" and "success" or "error", duration)
            end
            self.runtime.shellCraftingManual = nil
        end
        return
    end
    if string.find(lower, "roster database updated", 1, true)
        or string.find(lower, "roster baseline safely refreshed", 1, true) then
        if self.runtime.shellRosterManual and self.ui and self.ui.currentPage == "roster" then
            self:ShowToast("Roster updated.", "success", duration)
        end
        self.runtime.shellRosterManual = nil
        return
    end
    if string.find(lower, "checking for other order of the lion addon users", 1, true) then
        self.runtime.shellAddonCheckingUntil = self:Now() + 3
        if self.WakeScheduler180 then self:WakeScheduler180("addon-users-expiry") end
        if self.RefreshAddonUsersIndicator then self:RefreshAddonUsersIndicator() end
        return
    end
    if IsTechnicalMessage(text) then return end
    local tone = "success"
    if string.find(lower, "sending", 1, true) or string.find(lower, "waiting", 1, true)
        or string.find(lower, "syncing", 1, true) or string.find(lower, "updating", 1, true)
        or string.find(lower, "pending", 1, true) or string.find(lower, "prepared in the standard chat", 1, true)
        or string.find(lower, "cooldown", 1, true) then
        tone = "pending"
    elseif string.find(lower, "unable", 1, true) or string.find(lower, "failed", 1, true)
        or string.find(lower, "not found", 1, true) or string.find(lower, "not confirmed", 1, true)
        or string.find(lower, "error", 1, true) then
        tone = "error"
    end
    local shown = self:ShowToast(text, tone, duration)
    if shown then self.runtime.lastVisibleStatusSource180 = context and context.source or "legacy" end
    return shown
end

function OTLGM:ProcessStatus170()
    if not self.runtime then return end
    local now = self:Now()
    if self.runtime.shellToastUntil and now >= self.runtime.shellToastUntil then
        self.runtime.shellToastUntil = nil
        if self.ui and self.ui.shellToast then self.ui.shellToast:Hide() end
    end
    if self.runtime.shellAddonCheckingUntil and now >= self.runtime.shellAddonCheckingUntil then
        self.runtime.shellAddonCheckingUntil = nil
        if self.RefreshAddonUsersIndicator then self:RefreshAddonUsersIndicator() end
        if self.ui and self.ui.addonUsersDrawer and self.ui.activeDrawer == self.ui.addonUsersDrawer then
            self:RefreshAddonUsersDrawer()
        end
    end
    -- Shell.lua replaces the legacy status presentation, but a status deadline
    -- created before the shell override (or restored by an unusual load-order
    -- interaction) must still be consumed. Otherwise StatusDue180 sees a
    -- permanently expired statusUntil170 and keeps the scheduler awake.
    if self.runtime.statusUntil170 and now >= self.runtime.statusUntil170 then
        self.runtime.statusUntil170 = nil
        self.runtime.statusText170 = nil
        if self.ui and self.ui.statusBar then self.ui.statusBar:Hide() end
    end
end

function OTLGM:GetShellOperationState(kind)
    if kind == "updated" then return "Guild recipes updated" end
    if kind == "cached" then return "Using local data" end
    if kind == "waiting" then return "Guild update pending" end
    return "Using local data • Guild update pending"
end

local ShellBaseRequestCraftingSync180 = OTLGM.__impl180.RequestCraftingSync__impl1
if ShellBaseRequestCraftingSync180 then
    function OTLGM:RequestCraftingSync(force, userInitiated)
        local craft = self.EnsureCraftingDB and self:EnsureCraftingDB() or nil
        self.runtime = self.runtime or {}
        if craft and craft.syncState and craft.syncState.active then
            self.runtime.craftingSyncCoalesced180 = (tonumber(self.runtime.craftingSyncCoalesced180) or 0) + 1
            if userInitiated and self.ui and self.ui.currentPage == "professions" then
                self.runtime.shellCraftingManual = true
                self.runtime.shellCraftingFriendlyStatus = "Using local data • Guild update pending"
                if self.RefreshProfessionsPage then self:RefreshProfessionsPage() end
            end
            return false
        end
        local result = ShellBaseRequestCraftingSync180(self, force, userInitiated)
        if userInitiated and result then self.runtime.shellCraftingManual = true end
        if result then
            self.runtime.shellCraftingFriendlyStatus = "Using local data • Guild update pending"
            self.runtime.craftingSyncStartedByUser180 = userInitiated and true or nil
        end
        return result
    end
end

local ShellBaseRequestScan180 = OTLGM.__impl180.RequestScan__impl2 or OTLGM.__impl180.RequestScan__impl1
if ShellBaseRequestScan180 then
    function OTLGM:RequestScan(reason)
        self.runtime = self.runtime or {}
        if reason == "MANUAL" then self.runtime.shellRosterManual = true end
        return ShellBaseRequestScan180(self, reason)
    end
end

function OTLGM:StartAddonUsersCheck180()
    self.runtime = self.runtime or {}
    local now = self:Now()
    if self.runtime.shellAddonCheckingUntil and now < self.runtime.shellAddonCheckingUntil then return false end
    if self.lastAddonUserPingAt and now - self.lastAddonUserPingAt < 10 then
        self.runtime.shellAddonCheckingUntil = self.lastAddonUserPingAt + 10
        if self.WakeScheduler180 then self:WakeScheduler180("addon-users-expiry") end
        self:RefreshAddonUsersIndicator()
        if self.ui and self.ui.addonUsersDrawer then self:RefreshAddonUsersDrawer() end
        return false
    end
    local requested = self.RequestAddonUserPing and self:RequestAddonUserPing()
    if requested then
        self.runtime.shellAddonCheckingUntil = now + 3
        if self.WakeScheduler180 then self:WakeScheduler180("addon-users-expiry") end
    end
    self:RefreshAddonUsersIndicator()
    if self.ui and self.ui.addonUsersDrawer then self:RefreshAddonUsersDrawer() end
    return requested and true or false
end

local function ReactionParts(entryId)
    local _, _, targetType, targetId, author = string.find(tostring(entryId or ""), "^REACT:([^:]+):(.+):([^:]+)$")
    return targetType, targetId, author
end

function OTLGM:GetReactionTargetTitle180(targetType, targetId)
    if targetType == "ANN" and self.GetAnnouncement152 then
        local record = self:GetAnnouncement152(targetId)
        if record then return record.title or "Guild post" end
    elseif targetType == "CRAFT" and self.GetCraftingRequestByID then
        local request = self:GetCraftingRequestByID(targetId)
        if request then return request.item or "Crafting request" end
    elseif targetType == "BOARD" and self.EnsurePveDB then
        local pve = self:EnsurePveDB()
        local post = pve and pve.board and pve.board[targetId]
        if post then return post.title or post.text or "Guild board post" end
    end
    return targetType == "CRAFT" and "Crafting request" or "Guild post"
end

function OTLGM:GetActionCenterEntries180(mode)
    if self.PruneInboxActions180 then self:PruneInboxActions180() end
    local raw = self.GetInboxEntries170 and self:GetInboxEntries170("ALL") or {}
    local grouped, byKey, byObjectAction = {}, {}, {}
    local index, entry
    for index = 1, table.getn(raw) do
        entry = raw[index]
        local technical = entry and (entry.category == "background"
            or IsTechnicalMessage((entry.title or "") .. " " .. (entry.body or "")))
        if type(entry) == "table" and not technical then
            local targetType, targetId, authorKey = ReactionParts(entry.id)
            if targetType and targetId then
                local key = targetType .. ":" .. targetId
                local group = byKey[key]
                if not group then
                    group = {
                        id = entry.id,
                        ids = {},
                        names = {},
                        nameKeys = {},
                        ts = tonumber(entry.ts) or 0,
                        category = "reaction",
                        priority = entry.priority,
                        targetPage = entry.targetPage,
                        read = true,
                        targetType = targetType,
                        targetId = targetId,
                    }
                    byKey[key] = group
                    table.insert(grouped, group)
                end
                table.insert(group.ids, entry.id)
                group.ts = math.max(group.ts or 0, tonumber(entry.ts) or 0)
                if not entry.read then group.read = false end
                if entry.priority == "ACTION" or entry.priority == "CRITICAL" then group.priority = entry.priority end
                local _, _, displayName = string.find(tostring(entry.body or ""), "^([^ ]+) reacted")
                displayName = displayName or authorKey or "Guild member"
                local normalized = string.lower(displayName)
                if not group.nameKeys[normalized] then
                    group.nameKeys[normalized] = true
                    table.insert(group.names, displayName)
                end
            else
                local actionGroupKey = entry.objectType and entry.objectId and entry.actionKey
                    and (tostring(entry.objectType) .. ":" .. tostring(entry.objectId) .. ":" .. tostring(entry.actionKey)) or nil
                local existing = actionGroupKey and byObjectAction[actionGroupKey] or nil
                if existing then
                    table.insert(existing.ids, entry.id)
                    if not entry.read then existing.read = false end
                    if (tonumber(entry.ts) or 0) > (tonumber(existing.ts) or 0) then
                        existing.ts = entry.ts
                        existing.title = entry.title
                        existing.body = entry.body
                        existing.priority = entry.priority
                        existing.targetPage = entry.targetPage
                        existing.section = entry.section
                        existing.messageChannel = entry.messageChannel
                        existing.messageTs = entry.messageTs
                        existing.messageSender = entry.messageSender
                        existing.messageText = entry.messageText
                    end
                else
                    local copy = {}
                    local key, value
                    for key, value in pairs(entry) do copy[key] = value end
                    copy.ids = { entry.id }
                    copy.names = {}
                    if actionGroupKey then byObjectAction[actionGroupKey] = copy end
                    table.insert(grouped, copy)
                end
            end
        end
    end
    local supportEntryR59 = self.GetSupportIncidentActionEntryR59 and self:GetSupportIncidentActionEntryR59() or nil
    if supportEntryR59 then table.insert(grouped, 1, supportEntryR59) end
    for index = 1, table.getn(grouped) do
        local group = grouped[index]
        if group.targetType then
            local count = table.getn(group.names)
            local targetTitle = self:GetReactionTargetTitle180(group.targetType, group.targetId)
            group.title = tostring(count) .. (count == 1 and " member reacted" or " members reacted")
            group.body = "Reactions to \"" .. Short(targetTitle, 42) .. "\""
            group.tooltip = table.concat(group.names, ", ")
        end
    end
    mode = mode or "ALL"
    local result = {}
    for index = 1, table.getn(grouped) do
        entry = grouped[index]
        if mode == "ALL" or (mode == "UNREAD" and not entry.read)
            or (mode == "ACTION" and entry.supportIncidentR59)
            or (mode == "ACTION" and self.IsInboxEntryActionable180 and self:IsInboxEntryActionable180(entry)) then
            table.insert(result, entry)
        end
    end
    return result
end

function OTLGM:GetShellUnreadCount180(targetPage)
    local entries = self:GetActionCenterEntries180("UNREAD")
    local count, index = 0, 1
    for index = 1, table.getn(entries) do
        if not targetPage or entries[index].targetPage == targetPage then count = count + 1 end
    end
    return count
end

function OTLGM:SetActionCenterMode180(mode)
    self.ui.actionCenterMode = mode == "UNREAD" and "UNREAD" or mode == "ACTION" and "ACTION" or "ALL"
    self.ui.actionCenterOffset = 0
    self:RefreshActionCenter()
end

function OTLGM:OpenActionCenterEntry180(entry)
    if not entry then return false end
    if entry.supportIncidentR59 then
        if self.AcknowledgeSupportIncidentR59 then self:AcknowledgeSupportIncidentR59() end
        self:CloseShellDrawer()
        if self.OpenSupportCenterR59 then return self:OpenSupportCenterR59(true) end
        self:ShowPage("settings")
        if self.SetSettingsShellTab then self:SetSettingsShellTab("SUPPORT") end
        return true
    end
    local idIndex
    for idIndex = 1, table.getn(entry.ids or {}) do
        if self.MarkInboxRead170 then self:MarkInboxRead170(entry.ids[idIndex]) end
    end
    self:CloseShellDrawer()
    local sourceType, sourceId = entry.objectType or entry.targetType, entry.objectId or entry.targetId
    if not sourceType then
        local _, _, parsedType, parsedId = string.find(tostring(entry.id or ""), "^([^:]+):([^:]+)")
        sourceType, sourceId = parsedType, parsedId
    end
    if sourceType and sourceId and self:OpenGuildObject180(sourceType, sourceId, {
        page = entry.targetPage,
        section = entry.section,
        actionKey = entry.actionKey,
        messageChannel = entry.messageChannel,
        messageTs = entry.messageTs,
        messageSender = entry.messageSender,
        messageText = entry.messageText,
    }) then return true end
    if entry.targetPage then
        self:ShowPage(entry.targetPage)
        return true
    end
    return false
end

function OTLGM:BuildActionCenterDrawer()
    if self.ui.actionCenterDrawer then return end
    local drawer = UI:Drawer(self.ui.drawerHost, 420, 576)
    drawer:SetPoint("TOPRIGHT", self.ui.drawerHost, "TOPRIGHT", -10, -10)
    drawer.otlScrollable = true
    drawer.title = MakeLabel(drawer, "Action Center", "GameFontNormalLarge", 18, -18, 250, "LEFT")
    drawer.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    drawer.close = UI:IconButton(drawer, "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 28, 28, function() OTLGM:CloseShellDrawer() end, "Close", "utility")
    drawer.close:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -12, -12)
    drawer.markAll = UI:Button(drawer, "Mark all read", 106, 26, function()
        if OTLGM.MarkInboxCategoryRead170 then OTLGM:MarkInboxCategoryRead170(nil) end
        OTLGM:RefreshActionCenter()
    end, "inline")
    drawer.markAll:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -48, -14)
    drawer.modeButtons = {}
    local modes = { { "ALL", "All" }, { "UNREAD", "Unread" }, { "ACTION", "Actions" } }
    local index
    for index = 1, table.getn(modes) do
        local captured = index
        local button = UI:FilterChip(drawer, modes[captured][2], 92, function() OTLGM:SetActionCenterMode180(modes[captured][1]) end)
        button:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18 + ((captured - 1) * 98), -56)
        drawer.modeButtons[captured] = button
    end
    drawer.rows = {}
    drawer.visibleRowCount = 7
    drawer.rowPoolCount180 = 12
    for index = 1, drawer.rowPoolCount180 do
        local captured = index
        local row = UI:TableRow(drawer, 374, 49, function(button)
            local selected = button.otlEntry
            if not selected then return end
            OTLGM:OpenActionCenterEntry180(selected)
        end)
        row:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -92 - ((captured - 1) * 53))
        row.marker = row:CreateTexture(nil, "ARTWORK")
        row.marker:SetTexture(C.gold[1], C.gold[2], C.gold[3], 1)
        row.marker:SetWidth(5)
        row.marker:SetHeight(35)
        row.marker:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.titleText = MakeLabel(row, "", "GameFontNormalSmall", 18, -8, 344, "LEFT")
        row.bodyText = MakeLabel(row, "", "GameFontNormalSmall", 18, -27, 344, "LEFT")
        row:Hide()
        drawer.rows[captured] = row
    end
    drawer.scroll = UI:Scrollbar(drawer, 416, function(value)
        OTLGM.ui.actionCenterOffset = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
        OTLGM:RefreshActionCenter()
    end)
    drawer.scroll:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -10, -92)
    drawer:EnableMouseWheel(true)
    drawer:SetScript("OnMouseWheel", function()
        local maximum = tonumber(this.otlMaximumOffset) or 0
        local nextOffset = math.max(0, math.min(maximum, (OTLGM.ui.actionCenterOffset or 0) - ((tonumber(arg1) or 0) * 3)))
        OTLGM.ui.actionCenterOffset = nextOffset
        this.scroll.otlSilent = true
        this.scroll:SetValue(nextOffset)
        this.scroll.otlSilent = nil
        OTLGM:RefreshActionCenter()
    end)
    drawer.empty = UI:EmptyState(drawer, 350, 112, "All caught up", "Important guild actions will appear here.")
    drawer.empty:SetPoint("TOPLEFT", drawer, "TOPLEFT", 34, -116)
    drawer.empty:Hide()
    drawer.supportR59 = UI:Button(drawer, "Report Issue", 132, 28, function()
        OTLGM:CloseShellDrawer()
        if OTLGM.OpenSupportCenterR59 then OTLGM:OpenSupportCenterR59(false)
        else OTLGM:ShowPage("settings") if OTLGM.SetSettingsShellTab then OTLGM:SetSettingsShellTab("SUPPORT") end end
    end, "utility")
    drawer.supportR59:SetPoint("BOTTOMLEFT", drawer, "BOTTOMLEFT", 18, 14)
    drawer.supportHintR59 = MakeLabel(drawer, "Problem with the addon? Prepare one diagnostic report.", "GameFontNormalSmall", 160, -541, 236, "LEFT")
    drawer.supportHintR59:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    self.ui.actionCenterMode = "ALL"
    self.ui.actionCenterOffset = 0
    self.ui.actionCenterDrawer = drawer
    if self.LayoutShellDrawers180 then self:LayoutShellDrawers180("action-build") end
end

function OTLGM:RefreshActionCenter()
    if self.runtime and self.runtime.drawerDataRefresh180 then self.runtime.drawerDataRefresh180.actionCenter = nil end
    self:BuildActionCenterDrawer()
    local drawer = self.ui.actionCenterDrawer
    local entries = self:GetActionCenterEntries180(self.ui.actionCenterMode)
    local maximum = math.max(0, table.getn(entries) - drawer.visibleRowCount)
    local offset = math.max(0, math.min(maximum, tonumber(self.ui.actionCenterOffset) or 0))
    self.ui.actionCenterOffset = offset
    drawer.otlMaximumOffset = maximum
    if drawer.scroll.SetScrollMetrics180 then
        drawer.scroll:SetScrollMetrics180(table.getn(entries), drawer.visibleRowCount, offset)
    else
        drawer.scroll.otlSilent = true
        drawer.scroll:SetMinMaxValues(0, maximum)
        drawer.scroll:SetValue(offset)
        drawer.scroll.otlSilent = nil
    end
    local index
    for index = 1, table.getn(drawer.modeButtons) do
        UI:SetSelected(drawer.modeButtons[index], ({ "ALL", "UNREAD", "ACTION" })[index] == self.ui.actionCenterMode)
    end
    for index = 1, table.getn(drawer.rows) do
        local row = drawer.rows[index]
        local entry = index <= drawer.visibleRowCount and entries[offset + index] or nil
        if entry then
            row.otlEntry = entry
            if entry.supportSeverityR59 == "ERROR" then row.marker:SetTexture(C.red[1], C.red[2], C.red[3], 1)
            elseif entry.supportSeverityR59 == "ATTENTION" then row.marker:SetTexture(C.orange[1], C.orange[2], C.orange[3], 1)
            else row.marker:SetTexture(C.gold[1], C.gold[2], C.gold[3], 1) end
            row.titleText:SetText(Short(entry.title or "Guild activity", 54))
            row.bodyText:SetText(Short(entry.body or "", 64))
            if entry.read then
                row.marker:Hide()
                row.titleText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
                row.bodyText:SetTextColor(C.grey[1] * 0.8, C.grey[2] * 0.8, C.grey[3] * 0.8)
            else
                row.marker:Show()
                row.titleText:SetTextColor(C.white[1], C.white[2], C.white[3])
                row.bodyText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
            end
            row.otlTooltipTitle = entry.targetType and "Members" or "Open source"
            row.otlTooltip = entry.tooltip or "Open the related guild item."
            UI:SetSelected(row, not entry.read)
            row:Show()
        else
            row.otlEntry = nil
            row.marker:Hide()
            row:Hide()
        end
    end
    if table.getn(entries) == 0 then drawer.empty:Show() else drawer.empty:Hide() end
    if maximum > 0 then drawer.scroll:Show() else drawer.scroll:Hide() end
    local unread = self:GetShellUnreadCount180()
    if self.ui.actionCenterBadge then
        if unread > 0 then self.ui.actionCenterBadge.text:SetText(tostring(unread)) self.ui.actionCenterBadge:Show()
        else self.ui.actionCenterBadge:Hide() end
    end
    local incidentR59 = self.runtime and self.runtime.supportIncidentR59 or nil
    if self.ui.actionCenterButton and self.ui.actionCenterButton.SetBackdropBorderColor then
        if incidentR59 and not incidentR59.acknowledged and incidentR59.severity == "ERROR" then
            self.ui.actionCenterButton:SetBackdropBorderColor(C.red[1], C.red[2], C.red[3], 1)
        elseif incidentR59 and not incidentR59.acknowledged then
            self.ui.actionCenterButton:SetBackdropBorderColor(C.orange[1], C.orange[2], C.orange[3], 1)
        else
            self.ui.actionCenterButton:SetBackdropBorderColor(C.goldDark[1], C.goldDark[2], C.goldDark[3], 1)
        end
    end
end

function OTLGM:ToggleActionCenter()
    self:RefreshActionCenter()
    if self.ui.drawerHost:IsVisible() and self.ui.activeDrawer == self.ui.actionCenterDrawer then
        self:CloseShellDrawer()
    else
        self:ShowShellDrawer(self.ui.actionCenterDrawer)
    end
end

function OTLGM:OpenActionCenterFiltered180(mode)
    self:BuildActionCenterDrawer()
    self.ui.actionCenterMode = mode == "UNREAD" and "UNREAD" or mode == "ACTION" and "ACTION" or "ALL"
    self.ui.actionCenterOffset = 0
    self:RefreshActionCenter()
    return self:ShowShellDrawer(self.ui.actionCenterDrawer)
end

local function AddonPresenceAge(owner, timestamp)
    local age = math.max(0, owner:Now() - (tonumber(timestamp) or 0))
    if age < 60 then return "seen now" end
    if age < 3600 then return tostring(math.floor(age / 60)) .. "m ago" end
    if age < 86400 then return tostring(math.floor(age / 3600)) .. "h ago" end
    return tostring(math.floor(age / 86400)) .. "d ago"
end

local function AddonVersionLabel(info)
    if not info or not info.version or info.version == "" or info.version == "Detected" then return "version unknown" end
    return "v" .. PublicVersion(info.version)
end

function OTLGM:BuildAddonUsersDrawer()
    if self.ui.addonUsersDrawer then return end
    local drawer = UI:Drawer(self.ui.drawerHost, 430, 576)
    drawer:SetPoint("TOPRIGHT", self.ui.drawerHost, "TOPRIGHT", -10, -10)
    drawer.otlUsesSharedDrawerHost = true
    drawer.otlScrollable = true
    drawer.title = MakeLabel(drawer, "Sharing Status", "GameFontNormalLarge", 18, -18, 320, "LEFT")
    drawer.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    drawer.close = UI:IconButton(drawer, "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 28, 28, function()
        OTLGM:CloseShellDrawer()
    end, "Close", "utility")
    drawer.close:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -12, -12)
    drawer.subtitle = MakeLabel(drawer, "Guild members using the addon now or recently.", "GameFontNormalSmall", 18, -48, 286, "LEFT")
    drawer.subtitle:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    drawer.refresh = UI:Button(drawer, "Check now", 104, 26, function() OTLGM:StartAddonUsersCheck180() end, "inline")
    drawer.refresh:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -18, -44)

    drawer.summary = {}
    local summaryDefs = {
        { key = "Online", label = "Online now" },
        { key = "Current", label = "Up to date\nonline" },
        { key = "Outdated", label = "Outdated\nonline" },
        { key = "Recent", label = "Seen in 24h" },
    }
    local summaryIndex
    for summaryIndex = 1, table.getn(summaryDefs) do
        local definition = summaryDefs[summaryIndex]
        local card = UI:Card(drawer, 94, 42)
        card:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18 + ((summaryIndex - 1) * 99), -78)
        card.value = MakeLabel(card, "0", "GameFontNormal", 8, -7, 78, "CENTER")
        card.value:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
        card.label = MakeLabel(card, definition.label, "GameFontNormalSmall", 4, -24, 86, "CENTER")
        card.label:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        drawer.summary[definition.key] = card
    end

    drawer.filters = {}
    local filters = { { "ONLINE", "Online" }, { "OUTDATED", "Outdated" }, { "RECENT", "Recent" } }
    local filterIndex
    for filterIndex = 1, table.getn(filters) do
        local capturedFilter = filters[filterIndex][1]
        local button = UI:FilterChip(drawer, filters[filterIndex][2], 112, function()
            OTLGM.ui.addonUsersFilter = capturedFilter
            OTLGM.ui.addonUsersOffset = 0
            OTLGM:RefreshAddonUsersDrawer()
        end)
        button:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18 + ((filterIndex - 1) * 120), -130)
        drawer.filters[capturedFilter] = button
    end

    drawer.rows = {}
    drawer.visibleRowCount = 8
    drawer.rowPoolCount180 = 12
    local index
    for index = 1, drawer.rowPoolCount180 do
        local capturedIndex = index
        local row = UI:Card(drawer, 374, 40)
        row:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -166 - ((capturedIndex - 1) * 43))
        row.nameText = MakeLabel(row, "", "GameFontNormalSmall", 9, -6, 354, "LEFT")
        row.metaText = MakeLabel(row, "", "GameFontNormalSmall", 9, -22, 354, "LEFT")
        row.metaText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        row:EnableMouse(true)
        row.otlInteractiveContent = true
        row:SetScript("OnMouseUp", function()
            local entry = this.otlEntry
            if not entry then return end
            if entry.versionGroup then
                OTLGM.ui.addonUsersExpandedVersions = OTLGM.ui.addonUsersExpandedVersions or {}
                OTLGM.ui.addonUsersExpandedVersions[entry.expandKey] =
                    not OTLGM.ui.addonUsersExpandedVersions[entry.expandKey]
                OTLGM:RefreshAddonUsersDrawer()
            elseif entry.name and OTLGM.WhisperMember then
                OTLGM:WhisperMember(entry.name)
            end
        end)
        row:Hide()
        drawer.rows[capturedIndex] = row
    end

    drawer.scroll = UI:Scrollbar(drawer, 340, function(value)
        OTLGM.ui.addonUsersOffset = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
        OTLGM:RefreshAddonUsersDrawer()
    end)
    drawer.scroll:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -14, -166)
    drawer.copy = UI:Button(drawer, "Copy Outdated List", 160, 26, function()
        local records = OTLGM:GetAddonUsersCategorized180()
        local lines = {}
        local itemIndex
        for itemIndex = 1, table.getn(records.outdated) do
            local info = records.outdated[itemIndex]
            table.insert(lines, tostring(info.name or "Unknown") .. "  " .. AddonVersionLabel(info))
        end
        OTLGM:ShowCopyDialog("Players Using Older Versions",
            table.getn(lines) > 0 and table.concat(lines, "\n") or "No outdated addon users detected.")
    end, "utility")
    drawer.copy.otlTooltipTitle = "Copy Outdated List"
    drawer.copy.otlTooltip = "Copies the players detected with an outdated addon version so leadership can remind them to update."
    drawer.copy:SetPoint("BOTTOMLEFT", drawer, "BOTTOMLEFT", 18, 14)
    drawer:EnableMouseWheel(true)
    drawer:SetScript("OnMouseWheel", function()
        local maximum = tonumber(this.otlMaximumOffset) or 0
        local nextOffset = math.max(0, math.min(maximum, (OTLGM.ui.addonUsersOffset or 0) - ((tonumber(arg1) or 0) * 3)))
        OTLGM.ui.addonUsersOffset = nextOffset
        this.scroll.otlSilent = true
        this.scroll:SetValue(nextOffset)
        this.scroll.otlSilent = nil
        OTLGM:RefreshAddonUsersDrawer()
    end)
    self.ui.addonUsersOffset = 0
    self.ui.addonUsersFilter = "ONLINE"
    self.ui.addonUsersExpandedVersions = {}
    self.ui.addonUsersDrawer = drawer
    if self.LayoutShellDrawers180 then self:LayoutShellDrawers180("addon-build") end
end

function OTLGM:GetAddonUsersCategorized180()
    local list = self.GetDetectedAddonUserList and self:GetDetectedAddonUserList(7 * 86400) or {}
    local online, current, outdated, recent = {}, {}, {}, {}
    local upToDateOnline, outdatedOnline, seen24h = {}, {}, {}
    local hiddenLowLevelOffline = 0
    local now = self:Now()
    local index, info
    for index = 1, table.getn(list) do
        info = list[index]
        local isOlder = info.version and info.version ~= "Detected"
            and self.IsVersionNewer and self:IsVersionNewer(self.version, info.version)
        info.otlOlderVersion = isOlder and true or false
        local staleLowLevel = not info.online and (tonumber(info.level) or 0) > 0
            and (tonumber(info.level) or 0) <= 10 and now - (tonumber(info.ts) or 0) > 86400
        if staleLowLevel then
            hiddenLowLevelOffline = hiddenLowLevelOffline + 1
        else
            if info.online then table.insert(online, info) end
            if isOlder then table.insert(outdated, info)
            elseif info.version and PublicVersion(info.version) == PublicVersion(self.version) then
                table.insert(current, info)
            end
            if not info.online then table.insert(recent, info) end
            if info.online and isOlder then table.insert(outdatedOnline, info) end
            if info.online and not isOlder and info.version and PublicVersion(info.version) == PublicVersion(self.version) then table.insert(upToDateOnline, info) end
            if info.online or now - (tonumber(info.ts) or 0) <= 86400 then table.insert(seen24h, info) end
        end
    end
    return {
        all = list, online = online, current = current, outdated = outdated, recent = recent,
        upToDateOnline = upToDateOnline, outdatedOnline = outdatedOnline, seen24h = seen24h,
        hiddenLowLevelOffline = hiddenLowLevelOffline,
    }
end

function OTLGM:GetAddonUsersDrawerEntries()
    local data = self:GetAddonUsersCategorized180()
    local filter = self.ui.addonUsersFilter or "ONLINE"
    local records = filter == "OUTDATED" and data.outdated or (filter == "RECENT" and data.recent or data.online)
    if filter == "ONLINE" then
        table.sort(records, function(a, b)
            local rankA, rankB = tonumber(a.rankIndex) or 99, tonumber(b.rankIndex) or 99
            if rankA ~= rankB then return rankA < rankB end
            return string.lower(tostring(a.name or "")) < string.lower(tostring(b.name or ""))
        end)
        local entries = {}
        for index = 1, table.getn(records) do table.insert(entries, records[index]) end
        if table.getn(entries) == 0 then table.insert(entries, { empty = true, label = "No other addon users detected online." }) end
        return entries, data
    end
    if filter == "RECENT" then
        table.sort(records, function(a, b)
            if (tonumber(a.ts) or 0) ~= (tonumber(b.ts) or 0) then return (tonumber(a.ts) or 0) > (tonumber(b.ts) or 0) end
            return string.lower(tostring(a.name or "")) < string.lower(tostring(b.name or ""))
        end)
        local entries = {}
        for index = 1, table.getn(records) do table.insert(entries, records[index]) end
        if table.getn(entries) == 0 then table.insert(entries, { empty = true, label = "No recently seen offline users." }) end
        return entries, data
    end
    local grouped, versions = {}, {}
    local index
    for index = 1, table.getn(records) do
        local info = records[index]
        local version = AddonVersionLabel(info)
        if not grouped[version] then grouped[version] = {} table.insert(versions, version) end
        table.insert(grouped[version], info)
    end
    local currentVersion = PublicVersion(self.version)
    local function VersionRank180(versionLabel)
        local recordsForVersion = grouped[versionLabel] or {}
        local sample = recordsForVersion[1]
        if sample and sample.version and PublicVersion(sample.version) == currentVersion then return 1 end
        if not sample or not sample.otlOlderVersion then return 2 end
        return 3
    end
    table.sort(versions, function(a, b)
        local rankA, rankB = VersionRank180(a), VersionRank180(b)
        if rankA ~= rankB then return rankA < rankB end
        return string.lower(a) < string.lower(b)
    end)
    for _, versionLabel in ipairs(versions) do
        table.sort(grouped[versionLabel], function(a, b)
            if a.online ~= b.online then return a.online and true or false end
            if (tonumber(a.ts) or 0) ~= (tonumber(b.ts) or 0) then return (tonumber(a.ts) or 0) > (tonumber(b.ts) or 0) end
            return string.lower(a.name or "") < string.lower(b.name or "")
        end)
    end
    local entries = {}
    if table.getn(records) == 0 then
        local emptyText = filter == "OUTDATED" and "No outdated addon users detected."
            or (filter == "RECENT" and "No recently seen offline users." or "No other addon users detected online.")
        table.insert(entries, { empty = true, label = emptyText })
        return entries, data
    end
    for index = 1, table.getn(versions) do
        local version = versions[index]
        local expandKey = filter .. ":" .. version
        if self.ui.addonUsersExpandedVersions[expandKey] == nil then
            self.ui.addonUsersExpandedVersions[expandKey] = true
        end
        table.insert(entries, {
            versionGroup = true,
            expandKey = expandKey,
            label = version,
            count = table.getn(grouped[version]),
        })
        if self.ui.addonUsersExpandedVersions[expandKey] then
            local recordIndex
            for recordIndex = 1, table.getn(grouped[version]) do
                table.insert(entries, grouped[version][recordIndex])
            end
        end
    end
    return entries, data
end

function OTLGM:RefreshAddonUsersDrawer()
    if self.runtime and self.runtime.drawerDataRefresh180 then self.runtime.drawerDataRefresh180.addonUsers = nil end
    self:BuildAddonUsersDrawer()
    local drawer = self.ui.addonUsersDrawer
    local entries, data = self:GetAddonUsersDrawerEntries()
    drawer.summary.Online.value:SetText(tostring(table.getn(data.online)))
    drawer.summary.Current.value:SetText(tostring(table.getn(data.upToDateOnline or {})))
    drawer.summary.Outdated.value:SetText(tostring(table.getn(data.outdatedOnline or {})))
    drawer.summary.Recent.value:SetText(tostring(table.getn(data.seen24h or {})))
    local filterKey
    for filterKey, button in pairs(drawer.filters) do
        UI:SetSelected(button, filterKey == (self.ui.addonUsersFilter or "ONLINE"))
    end
    local maximum = math.max(0, table.getn(entries) - drawer.visibleRowCount)
    local offset = math.max(0, math.min(maximum, tonumber(self.ui.addonUsersOffset) or 0))
    self.ui.addonUsersOffset = offset
    drawer.otlMaximumOffset = maximum
    if drawer.scroll.SetScrollMetrics180 then
        drawer.scroll:SetScrollMetrics180(table.getn(entries), drawer.visibleRowCount, offset)
    else
        drawer.scroll.otlSilent = true
        drawer.scroll:SetMinMaxValues(0, maximum)
        drawer.scroll:SetValue(offset)
        drawer.scroll.otlSilent = nil
    end
    local checking = self.runtime and self.runtime.shellAddonCheckingUntil
        and self:Now() < self.runtime.shellAddonCheckingUntil
    local hiddenLow = tonumber(data.hiddenLowLevelOffline) or 0
    local hiddenSuffix = hiddenLow > 0 and ("  •  " .. tostring(hiddenLow) .. " low-level older offline hidden") or ""
    drawer.subtitle:SetText((checking and "Checking addon presence…" or "Guild members using the addon now or recently.") .. hiddenSuffix)
    UI:SetText(drawer.refresh, "Check now")
    UI:SetEnabled(drawer.refresh, not checking, "A presence check is already in progress.")

    local index
    for index = 1, drawer.visibleRowCount do
        local row = drawer.rows[index]
        local entry = entries[offset + index]
        if not entry then
            row.otlEntry = nil
            row:Hide()
        elseif entry.versionGroup then
            row.otlEntry = entry
            local expanded = self.ui.addonUsersExpandedVersions[entry.expandKey]
            row.nameText:SetText((expanded and "−  " or "+  ") .. tostring(entry.label)
                .. "  (" .. tostring(entry.count or 0) .. ")")
            row.nameText:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
            row.metaText:SetText(expanded and "Click to collapse" or "Click to show names")
            row:Show()
        elseif entry.empty then
            row.otlEntry = entry
            row.nameText:SetText(tostring(entry.label or "No users in this section."))
            row.nameText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
            row.metaText:SetText("")
            row:Show()
        else
            row.otlEntry = entry
            row.nameText:SetText(self:GetClassColor(entry.class) .. tostring(entry.name or "Unknown") .. self.colors.reset)
            row.nameText:SetTextColor(C.white[1], C.white[2], C.white[3])
            local state = entry.online and "Online" or AddonPresenceAge(self, entry.ts)
            local rank = tostring(entry.rank or entry.rankName or "Member")
            row.metaText:SetText(rank .. "  •  " .. AddonVersionLabel(entry) .. "  •  " .. state .. "  •  click to whisper")
            row:Show()
        end
    end
    for index = drawer.visibleRowCount + 1, table.getn(drawer.rows) do
        drawer.rows[index].otlEntry = nil
        drawer.rows[index]:Hide()
    end
    if maximum > 0 then drawer.scroll:Show() else drawer.scroll:Hide() end
    local canCopy = self.CanPublishAnnouncement152 and self:CanPublishAnnouncement152()
    if (self.ui.addonUsersFilter or "ONLINE") == "OUTDATED" and canCopy and table.getn(data.outdated or {}) > 0 then drawer.copy:Show()
    else drawer.copy:Hide() end
end

function OTLGM:ToggleAddonUsersDrawer()
    self:BuildAddonUsersDrawer()
    if self.ui.drawerHost:IsVisible() and self.ui.activeDrawer == self.ui.addonUsersDrawer then
        self:CloseShellDrawer()
        return
    end
    self.ui.addonUsersOffset = 0
    self.ui.addonUsersFilter = self.ui.addonUsersFilter or "ONLINE"
    self:RefreshAddonUsersDrawer()
    self:ShowShellDrawer(self.ui.addonUsersDrawer)
    self:StartAddonUsersCheck180()
end

function OTLGM:BuildPlayerMenus()
    if self.ui.playerMenu then return end
    local catcher = CreateFrame("Button", nil, UIParent)
    if self.PrepareInteractiveControl170 then self:PrepareInteractiveControl170(catcher, "button") end
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("TOOLTIP")
    catcher:SetFrameLevel(180)
    catcher:EnableMouse(true)
    -- Mouse catchers must never own the keyboard. In Vanilla clients a visible
    -- keyboard-enabled full-screen Button can swallow movement keys (WASD,
    -- jump) even though the addon is only being viewed while travelling.
    catcher:EnableKeyboard(false)
    catcher:SetScript("OnClick", function() OTLGM:CloseShellContextMenus() end)
    catcher:Hide()
    self.ui.contextMenuCatcher = catcher
    local menu = UI:ContextMenu(UIParent, 190, 234)
    menu:SetFrameLevel(catcher:GetFrameLevel() + 2)
    local entries = {
        { label = "Whisper", icon = "Interface\\Icons\\INV_Letter_15", action = function(name) OTLGM:WhisperMember(name) end },
        { label = "Invite", icon = "Interface\\Icons\\INV_Misc_GroupLooking", action = function(name) OTLGM:InviteMemberToGroup(name) end },
        { label = "Mention", icon = "Interface\\Icons\\INV_Misc_Note_01", action = function(name)
            OTLGM:ShowPage("guildchat")
            if OTLGM.InsertGuildChatName then OTLGM:InsertGuildChatName(name) end
        end },
        { label = "Open Guild Profile", icon = "Interface\\Icons\\INV_Misc_Book_09", action = function(name)
            OTLGM:ShowPage("roster")
            OTLGM:SelectRosterMember(name)
            local profile184 = OTLGM.ui and OTLGM.ui.guildProfile183 or nil
            local same184 = profile184 and profile184.IsVisible and profile184:IsVisible() and OTLGM.NormalizeName
                and OTLGM:NormalizeName(profile184.otlMemberName183) == OTLGM:NormalizeName(name)
            if not same184 and OTLGM.OpenGuildMemberProfile183 then OTLGM:OpenGuildMemberProfile183(name, "player-menu", false) end
        end },
        { label = "Main / Alt", icon = "Interface\\Icons\\INV_Misc_GroupLooking", action = function(name)
            if OTLGM.OpenCharacterIdentityForMember184 then OTLGM:OpenCharacterIdentityForMember184(name)
            elseif OTLGM.OpenGuildMemberProfile183 then OTLGM:OpenGuildMemberProfile183(name, "player-menu-characters", false) end
        end },
        { label = "More", icon = "Interface\\Icons\\INV_Misc_EngGizmos_17", more = true },
    }
    menu.buttons = {}
    local index
    for index = 1, table.getn(entries) do
        local captured = index
        local definition = entries[captured]
        local button = UI:Button(menu, definition.label, 168, 30, function()
            local activeName = menu.otlPlayerName
            if definition.more then
                OTLGM:TogglePlayerOfficerMenu(activeName, menu)
            else
                OTLGM:CloseShellContextMenus()
                definition.action(activeName)
            end
        end, "inline")
        button:SetPoint("TOPLEFT", menu, "TOPLEFT", 11, -10 - ((captured - 1) * 36))
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetTexture(definition.icon)
        button.icon:SetWidth(16)
        button.icon:SetHeight(16)
        button.icon:SetPoint("LEFT", button, "LEFT", 8, 0)
        button.text:ClearAllPoints()
        button.text:SetPoint("LEFT", button, "LEFT", 31, 0)
        button.text:SetWidth(128)
        button.text:SetJustifyH("LEFT")
        menu.buttons[captured] = button
    end

    local officer = UI:ContextMenu(UIParent, 190, 180)
    officer:SetFrameLevel(catcher:GetFrameLevel() + 4)
    officer.buttons = {}
    local officerEntries = {
        { label = "Recent History", style = "inline", action = function(name) OTLGM:OpenRosterHistory(name) end },
        { label = "Promote", style = "inline", action = function(name) OTLGM:StartRosterRankAction180("PROMOTE", name) end },
        { label = "Demote", style = "inline", action = function(name) OTLGM:StartRosterRankAction180("DEMOTE", name) end },
        { label = "Remove from Guild", style = "danger", action = function(name)
            OTLGM:ShowConfirm("Remove " .. tostring(name) .. "?", "This asks the game client to remove the selected member from the guild. The action cannot be undone by the addon.", "Remove", function() OTLGM:RemoveMember(name) end)
        end },
    }
    for index = 1, table.getn(officerEntries) do
        local captured = index
        local definition = officerEntries[captured]
        local button = UI:Button(officer, definition.label, 168, 30, function()
            local activeName = officer.otlPlayerName
            OTLGM:CloseShellContextMenus()
            definition.action(activeName)
        end, definition.style)
        button:SetPoint("TOPLEFT", officer, "TOPLEFT", 11, -10 - ((captured - 1) * 36))
        officer.buttons[captured] = button
    end
    self.ui.playerMenu = menu
    self.ui.playerOfficerMenu = officer
end

function OTLGM:OpenPlayerMenu(name, owner, x, y)
    if not name or name == "" then return end
    self:BuildPlayerMenus()
    self:CloseShellContextMenus()
    local menu = self.ui.playerMenu
    menu.otlPlayerName = name
    local cursorX, cursorY = x, y
    if (not cursorX or not cursorY) and GetCursorPosition then cursorX, cursorY = GetCursorPosition() end
    if (not cursorX or not cursorY) and owner and owner.GetCenter then cursorX, cursorY = owner:GetCenter() end
    UI:PlaceContextMenu(menu, cursorX or 20, cursorY or 220)
    self.ui.contextMenuCatcher:Show()
    RaiseShellTree(menu, self.ui.contextMenuCatcher:GetFrameLevel() + 2, 0)
    menu:Show()
end

function OTLGM:TogglePlayerOfficerMenu(name, parentMenu)
    local menu = self.ui.playerOfficerMenu
    if menu:IsVisible() then menu:Hide() return end
    menu.otlPlayerName = name
    local member = self.GetMember and self:GetMember(name) or nil
    local allowedPromote = self.CanUseOfficerActionForMember170 and self:CanUseOfficerActionForMember170("PROMOTE", member)
    local allowedDemote = self.CanUseOfficerActionForMember170 and self:CanUseOfficerActionForMember170("DEMOTE", member)
    local allowedRemove = self.CanUseOfficerActionForMember170 and self:CanUseOfficerActionForMember170("REMOVE", member)
    UI:SetEnabled(menu.buttons[2], allowedPromote and true or false, "Your rank cannot promote this member.")
    UI:SetEnabled(menu.buttons[3], allowedDemote and true or false, "Your rank cannot demote this member.")
    UI:SetEnabled(menu.buttons[4], allowedRemove and true or false, "Your rank cannot remove this member.")
    local left = (parentMenu and parentMenu.otlClampedX or 20) + (parentMenu and parentMenu:GetWidth() or 190) + 4
    local fallbackLeft = (parentMenu and parentMenu.otlClampedX or 20) - menu:GetWidth() - 4
    local top = parentMenu and parentMenu.otlClampedY or 220
    local scale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    UI:PlaceContextMenu(menu, left * scale, top * scale, fallbackLeft * scale)
    RaiseShellTree(menu, self.ui.contextMenuCatcher:GetFrameLevel() + 4, 0)
    menu:Show()
end

function OTLGM:OpenRosterHistory(name)
    local records = self.GetMemberRecentHistory and self:GetMemberRecentHistory(name, 8) or {}
    local lines = {}
    local index
    for index = 1, table.getn(records) do
        local record = records[index]
        table.insert(lines, self:Stamp(record.ts) .. "  " .. tostring(record.kind or "EVENT") .. "  " .. tostring(record.detail or ""))
    end
    if table.getn(lines) == 0 then table.insert(lines, "No stored history for this member.") end
    self:ShowNotice("Recent History: " .. tostring(name), table.concat(lines, "\n"))
end

function OTLGM:EnsureShellPage(pageKey)
    if not self.ui or not self.ui.pages then return nil end
    local existing = self.ui.pages[pageKey]
    if existing and not existing.otlLazyShell then return existing end
    local module = self.shellPageModules[pageKey]
    if not module then return nil end
    local page = module:Build(self.ui.contentHost)
    if not page then return nil end
    page.otlPageModule = module
    self.ui.pages[pageKey] = page
    page.otlBuilt = true
    local width = self.ui.contentHost:GetWidth()
    local height = self.ui.contentHost:GetHeight()
    module:Layout(width, height)
    self.runtime = self.runtime or {}
    self.runtime.shellLazyBuilds = self.runtime.shellLazyBuilds or {}
    self.runtime.shellLazyBuilds[pageKey] = (self.runtime.shellLazyBuilds[pageKey] or 0) + 1
    return page
end

local function BeginShellPerformance180(owner)
    if not owner or type(owner.BeginPerformanceSample180) ~= "function" then return nil end
    local ok, value = pcall(owner.BeginPerformanceSample180, owner)
    if ok then return value end
    if owner.RecordInternalIssueRC3 then pcall(owner.RecordInternalIssueRC3, owner, "Diagnostics/SHELL_PERF_BEGIN", value) end
    return nil
end

local function EndShellPerformance180(owner, label, started)
    if not owner or not started or type(owner.EndPerformanceSample180) ~= "function" then return end
    local ok, problem = pcall(owner.EndPerformanceSample180, owner, label, started)
    if not ok and owner.RecordInternalIssueRC3 then pcall(owner.RecordInternalIssueRC3, owner, "Diagnostics/SHELL_PERF_END", problem) end
end

function OTLGM:LayoutShellPage180(pageKey, reason)
    local module = self.shellPageModules and self.shellPageModules[pageKey]
    if not module or not module.root or not self.ui or not self.ui.contentHost then return false end
    local width = tonumber(self.ui.contentHost:GetWidth()) or 0
    local height = tonumber(self.ui.contentHost:GetHeight()) or 0
    local revision = self.runtime and self.runtime.layoutRevision180 or 0
    local signatureR26 = tostring(math.floor((width * 10) + 0.5)) .. ":" .. tostring(math.floor((height * 10) + 0.5)) .. ":" .. tostring(revision)
    local repeatSafeR26 = reason == "show" or reason == "chrome"
    if repeatSafeR26 and module.layoutSignatureR26 == signatureR26 then
        self.runtime = self.runtime or {}
        self.runtime.layoutSkipsR26 = (tonumber(self.runtime.layoutSkipsR26) or 0) + 1
        module.lastLayoutReason = tostring(reason or "layout") .. ":cached"
        return true
    end
    local started = BeginShellPerformance180(self)
    module.lastLayoutReason = reason
    local ok, problem = pcall(module.Layout, module, width, height)
    EndShellPerformance180(self, "layout passes", started)
    if not ok then error(problem) end
    module.layoutSignatureR26 = signatureR26
    return true
end

function OTLGM:LayoutAllShellPages180(reason)
    if not self.shellPageModules then return end
    local pageKey, module
    for pageKey, module in pairs(self.shellPageModules) do
        if module and module.root then
            -- A responsive defect in one hidden page must not abort geometry for
            -- every other page. The visible-page path remains strict, while a
            -- full preset/rebase pass isolates and reports each hidden module.
            local ok, problem = pcall(self.LayoutShellPage180, self, pageKey, reason)
            if not ok and self.RecordInternalIssueRC3 then
                pcall(self.RecordInternalIssueRC3, self, "UI/LAYOUT_" .. string.upper(tostring(pageKey)), problem)
            end
        end
    end
end

function OTLGM:MarkPageDirty180(pageKey)
    pageKey = tostring(pageKey or "")
    if pageKey == "" then return false end
    self.runtime = self.runtime or {}
    self.runtime.pageDirtyR5 = self.runtime.pageDirtyR5 or {}
    self.runtime.pageDirtyR5[pageKey] = true
    return true
end

function OTLGM:CanRefreshShellPage180(pageKey)
    if not self.ui or not self.ui.main then return true end
    if self.ui.main:IsVisible() and self.ui.currentPage == pageKey then
        if self.runtime and self.runtime.pageDirtyR5 then self.runtime.pageDirtyR5[pageKey] = nil end
        return true
    end
    self.runtime = self.runtime or {}
    self.runtime.pageDirtyR5 = self.runtime.pageDirtyR5 or {}
    self.runtime.pageDirtyR5[pageKey] = true
    if self.release176r5 then
        self.release176r5.hiddenRefreshesSkipped = (tonumber(self.release176r5.hiddenRefreshesSkipped) or 0) + 1
    end
    return false
end

function OTLGM:RefreshHeaderOnlineIndicator183()
    local indicator = self.ui and self.ui.headerOnline183
    if not indicator or not indicator.text then return false end
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local scanned = tonumber(db and db.lastScan) or 0
    if scanned <= 0 then
        indicator.text:SetText("— Online")
        if indicator.dot then indicator.dot:SetTexture(0.42, 0.42, 0.42, 1) end
        indicator.otlCached183 = true
        indicator.otlSnapshotAge183 = nil
        return true
    end
    local online = math.max(0, tonumber(db and db.lastOnline) or 0)
    local presenceAtR59 = tonumber(self.runtime and self.runtime.rosterPresenceLastAtR59) or 0
    local onlineFreshAtR59 = math.max(scanned, presenceAtR59)
    local age = math.max(0, self:Now() - onlineFreshAtR59)
    local interval = math.max(600, tonumber(OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.scanInterval) or 1200)
    local stale = age > math.max(3600, interval * 3)
    indicator.text:SetText(tostring(online) .. " Online")
    if indicator.dot then
        if stale then indicator.dot:SetTexture(0.56, 0.56, 0.56, 1)
        else indicator.dot:SetTexture(0.34, 0.86, 0.42, 1) end
    end
    indicator.otlCached183 = stale and true or nil
    indicator.otlSnapshotAge183 = age
    return true
end

function OTLGM:GetHeaderOnlineSupportSummary183()
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local scanned = tonumber(db and db.lastScan) or 0
    if scanned <= 0 then return "Header online: unknown / no successful saved roster update" end
    local presenceAtR59 = tonumber(self.runtime and self.runtime.rosterPresenceLastAtR59) or 0
    local age = math.max(0, self:Now() - math.max(scanned, presenceAtR59))
    local sourceR59 = presenceAtR59 > scanned and "presence" or "full-scan"
    return "Header online: " .. tostring(tonumber(db and db.lastOnline) or 0)
        .. "/" .. tostring(tonumber(db and db.lastTotal) or 0)
        .. " / online age " .. tostring(math.floor(age)) .. "s / " .. sourceR59
end

function OTLGM:RefreshShellPage(pageKey, reason)
    local module = self.shellPageModules and self.shellPageModules[pageKey]
    if not module then return false end
    self.runtime = self.runtime or {}
    if self.runtime.layoutDataRefresh180 then self.runtime.layoutDataRefresh180[pageKey] = nil end
    if pageKey == "guildchat" and self.ui then self.ui.chatRefreshPending180 = nil end
    self.runtime.uiRefreshMetrics180 = self.runtime.uiRefreshMetrics180 or { total = 0, pages = {}, reasons = {} }
    local metrics = self.runtime.uiRefreshMetrics180
    local revision = tostring(self.runtime.layoutRevision180 or 0) .. ":"
        .. tostring(self.runtime.pageRevision180 and self.runtime.pageRevision180[pageKey] or 0)
    local function perform()
        metrics.total = (tonumber(metrics.total) or 0) + 1
        metrics.pages[pageKey] = (tonumber(metrics.pages[pageKey]) or 0) + 1
        metrics.reasons[tostring(reason or "refresh")] = (tonumber(metrics.reasons[tostring(reason or "refresh")]) or 0) + 1
        metrics.lastPage = pageKey
        metrics.lastReason = tostring(reason or "refresh")
        metrics.lastAt = self:Now()
        local started = BeginShellPerformance180(self)
        local refreshOk, refreshProblem = pcall(module.Refresh, module, reason or "refresh")
        local perfLabelR26
        if pageKey == "activity" then
            perfLabelR26 = "Activity processing"
        elseif pageKey == "settings" then
            perfLabelR26 = "visible-page refresh:settings-" .. string.lower(tostring(self.ui and self.ui.settingsShellTab or "interface"))
        else
            perfLabelR26 = "visible-page refresh:" .. tostring(pageKey)
        end
        EndShellPerformance180(self, perfLabelR26, started)
        if not refreshOk then error(refreshProblem) end
        return true
    end
    if self.SafeRefreshPage180 then return self:SafeRefreshPage180(pageKey, revision, perform) end
    return perform()
end

function OTLGM:RefreshNavigation()
    if not self.ui or not self.ui.shellBuilt then return end
    local officerAllowed = self.IsOfficerMode and self:IsOfficerMode() or false
    local currentDefinition = self:GetShellPageDefinition(self.ui.currentPage)
    if currentDefinition and currentDefinition.officer and not officerAllowed then
        if self.RefreshQuickDockPermissions182 then self:RefreshQuickDockPermissions182(officerAllowed) end
        self:ShowPage("home")
        return
    end
    local navMode = OTLGM_DB.settings.shellNavMode == "OFFICER" and officerAllowed and "OFFICER" or "GUILD"
    OTLGM_DB.settings.shellNavMode = navMode
    if officerAllowed then
        self.ui.navGuildButton:SetWidth(78)
        self.ui.navGuildButton:Show()
        self.ui.navOfficerButton:Show()
    else
        self.ui.navGuildButton:SetWidth(164)
        self.ui.navGuildButton:Show()
        self.ui.navOfficerButton:Hide()
    end
    UI:SetSelected(self.ui.navGuildButton, navMode == "GUILD")
    UI:SetSelected(self.ui.navOfficerButton, navMode == "OFFICER")

    -- r42: Build the unread snapshot once per navigation refresh.
    -- GetShellUnreadCount180 historically rebuilt Action Center entries for
    -- every navigation button, which made roster-post-commit-small scale with
    -- the number of pages instead of with one inbox pass.
    local unreadEntriesR42 = self:GetActionCenterEntries180("UNREAD")
    local unreadByPageR42 = {}
    local unreadTotalR42 = 0
    local unreadIndexR42
    for unreadIndexR42 = 1, table.getn(unreadEntriesR42 or {}) do
        local unreadEntryR42 = unreadEntriesR42[unreadIndexR42]
        local unreadPageR42 = unreadEntryR42 and unreadEntryR42.targetPage or nil
        unreadTotalR42 = unreadTotalR42 + 1
        if unreadPageR42 then
            unreadByPageR42[unreadPageR42] = (tonumber(unreadByPageR42[unreadPageR42]) or 0) + 1
        end
    end

    local y = -76
    local index
    for index = 1, table.getn(PAGE_DEFS) do
        local definition = PAGE_DEFS[index]
        local button = self.ui.navButtons[definition.key]
        if button then
            local show = definition.group == "primary"
                or (definition.key == "roster" and (navMode == "GUILD" or (navMode == "OFFICER" and officerAllowed)))
                or (definition.group == "guild" and navMode == "GUILD")
                or (definition.group == "officer" and navMode == "OFFICER" and officerAllowed)
            if show then
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", self.ui.sidebar, "TOPLEFT", 12, y)
                button:Show()
                y = y - 34
            else
                button:Hide()
            end
            UI:SetSelected(button, self.ui.currentPage == definition.key)
            local pageUnread = tonumber(unreadByPageR42[definition.key]) or 0
            if button.unreadBadge then
                if pageUnread > 0 then button.unreadBadge.text:SetText(tostring(pageUnread)) button.unreadBadge:Show()
                else button.unreadBadge:Hide() end
            end
        end
    end
    UI:SetSelected(self.ui.settingsButton, self.ui.currentPage == "settings")
    local unread = unreadTotalR42
    if self.ui.actionCenterBadge then
        if unread > 0 then self.ui.actionCenterBadge.text:SetText(tostring(unread)) self.ui.actionCenterBadge:Show()
        else self.ui.actionCenterBadge:Hide() end
    end
    if self.ui.headerDate then self.ui.headerDate:SetText("Server Time (ST) " .. (self.FormatServerClock180 and self:FormatServerClock180(self:Now(), true) or date("%H:%M  %d %b"))) end
    if self.RefreshHeaderOnlineIndicator183 then self:RefreshHeaderOnlineIndicator183() end
    self:RefreshAddonUsersIndicator()
    if self.RefreshQuickDockPermissions182 then self:RefreshQuickDockPermissions182(officerAllowed) end
end

function OTLGM:SetShellNavMode180(nextMode)
    local officerAllowed = self.IsOfficerMode and self:IsOfficerMode() or false
    nextMode = nextMode == "OFFICER" and "OFFICER" or "GUILD"
    if nextMode == "OFFICER" and not officerAllowed then
        self:ShowToast("Officer tools are unavailable for your current guild rank.", "error")
        return
    end
    OTLGM_DB.settings.shellNavMode = nextMode
    local currentDefinition = self:GetShellPageDefinition(self.ui and self.ui.currentPage)
    if nextMode == "OFFICER" and currentDefinition and currentDefinition.group == "guild"
        and currentDefinition.key ~= "roster" then
        self:ShowPage("overview")
        return
    end
    if nextMode == "GUILD" and currentDefinition and currentDefinition.group == "officer" then
        self:ShowPage("home")
        return
    end
    self:RefreshNavigation()
end

function OTLGM:ToggleShellNavMode()
    self:SetShellNavMode180(OTLGM_DB.settings.shellNavMode == "OFFICER" and "GUILD" or "OFFICER")
end

function OTLGM:RequestStaleRosterOnOpen180(pageKey)
    if pageKey ~= "home" and pageKey ~= "roster" and pageKey ~= "overview" then return false end
    if not GetGuildInfo or not GetGuildInfo("player") then return false end
    local settings = OTLGM_DB and OTLGM_DB.settings or {}
    if settings.autoScan == false then return false end
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local now = self:Now()
    local interval = math.max(600, tonumber(settings.scanInterval) or 1200)
    self.runtime = self.runtime or {}
    local age = db and db.lastScan and (now - (tonumber(db.lastScan) or 0)) or interval + 1
    local eventDirty = self.runtime.rosterDataDirty180 and true or false
    if (tonumber(self.runtime.rosterAutoRetryAfterRC3) or 0) > now then return false end
    if (not eventDirty and age < interval) or self.pendingScan or self.runtime.rosterRead180 then return false end
    local pressureState = self.GetClientPressure181 and self:GetClientPressure181() or nil
    if (pressureState and tonumber(pressureState.level) >= 2) or self.runtime.transitionActive176 or (self.IsPerformanceGuardActive181 and self:IsPerformanceGuardActive181()) then
        self.runtime.rosterOpenPressureDeferrals181 = (tonumber(self.runtime.rosterOpenPressureDeferrals181) or 0) + 1
        self.runtime.rosterOpenPressureStarted181 = tonumber(self.runtime.rosterOpenPressureStarted181) or now
        if self.ScheduleAfter180 and now - self.runtime.rosterOpenPressureStarted181 < 30 then
            local capturedPage = pageKey
            self:ScheduleAfter180("roster-open-deferred-scan", 3, function(owner)
                if owner and owner.RequestStaleRosterOnOpen180 then owner:RequestStaleRosterOnOpen180(capturedPage) end
            end, 25)
        else
            -- Allow a later explicit page open to start one new bounded retry
            -- window without keeping this one alive permanently.
            self.runtime.rosterOpenPressureStarted181 = nil
        end
        return false
    end
    self.runtime.rosterOpenPressureStarted181 = nil
    if self.runtime.lastStaleRosterOpen180 and now - self.runtime.lastStaleRosterOpen180 < 15 then return false end
    self.runtime.lastStaleRosterOpen180 = now
    self.runtime.rosterOpenScanRequests180 = (tonumber(self.runtime.rosterOpenScanRequests180) or 0) + 1
    self:RequestScan(eventDirty and "GUILD_EVENT_OPEN" or "STALE_OPEN")
    return self.pendingScan and true or false
end

local function SupportIssueFingerprintR59(source, message)
    local cleanSource = tostring(source or "Addon")
    local cleanMessage = tostring(message or "Unknown error")
    cleanMessage = string.gsub(cleanMessage, "[%c]+", " ")
    cleanMessage = string.sub(cleanMessage, 1, 180)
    return cleanSource .. "|" .. cleanMessage
end

function OTLGM:CaptureSupportIncidentSnapshotR59(source, message)
    self.runtime = self.runtime or {}
    local fps = nil
    if GetFramerate then local ok, value = pcall(GetFramerate) if ok then fps = tonumber(value) end end
    local queue = 0
    if self.GetNetworkQueueDepth then local ok, value = pcall(self.GetNetworkQueueDepth, self) if ok then queue = tonumber(value) or 0 end end
    local zone = GetRealZoneText and GetRealZoneText() or (GetZoneText and GetZoneText() or "unknown")
    local subzone = GetSubZoneText and GetSubZoneText() or ""
    return {
        ts = self:Now(), source = tostring(source or "Addon"), message = tostring(message or "Unknown error"),
        page = tostring(self.ui and self.ui.currentPage or "closed"), zone = tostring(zone or "unknown"), subzone = tostring(subzone or ""),
        combat = self.InCombat and self:InCombat() and true or false, fps = fps, queue = queue,
    }
end

function OTLGM:RaiseSupportIncidentR59(severity, source, message)
    self.runtime = self.runtime or {}
    severity = severity == "ERROR" and "ERROR" or "ATTENTION"
    local now = self:Now()
    local signature = SupportIssueFingerprintR59(source, message)
    self.runtime.supportIssueTrackerR59 = self.runtime.supportIssueTrackerR59 or {}
    self.runtime.supportAcknowledgedR59 = self.runtime.supportAcknowledgedR59 or {}

    -- Keep this diagnostic-only tracker bounded for pathological error strings.
    -- It is runtime-only, but a broken third-party interaction should still not
    -- be able to grow a table for the whole play session.
    local trackerCountR59 = 0
    local trackerKeyR59, trackerValueR59
    for trackerKeyR59, trackerValueR59 in pairs(self.runtime.supportIssueTrackerR59) do
        if now - (tonumber(trackerValueR59 and trackerValueR59.lastAt) or 0) > 900 then
            self.runtime.supportIssueTrackerR59[trackerKeyR59] = nil
        else
            trackerCountR59 = trackerCountR59 + 1
        end
    end
    if trackerCountR59 > 48 then
        local oldestKeyR59, oldestAtR59 = nil, now
        for trackerKeyR59, trackerValueR59 in pairs(self.runtime.supportIssueTrackerR59) do
            local candidateAtR59 = tonumber(trackerValueR59 and trackerValueR59.lastAt) or 0
            if candidateAtR59 <= oldestAtR59 then oldestKeyR59, oldestAtR59 = trackerKeyR59, candidateAtR59 end
        end
        if oldestKeyR59 and oldestKeyR59 ~= signature then self.runtime.supportIssueTrackerR59[oldestKeyR59] = nil end
    end

    local tracker = self.runtime.supportIssueTrackerR59[signature]
    if not tracker or now - (tonumber(tracker.lastAt) or 0) > 90 then
        tracker = { count = 0, firstAt = now, lastAt = now, snapshot = self:CaptureSupportIncidentSnapshotR59(source, message) }
        self.runtime.supportIssueTrackerR59[signature] = tracker
    end
    tracker.count = (tonumber(tracker.count) or 0) + 1
    tracker.lastAt = now
    tracker.source = tostring(source or "Addon")
    tracker.message = tostring(message or "Unknown error")
    if self.runtime.supportAcknowledgedR59[signature] then return false end

    -- Anti-nag gate: routine caught/transient issues stay diagnostic-only until
    -- the same signature repeats three times in a short window. Explicit hard
    -- failures (for example a blocked page refresh) may opt into ERROR and are
    -- surfaced once immediately. No popup or automatic Support opening occurs.
    if severity ~= "ERROR" and tracker.count < 3 then return false end
    local existing = self.runtime.supportIncidentR59
    if existing and existing.signature == signature then
        existing.count = math.max(tonumber(existing.count) or 1, tracker.count)
        existing.lastAt = now
        if severity == "ERROR" then existing.severity = "ERROR" end
        return true
    end
    -- Never let a later amber/repeated issue hide an unacknowledged hard error.
    -- The amber event remains in errorHistoryRC3 and its tracker, but the one
    -- prominent Action Center slot keeps the more important report selected.
    if existing and not existing.acknowledged and existing.severity == "ERROR" and severity ~= "ERROR" then return false end
    self.runtime.supportIncidentR59 = {
        signature = signature, severity = severity, source = tracker.source, message = tracker.message,
        count = tracker.count, firstAt = tracker.firstAt, lastAt = now,
        snapshot = tracker.snapshot or self:CaptureSupportIncidentSnapshotR59(source, message), acknowledged = false,
    }
    if self.RefreshActionCenter then pcall(self.RefreshActionCenter, self) end
    return true
end

function OTLGM:AcknowledgeSupportIncidentR59()
    self.runtime = self.runtime or {}
    local incident = self.runtime.supportIncidentR59
    if not incident then return false end
    self.runtime.supportAcknowledgedR59 = self.runtime.supportAcknowledgedR59 or {}
    self.runtime.supportAcknowledgedR59[tostring(incident.signature or "")] = true
    incident.acknowledged = true
    if self.RefreshActionCenter then pcall(self.RefreshActionCenter, self) end
    return true
end

function OTLGM:GetSupportIncidentActionEntryR59()
    local incident = self.runtime and self.runtime.supportIncidentR59 or nil
    if not incident or incident.acknowledged then return nil end
    local hard = incident.severity == "ERROR"
    local count = math.max(1, tonumber(incident.count) or 1)
    return {
        id = "SUPPORT:R59", ids = {}, ts = tonumber(incident.lastAt) or self:Now(), read = false,
        category = "support", priority = "ACTION", targetPage = "settings", section = "SUPPORT",
        title = hard and "Addon problem detected" or "Repeated addon issue detected",
        body = tostring(incident.source or "Addon") .. (count > 1 and (" • x" .. tostring(count)) or "") .. " • diagnostic report ready",
        tooltip = "Open Support & Report. The addon will not send anything automatically.",
        supportIncidentR59 = true, supportSeverityR59 = hard and "ERROR" or "ATTENTION",
    }
end

function OTLGM:RecordInternalIssueRC3(source, message)
    self.runtime = self.runtime or {}
    self.runtime.errorHistoryRC3 = self.runtime.errorHistoryRC3 or {}
    local text = tostring(message or "Unknown error")
    local now = self:Now()
    local latest = self.runtime.errorHistoryRC3[1]
    if latest and latest.source == tostring(source or "Addon") and latest.message == text and now - (tonumber(latest.ts) or 0) < 2 then
        latest.ts = now
        latest.count = (tonumber(latest.count) or 1) + 1
        if self.RaiseSupportIncidentR59 then self:RaiseSupportIncidentR59("ATTENTION", source, text) end
        return
    end
    table.insert(self.runtime.errorHistoryRC3, 1, { ts = now, source = tostring(source or "Addon"), message = text, count = 1 })
    while table.getn(self.runtime.errorHistoryRC3) > 10 do table.remove(self.runtime.errorHistoryRC3) end
    if self.RaiseSupportIncidentR59 then self:RaiseSupportIncidentR59("ATTENTION", source, text) end
end

local function EstimateValueRC3(value, state, depth)
    if state.capped or state.entries >= 50000 or depth > 20 then state.capped = true return end
    local kind = type(value)
    state.entries = state.entries + 1
    if kind == "string" then state.bytes = state.bytes + string.len(value) + 16 return end
    if kind == "number" or kind == "boolean" then state.bytes = state.bytes + 16 return end
    if kind ~= "table" then state.bytes = state.bytes + 8 return end
    if state.seen[value] then return end
    state.seen[value] = true
    state.bytes = state.bytes + 32
    local key, child
    for key, child in pairs(value) do
        if state.capped then break end
        if type(key) == "string" then state.bytes = state.bytes + string.len(key) + 8 else state.bytes = state.bytes + 8 end
        EstimateValueRC3(child, state, depth + 1)
    end
end

function OTLGM:EstimateLocalDataRC3(force)
    self.runtime = self.runtime or {}
    local cached = self.runtime.localDataEstimateRC3
    local now = self:Now()
    if not force and cached and now - (tonumber(cached.ts) or 0) < 30 then return cached end
    local state = { bytes = 0, entries = 0, capped = false, seen = {} }
    local guild = self.GetGuildDB and self:GetGuildDB() or nil
    EstimateValueRC3(guild or {}, state, 0)
    EstimateValueRC3(OTLGM_DB and OTLGM_DB.settings or {}, state, 0)
    cached = { ts = now, bytes = state.bytes, entries = state.entries, capped = state.capped and true or false }
    self.runtime.localDataEstimateRC3 = cached
    return cached
end

local function AgeTextRC3(owner, ts)
    ts = tonumber(ts) or 0
    if ts <= 0 then return "never" end
    local age = math.max(0, owner:Now() - ts)
    if age < 60 then return tostring(math.floor(age)) .. "s ago" end
    if age < 3600 then return tostring(math.floor(age / 60)) .. "m ago" end
    if age < 86400 then return tostring(math.floor(age / 3600)) .. "h ago" end
    return tostring(math.floor(age / 86400)) .. "d ago"
end

function OTLGM:GetPreFinalHealthSummaryRC3()
    local scheduler = self.GetSchedulerDiagnostics180 and self:GetSchedulerDiagnostics180() or {}
    local total, critical, normal, bulk = 0, 0, 0, 0
    if self.GetNetworkQueueDepth then total, critical, normal, bulk = self:GetNetworkQueueDepth() end
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local craft = self.EnsureCraftingDB and self:EnsureCraftingDB() or nil
    local pve = self.EnsurePveDB and self:EnsurePveDB() or nil
    local treasurySync = self.runtime and self.runtime.treasurySync170 or nil
    local estimate = self:EstimateLocalDataRC3(false)
    local backoff = math.max(0, (tonumber(self.runtime and self.runtime.rosterAutoRetryAfterRC3) or 0) - self:Now())
    local lines = {
        "Runtime health: " .. (scheduler.active and "scheduler active" or "scheduler sleeping") .. " • tasks " .. tostring(scheduler.taskCount or 0) .. " • page " .. tostring(self.ui and self.ui.currentPage or "closed"),
        "Network queue: " .. tostring(total) .. " (" .. tostring(critical) .. "/" .. tostring(normal) .. "/" .. tostring(bulk) .. ")" .. ((tonumber(scheduler.errors) or 0) > 0 and (" • scheduler errors " .. tostring(scheduler.errors)) or ""),
        "Roster: " .. (self.pendingScan and "request pending" or (self.runtime and self.runtime.rosterRead180 and "bounded read" or "idle")) .. (backoff > 0 and (" • auto retry in " .. tostring(math.ceil(backoff)) .. "s") or "") .. " • last scan " .. AgeTextRC3(self, db and db.lastScan),
        "PvE confirmed: " .. AgeTextRC3(self, pve and pve.lastConfirmedSync180) .. (pve and pve.lastSyncPeer180 and (" with " .. tostring(pve.lastSyncPeer180)) or ""),
        "Professions: last sync " .. AgeTextRC3(self, craft and ((craft.syncState and craft.syncState.completed) or craft.lastSync)) .. " • Treasury: " .. AgeTextRC3(self, treasurySync and treasurySync.completed),
        "Local data estimate: " .. tostring(math.floor((tonumber(estimate.bytes) or 0) / 1024)) .. " KB / 1953 KB backup limit" .. (estimate.capped and " (estimate capped)" or ""),
    }
    if (tonumber(scheduler.errors) or 0) > 0 then table.insert(lines, "Scheduler last error: " .. tostring(scheduler.lastErrorKey or "unknown") .. " • " .. string.sub(tostring(scheduler.lastError or "unknown"), 1, 100)) end
    local errors = self.runtime and self.runtime.errorHistoryRC3 or {}
    if table.getn(errors) > 0 then table.insert(lines, "Recent internal issues: " .. tostring(table.getn(errors)) .. " • last " .. tostring(errors[1].source) .. ": " .. string.sub(tostring(errors[1].message or ""), 1, 90)) end
    return table.concat(lines, "\n")
end

function OTLGM:GetPreFinalHealthDiagnosticsRC3()
    local summary = self:GetPreFinalHealthSummaryRC3()
    local lines = { "--- FINAL ENGINEERING HEALTH ---", summary }
    local trace = self.runtime and self.runtime.rosterRankTraceRC4 or {}
    local newestTrace = trace and trace[1]
    if newestTrace then
        table.insert(lines, "Last rank action: " .. tostring(newestTrace.target or "unknown") .. " • " .. tostring(newestTrace.phase or "unknown") .. " • live " .. tostring(newestTrace.liveRank or "unknown") .. " • calls " .. tostring(newestTrace.apiCalls or 0) .. (newestTrace.detail and (" • " .. tostring(newestTrace.detail)) or ""))
    end
    local errors = self.runtime and self.runtime.errorHistoryRC3 or {}
    local index, item
    for index = 1, table.getn(errors) do
        item = errors[index]
        table.insert(lines, "Issue " .. tostring(index) .. ": " .. date("%H:%M:%S", tonumber(item.ts) or self:Now()) .. " [" .. tostring(item.source or "Addon") .. "] " .. tostring(item.message or "") .. ((tonumber(item.count) or 1) > 1 and (" x" .. tostring(item.count)) or ""))
    end
    return table.concat(lines, "\n")
end

function OTLGM:GetLocalMaintenancePreviewRC4()
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local now = self:Now()
    local stalePresence, expiredPve = 0, 0
    local name, info
    for name, info in pairs(db and db.detectedVersions or {}) do
        if type(info) ~= "table" or now - (tonumber(info.ts) or 0) > (30 * 86400) then stalePresence = stalePresence + 1 end
    end
    local pve = self.EnsurePveDB and self:EnsurePveDB() or nil
    local _, record
    for _, record in pairs(pve and pve.requests or {}) do if not record.expires or record.expires <= now then expiredPve = expiredPve + 1 end end
    for _, record in pairs(pve and pve.applications or {}) do if not record.expires or record.expires <= now then expiredPve = expiredPve + 1 end end
    for _, record in pairs(pve and pve.board or {}) do if not record.expires or record.expires <= now then expiredPve = expiredPve + 1 end end
    return { stalePresence = stalePresence, expiredPve = expiredPve, summary = "Old addon-user records: " .. tostring(stalePresence) .. ". Expired PvE entries: " .. tostring(expiredPve) .. ". Long-offline guild crafters stay stored but are de-prioritized; recipe data is removed only after the character is no longer in the guild or normal bounded cache limits apply." }
end

function OTLGM:RunLocalMaintenanceRC3()
    local result = { presence = 0, crafting = 0, pve = 0 }
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local now = self:Now()
    if db and type(db.detectedVersions) == "table" then
        local name, info
        for name, info in pairs(db.detectedVersions) do
            if type(info) ~= "table" or now - (tonumber(info.ts) or 0) > (30 * 86400) then db.detectedVersions[name] = nil result.presence = result.presence + 1 end
        end
        -- RC4-r9: maintenance can mutate the presence table in place.  Drop the
        -- normalized compatibility index only when that actually happened so a
        -- removed old peer cannot survive inside the Roster's cached Addon view.
        if result.presence > 0 then
            self.runtime = self.runtime or {}
            self.runtime.addonDetectionRevision184 = (tonumber(self.runtime.addonDetectionRevision184) or 0) + 1
            self.runtime.addonDetectionIndex184 = nil
            self.runtime.sortedRosterView184 = nil
        end
    end
    if self.CleanupDuplicateNotifications175 then self:CleanupDuplicateNotifications175() end
    if self.PruneCraftingDetails then self:PruneCraftingDetails(1200) end
    if self.PruneCraftingIconCache157 then self:PruneCraftingIconCache157() end
    if self.PurgeCraftingData and self:PurgeCraftingData(true) then result.crafting = 1 end
    if self.PurgePveData and self:PurgePveData(true) then result.pve = 1 end
    if self.EnsureTreasury170 then self:EnsureTreasury170() end
    result.removed = (tonumber(result.presence) or 0) + (tonumber(result.crafting) or 0) + (tonumber(result.pve) or 0)
    self.runtime.localDataEstimateRC3 = nil
    return result
end

function OTLGM:IsAddonVersionOlderRC4(candidate)
    candidate = tostring(candidate or "")
    local current = tostring(self.version or "")
    if candidate == "" or candidate == "unknown" or candidate == "Detected" then return false end
    if candidate == current then return false end
    -- Central version ordering understands final > RC > beta > alpha/C-stage,
    -- so every UI surface and compatibility warning agrees after 1.8.0 final.
    return self.IsVersionNewer and self:IsVersionNewer(current, candidate) or false
end

function OTLGM:GetAddonCompatibilityWarningRC4()
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local now = self:Now()
    local outdatedOnline, outdatedRecent, unknownRecent = 0, 0, 0
    local name, info
    for name, info in pairs(db and db.detectedVersions or {}) do
        local version = type(info) == "table" and tostring(info.version or "") or ""
        local age = now - (type(info) == "table" and (tonumber(info.ts) or 0) or 0)
        if age <= 86400 then
            if version == "" or version == "unknown" then
                unknownRecent = unknownRecent + 1
            elseif self.IsAddonVersionOlderRC4 and self:IsAddonVersionOlderRC4(version) then
                outdatedRecent = outdatedRecent + 1
                local member = self.GetMember and self:GetMember(name) or nil
                if member and member.online then outdatedOnline = outdatedOnline + 1 end
            end
        end
    end
    if outdatedRecent > 0 then
        return tostring(outdatedOnline) .. " outdated online / " .. tostring(outdatedRecent) .. " outdated seen in 24h; advanced Raid/Treasury/Crafting sharing requires compatible 1.8 addon users."
    end
    if unknownRecent > 0 then return tostring(unknownRecent) .. " recent addon user(s) have not reported a version yet." end
    return nil
end

function OTLGM:GetSystemHealthRC4()
    local scheduler = self.GetSchedulerDiagnostics180 and self:GetSchedulerDiagnostics180() or {}
    local total, critical, normal, bulk = 0, 0, 0, 0
    if self.GetNetworkQueueDepth then total, critical, normal, bulk = self:GetNetworkQueueDepth() end
    if (tonumber(scheduler.errors) or 0) > 0 then return "Needs attention", "Scheduler error recorded" end
    if self.IsPerformanceGuardActive181 and self:IsPerformanceGuardActive181() then
        local guard = self.GetPerformanceGuardState181 and self:GetPerformanceGuardState181() or {}
        return "Protected", "Adaptive stutter guard active" .. (guard.reason and (": " .. tostring(guard.reason)) or "")
    end
    if self.pendingScan then return "Updating", "Checking the guild roster" end
    if tonumber(total) and tonumber(total) > 80 then
        if (tonumber(critical) or 0) <= 0 and (tonumber(normal) or 0) <= 0 and (tonumber(bulk) or 0) > 0 then
            return "Syncing", tostring(bulk) .. " background messages queued"
        end
        return "Network backlog", tostring(total) .. " queued messages (" .. tostring(critical or 0) .. "/" .. tostring(normal or 0) .. "/" .. tostring(bulk or 0) .. ")"
    end
    if self.pveSyncPending180 then return "Updating", "Waiting for guild updates" end
    return "Healthy", "Background scheduler sleeps when no work is queued"
end

function OTLGM:GetCraftingVisibleRevisionRC3()
    self.runtime = self.runtime or {}
    local craft = self.EnsureCraftingDB and self:EnsureCraftingDB() or nil
    local sync = craft and craft.syncState or nil
    return table.concat({
        tostring(tonumber(self.runtime.craftingDataRevisionRC3) or 0),
        tostring(tonumber(craft and craft.lastSync) or 0),
        tostring(tonumber(sync and sync.completed) or 0),
        tostring(tonumber(sync and sync.received) or 0)
    }, ":")
end

function OTLGM:GetTreasuryVisibleRevisionRC3()
    local treasury = self.EnsureTreasury170 and self:EnsureTreasury170() or nil
    if not treasury then return "0:0:0" end
    -- Contribution and donor mutations bump a small runtime revision at their
    -- write sites. The open Treasury page can therefore detect real changes in
    -- O(1) time instead of walking every retained ledger row every 15 seconds.
    local sync = self.runtime and self.runtime.treasurySync170 or nil
    return table.concat({
        tostring(tonumber(treasury.revision) or 0),
        tostring(tonumber(self.runtime and self.runtime.treasuryDataRevisionRC5R3) or 0),
        tostring(tonumber(sync and sync.completed) or 0)
    }, ":")
end

function OTLGM:ScheduleVisiblePageClock180(pageKey)
    if self.CancelTask180 then self:CancelTask180("page-clock") end
    -- The ST clock lives in the shared header on every page. Earlier final-RC
    -- code only armed this foreground pulse for pages that also needed a
    -- recovery refresh, which left the visible ST clock frozen on Roster,
    -- Activity, History, Settings and other quiet pages. Keep one cheap keyed
    -- task while the addon window is visible on *any* page; page-specific work
    -- below is still restricted to the few pages that need it.
    if not self.ScheduleAfter180 then return end
    -- Quiet pages only display HH:MM in the shared ST header, so a five-second
    -- pulse was unnecessary foreground work. Recruitment/chat keep their short
    -- recovery cadence; domain pages keep their existing bounded cadence; all
    -- other pages update at most twice per minute while visible.
    local delay = (pageKey == "recruitment" or pageKey == "guildchat") and 2
        or pageKey == "professions" and 12 or pageKey == "treasury" and 15 or 30
    local settings = OTLGM_DB and OTLGM_DB.settings or {}
    local profile = settings.performanceProfile181 or "AUTO"
    local pressure = self.GetClientPressure181 and self:GetClientPressure181() or nil
    local fps = pressure and tonumber(pressure.fps) or nil
    if not fps and GetFramerate then local ok, value = pcall(GetFramerate) if ok then fps = tonumber(value) end end
    local guardActive = pressure and pressure.guard and true or (self.IsPerformanceGuardActive181 and self:IsPerformanceGuardActive181() or false)
    if profile == "SMOOTH" then delay = math.min(60, delay * 1.5) end
    if guardActive or (fps and fps < 30) then delay = math.min(60, math.max(4, delay * 2)) end
    self:ScheduleAfter180("page-clock", delay, function(owner)
        if not owner.ui or not owner.ui.main or not owner.ui.main:IsVisible() or owner.ui.currentPage ~= pageKey then return end
        -- The page clock is a foreground recovery pulse. One page-specific
        -- refresh/sync error must not permanently kill recruitment time, chat
        -- recovery or the rare profession/treasury safety refresh until the
        -- user changes tabs. Always re-arm the pulse while this page remains
        -- visible and report the failed sub-step separately.
        local pulseOk, pulseProblem = pcall(function()
        local now = owner:Now()
        owner.runtime = owner.runtime or {}
        owner.runtime.visiblePagePulse180 = owner.runtime.visiblePagePulse180 or {}
        local pulse = owner.runtime.visiblePagePulse180
        if owner.ui.headerDate then owner.ui.headerDate:SetText("Server Time (ST) " .. (owner.FormatServerClock180 and owner:FormatServerClock180(owner:Now(), true) or date("%H:%M  %d %b"))) end
        if pageKey == "recruitment" and owner.RefreshWorldRecruitmentIndicator then
            -- Tiny elapsed-time label only; does not rebuild the page.
            owner:RefreshWorldRecruitmentIndicator()
        elseif pageKey == "guildchat" then
            -- Incoming CHAT_MSG_GUILD/OFFICER already refreshes immediately. This
            -- cheap signature is only a safety net for missed/reordered client events.
            local settings = type(OTLGM_DB) == "table" and type(OTLGM_DB.settings) == "table" and OTLGM_DB.settings or {}
            local channel = settings.guildChatView == "OFFICER" and "OFFICER" or "GUILD"
            local messages = owner.GetGuildChatMessages and owner:GetGuildChatMessages(channel) or {}
            local count = table.getn(messages or {})
            local last = count > 0 and messages[count] or nil
            local signature = channel .. ":" .. tostring(count) .. ":" .. tostring(last and (last.ts or last.timestamp or last.id) or 0)
            if pulse.chatSignature ~= signature then
                pulse.chatSignature = signature
                if owner.RefreshGuildChatPage then owner:RefreshGuildChatPage() end
            end
        elseif pageKey == "professions" then
            -- Foreground professions stay responsive without rebuilding a large
            -- recipe list on every pulse. Domain mutations increment a revision;
            -- event handlers still refresh immediately when data truly changes.
            local revision = owner.GetCraftingVisibleRevisionRC3 and owner:GetCraftingVisibleRevisionRC3() or "0"
            if pulse.craftingRevisionRC3 == nil then pulse.craftingRevisionRC3 = revision
            elseif pulse.craftingRevisionRC3 ~= revision then
                pulse.craftingRevisionRC3 = revision
                if owner.RefreshProfessionsPage then owner:RefreshProfessionsPage() end
            end
            -- Recovery sync is intentionally rare. Real profession-window scans
            -- and change manifests remain immediate, so new recipes are not delayed.
            local pressureState = owner.GetClientPressure181 and owner:GetClientPressure181() or nil
            local pressure = (pressureState and tonumber(pressureState.level) >= 2) or (owner.runtime and owner.runtime.transitionActive176) or (owner.IsPerformanceGuardActive181 and owner:IsPerformanceGuardActive181()) or (owner.InCombat and owner:InCombat())
            if not pressure and (tonumber(pulse.craftingSyncAt) or 0) + 600 <= now and owner.RequestCraftingSync then
                pulse.craftingSyncAt = now
                owner:RequestCraftingSync(false, false)
            end
        elseif pageKey == "treasury" then
            local revision = owner.GetTreasuryVisibleRevisionRC3 and owner:GetTreasuryVisibleRevisionRC3() or "0"
            if pulse.treasuryRevisionRC3 == nil then pulse.treasuryRevisionRC3 = revision
            elseif pulse.treasuryRevisionRC3 ~= revision then
                pulse.treasuryRevisionRC3 = revision
                if owner.RefreshTreasuryPage170 then owner:RefreshTreasuryPage170() end
            end
            local pressureState = owner.GetClientPressure181 and owner:GetClientPressure181() or nil
            local pressure = (pressureState and tonumber(pressureState.level) >= 2) or (owner.runtime and owner.runtime.transitionActive176) or (owner.IsPerformanceGuardActive181 and owner:IsPerformanceGuardActive181()) or (owner.InCombat and owner:InCombat())
            if not pressure and (tonumber(pulse.treasurySyncAt) or 0) + 180 <= now and owner.RequestTreasurySync170 then
                pulse.treasurySyncAt = now
                owner:RequestTreasurySync170(false)
            end
        end
        end)
        if not pulseOk and owner.RecordInternalIssueRC3 then
            pcall(owner.RecordInternalIssueRC3, owner, "UI/PAGE_CLOCK_" .. string.upper(tostring(pageKey or "unknown")), pulseProblem)
        end
        -- Closing the addon or changing tab makes this callback return without
        -- re-arming, so hidden pages are still completely asleep.
        if owner.ui and owner.ui.main and owner.ui.main:IsVisible() and owner.ui.currentPage == pageKey then
            owner:ScheduleVisiblePageClock180(pageKey)
        end
    end, -1)
end

function OTLGM:ShowPage(pageKey, options183)
    options183 = type(options183) == "table" and options183 or {}
    if not self.ui or not self.ui.main then self:BuildUI() end
    local definition = self:GetShellPageDefinition(pageKey)
    if not definition then return false end
    if definition.officer and (not self.IsOfficerMode or not self:IsOfficerMode()) then
        self:ShowToast("This page requires guild officer permissions.", "error")
        pageKey = "home"
        definition = self:GetShellPageDefinition(pageKey)
    end
    if not self:CloseShellTransient(true, "page-change", false) then return false end
    local previousKey = self.ui.currentPage
    local previousModule = previousKey and self.shellPageModules[previousKey]
    if previousKey ~= pageKey and previousModule and previousModule.root then previousModule:OnHide() end
    local page = self:EnsureShellPage(pageKey)
    if not page then
        self:ShowOperationError("The page could not be opened.", function() OTLGM:ShowPage(pageKey) end)
        return false
    end
    local key, candidate
    for key, candidate in pairs(self.ui.pages) do
        if candidate and not candidate.otlLazyShell then
            if key == pageKey then candidate:Show() else candidate:Hide() end
        end
    end
    self.ui.currentPage = pageKey
    OTLGM_DB.settings.lastPage = pageKey
    -- Page-scoped operation feedback must not travel with the player after
    -- navigation.  This also cleans up a toast created by an older path just
    -- before the page changed.
    if self.runtime and self.runtime.lastVisibleStatusSource180 then
        local source = tostring(self.runtime.lastVisibleStatusSource180)
        local keep = (source == "pve" and (pageKey == "pve" or pageKey == "settings"))
            or (source == "crafting" and pageKey == "professions")
            or (source == "roster" and (pageKey == "roster" or pageKey == "settings"))
        if (source == "pve" or source == "crafting" or source == "roster") and not keep then
            self.runtime.shellToastUntil = nil
            self.runtime.lastVisibleStatusSource180 = nil
            if self.ui.shellToast then self.ui.shellToast:Hide() end
        end
    end
    self:ScheduleVisiblePageClock180(pageKey)
    if not options183.suppressRosterScan183 then self:RequestStaleRosterOnOpen180(pageKey) end
    local title = PAGE_TITLES[pageKey] or { definition.label, "" }
    self.ui.pageTitle:SetText(title[1])
    self.ui.pageSubtitle:SetText(title[2])
    if self.ui.pageIcon184 then
        self.ui.pageIcon184:SetTexture(definition.icon or "Interface\\Icons\\INV_Misc_Book_09")
        if self.ui.pageIcon184.SetTexCoord then self.ui.pageIcon184:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    end
    self.ui.pageHeader:Show()
    self:RefreshNavigation()
    if pageKey == "professions" then
        if self.RequestCraftingSync then self:RequestCraftingSync(false) end
        if self.MarkCraftingRead then self:MarkCraftingRead(OTLGM_DB.settings.craftingSection or "RECIPES") end
    elseif pageKey == "pve" and self.RequestPveSync then
        self:RequestPveSync(false)
    elseif pageKey == "treasury" and self.RequestTreasurySync170 then
        self:RequestTreasurySync170(false)
    end
    self:LayoutShellPage180(pageKey, "show")
    if self.ResetPageRefreshError180 then self:ResetPageRefreshError180(pageKey, "show") end
    local module = self.shellPageModules[pageKey]
    if module then
        module:OnShow({
            page = pageKey,
            workspace = OTLGM_DB.settings.shellNavMode,
            previousPage = previousKey,
        })
    end
    self:RefreshShellPage(pageKey, "show")
    if pageKey == "achievements" and self.ApplyPendingAchievementFocus180 then
        self:ApplyPendingAchievementFocus180("page-shown")
    end
    return true
end

function OTLGM:RefreshVisiblePage()
    if not self.ui or not self.ui.currentPage then return end
    self:RefreshShellPage(self.ui.currentPage, "visible")
end

function OTLGM:RefreshAll()
    if not self.ui or not self.ui.shellBuilt then return end
    self:RefreshNavigation()
    self:RefreshVisiblePage()
end

-- Responsive layouts can expose additional pooled rows without changing the
-- underlying data revision. Mark those pages for one refresh after the final
-- geometry pass instead of rebuilding them for every mouse-move sample.
function OTLGM:MarkLayoutDataRefresh180(pageKey)
    if not pageKey then return false end
    self.runtime = self.runtime or {}
    self.runtime.layoutDataRefresh180 = self.runtime.layoutDataRefresh180 or {}
    self.runtime.layoutDataRefresh180[tostring(pageKey)] = true
    return true
end

function OTLGM:MarkDrawerDataRefresh180(drawerKey)
    if not drawerKey then return false end
    self.runtime = self.runtime or {}
    self.runtime.drawerDataRefresh180 = self.runtime.drawerDataRefresh180 or {}
    self.runtime.drawerDataRefresh180[tostring(drawerKey)] = true
    return true
end

function OTLGM:FlushLayoutDataRefresh180(reason)
    if not self.ui or not self.ui.main then return false end
    self.runtime = self.runtime or {}
    if self.runtime.flushingLayoutData180 then return false end
    local interaction = self.runtime.windowInteraction180
    if interaction and interaction.mode == "RESIZE" then return false end
    self.runtime.flushingLayoutData180 = true

    local ok, problem = pcall(function()
        local drawerFlags = self.runtime.drawerDataRefresh180 or {}
        if drawerFlags.actionCenter and self.ui.activeDrawer == self.ui.actionCenterDrawer and self.RefreshActionCenter then
            drawerFlags.actionCenter = nil
            local refreshOk, refreshProblem = pcall(self.RefreshActionCenter, self)
            if not refreshOk and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "UI/ACTION_CENTER_REFLOW", refreshProblem) end
        end
        if drawerFlags.addonUsers and self.ui.activeDrawer == self.ui.addonUsersDrawer and self.RefreshAddonUsersDrawer then
            drawerFlags.addonUsers = nil
            local refreshOk, refreshProblem = pcall(self.RefreshAddonUsersDrawer, self)
            if not refreshOk and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "UI/ADDON_USERS_REFLOW", refreshProblem) end
        end

        local pageKey = self.ui.currentPage
        local pageFlags = self.runtime.layoutDataRefresh180 or {}
        if pageKey and pageFlags[pageKey] and self.ui.main:IsVisible() then
            pageFlags[pageKey] = nil
            self:RefreshShellPage(pageKey, reason or "layout-capacity")
        end
    end)
    self.runtime.flushingLayoutData180 = nil
    if not ok then
        if self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "UI/LAYOUT_DATA_FLUSH", problem) end
        return false
    end
    return true
end

function OTLGM:RefreshAddonUsersIndicator()
    if not self.ui or not self.ui.addonUsersButton then return end
    local count, latest, online = 0, nil, 0
    if self.GetDetectedAddonUsers then count, latest, online = self:GetDetectedAddonUsers(86400) end
    UI:SetText(self.ui.addonUsersButton, "Sharing  •  " .. tostring(online or count or 0) .. " online")
    if self.ui.addonUsersDrawer and self.ui.activeDrawer == self.ui.addonUsersDrawer then
        self:RefreshAddonUsersDrawer()
    end
end


-- RC5-R5 geometry controller. All coordinates are stored in UIParent logical
-- units and all cursor movement is converted from physical pixels through the
-- current UIParent effective scale. This avoids relying on StartMoving/
-- SetClampedToScreen behaviour that UI replacements commonly hook or rescale.
local WINDOW_SIZE_PRESETS180 = {
    COMPACT = { 1000, 700 },
    NORMAL = { 1160, 740 },
    LARGE = { 1320, 820 },
    XL = { 1480, 900 },
}

function OTLGM:GetUIParentMetrics180()
    local parent = UIParent
    local width = parent and parent.GetWidth and tonumber(parent:GetWidth()) or 1024
    local height = parent and parent.GetHeight and tonumber(parent:GetHeight()) or 768
    local scale = parent and parent.GetEffectiveScale and tonumber(parent:GetEffectiveScale()) or 1
    if not scale or scale <= 0 then scale = 1 end
    return math.max(1, width or 1024), math.max(1, height or 768), scale
end

-- Some Vanilla UI replacements deliberately give UIParent a reduced logical
-- workspace while the physical game viewport is still larger. Fit/Compact
-- sizing must continue to use UIParent (it is live-tested and intentionally
-- respects that workspace), but movable controls should be allowed to reach
-- the real visible screen. Resolve a separate positioning viewport from the
-- physical screen when the API is available, with a conservative fallback to
-- UIParent on clients that do not expose it.
function OTLGM:GetPositionViewportMetrics180()
    local parentWidth, parentHeight, parentScale = self:GetUIParentMetrics180()

    -- GetScreenWidth/GetScreenHeight are already expressed at UIParent scale
    -- on the Vanilla API. Cursor positions, on the other hand, are physical and
    -- are converted by parentScale by the drag handlers. Dividing the screen
    -- dimensions by parentScale a second time made the saved/clamped workspace
    -- too large whenever UI scale was below 100%, so Park could either stop at
    -- the wrong boundary or be saved beyond the visible edge after reload.
    --
    -- A UI replacement may still expose a deliberately smaller UIParent than
    -- the visible game viewport. In that case the screen API is the escape
    -- boundary we want; otherwise both values are normally the same.
    local screenWidth, screenHeight
    if GetScreenWidth then
        local ok, value = pcall(GetScreenWidth)
        if ok then screenWidth = tonumber(value) end
    end
    if GetScreenHeight then
        local ok, value = pcall(GetScreenHeight)
        if ok then screenHeight = tonumber(value) end
    end
    local width = math.max(parentWidth, (screenWidth and screenWidth > 0) and screenWidth or parentWidth)
    local height = math.max(parentHeight, (screenHeight and screenHeight > 0) and screenHeight or parentHeight)
    return width, height, parentScale
end

function OTLGM:UIParentMetricsChanged180(width, height, scale)
    self.runtime = self.runtime or {}
    local previous = self.runtime.uiParentMetrics180
    if not previous then return true end
    if math.abs((tonumber(previous.width) or 0) - (tonumber(width) or 0)) > 0.5 then return true end
    if math.abs((tonumber(previous.height) or 0) - (tonumber(height) or 0)) > 0.5 then return true end
    if math.abs((tonumber(previous.scale) or 1) - (tonumber(scale) or 1)) > 0.001 then return true end
    local positionWidth, positionHeight = self:GetPositionViewportMetrics180()
    if math.abs((tonumber(previous.positionWidth) or 0) - positionWidth) > 0.5 then return true end
    if math.abs((tonumber(previous.positionHeight) or 0) - positionHeight) > 0.5 then return true end
    return false
end

function OTLGM:RememberUIParentMetrics180()
    local width, height, scale = self:GetUIParentMetrics180()
    local positionWidth, positionHeight = self:GetPositionViewportMetrics180()
    self.runtime = self.runtime or {}
    self.runtime.uiParentMetrics180 = { width = width, height = height, scale = scale, positionWidth = positionWidth, positionHeight = positionHeight }
    return width, height, scale
end

-- Rebase only when the host geometry really changed. This preserves normalized
-- positions across DFUI/scale/resolution changes and keeps ordinary zoning from
-- performing two full hidden-page layout passes.
function OTLGM:RebaseUIParentGeometry180(reason, force)
    if not self.ui or not self.ui.main or not OTLGM_DB or not OTLGM_DB.settings then return false end
    local parentWidth, parentHeight, parentScale = self:GetUIParentMetrics180()
    if not force and not self:UIParentMetricsChanged180(parentWidth, parentHeight, parentScale) then return false end

    local positionWidth, positionHeight = self:GetPositionViewportMetrics180()
    local settings = OTLGM_DB.settings
    local normalizedX, normalizedY = tonumber(settings.windowNX180), tonumber(settings.windowNY180)
    if normalizedX then settings.windowX = normalizedX * positionWidth end
    if normalizedY then settings.windowY = normalizedY * positionHeight end
    local scaleRequest = settings.uiScaleModeR2 == "FIT" and "FIT" or (settings.uiScale or 1)
    if self:GetWindowSizePreset180() == "MAX" then
        self:SetWindowSizePreset180("MAX", { preserveNormalized = true, skipSettingsRefresh = true, reason = reason or "parent-rebase" })
    else
        self:ApplyUIScale(scaleRequest)
    end
    -- Scale restoration uses the rebased absolute offset. A final world-policy
    -- pass additionally recovers a still-reachable title area when strict
    -- clamping is disabled and the new monitor has a very different aspect.
    self:RestoreWindowPosition180("world")
    self:SaveWindowGeometry180(reason or "parent-rebase")
    self:RestoreParkPosition180("world")
    if self.ui and self.ui.guildProfile183 and self.ui.guildProfile183:IsVisible()
        and self.PositionGuildProfile183 and not self.ui.guildProfile183.otlDetached183 then
        self:PositionGuildProfile183("parent-rebase")
    end
    self:RememberUIParentMetrics180()
    return true
end

function OTLGM:GetFrameScaleRelativeToUIParent180(frame)
    if not frame then return 1 end
    local _, _, parentScale = self:GetUIParentMetrics180()
    local effective = frame.GetEffectiveScale and tonumber(frame:GetEffectiveScale()) or nil
    if effective and effective > 0 and parentScale > 0 then
        return math.max(0.01, effective / parentScale)
    end
    local localScale = frame.GetScale and tonumber(frame:GetScale()) or 1
    return math.max(0.01, localScale or 1)
end

function OTLGM:GetFrameCenterOffset180(frame)
    if not frame or not UIParent then return 0, 10 end
    -- The shell always owns a CENTER -> UIParent CENTER anchor. Reading that
    -- anchor directly avoids mixing physical pixels, frame-local scale and
    -- UIParent logical coordinates (a common source of DFUI snap-back).
    if frame.GetPoint then
        local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
        if point == "CENTER" and (relativeTo == UIParent or relativeTo == nil) and (relativePoint == "CENTER" or relativePoint == nil) then
            return tonumber(x) or 0, tonumber(y) or 0
        end
    end
    local centerX, centerY
    if frame.GetCenter then centerX, centerY = frame:GetCenter() end
    local parentCenterX, parentCenterY
    if UIParent.GetCenter then parentCenterX, parentCenterY = UIParent:GetCenter() end
    if centerX and centerY and parentCenterX and parentCenterY then
        return centerX - parentCenterX, centerY - parentCenterY
    end
    return tonumber(OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.windowX) or 0,
        tonumber(OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.windowY) or 10
end

function OTLGM:GetWindowMaximumSize180(scale)
    local parentWidth, parentHeight = self:GetUIParentMetrics180()
    scale = math.max(0.01, tonumber(scale) or (self.ui and self.ui.main and self:GetFrameScaleRelativeToUIParent180(self.ui.main)) or 1)
    local margin = 12
    return math.max(1000, math.min(2600, math.floor((parentWidth - margin) / scale))),
        math.max(700, math.min(1600, math.floor((parentHeight - margin) / scale)))
end

function OTLGM:SetFrameDimensions180(frame, width, height, source)
    if not frame then return false end
    self.runtime = self.runtime or {}
    local previousWidth = frame.GetWidth and tonumber(frame:GetWidth()) or nil
    local previousHeight = frame.GetHeight and tonumber(frame:GetHeight()) or nil
    self.runtime.geometryBatch180 = true
    local ok, problem = pcall(function()
        frame:SetWidth(width)
        frame:SetHeight(height)
    end)
    if not ok and previousWidth and previousHeight then
        pcall(function() frame:SetWidth(previousWidth) frame:SetHeight(previousHeight) end)
    end
    self.runtime.geometryBatch180 = nil
    if not ok then
        if self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "UI/GEOMETRY_" .. tostring(source or "SIZE"), problem) end
        return false
    end
    return true
end

function OTLGM:GetWindowSizePreset180()
    local value = OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.windowSizePreset180 or "NORMAL"
    if value ~= "COMPACT" and value ~= "NORMAL" and value ~= "LARGE" and value ~= "XL" and value ~= "MAX" and value ~= "CUSTOM" then
        value = "NORMAL"
    end
    return value
end

function OTLGM:SetWindowSizePreset180(preset, options)
    if not self.ui or not self.ui.main or not OTLGM_DB or not OTLGM_DB.settings then return false end
    preset = string.upper(tostring(preset or "NORMAL"))
    if preset ~= "COMPACT" and preset ~= "NORMAL" and preset ~= "LARGE" and preset ~= "XL" and preset ~= "MAX" then preset = "NORMAL" end
    options = type(options) == "table" and options or {}

    local settings = OTLGM_DB.settings
    local preservedNX = options.preserveNormalized and tonumber(settings.windowNX180) or nil
    local preservedNY = options.preserveNormalized and tonumber(settings.windowNY180) or nil
    local frame = self.ui.main
    local desiredWidth, desiredHeight
    if preset == "MAX" then
        -- Max uses as much of the viewport as the selected scale can actually
        -- support. Fixed UI scale remains authoritative; if the viewport is too
        -- short even for the 1000x700 safe minimum, only that unavoidable axis
        -- may overflow. This avoids the old mismatch where MAX calculated its
        -- size with a smaller hidden scale and then reapplied 150%, making both
        -- axes unnecessarily larger than the screen.
        local parentWidth, parentHeight = self:GetUIParentMetrics180()
        local availableWidth, availableHeight = math.max(1, parentWidth - 12), math.max(1, parentHeight - 12)
        if settings.uiScaleModeR2 == "FIT" then
            local targetScale = math.max(0.05, math.min(1.50, availableWidth / 1000, availableHeight / 700))
            desiredWidth = math.floor(availableWidth / targetScale)
            desiredHeight = math.floor(availableHeight / targetScale)
        else
            local preferred = math.max(0.75, math.min(1.50, tonumber(settings.uiScale) or 1))
            desiredWidth = math.floor(availableWidth / preferred)
            desiredHeight = math.floor(availableHeight / preferred)
        end
    else
        local definition = WINDOW_SIZE_PRESETS180[preset] or WINDOW_SIZE_PRESETS180.NORMAL
        desiredWidth, desiredHeight = definition[1], definition[2]
    end
    desiredWidth = math.max(1000, math.min(2600, tonumber(desiredWidth) or 1160))
    desiredHeight = math.max(700, math.min(1600, tonumber(desiredHeight) or 740))

    self.runtime = self.runtime or {}
    self.runtime.applyingWindowPreset180 = true
    local sizeApplied = self:SetFrameDimensions180(frame, desiredWidth, desiredHeight, "PRESET")
    self.runtime.applyingWindowPreset180 = nil
    if not sizeApplied then return false end
    settings.windowSizePreset180 = preset

    -- During a resolution/UIParent-scale rebase the old absolute offsets are
    -- stale, but the normalized location remains authoritative. Convert it to
    -- the new parent before ApplyUIScale performs its normal restore/clamp.
    if preservedNX or preservedNY then
        local parentWidth, parentHeight = self:GetPositionViewportMetrics180()
        if preservedNX then
            settings.windowNX180 = preservedNX
            settings.windowX = preservedNX * parentWidth
        end
        if preservedNY then
            settings.windowNY180 = preservedNY
            settings.windowY = preservedNY * parentHeight
        end
    end

    local scaleRequest = settings.uiScaleModeR2 == "FIT" and "FIT" or (settings.uiScale or 1)
    self:ApplyUIScale(scaleRequest)
    self:SaveWindowGeometry180(options.reason or "preset")
    if not options.skipSettingsRefresh and self.RefreshSettingsPage then self:RefreshSettingsPage() end
    return true
end

function OTLGM:SnapWindowGeometryToPixels183(x, y, width, height, scale)
    scale = math.max(0.01, tonumber(scale) or 1)
    local function snap(value)
        value = tonumber(value) or 0
        if value >= 0 then return math.floor((value * scale) + 0.5) / scale end
        return math.ceil((value * scale) - 0.5) / scale
    end
    x, y = snap(x), snap(y)
    if width then width = math.max(1, snap(width)) end
    if height then height = math.max(1, snap(height)) end
    return x, y, width, height
end

function OTLGM:BeginWindowInteraction180(mode)
    if not self.ui or not self.ui.main or not UIParent then return false end
    if mode == "DRAG" and OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.windowLocked then return false end
    local cursorX, cursorY
    if GetCursorPosition then cursorX, cursorY = GetCursorPosition() end
    if not cursorX or not cursorY then return false end
    local _, _, parentScale = self:GetUIParentMetrics180()
    local startX, startY = self:GetFrameCenterOffset180(self.ui.main)
    self.runtime = self.runtime or {}
    self.runtime.windowInteraction180 = {
        mode = mode,
        cursorX = cursorX / parentScale,
        cursorY = cursorY / parentScale,
        startX = startX,
        startY = startY,
        startWidth = tonumber(self.ui.main:GetWidth()) or 1160,
        startHeight = tonumber(self.ui.main:GetHeight()) or 740,
        relativeScale = self:GetFrameScaleRelativeToUIParent180(self.ui.main),
        moved = false,
    }
    self.ui.main:SetScript("OnUpdate", function()
        if not OTLGM or not OTLGM.runtime or not OTLGM.runtime.windowInteraction180 then return end
        local activeFrame = OTLGM.ui and OTLGM.ui.main
        local ok, problem = pcall(OTLGM.UpdateWindowInteraction180, OTLGM)
        if not ok then
            if activeFrame then activeFrame:SetScript("OnUpdate", nil) end
            OTLGM.runtime.windowInteraction180 = nil
            if OTLGM.RecordInternalIssueRC3 then pcall(OTLGM.RecordInternalIssueRC3, OTLGM, "UI/WINDOW_INTERACTION", problem) end
        end
    end)
    return true
end

function OTLGM:UpdateWindowInteraction180(force)
    local state = self.runtime and self.runtime.windowInteraction180
    local frame = self.ui and self.ui.main
    if not state or not frame or not UIParent or not GetCursorPosition then return false end
    -- Mouse-up can occur after the cursor has left the resize grip on some
    -- Vanilla UI replacements.  Do not leave a temporary interaction OnUpdate
    -- running indefinitely if the grip itself misses OnMouseUp.
    if not force and IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
        self:EndWindowInteraction180(state.mode == "RESIZE" and "resize-release" or "drag-release")
        return true
    end
    -- Resize causes a full responsive reflow while dragging only changes one
    -- anchor. Keep normal resizing fluid, but RC4-r9 lowers the reflow cadence
    -- automatically when the adaptive pressure detector already sees low FPS,
    -- combat/transition pressure or Smooth mode. This prevents a resize gesture
    -- from amplifying an existing frame-time spike on weaker clients. The final
    -- mouse-up sample is always forced, so geometry remains exact.
    if state.mode == "RESIZE" and not force and GetTime then
        local resizeInterval184 = 0.025
        if self.GetClientPressure181 then
            local pressure184 = self:GetClientPressure181()
            if pressure184 then
                local pressureLevel184 = tonumber(pressure184.level) or 0
                if pressureLevel184 >= 2 then resizeInterval184 = 0.060
                elseif pressureLevel184 >= 1 then resizeInterval184 = 0.040 end
            end
        end
        local preciseNow = GetTime()
        if state.lastResizeUpdate180 and preciseNow - state.lastResizeUpdate180 < resizeInterval184 then return true end
        state.lastResizeUpdate180 = preciseNow
    end
    local cursorX, cursorY = GetCursorPosition()
    local parentWidth, parentHeight, parentScale = self:GetPositionViewportMetrics180()
    cursorX, cursorY = cursorX / parentScale, cursorY / parentScale
    local dx, dy = cursorX - state.cursorX, cursorY - state.cursorY
    if math.abs(dx) > 1 or math.abs(dy) > 1 then state.moved = true end
    local strict = OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.keepWindowInsideScreen180 and true or false
    if state.mode == "DRAG" then
        local x, y = state.startX + dx, state.startY + dy
        local visualScale = self:GetFrameScaleRelativeToUIParent180(frame)
        if strict then
            x, y = self:GetSoftClampedWindowOffset180(x, y, parentWidth, parentHeight,
                frame:GetWidth(), frame:GetHeight(), visualScale, true)
        end
        -- Keep the frame on physical-pixel boundaries. Fractional CENTER
        -- offsets make thin border textures shimmer while the window moves.
        x, y = self:SnapWindowGeometryToPixels183(x, y, nil, nil, parentScale)
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    elseif state.mode == "RESIZE" then
        local relativeScale = math.max(0.01, tonumber(state.relativeScale) or 1)
        local width = state.startWidth + (dx / relativeScale)
        local height = state.startHeight - (dy / relativeScale)
        width = math.max(tonumber(frame.otlMinWidth180) or 1000, math.min(tonumber(frame.otlMaxWidth180) or 2400, width))
        height = math.max(tonumber(frame.otlMinHeight180) or 700, math.min(tonumber(frame.otlMaxHeight180) or 1600, height))
        -- Round dimensions to whole rendered pixels before reflow. This avoids
        -- alternating half-pixel borders during drag-resize and keeps Fit
        -- geometry stable across UI scale changes.
        local ignoreX, ignoreY
        ignoreX, ignoreY, width, height = self:SnapWindowGeometryToPixels183(0, 0, width, height, relativeScale)
        local visualWidthChange = (width - state.startWidth) * relativeScale
        local visualHeightChange = (height - state.startHeight) * relativeScale
        local x = state.startX + (visualWidthChange / 2)
        local y = state.startY - (visualHeightChange / 2)
        if strict then
            x, y = self:GetSoftClampedWindowOffset180(x, y, parentWidth, parentHeight, width, height, relativeScale, true)
        end
        x, y = self:SnapWindowGeometryToPixels183(x, y, nil, nil, parentScale)
        -- Set both dimensions as one geometry transaction. Without this guard
        -- SetWidth and SetHeight each fire OnSizeChanged and duplicate the full
        -- page layout for the same cursor sample.
        if not self:SetFrameDimensions180(frame, width, height, "RESIZE") then
            -- A protected/third-party frame hook can reject a size update. Stop
            -- the temporary interaction immediately instead of leaving its
            -- OnUpdate alive to repeat the same failed transaction every frame.
            frame:SetScript("OnUpdate", nil)
            if self.runtime then self.runtime.windowInteraction180 = nil end
            return false
        end
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
        self:LayoutShellChrome180("resize-sample")
    end
    return true
end

function OTLGM:EndWindowInteraction180(reason)
    local frame = self.ui and self.ui.main
    local state = self.runtime and self.runtime.windowInteraction180
    if not state then
        if frame then frame:SetScript("OnUpdate", nil) end
        return false
    end
    local updateOk, updateProblem = pcall(self.UpdateWindowInteraction180, self, true)
    if frame then frame:SetScript("OnUpdate", nil) end
    if self.runtime then self.runtime.windowInteraction180 = nil end
    if not updateOk then
        if self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "UI/WINDOW_INTERACTION_FINAL", updateProblem) end
        return false
    end
    if not frame then return false end

    if state.mode == "RESIZE" and OTLGM_DB and OTLGM_DB.settings then
        OTLGM_DB.settings.windowSizePreset180 = "CUSTOM"
        -- One final scale/layout transaction repopulates newly exposed pooled
        -- rows and recalculates strict containment for the custom workspace.
        local scaleRequest = OTLGM_DB.settings.uiScaleModeR2 == "FIT" and "FIT" or (OTLGM_DB.settings.uiScale or 1)
        self:ApplyUIScale(scaleRequest)
        self:SaveWindowGeometry180(reason or "resize-stop")
    else
        -- Dragging does not alter page geometry; saving the owned CENTER anchor
        -- is sufficient and avoids a needless all-page layout on mouse-up.
        self:SaveWindowGeometry180(reason or "drag-stop")
    end
    if self.ui and self.ui.guildProfile183 and self.ui.guildProfile183:IsVisible()
        and self.PositionGuildProfile183 and not self.ui.guildProfile183.otlDetached183 then
        self:PositionGuildProfile183(reason or "main-geometry")
    end
    if self.ui and self.ui.currentPage == "settings" and self.RefreshSettingsPage then self:RefreshSettingsPage() end
    return true
end

function OTLGM:ApplyUIScale(requested)
    if not self.ui or not self.ui.main then return tonumber(requested) or 1 end
    OTLGM_DB.settings = OTLGM_DB.settings or {}
    -- The request is authoritative. A numeric request always exits Fit mode;
    -- callers that want Fit pass the explicit string. This prevents stale
    -- SavedVariables state from making a fixed-scale button appear inert.
    local fitMode = requested == "FIT"
    if fitMode then OTLGM_DB.settings.uiScaleModeR2 = "FIT" end
    local preferred = fitMode and 1.50 or math.max(0.75, math.min(1.50, tonumber(requested) or tonumber(OTLGM_DB.settings.uiScale) or 1))
    if not fitMode then
        OTLGM_DB.settings.uiScale = preferred
        OTLGM_DB.settings.uiScaleModeR2 = "FIXED"
    end

    local parentWidth, parentHeight = self:GetUIParentMetrics180()
    local frame = self.ui.main
    local frameWidth = math.max(1, tonumber(frame:GetWidth()) or 1160)
    local frameHeight = math.max(1, tonumber(frame:GetHeight()) or 740)
    local margin = 12
    -- Window Size and UI Scale are independent.  Keep Inside changes only the
    -- position policy; a fixed scale selection must remain fixed.  Fit is the
    -- only scale mode that deliberately derives its value from the viewport.
    -- MAX computes its logical dimensions for the requested scale in
    -- SetWindowSizePreset180, so it does not need a second hidden scale cap.
    local screenFit = math.max(0.05, math.min(1.50, (parentWidth - margin) / frameWidth, (parentHeight - margin) / frameHeight))
    local effective = fitMode and screenFit or preferred

    frame:SetScale(effective)
    self.runtime = self.runtime or {}
    self.runtime.effectiveUIScale = effective
    self.runtime.uiScaleModeR2 = fitMode and "FIT" or "FIXED"
    self.runtime.uiScaleLimited180 = nil
    self.runtime.uiScaleLimitedReason180 = nil
    self:UpdateWindowResizeBounds180()
    self:RestoreWindowPosition180("scale")
    self:LayoutShellChrome180("scale")
    if self.ui and self.ui.guildProfile183 and self.ui.guildProfile183:IsVisible()
        and self.PositionGuildProfile183 and not self.ui.guildProfile183.otlDetached183 then
        self:PositionGuildProfile183("scale")
    end
    return effective
end

function OTLGM:UpdateWindowResizeBounds180()
    if not self.ui or not self.ui.main then return false end
    local frame = self.ui.main
    local minWidth, minHeight = 1000, 700
    local fitMode = OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.uiScaleModeR2 == "FIT"
    local maxWidth, maxHeight
    if fitMode then
        maxWidth, maxHeight = self:GetWindowMaximumSize180(self:GetFrameScaleRelativeToUIParent180(frame))
    else
        maxWidth, maxHeight = 2600, 1600
    end
    if frame.SetMinResize then frame:SetMinResize(minWidth, minHeight) end
    if frame.SetMaxResize then frame:SetMaxResize(maxWidth, maxHeight) end
    frame.otlMinWidth180, frame.otlMinHeight180 = minWidth, minHeight
    frame.otlMaxWidth180, frame.otlMaxHeight180 = maxWidth, maxHeight
    return true
end

function OTLGM:SaveWindowGeometry180(reason)
    if not self.ui or not self.ui.main or not OTLGM_DB or not OTLGM_DB.settings then return false end
    local frame = self.ui.main
    OTLGM_DB.settings.windowWidth180 = math.floor((frame:GetWidth() or 1160) + 0.5)
    OTLGM_DB.settings.windowHeight180 = math.floor((frame:GetHeight() or 740) + 0.5)
    local x, y = self:GetFrameCenterOffset180(frame)
    local parentWidth, parentHeight = self:GetPositionViewportMetrics180()
    OTLGM_DB.settings.windowX = x
    OTLGM_DB.settings.windowY = y
    OTLGM_DB.settings.windowNX180 = x / math.max(1, parentWidth)
    OTLGM_DB.settings.windowNY180 = y / math.max(1, parentHeight)
    if reason == "resize-stop" and not (self.runtime and self.runtime.applyingWindowPreset180) then
        OTLGM_DB.settings.windowSizePreset180 = "CUSTOM"
    end
    self.runtime = self.runtime or {}
    self.runtime.lastWindowGeometryReason180 = reason or "save"
    return true
end

function OTLGM:LayoutShellDrawers180(reason)
    if not self.ui then return false end
    local action = self.ui.actionCenterDrawer
    if action then
        local height = math.max(420, tonumber(action:GetHeight()) or 576)
        local previousVisible = tonumber(action.visibleRowCount)
        local visible = math.max(5, math.min(action.rowPoolCount180 or 12, math.floor((height - 108) / 53)))
        action.visibleRowCount = visible
        if previousVisible and previousVisible ~= visible and self.ui.activeDrawer == action then self:MarkDrawerDataRefresh180("actionCenter") end
        local index
        for index = 1, table.getn(action.rows or {}) do
            local row = action.rows[index]
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", action, "TOPLEFT", 18, -92 - ((index - 1) * 53))
            if index > visible then row:Hide() end
        end
        action.scroll:ClearAllPoints()
        action.scroll:SetPoint("TOPRIGHT", action, "TOPRIGHT", -10, -92)
        action.scroll:SetHeight(math.max(120, (visible * 53) - 8))
    end
    local addon = self.ui.addonUsersDrawer
    if addon then
        local height = math.max(420, tonumber(addon:GetHeight()) or 576)
        local previousVisible = tonumber(addon.visibleRowCount)
        local visible = math.max(5, math.min(addon.rowPoolCount180 or 12, math.floor((height - 220) / 43)))
        addon.visibleRowCount = visible
        if previousVisible and previousVisible ~= visible and self.ui.activeDrawer == addon then self:MarkDrawerDataRefresh180("addonUsers") end
        local index
        for index = 1, table.getn(addon.rows or {}) do
            local row = addon.rows[index]
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", addon, "TOPLEFT", 18, -166 - ((index - 1) * 43))
            if index > visible then row:Hide() end
        end
        addon.scroll:ClearAllPoints()
        addon.scroll:SetPoint("TOPRIGHT", addon, "TOPRIGHT", -14, -166)
        addon.scroll:SetHeight(math.max(120, (visible * 43) - 4))
        addon.copy:ClearAllPoints()
        addon.copy:SetPoint("BOTTOMLEFT", addon, "BOTTOMLEFT", 18, 14)
    end
    self.runtime = self.runtime or {}
    self.runtime.lastDrawerLayout180 = reason or "layout"
    return true
end

function OTLGM:LayoutShellChrome180(reason)
    if not self.ui or not self.ui.main then return false end
    local frame = self.ui.main
    local width = math.max(1000, tonumber(frame:GetWidth()) or 1160)
    local height = math.max(700, tonumber(frame:GetHeight()) or 740)
    local contentWidth = math.max(776, width - 224)
    local contentHeight = math.max(556, height - 144)
    if self.ui.header then self.ui.header:SetWidth(width - 24) end
    if self.ui.sidebar then self.ui.sidebar:SetHeight(height - 88) end
    if self.ui.pageHeader then self.ui.pageHeader:SetWidth(contentWidth) end
    if self.ui.pageSubtitle then self.ui.pageSubtitle:SetWidth(math.max(260, contentWidth - 408)) end
    if self.ui.contentHost then
        self.runtime = self.runtime or {}
        self.runtime.shellChromeApplying180 = true
        self.ui.contentHost:SetWidth(contentWidth)
        self.ui.contentHost:SetHeight(contentHeight)
        self.runtime.shellChromeApplying180 = nil
    end
    if self.ui.headerDate then
        self.ui.headerDate:ClearAllPoints()
        self.ui.headerDate:SetPoint("CENTER", self.ui.header, "CENTER", 0, 0)
    end
    local drawers = { self.ui.actionCenterDrawer, self.ui.addonUsersDrawer }
    local index, drawer
    for index = 1, table.getn(drawers) do
        drawer = drawers[index]
        if drawer then
            drawer:ClearAllPoints()
            drawer:SetPoint("TOPRIGHT", self.ui.drawerHost, "TOPRIGHT", -10, -10)
            drawer:SetHeight(math.max(420, contentHeight - 20))
        end
    end
    self:LayoutShellDrawers180(reason or "chrome")
    -- During an active resize only the visible page needs to follow the cursor.
    -- Hidden pages receive one complete pass at interaction end. This removes
    -- repeated work from a path that can otherwise run every rendered frame.
    local interaction = self.runtime and self.runtime.windowInteraction180
    if interaction and interaction.mode == "RESIZE" and self.ui.currentPage then
        self:LayoutShellPage180(self.ui.currentPage, reason or "chrome")
    else
        self:LayoutAllShellPages180(reason or "chrome")
    end
    self.runtime = self.runtime or {}
    self.runtime.lastShellChromeLayout180 = { width = width, height = height, reason = reason }
    if not interaction then self:FlushLayoutDataRefresh180(reason or "layout-capacity") end
    return true
end

-- Keep Inside is a position/reachability policy only.  It must never silently
-- change UI scale or force a large window back to the centre.  Large/custom
-- workspaces may extend beyond an edge, but a substantial part of the title
-- area always remains reachable so the user can drag the window back.
function OTLGM:GetSoftClampedWindowOffset180(x, y, parentWidth, parentHeight, frameWidth, frameHeight, scale, strict)
    parentWidth = math.max(1, tonumber(parentWidth) or 1024)
    parentHeight = math.max(1, tonumber(parentHeight) or 768)
    frameWidth = math.max(1, tonumber(frameWidth) or 1160)
    frameHeight = math.max(1, tonumber(frameHeight) or 740)
    scale = math.max(0.01, tonumber(scale) or 1)
    x = tonumber(x) or 0
    y = tonumber(y) or 10
    if not strict then return x, y end

    local margin = 3
    local halfParentWidth = parentWidth / 2
    local halfParentHeight = parentHeight / 2
    local visualWidth = frameWidth * scale
    local visualHeight = frameHeight * scale
    local halfFrameWidth = visualWidth / 2
    local halfFrameHeight = visualHeight / 2

    local minimumX, maximumX
    if visualWidth <= parentWidth - (margin * 2) then
        -- Normal case: the whole window fits.  Keep the complete visual frame
        -- on-screen and let it travel right up to either screen edge.
        minimumX = -halfParentWidth + halfFrameWidth + margin
        maximumX = halfParentWidth - halfFrameWidth - margin
    else
        -- Oversized custom/XL workspace: full containment is impossible. Pan
        -- only across the actual overflow so the window never jumps far away
        -- merely because it is a few pixels wider than the viewport.
        local overflowX = math.max(0, visualWidth - (parentWidth - (margin * 2)))
        minimumX = -(overflowX / 2)
        maximumX = overflowX / 2
    end

    local minimumY, maximumY
    if visualHeight <= parentHeight - (margin * 2) then
        -- Same rule vertically when the frame fits: full containment with only
        -- a tiny safety margin, not a centre-biased snap range.
        minimumY = -halfParentHeight + halfFrameHeight + margin
        maximumY = halfParentHeight - halfFrameHeight - margin
    else
        -- A taller-than-screen workspace cannot be fully contained. Anchor its
        -- title edge at the top and allow only a modest downward travel band.
        -- This keeps the title bar permanently reachable and avoids the old
        -- pathological case where a 6px overflow suddenly allowed most of the
        -- window to disappear below the screen.
        local topAlignedY = halfParentHeight - margin - halfFrameHeight
        local travelDown = math.min(180, math.max(0, parentHeight * 0.20))
        minimumY = topAlignedY - travelDown
        maximumY = topAlignedY
    end

    if minimumX > maximumX then minimumX, maximumX = maximumX, minimumX end
    if minimumY > maximumY then minimumY, maximumY = maximumY, minimumY end
    return math.max(minimumX, math.min(maximumX, x)),
        math.max(minimumY, math.min(maximumY, y))
end

function OTLGM:GetRecoverableWindowOffset180(x, y, parentWidth, parentHeight, frameWidth, frameHeight, scale)
    parentWidth = math.max(1, tonumber(parentWidth) or 1024)
    parentHeight = math.max(1, tonumber(parentHeight) or 768)
    frameWidth = math.max(1, tonumber(frameWidth) or 1160)
    frameHeight = math.max(1, tonumber(frameHeight) or 740)
    scale = math.max(0.01, tonumber(scale) or 1)
    x, y = tonumber(x) or 0, tonumber(y) or 10
    local halfParentWidth, halfParentHeight = parentWidth / 2, parentHeight / 2
    local halfFrameWidth, halfFrameHeight = (frameWidth * scale) / 2, (frameHeight * scale) / 2
    local visibleX = 96
    local minimumX = -halfParentWidth - halfFrameWidth + visibleX
    local maximumX = halfParentWidth + halfFrameWidth - visibleX
    -- Recovery must expose the actual header, not merely any 34-pixel strip of
    -- the frame. Keep the top edge inside the viewport and at least 58 pixels
    -- above the bottom so the user can always grab the title area again.
    local minimumTop = -halfParentHeight + 58
    local maximumTop = halfParentHeight - 4
    local minimumY = minimumTop - halfFrameHeight
    local maximumY = maximumTop - halfFrameHeight
    if minimumY > maximumY then minimumY, maximumY = maximumY, minimumY end
    return math.max(minimumX, math.min(maximumX, x)), math.max(minimumY, math.min(maximumY, y))
end

function OTLGM:RestoreWindowPosition180(reason)
    if not self.ui or not self.ui.main or not UIParent or not OTLGM_DB or not OTLGM_DB.settings then return false end
    local frame = self.ui.main
    local parentWidth, parentHeight, parentScale = self:GetPositionViewportMetrics180()
    local frameWidth = frame.GetWidth and frame:GetWidth() or 1160
    local frameHeight = frame.GetHeight and frame:GetHeight() or 740
    local scale = self:GetFrameScaleRelativeToUIParent180(frame)
    local strict = OTLGM_DB.settings.keepWindowInsideScreen180 and true or false
    -- Native SetClampedToScreen is deliberately disabled. On Vanilla-derived
    -- clients and UI replacements it can apply a second scale-dependent clamp
    -- after our saved coordinates, which is the source of the visible snap.
    if frame.SetClampedToScreen then frame:SetClampedToScreen(false) end
    local x = tonumber(OTLGM_DB.settings.windowX) or 0
    local y = tonumber(OTLGM_DB.settings.windowY) or 10
    local normalizedX = tonumber(OTLGM_DB.settings.windowNX180)
    local normalizedY = tonumber(OTLGM_DB.settings.windowNY180)
    if reason == "build" or reason == "show" or reason == "world" then
        if normalizedX then x = normalizedX * parentWidth end
        if normalizedY then y = normalizedY * parentHeight end
    end
    if strict then
        x, y = self:GetSoftClampedWindowOffset180(x, y, parentWidth, parentHeight, frameWidth, frameHeight, scale, true)
    elseif reason == "build" or reason == "show" or reason == "world" or reason == "recovery" then
        x, y = self:GetRecoverableWindowOffset180(x, y, parentWidth, parentHeight, frameWidth, frameHeight, scale)
    end
    x, y = self:SnapWindowGeometryToPixels183(x, y, nil, nil, parentScale)
    OTLGM_DB.settings.windowX, OTLGM_DB.settings.windowY = x, y
    OTLGM_DB.settings.windowNX180, OTLGM_DB.settings.windowNY180 = x / parentWidth, y / parentHeight
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    self.runtime = self.runtime or {}
    self.runtime.lastWindowPositionReason180 = reason or "restore"
    self.runtime.windowSoftClamp180 = { x = x, y = y, strict = strict }
    return true
end


function OTLGM:GetParkCenterOffset180()
    local button = self.ui and self.ui.shellParkTab
    if not button or not UIParent then return 0, 0 end
    if button.otlParkAnchorX182 ~= nil and button.otlParkAnchorY182 ~= nil then
        return tonumber(button.otlParkAnchorX182) or 0, tonumber(button.otlParkAnchorY182) or 0
    end
    local parentWidth = self:GetPositionViewportMetrics180()
    if button.GetPoint then
        local point, relativeTo, relativePoint, x, y = button:GetPoint(1)
        if point == "CENTER" and (relativeTo == UIParent or relativeTo == nil) and (relativePoint == "CENTER" or relativePoint == nil) then
            return tonumber(x) or 0, tonumber(y) or 0
        end
    end
    return tonumber(OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.parkX180) or ((parentWidth / 2) - 30),
        tonumber(OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.parkY180) or -176
end

function OTLGM:GetClampedParkOffset180(x, y)
    if self.GetClampedQuickDockAnchor182 and self.ui and self.ui.quickDockLion182 then
        return self:GetClampedQuickDockAnchor182(x, y)
    end
    local parentWidth, parentHeight = self:GetPositionViewportMetrics180()
    local button = self.ui and self.ui.shellParkTab
    local scale = button and self:GetFrameScaleRelativeToUIParent180(button) or 1
    local halfWidth = ((button and button:GetWidth() or 44) * scale) / 2
    local halfHeight = ((button and button:GetHeight() or 44) * scale) / 2
    local margin = 2
    local maximumX = math.max(0, (parentWidth / 2) - halfWidth - margin)
    local maximumY = math.max(0, (parentHeight / 2) - halfHeight - margin)
    return math.max(-maximumX, math.min(maximumX, tonumber(x) or 0)),
        math.max(-maximumY, math.min(maximumY, tonumber(y) or 0))
end

function OTLGM:SaveParkPosition180(reason)
    if not self.ui or not self.ui.shellParkTab or not OTLGM_DB or not OTLGM_DB.settings then return false end
    local x, y = self:GetParkCenterOffset180()
    local parentWidth, parentHeight = self:GetPositionViewportMetrics180()
    x, y = self:GetClampedParkOffset180(x, y)
    OTLGM_DB.settings.parkX180, OTLGM_DB.settings.parkY180 = x, y
    OTLGM_DB.settings.parkNX180, OTLGM_DB.settings.parkNY180 = x / parentWidth, y / parentHeight
    self.runtime = self.runtime or {}
    self.runtime.lastParkPositionReason180 = reason or "save"
    return true
end

function OTLGM:RestoreParkPosition180(reason)
    if not self.ui or not self.ui.shellParkTab or not UIParent or not OTLGM_DB or not OTLGM_DB.settings then return false end
    local parentWidth, parentHeight = self:GetPositionViewportMetrics180()
    local x = tonumber(OTLGM_DB.settings.parkX180)
    local y = tonumber(OTLGM_DB.settings.parkY180)
    if x == nil then x = (parentWidth / 2) - 28 end
    if y == nil then y = -176 end
    local nx, ny = tonumber(OTLGM_DB.settings.parkNX180), tonumber(OTLGM_DB.settings.parkNY180)
    if reason == "build" or reason == "show" or reason == "world" then
        if nx then x = nx * parentWidth end
        if ny then y = ny * parentHeight end
    end
    x, y = self:GetClampedParkOffset180(x, y)
    OTLGM_DB.settings.parkX180, OTLGM_DB.settings.parkY180 = x, y
    OTLGM_DB.settings.parkNX180, OTLGM_DB.settings.parkNY180 = x / parentWidth, y / parentHeight
    if self.PositionQuickDock182 and self.ui.quickDockLion182 then
        self:PositionQuickDock182(x, y)
    else
        self.ui.shellParkTab:ClearAllPoints()
        self.ui.shellParkTab:SetPoint("CENTER", UIParent, "CENTER", x, y)
    end
    return true
end

function OTLGM:BeginParkDrag180()
    local button = self.ui and self.ui.shellParkTab
    if not button or not GetCursorPosition then return false end
    local cursorX, cursorY = GetCursorPosition()
    local _, _, parentScale = self:GetUIParentMetrics180()
    local startX, startY = self:GetParkCenterOffset180()
    button.otlParkDrag180 = {
        cursorX = cursorX / parentScale,
        cursorY = cursorY / parentScale,
        startX = startX,
        startY = startY,
        moved = false,
    }
    button:SetScript("OnUpdate", function()
        local activeButton = button
        local ok, problem = pcall(function()
            if not activeButton.otlParkDrag180 or not GetCursorPosition then return end
            if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
                OTLGM:EndParkDrag180()
                return
            end
            local cx, cy = GetCursorPosition()
            local _, _, ps = OTLGM:GetUIParentMetrics180()
            cx, cy = cx / ps, cy / ps
            local dx, dy = cx - activeButton.otlParkDrag180.cursorX, cy - activeButton.otlParkDrag180.cursorY
            if math.abs(dx) > 1 or math.abs(dy) > 1 then activeButton.otlParkDrag180.moved = true end
            local x, y = OTLGM:GetClampedParkOffset180(activeButton.otlParkDrag180.startX + dx, activeButton.otlParkDrag180.startY + dy)
            if OTLGM.PositionQuickDock182 and OTLGM.ui and OTLGM.ui.quickDockLion182 then
                OTLGM:PositionQuickDock182(x, y)
            else
                activeButton:ClearAllPoints()
                activeButton:SetPoint("CENTER", UIParent, "CENTER", x, y)
            end
        end)
        if not ok then
            activeButton:SetScript("OnUpdate", nil)
            activeButton.otlParkDrag180 = nil
            if OTLGM and OTLGM.RecordInternalIssueRC3 then pcall(OTLGM.RecordInternalIssueRC3, OTLGM, "UI/PARK_INTERACTION", problem) end
        end
    end)
    return true
end

function OTLGM:EndParkDrag180()
    local button = self.ui and self.ui.shellParkTab
    if not button then return false end
    local moved = button.otlParkDrag180 and button.otlParkDrag180.moved
    button:SetScript("OnUpdate", nil)
    button.otlParkDrag180 = nil
    if moved then
        button.otlSuppressClickUntil180 = GetTime and (GetTime() + 0.20) or nil
    end
    self:SaveParkPosition180("drag-stop")
    self:RestoreParkPosition180("drag-stop")
    return true
end

function OTLGM:ShowQuickDockAfterImplicitHide183(reason)
    if not self.ui or not self.ui.shellBuilt or not self.ui.shellParkTab then return false end
    local settings = OTLGM_DB and OTLGM_DB.settings or {}
    if settings.closeToQuickDock183 == false then return false end
    if self.runtime and self.runtime.suppressQuickDockOnMainHide183 then return false end
    self:RestoreParkPosition180(reason or "escape")
    self.ui.shellParkTab:Show()
    self.runtime = self.runtime or {}
    self.runtime.lastImplicitPark183 = tostring(reason or "implicit-hide")
    return true
end

function OTLGM:ReleaseBlizzardSocialPanel183(reason)
    local released = false
    local frames = {}
    if FriendsFrame then table.insert(frames, FriendsFrame) end
    if GuildFrame and GuildFrame ~= FriendsFrame then table.insert(frames, GuildFrame) end
    local seen = {}
    local index, frame
    for index = 1, table.getn(frames) do
        frame = frames[index]
        if frame and not seen[frame] then
            seen[frame] = true
            local shown = frame.IsShown and frame:IsShown()
            if shown then
                -- Friends/Guild are managed UIPanels on 1.12-derived clients.
                -- Hiding them with Frame:Hide() leaves UIParent's panel slot
                -- occupied on some clients: the next profession/trade window is
                -- shifted right and Escape can keep closing a "phantom" panel.
                local usedManager = false
                if HideUIPanel then
                    local ok = pcall(HideUIPanel, frame)
                    usedManager = ok and true or false
                end
                if frame.IsShown and frame:IsShown() and frame.Hide then frame:Hide() end
                released = true
                self.runtime = self.runtime or {}
                self.runtime.lastSocialPanelRelease183 = tostring(reason or "guild-shortcut")
                self.runtime.socialPanelReleaseUsedManager183 = usedManager
            end
        end
    end
    if released then
        if UpdateUIPanelPositions then pcall(UpdateUIPanelPositions)
        elseif UIParent_ManageFramePositions then pcall(UIParent_ManageFramePositions) end
    end
    return released
end

function OTLGM:ResetBlizzardSocialTab183(reason)
    -- Explicit Guild clicks are routed into the addon, but Blizzard remembers
    -- the last Social tab. If we leave selectedTab=3 behind, opening Social
    -- later can immediately revisit Guild before the player can reach Friends /
    -- Who / Raid. Reset only Blizzard's remembered tab state; the Social frame
    -- is about to close, so this does not create a visible tab flash.
    if not FriendsFrame then return false end
    local changed = false
    if PanelTemplates_SetTab then
        local ok = pcall(PanelTemplates_SetTab, FriendsFrame, 1)
        if ok then changed = true end
    end
    if tonumber(FriendsFrame.selectedTab) ~= 1 then
        FriendsFrame.selectedTab = 1
        changed = true
    end
    self.runtime = self.runtime or {}
    self.runtime.socialGuildLastSelected183 = nil
    self.runtime.lastSocialTabReset183 = tostring(reason or "guild-redirect")
    return changed
end

function OTLGM:OpenOnlineRosterFromSocial183()
    if OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.socialGuildOpensRoster183 == false then return false end
    if not self.ui or not self.ui.main then self:BuildUI() end
    if not self.ui or not self.ui.main then return false end
    self.runtime = self.runtime or {}
    self.runtime.socialGuildLastSelected183 = true
    self:ResetBlizzardSocialTab183("social-guild-open")
    self:ReleaseBlizzardSocialPanel183("social-guild-open")
    if self.ui.shellParkTab then self.ui.shellParkTab:Hide() end
    if not self.ui.main:IsVisible() then
        if self.RebaseUIParentGeometry180 then self:RebaseUIParentGeometry180("social-guild", false) end
        self:RestoreWindowPosition180("show")
        self.ui.main:Show()
    end
    if not self:ShowPage("roster") then return false end
    local settings = OTLGM_DB and OTLGM_DB.settings or {}
    settings.rosterSearch = ""
    settings.rosterFilter = "ONLINE"
    settings.rosterRankFilter = ""
    settings.rosterProfessionFilter = ""
    self.ui.rosterFilter = "ONLINE"
    self.ui.rosterRankFilter = nil
    self.ui.rosterProfessionFilter = nil
    self.ui.rosterOffset = 0
    if self.ui.rosterSearch and UI.SetSearchText then UI:SetSearchText(self.ui.rosterSearch, "") end
    if self.RefreshRosterPage then self:RefreshRosterPage("social-guild") end
    if self.ScheduleVisiblePageClock180 then self:ScheduleVisiblePageClock180("roster") end
    self.runtime = self.runtime or {}
    self.runtime.socialGuildShortcut183 = (tonumber(self.runtime.socialGuildShortcut183) or 0) + 1
    return true
end

function OTLGM:IsNativeGuildSocialTabSelected183()
    if self.runtime and self.runtime.socialGuildLastSelected183 then return true end
    local selected
    if FriendsFrame and PanelTemplates_GetSelectedTab then
        local ok, value = pcall(PanelTemplates_GetSelectedTab, FriendsFrame)
        if ok then selected = tonumber(value) end
    end
    if not selected and FriendsFrame then selected = tonumber(FriendsFrame.selectedTab) end
    -- The classic Social frame uses tab 3 for Guild. Keep this only as a
    -- fallback; the click hook below is the authoritative signal.
    return selected == 3 and FriendsFrameTab3 and true or false
end

function OTLGM:InstallSocialGuildHook183()
    self.runtime = self.runtime or {}
    local candidates = { FriendsFrameTab3, FriendsFrameGuildButton, GuildFrameTab }
    local hooked, index = 0, nil
    for index = 1, table.getn(candidates) do
        local button = candidates[index]
        if button and button.GetScript and button.SetScript and not button.otlGuildRosterHook183 then
            local previous = button:GetScript("OnClick")
            button.otlGuildRosterHook183 = true
            button:SetScript("OnClick", function()
                if OTLGM and OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.socialGuildOpensRoster183 ~= false then
                    -- Do not run the Blizzard Guild-tab click first. Doing so
                    -- briefly registers/shows a managed UIPanel and then hiding
                    -- it directly can leave a phantom left panel behind.
                    OTLGM.runtime = OTLGM.runtime or {}
                    OTLGM.runtime.socialGuildLastSelected183 = true
                    OTLGM:OpenOnlineRosterFromSocial183()
                    return
                end
                if previous then previous(this, arg1) end
            end)
            hooked = hooked + 1
        elseif button and button.otlGuildRosterHook183 then
            hooked = hooked + 1
        end
    end

    -- Never redirect merely because Blizzard Social remembers Guild as its
    -- previous tab. Also repair an already-stale selectedTab=3 left by an older
    -- addon build: opening Social should land on Friends, not re-enter Guild.
    -- The explicit Guild-tab OnClick hook above remains the only redirect.
    if FriendsFrame and FriendsFrame.GetScript and FriendsFrame.SetScript and not FriendsFrame.otlGuildRosterOnShow183 then
        local previousShow = FriendsFrame:GetScript("OnShow")
        FriendsFrame.otlGuildRosterOnShow183 = true
        FriendsFrame:SetScript("OnShow", function()
            if OTLGM and not (OTLGM.runtime and OTLGM.runtime.allowNativeGuildOnce185)
                and tonumber(FriendsFrame and FriendsFrame.selectedTab) == 3
                and OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.socialGuildOpensRoster183 ~= false then
                OTLGM:ResetBlizzardSocialTab183("social-open-stale-guild")
            end
            if previousShow then previousShow() end
            if OTLGM then
                OTLGM.runtime = OTLGM.runtime or {}
                OTLGM.runtime.socialGuildLastSelected183 = nil
            end
        end)
    end

    -- Clear the remembered Guild intent when the player explicitly selects a
    -- different Social tab. This keeps Friends/Who/Raid usable normally.
    local otherTabs = { FriendsFrameTab1, FriendsFrameTab2, FriendsFrameTab4, FriendsFrameTab5 }
    for index = 1, table.getn(otherTabs) do
        local button = otherTabs[index]
        local isGuildButton = false
        local candidateIndex
        for candidateIndex = 1, table.getn(candidates) do if candidates[candidateIndex] == button then isGuildButton = true break end end
        if button and not isGuildButton and button.GetScript and button.SetScript and not button.otlGuildRosterOtherTab183 then
            local previous = button:GetScript("OnClick")
            button.otlGuildRosterOtherTab183 = true
            button:SetScript("OnClick", function()
                if OTLGM then
                    OTLGM.runtime = OTLGM.runtime or {}
                    OTLGM.runtime.socialGuildLastSelected183 = nil
                end
                if previous then previous(this, arg1) end
            end)
        end
    end

    self.runtime.socialGuildHooks183 = hooked
    return hooked > 0
end

function OTLGM:ParkWindow176()
    if not self.ui or not self.ui.main then return false end
    if not self:CloseShellTransient(true, "park", false) then return false end
    self:SaveWindowGeometry180("park")
    if self.ui.windowParkTab176 then self.ui.windowParkTab176:Hide() end
    if OTLGM_DB and OTLGM_DB.settings then OTLGM_DB.settings.windowParked176 = nil end
    self.ui.main:Hide()
    self:RestoreParkPosition180("show")
    self.ui.shellParkTab:Show()
    return true
end

-- Explicit hard-hide paths remain separate from Park. This keeps the main X
-- configurable while still giving a parked user an unambiguous way to put the
-- whole addon UI to sleep without changing any background data policy.
function OTLGM:HideQuickDock183(reason)
    if not self.ui or not self.ui.shellParkTab then return false end
    if self.CloseQuickDockPopover182 then self:CloseQuickDockPopover182() end
    if self.CancelQuickDockRecruitClock182 then self:CancelQuickDockRecruitClock182() end
    if self.ui.shellParkTab.otlParkDrag180 then self:EndParkDrag180() end
    self.ui.shellParkTab:Hide()
    if OTLGM_DB and OTLGM_DB.settings then OTLGM_DB.settings.windowParked176 = nil end
    self.runtime = self.runtime or {}
    self.runtime.lastQuickDockHide183 = tostring(reason or "explicit")
    return true
end

function OTLGM:HideMainWindow183(reason)
    if not self.ui or not self.ui.main then return false end
    if not self:CloseShellTransient(true, reason or "main-close", false) then return false end
    self:HideQuickDock183(reason or "main-close")
    if self.ui.windowParkTab176 then self.ui.windowParkTab176:Hide() end
    self.runtime = self.runtime or {}
    self.runtime.suppressQuickDockOnMainHide183 = true
    self.ui.main:Hide()
    self.runtime.suppressQuickDockOnMainHide183 = nil
    return true
end

function OTLGM:HandleMainClose183()
    local settings = OTLGM_DB and OTLGM_DB.settings or {}
    if settings.closeToQuickDock183 ~= false then return self:ParkWindow176() end
    return self:HideMainWindow183("main-x")
end

function OTLGM:UnparkWindow176()
    if not self.ui or not self.ui.main then return false end
    self.ui.shellParkTab:Hide()
    if self.ui.windowParkTab176 then self.ui.windowParkTab176:Hide() end
    if self.RebaseUIParentGeometry180 then self:RebaseUIParentGeometry180("unpark", false) end
    self:RestoreWindowPosition180("show")
    self.ui.main:Show()
    if self.ui.currentPage then self:LayoutShellPage180(self.ui.currentPage, "unpark") end
    local module = self.ui.currentPage and self.shellPageModules[self.ui.currentPage]
    if module then module:OnShow({ page = self.ui.currentPage, reason = "unpark" }) end
    self:RefreshVisiblePage()
    -- Parking hides the main frame and therefore correctly cancels foreground
    -- timers. Unparking must explicitly resume the one visible-page clock.
    if self.ui.currentPage then self:ScheduleVisiblePageClock180(self.ui.currentPage) end
    return true
end

function OTLGM:CenterWindow176()
    if not self.ui or not self.ui.main then return false end
    OTLGM_DB.settings.windowX = 0
    OTLGM_DB.settings.windowY = 10
    OTLGM_DB.settings.windowNX180 = 0
    local _, parentHeight180 = self:GetPositionViewportMetrics180()
    OTLGM_DB.settings.windowNY180 = 10 / math.max(1, parentHeight180)
    self.ui.main:ClearAllPoints()
    self.ui.main:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
    self.runtime = self.runtime or {}
    self.runtime.windowSoftClamp180 = { x = 0, y = 10, strict = OTLGM_DB.settings.keepWindowInsideScreen180 and true or false }
    self:SaveWindowGeometry180("center")
    return true
end

function OTLGM:ToggleUI()
    if not self.ui or not self.ui.main then self:BuildUI() end
    if not self.ui or not self.ui.main then return end
    if self.ui.main:IsVisible() then
        -- Minimap/slash toggle follows the same close policy as the main X.
        -- By default this leaves Quick Dock visible; the Settings toggle can
        -- still opt into a complete hard hide.
        self:HandleMainClose183()
    else
        self.ui.shellParkTab:Hide()
        if self.RebaseUIParentGeometry180 then self:RebaseUIParentGeometry180("show", false) end
        self:RestoreWindowPosition180("show")
        self.ui.main:Show()
        if self.ui.currentPage then self:LayoutShellPage180(self.ui.currentPage, "show") end
        self:RefreshNavigation()
        self:RefreshVisiblePage()
        -- OnHide cancels the foreground page clock so the addon is fully asleep.
        -- Reopening the same already-built page used to forget to arm it again,
        -- freezing the ST header and recruitment elapsed-time label until the
        -- user changed tabs.
        if self.ui.currentPage then self:ScheduleVisiblePageClock180(self.ui.currentPage) end
        self:StartAddonUsersCheck180()
    end
end

function OTLGM:BuildUI()
    if self.ui and self.ui.shellBuilt and self.ui.main then return end
    self.disableLegacyWindowPark176 = true
    self:EnsureDB()
    self.ui = self.ui or {}
    if OTLGM_DB and OTLGM_DB.settings then OTLGM_DB.settings.windowParked176 = nil end
    if self.ui.windowParkTab176 then self.ui.windowParkTab176:Hide() end

    local initialWidth = math.max(1000, math.min(2600, tonumber(OTLGM_DB.settings.windowWidth180) or 1160))
    local initialHeight = math.max(700, math.min(1600, tonumber(OTLGM_DB.settings.windowHeight180) or 740))
    local frame = UI:Surface(UIParent, "window", initialWidth, initialHeight, "OTLGM_MainFrame")
    frame:SetPoint("CENTER", UIParent, "CENTER", OTLGM_DB.settings.windowX or 0, OTLGM_DB.settings.windowY or 10)
    -- DIALOG keeps normal action bars and UI replacements below the addon
    -- while Blizzard tooltips and FULLSCREEN_DIALOG confirmation layers still
    -- remain above it.
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(50)
    if frame.SetToplevel then frame:SetToplevel(true) end
    frame:SetMovable(true)
    if frame.SetResizable then frame:SetResizable(true) end
    if frame.SetClampedToScreen then frame:SetClampedToScreen(false) end
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        if OTLGM then OTLGM:BeginWindowInteraction180("DRAG") end
    end)
    frame:SetScript("OnDragStop", function()
        if OTLGM then OTLGM:EndWindowInteraction180("drag-stop") end
    end)
    frame:SetScript("OnHide", function()
        if OTLGM then
            if OTLGM.runtime and OTLGM.runtime.windowInteraction180 then OTLGM:EndWindowInteraction180("hide") end
            OTLGM:CloseShellTransient(true, "main-hidden", true)
            -- Companion/special frames live on UIParent rather than under the
            -- main shell. Hide them explicitly so a child that is technically
            -- still IsShown() cannot consume another Escape after the addon is
            -- already gone.
            if OTLGM.CloseGuildProfile183 then OTLGM:CloseGuildProfile183("main-hidden") end
            if OTLGM.CloseQuickDockPopover182 then OTLGM:CloseQuickDockPopover182() end
            if OTLGM.ui and OTLGM.ui.raidTeamSelectionCatcher180 and OTLGM.ui.raidTeamSelectionCatcher180.Hide then
                OTLGM.ui.raidTeamSelectionCatcherProgrammatic180 = true
                OTLGM.ui.raidTeamSelectionCatcher180:Hide()
                OTLGM.ui.raidTeamSelectionCatcherProgrammatic180 = nil
            end
            local module = OTLGM.ui and OTLGM.ui.currentPage and OTLGM.shellPageModules[OTLGM.ui.currentPage]
            if module then module:OnHide() end
            if OTLGM.CancelTask180 then OTLGM:CancelTask180("page-clock") end
            if OTLGM.UpdateSchedulerState180 then OTLGM:UpdateSchedulerState180("ui-hidden") end
            -- UISpecialFrames hides the main window directly when Escape is pressed.
            -- Treat that implicit hide like Park, while explicit hard-hide paths set
            -- suppressQuickDockOnMainHide183 around their own Hide() call.
            OTLGM:ShowQuickDockAfterImplicitHide183("escape-or-specialframe")
        end
    end)
    frame:Hide()
    self.ui.main = frame
    -- Quiet chrome polish: a narrow gold cap and two short corner strokes make
    -- the window read as one deliberate frame without adding animation or any
    -- per-frame work. They move/scale with the window automatically.
    frame.topAccent184 = frame:CreateTexture(nil, "ARTWORK")
    frame.topAccent184:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -2)
    frame.topAccent184:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -2)
    frame.topAccent184:SetHeight(1)
    frame.topAccent184:SetTexture(C.gold[1], C.gold[2], C.gold[3], 0.44)
    frame.topCornerLeft184 = frame:CreateTexture(nil, "ARTWORK")
    frame.topCornerLeft184:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -2)
    frame.topCornerLeft184:SetWidth(54) frame.topCornerLeft184:SetHeight(2)
    frame.topCornerLeft184:SetTexture(C.gold[1], C.gold[2], C.gold[3], 0.82)
    frame.topCornerRight184 = frame:CreateTexture(nil, "ARTWORK")
    frame.topCornerRight184:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -2)
    frame.topCornerRight184:SetWidth(54) frame.topCornerRight184:SetHeight(2)
    frame.topCornerRight184:SetTexture(C.gold[1], C.gold[2], C.gold[3], 0.82)
    self:UpdateWindowResizeBounds180()
    frame:SetScript("OnSizeChanged", function()
        if not OTLGM or not OTLGM.ui or not OTLGM.ui.shellBuilt then return end
        if OTLGM.runtime and (OTLGM.runtime.applyingWindowPreset180 or OTLGM.runtime.geometryBatch180) then return end
        OTLGM:LayoutShellChrome180("window-size")
    end)
    local resizeGrip = CreateFrame("Button", nil, frame)
    if self.PrepareInteractiveControl170 then self:PrepareInteractiveControl170(resizeGrip, "button") end
    resizeGrip:SetWidth(24)
    resizeGrip:SetHeight(24)
    resizeGrip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    resizeGrip:SetFrameLevel(frame:GetFrameLevel() + 80)
    resizeGrip.texture = resizeGrip:CreateTexture(nil, "OVERLAY")
    resizeGrip.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip.texture:SetAllPoints(resizeGrip)
    resizeGrip:SetScript("OnMouseDown", function()
        if arg1 == "LeftButton" and OTLGM then OTLGM:BeginWindowInteraction180("RESIZE") end
    end)
    resizeGrip:SetScript("OnMouseUp", function()
        if OTLGM then OTLGM:EndWindowInteraction180("resize-stop") end
    end)
    resizeGrip.otlResizeGrip180 = true
    self.ui.resizeGrip180 = resizeGrip
    self.ui.shellBuilt = true
    if self.InstallSocialGuildHook183 then self:InstallSocialGuildHook183() end
    self.ui.v15Built = true
    self.ui152Loaded = true
    self.fullUILoaded = true
    AddSpecialFrame("OTLGM_MainFrame")
    self:RestoreWindowPosition180("build")

    -- Compact header.
    local header = UI:Surface(frame, "surface", 1136, 52)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12)
    self.ui.header = header
    local crestFrame = UI:Card(header, 42, 42)
    crestFrame:SetPoint("TOPLEFT", header, "TOPLEFT", 6, -5)
    local crest = crestFrame:CreateTexture(nil, "ARTWORK")
    crest:SetTexture("Interface\\AddOns\\OrderOfTheLionGM\\Assets\\LionCrest")
    crest:SetWidth(34)
    crest:SetHeight(34)
    crest:SetPoint("CENTER", crestFrame, "CENTER", 0, 0)
    self.ui.crestTexture = crest
    local guildTitle = MakeLabel(header, "ORDER OF THE LION", "GameFontNormalLarge", 58, -7, 300, "LEFT")
    guildTitle:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    local motto = MakeLabel(header, "Together We Grow Stronger", "GameFontNormalSmall", 58, -29, 300, "LEFT")
    motto:SetTextColor(C.white[1], C.white[2], C.white[3])
    self.ui.headerDate = MakeLabel(header, "", "GameFontNormalSmall", 452, -18, 236, "CENTER")
    self.ui.headerDate:SetTextColor(C.white[1], C.white[2], C.white[3])
    self.ui.actionCenterButton = UI:Button(header, "Action Center", 150, 30, function() OTLGM:ToggleActionCenter() end, "utility")
    self.ui.actionCenterButton:SetPoint("TOPRIGHT", header, "TOPRIGHT", -48, -11)
    self.ui.actionCenterButton.text:ClearAllPoints()
    self.ui.actionCenterButton.text:SetWidth(112)
    self.ui.actionCenterButton.text:SetPoint("LEFT", self.ui.actionCenterButton, "LEFT", 9, 0)
    self.ui.actionCenterBadge = UI:Badge(self.ui.actionCenterButton, 24, 16)
    self.ui.actionCenterBadge:SetPoint("RIGHT", self.ui.actionCenterButton, "RIGHT", -7, 0)
    self.ui.parkButton = UI:Button(header, "Park", 70, 30, function() OTLGM:ParkWindow176() end, "utility")
    self.ui.parkButton.otlTooltip = "Hide the full window and show the lightweight Quick Dock. Disable Quick Dock in Interface settings for crest-only parking."
    self.ui.parkButton.otlTooltipTitle = "Park window"
    self.ui.parkButton.icon = self.ui.parkButton:CreateTexture(nil, "ARTWORK")
    self.ui.parkButton.icon:SetTexture("Interface\\AddOns\\OrderOfTheLionGM\\Assets\\LionCrest")
    self.ui.parkButton.icon:SetWidth(17)
    self.ui.parkButton.icon:SetHeight(17)
    self.ui.parkButton.icon:SetPoint("LEFT", self.ui.parkButton, "LEFT", 7, 0)
    self.ui.parkButton.text:ClearAllPoints()
    self.ui.parkButton.text:SetPoint("LEFT", self.ui.parkButton, "LEFT", 28, 0)
    self.ui.parkButton.text:SetWidth(36)
    self.ui.parkButton:SetPoint("RIGHT", self.ui.actionCenterButton, "LEFT", -8, 0)
    local onlineIndicator = UI:Surface(header, "surface", 126, 26)
    onlineIndicator:SetPoint("RIGHT", self.ui.parkButton, "LEFT", -8, 0)
    onlineIndicator:EnableMouse(true)
    -- Do not use a Unicode bullet here. The stock 1.12 fonts used by OctoWoW
    -- can silently omit that glyph, which made the promised green online dot
    -- disappear even though the text itself was refreshed correctly. A real
    -- texture marker is deterministic on every supported client/font.
    onlineIndicator.dot = onlineIndicator:CreateTexture(nil, "ARTWORK")
    onlineIndicator.dot:SetWidth(7) onlineIndicator.dot:SetHeight(7)
    onlineIndicator.dot:SetPoint("LEFT", onlineIndicator, "LEFT", 13, 0)
    onlineIndicator.dot:SetTexture(0.42, 0.42, 0.42, 1)
    onlineIndicator.text = UI.Text(onlineIndicator, "— Online", "GameFontNormalSmall", "LEFT")
    onlineIndicator.text:SetPoint("LEFT", onlineIndicator.dot, "RIGHT", 7, 0)
    onlineIndicator.text:SetWidth(94)
    onlineIndicator:SetScript("OnEnter", function()
        if not OTLGM or not GameTooltip then return end
        local db = OTLGM.GetGuildDB and OTLGM:GetGuildDB() or nil
        local total = tonumber(db and db.lastTotal) or 0
        local online = tonumber(db and db.lastOnline) or 0
        local scanned = tonumber(db and db.lastScan) or 0
        GameTooltip:SetOwner(this, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Guild roster status", 1, 0.82, 0.35)
        if scanned > 0 then
            local age = math.max(0, OTLGM:Now() - scanned)
            local ageText
            if age < 60 then ageText = "less than a minute ago"
            elseif age < 3600 then ageText = tostring(math.floor(age / 60)) .. " min ago"
            elseif age < 86400 then ageText = tostring(math.floor(age / 3600)) .. " h ago"
            else ageText = tostring(math.floor(age / 86400)) .. " d ago" end
            GameTooltip:AddDoubleLine("Online / total", tostring(online) .. " / " .. tostring(total), 0.80, 0.80, 0.80, 0.45, 1, 0.45)
            GameTooltip:AddDoubleLine("Last full roster scan", ageText, 0.80, 0.80, 0.80, 1, 1, 1)
            local presenceAtR59 = tonumber(OTLGM.runtime and OTLGM.runtime.rosterPresenceLastAtR59) or 0
            if presenceAtR59 > scanned then
                local presenceAge = math.max(0, OTLGM:Now() - presenceAtR59)
                GameTooltip:AddDoubleLine("Online presence refreshed", tostring(math.floor(presenceAge)) .. "s ago", 0.80, 0.80, 0.80, 0.45, 1, 0.45)
            end
        else
            GameTooltip:AddLine("Roster information is not available yet. Use Refresh Roster when you want to update it.", 0.75, 0.75, 0.75, true)
        end
        GameTooltip:AddLine("This indicator only shows the latest roster information already available to the addon.", 0.55, 0.72, 1, true)
        GameTooltip:Show()
    end)
    onlineIndicator:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    self.ui.headerOnline183 = onlineIndicator
    self.ui.closeButton = UI:IconButton(header, "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 30, 30, function()
        OTLGM:HandleMainClose183()
    end, "Close", "danger")
    self.ui.closeButton:SetPoint("TOPRIGHT", header, "TOPRIGHT", -10, -11)
    self:RefreshHeaderOnlineIndicator183()

    -- Sidebar and owned page header/content host.
    local sidebar = UI:Surface(frame, "surface", 188, 652)
    sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -76)
    self.ui.sidebar = sidebar
    self.ui.navGuildButton = UI:Button(sidebar, "Guild", 78, 30, function() OTLGM:SetShellNavMode180("GUILD") end, "tab")
    self.ui.navGuildButton:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 12, -12)
    self.ui.navGuildButton.icon = self.ui.navGuildButton:CreateTexture(nil, "ARTWORK")
    self.ui.navGuildButton.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    self.ui.navGuildButton.icon:SetWidth(15)
    self.ui.navGuildButton.icon:SetHeight(15)
    self.ui.navGuildButton.icon:SetPoint("LEFT", self.ui.navGuildButton, "LEFT", 6, 0)
    self.ui.navGuildButton.text:ClearAllPoints()
    self.ui.navGuildButton.text:SetPoint("LEFT", self.ui.navGuildButton, "LEFT", 24, 0)
    self.ui.navGuildButton.text:SetWidth(48)
    self.ui.navOfficerButton = UI:Button(sidebar, "Officer", 78, 30, function() OTLGM:SetShellNavMode180("OFFICER") end, "tab")
    self.ui.navOfficerButton:SetPoint("LEFT", self.ui.navGuildButton, "RIGHT", 8, 0)
    self.ui.navOfficerButton.icon = self.ui.navOfficerButton:CreateTexture(nil, "ARTWORK")
    self.ui.navOfficerButton.icon:SetTexture("Interface\\Icons\\INV_Helmet_06")
    self.ui.navOfficerButton.icon:SetWidth(15)
    self.ui.navOfficerButton.icon:SetHeight(15)
    self.ui.navOfficerButton.icon:SetPoint("LEFT", self.ui.navOfficerButton, "LEFT", 6, 0)
    self.ui.navOfficerButton.text:ClearAllPoints()
    self.ui.navOfficerButton.text:SetPoint("LEFT", self.ui.navOfficerButton, "LEFT", 24, 0)
    self.ui.navOfficerButton.text:SetWidth(48)
    local sectionText = MakeLabel(sidebar, "NAVIGATION", "GameFontNormalSmall", 13, -54, 150, "LEFT")
    sectionText:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])

    self.ui.navButtons = {}
    local index
    for index = 1, table.getn(PAGE_DEFS) do
        local definition = PAGE_DEFS[index]
        if definition.group ~= "footer" then
            local capturedKey = definition.key
            local button = UI:Button(sidebar, definition.label, 164, 30, function() OTLGM:ShowPage(capturedKey) end, "nav")
            button.icon = button:CreateTexture(nil, "ARTWORK")
            button.icon:SetTexture(definition.icon)
            button.icon:SetWidth(17)
            button.icon:SetHeight(17)
            button.icon:SetPoint("LEFT", button, "LEFT", 8, 0)
            button.text:ClearAllPoints()
            button.text:SetPoint("LEFT", button, "LEFT", 31, 0)
            button.text:SetWidth(112)
            button.text:SetJustifyH("LEFT")
            button.unreadBadge = UI:Badge(button, 24, 16)
            button.unreadBadge:SetPoint("RIGHT", button, "RIGHT", -7, 0)
            button:Hide()
            self.ui.navButtons[capturedKey] = button
        end
    end
    self.ui.settingsButton = UI:Button(sidebar, "Settings", 164, 28, function() OTLGM:ShowPage("settings") end, "utility")
    self.ui.settingsButton:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 12, 44)
    self.ui.settingsButton.icon = self.ui.settingsButton:CreateTexture(nil, "ARTWORK")
    self.ui.settingsButton.icon:SetTexture("Interface\\Icons\\INV_Gizmo_02")
    self.ui.settingsButton.icon:SetWidth(16)
    self.ui.settingsButton.icon:SetHeight(16)
    self.ui.settingsButton.icon:SetPoint("LEFT", self.ui.settingsButton, "LEFT", 8, 0)
    self.ui.addonUsersButton = UI:Button(sidebar, "Sharing", 164, 28, function() OTLGM:ToggleAddonUsersDrawer() end, "utility")
    self.ui.addonUsersButton:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 12, 12)
    self.ui.addonUsersButton.icon = self.ui.addonUsersButton:CreateTexture(nil, "ARTWORK")
    self.ui.addonUsersButton.icon:SetTexture("Interface\\Icons\\INV_Misc_Rune_01")
    self.ui.addonUsersButton.icon:SetWidth(16)
    self.ui.addonUsersButton.icon:SetHeight(16)
    self.ui.addonUsersButton.icon:SetPoint("LEFT", self.ui.addonUsersButton, "LEFT", 8, 0)
    self.ui.settingsButton:ClearAllPoints()
    self.ui.settingsButton:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 12, 60)
    self.ui.addonUsersButton:ClearAllPoints()
    self.ui.addonUsersButton:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 12, 28)
    self.ui.publicVersion = UI.Text(sidebar, "OrderOfTheLionGM v" .. tostring(self:GetPublicVersion180()) .. "\n• by Hikol", "GameFontNormalSmall", "LEFT")
    self.ui.publicVersion:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 13, 4)
    self.ui.publicVersion:SetWidth(168)
    self.ui.publicVersion:SetHeight(22)
    self.ui.publicVersion:SetTextColor(C.grey[1], C.grey[2], C.grey[3])

    local pageHeader = UI:Surface(frame, "raised", 936, 46)
    pageHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 212, -76)
    self.ui.pageHeader = pageHeader
    -- Small icon plate: enough visual identity to separate pages at a glance,
    -- but deliberately static/texture-only so it has no interaction or update cost.
    self.ui.pageIconPlate184 = pageHeader:CreateTexture(nil, "BACKGROUND")
    self.ui.pageIconPlate184:SetWidth(30)
    self.ui.pageIconPlate184:SetHeight(30)
    self.ui.pageIconPlate184:SetPoint("LEFT", pageHeader, "LEFT", 9, 0)
    self.ui.pageIconPlate184:SetTexture(0.105, 0.070, 0.025, 1)
    self.ui.pageIcon184 = pageHeader:CreateTexture(nil, "ARTWORK")
    self.ui.pageIcon184:SetWidth(22)
    self.ui.pageIcon184:SetHeight(22)
    self.ui.pageIcon184:SetPoint("LEFT", pageHeader, "LEFT", 13, 0)
    if self.ui.pageIcon184.SetTexCoord then self.ui.pageIcon184:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    self.ui.pageIcon184:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    self.ui.pageTitle = MakeLabel(pageHeader, "", "GameFontNormalLarge", 43, -7, 330, "LEFT")
    self.ui.pageTitle:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    self.ui.pageSubtitle = MakeLabel(pageHeader, "", "GameFontNormalSmall", 390, -15, 528, "RIGHT")
    self.ui.pageSubtitle:SetTextColor(C.grey[1], C.grey[2], C.grey[3])

    local contentHost = UI:Surface(frame, "surface", 936, 596)
    contentHost:SetPoint("TOPLEFT", frame, "TOPLEFT", 212, -132)
    if contentHost.SetClipsChildren then contentHost:SetClipsChildren(true) end
    self.ui.contentHost = contentHost
    self.ui.content = contentHost
    contentHost:SetScript("OnSizeChanged", function()
        if not OTLGM or not OTLGM.ui or not OTLGM.ui.shellBuilt then return end
        -- LayoutShellChrome180 owns content-host sizing and performs exactly one
        -- page layout afterwards. Ignore the intermediate width/height events.
        if OTLGM.runtime and OTLGM.runtime.shellChromeApplying180 then return end
        local interaction = OTLGM.runtime and OTLGM.runtime.windowInteraction180
        if interaction and interaction.mode == "RESIZE" and OTLGM.ui.currentPage then
            OTLGM:LayoutShellPage180(OTLGM.ui.currentPage, "content-size")
        else
            OTLGM:LayoutAllShellPages180("content-size")
        end
    end)

    -- Exclusive transient hosts. They are hidden and therefore non-blocking
    -- until a drawer or modal is explicitly opened.
    local drawerHost = CreateFrame("Button", "OTLGM_DrawerHost", frame)
    if self.PrepareInteractiveControl170 then self:PrepareInteractiveControl170(drawerHost, "button") end
    drawerHost:SetPoint("TOPLEFT", contentHost, "TOPLEFT", 0, 0)
    drawerHost:SetPoint("BOTTOMRIGHT", contentHost, "BOTTOMRIGHT", 0, 0)
    drawerHost:SetFrameStrata("DIALOG")
    drawerHost:SetFrameLevel(frame:GetFrameLevel() + 60)
    drawerHost:EnableMouse(true)
    -- Keep character movement available while drawers are open. Escape is
    -- handled by the main shell / UISpecialFrames cleanup path instead.
    drawerHost:EnableKeyboard(false)
    local drawerShade = drawerHost:CreateTexture(nil, "BACKGROUND")
    drawerShade:SetTexture(0, 0, 0, 0.15)
    drawerShade:SetAllPoints(drawerHost)
    drawerHost.otlShadeAlpha = 0.15
    self.ui.drawerShade = drawerShade
    drawerHost:SetScript("OnClick", function() OTLGM:CloseShellDrawer() end)
    drawerHost:SetScript("OnHide", function()
        if OTLGM and OTLGM.ui and OTLGM.ui.activeDrawer then OTLGM.ui.activeDrawer:Hide() end
        if OTLGM and OTLGM.ui then OTLGM.ui.activeDrawer = nil end
    end)
    drawerHost:Hide()
    self.ui.drawerHost = drawerHost

    local modalHost = CreateFrame("Button", "OTLGM_ModalHost", frame)
    if self.PrepareInteractiveControl170 then self:PrepareInteractiveControl170(modalHost, "button") end
    modalHost:SetPoint("TOPLEFT", contentHost, "TOPLEFT", 0, 0)
    modalHost:SetPoint("BOTTOMRIGHT", contentHost, "BOTTOMRIGHT", 0, 0)
    modalHost:SetFrameStrata("FULLSCREEN_DIALOG")
    modalHost:SetFrameLevel(frame:GetFrameLevel() + 100)
    modalHost:EnableMouse(true)
    -- The shade blocks addon clicks behind a modal but deliberately does not
    -- capture keyboard input, so opening a form never stops normal movement.
    modalHost:EnableKeyboard(false)
    local modalShade = modalHost:CreateTexture(nil, "BACKGROUND")
    modalShade:SetTexture(0, 0, 0, 0.18)
    modalShade:SetAllPoints(modalHost)
    modalHost.otlShadeAlpha = 0.18
    self.ui.modalShade = modalShade
    modalHost:SetScript("OnClick", function() end)
    modalHost:SetScript("OnHide", function()
        if not OTLGM or not OTLGM.ui or OTLGM.ui.modalHostClosing180 then return end
        local stack = OTLGM.ui.modalStack180 or {}
        local index
        for index = table.getn(stack), 1, -1 do
            local frame = stack[index]
            if frame and frame.Hide then
                frame.otlClosing180 = true
                frame:Hide()
                frame.otlClosing180 = nil
            end
        end
        OTLGM.ui.modalStack180 = {}
        OTLGM.ui.activeModal = nil
    end)
    modalHost:Hide()
    self.ui.modalHost = modalHost

    self.ui.operationHost = UI:Card(frame, 430, 48)
    self.ui.operationHost:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -22, -126)
    self.ui.operationHost:SetFrameLevel(frame:GetFrameLevel() + 40)
    self.ui.operationText = MakeLabel(self.ui.operationHost, "", "GameFontNormalSmall", 10, -16, 310, "LEFT")
    self.ui.operationText:SetTextColor(C.red[1], C.red[2], C.red[3])
    self.ui.operationRetry = UI:Button(self.ui.operationHost, "Retry", 82, 26, function(button)
        local handler = button.otlRetryHandler
        OTLGM:ClearOperationError()
        if handler then handler() end
    end, "utility")
    self.ui.operationRetry:SetPoint("RIGHT", self.ui.operationHost, "RIGHT", -9, 0)
    self.ui.operationHost:Hide()

    self.ui.shellToast = UI:Toast(frame, 400)
    self.ui.shellToast:SetPoint("TOP", frame, "TOP", 0, -72)
    self.ui.shellToast:SetFrameLevel(frame:GetFrameLevel() + 50)

    local parkTab = self:BuildQuickDock182()
    self:RestoreParkPosition180("build")
    if self.InstallSocialGuildHook183 then self:InstallSocialGuildHook183() end

    self.ui.pages = {}
    for index = 1, table.getn(PAGE_DEFS) do
        local key = PAGE_DEFS[index].key
        self.ui.pages[key] = { otlLazyShell = true, pageKey = key }
    end

    self:BuildPlayerMenus()
    local initialScaleRequest180 = OTLGM_DB.settings.uiScaleModeR2 == "FIT" and "FIT" or (OTLGM_DB.settings.uiScale or 1)
    if self:GetWindowSizePreset180() == "MAX" then
        self:SetWindowSizePreset180("MAX", { preserveNormalized = true, skipSettingsRefresh = true, reason = "build" })
    else
        self:ApplyUIScale(initialScaleRequest180)
    end
    self:RememberUIParentMetrics180()
    self:RefreshNavigation()
    local requested = OTLGM_DB.settings.openHome and "home" or (OTLGM_DB.settings.lastPage or "home")
    if not self:GetShellPageDefinition(requested) then requested = "home" end
    self:ShowPage(requested)
end

-- All page dialogs are rebound to the one ContentHost-scoped modal owner.
-- No page is allowed to restore the former UIParent/full-window overlay.
function OTLGM:RegisterModal152(frame)
    if not frame then return false end
    self.ui.shellRegisteredModals = self.ui.shellRegisteredModals or {}
    local index
    for index = 1, table.getn(self.ui.shellRegisteredModals) do
        if self.ui.shellRegisteredModals[index] == frame then return true end
    end
    table.insert(self.ui.shellRegisteredModals, frame)
    frame.otlShellModal = true
    if frame.SetParent and self.ui and self.ui.modalHost then
        frame:SetParent(self.ui.modalHost)
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", self.ui.modalHost, "CENTER", 0, 0)
    end
    if self.NormalizeEditBoxes180 then self:NormalizeEditBoxes180(frame) end
    frame:Hide()
    return true
end

function OTLGM:ShowModal152(frame)
    return self:ShowShellModal(frame, false)
end

function OTLGM:OpenExclusiveModalR5(frame)
    if self.ui and self.ui.activeModal and self.ui.activeModal ~= frame then
        self:CloseModal180(self.ui.activeModal, "exclusive-replace")
    end
    return self:ShowShellModal(frame, false)
end

function OTLGM:CloseExclusiveModalR5(frame)
    return self:CloseModal180(frame, "exclusive-close")
end

function OTLGM:GetNativeUIDiagnostics180()
    local ui = self.ui or {}
    local registered, built = 0, 0
    local key, module
    for key, module in pairs(self.shellPageModules or {}) do
        registered = registered + 1
        if module and module.root and module.root.otlBuilt then built = built + 1 end
    end
    local stack = ui.modalStack180 or {}
    local active = ui.activeModal or stack[table.getn(stack)]
    local interaction = self.runtime and self.runtime.interactionAudit170 or {}
    return {
        loaded = ui.main ~= nil and ui.contentHost ~= nil and registered > 0,
        registered = registered,
        built = built,
        activePage = ui.currentPage or "none",
        buttons = tonumber(interaction.buttons) or 0,
        editBoxes = tonumber(interaction.editBoxes) or 0,
        repaired = tonumber(interaction.repaired) or 0,
        interactionScope = "legacy audit counters",
        chatShield = (ui.chatMenuShield157 or ui.contextMenuCatcher) and "Loaded" or "Inactive / not required",
        modalDepth = table.getn(stack),
        activeModal = active and ((active.GetName and active:GetName()) or active.otlDiagnosticName180 or "unnamed modal") or "none",
    }
end

OTLGM:RegisterModule("UIShell180", {
    stage = "B",
    revision = 4,
    standalone = true,
    lazyPages = true,
    nativeContentHost = true,
    pageContract = true,
    noLegacyWindowAdapter = true,
    noOnUpdate = true,
})
