-- Order of the Lion Guild Manager 1.8.0
-- Native Roster page with table, details, filters, saved views and guild invite workflow.

if not OTLGM or not OTLGM.UI then return end

local UI = OTLGM.UI
local C = UI.colors
local ROW_HEIGHT = 28
local MIN_ROW_COUNT = 8

local CLASS_COORDS = {
    WARRIOR = { 0, 0.25, 0, 0.25 }, MAGE = { 0.25, 0.496, 0, 0.25 },
    ROGUE = { 0.496, 0.742, 0, 0.25 }, DRUID = { 0.742, 0.988, 0, 0.25 },
    HUNTER = { 0, 0.25, 0.25, 0.5 }, SHAMAN = { 0.25, 0.496, 0.25, 0.5 },
    PRIEST = { 0.496, 0.742, 0.25, 0.5 }, WARLOCK = { 0.742, 0.988, 0.25, 0.5 },
    PALADIN = { 0, 0.25, 0.5, 0.75 },
}

local CLASS_RGB_183 = {
    Warrior = {0.78,0.61,0.43}, Mage = {0.41,0.80,0.94}, Rogue = {1.00,0.96,0.41}, Druid = {1.00,0.49,0.04},
    Hunter = {0.67,0.83,0.45}, Shaman = {0.00,0.44,0.87}, Priest = {0.94,0.94,0.94}, Warlock = {0.58,0.51,0.79}, Paladin = {0.96,0.55,0.73},
}

local function ApplyClassIcon(texture, className)
    local coordinates = CLASS_COORDS[string.upper(tostring(className or ""))]
    if coordinates then
        texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
        texture:SetTexCoord(coordinates[1], coordinates[2], coordinates[3], coordinates[4])
    else
        texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        texture:SetTexCoord(0, 1, 0, 1)
    end
end

local RANK_ICONS = {
    MUTED = "Interface\\Icons\\Spell_Shadow_CurseOfTounges",
    GUEST = "Interface\\Icons\\INV_Letter_15",
    LION = "Interface\\Icons\\Ability_Hunter_Pet_Cat",
    LOYAL = "Interface\\Icons\\INV_Misc_Rune_01",
    RAIDER = "Interface\\Icons\\INV_Sword_04",
    CORE_RAIDER = "Interface\\Icons\\Ability_DualWield",
    HELPER = "Interface\\Icons\\Spell_Holy_Heal",
    OFFICER = "Interface\\Icons\\INV_Shield_06",
    RAID_LEADER = "Interface\\Icons\\Ability_Warrior_BattleShout",
    GUILD_LEADER = "Interface\\Icons\\INV_Crown_01",
}

local RANK_INDEX_FALLBACK = {
    [0] = { "GUILD_LEADER", "Guild Leader" },
    [1] = { "RAID_LEADER", "Raid Leader" },
    [2] = { "OFFICER", "Officer" },
    [3] = { "HELPER", "Helper" },
    [4] = { "CORE_RAIDER", "Core Raider" },
    [5] = { "RAIDER", "Raider" },
    [6] = { "LOYAL", "Loyal" },
    [7] = { "LION", "Lion" },
    [8] = { "GUEST", "Guest" },
    [9] = { "MUTED", "Muted / Restricted" },
}

local function ResolveRankName180(rankName)
    local rank = string.lower(tostring(rankName or ""))
    rank = string.gsub(rank, "^%s+", "")
    rank = string.gsub(rank, "%s+$", "")
    if string.find(rank, "muted", 1, true) or string.find(rank, "restricted", 1, true)
        or string.find(rank, "tormented", 1, true) or string.find(rank, "punished", 1, true) then return "muted" end
    if string.find(rank, "guest", 1, true) then return "guest" end
    if string.find(rank, "lion", 1, true) and not string.find(rank, "lionheart", 1, true) then return "lion" end
    return "unknown"
end

function OTLGM:RankResolver180(rankName, rankIndex)
    local normalized = ResolveRankName180(rankName)
    return { name = tostring(rankName or ""), normalized = normalized, index = tonumber(rankIndex), known = normalized ~= "unknown" }
end

local function GetRankGroup(member)
    local rank = string.lower(tostring(member and member.rank or ""))
    local rankIndex = tonumber(member and member.rankIndex)
    if OTLGM.IsCanonicalGuildLeaderName180 and OTLGM:IsCanonicalGuildLeaderName180(member and member.name) then
        return "GUILD_LEADER", "Guild Leader"
    end
    if string.find(rank, "muted", 1, true) or string.find(rank, "restricted", 1, true)
        or string.find(rank, "tormented", 1, true) or string.find(rank, "punished", 1, true) then
        return "MUTED", "Muted / Restricted"
    end
    if string.find(rank, "guest", 1, true) then return "GUEST", "Guest" end
    if string.find(rank, "core raider", 1, true) or string.find(rank, "the devoted", 1, true) then return "CORE_RAIDER", "Core Raider" end
    if string.find(rank, "raid leader", 1, true) or string.find(rank, "raidlead", 1, true) then return "RAID_LEADER", "Raid Leader" end
    -- Do not infer the guild-leader identity from a stale rank label/index.
    -- Only the configured guild-leader identities can receive the guild-leader badge.
    if string.find(rank, "officer", 1, true) or string.find(rank, "lionheart", 1, true) then return "OFFICER", "Officer" end
    if string.find(rank, "helper", 1, true) or string.find(rank, "inn keeper", 1, true) then return "HELPER", "Helper" end
    if string.find(rank, "raider", 1, true) then return "RAIDER", "Raider" end
    if string.find(rank, "loyal", 1, true) then return "LOYAL", "Loyal" end
    if string.find(rank, "lion", 1, true) then return "LION", "Lion" end
    if rankIndex == 0 then return "OFFICER", "Leadership" end
    if rankIndex ~= nil and RANK_INDEX_FALLBACK[rankIndex] then
        return RANK_INDEX_FALLBACK[rankIndex][1], RANK_INDEX_FALLBACK[rankIndex][2]
    end
    return "GUEST", "Unknown rank"
end

local function ApplyRankGroupIcon(row, member)
    local key, label = GetRankGroup(member)
    row.rankGroup = key
    row.rankGroupLabel = label
    row.rankIcon:SetTexture(RANK_ICONS[key] or RANK_ICONS.GUEST)
    row.rankIcon:SetTexCoord(0, 1, 0, 1)
end

local function ApplyRosterRankTextColor180(fontString, member, leadership)
    if not fontString then return end
    local rankGroup = GetRankGroup(member)
    local color = nil
    if leadership then
        color = C.gold
    elseif rankGroup == "CORE_RAIDER" or rankGroup == "RAIDER" then
        color = C.purple or { 0.69, 0.42, 1.00, 1 }
    elseif rankGroup == "MUTED" then
        color = C.red
    else
        color = member and member.online and C.white or C.grey
    end
    if not (member and member.online) and (rankGroup == "CORE_RAIDER" or rankGroup == "RAIDER") then
        -- Keep the raid-rank identity visible while still making offline rows
        -- quieter than active members.
        fontString:SetTextColor(color[1] * 0.72, color[2] * 0.72, color[3] * 0.72)
    else
        fontString:SetTextColor(color[1], color[2], color[3])
    end
end

local function ApplyRosterRowState180(row, member, leadership, selected)
    -- The common button skin is applied first. This owning-page state then
    -- establishes a deterministic order: selected leadership > selected normal
    -- > leadership online/offline > normal online/offline.
    row.otlLeadership180 = leadership and true or false
    row.otlSelected180 = selected and true or false
    if row.rankIcon and row.rankIcon.SetVertexColor then row.rankIcon:SetVertexColor(1, 1, 1, 1) end
    if leadership then row.leadershipAccent:Show() else row.leadershipAccent:Hide() end
    if row.SetBackdropColor then
        if selected and leadership then row:SetBackdropColor(0.165, 0.115, 0.040, 0.99)
        elseif selected then row:SetBackdropColor(0.105, 0.080, 0.038, 0.98)
        elseif leadership and member.online then row:SetBackdropColor(0.125, 0.086, 0.032, 0.97)
        elseif leadership then row:SetBackdropColor(0.078, 0.060, 0.035, 0.96)
        elseif member.online and row.otlEven183 then row:SetBackdropColor(0.054, 0.047, 0.037, 0.94)
        elseif member.online then row:SetBackdropColor(0.040, 0.037, 0.032, 0.93)
        elseif row.otlEven183 then row:SetBackdropColor(0.029, 0.027, 0.024, 0.97)
        else row:SetBackdropColor(0.019, 0.019, 0.019, 0.97) end
    end
    if row.SetBackdropBorderColor then
        if selected and leadership then row:SetBackdropBorderColor(C.gold[1], C.gold[2], C.gold[3], 0.98)
        elseif selected then row:SetBackdropBorderColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3], 0.86)
        elseif leadership then row:SetBackdropBorderColor(C.goldDark[1], C.goldDark[2], C.goldDark[3], member.online and 0.88 or 0.68)
        else row:SetBackdropBorderColor(C.goldDark[1], C.goldDark[2], C.goldDark[3], 0.24) end
    end
end

local FILTERS = {
    { "ALL", "All members" }, { "ONLINE", "Online" }, { "LEADERSHIP", "Leadership" },
    { "SAMEZONE", "Same zone" }, { "NEARLEVEL", "Near my level" }, { "LEVEL60", "Level 60" },
    { "NEW14", "New in 14d" }, { "RETURNED14", "Returned 14d" }, { "PROMOTED14", "Promoted 14d" },
    { "INACTIVE14", "Inactive 14d" }, { "INACTIVE30", "Inactive 30d" }, { "INACTIVE60", "Inactive 60d" },
    { "INACTIVE90", "Inactive 90d" }, { "LEVEL1_19", "Level 1-19" }, { "LEVEL20_39", "Level 20-39" },
    { "LEVEL40_59", "Level 40-59" }, { "ADDON_ACTIVE", "Addon active" }, { "ADDON_SEEN", "Addon seen" },
    { "ADDON_UNDETECTED", "Addon unknown" }, { "MAIN_ALT", "Main / Alts" },
}

local function Label(parent, value, template, x, y, width, justify)
    local label = UI.Text(parent, value, template, justify)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then label:SetWidth(width) end
    return label
end

local function Short(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or 40
    if string.len(value) <= maximum then return value end
    return string.sub(value, 1, math.max(1, maximum - 3)) .. "..."
end

local function SetRosterMemberNameR35(owner, row, member)
    local badge184 = owner.GetCharacterIdentityRosterBadge184 and owner:GetCharacterIdentityRosterBadge184(member.name) or nil
    local canShowBadge184 = badge184 and row and row.nameText and (tonumber(row.nameText:GetWidth()) or 0) >= 82
    local maximum184 = canShowBadge184 and 16 or 20
    local prefix184 = canShowBadge184 and (tostring(badge184.color or owner.colors.blue) .. tostring(badge184.label or "") .. owner.colors.reset .. " ") or ""
    if member.online then
        row.nameText:SetText(prefix184 .. owner:GetClassColor(member.class) .. Short(member.name, maximum184) .. owner.colors.reset)
    else
        row.nameText:SetText(prefix184 .. owner.colors.grey .. Short(member.name, maximum184) .. owner.colors.reset)
    end
end

local function MakeNoteEdit(parent, width, height)
    return UI:EditBox(parent, width, height, {
        maxLetters = 31,
        fontObject = "GameFontHighlightSmall",
        changed = function()
            if OTLGM.RefreshRosterSaveState then OTLGM:RefreshRosterSaveState() end
        end,
    })
end

local RefreshDetails

local function CurrentFilterLabel(key)
    local index
    for index = 1, table.getn(FILTERS) do
        if FILTERS[index][1] == key then return FILTERS[index][2] end
    end
    return key or "All members"
end

local function SavedRosterViewLabelR39(slot, view)
    slot = tonumber(slot) or 1
    if not view then return "Favorite " .. tostring(slot) .. "  •  Empty" end
    local primary = CurrentFilterLabel(view.filter or "ALL")
    if view.rank and view.rank ~= "" then primary = primary .. " / " .. tostring(view.rank) end
    if view.search and view.search ~= "" then primary = "Search: " .. tostring(view.search) end
    return Short("Favorite " .. tostring(slot) .. "  •  " .. primary, 37)
end

function OTLGM:PersistRosterPosition180()
    if not OTLGM_DB or not OTLGM_DB.settings or not self.ui then return end
    OTLGM_DB.settings.rosterShellOffset180 = math.max(0, tonumber(self.ui.rosterOffset) or 0)
    OTLGM_DB.settings.rosterShellSelection180 = self.ui.rosterSelectedName or ""
end

function OTLGM:ScrollRosterShell180(lines)
    if not self.ui or not self.ui.rosterTable then return end
    local filter = self.ui.rosterFilter or OTLGM_DB.settings.rosterFilter or "ALL"
    local search = self.ui.rosterSearch and self.ui.rosterSearch:GetText() or OTLGM_DB.settings.rosterSearch or ""
    -- RC4-r9: the current view count is already known after every paint.  Do
    -- not sort the entire roster merely to learn the scrollbar maximum before
    -- RefreshRosterPage() paints the same view.  The fallback is only for the
    -- impossible/early case where scrolling happens before the first refresh.
    local listCount184 = tonumber(self.ui.rosterLastListCount184)
    if not listCount184 then
        local list184 = self:GetSortedRoster(search, filter, self.ui.rosterRankFilter, self.ui.rosterProfessionFilter)
        listCount184 = table.getn(list184)
    end
    local capacity = math.max(MIN_ROW_COUNT, tonumber(self.ui.rosterVisibleCapacity180) or MIN_ROW_COUNT)
    local maximum = math.max(0, listCount184 - capacity)
    self.ui.rosterOffset = math.max(0, math.min(maximum, (tonumber(self.ui.rosterOffset) or 0) + (tonumber(lines) or 0)))
    self:PersistRosterPosition180()
    self:RefreshRosterPage()
end

function OTLGM:ShowRosterRowTooltip180(row)
    if not row or not row.otlTooltipLines or not GameTooltip then return end
    GameTooltip:SetOwner(row, "ANCHOR_LEFT")
    local index
    for index = 1, table.getn(row.otlTooltipLines) do
        local line = row.otlTooltipLines[index]
        if line and line ~= "" then GameTooltip:AddLine(line, index == 1 and 1 or 0.9, index == 1 and 0.82 or 0.9, index == 1 and 0.35 or 0.9, true) end
    end
    -- r34 identity adds one tooltip line only; roster row geometry and columns
    -- remain untouched. Unverified/pending foreign claims are never shown.
    if row.otlMemberName and self.GetCharacterIdentityTooltipLine184 then
        local identityLine184 = self:GetCharacterIdentityTooltipLine184(row.otlMemberName)
        if identityLine184 and identityLine184 ~= "" then GameTooltip:AddLine(identityLine184, 0.52, 0.72, 1.00, true) end
    end
    GameTooltip:Show()
end

function OTLGM:SetRosterShellFilter(filter)
    filter = filter or "ALL"
    OTLGM_DB.settings.rosterFilter = filter
    self.ui.rosterFilter = filter
    self.ui.rosterOffset = 0
    self:PersistRosterPosition180()
    self:RefreshRosterPage()
end

function OTLGM:CycleRosterRankShell(direction)
    local ranks = self.GetRosterRanks and self:GetRosterRanks() or {}
    local values = { "" }
    local index
    for index = 1, table.getn(ranks) do table.insert(values, ranks[index].name) end
    local current = self.ui.rosterRankFilter or OTLGM_DB.settings.rosterRankFilter or ""
    local selected = 1
    for index = 1, table.getn(values) do if values[index] == current then selected = index break end end
    selected = selected + (direction or 1)
    if selected > table.getn(values) then selected = 1 end
    if selected < 1 then selected = table.getn(values) end
    self.ui.rosterRankFilter = values[selected] ~= "" and values[selected] or nil
    OTLGM_DB.settings.rosterRankFilter = values[selected]
    self.ui.rosterOffset = 0
    self:RefreshRosterFiltersDrawer()
    self:RefreshRosterPage()
end

function OTLGM:CycleRosterProfessionShell(direction)
    local definitions = self.GetCraftingProfessionDefinitions and self:GetCraftingProfessionDefinitions() or { { key = "ALL", label = "All Professions" } }
    local current = self.ui.rosterProfessionFilter or OTLGM_DB.settings.rosterProfessionFilter or ""
    if current == "" then current = "ALL" end
    local selected, index = 1, 1
    for index = 1, table.getn(definitions) do if definitions[index].key == current then selected = index break end end
    selected = selected + (direction or 1)
    if selected > table.getn(definitions) then selected = 1 end
    if selected < 1 then selected = table.getn(definitions) end
    local key = definitions[selected].key
    self.ui.rosterProfessionFilter = key ~= "ALL" and key or nil
    OTLGM_DB.settings.rosterProfessionFilter = key ~= "ALL" and key or ""
    self.ui.rosterOffset = 0
    self:RefreshRosterFiltersDrawer()
    self:RefreshRosterPage()
end

local function BuildRosterChoiceMenu180(parent, width, maximumItems, columns)
    columns = math.max(1, tonumber(columns) or 1)
    local menu = UI:Card(parent, width, 40, "")
    menu:SetFrameLevel((parent.GetFrameLevel and parent:GetFrameLevel() or 1) + 24)
    menu.rows180 = {}
    menu.columns180 = columns
    local gap, pad = 5, 5
    local cellWidth = math.floor((width - (pad * 2) - ((columns - 1) * gap)) / columns)
    local index
    for index = 1, maximumItems do
        local column = math.mod(index - 1, columns)
        local rowIndex = math.floor((index - 1) / columns)
        local row = UI:Button(menu, "", cellWidth, 24, function(button)
            local current = button and button.otlChoiceMenu180
            if not current or button.otlChoiceKey180 == nil then return end
            local callback = current.otlChoiceHandler180
            current:Hide()
            if callback then callback(button.otlChoiceKey180) end
        end, "filter")
        row:SetPoint("TOPLEFT", menu, "TOPLEFT", pad + (column * (cellWidth + gap)), -pad - (rowIndex * 25))
        row.otlChoiceMenu180 = menu
        row:Hide()
        menu.rows180[index] = row
    end
    menu:Hide()
    return menu
end

local function HideRosterChoiceMenus180(drawer, except)
    if not drawer then return end
    local menus = { drawer.viewMenu180, drawer.rankMenu180, drawer.professionMenu180 }
    local index
    for index = 1, table.getn(menus) do
        if menus[index] and menus[index] ~= except then menus[index]:Hide() end
    end
end

local function ToggleRosterChoiceMenu180(drawer, menu, definitions, selected, handler)
    if not drawer or not menu then return false end
    local wasVisible = menu:IsVisible()
    HideRosterChoiceMenus180(drawer, menu)
    if wasVisible then menu:Hide() return false end
    definitions = definitions or {}
    local count = math.min(table.getn(definitions), table.getn(menu.rows180 or {}))
    local index
    for index = 1, table.getn(menu.rows180 or {}) do
        local row, definition = menu.rows180[index], definitions[index]
        if definition and index <= count then
            row.otlChoiceKey180 = definition.key ~= nil and definition.key or definition[1]
            UI:SetText(row, definition.label or definition[2] or tostring(row.otlChoiceKey180 or "Any"))
            UI:SetSelected(row, row.otlChoiceKey180 == selected)
            row:Show()
        else
            row.otlChoiceKey180 = nil
            row:Hide()
        end
    end
    local columns = math.max(1, tonumber(menu.columns180) or 1)
    menu:SetHeight(10 + (math.ceil(count / columns) * 25))
    menu.otlChoiceHandler180 = handler
    menu:Show()
    return true
end

function OTLGM:BuildRosterFiltersDrawer()
    if self.ui.rosterFiltersDrawer then return end
    local drawer = UI:Drawer(self.ui.drawerHost, 420, 500)
    drawer:SetPoint("TOPRIGHT", self.ui.drawerHost, "TOPRIGHT", -10, -10)
    drawer.title = Label(drawer, "Roster Filters", "GameFontNormalLarge", 18, -18, 250, "LEFT")
    drawer.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    drawer.close = UI:IconButton(drawer, "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 28, 28, function() OTLGM:CloseShellDrawer() end, "Close", "utility")
    drawer.close:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -12, -12)
    drawer.clear = UI:Button(drawer, "Reset", 72, 26, function()
        OTLGM.ui.rosterRankFilter = nil
        OTLGM.ui.rosterProfessionFilter = nil
        OTLGM_DB.settings.rosterRankFilter = ""
        OTLGM_DB.settings.rosterProfessionFilter = ""
        OTLGM:SetRosterShellFilter("ALL")
        OTLGM:RefreshRosterFiltersDrawer()
    end, "utility")
    drawer.clear:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -50, -14)

    Label(drawer, "QUICK VIEW", "GameFontNormalSmall", 18, -60, 180, "LEFT"):SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    drawer.quickButtons180 = {}
    local quick = {
        { "ALL", "All" }, { "ONLINE", "Online" }, { "LEADERSHIP", "Leadership" },
        { "SAMEZONE", "My zone" }, { "NEARLEVEL", "Near level" }, { "LEVEL60", "Level 60" },
    }
    local index
    for index = 1, table.getn(quick) do
        local captured = index
        local column = math.mod(captured - 1, 3)
        local rowIndex = math.floor((captured - 1) / 3)
        local button = UI:FilterChip(drawer, quick[captured][2], 122, function()
            OTLGM:SetRosterShellFilter(quick[captured][1])
            OTLGM:RefreshRosterFiltersDrawer()
        end)
        button:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18 + (column * 128), -82 - (rowIndex * 30))
        button.otlFilterKey180 = quick[captured][1]
        drawer.quickButtons180[captured] = button
    end

    Label(drawer, "MEMBER VIEW", "GameFontNormalSmall", 18, -148, 180, "LEFT"):SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    drawer.view = UI:Button(drawer, "View: All members  v", 384, 30, function()
        local definitions = {}
        local i
        for i = 1, table.getn(FILTERS) do
            if string.sub(FILTERS[i][1], 1, 6) ~= "ADDON_" or OTLGM:IsOfficerMode() then
                table.insert(definitions, { key = FILTERS[i][1], label = FILTERS[i][2] })
            end
        end
        ToggleRosterChoiceMenu180(drawer, drawer.viewMenu180, definitions, OTLGM.ui.rosterFilter or "ALL", function(key)
            OTLGM:SetRosterShellFilter(key)
            OTLGM:RefreshRosterFiltersDrawer()
        end)
    end, "filter")
    drawer.view:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -169)
    drawer.viewMenu180 = BuildRosterChoiceMenu180(drawer, 384, table.getn(FILTERS), 2)
    drawer.viewMenu180:SetPoint("TOPLEFT", drawer.view, "BOTTOMLEFT", 0, -2)

    Label(drawer, "RANK", "GameFontNormalSmall", 18, -214, 120, "LEFT"):SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    Label(drawer, "PROFESSION", "GameFontNormalSmall", 216, -214, 150, "LEFT"):SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    drawer.rank = UI:Button(drawer, "Any rank  v", 186, 30, function()
        local definitions = { { key = "", label = "Any rank" } }
        local ranks = OTLGM:GetRosterRanks() or {}
        local i
        for i = 1, table.getn(ranks) do table.insert(definitions, { key = ranks[i].name, label = ranks[i].name }) end
        ToggleRosterChoiceMenu180(drawer, drawer.rankMenu180, definitions, OTLGM.ui.rosterRankFilter or "", function(key)
            OTLGM.ui.rosterRankFilter = key ~= "" and key or nil
            OTLGM_DB.settings.rosterRankFilter = key or ""
            OTLGM.ui.rosterOffset = 0
            OTLGM:RefreshRosterFiltersDrawer()
            OTLGM:RefreshRosterPage()
        end)
    end, "filter")
    drawer.rank:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -235)
    drawer.profession = UI:Button(drawer, "Any profession  v", 186, 30, function()
        local definitions = { { key = "", label = "Any profession" } }
        local professions = OTLGM.GetCraftingProfessionDefinitions and OTLGM:GetCraftingProfessionDefinitions() or {}
        local i
        for i = 1, table.getn(professions) do
            if professions[i].key ~= "ALL" then table.insert(definitions, { key = professions[i].key, label = professions[i].label }) end
        end
        ToggleRosterChoiceMenu180(drawer, drawer.professionMenu180, definitions, OTLGM.ui.rosterProfessionFilter or "", function(key)
            OTLGM.ui.rosterProfessionFilter = key ~= "" and key or nil
            OTLGM_DB.settings.rosterProfessionFilter = key or ""
            OTLGM.ui.rosterOffset = 0
            OTLGM:RefreshRosterFiltersDrawer()
            OTLGM:RefreshRosterPage()
        end)
    end, "filter")
    drawer.profession:SetPoint("TOPLEFT", drawer, "TOPLEFT", 216, -235)
    drawer.rankMenu180 = BuildRosterChoiceMenu180(drawer, 384, 14, 2)
    drawer.rankMenu180:SetPoint("TOPLEFT", drawer.rank, "BOTTOMLEFT", 0, -2)
    drawer.professionMenu180 = BuildRosterChoiceMenu180(drawer, 384, 14, 2)
    drawer.professionMenu180:SetPoint("TOPRIGHT", drawer.profession, "BOTTOMRIGHT", 0, -2)

    Label(drawer, "QUICK FAVORITES", "GameFontNormalSmall", 18, -286, 220, "LEFT"):SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    drawer.saved = {}
    for index = 1, 3 do
        local captured = index
        local load = UI:Button(drawer, "Favorite " .. tostring(captured), 270, 28, function()
            local exists = OTLGM_DB.settings.savedRosterViews and OTLGM_DB.settings.savedRosterViews[captured]
            if exists then
                OTLGM:LoadRosterView(captured)
            else
                OTLGM:SaveRosterView(captured)
                OTLGM:ShowToast("Roster favorite saved.", "success")
            end
            OTLGM:RefreshRosterFiltersDrawer()
        end, "secondary")
        load:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -308 - ((captured - 1) * 34))
        local save = UI:Button(drawer, "Save", 104, 28, function()
            OTLGM:SaveRosterView(captured)
            OTLGM:ShowToast("Favorite " .. tostring(captured) .. " updated.", "success")
            OTLGM:RefreshRosterFiltersDrawer()
        end, "utility")
        save:SetPoint("LEFT", load, "RIGHT", 8, 0)
        drawer.saved[captured] = { load = load, save = save }
    end
    drawer.hint = Label(drawer, "Favorites remember your search, filters and sorting. Select one to restore it, or replace it with the current roster view.", "GameFontNormalSmall", 18, -418, 384, "LEFT")
    drawer.hint:SetHeight(48)
    drawer.hint:SetJustifyV("TOP")
    drawer.hint:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    self.ui.rosterFiltersDrawer = drawer
end

function OTLGM:RefreshRosterFiltersDrawer()
    local drawer = self.ui and self.ui.rosterFiltersDrawer
    if not drawer then return end
    local current = self.ui.rosterFilter or OTLGM_DB.settings.rosterFilter or "ALL"
    local index
    for index = 1, table.getn(drawer.quickButtons180 or {}) do
        local button = drawer.quickButtons180[index]
        UI:SetSelected(button, button.otlFilterKey180 == current)
    end
    UI:SetText(drawer.view, "View: " .. CurrentFilterLabel(current) .. "  v")
    local rank = self.ui.rosterRankFilter or OTLGM_DB.settings.rosterRankFilter or ""
    local profession = self.ui.rosterProfessionFilter or OTLGM_DB.settings.rosterProfessionFilter or ""
    UI:SetText(drawer.rank, (rank ~= "" and rank or "Any rank") .. "  v")
    local professionLabel = "Any profession"
    local definitions = self.GetCraftingProfessionDefinitions and self:GetCraftingProfessionDefinitions() or {}
    for index = 1, table.getn(definitions) do
        if definitions[index].key == profession then professionLabel = definitions[index].label break end
    end
    UI:SetText(drawer.profession, professionLabel .. "  v")
    for index = 1, 3 do
        local exists = OTLGM_DB.settings.savedRosterViews and OTLGM_DB.settings.savedRosterViews[index]
        UI:SetText(drawer.saved[index].load, SavedRosterViewLabelR39(index, exists))
        UI:SetText(drawer.saved[index].save, exists and "Replace" or "Save")
        UI:SetEnabled(drawer.saved[index].load, true)
    end
end

function OTLGM:OpenRosterFiltersDrawer()
    self:BuildRosterFiltersDrawer()
    if self.ui and self.ui.rosterFiltersDrawer then HideRosterChoiceMenus180(self.ui.rosterFiltersDrawer) end
    self:RefreshRosterFiltersDrawer()
    self:ShowShellDrawer(self.ui.rosterFiltersDrawer)
end

function OTLGM:RefreshRosterSelection183(previousName, selectedName)
    self.runtime = self.runtime or {}
    self.runtime.rosterMetrics180 = self.runtime.rosterMetrics180 or { fullScans = 0, targetedRefreshes = 0, reasons = {} }
    self.runtime.rosterMetrics180.selectionRefreshes183 =
        (tonumber(self.runtime.rosterMetrics180.selectionRefreshes183) or 0) + 1
    local selectedMember = selectedName and self:GetMember(selectedName) or nil
    local previousKey, selectedKey = self:NormalizeName(previousName or ""), self:NormalizeName(selectedName or "")
    local index
    for index = 1, table.getn(self.ui and self.ui.rosterTable and self.ui.rosterTable.rows or {}) do
        local row = self.ui.rosterTable.rows[index]
        local rowKey = row and row.otlMemberName and self:NormalizeName(row.otlMemberName) or ""
        if rowKey ~= "" and (rowKey == previousKey or rowKey == selectedKey) then
            local member = self:GetMember(row.otlMemberName)
            local selected = member and rowKey == selectedKey and true or false
            UI:SetSelected(row, selected)
            if member then ApplyRosterRowState180(row, member, self:IsLeadership(member), selected) end
        end
    end
    if self.ui and self.ui.rosterDetails then RefreshDetails(self, selectedMember) end
    self:PersistRosterPosition180()
    return selectedMember ~= nil
end

function OTLGM:SelectRosterMember(name)
    local member = name and self:GetMember(name) or nil
    local previousName = self.ui.rosterSelectedName
    self.ui.rosterSelectedName = member and member.name or nil
    -- Retain the legacy alias for shared management/actions, but do not rebuild
    -- or sort the roster list merely to change selection.
    self.ui.selectedMember = self.ui.rosterSelectedName
    if self.ui.rosterDetails then self.ui.rosterDetails.historyOffset = 0 end
    self:RefreshRosterSelection183(previousName, self.ui.rosterSelectedName)
    -- Selection keeps the existing management workflow and then updates the
    -- separate cache-only companion. No display path requests fresh data.
    if member and self.OpenGuildMemberProfile183 then
        self:OpenGuildMemberProfile183(member.name, "roster", true)
    end
end

function OTLGM:RefreshRosterSaveState()
    local details = self.ui and self.ui.rosterDetails
    if not details or not details.otlMember then return end
    if self.rosterActionPending180 and not self.rosterActionPending180.targeted180 then details.saveNotes:Hide() return end
    local member = details.otlMember
    local publicChanged = details.publicEdit:IsVisible() and (details.publicEdit:GetText() or "") ~= tostring(member.note or "")
    local officerChanged = details.officerEdit:IsVisible() and (details.officerEdit:GetText() or "") ~= tostring(member.officerNote or "")
    if publicChanged or officerChanged then details.saveNotes:Show() else details.saveNotes:Hide() end
end

local function NormalizeGuildRankLabel180(value)
    local text = string.lower(tostring(value or ""))
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = string.gsub(text, "|r", "")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    -- OctoWoW may render the disciplinary rank as (- Muted -), - Muted -,
    -- or with a numeric prefix. Strip wrapper punctuation, not just dashes.
    text = string.gsub(text, "^%d+%s*[%p%s]*", "")
    text = string.gsub(text, "^[%p%s]+", "")
    text = string.gsub(text, "[%p%s]+$", "")
    text = string.gsub(text, "%s+", " ")
    return text
end

function OTLGM:NormalizeGuildRankLabel180(value)
    return NormalizeGuildRankLabel180(value)
end

function OTLGM:GetLiveGuildRankCatalog180()
    local result = {}
    local seen = {}
    local liveCatalogComplete = false
    local function AddRank(index, name, source)
        index = tonumber(index)
        name = tostring(name or "")
        if index == nil or name == "" or seen[index] then return false end
        result[table.getn(result) + 1] = {
            index = index,
            name = name,
            normalized = NormalizeGuildRankLabel180(name),
            source180 = source or "unknown",
        }
        seen[index] = true
        return true
    end
    if GuildControlGetNumRanks and GuildControlGetRankName then
        local okCount, count = pcall(GuildControlGetNumRanks)
        count = okCount and tonumber(count) or nil
        if count and count > 0 then
            local rankNumber, loaded = 1, 0
            for rankNumber = 1, count do
                local okName, currentName = pcall(GuildControlGetRankName, rankNumber)
                if okName and AddRank(rankNumber - 1, currentName, "live-api") then loaded = loaded + 1 end
            end
            liveCatalogComplete = loaded == count
        end
    end
    -- Keep the last complete guild-rank catalog. Empty ranks (notably - Muted -)
    -- cannot be reconstructed from occupied roster rows alone.
    local saved = OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.guildRankCatalog180
    if type(saved) == "table" then
        local index, entry
        for index = 1, table.getn(saved) do
            entry = saved[index]
            if type(entry) == "table" then AddRank(entry.index, entry.name, "saved-catalog") end
        end
    end
    local ranks = self.GetRosterRanks and self:GetRosterRanks() or {}
    local index
    for index = 1, table.getn(ranks) do AddRank(ranks[index].index, ranks[index].name, "occupied-roster") end

    -- If the full API is temporarily unavailable but live Guest and Lion rows
    -- prove a single empty rank between them, preserve the configured guild
    -- label for that exact midpoint. No other rank is guessed.
    local guestIndex, lionIndex, hasMuted
    for index = 1, table.getn(result) do
        local normalized = result[index].normalized
        if normalized == "guest" then guestIndex = tonumber(result[index].index)
        elseif normalized == "lion" then lionIndex = tonumber(result[index].index)
        elseif normalized == "muted" then hasMuted = true end
    end
    if not hasMuted and guestIndex and lionIndex and guestIndex == lionIndex + 2 then
        AddRank(lionIndex + 1, "- Muted -", "verified-midpoint")
    end

    table.sort(result, function(a, b)
        if tonumber(a.index) ~= tonumber(b.index) then return tonumber(a.index) < tonumber(b.index) end
        return tostring(a.name) < tostring(b.name)
    end)
    if liveCatalogComplete and OTLGM_DB and OTLGM_DB.settings then
        OTLGM_DB.settings.guildRankCatalog180 = {}
        for index = 1, table.getn(result) do
            OTLGM_DB.settings.guildRankCatalog180[index] = { index = result[index].index, name = result[index].name }
        end
    end
    return result
end

function OTLGM:FindGuildRankIndexByName180(rankName)
    local wanted = NormalizeGuildRankLabel180(rankName)
    if wanted == "" then return nil end
    local catalog = self:GetLiveGuildRankCatalog180()
    local foundIndex, foundName
    local index
    for index = 1, table.getn(catalog) do
        if catalog[index].normalized == wanted then
            if foundIndex ~= nil and foundIndex ~= tonumber(catalog[index].index) then return nil end
            foundIndex = tonumber(catalog[index].index)
            foundName = catalog[index].name
        end
    end
    return foundIndex, foundName
end

function OTLGM:ResolveGuestLionRankPath180()
    local guestIndex, guestName = self:FindGuildRankIndexByName180("Guest")
    local mutedIndex, mutedName = self:FindGuildRankIndexByName180("Muted")
    local lionIndex, lionName = self:FindGuildRankIndexByName180("Lion")
    if guestIndex == nil or mutedIndex == nil or lionIndex == nil then
        return nil, "The live Guest, Muted and Lion ranks could not all be resolved."
    end
    if guestIndex ~= mutedIndex + 1 or mutedIndex ~= lionIndex + 1 then
        return nil, "The live guild rank order is not Guest → Muted → Lion. Automatic promotion was not started."
    end
    return {
        guestIndex = guestIndex,
        guestName = guestName,
        mutedIndex = mutedIndex,
        mutedName = mutedName,
        lionIndex = lionIndex,
        lionName = lionName,
    }
end

function OTLGM:GetLiveRosterEntry180(name, preferredIndex)
    if not name or not GetGuildRosterInfo then return nil end
    self.runtime = self.runtime or {}
    self.runtime.rosterIndexByName180 = self.runtime.rosterIndexByName180 or {}
    local key = self:NormalizeName(name)
    local stored = self:GetMember(name)
    local candidates = {}
    local function AddCandidate180(value)
        value = tonumber(value)
        if not value then return end
        local candidateIndex
        for candidateIndex = 1, table.getn(candidates) do
            if candidates[candidateIndex] == value then return end
        end
        table.insert(candidates, value)
    end
    AddCandidate180(preferredIndex)
    AddCandidate180(stored and stored.rosterIndex)
    AddCandidate180(self.runtime.rosterIndexByName180[key])
    local rosterIndex, liveName, rank, rankIndex, level, className, zone, publicNote, officerNote, online, status, classFileName
    local index
    for index = 1, table.getn(candidates) do
        rosterIndex = candidates[index]
        if rosterIndex then
            liveName, rank, rankIndex, level, className, zone, publicNote, officerNote, online, status, classFileName = GetGuildRosterInfo(rosterIndex)
            if liveName and self:NormalizeName(liveName) == key then break end
            rosterIndex, liveName = nil, nil
        end
    end
    if not rosterIndex and self.FindRosterIndex then
        rosterIndex = self:FindRosterIndex(name)
        if rosterIndex then liveName, rank, rankIndex, level, className, zone, publicNote, officerNote, online, status, classFileName = GetGuildRosterInfo(rosterIndex) end
    end
    if not rosterIndex or not liveName or self:NormalizeName(liveName) ~= key then return nil end
    self.runtime.rosterIndexByName180[key] = rosterIndex
    stored = stored or self:GetMember(liveName)
    return {
        name = liveName,
        rosterIndex = rosterIndex,
        rank = rank,
        rankIndex = tonumber(rankIndex),
        level = tonumber(level),
        class = className,
        zone = zone,
        note = publicNote,
        officerNote = officerNote,
        online = online and true or false,
        status = status,
        classFileName = classFileName,
        guid = stored and stored.guid or nil,
    }
end

function OTLGM:ApplyTargetedRosterEntry180(entry)
    if type(entry) ~= "table" or not entry.name then return nil end
    local member = self:GetMember(entry.name)
    if not member then return nil end
    member.rosterIndex = entry.rosterIndex or member.rosterIndex
    if entry.rank ~= nil then member.rank = entry.rank end
    if entry.rankIndex ~= nil then member.rankIndex = entry.rankIndex end
    if entry.level ~= nil then member.level = entry.level end
    if entry.class ~= nil then member.class = entry.class end
    if entry.zone ~= nil then member.zone = entry.zone end
    if entry.note ~= nil then member.note = entry.note end
    if entry.officerNote ~= nil and self.CanViewOfficerNotes and self:CanViewOfficerNotes() then member.officerNote = entry.officerNote end
    member.online = entry.online and true or false
    if member.online then member.lastSeen = self:Now() end
    return member
end

function OTLGM:SetRosterRankInline180(name, text, state)
    self.rosterRankInline180 = self.rosterRankInline180 or {}
    local key = self:NormalizeName(name or "")
    if key == "" then return end
    if not text or text == "" then self.rosterRankInline180[key] = nil return end
    self.rosterRankInline180[key] = { text = tostring(text), state = tostring(state or "pending"), ts = self:Now() }
end

function OTLGM:GetRosterRankInline180(name)
    local map = self.rosterRankInline180
    local key = self:NormalizeName(name or "")
    local entry = map and map[key] or nil
    if entry and self:Now() - (tonumber(entry.ts) or self:Now()) > 120 then map[key] = nil return nil end
    return entry
end

function OTLGM:TraceRosterRankActionRC4(pending, phase, live, detail)
    self.runtime = self.runtime or {}
    self.runtime.rosterRankTraceRC4 = self.runtime.rosterRankTraceRC4 or {}
    local row = {
        ts = self:Now(), operationId = pending and pending.operationId180 or nil,
        name = pending and pending.name or (live and live.name) or nil,
        kind = pending and pending.kind or nil, phase = tostring(phase or ""),
        liveRank = live and live.rank or nil, liveRankIndex = live and live.rankIndex or nil,
        rosterIndex = live and live.rosterIndex or (pending and pending.rosterIndex) or nil,
        apiCalls = pending and pending.apiCalls or 0, detail = detail and tostring(detail) or nil,
    }
    table.insert(self.runtime.rosterRankTraceRC4, 1, row)
    while table.getn(self.runtime.rosterRankTraceRC4) > 24 do table.remove(self.runtime.rosterRankTraceRC4) end
    return row
end

local function SafeTraceRosterRankAction180(owner, pending, phase, live, detail)
    if not owner or type(owner.TraceRosterRankActionRC4) ~= "function" then return false end
    local ok, result = pcall(owner.TraceRosterRankActionRC4, owner, pending, phase, live, detail)
    if not ok and owner.RecordInternalIssueRC3 then pcall(owner.RecordInternalIssueRC3, owner, "Roster/RANK_TRACE", result) end
    return ok
end

function OTLGM:BeginRosterAction180(kind, name, publicNote, officerNote, liveEntry)
    local member = name and self:GetMember(name) or nil
    local normalizedKind = tostring(kind or "ACTION")
    liveEntry = liveEntry or (normalizedKind ~= "NOTE" and self:GetLiveRosterEntry180(name) or nil)
    self.rosterActionPending180 = {
        kind = normalizedKind,
        name = tostring(name or ""),
        publicNote = normalizedKind == "NOTE" and self:CanEditPublicNotes() and tostring(publicNote or "") or nil,
        officerNote = normalizedKind == "NOTE" and self:CanEditOfficerNotes() and tostring(officerNote or "") or nil,
        initialRankIndex = liveEntry and tonumber(liveEntry.rankIndex) or member and tonumber(member.rankIndex) or nil,
        initialRankName = liveEntry and tostring(liveEntry.rank or "") or member and tostring(member.rank or "") or "",
        rosterIndex = liveEntry and liveEntry.rosterIndex or member and member.rosterIndex or nil,
        targetGuid = member and member.guid or nil,
        guildName = GetGuildInfo and (GetGuildInfo("player")) or "",
        startedAt = self:Now(),
        nextCheckAt = self:Now(),
        targeted180 = normalizedKind ~= "NOTE",
    }
    self.ui.rosterSelectedName = name
    self:PersistRosterPosition180()
    if normalizedKind ~= "NOTE" then self:SetRosterRankInline180(name, nil) end
    local details = self.ui and self.ui.rosterDetails
    if details then
        if normalizedKind == "NOTE" then details.saveNotes:Hide() end
        UI:SetEnabled(details.promote, false, "Waiting for server roster confirmation.")
        UI:SetEnabled(details.demote, false, "Waiting for server roster confirmation.")
        if details.approveLion then UI:SetEnabled(details.approveLion, false, "Waiting for server roster confirmation.") end
        if details.muteGuest then UI:SetEnabled(details.muteGuest, false, "Waiting for server roster confirmation.") end
        details.pendingText:SetText(normalizedKind == "APPROVE_LION" and "Promoting 1/2…" or "Waiting for server roster…")
        details.pendingText:Show()
    end
    if self.WakeScheduler180 then self:WakeScheduler180("roster-action") end
end

function OTLGM:RequestTargetedRosterRefresh180(force)
    local pending = self.rosterActionPending180
    if not pending or not pending.targeted180 then return false end
    local now = self.GetPreciseTime180 and self:GetPreciseTime180() or self:Now()
    if force or not pending.lastRosterRequestAt or now - pending.lastRosterRequestAt >= 0.75 then
        pending.lastRosterRequestAt = now
        if SetGuildRosterShowOffline then pcall(SetGuildRosterShowOffline, true) end
        if GuildRoster then pcall(GuildRoster) end
    end
    return self:ConfirmRosterActionUpdate180(true)
end

function OTLGM:StartRosterRankAction180(kind, memberOrName, displayAction180, expectedRankName180, requiredInitialRankIndex180)
    kind = tostring(kind or "")
    if kind ~= "PROMOTE" and kind ~= "DEMOTE" then return false end
    if self.rosterActionPending180 then
        if self.SetStatus then self:SetStatus("A guild rank action is already waiting for server confirmation.") end
        return false
    end
    local name = type(memberOrName) == "table" and memberOrName.name or memberOrName
    local live = self:GetLiveRosterEntry180(name)
    if not live or live.rankIndex == nil then
        self:Notify("Guild Rank Unavailable", "The selected member could not be read from the live guild roster.")
        return false
    end
    if requiredInitialRankIndex180 ~= nil and tonumber(live.rankIndex) ~= tonumber(requiredInitialRankIndex180) then
        if self.SetStatus then self:SetStatus("Guild rank changed before the action could start. Refresh the member and retry.") end
        return false
    end
    if displayAction180 == "MUTE_GUEST" and NormalizeGuildRankLabel180(live.rank) ~= "guest" then
        if self.SetStatus then self:SetStatus("Mute Guest stopped because the live target is no longer 1 - Guest.") end
        return false
    end
    local member = self:ApplyTargetedRosterEntry180(live) or self:GetMember(name)
    local allowed, reason = self:CanUseOfficerActionForMember170(kind, member or name)
    if not allowed then
        self:Notify(kind == "PROMOTE" and "Promotion Unavailable" or "Demotion Unavailable", reason or "This guild rank action is unavailable.")
        return false
    end
    self:BeginRosterAction180(kind, live.name, nil, nil, live)
    local pending = self.rosterActionPending180
    -- Presentation/expectation metadata must be attached before the one
    -- non-idempotent guild API call.  A very fast/synchronous roster callback
    -- must never resolve the action before Mute Guest has been identified.
    pending.displayAction180 = displayAction180
    pending.expectedRankName = expectedRankName180
    pending.phase = 1
    pending.operationId180 = tostring(self:Now()) .. ":" .. tostring(live.name) .. ":" .. kind
    SafeTraceRosterRankAction180(self, pending, "api-1-ready", live, kind)
    local ok
    if kind == "PROMOTE" then ok = self:PromoteMember(live.name, { raw180 = true, verifiedMember180 = member })
    else ok = self:DemoteMember(live.name, { raw180 = true, verifiedMember180 = member }) end
    if not ok then
        self:ResolveRosterAction180(false, "The game client rejected the guild rank request.", true)
        return false
    end
    pending.apiCalls = 1
    -- The rank API request is already non-idempotent and accepted at this
    -- point. A follow-up refresh helper must never turn that successful first
    -- step into a visible Lua error; roster events + the compatibility state
    -- machine still provide independent confirmation/recovery.
    if self.RequestTargetedRosterRefresh180 then
        local refreshOk, refreshProblem = pcall(self.RequestTargetedRosterRefresh180, self, true)
        if not refreshOk and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Roster/QUICK_LION_FIRST_REFRESH", refreshProblem) end
    end
    return true
end

function OTLGM:GetQuickLionAvailability180(member)
    member = type(member) == "table" and member or self:GetMember(member)
    if not member then return false, "live target missing" end
    if self.rosterActionPending180 then return false, "operation pending" end
    local live = self:GetLiveRosterEntry180(member.name, member.rosterIndex)
    if not live or live.rankIndex == nil then return false, "live target missing" end
    if NormalizeGuildRankLabel180(live.rank) ~= "guest" then return false, "target is not 1 - Guest" end
    local path, pathReason = self:ResolveGuestLionRankPath180()
    if not path then return false, tostring(pathReason or "live rank path unavailable") end
    if tonumber(live.rankIndex) ~= tonumber(path.guestIndex) then return false, "live Guest rank does not match the verified guild-rank catalog" end
    local allowed, permissionReason = self:CanUseOfficerActionForMember170("PROMOTE", self:ApplyTargetedRosterEntry180(live) or member)
    if not allowed then return false, "permission denied: " .. tostring(permissionReason or "promotion unavailable") end
    return true, nil, live, path
end

function OTLGM:CanStartQuickLion180(member)
    local allowed = self:GetQuickLionAvailability180(member)
    return allowed and true or false
end

function OTLGM:GetMuteGuestAvailability180(member)
    member = type(member) == "table" and member or self:GetMember(member)
    if not member then return false, "live target missing" end
    if self.rosterActionPending180 then return false, "operation pending" end
    local live = self:GetLiveRosterEntry180(member.name, member.rosterIndex)
    if not live or live.rankIndex == nil then return false, "live target missing" end
    if NormalizeGuildRankLabel180(live.rank) ~= "guest" then return false, "target is not 1 - Guest" end
    local path, pathReason = self:ResolveGuestLionRankPath180()
    if not path then return false, pathReason or "rank path unavailable" end
    if tonumber(live.rankIndex) ~= tonumber(path.guestIndex) then return false, "live Guest rank does not match the verified guild-rank catalog" end
    local allowed, permissionReason = self:CanUseOfficerActionForMember170("PROMOTE", self:ApplyTargetedRosterEntry180(live) or member)
    if not allowed then return false, permissionReason or "rank action unavailable" end
    return true, nil, live, path
end

function OTLGM:StartMuteGuest180(member)
    local allowed, reason, live, path = self:GetMuteGuestAvailability180(member)
    if not allowed then
        if self.SetStatus then self:SetStatus("Mute Guest unavailable: " .. tostring(reason or "unknown live-state reason")) end
        return false
    end
    -- OctoWoW places - Muted - immediately above 1 - Guest.  The only safe
    -- server API is the standard one-step GuildPromote; we expose it as a
    -- disciplinary action only after verifying the exact live rank path.
    return self:StartRosterRankAction180("PROMOTE", live, "MUTE_GUEST", path and path.mutedName or "- Muted -", path and path.guestIndex)
end

function OTLGM:StartApproveToLion180(member)
    member = type(member) == "table" and member or self:GetMember(member)
    if not member or self.rosterActionPending180 then return false end
    local live = self:GetLiveRosterEntry180(member.name, member.rosterIndex)
    if not live or live.rankIndex == nil then return false end

    local retry = self.rosterQuickLionRetry180
    local retrying = retry and self:NormalizeName(retry.name) == self:NormalizeName(live.name)
        and NormalizeGuildRankLabel180(live.rank) == "muted"
    if retrying then
        local allowed, reason = self:CanUseOfficerActionForMember170("PROMOTE", self:ApplyTargetedRosterEntry180(live) or member)
        if not allowed then
            if self.SetStatus then self:SetStatus(reason or "Final promotion step is unavailable.") end
            return false
        end
        self:BeginRosterAction180("APPROVE_LION", live.name, nil, nil, live)
        local pending = self.rosterActionPending180
        pending.path180 = {
            guestIndex = tonumber(retry.guestIndex), guestName = "1 - Guest",
            mutedIndex = tonumber(live.rankIndex), mutedName = tostring(live.rank or "- Muted -"),
            lionName = "2 - Lion",
        }
        pending.phase = 2
        pending.initialGuestRankIndex180 = pending.path180.guestIndex
        pending.expectedRankName = pending.path180.lionName
        pending.finalRankName = pending.path180.lionName
        pending.operationId180 = tostring(self:Now()) .. ":" .. tostring(live.name) .. ":QUICK2"
        pending.apiCalls = 0
        SafeTraceRosterRankAction180(self, pending, "quick-retry-final-ready", live, "Muted -> Lion")
        self.rosterQuickLionRetry180 = nil
        local promoteOk, promoteAccepted = pcall(self.PromoteMember, self, live.name, { raw180 = true, verifiedMember180 = live })
        if not promoteOk or not promoteAccepted then
            self.rosterQuickLionRetry180 = retry
            if not promoteOk and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Roster/QUICK_LION_RETRY_API", promoteAccepted) end
            self:ResolveRosterAction180(false, "The final standard promotion request was rejected by the game client.", true)
            return false
        end
        pending.apiCalls = 1
        if self.RequestTargetedRosterRefresh180 then
            local refreshOk, refreshProblem = pcall(self.RequestTargetedRosterRefresh180, self, true)
            if not refreshOk and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Roster/QUICK_LION_RETRY_REFRESH", refreshProblem) end
        end
        return true
    end

    local available, pathReason, availableLive, path = self:GetQuickLionAvailability180(member)
    if not available then
        if self.SetStatus then self:SetStatus("Promote to 2 - Lion unavailable: " .. tostring(pathReason or "unknown live-state reason")) end
        return false
    end
    live = availableLive
    self.rosterQuickLionRetry180 = nil
    self:BeginRosterAction180("APPROVE_LION", live.name, nil, nil, live)
    local pending = self.rosterActionPending180
    pending.path180 = path
    pending.phase = 1
    pending.initialGuestRankIndex180 = tonumber(live.rankIndex)
    pending.expectedRankName = path.mutedName
    pending.finalRankName = path.lionName
    pending.operationId180 = tostring(self:Now()) .. ":" .. tostring(live.name) .. ":QUICK1"
    SafeTraceRosterRankAction180(self, pending, "quick-start", live, "Guest -> Muted -> Lion")
    local promoteOk, promoteAccepted = pcall(self.PromoteMember, self, live.name, { raw180 = true, verifiedMember180 = live })
    if not promoteOk or not promoteAccepted then
        if not promoteOk and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Roster/QUICK_LION_FIRST_API", promoteAccepted) end
        self:ResolveRosterAction180(false, "The first standard promotion request was rejected by the game client.", true)
        return false
    end
    pending.apiCalls = 1
    if self.RequestTargetedRosterRefresh180 then
        local refreshOk, refreshProblem = pcall(self.RequestTargetedRosterRefresh180, self, true)
        if not refreshOk and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Roster/QUICK_LION_FIRST_REFRESH", refreshProblem) end
    end
    return true
end

function OTLGM:IsRosterActionConfirmed180()
    local pending = self.rosterActionPending180
    if not pending then return false end
    local live = self:GetLiveRosterEntry180(pending.name, pending.rosterIndex)
    if not live then return false end
    if pending.kind == "NOTE" then
        if pending.publicNote ~= nil and tostring(live.note or "") ~= pending.publicNote then return false end
        if pending.officerNote ~= nil and tostring(live.officerNote or "") ~= pending.officerNote then return false end
        return true
    end
    if pending.kind == "PROMOTE" or pending.kind == "DEMOTE" then
        local changed = tostring(live.rank or "") ~= tostring(pending.initialRankName or "")
            or tonumber(live.rankIndex) ~= tonumber(pending.initialRankIndex)
        if not changed then return false end
        if pending.expectedRankName and pending.expectedRankName ~= "" then
            return NormalizeGuildRankLabel180(live.rank) == NormalizeGuildRankLabel180(pending.expectedRankName)
        end
        return true
    end
    return false
end

-- Execute the second Guest -> Muted -> Lion step as a recoverable state
-- transition.  The keyed scheduler is only the preferred wake-up; ProcessRosterAction180
-- can call the same helper if a scheduler callback is removed by an exception or
-- a UI replacement delays the task.  Phase 2 is written immediately after the
-- client accepts GuildPromote, before any diagnostic/refresh side effect, so the
-- same API request cannot be emitted twice by two recovery paths.
function OTLGM:TryQuickLionFinal180(operationId, source)
    local active = self.rosterActionPending180
    if not active or active.kind ~= "APPROVE_LION" or active.phase ~= 15 then return false end
    if operationId and active.operationId180 ~= operationId then return false end
    local preciseNow = self.GetPreciseTime180 and self:GetPreciseTime180() or self:Now()
    if active.finalStepDue180 and preciseNow < (tonumber(active.finalStepDue180) or preciseNow) then return false end
    if active.finalStepInFlight180 then return false end

    local function StopAtMuted180(message, target)
        active.finalStepInFlight180 = nil
        self.rosterQuickLionRetry180 = {
            name = active.name, rosterIndex = target and target.rosterIndex or active.rosterIndex,
            guestIndex = active.initialGuestRankIndex180, ts = self:Now(),
        }
        self:ResolveRosterAction180(false, message, true)
        return false
    end

    local target = self:GetLiveRosterEntry180(active.name, active.rosterIndex)
    if not target or NormalizeGuildRankLabel180(target.rank) ~= "muted" then
        active.finalStepInFlight180 = nil
        active.finalStepDue180 = preciseNow + 1
        active.nextCheckAt = self:Now() + 1
        if self.RequestTargetedRosterRefresh180 then pcall(self.RequestTargetedRosterRefresh180, self, true) end
        return false
    end
    local targetMember = self:ApplyTargetedRosterEntry180(target) or self:GetMember(active.name)
    local canPromote, blocked = self:CanUseOfficerActionForMember170("PROMOTE", targetMember or active.name)
    if not canPromote then
        return StopAtMuted180("First step completed. Current rank: " .. tostring(target.rank or "- Muted -") .. ". " .. tostring(blocked or "Retry the final step."), target)
    end

    active.initialRankIndex = target.rankIndex
    active.initialRankName = target.rank
    active.rosterIndex = target.rosterIndex
    active.startedAt = self:Now()
    active.nextCheckAt = self:Now()
    -- Mark the one truly non-idempotent section only immediately before the
    -- GuildPromote call.  Errors in live-roster/permission preparation therefore
    -- cannot strand the state machine forever with an in-flight flag set.
    active.finalStepInFlight180 = true
    local callOk, accepted = pcall(self.PromoteMember, self, active.name, { raw180 = true, verifiedMember180 = targetMember })
    if not callOk or not accepted then
        return StopAtMuted180("First step completed. Current rank: " .. tostring(target.rank or "- Muted -") .. ". Retry the final step.", target)
    end
    -- No fallible side effect may occur between a successful GuildPromote and
    -- this phase transition; it is the duplicate-request guard.
    active.phase = 2
    active.finalStepInFlight180 = nil
    active.finalStepDue180 = nil
    active.nextCheckAt = self:Now() + 1
    active.apiCalls = (tonumber(active.apiCalls) or 1) + 1
    if self.TraceRosterRankActionRC4 then pcall(self.TraceRosterRankActionRC4, self, active, "api-2-sent", target, "second GuildPromote accepted via " .. tostring(source or "recovery")) end
    if self.RequestTargetedRosterRefresh180 then pcall(self.RequestTargetedRosterRefresh180, self, true) end
    return true
end

function OTLGM:ConfirmRosterActionUpdate180()
    local pending = self.rosterActionPending180
    if not pending then return false end
    if pending.kind == "NOTE" then
        if not self:IsRosterActionConfirmed180() then return false end
        self:ResolveRosterAction180(true)
        return true
    end
    local currentGuild = GetGuildInfo and (GetGuildInfo("player")) or ""
    if tostring(currentGuild or "") ~= tostring(pending.guildName or "") then
        self:ResolveRosterAction180(false, "The guild changed while the rank action was running.", true)
        return false
    end
    local live = self:GetLiveRosterEntry180(pending.name, pending.rosterIndex)
    if not live or live.rankIndex == nil then return false end
    SafeTraceRosterRankAction180(self, pending, "roster-update", live, "live confirmation")
    local member = self:ApplyTargetedRosterEntry180(live)
    if not member or (pending.targetGuid and member.guid and pending.targetGuid ~= member.guid) then
        self:ResolveRosterAction180(false, "The target member could no longer be verified.", true)
        return false
    end
    if pending.kind == "PROMOTE" or pending.kind == "DEMOTE" then
        local changed = tostring(live.rank or "") ~= tostring(pending.initialRankName or "")
            or tonumber(live.rankIndex) ~= tonumber(pending.initialRankIndex)
        if changed then
            if pending.expectedRankName and pending.expectedRankName ~= ""
                and NormalizeGuildRankLabel180(live.rank) ~= NormalizeGuildRankLabel180(pending.expectedRankName) then
                self:ResolveRosterAction180(false, "Rank changed to " .. tostring(live.rank or live.rankIndex) .. " instead of the verified target " .. tostring(pending.expectedRankName) .. ". No follow-up action was sent.", true)
                return false
            end
            self:ResolveRosterAction180(true)
            return true
        end
        return false
    end
    if pending.kind ~= "APPROVE_LION" then return false end

    local normalizedRank = NormalizeGuildRankLabel180(live.rank)
    local path = pending.path180 or {}
    if pending.phase == 1 then
        if normalizedRank == "lion" then
            self.rosterQuickLionRetry180 = nil
            pending.finalRankName = tostring(live.rank or "2 - Lion")
            self:ResolveRosterAction180(true)
            return true
        end
        if normalizedRank == "muted" then
            -- The first promotion has been confirmed by the live roster.  Do not
            -- issue the second GuildPromote from the same roster-update callback:
            -- Vanilla/OctoWoW can silently discard that back-to-back request.
            -- Keep the operation bound to the exact member even if the officer
            -- clicks elsewhere while the server is settling the first change.
            local allowed, reason = self:CanUseOfficerActionForMember170("PROMOTE", member)
            if not allowed then
                self.rosterQuickLionRetry180 = {
                    name = pending.name, rosterIndex = live.rosterIndex,
                    guestIndex = pending.initialGuestRankIndex180, ts = self:Now(),
                }
                self:ResolveRosterAction180(false, "First step completed. Current rank: " .. tostring(live.rank or "- Muted -") .. ". " .. tostring(reason or "Retry the final step."), true)
                return false
            end
            pending.phase = 15
            SafeTraceRosterRankAction180(self, pending, "first-step-confirmed", live, "Muted confirmed; waiting before recoverable second API call")
            pending.initialRankIndex = live.rankIndex
            pending.initialRankName = live.rank
            pending.rosterIndex = live.rosterIndex
            pending.expectedRankName = path.lionName or "2 - Lion"
            pending.finalRankName = pending.expectedRankName
            pending.startedAt = self:Now()
            pending.nextCheckAt = self:Now() + 2
            pending.finalStepDue180 = (self.GetPreciseTime180 and self:GetPreciseTime180() or self:Now()) + 2
            if self.ui and self.ui.rosterDetails and self.ui.rosterDetails.pendingText then
                self.ui.rosterDetails.pendingText:SetText("Promoting 2/2…")
            end
            if self.CancelTask180 then self:CancelTask180("roster-quick-lion-final") end
            if self.ScheduleAfter180 then
                local operationId = pending.operationId180
                self:ScheduleAfter180("roster-quick-lion-final", 2.0, function(owner)
                    if owner.TryQuickLionFinal180 then owner:TryQuickLionFinal180(operationId, "scheduled wake") end
                end, -2)
            end
            -- No hard dependency on the one-shot callback: ProcessRosterAction180
            -- owns the same finalStepDue180 and will recover it if the task fails,
            -- is removed, or a third-party UI delays scheduler execution.
            if self.WakeScheduler180 then self:WakeScheduler180("roster-quick-lion-final") end
            return false
        end
        if normalizedRank ~= "guest" or tonumber(live.rankIndex) ~= tonumber(pending.initialRankIndex) then
            self:ResolveRosterAction180(false, "Stopped at " .. tostring(live.rank or live.rankIndex) .. ". No second promotion was sent.", true)
        end
        return false
    end

    if pending.phase == 15 then
        -- Waiting for the short server-settle delay before the exact-target
        -- second promotion. Muted is the only valid intermediate live state.
        if normalizedRank == "lion" then
            self.rosterQuickLionRetry180 = nil
            self:ResolveRosterAction180(true)
            return true
        end
        if normalizedRank ~= "muted" then
            self:ResolveRosterAction180(false, "Promotion stopped at the unexpected live rank " .. tostring(live.rank or live.rankIndex) .. ".", true)
        end
        return false
    end

    if pending.phase == 2 then
        if normalizedRank == "lion" then
            self.rosterQuickLionRetry180 = nil
            self:ResolveRosterAction180(true)
            return true
        end
        if normalizedRank ~= "muted" then
            self:ResolveRosterAction180(false, "Promotion stopped at the unexpected live rank " .. tostring(live.rank or live.rankIndex) .. ".", true)
        end
    end
    return false
end

function OTLGM:ResolveRosterAction180(success, reason, inlineOnly)
    local pending = self.rosterActionPending180
    if not pending then return end
    if pending.kind == "APPROVE_LION" and self.CancelTask180 then self:CancelTask180("roster-quick-lion-final") end
    local finalLive = pending.targeted180 and self:GetLiveRosterEntry180(pending.name, pending.rosterIndex) or nil
    SafeTraceRosterRankAction180(self, pending, success and "resolved-success" or "resolved-failure", finalLive, reason)
    self.rosterActionPending180 = nil
    local isRankAction = pending.kind == "PROMOTE" or pending.kind == "DEMOTE" or pending.kind == "APPROVE_LION"
    if success then
        if isRankAction then
            local actor = UnitName and UnitName("player") or "You"
            if pending.kind == "APPROVE_LION" then
                self:RememberGuildAction("PROMOTE", pending.name, actor, "1 - Guest → 2 - Lion")
                self:SetRosterRankInline180(pending.name, "Promoted to " .. tostring(pending.finalRankName or "2 - Lion") .. ".", "success")
            else
                self:RememberGuildAction(pending.kind, pending.name, actor, pending.displayAction180 == "MUTE_GUEST" and "1 - Guest → - Muted -" or "live targeted confirmation")
                local live = self:GetLiveRosterEntry180(pending.name, pending.rosterIndex)
                self:SetRosterRankInline180(pending.name, pending.displayAction180 == "MUTE_GUEST" and ("Muted: " .. tostring(live and live.rank or "- Muted -") .. ".") or ("Live rank confirmed: " .. tostring(live and live.rank or "updated") .. "."), "success")
            end
        end
        if self.ShowToast then
            local message = pending.kind == "NOTE" and "Notes updated from the live roster."
                or pending.kind == "APPROVE_LION" and "Guest promoted to 2 - Lion."
                or pending.displayAction180 == "MUTE_GUEST" and "Guest moved to - Muted -."
                or "Guild rank action confirmed."
            self:ShowToast(message, "success")
        end
    else
        if isRankAction then
            local detail = tostring(reason or "")
            local currentAt = string.find(detail, "Current rank", 1, true)
            local short = currentAt and string.sub(detail, currentAt)
                or pending.kind == "APPROVE_LION" and "Rank action stopped. Check the selected member."
                or "Rank action was not confirmed."
            if string.len(short) > 92 then short = string.sub(short, 1, 89) .. "..." end
            self:SetRosterRankInline180(pending.name, short, "error")
            self.runtime = self.runtime or {}
            self.runtime.lastRosterActionDetail180 = detail ~= "" and detail or short
        else
            -- C5-R4: never interrupt roster work with a blocking timeout modal.
            -- Notes and other non-rank updates use the same compact status path.
            if self.SetStatus then self:SetStatus(reason or "The roster update was not confirmed. Recheck the selected member before retrying.") end
        end
    end
    if self.RefreshRosterTarget180 then
        local refreshOk, refreshProblem = pcall(self.RefreshRosterTarget180, self, pending.name)
        if not refreshOk and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Roster/ACTION_PRESENTATION", refreshProblem) end
    elseif self.ui and self.ui.rosterTable and self.RefreshRosterPage then
        local refreshOk, refreshProblem = pcall(self.RefreshRosterPage, self)
        if not refreshOk and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Roster/ACTION_PRESENTATION", refreshProblem) end
    end
end

function OTLGM:ProcessRosterAction180()
    local pending = self.rosterActionPending180
    local now = self:Now()
    if pending then
        if pending.kind == "NOTE" then
            if now - (tonumber(pending.startedAt) or now) >= 12 then
                self:ResolveRosterAction180(false, "No GUILD_ROSTER_UPDATE was received within twelve seconds. Check the standard guild roster before retrying.")
            end
            return
        end
        if pending.kind == "APPROVE_LION" and pending.phase == 15 and self.TryQuickLionFinal180 then
            local preciseNow = self.GetPreciseTime180 and self:GetPreciseTime180() or now
            if preciseNow >= (tonumber(pending.finalStepDue180) or preciseNow) then
                local finalOk, finalProblem = pcall(self.TryQuickLionFinal180, self, pending.operationId180, "state-machine recovery")
                if not finalOk then
                    -- A broken permission/roster helper must not abort the whole
                    -- action processor forever. Keep a bounded retry and allow
                    -- the normal 15-second timeout below to resolve the state.
                    pending.finalStepInFlight180 = nil
                    pending.finalStepDue180 = preciseNow + 1
                    pending.nextCheckAt = now + 1
                    if self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Roster/QUICK_LION_RECOVERY", finalProblem) end
                end
                pending = self.rosterActionPending180
                if not pending then return end
            end
        end
        if now >= (tonumber(pending.nextCheckAt) or 0) then
            pending.nextCheckAt = now + 1
            if self.RequestTargetedRosterRefresh180 then
                local refreshOk, refreshProblem = pcall(self.RequestTargetedRosterRefresh180, self, false)
                if not refreshOk and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Roster/ACTION_REFRESH", refreshProblem) end
            end
        end
        local elapsed = now - (tonumber(pending.startedAt) or now)
        if elapsed >= 3 and self.ui and self.ui.rosterDetails and self.ui.rosterDetails.pendingText then
            self.ui.rosterDetails.pendingText:SetText("Waiting for guild roster confirmation…")
        end
        if elapsed >= 15 then
            local live = self:GetLiveRosterEntry180(pending.name, pending.rosterIndex)
            local currentRank = live and tostring(live.rank or live.rankIndex) or tostring(pending.initialRankName or "unknown")
            local message
            if pending.kind == "APPROVE_LION" and (pending.phase == 2 or pending.phase == 15) and live and NormalizeGuildRankLabel180(live.rank) == "muted" then
                self.rosterQuickLionRetry180 = {
                    name = pending.name, rosterIndex = live.rosterIndex,
                    guestIndex = pending.initialGuestRankIndex180, ts = self:Now(),
                }
                message = pending.phase == 15
                    and ("Final promotion request could not be issued. Current rank: " .. currentRank .. ". Retry final step.")
                    or ("Final step was not confirmed. Current rank: " .. currentRank .. ". Retry final step.")
            else
                message = "Server confirmation is still pending. Current rank: " .. currentRank .. ". Recheck before retrying."
            end
            self:ResolveRosterAction180(false, message, true)
        end
        return
    end
end


local function CreateRosterTableRow(owner, tablePanel, index)
    local captured = index
    local row = UI:TableRow(tablePanel, 552, 27, function(button)
        if not button.otlMemberName then return end
        if arg1 == "RightButton" then owner:OpenPlayerMenu(button.otlMemberName, button)
        else owner:SelectRosterMember(button.otlMemberName) end
    end)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetPoint("TOPLEFT", tablePanel, "TOPLEFT", 8, -40 - ((captured - 1) * ROW_HEIGHT))
    row.leadershipAccent = row:CreateTexture(nil, "ARTWORK")
    row.leadershipAccent:SetTexture(C.gold[1], C.gold[2], C.gold[3], 1)
    row.leadershipAccent:SetPoint("TOPLEFT", row, "TOPLEFT", 2, -2)
    row.leadershipAccent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 2, 2)
    row.leadershipAccent:SetWidth(4)
    row.leadershipAccent:Hide()
    row.otlEven183 = math.mod(captured, 2) == 0 and true or nil
    row.rankIcon = row:CreateTexture(nil, "ARTWORK")
    row.rankIcon:SetWidth(16)
    row.rankIcon:SetHeight(16)
    row.rankIcon:SetPoint("LEFT", row, "LEFT", 7, 0)
    row.onlineDot = row:CreateTexture(nil, "OVERLAY")
    row.onlineDot:SetTexture(C.green[1], C.green[2], C.green[3], 1)
    row.onlineDot:SetWidth(5)
    row.onlineDot:SetHeight(18)
    row.onlineDot:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.nameText = Label(row, "", "GameFontNormalSmall", 29, -7, 107, "LEFT")
    row.levelText = Label(row, "", "GameFontNormalSmall", 140, -7, 36, "CENTER")
    row.classText = Label(row, "", "GameFontNormalSmall", 176, -7, 70, "LEFT")
    row.rankText = Label(row, "", "GameFontNormalSmall", 246, -7, 94, "LEFT")
    row.zoneText = Label(row, "", "GameFontNormalSmall", 340, -7, 102, "LEFT")
    row.lastText = Label(row, "", "GameFontNormalSmall", 442, -7, 84, "LEFT")
    row.addonIcon = row:CreateTexture(nil, "ARTWORK")
    row.addonIcon:SetTexture("Interface\\Icons\\INV_Misc_Rune_01")
    row.addonIcon:SetWidth(16)
    row.addonIcon:SetHeight(16)
    row.addonIcon:SetPoint("CENTER", row, "LEFT", 539, 0)
    row:EnableMouseWheel(true)
    row:SetScript("OnMouseWheel", function() owner:ScrollRosterShell180(-((tonumber(arg1) or 0) * 3)) end)
    row.otlBaseEnter = row:GetScript("OnEnter")
    row.otlBaseLeave = row:GetScript("OnLeave")
    row:SetScript("OnEnter", function()
        if this.otlBaseEnter then this.otlBaseEnter() end
        owner:ShowRosterRowTooltip180(this)
    end)
    row:SetScript("OnLeave", function()
        if this.otlBaseLeave then this.otlBaseLeave() end
        if GameTooltip then GameTooltip:Hide() end
    end)
    row:Hide()
    tablePanel.rows[captured] = row
    return row
end

local function EnsureRosterRowCapacity(owner, capacity)
    local tablePanel = owner.ui and owner.ui.rosterTable
    if not tablePanel then return 0 end
    capacity = math.max(MIN_ROW_COUNT, math.floor(tonumber(capacity) or MIN_ROW_COUNT))
    local index
    for index = table.getn(tablePanel.rows) + 1, capacity do
        CreateRosterTableRow(owner, tablePanel, index)
    end
    owner.ui.rosterVisibleCapacity180 = capacity
    return capacity
end

function OTLGM:GetLiveRosterNotes180(member)
    if not member then return "", "", nil, false end
    local rosterIndex = tonumber(member.rosterIndex)
    local liveName, note, officerNote
    if rosterIndex and GetGuildRosterInfo then
        liveName, _, _, _, _, _, note, officerNote = GetGuildRosterInfo(rosterIndex)
        if not liveName or self:NormalizeName(liveName) ~= self:NormalizeName(member.name) then
            rosterIndex = nil
        end
    end
    if not rosterIndex and self.FindRosterIndex then rosterIndex = self:FindRosterIndex(member.name) end
    if rosterIndex and GetGuildRosterInfo then
        liveName, _, _, _, _, _, note, officerNote = GetGuildRosterInfo(rosterIndex)
    end
    if not liveName or self:NormalizeName(liveName) ~= self:NormalizeName(member.name) then
        return tostring(member.note or ""), tostring(member.officerNote or ""), nil, false
    end
    note = tostring(note or "")
    officerNote = tostring(officerNote or "")
    if not (self.CanViewOfficerNotes and self:CanViewOfficerNotes()) then officerNote = "" end
    member.rosterIndex = rosterIndex
    local db = self:GetGuildDB()
    local pendingKey = self.NormalizeName and self:NormalizeName(member.name) or string.lower(tostring(member.name or ""))
    local pending = db and db.pendingActions and db.pendingActions[pendingKey]
    if not pending or pending.kind ~= "NOTE" then
        member.note = note
        if self.CanViewOfficerNotes and self:CanViewOfficerNotes() then member.officerNote = officerNote end
    end
    return note, officerNote, rosterIndex, true
end

function OTLGM:BuildGuildInviteModal180()
    if self.ui.guildInviteModal180 then return end
    local modal = UI:Modal(self.ui.modalHost, 430, 238)
    modal:SetPoint("CENTER", self.ui.modalHost, "CENTER", 0, 0)
    modal.title = Label(modal, "Invite to Guild", "GameFontNormalLarge", 20, -18, 320, "LEFT")
    modal.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    modal.help = Label(modal, "Enter a character name. The invitation uses your normal guild permissions, just like inviting through the game interface.", "GameFontNormalSmall", 20, -52, 390, "LEFT")
    modal.help:SetHeight(38)
    if modal.help.SetJustifyV then modal.help:SetJustifyV("TOP") end
    modal.name = UI:EditBox(modal, 390, 32, { placeholder = "Character name", maxLetters = 24 })
    modal.name:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -100)
    modal.validation = Label(modal, "", "GameFontNormalSmall", 20, -140, 390, "LEFT")
    modal.validation:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.cancel = UI:Button(modal, "Cancel", 100, 30, function() OTLGM:CloseShellModal() end, "secondary")
    modal.cancel:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -128, 18)
    modal.submit180 = function()
        local value = modal.name:GetText() or ""
        value = string.gsub(value, "^%s+", "")
        value = string.gsub(value, "%s+$", "")
        local ok, message = OTLGM:InviteGuildCandidate180(value, "roster")
        if not ok then
            modal.validation:SetText(tostring(message or "Invite failed."))
            modal.validation:SetTextColor(C.red[1], C.red[2], C.red[3])
            return false
        end
        modal.name:ClearFocus()
        OTLGM:CloseShellModal()
        if OTLGM.ShowToast then OTLGM:ShowToast("Guild invite sent to " .. value .. ".", "success") end
        return true
    end
    modal.invite = UI:Button(modal, "Invite", 100, 30, function() modal.submit180() end, "primary")
    modal.invite:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -18, 18)
    modal.name:SetScript("OnEnterPressed", function() modal.submit180() end)
    self.ui.guildInviteModal180 = modal
end

function OTLGM:OpenGuildInviteModal180()
    self:BuildGuildInviteModal180()
    local modal = self.ui.guildInviteModal180
    local allowed = self.CanInviteGuildMembersR5 and self:CanInviteGuildMembersR5(true)
    if not allowed then
        modal.validation:SetText("Your current guild rank cannot invite members.")
        modal.validation:SetTextColor(C.red[1], C.red[2], C.red[3])
        UI:SetEnabled(modal.invite, false, "Your guild rank cannot invite members.")
    else
        modal.validation:SetText("Press Enter or click Invite.")
        modal.validation:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        UI:SetEnabled(modal.invite, true)
    end
    modal.name:SetText("")
    self:ShowShellModal(modal)
end

local function BuildRoster(owner, page)
    owner.ui.rosterSearch = UI:SearchBox(page, 244, 30, "Search members...", function(value)
        owner.ui.rosterSearchRuntime180 = value
        owner.ui.rosterOffset = 0
        owner.ui.rosterSearchDirty180 = true
        owner.ui.rosterSearchElapsed180 = 0
        if owner.WakeScheduler180 then owner:WakeScheduler180("ui-debounce:roster") end
    end)
    owner.ui.rosterSearch:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -4)
    UI:SetSearchText(owner.ui.rosterSearch, OTLGM_DB.settings.rosterSearch or "")
    owner.ui.rosterSearch:SetScript("OnKeyDown", function()
        local capacity = math.max(MIN_ROW_COUNT, tonumber(owner.ui.rosterVisibleCapacity180) or MIN_ROW_COUNT)
        if arg1 == "PAGEUP" then owner:ScrollRosterShell180(-capacity)
        elseif arg1 == "PAGEDOWN" then owner:ScrollRosterShell180(capacity) end
    end)
    owner.ui.rosterUpdate = UI:Button(page, "Refresh Roster", 118, 30, function()
        owner:RequestScan("MANUAL")
        owner:ShowToast("Roster refresh requested.", "success")
    end, "utility")
    owner.ui.rosterUpdate:SetPoint("LEFT", owner.ui.rosterSearch, "RIGHT", 8, 0)
    owner.ui.rosterInvite180 = UI:Button(page, "+ Invite", 86, 30, function() owner:OpenGuildInviteModal180() end, "primary")
    owner.ui.rosterInvite180:SetPoint("LEFT", owner.ui.rosterUpdate, "RIGHT", 8, 0)
    owner.ui.rosterFilters = UI:Button(page, "Filters", 82, 30, function() owner:OpenRosterFiltersDrawer() end, "secondary")
    owner.ui.rosterFilters:SetPoint("LEFT", owner.ui.rosterInvite180, "RIGHT", 8, 0)

    owner.ui.rosterQuick = {}
    local quick = { { "ALL", "All" }, { "ONLINE", "Online" }, { "LEADERSHIP", "Leadership" } }
    local index
    for index = 1, table.getn(quick) do
        local captured = index
        local button = UI:FilterChip(page, quick[captured][2], 98, function() owner:SetRosterShellFilter(quick[captured][1]) end)
        button:SetPoint("TOPLEFT", page, "TOPLEFT", (captured - 1) * 106, -42)
        owner.ui.rosterQuick[captured] = button
    end
    owner.ui.rosterActiveChips = {}
    owner.ui.rosterActiveChips.filter = UI:FilterChip(page, "", 138, function() owner:SetRosterShellFilter("ALL") end)
    owner.ui.rosterActiveChips.filter:SetPoint("TOPLEFT", page, "TOPLEFT", 324, -42)
    owner.ui.rosterActiveChips.rank = UI:FilterChip(page, "", 138, function()
        owner.ui.rosterRankFilter = nil
        OTLGM_DB.settings.rosterRankFilter = ""
        owner.ui.rosterOffset = 0
        owner:RefreshRosterPage()
    end)
    owner.ui.rosterActiveChips.rank:SetPoint("LEFT", owner.ui.rosterActiveChips.filter, "RIGHT", 6, 0)
    owner.ui.rosterActiveChips.profession = UI:FilterChip(page, "", 154, function()
        owner.ui.rosterProfessionFilter = nil
        OTLGM_DB.settings.rosterProfessionFilter = ""
        owner.ui.rosterOffset = 0
        owner:RefreshRosterPage()
    end)
    owner.ui.rosterActiveChips.profession:SetPoint("LEFT", owner.ui.rosterActiveChips.rank, "RIGHT", 6, 0)
    owner.ui.rosterActiveChips.filter:Hide()
    owner.ui.rosterActiveChips.rank:Hide()
    owner.ui.rosterActiveChips.profession:Hide()

    owner.ui.rosterSummary = Label(page, "", "GameFontNormalSmall", 0, -84, 572, "LEFT")
    owner.ui.rosterSummary:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    owner.ui.rosterSummary:Hide()
    owner.ui.rosterSummaryChips184 = {}
    local summaryDefs184 = {
        { key = "online", label = "Online", color = C.green },
        { key = "leadership", label = "Leadership", color = C.gold },
        { key = "level60", label = "Level 60", color = C.purple },
        { key = "shown", label = "Shown", color = C.blue },
    }
    local summaryIndex184
    for summaryIndex184 = 1, table.getn(summaryDefs184) do
        local definition184 = summaryDefs184[summaryIndex184]
        local chip184 = UI:Surface(page, "raised", 104, 20)
        chip184.text = UI.Text(chip184, definition184.label .. " 0", "GameFontNormalSmall", "CENTER")
        chip184.text:SetPoint("CENTER", chip184, "CENTER", 0, 0)
        chip184.text:SetWidth(98)
        chip184.text:SetTextColor(definition184.color[1], definition184.color[2], definition184.color[3])
        if chip184.SetBackdropBorderColor then chip184:SetBackdropBorderColor(definition184.color[1], definition184.color[2], definition184.color[3], 0.55) end
        chip184.otlLabel184 = definition184.label
        chip184.otlColor184 = definition184.color
        owner.ui.rosterSummaryChips184[definition184.key] = chip184
    end

    local tablePanel = UI:Card(page, 572, 482, "")
    tablePanel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -106)
    owner.ui.rosterTable = tablePanel
    local headers = {
        { key = "NAME", label = "Name", x = 8, width = 140 },
        { key = "LEVEL", label = "Lvl", x = 148, width = 36 },
        { key = "CLASS", label = "Class", x = 184, width = 70 },
        { key = "RANK", label = "Rank", x = 254, width = 94 },
        { key = nil, label = "Zone", x = 348, width = 102 },
        { key = "LASTONLINE", label = "Last", x = 450, width = 84 },
        { key = nil, label = "", x = 534, width = 26 },
    }
    tablePanel.headers = {}
    for index = 1, table.getn(headers) do
        local captured = index
        local definition = headers[captured]
        local header
        if definition.key then
            header = UI:Button(tablePanel, definition.label, definition.width, 24, function() owner:SetRosterSort(definition.key) end, "tab")
        else
            header = UI:Button(tablePanel, definition.label, definition.width, 24, function() end, "inline")
            UI:SetEnabled(header, false)
        end
        header:SetPoint("TOPLEFT", tablePanel, "TOPLEFT", definition.x, -10)
        if captured == 7 then
            header.icon = header:CreateTexture(nil, "ARTWORK")
            header.icon:SetTexture("Interface\\Icons\\INV_Misc_Rune_01")
            header.icon:SetWidth(15)
            header.icon:SetHeight(15)
            header.icon:SetPoint("CENTER", header, "CENTER", 0, 0)
            header.otlTooltip = "Addon presence"
        end
        tablePanel.headers[captured] = header
    end
    tablePanel:EnableMouse(true)
    tablePanel:EnableMouseWheel(true)
    tablePanel.otlMouseWheelOwner = true
    tablePanel:SetScript("OnMouseWheel", function() owner:ScrollRosterShell180(-((tonumber(arg1) or 0) * 3)) end)
    tablePanel.rows = {}
    for index = 1, MIN_ROW_COUNT do CreateRosterTableRow(owner, tablePanel, index) end
    tablePanel.empty = UI:EmptyState(tablePanel, 430, 130, "No members match", "Clear a filter or update the roster and try again.")
    tablePanel.empty:SetPoint("CENTER", tablePanel, "CENTER", 0, -10)
    tablePanel.empty:Hide()
    tablePanel.previous = UI:Button(tablePanel, "Previous", 78, 25, function()
        owner:ScrollRosterShell180(-math.max(MIN_ROW_COUNT, tonumber(owner.ui.rosterVisibleCapacity180) or MIN_ROW_COUNT))
    end, "utility")
    tablePanel.previous:SetPoint("BOTTOMRIGHT", tablePanel, "BOTTOMRIGHT", -170, 8)
    tablePanel.pageText = Label(tablePanel, "", "GameFontNormalSmall", 412, -486, 58, "CENTER")
    tablePanel.next = UI:Button(tablePanel, "Next", 70, 25, function()
        owner:ScrollRosterShell180(math.max(MIN_ROW_COUNT, tonumber(owner.ui.rosterVisibleCapacity180) or MIN_ROW_COUNT))
    end, "utility")
    tablePanel.next:SetPoint("BOTTOMRIGHT", tablePanel, "BOTTOMRIGHT", -8, 8)
    tablePanel.previous:Hide()
    tablePanel.pageText:Hide()
    tablePanel.next:Hide()
    tablePanel.scrollbar = UI:Scrollbar(tablePanel, 400, function(value)
        if owner.ui.rosterScrollSilent180 then return end
        owner.ui.rosterOffset = math.floor((tonumber(value) or 0) + 0.5)
        owner:PersistRosterPosition180()
        owner:RefreshRosterPage()
    end)
    tablePanel.scrollbar:SetPoint("TOPRIGHT", tablePanel, "TOPRIGHT", -3, -40)
    tablePanel.scrollbar:Hide()

    local details = UI:DetailsPanel(page, 348, 660, "Member Details")
    details:SetPoint("TOPLEFT", page, "TOPLEFT", 584, 0)
    details.hero183 = CreateFrame("Frame", nil, details)
    details.hero183:SetPoint("TOPLEFT", details, "TOPLEFT", 10, -28)
    details.hero183:SetPoint("TOPRIGHT", details, "TOPRIGHT", -10, -28)
    details.hero183:SetHeight(48)
    details.heroBackground183 = details.hero183:CreateTexture(nil, "BACKGROUND")
    details.heroBackground183:SetAllPoints(details.hero183)
    details.heroBackground183:SetTexture(C.raised[1], C.raised[2], C.raised[3], 0.55)
    details.heroAccent183 = details.hero183:CreateTexture(nil, "ARTWORK")
    details.heroAccent183:SetPoint("TOPLEFT", details.hero183, "TOPLEFT", 0, 0)
    details.heroAccent183:SetPoint("BOTTOMLEFT", details.hero183, "BOTTOMLEFT", 0, 0)
    details.heroAccent183:SetWidth(3) details.heroAccent183:SetTexture(C.gold[1], C.gold[2], C.gold[3], 0.9)
    details.classIconFrame183 = UI:Surface(details, "raised", 44, 44)
    details.classIconFrame183:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -31)
    details.classIcon = details.classIconFrame183:CreateTexture(nil, "ARTWORK")
    details.classIcon:SetWidth(36) details.classIcon:SetHeight(36) details.classIcon:SetPoint("CENTER", details.classIconFrame183, "CENTER", 0, 0)
    details.nameText = Label(details, "", "GameFontNormalLarge", 66, -35, 178, "LEFT")
    details.rankText = Label(details, "", "GameFontNormalSmall", 66, -58, 178, "LEFT")
    details.rankText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    details.profile183 = UI:Button(details, "Open Profile", 96, 24, function()
        if details.otlMember and owner.OpenGuildMemberProfile183 then
            owner:OpenGuildMemberProfile183(details.otlMember.name, "roster-button", false)
        elseif owner.OpenMyGuildProfile183 then
            owner:OpenMyGuildProfile183()
        end
    end, "primary")
    details.profile183:SetPoint("TOPRIGHT", details, "TOPRIGHT", -10, -7)
    details.profile183.otlTooltipTitle = "Guild Profile"
    details.profile183.otlTooltip = "The selected member profile normally opens automatically beside Roster. Use this button to reopen it after closing the profile."
    details.statusLabel = Label(details, "STATUS", "GameFontNormalSmall", 14, -86, 150, "LEFT")
    details.statusLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    details.statusText = Label(details, "", "GameFontNormalSmall", 14, -105, 316, "LEFT")
    details.zoneText = Label(details, "", "GameFontNormalSmall", 14, -125, 316, "LEFT")
    details.addonText = Label(details, "", "GameFontNormalSmall", 14, -145, 316, "LEFT")
    details.firstSeenText = Label(details, "", "GameFontNormalSmall", 14, -165, 316, "LEFT")
    details.firstSeenText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    details.identityDivider183 = details:CreateTexture(nil, "ARTWORK")
    details.identityDivider183:SetTexture(C.goldDark[1], C.goldDark[2], C.goldDark[3], 0.7)
    details.identityDivider183:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -178)
    details.identityDivider183:SetPoint("TOPRIGHT", details, "TOPRIGHT", -14, -178)
    details.identityDivider183:SetHeight(1)
    details.professionsLabel = Label(details, "PROFESSIONS", "GameFontNormalSmall", 14, -184, 150, "LEFT")
    details.professionsLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    details.professionsText = Label(details, "", "GameFontNormalSmall", 14, -204, 316, "LEFT")
    details.professionsText:SetHeight(34)
    details.professionsText:SetJustifyV("TOP")
    details.notesLabel = Label(details, "NOTES", "GameFontNormalSmall", 14, -244, 150, "LEFT")
    details.notesLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    details.publicNoteLabel = Label(details, "PUBLIC NOTE", "GameFontNormalSmall", 14, -264, 150, "LEFT")
    details.publicNoteLabel:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    details.publicEdit = MakeNoteEdit(details, 318, 34)
    details.publicEdit:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -272)
    details.publicRead = Label(details, "", "GameFontNormalSmall", 14, -288, 318, "LEFT")
    details.officerNoteLabel = Label(details, "OFFICER NOTE", "GameFontNormalSmall", 14, -324, 150, "LEFT")
    details.officerNoteLabel:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    details.officerEdit = MakeNoteEdit(details, 318, 34)
    details.officerEdit:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -332)
    details.officerRead = Label(details, "", "GameFontNormalSmall", 14, -348, 318, "LEFT")
    details.saveNotes = UI:Button(details, "Save Notes", 110, 28, function()
        local member = details.otlMember
        local active = owner.rosterActionPending180
        if not member or (active and not active.targeted180) then return end
        local publicNote = details.publicEdit:GetText() or ""
        local officerNote = details.officerEdit:GetText() or ""
        if owner:SaveMemberNotes(member.name, publicNote, officerNote) then
            if active and owner.SetStatus then owner:SetStatus("Notes submitted while the rank action continues to wait for the selected member.") end
        end
    end, "primary")
    details.saveNotes:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -370)
    details.saveNotes:Hide()
    details.actionsTitle = Label(details, "ACTIONS", "GameFontNormalSmall", 14, -414, 150, "LEFT")
    details.actionsTitle:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    details.whisper = UI:Button(details, "Whisper", 72, 28, function()
        if details.otlMember then owner:WhisperMember(details.otlMember.name) end
    end, "secondary")
    details.whisper:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -424)
    details.invite = UI:Button(details, "Invite", 64, 28, function()
        if details.otlMember then owner:InviteMemberToGroup(details.otlMember.name) end
    end, "secondary")
    details.invite:SetPoint("LEFT", details.whisper, "RIGHT", 7, 0)
    details.history = UI:Button(details, "History", 70, 28, function()
        if details.otlMember then owner:OpenRosterHistory(details.otlMember.name) end
    end, "utility")
    details.history:SetPoint("LEFT", details.invite, "RIGHT", 7, 0)
    details.more = UI:Button(details, "More", 64, 28, function(button)
        if details.otlMember then owner:OpenPlayerMenu(details.otlMember.name, button) end
    end, "utility")
    details.more:SetPoint("LEFT", details.history, "RIGHT", 7, 0)
    details.promote = UI:Button(details, "Promote", 94, 28, function()
        local member = details.otlMember
        if member and not owner.rosterActionPending180 then owner:StartRosterRankAction180("PROMOTE", member) end
    end, "primary")
    details.promote:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -458)
    details.demote = UI:Button(details, "Demote", 94, 28, function()
        local member = details.otlMember
        if member and not owner.rosterActionPending180 then owner:StartRosterRankAction180("DEMOTE", member) end
    end, "secondary")
    details.demote:SetPoint("LEFT", details.promote, "RIGHT", 8, 0)
    details.approveLion = UI:Button(details, "Promote to 2 - Lion", 196, 28, function()
        local member = details.otlMember
        if member and not owner.rosterActionPending180 then owner:StartApproveToLion180(member) end
    end, "primary")
    details.approveLion:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -492)
    details.approveLion:Hide()
    details.muteGuest = UI:Button(details, "Mute Guest", 108, 28, function()
        local member = details.otlMember
        if member and not owner.rosterActionPending180 then owner:StartMuteGuest180(member) end
    end, "danger")
    details.muteGuest:SetPoint("LEFT", details.approveLion, "RIGHT", 8, 0)
    details.muteGuest:Hide()
    details.pendingText = Label(details, "", "GameFontNormalSmall", 14, -536, 318, "LEFT")
    details.pendingText:SetHeight(34)
    details.pendingText:SetJustifyV("TOP")
    details.pendingText:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    details.historyTitle = Label(details, "RECENT ACTIVITY  •  WHEEL TO SCROLL", "GameFontNormalSmall", 14, -572, 300, "LEFT")
    details.historyTitle:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    details.historyRows = {}
    for index = 1, 4 do
        local captured = index
        local line = Label(details, "", "GameFontNormalSmall", 14, -592 - ((captured - 1) * 17), 318, "LEFT")
        line:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        details.historyRows[captured] = line
    end
    details.empty = UI:EmptyState(details, 310, 150, "Select a member", "Choose a roster row to view notes, status and available actions.")
    details.empty:SetPoint("CENTER", details, "CENTER", 0, 10)
    details.historyOffset = 0
    details:EnableMouse(true)
    details:EnableMouseWheel(true)
    details.otlMouseWheelOwner = true
    details:SetScript("OnMouseWheel", function()
        if not details.otlMember then return end
        local history = owner:GetMemberRecentHistory(details.otlMember.name, 40)
        local visibleRows = math.max(1, tonumber(details.historyVisibleRows180) or table.getn(details.historyRows))
        local maximum = math.max(0, table.getn(history) - visibleRows)
        details.historyOffset = math.max(0, math.min(maximum, (tonumber(details.historyOffset) or 0) - (tonumber(arg1) or 0)))
        owner:RefreshRosterPage()
    end)
    owner.ui.rosterDetails = details
    owner.ui.rosterFilter = OTLGM_DB.settings.rosterFilter or "ALL"
    owner.ui.rosterRankFilter = OTLGM_DB.settings.rosterRankFilter ~= "" and OTLGM_DB.settings.rosterRankFilter or nil
    owner.ui.rosterProfessionFilter = OTLGM_DB.settings.rosterProfessionFilter ~= "" and OTLGM_DB.settings.rosterProfessionFilter or nil
    owner.ui.rosterOffset = math.max(0, tonumber(OTLGM_DB.settings.rosterShellOffset180) or 0)
    owner.ui.rosterSelectedName = OTLGM_DB.settings.rosterShellSelection180 ~= "" and OTLGM_DB.settings.rosterShellSelection180 or nil
end

local function SetRosterDetailsStaticVisible180(details, visible)
    local labels = { details.statusLabel, details.professionsLabel, details.notesLabel, details.publicNoteLabel, details.officerNoteLabel }
    local index
    for index = 1, table.getn(labels) do
        if labels[index] then
            if visible then labels[index]:Show() else labels[index]:Hide() end
        end
    end
end

local function ClearDetails(details)
    details.otlMember = nil
    details.otlHistory183 = nil
    details.otlHistoryName183 = nil
    SetRosterDetailsStaticVisible180(details, false)
    details.classIcon:Hide()
    if details.classIconFrame183 then details.classIconFrame183:Hide() end
    if details.hero183 then details.hero183:Hide() end
    if details.identityDivider183 then details.identityDivider183:Hide() end
    details.nameText:SetText("")
    details.rankText:SetText("")
    details.statusText:SetText("")
    details.zoneText:SetText("")
    details.addonText:SetText("")
    details.firstSeenText:SetText("")
    details.professionsText:SetText("")
    details.publicEdit:Hide() details.publicRead:Hide()
    details.officerEdit:Hide() details.officerRead:Hide()
    details.saveNotes:Hide()
    details.whisper:Hide() details.invite:Hide() details.history:Hide() details.more:Hide()
    details.promote:Hide() details.demote:Hide() details.approveLion:Hide() details.muteGuest:Hide() details.pendingText:Hide()
    details.actionsTitle:Hide()
    if details.profile183 then UI:SetText(details.profile183, "My Profile") details.profile183:Show() end
    details.historyTitle:Hide()
    local index
    for index = 1, table.getn(details.historyRows) do details.historyRows[index]:Hide() end
    details.empty:Show()
end

RefreshDetails = function(owner, member)
    local details = owner.ui.rosterDetails
    if not member then ClearDetails(details) return end
    details.empty:Hide()
    SetRosterDetailsStaticVisible180(details, true)
    details.otlMember = member
    if details.profile183 then UI:SetText(details.profile183, "Open Profile") details.profile183:Show() end
    ApplyClassIcon(details.classIcon, member.class)
    if details.classIconFrame183 then details.classIconFrame183:Show() end
    if details.hero183 then details.hero183:Show() end
    if details.identityDivider183 then details.identityDivider183:Show() end
    details.classIcon:Show()
    details.nameText:SetText(owner:GetClassColor(member.class) .. tostring(member.name or "") .. owner.colors.reset)
    details.rankText:SetText("Level " .. tostring(member.level or 0) .. " " .. tostring(member.class or "") .. "  •  " .. tostring(member.rank or "Guild member"))
    local accent = CLASS_RGB_183[tostring(member.class or "")] or C.gold
    if details.heroAccent183 then details.heroAccent183:SetTexture(accent[1], accent[2], accent[3], 0.92) end
    if details.classIconFrame183 and details.classIconFrame183.SetBackdropBorderColor then details.classIconFrame183:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.90) end
    ApplyRosterRankTextColor180(details.rankText, member, owner:IsLeadership(member))
    details.statusText:SetText(member.online and "Online now" or ("Last online: " .. tostring(owner:GetFreshnessText(member.lastSeen))))
    details.statusText:SetTextColor(member.online and C.green[1] or C.grey[1], member.online and C.green[2] or C.grey[2], member.online and C.green[3] or C.grey[3])
    details.zoneText:SetText("Zone: " .. tostring(member.zone or "Unknown"))
    local detection = owner:GetAddonDetection170(member.name)
    local publicVersion = detection.version and owner.GetPublicVersion180 and owner:GetPublicVersion180(detection.version) or nil
    details.addonText:SetText("Addon: " .. tostring(detection.label or "Not detected") .. (publicVersion and ("  v" .. tostring(publicVersion)) or ""))
    local firstSeen = tonumber(member.joinedAt) or tonumber(member.trackedSince) or tonumber(member.firstSeenAt)
    local firstSeenLabel184 = firstSeen and ("First seen: " .. date("%d %b %Y", firstSeen)) or "First seen: no stored date"
    local identityCompact184 = owner.GetCharacterIdentityCompactText184 and owner:GetCharacterIdentityCompactText184(member.name) or nil
    if identityCompact184 and identityCompact184 ~= "" then
        details.firstSeenText:SetText(tostring(identityCompact184) .. "  -  " .. firstSeenLabel184)
        details.firstSeenText:SetTextColor(C.blue[1], C.blue[2], C.blue[3])
    else
        details.firstSeenText:SetText(firstSeenLabel184)
        details.firstSeenText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    end
    local professions = owner:GetMemberProfessionLabels(member)
    details.professionsText:SetText("Professions: " .. (table.getn(professions) > 0 and table.concat(professions, ", ") or "No shared profession data"))

    local livePublic, liveOfficer, liveIndex, liveAvailable = owner:GetLiveRosterNotes180(member)
    local canPublic = owner.CanEditPublicNotes and owner:CanEditPublicNotes()
    local canOfficer = owner.CanEditOfficerNotes and owner:CanEditOfficerNotes()
    local canViewOfficer = owner.CanViewOfficerNotes and owner:CanViewOfficerNotes()
    details.publicEdit.otlSilent = true
    details.publicEdit:SetText(livePublic or member.note or "")
    details.publicEdit.otlSilent = nil
    details.officerEdit.otlSilent = true
    details.officerEdit:SetText(liveOfficer or member.officerNote or "")
    details.officerEdit.otlSilent = nil
    details.publicRead:SetText(livePublic and livePublic ~= "" and livePublic or "No public note")
    details.officerRead:SetText(liveOfficer and liveOfficer ~= "" and liveOfficer or "No officer note")
    details.otlLiveRosterIndex180 = liveIndex
    details.otlLiveNotesAvailable180 = liveAvailable and true or false
    if canPublic then details.publicEdit:Show() details.publicRead:Hide() else details.publicEdit:Hide() details.publicRead:Show() end
    if canOfficer then details.officerEdit:Show() details.officerRead:Hide()
    elseif canViewOfficer then details.officerEdit:Hide() details.officerRead:Show()
    else details.officerEdit:Hide() details.officerRead:Hide() end
    details.saveNotes:Hide()
    details.whisper:Show() details.invite:Show() details.history:Show() details.more:Show()
    details.pendingText:Show()
    local pending = owner.rosterActionPending180
    local promoteAllowed, promoteReason = owner:CanUseOfficerActionForMember170("PROMOTE", member)
    local demoteAllowed, demoteReason = owner:CanUseOfficerActionForMember170("DEMOTE", member)
    local quickLion = owner:GetQuickLionAvailability180(member)
    local muteGuest, muteReason = owner:GetMuteGuestAvailability180(member)
    local retry = owner.rosterQuickLionRetry180
    local retryFinal = retry and owner:NormalizeName(retry.name) == owner:NormalizeName(member.name)
        and NormalizeGuildRankLabel180(member.rank) == "muted"
    details.promote:Show() details.demote:Show()
    UI:SetEnabled(details.promote, not pending and promoteAllowed, pending and "Waiting for server roster confirmation." or promoteReason)
    UI:SetEnabled(details.demote, not pending and demoteAllowed, pending and "Waiting for server roster confirmation." or demoteReason)
    if quickLion or retryFinal then
        details.approveLion:Show()
        UI:SetText(details.approveLion, retryFinal and "Retry final step" or "Promote to 2 - Lion")
        UI:SetEnabled(details.approveLion, not pending, pending and "Waiting for server roster confirmation." or nil)
    else
        details.approveLion:Hide()
        UI:SetText(details.approveLion, "Promote to 2 - Lion")
    end
    if muteGuest then
        details.muteGuest:Show()
        UI:SetEnabled(details.muteGuest, not pending, pending and "Waiting for server roster confirmation." or nil)
    else
        details.muteGuest:Hide()
        UI:SetEnabled(details.muteGuest, false, muteReason)
    end
    UI:SetEnabled(details.saveNotes, not pending or pending.targeted180, pending and not pending.targeted180 and "Waiting for roster update." or nil)
    local inline = owner:GetRosterRankInline180(member.name)
    if pending and owner:NormalizeName(pending.name) == owner:NormalizeName(member.name) then
        details.pendingText:SetText(pending.kind == "APPROVE_LION" and (pending.phase == 2 and "Promoting 2/2…" or "Promoting 1/2…") or "Waiting for guild roster confirmation…")
        details.pendingText:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    elseif retryFinal then
        details.pendingText:SetText("Stopped at - Muted -. Retry final step.")
        details.pendingText:SetTextColor(C.orange[1], C.orange[2], C.orange[3])
    elseif inline then
        details.pendingText:SetText(inline.text or "")
        if inline.state == "error" then details.pendingText:SetTextColor(C.red[1], C.red[2], C.red[3])
        elseif inline.state == "success" then details.pendingText:SetTextColor(C.green[1], C.green[2], C.green[3])
        else details.pendingText:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3]) end
    else
        details.pendingText:SetText("")
        details.pendingText:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    end
    details.actionsTitle:Show()
    local visibleRows = math.max(0, math.min(table.getn(details.historyRows), tonumber(details.historyVisibleRows180) or table.getn(details.historyRows)))
    if visibleRows > 0 then details.historyTitle:Show() else details.historyTitle:Hide() end
    local history = owner:GetMemberRecentHistory(member.name, 40)
    -- Reuse this already-bounded read in Guild Profile. Rapid member switching
    -- must not walk the retained history a second time for presentation.
    details.otlHistory183 = history
    details.otlHistoryName183 = member.name
    local maximum = math.max(0, table.getn(history) - math.max(1, visibleRows))
    details.historyOffset = math.max(0, math.min(maximum, tonumber(details.historyOffset) or 0))
    local index
    for index = 1, table.getn(details.historyRows) do
        if index <= visibleRows then
            local record = history[details.historyOffset + index]
            if record then
                local actor = record.actor and record.actor ~= "" and ("  by " .. tostring(record.actor)) or ""
                details.historyRows[index]:SetText(date("%d %b", record.ts or owner:Now()) .. "  "
                    .. Short(record.detail or record.kind or "Guild event", 34) .. actor)
                details.historyRows[index]:Show()
            else
                details.historyRows[index]:SetText(index == 1 and "No stored member activity." or "")
                if index == 1 then details.historyRows[index]:Show() else details.historyRows[index]:Hide() end
            end
        else
            details.historyRows[index]:Hide()
        end
    end
end

function OTLGM:RefreshRosterTarget180(name)
    self.runtime = self.runtime or {}
    -- A targeted rank/note change can affect the active sort/search without a
    -- new full roster timestamp. Drop the short-lived sorted view explicitly.
    self.runtime.sortedRosterView184 = nil
    self.runtime.rosterTargetRevision184 = (tonumber(self.runtime.rosterTargetRevision184) or 0) + 1
    self.runtime.rosterSummaryCounts184 = nil
    self.runtime.rosterMetrics180 = self.runtime.rosterMetrics180 or { fullScans = 0, targetedRefreshes = 0, reasons = {} }
    self.runtime.rosterMetrics180.targetedRefreshes = (tonumber(self.runtime.rosterMetrics180.targetedRefreshes) or 0) + 1
    self.runtime.rosterMetrics180.lastTargetedName = tostring(name or "")
    if not self.ui or not self.ui.rosterTable then return false end
    local member = self:GetMember(name)
    if not member then return false end
    local selected = self.ui.rosterSelectedName and self:NormalizeName(self.ui.rosterSelectedName) == self:NormalizeName(member.name)
    local index
    for index = 1, table.getn(self.ui.rosterTable.rows or {}) do
        local row = self.ui.rosterTable.rows[index]
        if row and row.otlMemberName and self:NormalizeName(row.otlMemberName) == self:NormalizeName(member.name) then
            ApplyRankGroupIcon(row, member)
            local leadership = self:IsLeadership(member)
            if member.online then row.onlineDot:Show() else row.onlineDot:Hide() end
            SetRosterMemberNameR35(self, row, member)
            row.levelText:SetText(tostring(member.level or 0))
            row.classText:SetText(Short(member.class or "", 11))
            row.rankText:SetText(Short(member.rank or "", 15))
            row.zoneText:SetText(Short(member.zone or "", 17))
            row.lastText:SetText(member.online and "Online" or Short(self:GetFreshnessText(member.lastSeen), 12))
            local detection = self:GetAddonDetection170(member.name)
            row.addonIcon:SetAlpha(detection.state == "ACTIVE" and 1 or detection.state == "UNDETECTED" and 0.28 or 0.58)
            if row.addonIcon.SetVertexColor then
                if detection.state == "ACTIVE" then row.addonIcon:SetVertexColor(C.green[1], C.green[2], C.green[3])
                else row.addonIcon:SetVertexColor(C.grey[1], C.grey[2], C.grey[3]) end
            end
            ApplyRosterRankTextColor180(row.rankText, member, leadership)
            row.otlTooltipLines = {
                tostring(member.name or "Guild member"),
                tostring(row.rankGroupLabel or "Member") .. "  •  " .. tostring(member.rank or "Unknown"),
                tostring(member.online and "Online" or self:GetFreshnessText(member.lastSeen)) .. "  •  " .. tostring(member.zone or "Unknown"),
            }
            UI:SetSelected(row, selected)
            ApplyRosterRowState180(row, member, leadership, selected)
            break
        end
    end
    if selected and self.ui.rosterDetails then RefreshDetails(self, member) end
    if selected and self.ui.guildProfile183 and self.ui.guildProfile183:IsVisible()
        and self.RefreshGuildProfile183 then self:RefreshGuildProfile183("roster-target") end
    self:PersistRosterPosition180()
    return true
end

function OTLGM:RefreshRosterPage()
    if self.CanRefreshShellPage180 and not self:CanRefreshShellPage180("roster") then return false end
    if not self.ui or not self.ui.rosterTable then return end
    local filter = self.ui.rosterFilter or OTLGM_DB.settings.rosterFilter or "ALL"
    if string.sub(filter, 1, 6) == "ADDON_" and not self:IsOfficerMode() then filter = "ALL" self.ui.rosterFilter = filter OTLGM_DB.settings.rosterFilter = filter end
    local search = self.ui.rosterSearch:GetText() or ""
    self.ui.rosterSearchRuntime180 = search
    local list = self:GetSortedRoster(search, filter, self.ui.rosterRankFilter, self.ui.rosterProfessionFilter)
    self.ui.rosterLastListCount184 = table.getn(list)
    self.runtime = self.runtime or {}
    self.runtime.rosterMetrics180 = self.runtime.rosterMetrics180 or { fullScans = 0, targetedRefreshes = 0, reasons = {} }
    self.runtime.rosterMetrics180.fullRefreshes183 = (tonumber(self.runtime.rosterMetrics180.fullRefreshes183) or 0) + 1
    -- RC4-r9: summary chips need counts, not ordering.  The former code called
    -- GetSortedRoster("", "ALL") here, causing a second O(n log n) sort on every
    -- Roster repaint.  Count directly in one linear pass instead.
    local onlineCount, leadershipCount, levelSixtyCount = 0, 0, 0
    local summaryDb184 = self:GetGuildDB()
    local summaryRoster184 = summaryDb184 and summaryDb184.roster or {}
    local summaryRevision184 = table.concat({
        tostring(summaryDb184 and summaryDb184.lastScan or 0), tostring(summaryDb184 and summaryDb184.lastTotal or 0),
        tostring(summaryRoster184), tostring(tonumber(self.runtime.rosterTargetRevision184) or 0),
        tostring(tonumber(self.runtime.rosterPresenceRevisionR59) or 0),
    }, ":")
    local summaryCache184 = self.runtime.rosterSummaryCounts184
    if summaryCache184 and summaryCache184.revision == summaryRevision184 then
        onlineCount = tonumber(summaryCache184.online) or 0
        leadershipCount = tonumber(summaryCache184.leadership) or 0
        levelSixtyCount = tonumber(summaryCache184.level60) or 0
    else
        local summaryName184, summaryMember
        for summaryName184, summaryMember in pairs(summaryRoster184) do
            if summaryMember.online then onlineCount = onlineCount + 1 end
            if self:IsLeadership(summaryMember) then leadershipCount = leadershipCount + 1 end
            if tonumber(summaryMember.level) == 60 then levelSixtyCount = levelSixtyCount + 1 end
        end
        self.runtime.rosterSummaryCounts184 = {
            revision = summaryRevision184, online = onlineCount, leadership = leadershipCount, level60 = levelSixtyCount,
        }
    end
    self.ui.rosterSummary:SetText(self.colors.green .. tostring(onlineCount) .. " Online" .. self.colors.reset
        .. self.colors.grey .. "  •  " .. self.colors.reset
        .. self.colors.gold .. tostring(leadershipCount) .. " Leadership" .. self.colors.reset
        .. self.colors.grey .. "  •  " .. self.colors.reset
        .. self.colors.purple .. tostring(levelSixtyCount) .. " Level 60" .. self.colors.reset
        .. self.colors.grey .. "  •  " .. tostring(table.getn(list)) .. " shown" .. self.colors.reset)
    local summaryChips184 = self.ui.rosterSummaryChips184
    if summaryChips184 then
        local values184 = { online = onlineCount, leadership = leadershipCount, level60 = levelSixtyCount, shown = table.getn(list) }
        local key184, chip184
        for key184, chip184 in pairs(summaryChips184) do
            if chip184 and chip184.text then chip184.text:SetText(tostring(chip184.otlLabel184 or key184) .. "  " .. tostring(values184[key184] or 0)) end
        end
    end
    local operation = self.GetOperationState156 and self:GetOperationState156("ROSTER") or { state = "IDLE" }
    if operation.state == "WORKING" or self.pendingScan then
        UI:SetText(self.ui.rosterUpdate, "Updating…")
        UI:SetEnabled(self.ui.rosterUpdate, false, "A roster update is already in progress.")
    else
        local db = self:GetGuildDB()
        local lastScan = db and tonumber(db.lastScan)
        local age = lastScan and math.max(0, self:Now() - lastScan) or nil
        local label
        if (operation.state == "ERROR" or operation.state == "TIMEOUT") and (not age or age > 30) then label = "Update failed"
        elseif age then label = "Updated  •  " .. tostring(age) .. " sec ago"
        else label = "Update guild" end
        UI:SetText(self.ui.rosterUpdate, label)
        UI:SetEnabled(self.ui.rosterUpdate, true)
    end
    if self.ui.rosterInvite180 then
        local canInvite = self.CanInviteGuildMembersR5 and self:CanInviteGuildMembersR5(false)
        UI:SetEnabled(self.ui.rosterInvite180, canInvite and true or false, canInvite and nil or "Your guild rank cannot invite members.")
    end
    local offset = math.max(0, tonumber(self.ui.rosterOffset) or 0)
    local capacity = math.max(MIN_ROW_COUNT, tonumber(self.ui.rosterVisibleCapacity180) or MIN_ROW_COUNT)
    EnsureRosterRowCapacity(self, capacity)
    local maximum = math.max(0, table.getn(list) - capacity)
    local positionByName184 = list.otlPositionByName184 or {}
    local focusName = self.ui.rosterFocusMember180
    if focusName then
        local focusIndex = positionByName184[self:NormalizeName(focusName)]
        if focusIndex then
            local desired = math.max(0, focusIndex - math.max(1, math.floor(capacity / 2)))
            offset = math.min(maximum, desired)
        end
        self.ui.rosterFocusMember180 = nil
    end
    if offset > maximum then offset = maximum end
    self.ui.rosterOffset = offset
    local previousSelection = self.ui.rosterSelectedName
    local selectedMember = previousSelection and self:GetMember(previousSelection) or nil
    local selectedPresent = selectedMember and positionByName184[self:NormalizeName(selectedMember.name)] ~= nil or false
    local scanIndex
    -- Roster is member-centric: on first entry choose a useful member so the
    -- companion Guild Profile is immediately discoverable. Prefer the player's
    -- own row, then the first visible member. This is presentation-only and does
    -- not request a roster refresh or any network data.
    if not selectedPresent and self.ui.rosterAutoProfilePending183
        and OTLGM_DB.settings.showGuildProfileOnRoster183 ~= false and table.getn(list) > 0 then
        local player = UnitName and UnitName("player") or ""
        local preferred = nil
        for scanIndex = 1, table.getn(list) do
            if self:NormalizeName(list[scanIndex].name) == self:NormalizeName(player) then preferred = list[scanIndex] break end
        end
        selectedMember = preferred or list[1]
        if selectedMember then
            selectedPresent = true
            self.ui.rosterSelectedName = selectedMember.name
            self.ui.selectedMember = selectedMember.name
        end
    end
    if not selectedPresent then
        selectedMember = nil
        self.ui.rosterSelectedName = nil
        self.ui.selectedMember = nil
        if previousSelection and self.ui.guildProfile183 and self.ui.guildProfile183:IsVisible()
            and self.CloseGuildProfile183 then self:CloseGuildProfile183("roster-selection-missing") end
    else
        self.ui.selectedMember = selectedMember.name
    end
    local index
    for index = 1, table.getn(self.ui.rosterTable.rows) do
        local row = self.ui.rosterTable.rows[index]
        -- The row pool only grows. After switching from a larger workspace to
        -- Compact/Fit, pooled rows beyond the new viewport capacity still
        -- exist and must remain hidden. Refresh used to re-show those stale
        -- rows whenever the filtered list was long enough, letting Roster draw
        -- below the ContentHost and over the game action bars. Capacity is the
        -- hard visibility boundary; scrolling changes the data mapped into the
        -- visible pool, never the number of rows allowed to render.
        local member = index <= capacity and list[offset + index] or nil
        if member then
            row.otlMemberName = member.name
            ApplyRankGroupIcon(row, member)
            local leadership = self:IsLeadership(member)
            row:SetAlpha(1)
            if member.online then
                row.onlineDot:Show()
                row.levelText:SetTextColor(C.white[1], C.white[2], C.white[3])
                row.classText:SetTextColor(C.white[1], C.white[2], C.white[3])
                row.zoneText:SetTextColor(C.white[1], C.white[2], C.white[3])
                row.lastText:SetTextColor(C.green[1], C.green[2], C.green[3])
            else
                row.onlineDot:Hide()
                row.levelText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
                row.classText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
                row.zoneText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
                row.lastText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
            end
            SetRosterMemberNameR35(self, row, member)
            ApplyRosterRankTextColor180(row.rankText, member, leadership)
            row.levelText:SetText(tostring(member.level or 0))
            row.classText:SetText(Short(member.class or "", 11))
            row.rankText:SetText(Short(member.rank or "", 15))
            row.zoneText:SetText(Short(member.zone or "", 17))
            row.lastText:SetText(member.online and "Online" or Short(self:GetFreshnessText(member.lastSeen), 12))
            local detection = self:GetAddonDetection170(member.name)
            row.addonIcon:SetAlpha(detection.state == "ACTIVE" and 1 or detection.state == "UNDETECTED" and 0.28 or 0.58)
            if row.addonIcon.SetVertexColor then
                if detection.state == "ACTIVE" then row.addonIcon:SetVertexColor(C.green[1], C.green[2], C.green[3])
                else row.addonIcon:SetVertexColor(C.grey[1], C.grey[2], C.grey[3]) end
            end
            row.otlTooltipLines = {
                tostring(member.name or "Guild member"),
                tostring(row.rankGroupLabel or "Member") .. "  •  " .. tostring(member.rank or "Unknown"),
                tostring(member.online and "Online" or self:GetFreshnessText(member.lastSeen)) .. "  •  " .. tostring(member.zone or "Unknown"),
            }
            local selected = selectedMember and self:NormalizeName(member.name) == self:NormalizeName(selectedMember.name)
            UI:SetSelected(row, selected)
            ApplyRosterRowState180(row, member, leadership, selected)
            row:Show()
        else
            row.otlMemberName = nil
            row.otlTooltipLines = nil
            row:SetAlpha(1)
            row.otlLeadership180 = nil
            row.otlSelected180 = nil
            row.onlineDot:Hide()
            row.leadershipAccent:Hide()
            if row.rankIcon and row.rankIcon.SetVertexColor then row.rankIcon:SetVertexColor(1, 1, 1, 1) end
            row:Hide()
        end
    end
    if table.getn(list) == 0 then self.ui.rosterTable.empty:Show() else self.ui.rosterTable.empty:Hide() end
    self.ui.rosterTable.previous:Hide()
    self.ui.rosterTable.next:Hide()
    self.ui.rosterTable.pageText:Hide()
    if self.ui.rosterTable.scrollbar then
        self.ui.rosterScrollSilent180 = true
        self.ui.rosterTable.scrollbar.otlSilent = true
        self.ui.rosterTable.scrollbar:SetMinMaxValues(0, maximum)
        self.ui.rosterTable.scrollbar:SetValue(offset)
        self.ui.rosterTable.scrollbar.otlSilent = nil
        self.ui.rosterScrollSilent180 = nil
        if maximum > 0 then self.ui.rosterTable.scrollbar:Show() else self.ui.rosterTable.scrollbar:Hide() end
    end
    local chips = self.ui.rosterActiveChips
    if filter ~= "ALL" and filter ~= "ONLINE" and filter ~= "LEADERSHIP" then
        UI:SetText(chips.filter, Short(CurrentFilterLabel(filter) .. "  x", 20))
        chips.filter:Show()
    else chips.filter:Hide() end
    if self.ui.rosterRankFilter then
        UI:SetText(chips.rank, Short("Rank: " .. self.ui.rosterRankFilter .. "  x", 20))
        chips.rank:Show()
    else chips.rank:Hide() end
    if self.ui.rosterProfessionFilter then
        UI:SetText(chips.profession, Short("Profession: " .. self.ui.rosterProfessionFilter .. "  x", 23))
        chips.profession:Show()
    else chips.profession:Hide() end
    for index = 1, table.getn(self.ui.rosterQuick) do
        UI:SetSelected(self.ui.rosterQuick[index], FILTERS[index][1] == filter)
    end
    UI:SetText(self.ui.rosterFilters, (self.ui.rosterRankFilter or self.ui.rosterProfessionFilter or (filter ~= "ALL" and filter ~= "ONLINE" and filter ~= "LEADERSHIP")) and "Filters active" or "Filters")
    local complexFiltersVisible180 = self.ui.rosterRankFilter or self.ui.rosterProfessionFilter or (filter ~= "ALL" and filter ~= "ONLINE" and filter ~= "LEADERSHIP")
    complexFiltersVisible180 = complexFiltersVisible180 and true or false
    if self.ui.rosterLayoutActiveRow180 ~= complexFiltersVisible180 and self.LayoutShellPage180 then
        self:LayoutShellPage180("roster", "filter-row")
    end
    local sortKey = OTLGM_DB.settings.rosterSortKey or "RANK"
    local headers = { "NAME", "LEVEL", "CLASS", "RANK", nil, "LASTONLINE", nil }
    for index = 1, table.getn(self.ui.rosterTable.headers) do
        if headers[index] then UI:SetSelected(self.ui.rosterTable.headers[index], sortKey == headers[index]) end
    end
    RefreshDetails(self, selectedMember)
    if self.ui.rosterAutoProfilePending183 and selectedMember then
        self.ui.rosterAutoProfilePending183 = nil
        if OTLGM_DB.settings.showGuildProfileOnRoster183 ~= false and self.OpenGuildMemberProfile183 then
            self:OpenGuildMemberProfile183(selectedMember.name, "roster-open", true)
        end
    end
    self:PersistRosterPosition180()
end

local function LayoutRosterTableColumns180(owner, tableWidth)
    local tablePanel = owner.ui.rosterTable
    if not tablePanel then return end
    local rowWidth = math.max(414, tableWidth - 26)
    local extra = math.max(0, rowWidth - 414)
    local columns = {
        84 + math.floor(extra * 0.24), -- name
        34 + math.floor(extra * 0.03), -- level
        56 + math.floor(extra * 0.10), -- class
        74 + math.floor(extra * 0.20), -- rank
        82 + math.floor(extra * 0.28), -- zone
        60 + math.floor(extra * 0.15), -- last online
        24,                            -- addon presence
    }
    local total = 0
    local index
    for index = 1, table.getn(columns) do total = total + columns[index] end
    columns[1] = columns[1] + (rowWidth - total)

    local x = 8
    for index = 1, table.getn(tablePanel.headers or {}) do
        local header = tablePanel.headers[index]
        if header then
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", tablePanel, "TOPLEFT", x, -10)
            header:SetWidth(columns[index])
            if header.text then header.text:SetWidth(math.max(20, columns[index] - 8)) end
        end
        x = x + columns[index]
    end

    for index = 1, table.getn(tablePanel.rows or {}) do
        local row = tablePanel.rows[index]
        row:SetWidth(rowWidth)
        local cursor = 0
        local nameWidth = columns[1]
        row.nameText:ClearAllPoints()
        row.nameText:SetPoint("TOPLEFT", row, "TOPLEFT", 29, -7)
        row.nameText:SetWidth(math.max(44, nameWidth - 33))
        cursor = cursor + columns[1]

        row.levelText:ClearAllPoints()
        row.levelText:SetPoint("TOPLEFT", row, "TOPLEFT", cursor, -7)
        row.levelText:SetWidth(columns[2])
        cursor = cursor + columns[2]

        row.classText:ClearAllPoints()
        row.classText:SetPoint("TOPLEFT", row, "TOPLEFT", cursor + 2, -7)
        row.classText:SetWidth(math.max(30, columns[3] - 4))
        cursor = cursor + columns[3]

        row.rankText:ClearAllPoints()
        row.rankText:SetPoint("TOPLEFT", row, "TOPLEFT", cursor + 2, -7)
        row.rankText:SetWidth(math.max(36, columns[4] - 4))
        cursor = cursor + columns[4]

        row.zoneText:ClearAllPoints()
        row.zoneText:SetPoint("TOPLEFT", row, "TOPLEFT", cursor + 2, -7)
        row.zoneText:SetWidth(math.max(38, columns[5] - 4))
        cursor = cursor + columns[5]

        row.lastText:ClearAllPoints()
        row.lastText:SetPoint("TOPLEFT", row, "TOPLEFT", cursor + 2, -7)
        row.lastText:SetWidth(math.max(34, columns[6] - 4))
        cursor = cursor + columns[6]

        row.addonIcon:ClearAllPoints()
        row.addonIcon:SetPoint("CENTER", row, "LEFT", cursor + math.floor(columns[7] / 2), 0)
    end
    tablePanel.otlColumnWidths180 = columns
end

local function LayoutRosterDetails180(details, detailsWidth, detailsHeight)
    if not details then return end
    local inner = math.max(210, detailsWidth - 28)
    local textWidth = math.max(160, inner)
    local titleWidth = math.max(120, detailsWidth - 154)
    local controlHeight = 28

    details.classIcon:ClearAllPoints()
    details.classIcon:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -34)
    details.nameText:ClearAllPoints()
    details.nameText:SetPoint("TOPLEFT", details, "TOPLEFT", 62, -35)
    details.nameText:SetWidth(titleWidth)
    details.rankText:ClearAllPoints()
    details.rankText:SetPoint("TOPLEFT", details, "TOPLEFT", 62, -58)
    details.rankText:SetWidth(titleWidth)
    if details.profile183 then
        details.profile183:ClearAllPoints()
        details.profile183:SetPoint("TOPRIGHT", details, "TOPRIGHT", -10, -7)
        details.profile183:SetWidth(math.max(70, math.min(82, detailsWidth * 0.24)))
        if details.profile183.text then details.profile183.text:SetWidth(math.max(48, details.profile183:GetWidth() - 8)) end
    end

    details.statusLabel:ClearAllPoints()
    details.statusLabel:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -82)
    details.statusText:ClearAllPoints()
    details.statusText:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -100)
    details.zoneText:ClearAllPoints()
    details.zoneText:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -118)
    details.addonText:ClearAllPoints()
    details.addonText:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -136)
    details.firstSeenText:ClearAllPoints()
    details.firstSeenText:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -154)
    details.statusText:SetWidth(textWidth)
    details.zoneText:SetWidth(textWidth)
    details.addonText:SetWidth(textWidth)
    details.firstSeenText:SetWidth(textWidth)

    details.professionsLabel:ClearAllPoints()
    details.professionsLabel:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -174)
    details.professionsText:ClearAllPoints()
    details.professionsText:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -193)
    details.professionsText:SetWidth(textWidth)
    details.professionsText:SetHeight(27)

    details.notesLabel:ClearAllPoints()
    details.notesLabel:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -226)
    details.publicNoteLabel:ClearAllPoints()
    details.publicNoteLabel:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -245)
    details.publicEdit:ClearAllPoints()
    details.publicEdit:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -257)
    details.publicEdit:SetWidth(inner)
    details.publicEdit:SetHeight(28)
    details.publicRead:ClearAllPoints()
    details.publicRead:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -265)
    details.publicRead:SetWidth(inner)

    details.officerNoteLabel:ClearAllPoints()
    details.officerNoteLabel:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -294)
    details.officerEdit:ClearAllPoints()
    details.officerEdit:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -306)
    details.officerEdit:SetWidth(inner)
    details.officerEdit:SetHeight(28)
    details.officerRead:ClearAllPoints()
    details.officerRead:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -314)
    details.officerRead:SetWidth(inner)

    details.saveNotes:ClearAllPoints()
    details.saveNotes:SetPoint("TOPRIGHT", details, "TOPRIGHT", -14, -220)
    local saveWidth = math.min(100, math.max(78, inner * 0.38))
    details.saveNotes:SetWidth(saveWidth)
    details.saveNotes:SetHeight(24)
    if details.saveNotes.text then details.saveNotes.text:SetWidth(math.max(54, saveWidth - 8)) end

    details.actionsTitle:ClearAllPoints()
    details.actionsTitle:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -344)
    local actionGap = 6
    local actionWidth = math.max(48, math.floor((inner - (actionGap * 3)) / 4))
    local actionButtons = { details.whisper, details.invite, details.history, details.more }
    local index
    for index = 1, table.getn(actionButtons) do
        local button = actionButtons[index]
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", details, "TOPLEFT", 14 + ((index - 1) * (actionWidth + actionGap)), -358)
        button:SetWidth(actionWidth)
        button:SetHeight(controlHeight)
        if button.text then button.text:SetWidth(math.max(24, actionWidth - 8)) end
    end

    local halfWidth = math.max(80, math.floor((inner - 8) / 2))
    details.promote:ClearAllPoints()
    details.promote:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -392)
    details.promote:SetWidth(halfWidth)
    details.promote:SetHeight(controlHeight)
    if details.promote.text then details.promote.text:SetWidth(math.max(40, halfWidth - 8)) end
    details.demote:ClearAllPoints()
    details.demote:SetPoint("TOPLEFT", details, "TOPLEFT", 14 + halfWidth + 8, -392)
    details.demote:SetWidth(inner - halfWidth - 8)
    details.demote:SetHeight(controlHeight)
    if details.demote.text then details.demote.text:SetWidth(math.max(40, inner - halfWidth - 16)) end

    details.approveLion:ClearAllPoints()
    details.approveLion:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -426)
    local muteWidth = math.max(94, math.min(116, math.floor(inner * 0.34)))
    local approveWidth = math.max(150, inner - muteWidth - 8)
    details.approveLion:SetWidth(approveWidth)
    details.approveLion:SetHeight(controlHeight)
    if details.approveLion.text then details.approveLion.text:SetWidth(math.max(60, approveWidth - 8)) end
    details.muteGuest:ClearAllPoints()
    details.muteGuest:SetPoint("LEFT", details.approveLion, "RIGHT", 8, 0)
    details.muteGuest:SetWidth(math.max(80, inner - approveWidth - 8))
    details.muteGuest:SetHeight(controlHeight)
    if details.muteGuest.text then details.muteGuest.text:SetWidth(math.max(60, details.muteGuest:GetWidth() - 8)) end
    details.pendingText:ClearAllPoints()
    details.pendingText:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -462)
    details.pendingText:SetWidth(inner)
    details.pendingText:SetHeight(27)

    local historyTop = 500
    local visibleRows = math.floor((detailsHeight - historyTop - 8) / 17)
    visibleRows = math.max(0, math.min(table.getn(details.historyRows), visibleRows))
    details.historyVisibleRows180 = visibleRows
    details.historyTitle:ClearAllPoints()
    details.historyTitle:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -492)
    details.historyTitle:SetWidth(inner)
    if visibleRows > 0 and details.otlMember then details.historyTitle:Show() else details.historyTitle:Hide() end
    for index = 1, table.getn(details.historyRows) do
        local line = details.historyRows[index]
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -512 - ((index - 1) * 17))
        line:SetWidth(inner)
        if index > visibleRows then line:Hide() end
    end

    details.empty:SetWidth(math.max(210, inner))
    details.empty:SetHeight(math.min(150, math.max(118, detailsHeight - 80)))
    details.empty:ClearAllPoints()
    details.empty:SetPoint("CENTER", details, "CENTER", 0, 4)
end

local function LayoutRoster(owner, page, width, height)
    local previousCapacity = tonumber(owner.ui.rosterVisibleCapacity180)
    local previousHistoryRows = owner.ui.rosterDetails and tonumber(owner.ui.rosterDetails.historyVisibleRows180) or nil
    local gap = 12
    local detailsWidth = math.max(280, math.floor(width * 0.35))
    detailsWidth = math.min(detailsWidth, math.max(280, width - 468 - gap))
    local tableWidth = width - detailsWidth - gap

    -- Search/update/invite/filter controls must always stay inside the roster-table side.
    -- Keep the manual guild invite available even in Fit/Compact without letting
    -- toolbar controls cross into Member Details.
    local filtersWidth = 76
    local inviteWidth = 82
    local updateWidth = 96
    local controlGaps = 24
    local searchWidth = math.max(150, tableWidth - filtersWidth - inviteWidth - updateWidth - controlGaps)
    owner.ui.rosterSearch:SetWidth(searchWidth)
    owner.ui.rosterSearch:ClearAllPoints()
    owner.ui.rosterSearch:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -4)
    owner.ui.rosterUpdate:SetWidth(updateWidth)
    if owner.ui.rosterUpdate.text then owner.ui.rosterUpdate.text:SetWidth(math.max(56, updateWidth - 8)) end
    owner.ui.rosterUpdate:ClearAllPoints()
    owner.ui.rosterUpdate:SetPoint("LEFT", owner.ui.rosterSearch, "RIGHT", 8, 0)
    owner.ui.rosterInvite180:SetWidth(inviteWidth)
    if owner.ui.rosterInvite180.text then owner.ui.rosterInvite180.text:SetWidth(math.max(52, inviteWidth - 8)) end
    owner.ui.rosterInvite180:ClearAllPoints()
    owner.ui.rosterInvite180:SetPoint("LEFT", owner.ui.rosterUpdate, "RIGHT", 8, 0)
    owner.ui.rosterFilters:SetWidth(filtersWidth)
    if owner.ui.rosterFilters.text then owner.ui.rosterFilters.text:SetWidth(math.max(46, filtersWidth - 8)) end
    owner.ui.rosterFilters:ClearAllPoints()
    owner.ui.rosterFilters:SetPoint("LEFT", owner.ui.rosterInvite180, "RIGHT", 8, 0)

    local quickGap = 8
    local quickWidth = math.floor((tableWidth - (quickGap * 2)) / 3)
    local index
    for index = 1, table.getn(owner.ui.rosterQuick) do
        local button = owner.ui.rosterQuick[index]
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", page, "TOPLEFT", (index - 1) * (quickWidth + quickGap), -42)
        button:SetWidth(quickWidth)
        if button.text then button.text:SetWidth(math.max(42, quickWidth - 8)) end
    end

    -- Complex active filters receive a dedicated row instead of extending under Member Details.
    local filter = owner.ui.rosterFilter or (OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.rosterFilter) or "ALL"
    local activeCount = 0
    if filter ~= "ALL" and filter ~= "ONLINE" and filter ~= "LEADERSHIP" then activeCount = activeCount + 1 end
    if owner.ui.rosterRankFilter then activeCount = activeCount + 1 end
    if owner.ui.rosterProfessionFilter then activeCount = activeCount + 1 end
    local hasActiveRow = activeCount > 0
    if hasActiveRow then
        local activeGap = 6
        local activeWidth = math.floor((tableWidth - ((activeCount - 1) * activeGap)) / activeCount)
        local cursorX = 0
        local active = owner.ui.rosterActiveChips
        local ordered = {}
        if filter ~= "ALL" and filter ~= "ONLINE" and filter ~= "LEADERSHIP" then table.insert(ordered, active.filter) end
        if owner.ui.rosterRankFilter then table.insert(ordered, active.rank) end
        if owner.ui.rosterProfessionFilter then table.insert(ordered, active.profession) end
        for index = 1, table.getn(ordered) do
            ordered[index]:ClearAllPoints()
            ordered[index]:SetPoint("TOPLEFT", page, "TOPLEFT", cursorX, -74)
            ordered[index]:SetWidth(activeWidth)
            if ordered[index].text then ordered[index].text:SetWidth(math.max(44, activeWidth - 8)) end
            cursorX = cursorX + activeWidth + activeGap
        end
    end

    local summaryY = hasActiveRow and -108 or -84
    local tableY = hasActiveRow and -130 or -106
    local tableTop = hasActiveRow and 130 or 106
    local tableHeight = math.max(270, height - tableTop)
    local capacity = math.max(MIN_ROW_COUNT, math.floor((tableHeight - 48) / ROW_HEIGHT))
    EnsureRosterRowCapacity(owner, capacity)

    owner.ui.rosterSummary:ClearAllPoints()
    owner.ui.rosterSummary:SetPoint("TOPLEFT", page, "TOPLEFT", 0, summaryY)
    owner.ui.rosterSummary:SetWidth(tableWidth)
    if owner.ui.rosterSummaryChips184 then
        local summaryOrder184 = { "online", "leadership", "level60", "shown" }
        local chipGap184 = 6
        local chipWidth184 = math.floor((tableWidth - (chipGap184 * 3)) / 4)
        for index = 1, table.getn(summaryOrder184) do
            local chip184 = owner.ui.rosterSummaryChips184[summaryOrder184[index]]
            if chip184 then
                chip184:ClearAllPoints()
                chip184:SetPoint("TOPLEFT", page, "TOPLEFT", (index - 1) * (chipWidth184 + chipGap184), summaryY + 2)
                chip184:SetWidth(chipWidth184)
                if chip184.text then chip184.text:SetWidth(math.max(36, chipWidth184 - 6)) end
                chip184:Show()
            end
        end
    end
    owner.ui.rosterTable:ClearAllPoints()
    owner.ui.rosterTable:SetPoint("TOPLEFT", page, "TOPLEFT", 0, tableY)
    owner.ui.rosterTable:SetWidth(tableWidth)
    owner.ui.rosterTable:SetHeight(tableHeight)
    -- Retail-derived clients can provide child clipping; old Vanilla clients
    -- do not. Use it as defence-in-depth while the row-pool capacity rule above
    -- remains the canonical cross-client protection.
    if owner.ui.rosterTable.SetClipsChildren then owner.ui.rosterTable:SetClipsChildren(true) end
    owner.ui.rosterDetails:ClearAllPoints()
    owner.ui.rosterDetails:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)
    owner.ui.rosterDetails:SetWidth(detailsWidth)
    owner.ui.rosterDetails:SetHeight(math.max(500, height - 8))

    LayoutRosterTableColumns180(owner, tableWidth)
    for index = 1, table.getn(owner.ui.rosterTable.rows) do
        local row = owner.ui.rosterTable.rows[index]
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", owner.ui.rosterTable, "TOPLEFT", 8, -40 - ((index - 1) * ROW_HEIGHT))
        if index > capacity then row:Hide() end
    end
    LayoutRosterDetails180(owner.ui.rosterDetails, detailsWidth, math.max(500, height - 8))
    if owner.ui.guildProfile183 and owner.ui.guildProfile183:IsVisible() and owner.PositionGuildProfile183 then
        owner:PositionGuildProfile183("roster-layout")
    end

    owner.ui.rosterTable.empty:SetWidth(math.max(260, tableWidth - 70))
    owner.ui.rosterTable.previous:Hide()
    owner.ui.rosterTable.pageText:Hide()
    owner.ui.rosterTable.next:Hide()
    if owner.ui.rosterTable.scrollbar then
        owner.ui.rosterTable.scrollbar:ClearAllPoints()
        owner.ui.rosterTable.scrollbar:SetPoint("TOPRIGHT", owner.ui.rosterTable, "TOPRIGHT", -3, -40)
        owner.ui.rosterTable.scrollbar:SetHeight(math.max(120, tableHeight - 48))
    end
    owner.ui.rosterVisibleCapacity180 = capacity
    owner.ui.rosterTable.otlNativeLayout = true
    owner.ui.rosterLayoutActiveRow180 = hasActiveRow
    local currentHistoryRows = owner.ui.rosterDetails and tonumber(owner.ui.rosterDetails.historyVisibleRows180) or nil
    if owner.MarkLayoutDataRefresh180 and ((previousCapacity and previousCapacity ~= capacity)
        or (previousHistoryRows and currentHistoryRows and previousHistoryRows ~= currentHistoryRows)) then
        owner:MarkLayoutDataRefresh180("roster")
    end
end

local rosterModule183 = OTLGM:CreateShellPageModule180("roster", BuildRoster,
    function(owner) owner:RefreshRosterPage() end,
    LayoutRoster, { "search", "filters", "saved-views" }, { width = 760, height = 520 })

if rosterModule183 then
    local BaseRosterShow183 = rosterModule183.OnShow
    function rosterModule183:OnShow(context)
        if BaseRosterShow183 then BaseRosterShow183(self, context) end
        if self.owner and self.owner.ui then
            self.owner.ui.rosterAutoProfilePending183 = OTLGM_DB.settings.showGuildProfileOnRoster183 ~= false and true or nil
        end
    end
    local BaseRosterHide183 = rosterModule183.OnHide
    function rosterModule183:OnHide()
        if BaseRosterHide183 then BaseRosterHide183(self) end
        if self.owner and self.owner.ui then self.owner.ui.rosterAutoProfilePending183 = nil end
        if self.owner and self.owner.CloseGuildProfile183 then self.owner:CloseGuildProfile183("roster-hidden") end
    end
end

OTLGM:RegisterModule("RosterPage180", {
    stage = "B",
    revision = 12,
    lazy = true,
    migrated = true,
    nativeContentHost = true,
    pageContract = true,
    savedViews = true,
    selectionOnlyRefresh183 = true,
    noOnUpdate = true,
})
