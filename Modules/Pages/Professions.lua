-- Order of the Lion Guild Manager 1.8.0 alpha2 shell r6
-- Fully migrated Professions page: Recipes and Crafting Requests.

if not OTLGM or not OTLGM.UI then return end

local UI = OTLGM.UI
local C = UI.colors
local QUALITY_COLORS = {
    [0] = { 0.62, 0.62, 0.62 },
    [1] = { 0.95, 0.95, 0.95 },
    [2] = { 0.12, 1.00, 0.12 },
    [3] = { 0.20, 0.55, 1.00 },
    [4] = { 0.72, 0.30, 1.00 },
}

local function ApplyQualityColor(label, quality)
    if not label or not label.SetTextColor then return end
    local color = QUALITY_COLORS[tonumber(quality) or 1] or QUALITY_COLORS[1]
    label:SetTextColor(color[1], color[2], color[3])
end
local RECIPE_ROWS = 24
local REQUEST_ROWS = 22
local DEFAULT_RECIPE_ROWS = 12
local DEFAULT_REQUEST_ROWS = 11

local LEVEL_FILTERS = {
    { "ANY", "Any level" }, { "1_20", "Level 1-20" }, { "21_40", "Level 21-40" },
    { "41_60", "Level 41-60" }, { "61_PLUS", "Level 61+" }, { "UNKNOWN", "Unknown level" },
}
local SKILL_FILTERS = {
    { "ANY", "Any skill" }, { "1_75", "Skill 1-75" }, { "76_150", "Skill 76-150" },
    { "151_225", "Skill 151-225" }, { "226_300", "Skill 226-300" }, { "301_PLUS", "Skill 301+" }, { "UNKNOWN", "Unknown skill" },
}
local RARITY_FILTERS = {
    { "ANY", "Any rarity" }, { "COMMON", "Common" }, { "UNCOMMON", "Uncommon" },
    { "RARE", "Rare" }, { "EPIC", "Epic" }, { "UNKNOWN", "Unknown rarity" },
}
local SORT_FILTERS = {
    { "ONLINE", "Online first" }, { "NAME", "Name" }, { "LEVEL", "Level" },
    { "RARITY", "Rarity" }, { "RECENT", "Recently shared" }, { "CRAFTERS", "Crafter count" },
}
local BASIS_FILTERS = { { "ITEM", "Item level" }, { "REQUIRED", "Required level" }, { "SKILL", "Required skill" } }

local CLASS_COORDS = {
    WARRIOR = { 0, 0.25, 0, 0.25 }, MAGE = { 0.25, 0.496, 0, 0.25 },
    ROGUE = { 0.496, 0.742, 0, 0.25 }, DRUID = { 0.742, 0.988, 0, 0.25 },
    HUNTER = { 0, 0.25, 0.25, 0.5 }, SHAMAN = { 0.25, 0.496, 0.25, 0.5 },
    PRIEST = { 0.496, 0.742, 0.25, 0.5 }, WARLOCK = { 0.742, 0.988, 0.25, 0.5 },
    PALADIN = { 0, 0.25, 0.5, 0.75 },
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

local function Label(parent, value, template, x, y, width, justify)
    local label = UI.Text(parent, value, template, justify)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then label:SetWidth(width) end
    return label
end

local function Short(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or 45
    if string.len(value) <= maximum then return value end
    return string.sub(value, 1, math.max(1, maximum - 3)) .. "..."
end

local function RequestStatusText(status)
    status = string.upper(tostring(status or "OPEN"))
    if status == "CLAIMED" then return "Claimed" end
    if status == "COMPLETED" then return "Completed" end
    return "Open"
end

local function MakeEdit(parent, width, height, multiline, maximum)
    return UI:EditBox(parent, width, height, {
        multiline = multiline and true or false,
        maxLetters = maximum or 80,
        fontObject = multiline and "ChatFontNormal" or "GameFontHighlightSmall",
    })
end

local function FindDefinition(definitions, key)
    local index
    for index = 1, table.getn(definitions or {}) do
        if definitions[index][1] == key or definitions[index].key == key then return index, definitions[index] end
    end
    return 1, definitions and definitions[1] or nil
end

local function CycleSetting(owner, settingKey, definitions, direction)
    local current = OTLGM_DB.settings[settingKey]
    local index = FindDefinition(definitions, current)
    index = index + (direction or 1)
    if index > table.getn(definitions) then index = 1 end
    if index < 1 then index = table.getn(definitions) end
    OTLGM_DB.settings[settingKey] = definitions[index][1]
    owner.ui.craftingRecipeOffset = 0
    owner:RefreshProfessionsFiltersDrawer()
    owner:RefreshProfessionsPage()
end

local function DefinitionLabel(definitions, key)
    local _, definition = FindDefinition(definitions, key)
    return definition and (definition[2] or definition.label) or tostring(key or "Any")
end

function OTLGM:SetProfessionsTab(section)
    section = section == "REQUESTS" and "REQUESTS" or "RECIPES"
    OTLGM_DB.settings.craftingSection = section
    self.ui.professionsSection = section
    if section == "RECIPES" then self.ui.professionsRecipesPanel:Show() self.ui.professionsRequestsPanel:Hide()
    else self.ui.professionsRecipesPanel:Hide() self.ui.professionsRequestsPanel:Show() end
    UI:SetSelected(self.ui.professionsRecipesTab, section == "RECIPES")
    UI:SetSelected(self.ui.professionsRequestsTab, section == "REQUESTS")
    if self.MarkCraftingRead then self:MarkCraftingRead(section) end
    self:RefreshProfessionsPage()
end

function OTLGM:BuildProfessionsFiltersDrawer()
    if self.ui.professionsFiltersDrawer then return end
    local drawer = UI:Drawer(self.ui.drawerHost, 420, 576)
    drawer:SetPoint("TOPRIGHT", self.ui.drawerHost, "TOPRIGHT", -10, -10)
    drawer.title = Label(drawer, "Recipe Filters", "GameFontNormalLarge", 18, -18, 300, "LEFT")
    drawer.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    drawer.close = UI:IconButton(drawer, "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 28, 28, function() OTLGM:CloseShellDrawer() end, "Close", "utility")
    drawer.close:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -12, -12)
    drawer.reset = UI:Button(drawer, "Reset", 78, 26, function()
        OTLGM_DB.settings.craftingCategory153 = "ALL"
        OTLGM_DB.settings.craftingLevelFilter153 = "ANY"
        OTLGM_DB.settings.craftingLevelBasis170 = "ITEM"
        OTLGM_DB.settings.craftingRarityFilter153 = "ANY"
        OTLGM_DB.settings.craftingSort153 = "ONLINE"
        OTLGM_DB.settings.craftingOnlineOnly153 = false
        OTLGM_DB.settings.craftingFavoritesOnly170 = false
        OTLGM.ui.craftingRecipeOffset = 0
        OTLGM:RefreshProfessionsFiltersDrawer()
        OTLGM:RefreshProfessionsPage()
    end, "utility")
    drawer.reset:SetPoint("TOPRIGHT", drawer, "TOPRIGHT", -52, -14)

    local function BuildCycle(label, y, width, previous, next)
        Label(drawer, label, "GameFontNormalSmall", 18, y, 160, "LEFT"):SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
        local prev = UI:Button(drawer, "<", 32, 30, previous, "utility")
        prev:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, y - 22)
        local value = UI:Button(drawer, "", width, 30, next, "filter")
        value:SetPoint("LEFT", prev, "RIGHT", 6, 0)
        local nextButton = UI:Button(drawer, ">", 32, 30, next, "utility")
        nextButton:SetPoint("LEFT", value, "RIGHT", 6, 0)
        return value
    end

    drawer.category = BuildCycle("CATEGORY", -64, 250,
        function() OTLGM:CycleProfessionCategoryShell(-1) end,
        function() OTLGM:CycleProfessionCategoryShell(1) end)
    drawer.basis = BuildCycle("LEVEL MEANS", -132, 250,
        function() CycleSetting(OTLGM, "craftingLevelBasis170", BASIS_FILTERS, -1) end,
        function() CycleSetting(OTLGM, "craftingLevelBasis170", BASIS_FILTERS, 1) end)
    drawer.level = BuildCycle("LEVEL OR SKILL", -200, 250,
        function() OTLGM:CycleProfessionLevelShell(-1) end,
        function() OTLGM:CycleProfessionLevelShell(1) end)
    drawer.rarity = BuildCycle("RARITY", -268, 250,
        function() CycleSetting(OTLGM, "craftingRarityFilter153", RARITY_FILTERS, -1) end,
        function() CycleSetting(OTLGM, "craftingRarityFilter153", RARITY_FILTERS, 1) end)
    drawer.sort = BuildCycle("SORT", -336, 250,
        function() CycleSetting(OTLGM, "craftingSort153", SORT_FILTERS, -1) end,
        function() CycleSetting(OTLGM, "craftingSort153", SORT_FILTERS, 1) end)

    drawer.online = UI:FilterChip(drawer, "Online crafters only", 180, function(button)
        OTLGM_DB.settings.craftingOnlineOnly153 = not OTLGM_DB.settings.craftingOnlineOnly153
        UI:SetSelected(button, OTLGM_DB.settings.craftingOnlineOnly153)
        OTLGM.ui.craftingRecipeOffset = 0
        OTLGM:RefreshProfessionsPage()
    end)
    drawer.online:SetPoint("TOPLEFT", drawer, "TOPLEFT", 18, -430)
    drawer.favorites = UI:FilterChip(drawer, "Favorites only", 150, function(button)
        OTLGM_DB.settings.craftingFavoritesOnly170 = not OTLGM_DB.settings.craftingFavoritesOnly170
        UI:SetSelected(button, OTLGM_DB.settings.craftingFavoritesOnly170)
        OTLGM.ui.craftingRecipeOffset = 0
        OTLGM:RefreshProfessionsPage()
    end)
    drawer.favorites:SetPoint("LEFT", drawer.online, "RIGHT", 8, 0)
    drawer.help = Label(drawer, "Filters always apply to the local recipe cache, even while guild sync is waiting.", "GameFontNormalSmall", 18, -480, 380, "LEFT")
    drawer.help:SetHeight(46)
    drawer.help:SetJustifyV("TOP")
    drawer.help:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    self.ui.professionsFiltersDrawer = drawer
end

function OTLGM:CycleProfessionCategoryShell(direction)
    local profession = self.ui.craftingProfessionFilterShell or "ALL"
    local definitions = self.GetCraftingCategoryDefinitions153 and self:GetCraftingCategoryDefinitions153(profession) or { { "ALL", "All" } }
    local current = OTLGM_DB.settings.craftingCategory153 or "ALL"
    local index = FindDefinition(definitions, current)
    index = index + (direction or 1)
    if index > table.getn(definitions) then index = 1 end
    if index < 1 then index = table.getn(definitions) end
    OTLGM_DB.settings.craftingCategory153 = definitions[index][1]
    self.ui.craftingRecipeOffset = 0
    self:RefreshProfessionsFiltersDrawer()
    self:RefreshProfessionsPage()
end

function OTLGM:CycleProfessionLevelShell(direction)
    local definitions = OTLGM_DB.settings.craftingLevelBasis170 == "SKILL" and SKILL_FILTERS or LEVEL_FILTERS
    CycleSetting(self, "craftingLevelFilter153", definitions, direction)
end

function OTLGM:RefreshProfessionsFiltersDrawer()
    local drawer = self.ui and self.ui.professionsFiltersDrawer
    if not drawer then return end
    local profession = self.ui.craftingProfessionFilterShell or "ALL"
    local categories = self.GetCraftingCategoryDefinitions153 and self:GetCraftingCategoryDefinitions153(profession) or { { "ALL", "All" } }
    local category = OTLGM_DB.settings.craftingCategory153 or "ALL"
    local _, categoryDefinition = FindDefinition(categories, category)
    if not categoryDefinition then category = "ALL" OTLGM_DB.settings.craftingCategory153 = "ALL" end
    UI:SetText(drawer.category, DefinitionLabel(categories, category))
    UI:SetText(drawer.basis, DefinitionLabel(BASIS_FILTERS, OTLGM_DB.settings.craftingLevelBasis170 or "ITEM"))
    local levelDefinitions = OTLGM_DB.settings.craftingLevelBasis170 == "SKILL" and SKILL_FILTERS or LEVEL_FILTERS
    UI:SetText(drawer.level, DefinitionLabel(levelDefinitions, OTLGM_DB.settings.craftingLevelFilter153 or "ANY"))
    UI:SetText(drawer.rarity, DefinitionLabel(RARITY_FILTERS, OTLGM_DB.settings.craftingRarityFilter153 or "ANY"))
    UI:SetText(drawer.sort, DefinitionLabel(SORT_FILTERS, OTLGM_DB.settings.craftingSort153 or "ONLINE"))
    UI:SetSelected(drawer.online, OTLGM_DB.settings.craftingOnlineOnly153 and true or false)
    UI:SetSelected(drawer.favorites, OTLGM_DB.settings.craftingFavoritesOnly170 and true or false)
end

function OTLGM:OpenProfessionsFiltersDrawer()
    self:BuildProfessionsFiltersDrawer()
    self:RefreshProfessionsFiltersDrawer()
    self:ShowShellDrawer(self.ui.professionsFiltersDrawer)
end

function OTLGM:ScrollCraftingCrafters180(lines)
    local details = self.ui and self.ui.recipeDetails
    local result = details and details.otlResult
    if not details or not result then return end
    local maximum = math.max(0, table.getn(result.crafters or {}) - table.getn(details.crafters or {}))
    details.crafterOffset = math.max(0, math.min(maximum, (tonumber(details.crafterOffset) or 0) + (tonumber(lines) or 0)))
    self:RefreshProfessionsPage()
end

local function BuildRecipePanels(owner, page)
    local panel = CreateFrame("Frame", nil, page)
    panel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -40)
    panel:SetWidth(932)
    panel:SetHeight(548)
    owner.ui.professionsRecipesPanel = panel

    owner.ui.craftingSearchEdit = UI:SearchBox(panel, 300, 30, "Search recipes, items or reagents...", function()
        owner.ui.craftingRecipeOffset = 0
        owner:RefreshProfessionsPage()
    end)
    owner.ui.craftingSearchEdit:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    owner.ui.craftingFavoriteFilter = UI:FilterChip(panel, "Favorites", 112, function(button)
        OTLGM_DB.settings.craftingFavoritesOnly170 = not OTLGM_DB.settings.craftingFavoritesOnly170
        UI:SetSelected(button, OTLGM_DB.settings.craftingFavoritesOnly170)
        owner.ui.craftingRecipeOffset = 0
        owner:RefreshProfessionsPage()
    end)
    owner.ui.craftingFavoriteFilter:SetPoint("LEFT", owner.ui.craftingSearchEdit, "RIGHT", 8, 0)
    owner.ui.craftingFavoriteFilter.icon = owner.ui.craftingFavoriteFilter:CreateTexture(nil, "ARTWORK")
    owner.ui.craftingFavoriteFilter.icon:SetTexture("Interface\\COMMON\\ReputationStar")
    owner.ui.craftingFavoriteFilter.icon:SetWidth(14) owner.ui.craftingFavoriteFilter.icon:SetHeight(14)
    owner.ui.craftingFavoriteFilter.icon:SetPoint("LEFT", owner.ui.craftingFavoriteFilter, "LEFT", 7, 0)
    owner.ui.craftingOnlineFirst = UI:FilterChip(panel, "Online First", 118, function(button)
        OTLGM_DB.settings.craftingSort153 = OTLGM_DB.settings.craftingSort153 == "ONLINE" and "NAME" or "ONLINE"
        UI:SetSelected(button, OTLGM_DB.settings.craftingSort153 == "ONLINE")
        owner:RefreshProfessionsPage()
    end)
    owner.ui.craftingOnlineFirst:SetPoint("LEFT", owner.ui.craftingFavoriteFilter, "RIGHT", 8, 0)
    owner.ui.craftingFilters = UI:Button(panel, "Filters", 90, 30, function() owner:OpenProfessionsFiltersDrawer() end, "secondary")
    owner.ui.craftingFilters:SetPoint("LEFT", owner.ui.craftingOnlineFirst, "RIGHT", 8, 0)
    owner.ui.craftingStateText = Label(panel, "", "GameFontNormalSmall", 648, -9, 154, "RIGHT")
    owner.ui.craftingStateText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    owner.ui.craftingUpdate = UI:Button(panel, "Update guild", 122, 30, function()
        if owner:RequestCraftingSync(true, true) and owner.ShowToast then owner:ShowToast("Synchronizing professions…", "pending") end
        owner:RefreshProfessionsPage()
    end, "utility")
    owner.ui.craftingUpdate:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)

    -- Live correction gives profession names more room while retaining three columns.
    local professions = UI:Card(panel, 180, 508, "Professions")
    professions:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -40)
    local recipes = UI:Card(panel, 416, 508, "Recipes")
    recipes:SetPoint("TOPLEFT", panel, "TOPLEFT", 186, -40)
    local details = UI:DetailsPanel(panel, 322, 508, "Recipe Details")
    details:SetPoint("TOPLEFT", panel, "TOPLEFT", 610, -40)
    professions.otlColumnPercent = 20
    recipes.otlColumnPercent = 45
    details.otlColumnPercent = 35
    owner.ui.professionColumn = professions
    owner.ui.recipeColumn = recipes
    owner.ui.recipeDetails = details

    professions.rows = {}
    local definitions = owner:GetCraftingProfessionDefinitions()
    local index
    for index = 1, table.getn(definitions) do
        local captured = index
        local definition = definitions[captured]
        local row = UI:TableRow(professions, 156, 34, function(button)
            owner.ui.craftingProfessionFilterShell = button.otlProfessionKey
            OTLGM_DB.settings.craftingCategory153 = "ALL"
            owner.ui.craftingRecipeOffset = 0
            owner.ui.craftingSelectedRecipeKey = nil
            details.crafterOffset = 0
            owner:RefreshProfessionsPage()
        end)
        row:SetPoint("TOPLEFT", professions, "TOPLEFT", 12, -32 - ((captured - 1) * 39))
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetTexture(definition.icon)
        row.icon:SetWidth(20) row.icon:SetHeight(20) row.icon:SetPoint("LEFT", row, "LEFT", 5, 0)
        local displayLabel = string.find(string.lower(definition.label or ""), "mining", 1, true) and "Mining" or definition.label
        row.nameText = Label(row, displayLabel, "GameFontNormalSmall", 30, -7, 78, "LEFT")
        row.countText = Label(row, "0", "GameFontNormalSmall", 110, -7, 42, "RIGHT")
        row.countText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        row.otlProfessionKey = definition.key
        row.otlTooltipTitle = definition.label
        row.otlTooltip = displayLabel ~= definition.label and definition.label or "Show recipes for this profession."
        professions.rows[captured] = row
    end
    professions.scroll = UI:Scrollbar(professions, 300, function(value)
        owner.ui.craftingProfessionOffset180 = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
        owner:RefreshProfessionsPage()
    end)
    professions.scroll:SetPoint("TOPRIGHT", professions, "TOPRIGHT", -6, -32)
    professions:EnableMouseWheel(true)
    professions:SetScript("OnMouseWheel", function()
        local visible = owner.ui.craftingProfessionVisibleRows180 or 10
        local maximum = math.max(0, table.getn(owner:GetCraftingProfessionDefinitions() or {}) - visible)
        owner.ui.craftingProfessionOffset180 = math.max(0, math.min(maximum, (owner.ui.craftingProfessionOffset180 or 0) - (tonumber(arg1) or 0)))
        owner:RefreshProfessionsPage()
    end)

    recipes.rows = {}
    for index = 1, RECIPE_ROWS do
        local captured = index
        local row = UI:TableRow(recipes, 392, 32, function(button)
            if button.otlResultKey then
                owner.ui.craftingSelectedRecipeKey = button.otlResultKey
                details.crafterOffset = 0
                owner:RefreshProfessionsPage()
            end
        end)
        row:SetPoint("TOPLEFT", recipes, "TOPLEFT", 12, -32 - ((captured - 1) * 34))
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetWidth(22) row.icon:SetHeight(22) row.icon:SetPoint("LEFT", row, "LEFT", 5, 0)
        row.favoriteIcon = row:CreateTexture(nil, "ARTWORK")
        row.favoriteIcon:SetTexture("Interface\\COMMON\\ReputationStar")
        row.favoriteIcon:SetWidth(14) row.favoriteIcon:SetHeight(14)
        row.favoriteIcon:SetPoint("LEFT", row, "LEFT", 258, 0)
        row.favoriteIcon:Hide()
        row.nameText = Label(row, "", "GameFontNormalSmall", 34, -6, 218, "LEFT")
        row.crafterText = Label(row, "", "GameFontNormalSmall", 270, -6, 112, "RIGHT")
        row.crafterText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        row:SetScript("OnEnter", function()
            this.otlHovered = true
            if this.otlResult and owner.ShowCraftingResultTooltip then owner:ShowCraftingResultTooltip(this, this.otlResult) end
        end)
        row:SetScript("OnLeave", function() this.otlHovered = nil if GameTooltip then GameTooltip:Hide() end end)
        row:Hide()
        recipes.rows[captured] = row
    end
    recipes.empty = UI:EmptyState(recipes, 344, 130, "No recipes match", "Try another profession, clear filters, or keep using local data while the guild update waits.")
    recipes.empty:SetPoint("CENTER", recipes, "CENTER", 0, 0)
    recipes.empty:Hide()
    recipes.previous = UI:Button(recipes, "Previous", 78, 25, function() end, "utility")
    recipes.next = UI:Button(recipes, "Next", 70, 25, function() end, "utility")
    recipes.previous:Hide()
    recipes.next:Hide()
    recipes.pageText = Label(recipes, "", "GameFontNormalSmall", 12, -482, 250, "LEFT")
    recipes.pageText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    recipes.scroll = UI:Scrollbar(recipes, 360, function(value)
        owner.ui.craftingRecipeOffset = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
        owner:RefreshProfessionsPage()
    end)
    recipes.scroll:SetPoint("TOPRIGHT", recipes, "TOPRIGHT", -6, -32)
    recipes:EnableMouseWheel(true)
    recipes:SetScript("OnMouseWheel", function()
        local visible = owner.ui.craftingRecipeVisibleRows180 or DEFAULT_RECIPE_ROWS
        local query = owner.ui.craftingSearchEdit:GetText() or ""
        owner.craftingFilterContext153 = true
        local ok, results = pcall(function() return owner:GetCraftingSearchResults(query, owner.ui.craftingProfessionFilterShell or "ALL") end)
        owner.craftingFilterContext153 = nil
        local maximum = ok and math.max(0, table.getn(results or {}) - visible) or 0
        owner.ui.craftingRecipeOffset = math.max(0, math.min(maximum, (owner.ui.craftingRecipeOffset or 0) - ((tonumber(arg1) or 0) * 3)))
        owner:RefreshProfessionsPage()
    end)

    details.iconButton = UI:IconButton(details, "Interface\\Icons\\INV_Misc_QuestionMark", 46, 46, function(button)
        if button.otlResult then owner:ShowCraftingResultTooltip(button, button.otlResult) end
    end, "Item details", "inline")
    details.iconButton:SetPoint("TOPLEFT", details, "TOPLEFT", 12, -32)
    details.titleText = Label(details, "", "GameFontNormal", 68, -34, 238, "LEFT")
    details.titleText:SetHeight(38)
    details.titleText:SetJustifyV("TOP")
    details.metaText = Label(details, "", "GameFontNormalSmall", 68, -75, 238, "LEFT")
    details.metaText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    details.effectTitle = Label(details, "ENCHANT EFFECT", "GameFontNormalSmall", 12, -104, 150, "LEFT")
    details.effectTitle:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    details.effectText = Label(details, "", "GameFontHighlightSmall", 12, -124, 298, "LEFT")
    details.effectText:SetHeight(42)
    details.effectText:SetJustifyV("TOP")
    details.effectTitle:Hide() details.effectText:Hide()
    details.favorite = UI:Button(details, "Favorite", 120, 26, function(button)
        if button.otlResult then owner:ToggleCraftingFavorite170(button.otlResult) end
    end, "secondary")
    details.favorite:SetPoint("TOPLEFT", details, "TOPLEFT", 12, -398)
    details.favorite.icon = details.favorite:CreateTexture(nil, "ARTWORK")
    details.favorite.icon:SetTexture("Interface\\COMMON\\ReputationStar")
    details.favorite.icon:SetWidth(14) details.favorite.icon:SetHeight(14) details.favorite.icon:SetPoint("LEFT", details.favorite, "LEFT", 7, 0)
    details.request = UI:Button(details, "Request This Craft", 170, 26, function(button)
        local result = button.otlResult
        owner:OpenCraftingRequestEditor(result)
    end, "primary")
    details.request:SetPoint("LEFT", details.favorite, "RIGHT", 8, 0)
    details.whisper = UI:Button(details, "Whisper", 96, 26, function()
        if details.otlCrafter then owner:WhisperMember(details.otlCrafter.name) end
    end, "secondary")
    details.whisper:SetPoint("TOPLEFT", details, "TOPLEFT", 12, -430)
    details.invite = UI:Button(details, "Invite", 84, 26, function()
        if details.otlCrafter then owner:InviteMemberToGroup(details.otlCrafter.name) end
    end, "secondary")
    details.invite:SetPoint("LEFT", details.whisper, "RIGHT", 8, 0)
    details.reagentsTitle = Label(details, "REAGENTS", "GameFontNormalSmall", 12, -104, 130, "LEFT")
    details.reagentsTitle:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    details.reagents = {}
    for index = 1, 5 do
        local captured = index
        local row = UI:TableRow(details, 298, 27, function(button)
            if button.otlReagent then owner:ShowCraftingObjectTooltip(button, button.otlReagent, button.otlProfessionKey) end
        end)
        row:SetPoint("TOPLEFT", details, "TOPLEFT", 12, -124 - ((captured - 1) * 28))
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetWidth(18) row.icon:SetHeight(18) row.icon:SetPoint("LEFT", row, "LEFT", 5, 0)
        row.nameText = Label(row, "", "GameFontNormalSmall", 29, -6, 258, "LEFT")
        row:SetScript("OnEnter", function() if this.otlReagent then owner:ShowCraftingObjectTooltip(this, this.otlReagent, this.otlProfessionKey) end end)
        row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        row:Hide()
        details.reagents[captured] = row
    end
    details.reagentEmpty = Label(details, "", "GameFontNormalSmall", 12, -124, 298, "LEFT")
    details.reagentEmpty:SetHeight(46)
    details.reagentEmpty:SetJustifyV("TOP")
    details.reagentEmpty:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    details.reagentEmpty:Hide()
    details.craftersTitle = Label(details, "GUILD CRAFTERS", "GameFontNormalSmall", 12, -270, 150, "LEFT")
    details.craftersTitle:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    details.crafters = {}
    for index = 1, 4 do
        local captured = index
        local row = UI:TableRow(details, 298, 29, function(button)
            if button.otlCrafter then
                details.otlCrafter = button.otlCrafter
                if arg1 == "RightButton" then owner:OpenPlayerMenu(button.otlCrafter.name, button) end
                owner:RefreshProfessionsPage()
            end
        end)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetPoint("TOPLEFT", details, "TOPLEFT", 12, -290 - ((captured - 1) * 29))
        row.classIcon = row:CreateTexture(nil, "ARTWORK")
        row.classIcon:SetWidth(18)
        row.classIcon:SetHeight(18)
        row.classIcon:SetPoint("LEFT", row, "LEFT", 5, 0)
        row.nameText = Label(row, "", "GameFontNormalSmall", 28, -7, 122, "LEFT")
        row.statusText = Label(row, "", "GameFontNormalSmall", 154, -7, 134, "RIGHT")
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function() owner:ScrollCraftingCrafters180(-((tonumber(arg1) or 0) * 2)) end)
        row:Hide()
        details.crafters[captured] = row
    end
    details.crafterScroll = UI:Scrollbar(details, 108, function(value)
        details.crafterOffset = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
        owner:RefreshProfessionsPage()
    end)
    details.crafterScroll:SetPoint("TOPRIGHT", details, "TOPRIGHT", -7, -290)
    details.crafterScroll:Hide()
    details.crafterEmpty = Label(details, "No guild crafters are cached for this recipe.", "GameFontNormalSmall", 12, -292, 286, "LEFT")
    details.crafterEmpty:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    details.crafterEmpty:Hide()
    details.actionsTitle = Label(details, "ACTIONS", "GameFontNormalSmall", 12, -378, 150, "LEFT")
    details.actionsTitle:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    details.crafterOffset = 0
    details:EnableMouse(true)
    details:EnableMouseWheel(true)
    details.otlMouseWheelOwner = true
    details:SetScript("OnMouseWheel", function() owner:ScrollCraftingCrafters180(-((tonumber(arg1) or 0) * 2)) end)
    details.empty = UI:EmptyState(details, 286, 150, "Select a recipe", "Choose a recipe to see materials, crafters and freshness.")
    details.empty:SetPoint("CENTER", details, "CENTER", 0, 10)
    owner.ui.craftingProfessionFilterShell = "ALL"
    owner.ui.craftingRecipeOffset = 0
end

function OTLGM:BuildCraftingRequestEditor()
    if self.ui.craftingRequestEditorShell then return end
    local modal = UI:Modal(self.ui.modalHost, 620, 520)
    modal:SetPoint("CENTER", self.ui.modalHost, "CENTER", 0, 0)
    modal.title = Label(modal, "New Crafting Request", "GameFontNormalLarge", 20, -18, 500, "LEFT")
    modal.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])

    modal.selectionCard = UI:Card(modal, 580, 136, "Selected Craft")
    modal.selectionCard:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -52)
    modal.selectionCard.icon = modal.selectionCard:CreateTexture(nil, "ARTWORK")
    modal.selectionCard.icon:SetWidth(36) modal.selectionCard.icon:SetHeight(36)
    modal.selectionCard.icon:SetPoint("TOPLEFT", modal.selectionCard, "TOPLEFT", 12, -30)
    modal.selectionCard.itemText = Label(modal.selectionCard, "", "GameFontNormal", 58, -30, 390, "LEFT")
    modal.selectionCard.recipeText = Label(modal.selectionCard, "", "GameFontNormalSmall", 58, -52, 390, "LEFT")
    modal.selectionCard.recipeText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.selectionCard.metaText = Label(modal.selectionCard, "", "GameFontNormalSmall", 58, -72, 390, "LEFT")
    modal.selectionCard.metaText:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    modal.selectionCard.reagentsText = Label(modal.selectionCard, "", "GameFontHighlightSmall", 12, -94, 548, "LEFT")
    modal.selectionCard.reagentsText:SetHeight(34)
    modal.selectionCard.reagentsText:SetJustifyV("TOP")
    modal.selectionCard.clear = UI:Button(modal.selectionCard, "Clear Selection", 114, 26, function()
        self:SetCraftingRequestEditorSelection180(nil)
        modal.item:SetFocus()
    end, "secondary")
    modal.selectionCard.clear:SetPoint("TOPRIGHT", modal.selectionCard, "TOPRIGHT", -10, -30)

    modal.itemLabel = Label(modal, "ITEM, RECIPE OR SERVICE", "GameFontNormalSmall", 20, -58, 240, "LEFT")
    modal.itemLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    modal.item = MakeEdit(modal, 580, 34, false, 52)
    modal.item:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -78)

    modal.kindLabel = Label(modal, "REQUEST TYPE", "GameFontNormalSmall", 20, -206, 160, "LEFT")
    modal.kindLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    modal.kind = "CRAFT"
    modal.kindButton = UI:Button(modal, "Craft", 130, 28, function(button)
        local values = { { "CRAFT", "Craft" }, { "ENCHANT", "Enchant" }, { "TRANSMUTE", "Transmute" }, { "GEM", "Gem" } }
        local index = FindDefinition(values, modal.kind)
        index = math.mod(index, table.getn(values)) + 1
        modal.kind = values[index][1]
        UI:SetText(button, values[index][2])
    end, "filter")
    modal.kindButton:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -228)
    modal.materials = "READY"
    modal.materialsButton = UI:Button(modal, "Materials ready", 180, 28, function(button)
        local values = { { "READY", "Materials ready" }, { "NEEDED", "Materials needed" }, { "DISCUSS", "Discuss materials" } }
        local index = FindDefinition(values, modal.materials)
        index = math.mod(index, table.getn(values)) + 1
        modal.materials = values[index][1]
        UI:SetText(button, values[index][2])
    end, "filter")
    modal.materialsButton:SetPoint("LEFT", modal.kindButton, "RIGHT", 8, 0)
    modal.noteLabel = Label(modal, "NOTE", "GameFontNormalSmall", 20, -274, 120, "LEFT")
    modal.noteLabel:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    modal.note = MakeEdit(modal, 580, 112, true, 120)
    modal.note:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -294)
    modal.validation = Label(modal, "", "GameFontNormalSmall", 20, -420, 420, "LEFT")
    modal.validation:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.cancel = UI:Button(modal, "Cancel", 100, 30, function() self:CloseShellModal() end, "secondary")
    modal.cancel:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -138, 18)
    modal.publish = UI:Button(modal, "Post Request", 112, 30, function()
        local identity = modal.requestIdentity180
        local item = identity and identity.displayName or (modal.item:GetText() or "")
        local ok, result = self:CreateCraftingRequest(modal.kind, item, modal.materials, modal.note:GetText() or "", identity)
        if not ok then
            modal.validation:SetText(tostring(result or "The request could not be posted."))
            modal.validation:SetTextColor(C.red[1], C.red[2], C.red[3])
            return
        end
        self.ui.craftingSelectedRequestShell = result.id
        self.ui.craftingFocusRequest180 = result.id
        self:CloseShellModal()
        self:ShowToast("Crafting request posted.", "success")
        self:SetProfessionsTab("REQUESTS")
    end, "primary")
    modal.publish:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -18, 18)
    self.ui.craftingRequestEditorShell = modal
end

function OTLGM:SetCraftingRequestEditorSelection180(result)
    self:BuildCraftingRequestEditor()
    local modal = self.ui.craftingRequestEditorShell
    local identity = type(result) == "table" and self:BuildCraftingRequestIdentity180(result) or nil
    modal.requestIdentity180 = identity
    if identity then
        modal.selectionCard.itemText:SetText(identity.displayName or identity.recipeName or "Selected craft")
        ApplyQualityColor(modal.selectionCard.itemText, identity.itemQuality)
        modal.selectionCard.recipeText:SetText(identity.recipeName and identity.recipeName ~= identity.displayName and ("Recipe: " .. identity.recipeName) or "Recipe-bound request")
        local skill = tonumber(identity.requiredSkill) or 0
        modal.selectionCard.metaText:SetText((identity.professionLabel or identity.professionKey or "Profession") .. (skill > 0 and ("  |  Required skill " .. tostring(skill)) or ""))
        modal.selectionCard.icon:SetTexture(identity.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        local reagents = {}
        local index
        for index = 1, math.min(8, table.getn(identity.reagents or {})) do
            local reagent = identity.reagents[index]
            table.insert(reagents, tostring(reagent.count or 0) .. "x " .. tostring(reagent.name or "Reagent"))
        end
        if table.getn(identity.reagents or {}) > 8 then table.insert(reagents, "+" .. tostring(table.getn(identity.reagents) - 8) .. " more") end
        modal.selectionCard.reagentsText:SetText(table.getn(reagents) > 0 and ("Reagents: " .. table.concat(reagents, ", ")) or "Reagents are not cached; this does not block the request.")
        modal.selectionCard:Show()
        modal.itemLabel:Hide() modal.item:Hide()
        modal.kindLabel:ClearAllPoints() modal.kindLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -206)
        modal.kindButton:ClearAllPoints() modal.kindButton:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -228)
        modal.materialsButton:ClearAllPoints() modal.materialsButton:SetPoint("LEFT", modal.kindButton, "RIGHT", 8, 0)
        modal.noteLabel:ClearAllPoints() modal.noteLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -274)
        modal.note:ClearAllPoints() modal.note:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -294)
    else
        modal.selectionCard:Hide()
        modal.itemLabel:Show() modal.item:Show()
        modal.kindLabel:ClearAllPoints() modal.kindLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -126)
        modal.kindButton:ClearAllPoints() modal.kindButton:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -148)
        modal.materialsButton:ClearAllPoints() modal.materialsButton:SetPoint("LEFT", modal.kindButton, "RIGHT", 8, 0)
        modal.noteLabel:ClearAllPoints() modal.noteLabel:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -194)
        modal.note:ClearAllPoints() modal.note:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -214)
    end
end

function OTLGM:OpenCraftingRequestEditor(itemOrResult)
    self:BuildCraftingRequestEditor()
    local modal = self.ui.craftingRequestEditorShell
    modal.item:SetText(type(itemOrResult) == "string" and itemOrResult or "")
    modal.note:SetText("")
    modal.kind = "CRAFT"
    modal.materials = "READY"
    UI:SetText(modal.kindButton, "Craft")
    UI:SetText(modal.materialsButton, "Materials ready")
    self:SetCraftingRequestEditorSelection180(type(itemOrResult) == "table" and itemOrResult or nil)
    modal.validation:SetText(modal.requestIdentity180 and "The selected item identity is locked to this recipe." or "Generic requests remain available for enchants, transmutes, materials and custom services.")
    modal.validation:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    self:ShowShellModal(modal)
    if modal.requestIdentity180 then modal.note:SetFocus() else modal.item:SetFocus() end
end

function OTLGM:BuildCraftingResponseEditor()
    if self.ui.craftingResponseEditorShell then return end
    local modal = UI:Modal(self.ui.modalHost, 540, 280)
    modal:SetPoint("CENTER", self.ui.modalHost, "CENTER", 0, 0)
    modal.title = Label(modal, "Reply to Crafting Request", "GameFontNormalLarge", 20, -18, 430, "LEFT")
    modal.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    modal.text = MakeEdit(modal, 500, 110, true, 72)
    modal.text:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -62)
    modal.canHelp = UI:FilterChip(modal, "I can help", 118, function(button)
        button.otlValue = not button.otlValue
        UI:SetSelected(button, button.otlValue)
    end)
    modal.canHelp:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -184)
    modal.cancel = UI:Button(modal, "Cancel", 100, 30, function() self:CloseShellModal() end, "secondary")
    modal.cancel:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -138, 18)
    modal.send = UI:Button(modal, "Send", 100, 30, function()
        local ok, problem = self:AddCraftingResponse(modal.requestId, modal.text:GetText() or "", modal.canHelp.otlValue)
        if not ok then self:ShowOperationError(tostring(problem or "The response could not be sent."), function() self:OpenCraftingResponseEditor(modal.requestId) end) return end
        self:CloseShellModal()
        self:ShowToast("Response sent.", "success")
        self:RefreshProfessionsPage()
    end, "primary")
    modal.send:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -18, 18)
    self.ui.craftingResponseEditorShell = modal
end

function OTLGM:OpenCraftingResponseEditor(requestId)
    self:BuildCraftingResponseEditor()
    local modal = self.ui.craftingResponseEditorShell
    modal.requestId = requestId
    modal.text:SetText("")
    modal.canHelp.otlValue = false
    UI:SetSelected(modal.canHelp, false)
    self:ShowShellModal(modal)
    modal.text:SetFocus()
end

local function BuildRequestsPanel(owner, page)
    local panel = CreateFrame("Frame", nil, page)
    panel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -40)
    panel:SetWidth(932)
    panel:SetHeight(548)
    panel:Hide()
    owner.ui.professionsRequestsPanel = panel
    owner.ui.craftingNewRequest = UI:Button(panel, "New Request", 116, 30, function() owner:OpenCraftingRequestEditor("") end, "primary")
    owner.ui.craftingNewRequest:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    owner.ui.craftingShowClosed = UI:FilterChip(panel, "Active only", 128, function(button)
        OTLGM_DB.settings.craftingShowClosed = not OTLGM_DB.settings.craftingShowClosed
        owner.ui.craftingRequestOffsetShell = 0
        owner:RefreshProfessionsPage()
    end)
    owner.ui.craftingShowClosed:SetPoint("LEFT", owner.ui.craftingNewRequest, "RIGHT", 8, 0)
    owner.ui.craftingRequestSummary = Label(panel, "", "GameFontNormalSmall", 520, -9, 412, "RIGHT")
    owner.ui.craftingRequestSummary:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    panel.emptyState = UI:EmptyState(panel, 430, 150, "No crafting requests", "Ask the guild for an item, enchant, transmute or gem.")
    panel.emptyState:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -62)
    panel.emptyState.action = UI:Button(panel.emptyState, "New Request", 124, 30, function() owner:OpenCraftingRequestEditor("") end, "primary")
    panel.emptyState.action:SetPoint("BOTTOM", panel.emptyState, "BOTTOM", 0, 14)
    panel.emptyState:Hide()

    local list = UI:Card(panel, 510, 508, "Crafting Requests")
    list:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -40)
    list.rows = {}
    local index
    for index = 1, REQUEST_ROWS do
        local captured = index
        local row = UI:TableRow(list, 486, 36, function(button)
            if button.otlRequestId then owner.ui.craftingSelectedRequestShell = button.otlRequestId owner:RefreshProfessionsPage() end
        end)
        row:SetPoint("TOPLEFT", list, "TOPLEFT", 12, -32 - ((captured - 1) * 38))
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetWidth(22) row.icon:SetHeight(22) row.icon:SetPoint("LEFT", row, "LEFT", 7, 0)
        row.itemText = Label(row, "", "GameFontNormalSmall", 35, -6, 232, "LEFT")
        row.authorText = Label(row, "", "GameFontNormalSmall", 272, -6, 120, "LEFT")
        row.metaText = Label(row, "", "GameFontNormalSmall", 35, -21, 442, "LEFT")
        row.metaText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        row:Hide()
        list.rows[captured] = row
    end
    list.empty = UI:EmptyState(list, 420, 130, "No crafting requests", "Post a request or include completed requests to review older items.")
    list.empty:SetPoint("CENTER", list, "CENTER", 0, 0)
    list.empty:Hide()
    list.previous = UI:Button(list, "Previous", 78, 25, function() end, "utility")
    list.next = UI:Button(list, "Next", 70, 25, function() end, "utility")
    list.previous:Hide()
    list.next:Hide()
    list.pageText = Label(list, "", "GameFontNormalSmall", 12, -482, 250, "LEFT")
    list.pageText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    list.scroll = UI:Scrollbar(list, 360, function(value)
        owner.ui.craftingRequestOffsetShell = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
        owner:RefreshProfessionsPage()
    end)
    list.scroll:SetPoint("TOPRIGHT", list, "TOPRIGHT", -6, -32)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function()
        local visible = owner.ui.craftingRequestVisibleRows180 or DEFAULT_REQUEST_ROWS
        local maximum = math.max(0, table.getn(owner:GetCraftingRequests(OTLGM_DB.settings.craftingShowClosed and true or false) or {}) - visible)
        owner.ui.craftingRequestOffsetShell = math.max(0, math.min(maximum, (owner.ui.craftingRequestOffsetShell or 0) - ((tonumber(arg1) or 0) * 3)))
        owner:RefreshProfessionsPage()
    end)
    owner.ui.craftingRequestListShell = list

    local details = UI:DetailsPanel(panel, 410, 508, "Request Details")
    details:SetPoint("TOPLEFT", panel, "TOPLEFT", 522, -40)
    details.itemIcon = details:CreateTexture(nil, "ARTWORK")
    details.itemIcon:SetWidth(34) details.itemIcon:SetHeight(34)
    details.itemIcon:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -34)
    details.itemText = Label(details, "", "GameFontNormalLarge", 56, -34, 340, "LEFT")
    details.itemText:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    details.metaText = Label(details, "", "GameFontNormalSmall", 56, -64, 340, "LEFT")
    details.metaText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    details.noteText = Label(details, "", "GameFontNormal", 14, -94, 382, "LEFT")
    details.noteText:SetHeight(80)
    details.noteText:SetJustifyV("TOP")
    details.relevanceText = Label(details, "", "GameFontNormalSmall", 14, -178, 382, "LEFT")
    details.relevanceText:SetTextColor(C.green[1], C.green[2], C.green[3])
    details.reactionsText = Label(details, "", "GameFontNormalSmall", 14, -198, 382, "LEFT")
    details.reactionsText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    details.help = UI:Button(details, "Can Help", 96, 27, function()
        if details.otlRequest then
            owner:SetCommunityReaction("CRAFT", details.otlRequest.id, "HELP", false)
            owner:RefreshProfessionsPage()
        end
    end, "secondary")
    details.help:SetPoint("TOPLEFT", details, "TOPLEFT", 14, -224)
    details.reply = UI:Button(details, "Reply", 84, 27, function()
        if details.otlRequest then owner:OpenCraftingResponseEditor(details.otlRequest.id) end
    end, "primary")
    details.reply:SetPoint("LEFT", details.help, "RIGHT", 8, 0)
    details.whisper = UI:Button(details, "Whisper", 88, 27, function()
        if details.otlRequest then owner:WhisperMember(details.otlRequest.author) end
    end, "secondary")
    details.whisper:SetPoint("LEFT", details.reply, "RIGHT", 8, 0)
    details.share = UI:Button(details, "Share", 76, 27, function()
        if details.otlRequest then owner:ShareCraftingRequestToGuildChat(details.otlRequest) owner:ShowToast("Request shared in guild chat.", "success") end
    end, "utility")
    details.share:SetPoint("LEFT", details.whisper, "RIGHT", 8, 0)
    Label(details, "RESPONSES", "GameFontNormalSmall", 14, -270, 160, "LEFT"):SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    details.responses = {}
    for index = 1, 6 do
        local captured = index
        local line = Label(details, "", "GameFontNormalSmall", 14, -292 - ((captured - 1) * 28), 382, "LEFT")
        line:SetHeight(26)
        line:SetJustifyV("TOP")
        details.responses[captured] = line
    end
    details.claim = UI:Button(details, "Claim", 88, 28, function()
        if not details.otlRequest then return end
        local ok, problem = owner:ClaimCraftingRequest(details.otlRequest.id)
        if not ok then owner:ShowToast(tostring(problem or "The request could not be claimed."), "error") end
        owner:RefreshProfessionsPage()
    end, "primary")
    details.claim:SetPoint("BOTTOMLEFT", details, "BOTTOMLEFT", 14, 14)
    details.complete = UI:Button(details, "Complete", 96, 28, function()
        local request = details.otlRequest
        if not request then return end
        local presentation = owner:GetCraftingRequestPresentation180(request) or {}
        local itemName = presentation.displayName or request.item or "this crafting request"
        owner:ShowConfirm("Complete Crafting Request?", "Mark \"" .. tostring(itemName) .. "\" as completed?", "Complete", function()
            local ok, problem = owner:CompleteCraftingRequest(request.id)
            if not ok then owner:ShowToast(tostring(problem or "The request could not be completed."), "error") end
            owner:RefreshProfessionsPage()
        end)
    end, "utility")
    details.complete:SetPoint("LEFT", details.claim, "RIGHT", 8, 0)
    details.delete = UI:Button(details, "Delete", 84, 28, function()
        local request = details.otlRequest
        if not request then return end
        owner:ShowConfirm("Delete Crafting Request?", "Delete the request for \"" .. tostring(request.item or "this item") .. "\"?", "Delete", function()
            owner:DeleteCraftingRequest(request.id)
            owner.ui.craftingSelectedRequestShell = nil
            owner:RefreshProfessionsPage()
        end)
    end, "danger")
    details.delete:SetPoint("LEFT", details.complete, "RIGHT", 8, 0)
    details.empty = UI:EmptyState(details, 370, 104, "Select a request", "Choose a request on the left to see its details.")
    details.empty:SetPoint("TOPLEFT", details, "TOPLEFT", 20, -56)
    owner.ui.craftingRequestDetailsShell = details
    owner.ui.craftingRequestOffsetShell = 0
end

local function BuildProfessions(owner, page)
    owner.ui.professionsRecipesTab = UI:Tab(page, "Recipes", 118, function() owner:SetProfessionsTab("RECIPES") end)
    owner.ui.professionsRecipesTab:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -4)
    owner.ui.professionsRequestsTab = UI:Tab(page, "Crafting Requests", 158, function() owner:SetProfessionsTab("REQUESTS") end)
    owner.ui.professionsRequestsTab:SetPoint("LEFT", owner.ui.professionsRecipesTab, "RIGHT", 8, 0)
    BuildRecipePanels(owner, page)
    BuildRequestsPanel(owner, page)
    owner.ui.professionsSection = OTLGM_DB.settings.craftingSection == "REQUESTS" and "REQUESTS" or "RECIPES"
    if owner.ui.professionsSection == "REQUESTS" then owner.ui.professionsRecipesPanel:Hide() owner.ui.professionsRequestsPanel:Show() end
end

local function ResolveRecipeIcon(owner, result)
    local recipe = result and result.recipe or nil
    if recipe and owner.IsTextureReference and owner:IsTextureReference(recipe.icon) then return recipe.icon end
    if owner.ResolveCraftingIcon157 then return owner:ResolveCraftingIcon157(recipe or {}, result and result.professionKey) end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function RefreshRecipeDetails(owner, selected)
    local details = owner.ui.recipeDetails
    if not selected then
        details.otlResult = nil details.otlCrafter = nil
        details.iconButton.otlResult = nil
        details.titleText:SetText("") details.metaText:SetText("")
        details.effectTitle:Hide() details.effectText:Hide() details.effectText:SetText("")
        details.favorite:Hide() details.request:Hide() details.whisper:Hide() details.invite:Hide()
        local index
        for index = 1, table.getn(details.reagents) do details.reagents[index]:Hide() end
        for index = 1, table.getn(details.crafters) do details.crafters[index]:Hide() end
        details.reagentEmpty:Hide()
        details.crafterEmpty:Hide()
        details.reagentsTitle:Hide()
        details.craftersTitle:Hide()
        details.actionsTitle:Hide()
        details.crafterScroll:Hide()
        details.empty:Show()
        return
    end
    details.empty:Hide()
    details.reagentsTitle:Show()
    details.craftersTitle:Show()
    details.actionsTitle:Show()
    details.otlResult = selected
    details.iconButton.otlResult = selected
    details.iconButton.icon:SetTexture(ResolveRecipeIcon(owner, selected))
    details.titleText:SetText(tostring(selected.recipe.name or "Recipe"))
    ApplyQualityColor(details.titleText, selected.recipe.quality)
    local skill = tonumber(selected.recipe.requiredSkill) or 0
    local meta = tostring(selected.professionLabel or selected.professionKey or "Profession")
    if skill > 0 then meta = meta .. "  |  Skill " .. tostring(skill) end
    details.metaText:SetText(meta .. "  |  " .. tostring(table.getn(selected.crafters or {})) .. " crafter(s)")
    local effectText = tostring(selected.recipe.effectText or "")
    if effectText == "" and owner.GetCraftingDetail then
        local cached = owner:GetCraftingDetail(selected.recipe, selected.professionKey)
        effectText = tostring(cached and cached.effectText or "")
    end
    if owner.NormalizeText and owner:NormalizeText(effectText) == owner:NormalizeText(selected.recipe.name or "") then effectText = "" end
    local hasEffect = effectText ~= ""
    local isEnchanting = tostring(selected.professionKey or "") == "ENCHANTING"
    local showEffectSection = hasEffect or isEnchanting
    if showEffectSection then
        details.effectTitle:Show() details.effectText:Show()
        if hasEffect then
            details.effectText:SetText(Short(effectText, 190))
        else
            details.effectText:SetText("Effect details have not been shared yet. An enchanter needs to open Enchanting once.")
        end
    else
        details.effectTitle:Hide() details.effectText:Hide() details.effectText:SetText("")
    end
    details.favorite.otlResult = selected
    details.request.otlResult = selected
    UI:SetSelected(details.favorite, owner:IsCraftingFavorite170(selected))
    details.favorite:Show() details.request:Show()
    local reagentTitleY = showEffectSection and 174 or 104
    local reagentStartY = reagentTitleY + 20
    details.reagentsTitle:ClearAllPoints()
    details.reagentsTitle:SetPoint("TOPLEFT", details, "TOPLEFT", 12, -reagentTitleY)
    local reagents = selected.recipe.reagents or {}
    local index
    for index = 1, table.getn(details.reagents) do
        local row = details.reagents[index]
        local reagent = reagents[index]
        if reagent then
            row.otlReagent = reagent
            row.otlProfessionKey = selected.professionKey
            row.icon:SetTexture((owner.IsTextureReference and owner:IsTextureReference(reagent.icon)) and reagent.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.nameText:SetText(tostring(reagent.count or 0) .. "x  " .. Short(reagent.name or "Unknown reagent", 34))
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", details, "TOPLEFT", 12, -reagentStartY - ((index - 1) * 28))
            row:Show()
        else row.otlReagent = nil row:Hide() end
    end
    details.reagentEmpty:ClearAllPoints()
    details.reagentEmpty:SetPoint("TOPLEFT", details, "TOPLEFT", 12, -reagentStartY)
    if table.getn(reagents) == 0 then
        details.reagentEmpty:SetText(selected.recipe.materialsStatus == "COMPLETE" and "No reagents are required." or "Reagent details are not cached yet.")
        details.reagentEmpty:Show()
    else details.reagentEmpty:Hide() end
    local reagentRows = math.min(5, table.getn(reagents))
    local reagentHeight = reagentRows > 0 and (reagentRows * 28) or 46
    local craftersTitleY = reagentStartY + reagentHeight + 8
    details.craftersTitle:ClearAllPoints()
    details.craftersTitle:SetPoint("TOPLEFT", details, "TOPLEFT", 12, -craftersTitleY)
    local crafterStartY = craftersTitleY + 20
    local selectedCrafter = details.otlCrafter
    local stillPresent = false
    for index = 1, table.getn(selected.crafters or {}) do
        if selectedCrafter and owner:NormalizeName(selected.crafters[index].name) == owner:NormalizeName(selectedCrafter.name) then selectedCrafter = selected.crafters[index] stillPresent = true break end
    end
    if not stillPresent then selectedCrafter = selected.crafters and selected.crafters[1] or nil end
    details.otlCrafter = selectedCrafter
    local totalCrafters = table.getn(selected.crafters or {})
    local detailHeight = tonumber(details:GetHeight()) or 508
    local availableRows = math.max(1, math.min(table.getn(details.crafters), math.floor(math.max(29, detailHeight - crafterStartY - 94) / 29)))
    local maximum = math.max(0, totalCrafters - availableRows)
    details.crafterOffset = math.max(0, math.min(maximum, tonumber(details.crafterOffset) or 0))
    for index = 1, table.getn(details.crafters) do
        local row = details.crafters[index]
        local crafter = index <= availableRows and selected.crafters and selected.crafters[details.crafterOffset + index] or nil
        if crafter then
            row.otlCrafter = crafter
            ApplyClassIcon(row.classIcon, crafter.class)
            row.nameText:SetText(owner:GetClassColor(crafter.class) .. Short(crafter.name, 18) .. owner.colors.reset)
            row.statusText:SetText(crafter.online and "Online" or Short(owner:GetFreshnessText(crafter.ts), 18))
            row.statusText:SetTextColor(crafter.online and C.green[1] or C.grey[1], crafter.online and C.green[2] or C.grey[2], crafter.online and C.green[3] or C.grey[3])
            UI:SetSelected(row, selectedCrafter and owner:NormalizeName(crafter.name) == owner:NormalizeName(selectedCrafter.name))
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", details, "TOPLEFT", 12, -crafterStartY - ((index - 1) * 29))
            row:Show()
        else row.otlCrafter = nil row:Hide() end
    end
    if totalCrafters == 0 then
        details.crafterEmpty:ClearAllPoints()
        details.crafterEmpty:SetPoint("TOPLEFT", details, "TOPLEFT", 12, -crafterStartY)
        details.crafterEmpty:Show()
    else details.crafterEmpty:Hide() end
    details.crafterScroll.otlSilent = true
    details.crafterScroll:SetMinMaxValues(0, maximum)
    details.crafterScroll:SetValue(details.crafterOffset)
    details.crafterScroll.otlSilent = nil
    details.crafterScroll:ClearAllPoints()
    details.crafterScroll:SetPoint("TOPRIGHT", details, "TOPRIGHT", -7, -crafterStartY)
    details.crafterScroll:SetHeight(math.max(29, math.min(availableRows, totalCrafters) * 29))
    if maximum > 0 then details.crafterScroll:Show() else details.crafterScroll:Hide() end
    local visibleCrafters = math.max(1, math.min(availableRows, totalCrafters))
    local actionsY = crafterStartY + (visibleCrafters * 29) + 8
    -- Keep the two action rows inside the compact details card even when a
    -- recipe has the full five-reagent block above it.
    actionsY = math.min(actionsY, math.max(crafterStartY + 29, detailHeight - 84))
    details.actionsTitle:ClearAllPoints()
    details.actionsTitle:SetPoint("TOPLEFT", details, "TOPLEFT", 12, -actionsY)
    local detailWidth = math.max(220, tonumber(details:GetWidth()) or 322)
    local actionInner = math.max(196, detailWidth - 24)
    local actionGap = 8
    local primaryWidth = math.floor((actionInner - actionGap) / 2)
    details.favorite:ClearAllPoints()
    details.favorite:SetPoint("TOPLEFT", details, "TOPLEFT", 12, -(actionsY + 20))
    details.favorite:SetWidth(primaryWidth)
    if details.favorite.text then details.favorite.text:SetWidth(math.max(46, primaryWidth - 8)) end
    details.request:ClearAllPoints()
    details.request:SetPoint("TOPLEFT", details, "TOPLEFT", 12 + primaryWidth + actionGap, -(actionsY + 20))
    local secondaryWidth = actionInner - primaryWidth - actionGap
    details.request:SetWidth(secondaryWidth)
    if details.request.text then details.request.text:SetWidth(math.max(54, secondaryWidth - 8)) end
    details.whisper:ClearAllPoints()
    details.whisper:SetPoint("TOPLEFT", details, "TOPLEFT", 12, -(actionsY + 52))
    details.whisper:SetWidth(primaryWidth)
    if details.whisper.text then details.whisper.text:SetWidth(math.max(46, primaryWidth - 8)) end
    details.invite:ClearAllPoints()
    details.invite:SetPoint("TOPLEFT", details, "TOPLEFT", 12 + primaryWidth + actionGap, -(actionsY + 52))
    details.invite:SetWidth(secondaryWidth)
    if details.invite.text then details.invite.text:SetWidth(math.max(46, secondaryWidth - 8)) end
    if selectedCrafter then details.whisper:Show() details.invite:Show()
    else details.whisper:Hide() details.invite:Hide() end
end

local function RefreshRecipes(owner)
    local query = owner.ui.craftingSearchEdit:GetText() or ""
    local profession = owner.ui.craftingProfessionFilterShell or "ALL"
    local counts = owner:GetCraftingProfessionCounts(query)
    local definitions = owner:GetCraftingProfessionDefinitions()
    local index
    local professionVisible = owner.ui.craftingProfessionVisibleRows180 or table.getn(definitions)
    local professionMaximum = math.max(0, table.getn(definitions) - professionVisible)
    local professionOffset = math.max(0, math.min(professionMaximum, tonumber(owner.ui.craftingProfessionOffset180) or 0))
    owner.ui.craftingProfessionOffset180 = professionOffset
    for index = 1, table.getn(owner.ui.professionColumn.rows) do
        local row = owner.ui.professionColumn.rows[index]
        local definition = index <= professionVisible and definitions[professionOffset + index] or nil
        if definition then
            local displayLabel = string.find(string.lower(definition.label or ""), "mining", 1, true) and "Mining" or definition.label
            row.otlProfessionKey = definition.key
            row.icon:SetTexture(definition.icon)
            row.nameText:SetText(displayLabel)
            row.countText:SetText(tostring(counts[definition.key] or 0))
            UI:SetSelected(row, definition.key == profession)
            row:Show()
        else
            row.otlProfessionKey = nil
            row:Hide()
        end
    end
    if owner.ui.professionColumn.scroll then
        owner.ui.professionColumn.scroll:SetScrollMetrics180(table.getn(definitions), professionVisible, professionOffset)
    end
    local categories = owner.GetCraftingCategoryDefinitions153 and owner:GetCraftingCategoryDefinitions153(profession) or { { "ALL", "All" } }
    local currentCategory = OTLGM_DB.settings.craftingCategory153 or "ALL"
    local _, categoryDef = FindDefinition(categories, currentCategory)
    if not categoryDef then OTLGM_DB.settings.craftingCategory153 = "ALL" end
    owner.craftingFilterContext153 = true
    local ok, results = pcall(function() return owner:GetCraftingSearchResults(query, profession) end)
    owner.craftingFilterContext153 = nil
    if not ok then
        results = {}
        owner:ShowOperationError("Recipe search could not be refreshed.", function() owner:RefreshProfessionsPage() end)
    else owner:ClearOperationError() end
    local visibleRows = owner.ui.craftingRecipeVisibleRows180 or DEFAULT_RECIPE_ROWS
    local offset = math.max(0, tonumber(owner.ui.craftingRecipeOffset) or 0)
    local maximum = math.max(0, table.getn(results) - visibleRows)
    if offset > maximum then offset = maximum end
    local selected, selectedIndex
    for index = 1, table.getn(results) do
        if owner.ui.craftingSelectedRecipeKey == results[index].key then selected = results[index] selectedIndex = index break end
    end
    if not selected then selected = results[1] owner.ui.craftingSelectedRecipeKey = selected and selected.key or nil end
    local focusKey = owner.ui.craftingFocusRecipeKey180
    if selectedIndex and focusKey and focusKey == selected.key then
        offset = math.max(0, math.min(maximum, selectedIndex - math.max(1, math.floor(visibleRows / 2))))
    end
    -- Deep-link focus is a one-shot command, not persistent selection gravity.
    -- Manual wheel/drag may move the selected row out of view while details stay open.
    owner.ui.craftingFocusRecipeKey180 = nil
    owner.ui.craftingRecipeOffset = offset
    for index = 1, table.getn(owner.ui.recipeColumn.rows) do
        local row = owner.ui.recipeColumn.rows[index]
        local result = index <= visibleRows and results[offset + index] or nil
        if result then
            row.otlResult = result
            row.otlResultKey = result.key
            row.icon:SetTexture(ResolveRecipeIcon(owner, result))
            local favorite = owner:IsCraftingFavorite170(result)
            row.nameText:SetText(Short(result.recipe.name or "Recipe", 32))
            ApplyQualityColor(row.nameText, result.recipe.quality)
            if favorite then row.favoriteIcon:Show() else row.favoriteIcon:Hide() end
            local online = 0
            local crafterIndex
            for crafterIndex = 1, table.getn(result.crafters or {}) do if result.crafters[crafterIndex].online then online = online + 1 end end
            row.crafterText:SetText(tostring(table.getn(result.crafters or {})) .. " crafters" .. (online > 0 and ("  " .. tostring(online) .. " online") or ""))
            UI:SetSelected(row, selected and result.key == selected.key)
            row:Show()
        else row.otlResult = nil row.otlResultKey = nil row.favoriteIcon:Hide() row:Hide() end
    end
    if table.getn(results) == 0 then owner.ui.recipeColumn.empty:Show() else owner.ui.recipeColumn.empty:Hide() end
    owner.ui.recipeColumn.previous:Hide()
    owner.ui.recipeColumn.next:Hide()
    local firstShown = table.getn(results) > 0 and (offset + 1) or 0
    local lastShown = math.min(table.getn(results), offset + visibleRows)
    owner.ui.recipeColumn.pageText:SetText("Showing " .. tostring(firstShown) .. "-" .. tostring(lastShown) .. " of " .. tostring(table.getn(results)))
    if owner.ui.recipeColumn.scroll then owner.ui.recipeColumn.scroll:SetScrollMetrics180(table.getn(results), visibleRows, offset) end
    UI:SetSelected(owner.ui.craftingFavoriteFilter, OTLGM_DB.settings.craftingFavoritesOnly170 and true or false)
    UI:SetSelected(owner.ui.craftingOnlineFirst, OTLGM_DB.settings.craftingSort153 == "ONLINE")
    local filterActive = OTLGM_DB.settings.craftingCategory153 ~= "ALL" or OTLGM_DB.settings.craftingLevelFilter153 ~= "ANY"
        or OTLGM_DB.settings.craftingRarityFilter153 ~= "ANY" or OTLGM_DB.settings.craftingOnlineOnly153
    UI:SetText(owner.ui.craftingFilters, filterActive and "Filters active" or "Filters")
    local craft = owner:EnsureCraftingDB()
    local sync = craft and craft.syncState or {}
    local operation = owner.GetOperationState156 and owner:GetOperationState156("CRAFTING") or { state = "IDLE", detail = "" }
    local state
    if operation.state == "ERROR" then
        state = "Error" .. (operation.detail ~= "" and (": " .. Short(operation.detail, 34)) or "")
    elseif sync and sync.active then
        state = "Updating..."
    else
        local freshest = tonumber(sync and sync.completed) or tonumber(craft and craft.lastSync) or 0
        if freshest > 0 then
            local minutes = math.max(0, math.floor((owner:Now() - freshest) / 60))
            state = "Updated " .. tostring(minutes) .. " min ago"
        elseif table.getn(results) > 0 then state = "Local data"
        else state = "Sync pending" end
    end
    owner.ui.craftingStateText:SetText(state)
    UI:SetText(owner.ui.craftingUpdate, sync and sync.active and "Updating…" or "Update guild")
    UI:SetEnabled(owner.ui.craftingUpdate, not (sync and sync.active), "A guild recipe update is already in progress.")
    RefreshRecipeDetails(owner, selected)
end

local function RefreshRequests(owner)
    local includeCompleted = OTLGM_DB.settings.craftingShowClosed and true or false
    local requests = owner:GetCraftingRequests(includeCompleted)
    local requestsPanel = owner.ui.professionsRequestsPanel
    if table.getn(requests) == 0 then
        owner.ui.craftingSelectedRequestShell = nil
        owner.ui.craftingNewRequest:Hide()
        owner.ui.craftingRequestListShell:Hide()
        owner.ui.craftingRequestDetailsShell:Hide()
        requestsPanel.emptyState:Show()
        UI:SetText(owner.ui.craftingShowClosed, includeCompleted and "Including completed" or "Active only")
        UI:SetSelected(owner.ui.craftingShowClosed, includeCompleted)
        local emptySummary = owner:GetCraftingSummary()
        owner.ui.craftingRequestSummary:SetText(tostring(emptySummary.requests or 0) .. " requests")
        return
    end
    requestsPanel.emptyState:Hide()
    owner.ui.craftingNewRequest:Show()
    owner.ui.craftingRequestListShell:Show()
    owner.ui.craftingRequestDetailsShell:Show()
    local visibleRows = owner.ui.craftingRequestVisibleRows180 or DEFAULT_REQUEST_ROWS
    local offset = math.max(0, tonumber(owner.ui.craftingRequestOffsetShell) or 0)
    local maximum = math.max(0, table.getn(requests) - visibleRows)
    if offset > maximum then offset = maximum end
    local selected, selectedIndex
    local index
    for index = 1, table.getn(requests) do
        if owner.ui.craftingSelectedRequestShell == requests[index].id then selected = requests[index] selectedIndex = index break end
    end
    if not selected then owner.ui.craftingSelectedRequestShell = nil end
    if selectedIndex and owner.ui.craftingFocusRequest180 == selected.id then
        offset = math.max(0, math.min(maximum, selectedIndex - math.max(1, math.floor(visibleRows / 2))))
    end
    owner.ui.craftingFocusRequest180 = nil
    owner.ui.craftingRequestOffsetShell = offset
    for index = 1, table.getn(owner.ui.craftingRequestListShell.rows) do
        local row = owner.ui.craftingRequestListShell.rows[index]
        local request = index <= visibleRows and requests[offset + index] or nil
        if request then
            local summary = owner:GetCommunityReactionSummary("CRAFT", request.id)
            local presentation = owner:GetCraftingRequestPresentation180(request) or {}
            row.otlRequestId = request.id
            row.icon:SetTexture(presentation.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.itemText:SetText(Short(presentation.displayName or request.item or "Crafting request", 38))
            ApplyQualityColor(row.itemText, presentation.quality)
            row.authorText:SetText(owner:GetClassColor(request.class) .. Short(request.author, 18) .. owner.colors.reset)
            row.metaText:SetText(RequestStatusText(request.status) .. "  |  " .. (presentation.source == "RECIPE" and ((presentation.professionLabel or presentation.professionKey or "Recipe") .. "  |  ") or "") .. (request.materials == "READY" and "Materials ready" or request.materials == "NEEDED" and "Materials needed" or "Discuss materials") .. "  |  Help " .. tostring(summary.HELP or 0))
            UI:SetSelected(row, selected and request.id == selected.id)
            row:Show()
        else row.otlRequestId = nil row.icon:SetTexture(nil) row:Hide() end
    end
    if table.getn(requests) == 0 then owner.ui.craftingRequestListShell.empty:Show() else owner.ui.craftingRequestListShell.empty:Hide() end
    owner.ui.craftingRequestListShell.previous:Hide()
    owner.ui.craftingRequestListShell.next:Hide()
    local firstShown = table.getn(requests) > 0 and (offset + 1) or 0
    local lastShown = math.min(table.getn(requests), offset + visibleRows)
    owner.ui.craftingRequestListShell.pageText:SetText("Showing " .. tostring(firstShown) .. "-" .. tostring(lastShown) .. " of " .. tostring(table.getn(requests)))
    if owner.ui.craftingRequestListShell.scroll then owner.ui.craftingRequestListShell.scroll:SetScrollMetrics180(table.getn(requests), visibleRows, offset) end
    UI:SetText(owner.ui.craftingShowClosed, includeCompleted and "Including completed" or "Active only")
    UI:SetSelected(owner.ui.craftingShowClosed, includeCompleted)
    local summary = owner:GetCraftingSummary()
    owner.ui.craftingRequestSummary:SetText(tostring(summary.requests or 0) .. " requests  |  " .. tostring(summary.responses or 0) .. " responses")
    local details = owner.ui.craftingRequestDetailsShell
    if not selected then
        details.otlRequest = nil
        details.itemIcon:SetTexture(nil)
        details.itemText:SetText("") details.metaText:SetText("") details.noteText:SetText("") details.relevanceText:SetText("") details.reactionsText:SetText("")
        details.help:Hide() details.reply:Hide() details.whisper:Hide() details.share:Hide()
        details.claim:Hide() details.complete:Hide() details.delete:Hide()
        for index = 1, table.getn(details.responses) do details.responses[index]:Hide() end
        details.empty:Show()
        return
    end
    details.empty:Hide()
    details.otlRequest = selected
    local presentation = owner:GetCraftingRequestPresentation180(selected) or {}
    details.itemIcon:SetTexture(presentation.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    details.itemText:SetText(Short(presentation.displayName or selected.item or "Crafting request", 52))
    ApplyQualityColor(details.itemText, presentation.quality)
    local claimedText = selected.claimedBy and selected.claimedBy ~= "" and ("  |  Crafter " .. tostring(selected.claimedBy)) or ""
    local identityText = presentation.source == "RECIPE" and ((presentation.professionLabel or presentation.professionKey or "Recipe") .. (presentation.recipeName and presentation.recipeName ~= presentation.displayName and ("  |  " .. presentation.recipeName) or "")) or "Generic request"
    details.metaText:SetText(RequestStatusText(selected.status) .. "  |  " .. tostring(selected.author or "Unknown") .. claimedText .. "  |  " .. identityText .. "  |  " .. owner:Stamp(selected.ts))
    local reagentText = ""
    if presentation.source == "RECIPE" and table.getn(presentation.reagents or {}) > 0 then
        local parts = {}
        for index = 1, math.min(5, table.getn(presentation.reagents)) do
            local reagent = presentation.reagents[index]
            table.insert(parts, tostring(reagent.count or 0) .. "x " .. tostring(reagent.name or "Reagent"))
        end
        reagentText = "\nReagents: " .. table.concat(parts, ", ")
    elseif presentation.source == "RECIPE" then
        reagentText = "\nRecipe metadata is available; reagents are not cached on this client."
    end
    details.noteText:SetText((selected.note and selected.note ~= "" and selected.note or "No note") .. "\n" .. (selected.materials == "READY" and "Materials ready" or selected.materials == "NEEDED" and "Materials needed" or "Discuss materials") .. reagentText)
    local match = owner:GetCraftingRequestMatch180(selected)
    if match and match.current then details.relevanceText:SetText("You know this recipe")
    elseif match then details.relevanceText:SetText("Known by " .. tostring(match.character))
    else details.relevanceText:SetText("") end
    local reactions = owner:GetCommunityReactionSummary("CRAFT", selected.id)
    details.reactionsText:SetText("Guild help reactions: " .. tostring(reactions.HELP or 0))
    UI:SetText(details.help, "Can Help  " .. tostring(reactions.HELP or 0))
    local completed = RequestStatusText(selected.status) == "Completed"
    if completed then details.help:Hide() details.reply:Hide()
    else details.help:Show() details.reply:Show() end
    details.whisper:Show() details.share:Show()
    local responses = owner:GetCraftingResponses(selected.id)
    for index = 1, table.getn(details.responses) do
        local response = responses[index]
        if response then
            local responseText
            if response.state == "CLAIMED" then responseText = " claimed this request."
            elseif response.state == "COMPLETED" then responseText = " completed this request."
            else responseText = (response.canHelp and " can help: " or ": ") .. Short(response.text or "", 48) end
            details.responses[index]:SetText(owner:GetClassColor(response.class) .. tostring(response.author or "Unknown") .. owner.colors.reset .. responseText)
            details.responses[index]:Show()
        else details.responses[index]:Hide() end
    end
    if owner:CanClaimCraftingRequest(selected) then details.claim:Show() else details.claim:Hide() end
    if owner:CanCompleteCraftingRequest(selected) then details.complete:Show() else details.complete:Hide() end
    if owner:CanModifyCraftingRequest(selected) then details.delete:Show() else details.delete:Hide() end
end

function OTLGM:RefreshProfessionsPage()
    if self.CanRefreshShellPage180 and not self:CanRefreshShellPage180("professions") then return false end
    if not self.ui or not self.ui.professionsRecipesPanel then return end
    local section = self.ui.professionsSection == "REQUESTS" and "REQUESTS" or "RECIPES"
    if section == "RECIPES" then self.ui.professionsRecipesPanel:Show() self.ui.professionsRequestsPanel:Hide() RefreshRecipes(self)
    else self.ui.professionsRecipesPanel:Hide() self.ui.professionsRequestsPanel:Show() RefreshRequests(self) end
    UI:SetSelected(self.ui.professionsRecipesTab, section == "RECIPES")
    UI:SetSelected(self.ui.professionsRequestsTab, section == "REQUESTS")
end

local function LayoutProfessions(owner, page, width, height)
    local previousProfessionRows = tonumber(owner.ui.craftingProfessionVisibleRows180)
    local previousRecipeRows = tonumber(owner.ui.craftingRecipeVisibleRows180)
    local previousRequestRows = tonumber(owner.ui.craftingRequestVisibleRows180)
    local panelHeight = math.max(430, height - 40)
    local columnHeight = panelHeight - 40
    owner.ui.professionsRecipesPanel:SetWidth(width)
    owner.ui.professionsRecipesPanel:SetHeight(panelHeight)
    owner.ui.professionsRequestsPanel:SetWidth(width)
    owner.ui.professionsRequestsPanel:SetHeight(panelHeight)

    -- Recipe toolbar: reserve a bounded right block for sync state/update and
    -- let search absorb the remaining width. Nothing is allowed to extend
    -- under the right edge at compact window sizes.
    local updateWidth = 112
    local stateWidth = width < 900 and 96 or 136
    local favoriteWidth = width < 900 and 96 or 112
    local onlineWidth = width < 900 and 104 or 118
    local filtersWidth = width < 900 and 80 or 90
    local gaps = 8
    local searchWidth = width - updateWidth - stateWidth - favoriteWidth - onlineWidth - filtersWidth - (gaps * 5)
    searchWidth = math.max(190, searchWidth)
    owner.ui.craftingSearchEdit:SetWidth(searchWidth)
    owner.ui.craftingSearchEdit:ClearAllPoints()
    owner.ui.craftingSearchEdit:SetPoint("TOPLEFT", owner.ui.professionsRecipesPanel, "TOPLEFT", 0, 0)
    owner.ui.craftingFavoriteFilter:SetWidth(favoriteWidth)
    if owner.ui.craftingFavoriteFilter.text then owner.ui.craftingFavoriteFilter.text:SetWidth(math.max(52, favoriteWidth - 8)) end
    owner.ui.craftingFavoriteFilter:ClearAllPoints()
    owner.ui.craftingFavoriteFilter:SetPoint("LEFT", owner.ui.craftingSearchEdit, "RIGHT", gaps, 0)
    owner.ui.craftingOnlineFirst:SetWidth(onlineWidth)
    if owner.ui.craftingOnlineFirst.text then owner.ui.craftingOnlineFirst.text:SetWidth(math.max(58, onlineWidth - 8)) end
    owner.ui.craftingOnlineFirst:ClearAllPoints()
    owner.ui.craftingOnlineFirst:SetPoint("LEFT", owner.ui.craftingFavoriteFilter, "RIGHT", gaps, 0)
    owner.ui.craftingFilters:SetWidth(filtersWidth)
    if owner.ui.craftingFilters.text then owner.ui.craftingFilters.text:SetWidth(math.max(48, filtersWidth - 8)) end
    owner.ui.craftingFilters:ClearAllPoints()
    owner.ui.craftingFilters:SetPoint("LEFT", owner.ui.craftingOnlineFirst, "RIGHT", gaps, 0)
    owner.ui.craftingUpdate:SetWidth(updateWidth)
    if owner.ui.craftingUpdate.text then owner.ui.craftingUpdate.text:SetWidth(math.max(58, updateWidth - 8)) end
    owner.ui.craftingUpdate:ClearAllPoints()
    owner.ui.craftingUpdate:SetPoint("TOPRIGHT", owner.ui.professionsRecipesPanel, "TOPRIGHT", 0, 0)
    owner.ui.craftingStateText:ClearAllPoints()
    owner.ui.craftingStateText:SetPoint("RIGHT", owner.ui.craftingUpdate, "LEFT", -gaps, 0)
    owner.ui.craftingStateText:SetWidth(stateWidth)

    local gap = 8
    local usable = width - (gap * 2)
    local professionWidth = math.max(170, math.floor(usable * 0.20))
    local recipeWidth = math.max(350, math.floor(usable * 0.45))
    local detailsWidth = width - professionWidth - recipeWidth - (gap * 2)
    -- Preserve a usable details panel on unusually narrow hosts by borrowing
    -- width from the recipe list first, then from the professions list.
    if detailsWidth < 230 then
        local need = 230 - detailsWidth
        local takeRecipe = math.min(need, math.max(0, recipeWidth - 330))
        recipeWidth = recipeWidth - takeRecipe
        need = need - takeRecipe
        local takeProfession = math.min(need, math.max(0, professionWidth - 160))
        professionWidth = professionWidth - takeProfession
        detailsWidth = width - professionWidth - recipeWidth - (gap * 2)
    end

    owner.ui.professionColumn:SetWidth(professionWidth)
    owner.ui.professionColumn:SetHeight(columnHeight)
    owner.ui.craftingProfessionVisibleRows180 = math.max(4, math.min(table.getn(owner.ui.professionColumn.rows), math.floor((columnHeight - 44) / 39)))
    owner.ui.craftingRecipeVisibleRows180 = math.max(4, math.min(RECIPE_ROWS, math.floor((columnHeight - 44) / 34)))
    owner.ui.recipeColumn:ClearAllPoints()
    owner.ui.recipeColumn:SetPoint("TOPLEFT", owner.ui.professionsRecipesPanel, "TOPLEFT", professionWidth + gap, -40)
    owner.ui.recipeColumn:SetWidth(recipeWidth)
    owner.ui.recipeColumn:SetHeight(columnHeight)
    owner.ui.recipeDetails:ClearAllPoints()
    owner.ui.recipeDetails:SetPoint("TOPRIGHT", owner.ui.professionsRecipesPanel, "TOPRIGHT", 0, -40)
    owner.ui.recipeDetails:SetWidth(detailsWidth)
    owner.ui.recipeDetails:SetHeight(columnHeight)
    local index
    for index = 1, table.getn(owner.ui.professionColumn.rows) do
        local row = owner.ui.professionColumn.rows[index]
        row:SetWidth(professionWidth - 30)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", owner.ui.professionColumn, "TOPLEFT", 12, -32 - ((index - 1) * 39))
        row.nameText:SetWidth(math.max(52, professionWidth - 106))
        row.countText:ClearAllPoints()
        row.countText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        row.countText:SetWidth(46)
    end
    for index = 1, table.getn(owner.ui.recipeColumn.rows) do
        local row = owner.ui.recipeColumn.rows[index]
        row:SetWidth(recipeWidth - 30)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", owner.ui.recipeColumn, "TOPLEFT", 12, -32 - ((index - 1) * 34))
        row.nameText:SetWidth(math.max(130, recipeWidth - 188))
        row.favoriteIcon:ClearAllPoints()
        row.favoriteIcon:SetPoint("RIGHT", row, "RIGHT", -116, 0)
        row.crafterText:ClearAllPoints()
        row.crafterText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        row.crafterText:SetWidth(104)
    end
    if owner.ui.professionColumn.scroll then
        owner.ui.professionColumn.scroll:ClearAllPoints()
        owner.ui.professionColumn.scroll:SetPoint("TOPRIGHT", owner.ui.professionColumn, "TOPRIGHT", -6, -32)
        owner.ui.professionColumn.scroll:SetHeight(math.max(80, owner.ui.craftingProfessionVisibleRows180 * 39 - 5))
    end
    if owner.ui.recipeColumn.scroll then
        owner.ui.recipeColumn.scroll:ClearAllPoints()
        owner.ui.recipeColumn.scroll:SetPoint("TOPRIGHT", owner.ui.recipeColumn, "TOPRIGHT", -6, -32)
        owner.ui.recipeColumn.scroll:SetHeight(math.max(80, owner.ui.craftingRecipeVisibleRows180 * 34 - 4))
    end
    owner.ui.recipeColumn.pageText:ClearAllPoints()
    owner.ui.recipeColumn.pageText:SetPoint("BOTTOMLEFT", owner.ui.recipeColumn, "BOTTOMLEFT", 12, 7)
    owner.ui.recipeColumn.pageText:SetWidth(recipeWidth - 36)

    local detailInner = math.max(196, detailsWidth - 24)
    owner.ui.recipeDetails.titleText:SetWidth(math.max(110, detailsWidth - 84))
    owner.ui.recipeDetails.metaText:SetWidth(math.max(110, detailsWidth - 84))
    owner.ui.recipeDetails.effectText:SetWidth(detailInner)
    owner.ui.recipeDetails.empty:SetWidth(math.max(196, detailsWidth - 34))
    for index = 1, table.getn(owner.ui.recipeDetails.reagents) do
        owner.ui.recipeDetails.reagents[index]:SetWidth(detailInner)
        owner.ui.recipeDetails.reagents[index].nameText:SetWidth(math.max(80, detailInner - 42))
    end
    owner.ui.recipeDetails.reagentEmpty:SetWidth(detailInner)
    owner.ui.recipeDetails.crafterEmpty:SetWidth(math.max(120, detailInner - 12))
    for index = 1, table.getn(owner.ui.recipeDetails.crafters) do
        local row = owner.ui.recipeDetails.crafters[index]
        row:SetWidth(detailInner)
        local statusWidth = math.min(116, math.max(76, math.floor(detailInner * 0.42)))
        row.nameText:SetWidth(math.max(54, detailInner - statusWidth - 34))
        row.statusText:ClearAllPoints()
        row.statusText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        row.statusText:SetWidth(statusWidth)
    end

    -- Requests toolbar and split view.
    owner.ui.craftingNewRequest:ClearAllPoints()
    owner.ui.craftingNewRequest:SetPoint("TOPLEFT", owner.ui.professionsRequestsPanel, "TOPLEFT", 0, 0)
    owner.ui.craftingShowClosed:ClearAllPoints()
    owner.ui.craftingShowClosed:SetPoint("LEFT", owner.ui.craftingNewRequest, "RIGHT", 8, 0)
    owner.ui.craftingRequestSummary:ClearAllPoints()
    owner.ui.craftingRequestSummary:SetPoint("TOPRIGHT", owner.ui.professionsRequestsPanel, "TOPRIGHT", 0, -9)
    owner.ui.craftingRequestSummary:SetWidth(math.max(220, width - 276))

    local requestListWidth = math.max(420, math.floor(width * 0.55))
    local requestDetailsWidth = width - requestListWidth - 12
    if requestDetailsWidth < 300 then
        requestDetailsWidth = 300
        requestListWidth = width - requestDetailsWidth - 12
    end
    owner.ui.craftingRequestListShell:SetWidth(requestListWidth)
    owner.ui.craftingRequestListShell:SetHeight(columnHeight)
    owner.ui.craftingRequestVisibleRows180 = math.max(4, math.min(REQUEST_ROWS, math.floor((columnHeight - 44) / 38)))
    for index = 1, table.getn(owner.ui.craftingRequestListShell.rows) do
        local row = owner.ui.craftingRequestListShell.rows[index]
        row:SetWidth(requestListWidth - 30)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", owner.ui.craftingRequestListShell, "TOPLEFT", 12, -32 - ((index - 1) * 38))
        row.itemText:SetWidth(math.max(120, requestListWidth - 260))
        row.authorText:ClearAllPoints()
        row.authorText:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -6)
        row.authorText:SetWidth(math.min(128, math.max(92, requestListWidth * 0.25)))
        row.metaText:SetWidth(math.max(130, requestListWidth - 66))
    end
    if owner.ui.craftingRequestListShell.scroll then
        owner.ui.craftingRequestListShell.scroll:ClearAllPoints()
        owner.ui.craftingRequestListShell.scroll:SetPoint("TOPRIGHT", owner.ui.craftingRequestListShell, "TOPRIGHT", -6, -32)
        owner.ui.craftingRequestListShell.scroll:SetHeight(math.max(80, owner.ui.craftingRequestVisibleRows180 * 38 - 4))
    end
    owner.ui.craftingRequestListShell.pageText:ClearAllPoints()
    owner.ui.craftingRequestListShell.pageText:SetPoint("BOTTOMLEFT", owner.ui.craftingRequestListShell, "BOTTOMLEFT", 12, 7)
    owner.ui.craftingRequestListShell.pageText:SetWidth(requestListWidth - 36)
    owner.ui.craftingRequestDetailsShell:ClearAllPoints()
    owner.ui.craftingRequestDetailsShell:SetPoint("TOPRIGHT", owner.ui.professionsRequestsPanel, "TOPRIGHT", 0, -40)
    owner.ui.craftingRequestDetailsShell:SetWidth(requestDetailsWidth)
    owner.ui.craftingRequestDetailsShell:SetHeight(columnHeight)
    local requestInner = math.max(260, requestDetailsWidth - 28)
    owner.ui.craftingRequestDetailsShell.itemText:SetWidth(math.max(140, requestDetailsWidth - 70))
    owner.ui.craftingRequestDetailsShell.metaText:SetWidth(math.max(140, requestDetailsWidth - 70))
    owner.ui.craftingRequestDetailsShell.noteText:SetWidth(requestInner)
    owner.ui.craftingRequestDetailsShell.relevanceText:SetWidth(requestInner)
    owner.ui.craftingRequestDetailsShell.reactionsText:SetWidth(requestInner)
    for index = 1, table.getn(owner.ui.craftingRequestDetailsShell.responses) do
        owner.ui.craftingRequestDetailsShell.responses[index]:SetWidth(requestInner)
    end
    owner.ui.craftingRequestDetailsShell.empty:SetWidth(math.max(240, requestDetailsWidth - 40))
    local requestActionGap = 6
    local requestActionWidth = math.floor((requestInner - (requestActionGap * 3)) / 4)
    local requestActions = {
        owner.ui.craftingRequestDetailsShell.help,
        owner.ui.craftingRequestDetailsShell.reply,
        owner.ui.craftingRequestDetailsShell.whisper,
        owner.ui.craftingRequestDetailsShell.share,
    }
    for index = 1, table.getn(requestActions) do
        requestActions[index]:ClearAllPoints()
        requestActions[index]:SetPoint("TOPLEFT", owner.ui.craftingRequestDetailsShell, "TOPLEFT",
            14 + ((index - 1) * (requestActionWidth + requestActionGap)), -224)
        requestActions[index]:SetWidth(requestActionWidth)
        if requestActions[index].text then requestActions[index].text:SetWidth(math.max(38, requestActionWidth - 8)) end
    end
    page.otlNativeLayout = true
    if owner.MarkLayoutDataRefresh180 and ((previousProfessionRows and previousProfessionRows ~= owner.ui.craftingProfessionVisibleRows180)
        or (previousRecipeRows and previousRecipeRows ~= owner.ui.craftingRecipeVisibleRows180)
        or (previousRequestRows and previousRequestRows ~= owner.ui.craftingRequestVisibleRows180)) then
        owner:MarkLayoutDataRefresh180("professions")
    end
end

OTLGM:CreateShellPageModule180("professions", BuildProfessions,
    function(owner) owner:RefreshProfessionsPage() end,
    LayoutProfessions, { "recipes", "crafting-requests", "filters" }, { width = 780, height = 520 })

OTLGM:RegisterModule("ProfessionsPage180", {
    stage = "C2",
    revision = 1,
    lazy = true,
    migrated = true,
    nativeContentHost = true,
    pageContract = true,
    split = "20/45/35",
    protocol = 3,
    noOnUpdate = true,
})
