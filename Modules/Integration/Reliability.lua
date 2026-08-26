-- Order of the Lion Guild Manager
-- Reliability, visual cleanup, raid priority and crafting manifest compatibility.

OTLGM.quality157Loaded = true

local PreviousEnsureDB157 = OTLGM.ApplySystemsDefaults
local PreviousEnsureCraftingDB157 = OTLGM.__impl180.Stage_Quality156_EnsureCraftingDB_2__impl1
local PreviousScanCurrentProfession157 = OTLGM.__impl180.Stage_Crafting_ScanCurrentProfession_1__impl1
local PreviousQueueCraftingProfessionShare157 = OTLGM.__impl180.Stage_Crafting_QueueCraftingProfessionShare_1__impl1
local PreviousApplyRemoteRecipeSnapshot157 = OTLGM.__impl180.Stage_Crafting_ApplyRemoteRecipeSnapshot155_1__impl1
local PreviousRequestCraftingSync157 = OTLGM.__impl180.Stage_Quality156_RequestCraftingSync_2__impl1
local PreviousProcessCraftingTimers157 = OTLGM.__impl180.Stage_Crafting_ProcessCraftingTimers_1__impl1
local PreviousHandleCommunityAddonMessage157 = OTLGM.__impl180.Stage_Crafting_HandleCommunityAddonMessage_1__impl1
local PreviousBuildNextProfessionsPage157 = OTLGM.__impl180.Stage_Quality156_BuildNextProfessionsPage_2__impl1
local PreviousRefreshCraftingRecipesPanel157 = OTLGM.__impl180.Stage_Quality156_RefreshCraftingRecipesPanel_3__impl1
local PreviousBuildPvePage157 = OTLGM.__impl180.Stage_Quality156_BuildPvePage_2__impl1
local PreviousRefreshPvePage157 = OTLGM.__impl180.Stage_Quality156_RefreshPvePage_3__impl1
local PreviousBuildRaidPlanner157 = OTLGM.BuildRaidPlanner156
local PreviousOpenRaidEditor157 = OTLGM.__impl180.Stage_Quality156_OpenRaidEditor156_1__impl1
local PreviousSerializePveRaid157 = OTLGM.__impl180.Stage_Quality156_SerializePveRaid_2__impl1
local PreviousApplyRemotePveRaid157 = OTLGM.__impl180.Stage_Quality156_ApplyRemotePveRaid_3__impl1
local PreviousHandlePveAddonMessage157 = OTLGM.__impl180.Stage_PVE_HandlePveAddonMessage_1__impl1
local PreviousQueuePveSyncResponse157 = OTLGM.__impl180.Stage_Quality156_QueuePveSyncResponse_2__impl1
local PreviousPublishPveRaidEvent157 = OTLGM.__impl180.Stage_Quality156_PublishPveRaidEvent156_1__impl1
local PreviousGetRaidList157 = OTLGM.__impl180.Stage_Quality156_GetRaidList156_1__impl1
local PreviousRefreshRaidPlanner157 = OTLGM.__impl180.Stage_Quality156_RefreshRaidPlanner156_1__impl1
local PreviousRefreshHomePveSummary157 = OTLGM.__impl180.Stage_UI_RefreshHomePveSummary155_1__impl1
local PreviousOpenAnnouncementComposer157 = OTLGM.__impl180.Stage_UI_OpenAnnouncementComposer152_1__impl1
local PreviousBuildActivityDialogs157 = OTLGM.__impl180.Stage_UINext_BuildActivityDialogs153_1__impl1
local PreviousGetActivityEntries157 = OTLGM.__impl180.Stage_UINext_GetActivityEntries153_1__impl1
local PreviousRefreshActivityDialog157 = OTLGM.__impl180.Stage_UINext_RefreshActivityDialog153_1__impl1
local PreviousOpenGuildChatNameMenu157 = OTLGM.__impl180.Stage_UI_OpenGuildChatNameMenu_1__impl1
local PreviousCloseTopModal157 = OTLGM.__impl180.Stage_UINext_CloseTopModal152_2__impl1
local PreviousBuildNextUI157 = OTLGM.__impl180.Stage_UINext_BuildNextUI_2__impl1
local PreviousSetCommunityReaction157 = OTLGM.__impl180.Stage_Crafting_SetCommunityReaction_1__impl1
local PreviousRefreshGuildChatPage157 = OTLGM.__impl180.Stage_Quality156_RefreshGuildChatPage_2__impl1
local PreviousGetDiagnosticsText157 = OTLGM.__impl180.Stage_Systems152_GetDiagnosticsText_2__impl1

local QUESTION_TEXTURE_157 = "Interface\\Icons\\INV_Misc_QuestionMark"
local MAIN_RAID_TEXTURE_157 = "Interface\\Icons\\INV_BannerPVP_02"
local NORMAL_RAID_TEXTURE_157 = "Interface\\Icons\\INV_Misc_Note_06"
local CANCELLED_RAID_TEXTURE_157 = "Interface\\Icons\\Ability_Creature_Cursed_05"

local function T157(text)
    text = tostring(text or "")
    text = string.gsub(text, "^%s*(.-)%s*$", "%1")
    return text
end

local function N157(text)
    text = string.lower(T157(text))
    text = string.gsub(text, "[%s%p%c]", "")
    return text
end

local function Split157(text, delimiter)
    local result = {}
    text = tostring(text or "")
    delimiter = delimiter or "^"
    local startAt = 1
    while true do
        local at = string.find(text, delimiter, startAt, true)
        if not at then table.insert(result, string.sub(text, startAt)) break end
        table.insert(result, string.sub(text, startAt, at - 1))
        startAt = at + string.len(delimiter)
    end
    return result
end

local function Escape157(text, maximum)
    text = tostring(text or "")
    text = string.gsub(text, "[\r\n\t]", " ")
    local parts, length = {}, 0
    local index, character, encoded
    for index = 1, string.len(text) do
        character = string.sub(text, index, index)
        if character == "%" then encoded = "%25"
        elseif character == "^" then encoded = "%5E"
        elseif character == "~" then encoded = "%7E"
        elseif character == "," then encoded = "%2C"
        else encoded = character end
        if maximum and length + string.len(encoded) > maximum then break end
        table.insert(parts, encoded)
        length = length + string.len(encoded)
    end
    return table.concat(parts)
end

local function Unescape157(text)
    text = tostring(text or "")
    text = string.gsub(text, "%%2C", ",")
    text = string.gsub(text, "%%7E", "~")
    text = string.gsub(text, "%%5E", "^")
    text = string.gsub(text, "%%25", "%%")
    return text
end

local function ParseItemID157(link)
    if not link then return 0 end
    local _, _, id = string.find(tostring(link), "item:(%d+)")
    return tonumber(id) or 0
end

local function ValidTexture157(texture)
    return texture ~= QUESTION_TEXTURE_157 and OTLGM:IsTextureReference(texture)
end

local function TextureValue157(texture)
    return texture
end

local function SetTextureSafe157(region, texture)
    if not region then return end
    if not ValidTexture157(texture) then texture = QUESTION_TEXTURE_157 end
    region:SetTexture(TextureValue157(texture))
    if region.SetVertexColor then region:SetVertexColor(1, 1, 1, 1) end
end

local function Count157(tbl)
    local count = 0
    local key
    for key in pairs(tbl or {}) do count = count + 1 end
    return count
end

local function ButtonText157(button, text)
    if not button then return end
    if button.text then button.text:SetText(text or "") end
    if button.label156 then button.label156:SetText(text or "") end
end

local function ButtonEnabled157(button, enabled, reason)
    if not button then return end
    button.disabledReason = reason
    OTLGM:SetControlEnabled170(button, enabled, reason)
    if button.label156 and OTLGM.ApplyQButton156 then OTLGM:ApplyQButton156(button) end
end

local function SetButtonSelected157(button, selected)
    if not button then return end
    button.selected156 = selected and true or false
    if OTLGM.ApplyQButton156 and button.label156 then OTLGM:ApplyQButton156(button) return end
    if button.SetBackdropColor then
        if selected then
            button:SetBackdropColor(0.16, 0.09, 0.02, 1)
            button:SetBackdropBorderColor(0.90, 0.58, 0.16, 1)
        else
            button:SetBackdropColor(0.018, 0.050, 0.085, 1)
            button:SetBackdropBorderColor(0.16, 0.42, 0.66, 1)
        end
    end
end

local function NewPanel157(parent, width, height)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame:SetBackdropColor(0.014, 0.013, 0.011, 1)
    frame:SetBackdropBorderColor(0.70, 0.45, 0.16, 1)
    if OTLGM.ApplyPanelSkin then OTLGM:ApplyPanelSkin(frame, "raised") end
    return frame
end

local function NewButton157(parent, text, x, y, width, height, callback)
    local button = CreateFrame("Button", nil, parent)
    OTLGM:PrepareInteractiveControl170(button, "button")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 9,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    button:SetBackdropColor(0.06, 0.025, 0.012, 1)
    button:SetBackdropBorderColor(0.52, 0.33, 0.12, 1)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.text:SetWidth(width - 8)
    button.text:SetText(text or "")
    button.actionStyle = "normal"
    button:SetScript("OnClick", callback)
    button:SetScript("OnEnter", function() this.hovered = true OTLGM:ApplyButtonSkin(this) end)
    button:SetScript("OnLeave", function() this.hovered = nil OTLGM:ApplyButtonSkin(this) if GameTooltip then GameTooltip:Hide() end end)
    if OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(button) end
    return button
end

local function NewText157(parent, template, text, x, y, width, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetWidth(width)
    fs:SetJustifyH(justify or "LEFT")
    fs:SetText(text or "")
    return fs
end

-- ---------------------------------------------------------------------------
-- Persistent, bounded crafting texture cache
-- ---------------------------------------------------------------------------

function OTLGM:EnsureCraftingIconCache157(craft)
    craft = craft or PreviousEnsureCraftingDB157(self)
    if not craft then return nil end
    craft.iconCache157 = craft.iconCache157 or { items = {}, names = {}, touched = self:Now() }
    craft.iconCache157.items = craft.iconCache157.items or {}
    craft.iconCache157.names = craft.iconCache157.names or {}
    return craft.iconCache157
end

local function SanitizeCraftingObject160(object)
    if type(object) ~= "table" then return false end
    local changed = false
    local equipLoc = object.equipLoc
    if not ValidTexture157(object.icon) then
        object.icon = nil
        if ValidTexture157(equipLoc) then object.icon = equipLoc end
        changed = true
    end
    if type(equipLoc) == "string" then
        local lower = string.lower(equipLoc)
        if string.find(lower, "interface\\", 1, true) == 1 or string.find(lower, "interface/", 1, true) == 1 then
            object.equipLoc = ""
            changed = true
        end
    end
    if object.itemSubType ~= nil and type(object.itemSubType) ~= "string" then
        object.itemSubType = ""
        changed = true
    end
    return changed
end

function OTLGM:RepairCraftingItemMetadata160(craft)
    craft = craft or PreviousEnsureCraftingDB157(self)
    if not craft or craft.itemInfoCompat160 == 2 then return false end
    local changed = false
    local characterName, character, professionKey, profession, recipeKey, recipe, index
    for characterName, character in pairs(craft.characters or {}) do
        if type(character) == "table" then
            for professionKey, profession in pairs(type(character.professions) == "table" and character.professions or {}) do
                if type(profession) == "table" then
                    for recipeKey, recipe in pairs(type(profession.recipes) == "table" and profession.recipes or {}) do
                        if type(recipe) == "table" then
                            if SanitizeCraftingObject160(recipe) then changed = true end
                            for index = 1, table.getn(recipe.reagents or {}) do
                                if SanitizeCraftingObject160(recipe.reagents[index]) then changed = true end
                            end
                        end
                    end
                end
            end
        end
    end
    local cache = self:EnsureCraftingIconCache157(craft)
    local key, entry
    for key, entry in pairs(cache and cache.items or {}) do
        if type(entry) ~= "table" or not ValidTexture157(entry.icon) then cache.items[key] = nil changed = true end
    end
    for key, entry in pairs(cache and cache.names or {}) do
        if type(entry) ~= "table" or not ValidTexture157(entry.icon) then cache.names[key] = nil changed = true end
    end
    craft.itemInfoCompat160 = 2
    return changed
end

function OTLGM:RememberCraftingIcon157(object, professionKey)
    if not object then return false end
    SanitizeCraftingObject160(object)
    local texture = object.icon
    if not ValidTexture157(texture) then return false end
    texture = TextureValue157(texture)
    object.icon = texture
    local craft = PreviousEnsureCraftingDB157(self)
    local cache = self:EnsureCraftingIconCache157(craft)
    if not cache then return false end
    local now = self:Now()
    local itemId = tonumber(object.itemId) or ParseItemID157(object.itemLink)
    if itemId > 0 then cache.items[tostring(itemId)] = { icon = texture, ts = now } end
    local nameKey = N157((professionKey or "") .. ":" .. (object.name or ""))
    if nameKey ~= "" then cache.names[nameKey] = { icon = texture, ts = now } end
    return true
end

function OTLGM:ResolveCraftingIcon157(object, professionKey)
    if not object then return QUESTION_TEXTURE_157 end
    SanitizeCraftingObject160(object)
    if ValidTexture157(object.icon) then
        self:RememberCraftingIcon157(object, professionKey)
        return object.icon
    end
    local craft = PreviousEnsureCraftingDB157(self)
    local cache = self:EnsureCraftingIconCache157(craft)
    local itemId = tonumber(object.itemId) or ParseItemID157(object.itemLink)
    local entry
    if cache and itemId > 0 then entry = cache.items[tostring(itemId)] end
    if not entry and cache then entry = cache.names[N157((professionKey or "") .. ":" .. (object.name or ""))] end
    if entry and ValidTexture157(entry.icon) then object.icon = entry.icon return entry.icon end
    if itemId > 0 and GetItemInfo then
        local _, link, quality, _, _, _, _, _, _, texture = self:GetItemInfoSafe(itemId)
        if link and not object.itemLink then object.itemLink = link end
        if quality ~= nil and object.quality == nil then object.quality = tonumber(quality) or 1 end
        if ValidTexture157(texture) then object.icon = texture self:RememberCraftingIcon157(object, professionKey) return texture end
    end
    return QUESTION_TEXTURE_157
end

local function CraftingHydrationObjectChanged180(beforeIcon, beforeLink, beforeQuality, object)
    return beforeIcon ~= object.icon or beforeLink ~= object.itemLink or beforeQuality ~= object.quality
end

local function HydrateCraftingObject180(owner, object, professionKey)
    if not object then return false end
    local beforeIcon, beforeLink, beforeQuality = object.icon, object.itemLink, object.quality
    local resolved = owner:ResolveCraftingIcon157(object, professionKey)
    local itemId = tonumber(object.itemId) or ParseItemID157(object.itemLink)
    if (not ValidTexture157(resolved) or not object.itemLink or object.itemLink == "") and itemId > 0 and owner.QueueCraftingCacheLookup then
        owner:QueueCraftingCacheLookup(itemId, object)
    end
    return CraftingHydrationObjectChanged180(beforeIcon, beforeLink, beforeQuality, object)
end

-- This helper is deliberately bounded by OBJECT count, not recipe count. A
-- recipe can contain many reagents, so the older implementation could perform
-- hundreds of GetItemInfo/cache operations in one frame even with a nominal
-- recipe budget. Long hydration is continued by ProcessCraftingIconHydration180.
function OTLGM:HydrateProfessionIcons157(profession, budget)
    if not profession then return false end
    budget = math.max(1, math.min(tonumber(budget) or 16, 24))
    local changed, used = false, 0
    local _, recipe, i
    for _, recipe in pairs(profession.recipes or {}) do
        if used >= budget then break end
        used = used + 1
        if HydrateCraftingObject180(self, recipe, profession.key) then changed = true end
        for i = 1, table.getn(recipe.reagents or {}) do
            if used >= budget then break end
            used = used + 1
            if HydrateCraftingObject180(self, recipe.reagents[i], profession.key) then changed = true end
        end
    end
    return changed
end

function OTLGM:QueueCraftingIconHydration180(ownerName, professionKey, profession, source)
    if type(profession) ~= "table" or type(profession.recipes) ~= "table" then return false end
    self.runtime = self.runtime or {}
    self.runtime.craftingIconHydration180 = self.runtime.craftingIconHydration180 or {}
    self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
    local jobs = self.runtime.craftingIconHydration180
    local key = N157(ownerName or "") .. ":" .. tostring(professionKey or profession.key or "")
    if key == ":" then return false end
    local existing = jobs[key]
    if existing and existing.profession == profession then
        if existing.source == "REMOTE" and source ~= "REMOTE" then existing.source = source end
        return true
    end
    local count = 0
    for _ in pairs(jobs) do count = count + 1 end
    if count >= 24 then
        local oldestKey, oldestAt
        local candidateKey, candidate
        for candidateKey, candidate in pairs(jobs) do
            local queuedAt = tonumber(candidate and candidate.queuedAt) or 0
            if not oldestAt or queuedAt < oldestAt then oldestKey, oldestAt = candidateKey, queuedAt end
        end
        if oldestKey then jobs[oldestKey] = nil end
    end
    local wasEmpty = next(jobs) == nil
    jobs[key] = {
        key = key,
        owner = ownerName,
        professionKey = professionKey or profession.key,
        profession = profession,
        source = source or "BACKGROUND",
        cursor = nil,
        activeRecipe = nil,
        reagentIndex = 0,
        changed = false,
        queuedAt = self:Now(),
        due = self:Now(),
    }
    local metrics = self.runtime.craftingMetrics180
    metrics.iconHydrationQueued = (tonumber(metrics.iconHydrationQueued) or 0) + 1
    if wasEmpty and self.WakeScheduler180 then self:WakeScheduler180("crafting-icon-hydration") end
    return true
end

function OTLGM:ProcessCraftingIconHydration180(maximumObjects)
    if self.InCombat and self:InCombat() then return false end
    self.runtime = self.runtime or {}
    local jobs = self.runtime.craftingIconHydration180 or {}
    self.runtime.craftingIconHydration180 = jobs
    self.runtime.craftingMetrics180 = self.runtime.craftingMetrics180 or {}
    local metrics = self.runtime.craftingMetrics180
    maximumObjects = math.max(1, math.min(tonumber(maximumObjects) or 20, 24))
    local jobKey, job = next(jobs)
    if not job then return false end
    local profession = job.profession
    if type(profession) ~= "table" or type(profession.recipes) ~= "table" then
        jobs[jobKey] = nil
        return false
    end

    local processed, finished = 0, false
    while processed < maximumObjects do
        if job.activeRecipe and job.reagentIndex > 0 and job.reagentIndex <= table.getn(job.activeRecipe.reagents or {}) then
            local reagent = job.activeRecipe.reagents[job.reagentIndex]
            job.reagentIndex = job.reagentIndex + 1
            processed = processed + 1
            if HydrateCraftingObject180(self, reagent, job.professionKey) then job.changed = true end
        else
            job.activeRecipe = nil
            job.reagentIndex = 0
            local recipeKey, recipe = next(profession.recipes, job.cursor)
            if not recipeKey then finished = true break end
            job.cursor = recipeKey
            job.activeRecipe = recipe
            job.reagentIndex = 1
            processed = processed + 1
            if HydrateCraftingObject180(self, recipe, job.professionKey) then job.changed = true end
        end
    end

    metrics.iconHydrationSlices = (tonumber(metrics.iconHydrationSlices) or 0) + 1
    metrics.iconHydrationObjects = (tonumber(metrics.iconHydrationObjects) or 0) + processed
    if finished then
        jobs[jobKey] = nil
        metrics.iconHydrationCompleted = (tonumber(metrics.iconHydrationCompleted) or 0) + 1
        if job.changed then
            metrics.iconHydrationChanged = (tonumber(metrics.iconHydrationChanged) or 0) + 1
            profession.iconRevision157 = (tonumber(profession.iconRevision157) or 0) + 1
            profession.lastSharedAt = 0
            if self.RehashCraftingProfession then self:RehashCraftingProfession(profession) end
            if job.source ~= "REMOTE" and self.QueueCraftingChangeManifest157 then
                self:QueueCraftingChangeManifest157(job.owner, job.professionKey)
            end
            if self.ui and self.ui.main and self.ui.main:IsVisible() and self.ui.currentPage == "professions" and self.RefreshProfessionsPage then
                self:RefreshProfessionsPage()
            elseif self.ui then
                self.ui.pageDirty = self.ui.pageDirty or {}
                self.ui.pageDirty.professions = true
            end
        end
    else
        job.due = self:Now()
    end
    return processed > 0
end

function OTLGM:PruneCraftingIconCache157()
    local craft = PreviousEnsureCraftingDB157(self)
    local cache = self:EnsureCraftingIconCache157(craft)
    if not cache then return end
    local now = self:Now()
    local limitAge = 120 * 86400
    local key, entry
    for key, entry in pairs(cache.items or {}) do if not entry.ts or entry.ts < now - limitAge then cache.items[key] = nil end end
    for key, entry in pairs(cache.names or {}) do if not entry.ts or entry.ts < now - limitAge then cache.names[key] = nil end end

    -- Recipe objects keep their own texture. These limits only bound the extra
    -- fallback index, so old visible recipe icons are never removed from data.
    local function TrimOldest(tbl, maximum)
        local rows = {}
        local k, v, i
        for k, v in pairs(tbl or {}) do table.insert(rows, { key = k, ts = tonumber(v.ts) or 0 }) end
        if table.getn(rows) <= maximum then return end
        table.sort(rows, function(a, b) return a.ts < b.ts end)
        for i = 1, table.getn(rows) - maximum do tbl[rows[i].key] = nil end
    end
    TrimOldest(cache.items, 2000)
    TrimOldest(cache.names, 2500)
    cache.touched = now
end

function OTLGM:EnsureCraftingDB()
    local craft = PreviousEnsureCraftingDB157(self)
    if craft then
        self:EnsureCraftingIconCache157(craft)
        self:RepairCraftingItemMetadata160(craft)
    end
    return craft
end

local function SnapshotOldIcons157(profession)
    local map = {}
    local key, recipe, i, reagent
    for key, recipe in pairs(profession and profession.recipes or {}) do
        map[key] = {
            icon = recipe.icon, quality = recipe.quality, itemLevel = recipe.itemLevel, requiredLevel = recipe.requiredLevel,
            itemType = recipe.itemType, itemSubType = recipe.itemSubType, equipLoc = recipe.equipLoc,
            itemLink = recipe.itemLink, recipeLink = recipe.recipeLink, effectText = recipe.effectText,
            effectSource183 = recipe.effectSource183, effectChecked = recipe.effectChecked,
            requiredSkill = recipe.requiredSkill, requirementText = recipe.requirementText,
            requirementChecked = recipe.requirementChecked, detailKey = recipe.detailKey, detailHash = recipe.detailHash,
            materialsStatus = recipe.materialsStatus, materialsAvailable = recipe.materialsAvailable,
            reagents = {}, reagentList = {},
        }
        for i = 1, table.getn(recipe.reagents or {}) do
            reagent = recipe.reagents[i]
            local storedReagent = {
                itemId = reagent.itemId, name = reagent.name, count = reagent.count, owned = reagent.owned,
                icon = reagent.icon, itemLink = reagent.itemLink, quality = reagent.quality,
            }
            map[key].reagents[N157((reagent.itemId or 0) .. ":" .. (reagent.name or ""))] = storedReagent
            table.insert(map[key].reagentList, storedReagent)
        end
    end
    return map
end

function OTLGM:CaptureOpenProfessionIcons157(mode)
    local rawName, count, isCraft = nil, 0, mode == "CRAFT"
    if isCraft then
        if not GetCraftName or not GetNumCrafts or not GetCraftInfo then return false end
        rawName = GetCraftName()
        count = tonumber(GetNumCrafts()) or 0
    else
        if not GetTradeSkillLine or not GetNumTradeSkills or not GetTradeSkillInfo then return false end
        rawName = GetTradeSkillLine()
        count = tonumber(GetNumTradeSkills()) or 0
    end
    local professionKey = self.NormalizeProfessionKey156 and self:NormalizeProfessionKey156(rawName, rawName) or string.upper(rawName or "")
    local craft = PreviousEnsureCraftingDB157(self)
    local player = string.gsub(UnitName("player") or "Unknown", "%-.*$", "")
    local character = craft and craft.characters and craft.characters[player]
    local profession = character and character.professions and character.professions[professionKey]
    if not profession then return false end
    local changed = false
    local index
    for index = 1, count do
        local name, recipeType
        if isCraft then name, _, recipeType = GetCraftInfo(index) else name, recipeType = GetTradeSkillInfo(index) end
        if name and recipeType ~= "header" then
            local link, icon
            if isCraft then
                if GetCraftItemLink then link = GetCraftItemLink(index) end
                if GetCraftIcon then icon = GetCraftIcon(index) end
            else
                if GetTradeSkillItemLink then link = GetTradeSkillItemLink(index) end
                if GetTradeSkillIcon then icon = GetTradeSkillIcon(index) end
            end
            local itemId = ParseItemID157(link)
            local recipeKey = itemId > 0 and tostring(itemId) or N157(name)
            local recipe = profession.recipes and profession.recipes[recipeKey]
            if not recipe then
                local candidateKey, candidate
                for candidateKey, candidate in pairs(profession.recipes or {}) do if N157(candidate.name) == N157(name) then recipe = candidate break end end
            end
            if recipe then
                if not ValidTexture157(icon) and itemId > 0 and GetItemInfo then local _, _, _, _, _, _, _, _, _, cached = self:GetItemInfoSafe(itemId) icon = cached end
                if ValidTexture157(icon) and recipe.icon ~= icon then recipe.icon = icon changed = true end
                self:RememberCraftingIcon157(recipe, professionKey)
                local reagentCount = 0
                if isCraft and GetCraftNumReagents then reagentCount = tonumber(GetCraftNumReagents(index)) or 0
                elseif not isCraft and GetTradeSkillNumReagents then reagentCount = tonumber(GetTradeSkillNumReagents(index)) or 0 end
                local ri
                for ri = 1, reagentCount do
                    local reagentName, reagentIcon, _, _, reagentLink
                    if isCraft then
                        if GetCraftReagentInfo then reagentName, reagentIcon = GetCraftReagentInfo(index, ri) end
                        if GetCraftReagentItemLink then reagentLink = GetCraftReagentItemLink(index, ri) end
                    else
                        if GetTradeSkillReagentInfo then reagentName, reagentIcon = GetTradeSkillReagentInfo(index, ri) end
                        if GetTradeSkillReagentItemLink then reagentLink = GetTradeSkillReagentItemLink(index, ri) end
                    end
                    local reagentId = ParseItemID157(reagentLink)
                    local stored = recipe.reagents and recipe.reagents[ri]
                    if not stored and recipe.reagents then
                        local sj
                        for sj = 1, table.getn(recipe.reagents) do if N157(recipe.reagents[sj].name) == N157(reagentName) then stored = recipe.reagents[sj] break end end
                    end
                    if stored then
                        if not ValidTexture157(reagentIcon) and reagentId > 0 and GetItemInfo then local _, _, _, _, _, _, _, _, _, cached = self:GetItemInfoSafe(reagentId) reagentIcon = cached end
                        if ValidTexture157(reagentIcon) and stored.icon ~= reagentIcon then stored.icon = reagentIcon changed = true end
                        self:RememberCraftingIcon157(stored, professionKey)
                    end
                end
            end
        end
    end
    if changed then profession.iconRevision157 = (tonumber(profession.iconRevision157) or 0) + 1 profession.lastSharedAt = 0 end
    return changed
end

function OTLGM.__impl180.ScanCurrentProfession__impl1(self, mode, attempt)
    local rawName
    if mode == "CRAFT" and GetCraftName then rawName = GetCraftName()
    elseif mode ~= "CRAFT" and GetTradeSkillLine then rawName = GetTradeSkillLine() end
    local professionKey = self.NormalizeProfessionKey156 and self:NormalizeProfessionKey156(rawName, rawName) or string.upper(rawName or "")
    local craftBefore = PreviousEnsureCraftingDB157(self)
    local player = string.gsub(UnitName("player") or "Unknown", "%-.*$", "")
    local oldProfession = craftBefore and craftBefore.characters and craftBefore.characters[player] and craftBefore.characters[player].professions and craftBefore.characters[player].professions[professionKey]
    local oldIcons = SnapshotOldIcons157(oldProfession)
    local ok, changed = PreviousScanCurrentProfession157(self, mode, attempt)
    local craft = PreviousEnsureCraftingDB157(self)
    local profession = craft and craft.characters and craft.characters[player] and craft.characters[player].professions and craft.characters[player].professions[professionKey]
    local restored = false
    if profession then
        local key, recipe, stored, i, reagent, oldReagent, detail
        for key, recipe in pairs(profession.recipes or {}) do
            stored = oldIcons[key]
            if stored and not ValidTexture157(recipe.icon) and ValidTexture157(stored.icon) then recipe.icon = stored.icon restored = true end
            if stored then
                if (tonumber(recipe.quality) or 0) <= 1 and (tonumber(stored.quality) or 0) > 1 then recipe.quality = stored.quality restored = true end
                if (tonumber(recipe.itemLevel) or 0) <= 0 and (tonumber(stored.itemLevel) or 0) > 0 then recipe.itemLevel = stored.itemLevel restored = true end
                if (tonumber(recipe.requiredLevel) or 0) <= 0 and (tonumber(stored.requiredLevel) or 0) > 0 then recipe.requiredLevel = stored.requiredLevel restored = true end
                if (tonumber(recipe.requiredSkill) or 0) <= 0 and (tonumber(stored.requiredSkill) or 0) > 0 then recipe.requiredSkill = stored.requiredSkill restored = true end
                if (not recipe.itemType or recipe.itemType == "") and stored.itemType and stored.itemType ~= "" then recipe.itemType = stored.itemType restored = true end
                if (not recipe.itemSubType or recipe.itemSubType == "") and stored.itemSubType and stored.itemSubType ~= "" then recipe.itemSubType = stored.itemSubType restored = true end
                if (not recipe.equipLoc or recipe.equipLoc == "") and stored.equipLoc and stored.equipLoc ~= "" then recipe.equipLoc = stored.equipLoc restored = true end
                if (not recipe.itemLink or recipe.itemLink == "") and stored.itemLink and stored.itemLink ~= "" then recipe.itemLink = stored.itemLink restored = true end
                if (not recipe.recipeLink or recipe.recipeLink == "") and stored.recipeLink and stored.recipeLink ~= "" then recipe.recipeLink = stored.recipeLink restored = true end
                if (not recipe.effectText or recipe.effectText == "") and stored.effectText and stored.effectText ~= "" then
                    local derivedStoredEffectR24 = self.IsDerivedEnchantEffect183 and self:IsDerivedEnchantEffect183(recipe, stored.effectText)
                    local restoredEffectSourceR24 = tostring(stored.effectSource183 or recipe.effectSource183 or "")
                    if restoredEffectSourceR24 == "" then restoredEffectSourceR24 = "LEGACY_NATIVE" end
                    if self.NormalizeEnchantEffectSourceR24 then restoredEffectSourceR24 = self:NormalizeEnchantEffectSourceR24(restoredEffectSourceR24) end
                    local trustedStoredEffectR24 = self.IsTrustedEnchantEffectSourceR24 and self:IsTrustedEnchantEffectSourceR24(restoredEffectSourceR24)
                    if not derivedStoredEffectR24 and trustedStoredEffectR24 then
                        recipe.effectText = stored.effectText
                        recipe.effectSource183 = restoredEffectSourceR24
                        recipe.effectChecked = stored.effectChecked and true or recipe.effectChecked
                        restored = true
                    end
                end
                if (not recipe.requirementText or recipe.requirementText == "") and stored.requirementText and stored.requirementText ~= "" then recipe.requirementText = stored.requirementText restored = true end
                if stored.requirementChecked then recipe.requirementChecked = true end
                if stored.detailKey then recipe.detailKey = stored.detailKey end
                if stored.detailHash then recipe.detailHash = stored.detailHash end

                -- A profession window can expose recipe names one frame before
                -- reagent rows. Never replace a previously complete material
                -- list with that temporary empty/partial view.
                if recipe.materialsStatus ~= "COMPLETE" and stored.materialsStatus == "COMPLETE" and table.getn(stored.reagentList or {}) > 0 then
                    recipe.reagents = {}
                    for i = 1, table.getn(stored.reagentList) do
                        oldReagent = stored.reagentList[i]
                        table.insert(recipe.reagents, {
                            itemId = oldReagent.itemId, name = oldReagent.name, count = oldReagent.count, owned = oldReagent.owned,
                            icon = oldReagent.icon, itemLink = oldReagent.itemLink, quality = oldReagent.quality,
                        })
                    end
                    recipe.materialsStatus = "COMPLETE"
                    recipe.materialsAvailable = stored.materialsAvailable == nil and true or (stored.materialsAvailable and true or false)
                    restored = true
                end
            end
            for i = 1, table.getn(recipe.reagents or {}) do
                reagent = recipe.reagents[i]
                oldReagent = stored and stored.reagents[N157((reagent.itemId or 0) .. ":" .. (reagent.name or ""))]
                if oldReagent then
                    if not ValidTexture157(reagent.icon) and ValidTexture157(oldReagent.icon) then reagent.icon = oldReagent.icon restored = true end
                    if (not reagent.itemLink or reagent.itemLink == "") and oldReagent.itemLink and oldReagent.itemLink ~= "" then reagent.itemLink = oldReagent.itemLink restored = true end
                    if (tonumber(reagent.quality) or 0) <= 1 and (tonumber(oldReagent.quality) or 0) > 1 then reagent.quality = oldReagent.quality restored = true end
                end
            end
            detail = self.GetCraftingDetail and self:GetCraftingDetail(recipe, professionKey) or nil
            if detail then
                if (tonumber(recipe.requiredSkill) or 0) <= 0 and (tonumber(detail.requiredSkill) or 0) > 0 then recipe.requiredSkill = detail.requiredSkill restored = true end
                if (not recipe.requirementText or recipe.requirementText == "") and detail.requirementText and detail.requirementText ~= "" then recipe.requirementText = detail.requirementText restored = true end
                if (not recipe.effectText or recipe.effectText == "") and detail.effectText and detail.effectText ~= "" then
                    local derivedEffect = self.IsDerivedEnchantEffect183 and self:IsDerivedEnchantEffect183(recipe, detail.effectText)
                    local detailEffectSourceR24 = tostring(detail.effectSource183 or recipe.effectSource183 or "")
                    if detailEffectSourceR24 == "" then detailEffectSourceR24 = "LEGACY_NATIVE" end
                    if self.NormalizeEnchantEffectSourceR24 then detailEffectSourceR24 = self:NormalizeEnchantEffectSourceR24(detailEffectSourceR24) end
                    local trustedDetailEffectR24 = self.IsTrustedEnchantEffectSourceR24 and self:IsTrustedEnchantEffectSourceR24(detailEffectSourceR24)
                    if not derivedEffect and trustedDetailEffectR24 then
                        recipe.effectText = detail.effectText
                        recipe.effectSource183 = detailEffectSourceR24
                        recipe.effectChecked = detail.effectChecked and true or recipe.effectChecked
                        restored = true
                    end
                end
                if detail.requirementChecked then recipe.requirementChecked = true end
                if detail.personalOnlyR27 then
                    recipe.personalOnlyR27 = true
                    recipe.personalReasonR27 = detail.personalReasonR27 or "BOP_OUTPUT"
                    restored = true
                end
                recipe.detailKey = detail.key or recipe.detailKey
                recipe.detailHash = detail.detailHash or recipe.detailHash
            end
        end
        if self:CaptureOpenProfessionIcons157(mode) then restored = true end
        if self:HydrateProfessionIcons157(profession, 16) then restored = true end
        self:QueueCraftingIconHydration180(player, professionKey, profession, "LOCAL")
        if restored then
            profession.iconRevision157 = (tonumber(profession.iconRevision157) or 0) + 1
            profession.lastSharedAt = 0
            if self.RehashCraftingProfession then self:RehashCraftingProfession(profession) end
            self:QueueCraftingProfessionShare(player, professionKey)
        end
        if self.QueueOpenProfessionDetails then self:QueueOpenProfessionDetails(mode, profession) end
        if mode ~= "CRAFT" and self.InstallEnchantingSelectionCaptureR24 then self:InstallEnchantingSelectionCaptureR24() end
        if professionKey == "ENCHANTING" and self.ScheduleSelectedTradeSkillNativeProbeR24 then
            self:ScheduleSelectedTradeSkillNativeProbeR24("profession-scan")
        end
    end
    return ok, changed
end

function OTLGM:QueueCraftingProfessionShare(ownerName, professionKey, target)
    local craft = PreviousEnsureCraftingDB157(self)
    local character = craft and craft.characters and craft.characters[ownerName]
    local profession = character and character.professions and character.professions[professionKey]
    if not character or not profession then return false end
    local localOwner = character.localOwner or profession.localOwner
    if character.localOwner and not profession.localOwner then profession.localOwner = true localOwner = true end
    if target and not localOwner then
        -- R26: do not relay another player's cached full profession. Relaying
        -- cached guild state made four SYNC peers multiply into dozens of
        -- transfers/chunks. The actual owner (including this account's offline
        -- alts, which remain localOwner) is authoritative for full snapshots.
        self.runtime = self.runtime or {}
        self.runtime.craftingRemoteRelayBlockedR26 = (tonumber(self.runtime.craftingRemoteRelayBlockedR26) or 0) + 1
        return false
    end
    self:HydrateProfessionIcons157(profession, 6)
    self:QueueCraftingIconHydration180(ownerName, professionKey, profession, "SHARE")
    if not target then return self:QueueCraftingChangeManifest157(ownerName, professionKey) end
    return PreviousQueueCraftingProfessionShare157(self, ownerName, professionKey, target, false)
end

function OTLGM:ApplyRemoteRecipeSnapshot155(fields, sender, channel)
    local result = PreviousApplyRemoteRecipeSnapshot157(self, fields, sender, channel)
    if result then
        local owner = string.gsub(Unescape157(fields[3] or ""), "%-.*$", "")
        local professionKey = fields[4] or ""
        local craft = PreviousEnsureCraftingDB157(self)
        local profession = craft and craft.characters and craft.characters[owner] and craft.characters[owner].professions and craft.characters[owner].professions[professionKey]
        if profession then
            self:HydrateProfessionIcons157(profession, 12)
            self:QueueCraftingIconHydration180(owner, professionKey, profession, "REMOTE")
        end
        if craft and craft.syncState then
            craft.syncState.wanted157 = craft.syncState.wanted157 or {}
            local wantedKey = N157(owner) .. ":" .. professionKey
            local wanted = craft.syncState.wanted157[wantedKey]
            local pendingKey = "RC3:" .. N157(sender) .. ":" .. N157(owner) .. ":" .. professionKey .. ":" .. tostring(tonumber(fields[5]) or 0) .. ":" .. tostring(fields[11] or "0")
            if craft.pendingRecipes and craft.pendingRecipes[pendingKey] then
                -- A successful RC3 call can mean "this fragment was stored".
                -- Keep the authorization alive until the complete snapshot has
                -- been assembled; otherwise relayed offline-alt professions
                -- lose every fragment after the first one.
                if wanted then wanted.lastProgress = self:Now() end
            else
                craft.syncState.wanted157[wantedKey] = nil
            end
        end
    end
    return result
end

-- ---------------------------------------------------------------------------
-- Manifest-based crafting sync. Only changed professions transfer full data.
-- R26 manifests/full snapshots are authoritative local-owner data only; cached
-- remote professions remain useful for display but are not re-broadcast as owners.
-- ---------------------------------------------------------------------------

local function ProfessionCompleteness157(profession)
    local recipeCount, iconCount, materialCount = 0, 0, 0
    local key, recipe, i, allIcons
    for key, recipe in pairs(profession and profession.recipes or {}) do
        if not (OTLGM.IsShareableCraftingRecipeR27 and not OTLGM:IsShareableCraftingRecipeR27(recipe)) then
            recipeCount = recipeCount + 1
            if ValidTexture157(recipe.icon) then iconCount = iconCount + 1 end
            allIcons = true
            for i = 1, table.getn(recipe.reagents or {}) do if not ValidTexture157(recipe.reagents[i].icon) then allIcons = false break end end
            if (recipe.materialsStatus == "COMPLETE" or recipe.materialsAvailable) and allIcons then materialCount = materialCount + 1 end
        end
    end
    return recipeCount, iconCount, materialCount
end

function OTLGM:QueueCraftingChangeManifest157(ownerName, professionKey)
    local craft = PreviousEnsureCraftingDB157(self)
    local character = craft and craft.characters and craft.characters[ownerName]
    local profession = character and character.professions and character.professions[professionKey]
    if not profession or not profession.localOwner then return false end
    local now = self:Now()
    if profession.lastSharedAt and now - profession.lastSharedAt < self.craftingShareCooldown then return false end
    if profession.hashDirty184 and self.RehashCraftingProfession then
        self:RehashCraftingProfession(profession)
        profession.hashDirty184 = nil
    end
    local count, iconCount, materialCount = ProfessionCompleteness157(profession)
    local entry = table.concat({
        Escape157(ownerName, 36), Escape157(professionKey, 20), tostring(tonumber(profession.ts) or now),
        tostring(count), Escape157(profession.hash or "0", 20), tostring(iconCount), tostring(materialCount)
    }, ",")
    profession.lastSharedAt = now
    return self:QueueNetworkPayload("C1^CCHG^" .. entry, "GUILD", nil, 2, "crafting-change", "craft:" .. self:NormalizeName(ownerName) .. ":" .. professionKey)
end

function OTLGM:QueueCraftingManifest157(target)
    local craft = PreviousEnsureCraftingDB157(self)
    if not craft or not target or target == "" then return false end
    local networkLimit = self.GetNetworkPayloadLimit and self:GetNetworkPayloadLimit("WHISPER", target) or 250
    if networkLimit < string.len("C1^CMEND") then return false end
    local entries = {}
    local owner, character, professionKey, profession
    for owner, character in pairs(craft.characters or {}) do
        if type(character) == "table" then
            for professionKey, profession in pairs(character.professions or {}) do
                if character.localOwner or (type(profession) == "table" and profession.localOwner) then
                    if character.localOwner and not profession.localOwner then profession.localOwner = true end
                    local count, iconCount, materialCount = ProfessionCompleteness157(profession)
                    if count > 0 then
                        table.insert(entries, table.concat({ Escape157(owner, 36), Escape157(professionKey, 20), tostring(tonumber(profession.ts) or 0), tostring(count), Escape157(profession.hash or "0", 20), tostring(iconCount), tostring(materialCount) }, ","))
                    end
                end
            end
        end
    end
    self.runtime = self.runtime or {}
    self.runtime.craftingLocalManifestEntriesR26 = table.getn(entries)
    table.sort(entries)
    local packet = ""
    local i, candidate
    for i = 1, table.getn(entries) do
        candidate = packet == "" and entries[i] or (packet .. "~" .. entries[i])
        if string.len("C1^CMAN^" .. candidate) > networkLimit then
            if packet == "" or not self:QueueCommunityPayload("C1^CMAN^" .. packet, "WHISPER", target, 2) then return false end
            packet = entries[i]
            if string.len("C1^CMAN^" .. packet) > networkLimit then return false end
        else packet = candidate end
    end
    if packet ~= "" and not self:QueueCommunityPayload("C1^CMAN^" .. packet, "WHISPER", target, 2) then return false end
    return self:QueueCommunityPayload("C1^CMEND", "WHISPER", target, 2)
end


local MAX_CRAFTING_WANTED_R2 = 6
local MAX_CRAFTING_OUTBOUND_R2 = 6

function OTLGM:GetDetectedPeerInfoR2(name)
    if not name or name == "" then return nil end
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local wanted = N157(name)
    local storedName, info
    for storedName, info in pairs(db and db.detectedVersions or {}) do
        if N157(storedName) == wanted then return type(info) == "table" and info or nil end
    end
    return nil
end

function OTLGM:IsModernSyncVersionR2(version)
    version = tostring(version or "")
    local major, minor, patch = 0, 0, 0
    if self.VersionParts then major, minor, patch = self:VersionParts(version) end
    major, minor, patch = tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
    if major > 1 then return true end
    if major < 1 or minor < 8 then return false end
    if minor > 8 or patch > 0 then return true end
    -- 1.8.0 release candidates use the explicit-session transfer contract.
    local _, _, rc = string.find(version, "%-rc(%d+)")
    if rc then return (tonumber(rc) or 0) >= 5 end
    -- A plain 1.8.0 is the final release and therefore compatible.
    if version == "1.8.0" then return true end
    return false
end

function OTLGM:IsModernSyncPeerR2(name, advertisedVersion)
    if N157(name) == N157(UnitName("player") or "") then return true end
    if advertisedVersion and advertisedVersion ~= "" and self:IsModernSyncVersionR2(advertisedVersion) then return true end
    local info = self:GetDetectedPeerInfoR2(name)
    return info and self:IsModernSyncVersionR2(info.version) and true or false
end

function OTLGM:GetCompatibleSyncPeersR2(maxAge)
    local peers, seen = {}, {}
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local now = self:Now()
    maxAge = math.max(30, tonumber(maxAge) or 360)
    local storedName, info
    for storedName, info in pairs(db and db.detectedVersions or {}) do
        if type(info) == "table" and now - (tonumber(info.ts) or 0) <= maxAge and self:IsModernSyncVersionR2(info.version) then
            local name = string.gsub(tostring(info.sender or storedName), "%-.*$", "")
            local key = N157(name)
            if key ~= "" and key ~= N157(UnitName("player") or "") and not seen[key] then
                local member = self.GetMember and self:GetMember(name) or nil
                if not member or member.online ~= false then
                    seen[key] = true
                    table.insert(peers, name)
                end
            end
        end
    end
    table.sort(peers)
    return peers
end

function OTLGM:HasCompatibleSyncPeerR2()
    return table.getn(self:GetCompatibleSyncPeersR2(360)) > 0
end

local function QueueWantedCraftingR2(self, state, key, wanted)
    if not state or not wanted or not wanted.sender then return false end
    state.wanted157 = state.wanted157 or {}
    if Count157(state.wanted157) >= MAX_CRAFTING_WANTED_R2 then return false end
    local now = self:Now()
    wanted.ts = now
    wanted.createdAt = wanted.createdAt or now
    wanted.lastProgress = now
    wanted.tries = tonumber(wanted.tries) or 1
    state.wanted157[key] = wanted
    if self.RegisterExpectedCraftingTransfer180 then self:RegisterExpectedCraftingTransfer180(wanted.sender, wanted.owner, wanted.professionKey, wanted.hash or "0", 120) end
    return self:QueueCommunityPayload(table.concat({ "C1", "CWANT", Escape157(wanted.owner, 36), Escape157(wanted.professionKey, 20), Escape157(wanted.hash or "0", 20) }, "^"), "WHISPER", wanted.sender, 1)
end

local function FillDeferredCraftingR2(self, state)
    if not state then return 0 end
    state.deferred157 = state.deferred157 or {}
    local moved = 0
    while Count157(state.wanted157 or {}) < MAX_CRAFTING_WANTED_R2 do
        local bestKey, best
        local key, candidate
        for key, candidate in pairs(state.deferred157) do
            if candidate and (not best or (tonumber(candidate.score) or 0) > (tonumber(best.score) or 0)) then bestKey, best = key, candidate end
        end
        if not bestKey then break end
        state.deferred157[bestKey] = nil
        if QueueWantedCraftingR2(self, state, bestKey, best) then moved = moved + 1 end
    end
    return moved
end

function OTLGM:ScheduleCraftingManifest157(target)
    if not target or target == "" or N157(target) == N157(UnitName("player") or "") then return false end
    if self.IsModernSyncPeerR2 and not self:IsModernSyncPeerR2(target) then return false end
    self.craftingManifestTargets157 = self.craftingManifestTargets157 or {}
    local name = UnitName("player") or "Player"
    local score = 0
    local index
    for index = 1, string.len(name) do score = score + string.byte(name, index) end
    local key = N157(target)
    local due = self:Now() + 1 + math.mod(score, 5)
    local old = self.craftingManifestTargets157[key]
    if not old or due < (old.due or due) then self.craftingManifestTargets157[key] = { name = target, due = due } end
    if self.WakeScheduler180 then self:WakeScheduler180("crafting-manifest") end
    return true
end

local function OrderedCraftingPeersR26(self, peers)
    local ordered = {}
    local count = table.getn(peers or {})
    if count <= 0 then return ordered end
    self.runtime = self.runtime or {}
    local cursor = tonumber(self.runtime.craftingPeerCursorR26) or 0
    local start = math.mod(cursor, count) + 1
    local offset, index
    for offset = 0, count - 1 do
        index = math.mod((start - 1) + offset, count) + 1
        table.insert(ordered, peers[index])
    end
    return ordered
end

local function QueueNextCraftingPeerR26(self, craft, now)
    local state = craft and craft.syncState
    if not state or not state.active then return false end
    local candidates = state.peerCandidatesR26 or {}
    local limit = math.min(tonumber(state.peerLimitR26) or 1, table.getn(candidates))
    local index = (tonumber(state.peerIndexR26) or 0) + 1
    if index > limit then return false end
    local target = candidates[index]
    if not target or target == "" then return false end
    if not self:QueueCommunityPayload("C1^SYNC157^" .. tostring(self.version), "WHISPER", target, 2, "crafting:manifest-sync:" .. N157(target)) then
        return false
    end
    state.peerIndexR26 = index
    state.peerAttemptsR26 = (tonumber(state.peerAttemptsR26) or 0) + 1
    state.lastPeerAttemptAtR26 = now
    state.currentPeerR26 = target
    state.peerAttemptedKeysR26 = state.peerAttemptedKeysR26 or {}
    state.peerAttemptedKeysR26[N157(target)] = true
    self.runtime = self.runtime or {}
    self.runtime.craftingSyncPeerAttemptsR26 = (tonumber(self.runtime.craftingSyncPeerAttemptsR26) or 0) + 1
    self.runtime.craftingPeerCursorR26 = math.mod((tonumber(self.runtime.craftingPeerCursorR26) or 0) + 1, math.max(1, table.getn(candidates)))
    return true
end

function OTLGM.__impl180.RequestCraftingSync__impl1(self, force, manual)
    local craft = PreviousEnsureCraftingDB157(self)
    if not craft or not SendAddonMessage or not GetGuildInfo("player") then return false end
    local now = self:Now()
    self.runtime = self.runtime or {}
    manual = manual and self.ui and self.ui.currentPage == "professions" and true or false
    if craft.syncState and craft.syncState.active then
        self.runtime.craftingSyncCoalesced180 = (tonumber(self.runtime.craftingSyncCoalesced180) or 0) + 1
        return false
    end
    -- R26: passive/page-open recovery is deliberately coarse. Live CCHG
    -- broadcasts remain immediate, while repeated full recovery scans no longer
    -- re-fan-out every 90/180 seconds. Manual force still bypasses this gate.
    if not force and craft.lastSync and now - craft.lastSync < 300 then return false end
    local peers = self.GetCompatibleSyncPeersR2 and self:GetCompatibleSyncPeersR2(360) or {}
    if table.getn(peers) == 0 then
        self.runtime.craftingNoCompatiblePeerR2 = (tonumber(self.runtime.craftingNoCompatiblePeerR2) or 0) + 1
        if manual and self.SetStatus then self:SetStatus("No compatible guildmate with profession sharing is online yet. Saved recipes were kept.", nil, { source = "crafting", manual = true }) end
        return false
    end
    local ordered = OrderedCraftingPeersR26(self, peers)
    local peerLimit = manual and math.min(3, table.getn(ordered)) or math.min(2, table.getn(ordered))
    craft.syncState = {
        active = true, started = now, received = 0, manifests157 = 0, requested157 = 0,
        wanted157 = {}, deferred157 = {}, legacyFallback157 = false, manual180 = manual,
        compatiblePeersR2 = table.getn(ordered), peerCandidatesR26 = ordered, peerLimitR26 = peerLimit,
        peerIndexR26 = 0, peerAttemptsR26 = 0, lastPeerAttemptAtR26 = 0, peerAttemptedKeysR26 = {},
    }
    if not QueueNextCraftingPeerR26(self, craft, now) then
        craft.syncState.active = false
        return false
    end
    craft.lastSync = now
    self.lastCraftingSyncRequestAt = now
    local reason = manual and "manual" or (force and "forced-background" or "background")
    self.runtime.craftingSyncContext180 = reason
    self.runtime.craftingSyncReasonsR26 = self.runtime.craftingSyncReasonsR26 or {}
    self.runtime.craftingSyncReasonsR26[reason] = (tonumber(self.runtime.craftingSyncReasonsR26[reason]) or 0) + 1
    if self.SetOperationState156 then self:SetOperationState156("CRAFTING", "WORKING", "Waiting for profession updates", nil, { source = "crafting", manual = manual }) end
    if manual and self.SetStatus then self:SetStatus("Checking for newer profession information from online guild members...", nil, { source = "crafting", manual = true }) end
    return true
end

function OTLGM:HandleCraftingManifest157(payload, sender)
    local craft = PreviousEnsureCraftingDB157(self)
    if not craft then return false end
    craft.syncState = craft.syncState or {}
    if not craft.syncState.active then
        craft.syncState.active = true
        craft.syncState.started = self:Now()
        craft.syncState.received = 0
    end
    craft.syncState.manifests157 = tonumber(craft.syncState.manifests157) or 0
    craft.syncState.requested157 = tonumber(craft.syncState.requested157) or 0
    craft.syncState.wanted157 = craft.syncState.wanted157 or {}
    craft.syncState.manifests157 = (tonumber(craft.syncState.manifests157) or 0) + 1
    craft.syncState.lastManifestAt157 = self:Now()
    craft.syncState.respondedPeerR26 = sender
    local entries = Split157(payload or "", "~")
    local i, fields, owner, professionKey, timestamp, count, hash, localProfession, key
    for i = 1, table.getn(entries) do
        fields = Split157(entries[i], ",")
        owner = Unescape157(fields[1] or "")
        professionKey = Unescape157(fields[2] or "")
        timestamp = tonumber(fields[3]) or 0
        count = tonumber(fields[4]) or 0
        hash = Unescape157(fields[5] or "0")
        local remoteIcons = tonumber(fields[6]) or 0
        local remoteMaterials = tonumber(fields[7]) or 0
        if owner ~= "" and professionKey ~= "" and count >= 0 then
            localProfession = craft.characters and craft.characters[owner] and craft.characters[owner].professions and craft.characters[owner].professions[professionKey]
            key = N157(owner) .. ":" .. professionKey
            local localCount, localIcons, localMaterials = ProfessionCompleteness157(localProfession)
            local score = (remoteIcons * 2) + remoteMaterials
            local needs = not localProfession
                or (tostring(localProfession.hash or "0") ~= tostring(hash) and tostring(localProfession.wireHash or "") ~= tostring(hash))
                or localCount ~= count or localIcons < remoteIcons or localMaterials < remoteMaterials
            local wanted = craft.syncState.wanted157[key]
            local deferred = craft.syncState.deferred157 and craft.syncState.deferred157[key]
            if needs and (not wanted or score > (wanted.score or -1)) and (not deferred or score > (deferred.score or -1)) then
                local requestedAt = self:Now()
                local candidate = { sender = sender, ts = requestedAt, createdAt = requestedAt, lastProgress = requestedAt, tries = 1, hash = hash, expected = count, owner = owner, professionKey = professionKey, score = score }
                craft.syncState.deferred157 = craft.syncState.deferred157 or {}
                if Count157(craft.syncState.wanted157) < MAX_CRAFTING_WANTED_R2 then
                    if QueueWantedCraftingR2(self, craft.syncState, key, candidate) and not wanted then craft.syncState.requested157 = (tonumber(craft.syncState.requested157) or 0) + 1 end
                else
                    craft.syncState.deferred157[key] = candidate
                end
            end
        end
    end
    return true
end

function OTLGM:HandleCommunityAddonMessage(message, channel, sender)
    if string.sub(message or "", 1, 3) == "C1^" then
        local fields = Split157(message, "^")
        local kind = fields[2]
        if kind == "SYNC157" then
            local advertised = fields[3] or ""
            if sender and N157(sender) ~= N157(UnitName("player") or "") and self:IsModernSyncPeerR2(sender, advertised) then self:ScheduleCraftingManifest157(sender) end
            return true
        elseif kind == "SYNC" and self.IsModernSyncPeerR2 and not self:IsModernSyncPeerR2(sender, fields[3]) then
            -- Old 1.7 clients used broad full-state replies. Ignore that sync
            -- generation in 1.8 so a mixed-version guild cannot create a storm.
            self.runtime = self.runtime or {}
            self.runtime.legacyCraftSyncIgnoredR2 = (tonumber(self.runtime.legacyCraftSyncIgnoredR2) or 0) + 1
            return true
        elseif kind == "CCHG" then
            return self:HandleCraftingManifest157(fields[3] or "", sender)
        elseif kind == "CMAN" then
            return self:HandleCraftingManifest157(fields[3] or "", sender)
        elseif kind == "CMEND" then
            local craft = PreviousEnsureCraftingDB157(self)
            if craft and craft.syncState then
                craft.syncState.manifestComplete157 = true
                craft.syncState.lastManifestAt157 = self:Now()
                craft.syncState.respondedPeerR26 = sender
                if (tonumber(craft.syncState.manifests157) or 0) == 0 then
                    -- A compatible peer with no local professions still replied;
                    -- do not fan out to another peer just because CMAN was empty.
                    craft.syncState.manifests157 = 1
                    craft.syncState.emptyManifestR26 = true
                end
            end
            return true
        elseif kind == "CWANT" then
            local owner = Unescape157(fields[3] or "")
            local professionKey = Unescape157(fields[4] or "")
            local craft = PreviousEnsureCraftingDB157(self)
            local profession = craft and craft.characters and craft.characters[owner] and craft.characters[owner].professions and craft.characters[owner].professions[professionKey]
            if profession and sender then
                self.runtime = self.runtime or {}
                self.runtime.craftingOutboundTransfers157 = self.runtime.craftingOutboundTransfers157 or {}
                local requestedHash = tostring(Unescape157(fields[5] or "0"))
                local currentHash = tostring(profession.hash or "0")
                if requestedHash ~= "0" and requestedHash ~= currentHash then
                    -- The snapshot changed after the manifest was observed. Send a
                    -- compact targeted manifest so the receiver requests the current
                    -- hash instead of accepting an obsolete transfer.
                    if self.QueueCraftingManifest157 then self:QueueCraftingManifest157(sender) end
                    return true
                end
                local transferKey = N157(sender) .. ":" .. N157(owner) .. ":" .. professionKey .. ":" .. currentHash
                local lastQueued = tonumber(self.runtime.craftingOutboundTransfers157[transferKey]) or 0
                -- A retry must not enqueue a second copy behind an already
                -- queued multi-packet snapshot. If the first queue attempt had
                -- no room it is not recorded, so the retry remains useful.
                if self:Now() - lastQueued >= 120 and self:QueueCraftingProfessionShare(owner, professionKey, sender) then
                    if Count157(self.runtime.craftingOutboundTransfers157) >= 120 then
                        local storedKey, storedAt, oldestKey, oldestAt
                        for storedKey, storedAt in pairs(self.runtime.craftingOutboundTransfers157) do
                            if not oldestAt or (tonumber(storedAt) or 0) < oldestAt then oldestKey, oldestAt = storedKey, tonumber(storedAt) or 0 end
                        end
                        if oldestKey then self.runtime.craftingOutboundTransfers157[oldestKey] = nil end
                    end
                    self.runtime.craftingOutboundTransfers157[transferKey] = self:Now()
                end
            end
            return true
        end
    end
    return PreviousHandleCommunityAddonMessage157(self, message, channel, sender)
end

function OTLGM.__impl180.ProcessCraftingTimers__impl1(self, stageR26)
    -- R26 lets the shared scheduler preempt between independent crafting
    -- domains. Calls without a stage preserve the historical aggregate API.
    if stageR26 == "BASE" then
        PreviousProcessCraftingTimers157(self, 2)
        return
    elseif stageR26 == "DETAIL" then
        if not (self.InCombat and self:InCombat()) and self.ProcessCraftingDetailQueue then self:ProcessCraftingDetailQueue(1) end
        return
    end
    local craft = PreviousEnsureCraftingDB157(self)
    local now = self:Now()
    local manifestKey, manifestPending
    for manifestKey, manifestPending in pairs(self.craftingManifestTargets157 or {}) do
        if manifestPending and now >= (manifestPending.due or 0) then
            self.craftingManifestTargets157[manifestKey] = nil
            self:QueueCraftingManifest157(manifestPending.name)
            break
        end
    end
    if craft and craft.syncState and craft.syncState.active then
        -- Do not leave the UI in Syncing forever when no current addon peer
        -- replies. Existing cached professions remain intact; a later manual
        -- request can try again after the normal cooldown.
        if (tonumber(craft.syncState.manifests157) or 0) == 0 then
            local lastAttempt = tonumber(craft.syncState.lastPeerAttemptAtR26) or tonumber(craft.syncState.started) or now
            local tried = tonumber(craft.syncState.peerIndexR26) or 0
            local limit = math.min(tonumber(craft.syncState.peerLimitR26) or 1, table.getn(craft.syncState.peerCandidatesR26 or {}))
            if now - lastAttempt >= 8 and tried < limit then
                -- Controlled fallback: exactly one additional peer is asked at a
                -- time. We never fan out four identical recovery requests.
                QueueNextCraftingPeerR26(self, craft, now)
            elseif now - lastAttempt >= 10 and tried >= limit then
                local received = tonumber(craft.syncState.received) or 0
                craft.syncState.active = false
                craft.syncState.completed = now
                if self.SetOperationState156 then self:SetOperationState156("CRAFTING", "DONE", received > 0 and ("Received " .. tostring(received) .. " older profession update(s)") or "No profession update received", 4, { source = "crafting", manual = craft.syncState.manual180 }) end
                if craft.syncState.manual180 and self.SetStatus and self.ui and self.ui.currentPage == "professions" then
                    if received > 0 then self:SetStatus("Crafting update finished: received " .. tostring(received) .. " profession update(s).", nil, { source = "crafting", manual = true })
                    else self:SetStatus("No compatible guild member shared profession data; existing recipes were kept.", nil, { source = "crafting", manual = true }) end
                end
            end
        end
        local key, wanted
        for key, wanted in pairs(craft.syncState.wanted157 or {}) do
            local idle = wanted and now - (wanted.lastProgress or wanted.ts or now) or 0
            local age = wanted and now - (wanted.createdAt or wanted.ts or now) or 0
            if wanted and idle >= 20 and (wanted.tries or 1) < 2 then
                wanted.tries = (wanted.tries or 1) + 1
                wanted.ts = now
                wanted.lastProgress = now
                local owner = wanted.owner
                local professionKey = wanted.professionKey
                if wanted.sender and owner and professionKey then
                    if self.RegisterExpectedCraftingTransfer180 then self:RegisterExpectedCraftingTransfer180(wanted.sender, owner, professionKey, wanted.hash or "0", 120) end
                    self:QueueCommunityPayload(table.concat({ "C1", "CWANT", Escape157(owner, 36), Escape157(professionKey, 20), Escape157(wanted.hash or "0", 20) }, "^"), "WHISPER", wanted.sender, 1)
                end
            elseif wanted and (idle >= 90 or age >= 120) then
                craft.syncState.wanted157[key] = nil
            end
        end
    end
    if craft and craft.syncState and craft.syncState.active and (tonumber(craft.syncState.manifests157) or 0) > 0 then
        FillDeferredCraftingR2(self, craft.syncState)
        local outstanding = Count157(craft.syncState.wanted157) + Count157(craft.syncState.deferred157 or {})
        local quiet = now - (craft.syncState.lastManifestAt157 or craft.syncState.started or now)
        if outstanding == 0 and quiet >= 5 then
            craft.syncState.active = false
            craft.syncState.completed = now
            if self.SetOperationState156 then self:SetOperationState156("CRAFTING", "DONE", "Received " .. tostring(craft.syncState.received or 0) .. " profession update(s)", 4, { source = "crafting", manual = craft.syncState.manual180 }) end
            if craft.syncState.manual180 and self.SetStatus and self.ui and self.ui.currentPage == "professions" then
                if (tonumber(craft.syncState.received) or 0) > 0 then self:SetStatus("Crafting update complete: " .. tostring(craft.syncState.received) .. " profession update(s) received.", nil, { source = "crafting", manual = true })
                else self:SetStatus("Crafting update complete: shared recipes are already up to date.", nil, { source = "crafting", manual = true }) end
            end
        end
    end
    if stageR26 == "SYNC" then return end
    PreviousProcessCraftingTimers157(self, 2)
    if not (self.InCombat and self:InCombat()) and self.ProcessCraftingDetailQueue then self:ProcessCraftingDetailQueue(1) end
end

-- ---------------------------------------------------------------------------
-- Professions UI: guaranteed safe icons and direct crafter interaction
-- ---------------------------------------------------------------------------

function OTLGM:BuildNextProfessionsPage(page)
    PreviousBuildNextProfessionsPage157(self, page)
    self:BuildCrafterInteraction157(page)
    if self.InitializeCraftingDetailsUI then self:InitializeCraftingDetailsUI() end
end

function OTLGM:BuildCrafterInteraction157(page)
    if self.ui.crafterMenu157 then return end
    local crafters = self.ui.craftingRequestButton and self.ui.craftingRequestButton:GetParent()
    if not crafters then return end
    local shield = CreateFrame("Button", nil, self.ui.pages.professions or page)
    OTLGM:PrepareInteractiveControl170(shield, "button")
    shield:SetAllPoints(self.ui.pages.professions or page)
    shield:SetFrameLevel((self.ui.pages.professions or page):GetFrameLevel() + 70)
    shield:EnableMouse(true)
    shield:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    shield:SetScript("OnClick", function() OTLGM:CloseCrafterMenu157() end)
    shield:Hide()
    self.ui.crafterShield157 = shield

    local menu = NewPanel157(self.ui.main, 176, 112)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetFrameLevel(self.ui.main:GetFrameLevel() + 230)
    menu:SetPoint("CENTER", self.ui.main, "CENTER", 250, 40)
    menu.title = NewText157(menu, "GameFontNormal", "Crafter", 10, -10, 156, "CENTER")
    menu.whisper = NewButton157(menu, "Whisper", 10, -34, 156, 22, function()
        local name = OTLGM.ui.crafterMenu157.target157
        OTLGM:CloseCrafterMenu157()
        if name then OTLGM:OpenGuildChatWhisper(name) end
    end)
    menu.invite = NewButton157(menu, "Invite to Group", 10, -58, 156, 22, function()
        local name = OTLGM.ui.crafterMenu157.target157
        OTLGM:CloseCrafterMenu157()
        if name then OTLGM:InviteMemberToGroup(name) end
    end)
    menu.roster = NewButton157(menu, "View in Roster", 10, -82, 156, 22, function()
        local name = OTLGM.ui.crafterMenu157.target157
        OTLGM:CloseCrafterMenu157()
        if name then OTLGM:ShowPage("roster") OTLGM:SelectRosterMember(name) end
    end)
    menu:Hide()
    self.ui.crafterMenu157 = menu

    local i
    for i = 1, table.getn(self.ui.craftingCrafterRows or {}) do
        local row = self.ui.craftingCrafterRows[i]
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("OnClick", function()
            if not this.crafterData then return end
            OTLGM.ui.craftingSelectedCrafter = this.crafterData.name
            if arg1 == "RightButton" then OTLGM:OpenCrafterMenu157(this.crafterData)
            else OTLGM:OpenGuildChatWhisper(this.crafterData.name) end
        end)
    end
end

function OTLGM:OpenCrafterMenu157(crafter)
    local menu = self.ui and self.ui.crafterMenu157
    if not menu or not crafter then return end
    if menu:IsVisible() and menu.target157 == crafter.name then self:CloseCrafterMenu157() return end
    menu.target157 = crafter.name
    menu.title:SetText((crafter.name or "Crafter") .. (crafter.online and "  |cff66ff66ONLINE|r" or "  |cff999999OFFLINE|r"))
    ButtonEnabled157(menu.invite, crafter.online and true or false, "This crafter is currently offline.")
    if self.ui.crafterShield157 then self.ui.crafterShield157:Show() end
    menu:Show()
end

function OTLGM:CloseCrafterMenu157()
    if self.ui and self.ui.crafterMenu157 then self.ui.crafterMenu157:Hide() end
    if self.ui and self.ui.crafterShield157 then self.ui.crafterShield157:Hide() end
end

function OTLGM.__impl180.RefreshCraftingRecipesPanel__impl1(self, summary)
    PreviousRefreshCraftingRecipesPanel157(self, summary)
    local i, row, result, professionKey, recipe, reagent
    for i = 1, table.getn(self.ui and self.ui.craftingRecipeRows or {}) do
        row = self.ui.craftingRecipeRows[i]
        result = row and row.recipeData
        if row and result and result.recipe then
            professionKey = result.professionKey
            SetTextureSafe157(row.recipeIcon, self:ResolveCraftingIcon157(result.recipe, professionKey))
        end
    end
    result = self.ui and self.ui.craftingSelectedRecipeData
    if result and result.recipe then
        SetTextureSafe157(self.ui.craftingRecipeIcon152, self:ResolveCraftingIcon157(result.recipe, result.professionKey))
        for i = 1, table.getn(self.ui.craftingMaterialRows152 or {}) do
            reagent = result.recipe.reagents and result.recipe.reagents[i]
            if reagent then SetTextureSafe157(self.ui.craftingMaterialRows152[i].icon, self:ResolveCraftingIcon157(reagent, result.professionKey)) end
        end
    end
    -- Whisper is now a direct left-click on the exact crafter row.
    if self.ui.craftingMoreWhisper156 then self.ui.craftingMoreWhisper156:Hide() end
end

-- ---------------------------------------------------------------------------
-- Raid planner cleanup, priority, date preview and access rules
-- ---------------------------------------------------------------------------

local function HideTree157(frame)
    if not frame then return end
    frame:Hide()
    local children = { frame:GetChildren() }
    local i
    for i = 1, table.getn(children) do HideTree157(children[i]) end
end

function OTLGM:HideLegacyRaidUI157()
    if self.ui and self.ui.legacyRaidHidden157 then return end
    local oldPanel = self.ui and self.ui.pvePanels and self.ui.pvePanels.RAIDS
    local root = self.ui and self.ui.raidPlanner156
    if not oldPanel or not root then return end
    local children = { oldPanel:GetChildren() }
    local regions = { oldPanel:GetRegions() }
    local i
    for i = 1, table.getn(children) do if children[i] ~= root then HideTree157(children[i]) end end
    for i = 1, table.getn(regions) do regions[i]:Hide() end
    root:Show()
    self.ui.legacyRaidHidden157 = true
end

function OTLGM:BuildPvePage(page)
    PreviousBuildPvePage157(self, page)
    self:BuildRaidEnhancements157()
    self:HideLegacyRaidUI157()
end

function OTLGM.__impl180.BuildRaidEnhancements157__impl1(self)
    if not self.ui or not self.ui.raidPlanner156 or self.ui.raidEnhancements157 then return end
    self.ui.raidEnhancements157 = true
    local i, row
    for i = 1, table.getn(self.ui.raidRows156 or {}) do
        row = self.ui.raidRows156[i]
        row.icon157 = row:CreateTexture(nil, "OVERLAY")
        row.icon157:SetPoint("LEFT", row, "LEFT", 7, 0)
        row.icon157:SetWidth(20)
        row.icon157:SetHeight(20)
        row.icon157:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        if row.label156 then row.label156:ClearAllPoints() row.label156:SetPoint("TOPLEFT", row, "TOPLEFT", 32, -5) row.label156:SetWidth(220) row.label156:SetJustifyH("LEFT") end
        if row.meta156 then row.meta156:ClearAllPoints() row.meta156:SetPoint("TOPLEFT", row, "TOPLEFT", 32, -22) row.meta156:SetWidth(220) end
    end
    local editor = self.ui.raidEditor156
    if editor then
        self.ui.raidDatePreview157 = NewText157(editor, "GameFontNormalSmall", "", 338, -174, 320, "LEFT")
        self.ui.raidDatePreview157:SetTextColor(0.95, 0.78, 0.30)
        self.ui.raidFeatured157 = false
        self.ui.raidFeaturedButton157 = NewButton157(editor, "Main Raid: Off", 238, -268, 136, 30, function()
            OTLGM.ui.raidFeatured157 = not OTLGM.ui.raidFeatured157
            ButtonText157(OTLGM.ui.raidFeaturedButton157, OTLGM.ui.raidFeatured157 and "Main Raid: On" or "Main Raid: Off")
            SetButtonSelected157(OTLGM.ui.raidFeaturedButton157, OTLGM.ui.raidFeatured157)
        end)
        local edits = { self.ui.raidDay156, self.ui.raidHour156, self.ui.raidMinute156, self.ui.raidGatherHour156, self.ui.raidGatherMinute156 }
        for i = 1, table.getn(edits) do if edits[i] then edits[i]:SetScript("OnTextChanged", function() OTLGM:RefreshRaidDatePreview157() end) end end
    end
end

function OTLGM.__impl180.OpenRaidEditor156__impl1(self, raid, duplicate)
    PreviousOpenRaidEditor157(self, raid, duplicate)
    self.ui.raidFeatured157 = raid and raid.featured and true or false
    ButtonText157(self.ui.raidFeaturedButton157, self.ui.raidFeatured157 and "Main Raid: On" or "Main Raid: Off")
    SetButtonSelected157(self.ui.raidFeaturedButton157, self.ui.raidFeatured157)
    if self.PrepareRaidRosterEditor180 then self:PrepareRaidRosterEditor180(raid, duplicate) end
    self:RefreshRaidDatePreview157()
end

function OTLGM.__impl180.PublishPveRaidEvent156__impl1(self, data, existingId)
    local ok, record = PreviousPublishPveRaidEvent157(self, data, existingId)
    if ok and record then
        local featured = data and data.featured and true or false
        if record.featured ~= featured then
            record.featured = featured
            record.rev = (tonumber(record.rev) or 0) + 1
            record.ts = self:Now()
            self:QueuePvePayload(self:SerializePveRaid(record), "GUILD")
        end
        self:QueueRaidMeta157(record)
        if self.ApplyRaidRosterSourceAfterPublish180 then
            local rosterOk, rosterError = self:ApplyRaidRosterSourceAfterPublish180(record, data, existingId)
            if not rosterOk then return false, rosterError or "The raid roster could not be prepared." end
        end
    end
    return ok, record
end

function OTLGM:SerializePveRaid(record)
    -- Keep the core packet backward-compatible while carrying the two short C6
    -- access fields early enough to avoid a private-event visibility flash before
    -- the optional RMETA1 packet arrives. Older clients ignore trailing fields.
    local core = PreviousSerializePveRaid157(self, record)
    local visibility = tostring(record and record.visibility180 or "GUILD_VISIBLE")
    local audience = tostring(record and record.notifyAudience180 or "ASSIGNED")
    local extended = core .. "^" .. visibility .. "^" .. audience
    if string.len(extended) <= 250 then return extended end
    return core
end

function OTLGM.__impl180.ApplyRemotePveRaid__impl1(self, fields)
    local result = PreviousApplyRemotePveRaid157(self, fields)
    if result then
        local id = fields and fields[3]
        local pve = self:EnsureRaid156DB()
        local record = id and self:GetRaidById156(id)
        local meta = pve and pve.raidMeta157 and pve.raidMeta157[id]
        if record and meta and (tonumber(meta.rev) or 0) >= (tonumber(record.rev) or 0) then
            record.featured = meta.featured
            record.cancelReason = meta.cancelReason
            pve.raidMeta157[id] = nil
        end
    end
    return result
end

function OTLGM:HandlePveAddonMessage(message, channel, sender)
    if string.sub(message or "", 1, 3) == tostring(self.pveProtocol or "P1") .. "^" then
        local fields = Split157(message, "^")
        if fields[2] == "RDMETA" then return self:ApplyRaidMeta157(fields, sender, channel) end
    end
    return PreviousHandlePveAddonMessage157(self, message, channel, sender)
end

function OTLGM:QueuePveSyncResponse(target)
    local result = PreviousQueuePveSyncResponse157(self, target)
    local pve = self:EnsureRaid156DB()
    local id, record
    for id, record in pairs(pve and pve.raids or {}) do self:QueueRaidMeta157(record, target) end
    for id, record in pairs(pve and pve.cancelledRaids156 or {}) do self:QueueRaidMeta157(record, target) end
    return result
end

function OTLGM:GetRaidList156(filter)
    local source = PreviousGetRaidList157(self, filter)
    if filter == "UPCOMING" then
        local pve = self:EnsureRaid156DB()
        local id, record
        for id, record in pairs(pve and pve.cancelledRaids156 or {}) do
            if (tonumber(record.startTs) or 0) + 14400 >= self:Now() then table.insert(source, record) end
        end
    end
    local list, index, candidate = {}, 1, nil
    for index = 1, table.getn(source or {}) do
        candidate = source[index]
        local access = self.GetRaidEventAccess180 and self:GetRaidEventAccess180(candidate) or { canView = true }
        if access.canView then table.insert(list, candidate) end
    end
    table.sort(list, function(a, b)
        if filter == "UPCOMING" then
            if (a.featured and true or false) ~= (b.featured and true or false) then return a.featured and true or false end
            if (a.status == "CANCELLED") ~= (b.status == "CANCELLED") then return a.status ~= "CANCELLED" end
        end
        if (a.startTs or 0) ~= (b.startTs or 0) then return filter == "PAST" and (a.startTs or 0) > (b.startTs or 0) or (a.startTs or 0) < (b.startTs or 0) end
        return tostring(a.id) < tostring(b.id)
    end)
    return list
end

function OTLGM.__impl180.RefreshRaidPlanner156__impl1(self)
    PreviousRefreshRaidPlanner157(self)
    self:HideLegacyRaidUI157()
    local filter = self.ui.raidFilter156 or "UPCOMING"
    local i, row, raid
    for i = 1, table.getn(self.ui.raidRows156 or {}) do
        row = self.ui.raidRows156[i]
        raid = row and row.raid156
        if row and raid then
            SetTextureSafe157(row.icon157, raid.status == "CANCELLED" and CANCELLED_RAID_TEXTURE_157 or (raid.featured and MAIN_RAID_TEXTURE_157 or NORMAL_RAID_TEXTURE_157))
            if raid.status == "CANCELLED" then
                row.label156:SetText("|cffff5555[CANCELLED]|r  |cff999999" .. (raid.name or "Guild Raid") .. "|r")
                row.meta156:SetTextColor(1, 0.32, 0.26)
            elseif raid.featured then
                row.label156:SetText("|cffffcc44[MAIN RAID]|r  " .. (raid.name or "Guild Raid"))
                row.meta156:SetTextColor(1, 0.78, 0.28)
                row:SetBackdropColor(0.12, 0.07, 0.015, 1)
                row:SetBackdropBorderColor(0.90, 0.58, 0.16, 1)
            else
                row.meta156:SetTextColor(0.60, 0.60, 0.58)
            end
        end
    end
    local selected = self:GetRaidById156(self.ui.raidSelected156)
    if selected then
        local active = filter == "UPCOMING" and selected.status ~= "CANCELLED"
        ButtonEnabled157(self.ui.raidSeen156, filter == "UPCOMING", "Seen is available for current raid notices.")
        local readyAllowed = active and self:IsRaidNoticeEligible()
        ButtonEnabled157(self.ui.raidReady156, readyAllowed, "Your current guild role is not approved for raid participation. Register in the guild Discord under your in-game name to receive a raider role.")
        if selected.featured and self.ui.raidDetailTitle156 then self.ui.raidDetailTitle156:SetText("|cffffcc44[MAIN RAID]|r  " .. (selected.name or "Guild Raid")) end
        if selected.status == "CANCELLED" then
            self.ui.raidDetailTitle156:SetText("|cffff5555[CANCELLED]|r  |cff999999" .. (selected.name or "Guild Raid") .. "|r")
            self.ui.raidDetailNote156:SetText((selected.cancelReason and selected.cancelReason ~= "" and ("Cancellation: " .. selected.cancelReason .. "\n") or "") .. (selected.note or ""))
        end
    end
    if self.ui.raidNoRole156 then
        self.ui.raidNoRole156:ClearAllPoints()
        self.ui.raidNoRole156:SetPoint("TOPLEFT", self.ui.raidSeen156:GetParent(), "TOPLEFT", 16, -314)
        self.ui.raidNoRole156:SetWidth(396)
        self.ui.raidNoRole156:SetHeight(58)
        self.ui.raidNoRole156:SetText("RAID PARTICIPATION ROLE REQUIRED\nYou can read every raid and mark Seen. Ready is available after registering in the guild Discord under your in-game name and receiving an approved raider role.")
    end
end

function OTLGM:RefreshPvePage()
    return PreviousRefreshPvePage157(self)
end

function OTLGM.__impl180.RefreshHomePveSummary155__impl1(self)
    PreviousRefreshHomePveSummary157(self)
    if not self.ui or not self.ui.homeRaidText then return end
    local all = self:GetRaidList156("UPCOMING")
    local active = {}
    local i, raid
    for i = 1, table.getn(all) do
        raid = all[i]
        if raid.status ~= "CANCELLED" and (raid.startTs or 0) >= self:Now() - 60 then table.insert(active, raid) end
    end
    table.sort(active, function(a, b)
        if (a.featured and true or false) ~= (b.featured and true or false) then return a.featured and true or false end
        return (a.startTs or 0) < (b.startTs or 0)
    end)
    raid = active[1]
    if raid then
        local startTs = tonumber(raid.startTs) or 0
        local dateText = startTs > 0 and (self.FormatServerDate180 and self:FormatServerDate180(startTs, "%A, %d %b") or date("%A, %d %b", startTs)) or "Date TBA"
        local timeText = self.GetPveRaidServerTime155 and self:GetPveRaidServerTime155(raid) or (raid.serverTime or "Time TBA")
        local remaining = self.GetPveRaidRemainingText and self:GetPveRaidRemainingText(raid) or ""
        local header = raid.featured and "|cffff5b3dIMPORTANT RAID|r" or "|cffffcc44NEXT RAID|r"
        local leader = raid.author and raid.author ~= "" and ("Leader: " .. tostring(raid.author)) or "Leader TBA"
        local place = raid.location and raid.location ~= "" and ("Location: " .. tostring(raid.location)) or "Location TBA"
        local note = raid.note and raid.note ~= "" and ("\n" .. self:Utf8Truncate(raid.note, 74)) or ""
        self.ui.homeRaidText:SetText(header .. "\n|cffffffff" .. tostring(raid.name or "Guild Raid") .. "|r\n" ..
            dateText .. "  -  " .. timeText .. "\n" .. remaining .. "\n" .. leader .. "\n" .. place .. note)
        if self.ui.homeRaidButton then self.ui.homeRaidButton.raidId170 = raid.id end
    else
        self.ui.homeRaidText:SetText("|cff888888No raid scheduled|r\nLeadership can publish the next raid from PvE Hub.")
    end
end

-- ---------------------------------------------------------------------------
-- New announcement means a clean form. Editing still loads existing content.
-- ---------------------------------------------------------------------------

function OTLGM:OpenAnnouncementComposer152(id)
    PreviousOpenAnnouncementComposer157(self, id)
    if not id and self.ui and self.ui.announcementComposer152 then
        local dialog = self.ui.announcementComposer152
        dialog.editId = nil
        dialog.titleEdit:SetText("")
        dialog.bodyEdit:SetText("")
        dialog.importance = "NORMAL"
        dialog.notifyFlag = false
        dialog.pinned = false
        if OTLGM_DB and OTLGM_DB.settings then OTLGM_DB.settings.announcementDraftTitle153 = "" OTLGM_DB.settings.announcementDraftBody153 = "" end
        if self.RefreshAnnouncementComposer152 then self:RefreshAnnouncementComposer152() end
    end
end

-- ---------------------------------------------------------------------------
-- Guild Activity: important/publication tabs and readable type colors
-- ---------------------------------------------------------------------------

local ActivityDefs157 = {
    { "ALL", "All" }, { "IMPORTANT", "Important" }, { "PUBLICATION", "Publications" },
    { "GROUP", "Groups" }, { "CRAFT", "Crafting" }, { "RESPONSE", "Replies" }, { "REACTION", "Reactions" },
}

local function ActivityMatch157(entry, filter)
    if filter == "ALL" then return true end
    local kind = string.upper(entry and entry.kind or "INFO")
    if filter == "IMPORTANT" then return kind == "RAID" or kind == "ANNOUNCEMENT" or kind == "RESPONSE" or kind == "APPLICATION" end
    if filter == "PUBLICATION" then return kind == "ANNOUNCEMENT" or kind == "RAID" end
    if filter == "GROUP" then return kind == "GROUP" end
    if filter == "CRAFT" then return kind == "CRAFT" or kind == "RECIPES" or kind == "REQUEST" end
    if filter == "RESPONSE" then return kind == "RESPONSE" or string.find(kind, "REPLY", 1, true) ~= nil or kind == "APPLICATION" end
    if filter == "REACTION" then return kind == "REACTION" or string.find(kind, "REACT", 1, true) ~= nil end
    return kind == filter
end

function OTLGM:GetActivityEntries153(mode, filter)
    local source = PreviousGetActivityEntries157(self, mode, "ALL") or {}
    local result = {}
    local i
    for i = 1, table.getn(source) do if ActivityMatch157(source[i], filter or "ALL") then table.insert(result, source[i]) end end
    table.sort(result, function(a, b) return (a.ts or 0) > (b.ts or 0) end)
    while table.getn(result) > 60 do table.remove(result) end
    return result
end

function OTLGM:BuildActivityDialogs153()
    PreviousBuildActivityDialogs157(self)
    local dialog = self.ui and self.ui.activityDialog153
    if not dialog or dialog.filters157 then return end
    dialog.filters157 = true
    local i
    for i = 1, 5 do
        dialog.filterButtons[i]:ClearAllPoints()
        dialog.filterButtons[i]:SetPoint("TOPLEFT", dialog, "TOPLEFT", 24 + ((i - 1) * 93), -72)
        dialog.filterButtons[i]:SetWidth(86)
    end
    for i = 6, 7 do
        local captured = i
        dialog.filterButtons[i] = NewButton157(dialog, ActivityDefs157[i][2], 24 + ((i - 1) * 93), -72, 86, 28, function()
            OTLGM.ui.activityDialog153.filter153 = ActivityDefs157[captured][1]
            OTLGM.ui.activityDialog153.offset153 = 0
            OTLGM:RefreshActivityDialog153()
        end)
    end
end

local function ActivityColor157(kind)
    kind = string.upper(kind or "INFO")
    if kind == "RAID" then return 1.0, 0.34, 0.18, "[RAID]" end
    if kind == "ANNOUNCEMENT" then return 1.0, 0.76, 0.20, "[POST]" end
    if kind == "GROUP" then return 0.35, 0.70, 1.0, "[GROUP]" end
    if kind == "CRAFT" or kind == "RECIPES" or kind == "REQUEST" then return 0.72, 0.46, 1.0, "[CRAFT]" end
    if kind == "RESPONSE" or kind == "APPLICATION" then return 0.35, 1.0, 0.52, "[REPLY]" end
    if kind == "REACTION" then return 0.55, 0.78, 1.0, "[REACT]" end
    return 0.82, 0.82, 0.78, "[INFO]"
end

function OTLGM:RefreshActivityDialog153()
    local dialog = self.ui and self.ui.activityDialog153
    if not dialog then return end
    local mode = dialog.mode153 or "GUILD"
    if mode == "CRAFTING" then
        if dialog.filterButtons[6] then dialog.filterButtons[6]:Hide() end
        if dialog.filterButtons[7] then dialog.filterButtons[7]:Hide() end
        local ci
        for ci = 1, 5 do if dialog.filterButtons[ci] then dialog.filterButtons[ci]:Show() end end
        return PreviousRefreshActivityDialog157(self)
    end
    if dialog.filterButtons[6] then dialog.filterButtons[6]:Show() end
    if dialog.filterButtons[7] then dialog.filterButtons[7]:Show() end
    local filter = dialog.filter153 or "ALL"
    local i, button
    for i = 1, 7 do
        button = dialog.filterButtons[i]
        button.filterKey153 = ActivityDefs157[i][1]
        ButtonText157(button, ActivityDefs157[i][2])
        SetButtonSelected157(button, filter == ActivityDefs157[i][1])
    end
    dialog.titleText:SetText("Guild Activity")
    dialog.subtitleText:SetText("Important publications, raids, groups, crafting and responses")
    local entries = self:GetActivityEntries153("GUILD", filter)
    local offset = math.max(0, dialog.offset153 or 0)
    local maximum = math.max(0, table.getn(entries) - 10)
    if offset > maximum then offset = maximum end
    dialog.offset153 = offset
    local row, entry, r, g, b, prefix
    for i = 1, 10 do
        row = dialog.rows[i]
        entry = entries[offset + i]
        if entry then
            row.entry153 = entry
            row.timeText:SetText(date("%d %b\n%H:%M", entry.ts or self:Now()))
            r, g, b, prefix = ActivityColor157(entry.kind)
            row.titleText:SetText(prefix .. "  " .. string.sub(entry.title or "Guild activity", 1, 52))
            row.titleText:SetTextColor(r, g, b)
            row.detailText:SetText(string.sub(entry.detail or "", 1, 31))
            row.kindText:SetText(string.upper(entry.kind or "INFO") .. (entry.targetPage and entry.targetPage ~= "" and "  -  click to open" or ""))
            row.kindText:SetTextColor(r * 0.75, g * 0.75, b * 0.75)
            row:Show()
        else row.entry153 = nil row:Hide() end
    end
    if table.getn(entries) == 0 then dialog.statusText:SetText("No activity matches this filter.")
    else dialog.statusText:SetText(tostring(offset + 1) .. "-" .. tostring(math.min(offset + 10, table.getn(entries))) .. " of " .. tostring(table.getn(entries))) end
    ButtonEnabled157(dialog.prevButton, offset > 0, "This is the first page.")
    ButtonEnabled157(dialog.nextButton, offset < maximum, "There are no more activity entries.")
end

function OTLGM.__impl180.SetCommunityReaction__impl1(self, targetType, targetId, reaction, force)
    if string.upper(targetType or "") == "RAID" and string.upper(reaction or "") == "READY" and not self:IsRaidNoticeEligible() then
        if self.ShowNotice then self:ShowNotice("Raider Role Required", "You can mark the raid as Seen, but Ready requires an approved raider guild role. Register in the guild Discord under your in-game name.") end
        return false
    end
    return PreviousSetCommunityReaction157(self, targetType, targetId, reaction, force)
end

-- ---------------------------------------------------------------------------
-- Context menus: stable during chat updates, but easy to close again
-- ---------------------------------------------------------------------------

function OTLGM.__impl180.RefreshGuildChatPage__impl1(self)
    local menu = self.ui and self.ui.chatNameMenu
    local wasVisible = menu and menu:IsVisible()
    local target = menu and menu.targetName
    local result = PreviousRefreshGuildChatPage157(self)
    if wasVisible and menu and target and (OTLGM_DB.settings.guildChatView or "GUILD") ~= "BOARD" then
        menu.targetName = target
        if self.ui.chatMenuShield157 then self.ui.chatMenuShield157:Show() end
        menu:Show()
    end
    if self.RefreshGuildChatExperience170 then self:RefreshGuildChatExperience170() end
    return result
end

function OTLGM:EnsureChatMenuShield157()
    if not self.ui or not self.ui.chatNameMenu or self.ui.chatMenuShield157 then return end
    local page = self.ui.pages and self.ui.pages.guildchat
    if not page then return end
    local shield = CreateFrame("Button", nil, page)
    OTLGM:PrepareInteractiveControl170(shield, "button")
    shield:SetAllPoints(page)
    shield:SetFrameLevel(self.ui.chatNameMenu:GetFrameLevel() - 1)
    shield:EnableMouse(true)
    shield:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    shield:SetScript("OnClick", function() OTLGM:CloseChatNameMenu157() end)
    shield:Hide()
    self.ui.chatMenuShield157 = shield
    self.ui.chatNameMenu:SetFrameLevel(shield:GetFrameLevel() + 2)
    self.ui.chatNameMenu:SetScript("OnHide", function() if OTLGM.ui.chatMenuShield157 then OTLGM.ui.chatMenuShield157:Hide() end end)
end

function OTLGM:OpenGuildChatNameMenu(sender, owner)
    self:EnsureChatMenuShield157()
    local short = string.gsub(sender or "", "%-.*$", "")
    local menu = self.ui and self.ui.chatNameMenu
    if menu and menu:IsVisible() and N157(menu.targetName) == N157(short) then self:CloseChatNameMenu157() return end
    PreviousOpenGuildChatNameMenu157(self, sender, owner)
    if self.ui and self.ui.chatMenuShield157 then self.ui.chatMenuShield157:Show() end
    if menu then menu:Show() end
end

function OTLGM:CloseChatNameMenu157()
    if self.ui and self.ui.chatNameMenu then self.ui.chatNameMenu:Hide() end
    if self.ui and self.ui.chatMenuShield157 then self.ui.chatMenuShield157:Hide() end
end

function OTLGM:CloseTopModal152()
    if self.ui and self.ui.crafterMenu157 and self.ui.crafterMenu157:IsVisible() then self:CloseCrafterMenu157() return true end
    if self.ui and self.ui.chatNameMenu and self.ui.chatNameMenu:IsVisible() then self:CloseChatNameMenu157() return true end
    return PreviousCloseTopModal157(self)
end

function OTLGM.__impl180.GetDiagnosticsText__impl1(self)
    local base = PreviousGetDiagnosticsText157 and PreviousGetDiagnosticsText157(self) or ""
    local craft = self:EnsureCraftingDB()
    local cache = craft and self:EnsureCraftingIconCache157(craft)
    local pve = self.EnsureRaid156DB and self:EnsureRaid156DB() or nil
    local details = craft and craft.details or {}
    local metrics = self.runtime and self.runtime.metrics and self.runtime.metrics.network or {}
    local transport = self.runtime and self.runtime.transport or {}
    local tooltipCompatibility = (GameTooltip and GameTooltip.otlTooltipCompatibility160)
        or (self.runtime and self.runtime.tooltipCompatibility160) or {}
    local backoff = math.max(0, (tonumber(transport.nextAttemptAt) or 0) - self:Now())
    local interaction = self.runtime and self.runtime.interactionAudit170 or {}
    local nativeUI = self.GetNativeUIDiagnostics180 and self:GetNativeUIDiagnostics180() or {}
    local result = base ..
        "\nRuntime foundation " .. tostring(self.version) .. ": Loaded" ..
        "\nRegistered modules: " .. tostring(Count157(self.modules)) ..
        "\nInbound sender validation: Enabled" ..
        "\nCrafting manifest sync: " .. tostring(self.HandleCraftingManifest157 and "Available" or "Unavailable") ..
        "\nCrafting special-result detail cache: " .. tostring(Count157(details)) ..
        "\nCrafting icon cache items/names: " .. tostring(Count157(cache and cache.items)) .. "/" .. tostring(Count157(cache and cache.names)) ..
        "\nCrafting manifest received/requested: " .. tostring(craft and craft.syncState and craft.syncState.manifests157 or 0) .. "/" .. tostring(craft and craft.syncState and craft.syncState.requested157 or 0) ..
        "\nRaid metadata cache: " .. tostring(Count157(pve and pve.raidMeta157)) ..
        "\nNetwork sent/retried/dropped/rejected: " .. tostring(metrics.sent or 0) .. "/" .. tostring(metrics.retried or 0) .. "/" .. tostring(metrics.dropped or 0) .. "/" .. tostring(metrics.rejected or 0) ..
        "\nTargeted routed/received/skipped (non-recipient packets are normal): " .. tostring(metrics.targetedRouted or 0) .. "/" .. tostring(metrics.targetedReceived or 0) .. "/" .. tostring(metrics.targetedSkipped or metrics.targetedIgnored or 0) .. " (fast " .. tostring(metrics.targetedFastSkippedR44 or 0) .. ", self echo " .. tostring(metrics.selfEchoFastSkippedR44 or 0) .. ")" ..
        "\nTargeted display payloads shortened safely: " .. tostring(metrics.targetedTrimmed or 0) ..
        "\nOutbound payloads sanitized for chat compatibility: " .. tostring(metrics.outboundSanitized172 or 0) ..
        "\nRecovered network errors: " .. tostring(metrics.recovered or 0) ..
        "\nNetwork backoff: " .. tostring(backoff) .. "s" ..
        "\nTurtleRP tooltip recursion guard: " .. tostring(tooltipCompatibility.wrapper and "Active" or "Not needed") ..
        "\nNative UI layer: " .. tostring(nativeUI.loaded and "Loaded" or "Unavailable") ..
        "\nNative pages registered/built/active: " .. tostring(nativeUI.registered or 0) .. "/" .. tostring(nativeUI.built or 0) .. "/" .. tostring(nativeUI.activePage or "none") ..
        "\nLegacy interaction audit (buttons/editboxes/repaired): " .. tostring(interaction.buttons or 0) .. "/" .. tostring(interaction.editBoxes or 0) .. "/" .. tostring(interaction.repaired or 0) ..
        "\nChat menu shield: " .. tostring(nativeUI.chatShield or "Inactive / not required") ..
        "\nModal stack depth/active: " .. tostring(nativeUI.modalDepth or 0) .. "/" .. tostring(nativeUI.activeModal or "none")
    if metrics.lastError then
        result = result .. "\nLast network error (" .. tostring(metrics.lastErrorChannel or "?") .. "/" .. tostring(metrics.lastErrorSource or "?") .. "): " .. tostring(metrics.lastError)
    end
    return result
end

function OTLGM:BuildNextUI()
    PreviousBuildNextUI157(self)
    self:EnsureChatMenuShield157()
    if self.BuildExperience170 then self:BuildExperience170() end
    if self.RefreshNavigation then self:RefreshNavigation() end
    if OTLGM_DB then OTLGM_DB.schemaVersion = self.schemaVersion end
end

-- Keep the icon cache bounded without polling. This is called by the existing
-- keyed sleeping scheduler, but the expensive prune runs only once every six hours.
local PreviousProcessQuality156Timers157 = OTLGM.__impl180.Stage_Quality156_ProcessQuality156Timers_1__impl1
function OTLGM.__impl180.ProcessQuality156Timers__impl1(self)
    if PreviousProcessQuality156Timers157 then
        local ok, problem = pcall(PreviousProcessQuality156Timers157, self)
        if not ok and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Quality/COORDINATION", problem) end
    end
    local now = self:Now()
    if not self.lastIconPrune157 or now - self.lastIconPrune157 > 21600 then
        self.lastIconPrune157 = now
        if self.PruneCraftingIconCache157 then
            local ok, problem = pcall(self.PruneCraftingIconCache157, self)
            if not ok and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Quality/ICON_PRUNE", problem) end
        end
        if self.PruneCraftingDetails then
            local ok, problem = pcall(self.PruneCraftingDetails, self, 1200)
            if not ok and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Quality/CRAFT_DETAIL_PRUNE", problem) end
        end
        if self.PruneDetectedAddonUsers170 then
            local ok, problem = pcall(self.PruneDetectedAddonUsers170, self)
            if not ok and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Quality/ADDON_USER_PRUNE", problem) end
        end
    end
end

OTLGM:RegisterModule("Reliability", { layer = "integration", generation = "1.6" })
