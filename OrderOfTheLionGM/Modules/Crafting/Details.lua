-- Local crafting result inspection. Standard item tooltips are preferred; a
-- hidden scanner captures enchant/custom-server lines while the profession
-- window is open so recipes without an output item still have useful details.

local DETAIL_MAX_LINES = 20
local DETAIL_MAX_AGE = 90 * 86400

local function ParseLinkID(link, linkType)
    if not link or link == "" then return 0 end
    local _, _, id = string.find(tostring(link), tostring(linkType or "item") .. ":(%d+)")
    return tonumber(id) or 0
end

local function DetailHash(lines)
    local hash = 17
    local index, characterIndex, text
    for index = 1, table.getn(lines or {}) do
        text = tostring(lines[index].left or "") .. "\031" .. tostring(lines[index].right or "")
        for characterIndex = 1, string.len(text) do hash = math.mod((hash * 33) + string.byte(text, characterIndex), 2147483000) end
    end
    return tostring(hash)
end

local function EffectSummary(self, recipe, lines)
    if (tonumber(recipe and recipe.itemId) or 0) > 0 or (recipe and recipe.itemLink and recipe.itemLink ~= "") then return "" end
    local parts = {}
    local recipeName = self:NormalizeText(recipe and recipe.name or "")
    local index, line, text
    for index = 1, table.getn(lines or {}) do
        line = lines[index]
        text = self:SafeText(((line and line.left) or "") .. ((line and line.right and line.right ~= "") and (" " .. line.right) or ""), 180, false, false)
        if text ~= "" and self:NormalizeText(text) ~= recipeName then table.insert(parts, text) end
    end
    return self:Utf8Truncate(table.concat(parts, " / "), 110)
end

function OTLGM:GetCraftingDetailKey(recipe, professionKey)
    if not recipe then return nil end
    local itemId = tonumber(recipe.itemId) or ParseLinkID(recipe.itemLink, "item")
    if itemId > 0 then return "I:" .. tostring(itemId) end
    local enchantId = ParseLinkID(recipe.recipeLink, "enchant")
    if enchantId <= 0 then enchantId = ParseLinkID(recipe.recipeLink, "spell") end
    if enchantId > 0 then return "E:" .. tostring(enchantId) end

    local text = tostring(professionKey or "UNKNOWN") .. ":" .. self:NormalizeText(recipe.name or "")
    local hash = 17
    local index
    for index = 1, string.len(text) do hash = math.mod((hash * 33) + string.byte(text, index), 2147483000) end
    return "R:" .. tostring(hash)
end

function OTLGM:EnsureCraftingDetailsDB()
    local craft = self:EnsureCraftingDB()
    if not craft then return nil end
    if type(craft.details) ~= "table" then craft.details = {} end
    return craft.details
end

function OTLGM:PruneCraftingDetails(maximum)
    local details = self:EnsureCraftingDetailsDB()
    maximum = math.max(100, tonumber(maximum) or 1200)
    if not details or self:Count(details) <= maximum then return 0 end
    local entries = {}
    local key, detail
    for key, detail in pairs(details) do table.insert(entries, { key = key, ts = tonumber(detail and detail.updatedAt) or 0 }) end
    table.sort(entries, function(left, right)
        if left.ts ~= right.ts then return left.ts < right.ts end
        return tostring(left.key) < tostring(right.key)
    end)
    local removeCount = table.getn(entries) - maximum
    local index
    for index = 1, removeCount do details[entries[index].key] = nil end
    return removeCount
end

function OTLGM:GetCraftingDetail(recipe, professionKey, knownDetails)
    local details = knownDetails or self:EnsureCraftingDetailsDB()
    local key = self:GetCraftingDetailKey(recipe, professionKey)
    return details and key and details[key] or nil
end

function OTLGM:GetCraftingDetailSearchText(recipe, professionKey, knownDetails)
    local detail = self:GetCraftingDetail(recipe, professionKey, knownDetails)
    if not detail then return "" end
    local parts = {}
    local index, line
    for index = 1, table.getn(detail.lines or {}) do
        line = detail.lines[index]
        if line.left and line.left ~= "" then table.insert(parts, line.left) end
        if line.right and line.right ~= "" then table.insert(parts, line.right) end
    end
    return table.concat(parts, " ")
end

function OTLGM:GetCraftingScannerTooltip()
    if self.runtime.craftingScanner then return self.runtime.craftingScanner end
    if not CreateFrame or not UIParent then return nil end
    local scanner = CreateFrame("GameTooltip", "OTLGM_CraftingScannerTooltip", UIParent, "GameTooltipTemplate")
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    self.runtime.craftingScanner = scanner
    return scanner
end

local function ReadTooltipLines(self, scanner)
    local lines = {}
    if not scanner or not scanner.NumLines or not getglobal then return lines end
    local total = math.min(DETAIL_MAX_LINES, tonumber(scanner:NumLines()) or 0)
    local index
    for index = 1, total do
        local leftRegion = getglobal(scanner:GetName() .. "TextLeft" .. tostring(index))
        local rightRegion = getglobal(scanner:GetName() .. "TextRight" .. tostring(index))
        local left = leftRegion and leftRegion.GetText and leftRegion:GetText() or ""
        local right = rightRegion and rightRegion.GetText and rightRegion:GetText() or ""
        left = self:SafeText(left, 180, false, false)
        right = self:SafeText(right, 120, false, false)
        if left ~= "" or right ~= "" then
            local lr, lg, lb = 1, 1, 1
            local rr, rg, rb = 1, 1, 1
            if leftRegion and leftRegion.GetTextColor then lr, lg, lb = leftRegion:GetTextColor() end
            if rightRegion and rightRegion.GetTextColor then rr, rg, rb = rightRegion:GetTextColor() end
            table.insert(lines, { left = left, right = right, lr = lr, lg = lg, lb = lb, rr = rr, rg = rg, rb = rb })
        end
    end
    return lines
end

local function ProfessionLabel(self, professionKey)
    local index, definition
    for index = 1, table.getn(self.professionDefinitions or {}) do
        definition = self.professionDefinitions[index]
        if definition.key == professionKey then return definition.label or professionKey end
    end
    return professionKey or ""
end

-- Vanilla does not expose an exact recipe-skill requirement API. Capture it
-- only when the native recipe tooltip states it explicitly; never infer a
-- number from recipe colour or the crafter's current rank.
local function ParseRequirement(self, lines, professionKey)
    local profession = self:NormalizeText(ProfessionLabel(self, professionKey))
    local index, line, text, normalized, _, _, value
    for index = 1, table.getn(lines or {}) do
        line = lines[index]
        text = self:SafeText(((line and line.left) or "") .. ((line and line.right and line.right ~= "") and (" " .. line.right) or ""), 180, false, false)
        normalized = self:NormalizeText(text)
        if normalized ~= "" and profession ~= "" and string.find(normalized, profession, 1, true)
            and string.find(normalized, "requires", 1, true) and not string.find(normalized, "requires level", 1, true) then
            _, _, value = string.find(text, "%((%d+)%)")
            if not value then _, _, value = string.find(text, "(%d+)%s*$") end
            value = tonumber(value) or 0
            if value > 0 and value <= 1000 then return value, text end
        end
    end
    return 0, ""
end

local function PopulateScanner(scanner, recipe, mode, sourceIndex, preferRecipe)
    scanner:ClearLines()
    local populated = false
    if preferRecipe and recipe.recipeLink and scanner.SetHyperlink then
        populated = pcall(scanner.SetHyperlink, scanner, recipe.recipeLink)
    elseif (tonumber(recipe.itemId) or 0) > 0 and recipe.itemLink and scanner.SetHyperlink then
        populated = pcall(scanner.SetHyperlink, scanner, recipe.itemLink)
    elseif mode == "TRADE" and sourceIndex and scanner.SetTradeSkillItem then
        populated = pcall(scanner.SetTradeSkillItem, scanner, sourceIndex)
    elseif mode == "CRAFT" and sourceIndex and scanner.SetCraftItem then
        populated = pcall(scanner.SetCraftItem, scanner, sourceIndex)
    end
    if not populated and recipe.recipeLink and scanner.SetHyperlink then populated = pcall(scanner.SetHyperlink, scanner, recipe.recipeLink) end
    return populated
end

function OTLGM:CaptureCraftingDetail(recipe, professionKey, mode, sourceIndex)
    if not recipe then return false end
    local scanner = self:GetCraftingScannerTooltip()
    if not scanner then return false end
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    local populated = PopulateScanner(scanner, recipe, mode, sourceIndex, false)
    if not populated then return false end

    local lines = ReadTooltipLines(self, scanner)
    if table.getn(lines) == 0 then return false end
    local requiredSkill, requirementText = ParseRequirement(self, lines, professionKey)
    if requiredSkill <= 0 and recipe.recipeLink then
        if PopulateScanner(scanner, recipe, mode, sourceIndex, true) then
            local requirementLines = ReadTooltipLines(self, scanner)
            requiredSkill, requirementText = ParseRequirement(self, requirementLines, professionKey)
            if table.getn(lines) == 0 then lines = requirementLines end
        end
    end
    local details = self:EnsureCraftingDetailsDB()
    local key = self:GetCraftingDetailKey(recipe, professionKey)
    if not details or not key then return false end
    local build = ""
    if GetBuildInfo then
        local ok, value = pcall(GetBuildInfo)
        if ok then build = tostring(value or "") end
    end
    local effectText = EffectSummary(self, recipe, lines)
    local detail = {
        key = key,
        lines = lines,
        locale = GetLocale and GetLocale() or "unknown",
        sourceBuild = build,
        source = mode or "LINK",
        updatedAt = self:Now(),
        detailHash = DetailHash(lines),
        completeness = table.getn(lines),
        requirementChecked = true,
        requiredSkill = requiredSkill,
        requirementText = requirementText,
        effectText = effectText,
    }
    details[key] = detail
    recipe.detailKey = key
    recipe.detailHash = detail.detailHash
    recipe.effectText = effectText
    recipe.requirementChecked = true
    if requiredSkill > 0 then recipe.requiredSkill = requiredSkill end
    if requirementText ~= "" then recipe.requirementText = requirementText end
    return true
end

function OTLGM:QueueOpenProfessionDetails(mode, profession)
    if not profession then return false end
    self.runtime = self.runtime or {}
    local queue = { items = {}, head = 1, mode = mode, professionKey = profession.key }
    local count = mode == "CRAFT" and GetNumCrafts and (tonumber(GetNumCrafts()) or 0)
        or (GetNumTradeSkills and (tonumber(GetNumTradeSkills()) or 0) or 0)
    local index
    for index = 1, count do
        local name, recipeType, itemLink
        if mode == "CRAFT" then
            if GetCraftInfo then name, _, recipeType = GetCraftInfo(index) end
            if GetCraftItemLink then itemLink = GetCraftItemLink(index) end
        else
            if GetTradeSkillInfo then name, recipeType = GetTradeSkillInfo(index) end
            if GetTradeSkillItemLink then itemLink = GetTradeSkillItemLink(index) end
        end
        if name and name ~= "" and recipeType ~= "header" then
            local itemId = ParseLinkID(itemLink, "item")
            local key = itemId > 0 and tostring(itemId) or self:NormalizeText(name)
            local recipe = profession.recipes and profession.recipes[key]
            if recipe then
                local existing = self:GetCraftingDetail(recipe, profession.key)
                if not existing or not existing.requirementChecked
                    or self:Now() - (tonumber(existing.updatedAt) or 0) > DETAIL_MAX_AGE then
                    table.insert(queue.items, { recipe = recipe, index = index })
                end
            end
        end
    end
    self.runtime.craftingDetailQueue = queue
    return table.getn(queue.items) > 0
end

function OTLGM:ProcessCraftingDetailQueue(maximum)
    local queue = self.runtime and self.runtime.craftingDetailQueue
    if not queue or queue.head > table.getn(queue.items) then return false end
    local windowOpen = (queue.mode == "TRADE" and TradeSkillFrame and TradeSkillFrame.IsShown and TradeSkillFrame:IsShown())
        or (queue.mode == "CRAFT" and CraftFrame and CraftFrame.IsShown and CraftFrame:IsShown())
    if not windowOpen then self.runtime.craftingDetailQueue = nil return false end
    maximum = math.max(1, math.min(8, tonumber(maximum) or 4))
    local processed, changed = 0, false
    while processed < maximum and queue.head <= table.getn(queue.items) do
        local job = queue.items[queue.head]
        queue.head = queue.head + 1
        processed = processed + 1
        if job and self:CaptureCraftingDetail(job.recipe, queue.professionKey, queue.mode, job.index) then changed = true queue.changed = true end
    end
    if queue.head > table.getn(queue.items) then
        self.runtime.craftingDetailQueue = nil
        if queue.changed then
            local craft = self:EnsureCraftingDB()
            local player = string.gsub(UnitName("player") or "", "%-.*$", "")
            local profession = craft and craft.characters and craft.characters[player] and craft.characters[player].professions and craft.characters[player].professions[queue.professionKey]
            if profession then
                profession.detailRevision = (tonumber(profession.detailRevision) or 0) + 1
                profession.lastSharedAt = 0
                if self.RehashCraftingProfession then self:RehashCraftingProfession(profession) end
                if self.QueueCraftingProfessionShare then self:QueueCraftingProfessionShare(player, queue.professionKey) end
            end
            if self.InvalidateCraftingSearchCache then self:InvalidateCraftingSearchCache() end
            self:PruneCraftingDetails(1200)
        end
    end
    return changed
end

local function AddCachedDetail(self, tooltip, detail)
    local index, line
    for index = 1, table.getn(detail and detail.lines or {}) do
        line = detail.lines[index]
        if line.right and line.right ~= "" then
            tooltip:AddDoubleLine(line.left or "", line.right, line.lr or 1, line.lg or 1, line.lb or 1, line.rr or 1, line.rg or 1, line.rb or 1)
        else
            tooltip:AddLine(line.left or "", line.lr or 1, line.lg or 1, line.lb or 1, true)
        end
    end
end

function OTLGM:ShowCraftingObjectTooltip(anchor, object, professionKey)
    if not anchor or not object or not GameTooltip then return end
    if self.InstallTooltipCompatibility160 then self:InstallTooltipCompatibility160() end
    self.runtime = self.runtime or {}
    if self.runtime.craftingTooltipBusy160 then return end
    self.runtime.craftingTooltipBusy160 = true
    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    pcall(GameTooltip.ClearLines, GameTooltip)
    local shown = false
    local link = object.itemLink
    if (tonumber(object.itemId) or 0) > 0 and GetItemInfo then
        local _, cachedLink = self:GetItemInfoSafe(object.itemId)
        if cachedLink and cachedLink ~= "" then link = cachedLink object.itemLink = cachedLink end
    end
    if link and GameTooltip.SetHyperlink then
        shown = pcall(GameTooltip.SetHyperlink, GameTooltip, link)
        shown = shown and (not GameTooltip.NumLines or (tonumber(GameTooltip:NumLines()) or 0) > 0)
    end
    if not shown and object.recipeLink and GameTooltip.SetHyperlink then
        shown = pcall(GameTooltip.SetHyperlink, GameTooltip, object.recipeLink)
        shown = shown and (not GameTooltip.NumLines or (tonumber(GameTooltip:NumLines()) or 0) > 0)
    end
    if not shown then
        local detail = self:GetCraftingDetail(object, professionKey)
        if detail then AddCachedDetail(self, GameTooltip, detail)
        elseif object.effectText and object.effectText ~= "" then
            GameTooltip:AddLine(object.name or "Crafting result", 1, 0.82, 0.30)
            GameTooltip:AddLine(object.effectText, 0.90, 0.90, 0.86, true)
        else
            GameTooltip:AddLine(object.name or "Crafting result", 1, 0.82, 0.30)
            if (tonumber(object.itemId) or 0) > 0 then
                GameTooltip:AddLine("Item details are not cached on this client yet. Hover the item in game or reopen this profession window.", 0.72, 0.72, 0.70, true)
            else
                GameTooltip:AddLine("Effect details are not cached yet. Ask the crafter to reopen this profession window.", 0.72, 0.72, 0.70, true)
            end
        end
    end
    GameTooltip:Show()
    self.runtime.craftingTooltipBusy160 = nil
end

function OTLGM:ShowCraftingResultTooltip(anchor, result)
    if not result or not result.recipe then return end
    self:ShowCraftingObjectTooltip(anchor, result.recipe, result.professionKey)
    if GameTooltip and result.crafters then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(tostring(table.getn(result.crafters)) .. " guild crafter" .. (table.getn(result.crafters) == 1 and "" or "s"), 0.76, 0.68, 0.46)
        GameTooltip:Show()
    end
end

function OTLGM:InitializeCraftingDetailsUI()
    local index, row
    for index = 1, table.getn(self.ui.craftingMaterialRows152 or {}) do
        row = self.ui.craftingMaterialRows152[index]
        row:EnableMouse(true)
        row:SetScript("OnEnter", function()
            if this.reagentData then OTLGM:ShowCraftingObjectTooltip(this, this.reagentData, this.professionKey) end
        end)
        row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    end
    if not self.ui.craftingResultHit160 and self.ui.craftingRecipeIcon152 then
        local parent = self.ui.craftingRecipeIcon152:GetParent()
        local hit = CreateFrame("Button", nil, parent)
        OTLGM:PrepareInteractiveControl170(hit, "button")
        hit:SetPoint("TOPLEFT", self.ui.craftingRecipeIcon152, "TOPLEFT", 0, 0)
        hit:SetWidth(42)
        hit:SetHeight(42)
        hit:SetFrameLevel(parent:GetFrameLevel() + 3)
        hit:SetScript("OnEnter", function()
            local result = OTLGM.ui and OTLGM.ui.craftingSelectedRecipeData
            if result then OTLGM:ShowCraftingResultTooltip(this, result) end
        end)
        hit:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        self.ui.craftingResultHit160 = hit
    end
end

OTLGM:RegisterModule("CraftingDetails", {
    localCapture = true,
    tooltipLines = DETAIL_MAX_LINES,
})
