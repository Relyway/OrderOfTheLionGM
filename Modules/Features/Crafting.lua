-- Order of the Lion Guild Manager
-- Crafting Network records, profession snapshots, requests and reactions.

OTLGM.craftingProtocol = "C1"
OTLGM.craftingRequestLifetime = 86400
OTLGM.craftingResponseLifetime = 86400
OTLGM.craftingShareCooldown = 8

local function CTrim(text)
    text = tostring(text or "")
    return string.gsub(text, "^%s*(.-)%s*$", "%1")
end

local function CNormalizeName(name)
    name = CTrim(name)
    name = string.gsub(name, "%-.*$", "")
    return string.lower(name)
end

local function CNormalizeText(text)
    text = string.lower(CTrim(text))
    text = string.gsub(text, "[%c]", " ")
    text = string.gsub(text, "%s+", " ")
    return text
end

local function CSafeText(text, maxLength)
    text = CTrim(text)
    text = string.gsub(text, "[\r\n\t]", " ")
    text = string.gsub(text, "%s+", " ")
    if maxLength then text = OTLGM:Utf8Truncate(text, maxLength) end
    return text
end

local function CEscape(text, maxWireLength)
    text = CSafeText(text)
    local result = {}
    local wireLength = 0
    local i, character, encoded
    for i = 1, string.len(text) do
        character = string.sub(text, i, i)
        if character == "%" then encoded = "%25"
        elseif character == "^" then encoded = "%5E"
        elseif character == "~" then encoded = "%7E"
        elseif character == "," then encoded = "%2C"
        elseif character == ":" then encoded = "%3A"
        elseif character == "+" then encoded = "%2B"
        elseif character == "|" then encoded = "%7C"
        else encoded = character end
        if maxWireLength and wireLength + string.len(encoded) > maxWireLength then break end
        table.insert(result, encoded)
        wireLength = wireLength + string.len(encoded)
    end
    return table.concat(result)
end

local function CUnescape(text)
    text = tostring(text or "")
    text = string.gsub(text, "%%7C", "|")
    text = string.gsub(text, "%%2B", "+")
    text = string.gsub(text, "%%3A", ":")
    text = string.gsub(text, "%%2C", ",")
    text = string.gsub(text, "%%7E", "~")
    text = string.gsub(text, "%%5E", "^")
    text = string.gsub(text, "%%25", "%%")
    return text
end

local function CSplit(text, delimiter)
    local result = {}
    local startAt = 1
    delimiter = delimiter or "^"
    while true do
        local found = string.find(text or "", delimiter, startAt, true)
        if not found then
            table.insert(result, string.sub(text or "", startAt))
            break
        end
        table.insert(result, string.sub(text or "", startAt, found - 1))
        startAt = found + string.len(delimiter)
    end
    return result
end

local function CTableCount(tbl)
    local count = 0
    local key
    for key in pairs(tbl or {}) do count = count + 1 end
    return count
end

local function CSortedKeys(tbl)
    local keys = {}
    local key
    for key in pairs(tbl or {}) do table.insert(keys, key) end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    return keys
end

local function CCopy(source)
    local target = {}
    local key, value
    for key, value in pairs(source or {}) do
        if type(value) == "table" then target[key] = CCopy(value) else target[key] = value end
    end
    return target
end

local function CPruneMapByTime(map, maximum)
    local entries = {}
    local key, value
    for key, value in pairs(map or {}) do
        table.insert(entries, { key = key, ts = tonumber(value and (value.ts or value.updated or value.created)) or 0 })
    end
    if table.getn(entries) <= (maximum or 0) then return false end
    table.sort(entries, function(a, b)
        if a.ts ~= b.ts then return a.ts < b.ts end
        return tostring(a.key) < tostring(b.key)
    end)
    local removeCount = table.getn(entries) - maximum
    local i
    for i = 1, removeCount do map[entries[i].key] = nil end
    return removeCount > 0
end

local function CHashRecipes(recipes)
    local keys = CSortedKeys(recipes)
    local hash = 17
    local i, key, recipe, text, j, reagentIndex, reagent
    for i = 1, table.getn(keys) do
        key = keys[i]
        recipe = recipes[key]
        local parts = {
            tostring(key), tostring(recipe and recipe.name or ""), tostring(recipe and recipe.itemId or 0),
            tostring(recipe and recipe.quality or 1), tostring(recipe and recipe.itemLevel or 0),
            tostring(recipe and recipe.requiredLevel or 0), tostring(recipe and recipe.itemType or ""),
            tostring(recipe and recipe.itemSubType or ""), tostring(recipe and recipe.equipLoc or ""),
            tostring(recipe and recipe.icon or ""), tostring(recipe and recipe.itemLink or ""),
            tostring(recipe and recipe.recipeLink or ""), tostring(recipe and recipe.materialsStatus or ""),
            tostring(recipe and recipe.effectText or ""), tostring(recipe and recipe.requiredSkill or 0),
            tostring(recipe and recipe.difficulty or ""),
        }
        for reagentIndex = 1, table.getn(recipe and recipe.reagents or {}) do
            reagent = recipe.reagents[reagentIndex]
            table.insert(parts, tostring(reagent.itemId or 0))
            table.insert(parts, tostring(reagent.name or ""))
            table.insert(parts, tostring(reagent.count or 0))
            table.insert(parts, tostring(reagent.icon or ""))
            table.insert(parts, tostring(reagent.quality or 1))
            table.insert(parts, tostring(reagent.itemLink or ""))
        end
        text = table.concat(parts, ":")
        for j = 1, string.len(text) do
            hash = math.mod((hash * 33) + string.byte(text, j), 2147483000)
        end
    end
    return tostring(hash)
end

local function CProfessionCompletenessScore(recipes)
    local recipeCount, iconCount, materialCount, metadataCount = 0, 0, 0, 0
    local _, recipe
    for _, recipe in pairs(recipes or {}) do
        recipeCount = recipeCount + 1
        if recipe.icon and recipe.icon ~= "" then iconCount = iconCount + 1 end
        if recipe.materialsStatus == "COMPLETE" or recipe.materialsAvailable then materialCount = materialCount + 1 end
        if (tonumber(recipe.itemId) or 0) > 0 or (recipe.itemLink and recipe.itemLink ~= "") or (recipe.recipeLink and recipe.recipeLink ~= "") then metadataCount = metadataCount + 1 end
    end
    return (recipeCount * 1000) + (materialCount * 10) + (iconCount * 3) + metadataCount
end

function OTLGM:RehashCraftingProfession(profession)
    if not profession then return nil end
    profession.hash = CHashRecipes(profession.recipes or {})
    return profession.hash
end

local function CParseItemID(link)
    if not link or link == "" then return 0 end
    local _, _, itemId = string.find(link, "item:(%d+)")
    return tonumber(itemId) or 0
end

local function CProfessionKey(rawName)
    local normalized = CNormalizeText(rawName)
    local definitions = {
        { key = "ALCHEMY", label = "Alchemy", terms = { "alchemy" } },
        { key = "COOKING", label = "Cooking", terms = { "cooking", "cook" } },
        { key = "BLACKSMITHING", label = "Blacksmithing", terms = { "blacksmithing", "blacksmith" } },
        { key = "ENCHANTING", label = "Enchanting", terms = { "enchanting", "enchant" } },
        { key = "ENGINEERING", label = "Engineering", terms = { "engineering", "engineer" } },
        { key = "JEWELCRAFTING", label = "Jewelcrafting", terms = { "jewelcrafting", "jewelcraft", "jewel crafter" } },
        { key = "LEATHERWORKING", label = "Leatherworking", terms = { "leatherworking", "leatherworker" } },
        { key = "TAILORING", label = "Tailoring", terms = { "tailoring", "tailor" } },
        { key = "MINING", label = "Mining", terms = { "mining", "smelting" } },
    }
    local i, j
    for i = 1, table.getn(definitions) do
        for j = 1, table.getn(definitions[i].terms) do
            if normalized == definitions[i].terms[j] or string.find(normalized, definitions[i].terms[j], 1, true) then
                return definitions[i].key, definitions[i].label
            end
        end
    end
    return nil, nil
end

local function CPlayerClassToken()
    local _, token = UnitClass("player")
    return token or ""
end

function OTLGM:_Stage_Crafting_EnsureCraftingDB_1()
    self:EnsureDB()
    local db = self:GetGuildDB()
    if not db then return nil end
    if type(db.crafting) ~= "table" then db.crafting = {} end
    local craft = db.crafting
    if type(craft.characters) ~= "table" then craft.characters = {} end
    if type(craft.requests) ~= "table" then craft.requests = {} end
    if type(craft.responses) ~= "table" then craft.responses = {} end
    if type(craft.reactions) ~= "table" then craft.reactions = {} end
    if type(craft.deleted) ~= "table" then craft.deleted = {} end
    if type(craft.events) ~= "table" then craft.events = {} end
    if type(craft.favorites170) ~= "table" then craft.favorites170 = {} end
    if type(craft.unread) ~= "table" then craft.unread = { RECIPES = 0, REQUESTS = 0 } end
    if craft.unread.PROFESSIONS and not craft.unread.RECIPES then craft.unread.RECIPES = craft.unread.PROFESSIONS end
    craft.unread.PROFESSIONS = nil
    craft.lastSync = craft.lastSync or 0
    if type(craft.pendingRecipes) ~= "table" then craft.pendingRecipes = {} end
    if type(craft.syncState) ~= "table" then craft.syncState = { active = false, started = 0, completed = 0, received = 0 } end

    OTLGM_DB.settings.craftingSection = OTLGM_DB.settings.craftingSection or "RECIPES"
    OTLGM_DB.settings.craftingProfession = OTLGM_DB.settings.craftingProfession or "ALL"
    OTLGM_DB.settings.craftingSearch = OTLGM_DB.settings.craftingSearch or ""
    OTLGM_DB.settings.craftingRequestTemplate = OTLGM_DB.settings.craftingRequestTemplate or "CRAFT"
    OTLGM_DB.settings.craftingMaterials = OTLGM_DB.settings.craftingMaterials or "READY"
    if OTLGM_DB.settings.craftingShareEnabled == nil then OTLGM_DB.settings.craftingShareEnabled = true end
    if OTLGM_DB.settings.craftingAutoSync == nil then OTLGM_DB.settings.craftingAutoSync = true end
    return craft
end

function OTLGM:AddCraftingEvent(kind, title, detail, targetPage, timestamp)
    local craft = self:EnsureCraftingDB()
    if not craft then return end
    table.insert(craft.events, 1, {
        ts = timestamp or self:Now(), kind = kind or "INFO", title = CSafeText(title, 64),
        detail = CSafeText(detail, 100), targetPage = targetPage or "professions",
    })
    while table.getn(craft.events) > 40 do table.remove(craft.events) end
end

function OTLGM:PurgeCraftingData(silent)
    local craft = self:EnsureCraftingDB()
    if not craft then return false end
    local now = self:Now()
    local changed = false
    local id, record
    for id, record in pairs(craft.requests) do
        if not record.expires or record.expires <= now then craft.requests[id] = nil changed = true end
    end
    if CPruneMapByTime(craft.requests, 120) then changed = true end
    for id, record in pairs(craft.responses) do
        if not record.expires or record.expires <= now or not craft.requests[record.requestId] then craft.responses[id] = nil changed = true end
    end
    if CPruneMapByTime(craft.responses, 400) then changed = true end
    for id, record in pairs(craft.deleted) do
        if not record.ts or record.ts + 172800 <= now then craft.deleted[id] = nil end
    end
    CPruneMapByTime(craft.deleted, 240)
    local targetKey, reactions
    for targetKey, reactions in pairs(craft.reactions) do
        local _, _, targetType, targetId = string.find(targetKey, "^([^:]+):(.+)$")
        local exists = true
        if targetType == "CRAFT" then exists = craft.requests[targetId] ~= nil end
        if targetType == "BOARD" then
            local pve = self.EnsurePveDB and self:EnsurePveDB() or nil
            exists = pve and pve.board and pve.board[targetId] ~= nil
        end
        if targetType == "RAID" then
            local pve = self.EnsurePveDB and self:EnsurePveDB() or nil
            exists = pve and ((pve.raids and pve.raids[targetId]) or (pve.raid and pve.raid.id == targetId)) and true or false
        end
        if not exists then
            craft.reactions[targetKey] = nil
        else
            CPruneMapByTime(reactions, 80)
        end
    end
    CPruneMapByTime(craft.reactions, 200)
    local pendingKey, pending
    for pendingKey, pending in pairs(craft.pendingRecipes or {}) do
        if not pending.created or pending.created + 300 < now then craft.pendingRecipes[pendingKey] = nil end
    end
    CPruneMapByTime(craft.pendingRecipes, 100)
    local name, character
    local roster = self:GetGuildDB() and self:GetGuildDB().roster or {}
    for name, character in pairs(craft.characters) do
        if not character.localOwner and not roster[name] and (character.updated or 0) + (60 * 86400) < now then
            craft.characters[name] = nil
            changed = true
        end
    end
    if CPruneMapByTime(craft.characters, 800) then changed = true end
    if changed and not silent then self:OnCraftingDataChanged(nil, false) end
    return changed
end

function OTLGM:QueueCraftingCacheLookup(itemId, object)
    local craft = self:EnsureCraftingDB()
    itemId = tonumber(itemId) or 0
    if not craft or itemId <= 0 or not object then return false end
    self.runtime = self.runtime or {}
    self.runtime.craftingCacheQueue = self.runtime.craftingCacheQueue or {}
    local queue = self.runtime.craftingCacheQueue
    local key = tostring(itemId) .. ":" .. tostring(object)
    if queue[key] then return true end
    local count = 0
    for _ in pairs(queue) do count = count + 1 end
    if count >= 160 then return false end
    queue[key] = { itemId = itemId, object = object, tries = 0, nextAt = self:Now() }
    return true
end

function OTLGM:ProcessCraftingCacheQueue()
    local craft = self:EnsureCraftingDB()
    if not craft or not GetItemInfo then return false end
    self.runtime = self.runtime or {}
    local queue = self.runtime.craftingCacheQueue or {}
    self.runtime.craftingCacheQueue = queue
    local now = self:Now()
    local processed, changed = 0, false
    local key, entry
    for key, entry in pairs(queue) do
        if processed >= 8 then break end
        if entry and now >= (entry.nextAt or 0) then
            processed = processed + 1
            local name, link, quality, itemLevel, requiredLevel, itemType, itemSubType, _, equipLoc, texture = self:GetItemInfoSafe(entry.itemId)
            if name or texture or link then
                local object = entry.object
                if object then
                    if link and link ~= "" then object.itemLink = link end
                    if texture and texture ~= "" then object.icon = texture end
                    if quality ~= nil then object.quality = tonumber(quality) or object.quality end
                    if itemLevel ~= nil then object.itemLevel = tonumber(itemLevel) or object.itemLevel end
                    if requiredLevel ~= nil then object.requiredLevel = tonumber(requiredLevel) or object.requiredLevel end
                    if itemType then object.itemType = itemType end
                    if itemSubType then object.itemSubType = itemSubType end
                    if equipLoc then object.equipLoc = equipLoc end
                end
                queue[key] = nil
                changed = true
            else
                entry.tries = (entry.tries or 0) + 1
                if entry.tries >= 4 then queue[key] = nil
                else entry.nextAt = now + (entry.tries * 2) end
            end
        end
    end
    if changed and self.ui and self.ui.main and self.ui.main:IsVisible() and self.ui.currentPage == "professions" and self.RefreshProfessionsPage then
        self:RefreshProfessionsPage()
    end
    return changed
end

function OTLGM:ScheduleProfessionRescan(mode, attempt, delay)
    self.craftingRescan = { mode = mode, attempt = tonumber(attempt) or 1, due = self:Now() + (tonumber(delay) or 1) }
end

function OTLGM:_Stage_Crafting_ScanCurrentProfession_1(mode, attempt)
    if not OTLGM_DB or not OTLGM_DB.settings or OTLGM_DB.settings.craftingShareEnabled == false then return false end
    attempt = tonumber(attempt) or 0
    local rawName, rank, maxRank
    local isCraft = mode == "CRAFT"
    if isCraft then
        if not GetCraftName or not GetNumCrafts or not GetCraftInfo then return false end
        rawName = GetCraftName()
        rank, maxRank = 0, 0
        if GetCraftDisplaySkillLine then
            local ok, skillRank, skillMax = pcall(GetCraftDisplaySkillLine)
            if ok then rank, maxRank = tonumber(skillRank) or 0, tonumber(skillMax) or 0 end
        end
    else
        if not GetTradeSkillLine or not GetNumTradeSkills or not GetTradeSkillInfo then return false end
        rawName, rank, maxRank = GetTradeSkillLine()
    end
    local professionKey, professionLabel = CProfessionKey(rawName)
    if not professionKey then return false end

    local recipes = {}
    local count = isCraft and (GetNumCrafts() or 0) or (GetNumTradeSkills() or 0)
    local missingMaterialRows = 0
    local i
    for i = 1, count do
        local recipeName, recipeType
        if isCraft then recipeName, _, recipeType = GetCraftInfo(i)
        else recipeName, recipeType = GetTradeSkillInfo(i) end
        if recipeName and recipeName ~= "" and recipeType ~= "header" then
            local itemLink, recipeLink, icon
            if isCraft then
                if GetCraftItemLink then itemLink = GetCraftItemLink(i) end
                if GetCraftRecipeLink then recipeLink = GetCraftRecipeLink(i) end
                if GetCraftIcon then icon = GetCraftIcon(i) end
            else
                if GetTradeSkillItemLink then itemLink = GetTradeSkillItemLink(i) end
                if GetTradeSkillRecipeLink then recipeLink = GetTradeSkillRecipeLink(i) end
                if GetTradeSkillIcon then icon = GetTradeSkillIcon(i) end
            end
            local itemId = CParseItemID(itemLink)
            local quality, itemLevel, requiredLevel, itemType, itemSubType, equipLoc = 1, 0, 0, "", "", ""
            if itemId > 0 and GetItemInfo then
                local _, cachedLink, itemQuality, cachedItemLevel, cachedRequiredLevel, cachedItemType, cachedItemSubType, _, cachedEquipLoc, itemTexture = self:GetItemInfoSafe(itemId)
                if (not itemLink or itemLink == "") and cachedLink then itemLink = cachedLink end
                quality = tonumber(itemQuality) or 1
                itemLevel = tonumber(cachedItemLevel) or 0
                requiredLevel = tonumber(cachedRequiredLevel) or 0
                itemType = cachedItemType or ""
                itemSubType = cachedItemSubType or ""
                equipLoc = cachedEquipLoc or ""
                if not icon and itemTexture then icon = itemTexture end
            end

            local reagents = {}
            local reagentCount = 0
            if isCraft and GetCraftNumReagents and GetCraftReagentInfo then
                reagentCount = tonumber(GetCraftNumReagents(i)) or 0
            elseif not isCraft and GetTradeSkillNumReagents and GetTradeSkillReagentInfo then
                reagentCount = tonumber(GetTradeSkillNumReagents(i)) or 0
            end
            local reagentIndex
            for reagentIndex = 1, reagentCount do
                local reagentName, reagentTexture, required, owned, reagentLink
                if isCraft then
                    reagentName, reagentTexture, required, owned = GetCraftReagentInfo(i, reagentIndex)
                    if GetCraftReagentItemLink then reagentLink = GetCraftReagentItemLink(i, reagentIndex) end
                else
                    reagentName, reagentTexture, required, owned = GetTradeSkillReagentInfo(i, reagentIndex)
                    if GetTradeSkillReagentItemLink then reagentLink = GetTradeSkillReagentItemLink(i, reagentIndex) end
                end
                if reagentName and reagentName ~= "" then
                    local reagentId = CParseItemID(reagentLink)
                    local reagentQuality = 1
                    if reagentId > 0 and GetItemInfo then
                        local _, cachedLink, cachedQuality, _, _, _, _, _, _, cachedTexture = self:GetItemInfoSafe(reagentId)
                        if (not reagentLink or reagentLink == "") and cachedLink then reagentLink = cachedLink end
                        reagentQuality = tonumber(cachedQuality) or 1
                        if not reagentTexture and cachedTexture then reagentTexture = cachedTexture end
                    end
                    table.insert(reagents, {
                        itemId = reagentId, name = CSafeText(reagentName, 48), count = tonumber(required) or 0,
                        owned = tonumber(owned) or 0, icon = reagentTexture, itemLink = reagentLink, quality = reagentQuality,
                    })
                end
            end

            local materialsStatus
            if reagentCount > 0 and table.getn(reagents) == reagentCount then materialsStatus = "COMPLETE"
            elseif reagentCount > 0 then materialsStatus = "PARTIAL" missingMaterialRows = missingMaterialRows + 1
            else materialsStatus = "UNAVAILABLE" missingMaterialRows = missingMaterialRows + 1 end

            local recipeKey = itemId > 0 and tostring(itemId) or CNormalizeText(recipeName)
            if recipeKey ~= "" then
                recipes[recipeKey] = {
                    key = recipeKey, name = CSafeText(recipeName, 80), itemId = itemId,
                    quality = quality, itemLevel = itemLevel, requiredLevel = requiredLevel,
                    requiredSkill = 0, difficulty = recipeType or "unknown",
                    itemType = itemType, itemSubType = itemSubType, equipLoc = equipLoc,
                    itemLink = itemLink, recipeLink = recipeLink, icon = icon,
                    effectText = professionKey == "ENCHANTING" and CSafeText(recipeName, 110) or nil,
                    reagents = reagents, materialsAvailable = materialsStatus == "COMPLETE", materialsStatus = materialsStatus,
                }
            end
        end
    end

    local craft = self:EnsureCraftingDB()
    if not craft then return false end
    local player = string.gsub(UnitName("player") or "Unknown", "%-.*$", "")
    local character = craft.characters[player] or { name = player, professions = {} }
    character.name = player
    character.class = CPlayerClassToken()
    character.level = UnitLevel("player") or 0
    character.updated = self:Now()
    character.localOwner = true
    character.professions = character.professions or {}
    local old = character.professions[professionKey]
    local hash = CHashRecipes(recipes)
    local changed = not old or old.hash ~= hash or CTableCount(old.recipes) ~= CTableCount(recipes)
    local oldCount = old and CTableCount(old.recipes) or 0
    character.professions[professionKey] = {
        key = professionKey, label = professionLabel, rank = tonumber(rank) or 0, maxRank = tonumber(maxRank) or 0,
        ts = self:Now(), hash = hash, recipes = recipes, localOwner = true, incompleteMaterials = missingMaterialRows,
    }
    craft.characters[player] = character

    -- Profession windows often populate reagent links one frame later. Retry only
    -- while the window is open, at most twice, and do not broadcast an incomplete
    -- snapshot before the final attempt.
    if missingMaterialRows > 0 and attempt < 2 then
        self:ScheduleProfessionRescan(mode, attempt + 1, attempt == 0 and 1 or 2)
    end

    if changed then
        local difference = CTableCount(recipes) - oldCount
        local eventTitle
        if difference > 0 then eventTitle = player .. " added " .. tostring(difference) .. " " .. professionLabel .. " recipe" .. (difference == 1 and "" or "s")
        else eventTitle = player .. " updated " .. professionLabel end
        self:AddCraftingEvent("RECIPES", eventTitle, tostring(CTableCount(recipes)) .. " recipes shared", "professions")
        if missingMaterialRows == 0 or attempt >= 2 then self:QueueCraftingProfessionShare(player, professionKey) end
        if self.SetStatus then
            local suffix = missingMaterialRows > 0 and ("; " .. tostring(missingMaterialRows) .. " recipe(s) need another cache pass") or ""
            self:SetStatus(professionLabel .. " scanned: " .. tostring(CTableCount(recipes)) .. " recipes" .. suffix .. ".")
        end
    elseif self.SetStatus and attempt == 0 then
        self:SetStatus(professionLabel .. " is already up to date: " .. tostring(CTableCount(recipes)) .. " recipes.")
    end
    self:OnCraftingDataChanged("RECIPES", false)
    return true, changed, CTableCount(recipes), missingMaterialRows
end

function OTLGM:_Stage_Crafting_QueueCraftingProfessionShare_1(ownerName, professionKey, target, allowRelay)
    local craft = self:EnsureCraftingDB()
    local character = craft and craft.characters and craft.characters[ownerName]
    local profession = character and character.professions and character.professions[professionKey]
    if not character or not profession or (not profession.localOwner and not (target and allowRelay)) then return false end
    local now = self:Now()
    if not target and profession.lastSharedAt and now - profession.lastSharedAt < self.craftingShareCooldown then return false end

    -- RC3 keeps stable IDs plus compact fallback textures/material data. Remote
    -- clients can render immediately even when their item cache is cold.
    local entries = {}
    local keys = CSortedKeys(profession.recipes)
    local i, recipe, reagentIndex, reagent, reagentParts
    for i = 1, table.getn(keys) do
        recipe = profession.recipes[keys[i]]
        reagentParts = {}
        for reagentIndex = 1, math.min(12, table.getn(recipe.reagents or {})) do
            reagent = recipe.reagents[reagentIndex]
            table.insert(reagentParts, table.concat({
                tostring(reagent.itemId or 0),
                CEscape(CSafeText(reagent.name, 48), 84),
                tostring(reagent.count or 0),
                CEscape(CSafeText(reagent.icon or "", 90), 120),
                tostring(reagent.quality or 1)
            }, ":"))
        end
        table.insert(entries, table.concat({
            tostring(recipe.itemId or 0),
            CEscape(CSafeText(recipe.name, 80), 120),
            tostring(recipe.quality or 1),
            tostring(recipe.itemLevel or 0), tostring(recipe.requiredLevel or 0),
            CEscape(CSafeText(recipe.equipLoc or "", 24), 40),
            CEscape(CSafeText(recipe.icon or "", 90), 120),
            CEscape(CSafeText(recipe.materialsStatus or "UNAVAILABLE", 12), 18),
            tostring(table.getn(reagentParts)), table.concat(reagentParts, "+"),
            CEscape(CSafeText(recipe.recipeLink or "", 180), 250),
            CEscape(CSafeText(recipe.itemLink or "", 180), 250),
            CEscape(CSafeText(recipe.effectText or "", 110), 140),
            tostring(recipe.requiredSkill or 0),
            CEscape(CSafeText(recipe.difficulty or "", 12), 18)
        }, ","))
    end

    local wire = table.concat(entries, "~")
    local networkLimit = self.GetNetworkPayloadLimit and self:GetNetworkPayloadLimit(target and "WHISPER" or "GUILD", target) or 250
    local headerReserve = 92 + string.len(CEscape(ownerName, 42)) + string.len(professionKey)
    local chunkSize = math.max(72, math.min(165, networkLimit - 4 - headerReserve))
    local chunks, at = {}, 1
    while at <= string.len(wire) do table.insert(chunks, string.sub(wire, at, at + chunkSize - 1)) at = at + chunkSize end
    if table.getn(chunks) == 0 then table.insert(chunks, "") end
    if table.getn(chunks) > 240 then
        self.communityDroppedPayloads = (self.communityDroppedPayloads or 0) + 1
        self.lastCommunityDroppedSize = string.len(wire)
        if self.SetStatus then self:SetStatus("The profession snapshot is too large to share safely.") end
        return false
    end

    local payloads, totalChunks = {}, table.getn(chunks)
    for i = 1, totalChunks do
        local payload = table.concat({
            self.craftingProtocol, "RC3", CEscape(ownerName, 42), professionKey,
            tostring(profession.ts or now), tostring(profession.rank or 0), tostring(profession.maxRank or 0),
            tostring(i), tostring(totalChunks), tostring(CTableCount(profession.recipes)), tostring(profession.hash or "0"), chunks[i] or ""
        }, "^")
        if string.len(payload) > networkLimit then return false end
        table.insert(payloads, payload)
    end
    if self.CanQueueNetworkPayloads and not self:CanQueueNetworkPayloads(table.getn(payloads), 18) then
        if self.SetStatus then self:SetStatus("The profession snapshot is waiting for network queue space.") end
        return false
    end
    for i = 1, table.getn(payloads) do
        if not self:QueueCommunityPayload(payloads[i], target and "WHISPER" or "GUILD", target, target and 1 or 0) then return false end
    end
    if not target then profession.lastSharedAt = now end
    return true
end

function OTLGM:QueueAllCraftingShares(target)
    local craft = self:EnsureCraftingDB()
    if not craft then return false end
    local queued = false
    local name, character, professionKey
    for name, character in pairs(craft.characters or {}) do
        if character.localOwner then
            for professionKey in pairs(character.professions or {}) do
                if self:QueueCraftingProfessionShare(name, professionKey, target) then queued = true end
            end
        end
    end
    return queued
end

function OTLGM:_Stage_Crafting_RequestCraftingSync_1(force)
    local craft = self:EnsureCraftingDB()
    if not craft or not SendAddonMessage or not GetGuildInfo("player") then return false end
    local now = self:Now()
    if not force and craft.lastSync and now - craft.lastSync < 60 then return false end
    if self.lastCraftingSyncRequestAt and now - self.lastCraftingSyncRequestAt < 20 then return false end
    self.lastCraftingSyncRequestAt = now
    craft.lastSync = now
    craft.syncState = { active = true, started = now, completed = 0, received = 0 }
    self:QueueCommunityPayload(table.concat({ self.craftingProtocol, "SYNC", self.version }, "^"), "GUILD", nil, 2, "crafting:legacy-sync")
    if self.SetStatus then self:SetStatus("Requesting current crafting data from online addon users...") end
    return true
end

function OTLGM:ScheduleCraftingShareResponse(targetName)
    if not targetName or CNormalizeName(targetName) == CNormalizeName(UnitName("player") or "") then return end
    local name = UnitName("player") or "Player"
    local score = 0
    local i
    for i = 1, string.len(name) do score = score + string.byte(name, i) end
    local delay = 2 + math.mod(score, 9)
    self.craftingShareTargets = self.craftingShareTargets or {}
    local normalized = CNormalizeName(targetName)
    local existing = self.craftingShareTargets[normalized]
    local due = self:Now() + delay
    if not existing or due < (existing.due or due) then self.craftingShareTargets[normalized] = { name = targetName, due = due } end
end

function OTLGM:QueueCraftingStateToTarget(targetName)
    if not targetName or targetName == "" then return false end
    local craft = self:EnsureCraftingDB()
    if not craft then return false end

    -- Only the account that owns a character re-sends that character's state.
    -- Relaying every cached request, response and reaction from every online
    -- client creates a duplicate storm in a large guild. Recipe data already
    -- follows the same authoritative localOwner rule.
    local function IsLocalAccountAuthor(authorName)
        local normalized = CNormalizeName(authorName)
        if normalized == CNormalizeName(UnitName("player") or "") then return true end
        local characterName, character
        for characterName, character in pairs(craft.characters or {}) do
            if character.localOwner and CNormalizeName(characterName) == normalized then return true end
        end
        return false
    end

    self:QueueAllCraftingShares(targetName)
    local id, record, targetKey, reactions, author, info
    for id, record in pairs(craft.requests or {}) do
        if IsLocalAccountAuthor(record.author) then self:QueueCommunityPayload(self:SerializeCraftingRequest(record), "WHISPER", targetName) end
    end
    for id, record in pairs(craft.responses or {}) do
        if IsLocalAccountAuthor(record.author) then self:QueueCommunityPayload(self:SerializeCraftingResponse(record), "WHISPER", targetName) end
    end
    for targetKey, reactions in pairs(craft.reactions or {}) do
        local _, _, targetType, targetId = string.find(targetKey, "^([^:]+):(.+)$")
        if targetType and targetId then
            for author, info in pairs(reactions or {}) do
                if IsLocalAccountAuthor(author) then
                    self:QueueCommunityPayload(table.concat({ self.craftingProtocol, "REACT", CEscape(targetType), CEscape(targetId), CEscape(author), CEscape(info.reaction or "NONE"), tostring(info.ts or self:Now()) }, "^"), "WHISPER", targetName)
                end
            end
        end
    end
    return true
end

function OTLGM:_Stage_Crafting_ProcessCraftingTimers_1()
    local normalized, pending
    for normalized, pending in pairs(self.craftingShareTargets or {}) do
        if pending and self:Now() >= (pending.due or 0) then
            self.craftingShareTargets[normalized] = nil
            self:QueueCraftingStateToTarget(pending.name)
            break
        end
    end
    if self.craftingRescan and self:Now() >= (self.craftingRescan.due or 0) then
        local job = self.craftingRescan
        self.craftingRescan = nil
        local frameOpen = (job.mode == "TRADE" and TradeSkillFrame and TradeSkillFrame.IsShown and TradeSkillFrame:IsShown())
            or (job.mode == "CRAFT" and CraftFrame and CraftFrame.IsShown and CraftFrame:IsShown())
        if frameOpen then self:ScanCurrentProfession(job.mode, job.attempt) end
    end
    self:ProcessCraftingCacheQueue()
    local craft = self:EnsureCraftingDB()
    -- Modern manifest recovery can legitimately carry a large profession for
    -- longer than the old 25-second broadcast window. The reliability owner
    -- finishes quiet/no-peer requests earlier and keeps active transfers alive
    -- for the same bounded window enforced by inbound security.
    if craft and craft.syncState and craft.syncState.active and self:Now() - (craft.syncState.started or 0) > 125 then
        craft.syncState.active = false
        if self.SetStatus then self:SetStatus("Crafting sync finished. Received " .. tostring(craft.syncState.received or 0) .. " profession snapshot(s).") end
    end
end

function OTLGM:ApplyRemoteRecipeChunk(fields, sender, channel)
    local craft = self:EnsureCraftingDB()
    if not craft then return false end
    local owner = string.gsub(CUnescape(fields[3] or ""), "%-.*$", "")
    local professionKey = fields[4] or ""
    local timestamp = tonumber(fields[5]) or 0
    local rank = tonumber(fields[6]) or 0
    local maxRank = tonumber(fields[7]) or 0
    local sequence = tonumber(fields[8]) or 1
    local total = tonumber(fields[9]) or 1
    local count = tonumber(fields[10]) or 0
    local hash = fields[11] or "0"
    local payload = fields[12] or ""
    if owner == "" or professionKey == "" or sequence < 1 or total < 1 or sequence > total or total > 200 then return false end
    if channel ~= "WHISPER" and sender and CNormalizeName(owner) ~= CNormalizeName(sender) then return false end
    local existing = craft.characters[owner]
    if existing and existing.localOwner then return true end
    local existingProfession = existing and existing.professions and existing.professions[professionKey]
    local directFromOwner = sender and CNormalizeName(owner) == CNormalizeName(sender)
    if existingProfession and not directFromOwner and (tonumber(existingProfession.ts) or 0) > timestamp then return true end

    local pendingKey = CNormalizeName(sender) .. ":" .. CNormalizeName(owner) .. ":" .. professionKey .. ":" .. tostring(timestamp)
    local pending = craft.pendingRecipes[pendingKey]
    if not pending then
        pending = { owner = owner, professionKey = professionKey, timestamp = timestamp, rank = rank, maxRank = maxRank, total = total, count = count, hash = hash, chunks = {}, sender = sender, created = self:Now() }
        craft.pendingRecipes[pendingKey] = pending
    end
    if pending.total ~= total or pending.hash ~= hash then return false end
    pending.chunks[sequence] = payload
    local received = 0
    local i
    for i = 1, total do if pending.chunks[i] ~= nil then received = received + 1 end end
    if received < total then return true end

    local recipes = {}
    for i = 1, total do
        local entries = CSplit(pending.chunks[i] or "", "~")
        local j, entryFields, itemId, recipeName, quality, key, reagentCount, reagentPayload, reagentEntries, reagentIndex, reagentFields, reagentId, reagentName, reagentRequired
        for j = 1, table.getn(entries) do
            if entries[j] ~= "" then
                entryFields = CSplit(entries[j], ",")
                itemId = tonumber(entryFields[1]) or 0
                recipeName = CUnescape(entryFields[2] or "")
                quality = tonumber(entryFields[3]) or 1
                reagentCount = tonumber(entryFields[4]) or 0
                reagentPayload = entryFields[5] or ""
                local transmittedRecipeLink = CUnescape(entryFields[6] or "")
                local transmittedItemLink = CUnescape(entryFields[7] or "")
                key = itemId > 0 and tostring(itemId) or CNormalizeText(recipeName)
                if key ~= "" then
                    local recipe = { key = key, name = recipeName, itemId = itemId, quality = quality, reagents = {}, materialsAvailable = reagentCount == 0,
                        recipeLink = transmittedRecipeLink ~= "" and transmittedRecipeLink or nil,
                        itemLink = transmittedItemLink ~= "" and transmittedItemLink or nil }
                    if itemId > 0 and GetItemInfo then
                        local _, link, cachedQuality, cachedItemLevel, cachedRequiredLevel, cachedType, cachedSubType, _, cachedEquipLoc, texture = self:GetItemInfoSafe(itemId)
                        if link and link ~= "" then recipe.itemLink = link end
                        recipe.quality = tonumber(cachedQuality) or recipe.quality
                        recipe.itemLevel = tonumber(cachedItemLevel) or 0
                        recipe.requiredLevel = tonumber(cachedRequiredLevel) or 0
                        recipe.itemType = cachedType or ""
                        recipe.itemSubType = cachedSubType or ""
                        recipe.equipLoc = cachedEquipLoc or ""
                        recipe.icon = texture
                    if itemId > 0 and (not recipe.icon or recipe.icon == "") then self:QueueCraftingCacheLookup(itemId, recipe) end
                    end
                    reagentEntries = reagentPayload ~= "" and CSplit(reagentPayload, "+") or {}
                    for reagentIndex = 1, table.getn(reagentEntries) do
                        reagentFields = CSplit(reagentEntries[reagentIndex], ":")
                        reagentId = tonumber(reagentFields[1]) or 0
                        reagentName = CUnescape(reagentFields[2] or "")
                        reagentRequired = tonumber(reagentFields[3]) or 0
                        local reagent = { itemId = reagentId, name = reagentName, count = reagentRequired }
                        if reagentId > 0 and GetItemInfo then
                            local _, link, _, _, _, _, _, _, _, texture = self:GetItemInfoSafe(reagentId)
                            reagent.itemLink = link
                            reagent.icon = texture
                            if reagentId > 0 and (not reagent.icon or reagent.icon == "") then self:QueueCraftingCacheLookup(reagentId, reagent) end
                        end
                        table.insert(recipe.reagents, reagent)
                    end
                    recipe.materialsAvailable = reagentCount == table.getn(recipe.reagents)
                    recipes[key] = recipe
                end
            end
        end
    end
    craft.pendingRecipes[pendingKey] = nil
    if CTableCount(recipes) ~= count then return false end

    local member = self:GetMember(owner)
    local character = existing or { name = owner, professions = {} }
    character.name = owner
    character.class = member and member.class or character.class or ""
    character.level = member and member.level or character.level or 0
    character.updated = self:Now()
    character.source = sender
    character.professions = character.professions or {}
    local label = professionKey
    local definitions = self.professionDefinitions or {}
    for i = 1, table.getn(definitions) do if definitions[i].key == professionKey then label = definitions[i].label break end end
    local old = character.professions[professionKey]
    local changed = not old or old.hash ~= hash
    local oldCount = old and CTableCount(old.recipes) or 0
    character.professions[professionKey] = { key = professionKey, label = label, rank = rank, maxRank = maxRank, ts = timestamp, receivedAt = self:Now(), hash = hash, recipes = recipes }
    craft.characters[owner] = character
    if changed then
        local difference = count - oldCount
        local title = difference > 0 and (owner .. " shared " .. tostring(difference) .. " new " .. label .. " recipe" .. (difference == 1 and "" or "s")) or (owner .. " updated " .. label)
        self:AddCraftingEvent("RECIPES", title, tostring(count) .. " recipes available", "professions", self:Now())
        self:IncrementCraftingUnread("RECIPES")
    end
    self:OnCraftingDataChanged("RECIPES", true)
    return true
end

function OTLGM:_Stage_Crafting_ApplyRemoteRecipeSnapshot155_1(fields, sender, channel)
    local craft = self:EnsureCraftingDB()
    if not craft then return false end
    local owner = string.gsub(CUnescape(fields[3] or ""), "%-.*$", "")
    local professionKey = fields[4] or ""
    local timestamp = tonumber(fields[5]) or 0
    local rank, maxRank = tonumber(fields[6]) or 0, tonumber(fields[7]) or 0
    local sequence, total = tonumber(fields[8]) or 0, tonumber(fields[9]) or 0
    local count, hash, wireChunk = tonumber(fields[10]) or 0, fields[11] or "0", fields[12] or ""
    if owner == "" or professionKey == "" or sequence < 1 or total < 1 or sequence > total or total > 240 or count < 0 then return false end
    if channel ~= "WHISPER" and sender and CNormalizeName(owner) ~= CNormalizeName(sender) then return false end
    local existing = craft.characters[owner]
    if existing and existing.localOwner then return true end
    local pendingKey = "RC3:" .. CNormalizeName(sender) .. ":" .. CNormalizeName(owner) .. ":" .. professionKey .. ":" .. tostring(timestamp) .. ":" .. tostring(hash)
    local pending = craft.pendingRecipes[pendingKey]
    if not pending then
        pending = { owner=owner, professionKey=professionKey, timestamp=timestamp, rank=rank, maxRank=maxRank, total=total, count=count, hash=hash, chunks={}, sender=sender, created=self:Now(), ts=self:Now() }
        craft.pendingRecipes[pendingKey] = pending
    end
    if pending.total ~= total or pending.hash ~= hash or pending.count ~= count then return false end
    pending.chunks[sequence] = wireChunk
    local i
    for i=1,total do if pending.chunks[i] == nil then return true end end
    local wireParts = {}
    for i=1,total do table.insert(wireParts, pending.chunks[i] or "") end
    local wire = table.concat(wireParts)
    local recipes, entries = {}, (wire ~= "" and CSplit(wire,"~") or {})
    local j
    for j=1,table.getn(entries) do
        if entries[j] ~= "" then
            local f=CSplit(entries[j],",")
            local itemId=tonumber(f[1]) or 0
            local recipeName=CUnescape(f[2] or "")
            local key=itemId>0 and tostring(itemId) or CNormalizeText(recipeName)
            local reagentCount=tonumber(f[9]) or 0
            if key ~= "" and recipeName ~= "" and reagentCount >= 0 and reagentCount <= 12 then
                local recipe={ key=key, name=recipeName, itemId=itemId, quality=tonumber(f[3]) or 1,
                    itemLevel=tonumber(f[4]) or 0, requiredLevel=tonumber(f[5]) or 0, equipLoc=CUnescape(f[6] or ""),
                    icon=CUnescape(f[7] or ""), materialsStatus=CUnescape(f[8] or "UNAVAILABLE"), reagents={},
                    recipeLink=(CUnescape(f[11] or "") ~= "" and CUnescape(f[11]) or nil),
                    itemLink=(CUnescape(f[12] or "") ~= "" and CUnescape(f[12]) or nil),
                    effectText=CUnescape(f[13] or ""), requiredSkill=tonumber(f[14]) or 0,
                    difficulty=CUnescape(f[15] or "") }
                local reagentEntries=(f[10] and f[10] ~= "") and CSplit(f[10],"+") or {}
                local ri
                for ri=1,math.min(12,table.getn(reagentEntries)) do
                    local rf=CSplit(reagentEntries[ri],":")
                    local reagent={ itemId=tonumber(rf[1]) or 0, name=CUnescape(rf[2] or ""), count=tonumber(rf[3]) or 0,
                        icon=CUnescape(rf[4] or ""), quality=tonumber(rf[5]) or 1 }
                    if reagent.name ~= "" then
                        table.insert(recipe.reagents,reagent)
                        if reagent.itemId>0 and (not reagent.icon or reagent.icon=="") then self:QueueCraftingCacheLookup(reagent.itemId,reagent) end
                    end
                end
                recipe.materialsAvailable=recipe.materialsStatus=="COMPLETE" and reagentCount==table.getn(recipe.reagents)
                if itemId>0 and (not recipe.icon or recipe.icon=="" or not recipe.itemLink) then self:QueueCraftingCacheLookup(itemId,recipe) end
                recipes[key]=recipe
            end
        end
    end
    craft.pendingRecipes[pendingKey]=nil
    if CTableCount(recipes) ~= count then return false end
    local computedHash = CHashRecipes(recipes)
    local incomingScore = CProfessionCompletenessScore(recipes)
    local member=self:GetMember(owner)
    local character=existing or {name=owner,professions={}}
    character.name=owner; character.class=member and member.class or character.class or ""; character.level=member and member.level or character.level or 0
    character.updated=self:Now(); character.source=sender; character.professions=character.professions or {}
    local label=professionKey
    local definitions=self.professionDefinitions or {}
    for i=1,table.getn(definitions) do if definitions[i].key==professionKey then label=definitions[i].label break end end
    local old=character.professions[professionKey]
    local directFromOwner = sender and CNormalizeName(sender) == CNormalizeName(owner)
    if old then
        local oldTimestamp = tonumber(old.ts) or 0
        local oldScore = tonumber(old.completenessScore) or CProfessionCompletenessScore(old.recipes)
        if oldTimestamp > timestamp then return true end
        -- Once a snapshot was received from its actual owner, an indirect
        -- relay may fill cache gaps but must never replace that trusted source.
        if not directFromOwner and old.sourceKind == "direct" then return true end
        if not directFromOwner and incomingScore < oldScore then return true end
    end
    local changed=not old or old.hash~=computedHash
    local oldCount=old and CTableCount(old.recipes) or 0
    character.professions[professionKey]={
        key=professionKey,label=label,rank=rank,maxRank=maxRank,ts=timestamp,receivedAt=self:Now(),
        hash=computedHash,wireHash=hash,recipes=recipes,completenessScore=incomingScore,
        sourceKind=directFromOwner and "direct" or "relay",source=sender,
    }
    craft.characters[owner]=character
    craft.syncState=craft.syncState or {}
    craft.syncState.received=(craft.syncState.received or 0)+1
    craft.syncState.completed=self:Now()
    if changed then
        local difference=count-oldCount
        local title=difference>0 and (owner.." shared "..tostring(difference).." new "..label.." recipe"..(difference==1 and "" or "s")) or (owner.." updated "..label)
        self:AddCraftingEvent("RECIPES",title,tostring(count).." recipes available","professions",self:Now())
        self:IncrementCraftingUnread("RECIPES")
    end
    self:OnCraftingDataChanged("RECIPES",true)
    return true
end

function OTLGM:ApplyRemoteRecipeSnapshot152(fields, sender, channel)
    local craft = self:EnsureCraftingDB()
    if not craft then return false end
    local owner = string.gsub(CUnescape(fields[3] or ""), "%-.*$", "")
    local professionKey = fields[4] or ""
    local timestamp = tonumber(fields[5]) or 0
    local rank = tonumber(fields[6]) or 0
    local maxRank = tonumber(fields[7]) or 0
    local sequence = tonumber(fields[8]) or 0
    local total = tonumber(fields[9]) or 0
    local count = tonumber(fields[10]) or 0
    local hash = fields[11] or "0"
    local wireChunk = fields[12] or ""
    if owner == "" or professionKey == "" or sequence < 1 or total < 1 or sequence > total or total > 240 or count < 0 then return false end
    if channel ~= "WHISPER" and sender and CNormalizeName(owner) ~= CNormalizeName(sender) then return false end

    local existing = craft.characters[owner]
    if existing and existing.localOwner then return true end
    local existingProfession = existing and existing.professions and existing.professions[professionKey]
    local directFromOwner = sender and CNormalizeName(owner) == CNormalizeName(sender)
    if existingProfession and not directFromOwner and (tonumber(existingProfession.ts) or 0) > timestamp then return true end

    local pendingKey = "RC2:" .. CNormalizeName(sender) .. ":" .. CNormalizeName(owner) .. ":" .. professionKey .. ":" .. tostring(timestamp) .. ":" .. tostring(hash)
    local pending = craft.pendingRecipes[pendingKey]
    if not pending then
        pending = {
            owner = owner, professionKey = professionKey, timestamp = timestamp,
            rank = rank, maxRank = maxRank, total = total, count = count,
            hash = hash, chunks = {}, sender = sender, created = self:Now(), ts = self:Now(),
        }
        craft.pendingRecipes[pendingKey] = pending
    end
    if pending.total ~= total or pending.hash ~= hash or pending.count ~= count then return false end
    pending.chunks[sequence] = wireChunk

    local i
    for i = 1, total do if pending.chunks[i] == nil then return true end end
    local wireParts = {}
    for i = 1, total do table.insert(wireParts, pending.chunks[i] or "") end
    local wire = table.concat(wireParts)

    local recipes = {}
    local entries = wire ~= "" and CSplit(wire, "~") or {}
    local j, entryFields, itemId, recipeName, quality, key
    local reagentCount, reagentPayload, reagentEntries, reagentIndex, reagentFields
    local reagentId, reagentName, reagentRequired
    for j = 1, table.getn(entries) do
        if entries[j] ~= "" then
            entryFields = CSplit(entries[j], ",")
            itemId = tonumber(entryFields[1]) or 0
            recipeName = CUnescape(entryFields[2] or "")
            quality = tonumber(entryFields[3]) or 1
            reagentCount = tonumber(entryFields[4]) or 0
            reagentPayload = entryFields[5] or ""
            local transmittedRecipeLink = CUnescape(entryFields[6] or "")
            local transmittedItemLink = CUnescape(entryFields[7] or "")
            key = itemId > 0 and tostring(itemId) or CNormalizeText(recipeName)
            if key ~= "" and recipeName ~= "" and reagentCount >= 0 and reagentCount <= 12 then
                local recipe = {
                    key = key, name = recipeName, itemId = itemId, quality = quality,
                    reagents = {}, materialsAvailable = reagentCount == 0,
                    recipeLink = transmittedRecipeLink ~= "" and transmittedRecipeLink or nil,
                    itemLink = transmittedItemLink ~= "" and transmittedItemLink or nil,
                }
                if itemId > 0 and GetItemInfo then
                    local _, link, cachedQuality, cachedItemLevel, cachedRequiredLevel, cachedType, cachedSubType, _, cachedEquipLoc, texture = self:GetItemInfoSafe(itemId)
                    if link and link ~= "" then recipe.itemLink = link end
                    recipe.quality = tonumber(cachedQuality) or recipe.quality
                    recipe.itemLevel = tonumber(cachedItemLevel) or 0
                    recipe.requiredLevel = tonumber(cachedRequiredLevel) or 0
                    recipe.itemType = cachedType or ""
                    recipe.itemSubType = cachedSubType or ""
                    recipe.equipLoc = cachedEquipLoc or ""
                    recipe.icon = texture
                    if itemId > 0 and (not recipe.icon or recipe.icon == "") then self:QueueCraftingCacheLookup(itemId, recipe) end
                end
                reagentEntries = reagentPayload ~= "" and CSplit(reagentPayload, "+") or {}
                for reagentIndex = 1, math.min(12, table.getn(reagentEntries)) do
                    reagentFields = CSplit(reagentEntries[reagentIndex], ":")
                    reagentId = tonumber(reagentFields[1]) or 0
                    reagentName = CUnescape(reagentFields[2] or "")
                    reagentRequired = tonumber(reagentFields[3]) or 0
                    if reagentName ~= "" then
                        local reagent = { itemId = reagentId, name = reagentName, count = reagentRequired }
                        if reagentId > 0 and GetItemInfo then
                            local _, link, _, _, _, _, _, _, _, texture = self:GetItemInfoSafe(reagentId)
                            reagent.itemLink = link
                            reagent.icon = texture
                            if reagentId > 0 and (not reagent.icon or reagent.icon == "") then self:QueueCraftingCacheLookup(reagentId, reagent) end
                        end
                        table.insert(recipe.reagents, reagent)
                    end
                end
                recipe.materialsAvailable = reagentCount == table.getn(recipe.reagents)
                recipes[key] = recipe
            end
        end
    end
    craft.pendingRecipes[pendingKey] = nil
    if CTableCount(recipes) ~= count then return false end

    local member = self:GetMember(owner)
    local character = existing or { name = owner, professions = {} }
    character.name = owner
    character.class = member and member.class or character.class or ""
    character.level = member and member.level or character.level or 0
    character.updated = self:Now()
    character.source = sender
    character.professions = character.professions or {}
    local label = professionKey
    local definitions = self.professionDefinitions or {}
    for i = 1, table.getn(definitions) do if definitions[i].key == professionKey then label = definitions[i].label break end end
    local old = character.professions[professionKey]
    local changed = not old or old.hash ~= hash
    local oldCount = old and CTableCount(old.recipes) or 0
    character.professions[professionKey] = {
        key = professionKey, label = label, rank = rank, maxRank = maxRank,
        ts = timestamp, receivedAt = self:Now(), hash = hash, recipes = recipes,
    }
    craft.characters[owner] = character
    if changed then
        local difference = count - oldCount
        local title = difference > 0 and (owner .. " shared " .. tostring(difference) .. " new " .. label .. " recipe" .. (difference == 1 and "" or "s")) or (owner .. " updated " .. label)
        self:AddCraftingEvent("RECIPES", title, tostring(count) .. " recipes available", "professions", self:Now())
        self:IncrementCraftingUnread("RECIPES")
    end
    self:OnCraftingDataChanged("RECIPES", true)
    return true
end

function OTLGM:GetCraftingProfessionDefinitions()
    return {
        { key = "ALL", label = "All Professions", icon = "Interface\\Icons\\INV_Misc_Book_09" },
        { key = "ALCHEMY", label = "Alchemy", icon = "Interface\\Icons\\Trade_Alchemy" },
        { key = "BLACKSMITHING", label = "Blacksmithing", icon = "Interface\\Icons\\Trade_BlackSmithing" },
        { key = "COOKING", label = "Cooking", icon = "Interface\\Icons\\INV_Misc_Food_15" },
        { key = "ENCHANTING", label = "Enchanting", icon = "Interface\\Icons\\Trade_Engraving" },
        { key = "ENGINEERING", label = "Engineering", icon = "Interface\\Icons\\Trade_Engineering" },
        { key = "JEWELCRAFTING", label = "Jewelcrafting", icon = "Interface\\Icons\\INV_Misc_Gem_01" },
        { key = "LEATHERWORKING", label = "Leatherworking", icon = "Interface\\Icons\\Trade_LeatherWorking" },
        { key = "TAILORING", label = "Tailoring", icon = "Interface\\Icons\\Trade_Tailoring" },
        { key = "MINING", label = "Mining / Smelting", icon = "Interface\\Icons\\Trade_Mining" },
    }
end

function OTLGM:GetCraftingItemLink154(recipe)
    if not recipe then return nil end
    local itemId = tonumber(recipe.itemId) or 0
    if itemId > 0 and GetItemInfo then
        local _, link = self:GetItemInfoSafe(itemId)
        if link and link ~= "" then
            recipe.itemLink = link
            return link
        end
    end
    if recipe.itemLink and recipe.itemLink ~= "" then return recipe.itemLink end
    return nil
end

function OTLGM:GetCraftingRecipeLink154(recipe)
    if not recipe then return nil end
    if recipe.recipeLink and recipe.recipeLink ~= "" then return recipe.recipeLink end
    return nil
end

function OTLGM:GetCraftingRecipeLink(recipe)
    return self:GetCraftingItemLink154(recipe)
end

local function CRecipeMetadataScore160(recipe)
    if not recipe then return 0 end
    local score = 0
    if (tonumber(recipe.itemId) or 0) > 0 then score = score + 20 end
    if recipe.itemLink and recipe.itemLink ~= "" then
        score = score + 90
        if string.find(recipe.itemLink, "|Hitem:", 1, true) then score = score + 8 end
    end
    if recipe.recipeLink and recipe.recipeLink ~= "" then score = score + 12 end
    if OTLGM:IsTextureReference(recipe.icon) then score = score + 28 end
    if recipe.effectText and recipe.effectText ~= "" then score = score + 55 end
    if recipe.materialsStatus == "COMPLETE" then score = score + 35 end
    local index, reagent
    for index = 1, table.getn(recipe.reagents or {}) do
        reagent = recipe.reagents[index]
        score = score + 2
        if reagent.itemLink and reagent.itemLink ~= "" then score = score + 2 end
        if OTLGM:IsTextureReference(reagent.icon) then score = score + 3 end
    end
    if type(recipe.itemType) == "string" and recipe.itemType ~= "" then score = score + 4 end
    if type(recipe.itemSubType) == "string" and recipe.itemSubType ~= "" then score = score + 2 end
    return score
end

local function CMergeRecipeMetadata160(target, source)
    if not target or not source then return target end
    local textFields = { "itemLink", "recipeLink", "effectText", "detailKey", "detailHash", "itemType", "difficulty", "requirementText" }
    local index, field
    for index = 1, table.getn(textFields) do
        field = textFields[index]
        if (not target[field] or target[field] == "") and source[field] and source[field] ~= "" then target[field] = source[field] end
    end
    if (tonumber(target.itemId) or 0) <= 0 and (tonumber(source.itemId) or 0) > 0 then target.itemId = source.itemId end
    if not OTLGM:IsTextureReference(target.icon) and OTLGM:IsTextureReference(source.icon) then target.icon = source.icon end
    if type(target.itemSubType) ~= "string" or target.itemSubType == "" then
        if type(source.itemSubType) == "string" then target.itemSubType = source.itemSubType end
    end
    if (not target.equipLoc or target.equipLoc == "" or OTLGM:IsTextureReference(target.equipLoc))
        and type(source.equipLoc) == "string" and not OTLGM:IsTextureReference(source.equipLoc) then target.equipLoc = source.equipLoc end
    local numericFields = { "quality", "itemLevel", "requiredLevel", "requiredSkill" }
    for index = 1, table.getn(numericFields) do
        field = numericFields[index]
        if (tonumber(source[field]) or 0) > (tonumber(target[field]) or 0) then target[field] = source[field] end
    end
    local targetCount = table.getn(target.reagents or {})
    local sourceCount = table.getn(source.reagents or {})
    if sourceCount > targetCount or (target.materialsStatus ~= "COMPLETE" and source.materialsStatus == "COMPLETE") then
        target.reagents = CCopy(source.reagents or {})
        target.materialsStatus = source.materialsStatus
        target.materialsAvailable = source.materialsAvailable
    end
    return target
end

function OTLGM:_Stage_Crafting_GetCraftingSearchResults_1(query, professionFilter)
    local craft = self:EnsureCraftingDB()
    local results = {}
    if not craft then return results end
    self:PurgeCraftingData(true)
    query = CNormalizeText(query)
    professionFilter = professionFilter or "ALL"
    local map = {}
    local characterName, character, professionKey, profession, recipeKey, recipe
    for characterName, character in pairs(craft.characters or {}) do
        for professionKey, profession in pairs(character.professions or {}) do
            if professionFilter == "ALL" or professionFilter == professionKey then
                for recipeKey, recipe in pairs(profession.recipes or {}) do
                    local searchable = CNormalizeText(recipe.name) .. " " .. CNormalizeText(characterName) .. " " .. CNormalizeText(profession.label or professionKey) .. " " .. CNormalizeText(recipe.effectText or "")
                    if self.GetCraftingDetailSearchText then searchable = searchable .. " " .. CNormalizeText(self:GetCraftingDetailSearchText(recipe, professionKey, craft.details)) end
                    local reagentIndex
                    for reagentIndex = 1, table.getn(recipe.reagents or {}) do searchable = searchable .. " " .. CNormalizeText(recipe.reagents[reagentIndex].name) end
                    if query == "" or string.find(searchable, query, 1, true) then
                        local aggregateName = CNormalizeText(recipe.name or "")
                        local aggregateKey = professionKey .. ":" .. (aggregateName ~= "" and aggregateName or tostring(recipeKey))
                        local result = map[aggregateKey]
                        local resultItemId = result and tonumber(result.recipe and result.recipe.itemId) or 0
                        local recipeItemId = tonumber(recipe.itemId) or 0
                        -- A shared display name normally identifies one recipe,
                        -- but never collapse two known, different item results.
                        if result and resultItemId > 0 and recipeItemId > 0 and resultItemId ~= recipeItemId then
                            aggregateKey = aggregateKey .. ":" .. tostring(recipeItemId)
                            result = map[aggregateKey]
                        end
                        if not result then
                            result = {
                                key = aggregateKey, professionKey = professionKey, professionLabel = profession.label or professionKey,
                                recipe = CCopy(recipe), crafters = {}, crafterMap160 = {}, metadataScore160 = CRecipeMetadataScore160(recipe),
                                metadataLocal160 = character.localOwner and true or false, metadataTs160 = profession.ts or character.updated or 0,
                            }
                            map[aggregateKey] = result
                            table.insert(results, result)
                        else
                            local score = CRecipeMetadataScore160(recipe)
                            local currentTs = profession.ts or character.updated or 0
                            local prefer = score > (result.metadataScore160 or 0)
                                or (score == (result.metadataScore160 or 0) and character.localOwner and not result.metadataLocal160)
                                or (score == (result.metadataScore160 or 0) and (character.localOwner and true or false) == result.metadataLocal160 and currentTs > (result.metadataTs160 or 0))
                            if prefer then
                                local previous = result.recipe
                                result.recipe = CMergeRecipeMetadata160(CCopy(recipe), previous)
                                result.metadataLocal160 = character.localOwner and true or false
                                result.metadataTs160 = currentTs
                            else
                                CMergeRecipeMetadata160(result.recipe, recipe)
                            end
                            result.metadataScore160 = CRecipeMetadataScore160(result.recipe)
                        end
                        local crafterKey = CNormalizeText(characterName)
                        if not result.crafterMap160[crafterKey] then
                            local member = self:GetMember(characterName)
                            table.insert(result.crafters, {
                                name = characterName, class = (member and member.class) or character.class or "",
                                level = (member and member.level) or character.level or 0,
                                online = member and member.online and true or false,
                                ts = profession.ts or character.updated or 0,
                                receivedAt = profession.receivedAt,
                                localOwner = character.localOwner and true or false,
                            })
                            result.crafterMap160[crafterKey] = true
                        end
                    end
                end
            end
        end
    end
    local i, result
    for i = 1, table.getn(results) do
        result = results[i]
        table.sort(result.crafters, function(a, b)
            if a.online ~= b.online then return a.online and true or false end
            if (a.ts or 0) ~= (b.ts or 0) then return (a.ts or 0) > (b.ts or 0) end
            return string.lower(a.name or "") < string.lower(b.name or "")
        end)
        result.metadataScore160 = nil
        result.metadataLocal160 = nil
        result.metadataTs160 = nil
        result.crafterMap160 = nil
    end
    table.sort(results, function(a, b)
        local an = string.lower(a.recipe and a.recipe.name or "")
        local bn = string.lower(b.recipe and b.recipe.name or "")
        if an ~= bn then return an < bn end
        return (a.professionLabel or "") < (b.professionLabel or "")
    end)
    return results
end

function OTLGM:GetCraftingSummary()
    local craft = self:EnsureCraftingDB()
    local result = { characters = 0, professions = 0, recipes = 0, uniqueRecipes = 0, requests = 0, responses = 0, unread = 0 }
    if not craft then return result end
    self:PurgeCraftingData(true)
    local unique = {}
    local name, character, professionKey, profession, recipeKey
    for name, character in pairs(craft.characters or {}) do
        local has = false
        for professionKey, profession in pairs(character.professions or {}) do
            result.professions = result.professions + 1
            has = true
            for recipeKey in pairs(profession.recipes or {}) do
                result.recipes = result.recipes + 1
                unique[professionKey .. ":" .. recipeKey] = true
            end
        end
        if has then result.characters = result.characters + 1 end
    end
    result.uniqueRecipes = CTableCount(unique)
    result.requests = CTableCount(craft.requests)
    result.responses = CTableCount(craft.responses)
    result.unread = (craft.unread.RECIPES or 0) + (craft.unread.REQUESTS or 0)
    return result
end

function OTLGM:_Stage_Crafting_GetCraftingProfessionCounts_1(query)
    local counts = { ALL = 0 }
    local results = self:GetCraftingSearchResults(query or "", "ALL")
    local i, result
    for i = 1, table.getn(results) do
        result = results[i]
        counts.ALL = counts.ALL + 1
        counts[result.professionKey] = (counts[result.professionKey] or 0) + 1
    end
    return counts
end

function OTLGM:_Stage_Crafting_CreateCraftingRequest_1(kind, item, materials, note)
    local craft = self:EnsureCraftingDB()
    if not craft then return false, "Guild data is not ready." end
    kind = CSafeText(kind or "CRAFT", 12)
    item = CSafeText(item, 52)
    materials = CSafeText(materials or "READY", 12)
    note = CSafeText(note, 60)
    if item == "" then return false, "Enter the item, recipe or service you need." end
    local now = self:Now()
    if self.lastCraftingRequestAt and now - self.lastCraftingRequestAt < 15 then return false, "Please wait before posting another request." end
    local player = string.gsub(UnitName("player") or "Unknown", "%-.*$", "")
    local own = {}
    local id, request
    for id, request in pairs(craft.requests) do if CNormalizeName(request.author) == CNormalizeName(player) then table.insert(own, request) end end
    table.sort(own, function(a, b) return (a.ts or 0) < (b.ts or 0) end)
    while table.getn(own) >= 3 do self:DeleteCraftingRequest(own[1].id, true) table.remove(own, 1) end
    local record = {
        id = self:MakePveID("C"), rev = 1, ts = now, expires = now + self.craftingRequestLifetime,
        author = player, level = UnitLevel("player") or 0, class = CPlayerClassToken(),
        kind = kind, item = item, materials = materials, note = note, status = "OPEN",
    }
    craft.requests[record.id] = record
    self.lastCraftingRequestAt = now
    self:QueueCommunityPayload(self:SerializeCraftingRequest(record), "GUILD")
    self:AddCraftingEvent("REQUEST", player .. " requested " .. item, note ~= "" and note or ("Materials: " .. materials), "professions", now)
    self:OnCraftingDataChanged("REQUESTS", false)
    return true, record
end

function OTLGM:SerializeCraftingRequest(record)
    local prefix = table.concat({
        self.craftingProtocol, "CREQ", CEscape(record.id, 38), tostring(record.rev or 1), tostring(record.ts or 0), tostring(record.expires or 0),
        CEscape(record.author, 42), tostring(record.level or 0), CEscape(record.class, 20), CEscape(record.kind, 16), CEscape(record.materials, 16)
    }, "^") .. "^"
    local suffix = "^" .. CEscape(record.status or "OPEN", 12)
    local available = math.max(0, 245 - string.len(prefix) - string.len(suffix) - 1)
    local itemBudget = math.min(96, math.max(0, math.floor(available * 0.58)))
    local item = CEscape(record.item, itemBudget)
    local noteBudget = math.max(0, available - string.len(item))
    local note = CEscape(record.note, noteBudget)
    return prefix .. item .. "^" .. note .. suffix
end

function OTLGM:GetCraftingRequests(includeClosed)
    local craft = self:EnsureCraftingDB()
    local result = {}
    if not craft then return result end
    self:PurgeCraftingData(true)
    local id, request
    for id, request in pairs(craft.requests or {}) do
        if includeClosed or request.status ~= "CLOSED" then table.insert(result, request) end
    end
    table.sort(result, function(a, b)
        if (a.status == "CLOSED") ~= (b.status == "CLOSED") then return a.status ~= "CLOSED" end
        if (a.ts or 0) ~= (b.ts or 0) then return (a.ts or 0) > (b.ts or 0) end
        return string.lower(a.author or "") < string.lower(b.author or "")
    end)
    return result
end

function OTLGM:GetCraftingRequestByID(id)
    local craft = self:EnsureCraftingDB()
    return craft and craft.requests and craft.requests[id] or nil
end

function OTLGM:CanModifyCraftingRequest(record)
    if not record then return false end
    if CNormalizeName(record.author) == CNormalizeName(UnitName("player") or "") then return true end
    return self.IsOfficerMode and self:IsOfficerMode()
end

function OTLGM:DeleteCraftingRequest(id, quiet)
    local craft = self:EnsureCraftingDB()
    local record = craft and craft.requests and craft.requests[id]
    if not record or not self:CanModifyCraftingRequest(record) then return false end
    local rev = (tonumber(record.rev) or 0) + 1
    craft.requests[id] = nil
    local responseId, response
    for responseId, response in pairs(craft.responses or {}) do if response.requestId == id then craft.responses[responseId] = nil end end
    craft.reactions["CRAFT:" .. id] = nil
    craft.deleted[id] = { rev = rev, ts = self:Now() }
    self:QueueCommunityPayload(table.concat({ self.craftingProtocol, "CDEL", id, tostring(rev) }, "^"), "GUILD")
    if not quiet then self:OnCraftingDataChanged("REQUESTS", false) end
    return true
end

function OTLGM:CloseCraftingRequest(id)
    local craft = self:EnsureCraftingDB()
    local record = craft and craft.requests and craft.requests[id]
    if not record or not self:CanModifyCraftingRequest(record) then return false end
    record.status = record.status == "CLOSED" and "OPEN" or "CLOSED"
    record.rev = (tonumber(record.rev) or 0) + 1
    record.ts = self:Now()
    self:QueueCommunityPayload(self:SerializeCraftingRequest(record), "GUILD")
    self:OnCraftingDataChanged("REQUESTS", false)
    return true
end

function OTLGM:AddCraftingResponse(requestId, text, canHelp)
    local craft = self:EnsureCraftingDB()
    local request = craft and craft.requests and craft.requests[requestId]
    if not request then return false, "This request is no longer available." end
    if request.status == "CLOSED" then return false, "This request is already closed." end
    text = CSafeText(text, 72)
    if text == "" and not canHelp then return false, "Write a short response first." end
    local now = self:Now()
    if self.lastCraftingResponseAt and now - self.lastCraftingResponseAt < 5 then return false, "Please wait a moment before responding again." end
    local player = string.gsub(UnitName("player") or "Unknown", "%-.*$", "")
    local record = {
        id = self:MakePveID("A"), requestId = requestId, rev = 1, ts = now,
        expires = math.min(request.expires or (now + self.craftingResponseLifetime), now + self.craftingResponseLifetime),
        author = player, class = CPlayerClassToken(), level = UnitLevel("player") or 0,
        canHelp = canHelp and true or false, text = text,
    }
    craft.responses[record.id] = record
    self.lastCraftingResponseAt = now
    self:QueueCommunityPayload(self:SerializeCraftingResponse(record), "GUILD")
    if canHelp then self:SetCommunityReaction("CRAFT", requestId, "HELP", true) end
    self:AddCraftingEvent("RESPONSE", player .. (canHelp and " can help with " or " replied to ") .. (request.item or "a request"), text, "professions", now)
    self:OnCraftingDataChanged("REQUESTS", false)
    return true, record
end

function OTLGM:SerializeCraftingResponse(record)
    local prefix = table.concat({
        self.craftingProtocol, "CRES", CEscape(record.id, 38), CEscape(record.requestId, 38), tostring(record.rev or 1), tostring(record.ts or 0), tostring(record.expires or 0),
        CEscape(record.author, 42), CEscape(record.class, 20), tostring(record.level or 0), record.canHelp and "1" or "0"
    }, "^") .. "^"
    return prefix .. CEscape(record.text, math.max(0, 245 - string.len(prefix)))
end

function OTLGM:GetCraftingResponses(requestId)
    local craft = self:EnsureCraftingDB()
    local result = {}
    if not craft then return result end
    local id, response
    for id, response in pairs(craft.responses or {}) do if response.requestId == requestId then table.insert(result, response) end end
    table.sort(result, function(a, b)
        if a.canHelp ~= b.canHelp then return a.canHelp and true or false end
        if (a.ts or 0) ~= (b.ts or 0) then return (a.ts or 0) > (b.ts or 0) end
        return string.lower(a.author or "") < string.lower(b.author or "")
    end)
    return result
end

function OTLGM:_Stage_Crafting_SetCommunityReaction_1(targetType, targetId, reaction, force)
    local craft = self:EnsureCraftingDB()
    if not craft or not targetType or not targetId then return false end
    local player = string.gsub(UnitName("player") or "Unknown", "%-.*$", "")
    local key = tostring(targetType) .. ":" .. tostring(targetId)
    craft.reactions[key] = craft.reactions[key] or {}
    local existing = craft.reactions[key][player]
    local chosen = reaction
    if not force and existing and existing.reaction == reaction then chosen = "NONE" end
    if chosen == "NONE" or chosen == "" or not chosen then
        craft.reactions[key][player] = nil
        chosen = "NONE"
    else
        craft.reactions[key][player] = { reaction = chosen, ts = self:Now(), author = player }
    end
    self:QueueCommunityPayload(table.concat({ self.craftingProtocol, "REACT", CEscape(targetType), CEscape(targetId), CEscape(player), CEscape(chosen), tostring(self:Now()) }, "^"), "GUILD")
    self:OnCraftingDataChanged(targetType == "CRAFT" and "REQUESTS" or nil, false)
    return true
end

function OTLGM:GetCommunityReactionSummary(targetType, targetId)
    local craft = self:EnsureCraftingDB()
    local result = {}
    if not craft then return result end
    local reactions = craft.reactions[tostring(targetType) .. ":" .. tostring(targetId)] or {}
    local name, info
    for name, info in pairs(reactions) do result[info.reaction or ""] = (result[info.reaction or ""] or 0) + 1 end
    return result
end

function OTLGM:GetCommunityReactors(targetType, targetId, reaction)
    local craft = self:EnsureCraftingDB()
    local result = {}
    if not craft then return result end
    local reactions = craft.reactions[tostring(targetType) .. ":" .. tostring(targetId)] or {}
    local name, info
    for name, info in pairs(reactions) do if not reaction or info.reaction == reaction then table.insert(result, name) end end
    table.sort(result)
    return result
end

function OTLGM:ShareCraftingRequestToGuildChat(record)
    record = record or nil
    if not record then return false end
    local typeLabel = record.kind == "ENCHANT" and "Enchant" or (record.kind == "TRANSMUTE" and "Transmute" or (record.kind == "GEM" and "Gem" or "Craft"))
    local text = "[OTLGM Crafting Request] " .. typeLabel .. ": " .. (record.item or "Unknown item")
    if record.materials == "READY" then text = text .. " - materials ready"
    elseif record.materials == "NEEDED" then text = text .. " - materials needed" end
    if record.note and record.note ~= "" then text = text .. ". " .. record.note end
    text = text .. " Whisper " .. (record.author or "the requester") .. ". Created with the Order of the Lion guild addon."
    text = CSafeText(text, 240)
    if SendChatMessage then pcall(SendChatMessage, text, "GUILD") return true end
    return false
end

function OTLGM:SharePveGroupToGuildChat(record)
    if not record then return false end
    local text = "[OTLGM Group Finder] " .. (record.activity or "Group") .. " - " .. tostring(record.current or 1) .. "/" .. tostring(record.maxSize or 5)
    local needs = {}
    if (tonumber(record.needTank) or 0) > 0 then table.insert(needs, tostring(record.needTank) .. " Tank") end
    if (tonumber(record.needHeal) or 0) > 0 then table.insert(needs, tostring(record.needHeal) .. " Healer") end
    if (tonumber(record.needDps) or 0) > 0 then table.insert(needs, tostring(record.needDps) .. " DPS") end
    if table.getn(needs) > 0 then text = text .. ". Need " .. table.concat(needs, ", ") end
    if record.note and record.note ~= "" then text = text .. ". " .. record.note end
    text = text .. ". Whisper " .. (record.author or "the leader") .. ". Created with the Order of the Lion guild addon."
    text = CSafeText(text, 240)
    if SendChatMessage then pcall(SendChatMessage, text, "GUILD") return true end
    return false
end

function OTLGM:SharePveBoardToGuildChat(record)
    if not record then return false end
    local text = "[OTLGM Guild Board] " .. (record.text or "") .. " - " .. (record.author or "Unknown") .. ". Created with the Order of the Lion guild addon."
    text = CSafeText(text, 240)
    if SendChatMessage then pcall(SendChatMessage, text, "GUILD") return true end
    return false
end

function OTLGM:GetCraftingUnread(section)
    local craft = self:EnsureCraftingDB()
    return craft and tonumber(craft.unread[section or "RECIPES"]) or 0
end

function OTLGM:IncrementCraftingUnread(section)
    local craft = self:EnsureCraftingDB()
    if not craft then return end
    if self.ui and self.ui.main and self.ui.main:IsVisible() and self.ui.currentPage == "professions" and (OTLGM_DB.settings.craftingSection or "RECIPES") == section then return end
    craft.unread[section] = (tonumber(craft.unread[section]) or 0) + 1
end

function OTLGM:MarkCraftingRead(section)
    local craft = self:EnsureCraftingDB()
    if craft then craft.unread[section] = 0 end
end

function OTLGM:_Stage_Crafting_ApplyRemoteCraftingRequest_1(fields, sender, channel)
    local craft = self:EnsureCraftingDB()
    if not craft then return false end
    local id = fields[3] or ""
    local rev = tonumber(fields[4]) or 0
    if id == "" then return false end
    local old = craft.requests[id]
    if old and (tonumber(old.rev) or 0) >= rev then return true end
    local record = {
        id = id, rev = rev, ts = tonumber(fields[5]) or self:Now(), expires = tonumber(fields[6]) or (self:Now() + self.craftingRequestLifetime),
        author = CUnescape(fields[7]), level = tonumber(fields[8]) or 0, class = CUnescape(fields[9]),
        kind = CUnescape(fields[10]), materials = CUnescape(fields[11]), item = CUnescape(fields[12]), note = CUnescape(fields[13]), status = CUnescape(fields[14]),
    }
    if channel ~= "WHISPER" and sender and CNormalizeName(record.author) ~= CNormalizeName(sender) then return false end
    craft.requests[id] = record
    if not old then
        self:IncrementCraftingUnread("REQUESTS")
        self:AddCraftingEvent("REQUEST", record.author .. " requested " .. record.item, record.note, "professions", record.ts)
    end
    self:OnCraftingDataChanged("REQUESTS", true)
    return true
end

function OTLGM:_Stage_Crafting_ApplyRemoteCraftingResponse_1(fields, sender, channel)
    local craft = self:EnsureCraftingDB()
    if not craft then return false end
    local id = fields[3] or ""
    local requestId = fields[4] or ""
    local rev = tonumber(fields[5]) or 0
    if id == "" or requestId == "" then return false end
    local old = craft.responses[id]
    if old and (tonumber(old.rev) or 0) >= rev then return true end
    local record = {
        id = id, requestId = requestId, rev = rev, ts = tonumber(fields[6]) or self:Now(), expires = tonumber(fields[7]) or (self:Now() + self.craftingResponseLifetime),
        author = CUnescape(fields[8]), class = CUnescape(fields[9]), level = tonumber(fields[10]) or 0,
        canHelp = fields[11] == "1", text = CUnescape(fields[12]),
    }
    if channel ~= "WHISPER" and sender and CNormalizeName(record.author) ~= CNormalizeName(sender) then return false end
    craft.responses[id] = record
    if not old then
        self:IncrementCraftingUnread("REQUESTS")
        local request = craft.requests[requestId]
        self:AddCraftingEvent("RESPONSE", record.author .. (record.canHelp and " can help" or " replied"), request and request.item or record.text, "professions", record.ts)
    end
    self:OnCraftingDataChanged("REQUESTS", true)
    return true
end

function OTLGM:_Stage_Crafting_ApplyRemoteReaction_1(fields, sender, channel)
    local craft = self:EnsureCraftingDB()
    if not craft then return false end
    local targetType = CUnescape(fields[3])
    local targetId = CUnescape(fields[4])
    local author = string.gsub(CUnescape(fields[5]), "%-.*$", "")
    local reaction = CUnescape(fields[6])
    local timestamp = tonumber(fields[7]) or self:Now()
    if targetType == "" or targetId == "" or author == "" then return false end
    if channel ~= "WHISPER" and sender and CNormalizeName(author) ~= CNormalizeName(sender) then return false end
    local key = targetType .. ":" .. targetId
    craft.reactions[key] = craft.reactions[key] or {}
    local old = craft.reactions[key][author]
    if old and (old.ts or 0) > timestamp then return true end
    if reaction == "NONE" or reaction == "" then craft.reactions[key][author] = nil
    else craft.reactions[key][author] = { reaction = reaction, ts = timestamp, author = author } end
    self:OnCraftingDataChanged(targetType == "CRAFT" and "REQUESTS" or nil, true)
    return true
end

function OTLGM:ApplyRemoteCraftingDelete(fields, sender)
    local craft = self:EnsureCraftingDB()
    if not craft then return false end
    local id = fields[3] or ""
    local rev = tonumber(fields[4]) or 0
    local old = craft.requests[id]
    if old and (tonumber(old.rev) or 0) > rev then return true end
    if old and sender and CNormalizeName(old.author) ~= CNormalizeName(sender) and not (self.IsPveLeadershipName and self:IsPveLeadershipName(sender) == true) then return false end
    craft.requests[id] = nil
    local responseId, response
    for responseId, response in pairs(craft.responses or {}) do if response.requestId == id then craft.responses[responseId] = nil end end
    craft.reactions["CRAFT:" .. id] = nil
    craft.deleted[id] = { rev = rev, ts = self:Now() }
    self:OnCraftingDataChanged("REQUESTS", true)
    return true
end

function OTLGM:_Stage_Crafting_HandleCommunityAddonMessage_1(message, channel, sender)
    if string.sub(message or "", 1, 3) ~= self.craftingProtocol .. "^" then return false end
    local fields = CSplit(message, "^")
    local kind = fields[2]
    if kind == "SYNC" then self:ScheduleCraftingShareResponse(sender) return true end
    if kind == "RC3" then return self:ApplyRemoteRecipeSnapshot155(fields, sender, channel) end
    if kind == "RC2" then return self:ApplyRemoteRecipeSnapshot152(fields, sender, channel) end
    if kind == "RCP" then return self:ApplyRemoteRecipeChunk(fields, sender, channel) end
    if kind == "CREQ" then return self:ApplyRemoteCraftingRequest(fields, sender, channel) end
    if kind == "CRES" then return self:ApplyRemoteCraftingResponse(fields, sender, channel) end
    if kind == "REACT" then return self:ApplyRemoteReaction(fields, sender, channel) end
    if kind == "CDEL" then return self:ApplyRemoteCraftingDelete(fields, sender) end
    return false
end

function OTLGM:_Stage_Crafting_OnCraftingDataChanged_1(section, remote)
    if self.ui and self.ui.main and self.ui.main:IsVisible() then
        if self.RefreshProfessionsPage and self.ui.currentPage == "professions" then self:RefreshProfessionsPage() end
        if self.RefreshHomePage and self.ui.currentPage == "home" then self:RefreshHomePage() end
        if self.RefreshSearchPage and self.ui.currentPage == "search" then self:RefreshSearchPage() end
        if self.RefreshPvePage and self.ui.currentPage == "pve" then self:RefreshPvePage() end
        if self.RefreshNavigation then self:RefreshNavigation() end
    end
end

function OTLGM:GetGlobalSearchResults(query)
    query = CNormalizeText(query)
    local results = {}
    if query == "" then return results end
    local db = self:GetGuildDB()
    local name, member
    for name, member in pairs(db and db.roster or {}) do
        local haystack = CNormalizeText((name or "") .. " " .. (member.class or "") .. " " .. (member.rank or "") .. " " .. (member.zone or "") .. " " .. (member.publicNote or ""))
        if string.find(haystack, query, 1, true) then
            table.insert(results, { type = "MEMBER", title = name, detail = "Level " .. tostring(member.level or 0) .. " " .. (member.class or "") .. " - " .. (member.rank or ""), page = "roster", target = name, priority = member.online and 1 or 3 })
        end
    end
    local recipes = self:GetCraftingSearchResults(query, "ALL")
    local i, result
    for i = 1, math.min(20, table.getn(recipes)) do
        result = recipes[i]
        local online = 0
        local j
        for j = 1, table.getn(result.crafters or {}) do if result.crafters[j].online then online = online + 1 end end
        table.insert(results, { type = "RECIPE", title = result.recipe.name, detail = result.professionLabel .. " - " .. tostring(table.getn(result.crafters or {})) .. " crafter(s), " .. tostring(online) .. " online", page = "professions", target = result.key, priority = online > 0 and 1 or 2 })
    end
    local pve = self.EnsurePveDB and self:EnsurePveDB() or nil
    local id, record, haystack
    for id, record in pairs(pve and pve.requests or {}) do
        haystack = CNormalizeText((record.activity or "") .. " " .. (record.note or "") .. " " .. (record.author or ""))
        if string.find(haystack, query, 1, true) then table.insert(results, { type = "GROUP", title = record.activity or "Open group", detail = "Leader: " .. (record.author or "") .. " - " .. tostring(record.current or 1) .. "/" .. tostring(record.maxSize or 5), page = "pve", target = id, section = "GROUPS", priority = 1 }) end
    end
    for id, record in pairs(pve and pve.board or {}) do
        haystack = CNormalizeText((record.text or "") .. " " .. (record.author or ""))
        if string.find(haystack, query, 1, true) then table.insert(results, { type = "BOARD", title = record.author or "Guild Board", detail = record.text or "", page = "pve", target = id, section = "BOARD", priority = 2 }) end
    end
    local craft = self:EnsureCraftingDB()
    for id, record in pairs(craft and craft.requests or {}) do
        haystack = CNormalizeText((record.item or "") .. " " .. (record.note or "") .. " " .. (record.author or "") .. " " .. (record.kind or ""))
        if string.find(haystack, query, 1, true) then table.insert(results, { type = "CRAFT REQUEST", title = record.item or "Crafting request", detail = record.author .. " - " .. (record.note or ""), page = "professions", target = id, section = "REQUESTS", priority = 1 }) end
    end
    if self.GetAnnouncementList152 then
        local announcements = self:GetAnnouncementList152(true)
        for i = 1, table.getn(announcements) do
            record = announcements[i]
            haystack = CNormalizeText((record.title or "") .. " " .. (record.body or "") .. " " .. (record.author or ""))
            if string.find(haystack, query, 1, true) then
                table.insert(results, { type = "ANNOUNCEMENT", title = record.title or "Leadership announcement", detail = (record.author or "Leadership") .. " - " .. string.sub(record.body or "", 1, 100), page = "home", target = record.id, priority = record.pinned and 0 or 1 })
            end
        end
    end
    table.sort(results, function(a, b)
        if (a.priority or 5) ~= (b.priority or 5) then return (a.priority or 5) < (b.priority or 5) end
        if a.type ~= b.type then return a.type < b.type end
        return string.lower(a.title or "") < string.lower(b.title or "")
    end)
    while table.getn(results) > 50 do table.remove(results) end
    return results
end

OTLGM:RegisterModule("Crafting", { layer = "feature", protocol = OTLGM.craftingProtocol })
