-- Order of the Lion Guild Manager 1.8.3 r38
-- Guild Administration UX polish over the r37 server-backed controls.
-- Vanilla / OctoWoW / Lua 5.0 compatible. No OnUpdate and no registered events.

if not OTLGM or not OTLGM.UI then return end

local UI = OTLGM.UI
local C = UI.colors

local ADMIN_TABS185 = {
    { "GENERAL", "Message & Info", 124 },
    { "RANKS", "Ranks & Permissions", 154 },
    { "MEMBERS", "Members", 92 },
}

local RANK_PERMISSIONS185 = {
    { 1, "Guild chat: Listen", "Can read guild chat", "CHAT" },
    { 2, "Guild chat: Speak", "Can send messages to guild chat", "CHAT" },
    { 3, "Officer chat: Listen", "Can read officer chat", "CHAT" },
    { 4, "Officer chat: Speak", "Can send messages to officer chat", "CHAT" },
    { 5, "Promote members", "Can promote lower-ranked guild members", "MEMBERS" },
    { 6, "Demote members", "Can demote lower-ranked guild members", "MEMBERS" },
    { 7, "Invite members", "Can invite players to the guild", "MEMBERS" },
    { 8, "Remove members", "Can remove lower-ranked guild members", "MEMBERS" },
    { 9, "Set Guild MOTD", "Can change the guild Message of the Day", "GUILD" },
    { 10, "Edit public notes", "Can edit member public notes", "GUILD" },
    { 11, "View officer notes", "Can read member officer notes", "GUILD" },
    { 12, "Edit officer notes", "Can edit member officer notes", "GUILD" },
}

local function Label(parent, value, template, x, y, width, justify)
    local label = UI.Text(parent, value, template or "GameFontNormalSmall", justify or "LEFT")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then label:SetWidth(width) end
    return label
end

local function SafeBoolean185(fn)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn)
    if not ok then return nil end
    return value and true or false
end

local function GuildAdminCaps185(owner)
    local leader = owner.IsGuildLeader170 and owner:IsGuildLeader170() or false
    local flags = owner.GetGuildPermissionFlags170 and owner:GetGuildPermissionFlags170(true) or {}
    local motd = SafeBoolean185(CanEditMOTD)
    local info = SafeBoolean185(CanEditGuildInfo)
    local invite = SafeBoolean185(CanGuildInvite)
    if motd == nil then motd = leader or (flags and flags.setMotd) or false end
    if info == nil then info = leader or (flags and flags.modifyGuildInfo) or false end
    if invite == nil then invite = leader or (flags and flags.invite) or false end
    return {
        leader = leader,
        canMotd = motd and true or false,
        canInfo = info and true or false,
        canInvite = invite and true or false,
        canPromote = owner.CanPromoteMembers and owner:CanPromoteMembers() or false,
        canDemote = owner.CanDemoteMembers and owner:CanDemoteMembers() or false,
        canRemove = owner.CanRemoveMembers and owner:CanRemoveMembers() or false,
        canPublic = owner.CanEditPublicNotes and owner:CanEditPublicNotes() or false,
        canOfficer = owner.CanEditOfficerNotes and owner:CanEditOfficerNotes() or false,
        canViewOfficer = owner.CanViewOfficerNotes and owner:CanViewOfficerNotes() or false,
        rankRead = type(GuildControlGetNumRanks) == "function" and type(GuildControlGetRankName) == "function"
            and type(GuildControlSetRank) == "function" and type(GuildControlGetRankFlags) == "function",
        rankWrite = leader and type(GuildControlSetRankFlag) == "function" and type(GuildControlSaveRank) == "function",
        rankAdd = leader and type(GuildControlAddRank) == "function",
        rankDelete = leader and type(GuildControlDelRank) == "function",
    }
end

local function RankCount185()
    if type(GuildControlGetNumRanks) ~= "function" then return 0 end
    local ok, count = pcall(GuildControlGetNumRanks)
    if not ok then return 0 end
    count = tonumber(count) or 0
    if count < 0 then count = 0 end
    if count > 10 then count = 10 end
    return count
end

local function RankName185(order)
    if type(GuildControlGetRankName) ~= "function" then return "" end
    local ok, value = pcall(GuildControlGetRankName, order)
    if not ok then return "" end
    return tostring(value or "")
end

local function CopyFlags185(source)
    local copy = {}
    local index
    for index = 1, 12 do copy[index] = source and source[index] and true or false end
    return copy
end

local function ReadRank185(order)
    if type(GuildControlSetRank) ~= "function" or type(GuildControlGetRankFlags) ~= "function" then return nil, "Rank-control API is unavailable on this client." end
    local ok = pcall(GuildControlSetRank, order)
    if not ok then return nil, "The client could not select this guild rank." end
    local success, f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12 = pcall(GuildControlGetRankFlags)
    if not success then return nil, "The client could not read permissions for this rank." end
    return {
        name = RankName185(order),
        flags = {
            f1 and true or false, f2 and true or false, f3 and true or false, f4 and true or false,
            f5 and true or false, f6 and true or false, f7 and true or false, f8 and true or false,
            f9 and true or false, f10 and true or false, f11 and true or false, f12 and true or false,
        },
    }
end

local function BottomRankMembers185(owner, rankCount)
    local total = GetNumGuildMembers and (GetNumGuildMembers(true) or 0) or 0
    local targetIndex = math.max(0, (tonumber(rankCount) or 1) - 1)
    local count = 0
    local index
    for index = 1, total do
        local name, rank, rankIndex = GetGuildRosterInfo(index)
        if name and tonumber(rankIndex) == targetIndex then count = count + 1 end
    end
    return count
end

local function SetEditEnabled185(box, enabled)
    if not box then return end
    if box.EnableMouse then box:EnableMouse(enabled and true or false) end
    if enabled then
        if box.SetTextColor then box:SetTextColor(C.white[1], C.white[2], C.white[3]) end
    else
        if box.ClearFocus then box:ClearFocus() end
        if box.SetTextColor then box:SetTextColor(C.grey[1], C.grey[2], C.grey[3]) end
    end
end

local function SetStatus185(label, text, tone)
    if not label then return end
    label:SetText(tostring(text or ""))
    local color = C.grey
    if tone == "good" then color = C.green
    elseif tone == "warn" then color = C.orange
    elseif tone == "danger" then color = C.red
    elseif tone == "gold" then color = C.goldMuted
    elseif tone == "blue" then color = C.blue end
    label:SetTextColor(color[1], color[2], color[3])
end

local function RankDraftDirty185(draft)
    if not draft then return false end
    if tostring(draft.name or "") ~= tostring(draft.originalName or "") then return true end
    local index
    for index = 1, 12 do
        if (draft.flags[index] and true or false) ~= (draft.originalFlags[index] and true or false) then return true end
    end
    return false
end

local function UpdateTextDirty185(owner, card, canEdit, apiAvailable, label)
    if not card then return end
    local current = tostring(card.edit and card.edit:GetText() or "")
    local server = tostring(card.serverValue or "")
    card.dirty = current ~= server
    if not canEdit then
        SetStatus185(card.state, "Read only", "gold")
    elseif card.externalChange then
        SetStatus185(card.state, "Server changed • review before saving", "warn")
    elseif card.dirty then
        SetStatus185(card.state, "Unsaved changes", "warn")
    else
        SetStatus185(card.state, "Saved", "good")
    end
    UI:SetEnabled(card.save, canEdit and apiAvailable and card.dirty, not canEdit and ("Your guild rank cannot edit " .. label .. ".") or (not apiAvailable and "This guild API is unavailable on this client." or "No changes to save."))
    UI:SetEnabled(card.revert, canEdit and card.dirty, not canEdit and ("Your guild rank cannot edit " .. label .. ".") or "No changes to revert.")
end

local function UpdateRankDirty185(owner)
    if not owner.ui or not owner.ui.guildAdmin185 or not owner.ui.guildAdmin185.rankRight then return end
    local ui = owner.ui.guildAdmin185
    local right = ui.rankRight
    local caps = GuildAdminCaps185(owner)
    local dirty = RankDraftDirty185(ui.rankDraft)
    ui.rankDirty = dirty and true or nil
    if not ui.rankDraft then
        SetStatus185(right.changeState, "No rank loaded", nil)
    elseif not caps.rankWrite then
        SetStatus185(right.changeState, "Read only", "gold")
    elseif dirty then
        SetStatus185(right.changeState, "Unsaved changes", "warn")
    else
        SetStatus185(right.changeState, "Saved", "good")
    end
    UI:SetEnabled(right.save, caps.rankWrite and ui.rankDraft ~= nil and dirty, not caps.rankWrite and "Only the Guild Leader can change rank permissions." or (not ui.rankDraft and "No rank is loaded." or "No changes to save."))
    UI:SetEnabled(right.revert, caps.rankWrite and ui.rankDraft ~= nil and dirty, not caps.rankWrite and "Only the Guild Leader can change rank permissions." or (not ui.rankDraft and "No rank is loaded." or "No changes to revert."))
end

local function SetAdminTab185(owner, key)
    if not owner.ui or not owner.ui.guildAdmin185 then return end
    local ui = owner.ui.guildAdmin185
    ui.tab = key
    local index
    for index = 1, table.getn(ADMIN_TABS185) do
        local tabKey = ADMIN_TABS185[index][1]
        if ui.panels[tabKey] then if tabKey == key then ui.panels[tabKey]:Show() else ui.panels[tabKey]:Hide() end end
        if ui.tabs[tabKey] then UI:SetSelected(ui.tabs[tabKey], tabKey == key) end
    end
    if owner.RefreshGuildAdmin185 then owner:RefreshGuildAdmin185() end
end

local function SelectRank185(owner, order)
    if not owner.ui or not owner.ui.guildAdmin185 then return end
    local ui = owner.ui.guildAdmin185
    order = tonumber(order) or 1
    if order == tonumber(ui.rankSelected) then return end
    local function apply()
        ui.rankSelected = order
        ui.rankDraft = nil
        ui.rankDirty = nil
        owner:RefreshGuildAdmin185()
    end
    if RankDraftDirty185(ui.rankDraft) then
        owner:ShowConfirm("Discard Rank Changes?", "This rank has unsaved changes. Switch ranks and discard them?", "Discard Changes", apply)
    else
        apply()
    end
end

local function BuildGeneral185(owner, panel)
    local ui = owner.ui.guildAdmin185
    local motd = UI:Card(panel, 932, 148, "Guild Message of the Day")
    motd:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    motd.help = Label(motd, "Short message shown to guild members when they log in.", "GameFontNormalSmall", 16, -39, 650, "LEFT")
    motd.help:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    motd.edit = UI:EditBox(motd, 720, 32, { maxLetters = 128, placeholder = "Guild message of the day..." })
    motd.edit:SetPoint("TOPLEFT", motd, "TOPLEFT", 16, -65)
    motd.count = Label(motd, "0 / 128", "GameFontNormalSmall", 16, -112, 90, "LEFT")
    motd.count:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    motd.state = Label(motd, "Saved", "GameFontNormalSmall", 106, -112, 260, "LEFT")
    motd.revert = UI:Button(motd, "Revert", 88, 28, function()
        if motd.serverValue == nil then return end
        motd.externalChange = nil
        motd.edit:SetText(tostring(motd.serverValue or ""))
        UpdateTextDirty185(owner, motd, GuildAdminCaps185(owner).canMotd, type(GuildSetMOTD) == "function", "the MOTD")
    end, "utility")
    motd.revert:SetPoint("BOTTOMRIGHT", motd, "BOTTOMRIGHT", -174, 12)
    motd.save = UI:Button(motd, "Save MOTD", 150, 28, function()
        local caps = GuildAdminCaps185(owner)
        if not caps.canMotd then owner:ShowToast("Your guild rank cannot edit the MOTD.", "error") return end
        if type(GuildSetMOTD) ~= "function" then owner:ShowToast("GuildSetMOTD is unavailable on this client.", "error") return end
        local value = owner:SafeText(motd.edit:GetText() or "", 128, false, false)
        local ok = pcall(GuildSetMOTD, value)
        if not ok then owner:ShowToast("The game client rejected the MOTD change.", "error") return end
        motd.serverValue = value
        motd.externalChange = nil
        UpdateTextDirty185(owner, motd, true, true, "the MOTD")
        owner:ShowToast("Guild MOTD saved.", "success")
        if owner.RefreshGuildInfoPage then owner:RefreshGuildInfoPage() end
    end, "primary")
    motd.save:SetPoint("BOTTOMRIGHT", motd, "BOTTOMRIGHT", -16, 12)
    motd.edit.otlChanged = function(value)
        if ui.loading then return end
        motd.count:SetText(tostring(string.len(value or "")) .. " / 128")
        local caps = GuildAdminCaps185(owner)
        UpdateTextDirty185(owner, motd, caps.canMotd, type(GuildSetMOTD) == "function", "the MOTD")
    end

    local info = UI:Card(panel, 932, 340, "Guild Information")
    info:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -160)
    info.help = Label(info, "Long-form guild information and rules from the classic Guild window.", "GameFontNormalSmall", 16, -39, 800, "LEFT")
    info.help:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    info.edit = UI:EditBox(info, 900, 220, { multiline = true, maxLetters = 500, placeholder = "Guild information..." })
    info.edit:SetPoint("TOPLEFT", info, "TOPLEFT", 16, -65)
    info.count = Label(info, "0 / 500", "GameFontNormalSmall", 16, -300, 90, "LEFT")
    info.count:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    info.state = Label(info, "Saved", "GameFontNormalSmall", 106, -300, 280, "LEFT")
    info.revert = UI:Button(info, "Revert", 88, 28, function()
        if info.serverValue == nil then return end
        info.externalChange = nil
        info.edit:SetText(tostring(info.serverValue or ""))
        UpdateTextDirty185(owner, info, GuildAdminCaps185(owner).canInfo, type(SetGuildInfoText) == "function", "Guild Information")
    end, "utility")
    info.revert:SetPoint("BOTTOMRIGHT", info, "BOTTOMRIGHT", -188, 12)
    info.save = UI:Button(info, "Save Guild Info", 164, 28, function()
        local caps = GuildAdminCaps185(owner)
        if not caps.canInfo then owner:ShowToast("Your guild rank cannot edit Guild Information.", "error") return end
        if type(SetGuildInfoText) ~= "function" then owner:ShowToast("SetGuildInfoText is unavailable on this client.", "error") return end
        local value = owner:SafeText(info.edit:GetText() or "", 500, true, false)
        local ok = pcall(SetGuildInfoText, value)
        if not ok then owner:ShowToast("The game client rejected the Guild Information change.", "error") return end
        if type(GuildRoster) == "function" then pcall(GuildRoster) end
        info.serverValue = value
        info.externalChange = nil
        UpdateTextDirty185(owner, info, true, true, "Guild Information")
        owner:ShowToast("Guild Information saved.", "success")
        if owner.RefreshGuildInfoPage then owner:RefreshGuildInfoPage() end
    end, "primary")
    info.save:SetPoint("BOTTOMRIGHT", info, "BOTTOMRIGHT", -16, 12)
    info.edit.otlChanged = function(value)
        if ui.loading then return end
        info.count:SetText(tostring(string.len(value or "")) .. " / 500")
        local caps = GuildAdminCaps185(owner)
        UpdateTextDirty185(owner, info, caps.canInfo, type(SetGuildInfoText) == "function", "Guild Information")
    end

    ui.motd = motd
    ui.info = info
end

local function CreatePermissionGroup185(right, title, y)
    local group = UI:Surface(right, "raised", 650, 88)
    group:SetPoint("TOPLEFT", right, "TOPLEFT", 16, y)
    group.title = Label(group, title, "GameFontNormalSmall", 10, -10, 610, "LEFT")
    group.title:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    return group
end

local function BuildRanks185(owner, panel)
    local ui = owner.ui.guildAdmin185
    local left = UI:Card(panel, 232, 500, "Guild Ranks")
    left:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    left.summary = Label(left, "Live server hierarchy", "GameFontNormalSmall", 16, -39, 200, "LEFT")
    left.summary:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    left.rows = {}
    local index
    for index = 1, 10 do
        local captured = index
        local row = UI:Button(left, "", 200, 28, function() SelectRank185(owner, captured) end, "nav")
        row:SetPoint("TOPLEFT", left, "TOPLEFT", 16, -60 - ((index - 1) * 31))
        row:Hide()
        left.rows[index] = row
    end
    left.addLabel = Label(left, "ADD LOWER RANK", "GameFontNormalSmall", 16, -386, 190, "LEFT")
    left.addLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    left.newEdit = UI:EditBox(left, 124, 28, { maxLetters = 15, placeholder = "New rank..." })
    left.newEdit:SetPoint("TOPLEFT", left, "TOPLEFT", 16, -410)
    left.add = UI:Button(left, "Add", 68, 28, function()
        local caps = GuildAdminCaps185(owner)
        if not caps.rankAdd then owner:ShowToast("Only the Guild Leader can add ranks.", "error") return end
        local count = RankCount185()
        if count >= 10 then owner:ShowToast("Vanilla guilds support at most 10 ranks.", "error") return end
        local name = owner:SafeText(left.newEdit:GetText() or "", 15, false, false)
        if name == "" then owner:ShowToast("Enter a rank name first.", "error") return end
        local function performAdd()
            local ok = pcall(GuildControlAddRank, name)
            if not ok then owner:ShowToast("The client rejected the new rank.", "error") return end
            left.newEdit:SetText("")
            ui.rankSelected = math.min(10, count + 1)
            ui.rankDraft = nil
            ui.rankDirty = nil
            if type(GuildRoster) == "function" then pcall(GuildRoster) end
            owner:ShowToast("Rank added at the bottom of the guild hierarchy.", "success")
            owner:RefreshGuildAdmin185()
        end
        if RankDraftDirty185(ui.rankDraft) then
            owner:ShowConfirm("Discard Rank Changes?", "The selected rank has unsaved changes. Add the new rank and discard them?", "Discard & Add", performAdd)
        else
            performAdd()
        end
    end, "primary")
    left.add:SetPoint("TOPRIGHT", left, "TOPRIGHT", -16, -410)

    local right = UI:Card(panel, 688, 500, "Selected Rank")
    right:SetPoint("TOPLEFT", panel, "TOPLEFT", 244, 0)
    right.state = Label(right, "Select a rank.", "GameFontNormalSmall", 16, -39, 430, "LEFT")
    right.state:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    right.changeState = Label(right, "Saved", "GameFontNormalSmall", 470, -39, 180, "RIGHT")
    right.nameLabel = Label(right, "Rank name", "GameFontNormalSmall", 16, -70, 80, "LEFT")
    right.nameEdit = UI:EditBox(right, 220, 30, { maxLetters = 15, placeholder = "Rank name" })
    right.nameEdit:SetPoint("TOPLEFT", right, "TOPLEFT", 96, -62)
    right.nameEdit.otlChanged = function(value)
        if ui.loading or not ui.rankDraft then return end
        ui.rankDraft.name = tostring(value or "")
        UpdateRankDirty185(owner)
    end

    right.groups = {
        CHAT = CreatePermissionGroup185(right, "CHAT", -106),
        MEMBERS = CreatePermissionGroup185(right, "MEMBER ACTIONS", -202),
        GUILD = CreatePermissionGroup185(right, "GUILD SETTINGS / NOTES", -298),
    }
    right.checks = {}
    local groupSlots = { CHAT = 0, MEMBERS = 0, GUILD = 0 }
    for index = 1, table.getn(RANK_PERMISSIONS185) do
        local definition = RANK_PERMISSIONS185[index]
        local capturedIndex = definition[1]
        local groupKey = definition[4]
        groupSlots[groupKey] = (groupSlots[groupKey] or 0) + 1
        local slot = groupSlots[groupKey]
        local row = math.floor((slot - 1) / 2)
        local col = math.mod(slot - 1, 2)
        local group = right.groups[groupKey]
        local check = UI:Check(group, definition[2], 300, function(value)
            if ui.loading or not ui.rankDraft then return end
            ui.rankDraft.flags[capturedIndex] = value and true or false
            UpdateRankDirty185(owner)
        end)
        check:SetPoint("TOPLEFT", group, "TOPLEFT", 10 + (col * 318), -31 - (row * 30))
        check.otlTooltipTitle = definition[2]
        check.otlTooltip = definition[3]
        check.otlGroupKey185 = groupKey
        check.otlSlot185 = slot
        right.checks[capturedIndex] = check
    end

    right.readOnly = Label(right, "", "GameFontNormalSmall", 16, -397, 650, "LEFT")
    right.readOnly:SetHeight(32)
    right.readOnly:SetJustifyV("TOP")
    right.delete = UI:Button(right, "Delete Lowest Rank", 158, 30, function()
        local caps = GuildAdminCaps185(owner)
        local count = RankCount185()
        local selected = tonumber(ui.rankSelected) or 1
        if not caps.rankDelete then owner:ShowToast("Only the Guild Leader can delete ranks.", "error") return end
        if selected ~= count then owner:ShowToast("Vanilla only allows deleting the lowest rank.", "error") return end
        if count <= 5 then owner:ShowToast("Vanilla keeps at least five guild ranks.", "error") return end
        local members = BottomRankMembers185(owner, count)
        if members > 0 then owner:ShowToast("Move " .. tostring(members) .. " member(s) out of the lowest rank first.", "error") return end
        local name = RankName185(selected)
        owner:ShowConfirm("Delete Lowest Rank?", "Delete the empty lowest guild rank \"" .. tostring(name) .. "\"? This changes the real guild rank structure.", "Delete Rank", function()
            local ok = pcall(GuildControlDelRank, name)
            if not ok then owner:ShowToast("The client rejected the rank deletion.", "error") return end
            ui.rankSelected = math.max(1, selected - 1)
            ui.rankDraft = nil
            ui.rankDirty = nil
            if type(GuildRoster) == "function" then pcall(GuildRoster) end
            owner:ShowToast("Lowest guild rank deleted.", "success")
            owner:RefreshGuildAdmin185()
        end)
    end, "danger")
    right.delete:SetPoint("BOTTOMLEFT", right, "BOTTOMLEFT", 16, 16)
    right.revert = UI:Button(right, "Revert", 88, 30, function()
        if not ui.rankDraft then return end
        ui.rankDraft.name = tostring(ui.rankDraft.originalName or "")
        ui.rankDraft.flags = CopyFlags185(ui.rankDraft.originalFlags)
        owner:RefreshGuildAdmin185()
    end, "utility")
    right.revert:SetPoint("BOTTOMRIGHT", right, "BOTTOMRIGHT", -198, 16)
    right.save = UI:Button(right, "Save Changes", 174, 30, function()
        local caps = GuildAdminCaps185(owner)
        if not caps.rankWrite then owner:ShowToast("Only the Guild Leader can change rank permissions.", "error") return end
        local selected = tonumber(ui.rankSelected) or 1
        local draft = ui.rankDraft
        if not draft then owner:ShowToast("No rank is loaded.", "error") return end
        local name = owner:SafeText(draft.name or "", 15, false, false)
        if name == "" then owner:ShowToast("Rank name cannot be empty.", "error") return end
        local ok = pcall(GuildControlSetRank, selected)
        if not ok then owner:ShowToast("The client could not select this guild rank.", "error") return end
        for index = 1, 12 do
            ok = pcall(GuildControlSetRankFlag, index, draft.flags[index] and true or false)
            if not ok then owner:ShowToast("The client rejected permission " .. tostring(index) .. ". Nothing was saved.", "error") ui.rankDraft = nil owner:RefreshGuildAdmin185() return end
        end
        ok = pcall(GuildControlSaveRank, name)
        if not ok then owner:ShowToast("The client rejected the rank save.", "error") ui.rankDraft = nil owner:RefreshGuildAdmin185() return end
        if type(GuildRoster) == "function" then pcall(GuildRoster) end
        draft.originalName = name
        draft.originalFlags = CopyFlags185(draft.flags)
        ui.rankDirty = nil
        owner:ShowToast("Guild rank permissions saved.", "success")
        owner:RefreshGuildAdmin185()
    end, "primary")
    right.save:SetPoint("BOTTOMRIGHT", right, "BOTTOMRIGHT", -16, 16)
    ui.rankLeft = left
    ui.rankRight = right
end

function OTLGM:OpenClassicGuildWindow185()
    if not FriendsFrame or not GuildFrame then
        self:ShowToast("The classic Guild window is unavailable on this client.", "error")
        return false
    end
    self.runtime = self.runtime or {}
    self.runtime.allowNativeGuildOnce185 = true
    if self.ui and self.ui.main and self.ui.main.IsShown and self.ui.main:IsShown() then
        self.runtime.suppressQuickDockOnMainHide183 = true
        self.ui.main:Hide()
        self.runtime.suppressQuickDockOnMainHide183 = nil
    end
    if PanelTemplates_SetTab then pcall(PanelTemplates_SetTab, FriendsFrame, 3) end
    FriendsFrame.selectedTab = 3
    local shown = false
    if ShowUIPanel then
        local ok = pcall(ShowUIPanel, FriendsFrame)
        shown = ok and true or false
    elseif FriendsFrame.Show then
        local ok = pcall(FriendsFrame.Show, FriendsFrame)
        shown = ok and true or false
    end
    if shown and FriendsFrame_Update then pcall(FriendsFrame_Update) end
    self.runtime.allowNativeGuildOnce185 = nil
    if not shown then
        self:ShowToast("The classic Guild window could not be opened.", "error")
        return false
    end
    return true
end

local function BuildMembers185(owner, panel)
    local ui = owner.ui.guildAdmin185
    local invite = UI:Card(panel, 932, 132, "Invite a Member")
    invite:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    invite.help = Label(invite, "Send a normal guild invitation. Your live rank permission still applies.", "GameFontNormalSmall", 16, -39, 720, "LEFT")
    invite.help:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    invite.edit = UI:EditBox(invite, 430, 30, { maxLetters = 48, placeholder = "Character name..." })
    invite.edit:SetPoint("TOPLEFT", invite, "TOPLEFT", 16, -70)
    invite.send = UI:Button(invite, "Invite to Guild", 152, 30, function()
        local caps = GuildAdminCaps185(owner)
        if not caps.canInvite then owner:ShowToast("Your guild rank cannot invite members.", "error") return end
        if type(GuildInviteByName) ~= "function" then owner:ShowToast("GuildInviteByName is unavailable on this client.", "error") return end
        local name = owner:SafeText(invite.edit:GetText() or "", 48, false, false)
        if name == "" then owner:ShowToast("Enter a character name first.", "error") return end
        local ok = pcall(GuildInviteByName, name)
        if not ok then owner:ShowToast("The game client rejected the guild invite.", "error") return end
        owner:ShowToast("Guild invite sent to " .. tostring(name) .. ".", "success")
        invite.edit:SetText("")
    end, "primary")
    invite.send:SetPoint("LEFT", invite.edit, "RIGHT", 10, 0)

    local management = UI:Card(panel, 932, 356, "Member Management")
    management:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -144)
    management.intro = Label(management, "Promotions, notes and removals stay in Roster so the selected member, history and Main / Alt context remain visible while you act.", "GameFontNormalSmall", 16, -39, 860, "LEFT")
    management.intro:SetHeight(36)
    management.intro:SetJustifyV("TOP")
    management.intro:SetTextColor(C.grey[1], C.grey[2], C.grey[3])

    management.rosterBox = UI:Surface(management, "raised", 520, 210)
    management.rosterBox:SetPoint("TOPLEFT", management, "TOPLEFT", 16, -88)
    management.rosterTitle = Label(management.rosterBox, "ROSTER MANAGEMENT", "GameFontNormalSmall", 12, -12, 470, "LEFT")
    management.rosterTitle:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    management.list = Label(management.rosterBox,
        "Promote / Demote\nRemove from guild (with confirmation)\nPublic and Officer notes\nWhisper / Invite / Guild Profile\nMain / Alt context\nOffline and inactivity history",
        "GameFontHighlightSmall", 16, -42, 470, "LEFT")
    management.list:SetHeight(146)
    management.list:SetJustifyV("TOP")

    management.accessBox = UI:Surface(management, "raised", 356, 210)
    management.accessBox:SetPoint("TOPRIGHT", management, "TOPRIGHT", -16, -88)
    management.accessTitle = Label(management.accessBox, "YOUR LIVE ACCESS", "GameFontNormalSmall", 12, -12, 320, "LEFT")
    management.accessTitle:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    management.permissions = Label(management.accessBox, "", "GameFontNormalSmall", 16, -42, 320, "LEFT")
    management.permissions:SetHeight(146)
    management.permissions:SetJustifyV("TOP")

    management.classic = UI:Button(management, "Open Classic Guild", 172, 30, function() owner:OpenClassicGuildWindow185() end, "utility")
    management.classic:SetPoint("BOTTOMLEFT", management, "BOTTOMLEFT", 16, 16)
    management.classic.otlTooltipTitle = "Classic Guild Window"
    management.classic.otlTooltip = "Fallback to Blizzard's original Guild panel for any rare server-specific action that is not exposed here."
    management.open = UI:Button(management, "Open Roster", 160, 30, function() owner:ShowPage("roster") end, "primary")
    management.open:SetPoint("BOTTOMRIGHT", management, "BOTTOMRIGHT", -16, 16)
    ui.invite = invite
    ui.memberManagement = management
end

local function BuildGuildAdmin185(owner, page)
    owner.ui.guildAdmin185 = owner.ui.guildAdmin185 or {}
    local ui = owner.ui.guildAdmin185
    ui.tabs = {}
    ui.panels = {}
    ui.tab = ui.tab or "GENERAL"

    local help = UI:HelpIcon(page, "Guild Administration", "Server-backed guild controls. Changes here affect the real guild. Message & Info covers MOTD and Guild Information, Ranks & Permissions manages the Vanilla rank matrix, and Members links to the existing Roster workflow. Classic Guild remains available as a fallback for rare server-specific actions.")
    help:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -4)
    ui.help = help
    ui.scope = UI.Text(page, "LIVE GUILD CONTROLS", "GameFontNormalSmall", "RIGHT")
    ui.scope:SetPoint("RIGHT", help, "LEFT", -10, 0)
    ui.scope:SetWidth(270)
    ui.scope:SetTextColor(C.grey[1], C.grey[2], C.grey[3])

    local x = 0
    local index
    for index = 1, table.getn(ADMIN_TABS185) do
        local definition = ADMIN_TABS185[index]
        local key = definition[1]
        local captured = key
        local button = UI:Tab(page, definition[2], definition[3], function() SetAdminTab185(owner, captured) end)
        button:SetPoint("TOPLEFT", page, "TOPLEFT", x, 0)
        ui.tabs[key] = button
        x = x + definition[3] + 8
    end

    local general = UI:Surface(page, "surface", 932, 500)
    general:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -42)
    local ranks = UI:Surface(page, "surface", 932, 500)
    ranks:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -42)
    local members = UI:Surface(page, "surface", 932, 500)
    members:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -42)
    ui.panels.GENERAL = general
    ui.panels.RANKS = ranks
    ui.panels.MEMBERS = members

    BuildGeneral185(owner, general)
    BuildRanks185(owner, ranks)
    BuildMembers185(owner, members)
    SetAdminTab185(owner, ui.tab)
end

function OTLGM:RefreshGuildAdmin185()
    if not self.ui or not self.ui.guildAdmin185 then return end
    local ui = self.ui.guildAdmin185
    ui.loading = true
    local caps = GuildAdminCaps185(self)

    if ui.scope then
        local guildName, rankName = GetGuildInfo and GetGuildInfo("player") or nil, nil
        if GetGuildInfo then guildName, rankName = GetGuildInfo("player") end
        local role = caps.leader and "Guild Leader" or tostring(rankName or "Officer")
        SetStatus185(ui.scope, "LIVE GUILD • " .. role, caps.leader and "gold" or "blue")
    end

    if ui.motd then
        local live = type(GetGuildRosterMOTD) == "function" and tostring(GetGuildRosterMOTD() or "") or ""
        if ui.motd.serverValue == nil then
            ui.motd.serverValue = live
            ui.motd.edit:SetText(live)
        elseif ui.motd.dirty then
            if live ~= tostring(ui.motd.serverValue or "") then ui.motd.externalChange = true ui.motd.serverValue = live end
        else
            ui.motd.serverValue = live
            ui.motd.externalChange = nil
            ui.motd.edit:SetText(live)
        end
        ui.motd.count:SetText(tostring(string.len(tostring(ui.motd.edit:GetText() or ""))) .. " / 128")
        SetEditEnabled185(ui.motd.edit, caps.canMotd)
        UpdateTextDirty185(self, ui.motd, caps.canMotd, type(GuildSetMOTD) == "function", "the MOTD")
    end
    if ui.info then
        local live = type(GetGuildInfoText) == "function" and tostring(GetGuildInfoText() or "") or ""
        if ui.info.serverValue == nil then
            ui.info.serverValue = live
            ui.info.edit:SetText(live)
        elseif ui.info.dirty then
            if live ~= tostring(ui.info.serverValue or "") then ui.info.externalChange = true ui.info.serverValue = live end
        else
            ui.info.serverValue = live
            ui.info.externalChange = nil
            ui.info.edit:SetText(live)
        end
        ui.info.count:SetText(tostring(string.len(tostring(ui.info.edit:GetText() or ""))) .. " / 500")
        SetEditEnabled185(ui.info.edit, caps.canInfo)
        UpdateTextDirty185(self, ui.info, caps.canInfo, type(SetGuildInfoText) == "function", "Guild Information")
    end

    if ui.rankLeft and ui.rankRight then
        local count = RankCount185()
        if ui.rankSelected == nil then ui.rankSelected = 1 end
        if ui.rankSelected > count then ui.rankSelected = math.max(1, count) end
        local index
        for index = 1, 10 do
            local row = ui.rankLeft.rows[index]
            if index <= count then
                UI:SetText(row, tostring(index) .. ".  " .. RankName185(index))
                UI:SetSelected(row, index == ui.rankSelected)
                row:Show()
            else row:Hide() end
        end
        ui.rankLeft.summary:SetText(count > 0 and (tostring(count) .. " / 10 ranks • live server") or "Rank list unavailable")
        UI:SetEnabled(ui.rankLeft.add, caps.rankAdd and count < 10, not caps.rankAdd and "Only the Guild Leader can add ranks." or "Vanilla guilds support at most 10 ranks.")
        SetEditEnabled185(ui.rankLeft.newEdit, caps.rankAdd and count < 10)

        if count > 0 and caps.rankRead then
            if not ui.rankDraft or tonumber(ui.rankDraft.order) ~= tonumber(ui.rankSelected) then
                local read, problem = ReadRank185(ui.rankSelected)
                if read then
                    ui.rankDraft = {
                        order = ui.rankSelected,
                        name = read.name,
                        flags = CopyFlags185(read.flags),
                        originalName = read.name,
                        originalFlags = CopyFlags185(read.flags),
                    }
                    ui.rankProblem = nil
                else
                    ui.rankProblem = problem
                    ui.rankDraft = nil
                end
            end
        else
            ui.rankDraft = nil
            ui.rankProblem = caps.rankRead and "No guild ranks were returned by the client." or "Rank-control API is unavailable on this client."
        end

        local draft = ui.rankDraft
        if draft then
            ui.rankRight.state:SetText((caps.rankWrite and "Editing rank " or "Viewing rank ") .. tostring(ui.rankSelected) .. " of " .. tostring(count) .. " • " .. tostring(RankName185(ui.rankSelected)))
            ui.rankRight.nameEdit:SetText(draft.name or "")
            SetEditEnabled185(ui.rankRight.nameEdit, caps.rankWrite)
            for index = 1, 12 do
                local check = ui.rankRight.checks[index]
                if check then
                    UI:SetChecked(check, draft.flags[index] and true or false)
                    check:EnableMouse(caps.rankWrite and true or false)
                    if check.text then check.text:SetTextColor(caps.rankWrite and C.white[1] or C.grey[1], caps.rankWrite and C.white[2] or C.grey[2], caps.rankWrite and C.white[3] or C.grey[3]) end
                end
            end
            ui.rankRight.readOnly:SetText(caps.rankWrite and "Edit safely here. Nothing reaches the server until you press Save Changes." or "Permission matrix is read-only. Only the Guild Leader can change rank names or permissions.")
            ui.rankRight.readOnly:SetTextColor(caps.rankWrite and C.grey[1] or C.goldMuted[1], caps.rankWrite and C.grey[2] or C.goldMuted[2], caps.rankWrite and C.grey[3] or C.goldMuted[3])
        else
            ui.rankRight.state:SetText(ui.rankProblem or "Select a rank.")
            ui.rankRight.nameEdit:SetText("")
            SetEditEnabled185(ui.rankRight.nameEdit, false)
            for index = 1, 12 do
                local check = ui.rankRight.checks[index]
                if check then UI:SetChecked(check, false) check:EnableMouse(false) end
            end
            ui.rankRight.readOnly:SetText("No rank data is available to edit.")
        end
        UpdateRankDirty185(self)

        local bottomMembers = count > 0 and BottomRankMembers185(self, count) or 0
        local canDelete = caps.rankDelete and count > 5 and ui.rankSelected == count and bottomMembers == 0
        local deleteReason = "Only the Guild Leader can delete ranks."
        if caps.rankDelete then
            if count <= 5 then deleteReason = "Vanilla keeps at least five guild ranks."
            elseif ui.rankSelected ~= count then deleteReason = "Only the lowest guild rank can be deleted."
            elseif bottomMembers > 0 then deleteReason = "Move " .. tostring(bottomMembers) .. " member(s) out of the lowest rank first."
            else deleteReason = nil end
        end
        UI:SetEnabled(ui.rankRight.delete, canDelete, deleteReason)
    end

    if ui.invite then
        SetEditEnabled185(ui.invite.edit, caps.canInvite)
        UI:SetEnabled(ui.invite.send, caps.canInvite and type(GuildInviteByName) == "function", caps.canInvite and "GuildInviteByName is unavailable on this client." or "Your guild rank cannot invite members.")
    end
    if ui.memberManagement then
        local yes = self.colors.green .. "Yes" .. self.colors.reset
        local no = self.colors.grey .. "No" .. self.colors.reset
        ui.memberManagement.permissions:SetText(
            "Invite members        " .. (caps.canInvite and yes or no) .. "\n" ..
            "Promote members       " .. (caps.canPromote and yes or no) .. "\n" ..
            "Demote members        " .. (caps.canDemote and yes or no) .. "\n" ..
            "Remove members        " .. (caps.canRemove and yes or no) .. "\n" ..
            "Edit public notes     " .. (caps.canPublic and yes or no) .. "\n" ..
            "Edit officer notes    " .. (caps.canOfficer and yes or no)
        )
    end
    ui.loading = nil
end

local function LayoutGuildAdmin185(owner, page, width, height)
    if not owner.ui or not owner.ui.guildAdmin185 then return end
    local ui = owner.ui.guildAdmin185
    local contentHeight = math.max(500, height - 42)
    local index
    for index = 1, table.getn(ADMIN_TABS185) do
        local key = ADMIN_TABS185[index][1]
        local panel = ui.panels[key]
        if panel then panel:SetWidth(width) panel:SetHeight(contentHeight) end
    end
    if ui.scope then ui.scope:SetWidth(math.max(170, math.min(300, width - 430))) end

    if ui.motd then
        ui.motd:SetWidth(width)
        if ui.motd.help then ui.motd.help:SetWidth(math.max(280, width - 32)) end
        ui.motd.edit:SetWidth(math.max(340, width - 202))
        ui.info:SetWidth(width)
        if ui.info.help then ui.info.help:SetWidth(math.max(280, width - 32)) end
        ui.info.edit:SetWidth(math.max(460, width - 32))
    end

    if ui.rankLeft and ui.rankRight then
        local leftWidth = math.max(218, math.min(246, math.floor(width * 0.25)))
        local rightWidth = math.max(480, width - leftWidth - 12)
        local innerWidth = math.max(420, rightWidth - 32)
        ui.rankLeft:SetWidth(leftWidth)
        local rowWidth = math.max(156, leftWidth - 32)
        for index = 1, 10 do if ui.rankLeft.rows[index] then ui.rankLeft.rows[index]:SetWidth(rowWidth) end end
        if ui.rankLeft.summary then ui.rankLeft.summary:SetWidth(rowWidth) end
        if ui.rankLeft.addLabel then ui.rankLeft.addLabel:SetWidth(rowWidth) end
        if ui.rankLeft.newEdit then ui.rankLeft.newEdit:SetWidth(math.max(88, leftWidth - 108)) end

        ui.rankRight:ClearAllPoints()
        ui.rankRight:SetPoint("TOPLEFT", ui.panels.RANKS, "TOPLEFT", leftWidth + 12, 0)
        ui.rankRight:SetWidth(rightWidth)
        if ui.rankRight.state then ui.rankRight.state:SetWidth(math.max(230, rightWidth - 230)) end
        if ui.rankRight.changeState then
            ui.rankRight.changeState:ClearAllPoints()
            ui.rankRight.changeState:SetPoint("TOPRIGHT", ui.rankRight, "TOPRIGHT", -16, -39)
            ui.rankRight.changeState:SetWidth(math.max(120, math.min(190, rightWidth - 300)))
        end
        if ui.rankRight.nameEdit then ui.rankRight.nameEdit:SetWidth(math.max(150, math.min(240, rightWidth - 160))) end
        if ui.rankRight.readOnly then ui.rankRight.readOnly:SetWidth(innerWidth) end

        local groupKeys = { "CHAT", "MEMBERS", "GUILD" }
        local groupIndex
        for groupIndex = 1, table.getn(groupKeys) do
            local group = ui.rankRight.groups and ui.rankRight.groups[groupKeys[groupIndex]]
            if group then
                group:SetWidth(innerWidth)
                if group.title then group.title:SetWidth(math.max(200, innerWidth - 20)) end
            end
        end
        local colGap = 10
        local colWidth = math.floor((innerWidth - 20 - colGap) / 2)
        for index = 1, 12 do
            local check = ui.rankRight.checks[index]
            if check then
                local slot = tonumber(check.otlSlot185) or 1
                local row = math.floor((slot - 1) / 2)
                local col = math.mod(slot - 1, 2)
                check:ClearAllPoints()
                check:SetPoint("TOPLEFT", check:GetParent(), "TOPLEFT", 10 + (col * (colWidth + colGap)), -31 - (row * 30))
                check:SetWidth(colWidth)
                if check.text then check.text:SetWidth(math.max(80, colWidth - 34)) end
            end
        end
    end

    if ui.invite then
        ui.invite:SetWidth(width)
        if ui.invite.help then ui.invite.help:SetWidth(math.max(280, width - 32)) end
        if ui.invite.edit then ui.invite.edit:SetWidth(math.max(250, math.min(430, width - 210))) end
    end
    if ui.memberManagement then
        ui.memberManagement:SetWidth(width)
        if ui.memberManagement.intro then ui.memberManagement.intro:SetWidth(math.max(300, width - 32)) end
        local inner = math.max(700, width - 32)
        local gap = 12
        local rosterWidth = math.max(360, math.floor(inner * 0.58))
        local accessWidth = math.max(250, inner - rosterWidth - gap)
        if ui.memberManagement.rosterBox then ui.memberManagement.rosterBox:SetWidth(rosterWidth) end
        if ui.memberManagement.rosterTitle then ui.memberManagement.rosterTitle:SetWidth(math.max(220, rosterWidth - 24)) end
        if ui.memberManagement.list then ui.memberManagement.list:SetWidth(math.max(250, rosterWidth - 32)) end
        if ui.memberManagement.accessBox then
            ui.memberManagement.accessBox:ClearAllPoints()
            ui.memberManagement.accessBox:SetPoint("TOPLEFT", ui.memberManagement, "TOPLEFT", 16 + rosterWidth + gap, -88)
            ui.memberManagement.accessBox:SetWidth(accessWidth)
        end
        if ui.memberManagement.accessTitle then ui.memberManagement.accessTitle:SetWidth(math.max(180, accessWidth - 24)) end
        if ui.memberManagement.permissions then ui.memberManagement.permissions:SetWidth(math.max(190, accessWidth - 32)) end
    end
    page.otlNativeLayout = true
end

OTLGM:CreateShellPageModule180("guildadmin", BuildGuildAdmin185,
    function(owner) owner:RefreshGuildAdmin185() end,
    LayoutGuildAdmin185, { "guild-text", "ranks", "permissions", "members" }, { width = 760, height = 520 })

OTLGM:RegisterModule("GuildAdmin185", {
    stage = "RC",
    revision = 2,
    lazy = true,
    nativeContentHost = true,
    pageContract = true,
    serverBacked = true,
    noOnUpdate = true,
    noEvents = true,
})
