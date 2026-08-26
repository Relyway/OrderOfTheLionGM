-- Local crafting result inspection. Standard item tooltips are preferred; a
-- hidden scanner captures enchant/custom-server lines while the profession
-- window is open so recipes without an output item still have useful details.

local DETAIL_MAX_LINES = 20
local DETAIL_MAX_AGE = 90 * 86400
local ENCHANT_DIAG_MAX_R24 = 40
local ENCHANT_CAPTURE_MAX_ATTEMPTS_R27 = 3

local function NormalizeEnchantEffectSourceR24(source)
    source = tostring(source or "")
    if source == "LOCAL_NATIVE" or source == "NATIVE_TOOLTIP" then return "LOCAL_NATIVE" end
    if source == "REMOTE_NATIVE" then return "REMOTE_NATIVE" end
    if source == "LEGACY_NATIVE" or source == "REMOTE_LEGACY" then return "LEGACY_NATIVE" end
    return "UNKNOWN"
end

local function TrustedEnchantEffectSourceR24(source)
    source = NormalizeEnchantEffectSourceR24(source)
    return source == "LOCAL_NATIVE" or source == "REMOTE_NATIVE" or source == "LEGACY_NATIVE"
end

function OTLGM:NormalizeEnchantEffectSourceR24(source)
    return NormalizeEnchantEffectSourceR24(source)
end

function OTLGM:IsTrustedEnchantEffectSourceR24(source)
    return TrustedEnchantEffectSourceR24(source)
end

local function EnchantDiagnosticPrintR24(text)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffcc33[Lion GM EnchantDiag]|r " .. tostring(text or "")) end
end

local function RecordEnchantDiagnosticR24(self, trigger, sourceIndex, recipeName, lines, effectText, source, outcome, note)
    local state = self.runtime and self.runtime.enchantDiagnosticsR24
    if not state or not state.enabled then return end
    state.entries = state.entries or {}
    local firstUseful = self:SafeText(effectText or "", 120, false, false)
    if firstUseful == "" then
        local i, text
        for i = 2, table.getn(lines or {}) do
            text = self:SafeText((((lines[i] and lines[i].left) or "") .. (((lines[i] and lines[i].right) or "") ~= "" and (" " .. lines[i].right) or "")), 120, false, false)
            if text ~= "" then firstUseful = text break end
        end
    end
    table.insert(state.entries, {
        ts = self:Now(), trigger = tostring(trigger or "?"), index = tonumber(sourceIndex) or 0,
        recipe = self:SafeText(recipeName or "", 80, false, false), lines = table.getn(lines or {}),
        effect = firstUseful, source = NormalizeEnchantEffectSourceR24(source), outcome = tostring(outcome or ""),
        note = self:SafeText(note or "", 100, false, false),
    })
    while table.getn(state.entries) > ENCHANT_DIAG_MAX_R24 do table.remove(state.entries, 1) end
end

function OTLGM:SetEnchantDiagnosticsR24(enabled)
    self.runtime = self.runtime or {}
    self.runtime.enchantDiagnosticsR24 = self.runtime.enchantDiagnosticsR24 or { entries = {} }
    self.runtime.enchantDiagnosticsR24.enabled = enabled and true or nil
    if enabled then self.runtime.enchantDiagnosticsR24.entries = {} end
end

function OTLGM:PrintEnchantDiagnosticsR24()
    local state = self.runtime and self.runtime.enchantDiagnosticsR24
    if not state or not state.enabled then EnchantDiagnosticPrintR24("Diagnostics are off. Use /otl enchantdiag on first.") return false end
    local rawName, rank, maxRank = "", 0, 0
    if self.ReadTradeSkillLine184 and TradeSkillFrame and TradeSkillFrame.IsShown and TradeSkillFrame:IsShown() then rawName, rank, maxRank = self:ReadTradeSkillLine184() end
    local selected = GetTradeSkillSelectionIndex and (tonumber(GetTradeSkillSelectionIndex()) or 0) or (TradeSkillFrame and tonumber(TradeSkillFrame.selectedSkill) or 0)
    local queue = self.runtime and self.runtime.craftingDetailQueue
    EnchantDiagnosticPrintR24("profession=" .. tostring(rawName or "") .. " " .. tostring(rank or 0) .. "/" .. tostring(maxRank or 0)
        .. " selected=" .. tostring(selected or 0)
        .. " SetTradeSkillItem=" .. tostring(GameTooltip and type(GameTooltip.SetTradeSkillItem) == "function" and "yes" or "no")
        .. " selectionHook=" .. tostring(self.runtime and self.runtime.enchantSelectionHookInstalledR24 and "yes" or "no")
        .. " updateHook=" .. tostring(self.runtime and self.runtime.enchantUpdateHookInstalledR27 and "yes" or "no")
        .. " r27Attempts=" .. tostring(self.runtime and self.runtime.craftingMetrics180 and self.runtime.craftingMetrics180.enchantCaptureAttemptsR27 or 0)
        .. " queue=" .. tostring(queue and (table.getn(queue.items or {}) - (tonumber(queue.head) or 1) + 1) or 0))
    local start = math.max(1, table.getn(state.entries or {}) - 14)
    local i, entry
    for i = start, table.getn(state.entries or {}) do
        entry = state.entries[i]
        EnchantDiagnosticPrintR24("#" .. tostring(i) .. " t=" .. tostring(entry.ts or 0) .. " trigger=" .. tostring(entry.trigger)
            .. " idx=" .. tostring(entry.index) .. " recipe=" .. tostring(entry.recipe) .. " lines=" .. tostring(entry.lines)
            .. " source=" .. tostring(entry.source) .. " result=" .. tostring(entry.outcome)
            .. ((entry.effect and entry.effect ~= "") and (" text=" .. entry.effect) or "")
            .. ((entry.note and entry.note ~= "") and (" note=" .. entry.note) or ""))
    end
    if table.getn(state.entries or {}) == 0 then EnchantDiagnosticPrintR24("No capture attempts recorded yet. Select an enchant and hover its result icon.") end
    return true
end

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
    if (tonumber(recipe and recipe.itemId) or 0) > 0 then return "" end
    local recipeName = self:NormalizeText(recipe and recipe.name or "")
    local reagentNames = {}
    local reagentIndex, reagent
    for reagentIndex = 1, table.getn(recipe and recipe.reagents or {}) do
        reagent = recipe.reagents[reagentIndex]
        if reagent and reagent.name then reagentNames[self:NormalizeText(reagent.name)] = true end
    end
    local bestText, bestScore = "", -1
    local index, line, text, normalized, skip, score, reagentName
    for index = 1, table.getn(lines or {}) do
        line = lines[index]
        text = self:SafeText(((line and line.left) or "") .. ((line and line.right and line.right ~= "") and (" " .. line.right) or ""), 220, false, false)
        normalized = self:NormalizeText(text)
        skip = text == "" or normalized == recipeName or normalized == "enchanting"
        if not skip and (string.find(normalized, "requires enchanting", 1, true)
            or string.find(normalized, "requires level", 1, true)
            or string.find(normalized, "sec cast", 1, true)
            or string.find(normalized, "second cast", 1, true)
            or string.find(normalized, "reagents:", 1, true)
            or string.find(normalized, "tools:", 1, true)
            or string.find(normalized, "vendor:", 1, true)
            or string.find(normalized, "value:", 1, true)
            or string.find(normalized, "cost:", 1, true)) then skip = true end
        if not skip then
            for reagentName in pairs(reagentNames) do
                if normalized == reagentName or string.find(normalized, reagentName .. " ", 1, true) == 1 then skip = true break end
            end
        end
        if not skip then
            score = math.min(120, string.len(text))
            if string.find(normalized, "permanently", 1, true) then score = score + 120 end
            if string.find(normalized, "enchant", 1, true) then score = score + 70 end
            if string.find(normalized, "additional", 1, true) then score = score + 45 end
            if string.find(normalized, "increase", 1, true) or string.find(normalized, "increases", 1, true) then score = score + 35 end
            if string.find(normalized, "points", 1, true) then score = score + 20 end
            if string.find(text, ".", 1, true) then score = score + 10 end
            if score > bestScore then bestScore, bestText = score, text end
        end
    end
    return self:Utf8Truncate(bestText, 180)
end

local function AppendUniqueTooltipLines(self, destination, source)
    local seen = {}
    local index, line, key
    for index = 1, table.getn(destination or {}) do
        line = destination[index]
        key = self:NormalizeText(tostring(line and line.left or "") .. " " .. tostring(line and line.right or ""))
        if key ~= "" then seen[key] = true end
    end
    for index = 1, table.getn(source or {}) do
        line = source[index]
        key = self:NormalizeText(tostring(line and line.left or "") .. " " .. tostring(line and line.right or ""))
        if key ~= "" and not seen[key] then
            seen[key] = true
            table.insert(destination, line)
        end
    end
end

local function FriendlyEnchantFallback(self, recipe, professionKey)
    if tostring(professionKey or "") ~= "ENCHANTING" then return "" end
    local name = self:SafeText(recipe and recipe.name or "", 100, false, false)
    local _, _, target, effect = string.find(name, "^Enchant%s+(.+)%s+%-%s+(.+)$")
    if target and effect then
        target = string.lower(self:SafeText(target, 32, false, false))
        effect = self:SafeText(effect, 70, false, false)
        return self:Utf8Truncate("Applies " .. effect .. " to " .. target .. ".", 160)
    end
    return ""
end

function OTLGM:GetFriendlyCraftingEffect183(recipe, professionKey)
    if not recipe then return "" end
    local source = NormalizeEnchantEffectSourceR24(recipe.effectSource183)
    local effectText = self:SafeText(recipe.effectText or "", 180, false, false)
    if effectText == "" and self.GetCraftingDetail then
        local cached = self:GetCraftingDetail(recipe, professionKey)
        effectText = self:SafeText(cached and cached.effectText or "", 180, false, false)
        source = NormalizeEnchantEffectSourceR24(cached and cached.effectSource183 or source)
    end
    if self.NormalizeText and self:NormalizeText(effectText) == self:NormalizeText(recipe.name or "") then effectText = "" end
    local derived = FriendlyEnchantFallback(self, recipe, professionKey)
    if effectText ~= "" and derived ~= "" and self:NormalizeText(effectText) == self:NormalizeText(derived)
        and not TrustedEnchantEffectSourceR24(source) then effectText = "" end
    if effectText ~= "" and TrustedEnchantEffectSourceR24(source) then return effectText end
    if tostring(professionKey or "") == "ENCHANTING" then
        return "Exact effect pending; select this recipe in Enchanting, then hover its result icon if needed."
    end
    return ""
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
    scanner:SetAlpha(0)
    scanner:ClearAllPoints()
    scanner:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", -1000, 1000)
    scanner:Hide()
    self.runtime.craftingScanner = scanner
    return scanner
end

local function ReadTooltipLines(self, scanner, keepVisible)
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
    if not keepVisible and scanner.Hide then scanner:Hide() end
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

local function IsPersonalCraftOutputR27(self, recipe, lines)
    if (tonumber(recipe and recipe.itemId) or 0) <= 0 then return false end
    local localized = ITEM_BIND_ON_PICKUP and self:NormalizeText(ITEM_BIND_ON_PICKUP) or ""
    local index, line, normalized
    for index = 1, table.getn(lines or {}) do
        line = lines[index]
        normalized = self:NormalizeText(tostring(line and line.left or "") .. " " .. tostring(line and line.right or ""))
        if normalized ~= "" then
            if localized ~= "" and normalized == localized then return true end
            if normalized == "binds when picked up" or normalized == "bind on pickup" then return true end
        end
    end
    return false
end

local function PopulateScanner(scanner, recipe, mode, sourceIndex, preferRecipe)
    scanner:ClearLines()
    local populated, method = false, "NONE"
    if preferRecipe and recipe.recipeLink and scanner.SetHyperlink then
        populated = pcall(scanner.SetHyperlink, scanner, recipe.recipeLink)
        method = "SetHyperlink(recipe)"
    elseif (tonumber(recipe.itemId) or 0) > 0 and recipe.itemLink and scanner.SetHyperlink then
        populated = pcall(scanner.SetHyperlink, scanner, recipe.itemLink)
        method = "SetHyperlink(item)"
    elseif mode == "TRADE" and sourceIndex and scanner.SetTradeSkillItem then
        populated = pcall(scanner.SetTradeSkillItem, scanner, sourceIndex)
        method = "SetTradeSkillItem"
    elseif mode == "CRAFT" and sourceIndex and scanner.SetCraftItem then
        populated = pcall(scanner.SetCraftItem, scanner, sourceIndex)
        method = "SetCraftItem"
    end
    if not populated and recipe.recipeLink and scanner.SetHyperlink then
        populated = pcall(scanner.SetHyperlink, scanner, recipe.recipeLink)
        method = "SetHyperlink(recipe-fallback)"
    end
    -- Several 1.12-derived clients do not populate GameTooltip font strings until
    -- the tooltip is shown at least once. The scanner is fully transparent and
    -- anchored off-screen, so this cannot flash over the player's profession UI.
    if populated and scanner.Show then scanner:Show() end
    return populated, method
end

function OTLGM:CaptureCraftingDetail(recipe, professionKey, mode, sourceIndex)
    if not recipe then return false end
    local scanner = self:GetCraftingScannerTooltip()
    if not scanner then return false end
    scanner:SetOwner(UIParent, "ANCHOR_NONE")

    -- Capture both native views. On Octo/Vanilla the visible TradeSkill recipe
    -- tooltip can contain the exact enchant sentence even when the output item
    -- does not exist, while the recipe hyperlink may expose complementary lines.
    local lines = {}
    local populatedPrimary, primaryMethod = PopulateScanner(scanner, recipe, mode, sourceIndex, false)
    if populatedPrimary then AppendUniqueTooltipLines(self, lines, ReadTooltipLines(self, scanner)) end
    local nativeEffect = EffectSummary(self, recipe, lines)
    local itemId = tonumber(recipe.itemId) or 0
    local secondaryMethod = ""
    if recipe.recipeLink and (itemId <= 0 or table.getn(lines) == 0 or nativeEffect == "") then
        local populatedSecondary
        populatedSecondary, secondaryMethod = PopulateScanner(scanner, recipe, mode, sourceIndex, true)
        if populatedSecondary then
            AppendUniqueTooltipLines(self, lines, ReadTooltipLines(self, scanner))
            nativeEffect = EffectSummary(self, recipe, lines)
        end
    end

    local requiredSkill, requirementText = ParseRequirement(self, lines, professionKey)
    local newlyPersonalOnlyR27 = (not recipe.personalOnlyR27) and IsPersonalCraftOutputR27(self, recipe, lines) or false
    local personalOnlyR27 = newlyPersonalOnlyR27 or (recipe.personalOnlyR27 and true or false)
    if tostring(professionKey or "") == "ENCHANTING" then
        local methodNote = tostring(primaryMethod or "NONE")
        if secondaryMethod ~= "" then methodNote = methodNote .. "+" .. secondaryMethod end
        RecordEnchantDiagnosticR24(self, "hidden-batch", sourceIndex, recipe.name, lines, nativeEffect, nativeEffect ~= "" and "LOCAL_NATIVE" or "UNKNOWN", nativeEffect ~= "" and "captured" or "miss", methodNote)
        self.runtime = self.runtime or {}
        self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
        if nativeEffect ~= "" then
            self.runtime.craftingMetrics180.nativeEnchantEffectCaptures184 = (tonumber(self.runtime.craftingMetrics180.nativeEnchantEffectCaptures184) or 0) + 1
        else
            self.runtime.craftingMetrics180.nativeEnchantEffectMisses184 = (tonumber(self.runtime.craftingMetrics180.nativeEnchantEffectMisses184) or 0) + 1
        end
    end
    local details = self:EnsureCraftingDetailsDB()
    local key = self:GetCraftingDetailKey(recipe, professionKey)
    if not details or not key then return false end
    local previous = details[key]
    local previousEffect = self:SafeText(previous and previous.effectText or "", 180, false, false)
    local previousSource = NormalizeEnchantEffectSourceR24(previous and previous.effectSource183)
    local derived = FriendlyEnchantFallback(self, recipe, professionKey)
    if previousEffect ~= "" and derived ~= "" and self:NormalizeText(previousEffect) == self:NormalizeText(derived)
        and not TrustedEnchantEffectSourceR24(previousSource) then
        previousEffect, previousSource = "", ""
    end
    local effectText = nativeEffect
    local effectSource = nativeEffect ~= "" and "LOCAL_NATIVE" or (tostring(professionKey or "") == "ENCHANTING" and "UNKNOWN" or "")
    if effectText == "" and previousEffect ~= "" and TrustedEnchantEffectSourceR24(previousSource) then
        effectText = previousEffect
        effectSource = previousSource
    end
    if table.getn(lines) == 0 and effectText == "" and requiredSkill <= 0 then return false end

    local build = ""
    if GetBuildInfo then
        local ok, value = pcall(GetBuildInfo)
        if ok then build = tostring(value or "") end
    end
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
        effectChecked = effectText ~= "",
        requiredSkill = requiredSkill,
        requirementText = requirementText,
        effectText = effectText,
        effectSource183 = effectSource,
        personalOnlyR27 = personalOnlyR27 and true or nil,
        personalReasonR27 = personalOnlyR27 and "BOP_OUTPUT" or nil,
    }
    details[key] = detail
    recipe.detailKey = key
    recipe.detailHash = detail.detailHash
    recipe.effectText = effectText ~= "" and effectText or nil
    recipe.effectSource183 = effectSource ~= "" and effectSource or nil
    recipe.requirementChecked = true
    recipe.effectChecked = effectText ~= ""
    if personalOnlyR27 then
        recipe.personalOnlyR27 = true
        recipe.personalReasonR27 = "BOP_OUTPUT"
        if newlyPersonalOnlyR27 then
            self.runtime = self.runtime or {}
            self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
            self.runtime.craftingMetrics180.personalOnlyRecipesR27 = (tonumber(self.runtime.craftingMetrics180.personalOnlyRecipesR27) or 0) + 1
        end
    end
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
                local existingEffect = self:SafeText(existing and existing.effectText or "", 180, false, false)
                local existingSource = NormalizeEnchantEffectSourceR24(existing and existing.effectSource183)
                local derived = FriendlyEnchantFallback(self, recipe, profession.key)
                local derivedStored = existingEffect ~= "" and derived ~= ""
                    and self:NormalizeText(existingEffect) == self:NormalizeText(derived)
                    and not TrustedEnchantEffectSourceR24(existingSource)
                local needsEffect = tostring(profession.key or "") == "ENCHANTING"
                    and (not existing or existingEffect == "" or derivedStored or not existing.effectChecked)
                if not existing or not existing.requirementChecked or needsEffect
                    or self:Now() - (tonumber(existing.updatedAt) or 0) > DETAIL_MAX_AGE then
                    table.insert(queue.items, { recipe = recipe, index = index })
                end
            end
        end
    end
    local pending = table.getn(queue.items) > 0
    -- Never retain an empty detail queue.  The shared scheduler treats a live
    -- queue as work; leaving { items = {}, head = 1 } behind would keep the
    -- addon awake forever even though there is nothing to capture.
    self.runtime.craftingDetailQueue = pending and queue or nil
    if pending and self.WakeScheduler180 then self:WakeScheduler180("crafting-detail-capture") end
    return pending
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

local function CraftingDetailContainsText183(self, detail, value)
    local wanted = self:NormalizeText(value or "")
    if wanted == "" then return false end
    local index, line, combined
    for index = 1, table.getn(detail and detail.lines or {}) do
        line = detail.lines[index]
        combined = self:NormalizeText(tostring(line and line.left or "") .. " " .. tostring(line and line.right or ""))
        if combined == wanted or string.find(combined, wanted, 1, true) then return true end
    end
    return false
end

function OTLGM:ShowCraftingObjectTooltip(anchor, object, professionKey)
    if not anchor or not object or not GameTooltip then return end
    if self.InstallTooltipCompatibility160 then self:InstallTooltipCompatibility160() end
    self.runtime = self.runtime or {}
    if self.runtime.craftingTooltipBusy160 then return end
    self.runtime.craftingTooltipBusy160 = true
    local tooltipAnchor = "ANCHOR_RIGHT"
    if anchor.GetCenter and UIParent and UIParent.GetCenter then
        local ax = anchor:GetCenter()
        local ux = UIParent:GetCenter()
        -- Put the tooltip away from the Details column: anchors on the right
        -- half open to the left, anchors on the left half open to the right.
        if ax and ux and ax > ux then tooltipAnchor = "ANCHOR_LEFT" end
    end
    GameTooltip:SetOwner(anchor, tooltipAnchor)
    if GameTooltip.SetClampedToScreen then GameTooltip:SetClampedToScreen(true) end
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
        local friendlyEffect = self.GetFriendlyCraftingEffect183 and self:GetFriendlyCraftingEffect183(object, professionKey)
            or self:SafeText(object.effectText or "", 180, false, false)
        if detail and table.getn(detail.lines or {}) > 0 then
            AddCachedDetail(self, GameTooltip, detail)
            if friendlyEffect ~= "" and not CraftingDetailContainsText183(self, detail, friendlyEffect) then
                GameTooltip:AddLine(friendlyEffect, 0.90, 0.90, 0.86, true)
            end
        elseif friendlyEffect ~= "" then
            GameTooltip:AddLine(object.name or "Crafting result", 1, 0.82, 0.30)
            GameTooltip:AddLine(friendlyEffect, 0.90, 0.90, 0.86, true)
        else
            GameTooltip:AddLine(object.name or "Crafting result", 1, 0.82, 0.30)
            if (tonumber(object.itemId) or 0) > 0 then
                GameTooltip:AddLine("Item details are not available yet. Hover the item in game or reopen this profession window.", 0.72, 0.72, 0.70, true)
            else
                GameTooltip:AddLine("This enchant has no cached native effect text yet. Reopen Enchanting on a character who knows it to refresh the shared details.", 0.72, 0.72, 0.70, true)
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

function OTLGM:CommitVisibleCraftingTooltipBatch185(professionKey)
    self.runtime = self.runtime or {}
    local dirty = self.runtime.visibleCraftingTooltipDirty185
    if type(dirty) ~= "table" or not dirty[professionKey] then return false end
    dirty[professionKey] = nil
    local craft = self:EnsureCraftingDB()
    local player = string.gsub(UnitName("player") or "", "%-.*$", "")
    local profession = craft and craft.characters and craft.characters[player]
        and craft.characters[player].professions and craft.characters[player].professions[professionKey]
    if not profession then return false end
    -- A burst of hover captures changes many recipe detail rows. Commit the
    -- expensive derived state once at the trailing edge instead of doing a full
    -- profession hash/completeness/network/UI pass for every hovered recipe.
    profession.lastSharedAt = 0
    if profession.hashDirty184 and self.RehashCraftingProfession then
        self:RehashCraftingProfession(profession)
        profession.hashDirty184 = nil
    end
    if self.QueueCraftingProfessionShare then self:QueueCraftingProfessionShare(player, professionKey) end
    if self.InvalidateCraftingSearchCache then self:InvalidateCraftingSearchCache() end
    if self.InvalidateGlobalSearchCache185 then self:InvalidateGlobalSearchCache185("crafting-tooltip") end
    if self.ui and self.ui.main and self.ui.main:IsVisible() and self.ui.currentPage == "professions" and self.RefreshProfessionsPage then
        self:RefreshProfessionsPage()
    end
    self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
    self.runtime.craftingMetrics180.visibleEnchantBatchCommits185 = (tonumber(self.runtime.craftingMetrics180.visibleEnchantBatchCommits185) or 0) + 1
    return true
end

function OTLGM:ScheduleVisibleCraftingTooltipCommit185(professionKey)
    if not professionKey or professionKey == "" then return false end
    self.runtime = self.runtime or {}
    self.runtime.visibleCraftingTooltipDirty185 = self.runtime.visibleCraftingTooltipDirty185 or {}
    self.runtime.visibleCraftingTooltipDirty185[professionKey] = true
    if self.ScheduleAfter180 then
        return self:ScheduleAfter180("crafting-visible-commit:" .. tostring(professionKey), 0.35, function(owner)
            owner:CommitVisibleCraftingTooltipBatch185(professionKey)
        end, 82)
    end
    return self:CommitVisibleCraftingTooltipBatch185(professionKey)
end

local function ResolveOpenTradeRecipeR24(self, sourceIndex)
    sourceIndex = tonumber(sourceIndex) or 0
    if sourceIndex <= 0 or not GetTradeSkillInfo then return nil end
    local name, recipeType = GetTradeSkillInfo(sourceIndex)
    if not name or name == "" or recipeType == "header" then return nil end
    local professionKey, profession
    if self.GetOpenTradeSkillProfession184 then professionKey, profession = self:GetOpenTradeSkillProfession184() end
    if not professionKey or not profession or not profession.recipes then return nil end
    local itemLink = GetTradeSkillItemLink and GetTradeSkillItemLink(sourceIndex) or nil
    local itemId = ParseLinkID(itemLink, "item")
    local recipeKey = itemId > 0 and tostring(itemId) or self:NormalizeText(name)
    local recipe = profession.recipes[recipeKey]
    if not recipe then
        local key, candidate
        for key, candidate in pairs(profession.recipes) do
            if self:NormalizeText(candidate and candidate.name or "") == self:NormalizeText(name) then recipe = candidate break end
        end
    end
    if not recipe then return nil end
    return professionKey, profession, recipe, name
end

local function ResolveOpenCraftRecipeR43(self, sourceIndex)
    sourceIndex = tonumber(sourceIndex) or 0
    if sourceIndex <= 0 or not GetCraftInfo then return nil end
    local name, _, recipeType = GetCraftInfo(sourceIndex)
    if not name or name == "" or recipeType == "header" then return nil end
    local professionKey, profession
    if self.GetOpenCraftProfessionR43 then professionKey, profession = self:GetOpenCraftProfessionR43() end
    if not professionKey or not profession or not profession.recipes then return nil end
    local itemLink = GetCraftItemLink and GetCraftItemLink(sourceIndex) or nil
    local itemId = ParseLinkID(itemLink, "item")
    local recipeKey = itemId > 0 and tostring(itemId) or self:NormalizeText(name)
    local recipe = profession.recipes[recipeKey]
    if not recipe then
        local key, candidate
        for key, candidate in pairs(profession.recipes) do
            if self:NormalizeText(candidate and candidate.name or "") == self:NormalizeText(name) then recipe = candidate break end
        end
    end
    if not recipe then return nil end
    return professionKey, profession, recipe, name
end

local function CommitNativeEnchantDescriptionR43(self, mode, sourceIndex, description, trigger)
    local professionKey, profession, recipe, name
    if mode == "CRAFT" then
        professionKey, profession, recipe, name = ResolveOpenCraftRecipeR43(self, sourceIndex)
    else
        professionKey, profession, recipe, name = ResolveOpenTradeRecipeR24(self, sourceIndex)
    end
    if professionKey ~= "ENCHANTING" or not profession or not recipe then return false, "recipe-unresolved" end
    local nativeEffect = self:SafeText(description or "", 180, false, false)
    if nativeEffect == "" then return false, "description-empty" end
    if self:NormalizeText(nativeEffect) == self:NormalizeText(name or recipe.name or "") then return false, "description-title-only" end

    local details = self:EnsureCraftingDetailsDB()
    local detailKey = self:GetCraftingDetailKey(recipe, professionKey)
    if not details or not detailKey then return false, "detail-db-missing" end
    local previous = details[detailKey]
    local previousText = self:SafeText(previous and previous.effectText or recipe.effectText or "", 180, false, false)
    local previousSource = NormalizeEnchantEffectSourceR24(previous and previous.effectSource183 or recipe.effectSource183)
    if previousText == nativeEffect and previousSource == "LOCAL_NATIVE" then return true, "cached" end

    local lines = {}
    if previous and type(previous.lines) == "table" then AppendUniqueTooltipLines(self, lines, previous.lines) end
    AppendUniqueTooltipLines(self, lines, { { left = nativeEffect, right = "" } })
    local detail = previous or {}
    detail.key = detailKey
    local capturedNameR44 = self:SafeText(name or recipe.name or "", 100, false, false)
    if capturedNameR44 ~= "" then
        detail.recipeName = capturedNameR44
        if not recipe.name or self:NormalizeText(recipe.name) == "" then recipe.name = capturedNameR44 end
    end
    detail.lines = lines
    detail.locale = GetLocale and GetLocale() or "unknown"
    detail.source = mode == "CRAFT" and "CRAFT_DESCRIPTION" or "TRADE_DESCRIPTION"
    detail.updatedAt = self:Now()
    detail.detailHash = DetailHash(lines)
    detail.completeness = math.max(1, table.getn(lines))
    detail.effectChecked = true
    detail.effectText = nativeEffect
    detail.effectSource183 = "LOCAL_NATIVE"
    if not detail.requirementChecked then detail.requirementChecked = recipe.requirementChecked and true or false end
    if (tonumber(detail.requiredSkill) or 0) <= 0 and (tonumber(recipe.requiredSkill) or 0) > 0 then detail.requiredSkill = recipe.requiredSkill end
    if (not detail.requirementText or detail.requirementText == "") and recipe.requirementText then detail.requirementText = recipe.requirementText end
    details[detailKey] = detail

    recipe.detailKey = detailKey
    recipe.detailHash = detail.detailHash
    recipe.effectText = nativeEffect
    recipe.effectSource183 = "LOCAL_NATIVE"
    recipe.effectChecked = true
    profession.detailRevision = (tonumber(profession.detailRevision) or 0) + 1
    profession.hashDirty184 = true

    self.runtime = self.runtime or {}
    self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
    local metrics = self.runtime.craftingMetrics180
    metrics.nativeEnchantDescriptionCapturesR43 = (tonumber(metrics.nativeEnchantDescriptionCapturesR43) or 0) + 1
    metrics.nativeEnchantDescriptionLastModeR43 = tostring(mode or "?")
    metrics.nativeEnchantDescriptionLastOutcomeR43 = "captured"
    if self.ScheduleVisibleCraftingTooltipCommit185 then self:ScheduleVisibleCraftingTooltipCommit185(professionKey) end
    RecordEnchantDiagnosticR24(self, trigger or "native-description", sourceIndex, name or recipe.name, lines, nativeEffect, "LOCAL_NATIVE", "captured", tostring(mode or "?") .. "_DESCRIPTION")
    return true, "captured"
end

local function ProbeNativeEnchantDescriptionR43(self, mode, sourceIndex, trigger)
    self.runtime = self.runtime or {}
    self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
    local metrics = self.runtime.craftingMetrics180
    metrics.nativeEnchantDescriptionAttemptsR43 = (tonumber(metrics.nativeEnchantDescriptionAttemptsR43) or 0) + 1
    metrics.nativeEnchantDescriptionLastModeR43 = tostring(mode or "?")

    local description = nil
    local ok, value = false, nil
    if mode == "CRAFT" and type(GetCraftDescription) == "function" then
        ok, value = pcall(GetCraftDescription, sourceIndex)
    elseif mode == "TRADE" and type(GetTradeSkillDescription) == "function" then
        ok, value = pcall(GetTradeSkillDescription, sourceIndex)
    else
        metrics.nativeEnchantDescriptionMissesR43 = (tonumber(metrics.nativeEnchantDescriptionMissesR43) or 0) + 1
        metrics.nativeEnchantDescriptionLastOutcomeR43 = "api-missing"
        return false, "api-missing"
    end
    if ok then description = value end
    if not ok then
        metrics.nativeEnchantDescriptionMissesR43 = (tonumber(metrics.nativeEnchantDescriptionMissesR43) or 0) + 1
        metrics.nativeEnchantDescriptionLastOutcomeR43 = "api-error"
        return false, "api-error"
    end
    local captured, outcome = CommitNativeEnchantDescriptionR43(self, mode, sourceIndex, description, trigger)
    if captured then
        metrics.nativeEnchantDescriptionLastOutcomeR43 = outcome or "captured"
        return true, outcome
    end
    metrics.nativeEnchantDescriptionMissesR43 = (tonumber(metrics.nativeEnchantDescriptionMissesR43) or 0) + 1
    metrics.nativeEnchantDescriptionLastOutcomeR43 = tostring(outcome or "description-miss")
    return false, outcome or "description-miss"
end

local function CommitTradeSkillNativeLinesR24(self, sourceIndex, lines, detailSource, trigger, requireExactTitle)
    local professionKey, profession, recipe, name = ResolveOpenTradeRecipeR24(self, sourceIndex)
    if not professionKey then return false end
    local tooltipTitle = self:NormalizeText(lines[1] and lines[1].left or "")
    if requireExactTitle and (tooltipTitle == "" or tooltipTitle ~= self:NormalizeText(name)) then
        RecordEnchantDiagnosticR24(self, trigger, sourceIndex, name, lines, "", "UNKNOWN", "rejected", "GameTooltip.SetTradeSkillItem/title-mismatch")
        return false
    end
    local nativeEffect = EffectSummary(self, recipe, lines)
    if nativeEffect == "" then
        RecordEnchantDiagnosticR24(self, trigger, sourceIndex, name, lines, "", "UNKNOWN", "miss", tostring(detailSource or "") .. "/GameTooltip.SetTradeSkillItem")
        return false
    end
    local details = self:EnsureCraftingDetailsDB()
    local detailKey = self:GetCraftingDetailKey(recipe, professionKey)
    if not details or not detailKey then return false end
    local previous = details[detailKey]
    local previousText = self:SafeText(previous and previous.effectText or recipe.effectText or "", 180, false, false)
    local previousSource = NormalizeEnchantEffectSourceR24(previous and previous.effectSource183 or recipe.effectSource183)
    if previousText == nativeEffect and previousSource == "LOCAL_NATIVE" then
        RecordEnchantDiagnosticR24(self, trigger, sourceIndex, name, lines, nativeEffect, previousSource, "unchanged", tostring(detailSource or "") .. "/GameTooltip.SetTradeSkillItem")
        return false
    end

    local requiredSkill, requirementText = ParseRequirement(self, lines, professionKey)
    local detail = previous or {}
    detail.key = detailKey
    detail.lines = lines
    detail.locale = GetLocale and GetLocale() or "unknown"
    detail.source = detailSource or "VISIBLE_TRADE_TOOLTIP"
    detail.updatedAt = self:Now()
    detail.detailHash = DetailHash(lines)
    detail.completeness = table.getn(lines)
    detail.requirementChecked = true
    detail.effectChecked = true
    detail.effectText = nativeEffect
    detail.effectSource183 = "LOCAL_NATIVE"
    if requiredSkill > 0 then detail.requiredSkill = requiredSkill end
    if requirementText ~= "" then detail.requirementText = requirementText end
    details[detailKey] = detail

    recipe.detailKey = detailKey
    recipe.detailHash = detail.detailHash
    recipe.effectText = nativeEffect
    recipe.effectSource183 = "LOCAL_NATIVE"
    recipe.effectChecked = true
    recipe.requirementChecked = true
    if requiredSkill > 0 then recipe.requiredSkill = requiredSkill end
    if requirementText ~= "" then recipe.requirementText = requirementText end

    self.runtime = self.runtime or {}
    self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
    self.runtime.craftingMetrics180.visibleEnchantEffectCaptures184 = (tonumber(self.runtime.craftingMetrics180.visibleEnchantEffectCaptures184) or 0) + 1
    if trigger == "selection-probe" then
        self.runtime.craftingMetrics180.selectedEnchantEffectCapturesR24 = (tonumber(self.runtime.craftingMetrics180.selectedEnchantEffectCapturesR24) or 0) + 1
    end
    profession.detailRevision = (tonumber(profession.detailRevision) or 0) + 1
    profession.hashDirty184 = true
    self:ScheduleVisibleCraftingTooltipCommit185(professionKey)
    RecordEnchantDiagnosticR24(self, trigger, sourceIndex, name, lines, nativeEffect, "LOCAL_NATIVE", "captured", tostring(detailSource or "") .. "/GameTooltip.SetTradeSkillItem")
    return true
end

function OTLGM:CaptureVisibleTradeSkillTooltip184(sourceIndex)
    sourceIndex = tonumber(sourceIndex) or 0
    if sourceIndex <= 0 or not GameTooltip or not GameTooltip.IsShown or not GameTooltip:IsShown() then return false end
    if not GetTradeSkillLine or not GetTradeSkillInfo then return false end
    local professionKey = self.GetOpenTradeSkillProfession184 and self:GetOpenTradeSkillProfession184() or nil
    if professionKey ~= "ENCHANTING" then return false end
    local lines = ReadTooltipLines(self, GameTooltip, true)
    return CommitTradeSkillNativeLinesR24(self, sourceIndex, lines, "VISIBLE_TRADE_TOOLTIP", "visible-hover", true)
end

function OTLGM:ProbeSelectedTradeSkillNativeR24(reason)
    if not GameTooltip or type(GameTooltip.SetTradeSkillItem) ~= "function" then return false end
    if not GetTradeSkillLine or not GetTradeSkillInfo then return false end
    local professionKey = self.GetOpenTradeSkillProfession184 and self:GetOpenTradeSkillProfession184() or nil
    if professionKey ~= "ENCHANTING" then return false end
    local sourceIndex = 0
    if GetTradeSkillSelectionIndex then
        sourceIndex = tonumber(GetTradeSkillSelectionIndex()) or 0
    elseif TradeSkillFrame then
        sourceIndex = tonumber(TradeSkillFrame.selectedSkill) or 0
    end
    local _, _, _, name = ResolveOpenTradeRecipeR24(self, sourceIndex)
    if sourceIndex <= 0 or not name then return false end

    -- Never steal a tooltip the player is already reading. A real hover is the
    -- strongest signal and the SetTradeSkillItem hook will capture it separately.
    if GameTooltip.IsShown and GameTooltip:IsShown() then
        local visibleLines = ReadTooltipLines(self, GameTooltip, true)
        local title = self:NormalizeText(visibleLines[1] and visibleLines[1].left or "")
        if title == self:NormalizeText(name) then
            return CommitTradeSkillNativeLinesR24(self, sourceIndex, visibleLines, "VISIBLE_TRADE_TOOLTIP", "selection-visible", true)
        end
        RecordEnchantDiagnosticR24(self, "selection-probe", sourceIndex, name, visibleLines, "", "UNKNOWN", "skipped", "GameTooltip-busy")
        return false
    end

    local oldAlpha = GameTooltip.GetAlpha and GameTooltip:GetAlpha() or 1
    self.runtime = self.runtime or {}
    self.runtime.enchantSelectionProbeActiveR24 = true
    GameTooltip:SetOwner(TradeSkillFrame or UIParent, "ANCHOR_NONE")
    if GameTooltip.SetAlpha then GameTooltip:SetAlpha(0) end
    if GameTooltip.ClearLines then GameTooltip:ClearLines() end
    local ok, problem = pcall(GameTooltip.SetTradeSkillItem, GameTooltip, sourceIndex)
    if ok and GameTooltip.Show then GameTooltip:Show() end
    local lines = ok and ReadTooltipLines(self, GameTooltip, false) or {}
    if GameTooltip.SetAlpha then GameTooltip:SetAlpha(oldAlpha or 1) end
    if GameTooltip.Hide then GameTooltip:Hide() end
    self.runtime.enchantSelectionProbeActiveR24 = nil
    if not ok then
        RecordEnchantDiagnosticR24(self, "selection-probe", sourceIndex, name, lines, "", "UNKNOWN", "error", tostring(problem))
        return false
    end
    local captured = CommitTradeSkillNativeLinesR24(self, sourceIndex, lines, "SELECTED_GAME_TOOLTIP", "selection-probe", true)
    if not captured then
        self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
        self.runtime.craftingMetrics180.selectedEnchantEffectMissesR24 = (tonumber(self.runtime.craftingMetrics180.selectedEnchantEffectMissesR24) or 0) + 1
    end
    return captured
end

local function RecordEnchantAttemptR27(self, outcome)
    self.runtime = self.runtime or {}
    self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
    local metrics = self.runtime.craftingMetrics180
    metrics.enchantCaptureAttemptsR27 = (tonumber(metrics.enchantCaptureAttemptsR27) or 0) + 1
    metrics.enchantCaptureAbortReasonsR27 = metrics.enchantCaptureAbortReasonsR27 or {}
    if outcome and outcome ~= "captured" and outcome ~= "cached" then
        metrics.enchantCaptureAbortReasonsR27[outcome] = (tonumber(metrics.enchantCaptureAbortReasonsR27[outcome]) or 0) + 1
        metrics.enchantCaptureLastAbortR27 = tostring(outcome)
    end
end

function OTLGM:RunSelectedEnchantCaptureR27(reason, attempt)
    attempt = math.max(1, math.min(ENCHANT_CAPTURE_MAX_ATTEMPTS_R27, tonumber(attempt) or 1))
    local trigger = "r27-" .. tostring(reason or "event") .. "-" .. tostring(attempt)
    -- R31: OctoWoW can fire TRADE_SKILL_SHOW/UPDATE and keep the 1.12
    -- TradeSkill APIs populated even when the stock TradeSkillFrame reports
    -- hidden. Visibility is presentation state, not proof that the native API
    -- is unavailable. Gate on the actual APIs/profession below instead.
    local rawName = self.ReadTradeSkillLine184 and self:ReadTradeSkillLine184() or ""
    local professionKey = self.GetOpenTradeSkillProfession184 and self:GetOpenTradeSkillProfession184() or nil
    if professionKey ~= "ENCHANTING" then
        RecordEnchantAttemptR27(self, rawName == "" and "profession-empty" or "not-enchanting")
        return false, rawName == "" and "profession-empty" or "not-enchanting"
    end
    if self.InstallVisibleCraftingTooltipCapture184 then self:InstallVisibleCraftingTooltipCapture184() end
    if self.InstallEnchantingSelectionCaptureR24 then self:InstallEnchantingSelectionCaptureR24() end
    local sourceIndex = GetTradeSkillSelectionIndex and (tonumber(GetTradeSkillSelectionIndex()) or 0) or (TradeSkillFrame and tonumber(TradeSkillFrame.selectedSkill) or 0)
    local _, _, recipe, name = ResolveOpenTradeRecipeR24(self, sourceIndex)
    if sourceIndex <= 0 then
        RecordEnchantAttemptR27(self, "no-selection")
        RecordEnchantDiagnosticR24(self, trigger, sourceIndex, "", {}, "", "UNKNOWN", "skipped", "no-selection")
        return false, "no-selection"
    end
    if not recipe then
        RecordEnchantAttemptR27(self, "recipe-unresolved")
        RecordEnchantDiagnosticR24(self, trigger, sourceIndex, name or "", {}, "", "UNKNOWN", "skipped", "recipe-unresolved")
        return false, "recipe-unresolved"
    end
    if self:SafeText(recipe.effectText or "", 180, false, false) ~= "" and NormalizeEnchantEffectSourceR24(recipe.effectSource183) == "LOCAL_NATIVE" then
        RecordEnchantAttemptR27(self, "cached")
        return true, "cached"
    end
    local directCapturedR43, directStateR43 = ProbeNativeEnchantDescriptionR43(self, "TRADE", sourceIndex, trigger .. "-description")
    if directCapturedR43 then
        RecordEnchantAttemptR27(self, "captured")
        return true, directStateR43 or "captured"
    end
    if not GameTooltip or type(GameTooltip.SetTradeSkillItem) ~= "function" then
        RecordEnchantAttemptR27(self, directStateR43 == "api-missing" and "api-missing" or "tooltip-api-missing")
        RecordEnchantDiagnosticR24(self, trigger, sourceIndex, name or "", {}, "", "UNKNOWN", "skipped", "GameTooltip.SetTradeSkillItem unavailable")
        return false, directStateR43 == "api-missing" and "api-missing" or "tooltip-api-missing"
    end
    local captured = self:ProbeSelectedTradeSkillNativeR24(trigger)
    if captured then
        RecordEnchantAttemptR27(self, "captured")
        return true, "captured"
    end

    -- r27 fallback: run the same hidden native scanner used by the bounded detail
    -- queue against the exact selected recipe. This is event-driven and capped; it
    -- does not introduce polling. Some Octo clients build the useful native lines
    -- only through this path even when the visible GameTooltip probe is empty.
    local hiddenCaptured = self.CaptureCraftingDetail and self:CaptureCraftingDetail(recipe, professionKey, "TRADE", sourceIndex) or false
    if hiddenCaptured and self:SafeText(recipe.effectText or "", 180, false, false) ~= ""
        and NormalizeEnchantEffectSourceR24(recipe.effectSource183) == "LOCAL_NATIVE" then
        local _, profession = self:GetOpenTradeSkillProfession184()
        if profession then
            profession.detailRevision = (tonumber(profession.detailRevision) or 0) + 1
            profession.hashDirty184 = true
        end
        if self.ScheduleVisibleCraftingTooltipCommit185 then self:ScheduleVisibleCraftingTooltipCommit185(professionKey) end
        RecordEnchantAttemptR27(self, "hidden-captured")
        return true, "hidden-captured"
    end
    RecordEnchantAttemptR27(self, hiddenCaptured and "hidden-no-effect" or "probe-miss")
    return false, hiddenCaptured and "hidden-no-effect" or "probe-miss"
end

function OTLGM:RunSelectedCraftEnchantCaptureR43(reason, attempt)
    attempt = math.max(1, math.min(ENCHANT_CAPTURE_MAX_ATTEMPTS_R27, tonumber(attempt) or 1))
    local trigger = "r43-craft-" .. tostring(reason or "event") .. "-" .. tostring(attempt)
    local professionKey = self.GetOpenCraftProfessionR43 and self:GetOpenCraftProfessionR43() or nil
    if professionKey ~= "ENCHANTING" then
        RecordEnchantAttemptR27(self, professionKey and "craft-not-enchanting" or "craft-profession-empty")
        return false, professionKey and "craft-not-enchanting" or "craft-profession-empty"
    end
    local sourceIndex = GetCraftSelectionIndex and (tonumber(GetCraftSelectionIndex()) or 0) or 0
    local _, _, recipe, name = ResolveOpenCraftRecipeR43(self, sourceIndex)
    if sourceIndex <= 0 then
        RecordEnchantAttemptR27(self, "craft-no-selection")
        RecordEnchantDiagnosticR24(self, trigger, sourceIndex, "", {}, "", "UNKNOWN", "skipped", "craft-no-selection")
        return false, "craft-no-selection"
    end
    if not recipe then
        RecordEnchantAttemptR27(self, "craft-recipe-unresolved")
        RecordEnchantDiagnosticR24(self, trigger, sourceIndex, name or "", {}, "", "UNKNOWN", "skipped", "craft-recipe-unresolved")
        return false, "craft-recipe-unresolved"
    end
    if self:SafeText(recipe.effectText or "", 180, false, false) ~= "" and NormalizeEnchantEffectSourceR24(recipe.effectSource183) == "LOCAL_NATIVE" then
        RecordEnchantAttemptR27(self, "cached")
        return true, "cached"
    end

    local directCaptured, directState = ProbeNativeEnchantDescriptionR43(self, "CRAFT", sourceIndex, trigger .. "-description")
    if directCaptured then
        RecordEnchantAttemptR27(self, "captured")
        return true, directState or "captured"
    end

    local hiddenCaptured = self.CaptureCraftingDetail and self:CaptureCraftingDetail(recipe, professionKey, "CRAFT", sourceIndex) or false
    if hiddenCaptured and self:SafeText(recipe.effectText or "", 180, false, false) ~= ""
        and NormalizeEnchantEffectSourceR24(recipe.effectSource183) == "LOCAL_NATIVE" then
        local _, profession = self:GetOpenCraftProfessionR43()
        if profession then
            profession.detailRevision = (tonumber(profession.detailRevision) or 0) + 1
            profession.hashDirty184 = true
        end
        if self.ScheduleVisibleCraftingTooltipCommit185 then self:ScheduleVisibleCraftingTooltipCommit185(professionKey) end
        RecordEnchantAttemptR27(self, "craft-hidden-captured")
        return true, "craft-hidden-captured"
    end
    local outcome = hiddenCaptured and "craft-hidden-no-effect" or (directState or "craft-probe-miss")
    RecordEnchantAttemptR27(self, outcome)
    return false, outcome
end

function OTLGM:ScheduleSelectedCraftEnchantCaptureR43(reason, attempt, delay)
    attempt = math.max(1, math.min(ENCHANT_CAPTURE_MAX_ATTEMPTS_R27, tonumber(attempt) or 1))
    delay = tonumber(delay) or (attempt == 1 and 0.05 or (attempt == 2 and 0.20 or 0.55))
    if not self.ScheduleAfter180 then return self:RunSelectedCraftEnchantCaptureR43(reason, attempt) end
    return self:ScheduleAfter180("crafting-enchant-craft-r43", delay, function(owner)
        local ok, state = owner:RunSelectedCraftEnchantCaptureR43(reason, attempt)
        if not ok and attempt < ENCHANT_CAPTURE_MAX_ATTEMPTS_R27
            and state ~= "craft-not-enchanting" and state ~= "craft-profession-empty" then
            owner:ScheduleSelectedCraftEnchantCaptureR43(reason, attempt + 1, attempt == 1 and 0.18 or 0.45)
        end
    end, 90)
end

function OTLGM:ScheduleSelectedEnchantCaptureR27(reason, attempt, delay)
    attempt = math.max(1, math.min(ENCHANT_CAPTURE_MAX_ATTEMPTS_R27, tonumber(attempt) or 1))
    delay = tonumber(delay) or (attempt == 1 and 0.05 or (attempt == 2 and 0.20 or 0.55))
    if not self.ScheduleAfter180 then return self:RunSelectedEnchantCaptureR27(reason, attempt) end
    return self:ScheduleAfter180("crafting-enchant-capture-r27", delay, function(owner)
        local ok, state = owner:RunSelectedEnchantCaptureR27(reason, attempt)
        if not ok and attempt < ENCHANT_CAPTURE_MAX_ATTEMPTS_R27
            and state ~= "not-enchanting" and state ~= "api-missing" then
            owner:ScheduleSelectedEnchantCaptureR27(reason, attempt + 1, attempt == 1 and 0.18 or 0.45)
        end
    end, 90)
end

function OTLGM:ObserveTradeSkillEventR27(reason)
    self.runtime = self.runtime or {}
    self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
    local metrics = self.runtime.craftingMetrics180
    local key = tostring(reason or "event")
    metrics.enchantTradeSkillEventsR30 = (tonumber(metrics.enchantTradeSkillEventsR30) or 0) + 1
    if key == "show" then metrics.enchantTradeSkillShowR30 = (tonumber(metrics.enchantTradeSkillShowR30) or 0) + 1 end
    if key == "update" then metrics.enchantTradeSkillUpdateR30 = (tonumber(metrics.enchantTradeSkillUpdateR30) or 0) + 1 end
    self.runtime.lastTradeSkillCaptureTriggerR27 = key
    if self.InstallVisibleCraftingTooltipCapture184 then self:InstallVisibleCraftingTooltipCapture184() end
    if self.InstallEnchantingSelectionCaptureR24 then self:InstallEnchantingSelectionCaptureR24() end
    return self:ScheduleSelectedEnchantCaptureR27(key, 1, 0.08)
end

function OTLGM:ObserveCraftEventR43(reason)
    self.runtime = self.runtime or {}
    self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
    local metrics = self.runtime.craftingMetrics180
    local key = tostring(reason or "event")
    metrics.enchantCraftEventsR43 = (tonumber(metrics.enchantCraftEventsR43) or 0) + 1
    if key == "show" then metrics.enchantCraftShowR43 = (tonumber(metrics.enchantCraftShowR43) or 0) + 1 end
    if key == "update" then metrics.enchantCraftUpdateR43 = (tonumber(metrics.enchantCraftUpdateR43) or 0) + 1 end
    self.runtime.lastTradeSkillCaptureTriggerR27 = "craft:" .. key
    if self.InstallCraftEnchantSelectionCaptureR43 then self:InstallCraftEnchantSelectionCaptureR43() end
    return self:ScheduleSelectedCraftEnchantCaptureR43(key, 1, 0.08)
end

function OTLGM:ScheduleSelectedTradeSkillNativeProbeR24(reason, sourceIndex)
    local index = tonumber(sourceIndex) or (GetTradeSkillSelectionIndex and tonumber(GetTradeSkillSelectionIndex())) or (TradeSkillFrame and tonumber(TradeSkillFrame.selectedSkill)) or 0
    if index <= 0 then return false end
    local professionKey, _, recipe = ResolveOpenTradeRecipeR24(self, index)
    if professionKey ~= "ENCHANTING" or not recipe then return false end
    if self:SafeText(recipe.effectText or "", 180, false, false) ~= "" and NormalizeEnchantEffectSourceR24(recipe.effectSource183) == "LOCAL_NATIVE" then return false end
    if not self.ScheduleAfter180 then return self:ProbeSelectedTradeSkillNativeR24(reason) end
    -- One keyed task follows the latest selection. Rapid clicking must coalesce
    -- instead of creating one tooltip probe per transient recipe index.
    return self:ScheduleAfter180("crafting-selection-native-r24", 0.05, function(owner)
        owner:ProbeSelectedTradeSkillNativeR24(reason or "selection")
    end, 89)
end

function OTLGM:InstallEnchantingSelectionCaptureR24()
    self.runtime = self.runtime or {}
    self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
    local metricsR30 = self.runtime.craftingMetrics180
    metricsR30.enchantHookInstallChecksR30 = (tonumber(metricsR30.enchantHookInstallChecksR30) or 0) + 1
    metricsR30.enchantTradeSkillFrameUpdateApiR30 = type(TradeSkillFrame_Update) == "function" and 1 or 0
    metricsR30.enchantTradeSkillSetSelectionApiR30 = type(TradeSkillFrame_SetSelection) == "function" and 1 or 0
    metricsR30.enchantSelectionIndexApiR30 = type(GetTradeSkillSelectionIndex) == "function" and 1 or 0
    if not self.runtime.enchantUpdateHookInstalledR27 and type(TradeSkillFrame_Update) == "function" then
        local previousUpdateR27 = TradeSkillFrame_Update
        TradeSkillFrame_Update = function()
            local r1, r2, r3, r4 = previousUpdateR27()
            if OTLGM and OTLGM.runtime then
                local selectedR27 = GetTradeSkillSelectionIndex and (tonumber(GetTradeSkillSelectionIndex()) or 0) or (TradeSkillFrame and tonumber(TradeSkillFrame.selectedSkill) or 0)
                if selectedR27 > 0 and selectedR27 ~= tonumber(OTLGM.runtime.lastEnchantSelectionR27) then
                    OTLGM.runtime.lastEnchantSelectionR27 = selectedR27
                    if OTLGM.ScheduleSelectedEnchantCaptureR27 then OTLGM:ScheduleSelectedEnchantCaptureR27("frame-update", 1, 0.04) end
                end
            end
            return r1, r2, r3, r4
        end
        self.runtime.enchantUpdateHookOriginalR27 = previousUpdateR27
        self.runtime.enchantUpdateHookInstalledR27 = true
    end
    if self.runtime.enchantSelectionHookInstalledR24 then return true end
    if type(TradeSkillFrame_SetSelection) ~= "function" then return self.runtime.enchantUpdateHookInstalledR27 and true or false end
    local previous = TradeSkillFrame_SetSelection
    local wrapper = function(id)
        local r1, r2, r3, r4 = previous(id)
        if OTLGM and OTLGM.ScheduleSelectedEnchantCaptureR27 then OTLGM:ScheduleSelectedEnchantCaptureR27("selection", 1, 0.04) elseif OTLGM and OTLGM.ScheduleSelectedTradeSkillNativeProbeR24 then OTLGM:ScheduleSelectedTradeSkillNativeProbeR24("selection", id) end
        return r1, r2, r3, r4
    end
    self.runtime.enchantSelectionHookOriginalR24 = previous
    self.runtime.enchantSelectionHookWrapperR24 = wrapper
    self.runtime.enchantSelectionHookInstalledR24 = true
    TradeSkillFrame_SetSelection = wrapper
    return true
end

function OTLGM:InstallCraftEnchantSelectionCaptureR43()
    self.runtime = self.runtime or {}
    self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
    local metrics = self.runtime.craftingMetrics180
    metrics.enchantCraftHookInstallChecksR43 = (tonumber(metrics.enchantCraftHookInstallChecksR43) or 0) + 1
    metrics.enchantCraftSelectionApiR43 = type(GetCraftSelectionIndex) == "function" and 1 or 0
    metrics.enchantCraftDescriptionApiR43 = type(GetCraftDescription) == "function" and 1 or 0
    metrics.enchantCraftFrameUpdateApiR43 = type(CraftFrame_Update) == "function" and 1 or 0
    metrics.enchantCraftFrameSetSelectionApiR43 = type(CraftFrame_SetSelection) == "function" and 1 or 0

    if not self.runtime.enchantCraftUpdateHookInstalledR43 and type(CraftFrame_Update) == "function" then
        local previousUpdate = CraftFrame_Update
        CraftFrame_Update = function()
            local r1, r2, r3, r4 = previousUpdate()
            if OTLGM and OTLGM.runtime then
                local selected = GetCraftSelectionIndex and (tonumber(GetCraftSelectionIndex()) or 0) or 0
                if selected > 0 and selected ~= tonumber(OTLGM.runtime.lastEnchantCraftSelectionR43) then
                    OTLGM.runtime.lastEnchantCraftSelectionR43 = selected
                    if OTLGM.ScheduleSelectedCraftEnchantCaptureR43 then OTLGM:ScheduleSelectedCraftEnchantCaptureR43("frame-update", 1, 0.04) end
                end
            end
            return r1, r2, r3, r4
        end
        self.runtime.enchantCraftUpdateHookOriginalR43 = previousUpdate
        self.runtime.enchantCraftUpdateHookInstalledR43 = true
    end

    if self.runtime.enchantCraftSelectionHookInstalledR43 then return true end
    if type(CraftFrame_SetSelection) ~= "function" then return self.runtime.enchantCraftUpdateHookInstalledR43 and true or false end
    local previous = CraftFrame_SetSelection
    local wrapper = function(id)
        local r1, r2, r3, r4 = previous(id)
        if OTLGM and OTLGM.ScheduleSelectedCraftEnchantCaptureR43 then OTLGM:ScheduleSelectedCraftEnchantCaptureR43("selection", 1, 0.04) end
        return r1, r2, r3, r4
    end
    self.runtime.enchantCraftSelectionHookOriginalR43 = previous
    self.runtime.enchantCraftSelectionHookWrapperR43 = wrapper
    self.runtime.enchantCraftSelectionHookInstalledR43 = true
    CraftFrame_SetSelection = wrapper
    return true
end

function OTLGM:InstallVisibleCraftingTooltipCapture184()
    if not GameTooltip or type(GameTooltip.SetTradeSkillItem) ~= "function" then return false end
    if GameTooltip.otlTradeSkillCapture184 then return true end
    local previous = GameTooltip.SetTradeSkillItem
    GameTooltip.otlTradeSkillCapture184 = previous
    GameTooltip.SetTradeSkillItem = function(frame, sourceIndex, reagentIndex)
        local result1, result2, result3, result4 = previous(frame, sourceIndex, reagentIndex)
        if frame == GameTooltip and OTLGM and OTLGM.ScheduleAfter180
            and not (OTLGM.runtime and OTLGM.runtime.enchantSelectionProbeActiveR24) then
            local index = tonumber(sourceIndex) or 0
            -- Reagent tooltips use the same API with a second index. They are not
            -- the recipe result and must never be bound as an enchant description.
            if index > 0 and not reagentIndex then
                OTLGM:ScheduleAfter180("crafting-visible-tooltip:" .. tostring(index), 0.01, function(owner)
                    owner:CaptureVisibleTradeSkillTooltip184(index)
                end, 88)
            end
        end
        return result1, result2, result3, result4
    end
    return true
end

local function FindOpenEnchantRecipeIndexR30(self, selected)
    local wanted = self:NormalizeText(selected and selected.recipe and selected.recipe.name or "")
    if wanted == "" then return 0, nil, nil, "recipe-name-empty", nil end

    -- R43: Vanilla 1.12 Enchanting normally lives in CraftFrame. Prefer that
    -- native API when it is active, then fall back to TradeSkillFrame for Octo
    -- variants that expose Enchanting through the newer trade-skill path.
    if GetNumCrafts and GetCraftInfo and self.GetOpenCraftProfessionR43 then
        local craftKey, craftProfession = self:GetOpenCraftProfessionR43()
        if craftKey == "ENCHANTING" then
            local total = tonumber(GetNumCrafts()) or 0
            local index, name, recipeType
            for index = 1, total do
                name, _, recipeType = GetCraftInfo(index)
                if recipeType ~= "header" and self:NormalizeText(name or "") == wanted then
                    local resolvedKey, resolvedProfession, recipe = ResolveOpenCraftRecipeR43(self, index)
                    if resolvedKey == "ENCHANTING" and recipe then return index, resolvedKey, resolvedProfession, recipe, "CRAFT" end
                    if craftProfession and craftProfession.recipes then
                        local recipeKey, candidate
                        for recipeKey, candidate in pairs(craftProfession.recipes) do
                            if self:NormalizeText(candidate and candidate.name or "") == wanted then return index, craftKey, craftProfession, candidate, "CRAFT" end
                        end
                    end
                    return index, craftKey, craftProfession, "recipe-unresolved", "CRAFT"
                end
            end
            return 0, craftKey, craftProfession, "recipe-index-missing", "CRAFT"
        end
    end

    if not GetNumTradeSkills or not GetTradeSkillInfo or not GetTradeSkillLine then return 0, nil, nil, "native-api-missing", nil end
    local professionKey, profession = nil, nil
    if self.GetOpenTradeSkillProfession184 then professionKey, profession = self:GetOpenTradeSkillProfession184() end
    if professionKey ~= "ENCHANTING" then return 0, professionKey, profession, "not-enchanting", "TRADE" end
    local total = tonumber(GetNumTradeSkills()) or 0
    local index, name, recipeType
    for index = 1, total do
        name, recipeType = GetTradeSkillInfo(index)
        if recipeType ~= "header" and self:NormalizeText(name or "") == wanted then
            local resolvedKey, resolvedProfession, recipe = ResolveOpenTradeRecipeR24(self, index)
            if resolvedKey == "ENCHANTING" and recipe then return index, resolvedKey, resolvedProfession, recipe, "TRADE" end
            if profession and profession.recipes then
                local recipeKey, candidate
                for recipeKey, candidate in pairs(profession.recipes) do
                    if self:NormalizeText(candidate and candidate.name or "") == wanted then return index, professionKey, profession, candidate, "TRADE" end
                end
            end
            return index, professionKey, profession, "recipe-unresolved", "TRADE"
        end
    end
    return 0, professionKey, profession, "recipe-index-missing", "TRADE"
end

function OTLGM:RunProfessionsEnchantProbeR30(selected, reason)
    self.runtime = self.runtime or {}
    self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
    local metrics = self.runtime.craftingMetrics180
    metrics.enchantPageProbeAttemptsR30 = (tonumber(metrics.enchantPageProbeAttemptsR30) or 0) + 1
    local index, professionKey, profession, recipeOrReason, nativeModeR43 = FindOpenEnchantRecipeIndexR30(self, selected)
    if index <= 0 or type(recipeOrReason) ~= "table" then
        local outcome = type(recipeOrReason) == "string" and recipeOrReason or "recipe-unresolved"
        metrics.enchantPageProbeLastOutcomeR30 = outcome
        self.runtime.lastTradeSkillCaptureTriggerR27 = "page-probe:" .. outcome
        return false, outcome
    end
    local recipe = recipeOrReason
    if self:SafeText(recipe.effectText or "", 180, false, false) ~= "" and NormalizeEnchantEffectSourceR24(recipe.effectSource183) == "LOCAL_NATIVE" then
        metrics.enchantPageProbeLastOutcomeR30 = "cached"
        return true, "cached"
    end
    self.runtime.lastTradeSkillCaptureTriggerR27 = "page-probe:" .. tostring(reason or "professions") .. ":" .. tostring(nativeModeR43 or "?")
    local directCapturedR43 = false
    if nativeModeR43 == "CRAFT" or nativeModeR43 == "TRADE" then
        directCapturedR43 = ProbeNativeEnchantDescriptionR43(self, nativeModeR43, index, "page-probe-description")
    end
    local captured = directCapturedR43 or (self.CaptureCraftingDetail and self:CaptureCraftingDetail(recipe, "ENCHANTING", nativeModeR43 or "TRADE", index) or false)
    local native = self:SafeText(recipe.effectText or "", 180, false, false) ~= "" and NormalizeEnchantEffectSourceR24(recipe.effectSource183) == "LOCAL_NATIVE"
    if native then
        metrics.enchantPageProbeCapturesR30 = (tonumber(metrics.enchantPageProbeCapturesR30) or 0) + 1
        metrics.enchantPageProbeLastOutcomeR30 = "captured"
        if selected and selected.recipe then
            selected.recipe.effectText = recipe.effectText
            selected.recipe.effectSource183 = recipe.effectSource183
            selected.recipe.effectChecked = true
        end
        if profession and not directCapturedR43 then
            profession.detailRevision = (tonumber(profession.detailRevision) or 0) + 1
            profession.hashDirty184 = true
        end
        if self.InvalidateCraftingAggregateIndexR30 then self:InvalidateCraftingAggregateIndexR30("enchant-page-capture") end
        if not directCapturedR43 and self.ScheduleVisibleCraftingTooltipCommit185 then self:ScheduleVisibleCraftingTooltipCommit185("ENCHANTING") end
        return true, "captured"
    end
    local outcome = captured and "scanner-no-native-effect" or "scanner-empty"
    metrics.enchantPageProbeMissesR30 = (tonumber(metrics.enchantPageProbeMissesR30) or 0) + 1
    metrics.enchantPageProbeLastOutcomeR30 = outcome
    return false, outcome
end

function OTLGM:ScheduleProfessionsEnchantProbeR30(selected, reason)
    if not selected or tostring(selected.professionKey or "") ~= "ENCHANTING" then return false end
    -- R43 correctness: GetFriendlyCraftingEffect183 deliberately returns the
    -- user-facing "Exact effect pending..." sentence when no native effect is
    -- known. Treating any non-empty display string as captured made this probe
    -- self-disable, which explains live sessions with a selected enchant but 0/0
    -- page-probe counters. Gate only on genuinely trusted native data instead.
    local effect = self:SafeText(selected.recipe and selected.recipe.effectText or "", 180, false, false)
    local source = NormalizeEnchantEffectSourceR24(selected.recipe and selected.recipe.effectSource183)
    if effect == "" and self.GetCraftingDetail then
        local cached = self:GetCraftingDetail(selected.recipe, selected.professionKey)
        effect = self:SafeText(cached and cached.effectText or "", 180, false, false)
        source = NormalizeEnchantEffectSourceR24(cached and cached.effectSource183 or source)
    end
    if effect ~= "" and TrustedEnchantEffectSourceR24(source) then return false end
    self.runtime = self.runtime or {}
    self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
    local key = tostring(selected.key or (selected.recipe and selected.recipe.name) or "unknown")
    local now = self:Now()
    if self.runtime.enchantPageProbeKeyR30 == key and now - (tonumber(self.runtime.enchantPageProbeAtR30) or 0) < 3 then return false end
    self.runtime.enchantPageProbeKeyR30, self.runtime.enchantPageProbeAtR30 = key, now
    self.runtime.craftingMetrics180.enchantPageProbeRequestsR30 = (tonumber(self.runtime.craftingMetrics180.enchantPageProbeRequestsR30) or 0) + 1
    if not self.ScheduleAfter180 then return self:RunProfessionsEnchantProbeR30(selected, reason) end
    return self:ScheduleAfter180("crafting-enchant-page-r30", 0.06, function(owner)
        local current = owner.ui and owner.ui.recipeDetails and owner.ui.recipeDetails.otlResult or selected
        if current and tostring(current.key or "") == tostring(key) then owner:RunProfessionsEnchantProbeR30(current, reason) end
    end, 91)
end

function OTLGM:InitializeCraftingDetailsUI()
    self:InstallVisibleCraftingTooltipCapture184()
    self:InstallEnchantingSelectionCaptureR24()
    self:InstallCraftEnchantSelectionCaptureR43()
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
