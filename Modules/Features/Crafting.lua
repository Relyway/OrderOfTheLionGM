-- Order of the Lion Guild Manager
-- Crafting Network records, profession snapshots, requests and reactions.

OTLGM.craftingProtocol = "C1"
OTLGM.craftingRequestLifetime = 86400
OTLGM.craftingResponseLifetime = 86400
OTLGM.craftingShareCooldown = 8
-- r46: a four-week window is a soft availability signal only. Older crafter
-- records are kept for rare-recipe history; they are simply de-prioritized and
-- excluded from the primary recent-crafter counts. No hard age purge is tied
-- to this value.
OTLGM.craftingRecentCrafterWindowR46 = 28 * 86400

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

-- R27: recipes whose crafted output binds on pickup are useful to the owner but
-- cannot be fulfilled for another guild member. Keep them in the local profession
-- snapshot for honesty, while excluding them from guild search/counts/transfers.
local function CShareableRecipeR27(recipe)
    return not (type(recipe) == "table" and recipe.personalOnlyR27)
end

local function CShareableRecipeKeysR27(recipes)
    local keys, key, recipe = {}, nil, nil
    for key, recipe in pairs(recipes or {}) do
        if CShareableRecipeR27(recipe) then table.insert(keys, key) end
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    return keys
end

local function CShareableRecipeCountR27(recipes)
    local count, _, recipe = 0, nil, nil
    for _, recipe in pairs(recipes or {}) do if CShareableRecipeR27(recipe) then count = count + 1 end end
    return count
end

function OTLGM:IsShareableCraftingRecipeR27(recipe)
    return CShareableRecipeR27(recipe)
end

local function CActivityHashR46(hash, text)
    text = tostring(text or "")
    local index
    for index = 1, string.len(text) do
        hash = math.mod((hash * 33) + string.byte(text, index), 2176782336)
    end
    return hash
end

-- r46: one shared activity interpretation for Professions. It deliberately
-- prefers the authoritative roster's last-online age over the age of the
-- recipe snapshot. Snapshot age is only a fallback when the roster API cannot
-- provide a member/last-online value. Nothing is deleted here.
function OTLGM:GetCraftingCrafterActivityR46(name, source)
    self.runtime = self.runtime or {}
    local now = self:Now()
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local scan = tonumber(db and db.lastScan) or 0
    local targetedRevision = tonumber(self.runtime.rosterTargetRevision184) or 0
    local normalized = self:NormalizeName(name or "")
    local activityCache = self.runtime.craftingCrafterActivityCacheR46
    if not activityCache or activityCache.scan ~= scan or activityCache.targetedRevision ~= targetedRevision then
        activityCache = { scan = scan, targetedRevision = targetedRevision, entries = {} }
        self.runtime.craftingCrafterActivityCacheR46 = activityCache
    end
    local cached = normalized ~= "" and activityCache.entries[normalized] or nil
    if cached then
        self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
        self.runtime.craftingMetrics180.activitySnapshotHitsR46 = (tonumber(self.runtime.craftingMetrics180.activitySnapshotHitsR46) or 0) + 1
        return cached
    end
    local member = self.GetMember and self:GetMember(name or "") or nil
    local rosterAuthoritative = db and db.initialized and scan > 0 and (tonumber(db.lastTotal) or 0) > 0
    local online = member and member.online and true or false
    local ageSeconds, ageKnown = 0, false
    if online then
        ageSeconds, ageKnown = 0, true
    elseif member and ((tonumber(member.offlineHours) or 0) > 0 or (member.lastOnlineText and member.lastOnlineText ~= "Offline" and member.lastOnlineText ~= "Online")) then
        ageSeconds = math.max(0, (tonumber(member.offlineHours) or 0) * 3600)
        ageKnown = true
    elseif member and tonumber(member.lastSeen) and tonumber(member.lastSeen) > 0 then
        ageSeconds = math.max(0, now - tonumber(member.lastSeen))
        ageKnown = true
    else
        local sourceTs = tonumber(source and (source.ts or source.updated or source.receivedAt)) or 0
        if sourceTs > 0 then
            ageSeconds = math.max(0, now - sourceTs)
            ageKnown = true
        end
    end
    local departed = rosterAuthoritative and not member and not (source and source.localOwner)
    local older = departed or (ageKnown and ageSeconds >= (tonumber(self.craftingRecentCrafterWindowR46) or (28 * 86400)))
    local recent = not departed and (online or not older)
    local ageDays = ageKnown and math.floor(ageSeconds / 86400) or nil
    local label
    if online then
        label = "Online"
    elseif member and member.lastOnlineText and member.lastOnlineText ~= "Offline" and member.lastOnlineText ~= "Online" then
        label = older and ("Inactive " .. tostring(member.lastOnlineText)) or ("Offline " .. tostring(member.lastOnlineText))
    elseif member and ageKnown then
        if older then label = "Inactive " .. tostring(ageDays or 0) .. "d"
        elseif ageSeconds < 86400 then label = "Offline <1d"
        else label = "Offline " .. tostring(ageDays or 0) .. "d" end
    elseif ageDays then
        label = older and ("Stored " .. tostring(ageDays) .. "d") or ("Stored recently")
    else
        label = departed and "No longer in guild" or "Stored"
    end
    local group = online and 0 or (recent and 1 or (departed and 3 or 2))
    local alpha = online and 1.0 or (recent and 0.88 or 0.58)
    local result = {
        online = online, recent = recent, older = older, departed = departed,
        ageSeconds = ageKnown and ageSeconds or 2147483647, ageDays = ageDays,
        group = group, alpha = alpha, label = label, member = member,
    }
    -- A roster member's activity is independent of which recipe references the
    -- character, so cache it once. Missing members may need the individual
    -- snapshot timestamp as fallback and therefore remain uncached.
    if member and normalized ~= "" then activityCache.entries[normalized] = result end
    self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
    self.runtime.craftingMetrics180.activitySnapshotBuildsR46 = (tonumber(self.runtime.craftingMetrics180.activitySnapshotBuildsR46) or 0) + 1
    return result
end
function OTLGM:GetCraftingRecipeRevisionR46()
    self.runtime = self.runtime or {}
    return tonumber(self.runtime.craftingRecipeRevisionR46) or 0
end

-- The token changes only when crafter-relevant roster state changes (online,
-- recent/older band, class or level), not merely because another full roster
-- scan updated db.lastScan. This keeps the profession search cache alive across
-- no-op guild scans while still reacting immediately to meaningful availability
-- changes.
function OTLGM:GetCraftingRosterActivityTokenR46()
    self.runtime = self.runtime or {}
    local craft = self:EnsureCraftingDB()
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local scan = tonumber(db and db.lastScan) or 0
    local targetedRevision = tonumber(self.runtime.rosterTargetRevision184) or 0
    local revision = self:GetCraftingRecipeRevisionR46()
    local cached = self.runtime.craftingActivityTokenR46
    if cached and cached.scan == scan and cached.targetedRevision == targetedRevision and cached.revision == revision and cached.characters == (craft and craft.characters) then
        return cached.token
    end
    local hash, onlineCount, recentCount, olderCount = 17, 0, 0, 0
    local names = CSortedKeys(craft and craft.characters or {})
    local index, name, character, activity, member, signature
    for index = 1, table.getn(names) do
        name = names[index]
        character = craft.characters[name]
        activity = self:GetCraftingCrafterActivityR46(name, character)
        member = activity.member
        if activity.online then onlineCount = onlineCount + 1 end
        if activity.recent then recentCount = recentCount + 1 else olderCount = olderCount + 1 end
        signature = table.concat({
            self:NormalizeName(name or ""), tostring(activity.group or 0),
            tostring(member and member.level or character and character.level or 0),
            tostring(member and member.class or character and character.class or ""),
        }, ":")
        hash = CActivityHashR46(hash, signature)
    end
    local token = tostring(hash) .. ":" .. tostring(onlineCount) .. ":" .. tostring(recentCount) .. ":" .. tostring(olderCount)
    self.runtime.craftingActivityTokenR46 = { scan = scan, targetedRevision = targetedRevision, revision = revision, characters = craft and craft.characters, token = token }
    self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
    self.runtime.craftingMetrics180.activityTokenBuildsR46 = (tonumber(self.runtime.craftingMetrics180.activityTokenBuildsR46) or 0) + 1
    self.runtime.craftingMetrics180.activityRecentCharactersR46 = recentCount
    self.runtime.craftingMetrics180.activityOlderCharactersR46 = olderCount
    return token
end

-- Silent maintenance used to remove records without invalidating the immutable
-- aggregate/search caches. Keep the UI quiet, but always invalidate derived data
-- when the authoritative crafting store actually changed.
function OTLGM:InvalidateCraftingDerivedCachesR46(reason, bumpRevision)
    self.runtime = self.runtime or {}
    local reasonText = tostring(reason or "data")
    local recipeChanged = reason == nil or reasonText == "RECIPES" or reasonText == "data" or reasonText == "maintenance-purge-recipes"
    if bumpRevision ~= false then
        self.runtime.craftingDataRevisionRC3 = (tonumber(self.runtime.craftingDataRevisionRC3) or 0) + 1
        self.runtime.craftingLastChangeAtRC3 = self:Now()
    end
    if recipeChanged then
        self.runtime.craftingSummaryCacheR46 = nil
        self.runtime.craftingRecipeRevisionR46 = (tonumber(self.runtime.craftingRecipeRevisionR46) or 0) + 1
        self.runtime.craftingActivityTokenR46 = nil
        self.runtime.craftingCrafterActivityCacheR46 = nil
        if self.InvalidateCraftingAggregateIndexR30 then self:InvalidateCraftingAggregateIndexR30(reasonText) end
        if self.InvalidateCraftingSearchCache then self:InvalidateCraftingSearchCache() end
    else
        self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
        self.runtime.craftingMetrics180.nonRecipeInvalidationsAvoidedR46 = (tonumber(self.runtime.craftingMetrics180.nonRecipeInvalidationsAvoidedR46) or 0) + 1
    end
    -- Global Search also contains crafting requests, so its cache follows the
    -- general crafting revision even when the recipe catalogue itself did not
    -- change.
    if self.InvalidateGlobalSearchCache185 then self:InvalidateGlobalSearchCache185("crafting") end
end
local function CPruneMapByTime(map, maximum)
    local entries = {}
    local key, value
    for key, value in pairs(map or {}) do
        local ts
        if type(value) == "table" then ts = tonumber(value.ts or value.updated or value.created) else ts = tonumber(value) end
        table.insert(entries, { key = key, ts = ts or 0 })
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
    local keys = CShareableRecipeKeysR27(recipes)
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
            tostring(recipe and recipe.effectText or ""), tostring(recipe and recipe.effectSource183 or ""),
            tostring(recipe and recipe.requiredSkill or 0), tostring(recipe and recipe.difficulty or ""),
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
        if CShareableRecipeR27(recipe) then
            recipeCount = recipeCount + 1
            if recipe.icon and recipe.icon ~= "" then iconCount = iconCount + 1 end
            if recipe.materialsStatus == "COMPLETE" or recipe.materialsAvailable then materialCount = materialCount + 1 end
            if (tonumber(recipe.itemId) or 0) > 0 or (recipe.itemLink and recipe.itemLink ~= "") or (recipe.recipeLink and recipe.recipeLink ~= "") then metadataCount = metadataCount + 1 end
        end
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

-- One immutable crafting registry feeds TradeSkill detection, tabs and remote
-- labels. Keeping it local avoids allocating a new definition table on every
-- page refresh. Survival is deliberately exact-only: outside a real
-- TradeSkill/Craft context that word can describe a Hunter specialization.
local CRAFTING_PROFESSION_DEFINITIONS183 = {
    { key = "ALL", label = "All Professions", icon = "Interface\\Icons\\INV_Misc_Book_09", terms = {} },
    { key = "ALCHEMY", label = "Alchemy", icon = "Interface\\Icons\\Trade_Alchemy", terms = { "alchemy" } },
    { key = "BLACKSMITHING", label = "Blacksmithing", icon = "Interface\\Icons\\Trade_BlackSmithing", terms = { "blacksmithing", "blacksmith" } },
    { key = "COOKING", label = "Cooking", icon = "Interface\\Icons\\INV_Misc_Food_15", terms = { "cooking", "cook" } },
    { key = "ENCHANTING", label = "Enchanting", icon = "Interface\\Icons\\Trade_Engraving", terms = { "enchanting", "enchant" } },
    { key = "ENGINEERING", label = "Engineering", icon = "Interface\\Icons\\Trade_Engineering", terms = { "engineering", "engineer" } },
    { key = "JEWELCRAFTING", label = "Jewelcrafting", icon = "Interface\\Icons\\INV_Misc_Gem_01", terms = { "jewelcrafting", "jewelcraft", "jewel crafter" } },
    { key = "LEATHERWORKING", label = "Leatherworking", icon = "Interface\\Icons\\Trade_LeatherWorking", terms = { "leatherworking", "leatherworker" } },
    { key = "TAILORING", label = "Tailoring", icon = "Interface\\Icons\\Trade_Tailoring", terms = { "tailoring", "tailor" } },
    { key = "MINING", label = "Mining / Smelting", icon = "Interface\\Icons\\Trade_Mining", terms = { "mining", "smelting" } },
    { key = "SURVIVAL", label = "Survival", icon = "Interface\\Icons\\Ability_Hunter_AspectOfTheMonkey", terms = { "survival" }, exactOnly183 = true },
}

local CRAFTING_PROFESSION_BY_KEY183 = {}
local professionDefinitionIndex183
for professionDefinitionIndex183 = 1, table.getn(CRAFTING_PROFESSION_DEFINITIONS183) do
    local definition183 = CRAFTING_PROFESSION_DEFINITIONS183[professionDefinitionIndex183]
    CRAFTING_PROFESSION_BY_KEY183[definition183.key] = definition183
end

local function CProfessionKey(rawName)
    local normalized = CNormalizeText(rawName)
    local i, j, definition, term
    for i = 1, table.getn(CRAFTING_PROFESSION_DEFINITIONS183) do
        definition = CRAFTING_PROFESSION_DEFINITIONS183[i]
        if definition.key ~= "ALL" then
            for j = 1, table.getn(definition.terms or {}) do
                term = definition.terms[j]
                if (definition.exactOnly183 and normalized == term)
                    or (not definition.exactOnly183 and (normalized == term or string.find(normalized, term, 1, true))) then
                    return definition.key, definition.label
                end
            end
        end
    end
    return nil, nil
end

local function CProfessionLabel183(professionKey)
    local definition = CRAFTING_PROFESSION_BY_KEY183[tostring(professionKey or "")]
    return definition and definition.label or tostring(professionKey or "")
end

local function CPlayerClassToken()
    local _, token = UnitClass("player")
    return token or ""
end

local function CNormalizeRequestStatus(status)
    status = string.upper(CSafeText(status or "OPEN", 12))
    if status == "CLOSED" then return "COMPLETED" end
    if status == "OPEN" or status == "CLAIMED" or status == "COMPLETED" then return status end
    -- Forward-compatible fail-open behaviour for a 1.7.6-shaped record whose
    -- status was written by a newer client.
    return "OPEN"
end

local function CRequestStatusPriority(status)
    status = CNormalizeRequestStatus(status)
    if status == "COMPLETED" then return 2 end
    if status == "CLAIMED" then return 1 end
    return 0
end

function OTLGM.__impl180.Stage_Crafting_EnsureCraftingDB_1__impl1(self)
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
    if type(craft.requestMatchSeen180) ~= "table" then craft.requestMatchSeen180 = {} end
    -- Optional request metadata may arrive before the core CREQ packet. It is
    -- intentionally runtime-only so stale partial transfers cannot survive a
    -- reload and masquerade as canonical request data.
    craft.pendingRequestMeta180 = nil
    self.runtime = self.runtime or {}
    self.runtime.crafting = self.runtime.crafting or {}
    if type(self.runtime.crafting.pendingRequestMeta180) ~= "table" then self.runtime.crafting.pendingRequestMeta180 = {} end
    if type(craft.unread) ~= "table" then craft.unread = { RECIPES = 0, REQUESTS = 0 } end
    if craft.unread.PROFESSIONS and not craft.unread.RECIPES then craft.unread.RECIPES = craft.unread.PROFESSIONS end
    craft.unread.PROFESSIONS = nil
    craft.lastSync = craft.lastSync or 0
    if type(craft.pendingRecipes) ~= "table" then craft.pendingRecipes = {} end
    if type(craft.syncState) ~= "table" then craft.syncState = { active = false, started = 0, completed = 0, received = 0 } end
    local requestId, request
    for requestId, request in pairs(craft.requests) do
        if type(request) ~= "table" then
            craft.requests[requestId] = nil
        else
            local oldStatus = string.upper(CSafeText(request.status or "OPEN", 24))
            request.status = CNormalizeRequestStatus(oldStatus)
            request.stateRev = math.max(0, tonumber(request.stateRev) or 0)
            request.stateTs = tonumber(request.stateTs) or tonumber(request.ts) or 0
            local requestSource = string.upper(CSafeText(request.source or "GENERIC", 12))
            request.source = requestSource == "RECIPE" and "RECIPE" or "GENERIC"
            if request.source == "RECIPE" then
                request.recipeKey = CSafeText(request.recipeKey, 80)
                request.itemId = math.max(0, tonumber(request.itemId) or 0)
                request.professionKey = string.upper(CSafeText(request.professionKey, 28))
                local quality = tonumber(request.itemQuality or request.quality)
                request.itemQuality = quality and math.max(0, math.min(7, math.floor(quality))) or nil
                request.displayName = CSafeText(request.displayName or request.item, 96)
                request.recipeName = CSafeText(request.recipeName or request.displayName or request.item, 96)
                request.itemLink = request.itemLink and tostring(request.itemLink) or nil
            else
                request.source = "GENERIC"
                request.displayName = CSafeText(request.displayName or request.item, 96)
            end
            if request.status == "COMPLETED" then
                request.stateRev = math.max(1, request.stateRev)
                request.completedAt = tonumber(request.completedAt) or request.stateTs
            elseif request.status == "OPEN" and oldStatus ~= "OPEN" then
                -- Unknown future states are deliberately safe on this client.
                request.stateRev = 0
                request.claimedBy = nil
                request.claimedAt = nil
                request.completedBy = nil
                request.completedAt = nil
            end
        end
    end

    OTLGM_DB.settings.craftingSection = OTLGM_DB.settings.craftingSection or "RECIPES"
    OTLGM_DB.settings.craftingProfession = OTLGM_DB.settings.craftingProfession or "ALL"
    OTLGM_DB.settings.craftingSearch = OTLGM_DB.settings.craftingSearch or ""
    OTLGM_DB.settings.craftingRequestTemplate = OTLGM_DB.settings.craftingRequestTemplate or "CRAFT"
    OTLGM_DB.settings.craftingMaterials = OTLGM_DB.settings.craftingMaterials or "READY"
    if OTLGM_DB.settings.craftingShareEnabled == nil then OTLGM_DB.settings.craftingShareEnabled = true end
    if OTLGM_DB.settings.craftingAutoSync == nil then OTLGM_DB.settings.craftingAutoSync = true end
    if OTLGM_DB.settings.c7CraftableRequests180 == nil then OTLGM_DB.settings.c7CraftableRequests180 = true end
    return craft
end

local function CRequestMetaSource180(value)
    value = string.upper(CSafeText(value or "GENERIC", 12))
    if value == "RECIPE" then return "RECIPE" end
    return "GENERIC"
end

local function CRequestMetaQuality180(value)
    value = tonumber(value)
    if not value then return nil end
    return math.max(0, math.min(7, math.floor(value)))
end

function OTLGM:GetPendingCraftingRequestMeta180()
    self.runtime = self.runtime or {}
    self.runtime.crafting = self.runtime.crafting or {}
    if type(self.runtime.crafting.pendingRequestMeta180) ~= "table" then self.runtime.crafting.pendingRequestMeta180 = {} end
    return self.runtime.crafting.pendingRequestMeta180
end

function OTLGM:IsCraftingRequestMetaSenderAllowed180(record, sender, channel)
    if not record or not sender or sender == "" then return false end
    if CNormalizeName(record.author) == CNormalizeName(sender) then return true end
    local craft = self:EnsureCraftingDB()
    return channel == "WHISPER" and craft and craft.syncState and craft.syncState.active
        and self:Now() - (tonumber(craft.syncState.started) or 0) <= 120
end

function OTLGM:NormalizeCraftingRequestMeta180(meta)
    if type(meta) ~= "table" then return nil end
    local normalized = {
        requestId = CSafeText(meta.requestId or meta.id, 64),
        requestRev = math.max(0, tonumber(meta.requestRev or meta.rev) or 0),
        source = CRequestMetaSource180(meta.source),
        recipeKey = CSafeText(meta.recipeKey, 80),
        itemId = math.max(0, tonumber(meta.itemId) or 0),
        professionKey = string.upper(CSafeText(meta.professionKey, 28)),
        quality = CRequestMetaQuality180(meta.quality or meta.itemQuality),
        displayName = CSafeText(meta.displayName or meta.item, 96),
        recipeName = CSafeText(meta.recipeName or meta.displayName or meta.item, 96),
        itemLink = meta.itemLink and tostring(meta.itemLink) or nil,
        sender = CSafeText(meta.sender, 48),
        channel = CSafeText(meta.channel, 12),
        ts = tonumber(meta.ts) or self:Now(),
        expires = tonumber(meta.expires) or (self:Now() + 90),
    }
    if normalized.requestId == "" or normalized.requestRev < 1 then return nil end
    if normalized.source == "RECIPE" and normalized.recipeKey == "" and normalized.itemId <= 0 then return nil end
    return normalized
end

function OTLGM:MergeCraftingRequestMeta180(record, meta)
    meta = self:NormalizeCraftingRequestMeta180(meta)
    if not record or not meta or tostring(record.id or "") ~= meta.requestId then return false, "identity" end
    local recordRev = tonumber(record.rev) or 0
    if recordRev ~= meta.requestRev then return false, recordRev > meta.requestRev and "stale" or "future" end
    if meta.sender ~= "" and not self:IsCraftingRequestMetaSenderAllowed180(record, meta.sender, meta.channel) then return false, "sender" end

    record.source = meta.source
    record.recipeKey = meta.recipeKey ~= "" and meta.recipeKey or nil
    record.itemId = meta.itemId > 0 and meta.itemId or nil
    record.professionKey = meta.professionKey ~= "" and meta.professionKey or nil
    record.itemQuality = meta.quality
    record.displayName = meta.displayName ~= "" and meta.displayName or record.item
    record.recipeName = meta.recipeName ~= "" and meta.recipeName or record.displayName
    if meta.itemLink and meta.itemLink ~= "" then record.itemLink = meta.itemLink end
    record.requestMeta180 = {
        requestRev = meta.requestRev,
        source = meta.source,
        recipeKey = record.recipeKey,
        itemId = record.itemId,
        professionKey = record.professionKey,
        quality = record.itemQuality,
        displayName = record.displayName,
        recipeName = record.recipeName,
        ts = meta.ts,
    }
    return true, "merged"
end

local function CStorePendingRequestMeta180(pending, meta)
    local bucket = pending[meta.requestId]
    if type(bucket) ~= "table" or type(bucket.entries) ~= "table" then
        local old = type(bucket) == "table" and bucket or nil
        bucket = { entries = {}, expires = 0, ts = 0 }
        if old and old.requestId then
            local oldKey = CNormalizeName(old.sender) .. ":" .. tostring(old.requestRev or 0)
            bucket.entries[oldKey] = old
            bucket.expires = tonumber(old.expires) or 0
        end
        pending[meta.requestId] = bucket
    end
    local key = CNormalizeName(meta.sender) .. ":" .. tostring(meta.requestRev or 0)
    local current = bucket.entries[key]
    if not current or (tonumber(current.ts) or 0) <= (tonumber(meta.ts) or 0) then bucket.entries[key] = meta end
    bucket.expires = math.max(tonumber(bucket.expires) or 0, tonumber(meta.expires) or 0)
    bucket.ts = math.max(tonumber(bucket.ts) or 0, tonumber(meta.ts) or 0)

    local rows = {}
    local entryKey, entry
    for entryKey, entry in pairs(bucket.entries) do table.insert(rows, { key = entryKey, ts = tonumber(entry.ts) or 0 }) end
    if table.getn(rows) > 8 then
        table.sort(rows, function(left, right) return left.ts < right.ts end)
        local index
        for index = 1, table.getn(rows) - 8 do bucket.entries[rows[index].key] = nil end
    end
    return bucket
end

function OTLGM:ApplyPendingCraftingRequestMeta180(requestId, record)
    local pending = self:GetPendingCraftingRequestMeta180()
    local bucket = pending[requestId]
    if not bucket then return false, "none" end
    local entries
    if type(bucket) == "table" and type(bucket.entries) == "table" then entries = bucket.entries
    elseif type(bucket) == "table" and bucket.requestId then entries = { legacy = bucket }
    else pending[requestId] = nil return false, "malformed" end

    local mergedAny, lastReason = false, "none"
    local key, meta
    for key, meta in pairs(entries) do
        if type(meta) ~= "table" or (tonumber(meta.expires) or 0) <= self:Now() then
            entries[key] = nil
            lastReason = "expired"
        else
            local merged, reason = self:MergeCraftingRequestMeta180(record, meta)
            lastReason = reason
            if merged then
                mergedAny = true
                local otherKey, other
                for otherKey, other in pairs(entries) do
                    if (tonumber(other.requestRev) or 0) <= (tonumber(record and record.rev) or 0) then entries[otherKey] = nil end
                end
                break
            elseif reason == "stale" or reason == "sender" or reason == "identity" then
                entries[key] = nil
            end
        end
    end
    local hasEntries = false
    for key in pairs(entries) do hasEntries = true break end
    if not hasEntries then pending[requestId] = nil end
    return mergedAny, lastReason
end

function OTLGM:SerializeCraftingRequestMeta180(record)
    if not record or not record.id then return nil end
    local meta = record.requestMeta180 or record
    local source = CRequestMetaSource180(meta.source or record.source)
    local recipeKey = CSafeText(meta.recipeKey or record.recipeKey, 80)
    local itemId = math.max(0, tonumber(meta.itemId or record.itemId) or 0)
    if source ~= "RECIPE" and recipeKey == "" and itemId <= 0 then return nil end
    local prefix = table.concat({
        self.craftingProtocol, "CMETA1", CEscape(record.id, 38), tostring(record.rev or 1), source,
        CEscape(recipeKey, 80), tostring(itemId), CEscape(meta.professionKey or record.professionKey or "", 28),
        tostring(CRequestMetaQuality180(meta.quality or meta.itemQuality or record.itemQuality) or -1),
    }, "^") .. "^"
    local displayName = meta.displayName or record.displayName or record.item or ""
    local recipeName = meta.recipeName or record.recipeName or displayName
    local available = math.max(0, 245 - string.len(prefix) - 1)
    local displayBudget = math.min(96, math.max(0, math.floor(available * 0.56)))
    local displayWire = CEscape(displayName, displayBudget)
    local recipeBudget = math.max(0, available - string.len(displayWire))
    return prefix .. displayWire .. "^" .. CEscape(recipeName, recipeBudget)
end

function OTLGM:QueueCraftingRequestRecord180(record, channel, target)
    if not record then return false end
    self:QueueCommunityPayload(self:SerializeCraftingRequest(record), channel or "GUILD", target)
    local metadata = self:SerializeCraftingRequestMeta180(record)
    if metadata then self:QueueCommunityPayload(metadata, channel or "GUILD", target) end
    return true
end

function OTLGM:ApplyRemoteCraftingRequestMeta180(fields, sender, channel)
    local craft = self:EnsureCraftingDB()
    if not craft then return false end
    local quality = tonumber(fields[9])
    if quality and quality < 0 then quality = nil end
    local meta = self:NormalizeCraftingRequestMeta180({
        requestId = CUnescape(fields[3]),
        requestRev = fields[4],
        source = CUnescape(fields[5]),
        recipeKey = CUnescape(fields[6]),
        itemId = fields[7],
        professionKey = CUnescape(fields[8]),
        quality = quality,
        displayName = CUnescape(fields[10]),
        recipeName = CUnescape(fields[11] or fields[10]),
        sender = sender,
        channel = channel,
        ts = self:Now(),
        expires = self:Now() + 90,
    })
    if not meta then return false end
    local request = craft.requests[meta.requestId]
    if request then
        local recordRev = tonumber(request.rev) or 0
        if recordRev > meta.requestRev then return true end
        if recordRev == meta.requestRev then
            local merged = self:MergeCraftingRequestMeta180(request, meta)
            if merged then
                self:EvaluateCraftingRequestMatch180(request, true, channel)
                self:OnCraftingDataChanged("REQUESTS", true)
            end
            return merged and true or false
        end
    end
    local pending = self:GetPendingCraftingRequestMeta180()
    -- Make room before insertion so a same-second metadata packet cannot be
    -- discarded merely because its request ID sorts before older buckets.
    if not pending[meta.requestId] then CPruneMapByTime(pending, 119) end
    CStorePendingRequestMeta180(pending, meta)
    CPruneMapByTime(pending, 120)
    return true
end

-- Stage C1 exact request identity. The request stores only stable identity fields;
-- reagents and other rich details are resolved from the local Crafting database.
function OTLGM:FindCraftingRecipeIdentity180(professionKey, recipeKey, itemId)
    local craft = self:EnsureCraftingDB()
    if not craft then return nil, nil end
    professionKey = string.upper(CSafeText(professionKey, 28))
    recipeKey = CSafeText(recipeKey, 80)
    itemId = math.max(0, tonumber(itemId) or 0)
    local fallbackRecipe, fallbackProfession
    local _, character, key, profession, candidateKey, recipe
    for _, character in pairs(craft.characters or {}) do
        for key, profession in pairs(character.professions or {}) do
            if professionKey == "" or key == professionKey then
                for candidateKey, recipe in pairs(profession.recipes or {}) do
                    if CShareableRecipeR27(recipe) then
                    local exactKey = recipeKey ~= "" and (tostring(candidateKey) == recipeKey or tostring(recipe.key or "") == recipeKey)
                    local exactItem = itemId > 0 and tonumber(recipe.itemId) == itemId
                    if exactKey or exactItem then
                        if character.localOwner then return recipe, profession end
                        if not fallbackRecipe then fallbackRecipe, fallbackProfession = recipe, profession end
                    end
                    end -- shareable recipe
                end
            end
        end
    end
    return fallbackRecipe, fallbackProfession
end

function OTLGM:BuildCraftingRequestIdentity180(result)
    if type(result) ~= "table" or type(result.recipe) ~= "table" then return nil end
    local recipe = result.recipe
    if not CShareableRecipeR27(recipe) then return nil end
    local itemId = math.max(0, tonumber(recipe.itemId) or 0)
    local displayName = CSafeText(recipe.name, 96)
    local itemLink, quality, icon = recipe.itemLink, CRequestMetaQuality180(recipe.quality), recipe.icon
    if itemId > 0 and self.GetItemInfoSafe then
        local cachedName, cachedLink, cachedQuality, _, _, _, _, _, _, cachedIcon = self:GetItemInfoSafe(itemId)
        if cachedName and cachedName ~= "" then displayName = CSafeText(cachedName, 96) end
        if cachedLink and cachedLink ~= "" then itemLink = cachedLink end
        if cachedQuality ~= nil then quality = CRequestMetaQuality180(cachedQuality) end
        if cachedIcon and cachedIcon ~= "" then icon = cachedIcon end
    end
    return {
        source = "RECIPE",
        recipeKey = CSafeText(recipe.key or result.recipeKey or result.key, 80),
        itemId = itemId,
        displayName = displayName,
        itemQuality = quality,
        professionKey = string.upper(CSafeText(result.professionKey, 28)),
        professionLabel = CSafeText(result.professionLabel or result.professionKey, 48),
        recipeName = CSafeText(recipe.name or displayName, 96),
        itemLink = itemLink,
        icon = icon,
        requiredSkill = math.max(0, tonumber(recipe.requiredSkill) or 0),
        reagents = CCopy(recipe.reagents or {}),
    }
end

function OTLGM:ApplyCraftingRequestIdentity180(record, identity)
    if not record then return false end
    identity = type(identity) == "table" and CCopy(identity) or {}
    identity.requestId = tostring(record.id or identity.requestId or "")
    identity.requestRev = tonumber(record.rev) or tonumber(identity.requestRev) or 1
    identity = self:NormalizeCraftingRequestMeta180(identity)
    if not identity or identity.source ~= "RECIPE" then
        record.source = "GENERIC"
        record.displayName = CSafeText(record.displayName or record.item, 96)
        return false
    end
    record.source = "RECIPE"
    record.recipeKey = identity.recipeKey ~= "" and identity.recipeKey or nil
    record.itemId = identity.itemId > 0 and identity.itemId or nil
    record.professionKey = identity.professionKey ~= "" and identity.professionKey or nil
    record.itemQuality = identity.quality
    record.displayName = identity.displayName ~= "" and identity.displayName or record.item
    record.recipeName = identity.recipeName ~= "" and identity.recipeName or record.displayName
    record.itemLink = identity.itemLink
    record.item = record.displayName or record.item
    record.requestMeta180 = {
        requestRev = tonumber(record.rev) or 1, source = "RECIPE", recipeKey = record.recipeKey,
        itemId = record.itemId, professionKey = record.professionKey, quality = record.itemQuality,
        displayName = record.displayName, recipeName = record.recipeName, ts = tonumber(record.ts) or self:Now(),
    }
    return true
end

function OTLGM:GetCraftingRequestPresentation180(record)
    if type(record) ~= "table" then return nil end
    local presentation = {
        source = CRequestMetaSource180(record.source),
        displayName = CSafeText(record.displayName or record.item or "Crafting request", 96),
        recipeName = CSafeText(record.recipeName or record.displayName or record.item, 96),
        itemId = math.max(0, tonumber(record.itemId) or 0),
        quality = CRequestMetaQuality180(record.itemQuality or record.quality),
        professionKey = string.upper(CSafeText(record.professionKey, 28)),
        professionLabel = string.upper(CSafeText(record.professionKey, 28)),
        recipeKey = CSafeText(record.recipeKey, 80),
        itemLink = record.itemLink,
        icon = record.icon,
        requiredSkill = 0,
        reagents = {},
    }
    if presentation.source == "RECIPE" then
        local recipe, profession = self:FindCraftingRecipeIdentity180(presentation.professionKey, presentation.recipeKey, presentation.itemId)
        if recipe then
            presentation.recipeName = CSafeText(recipe.name or presentation.recipeName, 96)
            presentation.displayName = presentation.displayName ~= "" and presentation.displayName or presentation.recipeName
            presentation.itemId = presentation.itemId > 0 and presentation.itemId or math.max(0, tonumber(recipe.itemId) or 0)
            presentation.quality = presentation.quality or CRequestMetaQuality180(recipe.quality)
            presentation.itemLink = presentation.itemLink or recipe.itemLink
            presentation.icon = presentation.icon or recipe.icon
            presentation.requiredSkill = math.max(0, tonumber(recipe.requiredSkill) or 0)
            presentation.reagents = CCopy(recipe.reagents or {})
            presentation.professionLabel = CSafeText(profession and profession.label or presentation.professionKey, 48)
            presentation.recipeKnown = true
        end
        if presentation.itemId > 0 and self.GetItemInfoSafe then
            local name, link, quality, _, _, _, _, _, _, texture = self:GetItemInfoSafe(presentation.itemId)
            if name and name ~= "" then presentation.displayName = CSafeText(name, 96) end
            if link and link ~= "" then presentation.itemLink = link record.itemLink = link end
            if quality ~= nil then presentation.quality = CRequestMetaQuality180(quality) record.itemQuality = presentation.quality end
            if texture and texture ~= "" then presentation.icon = texture record.icon = texture end
            if not name and self.QueueCraftingCacheLookup then self:QueueCraftingCacheLookup(presentation.itemId, record) end
        end
        if presentation.professionLabel == "" then presentation.professionLabel = presentation.professionKey end
    end
    if not presentation.icon or presentation.icon == "" then
        local definitions = self.GetCraftingProfessionDefinitions and self:GetCraftingProfessionDefinitions() or {}
        local index
        for index = 1, table.getn(definitions) do
            if definitions[index].key == presentation.professionKey then
                presentation.icon = definitions[index].icon
                presentation.professionLabel = definitions[index].label
                break
            end
        end
    end
    presentation.icon = presentation.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
    return presentation
end


-- Stage C2: exact local relevance, bounded anti-spam and deterministic request state.
local function CRequestIdentityRevision180(record)
    return tostring(record and record.id or "") .. ":" .. tostring(math.max(1, tonumber(record and record.rev) or 1))
end

local function CCharacterRecipeMatch180(character, professionKey, recipeKey, itemId)
    if type(character) ~= "table" or not character.localOwner then return nil end
    local profession = character.professions and character.professions[professionKey]
    if type(profession) ~= "table" then return nil end
    local candidateKey, recipe
    if recipeKey ~= "" then
        recipe = profession.recipes and profession.recipes[recipeKey]
        if recipe and CShareableRecipeR27(recipe) then return recipe end
    end
    for candidateKey, recipe in pairs(profession.recipes or {}) do
        if CShareableRecipeR27(recipe) and ((recipeKey ~= "" and (tostring(candidateKey) == recipeKey or tostring(recipe.key or "") == recipeKey))
            or (itemId > 0 and tonumber(recipe.itemId) == itemId)) then return recipe end
    end
    return nil
end

function OTLGM:GetCraftingRequestMatch180(record)
    if type(record) ~= "table" or CRequestMetaSource180(record.source) ~= "RECIPE" then return nil end
    local professionKey = string.upper(CSafeText(record.professionKey, 28))
    local recipeKey = CSafeText(record.recipeKey, 80)
    local itemId = math.max(0, tonumber(record.itemId) or 0)
    if professionKey == "" or (recipeKey == "" and itemId <= 0) then return nil end
    local craft = self:EnsureCraftingDB()
    if not craft then return nil end
    local current = CNormalizeName(UnitName("player") or "")
    local matches = {}
    local key, character, recipe
    for key, character in pairs(craft.characters or {}) do
        recipe = CCharacterRecipeMatch180(character, professionKey, recipeKey, itemId)
        if recipe then
            local characterName = string.gsub(tostring(character.name or key or ""), "%-.*$", "")
            table.insert(matches, {
                character = characterName,
                current = CNormalizeName(characterName) == current,
                recipe = recipe,
                profession = character.professions and character.professions[professionKey],
            })
        end
    end
    table.sort(matches, function(left, right)
        if left.current ~= right.current then return left.current and true or false end
        return CNormalizeName(left.character) < CNormalizeName(right.character)
    end)
    return matches[1]
end

function OTLGM:IsCraftingColdSync180(channel)
    if channel ~= "WHISPER" then return false end
    local craft = self:EnsureCraftingDB()
    return craft and craft.syncState and craft.syncState.active
        and self:Now() - (tonumber(craft.syncState.started) or 0) <= 125
end

function OTLGM:EvaluateCraftingRequestMatch180(record, remote, channel)
    local craft = self:EnsureCraftingDB()
    if not craft or type(record) ~= "table" or not remote then return nil, "local" end
    if CNormalizeRequestStatus(record.status) ~= "OPEN" then return nil, "inactive" end
    if CNormalizeName(record.author) == CNormalizeName(UnitName("player") or "") then return nil, "own" end
    local match = self:GetCraftingRequestMatch180(record)
    if not match then return nil, "not-relevant" end
    if OTLGM_DB.settings.c7CraftableRequests180 == false then return match, "disabled" end
    local dedupeKey = CRequestIdentityRevision180(record)
    if craft.requestMatchSeen180[dedupeKey] then return match, "seen" end
    craft.requestMatchSeen180[dedupeKey] = {
        ts = self:Now(), requestId = record.id, rev = tonumber(record.rev) or 1,
        character = match.character, silent = self:IsCraftingColdSync180(channel) and true or false,
    }
    CPruneMapByTime(craft.requestMatchSeen180, 400)
    if self:IsCraftingColdSync180(channel) then return match, "cold-sync" end
    local presentation = self:GetCraftingRequestPresentation180(record) or {}
    local itemName = presentation.displayName or record.item or "this item"
    local title
    if match.current then title = "You can craft " .. itemName .. " for " .. tostring(record.author or "a guild member")
    else title = "Your character " .. tostring(match.character) .. " can craft " .. itemName .. " for " .. tostring(record.author or "a guild member") end
    if self.NotifyEvent152 then
        self:NotifyEvent152("crafting", "CRAFT_MATCH:" .. dedupeKey, title,
            "Open the exact request to review or claim it.", "ACTION", true, "professions", {
                objectType = "CRAFT_REQUEST", objectId = record.id, section = "REQUESTS", actionKey = "CLAIM",
            })
    end
    return match, "notified"
end

function OTLGM:RemoveCraftingRequestActions180(requestId)
    if self.RemoveInboxObject180 then self:RemoveInboxObject180("CRAFT_REQUEST", requestId) end
    local craft = self:EnsureCraftingDB()
    if not craft then return end
    local key, value
    for key, value in pairs(craft.requestMatchSeen180 or {}) do
        if type(value) == "table" and tostring(value.requestId or "") == tostring(requestId or "") then craft.requestMatchSeen180[key] = nil end
    end
end

local function CStateActor180(response, sender)
    return string.gsub(tostring(response and response.author or sender or ""), "%-.*$", "")
end

local function CLeadershipActor180(self, actor)
    return self.IsLeadershipSender and self:IsLeadershipSender(actor) or false
end

local function CClaimComesBefore180(left, right)
    local leftRev, rightRev = tonumber(left.stateRev) or 0, tonumber(right.stateRev) or 0
    if leftRev ~= rightRev then return leftRev > rightRev end
    local leftTs, rightTs = tonumber(left.ts) or 0, tonumber(right.ts) or 0
    if leftTs ~= rightTs then return leftTs < rightTs end
    local leftActor, rightActor = CNormalizeName(left.author), CNormalizeName(right.author)
    if leftActor ~= rightActor then return leftActor < rightActor end
    return tostring(left.id or "") < tostring(right.id or "")
end

local function CCompletionComesBefore180(left, right)
    local leftRev, rightRev = tonumber(left.stateRev) or 0, tonumber(right.stateRev) or 0
    if leftRev ~= rightRev then return leftRev > rightRev end
    local leftTs, rightTs = tonumber(left.ts) or 0, tonumber(right.ts) or 0
    if leftTs ~= rightTs then return leftTs > rightTs end
    local leftActor, rightActor = CNormalizeName(left.author), CNormalizeName(right.author)
    if leftActor ~= rightActor then return leftActor < rightActor end
    return tostring(left.id or "") < tostring(right.id or "")
end

function OTLGM:NotifyCraftingRequestState180(request, oldStatus, remote)
    if not remote or type(request) ~= "table" then return false end
    local status = CNormalizeRequestStatus(request.status)
    if status == CNormalizeRequestStatus(oldStatus) then return false end
    local player = CNormalizeName(UnitName("player") or "")
    local relevant = CNormalizeName(request.author) == player
        or (status == "COMPLETED" and CNormalizeName(request.claimedBy) == player)
    if not relevant then return false end
    local presentation = self:GetCraftingRequestPresentation180(request) or {}
    local itemName = presentation.displayName or request.item or "Crafting request"
    local actor = status == "CLAIMED" and request.claimedBy or request.completedBy
    local title = status == "CLAIMED" and (itemName .. " was claimed") or (itemName .. " was completed")
    local body = tostring(actor or "A guild member") .. (status == "CLAIMED" and " claimed your request." or " completed the request.")
    return self.NotifyEvent152 and self:NotifyEvent152("response",
        "CRAFT_STATE:" .. tostring(request.id) .. ":" .. status .. ":" .. tostring(request.stateRev or 0),
        title, body, status == "CLAIMED" and "ACTION" or "NORMAL", true, "professions", {
            objectType = "CRAFT_REQUEST", objectId = request.id, section = "REQUESTS", actionKey = status,
        }) or false
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

function OTLGM.__impl180.PurgeCraftingData__impl1(self, silent)
    local craft = self:EnsureCraftingDB()
    if not craft then return false end
    local now = self:Now()
    local changed = false
    local recipeChangedR46 = false
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
    local requestMeta = self:GetPendingCraftingRequestMeta180()
    for pendingKey, pending in pairs(requestMeta or {}) do
        if type(pending) ~= "table" or (tonumber(pending.expires) or 0) <= now then
            requestMeta[pendingKey] = nil
        elseif type(pending.entries) == "table" then
            local entryKey, entry
            for entryKey, entry in pairs(pending.entries) do
                if type(entry) ~= "table" or (tonumber(entry.expires) or 0) <= now then pending.entries[entryKey] = nil end
            end
            local hasEntry = false
            for entryKey in pairs(pending.entries) do hasEntry = true break end
            if not hasEntry then requestMeta[pendingKey] = nil end
        end
    end
    CPruneMapByTime(requestMeta, 120)
    CPruneMapByTime(craft.requestMatchSeen180, 400)
    CPruneMapByTime(craft.pendingRecipes, 100)
    local name, character
    local guildDB = self:GetGuildDB()
    local roster = guildDB and guildDB.roster or {}
    -- Only treat absence from roster as proof that somebody left after a real,
    -- successfully committed guild scan. During login/partial API states keep
    -- the old 60-day fallback so a temporarily empty roster cannot wipe data.
    local rosterAuthoritative = guildDB and guildDB.initialized
        and (tonumber(guildDB.lastScan) or 0) > 0
        and (tonumber(guildDB.lastTotal) or 0) > 0
    for name, character in pairs(craft.characters) do
        local currentMember = rosterAuthoritative and self.GetMember and self:GetMember(name) or nil
        if (rosterAuthoritative and not currentMember)
            or (not rosterAuthoritative and not character.localOwner and not roster[name]
                and (character.updated or 0) + (60 * 86400) < now) then
            if rosterAuthoritative and not currentMember then
                self.runtime = self.runtime or {}
                self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
                self.runtime.craftingMetrics180.departedCrafterPurges184 = (tonumber(self.runtime.craftingMetrics180.departedCrafterPurges184) or 0) + 1
            end
            craft.characters[name] = nil
            changed = true
            recipeChangedR46 = true
        end
    end
    if CPruneMapByTime(craft.characters, 800) then changed = true recipeChangedR46 = true end
    if changed then
        local changedSectionR46 = recipeChangedR46 and "maintenance-purge-recipes" or "REQUESTS"
        if silent then
            if self.InvalidateCraftingDerivedCachesR46 then
                self:InvalidateCraftingDerivedCachesR46(changedSectionR46, true)
            else
                self.runtime = self.runtime or {}
                self.runtime.craftingDataRevisionRC3 = (tonumber(self.runtime.craftingDataRevisionRC3) or 0) + 1
            end
        else
            self:OnCraftingDataChanged(recipeChangedR46 and "RECIPES" or "REQUESTS", false)
        end
    end
    return changed
end

function OTLGM:QueueCraftingCacheLookup(itemId, object)
    local craft = self:EnsureCraftingDB()
    itemId = tonumber(itemId) or 0
    if not craft or itemId <= 0 or not object then return false end
    self.runtime = self.runtime or {}
    self.runtime.craftingCacheQueue = self.runtime.craftingCacheQueue or {}
    local queue = self.runtime.craftingCacheQueue
    local queueWasEmpty = next(queue) == nil
    local key = tostring(itemId) .. ":" .. tostring(object)
    if queue[key] then return true end
    local count = 0
    for _ in pairs(queue) do count = count + 1 end
    if count >= 160 then return false end
    queue[key] = { itemId = itemId, object = object, tries = 0, nextAt = self:Now() }
    if queueWasEmpty and self.WakeScheduler180 then self:WakeScheduler180("crafting-cache-lookup") end
    return true
end

function OTLGM.__impl180.ProcessCraftingCacheQueue__impl1(self, maximumR26)
    local craft = self:EnsureCraftingDB()
    if not craft or not GetItemInfo then return false end
    self.runtime = self.runtime or {}
    local queue = self.runtime.craftingCacheQueue or {}
    self.runtime.craftingCacheQueue = queue
    local now = self:Now()
    local processed, changed = 0, false
    maximumR26 = math.max(1, math.min(8, tonumber(maximumR26) or 8))
    local key, entry
    for key, entry in pairs(queue) do
        if processed >= maximumR26 then break end
        if entry and now >= (entry.nextAt or 0) then
            processed = processed + 1
            local name, link, quality, itemLevel, requiredLevel, itemType, itemSubType, _, equipLoc, texture = self:GetItemInfoSafe(entry.itemId)
            if name or texture or link then
                local object = entry.object
                if object then
                    if link and link ~= "" then object.itemLink = link end
                    if texture and texture ~= "" then object.icon = texture end
                    if name and name ~= "" and (object.source == "RECIPE" or object.displayName == nil or object.displayName == "") then
                        object.displayName = CSafeText(name, 96)
                        if object.item == nil or object.item == "" then object.item = object.displayName end
                    end
                    if quality ~= nil then
                        object.quality = tonumber(quality) or object.quality
                        if object.source == "RECIPE" then object.itemQuality = tonumber(quality) or object.itemQuality end
                    end
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

local function CDerivedEnchantEffect183(recipeName, effectText)
    local name = CSafeText(recipeName or "", 100)
    local _, _, target, effect = string.find(name, "^Enchant%s+(.+)%s+%-%s+(.+)$")
    if not target or not effect then return false end
    local derived = "Applies " .. CSafeText(effect, 70) .. " to " .. string.lower(CSafeText(target, 32)) .. "."
    return CNormalizeText(derived) == CNormalizeText(effectText or "")
end

function OTLGM:IsDerivedEnchantEffect183(recipe, effectText)
    local recipeName = type(recipe) == "table" and recipe.name or recipe
    return CDerivedEnchantEffect183(recipeName, effectText)
end

-- R24 keeps the wire protocol unchanged while normalizing provenance names.
-- NATIVE_TOOLTIP/REMOTE_LEGACY are accepted only as backward-compatible input.
local function CNormalizeEnchantSourceR24(source)
    source = tostring(source or "")
    if source == "LOCAL_NATIVE" or source == "NATIVE_TOOLTIP" then return "LOCAL_NATIVE" end
    if source == "REMOTE_NATIVE" then return "REMOTE_NATIVE" end
    if source == "LEGACY_NATIVE" or source == "REMOTE_LEGACY" then return "LEGACY_NATIVE" end
    return "UNKNOWN"
end

local function CTrustedEnchantSourceR24(source)
    source = CNormalizeEnchantSourceR24(source)
    return source == "LOCAL_NATIVE" or source == "REMOTE_NATIVE" or source == "LEGACY_NATIVE"
end

local function CRemoteEnchantSourceR24(source, hasEffect)
    if not hasEffect then return "UNKNOWN" end
    source = tostring(source or "")
    if source == "LOCAL_NATIVE" or source == "NATIVE_TOOLTIP" or source == "REMOTE_NATIVE" then return "REMOTE_NATIVE" end
    if source == "" or source == "LEGACY_NATIVE" or source == "REMOTE_LEGACY" then return "LEGACY_NATIVE" end
    return "UNKNOWN"
end

local function CReadTradeSkillLine184()
    local rawName, value2, value3, value4, value5 = GetTradeSkillLine()
    local number2, number3, number4 = tonumber(value2), tonumber(value3), tonumber(value4)
    local rank, maxRank = 0, 0
    -- Stock 1.12 uses name/current/max. Some Octo-derived trade-skill frames add
    -- a textual rank between the name and the numeric pair. Prefer the numeric
    -- 3rd/4th pair when it exists; otherwise use the stock 2nd/3rd pair.
    if number3 and number4 and number4 >= number3 then
        rank, maxRank = number3, number4
    elseif number2 and number3 and number3 >= number2 then
        rank, maxRank = number2, number3
    elseif number3 then
        rank, maxRank = number3, number4 or 0
    elseif number2 then
        rank, maxRank = number2, number3 or 0
    end
    return rawName, rank, maxRank, value2, value3, value4, value5
end

function OTLGM:ReadTradeSkillLine184()
    return CReadTradeSkillLine184()
end

function OTLGM:GetOpenTradeSkillProfession184()
    if not GetTradeSkillLine then return nil end
    local rawName = self:ReadTradeSkillLine184()
    local professionKey = CProfessionKey(rawName)
    if not professionKey then return nil end
    local craft = self:EnsureCraftingDB()
    local player = string.gsub(UnitName("player") or "", "%-.*$", "")
    local character = craft and craft.characters and craft.characters[player]
    local profession = character and character.professions and character.professions[professionKey]
    return professionKey, profession
end

-- R43: Vanilla-era Enchanting can use CraftFrame rather than TradeSkillFrame.
-- Keep a separate resolver so exact-effect capture can follow whichever native
-- profession API Octo exposes without guessing account or recipe state.
function OTLGM:GetOpenCraftProfessionR43()
    if not GetCraftName then return nil end
    local rawName = GetCraftName()
    local professionKey = CProfessionKey(rawName)
    if not professionKey and GetCraftDisplaySkillLine then
        local ok, displayName = pcall(GetCraftDisplaySkillLine)
        if ok then professionKey = CProfessionKey(displayName) end
    end
    if not professionKey then return nil end
    local craft = self:EnsureCraftingDB()
    local player = string.gsub(UnitName("player") or "", "%-.*$", "")
    local character = craft and craft.characters and craft.characters[player]
    local profession = character and character.professions and character.professions[professionKey]
    return professionKey, profession
end

function OTLGM:ScheduleProfessionRescan(mode, attempt, delay)
    -- Domain timers compare against the persisted whole-second clock. Round the
    -- debounce up so the fractional scheduler cannot spin while the domain clock
    -- is still on the preceding second.
    local wait = math.max(1, math.ceil(tonumber(delay) or 1))
    self.craftingRescan = { mode = mode, attempt = tonumber(attempt) or 1, due = self:Now() + wait }
    if self.WakeScheduler180 then self:WakeScheduler180("profession-rescan") end
end

function OTLGM.__impl180.Stage_Crafting_ScanCurrentProfession_1__impl1(self, mode, attempt)
    if not OTLGM_DB or not OTLGM_DB.settings or OTLGM_DB.settings.craftingShareEnabled == false then return false end
    attempt = tonumber(attempt) or 0
    local rawName, rank, maxRank
    local isCraft = mode == "CRAFT"
    if isCraft then
        if not GetCraftName or not GetNumCrafts or not GetCraftInfo then return false end
        rawName = GetCraftName()
        rank, maxRank = 0, 0
        if GetCraftDisplaySkillLine then
            -- Vanilla/Octo returns name, rank, maxRank. pcall adds the boolean
            -- in front, so the old r58 assignment accidentally treated the
            -- profession name ("Enchanting") as the numeric rank and produced
            -- 0/300 in shared/profile data.
            local ok, displayName, skillRank, skillMax = pcall(GetCraftDisplaySkillLine)
            if ok then
                if (not rawName or rawName == "") and displayName then rawName = displayName end
                rank, maxRank = tonumber(skillRank) or 0, tonumber(skillMax) or 0
            end
        end
    else
        if not GetTradeSkillLine or not GetNumTradeSkills or not GetTradeSkillInfo then return false end
        local raw2, raw3, raw4, raw5
        rawName, rank, maxRank, raw2, raw3, raw4, raw5 = self:ReadTradeSkillLine184()
        self.runtime = self.runtime or {}
        self.runtime.lastTradeSkillLineRaw184 = {
            ts = self:Now(), name = tostring(rawName or ""), value2 = tostring(raw2 or ""),
            value3 = tostring(raw3 or ""), value4 = tostring(raw4 or ""), value5 = tostring(raw5 or ""),
            rank = tonumber(rank) or 0, maxRank = tonumber(maxRank) or 0,
        }
    end
    local professionKey, professionLabel = CProfessionKey(rawName)
    if not professionKey then
        -- Some 1.12-derived clients fire SHOW before the trade-skill title is
        -- populated. Retry only that transient empty-title state; an actual
        -- unsupported profession (for example First Aid) remains ignored.
        if (not rawName or rawName == "") and attempt < 2 then
            self:ScheduleProfessionRescan(mode, attempt + 1, 1)
        end
        return false
    end

    local craftEarlyR31 = self:EnsureCraftingDB()
    local playerEarlyR31 = string.gsub(UnitName("player") or "Unknown", "%-.*$", "")
    local oldEarlyR31 = craftEarlyR31 and craftEarlyR31.characters and craftEarlyR31.characters[playerEarlyR31]
        and craftEarlyR31.characters[playerEarlyR31].professions and craftEarlyR31.characters[playerEarlyR31].professions[professionKey] or nil
    local oldRecipesR31 = oldEarlyR31 and oldEarlyR31.recipes or nil
    -- r59 CP3: some Vanilla-derived CraftFrame implementations briefly expose
    -- the profession/max-skill before the current rank is populated. Never
    -- overwrite a previously valid Enchanting rank with that transient 0/max
    -- state. On first capture retry twice; with an existing snapshot preserve
    -- its known rank while still allowing recipe/effect refresh to continue.
    if isCraft and (tonumber(maxRank) or 0) > 0 and (tonumber(rank) or 0) <= 0 then
        self.runtime = self.runtime or {}
        self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
        self.runtime.craftingMetrics180.transientCraftRankR59 = (tonumber(self.runtime.craftingMetrics180.transientCraftRankR59) or 0) + 1
        local previousRankR59 = oldEarlyR31 and tonumber(oldEarlyR31.rank) or 0
        local previousMaxR59 = oldEarlyR31 and tonumber(oldEarlyR31.maxRank) or 0
        if previousRankR59 > 0 then
            rank = previousRankR59
            if previousMaxR59 > 0 then maxRank = previousMaxR59 end
            if attempt < 2 then self:ScheduleProfessionRescan(mode, attempt + 1, 1) end
        elseif attempt < 2 then
            self:ScheduleProfessionRescan(mode, attempt + 1, 1)
            return false
        end
    end
    local scanSignatureR31 = 23
    local function MixScanR31(value)
        local text = tostring(value or "")
        local mixIndexR31
        for mixIndexR31 = 1, string.len(text) do
            scanSignatureR31 = math.mod((scanSignatureR31 * 31) + string.byte(text, mixIndexR31), 2147483000)
        end
        scanSignatureR31 = math.mod((scanSignatureR31 * 31) + 124, 2147483000)
    end

    local recipes = {}
    local count = isCraft and (GetNumCrafts() or 0) or (GetNumTradeSkills() or 0)
    if count <= 0 then
        -- Never replace a valid profession snapshot with an empty list caused
        -- by a window that has not finished populating yet. Enchanting is the
        -- most common offender on custom 1.12 clients because SHOW can precede
        -- its first TRADE_SKILL_UPDATE.
        self.runtime = self.runtime or {}
        self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or { scans = 0, noChangeSkips = 0, commits = 0 }
        self.runtime.craftingMetrics180.emptyWindowRetries184 = (tonumber(self.runtime.craftingMetrics180.emptyWindowRetries184) or 0) + 1
        if attempt < 2 then self:ScheduleProfessionRescan(mode, attempt + 1, attempt == 0 and 1 or 2) end
        return false
    end
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
            local preliminaryKeyR31 = itemId > 0 and tostring(itemId) or CNormalizeText(recipeName)
            local previousRecipeR31 = oldRecipesR31 and oldRecipesR31[preliminaryKeyR31] or nil
            local quality, itemLevel, requiredLevel, itemType, itemSubType, equipLoc = 1, 0, 0, "", "", ""
            if previousRecipeR31 then
                self.runtime = self.runtime or {}
                self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
                self.runtime.craftingMetrics180.scanRecipeMetadataReuseR31 = (tonumber(self.runtime.craftingMetrics180.scanRecipeMetadataReuseR31) or 0) + 1
                quality = tonumber(previousRecipeR31.quality) or 1
                itemLevel = tonumber(previousRecipeR31.itemLevel) or 0
                requiredLevel = tonumber(previousRecipeR31.requiredLevel) or 0
                itemType = previousRecipeR31.itemType or ""
                itemSubType = previousRecipeR31.itemSubType or ""
                equipLoc = previousRecipeR31.equipLoc or ""
                if (not itemLink or itemLink == "") and previousRecipeR31.itemLink then itemLink = previousRecipeR31.itemLink end
                if (not recipeLink or recipeLink == "") and previousRecipeR31.recipeLink then recipeLink = previousRecipeR31.recipeLink end
                if not icon and previousRecipeR31.icon then icon = previousRecipeR31.icon end
            elseif itemId > 0 and GetItemInfo then
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
            MixScanR31(preliminaryKeyR31)
            MixScanR31(recipeName)
            MixScanR31(recipeType or "")

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
                    local previousReagentR31 = previousRecipeR31 and previousRecipeR31.reagents and previousRecipeR31.reagents[reagentIndex] or nil
                    local previousMatchesR31 = previousReagentR31 and ((reagentId > 0 and tonumber(previousReagentR31.itemId) == reagentId)
                        or CNormalizeText(previousReagentR31.name or "") == CNormalizeText(reagentName or ""))
                    if previousMatchesR31 then
                        self.runtime = self.runtime or {}
                        self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
                        self.runtime.craftingMetrics180.scanReagentMetadataReuseR31 = (tonumber(self.runtime.craftingMetrics180.scanReagentMetadataReuseR31) or 0) + 1
                        reagentQuality = tonumber(previousReagentR31.quality) or 1
                        if (not reagentLink or reagentLink == "") and previousReagentR31.itemLink then reagentLink = previousReagentR31.itemLink end
                        if not reagentTexture and previousReagentR31.icon then reagentTexture = previousReagentR31.icon end
                    elseif reagentId > 0 and GetItemInfo then
                        local _, cachedLink, cachedQuality, _, _, _, _, _, _, cachedTexture = self:GetItemInfoSafe(reagentId)
                        if (not reagentLink or reagentLink == "") and cachedLink then reagentLink = cachedLink end
                        reagentQuality = tonumber(cachedQuality) or 1
                        if not reagentTexture and cachedTexture then reagentTexture = cachedTexture end
                    end
                    MixScanR31(reagentId)
                    MixScanR31(reagentName or "")
                    MixScanR31(tonumber(required) or 0)
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

            local recipeKey = preliminaryKeyR31
            MixScanR31(reagentCount)
            if recipeKey ~= "" then
                recipes[recipeKey] = {
                    key = recipeKey, name = CSafeText(recipeName, 80), itemId = itemId,
                    quality = quality, itemLevel = itemLevel, requiredLevel = requiredLevel,
                    requiredSkill = 0, difficulty = recipeType or "unknown",
                    itemType = itemType, itemSubType = itemSubType, equipLoc = equipLoc,
                    itemLink = itemLink, recipeLink = recipeLink, icon = icon,
                    effectText = nil,
                    reagents = reagents, materialsAvailable = materialsStatus == "COMPLETE", materialsStatus = materialsStatus,
                }
            end
        end
    end

    local craft = craftEarlyR31 or self:EnsureCraftingDB()
    if not craft then return false end
    local player = playerEarlyR31
    local character = craft.characters[player]
    local old = oldEarlyR31 or (character and character.professions and character.professions[professionKey] or nil)
    -- A profession rescan rebuilds the structural recipe list from the live API.
    -- Preserve previously captured native detail metadata before hashing so an
    -- unchanged profession does not oscillate between "effect present" and nil.
    if old and type(old.recipes) == "table" then
        local recipeKey, recipe, previousRecipe
        for recipeKey, recipe in pairs(recipes) do
            previousRecipe = old.recipes[recipeKey]
            if previousRecipe then
                local previousEffect = tostring(previousRecipe.effectText or "")
                if previousEffect ~= "" and not CDerivedEnchantEffect183(recipe.name, previousEffect) then
                    local previousSource = CNormalizeEnchantSourceR24(previousRecipe.effectSource183)
                    if previousSource == "UNKNOWN" and tostring(previousRecipe.effectSource183 or "") == "" then previousSource = "LEGACY_NATIVE" end
                    if CTrustedEnchantSourceR24(previousSource) then
                        recipe.effectText = previousEffect
                        recipe.effectSource183 = previousSource
                        recipe.effectChecked = previousRecipe.effectChecked
                    end
                end
                recipe.detailKey = previousRecipe.detailKey
                recipe.detailHash = previousRecipe.detailHash
                recipe.requirementChecked = previousRecipe.requirementChecked
                recipe.requirementText = previousRecipe.requirementText
                if previousRecipe.personalOnlyR27 then
                    recipe.personalOnlyR27 = true
                    recipe.personalReasonR27 = previousRecipe.personalReasonR27 or "BOP_OUTPUT"
                end
                if (tonumber(previousRecipe.requiredSkill) or 0) > 0 then recipe.requiredSkill = previousRecipe.requiredSkill end
            end
        end
    end
    MixScanR31(count)
    MixScanR31(rank or 0)
    MixScanR31(maxRank or 0)
    local scanSignatureTextR31 = tostring(scanSignatureR31)
    local hash
    if old and tostring(old.scanSignatureR31 or "") == scanSignatureTextR31 and old.hash then
        -- The structural live API view is unchanged. Reuse the canonical wire
        -- hash instead of sorting/re-hashing every recipe/reagent string.
        hash = tostring(old.hash)
        self.runtime = self.runtime or {}
        self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
        self.runtime.craftingMetrics180.scanHashReuseR31 = (tonumber(self.runtime.craftingMetrics180.scanHashReuseR31) or 0) + 1
    else
        hash = CHashRecipes(recipes)
    end
    local recipeCount = CShareableRecipeCountR27(recipes)
    local oldCount = old and CShareableRecipeCountR27(old.recipes) or 0
    local changed = not old or old.hash ~= hash or oldCount ~= recipeCount
        or (tonumber(old.rank) or 0) ~= (tonumber(rank) or 0)
        or (tonumber(old.maxRank) or 0) ~= (tonumber(maxRank) or 0)
        or (tonumber(old.incompleteMaterials) or 0) ~= (tonumber(missingMaterialRows) or 0)

    self.runtime = self.runtime or {}
    self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or { scans = 0, noChangeSkips = 0, commits = 0 }
    local scanMetrics = self.runtime.craftingMetrics180
    scanMetrics.scans = (tonumber(scanMetrics.scans) or 0) + 1
    scanMetrics.lastScanAt = self:Now()
    scanMetrics.lastProfession = professionKey

    -- An unchanged scan is a read-only operation. Do not replace the SavedVariables
    -- snapshot, bump timestamps, dirty the page or trigger a new manifest.
    if changed then
        character = character or { name = player, professions = {} }
        character.name = player
        character.class = CPlayerClassToken()
        character.level = UnitLevel("player") or 0
        character.updated = self:Now()
        character.localOwner = true
        character.professions = character.professions or {}
        character.professions[professionKey] = {
            key = professionKey, label = professionLabel, rank = tonumber(rank) or 0, maxRank = tonumber(maxRank) or 0,
            ts = self:Now(), hash = hash, recipes = recipes, localOwner = true, incompleteMaterials = missingMaterialRows,
            scanSignatureR31 = scanSignatureTextR31,
        }
        craft.characters[player] = character
        scanMetrics.commits = (tonumber(scanMetrics.commits) or 0) + 1
    else
        scanMetrics.noChangeSkips = (tonumber(scanMetrics.noChangeSkips) or 0) + 1
        if old and tostring(old.scanSignatureR31 or "") == "" then old.scanSignatureR31 = scanSignatureTextR31 end
    end

    -- Profession windows often populate reagent links one frame later. Retry only
    -- while the window is open, at most twice, and do not broadcast an incomplete
    -- snapshot before the final attempt.
    if missingMaterialRows > 0 and attempt < 2 then
        self:ScheduleProfessionRescan(mode, attempt + 1, attempt == 0 and 1 or 2)
    end

    local statusVisible = self.ui and self.ui.main and self.ui.main:IsVisible() and self.ui.currentPage == "professions"
    if changed then
        local difference = recipeCount - oldCount
        local eventTitle
        if difference > 0 then eventTitle = player .. " added " .. tostring(difference) .. " " .. professionLabel .. " recipe" .. (difference == 1 and "" or "s")
        else eventTitle = player .. " updated " .. professionLabel end
        self:AddCraftingEvent("RECIPES", eventTitle, tostring(recipeCount) .. " recipes shared", "professions")
        if missingMaterialRows == 0 or attempt >= 2 then self:QueueCraftingProfessionShare(player, professionKey) end
        if statusVisible and self.SetStatus then
            local suffix = missingMaterialRows > 0 and ("; " .. tostring(missingMaterialRows) .. " recipe(s) still waiting for reagent details") or ""
            self:SetStatus(professionLabel .. " updated: " .. tostring(recipeCount) .. " recipes" .. suffix .. ".", nil, { source = "crafting", manual = self.ui and self.ui.main and self.ui.main:IsVisible() and self.ui.currentPage == "professions" })
        end
        self:OnCraftingDataChanged("RECIPES", false)
    elseif statusVisible and self.SetStatus and attempt == 0 then
        self:SetStatus(professionLabel .. " is already up to date: " .. tostring(recipeCount) .. " recipes.", nil, { source = "crafting", manual = self.ui and self.ui.main and self.ui.main:IsVisible() and self.ui.currentPage == "professions" })
    end
    return true, changed, recipeCount, missingMaterialRows
end

local function CraftingWireEffect180(recipe)
    recipe = recipe or {}
    local wireEffect = tostring(recipe.effectText or "")
    local rawWireSource = tostring(recipe.effectSource183 or "")
    local wireSource = CNormalizeEnchantSourceR24(rawWireSource)
    if CDerivedEnchantEffect183(recipe.name, wireEffect) or rawWireSource == "DERIVED_FALLBACK" then
        wireEffect, wireSource = "", "UNKNOWN"
    elseif wireEffect == "" then
        wireSource = "UNKNOWN"
    elseif wireSource == "UNKNOWN" and rawWireSource == "" then
        -- Old local SavedVariables may contain a legitimate captured effect but no
        -- provenance field. Keep it explicitly legacy rather than claiming local-native.
        wireSource = "LEGACY_NATIVE"
    elseif not CTrustedEnchantSourceR24(wireSource) then
        -- Never broadcast an unverified/synthetic effect as native.
        wireEffect, wireSource = "", "UNKNOWN"
    end
    return wireEffect, wireSource
end

local function CEscapedWireLengthR42(text, maxWireLength)
    -- Measure the exact number of bytes CEscape would emit without constructing
    -- the percent-escaped output. This keeps PREPARE allocation-light even for
    -- large profession snapshots. All escaped characters below are three bytes.
    text = CSafeText(text)
    local wireLength = 0
    local i, character, encodedLength
    for i = 1, string.len(text) do
        character = string.sub(text, i, i)
        if character == "%" or character == "^" or character == "~" or character == ","
            or character == ":" or character == "+" or character == "|" then encodedLength = 3
        else encodedLength = 1 end
        if maxWireLength and wireLength + encodedLength > maxWireLength then break end
        wireLength = wireLength + encodedLength
    end
    return wireLength
end

local function MeasureCraftingRecipeWireLengthR42(recipe)
    recipe = recipe or {}
    local wireEffect, wireSource = CraftingWireEffect180(recipe)
    local reagentWireLength, reagentCount = 0, math.min(12, table.getn(recipe.reagents or {}))
    local reagentIndex, reagent
    for reagentIndex = 1, reagentCount do
        reagent = recipe.reagents[reagentIndex] or {}
        local partLength = string.len(tostring(reagent.itemId or 0))
            + 1 + CEscapedWireLengthR42(CSafeText(reagent.name, 48), 84)
            + 1 + string.len(tostring(reagent.count or 0))
            + 1 + CEscapedWireLengthR42(CSafeText(reagent.icon or "", 90), 120)
            + 1 + string.len(tostring(reagent.quality or 1))
        reagentWireLength = reagentWireLength + partLength
        if reagentIndex > 1 then reagentWireLength = reagentWireLength + 1 end -- + separator
    end

    -- EncodeCraftingRecipe180 emits 16 comma-separated fields. Add 15 separators
    -- and measure each escaped field with the same per-field wire cap.
    local total = 15
        + string.len(tostring(recipe.itemId or 0))
        + CEscapedWireLengthR42(CSafeText(recipe.name, 80), 120)
        + string.len(tostring(recipe.quality or 1))
        + string.len(tostring(recipe.itemLevel or 0))
        + string.len(tostring(recipe.requiredLevel or 0))
        + CEscapedWireLengthR42(CSafeText(recipe.equipLoc or "", 24), 40)
        + CEscapedWireLengthR42(CSafeText(recipe.icon or "", 90), 120)
        + CEscapedWireLengthR42(CSafeText(recipe.materialsStatus or "UNAVAILABLE", 12), 18)
        + string.len(tostring(reagentCount))
        + reagentWireLength
        + CEscapedWireLengthR42(CSafeText(recipe.recipeLink or "", 180), 250)
        + CEscapedWireLengthR42(CSafeText(recipe.itemLink or "", 180), 250)
        + CEscapedWireLengthR42(CSafeText(wireEffect, 160), 200)
        + string.len(tostring(recipe.requiredSkill or 0))
        + CEscapedWireLengthR42(CSafeText(recipe.difficulty or "", 12), 18)
        + CEscapedWireLengthR42(CSafeText(wireSource, 24), 32)
    return total
end

-- Exposed only for bounded diagnostics/tests; normal callers use the local helper.
OTLGM.MeasureCraftingRecipeWireLengthR42 = MeasureCraftingRecipeWireLengthR42

local function EncodeCraftingRecipe180(recipe)
    recipe = recipe or {}
    local reagentParts = {}
    local wireEffect, wireSource = CraftingWireEffect180(recipe)
    local reagentIndex, reagent
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
    return table.concat({
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
        CEscape(CSafeText(wireEffect, 160), 200),
        tostring(recipe.requiredSkill or 0),
        CEscape(CSafeText(recipe.difficulty or "", 12), 18),
        CEscape(CSafeText(wireSource, 24), 32)
    }, ",")
end

-- The transfer is prepared and emitted incrementally. It stores only sorted
-- recipe keys, cursors and a small carry buffer; it never builds a full wire
-- snapshot, chunk array or payload array in one frame.
-- Test/diagnostic hook used by the release gate to prove that the allocation-light
-- PREPARE measurement is byte-exact with the actual SEND encoder.
OTLGM.EncodeCraftingRecipeWireR42 = EncodeCraftingRecipe180

local function PrepareCraftingTransferSlice180(transfer, profession, budget)
    local keys = transfer.recipeKeys or {}
    local processed = 0
    while transfer.prepareIndex <= table.getn(keys) and processed < budget do
        local prepareIndex = transfer.prepareIndex
        local recipe = profession and profession.recipes and profession.recipes[keys[prepareIndex]] or nil
        -- Measure without allocating the escaped wire record. SEND performs the
        -- only actual recipe encoding, keeping PREPARE cheap even on weak PCs.
        local measuredLength = MeasureCraftingRecipeWireLengthR42(recipe)
        transfer.serializedLength = (tonumber(transfer.serializedLength) or 0) + measuredLength
        if prepareIndex > 1 then transfer.serializedLength = transfer.serializedLength + 1 end
        transfer.prepareIndex = prepareIndex + 1
        processed = processed + 1
    end
    if transfer.prepareIndex > table.getn(keys) then
        transfer.totalChunks = math.max(1, math.ceil((tonumber(transfer.serializedLength) or 0) / transfer.chunkSize))
        transfer.phase = "SEND"
        transfer.recipeIndex = 1
        transfer.sendBuffer = ""
        transfer.nextChunk = 1
    end
    return processed
end

local function NextCraftingWireChunk180(transfer, profession)
    local keys = transfer.recipeKeys or {}
    local chunkSize = tonumber(transfer.chunkSize) or 120
    local buffer = transfer.sendBuffer or ""
    while string.len(buffer) < chunkSize and transfer.recipeIndex <= table.getn(keys) do
        local recipeIndex = transfer.recipeIndex
        local recipe = profession and profession.recipes and profession.recipes[keys[recipeIndex]] or nil
        -- r42 deliberately avoids a whole-profession wire cache. Encoding one
        -- recipe here keeps retained memory flat and prevents a large transfer
        -- from turning into a later Lua GC spike.
        local encoded = EncodeCraftingRecipe180(recipe)
        if recipeIndex > 1 then buffer = buffer .. "~" end
        buffer = buffer .. encoded
        transfer.recipeIndex = recipeIndex + 1
    end
    local chunk = string.sub(buffer, 1, chunkSize)
    transfer.sendBuffer = string.sub(buffer, chunkSize + 1)
    return chunk
end

local MAX_CRAFTING_TRANSFER_CHUNKS_R42 = 240

local function CraftingTransferKey180(target, ownerName, professionKey, hash)
    return CNormalizeName(target) .. ":" .. CNormalizeName(ownerName) .. ":" .. tostring(professionKey or "") .. ":" .. tostring(hash or "0")
end

local function CraftingWireMeasureKeyR42(ownerName, professionKey)
    return CNormalizeName(ownerName) .. ":" .. tostring(professionKey or "")
end

local function GetCraftingWireMeasureCacheR42(owner)
    owner.runtime = owner.runtime or {}
    if type(owner.runtime.craftingWireMeasureCacheR42) ~= "table" then owner.runtime.craftingWireMeasureCacheR42 = {} end
    return owner.runtime.craftingWireMeasureCacheR42
end

local function StoreCraftingWireMeasureR42(owner, transfer, exact)
    if not owner or not transfer then return end
    local cache = GetCraftingWireMeasureCacheR42(owner)
    local key = CraftingWireMeasureKeyR42(transfer.ownerName, transfer.professionKey)
    local length = math.max(0, tonumber(transfer.serializedLength) or 0)
    local previous = cache[key]
    if exact then
        cache[key] = { hash = tostring(transfer.hash or "0"), length = length, exact = true }
    elseif not previous or tostring(previous.hash or "") ~= tostring(transfer.hash or "0")
        or (not previous.exact and length > (tonumber(previous.lowerBound) or 0)) then
        cache[key] = { hash = tostring(transfer.hash or "0"), lowerBound = length, exact = false }
    end
end

function OTLGM:CreateCraftingOutboundTransfer180(ownerName, professionKey, target, allowRelay)
    if not target or target == "" then return false end
    if self.IsModernSyncPeerR2 and not self:IsModernSyncPeerR2(target) then return false end
    local craft = self:EnsureCraftingDB()
    local character = craft and craft.characters and craft.characters[ownerName]
    local profession = character and character.professions and character.professions[professionKey]
    if not character or not profession or (not profession.localOwner and not allowRelay) then return false end
    -- A newly captured native detail can change effect provenance/serialized data
    -- before the trailing-edge batch commit runs. Never start a transfer against
    -- a stale profession hash or reuse a measurement from that old wire shape.
    if profession.hashDirty184 and self.RehashCraftingProfession then
        self:RehashCraftingProfession(profession)
        profession.hashDirty184 = nil
    end

    self.runtime = self.runtime or {}
    self.runtime.craftingOutboundTransferStates180 = self.runtime.craftingOutboundTransferStates180 or {}
    self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or { scans = 0, noChangeSkips = 0, commits = 0 }
    local states = self.runtime.craftingOutboundTransferStates180
    local now = self:Now()
    local hash = tostring(profession.hash or CHashRecipes(profession.recipes or {}) or "0")
    local key = CraftingTransferKey180(target, ownerName, professionKey, hash)
    local existing = states[key]
    if existing and (tonumber(existing.expiresAt) or 0) > now then
        existing.expiresAt = now + 180
        existing.lastRequestedAt = now
        self.runtime.craftingMetrics180.transferCoalesced = (tonumber(self.runtime.craftingMetrics180.transferCoalesced) or 0) + 1
        if self.WakeScheduler180 then self:WakeScheduler180("crafting-transfer-coalesced") end
        return true
    end

    -- A new revision supersedes an older transfer for the same target/owner/profession.
    local logicalPrefix = CNormalizeName(target) .. ":" .. CNormalizeName(ownerName) .. ":" .. tostring(professionKey or "") .. ":"
    local storedKey, stored
    for storedKey, stored in pairs(states) do
        if string.sub(storedKey, 1, string.len(logicalPrefix)) == logicalPrefix then states[storedKey] = nil end
    end

    local networkLimit = self.GetNetworkPayloadLimit and self:GetNetworkPayloadLimit("WHISPER", target) or 250
    local headerReserve = 92 + string.len(CEscape(ownerName, 42)) + string.len(professionKey)
    local chunkSize = math.max(72, math.min(165, networkLimit - 4 - headerReserve))
    local recipeKeys = CShareableRecipeKeysR27(profession.recipes or {})

    local stateCount = CTableCount(states)
    if stateCount >= 3 then
        -- R31: three simultaneous explicit sessions are enough for the manual
        -- peer fallback while keeping serialization/runtime memory tightly
        -- bounded. The requester already owns retry/fallback behavior.
        self.runtime.craftingMetrics180.transferCapacityRejected = (tonumber(self.runtime.craftingMetrics180.transferCapacityRejected) or 0) + 1
        return false
    end

    local measureCacheR42 = GetCraftingWireMeasureCacheR42(self)
    local measureKeyR42 = CraftingWireMeasureKeyR42(ownerName, professionKey)
    local cachedMeasureR42 = measureCacheR42[measureKeyR42]
    local cachedLengthR42 = nil
    if cachedMeasureR42 and tostring(cachedMeasureR42.hash or "") == hash then
        if cachedMeasureR42.exact then
            cachedLengthR42 = math.max(0, tonumber(cachedMeasureR42.length) or 0)
            self.runtime.craftingMetrics180.wireMeasureCacheHitsR42 = (tonumber(self.runtime.craftingMetrics180.wireMeasureCacheHitsR42) or 0) + 1
        elseif (tonumber(cachedMeasureR42.lowerBound) or 0) > (chunkSize * MAX_CRAFTING_TRANSFER_CHUNKS_R42) then
            -- A previous bounded measurement already proved this exact snapshot
            -- cannot fit this target's envelope. Reject without redoing work.
            self.runtime.craftingMetrics180.earlyOversizedCacheRejectR42 = (tonumber(self.runtime.craftingMetrics180.earlyOversizedCacheRejectR42) or 0) + 1
            return false
        end
    end
    if cachedLengthR42 and cachedLengthR42 > (chunkSize * MAX_CRAFTING_TRANSFER_CHUNKS_R42) then
        self.runtime.craftingMetrics180.earlyOversizedCacheRejectR42 = (tonumber(self.runtime.craftingMetrics180.earlyOversizedCacheRejectR42) or 0) + 1
        return false
    end

    states[key] = {
        key = key, ownerName = ownerName, professionKey = professionKey, target = target,
        timestamp = tonumber(profession.ts) or now, rank = tonumber(profession.rank) or 0,
        maxRank = tonumber(profession.maxRank) or 0, count = CShareableRecipeCountR27(profession.recipes),
        hash = hash, chunkSize = chunkSize, recipeKeys = recipeKeys,
        phase = cachedLengthR42 and "SEND" or "PREPARE",
        prepareIndex = cachedLengthR42 and (table.getn(recipeKeys) + 1) or 1,
        serializedLength = cachedLengthR42 or 0,
        totalChunks = cachedLengthR42 and math.max(1, math.ceil(cachedLengthR42 / chunkSize)) or nil,
        recipeIndex = cachedLengthR42 and 1 or nil, sendBuffer = cachedLengthR42 and "" or nil, nextChunk = cachedLengthR42 and 1 or nil,
        createdAt = now, lastRequestedAt = now, expiresAt = now + 180,
    }
    self.runtime.craftingMetrics180.transfersCreated = (tonumber(self.runtime.craftingMetrics180.transfersCreated) or 0) + 1
    if self.WakeScheduler180 then self:WakeScheduler180("crafting-transfer-created") end
    return true
end

function OTLGM:ProcessCraftingOutboundTransfers180(maxChunks)
    self.runtime = self.runtime or {}
    local states = self.runtime.craftingOutboundTransferStates180
    if type(states) ~= "table" or not next(states) then return 0 end
    if self.InCombat and self:InCombat() then return 0 end
    maxChunks = math.max(1, math.min(6, tonumber(maxChunks) or 4))
    local now = self.GetPreciseTime180 and self:GetPreciseTime180() or self:Now()
    local produced = 0
    local workUnitsR31 = 0
    local maxWorkUnitsR31 = math.max(1, math.min(2, tonumber(maxChunks) or 1))
    local keys = CSortedKeys(states)
    local index, key, transfer
    for index = 1, table.getn(keys) do
        if produced >= maxChunks or workUnitsR31 >= maxWorkUnitsR31 then break end
        key = keys[index]
        transfer = states[key]
        if transfer then
            if (tonumber(transfer.nextAttemptAt) or 0) > now then
                -- Capacity/backoff deadline is represented in the shared scheduler.
            elseif now > (tonumber(transfer.expiresAt) or 0) then
                states[key] = nil
            else
                local craft = self:EnsureCraftingDB()
                local character = craft and craft.characters and craft.characters[transfer.ownerName]
                local profession = character and character.professions and character.professions[transfer.professionKey]
                if not profession or tostring(profession.hash or CHashRecipes(profession.recipes or {}) or "0") ~= tostring(transfer.hash or "0") then
                    states[key] = nil
                    self.runtime.craftingMetrics180.transferSuperseded = (tonumber(self.runtime.craftingMetrics180.transferSuperseded) or 0) + 1
                elseif transfer.phase == "PREPARE" then
                    local prepared = PrepareCraftingTransferSlice180(transfer, profession, 1)
                    workUnitsR31 = workUnitsR31 + math.max(1, prepared)
                    self.runtime.craftingMetrics180.outboundWorkUnitsR31 = (tonumber(self.runtime.craftingMetrics180.outboundWorkUnitsR31) or 0) + math.max(1, prepared)
                    self.runtime.craftingMetrics180.recipePrepareUnits = (tonumber(self.runtime.craftingMetrics180.recipePrepareUnits) or 0) + prepared
                    local safeWireLimitR42 = math.max(1, tonumber(transfer.chunkSize) or 120) * MAX_CRAFTING_TRANSFER_CHUNKS_R42
                    if transfer.phase == "SEND" then StoreCraftingWireMeasureR42(self, transfer, true) end
                    if (tonumber(transfer.serializedLength) or 0) > safeWireLimitR42 then
                        StoreCraftingWireMeasureR42(self, transfer, transfer.phase == "SEND")
                        states[key] = nil
                        self.communityDroppedPayloads = (self.communityDroppedPayloads or 0) + 1
                        self.lastCommunityDroppedSize = tonumber(transfer.serializedLength) or 0
                        self.runtime.craftingMetrics180.oversizedTransfers = (tonumber(self.runtime.craftingMetrics180.oversizedTransfers) or 0) + 1
                        self.runtime.craftingMetrics180.earlyOversizedAbortR42 = (tonumber(self.runtime.craftingMetrics180.earlyOversizedAbortR42) or 0) + 1
                        self.runtime.craftingMetrics180.lastOversizedOwner = transfer.ownerName
                        self.runtime.craftingMetrics180.lastOversizedProfession = transfer.professionKey
                    elseif transfer.phase == "PREPARE" then
                        -- PREPARE is background work. A short deadline prevents a
                        -- large profession from pinning the compatibility scheduler
                        -- at its fastest poll rate while the player is idle in town.
                        transfer.nextAttemptAt = now + 0.05
                    elseif transfer.phase == "SEND" and (tonumber(transfer.totalChunks) or 0) > MAX_CRAFTING_TRANSFER_CHUNKS_R42 then
                        states[key] = nil
                        self.communityDroppedPayloads = (self.communityDroppedPayloads or 0) + 1
                        self.lastCommunityDroppedSize = tonumber(transfer.serializedLength) or 0
                        self.runtime.craftingMetrics180.oversizedTransfers = (tonumber(self.runtime.craftingMetrics180.oversizedTransfers) or 0) + 1
                        self.runtime.craftingMetrics180.lastOversizedOwner = transfer.ownerName
                        self.runtime.craftingMetrics180.lastOversizedProfession = transfer.professionKey
                        if self.runtime.shellCraftingManual and self.ui and self.ui.currentPage == "professions" and self.SetStatus then
                            self:SetStatus("This profession update is too large to share safely.", 4, { source = "crafting", manual = true })
                        end
                    end
                elseif transfer.phase == "SEND" then
                while transfer.nextChunk <= transfer.totalChunks and produced < maxChunks do
                    if self.CanQueueNetworkPayloads and not self:CanQueueNetworkPayloads(1, 60) then
                        self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
                        self.runtime.craftingMetrics180.queueWaits = (tonumber(self.runtime.craftingMetrics180.queueWaits) or 0) + 1
                        transfer.nextAttemptAt = now + 0.5
                        if self.ScheduleAfter180 then
                            self:ScheduleAfter180("crafting-transfer-capacity", 0.5, function(owner)
                                if owner.WakeScheduler180 then owner:WakeScheduler180("crafting-transfer-capacity") end
                            end, 0)
                        end
                        return produced
                    end
                    local sequence = transfer.nextChunk
                    local chunk = NextCraftingWireChunk180(transfer, profession)
                    local payload = table.concat({
                        self.craftingProtocol, "RC3", CEscape(transfer.ownerName, 42), transfer.professionKey,
                        tostring(transfer.timestamp or now), tostring(transfer.rank or 0), tostring(transfer.maxRank or 0),
                        tostring(sequence), tostring(transfer.totalChunks), tostring(transfer.count or 0), tostring(transfer.hash or "0"), chunk
                    }, "^")
                    local networkLimit = self.GetNetworkPayloadLimit and self:GetNetworkPayloadLimit("WHISPER", transfer.target) or 250
                    if string.len(payload) > networkLimit then
                        states[key] = nil
                        self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
                        self.runtime.craftingMetrics180.payloadRejected = (tonumber(self.runtime.craftingMetrics180.payloadRejected) or 0) + 1
                        break
                    end
                    local coalesceKey = "crafting:rc3:" .. key .. ":" .. tostring(sequence)
                    if not self:QueueCommunityPayload(payload, "WHISPER", transfer.target, 0, coalesceKey) then
                        transfer.nextAttemptAt = now + 0.5
                        return produced
                    end
                    transfer.nextAttemptAt = nil
                    transfer.nextChunk = sequence + 1
                    transfer.lastProgressAt = now
                    produced = produced + 1
                    workUnitsR31 = workUnitsR31 + 1
                    self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
                    self.runtime.craftingMetrics180.outboundWorkUnitsR31 = (tonumber(self.runtime.craftingMetrics180.outboundWorkUnitsR31) or 0) + 1
                    self.runtime.craftingMetrics180.chunksProduced = (tonumber(self.runtime.craftingMetrics180.chunksProduced) or 0) + 1
                end
                if states[key] and transfer.nextChunk > transfer.totalChunks then
                    states[key] = nil
                    self.runtime.craftingMetrics180.transfersCompleted = (tonumber(self.runtime.craftingMetrics180.transfersCompleted) or 0) + 1
                end
                end
            end
        end
    end
    -- Do not WakeScheduler180 here. This function is normally running inside
    -- __compatibility180 and SchedulerOnUpdate recomputes CraftingDue180 after
    -- the slice. Forcing an immediate wake here collapsed a 50 ms PREPARE
    -- deadline back to the scheduler's 20 ms minimum poll.
    return produced
end

function OTLGM.__impl180.Stage_Crafting_QueueCraftingProfessionShare_1__impl1(self, ownerName, professionKey, target, allowRelay)
    local craft = self:EnsureCraftingDB()
    local character = craft and craft.characters and craft.characters[ownerName]
    local profession = character and character.professions and character.professions[professionKey]
    if not character or not profession or (not profession.localOwner and not (target and allowRelay)) then return false end
    local now = self:Now()
    if target then return self:CreateCraftingOutboundTransfer180(ownerName, professionKey, target, allowRelay) end
    if profession.lastSharedAt and now - profession.lastSharedAt < self.craftingShareCooldown then return false end
    -- Automatic changes share only the compact manifest. Full recipe snapshots
    -- are produced lazily and only in response to an explicit targeted CWANT.
    if self.QueueCraftingChangeManifest157 then
        local queued = self:QueueCraftingChangeManifest157(ownerName, professionKey)
        if queued then profession.lastSharedAt = now end
        return queued
    end
    return false
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

function OTLGM.__impl180.Stage_Crafting_RequestCraftingSync_1__impl1(self, force)
    local craft = self:EnsureCraftingDB()
    if not craft or not SendAddonMessage or not GetGuildInfo("player") then return false end
    local now = self:Now()
    if not force and craft.lastSync and now - craft.lastSync < 60 then return false end
    if self.lastCraftingSyncRequestAt and now - self.lastCraftingSyncRequestAt < 20 then return false end
    self.lastCraftingSyncRequestAt = now
    craft.lastSync = now
    craft.syncState = { active = true, started = now, completed = 0, received = 0 }
    self:QueueCommunityPayload(table.concat({ self.craftingProtocol, "SYNC", self.version }, "^"), "GUILD", nil, 2, "crafting:legacy-sync")
    if self.SetStatus then self:SetStatus("Requesting current crafting data from online addon users...", nil, { source = "crafting", manual = self.ui and self.ui.main and self.ui.main:IsVisible() and self.ui.currentPage == "professions" }) end
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
    if self.WakeScheduler180 then self:WakeScheduler180("crafting-share-response") end
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
        if IsLocalAccountAuthor(record.author) then self:QueueCraftingRequestRecord180(record, "WHISPER", targetName) end
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

function OTLGM.__impl180.Stage_Crafting_ProcessCraftingTimers_1__impl1(self, cacheMaximumR26)
    local inCombat = self.InCombat and self:InCombat()
    if not inCombat then
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
        self:ProcessCraftingCacheQueue(cacheMaximumR26 or 8)
    end
    local craft = self:EnsureCraftingDB()
    -- Modern manifest recovery can legitimately carry a large profession for
    -- longer than the old 25-second broadcast window. The reliability owner
    -- finishes quiet/no-peer requests earlier and keeps active transfers alive
    -- for the same bounded window enforced by inbound security.
    if craft and craft.syncState and craft.syncState.active and self:Now() - (craft.syncState.started or 0) >= 125 then
        craft.syncState.active = false
        if self.SetStatus then self:SetStatus("Profession update finished. Received " .. tostring(craft.syncState.received or 0) .. " profession update(s).", nil, { source = "crafting", manual = craft.syncState.manual180 and self.ui and self.ui.main and self.ui.main:IsVisible() and self.ui.currentPage == "professions" }) end
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
    -- Match the current RC3 trust rule: once this client has a snapshot that
    -- came directly from the profession owner, an indirect legacy relay may not
    -- replace it. Relays can still populate owners for whom no direct source is
    -- known.
    if existingProfession and not directFromOwner and existingProfession.sourceKind == "direct" then return true end
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
    local label = CProfessionLabel183(professionKey)
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

function OTLGM.__impl180.Stage_Crafting_ApplyRemoteRecipeSnapshot155_1__impl1(self, fields, sender, channel)
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
                    difficulty=CUnescape(f[15] or ""), effectSource183=CUnescape(f[16] or "") }
                if recipe.effectText ~= "" then
                    if CDerivedEnchantEffect183(recipe.name, recipe.effectText) then
                        recipe.effectText = ""
                        recipe.effectSource183 = "UNKNOWN"
                    else
                        recipe.effectSource183 = CRemoteEnchantSourceR24(recipe.effectSource183, true)
                        if recipe.effectSource183 == "UNKNOWN" then recipe.effectText = "" end
                    end
                else
                    recipe.effectSource183 = "UNKNOWN"
                end
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

    -- R24 mixed-version protection: a weaker/older RC3 payload must not erase a
    -- richer native effect already stored for the same remote character.
    local existingProfessionR24 = existing and existing.professions and existing.professions[professionKey]
    if existingProfessionR24 and type(existingProfessionR24.recipes) == "table" then
        local recipeKeyR24, incomingRecipeR24
        for recipeKeyR24, incomingRecipeR24 in pairs(recipes) do
            local oldRecipeR24 = existingProfessionR24.recipes[recipeKeyR24]
            if oldRecipeR24 then
                local oldTextR24 = tostring(oldRecipeR24.effectText or "")
                local oldSourceR24 = CRemoteEnchantSourceR24(oldRecipeR24.effectSource183, oldTextR24 ~= "")
                local incomingTextR24 = tostring(incomingRecipeR24.effectText or "")
                local incomingSourceR24 = CNormalizeEnchantSourceR24(incomingRecipeR24.effectSource183)
                local oldTrustedR24 = oldTextR24 ~= "" and CTrustedEnchantSourceR24(oldSourceR24)
                    and not CDerivedEnchantEffect183(oldRecipeR24.name or incomingRecipeR24.name, oldTextR24)
                local incomingTrustedR24 = incomingTextR24 ~= "" and CTrustedEnchantSourceR24(incomingSourceR24)
                local incomingWeakerR24 = (not incomingTrustedR24)
                    or (oldSourceR24 == "REMOTE_NATIVE" and incomingSourceR24 == "LEGACY_NATIVE")
                if oldTrustedR24 and incomingWeakerR24 then
                    incomingRecipeR24.effectText = oldTextR24
                    incomingRecipeR24.effectSource183 = oldSourceR24
                    incomingRecipeR24.effectChecked = oldRecipeR24.effectChecked
                end
            end
        end
    end
    local computedHash = CHashRecipes(recipes)
    local incomingScore = CProfessionCompletenessScore(recipes)
    local member=self:GetMember(owner)
    local character=existing or {name=owner,professions={}}
    character.name=owner; character.class=member and member.class or character.class or ""; character.level=member and member.level or character.level or 0
    character.updated=self:Now(); character.source=sender; character.professions=character.professions or {}
    local label=CProfessionLabel183(professionKey)
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
    local label = CProfessionLabel183(professionKey)
    local old = character.professions[professionKey]
    -- Mixed-version hardening: legacy RC2 snapshots do not carry the richer
    -- recipe metadata introduced by current clients.  Preserve verified/native
    -- effect text and other non-wire detail fields for recipes that are still
    -- present instead of letting an older client erase them during sync.
    if old and type(old.recipes) == "table" then
        local recipeKey, incomingRecipe
        for recipeKey, incomingRecipe in pairs(recipes) do
            local oldRecipe = old.recipes[recipeKey]
            if oldRecipe then
                local oldEffectSource = CRemoteEnchantSourceR24(oldRecipe.effectSource183, oldRecipe.effectText and oldRecipe.effectText ~= "")
                local trustedOldEffect = oldRecipe.effectText and oldRecipe.effectText ~= ""
                    and CTrustedEnchantSourceR24(oldEffectSource)
                    and not CDerivedEnchantEffect183(oldRecipe.name or incomingRecipe.name, oldRecipe.effectText)
                if (not incomingRecipe.effectText or incomingRecipe.effectText == "") and trustedOldEffect then
                    incomingRecipe.effectText = oldRecipe.effectText
                    incomingRecipe.effectSource183 = oldEffectSource
                    incomingRecipe.effectChecked = oldRecipe.effectChecked
                end
                if (tonumber(incomingRecipe.requiredSkill) or 0) <= 0 and (tonumber(oldRecipe.requiredSkill) or 0) > 0 then incomingRecipe.requiredSkill = oldRecipe.requiredSkill end
                if (not incomingRecipe.requirementText or incomingRecipe.requirementText == "") and oldRecipe.requirementText and oldRecipe.requirementText ~= "" then incomingRecipe.requirementText = oldRecipe.requirementText end
                if (not incomingRecipe.difficulty or incomingRecipe.difficulty == "") and oldRecipe.difficulty and oldRecipe.difficulty ~= "" then incomingRecipe.difficulty = oldRecipe.difficulty end
                if (not incomingRecipe.detailKey or incomingRecipe.detailKey == "") and oldRecipe.detailKey and oldRecipe.detailKey ~= "" then incomingRecipe.detailKey = oldRecipe.detailKey end
                if (not incomingRecipe.detailHash or incomingRecipe.detailHash == "") and oldRecipe.detailHash and oldRecipe.detailHash ~= "" then incomingRecipe.detailHash = oldRecipe.detailHash end
            end
        end
    end
    local computedHash = CHashRecipes(recipes)
    local incomingScore = CProfessionCompletenessScore(recipes)
    local changed = not old or old.hash ~= computedHash
    local oldCount = old and CTableCount(old.recipes) or 0
    character.professions[professionKey] = {
        key = professionKey, label = label, rank = rank, maxRank = maxRank,
        ts = timestamp, receivedAt = self:Now(), hash = computedHash, wireHash = hash, recipes = recipes,
        completenessScore = incomingScore, sourceKind = directFromOwner and "direct" or "relay", source = sender,
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
    return CRAFTING_PROFESSION_DEFINITIONS183
end

function OTLGM:GetCraftingProfessionDefinition183(professionKey)
    return CRAFTING_PROFESSION_BY_KEY183[tostring(professionKey or "")]
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
    local textFields = { "itemLink", "recipeLink", "effectText", "effectSource183", "detailKey", "detailHash", "itemType", "difficulty", "requirementText" }
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

-- r30: the old search path rebuilt the full cross-character recipe aggregate
-- synchronously for every cache miss. With 700-800 shared recipes that could
-- stall the client for hundreds of milliseconds. Build the immutable aggregate
-- in bounded scheduler slices and let page/search filters read that index.
function OTLGM:RefreshCraftingResultCrafterStateR46(result)
    if type(result) ~= "table" then return result end
    self.runtime = self.runtime or {}
    local token = self.GetCraftingRosterActivityTokenR46 and self:GetCraftingRosterActivityTokenR46() or "legacy"
    if result.crafterActivityTokenR46 == token then
        self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
        self.runtime.craftingMetrics180.activityResultSkipsR46 = (tonumber(self.runtime.craftingMetrics180.activityResultSkipsR46) or 0) + 1
        return result
    end
    local onlineCount, recentCount, olderCount = 0, 0, 0
    local index, crafter, activity, member
    for index = 1, table.getn(result.crafters or {}) do
        crafter = result.crafters[index]
        activity = self:GetCraftingCrafterActivityR46(crafter.name, crafter)
        member = activity.member
        if member then
            crafter.class = member.class or crafter.class or ""
            crafter.level = member.level or crafter.level or 0
        end
        crafter.online = activity.online and true or false
        crafter.recentR46 = activity.recent and true or false
        crafter.olderR46 = activity.older and true or false
        crafter.departedR46 = activity.departed and true or false
        crafter.activityGroupR46 = activity.group
        crafter.activityAgeR46 = activity.ageSeconds
        crafter.activityLabelR46 = activity.label
        crafter.activityAlphaR46 = activity.alpha
        if activity.online then onlineCount = onlineCount + 1 end
        if activity.recent then recentCount = recentCount + 1 else olderCount = olderCount + 1 end
    end
    table.sort(result.crafters or {}, function(a, b)
        local ag, bg = tonumber(a.activityGroupR46) or 2, tonumber(b.activityGroupR46) or 2
        if ag ~= bg then return ag < bg end
        local aa, ba = tonumber(a.activityAgeR46) or 2147483647, tonumber(b.activityAgeR46) or 2147483647
        if aa ~= ba then return aa < ba end
        if (a.ts or 0) ~= (b.ts or 0) then return (a.ts or 0) > (b.ts or 0) end
        return string.lower(a.name or "") < string.lower(b.name or "")
    end)
    result.onlineCrafterCountR46 = onlineCount
    result.recentCrafterCountR46 = recentCount
    result.olderCrafterCountR46 = olderCount
    result.crafterActivityTokenR46 = token
    self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
    self.runtime.craftingMetrics180.activityResultRefreshesR46 = (tonumber(self.runtime.craftingMetrics180.activityResultRefreshesR46) or 0) + 1
    return result
end

function OTLGM:GetCraftingCrafterCountsR46(result)
    if self.RefreshCraftingResultCrafterStateR46 then self:RefreshCraftingResultCrafterStateR46(result) end
    local total = table.getn(result and result.crafters or {})
    local recent = tonumber(result and result.recentCrafterCountR46)
    if recent == nil then recent = total end
    local older = tonumber(result and result.olderCrafterCountR46)
    if older == nil then older = math.max(0, total - recent) end
    local online = tonumber(result and result.onlineCrafterCountR46)
    if online == nil then
        online = 0
        local index
        for index = 1, total do if result.crafters[index].online then online = online + 1 end end
    end
    return total, recent, older, online
end

local function CRefreshAggregateCrafterStateR30(self, result)
    return self:RefreshCraftingResultCrafterStateR46(result)
end

local function CProcessAggregateRecipeR30(self, state, characterName, character, professionKey, profession, recipeKey, recipe)
    if not CShareableRecipeR27(recipe) then return end
    local aggregateName = CNormalizeText(recipe.name or "")
    local aggregateKey = professionKey .. ":" .. (aggregateName ~= "" and aggregateName or tostring(recipeKey))
    local result = state.map[aggregateKey]
    local resultItemId = result and tonumber(result.recipe and result.recipe.itemId) or 0
    local recipeItemId = tonumber(recipe.itemId) or 0
    if result and resultItemId > 0 and recipeItemId > 0 and resultItemId ~= recipeItemId then
        aggregateKey = aggregateKey .. ":" .. tostring(recipeItemId)
        result = state.map[aggregateKey]
    end
    if not result then
        result = {
            key = aggregateKey, professionKey = professionKey, professionLabel = profession.label or professionKey,
            recipe = CCopy(recipe), crafters = {}, crafterMap160 = {}, metadataScore160 = CRecipeMetadataScore160(recipe),
            metadataLocal160 = character.localOwner and true or false, metadataTs160 = profession.ts or character.updated or 0,
        }
        local searchable = CNormalizeText(recipe.name) .. " " .. CNormalizeText(profession.label or professionKey)
            .. " " .. CNormalizeText(recipe.effectText or "")
        if self.GetCraftingDetailSearchText then
            searchable = searchable .. " " .. CNormalizeText(self:GetCraftingDetailSearchText(recipe, professionKey, state.details))
        end
        local reagentIndex
        for reagentIndex = 1, table.getn(recipe.reagents or {}) do
            searchable = searchable .. " " .. CNormalizeText(recipe.reagents[reagentIndex].name)
        end
        result.searchTextR30 = searchable
        state.map[aggregateKey] = result
        table.insert(state.results, result)
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
        result.searchTextR30 = tostring(result.searchTextR30 or "") .. " " .. CNormalizeText(characterName)
    end
end

function OTLGM:InvalidateCraftingAggregateIndexR30(reason)
    self.runtime = self.runtime or {}
    self.runtime.craftingAggregateGenerationR30 = (tonumber(self.runtime.craftingAggregateGenerationR30) or 0) + 1
    self.runtime.craftingAggregateDirtyR30 = true
    self.runtime.craftingAggregateLastInvalidationR30 = tostring(reason or "data")
    if self.CancelTask180 and self.runtime.craftingAggregateBuildR30 then
        self:CancelTask180("crafting-aggregate-index-r30")
    end
    self.runtime.craftingAggregateBuildR30 = nil
end

function OTLGM:StartCraftingAggregateIndexR30(reason)
    self.runtime = self.runtime or {}
    if self.runtime.craftingAggregateBuildR30 then return true end
    local craft = self:EnsureCraftingDB()
    if not craft then return false end
    local revision = self:GetCraftingRecipeRevisionR46()
    local generation = tonumber(self.runtime.craftingAggregateGenerationR30) or 0
    local state = {
        revision = revision, generation = generation, craft = craft, details = craft.details,
        map = {}, results = {}, characterKey = nil, professionKey = nil, recipeKey = nil,
        character = nil, profession = nil, recipesProcessed = 0, slices = 0,
        startedAt = self:Now(), reason = tostring(reason or "query"),
    }
    self.runtime.craftingAggregateBuildR30 = state

    local function AdvanceOne(owner)
        while true do
            if state.profession then
                local recipeKey, recipe = next(state.profession.recipes or {}, state.recipeKey)
                if recipeKey ~= nil then
                    state.recipeKey = recipeKey
                    CProcessAggregateRecipeR30(owner, state, state.characterKey, state.character,
                        state.professionKey, state.profession, recipeKey, recipe)
                    state.recipesProcessed = state.recipesProcessed + 1
                    return true
                end
                state.profession, state.recipeKey = nil, nil
            end
            if state.character then
                local professionKey, profession = next(state.character.professions or {}, state.professionKey)
                if professionKey ~= nil then
                    state.professionKey, state.profession = professionKey, profession
                    state.recipeKey = nil
                else
                    state.character, state.professionKey = nil, nil
                end
            else
                local characterKey, character = next(state.craft.characters or {}, state.characterKey)
                if characterKey ~= nil then
                    state.characterKey, state.character = characterKey, character
                    state.professionKey, state.profession, state.recipeKey = nil, nil, nil
                else
                    return false
                end
            end
        end
    end

    local function Finish(owner)
        local i, result
        for i = 1, table.getn(state.results) do
            result = state.results[i]
            result.metadataScore160 = nil
            result.metadataLocal160 = nil
            result.metadataTs160 = nil
            result.crafterMap160 = nil
        end
        table.sort(state.results, function(a, b)
            local an = string.lower(a.recipe and a.recipe.name or "")
            local bn = string.lower(b.recipe and b.recipe.name or "")
            if an ~= bn then return an < bn end
            return (a.professionLabel or "") < (b.professionLabel or "")
        end)
        owner.runtime = owner.runtime or {}
        -- If data changed while this generation was building, do not publish a
        -- stale index. The next query starts a fresh bounded generation.
        if (owner:GetCraftingRecipeRevisionR46()) ~= state.revision
            or (tonumber(owner.runtime.craftingAggregateGenerationR30) or 0) ~= state.generation then
            owner.runtime.craftingAggregateBuildR30 = nil
            owner.runtime.craftingAggregateDiscardedR30 = (tonumber(owner.runtime.craftingAggregateDiscardedR30) or 0) + 1
            return
        end
        owner.runtime.craftingAggregateReadyR30 = {
            revision = state.revision, results = state.results, builtAt = owner:Now(),
            recipes = state.recipesProcessed, slices = state.slices,
        }
        owner.runtime.craftingAggregateBuildR30 = nil
        owner.runtime.craftingAggregateDirtyR30 = nil
        owner.runtime.craftingAggregateBuildsR30 = (tonumber(owner.runtime.craftingAggregateBuildsR30) or 0) + 1
        owner.runtime.craftingAggregateLastRecipesR30 = state.recipesProcessed
        owner.runtime.craftingAggregateLastSlicesR30 = state.slices
        if owner.InvalidateCraftingSearchCache then owner:InvalidateCraftingSearchCache() end
        if owner.ui and owner.ui.main and owner.ui.main:IsVisible() and owner.ui.currentPage == "professions" and owner.RefreshProfessionsPage then
            if owner.ScheduleAfter180 then
                owner:ScheduleAfter180("crafting-aggregate-ready-r30", 0.03, function(current) current:RefreshProfessionsPage() end, 72)
            else
                owner:RefreshProfessionsPage()
            end
        end
    end

    local function Slice(owner)
        if not state or owner.runtime.craftingAggregateBuildR30 ~= state then return end
        if (owner:GetCraftingRecipeRevisionR46()) ~= state.revision
            or (tonumber(owner.runtime.craftingAggregateGenerationR30) or 0) ~= state.generation then
            owner.runtime.craftingAggregateBuildR30 = nil
            return
        end
        local pressure = owner.GetClientPressure181 and owner:GetClientPressure181() or nil
        local level = pressure and tonumber(pressure.level) or 0
        local maximum = level >= 3 and 4 or level >= 2 and 8 or 18
        local budgetMs = level >= 3 and 0.45 or level >= 2 and 0.70 or 1.20
        local started
        if debugprofilestop then local ok, value = pcall(debugprofilestop) if ok then started = tonumber(value) end end
        local processed = 0
        while processed < maximum do
            if not AdvanceOne(owner) then Finish(owner) return end
            processed = processed + 1
            if started and debugprofilestop and processed >= 3 then
                local ok, nowMs = pcall(debugprofilestop)
                if ok and tonumber(nowMs) and tonumber(nowMs) - started >= budgetMs then break end
            end
        end
        state.slices = state.slices + 1
        owner.runtime.craftingAggregateSlicesR30 = (tonumber(owner.runtime.craftingAggregateSlicesR30) or 0) + 1
        local gap = level >= 3 and 0.20 or level >= 2 and 0.08 or 0.02
        owner:ScheduleAfter180("crafting-aggregate-index-r30", gap, Slice, 70)
    end

    if self.ScheduleAfter180 then
        return self:ScheduleAfter180("crafting-aggregate-index-r30", 0.01, Slice, 70)
    end
    -- Compatibility fallback for unusual stripped clients: still correct, but
    -- normal OctoWoW r30 always owns the bounded scheduler by the time UI opens.
    while AdvanceOne(self) do end
    Finish(self)
    return true
end

function OTLGM:GetCraftingAggregateIndexR30()
    self.runtime = self.runtime or {}
    local revision = self:GetCraftingRecipeRevisionR46()
    local ready = self.runtime.craftingAggregateReadyR30
    if ready and tonumber(ready.revision) == revision and not self.runtime.craftingAggregateDirtyR30 then
        return ready.results or {}, false
    end
    self:StartCraftingAggregateIndexR30("query")
    -- A previous complete generation is safe to display for a few frames while
    -- the new revision builds. This is preferable to freezing or blanking the UI.
    return ready and ready.results or {}, true
end

function OTLGM.__impl180.Stage_Crafting_GetCraftingSearchResults_1__impl1(self, query, professionFilter)
    local craft = self:EnsureCraftingDB()
    local results = {}
    if not craft then return results end
    query = CNormalizeText(query)
    professionFilter = professionFilter or "ALL"
    local aggregate, stale = self:GetCraftingAggregateIndexR30()
    self.runtime = self.runtime or {}
    self.runtime.craftingAggregateServedStaleR30 = stale and ((tonumber(self.runtime.craftingAggregateServedStaleR30) or 0) + 1)
        or (tonumber(self.runtime.craftingAggregateServedStaleR30) or 0)
    local i, result
    for i = 1, table.getn(aggregate or {}) do
        result = aggregate[i]
        if (professionFilter == "ALL" or professionFilter == result.professionKey)
            and (query == "" or string.find(tostring(result.searchTextR30 or ""), query, 1, true)) then
            CRefreshAggregateCrafterStateR30(self, result)
            table.insert(results, result)
        end
    end
    return results
end

function OTLGM:GetCraftingSummary()
    self.runtime = self.runtime or {}
    local craft = self:EnsureCraftingDB()
    local empty = { characters = 0, recentCharacters = 0, olderCharacters = 0, professions = 0, recipes = 0, uniqueRecipes = 0, recentUniqueRecipes = 0, requests = 0, responses = 0, unread = 0 }
    if not craft then return empty end
    local now = self:Now()
    -- Maintenance is useful, but walking the entire crafting store on every UI
    -- repaint was wasteful. At most once every five minutes is sufficient here;
    -- request lists still prune their own expirations when opened.
    if not self.runtime.craftingSummaryMaintenanceAtR46 or now - self.runtime.craftingSummaryMaintenanceAtR46 >= 300 then
        self.runtime.craftingSummaryMaintenanceAtR46 = now
        self:PurgeCraftingData(true)
    end
    local recipeRevision = self:GetCraftingRecipeRevisionR46()
    local activityToken = self.GetCraftingRosterActivityTokenR46 and self:GetCraftingRosterActivityTokenR46() or "legacy"
    local cached = self.runtime.craftingSummaryCacheR46
    local result
    if cached and cached.recipeRevision == recipeRevision and cached.activityToken == activityToken then
        result = cached.value
        self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
        self.runtime.craftingMetrics180.summaryCacheHitsR46 = (tonumber(self.runtime.craftingMetrics180.summaryCacheHitsR46) or 0) + 1
    else
        result = { characters = 0, recentCharacters = 0, olderCharacters = 0, professions = 0, recipes = 0, uniqueRecipes = 0, recentUniqueRecipes = 0, requests = 0, responses = 0, unread = 0 }
        local unique, recentUnique = {}, {}
        local name, character, professionKey, profession, recipeKey, recipe, has, activity
        for name, character in pairs(craft.characters or {}) do
            has = false
            activity = self:GetCraftingCrafterActivityR46(name, character)
            for professionKey, profession in pairs(character.professions or {}) do
                result.professions = result.professions + 1
                has = true
                for recipeKey, recipe in pairs(profession.recipes or {}) do
                    if CShareableRecipeR27(recipe) then
                        result.recipes = result.recipes + 1
                        unique[professionKey .. ":" .. recipeKey] = true
                        if activity.recent then recentUnique[professionKey .. ":" .. recipeKey] = true end
                    end
                end
            end
            if has then
                result.characters = result.characters + 1
                if activity.recent then result.recentCharacters = result.recentCharacters + 1 else result.olderCharacters = result.olderCharacters + 1 end
            end
        end
        result.uniqueRecipes = CTableCount(unique)
        result.recentUniqueRecipes = CTableCount(recentUnique)
        self.runtime.craftingSummaryCacheR46 = { recipeRevision = recipeRevision, activityToken = activityToken, value = result }
        self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
        self.runtime.craftingMetrics180.summaryBuildsR46 = (tonumber(self.runtime.craftingMetrics180.summaryBuildsR46) or 0) + 1
    end
    -- Requests/responses are small and volatile. Refresh only those counters so
    -- creating a commission never forces a full recipe-summary traversal.
    result.requests = CTableCount(craft.requests)
    result.responses = CTableCount(craft.responses)
    result.unread = (craft.unread.RECIPES or 0) + (craft.unread.REQUESTS or 0)
    return result
end

function OTLGM.__impl180.Stage_Crafting_GetCraftingProfessionCounts_1__impl1(self, query)
    local counts = { ALL = 0 }
    query = CNormalizeText(query or "")
    local aggregate = self:GetCraftingAggregateIndexR30()
    local i, result
    for i = 1, table.getn(aggregate or {}) do
        result = aggregate[i]
        if query == "" or string.find(tostring(result.searchTextR30 or ""), query, 1, true) then
            counts.ALL = counts.ALL + 1
            counts[result.professionKey] = (counts[result.professionKey] or 0) + 1
        end
    end
    return counts
end

function OTLGM.__impl180.Stage_Crafting_CreateCraftingRequest_1__impl1(self, kind, item, materials, note, requestIdentity)
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
        kind = kind, item = item, displayName = item, source = "GENERIC",
        materials = materials, note = note, status = "OPEN", stateRev = 0, stateTs = now,
    }
    if type(requestIdentity) == "table" then
        local identity = CCopy(requestIdentity)
        identity.requestId = record.id
        identity.requestRev = record.rev
        self:ApplyCraftingRequestIdentity180(record, identity)
    end
    craft.requests[record.id] = record
    self.lastCraftingRequestAt = now
    self:QueueCraftingRequestRecord180(record, "GUILD")
    self:AddCraftingEvent("REQUEST", player .. " requested " .. item, note ~= "" and note or ("Materials: " .. materials), "professions", now)
    self:OnCraftingDataChanged("REQUESTS", false)
    return true, record
end

function OTLGM:SerializeCraftingRequest(record)
    local status = CNormalizeRequestStatus(record and record.status)
    local stateSuffix = table.concat({
        status,
        CEscape(record and record.claimedBy or "", 42),
        tostring(record and record.stateTs or record and record.ts or 0),
        tostring(record and record.stateRev or 0),
    }, "^")
    local prefix = table.concat({
        self.craftingProtocol, "CREQ", CEscape(record.id, 38), tostring(record.rev or 1), tostring(record.ts or 0), tostring(record.expires or 0),
        CEscape(record.author, 42), tostring(record.level or 0), CEscape(record.class, 20), CEscape(record.kind, 16), CEscape(record.materials, 16)
    }, "^") .. "^"
    local suffix = "^" .. stateSuffix
    local available = math.max(0, 245 - string.len(prefix) - string.len(suffix) - 1)
    local itemBudget = math.min(96, math.max(0, math.floor(available * 0.58)))
    local item = CEscape(record.item, itemBudget)
    local noteBudget = math.max(0, available - string.len(item))
    local note = CEscape(record.note, noteBudget)
    return prefix .. item .. "^" .. note .. suffix
end

function OTLGM:GetCraftingRequests(includeCompleted)
    local craft = self:EnsureCraftingDB()
    local result = {}
    if not craft then return result end
    self:PurgeCraftingData(true)
    local id, request
    for id, request in pairs(craft.requests or {}) do
        request.status = CNormalizeRequestStatus(request.status)
        if includeCompleted or request.status ~= "COMPLETED" then table.insert(result, request) end
    end
    table.sort(result, function(a, b)
        local ap, bp = CRequestStatusPriority(a.status), CRequestStatusPriority(b.status)
        if ap ~= bp then return ap < bp end
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

function OTLGM:CanClaimCraftingRequest(record)
    if not record or CNormalizeRequestStatus(record.status) ~= "OPEN" then return false end
    local player = string.gsub(UnitName("player") or "", "%-.*$", "")
    if player == "" or CNormalizeName(player) == CNormalizeName(record.author) then return false end
    if not (GetGuildInfo and GetGuildInfo("player")) then return false end
    if CRequestMetaSource180(record.source) == "RECIPE" then
        local match = self:GetCraftingRequestMatch180(record)
        return match and match.current and true or false
    end
    -- Generic/legacy requests retain the 1.7.6-compatible manual Claim path.
    return true
end

function OTLGM:CanCompleteCraftingRequest(record)
    if not record or CNormalizeRequestStatus(record.status) ~= "CLAIMED" then return false end
    local player = string.gsub(UnitName("player") or "", "%-.*$", "")
    if CNormalizeName(player) == CNormalizeName(record.author) then return true end
    if CNormalizeName(player) == CNormalizeName(record.claimedBy) then return true end
    return self.IsOfficerMode and self:IsOfficerMode() or false
end

function OTLGM:ApplyCraftingRequestStateResponse(response, sender)
    local craft = self:EnsureCraftingDB()
    local request = craft and craft.requests and response and craft.requests[response.requestId]
    if not request then return true, "pending-request" end
    local status = response and CNormalizeRequestStatus(response.state) or "OPEN"
    if status ~= "CLAIMED" and status ~= "COMPLETED" then return false, "Invalid crafting request state." end
    local actor = CStateActor180(response, sender)
    if actor == "" then return false, "The state author is missing." end
    if sender and CNormalizeName(actor) ~= CNormalizeName(sender) then return false, "The state author does not match its sender." end
    if status == "CLAIMED" then
        if CNormalizeName(actor) == CNormalizeName(request.author) then return false, "The requester cannot claim their own request." end
        return true, "candidate"
    end
    local authorAllowed = CNormalizeName(actor) == CNormalizeName(request.author)
    local claimerAllowed = CNormalizeName(actor) == CNormalizeName(request.claimedBy)
    if not authorAllowed and not claimerAllowed and not CLeadershipActor180(self, actor) then
        return false, "Only the requester, claimed crafter or leadership can complete this request."
    end
    return true, "candidate"
end

function OTLGM:ReconcileCraftingRequestState(requestId)
    local craft = self:EnsureCraftingDB()
    local request = craft and craft.requests and craft.requests[requestId]
    if not request then return false end
    local oldStatus = CNormalizeRequestStatus(request.status)
    local oldClaimedBy = request.claimedBy
    -- COMPLETED is terminal. A delayed/stale Claim packet must never reopen or
    -- retroactively replace the crafter after completion has converged.
    if oldStatus == "COMPLETED" then return true, oldStatus, oldClaimedBy end
    local claims, completions = {}, {}
    local _, response
    for _, response in pairs(craft.responses or {}) do
        if response.requestId == requestId and response.state == "CLAIMED" then
            if CNormalizeName(response.author) ~= CNormalizeName(request.author) then table.insert(claims, response) end
        elseif response.requestId == requestId and response.state == "COMPLETED" then
            table.insert(completions, response)
        end
    end
    table.sort(claims, CClaimComesBefore180)
    local winner = claims[1]
    local winningClaimer = winner and CStateActor180(winner) or request.claimedBy
    local validCompletions = {}
    local index, actor
    for index = 1, table.getn(completions) do
        response = completions[index]
        actor = CStateActor180(response)
        if CNormalizeName(actor) == CNormalizeName(request.author)
            or (winningClaimer and CNormalizeName(actor) == CNormalizeName(winningClaimer))
            or CLeadershipActor180(self, actor) then table.insert(validCompletions, response) end
    end
    table.sort(validCompletions, CCompletionComesBefore180)
    local completion = validCompletions[1]
    if completion then
        request.status = "COMPLETED"
        request.claimedBy = winningClaimer
        request.claimedAt = winner and tonumber(winner.ts) or request.claimedAt
        request.completedBy = CStateActor180(completion)
        request.completedAt = tonumber(completion.ts) or self:Now()
        request.stateActor = request.completedBy
        request.stateTs = request.completedAt
        request.stateRev = math.max(tonumber(request.stateRev) or 0, tonumber(completion.stateRev) or 0, winner and tonumber(winner.stateRev) or 0)
    elseif winner then
        request.status = "CLAIMED"
        request.claimedBy = CStateActor180(winner)
        request.claimedAt = tonumber(winner.ts) or self:Now()
        request.completedBy = nil
        request.completedAt = nil
        request.stateActor = request.claimedBy
        request.stateTs = request.claimedAt
        request.stateRev = math.max(tonumber(request.stateRev) or 0, tonumber(winner.stateRev) or 0)
    end
    return true, oldStatus, oldClaimedBy
end

function OTLGM:PublishCraftingRequestState(id, status)
    local craft = self:EnsureCraftingDB()
    local request = craft and craft.requests and craft.requests[id]
    status = CNormalizeRequestStatus(status)
    if not request then return false, "This request is no longer available." end
    if status == "CLAIMED" and not self:CanClaimCraftingRequest(request) then
        return false, "Only a matching current-character crafter can claim this open request."
    end
    if status == "COMPLETED" and not self:CanCompleteCraftingRequest(request) then
        return false, "Only the requester, claimed crafter or leadership can complete this request."
    end
    if status ~= "CLAIMED" and status ~= "COMPLETED" then return false, "Unsupported crafting request state." end

    local now = self:Now()
    local actor = string.gsub(UnitName("player") or "Unknown", "%-.*$", "")
    local stateRev = (tonumber(request.stateRev) or 0) + 1
    local response = {
        id = self:MakePveID("S"), requestId = id, rev = 1, ts = now,
        expires = math.min(request.expires or (now + self.craftingResponseLifetime), now + self.craftingResponseLifetime),
        author = actor, class = CPlayerClassToken(), level = UnitLevel("player") or 0,
        canHelp = status == "CLAIMED", state = status, stateRev = stateRev,
        text = status == "CLAIMED" and "Claimed this crafting request." or "Marked this crafting request completed.",
    }
    local accepted, problem = self:ApplyCraftingRequestStateResponse(response, actor)
    if not accepted then return false, problem end
    craft.responses[response.id] = response
    local previousStatus = CNormalizeRequestStatus(request.status)
    self:ReconcileCraftingRequestState(id)
    if CNormalizeRequestStatus(request.status) ~= previousStatus and self.RemoveInboxObject180 then
        self:RemoveInboxObject180("CRAFT_REQUEST", id)
    end
    if status == "CLAIMED" and CNormalizeName(request.claimedBy) ~= CNormalizeName(actor) then
        craft.responses[response.id] = nil
        self:ReconcileCraftingRequestState(id)
        return false, "Another crafter already claimed this request."
    end
    self:QueueCommunityPayload(self:SerializeCraftingResponse(response), "GUILD")
    self:AddCraftingEvent("REQUEST_STATE", actor .. (status == "CLAIMED" and " claimed " or " completed ") .. (request.item or "a crafting request"), response.text, "professions", now)
    self:OnCraftingDataChanged("REQUESTS", false)
    return true, response
end

function OTLGM:ClaimCraftingRequest(id)
    return self:PublishCraftingRequestState(id, "CLAIMED")
end

function OTLGM:CompleteCraftingRequest(id)
    return self:PublishCraftingRequestState(id, "COMPLETED")
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
    self:RemoveCraftingRequestActions180(id)
    craft.deleted[id] = { rev = rev, ts = self:Now() }
    self:QueueCommunityPayload(table.concat({ self.craftingProtocol, "CDEL", id, tostring(rev) }, "^"), "GUILD")
    if not quiet then self:OnCraftingDataChanged("REQUESTS", false) end
    return true
end

function OTLGM:CloseCraftingRequest(id)
    -- Compatibility alias for old page-level callers.  The r2 UI exposes the
    -- explicit Complete action and never creates a fourth/legacy status.
    return self:CompleteCraftingRequest(id)
end

function OTLGM:AddCraftingResponse(requestId, text, canHelp)
    local craft = self:EnsureCraftingDB()
    local request = craft and craft.requests and craft.requests[requestId]
    if not request then return false, "This request is no longer available." end
    if CNormalizeRequestStatus(request.status) == "COMPLETED" then return false, "This request is already completed." end
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
    local suffix = ""
    if record.state == "CLAIMED" or record.state == "COMPLETED" then
        suffix = "^STATE1^" .. record.state .. "^" .. tostring(math.max(1, tonumber(record.stateRev) or 1))
    end
    return prefix .. CEscape(record.text, math.max(0, 245 - string.len(prefix) - string.len(suffix))) .. suffix
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

function OTLGM.__impl180.Stage_Crafting_SetCommunityReaction_1__impl1(self, targetType, targetId, reaction, force)
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

function OTLGM:CanShareGuildObject180(objectType, objectId, cooldown)
    self.runtime = self.runtime or {}
    self.runtime.guildObjectShareCooldown180 = type(self.runtime.guildObjectShareCooldown180) == "table" and self.runtime.guildObjectShareCooldown180 or {}
    local key = string.upper(tostring(objectType or "OBJECT")) .. ":" .. tostring(objectId or "")
    local now = self:Now()
    cooldown = math.max(10, tonumber(cooldown) or 30)
    local previous = tonumber(self.runtime.guildObjectShareCooldown180[key]) or 0
    if now - previous < cooldown then return false, math.max(1, math.ceil(cooldown - (now - previous))) end
    self.runtime.guildObjectShareCooldown180[key] = now
    local rows, storedKey = {}, nil
    for storedKey, previous in pairs(self.runtime.guildObjectShareCooldown180) do table.insert(rows, { key = storedKey, ts = tonumber(previous) or 0 }) end
    if table.getn(rows) > 80 then
        table.sort(rows, function(left, right) return left.ts < right.ts end)
        local index
        for index = 1, table.getn(rows) - 80 do self.runtime.guildObjectShareCooldown180[rows[index].key] = nil end
    end
    return true, 0
end

function OTLGM:SendGuildObjectShare180(objectType, objectId, text)
    text = CSafeText(text, 240)
    if text == "" or not SendChatMessage then return false, "chat-unavailable" end
    local allowed, remaining = self:CanShareGuildObject180(objectType, objectId, 30)
    if not allowed then
        if self.SetStatus then self:SetStatus("This item was just shared. Try again in " .. tostring(remaining) .. "s.") end
        return false, "cooldown"
    end
    local ok = pcall(SendChatMessage, text, "GUILD")
    if not ok then
        local key = string.upper(tostring(objectType or "OBJECT")) .. ":" .. tostring(objectId or "")
        if self.runtime and self.runtime.guildObjectShareCooldown180 then self.runtime.guildObjectShareCooldown180[key] = nil end
        return false, "send-failed"
    end
    return true
end

function OTLGM:ShareCraftingRequestToGuildChat(record)
    if not record then return false end
    local typeLabel = record.kind == "ENCHANT" and "Enchant" or (record.kind == "TRANSMUTE" and "Transmute" or (record.kind == "GEM" and "Gem" or "Craft"))
    local text = "[OTLGM Crafting] " .. typeLabel .. ": " .. tostring(record.displayName or record.item or "Unknown item")
    if record.materials == "READY" then text = text .. " — materials ready"
    elseif record.materials == "NEEDED" then text = text .. " — materials needed" end
    if record.note and record.note ~= "" then text = text .. ". " .. record.note end
    text = text .. ". Contact: " .. tostring(record.author or "requester") .. "."
    return self:SendGuildObjectShare180("CRAFT_REQUEST", record.id, text)
end

function OTLGM:SharePveGroupToGuildChat(record)
    if not record then return false end
    local text = "[OTLGM Group] " .. tostring(record.activity or "Group") .. " — " .. tostring(record.current or 1) .. "/" .. tostring(record.maxSize or 5)
    local needs = {}
    if (tonumber(record.needTank) or 0) > 0 then table.insert(needs, tostring(record.needTank) .. " Tank") end
    if (tonumber(record.needHeal) or 0) > 0 then table.insert(needs, tostring(record.needHeal) .. " Healer") end
    if (tonumber(record.needDps) or 0) > 0 then table.insert(needs, tostring(record.needDps) .. " Damage") end
    if table.getn(needs) > 0 then text = text .. ". Need: " .. table.concat(needs, ", ") end
    if record.note and record.note ~= "" then text = text .. ". " .. record.note end
    text = text .. ". Leader: " .. tostring(record.author or "unknown") .. "."
    return self:SendGuildObjectShare180("GROUP", record.id, text)
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

function OTLGM.__impl180.Stage_Crafting_ApplyRemoteCraftingRequest_1__impl1(self, fields, sender, channel)
    local craft = self:EnsureCraftingDB()
    if not craft then return false end
    local id = fields[3] or ""
    local rev = tonumber(fields[4]) or 0
    if id == "" then return false end
    local old = craft.requests[id]
    if old and (tonumber(old.rev) or 0) >= rev then
        self:ApplyPendingCraftingRequestMeta180(id, old)
        return true
    end
    local record = {
        id = id, rev = rev, ts = tonumber(fields[5]) or self:Now(), expires = tonumber(fields[6]) or (self:Now() + self.craftingRequestLifetime),
        author = CUnescape(fields[7]), level = tonumber(fields[8]) or 0, class = CUnescape(fields[9]),
        kind = CUnescape(fields[10]), materials = CUnescape(fields[11]), item = CUnescape(fields[12]), note = CUnescape(fields[13]),
        status = CNormalizeRequestStatus(CUnescape(fields[14])),
        claimedBy = CUnescape(fields[15]), stateTs = tonumber(fields[16]) or tonumber(fields[5]) or self:Now(),
        stateRev = math.max(0, tonumber(fields[17]) or 0),
    }
    if record.claimedBy == "" then record.claimedBy = nil end
    if record.status == "COMPLETED" then record.completedAt = record.stateTs end
    if channel ~= "WHISPER" and sender and CNormalizeName(record.author) ~= CNormalizeName(sender) then return false end
    craft.requests[id] = record
    self:ApplyPendingCraftingRequestMeta180(id, record)
    self:GetCraftingRequestPresentation180(record)
    self:ReconcileCraftingRequestState(id)
    self:EvaluateCraftingRequestMatch180(record, true, channel)
    if not old then
        self:IncrementCraftingUnread("REQUESTS")
        self:AddCraftingEvent("REQUEST", record.author .. " requested " .. record.item, record.note, "professions", record.ts)
    end
    self:OnCraftingDataChanged("REQUESTS", true)
    return true
end

function OTLGM.__impl180.Stage_Crafting_ApplyRemoteCraftingResponse_1__impl1(self, fields, sender, channel)
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
    if fields[13] == "STATE1" then
        local state = CNormalizeRequestStatus(fields[14])
        if state ~= "CLAIMED" and state ~= "COMPLETED" then return false end
        record.state = state
        record.stateRev = math.max(1, tonumber(fields[15]) or 1)
    end
    if channel ~= "WHISPER" and sender and CNormalizeName(record.author) ~= CNormalizeName(sender) then return false end
    if record.state then
        local stateAccepted = self:ApplyCraftingRequestStateResponse(record, sender)
        if not stateAccepted then return false end
    end
    local request = craft.requests[requestId]
    local oldStatus = request and CNormalizeRequestStatus(request.status) or nil
    craft.responses[id] = record
    if record.state and request then
        self:ReconcileCraftingRequestState(requestId)
        if CNormalizeRequestStatus(request.status) ~= CNormalizeRequestStatus(oldStatus) and self.RemoveInboxObject180 then
            self:RemoveInboxObject180("CRAFT_REQUEST", requestId)
        end
        self:NotifyCraftingRequestState180(request, oldStatus, true)
    end
    if not old then
        self:IncrementCraftingUnread("REQUESTS")
        self:AddCraftingEvent("RESPONSE", record.author .. (record.canHelp and " can help" or " replied"), request and request.item or record.text, "professions", record.ts)
    end
    self:OnCraftingDataChanged("REQUESTS", true)
    return true
end

function OTLGM.__impl180.Stage_Crafting_ApplyRemoteReaction_1__impl1(self, fields, sender, channel)
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
    self:RemoveCraftingRequestActions180(id)
    craft.deleted[id] = { rev = rev, ts = self:Now() }
    self:OnCraftingDataChanged("REQUESTS", true)
    return true
end

function OTLGM.__impl180.Stage_Crafting_HandleCommunityAddonMessage_1__impl1(self, message, channel, sender)
    if string.sub(message or "", 1, 3) ~= self.craftingProtocol .. "^" then return false end
    local fields = CSplit(message, "^")
    local kind = fields[2]
    if kind == "SYNC" then self:ScheduleCraftingShareResponse(sender) return true end
    if kind == "RC3" then return self:ApplyRemoteRecipeSnapshot155(fields, sender, channel) end
    if kind == "RC2" then return self:ApplyRemoteRecipeSnapshot152(fields, sender, channel) end
    if kind == "RCP" then return self:ApplyRemoteRecipeChunk(fields, sender, channel) end
    if kind == "CREQ" then return self:ApplyRemoteCraftingRequest(fields, sender, channel) end
    if kind == "CMETA1" then return self:ApplyRemoteCraftingRequestMeta180(fields, sender, channel) end
    if kind == "CRES" then return self:ApplyRemoteCraftingResponse(fields, sender, channel) end
    if kind == "REACT" then return self:ApplyRemoteReaction(fields, sender, channel) end
    if kind == "CDEL" then return self:ApplyRemoteCraftingDelete(fields, sender) end
    return false
end

function OTLGM.__impl180.Stage_Crafting_OnCraftingDataChanged_1__impl1(self, section, remote)
    self.runtime = self.runtime or {}
    self.runtime.pageDirtyR5 = self.runtime.pageDirtyR5 or {}
    if not (self.ui and self.ui.main and self.ui.main:IsVisible() and self.ui.currentPage == "professions") then
        self.runtime.pageDirtyR5.professions = true
    end
    if not (self.ui and self.ui.main and self.ui.main:IsVisible()) then return end

    local function RefreshRelevantCraftingPage184(owner)
        if not owner or not owner.ui or not owner.ui.main or not owner.ui.main:IsVisible() then return end
        if owner.RefreshProfessionsPage and owner.ui.currentPage == "professions" then owner:RefreshProfessionsPage() end
        if owner.RefreshHomePage and owner.ui.currentPage == "home" then owner:RefreshHomePage() end
        if owner.RefreshSearchPage and owner.ui.currentPage == "search" then owner:RefreshSearchPage() end
        if owner.RefreshPvePage and owner.ui.currentPage == "pve" then owner:RefreshPvePage() end
        if owner.RefreshNavigation then owner:RefreshNavigation() end
    end

    -- RC4-r9: remote recipe snapshots commonly arrive as a short packet burst.
    -- Rendering Professions/Home/Search after every individual chunk does no
    -- useful work; collapse only remote updates into one near-immediate repaint.
    -- Local button actions remain synchronous so the interface still feels exact.
    if remote and self.ScheduleAfter180 then
        self:ScheduleAfter180("crafting-visible-refresh-184", 0.08, RefreshRelevantCraftingPage184, 74)
    else
        RefreshRelevantCraftingPage184(self)
    end
end

local GLOBAL_SEARCH_CACHE_AGE185 = 8

function OTLGM:InvalidateGlobalSearchCache185(reason)
    self.runtime = self.runtime or {}
    self.runtime.globalSearchDataRevision185 = (tonumber(self.runtime.globalSearchDataRevision185) or 0) + 1
    self.runtime.globalSearchResultCache185 = nil
    self.runtime.globalSearchMetrics185 = self.runtime.globalSearchMetrics185 or { hits = 0, builds = 0, invalidations = 0 }
    self.runtime.globalSearchMetrics185.invalidations = (tonumber(self.runtime.globalSearchMetrics185.invalidations) or 0) + 1
    if reason and reason ~= "" then self.runtime.globalSearchLastInvalidation185 = tostring(reason) end
end

function OTLGM:GetGlobalSearchResults(query)
    query = CNormalizeText(query)
    local results = {}
    if query == "" then return results end
    local db = self:GetGuildDB()
    self.runtime = self.runtime or {}
    local rosterTableRC4 = db and db.roster or {}
    local rosterRevision = tostring(tonumber(db and db.lastScan) or 0) .. ":" .. tostring(tonumber(db and db.lastTotal) or 0) .. ":" .. tostring(tonumber(self.runtime.rosterTargetRevision184) or 0)
    local dataRevision185 = tonumber(self.runtime.globalSearchDataRevision185) or 0
    local now185 = self:Now()
    local cache185 = self.runtime.globalSearchResultCache185
    self.runtime.globalSearchMetrics185 = self.runtime.globalSearchMetrics185 or { hits = 0, builds = 0, invalidations = 0 }
    if cache185 and cache185.query == query and cache185.rosterRevision == rosterRevision
        and cache185.dataRevision == dataRevision185 and now185 - (tonumber(cache185.builtAt) or 0) <= GLOBAL_SEARCH_CACHE_AGE185 then
        self.runtime.globalSearchMetrics185.hits = (tonumber(self.runtime.globalSearchMetrics185.hits) or 0) + 1
        return cache185.results or results
    end
    local indexState = self.runtime.globalSearchRosterIndexRC4
    if not indexState or indexState.revision ~= rosterRevision or indexState.roster ~= rosterTableRC4 then
        indexState = { revision = rosterRevision, roster = rosterTableRC4, rows = {} }
        local indexedName, indexedMember
        for indexedName, indexedMember in pairs(db and db.roster or {}) do
            table.insert(indexState.rows, {
                name = indexedName, member = indexedMember,
                haystack = CNormalizeText((indexedName or "") .. " " .. (indexedMember.class or "") .. " " .. (indexedMember.rank or "") .. " " .. (indexedMember.zone or "") .. " " .. (indexedMember.publicNote or "")),
            })
        end
        self.runtime.globalSearchRosterIndexRC4 = indexState
    end
    local index, indexed
    for index = 1, table.getn(indexState.rows or {}) do
        indexed = indexState.rows[index]
        if string.find(indexed.haystack or "", query, 1, true) then
            local member = indexed.member or {}
            table.insert(results, { type = "MEMBER", title = indexed.name, detail = "Level " .. tostring(member.level or 0) .. " " .. (member.class or "") .. " - " .. (member.rank or ""), class = member.class, page = "roster", target = indexed.name, priority = member.online and 1 or 3 })
        end
    end
    local recipes = self:GetCraftingSearchResults(query, "ALL")
    local i, result
    -- Keep the complete matching recipe set. The native Search page owns
    -- viewport capacity/scrolling; truncating here made the Recipes filter
    -- silently incomplete and also distorted the first 50 mixed results.
    for i = 1, table.getn(recipes) do
        result = recipes[i]
        local total, recent, older, online = self:GetCraftingCrafterCountsR46(result)
        local recentLabelR51 = tostring(recent) .. " recent " .. (recent == 1 and "crafter" or "crafters")
        local onlineLabelR51 = tostring(online) .. " online"
        local availability = recentLabelR51 .. " - " .. onlineLabelR51
        if older > 0 then availability = availability .. " - " .. tostring(older) .. " inactive" end
        table.insert(results, { type = "RECIPE", title = result.recipe.name, detail = result.professionLabel .. " - " .. availability, icon = result.recipe.icon, itemId = result.recipe.itemId, page = "professions", target = result.key, priority = online > 0 and 1 or (recent > 0 and 2 or 3) })
    end
    local pve = self.EnsurePveDB and self:EnsurePveDB() or nil
    local id, record, haystack
    for id, record in pairs(pve and pve.requests or {}) do
        haystack = CNormalizeText((record.activity or "") .. " " .. (record.note or "") .. " " .. (record.author or ""))
        if string.find(haystack, query, 1, true) then table.insert(results, { type = "GROUP", title = record.activity or "Open group", detail = "Leader: " .. (record.author or "") .. " - " .. tostring(record.current or 1) .. "/" .. tostring(record.maxSize or 5), kind = record.kind or record.activityType, page = "pve", target = id, section = "GROUPS", priority = 1 }) end
    end
    local raids = {}
    for _, record in pairs(pve and pve.raids or {}) do table.insert(raids, record) end
    table.sort(raids, function(left, right)
        local leftTs, rightTs = tonumber(left.startTs) or 0, tonumber(right.startTs) or 0
        if leftTs ~= rightTs then return leftTs < rightTs end
        return tostring(left.id or "") < tostring(right.id or "")
    end)
    for i = 1, table.getn(raids) do
        record = raids[i]
        haystack = CNormalizeText((record.title or record.name or "") .. " " .. (record.note or record.briefing or "") .. " " .. (record.leader or record.author or ""))
        if string.find(haystack, query, 1, true) then
            table.insert(results, {
                type = "RAID", title = record.title or record.name or "Raid alert",
                detail = (record.leader or record.author or "Leadership") .. " - " .. tostring(record.date or record.day or "") .. " " .. tostring(record.time or record.st or ""),
                page = "pve", target = record.id, section = "RAIDS", priority = 1,
            })
        end
    end
    for id, record in pairs(pve and pve.board or {}) do
        haystack = CNormalizeText((record.text or "") .. " " .. (record.author or ""))
        if string.find(haystack, query, 1, true) then table.insert(results, { type = "BOARD", title = record.author or "Guild Board", detail = record.text or "", page = "pve", target = id, section = "BOARD", priority = 2 }) end
    end
    local craft = self:EnsureCraftingDB()
    for id, record in pairs(craft and craft.requests or {}) do
        local presentation = self:GetCraftingRequestPresentation180(record) or {}
        haystack = CNormalizeText((presentation.displayName or record.item or "") .. " " .. (presentation.recipeName or "") .. " " .. (presentation.professionKey or "") .. " " .. (record.note or "") .. " " .. (record.author or "") .. " " .. (record.kind or ""))
        if string.find(haystack, query, 1, true) then
            table.insert(results, {
                type = "CRAFT REQUEST", title = presentation.displayName or record.item or "Crafting request",
                detail = record.author .. " - " .. (presentation.source == "RECIPE" and ((presentation.professionLabel or presentation.professionKey or "Recipe") .. " - ") or "") .. (record.note or ""),
                icon = presentation.icon, itemId = presentation.itemId, quality = presentation.quality,
                objectType = "CRAFT_REQUEST", objectId = id, page = "professions", target = id, section = "REQUESTS", priority = 1,
            })
        end
    end
    if self.GetAnnouncementList152 then
        local announcements = self:GetAnnouncementList152(true)
        for i = 1, table.getn(announcements) do
            record = announcements[i]
            haystack = CNormalizeText((record.title or "") .. " " .. (record.body or "") .. " " .. (record.author or ""))
            if string.find(haystack, query, 1, true) then
                table.insert(results, { type = "ANNOUNCEMENT", title = record.title or "Leadership announcement", detail = (record.author or "Leadership") .. " - " .. string.sub(record.body or "", 1, 100), page = "home", target = record.id, archived = record.archived and true or false, priority = record.pinned and 0 or 1 })
            end
        end
    end
    table.sort(results, function(a, b)
        if (a.priority or 5) ~= (b.priority or 5) then return (a.priority or 5) < (b.priority or 5) end
        if a.type ~= b.type then return a.type < b.type end
        return string.lower(a.title or "") < string.lower(b.title or "")
    end)
    -- Do not cap the source result set. Filters are applied by the native Search
    -- page after this function returns, so a pre-filter cap could make Members
    -- or Recipes appear incomplete even when matching records existed.
    self.runtime.globalSearchMetrics185.builds = (tonumber(self.runtime.globalSearchMetrics185.builds) or 0) + 1
    self.runtime.globalSearchResultCache185 = {
        query = query, rosterRevision = rosterRevision, dataRevision = dataRevision185,
        builtAt = now185, results = results,
    }
    return results
end

OTLGM:RegisterModule("Crafting", { layer = "feature", protocol = OTLGM.craftingProtocol })
