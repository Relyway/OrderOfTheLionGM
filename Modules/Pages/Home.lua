-- Order of the Lion Guild Manager 1.8.0 alpha2 shell r6
-- Fully migrated Home page: Overview and Guild Posts.

if not OTLGM or not OTLGM.UI then return end

local UI = OTLGM.UI
local C = UI.colors

local function Label(parent, value, template, x, y, width, justify)
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

local function WordSafePreview(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or 120
    if string.len(value) <= maximum then return value end
    local clipped = string.sub(value, 1, math.max(1, maximum - 3))
    local lastSpace
    local index
    for index = string.len(clipped), math.max(1, string.len(clipped) - 28), -1 do
        if string.sub(clipped, index, index) == " " then lastSpace = index break end
    end
    if lastSpace and lastSpace > math.floor(maximum * 0.55) then clipped = string.sub(clipped, 1, lastSpace - 1) end
    return clipped .. "..."
end

local function EstimateWrappedHeight180(value, width)
    value = tostring(value or "")
    width = math.max(120, tonumber(width) or 420)
    -- Strip non-visible colour wrappers for a conservative line estimate.
    local visible = string.gsub(value, "|c%x%x%x%x%x%x%x%x", "")
    visible = string.gsub(visible, "|r", "")
    local charsPerLine = math.max(12, math.floor(width / 6.8))
    local lines = 0
    local startAt = 1
    while true do
        local newline = string.find(visible, "\n", startAt, true)
        local paragraph = newline and string.sub(visible, startAt, newline - 1) or string.sub(visible, startAt)
        lines = lines + math.max(1, math.ceil(string.len(paragraph) / charsPerLine))
        if not newline then break end
        startAt = newline + 1
    end
    return math.max(32, (lines * 16) + 16)
end

local function MeasurePostBodyHeight180(details, value)
    local width = math.max(120, details.body:GetWidth() or 420)
    local estimate = EstimateWrappedHeight180(value, width)
    local measure = details.bodyMeasure180
    local measured = 0
    if measure then
        measure:SetWidth(width)
        measure:SetText(tostring(value or ""))
        if measure.GetStringHeight then measured = tonumber(measure:GetStringHeight()) or 0 end
    end
    return math.max(estimate, measured + 12)
end

local function MakeEdit(parent, width, height, multiline, maximum)
    return UI:EditBox(parent, width, height, {
        multiline = multiline and true or false,
        maxLetters = maximum or 80,
        fontObject = multiline and "ChatFontNormal" or "GameFontHighlightSmall",
    })
end

local HOME_POST_AUDIENCES180 = {
    { key = "SILENT", label = "Silent" },
    { key = "ALL_MEMBERS", label = "All Members" },
    { key = "LEADERSHIP", label = "Leadership" },
    { key = "RAID_TEAM", label = "Raid Team" },
}

local function RefreshHomePostAudience180(owner, modal)
    local label = "Silent"
    local index
    for index = 1, table.getn(HOME_POST_AUDIENCES180) do
        if HOME_POST_AUDIENCES180[index].key == modal.notifyAudience180 then label = HOME_POST_AUDIENCES180[index].label break end
    end
    UI:SetText(modal.notifyButton, "Notify: " .. label)
    UI:SetSelected(modal.notifyButton, modal.notifyAudience180 ~= "SILENT")
    if modal.notifyAudience180 == "RAID_TEAM" then
        local team = modal.notifyTeamId180 and owner.GetRaidTeam180 and owner:GetRaidTeam180(modal.notifyTeamId180) or nil
        UI:SetText(modal.teamButton, team and ("Team: " .. Short(team.name or "Raid Team", 26)) or "Select Raid Team")
        modal.teamButton:Show()
    else
        modal.teamButton:Hide()
    end
end

local function CycleHomePostAudience180(owner, modal)
    local currentIndex = 1
    local index
    for index = 1, table.getn(HOME_POST_AUDIENCES180) do if HOME_POST_AUDIENCES180[index].key == modal.notifyAudience180 then currentIndex = index break end end
    currentIndex = math.mod(currentIndex, table.getn(HOME_POST_AUDIENCES180)) + 1
    modal.notifyAudience180 = HOME_POST_AUDIENCES180[currentIndex].key
    if modal.notifyAudience180 == "RAID_TEAM" and not modal.notifyTeamId180 then
        local teams = owner.GetRaidTeamList180 and owner:GetRaidTeamList180(false) or {}
        modal.notifyTeamId180 = teams[1] and teams[1].id or nil
    end
    RefreshHomePostAudience180(owner, modal)
end

local function CycleHomePostTeam180(owner, modal)
    local teams = owner.GetRaidTeamList180 and owner:GetRaidTeamList180(false) or {}
    if table.getn(teams) == 0 then modal.notifyTeamId180 = nil RefreshHomePostAudience180(owner, modal) return end
    local selected = 0
    local index
    for index = 1, table.getn(teams) do if teams[index].id == modal.notifyTeamId180 then selected = index break end end
    selected = math.mod(selected, table.getn(teams)) + 1
    modal.notifyTeamId180 = teams[selected].id
    RefreshHomePostAudience180(owner, modal)
end

local function BuildHomePostEditor(owner)
    if owner.ui.homePostEditor then return end
    local modal = UI:Modal(owner.ui.modalHost, 700, 560)
    modal:SetPoint("CENTER", owner.ui.modalHost, "CENTER", 0, 0)
    modal.title = Label(modal, "New Guild Post", "GameFontNormalLarge", 20, -18, 580, "LEFT")
    modal.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    Label(modal, "TITLE", "GameFontNormalSmall", 20, -58, 160, "LEFT"):SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    modal.titleEdit = MakeEdit(modal, 660, 34, false, 80)
    modal.titleEdit:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -78)
    Label(modal, "MESSAGE", "GameFontNormalSmall", 20, -126, 160, "LEFT"):SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    modal.bodyEdit = MakeEdit(modal, 660, 230, true, 900)
    modal.bodyEdit:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -146)

    modal.importance = "NORMAL"
    modal.importanceButtons = {}
    local definitions = {
        { key = "NORMAL", label = "Normal" },
        { key = "IMPORTANT", label = "Important" },
        { key = "CRITICAL", label = "Urgent" },
    }
    local index
    for index = 1, table.getn(definitions) do
        local captured = index
        local definition = definitions[captured]
        local button = UI:FilterChip(modal, definition.label, 100, function()
            modal.importance = definition.key
            local refreshIndex
            for refreshIndex = 1, table.getn(definitions) do
                UI:SetSelected(modal.importanceButtons[refreshIndex], definitions[refreshIndex].key == modal.importance)
            end
        end)
        button:SetPoint("TOPLEFT", modal, "TOPLEFT", 20 + ((captured - 1) * 108), -394)
        modal.importanceButtons[captured] = button
    end
    modal.notifyAudience180 = "SILENT"
    modal.notifyTeamId180 = nil
    modal.notifyButton = UI:FilterChip(modal, "Notify: Silent", 166, function()
        CycleHomePostAudience180(owner, modal)
    end)
    modal.notifyButton:SetPoint("TOPLEFT", modal, "TOPLEFT", 340, -394)
    modal.teamButton = UI:Button(modal, "Select Raid Team", 300, 24, function()
        CycleHomePostTeam180(owner, modal)
    end, "utility")
    modal.teamButton:SetPoint("TOPLEFT", modal, "TOPLEFT", 340, -426)
    modal.teamButton:Hide()
    modal.pinButton = UI:FilterChip(modal, "Pin on Home", 128, function(button)
        button.otlValue = not button.otlValue
        UI:SetSelected(button, button.otlValue)
    end)
    modal.pinButton:SetPoint("TOPLEFT", modal, "TOPLEFT", 514, -394)
    modal.validation = Label(modal, "", "GameFontNormalSmall", 20, -470, 620, "LEFT")
    modal.validation:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.cancel = UI:Button(modal, "Cancel", 100, 30, function() owner:CloseShellModal() end, "secondary")
    modal.cancel:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -138, 18)
    modal.publish = UI:Button(modal, "Publish", 112, 30, function()
        local title = modal.titleEdit:GetText() or ""
        local body = modal.bodyEdit:GetText() or ""
        local notifyFlag = modal.notifyAudience180 ~= "SILENT"
        local ok, result = owner:PublishAnnouncement152(title, body, modal.importance, notifyFlag, modal.pinButton.otlValue, modal.editId, modal.notifyAudience180, modal.notifyTeamId180)
        if not ok then
            modal.validation:SetText(tostring(result or "The post could not be saved."))
            modal.validation:SetTextColor(C.red[1], C.red[2], C.red[3])
            return
        end
        owner.ui.homeSelectedPostId = result and result.id or modal.editId
        owner:CloseShellModal()
        owner:ShowToast(modal.editId and "Guild post updated." or "Guild post published.", "success")
        owner:RefreshHomePage()
    end, "primary")
    modal.publish:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -18, 18)
    owner.ui.homePostEditor = modal
end

function OTLGM:OpenHomePostEditor(recordId)
    if not self.CanPublishAnnouncement152 or not self:CanPublishAnnouncement152() then
        self:ShowNotice("Guild Posts", "Only guild leadership can publish or edit official guild posts.")
        return
    end
    BuildHomePostEditor(self)
    local modal = self.ui.homePostEditor
    local record = recordId and self:GetAnnouncement152(recordId) or nil
    modal.editId = record and record.id or nil
    modal.title:SetText(record and "Edit Guild Post" or "New Guild Post")
    modal.titleEdit:SetText(record and record.title or "")
    modal.bodyEdit:SetText(record and record.body or "")
    modal.importance = record and record.importance or "NORMAL"
    modal.notifyAudience180 = record and record.notifyAudience180 or (record and record.notifyFlag and "ALL_MEMBERS" or "SILENT")
    modal.notifyTeamId180 = record and record.notifyTeamId180 or nil
    modal.pinButton.otlValue = record and record.pinned and true or false
    RefreshHomePostAudience180(self, modal)
    UI:SetSelected(modal.pinButton, modal.pinButton.otlValue)
    local definitions = { "NORMAL", "IMPORTANT", "CRITICAL" }
    local index
    for index = 1, table.getn(definitions) do UI:SetSelected(modal.importanceButtons[index], definitions[index] == modal.importance) end
    modal.validation:SetText("A title and message are required.")
    modal.validation:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    UI:SetText(modal.publish, record and "Save Changes" or "Publish")
    self:ShowShellModal(modal)
    modal.titleEdit:SetFocus()
end

function OTLGM:ShowHomePostReaders(recordId)
    self:ShowHomePostPeople180(recordId, "READ")
end

function OTLGM:BuildHomePostPeople180()
    if self.ui.homePostPeople180 then return end
    local modal = UI:Modal(self.ui.modalHost, 430, 430)
    modal:SetPoint("CENTER", self.ui.modalHost, "CENTER", 0, 0)
    modal.title = Label(modal, "Reactions & Readers", "GameFontNormalLarge", 18, -18, 330, "LEFT")
    modal.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    modal.close = UI:IconButton(modal, "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 28, 28, function()
        OTLGM:CloseShellModal()
    end, "Close", "utility")
    modal.close:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -12, -12)
    modal.tabs = {}
    local definitions = { { "LIKE", "Like" }, { "SEEN", "Seen" }, { "SUPPORT", "Support" }, { "READ", "Read by" } }
    local index
    for index = 1, table.getn(definitions) do
        local captured = index
        local definition = definitions[captured]
        local button = UI:Tab(modal, definition[2], 92, function()
            modal.mode = definition[1]
            modal.offset = 0
            OTLGM:RefreshHomePostPeople180()
        end)
        button:SetPoint("TOPLEFT", modal, "TOPLEFT", 18 + ((captured - 1) * 98), -58)
        modal.tabs[captured] = button
    end
    modal.rows = {}
    for index = 1, 12 do
        local row = UI:TableRow(modal, 374, 24, function() end)
        row:SetPoint("TOPLEFT", modal, "TOPLEFT", 18, -96 - ((index - 1) * 25))
        row.nameText = Label(row, "", "GameFontNormalSmall", 8, -6, 354, "LEFT")
        row:Hide()
        modal.rows[index] = row
    end
    modal.scrollbar = UI:Scrollbar(modal, 300, function(value)
        modal.offset = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
        OTLGM:RefreshHomePostPeople180()
    end)
    modal.scrollbar:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -10, -96)
    modal.empty = Label(modal, "No names are stored for this tab.", "GameFontNormalSmall", 18, -128, 374, "CENTER")
    modal.empty:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.empty:Hide()
    modal.mode = "READ"
    modal.offset = 0
    self.ui.homePostPeople180 = modal
end

function OTLGM:RefreshHomePostPeople180()
    local modal = self.ui and self.ui.homePostPeople180
    if not modal or not modal.recordId then return end
    local mode = modal.mode or "READ"
    local names
    if mode == "READ" then
        names = self.GetAnnouncementReaders172 and self:GetAnnouncementReaders172(modal.recordId) or {}
    else
        names = self.GetCommunityReactors and self:GetCommunityReactors("ANN", modal.recordId, mode) or {}
    end
    table.sort(names, function(a, b) return string.lower(tostring(a)) < string.lower(tostring(b)) end)
    local maximum = math.max(0, table.getn(names) - table.getn(modal.rows))
    modal.offset = math.max(0, math.min(maximum, tonumber(modal.offset) or 0))
    local index
    for index = 1, table.getn(modal.tabs) do
        UI:SetSelected(modal.tabs[index], ({ "LIKE", "SEEN", "SUPPORT", "READ" })[index] == mode)
    end
    for index = 1, table.getn(modal.rows) do
        local name = names[modal.offset + index]
        if name then modal.rows[index].nameText:SetText(tostring(name)) modal.rows[index]:Show()
        else modal.rows[index]:Hide() end
    end
    modal.empty:SetText(mode == "READ" and "No one has opened this revision yet." or "No reactions are stored for this tab.")
    if table.getn(names) == 0 then modal.empty:Show() else modal.empty:Hide() end
    modal.scrollbar.otlSilent = true
    modal.scrollbar:SetMinMaxValues(0, maximum)
    modal.scrollbar:SetValue(modal.offset)
    modal.scrollbar.otlSilent = nil
    if maximum > 0 then modal.scrollbar:Show() else modal.scrollbar:Hide() end
end

function OTLGM:ShowHomePostPeople180(recordId, mode)
    if not recordId then return end
    self:BuildHomePostPeople180()
    local modal = self.ui.homePostPeople180
    modal.recordId = recordId
    modal.mode = mode == "LIKE" and "LIKE" or mode == "SEEN" and "SEEN" or mode == "SUPPORT" and "SUPPORT" or "READ"
    modal.offset = 0
    self:RefreshHomePostPeople180()
    self:ShowShellModal(modal)
end

function OTLGM:SelectHomePost(recordId)
    local record = recordId and self:GetAnnouncement152(recordId) or nil
    self.ui.homeSelectedPostId = record and record.id or nil
    if record then
        if self.MarkAnnouncementRead154 then self:MarkAnnouncementRead154(record.id) end
        if self.RecordAnnouncementReadReceipt172 then self:RecordAnnouncementReadReceipt172(record.id) end
    end
    self:RefreshHomePage()
end

function OTLGM:SetHomeTab(tab)
    tab = tab == "POSTS" and "POSTS" or "OVERVIEW"
    self.ui.homeShellTab = tab
    OTLGM_DB.settings.homeShellTab = tab
    if self.ui.homeOverviewPanel then
        if tab == "OVERVIEW" then self.ui.homeOverviewPanel:Show() else self.ui.homeOverviewPanel:Hide() end
        if tab == "POSTS" then self.ui.homePostsPanel:Show() else self.ui.homePostsPanel:Hide() end
        UI:SetSelected(self.ui.homeOverviewTab, tab == "OVERVIEW")
        UI:SetSelected(self.ui.homePostsTab, tab == "POSTS")
    end
    self:RefreshHomePage()
end

local HOME_ROLE_ICONS = {
    ["Guild Leader"] = "Interface\\Icons\\INV_Crown_01",
    ["Raid Leader"] = "Interface\\Icons\\Ability_Warrior_BattleShout",
    ["Officer"] = "Interface\\Icons\\INV_Shield_06",
    ["Helper"] = "Interface\\Icons\\INV_Misc_Bandage_12",
}

local function HomeLeadershipRole(member)
    local rank = string.lower(tostring(member and member.rank or ""))
    local rankIndex = tonumber(member and member.rankIndex) or 99
    if OTLGM.IsCanonicalGuildLeaderName180 and OTLGM:IsCanonicalGuildLeaderName180(member and member.name) then return "Guild Leader", 1 end
    if string.find(rank, "raid leader", 1, true) or string.find(rank, "raidlead", 1, true) then return "Raid Leader", 2 end
    if string.find(rank, "officer", 1, true) or string.find(rank, "lionheart", 1, true) or rankIndex <= 2 then return "Officer", 3 end
    return "Helper", 4
end

local function CollectHomeLeadership180(owner)
    local leaders = owner.GetLeadershipOnline and owner:GetLeadershipOnline() or {}
    table.sort(leaders, function(a, b)
        local _, ao = HomeLeadershipRole(a)
        local _, bo = HomeLeadershipRole(b)
        if ao ~= bo then return ao < bo end
        return string.lower(tostring(a and a.name or "")) < string.lower(tostring(b and b.name or ""))
    end)
    local result = { all = leaders, guildLeader = nil, mainRaidLeader = nil, regular = {} }
    local index
    for index = 1, table.getn(leaders) do
        local role = HomeLeadershipRole(leaders[index])
        local shortName = string.lower(tostring(leaders[index].name or ""))
        local dash = string.find(shortName, "-", 1, true)
        if dash then shortName = string.sub(shortName, 1, dash - 1) end
        if role == "Guild Leader" and not result.guildLeader then result.guildLeader = leaders[index]
        elseif shortName == "rangark" and not result.mainRaidLeader then result.mainRaidLeader = leaders[index]
        else table.insert(result.regular, leaders[index]) end
    end
    return result
end

local function BuildOverview(owner, page)
    local panel = CreateFrame("Frame", nil, page)
    panel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -40)
    panel:SetWidth(932)
    panel:SetHeight(548)
    owner.ui.homeOverviewPanel = panel

    local pinned = UI:Card(panel, 590, 220, "Official Guild Post")
    pinned:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    if pinned.SetBackdropColor then pinned:SetBackdropColor(0.055, 0.045, 0.025, 1) end
    if pinned.SetBackdropBorderColor then pinned:SetBackdropBorderColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3], 1) end
    pinned.importanceAccent180 = pinned:CreateTexture(nil, "ARTWORK")
    pinned.importanceAccent180:SetPoint("TOPLEFT", pinned, "TOPLEFT", 2, -2)
    pinned.importanceAccent180:SetPoint("BOTTOMLEFT", pinned, "BOTTOMLEFT", 2, 2)
    pinned.importanceAccent180:SetWidth(4)
    pinned.icon = pinned:CreateTexture(nil, "ARTWORK")
    pinned.icon:SetTexture("Interface\\Icons\\INV_Scroll_03")
    pinned.icon:SetWidth(30) pinned.icon:SetHeight(30)
    pinned.icon:SetPoint("TOPLEFT", pinned, "TOPLEFT", 14, -34)
    pinned.titleText = Label(pinned, "", "GameFontNormalLarge", 54, -32, 420, "LEFT")
    pinned.badgeText = Label(pinned, "", "GameFontNormalSmall", 430, -35, 140, "RIGHT")
    pinned.badgeText:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    pinned.metaText = Label(pinned, "", "GameFontNormalSmall", 54, -58, 500, "LEFT")
    pinned.metaText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    pinned.bodyText = Label(pinned, "", "GameFontHighlightSmall", 14, -88, 548, "LEFT")
    pinned.bodyText:SetHeight(78)
    pinned.bodyText:SetJustifyV("TOP")
    pinned.open = UI:Button(pinned, "Open Post", 94, 26, function()
        if pinned.otlRecordId then
            owner:SetHomeTab("POSTS")
            owner:SelectHomePost(pinned.otlRecordId)
        end
    end, "inline")
    pinned.open:SetPoint("BOTTOMRIGHT", pinned, "BOTTOMRIGHT", -12, 10)
    pinned.reactions = {}
    local reactionDefs = {
        { "LIKE", "Like" }, { "SEEN", "Seen" }, { "SUPPORT", "Support" }, { "READ", "Read" },
    }
    for index = 1, table.getn(reactionDefs) do
        local captured = index
        local mode = reactionDefs[captured][1]
        local button = UI:Button(pinned, reactionDefs[captured][2], mode == "SUPPORT" and 78 or 62, 23, function()
            if not pinned.otlRecordId then return end
            if mode == "READ" then owner:ShowHomePostPeople180(pinned.otlRecordId, "READ")
            else owner:ReactToAnnouncement152(pinned.otlRecordId, mode) owner:RefreshHomePage() end
        end, "inline")
        if captured == 1 then button:SetPoint("BOTTOMLEFT", pinned, "BOTTOMLEFT", 12, 10)
        else button:SetPoint("LEFT", pinned.reactions[captured - 1], "RIGHT", 5, 0) end
        pinned.reactions[captured] = button
    end
    owner.ui.homePinnedCard = pinned

    local recent = UI:Card(panel, 590, 210, "Latest Important Posts")
    recent:SetPoint("TOPLEFT", pinned, "BOTTOMLEFT", 0, -8)
    recent.rows = {}
    local index
    for index = 1, 2 do
        local captured = index
        local row = UI:TableRow(recent, 560, 64, function(button)
            if button.otlRecordId then
                owner:SetHomeTab("POSTS")
                owner:SelectHomePost(button.otlRecordId)
            end
        end)
        row:SetPoint("TOPLEFT", recent, "TOPLEFT", 14, -34 - ((captured - 1) * 68))
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetWidth(20) row.icon:SetHeight(20)
        row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -9)
        row.titleText = Label(row, "", "GameFontNormal", 36, -7, 390, "LEFT")
        row.titleText:SetHeight(22)
        row.badgeText = Label(row, "", "GameFontNormalSmall", 430, -8, 116, "RIGHT")
        row.badgeText:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
        row.metaText = Label(row, "", "GameFontNormalSmall", 36, -31, 510, "LEFT")
        row.metaText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        row.previewText = Label(row, "", "GameFontNormalSmall", 36, -47, 510, "LEFT")
        row.previewText:SetTextColor(0.78, 0.76, 0.70)
        row:Hide()
        recent.rows[captured] = row
    end
    recent.empty = Label(recent, "No additional important guild posts.", "GameFontNormalSmall", 14, -48, 540, "CENTER")
    recent.empty:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    recent.viewAll = UI:Button(recent, "View all posts", 112, 24, function() owner:SetHomeTab("POSTS") end, "inline")
    recent.viewAll:SetPoint("BOTTOMRIGHT", recent, "BOTTOMRIGHT", -10, 9)
    owner.ui.homeRecentPostsCard = recent

    local raid = UI:Card(panel, 332, 142, "Next Raid")
    raid:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    raid.titleText = Label(raid, "", "GameFontNormal", 12, -32, 302, "LEFT")
    raid.dateText = Label(raid, "", "GameFontNormalSmall", 12, -54, 302, "LEFT")
    raid.dateText:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    raid.leaderText = Label(raid, "", "GameFontNormalSmall", 12, -73, 302, "LEFT")
    raid.contactText = Label(raid, "", "GameFontNormalSmall", 12, -91, 302, "LEFT")
    raid.contactText:Hide()
    raid.gatherText = Label(raid, "", "GameFontNormalSmall", 12, -92, 302, "LEFT")
    raid.meetingText = Label(raid, "", "GameFontNormalSmall", 12, -110, 210, "LEFT")
    raid.meetingText:Hide()
    raid.countdownText = Label(raid, "", "GameFontNormalSmall", 12, -113, 190, "LEFT")
    raid.countdownText:SetTextColor(C.green[1], C.green[2], C.green[3])
    raid.open = UI:Button(raid, "View Raid", 92, 25, function()
        if raid.otlRaidId then owner:OpenNativeObject180({ type = "RAID", target = raid.otlRaidId, page = "pve" })
        else owner:ShowPage("pve") end
    end, "primary")
    raid.open:SetPoint("BOTTOMRIGHT", raid, "BOTTOMRIGHT", -10, 9)
    raid.empty = Label(raid, "No raid announced.", "GameFontNormalSmall", 12, -56, 300, "CENTER")
    raid.empty:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    owner.ui.homeRaidCard = raid

    local groups = UI:Card(panel, 332, 122, "Active Groups")
    groups:SetPoint("TOPRIGHT", raid, "BOTTOMRIGHT", 0, -8)
    groups.rows = {}
    for index = 1, 3 do
        local captured = index
        local row = UI:TableRow(groups, 306, 27, function(button)
            if button.otlGroupId then owner:OpenNativeObject180({ type = "GROUP", target = button.otlGroupId, page = "pve" })
            else owner:ShowPage("pve") end
        end)
        row:SetPoint("TOPLEFT", groups, "TOPLEFT", 12, -31 - ((captured - 1) * 29))
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetTexture("Interface\\Icons\\INV_Misc_GroupNeedMore")
        row.icon:SetWidth(16) row.icon:SetHeight(16)
        row.icon:SetPoint("LEFT", row, "LEFT", 7, 0)
        row.titleText = Label(row, "", "GameFontNormalSmall", 28, -7, 150, "LEFT")
        row.leaderText = Label(row, "", "GameFontNormalSmall", 178, -7, 82, "LEFT")
        row.leaderText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        row.countText = Label(row, "", "GameFontNormalSmall", 260, -7, 38, "RIGHT")
        row:Hide()
        groups.rows[captured] = row
    end
    groups.empty = Label(groups, "No active guild groups.", "GameFontNormalSmall", 12, -48, 306, "CENTER")
    groups.empty:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    groups.open = UI:Button(groups, "Group Finder", 104, 23, function() owner:ShowPage("pve") end, "inline")
    groups.open:SetPoint("BOTTOMRIGHT", groups, "BOTTOMRIGHT", -10, 8)
    owner.ui.homeGroupsCard = groups

    local leadership = UI:Card(panel, 332, 154, "Leadership Online")
    leadership:SetPoint("TOPRIGHT", groups, "BOTTOMRIGHT", 0, -8)
    leadership.guildLeader = UI:TableRow(leadership, 306, 62, function(button)
        if button.otlMemberName then owner:OpenPlayerMenu(button.otlMemberName, button) end
    end)
    leadership.guildLeader:SetPoint("TOPLEFT", leadership, "TOPLEFT", 12, -31)
    leadership.guildLeader.icon = leadership.guildLeader:CreateTexture(nil, "ARTWORK")
    leadership.guildLeader.icon:SetTexture(HOME_ROLE_ICONS["Guild Leader"])
    leadership.guildLeader.icon:SetWidth(28) leadership.guildLeader.icon:SetHeight(28)
    leadership.guildLeader.icon:SetPoint("TOPLEFT", leadership.guildLeader, "TOPLEFT", 8, -9)
    leadership.guildLeader.nameText = Label(leadership.guildLeader, "", "GameFontNormal", 44, -7, 158, "LEFT")
    leadership.guildLeader.roleText = Label(leadership.guildLeader, "Guild Leader", "GameFontNormalSmall", 204, -8, 92, "RIGHT")
    leadership.guildLeader.roleText:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    leadership.guildLeader.subtitleText = Label(leadership.guildLeader, "Guild Leader • Addon Creator\nQuestions about the guild or addon", "GameFontNormalSmall", 44, -27, 178, "LEFT")
    leadership.guildLeader.subtitleText:SetHeight(32)
    leadership.guildLeader.subtitleText:SetJustifyV("TOP")
    leadership.guildLeader.subtitleText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    leadership.guildLeader.whisper = UI:Button(leadership.guildLeader, "Whisper", 72, 22, function()
        local name = leadership.guildLeader.otlMemberName
        if name then owner:WhisperMember(name) end
    end, "inline")
    leadership.guildLeader.whisper:SetPoint("BOTTOMRIGHT", leadership.guildLeader, "BOTTOMRIGHT", -7, 6)
    leadership.guildLeader:Hide()
    leadership.mainRaidLeader = UI:TableRow(leadership, 306, 48, function(button)
        if button.otlMemberName then owner:OpenPlayerMenu(button.otlMemberName, button) end
    end)
    leadership.mainRaidLeader.icon = leadership.mainRaidLeader:CreateTexture(nil, "ARTWORK")
    leadership.mainRaidLeader.icon:SetTexture(HOME_ROLE_ICONS["Raid Leader"])
    leadership.mainRaidLeader.icon:SetWidth(24) leadership.mainRaidLeader.icon:SetHeight(24)
    leadership.mainRaidLeader.icon:SetPoint("LEFT", leadership.mainRaidLeader, "LEFT", 8, 0)
    leadership.mainRaidLeader.nameText = Label(leadership.mainRaidLeader, "", "GameFontNormal", 40, -7, 148, "LEFT")
    leadership.mainRaidLeader.roleText = Label(leadership.mainRaidLeader, "Main Raid Leader", "GameFontNormalSmall", 186, -8, 112, "RIGHT")
    leadership.mainRaidLeader.roleText:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    leadership.mainRaidLeader.subtitleText = Label(leadership.mainRaidLeader, "Questions about raids", "GameFontNormalSmall", 40, -27, 174, "LEFT")
    leadership.mainRaidLeader.subtitleText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    leadership.mainRaidLeader.whisper = UI:Button(leadership.mainRaidLeader, "Whisper", 66, 21, function()
        local name = leadership.mainRaidLeader.otlMemberName
        if name then owner:WhisperMember(name) end
    end, "inline")
    leadership.mainRaidLeader.whisper:SetPoint("BOTTOMRIGHT", leadership.mainRaidLeader, "BOTTOMRIGHT", -6, 5)
    leadership.mainRaidLeader:Hide()
    leadership.rows = {}
    for index = 1, 4 do
        local captured = index
        local row = UI:TableRow(leadership, 148, 27, function(button)
            if button.otlMemberName then owner:OpenPlayerMenu(button.otlMemberName, button) end
        end)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetWidth(16) row.icon:SetHeight(16)
        row.icon:SetPoint("LEFT", row, "LEFT", 7, 0)
        row.nameText = Label(row, "", "GameFontNormalSmall", 28, -7, 74, "LEFT")
        row.rankText = Label(row, "", "GameFontNormalSmall", 103, -7, 38, "RIGHT")
        row.rankText:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
        row:Hide()
        leadership.rows[captured] = row
    end
    leadership.empty = Label(leadership, "No leadership members are online.", "GameFontNormalSmall", 12, -50, 306, "CENTER")
    leadership.empty:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    leadership.moreText = Label(leadership, "", "GameFontNormalSmall", 12, -136, 306, "CENTER")
    leadership.moreText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    leadership.moreText:Hide()
    owner.ui.homeLeadershipCard = leadership

    local activity = UI:Card(panel, 932, 112, "Recent Important Activity")
    activity:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    activity.viewAll = UI:Button(activity, "View All", 76, 23, function() owner:OpenActionCenterFiltered180("ACTION") end, "inline")
    activity.viewAll:SetPoint("TOPRIGHT", activity, "TOPRIGHT", -10, -7)
    activity.rows = {}
    for index = 1, 3 do
        local captured = index
        local row = UI:TableRow(activity, 902, 24, function(button)
            local entry = button.otlActivity
            if entry then
                if entry.targetType and entry.targetId then owner:OpenNativeObject180({ type = entry.targetType, target = entry.targetId, page = entry.targetPage })
                elseif entry.targetPage then owner:ShowPage(entry.targetPage) end
            end
        end)
        row:SetPoint("TOPLEFT", activity, "TOPLEFT", 13, -31 - ((captured - 1) * 25))
        row.kindIcon = row:CreateTexture(nil, "ARTWORK")
        row.kindIcon:SetWidth(16) row.kindIcon:SetHeight(16)
        row.kindIcon:SetPoint("LEFT", row, "LEFT", 7, 0)
        row.timeText = Label(row, "", "GameFontNormalSmall", 30, -6, 92, "LEFT")
        row.timeText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        row.titleText = Label(row, "", "GameFontNormalSmall", 126, -6, 748, "LEFT")
        row:Hide()
        activity.rows[captured] = row
    end
    activity.empty = Label(activity, "Important guild activity will appear here.", "GameFontNormalSmall", 14, -52, 900, "CENTER")
    activity.empty:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    owner.ui.homeActivityCard = activity

    local forYou = UI:Card(panel, 452, 112, "For You")
    forYou:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    forYou.viewAll = UI:Button(forYou, "View All", 76, 23, function() owner:OpenActionCenterFiltered180("ALL") end, "primary")
    forYou.viewAll:SetPoint("TOPRIGHT", forYou, "TOPRIGHT", -10, -7)
    forYou.rows = {}
    for index = 1, 3 do
        local captured = index
        local row = UI:TableRow(forYou, 424, 24, function(button)
            if button.otlAction then owner:OpenActionCenterEntry180(button.otlAction) end
        end)
        row:SetPoint("TOPLEFT", forYou, "TOPLEFT", 12, -31 - ((captured - 1) * 25))
        row.marker = row:CreateTexture(nil, "ARTWORK")
        row.marker:SetTexture(C.gold[1], C.gold[2], C.gold[3], 1)
        row.marker:SetWidth(4) row.marker:SetHeight(16)
        row.marker:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.titleText = Label(row, "", "GameFontNormalSmall", 18, -6, 388, "LEFT")
        row:Hide()
        forYou.rows[captured] = row
    end
    forYou:Hide()
    owner.ui.homeForYouCard180 = forYou
end

local function BuildPosts(owner, page)
    local panel = CreateFrame("Frame", nil, page)
    panel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -40)
    panel:SetWidth(932)
    panel:SetHeight(548)
    panel:Hide()
    owner.ui.homePostsPanel = panel

    local list = UI:Card(panel, 344, 548, "Guild Posts")
    list:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    list:EnableMouse(true)
    list:EnableMouseWheel(true)
    list.otlMouseWheelOwner = true
    list:SetScript("OnMouseWheel", function()
        local maximum = tonumber(this.otlMaximumOffset) or 0
        owner.ui.homePostOffset = math.max(0, math.min(maximum,
            (tonumber(owner.ui.homePostOffset) or 0) - ((tonumber(arg1) or 0) * 3)))
        owner:RefreshHomePage()
    end)
    list.rows = {}
    local index
    for index = 1, 11 do
        local captured = index
        local row = UI:TableRow(list, 304, 48, function(button)
            if button.otlRecordId then owner:SelectHomePost(button.otlRecordId) end
        end)
        row:SetPoint("TOPLEFT", list, "TOPLEFT", 12, -58 - ((captured - 1) * 51))
        row.dateHeader = Label(row, "", "GameFontNormalSmall", 4, -5, 284, "LEFT")
        row.dateHeader:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
        row.dateHeader:Hide()
        row.kindIcon = row:CreateTexture(nil, "ARTWORK")
        row.kindIcon:SetWidth(18) row.kindIcon:SetHeight(18)
        row.kindIcon:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.titleText = Label(row, "", "GameFontNormalSmall", 30, -6, 172, "LEFT")
        row.titleText:SetHeight(26)
        row.titleText:SetJustifyV("TOP")
        row.badgeText = Label(row, "", "GameFontNormalSmall", 204, -6, 88, "RIGHT")
        row.badgeText:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
        row.metaText = Label(row, "", "GameFontNormalSmall", 30, -21, 262, "LEFT")
        row.metaText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        row.previewText = Label(row, "", "GameFontNormalSmall", 30, -39, 262, "LEFT")
        row.previewText:SetTextColor(0.76, 0.74, 0.68)
        row.previewText:SetHeight(18)
        row.unreadBar = row:CreateTexture(nil, "ARTWORK")
        row.unreadBar:SetTexture(C.gold[1], C.gold[2], C.gold[3], 1)
        row.unreadBar:SetPoint("TOPLEFT", row, "TOPLEFT", 1, -2)
        row.unreadBar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 1, 2)
        row.unreadBar:SetWidth(3)
        row.unreadBar:Hide()
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function()
            local maximum = tonumber(list.otlMaximumOffset) or 0
            owner.ui.homePostOffset = math.max(0, math.min(maximum,
                (tonumber(owner.ui.homePostOffset) or 0) - ((tonumber(arg1) or 0) * 3)))
            owner:RefreshHomePage()
        end)
        row:Hide()
        list.rows[captured] = row
    end
    list.archive = UI:Button(list, "Archive", 102, 26, function()
        owner.ui.homeShowArchived = not owner.ui.homeShowArchived
        owner.ui.homeSelectedPostId = nil
        owner.ui.homePostOffset = 0
        owner:RefreshHomePage()
    end, "utility")
    list.archive:SetPoint("TOPLEFT", list, "TOPLEFT", 12, -26)
    list.new = UI:Button(list, "New Guild Post", 150, 26, function() owner:OpenHomePostEditor() end, "primary")
    list.new:SetPoint("TOPRIGHT", list, "TOPRIGHT", -12, -26)
    list.empty = Label(list, "", "GameFontNormalSmall", 12, -92, 320, "CENTER")
    list.empty:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    list.empty:Hide()
    list.counter = Label(list, "", "GameFontNormalSmall", 12, -522, 320, "LEFT")
    list.counter:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    list.counter:ClearAllPoints()
    list.counter:SetPoint("BOTTOMLEFT", list, "BOTTOMLEFT", 12, 12)
    list.scrollbar = UI:Scrollbar(list, 410, function(value)
        owner.ui.homePostOffset = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
        owner:RefreshHomePage()
    end)
    list.scrollbar:SetPoint("TOPRIGHT", list, "TOPRIGHT", -6, -58)
    list.scrollbar:Hide()
    owner.ui.homePostList = list

    local details = UI:DetailsPanel(panel, 576, 548, "Post Details")
    details:SetPoint("TOPLEFT", panel, "TOPLEFT", 356, 0)
    details.postTitle = Label(details, "", "GameFontNormalLarge", 14, -34, 548, "LEFT")
    details.postTitle:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    details.postTitle:SetHeight(42)
    details.postTitle:SetJustifyV("TOP")
    details.meta = Label(details, "", "GameFontNormalSmall", 14, -80, 548, "LEFT")
    details.meta:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    details.bodyScroll = CreateFrame("ScrollFrame", nil, details)
    details.bodyScroll:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -108)
    details.bodyScroll:SetWidth(528)
    details.bodyScroll:SetHeight(244)
    details.bodyChild = CreateFrame("Frame", nil, details.bodyScroll)
    details.bodyChild:SetWidth(510)
    details.bodyChild:SetHeight(244)
    details.bodyScroll:SetScrollChild(details.bodyChild)
    details.body = Label(details.bodyChild, "", "GameFontNormal", 0, 0, 500, "LEFT")
    details.body:SetJustifyV("TOP")
    details.body:SetHeight(240)
    -- Separate unconstrained measurement string: GetStringHeight on the visible
    -- fixed-height body is unreliable on Vanilla-derived clients.
    details.bodyMeasure180 = Label(details.bodyChild, "", "GameFontNormal", -2000, 0, 500, "LEFT")
    details.bodyMeasure180:SetJustifyV("TOP")
    details.bodyMeasure180:SetAlpha(0)
    details.scrollbar = UI:Scrollbar(details, 244, function(value)
        details.bodyScroll:SetVerticalScroll(value)
        owner.ui.homePostBodyOffsets180 = owner.ui.homePostBodyOffsets180 or {}
        if details.otlRecordId then owner.ui.homePostBodyOffsets180[details.otlRecordId] = tonumber(value) or 0 end
    end)
    details.scrollbar:SetPoint("TOPRIGHT", details, "TOPRIGHT", -12, -108)
    details.bodyScroll:EnableMouse(true)
    details.bodyScroll:EnableMouseWheel(true)
    details.bodyScroll:SetScript("OnMouseWheel", function()
        local minimum, maximum = details.scrollbar:GetMinMaxValues()
        local nextValue = math.max(minimum or 0, math.min(maximum or 0,
            (details.scrollbar:GetValue() or 0) - ((tonumber(arg1) or 0) * 42)))
        details.scrollbar:SetValue(nextValue)
    end)
    details.like = UI:Button(details, "Like", 92, 27, function()
        if details.otlRecordId then owner:ReactToAnnouncement152(details.otlRecordId, "LIKE") owner:RefreshHomePage() end
    end, "secondary")
    details.like:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -352)
    details.likeCount = UI:Button(details, "0", 34, 27, function()
        if details.otlRecordId then owner:ShowHomePostPeople180(details.otlRecordId, "LIKE") end
    end, "inline")
    details.likeCount:SetPoint("LEFT", details.like, "RIGHT", 4, 0)
    details.seen = UI:Button(details, "Seen", 104, 27, function()
        if details.otlRecordId then owner:ReactToAnnouncement152(details.otlRecordId, "SEEN") owner:RefreshHomePage() end
    end, "secondary")
    details.seen:SetPoint("LEFT", details.like, "RIGHT", 8, 0)
    details.seenCount = UI:Button(details, "0", 34, 27, function()
        if details.otlRecordId then owner:ShowHomePostPeople180(details.otlRecordId, "SEEN") end
    end, "inline")
    details.seenCount:SetPoint("LEFT", details.seen, "RIGHT", 4, 0)
    details.support = UI:Button(details, "Support", 104, 27, function()
        if details.otlRecordId then owner:ReactToAnnouncement152(details.otlRecordId, "SUPPORT") owner:RefreshHomePage() end
    end, "secondary")
    details.support:SetPoint("LEFT", details.seen, "RIGHT", 8, 0)
    details.supportCount = UI:Button(details, "0", 34, 27, function()
        if details.otlRecordId then owner:ShowHomePostPeople180(details.otlRecordId, "SUPPORT") end
    end, "inline")
    details.supportCount:SetPoint("LEFT", details.support, "RIGHT", 4, 0)
    details.readers = UI:Button(details, "Read", 82, 27, function()
        if details.otlRecordId then owner:ShowHomePostReaders(details.otlRecordId) end
    end, "inline")
    details.readers:SetPoint("LEFT", details.support, "RIGHT", 8, 0)
    details.edit = UI:Button(details, "Edit", 82, 28, function()
        if details.otlRecordId then owner:OpenHomePostEditor(details.otlRecordId) end
    end, "secondary")
    details.edit:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -394)
    details.archive = UI:Button(details, "Archive", 98, 28, function()
        local record = details.otlRecordId and owner:GetAnnouncement152(details.otlRecordId)
        if record then
            owner:SetAnnouncementArchived152(record.id, not record.archived)
            owner.ui.homeSelectedPostId = nil
            owner:ShowToast(record.archived and "Guild post archived." or "Guild post restored.", "success")
            owner:RefreshHomePage()
        end
    end, "utility")
    details.archive:SetPoint("LEFT", details.edit, "RIGHT", 8, 0)
    details.delete = UI:Button(details, "Delete", 92, 28, function()
        local record = details.otlRecordId and owner:GetAnnouncement152(details.otlRecordId)
        if not record then return end
        owner:ShowConfirm("Delete Guild Post?", "Delete \"" .. tostring(record.title or "this post") .. "\" from the shared guild archive?", "Delete", function()
            owner:DeleteAnnouncement152(record.id)
            owner.ui.homeSelectedPostId = nil
            owner:RefreshHomePage()
        end)
    end, "danger")
    details.delete:SetPoint("LEFT", details.archive, "RIGHT", 8, 0)
    details.empty = UI:EmptyState(details, 500, 150, "Select a guild post", "Choose a post on the left to read it and see available actions.")
    details.empty:SetPoint("CENTER", details, "CENTER", 0, 10)
    owner.ui.homePostDetails = details
end

local function BuildHome(owner, page)
    owner.ui.homeOverviewTab = UI:Tab(page, "Overview", 120, function() owner:SetHomeTab("OVERVIEW") end)
    owner.ui.homeOverviewTab:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -4)
    owner.ui.homePostsTab = UI:Tab(page, "Guild Posts", 132, function() owner:SetHomeTab("POSTS") end)
    owner.ui.homePostsTab:SetPoint("LEFT", owner.ui.homeOverviewTab, "RIGHT", 8, 0)
    owner.ui.homeGuildInfo = UI:Button(page, "Guild Info", 108, 28, function() owner:ShowPage("guildinfo") end, "utility")
    owner.ui.homeGuildInfo:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -4)
    BuildOverview(owner, page)
    BuildPosts(owner, page)
    owner.ui.homePostOffset = 0
    owner.ui.homePostBodyOffsets180 = owner.ui.homePostBodyOffsets180 or {}
    owner.ui.homeShellTab = OTLGM_DB.settings.homeShellTab == "POSTS" and "POSTS" or "OVERVIEW"
    if owner.ui.homeShellTab == "POSTS" then owner.ui.homeOverviewPanel:Hide() owner.ui.homePostsPanel:Show() end
end

local HOME_ACTIVITY_ICONS = {
    REACTION = "Interface\\Icons\\INV_ValentinesCard01",
    RAID = "Interface\\Icons\\INV_Helmet_06",
    GROUP = "Interface\\Icons\\INV_Misc_GroupNeedMore",
    CRAFTING = "Interface\\Icons\\Trade_BlackSmithing",
    ROSTER = "Interface\\Icons\\INV_Misc_GroupLooking",
    ANNOUNCEMENT = "Interface\\Icons\\INV_Scroll_03",
    NOTE = "Interface\\Icons\\INV_Misc_Note_06",
    TREASURY = "Interface\\Icons\\INV_Misc_Coin_01",
}

local function GroupHomeActivity(owner, source)
    local result, groups, seenEvents = {}, {}, {}
    local index, entry
    for index = 1, table.getn(source or {}) do
        entry = source[index]
        local eventKey = entry and tostring(entry.eventKey180 or entry.eventKey175 or "") or ""
        local _, _, targetType, targetId = string.find(eventKey, "^REACT:([^:]+):(.+):[^:]+$")
        if entry and entry.kind == "REACTION" and targetType and targetId then
            local key = "REACTION:" .. targetType .. ":" .. targetId
            local group = groups[key]
            if not group then
                group = { kind = "REACTION", eventType = "REACTION", objectId = targetId,
                    targetPage = entry.targetPage, ts = entry.ts, count = 0,
                    targetType = targetType, targetId = targetId, names = {}, nameKeys = {} }
                groups[key] = group
                table.insert(result, group)
            end
            group.count = group.count + 1
            group.ts = math.max(tonumber(group.ts) or 0, tonumber(entry.ts) or 0)
            local _, _, reactionName = string.find(tostring(entry.body or ""), "^([^ ]+) reacted")
            if not reactionName then _, _, reactionName = string.find(tostring(entry.title or ""), "^([^ ]+) reacted") end
            reactionName = reactionName or "Guild member"
            local normalized = string.lower(reactionName)
            if not group.nameKeys[normalized] then group.nameKeys[normalized] = true table.insert(group.names, reactionName) end
        elseif entry then
            local eventType = tostring(entry.eventType or entry.kind or "EVENT")
            local objectId = entry.objectId or entry.targetId or entry.recordId or entry.id
            local identity
            if objectId and tostring(objectId) ~= "" then
                identity = string.lower(eventType .. ":" .. tostring(objectId))
            elseif eventKey ~= "" then
                identity = string.lower(eventType .. ":" .. eventKey)
            else
                identity = string.lower(table.concat({ eventType, tostring(entry.title or ""), tostring(entry.detail or entry.body or "") }, "|"))
            end
            if not seenEvents[identity] then
                seenEvents[identity] = true
                entry.eventType = eventType
                entry.objectId = objectId
                table.insert(result, entry)
            end
        end
        if table.getn(result) >= 8 then break end
    end
    for index = 1, table.getn(result) do
        entry = result[index]
        if entry.targetType then
            local title = owner.GetReactionTargetTitle180 and owner:GetReactionTargetTitle180(entry.targetType, entry.targetId) or "guild post"
            local visibleNames = {}
            local nameIndex
            for nameIndex = 1, math.min(3, table.getn(entry.names or {})) do table.insert(visibleNames, entry.names[nameIndex]) end
            local remaining = math.max(0, table.getn(entry.names or {}) - table.getn(visibleNames))
            entry.title = (table.getn(visibleNames) > 0 and table.concat(visibleNames, ", ") or tostring(entry.count) .. " members")
                .. (remaining > 0 and (" +" .. tostring(remaining)) or "") .. " reacted to \"" .. Short(title, 44) .. "\""
            entry.tooltip = table.concat(entry.names or {}, ", ")
        end
    end
    return result
end

local function IsGuildLeaderMember(member)
    if not member then return false end
    return OTLGM.IsCanonicalGuildLeaderName180 and OTLGM:IsCanonicalGuildLeaderName180(member.name) or false
end

local function HomePostDateGroup(owner, timestamp)
    timestamp = tonumber(timestamp) or owner:Now()
    local today = date("%Y-%m-%d", owner:Now())
    local yesterday = date("%Y-%m-%d", owner:Now() - 86400)
    local key = date("%Y-%m-%d", timestamp)
    if key == today then return "Today" end
    if key == yesterday then return "Yesterday" end
    if owner:Now() - timestamp > 30 * 86400 then return "Older" end
    return date("%d %B %Y", timestamp)
end

local function HomePostBadges(owner, record)
    if not record then return "" end
    local parts = {}
    if owner.IsAnnouncementUnread154 and owner:IsAnnouncementUnread154(record.id) then table.insert(parts, "NEW") end
    if record.importance == "CRITICAL" then table.insert(parts, "URGENT")
    elseif record.importance == "IMPORTANT" then table.insert(parts, "IMPORTANT") end
    if record.pinned then table.insert(parts, "PINNED") end
    return table.concat(parts, "  ")
end

local function HomeCountdown(owner, timestamp)
    timestamp = tonumber(timestamp)
    if not timestamp then return "Countdown unavailable" end
    local remaining = timestamp - owner:Now()
    if remaining <= 0 then
        local elapsed = math.max(0, -remaining)
        if elapsed < 60 then return "Starting now" end
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor(math.mod(elapsed, 3600) / 60)
        if hours > 0 then return "Started " .. tostring(hours) .. "h " .. tostring(minutes) .. "m ago" end
        return "Started " .. tostring(math.max(1, minutes)) .. "m ago"
    end
    local days = math.floor(remaining / 86400)
    local hours = math.floor(math.mod(remaining, 86400) / 3600)
    local minutes = math.floor(math.mod(remaining, 3600) / 60)
    if days > 0 then return "In " .. tostring(days) .. "d " .. tostring(hours) .. "h" end
    if hours > 0 then return "In " .. tostring(hours) .. "h " .. tostring(minutes) .. "m" end
    return "In " .. tostring(math.max(1, minutes)) .. "m"
end

local function ApplyHomeBottomLayout180(owner)
    local panel = owner.ui and owner.ui.homeOverviewPanel
    local activity = owner.ui and owner.ui.homeActivityCard
    local forYou = owner.ui and owner.ui.homeForYouCard180
    if not panel or not activity or not forYou then return end
    local width = math.max(400, panel:GetWidth() or 932)
    local height = math.max(90, activity:GetHeight() or 112)
    local gap = 10
    local hasActions = owner.ui.homeForYouHasActions180 and true or false
    activity:ClearAllPoints()
    forYou:ClearAllPoints()
    if hasActions then
        local forWidth = math.max(320, math.floor(width * 0.48))
        local activityWidth = width - forWidth - gap
        forYou:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
        forYou:SetWidth(forWidth) forYou:SetHeight(height) forYou:Show()
        activity:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
        activity:SetWidth(activityWidth) activity:SetHeight(height)
    else
        forYou:Hide()
        activity:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
        activity:SetWidth(width) activity:SetHeight(height)
    end
    local index
    for index = 1, table.getn(activity.rows or {}) do
        local row = activity.rows[index]
        row:SetWidth(activity:GetWidth() - 24)
        row.titleText:SetWidth(math.max(120, activity:GetWidth() - 166))
    end
    activity.empty:SetWidth(activity:GetWidth() - 28)
    for index = 1, table.getn(forYou.rows or {}) do
        local row = forYou.rows[index]
        row:SetWidth(forYou:GetWidth() - 24)
        row.titleText:SetWidth(math.max(150, forYou:GetWidth() - 48))
    end
end

local function RefreshOverview(owner)
    local announcements = owner:GetAnnouncementList152(false) or {}
    local pinned, index
    for index = 1, table.getn(announcements) do
        if announcements[index].pinned then pinned = announcements[index] break end
    end
    if not pinned then
        for index = 1, table.getn(announcements) do
            if announcements[index].importance == "CRITICAL" then pinned = announcements[index] break end
        end
    end
    pinned = pinned or announcements[1]
    local card = owner.ui.homePinnedCard
    if pinned then
        card.otlRecordId = pinned.id
        card.titleText:SetText(Short(pinned.title or "Guild Post", 70))
        card.badgeText:SetText(HomePostBadges(owner, pinned))
        card.metaText:SetText("By " .. tostring(pinned.author or "Leadership") .. "  •  " .. owner:Stamp(pinned.createdAt))
        card.bodyText:SetText(WordSafePreview(pinned.body or "", 560))
        card.icon:SetTexture(pinned.importance == "CRITICAL" and "Interface\\Icons\\Ability_Warrior_RallyingCry" or "Interface\\Icons\\INV_Scroll_03")
        -- Semantic importance belongs to the card frame, not a bright full fill.
        -- The narrow accent remains readable without breaking the black/gold shell.
        if pinned.importance == "CRITICAL" then
            card.importanceAccent180:SetTexture(0.78, 0.12, 0.10, 1)
            card:SetBackdropColor(0.095, 0.035, 0.028, 1)
            card:SetBackdropBorderColor(0.62, 0.16, 0.12, 0.95)
        elseif pinned.importance == "IMPORTANT" then
            card.importanceAccent180:SetTexture(C.gold[1], C.gold[2], C.gold[3], 1)
            card:SetBackdropColor(0.075, 0.056, 0.025, 1)
            card:SetBackdropBorderColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3], 1)
        else
            card.importanceAccent180:SetTexture(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3], 0.72)
            card:SetBackdropColor(0.055, 0.045, 0.025, 1)
            card:SetBackdropBorderColor(C.goldDark[1], C.goldDark[2], C.goldDark[3], 0.86)
        end
        card.importanceAccent180:Show()
        card.open:Show()
        local summary = owner:GetAnnouncementReactionSummary152(pinned.id) or {}
        local modes = { "LIKE", "SEEN", "SUPPORT", "READ" }
        for index = 1, table.getn(card.reactions or {}) do
            local mode = modes[index]
            local count
            if mode == "READ" then count = table.getn(owner.GetAnnouncementReaders172 and owner:GetAnnouncementReaders172(pinned.id) or {})
            else count = tonumber(summary[mode]) or 0 end
            UI:SetText(card.reactions[index], (mode == "LIKE" and "Like" or mode == "SEEN" and "Seen" or mode == "SUPPORT" and "Support" or "Read") .. " " .. tostring(count))
            local names = mode == "READ" and (owner.GetAnnouncementReaders172 and owner:GetAnnouncementReaders172(pinned.id) or {})
                or (owner.GetCommunityReactors and owner:GetCommunityReactors("ANN", pinned.id, mode) or {})
            card.reactions[index].otlTooltip = table.getn(names) > 0 and table.concat(names, ", ") or "No names yet."
            card.reactions[index]:Show()
        end
    else
        card.otlRecordId = nil
        card.titleText:SetText("No official guild post")
        card.badgeText:SetText("")
        card.metaText:SetText("Leadership posts will appear here.")
        card.bodyText:SetText("")
        if card.importanceAccent180 then card.importanceAccent180:Hide() end
        card:SetBackdropColor(0.055, 0.045, 0.025, 1)
        card:SetBackdropBorderColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3], 1)
        card.open:Hide()
        for index = 1, table.getn(card.reactions or {}) do card.reactions[index]:Hide() end
    end

    local candidates, fallback = {}, {}
    for index = 1, table.getn(announcements) do
        local record = announcements[index]
        if not pinned or record.id ~= pinned.id then
            local unread = owner.IsAnnouncementUnread154 and owner:IsAnnouncementUnread154(record.id)
            if unread or record.importance == "CRITICAL" or record.importance == "IMPORTANT" then table.insert(candidates, record)
            else table.insert(fallback, record) end
        end
    end
    for index = 1, table.getn(fallback) do
        if table.getn(candidates) >= 2 then break end
        table.insert(candidates, fallback[index])
    end
    local recent = owner.ui.homeRecentPostsCard
    for index = 1, table.getn(recent.rows) do
        local row, record = recent.rows[index], candidates[index]
        if record then
            row.otlRecordId = record.id
            row.icon:SetTexture(record.importance == "CRITICAL" and "Interface\\Icons\\Ability_Warrior_RallyingCry" or "Interface\\Icons\\INV_Scroll_03")
            row.titleText:SetText(Short(record.title or "Guild Post", 64))
            row.badgeText:SetText(HomePostBadges(owner, record))
            row.metaText:SetText("By " .. tostring(record.author or "Leadership") .. "  •  " .. owner:Stamp(record.createdAt))
            row.previewText:SetText(WordSafePreview(record.body or "", 84))
            row:Show()
        else
            row.otlRecordId = nil
            row:Hide()
        end
    end
    if table.getn(candidates) == 0 then recent.empty:Show() else recent.empty:Hide() end

    local raid = owner.GetPveActiveRaid and owner:GetPveActiveRaid() or nil
    local raidCard = owner.ui.homeRaidCard
    if raid then
        raidCard.otlRaidId = raid.id
        local startTs = tonumber(raid.startTs)
        local dateText = owner.GetPveRaidServerTime155 and owner:GetPveRaidServerTime155(raid)
            or raid.serverTime or raid.when or (startTs and owner.FormatServerDate180 and owner.FormatServerClock180 and (owner:FormatServerDate180(startTs, "%d %b") .. "  " .. owner:FormatServerClock180(startTs, false) .. " ST")) or "Date and ST pending"
        local linkedTeam = raid.teamId180 and owner.GetRaidTeam180 and owner:GetRaidTeam180(raid.teamId180) or nil
        local raidLeader = (linkedTeam and linkedTeam.raidLeader) or raid.raidLeader or raid.leader or "Leadership"
        local inviteContact = (linkedTeam and linkedTeam.inviteContact) or raid.inviteContact or ""
        local gatherText = "TBA"
        if raid.gatherHour ~= nil or raid.gatherMinute ~= nil then
            gatherText = string.format("%02d:%02d ST", tonumber(raid.gatherHour) or tonumber(raid.stHour) or 0, tonumber(raid.gatherMinute) or tonumber(raid.stMinute) or 0)
        elseif raid.gatherTime or raid.gatherAt then
            gatherText = tostring(raid.gatherTime or raid.gatherAt)
        end
        raidCard.titleText:SetText(Short(raid.name or raid.activity or "Guild Raid", 54))
        raidCard.dateText:SetText(tostring(dateText))
        raidCard.leaderText:SetText("Raid Leader: " .. tostring(raidLeader))
        raidCard.contactText:SetText("")
        raidCard.gatherText:SetText("Gather: " .. gatherText .. "  •  " .. Short(raid.meetingPoint or raid.location or raid.meeting or "Meeting TBA", 24))
        raidCard.meetingText:SetText("")
        raidCard.countdownText:SetText(HomeCountdown(owner, startTs))
        raidCard.empty:Hide()
        raidCard.open:Show()
    else
        raidCard.otlRaidId = nil
        raidCard.titleText:SetText("") raidCard.dateText:SetText("") raidCard.leaderText:SetText("") raidCard.contactText:SetText("")
        raidCard.gatherText:SetText("") raidCard.meetingText:SetText("") raidCard.countdownText:SetText("")
        raidCard.empty:Show() raidCard.open:Hide()
    end

    local groups = owner.GetPveRequests and owner:GetPveRequests() or {}
    for index = 1, table.getn(owner.ui.homeGroupsCard.rows) do
        local row, record = owner.ui.homeGroupsCard.rows[index], groups[index]
        if record then
            row.otlGroupId = record.id
            row.titleText:SetText(Short(record.activity or "Guild group", 28))
            row.leaderText:SetText(Short(record.author or "Unknown", 12))
            row.countText:SetText(tostring(record.current or 1) .. "/" .. tostring(record.maxSize or 5))
            row:Show()
        else row.otlGroupId = nil row:Hide() end
    end
    if table.getn(groups) == 0 then owner.ui.homeGroupsCard.empty:Show() owner.ui.homeGroupsCard.open:Show()
    else owner.ui.homeGroupsCard.empty:Hide() owner.ui.homeGroupsCard.open:Hide() end

    local leadershipData = CollectHomeLeadership180(owner)
    local leaders = leadershipData.all
    local guildLeader = leadershipData.guildLeader
    local mainRaidLeader = leadershipData.mainRaidLeader
    local regular = leadershipData.regular
    local leadership = owner.ui.homeLeadershipCard
    leadership.otlLeadershipData180 = leadershipData
    leadership.otlHasGuildLeader180 = guildLeader and true or false
    leadership.otlHasMainRaidLeader180 = mainRaidLeader and true or false
    if guildLeader then
        local row = leadership.guildLeader
        row.otlMemberName = guildLeader.name
        row.nameText:SetText(owner:GetClassColor(guildLeader.class) .. tostring(guildLeader.name or "Morrow") .. owner.colors.reset)
        row.roleText:SetText("Guild Leader")
        row.icon:SetTexture(HOME_ROLE_ICONS["Guild Leader"])
        row:Show()
    else leadership.guildLeader.otlMemberName = nil leadership.guildLeader:Hide() end
    if mainRaidLeader then
        local row = leadership.mainRaidLeader
        row.otlMemberName = mainRaidLeader.name
        row.nameText:SetText(owner:GetClassColor(mainRaidLeader.class) .. tostring(mainRaidLeader.name or "Rangark") .. owner.colors.reset)
        row:Show()
    else leadership.mainRaidLeader.otlMemberName = nil leadership.mainRaidLeader:Hide() end
    local regularCapacity = math.max(0, tonumber(leadership.otlRegularCapacity180) or 4)
    for index = 1, table.getn(leadership.rows) do
        local row, member = leadership.rows[index], index <= regularCapacity and regular[index] or nil
        if member then
            local role = HomeLeadershipRole(member)
            row.otlMemberName = member.name
            row.icon:SetTexture(HOME_ROLE_ICONS[role] or HOME_ROLE_ICONS.Helper)
            row.nameText:SetText(owner:GetClassColor(member.class) .. Short(member.name or "", 12) .. owner.colors.reset)
            row.rankText:SetText(role == "Raid Leader" and "RL" or role == "Officer" and "Officer" or "Helper")
            row:Show()
        else row.otlMemberName = nil row:Hide() end
    end
    local hidden = math.max(0, table.getn(regular) - regularCapacity)
    if hidden > 0 then leadership.moreText:SetText("+" .. tostring(hidden) .. " more leadership online") leadership.moreText:Show()
    else leadership.moreText:Hide() end
    if table.getn(leaders) == 0 then leadership.empty:Show() else leadership.empty:Hide() end

    local activity = GroupHomeActivity(owner, owner.GetUsefulActivity152 and owner:GetUsefulActivity152(24) or {})
    for index = 1, table.getn(owner.ui.homeActivityCard.rows) do
        local row, entry = owner.ui.homeActivityCard.rows[index], activity[index]
        if entry then
            row.otlActivity = entry
            row.otlTooltipTitle = entry.targetType and "Reactions" or nil
            row.otlTooltip = entry.tooltip
            local kind = string.upper(tostring(entry.eventType or entry.kind or "NOTE"))
            row.kindIcon:SetTexture(HOME_ACTIVITY_ICONS[kind] or HOME_ACTIVITY_ICONS.NOTE)
            row.timeText:SetText(date("%H:%M", entry.ts or owner:Now()))
            row.titleText:SetText(Short(entry.title or entry.detail or entry.body or "Guild activity", 112))
            row:Show()
        else row.otlActivity = nil row.otlTooltip = nil row:Hide() end
    end
    if table.getn(activity) == 0 then owner.ui.homeActivityCard.empty:Show() else owner.ui.homeActivityCard.empty:Hide() end

    local actions = owner.GetPersonalActionEntries180 and owner:GetPersonalActionEntries180(3) or {}
    local forYou = owner.ui.homeForYouCard180
    owner.ui.homeForYouHasActions180 = table.getn(actions) > 0
    for index = 1, table.getn(forYou.rows) do
        local row, entry = forYou.rows[index], actions[index]
        if entry then
            row.otlAction = entry
            local body = tostring(entry.body or "")
            row.titleText:SetText(Short(tostring(entry.title or "Action") .. (body ~= "" and (" — " .. body) or ""), 78))
            if entry.read then row.marker:Hide() else row.marker:Show() end
            row:Show()
        else
            row.otlAction = nil
            row:Hide()
        end
    end
    ApplyHomeBottomLayout180(owner)
end

local function RefreshPosts(owner)
    local showArchived = owner.ui.homeShowArchived and true or false
    local all = owner:GetAnnouncementList152(true)
    local list = {}
    local index
    for index = 1, table.getn(all) do
        if (all[index].archived and true or false) == showArchived then table.insert(list, all[index]) end
    end
    local archivedCount = 0
    for index = 1, table.getn(all) do if all[index].archived then archivedCount = archivedCount + 1 end end
    local activeCount = table.getn(all) - archivedCount
    owner.ui.homePostList.counter:SetText(tostring(activeCount) .. " posts • " .. tostring(archivedCount) .. " archived")
    local listHeight = owner.ui.homePostsPanel:GetHeight()
    owner.ui.homePostList:SetHeight(listHeight)
    local capacity = math.max(4, math.min(table.getn(owner.ui.homePostList.rows), math.floor((listHeight - 80) / 70)))
    local maximum = math.max(0, table.getn(list) - capacity)
    local offset = math.max(0, math.min(maximum, tonumber(owner.ui.homePostOffset) or 0))
    owner.ui.homePostOffset = offset
    owner.ui.homePostList.otlMaximumOffset = maximum
    owner.ui.homePostList.scrollbar.otlSilent = true
    owner.ui.homePostList.scrollbar:SetMinMaxValues(0, maximum)
    owner.ui.homePostList.scrollbar:SetValue(offset)
    owner.ui.homePostList.scrollbar:SetHeight(math.max(40, listHeight - 100))
    owner.ui.homePostList.scrollbar.otlSilent = nil
    if maximum > 0 then owner.ui.homePostList.scrollbar:Show() else owner.ui.homePostList.scrollbar:Hide() end
    UI:SetText(owner.ui.homePostList.archive, showArchived and "Active Posts" or "Archive")
    local canPublish = owner.CanPublishAnnouncement152 and owner:CanPublishAnnouncement152()
    if canPublish then owner.ui.homePostList.new:Show() else owner.ui.homePostList.new:Hide() end
    local previousDateGroup
    local rowY = 58
    local visibleRows = 0
    for index = 1, table.getn(owner.ui.homePostList.rows) do
        local row = owner.ui.homePostList.rows[index]
        local record = index <= capacity and list[offset + index] or nil
        if record then
            visibleRows = visibleRows + 1
            row.otlRecordId = record.id
            local unread = owner.IsAnnouncementUnread154 and owner:IsAnnouncementUnread154(record.id)
            local urgent = record.importance == "CRITICAL"
            if urgent then row.kindIcon:SetTexture("Interface\\Icons\\Ability_Warrior_RallyingCry")
            elseif record.pinned then row.kindIcon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
            else row.kindIcon:SetTexture("Interface\\Icons\\INV_Scroll_03") end
            row.titleText:SetText(Short(record.title or "Guild Post", 72))
            local badges = ""
            if record.pinned then badges = "PIN" end
            if urgent then badges = badges .. (badges ~= "" and "  " or "") .. "URG" end
            if unread then badges = badges .. (badges ~= "" and "  " or "") .. "NEW" end
            row.badgeText:SetText(badges)
            row.metaText:SetText((unread and "Unread  |  " or "") .. tostring(record.author or "Leadership") .. "  " .. date("%d %b %H:%M", record.createdAt or owner:Now()))
            row.previewText:SetText(WordSafePreview(record.body or "", 72))
            local dateGroup = HomePostDateGroup(owner, record.createdAt)
            local showHeader = dateGroup ~= previousDateGroup
            previousDateGroup = dateGroup
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", owner.ui.homePostList, "TOPLEFT", 12, -rowY)
            if showHeader then
                row:SetHeight(84)
                row.dateHeader:SetText(dateGroup)
                row.dateHeader:Show()
                row.kindIcon:ClearAllPoints()
                row.kindIcon:SetPoint("TOPLEFT", row, "TOPLEFT", 6, -28)
                row.titleText:ClearAllPoints()
                row.titleText:SetPoint("TOPLEFT", row, "TOPLEFT", 30, -22)
                row.titleText:SetHeight(30)
                row.metaText:ClearAllPoints()
                row.metaText:SetPoint("TOPLEFT", row, "TOPLEFT", 30, -52)
                row.previewText:ClearAllPoints()
                row.previewText:SetPoint("TOPLEFT", row, "TOPLEFT", 30, -67)
                rowY = rowY + 87
            else
                row:SetHeight(66)
                row.dateHeader:Hide()
                row.kindIcon:ClearAllPoints()
                row.kindIcon:SetPoint("LEFT", row, "LEFT", 6, 0)
                row.titleText:ClearAllPoints()
                row.titleText:SetPoint("TOPLEFT", row, "TOPLEFT", 30, -5)
                row.titleText:SetHeight(30)
                row.metaText:ClearAllPoints()
                row.metaText:SetPoint("TOPLEFT", row, "TOPLEFT", 30, -35)
                row.previewText:ClearAllPoints()
                row.previewText:SetPoint("TOPLEFT", row, "TOPLEFT", 30, -50)
                rowY = rowY + 69
            end
            if unread then row.unreadBar:Show() else row.unreadBar:Hide() end
            UI:SetSelected(row, owner.ui.homeSelectedPostId == record.id)
            row:Show()
        else
            row.otlRecordId = nil row.badgeText:SetText("") row.previewText:SetText("") row.dateHeader:Hide() row.unreadBar:Hide() row:Hide()
        end
    end
    owner.ui.homePostList.empty:SetText(showArchived and "No archived guild posts." or "No active guild posts.")
    if table.getn(list) == 0 then owner.ui.homePostList.empty:Show() else owner.ui.homePostList.empty:Hide() end

    local selected = owner.ui.homeSelectedPostId and owner:GetAnnouncement152(owner.ui.homeSelectedPostId) or nil
    if selected and (selected.archived and true or false) ~= showArchived then selected = nil end
    if not selected and list[1] then selected = list[1] owner.ui.homeSelectedPostId = selected.id end
    local details = owner.ui.homePostDetails
    if not selected then
        details.otlRecordId = nil
        details.postTitle:SetText("")
        details.meta:SetText("")
        details.body:SetText("")
        details.empty:Show()
        details.like:Hide() details.seen:Hide() details.support:Hide() details.readers:Hide()
        details.likeCount:Hide() details.seenCount:Hide() details.supportCount:Hide()
        details.edit:Hide() details.archive:Hide() details.delete:Hide()
        return
    end
    details.empty:Hide()
    details.otlRecordId = selected.id
    local importance = selected.importance == "CRITICAL" and "URGENT" or (selected.importance == "IMPORTANT" and "IMPORTANT" or "GUILD POST")
    details.postTitle:SetText(importance .. "  " .. tostring(selected.title or "Guild Post"))
    local dateMeta = "Published " .. owner:Stamp(selected.createdAt)
    if selected.archived and tonumber(selected.archivedAt) then dateMeta = dateMeta .. "  |  Archived " .. owner:Stamp(selected.archivedAt) end
    details.meta:SetText("By " .. tostring(selected.author or "Leadership") .. "  |  " .. dateMeta .. (selected.pinned and "  |  Pinned" or ""))
    local fullBody = tostring(selected.body or "")
    details.body:SetText(fullBody)
    local detailsHeight = details:GetHeight()
    local visibleHeight = math.max(120, detailsHeight - 226)
    local measured = MeasurePostBodyHeight180(details, fullBody)
    local childHeight = math.max(visibleHeight, measured)
    details.bodyScroll:SetHeight(visibleHeight)
    details.scrollbar:SetHeight(visibleHeight)
    details.body:SetHeight(childHeight)
    details.bodyChild:SetHeight(childHeight)
    local maximum = math.max(0, childHeight - visibleHeight)
    details.scrollbar.otlSilent = true
    details.scrollbar:SetMinMaxValues(0, maximum)
    local storedOffset = owner.ui.homePostBodyOffsets180 and tonumber(owner.ui.homePostBodyOffsets180[selected.id]) or 0
    storedOffset = math.max(0, math.min(maximum, storedOffset))
    details.scrollbar:SetValue(storedOffset)
    details.scrollbar.otlSilent = nil
    details.bodyScroll:SetVerticalScroll(storedOffset)
    if maximum > 0 then details.scrollbar:Show() else details.scrollbar:Hide() end
    local summary = owner:GetAnnouncementReactionSummary152(selected.id) or {}
    details.like:ClearAllPoints()
    details.like:SetPoint("BOTTOMLEFT", details, "BOTTOMLEFT", 14, 72)
    details.like:SetWidth(62)
    UI:SetText(details.like, "Like")
    details.likeCount:ClearAllPoints()
    details.likeCount:SetPoint("LEFT", details.like, "RIGHT", 4, 0)
    UI:SetText(details.likeCount, tostring(summary.LIKE or 0))
    details.seen:ClearAllPoints()
    details.seen:SetPoint("LEFT", details.likeCount, "RIGHT", 8, 0)
    details.seen:SetWidth(selected.requiresAck and 92 or 62)
    UI:SetText(details.seen, selected.requiresAck and "Acknowledge" or "Seen")
    details.seenCount:ClearAllPoints()
    details.seenCount:SetPoint("LEFT", details.seen, "RIGHT", 4, 0)
    UI:SetText(details.seenCount, tostring(summary.SEEN or 0))
    details.support:ClearAllPoints()
    details.support:SetPoint("LEFT", details.seenCount, "RIGHT", 8, 0)
    details.support:SetWidth(70)
    UI:SetText(details.support, "Support")
    details.supportCount:ClearAllPoints()
    details.supportCount:SetPoint("LEFT", details.support, "RIGHT", 4, 0)
    UI:SetText(details.supportCount, tostring(summary.SUPPORT or 0))
    local likeNames = owner.GetCommunityReactors and owner:GetCommunityReactors("ANN", selected.id, "LIKE") or {}
    local seenNames = owner.GetCommunityReactors and owner:GetCommunityReactors("ANN", selected.id, "SEEN") or {}
    local supportNames = owner.GetCommunityReactors and owner:GetCommunityReactors("ANN", selected.id, "SUPPORT") or {}
    details.like.otlTooltip = table.getn(likeNames) > 0 and table.concat(likeNames, ", ") or "No likes yet."
    details.seen.otlTooltip = table.getn(seenNames) > 0 and table.concat(seenNames, ", ") or "No seen reactions yet."
    details.support.otlTooltip = table.getn(supportNames) > 0 and table.concat(supportNames, ", ") or "No support reactions yet."
    details.like:Show() details.likeCount:Show()
    details.seen:Show() details.seenCount:Show()
    details.support:Show() details.supportCount:Show()
    if canPublish then
        local readers = owner.GetAnnouncementReaders172 and owner:GetAnnouncementReaders172(selected.id) or {}
        UI:SetText(details.readers, tostring(table.getn(readers)) .. " read")
        UI:SetText(details.archive, selected.archived and "Restore" or "Archive")
        details.readers:ClearAllPoints()
        details.readers:SetPoint("LEFT", details.supportCount, "RIGHT", 8, 0)
        details.edit:ClearAllPoints()
        details.edit:SetPoint("BOTTOMLEFT", details, "BOTTOMLEFT", 14, 34)
        details.readers:Show() details.edit:Show() details.archive:Show() details.delete:Show()
    else
        details.readers:Hide() details.edit:Hide() details.archive:Hide() details.delete:Hide()
    end
end

function OTLGM:RefreshHomePage()
    if self.CanRefreshShellPage180 and not self:CanRefreshShellPage180("home") then return false end
    if not self.ui or not self.ui.homeOverviewPanel then return end
    local tab = self.ui.homeShellTab == "POSTS" and "POSTS" or "OVERVIEW"
    if tab == "OVERVIEW" then self.ui.homeOverviewPanel:Show() self.ui.homePostsPanel:Hide()
    else self.ui.homeOverviewPanel:Hide() self.ui.homePostsPanel:Show() end
    UI:SetSelected(self.ui.homeOverviewTab, tab == "OVERVIEW")
    UI:SetSelected(self.ui.homePostsTab, tab == "POSTS")
    if tab == "OVERVIEW" then RefreshOverview(self) else RefreshPosts(self) end
end

local function LayoutHome(owner, page, width, height)
    -- First-open geometry must be based on actual leadership data, not on the
    -- pre-bind visibility of hidden row frames.
    local leadershipData = CollectHomeLeadership180(owner)
    local leadershipCard = owner.ui and owner.ui.homeLeadershipCard
    if leadershipCard then
        leadershipCard.otlLeadershipData180 = leadershipData
        leadershipCard.otlHasGuildLeader180 = leadershipData.guildLeader and true or false
        leadershipCard.otlHasMainRaidLeader180 = leadershipData.mainRaidLeader and true or false
    end
    local panelHeight = math.max(420, height - 40)
    local gap = 10
    owner.ui.homeOverviewPanel:SetWidth(width)
    owner.ui.homeOverviewPanel:SetHeight(panelHeight)
    owner.ui.homePostsPanel:SetWidth(width)
    owner.ui.homePostsPanel:SetHeight(panelHeight)

    local activityHeight = math.max(100, math.min(125, math.floor(panelHeight * 0.22)))
    local mainHeight = panelHeight - activityHeight - gap
    local leftWidth = math.floor(width * 0.64)
    local rightWidth = width - leftWidth - gap
    local pinnedHeight = math.max(178, math.min(224, math.floor(mainHeight * 0.54)))
    local recentHeight = mainHeight - pinnedHeight - gap

    local pinned = owner.ui.homePinnedCard
    pinned:ClearAllPoints() pinned:SetPoint("TOPLEFT", owner.ui.homeOverviewPanel, "TOPLEFT", 0, 0)
    pinned:SetWidth(leftWidth) pinned:SetHeight(pinnedHeight)
    pinned.titleText:SetWidth(math.max(220, leftWidth - 210))
    pinned.badgeText:ClearAllPoints() pinned.badgeText:SetPoint("TOPRIGHT", pinned, "TOPRIGHT", -14, -35)
    pinned.badgeText:SetWidth(150)
    pinned.metaText:SetWidth(leftWidth - 72)
    pinned.bodyText:SetWidth(leftWidth - 28)
    pinned.bodyText:SetHeight(math.max(44, pinnedHeight - 148))

    local recent = owner.ui.homeRecentPostsCard
    recent:ClearAllPoints() recent:SetPoint("TOPLEFT", pinned, "BOTTOMLEFT", 0, -gap)
    recent:SetWidth(leftWidth) recent:SetHeight(recentHeight)
    local recentBodyHeight = math.max(62, recentHeight - 60)
    local recentRowHeight = math.max(50, math.floor(recentBodyHeight / 2))
    local index
    for index = 1, table.getn(recent.rows) do
        local row = recent.rows[index]
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", recent, "TOPLEFT", 12, -32 - ((index - 1) * recentRowHeight))
        row:SetWidth(leftWidth - 24) row:SetHeight(recentRowHeight - 4)
        row.titleText:SetWidth(math.max(160, leftWidth - 180))
        row.badgeText:ClearAllPoints() row.badgeText:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -8)
        row.badgeText:SetWidth(126)
        row.metaText:SetWidth(leftWidth - 64)
        row.previewText:SetWidth(leftWidth - 64)
    end
    recent.empty:SetWidth(leftWidth - 28)

    -- Reserve enough vertical room for GL, main raid leader and at least one
    -- compact officer/helper row on the normal Stage B window.  Raid/group
    -- cards remain readable but no longer consume fixed legacy proportions.
    local raidHeight = math.max(132, math.min(146, math.floor(mainHeight * 0.30)))
    local groupsHeight = math.max(76, math.min(94, math.floor(mainHeight * 0.19)))
    local leadershipHeight = math.max(110, mainHeight - raidHeight - groupsHeight - (gap * 2))
    local raid = owner.ui.homeRaidCard
    raid:ClearAllPoints() raid:SetPoint("TOPRIGHT", owner.ui.homeOverviewPanel, "TOPRIGHT", 0, 0)
    raid:SetWidth(rightWidth) raid:SetHeight(raidHeight)
    raid.titleText:SetWidth(rightWidth - 24) raid.dateText:SetWidth(rightWidth - 24)
    raid.leaderText:SetWidth(rightWidth - 24) raid.contactText:SetWidth(rightWidth - 24)
    raid.gatherText:SetWidth(rightWidth - 24)
    raid.meetingText:SetWidth(math.max(120, rightWidth - 120))
    raid.countdownText:SetWidth(math.max(120, rightWidth - 120))
    raid.empty:SetWidth(rightWidth - 24)

    local groups = owner.ui.homeGroupsCard
    groups:ClearAllPoints() groups:SetPoint("TOPRIGHT", raid, "BOTTOMRIGHT", 0, -gap)
    groups:SetWidth(rightWidth) groups:SetHeight(groupsHeight)
    local groupRowHeight = math.max(24, math.floor((groupsHeight - 34) / 3))
    for index = 1, table.getn(groups.rows) do
        local row = groups.rows[index]
        row:ClearAllPoints() row:SetPoint("TOPLEFT", groups, "TOPLEFT", 10, -30 - ((index - 1) * groupRowHeight))
        row:SetWidth(rightWidth - 20) row:SetHeight(groupRowHeight - 2)
        row.titleText:SetWidth(math.max(96, rightWidth - 162))
        row.leaderText:ClearAllPoints() row.leaderText:SetPoint("RIGHT", row.countText, "LEFT", -8, 0)
        row.leaderText:SetWidth(78)
        row.countText:ClearAllPoints() row.countText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    end
    groups.empty:SetWidth(rightWidth - 24)

    local leadership = owner.ui.homeLeadershipCard
    leadership:ClearAllPoints() leadership:SetPoint("TOPRIGHT", groups, "BOTTOMRIGHT", 0, -gap)
    leadership:SetWidth(rightWidth) leadership:SetHeight(leadershipHeight)
    local gl = leadership.guildLeader
    gl:SetWidth(rightWidth - 20)
    gl.nameText:SetWidth(math.max(90, rightWidth - 172))
    gl.roleText:ClearAllPoints() gl.roleText:SetPoint("TOPRIGHT", gl, "TOPRIGHT", -8, -8)
    gl.subtitleText:SetWidth(math.max(110, rightWidth - 138))
    gl:ClearAllPoints()
    gl:SetPoint("TOPLEFT", leadership, "TOPLEFT", 10, -31)
    local nextY = -31
    if leadership.otlHasGuildLeader180 then nextY = nextY - 60 end
    local rl = leadership.mainRaidLeader
    rl:ClearAllPoints()
    rl:SetPoint("TOPLEFT", leadership, "TOPLEFT", 10, nextY)
    rl:SetWidth(rightWidth - 20)
    rl.nameText:SetWidth(math.max(88, rightWidth - 184))
    rl.roleText:ClearAllPoints() rl.roleText:SetPoint("TOPRIGHT", rl, "TOPRIGHT", -8, -8)
    rl.subtitleText:SetWidth(math.max(100, rightWidth - 126))
    if leadership.otlHasMainRaidLeader180 then nextY = nextY - 48 end
    local regularStartY = nextY
    local availableForRegular = math.max(0, leadershipHeight + regularStartY - 8)
    local oneColumn = rightWidth < 326
    local regularWidth = oneColumn and math.max(118, rightWidth - 20) or math.max(118, math.floor((rightWidth - 30) / 2))
    local columns = oneColumn and 1 or 2
    local regularLines = math.max(0, math.floor(availableForRegular / 30))
    leadership.otlRegularColumns180 = columns
    leadership.otlRegularCapacity180 = math.min(4, regularLines * columns)
    for index = 1, table.getn(leadership.rows) do
        local row = leadership.rows[index]
        local column = math.mod(index - 1, columns)
        local line = math.floor((index - 1) / columns)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", leadership, "TOPLEFT", 10 + (column * (regularWidth + 8)), regularStartY - (line * 30))
        row:SetWidth(regularWidth) row:SetHeight(27)
        row.nameText:SetWidth(math.max(54, regularWidth - 82))
        row.rankText:ClearAllPoints() row.rankText:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row.rankText:SetWidth(50)
    end
    leadership.empty:SetWidth(rightWidth - 24)
    leadership.moreText:ClearAllPoints()
    leadership.moreText:SetPoint("BOTTOM", leadership, "BOTTOM", 0, 8)
    leadership.moreText:SetWidth(rightWidth - 24)

    local activity = owner.ui.homeActivityCard
    activity:ClearAllPoints() activity:SetPoint("BOTTOMLEFT", owner.ui.homeOverviewPanel, "BOTTOMLEFT", 0, 0)
    activity:SetWidth(width) activity:SetHeight(activityHeight)
    local activityRowHeight = math.max(22, math.floor((activityHeight - 34) / 3))
    for index = 1, table.getn(activity.rows) do
        local row = activity.rows[index]
        row:ClearAllPoints() row:SetPoint("TOPLEFT", activity, "TOPLEFT", 12, -30 - ((index - 1) * activityRowHeight))
        row:SetWidth(width - 24) row:SetHeight(activityRowHeight - 2)
        row.titleText:SetWidth(width - 166)
    end
    activity.empty:SetWidth(width - 28)
    ApplyHomeBottomLayout180(owner)

    local listWidth = math.max(310, math.floor(width * 0.36))
    local detailsWidth = width - listWidth - 12
    owner.ui.homePostList:SetWidth(listWidth)
    owner.ui.homePostList:SetHeight(panelHeight)
    owner.ui.homePostList.counter:SetWidth(listWidth - 24)
    owner.ui.homePostList.empty:SetWidth(listWidth - 24)
    owner.ui.homePostList.scrollbar:SetHeight(math.max(120, panelHeight - 138))
    for index = 1, table.getn(owner.ui.homePostList.rows) do
        local row = owner.ui.homePostList.rows[index]
        row:SetWidth(listWidth - 40)
        row.titleText:SetWidth(math.max(112, listWidth - 144))
        row.titleText:SetHeight(30)
        row.badgeText:ClearAllPoints()
        row.badgeText:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -6)
        row.badgeText:SetWidth(92)
        row.metaText:SetWidth(listWidth - 72)
        row.previewText:SetWidth(listWidth - 72)
    end
    owner.ui.homePostDetails:ClearAllPoints()
    owner.ui.homePostDetails:SetPoint("TOPRIGHT", owner.ui.homePostsPanel, "TOPRIGHT", 0, 0)
    owner.ui.homePostDetails:SetWidth(detailsWidth)
    owner.ui.homePostDetails:SetHeight(panelHeight)
    owner.ui.homePostDetails.postTitle:SetWidth(detailsWidth - 28)
    owner.ui.homePostDetails.meta:SetWidth(detailsWidth - 28)
    owner.ui.homePostDetails.bodyScroll:ClearAllPoints()
    owner.ui.homePostDetails.bodyScroll:SetPoint("TOPLEFT", owner.ui.homePostDetails, "TOPLEFT", 14, -108)
    owner.ui.homePostDetails.bodyScroll:SetWidth(detailsWidth - 48)
    owner.ui.homePostDetails.bodyChild:SetWidth(detailsWidth - 64)
    owner.ui.homePostDetails.body:SetWidth(detailsWidth - 70)
    if owner.ui.homePostDetails.bodyMeasure180 then owner.ui.homePostDetails.bodyMeasure180:SetWidth(detailsWidth - 70) end
    owner.ui.homePostDetails.scrollbar:ClearAllPoints()
    owner.ui.homePostDetails.scrollbar:SetPoint("TOPRIGHT", owner.ui.homePostDetails, "TOPRIGHT", -12, -108)
    owner.ui.homePostDetails.empty:SetWidth(math.max(260, detailsWidth - 54))
    page.otlNativeLayout = true
end

OTLGM:CreateShellPageModule180("home", BuildHome,
    function(owner) owner:RefreshHomePage() end,
    LayoutHome, { "overview", "guild-posts" }, { width = 760, height = 520 })

OTLGM:RegisterModule("HomePage180", {
    stage = "B",
    revision = 9,
    lazy = true,
    migrated = true,
    nativeContentHost = true,
    pageContract = true,
    noOnUpdate = true,
})
