-- Transactional, type-safe full backup format. It serializes durable settings
-- and the active guild database without executing imported text as Lua code.

local LegacyImportBackup160 = OTLGM._Legacy_ImportBackupV1

local BACKUP_HEADER = "OTLGM_BACKUP_V2"
local MAX_BACKUP_BYTES = 2000000
local MAX_BACKUP_ENTRIES = 160000
local MAX_BACKUP_DEPTH = 18
local MAX_BACKUP_STRING = 16000

local function EscapeToken(value)
    value = tostring(value or "")
    local parts = {}
    local index, character
    for index = 1, string.len(value) do
        character = string.sub(value, index, index)
        if character == "%" then table.insert(parts, "%25")
        elseif character == "|" then table.insert(parts, "%7C")
        elseif character == "/" then table.insert(parts, "%2F")
        elseif character == "\n" then table.insert(parts, "%0A")
        elseif character == "\r" then table.insert(parts, "%0D")
        else table.insert(parts, character) end
    end
    return table.concat(parts)
end

local function UnescapeToken(value)
    value = tostring(value or "")
    value = string.gsub(value, "%%0D", "\r")
    value = string.gsub(value, "%%0A", "\n")
    value = string.gsub(value, "%%2F", "/")
    value = string.gsub(value, "%%7C", "|")
    value = string.gsub(value, "%%25", "%%")
    return value
end

local function HashLine(hash, line)
    local index
    for index = 1, string.len(line) do hash = math.mod((hash * 33) + string.byte(line, index), 2147483000) end
    return hash
end

local function EncodeSegment(key)
    if type(key) == "number" then return "N:" .. tostring(key) end
    return "S:" .. EscapeToken(key)
end

local function SortedKeys(tableValue, state)
    local keys = {}
    local key
    for key in pairs(tableValue or {}) do
        if type(key) ~= "string" and type(key) ~= "number" then
            state.error = "Unsupported backup key type: " .. type(key)
            return keys
        end
        table.insert(keys, key)
    end
    table.sort(keys, function(left, right)
        if type(left) ~= type(right) then return type(left) == "number" end
        if type(left) == "number" then return left < right end
        return tostring(left) < tostring(right)
    end)
    return keys
end

local function Emit(state, line)
    if state.error then return false end
    state.count = state.count + 1
    state.bytes = state.bytes + string.len(line) + 1
    if state.count > MAX_BACKUP_ENTRIES then state.error = "The database has too many backup entries." return false end
    if state.bytes > MAX_BACKUP_BYTES then state.error = "The full backup is larger than the safe in-game copy limit." return false end
    table.insert(state.lines, line)
    state.hash = HashLine(state.hash, line)
    return true
end

local function SerializeValue(state, value, path, depth)
    if state.error then return end
    if depth > MAX_BACKUP_DEPTH then state.error = "The database nesting depth is invalid." return end
    local valueType = type(value)
    if valueType == "table" then
        if state.stack[value] then state.error = "The database contains a cyclic table." return end
        state.stack[value] = true
        if not Emit(state, "T|" .. path) then state.stack[value] = nil return end
        local keys = SortedKeys(value, state)
        local index, key, childPath
        for index = 1, table.getn(keys) do
            key = keys[index]
            childPath = path .. "/" .. EncodeSegment(key)
            SerializeValue(state, value[key], childPath, depth + 1)
            if state.error then break end
        end
        state.stack[value] = nil
    elseif valueType == "string" then
        if string.len(value) > MAX_BACKUP_STRING then state.error = "A database text field is unexpectedly large." return end
        Emit(state, "V|" .. path .. "|S|" .. EscapeToken(value))
    elseif valueType == "number" then
        local encoded = tostring(value)
        if value ~= value or encoded == "inf" or encoded == "-inf" then state.error = "The database contains an invalid number." return end
        Emit(state, "V|" .. path .. "|N|" .. encoded)
    elseif valueType == "boolean" then
        Emit(state, "V|" .. path .. "|B|" .. (value and "1" or "0"))
    elseif value ~= nil then
        state.error = "Unsupported backup value type: " .. valueType
    end
end

local function BuildDurableSnapshot(self, db)
    local guild = self:Copy(db, MAX_BACKUP_DEPTH)
    local settings = self:Copy(OTLGM_DB and OTLGM_DB.settings or {}, MAX_BACKUP_DEPTH)
    if type(guild) ~= "table" or type(settings) ~= "table" then return nil end

    guild.pendingInvites = {}
    guild.pendingActions = {}
    guild.pendingAnnouncements = {}
    if type(guild.crafting) == "table" then
        guild.crafting.pendingRecipes = {}
        guild.crafting.cacheQueue = nil
        guild.crafting.syncState = { active = false, started = 0, completed = 0, received = 0 }
    end
    if type(guild.pve) == "table" then guild.pve.applicationRetries = {} end
    guild.schemaVersion = self.schemaVersion
    return { settings = settings, guild = guild }
end

function OTLGM:ExportBackup()
    local db = self:GetGuildDB()
    if not db then return BACKUP_HEADER .. "\nERROR|No guild database is available." end
    local snapshot = BuildDurableSnapshot(self, db)
    if not snapshot then return BACKUP_HEADER .. "\nERROR|The database could not be prepared safely." end

    local state = { lines = {}, count = 0, bytes = 0, hash = 5381, stack = {} }
    SerializeValue(state, snapshot.settings, EncodeSegment("settings"), 1)
    SerializeValue(state, snapshot.guild, EncodeSegment("guild"), 1)
    if state.error then return BACKUP_HEADER .. "\nERROR|" .. state.error end

    local lines = {
        BACKUP_HEADER,
        table.concat({ "META", EscapeToken(self.version), tostring(self.schemaVersion), tostring(self:Now()), EscapeToken(db.realm or ""), EscapeToken(db.name or "") }, "|"),
    }
    local index
    for index = 1, table.getn(state.lines) do table.insert(lines, state.lines[index]) end
    table.insert(lines, "CHECK|" .. tostring(state.count) .. "|" .. tostring(state.hash))
    table.insert(lines, "END")
    local result = table.concat(lines, "\n")
    if string.len(result) > MAX_BACKUP_BYTES then return BACKUP_HEADER .. "\nERROR|The full backup is larger than the safe in-game copy limit." end
    return result
end

local function SplitLines(text)
    local lines = {}
    text = string.gsub(tostring(text or ""), "\r\n", "\n")
    text = string.gsub(text, "\r", "\n")
    local startAt = 1
    while startAt <= string.len(text) + 1 do
        local found = string.find(text, "\n", startAt, true)
        if not found then table.insert(lines, string.sub(text, startAt)) break end
        table.insert(lines, string.sub(text, startAt, found - 1))
        startAt = found + 1
    end
    return lines
end

local function DecodeSegment(segment)
    local prefix = string.sub(segment or "", 1, 2)
    local value = string.sub(segment or "", 3)
    if prefix == "S:" then
        value = UnescapeToken(value)
        if string.len(value) > 200 then return nil, "A backup key is too long." end
        return value
    end
    if prefix == "N:" then
        local number = tonumber(value)
        if not number or number ~= math.floor(number) or math.abs(number) > 10000000 then return nil, "A numeric backup key is invalid." end
        return number
    end
    return nil, "A backup path segment is invalid."
end

local function DecodePath(self, path)
    if not path or path == "" or string.len(path) > 1200 then return nil, "A backup path is invalid." end
    local encoded = self:Split(path, "/")
    local decoded = {}
    local index, key, problem
    for index = 1, table.getn(encoded) do
        key, problem = DecodeSegment(encoded[index])
        if problem then return nil, problem end
        table.insert(decoded, key)
    end
    if table.getn(decoded) > MAX_BACKUP_DEPTH then return nil, "A backup path is too deep." end
    return decoded
end

local function AssignPath(root, path, value, isTable)
    local parent = root
    local index, key
    for index = 1, table.getn(path) - 1 do
        key = path[index]
        if type(parent[key]) ~= "table" then return false, "A backup parent table is missing." end
        parent = parent[key]
    end
    key = path[table.getn(path)]
    if parent[key] ~= nil then return false, "A backup path is duplicated." end
    parent[key] = isTable and {} or value
    return true
end

local function DecodeScalar(kind, encoded)
    if kind == "S" then
        local value = UnescapeToken(encoded)
        if string.len(value) > MAX_BACKUP_STRING then return nil, "A backup text field is too large." end
        return value
    end
    if kind == "N" then
        local value = tonumber(encoded)
        if not value or value ~= value or value == math.huge or value == -math.huge then return nil, "A backup number is invalid." end
        return value
    end
    if kind == "B" and (encoded == "0" or encoded == "1") then return encoded == "1" end
    return nil, "A backup value type is invalid."
end

local function ValidateImportedSnapshot(self, snapshot, metadata)
    if type(snapshot.settings) ~= "table" or type(snapshot.guild) ~= "table" then return false, "The backup does not contain settings and guild data." end
    if not tonumber(metadata.schema) or not tonumber(metadata.created) then return false, "The backup metadata is invalid." end
    if tonumber(metadata.schema) > tonumber(self.schemaVersion) then return false, "This backup was created by a newer, incompatible addon version." end
    local storedSchema = tonumber(snapshot.guild.schemaVersion) or tonumber(metadata.schema)
    if not storedSchema or storedSchema < 0 then return false, "The guild schema in this backup is invalid." end
    if storedSchema > tonumber(self.schemaVersion) then return false, "The guild data was created by a newer, incompatible addon version." end
    local currentName = GetGuildInfo("player") or ""
    local importedName = snapshot.guild.name or metadata.guild or ""
    if self:NormalizeName(currentName) ~= self:NormalizeName(importedName) then return false, "This backup belongs to a different guild." end
    local currentRealm = GetCVar("realmName") or "UnknownRealm"
    local importedRealm = snapshot.guild.realm or metadata.realm or ""
    if importedRealm ~= "" and string.lower(importedRealm) ~= string.lower(currentRealm) then return false, "This backup belongs to a different realm." end
    snapshot.guild.roster = type(snapshot.guild.roster) == "table" and snapshot.guild.roster or {}
    snapshot.guild.log = type(snapshot.guild.log) == "table" and snapshot.guild.log or {}
    snapshot.guild.pendingInvites = {}
    snapshot.guild.pendingActions = {}
    snapshot.guild.pendingAnnouncements = {}
    if type(snapshot.guild.crafting) == "table" then
        snapshot.guild.crafting.pendingRecipes = {}
        snapshot.guild.crafting.cacheQueue = nil
        snapshot.guild.crafting.syncState = { active = false, started = 0, completed = 0, received = 0 }
    end
    if type(snapshot.guild.pve) == "table" then snapshot.guild.pve.applicationRetries = {} end
    return true
end

function OTLGM:ImportBackup(text)
    text = tostring(text or "")
    if string.len(text) > MAX_BACKUP_BYTES then return false, "The pasted backup is larger than the safe import limit." end
    if string.find(text, "^OTLGM_BACKUP_V1") then
        if not LegacyImportBackup160 then return false, "Legacy backup import is unavailable." end
        local _, _, encodedRealm, encodedGuild = string.find(text, "\nG|([^|]*)|([^|]*)|")
        if not encodedRealm or not encodedGuild then return false, "The legacy backup metadata is missing." end
        local currentRealm = GetCVar("realmName") or "UnknownRealm"
        local currentGuild = GetGuildInfo("player") or ""
        if string.lower(UnescapeToken(encodedRealm)) ~= string.lower(currentRealm)
            or self:NormalizeName(UnescapeToken(encodedGuild)) ~= self:NormalizeName(currentGuild) then
            return false, "This legacy backup belongs to a different guild or realm."
        end
        local ok, message = LegacyImportBackup160(self, text)
        if ok then
            local db = self:GetGuildDB()
            if db then self:MigrateGuildDB(db) end
            self:EnsureDB()
            self:ResetSessionData()
            if self.RefreshVisiblePage then self:RefreshVisiblePage() elseif self.RefreshAll then self:RefreshAll() end
        end
        return ok, message
    end

    local lines = SplitLines(text)
    if lines[1] ~= BACKUP_HEADER then return false, "The text is not an Order of the Lion backup." end
    local snapshot = {}
    local metadata = {}
    local calculatedHash, calculatedCount = 5381, 0
    local expectedHash, expectedCount, foundEnd, foundCheck = nil, nil, false, false
    local index
    for index = 2, table.getn(lines) do
        local line = lines[index]
        if line ~= "" then
            local fields = self:Split(line, "|")
            local kind = fields[1]
            if kind == "META" then
                if metadata.seen then return false, "The backup metadata is duplicated." end
                metadata = { seen = true, version = UnescapeToken(fields[2]), schema = tonumber(fields[3]), created = tonumber(fields[4]), realm = UnescapeToken(fields[5]), guild = UnescapeToken(fields[6]) }
            elseif kind == "T" or kind == "V" then
                if foundCheck then return false, "The backup contains data after its checksum." end
                calculatedCount = calculatedCount + 1
                if calculatedCount > MAX_BACKUP_ENTRIES then return false, "The backup contains too many entries." end
                calculatedHash = HashLine(calculatedHash, line)
                local path, problem = DecodePath(self, fields[2])
                if not path then return false, problem end
                local value, ok
                if kind == "T" then ok, problem = AssignPath(snapshot, path, nil, true)
                else
                    value, problem = DecodeScalar(fields[3], fields[4] or "")
                    if problem then return false, problem end
                    ok, problem = AssignPath(snapshot, path, value, false)
                end
                if not ok then return false, problem end
            elseif kind == "CHECK" then
                if foundCheck then return false, "The backup checksum record is duplicated." end
                expectedCount, expectedHash = tonumber(fields[2]), tonumber(fields[3])
                foundCheck = true
            elseif kind == "END" then
                if not foundCheck then return false, "The backup checksum is missing." end
                foundEnd = true
                local trailingIndex
                for trailingIndex = index + 1, table.getn(lines) do
                    if lines[trailingIndex] ~= "" then return false, "The backup contains data after its end marker." end
                end
                break
            else
                return false, "The backup contains an unknown record."
            end
        end
    end
    if not metadata.seen or not foundEnd or not expectedCount or not expectedHash then return false, "The backup is incomplete." end
    if expectedCount ~= calculatedCount or expectedHash ~= calculatedHash then return false, "The backup checksum does not match; paste it again without editing." end
    local valid, problem = ValidateImportedSnapshot(self, snapshot, metadata)
    if not valid then return false, problem end

    local guildKey = self:GuildKey()
    if not guildKey then return false, "No current guild database is available." end
    local previousGuild = self:Copy(OTLGM_DB.guilds[guildKey], MAX_BACKUP_DEPTH)
    local previousSettings = self:Copy(OTLGM_DB.settings, MAX_BACKUP_DEPTH)
    if type(previousGuild) ~= "table" or type(previousSettings) ~= "table" then return false, "The current database could not be copied for a safe rollback." end
    local previousVersion, previousSchema = OTLGM_DB.version, OTLGM_DB.schemaVersion
    local committed, commitProblem = pcall(function()
        OTLGM_DB.settings = snapshot.settings
        OTLGM_DB.guilds[guildKey] = snapshot.guild
        OTLGM_DB.version = self.version
        OTLGM_DB.schemaVersion = self.schemaVersion
        self:MigrateGuildDB(snapshot.guild)
        self:EnsureDB()
        self:ResetSessionData()
    end)
    if not committed then
        OTLGM_DB.settings = previousSettings
        OTLGM_DB.guilds[guildKey] = previousGuild
        OTLGM_DB.version = previousVersion
        OTLGM_DB.schemaVersion = previousSchema
        pcall(function() self:EnsureDB() self:ResetSessionData() end)
        return false, "The backup could not be committed safely; the previous data was restored. " .. tostring(commitProblem)
    end
    self.runtime.preImportBackup160 = { guildKey = guildKey, guild = previousGuild, settings = previousSettings }
    pcall(function()
        if self.RefreshVisiblePage then self:RefreshVisiblePage() elseif self.RefreshAll then self:RefreshAll() end
    end)
    return true, "Full backup restored: " .. tostring(calculatedCount) .. " validated data entries."
end

OTLGM:RegisterModule("Backup", {
    format = 2,
    transactional = true,
    checksum = true,
    legacyImport = LegacyImportBackup160 and true or false,
})
