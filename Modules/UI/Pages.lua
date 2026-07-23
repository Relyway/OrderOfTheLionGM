-- Order of the Lion Guild Manager
-- Composed pages for crafting, search, announcements, PvE and UI polish.

OTLGM.nextUILoaded = true
OTLGM.nextUIVersion = OTLGM.version

local BaseBuildUI = OTLGM._Stage_UI_BuildUI_1
local BaseRefreshNavigation = OTLGM._Stage_UI_RefreshNavigation_1
local BaseShowPage = OTLGM._Stage_UI_ShowPage_1
local BaseRefreshVisiblePage = OTLGM._Stage_UI_RefreshVisiblePage_1
local BaseRefreshHomePage = OTLGM._Stage_UI_RefreshHomePage_1
local BaseRefreshOverviewPage = OTLGM._Stage_UI_RefreshOverviewPage_1
local BaseRefreshPvePage = OTLGM._Stage_UI_RefreshPvePage_1
local BaseRefreshSettingsPage = OTLGM._Stage_UI_RefreshSettingsPage_1
local BaseRefreshAll = OTLGM._Stage_UI_RefreshAll_1
local BaseRefreshWizard = OTLGM._Stage_UI_RefreshWizard_1

local N_PAGE_WIDTH = 756
local N_PAGE_HEIGHT = 532
local N_RECIPE_ROWS = 8
local N_CRAFTER_ROWS = 5
local N_REQUEST_ROWS = 9
local N_RESPONSE_ROWS = 4
local N_SEARCH_ROWS = 12

local function NBackdrop(frame, inset)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = inset or 4, right = inset or 4, top = inset or 4, bottom = inset or 4 },
    })
end

local function NText(parent, template, text, x, y, width, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then fs:SetWidth(width) end
    fs:SetJustifyH(justify or "LEFT")
    fs:SetText(text or "")
    return fs
end

local function NWrapped(parent, template, text, x, y, width, height)
    local fs = NText(parent, template, text, x, y, width, "LEFT")
    fs:SetJustifyV("TOP")
    if height then fs:SetHeight(height) end
    return fs
end

local function NApplyButton(button)
    if not button or not button.SetBackdropColor then return end
    if OTLGM.ApplyButtonSkin and OTLGM:ApplyButtonSkin(button) then return end
    if button.disabled then
        button:SetBackdropColor(0.055, 0.050, 0.045, 0.98)
        button:SetBackdropBorderColor(0.22, 0.20, 0.17, 1)
        if button.text then button.text:SetTextColor(0.42, 0.40, 0.36) end
        return
    end
    local style = button.actionStyle or "normal"
    if style == "section" then
        button:SetBackdropColor(0.020, 0.018, 0.015, button.hovered and 0.98 or 0.72)
        button:SetBackdropBorderColor(button.selected and 0.74 or 0.34, button.selected and 0.48 or 0.27, button.selected and 0.14 or 0.13, 0.95)
        if button.text then
            if button.selected or button.hovered then button.text:SetTextColor(1.0, 0.82, 0.30)
            else button.text:SetTextColor(0.72, 0.65, 0.50) end
        end
        return
    end
    if button.selected then
        if style == "raid" then
            button:SetBackdropColor(0.39, 0.025, 0.018, 1)
            button:SetBackdropBorderColor(1.0, 0.27, 0.16, 1)
            if button.text then button.text:SetTextColor(1.0, 0.76, 0.52) end
        elseif style == "utility" then
            button:SetBackdropColor(0.035, 0.14, 0.27, 1)
            button:SetBackdropBorderColor(0.32, 0.67, 1.0, 1)
            if button.text then button.text:SetTextColor(0.74, 0.89, 1.0) end
        elseif style == "confirm" then
            button:SetBackdropColor(0.035, 0.22, 0.075, 1)
            button:SetBackdropBorderColor(0.28, 0.80, 0.36, 1)
            if button.text then button.text:SetTextColor(0.70, 1.0, 0.72) end
        else
            button:SetBackdropColor(0.34, 0.18, 0.025, 1)
            button:SetBackdropBorderColor(1.0, 0.72, 0.24, 1)
            if button.text then button.text:SetTextColor(1.0, 0.84, 0.36) end
        end
    elseif button.hovered then
        if style == "raid" then
            button:SetBackdropColor(0.31, 0.045, 0.030, 1)
            button:SetBackdropBorderColor(0.92, 0.40, 0.22, 1)
        elseif style == "utility" then
            button:SetBackdropColor(0.040, 0.125, 0.235, 1)
            button:SetBackdropBorderColor(0.34, 0.65, 0.96, 1)
        elseif style == "confirm" then
            button:SetBackdropColor(0.040, 0.25, 0.085, 1)
            button:SetBackdropBorderColor(0.32, 0.90, 0.42, 1)
        else
            button:SetBackdropColor(0.25, 0.10, 0.025, 1)
            button:SetBackdropBorderColor(0.84, 0.55, 0.18, 1)
        end
        if button.text then button.text:SetTextColor(1.0, 0.88, 0.48) end
    elseif style == "raid" then
        button:SetBackdropColor(0.20, 0.023, 0.018, 1)
        button:SetBackdropBorderColor(0.52, 0.12, 0.08, 1)
        if button.text then button.text:SetTextColor(1.0, 0.66, 0.42) end
    elseif style == "utility" then
        button:SetBackdropColor(0.022, 0.075, 0.15, 1)
        button:SetBackdropBorderColor(0.24, 0.45, 0.72, 1)
        if button.text then button.text:SetTextColor(0.61, 0.79, 1.0) end
    elseif style == "confirm" then
        button:SetBackdropColor(0.025, 0.16, 0.055, 1)
        button:SetBackdropBorderColor(0.21, 0.62, 0.29, 1)
        if button.text then button.text:SetTextColor(0.56, 0.94, 0.62) end
    elseif style == "danger" then
        button:SetBackdropColor(0.20, 0.025, 0.020, 1)
        button:SetBackdropBorderColor(0.60, 0.14, 0.10, 1)
        if button.text then button.text:SetTextColor(1.0, 0.56, 0.46) end
    else
        button:SetBackdropColor(0.105, 0.065, 0.022, 1)
        button:SetBackdropBorderColor(0.50, 0.33, 0.13, 1)
        if button.text then button.text:SetTextColor(1.0, 0.79, 0.28) end
    end
end

local function NButton(parent, text, x, y, width, height, handler, style)
    local button = CreateFrame("Button", nil, parent)
    OTLGM:PrepareInteractiveControl170(button, "button")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetWidth(width)
    button:SetHeight(height)
    NBackdrop(button, 3)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.text:SetText(text or "")
    button.labelText = text or ""
    button.handler = handler
    button.actionStyle = style or "normal"
    button:SetScript("OnEnter", function()
        if this.disabled then
            if this.disabledReason then
                GameTooltip:SetOwner(this, "ANCHOR_LEFT")
                GameTooltip:AddLine("Unavailable", 1, 0.72, 0.28)
                GameTooltip:AddLine(this.disabledReason, 1, 1, 1, true)
                GameTooltip:Show()
            end
            return
        end
        this.hovered = true
        NApplyButton(this)
        if this.recipeData and OTLGM.ShowCraftingResultTooltip then OTLGM:ShowCraftingResultTooltip(this, this.recipeData) end
    end)
    button:SetScript("OnLeave", function()
        this.hovered = false
        NApplyButton(this)
        GameTooltip:Hide()
    end)
    button:SetScript("OnClick", function()
        if this.disabled then
            if this.disabledReason and OTLGM and OTLGM.Notify then OTLGM:Notify("Action Unavailable", this.disabledReason) end
            return
        end
        if this.handler then this.handler() end
    end)
    NApplyButton(button)
    return button
end

local function NSetButtonText(button, text)
    if not button then return end
    button.labelText = text or ""
    if button.text then button.text:SetText(text or "") end
end

local function NSetSelected(button, selected)
    if not button then return end
    button.selected = selected and true or false
    NApplyButton(button)
end

local function NSetEnabled(button, enabled, reason)
    if not button then return end
    OTLGM:SetControlEnabled170(button, enabled, reason)
    NApplyButton(button)
end

local function NIcon(button, texture, size)
    if not button or not texture then return end
    button.iconTexture = button.iconTexture or button:CreateTexture(nil, "OVERLAY")
    button.iconTexture:SetTexture(texture)
    button.iconTexture:SetWidth(size or 16)
    button.iconTexture:SetHeight(size or 16)
    button.iconTexture:SetPoint("LEFT", button, "LEFT", 8, 0)
    button.iconTexture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    if button.text then
        button.text:ClearAllPoints()
        button.text:SetPoint("LEFT", button, "LEFT", 30, 0)
        button.text:SetWidth((button:GetWidth() or 0) - 36)
        button.text:SetJustifyH("LEFT")
    end
end

local function NEdit(parent, name, x, y, width, height, multiline)
    local edit = CreateFrame("EditBox", name, parent)
    OTLGM:PrepareInteractiveControl170(edit, "editbox")
    edit:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    edit:SetWidth(width)
    edit:SetHeight(height)
    edit:SetAutoFocus(false)
    edit:SetFontObject("GameFontHighlightSmall")
    edit:SetTextInsets(8, 8, 7, 7)
    if multiline then edit:SetMultiLine(true) end
    NBackdrop(edit, 4)
    edit:SetBackdropColor(0.012, 0.012, 0.012, 0.995)
    edit:SetBackdropBorderColor(0.38, 0.30, 0.18, 1)
    if OTLGM.ApplyEditSkin then OTLGM:ApplyEditSkin(edit) end
    edit:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    return edit
end

local function NPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -14)
    page:SetWidth(N_PAGE_WIDTH)
    page:SetHeight(N_PAGE_HEIGHT)
    page:Hide()
    return page
end

local function NPanel(parent, x, y, width, height, r, g, b)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    panel:SetWidth(width)
    panel:SetHeight(height)
    NBackdrop(panel, 5)
    panel:SetBackdropColor(r or 0.026, g or 0.023, b or 0.019, 0.995)
    panel:SetBackdropBorderColor(0.37, 0.28, 0.16, 1)
    if OTLGM.ApplyPanelSkin then OTLGM:ApplyPanelSkin(panel, "surface") end
    return panel
end

local function NShort(text, limit)
    text = tostring(text or "")
    if string.len(text) <= (limit or 50) then return text end
    return OTLGM:Utf8Truncate(text, (limit or 50) - 3) .. "..."
end

local N_QUALITY_HEX_155 = {
    [0] = "9d9d9d", [1] = "ffffff", [2] = "1eff00", [3] = "0070dd",
    [4] = "a335ee", [5] = "ff8000", [6] = "e6cc80",
}

local function NQualityText155(text, quality)
    local hex = N_QUALITY_HEX_155[tonumber(quality)] or "b8b8b8"
    return "|cff" .. hex .. tostring(text or "") .. "|r"
end

local function NValidTexture155(texture)
    return OTLGM:IsTextureReference(texture) and texture or nil
end

local function NResolveRecipeTexture155(recipe)
    if not recipe then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    local itemId = tonumber(recipe.itemId) or 0
    if itemId > 0 and GetItemInfo then
        local _, _, _, _, _, _, _, _, _, cached = OTLGM:GetItemInfoSafe(itemId)
        if NValidTexture155(cached) then recipe.icon = cached return cached end
    end
    return NValidTexture155(recipe.icon) or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function NAge(self, timestamp)
    if not timestamp or timestamp <= 0 then return "unknown" end
    local elapsed = math.max(0, self:Now() - timestamp)
    if elapsed < 60 then return "just now" end
    if elapsed < 3600 then return tostring(math.floor(elapsed / 60)) .. "m ago" end
    if elapsed < 86400 then return tostring(math.floor(elapsed / 3600)) .. "h ago" end
    return tostring(math.floor(elapsed / 86400)) .. "d ago"
end

local function NDateText()
    return date("%A", time()) .. "  |  " .. date("%d %B", time())
end

local function NRankPriority(info)
    if info.leadership then return 1 end
    local rank = string.lower(info.rank or "")
    if string.find(rank, "core raider", 1, true) or string.find(rank, "devoted", 1, true) then return 2 end
    if rank == "raider" or string.find(rank, "raider", 1, true) then return 3 end
    return 4
end

local function NFindRecipe(results, key)
    local i
    for i = 1, table.getn(results or {}) do if results[i].key == key then return results[i] end end
    return nil
end

local function NFindRequest(requests, id)
    local i
    for i = 1, table.getn(requests or {}) do if requests[i].id == id then return requests[i] end end
    return nil
end

local function NReactionText(summary, key, label)
    local count = tonumber(summary and summary[key]) or 0
    if count > 0 then return label .. " " .. tostring(count) end
    return label
end

local function NAttachReactionTooltip(button, targetType, reaction, label, targetGetter)
    if not button then return end
    button:SetScript("OnEnter", function()
        if this.disabled then return end
        this.hovered = true
        NApplyButton(this)
        local targetId = targetGetter and targetGetter() or nil
        if not targetId then return end
        local names = OTLGM:GetCommunityReactors(targetType, targetId, reaction)
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:AddLine(label or reaction, 1, 0.82, 0.35)
        if table.getn(names) == 0 then
            GameTooltip:AddLine("No reactions yet.", 0.62, 0.62, 0.62)
        else
            local i
            for i = 1, math.min(12, table.getn(names)) do GameTooltip:AddLine(names[i], 1, 1, 1) end
            if table.getn(names) > 12 then GameTooltip:AddLine("...and " .. tostring(table.getn(names) - 12) .. " more", 0.62, 0.62, 0.62) end
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        this.hovered = false
        NApplyButton(this)
        GameTooltip:Hide()
    end)
end

function OTLGM:BuildNextSearchPage(page)
    NText(page, "GameFontNormalLarge", "Guild Search", 0, -2, 400, "LEFT")
    NWrapped(page, "GameFontNormalSmall", "Search members, recipes, open groups, crafting requests, Guild Board posts and leadership announcements from one place.", 0, -28, 700, 32)

    local searchBar = NPanel(page, 0, -60, 718, 56, 0.035, 0.030, 0.022)
    self.ui.globalSearchEdit = NEdit(searchBar, "OTLGM_GlobalSearch", 12, -12, 580, 32, false)
    self.ui.globalSearchEdit:SetMaxLetters(64)
    self.ui.globalSearchEdit:SetText(OTLGM_DB.settings.globalSearch or "")
    self.ui.globalSearchHint = NText(self.ui.globalSearchEdit, "GameFontNormalSmall", "Search guild...", 8, -9, 500, "LEFT")
    self.ui.globalSearchHint:SetTextColor(0.42, 0.42, 0.42)
    self.ui.globalSearchButton = NButton(searchBar, "Search", 602, -12, 104, 32, function() OTLGM:RefreshSearchPage(true) end, "utility")
    self.ui.globalSearchEdit:SetScript("OnEnterPressed", function() this:ClearFocus() OTLGM:RefreshSearchPage(true) end)
    self.ui.globalSearchEdit:SetScript("OnTextChanged", function()
        OTLGM_DB.settings.globalSearch = this:GetText() or ""
        OTLGM.ui.searchDirty = true
        OTLGM.ui.searchDirtyElapsed = 0
        if OTLGM.ui.globalSearchHint then
            if (this:GetText() or "") == "" then OTLGM.ui.globalSearchHint:Show() else OTLGM.ui.globalSearchHint:Hide() end
        end
    end)

    local list = NPanel(page, 0, -126, 718, 376, 0.018, 0.017, 0.015)
    self.ui.globalSearchRows = {}
    local i
    for i = 1, N_SEARCH_ROWS do
        local row = NButton(list, "", 10, -10 - ((i - 1) * 29), 698, 27, function()
            if this.resultData then OTLGM:OpenGlobalSearchResult(this.resultData) end
        end, "normal")
        row.text:Hide()
        row.typeText = NText(row, "GameFontNormalSmall", "", 8, -8, 100, "LEFT")
        row.titleText = NText(row, "GameFontNormal", "", 112, -7, 218, "LEFT")
        row.detailText = NText(row, "GameFontHighlightSmall", "", 336, -7, 352, "LEFT")
        row:Hide()
        self.ui.globalSearchRows[i] = row
    end
    self.ui.globalSearchStatus = NText(page, "GameFontNormalSmall", "Enter at least two characters to search.", 0, -514, 560, "LEFT")
    self.ui.globalSearchPrev = NButton(page, "Previous", 574, -506, 68, 26, function()
        OTLGM.ui.globalSearchOffset = math.max(0, (OTLGM.ui.globalSearchOffset or 0) - N_SEARCH_ROWS)
        OTLGM:RefreshSearchPage(true)
    end, "utility")
    self.ui.globalSearchNext = NButton(page, "Next", 650, -506, 68, 26, function()
        OTLGM.ui.globalSearchOffset = (OTLGM.ui.globalSearchOffset or 0) + N_SEARCH_ROWS
        OTLGM:RefreshSearchPage(true)
    end, "utility")
    page:EnableMouseWheel(1)
    page:SetScript("OnMouseWheel", function()
        if arg1 > 0 then OTLGM.ui.globalSearchOffset = math.max(0, (OTLGM.ui.globalSearchOffset or 0) - N_SEARCH_ROWS)
        else OTLGM.ui.globalSearchOffset = (OTLGM.ui.globalSearchOffset or 0) + N_SEARCH_ROWS end
        OTLGM:RefreshSearchPage(true)
    end)
end

function OTLGM:OpenGlobalSearchResult(result)
    if not result then return end
    if result.type == "MEMBER" then
        self.ui.selectedMember = result.target
        if OTLGM_DB and OTLGM_DB.settings then OTLGM_DB.settings.rosterSearch = result.target or "" end
        if self.ui.rosterSearch then self.ui.rosterSearch:SetText(result.target or "") end
        self:ShowPage("roster")
        if self.SelectRosterMember then self:SelectRosterMember(result.target) end
        return
    end
    if result.type == "RECIPE" then
        OTLGM_DB.settings.craftingSection = "RECIPES"
        OTLGM_DB.settings.craftingSearch = result.title or ""
        self.ui.craftingSelectedRecipe = result.target
        self:ShowPage("professions")
        return
    end
    if result.type == "CRAFT REQUEST" then
        OTLGM_DB.settings.craftingSection = "REQUESTS"
        self.ui.craftingSelectedRequest = result.target
        self:ShowPage("professions")
        return
    end
    if result.type == "GROUP" then
        OTLGM_DB.settings.pveSection = "GROUPS"
        self.ui.pveSelectedRequest = result.target
        self:ShowPage("pve")
        if self.ShowPveSection then self:ShowPveSection("GROUPS") end
        return
    end
    if result.type == "BOARD" then
        self:ShowPage("guildchat")
        self.ui.guildBoardSelected152 = result.target
        if self.SelectGuildChatView152 then self:SelectGuildChatView152("BOARD") end
        return
    end
    if result.type == "ANNOUNCEMENT" then
        self:ShowPage("home")
        if result.target and self.OpenAnnouncementReader152 then self:OpenAnnouncementReader152(result.target) end
    end
end

function OTLGM:RefreshSearchPage(force)
    if not self.ui or not self.ui.globalSearchRows then return end
    local query = self.ui.globalSearchEdit and (self.ui.globalSearchEdit:GetText() or "") or (OTLGM_DB.settings.globalSearch or "")
    local results = {}
    if string.len(query) >= 2 then results = self:GetGlobalSearchResults(query) end
    local offset = math.max(0, self.ui.globalSearchOffset or 0)
    local maximum = math.max(0, table.getn(results) - N_SEARCH_ROWS)
    if offset > maximum then offset = maximum end
    self.ui.globalSearchOffset = offset
    local i, row, result
    for i = 1, N_SEARCH_ROWS do
        row = self.ui.globalSearchRows[i]
        result = results[offset + i]
        if result then
            row.resultData = result
            row.typeText:SetText(self.colors.gold .. (result.type or "RESULT") .. self.colors.reset)
            row.titleText:SetText(self:GetClassColor(result.class) .. NShort(result.title, 28) .. self.colors.reset)
            row.detailText:SetText(NShort(result.detail, 58))
            row:Show()
        else
            row.resultData = nil
            row:Hide()
        end
    end
    if string.len(query) < 2 then
        self.ui.globalSearchStatus:SetText("Enter at least two characters to search across the guild addon.")
    elseif table.getn(results) == 0 then
        self.ui.globalSearchStatus:SetText("No matching members, recipes, groups or posts were found.")
    else
        self.ui.globalSearchStatus:SetText("Showing " .. tostring(offset + 1) .. "-" .. tostring(math.min(offset + N_SEARCH_ROWS, table.getn(results))) .. " of " .. tostring(table.getn(results)) .. " results")
    end
    NSetEnabled(self.ui.globalSearchPrev, offset > 0, "You are at the first result page.")
    NSetEnabled(self.ui.globalSearchNext, offset < maximum, "There are no more results.")
end

function OTLGM:_Stage_UINext_BuildNextProfessionsPage_1(page)
    NText(page, "GameFontNormalLarge", "Professions", 0, -2, 390, "LEFT")
    NWrapped(page, "GameFontNormalSmall", "Find guild crafters, scan known recipes and ask the guild for help without searching manually in chat.", 0, -28, 700, 32)

    self.ui.craftingTabButtons = {}
    self.ui.craftingTabButtons.RECIPES = NButton(page, "Recipes", 0, -58, 146, 30, function() OTLGM:ShowCraftingSection("RECIPES") end, "utility")
    NIcon(self.ui.craftingTabButtons.RECIPES, "Interface\\Icons\\INV_Misc_Book_09", 16)
    self.ui.craftingTabButtons.REQUESTS = NButton(page, "Crafting Requests", 156, -58, 174, 30, function() OTLGM:ShowCraftingSection("REQUESTS") end, "normal")
    NIcon(self.ui.craftingTabButtons.REQUESTS, "Interface\\Icons\\INV_Letter_15", 16)
    self.ui.craftingNetworkText = NText(page, "GameFontNormalSmall", "Network: checking", 442, -65, 158, "RIGHT")
    self.ui.craftingNetworkText:SetTextColor(0.58, 0.58, 0.58)
    self.ui.craftingSyncButton = NButton(page, "Sync Now", 614, -58, 104, 30, function()
        OTLGM:RequestAddonUserPing()
        OTLGM:RequestCraftingSync(true)
        OTLGM:SetStatus("Requesting current crafting data from online addon users...")
    end, "utility")

    self.ui.craftingPanels = {}
    self:BuildRecipesPanel(page)
    self:BuildCraftingRequestsPanel(page)
    self:BuildCraftingRequestDialog()
    self:ShowCraftingSection(OTLGM_DB.settings.craftingSection or "RECIPES")
end

function OTLGM:_Stage_UINext_BuildRecipesPanel_1(page)
    local panel = CreateFrame("Frame", nil, page)
    panel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -98)
    panel:SetWidth(718)
    panel:SetHeight(418)
    self.ui.craftingPanels.RECIPES = panel

    local filters = NPanel(panel, 0, 0, 154, 418, 0.026, 0.023, 0.019)
    NText(filters, "GameFontNormalSmall", "PROFESSIONS", 10, -10, 134, "LEFT")
    self.ui.craftingProfessionButtons = {}
    local definitions = self:GetCraftingProfessionDefinitions()
    local i
    for i = 1, table.getn(definitions) do
        local definition = definitions[i]
        local key = definition.key
        local button = NButton(filters, definition.label, 8, -30 - ((i - 1) * 26), 138, 24, function()
            OTLGM_DB.settings.craftingProfession = key
            OTLGM.ui.craftingRecipeOffset = 0
            OTLGM.ui.craftingSelectedRecipe = nil
            OTLGM:RefreshProfessionsPage()
        end, "normal")
        NIcon(button, definition.icon or "Interface\\Icons\\INV_Misc_QuestionMark", 14)
        button.text:SetWidth(100)
        self.ui.craftingProfessionButtons[key] = button
    end
    NText(filters, "GameFontNormalSmall", "RECENT CRAFTING", 10, -298, 134, "LEFT")
    self.ui.craftingRecentRows152 = {}
    for i = 1, 4 do
        local recent = NWrapped(filters, "GameFontNormalSmall", "", 10, -320 - ((i - 1) * 22), 134, 20)
        recent:SetTextColor(0.68, 0.68, 0.66)
        self.ui.craftingRecentRows152[i] = recent
    end
    self.ui.craftingRecentEmpty152 = NWrapped(filters, "GameFontNormalSmall", "Open a profession window to share recipes.", 10, -324, 134, 54)
    self.ui.craftingRecentEmpty152:SetTextColor(0.48, 0.48, 0.46)

    local recipes = NPanel(panel, 164, 0, 324, 418, 0.018, 0.017, 0.015)
    self.ui.craftingSearchEdit = NEdit(recipes, "OTLGM_CraftingSearch", 10, -10, 246, 30, false)
    self.ui.craftingSearchEdit:SetMaxLetters(60)
    self.ui.craftingSearchEdit:SetText(OTLGM_DB.settings.craftingSearch or "")
    self.ui.craftingSearchHint = NText(self.ui.craftingSearchEdit, "GameFontNormalSmall", "Search item, recipe or crafter...", 8, -8, 214, "LEFT")
    self.ui.craftingSearchHint:SetTextColor(0.42, 0.42, 0.42)
    self.ui.craftingSearchClear = NButton(recipes, "Clear", 264, -10, 50, 30, function()
        OTLGM.ui.craftingSearchEdit:SetText("")
        OTLGM.ui.craftingSearchEdit:ClearFocus()
        OTLGM.ui.craftingRecipeOffset = 0
        OTLGM:RefreshProfessionsPage()
    end, "utility")
    self.ui.craftingSearchEdit:SetScript("OnTextChanged", function()
        OTLGM_DB.settings.craftingSearch = this:GetText() or ""
        if (this:GetText() or "") == "" then OTLGM.ui.craftingSearchHint:Show() else OTLGM.ui.craftingSearchHint:Hide() end
        OTLGM.ui.craftingSearchDirty = true
        OTLGM.ui.craftingSearchElapsed = 0
    end)
    self.ui.craftingSearchEdit:SetScript("OnEnterPressed", function() this:ClearFocus() OTLGM.ui.craftingRecipeOffset = 0 OTLGM:RefreshProfessionsPage() end)

    self.ui.craftingRecipeRows = {}
    for i = 1, N_RECIPE_ROWS do
        local row = NButton(recipes, "", 10, -48 - ((i - 1) * 32), 304, 30, function()
            if this.recipeData then
                OTLGM.ui.craftingSelectedRecipe = this.recipeData.key
                OTLGM.ui.craftingSelectedCrafter = this.recipeData.crafters and this.recipeData.crafters[1] and this.recipeData.crafters[1].name or nil
                OTLGM:RefreshProfessionsPage()
            end
        end, "normal")
        row.text:Hide()
        row.recipeIcon = row:CreateTexture(nil, "OVERLAY")
        row.recipeIcon:SetPoint("LEFT", row, "LEFT", 7, 0)
        row.recipeIcon:SetWidth(20)
        row.recipeIcon:SetHeight(20)
        row.recipeIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.nameText = NText(row, "GameFontNormalSmall", "", 32, -7, 174, "LEFT")
        row.countText = NText(row, "GameFontNormalSmall", "", 210, -7, 86, "RIGHT")
        row:Hide()
        self.ui.craftingRecipeRows[i] = row
    end
    self.ui.craftingRecipeStatus = NText(recipes, "GameFontNormalSmall", "", 10, -382, 214, "LEFT")
    self.ui.craftingRecipePrev = NButton(recipes, "<", 232, -376, 36, 26, function()
        OTLGM.ui.craftingRecipeOffset = math.max(0, (OTLGM.ui.craftingRecipeOffset or 0) - N_RECIPE_ROWS)
        OTLGM:RefreshProfessionsPage()
    end, "utility")
    self.ui.craftingRecipeNext = NButton(recipes, ">", 276, -376, 36, 26, function()
        OTLGM.ui.craftingRecipeOffset = (OTLGM.ui.craftingRecipeOffset or 0) + N_RECIPE_ROWS
        OTLGM:RefreshProfessionsPage()
    end, "utility")
    recipes:EnableMouseWheel(1)
    recipes:SetScript("OnMouseWheel", function()
        if arg1 > 0 then OTLGM.ui.craftingRecipeOffset = math.max(0, (OTLGM.ui.craftingRecipeOffset or 0) - N_RECIPE_ROWS)
        else OTLGM.ui.craftingRecipeOffset = (OTLGM.ui.craftingRecipeOffset or 0) + N_RECIPE_ROWS end
        OTLGM:RefreshProfessionsPage()
    end)
    local crafters = NPanel(panel, 498, 0, 220, 418, 0.026, 0.023, 0.019)
    self.ui.craftingRecipeIcon152 = crafters:CreateTexture(nil, "OVERLAY")
    self.ui.craftingRecipeIcon152:SetPoint("TOPLEFT", crafters, "TOPLEFT", 10, -12)
    self.ui.craftingRecipeIcon152:SetWidth(34)
    self.ui.craftingRecipeIcon152:SetHeight(34)
    self.ui.craftingRecipeIcon152:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    self.ui.craftingRecipeTitle = NWrapped(crafters, "GameFontNormal", "Select a recipe", 52, -10, 158, 36)
    self.ui.craftingRecipeMeta = NText(crafters, "GameFontNormalSmall", "", 52, -46, 158, "LEFT")
    self.ui.craftingRecipeMeta:SetTextColor(0.60, 0.60, 0.58)
    self.ui.craftingMaterialsTitle152 = NText(crafters, "GameFontNormalSmall", "REQUIRED MATERIALS", 10, -70, 200, "LEFT")
    self.ui.craftingMaterialRows152 = {}
    for i = 1, 3 do
        local material = CreateFrame("Frame", nil, crafters)
        material:SetPoint("TOPLEFT", crafters, "TOPLEFT", 10, -90 - ((i - 1) * 24))
        material:SetWidth(200)
        material:SetHeight(22)
        material.icon = material:CreateTexture(nil, "OVERLAY")
        material.icon:SetPoint("LEFT", material, "LEFT", 0, 0)
        material.icon:SetWidth(18)
        material.icon:SetHeight(18)
        material.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        material.text = NText(material, "GameFontNormalSmall", "", 24, -4, 174, "LEFT")
        material:Hide()
        self.ui.craftingMaterialRows152[i] = material
    end
    self.ui.craftingMaterialsEmpty152 = NWrapped(crafters, "GameFontNormalSmall", "Select a recipe to view materials.", 10, -92, 200, 62)
    self.ui.craftingMaterialsEmpty152:SetTextColor(0.52, 0.52, 0.50)
    NText(crafters, "GameFontNormalSmall", "GUILD CRAFTERS", 10, -166, 200, "LEFT")
    self.ui.craftingCrafterRows = {}
    for i = 1, N_CRAFTER_ROWS do
        local row = NButton(crafters, "", 10, -184 - ((i - 1) * 34), 200, 32, function()
            if this.crafterData then OTLGM.ui.craftingSelectedCrafter = this.crafterData.name OTLGM:RefreshProfessionsPage() end
        end, "normal")
        row.text:Hide()
        row.nameText = NText(row, "GameFontNormalSmall", "", 8, -6, 120, "LEFT")
        row.statusText = NText(row, "GameFontNormalSmall", "", 130, -6, 60, "RIGHT")
        row.ageText = NText(row, "GameFontNormalSmall", "", 8, -18, 182, "LEFT")
        row.ageText:SetTextColor(0.52, 0.52, 0.52)
        row:Hide()
        self.ui.craftingCrafterRows[i] = row
    end
    self.ui.craftingWhisperButton = NButton(crafters, "Whisper", 10, -354, 56, 26, function()
        if OTLGM.ui.craftingSelectedCrafter then
            if OTLGM.RecordCrafterContact174 then OTLGM:RecordCrafterContact174(OTLGM.ui.craftingSelectedCrafter) end
            OTLGM:OpenGuildChatWhisper(OTLGM.ui.craftingSelectedCrafter)
        end
    end, "utility")
    self.ui.craftingLinkButton = NButton(crafters, "Link Item", 70, -354, 64, 26, function()
        local result = OTLGM.ui.craftingSelectedRecipeData
        local link = result and OTLGM:GetCraftingItemLink154(result.recipe)
        if link then OTLGM:OpenGuildChatWithLink154(link)
        else OTLGM:ShowNotice("Item Link", "The item link is not cached yet. Open or inspect the item once, then try again.") end
    end, "utility")
    self.ui.craftingRecipeLinkButton152 = NButton(crafters, "Link Recipe", 138, -354, 72, 26, function()
        local result = OTLGM.ui.craftingSelectedRecipeData
        local link = result and OTLGM:GetCraftingRecipeLink154(result.recipe)
        if link then OTLGM:OpenGuildChatWithLink154(link)
        else OTLGM:ShowNotice("Recipe Link", "This recipe link was not included in the scan. Ask the crafter to reopen the profession window with the latest addon.") end
    end, "utility")
    self.ui.craftingRequestButton = NButton(crafters, "Request This Craft", 10, -386, 200, 26, function()
        local result = OTLGM.ui.craftingSelectedRecipeData
        OTLGM:OpenCraftingRequestDialog(result and result.recipe and result.recipe.name or "", "CRAFT")
    end, "confirm")
end

-- Search fields share the addon's single heartbeat instead of installing an
-- OnUpdate handler on every searchable panel.
function OTLGM:ProcessUIDebounce(elapsed)
    if self.ProcessExperienceMotion170 then self:ProcessExperienceMotion170(elapsed) end
    if not self:IsUIVisible() then return end
    elapsed = tonumber(elapsed) or 0
    if self.ui.currentPage == "search" and self.ui.searchDirty then
        self.ui.searchDirtyElapsed = (self.ui.searchDirtyElapsed or 0) + elapsed
        if self.ui.searchDirtyElapsed >= 0.25 then
            self.ui.searchDirty = nil
            self.ui.searchDirtyElapsed = 0
            self.ui.globalSearchOffset = 0
            self:RefreshSearchPage(true)
        end
    end
    if self.ui.currentPage == "professions" and self.ui.craftingSearchDirty then
        self.ui.craftingSearchElapsed = (self.ui.craftingSearchElapsed or 0) + elapsed
        if self.ui.craftingSearchElapsed >= 0.25 then
            self.ui.craftingSearchDirty = nil
            self.ui.craftingSearchElapsed = 0
            self.ui.craftingRecipeOffset = 0
            self.ui.craftingSelectedRecipe = nil
            self:RefreshProfessionsPage()
        end
    end
end

function OTLGM:BuildCraftingRequestsPanel(page)
    local panel = CreateFrame("Frame", nil, page)
    panel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -98)
    panel:SetWidth(718)
    panel:SetHeight(418)
    panel:Hide()
    self.ui.craftingPanels.REQUESTS = panel

    local list = NPanel(panel, 0, 0, 338, 418, 0.018, 0.017, 0.015)
    self.ui.newCraftingRequestButton = NButton(list, "New Crafting Request", 10, -10, 188, 30, function() OTLGM:OpenCraftingRequestDialog("", "CRAFT") end, "confirm")
    self.ui.craftingRequestViewButton = NButton(list, "Open only", 206, -10, 122, 30, function()
        OTLGM_DB.settings.craftingShowClosed = not OTLGM_DB.settings.craftingShowClosed
        OTLGM.ui.craftingRequestOffset = 0
        OTLGM:RefreshProfessionsPage()
    end, "utility")
    self.ui.craftingRequestRows = {}
    local i
    for i = 1, N_REQUEST_ROWS do
        local row = NButton(list, "", 10, -48 - ((i - 1) * 36), 318, 34, function()
            if this.requestData then OTLGM.ui.craftingSelectedRequest = this.requestData.id OTLGM:RefreshProfessionsPage() end
        end, "normal")
        row.text:Hide()
        row.itemText = NText(row, "GameFontNormalSmall", "", 8, -7, 196, "LEFT")
        row.authorText = NText(row, "GameFontNormalSmall", "", 208, -7, 100, "RIGHT")
        row.detailText = NText(row, "GameFontNormalSmall", "", 8, -20, 300, "LEFT")
        row.detailText:SetTextColor(0.55, 0.55, 0.55)
        row:Hide()
        self.ui.craftingRequestRows[i] = row
    end
    self.ui.craftingRequestStatus = NText(list, "GameFontNormalSmall", "", 10, -382, 218, "LEFT")
    self.ui.craftingRequestPrev = NButton(list, "<", 246, -376, 36, 26, function()
        OTLGM.ui.craftingRequestOffset = math.max(0, (OTLGM.ui.craftingRequestOffset or 0) - N_REQUEST_ROWS)
        OTLGM:RefreshProfessionsPage()
    end, "utility")
    self.ui.craftingRequestNext = NButton(list, ">", 290, -376, 36, 26, function()
        OTLGM.ui.craftingRequestOffset = (OTLGM.ui.craftingRequestOffset or 0) + N_REQUEST_ROWS
        OTLGM:RefreshProfessionsPage()
    end, "utility")

    local detail = NPanel(panel, 348, 0, 370, 418, 0.026, 0.023, 0.019)
    self.ui.craftingRequestTitle = NWrapped(detail, "GameFontNormalLarge", "Select a crafting request", 12, -12, 346, 42)
    self.ui.craftingRequestMeta = NWrapped(detail, "GameFontNormalSmall", "", 12, -54, 346, 48)
    self.ui.craftingReactionButtons = {}
    self.ui.craftingReactionButtons.HELP = NButton(detail, "Can Help", 12, -106, 104, 26, function() OTLGM:ReactToSelectedCraftingRequest("HELP") end, "confirm")
    self.ui.craftingReactionButtons.NEED = NButton(detail, "Need This Too", 124, -106, 112, 26, function() OTLGM:ReactToSelectedCraftingRequest("NEED") end, "normal")
    self.ui.craftingReactionButtons.SEEN = NButton(detail, "Seen", 244, -106, 112, 26, function() OTLGM:ReactToSelectedCraftingRequest("SEEN") end, "utility")
    NAttachReactionTooltip(self.ui.craftingReactionButtons.HELP, "CRAFT", "HELP", "Can Help", function() return OTLGM.ui.craftingSelectedRequest end)
    NAttachReactionTooltip(self.ui.craftingReactionButtons.NEED, "CRAFT", "NEED", "Need This Too", function() return OTLGM.ui.craftingSelectedRequest end)
    NAttachReactionTooltip(self.ui.craftingReactionButtons.SEEN, "CRAFT", "SEEN", "Seen", function() return OTLGM.ui.craftingSelectedRequest end)
    NText(detail, "GameFontNormalSmall", "RESPONSES", 12, -148, 180, "LEFT")
    self.ui.craftingResponseRows = {}
    for i = 1, N_RESPONSE_ROWS do
        local row = NPanel(detail, 12, -168 - ((i - 1) * 42), 344, 38, 0.020, 0.019, 0.017)
        row.authorText = NText(row, "GameFontNormalSmall", "", 8, -7, 112, "LEFT")
        row.messageText = NText(row, "GameFontHighlightSmall", "", 124, -7, 210, "LEFT")
        row.statusText = NText(row, "GameFontNormalSmall", "", 8, -21, 326, "LEFT")
        row.statusText:SetTextColor(0.50, 0.50, 0.50)
        row:Hide()
        self.ui.craftingResponseRows[i] = row
    end
    self.ui.craftingResponseEmpty = NWrapped(detail, "GameFontNormalSmall", "No responses yet. Use Can Help or leave a short reply.", 16, -178, 332, 42)
    self.ui.craftingResponseEdit = NEdit(detail, "OTLGM_CraftingResponse", 12, -340, 220, 30, false)
    self.ui.craftingResponseEdit:SetMaxLetters(72)
    self.ui.craftingReplyButton = NButton(detail, "Reply", 240, -340, 56, 30, function() OTLGM:ReplyToSelectedCraftingRequest(false) end, "utility")
    self.ui.craftingHelpReplyButton = NButton(detail, "Help", 304, -340, 52, 30, function() OTLGM:ReplyToSelectedCraftingRequest(true) end, "confirm")
    self.ui.craftingWhisperAuthorButton = NButton(detail, "Whisper", 12, -378, 76, 28, function()
        local request = OTLGM:GetCraftingRequestByID(OTLGM.ui.craftingSelectedRequest)
        if request then OTLGM:OpenGuildChatWhisper(request.author) end
    end, "utility")
    self.ui.craftingShareButton = NButton(detail, "Share to /g", 96, -378, 92, 28, function()
        local request = OTLGM:GetCraftingRequestByID(OTLGM.ui.craftingSelectedRequest)
        if request then OTLGM:ShareCraftingRequestToGuildChat(request) OTLGM:SetStatus("Crafting request shared to guild chat with an OTLGM label.") end
    end, "utility")
    self.ui.craftingCloseButton = NButton(detail, "Close / Reopen", 196, -378, 96, 28, function()
        if OTLGM.ui.craftingSelectedRequest then OTLGM:CloseCraftingRequest(OTLGM.ui.craftingSelectedRequest) end
    end, "normal")
    self.ui.craftingDeleteButton = NButton(detail, "Delete", 300, -378, 56, 28, function()
        local request = OTLGM:GetCraftingRequestByID(OTLGM.ui.craftingSelectedRequest)
        if request then OTLGM:ShowConfirm("Delete Crafting Request", "Remove this request from connected addon users?", "Delete", function() OTLGM:DeleteCraftingRequest(request.id, false) end) end
    end, "danger")
end

function OTLGM:BuildCraftingRequestDialog()
    local dialog = CreateFrame("Frame", "OTLGM_CraftingRequestDialog", self.ui.main)
    dialog:SetWidth(590)
    dialog:SetHeight(454)
    dialog:SetPoint("CENTER", self.ui.main, "CENTER", 0, 5)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetFrameLevel(self.ui.main:GetFrameLevel() + 70)
    NBackdrop(dialog, 8)
    dialog:SetBackdropColor(0.014, 0.013, 0.011, 1)
    dialog:SetBackdropBorderColor(0.90, 0.60, 0.19, 1)
    dialog.title = NText(dialog, "GameFontNormalLarge", "New Crafting Request", 20, -18, 550, "CENTER")
    NWrapped(dialog, "GameFontNormalSmall", "Choose a request type, describe what you need and share it with online guild addon users.", 24, -50, 542, 36)
    NText(dialog, "GameFontNormalSmall", "REQUEST TYPE", 24, -90, 180, "LEFT")
    dialog.templateButtons = {}
    local templates = {
        {"CRAFT", "Craft Item"}, {"ENCHANT", "Enchant"}, {"TRANSMUTE", "Transmute"}, {"GEM", "Cut Gem"},
        {"COOKING", "Cooking"}, {"MATERIALS", "Need Materials"}, {"CUSTOM", "Custom"}
    }
    local i
    for i = 1, table.getn(templates) do
        local key = templates[i][1]
        local row = i <= 4 and 0 or 1
        local column = row == 0 and (i - 1) or (i - 5)
        local button = NButton(dialog, templates[i][2], 24 + (column * 132), -108 - (row * 34), 124, 28, function()
            OTLGM_DB.settings.craftingRequestTemplate = key
            OTLGM:RefreshCraftingRequestDialog()
        end, "normal")
        dialog.templateButtons[key] = button
    end
    NText(dialog, "GameFontNormalSmall", "ITEM / RECIPE / SERVICE", 24, -180, 260, "LEFT")
    dialog.itemEdit = NEdit(dialog, "OTLGM_CraftingRequestItem", 24, -198, 542, 32, false)
    dialog.itemEdit:SetMaxLetters(64)
    NText(dialog, "GameFontNormalSmall", "MATERIALS", 24, -244, 130, "LEFT")
    dialog.materialButtons = {}
    dialog.materialButtons.READY = NButton(dialog, "Materials Ready", 24, -262, 160, 28, function() OTLGM_DB.settings.craftingMaterials = "READY" OTLGM:RefreshCraftingRequestDialog() end, "confirm")
    dialog.materialButtons.NEEDED = NButton(dialog, "Need Materials", 194, -262, 160, 28, function() OTLGM_DB.settings.craftingMaterials = "NEEDED" OTLGM:RefreshCraftingRequestDialog() end, "normal")
    dialog.materialButtons.DISCUSS = NButton(dialog, "Discuss", 364, -262, 120, 28, function() OTLGM_DB.settings.craftingMaterials = "DISCUSS" OTLGM:RefreshCraftingRequestDialog() end, "utility")
    NText(dialog, "GameFontNormalSmall", "SHORT NOTE", 24, -306, 160, "LEFT")
    dialog.noteEdit = NEdit(dialog, "OTLGM_CraftingRequestNote", 24, -324, 542, 52, true)
    dialog.noteEdit:SetMaxLetters(80)
    dialog.post = NButton(dialog, "Post Request", 342, -402, 132, 30, function()
        local ok, result = OTLGM:CreateCraftingRequest(OTLGM_DB.settings.craftingRequestTemplate, OTLGM.ui.craftingRequestDialog.itemEdit:GetText(), OTLGM_DB.settings.craftingMaterials, OTLGM.ui.craftingRequestDialog.noteEdit:GetText())
        if ok then
            OTLGM.ui.craftingRequestDialog:Hide()
            OTLGM.ui.craftingSelectedRequest = result.id
            OTLGM_DB.settings.craftingSection = "REQUESTS"
            OTLGM:ShowPage("professions")
            OTLGM:SetStatus("Crafting request shared with online guild addon users.")
        else OTLGM:ShowNotice("Crafting Request", result or "Could not create the request.") end
    end, "confirm")
    dialog.cancel = NButton(dialog, "Cancel", 484, -402, 82, 30, function() OTLGM.ui.craftingRequestDialog:Hide() end, "normal")
    dialog.validationText154 = NText(dialog, "GameFontNormalSmall", "Item, recipe or service is required.", 24, -382, 300, "LEFT")
    dialog.validationText154:SetTextColor(0.82, 0.58, 0.35)
    dialog.itemEdit:SetScript("OnTextChanged", function() OTLGM:RefreshCraftingRequestDialog() end)
    dialog:Hide()
    self.ui.craftingRequestDialog = dialog
end

function OTLGM:OpenCraftingRequestDialog(item, template)
    local dialog = self.ui and self.ui.craftingRequestDialog
    if not dialog then return end
    OTLGM_DB.settings.craftingRequestTemplate = template or OTLGM_DB.settings.craftingRequestTemplate or "CRAFT"
    dialog.itemEdit:SetText(item or "")
    dialog.noteEdit:SetText("")
    self:ShowModal152(dialog)
    self:RefreshCraftingRequestDialog()
    dialog.itemEdit:SetFocus()
end

function OTLGM:RefreshCraftingRequestDialog()
    local dialog = self.ui and self.ui.craftingRequestDialog
    if not dialog then return end
    local key, button
    for key, button in pairs(dialog.templateButtons or {}) do NSetSelected(button, key == (OTLGM_DB.settings.craftingRequestTemplate or "CRAFT")) end
    for key, button in pairs(dialog.materialButtons or {}) do NSetSelected(button, key == (OTLGM_DB.settings.craftingMaterials or "READY")) end
    local item = string.gsub(dialog.itemEdit:GetText() or "", "^%s*(.-)%s*$", "%1")
    local ready = item ~= ""
    NSetEnabled(dialog.post, ready, "Enter an item, recipe or service first.")
    if dialog.validationText154 then
        dialog.validationText154:SetText(ready and "Ready to share with online guild addon users." or "Item, recipe or service is required.")
        if ready then dialog.validationText154:SetTextColor(0.45, 0.82, 0.48) else dialog.validationText154:SetTextColor(0.82, 0.58, 0.35) end
    end
end

function OTLGM:ShowCraftingSection(section)
    section = section == "REQUESTS" and "REQUESTS" or "RECIPES"
    OTLGM_DB.settings.craftingSection = section
    local key, panel
    for key, panel in pairs(self.ui.craftingPanels or {}) do if key == section then panel:Show() else panel:Hide() end end
    for key, panel in pairs(self.ui.craftingTabButtons or {}) do NSetSelected(panel, key == section) end
    self:MarkCraftingRead(section)
    self:RefreshProfessionsPage()
end

function OTLGM:RefreshProfessionsPage()
    if not self.ui or not self.ui.craftingPanels then return end
    local section = OTLGM_DB.settings.craftingSection or "RECIPES"
    local key, panel
    for key, panel in pairs(self.ui.craftingPanels) do if key == section then panel:Show() else panel:Hide() end end
    local summary = self:GetCraftingSummary()
    local _, _, online = self:GetDetectedAddonUsers(86400)
    local craft = self:EnsureCraftingDB()
    local syncState = craft and craft.syncState or nil
    if syncState and syncState.active then
        self.ui.craftingNetworkText:SetText(self.colors.gold .. "Syncing: " .. tostring(syncState.received or 0) .. " snapshot(s)" .. self.colors.reset)
        NSetEnabled(self.ui.craftingSyncButton, false, "Crafting data is already being synchronized.")
    else
        self.ui.craftingNetworkText:SetText(self.colors.green .. "Network: " .. tostring(online) .. " online" .. self.colors.reset)
        NSetEnabled(self.ui.craftingSyncButton, true)
    end
    NSetButtonText(self.ui.craftingTabButtons.RECIPES, "Recipes" .. (self:GetCraftingUnread("RECIPES") > 0 and (" (" .. tostring(self:GetCraftingUnread("RECIPES")) .. ")") or ""))
    NSetButtonText(self.ui.craftingTabButtons.REQUESTS, "Crafting Requests" .. (self:GetCraftingUnread("REQUESTS") > 0 and (" (" .. tostring(self:GetCraftingUnread("REQUESTS")) .. ")") or ""))
    for key, panel in pairs(self.ui.craftingTabButtons) do NSetSelected(panel, key == section) end
    if section == "RECIPES" then self:RefreshCraftingRecipesPanel(summary) else self:RefreshCraftingRequestsPanel(summary) end
end

function OTLGM:_Stage_UINext_RefreshCraftingRecipesPanel_1(summary)
    local query = self.ui.craftingSearchEdit and (self.ui.craftingSearchEdit:GetText() or "") or ""
    local profession = OTLGM_DB.settings.craftingProfession or "ALL"
    local results = self:GetCraftingSearchResults(query, profession)
    local counts = self:GetCraftingProfessionCounts(query)
    local definitions = self:GetCraftingProfessionDefinitions()
    local definitionMap = {}
    local i
    for i = 1, table.getn(definitions) do definitionMap[definitions[i].key] = definitions[i] end
    local key, button
    for key, button in pairs(self.ui.craftingProfessionButtons or {}) do
        local definition = definitionMap[key]
        local label = definition and definition.label or key
        NSetButtonText(button, label .. ((counts[key] or 0) > 0 and ("  " .. tostring(counts[key])) or ""))
        NSetSelected(button, key == profession)
    end

    local craft = self:EnsureCraftingDB()
    local events = craft and craft.events or {}
    for i = 1, 4 do
        local eventInfo = events[i]
        if eventInfo then
            self.ui.craftingRecentRows152[i]:SetText(self.colors.gold .. "-" .. self.colors.reset .. " " .. NShort(eventInfo.title, 25))
            self.ui.craftingRecentRows152[i]:Show()
        else self.ui.craftingRecentRows152[i]:SetText("") self.ui.craftingRecentRows152[i]:Hide() end
    end
    if table.getn(events) == 0 then self.ui.craftingRecentEmpty152:Show() else self.ui.craftingRecentEmpty152:Hide() end

    local offset = math.max(0, self.ui.craftingRecipeOffset or 0)
    local maximum = math.max(0, table.getn(results) - N_RECIPE_ROWS)
    if offset > maximum then offset = maximum end
    self.ui.craftingRecipeOffset = offset
    local row, result, onlineCount
    for i = 1, N_RECIPE_ROWS do
        row = self.ui.craftingRecipeRows[i]
        result = results[offset + i]
        if result then
            row.recipeData = result
            onlineCount = 0
            local j
            for j = 1, table.getn(result.crafters or {}) do if result.crafters[j].online then onlineCount = onlineCount + 1 end end
            row.recipeIcon:SetTexture(NResolveRecipeTexture155(result.recipe))
            row.nameText:SetText(NQualityText155(NShort(result.recipe.name, 27), result.recipe.quality))
            row.countText:SetText((onlineCount > 0 and self.colors.green or self.colors.grey) .. tostring(table.getn(result.crafters or {})) .. " crafter" .. (table.getn(result.crafters or {}) == 1 and "" or "s") .. self.colors.reset)
            NSetSelected(row, self.ui.craftingSelectedRecipe == result.key)
            row:Show()
        else row.recipeData = nil row:Hide() end
    end
    if table.getn(results) == 0 then
        self.ui.craftingRecipeStatus:SetText(summary.uniqueRecipes == 0 and "No shared recipes. Open a profession window once." or "No recipes match this search.")
    else
        self.ui.craftingRecipeStatus:SetText(tostring(offset + 1) .. "-" .. tostring(math.min(offset + N_RECIPE_ROWS, table.getn(results))) .. " of " .. tostring(table.getn(results)))
    end
    NSetEnabled(self.ui.craftingRecipePrev, offset > 0, "You are at the first recipe page.")
    NSetEnabled(self.ui.craftingRecipeNext, offset < maximum, "There are no more recipes.")

    local selected = NFindRecipe(results, self.ui.craftingSelectedRecipe)
    if not selected and results[1] then selected = results[1] self.ui.craftingSelectedRecipe = selected.key end
    self.ui.craftingSelectedRecipeData = selected
    local selectedRecipeIcon
    if selected then
        selectedRecipeIcon = NResolveRecipeTexture155(selected.recipe)
        self.ui.craftingRecipeIcon152:SetTexture(selectedRecipeIcon)
        self.ui.craftingRecipeTitle:SetText(NQualityText155(NShort(selected.recipe.name or "Recipe", 35), selected.recipe.quality))
        self.ui.craftingRecipeMeta:SetText((selected.professionLabel or "Profession") .. "  |  " .. tostring(table.getn(selected.crafters or {})) .. " crafter(s)")
        self.ui.craftingRecipeIcon152:Show()
    else
        self.ui.craftingRecipeIcon152:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        self.ui.craftingRecipeTitle:SetText(self.colors.grey .. "Select a recipe" .. self.colors.reset)
        self.ui.craftingRecipeMeta:SetText("Online crafters are listed first.")
    end

    local reagents = selected and selected.recipe and selected.recipe.reagents or {}
    local materialsAvailable = selected and selected.recipe and selected.recipe.materialsAvailable
    for i = 1, 3 do
        local material = self.ui.craftingMaterialRows152[i]
        local reagent = reagents[i]
        if reagent then
            material.reagentData = reagent
            material.professionKey = selected and selected.professionKey
            local texture = reagent.icon
            if not NValidTexture155(texture) and tonumber(reagent.itemId) and tonumber(reagent.itemId) > 0 and GetItemInfo then local _, _, _, _, _, _, _, _, _, cached = self:GetItemInfoSafe(reagent.itemId) texture = cached end
            material.icon:SetTexture(NValidTexture155(texture) or "Interface\\Icons\\INV_Misc_QuestionMark")
            material.text:SetText(tostring(reagent.count or 0) .. "x  " .. NShort(reagent.name or "Unknown reagent", 23))
            material:Show()
        else material.reagentData = nil material.professionKey = nil material:Hide() end
    end
    if not selected then
        self.ui.craftingMaterialsEmpty152:SetText("Select a recipe to view materials.")
        self.ui.craftingMaterialsEmpty152:Show()
    elseif table.getn(reagents) == 0 then
        local materialState = selected.recipe.materialsStatus or (materialsAvailable and "COMPLETE" or "UNAVAILABLE")
        if materialState == "COMPLETE" then
            self.ui.craftingMaterialsEmpty152:SetText("No reagents are required for this craft.")
        else
            self.ui.craftingMaterialsEmpty152:SetText("Materials are incomplete. Ask the crafter to reopen this profession once with the latest addon.")
        end
        self.ui.craftingMaterialsEmpty152:Show()
    else
        self.ui.craftingMaterialsEmpty152:Hide()
    end
    self.ui.craftingMaterialsEmpty152:ClearAllPoints()
    self.ui.craftingMaterialsEmpty152:SetPoint("TOPLEFT", self.ui.craftingRecipeTitle:GetParent(), "TOPLEFT", 10, -92)
    self.ui.craftingMaterialsEmpty152:SetHeight(62)
    if self.ui.craftingMaterialsTitle152 then
        local title = "REQUIRED MATERIALS"
        if table.getn(reagents) > 3 then title = title .. "  (+" .. tostring(table.getn(reagents) - 3) .. " MORE)" end
        if selected and selected.recipe and selected.recipe.materialsStatus == "PARTIAL" then title = title .. "  -  PARTIAL" end
        self.ui.craftingMaterialsTitle152:SetText(title)
    end

    local selectedCrafter
    for i = 1, table.getn(selected and selected.crafters or {}) do
        if selected.crafters[i].name == self.ui.craftingSelectedCrafter then selectedCrafter = selected.crafters[i] break end
    end
    if not selectedCrafter and selected and selected.crafters and selected.crafters[1] then selectedCrafter = selected.crafters[1] self.ui.craftingSelectedCrafter = selectedCrafter.name end
    for i = 1, N_CRAFTER_ROWS do
        row = self.ui.craftingCrafterRows[i]
        local crafter = selected and selected.crafters and selected.crafters[i]
        if crafter then
            row.crafterData = crafter
            local member = self:GetMember(crafter.name)
            local specialization = member and self.GetProfessionSpecializationLabel and self:GetProfessionSpecializationLabel(member, selected.professionKey) or nil
            row.nameText:SetText(self:GetClassColor(crafter.class) .. NShort(crafter.name, 16) .. self.colors.reset)
            row.statusText:SetText(crafter.online and (self.colors.green .. "ONLINE" .. self.colors.reset) or self.colors.grey .. "OFFLINE" .. self.colors.reset)
            local age = math.max(0, self:Now() - (tonumber(crafter.ts) or 0))
            local freshness = age < 86400 and "Scanned today" or (age < 30 * 86400 and ("Scanned " .. NAge(self, crafter.ts)) or "Data may be outdated")
            row.ageText:SetText((specialization and (specialization .. "  |  ") or "") .. freshness)
            NSetSelected(row, selectedCrafter and selectedCrafter.name == crafter.name)
            row:Show()
        else row.crafterData = nil row:Hide() end
    end
    NSetEnabled(self.ui.craftingWhisperButton, selectedCrafter ~= nil, "Select a guild crafter first.")
    NSetEnabled(self.ui.craftingLinkButton, selected and self:GetCraftingItemLink154(selected.recipe) ~= nil, "The item link is not cached yet.")
    NSetEnabled(self.ui.craftingRecipeLinkButton152, selected and self:GetCraftingRecipeLink154(selected.recipe) ~= nil, "The crafter must rescan this profession with the current addon version to share its recipe link.")
    NSetEnabled(self.ui.craftingRequestButton, selected ~= nil or query ~= "", "Select a recipe or enter what you need.")
end

function OTLGM:ReactToSelectedCraftingRequest(reaction)
    local id = self.ui and self.ui.craftingSelectedRequest
    if not id then return end
    self:SetCommunityReaction("CRAFT", id, reaction, false)
    self:RefreshProfessionsPage()
end

function OTLGM:ReplyToSelectedCraftingRequest(canHelp)
    local id = self.ui and self.ui.craftingSelectedRequest
    if not id then return end
    local text = self.ui.craftingResponseEdit and self.ui.craftingResponseEdit:GetText() or ""
    local ok, result = self:AddCraftingResponse(id, text, canHelp)
    if ok then self.ui.craftingResponseEdit:SetText("") self:RefreshProfessionsPage()
    else self:ShowNotice("Crafting Response", result or "Could not send the response.") end
end

function OTLGM:RefreshCraftingRequestsPanel(summary)
    local requests = self:GetCraftingRequests(OTLGM_DB.settings.craftingShowClosed and true or false)
    NSetButtonText(self.ui.craftingRequestViewButton, OTLGM_DB.settings.craftingShowClosed and "Including closed" or "Open only")
    local offset = math.max(0, self.ui.craftingRequestOffset or 0)
    local maximum = math.max(0, table.getn(requests) - N_REQUEST_ROWS)
    if offset > maximum then offset = maximum end
    self.ui.craftingRequestOffset = offset
    local i, row, request
    for i = 1, N_REQUEST_ROWS do
        row = self.ui.craftingRequestRows[i]
        request = requests[offset + i]
        if request then
            row.requestData = request
            local reactions = self:GetCommunityReactionSummary("CRAFT", request.id)
            row.itemText:SetText((request.status == "CLOSED" and self.colors.grey or self.colors.gold) .. NShort(request.item, 30) .. self.colors.reset)
            row.authorText:SetText(self:GetClassColor(request.class) .. NShort(request.author, 14) .. self.colors.reset)
            row.detailText:SetText((request.materials == "READY" and "Materials ready" or (request.materials == "NEEDED" and "Needs materials" or "Discuss materials")) .. "  |  Help " .. tostring(reactions.HELP or 0) .. "  |  " .. NAge(self, request.ts))
            NSetSelected(row, self.ui.craftingSelectedRequest == request.id)
            row:Show()
        else row.requestData = nil row:Hide() end
    end
    if table.getn(requests) == 0 then self.ui.craftingRequestStatus:SetText("No open crafting requests. Create one when you need guild help.")
    else self.ui.craftingRequestStatus:SetText(tostring(offset + 1) .. "-" .. tostring(math.min(offset + N_REQUEST_ROWS, table.getn(requests))) .. " of " .. tostring(table.getn(requests))) end
    NSetEnabled(self.ui.craftingRequestPrev, offset > 0, "You are at the first request page.")
    NSetEnabled(self.ui.craftingRequestNext, offset < maximum, "There are no more requests.")
    local selected = NFindRequest(requests, self.ui.craftingSelectedRequest)
    if not selected and requests[1] then selected = requests[1] self.ui.craftingSelectedRequest = selected.id end
    if selected then
        self.ui.craftingRequestTitle:SetText(self.colors.gold .. (selected.item or "Crafting Request") .. self.colors.reset)
        self.ui.craftingRequestMeta:SetText(self:GetClassColor(selected.class) .. (selected.author or "Unknown") .. self.colors.reset .. "  -  Level " .. tostring(selected.level or 0) .. "  -  " .. (selected.status or "OPEN") .. "\n" .. (selected.note ~= "" and selected.note or "No additional note.") .. "  Materials: " .. string.lower(selected.materials or "discuss"))
    else
        self.ui.craftingRequestTitle:SetText(self.colors.grey .. "Select a crafting request" .. self.colors.reset)
        self.ui.craftingRequestMeta:SetText("Members can react, reply, whisper or share the request to normal guild chat.")
    end
    local reactionSummary = selected and self:GetCommunityReactionSummary("CRAFT", selected.id) or {}
    NSetButtonText(self.ui.craftingReactionButtons.HELP, NReactionText(reactionSummary, "HELP", "Can Help"))
    NSetButtonText(self.ui.craftingReactionButtons.NEED, NReactionText(reactionSummary, "NEED", "Need This Too"))
    NSetButtonText(self.ui.craftingReactionButtons.SEEN, NReactionText(reactionSummary, "SEEN", "Seen"))
    local responses = selected and self:GetCraftingResponses(selected.id) or {}
    for i = 1, N_RESPONSE_ROWS do
        row = self.ui.craftingResponseRows[i]
        local response = responses[i]
        if response then
            row.authorText:SetText(self:GetClassColor(response.class) .. NShort(response.author, 16) .. self.colors.reset)
            row.messageText:SetText(NShort(response.text ~= "" and response.text or "I can help.", 34))
            row.statusText:SetText((response.canHelp and "Can help  |  " or "Reply  |  ") .. NAge(self, response.ts))
            row:Show()
        else row:Hide() end
    end
    if table.getn(responses) == 0 and selected then self.ui.craftingResponseEmpty:Show() else self.ui.craftingResponseEmpty:Hide() end
    local enabled = selected ~= nil
    local canModify = selected and self:CanModifyCraftingRequest(selected)
    NSetEnabled(self.ui.craftingReactionButtons.HELP, enabled and selected.status ~= "CLOSED", "Select an open request first.")
    NSetEnabled(self.ui.craftingReactionButtons.NEED, enabled and selected.status ~= "CLOSED", "Select an open request first.")
    NSetEnabled(self.ui.craftingReactionButtons.SEEN, enabled, "Select a request first.")
    NSetEnabled(self.ui.craftingReplyButton, enabled and selected.status ~= "CLOSED", "Select an open request first.")
    NSetEnabled(self.ui.craftingHelpReplyButton, enabled and selected.status ~= "CLOSED", "Select an open request first.")
    NSetEnabled(self.ui.craftingWhisperAuthorButton, enabled, "Select a request first.")
    NSetEnabled(self.ui.craftingShareButton, enabled, "Select a request first.")
    NSetEnabled(self.ui.craftingCloseButton, canModify, "Only the author or leadership can close this request.")
    NSetEnabled(self.ui.craftingDeleteButton, canModify, "Only the author or leadership can delete this request.")
end

function OTLGM:BuildNextHomeEnhancements()
    -- Home is built directly by Main.lua. Keeping the former Chronicle overlay
    -- disabled prevents duplicated cards and text overlap.
    self.ui.home152DirectLayout = true
end


function OTLGM:RefreshHomeRecent()
    -- Recent useful activity is refreshed by the direct Home implementation.
end

function OTLGM:BuildNextPveEnhancements()
    if not self.ui.pvePanels then return end
    local raidCard = self.ui.pveRaidName and self.ui.pveRaidName:GetParent()
    if raidCard then
        if self.ui.pveRaidNote then self.ui.pveRaidNote:SetHeight(34) end
        if self.ui.pveRaidOrganizer then
            self.ui.pveRaidOrganizer:ClearAllPoints()
            self.ui.pveRaidOrganizer:SetPoint("TOPLEFT", raidCard, "TOPLEFT", 440, -74)
        end
        self.ui.pveRaidReactionFrame = CreateFrame("Frame", nil, raidCard)
        self.ui.pveRaidReactionFrame:SetPoint("BOTTOMRIGHT", raidCard, "BOTTOMRIGHT", -10, 4)
        self.ui.pveRaidReactionFrame:SetWidth(260)
        self.ui.pveRaidReactionFrame:SetHeight(26)
        self.ui.pveRaidSeenButton = NButton(self.ui.pveRaidReactionFrame, "Seen", 0, 0, 82, 24, function() OTLGM:ReactToRaid("SEEN") end, "utility")
        self.ui.pveRaidReadyButton = NButton(self.ui.pveRaidReactionFrame, "Ready", 88, 0, 82, 24, function() OTLGM:ReactToRaid("READY") end, "confirm")
        self.ui.pveRaidReactionNote = NText(self.ui.pveRaidReactionFrame, "GameFontNormalSmall", "Not a sign-up", 174, -7, 84, "RIGHT")
        self.ui.pveRaidReactionNote:SetTextColor(0.50, 0.50, 0.50)
        NAttachReactionTooltip(self.ui.pveRaidSeenButton, "RAID", "SEEN", "Seen", function() local raid = OTLGM:GetPveActiveRaid() return raid and raid.id end)
        NAttachReactionTooltip(self.ui.pveRaidReadyButton, "RAID", "READY", "Ready (not a sign-up)", function() local raid = OTLGM:GetPveActiveRaid() return raid and raid.id end)
    end
    local groupPanel = self.ui.pvePanels.GROUPS
    if groupPanel then
        local groupList = self.ui.pveRequestCount and self.ui.pveRequestCount:GetParent()
        if groupList then
            self.ui.pveRequestCount:ClearAllPoints()
            self.ui.pveRequestCount:SetPoint("TOPLEFT", groupList, "TOPLEFT", 206, -10)
            self.ui.pveRequestCount:SetWidth(94)
            self.ui.pveGroupShareButton = NButton(groupList, "Share /g", 308, -5, 100, 24, function()
                local record = OTLGM:GetPveRequestByID(OTLGM.ui.pveSelectedRequest)
                if record then OTLGM:SharePveGroupToGuildChat(record) OTLGM:SetStatus("Group shared to guild chat with an OTLGM label.") end
            end, "utility")
        end
        local form = self.ui.pveRequestActivityEdit and self.ui.pveRequestActivityEdit:GetParent()
        if form then self.ui.pveGroupTemplateButton = NButton(form, "Templates", 206, -386, 60, 28, function() OTLGM:OpenGroupTemplateMenu() end, "utility") end
    end
    -- Guild Board is now presented only as the third Guild Chat tab.
    if self.ui.pveTabButtons and self.ui.pveTabButtons.BOARD then self.ui.pveTabButtons.BOARD:Hide() end
    if self.ui.pvePanels.BOARD then self.ui.pvePanels.BOARD:Hide() end
    if OTLGM_DB.settings.pveSection == "BOARD" then OTLGM_DB.settings.pveSection = "GROUPS" end
    self:BuildGroupTemplateDialog()
end

function OTLGM:BuildGroupTemplateDialog()
    local dialog = CreateFrame("Frame", "OTLGM_GroupTemplates", self.ui.main)
    dialog:SetWidth(420)
    dialog:SetHeight(330)
    dialog:SetPoint("CENTER", self.ui.main, "CENTER", 0, 10)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetFrameLevel(self.ui.main:GetFrameLevel() + 71)
    NBackdrop(dialog, 8)
    dialog:SetBackdropColor(0.014, 0.013, 0.011, 1)
    dialog:SetBackdropBorderColor(0.84, 0.55, 0.17, 1)
    NText(dialog, "GameFontNormalLarge", "Group Templates", 18, -18, 384, "CENTER")
    NWrapped(dialog, "GameFontNormalSmall", "Choose a common activity. You can still edit every field before creating the group.", 22, -50, 376, 40)
    local templates = {
        { "BRD", "DUNGEON", "Blackrock Depths", "5", "1", "1", "3" },
        { "Stratholme", "DUNGEON", "Stratholme", "5", "1", "1", "3" },
        { "Scholomance", "DUNGEON", "Scholomance", "5", "1", "1", "3" },
        { "Dire Maul", "DUNGEON", "Dire Maul", "5", "1", "1", "3" },
        { "Attunement", "ATTUNE", "Attunement", "5", "1", "1", "3" },
        { "Elite Quest", "QUEST", "Elite Quest", "5", "1", "1", "3" },
    }
    local i
    dialog.buttons = {}
    for i = 1, table.getn(templates) do
        local data = templates[i]
        local button = NButton(dialog, data[1], 24 + (math.mod(i - 1, 2) * 186), -104 - (math.floor((i - 1) / 2) * 48), 176, 36, function()
            OTLGM_DB.settings.pveRequestKind = data[2]
            OTLGM.ui.pveRequestActivityEdit:SetText(data[3])
            OTLGM.ui.pveGroupSizeEdit:SetText(data[4])
            OTLGM.ui.pveNeedTankEdit:SetText(data[5])
            OTLGM.ui.pveNeedHealEdit:SetText(data[6])
            OTLGM.ui.pveNeedDpsEdit:SetText(data[7])
            OTLGM.ui.groupTemplateDialog:Hide()
            OTLGM:RefreshPvePage()
        end, "normal")
        dialog.buttons[i] = button
    end
    NButton(dialog, "Close", 298, -284, 98, 28, function() OTLGM.ui.groupTemplateDialog:Hide() end, "utility")
    dialog:Hide()
    self.ui.groupTemplateDialog = dialog
end

function OTLGM:OpenGroupTemplateMenu()
    if self.ui and self.ui.groupTemplateDialog then self:ShowModal152(self.ui.groupTemplateDialog) end
end

function OTLGM:ReactToRaid(reaction)
    local raid = self:GetPveActiveRaid()
    if not raid then return end
    self:SetCommunityReaction("RAID", raid.id, reaction, false)
    self:RefreshPvePage()
end

function OTLGM:RefreshNextPveActions()
    local raid = self:GetPveActiveRaid()
    if self.ui.pveRaidReactionFrame then
        if raid then
            local summary = self:GetCommunityReactionSummary("RAID", raid.id)
            NSetButtonText(self.ui.pveRaidSeenButton, NReactionText(summary, "SEEN", "Seen"))
            NSetButtonText(self.ui.pveRaidReadyButton, NReactionText(summary, "READY", "Ready"))
            self.ui.pveRaidReactionFrame:Show()
        else self.ui.pveRaidReactionFrame:Hide() end
    end
    local group = self:GetPveRequestByID(self.ui.pveSelectedRequest)
    NSetEnabled(self.ui.pveGroupShareButton, group ~= nil, "Select a group first.")
    if self.ui.pveTabButtons and self.ui.pveTabButtons.BOARD then self.ui.pveTabButtons.BOARD:Hide() end
    if self.ui.pvePanels and self.ui.pvePanels.BOARD then self.ui.pvePanels.BOARD:Hide() end
end

function OTLGM:BuildNextHeaderAndFooter()
    local frame = self.ui.main
    local sidebar = self.ui.sidebar
    self.ui.authorLine = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.ui.authorLine:SetPoint("TOP", frame, "TOP", 0, -58)
    self.ui.authorLine:SetText("Created by Hikol  |  Discord: mrhikol  |  In-game: Lucks")
    self.ui.authorLine:SetTextColor(0.40, 0.37, 0.31)
    self.ui.dateIndicator = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.ui.dateIndicator:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -48, -50)
    self.ui.dateIndicator:SetWidth(190)
    self.ui.dateIndicator:SetJustifyH("RIGHT")
    self.ui.dateIndicator:SetTextColor(0.64, 0.56, 0.42)
    self:RefreshDateIndicator(true)

    self.ui.updateWarning = NButton(frame, "UPDATE AVAILABLE", 0, 0, 150, 22, function()
        OTLGM:ShowPage("settings")
        if OTLGM.ShowSettingsSection then OTLGM:ShowSettingsSection("DATA") end
    end, "danger")
    self.ui.updateWarning:ClearAllPoints()
    self.ui.updateWarning:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -78)
    self.ui.updateWarning:SetFrameLevel(frame:GetFrameLevel() + 20)
    self.ui.updateWarning:Hide()

    if self.ui.memberDivider then self.ui.memberDivider:Hide() end
    if self.ui.memberLabel then self.ui.memberLabel:Hide() end
    if self.ui.officerDivider then self.ui.officerDivider:Hide() end
    if self.ui.officerLabel then self.ui.officerLabel:Hide() end
    self.ui.guildSectionButton = NButton(sidebar, "GUILD", 12, -158, 142, 20, function()
        OTLGM_DB.settings.guildSectionExpanded = not OTLGM_DB.settings.guildSectionExpanded
        OTLGM:RefreshNavigation()
    end, "section")
    self.ui.guildSectionButton.text:SetJustifyH("LEFT")
    self.ui.guildSectionButton.text:ClearAllPoints()
    self.ui.guildSectionButton.text:SetPoint("LEFT", self.ui.guildSectionButton, "LEFT", 9, 0)
    self.ui.guildSectionButton.text:SetWidth(124)
    self.ui.officerSectionButton = NButton(sidebar, "OFFICER TOOLS", 12, -276, 142, 20, function()
        OTLGM_DB.settings.officerSectionExpanded = not OTLGM_DB.settings.officerSectionExpanded
        OTLGM:RefreshNavigation()
    end, "section")
    self.ui.officerSectionButton.text:SetJustifyH("LEFT")
    self.ui.officerSectionButton.text:ClearAllPoints()
    self.ui.officerSectionButton.text:SetPoint("LEFT", self.ui.officerSectionButton, "LEFT", 9, 0)
    self.ui.officerSectionButton.text:SetWidth(124)

    -- Navigation is split into fixed top, scrollable middle and fixed footer.
    -- The scroll frame stays invisible while content fits, but prevents future
    -- pages from ever overlapping Officer Mode or utility controls.
    self.ui.sidebarMiddle174 = CreateFrame("ScrollFrame", "OTLGM_SidebarMiddle174", sidebar)
    self.ui.sidebarMiddle174:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 12, -154)
    self.ui.sidebarMiddle174:SetWidth(142)
    self.ui.sidebarMiddle174:SetHeight(268)
    self.ui.sidebarMiddle174:EnableMouse(true)
    self.ui.sidebarMiddle174:EnableMouseWheel(true)
    self.ui.sidebarMiddleChild174 = CreateFrame("Frame", nil, self.ui.sidebarMiddle174)
    self.ui.sidebarMiddleChild174:SetWidth(142)
    self.ui.sidebarMiddleChild174:SetHeight(268)
    self.ui.sidebarMiddle174:SetScrollChild(self.ui.sidebarMiddleChild174)
    self.ui.sidebarMiddle174:SetScript("OnMouseWheel", function()
        local current = this:GetVerticalScroll() or 0
        local child = OTLGM.ui and OTLGM.ui.sidebarMiddleChild174
        local maximum = math.max(0, ((child and child:GetHeight()) or 268) - (this:GetHeight() or 268))
        local nextValue = math.max(0, math.min(maximum, current - ((arg1 or 0) * 42)))
        this:SetVerticalScroll(nextValue)
        OTLGM_DB.settings.sidebarScroll174 = nextValue
    end)
end

function OTLGM:BuildNextNavigationButtons()
    local sidebar = self.ui.sidebar
    self.ui.navButtons.search = NButton(sidebar, "Search", 12, -90, 142, 28, function() OTLGM:ShowPage("search") end, "primary")
    NIcon(self.ui.navButtons.search, "Interface\\Icons\\INV_Misc_Spyglass_03", 16)
    self.ui.navButtons.professions = NButton(sidebar, "Professions", 12, -214, 142, 26, function() OTLGM:ShowPage("professions") end, "normal")
    NIcon(self.ui.navButtons.professions, "Interface\\Icons\\Trade_BlackSmithing", 16)
end

function OTLGM:BuildNextSettingsEnhancements()
    local data = self.ui.settingsPanels and self.ui.settingsPanels.DATA
    if not data then return end
    local page = data:GetParent()
    self.ui.copyDiagnosticsButton = NButton(data, "Copy Diagnostic Report", 14, -348, 180, 30, function()
        OTLGM:ShowCopyDialog("OTLGM Diagnostic Report", OTLGM:GetDiagnosticsText())
    end, "utility")
    self.ui.cleanCraftingButton = NButton(data, "Clean Expired Data", 204, -348, 160, 30, function()
        OTLGM:PurgePveData(true)
        OTLGM:PurgeCraftingData(true)
        OTLGM:SetStatus("Expired PvE and crafting data cleaned.")
        OTLGM:RefreshSettingsPage()
    end, "utility")

    local positions = {
        GENERAL = {0, 96}, CHAT = {102, 130}, PVE = {418, 94}, DATA = {518, 200}
    }
    local key, pos, button
    for key, pos in pairs(positions) do
        button = self.ui.settingsSectionButtons[key]
        if button then button:ClearAllPoints() button:SetPoint("TOPLEFT", page, "TOPLEFT", pos[1], -50) button:SetWidth(pos[2]) end
    end
    self.ui.settingsSectionButtons.NOTIFY = NButton(page, "Notifications", 238, -50, 174, 30, function() OTLGM:ShowSettingsSection("NOTIFY") end, "utility")

    local panel = NPanel(page, 0, -88, 718, 430, 0.032, 0.028, 0.023)
    panel:Hide()
    self.ui.settingsPanels.NOTIFY = panel
    NText(panel, "GameFontNormal", "NOTIFICATION CATEGORIES", 14, -14, 360, "LEFT")
    local intro = NWrapped(panel, "GameFontNormalSmall", "Visual badges and sounds are controlled separately. Ordinary roster scans and join/leave history remain quiet by default. Leadership chooses explicitly whether an announcement should notify members.", 14, -38, 686, 48)
    intro:SetTextColor(0.64, 0.64, 0.62)
    local definitions = {
        {"raid", "Raid alerts", "New raids and urgent raid changes"},
        {"announcement", "Leadership announcements", "Only posts published with Notify Members"},
        {"group", "Group Finder", "New relevant groups"},
        {"response", "Applications & responses", "Accepted, declined and replies to your requests"},
        {"crafting", "Crafting requests", "New guild crafting requests"},
        {"reaction", "Reactions & replies", "Reactions on your own posts"},
        {"mention", "Guild Chat mentions", "Your character name is mentioned in guild or officer chat"},
        {"background", "Background activity", "Roster scans, joins, leaves and database updates"},
    }
    self.ui.notificationRows152 = {}
    local i
    for i = 1, table.getn(definitions) do
        local category = definitions[i][1]
        local row = NPanel(panel, 12, -80 - ((i - 1) * 42), 694, 36, 0.024, 0.022, 0.019)
        row.label = NText(row, "GameFontNormalSmall", definitions[i][2], 10, -5, 202, "LEFT")
        row.detail = NText(row, "GameFontNormalSmall", definitions[i][3], 10, -19, 300, "LEFT")
        row.detail:SetTextColor(0.50, 0.50, 0.48)
        row.visual = NButton(row, "Visual", 314, -4, 104, 27, function()
            local pref = OTLGM:GetNotificationPreference152(category)
            pref.visual = not pref.visual
            OTLGM:RefreshSettingsPage()
        end, "utility")
        row.sound = NButton(row, "Sound", 426, -4, 104, 27, function()
            local pref = OTLGM:GetNotificationPreference152(category)
            pref.sound = not pref.sound
            OTLGM:RefreshSettingsPage()
        end, "confirm")
        row.choice = NButton(row, "Message", 538, -4, 144, 27, function()
            OTLGM:CycleNotificationSound152(category)
            OTLGM:RefreshSettingsPage()
        end, "normal")
        row.category = category
        self.ui.notificationRows152[category] = row
    end
end

function OTLGM:PolishFirstRunWizard()
    local wizard = self.ui and self.ui.firstRunWizard
    if not wizard then return end
    wizard:SetWidth(660)
    wizard:SetHeight(410)
    wizard:SetBackdropColor(0.012, 0.011, 0.009, 1)
    wizard:SetBackdropBorderColor(0.96, 0.65, 0.20, 1)
    wizard.title:SetWidth(612)
    wizard.step:SetWidth(612)
    wizard.body:ClearAllPoints()
    wizard.body:SetPoint("TOPLEFT", wizard, "TOPLEFT", 46, -94)
    wizard.body:SetWidth(568)
    wizard.body:SetHeight(210)
    wizard.back:Hide()
    wizard.next:ClearAllPoints()
    wizard.next:SetPoint("TOPLEFT", wizard, "TOPLEFT", 250, -354)
    wizard.next:SetWidth(160)
end

-- Compatibility stage retained deliberately: Reliability wraps this modal
-- stack handler after all UI generations have loaded.
function OTLGM:_Stage_UINext_CloseTopModal152_2()
    local stack = self.ui and self.ui.modalStack154 or {}
    local i
    for i = table.getn(stack), 1, -1 do
        if stack[i] and stack[i]:IsVisible() then stack[i]:Hide() return true end
    end
    return false
end

function OTLGM:ApplyEscapeHandler152(editBox, onClear, closeFrame)
    if not editBox then return end
    editBox:SetScript("OnEscapePressed", function()
        local text = this:GetText() or ""
        if text ~= "" then
            this:SetText("")
            if onClear then onClear() end
            return
        end
        this:ClearFocus()
        if closeFrame and closeFrame:IsVisible() then closeFrame:Hide() return end
        if OTLGM:CloseTopModal152() then return end
        if OTLGM.ui and OTLGM.ui.main then OTLGM.ui.main:Hide() end
    end)
end

function OTLGM:ApplyGuildChatEscapeBehavior()
    self:ApplyEscapeHandler152(self.ui and self.ui.guildChatEdit, function()
        if OTLGM and OTLGM.SaveGuildChatDraft and OTLGM.GetGuildChatChannel then OTLGM:SaveGuildChatDraft(OTLGM:GetGuildChatChannel()) end
    end)
end

function OTLGM:ApplyAllEscapeHandlers152()
    self:ApplyGuildChatEscapeBehavior()
    self:ApplyEscapeHandler152(self.ui.rosterSearch, function() if OTLGM.RefreshRosterPage then OTLGM:RefreshRosterPage() end end)
    self:ApplyEscapeHandler152(self.ui.historySearch, function() if OTLGM.RefreshHistoryPage then OTLGM:RefreshHistoryPage() end end)
    self:ApplyEscapeHandler152(self.ui.globalSearchEdit, function() OTLGM.ui.globalSearchOffset = 0 OTLGM:RefreshSearchPage(true) end)
    self:ApplyEscapeHandler152(self.ui.craftingSearchEdit, function() OTLGM.ui.craftingRecipeOffset = 0 OTLGM:RefreshProfessionsPage() end)
    self:ApplyEscapeHandler152(self.ui.guildBoardNewEdit152, function() end)
    local function ModalEscape154(edit)
        if not edit then return end
        edit:SetScript("OnEscapePressed", function()
            this:ClearFocus()
            OTLGM:CloseTopModal152()
        end)
    end
    if self.ui.craftingRequestDialog then ModalEscape154(self.ui.craftingRequestDialog.itemEdit) ModalEscape154(self.ui.craftingRequestDialog.noteEdit) end
    if self.ui.announcementComposer152 then ModalEscape154(self.ui.announcementComposer152.titleEdit) ModalEscape154(self.ui.announcementComposer152.bodyEdit) end
end

function OTLGM:_Stage_UINext_BuildNextUI_1()
    if self.ui.v15Built then return end
    self.ui.pages.search = NPage(self.ui.content)
    self.ui.pages.professions = NPage(self.ui.content)
    self:BuildNextSearchPage(self.ui.pages.search)
    self:BuildNextProfessionsPage(self.ui.pages.professions)
    self:BuildNextHeaderAndFooter()
    self:BuildNextNavigationButtons()
    self:BuildNextHomeEnhancements()
    self:BuildNextPveEnhancements()
    self:BuildNextSettingsEnhancements()
    self:PolishFirstRunWizard()
    if self.RegisterModal152 then
        self:RegisterModal152(self.ui.craftingRequestDialog)
        self:RegisterModal152(self.ui.groupTemplateDialog)
    end
    self:ApplyAllEscapeHandlers152()
    self.ui.v15Built = true
    self.ui152Loaded = true
    OTLGM.ui152Loaded = true
end

function OTLGM:BuildUI()
    if self.ui and self.ui.main and self.ui.v15Built then return end
    local requestedPage = OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.lastPage or nil
    BaseBuildUI(self)
    if not self.ui or not self.ui.main then return end
    self:BuildNextUI()
    if self.ApplyWindowTheme then self:ApplyWindowTheme() end
    self:RefreshNavigation()
    if requestedPage == "search" or requestedPage == "professions" or requestedPage == "treasury" then self:ShowPage(requestedPage)
    else self:RefreshVisiblePage() end
end

function OTLGM:RefreshDateIndicator(force)
    if not self.ui or not self.ui.dateIndicator then return end
    local key = date("%Y-%m-%d", time())
    if force or self.ui.dateIndicatorKey ~= key then
        self.ui.dateIndicatorKey = key
        self.ui.dateIndicator:SetText(NDateText())
    end
end

function OTLGM:RefreshUpdateWarning()
    if not self.ui or not self.ui.updateWarning then return end
    local _, latest = self:GetDetectedAddonUsers(86400)
    if latest and self:IsVersionNewer(latest, self.version) then
        NSetButtonText(self.ui.updateWarning, "UPDATE  v" .. tostring(latest))
        self.ui.updateWarning:Show()
    else self.ui.updateWarning:Hide() end
end

function OTLGM:RefreshNavigation()
    if not self.ui or not self.ui.v15Built then return BaseRefreshNavigation(self) end
    local officer = self:IsOfficerMode()
    local guildOpen = OTLGM_DB.settings.guildSectionExpanded ~= false
    local officerOpen = OTLGM_DB.settings.officerSectionExpanded ~= false
    local sidebar = self.ui.sidebar
    local middle = self.ui.sidebarMiddle174
    local middleChild = self.ui.sidebarMiddleChild174 or sidebar
    local key, button
    for key, button in pairs(self.ui.navButtons or {}) do button:Hide() end
    if self.ui.memberDivider then self.ui.memberDivider:Hide() end
    if self.ui.memberLabel then self.ui.memberLabel:Hide() end
    if self.ui.officerDivider then self.ui.officerDivider:Hide() end
    if self.ui.officerLabel then self.ui.officerLabel:Hide() end

    if self.ui.generalLabel then
        self.ui.generalLabel:ClearAllPoints()
        self.ui.generalLabel:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 12, -10)
        self.ui.generalLabel:SetText("MAIN")
        self.ui.generalLabel:Show()
    end

    local function Reparent(control, parent)
        if not control or not parent then return end
        if control.GetParent and control:GetParent() ~= parent and control.SetParent then control:SetParent(parent) end
    end

    local function PlaceNavigationButton(buttonKey, parent, x, y, height)
        local navButton = OTLGM.ui.navButtons and OTLGM.ui.navButtons[buttonKey]
        if not navButton then return y end
        Reparent(navButton, parent)
        navButton:ClearAllPoints()
        navButton:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        navButton:SetWidth(142)
        navButton:SetHeight(height or 22)
        navButton:Show()
        return y - (height or 22) - 2
    end

    -- Fixed primary navigation.
    PlaceNavigationButton("home", sidebar, 12, -28, 28)
    PlaceNavigationButton("guildchat", sidebar, 12, -58, 28)
    PlaceNavigationButton("search", sidebar, 12, -88, 28)
    PlaceNavigationButton("pve", sidebar, 12, -118, 30)

    -- Scrollable guild/officer navigation. Every row derives from one cursor.
    Reparent(self.ui.guildSectionButton, middleChild)
    Reparent(self.ui.officerSectionButton, middleChild)
    local cursor = 0
    self.ui.guildSectionButton:ClearAllPoints()
    self.ui.guildSectionButton:SetPoint("TOPLEFT", middleChild, "TOPLEFT", 0, cursor)
    self.ui.guildSectionButton:SetWidth(142)
    self.ui.guildSectionButton:SetHeight(20)
    NSetButtonText(self.ui.guildSectionButton, guildOpen and "-  GUILD" or "+  GUILD")
    self.ui.guildSectionButton:Show()
    cursor = cursor - 22
    if guildOpen then
        local guildKeys = { "roster", "professions", "achievements", "treasury", "activity" }
        local i
        for i = 1, table.getn(guildKeys) do cursor = PlaceNavigationButton(guildKeys[i], middleChild, 0, cursor, 22) end
    end

    cursor = cursor - 2
    if officer then
        self.ui.officerSectionButton:ClearAllPoints()
        self.ui.officerSectionButton:SetPoint("TOPLEFT", middleChild, "TOPLEFT", 0, cursor)
        self.ui.officerSectionButton:SetWidth(142)
        self.ui.officerSectionButton:SetHeight(20)
        NSetButtonText(self.ui.officerSectionButton, officerOpen and "-  OFFICER TOOLS" or "+  OFFICER TOOLS")
        self.ui.officerSectionButton:Show()
        cursor = cursor - 22
        if officerOpen then
            local officerKeys = { "overview", "recruitment", "history", "inactive" }
            local i
            for i = 1, table.getn(officerKeys) do cursor = PlaceNavigationButton(officerKeys[i], middleChild, 0, cursor, 22) end
        end
    else
        self.ui.officerSectionButton:Hide()
    end

    local contentHeight = math.max(268, -cursor + 2)
    middleChild:SetHeight(contentHeight)
    if middle then
        local maximum = math.max(0, contentHeight - (middle:GetHeight() or 268))
        local wanted = math.max(0, math.min(maximum, tonumber(OTLGM_DB.settings.sidebarScroll174) or 0))
        middle:SetVerticalScroll(wanted)
        OTLGM_DB.settings.sidebarScroll174 = wanted
        middle:Show()
    end

    -- Fixed footer, independent from the number of navigation rows.
    PlaceNavigationButton("settings", sidebar, 12, -493, 22)
    if self.ui.modeText then
        self.ui.modeText:ClearAllPoints()
        self.ui.modeText:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 12, -430)
        self.ui.modeText:SetWidth(142)
        self.ui.modeText:SetText(officer and self.colors.gold .. "OFFICER MODE" .. self.colors.reset or self.colors.grey .. "MEMBER MODE" .. self.colors.reset)
    end
    if self.ui.versionText then
        self.ui.versionText:ClearAllPoints()
        self.ui.versionText:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 12, -444)
        self.ui.versionText:SetWidth(142)
        self.ui.versionText:SetText("Lion GM  v" .. self.version)
    end
    if self.ui.addonUsersButton then
        Reparent(self.ui.addonUsersButton, sidebar)
        self.ui.addonUsersButton:ClearAllPoints()
        self.ui.addonUsersButton:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 12, -459)
        self.ui.addonUsersButton:SetHeight(28)
        self.ui.addonUsersButton:Show()
    end
    if self.ui.scanButton then
        Reparent(self.ui.scanButton, sidebar)
        self.ui.scanButton:ClearAllPoints()
        self.ui.scanButton:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 12, -519)
        self.ui.scanButton:SetHeight(30)
        self.ui.scanButton:Show()
    end

    self:RefreshAddonUsersIndicator()
    if self.RefreshGuildChatNavigationBadge then self:RefreshGuildChatNavigationBadge() end
    if self.RefreshPveNavigationBadge then self:RefreshPveNavigationBadge() end
    local homeUnread = self.GetAnnouncementUnreadCount154 and self:GetAnnouncementUnreadCount154() or 0
    if self.ui.navButtons.home then
        NSetButtonText(self.ui.navButtons.home, "Home")
        if self.SetNavigationBadge170 then self:SetNavigationBadge170(self.ui.navButtons.home, homeUnread, "gold") end
    end
    local craftUnread = self:GetCraftingUnread("RECIPES") + self:GetCraftingUnread("REQUESTS")
    if self.ui.navButtons.professions then
        NSetButtonText(self.ui.navButtons.professions, "Professions")
        if self.SetNavigationBadge170 then self:SetNavigationBadge170(self.ui.navButtons.professions, craftUnread, "blue") end
    end
    local unread = self:GetUnreadCount()
    if self.ui.navButtons.history then
        NSetButtonText(self.ui.navButtons.history, "History")
        if self.SetNavigationBadge170 then self:SetNavigationBadge170(self.ui.navButtons.history, unread, "gold") end
    end

    local visibleSelection = self.ui.currentPage == "guildinfo" and "home" or self.ui.currentPage
    for key, button in pairs(self.ui.navButtons or {}) do NSetSelected(button, key == visibleSelection) end
    NSetSelected(self.ui.guildSectionButton, visibleSelection == "roster" or visibleSelection == "professions" or visibleSelection == "activity" or visibleSelection == "achievements" or visibleSelection == "treasury")
    NSetSelected(self.ui.officerSectionButton, visibleSelection == "overview" or visibleSelection == "recruitment" or visibleSelection == "history" or visibleSelection == "inactive")
    self:RefreshUpdateWarning()
    if self.RefreshExperienceNavigation170 then self:RefreshExperienceNavigation170() end
end

function OTLGM:ShowPage(pageKey)
    if not self.ui or not self.ui.v15Built then return BaseShowPage(self, pageKey) end
    local previousPage170 = self.ui.currentPage
    if pageKey ~= "search" and pageKey ~= "professions" and pageKey ~= "treasury" then
        BaseShowPage(self, pageKey)
        self:RefreshNavigation()
        if self.RepairInteractiveTree170 and self.ui.pages and self.ui.pages[pageKey] then self:RepairInteractiveTree170(self.ui.pages[pageKey]) end
        if previousPage170 ~= pageKey and self.StartExperienceMotion170 and self.ui.pages and self.ui.pages[pageKey] then self:StartExperienceMotion170(self.ui.pages[pageKey], 0.78, 1, 0.11) end
        return
    end
    local key, page
    for key, page in pairs(self.ui.pages or {}) do if key == pageKey then page:Show() else page:Hide() end end
    self.ui.currentPage = pageKey
    OTLGM_DB.settings.lastPage = pageKey
    if pageKey == "search" then self:RefreshSearchPage(true) end
    if pageKey == "professions" then
        self:RequestCraftingSync(false)
        self:MarkCraftingRead(OTLGM_DB.settings.craftingSection or "RECIPES")
        if self.MarkInboxPageRead170 then self:MarkInboxPageRead170("professions") end
        self:RefreshProfessionsPage()
    end
    if pageKey == "treasury" then
        self:RequestTreasurySync170(false)
        self:RefreshGuildBankAdapter170()
        self:RefreshTreasuryPage170()
    end
    self:RefreshNavigation()
    if self.RepairInteractiveTree170 and self.ui.pages and self.ui.pages[pageKey] then self:RepairInteractiveTree170(self.ui.pages[pageKey]) end
    if previousPage170 ~= pageKey and self.StartExperienceMotion170 and self.ui.pages and self.ui.pages[pageKey] then self:StartExperienceMotion170(self.ui.pages[pageKey], 0.78, 1, 0.11) end
end

function OTLGM:RefreshVisiblePage()
    if not self.ui or not self.ui.v15Built then return BaseRefreshVisiblePage(self) end
    if self.ui.currentPage == "search" then self:RefreshSearchPage(true) return end
    if self.ui.currentPage == "professions" then self:RefreshProfessionsPage() return end
    if self.ui.currentPage == "treasury" then self:RefreshTreasuryPage170() return end
    BaseRefreshVisiblePage(self)
end

function OTLGM:RefreshHomePage()
    BaseRefreshHomePage(self)
    if not self.ui or not self.ui.v15Built then return end
    self:RefreshHomeRecent()
    if self.RefreshHomeExperience170 then self:RefreshHomeExperience170() end
end

local function NDelta(self, value)
    value = tonumber(value) or 0
    if value > 0 then return self.colors.green .. "+" .. tostring(value) .. self.colors.reset end
    if value < 0 then return self.colors.red .. tostring(value) .. self.colors.reset end
    return self.colors.grey .. "0" .. self.colors.reset
end

function OTLGM:RefreshOverviewPage()
    BaseRefreshOverviewPage(self)
    if not self.ui or not self.ui.v15Built or not self.ui.overviewGrowth then return end
    local comparison = self:GetWeeklyComparison()
    if comparison.available then
        self.ui.overviewGrowth:SetText("7-DAY CHANGE  " .. NDelta(self, comparison.net))
        self.ui.overviewChanges:SetText("Members " .. tostring(comparison.current.total) .. "  (" .. NDelta(self, comparison.delta.total) .. ")     Level 60 " .. tostring(comparison.current.level60) .. "  (" .. NDelta(self, comparison.delta.level60) .. ")\nActive 7d " .. tostring(comparison.current.active7) .. "  (" .. NDelta(self, comparison.delta.active7) .. ")     Online peak " .. tostring(comparison.currentPeak) .. "  (" .. NDelta(self, comparison.delta.peak) .. ")")
        self.ui.overviewFreshness:SetText("Joined " .. tostring(comparison.joins) .. "  |  Left " .. tostring(comparison.leaves) .. "  |  Compared with " .. date("%d %b", comparison.previous.ts or self:Now()))
    else
        self.ui.overviewGrowth:SetText("WEEKLY COMPARISON")
        self.ui.overviewChanges:SetText("A reliable comparison will appear after the addon stores a roster snapshot close to seven days old.")
        self.ui.overviewFreshness:SetText("Current week: " .. tostring(comparison.current.total or 0) .. " members, " .. tostring(comparison.current.level60 or 0) .. " level 60.")
    end
end

function OTLGM:_Stage_UINext_RefreshPvePage_2()
    if OTLGM_DB.settings.pveSection == "BOARD" then OTLGM_DB.settings.pveSection = "GROUPS" end
    BaseRefreshPvePage(self)
    if self.ui and self.ui.v15Built then
        if self.ui.pveTabButtons and self.ui.pveTabButtons.BOARD then self.ui.pveTabButtons.BOARD:Hide() end
        if self.ui.pvePanels and self.ui.pvePanels.BOARD then self.ui.pvePanels.BOARD:Hide() end
        self:RefreshNextPveActions()
    end
end

function OTLGM:RefreshSettingsPage()
    BaseRefreshSettingsPage(self)
    if not self.ui or not self.ui.v15Built then return end
    local category, row, pref
    for category, row in pairs(self.ui.notificationRows152 or {}) do
        pref = self:GetNotificationPreference152(category)
        NSetButtonText(row.visual, pref.visual and "Visual: ON" or "Visual: OFF")
        NSetSelected(row.visual, pref.visual)
        NSetButtonText(row.sound, pref.sound and "Sound: ON" or "Sound: OFF")
        NSetSelected(row.sound, pref.sound)
        NSetButtonText(row.choice, self:GetNotificationSoundLabel152(category))
        NSetEnabled(row.choice, pref.sound, "Enable sound for this category first.")
    end
    self:RefreshUpdateWarning()
    if self.RefreshExperienceSettings170 then self:RefreshExperienceSettings170() end
end

function OTLGM:RefreshAll()
    BaseRefreshAll(self)
    if not self.ui or not self.ui.v15Built then return end
    self:RefreshSearchPage(true)
    self:RefreshProfessionsPage()
    self:RefreshHomeRecent()
    self:RefreshUpdateWarning()
    self:RefreshDateIndicator(false)
end

function OTLGM:ShowAddonUsersTooltip(owner)
    if not owner then return end
    local list = self:GetDetectedAddonUserList(86400)
    local now = self:Now()
    local cutoffLevel = tonumber(OTLGM_DB.settings.lowLevelAddonCutoff) or 10
    local online, recent = {}, {}
    local hiddenLow, outdated = 0, 0
    local i, info
    for i = 1, table.getn(list) do
        info = list[i]
        if info.version and info.version ~= "Detected" and self:IsVersionNewer(self.version, info.version) then outdated = outdated + 1 end
        if info.online then table.insert(online, info)
        elseif (tonumber(info.level) or 0) <= cutoffLevel then hiddenLow = hiddenLow + 1
        else table.insert(recent, info) end
    end
    table.sort(online, function(a, b)
        local ap, bp = NRankPriority(a), NRankPriority(b)
        if ap ~= bp then return ap < bp end
        if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) > (b.level or 0) end
        return string.lower(a.name or "") < string.lower(b.name or "")
    end)
    table.sort(recent, function(a, b) return (a.ts or 0) > (b.ts or 0) end)
    -- The launcher sits at the left edge; ANCHOR_RIGHT covered the search and
    -- roster results. A compact upward tooltip stays primarily over navigation.
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:AddLine("Order of the Lion Addon Network", 1, 0.82, 0.35)
    GameTooltip:AddDoubleLine("Online now", tostring(table.getn(online)), 0.75, 0.75, 0.75, 0.35, 1.0, 0.35)
    GameTooltip:AddDoubleLine("Seen in 24 hours", tostring(table.getn(list)), 0.75, 0.75, 0.75, 1.0, 1.0, 1.0)
    if outdated > 0 then GameTooltip:AddDoubleLine("Older versions", tostring(outdated), 0.75, 0.75, 0.75, 1.0, 0.42, 0.25) end
    if hiddenLow > 0 then GameTooltip:AddDoubleLine("Low-level offline hidden", tostring(hiddenLow), 0.75, 0.75, 0.75, 0.60, 0.60, 0.60) end
    if table.getn(online) > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("ONLINE USERS", 0.92, 0.70, 0.28)
        local maxOnline = math.min(8, table.getn(online))
        for i = 1, maxOnline do
            info = online[i]
            local versionText = info.version and info.version ~= "Detected" and ("v" .. tostring(info.version)) or "detected"
            local rankText = info.leadership and "Leadership" or (info.rank ~= "" and info.rank or ("Level " .. tostring(info.level or 0)))
            GameTooltip:AddDoubleLine(self:GetClassColor(info.class) .. (info.name or "Unknown") .. self.colors.reset .. "  " .. versionText, rankText, 1, 1, 1, 0.65, 0.65, 0.65)
        end
        if table.getn(online) > maxOnline then GameTooltip:AddLine("...and " .. tostring(table.getn(online) - maxOnline) .. " more online", 0.62, 0.62, 0.62) end
    end
    local remaining = math.max(0, 10 - math.min(8, table.getn(online)))
    if remaining > 0 and table.getn(recent) > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("RECENTLY SEEN", 0.62, 0.72, 0.92)
        local maxRecent = math.min(remaining, table.getn(recent))
        for i = 1, maxRecent do
            info = recent[i]
            GameTooltip:AddDoubleLine(self:GetClassColor(info.class) .. (info.name or "Unknown") .. self.colors.reset, NAge(self, info.ts), 1, 1, 1, 0.60, 0.60, 0.60)
        end
        if table.getn(recent) > maxRecent then GameTooltip:AddLine("...and " .. tostring(table.getn(recent) - maxRecent) .. " more recently seen", 0.58, 0.58, 0.58) end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Full network diagnostics: Settings", 0.52, 0.52, 0.50)
    GameTooltip:Show()
end

function OTLGM:RefreshWizard()
    local wizard = self.ui and self.ui.firstRunWizard
    if not wizard then return end
    wizard.currentStep = 4
    wizard.step:SetText("Guild companion overview")
    local i
    for i = 1, table.getn(wizard.intervalButtons or {}) do wizard.intervalButtons[i]:Hide() end
    wizard.back:Hide()
    wizard.title:SetText(self.colors.gold .. "WELCOME TO ORDER OF THE LION" .. self.colors.reset)
    wizard.body:SetText("Guild Chat  -  readable guild communication and the Guild Board.\n\nPvE Hub  -  raid alerts and group finding; official raid sign-ups remain in Discord.\n\nProfessions  -  scan recipes, find guild crafters and create crafting requests.\n\nHome  -  leadership announcements, the next raid and useful recent activity.\n\nOpen each profession window once to share its recipes. All options can be changed later in Settings.")
    NSetButtonText(wizard.next, "Start")
end

function OTLGM:OpenFirstRunWizard()
    if self.ui.main and not self.ui.main:IsVisible() then self.ui.main:Show() end
    self.ui.firstRunWizard.currentStep = 4
    if self.ShowModal152 then self:ShowModal152(self.ui.firstRunWizard) else self.ui.firstRunWizard:Show() end
    self:RefreshWizard()
end


-- ---------------------------------------------------------------------------
-- Preserved profession categories/filters and full activity readers. These
-- explicit stages are composed before BuildUI is executed.
-- ---------------------------------------------------------------------------

local BaseBuildRecipesPanel153 = OTLGM._Stage_UINext_BuildRecipesPanel_1
local BaseBuildNextUI153 = OTLGM._Stage_UINext_BuildNextUI_1
local BaseGetCraftingSearchResults153 = OTLGM._Stage_Crafting_GetCraftingSearchResults_1
local BaseRefreshCraftingRecipesPanel153 = OTLGM._Stage_UINext_RefreshCraftingRecipesPanel_1

local categoryDefinitions153 = {
    ALL = { {"ALL", "All"} },
    ALCHEMY = { {"ALL", "All"}, {"POTIONS", "Potions"}, {"ELIXIRS", "Elixirs"}, {"FLASKS", "Flasks"}, {"TRANSMUTES", "Transmutes"}, {"OILS", "Oils"}, {"OTHER", "Other"} },
    BLACKSMITHING = { {"ALL", "All"}, {"WEAPONS", "Weapons"}, {"ARMOR", "Armor"}, {"SHIELDS", "Shields"}, {"TOOLS", "Tools"}, {"SPECIAL", "Special"} },
    COOKING = { {"ALL", "All"}, {"FOOD_BUFFS", "Food Buffs"}, {"RESTORATION", "Restoration"}, {"DRINKS", "Drinks"}, {"SPECIAL", "Special"} },
    ENCHANTING = { {"ALL", "All"}, {"WEAPON", "Weapon"}, {"CHEST", "Chest"}, {"BRACERS", "Bracers"}, {"GLOVES", "Gloves"}, {"BOOTS", "Boots"}, {"CLOAK", "Cloak"}, {"SHIELD", "Shield"}, {"LEGS", "Legs"}, {"OTHER", "Other"} },
    ENGINEERING = { {"ALL", "All"}, {"DEVICES", "Devices"}, {"EXPLOSIVES", "Explosives"}, {"GOGGLES", "Goggles"}, {"SCOPES", "Scopes"}, {"AMMO", "Ammo"}, {"PETS", "Pets"}, {"MATERIALS", "Materials"} },
    JEWELCRAFTING = { {"ALL", "All"}, {"GEMS", "Gems"}, {"RINGS", "Rings"}, {"NECKLACES", "Necklaces"}, {"TRINKETS", "Trinkets"}, {"MATERIALS", "Materials"} },
    LEATHERWORKING = { {"ALL", "All"}, {"LEATHER_ARMOR", "Leather Armor"}, {"MAIL_ARMOR", "Mail Armor"}, {"ARMOR_KITS", "Armor Kits"}, {"BAGS", "Bags"}, {"SPECIAL", "Special"} },
    TAILORING = { {"ALL", "All"}, {"ARMOR", "Armor"}, {"BAGS", "Bags"}, {"SHIRTS", "Shirts"}, {"CLOTH", "Cloth"}, {"SPECIAL", "Special"} },
    MINING = { {"ALL", "All"}, {"BARS", "Bars"}, {"ALLOYS", "Alloys"}, {"SPECIAL", "Special"} },
}

local levelFilters153 = {
    {"ANY", "Level: Any"}, {"1_20", "Level: 1-20"}, {"21_40", "Level: 21-40"},
    {"41_60", "Level: 41-60"}, {"61_PLUS", "Level: 61+"}, {"UNKNOWN", "Level: ?"},
}
local skillFilters170 = {
    {"ANY", "Skill: Any"}, {"1_75", "Skill: 1-75"}, {"76_150", "Skill: 76-150"},
    {"151_225", "Skill: 151-225"}, {"226_300", "Skill: 226-300"}, {"301_PLUS", "Skill: 301+"}, {"UNKNOWN", "Skill: ?"},
}
local rarityFilters153 = {
    {"ANY", "Rarity: Any"}, {"COMMON", "Common"}, {"UNCOMMON", "Uncommon"},
    {"RARE", "Rare"}, {"EPIC", "Epic"}, {"UNKNOWN", "Unknown"},
}
local sortFilters153 = {
    {"ONLINE", "Sort: Online"}, {"NAME", "Sort: Name"}, {"LEVEL", "Sort: Level"},
    {"RARITY", "Sort: Rarity"}, {"RECENT", "Sort: Recent"}, {"CRAFTERS", "Sort: Crafters"},
}

local function NContains153(text, needle)
    return string.find(string.lower(text or ""), string.lower(needle or ""), 1, true) ~= nil
end

local function NGetItemMeta153(recipe)
    local quality = tonumber(recipe and recipe.quality) or 0
    local requiredLevel = tonumber(recipe and recipe.requiredLevel) or 0
    local itemLevel = tonumber(recipe and recipe.itemLevel) or 0
    local requiredSkill = tonumber(recipe and recipe.requiredSkill) or 0
    local itemType = recipe and recipe.itemType or ""
    local itemSubType = recipe and recipe.itemSubType or ""
    local equipLoc = recipe and recipe.equipLoc or ""
    local itemId = tonumber(recipe and recipe.itemId) or 0
    if itemId > 0 and GetItemInfo then
        local name, link, cachedQuality, cachedItemLevel, cachedRequiredLevel, cachedType, cachedSubType, stackCount, cachedEquipLoc, texture = OTLGM:GetItemInfoSafe(itemId)
        quality = tonumber(cachedQuality) or quality
        requiredLevel = tonumber(cachedRequiredLevel) or requiredLevel
        itemLevel = tonumber(cachedItemLevel) or itemLevel
        itemType = cachedType or itemType
        itemSubType = cachedSubType or itemSubType
        equipLoc = cachedEquipLoc or equipLoc
        -- The client cache may become ready after the network snapshot was
        -- received. Persist only exact API values so row labels, details,
        -- sorting and later searches all converge on the same metadata.
        if recipe and (name or link or texture) then
            if cachedQuality ~= nil then recipe.quality = tonumber(cachedQuality) or recipe.quality end
            if cachedItemLevel ~= nil then recipe.itemLevel = tonumber(cachedItemLevel) or recipe.itemLevel end
            if cachedRequiredLevel ~= nil then recipe.requiredLevel = tonumber(cachedRequiredLevel) or recipe.requiredLevel end
            if cachedType ~= nil then recipe.itemType = cachedType end
            if cachedSubType ~= nil then recipe.itemSubType = cachedSubType end
            if cachedEquipLoc ~= nil then recipe.equipLoc = cachedEquipLoc end
            if link and link ~= "" then recipe.itemLink = link end
            if texture and texture ~= "" then recipe.icon = texture end
        end
    end
    return quality, requiredLevel, itemLevel, itemType, itemSubType, equipLoc, requiredSkill
end

function OTLGM:GetCraftingCategoryDefinitions153(professionKey)
    return categoryDefinitions153[professionKey or "ALL"] or categoryDefinitions153.ALL
end

function OTLGM:GetCraftingCategory153(result)
    if not result or not result.recipe then return "OTHER" end
    local profession = result.professionKey or "ALL"
    local name = string.lower(result.recipe.name or "")
    local quality, requiredLevel, itemLevel, itemType, itemSubType, equipLoc = NGetItemMeta153(result.recipe)
    local haystack = name .. " " .. string.lower(itemType or "") .. " " .. string.lower(itemSubType or "") .. " " .. string.lower(equipLoc or "")

    if profession == "ENCHANTING" then
        if NContains153(haystack, "bracer") or NContains153(haystack, "wrist") then return "BRACERS" end
        if NContains153(haystack, "glove") or NContains153(haystack, "hands") then return "GLOVES" end
        if NContains153(haystack, "boot") or NContains153(haystack, "feet") then return "BOOTS" end
        if NContains153(haystack, "cloak") or NContains153(haystack, "back") then return "CLOAK" end
        if NContains153(haystack, "shield") then return "SHIELD" end
        if NContains153(haystack, "chest") or NContains153(haystack, "breastplate") then return "CHEST" end
        if NContains153(haystack, "leg") then return "LEGS" end
        if NContains153(haystack, "weapon") or NContains153(haystack, "staff") or NContains153(haystack, "two-handed") or NContains153(haystack, "2h") then return "WEAPON" end
        return "OTHER"
    end
    if profession == "ALCHEMY" then
        if NContains153(haystack, "transmute") then return "TRANSMUTES" end
        if NContains153(haystack, "flask") then return "FLASKS" end
        if NContains153(haystack, "elixir") then return "ELIXIRS" end
        if NContains153(haystack, "oil") then return "OILS" end
        if NContains153(haystack, "potion") then return "POTIONS" end
        return "OTHER"
    end
    if profession == "BLACKSMITHING" then
        if NContains153(haystack, "shield") then return "SHIELDS" end
        if NContains153(haystack, "weapon") or NContains153(haystack, "sword") or NContains153(haystack, "axe") or NContains153(haystack, "mace") or NContains153(haystack, "dagger") or NContains153(haystack, "hammer") then return "WEAPONS" end
        if NContains153(haystack, "rod") or NContains153(haystack, "tool") or NContains153(haystack, "key") then return "TOOLS" end
        if NContains153(haystack, "armor") or NContains153(haystack, "plate") or NContains153(haystack, "mail") or equipLoc ~= "" then return "ARMOR" end
        return "SPECIAL"
    end
    if profession == "TAILORING" then
        if NContains153(haystack, "bag") or NContains153(haystack, "pouch") then return "BAGS" end
        if NContains153(haystack, "shirt") or NContains153(haystack, "tuxedo") then return "SHIRTS" end
        if NContains153(haystack, "bolt") or NContains153(haystack, "cloth") then return "CLOTH" end
        if equipLoc ~= "" or NContains153(haystack, "robe") or NContains153(haystack, "glove") or NContains153(haystack, "boot") then return "ARMOR" end
        return "SPECIAL"
    end
    if profession == "LEATHERWORKING" then
        if NContains153(haystack, "armor kit") then return "ARMOR_KITS" end
        if NContains153(haystack, "bag") or NContains153(haystack, "quiver") or NContains153(haystack, "ammo pouch") then return "BAGS" end
        if NContains153(haystack, "mail") or NContains153(haystack, "dragonscale") then return "MAIL_ARMOR" end
        if equipLoc ~= "" or NContains153(haystack, "leather") then return "LEATHER_ARMOR" end
        return "SPECIAL"
    end
    if profession == "ENGINEERING" then
        if NContains153(haystack, "bomb") or NContains153(haystack, "dynamite") or NContains153(haystack, "grenade") or NContains153(haystack, "explosive") then return "EXPLOSIVES" end
        if NContains153(haystack, "goggle") or NContains153(haystack, "helmet") then return "GOGGLES" end
        if NContains153(haystack, "scope") then return "SCOPES" end
        if NContains153(haystack, "bullet") or NContains153(haystack, "shell") or NContains153(haystack, "ammo") then return "AMMO" end
        if NContains153(haystack, "pet") or NContains153(haystack, "dragonling") or NContains153(haystack, "squirrel") or NContains153(haystack, "mechanical") then return "PETS" end
        if NContains153(haystack, "bar") or NContains153(haystack, "tube") or NContains153(haystack, "powder") or NContains153(haystack, "frame") then return "MATERIALS" end
        return "DEVICES"
    end
    if profession == "COOKING" then
        if NContains153(haystack, "tea") or NContains153(haystack, "drink") or NContains153(haystack, "rum") or NContains153(haystack, "juice") then return "DRINKS" end
        if NContains153(haystack, "soup") or NContains153(haystack, "stew") or NContains153(haystack, "bread") or NContains153(haystack, "fish") or NContains153(haystack, "meat") then return "RESTORATION" end
        if NContains153(haystack, "delight") or NContains153(haystack, "special") or NContains153(haystack, "feast") then return "SPECIAL" end
        return "FOOD_BUFFS"
    end
    if profession == "JEWELCRAFTING" then
        if NContains153(haystack, "ring") or equipLoc == "INVTYPE_FINGER" then return "RINGS" end
        if NContains153(haystack, "neck") or NContains153(haystack, "amulet") or equipLoc == "INVTYPE_NECK" then return "NECKLACES" end
        if NContains153(haystack, "trinket") or equipLoc == "INVTYPE_TRINKET" then return "TRINKETS" end
        if NContains153(haystack, "gem") or NContains153(haystack, "stone") then return "GEMS" end
        return "MATERIALS"
    end
    if profession == "MINING" then
        if NContains153(haystack, "steel") or NContains153(haystack, "alloy") or NContains153(haystack, "bronze") then return "ALLOYS" end
        if NContains153(haystack, "bar") or NContains153(haystack, "smelt") then return "BARS" end
        return "SPECIAL"
    end
    return "OTHER"
end

local function NCycleSetting153(settingKey, values)
    local current = OTLGM_DB.settings[settingKey] or values[1][1]
    local i
    for i = 1, table.getn(values) do
        if values[i][1] == current then
            OTLGM_DB.settings[settingKey] = values[math.mod(i, table.getn(values)) + 1][1]
            return
        end
    end
    OTLGM_DB.settings[settingKey] = values[1][1]
end

local function NFilterLabel153(values, key)
    local i
    for i = 1, table.getn(values) do if values[i][1] == key then return values[i][2] end end
    return values[1][2]
end

local function NMatchesLevel153(levelValue, filter)
    levelValue = tonumber(levelValue) or 0
    if filter == "ANY" then return true end
    if filter == "UNKNOWN" then return levelValue <= 0 end
    if filter == "1_20" then return levelValue >= 1 and levelValue <= 20 end
    if filter == "21_40" then return levelValue >= 21 and levelValue <= 40 end
    if filter == "41_60" then return levelValue >= 41 and levelValue <= 60 end
    if filter == "61_PLUS" then return levelValue >= 61 end
    if filter == "1_75" then return levelValue >= 1 and levelValue <= 75 end
    if filter == "76_150" then return levelValue >= 76 and levelValue <= 150 end
    if filter == "151_225" then return levelValue >= 151 and levelValue <= 225 end
    if filter == "226_300" then return levelValue >= 226 and levelValue <= 300 end
    if filter == "301_PLUS" then return levelValue >= 301 end
    return true
end

local function NMatchesRarity153(quality, filter)
    quality = tonumber(quality) or 0
    if filter == "ANY" then return true end
    if filter == "UNKNOWN" then return quality <= 0 end
    if filter == "COMMON" then return quality == 1 end
    if filter == "UNCOMMON" then return quality == 2 end
    if filter == "RARE" then return quality == 3 end
    if filter == "EPIC" then return quality >= 4 end
    return true
end

function OTLGM:_Stage_UINext_GetCraftingSearchResults_2(query, professionFilter)
    local results = BaseGetCraftingSearchResults153(self, query, professionFilter)
    if not self.craftingFilterContext153 then return results end
    local category = OTLGM_DB.settings.craftingCategory153 or "ALL"
    local levelFilter = OTLGM_DB.settings.craftingLevelFilter153 or "ANY"
    local levelBasis = OTLGM_DB.settings.craftingLevelBasis170 or "ITEM"
    local rarityFilter = OTLGM_DB.settings.craftingRarityFilter153 or "ANY"
    local onlineOnly = OTLGM_DB.settings.craftingOnlineOnly153 and true or false
    local favoritesOnly = OTLGM_DB.settings.craftingFavoritesOnly170 and true or false
    local filtered = {}
    local i, result, quality, requiredLevel, itemLevel, itemType, itemSubType, equipLoc, requiredSkill, levelValue, hasOnline, favorite, j
    for i = 1, table.getn(results) do
        result = results[i]
        quality, requiredLevel, itemLevel, itemType, itemSubType, equipLoc, requiredSkill = NGetItemMeta153(result.recipe)
        if levelBasis == "REQUIRED" then levelValue = requiredLevel
        elseif levelBasis == "SKILL" then levelValue = requiredSkill
        else levelValue = itemLevel end
        hasOnline = false
        for j = 1, table.getn(result.crafters or {}) do if result.crafters[j].online then hasOnline = true break end end
        favorite = self.IsCraftingFavorite170 and self:IsCraftingFavorite170(result) or false
        if (category == "ALL" or self:GetCraftingCategory153(result) == category) and NMatchesLevel153(levelValue, levelFilter) and NMatchesRarity153(quality, rarityFilter) and (not onlineOnly or hasOnline) and (not favoritesOnly or favorite) then
            result.filterQuality153 = quality
            result.filterRequiredLevel153 = requiredLevel
            result.filterItemLevel153 = itemLevel
            result.filterRequiredSkill170 = requiredSkill
            result.filterLevel170 = levelValue
            result.filterHasOnline153 = hasOnline
            result.filterFavorite170 = favorite
            table.insert(filtered, result)
        end
    end
    local sortKey = OTLGM_DB.settings.craftingSort153 or "ONLINE"
    table.sort(filtered, function(a, b)
        if a.filterFavorite170 ~= b.filterFavorite170 then return a.filterFavorite170 and true or false end
        if sortKey == "ONLINE" and a.filterHasOnline153 ~= b.filterHasOnline153 then return a.filterHasOnline153 and true or false end
        if sortKey == "LEVEL" and (a.filterLevel170 or 0) ~= (b.filterLevel170 or 0) then return (a.filterLevel170 or 0) > (b.filterLevel170 or 0) end
        if sortKey == "RARITY" and (a.filterQuality153 or 0) ~= (b.filterQuality153 or 0) then return (a.filterQuality153 or 0) > (b.filterQuality153 or 0) end
        if sortKey == "RECENT" then
            local at = a.crafters and a.crafters[1] and a.crafters[1].ts or 0
            local bt = b.crafters and b.crafters[1] and b.crafters[1].ts or 0
            if at ~= bt then return at > bt end
        end
        if sortKey == "CRAFTERS" and table.getn(a.crafters or {}) ~= table.getn(b.crafters or {}) then return table.getn(a.crafters or {}) > table.getn(b.crafters or {}) end
        return string.lower(a.recipe and a.recipe.name or "") < string.lower(b.recipe and b.recipe.name or "")
    end)
    return filtered
end

function OTLGM:BuildRecipesPanel(page)
    BaseBuildRecipesPanel153(self, page)
    local recipes = self.ui.craftingSearchEdit and self.ui.craftingSearchEdit:GetParent()
    local filters = self.ui.craftingProfessionButtons and self.ui.craftingProfessionButtons.ALL and self.ui.craftingProfessionButtons.ALL:GetParent()
    if not recipes or not filters then return end

    self.ui.craftingCategoryPrev153 = NButton(recipes, "<", 10, -48, 24, 26, function()
        OTLGM.ui.craftingCategoryOffset153 = math.max(0, (OTLGM.ui.craftingCategoryOffset153 or 0) - 1)
        OTLGM:RefreshProfessionsPage()
    end, "utility")
    self.ui.craftingCategoryButtons153 = {}
    local i
    for i = 1, 4 do
        local captured = i
        self.ui.craftingCategoryButtons153[i] = NButton(recipes, "All", 38 + ((i - 1) * 60), -48, 56, 26, function()
            local button = OTLGM.ui.craftingCategoryButtons153[captured]
            if button and button.categoryKey153 then
                OTLGM_DB.settings.craftingCategory153 = button.categoryKey153
                OTLGM.ui.craftingRecipeOffset = 0
                OTLGM.ui.craftingSelectedRecipe = nil
                OTLGM:RefreshProfessionsPage()
            end
        end, "normal")
    end
    self.ui.craftingCategoryNext153 = NButton(recipes, ">", 280, -48, 34, 26, function()
        OTLGM.ui.craftingCategoryOffset153 = (OTLGM.ui.craftingCategoryOffset153 or 0) + 1
        OTLGM:RefreshProfessionsPage()
    end, "utility")

    self.ui.craftingLevelFilter153 = NButton(recipes, "Level: Any", 10, -78, 76, 26, function()
        NCycleSetting153("craftingLevelFilter153", (OTLGM_DB.settings.craftingLevelBasis170 == "SKILL") and skillFilters170 or levelFilters153)
        OTLGM.ui.craftingRecipeOffset = 0
        OTLGM:RefreshProfessionsPage()
    end, "utility")
    self.ui.craftingRarityFilter153 = NButton(recipes, "Rarity: Any", 90, -78, 76, 26, function()
        NCycleSetting153("craftingRarityFilter153", rarityFilters153)
        OTLGM.ui.craftingRecipeOffset = 0
        OTLGM:RefreshProfessionsPage()
    end, "utility")
    self.ui.craftingSortFilter153 = NButton(recipes, "Sort: Online", 170, -78, 84, 26, function()
        NCycleSetting153("craftingSort153", sortFilters153)
        OTLGM.ui.craftingRecipeOffset = 0
        OTLGM:RefreshProfessionsPage()
    end, "utility")
    self.ui.craftingOnlineFilter153 = NButton(recipes, "Online: All", 258, -78, 56, 26, function()
        OTLGM_DB.settings.craftingOnlineOnly153 = not OTLGM_DB.settings.craftingOnlineOnly153
        OTLGM.ui.craftingRecipeOffset = 0
        OTLGM:RefreshProfessionsPage()
    end, "confirm")

    for i = 1, table.getn(self.ui.craftingRecipeRows or {}) do
        self.ui.craftingRecipeRows[i]:ClearAllPoints()
        self.ui.craftingRecipeRows[i]:SetPoint("TOPLEFT", recipes, "TOPLEFT", 10, -110 - ((i - 1) * 32))
        if not self.ui.craftingRecipeRows[i].levelText170 then
            local row = self.ui.craftingRecipeRows[i]
            row.nameText:SetWidth(152)
            row.countText:ClearAllPoints()
            row.countText:SetPoint("TOPRIGHT", row, "TOPRIGHT", -6, -7)
            row.countText:SetWidth(62)
            row.levelText170 = NText(row, "GameFontNormalSmall", "", 188, -7, 48, "RIGHT")
            row.levelText170:SetTextColor(0.95, 0.72, 0.24)
        end
    end

    for i = 1, table.getn(self.ui.craftingRecentRows152 or {}) do self.ui.craftingRecentRows152[i]:Hide() end
    if self.ui.craftingRecentEmpty152 then self.ui.craftingRecentEmpty152:Hide() end
    self.ui.craftingActivityButton153 = NButton(filters, "Open Full Activity", 8, -320, 138, 28, function()
        OTLGM:OpenActivityDialog153("CRAFTING", "ALL")
    end, "utility")
    self.ui.craftingActivitySummary153 = NWrapped(filters, "GameFontNormalSmall", "No recent crafting activity.", 10, -354, 134, 46)
    self.ui.craftingActivitySummary153:SetTextColor(0.58, 0.58, 0.56)
end

local function NRefreshCategoryControls153(self)
    local profession = OTLGM_DB.settings.craftingProfession or "ALL"
    local definitions = self:GetCraftingCategoryDefinitions153(profession)
    local selected = OTLGM_DB.settings.craftingCategory153 or "ALL"
    local selectedValid = false
    local i
    for i = 1, table.getn(definitions) do if definitions[i][1] == selected then selectedValid = true break end end
    if not selectedValid then selected = "ALL" OTLGM_DB.settings.craftingCategory153 = "ALL" end

    local offset = math.max(0, self.ui.craftingCategoryOffset153 or 0)
    local maximum = math.max(0, table.getn(definitions) - 4)
    if offset > maximum then offset = maximum end
    for i = 1, table.getn(definitions) do
        if definitions[i][1] == selected and (i - 1 < offset or i > offset + 4) then offset = math.max(0, math.min(maximum, i - 2)) break end
    end
    self.ui.craftingCategoryOffset153 = offset
    for i = 1, 4 do
        local button = self.ui.craftingCategoryButtons153[i]
        local definition = definitions[offset + i]
        if definition then
            button.categoryKey153 = definition[1]
            NSetButtonText(button, NShort(definition[2], 10))
            NSetSelected(button, definition[1] == selected)
            button:Show()
        else button.categoryKey153 = nil button:Hide() end
    end
    NSetEnabled(self.ui.craftingCategoryPrev153, offset > 0, "The first category group is already visible.")
    NSetEnabled(self.ui.craftingCategoryNext153, offset < maximum, "There are no more categories.")
    local levelDefinitions = OTLGM_DB.settings.craftingLevelBasis170 == "SKILL" and skillFilters170 or levelFilters153
    NSetButtonText(self.ui.craftingLevelFilter153, NFilterLabel153(levelDefinitions, OTLGM_DB.settings.craftingLevelFilter153 or "ANY"))
    NSetButtonText(self.ui.craftingRarityFilter153, NFilterLabel153(rarityFilters153, OTLGM_DB.settings.craftingRarityFilter153 or "ANY"))
    NSetButtonText(self.ui.craftingSortFilter153, NFilterLabel153(sortFilters153, OTLGM_DB.settings.craftingSort153 or "ONLINE"))
    NSetButtonText(self.ui.craftingOnlineFilter153, OTLGM_DB.settings.craftingOnlineOnly153 and "Online: Only" or "Online: All")
    NSetSelected(self.ui.craftingOnlineFilter153, OTLGM_DB.settings.craftingOnlineOnly153 and true or false)
end

function OTLGM:_Stage_UINext_RefreshCraftingRecipesPanel_2(summary)
    self.craftingFilterContext153 = true
    BaseRefreshCraftingRecipesPanel153(self, summary)
    self.craftingFilterContext153 = nil
    if self.ui.craftingCategoryButtons153 then NRefreshCategoryControls153(self) end
    local craft = self:EnsureCraftingDB()
    local eventCount = table.getn(craft and craft.events or {})
    if self.ui.craftingActivitySummary153 then
        if eventCount == 0 then self.ui.craftingActivitySummary153:SetText("No recent crafting activity. Open a profession window to share recipes.")
        else self.ui.craftingActivitySummary153:SetText(tostring(eventCount) .. " recent event" .. (eventCount == 1 and "" or "s") .. ". Open the full activity window to read details.") end
    end
    local basis = OTLGM_DB.settings.craftingLevelBasis170 or "ITEM"
    local i, row, recipe, value
    for i = 1, table.getn(self.ui.craftingRecipeRows or {}) do
        row = self.ui.craftingRecipeRows[i]
        recipe = row.recipeData and row.recipeData.recipe
        if row.levelText170 then
            if basis == "REQUIRED" then value = tonumber(row.recipeData and row.recipeData.filterRequiredLevel153) or tonumber(recipe and recipe.requiredLevel) or 0
            elseif basis == "SKILL" then value = tonumber(row.recipeData and row.recipeData.filterRequiredSkill170) or tonumber(recipe and recipe.requiredSkill) or 0
            else value = tonumber(row.recipeData and row.recipeData.filterItemLevel153) or tonumber(recipe and recipe.itemLevel) or 0 end
            local prefix = basis == "SKILL" and "S" or basis == "REQUIRED" and "L" or "i"
            row.levelText170:SetText(value > 0 and (prefix .. tostring(value)) or "")
        end
    end
    local selected = self.ui.craftingSelectedRecipeData
    if selected and selected.recipe and self.ui.craftingRecipeMeta then
        local itemLevel = tonumber(selected.recipe.itemLevel) or 0
        local requiredLevel = tonumber(selected.recipe.requiredLevel) or 0
        local requiredSkill = tonumber(selected.recipe.requiredSkill) or 0
        local crafterCount = table.getn(selected.crafters or {})
        local levels = {}
        if itemLevel > 0 then table.insert(levels, "iLvl " .. tostring(itemLevel)) end
        if requiredLevel > 0 then table.insert(levels, "Use " .. tostring(requiredLevel)) end
        if requiredSkill > 0 then table.insert(levels, "Skill " .. tostring(requiredSkill)) end
        local firstLine = (selected.professionLabel or "Profession") .. "  -  " .. tostring(crafterCount) .. " crafter" .. (crafterCount == 1 and "" or "s")
        self.ui.craftingRecipeMeta:SetText(firstLine .. (table.getn(levels) > 0 and "\n" .. table.concat(levels, "  -  ") or ""))
    end
    for i = 1, table.getn(self.ui.craftingRecentRows152 or {}) do self.ui.craftingRecentRows152[i]:Hide() end
    if self.ui.craftingRecentEmpty152 then self.ui.craftingRecentEmpty152:Hide() end
end

local activityFilterDefinitions153 = {
    GUILD = { {"ALL", "All"}, {"GROUP", "Groups"}, {"CRAFT", "Crafting"}, {"RESPONSE", "Replies"}, {"REACTION", "Reactions"} },
    CRAFTING = { {"ALL", "All"}, {"RECIPES", "Recipes"}, {"REQUEST", "Requests"}, {"RESPONSE", "Replies"}, {"REACTION", "Reactions"} },
}

local function NActivityMatches153(entry, filter)
    if filter == "ALL" then return true end
    local kind = string.upper(entry.kind or "")
    if filter == "CRAFT" then return kind == "CRAFT" or kind == "RECIPES" or kind == "REQUEST" end
    if filter == "GROUP" then return kind == "GROUP" or kind == "RAID" end
    if filter == "REQUEST" then return kind == "REQUEST" or kind == "CRAFT" end
    if filter == "RESPONSE" then return kind == "RESPONSE" or string.find(kind, "REPLY", 1, true) ~= nil end
    if filter == "REACTION" then return kind == "REACTION" or string.find(kind, "REACT", 1, true) ~= nil end
    return kind == filter
end

function OTLGM:_Stage_UINext_GetActivityEntries153_1(mode, filter)
    local result = {}
    local i, entry
    if mode == "CRAFTING" then
        local craft = self:EnsureCraftingDB()
        for i = 1, table.getn(craft and craft.events or {}) do
            entry = craft.events[i]
            if NActivityMatches153(entry, filter or "ALL") then table.insert(result, entry) end
        end
    else
        local useful = self:GetUsefulActivity152(50)
        for i = 1, table.getn(useful or {}) do
            entry = useful[i]
            if NActivityMatches153(entry, filter or "ALL") then table.insert(result, entry) end
        end
    end
    table.sort(result, function(a, b) return (a.ts or 0) > (b.ts or 0) end)
    while table.getn(result) > 50 do table.remove(result) end
    return result
end

function OTLGM:_Stage_UINext_BuildActivityDialogs153_1()
    if self.ui.activityDialog153 then return end
    local dialog = CreateFrame("Frame", "OTLGM_ActivityDialog153", self.ui.main)
    dialog:SetWidth(700)
    dialog:SetHeight(520)
    dialog:SetPoint("CENTER", self.ui.main, "CENTER", 0, 0)
    dialog.preferredModalStrata153 = "FULLSCREEN_DIALOG"
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetFrameLevel(self.ui.main:GetFrameLevel() + 100)
    NBackdrop(dialog, 8)
    dialog:SetBackdropColor(0.012, 0.011, 0.010, 1)
    dialog:SetBackdropBorderColor(0.90, 0.60, 0.18, 1)
    dialog.titleText = NText(dialog, "GameFontNormalLarge", "Guild Activity", 24, -20, 652, "CENTER")
    dialog.subtitleText = NText(dialog, "GameFontNormalSmall", "Recent useful events", 24, -48, 652, "CENTER")
    dialog.subtitleText:SetTextColor(0.60, 0.60, 0.58)
    dialog.filterButtons = {}
    local i
    for i = 1, 5 do
        local captured = i
        dialog.filterButtons[i] = NButton(dialog, "All", 24 + ((i - 1) * 126), -72, 118, 28, function()
            local button = OTLGM.ui.activityDialog153.filterButtons[captured]
            if button and button.filterKey153 then
                OTLGM.ui.activityDialog153.filter153 = button.filterKey153
                OTLGM.ui.activityDialog153.offset153 = 0
                OTLGM:RefreshActivityDialog153()
            end
        end, "utility")
    end
    dialog.rows = {}
    for i = 1, 10 do
        local captured = i
        local row = NButton(dialog, "", 24, -110 - ((i - 1) * 35), 652, 33, function()
            local selected = OTLGM.ui.activityDialog153.rows[captured].entry153
            if selected and selected.targetPage and selected.targetPage ~= "" then
                OTLGM.ui.activityDialog153:Hide()
                OTLGM:ShowPage(selected.targetPage)
            end
        end, "normal")
        row.text:Hide()
        row.timeText = NText(row, "GameFontNormalSmall", "", 8, -7, 64, "LEFT")
        row.titleText = NText(row, "GameFontNormalSmall", "", 76, -6, 354, "LEFT")
        row.detailText = NText(row, "GameFontHighlightSmall", "", 434, -6, 208, "RIGHT")
        row.kindText = NText(row, "GameFontNormalSmall", "", 76, -19, 354, "LEFT")
        row.kindText:SetTextColor(0.48, 0.48, 0.46)
        row:Hide()
        dialog.rows[i] = row
    end
    dialog.statusText = NText(dialog, "GameFontNormalSmall", "", 24, -466, 380, "LEFT")
    dialog.prevButton = NButton(dialog, "Previous", 430, -462, 76, 28, function()
        OTLGM.ui.activityDialog153.offset153 = math.max(0, (OTLGM.ui.activityDialog153.offset153 or 0) - 10)
        OTLGM:RefreshActivityDialog153()
    end, "utility")
    dialog.nextButton = NButton(dialog, "Next", 514, -462, 68, 28, function()
        OTLGM.ui.activityDialog153.offset153 = (OTLGM.ui.activityDialog153.offset153 or 0) + 10
        OTLGM:RefreshActivityDialog153()
    end, "utility")
    dialog.closeButton = NButton(dialog, "Close", 590, -462, 86, 28, function() OTLGM.ui.activityDialog153:Hide() end, "normal")
    dialog:Hide()
    self.ui.activityDialog153 = dialog
end

function OTLGM:OpenActivityDialog153(mode, filter)
    if not self.ui.activityDialog153 then self:BuildActivityDialogs153() end
    local dialog = self.ui.activityDialog153
    dialog.mode153 = mode == "CRAFTING" and "CRAFTING" or "GUILD"
    dialog.filter153 = filter or "ALL"
    dialog.offset153 = 0
    self:RefreshActivityDialog153()
    if self.ShowModal152 then self:ShowModal152(dialog) else dialog:Show() end
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
end

function OTLGM:_Stage_UINext_RefreshActivityDialog153_1()
    local dialog = self.ui and self.ui.activityDialog153
    if not dialog then return end
    local mode = dialog.mode153 or "GUILD"
    local filter = dialog.filter153 or "ALL"
    local definitions = activityFilterDefinitions153[mode]
    local i, definition
    for i = 1, 5 do
        definition = definitions[i]
        local button = dialog.filterButtons[i]
        button.filterKey153 = definition[1]
        NSetButtonText(button, definition[2])
        NSetSelected(button, definition[1] == filter)
    end
    dialog.titleText:SetText(mode == "CRAFTING" and "Crafting Activity" or "Guild Activity")
    dialog.subtitleText:SetText(mode == "CRAFTING" and "Recipe scans, crafting requests and guild responses" or "Groups, crafting, replies and reactions that may need attention")
    local entries = self:GetActivityEntries153(mode, filter)
    local offset = math.max(0, dialog.offset153 or 0)
    local maximum = math.max(0, table.getn(entries) - 10)
    if offset > maximum then offset = maximum end
    dialog.offset153 = offset
    local row, entry
    for i = 1, 10 do
        row = dialog.rows[i]
        entry = entries[offset + i]
        if entry then
            row.entry153 = entry
            row.timeText:SetText(date("%d %b\n%H:%M", entry.ts or self:Now()))
            row.titleText:SetText(NShort(entry.title or "Guild activity", 52))
            row.detailText:SetText(NShort(entry.detail or "", 31))
            row.kindText:SetText(string.upper(entry.kind or "INFO") .. (entry.targetPage and entry.targetPage ~= "" and "  -  click to open" or ""))
            row:Show()
        else row.entry153 = nil row:Hide() end
    end
    if table.getn(entries) == 0 then dialog.statusText:SetText("No activity matches this filter.")
    else dialog.statusText:SetText(tostring(offset + 1) .. "-" .. tostring(math.min(offset + 10, table.getn(entries))) .. " of " .. tostring(table.getn(entries))) end
    NSetEnabled(dialog.prevButton, offset > 0, "This is the first page.")
    NSetEnabled(dialog.nextButton, offset < maximum, "There are no more activity entries.")
end

function OTLGM:_Stage_UINext_BuildNextUI_2()
    BaseBuildNextUI153(self)
    self:BuildActivityDialogs153()
    if self.RegisterModal152 then self:RegisterModal152(self.ui.activityDialog153) end
    OTLGM.ui153Loaded = true
end

OTLGM:RegisterModule("Pages", { layer = "ui", generation = "1.5" })
