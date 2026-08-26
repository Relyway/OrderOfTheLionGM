-- Order of the Lion Guild Manager 1.8.0
-- Native ContentHost geometry and continuous scrolling for release pages.
-- Every page is laid out from explicit semantic references. No old window,
-- fixed inner canvas, child-order lookup, size lookup, or text lookup is used.

if not OTLGM or not OTLGM.UI or not OTLGM.nativePageSources then return end

local UI = OTLGM.UI
local C = UI.colors

local function Size(frame, width, height)
    if not frame then return end
    if width then frame:SetWidth(math.max(1, width)) end
    if height then frame:SetHeight(math.max(1, height)) end
end

local function Move(frame, parent, x, y, width, height)
    if not frame or not parent then return end
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 0, y or 0)
    Size(frame, width, height)
end

local function Hide(frame)
    if frame then frame:Hide() end
end

local function Show(frame)
    if frame then frame:Show() end
end

local function Short(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or 60
    if string.len(value) <= maximum then return value end
    return string.sub(value, 1, math.max(1, maximum - 3)) .. "..."
end

local function SuppressLegacy(refs)
    local index
    for index = 1, table.getn(refs and refs.legacyLabels or {}) do
        Hide(refs.legacyLabels[index])
    end
end

local function RegisterSemanticRefs(root, key, refs)
    refs = refs or {}
    refs.toolbar = refs.toolbar or {}
    refs.primaryList = refs.primaryList or {}
    refs.details = refs.details or {}
    refs.footer = refs.footer or {}
    refs.scrollOwner = refs.scrollOwner or {}
    refs.legacyLabels = refs.legacyLabels or {}
    refs.key = key
    root.otlSemanticRefs = refs
    root.otlSemanticContract180 = true
    SuppressLegacy(refs)
    return refs
end

local function SetWheel(frame, handler)
    if not frame then return end
    frame:EnableMouseWheel(1)
    frame:SetScript("OnMouseWheel", function()
        handler(arg1 or 0)
    end)
end

local function SetScrollbar(scrollbar, value, maximum)
    if not scrollbar then return end
    maximum = math.max(0, tonumber(maximum) or 0)
    value = math.max(0, math.min(maximum, tonumber(value) or 0))
    scrollbar.otlSilent = true
    scrollbar:SetMinMaxValues(0, maximum)
    scrollbar:SetValue(value)
    scrollbar.otlSilent = nil
    if maximum > 0 then scrollbar:Show() else scrollbar:Hide() end
end

-- ---------------------------------------------------------------------------
-- Search: dynamic reusable rows and continuous scrolling.
-- ---------------------------------------------------------------------------

local SEARCH_ROW_HEIGHT = 32
local SEARCH_ICONS = {
    MEMBER = "Interface\\Icons\\INV_Misc_GroupNeedMore",
    RECIPE = "Interface\\Icons\\INV_Misc_Book_09",
    ["CRAFT REQUEST"] = "Interface\\Icons\\INV_Letter_15",
    GROUP = "Interface\\Icons\\INV_Helmet_06",
    RAID = "Interface\\Icons\\INV_Misc_Map_01",
    BOARD = "Interface\\Icons\\INV_Misc_Note_06",
    ANNOUNCEMENT = "Interface\\Icons\\INV_Scroll_03",
}

local SEARCH_CLASS_COORDS = {
    WARRIOR = { 0, 0.25, 0, 0.25 }, MAGE = { 0.25, 0.496, 0, 0.25 },
    ROGUE = { 0.496, 0.742, 0, 0.25 }, DRUID = { 0.742, 0.988, 0, 0.25 },
    HUNTER = { 0, 0.25, 0.25, 0.5 }, SHAMAN = { 0.25, 0.496, 0.25, 0.5 },
    PRIEST = { 0.496, 0.742, 0.25, 0.5 }, WARLOCK = { 0.742, 0.988, 0.25, 0.5 },
    PALADIN = { 0, 0.25, 0.5, 0.75 },
}

local SEARCH_GROUP_ICONS = {
    DUNGEON = "Interface\\Icons\\INV_Misc_Key_03",
    QUEST = "Interface\\Icons\\INV_Misc_Note_01",
    FARM = "Interface\\Icons\\INV_Misc_Bag_10",
    ATTUNE = "Interface\\Icons\\INV_Misc_Rune_06",
    RAID = "Interface\\Icons\\INV_Helmet_06",
}

local SEARCH_FILTER_ORDER = {
    { "ALL", "All" }, { "MEMBERS", "Members" }, { "RECIPES", "Recipes" },
    { "GROUPS", "Groups" }, { "POSTS", "Posts" },
}

local SEARCH_TYPE_LABELS_R51 = {
    MEMBER = "Member",
    RECIPE = "Recipe",
    ["CRAFT REQUEST"] = "Craft Request",
    GROUP = "Group",
    RAID = "Raid",
    BOARD = "Guild Post",
    ANNOUNCEMENT = "Announcement",
}

local function SearchResultBucketsR51(results)
    local buckets = { ALL = results or {}, MEMBERS = {}, RECIPES = {}, GROUPS = {}, POSTS = {} }
    local counts = { ALL = table.getn(results or {}), MEMBERS = 0, RECIPES = 0, GROUPS = 0, POSTS = 0 }
    local index, result, resultType, bucketKey
    for index = 1, table.getn(results or {}) do
        result = results[index]
        resultType = tostring(result and result.type or "")
        if resultType == "MEMBER" then bucketKey = "MEMBERS"
        elseif resultType == "RECIPE" then bucketKey = "RECIPES"
        elseif resultType == "GROUP" or resultType == "RAID" then bucketKey = "GROUPS"
        elseif resultType == "ANNOUNCEMENT" or resultType == "BOARD" or resultType == "CRAFT REQUEST" then bucketKey = "POSTS"
        else bucketKey = nil end
        if bucketKey then
            table.insert(buckets[bucketKey], result)
            counts[bucketKey] = counts[bucketKey] + 1
        end
    end
    return buckets, counts
end

local function ResolveSearchIcon(owner, result, texture)
    if not texture then return end
    texture:SetVertexColor(1, 1, 1)
    local resultType = tostring(result and result.type or "")
    if resultType == "MEMBER" then
        local coordinates = SEARCH_CLASS_COORDS[string.upper(tostring(result.class or ""))]
        if coordinates then
            texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
            texture:SetTexCoord(coordinates[1], coordinates[2], coordinates[3], coordinates[4])
            return
        end
    end
    texture:SetTexCoord(0, 1, 0, 1)
    if resultType == "RECIPE" or resultType == "CRAFT REQUEST" then
        local icon = result.icon
        if (not icon or icon == "") and tonumber(result.itemId) and tonumber(result.itemId) > 0
            and owner.GetItemInfoSafe then
            local _, _, _, _, _, _, _, _, _, cachedIcon = owner:GetItemInfoSafe(tonumber(result.itemId))
            icon = cachedIcon
        end
        texture:SetTexture(icon or SEARCH_ICONS.RECIPE)
        return
    end
    if resultType == "GROUP" then
        local kind = string.upper(tostring(result.kind or ""))
        texture:SetTexture(SEARCH_GROUP_ICONS[kind] or SEARCH_ICONS.GROUP)
        return
    end
    if resultType == "RAID" then
        texture:SetTexture(SEARCH_ICONS.RAID)
        return
    end
    texture:SetTexture(SEARCH_ICONS[resultType] or "Interface\\Icons\\INV_Misc_QuestionMark")
end

local function EnsureSearchFilters(owner, toolbar)
    owner.ui.globalSearchFilter180 = owner.ui.globalSearchFilter180 or "ALL"
    owner.ui.globalSearchFilterButtons180 = owner.ui.globalSearchFilterButtons180 or {}
    local index
    for index = 1, table.getn(SEARCH_FILTER_ORDER) do
        local definition = SEARCH_FILTER_ORDER[index]
        local key = definition[1]
        if not owner.ui.globalSearchFilterButtons180[key] then
            owner.ui.globalSearchFilterButtons180[key] = UI:FilterChip(toolbar, definition[2], 82, function()
                owner.ui.globalSearchFilter180 = key
                owner.ui.globalSearchOffset = 0
                owner:RefreshSearchPage(true)
            end)
        end
    end
end

local function ScrollSearch(owner, delta)
    local maximum = tonumber(owner.ui.globalSearchMaximum180) or 0
    local offset = tonumber(owner.ui.globalSearchOffset) or 0
    if delta > 0 then offset = offset - 3 else offset = offset + 3 end
    owner.ui.globalSearchOffset = math.max(0, math.min(maximum, offset))
    owner:RefreshSearchPage(true)
end

local function WireSearchRow(owner, row)
    if row.otlNativeSearchRow180 then return end
    row.otlNativeSearchRow180 = true
    if not row.typeIcon180 then
        row.typeIcon180 = row:CreateTexture(nil, "ARTWORK")
        row.typeIcon180:SetWidth(18)
        row.typeIcon180:SetHeight(18)
        row.typeIcon180:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    SetWheel(row, function(delta) ScrollSearch(owner, delta) end)
end

local function CreateSearchRow(owner, list)
    local row = UI:TableRow(list, 600, 28, function(button)
        if button.resultData then owner:OpenGlobalSearchResult(button.resultData) end
    end)
    row.typeText = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
    row.titleText = UI.Text(row, "", "GameFontNormal", "LEFT")
    row.detailText = UI.Text(row, "", "GameFontHighlightSmall", "LEFT")
    row:Hide()
    WireSearchRow(owner, row)
    return row
end

local function EnsureSearchRows(owner, capacity)
    local list = owner.ui.globalSearchList180
    if not list then return end
    -- Pages.lua creates twelve legacy NButton rows before the native ContentHost
    -- knows its responsive capacity. Mixing those buttons with later TableRow
    -- objects made the bottom rows permanently darker. Retire the legacy pool
    -- once and own one homogeneous native row contract from this point onward.
    if not owner.ui.globalSearchRowsNative184 then
        local legacy = owner.ui.globalSearchRows or {}
        local index
        for index = 1, table.getn(legacy) do if legacy[index] then legacy[index]:Hide() end end
        owner.ui.globalSearchLegacyRows184 = legacy
        owner.ui.globalSearchRows = {}
        owner.ui.globalSearchRowsNative184 = true
    end
    owner.ui.globalSearchRows = owner.ui.globalSearchRows or {}
    while table.getn(owner.ui.globalSearchRows) < capacity do
        local row = CreateSearchRow(owner, list)
        row.otlStyle = "inline"
        table.insert(owner.ui.globalSearchRows, row)
    end
    local index
    for index = 1, table.getn(owner.ui.globalSearchRows) do
        local row = owner.ui.globalSearchRows[index]
        row.otlStyle = "inline"
        WireSearchRow(owner, row)
        -- Do NOT reset an already-bound row during a layout/capacity pass.
        -- ResetReusableRow180 intentionally clears resultData and restores the
        -- icon TexCoord to a generic crop. LayoutSearch can run after refresh
        -- on Vanilla/Octo, which was why MEMBER rows showed the entire class
        -- atlas squeezed into an 18px icon and also lost their click target.
        -- The authoritative reset belongs only in RefreshSearchNative before a
        -- new result is bound to the pooled row.
    end
end

local function RefreshSearchNative(owner)
    if not owner.ui or not owner.ui.globalSearchRows then return end
    local query = owner.ui.globalSearchEdit and (owner.ui.globalSearchEdit:GetText() or "")
        or (OTLGM_DB.settings.globalSearch or "")
    local allResults = {}
    if string.len(query) >= 2 then allResults = owner:GetGlobalSearchResults(query) end
    local filterKey = owner.ui.globalSearchFilter180 or "ALL"
    local categoryCacheR51 = owner.ui.globalSearchCategoryCacheR51
    if not categoryCacheR51 or categoryCacheR51.source ~= allResults then
        local bucketsR51, countsR51 = SearchResultBucketsR51(allResults)
        categoryCacheR51 = { source = allResults, buckets = bucketsR51, counts = countsR51 }
        owner.ui.globalSearchCategoryCacheR51 = categoryCacheR51
    end
    local filterCountsR51 = categoryCacheR51.counts or { ALL = 0, MEMBERS = 0, RECIPES = 0, GROUPS = 0, POSTS = 0 }
    owner.ui.globalSearchFilterCountsR51 = filterCountsR51
    local results = categoryCacheR51.buckets and categoryCacheR51.buckets[filterKey] or allResults
    local capacity = math.max(6, tonumber(owner.ui.globalSearchCapacity180) or 6)
    EnsureSearchRows(owner, capacity)
    local maximum = math.max(0, table.getn(results) - capacity)
    local offset = math.max(0, math.min(maximum, tonumber(owner.ui.globalSearchOffset) or 0))
    owner.ui.globalSearchOffset = offset
    owner.ui.globalSearchMaximum180 = maximum
    local filterIndex, filterDefinition, filterButton
    for filterIndex = 1, table.getn(SEARCH_FILTER_ORDER) do
        filterDefinition = SEARCH_FILTER_ORDER[filterIndex]
        filterButton = owner.ui.globalSearchFilterButtons180 and owner.ui.globalSearchFilterButtons180[filterDefinition[1]]
        if filterButton then
            UI:SetSelected(filterButton, filterDefinition[1] == filterKey)
            local baseLabelR51 = filterDefinition[2]
            local countR51 = tonumber(filterCountsR51[filterDefinition[1]]) or 0
            UI:SetText(filterButton, string.len(query) >= 2 and (baseLabelR51 .. " " .. tostring(countR51)) or baseLabelR51)
        end
    end
    local index, row, result
    for index = 1, table.getn(owner.ui.globalSearchRows) do
        row = owner.ui.globalSearchRows[index]
        if UI.ResetReusableRow180 then UI:ResetReusableRow180(row) end
        -- Every result category uses one neutral table-row surface. Category
        -- identity belongs to icon/type/title text, never to a stale row color.
        if row.SetBackdropColor then row:SetBackdropColor(0.030, 0.026, 0.020, 1) end
        if row.SetBackdropBorderColor then row:SetBackdropBorderColor(C.goldDark[1], C.goldDark[2], C.goldDark[3], 1) end
        result = index <= capacity and results[offset + index] or nil
        if result then
            row.resultData = result
            ResolveSearchIcon(owner, result, row.typeIcon180)
            -- Pooled rows must not inherit class/result colors from earlier occupants.
            -- Category is communicated by the icon and label, while the text palette
            -- remains stable across MEMBER / RECIPE / GROUP / POST results.
            row.typeText:SetText(SEARCH_TYPE_LABELS_R51[tostring(result.type or "")] or "Result")
            row.typeText:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
            row.titleText:SetText(Short(result.title, 48))
            row.titleText:SetTextColor(0.94, 0.92, 0.87)
            row.detailText:SetText(Short(result.detail, 110))
            row.detailText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
            row:Show()
        else
            row.resultData = nil
            row:Hide()
        end
    end
    if string.len(query) < 2 then
        owner.ui.globalSearchStatus:SetText("Enter at least two characters to search across the guild addon.")
    elseif table.getn(results) == 0 then
        if table.getn(allResults) > 0 and filterKey ~= "ALL" then
            owner.ui.globalSearchStatus:SetText("No results in this category. Try All or another filter.")
        else
            owner.ui.globalSearchStatus:SetText("No matching members, recipes, groups or posts were found.")
        end
    else
        owner.ui.globalSearchStatus:SetText(tostring(table.getn(results)) .. " results")
    end
    Hide(owner.ui.globalSearchPrev)
    Hide(owner.ui.globalSearchNext)
    SetScrollbar(owner.ui.globalSearchScrollbar180, offset, maximum)
end

local function LayoutSearch(owner, page, width, height)
    local refs = page.otlSemanticRefs
    SuppressLegacy(refs)
    local toolbar = owner.ui.globalSearchToolbar180
    local list = owner.ui.globalSearchList180
    local footerHeight = 24
    EnsureSearchFilters(owner, toolbar)
    Move(toolbar, page, 0, 0, width, 84)
    if owner.ui.globalSearchEdit then Size(owner.ui.globalSearchEdit, width - 140, 32) end
    if owner.ui.globalSearchHint then owner.ui.globalSearchHint:SetWidth(width - 174) end
    Move(owner.ui.globalSearchButton, toolbar, width - 116, -11, 104, 32)
    local filterGap = 6
    local filterWidth = math.floor((width - 16 - (filterGap * 4)) / 5)
    local filterIndex
    for filterIndex = 1, table.getn(SEARCH_FILTER_ORDER) do
        local filterKey = SEARCH_FILTER_ORDER[filterIndex][1]
        local button = owner.ui.globalSearchFilterButtons180[filterKey]
        Move(button, toolbar, 8 + ((filterIndex - 1) * (filterWidth + filterGap)), -52, filterWidth, 24)
        UI:SetSelected(button, owner.ui.globalSearchFilter180 == filterKey)
    end
    local listHeight = math.max(250, height - 118)
    Move(list, page, 0, -92, width, listHeight)
    local capacity = math.max(6, math.floor((listHeight - 16) / SEARCH_ROW_HEIGHT))
    owner.ui.globalSearchCapacity180 = capacity
    EnsureSearchRows(owner, capacity)
    local index, row
    for index = 1, table.getn(owner.ui.globalSearchRows or {}) do
        row = owner.ui.globalSearchRows[index]
        if index <= capacity then
            Move(row, list, 8, -8 - ((index - 1) * SEARCH_ROW_HEIGHT), width - 34, SEARCH_ROW_HEIGHT - 3)
            Move(row.typeIcon180, row, 8, -5, 18, 18)
            Move(row.typeText, row, 34, -8, 112, 18)
            Move(row.titleText, row, 150, -7, math.max(160, math.floor((width - 190) * 0.34)), 20)
            local detailX = 158 + math.max(160, math.floor((width - 190) * 0.34))
            Move(row.detailText, row, detailX, -8, math.max(130, width - detailX - 44), 18)
        else
            row:Hide()
        end
    end
    Move(owner.ui.globalSearchStatus, page, 0, -(height - footerHeight), width - 20, 20)
    Move(owner.ui.globalSearchScrollbar180, list, width - 20, -8, 14, math.max(80, listHeight - 16))
    Hide(owner.ui.globalSearchPrev)
    Hide(owner.ui.globalSearchNext)
    SetWheel(list, function(delta) ScrollSearch(owner, delta) end)
    page.otlNativeLayout = true
end

-- ---------------------------------------------------------------------------
-- Achievements: separated header, dynamic cards and continuous scrolling.
-- ---------------------------------------------------------------------------

local ACHIEVEMENT_ROW_HEIGHT = 61
local RefreshAchievementsNative

local function ScrollAchievements(owner, delta)
    local maximum = tonumber(owner.ui.achievementMaximum180) or 0
    local offset = tonumber(owner.ui.achievementOffset174) or 0
    if delta > 0 then offset = offset - 1 else offset = offset + 1 end
    owner.ui.achievementOffset174 = math.max(0, math.min(maximum, offset))
    if RefreshAchievementsNative then RefreshAchievementsNative(owner, true) end
end

local function WireAchievementRow(owner, row)
    if not row.otlNativeAchievementRow180 then
        row.otlNativeAchievementRow180 = true
        SetWheel(row, function(delta) ScrollAchievements(owner, delta) end)
    end
    -- Several legacy builders refreshed the full achievement catalog on
    -- OnLeave. Reused native rows must only restore their visual border.
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
        local border = this.otlBorder180
        if border then this:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1) end
    end)
end

local function CreateAchievementRow(owner, list)
    local row = UI:TableRow(list, 500, 57, function(button)
        if not button.achievement174 then return end
        if IsShiftKeyDown and IsShiftKeyDown() then
            if owner:InsertAchievementLinkInBlizzardChat174(button.achievement174) then return end
            if owner.InsertGuildChatLink then
                owner:InsertGuildChatLink(owner:GetAchievementLink174(button.achievement174), true)
                return
            end
        end
        owner:FocusAchievement174(button.achievement174.id)
    end)
    row.icon174 = row:CreateTexture(nil, "ARTWORK")
    row.icon174:SetWidth(41)
    row.icon174:SetHeight(41)
    row.icon174:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.name174 = UI.Text(row, "", "GameFontNormal", "LEFT")
    row.description174 = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
    row.description174:SetTextColor(0.66, 0.66, 0.63)
    row.status174 = UI.Text(row, "", "GameFontNormalSmall", "RIGHT")
    row.date174 = UI.Text(row, "", "GameFontNormalSmall", "RIGHT")
    -- Persistent focus state is independent from Track/Untrack.  Native rows
    -- replace the six legacy cards, so selection visuals must live here too.
    row.selectedWash174 = row:CreateTexture(nil, "BACKGROUND")
    row.selectedWash174:SetAllPoints(row)
    row.selectedWash174:SetTexture(0.12, 0.38, 0.72, 0.16)
    row.selectedWash174:Hide()
    row.selectedRail174 = row:CreateTexture(nil, "ARTWORK")
    row.selectedRail174:SetPoint("TOPLEFT", row, "TOPLEFT", 2, -3)
    row.selectedRail174:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 2, 3)
    row.selectedRail174:SetWidth(4)
    row.selectedRail174:SetTexture(0.30, 0.72, 1, 0.96)
    row.selectedRail174:Hide()
    -- A quiet progress strip makes partially completed goals scannable without
    -- adding another text column. It updates only on page refresh: no animation
    -- and no additional OnUpdate work.
    row.progressTrack184 = row:CreateTexture(nil, "ARTWORK")
    row.progressTrack184:SetTexture(0.10, 0.09, 0.075, 1)
    row.progressFill184 = row:CreateTexture(nil, "ARTWORK")
    row.progressFill184:SetTexture(0.93, 0.68, 0.22, 0.86)
    row.progressTrack184:Hide()
    row.progressFill184:Hide()
    row:SetScript("OnEnter", function()
        if not this.achievement174 then return end
        this:SetBackdropBorderColor(0.34, 0.70, 1, 1)
        local complete = OTLGM:IsAchievementComplete174(this.achievement174.id)
        local name, description = OTLGM:GetAchievementPresentation174(this.achievement174, complete)
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:AddLine(name, 1, 0.82, 0.35)
        GameTooltip:AddLine(description, 1, 1, 1, true)
        GameTooltip:AddLine("Shift-click to link", 0.52, 0.72, 1)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
        local border = this.otlBorder180
        if border then this:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1) end
    end)
    WireAchievementRow(owner, row)
    row:Hide()
    return row
end

local function EnsureAchievementRows(owner, capacity)
    local list = owner.ui.achievementList174
    if not list then return end
    -- AchievementRaidRuntime.lua builds six pre-native cards without progress
    -- textures. A responsive seventh row was therefore the only row capable of
    -- displaying a progress strip. Replace that mixed pool once instead of
    -- trying to bolt native fields onto only the newly-created rows.
    if not owner.ui.achievementRowsNative184 then
        local legacy = owner.ui.achievementRows174 or {}
        local index
        for index = 1, table.getn(legacy) do if legacy[index] then legacy[index]:Hide() end end
        owner.ui.achievementLegacyRows184 = legacy
        owner.ui.achievementRows174 = {}
        owner.ui.achievementRowsNative184 = true
    end
    owner.ui.achievementRows174 = owner.ui.achievementRows174 or {}
    while table.getn(owner.ui.achievementRows174) < capacity do
        table.insert(owner.ui.achievementRows174, CreateAchievementRow(owner, list))
    end
    local index
    for index = 1, table.getn(owner.ui.achievementRows174) do
        WireAchievementRow(owner, owner.ui.achievementRows174[index])
    end
end

local function HumanAchievementProgressNative184(def, current, required)
    if not def then return nil end
    current = math.max(0, tonumber(current) or 0)
    required = math.max(1, tonumber(required) or 1)
    if def.progress == "groupSeconds" or def.progress == "longWatchSeconds" then
        if required >= 3600 then
            local currentHours = math.floor((current / 3600) * 10) / 10
            local requiredHours = math.floor(required / 3600)
            return tostring(currentHours) .. " / " .. tostring(requiredHours) .. " h"
        end
        return tostring(math.floor(current / 60)) .. " / " .. tostring(math.floor(required / 60)) .. " min"
    elseif def.progress == "regularTableSeconds" or def.progress == "raidPresence" then
        return tostring(math.floor(current / 60)) .. " / " .. tostring(math.floor(required / 60)) .. " min"
    end
    return nil
end

local function HideAchievementRowTooltipNative184(owner)
    if not GameTooltip or not GameTooltip.GetOwner or not owner.ui or not owner.ui.achievementRows174 then return end
    local ok, tooltipOwner = pcall(GameTooltip.GetOwner, GameTooltip)
    if not ok or not tooltipOwner then return end
    local index
    for index = 1, table.getn(owner.ui.achievementRows174) do
        if tooltipOwner == owner.ui.achievementRows174[index] then
            GameTooltip:Hide()
            return
        end
    end
end

RefreshAchievementsNative = function(owner, useCache)
    if not owner.ui or not owner.ui.achievementRows174 then return end
    -- Recycled rows can move under the mouse while scrolling; a Vanilla
    -- GameTooltip does not always receive OnLeave in that case and can display
    -- the achievement that previously occupied the row. Clear only tooltips
    -- owned by these recycled rows before rebinding them.
    HideAchievementRowTooltipNative184(owner)
    local list
    if useCache and owner.ui.achievementFilteredCache180 then
        list = owner.ui.achievementFilteredCache180
    else
        list = owner:GetAchievementDisplayList174()
        owner.ui.achievementFilteredCache180 = list
    end
    local capacity = math.max(5, tonumber(owner.ui.achievementCapacity180) or 5)
    EnsureAchievementRows(owner, capacity)
    local maximum = math.max(0, table.getn(list) - capacity)
    local offset = math.max(0, math.min(maximum, tonumber(owner.ui.achievementOffset174) or 0))
    owner.ui.achievementOffset174 = offset
    owner.ui.achievementMaximum180 = maximum
    local index, row, def, complete, name, description, icon, secret, current, required, when
    for index = 1, table.getn(owner.ui.achievementRows174) do
        row = owner.ui.achievementRows174[index]
        def = index <= capacity and list[offset + index] or nil
        if def then
            complete = owner:IsAchievementComplete174(def.id)
            name, description, icon, secret = owner:GetAchievementPresentation174(def, complete)
            current, required = owner:GetAchievementProgress174(def)
            when = owner:GetAchievementCompletedAt174(def.id)
            row.achievement174 = def
            row.icon174:SetTexture(def.icon or icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.name174:SetText(name)
            row.description174:SetText(description)
            if complete then
                row:SetBackdropColor(0.075, 0.052, 0.020, 1)
                row:SetBackdropBorderColor(0.68, 0.44, 0.12, 1)
                row.otlBorder180 = { 0.68, 0.44, 0.12, 1 }
                row.icon174:SetVertexColor(1, 1, 1)
                row.name174:SetTextColor(1, 0.82, 0.35)
                row.status174:SetText("COMPLETE")
                row.status174:SetTextColor(0.35, 0.95, 0.42)
                row.date174:SetText(when and date("%d %b %Y", when) or "")
            elseif secret then
                row:SetBackdropColor(0.035, 0.020, 0.050, 1)
                row:SetBackdropBorderColor(0.38, 0.18, 0.52, 1)
                row.otlBorder180 = { 0.38, 0.18, 0.52, 1 }
                row.icon174:SetVertexColor(0.72, 0.45, 0.94)
                row.name174:SetTextColor(0.78, 0.46, 1)
                row.status174:SetText("SECRET")
                row.status174:SetTextColor(0.78, 0.46, 1)
                row.date174:SetText("")
            else
                row:SetBackdropColor(0.025, 0.023, 0.020, 1)
                row:SetBackdropBorderColor(0.24, 0.22, 0.19, 1)
                row.otlBorder180 = { 0.24, 0.22, 0.19, 1 }
                row.icon174:SetVertexColor(0.40, 0.40, 0.40)
                row.name174:SetTextColor(0.72, 0.72, 0.70)
                if def.unitR6 == "gold" then
                    row.status174:SetText(tostring(math.floor((current or 0) / 10000))
                        .. " / " .. tostring(math.floor((required or 0) / 10000)) .. "g")
                else
                    local humanProgress184 = HumanAchievementProgressNative184(def, current, required)
                    if humanProgress184 then
                        row.status174:SetText(humanProgress184)
                    elseif (tonumber(current) or 0) > 0 then
                        row.status174:SetText(tostring(math.floor(current)) .. " / " .. tostring(math.floor(required)))
                    else
                        row.status174:SetText("Not started")
                    end
                end
                row.status174:SetTextColor(current > 0 and 1 or 0.72,
                    current > 0 and 0.78 or 0.72, current > 0 and 0.18 or 0.68)
                row.date174:SetText("")
            end
            if row.progressTrack184 and row.progressFill184 then
                local progressCurrent = math.max(0, tonumber(current) or 0)
                local progressRequired = math.max(0, tonumber(required) or 0)
                if not complete and not secret and progressCurrent > 0 and progressRequired > 0 then
                    local ratio184 = math.max(0, math.min(1, progressCurrent / progressRequired))
                    row.otlProgressRatio184 = ratio184
                    local trackWidth184 = math.max(1, tonumber(row.otlProgressWidth184) or 100)
                    row.progressFill184:SetWidth(math.max(1, math.floor(trackWidth184 * ratio184)))
                    row.progressTrack184:Show()
                    row.progressFill184:Show()
                else
                    row.otlProgressRatio184 = nil
                    row.progressTrack184:Hide()
                    row.progressFill184:Hide()
                end
            end
            local trackedR32 = not complete and owner.IsAchievementTracked183 and owner:IsAchievementTracked183(def.id)
            if trackedR32 then
                row.date174:SetText("MY GOAL")
                row.date174:SetTextColor(C.orange[1], C.orange[2], C.orange[3])
                if owner.ui.achievementFocus174 ~= def.id then
                    row:SetBackdropBorderColor(C.orange[1], C.orange[2], C.orange[3], 0.82)
                    row.otlBorder180 = { C.orange[1], C.orange[2], C.orange[3], 0.82 }
                end
            elseif not complete then
                row.date174:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
            end
            if owner.ui.achievementFocus174 == def.id then
                row:SetBackdropBorderColor(0.30, 0.72, 1, 1)
                row.otlBorder180 = { 0.30, 0.72, 1, 1 }
                if row.selectedWash174 then row.selectedWash174:Show() end
                if row.selectedRail174 then row.selectedRail174:Show() end
            else
                if row.selectedWash174 then row.selectedWash174:Hide() end
                if row.selectedRail174 then row.selectedRail174:Hide() end
            end
            row:Show()
        else
            row.achievement174 = nil
            if row.progressTrack184 then row.progressTrack184:Hide() end
            if row.progressFill184 then row.progressFill184:Hide() end
            if row.selectedWash174 then row.selectedWash174:Hide() end
            if row.selectedRail174 then row.selectedRail174:Hide() end
            row:Hide()
        end
    end
    if table.getn(list) == 0 then
        owner.ui.achievementStatus174:SetText("No achievements match this view.")
        owner.ui.achievementStatus174:Show()
    else
        owner.ui.achievementStatus174:Hide()
    end
    Hide(owner.ui.achievementPrev174)
    Hide(owner.ui.achievementNext174)
    SetScrollbar(owner.ui.achievementScrollbar180, offset, maximum)
    -- Native scrolling recycles row frames. Refresh the optional Track control
    -- after assigning achievement174 so a button can never remain attached to
    -- the achievement that previously occupied this row.
    if owner.RefreshAchievementTrackingButtons183 then owner:RefreshAchievementTrackingButtons183() end
end

local function LayoutAchievements(owner, page, width, height)
    local refs = page.otlSemanticRefs
    SuppressLegacy(refs)
    local summaryHeight = 58
    local toolbarY = 66
    local toolbarHeight = 30
    local bodyY = toolbarY + toolbarHeight + 8
    local categories = owner.ui.achievementCategories174
    local list = owner.ui.achievementList174
    local categoryWidth = math.max(176, math.min(204, math.floor(width * 0.21)))
    Move(owner.ui.achievementTitleIcon174, page, 0, -2, 28, 28)
    Move(owner.ui.achievementSummaryTitle174, page, 38, -1, math.max(260, width - 260), 24)
    Move(owner.ui.achievementSummarySubtitle174, page, 38, -27, math.max(260, width - 260), 18)
    Move(owner.ui.achievementCount174, page, width - 146, -3, 146, 22)
    Move(owner.ui.achievementProgressPanel174, page, 38, -43, math.max(240, width - 250), 13)
    Move(owner.ui.achievementProgressText174, page, width - 190, -43, 190, 18)
    local completed, total = owner:GetAchievementCount174()
    local ratio = total > 0 and completed / total or 0
    if owner.ui.achievementProgressFill174 then
        owner.ui.achievementProgressFill174:SetWidth(math.max(1,
            math.floor((owner.ui.achievementProgressPanel174:GetWidth() - 6) * ratio)))
    end
    local searchWidth = math.max(190, width - 438)
    Move(owner.ui.achievementSearch174, page, 0, -toolbarY, searchWidth, toolbarHeight)
    Move(owner.ui.achievementSearchPlaceholder175, page, 10, -(toolbarY + 7), searchWidth - 20, 18)
    local filterStart = searchWidth + 8
    local filterGap = 6
    local filterWidth = math.floor((width - filterStart - (filterGap * 3)) / 4)
    local order = { "ALL", "COMPLETE", "PROGRESS", "LOCKED" }
    local index
    for index = 1, table.getn(order) do
        Move(owner.ui.achievementFilterButtons174[order[index]], page,
            filterStart + ((index - 1) * (filterWidth + filterGap)), -toolbarY, filterWidth, toolbarHeight)
    end
    local bodyHeight = math.max(300, height - bodyY)
    Move(categories, page, 0, -bodyY, categoryWidth, bodyHeight)
    Move(list, page, categoryWidth + 8, -bodyY, width - categoryWidth - 8, bodyHeight)
    local capacity = math.max(5, math.floor((bodyHeight - 14) / ACHIEVEMENT_ROW_HEIGHT))
    owner.ui.achievementCapacity180 = capacity
    EnsureAchievementRows(owner, capacity)
    local rowWidth = list:GetWidth() - 32
    local row
    for index = 1, table.getn(owner.ui.achievementRows174 or {}) do
        row = owner.ui.achievementRows174[index]
        if index <= capacity then
            Move(row, list, 8, -7 - ((index - 1) * ACHIEVEMENT_ROW_HEIGHT), rowWidth, 57)
            Move(row.icon174, row, 8, -8, 41, 41)
            Move(row.name174, row, 58, -7, math.max(170, rowWidth - 210), 19)
            Move(row.description174, row, 58, -27, math.max(180, rowWidth - 200), 27)
            Move(row.status174, row, rowWidth - 132, -9, 122, 18)
            Move(row.date174, row, rowWidth - 132, -31, 122, 18)
            -- Reserve the lower-right corner for SocialProfiles183's Track /
            -- Untrack button. Progress used to occupy the same pixels and could
            -- visually merge with the button after Overview/scroll row reuse.
            -- Progress belongs to the text lane, not to the action corner.
            -- Keeping a fixed gap before the right status/Track lane prevents
            -- the thin bar from visually running into a recycled Track button.
            local progressX184 = 58
            local progressWidth184 = math.max(86, rowWidth - progressX184 - 174)
            row.otlProgressWidth184 = progressWidth184
            Move(row.progressTrack184, row, progressX184, -50, progressWidth184, 3)
            local fillWidth184 = math.max(1, math.floor(progressWidth184 * (tonumber(row.otlProgressRatio184) or 0)))
            Move(row.progressFill184, row, progressX184, -50, fillWidth184, 3)
            if row.otlGoalButton183 then
                row.otlGoalButton183:ClearAllPoints()
                row.otlGoalButton183:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, 5)
                row.otlGoalButton183:SetWidth(62) row.otlGoalButton183:SetHeight(20)
                if row.otlGoalButton183.SetFrameLevel and row.GetFrameLevel then
                    row.otlGoalButton183:SetFrameLevel(row:GetFrameLevel() + 12)
                end
            end
        else
            row:Hide()
        end
    end
    Move(owner.ui.achievementScrollbar180, list, list:GetWidth() - 19, -7, 14, math.max(80, bodyHeight - 14))
    Move(owner.ui.achievementStatus174, list, 20, -math.floor(bodyHeight / 2), list:GetWidth() - 40, 24)
    Hide(owner.ui.achievementPrev174)
    Hide(owner.ui.achievementNext174)
    SetWheel(list, function(delta) ScrollAchievements(owner, delta) end)
    page.otlNativeLayout = true
end

-- ---------------------------------------------------------------------------
-- Guild chat and Guild Board.
-- ---------------------------------------------------------------------------

local function EnsureChatInput(owner)
    local edit = owner.ui.guildChatEdit
    if not edit or edit.otlNativeInput180 then return end
    edit.otlNativeInput180 = true
    UI:MakeOpaque(edit, C.input, C.goldMuted)
    if edit.SetTextInsets then edit:SetTextInsets(10, 10, 0, 0) end
    local placeholder = UI.Text(edit, "Write a message…", "GameFontNormalSmall", "LEFT")
    placeholder:SetPoint("LEFT", edit, "LEFT", 10, 0)
    placeholder:SetWidth(math.max(100, edit:GetWidth() - 20))
    placeholder:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    owner.ui.guildChatPlaceholder180 = placeholder
    local previousChanged = edit.otlChanged
    edit.otlChanged = function(value, field)
        if previousChanged then previousChanged(value, field) end
        if value == "" and not OTLGM.guildChatEditFocused then
            OTLGM.ui.guildChatPlaceholder180:Show()
        else
            OTLGM.ui.guildChatPlaceholder180:Hide()
        end
    end
    edit.otlFocusGainedCallback180 = function(field)
        OTLGM.guildChatEditFocused = true
        OTLGM.ui.guildChatPlaceholder180:Hide()
        field:SetBackdropBorderColor(C.gold[1], C.gold[2], C.gold[3], 1)
    end
    edit.otlFocusLostCallback180 = function(field)
        OTLGM.guildChatEditFocused = nil
        if (field:GetText() or "") == "" then OTLGM.ui.guildChatPlaceholder180:Show() end
        field:SetBackdropBorderColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3], 1)
    end
    if not owner.ui.guildChatFooter180 then
        local footer = CreateFrame("Frame", nil, edit:GetParent())
        owner.ui.guildChatFooter180 = footer
        if edit.SetParent then edit:SetParent(footer) end
        if owner.ui.guildChatSendButton and owner.ui.guildChatSendButton.SetParent then owner.ui.guildChatSendButton:SetParent(footer) end
    end
end

function OTLGM:LayoutChatRows180()
    local ui = self.ui
    local list = ui and ui.chatList
    if not list then return false end
    local width = tonumber(list:GetWidth()) or 0
    local height = tonumber(list:GetHeight()) or 0
    local headerBottom = 30
    local bottomInset = 3
    local total, index, row, visibleCount = 0, 1, nil, 0
    for index = 1, table.getn(ui.chatRows or {}) do
        row = ui.chatRows[index]
        if row and row:IsVisible() then
            total = total + (tonumber(row:GetHeight()) or 0)
            visibleCount = visibleCount + 1
        end
    end

    local visibleBottom = height - bottomInset
    local available = math.max(0, visibleBottom - headerBottom)
    local slack = math.max(0, available - total)
    local channel = self.GetGuildChatChannel and self:GetGuildChatChannel() or "GUILD"
    local offset = ui.chatOffsets and (tonumber(ui.chatOffsets[channel]) or 0) or 0
    local messages = self.GetGuildChatMessages and self:GetGuildChatMessages(channel) or {}
    local hasEarlierHistory = table.getn(messages or {}) > visibleCount

    -- r28: short histories remain top-aligned.  Only the canonical Newest
    -- window of a longer history consumes whole-row remainder at the top so
    -- the last full row lands against the bottom inset.  Scroll-up keeps its
    -- old top anchor and never jumps merely to hide pagination slack.
    local anchorNewest = offset == 0 and hasEarlierHistory and visibleCount > 0
    local cursor = headerBottom + (anchorNewest and slack or 0)
    ui.chatContentHeight180 = total
    ui.chatBottomSlackR28 = anchorNewest and math.max(0, visibleBottom - (cursor + total)) or slack
    ui.chatBottomAnchoredR28 = anchorNewest and true or false
    ui.chatHistoryBottomInsetR28 = bottomInset

    local laidOut = 0
    for index = 1, table.getn(ui.chatRows or {}) do
        row = ui.chatRows[index]
        if row then
            local rowHeight = tonumber(row:GetHeight()) or 0
            row:SetWidth(math.max(1, width - 44))
            if row:IsVisible() then
                local rowBottom = cursor + rowHeight
                if cursor >= headerBottom and rowBottom <= visibleBottom + 0.5 then
                    row:ClearAllPoints()
                    row:SetPoint("TOPLEFT", list, "TOPLEFT", 8, -cursor)
                    row.otlChatTop180 = cursor
                    row.otlChatBottom180 = rowBottom
                    laidOut = laidOut + 1
                    cursor = rowBottom
                else
                    row:Hide()
                    row.otlChatTop180 = nil
                    row.otlChatBottom180 = nil
                end
            else
                row.otlChatTop180 = nil
                row.otlChatBottom180 = nil
            end
            if row.newLine then row.newLine:SetWidth(math.max(1, width - 44)) end
            if row.separatorText then row.separatorText:SetWidth(math.max(1, width - 68)) end
        end
    end
    ui.chatRowsLaidOut180 = laidOut
    ui.chatLayoutPasses180 = (tonumber(ui.chatLayoutPasses180) or 0) + 1
    return true
end

local function ScrollGuildBoard(owner, delta)
    local posts = owner:GetPveBoardPosts() or {}
    local maximum = math.max(0, table.getn(posts) - table.getn(owner.ui.guildBoardChatRows152 or {}))
    local offset = tonumber(owner.ui.guildBoardOffset152) or 0
    if delta > 0 then offset = offset - 1 else offset = offset + 1 end
    owner.ui.guildBoardOffset152 = math.max(0, math.min(maximum, offset))
    owner:RefreshGuildBoardChat152()
end

local function EnsureGuildBoardListScrollbar180(owner)
    local list = owner.ui.guildBoardList152
    if not list or owner.ui.guildBoardListScrollbar180 then return end
    local bar = UI:Scrollbar(list, 240, function(value)
        owner.ui.guildBoardOffset152 = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
        owner:RefreshGuildBoardChat152()
    end)
    owner.ui.guildBoardListScrollbar180 = bar
    SetWheel(list, function(delta) ScrollGuildBoard(owner, delta) end)
end

local function EnsureGuildBoardScroll(owner)
    local detail = owner.ui.guildBoardDetails152
    local body = owner.ui.guildBoardBodyPanel152
    if not detail or not body or owner.ui.guildBoardDetailScroll180 then return end
    local scroll = CreateFrame("ScrollFrame", nil, detail)
    owner.ui.guildBoardDetailScroll180 = scroll
    body:SetParent(scroll)
    if scroll.SetScrollChild then scroll:SetScrollChild(body) end
    local bar = UI:Scrollbar(detail, 200, function(value)
        if scroll.SetVerticalScroll then scroll:SetVerticalScroll(math.floor(value + 0.5)) end
    end)
    owner.ui.guildBoardDetailScrollbar180 = bar
    SetWheel(scroll, function(delta)
        local maximum = tonumber(scroll.otlMaximum180) or 0
        local value = owner.ui.guildBoardDetailScrollbar180:GetValue() or 0
        if delta > 0 then value = value - 28 else value = value + 28 end
        value = math.max(0, math.min(maximum, value))
        owner.ui.guildBoardDetailScrollbar180:SetValue(value)
    end)
end

local function RefreshGuildBoardNative(owner)
    if not owner.ui or not owner.ui.guildBoardChatPanel152 then return end
    local posts = owner:GetPveBoardPosts() or {}
    local empty = table.getn(posts) == 0
    if owner.ui.guildBoardEmpty180 then
        if empty then owner.ui.guildBoardEmpty180:Show() else owner.ui.guildBoardEmpty180:Hide() end
    end
    EnsureGuildBoardListScrollbar180(owner)
    EnsureGuildBoardScroll(owner)
    local visibleRows = table.getn(owner.ui.guildBoardChatRows152 or {})
    local listMaximum = math.max(0, table.getn(posts) - visibleRows)
    local listOffset = math.max(0, math.min(listMaximum, tonumber(owner.ui.guildBoardOffset152) or 0))
    owner.ui.guildBoardOffset152 = listOffset
    local listBar = owner.ui.guildBoardListScrollbar180
    if listBar and listBar.SetScrollMetrics180 then
        listBar:SetScrollMetrics180(table.getn(posts), math.max(1, visibleRows), listOffset)
    elseif listBar then
        SetScrollbar(listBar, listOffset, listMaximum)
    end
    local scroll = owner.ui.guildBoardDetailScroll180
    local body = owner.ui.guildBoardBodyPanel152
    local text = owner.ui.guildBoardDetailBody152
    if scroll and body and text then
        local measured = text.GetStringHeight and math.max(120, (text:GetStringHeight() or 100) + 30) or 150
        body:SetHeight(measured)
        local visible = scroll:GetHeight()
        local maximum = math.max(0, measured - visible)
        scroll.otlMaximum180 = maximum
        SetScrollbar(owner.ui.guildBoardDetailScrollbar180,
            owner.ui.guildBoardDetailScrollbar180:GetValue() or 0, maximum)
    end
end

local function EnsureGuildBoardComposer180(owner)
    local ui = owner.ui
    local list = ui.guildBoardList152
    local edit = ui.guildBoardNewEdit152
    if not list or not edit or ui.guildBoardComposerScroll180 then return end
    local scroll = CreateFrame("ScrollFrame", nil, list)
    scroll:EnableMouse(true)
    scroll:EnableMouseWheel(true)
    edit:SetParent(scroll)
    edit:ClearAllPoints()
    edit:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    edit:SetWidth(220)
    edit:SetHeight(180)
    if scroll.SetScrollChild then scroll:SetScrollChild(edit) end
    scroll:SetScript("OnMouseWheel", function()
        local value = this:GetVerticalScroll() - ((tonumber(arg1) or 0) * 24)
        local maximum = math.max(0, (edit:GetHeight() or 180) - (this:GetHeight() or 100))
        this:SetVerticalScroll(math.max(0, math.min(maximum, value)))
    end)
    ui.guildBoardComposerScroll180 = scroll
end

local function LayoutGuildBoard(owner, page, width, height, bodyY, bodyHeight)
    local panel = owner.ui.guildBoardChatPanel152
    local list = owner.ui.guildBoardList152
    local detail = owner.ui.guildBoardDetails152
    local posts = owner:GetPveBoardPosts() or {}
    local empty = table.getn(posts) == 0
    Move(panel, page, 0, -bodyY, width, bodyHeight)
    if not owner.ui.guildBoardEmpty180 then
        local state = UI:EmptyState(list, 420, 126, "No Guild Board posts",
            "Create a compact community post below, or use Check Updates to look for recent guild posts.")
        owner.ui.guildBoardEmpty180 = state
    end
    if empty then
        Move(list, panel, 0, 0, width, bodyHeight)
        Hide(detail)
        Move(owner.ui.guildBoardEmpty180, list, math.max(12, math.floor((width - 460) / 2)),
            -math.max(60, math.floor((bodyHeight - 126) / 2) - 24), math.min(460, width - 24), 126)
    else
        local listWidth = math.max(300, math.floor(width * 0.38))
        Move(list, panel, 0, 0, listWidth, bodyHeight)
        Move(detail, panel, listWidth + 8, 0, width - listWidth - 8, bodyHeight)
        Show(detail)
        Hide(owner.ui.guildBoardEmpty180)
    end
    local listWidth = list:GetWidth()
    EnsureGuildBoardListScrollbar180(owner)
    local composerHeight = 126
    local navY = bodyHeight - composerHeight - 8
    local rowArea = math.max(160, navY - 32)
    local rows = owner.ui.guildBoardChatRows152 or {}
    local rowHeight = math.max(32, math.min(43, math.floor(rowArea / math.max(1, table.getn(rows)))))
    local index, row
    for index = 1, table.getn(rows) do
        row = rows[index]
        Move(row, list, 10, -32 - ((index - 1) * rowHeight), listWidth - 38, rowHeight - 3)
        if row.titleText then row.titleText:SetWidth(math.max(120, listWidth - 132)) end
        if row.previewText then row.previewText:SetWidth(math.max(150, listWidth - 28)) end
        if row.metaText then
            row.metaText:ClearAllPoints()
            row.metaText:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -6)
            row.metaText:SetWidth(92)
        end
        SetWheel(row, function(delta) ScrollGuildBoard(owner, delta) end)
    end
    Move(owner.ui.guildBoardListScrollbar180, list, listWidth - 19, -32, 14, rowArea)
    Hide(owner.ui.guildBoardPrev152)
    Hide(owner.ui.guildBoardNext152)
    Move(owner.ui.guildBoardComposerLabel152, list, 12, -(bodyHeight - composerHeight + 2), listWidth - 104, 18)
    if owner.ui.guildBoardCount152 then Move(owner.ui.guildBoardCount152, list, listWidth - 86, -(bodyHeight - composerHeight + 2), 74, 18) end
    EnsureGuildBoardComposer180(owner)
    Move(owner.ui.guildBoardComposerScroll180, list, 10, -(bodyHeight - composerHeight + 24), listWidth - 20, 90)
    owner.ui.guildBoardNewEdit152:SetWidth(math.max(180, listWidth - 38))
    owner.ui.guildBoardNewEdit152:SetHeight(180)
    Move(owner.ui.guildBoardPostButton152, list, listWidth - 92, -(bodyHeight - 34), 82, 28)
    SetWheel(list, function(delta) ScrollGuildBoard(owner, delta) end)
    if not empty then
        local detailWidth = detail:GetWidth()
        Move(owner.ui.guildBoardDetailsTitle152, detail, 12, -10, detailWidth - 24, 18)
        Move(owner.ui.guildBoardDetailTitle152, detail, 12, -36, detailWidth - 24, 40)
        Move(owner.ui.guildBoardDetailMeta152, detail, 12, -80, detailWidth - 24, 18)
        EnsureGuildBoardScroll(owner)
        local actionsHeight = 104
        local scrollHeight = math.max(120, bodyHeight - 108 - actionsHeight)
        Move(owner.ui.guildBoardDetailScroll180, detail, 10, -106, detailWidth - 34, scrollHeight)
        Move(owner.ui.guildBoardBodyPanel152, owner.ui.guildBoardDetailScroll180, 0, 0,
            detailWidth - 36, math.max(scrollHeight, owner.ui.guildBoardBodyPanel152:GetHeight()))
        Move(owner.ui.guildBoardDetailBody152, owner.ui.guildBoardBodyPanel152, 12, -12,
            detailWidth - 60, math.max(100, owner.ui.guildBoardBodyPanel152:GetHeight() - 24))
        Move(owner.ui.guildBoardDetailScrollbar180, detail, detailWidth - 19, -106, 14, scrollHeight)
        local reactionWidth = math.floor((detailWidth - 40) / 3)
        local order = { "HEART", "FUNNY", "SEEN" }
        for index = 1, table.getn(order) do
            Move(owner.ui.guildBoardReactionButtons152[order[index]], detail,
                12 + ((index - 1) * (reactionWidth + 6)), -(bodyHeight - 94), reactionWidth, 28)
        end
        local actionY = bodyHeight - 58
        Move(owner.ui.guildBoardWhisper152, detail, 12, -actionY, 82, 28)
        Move(owner.ui.guildBoardShare152, detail, 102, -actionY, 104, 28)
        Move(owner.ui.guildBoardDelete152, detail, 214, -actionY, 78, 28)
        Move(owner.ui.guildBoardSync152, detail, detailWidth - 110, -actionY, 98, 28)
        Hide(owner.ui.guildBoardInfo152)
    end
end

local function LayoutGuildChat(owner, page, width, height)
    -- Deep links (notably mention notifications) can change the desired chat
    -- channel before the lazily-built Guild Chat controls exist. Layout must not
    -- dereference those controls until the page builder has completed.
    if not owner or not owner.ui or not page or not owner.ui.chatChannelButtons or not owner.ui.chatList then return false end
    local previousViewportHeight = tonumber(owner.ui.chatViewportHeight180)
    local refs = page.otlSemanticRefs
    SuppressLegacy(refs)
    EnsureChatInput(owner)
    local toolbarHeight = 34
    local composerHeight = 38
    local gap = 12
    local bottomInset = 10
    local bodyY = toolbarHeight + gap
    local composerTop = math.max(bodyY + 96 + gap, height - bottomInset - composerHeight)
    local bodyHeight = math.max(96, composerTop - bodyY - gap)
    local order = { "GUILD", "OFFICER", "BOARD" }
    local index
    for index = 1, table.getn(order) do
        Move(owner.ui.chatChannelButtons[order[index]], page, (index - 1) * 136, -2, 128, 30)
    end
    if owner.ui.chatClearButton then owner.ui.chatClearButton:Hide() end
    Move(owner.ui.chatHighlightsButton180, page, width - 100, -2, 100, 30)
    Move(owner.ui.chatNewestButton, page, width - 192, -2, 84, 30)
    Move(owner.ui.chatUnreadText, page, width - 306, -9, 112, 20)
    local view = OTLGM_DB.settings.guildChatView or "GUILD"
    if view == "BOARD" then
        LayoutGuildBoard(owner, page, width, height, bodyY, height - bodyY)
        page.otlNativeLayout = true
        return
    end
    local showOfficer = view == "OFFICER" and width >= 840 and owner.ui.officerOnlinePanel
    local officerWidth = showOfficer and math.max(170, math.floor(width * 0.20)) or 0
    local chatWidth = width - (showOfficer and (officerWidth + gap) or 0)
    owner.ui.chatLayout180 = { page = page, chatWidth = chatWidth, bodyY = bodyY, bodyHeight = bodyHeight }
    Move(owner.ui.chatList, page, 0, -bodyY, chatWidth, bodyHeight)
    if owner.LayoutChatHighlights180 then owner:LayoutChatHighlights180(page, chatWidth, bodyY, bodyHeight) end
    owner.ui.chatViewportHeight180 = bodyHeight
    if previousViewportHeight and math.abs(previousViewportHeight - bodyHeight) > 1 and owner.MarkLayoutDataRefresh180 then
        owner:MarkLayoutDataRefresh180("guildchat")
    end
    if owner.ui.chatListHeader then Size(owner.ui.chatListHeader, chatWidth - 32, 20) end
    if owner.ui.chatHeaderMessage then owner.ui.chatHeaderMessage:SetWidth(math.max(172, chatWidth - 286)) end
    local available = bodyHeight - 38
    local total = 0
    local row
    for index = 1, table.getn(owner.ui.chatRows or {}) do
        row = owner.ui.chatRows[index]
        Size(row, chatWidth - 44, row:GetHeight())
        if row:IsVisible() then total = total + row:GetHeight() + 2 end
        if row.messageFrame then row.messageFrame:SetWidth(math.max(172, chatWidth - 290)) end
    end
    owner:LayoutChatRows180()
    Move(owner.ui.chatSlider, owner.ui.chatList, chatWidth - 25, -28,
        owner.ui.chatSlider:GetWidth(), math.max(100, available))
    if owner.ui.officerOnlinePanel then
        if showOfficer then
            local officerCount = table.getn(owner:GetOfficerChatOnlineMembers() or {})
            local officerHeight = math.min(bodyHeight, math.max(78, 58 + (math.min(12, officerCount) * 27)))
            Move(owner.ui.officerOnlinePanel, page, width - officerWidth, -bodyY, officerWidth, officerHeight)
            Show(owner.ui.officerOnlinePanel)
            if owner.ui.officerOnlinePanel.title then owner.ui.officerOnlinePanel.title:SetWidth(officerWidth - 16) end
            if owner.ui.officerOnlinePanel.sub then owner.ui.officerOnlinePanel.sub:SetWidth(officerWidth - 16) end
            for index = 1, table.getn(owner.ui.officerOnlinePanel.rows or {}) do
                row = owner.ui.officerOnlinePanel.rows[index]
                Size(row, officerWidth - 14, row:GetHeight())
                if row.nameText then row.nameText:SetWidth(officerWidth - 46) end
            end
        else
            Hide(owner.ui.officerOnlinePanel)
        end
    end
    local footer = owner.ui.guildChatFooter180
    if footer then
        Move(footer, page, 0, -composerTop, width, composerHeight)
        Move(owner.ui.guildChatEdit, footer, 0, 0, width - 112, composerHeight)
        Move(owner.ui.guildChatSendButton, footer, width - 104, 0, 104, composerHeight)
    else
        Move(owner.ui.guildChatEdit, page, 0, -composerTop, width - 112, composerHeight)
        Move(owner.ui.guildChatSendButton, page, width - 104, -composerTop, 104, composerHeight)
    end
    if owner.ui.guildChatPlaceholder180 then
        owner.ui.guildChatPlaceholder180:SetWidth(math.max(100, width - 142))
        if (owner.ui.guildChatEdit:GetText() or "") == "" and not owner.guildChatEditFocused then
            owner.ui.guildChatPlaceholder180:Show()
        else
            owner.ui.guildChatPlaceholder180:Hide()
        end
    end
    page.otlChatViewportHeight180 = bodyHeight
    page.otlChatComposerGap180 = gap
    page.otlChatBottomInset180 = bottomInset
    page.otlChatComposerTop180 = composerTop
    page.otlChatBottomAligned180 = false
    page.otlChatTopAligned180 = true
    page.otlNativeLayout = true
end

-- ---------------------------------------------------------------------------
-- PvE Hub.
-- ---------------------------------------------------------------------------

local function PveProfileSetClassIcon180(texture, classToken)
    if not texture then return end
    local coordinates = SEARCH_CLASS_COORDS[string.upper(tostring(classToken or ""))]
    texture:SetVertexColor(1, 1, 1)
    if coordinates then
        texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
        texture:SetTexCoord(coordinates[1], coordinates[2], coordinates[3], coordinates[4])
    else
        texture:SetTexture("Interface\\Icons\\INV_Misc_GroupNeedMore")
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
end

function OTLGM:SetPveGroupRightTab180(tab)
    if not self.ui then return false end
    tab = tab == "PROFILE" and "PROFILE" or "DETAILS"
    self.ui.pveGroupRightTab180 = tab
    if self.ui.pveGroupDetailsTab180 then UI:SetSelected(self.ui.pveGroupDetailsTab180, tab == "DETAILS") end
    if self.ui.pveGroupProfileTab180 then UI:SetSelected(self.ui.pveGroupProfileTab180, tab == "PROFILE") end
    if self.ui.pveGroupDetails180 then if tab == "DETAILS" then self.ui.pveGroupDetails180:Show() else self.ui.pveGroupDetails180:Hide() end end
    if self.ui.pveGroupProfilePanel180 then if tab == "PROFILE" then self.ui.pveGroupProfilePanel180:Show() else self.ui.pveGroupProfilePanel180:Hide() end end
    if tab == "PROFILE" and self.RefreshPveCharacterProfile180 then self:RefreshPveCharacterProfile180() end
    return true
end

function OTLGM:RefreshPveCharacterProfile180()
    if not self.ui or not self.ui.pveGroupProfilePanel180 or not self.EnsurePveCharacterProfile180 then return false end
    local profile, key = self:EnsurePveCharacterProfile180()
    if not profile then return false end
    local panel = self.ui.pveGroupProfilePanel180
    panel.otlProfileKey180 = key
    if panel.identity then panel.identity:SetText((profile.name or "Unknown") .. "  •  Level " .. tostring(profile.level or "?") .. " " .. (profile.className or profile.class or "")) end
    PveProfileSetClassIcon180(panel.classIcon, profile.class)
    if panel.roles then
        UI:SetChecked(panel.roles.TANK, profile.roles and profile.roles.TANK == true)
        UI:SetChecked(panel.roles.HEAL, profile.roles and profile.roles.HEAL == true)
        UI:SetChecked(panel.roles.DPS, profile.roles and profile.roles.DPS == true)
    end
    UI:SetChecked(panel.notify, profile.notify == true)
    if panel.note and not panel.note.otlFocused180 and (panel.note:GetText() or "") ~= (profile.defaultNote or "") then
        panel.note.otlSilent = true
        panel.note:SetText(profile.defaultNote or "")
        panel.note.otlSilent = nil
    end
    local enabled, reason = self:IsPveGroupMatchingEnabled180(profile)
    if reason == "no-roles" then
        panel.matchState:SetText(self.colors.orange .. "Choose at least one role to enable matching notifications." .. self.colors.reset)
    elseif reason == "global-off" then
        panel.matchState:SetText(self.colors.grey .. "Matching notifications are disabled in Settings → PvE Hub." .. self.colors.reset)
    elseif reason == "profile-off" then
        panel.matchState:SetText(self.colors.grey .. "Notifications are disabled for this character profile." .. self.colors.reset)
    elseif enabled then
        panel.matchState:SetText(self.colors.green .. "Ready for matching groups." .. self.colors.reset)
    end
    panel.saved:SetText(self.colors.green .. "Saved" .. self.colors.reset .. self.colors.grey .. "  •  local to " .. tostring(profile.name or "this character") .. self.colors.reset)
    return true
end

local function EnsurePveProfileControls180(owner, host)
    local ui = owner.ui
    if not host or ui.pveGroupProfilePanel180 then return end
    ui.pveGroupRightTab180 = ui.pveGroupRightTab180 or "DETAILS"
    ui.pveGroupDetailsTab180 = UI:Tab(host, "Group Details", 150, function() owner:SetPveGroupRightTab180("DETAILS") end)
    ui.pveGroupProfileTab180 = UI:Tab(host, "My Profile", 130, function() owner:SetPveGroupRightTab180("PROFILE") end)
    local panel = UI:Card(host, 360, 360, "My Profile")
    panel:Hide()
    panel.classIcon = panel:CreateTexture(nil, "ARTWORK")
    panel.classIcon:SetWidth(42) panel.classIcon:SetHeight(42)
    panel.identity = UI.Text(panel, "", "GameFontNormal", "LEFT")
    panel.identity:SetHeight(42)
    panel.identity:SetJustifyV("MIDDLE")
    panel.roleTitle = UI.Text(panel, "ROLES FOR GROUP MATCHING", "GameFontNormalSmall", "LEFT")
    panel.roleTitle:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    panel.roles = {}
    panel.roles.TANK = UI:Check(panel, "Tank", 108, function(value) owner:SetPveCharacterProfileRole180("TANK", value) owner:RefreshPveCharacterProfile180() end)
    panel.roles.HEAL = UI:Check(panel, "Healer", 108, function(value) owner:SetPveCharacterProfileRole180("HEAL", value) owner:RefreshPveCharacterProfile180() end)
    panel.roles.DPS = UI:Check(panel, "Damage", 108, function(value) owner:SetPveCharacterProfileRole180("DPS", value) owner:RefreshPveCharacterProfile180() end)
    panel.notify = UI:Check(panel, "Notify me about matching groups", 320, function(value) owner:SetPveCharacterProfileNotify180(value) owner:RefreshPveCharacterProfile180() end)
    panel.matchState = UI.Text(panel, "", "GameFontNormalSmall", "LEFT")
    panel.matchState:SetHeight(38) panel.matchState:SetJustifyV("TOP")
    panel.noteTitle = UI.Text(panel, "DEFAULT APPLICATION NOTE", "GameFontNormalSmall", "LEFT")
    panel.noteTitle:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    panel.note = UI:EditBox(panel, 320, 30, {
        placeholder = "Optional note for Join Request...",
        maxLetters = 44,
        changed = function(value) owner:SetPveCharacterProfileNote180(value) owner:RefreshPveCharacterProfile180() end,
    })
    panel.noteHelp = UI.Text(panel, "Inserted into Join Request for this character and still editable before sending.", "GameFontNormalSmall", "LEFT")
    panel.noteHelp:SetHeight(36) panel.noteHelp:SetJustifyV("TOP") panel.noteHelp:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    panel.privacy = UI.Text(panel, "This profile is stored per realm:character and is never published over the addon channel.", "GameFontNormalSmall", "LEFT")
    panel.privacy:SetHeight(42) panel.privacy:SetJustifyV("TOP") panel.privacy:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    panel.saved = UI.Text(panel, "", "GameFontNormalSmall", "LEFT")
    ui.pveGroupProfilePanel180 = panel
    owner:SetPveGroupRightTab180(ui.pveGroupRightTab180)
end


local RAID_TEAM_CLASS_ORDER180 = { "ALL", "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
local RAID_TEAM_ROLE_ORDER180 = { "FLEXIBLE", "TANK", "HEALER", "DAMAGE" }

local function RaidTeamSelectionList180(selection)
    local result, key = {}, nil
    for key in pairs(selection or {}) do if selection[key] then table.insert(result, key) end end
    return result
end

local function RaidTeamSortedMembers180(team)
    local rows, _, member = {}, nil, nil
    for _, member in pairs(team and team.members or {}) do table.insert(rows, member) end
    table.sort(rows, function(left, right)
        local order = { CORE = 1, RESERVE = 2, GUEST = 3 }
        local lo, ro = order[left.tier] or 4, order[right.tier] or 4
        if lo ~= ro then return lo < ro end
        return string.lower(left.character or "") < string.lower(right.character or "")
    end)
    return rows
end

function OTLGM.__impl180.OpenRaidTeamNative180__impl1(self, teamId, options)
    if not self.ui then return false, "ui-not-ready" end
    if OTLGM_DB and OTLGM_DB.settings then OTLGM_DB.settings.pveSection = "RAIDS" end
    self.ui.raidTeamSelectedId180 = teamId
    self:ShowPage("pve")
    if self.ShowPveSection then self:ShowPveSection("RAIDS") end
    self:SetPveRaidAreaMode180("TEAMS")
    if self.RefreshRaidTeamsPanel180 then self:RefreshRaidTeamsPanel180() end
    local team = self:GetRaidTeam180(teamId)
    if team then return true end
    return false, "raid-team-not-found"
end

function OTLGM:SetPveRaidAreaMode180(mode)
    if not self.ui then return false end
    mode = mode == "TEAMS" and "TEAMS" or "EVENTS"
    self.ui.pveRaidAreaMode180 = mode
    if self.ui.pveRaidEventsTab180 then UI:SetSelected(self.ui.pveRaidEventsTab180, mode == "EVENTS") end
    if self.ui.pveRaidTeamsTab180 then UI:SetSelected(self.ui.pveRaidTeamsTab180, mode == "TEAMS") end
    if mode == "TEAMS" and self.RefreshRaidTeamsPanel180 then self:RefreshRaidTeamsPanel180() end
    if self.LayoutShellPage180 then self:LayoutShellPage180("pve", "raid-area-mode") end
    return true
end

function OTLGM:OpenRaidTeamEditor180(team)
    local ui = self.ui
    if not ui or not ui.raidTeamEditor180 then return false end
    if ui.raidEditorNative180 and ui.raidEditorNative180:IsVisible() then
        if self.SetStatus then self:SetStatus("Close or save the active Raid Event draft before opening the Raid Team editor.") end
        return false, "raid-event-editor-active"
    end
    if team and not self:CanManageRaidTeams180(team) then return false end
    ui.raidTeamEditor180.teamId180 = team and team.id or nil
    ui.raidTeamEditorTitle180:SetText(team and "EDIT RAID TEAM" or "CREATE RAID TEAM")
    ui.raidTeamNameEdit180:SetText(team and team.name or "")
    ui.raidTeamLeaderEdit180:SetText(team and team.raidLeader or (UnitName("player") or ""))
    ui.raidTeamContactEdit180:SetText(team and team.inviteContact or (UnitName("player") or ""))
    ui.raidTeamHelpersEdit180:SetText(team and team.inviteHelpers or "")
    ui.raidTeamDescriptionEdit180:SetText(team and team.description or "")
    if ui.raidTeamPrimaryCheck180 then
        ui.raidTeamPrimaryCheck180:SetChecked(team and team.primary180 and true or false)
        if self.IsOfficerMode and self:IsOfficerMode() then ui.raidTeamPrimaryCheck180:Show() else ui.raidTeamPrimaryCheck180:Hide() end
    end
    UI:SetText(ui.raidTeamEditorSave180, team and "Save Team" or "Create Team")
    if self.ShowModal152 then self:ShowModal152(ui.raidTeamEditor180) else ui.raidTeamEditor180:Show() end
    return true
end

function OTLGM:SaveRaidTeamEditor180()
    local ui = self.ui
    if not ui or not ui.raidTeamEditor180 then return false end
    local data = {
        name = ui.raidTeamNameEdit180:GetText(), raidLeader = ui.raidTeamLeaderEdit180:GetText(),
        inviteContact = ui.raidTeamContactEdit180:GetText(), inviteHelpers = ui.raidTeamHelpersEdit180:GetText(),
        description = ui.raidTeamDescriptionEdit180:GetText(),
        primary180 = ui.raidTeamPrimaryCheck180 and ui.raidTeamPrimaryCheck180:GetChecked() and true or false,
    }
    local id = ui.raidTeamEditor180.teamId180
    local ok, result
    if id then ok, result = self:UpdateRaidTeam180(id, data) else ok, result = self:CreateRaidTeam180(data) end
    if not ok then if self.ShowNotice then self:ShowNotice("Raid Team", result or "The Raid Team could not be saved.") end return false end
    ui.raidTeamSelectedId180 = result.id
    if self.CloseModal180 then self:CloseModal180(ui.raidTeamEditor180, "save-success") else ui.raidTeamEditor180:Hide() end
    self:SetPveRaidAreaMode180("TEAMS")
    self:RefreshRaidTeamsPanel180()
    return true
end

local function EnsureRaidTeamsControls180(owner, root)
    local ui = owner.ui
    if not root or ui.raidTeamsPanel180 then return end
    ui.pveRaidAreaMode180 = ui.pveRaidAreaMode180 or "EVENTS"
    ui.pveRaidEventsTab180 = UI:Tab(root, "Events", 108, function() owner:SetPveRaidAreaMode180("EVENTS") end)
    ui.pveRaidTeamsTab180 = UI:Tab(root, "Raid Teams", 120, function() owner:SetPveRaidAreaMode180("TEAMS") end)

    local panel = UI:Surface(root, "surface", 700, 400)
    ui.raidTeamsPanel180 = panel
    ui.raidTeamSearchBox180 = UI:SearchBox(panel, 220, 28, "Search Raid Teams...", function(value)
        ui.raidTeamSearch180 = value or "" ui.raidTeamOffset180 = 0 owner:RefreshRaidTeamsPanel180()
    end)
    ui.raidTeamCreate180 = UI:Button(panel, "+ Create Team", 118, 28, function() owner:OpenRaidTeamEditor180(nil) end, "primary")
    ui.raidTeamEdit180 = UI:Button(panel, "Edit", 72, 28, function() owner:OpenRaidTeamEditor180(owner:GetRaidTeam180(ui.raidTeamSelectedId180)) end)
    ui.raidTeamArchive180 = UI:Button(panel, "Archive", 78, 28, function()
        local team = owner:GetRaidTeam180(ui.raidTeamSelectedId180) if not team then return end
        owner:ShowConfirm(team.status == "ARCHIVED" and "Restore Raid Team" or "Archive Raid Team",
            team.status == "ARCHIVED" and "Restore this Raid Team for future events?" or "Archive this Raid Team? Existing event rosters will remain unchanged.",
            team.status == "ARCHIVED" and "Restore" or "Archive", function() owner:ArchiveRaidTeam180(team.id, team.status ~= "ARCHIVED") owner:RefreshRaidTeamsPanel180() end)
    end, "utility")
    ui.raidTeamDelete180 = UI:Button(panel, "Delete", 72, 28, function()
        local team = owner:GetRaidTeam180(ui.raidTeamSelectedId180) if not team then return end
        owner:ShowConfirm("Delete Raid Team", "Delete " .. (team.name or "this Raid Team") .. "? Existing event rosters will not be deleted.", "Delete", function() owner:DeleteRaidTeam180(team.id) ui.raidTeamSelectedId180=nil owner:RefreshRaidTeamsPanel180() end)
    end, "danger")

    ui.raidTeamListPanel180 = UI:Card(panel, 300, 330, "Raid Teams")
    ui.raidTeamRows180 = {}
    local index
    for index = 1, 10 do
        local row = UI:TableRow(ui.raidTeamListPanel180, 270, 46, function(button)
            if button.team180 then ui.raidTeamSelectedId180 = button.team180.id ui.raidTeamMemberSelection180 = {} owner:RefreshRaidTeamsPanel180() end
        end)
        row.nameText = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.metaText = UI.Text(row, "", "GameFontNormalSmall", "LEFT") row.metaText:SetTextColor(C.grey[1],C.grey[2],C.grey[3])
        SetWheel(row, function(delta) local max=math.max(0,table.getn(owner:GetRaidTeamList180(true))-(ui.raidTeamVisibleRows180 or 8)); ui.raidTeamOffset180=math.max(0,math.min(max,(ui.raidTeamOffset180 or 0)-delta)); owner:RefreshRaidTeamsPanel180() end)
        ui.raidTeamRows180[index] = row
    end
    ui.raidTeamScrollbar180 = UI:Scrollbar(ui.raidTeamListPanel180, 280, function(value) ui.raidTeamOffset180=math.floor(value or 0) owner:RefreshRaidTeamsPanel180() end)

    ui.raidTeamDetailsPanel180 = UI:Card(panel, 390, 330, "Team Details")
    -- The generic card title and the live team title occupied the same pixels.
    -- Keep one header owner only; the live title below is the canonical header.
    if ui.raidTeamDetailsPanel180.title then ui.raidTeamDetailsPanel180.title:Hide() end
    ui.raidTeamDetailTitle180 = UI.Text(ui.raidTeamDetailsPanel180, "Select a Raid Team", "GameFontNormalLarge", "LEFT")
    ui.raidTeamDetailMeta180 = UI.Text(ui.raidTeamDetailsPanel180, "", "GameFontNormalSmall", "LEFT") ui.raidTeamDetailMeta180:SetJustifyV("TOP")
    ui.raidTeamDetailDescription180 = UI.Text(ui.raidTeamDetailsPanel180, "", "GameFontHighlightSmall", "LEFT") ui.raidTeamDetailDescription180:SetJustifyV("TOP")
    ui.raidTeamAddMembers180 = UI:Button(ui.raidTeamDetailsPanel180, "+ Add from Roster", 126, 26, function() owner:OpenRaidTeamMemberPicker180(ui.raidTeamSelectedId180) end, "primary")
    ui.raidTeamMemberRows180 = {}
    for index = 1, 12 do
        local row = UI:TableRow(ui.raidTeamDetailsPanel180, 350, 30, function(button)
            if not button.memberKey180 then return end
            ui.raidTeamMemberSelection180 = ui.raidTeamMemberSelection180 or {}
            ui.raidTeamMemberSelection180[button.memberKey180] = not ui.raidTeamMemberSelection180[button.memberKey180]
            owner:RefreshRaidTeamsPanel180()
        end)
        row.nameText = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.metaText = UI.Text(row, "", "GameFontNormalSmall", "RIGHT") row.metaText:SetTextColor(C.grey[1],C.grey[2],C.grey[3])
        ui.raidTeamMemberRows180[index] = row
    end
    ui.raidTeamMemberScrollbar180 = UI:Scrollbar(ui.raidTeamDetailsPanel180, 220, function(value) ui.raidTeamMemberOffset180=math.floor(value or 0) owner:RefreshRaidTeamsPanel180() end)
    ui.raidTeamMemberActionButtons180 = {
        remove = UI:Button(ui.raidTeamDetailsPanel180, "Remove", 66, 24, function() owner:ApplyRaidTeamMemberAction180("REMOVE") end, "danger"),
        core = UI:Button(ui.raidTeamDetailsPanel180, "Core", 54, 24, function() owner:ApplyRaidTeamMemberAction180("TIER","CORE") end),
        reserve = UI:Button(ui.raidTeamDetailsPanel180, "Reserve", 64, 24, function() owner:ApplyRaidTeamMemberAction180("TIER","RESERVE") end),
        guest = UI:Button(ui.raidTeamDetailsPanel180, "Guest", 56, 24, function() owner:ApplyRaidTeamMemberAction180("TIER","GUEST") end),
        role = UI:Button(ui.raidTeamDetailsPanel180, "Role: Flexible", 104, 24, function(button)
            local current=button.role180 or "FLEXIBLE" local nextRole="TANK"
            for i=1,table.getn(RAID_TEAM_ROLE_ORDER180) do if RAID_TEAM_ROLE_ORDER180[i]==current then nextRole=RAID_TEAM_ROLE_ORDER180[math.mod(i, table.getn(RAID_TEAM_ROLE_ORDER180)) + 1] break end end
            button.role180=nextRole UI:SetText(button,"Role: "..nextRole) owner:ApplyRaidTeamMemberAction180("ROLE",nextRole)
        end, "utility"),
    }

    -- Team editor.
    local editor = UI:Modal(ui.main, 560, 430)
    editor:SetPoint("CENTER", ui.main, "CENTER", 0, 0)
    ui.raidTeamEditor180 = editor
    if owner.RegisterModal152 then owner:RegisterModal152(editor) end
    ui.raidTeamEditorTitle180 = UI.Text(editor, "CREATE RAID TEAM", "GameFontNormalLarge", "CENTER")
    ui.raidTeamNameEdit180 = UI:EditBox(editor, 250, 30, {placeholder="Team name",maxLetters=36})
    ui.raidTeamLeaderEdit180 = UI:EditBox(editor, 250, 30, {placeholder="Raid Leader character",maxLetters=40})
    ui.raidTeamContactEdit180 = UI:EditBox(editor, 250, 30, {placeholder="Invite contact",maxLetters=40})
    ui.raidTeamHelpersEdit180 = UI:EditBox(editor, 250, 30, {placeholder="Invite helpers, comma separated",maxLetters=96})
    ui.raidTeamDescriptionEdit180 = UI:EditBox(editor, 518, 82, {placeholder="Short team description",maxLetters=96,multiline=true})
    ui.raidTeamPrimaryCheck180 = UI:Check(editor, "Primary Raid Team", 180, function() end)
    ui.raidTeamEditorSave180 = UI:Button(editor, "Create Team", 118, 32, function() owner:SaveRaidTeamEditor180() end, "primary")
    ui.raidTeamEditorCancel180 = UI:Button(editor, "Cancel", 96, 32, function() owner:CloseModal180(editor, "cancel") end)

    -- Guild roster picker with search, class filter, selected filter and multi-select.
    local picker = UI:Modal(ui.main, 620, 540)
    picker:SetPoint("CENTER", ui.main, "CENTER", 0, 0)
    ui.raidTeamPicker180 = picker
    if owner.RegisterModal152 then owner:RegisterModal152(picker) end
    local pickerTitle = UI.Text(picker, "ADD GUILD MEMBERS", "GameFontNormalLarge", "CENTER")
    ui.raidTeamPickerSearchBox180 = UI:SearchBox(picker, 250, 30, "Search guild roster...", function(value) ui.raidTeamPickerSearch180=value or "" ui.raidTeamPickerOffset180=0 owner:RefreshRaidTeamPicker180() end)
    ui.raidTeamPickerClassButton180 = UI:Button(picker, "Class: ALL", 126, 30, function()
        local current=ui.raidTeamPickerClass180 or "ALL" local nextClass="ALL"
        for i=1,table.getn(RAID_TEAM_CLASS_ORDER180) do if RAID_TEAM_CLASS_ORDER180[i]==current then nextClass=RAID_TEAM_CLASS_ORDER180[math.mod(i, table.getn(RAID_TEAM_CLASS_ORDER180)) + 1] break end end
        ui.raidTeamPickerClass180=nextClass ui.raidTeamPickerOffset180=0 owner:RefreshRaidTeamPicker180()
    end, "utility")
    ui.raidTeamPickerSelectedButton180 = UI:Button(picker, "Selected only", 108, 30, function() ui.raidTeamPickerSelectedOnly180=not ui.raidTeamPickerSelectedOnly180 ui.raidTeamPickerOffset180=0 owner:RefreshRaidTeamPicker180() end, "filter")
    ui.raidTeamPickerRows180 = {}
    for index = 1, 12 do
        local row = UI:TableRow(picker, 560, 32, function(button)
            if not button.memberKey180 then return end
            ui.raidTeamPickerSelection180[button.memberKey180]=not ui.raidTeamPickerSelection180[button.memberKey180]
            owner:RefreshRaidTeamPicker180()
        end)
        row.nameText = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.metaText = UI.Text(row, "", "GameFontNormalSmall", "RIGHT") row.metaText:SetTextColor(C.grey[1],C.grey[2],C.grey[3])
        ui.raidTeamPickerRows180[index]=row
    end
    ui.raidTeamPickerScrollbar180 = UI:Scrollbar(picker, 380, function(value) ui.raidTeamPickerOffset180=math.floor(value or 0) owner:RefreshRaidTeamPicker180() end)
    ui.raidTeamPickerAdd180 = UI:Button(picker, "Add Selected (0)", 150, 32, function()
        local names=RaidTeamSelectionList180(ui.raidTeamPickerSelection180)
        if picker.targetType180 == "EVENT_CUSTOM" then
            local roster = {}
            local candidates = owner:GetRaidTeamRosterCandidates180("", "ALL", false, ui.raidTeamPickerSelection180)
            local index, member, key
            for index=1,table.getn(candidates) do
                member=candidates[index]; key=string.lower(string.gsub(member.name or "", "%-.*$", ""))
                if ui.raidTeamPickerSelection180[key] then roster[key]={character=member.name,class=member.classFile or member.class or "",mainRole="UNASSIGNED",roleNeedsReview180=true,slotStatus="ASSIGNED"} end
            end
            ui.raidCustomRoster180 = roster
            owner:CloseModal180(picker, "custom-roster-selected"); owner:RefreshRaidRosterEditor180(); return
        end
        local teamId=picker.teamId180
        local ok,message=owner:MutateRaidTeamMembers180(teamId,names,"ADD")
        if not ok then if owner.ShowNotice then owner:ShowNotice("Raid Team",message or "No members were added.") end return end
        owner:CloseModal180(picker, "members-added") ui.raidTeamSelectedId180=teamId owner:RefreshRaidTeamsPanel180()
    end, "primary")
    ui.raidTeamPickerCancel180 = UI:Button(picker, "Cancel", 96, 32, function() owner:CloseModal180(picker, "cancel") end)

    -- Event roster source controls are integrated into the existing editor.
    local raidEditor = ui.raidEditor156
    if raidEditor then
        raidEditor:SetHeight(610)
        ui.raidRosterLabel180 = UI.Text(raidEditor, "EVENT ROSTER", "GameFontNormalSmall", "LEFT")
        ui.raidRosterModeCustom180 = UI:Button(raidEditor, "Custom / Keep", 122, 28, function() ui.raidRosterMode180="CUSTOM" ui.raidRosterSourceId180=nil owner:RefreshRaidRosterEditor180() end, "filter")
        ui.raidRosterModeTeam180 = UI:Button(raidEditor, "Use Raid Team", 122, 28, function() owner:OpenRaidRosterSourceSelector180("TEAM") end, "filter")
        ui.raidRosterModeClone180 = UI:Button(raidEditor, "Clone Previous", 122, 28, function() owner:OpenRaidRosterSourceSelector180("CLONE_PREVIOUS") end, "filter")
        ui.raidRosterSourceButton180 = UI:Button(raidEditor, "Custom roster", 382, 28, function() owner:CycleRaidRosterSource180() end, "utility")
        ui.raidRosterCustomEdit180 = UI:Button(raidEditor, "Edit Custom", 122, 28, function() owner:OpenCustomRaidRosterPicker180() end, "utility")
        ui.raidRosterPreview180 = UI.Text(raidEditor, "Event roster preview", "GameFontNormalSmall", "LEFT")
        ui.raidRosterHelp180 = UI.Text(raidEditor, "The roster is copied into this event. Future team edits never rewrite the published event automatically.", "GameFontNormalSmall", "LEFT") ui.raidRosterHelp180:SetTextColor(C.grey[1],C.grey[2],C.grey[3])
    end

    -- Event details snapshot summary and explicit refresh action.
    if ui.raidDetailsPanel180 then
        ui.raidRosterSummary180 = UI.Text(ui.raidDetailsPanel180, "", "GameFontNormalSmall", "LEFT")
        ui.raidRefreshRoster180 = UI:Button(ui.raidDetailsPanel180, "Refresh from Team", 132, 26, function()
            local event=owner:GetRaidEvent180(ui.raidSelected156) if not event or not event.teamId180 then return end
            local team=owner:GetRaidTeam180(event.teamId180) if not team then return end
            local total,assigned,reserve,guest=owner:GetRaidRosterSummary180((owner:BuildRaidRosterSnapshotFromTeam180(team.id)))
            owner:ShowConfirm("Refresh Event Roster", "Replace this event roster with the current "..(team.name or "Raid Team").." roster ("..tostring(total).." members)? This does not modify the team or other events.", "Refresh", function() owner:RefreshRaidEventRosterFromTeam180(event.id) owner:RefreshRaidPlanner156() end)
        end, "utility")
    end

    -- Static modal geometry.
    Move(ui.raidTeamEditorTitle180, editor, 20, -18, 520, 24)
    local labels = {
        {"TEAM NAME",20,-58},{"RAID LEADER",290,-58},{"INVITE CONTACT",20,-116},{"INVITE HELPERS",290,-116},{"DESCRIPTION",20,-176},
    }
    for index=1,table.getn(labels) do local l=UI.Text(editor,labels[index][1],"GameFontNormalSmall","LEFT"); Move(l,editor,labels[index][2],labels[index][3],240,18) end
    Move(ui.raidTeamNameEdit180,editor,20,-76,250,30); Move(ui.raidTeamLeaderEdit180,editor,290,-76,250,30)
    Move(ui.raidTeamContactEdit180,editor,20,-134,250,30); Move(ui.raidTeamHelpersEdit180,editor,290,-134,250,30)
    Move(ui.raidTeamDescriptionEdit180,editor,20,-194,520,82)
    Move(ui.raidTeamPrimaryCheck180,editor,20,-286,180,24)
    Move(ui.raidTeamEditorSave180,editor,318,-374,118,32); Move(ui.raidTeamEditorCancel180,editor,444,-374,96,32)
    Move(pickerTitle,picker,20,-18,580,24); Move(ui.raidTeamPickerSearchBox180,picker,20,-56,250,30); Move(ui.raidTeamPickerClassButton180,picker,280,-56,126,30); Move(ui.raidTeamPickerSelectedButton180,picker,416,-56,108,30)
    for index=1,table.getn(ui.raidTeamPickerRows180) do local row=ui.raidTeamPickerRows180[index]; Move(row,picker,20,-96-((index-1)*32),560,30); Move(row.nameText,row,8,-7,230,18); Move(row.metaText,row,244,-7,306,18) end
    Move(ui.raidTeamPickerScrollbar180,picker,584,-96,14,382); Move(ui.raidTeamPickerAdd180,picker,348,-496,150,32); Move(ui.raidTeamPickerCancel180,picker,506,-496,96,32)
    if raidEditor then
        Move(ui.raidRosterLabel180,raidEditor,22,-338,220,18); Move(ui.raidRosterModeCustom180,raidEditor,22,-360,122,28); Move(ui.raidRosterModeTeam180,raidEditor,152,-360,122,28); Move(ui.raidRosterModeClone180,raidEditor,282,-360,122,28)
        Move(ui.raidRosterSourceButton180,raidEditor,22,-396,382,28); Move(ui.raidRosterCustomEdit180,raidEditor,414,-396,122,28); Move(ui.raidRosterPreview180,raidEditor,22,-432,636,18); Move(ui.raidRosterHelp180,raidEditor,22,-458,636,40)
        Move(ui.raidSave156,raidEditor,390,-558,128,34); Move(ui.raidEditorCancel156,raidEditor,530,-558,128,34)
    end

    owner:SetPveRaidAreaMode180(ui.pveRaidAreaMode180)
end

local function LayoutRaidTeams180(owner, panel, width, height)
    -- C5-R5: the legacy page layout owns only the outer content rectangle.
    -- All internal Raid Teams controls are positioned by the single final
    -- C5R4LayoutRaidTeams180 owner inside RefreshRaidTeamsPanel180.
    local ui = owner.ui
    Move(ui.raidTeamsPanel180, panel, 0, -38, width, height - 38)
    ui.raidTeamLayoutSignature180 = nil
    owner:RefreshRaidTeamsPanel180()
end


local function ClearPveGroupComposerFocus180(owner)
    local ui = owner and owner.ui
    if not ui then return end
    local fields = {
        ui.pveRequestActivityEdit, ui.pveRequestNoteEdit, ui.pveGroupSizeEdit,
        ui.pveNeedTankEdit, ui.pveNeedHealEdit, ui.pveNeedDpsEdit,
        ui.pveMinLevelEdit, ui.pveMaxLevelEdit,
    }
    local index
    for index = 1, table.getn(fields) do if fields[index] and fields[index].ClearFocus then fields[index]:ClearFocus() end end
end

function OTLGM:OpenGroupFinderComposer180(record)
    if not self.ui or not self.ui.main then self:BuildUI() end
    if not self.ui or not self.ui.pveGroupForm180 then
        if not self:ShowPage("pve") then return false end
    end
    if self.ShowPveSection then self:ShowPveSection("GROUPS") end
    local form = self.ui and self.ui.pveGroupForm180
    if not form then return false end
    record = record or (self.GetOwnPveGroup180 and self:GetOwnPveGroup180()) or nil
    if self.PopulatePveGroupEditor180 then self:PopulatePveGroupEditor180(record) end
    form.otlEditingGroupId180 = record and record.id or nil
    form.otlComposerMode180 = record and "EDIT" or "CREATE"
    if self.RegisterModal152 then self:RegisterModal152(form) end
    if self.ui.modalHost and form.GetParent and form:GetParent() ~= self.ui.modalHost then
        form:SetParent(self.ui.modalHost)
    end
    form:ClearAllPoints()
    form:SetPoint("CENTER", self.ui.modalHost or self.ui.main, "CENTER", 0, 0)
    form:SetWidth(304)
    form:SetHeight(438)
    if self.ShowShellModal then self:ShowShellModal(form, false) else form:Show() end
    return true
end

function OTLGM:CloseGroupFinderComposer180(clearComposer, reason)
    local form = self.ui and self.ui.pveGroupForm180
    if not form then return false end
    ClearPveGroupComposerFocus180(self)
    if clearComposer then
        self.ui.pveGroupEditingId180 = nil
        form.otlEditingGroupId180 = nil
        if self.ui.pveRequestActivityEdit then self.ui.pveRequestActivityEdit:SetText("") end
        if self.ui.pveRequestNoteEdit then self.ui.pveRequestNoteEdit:SetText("") end
    end
    if self.CloseModal180 then self:CloseModal180(form, reason or "group-composer-close") else form:Hide() end
    return true
end

function OTLGM:SaveGroupFinderComposer180()
    local ui = self.ui
    if not ui or not ui.pveGroupForm180 then return false end
    OTLGM_DB.settings.pveGroupSize = ui.pveGroupSizeEdit:GetText()
    OTLGM_DB.settings.pveNeedTank = ui.pveNeedTankEdit:GetText()
    OTLGM_DB.settings.pveNeedHeal = ui.pveNeedHealEdit:GetText()
    OTLGM_DB.settings.pveNeedDps = ui.pveNeedDpsEdit:GetText()
    OTLGM_DB.settings.pveMinLevel180 = ui.pveMinLevelEdit and ui.pveMinLevelEdit:GetText() or ""
    OTLGM_DB.settings.pveMaxLevel180 = ui.pveMaxLevelEdit and ui.pveMaxLevelEdit:GetText() or ""
    local ok, result = self:CreatePveRequest(
        OTLGM_DB.settings.pveRequestKind,
        OTLGM_DB.settings.pveRequestRole,
        ui.pveRequestActivityEdit:GetText(),
        ui.pveRequestNoteEdit:GetText(),
        ui.pveGroupSizeEdit:GetText(),
        ui.pveNeedTankEdit:GetText(),
        ui.pveNeedHealEdit:GetText(),
        ui.pveNeedDpsEdit:GetText(),
        ui.pveMinLevelEdit and ui.pveMinLevelEdit:GetText() or "",
        ui.pveMaxLevelEdit and ui.pveMaxLevelEdit:GetText() or "")
    if not ok then
        self:ShowNotice("Group Finder", result or "Could not save the group.")
        return false
    end
    ui.pveSelectedRequest = result and result.id or ui.pveSelectedRequest
    ui.pveSelectedApplication = nil
    ui.pveGroupEditingId180 = nil
    self:SetStatus(result and result.rev and result.rev > 1 and "Group updated and shared with online addon users." or "Group shared with online addon users.")
    self:CloseGroupFinderComposer180(true, "group-save")
    if self.SetPveGroupRightTab180 then self:SetPveGroupRightTab180("DETAILS") end
    self:RefreshPvePage()
    self:RefreshPveGroupsPanel()
    return true, result
end

local EnsureRaidC6Controls180

local function EnsurePveNativeControls(owner)
    local ui = owner and owner.ui
    if not ui then return false end

    -- BuildPvePage may request refreshes before every child frame exists. R6
    -- used a one-shot flag at that moment, permanently skipping both PvE
    -- scrollbars. Every control is now created independently and this function
    -- remains safe to call during Create, Bind, Refresh and Resize.
    if ui.pveGroupsPanel180 and not ui.pveGroupCreateToggle180 then
        ui.pveGroupCreateToggle180 = UI:Button(ui.pveGroupsPanel180, "+ Create Group", 132, 28, function()
            OTLGM:OpenGroupFinderComposer180(OTLGM.GetOwnPveGroup180 and OTLGM:GetOwnPveGroup180() or nil)
        end, "primary")
    end
    if ui.pveGroupForm180 then
        local form = ui.pveGroupForm180
        if owner.RegisterModal152 then owner:RegisterModal152(form) end
        if ui.pveRequestCreateButton then
            ui.pveRequestCreateButton:SetScript("OnClick", function() OTLGM:SaveGroupFinderComposer180() end)
            ui.pveRequestCreateButton:ClearAllPoints()
            ui.pveRequestCreateButton:SetPoint("BOTTOMRIGHT", form, "BOTTOMRIGHT", -12, 12)
            ui.pveRequestCreateButton:SetWidth(132)
        end
        if not ui.pveGroupCancel180 then
            ui.pveGroupCancel180 = UI:Button(form, "Cancel", 96, 28, function() OTLGM:CloseGroupFinderComposer180(false, "cancel") end, "secondary")
            ui.pveGroupCancel180:SetPoint("BOTTOMLEFT", form, "BOTTOMLEFT", 12, 12)
        end
        if not ui.pveGroupClose180 then
            ui.pveGroupClose180 = UI:Button(form, "X", 26, 24, function() OTLGM:CloseGroupFinderComposer180(false, "x") end, "danger")
            ui.pveGroupClose180:SetPoint("TOPRIGHT", form, "TOPRIGHT", -8, -8)
        end
    end
    if ui.pveRaidsPanel180 and not ui.pveRaidEmpty180 then
        ui.pveRaidEmpty180 = UI:EmptyState(ui.pveRaidsPanel180, 520, 150, "No raids in this view",
            "Create a raid event, or use Check Updates to look for recently shared raids.")
        ui.pveRaidEmpty180:Hide()
    end
    if ui.raidPlanner156 then EnsureRaidTeamsControls180(owner, ui.raidPlanner156) end
    if owner.EnsureRaidTeamPack2Controls180 and ui.raidTeamsPanel180 then owner:EnsureRaidTeamPack2Controls180() end
    if ui.pveGroupsPanel180 and not ui.pveGroupEmpty180 then
        ui.pveGroupEmpty180 = UI:EmptyState(ui.pveGroupsPanel180, 520, 150, "No open groups",
            "Create a group when you are ready to lead, or use Check Updates to look for open guild groups.")
        ui.pveGroupEmpty180:Hide()
    end
    if ui.pveGroupsPanel180 then
        EnsurePveProfileControls180(owner, ui.pveGroupsPanel180)
        if ui.pveGroupDetails180 and ui.pveGroupDetails180:GetParent() ~= ui.pveGroupsPanel180 then ui.pveGroupDetails180:SetParent(ui.pveGroupsPanel180) end
        if ui.pveGroupDetails180 and not ui.pveGroupShare180 then
            ui.pveGroupShare180 = UI:Button(ui.pveGroupDetails180, "Share Group", 104, 24, function()
                local record = owner.GetPveRequestByID and owner:GetPveRequestByID(owner.ui.pveSelectedRequest) or nil
                if not record then return end
                local ok, reason = owner:SharePveGroupToGuildChat(record)
                if ok and owner.ShowToast then owner:ShowToast("Group shared to guild chat.", "success")
                elseif reason ~= "cooldown" and owner.SetStatus then owner:SetStatus("The group could not be shared.") end
            end, "utility")
        end
    end
    if ui.pveBoardPanel180 and not ui.pveBoardEmpty180 then
        ui.pveBoardEmpty180 = UI:EmptyState(ui.pveBoardPanel180, 520, 128, "No Guild Board posts",
            "Write the first short community post above.")
        ui.pveBoardEmpty180:Hide()
    end

    local raidHostChanged = ui.pveRaidScrollbar180 and ui.pveRaidScrollbar180.GetParent
        and ui.pveRaidScrollbar180:GetParent() ~= ui.raidListPanel180
    if raidHostChanged then
        ui.pveRaidScrollbar180:Hide()
        ui.pveRaidScrollbar180 = nil
    end
    if ui.raidListPanel180 and not ui.pveRaidScrollbar180 then
        ui.pveRaidScrollbar180 = UI:Scrollbar(ui.raidListPanel180, 260, function(value)
            local nextOffset = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
            if nextOffset == (tonumber(ui.raidOffset156) or 0) then return end
            ui.raidOffset156 = nextOffset
            if owner.CanRefreshShellPage180 and not owner:CanRefreshShellPage180("pve") then
                ui.pveNativeRefreshPending180 = true
                return
            end
            owner:RefreshRaidPlanner156()
        end)
        ui.pveRaidScrollbar180.otlPveOwner180 = "RAIDS"
        SetWheel(ui.raidListPanel180, function(delta)
            local raids = owner:GetRaidList156(ui.raidFilter156 or "UPCOMING") or {}
            local maximum = math.max(0, table.getn(raids) - (tonumber(ui.raidVisibleRows180) or 7))
            local nextOffset = math.max(0, math.min(maximum,
                (tonumber(ui.raidOffset156) or 0) - ((tonumber(delta) or 0) * 2)))
            if nextOffset == (tonumber(ui.raidOffset156) or 0) then return end
            ui.raidOffset156 = nextOffset
            owner:RefreshRaidPlanner156()
        end)
    end

    local groupHostChanged = ui.pveGroupScrollbar180 and ui.pveGroupScrollbar180.GetParent
        and ui.pveGroupScrollbar180:GetParent() ~= ui.pveGroupList180
    if groupHostChanged then
        ui.pveGroupScrollbar180:Hide()
        ui.pveGroupScrollbar180 = nil
    end
    if ui.pveGroupList180 and not ui.pveGroupScrollbar180 then
        ui.pveGroupScrollbar180 = UI:Scrollbar(ui.pveGroupList180, 260, function(value)
            local nextOffset = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
            if nextOffset == (tonumber(ui.pveGroupOffset) or 0) then return end
            ui.pveGroupOffset = nextOffset
            if owner.CanRefreshShellPage180 and not owner:CanRefreshShellPage180("pve") then
                ui.pveNativeRefreshPending180 = true
                return
            end
            owner:RefreshPveGroupsPanel()
        end)
        ui.pveGroupScrollbar180.otlPveOwner180 = "GROUPS"
        SetWheel(ui.pveGroupList180, function(delta)
            local requests = owner:GetPveRequests() or {}
            local maximum = math.max(0, table.getn(requests) - (tonumber(ui.pveGroupVisibleRows180) or 5))
            local nextOffset = math.max(0, math.min(maximum,
                (tonumber(ui.pveGroupOffset) or 0) - ((tonumber(delta) or 0) * 2)))
            if nextOffset == (tonumber(ui.pveGroupOffset) or 0) then return end
            ui.pveGroupOffset = nextOffset
            owner:RefreshPveGroupsPanel()
        end)
    end
    if ui.raidEditor156 then ui.raidEditor156.otlNonDangerModal180 = true end
    if EnsureRaidC6Controls180 then EnsureRaidC6Controls180(owner) end

    local ready = ui.raidListPanel180 and ui.pveRaidScrollbar180 and ui.raidTeamsPanel180
        and ui.pveGroupList180 and ui.pveGroupScrollbar180 and ui.pveGroupProfilePanel180
    ui.pveNativeControlsReady180 = ready and true or false
    return ui.pveNativeControlsReady180
end

local function LayoutRaidPlanner(owner, panel, width, height)
    local ui = owner.ui
    local root = ui.raidPlanner156
    if not root then return end
    Move(root, panel, 0, 0, width, height)
    Move(ui.pveRaidEventsTab180, root, 0, 0, 108, 28)
    Move(ui.pveRaidTeamsTab180, root, 116, 0, 120, 28)
    UI:SetSelected(ui.pveRaidEventsTab180, (ui.pveRaidAreaMode180 or "EVENTS") == "EVENTS")
    UI:SetSelected(ui.pveRaidTeamsTab180, (ui.pveRaidAreaMode180 or "EVENTS") == "TEAMS")

    if (ui.pveRaidAreaMode180 or "EVENTS") == "TEAMS" then
        local _, button
        for _, button in pairs(ui.raidTabs156 or {}) do Hide(button) end
        Hide(ui.raidCreate156) Hide(ui.raidListPanel180) Hide(ui.raidDetailsPanel180) Hide(ui.pveRaidEmpty180)
        Show(ui.raidTeamsPanel180)
        LayoutRaidTeams180(owner, root, width, height)
        return
    end

    Hide(ui.raidTeamsPanel180)
    local order = { "UPCOMING", "CANCELLED", "PAST" }
    local index
    for index = 1, table.getn(order) do
        Move(ui.raidTabs156[order[index]], root, (index - 1) * 96, -34, 90, 28)
        Show(ui.raidTabs156[order[index]])
    end
    Move(ui.raidCreate156, root, width - 136, -34, 136, 28)
    Show(ui.raidCreate156)
    local raids = owner.GetRaidList156 and owner:GetRaidList156(ui.raidFilter156 or "UPCOMING") or {}
    local empty = table.getn(raids) == 0
    local bodyTop = 72
    local bodyHeight = math.max(250, height - bodyTop)
    if empty then
        Hide(ui.raidListPanel180)
        Hide(ui.raidDetailsPanel180)
        Move(ui.pveRaidEmpty180, root, math.max(12, math.floor((width - 560) / 2)),
            -math.max(bodyTop + 12, bodyTop + math.floor((bodyHeight - 150) / 2)), math.min(560, width - 24), 150)
        Show(ui.pveRaidEmpty180)
    else
        Hide(ui.pveRaidEmpty180)
        local listWidth = math.max(280, math.floor(width * 0.38))
        Move(ui.raidListPanel180, root, 0, -bodyTop, listWidth, bodyHeight)
        local raidCapacity = math.max(5, math.min(ui.raidRowPool180 or table.getn(ui.raidRows156 or {}), math.floor((bodyHeight - 72) / 42)))
        ui.raidVisibleRows180 = raidCapacity
        Move(ui.raidDetailsPanel180, root, listWidth + 8, -bodyTop, width - listWidth - 8, bodyHeight)
        Show(ui.raidListPanel180)
        Show(ui.raidDetailsPanel180)
        for index = 1, table.getn(ui.raidRows156 or {}) do
            local row = ui.raidRows156[index]
            if index <= raidCapacity then
                Move(row, ui.raidListPanel180, 8, -32 - ((index - 1) * 42), listWidth - 34, 38)
            else
                row:Hide()
            end
            if row.label156 then row.label156:SetWidth(math.max(130, listWidth - 74)) end
            if row.meta156 then row.meta156:SetWidth(math.max(130, listWidth - 74)) end
        end
        Hide(ui.raidListPrev156)
        Hide(ui.raidListNext156)
        Move(ui.raidListStatus156, ui.raidListPanel180, 10, -(bodyHeight - 26), listWidth - 40, 18)
        local raidScrollbar = ui.pveRaidScrollbar180
        if not raidScrollbar then
            ui.pveNativeRefreshPending180 = true
            return
        end
        Move(raidScrollbar, ui.raidListPanel180, listWidth - 19, -32, 14, math.max(120, (raidCapacity * 42) - 4))
        local raidMaximum = math.max(0, table.getn(raids) - raidCapacity)
        ui.raidOffset156 = math.max(0, math.min(raidMaximum, tonumber(ui.raidOffset156) or 0))
        if raidScrollbar.SetScrollMetrics180 then raidScrollbar:SetScrollMetrics180(table.getn(raids), raidCapacity, ui.raidOffset156) end

        local detailWidth = ui.raidDetailsPanel180:GetWidth()
        Move(ui.raidDetailTitle156, ui.raidDetailsPanel180, 16, -14, detailWidth - 32, 42)
        Move(ui.raidDetailTime156, ui.raidDetailsPanel180, 16, -62, detailWidth - 32, 20)
        Move(ui.raidDetailGather156, ui.raidDetailsPanel180, 16, -86, detailWidth - 32, 18)
        Move(ui.raidDetailLocation156, ui.raidDetailsPanel180, 16, -108, detailWidth - 32, 18)
        local noteHeight = math.max(38, math.min(64, bodyHeight - 286))
        Move(ui.raidDetailNote156, ui.raidDetailsPanel180, 16, -132, detailWidth - 32, noteHeight)
        local authorY = 140 + noteHeight
        Move(ui.raidDetailAuthor156, ui.raidDetailsPanel180, 16, -authorY, detailWidth - 32, 36)
        local personalY = authorY + 40
        Move(ui.raidPersonalStatus180, ui.raidDetailsPanel180, 16, -personalY, detailWidth - 32, 38)
        local actionY = personalY + 42
        Move(ui.raidSeen156, ui.raidDetailsPanel180, 16, -actionY, 82, 26)
        Move(ui.raidReady156, ui.raidDetailsPanel180, 104, -actionY, 82, 26)
        Move(ui.raidC6Contact180, ui.raidDetailsPanel180, 192, -actionY, 128, 26)
        Move(ui.raidC6Manage180, ui.raidDetailsPanel180, math.max(326, detailWidth - 126), -actionY, 110, 26)
        local actionY2 = actionY + 32
        Move(ui.raidC6Discord180, ui.raidDetailsPanel180, 16, -actionY2, 96, 26)
        Move(ui.raidC6Copy180, ui.raidDetailsPanel180, 118, -actionY2, 108, 26)
        Move(ui.raidC6GuildLeader180, ui.raidDetailsPanel180, 232, -actionY2, 140, 26)
        Move(ui.raidEdit156, ui.raidDetailsPanel180, math.max(232, detailWidth - 174), -actionY2, 72, 26)
        Move(ui.raidMore156, ui.raidDetailsPanel180, detailWidth - 88, -actionY2, 72, 26)
        Hide(ui.raidRosterSummary180) Hide(ui.raidRefreshRoster180) Hide(ui.raidNoRole156)
    end
end

local function LayoutPveGroups(owner, panel, width, height)
    local ui = owner.ui
    local list = ui.pveGroupList180
    local form = ui.pveGroupForm180
    local details = ui.pveGroupDetails180
    local gap = 10
    local rightWidth = math.max(330, math.min(430, math.floor(width * 0.42)))
    local leftWidth = width - rightWidth - gap
    if leftWidth < 410 then
        leftWidth = 410
        rightWidth = math.max(300, width - leftWidth - gap)
    end
    local rightX = leftWidth + gap
    Move(list, panel, 0, 0, leftWidth, height)

    local requests = owner:GetPveRequests() or {}
    local ownGroup = nil
    local requestIndex
    for requestIndex = 1, table.getn(requests) do
        if owner.IsOwnPveGroup and owner:IsOwnPveGroup(requests[requestIndex]) then ownGroup = requests[requestIndex] break end
    end
    UI:SetText(ui.pveGroupCreateToggle180, ownGroup and "Edit My Group" or "+ Create Group")
    ui.pveGroupCreateToggle180:SetWidth(ownGroup and 146 or 132)
    ui.pveGroupCreateToggle180:ClearAllPoints()
    ui.pveGroupCreateToggle180:SetPoint("TOPRIGHT", list, "TOPRIGHT", -8, -6)

    local empty = table.getn(requests) == 0
    if empty and not (form and form:IsVisible()) then
        Move(ui.pveGroupEmpty180, panel, 12, -math.max(58, math.floor((height - 150) / 2)), math.max(280, leftWidth - 24), 150)
        Show(ui.pveGroupEmpty180)
    else
        Hide(ui.pveGroupEmpty180)
    end
    if form then
        Size(form, 304, 438)
        if owner.ui.modalHost and form.GetParent and form:GetParent() == owner.ui.modalHost then
            form:ClearAllPoints()
            form:SetPoint("CENTER", owner.ui.modalHost, "CENTER", 0, 0)
            form:SetFrameLevel(owner.ui.modalHost:GetFrameLevel() + 12)
        end
        if not form.otlNativeInitialHidden180 then form.otlNativeInitialHidden180 = true form:Hide() end
    end
    if ui.pveRequestCount then Move(ui.pveRequestCount, list, math.max(170, leftWidth - 390), -10, 236, 18) end

    local rows = ui.pveRequestRows or {}
    local rowArea = math.max(230, height - 42)
    local capacity = math.max(4, math.min(ui.pveGroupRowPool180 or table.getn(rows), math.floor(rowArea / 52)))
    ui.pveGroupVisibleRows180 = capacity
    local rowHeight = math.max(48, math.min(66, math.floor(rowArea / math.max(1, capacity))))
    local index, row
    for index = 1, table.getn(rows) do
        row = rows[index]
        if index <= capacity then Move(row, list, 10, -34 - ((index - 1) * rowHeight), leftWidth - 44, rowHeight - 4) else row:Hide() end
        if row.title then row.title:SetWidth(math.max(150, leftWidth - 320)) end
        if row.author then row.author:ClearAllPoints() row.author:SetPoint("TOPRIGHT", row, "TOPRIGHT", -12, -6) row.author:SetWidth(142) end
        if row.composition then row.composition:SetWidth(math.max(160, leftWidth - 270)) end
        if row.status then row.status:ClearAllPoints() row.status:SetPoint("TOPRIGHT", row, "TOPRIGHT", -12, -25) row.status:SetWidth(142) end
    end
    Hide(ui.pveGroupSlider)
    local groupScrollbar = ui.pveGroupScrollbar180
    if not groupScrollbar then ui.pveNativeRefreshPending180 = true return end
    Move(groupScrollbar, list, leftWidth - 19, -34, 14, math.max(100, rowArea - 6))
    local groupMaximum = math.max(0, table.getn(requests) - capacity)
    ui.pveGroupOffset = math.max(0, math.min(groupMaximum, tonumber(ui.pveGroupOffset) or 0))
    if groupScrollbar.SetScrollMetrics180 then groupScrollbar:SetScrollMetrics180(table.getn(requests), capacity, ui.pveGroupOffset) end

    local tabGap = 6
    local detailsTabWidth = math.floor((rightWidth - tabGap) * 0.55)
    Move(ui.pveGroupDetailsTab180, panel, rightX, 0, detailsTabWidth, 28)
    Move(ui.pveGroupProfileTab180, panel, rightX + detailsTabWidth + tabGap, 0, rightWidth - detailsTabWidth - tabGap, 28)
    local bodyY = 36
    Move(details, panel, rightX, -bodyY, rightWidth, height - bodyY)
    Move(ui.pveGroupProfilePanel180, panel, rightX, -bodyY, rightWidth, height - bodyY)
    UI:SetSelected(ui.pveGroupDetailsTab180, (ui.pveGroupRightTab180 or "DETAILS") == "DETAILS")
    UI:SetSelected(ui.pveGroupProfileTab180, (ui.pveGroupRightTab180 or "DETAILS") == "PROFILE")
    if (ui.pveGroupRightTab180 or "DETAILS") == "PROFILE" then Hide(details) Show(ui.pveGroupProfilePanel180) else Show(details) Hide(ui.pveGroupProfilePanel180) end

    if ui.pveRequestSelectedText then ui.pveRequestSelectedText:SetWidth(math.max(180, rightWidth - 20)) end
    local noteWidth = math.max(96, rightWidth - 242)
    Move(ui.pveJoinNoteEdit, details, 232, -42, noteWidth, 24)
    Move(ui.pveRequestDeleteButton, details, math.max(298, rightWidth - 112), -72, 102, 24)
    local applicantWidth = math.max(86, math.floor((rightWidth - 28) / 3))
    for index = 1, table.getn(ui.pveApplicantButtons or {}) do Move(ui.pveApplicantButtons[index], details, 10 + ((index - 1) * (applicantWidth + 4)), -42, applicantWidth, 24) end
    Move(ui.pveApplicantAcceptButton, details, 10, -72, math.min(116, math.max(98, rightWidth - 216)), 24)
    Move(ui.pveApplicantDeclineButton, details, math.min(134, rightWidth - 172), -72, 88, 24)
    Move(ui.pveApplicantWhisperButton, details, math.min(230, rightWidth - 76), -72, 74, 24)
    if ui.pveGroupShare180 then
        Move(ui.pveGroupShare180, details, rightWidth - 116, -(height - bodyY - 32), 104, 24)
        UI:SetEnabled(ui.pveGroupShare180, owner.GetPveRequestByID and owner:GetPveRequestByID(ui.pveSelectedRequest) ~= nil, "Select a group first.")
    end

    local profile = ui.pveGroupProfilePanel180
    if profile then
        Move(profile.classIcon, profile, 14, -36, 42, 42)
        Move(profile.identity, profile, 66, -36, rightWidth - 80, 42)
        Move(profile.roleTitle, profile, 14, -92, rightWidth - 28, 18)
        local roleWidth = math.max(92, math.floor((rightWidth - 36) / 3))
        Move(profile.roles.TANK, profile, 14, -116, roleWidth, 26)
        Move(profile.roles.HEAL, profile, 18 + roleWidth, -116, roleWidth, 26)
        Move(profile.roles.DPS, profile, 22 + (roleWidth * 2), -116, roleWidth, 26)
        Move(profile.notify, profile, 14, -154, rightWidth - 28, 28)
        Move(profile.matchState, profile, 14, -190, rightWidth - 28, 38)
        Move(profile.noteTitle, profile, 14, -240, rightWidth - 28, 18)
        Move(profile.note, profile, 14, -262, rightWidth - 28, 30)
        Move(profile.noteHelp, profile, 14, -302, rightWidth - 28, 36)
        Move(profile.privacy, profile, 14, -352, rightWidth - 28, 42)
        Move(profile.saved, profile, 14, -(height - bodyY - 26), rightWidth - 28, 18)
        owner:RefreshPveCharacterProfile180()
    end
end

local function LayoutPveBoard(owner, panel, width, height)
    local ui = owner.ui
    local composerHeight = 82
    Move(ui.pveBoardComposer180, panel, 0, 0, width, composerHeight)
    Move(ui.pveBoardEdit, ui.pveBoardComposer180, 12, -32, width - 134, 36)
    Move(ui.pveBoardPostButton, ui.pveBoardComposer180, width - 112, -32, 100, 36)
    Move(ui.pveBoardList180, panel, 0, -(composerHeight + 8), width, height - composerHeight - 8)
    local listHeight = ui.pveBoardList180:GetHeight()
    local footerHeight = 42
    local rows = ui.pveBoardRows or {}
    local rowHeight = math.max(34,
        math.floor((listHeight - footerHeight - 18) / math.max(1, table.getn(rows))))
    local index, row
    for index = 1, table.getn(rows) do
        row = rows[index]
        Move(row, ui.pveBoardList180, 10, -10 - ((index - 1) * rowHeight), width - 20, rowHeight - 4)
        if row.messageText then row.messageText:SetWidth(math.max(180, width - 224)) end
    end
    Move(ui.pveBoardSelected, ui.pveBoardList180, 10, -(listHeight - 32), width - 250, 20)
    Move(ui.pveBoardWhisperButton, ui.pveBoardList180, width - 218, -(listHeight - 38), 96, 30)
    Move(ui.pveBoardDeleteButton, ui.pveBoardList180, width - 112, -(listHeight - 38), 100, 30)
    local posts = owner:GetPveBoardPosts() or {}
    if table.getn(posts) == 0 then
        Move(ui.pveBoardEmpty180, ui.pveBoardList180, math.max(12, math.floor((width - 560) / 2)),
            -math.max(40, math.floor((listHeight - 128) / 2)), math.min(560, width - 24), 128)
        Show(ui.pveBoardEmpty180)
    else
        Hide(ui.pveBoardEmpty180)
    end
end


local C6_RAID_ROLE_SEQUENCE180 = { "TANK", "HEALER", "DAMAGE", "UNASSIGNED" }
local C6_CLASS_COORDS180 = {
    WARRIOR = { 0, 0.25, 0, 0.25 }, MAGE = { 0.25, 0.5, 0, 0.25 }, ROGUE = { 0.5, 0.75, 0, 0.25 }, DRUID = { 0.75, 1, 0, 0.25 },
    HUNTER = { 0, 0.25, 0.25, 0.5 }, SHAMAN = { 0.25, 0.5, 0.25, 0.5 }, PRIEST = { 0.5, 0.75, 0.25, 0.5 }, WARLOCK = { 0.75, 1, 0.25, 0.5 },
    PALADIN = { 0, 0.25, 0.5, 0.75 },
}

local function SetRaidC6ClassIcon180(texture, classToken)
    if not texture then return end
    local coords = C6_CLASS_COORDS180[string.upper(tostring(classToken or ""))]
    if coords then
        texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
        texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        texture:Show()
    else texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") texture:SetTexCoord(0, 1, 0, 1) texture:Show() end
end

local function RaidC6StatusText180(owner, event, access)
    if not event or not access then return "Select a raid event." end
    local teamName = access.team and access.team.name or "the confirmed team"
    local role = access.member and (access.member.mainRole or access.member.role or "UNASSIGNED") or ""
    if role == "FLEXIBLE" or role == "UNASSIGNED" then role = "Needs Review" end
    if access.state == "ASSIGNED" then
        local eventTime = OTLGM.GetPveRaidServerTime155 and OTLGM:GetPveRaidServerTime155(event) or tostring(event.serverTime or "Time TBA")
        return "|cff74d67aYou are assigned to this raid.|r  Role: " .. tostring(role) .. "  •  " .. eventTime
    elseif access.state == "RESERVE" then
        return "|cffffcc66You are listed as a reserve.|r You may be contacted if a place becomes available."
    elseif access.state == "GUEST" then
        return "|cffffcc66You are listed as a guest for this event.|r Contact the Raid Leader for participation details."
    elseif access.state == "TEAM_NOT_ASSIGNED" then
        return "You are a member of " .. tostring(teamName) .. ", but you are not assigned to this raid."
    elseif access.state == "ALT_ASSIGNED" then
        return "Another character on this account is assigned: |cffffcc66" .. tostring(access.altName or "Unknown") .. "|r. Ready is available only on that character."
    elseif access.state == "OPEN_GUILD" then
        return "This raid is open to guild members. Sign-up is managed through Discord."
    elseif access.state == "LEADERSHIP_NOT_PARTICIPANT" then
        return "Leadership access — you are not part of this raid roster."
    elseif access.state == "CANCELLED" then return "|cffff5b5bThis raid has been cancelled.|r"
    elseif access.state == "PAST" then return "This raid event is in the past. Participant actions are closed."
    elseif access.state == "DRAFT" then return "This raid is still a draft. Participant actions are unavailable."
    end
    if event.teamId180 then return "This raid uses a confirmed team roster. Contact the Raid Leader or use Discord sign-up." end
    return "You are not assigned to this raid. Contact the Raid Leader or use Discord sign-up."
end

local function RaidC6SetButtonShown180(button, shown)
    if not button then return end
    if shown then button:Show() else button:Hide() end
end

local function RefreshRaidC6Manager180(owner)
    local ui = owner.ui
    local modal = ui and ui.raidC6Manager180
    if not modal or not modal:IsVisible() then return false end
    local event = owner:GetRaidEvent180(modal.eventId180)
    if not event then owner:CloseModal180(modal, "event-missing") return false end
    local access = owner:GetRaidEventAccess180(event)
    if not access.canManage and not access.canInvite then owner:CloseModal180(modal, "permission-lost") return false end
    owner:RefreshRaidInviteLiveState180(event.id, access.canInvite)
    local mode = modal.mode180 or "ROSTER"
    UI:SetSelected(modal.rosterTab180, mode == "ROSTER")
    UI:SetSelected(modal.inviteTab180, mode == "INVITES")
    modal.title180:SetText((mode == "INVITES" and "RAID INVITE MODE — " or "EVENT ROSTER — ") .. tostring(event.name or "Guild Raid"))
    local rows = owner:GetRaidOrganizerRows180(event, mode)
    modal.rowsData180 = rows
    local maximum = math.max(0, table.getn(rows) - modal.visibleRows180)
    modal.offset180 = math.max(0, math.min(maximum, tonumber(modal.offset180) or 0))
    if modal.scrollbar180 and modal.scrollbar180.SetScrollMetrics180 then modal.scrollbar180:SetScrollMetrics180(table.getn(rows), modal.visibleRows180, modal.offset180) end
    local selectedExists = false
    local index, visual, data
    for index = 1, table.getn(modal.rows180) do
        visual = modal.rows180[index]
        data = rows[(modal.offset180 or 0) + index]
        visual.data180 = data
        if data then
            visual:Show()
            if data.header then
                visual.classIcon180:Hide()
                visual.name180:SetText("|cffffcc66" .. tostring(data.label) .. "|r  " .. tostring(data.count or 0))
                visual.meta180:SetText("")
                visual:SetBackdropColor(0.08, 0.07, 0.04, 0.96)
            else
                SetRaidC6ClassIcon180(visual.classIcon180, data.class)
                visual.name180:SetText(tostring(data.character or "Unknown"))
                local statusText = tostring(data.slotStatus or "ASSIGNED") .. "  •  " .. tostring(data.mainRole or "UNASSIGNED")
                    .. "  •  " .. (data.seen and "Seen" or "Unseen") .. " / " .. (data.ready and "Ready" or "Not Ready")
                    .. "  •  " .. tostring(data.inviteState or "WAITING") .. "  •  " .. tostring(data.addonStatus or "Not detected")
                visual.meta180:SetText(statusText)
                local selected = modal.selectedCharacter180 and string.lower(tostring(modal.selectedCharacter180)) == string.lower(tostring(data.character or ""))
                if selected then selectedExists = true visual:SetBackdropColor(0.24, 0.18, 0.05, 0.96)
                elseif data.online then visual:SetBackdropColor(0.04, 0.08, 0.05, 0.92)
                else visual:SetBackdropColor(0.04, 0.04, 0.04, 0.90) end
            end
        else visual:Hide() end
    end
    if modal.selectedCharacter180 and not selectedExists then
        local _, row
        for _, row in pairs(event.roster180 or {}) do if string.lower(tostring(row.character or "")) == string.lower(tostring(modal.selectedCharacter180)) then selectedExists = true break end end
        if not selectedExists then modal.selectedCharacter180 = nil end
    end
    local selected = modal.selectedCharacter180 and owner:GetRaidEventRosterMember180(event, modal.selectedCharacter180) or nil
    modal.selection180:SetText(selected and ("Selected: " .. tostring(selected.character) .. "  •  " .. tostring(selected.slotStatus or "ASSIGNED") .. "  •  " .. tostring(selected.mainRole or selected.role or "UNASSIGNED")) or "Select a participant to use actions.")
    local canRoster = access.canManage and selected ~= nil
    local canInviteSelected = access.canInvite and selected and selected.slotStatus == "ASSIGNED"
    RaidC6SetButtonShown180(modal.whisper180, selected ~= nil)
    RaidC6SetButtonShown180(modal.invite180, mode == "INVITES" and canInviteSelected)
    RaidC6SetButtonShown180(modal.assigned180, canRoster and selected.slotStatus ~= "ASSIGNED")
    RaidC6SetButtonShown180(modal.reserve180, canRoster and selected.slotStatus ~= "RESERVE")
    RaidC6SetButtonShown180(modal.role180, canRoster)
    RaidC6SetButtonShown180(modal.remove180, canRoster)
    RaidC6SetButtonShown180(modal.start180, access.canInvite)
    RaidC6SetButtonShown180(modal.next180, access.canInvite and mode == "INVITES")
    if selected and modal.invite180:IsVisible() then
        local state = owner:GetRaidInviteState180(event, selected)
        UI:SetText(modal.invite180, state == "INVITED" and "Invited" or state == "JOINED" and "Joined" or state == "OFFLINE" and "Offline" or "Invite")
        UI:SetEnabled(modal.invite180, state == "WAITING", state == "OFFLINE" and "Character is offline." or state == "JOINED" and "Character already joined." or "Invite already sent.")
    end
    local total, assigned, reserve, guest = owner:GetRaidRosterSummary180(event.roster180 or {})
    modal.summary180:SetText("Roster " .. tostring(total) .. "  •  Assigned " .. tostring(assigned) .. "  •  Reserve " .. tostring(reserve) .. "  •  Guest " .. tostring(guest)
        .. (event.invitesOpen and "  •  |cff5fd9ffInvites open|r" or ""))
    return true
end

function OTLGM:OpenRaidEventManager180(eventId, mode)
    local ui = self.ui
    local modal = ui and ui.raidC6Manager180
    local event = self:GetRaidEvent180(eventId)
    if not modal or not event then return false end
    local access = self:GetRaidEventAccess180(event)
    if not access.canManage and not access.canInvite then return false end
    modal.eventId180 = eventId
    modal.mode180 = mode == "INVITES" and "INVITES" or "ROSTER"
    modal.offset180 = 0 modal.selectedCharacter180 = nil
    if self.ShowModal152 then self:ShowModal152(modal) else modal:Show() end
    RefreshRaidC6Manager180(self)
    return true
end

function OTLGM:RefreshRaidC6Details180()
    local ui = self.ui
    if not ui or not ui.raidPersonalStatus180 then return false end
    local event = self:GetRaidEvent180(ui.raidSelected156)
    if not event then
        ui.raidPersonalStatus180:SetText("Select a raid event to see your personal status.")
        RaidC6SetButtonShown180(ui.raidSeen156, false) RaidC6SetButtonShown180(ui.raidReady156, false)
        RaidC6SetButtonShown180(ui.raidC6Contact180, false) RaidC6SetButtonShown180(ui.raidC6GuildLeader180, false) RaidC6SetButtonShown180(ui.raidC6Discord180, false)
        RaidC6SetButtonShown180(ui.raidC6Copy180, false) RaidC6SetButtonShown180(ui.raidC6Manage180, false)
        return false
    end
    local access = self:GetRaidEventAccess180(event)
    ui.raidPersonalStatus180:SetText(RaidC6StatusText180(self, event, access))
    local participant = self:GetRaidEventParticipantStatus180(event)
    RaidC6SetButtonShown180(ui.raidSeen156, access.canSeen)
    RaidC6SetButtonShown180(ui.raidReady156, access.canReady)
    if access.canSeen then UI:SetText(ui.raidSeen156, participant.seen and "Seen ✓" or "Mark Seen") UI:SetSelected(ui.raidSeen156, participant.seen) end
    if access.canReady then UI:SetText(ui.raidReady156, participant.ready and "Ready ✓" or "Mark Ready") UI:SetSelected(ui.raidReady156, participant.ready) end
    local target = self:GetRaidEventContactTarget180(event)
    RaidC6SetButtonShown180(ui.raidC6Contact180, target ~= nil)
    if target then UI:SetText(ui.raidC6Contact180, "Whisper RL: " .. self:Utf8Truncate(target, 10)) ui.raidC6Contact180.target180 = target end
    local guildLeader = self.GetRaidEventGuildLeader180 and self:GetRaidEventGuildLeader180() or nil
    local showGuildLeader = guildLeader and not access.canManage and string.lower(tostring(guildLeader)) ~= string.lower(tostring(target or ""))
        and string.lower(tostring(guildLeader)) ~= string.lower(tostring(UnitName("player") or ""))
    RaidC6SetButtonShown180(ui.raidC6GuildLeader180, showGuildLeader and true or false)
    if showGuildLeader then ui.raidC6GuildLeader180.target180 = guildLeader end
    RaidC6SetButtonShown180(ui.raidC6Discord180, true)
    UI:SetText(ui.raidC6Discord180, event.discordUrl180 and event.discordUrl180 ~= "" and "Copy Discord" or "Guild Info")
    RaidC6SetButtonShown180(ui.raidC6Copy180, true)
    RaidC6SetButtonShown180(ui.raidC6Manage180, access.canManage or access.canInvite)
    UI:SetText(ui.raidC6Manage180, access.canInvite and (event.invitesOpen and "Invite Mode" or "Manage Raid") or "Manage Roster")
    RaidC6SetButtonShown180(ui.raidEdit156, access.canManage)
    RaidC6SetButtonShown180(ui.raidMore156, access.canManage)
    if ui.raidRefreshRoster180 then RaidC6SetButtonShown180(ui.raidRefreshRoster180, access.canManage and event.teamId180 ~= nil) end
    if ui.raidWhisperInvite175 then ui.raidWhisperInvite175:Hide() end
    if ui.raidStartInvites175 then ui.raidStartInvites175:Hide() end
    if ui.raidNoRole156 then ui.raidNoRole156:Hide() end
    return true
end

EnsureRaidC6Controls180 = function(owner)
    local ui = owner and owner.ui
    local detail = ui and ui.raidDetailsPanel180
    if not detail then return false end
    if not ui.raidPersonalStatus180 then
        ui.raidPersonalStatus180 = UI.Text(detail, "Select a raid event to see your personal status.", "GameFontNormalSmall", "LEFT")
        ui.raidPersonalStatus180:SetJustifyV("TOP")
        ui.raidPersonalStatus180:SetTextColor(0.90, 0.88, 0.80)
        ui.raidC6Contact180 = UI:Button(detail, "Whisper Raid Leader", 128, 28, function()
            local target = OTLGM.ui.raidC6Contact180.target180
            if target and OTLGM.OpenGuildChatWhisper then OTLGM:OpenGuildChatWhisper(target) end
        end, "utility")
        ui.raidC6GuildLeader180 = UI:Button(detail, "Whisper Guild Leader", 140, 28, function()
            local target = OTLGM.ui.raidC6GuildLeader180.target180
            if target and OTLGM.OpenGuildChatWhisper then OTLGM:OpenGuildChatWhisper(target) end
        end, "utility")
        ui.raidC6Discord180 = UI:Button(detail, "Guild Info", 104, 28, function()
            local event = OTLGM:GetRaidEvent180(OTLGM.ui.raidSelected156)
            if event and event.discordUrl180 and event.discordUrl180 ~= "" then OTLGM:ShowCopyDialog("Raid Discord Sign-up", event.discordUrl180)
            elseif OTLGM.ShowPage then OTLGM:ShowPage("guildinfo") end
        end, "utility")
        ui.raidC6Copy180 = UI:Button(detail, "Copy Raid Info", 112, 28, function()
            local event = OTLGM:GetRaidEvent180(OTLGM.ui.raidSelected156)
            if event then OTLGM:ShowCopyDialog("Raid Information", OTLGM:GetRaidEventSummaryText180(event)) end
        end, "utility")
        ui.raidC6Manage180 = UI:Button(detail, "Manage Raid", 112, 28, function()
            local event = OTLGM:GetRaidEvent180(OTLGM.ui.raidSelected156)
            if event then OTLGM:OpenRaidEventManager180(event.id, event.invitesOpen and "INVITES" or "ROSTER") end
        end, "primary")
        if ui.raidSeen156 then ui.raidSeen156:SetScript("OnClick", function()
            local ok, message = OTLGM:SetRaidParticipantStatus180(OTLGM.ui.raidSelected156, "SEEN")
            if not ok and OTLGM.SetStatus then OTLGM:SetStatus(message or "Seen could not be updated.") end
            OTLGM:RefreshRaidPlanner156()
        end) end
        if ui.raidReady156 then ui.raidReady156:SetScript("OnClick", function()
            local ok, message = OTLGM:SetRaidParticipantStatus180(OTLGM.ui.raidSelected156, "READY")
            if not ok and OTLGM.SetStatus then OTLGM:SetStatus(message or "Ready could not be updated.") end
            OTLGM:RefreshRaidPlanner156()
        end) end
    end
    if not ui.raidC6Manager180 then
        local modal = UI:Modal(ui.main, 790, 610)
        modal.otlNonDangerModal180 = true modal.mode180 = "ROSTER" modal.offset180 = 0 modal.visibleRows180 = 10
        ui.raidC6Manager180 = modal
        if owner.RegisterModal152 then owner:RegisterModal152(modal) end
        modal.title180 = UI.Text(modal, "EVENT ROSTER", "GameFontNormalLarge", "CENTER")
        Move(modal.title180, modal, 22, -16, 746, 28)
        modal.close180 = UI:Button(modal, "X", 28, 24, function() OTLGM:CloseModal180(modal, "x") end, "danger")
        Move(modal.close180, modal, 750, -10, 28, 24)
        modal.rosterTab180 = UI:Button(modal, "Organizer Roster", 142, 28, function() modal.mode180 = "ROSTER" modal.offset180 = 0 modal.selectedCharacter180 = nil RefreshRaidC6Manager180(OTLGM) end, "filter")
        modal.inviteTab180 = UI:Button(modal, "Invite Mode", 122, 28, function() modal.mode180 = "INVITES" modal.offset180 = 0 modal.selectedCharacter180 = nil RefreshRaidC6Manager180(OTLGM) end, "filter")
        Move(modal.rosterTab180, modal, 20, -52, 142, 28) Move(modal.inviteTab180, modal, 170, -52, 122, 28)
        modal.summary180 = UI.Text(modal, "", "GameFontNormalSmall", "RIGHT") Move(modal.summary180, modal, 308, -58, 452, 20)
        modal.list180 = UI:Surface(modal, "card", 748, 386) Move(modal.list180, modal, 20, -88, 748, 386)
        modal.rows180 = {}
        local index
        for index = 1, modal.visibleRows180 do
            local row = UI:Button(modal.list180, "", 720, 34, function()
                local data = this.data180
                if data and not data.header then modal.selectedCharacter180 = data.character RefreshRaidC6Manager180(OTLGM) end
            end, "row")
            Move(row, modal.list180, 8, -8 - ((index - 1) * 37), 720, 34)
            row.classIcon180 = row:CreateTexture(nil, "ARTWORK") row.classIcon180:SetWidth(22) row.classIcon180:SetHeight(22) row.classIcon180:SetPoint("LEFT", row, "LEFT", 8, 0)
            row.name180 = UI.Text(row, "", "GameFontNormal", "LEFT") Move(row.name180, row, 38, -7, 170, 20)
            row.meta180 = UI.Text(row, "", "GameFontNormalSmall", "LEFT") Move(row.meta180, row, 214, -7, 494, 20)
            table.insert(modal.rows180, row)
        end
        modal.scrollbar180 = UI:Scrollbar(modal.list180, 366, function(value) modal.offset180 = math.max(0, math.floor((tonumber(value) or 0) + 0.5)) RefreshRaidC6Manager180(OTLGM) end)
        Move(modal.scrollbar180, modal.list180, 730, -8, 14, 366)
        SetWheel(modal.list180, function(delta)
            local rows = modal.rowsData180 or {}
            local maximum = math.max(0, table.getn(rows) - modal.visibleRows180)
            modal.offset180 = math.max(0, math.min(maximum, (modal.offset180 or 0) - ((tonumber(delta) or 0) * 2)))
            RefreshRaidC6Manager180(OTLGM)
        end)
        modal.selection180 = UI.Text(modal, "Select a participant to use actions.", "GameFontNormalSmall", "LEFT") Move(modal.selection180, modal, 20, -486, 748, 20)
        modal.whisper180 = UI:Button(modal, "Whisper", 88, 28, function()
            if modal.selectedCharacter180 and OTLGM.OpenGuildChatWhisper then OTLGM:OpenGuildChatWhisper(modal.selectedCharacter180) end
        end, "utility")
        modal.invite180 = UI:Button(modal, "Invite", 88, 28, function()
            local ok, message = OTLGM:InviteRaidParticipant180(modal.eventId180, modal.selectedCharacter180)
            if OTLGM.SetStatus then OTLGM:SetStatus(ok and ("Invite sent to " .. tostring(modal.selectedCharacter180) .. ".") or (message or "Invite failed.")) end
            RefreshRaidC6Manager180(OTLGM)
        end, "primary")
        modal.assigned180 = UI:Button(modal, "Move Assigned", 116, 28, function()
            local ok, message = OTLGM:MoveRaidEventMember180(modal.eventId180, modal.selectedCharacter180, "ASSIGNED")
            if not ok and OTLGM.SetStatus then OTLGM:SetStatus(message or "Roster update failed.") end RefreshRaidC6Manager180(OTLGM)
        end, "utility")
        modal.reserve180 = UI:Button(modal, "Move Reserve", 112, 28, function()
            local ok, message = OTLGM:MoveRaidEventMember180(modal.eventId180, modal.selectedCharacter180, "RESERVE")
            if not ok and OTLGM.SetStatus then OTLGM:SetStatus(message or "Roster update failed.") end RefreshRaidC6Manager180(OTLGM)
        end, "utility")
        modal.role180 = UI:Button(modal, "Set Role", 94, 28, function()
            local event = OTLGM:GetRaidEvent180(modal.eventId180)
            local member = event and OTLGM:GetRaidEventRosterMember180(event, modal.selectedCharacter180)
            if member then
                local current = member.mainRole or member.role or "UNASSIGNED" if current == "FLEXIBLE" then current = "UNASSIGNED" end
                local nextRole, i = "TANK", 1
                for i = 1, table.getn(C6_RAID_ROLE_SEQUENCE180) do if C6_RAID_ROLE_SEQUENCE180[i] == current then nextRole = C6_RAID_ROLE_SEQUENCE180[math.mod(i, table.getn(C6_RAID_ROLE_SEQUENCE180)) + 1] break end end
                OTLGM:SetRaidEventMemberRole180(event.id, member.character, nextRole)
            end
            RefreshRaidC6Manager180(OTLGM)
        end, "utility")
        modal.remove180 = UI:Button(modal, "Remove", 82, 28, function()
            local character = modal.selectedCharacter180
            if character then OTLGM:ShowConfirm("Remove Participant", "Remove " .. tostring(character) .. " from this event roster?", "Remove", function()
                OTLGM:RemoveRaidEventMember180(modal.eventId180, character) modal.selectedCharacter180 = nil RefreshRaidC6Manager180(OTLGM)
            end) end
        end, "danger")
        local actionButtons = { modal.whisper180, modal.invite180, modal.assigned180, modal.reserve180, modal.role180, modal.remove180 }
        local actionX = 20
        for index = 1, table.getn(actionButtons) do Move(actionButtons[index], modal, actionX, -514, actionButtons[index]:GetWidth(), 28) actionX = actionX + actionButtons[index]:GetWidth() + 6 end
        modal.start180 = UI:Button(modal, "Start Invites", 116, 30, function()
            local ok, message = OTLGM:StartRaidInviteCollection180(modal.eventId180)
            if OTLGM.SetStatus then OTLGM:SetStatus(ok and "Invite collection started." or (message or "Invite collection could not start.")) end
            modal.mode180 = "INVITES" RefreshRaidC6Manager180(OTLGM)
        end, "primary")
        modal.next180 = UI:Button(modal, "Invite Next Online", 146, 30, function()
            local ok, message = OTLGM:InviteNextRaidParticipant180(modal.eventId180)
            if OTLGM.SetStatus then OTLGM:SetStatus(ok and "Invited the next online waiting participant." or (message or "No participant invited.")) end
            RefreshRaidC6Manager180(OTLGM)
        end, "primary")
        modal.done180 = UI:Button(modal, "Done", 86, 30, function() OTLGM:CloseModal180(modal, "done") end, "secondary")
        Move(modal.start180, modal, 20, -558, 116, 30) Move(modal.next180, modal, 144, -558, 146, 30) Move(modal.done180, modal, 682, -558, 86, 30)
    end
    return true
end

local function RefreshPveNative(owner)
    if not owner.ui then return false end
    if not EnsurePveNativeControls(owner) then
        owner.ui.pveNativeRefreshPending180 = true
        return false
    end
    local page = owner.shellPageModules and owner.shellPageModules.pve
        and owner.shellPageModules.pve.root or nil
    if not page then
        owner.ui.pveNativeRefreshPending180 = true
        return false
    end
    owner.ui.pveNativeRefreshPending180 = nil
    if page.otlSemanticRefs then SuppressLegacy(page.otlSemanticRefs) end
    if owner.ui.pveRaidAreaMode180 == "TEAMS" and owner.RefreshRaidTeamsPanel180 then owner:RefreshRaidTeamsPanel180()
    elseif owner.ui.pveRaidAreaMode180 == "EVENTS" and owner.RefreshRaidC6Details180 then owner:RefreshRaidC6Details180() end
    if owner.ui.raidC6Manager180 and owner.ui.raidC6Manager180:IsVisible() then RefreshRaidC6Manager180(owner) end
    return true
end

local function LayoutPve(owner, page, width, height)
    local previousRaidRows = tonumber(owner.ui.raidVisibleRows180)
    local previousGroupRows = tonumber(owner.ui.pveGroupVisibleRows180)
    local previousTeamRows = tonumber(owner.ui.raidTeamVisibleRows180)
    local previousMemberRows = tonumber(owner.ui.raidTeamMemberVisibleRows180)
    local refs = page.otlSemanticRefs
    SuppressLegacy(refs)
    if not EnsurePveNativeControls(owner) then
        owner.ui.pveNativeRefreshPending180 = true
        return
    end
    local order = { "RAIDS", "GROUPS", "BOARD" }
    local index
    for index = 1, table.getn(order) do
        Move(owner.ui.pveTabButtons[order[index]], page, (index - 1) * 150, 0,
            order[index] == "BOARD" and 126 or 142, 30)
    end
    Move(owner.ui.pveSyncButton, page, width - 104, 0, 104, 30)
    Move(owner.ui.pveNetworkText, page, width - 276, -7, 160, 20)
    local bodyY = 40
    local bodyHeight = math.max(330, height - bodyY)
    local key, panel
    for key, panel in pairs(owner.ui.pvePanels or {}) do
        Move(panel, page, 0, -bodyY, width, bodyHeight)
    end
    LayoutRaidPlanner(owner, owner.ui.pvePanels.RAIDS, width, bodyHeight)
    LayoutPveGroups(owner, owner.ui.pvePanels.GROUPS, width, bodyHeight)
    LayoutPveBoard(owner, owner.ui.pvePanels.BOARD, width, bodyHeight)
    page.otlPveFlow180 = {
        primaryToolbarTop = 0,
        primaryToolbarBottom = 30,
        bodyTop = bodyY,
        bodyBottom = bodyY + bodyHeight,
        raidToolbarTop = bodyY,
        raidToolbarBottom = bodyY + 28,
        raidContentTop = bodyY + 38,
    }
    page.otlNativeLayout = true
    if owner.MarkLayoutDataRefresh180 and ((previousRaidRows and previousRaidRows ~= owner.ui.raidVisibleRows180)
        or (previousGroupRows and previousGroupRows ~= owner.ui.pveGroupVisibleRows180)
        or (previousTeamRows and previousTeamRows ~= owner.ui.raidTeamVisibleRows180)
        or (previousMemberRows and previousMemberRows ~= owner.ui.raidTeamMemberVisibleRows180)) then
        owner:MarkLayoutDataRefresh180("pve")
    end
end

-- ---------------------------------------------------------------------------
-- Remaining pages: explicit references and ContentHost-relative geometry.
-- ---------------------------------------------------------------------------

local function LayoutGuildInfo(owner, page, width, height)
    SuppressLegacy(page.otlSemanticRefs)
    local viewportWidth = width - 18
    Move(owner.ui.guildInfoViewport, page, 0, 0, viewportWidth, height)
    if owner.ui.guildInfoChild then owner.ui.guildInfoChild:SetWidth(viewportWidth - 22) end
    local textWidth = math.max(320, viewportWidth - 58)
    if owner.ui.guildInfoMotd then owner.ui.guildInfoMotd:SetWidth(textWidth) end
    if owner.ui.guildInfoText then owner.ui.guildInfoText:SetWidth(textWidth) end
    if owner.ui.guildInfoLeadership then owner.ui.guildInfoLeadership:SetWidth(textWidth) end
    if owner.ui.guildCurrentRank then owner.ui.guildCurrentRank:SetWidth(math.max(220, textWidth - 320)) end
    local index
    for index = 1, table.getn(owner.ui.guildRankCards or {}) do
        Size(owner.ui.guildRankCards[index], textWidth, owner.ui.guildRankCards[index]:GetHeight())
    end
    Move(owner.ui.guildInfoSlider, page, width - 12, 0, owner.ui.guildInfoSlider:GetWidth(), height)
    if owner.ui.guildInfoSlider and owner.ui.guildInfoContentHeight then
        owner.ui.guildInfoSlider:SetMinMaxValues(0, math.max(0, owner.ui.guildInfoContentHeight - height))
    end
    page.otlNativeLayout = true
end

local function EnsureTreasuryGoalScrollbar180(owner)
    local treasury = owner.ui and owner.ui.treasury170
    if not treasury or not treasury.list or treasury.goalScrollbar180 then return end
    local bar = UI:Scrollbar(treasury.list, 240, function(value)
        treasury.offset = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
        owner:RefreshTreasuryPage170()
    end)
    treasury.goalScrollbar180 = bar
    SetWheel(treasury.list, function(delta)
        local maximum = tonumber(treasury.goalMaximumOffset180) or 0
        local value = math.max(0, math.min(maximum, (tonumber(treasury.offset) or 0) - ((tonumber(delta) or 0) * 2)))
        treasury.offset = value
        owner:RefreshTreasuryPage170()
    end)
end

local function LayoutTreasury(owner, page, width, height)
    SuppressLegacy(page.otlSemanticRefs)
    local ui = owner.ui.treasury170
    if not ui then return end
    Move(ui.activityButtonR5, page, width - 382, 0, 96, 26)
    Move(ui.ledgerButtonR5, page, width - 280, 0, 100, 26)
    Move(ui.contributionButton176, page, width - 174, 0, 174, 26)
    Move(ui.banner, page, 0, -34, width, 86)
    Move(ui.copyLucks, ui.banner, width - 120, -10, 108, 28)
    Move(ui.sync, ui.banner, width - 120, -46, 108, 28)
    if ui.contributionDetail then ui.contributionDetail:SetWidth(math.max(260, width - 210)) end
    if ui.bannerStatus then ui.bannerStatus:SetWidth(math.max(260, width - 210)) end

    local bodyY = 130
    local bodyHeight = math.max(300, height - bodyY)
    local listWidth = math.max(430, math.floor(width * 0.61))
    Move(ui.list, page, 0, -bodyY, listWidth, bodyHeight)
    Move(ui.detail, page, listWidth + 10, -bodyY, width - listWidth - 10, bodyHeight)
    EnsureTreasuryGoalScrollbar180(owner)
    Move(ui.newGoal, ui.list, listWidth - 132, -8, 112, 26)

    -- Funding goals are cards, not table rows. The old 56px contract forced the
    -- title, meta, amount, two action buttons and progress bar into nearly the
    -- same line. Give every card a dedicated title lane, metadata lane and bar.
    local rowHeight, rowPitch = 68, 76
    local capacity = math.max(3, math.min(ui.rowPoolCount180 or table.getn(ui.rows or {}), math.floor((bodyHeight - 82) / rowPitch)))
    ui.visibleRows180 = capacity
    local index, row
    for index = 1, table.getn(ui.rows or {}) do
        row = ui.rows[index]
        local rowWidth = math.max(392, listWidth - 38)
        if index <= capacity then
            Move(row, ui.list, 10, -44 - ((index - 1) * rowPitch), rowWidth, rowHeight)
        else
            row:Hide()
        end
        if row.goalIconH1 then Move(row.goalIconH1, row, 10, -10, 24, 24) end
        if row.name then
            row.name:ClearAllPoints()
            row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 42, -8)
            row.name:SetWidth(math.max(150, rowWidth - 190))
        end
        if row.meta then
            row.meta:ClearAllPoints()
            row.meta:SetPoint("TOPLEFT", row, "TOPLEFT", 42, -34)
            row.meta:SetWidth(math.max(150, rowWidth - 220))
        end
        if row.amount then
            row.amount:ClearAllPoints()
            row.amount:SetPoint("TOPRIGHT", row, "TOPRIGHT", -12, -34)
            row.amount:SetWidth(math.max(120, math.min(170, rowWidth - 260)))
        end
        if row.ledgerButtonH1 then Move(row.ledgerButtonH1, row, rowWidth - 132, -6, 58, 24) end
        if row.addButtonH1 then Move(row.addButtonH1, row, rowWidth - 68, -6, 58, 24) end
        local progressWidth = math.max(1, rowWidth - 54)
        row.otlTreasuryProgressWidth184 = progressWidth
        if row.progressBack then
            row.progressBack:ClearAllPoints()
            row.progressBack:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 42, 7)
            row.progressBack:SetWidth(progressWidth)
            row.progressBack:SetHeight(4)
        end
        if row.progress then
            row.progress:ClearAllPoints()
            row.progress:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 42, 7)
            row.progress:SetHeight(4)
            local goal = row.goal170
            local ratio = goal and (tonumber(goal.target) or 0) > 0
                and math.min(1, math.max(0, (tonumber(goal.current) or 0) / tonumber(goal.target))) or 0
            row.progress:SetWidth(math.max(1, math.floor(progressWidth * ratio)))
        end
    end
    if ui.status then Move(ui.status, ui.list, 12, -(bodyHeight - 28), listWidth - 42, 20) end
    Hide(ui.prev)
    Hide(ui.next)
    local goals = owner:GetTreasuryGoals170() or {}
    local maximum = math.max(0, table.getn(goals) - capacity)
    ui.goalMaximumOffset180 = maximum
    ui.offset = math.max(0, math.min(maximum, tonumber(ui.offset) or 0))
    Move(ui.goalScrollbar180, ui.list, listWidth - 19, -44, 14, math.max(120, (capacity * rowPitch) - 8))
    if ui.goalScrollbar180.SetScrollMetrics180 then
        ui.goalScrollbar180:SetScrollMetrics180(table.getn(goals), capacity, ui.offset)
    else
        SetScrollbar(ui.goalScrollbar180, ui.offset, maximum)
    end

    local detailWidth = ui.detail:GetWidth()
    if ui.serverTitle then ui.serverTitle:SetWidth(detailWidth - 24) end
    if ui.serverState then ui.serverState:SetWidth(detailWidth - 24) end
    if ui.detect then Size(ui.detect, detailWidth - 24, 26) end
    -- Top Contributors keeps the existing data/interaction model but receives a
    -- real full-width subtitle lane. This prevents long goal names from wrapping
    -- into the donor rows while Full Ledger occupies the header's right side.
    if ui.contributorSummaryH1 then
        local card = ui.contributorSummaryH1
        local cardWidth = math.max(220, detailWidth - 20)
        local donorCapacity = bodyHeight >= 430 and 5 or 3
        local previousDonorCapacity = ui.contributorVisibleRowsR25
        ui.contributorVisibleRowsR25 = donorCapacity
        if previousDonorCapacity and previousDonorCapacity ~= donorCapacity and owner.MarkLayoutDataRefresh180 then
            owner:MarkLayoutDataRefresh180("treasury")
        end
        local cardHeight = donorCapacity == 5 and 150 or 116
        Move(card, ui.detail, 10, -7, cardWidth, cardHeight)
        Move(ui.contributorIcon184, card, 8, -7, 17, 17)
        Move(ui.contributorTitleH1, card, 31, -8, math.max(90, cardWidth - 142), 18)
        Move(ui.fullLedgerH1, card, cardWidth - 100, -6, 90, 24)
        Move(ui.contributorGoalH1, card, 10, -31, cardWidth - 20, 18)
        local donorRow
        for index = 1, table.getn(ui.contributorRowsH1 or {}) do
            donorRow = ui.contributorRowsH1[index]
            Move(donorRow, card, 8, -48 - ((index - 1) * 17), cardWidth - 16, 16)
            Move(donorRow.rank, donorRow, 0, -1, 18, 16)
            Move(donorRow.name, donorRow, 21, -1, math.max(70, cardWidth - 126), 16)
            Move(donorRow.amount, donorRow, cardWidth - 96, -1, 78, 16)
            if index > donorCapacity then donorRow:Hide() end
        end
        Move(ui.contributorStatusH1, card, 8, -(donorCapacity == 5 and 133 or 99), cardWidth - 16, 16)

        -- Keep editor and change history visually separate below the donor card.
        -- Their data model/revision protection is unchanged; only hierarchy and
        -- spacing are adjusted so Recent Changes cannot read like editor text.
        local editorTop = cardHeight + 18
        local half = math.max(88, math.floor((cardWidth - 36) / 2))
        if ui.editorTitle then Move(ui.editorTitle, ui.detail, 12, -editorTop, cardWidth - 24, 20) end
        if ui.nameLabelR25 then Move(ui.nameLabelR25, ui.detail, 12, -(editorTop + 28), 54, 18) end
        if ui.nameEdit then Move(ui.nameEdit, ui.detail, 72, -(editorTop + 22), math.max(120, cardWidth - 84), 26) end
        if ui.currentLabelR25 then Move(ui.currentLabelR25, ui.detail, 12, -(editorTop + 59), half, 18) end
        if ui.targetLabelR25 then Move(ui.targetLabelR25, ui.detail, 24 + half, -(editorTop + 59), half, 18) end
        if ui.currentEdit then Move(ui.currentEdit, ui.detail, 12, -(editorTop + 75), half, 26) end
        if ui.targetEdit then Move(ui.targetEdit, ui.detail, 24 + half, -(editorTop + 75), half, 26) end
        if ui.save then Move(ui.save, ui.detail, 12, -(editorTop + 111), math.min(152, cardWidth - 104), 28) end
        if ui.delete then Move(ui.delete, ui.detail, cardWidth - 88, -(editorTop + 111), 76, 28) end
        local historyTop = editorTop + 151
        if ui.recentChangesTitleR25 then Move(ui.recentChangesTitleR25, ui.detail, 12, -historyTop, cardWidth - 24, 18) end
        for index = 1, table.getn(ui.history or {}) do
            Move(ui.history[index], ui.detail, 12, -(historyTop + 22 + ((index - 1) * 22)), cardWidth - 24, 20)
        end
    end
    page.otlNativeLayout = true
end

local function LayoutActivity(owner, page, width, height)
    SuppressLegacy(page.otlSemanticRefs)
    local cards = {
        owner.ui.activityCards and owner.ui.activityCards.today,
        owner.ui.activityCards and owner.ui.activityCards.week,
        owner.ui.activityCards and owner.ui.activityCards.all,
        owner.ui.activityCards and owner.ui.activityCards.average,
    }
    local gap = 8
    local cardWidth = math.floor((width - (gap * 3)) / 4)
    local index
    for index = 1, table.getn(cards) do
        Move(cards[index], page, (index - 1) * (cardWidth + gap), 0, cardWidth, 78)
    end

    local footerHeight = 38
    local bodyY = 88
    local availableHeight = math.max(370, height - bodyY - footerHeight - 8)
    local insightHeight = math.min(72, math.max(62, math.floor(availableHeight * 0.16)))
    local heatHeight = math.min(392, math.max(300, availableHeight - insightHeight - gap))
    local bodyContentHeight = heatHeight + gap + insightHeight
    local heatWidth = math.max(470, math.floor(width * 0.625))
    heatWidth = math.min(heatWidth, width - 270)
    local compositionWidth = math.max(260, width - heatWidth - gap)

    Move(owner.ui.activityHeatmap180, page, 0, -bodyY, heatWidth, heatHeight)
    Move(owner.ui.activityComposition180, page, heatWidth + gap, -bodyY,
        compositionWidth, bodyContentHeight)

    -- The heatmap frame follows the actual table rather than stretching to the
    -- bottom of ContentHost. Cell geometry expands safely with the window.
    local gridLeft = 68
    local gridRight = 12
    local gridWidth = math.max(360, heatWidth - gridLeft - gridRight)
    local cellGap = 5
    local cellWidth = math.floor((gridWidth - (cellGap * 7)) / 8)
    local gridTop = 56
    local gridBottom = 48
    local rowGap = 3
    local rowHeight = math.floor((heatHeight - gridTop - gridBottom - (rowGap * 6)) / 7)
    rowHeight = math.max(28, math.min(42, rowHeight))
    local hourIndex
    for hourIndex = 1, table.getn(owner.ui.heatmapHourLabels180 or {}) do
        Move(owner.ui.heatmapHourLabels180[hourIndex], owner.ui.activityHeatmap180,
            gridLeft + ((hourIndex - 1) * (cellWidth + cellGap)), -35, cellWidth, 18)
    end
    local dayIndex, weekday, slot
    local weekdayOrder = { 1, 2, 3, 4, 5, 6, 0 }
    for dayIndex = 1, 7 do
        Move(owner.ui.heatmapDayLabels180 and owner.ui.heatmapDayLabels180[dayIndex],
            owner.ui.activityHeatmap180, 12,
            -(gridTop + ((dayIndex - 1) * (rowHeight + rowGap)) + 7), 48, 18)
        weekday = weekdayOrder[dayIndex]
        for slot = 0, 7 do
            Move(owner.ui.heatmapCells and owner.ui.heatmapCells[weekday] and owner.ui.heatmapCells[weekday][slot],
                owner.ui.activityHeatmap180,
                gridLeft + (slot * (cellWidth + cellGap)),
                -(gridTop + ((dayIndex - 1) * (rowHeight + rowGap))),
                cellWidth, rowHeight)
        end
    end

    Move(owner.ui.activityHeatmapLegend180, owner.ui.activityHeatmap180,
        12, -(heatHeight - 24), heatWidth - 24, 18)

    local insightWidth = math.floor((heatWidth - (gap * 2)) / 3)
    for index = 1, table.getn(owner.ui.activityInsightCards180 or {}) do
        local card = owner.ui.activityInsightCards180[index]
        Move(card, page, (index - 1) * (insightWidth + gap),
            -(bodyY + heatHeight + gap), insightWidth, insightHeight)
        if card.title then card.title:SetWidth(insightWidth - 20) end
        if card.value then card.value:SetWidth(insightWidth - 20) end
    end
    Hide(owner.ui.activityInsightPanelR4)

    local composition = owner.ui.activityComposition180
    local innerWidth = math.max(210, compositionWidth - 20)
    local classHeight = math.max(184, math.floor((bodyContentHeight - 48) * 0.54))
    local levelHeight = math.max(104, math.floor((bodyContentHeight - 48) * 0.27))
    local onlineHeight = math.max(74, bodyContentHeight - 40 - classHeight - levelHeight - (gap * 2))
    Move(owner.ui.activityClassPanel180, composition, 10, -36, innerWidth, classHeight)
    Move(owner.ui.activityLevelPanel180, composition, 10, -(36 + classHeight + gap), innerWidth, levelHeight)
    Move(owner.ui.activityOnlinePanel180, composition, 10,
        -(36 + classHeight + gap + levelHeight + gap), innerWidth, onlineHeight)

    local function LayoutBarRows(panel, rowCount, headerHeight)
        if not panel or not panel.rows then return end
        local panelWidth = panel:GetWidth() or innerWidth
        local panelHeight = panel:GetHeight() or 100
        local rowArea = math.max(1, panelHeight - headerHeight - 6)
        local rowHeightLocal = math.max(14, math.floor(rowArea / rowCount))
        local barX = math.max(72, math.floor(panelWidth * 0.34))
        local valueWidth = 28
        local barWidth = math.max(42, panelWidth - barX - valueWidth - 18)
        local rowIndex
        for rowIndex = 1, rowCount do
            local row = panel.rows[rowIndex]
            Move(row, panel, 10, -(headerHeight + ((rowIndex - 1) * rowHeightLocal)),
                panelWidth - 20, rowHeightLocal)
            if row.label then
                row.label:ClearAllPoints()
                if row.classIcon then
                    row.classIcon:ClearAllPoints()
                    row.classIcon:SetPoint("LEFT", row, "LEFT", 0, 0)
                    row.classIcon:SetWidth(15)
                    row.classIcon:SetHeight(15)
                    row.label:SetPoint("LEFT", row, "LEFT", 19, 0)
                    row.label:SetWidth(math.max(24, barX - 27))
                else
                    row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
                    row.label:SetWidth(barX - 8)
                end
            end
            if row.back then
                row.back:ClearAllPoints()
                row.back:SetPoint("LEFT", row, "LEFT", barX, 0)
                row.back:SetWidth(barWidth)
            end
            if row.fill then
                row.fill:ClearAllPoints()
                row.fill:SetPoint("LEFT", row, "LEFT", barX, 0)
                row.fill:SetWidth(math.max(1, math.floor(barWidth * math.max(0, math.min(1, tonumber(row.otlRatio180) or 0)))))
            end
            if row.value then
                row.value:ClearAllPoints()
                row.value:SetPoint("RIGHT", row, "RIGHT", 0, 0)
                row.value:SetWidth(valueWidth)
            end
        end
    end
    LayoutBarRows(owner.ui.activityClassPanel180, 9, 27)
    LayoutBarRows(owner.ui.activityLevelPanel180, 4, 29)

    local online = owner.ui.activityOnlinePanel180
    if online then
        if online.title then online.title:SetWidth(innerWidth - 28) end
        local half = math.floor(innerWidth / 2)
        if online.allianceIcon then
            online.allianceIcon:ClearAllPoints()
            online.allianceIcon:SetPoint("TOPLEFT", online, "TOPLEFT", 10, -26)
        end
        if online.hordeIcon then
            online.hordeIcon:ClearAllPoints()
            online.hordeIcon:SetPoint("TOPLEFT", online, "TOPLEFT", half + 2, -26)
        end
        if online.value then Move(online.value, online, 34, -27, math.max(46, half - 38), 22) end
        if online.level then Move(online.level, online, half + 26, -27, math.max(46, innerWidth - half - 34), 22) end
        if online.note then Move(online.note, online, 10, -(onlineHeight - 22), innerWidth - 20, 18) end
    end

    Move(owner.ui.activitySync156, page, width - 378, -(height - 30), 178, 28)
    Move(owner.ui.activitySummaryButton, page, width - 190, -(height - 30), 190, 28)
    page.otlActivityBodyHeight180 = bodyContentHeight
    page.otlNativeLayout = true
end


local function OverviewEventColor180(owner, kind)
    if kind == "JOIN" or kind == "RETURN" then return owner.colors.green end
    if kind == "LEAVE" then return owner.colors.red end
    if kind == "RANK" then return owner.colors.gold end
    if kind == "LEVEL" then return owner.colors.blue end
    if kind == "NOTE" then return owner.colors.grey end
    return owner.colors.white
end

local function CreateOverviewEventRow180(owner, section, index)
    local row = CreateFrame("Button", nil, section)
    row:SetHeight(23)
    row:EnableMouse(true)
    row:SetScript("OnClick", function() owner:ShowPage("history") end)
    row:SetScript("OnEnter", function()
        if this.highlight then this.highlight:Show() end
    end)
    row:SetScript("OnLeave", function()
        if this.highlight then this.highlight:Hide() end
    end)
    row.highlight = row:CreateTexture(nil, "BACKGROUND")
    row.highlight:SetTexture(0.23, 0.15, 0.055, 0.42)
    row.highlight:SetAllPoints(row)
    row.highlight:Hide()
    local function Text(width, justify)
        local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetHeight(18)
        text:SetWidth(width)
        text:SetJustifyH(justify or "LEFT")
        return text
    end
    row.time = Text(88, "LEFT")
    row.kind = Text(74, "LEFT")
    row.name = Text(116, "LEFT")
    row.detail = Text(300, "LEFT")
    SetWheel(row, function(delta)
        local minimum, maximum = section.scrollbar:GetMinMaxValues()
        section.scrollbar:SetValue(math.max(minimum, math.min(maximum,
            (tonumber(section.offset) or 0) - ((tonumber(delta) or 0) * 2))))
    end)
    return row
end

local function EnsureOverviewNative180(owner, page)
    local ui = owner.ui
    if ui.overviewActivitySection180 then return end
    local section = UI:Card(page, 620, 180, "Recent Important Activity")
    section.rows = {}
    section.offset = 0
    section.visibleRows = 1
    section.empty = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    section.empty:SetText("No recorded important activity.")
    section.empty:SetTextColor(0.48, 0.48, 0.46)
    section.empty:SetJustifyH("CENTER")
    section.empty:SetPoint("CENTER", section, "CENTER", 0, -4)
    section.scrollbar = UI:Scrollbar(section, 120, function(value)
        section.offset = math.floor((tonumber(value) or 0) + 0.5)
        if owner.RefreshOverviewNativeRows180 then owner:RefreshOverviewNativeRows180() end
    end)
    SetWheel(section, function(delta)
        local minimum, maximum = section.scrollbar:GetMinMaxValues()
        section.scrollbar:SetValue(math.max(minimum, math.min(maximum,
            (tonumber(section.offset) or 0) - ((tonumber(delta) or 0) * 2))))
    end)
    ui.overviewActivitySection180 = section
    ui.overviewActivityScrollbar180 = section.scrollbar

    local clickable = {
        { ui.overviewCards and ui.overviewCards.members, "roster" },
        { ui.overviewCards and ui.overviewCards.online, "roster" },
        { ui.overviewCards and ui.overviewCards.unread, "history" },
        { ui.overviewCards and ui.overviewCards.inactive, "inactive" },
        { ui.overviewPulseCards and ui.overviewPulseCards.requests, "pve" },
        { ui.overviewPulseCards and ui.overviewPulseCards.pending, "pve" },
    }
    local index
    for index = 1, table.getn(clickable) do
        local card, key = clickable[index][1], clickable[index][2]
        if card and not card.otlOverviewNavigation180 then
            card.otlOverviewNavigation180 = key
            card:EnableMouse(true)
            card:SetScript("OnMouseDown", function() owner:ShowPage(this.otlOverviewNavigation180) end)
        end
    end
end

function OTLGM:RefreshOverviewNativeRows180()
    local section = self.ui and self.ui.overviewActivitySection180
    if not section then return end
    local db = self:GetGuildDB()
    local list = {}
    local index, eventInfo
    for index = 1, table.getn(db and db.log or {}) do
        eventInfo = db.log[index]
        if eventInfo and eventInfo.kind ~= "BASELINE" and not eventInfo.hiddenLegacyLevel then
            table.insert(list, eventInfo)
        end
    end
    local visible = math.max(1, tonumber(section.visibleRows) or 1)
    local maximum = math.max(0, table.getn(list) - visible)
    section.offset = math.max(0, math.min(maximum, tonumber(section.offset) or 0))
    if section.scrollbar.SetScrollMetrics180 then
        section.scrollbar:SetScrollMetrics180(table.getn(list), visible, section.offset)
    else
        SetScrollbar(section.scrollbar, section.offset, maximum)
    end
    if table.getn(list) == 0 then section.empty:Show() else section.empty:Hide() end
    for index = 1, table.getn(section.rows) do
        local row = section.rows[index]
        eventInfo = list[section.offset + index]
        if index <= visible and eventInfo then
            local kind = tostring(eventInfo.kind or "EVENT")
            row.eventInfo = eventInfo
            row.time:SetText(self.colors.grey .. date("%d/%m %H:%M", tonumber(eventInfo.ts) or self:Now()) .. self.colors.reset)
            row.kind:SetText(OverviewEventColor180(self, kind) .. kind .. self.colors.reset)
            local nameColor = eventInfo.class and eventInfo.class ~= "" and self:GetClassColor(eventInfo.class) or self.colors.white
            row.name:SetText(nameColor .. tostring(eventInfo.name or "") .. self.colors.reset)
            local detail = tostring(eventInfo.detail or "")
            if eventInfo.actor and eventInfo.actor ~= "" then detail = detail .. "  by " .. tostring(eventInfo.actor) end
            row.detail:SetText(detail)
            row:Show()
        else
            row.eventInfo = nil
            row:Hide()
        end
    end
end

local function LayoutOverview(owner, page, width, height)
    SuppressLegacy(page.otlSemanticRefs)
    EnsureOverviewNative180(owner, page)
    local first = { "members", "online", "joined", "inactive", "unread" }
    local second = { "level60", "requests", "pending", "addon" }
    local gap = 8
    local index
    local firstWidth = math.floor((width - (gap * 4)) / 5)
    for index = 1, table.getn(first) do
        Move(owner.ui.overviewCards[first[index]], page,
            (index - 1) * (firstWidth + gap), 0, firstWidth, 76)
    end
    local secondWidth = math.floor((width - (gap * 3)) / 4)
    for index = 1, table.getn(second) do
        Move(owner.ui.overviewPulseCards[second[index]], page,
            (index - 1) * (secondWidth + gap), -86, secondWidth, 68)
    end
    local summary = owner.ui.overviewGrowth and owner.ui.overviewGrowth:GetParent()
    Move(summary, page, 0, -164, width, 78)
    if owner.ui.overviewChanges then owner.ui.overviewChanges:SetWidth(width - 276) end
    if owner.ui.overviewFreshness then owner.ui.overviewFreshness:SetWidth(width - 28) end

    Hide(owner.ui.overviewRecentLegacyTitle180)
    for index = 1, table.getn(owner.ui.overviewEvents or {}) do Hide(owner.ui.overviewEvents[index]) end
    local footerHeight = 38
    local sectionY = 252
    local sectionHeight = math.max(116, height - sectionY - footerHeight - 8)
    local section = owner.ui.overviewActivitySection180
    Move(section, page, 0, -sectionY, width, sectionHeight)
    if section.title then section.title:SetWidth(width - 42) end
    local rowTop = 34
    local rowHeight = 23
    local capacity = math.max(3, math.floor((sectionHeight - rowTop - 10) / rowHeight))
    while table.getn(section.rows) < capacity do
        table.insert(section.rows, CreateOverviewEventRow180(owner, section, table.getn(section.rows) + 1))
    end
    section.visibleRows = capacity
    local rowWidth = width - 34
    for index = 1, table.getn(section.rows) do
        local row = section.rows[index]
        if index <= capacity then
            Move(row, section, 10, -(rowTop + ((index - 1) * rowHeight)), rowWidth, rowHeight)
            Move(row.time, row, 0, -3, math.min(92, math.floor(rowWidth * 0.17)), 18)
            local timeWidth = row.time:GetWidth()
            Move(row.kind, row, timeWidth + 6, -3, math.min(76, math.floor(rowWidth * 0.13)), 18)
            local kindWidth = row.kind:GetWidth()
            Move(row.name, row, timeWidth + kindWidth + 12, -3, math.min(126, math.floor(rowWidth * 0.20)), 18)
            local nameWidth = row.name:GetWidth()
            Move(row.detail, row, timeWidth + kindWidth + nameWidth + 18, -3,
                math.max(120, rowWidth - timeWidth - kindWidth - nameWidth - 18), 18)
        else row:Hide() end
    end
    Move(section.scrollbar, section, width - 17, -30, 14, math.max(48, sectionHeight - 38))
    section.empty:SetWidth(math.max(120, width - 40))
    owner:RefreshOverviewNativeRows180()

    local footerY = -(height - 30)
    Move(owner.ui.overviewAnnouncementButton, page, 0, footerY, 126, 30)
    Move(owner.ui.overviewRaidButton, page, 136, footerY, 116, 30)
    Move(owner.ui.overviewRecruitButton, page, 262, footerY, 120, 30)
    Move(owner.ui.overviewSummaryButton, page, width - 166, footerY, 166, 30)
    page.otlNativeLayout = true
end

local function SendGuildWelcomeR32(owner)
    if not SendChatMessage then
        if owner.ShowToast then owner:ShowToast("Guild chat is unavailable on this client.", "error") end
        return false
    end
    local ok, problem = pcall(SendChatMessage, "Welcome!", "GUILD")
    if not ok then
        if owner.ShowToast then owner:ShowToast("Welcome message could not be sent: " .. tostring(problem or "client rejected it"), "error") end
        return false
    end
    if owner.ShowToast then owner:ShowToast("Welcome! sent to guild chat.", "success") end
    return true
end

local function EnsureRecruitmentR32Controls(owner, page)
    if not owner.ui.recruitmentWelcomeR32 then
        owner.ui.recruitmentWelcomeR32 = UI:Button(page, "Welcome!", 86, 28, function() SendGuildWelcomeR32(owner) end, "utility")
        owner.ui.recruitmentWelcomeR32.otlTooltipTitle = "Quick guild welcome"
        owner.ui.recruitmentWelcomeR32.otlTooltip = "Sends exactly: Welcome! to guild chat. It does not affect recruitment cooldowns or the Send Next message order."
    end
    if not owner.ui.recruitmentHelpR32 and UI.HelpIcon then
        owner.ui.recruitmentHelpR32 = UI:ContextHelpIcon(page, "RECRUITMENT")
    end
end

local function EnsureRecruitmentComposerPanelR25(owner, page)
    local ui = owner.ui
    if ui.recruitmentComposerPanelR25 then return ui.recruitmentComposerPanelR25 end
    local panel = UI:Card(page, 680, 210, "Recruitment Composer")
    panel:SetFrameLevel(page:GetFrameLevel())
    panel:EnableMouse(false)
    -- Keep the card as a border/title owner but draw its fill on BACKGROUND so
    -- legacy page FontStrings (counter/status labels) remain above it.
    if panel.SetBackdropColor then panel:SetBackdropColor(0, 0, 0, 0) end
    panel.backingR25 = panel:CreateTexture(nil, "BACKGROUND")
    panel.backingR25:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
    panel.backingR25:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 4)
    panel.backingR25:SetTexture(C.card[1], C.card[2], C.card[3], 0.72)
    panel.helpR25 = UI.Text(panel, "Edit the message, choose where it should go, then open it in chat or send it directly.", "GameFontNormalSmall", "LEFT")
    panel.helpR25:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -30)
    panel.helpR25:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    panel.helpR25:SetWidth(620)
    panel.separatorR25 = panel:CreateTexture(nil, "ARTWORK")
    panel.separatorR25:SetTexture(C.goldDark[1], C.goldDark[2], C.goldDark[3], 0.52)
    panel.separatorR25:SetHeight(1)
    ui.recruitmentComposerPanelR25 = panel
    return panel
end

local function LayoutRecruitment(owner, page, width, height)
    SuppressLegacy(page.otlSemanticRefs)
    local ui = owner.ui
    local margin = 10
    local contentWidth = math.max(720, width - (margin * 2))
    local compact = height < 540
    local medium = height >= 540 and height < 660
    local statusHeight = compact and 48 or (medium and 54 or 60)
    local rotationY = compact and 54 or (medium and 62 or 70)
    -- Six fixed presets now include two alternating raid-recruitment options. Keep
    -- compact/medium rows intentionally tight so the editor and action footer do
    -- not get pushed outside ContentHost at the minimum supported size.
    local rotationGap = compact and 2 or (medium and 3 or 6)
    local rotationHeight = compact and 28 or (medium and 30 or 40)
    local order = { "BASE1", "RAID1", "BASE2", "RAID2", "GUILDINFO", "ADDONINFO" }
    -- BuildRecruitmentPage's status card was authored at 310px. Letting the
    -- responsive layout shrink it to 276 clipped the channel control and the
    -- elapsed/meta text at Compact scale. Keep the known-safe width; the left
    -- toolbar still has ample room at the minimum ContentHost width.
    local statusWidth = math.min(340, math.max(310, math.floor(contentWidth * 0.34)))
    Move(ui.worldRecruitmentCard, page, margin + contentWidth - statusWidth, -2, statusWidth, statusHeight)
    if ui.worldRecruitmentCard then
        local card = ui.worldRecruitmentCard
        -- The 48px compact card intentionally omits the tertiary metadata row
        -- instead of drawing it outside the card and over the first preset.
        if card.meta then if compact then card.meta:Hide() else card.meta:Show() end end
        if card.autoText then if compact then card.autoText:Hide() else card.autoText:Show() end end
        if card.detail then card.detail:SetWidth(math.max(128, statusWidth - 156)) end
    end
    local toolbarWidth = math.max(250, contentWidth - statusWidth - 18)
    Move(ui.recruitmentRotationTitle180, page, margin, -8, math.max(120, toolbarWidth - 150), 20)
    Move(ui.recentWhisperButton176, page, margin + toolbarWidth - 150, -4, 150, 28)
    UI:SetText(ui.recentWhisperButton176, "Recent Contacts")
    local index
    for index = 1, table.getn(order) do
        local row = ui.recruitmentPresetRows180 and ui.recruitmentPresetRows180[order[index]]
        if not row then
            local select = ui.recruitPresetButtons and ui.recruitPresetButtons[order[index]]
            row = select and select:GetParent() or nil
        end
        if row then
            Move(row, page, margin, -(rotationY + ((index - 1) * (rotationHeight + rotationGap))),
                contentWidth, rotationHeight)
            local select = ui.recruitPresetButtons and ui.recruitPresetButtons[order[index]]
            local badge = ui.recruitPresetBadges170 and ui.recruitPresetBadges170[order[index]]
            local send = ui.presetSendButtons and ui.presetSendButtons[order[index]]
            local edit = ui.presetEditButtons180 and ui.presetEditButtons180[order[index]]
            local buttonY = compact and -2 or -6
            local buttonHeight = compact and 26 or 28
            Move(select, row, 8, buttonY, 96, buttonHeight)
            Move(send, row, contentWidth - 126, buttonY, 116, buttonHeight)
            if edit then Move(edit, row, contentWidth - 210, buttonY, 76, buttonHeight) end
            if badge then
                Move(badge, row, 112, compact and -2 or -5, math.max(100, contentWidth - 360), 14)
            end
            local preview = ui.recruitPresetPreviews170 and ui.recruitPresetPreviews170[order[index]]
            if preview then
                -- Preview begins at x=112; leave an explicit gutter before Edit/Send.
                -- Compact rows also move the second line upward so no glyph is
                -- rendered into the following preset row.
                local previewWidth = math.max(210, contentWidth - (edit and 344 or 252))
                Move(preview, row, 112, compact and -16 or -21, previewWidth, 14)
                preview.otlPreviewChars180 = math.max(34, math.min(88, math.floor(previewWidth / 5.2)))
                if owner.GetRecruitmentPreset170 and owner.GetRecruitmentPreview then
                    local preset = owner:GetRecruitmentPreset170(order[index])
                    if preset then preview:SetText(owner:GetRecruitmentPreview(preset.text, preview.otlPreviewChars180)) end
                end
            end
        end
    end
    local slotsTitleY = rotationY + (table.getn(order) * (rotationHeight + rotationGap)) + 2
    Move(ui.recruitmentCustomTitle180, page, margin, -slotsTitleY, 220, 20)
    local slotY = slotsTitleY + 24
    local slotWidth = math.floor((contentWidth - 24) / 3)
    for index = 1, 3 do
        Move(ui.customSlotButtons["CUSTOM" .. tostring(index)], page,
            margin + ((index - 1) * (slotWidth + 12)), -slotY, slotWidth, 36)
    end
    local stateY = slotY + 44
    Move(ui.recruitmentState, page, margin, -stateY, contentWidth - 390, 20)
    Move(ui.recruitRotationLabel170, page, margin + contentWidth - 380, -stateY, 132, 20)
    for index = 1, 2 do
        Move(ui.saveCopyButtons[index], page, margin + contentWidth - 238 + ((index - 1) * 42), -(stateY - 4), 34, 25)
    end
    Move(ui.workingTargetText, page, margin + contentWidth - 340, -(stateY + 26), 340, 20)
    local composerLabelY = stateY + 28
    Move(ui.recruitmentComposerLabel180, page, margin, -composerLabelY, 140, 20)
    local actionHeight = 68
    local footerHeight = 28
    local actionY = height - actionHeight - footerHeight - 10
    local editorY = composerLabelY + 22
    local editorHeight = math.max(56, actionY - editorY - 8)
    Move(ui.recruitmentEdit, page, margin, -editorY, contentWidth, editorHeight)
    Move(ui.recruitmentCount, page, margin + contentWidth - 92, -(editorY + editorHeight - 22), 82, 20)
    local actionsY = actionY
    Move(ui.recruitmentSlotLabel180, page, margin, -(actionsY + 7), 112, 20)
    Move(ui.customNameEdit, page, margin + 120, -actionsY, 174, 28)
    Move(ui.renameCustomButton, page, margin + 302, -actionsY, 74, 28)
    local rightX = margin + contentWidth - 300
    Move(ui.customWorldButton, page, rightX, -actionsY, 62, 28)
    Move(ui.customGuildButton, page, rightX + 68, -actionsY, 62, 28)
    Move(ui.saveSlotButton, page, rightX + 140, -actionsY, 82, 28)
    Move(ui.clearSlotButton, page, rightX + 228, -actionsY, 58, 28)
    Move(ui.workingTargetText, page, margin, -(actionsY + 42), math.max(240, contentWidth - 210), 20)
    Move(ui.openRecruitmentChatButton180, page, margin + contentWidth - 198, -(actionsY + 34), 112, 28)
    Move(ui.sendCurrentButton, page, margin + contentWidth - 78, -(actionsY + 34), 78, 28)
    Move(ui.sendNextButton, page, margin, -(height - footerHeight), 150, 26)
    Move(ui.recruitReadyText, page, margin + 164, -(height - footerHeight + 6), contentWidth - 164, 20)
    page.otlRecruitmentFlow180 = {
        status = statusHeight, rotation = rotationY, slots = slotY,
        editorTop = editorY, editorHeight = editorHeight, actions = actionsY,
        actionBottom = actionsY + 28, footerTop = height - footerHeight,
        compact = compact, medium = medium,
    }
    page.otlNativeLayout = true
end

local PreviousLayoutRecruitment184 = LayoutRecruitment
LayoutRecruitment = function(owner, page, width, height)
    EnsureRecruitmentR32Controls(owner, page)
    -- width/height are the usable ContentHost dimensions, not the whole addon
    -- window. The old 900x620 gate kept the wide composition disabled at normal
    -- live sizes even though it fits safely much earlier.
    if width < 720 or height < 560 then
        PreviousLayoutRecruitment184(owner, page, width, height)
        local ui = owner.ui
        local composer = EnsureRecruitmentComposerPanelR25(owner, page)
        local flow = page.otlRecruitmentFlow180 or {}
        local top = math.max(290, tonumber(flow.editorTop) and (tonumber(flow.editorTop) - 30) or 300)
        local bottom = math.min(height - 4, tonumber(flow.footerTop) and (tonumber(flow.footerTop) + 26) or height - 4)
        Move(composer, page, 6, -top, math.max(320, width - 12), math.max(180, bottom - top))
        if composer.helpR25 then composer.helpR25:SetWidth(math.max(240, width - 44)) end
        composer:Show()
        if owner.ui.recruitmentHelpR32 then Move(owner.ui.recruitmentHelpR32, page, math.max(152, width - 28), -4, 22, 22) end
        if owner.ui.recruitmentWelcomeR32 then
            local flowR32 = page.otlRecruitmentFlow180 or {}
            local yR32 = tonumber(flowR32.footerTop) or (height - 28)
            Move(owner.ui.recruitmentWelcomeR32, page, math.max(166, width - 292), -yR32, 86, 28)
        end
        return
    end
    SuppressLegacy(page.otlSemanticRefs)
    local ui = owner.ui
    local margin, gap = 10, 12
    local contentWidth = width - (margin * 2)
    local leftWidth = math.floor(contentWidth * 0.60)
    local rightWidth = contentWidth - leftWidth - gap
    local rightX = margin + leftWidth + gap
    local order = { "BASE1", "RAID1", "BASE2", "RAID2", "GUILDINFO", "ADDONINFO" }

    Move(ui.recruitmentRotationTitle180, page, margin, -8, math.max(150, leftWidth - 196), 20)
    if ui.recruitmentHelpR32 then Move(ui.recruitmentHelpR32, page, margin + leftWidth - 178, -6, 22, 22) end
    Move(ui.recentWhisperButton176, page, margin + leftWidth - 150, -4, 150, 28)
    UI:SetText(ui.recentWhisperButton176, "Recent Contacts")
    Move(ui.worldRecruitmentCard, page, rightX, -2, rightWidth, 76)
    if ui.worldRecruitmentCard then
        local card = ui.worldRecruitmentCard
        if card.meta then card.meta:Show() end
        if card.autoText then card.autoText:Show() end
        if card.detail then card.detail:SetWidth(math.max(110, rightWidth - 156)) end
    end

    local rowY, rowHeight, rowGap = 38, 38, 4
    local index
    for index = 1, table.getn(order) do
        local row = ui.recruitmentPresetRows180 and ui.recruitmentPresetRows180[order[index]]
        if not row then
            local select = ui.recruitPresetButtons and ui.recruitPresetButtons[order[index]]
            row = select and select:GetParent() or nil
        end
        if row then
            Move(row, page, margin, -(rowY + ((index - 1) * (rowHeight + rowGap))), leftWidth, rowHeight)
            local select = ui.recruitPresetButtons and ui.recruitPresetButtons[order[index]]
            local badge = ui.recruitPresetBadges170 and ui.recruitPresetBadges170[order[index]]
            local send = ui.presetSendButtons and ui.presetSendButtons[order[index]]
            local edit = ui.presetEditButtons180 and ui.presetEditButtons180[order[index]]
            Move(select, row, 8, -5, 96, 28)
            Move(send, row, leftWidth - 126, -5, 116, 28)
            if edit then Move(edit, row, leftWidth - 210, -5, 76, 28) end
            if badge then Move(badge, row, 112, -3, math.max(100, leftWidth - 360), 14) end
            local preview = ui.recruitPresetPreviews170 and ui.recruitPresetPreviews170[order[index]]
            if preview then
                local previewWidth = math.max(170, leftWidth - (edit and 344 or 252))
                Move(preview, row, 112, -20, previewWidth, 14)
                preview.otlPreviewChars180 = math.max(32, math.min(80, math.floor(previewWidth / 5.2)))
                if owner.GetRecruitmentPreset170 and owner.GetRecruitmentPreview then
                    local preset = owner:GetRecruitmentPreset170(order[index])
                    if preset then preview:SetText(owner:GetRecruitmentPreview(preset.text, preview.otlPreviewChars180)) end
                end
            end
        end
    end

    Move(ui.recruitmentCustomTitle180, page, rightX, -86, rightWidth, 20)
    for index = 1, 3 do
        Move(ui.customSlotButtons["CUSTOM" .. tostring(index)], page, rightX, -110 - ((index - 1) * 48), rightWidth, 42)
    end

    -- Keep rotation-replacement controls fully inside the left column and below
    -- the last right-hand saved slot. The previous wide draft let button B cross
    -- the column boundary and touch Custom Slot 3 at the smallest wide height.
    local stateY = 300
    local leftRight = margin + leftWidth
    Move(ui.recruitmentState, page, margin, -stateY, math.max(180, leftWidth - 238), 20)
    Move(ui.recruitRotationLabel170, page, leftRight - 224, -stateY, 132, 20)
    Move(ui.saveCopyButtons[1], page, leftRight - 82, -(stateY - 4), 34, 25)
    Move(ui.saveCopyButtons[2], page, leftRight - 40, -(stateY - 4), 34, 25)

    -- r25: the lower half is one bounded Composer panel rather than a legacy
    -- edit box stretched into whatever vertical space remains. This preserves
    -- the successful two-column upper composition while giving Working Copy,
    -- custom-slot controls, destination and send actions one visual hierarchy.
    local composer = EnsureRecruitmentComposerPanelR25(owner, page)
    local composerY = 326
    local composerHeight = math.min(248, math.max(206, height - composerY - 10))
    Move(composer, page, margin, -composerY, contentWidth, composerHeight)
    if composer.helpR25 then composer.helpR25:SetWidth(math.max(240, contentWidth - 32)) end
    if composer.separatorR25 then
        composer.separatorR25:ClearAllPoints()
        composer.separatorR25:SetPoint("BOTTOMLEFT", composer, "BOTTOMLEFT", 12, 48)
        composer.separatorR25:SetPoint("BOTTOMRIGHT", composer, "BOTTOMRIGHT", -12, 48)
    end

    Move(ui.recruitmentComposerLabel180, page, margin + 16, -(composerY + 50), 120, 20)
    local editorY = composerY + 68
    local footerBand = 82
    local editorHeight = math.min(126, math.max(72, composerHeight - 68 - footerBand))
    Move(ui.recruitmentEdit, page, margin + 14, -editorY, contentWidth - 28, editorHeight)
    Move(ui.recruitmentCount, page, margin + contentWidth - 100, -(editorY + editorHeight - 22), 82, 20)

    local slotY = editorY + editorHeight + 8
    Move(ui.recruitmentSlotLabel180, page, margin + 16, -(slotY + 7), 108, 20)
    Move(ui.customNameEdit, page, margin + 126, -slotY, 160, 28)
    Move(ui.renameCustomButton, page, margin + 294, -slotY, 72, 28)
    Move(ui.saveSlotButton, page, margin + 374, -slotY, 82, 28)
    Move(ui.clearSlotButton, page, margin + 464, -slotY, 58, 28)

    local destinationX = margin + contentWidth - 138
    Move(ui.customWorldButton, page, destinationX, -slotY, 62, 28)
    Move(ui.customGuildButton, page, destinationX + 68, -slotY, 62, 28)
    local footerY = composerY + composerHeight - 40
    Move(ui.sendNextButton, page, margin + 14, -footerY, 150, 28)
    Move(ui.recruitReadyText, page, margin + 174, -(footerY + 6), math.max(190, contentWidth - 390), 20)
    Move(ui.workingTargetText, page, margin + 174, -(footerY + 24), math.max(190, contentWidth - 390), 18)
    Move(ui.recruitmentWelcomeR32, page, margin + contentWidth - 292, -footerY, 86, 28)
    Move(ui.openRecruitmentChatButton180, page, margin + contentWidth - 198, -footerY, 112, 28)
    Move(ui.sendCurrentButton, page, margin + contentWidth - 78, -footerY, 78, 28)

    page.otlRecruitmentFlow180 = {
        status = 76, rotation = rowY, slots = 110, editorTop = editorY, editorHeight = editorHeight,
        actions = slotY, actionBottom = composerY + composerHeight, footerTop = footerY,
        compact = false, medium = false, wide184 = true, composerR25 = true,
    }
    page.otlNativeLayout = true
end

local function RecentContactShortName180(name)
    return string.gsub(tostring(name or ""), "%-.*$", "")
end

local function RecentContactMember180(owner, name)
    if not owner or not name then return nil end
    return owner.GetMember and owner:GetMember(RecentContactShortName180(name)) or nil
end

function OTLGM:RemoveRecentRecruitmentContact180(name)
    self.runtime = self.runtime or {}
    local shortName = RecentContactShortName180(name)
    if shortName == "" then return false end
    local key = string.lower(shortName)
    local source = self.runtime.recentWhispers176 or {}
    local filtered = {}
    local removed = false
    local index, entry
    for index = 1, table.getn(source) do
        entry = source[index]
        if entry and string.lower(RecentContactShortName180(entry.name)) == key then
            removed = true
        elseif entry then
            table.insert(filtered, entry)
        end
    end
    self.runtime.recentWhispers176 = filtered
    self.runtime.dismissedRecruitmentContacts180 = self.runtime.dismissedRecruitmentContacts180 or {}
    self.runtime.dismissedRecruitmentContacts180[key] = self:Now()
    if self.ui then
        local maximum = math.max(0, table.getn(filtered) - 1)
        self.ui.recentRecruitmentContactsOffset180 = math.max(0, math.min(maximum, tonumber(self.ui.recentRecruitmentContactsOffset180) or 0))
    end
    if self.RefreshRecentWhispers180 then self:RefreshRecentWhispers180()
    elseif self.RefreshRecentWhispers176 then self:RefreshRecentWhispers176() end
    if self.MarkQuickDockDirty182 then self:MarkQuickDockDirty182("recruitment") end
    if removed and self.SetStatus then self:SetStatus(shortName .. " removed from recent recruitment contacts.") end
    return removed
end

function OTLGM:PruneRecentRecruitmentContacts180()
    self.runtime = self.runtime or {}
    local dismissed = self.runtime.dismissedRecruitmentContacts180 or {}
    local dismissedKey, dismissedAt
    local now = self:Now()
    for dismissedKey, dismissedAt in pairs(dismissed) do
        if now - (tonumber(dismissedAt) or 0) > 7200 then dismissed[dismissedKey] = nil end
    end
    self.runtime.dismissedRecruitmentContacts180 = dismissed
    local source = self.runtime.recentWhispers176 or {}
    local filtered, index, entry = {}, 1, nil
    for index = 1, table.getn(source) do
        entry = source[index]
        if entry and entry.name and now - (tonumber(entry.ts) or now) <= 7200 and table.getn(filtered) < 20 then
            local member = RecentContactMember180(self, entry.name)
            table.insert(filtered, {
                name = entry.name,
                ts = entry.ts,
                inviteSentAt176 = entry.inviteSentAt176,
                welcomedAt176 = entry.welcomedAt176,
                state180 = member and "JOINED" or "EXTERNAL",
            })
        end
    end
    self.runtime.recentWhispers176 = filtered
    return filtered
end

function OTLGM:SendRecentRecruitmentWelcome180(name)
    self.runtime = self.runtime or {}
    local shortName = RecentContactShortName180(name)
    if shortName == "" then return false, "Contact name is unavailable." end
    local member = RecentContactMember180(self, shortName)
    if not member then return false, "The character has not joined the guild yet." end
    local entries = self.runtime.recentWhispers176 or {}
    local entry, index
    for index = 1, table.getn(entries) do
        if string.lower(RecentContactShortName180(entries[index].name)) == string.lower(shortName) then entry = entries[index] break end
    end
    if not entry then return false, "Recent contact is no longer available." end
    local now = self:Now()
    if entry.welcomedAt176 and now - (tonumber(entry.welcomedAt176) or 0) < 10 then return false, "Welcome was just sent." end
    if type(SendChatMessage) ~= "function" then return false, "Guild chat is not available right now." end
    local message = "Welcome [" .. shortName .. "] !"
    local ok, problem = pcall(SendChatMessage, message, "GUILD")
    if not ok then return false, tostring(problem or "Welcome could not be sent.") end
    entry.welcomedAt176 = now
    entry.state180 = "JOINED"
    if self.RefreshRecentWhispers180 then self:RefreshRecentWhispers180() end
    return true
end

local function EnsureRecentWhispersDrawer180(owner)
    if owner.ui.recentWhispersDrawer180 then return owner.ui.recentWhispersDrawer180 end
    if not owner.ui.drawerHost then return nil end
    local drawer = UI:Drawer(owner.ui.drawerHost, 520, 220)
    drawer:SetPoint("TOPRIGHT", owner.ui.drawerHost, "TOPRIGHT", -10, -10)
    drawer.title = UI.Text(drawer, "Recent Recruitment Contacts", "GameFontNormalLarge", "LEFT")
    drawer.title:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -18)
    drawer.title:SetWidth(410)
    drawer.subtitle = UI.Text(drawer, "Recent candidates and joined recruits from this session. Use X to dismiss unrelated whispers; private text is never saved.", "GameFontNormalSmall", "LEFT")
    drawer.subtitle:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -46)
    drawer.subtitle:SetWidth(470)
    drawer.subtitle:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    drawer.close = UI:IconButton(drawer, "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 28, 28,
        function() owner:CloseShellDrawer() end, "Close", "utility")
    drawer.close:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -12, -12)
    drawer.rows = {}
    local index
    for index = 1, 10 do
        local row = UI:TableRow(drawer, 474, 44, function(button)
            local entry = button.otlContact180
            if not entry then return end
            if owner.InviteRecentWhisper176 then owner:InviteRecentWhisper176(entry.name) end
        end)
        row.nameText = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.nameText:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -7)
        row.nameText:SetWidth(168)
        row.metaText = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.metaText:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -25)
        row.metaText:SetWidth(178)
        row.metaText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        local captured = row
        row.whisper = UI:Button(row, "Whisper", 72, 24, function()
            local entry = captured.otlContact180
            if entry and owner.WhisperMember then owner:WhisperMember(entry.name) end
        end, "secondary")
        row.whisper:SetPoint("TOPLEFT", row, "TOPLEFT", 190, -10)
        row.action2 = UI:Button(row, "Invite to Guild", 92, 24, function()
            local entry = captured.otlContact180
            if not entry then return end
            if owner.InviteRecentWhisper176 then owner:InviteRecentWhisper176(entry.name) end
        end, "utility")
        row.action2:SetPoint("TOPLEFT", row, "TOPLEFT", 266, -10)
        row.action3 = UI:Button(row, "Welcome", 68, 24, function()
            local entry = captured.otlContact180
            if not entry then return end
            local ok, problem = owner:SendRecentRecruitmentWelcome180(entry.name)
            if not ok and owner.SetStatus then owner:SetStatus(problem or "Welcome was not sent.") end
        end, "utility")
        row.action3:SetPoint("TOPLEFT", row, "TOPLEFT", 366, -10)
        row.remove = UI:Button(row, "X", 28, 24, function()
            local entry = captured.otlContact180
            if entry and owner.RemoveRecentRecruitmentContact180 then owner:RemoveRecentRecruitmentContact180(entry.name) end
        end, "danger")
        row.remove:SetPoint("TOPLEFT", row, "TOPLEFT", 438, -10)
        row.remove.otlTooltipText = "Remove this contact from the recruitment list for this session."
        row:Hide()
        drawer.rows[index] = row
    end
    drawer.scrollbar = UI:Scrollbar(drawer, 320, function(value)
        owner.ui.recentRecruitmentContactsOffset180 = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
        owner:RefreshRecentWhispers180()
    end)
    drawer.empty = UI:EmptyState(drawer, 474, 92, "No recent recruitment contacts", "Incoming recruitment whispers appear here and remain through the joined transition for this session.")
    drawer.empty:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -82)
    SetWheel(drawer, function(delta)
        local maximum = tonumber(drawer.maximum180) or 0
        local offset = tonumber(owner.ui.recentRecruitmentContactsOffset180) or 0
        offset = math.max(0, math.min(maximum, offset - ((tonumber(delta) or 0) * 2)))
        owner.ui.recentRecruitmentContactsOffset180 = offset
        owner:RefreshRecentWhispers180()
    end)
    owner.ui.recentWhispersDrawer180 = drawer
    return drawer
end

function OTLGM:RefreshRecentWhispers180()
    local drawer = EnsureRecentWhispersDrawer180(self)
    if not drawer then return false end
    local entries = self:PruneRecentRecruitmentContacts180()
    local total = table.getn(entries)
    local visible = total > 0 and math.min(10, total) or 0
    local rowHeight = 48
    local listHeight = visible > 0 and (visible * rowHeight) or 92
    local drawerHeight = 82 + listHeight + 18
    drawer:SetHeight(math.max(192, math.min(580, drawerHeight)))
    local maximum = math.max(0, total - visible)
    local offset = math.max(0, math.min(maximum, tonumber(self.ui.recentRecruitmentContactsOffset180) or 0))
    self.ui.recentRecruitmentContactsOffset180 = offset
    drawer.maximum180 = maximum
    local index
    for index = 1, table.getn(drawer.rows) do
        local row = drawer.rows[index]
        local entry = index <= visible and entries[offset + index] or nil
        if entry then
            row.otlContact180 = entry
            row.otlWhisperEntry180 = entry
            local member = RecentContactMember180(self, entry.name)
            entry.state180 = member and "JOINED" or "EXTERNAL"
            row.otlContactMember180 = member
            Move(row, drawer, 18, -(78 + ((index - 1) * rowHeight)), 474, 44)
            local ageSeconds = math.max(0, self:Now() - (tonumber(entry.ts) or self:Now()))
            local age = ageSeconds < 60 and "now" or (tostring(math.floor(ageSeconds / 60)) .. "m")
            row.nameText:SetText(RecentContactShortName180(entry.name) .. "  " .. age)
            row.nameText:SetTextColor(C.white[1], C.white[2], C.white[3])
            local inviteSent = entry.inviteSentAt176 and self:Now() - (tonumber(entry.inviteSentAt176) or 0) < 8
            local welcomed = entry.welcomedAt176 and self:Now() - (tonumber(entry.welcomedAt176) or 0) < 10
            if member then
                row.metaText:SetText(welcomed and "Joined • Welcomed" or "Joined the guild")
                UI:SetText(row.action2, "In Guild")
                UI:SetEnabled(row.action2, false, "This character is already in the guild.")
                UI:SetText(row.action3, welcomed and "Welcomed" or "Welcome")
                UI:SetEnabled(row.action3, not welcomed, welcomed and "Welcome was just sent." or nil)
            else
                row.metaText:SetText(inviteSent and "Invite sent" or "External candidate")
                UI:SetText(row.action2, inviteSent and "Invite sent" or "Invite to Guild")
                UI:SetEnabled(row.action2, not inviteSent, inviteSent and "A guild invite was just sent to this character." or nil)
                UI:SetText(row.action3, "Welcome")
                UI:SetEnabled(row.action3, false, "The character has not joined the guild yet.")
            end
            SetWheel(row, function(delta)
                local current = tonumber(self.ui.recentRecruitmentContactsOffset180) or 0
                current = math.max(0, math.min(maximum, current - ((tonumber(delta) or 0) * 2)))
                self.ui.recentRecruitmentContactsOffset180 = current
                self:RefreshRecentWhispers180()
            end)
            row:Show()
        else
            row.otlContact180 = nil
            row.otlWhisperEntry180 = nil
            row.otlContactMember180 = nil
            row:Hide()
        end
    end
    Move(drawer.scrollbar, drawer, 498, -82, 14, math.max(48, listHeight - 4))
    SetScrollbar(drawer.scrollbar, offset, maximum)
    if total == 0 then drawer.empty:Show() else drawer.empty:Hide() end
    return true
end

function OTLGM:OpenRecentWhispers176()
    if self.ui and self.ui.recentWhisperDialog176 then self.ui.recentWhisperDialog176:Hide() end
    local drawer = EnsureRecentWhispersDrawer180(self)
    if not drawer then return false end
    self.ui.recentRecruitmentContactsOffset180 = 0
    self:RefreshRecentWhispers180()
    return self:ShowShellDrawer(drawer)
end

function OTLGM:RefreshRecentWhispers176()
    if self.ui and self.ui.recentWhispersDrawer180 then return self:RefreshRecentWhispers180() end
    return true
end

local function LayoutHistory(owner, page, width, height)
    SuppressLegacy(page.otlSemanticRefs)
    local ui = owner.ui
    Move(ui.historySearch, page, 0, 0, 226, 28)
    Move(ui.historyClearButton180, page, 232, 0, 58, 28)
    if ui.historySearchHint then
        Move(ui.historySearchHint, page, 8, -6, 208, 18)
    end

    local filterOrder = { "ALL", "UNREAD", "MEMBERS", "RANK", "MILESTONE", "RETURN", "NOTE", "LEVEL60" }
    local widths = { 44, 58, 82, 52, 72, 58, 50, 58 }
    local x = 0
    local gap = 4
    local index
    for index = 1, table.getn(filterOrder) do
        local button = ui.historyFilterButtons[filterOrder[index]]
        if button then
            Move(button, page, x, -36, widths[index], 27)
            x = x + widths[index] + gap
        end
    end
    Hide(ui.historyActionsLabel180)
    local actionWidth = math.max(86, math.min(112, math.floor((width - x - 8) * 0.52)))
    local copyWidth = math.max(78, width - x - actionWidth - 8)
    Move(ui.historyMarkButton, page, x + 4, -36, actionWidth, 27)
    Move(ui.historyCopyButton, page, x + actionWidth + 8, -36, copyWidth, 27)

    local headerY = 72
    local listY = 98
    local listHeight = math.max(216, height - listY - 24)
    local capacity = math.max(8, math.floor(listHeight / 24))
    if owner.EnsureHistoryRows180 then owner:EnsureHistoryRows180(capacity) end
    Move(ui.historyHeader180, page, 0, -headerY, width - 18, 22)
    Move(ui.historyListFrame, page, 0, -listY, width - 18, capacity * 24)
    for index = 1, table.getn(ui.historyRows or {}) do
        local row = ui.historyRows[index]
        if index <= capacity then
            Move(row, ui.historyListFrame, 0, -((index - 1) * 24), width - 18, 24)
            if row.header then row.header:SetWidth(width - 34) end
            if row.detail then row.detail:SetWidth(math.max(180, width - 528)) end
        else row:Hide() end
    end
    Move(ui.historySlider, page, width - 10, -listY, 14, capacity * 24)
    Move(ui.historyCount, page, 0, -(height - 20), width - 20, 18)
    if owner.nativePageSources and owner.nativePageSources.RefreshHistoryPage then
        owner.nativePageSources.RefreshHistoryPage(owner)
    elseif owner.RefreshHistoryRowsOnly then
        owner:RefreshHistoryRowsOnly()
    end
    page.otlNativeLayout = true
end

local function LayoutInactive(owner, page, width, height)
    SuppressLegacy(page.otlSemanticRefs)
    local index
    for index = 1, table.getn(owner.ui.inactiveThresholdButtons or {}) do
        Move(owner.ui.inactiveThresholdButtons[index], page, (index - 1) * 76, 0, 68, 28)
    end
    for index = 1, table.getn(owner.ui.inactiveStatusButtons or {}) do
        Move(owner.ui.inactiveStatusButtons[index], page,
            width - 330 + ((index - 1) * 84), 0, 78, 28)
    end
    local detailWidth = math.max(230, math.floor(width * 0.31))
    local listWidth = width - detailWidth - 28
    local bodyHeight = math.max(288, height - 88)
    local capacity = math.max(8, math.floor(bodyHeight / 24))
    if owner.EnsureInactiveRows180 then owner:EnsureInactiveRows180(capacity) end
    Move(owner.ui.inactiveHeader180, page, 0, -38, listWidth, 22)
    Move(owner.ui.inactiveListFrame, page, 0, -62, listWidth, capacity * 24)
    for index = 1, table.getn(owner.ui.inactiveRows or {}) do
        local row = owner.ui.inactiveRows[index]
        if index <= capacity then Move(row, owner.ui.inactiveListFrame, 0, -((index - 1) * 24), listWidth, 24)
        else row:Hide() end
    end
    Move(owner.ui.inactiveSlider, page, listWidth + 4, -62,
        owner.ui.inactiveSlider:GetWidth(), capacity * 24)
    Move(owner.ui.inactivePanel, page, width - detailWidth, -38, detailWidth, bodyHeight + 24)
    owner.ui.inactiveName:SetWidth(detailWidth - 20)
    owner.ui.inactiveInfo:SetWidth(detailWidth - 20)
    owner.ui.inactiveState:SetWidth(detailWidth - 20)
    Move(owner.ui.inactiveReviewButton, owner.ui.inactivePanel, 10, -198, detailWidth - 20, 26)
    local half = math.floor((detailWidth - 30) / 2)
    Move(owner.ui.inactiveKeepButton, owner.ui.inactivePanel, 10, -230, half, 26)
    Move(owner.ui.inactiveExemptButton, owner.ui.inactivePanel, 20 + half, -230, half, 26)
    Move(owner.ui.inactiveWhisperButton, owner.ui.inactivePanel, 10, -262, half, 26)
    Move(owner.ui.inactiveRemoveButton, owner.ui.inactivePanel, 20 + half, -262, half, 26)
    Move(owner.ui.inactiveCount, page, 0, -(height - 20), listWidth, 18)
    if owner.nativePageSources and owner.nativePageSources.RefreshInactivePage then
        owner.nativePageSources.RefreshInactivePage(owner)
    end
    page.otlNativeLayout = true
end

-- ---------------------------------------------------------------------------
-- Semantic reference registry.
-- ---------------------------------------------------------------------------

local function BuildRefs(owner, root, key)
    local ui = owner.ui
    if key == "guildchat" then
        EnsureChatInput(owner)
        EnsureGuildBoardScroll(owner)
        return RegisterSemanticRefs(root, key, {
            toolbar = ui.chatChannelButtons,
            primaryList = { ui.chatList, ui.guildBoardList152 },
            details = { ui.officerOnlinePanel, ui.guildBoardDetails152 },
            footer = { ui.guildChatEdit, ui.guildChatSendButton, ui.guildBoardNewEdit152, ui.guildBoardPostButton152 },
            scrollOwner = { ui.chatList, ui.guildBoardList152, ui.guildBoardDetailScroll180 },
            legacyLabels = { ui.guildChatLegacyTitle180, ui.guildChatLegacyHelp180 },
        })
    elseif key == "search" then
        local refs = RegisterSemanticRefs(root, key, {
            toolbar = { ui.globalSearchToolbar180 },
            primaryList = { ui.globalSearchList180 },
            details = {},
            footer = { ui.globalSearchStatus },
            scrollOwner = { ui.globalSearchList180 },
            legacyLabels = { ui.globalSearchLegacyTitle, ui.globalSearchLegacyHelp },
        })
        ui.globalSearchScrollbar180 = UI:Scrollbar(ui.globalSearchList180, 300, function(value)
            ui.globalSearchOffset = math.floor(value + 0.5)
            owner:RefreshSearchPage(true)
        end)
        refs.scrollOwner[2] = ui.globalSearchScrollbar180
        return refs
    elseif key == "pve" then
        EnsurePveNativeControls(owner)
        return RegisterSemanticRefs(root, key, {
            toolbar = { ui.pveTabButtons, ui.pveNetworkText, ui.pveSyncButton, ui.raidTabs156, ui.raidCreate156 },
            primaryList = { ui.raidListPanel180, ui.pveGroupList180, ui.pveBoardList180 },
            details = { ui.raidDetailsPanel180, ui.pveGroupDetails180 },
            footer = { ui.pveGroupCreateToggle180, ui.pveBoardComposer180 },
            scrollOwner = { ui.raidListPanel180, ui.pveGroupList180, ui.pveBoardList180 },
            legacyLabels = {
                ui.pveLegacyTitle180, ui.pveLegacyHelp180, ui.pveLegacySubtitle180,
                ui.pveLegacyNetworkBadge180,
            },
        })
    elseif key == "guildinfo" then
        return RegisterSemanticRefs(root, key, {
            toolbar = {},
            primaryList = { ui.guildInfoViewport, ui.guildInfoChild },
            details = {},
            footer = {},
            scrollOwner = { ui.guildInfoViewport, ui.guildInfoSlider },
            legacyLabels = {
                ui.guildInfoLegacyTitle180, ui.guildInfoLegacyHelp180, ui.guildInfoLegacySubtitle180,
            },
        })
    elseif key == "achievements" then
        local refs = RegisterSemanticRefs(root, key, {
            toolbar = { ui.achievementSearch174, ui.achievementFilterButtons174 },
            primaryList = { ui.achievementCategories174, ui.achievementList174 },
            details = {},
            footer = {},
            scrollOwner = { ui.achievementList174 },
            legacyLabels = {},
            summary = {
                ui.achievementTitleIcon174, ui.achievementSummaryTitle174,
                ui.achievementSummarySubtitle174, ui.achievementProgressPanel174,
                ui.achievementProgressText174, ui.achievementCount174,
            },
        })
        ui.achievementScrollbar180 = UI:Scrollbar(ui.achievementList174, 300, function(value)
            ui.achievementOffset174 = math.floor(value + 0.5)
            if RefreshAchievementsNative then RefreshAchievementsNative(owner, true) end
        end)
        if ui.achievementSearch174 then
            ui.achievementSearch174:SetScript("OnTextChanged", function()
                ui.achievementSearchRuntime180 = this:GetText() or ""
                if not ui.achievementProgrammaticFocus180 then
                    ui.achievementSearchDirty180 = true
                    ui.achievementSearchElapsed180 = 0
                    if owner.WakeScheduler180 then owner:WakeScheduler180("ui-debounce:achievements") end
                end
                if ui.achievementSearchPlaceholder175 then
                    if (this:GetText() or "") == "" then ui.achievementSearchPlaceholder175:Show()
                    else ui.achievementSearchPlaceholder175:Hide() end
                end
            end)
            UI:ApplyEditBox(ui.achievementSearch174, { closeOnEmptyEscape = true })
            UI:AttachClearControl180(ui.achievementSearch174)
        end
        refs.scrollOwner[2] = ui.achievementScrollbar180
        return refs
    elseif key == "treasury" then
        local treasury = ui.treasury170
        return RegisterSemanticRefs(root, key, {
            toolbar = {
                treasury and treasury.activityButtonR5, treasury and treasury.ledgerButtonR5,
                treasury and treasury.contributionButton176,
            },
            primaryList = { treasury and treasury.list },
            details = { treasury and treasury.detail },
            footer = { treasury and treasury.status, treasury and treasury.prev, treasury and treasury.next },
            scrollOwner = { treasury and treasury.list },
            legacyLabels = { treasury and treasury.legacyTitle180, treasury and treasury.legacySubtitle180 },
        })
    elseif key == "activity" then
        return RegisterSemanticRefs(root, key, {
            toolbar = { ui.activityCards },
            primaryList = { ui.activityHeatmap180 },
            details = { ui.activityComposition180 },
            footer = { ui.activityInsightPanelR4, ui.activitySync156, ui.activitySummaryButton },
            scrollOwner = {},
            legacyLabels = { ui.activityLegacyTitle180, ui.activityLegacyHelp180, ui.activityLegacySubtitle180 },
        })
    elseif key == "overview" then
        return RegisterSemanticRefs(root, key, {
            toolbar = { ui.overviewCards, ui.overviewPulseCards },
            primaryList = { ui.overviewEvents, ui.overviewActivitySection180 },
            details = { ui.overviewGrowth and ui.overviewGrowth:GetParent() },
            footer = {
                ui.overviewAnnouncementButton, ui.overviewRaidButton,
                ui.overviewRecruitButton, ui.overviewSummaryButton,
            },
            scrollOwner = {},
            legacyLabels = { ui.overviewLegacyTitle180, ui.overviewLegacyHelp180, ui.overviewLegacySubtitle180, ui.overviewRecentLegacyTitle180 },
        })
    elseif key == "recruitment" then
        return RegisterSemanticRefs(root, key, {
            toolbar = { ui.worldRecruitmentCard },
            primaryList = { ui.recruitmentPresetRows180, ui.customSlotButtons },
            details = { ui.recruitmentEdit },
            footer = {
                ui.customNameEdit, ui.customWorldButton, ui.customGuildButton,
                ui.saveSlotButton, ui.clearSlotButton, ui.sendCurrentButton, ui.sendNextButton,
            },
            scrollOwner = {},
            legacyLabels = {
                ui.recruitmentLegacyTitle180, ui.recruitmentLegacyHelp180,
                ui.recruitmentLegacySubtitle180,
            },
        })
    elseif key == "history" then
        if ui.historySlider and not ui.historyScrollbar180 then
            ui.historyLegacySlider180 = ui.historySlider
            Hide(ui.historyLegacySlider180)
            ui.historyScrollbar180 = UI:Scrollbar(root, 300, function(value)
                ui.historyOffset = math.floor((tonumber(value) or 0) + 0.5)
                if owner.RefreshHistoryRowsOnly then owner:RefreshHistoryRowsOnly() end
            end)
            ui.historySlider = ui.historyScrollbar180
        end
        return RegisterSemanticRefs(root, key, {
            toolbar = { ui.historySearch, ui.historyFilterButtons },
            primaryList = { ui.historyHeader180, ui.historyListFrame },
            details = {},
            footer = { ui.historyCount },
            scrollOwner = { ui.historyListFrame, ui.historySlider },
            legacyLabels = { ui.historyLegacyTitle180, ui.historyLegacyHelp180, ui.historyLegacySubtitle180 },
        })
    elseif key == "inactive" then
        return RegisterSemanticRefs(root, key, {
            toolbar = { ui.inactiveThresholdButtons, ui.inactiveStatusButtons },
            primaryList = { ui.inactiveHeader180, ui.inactiveListFrame },
            details = { ui.inactivePanel },
            footer = { ui.inactiveCount },
            scrollOwner = { ui.inactiveListFrame, ui.inactiveSlider },
            legacyLabels = { ui.inactiveLegacyTitle180, ui.inactiveLegacyHelp180, ui.inactiveLegacySubtitle180 },
        })
    end
    return RegisterSemanticRefs(root, key, {})
end

local LAYOUTS = {
    guildchat = LayoutGuildChat,
    search = LayoutSearch,
    pve = LayoutPve,
    guildinfo = LayoutGuildInfo,
    achievements = LayoutAchievements,
    treasury = LayoutTreasury,
    activity = LayoutActivity,
    overview = LayoutOverview,
    recruitment = LayoutRecruitment,
    history = LayoutHistory,
    inactive = LayoutInactive,
}

local POST_REFRESH = {
    overview = function(owner)
        if owner.RefreshOverviewNativeRows180 then owner:RefreshOverviewNativeRows180() end
    end,
    guildchat = function(owner)
        RefreshGuildBoardNative(owner)
    end,
    search = RefreshSearchNative,
    pve = RefreshPveNative,
    achievements = RefreshAchievementsNative,
}

local SOURCES = {
    guildchat = {
        builder = "BuildGuildChatPage", sourceRefresh = "RefreshGuildChatPage",
        publicRefresh = "RefreshGuildChatPage", toolbar = { "channels", "filters", "composer" },
    },
    search = {
        builder = "BuildSearchPage", sourceRefresh = "RefreshSearchPage",
        publicRefresh = "RefreshSearchPage", toolbar = { "search", "filters", "continuous-scroll" },
        nativeOwnsRefresh = true,
    },
    pve = {
        builder = "BuildPvePage", sourceRefresh = "RefreshPvePage",
        publicRefresh = "RefreshPvePage", toolbar = { "raids", "groups", "board" },
    },
    guildinfo = {
        builder = "BuildGuildInfoPage", sourceRefresh = "RefreshGuildInfoPage",
        publicRefresh = "RefreshGuildInfoPage", toolbar = { "scroll" },
    },
    achievements = {
        builder = "BuildAchievementsPage", sourceRefresh = "RefreshAchievements",
        publicRefresh = "RefreshAchievements174", toolbar = { "search", "filters", "categories", "continuous-scroll" },
    },
    treasury = {
        builder = "BuildTreasuryPage", sourceRefresh = "RefreshTreasuryPage",
        publicRefresh = "RefreshTreasuryPage170", toolbar = { "activity", "ledger", "contribution" },
    },
    activity = {
        builder = "BuildActivityPage", sourceRefresh = "RefreshActivityPage",
        publicRefresh = "RefreshActivityPage", toolbar = { "metrics", "heatmap", "composition" },
    },
    overview = {
        builder = "BuildOverviewPage", sourceRefresh = "RefreshOverviewPage",
        publicRefresh = "RefreshOverviewPage", toolbar = { "metrics", "activity" },
    },
    recruitment = {
        builder = "BuildRecruitmentPage", sourceRefresh = "RefreshRecruitmentPage",
        publicRefresh = "RefreshRecruitmentPage", toolbar = { "rotation", "custom-slots", "composer" },
    },
    history = {
        builder = "BuildHistoryPage", sourceRefresh = "RefreshHistoryPage",
        publicRefresh = "RefreshHistoryPage", toolbar = { "search", "filters" },
    },
    inactive = {
        builder = "BuildInactivePage", sourceRefresh = "RefreshInactivePage",
        publicRefresh = "RefreshInactivePage", toolbar = { "filters", "members", "details" },
    },
}

local key, definition
for key, definition in pairs(SOURCES) do
    local capturedKey = key
    local capturedDefinition = definition
    OTLGM:CreateShellPageModule180(capturedKey,
        function(owner, root)
            local builder = owner.nativePageSources[capturedDefinition.builder]
            if not builder then
                local empty = UI:EmptyState(root, 520, 150, "Page unavailable",
                    "The page-level control builder was not loaded.")
                empty:SetPoint("CENTER", root, "CENTER", 0, 0)
                root.otlUnavailable = true
                RegisterSemanticRefs(root, capturedKey, {})
                return
            end
            builder(owner, root)
            if owner.NormalizeEditBoxes180 then owner:NormalizeEditBoxes180(root) end
            BuildRefs(owner, root, capturedKey)
            if capturedKey == "pve" then
                local pveReady = EnsurePveNativeControls(owner)
                if pveReady and owner.ui.pveNativeRefreshPending180 then
                    owner.ui.pveNativeRefreshPending180 = nil
                    RefreshPveNative(owner)
                end
            end
            if capturedKey == "achievements" and owner.BuildAchievementToast174 then
                owner:BuildAchievementToast174()
            elseif capturedKey == "overview" and owner.ui.overviewPulseCards
                and owner.ui.overviewPulseCards.addon then
                local addonCard = owner.ui.overviewPulseCards.addon
                addonCard:SetScript("OnEnter", nil)
                addonCard:SetScript("OnLeave", nil)
                addonCard:SetScript("OnMouseDown", function() OTLGM:ToggleAddonUsersDrawer() end)
            end
            root.otlNativeContentHost = true
        end,
        function(owner, reason)
            owner[capturedDefinition.publicRefresh](owner, reason)
        end,
        function(owner, page, width, height)
            -- Resolve the page layout at call time. NativePages deliberately
            -- applies a few late compatibility wrappers after shell modules are
            -- registered; capturing the current function here would freeze the
            -- earlier implementation and silently bypass those wrappers.
            local layout = LAYOUTS[capturedKey]
            if layout then layout(owner, page, width, height) end
        end,
        capturedDefinition.toolbar,
        { width = 720, height = 500 })
end

-- Public refresh paths are replaced only after every immutable source function
-- has been captured. Buttons, events and direct refreshes therefore all finish
-- with the same native post-refresh and ContentHost layout pass.
for key, definition in pairs(SOURCES) do
    local capturedKey = key
    local capturedDefinition = definition
    OTLGM[capturedDefinition.publicRefresh] = function(owner, value)
        if owner.CanRefreshShellPage180 and not owner:CanRefreshShellPage180(capturedKey) then return false end
        local source = owner.nativePageSources[capturedDefinition.sourceRefresh]
        local result
        -- Search has a complete native renderer. Running the retired legacy
        -- renderer first rebuilt and sorted the same global result set a second
        -- time on every scroll/filter refresh. Other pages still use their
        -- source refresh for state that has not yet moved into the native layer.
        if source and not capturedDefinition.nativeOwnsRefresh then result = source(owner, value) end
        local post = POST_REFRESH[capturedKey]
        if post then post(owner) end
        owner:LayoutShellPage180(capturedKey, "native-refresh")
        return result
    end
end

local function WrapNestedRefresh(name, pageKey, post)
    local source = OTLGM[name]
    if not source then return end
    OTLGM[name] = function(owner, value)
        local result = source(owner, value)
        if post then post(owner) end
        owner:LayoutShellPage180(pageKey, "nested-refresh")
        return result
    end
end

WrapNestedRefresh("RefreshGuildBoardChat152", "guildchat", RefreshGuildBoardNative)
WrapNestedRefresh("RefreshRaidPlanner156", "pve", RefreshPveNative)
WrapNestedRefresh("RefreshPveGroupsPanel", "pve", RefreshPveNative)
WrapNestedRefresh("RefreshPveBoardPanel", "pve", RefreshPveNative)

OTLGM:RegisterModule("UINativePages180", {
    stage = "B",
    revision = 9,
    nativeContentHost = true,
    semanticReferences = true,
    dynamicCapacity = true,
    repeatedRefreshLayout = true,
    continuousAchievementScroll = true,
    continuousSearchScroll = true,
    pageContract = true,
    pageCount = 11,
    noLegacyWindowAdapter = true,
    noOnUpdate = true,
})

-- ---------------------------------------------------------------------------
-- C5-R2 PACK 2: Raid Teams presentation, picker UX, exact permissions and
-- native Raid Event editor. This remains inside the canonical NativePages
-- module and does not add a release/hotfix layer.
-- ---------------------------------------------------------------------------

local RAID_TEAM_PICKER_CATEGORY_ORDER_PACK2 = { "MEMBERS", "RAIDERS", "LEADERSHIP", "GUESTS", "ALL" }
local RAID_TEAM_ROLE_ICONS_PACK2 = {
    FLEXIBLE = "Interface\\AddOns\\OrderOfTheLionGM\\Assets\\Roles\\Review",
    UNASSIGNED = "Interface\\AddOns\\OrderOfTheLionGM\\Assets\\Roles\\Review",
    TANK = "Interface\\AddOns\\OrderOfTheLionGM\\Assets\\Roles\\Tank",
    HEALER = "Interface\\AddOns\\OrderOfTheLionGM\\Assets\\Roles\\Healer",
    DAMAGE = "Interface\\AddOns\\OrderOfTheLionGM\\Assets\\Roles\\Damage",
}

local function RaidTeamNormalizePack2(value)
    return string.lower(string.gsub(tostring(value or ""), "%-.*$", ""))
end

local function RaidTeamApplyClassIconPack2(texture, classToken)
    PveProfileSetClassIcon180(texture, classToken)
end

local function RaidTeamApplyRoleIconPack2(texture, role)
    if not texture then return end
    texture:SetTexture(RAID_TEAM_ROLE_ICONS_PACK2[string.upper(tostring(role or "FLEXIBLE"))] or RAID_TEAM_ROLE_ICONS_PACK2.FLEXIBLE)
    texture:SetTexCoord(0, 1, 0, 1)
    texture:SetVertexColor(1, 1, 1)
end

local function RaidTeamMemberDisplayRowsPack2(owner, team)
    local roles = { "TANK", "HEALER", "DAMAGE", "FLEXIBLE" }
    local roleLabels = { TANK = "TANKS", HEALER = "HEALERS", DAMAGE = "DAMAGE", FLEXIBLE = "FLEXIBLE" }
    local groups = { CORE = {}, RESERVE = {}, GUEST = {} }
    local _, member
    for _, member in pairs(team and team.members or {}) do
        local tier = member.tier == "CORE" and "CORE" or (member.tier == "RESERVE" and "RESERVE" or "GUEST")
        table.insert(groups[tier], member)
    end
    local function sortMembers(rows)
        table.sort(rows, function(left, right)
            local leftStored = owner and owner.GetMember and owner:GetMember(left.character) or nil
            local rightStored = owner and owner.GetMember and owner:GetMember(right.character) or nil
            local leftOnline = leftStored and leftStored.online and true or false
            local rightOnline = rightStored and rightStored.online and true or false
            if leftOnline ~= rightOnline then return leftOnline end
            local lr, rr = tostring(left.role or "FLEXIBLE"), tostring(right.role or "FLEXIBLE")
            if lr ~= rr then return lr < rr end
            return RaidTeamNormalizePack2(left.character) < RaidTeamNormalizePack2(right.character)
        end)
    end
    local result, roleIndex, index = {}, 1, 1
    local coreByRole = { TANK = {}, HEALER = {}, DAMAGE = {}, FLEXIBLE = {} }
    for index = 1, table.getn(groups.CORE) do
        member = groups.CORE[index]
        local role = coreByRole[member.role] and member.role or "FLEXIBLE"
        table.insert(coreByRole[role], member)
    end
    for roleIndex = 1, table.getn(roles) do
        local role = roles[roleIndex]
        sortMembers(coreByRole[role])
        if table.getn(coreByRole[role]) > 0 then
            table.insert(result, { otlHeader180 = true, title = "CORE - " .. roleLabels[role] .. "  " .. tostring(table.getn(coreByRole[role])), tier = "CORE", role = role })
            for index = 1, table.getn(coreByRole[role]) do table.insert(result, coreByRole[role][index]) end
        end
    end
    local tiers = { "RESERVE", "GUEST" }
    local labels = { RESERVE = "RESERVES", GUEST = "GUESTS" }
    for index = 1, table.getn(tiers) do
        local tier = tiers[index]
        sortMembers(groups[tier])
        if table.getn(groups[tier]) > 0 then
            table.insert(result, { otlHeader180 = true, title = labels[tier] .. "  " .. tostring(table.getn(groups[tier])), tier = tier })
            local memberIndex
            for memberIndex = 1, table.getn(groups[tier]) do table.insert(result, groups[tier][memberIndex]) end
        end
    end
    return result
end

local function RaidTeamPickerCategoryNextPack2(current)
    current = current or "MEMBERS"
    local index
    for index = 1, table.getn(RAID_TEAM_PICKER_CATEGORY_ORDER_PACK2) do
        if RAID_TEAM_PICKER_CATEGORY_ORDER_PACK2[index] == current then
            return RAID_TEAM_PICKER_CATEGORY_ORDER_PACK2[math.mod(index, table.getn(RAID_TEAM_PICKER_CATEGORY_ORDER_PACK2)) + 1]
        end
    end
    return "MEMBERS"
end

function OTLGM.__impl180.EnsureRaidTeamPack2Controls180__impl1(self)
    local ui = self.ui
    if not ui or not ui.raidTeamsPanel180 or ui.raidTeamPack2Controls180 then return false end
    ui.raidTeamPack2Controls180 = true
    local panel = ui.raidTeamsPanel180

    ui.raidTeamAllTeams180 = UI:FilterChip(panel, "All Teams", 86, function()
        ui.raidTeamMyTeamsOnly180 = false ui.raidTeamOffset180 = 0 self:RefreshRaidTeamsPanel180()
    end)
    ui.raidTeamMyTeams180 = UI:FilterChip(panel, "My Teams", 82, function()
        ui.raidTeamMyTeamsOnly180 = true ui.raidTeamOffset180 = 0 self:RefreshRaidTeamsPanel180()
    end)
    ui.raidTeamPersonalStatus180 = UI.Text(ui.raidTeamDetailsPanel180, "", "GameFontNormalSmall", "LEFT")
    ui.raidTeamPersonalStatus180:SetHeight(24)
    ui.raidTeamPrimaryBadge180 = UI.Text(ui.raidTeamDetailsPanel180, "", "GameFontNormalSmall", "LEFT")
    ui.raidTeamOnlineSummary180 = UI.Text(ui.raidTeamDetailsPanel180, "", "GameFontNormalSmall", "LEFT")
    ui.raidTeamRoleSummary180 = UI.Text(ui.raidTeamDetailsPanel180, "", "GameFontNormalSmall", "LEFT")
    ui.raidTeamRoleSummary180:SetJustifyV("TOP")
    ui.raidTeamNextRaid180 = UI.Text(ui.raidTeamDetailsPanel180, "", "GameFontNormalSmall", "LEFT")
    ui.raidTeamWhisperLeader180 = UI:Button(ui.raidTeamDetailsPanel180, "Whisper Raid Leader", 126, 24, function()
        local team = self:GetRaidTeam180(ui.raidTeamSelectedId180)
        if team and team.raidLeader and self.WhisperMember then self:WhisperMember(team.raidLeader) end
    end, "utility")
    ui.raidTeamWhisperContact180 = UI:Button(ui.raidTeamDetailsPanel180, "Whisper Invite Contact", 140, 24, function()
        local team = self:GetRaidTeam180(ui.raidTeamSelectedId180)
        local contact = team and (team.inviteContact or team.raidLeader)
        if contact and self.WhisperMember then self:WhisperMember(contact) end
    end, "utility")
    ui.raidTeamSelfContact180 = UI.Text(ui.raidTeamDetailsPanel180, "", "GameFontNormalSmall", "LEFT")
    ui.raidTeamSelfContact180:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    ui.raidTeamSelfContact180:Hide()
    ui.raidTeamOpenNextRaid180 = UI:Button(ui.raidTeamDetailsPanel180, "View Raid", 78, 24, function()
        local eventId = ui.raidTeamNextRaidId180
        if eventId and self.OpenGuildObject180 then self:OpenGuildObject180("RAID_EVENT", eventId, { section = "RAIDS" }) end
    end, "utility")
    ui.raidTeamSetPrimary180 = UI:Button(ui.raidTeamDetailsPanel180, "Set Primary", 88, 24, function()
        local team = self:GetRaidTeam180(ui.raidTeamSelectedId180)
        if not team then return end
        local ok, problem = self:SetPrimaryRaidTeam180(team.id)
        if not ok and self.ShowNotice then self:ShowNotice("Raid Team", problem or "Primary Team could not be changed.") end
        self:RefreshRaidTeamsPanel180()
    end, "utility")

    local index, row
    for index = 1, table.getn(ui.raidTeamRows180 or {}) do
        row = ui.raidTeamRows180[index]
        row.primaryAccent180 = row:CreateTexture(nil, "ARTWORK")
        row.primaryAccent180:SetTexture("Interface\\Buttons\\WHITE8X8")
        row.primaryAccent180:SetVertexColor(0.72, 0.12, 0.08, 0.95)
        row.primaryAccent180:SetWidth(4)
        row.primaryAccent180:SetPoint("TOPLEFT", row, "TOPLEFT", 1, -2)
        row.primaryAccent180:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 1, 2)
        row.primaryAccent180:Hide()
    end
    for index = 1, table.getn(ui.raidTeamMemberRows180 or {}) do
        row = ui.raidTeamMemberRows180[index]
        row.classIcon180 = row:CreateTexture(nil, "ARTWORK")
        row.classIcon180:SetWidth(18) row.classIcon180:SetHeight(18)
        row.roleIcon180 = row:CreateTexture(nil, "ARTWORK")
        row.roleIcon180:SetWidth(18) row.roleIcon180:SetHeight(18)
    end
    for index = 1, table.getn(ui.raidTeamPickerRows180 or {}) do
        row = ui.raidTeamPickerRows180[index]
        row.classIcon180 = row:CreateTexture(nil, "ARTWORK")
        row.classIcon180:SetWidth(18) row.classIcon180:SetHeight(18)
        row:SetScript("OnClick", function()
            if this.otlDisabled or not this.memberKey180 or this.alreadyInTeam180 then return end
            ui.raidTeamPickerSelection180 = ui.raidTeamPickerSelection180 or {}
            ui.raidTeamPickerSelection180[this.memberKey180] = not ui.raidTeamPickerSelection180[this.memberKey180]
            OTLGM:RefreshRaidTeamPicker180()
        end)
    end

    local actions = ui.raidTeamMemberActionButtons180 or {}
    if actions.role then actions.role:Hide() end
    actions.flexible = UI:Button(ui.raidTeamDetailsPanel180, "Needs Review", 92, 24, function() self:ApplyRaidTeamMemberAction180("MAIN_ROLE", "UNASSIGNED") end, "utility")
    actions.tank = UI:Button(ui.raidTeamDetailsPanel180, "Tank", 62, 24, function() self:ApplyRaidTeamMemberAction180("ROLE", "TANK") end, "utility")
    actions.healer = UI:Button(ui.raidTeamDetailsPanel180, "Healer", 68, 24, function() self:ApplyRaidTeamMemberAction180("ROLE", "HEALER") end, "utility")
    actions.damage = UI:Button(ui.raidTeamDetailsPanel180, "Damage", 76, 24, function() self:ApplyRaidTeamMemberAction180("ROLE", "DAMAGE") end, "utility")
    local roleKeys = { "flexible", "tank", "healer", "damage" }
    for index = 1, table.getn(roleKeys) do
        local button = actions[roleKeys[index]]
        button.roleIcon180 = button:CreateTexture(nil, "ARTWORK")
        button.roleIcon180:SetWidth(14) button.roleIcon180:SetHeight(14)
        button.roleIcon180:SetPoint("LEFT", button, "LEFT", 5, 0)
        RaidTeamApplyRoleIconPack2(button.roleIcon180, string.upper(roleKeys[index]))
        button.text:ClearAllPoints() button.text:SetPoint("CENTER", button, "CENTER", 7, 0)
    end
    ui.raidTeamMemberActionButtons180 = actions

    local picker = ui.raidTeamPicker180
    ui.raidTeamPickerCategory180 = ui.raidTeamPickerCategory180 or "MEMBERS"
    ui.raidTeamPickerCategoryButton180 = UI:Button(picker, "Members", 104, 28, function()
        ui.raidTeamPickerCategory180 = RaidTeamPickerCategoryNextPack2(ui.raidTeamPickerCategory180)
        ui.raidTeamPickerOffset180 = 0 self:RefreshRaidTeamPicker180()
    end, "filter")
    ui.raidTeamPickerOnlineButton180 = UI:Button(picker, "Online only", 94, 28, function()
        ui.raidTeamPickerOnlineOnly180 = not ui.raidTeamPickerOnlineOnly180
        ui.raidTeamPickerOffset180 = 0 self:RefreshRaidTeamPicker180()
    end, "filter")
    ui.raidTeamPickerSelectedCount180 = UI.Text(picker, "Selected: 0", "GameFontNormalSmall", "LEFT")
    ui.raidTeamPickerSelectedCount180:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])

    local function pickerWheel(delta)
        local candidates = self:GetRaidTeamRosterCandidates180(
            ui.raidTeamPickerSearch180 or "", ui.raidTeamPickerClass180 or "ALL",
            ui.raidTeamPickerSelectedOnly180, ui.raidTeamPickerSelection180,
            ui.raidTeamPickerCategory180 or "MEMBERS", ui.raidTeamPickerOnlineOnly180,
            picker and picker.teamId180)
        local capacity = tonumber(ui.raidTeamPickerVisibleRows180) or 10
        local maximum = math.max(0, table.getn(candidates) - capacity)
        local nextOffset = math.max(0, math.min(maximum, (tonumber(ui.raidTeamPickerOffset180) or 0) - ((tonumber(delta) or 0) * 3)))
        if nextOffset ~= (tonumber(ui.raidTeamPickerOffset180) or 0) then ui.raidTeamPickerOffset180 = nextOffset self:RefreshRaidTeamPicker180() end
    end
    SetWheel(picker, pickerWheel)
    for index = 1, table.getn(ui.raidTeamPickerRows180 or {}) do SetWheel(ui.raidTeamPickerRows180[index], pickerWheel) end
    SetWheel(ui.raidTeamListPanel180, function(delta)
        local teams = self:GetRaidTeamList180(true, ui.raidTeamMyTeamsOnly180)
        local maximum = math.max(0, table.getn(teams) - (tonumber(ui.raidTeamVisibleRows180) or 8))
        ui.raidTeamOffset180 = math.max(0, math.min(maximum, (tonumber(ui.raidTeamOffset180) or 0) - ((tonumber(delta) or 0) * 2)))
        self:RefreshRaidTeamsPanel180()
    end)
    SetWheel(ui.raidTeamDetailsPanel180, function(delta)
        local team = self:GetRaidTeam180(ui.raidTeamSelectedId180)
        local rows = RaidTeamMemberDisplayRowsPack2(self, team)
        local maximum = math.max(0, table.getn(rows) - (tonumber(ui.raidTeamMemberVisibleRows180) or 9))
        ui.raidTeamMemberOffset180 = math.max(0, math.min(maximum, (tonumber(ui.raidTeamMemberOffset180) or 0) - ((tonumber(delta) or 0) * 2)))
        self:RefreshRaidTeamsPanel180()
    end)

    ui.raidTeamPickerAdd180:SetScript("OnClick", function()
        if this.otlDisabled then return end
        local names = RaidTeamSelectionList180(ui.raidTeamPickerSelection180)
        if picker.targetType180 == "EVENT_CUSTOM" then
            local roster = {}
            local candidates = OTLGM:GetRaidTeamRosterCandidates180("", "ALL", true, ui.raidTeamPickerSelection180, "ALL", false, nil)
            local candidateIndex, member, key
            for candidateIndex = 1, table.getn(candidates) do
                member = candidates[candidateIndex]
                key = RaidTeamNormalizePack2(member.name)
                if ui.raidTeamPickerSelection180[key] then
                    roster[key] = { character = member.name, class = member.classFile or member.class or "", mainRole = "UNASSIGNED", roleNeedsReview180 = true, slotStatus = "ASSIGNED" }
                end
            end
            ui.raidCustomRoster180 = roster
            OTLGM:CloseModal180(picker, "custom-roster-selected")
            OTLGM:RefreshRaidRosterEditor180()
            return
        end
        local ok, message = OTLGM:MutateRaidTeamMembers180(picker.teamId180, names, "ADD")
        if not ok then OTLGM:ShowNotice("Raid Team", message or "No members were added.") return end
        OTLGM:CloseModal180(picker, "members-added")
        ui.raidTeamSelectedId180 = picker.teamId180
        OTLGM:RefreshRaidTeamsPanel180()
    end)
    ui.raidTeamPickerCancel180:SetScript("OnClick", function() OTLGM:CloseModal180(picker, "cancel") end)
    return true
end

function OTLGM:OpenRaidTeamMemberPicker180(teamId)
    self:EnsureRaidTeamPack2Controls180()
    local ui = self.ui
    local team = self:GetRaidTeam180(teamId)
    if not ui or not ui.raidTeamPicker180 or not team or not self:CanManageRaidTeams180(team) then return false end
    local picker = ui.raidTeamPicker180
    picker.teamId180 = teamId picker.targetType180 = "TEAM"
    ui.raidTeamPickerSelection180 = {}
    ui.raidTeamPickerSearch180 = "" ui.raidTeamPickerClass180 = "ALL"
    ui.raidTeamPickerCategory180 = "MEMBERS" ui.raidTeamPickerOnlineOnly180 = false
    ui.raidTeamPickerSelectedOnly180 = false ui.raidTeamPickerOffset180 = 0
    UI:SetSearchText(ui.raidTeamPickerSearchBox180, "")
    if self.ShowModal152 then self:ShowModal152(picker) else picker:Show() end
    self:RefreshRaidTeamPicker180()
    return true
end

function OTLGM:OpenCustomRaidRosterPicker180()
    self:EnsureRaidTeamPack2Controls180()
    local ui = self.ui
    if not ui or not ui.raidTeamPicker180 then return false end
    local picker = ui.raidTeamPicker180
    picker.teamId180 = nil picker.targetType180 = "EVENT_CUSTOM"
    ui.raidTeamPickerSelection180 = {}
    local source = ui.raidCustomRoster180
    if type(source) ~= "table" then
        local current = ui.raidEditor156 and ui.raidEditor156.editId156 and self:GetRaidEvent180(ui.raidEditor156.editId156)
        source = current and current.roster180 or {}
    end
    local key, member
    for key, member in pairs(source or {}) do ui.raidTeamPickerSelection180[RaidTeamNormalizePack2(member.character or key)] = true end
    ui.raidTeamPickerSearch180 = "" ui.raidTeamPickerClass180 = "ALL"
    ui.raidTeamPickerCategory180 = "ALL" ui.raidTeamPickerOnlineOnly180 = false
    ui.raidTeamPickerSelectedOnly180 = false ui.raidTeamPickerOffset180 = 0
    UI:SetSearchText(ui.raidTeamPickerSearchBox180, "")
    if self.ShowModal152 then self:ShowModal152(picker) else picker:Show() end
    self:RefreshRaidTeamPicker180()
    return true
end

function OTLGM:RefreshRaidTeamPicker180()
    self:EnsureRaidTeamPack2Controls180()
    local ui = self.ui
    local picker = ui and ui.raidTeamPicker180
    if not picker or not picker:IsVisible() then return false end
    local candidates = self:GetRaidTeamRosterCandidates180(
        ui.raidTeamPickerSearch180 or "", ui.raidTeamPickerClass180 or "ALL",
        ui.raidTeamPickerSelectedOnly180, ui.raidTeamPickerSelection180,
        ui.raidTeamPickerCategory180 or "MEMBERS", ui.raidTeamPickerOnlineOnly180,
        picker.teamId180)
    local capacity = tonumber(ui.raidTeamPickerVisibleRows180) or 10
    local maximum = math.max(0, table.getn(candidates) - capacity)
    ui.raidTeamPickerOffset180 = math.max(0, math.min(maximum, tonumber(ui.raidTeamPickerOffset180) or 0))
    local index, row, member, key
    for index = 1, table.getn(ui.raidTeamPickerRows180 or {}) do
        row = ui.raidTeamPickerRows180[index]
        member = index <= capacity and candidates[ui.raidTeamPickerOffset180 + index] or nil
        if member then
            key = RaidTeamNormalizePack2(member.name)
            row.member180 = member row.memberKey180 = key row.alreadyInTeam180 = member.raidTeamAlreadyIn180 and true or false
            RaidTeamApplyClassIconPack2(row.classIcon180, member.classFile or member.class)
            local prefix = ui.raidTeamPickerSelection180[key] and "|cffffcc44[SELECTED]|r  " or ""
            row.nameText:SetText(prefix .. self:GetClassColor(member.class or member.classFile) .. tostring(member.name or "Unknown") .. self.colors.reset)
            row.metaText:SetText("Lv " .. tostring(member.level or "?") .. "  |  " .. tostring(member.class or member.classFile or "Unknown") .. "  |  " .. tostring(member.rank or "") ..
                (member.online and "  |cff55dd77Online|r" or "  |cff888888Offline|r") .. (member.raidTeamAlreadyIn180 and "  |cffbba96aAlready in team|r" or ""))
            UI:SetSelected(row, ui.raidTeamPickerSelection180[key] == true)
            UI:SetEnabled(row, not member.raidTeamAlreadyIn180, "Already in this Raid Team.")
            row:Show()
        else row.member180 = nil row.memberKey180 = nil row.alreadyInTeam180 = nil row:Hide() end
    end
    if ui.raidTeamPickerScrollbar180 and ui.raidTeamPickerScrollbar180.SetScrollMetrics180 then
        ui.raidTeamPickerScrollbar180:SetScrollMetrics180(table.getn(candidates), capacity, ui.raidTeamPickerOffset180)
    end
    UI:SetText(ui.raidTeamPickerClassButton180, "Class: " .. tostring(ui.raidTeamPickerClass180 or "ALL"))
    UI:SetText(ui.raidTeamPickerCategoryButton180, string.gsub(tostring(ui.raidTeamPickerCategory180 or "MEMBERS"), "_", " "))
    UI:SetSelected(ui.raidTeamPickerCategoryButton180, (ui.raidTeamPickerCategory180 or "MEMBERS") ~= "MEMBERS")
    UI:SetSelected(ui.raidTeamPickerOnlineButton180, ui.raidTeamPickerOnlineOnly180)
    UI:SetSelected(ui.raidTeamPickerSelectedButton180, ui.raidTeamPickerSelectedOnly180)
    local count = table.getn(RaidTeamSelectionList180(ui.raidTeamPickerSelection180))
    ui.raidTeamPickerSelectedCount180:SetText("Selected: " .. tostring(count))
    UI:SetText(ui.raidTeamPickerAdd180, (picker.targetType180 == "EVENT_CUSTOM" and "Use Selected (" or "Add Selected (") .. tostring(count) .. ")")
    UI:SetEnabled(ui.raidTeamPickerAdd180, count > 0, "Select at least one guild member.")
    return true
end

function OTLGM:ApplyRaidTeamMemberAction180(action, value)
    local ui = self.ui
    local teamId = ui and ui.raidTeamSelectedId180
    local team = teamId and self:GetRaidTeam180(teamId) or nil
    local selection = ui and ui.raidTeamMemberSelection180 or {}
    local names = RaidTeamSelectionList180(selection)
    if not team or table.getn(names) == 0 then return false end

    local validNames, index = {}, 1
    for index = 1, table.getn(names) do
        local key = RaidTeamNormalizePack2(names[index])
        local current = team.members and team.members[key] or nil
        if not current then
            for _, candidate in pairs(team.members or {}) do
                if RaidTeamNormalizePack2(candidate.character) == key then current = candidate break end
            end
        end
        if current then table.insert(validNames, current.character or names[index]) end
    end
    if table.getn(validNames) ~= table.getn(names) then
        if self.ShowNotice then self:ShowNotice("Raid Team", "Selection changed. Re-select visible members before applying an action.") end
        self:ClearRaidTeamMemberSelection180("stale-selection", true)
        return false
    end

    local ok, message = self:MutateRaidTeamMembers180(teamId, validNames, action, value)
    if not ok then
        if self.ShowNotice then self:ShowNotice("Raid Team", message or "No membership change was applied.") end
        return false
    end
    self:ClearRaidTeamMemberSelection180("action-success", false)
    ui.raidTeamMemberOffset180 = 0
    self:RefreshRaidTeamsPanel180()
    return true
end

local function LayoutRaidTeamPack2Extras180(owner)
    local ui = owner.ui
    local panel = ui.raidTeamsPanel180
    local details = ui.raidTeamDetailsPanel180
    if not panel or not details then return end
    local width = panel:GetWidth() or 720
    local detailWidth = details:GetWidth() or 390
    local detailHeight = details:GetHeight() or 330
    local searchWidth = math.max(170, math.min(250, math.floor(width * 0.24)))
    Move(ui.raidTeamSearchBox180, panel, 0, 0, searchWidth, 28)
    Move(ui.raidTeamAllTeams180, panel, searchWidth + 8, 2, 86, 24)
    Move(ui.raidTeamMyTeams180, panel, searchWidth + 100, 2, 82, 24)

    Move(ui.raidTeamPrimaryBadge180, details, 12, -104, 120, 20)
    Move(ui.raidTeamOnlineSummary180, details, 136, -104, detailWidth - 148, 20)
    Move(ui.raidTeamPersonalStatus180, details, 12, -128, detailWidth - 24, 22)
    Move(ui.raidTeamDetailDescription180, details, 12, -152, detailWidth - 24, 34)
    Move(ui.raidTeamRoleSummary180, details, 12, -188, detailWidth - 24, 38)
    Move(ui.raidTeamNextRaid180, details, 12, -228, detailWidth - 102, 34)
    Move(ui.raidTeamOpenNextRaid180, details, detailWidth - 90, -230, 78, 24)
    Move(ui.raidTeamWhisperLeader180, details, 12, -264, 126, 24)
    Move(ui.raidTeamWhisperContact180, details, 144, -264, 140, 24)
    Move(ui.raidTeamSetPrimary180, details, detailWidth - 100, -264, 88, 24)
    Move(ui.raidTeamAddMembers180, details, detailWidth - 138, -292, 126, 26)

    local memberTop = 324
    local actionRowsHeight = 66
    local memberArea = math.max(62, detailHeight - memberTop - actionRowsHeight)
    local capacity = math.max(2, math.min(table.getn(ui.raidTeamMemberRows180 or {}), math.floor(memberArea / 30)))
    ui.raidTeamMemberVisibleRows180 = capacity
    local index, row
    for index = 1, table.getn(ui.raidTeamMemberRows180 or {}) do
        row = ui.raidTeamMemberRows180[index]
        if index <= capacity then
            Move(row, details, 12, -memberTop - ((index - 1) * memberRowStep), detailWidth - 38, memberRowStep - 2)
            if row.classIcon180 then row.classIcon180:ClearAllPoints() row.classIcon180:SetPoint("LEFT", row, "LEFT", 7, 0) end
            Move(row.nameText, row, 31, -5, math.floor((detailWidth - 70) * 0.46), 18)
            if row.roleIcon180 then row.roleIcon180:ClearAllPoints() row.roleIcon180:SetPoint("LEFT", row, "LEFT", math.floor((detailWidth - 70) * 0.46) + 38, 0) end
            Move(row.metaText, row, math.floor((detailWidth - 70) * 0.46) + 60, -5, math.floor((detailWidth - 70) * 0.54) - 60, 18)
        end
    end
    Move(ui.raidTeamMemberScrollbar180, details, detailWidth - 19, -memberTop, 14, math.max(54, capacity * 30 - 2))

    local actions = ui.raidTeamMemberActionButtons180 or {}
    local tierY = detailHeight - 58
    local roleY = detailHeight - 30
    local x = 12
    local tierOrder = { "remove", "core", "reserve", "guest" }
    for index = 1, table.getn(tierOrder) do
        local button = actions[tierOrder[index]]
        if button then Move(button, details, x, -tierY, button:GetWidth(), 24) x = x + button:GetWidth() + 5 end
    end
    x = 12
    local roleOrder = { "flexible", "tank", "healer", "damage" }
    for index = 1, table.getn(roleOrder) do
        local button = actions[roleOrder[index]]
        if button then Move(button, details, x, -roleY, button:GetWidth(), 24) x = x + button:GetWidth() + 5 end
    end

    local picker = ui.raidTeamPicker180
    if picker then
        Move(ui.raidTeamPickerSearchBox180, picker, 20, -54, 230, 30)
        Move(ui.raidTeamPickerCategoryButton180, picker, 258, -54, 104, 30)
        Move(ui.raidTeamPickerClassButton180, picker, 370, -54, 110, 30)
        Move(ui.raidTeamPickerOnlineButton180, picker, 488, -54, 104, 30)
        Move(ui.raidTeamPickerSelectedButton180, picker, 20, -88, 108, 28)
        ui.raidTeamPickerVisibleRows180 = 10
        for index = 1, table.getn(ui.raidTeamPickerRows180 or {}) do
            row = ui.raidTeamPickerRows180[index]
            if index <= 10 then
                Move(row, picker, 20, -122 - ((index - 1) * 32), 560, 30)
                if row.classIcon180 then row.classIcon180:ClearAllPoints() row.classIcon180:SetPoint("LEFT", row, "LEFT", 7, 0) end
                Move(row.nameText, row, 31, -6, 188, 18)
                Move(row.metaText, row, 225, -6, 327, 18)
            else row:Hide() end
        end
        Move(ui.raidTeamPickerScrollbar180, picker, 584, -122, 14, 318)
        Move(ui.raidTeamPickerSelectedCount180, picker, 20, -458, 180, 24)
        Move(ui.raidTeamPickerAdd180, picker, 348, -480, 150, 32)
        Move(ui.raidTeamPickerCancel180, picker, 506, -480, 96, 32)
    end
end

-- Native Raid Event editor ---------------------------------------------------

local function RaidEditorMarkDirtyPack2(owner)
    local editor = owner.ui and owner.ui.raidEditorNative180
    if editor and not editor.otlLoading180 then editor.otlDirty180 = true end
end

local function RaidEditorLabelPack2(parent, text, x, y, width, gold)
    local label = UI.Text(parent, text, "GameFontNormalSmall", "LEFT")
    Move(label, parent, x, y, width, 18)
    if gold then label:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3]) end
    return label
end

local function RaidEditorSetScrollPack2(owner, value)
    local editor = owner.ui and owner.ui.raidEditorNative180
    if not editor then return end
    local maximum = math.max(0, (tonumber(editor.otlContentHeight180) or 640) - (tonumber(editor.otlViewportHeight180) or 500))
    editor.otlScroll180 = math.max(0, math.min(maximum, tonumber(value) or 0))
    if editor.viewport180 and editor.viewport180.SetVerticalScroll then editor.viewport180:SetVerticalScroll(editor.otlScroll180) end
    if editor.scrollbar180 and editor.scrollbar180.SetScrollMetrics180 then editor.scrollbar180:SetScrollMetrics180(editor.otlContentHeight180, editor.otlViewportHeight180, editor.otlScroll180) end
end

function OTLGM.__impl180.EnsureNativeRaidEventEditorPack2__impl1(self)
    local ui = self.ui
    if not ui or not ui.main then return false end
    if ui.raidEditorNative180 then return true end
    local legacy = ui.raidEditor156
    if legacy then legacy:Hide() ui.raidLegacyEditor156 = legacy end

    local editor = UI:Modal(ui.main, 720, 620)
    editor:SetPoint("CENTER", ui.main, "CENTER", 0, 0)
    editor.otlNonDangerModal180 = true
    editor.otlContentHeight180 = 650 editor.otlViewportHeight180 = 500 editor.otlScroll180 = 0
    ui.raidEditorNative180 = editor ui.raidEditor156 = editor
    if self.RegisterModal152 then self:RegisterModal152(editor) end

    ui.raidEditorTitle156 = UI.Text(editor, "CREATE RAID EVENT", "GameFontNormalLarge", "CENTER")
    Move(ui.raidEditorTitle156, editor, 20, -16, 680, 28)
    ui.raidEditorClose180 = UI:Button(editor, "X", 28, 24, function() self:CloseModal180(editor, "x") end, "danger")
    Move(ui.raidEditorClose180, editor, 680, -10, 28, 24)

    local viewport = CreateFrame("ScrollFrame", nil, editor)
    Move(viewport, editor, 18, -52, 664, 500)
    local content = CreateFrame("Frame", nil, viewport)
    content:SetWidth(646) content:SetHeight(editor.otlContentHeight180)
    if viewport.SetScrollChild then viewport:SetScrollChild(content) end
    editor.viewport180 = viewport editor.content180 = content
    editor.scrollbar180 = UI:Scrollbar(editor, 500, function(value) RaidEditorSetScrollPack2(self, value) end)
    Move(editor.scrollbar180, editor, 688, -52, 14, 500)
    SetWheel(viewport, function(delta) RaidEditorSetScrollPack2(self, (editor.otlScroll180 or 0) - ((tonumber(delta) or 0) * 38)) end)

    RaidEditorLabelPack2(content, "BASIC INFORMATION", 0, 0, 300, true)
    RaidEditorLabelPack2(content, "RAID NAME", 0, -24, 300)
    RaidEditorLabelPack2(content, "LOCATION / MEETING POINT", 326, -24, 300)
    ui.raidName156 = UI:EditBox(content, 310, 30, { placeholder = "Raid name", maxLetters = 48, changed = function() RaidEditorMarkDirtyPack2(self) end })
    ui.raidLocation156 = UI:EditBox(content, 320, 30, { placeholder = "Meeting point", maxLetters = 48, changed = function() RaidEditorMarkDirtyPack2(self) end })
    Move(ui.raidName156, content, 0, -42, 310, 30) Move(ui.raidLocation156, content, 326, -42, 320, 30)

    RaidEditorLabelPack2(content, "DATE AND TIME", 0, -82, 300, true)
    RaidEditorLabelPack2(content, "DAY OFFSET", 0, -106, 100)
    ui.raidDay156 = UI:EditBox(content, 52, 30, { placeholder = "0", maxLetters = 2, changed = function() RaidEditorMarkDirtyPack2(self) self:RefreshRaidDatePreview157() end })
    Move(ui.raidDay156, content, 0, -124, 52, 30)
    ui.raidToday180 = UI:Button(content, "Today", 66, 30, function() ui.raidDay156:SetText("0") end, "utility")
    ui.raidTomorrow180 = UI:Button(content, "Tomorrow", 78, 30, function() ui.raidDay156:SetText("1") end, "utility")
    ui.raidWeek180 = UI:Button(content, "+7 days", 72, 30, function() ui.raidDay156:SetText("7") end, "utility")
    Move(ui.raidToday180, content, 60, -124, 66, 30) Move(ui.raidTomorrow180, content, 132, -124, 78, 30) Move(ui.raidWeek180, content, 216, -124, 72, 30)
    RaidEditorLabelPack2(content, "START ST", 326, -106, 90) RaidEditorLabelPack2(content, "GATHER ST", 488, -106, 90)
    ui.raidHour156 = UI:EditBox(content, 44, 30, { placeholder = "20", maxLetters = 2, changed = function() RaidEditorMarkDirtyPack2(self) self:RefreshRaidDatePreview157() end })
    ui.raidMinute156 = UI:EditBox(content, 44, 30, { placeholder = "00", maxLetters = 2, changed = function() RaidEditorMarkDirtyPack2(self) self:RefreshRaidDatePreview157() end })
    ui.raidGatherHour156 = UI:EditBox(content, 44, 30, { placeholder = "19", maxLetters = 2, changed = function() RaidEditorMarkDirtyPack2(self) self:RefreshRaidDatePreview157() end })
    ui.raidGatherMinute156 = UI:EditBox(content, 44, 30, { placeholder = "45", maxLetters = 2, changed = function() RaidEditorMarkDirtyPack2(self) self:RefreshRaidDatePreview157() end })
    Move(ui.raidHour156, content, 326, -124, 44, 30) Move(ui.raidMinute156, content, 378, -124, 44, 30)
    Move(ui.raidGatherHour156, content, 488, -124, 44, 30) Move(ui.raidGatherMinute156, content, 540, -124, 44, 30)
    ui.raidDatePreview157 = UI.Text(content, "", "GameFontNormalSmall", "LEFT")
    ui.raidDatePreview157:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    Move(ui.raidDatePreview157, content, 0, -160, 646, 20)

    RaidEditorLabelPack2(content, "BRIEFING", 0, -190, 300, true)
    ui.raidNote156 = UI:EditBox(content, 646, 78, { placeholder = "Raid briefing and preparation notes", maxLetters = 220, multiline = true, changed = function() RaidEditorMarkDirtyPack2(self) end })
    Move(ui.raidNote156, content, 0, -212, 646, 78)

    RaidEditorLabelPack2(content, "EVENT ROSTER", 0, -304, 300, true)
    ui.raidRosterMode180 = "CUSTOM"
    ui.raidRosterModeCustom180 = UI:Button(content, "Custom / Keep", 118, 28, function() ui.raidRosterMode180 = ui.raidEditor156.editId156 and "KEEP" or "CUSTOM" ui.raidRosterSourceId180 = nil RaidEditorMarkDirtyPack2(self) self:RefreshRaidRosterEditor180() end, "filter")
    ui.raidRosterModeTeam180 = UI:Button(content, "Use Raid Team", 118, 28, function()
        self:OpenRaidRosterSourceSelector180("TEAM")
    end, "filter")
    ui.raidRosterModeClone180 = UI:Button(content, "Clone Previous", 118, 28, function()
        self:OpenRaidRosterSourceSelector180("CLONE_PREVIOUS")
    end, "filter")
    Move(ui.raidRosterModeCustom180, content, 0, -326, 118, 28) Move(ui.raidRosterModeTeam180, content, 126, -326, 118, 28) Move(ui.raidRosterModeClone180, content, 252, -326, 118, 28)
    ui.raidRosterSourceButton180 = UI:Button(content, "Custom roster", 474, 28, function() self:CycleRaidRosterSource180() RaidEditorMarkDirtyPack2(self) end, "utility")
    ui.raidRosterCustomEdit180 = UI:Button(content, "Edit Custom Roster", 162, 28, function() self:OpenCustomRaidRosterPicker180() end, "utility")
    Move(ui.raidRosterSourceButton180, content, 0, -362, 474, 28) Move(ui.raidRosterCustomEdit180, content, 484, -362, 162, 28)
    ui.raidRosterPreview180 = UI.Text(content, "Event roster preview", "GameFontNormalSmall", "LEFT")
    Move(ui.raidRosterPreview180, content, 0, -396, 646, 18)
    ui.raidRosterHelp180 = UI.Text(content, "The selected team roster is copied into this event. Later team changes do not update this event automatically.", "GameFontNormalSmall", "LEFT")
    ui.raidRosterHelp180:SetTextColor(C.grey[1], C.grey[2], C.grey[3]) ui.raidRosterHelp180:SetHeight(32) ui.raidRosterHelp180:SetJustifyV("TOP")
    Move(ui.raidRosterHelp180, content, 0, -418, 646, 32)

    RaidEditorLabelPack2(content, "LEADERSHIP AND INVITES", 0, -458, 300, true)
    RaidEditorLabelPack2(content, "RAID LEADER", 0, -482, 200) RaidEditorLabelPack2(content, "MAIN INVITE CONTACT", 218, -482, 200) RaidEditorLabelPack2(content, "INVITE HELPERS", 436, -482, 210)
    ui.raidLeader175 = UI:EditBox(content, 202, 30, { placeholder = "Raid Leader", maxLetters = 32, changed = function() RaidEditorMarkDirtyPack2(self) end })
    ui.raidInviteContact175 = UI:EditBox(content, 202, 30, { placeholder = "Invite contact", maxLetters = 32, changed = function() RaidEditorMarkDirtyPack2(self) end })
    ui.raidInviteHelpers175 = UI:EditBox(content, 210, 30, { placeholder = "Helpers, comma separated", maxLetters = 96, changed = function() RaidEditorMarkDirtyPack2(self) end })
    Move(ui.raidLeader175, content, 0, -500, 202, 30) Move(ui.raidInviteContact175, content, 218, -500, 202, 30) Move(ui.raidInviteHelpers175, content, 436, -500, 210, 30)

    RaidEditorLabelPack2(content, "NOTIFICATION", 0, -548, 300, true)
    RaidEditorLabelPack2(content, "REMINDER MINUTES", 0, -572, 140)
    ui.raidReminder156 = UI:EditBox(content, 72, 30, { placeholder = "60", maxLetters = 4, changed = function() RaidEditorMarkDirtyPack2(self) end })
    Move(ui.raidReminder156, content, 0, -590, 72, 30)
    ui.raidRecurring156 = "ONCE"
    ui.raidRecurringButton156 = UI:Button(content, "One Time", 112, 30, function()
        ui.raidRecurring156 = ui.raidRecurring156 == "WEEKLY" and "ONCE" or "WEEKLY"
        UI:SetText(ui.raidRecurringButton156, ui.raidRecurring156 == "WEEKLY" and "Weekly" or "One Time")
        UI:SetSelected(ui.raidRecurringButton156, ui.raidRecurring156 == "WEEKLY") RaidEditorMarkDirtyPack2(self)
    end, "filter")
    ui.raidFeatured157 = false
    ui.raidFeaturedButton157 = UI:Button(content, "Main Raid: Off", 128, 30, function()
        ui.raidFeatured157 = not ui.raidFeatured157
        UI:SetText(ui.raidFeaturedButton157, ui.raidFeatured157 and "Main Raid: On" or "Main Raid: Off")
        UI:SetSelected(ui.raidFeaturedButton157, ui.raidFeatured157) RaidEditorMarkDirtyPack2(self)
    end, "filter")
    Move(ui.raidRecurringButton156, content, 92, -590, 112, 30) Move(ui.raidFeaturedButton157, content, 214, -590, 128, 30)

    ui.raidSave156 = UI:Button(editor, "Create Event", 132, 34, function() self:SaveRaidEditor156() end, "primary")
    ui.raidEditorCancel156 = UI:Button(editor, "Cancel", 100, 34, function() self:CloseModal180(editor, "cancel") end, "secondary")
    Move(ui.raidEditorCancel156, editor, 460, -574, 100, 34) Move(ui.raidSave156, editor, 570, -574, 132, 34)

    editor.otlBeforeClose180 = function(frame, reason)
        if not frame.otlDirty180 then return true end
        if frame.otlDiscardPrompt180 then return false end
        frame.otlDiscardPrompt180 = true
        self:ShowConfirm("Discard changes?", "Close the Raid Event editor and discard the current changes?", "Discard", function()
            frame.otlDiscardPrompt180 = nil frame.otlDirty180 = nil frame.otlForceClose180 = true
            local uiState = self.ui or {}
            local childModals = { uiState.raidRosterSourceSelector180, uiState.eventRosterDraftEditor180, uiState.raidTeamPicker180 }
            local childIndex
            for childIndex = 1, table.getn(childModals) do
                local child = childModals[childIndex]
                if child and child ~= frame and child.IsVisible and child:IsVisible() then
                    child.otlForceClose180 = true
                    self:CloseModal180(child, "parent-editor-discard")
                end
            end
            self:CloseModal180(frame, "discard-confirmed")
        end, function()
            frame.otlDiscardPrompt180 = nil
        end)
        return false
    end
    RaidEditorSetScrollPack2(self, 0)
    return true
end

function OTLGM:RefreshRaidDatePreview157()
    local ui = self.ui
    if not ui or not ui.raidDatePreview157 then return false end
    local dayOffset = math.max(0, math.min(60, tonumber(ui.raidDay156 and ui.raidDay156:GetText()) or 0))
    local hour = math.max(0, math.min(23, tonumber(ui.raidHour156 and ui.raidHour156:GetText()) or 20))
    local minute = math.max(0, math.min(59, tonumber(ui.raidMinute156 and ui.raidMinute156:GetText()) or 0))
    local now = self:Now()
    local target
    if self.GetServerDayStart180 then
        target = self:GetServerDayStart180(now, dayOffset) + (hour * 3600) + (minute * 60)
    else
        local serverHour, serverMinute = 0, 0
        if GetGameTime then serverHour, serverMinute = GetGameTime() end
        serverHour = tonumber(serverHour) or tonumber(date("%H", now)) or 0
        serverMinute = tonumber(serverMinute) or tonumber(date("%M", now)) or 0
        target = now - ((serverHour * 3600) + (serverMinute * 60)) + (dayOffset * 86400) + (hour * 3600) + (minute * 60)
    end
    if target <= now and dayOffset == 0 then target = target + 86400 end
    local serverDate = self.FormatServerDate180 and self:FormatServerDate180(target, "%A, %d %B %Y") or date("%A, %d %B %Y", target)
    ui.raidDatePreview157:SetText(serverDate .. "  •  " .. string.format("%02d:%02d ST", hour, minute))
    return true
end

function OTLGM:OpenRaidEditor156(raid, duplicate)
    if not self.ui or not self.ui.main then self:BuildUI() end
    if self.ui and ((self.ui.raidTeamEditor180 and self.ui.raidTeamEditor180:IsVisible()) or (self.ui.raidTeamPicker180 and self.ui.raidTeamPicker180:IsVisible())) then
        if self.SetStatus then self:SetStatus("Close the active Raid Team window before opening the Raid Event editor.") end
        return false, "raid-team-modal-active"
    end
    if not self.ui or not self.ui.raidPlanner156 then self:ShowPage("pve") end
    self:EnsureNativeRaidEventEditorPack2()
    local ui = self.ui local editor = ui.raidEditorNative180
    if not editor then return false end
    editor.otlLoading180 = true editor.otlDirty180 = nil editor.otlDiscardPrompt180 = nil
    local editing = raid and not duplicate
    editor.editId156 = editing and raid.id or nil
    ui.raidEditorTitle156:SetText(editing and "EDIT RAID EVENT" or (duplicate and "DUPLICATE RAID EVENT" or "CREATE RAID EVENT"))
    UI:SetText(ui.raidSave156, editing and "Save Changes" or "Create Event")
    ui.raidName156:SetText(raid and raid.name or "") ui.raidLocation156:SetText(raid and raid.location or "")
    local dayOffset = 0
    if raid and raid.startTs then dayOffset = math.max(0, self.GetServerDayOffset180 and self:GetServerDayOffset180(raid.startTs, self:Now()) or math.floor(((tonumber(raid.startTs) or self:Now()) - self:Now()) / 86400 + 0.5)) end
    ui.raidDay156:SetText(tostring(dayOffset))
    ui.raidHour156:SetText(string.format("%02d", raid and tonumber(raid.stHour) or 20))
    ui.raidMinute156:SetText(string.format("%02d", raid and tonumber(raid.stMinute) or 0))
    ui.raidGatherHour156:SetText(string.format("%02d", raid and tonumber(raid.gatherHour) or 19))
    ui.raidGatherMinute156:SetText(string.format("%02d", raid and tonumber(raid.gatherMinute) or 45))
    ui.raidNote156:SetText(raid and raid.note or "")
    ui.raidLeader175:SetText(raid and (raid.raidLeader or raid.author) or (UnitName("player") or ""))
    ui.raidInviteContact175:SetText(raid and (raid.inviteContact or raid.raidLeader or raid.author) or (UnitName("player") or ""))
    ui.raidInviteHelpers175:SetText(raid and raid.inviteHelpers or "")
    ui.raidReminder156:SetText(tostring(raid and raid.reminderMinutes or 60))
    ui.raidRecurring156 = raid and raid.recurring == "WEEKLY" and "WEEKLY" or "ONCE"
    UI:SetText(ui.raidRecurringButton156, ui.raidRecurring156 == "WEEKLY" and "Weekly" or "One Time") UI:SetSelected(ui.raidRecurringButton156, ui.raidRecurring156 == "WEEKLY")
    ui.raidFeatured157 = raid and raid.featured and true or false
    UI:SetText(ui.raidFeaturedButton157, ui.raidFeatured157 and "Main Raid: On" or "Main Raid: Off") UI:SetSelected(ui.raidFeaturedButton157, ui.raidFeatured157)
    ui.raidVisibility180 = raid and raid.visibility180 or "GUILD_VISIBLE"
    ui.raidNotifyAudience180 = raid and raid.notifyAudience180 or "ASSIGNED"
    local visibilityLabels = { PRIVATE_TEAM = "Private Team", GUILD_VISIBLE = "Guild Visible", OPEN_GUILD = "Open Guild" }
    local audienceLabels = { ASSIGNED = "Assigned", ASSIGNED_RESERVES = "Assigned + Reserves", ENTIRE_TEAM = "Entire Team", ALL_GUILD = "All Guild" }
    if ui.raidVisibilityButton180 then UI:SetText(ui.raidVisibilityButton180, visibilityLabels[ui.raidVisibility180] or "Guild Visible") end
    if ui.raidNotifyAudienceButton180 then UI:SetText(ui.raidNotifyAudienceButton180, audienceLabels[ui.raidNotifyAudience180] or "Assigned") end
    if ui.raidDiscordUrl180 then ui.raidDiscordUrl180:SetText(raid and raid.discordUrl180 or "") end
    if ui.raidSignUpNote180 then ui.raidSignUpNote180:SetText(raid and raid.signUpNote180 or "") end
    self:PrepareRaidRosterEditor180(raid, duplicate)
    self:RefreshRaidDatePreview157()
    editor.otlLoading180 = nil editor.otlDirty180 = nil
    RaidEditorSetScrollPack2(self, 0)
    if self.ShowModal152 then self:ShowModal152(editor) else editor:Show() end
    return true
end

function OTLGM.__impl180.SaveRaidEditor156__impl3(self)
    local ui = self.ui
    local editor = ui and ui.raidEditorNative180
    if not editor then return false end
    local rosterMode = ui.raidRosterMode180 or (editor.editId156 and "KEEP" or "CUSTOM")
    local eventDraft = ui.eventRosterDraft180
    if (rosterMode == "TEAM" or rosterMode == "CLONE_PREVIOUS") and not ui.eventRosterDraftInitialized180
        and (type(eventDraft) ~= "table" or not next(eventDraft)) then
        eventDraft = nil
    end
    local data = {
        name = ui.raidName156:GetText(), location = ui.raidLocation156:GetText(), note = ui.raidNote156:GetText(),
        dayOffset = ui.raidDay156:GetText(), hour = ui.raidHour156:GetText(), minute = ui.raidMinute156:GetText(),
        gatherHour = ui.raidGatherHour156:GetText(), gatherMinute = ui.raidGatherMinute156:GetText(),
        recurring = ui.raidRecurring156, reminderMinutes = ui.raidReminder156:GetText(), featured = ui.raidFeatured157,
        raidLeader = ui.raidLeader175:GetText(), inviteContact = ui.raidInviteContact175:GetText(), inviteHelpers = ui.raidInviteHelpers175:GetText(),
        rosterMode180 = ui.raidRosterMode180 or (editor.editId156 and "KEEP" or "CUSTOM"),
        rosterSourceId180 = ui.raidRosterSourceId180, customRoster180 = ui.raidCustomRoster180,
    }
    local editId = editor.editId156
    if data.rosterMode180 == "TEAM" then
        local source = self:GetRaidTeam180(data.rosterSourceId180)
        if not source or source.status == "ARCHIVED" then
            ui.raidRosterMode180 = editId and "KEEP" or "CUSTOM" ui.raidRosterSourceId180 = nil
            self:RefreshRaidRosterEditor180()
            if self.SetStatus then self:SetStatus("The selected Raid Team is no longer available. Review the roster mode and save again.") end
            return false
        end
    elseif data.rosterMode180 == "CLONE_PREVIOUS" then
        local source = self:GetRaidRosterSourceEvent180(data.rosterSourceId180)
        if not source or type(source.roster180) ~= "table" or not next(source.roster180) then
            ui.raidRosterMode180 = editId and "KEEP" or "CUSTOM" ui.raidRosterSourceId180 = nil
            self:RefreshRaidRosterEditor180()
            if self.SetStatus then self:SetStatus("The previous roster source is no longer available. Review the roster mode and save again.") end
            return false
        end
    end
    local ok, result = self:PublishPveRaidEvent156(data, editId)
    if not ok then self:ShowNotice("Raid Event", result or "The raid event could not be saved.") return false end
    editor.otlDirty180 = nil editor.otlForceClose180 = true
    self:CloseModal180(editor, "save-success")
    ui.raidFilter156 = "UPCOMING" ui.raidSelected156 = result.id
    self:SetPveRaidAreaMode180("EVENTS") self:RefreshRaidPlanner156()
    self:SetStatus(editId and "Raid event updated." or "New raid event created.")
    return true, result
end

-- Ensure the PACK 2 controls are added as soon as the native PvE page exists.
local PreviousOpenRaidTeamNativePack2 = OTLGM.__impl180.OpenRaidTeamNative180__impl1
function OTLGM:OpenRaidTeamNative180(teamId, options)
    local result, problem = PreviousOpenRaidTeamNativePack2(self, teamId, options)
    if self.ui and self.ui.raidTeamsPanel180 then self:EnsureRaidTeamPack2Controls180() self:RefreshRaidTeamsPanel180() end
    return result, problem
end


-- ---------------------------------------------------------------------------
-- C5-R4 PACK 1: canonical Raid Team dashboard, explicit event roster source
-- selectors, independent event-roster draft, and width-safe chat reflow.
-- This code lives in NativePages.lua intentionally; no release/hotfix/overlay
-- file or SavedVariables schema change is introduced.
-- ---------------------------------------------------------------------------

local function C5R4Copy180(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    local key, item
    for key, item in pairs(value) do copy[C5R4Copy180(key, seen)] = C5R4Copy180(item, seen) end
    return copy
end

local function C5R4Role180(member)
    local role = string.upper(tostring(member and (member.mainRole or member.role) or "UNASSIGNED"))
    if role ~= "TANK" and role ~= "HEALER" and role ~= "DAMAGE" then role = "UNASSIGNED" end
    return role
end

local function C5R4Offspec180(member)
    local role = string.upper(tostring(member and member.offspecRole or "NONE"))
    if role ~= "TANK" and role ~= "HEALER" and role ~= "DAMAGE" then role = "NONE" end
    if role == C5R4Role180(member) then role = "NONE" end
    return role
end

local C5R4_ROLE_ASSETS180 = {
    TANK = "Interface\\AddOns\\OrderOfTheLionGM\\Assets\\Roles\\Tank",
    HEALER = "Interface\\AddOns\\OrderOfTheLionGM\\Assets\\Roles\\Healer",
    DAMAGE = "Interface\\AddOns\\OrderOfTheLionGM\\Assets\\Roles\\Damage",
    UNASSIGNED = "Interface\\AddOns\\OrderOfTheLionGM\\Assets\\Roles\\Review",
}

function OTLGM:ResolveRoleIcon180(role)
    role = string.upper(tostring(role or "UNASSIGNED"))
    if not C5R4_ROLE_ASSETS180[role] then role = "UNASSIGNED" end
    return C5R4_ROLE_ASSETS180[role], { 0, 1, 0, 1 }, C5R4_ROLE_ASSETS180.UNASSIGNED
end

local function C5R4ApplyRoleIcon180(owner, texture, role)
    if not texture then return end
    local path, coords, fallback = owner:ResolveRoleIcon180(role)
    texture:SetTexture(path or fallback)
    if coords then texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4]) else texture:SetTexCoord(0, 1, 0, 1) end
    texture:SetVertexColor(1, 1, 1)
end

local function C5R4Name180(value)
    return string.lower(string.gsub(tostring(value or ""), "%-.*$", ""))
end

local function C5R4RoleLabel180(role)
    role = string.upper(tostring(role or "UNASSIGNED"))
    if role == "TANK" then return "Tank" end
    if role == "HEALER" then return "Healer" end
    if role == "DAMAGE" then return "Damage" end
    return "Role needs review"
end

local function C5R4NamesText180(names)
    if type(names) ~= "table" or table.getn(names) == 0 then return "None" end
    return table.concat(names, ", ")
end

-- Interface 11200 uses the Lua 5.0 string library.  Keep parsing local and
-- explicit instead of installing a global 5.1 compatibility alias.
local function SplitCommaList180(text, maximum)
    local result, seen = {}, {}
    local iterator = string.gfind and string.gfind(tostring(text or ""), "[^,]+") or nil
    if not iterator then return result end
    local value
    for value in iterator do
        value = string.gsub(value, "^%s+", "")
        value = string.gsub(value, "%s+$", "")
        local key = string.lower(value)
        if value ~= "" and not seen[key] then
            seen[key] = true
            table.insert(result, value)
            if maximum and table.getn(result) >= maximum then break end
        end
    end
    return result
end

local C5R4_ROLE_SECTION_ORDER180 = { "TANK", "HEALER", "DAMAGE", "UNASSIGNED" }
local C5R4_ROLE_SECTION_LABELS180 = {
    TANK = "Tanks", HEALER = "Healers", DAMAGE = "Damage", UNASSIGNED = "Needs Review",
}
local C5R4_TIER_ORDER180 = { CORE = 1, RESERVE = 2, GUEST = 3 }

local function C5R4SortRoleMembers180(left, right)
    if left.otlOnline180 ~= right.otlOnline180 then return left.otlOnline180 end
    local lt = C5R4_TIER_ORDER180[string.upper(tostring(left.tier or ""))] or 4
    local rt = C5R4_TIER_ORDER180[string.upper(tostring(right.tier or ""))] or 4
    if lt ~= rt then return lt < rt end
    return C5R4Name180(left.character) < C5R4Name180(right.character)
end

local function C5R4TeamMembers180(owner, team, ui)
    owner.runtime = owner.runtime or {}
    owner.runtime.raidTeamMemberCache180 = owner.runtime.raidTeamMemberCache180 or {}
    local query = string.lower(tostring(ui.raidTeamRosterSearch180 or ""))
    local roleFilter = string.upper(tostring(ui.raidTeamRosterRoleFilter180 or "ALL"))
    local tierFilter = string.upper(tostring(ui.raidTeamRosterTierFilter180 or "ALL"))
    local onlineOnly = ui.raidTeamRosterOnlineOnly180 and true or false
    local onlineParts, key, member = {}, nil, nil
    for key, member in pairs(team and team.members or {}) do
        local rosterMember = owner:GetMember(member.character)
        table.insert(onlineParts, tostring(key) .. ":" .. (rosterMember and rosterMember.online and "1" or "0"))
    end
    table.sort(onlineParts)
    local signature = table.concat({ tostring(team and team.id or ""), tostring(team and team.rev or 0), query, roleFilter, tierFilter, onlineOnly and "1" or "0", table.concat(onlineParts, ",") }, "|")
    local cached = owner.runtime.raidTeamMemberCache180[team and team.id or ""]
    if cached and cached.signature == signature then
        owner.runtime.raidTeamRefreshMetrics180 = owner.runtime.raidTeamRefreshMetrics180 or {}
        owner.runtime.raidTeamRefreshMetrics180.rosterCacheHits = (tonumber(owner.runtime.raidTeamRefreshMetrics180.rosterCacheHits) or 0) + 1
        return cached.rows
    end

    local groups = { TANK = {}, HEALER = {}, DAMAGE = {}, UNASSIGNED = {} }
    local _, sourceMember
    for _, sourceMember in pairs(team and team.members or {}) do
        local rosterMember = owner:GetMember(sourceMember.character)
        local online = rosterMember and rosterMember.online and true or false
        local role = C5R4Role180(sourceMember)
        local tier = string.upper(tostring(sourceMember.tier or "GUEST"))
        local allowed = query == "" or string.find(string.lower(tostring(sourceMember.character or "")), query, 1, true)
        if allowed and roleFilter ~= "ALL" and role ~= roleFilter then allowed = false end
        if allowed and tierFilter ~= "ALL" and tier ~= tierFilter then allowed = false end
        if allowed and onlineOnly and not online then allowed = false end
        if allowed then
            local entry = C5R4Copy180(sourceMember)
            entry.otlOnline180 = online
            entry.otlRosterMember180 = rosterMember
            table.insert(groups[role] or groups.UNASSIGNED, entry)
        end
    end

    local rows, sectionIndex = {}, 1
    for sectionIndex = 1, table.getn(C5R4_ROLE_SECTION_ORDER180) do
        local role = C5R4_ROLE_SECTION_ORDER180[sectionIndex]
        local members = groups[role]
        table.sort(members, C5R4SortRoleMembers180)
        if table.getn(members) > 0 then
            local onlineCount, memberIndex = 0, 1
            for memberIndex = 1, table.getn(members) do if members[memberIndex].otlOnline180 then onlineCount = onlineCount + 1 end end
            table.insert(rows, {
                otlHeader180 = true, role180 = role,
                title = C5R4_ROLE_SECTION_LABELS180[role], count180 = table.getn(members), online180 = onlineCount,
            })
            for memberIndex = 1, table.getn(members) do table.insert(rows, members[memberIndex]) end
        end
    end
    owner.runtime.raidTeamMemberCache180[team and team.id or ""] = { signature = signature, rows = rows }
    owner.runtime.raidTeamRefreshMetrics180 = owner.runtime.raidTeamRefreshMetrics180 or {}
    owner.runtime.raidTeamRefreshMetrics180.rosterBuilds = (tonumber(owner.runtime.raidTeamRefreshMetrics180.rosterBuilds) or 0) + 1
    return rows
end

function OTLGM:ClearRaidTeamMemberSelection180(reason, refresh)
    local ui = self.ui
    if not ui then return false end
    local hadSelection = false
    local _, selected
    for _, selected in pairs(ui.raidTeamMemberSelection180 or {}) do if selected then hadSelection = true break end end
    ui.raidTeamMemberSelection180 = {}
    ui.raidTeamSelectionReason180 = reason
    local catcher = ui.raidTeamSelectionCatcher180
    if catcher and catcher:IsVisible() then
        ui.raidTeamSelectionCatcherProgrammatic180 = true
        catcher:Hide()
        ui.raidTeamSelectionCatcherProgrammatic180 = nil
    end
    if refresh and hadSelection and self.RefreshRaidTeamsPanel180 then self:RefreshRaidTeamsPanel180() end
    return hadSelection
end

local function C5R4RaidInviteTarget180(owner, team)
    if not team then return nil, "No Raid Team is selected." end
    local target = tostring(team.inviteContact or "")
    if target == "" then target = tostring(team.raidLeader or "") end
    if target == "" then return nil, "No Invite Contact or Raid Leader is assigned." end
    local player = C5R4Name180(UnitName and UnitName("player") or "")
    if C5R4Name180(target) == player then return target, "You are the Invite Contact." end
    local member = owner.GetMember and owner:GetMember(target) or nil
    if not member or not member.online then return target, "The Invite Contact is offline." end
    return target, nil
end

function OTLGM:RequestRaidTeamInvite180()
    local ui = self.ui
    local team = ui and self:GetRaidTeam180(ui.raidTeamSelectedId180)
    if not team or team.status == "ARCHIVED" then return false, "No active Raid Team is selected." end
    if not self:GetRaidTeamMembership180(team) then return false, "You are not a member of this Raid Team." end
    local target, problem = C5R4RaidInviteTarget180(self, team)
    if problem then return false, problem end
    self.runtime = self.runtime or {}
    self.runtime.raidTeamInviteRequestCooldown180 = self.runtime.raidTeamInviteRequestCooldown180 or {}
    local key = tostring(team.id or "") .. ":" .. C5R4Name180(target)
    local now = self:Now()
    local previous = tonumber(self.runtime.raidTeamInviteRequestCooldown180[key]) or 0
    if now - previous < 10 then return false, "An invite request was just sent." end
    if type(SendChatMessage) ~= "function" then return false, "Whispers are not available right now." end
    local text = "Hi, can I get an invite for " .. tostring(team.name or "this Raid Team") .. "?"
    local ok, errorText = pcall(SendChatMessage, text, "WHISPER", nil, target)
    if not ok then return false, tostring(errorText or "Invite request failed.") end
    self.runtime.raidTeamInviteRequestCooldown180[key] = now
    if ui.raidTeamInviteRequestStatus180 then
        ui.raidTeamInviteRequestStatus180:SetText("Invite request sent to " .. string.gsub(target, "%-.*$", "") .. ".")
        ui.raidTeamInviteRequestStatus180.otlDataVisible180 = true
    end
    if self.ScheduleAfter180 then
        self:ScheduleAfter180("raid-team-invite-request:" .. key, 10, function(owner)
            if owner.ui then owner.ui.raidTeamRefreshSignature180 = nil end
            if owner.ui and owner.ui.currentPage == "pve" and owner.ui.pveRaidAreaMode180 == "TEAMS" then owner:RefreshRaidTeamsPanel180() end
        end, 20)
    end
    self:RefreshRaidTeamsPanel180()
    return true, target
end

function OTLGM:ApplyRaidTeamDetailsVisibility180(mode, team, canManage, canCreate)
    local ui = self.ui
    if not ui then return false end
    mode = mode == "ROSTER" and "ROSTER" or "OVERVIEW"
    local hasTeam = team and true or false
    local function apply(control, visible)
        if not control then return end
        local shouldShow = visible and control.otlDataVisible180 ~= false
        if shouldShow then
            control:Show()
        else
            if control == ui.raidTeamSelectionCatcher180 then
                ui.raidTeamSelectionCatcherProgrammatic180 = true
                control:Hide()
                ui.raidTeamSelectionCatcherProgrammatic180 = nil
            else
                control:Hide()
            end
        end
    end
    apply(ui.raidTeamDetailTitle180, true)
    apply(ui.raidTeamDetailMeta180, true)
    apply(ui.raidTeamOverviewTab180, true)
    apply(ui.raidTeamRosterTab180, true)

    local overviewControls = {
        ui.raidTeamDetailDescription180, ui.raidTeamPersonalStatus180, ui.raidTeamPrimaryBadge180,
        ui.raidTeamOnlineSummary180, ui.raidTeamContactSummary180, ui.raidTeamHelpersSummary180,
        ui.raidTeamSelfContact180, ui.raidTeamWhisperLeader180, ui.raidTeamWhisperContact180,
        ui.raidTeamAskInvite180, ui.raidTeamInviteRequestStatus180, ui.raidTeamNextRaid180,
        ui.raidTeamOpenNextRaid180, ui.raidTeamSetPrimary180, ui.raidTeamUnassigned180,
    }
    local index
    for index = 1, table.getn(overviewControls) do apply(overviewControls[index], hasTeam and mode == "OVERVIEW") end
    for _, card in pairs(ui.raidTeamRoleCards180 or {}) do apply(card, hasTeam and mode == "OVERVIEW") end
    for index = 1, table.getn(ui.raidTeamHelperButtons180 or {}) do apply(ui.raidTeamHelperButtons180[index], hasTeam and mode == "OVERVIEW") end

    local rosterControls = {
        ui.raidTeamRosterSearchBox180, ui.raidTeamRosterRoleButton180, ui.raidTeamRosterTierButton180,
        ui.raidTeamRosterOnlineButton180, ui.raidTeamRosterClearFiltersR2, ui.raidTeamMemberScrollbar180,
    }
    for index = 1, table.getn(rosterControls) do apply(rosterControls[index], hasTeam and mode == "ROSTER") end
    for index = 1, table.getn(ui.raidTeamMemberRows180 or {}) do
        local row = ui.raidTeamMemberRows180[index]
        if mode ~= "ROSTER" then row:Hide() end
    end
    apply(ui.raidTeamAddMembers180, hasTeam and mode == "ROSTER" and canManage)
    local actions = ui.raidTeamMemberActionButtons180 or {}
    for _, button in pairs(actions) do
        if button then apply(button, hasTeam and mode == "ROSTER" and canManage and button.otlActionVisible180 ~= false) end
    end
    local selectedCount = table.getn(RaidTeamSelectionList180(ui.raidTeamMemberSelection180 or {}))
    apply(ui.raidTeamSelectionCatcher180, hasTeam and mode == "ROSTER" and selectedCount > 0)
    if ui.raidTeamClearSelection180 then
        ui.raidTeamClearSelection180.otlDataVisible180 = selectedCount > 0
        UI:SetText(ui.raidTeamClearSelection180, "Clear selection (" .. tostring(selectedCount) .. ")")
        apply(ui.raidTeamClearSelection180, hasTeam and mode == "ROSTER")
    end
    return true
end

local function C5R4SetTeamTab180(owner, mode)
    local ui = owner.ui
    if not ui then return end
    mode = mode == "ROSTER" and "ROSTER" or "OVERVIEW"
    if ui.raidTeamInnerTab180 ~= mode and owner.ClearRaidTeamMemberSelection180 then owner:ClearRaidTeamMemberSelection180("tab-change", false) end
    ui.raidTeamInnerTab180 = mode
    UI:SetSelected(ui.raidTeamOverviewTab180, mode == "OVERVIEW")
    UI:SetSelected(ui.raidTeamRosterTab180, mode == "ROSTER")
    ui.raidTeamMemberOffset180 = 0
    owner:RefreshRaidTeamsPanel180()
end

local PreviousEnsureRaidTeamPack2ControlsC5R4 = OTLGM.__impl180.EnsureRaidTeamPack2Controls180__impl1
function OTLGM:EnsureRaidTeamPack2Controls180()
    if PreviousEnsureRaidTeamPack2ControlsC5R4 then PreviousEnsureRaidTeamPack2ControlsC5R4(self) end
    local ui = self.ui
    if not ui or not ui.raidTeamDetailsPanel180 or ui.raidTeamC5R4Controls180 then return false end
    ui.raidTeamC5R4Controls180 = true
    local details = ui.raidTeamDetailsPanel180
    ui.raidTeamInnerTab180 = ui.raidTeamInnerTab180 or "OVERVIEW"
    ui.raidTeamOverviewTab180 = UI:Tab(details, "Overview", 96, function() C5R4SetTeamTab180(self, "OVERVIEW") end)
    ui.raidTeamRosterTab180 = UI:Tab(details, "Roster", 90, function() C5R4SetTeamTab180(self, "ROSTER") end)
    ui.raidTeamRosterSearchBox180 = UI:SearchBox(details, 170, 26, "Search members...", function(value)
        if self.ClearRaidTeamMemberSelection180 then self:ClearRaidTeamMemberSelection180("search-change", false) end
        ui.raidTeamRosterSearch180 = value or "" ui.raidTeamMemberOffset180 = 0 self:RefreshRaidTeamsPanel180()
    end)
    ui.raidTeamRosterRoleFilter180 = "ALL"
    ui.raidTeamRosterRoleButton180 = UI:Button(details, "Role: All", 94, 26, function()
        local order = { "ALL", "TANK", "HEALER", "DAMAGE", "UNASSIGNED" }
        local current, nextRole, index = ui.raidTeamRosterRoleFilter180 or "ALL", "ALL", 1
        for index = 1, table.getn(order) do if order[index] == current then nextRole = order[math.mod(index, table.getn(order)) + 1] break end end
        if self.ClearRaidTeamMemberSelection180 then self:ClearRaidTeamMemberSelection180("role-filter-change", false) end
        ui.raidTeamRosterRoleFilter180 = nextRole ui.raidTeamMemberOffset180 = 0 self:RefreshRaidTeamsPanel180()
    end, "filter")
    ui.raidTeamRosterRoleButton180.roleIcon180 = ui.raidTeamRosterRoleButton180:CreateTexture(nil, "ARTWORK")
    ui.raidTeamRosterRoleButton180.roleIcon180:SetWidth(14) ui.raidTeamRosterRoleButton180.roleIcon180:SetHeight(14)
    ui.raidTeamRosterRoleButton180.roleIcon180:SetPoint("LEFT", ui.raidTeamRosterRoleButton180, "LEFT", 5, 0)
    ui.raidTeamRosterRoleButton180.roleIcon180:Hide()
    ui.raidTeamRosterTierFilter180 = "ALL"
    ui.raidTeamRosterTierButton180 = UI:Button(details, "Tier: All", 90, 26, function()
        local order = { "ALL", "CORE", "RESERVE", "GUEST" }
        local current, nextTier, index = ui.raidTeamRosterTierFilter180 or "ALL", "ALL", 1
        for index = 1, table.getn(order) do if order[index] == current then nextTier = order[math.mod(index, table.getn(order)) + 1] break end end
        if self.ClearRaidTeamMemberSelection180 then self:ClearRaidTeamMemberSelection180("tier-filter-change", false) end
        ui.raidTeamRosterTierFilter180 = nextTier ui.raidTeamMemberOffset180 = 0 self:RefreshRaidTeamsPanel180()
    end, "filter")
    ui.raidTeamRosterOnlineButton180 = UI:Button(details, "Online", 72, 26, function()
        if self.ClearRaidTeamMemberSelection180 then self:ClearRaidTeamMemberSelection180("online-filter-change", false) end
        ui.raidTeamRosterOnlineOnly180 = not ui.raidTeamRosterOnlineOnly180 ui.raidTeamMemberOffset180 = 0 self:RefreshRaidTeamsPanel180()
    end, "filter")
    ui.raidTeamRosterClearFiltersR2 = UI:Button(details, "Clear Filters", 96, 24, function()
        if self.ClearRaidTeamMemberSelection180 then self:ClearRaidTeamMemberSelection180("clear-filters", false) end
        ui.raidTeamRosterSearch180 = ""
        if ui.raidTeamRosterSearchBox180 and ui.raidTeamRosterSearchBox180.SetText then ui.raidTeamRosterSearchBox180:SetText("") end
        ui.raidTeamRosterRoleFilter180 = "ALL"
        ui.raidTeamRosterTierFilter180 = "ALL"
        ui.raidTeamRosterOnlineOnly180 = false
        ui.raidTeamMemberOffset180 = 0
        self:RefreshRaidTeamsPanel180()
    end, "utility")

    ui.raidTeamAskInvite180 = UI:Button(details, "Ask for Invite", 118, 24, function()
        local ok, problem = self:RequestRaidTeamInvite180()
        if not ok and self.SetStatus then self:SetStatus(problem or "Invite request was not sent.") end
    end, "primary")
    ui.raidTeamInviteRequestStatus180 = UI.Text(details, "", "GameFontNormalSmall", "LEFT")
    ui.raidTeamInviteRequestStatus180:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    ui.raidTeamInviteRequestStatus180.otlDataVisible180 = false
    ui.raidTeamClearSelection180 = UI:Button(details, "Clear selection", 126, 22, function()
        self:ClearRaidTeamMemberSelection180("button", true)
    end, "utility")
    local catcher = CreateFrame("Button", "OTLGM_RaidTeamSelectionCatcher180", details)
    catcher:EnableMouse(true)
    catcher:SetScript("OnClick", function() OTLGM:ClearRaidTeamMemberSelection180("free-space", true) end)
    catcher:SetScript("OnHide", function()
        if not OTLGM.ui or OTLGM.ui.raidTeamSelectionCatcherProgrammatic180 then return end
        local selection = OTLGM.ui.raidTeamMemberSelection180 or {}
        local _, selected
        for _, selected in pairs(selection) do
            if selected then OTLGM:ClearRaidTeamMemberSelection180("escape", true) return end
        end
    end)
    if catcher.SetFrameLevel and details.GetFrameLevel then catcher:SetFrameLevel(details:GetFrameLevel() + 1) end
    catcher:Hide()
    ui.raidTeamSelectionCatcher180 = catcher
    if UISpecialFrames then
        local found, specialIndex = false, 1
        for specialIndex = 1, table.getn(UISpecialFrames) do if UISpecialFrames[specialIndex] == "OTLGM_RaidTeamSelectionCatcher180" then found = true break end end
        if not found then table.insert(UISpecialFrames, "OTLGM_RaidTeamSelectionCatcher180") end
    end
    if ui.raidTeamRosterSearchBox180 and ui.raidTeamRosterSearchBox180.SetScript then
        local oldEscape = ui.raidTeamRosterSearchBox180.GetScript and ui.raidTeamRosterSearchBox180:GetScript("OnEscapePressed") or nil
        ui.raidTeamRosterSearchBox180:SetScript("OnEscapePressed", function()
            if OTLGM:ClearRaidTeamMemberSelection180("search-escape", true) then return end
            if oldEscape then oldEscape() elseif this.ClearFocus then this:ClearFocus() end
        end)
    end

    ui.raidTeamContactSummary180 = UI.Text(details, "", "GameFontNormalSmall", "LEFT")
    ui.raidTeamContactSummary180:SetJustifyV("TOP")
    ui.raidTeamHelpersSummary180 = UI.Text(details, "", "GameFontNormalSmall", "LEFT")
    ui.raidTeamHelpersSummary180:SetJustifyV("TOP")
    ui.raidTeamHelperButtons180 = {}
    local helperIndex
    for helperIndex = 1, 3 do
        ui.raidTeamHelperButtons180[helperIndex] = UI:Button(details, "Whisper Helper", 112, 22, function(button)
            if button.helperName180 and self.WhisperMember then self:WhisperMember(button.helperName180) end
        end, "utility")
    end

    ui.raidTeamRoleCards180 = {}
    local roles = { "TANK", "HEALER", "DAMAGE" }
    local roleIndex, role
    for roleIndex = 1, table.getn(roles) do
        role = roles[roleIndex]
        local captured = role
        local card = UI:Button(details, C5R4RoleLabel180(role), 112, 54, function()
            ui.raidTeamRosterRoleFilter180 = captured
            C5R4SetTeamTab180(self, "ROSTER")
        end, "secondary")
        card.roleIcon180 = card:CreateTexture(nil, "ARTWORK")
        card.roleIcon180:SetWidth(24) card.roleIcon180:SetHeight(24)
        card.roleIcon180:SetPoint("LEFT", card, "LEFT", 8, 0)
        card.text:ClearAllPoints() card.text:SetPoint("LEFT", card, "LEFT", 38, 0) card.text:SetWidth(68)
        C5R4ApplyRoleIcon180(self, card.roleIcon180, role)
        ui.raidTeamRoleCards180[role] = card
    end
    ui.raidTeamUnassigned180 = UI:Button(details, "Role needs review", 160, 24, function()
        ui.raidTeamRosterRoleFilter180 = "UNASSIGNED" C5R4SetTeamTab180(self, "ROSTER")
    end, "danger")

    local actions = ui.raidTeamMemberActionButtons180 or {}
    if actions.flexible then actions.flexible.otlActionVisible180 = false actions.flexible:Hide() end
    if actions.role then actions.role.otlActionVisible180 = false actions.role:Hide() end
    actions.tank = actions.tank or UI:Button(details, "Main: Tank", 82, 24, function() self:ApplyRaidTeamMemberAction180("MAIN_ROLE", "TANK") end, "utility")
    actions.healer = actions.healer or UI:Button(details, "Main: Healer", 88, 24, function() self:ApplyRaidTeamMemberAction180("MAIN_ROLE", "HEALER") end, "utility")
    actions.damage = actions.damage or UI:Button(details, "Main: Damage", 96, 24, function() self:ApplyRaidTeamMemberAction180("MAIN_ROLE", "DAMAGE") end, "utility")
    actions.offNone = UI:Button(details, "OS: None", 72, 24, function() self:ApplyRaidTeamMemberAction180("OFFSPEC_ROLE", "NONE") end, "utility")
    actions.offTank = UI:Button(details, "OS: Tank", 74, 24, function() self:ApplyRaidTeamMemberAction180("OFFSPEC_ROLE", "TANK") end, "utility")
    actions.offHealer = UI:Button(details, "OS: Healer", 80, 24, function() self:ApplyRaidTeamMemberAction180("OFFSPEC_ROLE", "HEALER") end, "utility")
    actions.offDamage = UI:Button(details, "OS: Damage", 88, 24, function() self:ApplyRaidTeamMemberAction180("OFFSPEC_ROLE", "DAMAGE") end, "utility")
    ui.raidTeamMemberActionButtons180 = actions
    return true
end

-- C5-R4 Pack 1-R2: return an explicit responsive action layout.  The helper is
-- intentionally data-only so the geometry matrix can validate the exact
-- calculated bounds without relying on static token checks.
function OTLGM:GetRaidTeamRosterActionLayout180(detailWidth, detailHeight)
    detailWidth = math.max(360, tonumber(detailWidth) or 390)
    detailHeight = math.max(260, tonumber(detailHeight) or 330)
    local left, right, gap, rowHeight = 12, detailWidth - 12, 4, 24
    local contentWidth = math.max(1, right - left)
    local rows = {}
    local function addRow(name, y, controls)
        local row = { name = name, y = y, height = rowHeight, controls = {} }
        local x = left
        local index, item
        for index = 1, table.getn(controls) do
            item = controls[index]
            local width = tonumber(item.width) or 0
            table.insert(row.controls, { key = item.key, left = x, right = x + width, top = y, bottom = y + rowHeight, width = width })
            x = x + width + gap
        end
        rows[name] = row
        return row
    end

    local tier = {
        { key = "remove", width = 66 }, { key = "core", width = 54 },
        { key = "reserve", width = 64 }, { key = "guest", width = 56 },
    }
    local main = {
        { key = "tank", width = 82 }, { key = "healer", width = 88 }, { key = "damage", width = 96 },
    }
    local offspec = {
        { key = "offNone", width = 72 }, { key = "offTank", width = 74 },
        { key = "offHealer", width = 80 }, { key = "offDamage", width = 88 },
    }
    local tierWidth = 66 + 54 + 64 + 56 + (3 * gap)
    local addWidth = 126
    local addSharesTier = tierWidth + gap + addWidth <= contentWidth
    local rowCount = addSharesTier and 3 or 4
    local actionAreaHeight = rowCount == 3 and 92 or 122
    local firstY = detailHeight - actionAreaHeight + 4
    local tierRow = addRow("tier", firstY, tier)
    local mainY
    if addSharesTier then
        local addLeft = right - addWidth
        table.insert(tierRow.controls, { key = "addMembers", left = addLeft, right = right, top = firstY, bottom = firstY + rowHeight, width = addWidth })
        mainY = firstY + 30
    else
        addRow("add", firstY + 30, { { key = "addMembers", width = addWidth } })
        mainY = firstY + 60
    end
    addRow("main", mainY, main)
    addRow("offspec", mainY + 30, offspec)

    local allInside = true
    local _, row, index, control
    for _, row in pairs(rows) do
        for index = 1, table.getn(row.controls or {}) do
            control = row.controls[index]
            if control.left < 0 or control.right > detailWidth or control.top < 0 or control.bottom > detailHeight then allInside = false end
        end
    end
    return {
        rows = rows, actionAreaHeight = actionAreaHeight, addSharesTier = addSharesTier,
        memberTop = 154, memberRowStep = 24, allInside = allInside, detailWidth = detailWidth, detailHeight = detailHeight,
    }
end

local function C5R4LayoutRaidTeams180(owner)
    local ui = owner.ui
    local panel, list, details = ui.raidTeamsPanel180, ui.raidTeamListPanel180, ui.raidTeamDetailsPanel180
    if not panel or not list or not details then return end
    local width, height = panel:GetWidth() or 700, panel:GetHeight() or 400
    local listWidth = math.max(270, math.min(330, math.floor(width * 0.36)))
    local detailWidth = math.max(390, width - listWidth - 10)
    local visibilitySignature = table.concat({
        ui.raidTeamCreate180 and ui.raidTeamCreate180:IsVisible() and "1" or "0",
        ui.raidTeamEdit180 and ui.raidTeamEdit180:IsVisible() and "1" or "0",
        ui.raidTeamArchive180 and ui.raidTeamArchive180:IsVisible() and "1" or "0",
        ui.raidTeamDelete180 and ui.raidTeamDelete180:IsVisible() and "1" or "0",
    }, "")
    local layoutSignature = table.concat({ tostring(width), tostring(height), tostring(ui.raidTeamInnerTab180 or "OVERVIEW"), visibilitySignature }, ":")
    if ui.raidTeamLayoutSignature180 == layoutSignature then return false end
    ui.raidTeamLayoutSignature180 = layoutSignature
    owner.runtime = owner.runtime or {}
    owner.runtime.raidTeamRefreshMetrics180 = owner.runtime.raidTeamRefreshMetrics180 or {}
    owner.runtime.raidTeamRefreshMetrics180.layoutPasses = (tonumber(owner.runtime.raidTeamRefreshMetrics180.layoutPasses) or 0) + 1
    Move(ui.raidTeamSearchBox180, panel, 0, 0, math.max(150, listWidth - 184), 28)
    Move(ui.raidTeamAllTeams180, panel, math.max(156, listWidth - 176), 2, 86, 24)
    Move(ui.raidTeamMyTeams180, panel, math.max(248, listWidth - 84), 2, 82, 24)
    if owner.LayoutRightButtonGroup180 then
        owner:LayoutRightButtonGroup180(panel, { ui.raidTeamCreate180, ui.raidTeamEdit180, ui.raidTeamArchive180, ui.raidTeamDelete180 }, width, 0, 8)
    end
    Move(list, panel, 0, -38, listWidth, height - 38)
    Move(details, panel, listWidth + 10, -38, detailWidth, height - 38)
    local listHeight = list:GetHeight() or (height - 38)
    local teamCapacity = math.max(5, math.min(table.getn(ui.raidTeamRows180 or {}), math.floor((listHeight - 42) / 48)))
    ui.raidTeamVisibleRows180 = teamCapacity
    local index, row
    for index = 1, table.getn(ui.raidTeamRows180 or {}) do
        row = ui.raidTeamRows180[index]
        if index <= teamCapacity then
            Move(row, list, 8, -32 - ((index - 1) * 48), listWidth - 32, 45)
            Move(row.nameText, row, 9, -6, listWidth - 50, 18)
            Move(row.metaText, row, 9, -23, listWidth - 50, 18)
        else row:Hide() end
    end
    Move(ui.raidTeamScrollbar180, list, listWidth - 19, -32, 14, math.max(80, teamCapacity * 48 - 3))
    -- One owner for the complete details header: title, meta and tabs never share a row.
    Move(ui.raidTeamDetailTitle180, details, 12, -8, detailWidth - 24, 20)
    Move(ui.raidTeamDetailMeta180, details, 12, -29, detailWidth - 24, 18)
    Move(ui.raidTeamOverviewTab180, details, 10, -52, 96, 26)
    Move(ui.raidTeamRosterTab180, details, 112, -52, 90, 26)
    local dHeight = details:GetHeight() or 330
    local mode = ui.raidTeamInnerTab180 or "OVERVIEW"

    if ui.raidTeamRoleSummary180 then ui.raidTeamRoleSummary180:Hide() end
    -- Visibility is applied once after data refresh by ApplyRaidTeamDetailsVisibility180.
    -- Layout owns coordinates only and never re-shows controls from another inner tab.

    if mode == "OVERVIEW" then
        local compact = dHeight < 500
        local wideActions = detailWidth >= 540
        local contactY = compact and 132 or 140
        local whisperY = compact and 170 or 180
        local helpersY = wideActions and (compact and 204 or 214) or (compact and 226 or 240)
        local helperButtonsY = helpersY + 26
        local roleCardsY = helperButtonsY + 28
        local unassignedY = roleCardsY + 58
        local nextRaidY = unassignedY + 28
        local descriptionY = nextRaidY + 38
        Move(ui.raidTeamPrimaryBadge180, details, 12, -88, 150, 20)
        Move(ui.raidTeamOnlineSummary180, details, 168, -88, detailWidth - 180, 20)
        Move(ui.raidTeamPersonalStatus180, details, 12, -112, detailWidth - 24, 22)
        Move(ui.raidTeamContactSummary180, details, 12, -contactY, detailWidth - 24, 38)
        if wideActions then
            -- One clean action row on the normal RC window.  Hidden controls stay
            -- hidden; layout changes coordinates only.
            Move(ui.raidTeamWhisperLeader180, details, 12, -whisperY, 146, 24)
            Move(ui.raidTeamAskInvite180, details, 166, -whisperY, 122, 24)
            Move(ui.raidTeamWhisperContact180, details, 296, -whisperY, math.max(118, detailWidth - 308), 24)
            Move(ui.raidTeamSelfContact180, details, 12, -whisperY, detailWidth - 24, 22)
            Move(ui.raidTeamInviteRequestStatus180, details, 12, -(whisperY + 27), detailWidth - 24, 18)
        else
            local halfWidth = math.min(150, math.max(118, math.floor((detailWidth - 30) / 2)))
            Move(ui.raidTeamWhisperLeader180, details, 12, -whisperY, halfWidth, 24)
            Move(ui.raidTeamWhisperContact180, details, math.floor(detailWidth / 2) + 3, -whisperY, math.max(118, math.floor(detailWidth / 2) - 15), 24)
            Move(ui.raidTeamSelfContact180, details, 12, -whisperY, detailWidth - 24, 22)
            Move(ui.raidTeamAskInvite180, details, 12, -(whisperY + 28), 118, 24)
            Move(ui.raidTeamInviteRequestStatus180, details, 138, -(whisperY + 31), detailWidth - 150, 20)
        end
        Move(ui.raidTeamHelpersSummary180, details, 12, -helpersY, detailWidth - 24, 24)
        for index = 1, table.getn(ui.raidTeamHelperButtons180 or {}) do Move(ui.raidTeamHelperButtons180[index], details, 12 + ((index - 1) * 118), -helperButtonsY, 112, 22) end
        local cardWidth = math.max(94, math.floor((detailWidth - 36) / 3))
        local roleOrder = { "TANK", "HEALER", "DAMAGE" }
        for index = 1, table.getn(roleOrder) do Move(ui.raidTeamRoleCards180[roleOrder[index]], details, 12 + ((index - 1) * (cardWidth + 6)), -roleCardsY, cardWidth, 54) end
        Move(ui.raidTeamUnassigned180, details, 12, -unassignedY, 160, 24)
        Move(ui.raidTeamNextRaid180, details, 12, -nextRaidY, detailWidth - 102, 38)
        Move(ui.raidTeamOpenNextRaid180, details, detailWidth - 90, -(nextRaidY + 4), 78, 24)
        Move(ui.raidTeamDetailDescription180, details, 12, -descriptionY, detailWidth - 24, math.max(24, dHeight - descriptionY - 38))
        Move(ui.raidTeamSetPrimary180, details, detailWidth - 100, -(dHeight - 34), 88, 24)
    else
        -- Two stable toolbar rows.  Search/Role/Tier never compete with Online,
        -- Clear Filters or Clear Selection, even at the minimum supported width.
        local searchWidth = math.max(150, detailWidth - 230)
        Move(ui.raidTeamRosterSearchBox180, details, 12, -88, searchWidth, 26)
        Move(ui.raidTeamRosterRoleButton180, details, 18 + searchWidth, -88, 100, 26)
        Move(ui.raidTeamRosterTierButton180, details, 124 + searchWidth, -88, math.max(82, detailWidth - (136 + searchWidth)), 26)
        Move(ui.raidTeamRosterOnlineButton180, details, 12, -120, 72, 24)
        Move(ui.raidTeamRosterClearFiltersR2, details, 90, -120, 96, 24)
        local actionLayout = owner:GetRaidTeamRosterActionLayout180(detailWidth, dHeight)
        local actionHeight = actionLayout.actionAreaHeight
        local memberTop = actionLayout.memberTop
        local memberArea = math.max(120, dHeight - memberTop - actionHeight)
        local memberRowStep = actionLayout.memberRowStep or 28
        local capacity = math.max(4, math.min(table.getn(ui.raidTeamMemberRows180 or {}), math.floor(memberArea / memberRowStep)))
        ui.raidTeamMemberVisibleRows180 = capacity
        Move(ui.raidTeamSelectionCatcher180, details, 12, -memberTop, detailWidth - 38, math.max(40, capacity * memberRowStep - 2))
        Move(ui.raidTeamClearSelection180, details, detailWidth - 146, -121, 134, 22)
        for index = 1, table.getn(ui.raidTeamMemberRows180 or {}) do
            row = ui.raidTeamMemberRows180[index]
            if index <= capacity then
                Move(row, details, 12, -memberTop - ((index - 1) * memberRowStep), detailWidth - 38, memberRowStep - 2)
                if row.SetFrameLevel and details.GetFrameLevel then row:SetFrameLevel(details:GetFrameLevel() + 3) end
                if row.classIcon180 then row.classIcon180:ClearAllPoints() row.classIcon180:SetPoint("LEFT", row, "LEFT", 7, 0) end
                Move(row.nameText, row, 31, -5, math.max(130, math.floor(detailWidth * 0.36)), 18)
                if row.roleIcon180 then row.roleIcon180:ClearAllPoints() row.roleIcon180:SetPoint("LEFT", row, "LEFT", math.floor(detailWidth * 0.40), 0) end
                Move(row.metaText, row, math.floor(detailWidth * 0.45), -5, math.max(150, math.floor(detailWidth * 0.51)), 18)
            end
        end
        Move(ui.raidTeamMemberScrollbar180, details, detailWidth - 19, -memberTop, 14, math.max(80, capacity * memberRowStep - 2))
        local actions = ui.raidTeamMemberActionButtons180 or {}
        local key, layoutRow, control
        for _, layoutRow in pairs(actionLayout.rows or {}) do
            for index = 1, table.getn(layoutRow.controls or {}) do
                control = layoutRow.controls[index]
                if control.key == "addMembers" then
                    Move(ui.raidTeamAddMembers180, details, control.left, -control.top, control.width, control.bottom - control.top)
                else
                    local button = actions[control.key]
                    if button then Move(button, details, control.left, -control.top, control.width, control.bottom - control.top) end
                end
            end
        end
        ui.raidTeamActionLayout180 = actionLayout
    end
    local selectedTeam = owner:GetRaidTeam180(ui.raidTeamSelectedId180)
    owner:ApplyRaidTeamDetailsVisibility180(mode, selectedTeam,
        selectedTeam and owner:CanManageRaidTeams180(selectedTeam), owner.IsOfficerMode and owner:IsOfficerMode())
    return true
end

function OTLGM:RefreshRaidTeamsPanel180()
    self:EnsureRaidTeamPack2Controls180()
    local ui = self.ui
    if not ui or not ui.raidTeamsPanel180 then return false end
    C5R4LayoutRaidTeams180(self)
    local teams = self:GetRaidTeamList180(true, ui.raidTeamMyTeamsOnly180)
    local query = string.lower(tostring(ui.raidTeamSearch180 or ""))
    local filtered, index, team = {}, 1, nil
    for index = 1, table.getn(teams) do
        team = teams[index]
        if query == "" or string.find(string.lower((team.name or "") .. " " .. (team.raidLeader or "")), query, 1, true) then table.insert(filtered, team) end
    end
    local previousSelectedTeamId180 = ui.raidTeamSelectedId180
    if not ui.raidTeamSelectedId180 or not self:GetRaidTeam180(ui.raidTeamSelectedId180) then ui.raidTeamSelectedId180 = filtered[1] and filtered[1].id or nil end
    local selectedVisible = false
    for index = 1, table.getn(filtered) do if filtered[index].id == ui.raidTeamSelectedId180 then selectedVisible = true break end end
    if not selectedVisible then ui.raidTeamSelectedId180 = filtered[1] and filtered[1].id or nil end
    if previousSelectedTeamId180 ~= ui.raidTeamSelectedId180 and self.ClearRaidTeamMemberSelection180 then
        self:ClearRaidTeamMemberSelection180("team-change", false)
        ui.raidTeamMemberOffset180 = 0
    end
    local signatureTeam = self:GetRaidTeam180(ui.raidTeamSelectedId180)
    local signatureCanManage = signatureTeam and self:CanManageRaidTeams180(signatureTeam) and true or false
    local signatureCanCreate = self.IsOfficerMode and self:IsOfficerMode() and true or false
    local inviteCooldownSignature180 = ""
    if signatureTeam then
        local inviteTarget180 = tostring(signatureTeam.inviteContact or "")
        if inviteTarget180 == "" then inviteTarget180 = tostring(signatureTeam.raidLeader or "") end
        local inviteKey180 = tostring(signatureTeam.id or "") .. ":" .. C5R4Name180(inviteTarget180)
        local inviteSentAt180 = self.runtime and self.runtime.raidTeamInviteRequestCooldown180 and tonumber(self.runtime.raidTeamInviteRequestCooldown180[inviteKey180]) or 0
        inviteCooldownSignature180 = inviteSentAt180 > 0 and ((self:Now() - inviteSentAt180 < 10) and "COOLDOWN" or "READY") or "NONE"
    end
    local signatureParts = { tostring(ui.raidTeamSearch180 or ""), ui.raidTeamMyTeamsOnly180 and "1" or "0", tostring(ui.raidTeamSelectedId180 or ""), tostring(ui.raidTeamOffset180 or 0), tostring(ui.raidTeamMemberOffset180 or 0), tostring(ui.raidTeamInnerTab180 or "OVERVIEW"), tostring(ui.raidTeamRosterSearch180 or ""), tostring(ui.raidTeamRosterRoleFilter180 or "ALL"), tostring(ui.raidTeamRosterTierFilter180 or "ALL"), ui.raidTeamRosterOnlineOnly180 and "1" or "0", tostring(UnitName and UnitName("player") or ""), signatureCanManage and "M1" or "M0", signatureCanCreate and "C1" or "C0", inviteCooldownSignature180 }
    for index = 1, table.getn(teams) do
        team = teams[index]
        local onlineParts, memberKey, signatureMember = {}, nil, nil
        for memberKey, signatureMember in pairs(team.members or {}) do
            local rosterMember = self:GetMember(signatureMember.character)
            table.insert(onlineParts, tostring(memberKey) .. (rosterMember and rosterMember.online and "+" or "-"))
        end
        table.sort(onlineParts)
        table.insert(signatureParts, tostring(team.id or "") .. ":" .. tostring(team.rev or 0) .. ":" .. tostring(team.status or "") .. ":" .. (team.primary180 and "1" or "0") .. ":" .. table.concat(onlineParts, ","))
    end
    local selectionParts, selectedKey, selectedValue = {}, nil, nil
    for selectedKey, selectedValue in pairs(ui.raidTeamMemberSelection180 or {}) do if selectedValue then table.insert(selectionParts, tostring(selectedKey)) end end
    table.sort(selectionParts)
    table.insert(signatureParts, "selection=" .. table.concat(selectionParts, ","))
    local pveSignature = self:EnsurePveDB()
    local raidParts, raidId, raidEvent = {}, nil, nil
    for raidId, raidEvent in pairs(pveSignature and pveSignature.raids or {}) do
        table.insert(raidParts, tostring(raidId) .. ":" .. tostring(raidEvent.rev or raidEvent.revision or 0) .. ":" .. tostring(raidEvent.teamId180 or "") .. ":" .. tostring(raidEvent.startTs or 0) .. ":" .. (raidEvent.cancelled and "1" or "0"))
    end
    table.sort(raidParts)
    table.insert(signatureParts, "raids=" .. table.concat(raidParts, ","))
    local refreshSignature = table.concat(signatureParts, "|")
    self.runtime = self.runtime or {}
    self.runtime.raidTeamRefreshMetrics180 = self.runtime.raidTeamRefreshMetrics180 or {}
    if ui.raidTeamRefreshSignature180 == refreshSignature then
        self.runtime.raidTeamRefreshMetrics180.skippedUnchanged = (tonumber(self.runtime.raidTeamRefreshMetrics180.skippedUnchanged) or 0) + 1
        self:ApplyRaidTeamDetailsVisibility180(ui.raidTeamInnerTab180, signatureTeam, signatureCanManage, signatureCanCreate)
        return true
    end
    ui.raidTeamRefreshSignature180 = refreshSignature
    self.runtime.raidTeamRefreshMetrics180.fullPasses = (tonumber(self.runtime.raidTeamRefreshMetrics180.fullPasses) or 0) + 1
    local capacity = tonumber(ui.raidTeamVisibleRows180) or 8
    local maximum = math.max(0, table.getn(filtered) - capacity)
    ui.raidTeamOffset180 = math.max(0, math.min(maximum, tonumber(ui.raidTeamOffset180) or 0))
    local row
    for index = 1, table.getn(ui.raidTeamRows180 or {}) do
        row = ui.raidTeamRows180[index]
        team = index <= capacity and filtered[ui.raidTeamOffset180 + index] or nil
        if team then
            local dashboard = self:GetRaidTeamDashboard180(team) or {}
            local total, core, reserve, guest = self:GetRaidTeamMemberCount180(team)
            local mine = self:GetRaidTeamMembership180(team)
            row.team180 = team
            row.nameText:SetText((team.status == "ARCHIVED" and "|cff888888[ARCHIVED]|r  " or "") .. (team.primary180 and "|cffff6655PRIMARY|r  " or "") .. tostring(team.name or "Raid Team") .. (mine and "  |cffffcc44MY TEAM|r" or ""))
            row.metaText:SetText(tostring(team.raidLeader or "Unknown") .. "  |  " .. tostring(total) .. " members / " .. tostring(dashboard.online or 0) .. " online\n" .. tostring(core) .. " Core  •  " .. tostring(reserve) .. " Reserve  •  " .. tostring(guest) .. " Guest")
            UI:SetSelected(row, team.id == ui.raidTeamSelectedId180)
            if row.primaryAccent180 then if team.primary180 then row.primaryAccent180:Show() else row.primaryAccent180:Hide() end end
            row:Show()
        else row.team180 = nil if row.primaryAccent180 then row.primaryAccent180:Hide() end row:Hide() end
    end
    if ui.raidTeamScrollbar180 and ui.raidTeamScrollbar180.SetScrollMetrics180 then ui.raidTeamScrollbar180:SetScrollMetrics180(table.getn(filtered), capacity, ui.raidTeamOffset180) end
    UI:SetSelected(ui.raidTeamAllTeams180, not ui.raidTeamMyTeamsOnly180)
    UI:SetSelected(ui.raidTeamMyTeams180, ui.raidTeamMyTeamsOnly180)

    team = self:GetRaidTeam180(ui.raidTeamSelectedId180)
    local canManage = team and self:CanManageRaidTeams180(team)
    local canCreate = self.IsOfficerMode and self:IsOfficerMode()
    if canCreate then ui.raidTeamCreate180:Show() else ui.raidTeamCreate180:Hide() end
    local admin = { ui.raidTeamEdit180, ui.raidTeamArchive180, ui.raidTeamDelete180 }
    for index = 1, table.getn(admin) do if canManage then admin[index]:Show() else admin[index]:Hide() end end
    if ui.raidTeamAddMembers180 then if canManage then ui.raidTeamAddMembers180:Show() else ui.raidTeamAddMembers180:Hide() end end
    -- Permission visibility is part of the geometry contract.  A changed set
    -- invalidates only the layout pass, not team data or roster caches.
    C5R4LayoutRaidTeams180(self)

    local function dataVisible180(control, visible)
        if control then control.otlDataVisible180 = visible and true or false end
    end
    if not team then
        ui.raidTeamDetailTitle180:SetText("Select a Raid Team")
        ui.raidTeamDetailMeta180:SetText("All guild members may view permanent character-based teams.")
        ui.raidTeamDetailDescription180:SetText("") ui.raidTeamPersonalStatus180:SetText("")
        ui.raidTeamPrimaryBadge180:SetText("") ui.raidTeamOnlineSummary180:SetText("")
        ui.raidTeamContactSummary180:SetText("") ui.raidTeamHelpersSummary180:SetText("")
        ui.raidTeamNextRaid180:SetText("") ui.raidTeamNextRaidId180 = nil
        dataVisible180(ui.raidTeamOpenNextRaid180, false)
        dataVisible180(ui.raidTeamWhisperLeader180, false)
        dataVisible180(ui.raidTeamWhisperContact180, false)
        dataVisible180(ui.raidTeamSelfContact180, false)
        dataVisible180(ui.raidTeamAskInvite180, false)
        dataVisible180(ui.raidTeamInviteRequestStatus180, false)
        dataVisible180(ui.raidTeamSetPrimary180, false)
        dataVisible180(ui.raidTeamUnassigned180, false)
        for _, card in pairs(ui.raidTeamRoleCards180 or {}) do
            UI:SetText(card, "0 / 0 online")
            card.otlTooltip = "No members assigned."
            dataVisible180(card, false)
        end
        for index = 1, table.getn(ui.raidTeamHelperButtons180 or {}) do
            ui.raidTeamHelperButtons180[index].helperName180 = nil
            dataVisible180(ui.raidTeamHelperButtons180[index], false)
        end
    else
        local dashboard = self:GetRaidTeamDashboard180(team) or {}
        local total, core, reserve, guest = self:GetRaidTeamMemberCount180(team)
        local roles = dashboard.roles or {}
        ui.raidTeamDetailTitle180:SetText(tostring(team.name or "Raid Team"))
        ui.raidTeamDetailMeta180:SetText("Members " .. tostring(total) .. "  |  Core " .. tostring(core) .. "  |  Reserve " .. tostring(reserve) .. "  |  Guest " .. tostring(guest))
        ui.raidTeamPrimaryBadge180:SetText(team.primary180 and "|cffff6655PRIMARY RAID TEAM|r" or "")
        dataVisible180(ui.raidTeamPrimaryBadge180, team.primary180 and true or false)
        ui.raidTeamOnlineSummary180:SetText("Online |cff55dd77" .. tostring(dashboard.online or 0) .. "|r / " .. tostring(dashboard.total or total))
        ui.raidTeamOnlineSummary180.otlTooltipTitle = "Team availability"
        ui.raidTeamOnlineSummary180.otlTooltip = "Online: " .. C5R4NamesText180(dashboard.onlineNames) .. "\nOffline: " .. C5R4NamesText180(dashboard.offlineNames)
        ui.raidTeamDetailDescription180:SetText(team.description ~= "" and team.description or "No team description.")
        local mine = self:GetRaidTeamMembership180(team)
        if mine then
            local mainRole, offspec = C5R4Role180(mine), C5R4Offspec180(mine)
            ui.raidTeamPersonalStatus180:SetText(self.colors.gold .. "You are " .. tostring(mine.tier or "Guest") .. self.colors.reset .. self.colors.grey .. "  •  Main: " .. C5R4RoleLabel180(mainRole) .. (offspec ~= "NONE" and ("  •  OS: " .. C5R4RoleLabel180(offspec)) or "") .. self.colors.reset)
        else
            ui.raidTeamPersonalStatus180:SetText(self.colors.grey .. "You are not a member of this team." .. self.colors.reset)
        end

        local leaderName = tostring(team.raidLeader or "Unknown")
        local contactName = tostring(team.inviteContact or team.raidLeader or "Unknown")
        local sameContact = C5R4Name180(leaderName) ~= "" and C5R4Name180(leaderName) == C5R4Name180(contactName)
        ui.raidTeamContactSummary180:SetText(sameContact and ("Raid Leader / Invite Contact: |cffffdd77" .. leaderName .. "|r") or ("Raid Leader: |cffffdd77" .. leaderName .. "|r\nMain Invite Contact: |cffffdd77" .. contactName .. "|r"))
        local player = C5R4Name180(UnitName and UnitName("player") or "")
        local leaderIsPlayer = C5R4Name180(leaderName) == player
        local contactIsPlayer = C5R4Name180(contactName) == player
        if ui.raidTeamSelfContact180 then
            ui.raidTeamSelfContact180:SetText(leaderIsPlayer and contactIsPlayer and "You are the Raid Leader and Invite Contact"
                or leaderIsPlayer and "You are the Raid Leader"
                or contactIsPlayer and "You are the Invite Contact" or "")
            dataVisible180(ui.raidTeamSelfContact180, leaderIsPlayer or contactIsPlayer)
        end
        UI:SetText(ui.raidTeamWhisperLeader180, sameContact and "Whisper Raid Leader / Invite Contact" or "Whisper Raid Leader")
        UI:SetEnabled(ui.raidTeamWhisperLeader180, not leaderIsPlayer, leaderIsPlayer and "This is your character." or nil)
        dataVisible180(ui.raidTeamWhisperLeader180, not leaderIsPlayer)
        UI:SetText(ui.raidTeamWhisperContact180, "Whisper Invite Contact")
        UI:SetEnabled(ui.raidTeamWhisperContact180, not sameContact and not contactIsPlayer, contactIsPlayer and "This is your character." or nil)
        dataVisible180(ui.raidTeamWhisperContact180, not sameContact and not contactIsPlayer)

        local inviteTarget, inviteProblem = C5R4RaidInviteTarget180(self, team)
        local inviteVisible = team.status ~= "ARCHIVED" and mine and inviteTarget and inviteTarget ~= ""
        local inviteKey = tostring(team.id or "") .. ":" .. C5R4Name180(inviteTarget)
        local inviteSentAt = self.runtime and self.runtime.raidTeamInviteRequestCooldown180 and tonumber(self.runtime.raidTeamInviteRequestCooldown180[inviteKey]) or 0
        local inviteCooldown = inviteSentAt > 0 and self:Now() - inviteSentAt < 10
        if inviteCooldown then inviteProblem = "An invite request was just sent." end
        dataVisible180(ui.raidTeamAskInvite180, inviteVisible)
        UI:SetEnabled(ui.raidTeamAskInvite180, inviteVisible and not inviteProblem and not inviteCooldown, inviteProblem or "You are not a member of this Raid Team.")
        if inviteCooldown then
            ui.raidTeamInviteRequestStatus180:SetText("Invite request sent to " .. string.gsub(tostring(inviteTarget or ""), "%-.*$", "") .. ".")
            dataVisible180(ui.raidTeamInviteRequestStatus180, true)
        elseif not ui.raidTeamInviteRequestStatus180.otlManualStatus180 then
            ui.raidTeamInviteRequestStatus180:SetText("")
            dataVisible180(ui.raidTeamInviteRequestStatus180, false)
        end

        ui.raidTeamParsedHelpers180 = ui.raidTeamParsedHelpers180 or {}
        local helperSignature = tostring(team.rev or 0) .. ":" .. tostring(team.inviteHelpers or "")
        local helperCache = ui.raidTeamParsedHelpers180[team.id]
        local helpers
        if helperCache and helperCache.signature == helperSignature then
            helpers = helperCache.helpers
            self.runtime.raidTeamRefreshMetrics180.helperCacheHits = (tonumber(self.runtime.raidTeamRefreshMetrics180.helperCacheHits) or 0) + 1
        else
            helpers = SplitCommaList180(team.inviteHelpers, 3)
            ui.raidTeamParsedHelpers180[team.id] = { signature = helperSignature, helpers = helpers }
            self.runtime.raidTeamRefreshMetrics180.helperParses = (tonumber(self.runtime.raidTeamRefreshMetrics180.helperParses) or 0) + 1
        end
        ui.raidTeamHelpersSummary180:SetText(table.getn(helpers) > 0 and ("Invite Helpers: " .. table.concat(helpers, ", ")) or "Invite Helpers: none assigned")
        for index = 1, table.getn(ui.raidTeamHelperButtons180 or {}) do
            local button, helper = ui.raidTeamHelperButtons180[index], helpers[index]
            if helper and C5R4Name180(helper) ~= player then
                button.helperName180 = helper
                UI:SetText(button, "Whisper " .. string.gsub(helper, "%-.*$", ""))
                local rosterMember = self:GetMember(helper)
                UI:SetEnabled(button, rosterMember and rosterMember.online, "Invite Helper is offline.")
                dataVisible180(button, true)
            else
                button.helperName180 = nil
                dataVisible180(button, false)
            end
        end

        local roleOrder = { "TANK", "HEALER", "DAMAGE" }
        for index = 1, table.getn(roleOrder) do
            local role, card = roleOrder[index], ui.raidTeamRoleCards180[roleOrder[index]]
            local info = roles[role] or {}
            UI:SetText(card, C5R4RoleLabel180(role) .. "\n" .. tostring(info.online or 0) .. " / " .. tostring(info.total or 0) .. " online")
            card.otlTooltipTitle = C5R4RoleLabel180(role)
            card.otlTooltip = "Online: " .. C5R4NamesText180(info.onlineNames) .. "\nOffline: " .. C5R4NamesText180(info.offlineNames)
            dataVisible180(card, true)
        end
        local unassigned = roles.UNASSIGNED or {}
        if (tonumber(unassigned.total) or 0) > 0 then UI:SetText(ui.raidTeamUnassigned180, "Role needs review: " .. tostring(unassigned.total)) end
        dataVisible180(ui.raidTeamUnassigned180, (tonumber(unassigned.total) or 0) > 0)
        local nextRaid = dashboard.nextRaid
        if nextRaid then
            ui.raidTeamNextRaidId180 = nextRaid.id
            local startTs = tonumber(nextRaid.startTs) or 0
            local dateText = startTs > 0 and date("%a %d %b", startTs) or "Date TBA"
            local startText = string.format("%02d:%02d", tonumber(nextRaid.stHour) or 0, tonumber(nextRaid.stMinute) or 0)
            local gatherText = string.format("%02d:%02d", tonumber(nextRaid.gatherHour) or math.max(0, (tonumber(nextRaid.stHour) or 0) - 1), tonumber(nextRaid.gatherMinute) or 45)
            ui.raidTeamNextRaid180:SetText("Next raid: |cffffdd77" .. tostring(nextRaid.name or "Raid Event") .. "|r\n" .. dateText .. "  Start " .. startText .. " ST  •  Gather " .. gatherText .. " ST")
            dataVisible180(ui.raidTeamOpenNextRaid180, true)
        else
            ui.raidTeamNextRaidId180 = nil
            ui.raidTeamNextRaid180:SetText(self.colors.grey .. "No upcoming raid assigned." .. self.colors.reset)
            dataVisible180(ui.raidTeamOpenNextRaid180, false)
        end
        dataVisible180(ui.raidTeamSetPrimary180, canCreate and team.status ~= "ARCHIVED" and not team.primary180)
    end

    local memberRows = C5R4TeamMembers180(self, team, ui)
    local memberCapacity = tonumber(ui.raidTeamMemberVisibleRows180) or 12
    local memberMaximum = math.max(0, table.getn(memberRows) - memberCapacity)
    ui.raidTeamMemberOffset180 = math.max(0, math.min(memberMaximum, tonumber(ui.raidTeamMemberOffset180) or 0))
    ui.raidTeamMemberSelection180 = type(ui.raidTeamMemberSelection180) == "table" and ui.raidTeamMemberSelection180 or {}
    for index = 1, table.getn(ui.raidTeamMemberRows180 or {}) do
        row = ui.raidTeamMemberRows180[index]
        local entry = ui.raidTeamInnerTab180 == "ROSTER" and index <= memberCapacity and memberRows[ui.raidTeamMemberOffset180 + index] or nil
        if entry then
            if entry.otlHeader180 then
                row.member180 = nil
                row.memberKey180 = nil
                row.otlHeader180 = true
                if row.classIcon180 then row.classIcon180:Hide() end
                if row.roleIcon180 then row.roleIcon180:Hide() end
                row.nameText:SetText("|cffffcc66" .. tostring(entry.title or "Role") .. "|r")
                row.metaText:SetText(tostring(entry.online180 or 0) .. " / " .. tostring(entry.count180 or 0) .. " online")
                row:SetAlpha(1)
                UI:SetSelected(row, false)
                UI:SetEnabled(row, false, "Section header.")
                row:Show()
            else
                local key, online = C5R4Name180(entry.character), entry.otlOnline180
                local role, offspec = C5R4Role180(entry), C5R4Offspec180(entry)
                row.member180 = entry row.memberKey180 = key row.otlHeader180 = nil
                RaidTeamApplyClassIconPack2(row.classIcon180, entry.class or (entry.otlRosterMember180 and (entry.otlRosterMember180.classFile or entry.otlRosterMember180.class)))
                C5R4ApplyRoleIcon180(self, row.roleIcon180, role)
                if row.classIcon180 then row.classIcon180:Show() if row.classIcon180.SetDesaturated then row.classIcon180:SetDesaturated(not online) end row.classIcon180:SetVertexColor(online and 1 or 0.48, online and 1 or 0.48, online and 1 or 0.48) end
                if row.roleIcon180 then row.roleIcon180:Show() if row.roleIcon180.SetDesaturated then row.roleIcon180:SetDesaturated(not online) end row.roleIcon180:SetVertexColor(online and 1 or 0.48, online and 1 or 0.48, online and 1 or 0.48) end
                local prefix = ui.raidTeamMemberSelection180[key] and "|cffffcc44[SELECTED]|r  " or ""
                local nameText = tostring(entry.character or "Unknown")
                if online then row.nameText:SetText(prefix .. self:GetClassColor(entry.class or "") .. nameText .. self.colors.reset)
                else row.nameText:SetText(prefix .. "|cff777777" .. nameText .. "|r") end
                row.metaText:SetText((online and "" or "|cff777777") .. C5R4RoleLabel180(role) .. (offspec ~= "NONE" and ("  •  OS: " .. C5R4RoleLabel180(offspec)) or "") .. "  •  " .. tostring(entry.tier or "GUEST") .. "  •  " .. (online and "|cff55dd77Online|r" or "Offline|r"))
                row:SetAlpha(online and 1 or 0.62)
                UI:SetEnabled(row, true) UI:SetSelected(row, ui.raidTeamMemberSelection180[key] == true) row:Show()
            end
        else
            row.member180 = nil row.memberKey180 = nil row.otlHeader180 = nil row:SetAlpha(1)
            if row.classIcon180 then row.classIcon180:Hide() end
            if row.roleIcon180 then row.roleIcon180:Hide() end
            row:Hide()
        end
    end
    if ui.raidTeamMemberScrollbar180 and ui.raidTeamMemberScrollbar180.SetScrollMetrics180 then ui.raidTeamMemberScrollbar180:SetScrollMetrics180(table.getn(memberRows), memberCapacity, ui.raidTeamMemberOffset180) end
    UI:SetText(ui.raidTeamRosterRoleButton180, "Role: " .. (ui.raidTeamRosterRoleFilter180 == "UNASSIGNED" and "Review" or string.gsub(tostring(ui.raidTeamRosterRoleFilter180 or "ALL"), "^%l", string.upper)))
    if ui.raidTeamRosterRoleButton180 and ui.raidTeamRosterRoleButton180.roleIcon180 then
        if ui.raidTeamRosterRoleFilter180 and ui.raidTeamRosterRoleFilter180 ~= "ALL" then
            C5R4ApplyRoleIcon180(self, ui.raidTeamRosterRoleButton180.roleIcon180, ui.raidTeamRosterRoleFilter180)
            ui.raidTeamRosterRoleButton180.roleIcon180:Show()
        else
            ui.raidTeamRosterRoleButton180.roleIcon180:Hide()
        end
    end
    UI:SetText(ui.raidTeamRosterTierButton180, "Tier: " .. string.gsub(string.lower(tostring(ui.raidTeamRosterTierFilter180 or "ALL")), "^%l", string.upper))
    UI:SetSelected(ui.raidTeamRosterOnlineButton180, ui.raidTeamRosterOnlineOnly180)
    if ui.raidTeamRosterClearFiltersR2 then
        local hasFilters = tostring(ui.raidTeamRosterSearch180 or "") ~= "" or tostring(ui.raidTeamRosterRoleFilter180 or "ALL") ~= "ALL" or tostring(ui.raidTeamRosterTierFilter180 or "ALL") ~= "ALL" or ui.raidTeamRosterOnlineOnly180
        UI:SetEnabled(ui.raidTeamRosterClearFiltersR2, hasFilters and true or false, "All roster filters are already cleared.")
    end

    local selectedNames = RaidTeamSelectionList180(ui.raidTeamMemberSelection180)
    local selectedCount = table.getn(selectedNames)
    local actions = ui.raidTeamMemberActionButtons180 or {}
    local actionKeys = { "remove", "core", "reserve", "guest", "tank", "healer", "damage", "offNone", "offTank", "offHealer", "offDamage" }
    for index = 1, table.getn(actionKeys) do
        local button = actions[actionKeys[index]]
        if button then
            button.otlActionVisible180 = true
            UI:SetEnabled(button, canManage and selectedCount > 0, "Select one or more team members.")
        end
    end
    if actions.flexible then actions.flexible.otlActionVisible180 = false end
    if actions.role then actions.role.otlActionVisible180 = false end
    dataVisible180(ui.raidTeamAddMembers180, canManage)
    dataVisible180(ui.raidTeamSelectionCatcher180, selectedCount > 0)
    dataVisible180(ui.raidTeamClearSelection180, selectedCount > 0)
    self:ApplyRaidTeamDetailsVisibility180(ui.raidTeamInnerTab180, team, canManage, canCreate)
    return true
end

-- Raid Event source selectors and independent roster editor ------------------

local function C5R4RaidSourceList180(owner, sourceType)
    local list = sourceType == "TEAM" and owner:GetRaidTeamList180(false) or owner:GetPreviousRaidRosterSources180(owner.ui and owner.ui.raidEditor156 and owner.ui.raidEditor156.editId156)
    local result, index = {}, 1
    for index = 1, table.getn(list or {}) do table.insert(result, list[index]) end
    if sourceType == "TEAM" then
        table.sort(result, function(left, right)
            if (left.primary180 and true or false) ~= (right.primary180 and true or false) then return left.primary180 and true or false end
            local leftMine = owner:GetRaidTeamMembership180(left) and true or false
            local rightMine = owner:GetRaidTeamMembership180(right) and true or false
            if leftMine ~= rightMine then return leftMine end
            return string.lower(tostring(left.name or "")) < string.lower(tostring(right.name or ""))
        end)
    end
    return result
end

function OTLGM:EnsureRaidRosterSourceSelectorC5R4()
    local ui = self.ui
    if not ui or not ui.main or ui.raidRosterSourceSelector180 then return true end
    local selector = UI:Modal(ui.main, 620, 470)
    selector:SetPoint("CENTER", ui.main, "CENTER", 0, 0)
    selector.otlNonDangerModal180 = true
    ui.raidRosterSourceSelector180 = selector
    if self.RegisterModal152 then self:RegisterModal152(selector) end
    selector.title = UI.Text(selector, "SELECT RAID TEAM", "GameFontNormalLarge", "CENTER")
    Move(selector.title, selector, 20, -16, 580, 26)
    selector.subtitle = UI.Text(selector, "Choose a template. Nothing changes until Confirm.", "GameFontNormalSmall", "CENTER")
    selector.subtitle:SetTextColor(C.grey[1], C.grey[2], C.grey[3]) Move(selector.subtitle, selector, 20, -44, 580, 20)
    selector.rows = {}
    local index
    for index = 1, 9 do
        local row = UI:TableRow(selector, 560, 36, function(button)
            if button.source180 then selector.selectedId180 = button.source180.id self:RefreshRaidRosterSourceSelectorC5R4() end
        end)
        row.nameText = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.metaText = UI.Text(row, "", "GameFontNormalSmall", "RIGHT") row.metaText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        Move(row, selector, 20, -76 - ((index - 1) * 38), 560, 36)
        Move(row.nameText, row, 10, -8, 230, 18) Move(row.metaText, row, 246, -8, 304, 18)
        selector.rows[index] = row
    end
    selector.scrollbar = UI:Scrollbar(selector, 338, function(value) selector.offset180 = math.floor(value or 0) self:RefreshRaidRosterSourceSelectorC5R4() end)
    Move(selector.scrollbar, selector, 588, -76, 14, 338)
    selector.confirm = UI:Button(selector, "Confirm Team", 126, 32, function() self:ConfirmRaidRosterSourceC5R4() end, "primary")
    selector.cancel = UI:Button(selector, "Cancel", 96, 32, function() self:CloseModal180(selector, "cancel") end, "secondary")
    Move(selector.confirm, selector, 372, -426, 126, 32) Move(selector.cancel, selector, 506, -426, 96, 32)
    return true
end

function OTLGM:OpenRaidRosterSourceSelector180(sourceType)
    self:EnsureRaidRosterSourceSelectorC5R4()
    local selector = self.ui and self.ui.raidRosterSourceSelector180
    if not selector then return false end
    sourceType = sourceType == "CLONE_PREVIOUS" and "CLONE_PREVIOUS" or "TEAM"
    local list = C5R4RaidSourceList180(self, sourceType)
    if table.getn(list) == 0 then
        if self.SetStatus then self:SetStatus(sourceType == "TEAM" and "No active Raid Team is available." or "No previous event roster is available.") end
        self:RefreshRaidRosterEditor180()
        return false
    end
    selector.sourceType180 = sourceType selector.offset180 = 0
    -- A new source must be selected explicitly.  Existing edit/change flows may
    -- preselect only the source already committed to the event.
    selector.selectedId180 = nil
    if self.ui.raidRosterMode180 == sourceType and self.ui.raidRosterSourceId180 then
        local index
        for index = 1, table.getn(list) do
            if list[index].id == self.ui.raidRosterSourceId180 then selector.selectedId180 = list[index].id break end
        end
    end
    selector.title:SetText(sourceType == "TEAM" and "SELECT RAID TEAM" or "SELECT PREVIOUS RAID EVENT")
    UI:SetText(selector.confirm, sourceType == "TEAM" and "Confirm Team" or "Confirm Event")
    if self.ShowModal152 then self:ShowModal152(selector) else selector:Show() end
    -- Rows are populated after the modal becomes visible; the refresh helper
    -- deliberately ignores hidden selectors to avoid background UI work.
    self:RefreshRaidRosterSourceSelectorC5R4()
    return true
end

function OTLGM:RefreshRaidRosterSourceSelectorC5R4()
    local selector = self.ui and self.ui.raidRosterSourceSelector180
    if not selector or not selector:IsVisible() then return false end
    local list = C5R4RaidSourceList180(self, selector.sourceType180)
    local capacity = table.getn(selector.rows or {})
    local maximum = math.max(0, table.getn(list) - capacity)
    selector.offset180 = math.max(0, math.min(maximum, tonumber(selector.offset180) or 0))
    local index, row, source
    for index = 1, capacity do
        row = selector.rows[index] source = list[selector.offset180 + index]
        if source then
            row.source180 = source
            if selector.sourceType180 == "TEAM" then
                local dashboard = self:GetRaidTeamDashboard180(source) or {}
                local total, core, reserve, guest = self:GetRaidTeamMemberCount180(source)
                row.nameText:SetText((source.primary180 and "|cffff6655PRIMARY|r  " or "") .. (self:GetRaidTeamMembership180(source) and "|cffffcc44MY TEAM|r  " or "") .. tostring(source.name or "Raid Team"))
                row.metaText:SetText("RL " .. tostring(source.raidLeader or "Unknown") .. "  •  " .. tostring(core) .. "/" .. tostring(reserve) .. "/" .. tostring(guest) .. "  •  " .. tostring(dashboard.online or 0) .. "/" .. tostring(total) .. " online")
            else
                row.nameText:SetText(tostring(source.name or "Raid Event"))
                row.metaText:SetText(date("%d %b %Y", tonumber(source.startTs) or tonumber(source.createdAt) or self:Now()) .. "  •  " .. tostring(self:GetRaidRosterSummary180(source.roster180 or {})) .. " characters")
            end
            UI:SetSelected(row, source.id == selector.selectedId180) row:Show()
        else row.source180 = nil row:Hide() end
    end
    if selector.scrollbar and selector.scrollbar.SetScrollMetrics180 then selector.scrollbar:SetScrollMetrics180(table.getn(list), capacity, selector.offset180) end
    UI:SetEnabled(selector.confirm, selector.selectedId180 ~= nil, "Select a source first.")
    return true
end

local function C5R4ApplyRosterSource180(owner, sourceType, sourceId)
    local ui = owner.ui
    local roster, source
    if sourceType == "TEAM" then roster, source = owner:BuildRaidRosterSnapshotFromTeam180(sourceId)
    else roster, source = owner:CloneRaidEventRoster180(sourceId) end
    if not roster then return false, source end
    ui.eventRosterDraft180 = owner.CopyRaidEventRosterDomain180 and owner:CopyRaidEventRosterDomain180(roster) or C5R4Copy180(roster)
    ui.eventRosterDraftInitialized180 = true
    ui.eventRosterDraftDirty180 = nil
    ui.raidRosterMode180 = sourceType
    ui.raidRosterSourceId180 = sourceId
    ui.raidCustomRoster180 = ui.eventRosterDraft180
    RaidEditorMarkDirtyPack2(owner)
    owner:RefreshRaidRosterEditor180()
    return true
end

function OTLGM:ConfirmRaidRosterSourceC5R4()
    local ui = self.ui
    local selector = ui and ui.raidRosterSourceSelector180
    if not selector or not selector.selectedId180 then return false end
    local function apply()
        local ok, problem = C5R4ApplyRosterSource180(self, selector.sourceType180, selector.selectedId180)
        if not ok and self.ShowNotice then self:ShowNotice("Raid Event Roster", problem or "The roster source could not be copied.") return end
        self:CloseModal180(selector, "source-confirmed")
    end
    -- Dirty is the sole guard.  An intentionally emptied draft is still a
    -- meaningful manual edit and must never be replaced silently.
    if ui.eventRosterDraftDirty180 then
        self:ShowConfirm("Replace current event roster draft?", "Manual event-specific roster changes will be replaced by the selected source. The permanent Raid Team is not modified.", "Replace", apply)
    else apply() end
    return true
end

function OTLGM:RefreshEventRosterDraftFromTeam180()
    local ui = self.ui
    if not ui or ui.raidRosterMode180 ~= "TEAM" or not ui.raidRosterSourceId180 then return false end
    local team = self:GetRaidTeam180(ui.raidRosterSourceId180)
    if not team then return false end
    self:ShowConfirm("Refresh from Team", "Replace only this event roster draft with the current " .. tostring(team.name or "Raid Team") .. " roster? The permanent team will not be edited.", "Refresh", function()
        C5R4ApplyRosterSource180(self, "TEAM", team.id)
    end)
    return true
end

function OTLGM:EnsureEventRosterDraftEditorC5R4()
    local ui = self.ui
    if not ui or not ui.main or ui.eventRosterDraftEditor180 then return true end
    local editor = UI:Modal(ui.main, 700, 560)
    editor:SetPoint("CENTER", ui.main, "CENTER", 0, 0) editor.otlNonDangerModal180 = true
    ui.eventRosterDraftEditor180 = editor
    if self.RegisterModal152 then self:RegisterModal152(editor) end
    editor.title = UI.Text(editor, "EDIT EVENT ROSTER", "GameFontNormalLarge", "CENTER") Move(editor.title, editor, 20, -16, 660, 26)
    editor.summary = UI.Text(editor, "", "GameFontNormalSmall", "LEFT") Move(editor.summary, editor, 20, -46, 660, 22)
    editor.search = UI:SearchBox(editor, 220, 28, "Search event roster...", function(value) editor.search180 = value or "" editor.offset180 = 0 self:RefreshEventRosterDraftEditorC5R4() end)
    Move(editor.search, editor, 20, -72, 220, 28)
    editor.addName = UI:EditBox(editor, 180, 28, { placeholder = "Guest character name", maxLetters = 40 }) Move(editor.addName, editor, 248, -72, 180, 28)
    editor.addGuest = UI:Button(editor, "+ Add Guest", 100, 28, function()
        local name = editor.addName:GetText() or "" local key = C5R4Name180(name)
        if key == "" then return end
        ui.eventRosterDraft180 = type(ui.eventRosterDraft180) == "table" and ui.eventRosterDraft180 or {}
        if not ui.eventRosterDraft180[key] then ui.eventRosterDraft180[key] = { character = name, class = "", mainRole = "UNASSIGNED", roleNeedsReview180 = true, slotStatus = "GUEST" } end
        editor.addName:SetText("") ui.eventRosterDraftDirty180 = true RaidEditorMarkDirtyPack2(self) self:RefreshEventRosterDraftEditorC5R4() self:RefreshRaidRosterEditor180()
    end, "primary") Move(editor.addGuest, editor, 436, -72, 100, 28)
    editor.rows = {}
    local index
    for index = 1, 11 do
        local row = UI:TableRow(editor, 640, 30, function(button) editor.selectedKey180 = button.memberKey180 self:RefreshEventRosterDraftEditorC5R4() end)
        row.nameText = UI.Text(row, "", "GameFontNormalSmall", "LEFT") row.metaText = UI.Text(row, "", "GameFontNormalSmall", "RIGHT") row.metaText:SetTextColor(C.grey[1],C.grey[2],C.grey[3])
        Move(row, editor, 20, -110 - ((index - 1) * 31), 640, 29) Move(row.nameText, row, 9, -6, 210, 18) Move(row.metaText, row, 226, -6, 402, 18)
        editor.rows[index] = row
    end
    editor.scrollbar = UI:Scrollbar(editor, 340, function(value) editor.offset180 = math.floor(value or 0) self:RefreshEventRosterDraftEditorC5R4() end) Move(editor.scrollbar, editor, 668, -110, 14, 340)
    local function mutate(action, value)
        local member = ui.eventRosterDraft180 and ui.eventRosterDraft180[editor.selectedKey180]
        if not member then return end
        if action == "ROLE" then
            member.mainRole = value member.role = value member.roleNeedsReview180 = nil
            if C5R4Offspec180(member) == value then member.offspecRole = nil end
        elseif action == "OFFSPEC" then
            member.offspecRole = value == "NONE" and nil or value
            if member.offspecRole == C5R4Role180(member) then member.offspecRole = nil end
        elseif action == "SLOT" then member.slotStatus = value
        elseif action == "REMOVE" then ui.eventRosterDraft180[editor.selectedKey180] = nil editor.selectedKey180 = nil end
        ui.eventRosterDraftDirty180 = true RaidEditorMarkDirtyPack2(self) self:RefreshEventRosterDraftEditorC5R4() self:RefreshRaidRosterEditor180()
    end
    editor.remove = UI:Button(editor, "Remove", 66, 24, function() mutate("REMOVE") end, "danger")
    editor.assigned = UI:Button(editor, "Assigned", 72, 24, function() mutate("SLOT", "ASSIGNED") end)
    editor.reserve = UI:Button(editor, "Reserve", 68, 24, function() mutate("SLOT", "RESERVE") end)
    editor.guest = UI:Button(editor, "Guest", 60, 24, function() mutate("SLOT", "GUEST") end)
    editor.tank = UI:Button(editor, "Main Tank", 78, 24, function() mutate("ROLE", "TANK") end)
    editor.healer = UI:Button(editor, "Main Healer", 84, 24, function() mutate("ROLE", "HEALER") end)
    editor.damage = UI:Button(editor, "Main Damage", 92, 24, function() mutate("ROLE", "DAMAGE") end)
    editor.offNone = UI:Button(editor, "OS None", 68, 24, function() mutate("OFFSPEC", "NONE") end)
    editor.offTank = UI:Button(editor, "OS Tank", 68, 24, function() mutate("OFFSPEC", "TANK") end)
    editor.offHealer = UI:Button(editor, "OS Heal", 68, 24, function() mutate("OFFSPEC", "HEALER") end)
    editor.offDamage = UI:Button(editor, "OS Damage", 80, 24, function() mutate("OFFSPEC", "DAMAGE") end)
    local editorRoleButtons180 = {
        { editor.tank, "TANK" }, { editor.healer, "HEALER" }, { editor.damage, "DAMAGE" },
        { editor.offTank, "TANK" }, { editor.offHealer, "HEALER" }, { editor.offDamage, "DAMAGE" },
    }
    local editorRoleIndex180
    for editorRoleIndex180 = 1, table.getn(editorRoleButtons180) do
        local roleButton180 = editorRoleButtons180[editorRoleIndex180][1]
        roleButton180.roleIcon180 = roleButton180:CreateTexture(nil, "ARTWORK")
        roleButton180.roleIcon180:SetWidth(13) roleButton180.roleIcon180:SetHeight(13)
        roleButton180.roleIcon180:SetPoint("LEFT", roleButton180, "LEFT", 4, 0)
        C5R4ApplyRoleIcon180(self, roleButton180.roleIcon180, editorRoleButtons180[editorRoleIndex180][2])
        if roleButton180.text then roleButton180.text:ClearAllPoints() roleButton180.text:SetPoint("CENTER", roleButton180, "CENTER", 6, 0) end
    end
    local controls = { editor.remove, editor.assigned, editor.reserve, editor.guest, editor.tank, editor.healer, editor.damage, editor.offNone, editor.offTank, editor.offHealer, editor.offDamage }
    editor.mutationControls180 = controls
    local x = 20
    for index = 1, 7 do Move(controls[index], editor, x, -466, controls[index]:GetWidth(), 24) x = x + controls[index]:GetWidth() + 4 end
    x = 20
    for index = 8, table.getn(controls) do Move(controls[index], editor, x, -496, controls[index]:GetWidth(), 24) x = x + controls[index]:GetWidth() + 4 end
    editor.close = UI:Button(editor, "Done", 96, 30, function() self:CloseModal180(editor, "done") self:RefreshRaidRosterEditor180() end, "primary") Move(editor.close, editor, 584, -520, 96, 30)
    return true
end

function OTLGM:OpenRaidEventRosterEditor180()
    local ui = self.ui
    if not ui then return false end
    ui.eventRosterDraft180 = type(ui.eventRosterDraft180) == "table" and ui.eventRosterDraft180 or {}
    ui.eventRosterDraftInitialized180 = true
    self:EnsureEventRosterDraftEditorC5R4()
    local editor = ui.eventRosterDraftEditor180 editor.offset180 = 0 editor.selectedKey180 = nil
    self:RefreshEventRosterDraftEditorC5R4()
    if self.ShowModal152 then self:ShowModal152(editor) else editor:Show() end
    return true
end

function OTLGM:RefreshEventRosterDraftEditorC5R4()
    local ui, editor = self.ui, self.ui and self.ui.eventRosterDraftEditor180
    if not editor or not editor:IsVisible() then return false end
    local rows, key, member = {}, nil, nil
    local query = string.lower(tostring(editor.search180 or ""))
    for key, member in pairs(ui.eventRosterDraft180 or {}) do
        if query == "" or string.find(string.lower(tostring(member.character or key)), query, 1, true) then
            table.insert(rows, { key = key, member = member })
        end
    end
    table.sort(rows, function(left,right) return C5R4Name180(left.member and left.member.character) < C5R4Name180(right.member and right.member.character) end)
    local capacity = table.getn(editor.rows or {}) local maximum = math.max(0, table.getn(rows) - capacity)
    editor.offset180 = math.max(0, math.min(maximum, tonumber(editor.offset180) or 0))
    local index, row
    for index = 1, capacity do
        row = editor.rows[index]
        local descriptor = rows[editor.offset180 + index]
        member = descriptor and descriptor.member or nil
        if member then
            key = descriptor.key or C5R4Name180(member.character)
            row.memberKey180 = key
            row.nameText:SetText(tostring(member.character or "Unknown"))
            local role, offspec = C5R4Role180(member), C5R4Offspec180(member)
            row.metaText:SetText(C5R4RoleLabel180(role) .. (offspec ~= "NONE" and ("  •  OS: " .. C5R4RoleLabel180(offspec)) or "") .. "  •  " .. tostring(member.slotStatus or "ASSIGNED"))
            UI:SetSelected(row, key == editor.selectedKey180) row:Show()
        else row.memberKey180 = nil row:Hide() end
    end
    if editor.scrollbar and editor.scrollbar.SetScrollMetrics180 then editor.scrollbar:SetScrollMetrics180(table.getn(rows), capacity, editor.offset180) end
    local total, assigned, reserve, guest, summary = self:GetRaidRosterSummary180(ui.eventRosterDraft180 or {})
    editor.summary:SetText("Tank " .. tostring(summary.TANK or 0) .. "  •  Healer " .. tostring(summary.HEALER or 0) .. "  •  Damage " .. tostring(summary.DAMAGE or 0) .. "  •  Reserve " .. tostring(reserve) .. "  •  Guest " .. tostring(guest) .. ((summary.UNASSIGNED or 0) > 0 and ("  •  |cffff7755Unassigned " .. tostring(summary.UNASSIGNED) .. "|r") or ""))
    local enabled = editor.selectedKey180 and ui.eventRosterDraft180 and ui.eventRosterDraft180[editor.selectedKey180]
    for index = 1, table.getn(editor.mutationControls180 or {}) do UI:SetEnabled(editor.mutationControls180[index], enabled and true or false, "Select an event roster member.") end
    return true
end

function OTLGM:PrepareRaidRosterEditor180(raid, duplicate)
    local ui = self.ui
    if not ui or not ui.raidRosterModeCustom180 then return false end
    ui.eventRosterDraftDirty180 = nil
    ui.raidCustomRoster180 = nil
    if duplicate and raid and type(raid.roster180) == "table" and next(raid.roster180) then
        ui.raidRosterMode180, ui.raidRosterSourceId180 = "CLONE_PREVIOUS", raid.id
        ui.eventRosterDraft180 = self.CopyRaidEventRosterDomain180 and self:CopyRaidEventRosterDomain180(raid.roster180) or C5R4Copy180(raid.roster180)
        ui.eventRosterDraftInitialized180 = true
    elseif raid and not duplicate then
        ui.raidRosterMode180 = raid.rosterSource180 == "RAID_TEAM" and "TEAM" or (raid.rosterSource180 == "CLONE_PREVIOUS" and "CLONE_PREVIOUS" or "KEEP")
        ui.raidRosterSourceId180 = raid.rosterSourceId180 or raid.teamId180
        ui.eventRosterDraft180 = self.CopyRaidEventRosterDomain180 and self:CopyRaidEventRosterDomain180(raid.roster180 or {}) or C5R4Copy180(raid.roster180 or {})
        ui.eventRosterDraftInitialized180 = true
    else
        ui.raidRosterMode180, ui.raidRosterSourceId180 = "CUSTOM", nil
        ui.eventRosterDraft180 = {}
        ui.eventRosterDraftInitialized180 = nil
    end
    ui.raidCustomRoster180 = ui.eventRosterDraft180
    self:RefreshRaidRosterEditor180()
    return true
end

function OTLGM:RefreshRaidRosterEditor180()
    local ui = self.ui
    if not ui or not ui.raidRosterModeCustom180 then return false end
    local mode = ui.raidRosterMode180 or "CUSTOM"
    local teams = self:GetRaidTeamList180(false)
    local previous = self:GetPreviousRaidRosterSources180(ui.raidEditor156 and ui.raidEditor156.editId156)
    UI:SetSelected(ui.raidRosterModeCustom180, mode == "CUSTOM" or mode == "KEEP")
    UI:SetSelected(ui.raidRosterModeTeam180, mode == "TEAM") UI:SetSelected(ui.raidRosterModeClone180, mode == "CLONE_PREVIOUS")
    local label = "Custom independent event roster"
    if mode == "TEAM" then local team = self:GetRaidTeam180(ui.raidRosterSourceId180) label = team and ("Source: copied from " .. tostring(team.name or "Raid Team")) or "Select a Raid Team"
    elseif mode == "CLONE_PREVIOUS" then local event = self:GetRaidRosterSourceEvent180(ui.raidRosterSourceId180) label = event and ("Source: copied from " .. tostring(event.name or "previous raid event")) or "Select a previous event"
    elseif mode == "KEEP" then label = "Current independent event roster" end
    UI:SetText(ui.raidRosterSourceButton180, label .. ((mode == "TEAM" or mode == "CLONE_PREVIOUS") and "  •  Change" or ""))
    local total, assigned, reserve, guest, summary = self:GetRaidRosterSummary180(ui.eventRosterDraft180 or {})
    ui.raidRosterPreview180:SetText("Independent event roster: " .. tostring(total) .. "  |  Tank " .. tostring(summary.TANK or 0) .. "  |  Healer " .. tostring(summary.HEALER or 0) .. "  |  Damage " .. tostring(summary.DAMAGE or 0) .. "  |  Reserve " .. tostring(reserve) .. "  |  Guest " .. tostring(guest) .. ((summary.UNASSIGNED or 0) > 0 and ("  |  |cffff7755Unassigned " .. tostring(summary.UNASSIGNED) .. "|r") or ""))
    UI:SetEnabled(ui.raidRosterModeTeam180, table.getn(teams) > 0, "No active Raid Team available")
    UI:SetEnabled(ui.raidRosterModeClone180, table.getn(previous) > 0, "No previous roster available")
    UI:SetEnabled(ui.raidRosterSourceButton180, mode == "TEAM" or mode == "CLONE_PREVIOUS", "Choose Raid Team or Clone Previous first.")
    if ui.raidRosterCustomEdit180 then UI:SetEnabled(ui.raidRosterCustomEdit180, true) UI:SetText(ui.raidRosterCustomEdit180, "Edit Event Roster") end
    if ui.raidRosterRefreshTeam180 then if mode == "TEAM" then ui.raidRosterRefreshTeam180:Show() else ui.raidRosterRefreshTeam180:Hide() end end
    if ui.raidRosterHelp180 then ui.raidRosterHelp180:SetText("Independent event roster. Main role may be changed for this event; off-spec is only a hint. Team and event never overwrite each other automatically.") end
    return true
end

function OTLGM:CycleRaidRosterSource180()
    local ui = self.ui
    if not ui then return false end
    if ui.raidRosterMode180 == "CLONE_PREVIOUS" then return self:OpenRaidRosterSourceSelector180("CLONE_PREVIOUS") end
    return self:OpenRaidRosterSourceSelector180("TEAM")
end

local PreviousEnsureNativeRaidEventEditorC5R4 = OTLGM.__impl180.EnsureNativeRaidEventEditorPack2__impl1
function OTLGM:EnsureNativeRaidEventEditorPack2()
    local result = PreviousEnsureNativeRaidEventEditorC5R4(self)
    local ui = self.ui
    if not ui or not ui.raidEditorNative180 or ui.raidEditorC5R4Controls180 then return result end
    ui.raidEditorC5R4Controls180 = true
    ui.raidRosterModeTeam180.otlHandler = function() self:OpenRaidRosterSourceSelector180("TEAM") end
    ui.raidRosterModeClone180.otlHandler = function() self:OpenRaidRosterSourceSelector180("CLONE_PREVIOUS") end
    ui.raidRosterSourceButton180.otlHandler = function() self:CycleRaidRosterSource180() end
    ui.raidRosterCustomEdit180.otlHandler = function() self:OpenRaidEventRosterEditor180() end
    ui.raidRosterRefreshTeam180 = UI:Button(ui.raidEditorNative180.content180, "Refresh from Team", 150, 28, function() self:RefreshEventRosterDraftFromTeam180() end, "utility")
    Move(ui.raidRosterSourceButton180, ui.raidEditorNative180.content180, 0, -362, 322, 28)
    Move(ui.raidRosterRefreshTeam180, ui.raidEditorNative180.content180, 330, -362, 150, 28)
    Move(ui.raidRosterCustomEdit180, ui.raidEditorNative180.content180, 488, -362, 158, 28)

    local editor = ui.raidEditorNative180
    local content = editor.content180
    editor.otlContentHeight180 = 822
    if content and content.SetHeight then content:SetHeight(editor.otlContentHeight180) end
    RaidEditorLabelPack2(content, "ACCESS AND TARGETING", 0, -632, 300, true)
    RaidEditorLabelPack2(content, "VISIBILITY", 0, -656, 170)
    RaidEditorLabelPack2(content, "NOTIFICATION AUDIENCE", 218, -656, 210)
    ui.raidVisibility180 = "GUILD_VISIBLE"
    ui.raidNotifyAudience180 = "ASSIGNED"
    local visibilityOrder = { "PRIVATE_TEAM", "GUILD_VISIBLE", "OPEN_GUILD" }
    local visibilityLabels = { PRIVATE_TEAM = "Private Team", GUILD_VISIBLE = "Guild Visible", OPEN_GUILD = "Open Guild" }
    local audienceOrder = { "ASSIGNED", "ASSIGNED_RESERVES", "ENTIRE_TEAM", "ALL_GUILD" }
    local audienceLabels = { ASSIGNED = "Assigned", ASSIGNED_RESERVES = "Assigned + Reserves", ENTIRE_TEAM = "Entire Team", ALL_GUILD = "All Guild" }
    ui.raidVisibilityButton180 = UI:Button(content, "Guild Visible", 202, 30, function()
        local current, index = ui.raidVisibility180 or "GUILD_VISIBLE", 1
        local i for i = 1, table.getn(visibilityOrder) do if visibilityOrder[i] == current then index = i break end end
        index = index + 1 if index > table.getn(visibilityOrder) then index = 1 end
        ui.raidVisibility180 = visibilityOrder[index]
        UI:SetText(ui.raidVisibilityButton180, visibilityLabels[ui.raidVisibility180])
        RaidEditorMarkDirtyPack2(self)
    end, "filter")
    ui.raidNotifyAudienceButton180 = UI:Button(content, "Assigned", 210, 30, function()
        local current, index = ui.raidNotifyAudience180 or "ASSIGNED", 1
        local i for i = 1, table.getn(audienceOrder) do if audienceOrder[i] == current then index = i break end end
        index = index + 1 if index > table.getn(audienceOrder) then index = 1 end
        ui.raidNotifyAudience180 = audienceOrder[index]
        UI:SetText(ui.raidNotifyAudienceButton180, audienceLabels[ui.raidNotifyAudience180])
        RaidEditorMarkDirtyPack2(self)
    end, "filter")
    Move(ui.raidVisibilityButton180, content, 0, -674, 202, 30)
    Move(ui.raidNotifyAudienceButton180, content, 218, -674, 210, 30)
    RaidEditorLabelPack2(content, "DISCORD SIGN-UP LINK", 0, -714, 280)
    RaidEditorLabelPack2(content, "SIGN-UP INSTRUCTION", 326, -714, 300)
    ui.raidDiscordUrl180 = UI:EditBox(content, 310, 30, { placeholder = "https://discord.gg/...", maxLetters = 96, changed = function() RaidEditorMarkDirtyPack2(self) end })
    ui.raidSignUpNote180 = UI:EditBox(content, 320, 30, { placeholder = "Sign-up is managed in Discord", maxLetters = 120, changed = function() RaidEditorMarkDirtyPack2(self) end })
    Move(ui.raidDiscordUrl180, content, 0, -732, 310, 30)
    Move(ui.raidSignUpNote180, content, 326, -732, 320, 30)
    ui.raidTargetingHelp180 = UI.Text(content, "Visibility controls who can read the card. Notification audience controls active alerts. Participant actions still depend on the exact event roster.", "GameFontNormalSmall", "LEFT")
    ui.raidTargetingHelp180:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    ui.raidTargetingHelp180:SetJustifyV("TOP")
    Move(ui.raidTargetingHelp180, content, 0, -772, 646, 36)
    RaidEditorSetScrollPack2(self, editor.otlScroll180 or 0)
    return result
end

local PreviousSaveRaidEditorC5R4 = OTLGM.__impl180.SaveRaidEditor156__impl3
function OTLGM:SaveRaidEditor156()
    local ui = self.ui
    if not ui or not ui.raidEditorNative180 then return PreviousSaveRaidEditorC5R4 and PreviousSaveRaidEditorC5R4(self) end
    local editor = ui.raidEditorNative180
    local rosterMode = ui.raidRosterMode180 or (editor.editId156 and "KEEP" or "CUSTOM")
    local eventDraft = ui.eventRosterDraft180
    if (rosterMode == "TEAM" or rosterMode == "CLONE_PREVIOUS") and not ui.eventRosterDraftInitialized180
        and (type(eventDraft) ~= "table" or not next(eventDraft)) then
        eventDraft = nil
    end
    local data = {
        name = ui.raidName156:GetText(), location = ui.raidLocation156:GetText(), note = ui.raidNote156:GetText(),
        dayOffset = ui.raidDay156:GetText(), hour = ui.raidHour156:GetText(), minute = ui.raidMinute156:GetText(),
        gatherHour = ui.raidGatherHour156:GetText(), gatherMinute = ui.raidGatherMinute156:GetText(),
        recurring = ui.raidRecurring156, reminderMinutes = ui.raidReminder156:GetText(), featured = ui.raidFeatured157,
        raidLeader = ui.raidLeader175:GetText(), inviteContact = ui.raidInviteContact175:GetText(), inviteHelpers = ui.raidInviteHelpers175:GetText(),
        visibility180 = ui.raidVisibility180 or "GUILD_VISIBLE",
        notifyAudience180 = ui.raidNotifyAudience180 or "ASSIGNED",
        discordUrl180 = ui.raidDiscordUrl180 and ui.raidDiscordUrl180:GetText() or "",
        signUpNote180 = ui.raidSignUpNote180 and ui.raidSignUpNote180:GetText() or "",
        rosterMode180 = rosterMode,
        rosterSourceId180 = ui.raidRosterSourceId180,
        customRoster180 = eventDraft,
        eventRosterDraft180 = eventDraft,
    }
    local editId = editor.editId156
    if data.rosterMode180 == "TEAM" then
        local source = self:GetRaidTeam180(data.rosterSourceId180)
        if not source or source.status == "ARCHIVED" then if self.SetStatus then self:SetStatus("The selected Raid Team is no longer available. Choose another team.") end return false end
    elseif data.rosterMode180 == "CLONE_PREVIOUS" then
        local source = self:GetRaidRosterSourceEvent180(data.rosterSourceId180)
        if not source then if self.SetStatus then self:SetStatus("The selected previous event is no longer available.") end return false end
    end
    local ok, result = self:PublishPveRaidEvent156(data, editId)
    if not ok then self:ShowNotice("Raid Event", result or "The raid event could not be saved.") return false end
    editor.otlDirty180 = nil editor.otlForceClose180 = true
    self:CloseModal180(editor, "save-success")
    ui.raidFilter156 = "UPCOMING" ui.raidSelected156 = result.id
    self:SetPveRaidAreaMode180("EVENTS") self:RefreshRaidPlanner156()
    self:SetStatus(editId and "Raid event updated." or "New raid event created.")
    return true, result
end

-- Width-safe Guild/Officer Chat reflow --------------------------------------

local PreviousGetGuildChatRowMetricsC5R4 = OTLGM.__impl180.GetGuildChatRowMetrics__impl4
local R23_CHAT_MEASURE_LIMIT180 = 300

local function ChatNameKey184(value)
    return string.lower(string.gsub(tostring(value or ""), "%-.*$", ""))
end

local function ChatUtf8Length184(text)
    text = tostring(text or "")
    local count, index, byte = 0, 1, nil
    while index <= string.len(text) do
        byte = string.byte(text, index) or 0
        if byte < 128 then index = index + 1
        elseif byte < 224 then index = index + 2
        elseif byte < 240 then index = index + 3
        else index = index + 4 end
        count = count + 1
    end
    return count
end

local function SameChatGroup184(previous, current)
    if not previous or not current then return false end
    if tostring(previous.channel or "") ~= tostring(current.channel or "") then return false end
    if ChatNameKey184(previous.sender or previous.author) ~= ChatNameKey184(current.sender or current.author) then return false end
    local gap = (tonumber(current.ts) or 0) - (tonumber(previous.ts) or 0)
    if gap < 0 or gap > 120 then return false end
    if OTLGM:IsGuildAchievementChatMessage180(previous.text or "") then return false end
    if OTLGM:IsGuildAchievementChatMessage180(current.text or "") then return false end
    return true
end

local function EnsureCanonicalChatMeasureR23(owner)
    owner.ui = owner.ui or {}
    local label = owner.ui.chatMeasureR23
    if label then
        if owner.ApplyGuildChatMessageFont180 then owner:ApplyGuildChatMessageFont180(label) end
        return label
    end
    local holder = CreateFrame("Frame", nil, UIParent)
    holder:SetWidth(12) holder:SetHeight(12)
    holder:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -3200, -3200)
    if holder.SetAlpha then holder:SetAlpha(0) end
    holder:Show()
    label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    label:SetJustifyH("LEFT")
    if label.SetJustifyV then label:SetJustifyV("TOP") end
    if owner.ApplyGuildChatMessageFont180 then owner:ApplyGuildChatMessageFont180(label) end
    owner.ui.chatMeasureHolderR23 = holder
    owner.ui.chatMeasureR23 = label
    return label
end

local function ChatMeasureFontSignatureR23(label)
    if not label or not label.GetFont then return "default:13" end
    local ok, path, size, flags = pcall(label.GetFont, label)
    if not ok then return "default:13" end
    return tostring(path or "default") .. ":" .. tostring(math.floor((tonumber(size) or 13) * 10 + 0.5)) .. ":" .. tostring(flags or "")
end

local function ChatMeasureLineHeightR23(label)
    if label and label.GetFont then
        local ok, _, size = pcall(label.GetFont, label)
        if ok and tonumber(size) then return math.max(12, math.floor(tonumber(size) + 2.5)) end
    end
    return 15
end

local function C5R4ChatMeasureKey180(owner, info, width, achievement, visible, fontSignature)
    local scale = 1
    if UIParent and UIParent.GetEffectiveScale then scale = tonumber(UIParent:GetEffectiveScale()) or 1 end
    local widthPixel = math.floor((tonumber(width) or 0) + 0.5)
    local stable = tostring(info.id or info.messageId or info.ts or "") .. ":" .. tostring(info.author or info.sender or "")
    return stable .. ":" .. tostring(info.channel or "GUILD") .. ":" .. tostring(widthPixel) .. ":" .. tostring(math.floor(scale * 100 + 0.5)) .. ":" .. (achievement and "A" or "M") .. ":" .. tostring(fontSignature or "") .. ":" .. tostring(visible or "")
end

local function CountExplicitChatLinesR23(visible)
    local count, startAt = 1, 1
    while true do
        local newlineAt = string.find(visible, "\n", startAt, true)
        if not newlineAt then break end
        count = count + 1
        startAt = newlineAt + 1
    end
    return count
end

local function MeasureGuildChatTextR23(owner, info, width, achievement)
    width = math.max(120, tonumber(width) or 120)
    local visible = owner:GetGuildChatVisibleText(info and info.text or "")
    local measure = EnsureCanonicalChatMeasureR23(owner)
    local fontSignature = ChatMeasureFontSignatureR23(measure)
    owner.runtime = owner.runtime or {}
    local cache = owner.runtime.chatMeasureCacheR23
    if type(cache) ~= "table" then
        cache = { values = {}, order = {}, hits = 0, misses = 0 }
        owner.runtime.chatMeasureCacheR23 = cache
    end
    local cacheKey = C5R4ChatMeasureKey180(owner, info or {}, width, achievement, visible, fontSignature)
    local cached = cache.values[cacheKey]
    if cached then
        cache.hits = (tonumber(cache.hits) or 0) + 1
        return cached.textHeight, cached.lines, visible
    end

    measure:SetWidth(width)
    measure:SetText(visible)
    local textHeight = measure.GetStringHeight and tonumber(measure:GetStringHeight()) or nil
    local lineHeight = ChatMeasureLineHeightR23(measure)
    local explicitLines = CountExplicitChatLinesR23(visible)

    -- GetStringHeight is the primary authority.  Only if the 1.12-derived
    -- client returns no usable value do we fall back to an UTF-8 character
    -- estimate; raw byte length is never used as the normal line counter.
    if not textHeight or textHeight < 8 then
        local charsPerLine = math.max(12, math.floor(width / math.max(5.5, lineHeight * 0.47)))
        local fallbackLines = math.max(explicitLines, math.max(1, math.ceil(ChatUtf8Length184(visible) / charsPerLine)))
        textHeight = fallbackLines * lineHeight
    end
    textHeight = math.max(lineHeight - 2, math.min(240, math.ceil(textHeight)))
    local lines = math.max(explicitLines, math.max(1, math.floor((textHeight + (lineHeight * 0.30)) / lineHeight)))
    if lines > 16 then lines = 16 end

    cache.values[cacheKey] = { textHeight = textHeight, lines = lines }
    table.insert(cache.order, cacheKey)
    cache.misses = (tonumber(cache.misses) or 0) + 1
    while table.getn(cache.order) > R23_CHAT_MEASURE_LIMIT180 do
        local expired = table.remove(cache.order, 1)
        cache.values[expired] = nil
    end
    return textHeight, lines, visible
end

function OTLGM:GetGuildChatCanonicalTextMetricsR23(info, width, achievement)
    return MeasureGuildChatTextR23(self, info or {}, width, achievement and true or false)
end

function OTLGM:GetGuildChatRowMetrics(messages, index, markerIndex)
    local info = messages and messages[index]
    if not info then return 29, 1, nil, false, 15 end
    local achievement = self:IsGuildAchievementChatMessage180(info.text or "")
    local width = achievement and (self.ui and self.ui.chatAchievementWidth180) or (self.ui and self.ui.chatMessageWidth180)
    if not width or width < 120 then return PreviousGetGuildChatRowMetricsC5R4(self, messages, index, markerIndex) end
    local textHeight, lines = MeasureGuildChatTextR23(self, info, width, achievement)
    local separator = self:GetGuildChatTimeSeparator(messages, index)
    local marker = markerIndex and markerIndex == index
    local nextGrouped = SameChatGroup184(info, messages[index + 1])

    -- Row ownership mirrors the renderer exactly: 3px top inset, explicit
    -- separator/NEW blocks, actual measured message height, then a stable
    -- bottom pad. Continuation changes header visibility and the inter-group
    -- gap only; it never changes the base text box height.
    local messageBlock = math.max(20, textHeight + 2)
    local height = 3 + messageBlock + 3
    if separator then height = height + 17 end
    if marker then height = height + 9 end
    if not nextGrouped then height = height + 3 end
    return height, lines, separator, marker, textHeight
end


local PreviousLayoutGuildChatC5R4 = LayoutGuildChat
LayoutGuildChat = function(owner, page, width, height)
    local view = OTLGM_DB.settings.guildChatView or "GUILD"
    local changed = false
    if view ~= "BOARD" then
        local gap = 12
        local showOfficer = view == "OFFICER" and width >= 840 and owner.ui.officerOnlinePanel
        local officerWidth = showOfficer and math.max(170, math.floor(width * 0.20)) or 0
        local chatWidth = width - (showOfficer and (officerWidth + gap) or 0)
        -- Reserve the row's pin affordance and scrollbar gutter instead of
        -- letting wrapped text run underneath them at compact widths.
        local nextMessageWidth = math.max(172, chatWidth - 332)
        local nextAchievementWidth = math.max(210, chatWidth - 150)
        changed = owner.ui.chatMessageWidth180 ~= nextMessageWidth or owner.ui.chatAchievementWidth180 ~= nextAchievementWidth
        owner.ui.chatMessageWidth180 = nextMessageWidth
        owner.ui.chatAchievementWidth180 = nextAchievementWidth
        if changed then
            owner.ui.chatMeasureRevision180 = (tonumber(owner.ui.chatMeasureRevision180) or 0) + 1
            owner.ui.chatRefreshPending180 = true
        end
    end
    PreviousLayoutGuildChatC5R4(owner, page, width, height)
    if view ~= "BOARD" then
        owner:LayoutChatRows180()
        if changed and owner.MarkLayoutDataRefresh180 then owner:MarkLayoutDataRefresh180("guildchat") end
        local interaction = owner.runtime and owner.runtime.windowInteraction180
        if changed and owner.ScheduleAfter180 and not (interaction and interaction.mode == "RESIZE") then
            owner:ScheduleAfter180("ui-debounce:guildchat-width", 0.01, function(target)
                if target.ui then target.ui.chatRefreshPending180 = nil end
                local pending = target.runtime and target.runtime.layoutDataRefresh180 and target.runtime.layoutDataRefresh180.guildchat
                if pending and target.ui and target.ui.currentPage == "guildchat" and type(target.RefreshGuildChatPage) == "function" then
                    -- Re-enter the public native refresh path only if the shell
                    -- did not already flush this capacity change synchronously.
                    target.runtime.layoutDataRefresh180.guildchat = nil
                    target:RefreshGuildChatPage("width-reflow")
                end
            end, 20)
        end
    end
end

-- The shell module resolves LAYOUTS dynamically. Publish this final wrapper so
-- its width-aware reflow is the actual Guild Chat layout owner, rather than a
-- dead late local reassignment.
LAYOUTS.guildchat = LayoutGuildChat

-- r23 Guild Chat runtime geometry finalizer ---------------------------------
--
-- Several older presentation layers still decorate Guild Chat after the base
-- refresh and historically also changed ScrollingMessageFrame height using
-- their own measurement FontStrings.  Keep those visual features, then restore
-- one canonical width/font/height contract at the very end of the public
-- refresh path.  This is intentionally event/refresh driven; no OnUpdate or
-- polling loop is introduced.

local function GuildChatDiagnosticPrintR23(text)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffcc33[Lion GM ChatDiag]|r " .. tostring(text or ""))
    end
end

local function CurrentGuildChatRowsR23(owner)
    local result = {}
    local index, row
    for index = 1, table.getn(owner.ui and owner.ui.chatRows or {}) do
        row = owner.ui.chatRows[index]
        if row and row:IsVisible() and row.chatData then table.insert(result, row) end
    end
    return result
end

function OTLGM:CaptureGuildChatDiagnosticsR23(reason)
    local diag = self.runtime and self.runtime.guildChatDiagnosticsR23
    if not diag or not diag.enabled or not self.ui then return nil end
    local channel = self:GetGuildChatChannel()
    local messages = self:GetGuildChatMessages(channel) or {}
    local markerIndex = self:GetGuildChatMarkerIndex(messages, channel)
    local totalHeight = 0
    local index, height
    for index = 1, table.getn(messages) do
        height = self:GetGuildChatRowMetrics(messages, index, markerIndex)
        totalHeight = totalHeight + (tonumber(height) or 0)
    end
    local minValue, maxValue = 0, 0
    if self.ui.chatSlider and self.ui.chatSlider.GetMinMaxValues then minValue, maxValue = self.ui.chatSlider:GetMinMaxValues() end
    local report = {
        reason = tostring(reason or "refresh"),
        channel = channel,
        messageCount = table.getn(messages),
        viewportHeight = self:GetGuildChatViewportHeight180(),
        contentHeight = totalHeight,
        offset = self.ui.chatOffsets and (tonumber(self.ui.chatOffsets[channel]) or 0) or 0,
        scrollMin = tonumber(minValue) or 0,
        scrollMax = tonumber(maxValue) or 0,
        bottomSlackR28 = tonumber(self.ui.chatBottomSlackR28) or 0,
        bottomAnchoredR28 = self.ui.chatBottomAnchoredR28 and true or false,
        bottomInsetR28 = tonumber(self.ui.chatHistoryBottomInsetR28) or 0,
        rows = {},
    }
    local rows = CurrentGuildChatRowsR23(self)
    local previous = nil
    for index = 1, math.min(20, table.getn(rows)) do
        local row = rows[index]
        local info = row.chatData
        local achievement = self:IsGuildAchievementChatMessage180(info.text or "")
        local width = achievement and (tonumber(self.ui.chatAchievementWidth180) or 0) or (tonumber(self.ui.chatMessageWidth180) or 0)
        local textHeight, lines, visible = self:GetGuildChatCanonicalTextMetricsR23(info, width, achievement)
        local grouped = SameChatGroup184(previous, info)
            and not (row.separatorText and row.separatorText:IsVisible())
            and not (row.newLine and row.newLine:IsVisible())
        table.insert(report.rows, {
            width = width,
            textHeight = textHeight,
            lines = lines,
            rowHeight = tonumber(row:GetHeight()) or 0,
            top = tonumber(row.otlChatTop180) or -1,
            bottom = tonumber(row.otlChatBottom180) or -1,
            grouped = grouped and true or false,
            separator = row.separatorText and row.separatorText:IsVisible() and true or false,
            marker = row.newLine and row.newLine:IsVisible() and true or false,
            visibleChars = ChatUtf8Length184(visible or ""),
            achievement = achievement and true or false,
        })
        previous = info
    end
    diag.last = report
    return report
end

function OTLGM:PrintGuildChatDiagnosticsR23(reason)
    local report = self:CaptureGuildChatDiagnosticsR23(reason or "manual-dump")
    if not report then GuildChatDiagnosticPrintR23("Diagnostics are off. Use /otl chatdiag on first.") return false end
    GuildChatDiagnosticPrintR23("reason=" .. report.reason .. " channel=" .. tostring(report.channel)
        .. " messages=" .. tostring(report.messageCount) .. " viewport=" .. tostring(math.floor(report.viewportHeight + 0.5))
        .. " content=" .. tostring(math.floor(report.contentHeight + 0.5)) .. " offset=" .. tostring(report.offset)
        .. " scroll=" .. tostring(report.scrollMin) .. ".." .. tostring(report.scrollMax)
        .. " bottomSlack=" .. tostring(math.floor((report.bottomSlackR28 or 0) + 0.5))
        .. " anchored=" .. tostring(report.bottomAnchoredR28 and 1 or 0)
        .. " inset=" .. tostring(report.bottomInsetR28 or 0))
    local index, row
    for index = 1, table.getn(report.rows or {}) do
        row = report.rows[index]
        GuildChatDiagnosticPrintR23("row" .. tostring(index)
            .. " w=" .. tostring(math.floor((row.width or 0) + 0.5))
            .. " textH=" .. tostring(math.floor((row.textHeight or 0) + 0.5))
            .. " rowH=" .. tostring(math.floor((row.rowHeight or 0) + 0.5))
            .. " y=" .. tostring(math.floor((row.top or 0) + 0.5)) .. ".." .. tostring(math.floor((row.bottom or 0) + 0.5))
            .. " lines=" .. tostring(row.lines or 1) .. " chars=" .. tostring(row.visibleChars or 0)
            .. " group=" .. tostring(row.grouped and 1 or 0)
            .. " sep=" .. tostring(row.separator and 1 or 0)
            .. " new=" .. tostring(row.marker and 1 or 0)
            .. " ach=" .. tostring(row.achievement and 1 or 0))
    end
    return true
end

function OTLGM:ApplyCanonicalGuildChatGeometryR23(reason)
    if not self.ui or not self.ui.chatRows then return false end
    if (OTLGM_DB.settings.guildChatView or "GUILD") == "BOARD" then return false end
    local previous = nil
    local index, row, info, achievement, width, textHeight, grouped
    for index = 1, table.getn(self.ui.chatRows) do
        row = self.ui.chatRows[index]
        info = row and row:IsVisible() and row.chatData or nil
        if info then
            achievement = self:IsGuildAchievementChatMessage180(info.text or "")
            width = achievement and (tonumber(self.ui.chatAchievementWidth180) or 210)
                or (tonumber(self.ui.chatMessageWidth180) or 172)
            textHeight = self:GetGuildChatCanonicalTextMetricsR23(info, width, achievement)
            if row.messageFrame then
                row.messageFrame:SetWidth(math.max(achievement and 210 or 172, width))
                row.messageFrame:SetHeight(math.max(18, (tonumber(textHeight) or 15) + 2))
                if row.messageFrame.SetInsertMode then row.messageFrame:SetInsertMode("TOP") end
                if row.messageFrame.SetJustifyV then row.messageFrame:SetJustifyV("TOP") end
                if row.messageFrame.ScrollToTop then row.messageFrame:ScrollToTop() end
            end
            grouped = SameChatGroup184(previous, info)
                and not (row.separatorText and row.separatorText:IsVisible())
                and not (row.newLine and row.newLine:IsVisible())
            if achievement then
                row.timeText:Show()
                row.rankButton:Hide()
                row.senderButton:Hide()
                if row.continuationR5 then row.continuationR5:Hide() end
            elseif grouped then
                row.timeText:Hide()
                row.rankButton:Hide()
                row.senderButton:Hide()
                if row.continuationR5 then
                    row.continuationR5:ClearAllPoints()
                    row.continuationR5:SetPoint("TOPLEFT", row, "TOPLEFT", 214, -2)
                    row.continuationR5:SetHeight(math.max(12, row:GetHeight() - 6))
                    row.continuationR5:Show()
                end
            else
                row.timeText:Show()
                row.rankButton:Show()
                row.senderButton:Show()
                if row.continuationR5 then row.continuationR5:Hide() end
            end
            if row.newLine and row.newLine:IsVisible() then
                local markerY = -3
                if row.separatorText and row.separatorText:IsVisible() then markerY = markerY - 17 end
                row.newLine:ClearAllPoints()
                row.newLine:SetPoint("TOPLEFT", row, "TOPLEFT", 0, markerY - 2)
                if row.newText then
                    row.newText:ClearAllPoints()
                    row.newText:SetPoint("TOPLEFT", row, "TOPLEFT", math.max(120, (tonumber(row:GetWidth()) or 1) - 64), markerY - 1)
                end
            end
            if row.channelAccent then row.channelAccent:SetHeight(row:GetHeight()) end
            previous = info
        else
            if row and row.continuationR5 then row.continuationR5:Hide() end
        end
    end
    self:LayoutChatRows180()
    self:CaptureGuildChatDiagnosticsR23(reason or "refresh")
    return true
end

local PreviousRefreshGuildChatR23 = OTLGM.RefreshGuildChatPage
if PreviousRefreshGuildChatR23 then
    function OTLGM:RefreshGuildChatPage(reason)
        local page = self.ui and self.ui.pages and self.ui.pages.guildchat
        local view = OTLGM_DB.settings.guildChatView or "GUILD"
        local pageWidth = page and page.GetWidth and tonumber(page:GetWidth()) or 0
        local pageHeight = page and page.GetHeight and tonumber(page:GetHeight()) or 0
        local state = self.ui and self.ui.chatGeometryStateR23
        local pageReadyR54 = page and not page.otlLazyShell and page.otlBuilt
            and self.ui and self.ui.chatChannelButtons and self.ui.chatList
        local needsPreLayout = pageReadyR54 and view ~= "BOARD" and (not self.ui.chatMessageWidth180
            or not state or state.view ~= view
            or math.abs((tonumber(state.width) or 0) - pageWidth) > 1
            or math.abs((tonumber(state.height) or 0) - pageHeight) > 1)
        if needsPreLayout then LayoutGuildChat(self, page, pageWidth, pageHeight) end

        -- NativePages' registered public wrapper performs the source refresh and
        -- then a dynamic LayoutShellPage180 pass, so at return time responsive
        -- row widths are authoritative again.  Finalize only text geometry here
        -- instead of redundantly running a second full page layout every refresh.
        local result = PreviousRefreshGuildChatR23(self, reason)
        if result ~= false then
            if view ~= "BOARD" then self:ApplyCanonicalGuildChatGeometryR23(reason or "refresh") end
            self.ui.chatGeometryStateR23 = { view = view, width = pageWidth, height = pageHeight }
        end
        return result
    end
end

-- Temporary, opt-in live instrumentation requested by the r23 geometry stage.
-- It stores only the latest compact metrics snapshot and performs no work while
-- disabled.  Nothing is written to SavedVariables.
local PreviousGuildChatSlashR23 = SlashCmdList and SlashCmdList["OTLGM"]
if SlashCmdList then
    SlashCmdList["OTLGM"] = function(message)
        local raw = tostring(message or "")
        local normalized = string.lower(string.gsub(string.gsub(raw, "^%s+", ""), "%s+$", ""))
        if normalized == "enchantdiag on" then
            if OTLGM.SetEnchantDiagnosticsR24 then OTLGM:SetEnchantDiagnosticsR24(true) end
            if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffcc33[Lion GM EnchantDiag]|r Enabled for this session. Select an enchant, hover its result icon if needed, then use /otl enchantdiag dump.") end
            return
        elseif normalized == "enchantdiag off" then
            if OTLGM.SetEnchantDiagnosticsR24 then OTLGM:SetEnchantDiagnosticsR24(false) end
            if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffcc33[Lion GM EnchantDiag]|r Disabled.") end
            return
        elseif normalized == "enchantdiag dump" then
            if OTLGM.PrintEnchantDiagnosticsR24 then OTLGM:PrintEnchantDiagnosticsR24() end
            return
        elseif normalized == "enchantdiag" then
            if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffcc33[Lion GM EnchantDiag]|r Use /otl enchantdiag on | /otl enchantdiag dump | /otl enchantdiag off") end
            return
        elseif normalized == "chatdiag on" then
            OTLGM.runtime = OTLGM.runtime or {}
            OTLGM.runtime.guildChatDiagnosticsR23 = OTLGM.runtime.guildChatDiagnosticsR23 or {}
            OTLGM.runtime.guildChatDiagnosticsR23.enabled = true
            GuildChatDiagnosticPrintR23("Enabled for this session. Reproduce the chat layout, then use /otl chatdiag dump.")
            if OTLGM.RefreshGuildChatPage then OTLGM:RefreshGuildChatPage("diag-enable") end
            return
        elseif normalized == "chatdiag off" then
            if OTLGM.runtime and OTLGM.runtime.guildChatDiagnosticsR23 then OTLGM.runtime.guildChatDiagnosticsR23.enabled = nil end
            GuildChatDiagnosticPrintR23("Disabled.")
            return
        elseif normalized == "chatdiag dump" then
            OTLGM:PrintGuildChatDiagnosticsR23("manual-dump")
            return
        elseif normalized == "chatdiag" then
            GuildChatDiagnosticPrintR23("Use /otl chatdiag on | /otl chatdiag dump | /otl chatdiag off")
            return
        end
        if PreviousGuildChatSlashR23 then return PreviousGuildChatSlashR23(message) end
    end
end

-- GUILD_ROSTER_UPDATE pruning is event-driven and session-only.
function OTLGM:OnGuildRosterUpdatedRecruitmentC5R4()
    if self.PruneRecentRecruitmentContacts180 then self:PruneRecentRecruitmentContacts180() end
    if self.ui and self.ui.recentWhispersDrawer180 and self.ui.recentWhispersDrawer180:IsVisible() and self.RefreshRecentWhispers180 then self:RefreshRecentWhispers180() end
end
