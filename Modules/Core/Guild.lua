-- Order of the Lion Guild Manager
-- Core systems for Vanilla WoW / OctoWoW (Interface 11200)

OTLGM = OTLGM or {}
OTLGM.pendingScan = false
OTLGM.pendingSilent = true
OTLGM.elapsed = 0
OTLGM.ui = OTLGM.ui or {}

OTLGM.colors = OTLGM.colors or {
    gold = "|cffffd36b",
    green = "|cff69cc73",
    red = "|cffff7777",
    grey = "|cffaaaaaa",
    darkGrey = "|cff777777",
    white = "|cffffffff",
    blue = "|cff69a8ff",
    purple = "|cffb06cff",
    reset = "|r",
}

OTLGM.classHex = {
    warrior = "|cffc79c6e",
    mage = "|cff69ccf0",
    rogue = "|cfffff569",
    druid = "|cffff7d0a",
    hunter = "|cffabd473",
    shaman = "|cff0070de",
    priest = "|cffffffff",
    warlock = "|cff9482c9",
    paladin = "|cfff58cba",
}


OTLGM.professionDefinitions = {
    { key = "ALCHEMY", label = "Alchemy", terms = { "alchemy", "alchemist" } },
    { key = "COOKING", label = "Cooking", terms = { "cooking", "cook" } },
    { key = "BLACKSMITHING", label = "Blacksmithing", terms = { "blacksmith", "blacksmithing" } },
    { key = "ENCHANTING", label = "Enchanting", terms = { "enchanting", "enchanter" } },
    { key = "ENGINEERING", label = "Engineering", terms = { "engineering", "engineer" } },
    { key = "JEWELCRAFTING", label = "Jewelcrafting", terms = { "jewelcrafting", "jewelcrafter", "jc" } },
    { key = "HERBALISM", label = "Herbalism", terms = { "herbalism", "herbalist" } },
    { key = "LEATHERWORKING", label = "Leatherworking", terms = { "leatherworking", "leatherworker" } },
    { key = "MINING", label = "Mining", terms = { "mining", "miner" } },
    { key = "SKINNING", label = "Skinning", terms = { "skinning", "skinner" } },
    { key = "TAILORING", label = "Tailoring", terms = { "tailoring", "tailor" } },
}



local LEGACY_RECRUIT_BASE1_180 = "[ENG/EU] <Order of the Lion> is looking for new, returning and casual players for relaxed PvE, leveling, dungeons, professions and future raids. Active Discord. Formed guild Lions Pride"
local LEGACY_RECRUIT_BASE2_180 = "No one has to level alone. Looking for players who want a calm guild, dungeons, farm, professions and future PvE plans. Formed \"Lion's Pride\", <Order of the Lion> [ENG/EU]"
-- CP7: these are the exact addon-owned social defaults observed in the live CP6
-- SavedVariables. Older builds stamped updatedAt even when the text was still the
-- built-in default, so updatedAt cannot be used as proof of a Leadership edit.
local LEGACY_RECRUIT_BASE1_LIVE_CP7 = "[ENG/EU] Crossfaction <Order of the Lion> is looking for new, returning and casual players for relaxed PvE, leveling, dungeons, professions and future raids. Active Discord + Own Guild Addon. Formed guild Lions Pride."
local LEGACY_RECRUIT_BASE2_LIVE_CP7 = "No one has to level alone. Looking for SOCIAL players (both factions) who want a calm guild, dungeons, farm, professions and future PvE plans. Live Discord and own guild addon. Formed \"Lion's Pride\", <Order of the Lion> [ENG/EU]"
local R59_RECRUIT_BASE1_180 = "[ENG/EU] <Order of the Lion> is looking for new, returning and casual players for relaxed PvE, leveling, dungeons, professions and more. Weekly Sunday raids at 20:00 ST, 2SR > MS > OS. Active Discord + guild addon. Former Lion's Pride."
local R59_RECRUIT_BASE2_180 = "No one has to level alone. <Order of the Lion> welcomes social and casual players for leveling, dungeons, professions and relaxed PvE. Sunday raids 20:00 ST, 2SR > MS > OS. Active Discord + guild addon. Former Lion's Pride. [ENG/EU]"
-- r53 temporarily replaced World Message 2 with a raid-specific line. r54 restored
-- both established social messages. r55 keeps them intact and inserts the protected
-- raid preset between them in the confirmed Send Next queue.
local R53_RECRUIT_BASE1_180 = "[ENG/EU] <Order of the Lion> - friendly PvE guild for leveling, dungeons, professions & weekly raids. New/returning players welcome. Discord: https://discord.gg/UNacDPrGt2"
local R53_RECRUIT_BASE2_180 = "[ENG/EU] <Order of the Lion> recruiting raiders for Sundays 20:00 ST. Reliable lvl 60 players wanted; all roles/classes welcome. 2SR > MS > OS. Discord: https://discord.gg/UNacDPrGt2"
local R54_RECRUIT_RAID_180 = "[ENG/EU] <Order of the Lion> recruiting for our raid roster. Looking for lvl 60 players for regular guild raids and endgame PvE. All classes welcome. Discord: https://discord.gg/UNacDPrGt2"
local R55_RECRUIT_RAID_180 = "[ENG/EU] <Order of the Lion> recruiting for Sunday raids at 20:00 ST. Steady guild roster, 2SR > MS > OS. Sign-ups & raid info: https://discord.gg/UNacDPrGt2"
local R56_RECRUIT_RAID1_180 = "[ENG/EU] <Order of the Lion> recruiting for our Sunday raid roster - 20:00 ST, 2SR > MS > OS. Looking especially for Rogues, Mages and 1-2 more healers; Hpala/Rdruid priority. /w for info"
local R56_RECRUIT_RAID2_180 = "[ENG/EU] <Order of the Lion> filling our Sunday 20:00 ST raid roster. 2SR > MS > OS. Need a few more solid players - healers are the main priority, with room for Rogue/Mage as well. /w for info"

local function IsAddonOwnedSocialDefaultCP7(index, text)
    text = tostring(text or "")
    if index == 1 then
        return text == LEGACY_RECRUIT_BASE1_180 or text == LEGACY_RECRUIT_BASE1_LIVE_CP7 or text == R53_RECRUIT_BASE1_180
    end
    return text == LEGACY_RECRUIT_BASE2_180 or text == LEGACY_RECRUIT_BASE2_LIVE_CP7 or text == R53_RECRUIT_BASE2_180
end

-- Send Next intentionally alternates ordinary/social recruitment with two raid
-- messages without adding another background rotation system. The established
-- social messages remain editable World Message 1/2; the two raid presets are
-- fixed current guild defaults: Social 1 -> Raid 1 -> Social 2 -> Raid 2.
local RECRUITMENT_SEND_QUEUE_R56 = { "BASE1", "RAID1", "BASE2", "RAID2" }

OTLGM.recruitmentPresets = {
    BASE1 = {
        label = "Recruit 1",
        target = "WORLD",
        text = R59_RECRUIT_BASE1_180,
    },
    BASE2 = {
        label = "Recruit 2",
        target = "WORLD",
        text = R59_RECRUIT_BASE2_180,
    },
    RAID1 = {
        label = "Raid 1",
        target = "WORLD",
        text = R56_RECRUIT_RAID1_180,
    },
    RAID2 = {
        label = "Raid 2",
        target = "WORLD",
        text = R56_RECRUIT_RAID2_180,
    },
    GUILDINFO = {
        label = "Share Discord",
        target = "GUILD",
        text = "[Guild Discord] Join for guides, raid info, announcements, help, events and guild chat. Stay connected outside the game if the server is unavailable. Discord also counts as your first guild rank promotion. https://discord.gg/UNacDPrGt2",
    },
    ADDONINFO = {
        label = "Share Addon",
        target = "GUILD",
        text = "[Lion Addon] OrderOfTheLionGM - our guild addon for profiles, professions, groups & achievements. Download: https://github.com/Relyway/OrderOfTheLionGM",
    },
}

function OTLGM:GetRecruitmentQueueStepR56(index)
    index = math.floor(tonumber(index) or 1)
    if index < 1 or index > table.getn(RECRUITMENT_SEND_QUEUE_R56) then index = 1 end
    local key = RECRUITMENT_SEND_QUEUE_R56[index]
    local marker = key == "RAID1" and "R1" or key == "RAID2" and "R2" or (key == "BASE2" and "S2" or "S1")
    return key, index, marker
end

function OTLGM:AdvanceRecruitmentQueueR56()
    if not OTLGM_DB or not OTLGM_DB.settings then return 1 end
    local _, index = self:GetRecruitmentQueueStepR56(OTLGM_DB.settings.nextRecruitIndex)
    index = index + 1
    if index > table.getn(RECRUITMENT_SEND_QUEUE_R56) then index = 1 end
    OTLGM_DB.settings.nextRecruitIndex = index
    return index
end

-- Compatibility aliases for r55 callers that may still exist in SavedVariables-era
-- callbacks during an in-place upgrade. New code uses the r56 names above.
OTLGM.GetRecruitmentQueueStepR55 = OTLGM.GetRecruitmentQueueStepR56
OTLGM.AdvanceRecruitmentQueueR55 = OTLGM.AdvanceRecruitmentQueueR56

local function Trim(text)
    if not text then return "" end
    local trimmed = string.gsub(text, "^%s*(.-)%s*$", "%1")
    return trimmed
end

local function NormalizeName(name)
    name = Trim(name or "")
    local normalized = string.gsub(name, "%-.*$", "")
    return string.lower(normalized)
end

-- Canonical guild-leader identity for guild-specific presentation and
-- achievements.  Server permission checks intentionally remain separate: they
-- still use the live guild APIs/rank flags below and are never granted merely
-- because a character name matches this list.
local CANONICAL_GUILD_LEADERS180 = {
    -- Live/current guild-leader identity is intentionally strict. Historical
    -- Morrow records remain readable through display/history compatibility,
    -- but must never grant current GL presentation, permissions or conditions.
    lucks = true,
}

function OTLGM:IsCanonicalGuildLeaderName180(name)
    return CANONICAL_GUILD_LEADERS180[NormalizeName(name)] and true or false
end

function OTLGM:GetCanonicalGuildLeaderName180()
    -- Lucks is the only current user-facing/canonical guild leader. Historical
    -- Morrow records are handled by display/history compatibility, not this live helper.
    return "Lucks"
end

function OTLGM:DisplayGuildActor180(value)
    local raw = tostring(value or "Leadership")
    if NormalizeName(raw) == "morrow" then return "Lucks" end
    return raw
end

local function SafeBooleanFunction(fn)
    if not fn then return false end
    local ok, result = pcall(fn)
    if not ok then return false end
    return result and true or false
end

function OTLGM:Now()
    return time()
end

function OTLGM:Stamp(timestamp)
    if not timestamp then return "Never" end
    return date("%d/%m/%Y %H:%M", timestamp)
end

function OTLGM:TodayKey()
    return date("%Y-%m-%d")
end

function OTLGM:ApplyCoreDefaults()
    if not OTLGM_DB then OTLGM_DB = {} end
    if not OTLGM_DB.guilds then OTLGM_DB.guilds = {} end
    if not OTLGM_DB.settings then OTLGM_DB.settings = {} end

    local settings = OTLGM_DB.settings
    if settings.autoScan == nil then settings.autoScan = true end
    if settings.chatNotices == nil then settings.chatNotices = true end
    if settings.showMinimap == nil then settings.showMinimap = true end
    if settings.classColors == nil then settings.classColors = true end
    if settings.highlightLeadership == nil then settings.highlightLeadership = true end
    if settings.scanInterval == nil then settings.scanInterval = 600 end
    if settings.minimapX == nil then settings.minimapX = -70 end
    if settings.minimapY == nil then settings.minimapY = -52 end
    if settings.worldChannel == nil or settings.worldChannel == "" or settings.worldChannel == "World" then settings.worldChannel = "6" end
    if settings.customTarget == nil then settings.customTarget = "WORLD" end
    if settings.rosterSortKey == nil then settings.rosterSortKey = "RANK" end
    if settings.rosterSortAsc == nil then settings.rosterSortAsc = true end
    if settings.rosterFilter == nil then settings.rosterFilter = "ALL" end
    if settings.rosterRankFilter == nil then settings.rosterRankFilter = "" end
    if settings.rosterProfessionFilter == nil then settings.rosterProfessionFilter = "" end
    if settings.rosterSearch == nil then settings.rosterSearch = "" end
    if settings.lastPage == nil then settings.lastPage = "overview" end
    if settings.historyFilter == nil then settings.historyFilter = "ALL" end
    if settings.windowX == nil then settings.windowX = 0 end
    if settings.windowY == nil then settings.windowY = 10 end
    if settings.windowWidth180 == nil then settings.windowWidth180 = 1160 end
    if settings.windowHeight180 == nil then settings.windowHeight180 = 740 end
    if settings.windowSizePreset180 == nil then
        -- Existing 1.8 test installs may already contain a manually resized
        -- window but no preset marker. Preserve that geometry as Custom rather
        -- than falsely labelling a 1000x700 window as Normal.
        local savedWidth = tonumber(settings.windowWidth180) or 1160
        local savedHeight = tonumber(settings.windowHeight180) or 740
        if math.abs(savedWidth - 1160) <= 2 and math.abs(savedHeight - 740) <= 2 then
            settings.windowSizePreset180 = "NORMAL"
        else
            settings.windowSizePreset180 = "CUSTOM"
        end
    end
    if settings.keepWindowInsideScreen180 == nil then
        -- r59: safe fresh-install default. Existing users keep their explicit
        -- saved choice, including false, so upgrades never move a window
        -- against the player's preference.
        settings.keepWindowInsideScreen180 = true
    end
    if settings.customMessageNames == nil then settings.customMessageNames = { "Custom 1", "Custom 2", "Custom 3" } end
    if settings.recruitmentLastSent == nil then settings.recruitmentLastSent = {} end
    if settings.recruitmentReminderSeconds == nil then settings.recruitmentReminderSeconds = 300 end
    if settings.worldRecruitmentMinSeconds == nil then settings.worldRecruitmentMinSeconds = 480 end
    if settings.worldRecruitmentRecommendedSeconds == nil then settings.worldRecruitmentRecommendedSeconds = 600 end
    -- r59: the previous built-in 10/15 recommendation was never a user-facing
    -- custom value. Migrate that exact legacy pair to the agreed 8/10 window;
    -- any genuinely custom interval is preserved untouched.
    if not settings.worldRecruitmentWindowR59Migrated then
        if tonumber(settings.worldRecruitmentMinSeconds) == 600 and tonumber(settings.worldRecruitmentRecommendedSeconds) == 900 then
            settings.worldRecruitmentMinSeconds = 480
            settings.worldRecruitmentRecommendedSeconds = 600
        end
        settings.worldRecruitmentWindowR59Migrated = true
    end
    -- r55 expands the two-step A/B order into Social -> Raid -> Social -> Raid.
    -- Preserve the previously pending social message on upgrade: old index 2
    -- meant BASE2, which is step 3 in the new queue.
    if not settings.recruitmentAlternatingQueueR55Migrated then
        local oldNext = tonumber(settings.nextRecruitIndex) or 1
        settings.nextRecruitIndex = oldNext == 2 and 3 or 1
        settings.recruitmentAlternatingQueueR55Migrated = true
    end
    if not settings.recruitmentDualRaidQueueR56Migrated then
        if settings.selectedRecruitment == "RAID" then settings.selectedRecruitment = "RAID1" end
        if settings.recruitmentMessage == R54_RECRUIT_RAID_180 or settings.recruitmentMessage == R55_RECRUIT_RAID_180 then
            settings.recruitmentMessage = R56_RECRUIT_RAID1_180
        end
        settings.recruitmentDualRaidQueueR56Migrated = true
    end
    -- CP7 live migration: replace only exact historical addon-owned Social 1/2
    -- copies. This deliberately ignores their stale updatedAt marker because CP6
    -- proved that old builds could stamp the built-in text as if it were edited.
    -- Arbitrary Leadership text is never matched or rewritten.
    if IsAddonOwnedSocialDefaultCP7(1, settings.recruitmentMessage) and (settings.selectedRecruitment == nil or settings.selectedRecruitment == "BASE1") then
        settings.recruitmentMessage = R59_RECRUIT_BASE1_180
    elseif IsAddonOwnedSocialDefaultCP7(2, settings.recruitmentMessage) and settings.selectedRecruitment == "BASE2" then
        settings.recruitmentMessage = R59_RECRUIT_BASE2_180
    end
    if settings.guildChatChannel == nil then settings.guildChatChannel = "GUILD" end
    if settings.guildChatDrafts == nil then settings.guildChatDrafts = { GUILD = "", OFFICER = "" } end
    if settings.guildChatDrafts.GUILD == nil then settings.guildChatDrafts.GUILD = "" end
    if settings.guildChatDrafts.OFFICER == nil then settings.guildChatDrafts.OFFICER = "" end
    if settings.chatHighlightMentions == nil then settings.chatHighlightMentions = true end
    if settings.chatTimeSeparators == nil then settings.chatTimeSeparators = true end
    if settings.chatShowRanks == nil then settings.chatShowRanks = true end
    if settings.settingsSection == nil then settings.settingsSection = "GENERAL" end
    if settings.worldRecruitmentTimerMigrated == nil then
        if settings.lastWorldRecruitmentAt == nil then
            local baseOne = tonumber(settings.recruitmentLastSent.BASE1) or 0
            local baseTwo = tonumber(settings.recruitmentLastSent.BASE2) or 0
            if baseOne > 0 or baseTwo > 0 then
                if baseOne >= baseTwo then
                    settings.lastWorldRecruitmentAt = baseOne
                    settings.lastWorldRecruitmentLabel = "Recruit 1"
                else
                    settings.lastWorldRecruitmentAt = baseTwo
                    settings.lastWorldRecruitmentLabel = "Recruit 2"
                end
                settings.lastWorldRecruitmentChannel = tostring(settings.worldChannel or "6")
            end
        end
        settings.worldRecruitmentTimerMigrated = true
    end
    if not settings.customMessageNames[1] then settings.customMessageNames[1] = "Custom 1" end
    if not settings.customMessageNames[2] then settings.customMessageNames[2] = "Custom 2" end
    if not settings.customMessageNames[3] then settings.customMessageNames[3] = "Custom 3" end

    if not settings.customMessages then
        settings.customMessages = { "", "", "" }
        if settings.recruitmentMessage and settings.recruitmentMessage ~= "" then
            settings.customMessages[1] = settings.recruitmentMessage
            settings.selectedRecruitment = "CUSTOM1"
        end
    end
    if not settings.customMessages[1] then settings.customMessages[1] = "" end
    if not settings.customMessages[2] then settings.customMessages[2] = "" end
    if not settings.customMessages[3] then settings.customMessages[3] = "" end

    if not settings.selectedRecruitment then settings.selectedRecruitment = "BASE1" end
    if not settings.recruitmentMessage or settings.recruitmentMessage == "" then
        settings.recruitmentMessage = self:GetRecruitmentText(settings.selectedRecruitment)
        if settings.recruitmentMessage == "" then
            settings.selectedRecruitment = "BASE1"
            settings.recruitmentMessage = self.recruitmentPresets.BASE1.text
        end
    end

    OTLGM_DB.version = self.version
end

function OTLGM:EnsureRecruitmentRotation170()
    OTLGM_DB = OTLGM_DB or {}
    OTLGM_DB.settings = OTLGM_DB.settings or {}
    local settings = OTLGM_DB.settings
    if type(settings.recruitmentRotation170) ~= "table" then settings.recruitmentRotation170 = {} end
    local index
    for index = 1, 2 do
        local key = index == 1 and "BASE1" or "BASE2"
        local original = self.recruitmentPresets[key]
        local slot = settings.recruitmentRotation170[index]
        local legacyText = index == 1 and LEGACY_RECRUIT_BASE1_180 or LEGACY_RECRUIT_BASE2_180
        local r53Text = index == 1 and R53_RECRUIT_BASE1_180 or R53_RECRUIT_BASE2_180
        local addonDefaultMigratedR59 = false
        if type(slot) ~= "table" or type(slot.text) ~= "string" or slot.text == "" then
            settings.recruitmentRotation170[index] = {
                key = key, label = original and original.label or (index == 1 and "Recruit 1" or "Recruit 2"), target = "WORLD",
                text = original and original.text or "", updatedAt = 0, revision = 1,
            }
            addonDefaultMigratedR59 = true
        else
            slot.key = key
            -- Restore only exact addon-owned historical defaults. CP6 live data
            -- showed that old builds could stamp updatedAt on an untouched default,
            -- so that timestamp is not a safe ownership signal. Unknown/custom text
            -- remains byte-for-byte untouched.
            if IsAddonOwnedSocialDefaultCP7(index, slot.text) then
                slot.text = original and original.text or slot.text
                slot.label = original and original.label or slot.label
                addonDefaultMigratedR59 = true
            end
            if not slot.label or slot.label == "Recruit A" or slot.label == "Recruit B" or slot.label == "Guild Recruitment" or slot.label == "Raid Recruitment" then
                slot.label = original and original.label or (index == 1 and "Recruit 1" or "Recruit 2")
            end
            slot.target = "WORLD"
            slot.revision = tonumber(slot.revision) or 1
        end
        if addonDefaultMigratedR59 and IsAddonOwnedSocialDefaultCP7(index, settings.recruitmentMessage) then
            settings.recruitmentMessage = original and original.text or settings.recruitmentMessage
        end
    end
    if settings.selectedRecruitment == "BASE1" and IsAddonOwnedSocialDefaultCP7(1, settings.recruitmentMessage) then
        settings.recruitmentMessage = self.recruitmentPresets.BASE1.text
    elseif settings.selectedRecruitment == "BASE2" and IsAddonOwnedSocialDefaultCP7(2, settings.recruitmentMessage) then
        settings.recruitmentMessage = self.recruitmentPresets.BASE2.text
    end
    return settings.recruitmentRotation170
end

function OTLGM.__impl180.GetRecruitmentPreset170__impl1(self, key)
    if key == "BASE1" or key == "BASE2" then
        local rotation = self:EnsureRecruitmentRotation170()
        return rotation[key == "BASE1" and 1 or 2]
    end
    return self.recruitmentPresets[key]
end

function OTLGM:ReplaceRecruitmentRotation170(index, text)
    self:EnsureDB()
    if not ((self.CanPublishAnnouncement152 and self:CanPublishAnnouncement152()) or (self.CanEditOfficerNotes and self:CanEditOfficerNotes())) then
        return false, "Only guild leadership can change the recruitment rotation."
    end
    index = tonumber(index)
    if index ~= 1 and index ~= 2 then return false, "Choose World Message 1 or 2." end
    text = self:SafeText(text, 240, false, false)
    if text == "" then return false, "The recruitment message cannot be empty." end
    local rotation = self:EnsureRecruitmentRotation170()
    local old = rotation[index]
    local original = self.recruitmentPresets[index == 1 and "BASE1" or "BASE2"]
    rotation[index] = {
        key = index == 1 and "BASE1" or "BASE2", label = original and original.label or (index == 1 and "Recruit 1" or "Recruit 2"), target = "WORLD",
        text = text, updatedAt = self:Now(), updatedBy = string.gsub(UnitName("player") or "Leadership", "%-.*$", ""),
        revision = (tonumber(old and old.revision) or 0) + 1,
    }
    OTLGM_DB.settings.selectedRecruitment = rotation[index].key
    OTLGM_DB.settings.recruitmentMessage = text
    OTLGM_DB.settings.customTarget = "WORLD"
    if self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
    return true, rotation[index]
end

function OTLGM:GetRecruitmentText(key)
    local preset = self:GetRecruitmentPreset170(key)
    if preset then return preset.text or "" end

    local customText = string.gsub(key or "", "^CUSTOM", "")
    local index = tonumber(customText)
    if index and OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.customMessages then
        return OTLGM_DB.settings.customMessages[index] or ""
    end
    return ""
end

function OTLGM:SelectRecruitment(key)
    self:EnsureDB()
    local customText = string.gsub(key or "", "^CUSTOM", "")
    local customIndex = tonumber(customText)
    if not self.recruitmentPresets[key] and not (customIndex and customIndex >= 1 and customIndex <= 3 and key == "CUSTOM" .. tostring(customIndex)) then return end

    OTLGM_DB.settings.selectedRecruitment = key
    OTLGM_DB.settings.recruitmentMessage = self:GetRecruitmentText(key)
    self.pendingCustomSaveIndex = nil
    self.pendingCustomSaveTime = nil
    self.pendingCustomClearIndex = nil
    self.pendingCustomClearTime = nil
    local selectedPreset = self:GetRecruitmentPreset170(key)
    if selectedPreset then OTLGM_DB.settings.customTarget = selectedPreset.target or "WORLD" end
    if self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
end

function OTLGM:SaveSelectedCustom()
    self:EnsureDB()
    local key = OTLGM_DB.settings.selectedRecruitment or ""
    local customText = string.gsub(key, "^CUSTOM", "")
    local index = tonumber(customText)
    if not index then
        self:SetStatus("Pinned messages are protected. Select Custom 1, 2 or 3 before saving.")
        return
    end

    local current = OTLGM_DB.settings.recruitmentMessage or ""
    local saved = OTLGM_DB.settings.customMessages[index] or ""
    local now = self:Now()
    if saved ~= "" and saved ~= current then
        if self.pendingCustomSaveIndex ~= index or not self.pendingCustomSaveTime or (now - self.pendingCustomSaveTime) > 5 then
            self.pendingCustomSaveIndex = index
            self.pendingCustomSaveTime = now
            self:SetStatus("Custom " .. tostring(index) .. " already contains a message. Click Confirm Save within 5 seconds to overwrite it.")
            if self.RefreshRecruitmentButtons then self:RefreshRecruitmentButtons() end
            return
        end
    end

    OTLGM_DB.settings.customMessages[index] = current
    self.pendingCustomSaveIndex = nil
    self.pendingCustomSaveTime = nil
    self:SetStatus("Saved current text to Custom " .. tostring(index) .. ".")
    if self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
end

function OTLGM:SaveCurrentToCustom(index)
    self:EnsureDB()
    index = tonumber(index)
    if not index or index < 1 or index > 3 then return end

    local current = OTLGM_DB.settings.recruitmentMessage or ""
    local saved = OTLGM_DB.settings.customMessages[index] or ""
    local now = self:Now()
    if saved ~= "" and saved ~= current then
        if self.pendingCustomSaveIndex ~= index or not self.pendingCustomSaveTime or (now - self.pendingCustomSaveTime) > 5 then
            self.pendingCustomSaveIndex = index
            self.pendingCustomSaveTime = now
            self:SetStatus("Custom " .. tostring(index) .. " already contains a message. Click the same numbered save button again within 5 seconds.")
            if self.RefreshRecruitmentButtons then self:RefreshRecruitmentButtons() end
            return
        end
    end

    OTLGM_DB.settings.customMessages[index] = current
    OTLGM_DB.settings.selectedRecruitment = "CUSTOM" .. tostring(index)
    self.pendingCustomSaveIndex = nil
    self.pendingCustomSaveTime = nil
    self:SetStatus("Working copy saved to Custom " .. tostring(index) .. ".")
    if self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
end

function OTLGM:ClearSelectedCustom()
    self:EnsureDB()
    local key = OTLGM_DB.settings.selectedRecruitment or ""
    local customText = string.gsub(key, "^CUSTOM", "")
    local index = tonumber(customText)
    if not index then
        self:SetStatus("Select a custom slot before clearing it.")
        return
    end

    local now = self:Now()
    if (OTLGM_DB.settings.customMessages[index] or "") ~= "" then
        if self.pendingCustomClearIndex ~= index or not self.pendingCustomClearTime or (now - self.pendingCustomClearTime) > 5 then
            self.pendingCustomClearIndex = index
            self.pendingCustomClearTime = now
            self:SetStatus("Click Confirm Clear within 5 seconds to erase Custom " .. tostring(index) .. ".")
            if self.RefreshRecruitmentButtons then self:RefreshRecruitmentButtons() end
            return
        end
    end

    OTLGM_DB.settings.customMessages[index] = ""
    OTLGM_DB.settings.recruitmentMessage = ""
    self.pendingCustomClearIndex = nil
    self.pendingCustomClearTime = nil
    self:SetStatus("Custom " .. tostring(index) .. " cleared.")
    if self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
end

function OTLGM:GetRecruitmentPreview(text, maxLength)
    text = Trim(text or "")
    text = string.gsub(text, "[\r\n]+", " ")
    maxLength = maxLength or 34
    if string.len(text) > maxLength then return string.sub(text, 1, maxLength - 3) .. "..." end
    if text == "" then return "Empty" end
    return text
end

function OTLGM:GuildKey()
    local guildName = GetGuildInfo("player")
    local realm = GetCVar("realmName") or "UnknownRealm"
    if not guildName then return nil end
    return realm .. "::" .. guildName
end

function OTLGM:RecountHistoryUnreadR59(db, markRepair)
    if type(db) ~= "table" then return 0 end
    db.log = type(db.log) == "table" and db.log or {}
    local unreadR59 = 0
    local iR59
    for iR59 = 1, table.getn(db.log) do
        if db.log[iR59] and db.log[iR59].reviewed ~= true then unreadR59 = unreadR59 + 1 end
    end
    db.unread = unreadR59
    if markRepair ~= false then db.historyUnreadRecountR59 = true end
    return unreadR59
end

-- 1.8.3 final one-time recovery for the live-confirmed pre-CP7 roster burst.
-- A bad same-size roster snapshot could fill the retained History with hundreds
-- of JOIN/LEAVE rows even though the guild had not actually churned. The final
-- repair is intentionally strict: it only touches a history that is already
-- dominated by a near-balanced JOIN/LEAVE burst and only removes dense
-- short-window clusters. Ordinary joins/leaves and every other history kind are
-- preserved. The repair never needs a schema bump and runs at most once/guild.
function OTLGM:RepairSyntheticHistoryBurst183(db)
    if type(db) ~= "table" then return 0 end
    if db.historySyntheticBurstRepair183 then
        local state = db.historySyntheticBurstRepair183
        return type(state) == "table" and (tonumber(state.removed) or 0) or 0
    end

    db.log = type(db.log) == "table" and db.log or {}
    local total = table.getn(db.log)
    local joinTotal, leaveTotal = 0, 0
    local i, entry, kind
    for i = 1, total do
        entry = db.log[i]
        kind = tostring(entry and entry.kind or "")
        if kind == "JOIN" then joinTotal = joinTotal + 1
        elseif kind == "LEAVE" then leaveTotal = leaveTotal + 1 end
    end

    local jlTotal = joinTotal + leaveTotal
    local balanceLimit = math.max(12, math.floor(math.min(joinTotal, leaveTotal) * 0.08))
    local eligible = total >= 300 and joinTotal >= 100 and leaveTotal >= 100
        and jlTotal >= math.floor(total * 0.80)
        and math.abs(joinTotal - leaveTotal) <= balanceLimit

    local repair = { at = self:Now(), removed = 0, clusters = 0, join = joinTotal, leave = leaveTotal }
    db.historySyntheticBurstRepair183 = repair
    if not eligible then return 0 end

    local clusters = {}
    local current = nil
    local lastTs = nil
    for i = 1, total do
        entry = db.log[i]
        kind = tostring(entry and entry.kind or "")
        if kind == "JOIN" or kind == "LEAVE" then
            local ts = tonumber(entry and entry.ts) or 0
            if not current or not lastTs or ts <= 0 or math.abs(lastTs - ts) > 15 then
                current = { indices = {}, join = 0, leave = 0, newest = ts, oldest = ts }
                table.insert(clusters, current)
            end
            table.insert(current.indices, i)
            if kind == "JOIN" then current.join = current.join + 1 else current.leave = current.leave + 1 end
            if ts > 0 then
                if not current.newest or current.newest <= 0 or ts > current.newest then current.newest = ts end
                if not current.oldest or current.oldest <= 0 or ts < current.oldest then current.oldest = ts end
                lastTs = ts
            end
        end
    end

    local remove = {}
    local baselines = {}
    local c, cluster, clusterTotal, clusterLimit, idx
    for c = 1, table.getn(clusters) do
        cluster = clusters[c]
        clusterTotal = (tonumber(cluster.join) or 0) + (tonumber(cluster.leave) or 0)
        clusterLimit = math.max(8, math.floor(math.min(tonumber(cluster.join) or 0, tonumber(cluster.leave) or 0) * 0.10))
        if (tonumber(cluster.join) or 0) >= 40 and (tonumber(cluster.leave) or 0) >= 40
            and clusterTotal >= 100
            and math.abs((tonumber(cluster.join) or 0) - (tonumber(cluster.leave) or 0)) <= clusterLimit then
            for idx = 1, table.getn(cluster.indices) do remove[cluster.indices[idx]] = true end
            repair.clusters = repair.clusters + 1
            repair.removed = repair.removed + clusterTotal
            table.insert(baselines, {
                ts = tonumber(cluster.newest) or self:Now(),
                kind = "BASELINE", name = "Guild", reviewed = true,
                detail = "Recovered roster baseline: removed a synthetic mass JOIN/LEAVE history burst ("
                    .. tostring(cluster.join) .. "/" .. tostring(cluster.leave) .. ")",
                actor = "", source = "1.8.3 history repair",
            })
        end
    end

    if repair.removed <= 0 then return 0 end

    for i = total, 1, -1 do
        if remove[i] then table.remove(db.log, i) end
    end
    for i = 1, table.getn(baselines) do table.insert(db.log, 1, baselines[i]) end
    while table.getn(db.log) > 500 do table.remove(db.log) end
    self:RecountHistoryUnreadR59(db, true)
    return repair.removed
end

function OTLGM:GetOrCreateGuildDB()
    self:EnsureDB()
    local key = self:GuildKey()
    if not key then return nil end

    if not OTLGM_DB.guilds[key] then
        OTLGM_DB.guilds[key] = {
            name = GetGuildInfo("player"),
            realm = GetCVar("realmName") or "UnknownRealm",
            created = self:Now(),
            roster = {},
            log = {},
            daily = {},
            pendingInvites = {},
            pendingActions = {},
            initialized = false,
            lastScan = nil,
            lastTotal = 0,
            lastOnline = 0,
            unread = 0,
            schemaVersion = 2,
        }
    end

    local db = OTLGM_DB.guilds[key]
    if not db.roster then db.roster = {} end
    if not db.log then db.log = {} end
    if not db.daily then db.daily = {} end
    if not db.pendingInvites then db.pendingInvites = {} end
    if not db.pendingActions then db.pendingActions = {} end
    if db.unread == nil then db.unread = 0 end
    self:MigrateGuildDB(db)
    -- r59 repair: older builds incremented unread when adding a History row but
    -- did not decrement it when the 500-row retention cap removed an unread
    -- row. Repair each guild database once without deleting SavedVariables.
    if db.historyUnreadRecountR59 ~= true then self:RecountHistoryUnreadR59(db, true) end
    if not db.historySyntheticBurstRepair183 then self:RepairSyntheticHistoryBurst183(db) end
    return db
end

function OTLGM:MigrateLegacySchema2(db)
    if not db then return end
    if (db.schemaVersion or 0) >= 2 then return end

    local i, eventInfo, member, beforeRank, afterRank
    for i = 1, table.getn(db.log or {}) do
        eventInfo = db.log[i]
        if eventInfo then
            member = db.roster and db.roster[eventInfo.name] or nil
            if member then
                if not eventInfo.class or eventInfo.class == "" then eventInfo.class = member.class or "" end
                if not eventInfo.rank or eventInfo.rank == "" then eventInfo.rank = member.rank or "" end
            end
            if eventInfo.kind == "RANK" and (not eventInfo.rankBefore or not eventInfo.rankAfter) and eventInfo.detail then
                local startPos, endPos, foundBefore, foundAfter = string.find(eventInfo.detail, "^(.-)%s*%-%>%s*(.-)$")
                beforeRank = foundBefore
                afterRank = foundAfter
                if beforeRank and afterRank then
                    eventInfo.rankBefore = eventInfo.rankBefore or beforeRank
                    eventInfo.rankAfter = eventInfo.rankAfter or afterRank
                end
            end
            if eventInfo.kind == "LEVEL" and (not eventInfo.levelBefore or not eventInfo.levelAfter) and eventInfo.detail then
                local levelStart, levelEnd, oldLevel, newLevel = string.find(eventInfo.detail, "^(%d+)%s*%-%>%s*(%d+)$")
                if oldLevel and newLevel then
                    eventInfo.levelBefore = tonumber(oldLevel)
                    eventInfo.levelAfter = tonumber(newLevel)
                end
            end
        end
    end
    db.schemaVersion = 2
end

function OTLGM:RememberInvite(name)
    local db = self:GetGuildDB()
    if not db or not name or name == "" then return end
    db.pendingInvites[NormalizeName(name)] = {
        inviter = UnitName("player") or "You",
        ts = self:Now(),
    }
end

function OTLGM:ConsumeInvite(name)
    local db = self:GetGuildDB()
    if not db then return nil end
    local key = NormalizeName(name)
    local invite = db.pendingInvites[key]
    db.pendingInvites[key] = nil
    if invite and invite.ts and (self:Now() - invite.ts) <= 3600 then return invite end
    return nil
end

function OTLGM:CleanupPendingInvites(db)
    if not db or not db.pendingInvites then return end
    local key, invite
    for key, invite in pairs(db.pendingInvites) do
        if not invite.ts or (self:Now() - invite.ts) > 3600 then db.pendingInvites[key] = nil end
    end
end

function OTLGM:InstallInviteHook()
    if self.inviteHookInstalled or not GuildInvite then return end

    self.originalGuildInvite = GuildInvite
    GuildInvite = function(name)
        if OTLGM and name then OTLGM:RememberInvite(name) end
        return OTLGM.originalGuildInvite(name)
    end
    self.inviteHookInstalled = true
end

local function EscapeLuaPattern(text)
    if not text then return "" end
    text = string.gsub(text, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    return text
end

local function FormatStringToPattern(formatText)
    if not formatText or formatText == "" then return nil end
    local marker = "__OTLGM_PERCENT__"
    local pattern = string.gsub(formatText, "%%%%", marker)
    pattern = EscapeLuaPattern(pattern)
    pattern = string.gsub(pattern, "%%%%%d+%$s", "(.+)")
    pattern = string.gsub(pattern, "%%%%s", "(.+)")
    pattern = string.gsub(pattern, "%%%%%d+%$d", "(%%d+)")
    pattern = string.gsub(pattern, "%%%%d", "(%%d+)")
    pattern = string.gsub(pattern, marker, "%%%%")
    return "^" .. pattern .. "$"
end

function OTLGM:RememberGuildAction(kind, target, actor, source)
    local db = self:GetGuildDB()
    if not db or not target or target == "" then return end
    local key = NormalizeName(target)
    db.pendingActions[key] = {
        kind = kind or "",
        target = target,
        actor = actor or UnitName("player") or "",
        source = source or "local",
        ts = self:Now(),
    }
end

function OTLGM:ConsumeGuildAction(target, expectedKind)
    local db = self:GetGuildDB()
    if not db or not target then return nil end
    local key = NormalizeName(target)
    local action = db.pendingActions[key]
    if not action then return nil end
    if not action.ts or (self:Now() - action.ts) > 300 then
        db.pendingActions[key] = nil
        return nil
    end
    if expectedKind and action.kind ~= expectedKind then return nil end
    db.pendingActions[key] = nil
    return action
end

function OTLGM:CleanupPendingActions(db)
    if not db or not db.pendingActions then return end
    local key, action
    for key, action in pairs(db.pendingActions) do
        if not action.ts or (self:Now() - action.ts) > 300 then db.pendingActions[key] = nil end
    end
end

function OTLGM:HookGuildActionFunction(functionName, kind)
    self.guildActionHooks = self.guildActionHooks or {}
    if self.guildActionHooks[functionName] then return end
    local original = _G and _G[functionName]
    if type(original) ~= "function" then return end

    self.guildActionHooks[functionName] = original
    _G[functionName] = function(target)
        if OTLGM and target then OTLGM:RememberGuildAction(kind, target, UnitName("player") or "You", "local action") end
        return OTLGM.guildActionHooks[functionName](target)
    end
end

function OTLGM:InstallGuildActionHooks()
    if self.guildActionHooksInstalled then return end
    self:HookGuildActionFunction("GuildPromote", "PROMOTE")
    self:HookGuildActionFunction("GuildPromoteByName", "PROMOTE")
    self:HookGuildActionFunction("PromoteByName", "PROMOTE")
    self:HookGuildActionFunction("GuildDemote", "DEMOTE")
    self:HookGuildActionFunction("GuildDemoteByName", "DEMOTE")
    self:HookGuildActionFunction("DemoteByName", "DEMOTE")
    self:HookGuildActionFunction("GuildUninvite", "REMOVE")
    self:HookGuildActionFunction("GuildUninviteByName", "REMOVE")
    self:HookGuildActionFunction("GuildRemove", "REMOVE")
    self.guildActionHooksInstalled = true
end

function OTLGM:ApplyActorToRecentLog(actionKind, target, actor, source)
    local db = self:GetGuildDB()
    if not db or not target or not actor then return false end
    local expectedLogKind = actionKind == "REMOVE" and "LEAVE" or "RANK"
    local normalizedTarget = NormalizeName(target)
    local now = self:Now()
    local i, eventInfo
    for i = 1, math.min(20, table.getn(db.log)) do
        eventInfo = db.log[i]
        if eventInfo and eventInfo.ts and (now - eventInfo.ts) <= 30 and eventInfo.kind == expectedLogKind and NormalizeName(eventInfo.name) == normalizedTarget then
            if not eventInfo.actor or eventInfo.actor == "" then
                eventInfo.actor = actor
                eventInfo.source = source or "server message"
                if actionKind == "REMOVE" then eventInfo.detail = "Removed from the guild" end
            end
            return true
        end
    end
    return false
end

function OTLGM:TryCaptureSystemGuildAction(message)
    if not message or message == "" then return false end
    local patterns = {
        { kind = "PROMOTE", format = ERR_GUILD_PROMOTE_SSS, fallback = "^(.+) has promoted (.+) to (.+)%.$", actorPos = 1, targetPos = 2 },
        { kind = "DEMOTE", format = ERR_GUILD_DEMOTE_SSS, fallback = "^(.+) has demoted (.+) to (.+)%.$", actorPos = 1, targetPos = 2 },
        { kind = "REMOVE", format = ERR_GUILD_REMOVE_SS, fallback = "^(.+) has been kicked out of the guild by (.+)%.$", actorPos = 2, targetPos = 1 },
    }

    local i, item
    for i = 1, table.getn(patterns) do
        item = patterns[i]
        local pattern = FormatStringToPattern(item.format) or item.fallback
        local startPos, endPos, first, second, third = string.find(message, pattern)
        if not first then startPos, endPos, first, second, third = string.find(message, item.fallback) end
        if first and second then
            local values = { first, second, third }
            local target = values[item.targetPos]
            local actor = values[item.actorPos]
            if not self:ApplyActorToRecentLog(item.kind, target, actor, "server message") then
                self:RememberGuildAction(item.kind, target, actor, "server message")
            end
            if self.RefreshAll then self:RefreshAll() end
            return true
        end
    end
    return false
end

function OTLGM:BuildOfflineInfo(index, isOnline)
    if isOnline then return 0, "Online" end
    if not GetGuildRosterLastOnline then return 0, "Offline" end

    local years, months, days, hours = GetGuildRosterLastOnline(index)
    years = years or 0
    months = months or 0
    days = days or 0
    hours = hours or 0
    local totalHours = (((years * 12) + months) * 30 * 24) + (days * 24) + hours
    local text = "Offline"

    if years > 0 then
        text = tostring(years) .. "y " .. tostring(months) .. "mo"
    elseif months > 0 then
        text = tostring(months) .. "mo " .. tostring(days) .. "d"
    elseif days > 0 then
        text = tostring(days) .. "d " .. tostring(hours) .. "h"
    else
        text = tostring(hours) .. "h"
    end
    return totalHours, text
end

-- OctoWoW itself does not document a faction field in the stock 1.12 guild
-- tuple. Some compatible clients/extensions append useful strings, while the
-- popular Improved Guild Window convention stores a short race code at the
-- start of the officer note (for example Hu-, NE-, Ta-, Go-). Accept both
-- sources when they are explicit, but never infer faction from a character
-- name, zone or a non-exclusive class.
local ROSTER_RACE_FACTION_180 = {
    HUMAN = "Alliance", DWARF = "Alliance", NIGHTELF = "Alliance", GNOME = "Alliance", HIGHELF = "Alliance",
    ORC = "Horde", UNDEAD = "Horde", SCOURGE = "Horde", TAUREN = "Horde", TROLL = "Horde", GOBLIN = "Horde",
}

local ROSTER_RACE_DISPLAY_180 = {
    HUMAN = "Human", DWARF = "Dwarf", NIGHTELF = "Night Elf", GNOME = "Gnome", HIGHELF = "High Elf",
    ORC = "Orc", UNDEAD = "Undead", SCOURGE = "Undead", TAUREN = "Tauren", TROLL = "Troll", GOBLIN = "Goblin",
}

local OFFICER_RACE_CODES_180 = {
    HU = "HUMAN", DW = "DWARF", NE = "NIGHTELF", GN = "GNOME", HE = "HIGHELF",
    OR = "ORC", UN = "UNDEAD", TA = "TAUREN", TR = "TROLL", GO = "GOBLIN",
}

local function NormalizeRaceCandidate180(value)
    local text = string.upper(tostring(value or ""))
    text = string.gsub(text, "[%s_%-]", "")
    if text == "NIGHTELF" or text == "HIGHELF" or text == "HUMAN" or text == "DWARF" or text == "GNOME"
        or text == "ORC" or text == "UNDEAD" or text == "SCOURGE" or text == "TAUREN" or text == "TROLL" or text == "GOBLIN" then
        return text
    end
    return nil
end

local OFFICER_RACE_CODES_SHORT_180 = {
    H = "HUMAN", D = "DWARF", N = "NIGHTELF", G = "GNOME",
    O = "ORC", U = "UNDEAD", T = "TROLL",
}

local function FactionFromOfficerNote180(note)
    note = tostring(note or "")
    -- Current convention: two-letter race code, e.g. Hu-, NE-, Ta-, Go-.
    if string.len(note) >= 3 and string.sub(note, 3, 3) == "-" then
        local code = string.upper(string.sub(note, 1, 2))
        local race = OFFICER_RACE_CODES_180[code]
        if race then return ROSTER_RACE_FACTION_180[race], race end
    end
    -- Backward-compatible convention used by older guild notes: H-, N-, O-,
    -- etc. T- historically means Troll; Tauren requires Ta- so it is never
    -- guessed ambiguously.
    if string.len(note) >= 2 and string.sub(note, 2, 2) == "-" then
        local code = string.upper(string.sub(note, 1, 1))
        local race = OFFICER_RACE_CODES_SHORT_180[code]
        if race then return ROSTER_RACE_FACTION_180[race], race end
    end
    return nil, nil
end

local function FactionFromRosterExtraValue180(value)
    if type(value) ~= "string" then return nil, nil end
    local upper = string.upper(value)
    if upper == "ALLIANCE" then return "Alliance", nil end
    if upper == "HORDE" then return "Horde", nil end
    local race = NormalizeRaceCandidate180(value)
    if race and ROSTER_RACE_FACTION_180[race] then
        return ROSTER_RACE_FACTION_180[race], race
    end
    return nil, nil
end

local function FactionFromRosterExtras180(officerNote, extra1, extra2, extra3, extra4, extra5, extra6, extra7)
    local faction, race
    faction, race = FactionFromRosterExtraValue180(extra1) if faction then return faction, race, race and "roster-race" or "roster-api" end
    faction, race = FactionFromRosterExtraValue180(extra2) if faction then return faction, race, race and "roster-race" or "roster-api" end
    faction, race = FactionFromRosterExtraValue180(extra3) if faction then return faction, race, race and "roster-race" or "roster-api" end
    faction, race = FactionFromRosterExtraValue180(extra4) if faction then return faction, race, race and "roster-race" or "roster-api" end
    faction, race = FactionFromRosterExtraValue180(extra5) if faction then return faction, race, race and "roster-race" or "roster-api" end
    faction, race = FactionFromRosterExtraValue180(extra6) if faction then return faction, race, race and "roster-race" or "roster-api" end
    faction, race = FactionFromRosterExtraValue180(extra7) if faction then return faction, race, race and "roster-race" or "roster-api" end
    faction, race = FactionFromOfficerNote180(officerNote)
    if faction then return faction, race, "officer-race-code" end
    return nil, nil, nil
end

local function ReadRosterMember180(owner, index, now)
    local name, rank, rankIndex, level, class, zone, note, officerNote, isOnline, extra1, extra2, extra3, extra4, extra5, extra6, extra7 = GetGuildRosterInfo(index)
    if not name then return nil, false end
    local offlineHours, lastOnlineText = owner:BuildOfflineInfo(index, isOnline)
    local faction180, raceToken180, factionSource180 = FactionFromRosterExtras180(officerNote, extra1, extra2, extra3, extra4, extra5, extra6, extra7)
    return {
        name = name,
        rank = rank or "",
        rankIndex = rankIndex or 99,
        level = level or 0,
        class = class or "",
        zone = zone or "",
        note = note or "",
        officerNote = officerNote or "",
        online = isOnline and true or false,
        offlineHours = offlineHours or 0,
        offlineDays = math.floor((offlineHours or 0) / 24),
        lastOnlineText = lastOnlineText or "Offline",
        rosterIndex = index,
        seen = now,
        faction180 = faction180,
        factionSeenAt180 = faction180 and now or nil,
        factionSource180 = factionSource180,
        race180 = raceToken180 and ROSTER_RACE_DISPLAY_180[raceToken180] or nil,
    }, isOnline and true or false
end


-- r59 presence lane ---------------------------------------------------------
-- GUILD_ROSTER_UPDATE fires for ordinary login/logout presence changes as well
-- as real membership/rank/note changes. The lightweight lane below stages only
-- volatile online/zone/index data and publishes it atomically after the entire
-- roster cache has been validated. It never writes partial presence into the
-- committed roster. Any durable/structural difference discards the staged data
-- and immediately escalates to the existing authoritative full scan.
local function ScheduleRosterPresenceSliceR59(owner, delay)
    if not owner or not owner.ScheduleAfter180 then return false end
    return owner:ScheduleAfter180("roster-presence-slice-r59", math.max(0, tonumber(delay) or 0), function(current)
        local ok, problem = pcall(current.ProcessRosterPresenceSliceR59, current)
        if ok then return end
        current.runtime = current.runtime or {}
        current.runtime.rosterPresenceR59 = nil
        current.runtime.rosterDataDirty180 = true
        if current.RecordInternalIssueRC3 then pcall(current.RecordInternalIssueRC3, current, "Roster/PRESENCE_SLICE", problem) end
        -- Fail closed: preserve the last committed roster and let the normal
        -- bounded authoritative path reconcile it on the next safe opportunity.
        if current.RequestScan and not current.pendingScan and not current.runtime.rosterRead180 then
            current:RequestScan("GUILD_EVENT_STRUCTURE")
        end
    end, 58)
end

local function EscalateRosterPresenceR59(owner, reason, detail)
    owner.runtime = owner.runtime or {}
    owner.runtime.rosterPresenceR59 = nil
    owner.runtime.rosterDataDirty180 = true
    owner.runtime.rosterPresenceMetricsR59 = owner.runtime.rosterPresenceMetricsR59 or { runs = 0, slices = 0, escalations = 0, restarts = 0 }
    owner.runtime.rosterPresenceMetricsR59.escalations = (tonumber(owner.runtime.rosterPresenceMetricsR59.escalations) or 0) + 1
    owner.runtime.rosterPresenceMetricsR59.lastEscalationReason = tostring(reason or "STRUCTURE")
    owner.runtime.rosterPresenceMetricsR59.lastEscalationDetail = detail and tostring(detail) or nil
    if owner.RequestScan and not owner.pendingScan and not owner.runtime.rosterRead180 then
        owner:RequestScan("GUILD_EVENT_STRUCTURE")
    end
    return true
end

function OTLGM:BeginRosterPresenceRefreshR59(reason)
    self.runtime = self.runtime or {}
    if self.pendingScan or self.runtime.rosterRead180 then return false end
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    if not db or not db.initialized or type(db.roster) ~= "table" then return false end
    local total = GetNumGuildMembers and (tonumber(GetNumGuildMembers(true)) or 0) or 0
    if total <= 0 then return false end
    if tonumber(db.lastTotal) and tonumber(db.lastTotal) > 0 and total ~= tonumber(db.lastTotal) then
        return EscalateRosterPresenceR59(self, "COUNT_CHANGED")
    end
    local state = self.runtime.rosterPresenceR59
    if state then
        -- Never publish an already half-read cache after a second roster event.
        -- Finish/discard this pass and immediately reread from row 1.
        state.restartRequested = true
        state.reason = tostring(reason or state.reason or "GUILD_EVENT")
        return true
    end
    self.runtime.rosterPresenceR59 = {
        reason = tostring(reason or "GUILD_EVENT"), total = total, index = 1,
        online = 0, rows = 0, startedAt = self:Now(), restartRequested = false,
        staged = {},
    }
    self.runtime.rosterPresenceMetricsR59 = self.runtime.rosterPresenceMetricsR59 or { runs = 0, slices = 0, escalations = 0, restarts = 0 }
    return ScheduleRosterPresenceSliceR59(self, 0)
end

function OTLGM:ProcessRosterPresenceSliceR59()
    local state = self.runtime and self.runtime.rosterPresenceR59
    if not state then return false end
    local db = self.GetGuildDB and self:GetGuildDB() or nil
    if not db or type(db.roster) ~= "table" then self.runtime.rosterPresenceR59 = nil return false end

    local liveTotal = GetNumGuildMembers and (tonumber(GetNumGuildMembers(true)) or 0) or 0
    if liveTotal <= 0 or liveTotal ~= tonumber(state.total) or (tonumber(db.lastTotal) or liveTotal) ~= liveTotal then
        return EscalateRosterPresenceR59(self, "COUNT_CHANGED_DURING_PRESENCE")
    end

    local startedProfile
    if debugprofilestop then local ok, value = pcall(debugprofilestop) if ok then startedProfile = tonumber(value) end end
    local maximum, budgetMs = 96, 2.0
    local pressure = self.GetClientPressure181 and self:GetClientPressure181() or nil
    if pressure and tonumber(pressure.level) >= 2 then maximum, budgetMs = 48, 1.25 end
    if self.IsPerformanceGuardActive181 and self:IsPerformanceGuardActive181() then maximum, budgetMs = 32, 0.9 end

    local processed = 0
    while state.index <= math.max(0, tonumber(state.total) or 0) and processed < maximum do
        local ok, name, rank, rankIndex, level, class, zone, note, officerNote, isOnline = pcall(GetGuildRosterInfo, state.index)
        if not ok then
            self.runtime.rosterPresenceR59 = nil
            self.runtime.rosterDataDirty180 = true
            if self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Roster/PRESENCE_ROW", name) end
            if self.RequestScan and not self.pendingScan then self:RequestScan("GUILD_EVENT_STRUCTURE") end
            return false
        end
        if not name then return EscalateRosterPresenceR59(self, "MISSING_ROW") end

        local member = db.roster[name]
        if not member then return EscalateRosterPresenceR59(self, "UNKNOWN_MEMBER") end

        -- Durable fields are validation-only here. A mismatch belongs to the
        -- canonical full scan so History/authority/first-seen/backups stay exact.
        local durableFieldR59, savedValueR59, liveValueR59
        if tostring(member.rank or "") ~= tostring(rank or "") then
            durableFieldR59, savedValueR59, liveValueR59 = "rank", member.rank, rank
        elseif tonumber(member.rankIndex or 99) ~= tonumber(rankIndex or 99) then
            durableFieldR59, savedValueR59, liveValueR59 = "rankIndex", member.rankIndex, rankIndex
        elseif tonumber(member.level or 0) ~= tonumber(level or 0) then
            durableFieldR59, savedValueR59, liveValueR59 = "level", member.level, level
        elseif tostring(member.class or "") ~= tostring(class or "") then
            durableFieldR59, savedValueR59, liveValueR59 = "class", member.class, class
        elseif tostring(member.note or "") ~= tostring(note or "") then
            durableFieldR59, savedValueR59, liveValueR59 = "note", member.note, note
        elseif tostring(member.officerNote or "") ~= tostring(officerNote or "") then
            durableFieldR59, savedValueR59, liveValueR59 = "officerNote", member.officerNote, officerNote
        end
        if durableFieldR59 then
            local detailR59 = tostring(name or "?") .. " field=" .. tostring(durableFieldR59)
            -- Notes can contain private guild text. Keep their values out of the
            -- support export while still naming the field that forced the safe
            -- authoritative scan. Non-note scalar fields are safe and useful.
            if durableFieldR59 ~= "note" and durableFieldR59 ~= "officerNote" then
                detailR59 = detailR59 .. " saved=" .. tostring(savedValueR59 or "") .. " live=" .. tostring(liveValueR59 or "")
            end
            return EscalateRosterPresenceR59(self, "DURABLE_FIELD_CHANGED", detailR59)
        end

        state.staged[name] = {
            online = isOnline and true or false,
            zone = zone or member.zone or "",
            rosterIndex = state.index,
        }
        if isOnline then state.online = state.online + 1 end
        state.rows = state.rows + 1
        state.index = state.index + 1
        processed = processed + 1
        if startedProfile and debugprofilestop and processed >= 16 then
            local okNow, nowValue = pcall(debugprofilestop)
            if okNow and tonumber(nowValue) and tonumber(nowValue) - startedProfile >= budgetMs then break end
        end
    end

    local metrics = self.runtime.rosterPresenceMetricsR59 or { runs = 0, slices = 0, escalations = 0, restarts = 0 }
    self.runtime.rosterPresenceMetricsR59 = metrics
    metrics.slices = (tonumber(metrics.slices) or 0) + 1
    metrics.lastSliceRows = processed
    if startedProfile and debugprofilestop then
        local okNow, nowValue = pcall(debugprofilestop)
        if okNow and tonumber(nowValue) then
            metrics.lastSliceMs = math.max(0, tonumber(nowValue) - startedProfile)
            metrics.maxSliceMs = math.max(tonumber(metrics.maxSliceMs) or 0, tonumber(metrics.lastSliceMs) or 0)
        end
    end

    if state.index <= math.max(0, tonumber(state.total) or 0) then
        ScheduleRosterPresenceSliceR59(self, 0.02)
        return false
    end

    -- A second GUILD_ROSTER_UPDATE arrived while this pass was in flight. The
    -- cache may have changed behind already-read rows, so discard the whole pass
    -- instead of briefly publishing stale/half-coherent presence.
    if state.restartRequested then
        metrics.restarts = (tonumber(metrics.restarts) or 0) + 1
        local reason = tostring(state.reason or "GUILD_EVENT_COALESCED")
        self.runtime.rosterPresenceR59 = nil
        return self:BeginRosterPresenceRefreshR59(reason)
    end

    -- Atomic publication: only after all rows validated do volatile fields move
    -- into the committed roster. No structural path above can leave half the
    -- roster showing new presence and half showing the previous snapshot.
    local nameR59, updateR59
    for nameR59, updateR59 in pairs(state.staged or {}) do
        local member = db.roster[nameR59]
        if member then
            member.online = updateR59.online and true or false
            member.zone = updateR59.zone or member.zone or ""
            member.rosterIndex = tonumber(updateR59.rosterIndex) or member.rosterIndex
            if updateR59.online then
                member.offlineHours = 0
                member.offlineDays = 0
                member.lastOnlineText = "Online"
            elseif member.lastOnlineText == "Online" or not member.lastOnlineText or member.lastOnlineText == "" then
                -- Presence intentionally does not call GetGuildRosterLastOnline;
                -- the next canonical scan fills the exact offline duration.
                member.lastOnlineText = "Offline"
            end
        end
    end

    local online = tonumber(state.online) or 0
    self.runtime.rosterPresenceR59 = nil
    metrics.runs = (tonumber(metrics.runs) or 0) + 1
    metrics.lastRows = tonumber(state.rows) or 0
    metrics.lastOnline = online
    metrics.lastReason = tostring(state.reason or "GUILD_EVENT")
    db.lastOnline = online
    -- CP7: Presence changes member.online in-place without changing db.lastScan.
    -- Any cache keyed only by the canonical scan timestamp would otherwise keep
    -- the previous Online/Shown composition for several seconds. Publish one
    -- volatile revision and invalidate only the online-dependent view caches.
    self.runtime.rosterPresenceRevisionR59 = (tonumber(self.runtime.rosterPresenceRevisionR59) or 0) + 1
    self.runtime.sortedRosterView184 = nil
    self.runtime.rosterSummaryCounts184 = nil
    self.runtime.compositionCache180 = nil
    self.runtime.rosterPresenceLastAtR59 = self:Now()
    self.runtime.rosterPresenceLastRowsR59 = tonumber(state.rows) or 0
    if self.RefreshHeaderOnlineIndicator183 then pcall(self.RefreshHeaderOnlineIndicator183, self) end
    if self.UpdateMinimapBadge then pcall(self.UpdateMinimapBadge, self) end
    local page = self.ui and self.ui.currentPage or nil
    if self.ui and self.ui.main and self.ui.main.IsVisible and self.ui.main:IsVisible()
        and (page == "roster" or page == "home" or page == "overview") and self.RefreshVisiblePage then
        pcall(self.RefreshVisiblePage, self)
    end
    return true
end

function OTLGM:ReadRoster()
    local override = self.runtime and self.runtime.rosterReadOverride180
    if override then return override.snapshot or {}, tonumber(override.total) or 0, tonumber(override.online) or 0 end

    local snapshot = {}
    local total = GetNumGuildMembers(true) or 0
    local online = 0
    local now = self:Now()
    local i
    for i = 1, total do
        local member, isOnline = ReadRosterMember180(self, i, now)
        if member then
            snapshot[member.name] = member
            if isOnline then online = online + 1 end
        end
    end
    return snapshot, total, online
end

-- Full guild rosters on OctoWoW can exceed 780 characters. Reading every
-- roster API row and its last-online tuple in one event callback is a visible
-- freeze risk, so the canonical full-scan path reads bounded slices and only
-- commits after the snapshot is complete. Domain data is never partially
-- replaced.
local function ScheduleRosterScanSliceSafe180(owner, delay)
    if not owner or not owner.ScheduleAfter180 then return false end
    return owner:ScheduleAfter180("roster-scan-slice", math.max(0, tonumber(delay) or 0), function(current)
        local ok, problem = pcall(current.ProcessRosterScanSlice180, current)
        current.runtime = current.runtime or {}
        if ok then
            current.runtime.rosterSliceDispatchFailures180 = 0
            return
        end
        local failures = math.min(3, (tonumber(current.runtime.rosterSliceDispatchFailures180) or 0) + 1)
        current.runtime.rosterSliceDispatchFailures180 = failures
        if current.RecordInternalIssueRC3 then pcall(current.RecordInternalIssueRC3, current, "Roster/SLICE_DISPATCH", problem) end
        if current.runtime.rosterRead180 and failures < 3 and current.ScheduleAfter180 then
            ScheduleRosterScanSliceSafe180(current, 0.5)
            return
        end
        -- An unexpected outer failure must not leave the bounded-reader lock
        -- set forever. Preserve the last committed roster and fail closed.
        current.runtime.rosterRead180 = nil
        current.runtime.rosterReadOverride180 = nil
        if current.SetOperationState156 then pcall(current.SetOperationState156, current, "ROSTER", "ERROR", "Roster scan stopped after an internal error", 6) end
        if current.SetStatus then pcall(current.SetStatus, current, "Roster scan stopped safely: " .. tostring(problem or "unknown error")) end
    end, 70)
end
function OTLGM:BeginRosterScan180(reason)
    self.runtime = self.runtime or {}
    if self.runtime.rosterRead180 then return false end
    local total = GetNumGuildMembers and (tonumber(GetNumGuildMembers(true)) or 0) or 0
    self.runtime.rosterRead180 = {
        reason = tostring(reason or "INTERNAL"), total = total, index = 1,
        online = 0, snapshot = {}, lookupByKeyR26 = {}, startedAt = self:Now(), restarts = 0,
    }
    self.runtime.rosterMetrics180 = self.runtime.rosterMetrics180 or { fullScans = 0, targetedRefreshes = 0, reasons = {} }
    if self.ScheduleAfter180 then
        ScheduleRosterScanSliceSafe180(self, 0)
        return true
    end
    -- Never fall back to a synchronous 780+ member scan. Without the shared
    -- scheduler the safe behavior is an explicit error and no partial commit.
    self.runtime.rosterRead180 = nil
    if self.SetOperationState156 then self:SetOperationState156("ROSTER", "ERROR", "Guild roster update is temporarily unavailable", 6) end
    return false
end

function OTLGM:ProcessRosterScanSlice180(forceAll)
    local state = self.runtime and self.runtime.rosterRead180
    if not state then return false end
    if self.InCombat and self:InCombat() and state.reason ~= "MANUAL" then
        if self.ScheduleAfter180 then ScheduleRosterScanSliceSafe180(self, 1) end
        return false
    end
    if state.reason ~= "MANUAL" and self.runtime and self.runtime.transitionActive176 then
        self.runtime.rosterTransitionDeferrals181 = (tonumber(self.runtime.rosterTransitionDeferrals181) or 0) + 1
        if self.ScheduleAfter180 then ScheduleRosterScanSliceSafe180(self, 1) end
        return false
    end

    local liveTotal = 0
    if GetNumGuildMembers then
        local countOk, countValue = pcall(GetNumGuildMembers, true)
        if countOk then
            liveTotal = tonumber(countValue) or 0
        else
            state.failures180 = (tonumber(state.failures180) or 0) + 1
            if self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Roster/SLICE_COUNT", countValue) end
            if state.failures180 <= 2 and self.ScheduleAfter180 then
                ScheduleRosterScanSliceSafe180(self, 0.5)
                return false
            end
            self.runtime.rosterRead180 = nil
            self.runtime.rosterReadOverride180 = nil
            if self.SetOperationState156 then self:SetOperationState156("ROSTER", "ERROR", "Guild roster could not be read safely", 6) end
            return false
        end
    end
    state.failures180 = 0
    if liveTotal ~= state.total and state.index > 1 and (tonumber(state.restarts) or 0) < 2 then
        state.total = liveTotal
        state.index = 1
        state.online = 0
        state.snapshot = {}
        state.lookupByKeyR26 = {}
        state.restarts = (tonumber(state.restarts) or 0) + 1
    else
        state.total = liveTotal
    end

    local startedProfile
    if debugprofilestop then
        local ok, value = pcall(debugprofilestop)
        if ok then startedProfile = tonumber(value) end
    end
    local processed = 0
    -- A 788+ member OctoWoW guild must never monopolize one rendered frame.
    -- 1.8.1 also adapts the slice to current client pressure: rain, cities and
    -- dense scenes leave less frame budget for Lua even when addon work itself
    -- has not changed.
    local pressureState = self.GetClientPressure181 and self:GetClientPressure181() or nil
    local fps = pressureState and tonumber(pressureState.fps) or nil
    if not fps and GetFramerate then
        local fpsOk, fpsValue = pcall(GetFramerate)
        if fpsOk then fps = tonumber(fpsValue) end
    end
    local profile = OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.performanceProfile181 or "AUTO"
    local guardActive = pressureState and pressureState.guard and true or (self.IsPerformanceGuardActive181 and self:IsPerformanceGuardActive181() or false)
    local sliceBudgetMs = 4.0
    local maximum = forceAll and math.max(1, state.total) or 50
    if not forceAll and profile == "SMOOTH" then
        maximum = 30
        sliceBudgetMs = 2.5
    elseif not forceAll and profile == "FRESH" then
        maximum = 64
        sliceBudgetMs = 4.5
    end
    -- FPS protection overrides the preference when the renderer is already
    -- struggling. This is deliberately conservative for dense cities/weather.
    if not forceAll and fps and fps < 30 then
        maximum = math.min(maximum, 24)
        sliceBudgetMs = math.min(sliceBudgetMs, 2.0)
    elseif not forceAll and fps and fps < 45 then
        maximum = math.min(maximum, 36)
        sliceBudgetMs = math.min(sliceBudgetMs, 3.0)
    end
    if not forceAll and guardActive then
        maximum = math.min(maximum, 18)
        sliceBudgetMs = math.min(sliceBudgetMs, 1.5)
    end
    if not forceAll and pressureState and tonumber(pressureState.level) >= 2 and not guardActive then
        maximum = math.min(maximum, 24)
        sliceBudgetMs = math.min(sliceBudgetMs, 2.0)
    end
    state.snapshot = type(state.snapshot) == "table" and state.snapshot or {}
    state.online = tonumber(state.online) or 0
    state.index = math.max(1, tonumber(state.index) or 1)
    local sliceNow = self:Now()
    while state.index <= state.total and processed < maximum do
        local rowOk, member, isOnline = pcall(ReadRosterMember180, self, state.index, sliceNow)
        if not rowOk then
            state.rowFailures180 = (tonumber(state.rowFailures180) or 0) + 1
            if self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Roster/SLICE_ROW", member) end
            if state.rowFailures180 <= 2 and self.ScheduleAfter180 then
                ScheduleRosterScanSliceSafe180(self, 0.5)
                return false
            end
            -- Do not leave rosterRead180 set after a persistent API/helper
            -- failure: that state gates future scans, confirmation work and
            -- several transition paths. Fail closed with the last committed
            -- roster still intact rather than making the addon look inactive.
            self.runtime.rosterRead180 = nil
            self.runtime.rosterReadOverride180 = nil
            if self.SetOperationState156 then self:SetOperationState156("ROSTER", "ERROR", "Roster row could not be read safely", 6) end
            return false
        end
        state.rowFailures180 = 0
        if member then
            state.snapshot[member.name] = member
            state.lookupByKeyR26 = type(state.lookupByKeyR26) == "table" and state.lookupByKeyR26 or {}
            local normalizedR26 = self:NormalizeName(member.name or "")
            if normalizedR26 ~= "" then state.lookupByKeyR26[normalizedR26] = member end
            if isOnline then state.online = state.online + 1 end
        end
        state.index = state.index + 1
        processed = processed + 1
        if not forceAll and startedProfile and debugprofilestop and processed >= 12 then
            local ok, current = pcall(debugprofilestop)
            if ok and tonumber(current) and (tonumber(current) - startedProfile) >= sliceBudgetMs then break end
        end
    end

    local metrics = self.runtime.rosterMetrics180
    if type(metrics) ~= "table" then
        metrics = { fullScans = 0, targetedRefreshes = 0, reasons = {} }
        self.runtime.rosterMetrics180 = metrics
    end
    metrics.readSlices = (tonumber(metrics.readSlices) or 0) + 1
    metrics.rowsRead = (tonumber(metrics.rowsRead) or 0) + processed
    metrics.lastSliceRows = processed
    metrics.lastSliceFps181 = fps
    if fps and fps < 45 then metrics.lowFpsSlices181 = (tonumber(metrics.lowFpsSlices181) or 0) + 1 end
    if guardActive then metrics.guardSlices181 = (tonumber(metrics.guardSlices181) or 0) + 1 end
    if startedProfile and debugprofilestop then
        local ok, current = pcall(debugprofilestop)
        if ok and tonumber(current) then
            metrics.lastSliceMs = math.max(0, tonumber(current) - startedProfile)
            metrics.maxSliceMs181 = math.max(tonumber(metrics.maxSliceMs181) or 0, tonumber(metrics.lastSliceMs) or 0)
        end
    end

    if state.index <= state.total then
        if self.ScheduleAfter180 then ScheduleRosterScanSliceSafe180(self, 0.02) end
        return false
    end

    -- The comparison/commit walks the old and new roster and can be the largest
    -- remaining single callback for a 700+ member guild. Hold that atomic step
    -- through transient city/weather/transition pressure, with a bounded maximum
    -- wait so sustained low FPS cannot leave the roster pipeline locked forever.
    local pressureLevel = pressureState and tonumber(pressureState.level) or 0
    if not forceAll and state.reason ~= "MANUAL" and pressureLevel >= 2 then
        state.commitWaitStarted181 = tonumber(state.commitWaitStarted181) or self:Now()
        local maximumWait = pressureLevel >= 3 and 30 or 15
        if self:Now() - state.commitWaitStarted181 < maximumWait then
            metrics.commitPressureDeferrals181 = (tonumber(metrics.commitPressureDeferrals181) or 0) + 1
            if self.ScheduleAfter180 then ScheduleRosterScanSliceSafe180(self, pressureLevel >= 3 and 2 or 1) end
            return false
        end
    end
    state.commitWaitStarted181 = nil

    self.runtime.rosterRead180 = nil
    self.runtime.rosterDataDirty180 = nil
    -- r26: publish the normalized sender/member index produced by the same
    -- bounded roster slices. Scan() atomically adopts it with the snapshot, so
    -- the first addon packet after commit never rebuilds ~800 names in one frame.
    self.runtime.pendingRosterMemberLookupR26 = { roster = state.snapshot, byKey = state.lookupByKeyR26 or {} }
    self.runtime.rosterReadOverride180 = { snapshot = state.snapshot, total = state.total, online = state.online }
    local commitStarted
    if debugprofilestop then local profileOk, value = pcall(debugprofilestop) if profileOk then commitStarted = tonumber(value) end end
    local ok, problem = pcall(function() self:Scan(state.reason) end)
    self.runtime.rosterReadOverride180 = nil
    if commitStarted and debugprofilestop then
        local profileOk, value = pcall(debugprofilestop)
        if profileOk and tonumber(value) then
            local commitMs = math.max(0, tonumber(value) - commitStarted)
            self.runtime.rosterMetrics180 = self.runtime.rosterMetrics180 or {}
            self.runtime.rosterMetrics180.lastCommitMs181 = commitMs
            self.runtime.rosterMetrics180.maxCommitMs181 = math.max(tonumber(self.runtime.rosterMetrics180.maxCommitMs181) or 0, commitMs)
            if self.EndPerformanceSample180 and commitMs >= 8 and self.ActivatePerformanceGuard181 then
                self:ActivatePerformanceGuard181("roster commit", math.min(20, math.max(8, commitMs)), commitMs, fps)
            end
        end
    end
    if not ok then
        self.runtime.pendingRosterMemberLookupR26 = nil
        if self.SetOperationState156 then self:SetOperationState156("ROSTER", "ERROR", tostring(problem or "Roster commit failed"), 6) end
        if self.SetStatus then self:SetStatus("Guild roster update could not be saved: " .. tostring(problem or "unknown error")) end
        return false
    end

    -- The bounded reader already produced the normalized sender/member lookup.
    -- RefreshSenderRosterCache(force=true) therefore adopts that committed table
    -- in O(1); this delayed step only refreshes authority state and replays any
    -- packets that were quarantined while the roster commit was pending.
    local authorityRefreshStarted181 = self:Now()
    local function RefreshAuthorityAfterCommit181(current)
        local pressure = current.GetClientPressure181 and current:GetClientPressure181() or nil
        if pressure and tonumber(pressure.level) >= 2 and current.ScheduleAfter180 and current:Now() - authorityRefreshStarted181 < 20 then
            current.runtime = current.runtime or {}
            current.runtime.rosterPostCommitDeferrals181 = (tonumber(current.runtime.rosterPostCommitDeferrals181) or 0) + 1
            current:ScheduleAfter180("roster-post-commit-authority", 2, RefreshAuthorityAfterCommit181, 60)
            return
        end
        if current.__impl180 and current.__impl180.RefreshSenderRosterCache__impl1 then
            pcall(current.__impl180.RefreshSenderRosterCache__impl1, current, true)
        elseif current.RefreshSenderRosterCache then
            pcall(current.RefreshSenderRosterCache, current, true)
        end
        if current.ReplayAuthorityPacketsRC5 then pcall(current.ReplayAuthorityPacketsRC5, current) end
    end
    if self.ScheduleAfter180 then
        self:ScheduleAfter180("roster-post-commit-authority", 0.12, RefreshAuthorityAfterCommit181, 60)
    else
        RefreshAuthorityAfterCommit181(self)
    end
    return true
end

function OTLGM:IsLeadership(member)
    if not member then return false end
    local rank = string.lower(member.rank or "")
    if (member.rankIndex or 99) <= 2 then return true end
    if string.find(rank, "officer", 1, true) then return true end
    if string.find(rank, "helper", 1, true) then return true end
    if string.find(rank, "leader", 1, true) then return true end
    if string.find(rank, "manager", 1, true) then return true end
    if string.find(rank, "inn keeper", 1, true) then return true end
    return false
end

function OTLGM:GetClassColor(className)
    if not OTLGM_DB or not OTLGM_DB.settings or not OTLGM_DB.settings.classColors then return self.colors.white end
    return self.classHex[string.lower(className or "")] or self.colors.white
end

function OTLGM:GetRosterRanks()
    local db = self:GetGuildDB()
    local result = {}
    local seen = {}
    if not db then return result end

    local name, member
    for name, member in pairs(db.roster) do
        local rank = member.rank or ""
        if rank ~= "" and not seen[rank] then
            seen[rank] = true
            table.insert(result, { name = rank, index = member.rankIndex or 99 })
        end
    end

    table.sort(result, function(a, b)
        if a.index ~= b.index then return a.index < b.index end
        return string.lower(a.name) < string.lower(b.name)
    end)
    return result
end

function OTLGM:SetRosterSort(sortKey)
    self:EnsureDB()
    local settings = OTLGM_DB.settings
    if settings.rosterSortKey == sortKey then
        settings.rosterSortAsc = not settings.rosterSortAsc
    else
        settings.rosterSortKey = sortKey
        if sortKey == "LEVEL" or sortKey == "LASTONLINE" then settings.rosterSortAsc = false else settings.rosterSortAsc = true end
    end
    if self.ui then self.ui.rosterOffset = 0 end
    if self.RefreshRosterPage then self:RefreshRosterPage() end
end

function OTLGM:GetMember(name)
    local db = self:GetGuildDB()
    if not db or not name then return nil end
    if db.roster[name] then return db.roster[name] end
    self.runtime = self.runtime or {}
    local lookup = self.runtime.rosterMemberLookup180
    if not lookup or lookup.roster ~= db.roster or lookup.lastScan ~= db.lastScan then
        lookup = { roster = db.roster, lastScan = db.lastScan, byKey = {} }
        local storedName, member, key
        for storedName, member in pairs(db.roster or {}) do
            key = NormalizeName(storedName)
            if key ~= "" then lookup.byKey[key] = member end
            key = NormalizeName(member and member.name)
            if key ~= "" then lookup.byKey[key] = member end
        end
        self.runtime.rosterMemberLookup180 = lookup
    end
    return lookup.byKey[NormalizeName(name)]
end

function OTLGM:FindRosterIndex(name)
    if not name then return nil end
    local total = GetNumGuildMembers(true) or 0
    local target = NormalizeName(name)
    local i
    for i = 1, total do
        local rosterName = GetGuildRosterInfo(i)
        if rosterName == name or NormalizeName(rosterName) == target then return i end
    end
    return nil
end

function OTLGM:GetPlayerGuildRankIndex170()
    local guildName, rankName, rankIndex
    if GetGuildInfo then guildName, rankName, rankIndex = GetGuildInfo("player") end
    rankIndex = tonumber(rankIndex)
    if rankIndex ~= nil then return rankIndex end
    local playerName = UnitName and UnitName("player")
    local member = playerName and self.GetMember and self:GetMember(playerName) or nil
    return member and tonumber(member.rankIndex) or nil
end

function OTLGM:IsGuildLeader170()
    -- Guild-leader identity is guild-specific and must never be inferred for an
    -- unrelated character merely because a stale/custom-server API reports
    -- rank index 0.  Lucks still has to pass the live server leader
    -- signal before this *permission* helper grants leader-level capabilities.
    -- Other officers continue through the normal live rank-flag checks below.
    local playerName = UnitName and UnitName("player") or ""
    if self.IsCanonicalGuildLeaderName180 and not self:IsCanonicalGuildLeaderName180(playerName) then return false end
    if IsGuildLeader then
        local ok, result = pcall(IsGuildLeader, playerName)
        if ok and result then return true end
        ok, result = pcall(IsGuildLeader)
        if ok and result then return true end
    end
    local guildName, rankName, rankIndex
    if GetGuildInfo then guildName, rankName, rankIndex = GetGuildInfo("player") end
    if tonumber(rankIndex) == 0 then return true end
    rankName = string.lower(tostring(rankName or ""))
    return string.find(rankName, "guild leader", 1, true) ~= nil
        or string.find(rankName, "guild master", 1, true) ~= nil
        or string.find(rankName, "guildmaster", 1, true) ~= nil
end

function OTLGM:GetGuildPermissionFlags170(force)
    self.runtime = self.runtime or {}
    local now = GetTime and GetTime() or self:Now()
    local cached = self.runtime.guildPermissionFlags170
    if not force and cached and cached.checkedAt and now - cached.checkedAt < 3 then return cached end

    local flags = {
        checkedAt = now,
        promote = false, demote = false, remove = false, invite = false, setMotd = false,
        editPublic = false, viewOfficer = false, editOfficer = false, modifyGuildInfo = false,
        source = "unavailable",
    }
    if self:IsGuildLeader170() then
        flags.promote, flags.demote, flags.remove, flags.invite, flags.setMotd = true, true, true, true, true
        flags.editPublic, flags.viewOfficer, flags.editOfficer, flags.modifyGuildInfo = true, true, true, true
        flags.source = "guild-leader"
        self.runtime.guildPermissionFlags170 = flags
        return flags
    end

    local rankIndex = self:GetPlayerGuildRankIndex170()
    if rankIndex ~= nil and GuildControlSetRank and GuildControlGetRankFlags then
        local selected = pcall(GuildControlSetRank, rankIndex + 1)
        if selected then
            local ok, guildListen, guildSpeak, officerListen, officerSpeak,
                promote, demote, inviteMember, removeMember, setMotd,
                editPublic, viewOfficer, editOfficer, modifyGuildInfo = pcall(GuildControlGetRankFlags)
            if ok then
                flags.promote = promote and true or false
                flags.demote = demote and true or false
                flags.remove = removeMember and true or false
                flags.invite = inviteMember and true or false
                flags.setMotd = setMotd and true or false
                flags.editPublic = editPublic and true or false
                flags.viewOfficer = viewOfficer and true or false
                flags.editOfficer = editOfficer and true or false
                flags.modifyGuildInfo = modifyGuildInfo and true or false
                flags.source = "rank-flags"
            end
        end
    end
    self.runtime.guildPermissionFlags170 = flags
    return flags
end

function OTLGM:CanEditPublicNotes()
    if SafeBooleanFunction(CanEditPublicNote) then return true end
    return self:GetGuildPermissionFlags170().editPublic
end

function OTLGM:CanEditOfficerNotes()
    if SafeBooleanFunction(CanEditOfficerNote) then return true end
    return self:GetGuildPermissionFlags170().editOfficer
end

function OTLGM:CanViewOfficerNotes()
    if SafeBooleanFunction(CanViewOfficerNote) then return true end
    local flags = self:GetGuildPermissionFlags170()
    return flags.viewOfficer or flags.editOfficer
end

function OTLGM:CanPromoteMembers()
    if SafeBooleanFunction(CanGuildPromote) then return true end
    return self:GetGuildPermissionFlags170().promote
end

function OTLGM:CanDemoteMembers()
    if SafeBooleanFunction(CanGuildDemote) then return true end
    return self:GetGuildPermissionFlags170().demote
end

function OTLGM:CanRemoveMembers()
    if SafeBooleanFunction(CanGuildRemove) then return true end
    return self:GetGuildPermissionFlags170().remove
end

function OTLGM:ResetGuildData()
    local key = self:GuildKey()
    if key and OTLGM_DB and OTLGM_DB.guilds then
        OTLGM_DB.guilds[key] = nil
        self:Chat("Local history for the current guild has been reset. The next scan will create a new baseline.")
        self:RequestScan("MANUAL")
        if self.RefreshAll then self:RefreshAll() end
    end
end

function OTLGM:DetectWorldChannel153(force)
    self:EnsureDB()
    local now = self:Now()
    if not force and self.worldChannelDetectedAt153 and now - self.worldChannelDetectedAt153 < 10 then
        local cached = tonumber(OTLGM_DB.settings.worldChannelDetected153)
        if cached and cached > 0 then return cached, OTLGM_DB.settings.worldChannelName153 or "World", true end
    end
    self.worldChannelDetectedAt153 = now

    local function IsWorldName(name)
        name = string.lower(Trim(name or ""))
        name = string.gsub(name, "[%s%-%_]", "")
        if name == "world" or name == "worldchat" or name == "global" or name == "globalchat" then return true end
        if string.find(name, "world", 1, true) and not string.find(name, "defense", 1, true) then return true end
        return false
    end

    local candidates = { "World", "world", "WORLD", "World Chat", "Global", "Global Chat" }
    local i, id, channelName
    if GetChannelName then
        for i = 1, table.getn(candidates) do
            local ok, resolvedId, resolvedName = pcall(GetChannelName, candidates[i])
            if ok and tonumber(resolvedId) and tonumber(resolvedId) > 0 then
                id = math.floor(tonumber(resolvedId))
                channelName = resolvedName or candidates[i]
                if IsWorldName(channelName) or IsWorldName(candidates[i]) then
                    OTLGM_DB.settings.worldChannelDetected153 = tostring(id)
                    OTLGM_DB.settings.worldChannelName153 = tostring(channelName or "World")
                    OTLGM_DB.settings.worldChannelAuto153 = true
                    OTLGM_DB.settings.worldChannel = tostring(id)
                    return id, channelName, true
                end
            end
        end
    end

    if GetChannelList then
        local values = { GetChannelList() }
        i = 1
        while i <= table.getn(values) do
            id = tonumber(values[i])
            channelName = values[i + 1]
            if id and id > 0 and IsWorldName(channelName) then
                id = math.floor(id)
                OTLGM_DB.settings.worldChannelDetected153 = tostring(id)
                OTLGM_DB.settings.worldChannelName153 = tostring(channelName or "World")
                OTLGM_DB.settings.worldChannelAuto153 = true
                OTLGM_DB.settings.worldChannel = tostring(id)
                return id, channelName, true
            end
            i = i + 3
        end
    end

    OTLGM_DB.settings.worldChannelDetected153 = nil
    OTLGM_DB.settings.worldChannelName153 = nil
    OTLGM_DB.settings.worldChannelAuto153 = false
    return nil, nil, false
end

function OTLGM:GetWorldChannelNumber()
    self:EnsureDB()
    local detected = self:DetectWorldChannel153(false)
    if detected then return detected end

    local text = OTLGM_DB.settings.worldChannel or "6"
    if self.ui and self.ui.channelEdit and self.ui.channelEdit.GetText then
        local liveText = self.ui.channelEdit:GetText() or ""
        if liveText ~= "" then text = liveText end
    end
    text = Trim(text)
    local number = tonumber(text)
    if not number or number < 1 or number > 99 then return nil end
    number = math.floor(number)
    OTLGM_DB.settings.worldChannel = tostring(number)
    return number
end

function OTLGM:GetWorldChannelDisplay153()
    local channel, name, automatic = self:DetectWorldChannel153(false)
    if channel then return "/" .. tostring(channel), name or "World", automatic end
    local fallback = tonumber(OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.worldChannel)
    if fallback and fallback > 0 then return "/" .. tostring(math.floor(fallback)), "Manual", false end
    return "Not joined", "World", false
end

function OTLGM:FormatElapsedShort(seconds)
    seconds = math.max(0, seconds or 0)
    if seconds < 60 then return tostring(math.floor(seconds)) .. "s ago" end
    if seconds < 3600 then return tostring(math.floor(seconds / 60)) .. "m ago" end
    if seconds < 86400 then return tostring(math.floor(seconds / 3600)) .. "h ago" end
    return tostring(math.floor(seconds / 86400)) .. "d ago"
end

function OTLGM:FormatWorldRecruitmentElapsed(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)
    if seconds < 60 then return "<1m ago" end
    if seconds < 3600 then return tostring(math.floor(seconds / 60)) .. "m ago" end
    if seconds < 86400 then
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor(math.mod(seconds, 3600) / 60)
        if minutes > 0 then return tostring(hours) .. "h " .. tostring(minutes) .. "m ago" end
        return tostring(hours) .. "h ago"
    end
    return tostring(math.floor(seconds / 86400)) .. "d ago"
end

function OTLGM:GetWorldRecruitmentInfo()
    self:EnsureDB()
    local settings = OTLGM_DB.settings
    local timestamp = tonumber(settings.lastWorldRecruitmentAt)
    local minimum = tonumber(settings.worldRecruitmentMinSeconds) or 480
    local recommended = tonumber(settings.worldRecruitmentRecommendedSeconds) or 600
    if recommended < minimum then recommended = minimum end
    local minimumMinutes = math.max(1, math.floor((minimum + 59) / 60))
    local recommendedMinutes = math.max(minimumMinutes, math.floor((recommended + 59) / 60))
    local info = {
        timestamp = timestamp,
        label = settings.lastWorldRecruitmentLabel or "World recruitment",
        channel = settings.lastWorldRecruitmentChannel or tostring(settings.worldChannel or "6"),
        value = "NEVER",
        detail = "No world recruitment post recorded yet. Preferred interval: " .. tostring(minimumMinutes) .. "-" .. tostring(recommendedMinutes) .. " min.",
        state = "NEVER",
        elapsed = nil,
        minimum = minimum, recommended = recommended,
        minimumMinutes = minimumMinutes, recommendedMinutes = recommendedMinutes,
    }
    if not timestamp then return info end

    local elapsed = self:Now() - timestamp
    if elapsed < 0 then elapsed = 0 end

    info.elapsed = elapsed
    info.value = self:FormatWorldRecruitmentElapsed(elapsed)
    if elapsed < minimum then
        local waitMinutes = math.ceil((minimum - elapsed) / 60)
        if waitMinutes < 1 then waitMinutes = 1 end
        info.state = "WAIT"
        info.detail = "Wait " .. tostring(waitMinutes) .. "m before posting again."
    elseif elapsed < recommended then
        info.state = "WINDOW"
        info.detail = tostring(minimumMinutes) .. "-" .. tostring(recommendedMinutes) .. " min window; "
            .. tostring(recommendedMinutes) .. "m+ is the preferred green-ready point."
    else
        info.state = "READY"
        info.detail = "Preferred interval reached; safe to post in world again."
    end
    return info
end

function OTLGM:MarkRecruitmentSent(key, target, label)
    self:EnsureDB()
    if target ~= "WORLD" then return end
    if not key or key == "" then key = "WORKING" end
    local now = self:Now()
    OTLGM_DB.settings.recruitmentLastSent[key] = now
    OTLGM_DB.settings.lastWorldRecruitmentAt = now
    OTLGM_DB.settings.lastWorldRecruitmentLabel = label or key
    OTLGM_DB.settings.lastWorldRecruitmentChannel = tostring(self:GetWorldChannelNumber() or OTLGM_DB.settings.worldChannel or "6")
    if self.RefreshWorldRecruitmentIndicator then self:RefreshWorldRecruitmentIndicator() end
    if self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
    if self.MarkQuickDockDirty182 then self:MarkQuickDockDirty182("recruitment") end
end

function OTLGM:GetGuildChatMessages(channel)
    channel = channel == "OFFICER" and "OFFICER" or "GUILD"
    if channel == "OFFICER" then
        self.officerChatMessages = self.officerChatMessages or {}
        return self.officerChatMessages
    end

    local db = self:GetGuildDB()
    if not db then
        self.pendingGuildChatMessages = self.pendingGuildChatMessages or {}
        return self.pendingGuildChatMessages
    end
    db.guildChatMessages = db.guildChatMessages or {}
    if self.pendingGuildChatMessages and table.getn(self.pendingGuildChatMessages) > 0 then
        local i
        for i = 1, table.getn(self.pendingGuildChatMessages) do
            table.insert(db.guildChatMessages, self.pendingGuildChatMessages[i])
        end
        while table.getn(db.guildChatMessages) > 150 do table.remove(db.guildChatMessages, 1) end
        self.pendingGuildChatMessages = {}
        db.guildChatUnread = (db.guildChatUnread or 0) + (self.pendingGuildChatUnread or 0)
        self.pendingGuildChatUnread = 0
    end
    return db.guildChatMessages
end

function OTLGM:GetGuildChatChannel()
    self:EnsureDB()
    local channel = OTLGM_DB.settings.guildChatChannel or "GUILD"
    if channel == "OFFICER" and self.IsOfficerMode and not self:IsOfficerMode() then
        channel = "GUILD"
        OTLGM_DB.settings.guildChatChannel = channel
    end
    return channel
end

function OTLGM:GetGuildChatUnread(channel)
    channel = channel == "OFFICER" and "OFFICER" or "GUILD"
    if channel == "OFFICER" then return self.officerChatUnread or 0 end
    local db = self:GetGuildDB()
    if db then return db.guildChatUnread or 0 end
    return self.pendingGuildChatUnread or 0
end

function OTLGM:SetGuildChatUnread(channel, count)
    channel = channel == "OFFICER" and "OFFICER" or "GUILD"
    count = math.max(0, tonumber(count) or 0)
    if channel == "OFFICER" then
        self.officerChatUnread = count
    else
        local db = self:GetGuildDB()
        if db then db.guildChatUnread = count else self.pendingGuildChatUnread = count end
    end
end

function OTLGM:IsGuildChatChannelBeingRead(channel)
    if not self.ui or not self.ui.main or not self.ui.main:IsVisible() then return false end
    if self.ui.currentPage ~= "guildchat" then return false end
    if self:GetGuildChatChannel() ~= channel then return false end
    local offset = self.ui.chatOffsets and (self.ui.chatOffsets[channel] or 0) or 0
    return offset == 0
end

function OTLGM:SetGuildChatChannel(channel)
    local previousChannel180 = self.GetGuildChatChannel and self:GetGuildChatChannel() or "GUILD"
    if self.SaveGuildChatDraft and previousChannel180 then self:SaveGuildChatDraft(previousChannel180) end
    channel = channel == "OFFICER" and "OFFICER" or "GUILD"
    if channel == "OFFICER" and (not self.IsOfficerMode or not self:IsOfficerMode()) then
        if self.Notify then self:Notify("Officer Chat Unavailable", "Your current guild rank does not expose officer tools to the addon.") end
        channel = "GUILD"
    end
    self:EnsureDB()
    OTLGM_DB.settings.guildChatChannel = channel
    self.ui.chatOffsets = self.ui.chatOffsets or { GUILD = 0, OFFICER = 0 }
    self.ui.chatOffsets[channel] = 0
    self:SetGuildChatUnread(channel, 0)
    if self.RefreshGuildChatPage then self:RefreshGuildChatPage() end
    if self.RefreshGuildChatNavigationBadge then self:RefreshGuildChatNavigationBadge() elseif self.RefreshNavigation then self:RefreshNavigation() end
end

function OTLGM.__impl180.CaptureGuildChatMessage__impl1(self, channel, message, sender)
    channel = channel == "OFFICER" and "OFFICER" or "GUILD"
    message = Trim(message or "")
    sender = Trim(sender or "Unknown")
    if message == "" then return end
    message = string.gsub(message, "[\r\n]", " ")

    local messages = self:GetGuildChatMessages(channel)
    local messageTime = self:Now()
    if self.ui and self.ui.chatOffsets and (self.ui.chatOffsets[channel] or 0) > 0 then
        self.ui.chatOffsets[channel] = (self.ui.chatOffsets[channel] or 0) + 1
    end
    table.insert(messages, {
        ts = messageTime,
        sender = sender,
        text = message,
        channel = channel,
    })
    while table.getn(messages) > 150 do table.remove(messages, 1) end

    local playerName = UnitName and UnitName("player") or ""
    local ownMessage = NormalizeName(sender) == NormalizeName(playerName)
    local channelBeingRead = self:IsGuildChatChannelBeingRead(channel)
    if channelBeingRead then
        self:SetGuildChatUnread(channel, 0)
    elseif not ownMessage then
        local previousUnread = self:GetGuildChatUnread(channel)
        self.guildChatNewMarker = self.guildChatNewMarker or {}
        if previousUnread <= 0 or not self.guildChatNewMarker[channel] then
            self.guildChatNewMarker[channel] = messageTime
        end
        self:SetGuildChatUnread(channel, previousUnread + 1)
    end

    if not ownMessage and not channelBeingRead and OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.chatHighlightMentions ~= false
        and self.GuildChatTextMentionsPlayer and self:GuildChatTextMentionsPlayer(message) and self.NotifyEvent152 then
        local shortSender = string.gsub(sender or "Unknown", "%-.*$", "")
        local preview = self:Utf8Truncate(message, 120)
        local fingerprint = self:NormalizeText(shortSender .. ":" .. preview)
        self.runtime = self.runtime or {}
        self.runtime.pendingMentionTarget174 = { channel = channel, ts = messageTime, sender = shortSender, text = message }
        self:NotifyEvent152("mention", "MENTION:" .. channel .. ":" .. tostring(messageTime) .. ":" .. fingerprint,
            shortSender .. (channel == "OFFICER" and " mentioned you in officer chat" or " mentioned you in guild chat"),
            preview, "ACTION", true, "guildchat", {
                objectType = "CHAT_MESSAGE", objectId = channel .. ":" .. tostring(messageTime) .. ":" .. fingerprint,
                section = channel, actionKey = "MENTION", messageChannel = channel, messageTs = messageTime,
                messageSender = shortSender, messageText = message,
            })
        self.runtime.pendingMentionTarget174 = nil
    end

    if self.ui and self.ui.main and self.ui.main:IsVisible() and self.ui.currentPage == "guildchat" and self.RefreshGuildChatPage then
        -- RC4-r9: a busy guild channel can deliver several messages inside one
        -- render slice.  Rebuilding the complete chat page for each line causes
        -- needless layout churn.  Collapse a burst into one keyed refresh while
        -- keeping the delay below a perceptible chat latency.
        if self.ScheduleAfter180 then
            self:ScheduleAfter180("guild-chat-visible-refresh-184", 0.05, function(owner)
                if owner and owner.ui and owner.ui.main and owner.ui.main:IsVisible() and owner.ui.currentPage == "guildchat"
                    and owner.RefreshGuildChatPage then owner:RefreshGuildChatPage("chat-burst") end
            end, 76)
        else
            self:RefreshGuildChatPage()
        end
    end
    if self.RefreshGuildChatNavigationBadge then self:RefreshGuildChatNavigationBadge() elseif self.RefreshNavigation then self:RefreshNavigation() end
    if self.MarkQuickDockDirty182 then self:MarkQuickDockDirty182("chat") end
    return true
end

function OTLGM:ClearGuildChatHistory(channel)
    channel = channel == "OFFICER" and "OFFICER" or "GUILD"
    self.guildChatNewMarker = self.guildChatNewMarker or {}
    self.guildChatNewMarker[channel] = nil
    if channel == "OFFICER" then
        self.officerChatMessages = {}
        self.officerChatUnread = 0
    else
        self.pendingGuildChatMessages = {}
        self.pendingGuildChatUnread = 0
        local db = self:GetGuildDB()
        if db then
            db.guildChatMessages = {}
            db.guildChatUnread = 0
        end
    end
    if self.ui and self.ui.chatOffsets then self.ui.chatOffsets[channel] = 0 end
    if self.RefreshGuildChatPage then self:RefreshGuildChatPage() end
    if self.RefreshGuildChatNavigationBadge then self:RefreshGuildChatNavigationBadge() elseif self.RefreshNavigation then self:RefreshNavigation() end
end

function OTLGM:ClearGuildChatNewMarkers()
    self.guildChatNewMarker = {}
end

function OTLGM:SendGuildChatMessage(message, channel, quietFeedback)
    message = Trim(message or "")
    channel = channel == "OFFICER" and "OFFICER" or "GUILD"
    if message == "" then
        if not quietFeedback and self.Notify then self:Notify("Message Empty", "Write a message before sending.") end
        return false, "Write a message before sending."
    end
    if not GetGuildInfo or not GetGuildInfo("player") then
        if not quietFeedback and self.Notify then self:Notify("Guild Chat Unavailable", "You are not currently in a guild.") end
        return false, "You are not currently in a guild."
    end
    if channel == "OFFICER" and (not self.IsOfficerMode or not self:IsOfficerMode()) then
        if not quietFeedback and self.Notify then self:Notify("Officer Chat Unavailable", "Your current guild rank cannot use the officer chat page.") end
        return false, "Your current guild rank cannot use officer chat."
    end

    local ok, err = pcall(SendChatMessage, message, channel)
    if not ok then
        if not quietFeedback and self.Notify then self:Notify("Chat Message Failed", tostring(err)) end
        return false, tostring(err or "The game client rejected the message.")
    end
    if not quietFeedback and self.SetStatus then
        self:SetStatus(channel == "OFFICER" and "Message sent to officer chat." or "Message sent to guild chat.")
    end
    return true
end

OTLGM:RegisterModule("Guild", { layer = "core", owns = { "GuildKey", "Now", "ApplyCoreDefaults" } })
