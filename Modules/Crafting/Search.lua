-- Bounded query cache for profession search. Recipe aggregation is one of the
-- larger local operations, so repeated redraws reuse the same immutable result
-- set until crafting data, roster freshness or a filter changes.

local PreviousGetCraftingSearchResults160 = OTLGM.__impl180.Stage_Quality156_GetCraftingSearchResults_3__impl1
local PreviousGetCraftingProfessionCounts160 = OTLGM.__impl180.Stage_Crafting_GetCraftingProfessionCounts_1__impl1
local PreviousOnCraftingDataChanged160 = OTLGM.__impl180.Stage_Systems152_OnCraftingDataChanged_2__impl1

local CACHE_LIMIT = 12
local CACHE_AGE = 45

local function EnsureSearchCache(self)
    self.runtime = self.runtime or {}
    if not self.runtime.craftingSearch then
        self.runtime.craftingSearch = { revision = 1, entries = {}, order = {}, hits = 0, builds = 0 }
    end
    return self.runtime.craftingSearch
end

local function CacheKey(self, query, professionFilter)
    local settings = OTLGM_DB and OTLGM_DB.settings or {}
    local activityTokenR46 = self.GetCraftingRosterActivityTokenR46 and self:GetCraftingRosterActivityTokenR46() or "legacy"
    return table.concat({
        self:NormalizeText(query or ""), tostring(professionFilter or "ALL"),
        self.craftingFilterContext153 and "FILTERED" or "BASE",
        tostring(settings.craftingCategory153 or "ALL"), tostring(settings.craftingLevelFilter153 or "ANY"),
        tostring(settings.craftingLevelBasis170 or "ITEM"), tostring(settings.craftingRarityFilter153 or "ANY"),
        tostring(settings.craftingSort153 or "ONLINE"), settings.craftingOnlineOnly153 and "ONLINE" or "ANY",
        settings.craftingFavoritesOnly170 and "FAVORITES" or "ALL_RECIPES",
        tostring(self.ui and self.ui.craftingCrafterFilterR42 or ""), tostring(activityTokenR46),
    }, "\031")
end

local function Put(cache, key, value, now)
    if not cache.entries[key] then table.insert(cache.order, key) end
    cache.entries[key] = { value = value, ts = now, revision = cache.revision }
    while table.getn(cache.order) > CACHE_LIMIT do
        local oldest = table.remove(cache.order, 1)
        cache.entries[oldest] = nil
    end
end

function OTLGM:InvalidateCraftingSearchCache()
    local cache = EnsureSearchCache(self)
    cache.revision = (tonumber(cache.revision) or 0) + 1
    cache.entries = {}
    cache.order = {}
end

local function FilterByCrafterR42(self, results)
    local wanted = self.ui and self.ui.craftingCrafterFilterR42 or nil
    wanted = wanted and self:NormalizeText(wanted) or ""
    if wanted == "" then return results end
    local filtered, index, crafterIndex, result, crafter = {}
    for index = 1, table.getn(results or {}) do
        result = results[index]
        for crafterIndex = 1, table.getn(result and result.crafters or {}) do
            crafter = result.crafters[crafterIndex]
            if self:NormalizeText(crafter and crafter.name or "") == wanted then
                table.insert(filtered, result)
                break
            end
        end
    end
    return filtered
end

function OTLGM:GetCraftingSearchResults(query, professionFilter)
    local cache = EnsureSearchCache(self)
    local key = CacheKey(self, query, professionFilter)
    local now = self:Now()
    local entry = cache.entries[key]
    if entry and entry.revision == cache.revision and now - (entry.ts or 0) <= CACHE_AGE then
        cache.hits = cache.hits + 1
        return entry.value
    end
    local results = FilterByCrafterR42(self, PreviousGetCraftingSearchResults160(self, query, professionFilter))
    cache.builds = cache.builds + 1
    Put(cache, key, results, now)
    return results
end

function OTLGM:GetCraftingProfessionCounts(query)
    local cache = EnsureSearchCache(self)
    local key = "COUNTS\031" .. CacheKey(self, query, "ALL")
    local now = self:Now()
    local entry = cache.entries[key]
    if entry and entry.revision == cache.revision and now - (entry.ts or 0) <= CACHE_AGE then
        cache.hits = cache.hits + 1
        return entry.value
    end
    local counts
    if self.ui and self.ui.craftingCrafterFilterR42 then
        counts = {}
        local results = self:GetCraftingSearchResults(query, "ALL")
        local index, result
        for index = 1, table.getn(results or {}) do
            result = results[index]
            counts[result.professionKey] = (tonumber(counts[result.professionKey]) or 0) + 1
            counts.ALL = (tonumber(counts.ALL) or 0) + 1
        end
    else
        counts = PreviousGetCraftingProfessionCounts160(self, query)
    end
    cache.builds = cache.builds + 1
    Put(cache, key, counts, now)
    return counts
end

function OTLGM:OnCraftingDataChanged(section, remote)
    if self.InvalidateCraftingDerivedCachesR46 then
        self:InvalidateCraftingDerivedCachesR46(section or "data", true)
    else
        self.runtime = self.runtime or {}
        self.runtime.craftingDataRevisionRC3 = (tonumber(self.runtime.craftingDataRevisionRC3) or 0) + 1
        self.runtime.craftingLastChangeAtRC3 = self:Now()
        if self.InvalidateCraftingAggregateIndexR30 then self:InvalidateCraftingAggregateIndexR30(section or "data") end
        self:InvalidateCraftingSearchCache()
        if self.InvalidateGlobalSearchCache185 then self:InvalidateGlobalSearchCache185("crafting") end
    end
    return PreviousOnCraftingDataChanged160(self, section, remote)
end

OTLGM:RegisterModule("CraftingSearch", {
    cacheLimit = CACHE_LIMIT,
    cacheAge = CACHE_AGE,
})
