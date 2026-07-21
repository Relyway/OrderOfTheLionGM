-- Bounded query cache for profession search. Recipe aggregation is one of the
-- larger local operations, so repeated redraws reuse the same immutable result
-- set until crafting data, roster freshness or a filter changes.

local BaseGetCraftingSearchResults160 = OTLGM._Stage_Quality156_GetCraftingSearchResults_3
local BaseGetCraftingProfessionCounts160 = OTLGM._Stage_Crafting_GetCraftingProfessionCounts_1
local BaseOnCraftingDataChanged160 = OTLGM._Stage_Systems152_OnCraftingDataChanged_2

local CACHE_LIMIT = 12
local CACHE_AGE = 10

local function EnsureSearchCache(self)
    self.runtime = self.runtime or {}
    if not self.runtime.craftingSearch then
        self.runtime.craftingSearch = { revision = 1, entries = {}, order = {}, hits = 0, builds = 0 }
    end
    return self.runtime.craftingSearch
end

local function CacheKey(self, query, professionFilter)
    local settings = OTLGM_DB and OTLGM_DB.settings or {}
    local db = self:GetGuildDB()
    return table.concat({
        self:NormalizeText(query or ""), tostring(professionFilter or "ALL"),
        self.craftingFilterContext153 and "FILTERED" or "BASE",
        tostring(settings.craftingCategory153 or "ALL"), tostring(settings.craftingLevelFilter153 or "ANY"),
        tostring(settings.craftingLevelBasis170 or "ITEM"), tostring(settings.craftingRarityFilter153 or "ANY"),
        tostring(settings.craftingSort153 or "ONLINE"), settings.craftingOnlineOnly153 and "ONLINE" or "ANY",
        settings.craftingFavoritesOnly170 and "FAVORITES" or "ALL_RECIPES", tostring(db and db.lastScan or 0),
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

function OTLGM:GetCraftingSearchResults(query, professionFilter)
    local cache = EnsureSearchCache(self)
    local key = CacheKey(self, query, professionFilter)
    local now = self:Now()
    local entry = cache.entries[key]
    if entry and entry.revision == cache.revision and now - (entry.ts or 0) <= CACHE_AGE then
        cache.hits = cache.hits + 1
        return entry.value
    end
    local results = BaseGetCraftingSearchResults160(self, query, professionFilter)
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
    local counts = BaseGetCraftingProfessionCounts160(self, query)
    cache.builds = cache.builds + 1
    Put(cache, key, counts, now)
    return counts
end

function OTLGM:OnCraftingDataChanged(section, remote)
    self:InvalidateCraftingSearchCache()
    return BaseOnCraftingDataChanged160(self, section, remote)
end

OTLGM:RegisterModule("CraftingSearch", {
    cacheLimit = CACHE_LIMIT,
    cacheAge = CACHE_AGE,
})
