-- Order of the Lion Guild Manager
-- v1.5.7 reliability, visual cleanup, raid priority and crafting manifest layer

OTLGM.version = "1.5.7"
OTLGM.quality157Loaded = true
OTLGM.schemaVersion = 12

local BaseEnsureDB157 = OTLGM.EnsureDB
local BaseEnsureCraftingDB157 = OTLGM.EnsureCraftingDB
local BaseScanCurrentProfession157 = OTLGM.ScanCurrentProfession
local BaseQueueCraftingProfessionShare157 = OTLGM.QueueCraftingProfessionShare
local BaseApplyRemoteRecipeSnapshot157 = OTLGM.ApplyRemoteRecipeSnapshot155
local BaseRequestCraftingSync157 = OTLGM.RequestCraftingSync
local BaseProcessCraftingTimers157 = OTLGM.ProcessCraftingTimers
local BaseHandleCommunityAddonMessage157 = OTLGM.HandleCommunityAddonMessage
local BaseBuildNextProfessionsPage157 = OTLGM.BuildNextProfessionsPage
local BaseRefreshCraftingRecipesPanel157 = OTLGM.RefreshCraftingRecipesPanel
local BaseBuildPvePage157 = OTLGM.BuildPvePage
local BaseRefreshPvePage157 = OTLGM.RefreshPvePage
local BaseBuildRaidPlanner157 = OTLGM.BuildRaidPlanner156
local BaseOpenRaidEditor157 = OTLGM.OpenRaidEditor156
local BaseSerializePveRaid157 = OTLGM.SerializePveRaid
local BaseApplyRemotePveRaid157 = OTLGM.ApplyRemotePveRaid
local BaseHandlePveAddonMessage157 = OTLGM.HandlePveAddonMessage
local BaseQueuePveSyncResponse157 = OTLGM.QueuePveSyncResponse
local BasePublishPveRaidEvent157 = OTLGM.PublishPveRaidEvent156
local BaseGetRaidList157 = OTLGM.GetRaidList156
local BaseRefreshRaidPlanner157 = OTLGM.RefreshRaidPlanner156
local BaseRefreshHomePveSummary157 = OTLGM.RefreshHomePveSummary155
local BaseOpenAnnouncementComposer157 = OTLGM.OpenAnnouncementComposer152
local BaseBuildActivityDialogs157 = OTLGM.BuildActivityDialogs153
local BaseGetActivityEntries157 = OTLGM.GetActivityEntries153
local BaseRefreshActivityDialog157 = OTLGM.RefreshActivityDialog153
local BaseOpenGuildChatNameMenu157 = OTLGM.OpenGuildChatNameMenu
local BaseCloseTopModal157 = OTLGM.CloseTopModal152
local BaseBuildNextUI157 = OTLGM.BuildNextUI
local BaseSetCommunityReaction157 = OTLGM.SetCommunityReaction
local BaseRefreshGuildChatPage157 = OTLGM.RefreshGuildChatPage
local BaseGetDiagnosticsText157 = OTLGM.GetDiagnosticsText

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
    text = string.gsub(text, "[^%w]", "")
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
    text = string.gsub(text, "%%", "%%25")
    text = string.gsub(text, "%^", "%%5E")
    text = string.gsub(text, "~", "%%7E")
    text = string.gsub(text, ",", "%%2C")
    text = string.gsub(text, "[\r\n\t]", " ")
    if maximum and string.len(text) > maximum then text = string.sub(text, 1, maximum) end
    return text
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
    if type(texture) == "number" then return texture > 0 end
    if type(texture) ~= "string" then return false end
    texture = T157(texture)
    if texture == "" or texture == "?" or texture == "0" then return false end
    if string.find(string.lower(texture), "white8x8", 1, true) then return false end
    -- Some custom clients expose texture file IDs instead of classic paths.
    if string.find(texture, "^%d+$") then return (tonumber(texture) or 0) > 0 end
    if string.len(texture) < 8 then return false end
    if string.find(texture, "\\", 1, true) or string.find(texture, "/", 1, true) then return true end
    return false
end

local function TextureValue157(texture)
    if type(texture) == "string" and string.find(texture, "^%d+$") then return tonumber(texture) end
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
    button.disabledReason156 = reason
    button.enabled156 = enabled and true or false
    button.disabled = not enabled
    if enabled then button:Enable() else button:Disable() end
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
    return frame
end

local function NewButton157(parent, text, x, y, width, height, callback)
    local button = CreateFrame("Button", nil, parent)
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
    button:SetScript("OnClick", callback)
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

function OTLGM:EnsureDB()
    local db = BaseEnsureDB157(self)
    if db and (tonumber(db.schemaVersion) or 0) < 12 then db.schemaVersion = 12 end
    return db
end

-- ---------------------------------------------------------------------------
-- Persistent, bounded crafting texture cache
-- ---------------------------------------------------------------------------

function OTLGM:EnsureCraftingIconCache157(craft)
    craft = craft or BaseEnsureCraftingDB157(self)
    if not craft then return nil end
    craft.iconCache157 = craft.iconCache157 or { items = {}, names = {}, touched = self:Now() }
    craft.iconCache157.items = craft.iconCache157.items or {}
    craft.iconCache157.names = craft.iconCache157.names or {}
    return craft.iconCache157
end

function OTLGM:RememberCraftingIcon157(object, professionKey)
    if not object then return false end
    local texture = object.icon
    if not ValidTexture157(texture) then return false end
    texture = TextureValue157(texture)
    object.icon = texture
    local craft = BaseEnsureCraftingDB157(self)
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
    if ValidTexture157(object.icon) then
        self:RememberCraftingIcon157(object, professionKey)
        return object.icon
    end
    local craft = BaseEnsureCraftingDB157(self)
    local cache = self:EnsureCraftingIconCache157(craft)
    local itemId = tonumber(object.itemId) or ParseItemID157(object.itemLink)
    local entry
    if cache and itemId > 0 then entry = cache.items[tostring(itemId)] end
    if not entry and cache then entry = cache.names[N157((professionKey or "") .. ":" .. (object.name or ""))] end
    if entry and ValidTexture157(entry.icon) then object.icon = entry.icon return entry.icon end
    if itemId > 0 and GetItemInfo then
        local _, link, quality, _, _, _, _, _, _, texture = GetItemInfo(itemId)
        if link and not object.itemLink then object.itemLink = link end
        if quality ~= nil and object.quality == nil then object.quality = tonumber(quality) or 1 end
        if ValidTexture157(texture) then object.icon = texture self:RememberCraftingIcon157(object, professionKey) return texture end
    end
    return QUESTION_TEXTURE_157
end

function OTLGM:HydrateProfessionIcons157(profession, budget)
    if not profession then return false end
    budget = tonumber(budget) or 500
    local changed = false
    local key, recipe, reagent, i
    for key, recipe in pairs(profession.recipes or {}) do
        if budget <= 0 then break end
        budget = budget - 1
        local before = recipe.icon
        local resolved = self:ResolveCraftingIcon157(recipe, profession.key)
        if ValidTexture157(resolved) and before ~= resolved then recipe.icon = resolved changed = true end
        for i = 1, table.getn(recipe.reagents or {}) do
            reagent = recipe.reagents[i]
            before = reagent.icon
            resolved = self:ResolveCraftingIcon157(reagent, profession.key)
            if ValidTexture157(resolved) and before ~= resolved then reagent.icon = resolved changed = true end
        end
    end
    return changed
end

function OTLGM:PruneCraftingIconCache157()
    local craft = BaseEnsureCraftingDB157(self)
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
    TrimOldest(cache.items, 5000)
    TrimOldest(cache.names, 7000)
    cache.touched = now
end

function OTLGM:EnsureCraftingDB()
    local craft = BaseEnsureCraftingDB157(self)
    if craft then self:EnsureCraftingIconCache157(craft) end
    return craft
end

local function SnapshotOldIcons157(profession)
    local map = {}
    local key, recipe, i, reagent
    for key, recipe in pairs(profession and profession.recipes or {}) do
        map[key] = { icon = recipe.icon, reagents = {} }
        for i = 1, table.getn(recipe.reagents or {}) do
            reagent = recipe.reagents[i]
            map[key].reagents[N157((reagent.itemId or 0) .. ":" .. (reagent.name or ""))] = reagent.icon
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
    local craft = BaseEnsureCraftingDB157(self)
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
                if not ValidTexture157(icon) and itemId > 0 and GetItemInfo then local _, _, _, _, _, _, _, _, _, cached = GetItemInfo(itemId) icon = cached end
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
                        if not ValidTexture157(reagentIcon) and reagentId > 0 and GetItemInfo then local _, _, _, _, _, _, _, _, _, cached = GetItemInfo(reagentId) reagentIcon = cached end
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

function OTLGM:ScanCurrentProfession(mode, attempt)
    local rawName
    if mode == "CRAFT" and GetCraftName then rawName = GetCraftName()
    elseif mode ~= "CRAFT" and GetTradeSkillLine then rawName = GetTradeSkillLine() end
    local professionKey = self.NormalizeProfessionKey156 and self:NormalizeProfessionKey156(rawName, rawName) or string.upper(rawName or "")
    local craftBefore = BaseEnsureCraftingDB157(self)
    local player = string.gsub(UnitName("player") or "Unknown", "%-.*$", "")
    local oldProfession = craftBefore and craftBefore.characters and craftBefore.characters[player] and craftBefore.characters[player].professions and craftBefore.characters[player].professions[professionKey]
    local oldIcons = SnapshotOldIcons157(oldProfession)
    local ok, changed = BaseScanCurrentProfession157(self, mode, attempt)
    local craft = BaseEnsureCraftingDB157(self)
    local profession = craft and craft.characters and craft.characters[player] and craft.characters[player].professions and craft.characters[player].professions[professionKey]
    local restored = false
    if profession then
        local key, recipe, stored, i, reagent, oldIcon
        for key, recipe in pairs(profession.recipes or {}) do
            stored = oldIcons[key]
            if stored and not ValidTexture157(recipe.icon) and ValidTexture157(stored.icon) then recipe.icon = stored.icon restored = true end
            for i = 1, table.getn(recipe.reagents or {}) do
                reagent = recipe.reagents[i]
                oldIcon = stored and stored.reagents[N157((reagent.itemId or 0) .. ":" .. (reagent.name or ""))]
                if not ValidTexture157(reagent.icon) and ValidTexture157(oldIcon) then reagent.icon = oldIcon restored = true end
            end
        end
        if self:CaptureOpenProfessionIcons157(mode) then restored = true end
        self:HydrateProfessionIcons157(profession, 600)
        if restored then
            profession.iconRevision157 = (tonumber(profession.iconRevision157) or 0) + 1
            profession.lastSharedAt = 0
            self:QueueCraftingProfessionShare(player, professionKey)
        end
    end
    return ok, changed
end

function OTLGM:QueueCraftingProfessionShare(ownerName, professionKey, target)
    local craft = BaseEnsureCraftingDB157(self)
    local character = craft and craft.characters and craft.characters[ownerName]
    local profession = character and character.professions and character.professions[professionKey]
    if profession then self:HydrateProfessionIcons157(profession, 800) end
    -- A targeted v1.5.7 request may relay a complete cached profession while the
    -- original crafter is offline. The base RC3 serializer is still used, but
    -- localOwner is enabled only for this one whisper and immediately restored.
    local oldLocalOwner = profession and profession.localOwner
    if target and profession and not profession.localOwner then profession.localOwner = true end
    local result = BaseQueueCraftingProfessionShare157(self, ownerName, professionKey, target)
    if profession then profession.localOwner = oldLocalOwner end
    return result
end

function OTLGM:ApplyRemoteRecipeSnapshot155(fields, sender, channel)
    local result = BaseApplyRemoteRecipeSnapshot157(self, fields, sender, channel)
    if result then
        local owner = string.gsub(Unescape157(fields[3] or ""), "%-.*$", "")
        local professionKey = fields[4] or ""
        local craft = BaseEnsureCraftingDB157(self)
        local profession = craft and craft.characters and craft.characters[owner] and craft.characters[owner].professions and craft.characters[owner].professions[professionKey]
        if profession then self:HydrateProfessionIcons157(profession, 800) end
        if craft and craft.syncState then
            craft.syncState.wanted157 = craft.syncState.wanted157 or {}
            craft.syncState.wanted157[N157(owner) .. ":" .. professionKey] = nil
        end
    end
    return result
end

-- ---------------------------------------------------------------------------
-- Manifest-based crafting sync. Only changed professions transfer full data.
-- Cached professions may be relayed so late/offline owners do not fragment the DB.
-- ---------------------------------------------------------------------------

local function ProfessionCompleteness157(profession)
    local recipeCount, iconCount, materialCount = 0, 0, 0
    local key, recipe, i, allIcons
    for key, recipe in pairs(profession and profession.recipes or {}) do
        recipeCount = recipeCount + 1
        if ValidTexture157(recipe.icon) then iconCount = iconCount + 1 end
        allIcons = true
        for i = 1, table.getn(recipe.reagents or {}) do if not ValidTexture157(recipe.reagents[i].icon) then allIcons = false break end end
        if (recipe.materialsStatus == "COMPLETE" or recipe.materialsAvailable) and allIcons then materialCount = materialCount + 1 end
    end
    return recipeCount, iconCount, materialCount
end

function OTLGM:QueueCraftingManifest157(target)
    local craft = BaseEnsureCraftingDB157(self)
    if not craft or not target or target == "" then return false end
    local entries = {}
    local owner, character, professionKey, profession
    for owner, character in pairs(craft.characters or {}) do
        for professionKey, profession in pairs(character.professions or {}) do
            local count, iconCount, materialCount = ProfessionCompleteness157(profession)
            if count > 0 then
                table.insert(entries, table.concat({ Escape157(owner, 36), Escape157(professionKey, 20), tostring(tonumber(profession.ts) or 0), tostring(count), Escape157(profession.hash or "0", 20), tostring(iconCount), tostring(materialCount) }, ","))
            end
        end
    end
    table.sort(entries)
    local packet = ""
    local i, candidate
    for i = 1, table.getn(entries) do
        candidate = packet == "" and entries[i] or (packet .. "~" .. entries[i])
        if string.len("C1^CMAN^" .. candidate) > 235 then
            self:QueueCommunityPayload("C1^CMAN^" .. packet, "WHISPER", target, 2)
            packet = entries[i]
        else packet = candidate end
    end
    if packet ~= "" then self:QueueCommunityPayload("C1^CMAN^" .. packet, "WHISPER", target, 2) end
    self:QueueCommunityPayload("C1^CMEND", "WHISPER", target, 2)
    return true
end

function OTLGM:RequestCraftingSync(force)
    local craft = BaseEnsureCraftingDB157(self)
    if not craft or not SendAddonMessage or not GetGuildInfo("player") then return false end
    local now = self:Now()
    if craft.syncState and craft.syncState.active then return false end
    if not force and craft.lastSync and now - craft.lastSync < 45 then return false end
    craft.lastSync = now
    self.lastCraftingSyncRequestAt = now
    craft.syncState = { active = true, started = now, received = 0, manifests157 = 0, requested157 = 0, wanted157 = {}, legacyFallback157 = false }
    self:QueueCommunityPayload("C1^SYNC157^" .. tostring(self.version), "GUILD", nil, 2)
    if self.SetStatus then self:SetStatus("Requesting crafting manifests from online addon users...") end
    return true
end

function OTLGM:HandleCraftingManifest157(payload, sender)
    local craft = BaseEnsureCraftingDB157(self)
    if not craft then return false end
    craft.syncState = craft.syncState or { active = true, started = self:Now(), received = 0, manifests157 = 0, requested157 = 0, wanted157 = {} }
    craft.syncState.manifests157 = (tonumber(craft.syncState.manifests157) or 0) + 1
    craft.syncState.lastManifestAt157 = self:Now()
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
            local needs = not localProfession or tostring(localProfession.hash or "0") ~= tostring(hash) or localCount ~= count or localIcons < remoteIcons or localMaterials < remoteMaterials
            local wanted = craft.syncState.wanted157[key]
            if needs and (not wanted or score > (wanted.score or -1)) then
                craft.syncState.wanted157[key] = { sender = sender, ts = self:Now(), tries = 1, hash = hash, expected = count, owner = owner, professionKey = professionKey, score = score }
                if not wanted then craft.syncState.requested157 = (tonumber(craft.syncState.requested157) or 0) + 1 end
                self:QueueCommunityPayload(table.concat({ "C1", "CWANT", Escape157(owner, 36), Escape157(professionKey, 20), Escape157(hash, 20) }, "^"), "WHISPER", sender, 1)
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
            if sender and N157(sender) ~= N157(UnitName("player") or "") then self:QueueCraftingManifest157(sender) end
            return true
        elseif kind == "CMAN" then
            return self:HandleCraftingManifest157(fields[3] or "", sender)
        elseif kind == "CMEND" then
            local craft = BaseEnsureCraftingDB157(self)
            if craft and craft.syncState then craft.syncState.manifestComplete157 = true end
            return true
        elseif kind == "CWANT" then
            local owner = Unescape157(fields[3] or "")
            local professionKey = Unescape157(fields[4] or "")
            local craft = BaseEnsureCraftingDB157(self)
            local profession = craft and craft.characters and craft.characters[owner] and craft.characters[owner].professions and craft.characters[owner].professions[professionKey]
            if profession and sender then self:QueueCraftingProfessionShare(owner, professionKey, sender) end
            return true
        end
    end
    return BaseHandleCommunityAddonMessage157(self, message, channel, sender)
end

function OTLGM:ProcessCraftingTimers()
    local craft = BaseEnsureCraftingDB157(self)
    local now = self:Now()
    if craft and craft.syncState and craft.syncState.active then
        local elapsed = now - (craft.syncState.started or now)
        if elapsed > 7 and (tonumber(craft.syncState.manifests157) or 0) == 0 and not craft.syncState.legacyFallback157 then
            craft.syncState.legacyFallback157 = true
            self:QueueCommunityPayload("C1^SYNC^" .. tostring(self.version), "GUILD", nil, 2)
            if self.SetStatus then self:SetStatus("No v1.5.7 manifest received yet; requesting legacy profession snapshots...") end
        end
        local key, wanted
        for key, wanted in pairs(craft.syncState.wanted157 or {}) do
            if wanted and now - (wanted.ts or now) > 8 and (wanted.tries or 1) < 2 then
                wanted.tries = (wanted.tries or 1) + 1
                wanted.ts = now
                local owner = wanted.owner
                local professionKey = wanted.professionKey
                if wanted.sender and owner and professionKey then self:QueueCommunityPayload(table.concat({ "C1", "CWANT", Escape157(owner, 36), Escape157(professionKey, 20), Escape157(wanted.hash or "0", 20) }, "^"), "WHISPER", wanted.sender, 1) end
            elseif wanted and now - (wanted.ts or now) > 18 then
                craft.syncState.wanted157[key] = nil
            end
        end
    end
    if craft and craft.syncState and craft.syncState.active and (tonumber(craft.syncState.manifests157) or 0) > 0 then
        local outstanding = Count157(craft.syncState.wanted157)
        local quiet = now - (craft.syncState.lastManifestAt157 or craft.syncState.started or now)
        if outstanding == 0 and quiet >= 2 then
            craft.syncState.active = false
            craft.syncState.completed = now
            if self.SetStatus then
                if (tonumber(craft.syncState.received) or 0) > 0 then self:SetStatus("Crafting sync complete: " .. tostring(craft.syncState.received) .. " updated profession snapshot(s).")
                else self:SetStatus("Crafting sync complete: shared recipe database is already up to date.") end
            end
        end
    end
    BaseProcessCraftingTimers157(self)
end

-- ---------------------------------------------------------------------------
-- Professions UI: guaranteed safe icons and direct crafter interaction
-- ---------------------------------------------------------------------------

function OTLGM:BuildNextProfessionsPage(page)
    BaseBuildNextProfessionsPage157(self, page)
    self:BuildCrafterInteraction157(page)
end

function OTLGM:BuildCrafterInteraction157(page)
    if self.ui.crafterMenu157 then return end
    local crafters = self.ui.craftingRequestButton and self.ui.craftingRequestButton:GetParent()
    if not crafters then return end
    local shield = CreateFrame("Button", nil, self.ui.pages.professions or page)
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

function OTLGM:RefreshCraftingRecipesPanel(summary)
    BaseRefreshCraftingRecipesPanel157(self, summary)
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
    local oldPanel = self.ui and self.ui.pvePanels and self.ui.pvePanels.RAIDS
    local root = self.ui and self.ui.raidPlanner156
    if not oldPanel or not root then return end
    local children = { oldPanel:GetChildren() }
    local regions = { oldPanel:GetRegions() }
    local i
    for i = 1, table.getn(children) do if children[i] ~= root then HideTree157(children[i]) end end
    for i = 1, table.getn(regions) do regions[i]:Hide() end
    root:Show()
end

function OTLGM:BuildPvePage(page)
    BaseBuildPvePage157(self, page)
    self:BuildRaidEnhancements157()
    self:HideLegacyRaidUI157()
end

function OTLGM:BuildRaidEnhancements157()
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

function OTLGM:RefreshRaidDatePreview157()
    if not self.ui or not self.ui.raidDatePreview157 then return end
    local dayOffset = math.max(0, math.min(60, tonumber(self.ui.raidDay156 and self.ui.raidDay156:GetText()) or 0))
    local hour = math.max(0, math.min(23, tonumber(self.ui.raidHour156 and self.ui.raidHour156:GetText()) or 20))
    local minute = math.max(0, math.min(59, tonumber(self.ui.raidMinute156 and self.ui.raidMinute156:GetText()) or 0))
    local now = self:Now()
    local serverHour, serverMinute = 0, 0
    if GetGameTime then serverHour, serverMinute = GetGameTime() end
    serverHour = tonumber(serverHour) or tonumber(date("%H", now)) or 0
    serverMinute = tonumber(serverMinute) or tonumber(date("%M", now)) or 0
    local target = now - ((serverHour * 3600) + (serverMinute * 60)) + (dayOffset * 86400) + (hour * 3600) + (minute * 60)
    if target <= now and dayOffset == 0 then target = target + 86400 end
    self.ui.raidDatePreview157:SetText(date("%A, %d %B %Y", target) .. "  [" .. string.format("%02d:%02d", hour, minute) .. " ST]")
end

function OTLGM:OpenRaidEditor156(raid, duplicate)
    BaseOpenRaidEditor157(self, raid, duplicate)
    self.ui.raidFeatured157 = raid and raid.featured and true or false
    ButtonText157(self.ui.raidFeaturedButton157, self.ui.raidFeatured157 and "Main Raid: On" or "Main Raid: Off")
    SetButtonSelected157(self.ui.raidFeaturedButton157, self.ui.raidFeatured157)
    self:RefreshRaidDatePreview157()
end

function OTLGM:SaveRaidEditor156()
    local data = {
        name = self.ui.raidName156:GetText(), location = self.ui.raidLocation156:GetText(), note = self.ui.raidNote156:GetText(),
        dayOffset = self.ui.raidDay156:GetText(), hour = self.ui.raidHour156:GetText(), minute = self.ui.raidMinute156:GetText(),
        gatherHour = self.ui.raidGatherHour156:GetText(), gatherMinute = self.ui.raidGatherMinute156:GetText(),
        recurring = self.ui.raidRecurring156, reminderMinutes = self.ui.raidReminder156:GetText(), featured = self.ui.raidFeatured157,
    }
    local editId = self.ui.raidEditor156.editId156
    local ok, result = self:PublishPveRaidEvent156(data, editId)
    if ok then
        self.ui.raidEditor156:Hide()
        self.ui.raidFilter156 = "UPCOMING"
        self.ui.raidSelected156 = result.id
        self:RefreshRaidPlanner156()
        self:SetStatus(editId and "Raid event updated." or "New raid event created.")
    else self:ShowNotice("Raid Event", result or "The raid event could not be saved.") end
end

function OTLGM:PublishPveRaidEvent156(data, existingId)
    local ok, record = BasePublishPveRaidEvent157(self, data, existingId)
    if ok and record then
        local featured = data and data.featured and true or false
        if record.featured ~= featured then
            record.featured = featured
            record.rev = (tonumber(record.rev) or 0) + 1
            record.ts = self:Now()
            self:QueuePvePayload(self:SerializePveRaid(record), "GUILD")
        end
        self:QueueRaidMeta157(record)
    end
    return ok, record
end

function OTLGM:SerializePveRaid(record)
    -- Keep the core raid packet below the Vanilla 250-byte hard limit.
    return BaseSerializePveRaid157(self, record)
end

function OTLGM:QueueRaidMeta157(record, target)
    if not record or not record.id then return false end
    local payload = table.concat({
        self.pveProtocol, "RDMETA", tostring(record.id), tostring(record.rev or 1),
        record.featured and "1" or "0", Escape157(record.cancelReason or "", 60)
    }, "^")
    return self:QueuePvePayload(payload, target and "WHISPER" or "GUILD", target)
end

function OTLGM:ApplyRaidMeta157(fields)
    local id = fields[3] or ""
    local revision = tonumber(fields[4]) or 0
    if id == "" then return false end
    local pve = self:EnsureRaid156DB()
    if not pve then return false end
    pve.raidMeta157 = pve.raidMeta157 or {}
    local meta = { rev = revision, featured = fields[5] == "1", cancelReason = Unescape157(fields[6] or ""), ts = self:Now() }
    local record = self:GetRaidById156(id)
    if record and revision >= (tonumber(record.rev) or 0) then
        record.featured = meta.featured
        record.cancelReason = meta.cancelReason
    else
        local old = pve.raidMeta157[id]
        if not old or revision >= (tonumber(old.rev) or 0) then pve.raidMeta157[id] = meta end
    end
    return true
end

function OTLGM:ApplyRemotePveRaid(fields)
    local result = BaseApplyRemotePveRaid157(self, fields)
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
        if fields[2] == "RDMETA" then return self:ApplyRaidMeta157(fields) end
    end
    return BaseHandlePveAddonMessage157(self, message, channel, sender)
end

function OTLGM:QueuePveSyncResponse(target)
    local result = BaseQueuePveSyncResponse157(self, target)
    local pve = self:EnsureRaid156DB()
    local id, record
    for id, record in pairs(pve and pve.raids or {}) do self:QueueRaidMeta157(record, target) end
    for id, record in pairs(pve and pve.cancelledRaids156 or {}) do self:QueueRaidMeta157(record, target) end
    return result
end

function OTLGM:GetRaidList156(filter)
    local list = BaseGetRaidList157(self, filter)
    if filter == "UPCOMING" then
        local pve = self:EnsureRaid156DB()
        local id, record
        for id, record in pairs(pve and pve.cancelledRaids156 or {}) do
            if (tonumber(record.startTs) or 0) + 14400 >= self:Now() then table.insert(list, record) end
        end
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

function OTLGM:RefreshRaidPlanner156()
    BaseRefreshRaidPlanner157(self)
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
    BaseRefreshPvePage157(self)
    self:HideLegacyRaidUI157()
    self:RefreshRaidPlanner156()
end

function OTLGM:RefreshHomePveSummary155()
    BaseRefreshHomePveSummary157(self)
    if not self.ui or not self.ui.homeRaidText then return end
    local all = self:GetRaidList156("UPCOMING")
    local active = {}
    local i, raid
    for i = 1, table.getn(all) do
        raid = all[i]
        if raid.status ~= "CANCELLED" and (raid.startTs or 0) >= self:Now() - 60 then table.insert(active, raid) end
    end
    table.sort(active, function(a, b) return (a.startTs or 0) < (b.startTs or 0) end)
    local lines = {}
    for i = 1, math.min(3, table.getn(active)) do
        raid = active[i]
        table.insert(lines, (raid.featured and "|cffffcc44★|r " or "") .. (raid.name or "Guild Raid") .. "  [" .. string.format("%02d:%02d", tonumber(raid.stHour) or 0, tonumber(raid.stMinute) or 0) .. " ST]")
    end
    if table.getn(lines) == 0 then table.insert(lines, "|cff888888No raid scheduled|r") end
    self.ui.homeRaidText:SetText(table.concat(lines, "\n"))
end

-- ---------------------------------------------------------------------------
-- New announcement means a clean form. Editing still loads existing content.
-- ---------------------------------------------------------------------------

function OTLGM:OpenAnnouncementComposer152(id)
    BaseOpenAnnouncementComposer157(self, id)
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
        dialog.titleEdit:SetFocus()
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
    local source = BaseGetActivityEntries157(self, mode, "ALL") or {}
    local result = {}
    local i
    for i = 1, table.getn(source) do if ActivityMatch157(source[i], filter or "ALL") then table.insert(result, source[i]) end end
    table.sort(result, function(a, b) return (a.ts or 0) > (b.ts or 0) end)
    while table.getn(result) > 60 do table.remove(result) end
    return result
end

function OTLGM:BuildActivityDialogs153()
    BaseBuildActivityDialogs157(self)
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
        return BaseRefreshActivityDialog157(self)
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

function OTLGM:SetCommunityReaction(targetType, targetId, reaction, force)
    if string.upper(targetType or "") == "RAID" and string.upper(reaction or "") == "READY" and not self:IsRaidNoticeEligible() then
        if self.ShowNotice then self:ShowNotice("Raider Role Required", "You can mark the raid as Seen, but Ready requires an approved raider guild role. Register in the guild Discord under your in-game name.") end
        return false
    end
    return BaseSetCommunityReaction157(self, targetType, targetId, reaction, force)
end

-- ---------------------------------------------------------------------------
-- Context menus: stable during chat updates, but easy to close again
-- ---------------------------------------------------------------------------

function OTLGM:RefreshGuildChatPage()
    local menu = self.ui and self.ui.chatNameMenu
    local wasVisible = menu and menu:IsVisible()
    local target = menu and menu.targetName
    local result = BaseRefreshGuildChatPage157(self)
    if wasVisible and menu and target and (OTLGM_DB.settings.guildChatView or "GUILD") ~= "BOARD" then
        menu.targetName = target
        if self.ui.chatMenuShield157 then self.ui.chatMenuShield157:Show() end
        menu:Show()
    end
    return result
end

function OTLGM:EnsureChatMenuShield157()
    if not self.ui or not self.ui.chatNameMenu or self.ui.chatMenuShield157 then return end
    local page = self.ui.pages and self.ui.pages.guildchat
    if not page then return end
    local shield = CreateFrame("Button", nil, page)
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
    BaseOpenGuildChatNameMenu157(self, sender, owner)
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
    return BaseCloseTopModal157(self)
end

function OTLGM:GetDiagnosticsText()
    local base = BaseGetDiagnosticsText157 and BaseGetDiagnosticsText157(self) or ""
    local craft = BaseEnsureCraftingDB157(self)
    local cache = craft and self:EnsureCraftingIconCache157(craft)
    local pve = self.EnsureRaid156DB and self:EnsureRaid156DB() or nil
    return base ..
        "\nQuality 1.5.7: Loaded" ..
        "\nCrafting manifest sync: " .. tostring(self.HandleCraftingManifest157 and "Available" or "Unavailable") ..
        "\nCrafting icon cache items/names: " .. tostring(Count157(cache and cache.items)) .. "/" .. tostring(Count157(cache and cache.names)) ..
        "\nCrafting manifest received/requested: " .. tostring(craft and craft.syncState and craft.syncState.manifests157 or 0) .. "/" .. tostring(craft and craft.syncState and craft.syncState.requested157 or 0) ..
        "\nRaid metadata cache: " .. tostring(Count157(pve and pve.raidMeta157)) ..
        "\nPersistent chat menu shield: " .. tostring(self.ui and self.ui.chatMenuShield157 and "Loaded" or "Not built yet")
end

function OTLGM:BuildNextUI()
    BaseBuildNextUI157(self)
    self:EnsureChatMenuShield157()
    if OTLGM_DB then OTLGM_DB.schemaVersion = 12 end
end

-- Keep the icon cache bounded without polling. This is called by the existing
-- one-second heartbeat, but the expensive prune runs only once every six hours.
local BaseProcessQuality156Timers157 = OTLGM.ProcessQuality156Timers
function OTLGM:ProcessQuality156Timers()
    BaseProcessQuality156Timers157(self)
    local now = self:Now()
    if not self.lastIconPrune157 or now - self.lastIconPrune157 > 21600 then self.lastIconPrune157 = now self:PruneCraftingIconCache157() end
end
