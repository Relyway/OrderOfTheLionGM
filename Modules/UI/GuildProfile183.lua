-- Order of the Lion Guild Manager 1.8.3
-- Lazy, cache-only Guild Profile companion. No event frame, scheduler task,
-- network request, roster request, profession scan or permanent OnUpdate.

if not OTLGM or not OTLGM.UI then return end

local UI = OTLGM.UI
local C = UI.colors
local PROFILE_WIDTH_183 = 400
local PROFILE_HEIGHT_183 = 680
local BODY_WIDTH_183 = 344
local BODY_VIEW_HEIGHT_183 = 514
local CARD_GAP_183 = 9
local PROFILE_DOCK_GAP_183 = 12
local PROFILE_SNAP_ZONE_183 = 44
local INITIAL_PROFILE_PROFESSION_ROWS_183 = 4
local MAX_PROFILE_PROFESSION_ROWS_183 = 12
local EnsureGuildProfileProfessionRows183

local CLASS_COORDS_183 = {
    WARRIOR = { 0, 0.25, 0, 0.25 }, MAGE = { 0.25, 0.496, 0, 0.25 },
    ROGUE = { 0.496, 0.742, 0, 0.25 }, DRUID = { 0.742, 0.988, 0, 0.25 },
    HUNTER = { 0, 0.25, 0.25, 0.5 }, SHAMAN = { 0.25, 0.496, 0.25, 0.5 },
    PRIEST = { 0.496, 0.742, 0.25, 0.5 }, WARLOCK = { 0.742, 0.988, 0.25, 0.5 },
    PALADIN = { 0, 0.25, 0.5, 0.75 },
}

local CLASS_RGB_183 = {
    WARRIOR = { 0.78, 0.61, 0.43 }, MAGE = { 0.41, 0.80, 0.94 },
    ROGUE = { 1.00, 0.96, 0.41 }, DRUID = { 1.00, 0.49, 0.04 },
    HUNTER = { 0.67, 0.83, 0.45 }, SHAMAN = { 0.00, 0.44, 0.87 },
    PRIEST = { 0.94, 0.94, 0.94 }, WARLOCK = { 0.58, 0.51, 0.79 },
    PALADIN = { 0.96, 0.55, 0.73 },
}

local PROFILE_SECTION_ICONS_183 = {
    ABOUT = "Interface\\Icons\\INV_Misc_Note_06",
    IDENTITY = "Interface\\Icons\\INV_Misc_GroupNeedMore",
    JOURNEY = "Interface\\Icons\\INV_Misc_Map_01",
    ACHIEVEMENTS = "Interface\\Icons\\INV_Misc_Medal_01",
    GOALS = "Interface\\Icons\\INV_Misc_Note_02",
    PROFESSIONS = "Interface\\Icons\\Trade_BlackSmithing",
    ACTIVITY = "Interface\\Icons\\INV_Misc_PocketWatch_01",
}

local function ClassRGB183(className)
    local value = CLASS_RGB_183[string.upper(tostring(className or ""))]
    if value then return value[1], value[2], value[3] end
    return C.gold[1], C.gold[2], C.gold[3]
end

local function ProfileLabel183(parent, value, template, x, y, width, justify)
    local label = UI.Text(parent, value or "", template or "GameFontNormalSmall", justify or "LEFT")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 0, y or 0)
    if width then label:SetWidth(width) end
    return label
end

local function Short183(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or 60
    if string.len(value) <= maximum then return value end
    return string.sub(value, 1, math.max(1, maximum - 3)) .. "..."
end

local function ApplyClassIcon183(texture, className)
    if not texture then return end
    local coordinates = CLASS_COORDS_183[string.upper(tostring(className or ""))]
    if coordinates then
        texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
        texture:SetTexCoord(coordinates[1], coordinates[2], coordinates[3], coordinates[4])
    else
        texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        texture:SetTexCoord(0, 1, 0, 1)
    end
end

local function AddSpecialFrame183(name)
    if not name then return end
    UISpecialFrames = UISpecialFrames or {}
    local index
    for index = 1, table.getn(UISpecialFrames) do if UISpecialFrames[index] == name then return end end
    table.insert(UISpecialFrames, name)
end

local function NormalizeProfileName183(owner, name)
    if owner.NormalizeName then return owner:NormalizeName(name or "") end
    name = string.gsub(tostring(name or ""), "^%s+", "")
    name = string.gsub(name, "%s+$", "")
    name = string.gsub(name, "%-.*$", "")
    return string.lower(name)
end

local function IsSelf183(owner, name)
    local player = UnitName and UnitName("player") or ""
    return NormalizeProfileName183(owner, player) ~= ""
        and NormalizeProfileName183(owner, player) == NormalizeProfileName183(owner, name)
end

local function FriendlyAge183(owner, timestamp)
    timestamp = tonumber(timestamp)
    if not timestamp or timestamp <= 0 then return "unknown" end
    local elapsed = math.max(0, owner:Now() - timestamp)
    if elapsed < 60 then return "just now" end
    if elapsed < 3600 then return tostring(math.floor(elapsed / 60)) .. "m ago" end
    if elapsed < 86400 then return tostring(math.floor(elapsed / 3600)) .. "h ago" end
    return tostring(math.floor(elapsed / 86400)) .. "d ago"
end

local function KnownDuration183(owner, timestamp)
    timestamp = tonumber(timestamp)
    if not timestamp or timestamp <= 0 then return nil end
    local days = math.max(0, math.floor((owner:Now() - timestamp) / 86400))
    if days < 1 then return "today" end
    if days < 30 then return tostring(days) .. " day" .. (days == 1 and "" or "s") end
    if days < 365 then return tostring(math.floor(days / 30)) .. " month(s)" end
    local years = math.floor(days / 365)
    local months = math.floor(math.mod(days, 365) / 30)
    return tostring(years) .. "y" .. (months > 0 and (" " .. tostring(months) .. "m") or "")
end

local function Freshness183(owner, timestamp)
    timestamp = tonumber(timestamp)
    if not timestamp or timestamp <= 0 then return "Unknown", C.grey end
    local elapsed = math.max(0, owner:Now() - timestamp)
    if elapsed <= 300 then return "Live", C.green end
    if elapsed <= 7 * 86400 then return "Recent", C.gold end
    return "Stored", C.grey
end

-- r49 deliberately derives Journey/category presentation from data that already
-- exists in the roster and achievement-detail cache.  No new SavedVariables,
-- events, timers, polling or profile packets are required.
local PROFILE_CATEGORY_ORDER_R49 = {
    { key="SOCIAL", label="Social" },
    { key="DUNGEONS", label="Dungeons" },
    { key="RAIDS", label="Raids" },
    { key="PROFESSIONS", label="Prof" },
    { key="GROUP_FINDER", label="Group" },
    { key="LEGACY", label="Legacy" },
    { key="SECRETS", label="Secrets" },
}

local function CategoryPairR49(completed, totals, categoryKey, label)
    return tostring(label) .. " " .. tostring(completed[categoryKey] or 0) .. "/" .. tostring(totals[categoryKey] or 0)
end

local function AddJourneyMilestoneR49(list, label, timestamp, kind, note)
    timestamp = tonumber(timestamp) or 0
    local record = { label=label, ts=timestamp, kind=kind or "MILESTONE", note=note }
    table.insert(list, record)
    return record
end

local function AchievementCategoryProgressR49(owner, details)
    if type(details) ~= "table" or type(details.completedMap) ~= "table" then return nil end
    local catalog = owner.achievements174 and owner.achievements174.catalog or {}
    local totals, completed = {}, {}
    local index, entry, key
    for index = 1, table.getn(PROFILE_CATEGORY_ORDER_R49) do
        key = PROFILE_CATEGORY_ORDER_R49[index].key
        totals[key], completed[key] = 0, 0
    end
    for index = 1, table.getn(catalog) do
        entry = catalog[index]
        key = entry and entry.category or nil
        if totals[key] ~= nil then
            totals[key] = totals[key] + 1
            if entry.id and details.completedMap[entry.id] then completed[key] = completed[key] + 1 end
        end
    end
    return {
        line1 = CategoryPairR49(completed, totals, "SOCIAL", "Social") .. "  •  " .. CategoryPairR49(completed, totals, "DUNGEONS", "Dungeons") .. "  •  " .. CategoryPairR49(completed, totals, "RAIDS", "Raids"),
        line2 = CategoryPairR49(completed, totals, "PROFESSIONS", "Prof") .. "  •  " .. CategoryPairR49(completed, totals, "GROUP_FINDER", "Group") .. "  •  " .. CategoryPairR49(completed, totals, "LEGACY", "Legacy") .. "  •  " .. CategoryPairR49(completed, totals, "SECRETS", "Secrets"),
        totals = totals, completed = completed,
    }
end

local function JourneyMilestonesR49(owner, member, details)
    local list = {}
    local recentReturn = nil
    if tonumber(member.returnedAt) and tonumber(member.returnedAt) > 0 then
        local days = math.max(0, tonumber(member.returnAfterDays) or 0)
        recentReturn = AddJourneyMilestoneR49(list, "Returned after " .. tostring(days) .. " day" .. (days == 1 and "" or "s"), member.returnedAt, "RETURN")
    end
    if tonumber(member.lastMilestone) == 60 and tonumber(member.lastMilestoneAt) and tonumber(member.lastMilestoneAt) > 0 then
        AddJourneyMilestoneR49(list, "Reached level 60", member.lastMilestoneAt, "LEVEL")
    end
    if tonumber(member.promotedAt) and tonumber(member.promotedAt) > 0
        and (not tonumber(member.rankChangedAt) or tonumber(member.promotedAt) >= tonumber(member.rankChangedAt)) then
        AddJourneyMilestoneR49(list, "Promoted to " .. tostring(member.rank or "current rank"), member.promotedAt, "RANK")
    end
    local map = details and details.completedMap or nil
    local times = details and details.completedAtMap or nil
    if type(map) == "table" then
        if map.A041 then AddJourneyMilestoneR49(list, "First guild commission", times and times.A041 or 0, "CRAFT") end
        if map.A043 then AddJourneyMilestoneR49(list, "First guild dungeon", times and times.A043 or 0, "DUNGEON") end
        local raidTime = nil
        if map.A053 then raidTime = times and times.A053 or 0 end
        if map.A055 then
            local trophyTime = times and times.A055 or 0
            if not raidTime or raidTime <= 0 or (trophyTime > 0 and trophyTime < raidTime) then raidTime = trophyTime end
        end
        if map.A053 or map.A055 then AddJourneyMilestoneR49(list, "First guild raid", raidTime or 0, "RAID") end
    end
    table.sort(list, function(left, right)
        local lts, rts = tonumber(left.ts) or 0, tonumber(right.ts) or 0
        if lts ~= rts then return lts > rts end
        return tostring(left.label or "") < tostring(right.label or "")
    end)
    -- A genuine recent return is socially useful context, so keep it visible for
    -- 30 days even if the member immediately earns several newer milestones.
    if recentReturn and tonumber(recentReturn.ts) and (owner:Now() - tonumber(recentReturn.ts)) <= 30 * 86400 then
        local returnIndex = nil
        local scanIndex
        for scanIndex = 1, table.getn(list) do if list[scanIndex] == recentReturn then returnIndex = scanIndex break end end
        if returnIndex and returnIndex > 3 then
            table.remove(list, returnIndex)
            table.insert(list, 3, recentReturn)
        end
    end
    while table.getn(list) > 3 do table.remove(list) end
    return list
end

local function NewProfileCard183(parent, title, accent, iconPath)
    local card = UI:Card(parent, BODY_WIDTH_183, 80, title)
    accent = accent or C.gold
    card.accent183 = card:CreateTexture(nil, "ARTWORK")
    card.accent183:SetPoint("TOPLEFT", card, "TOPLEFT", 3, -3)
    card.accent183:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 3, 3)
    card.accent183:SetWidth(3)
    card.accent183:SetTexture(accent[1], accent[2], accent[3], 0.92)
    card.topGlow183 = card:CreateTexture(nil, "ARTWORK")
    card.topGlow183:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -2)
    card.topGlow183:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -2)
    card.topGlow183:SetHeight(1)
    card.topGlow183:SetTexture(accent[1], accent[2], accent[3], 0.34)
    if iconPath then
        if card.titleMarker184 then card.titleMarker184:Hide() end
        card.sectionIcon183 = card:CreateTexture(nil, "ARTWORK")
        card.sectionIcon183:SetTexture(iconPath)
        card.sectionIcon183:SetWidth(16) card.sectionIcon183:SetHeight(16)
        card.sectionIcon183:SetPoint("TOPLEFT", card, "TOPLEFT", 11, -8)
        if card.sectionIcon183.SetVertexColor then card.sectionIcon183:SetVertexColor(accent[1], accent[2], accent[3]) end
        if card.title then
            card.title:ClearAllPoints()
            card.title:SetPoint("TOPLEFT", card, "TOPLEFT", 32, -9)
            card.title:SetWidth(BODY_WIDTH_183 - 42)
        end
    end
    if card.title then card.title:SetTextColor(accent[1], accent[2], accent[3]) end
    if card.SetBackdropBorderColor then card:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.48) end
    card:Hide()
    return card
end

function OTLGM:GetGuildProfileRecord183(name)
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local records = db and db.guildProfiles183
    if type(records) ~= "table" then return nil end
    local normalized = NormalizeProfileName183(self, name)
    local record = records[normalized] or records[tostring(name or "")]
    return type(record) == "table" and record or nil
end

function OTLGM:GetGuildProfileAchievementSnapshot183(name)
    local shared = self:GetGuildProfileRecord183(name)
    if not IsSelf183(self, name) then
        local achievement = shared and shared.achievements
        if type(achievement) ~= "table" then return { known = false, recent = {} } end
        local completed = math.max(0, tonumber(achievement.completed) or 0)
        local total = math.max(completed, tonumber(achievement.total) or 0)
        local recent = type(achievement.recent) == "table" and achievement.recent or {}
        return {
            known = total > 0, completed = completed, total = total,
            updatedAt = tonumber(achievement.updatedAt or shared.updatedAt), recent = recent,
            rank = tonumber(achievement.rank), coverage = tonumber(achievement.coverage),
        }
    end

    local guild = self.GetGuildDB and self:GetGuildDB() or nil
    local key = self.GetAchievementCharacterKey174 and self:GetAchievementCharacterKey174() or nil
    local character = key and guild and guild.achievements174 and guild.achievements174.characters
        and guild.achievements174.characters[key] or nil
    local completedMap = character and character.completed
    local catalog = self.achievements174 and self.achievements174.catalog or {}
    local byId = self.achievements174 and self.achievements174.byId or {}
    if type(completedMap) ~= "table" then return { known = false, recent = {} } end
    local completed, recent = 0, {}
    local id, record
    for id, record in pairs(completedMap) do
        if byId[id] then
            completed = completed + 1
            table.insert(recent, {
                id = id, name = byId[id].name or id,
                ts = type(record) == "table" and tonumber(record.unlockedAt) or tonumber(record),
            })
        end
    end
    table.sort(recent, function(left, right)
        local leftTime, rightTime = tonumber(left.ts) or 0, tonumber(right.ts) or 0
        if leftTime ~= rightTime then return leftTime > rightTime end
        return tostring(left.id or "") < tostring(right.id or "")
    end)
    while table.getn(recent) > 3 do table.remove(recent) end
    return { known = true, completed = completed, total = table.getn(catalog), recent = recent, localOwner = true }
end

function OTLGM:GetGuildProfileRecipeCount183(name, professionKey, profession)
    if type(profession) ~= "table" or type(profession.recipes) ~= "table" then return nil end
    self.runtime = self.runtime or {}
    self.runtime.guildProfileRecipeCounts183 = self.runtime.guildProfileRecipeCounts183 or {}
    local cache = self.runtime.guildProfileRecipeCounts183
    local signature = NormalizeProfileName183(self, name) .. ":" .. tostring(professionKey or "") .. ":"
        .. tostring(profession.hash or "") .. ":" .. tostring(tonumber(profession.ts) or 0)
    if cache[signature] ~= nil then return cache[signature] end
    local count, key = 0, nil
    for key in pairs(profession.recipes) do count = count + 1 end
    local entries, cacheKey = 0, nil
    for cacheKey in pairs(cache) do entries = entries + 1 end
    if entries >= 64 then cache = {} self.runtime.guildProfileRecipeCounts183 = cache end
    cache[signature] = count
    return count
end

function OTLGM:GetGuildProfileProfessions183(name)
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    local characters = db and db.crafting and db.crafting.characters
    if type(characters) ~= "table" then return {} end
    local shortName = string.gsub(tostring(name or ""), "%-.*$", "")
    local character = characters[tostring(name or "")] or characters[shortName]
    if type(character) ~= "table" or type(character.professions) ~= "table" then return {} end
    local result = {}
    local professionKey, profession
    for professionKey, profession in pairs(character.professions) do
        if type(profession) == "table" then
            local definition = self.GetCraftingProfessionDefinition183 and self:GetCraftingProfessionDefinition183(professionKey) or nil
            table.insert(result, {
                key = professionKey,
                label = tostring(profession.label or definition and definition.label or professionKey),
                icon = definition and definition.icon or "Interface\\Icons\\INV_Misc_Book_09",
                rank = tonumber(profession.rank), maxRank = tonumber(profession.maxRank),
                ts = tonumber(profession.ts or character.updated), profession = profession,
                sourceLabel = character.localOwner and "This character"
                    or tostring(profession.sourceLabel183 or profession.source183 or "Guild sharing"),
            })
        end
    end
    table.sort(result, function(left, right)
        local leftLabel, rightLabel = string.lower(tostring(left.label or "")), string.lower(tostring(right.label or ""))
        if leftLabel ~= rightLabel then return leftLabel < rightLabel end
        return tostring(left.key or "") < tostring(right.key or "")
    end)
    -- The canonical crafting registry currently fits well below this corrupted-
    -- data guard.  Unlike RC2's four-row truncation, every realistic primary,
    -- secondary and custom profession (including Survival/Jewelcrafting) stays
    -- visible in the Profile's existing common scroll.
    while table.getn(result) > MAX_PROFILE_PROFESSION_ROWS_183 do table.remove(result) end
    local index
    for index = 1, table.getn(result) do
        result[index].recipeCount = self:GetGuildProfileRecipeCount183(name, result[index].key, result[index].profession)
    end
    return result
end

function OTLGM:GetGuildProfileHistory183(name)
    local details = self.ui and self.ui.rosterDetails
    if details and details.otlHistoryName183
        and NormalizeProfileName183(self, details.otlHistoryName183) == NormalizeProfileName183(self, name)
        and type(details.otlHistory183) == "table" then
        local result = {}
        local index
        for index = 1, math.min(3, table.getn(details.otlHistory183)) do result[index] = details.otlHistory183[index] end
        return result
    end
    self.runtime = self.runtime or {}
    self.runtime.guildProfileMetrics183 = self.runtime.guildProfileMetrics183 or {}
    self.runtime.guildProfileMetrics183.historyFallbacks = (tonumber(self.runtime.guildProfileMetrics183.historyFallbacks) or 0) + 1
    return self.GetMemberRecentHistory and self:GetMemberRecentHistory(name, 3) or {}
end

function OTLGM:GetGuildProfileSnapshot183(name)
    local member = self.GetMember and self:GetMember(name) or nil
    if not member then return nil end
    local shared = self:GetGuildProfileRecord183(member.name)
    local knownSince = tonumber(member.joinedAt) or tonumber(member.trackedSince) or tonumber(member.firstSeenAt)
    local detailsR49 = self.GetGuildAchievementDetailsR42 and self:GetGuildAchievementDetailsR42(member.name) or nil
    return {
        member = member,
        selfProfile = IsSelf183(self, member.name),
        about = shared and tostring(shared.about or "") or "",
        knownSince = knownSince,
        knownDuration = KnownDuration183(self, knownSince),
        achievements = self:GetGuildProfileAchievementSnapshot183(member.name),
        achievementDetailsR49 = detailsR49,
        achievementCategoryR49 = AchievementCategoryProgressR49(self, detailsR49),
        journeyMilestonesR49 = JourneyMilestonesR49(self, member, detailsR49),
        professions = self:GetGuildProfileProfessions183(member.name),
        activity = self:GetGuildProfileHistory183(member.name),
        goals = self.GetTrackedAchievementGoals183 and self:GetTrackedAchievementGoals183() or {},
        identity184 = self.GetCharacterIdentityView184 and self:GetCharacterIdentityView184(member.name) or nil,
        profileIdentityR48 = self.GetGuildProfileIdentityR48 and self:GetGuildProfileIdentityR48(member.name, detailsR49) or { titleKey="NONE", titleLabel=nil, showcase={} },
        sharedAt = shared and tonumber(shared.updatedAt) or nil,
    }
end

function OTLGM:UpdateGuildProfileScroll183(contentHeight)
    local frame = self.ui and self.ui.guildProfile183
    if not frame then return end
    contentHeight = math.max(BODY_VIEW_HEIGHT_183, tonumber(contentHeight) or BODY_VIEW_HEIGHT_183)
    frame.body:SetHeight(contentHeight)
    local maximum = math.max(0, contentHeight - BODY_VIEW_HEIGHT_183)
    local current = math.max(0, math.min(maximum, tonumber(frame.otlScroll183) or 0))
    frame.otlScroll183 = current
    frame.scrollbar.otlSilent = true
    frame.scrollbar:SetMinMaxValues(0, maximum)
    frame.scrollbar:SetValue(current)
    frame.scrollbar.otlSilent = nil
    frame.scroll:SetVerticalScroll(current)
    if frame.scroll.UpdateScrollChildRect then frame.scroll:UpdateScrollChildRect() end
end

function OTLGM:RefreshGuildProfile183(reason)
    local frame = self.ui and self.ui.guildProfile183
    if not frame or not frame.otlMemberName183 then return false end
    local snapshot = self:GetGuildProfileSnapshot183(frame.otlMemberName183)
    if not snapshot then self:CloseGuildProfile183("member-missing") return false end
    local member = snapshot.member
    ApplyClassIcon183(frame.classIcon, member.class)
    local classR, classG, classB = ClassRGB183(member.class)
    if frame.classIconFrame183 and frame.classIconFrame183.SetBackdropBorderColor then
        frame.classIconFrame183:SetBackdropBorderColor(classR, classG, classB, 0.92)
    end
    if frame.headerAccent183 then frame.headerAccent183:SetTexture(classR, classG, classB, 0.96) end
    if frame.headerLine then frame.headerLine:SetTexture(classR, classG, classB, 0.52) end
    frame.nameText:SetText(self:GetClassColor(member.class) .. tostring(member.name or "Guild member") .. self.colors.reset)
    frame.identityText:SetText("Level " .. tostring(member.level or 0) .. "  •  " .. tostring(member.class or "Unknown"))

    local rankIndexR48 = tonumber(member.rankIndex)
    local rankTextR48 = string.lower(tostring(member.rank or ""))
    local guildLeaderR48 = rankIndexR48 == 0
    local leadershipR48 = guildLeaderR48 or (rankIndexR48 ~= nil and rankIndexR48 <= 2)
        or string.find(rankTextR48, "officer", 1, true) ~= nil
        or string.find(rankTextR48, "guild leader", 1, true) ~= nil
    local themeR48 = self.theme or {}
    if frame.SetBackdropBorderColor then
        if guildLeaderR48 then frame:SetBackdropBorderColor(C.gold[1], C.gold[2], C.gold[3], 0.98)
        elseif leadershipR48 then frame:SetBackdropBorderColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3], 0.82)
        else
            local borderR48 = themeR48.borderSoft or { 0.15, 0.15, 0.14, 0.88 }
            frame:SetBackdropBorderColor(borderR48[1], borderR48[2], borderR48[3], borderR48[4] or 0.88)
        end
    end
    if frame.prestigeIconR48 then
        if guildLeaderR48 then
            frame.prestigeIconR48:SetTexture("Interface\\Icons\\INV_Crown_01")
            frame.prestigeIconR48:Show()
            frame.windowTitle:SetText("GUILD PROFILE  •  GUILD LEADER")
        else
            frame.prestigeIconR48:Hide()
            frame.windowTitle:SetText(leadershipR48 and "GUILD PROFILE  •  LEADERSHIP" or "GUILD PROFILE")
        end
    end
    if frame.rankBadge183 then
        frame.rankBadge183.text:SetText(Short183(member.rank or "Guild member", 18))
        if frame.rankBadge183.SetBackdropBorderColor then
            if guildLeaderR48 then frame.rankBadge183:SetBackdropBorderColor(C.gold[1], C.gold[2], C.gold[3], 0.95)
            elseif leadershipR48 then frame.rankBadge183:SetBackdropBorderColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3], 0.86)
            else frame.rankBadge183:SetBackdropBorderColor(classR, classG, classB, 0.80) end
        end
        frame.rankBadge183:Show()
    end

    local profileIdentityR48 = snapshot.profileIdentityR48 or {}
    if frame.titleBadgeR48 and profileIdentityR48.titleLabel then
        frame.titleBadgeR48.text:SetText(Short183(profileIdentityR48.titleLabel, 18))
        frame.titleBadgeR48:Show()
        frame.statusText:SetWidth(158)
    elseif frame.titleBadgeR48 then
        frame.titleBadgeR48:Hide()
        frame.statusText:SetWidth(260)
    end
    frame.statusDot:SetTexture(member.online and C.green[1] or C.grey[1], member.online and C.green[2] or C.grey[2], member.online and C.green[3] or C.grey[3], 1)
    frame.statusText:SetText(member.online and ("Online  •  " .. tostring(member.zone or "Unknown zone"))
        or ("Offline  •  " .. FriendlyAge183(self, member.lastSeen)))
    frame.statusText:SetTextColor(member.online and C.green[1] or C.grey[1], member.online and C.green[2] or C.grey[2], member.online and C.green[3] or C.grey[3])

    local cursor = 0
    local function Place(card, height)
        card.otlProfileTop183 = cursor
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", frame.body, "TOPLEFT", 0, -cursor)
        card:SetWidth(BODY_WIDTH_183)
        card:SetHeight(height)
        if card.title then card.title:SetWidth(card.sectionIcon183 and (BODY_WIDTH_183 - 42) or (BODY_WIDTH_183 - 20)) end
        card:Show()
        cursor = cursor + height + CARD_GAP_183
    end

    if snapshot.about ~= "" then
        frame.about.text:SetText(snapshot.about)
        Place(frame.about, 72)
    else
        frame.about:Hide()
    end

    local identity184 = snapshot.identity184
    local relatedCountR42 = 0
    if frame.characterIdentity184.relatedRowsR42 then
        local relatedIndexR42
        for relatedIndexR42 = 1, table.getn(frame.characterIdentity184.relatedRowsR42) do
            frame.characterIdentity184.relatedRowsR42[relatedIndexR42].otlRelatedNameR42 = nil
            frame.characterIdentity184.relatedRowsR42[relatedIndexR42]:Hide()
        end
    end
    if snapshot.selfProfile or (identity184 and (identity184.verified or identity184.localConfirmed)) then
        if snapshot.selfProfile then
            frame.characterIdentity184.view:Hide()
            local pendingIdentity184 = identity184 and tonumber(identity184.pendingCount) or 0
            UI:SetText(frame.characterIdentity184.manage, pendingIdentity184 > 0 and ("Review " .. tostring(pendingIdentity184)) or "Manage")
            frame.characterIdentity184.manage.otlStyle = pendingIdentity184 > 0 and "primary" or "utility"
            frame.characterIdentity184.manage.otlTooltipTitle = pendingIdentity184 > 0 and "Main / Alt requests need review" or "Main / Alt identity"
            frame.characterIdentity184.manage.otlTooltip = pendingIdentity184 > 0
                and (tostring(pendingIdentity184) .. " pending alt request(s). Open the manager to confirm or decline them.")
                or "Link this character to a main, review linked alts, or remove a voluntary character link."
            UI:SetSelected(frame.characterIdentity184.manage, false)
            frame.characterIdentity184.manage:Show()
            if identity184 and identity184.role == "ALT" then
                frame.characterIdentity184.line1:SetText(self.colors.gold .. "Alt character" .. self.colors.reset)
                frame.characterIdentity184.line2:SetText(identity184.counterpartInGuild == false
                    and (self.colors.grey .. "Main not currently in guild  •  link kept locally" .. self.colors.reset)
                    or identity184.state == "CONFIRMED"
                        and (self.colors.green .. "Confirmed" .. self.colors.reset .. self.colors.grey .. "  •  shared after both characters verify" .. self.colors.reset)
                        or (self.colors.orange .. "Waiting for main confirmation" .. self.colors.reset))
            elseif identity184 and identity184.role == "MAIN" then
                frame.characterIdentity184.line1:SetText(self.colors.gold .. "Main character" .. self.colors.reset .. "  •  "
                    .. tostring(identity184.confirmedCount or 0) .. " linked alt(s)")
                local outsideGuild184 = math.max(0, (tonumber(identity184.confirmedCount) or 0) - (tonumber(identity184.rosterAltCount) or 0))
                frame.characterIdentity184.line2:SetText((tonumber(identity184.pendingCount) or 0) > 0
                    and (self.colors.orange .. tostring(identity184.pendingCount) .. " request(s) waiting for confirmation" .. self.colors.reset)
                    or outsideGuild184 > 0
                        and (self.colors.grey .. tostring(outsideGuild184) .. " alt(s) outside guild  •  not shared" .. self.colors.reset)
                        or (self.colors.grey .. "No pending alt requests." .. self.colors.reset))
            else
                frame.characterIdentity184.line1:SetText("No Main/Alt link is set for this character.")
                frame.characterIdentity184.line2:SetText(self.colors.grey .. "Optional and never automatic." .. self.colors.reset)
            end
        else
            frame.characterIdentity184.manage:Hide()
            UI:SetText(frame.characterIdentity184.view, identity184.role == "ALT" and "View Main" or "View Alts")
            frame.characterIdentity184.view:Show()
            if identity184.role == "ALT" then
                frame.characterIdentity184.line1:SetText(self.colors.gold .. "Alt character" .. self.colors.reset)
                frame.characterIdentity184.line2:SetText(identity184.counterpartInGuild == false
                    and (self.colors.grey .. "Main not currently in guild" .. self.colors.reset)
                    or identity184.verified
                        and (self.colors.green .. "Verified by both characters" .. self.colors.reset)
                        or (self.colors.gold .. "Confirmed here" .. self.colors.reset .. self.colors.grey .. "  •  waiting for matching share" .. self.colors.reset))
            else
                local altText = table.concat(identity184.alts or {}, ", ")
                frame.characterIdentity184.line1:SetText(self.colors.gold .. "Linked alts  " .. self.colors.reset .. (altText ~= "" and Short183(altText, 46) or "No current-guild alts"))
                frame.characterIdentity184.line2:SetText(identity184.counterpartInGuild == false
                    and (self.colors.grey .. "Linked character(s) not currently in guild" .. self.colors.reset)
                    or identity184.verified
                        and (self.colors.green .. "Verified by both characters" .. self.colors.reset)
                        or (self.colors.gold .. "Confirmed here" .. self.colors.reset .. self.colors.grey .. "  •  waiting for matching share" .. self.colors.reset))
            end
        end
        frame.characterIdentity184.line1:SetWidth(snapshot.selfProfile and 230 or 315)
        if identity184 and frame.characterIdentity184.relatedRowsR42 then
            if identity184.role == "MAIN" then
                local linkedR42 = identity184.alts or {}
                local sourceIndexR42, relatedNameR42, relatedRowR42
                for sourceIndexR42 = 1, table.getn(linkedR42) do
                    if relatedCountR42 >= 6 then break end
                    relatedNameR42 = linkedR42[sourceIndexR42]
                    -- Direct profile links are useful only for characters that are
                    -- actually present in the current guild roster. Persisted links
                    -- outside the guild remain represented by the status text above.
                    if relatedNameR42 and self.GetMember and self:GetMember(relatedNameR42) then
                        relatedCountR42 = relatedCountR42 + 1
                        relatedRowR42 = frame.characterIdentity184.relatedRowsR42[relatedCountR42]
                        relatedRowR42.otlRelatedNameR42 = relatedNameR42
                        local relatedMemberR45 = self:GetMember(relatedNameR42)
                        local relatedColorR45 = relatedMemberR45 and self:GetClassColor(relatedMemberR45.class or relatedMemberR45.classFile or "") or self.colors.white
                        UI:SetText(relatedRowR42, self.colors.grey .. "Alt  •  " .. self.colors.reset .. relatedColorR45 .. tostring(relatedNameR42) .. self.colors.reset .. "   ›")
                        relatedRowR42.otlTooltipTitle = "Open " .. tostring(relatedNameR42)
                        relatedRowR42.otlTooltip = "Open this linked alt's Guild Profile."
                        relatedRowR42:Show()
                    end
                end
            elseif identity184.role == "ALT" and identity184.main and identity184.counterpartInGuild ~= false
                and self.GetMember and self:GetMember(identity184.main) then
                local relatedRowR42 = frame.characterIdentity184.relatedRowsR42[1]
                relatedCountR42 = 1
                relatedRowR42.otlRelatedNameR42 = identity184.main
                local mainMemberR45 = self:GetMember(identity184.main)
                local mainColorR45 = mainMemberR45 and self:GetClassColor(mainMemberR45.class or mainMemberR45.classFile or "") or self.colors.white
                UI:SetText(relatedRowR42, self.colors.grey .. "Main  •  " .. self.colors.reset .. mainColorR45 .. tostring(identity184.main) .. self.colors.reset .. "   ›")
                relatedRowR42.otlTooltipTitle = "Open " .. tostring(identity184.main)
                relatedRowR42.otlTooltip = "Open this character's linked Main Guild Profile."
                relatedRowR42:Show()
            end
            if not snapshot.selfProfile and relatedCountR42 > 0 then frame.characterIdentity184.view:Hide() end
        end
        Place(frame.characterIdentity184, (snapshot.selfProfile and 82 or 72) + (relatedCountR42 * 22))
    else
        frame.characterIdentity184.manage:Hide()
        frame.characterIdentity184.view:Hide()
        frame.characterIdentity184:Hide()
    end

    frame.journey.known:SetText(self.colors.gold .. "Known since  " .. self.colors.reset
        .. (snapshot.knownSince and (date("%d %b %Y", snapshot.knownSince)
        .. (snapshot.knownDuration and ("  •  " .. snapshot.knownDuration) or "")) or "Not recorded yet"))
    frame.journey.rank:SetText(self.colors.gold .. "Current rank  " .. self.colors.reset .. tostring(member.rank or "Unknown"))
    frame.journey.last:SetText(self.colors.gold .. "Last online  " .. self.colors.reset
        .. (member.online and "Online now" or FriendlyAge183(self, member.lastSeen)))
    local lastColor = member.online and C.green or C.grey
    frame.journey.last:SetTextColor(lastColor[1], lastColor[2], lastColor[3])
    local journeyMilestonesR49 = snapshot.journeyMilestonesR49 or {}
    local journeyCountR49 = math.min(3, table.getn(journeyMilestonesR49))
    self.runtime = self.runtime or {}
    self.runtime.guildProfileMetrics183 = self.runtime.guildProfileMetrics183 or {}
    self.runtime.guildProfileMetrics183.lastJourneyMilestonesR49 = journeyCountR49
    if frame.journey.milestoneTitleR49 then
        if journeyCountR49 > 0 then frame.journey.milestoneTitleR49:Show() else frame.journey.milestoneTitleR49:Hide() end
    end
    if frame.journey.milestoneRowsR49 then
        local journeyIndexR49
        for journeyIndexR49 = 1, table.getn(frame.journey.milestoneRowsR49) do
            local milestoneRowR49 = frame.journey.milestoneRowsR49[journeyIndexR49]
            local milestoneR49 = journeyMilestonesR49[journeyIndexR49]
            if journeyIndexR49 <= journeyCountR49 and milestoneR49 then
                local whenR49 = tonumber(milestoneR49.ts) and tonumber(milestoneR49.ts) > 0 and date("%d %b %Y", milestoneR49.ts) or "Recorded"
                milestoneRowR49:SetText(self.colors.gold .. "• " .. self.colors.reset .. tostring(milestoneR49.label or "Guild milestone")
                    .. self.colors.grey .. "  •  " .. tostring(whenR49) .. self.colors.reset)
                if milestoneR49.kind == "RETURN" and tonumber(milestoneR49.ts) and (self:Now() - tonumber(milestoneR49.ts)) <= 30 * 86400 then
                    milestoneRowR49:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
                else
                    milestoneRowR49:SetTextColor(C.white[1], C.white[2], C.white[3])
                end
                milestoneRowR49:Show()
            else
                milestoneRowR49:Hide()
            end
        end
    end
    Place(frame.journey, journeyCountR49 > 0 and (118 + journeyCountR49 * 20) or 100)

    local achievementPeerVersionR27 = self.GetDetectedAddonVersion183 and self:GetDetectedAddonVersion183(member.name) or nil
    local achievementPeerCompatibleR27 = achievementPeerVersionR27 and self.IsSocialProfilePeer183 and self:IsSocialProfilePeer183(achievementPeerVersionR27)
    local achievementPeerTargetedR27 = achievementPeerVersionR27 and self.IsTargetedSocialProfilePeerR27 and self:IsTargetedSocialProfilePeerR27(achievementPeerVersionR27)
    local missingAchievementLabelR27 = "Not shared yet"
    if achievementPeerVersionR27 and not achievementPeerCompatibleR27 then
        local versionLabelR47 = self.GetFriendlyVersionLabelR47 and self:GetFriendlyVersionLabelR47(achievementPeerVersionR27) or Short183(achievementPeerVersionR27, 15)
        missingAchievementLabelR27 = "Update needed • " .. tostring(versionLabelR47)
    elseif achievementPeerCompatibleR27 then
        missingAchievementLabelR27 = achievementPeerTargetedR27 and "Waiting / refresh available" or "Waiting for shared data"
    end
    local sharedAchievementCount = (snapshot.achievements and snapshot.achievements.known) and (tostring(snapshot.achievements.completed or 0) .. "/" .. tostring(snapshot.achievements.total or 0)) or missingAchievementLabelR27
    local professionSharedCount = table.getn(snapshot.professions or {})
    local sharedAge = snapshot.sharedAt and FriendlyAge183(self, snapshot.sharedAt) or "No profile note yet"
    frame.shared.rows[1]:SetText(self.colors.gold .. "Shared profile  " .. self.colors.reset .. sharedAge)
    frame.shared.rows[2]:SetText(self.colors.gold .. "Achievements  " .. self.colors.reset .. sharedAchievementCount)
    local professionMissingR32 = "Not shared yet"
    if professionSharedCount == 0 and self.GetFeatureCompatibilityR32 then
        local supportedR32, stateR32, versionR32 = self:GetFeatureCompatibilityR32(member.name, "PROFILE_PROFESSIONS")
        if not supportedR32 and stateR32 == "OUTDATED" then
            local versionLabelR47 = self.GetFriendlyVersionLabelR47 and self:GetFriendlyVersionLabelR47(versionR32) or Short183(versionR32, 15)
            professionMissingR32 = "Update needed • " .. tostring(versionLabelR47)
        elseif not supportedR32 and stateR32 == "NOT_DETECTED" then professionMissingR32 = "Addon not detected" end
    end
    frame.shared.rows[3]:SetText(self.colors.gold .. "Professions  " .. self.colors.reset .. (professionSharedCount > 0 and (tostring(professionSharedCount) .. " shared") or professionMissingR32))
    Place(frame.shared, 88)

    local achievement = snapshot.achievements or { known = false, recent = {} }
    local recentCount = achievement.known and math.min(3, table.getn(achievement.recent or {})) or 0
    if achievement.known then
        local completed, total = math.max(0, tonumber(achievement.completed) or 0), math.max(0, tonumber(achievement.total) or 0)
        local percent = total > 0 and math.floor((completed / total) * 100 + 0.5) or 0
        frame.achievements.count:SetText(tostring(completed) .. " / " .. tostring(total) .. " completed  •  " .. tostring(percent) .. "%")
        if achievement.rank and achievement.coverage then
            frame.achievements.coverage:SetText("#" .. tostring(achievement.rank) .. " among " .. tostring(achievement.coverage)
                .. " guild members sharing achievement progress"
                .. (not achievement.localOwner and achievement.updatedAt and ("  •  " .. FriendlyAge183(self, achievement.updatedAt)) or ""))
        elseif achievement.localOwner then
            frame.achievements.coverage:SetText("Your progress is shown here. Guild ranking will appear when enough members share their progress.")
        else
            frame.achievements.coverage:SetText("Guild-shared progress"
                .. (achievement.updatedAt and ("  •  " .. FriendlyAge183(self, achievement.updatedAt)) or ""))
        end
        local fillWidth = total > 0 and math.floor(304 * math.min(1, completed / total)) or 0
        if fillWidth > 0 then frame.achievements.progressFill:SetWidth(fillWidth) frame.achievements.progressFill:Show()
        else frame.achievements.progressFill:Hide() end
    else
        if achievementPeerVersionR27 and not achievementPeerCompatibleR27 then
            local versionLabelR47 = self.GetFriendlyVersionLabelR47 and self:GetFriendlyVersionLabelR47(achievementPeerVersionR27) or tostring(achievementPeerVersionR27)
            frame.achievements.count:SetText("Detailed achievement data needs an addon update on this player.")
            frame.achievements.coverage:SetText("Detected " .. tostring(versionLabelR47) .. ". Older clients keep safe summary fallbacks; missing progress is never guessed.")
        elseif achievementPeerTargetedR27 then
            frame.achievements.count:SetText("Waiting for this member's shared achievement data.")
            frame.achievements.coverage:SetText("Compatible addon detected. A direct refresh request has been sent.")
        elseif achievementPeerCompatibleR27 then
            frame.achievements.count:SetText("Waiting for this member's shared achievement data.")
            frame.achievements.coverage:SetText("Saved achievement sharing is supported, but live refresh needs a newer addon on this player.")
        else
            frame.achievements.count:SetText("Achievement data has not been shared yet.")
            frame.achievements.coverage:SetText("No compatible achievement-sharing client has been detected for this member yet.")
        end
        frame.achievements.progressFill:Hide()
    end
    local categoryProgressR49 = snapshot.achievementCategoryR49
    local achievementDetailOffsetR49 = 0
    self.runtime.guildProfileMetrics183.lastCategoryExactR49 = categoryProgressR49 and true or false
    if categoryProgressR49 and frame.achievements.categoryLine1R49 and frame.achievements.categoryLine2R49 then
        frame.achievements.categoryLine1R49:SetText(tostring(categoryProgressR49.line1 or ""))
        frame.achievements.categoryLine2R49:SetText(tostring(categoryProgressR49.line2 or ""))
        frame.achievements.categoryLine1R49:Show() frame.achievements.categoryLine2R49:Show()
        achievementDetailOffsetR49 = 38
    else
        if frame.achievements.categoryLine1R49 then frame.achievements.categoryLine1R49:Hide() end
        if frame.achievements.categoryLine2R49 then frame.achievements.categoryLine2R49:Hide() end
    end
    local index
    local showcaseR48 = profileIdentityR48.showcase or {}
    local showcaseCountR48 = math.min(3, table.getn(showcaseR48))
    if frame.achievements.showcaseLabelR48 then
        frame.achievements.showcaseLabelR48:ClearAllPoints()
        frame.achievements.showcaseLabelR48:SetPoint("TOPLEFT", frame.achievements, "TOPLEFT", 12, -91 - achievementDetailOffsetR49)
        if showcaseCountR48 > 0 then frame.achievements.showcaseLabelR48:Show() else frame.achievements.showcaseLabelR48:Hide() end
    end
    if frame.achievements.showcaseBadgesR48 then
        local totalWidthR48 = showcaseCountR48 > 0 and ((showcaseCountR48 * 42) + ((showcaseCountR48 - 1) * 36)) or 0
        local startXR48 = math.max(12, math.floor((BODY_WIDTH_183 - totalWidthR48) / 2))
        for index = 1, table.getn(frame.achievements.showcaseBadgesR48) do
            local badgeR48 = frame.achievements.showcaseBadgesR48[index]
            local entryR48 = showcaseR48[index]
            if index <= showcaseCountR48 and entryR48 then
                badgeR48.otlAchievementIdR48 = entryR48.id
                badgeR48.icon:SetTexture(entryR48.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                if entryR48.secret then
                    badgeR48:SetBackdropColor(0.035, 0.020, 0.050, 0.94)
                    badgeR48:SetBackdropBorderColor(0.48, 0.26, 0.62, 0.92)
                else
                    badgeR48:SetBackdropColor(C.raised[1], C.raised[2], C.raised[3], 0.92)
                    badgeR48:SetBackdropBorderColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3], 0.74)
                end
                badgeR48:ClearAllPoints()
                badgeR48:SetPoint("TOPLEFT", frame.achievements, "TOPLEFT", startXR48 + ((index - 1) * 78), -105 - achievementDetailOffsetR49)
                badgeR48:Show()
            else
                badgeR48.otlAchievementIdR48 = nil
                badgeR48:Hide()
            end
        end
    end
    for index = 1, table.getn(frame.achievements.recentRows) do
        local row = frame.achievements.recentRows[index]
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame.achievements, "TOPLEFT", 11, -86 - achievementDetailOffsetR49 - ((index - 1) * 26))
        local record = achievement.recent and achievement.recent[index]
        if showcaseCountR48 < 1 and index <= recentCount and record then
            local definition = self.achievements174 and self.achievements174.byId and self.achievements174.byId[record.id] or nil
            row.otlAchievementId183 = record.id
            row.icon:SetTexture((definition and definition.icon) or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.text:SetText(Short183(record.name or (definition and definition.name) or record.id or "Achievement", 31)
                .. (record.ts and ("  •  " .. FriendlyAge183(self, record.ts)) or ""))
            row:Show()
        else
            row.otlAchievementId183 = nil
            row:Hide()
        end
    end
    Place(frame.achievements, (showcaseCountR48 > 0 and 158 or (92 + (recentCount * 26))) + achievementDetailOffsetR49)

    local goals = snapshot.selfProfile and snapshot.goals or {}
    if table.getn(goals) > 0 then
        local goalCount = math.min(3, table.getn(goals))
        for index = 1, table.getn(frame.goals.rows) do
            local row, goal = frame.goals.rows[index], goals[index]
            if index <= goalCount and goal then
                row.otlAchievementId183 = goal.id
                row.text:SetText(Short183(goal.name or goal.id or "Achievement", 34) .. "  •  " .. tostring(goal.progressText or "Tracked"))
                row:Show()
            else row.otlAchievementId183 = nil row:Hide() end
        end
        Place(frame.goals, 42 + (goalCount * 28))
    else
        frame.goals:Hide()
    end

    local professions = snapshot.professions or {}
    EnsureGuildProfileProfessionRows183(frame, table.getn(professions))
    local professionRows = math.max(1, table.getn(professions))
    for index = 1, table.getn(frame.professions.rows) do
        local row, profession = frame.professions.rows[index], professions[index]
        if profession then
            row.icon:SetTexture(profession.icon or "Interface\\Icons\\INV_Misc_Book_09")
            row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            local rankText = profession.rank and (" " .. tostring(profession.rank)
                .. (profession.maxRank and profession.maxRank > 0 and ("/" .. tostring(profession.maxRank)) or "")) or ""
            local recipeText = profession.recipeCount ~= nil and (tostring(profession.recipeCount) .. " recipes") or "Recipe data not yet shared"
            local freshness, freshnessColor = Freshness183(self, profession.ts)
            local sourceLabel = tostring(profession.sourceLabel or "Guild sharing")
            local sourceLower = string.lower(sourceLabel)
            if string.find(sourceLower, "local cache", 1, true) then sourceLabel = "This character"
            elseif string.find(sourceLower, "shared cache", 1, true) or string.find(sourceLower, "cache", 1, true) then sourceLabel = "Guild sharing" end
            local freshnessHex = freshness == "Live" and self.colors.green or (freshness == "Recent" and self.colors.gold or self.colors.grey)
            row.text:SetText(self.colors.gold .. Short183(profession.label, 22) .. self.colors.reset .. rankText
                .. self.colors.grey .. "  •  " .. recipeText .. "  •  " .. self.colors.reset
                .. freshnessHex .. freshness .. self.colors.reset .. self.colors.grey .. " / " .. Short183(sourceLabel, 16) .. self.colors.reset)
            row.text:SetTextColor(C.white[1], C.white[2], C.white[3])
            row:Show()
        elseif index == 1 and table.getn(professions) == 0 then
            row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            row.text:SetText("This member has not shared profession information yet.")
            row.text:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
            row:Show()
        else row:Hide() end
    end
    Place(frame.professions, 42 + (professionRows * 34))

    local activity = snapshot.activity or {}
    if table.getn(activity) > 0 then
        local activityCount = math.min(3, table.getn(activity))
        for index = 1, table.getn(frame.activity.rows) do
            local row, record = frame.activity.rows[index], activity[index]
            if index <= activityCount and record then
                local when = record.ts and date("%d %b", record.ts) or "Stored"
                row:SetText(when .. "  •  " .. Short183(record.detail or record.kind or "Guild event", 45))
                row:Show()
            else row:Hide() end
        end
        Place(frame.activity, 42 + (activityCount * 27))
    else
        frame.activity:Hide()
    end

    if frame.selfBadge184 then
        if snapshot.selfProfile then frame.selfBadge184:Show() else frame.selfBadge184:Hide() end
    end
    -- Keep the footer useful without making the profile wider. Other members
    -- get a direct Whisper action; your own profile keeps Edit About instead.
    if frame.contactButton184 and frame.achievementsButton and frame.professionsButton and frame.editAboutButton183 then
        frame.contactButton184:ClearAllPoints()
        frame.achievementsButton:ClearAllPoints()
        frame.professionsButton:ClearAllPoints()
        frame.editAboutButton183:ClearAllPoints()
        if snapshot.selfProfile then
            frame.contactButton184:Hide()
            UI:SetText(frame.achievementsButton, "Achievements")
            UI:SetText(frame.professionsButton, "Professions")
            frame.achievementsButton:SetWidth(108)
            frame.professionsButton:SetWidth(100)
            frame.achievementsButton.otlTooltipTitle = "My achievements"
            frame.achievementsButton.otlTooltip = "Open your full Guild Achievements page."
            frame.professionsButton.otlTooltipTitle = "My professions"
            frame.professionsButton.otlTooltip = "Open your full Professions page."
            frame.achievementsButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 13)
            frame.professionsButton:SetPoint("LEFT", frame.achievementsButton, "RIGHT", 8, 0)
            frame.editAboutButton183:SetPoint("LEFT", frame.professionsButton, "RIGHT", 8, 0)
            frame.editAboutButton183:Show()
        else
            frame.editAboutButton183:Hide()
            UI:SetText(frame.achievementsButton, "Achievements")
            UI:SetText(frame.professionsButton, "Professions")
            frame.achievementsButton.otlTooltipTitle = "View member achievements"
            frame.achievementsButton.otlTooltip = "Open a full read-only achievement browser for this member. Compatible clients can share exact completion details; older clients keep the saved summary."
            frame.professionsButton.otlTooltipTitle = "View member professions"
            frame.professionsButton.otlTooltip = "Open the Professions page filtered to recipes shared by this member."
            frame.contactButton184:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 13)
            frame.contactButton184:Show()
            frame.achievementsButton:SetWidth(122)
            frame.professionsButton:SetWidth(116)
            frame.achievementsButton:SetPoint("LEFT", frame.contactButton184, "RIGHT", 8, 0)
            frame.professionsButton:SetPoint("LEFT", frame.achievementsButton, "RIGHT", 8, 0)
        end
    end
    self:UpdateGuildProfileScroll183(math.max(BODY_VIEW_HEIGHT_183, cursor - CARD_GAP_183))
    self.runtime = self.runtime or {}
    self.runtime.guildProfileMetrics183 = self.runtime.guildProfileMetrics183 or {}
    self.runtime.guildProfileMetrics183.renders = (tonumber(self.runtime.guildProfileMetrics183.renders) or 0) + 1
    self.runtime.guildProfileMetrics183.lastReason = tostring(reason or "refresh")
    return true
end

function OTLGM:ScrollGuildProfileSectionR32(sectionKey)
    local frame = self.ui and self.ui.guildProfile183
    if not frame or not frame:IsVisible() then return false end
    local key = string.upper(tostring(sectionKey or ""))
    local card = key == "ACHIEVEMENTS" and frame.achievements or (key == "PROFESSIONS" and frame.professions or nil)
    if not card or not card:IsVisible() then return false end
    local top = math.max(0, (tonumber(card.otlProfileTop183) or 0) - 8)
    local maximum = math.max(0, (frame.body:GetHeight() or BODY_VIEW_HEIGHT_183) - BODY_VIEW_HEIGHT_183)
    frame.otlScroll183 = math.min(maximum, top)
    frame.scrollbar:SetValue(frame.otlScroll183)
    frame.scroll:SetVerticalScroll(frame.otlScroll183)
    if card.SetBackdropBorderColor then card:SetBackdropBorderColor(C.gold[1], C.gold[2], C.gold[3], 0.95) end
    local name = frame.otlMemberName183
    if key == "ACHIEVEMENTS" and self.GetFeatureCompatibilityMessageR32 and name then
        local message = self:GetFeatureCompatibilityMessageR32(name, "PROFILE_ACHIEVEMENTS", true)
        local snapshot = self:GetGuildProfileAchievementSnapshot183(name)
        if not snapshot or not snapshot.known then
            if not message then
                local version = self.GetDetectedAddonVersion183 and self:GetDetectedAddonVersion183(name) or nil
                if version and self.IsTargetedSocialProfilePeerR27 and self:IsTargetedSocialProfilePeerR27(version) then
                    message = "No achievement summary has arrived from " .. tostring(name) .. " yet. A direct refresh request was sent; their addon must be online and allow shared profile data."
                else
                    message = "No achievement summary has been shared by " .. tostring(name) .. " yet. Their compatible addon must be online and publish profile data."
                end
            end
            if message and self.ShowToast then self:ShowToast(message, "pending", 7) end
        end
    elseif key == "PROFESSIONS" and self.GetFeatureCompatibilityMessageR32 and name then
        local professions = self:GetGuildProfileProfessions183(name) or {}
        local message = self:GetFeatureCompatibilityMessageR32(name, "PROFILE_PROFESSIONS", true)
        if table.getn(professions) == 0 then
            if not message then message = "No profession data has been shared by " .. tostring(name) .. " yet. They should open the normal profession window from the spellbook at least once, then stay online long enough for guild sync." end
            if self.ShowToast then self:ShowToast(message, "pending", 7) end
        end
    end
    return true
end

function OTLGM:SaveGuildProfilePosition183()
    local frame = self.ui and self.ui.guildProfile183
    if not frame or frame.otlAttachSide183 ~= "FLOAT" or not OTLGM_DB or not OTLGM_DB.settings then return false end
    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    if point ~= "CENTER" or (relativeTo ~= UIParent and relativeTo ~= nil) then return false end
    local width, height = self:GetPositionViewportMetrics180()
    local scale = self.GetFrameScaleRelativeToUIParent180 and self:GetFrameScaleRelativeToUIParent180(frame) or 1
    local localWidth, localHeight = width / math.max(0.01, scale), height / math.max(0.01, scale)
    OTLGM_DB.settings.guildProfileNX183 = (tonumber(x) or 0) / math.max(1, localWidth)
    OTLGM_DB.settings.guildProfileNY183 = (tonumber(y) or 0) / math.max(1, localHeight)
    return true
end

function OTLGM:RestoreGuildProfilePosition183(frame)
    frame = frame or self.ui and self.ui.guildProfile183
    if not frame then return false end
    local width, height = self:GetPositionViewportMetrics180()
    local scale = self.GetFrameScaleRelativeToUIParent180 and self:GetFrameScaleRelativeToUIParent180(frame) or 1
    local localWidth, localHeight = width / math.max(0.01, scale), height / math.max(0.01, scale)
    local settings = OTLGM_DB and OTLGM_DB.settings or {}
    local x = tonumber(settings.guildProfileNX183) and tonumber(settings.guildProfileNX183) * localWidth or 0
    local y = tonumber(settings.guildProfileNY183) and tonumber(settings.guildProfileNY183) * localHeight or 0
    local maxX = math.max(0, (localWidth - PROFILE_WIDTH_183) / 2 - 8)
    local maxY = math.max(0, (localHeight - PROFILE_HEIGHT_183) / 2 - 8)
    x = math.max(-maxX, math.min(maxX, x))
    y = math.max(-maxY, math.min(maxY, y))
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    frame.otlAttachSide183 = "FLOAT"
    return true
end

function OTLGM:PositionGuildProfile183(reason)
    local frame, main = self.ui and self.ui.guildProfile183, self.ui and self.ui.main
    if not frame then return false end
    local parentWidth, parentHeight = self:GetPositionViewportMetrics180()
    if main and main.GetScale and frame.SetScale then
        local requestedScale = math.max(0.05, tonumber(main:GetScale()) or 1)
        local fitScale = math.max(0.05, math.min(requestedScale,
            (math.max(1, parentWidth) - 16) / PROFILE_WIDTH_183,
            (math.max(1, parentHeight) - 16) / PROFILE_HEIGHT_183))
        frame:SetScale(fitScale)
        self.runtime = self.runtime or {}
        self.runtime.guildProfileFitScale183 = fitScale
    end
    if frame.otlDetached183 or not main or not main.IsVisible or not main:IsVisible() then
        return self:RestoreGuildProfilePosition183(frame)
    end

    local scale = self.GetFrameScaleRelativeToUIParent180 and self:GetFrameScaleRelativeToUIParent180(main) or 1
    local profileScale = self.GetFrameScaleRelativeToUIParent180 and self:GetFrameScaleRelativeToUIParent180(frame) or scale
    -- The shell owns a CENTER -> UIParent CENTER anchor. Derive the visible main
    -- bounds from that authoritative anchor instead of GetLeft/GetRight, whose
    -- coordinate space differs across some 1.12 UI replacements when scale < 1.
    local centerX = self.GetFrameCenterOffset180 and self:GetFrameCenterOffset180(main) or 0
    local mainWidth = main.GetWidth and main:GetWidth() or 1000
    local visualWidth = mainWidth * scale
    local visualCenter = (parentWidth / 2) + centerX
    local left = visualCenter - (visualWidth / 2)
    local right = visualCenter + (visualWidth / 2)
    local needed = (PROFILE_WIDTH_183 + PROFILE_DOCK_GAP_183) * profileScale
    local rightSpace, leftSpace = math.max(0, parentWidth - right), math.max(0, left)
    local settings = OTLGM_DB and OTLGM_DB.settings or {}
    local preferred = settings.guildProfileDockSide183 == "LEFT" and "LEFT" or "RIGHT"
    local alternate = preferred == "RIGHT" and "LEFT" or "RIGHT"

    local function Fits(side)
        return (side == "RIGHT" and rightSpace or leftSpace) >= needed + 4
    end
    local function Dock(side, inside)
        frame:ClearAllPoints()
        if side == "RIGHT" then
            if inside then frame:SetPoint("TOPRIGHT", main, "TOPRIGHT", -10, -10)
            else frame:SetPoint("TOPLEFT", main, "TOPRIGHT", PROFILE_DOCK_GAP_183, 0) end
        else
            if inside then frame:SetPoint("TOPLEFT", main, "TOPLEFT", 10, -10)
            else frame:SetPoint("TOPRIGHT", main, "TOPLEFT", -PROFILE_DOCK_GAP_183, 0) end
        end
        frame.otlAttachSide183 = inside and (side .. "_INNER") or side
        frame.otlDetached183 = nil
        if OTLGM_DB and OTLGM_DB.settings then OTLGM_DB.settings.guildProfileDockSide183 = side end
        return true
    end

    if Fits(preferred) then
        Dock(preferred, false)
    elseif Fits(alternate) then
        Dock(alternate, false)
    else
        -- Deterministic no-space fallback: stay attached to the nearest preferred
        -- edge *inside* the main window. Never leave a freshly opened profile as
        -- an arbitrary floating overlay in the middle of the UI.
        local insideSide = preferred
        if settings.guildProfileDockSide183 == nil then insideSide = rightSpace >= leftSpace and "RIGHT" or "LEFT" end
        Dock(insideSide, true)
    end
    self.runtime = self.runtime or {}
    self.runtime.guildProfileMetrics183 = self.runtime.guildProfileMetrics183 or {}
    self.runtime.guildProfileMetrics183.lastAttach = frame.otlAttachSide183
    self.runtime.guildProfileMetrics183.lastPositionReason = tostring(reason or "position")
    self.runtime.guildProfileMetrics183.rightSpace = math.floor(rightSpace + 0.5)
    self.runtime.guildProfileMetrics183.leftSpace = math.floor(leftSpace + 0.5)
    return true
end

function OTLGM:TrySnapGuildProfile183(frame)
    frame = frame or self.ui and self.ui.guildProfile183
    local main = self.ui and self.ui.main
    if not frame or not main or not main.IsVisible or not main:IsVisible() then return false end
    local mainScale = self.GetFrameScaleRelativeToUIParent180 and self:GetFrameScaleRelativeToUIParent180(main) or 1
    local frameScale = self.GetFrameScaleRelativeToUIParent180 and self:GetFrameScaleRelativeToUIParent180(frame) or 1
    local ml, mr, fl, fr = main:GetLeft(), main:GetRight(), frame:GetLeft(), frame:GetRight()
    if not ml or not mr or not fl or not fr then return false end
    ml, mr = ml * mainScale, mr * mainScale
    fl, fr = fl * frameScale, fr * frameScale
    local rightDistance = math.min(math.abs(fl - mr), math.abs(fr - mr))
    local leftDistance = math.min(math.abs(fr - ml), math.abs(fl - ml))
    local side
    if rightDistance <= PROFILE_SNAP_ZONE_183 or leftDistance <= PROFILE_SNAP_ZONE_183 then
        side = rightDistance <= leftDistance and "RIGHT" or "LEFT"
    end
    if not side then return false end
    if OTLGM_DB and OTLGM_DB.settings then OTLGM_DB.settings.guildProfileDockSide183 = side end
    frame.otlDetached183 = nil
    self:PositionGuildProfile183("drag-snap")
    return true
end

local function CreateGuildProfileProfessionRow183(frame, index)
    local row = CreateFrame("Frame", nil, frame.professions)
    row:SetPoint("TOPLEFT", frame.professions, "TOPLEFT", 12, -30 - ((index - 1) * 34))
    row:SetWidth(320) row:SetHeight(30)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(24) row.icon:SetHeight(24) row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.text = ProfileLabel183(row, "", "GameFontNormalSmall", 32, -7, 286, "LEFT")
    row:Hide()
    frame.professions.rows[index] = row
    return row
end

EnsureGuildProfileProfessionRows183 = function(frame, count)
    count = math.max(1, math.min(MAX_PROFILE_PROFESSION_ROWS_183, tonumber(count) or 1))
    local index
    for index = table.getn(frame.professions.rows) + 1, count do
        CreateGuildProfileProfessionRow183(frame, index)
    end
end

function OTLGM:BuildGuildProfile183()
    self.ui = self.ui or {}
    if self.ui.guildProfile183 then return self.ui.guildProfile183 end
    local frame = UI:Surface(UIParent, "window", PROFILE_WIDTH_183, PROFILE_HEIGHT_183, "OTLGM_GuildProfileFrame183")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(78)
    if frame.SetToplevel then frame:SetToplevel(true) end
    frame:SetMovable(true)
    frame:EnableMouse(true)
    if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        if not this.StartMoving then return end
        this.otlDetached183 = true
        this.otlAttachSide183 = "FLOAT"
        this:StartMoving()
    end)
    frame:SetScript("OnDragStop", function()
        if this.StopMovingOrSizing then this:StopMovingOrSizing() end
        if OTLGM and OTLGM.TrySnapGuildProfile183 and OTLGM:TrySnapGuildProfile183(this) then return end
        local centerX, centerY = nil, nil
        if this.GetCenter then centerX, centerY = this:GetCenter() end
        local parentX, parentY = nil, nil
        if UIParent and UIParent.GetCenter then parentX, parentY = UIParent:GetCenter() end
        if centerX and centerY and parentX and parentY then
            this:ClearAllPoints()
            this:SetPoint("CENTER", UIParent, "CENTER", centerX - parentX, centerY - parentY)
        end
        this.otlDetached183 = true
        this.otlAttachSide183 = "FLOAT"
        if OTLGM then OTLGM:SaveGuildProfilePosition183() end
    end)
    frame:SetScript("OnHide", function()
        if OTLGM then OTLGM:SaveGuildProfilePosition183() end
        this.otlDetached183 = nil
    end)

    frame.windowCrest183 = frame:CreateTexture(nil, "ARTWORK")
    frame.windowCrest183:SetTexture("Interface\\AddOns\\OrderOfTheLionGM\\Assets\\LionCrest.tga")
    frame.windowCrest183:SetWidth(18) frame.windowCrest183:SetHeight(18)
    frame.windowCrest183:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -9)
    frame.windowTitle = ProfileLabel183(frame, "GUILD PROFILE", "GameFontNormalSmall", 39, -14, 230, "LEFT")
    frame.windowTitle:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    frame.close = UI:Button(frame, "x", 28, 24, function() OTLGM:CloseGuildProfile183("user") end, "danger")
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -9)
    frame.headerBackground183 = frame:CreateTexture(nil, "BACKGROUND")
    frame.headerBackground183:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -32)
    frame.headerBackground183:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -32)
    frame.headerBackground183:SetHeight(66)
    frame.headerBackground183:SetTexture(C.raised and C.raised[1] or 0.09, C.raised and C.raised[2] or 0.07, C.raised and C.raised[3] or 0.04, 0.72)
    frame.headerAccent183 = frame:CreateTexture(nil, "ARTWORK")
    frame.headerAccent183:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -32)
    frame.headerAccent183:SetWidth(3) frame.headerAccent183:SetHeight(66)
    frame.headerAccent183:SetTexture(C.gold[1], C.gold[2], C.gold[3], 0.95)
    frame.classIconFrame183 = UI:Surface(frame, "raised", 58, 58)
    frame.classIconFrame183:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -36)
    frame.classIcon = frame.classIconFrame183:CreateTexture(nil, "ARTWORK")
    frame.classIcon:SetWidth(48) frame.classIcon:SetHeight(48)
    frame.classIcon:SetPoint("CENTER", frame.classIconFrame183, "CENTER", 0, 0)
    frame.nameText = ProfileLabel183(frame, "", "GameFontNormalLarge", 84, -39, 184, "LEFT")
    frame.identityText = ProfileLabel183(frame, "", "GameFontNormalSmall", 84, -64, 184, "LEFT")
    frame.identityText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    frame.rankBadge183 = UI:Badge(frame, 112, 20)
    frame.rankBadge183:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -56)
    frame.rankBadge183.text:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    frame.selfBadge184 = UI:Badge(frame, 42, 18)
    frame.selfBadge184:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -38)
    frame.selfBadge184.text:SetText("YOU")
    frame.selfBadge184.text:SetTextColor(C.green[1], C.green[2], C.green[3])
    if frame.selfBadge184.SetBackdropBorderColor then frame.selfBadge184:SetBackdropBorderColor(C.green[1], C.green[2], C.green[3], 0.72) end
    frame.selfBadge184:Hide()

    -- r48 identity remains intentionally compact: one earned-title badge and
    -- an automatic Leadership prestige treatment.  Class colour stays the
    -- primary character accent so gold never overwhelms normal profile data.
    frame.titleBadgeR48 = UI:Badge(frame, 118, 18)
    frame.titleBadgeR48:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -78)
    frame.titleBadgeR48.text:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    if frame.titleBadgeR48.SetBackdropBorderColor then frame.titleBadgeR48:SetBackdropBorderColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3], 0.74) end
    frame.titleBadgeR48:Hide()
    frame.prestigeIconR48 = frame:CreateTexture(nil, "OVERLAY")
    frame.prestigeIconR48:SetWidth(18) frame.prestigeIconR48:SetHeight(18)
    frame.prestigeIconR48:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -48, -11)
    frame.prestigeIconR48:SetTexture("Interface\\Icons\\INV_Crown_01")
    frame.prestigeIconR48:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.prestigeIconR48:Hide()
    frame.statusDot = frame:CreateTexture(nil, "ARTWORK")
    frame.statusDot:SetWidth(7) frame.statusDot:SetHeight(7)
    frame.statusDot:SetPoint("TOPLEFT", frame, "TOPLEFT", 85, -86)
    frame.statusText = ProfileLabel183(frame, "", "GameFontNormalSmall", 98, -81, 260, "LEFT")
    frame.headerLine = frame:CreateTexture(nil, "ARTWORK")
    frame.headerLine:SetTexture(C.goldDark[1], C.goldDark[2], C.goldDark[3], 1)
    frame.headerLine:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -101)
    frame.headerLine:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -101)
    frame.headerLine:SetHeight(1)

    frame.scroll = CreateFrame("ScrollFrame", nil, frame)
    frame.scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -111)
    frame.scroll:SetWidth(BODY_WIDTH_183)
    frame.scroll:SetHeight(BODY_VIEW_HEIGHT_183)
    frame.scroll:EnableMouseWheel(true)
    frame.body = CreateFrame("Frame", nil, frame.scroll)
    frame.body:SetWidth(BODY_WIDTH_183)
    frame.body:SetHeight(BODY_VIEW_HEIGHT_183)
    frame.scroll:SetScrollChild(frame.body)
    frame.scroll:SetScript("OnMouseWheel", function()
        local maximum = math.max(0, (this:GetScrollChild():GetHeight() or BODY_VIEW_HEIGHT_183) - BODY_VIEW_HEIGHT_183)
        local nextValue = math.max(0, math.min(maximum, (tonumber(frame.otlScroll183) or 0) - ((tonumber(arg1) or 0) * 42)))
        frame.otlScroll183 = nextValue
        frame.scrollbar:SetValue(nextValue)
    end)
    frame.scrollbar = UI:Scrollbar(frame, BODY_VIEW_HEIGHT_183, function(value)
        frame.otlScroll183 = math.max(0, tonumber(value) or 0)
        frame.scroll:SetVerticalScroll(frame.otlScroll183)
    end)
    frame.scrollbar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -111)

    frame.about = NewProfileCard183(frame.body, "About Me", C.blue, PROFILE_SECTION_ICONS_183.ABOUT)
    frame.about.text = ProfileLabel183(frame.about, "", "GameFontNormalSmall", 12, -32, 320, "LEFT")
    frame.about.text:SetHeight(34) frame.about.text:SetJustifyV("TOP")

    frame.characterIdentity184 = NewProfileCard183(frame.body, "Characters", C.blue, PROFILE_SECTION_ICONS_183.IDENTITY)
    frame.characterIdentity184.line1 = ProfileLabel183(frame.characterIdentity184, "", "GameFontNormalSmall", 12, -32, 230, "LEFT")
    frame.characterIdentity184.line2 = ProfileLabel183(frame.characterIdentity184, "", "GameFontNormalSmall", 12, -52, 315, "LEFT")
    frame.characterIdentity184.line2:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    frame.characterIdentity184.manage = UI:Button(frame.characterIdentity184, "Manage", 82, 22, function()
        if OTLGM.OpenCharacterIdentityManager184 then OTLGM:OpenCharacterIdentityManager184() end
    end, "utility")
    frame.characterIdentity184.manage:SetPoint("TOPRIGHT", frame.characterIdentity184, "TOPRIGHT", -10, -28)
    frame.characterIdentity184.manage.otlTooltipTitle = "Main / Alt identity"
    frame.characterIdentity184.manage.otlTooltip = "Link this character to a main, confirm incoming alt requests, or unlink a character. Nothing is inferred automatically."
    frame.characterIdentity184.view = UI:Button(frame.characterIdentity184, "View", 82, 22, function()
        local name184 = frame.otlMemberName183
        if name184 and OTLGM.OpenCharacterIdentityForMember184 then OTLGM:OpenCharacterIdentityForMember184(name184) end
    end, "secondary")
    frame.characterIdentity184.view:SetPoint("TOPRIGHT", frame.characterIdentity184, "TOPRIGHT", -10, -28)
    frame.characterIdentity184.view.otlTooltipTitle = "Related characters"
    frame.characterIdentity184.view.otlTooltip = "Browse verified Main/Alt relationships and open the related guild profiles."
    frame.characterIdentity184.view:Hide()
    frame.characterIdentity184.relatedRowsR42 = {}
    for relatedIndexR42 = 1, 6 do
        local relatedRowR42 = UI:Button(frame.characterIdentity184, "", 316, 20, function(button)
            local relatedNameR42 = button and button.otlRelatedNameR42 or nil
            if relatedNameR42 and OTLGM.OpenCharacterIdentityProfile184 then OTLGM:OpenCharacterIdentityProfile184(relatedNameR42) end
        end, "inline")
        relatedRowR42:SetPoint("TOPLEFT", frame.characterIdentity184, "TOPLEFT", 12, -70 - ((relatedIndexR42 - 1) * 22))
        relatedRowR42:Hide()
        frame.characterIdentity184.relatedRowsR42[relatedIndexR42] = relatedRowR42
    end
    if UI.ContextHelpIcon then
        frame.characterIdentity184.helpR35 = UI:ContextHelpIcon(frame.characterIdentity184, "CHARACTER_IDENTITY")
        frame.characterIdentity184.helpR35:SetPoint("TOPRIGHT", frame.characterIdentity184, "TOPRIGHT", -8, -4)
    end
    frame.characterIdentity184:Hide()

    frame.journey = NewProfileCard183(frame.body, "Guild Journey", C.gold, PROFILE_SECTION_ICONS_183.JOURNEY)
    frame.journey.known = ProfileLabel183(frame.journey, "", "GameFontNormalSmall", 12, -32, 320, "LEFT")
    frame.journey.rank = ProfileLabel183(frame.journey, "", "GameFontNormalSmall", 12, -53, 320, "LEFT")
    frame.journey.last = ProfileLabel183(frame.journey, "", "GameFontNormalSmall", 12, -74, 320, "LEFT")
    frame.journey.known:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    frame.journey.rank:SetTextColor(C.white and C.white[1] or 1, C.white and C.white[2] or 1, C.white and C.white[3] or 1)
    frame.journey.last:SetTextColor(C.green[1], C.green[2], C.green[3])
    frame.journey.milestoneTitleR49 = ProfileLabel183(frame.journey, "MILESTONES", "GameFontNormalSmall", 12, -100, 180, "LEFT")
    frame.journey.milestoneTitleR49:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    frame.journey.milestoneTitleR49:Hide()
    frame.journey.milestoneRowsR49 = {}
    local journeyRowIndexR49
    for journeyRowIndexR49 = 1, 3 do
        local journeyRowR49 = ProfileLabel183(frame.journey, "", "GameFontNormalSmall", 12, -119 - ((journeyRowIndexR49 - 1) * 20), 320, "LEFT")
        journeyRowR49:SetTextColor(C.white[1], C.white[2], C.white[3])
        journeyRowR49:Hide()
        frame.journey.milestoneRowsR49[journeyRowIndexR49] = journeyRowR49
    end
    frame.journey.otlTooltipTitle = "Guild Journey"
    frame.journey.otlTooltip = "Known since is the first time this addon observed the member in the guild. Milestones reuse existing roster and verified achievement data; no separate activity tracker is created."
    frame.journey:EnableMouse(true)
    frame.journey:SetScript("OnEnter", function()
        if not GameTooltip then return end
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:AddLine(this.otlTooltipTitle, 1, 0.82, 0.35)
        GameTooltip:AddLine(this.otlTooltip, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame.journey:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

    frame.shared = NewProfileCard183(frame.body, "Shared Data", C.blue, PROFILE_SECTION_ICONS_183.PROFESSIONS)
    frame.shared.rows = {}
    for index = 1, 3 do
        frame.shared.rows[index] = ProfileLabel183(frame.shared, "", "GameFontNormalSmall", 12, -32 - ((index - 1) * 21), 320, "LEFT")
        frame.shared.rows[index]:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    end

    frame.achievements = NewProfileCard183(frame.body, "Guild Achievements", C.purple, PROFILE_SECTION_ICONS_183.ACHIEVEMENTS)
    frame.achievements.count = ProfileLabel183(frame.achievements, "", "GameFontNormal", 12, -31, 320, "LEFT")
    frame.achievements.progress = CreateFrame("Frame", nil, frame.achievements)
    frame.achievements.progress:SetPoint("TOPLEFT", frame.achievements, "TOPLEFT", 14, -56)
    frame.achievements.progress:SetWidth(304) frame.achievements.progress:SetHeight(8)
    frame.achievements.progressBackground = frame.achievements.progress:CreateTexture(nil, "BACKGROUND")
    frame.achievements.progressBackground:SetAllPoints(frame.achievements.progress)
    frame.achievements.progressBackground:SetTexture(C.raised and C.raised[1] or 0.10, C.raised and C.raised[2] or 0.08, C.raised and C.raised[3] or 0.05, 1)
    frame.achievements.progressFill = frame.achievements.progress:CreateTexture(nil, "ARTWORK")
    frame.achievements.progressFill:SetPoint("TOPLEFT", frame.achievements.progress, "TOPLEFT", 0, 0)
    frame.achievements.progressFill:SetHeight(8)
    frame.achievements.progressFill:SetTexture(C.gold[1], C.gold[2], C.gold[3], 1)
    frame.achievements.coverage = ProfileLabel183(frame.achievements, "", "GameFontNormalSmall", 12, -70, 320, "LEFT")
    frame.achievements.coverage:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    frame.achievements.categoryLine1R49 = ProfileLabel183(frame.achievements, "", "GameFontNormalSmall", 12, -91, 320, "LEFT")
    frame.achievements.categoryLine2R49 = ProfileLabel183(frame.achievements, "", "GameFontNormalSmall", 12, -109, 320, "LEFT")
    frame.achievements.categoryLine1R49:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    frame.achievements.categoryLine2R49:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    frame.achievements.categoryLine1R49:Hide() frame.achievements.categoryLine2R49:Hide()
    frame.achievements.showcaseLabelR48 = ProfileLabel183(frame.achievements, "SHOWCASE", "GameFontNormalSmall", 12, -91, 100, "LEFT")
    frame.achievements.showcaseLabelR48:SetTextColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3])
    frame.achievements.showcaseLabelR48:Hide()
    frame.achievements.showcaseBadgesR48 = {}
    local showcaseIndexR48
    for showcaseIndexR48 = 1, 3 do
        local badgeR48 = CreateFrame("Button", nil, frame.achievements)
        badgeR48:SetWidth(42) badgeR48:SetHeight(42)
        badgeR48:SetPoint("TOPLEFT", frame.achievements, "TOPLEFT", 62 + ((showcaseIndexR48 - 1) * 78), -105)
        if OTLGM.PrepareInteractiveControl170 then OTLGM:PrepareInteractiveControl170(badgeR48, "button") end
        badgeR48:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 9,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        badgeR48:SetBackdropColor(C.raised[1], C.raised[2], C.raised[3], 0.92)
        badgeR48:SetBackdropBorderColor(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3], 0.74)
        badgeR48.icon = badgeR48:CreateTexture(nil, "ARTWORK")
        badgeR48.icon:SetPoint("CENTER", badgeR48, "CENTER", 0, 0)
        badgeR48.icon:SetWidth(32) badgeR48.icon:SetHeight(32)
        badgeR48.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        badgeR48:SetScript("OnEnter", function()
            if not this.otlAchievementIdR48 or not GameTooltip then return end
            local definitionR48 = OTLGM.achievements174 and OTLGM.achievements174.byId and OTLGM.achievements174.byId[this.otlAchievementIdR48] or nil
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:AddLine(definitionR48 and definitionR48.name or "Showcased achievement", 1, 0.82, 0.35)
            GameTooltip:AddLine("Featured by this player in their Guild Profile.", 0.72, 0.72, 0.72, true)
            if definitionR48 then
                local _, descriptionR48 = OTLGM:GetAchievementPresentation174(definitionR48, true)
                if descriptionR48 and descriptionR48 ~= "" then GameTooltip:AddLine(descriptionR48, 1, 1, 1, true) end
            end
            GameTooltip:AddLine("Click to open achievements", 0.52, 0.72, 1)
            GameTooltip:Show()
        end)
        badgeR48:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        badgeR48:SetScript("OnClick", function()
            if not this.otlAchievementIdR48 then return end
            local profileR48 = OTLGM.ui and OTLGM.ui.guildProfile183
            local nameR48 = profileR48 and profileR48.otlMemberName183 or nil
            if nameR48 and IsSelf183(OTLGM, nameR48) then
                if OTLGM.OpenAchievement174 then OTLGM:OpenAchievement174(this.otlAchievementIdR48) end
            elseif nameR48 and OTLGM.OpenGuildMemberAchievementsR42 then
                OTLGM:OpenGuildMemberAchievementsR42(nameR48)
            end
        end)
        badgeR48:Hide()
        frame.achievements.showcaseBadgesR48[showcaseIndexR48] = badgeR48
    end
    frame.achievements.recentRows = {}
    local index
    for index = 1, 3 do
        local row = CreateFrame("Button", nil, frame.achievements)
        row:SetPoint("TOPLEFT", frame.achievements, "TOPLEFT", 11, -86 - ((index - 1) * 26))
        row:SetWidth(322) row:SetHeight(24)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.icon:SetWidth(20) row.icon:SetHeight(20)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.text = ProfileLabel183(row, "", "GameFontNormalSmall", 28, -5, 288, "LEFT")
        row.text:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        row.hover183 = row:CreateTexture(nil, "BACKGROUND")
        row.hover183:SetAllPoints(row)
        row.hover183:SetTexture(C.purple[1], C.purple[2], C.purple[3], 0.10)
        row.hover183:Hide()
        row:SetScript("OnEnter", function()
            if this.hover183 then this.hover183:Show() end
            if not this.otlAchievementId183 or not GameTooltip then return end
            local definition = OTLGM.achievements174 and OTLGM.achievements174.byId and OTLGM.achievements174.byId[this.otlAchievementId183] or nil
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:AddLine(definition and definition.name or "Guild Achievement", 1, 0.82, 0.35)
            if definition then
                local complete = OTLGM.IsAchievementComplete174 and OTLGM:IsAchievementComplete174(definition.id)
                local _, description = OTLGM:GetAchievementPresentation174(definition, complete and true or false)
                if description and description ~= "" then GameTooltip:AddLine(description, 1, 1, 1, true) end
            end
            GameTooltip:AddLine("Click to open achievement", 0.52, 0.72, 1)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            if this.hover183 then this.hover183:Hide() end
            if GameTooltip then GameTooltip:Hide() end
        end)
        row:SetScript("OnClick", function()
            if this.otlAchievementId183 and OTLGM.OpenAchievement174 then OTLGM:OpenAchievement174(this.otlAchievementId183) end
        end)
        row:Hide()
        frame.achievements.recentRows[index] = row
    end

    frame.goals = NewProfileCard183(frame.body, "My Goals", C.orange, PROFILE_SECTION_ICONS_183.GOALS)
    frame.goals.rows = {}
    for index = 1, 3 do
        local row = UI:TableRow(frame.goals, 320, 25, function(button)
            if button.otlAchievementId183 and OTLGM.OpenAchievement174 then OTLGM:OpenAchievement174(button.otlAchievementId183) end
        end)
        row:SetPoint("TOPLEFT", frame.goals, "TOPLEFT", 12, -30 - ((index - 1) * 28))
        row.text = ProfileLabel183(row, "", "GameFontNormalSmall", 8, -6, 304, "LEFT")
        row:Hide()
        frame.goals.rows[index] = row
    end

    frame.professions = NewProfileCard183(frame.body, "Professions", C.blue, PROFILE_SECTION_ICONS_183.PROFESSIONS)
    frame.professions.rows = {}
    EnsureGuildProfileProfessionRows183(frame, INITIAL_PROFILE_PROFESSION_ROWS_183)

    frame.activity = NewProfileCard183(frame.body, "Recent Guild Activity", C.green, PROFILE_SECTION_ICONS_183.ACTIVITY)
    frame.activity.rows = {}
    for index = 1, 3 do
        frame.activity.rows[index] = ProfileLabel183(frame.activity, "", "GameFontNormalSmall", 12, -31 - ((index - 1) * 27), 320, "LEFT")
        frame.activity.rows[index]:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    end

    frame.contactButton184 = UI:Button(frame, "Whisper", 82, 30, function()
        local name = frame.otlMemberName183
        if name and OTLGM.WhisperMember then OTLGM:WhisperMember(name) end
    end, "primary")
    frame.contactButton184.otlTooltipTitle = "Whisper member"
    frame.contactButton184.otlTooltip = "Start a whisper with this guild member without closing their profile."
    frame.contactButton184:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 13)
    frame.contactButton184:Hide()
    frame.achievementsButton = UI:Button(frame, "Achievements", 108, 30, function()
        local name = frame.otlMemberName183
        if name and not IsSelf183(OTLGM, name) then
            if OTLGM.OpenGuildMemberAchievementsR42 then OTLGM:OpenGuildMemberAchievementsR42(name) end
        else
            OTLGM:ShowPage("achievements")
        end
    end, "utility")
    frame.achievementsButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 13)
    frame.professionsButton = UI:Button(frame, "Professions", 100, 30, function()
        local name = frame.otlMemberName183
        if name and not IsSelf183(OTLGM, name) then
            if OTLGM.OpenGuildMemberProfessionsR42 then OTLGM:OpenGuildMemberProfessionsR42(name) end
        else
            -- A member-specific profession view is transient. Returning to the
            -- owner's own Professions page from Profile must never inherit it.
            if OTLGM.ui then OTLGM.ui.craftingCrafterFilterR42 = nil end
            if OTLGM.InvalidateCraftingSearchCache then OTLGM:InvalidateCraftingSearchCache("profile-self-r42") end
            OTLGM:ShowPage("professions")
        end
    end, "secondary")
    frame.professionsButton:SetPoint("LEFT", frame.achievementsButton, "RIGHT", 8, 0)
    frame.editAboutButton183 = UI:Button(frame, "Customize", 104, 30, function()
        if OTLGM.OpenGuildProfileEditor183 then OTLGM:OpenGuildProfileEditor183() end
    end, "primary")
    frame.editAboutButton183:SetPoint("LEFT", frame.professionsButton, "RIGHT", 8, 0)
    frame.editAboutButton183.otlTooltipTitle = "Customize Guild Profile"
    frame.editAboutButton183.otlTooltip = "Edit About Me, choose an earned title, and manage your achievement showcase."
    frame.editAboutButton183:Hide()

    AddSpecialFrame183("OTLGM_GuildProfileFrame183")
    frame:Hide()
    self.ui.guildProfile183 = frame
    self.runtime = self.runtime or {}
    self.runtime.guildProfileMetrics183 = self.runtime.guildProfileMetrics183 or {}
    self.runtime.guildProfileMetrics183.frameCreates = (tonumber(self.runtime.guildProfileMetrics183.frameCreates) or 0) + 1
    return frame
end

function OTLGM:OpenGuildMemberProfile183(name, source, automatic)
    local member = name and self.GetMember and self:GetMember(name) or nil
    if not member then return false end
    if automatic and OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.showGuildProfileOnRoster183 == false then return false end
    if not self.ui or not self.ui.main or not self.ui.main:IsVisible() then return false end
    local frame = self:BuildGuildProfile183()
    local wasVisible = frame:IsVisible()
    if not wasVisible then frame.otlDetached183 = nil frame.otlScroll183 = 0 end
    frame.otlMemberName183 = member.name
    frame.otlSource183 = tostring(source or "unknown")
    if not self:RefreshGuildProfile183(automatic and "roster-select" or "explicit-open") then return false end
    self:PositionGuildProfile183("open")
    frame:Show()
    if frame.Raise then frame:Raise() end
    self.runtime = self.runtime or {}
    self.runtime.guildProfileMetrics183 = self.runtime.guildProfileMetrics183 or {}
    self.runtime.guildProfileMetrics183.opens = (tonumber(self.runtime.guildProfileMetrics183.opens) or 0) + 1
    self.runtime.guildProfileMetrics183.selected = true
    return true
end

function OTLGM:CloseGuildProfile183(reason)
    local frame = self.ui and self.ui.guildProfile183
    if not frame then return false end
    self.runtime = self.runtime or {}
    self.runtime.guildProfileMetrics183 = self.runtime.guildProfileMetrics183 or {}
    self.runtime.guildProfileMetrics183.lastClose = tostring(reason or "close")
    self.runtime.guildProfileMetrics183.selected = nil
    frame:Hide()
    return true
end

function OTLGM:OpenMyGuildProfile183()
    local player = UnitName and UnitName("player") or nil
    if not player or player == "" then return false end
    local member = self.GetMember and self:GetMember(player) or nil
    if not member then
        if self.ShowToast then self:ShowToast("Your character is not in the current guild list yet. Use Refresh Roster when convenient.", "error") end
        return false
    end
    local previousFocus, previousSelected = self.ui.rosterFocusMember180, self.ui.rosterSelectedName
    self.ui.rosterFocusMember180 = member.name
    self.ui.rosterSelectedName = member.name
    if not self:ShowPage("roster", { suppressRosterScan183 = true }) then
        self.ui.rosterFocusMember180, self.ui.rosterSelectedName = previousFocus, previousSelected
        return false
    end
    if self.PersistRosterPosition180 then self:PersistRosterPosition180() end
    -- Roster entry can already have opened the same companion automatically.
    -- Avoid a second cache rebuild/flicker when My Profile routed through Roster.
    local currentProfile = self.ui and self.ui.guildProfile183
    if currentProfile and currentProfile.IsVisible and currentProfile:IsVisible()
        and NormalizeProfileName183(self, currentProfile.otlMemberName183) == NormalizeProfileName183(self, member.name) then
        return true
    end
    return self:OpenGuildMemberProfile183(member.name, "my-profile", false)
end

function OTLGM:GetGuildProfileSupportSummary183()
    local frame = self.ui and self.ui.guildProfile183
    local metrics = self.runtime and self.runtime.guildProfileMetrics183 or {}
    return "Guild Profile: " .. tostring(frame and frame:IsVisible() and "visible" or "hidden")
        .. " / selected " .. tostring(frame and frame.otlMemberName183 and "yes" or "no")
        .. " / side " .. tostring(frame and frame.otlAttachSide183 or "none")
        .. " / source " .. tostring(frame and frame.otlSource183 or "none")
        .. " / frames " .. tostring(metrics.frameCreates or 0)
        .. " / opens-renders " .. tostring(metrics.opens or 0) .. "/" .. tostring(metrics.renders or 0)
        .. " / history fallback " .. tostring(metrics.historyFallbacks or 0)
        .. " / r49 journey/category " .. tostring(metrics.lastJourneyMilestonesR49 or 0) .. "/" .. tostring(metrics.lastCategoryExactR49 and "exact" or "summary")
        .. " / refresh triggers 0"
end

OTLGM:RegisterModule("GuildProfile183", {
    stage = "D",
    revision = 3,
    lazy = true,
    cacheOnly = true,
    companionFrame = true,
    professionRows = MAX_PROFILE_PROFESSION_ROWS_183,
    commonScroll = true,
    noOnUpdate = true,
    noRosterRequest = true,
    noNetworkRequest = true,
    noProfessionScan = true,
})
