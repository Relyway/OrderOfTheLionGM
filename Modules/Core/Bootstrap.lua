-- Order of the Lion Guild Manager
-- Stable runtime identity, shared utilities and module registry.
-- Compatible with the Lua runtime used by Vanilla/OctoWoW (Interface 11200).

OTLGM = OTLGM or {}
OTLGM.__impl180 = OTLGM.__impl180 or {}

OTLGM.name = "Order of the Lion Guild Manager"
OTLGM.addonName = "OrderOfTheLionGM"
OTLGM.version = "1.8.3"
OTLGM.build = "release-1.8.3-20260827"
OTLGM.hotfix = nil
OTLGM.schemaVersion = 15
OTLGM.protocolVersion = 3
-- 1.8 network contract. These constants are the single source of truth for
-- sender pacing, receiver abuse protection and the per-slice queue budget.
-- The receiver keeps modest headroom above the maximum legitimate 1.8 sender
-- window so the addon can never rate-limit its own normal synchronization.
OTLGM.networkPacketBudget180 = 2
OTLGM.networkRateWindow180 = 10
OTLGM.networkOutboundMaximum180 = 80
OTLGM.networkInboundMaximum180 = 90
OTLGM.useRaidPlanner160 = true

OTLGM.ui = OTLGM.ui or {}
OTLGM.runtime = OTLGM.runtime or {}
OTLGM.modules = OTLGM.modules or {}
OTLGM.moduleOrder = OTLGM.moduleOrder or {}

OTLGM.colors = {
    gold = "|cffffd36b",
    green = "|cff69cc73",
    red = "|cffff7777",
    orange = "|cffffa63d",
    grey = "|cffaaaaaa",
    darkGrey = "|cff777777",
    white = "|cffffffff",
    blue = "|cff69a8ff",
    purple = "|cffb06cff",
    reset = "|r",
}

OTLGM.theme = {
    background = { 0.010, 0.012, 0.014, 1.0 },
    surface = { 0.028, 0.030, 0.034, 1.0 },
    surfaceRaised = { 0.054, 0.052, 0.048, 1.0 },
    border = { 0.26, 0.22, 0.14, 0.92 },
    borderSoft = { 0.15, 0.15, 0.14, 0.88 },
    gold = { 0.92, 0.67, 0.22, 1.0 },
    goldBright = { 1.0, 0.82, 0.36, 1.0 },
    blue = { 0.20, 0.50, 0.78, 1.0 },
    green = { 0.18, 0.62, 0.32, 1.0 },
    red = { 0.70, 0.20, 0.14, 1.0 },
    text = { 0.92, 0.90, 0.84, 1.0 },
    textMuted = { 0.64, 0.63, 0.59, 1.0 },
    disabled = { 0.27, 0.27, 0.27, 1.0 },
}

function OTLGM:RegisterModule(name, module)
    if type(name) ~= "string" or name == "" or type(module) ~= "table" then return false end
    if not self.modules[name] then table.insert(self.moduleOrder, name) end
    self.modules[name] = module
    return true
end

function OTLGM:GetModule(name)
    return self.modules and self.modules[name] or nil
end

function OTLGM:Trim(text)
    text = tostring(text or "")
    return string.gsub(text, "^%s*(.-)%s*$", "%1")
end

-- Character names may contain non-ASCII bytes on custom clients. Keep those
-- bytes intact instead of collapsing the whole name to an empty cache key.
function OTLGM:NormalizeName(name)
    name = self:Trim(name)
    name = string.gsub(name, "%-.*$", "")
    return string.lower(name)
end

function OTLGM:NormalizeText(text)
    text = string.lower(self:Trim(text))
    text = string.gsub(text, "[%c]", " ")
    text = string.gsub(text, "%s+", " ")
    return text
end

function OTLGM:Utf8Truncate(text, maximum)
    text = tostring(text or "")
    maximum = tonumber(maximum)
    if not maximum or maximum < 0 or string.len(text) <= maximum then return text end
    if maximum == 0 then return "" end

    local cut = maximum
    local byteValue = string.byte(text, cut)
    while cut > 0 and byteValue and byteValue >= 128 and byteValue < 192 do
        cut = cut - 1
        byteValue = string.byte(text, cut)
    end
    if cut <= 0 then return "" end

    local expected = 1
    if byteValue and byteValue >= 240 then expected = 4
    elseif byteValue and byteValue >= 224 then expected = 3
    elseif byteValue and byteValue >= 192 then expected = 2 end
    if cut + expected - 1 > maximum then cut = cut - 1 else cut = maximum end
    if cut < 0 then cut = 0 end
    return string.sub(text, 1, cut)
end

function OTLGM:SafeText(text, maximum, multiline, allowLinks)
    text = tostring(text or "")
    local parts = {}
    local index, byteValue, character
    for index = 1, string.len(text) do
        byteValue = string.byte(text, index)
        character = string.sub(text, index, index)
        if byteValue >= 32 or byteValue == 9 or byteValue == 10 or byteValue == 13 then
            table.insert(parts, character)
        end
    end
    text = table.concat(parts)

    if multiline then
        text = string.gsub(text, "\r\n", "\n")
        text = string.gsub(text, "\r", "\n")
        text = string.gsub(text, "\t", " ")
        text = string.gsub(text, "\n\n\n+", "\n\n")
    else
        text = string.gsub(text, "[\r\n\t]", " ")
        text = string.gsub(text, "%s+", " ")
    end

    -- Untrusted texture/color escape sequences can produce misleading UI. Item
    -- and spell links are preserved only in code paths that explicitly request it.
    if not allowLinks then text = string.gsub(text, "|", "/") end
    text = self:Trim(text)
    return self:Utf8Truncate(text, maximum)
end

function OTLGM:Split(text, delimiter)
    local result = {}
    text = tostring(text or "")
    delimiter = delimiter or "^"
    local startAt = 1
    while true do
        local found = string.find(text, delimiter, startAt, true)
        if not found then
            table.insert(result, string.sub(text, startAt))
            break
        end
        table.insert(result, string.sub(text, startAt, found - 1))
        startAt = found + string.len(delimiter)
    end
    return result
end

function OTLGM:Count(tableValue)
    if type(tableValue) ~= "table" then return 0 end
    local count = 0
    local key
    for key in pairs(tableValue) do count = count + 1 end
    return count
end

function OTLGM:Copy(source, maximumDepth, currentDepth)
    if type(source) ~= "table" then return source end
    maximumDepth = tonumber(maximumDepth) or 12
    currentDepth = tonumber(currentDepth) or 0
    if currentDepth >= maximumDepth then return nil end
    local target = {}
    local key, value
    for key, value in pairs(source) do
        if type(key) == "string" or type(key) == "number" then
            if type(value) == "table" then target[key] = self:Copy(value, maximumDepth, currentDepth + 1)
            elseif type(value) == "string" or type(value) == "number" or type(value) == "boolean" then target[key] = value end
        end
    end
    return target
end

function OTLGM:IsValidID(id, maximum)
    id = tostring(id or "")
    maximum = tonumber(maximum) or 64
    if id == "" or string.len(id) > maximum then return false end
    return string.find(id, "^[A-Za-z0-9_%-]+$") ~= nil
end

function OTLGM:VersionParts(version)
    local _, _, major, minor, patch = string.find(tostring(version or ""), "^(%d+)%.(%d+)%.(%d+)")
    return tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
end

local function VersionStage180(version)
    local lower = string.lower(tostring(version or ""))
    local _, _, rc = string.find(lower, "%-rc(%d+)")
    if rc then
        local _, _, revision = string.find(lower, "%-r(%d+)")
        return 3, tonumber(rc) or 0, tonumber(revision) or 0, 0
    end
    local _, _, beta = string.find(lower, "beta(%d*)")
    if beta ~= nil then
        local _, _, revision = string.find(lower, "%-r(%d+)")
        return 2, tonumber(beta) or 0, tonumber(revision) or 0, 0
    end
    local _, _, alpha = string.find(lower, "alpha(%d*)")
    local _, _, cstage = string.find(lower, "%-c(%d+)")
    if alpha ~= nil or cstage ~= nil then
        local _, _, revision = string.find(lower, "%-r(%d+)")
        return 1, tonumber(alpha) or 0, tonumber(cstage) or 0, tonumber(revision) or 0
    end
    -- A plain semantic version is the final/stable release and sorts above
    -- every same-base prerelease. Unknown custom suffixes sort below final but
    -- above the old alpha family only when explicitly marked beta/RC above.
    if not string.find(lower, "-", 1, true) then return 4, 0, 0, 0 end
    return 0, 0, 0, 0
end

function OTLGM:IsVersionNewer(left, right)
    local leftMajor, leftMinor, leftPatch = self:VersionParts(left)
    local rightMajor, rightMinor, rightPatch = self:VersionParts(right)
    if leftMajor ~= rightMajor then return leftMajor > rightMajor end
    if leftMinor ~= rightMinor then return leftMinor > rightMinor end
    if leftPatch ~= rightPatch then return leftPatch > rightPatch end
    local leftStage, leftA, leftB, leftC = VersionStage180(left)
    local rightStage, rightA, rightB, rightC = VersionStage180(right)
    if leftStage ~= rightStage then return leftStage > rightStage end
    if leftA ~= rightA then return leftA > rightA end
    if leftB ~= rightB then return leftB > rightB end
    return leftC > rightC
end

function OTLGM:InCombat()
    if not UnitAffectingCombat then return false end
    local ok, result = pcall(UnitAffectingCombat, "player")
    return ok and result and true or false
end

function OTLGM:IsUIVisible()
    return self.ui and self.ui.main and self.ui.main.IsVisible and self.ui.main:IsVisible() and true or false
end

-- RC4: one canonical server-time adapter. Any text labelled ST must flow
-- through these helpers rather than the user's local operating-system clock.
function OTLGM:GetServerOffsetSeconds180(now)
    now = tonumber(now) or (self.Now and self:Now()) or (time and time() or 0)
    if not GetGameTime or not date then return 0 end
    local ok, serverHour, serverMinute = pcall(GetGameTime)
    if not ok or serverHour == nil then return 0 end
    local localHour = tonumber(date("%H", now)) or 0
    local localMinute = tonumber(date("%M", now)) or 0
    local delta = ((tonumber(serverHour) or 0) * 60 + (tonumber(serverMinute) or 0)) - (localHour * 60 + localMinute)
    -- Choose the nearest same-instant wall-clock offset. This handles clients
    -- on the previous/next local calendar day without inventing a date API.
    while delta > 720 do delta = delta - 1440 end
    while delta < -720 do delta = delta + 1440 end
    return delta * 60
end

function OTLGM:GetServerNow180(now)
    now = tonumber(now) or (self.Now and self:Now()) or (time and time() or 0)
    return now + self:GetServerOffsetSeconds180(now)
end

function OTLGM:FormatServerClock180(ts, includeDate)
    ts = tonumber(ts) or (self.Now and self:Now()) or (time and time() or 0)
    -- GetGameTime describes the server wall clock at the current instant. Reuse
    -- that current offset when formatting a future/past event timestamp; asking
    -- GetServerOffsetSeconds180(targetTs) would incorrectly compare today's
    -- server clock with the target timestamp's local hour and make every event
    -- drift toward the current server time.
    local sampleNow = (self.Now and self:Now()) or (time and time() or ts)
    local shifted = ts + self:GetServerOffsetSeconds180(sampleNow)
    if includeDate then return date("%H:%M  %d %b", shifted) end
    return date("%H:%M", shifted)
end

function OTLGM:FormatServerDate180(ts, pattern)
    ts = tonumber(ts) or (self.Now and self:Now()) or (time and time() or 0)
    local sampleNow = (self.Now and self:Now()) or (time and time() or ts)
    local shifted = ts + self:GetServerOffsetSeconds180(sampleNow)
    return date(pattern or "%d %b", shifted)
end

function OTLGM:GetServerDayOffset180(targetTs, nowTs)
    targetTs = tonumber(targetTs) or 0
    nowTs = tonumber(nowTs) or (self.Now and self:Now()) or (time and time() or 0)
    if targetTs <= 0 then return 0 end
    local offset = self:GetServerOffsetSeconds180(nowTs)
    local nowParts = date("*t", nowTs + offset)
    local targetParts = date("*t", targetTs + offset)
    if not nowParts or not targetParts then
        return math.max(0, math.floor(((targetTs - nowTs) + 86399) / 86400))
    end
    -- Noon avoids DST/midnight discontinuities when converting calendar days.
    local nowDay = time({ year=nowParts.year, month=nowParts.month, day=nowParts.day, hour=12, min=0, sec=0 })
    local targetDay = time({ year=targetParts.year, month=targetParts.month, day=targetParts.day, hour=12, min=0, sec=0 })
    return math.max(0, math.floor(((targetDay - nowDay) / 86400) + 0.5))
end

function OTLGM:GetServerDayStart180(nowTs, dayOffset)
    nowTs = tonumber(nowTs) or (self.Now and self:Now()) or (time and time() or 0)
    dayOffset = tonumber(dayOffset) or 0
    local offset = self:GetServerOffsetSeconds180(nowTs)
    local parts = date("*t", nowTs + offset)
    if not parts then return nowTs - math.mod(nowTs, 86400) + (dayOffset * 86400) end
    local shiftedMidnight = time({ year=parts.year, month=parts.month, day=parts.day, hour=0, min=0, sec=0 }) + (dayOffset * 86400)
    return shiftedMidnight - offset
end

function OTLGM:FormatServerDayTime180(targetTs, recurring)
    targetTs = tonumber(targetTs) or 0
    if targetTs <= 0 then return "Time TBA" end
    local dayOffset = self:GetServerDayOffset180(targetTs)
    local prefix = dayOffset == 0 and "Today" or (dayOffset == 1 and "Tomorrow" or ("+" .. tostring(dayOffset) .. "d"))
    local clock = self:FormatServerClock180(targetTs, false)
    return prefix .. " " .. clock .. " ST" .. (recurring == "WEEKLY" and "  -  Weekly" or "")
end

-- OctoWoW keeps the Vanilla API name but some client builds return the item
-- texture in slot 9 and a vendor price in slot 10. Stock 1.12 returns the
-- texture in slot 10. Keep that difference behind one adapter so a price such
-- as 10 or 613 can never be handed to Texture:SetTexture as a file ID.
function OTLGM:IsTextureReference(value)
    if type(value) ~= "string" then return false end
    value = self:Trim(value)
    if value == "" or value == "0" or value == "?" or string.len(value) < 8 then return false end
    local lower = string.lower(value)
    if string.find(lower, "white8x8", 1, true) then return false end
    if not string.find(value, "\\", 1, true) and not string.find(value, "/", 1, true) then return false end
    -- RC3 from older builds could truncate a misplaced texture path while
    -- serializing it as equipLoc. A path ending in a separator/underscore is
    -- not a usable item texture and otherwise renders as a solid red square.
    local tail = string.sub(value, -1)
    if tail == "\\" or tail == "/" or tail == "_" then return false end
    return true
end

function OTLGM:GetItemInfoSafe(item)
    if not GetItemInfo then return nil end
    local ok, name, link, quality, itemLevel, requiredLevel, itemType,
        seventh, eighth, ninth, tenth, eleventh, twelfth = pcall(GetItemInfo, item)
    if not ok then return nil end

    local texture
    if self:IsTextureReference(tenth) then texture = tenth
    elseif self:IsTextureReference(ninth) then texture = ninth
    elseif self:IsTextureReference(eleventh) then texture = eleventh
    elseif self:IsTextureReference(twelfth) then texture = twelfth
    elseif self:IsTextureReference(eighth) then texture = eighth end

    local itemSubType = type(seventh) == "string" and not self:IsTextureReference(seventh) and seventh or ""
    local stackCount = tonumber(eighth) or 0
    local equipLoc = ""
    if type(ninth) == "string" and not self:IsTextureReference(ninth) then equipLoc = ninth end
    if equipLoc == "" and type(eighth) == "string" and string.find(eighth, "^INVTYPE_") then equipLoc = eighth end

    return name, link, quality, itemLevel, requiredLevel, itemType,
        itemSubType, stackCount, equipLoc, texture
end

OTLGM:RegisterModule("Bootstrap", {
    version = OTLGM.version,
    schema = OTLGM.schemaVersion,
})
