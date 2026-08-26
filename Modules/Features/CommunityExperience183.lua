-- Order of the Lion Guild Manager 1.8.3
-- Static onboarding and bounded "Since Your Last Visit" counters.
-- No history scan, event frame, timer, network request or OnUpdate is added.

if not OTLGM or not OTLGM.UI then return end

local UI = OTLGM.UI
local C = UI.colors
local MAX_VISIT_KEYS_183 = 64

local VISIT_KINDS_183 = {
    { key = "members", singular = "new guild member", plural = "new guild members", page = "roster" },
    { key = "ranks", singular = "guild rank change", plural = "guild rank changes", page = "roster" },
    { key = "announcements", singular = "new guild post", plural = "new guild posts", page = "home" },
    { key = "achievements", singular = "achievement completed", plural = "achievements completed", page = "achievements" },
    { key = "raids", singular = "raid update", plural = "raid updates", page = "pve" },
}

local WELCOME_ITEMS_183 = {
    { title = "Guild & Rules", body = "Read the guild MOTD, full information, rank structure and contacts.", page = "guildinfo", icon = "Interface\\Icons\\INV_Scroll_03" },
    { title = "Discord", body = "Find the official link in Guild Info for announcements, communication and raids.", page = "guildinfo", icon = "Interface\\Icons\\INV_Letter_15" },
    { title = "Roster & Profiles", body = "Select a guild member to keep management tools visible and open their Guild Profile.", page = "roster", icon = "Interface\\Icons\\INV_Misc_Book_09" },
    { title = "Professions", body = "Search known recipes and crafters. Opening a profile does not start a new profession update.", page = "professions", icon = "Interface\\Icons\\Trade_BlackSmithing" },
    { title = "PvE & Groups", body = "Use PvE Hub for guild groups, raid planning and coordination.", page = "pve", icon = "Interface\\Icons\\INV_Helmet_06" },
    { title = "Achievements", body = "Browse guild achievements, track up to three goals and view the honest shared-data ranking.", page = "achievements", icon = "Interface\\Icons\\INV_Misc_Note_06" },
}

local function Short183(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or 60
    if string.len(value) <= maximum then return value end
    return string.sub(value, 1, math.max(1, maximum - 3)) .. "..."
end

local function CountMap183(map)
    local count, key = 0, nil
    for key in pairs(map or {}) do count = count + 1 end
    return count
end

local function EmptyVisitCounts183()
    return { members = 0, ranks = 0, announcements = 0, achievements = 0, raids = 0 }
end

local function CopyVisitCounts183(source)
    local result = EmptyVisitCounts183()
    local index, key
    for index = 1, table.getn(VISIT_KINDS_183) do
        key = VISIT_KINDS_183[index].key
        result[key] = math.max(0, math.floor(tonumber(source and source[key]) or 0))
    end
    return result
end

local function TotalVisitCounts183(counts)
    local total, index = 0, 1
    for index = 1, table.getn(VISIT_KINDS_183) do total = total + (tonumber(counts and counts[VISIT_KINDS_183[index].key]) or 0) end
    return total
end

function OTLGM:EnsureSinceVisitState183()
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    if not db then return nil end
    if type(db.sinceVisit183) ~= "table" then db.sinceVisit183 = {} end
    local state = db.sinceVisit183
    state.startedAt = tonumber(state.startedAt) or self:Now()
    state.lastVisitAt = tonumber(state.lastVisitAt) or state.startedAt
    state.pending = CopyVisitCounts183(state.pending)
    if type(state.keys) ~= "table" then state.keys = {} end
    local key, timestamp
    for key, timestamp in pairs(state.keys) do
        if type(key) ~= "string" or string.len(key) > 140 or not tonumber(timestamp) then state.keys[key] = nil end
    end
    if CountMap183(state.keys) > MAX_VISIT_KEYS_183 then
        local entries = {}
        for key, timestamp in pairs(state.keys) do table.insert(entries, { key = key, ts = tonumber(timestamp) or 0 }) end
        table.sort(entries, function(left, right)
            if left.ts ~= right.ts then return left.ts > right.ts end
            return tostring(left.key) < tostring(right.key)
        end)
        local index
        for index = MAX_VISIT_KEYS_183 + 1, table.getn(entries) do state.keys[entries[index].key] = nil end
    end
    return state
end

function OTLGM:RecordSinceVisitEvent183(kind, eventKey)
    local allowed, index = false, 1
    for index = 1, table.getn(VISIT_KINDS_183) do if VISIT_KINDS_183[index].key == kind then allowed = true break end end
    if not allowed then return false end
    local state = self:EnsureSinceVisitState183()
    if not state then return false end
    eventKey = self.SafeText and self:SafeText(tostring(eventKey or ""), 120, false, false) or string.sub(tostring(eventKey or ""), 1, 120)
    if eventKey == "" then eventKey = kind .. ":" .. tostring(self:Now()) end
    local dedupe = tostring(kind) .. ":" .. eventKey
    if state.keys[dedupe] then return false end
    state.keys[dedupe] = self:Now()
    state.pending[kind] = math.min(9999, (tonumber(state.pending[kind]) or 0) + 1)
    if CountMap183(state.keys) > MAX_VISIT_KEYS_183 then
        local oldestKey, oldestTime, key, timestamp
        for key, timestamp in pairs(state.keys) do
            timestamp = tonumber(timestamp) or 0
            if not oldestTime or timestamp < oldestTime or (timestamp == oldestTime and tostring(key) < tostring(oldestKey)) then
                oldestKey, oldestTime = key, timestamp
            end
        end
        if oldestKey then state.keys[oldestKey] = nil end
    end
    self.runtime = self.runtime or {}
    self.runtime.sinceVisitRecorded183 = (tonumber(self.runtime.sinceVisitRecorded183) or 0) + 1
    return true
end

function OTLGM:CaptureSinceVisit183()
    self.runtime = self.runtime or {}
    if self.runtime.sinceVisitSnapshot183 then return self.runtime.sinceVisitSnapshot183 end
    local state = self:EnsureSinceVisitState183()
    if not state then return { counts = EmptyVisitCounts183(), total = 0, from = self:Now(), trackingStarted = true } end
    local counts = CopyVisitCounts183(state.pending)
    local snapshot = {
        counts = counts,
        total = TotalVisitCounts183(counts),
        from = tonumber(state.lastVisitAt) or tonumber(state.startedAt) or self:Now(),
        capturedAt = self:Now(),
        trackingStarted = (tonumber(state.lastVisitAt) or 0) == (tonumber(state.startedAt) or 0) and TotalVisitCounts183(counts) == 0,
    }
    self.runtime.sinceVisitSnapshot183 = snapshot
    state.pending = EmptyVisitCounts183()
    state.keys = {}
    state.lastVisitAt = snapshot.capturedAt
    return snapshot
end

function OTLGM:GetSinceVisitLines183(snapshot)
    snapshot = snapshot or self:CaptureSinceVisit183()
    local lines = {}
    local index, definition, count
    for index = 1, table.getn(VISIT_KINDS_183) do
        definition = VISIT_KINDS_183[index]
        count = tonumber(snapshot.counts and snapshot.counts[definition.key]) or 0
        if count > 0 then
            table.insert(lines, tostring(count) .. " " .. (count == 1 and definition.singular or definition.plural))
        end
    end
    if table.getn(lines) == 0 then
        table.insert(lines, snapshot.trackingStarted and "Tracking starts with this version; older activity is not reconstructed."
            or "No new tracked guild changes since the previous Home visit.")
    end
    return lines
end

local PreviousAddLog183 = OTLGM.AddLog
if PreviousAddLog183 then
    function OTLGM:AddLog(db, kind, name, detail, actor, source, meta)
        local eventInfo = PreviousAddLog183(self, db, kind, name, detail, actor, source, meta)
        if eventInfo and kind == "JOIN" then
            self:RecordSinceVisitEvent183("members", "roster:" .. tostring(name or "") .. ":" .. tostring(eventInfo.ts or self:Now()))
        elseif eventInfo and kind == "RANK" then
            self:RecordSinceVisitEvent183("ranks", "roster:" .. tostring(name or "") .. ":" .. tostring(eventInfo.ts or self:Now()))
        end
        return eventInfo
    end
end

local PreviousNotifyEvent183 = OTLGM.NotifyEvent152
if PreviousNotifyEvent183 then
    function OTLGM:NotifyEvent152(category, eventKey, title, body, priority, remote, targetPage, route)
        local changed = PreviousNotifyEvent183(self, category, eventKey, title, body, priority, remote, targetPage, route)
        if changed and category == "announcement" then self:RecordSinceVisitEvent183("announcements", eventKey)
        elseif changed and category == "raid" then self:RecordSinceVisitEvent183("raids", eventKey) end
        return changed
    end
end

local PreviousCompleteAchievement183 = OTLGM.CompleteAchievement174
if PreviousCompleteAchievement183 then
    function OTLGM:CompleteAchievement174(id, silent)
        local changed = PreviousCompleteAchievement183(self, id, silent)
        if changed then self:RecordSinceVisitEvent183("achievements", tostring(id or "") .. ":" .. tostring(self:Now())) end
        return changed
    end
end

function OTLGM:BuildWelcome183()
    self.ui = self.ui or {}
    if self.ui.welcome183 then return self.ui.welcome183 end
    if not self.ui.modalHost then return nil end
    local modal = UI:Modal(self.ui.modalHost, 700, 544)
    modal:SetPoint("CENTER", self.ui.modalHost, "CENTER", 0, 0)
    modal.otlDiagnosticName180 = "Welcome Start Here"
    modal.title = UI.Text(modal, "Welcome to Order of the Lion", "GameFontNormalLarge", "LEFT")
    modal.title:SetPoint("TOPLEFT", modal, "TOPLEFT", 22, -20) modal.title:SetWidth(560)
    modal.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    modal.subtitle = UI.Text(modal, "Start here — six useful places, no long tutorial.", "GameFontNormalSmall", "LEFT")
    modal.subtitle:SetPoint("TOPLEFT", modal, "TOPLEFT", 22, -50) modal.subtitle:SetWidth(640)
    modal.subtitle:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.close = UI:IconButton(modal, "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 28, 28, function()
        OTLGM:CloseModal180(modal, "welcome-close")
    end, "Close", "utility")
    modal.close:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -14, -13)
    modal.rows = {}
    local index
    for index = 1, table.getn(WELCOME_ITEMS_183) do
        local definition = WELCOME_ITEMS_183[index]
        local row = UI:Card(modal, 656, 62)
        row:SetPoint("TOPLEFT", modal, "TOPLEFT", 22, -78 - ((index - 1) * 66))
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetTexture(definition.icon) row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.icon:SetWidth(34) row.icon:SetHeight(34) row.icon:SetPoint("LEFT", row, "LEFT", 12, 0)
        row.title = UI.Text(row, definition.title, "GameFontNormal", "LEFT")
        row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 58, -10) row.title:SetWidth(180)
        row.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
        row.body = UI.Text(row, definition.body, "GameFontNormalSmall", "LEFT")
        row.body:SetPoint("TOPLEFT", row, "TOPLEFT", 58, -31) row.body:SetWidth(480) row.body:SetHeight(27) row.body:SetJustifyV("TOP")
        row.body:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        row.open = UI:Button(row, "Open", 76, 26, function()
            OTLGM:CloseModal180(modal, "welcome-navigation")
            OTLGM:ShowPage(definition.page)
        end, "utility")
        row.open:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        modal.rows[index] = row
    end
    modal.dontShow = UI:Check(modal, "Don't show automatically again", 280, function(value)
        if OTLGM_DB and OTLGM_DB.settings then OTLGM_DB.settings.welcomeDismissed183 = value and true or false end
    end)
    modal.dontShow:SetPoint("BOTTOMLEFT", modal, "BOTTOMLEFT", 22, 18)
    modal.explore = UI:Button(modal, "Explore Addon", 132, 32, function()
        OTLGM:CloseModal180(modal, "welcome-explore")
        OTLGM:ShowPage("guildinfo")
    end, "primary")
    modal.explore:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -22, 16)
    self.ui.welcome183 = modal
    return modal
end

function OTLGM:OpenWelcome183(automatic)
    if automatic and OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.welcomeDismissed183 then return false end
    if not self.ui or not self.ui.main then self:BuildUI() end
    if not self.ui or not self.ui.main then return false end
    local modal = self:BuildWelcome183()
    if not modal then return false end
    UI:SetChecked(modal.dontShow, OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.welcomeDismissed183 and true or false)
    self.runtime = self.runtime or {}
    self.runtime.welcomeShown183 = true
    self.runtime.welcomeAutomatic183 = automatic and true or nil
    return self:ShowShellModal(modal)
end

function OTLGM:BuildSinceVisitDrawer183()
    self.ui = self.ui or {}
    if self.ui.sinceVisitDrawer183 then return self.ui.sinceVisitDrawer183 end
    if not self.ui.drawerHost then return nil end
    local drawer = UI:Drawer(self.ui.drawerHost, 420, 360)
    drawer:SetPoint("TOPRIGHT", self.ui.drawerHost, "TOPRIGHT", -10, -10)
    drawer.title = UI.Text(drawer, "Since Your Last Visit", "GameFontNormalLarge", "LEFT")
    drawer.title:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -18) drawer.title:SetWidth(310)
    drawer.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    drawer.close = UI:IconButton(drawer, "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 28, 28, function() OTLGM:CloseShellDrawer() end, "Close", "utility")
    drawer.close:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -12, -12)
    drawer.period = UI.Text(drawer, "", "GameFontNormalSmall", "LEFT")
    drawer.period:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -54) drawer.period:SetWidth(380)
    drawer.period:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    drawer.rows = {}
    local index
    for index = 1, 5 do
        local row = UI:Card(drawer, 384, 42)
        row:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -86 - ((index - 1) * 47))
        row.marker = row:CreateTexture(nil, "ARTWORK")
        row.marker:SetTexture(C.gold[1], C.gold[2], C.gold[3], 1)
        row.marker:SetWidth(4) row.marker:SetHeight(24) row.marker:SetPoint("LEFT", row, "LEFT", 8, 0)
        row.text = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.text:SetPoint("LEFT", row, "LEFT", 22, 0) row.text:SetWidth(348)
        row:Hide() drawer.rows[index] = row
    end
    drawer.note = UI.Text(drawer, "Counters are updated by existing events; Home never scans the full History for this summary.", "GameFontNormalSmall", "LEFT")
    drawer.note:SetPoint("BOTTOMLEFT", drawer, "BOTTOMLEFT", 18, 15) drawer.note:SetWidth(384) drawer.note:SetHeight(32)
    drawer.note:SetJustifyV("BOTTOM") drawer.note:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    drawer.otlUsesSharedDrawerHost = true
    self.ui.sinceVisitDrawer183 = drawer
    return drawer
end

function OTLGM:RefreshSinceVisitUI183()
    local snapshot = self:CaptureSinceVisit183()
    local button = self.ui and self.ui.homeSinceVisit183
    if button then
        UI:SetText(button, snapshot.total > 0 and ("Since Visit  •  " .. tostring(snapshot.total)) or "Since Last Visit")
        UI:SetSelected(button, snapshot.total > 0)
    end
    local drawer = self.ui and self.ui.sinceVisitDrawer183
    if not drawer then return true end
    local lines = self:GetSinceVisitLines183(snapshot)
    local fromText = date and date("%d %b %Y %H:%M", snapshot.from or self:Now()) or tostring(snapshot.from or "")
    drawer.period:SetText("Tracked since " .. tostring(fromText) .. "  •  " .. tostring(snapshot.total or 0) .. " update(s)")
    local index
    for index = 1, table.getn(drawer.rows) do
        if lines[index] then drawer.rows[index].text:SetText(Short183(lines[index], 76)) drawer.rows[index]:Show()
        else drawer.rows[index]:Hide() end
    end
    return true
end

function OTLGM:OpenSinceVisitDrawer183()
    local drawer = self:BuildSinceVisitDrawer183()
    if not drawer then return false end
    self:RefreshSinceVisitUI183()
    return self:ShowShellDrawer(drawer)
end

function OTLGM:AttachHomeCommunityControls183(page)
    if not page or page.otlCommunityControls183 then return end
    page.otlCommunityControls183 = true
    self.ui.homeSinceVisit183 = UI:Button(page, "Since Last Visit", 154, 28, function() OTLGM:OpenSinceVisitDrawer183() end, "secondary")
    self.ui.homeSinceVisit183.otlTooltipTitle = "Since Your Last Visit"
    self.ui.homeSinceVisit183.otlTooltip = "A bounded event-counter summary. It does not read or rebuild full History."
end

function OTLGM:LayoutHomeCommunityControls183()
    local button = self.ui and self.ui.homeSinceVisit183
    local page = self.ui and self.ui.pages and self.ui.pages.home
    if not button or not page then return end
    -- Home has two toolbar rows: primary navigation on top, optional utilities
    -- beneath it.  Keeping these controls off the primary row prevents Fit and
    -- narrow windows from stacking Report / Help over Guild Posts / My Profile.
    button:ClearAllPoints()
    local report = self.ui and self.ui.homeModeration183
    if report then button:SetPoint("LEFT", report, "RIGHT", 8, 0)
    else button:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -40) end
    button:SetWidth(154) button:SetHeight(28)
end

function OTLGM:AttachGuildInfoWelcome183(page)
    if not page or page.otlWelcomeButton183 then return end
    local parent = self.ui and self.ui.guildInfoChild or page
    page.otlWelcomeButton183 = UI:Button(parent, "Start Here", 104, 26, function() OTLGM:OpenWelcome183(false) end, "utility")
    page.otlWelcomeButton183.otlTooltip = "Open the short addon guide."
end

function OTLGM:LayoutGuildInfoWelcome183(page)
    local button = page and page.otlWelcomeButton183
    local child = self.ui and self.ui.guildInfoChild
    if not button or not child then return end
    button:ClearAllPoints() button:SetPoint("TOPRIGHT", child, "TOPRIGHT", -18, -18)
    if button.SetFrameLevel and child.GetFrameLevel then button:SetFrameLevel(child:GetFrameLevel() + 8) end
end

function OTLGM:AttachSettingsWelcome183()
    local about = self.ui and self.ui.settingsAboutCard
    if not about or about.welcome183 then return end
    about.welcome183 = UI:Button(about, "Open Welcome", 132, 30, function() OTLGM:OpenWelcome183(false) end, "utility")
    about.welcome183:SetPoint("LEFT", about.diagnostics, "RIGHT", 8, 0)
end

local function WrapPageModule183(key, attach, layout, refresh, onShow)
    local module = OTLGM.shellPageModules and OTLGM.shellPageModules[key]
    if not module or module.otlCommunityWrapped183 then return end
    module.otlCommunityWrapped183 = true
    local PreviousBuild, PreviousLayout, PreviousRefresh, PreviousOnShow = module.Build, module.Layout, module.Refresh, module.OnShow
    function module:Build(contentHost)
        local root = PreviousBuild(self, contentHost)
        if attach then attach(self.owner, root) end
        return root
    end
    function module:Layout(width, height)
        PreviousLayout(self, width, height)
        if layout then layout(self.owner, self.root, width, height) end
    end
    function module:Refresh(reason)
        PreviousRefresh(self, reason)
        if refresh then refresh(self.owner, self.root, reason) end
    end
    function module:OnShow(context)
        PreviousOnShow(self, context)
        if onShow then onShow(self.owner, self.root, context) end
    end
end

WrapPageModule183("home",
    function(owner, page) owner:AttachHomeCommunityControls183(page) end,
    function(owner) owner:LayoutHomeCommunityControls183() end,
    function(owner) owner:RefreshSinceVisitUI183() end,
    function(owner)
        owner:CaptureSinceVisit183()
        owner.runtime = owner.runtime or {}
        if not owner.runtime.welcomeAttempted183 then
            owner.runtime.welcomeAttempted183 = true
            owner:OpenWelcome183(true)
        end
    end)

WrapPageModule183("guildinfo",
    function(owner, page) owner:AttachGuildInfoWelcome183(page) end,
    function(owner, page) owner:LayoutGuildInfoWelcome183(page) end)

WrapPageModule183("settings",
    function(owner) owner:AttachSettingsWelcome183() end,
    function(owner) owner:AttachSettingsWelcome183() end)

local PreviousDiagnostics183 = OTLGM.GetDiagnosticsText
if PreviousDiagnostics183 then
    function OTLGM:GetDiagnosticsText()
        local text = tostring(PreviousDiagnostics183(self) or "")
        local state = self:EnsureSinceVisitState183()
        local pending = state and TotalVisitCounts183(state.pending) or 0
        return text .. "\nCommunity UX: welcome "
            .. tostring(OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.welcomeDismissed183 and "dismissed" or "available")
            .. " / since-visit pending " .. tostring(pending)
            .. " / snapshot " .. tostring(self.runtime and self.runtime.sinceVisitSnapshot183 and "captured" or "not-captured")
            .. " / history scans 0 / content excluded"
    end
end

OTLGM:RegisterModule("CommunityExperience183", {
    stage = "F",
    revision = 1,
    welcomeItems = table.getn(WELCOME_ITEMS_183),
    sinceVisitKinds = table.getn(VISIT_KINDS_183),
    sinceVisitKeyLimit = MAX_VISIT_KEYS_183,
    startsAtInstall = true,
    staticWelcome = true,
    noOnUpdate = true,
    noPolling = true,
    noHistoryScan = true,
    noRosterRequest = true,
    noNetworkRequest = true,
})
