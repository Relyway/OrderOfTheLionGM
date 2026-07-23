-- Order of the Lion Guild Manager v1.7.5
-- Corrective release layer r4. Loaded after Release175.lua.
-- Vanilla / OctoWoW / Lua 5.0 compatible. No OnUpdate handlers.

local R4 = {
    revision = 4,
    thresholdGuard = false,
    reactionGuard = false,
    chatMeasureCache = {},
}
OTLGM.release175r4 = R4

local A4 = OTLGM.achievements174
local SAFE_ICON_R4 = "Interface\\Icons\\INV_Misc_Book_09"

local function TrimR4(text)
    text = tostring(text or "")
    return string.gsub(text, "^%s*(.-)%s*$", "%1")
end

local function ShortNameR4(name)
    return string.gsub(TrimR4(name), "%-.*$", "")
end

local function NameKeyR4(name)
    return string.lower(ShortNameR4(name or ""))
end

local function CountR4(tbl)
    local count = 0
    local key
    for key in pairs(tbl or {}) do count = count + 1 end
    return count
end

local function SetButtonTextR4(button, text)
    if not button then return end
    if button.text and button.text.SetText then button.text:SetText(text or "")
    elseif button.label156 and button.label156.SetText then button.label156:SetText(text or "") end
end

local function SetButtonSelectedR4(button, selected)
    if not button then return end
    button.selected = selected and true or false
    button.selected156 = selected and true or false
    if OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(button) end
end

local function SetTextureR4(region, path)
    if not region then return end
    region:SetTexture(nil)
    if region.SetTexCoord then region:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    if region.SetVertexColor then region:SetVertexColor(1,1,1) end
    region:SetTexture(path and path ~= "" and path or SAFE_ICON_R4)
end

local function CreatePanelR4(parent, x, y, width, height, kind)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:SetWidth(width)
    frame:SetHeight(height)
    if OTLGM.ApplyPanelSkin then OTLGM:ApplyPanelSkin(frame, kind or "surface")
    else
        frame:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=9,insets={left=3,right=3,top=3,bottom=3}})
        frame:SetBackdropColor(0.02,0.02,0.018,0.98)
        frame:SetBackdropBorderColor(0.46,0.31,0.12,1)
    end
    return frame
end

local function CreateTextR4(parent, template, text, x, y, width, justify)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then label:SetWidth(width) end
    label:SetJustifyH(justify or "LEFT")
    if label.SetJustifyV then label:SetJustifyV("TOP") end
    label:SetText(text or "")
    return label
end

local function CreateButtonR4(parent, text, x, y, width, height, callback, style)
    local button = CreateFrame("Button", nil, parent)
    if OTLGM.PrepareInteractiveControl170 then OTLGM:PrepareInteractiveControl170(button, "button") end
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=9,insets={left=2,right=2,top=2,bottom=2}})
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.text:SetWidth(width - 8)
    button.text:SetText(text or "")
    button.label156 = button.text
    button.actionStyle = style or "normal"
    button.callbackR4 = callback
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function() if not this.disabled and this.callbackR4 then this.callbackR4(this) end end)
    button:SetScript("OnEnter", function() this.hovered=true if OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(this) end end)
    button:SetScript("OnLeave", function() this.hovered=nil if OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(this) end if GameTooltip then GameTooltip:Hide() end end)
    if OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(button) end
    return button
end

local function CreateEditR4(parent, name, x, y, width, height, maxLetters, multiline)
    local edit = CreateFrame("EditBox", name, parent)
    if OTLGM.PrepareInteractiveControl170 then OTLGM:PrepareInteractiveControl170(edit, "editbox") end
    edit:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    edit:SetWidth(width)
    edit:SetHeight(height)
    edit:SetAutoFocus(false)
    edit:SetFontObject("GameFontHighlightSmall")
    edit:SetMaxLetters(maxLetters or 80)
    edit:SetMultiLine(multiline and true or false)
    edit:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=9,insets={left=7,right=5,top=5,bottom=5}})
    edit:SetBackdropColor(0.018,0.018,0.018,1)
    edit:SetBackdropBorderColor(0.34,0.28,0.19,1)
    edit:SetTextInsets(6,6,3,3)
    edit:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    return edit
end

-- ---------------------------------------------------------------------------
-- Additional threshold achievement chains. All use existing shared aggregates.
-- ---------------------------------------------------------------------------

local THRESHOLD_ACHIEVEMENTS_R4 = {
    {id="C001",category="SOCIAL",name="Keeper of the Fallen",description="Successfully resurrect one hundred different guild members.",icon="Interface\\Icons\\Spell_Holy_Resurrection",progress="resurrectedGuild",required=100},
    {id="C002",category="SOCIAL",name="Voice of Renewal",description="Successfully resurrect two hundred and fifty different guild members.",icon="Interface\\Icons\\Spell_Holy_Renew",progress="resurrectedGuild",required=250},
    {id="C003",category="SOCIAL",name="No Lion Left Behind",description="Successfully resurrect five hundred different guild members.",icon="Interface\\Icons\\Spell_Holy_DivineIntervention",progress="resurrectedGuild",required=500},

    {id="C004",category="SOCIAL",name="Known by a Hundred",description="Share qualifying adventures with one hundred different guild members.",icon="Interface\\Icons\\INV_Misc_GroupNeedMore",progress="sharedPartners",required=100},
    {id="C005",category="SOCIAL",name="A Hall of Friends",description="Share qualifying adventures with two hundred and fifty different guild members.",icon="Interface\\Icons\\Spell_Holy_PrayerOfSpirit",progress="sharedPartners",required=250},
    {id="C006",category="SOCIAL",name="Every Mane Remembered",description="Share qualifying adventures with five hundred different guild members.",icon="Interface\\Icons\\INV_BannerPVP_01",progress="sharedPartners",required=500},

    {id="C007",category="SOCIAL",name="Twenty-Five Hours Together",description="Spend twenty-five hours grouped with guild members.",icon="Interface\\Icons\\INV_Misc_PocketWatch_01",progress="groupSeconds",required=90000},
    {id="C008",category="SOCIAL",name="Fifty Hours Together",description="Spend fifty hours grouped with guild members.",icon="Interface\\Icons\\INV_Misc_PocketWatch_02",progress="groupSeconds",required=180000},
    {id="C009",category="SOCIAL",name="A Hundred Hours Together",description="Spend one hundred hours grouped with guild members.",icon="Interface\\Icons\\Spell_Holy_DevotionAura",progress="groupSeconds",required=360000},
    {id="C010",category="SOCIAL",name="A Lifetime of Company",description="Spend two hundred and fifty hours grouped with guild members.",icon="Interface\\Icons\\INV_Crown_01",progress="groupSeconds",required=900000},

    {id="C011",category="DUNGEONS",name="Seasoned Delver",description="Defeat twenty-five dungeon bosses alongside guild members.",icon="Interface\\Icons\\INV_Misc_Key_03",progress="dungeonBosses",required=25},
    {id="C012",category="DUNGEONS",name="Deep Hall Veteran",description="Defeat two hundred and fifty dungeon bosses alongside guild members.",icon="Interface\\Icons\\INV_Pick_02",progress="dungeonBosses",required=250},
    {id="C013",category="DUNGEONS",name="Master of the Depths",description="Defeat five hundred dungeon bosses alongside guild members.",icon="Interface\\Icons\\INV_Hammer_04",progress="dungeonBosses",required=500},

    {id="C014",category="DUNGEONS",name="Fifty Strong",description="Complete fifty dungeons with a full guild party.",icon="Interface\\Icons\\INV_Shield_06",progress="fullGuildDungeonCompletions",required=50},
    {id="C015",category="DUNGEONS",name="One Hundred Strong",description="Complete one hundred dungeons with a full guild party.",icon="Interface\\Icons\\INV_Crown_01",progress="fullGuildDungeonCompletions",required=100},

    {id="C016",category="RAIDS",name="Raid Campaigner",description="Defeat twenty-five raid bosses alongside the guild.",icon="Interface\\Icons\\INV_Misc_Head_Dragon_01",progress="raidBosses",required=25},
    {id="C017",category="RAIDS",name="Banner of Two Hundred Fifty",description="Defeat two hundred and fifty raid bosses alongside the guild.",icon="Interface\\Icons\\INV_BannerPVP_02",progress="raidBosses",required=250},
    {id="C018",category="RAIDS",name="Conqueror of Five Hundred",description="Defeat five hundred raid bosses alongside the guild.",icon="Interface\\Icons\\INV_Crown_01",progress="raidBosses",required=500},

    {id="C019",category="PROFESSIONS",name="Thousandfold Craft",description="Complete one thousand successful crafting actions.",icon="Interface\\Icons\\Trade_BlackSmithing",progress="craftActions",required=1000},
    {id="C020",category="PROFESSIONS",name="Relentless Artisan",description="Complete two thousand five hundred successful crafting actions.",icon="Interface\\Icons\\INV_Misc_Gear_01",progress="craftActions",required=2500},
    {id="C021",category="PROFESSIONS",name="Hands of the Order",description="Complete five thousand successful crafting actions.",icon="Interface\\Icons\\INV_Hammer_04",progress="craftActions",required=5000},

    {id="C022",category="GROUP_FINDER",name="Frequent Volunteer",description="Send twenty-five applications through the Guild Group Finder.",icon="Interface\\Icons\\INV_Letter_15",progress="groupApplications",required=25},
    {id="C023",category="GROUP_FINDER",name="Always Answering",description="Send fifty applications through the Guild Group Finder.",icon="Interface\\Icons\\INV_Misc_Note_02",progress="groupApplications",required=50},
    {id="C024",category="GROUP_FINDER",name="A Hundred Calls Answered",description="Send one hundred applications through the Guild Group Finder.",icon="Interface\\Icons\\Spell_Holy_SealOfSalvation",progress="groupApplications",required=100},
    {id="C025",category="GROUP_FINDER",name="Trusted Fifty",description="Have fifty Group Finder applications accepted.",icon="Interface\\Icons\\Spell_Holy_BlessingOfProtection",progress="acceptedApplications",required=50},
    {id="C026",category="GROUP_FINDER",name="Trusted Hundred",description="Have one hundred Group Finder applications accepted.",icon="Interface\\Icons\\INV_BannerPVP_01",progress="acceptedApplications",required=100},

    {id="C027",category="PROFESSIONS",name="Workshop Regular",description="Contact twenty-five different guild crafters through the crafting network.",icon="Interface\\Icons\\INV_Misc_Rune_01",progress="crafterContacts",required=25},
    {id="C028",category="PROFESSIONS",name="Crafting Networker",description="Contact fifty different guild crafters through the crafting network.",icon="Interface\\Icons\\INV_Scroll_03",progress="crafterContacts",required=50},
    {id="C029",category="PROFESSIONS",name="Every Workshop Door",description="Contact one hundred different guild crafters through the crafting network.",icon="Interface\\Icons\\INV_Misc_Book_09",progress="crafterContacts",required=100},

    {id="C030",category="SOCIAL",name="Ten Voices in the Hall",description="React to ten different leadership announcements.",icon="Interface\\Icons\\INV_Misc_Note_01",progress="announcementReactions",required=10},
    {id="C031",category="SOCIAL",name="Twenty-Five Voices",description="React to twenty-five different leadership announcements.",icon="Interface\\Icons\\INV_Misc_Note_02",progress="announcementReactions",required=25},
    {id="C032",category="SOCIAL",name="Fifty Voices",description="React to fifty different leadership announcements.",icon="Interface\\Icons\\INV_Scroll_03",progress="announcementReactions",required=50},

    {id="C033",category="PROFESSIONS",name="Grand Recipe Archive",description="Publish two hundred and fifty unique recipes to the guild crafting network.",icon="Interface\\Icons\\INV_Scroll_03",progress="publishedRecipes",required=250},
    {id="C034",category="PROFESSIONS",name="Living Library",description="Publish five hundred unique recipes to the guild crafting network.",icon="Interface\\Icons\\INV_Misc_Book_09",progress="publishedRecipes",required=500},
}

local function AddThresholdAchievementsR4()
    if not A4 then return end
    local index, def
    for index=1,table.getn(THRESHOLD_ACHIEVEMENTS_R4) do
        def = THRESHOLD_ACHIEVEMENTS_R4[index]
        if not A4.byId[def.id] then
            table.insert(A4.catalog, def)
            A4.byId[def.id] = def
        end
    end
    A4.catalogRevision = math.max(tonumber(A4.catalogRevision) or 0, 14)
end
AddThresholdAchievementsR4()

local THRESHOLD_KEYS_R4 = {
    resurrectedGuild=true, sharedPartners=true, groupSeconds=true, dungeonBosses=true,
    fullGuildDungeonCompletions=true, raidBosses=true, craftActions=true,
    groupApplications=true, acceptedApplications=true, crafterContacts=true,
    announcementReactions=true, publishedRecipes=true,
}

local function ProgressValueR4(self, progress)
    local db = self:EnsureAchievements174()
    if progress == "resurrectedGuild" or progress == "sharedPartners" or progress == "crafterContacts" or progress == "announcementReactions" then
        return CountR4(self:GetAchievementSet174(progress))
    end
    return tonumber(db.counters[progress]) or 0
end

local function EvaluateThresholdAchievementsR4(self, silent)
    if R4.thresholdGuard then return end
    R4.thresholdGuard = true
    local index, def, value
    for index=1,table.getn(THRESHOLD_ACHIEVEMENTS_R4) do
        def = THRESHOLD_ACHIEVEMENTS_R4[index]
        if not self:IsAchievementComplete174(def.id) then
            value = ProgressValueR4(self, def.progress)
            if value >= (tonumber(def.required) or 1) then self:CompleteAchievement174(def.id, silent and true or false) end
        end
    end
    R4.thresholdGuard = false
end

local BaseProgressR4 = OTLGM.GetAchievementProgress174
function OTLGM:GetAchievementProgress174(def)
    if def and string.sub(tostring(def.id or ""),1,1) == "C" then
        local required = tonumber(def.required) or 1
        if self:IsAchievementComplete174(def.id) then return required, required end
        return math.min(required, ProgressValueR4(self, def.progress)), required
    end
    return BaseProgressR4(self, def)
end

local BaseAddCounterR4 = OTLGM.AddAchievementCounter174
function OTLGM:AddAchievementCounter174(key, amount)
    local value = BaseAddCounterR4(self, key, amount)
    if THRESHOLD_KEYS_R4[key] then EvaluateThresholdAchievementsR4(self, false) end
    return value
end

local BaseSetCounterR4 = OTLGM.SetAchievementCounter174
function OTLGM:SetAchievementCounter174(key, value)
    local result = BaseSetCounterR4(self, key, value)
    if THRESHOLD_KEYS_R4[key] then EvaluateThresholdAchievementsR4(self, false) end
    return result
end

local BaseAddSetR4 = OTLGM.AddAchievementSetValue174
function OTLGM:AddAchievementSetValue174(key, value)
    local changed = BaseAddSetR4(self, key, value)
    if changed and THRESHOLD_KEYS_R4[key] then EvaluateThresholdAchievementsR4(self, false) end
    return changed
end

local BaseCommunityReactionR4 = OTLGM.SetCommunityReaction
function OTLGM:SetCommunityReaction(kind, id, reaction, remote)
    local result = BaseCommunityReactionR4(self, kind, id, reaction, remote)
    if result and tostring(kind or "") == "ANN" and not remote and not R4.reactionGuard then
        R4.reactionGuard = true
        self:AddAchievementSetValue174("announcementReactions", tostring(id or ""))
        R4.reactionGuard = false
    end
    return result
end

-- ---------------------------------------------------------------------------
-- Robust guild tabard detection for custom OctoWoW tabards.
-- Slot 19 is the dedicated tabard slot, so any equipped item there while in a
-- guild is a safer fallback than a single Classic item ID or English name.
-- ---------------------------------------------------------------------------

function OTLGM:IsGuildTabardEquipped175R4()
    if GetGuildInfo and not GetGuildInfo("player") then return false end
    local link = GetInventoryItemLink and GetInventoryItemLink("player", 19) or nil
    local texture = GetInventoryItemTexture and GetInventoryItemTexture("player", 19) or nil
    if link and link ~= "" then return true end
    if texture and texture ~= "" then return true end
    return false
end

function OTLGM:CheckUnderBanner175R4(silent)
    if self:IsAchievementComplete174("UNDER_BANNER") then return true end
    if self:IsGuildTabardEquipped175R4() then return self:CompleteAchievement174("UNDER_BANNER", silent and true or false) end
    return false
end

-- ---------------------------------------------------------------------------
-- Achievements UI: no full rebuild on hover; human-readable time progress.
-- ---------------------------------------------------------------------------

local BaseBuildAchievementsR4 = OTLGM.BuildAchievementsPage174
function OTLGM:BuildAchievementsPage174(page)
    BaseBuildAchievementsR4(self, page)
    local index, row
    for index=1,table.getn(self.ui.achievementRows174 or {}) do
        row = self.ui.achievementRows174[index]
        row:SetScript("OnEnter", function()
            if not this.achievement174 then return end
            this:SetBackdropBorderColor(0.34,0.70,1,1)
            local complete = OTLGM:IsAchievementComplete174(this.achievement174.id)
            local name, description = OTLGM:GetAchievementPresentation174(this.achievement174, complete)
            GameTooltip:SetOwner(this,"ANCHOR_CURSOR")
            GameTooltip:AddLine(name,1,0.82,0.35)
            GameTooltip:AddLine(description,1,1,1,true)
            GameTooltip:AddLine("Shift-click to link",0.52,0.72,1)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
            local color = this.baseBorderR4 or {0.24,0.22,0.19,1}
            this:SetBackdropBorderColor(color[1],color[2],color[3],color[4] or 1)
        end)
    end
end

local function HumanProgressR4(current, required, progress)
    current = tonumber(current) or 0
    required = tonumber(required) or 1
    if progress == "groupSeconds" or progress == "longWatchSeconds" then
        if required >= 3600 then
            local currentHours = math.floor((current / 3600) * 10) / 10
            local requiredHours = math.floor(required / 3600)
            return tostring(currentHours) .. " / " .. tostring(requiredHours) .. " h"
        end
        return tostring(math.floor(current / 60)) .. " / " .. tostring(math.floor(required / 60)) .. " min"
    elseif progress == "regularTableSeconds" or progress == "raidPresence" then
        return tostring(math.floor(current / 60)) .. " / " .. tostring(math.floor(required / 60)) .. " min"
    end
    return nil
end

local BaseRefreshAchievementsR4 = OTLGM.RefreshAchievements174
function OTLGM:RefreshAchievements174()
    -- Safe recovery check. It is event-driven in normal play, but opening the
    -- page can repair a missed equipment event after a cache delay.
    self:CheckUnderBanner175R4(false)
    BaseRefreshAchievementsR4(self)
    local index, row, def, complete, current, required, human
    for index=1,table.getn(self.ui and self.ui.achievementRows174 or {}) do
        row = self.ui.achievementRows174[index]
        def = row and row.achievement174
        if def and row:IsVisible() then
            complete = self:IsAchievementComplete174(def.id)
            current, required = self:GetAchievementProgress174(def)
            if complete then row.baseBorderR4 = {0.68,0.44,0.12,1}
            elseif def.secret then row.baseBorderR4 = {0.38,0.18,0.52,1}
            else row.baseBorderR4 = {0.24,0.22,0.19,1} end
            if self.ui.achievementFocus174 == def.id then row.baseBorderR4 = {0.30,0.72,1,1} end
            human = not complete and HumanProgressR4(current,required,def.progress) or nil
            if human then row.status174:SetText(human) end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Guild Chat: measured row heights, restored consecutive-message grouping,
-- and separate Guild / Officer / Board navigation badges.
-- ---------------------------------------------------------------------------

local function EnsureChatMeasureR4(self)
    self.ui = self.ui or {}
    if self.ui.chatMeasureR4 then return self.ui.chatMeasureR4 end
    local holder = CreateFrame("Frame", nil, UIParent)
    holder:SetWidth(10) holder:SetHeight(10)
    holder:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -3000, -3000)
    if holder.SetAlpha then holder:SetAlpha(0) end
    holder:Show()
    local label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    label:SetJustifyH("LEFT")
    if label.SetJustifyV then label:SetJustifyV("TOP") end
    self.ui.chatMeasureR4 = label
    return label
end

local function MeasureChatHeightR4(self, text, width)
    local visible = self:GetGuildChatVisibleText(text or "")
    local key = tostring(width) .. "|" .. visible
    local cached = R4.chatMeasureCache[key]
    if cached then return cached end
    local label = EnsureChatMeasureR4(self)
    label:SetWidth(width)
    label:SetText(visible)
    local height = label.GetStringHeight and tonumber(label:GetStringHeight()) or nil
    if not height or height < 12 then
        local length = string.len(visible)
        local perLine = width >= 560 and 78 or width >= 430 and 54 or 34
        height = math.max(14, math.ceil(length / perLine) * 15)
    end
    height = math.ceil(height + 2)
    if height > 190 then height = 190 end
    R4.chatMeasureCache[key] = height
    local count = CountR4(R4.chatMeasureCache)
    if count > 500 then R4.chatMeasureCache = {} R4.chatMeasureCache[key] = height end
    return height
end

function OTLGM:GetGuildChatLineCount(text)
    local channel = self:GetGuildChatChannel()
    local width = channel == "OFFICER" and 284 or 444
    local height = MeasureChatHeightR4(self, text, width)
    return math.max(1, math.ceil(height / 15))
end

function OTLGM:GetGuildChatRowMetrics(messages, index, markerIndex)
    local info = messages[index]
    if not info then return 29,1,nil,false end
    local achievement = string.find(tostring(info.text or ""), "^%[Guild Achievement%]") ~= nil
    local width = achievement and 606 or (info.channel == "OFFICER" and 284 or 444)
    local textHeight = MeasureChatHeightR4(self, info.text or "", width)
    local lines = math.max(1, math.ceil(textHeight / 15))
    local separator = self:GetGuildChatTimeSeparator(messages,index)
    local marker = markerIndex and markerIndex == index
    local height = math.max(29, textHeight + 10)
    if separator then height = height + 17 end
    if marker then height = height + 9 end
    return height,lines,separator,marker
end

local function SameChatGroupR4(previous, current)
    if not previous or not current then return false end
    if tostring(previous.channel or "") ~= tostring(current.channel or "") then return false end
    if NameKeyR4(previous.sender) ~= NameKeyR4(current.sender) then return false end
    local gap = (tonumber(current.ts) or 0) - (tonumber(previous.ts) or 0)
    if gap < 0 or gap > 120 then return false end
    if string.find(tostring(previous.text or ""), "^%[Guild Achievement%]") then return false end
    if string.find(tostring(current.text or ""), "^%[Guild Achievement%]") then return false end
    return true
end

local BaseRefreshGuildChatR4 = OTLGM.RefreshGuildChatPage
function OTLGM:RefreshGuildChatPage()
    local result = BaseRefreshGuildChatR4(self)
    if not self.ui or not self.ui.chatRows or (OTLGM_DB.settings.guildChatView or "GUILD") == "BOARD" then
        if self.RefreshGuildChatNavigationBadge then self:RefreshGuildChatNavigationBadge() end
        return result
    end
    local previous = nil
    local index, row, current, grouped
    for index=1,table.getn(self.ui.chatRows) do
        row = self.ui.chatRows[index]
        current = row and row:IsVisible() and row.chatData or nil
        if current then
            grouped = SameChatGroupR4(previous,current) and not row.separatorText:IsVisible() and not row.newLine:IsVisible()
            if row.messageFrame.SetJustifyV then row.messageFrame:SetJustifyV("TOP") end
            local achievement = string.find(tostring(current.text or ""), "^%[Guild Achievement%]") ~= nil
            local measuredWidth = achievement and 606 or (current.channel == "OFFICER" and 284 or 444)
            row.messageFrame:SetHeight(MeasureChatHeightR4(self,current.text or "",measuredWidth)+3)
            if grouped then
                row.timeText:Hide()
                row.rankButton:Hide()
                row.senderButton:Hide()
            else
                row.timeText:Show()
                if not string.find(tostring(current.text or ""), "^%[Guild Achievement%]") then
                    row.rankButton:Show()
                    row.senderButton:Show()
                end
            end
            previous = current
        end
    end
    self:RefreshGuildChatNavigationBadge()
    return result
end

local function MakeMiniBadgeR4(parent, label, rightOffset, tone)
    local badge = CreateFrame("Frame", nil, parent)
    badge:SetWidth(24) badge:SetHeight(15)
    badge:SetPoint("RIGHT", parent, "RIGHT", rightOffset, 0)
    badge:SetFrameLevel(parent:GetFrameLevel()+5)
    badge:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=7,insets={left=1,right=1,top=1,bottom=1}})
    badge.text = badge:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    badge.text:SetPoint("CENTER",badge,"CENTER",0,0)
    badge.prefixR4 = label
    badge.toneR4 = tone
    badge:Hide()
    return badge
end

local function StyleMiniBadgeR4(badge, mention)
    local tone = badge.toneR4
    if mention then
        badge:SetBackdropColor(0.04,0.18,0.44,1)
        badge:SetBackdropBorderColor(0.32,0.75,1,1)
    elseif tone == "guild" then
        badge:SetBackdropColor(0.02,0.24,0.07,1)
        badge:SetBackdropBorderColor(0.24,0.80,0.34,1)
    elseif tone == "officer" then
        badge:SetBackdropColor(0.34,0.18,0.02,1)
        badge:SetBackdropBorderColor(0.95,0.60,0.15,1)
    else
        badge:SetBackdropColor(0.05,0.15,0.30,1)
        badge:SetBackdropBorderColor(0.26,0.60,0.95,1)
    end
end

local function MentionChannelsR4(self)
    local guildMention, officerMention = false, false
    local db = self:GetGuildDB()
    local index, entry, id
    for index=1,table.getn(db and db.inbox170 or {}) do
        entry = db.inbox170[index]
        if type(entry)=="table" and not entry.read and tostring(entry.category or "") == "mention" then
            id = string.upper(tostring(entry.id or ""))
            if string.find(id,"OFFICER",1,true) then officerMention=true else guildMention=true end
        end
    end
    return guildMention, officerMention
end

function OTLGM:EnsureGuildChatBadgesR4()
    if not self.ui or not self.ui.navButtons then return end
    local button = self.ui.navButtons.guildchat
    if button and not button.chatBadgesR4 then
        button.chatBadgesR4 = {
            guild=MakeMiniBadgeR4(button,"G",-53,"guild"),
            officer=MakeMiniBadgeR4(button,"O",-28,"officer"),
            board=MakeMiniBadgeR4(button,"B",-3,"board"),
        }
        if button.text then
            button.text:ClearAllPoints()
            button.text:SetPoint("LEFT",button,"LEFT",28,0)
            button.text:SetWidth(58)
            button.text:SetJustifyH("LEFT")
        end
    end
    local tabs = self.ui.chatChannelButtons
    if tabs then
        if tabs.GUILD and not tabs.GUILD.miniBadgeR4 then tabs.GUILD.miniBadgeR4=MakeMiniBadgeR4(tabs.GUILD,"G",-4,"guild") end
        if tabs.OFFICER and not tabs.OFFICER.miniBadgeR4 then tabs.OFFICER.miniBadgeR4=MakeMiniBadgeR4(tabs.OFFICER,"O",-4,"officer") end
        if tabs.BOARD and not tabs.BOARD.miniBadgeR4 then tabs.BOARD.miniBadgeR4=MakeMiniBadgeR4(tabs.BOARD,"B",-4,"board") end
    end
end

local function ShowMiniBadgeR4(badge, count, mention)
    if not badge then return end
    count = tonumber(count) or 0
    if count <= 0 and not mention then badge:Hide() return end
    local value = count > 9 and "9+" or tostring(count)
    if mention and count <= 0 then value="@" end
    badge.text:SetText(value)
    StyleMiniBadgeR4(badge,mention)
    badge:Show()
end

function OTLGM:RefreshGuildChatNavigationBadge()
    if not self.ui or not self.ui.navButtons then return end
    self:EnsureGuildChatBadgesR4()
    local chatButton = self.ui.navButtons.guildchat
    if chatButton and chatButton.navBadge170 then chatButton.navBadge170:Hide() end
    local guildUnread = self:GetGuildChatUnread("GUILD")
    local officerUnread = self:IsOfficerMode() and self:GetGuildChatUnread("OFFICER") or 0
    local boardUnread = self.GetPveUnread and self:GetPveUnread("BOARD") or 0
    local guildMention, officerMention = MentionChannelsR4(self)
    if chatButton and chatButton.chatBadgesR4 then
        ShowMiniBadgeR4(chatButton.chatBadgesR4.guild,guildUnread,guildMention)
        ShowMiniBadgeR4(chatButton.chatBadgesR4.officer,officerUnread,officerMention)
        ShowMiniBadgeR4(chatButton.chatBadgesR4.board,boardUnread,false)
    end
    local tabs = self.ui.chatChannelButtons
    if tabs then
        ShowMiniBadgeR4(tabs.GUILD and tabs.GUILD.miniBadgeR4,guildUnread,guildMention)
        ShowMiniBadgeR4(tabs.OFFICER and tabs.OFFICER.miniBadgeR4,officerUnread,officerMention)
        ShowMiniBadgeR4(tabs.BOARD and tabs.BOARD.miniBadgeR4,boardUnread,false)
        SetButtonTextR4(tabs.GUILD,"Guild")
        SetButtonTextR4(tabs.OFFICER,"Officer")
        SetButtonTextR4(tabs.BOARD,"Guild Board")
    end
end

-- ---------------------------------------------------------------------------
-- Guild Activity: dedicated insight strip above a separate action row.
-- ---------------------------------------------------------------------------

local BaseBuildActivityR4 = OTLGM.BuildActivityPage
function OTLGM:BuildActivityPage(page)
    BaseBuildActivityR4(self,page)
    local heat = self.ui.heatmapCells and self.ui.heatmapCells[0] and self.ui.heatmapCells[0][0] and self.ui.heatmapCells[0][0]:GetParent() or nil
    local composition = self.ui.compositionTotal and self.ui.compositionTotal:GetParent() or nil
    if heat then
        heat:ClearAllPoints()
        heat:SetPoint("TOPLEFT",page,"TOPLEFT",0,-146)
        heat:SetHeight(326)
    end
    if composition then
        composition:ClearAllPoints()
        composition:SetPoint("TOPLEFT",page,"TOPLEFT",480,-146)
        composition:SetHeight(326)
    end
    self.ui.activityInsightPanelR4 = CreatePanelR4(page,0,-478,718,38,"background")
    if self.ui.activityInsightText170 then
        self.ui.activityInsightText170:ClearAllPoints()
        self.ui.activityInsightText170:SetParent(self.ui.activityInsightPanelR4)
        self.ui.activityInsightText170:SetPoint("TOPLEFT",self.ui.activityInsightPanelR4,"TOPLEFT",9,-6)
        self.ui.activityInsightText170:SetWidth(700)
        self.ui.activityInsightText170:SetHeight(28)
        if self.ui.activityInsightText170.SetJustifyV then self.ui.activityInsightText170:SetJustifyV("TOP") end
    end
    if self.ui.activitySync156 then
        self.ui.activitySync156:ClearAllPoints()
        self.ui.activitySync156:SetPoint("TOPLEFT",page,"TOPLEFT",340,-522)
        self.ui.activitySync156:SetWidth(178)
        self.ui.activitySync156:SetHeight(27)
    end
    if self.ui.activitySummaryButton then
        self.ui.activitySummaryButton:ClearAllPoints()
        self.ui.activitySummaryButton:SetPoint("TOPLEFT",page,"TOPLEFT",528,-522)
        self.ui.activitySummaryButton:SetWidth(190)
        self.ui.activitySummaryButton:SetHeight(27)
    end
end

local BaseRefreshActivityR4 = OTLGM.RefreshActivityPage
function OTLGM:RefreshActivityPage()
    BaseRefreshActivityR4(self)
    if not self.ui or not self.ui.activityInsightText170 then return end
    local summary = self:GetActivitySummary(7)
    local coverage = tonumber(summary.sharedCoverage156) or 0
    local sources = tonumber(summary.sharedSources156) or 0
    local current = tostring(self.ui.activityInsightText170:GetText() or "")
    current = string.gsub(current,"%s+"," ")
    if current == "" then current = "More shared activity samples are needed before a reliable recommendation can be shown." end
    self.ui.activityInsightText170:SetText(current .. "  |  Coverage: " .. tostring(coverage) .. "% from " .. tostring(sources) .. " addon users")
end

-- ---------------------------------------------------------------------------
-- Raid editor and detail layout rebuilt as explicit vertical sections.
-- ---------------------------------------------------------------------------

function OTLGM:BuildRaidEditor156()
    if self.ui.raidEditor156 then return end
    local dialog = CreatePanelR4(self.ui.main,0,0,700,600,"surface")
    dialog:ClearAllPoints()
    dialog:SetPoint("CENTER",self.ui.main,"CENTER",0,0)
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetFrameLevel(self.ui.main:GetFrameLevel()+70)
    dialog:Hide()
    self.ui.raidEditor156 = dialog
    if self.RegisterModal152 then self:RegisterModal152(dialog) end

    self.ui.raidEditorTitle156 = CreateTextR4(dialog,"GameFontNormalLarge","CREATE RAID EVENT",20,-17,660,"CENTER")
    CreateTextR4(dialog,"GameFontNormalSmall","BASIC INFORMATION",22,-50,300,"LEFT"):SetTextColor(1,0.78,0.20)
    CreateTextR4(dialog,"GameFontNormalSmall","RAID NAME",22,-72,260,"LEFT")
    CreateTextR4(dialog,"GameFontNormalSmall","LOCATION / MEETING POINT",356,-72,300,"LEFT")
    self.ui.raidName156 = CreateEditR4(dialog,"OTLGM_RaidName156",22,-90,312,30,48,false)
    self.ui.raidLocation156 = CreateEditR4(dialog,"OTLGM_RaidLocation156",356,-90,322,30,48,false)

    CreateTextR4(dialog,"GameFontNormalSmall","DAY OFFSET",22,-136,100,"LEFT")
    self.ui.raidDay156 = CreateEditR4(dialog,"OTLGM_RaidDay156",22,-154,54,30,2,false)
    self.ui.raidDay156:SetText("0")
    CreateButtonR4(dialog,"Today",84,-154,68,30,function() OTLGM.ui.raidDay156:SetText("0") end,"normal")
    CreateButtonR4(dialog,"Tomorrow",160,-154,82,30,function() OTLGM.ui.raidDay156:SetText("1") end,"normal")
    CreateButtonR4(dialog,"+7 days",250,-154,76,30,function() OTLGM.ui.raidDay156:SetText("7") end,"normal")
    CreateTextR4(dialog,"GameFontNormalSmall","START (ST)",356,-136,100,"LEFT")
    self.ui.raidHour156 = CreateEditR4(dialog,"OTLGM_RaidHour156",356,-154,48,30,2,false)
    CreateTextR4(dialog,"GameFontNormalLarge",":",410,-159,16,"CENTER")
    self.ui.raidMinute156 = CreateEditR4(dialog,"OTLGM_RaidMinute156",428,-154,48,30,2,false)
    CreateTextR4(dialog,"GameFontNormalSmall","GATHER (ST)",500,-136,110,"LEFT")
    self.ui.raidGatherHour156 = CreateEditR4(dialog,"OTLGM_RaidGatherHour156",500,-154,48,30,2,false)
    CreateTextR4(dialog,"GameFontNormalLarge",":",554,-159,16,"CENTER")
    self.ui.raidGatherMinute156 = CreateEditR4(dialog,"OTLGM_RaidGatherMinute156",572,-154,48,30,2,false)

    CreateTextR4(dialog,"GameFontNormalSmall","BRIEFING",22,-207,100,"LEFT")
    self.ui.raidNote156 = CreateEditR4(dialog,"OTLGM_RaidNote156",22,-225,656,64,220,true)
    if self.ui.raidNote156.SetJustifyV then self.ui.raidNote156:SetJustifyV("TOP") end

    CreateTextR4(dialog,"GameFontNormalSmall","RAID TEAM",22,-302,300,"LEFT"):SetTextColor(1,0.78,0.20)
    CreateTextR4(dialog,"GameFontNormalSmall","RAID LEADER",22,-324,202,"LEFT")
    CreateTextR4(dialog,"GameFontNormalSmall","MAIN INVITE CONTACT",242,-324,202,"LEFT")
    self.ui.raidLeader175 = CreateEditR4(dialog,"OTLGM_RaidLeader175",22,-342,202,30,32,false)
    self.ui.raidInviteContact175 = CreateEditR4(dialog,"OTLGM_RaidInviteContact175",242,-342,202,30,32,false)
    CreateTextR4(dialog,"GameFontNormalSmall","INVITE HELPERS  (comma separated)",462,-324,216,"LEFT")
    self.ui.raidInviteHelpers175 = CreateEditR4(dialog,"OTLGM_RaidInviteHelpers175",462,-342,216,30,96,false)

    CreateTextR4(dialog,"GameFontNormalSmall","NOTIFICATIONS",22,-397,300,"LEFT"):SetTextColor(1,0.78,0.20)
    CreateTextR4(dialog,"GameFontNormalSmall","REMINDER MINUTES",22,-420,140,"LEFT")
    self.ui.raidReminder156 = CreateEditR4(dialog,"OTLGM_RaidReminder156",22,-438,72,30,4,false)
    self.ui.raidReminder156:SetText("60")
    self.ui.raidRecurring156 = "ONCE"
    self.ui.raidRecurringButton156 = CreateButtonR4(dialog,"One time",112,-438,118,30,function()
        OTLGM.ui.raidRecurring156 = OTLGM.ui.raidRecurring156 == "WEEKLY" and "ONCE" or "WEEKLY"
        SetButtonTextR4(OTLGM.ui.raidRecurringButton156,OTLGM.ui.raidRecurring156 == "WEEKLY" and "Weekly" or "One time")
        SetButtonSelectedR4(OTLGM.ui.raidRecurringButton156,OTLGM.ui.raidRecurring156 == "WEEKLY")
    end,"utility")

    self.ui.raidEditorHelpR4 = CreateTextR4(dialog,"GameFontNormalSmall","Raid Leader runs the event. Main Invite Contact receives Whisper for Invite. Helpers may also start the invite announcement. Official sign-ups remain in Discord.",22,-488,656,"LEFT")
    self.ui.raidEditorHelpR4:SetHeight(42)
    self.ui.raidEditorHelpR4:SetTextColor(0.60,0.60,0.58)
    self.ui.raidSave156 = CreateButtonR4(dialog,"Create Event",402,-548,132,34,function() OTLGM:SaveRaidEditor156() end,"confirm")
    self.ui.raidEditorCancel156 = CreateButtonR4(dialog,"Cancel",546,-548,132,34,function() dialog:Hide() end,"normal")
end

local BaseBuildRaidEnhancementsR4 = OTLGM.BuildRaidEnhancements157
function OTLGM:BuildRaidEnhancements157()
    BaseBuildRaidEnhancementsR4(self)
    local editor = self.ui and self.ui.raidEditor156
    if editor then
        if self.ui.raidDatePreview157 then
            self.ui.raidDatePreview157:ClearAllPoints()
            self.ui.raidDatePreview157:SetPoint("TOPLEFT",editor,"TOPLEFT",356,-190)
            self.ui.raidDatePreview157:SetWidth(322)
        end
        if self.ui.raidFeaturedButton157 then
            self.ui.raidFeaturedButton157:ClearAllPoints()
            self.ui.raidFeaturedButton157:SetPoint("TOPLEFT",editor,"TOPLEFT",248,-438)
            self.ui.raidFeaturedButton157:SetWidth(142)
            self.ui.raidFeaturedButton157:SetHeight(30)
        end
    end
    local detail = self.ui and self.ui.raidSeen156 and self.ui.raidSeen156:GetParent() or nil
    if detail then
        local function Move(frame,x,y,w,h)
            if not frame then return end
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT",detail,"TOPLEFT",x,y)
            if w then frame:SetWidth(w) end
            if h then frame:SetHeight(h) end
        end
        Move(self.ui.raidDetailTitle156,16,-14,396,38)
        Move(self.ui.raidDetailTime156,16,-54,396,20)
        Move(self.ui.raidDetailGather156,16,-78,396,18)
        Move(self.ui.raidDetailLocation156,16,-99,396,18)
        Move(self.ui.raidDetailNote156,16,-126,396,66)
        Move(self.ui.raidDetailAuthor156,16,-201,396,42)
        Move(self.ui.raidSeen156,16,-251,92,27)
        Move(self.ui.raidReady156,116,-251,92,27)
        Move(self.ui.raidEdit156,224,-251,86,27)
        Move(self.ui.raidMore156,318,-251,94,27)
        Move(self.ui.raidWhisperInvite175,16,-285,180,27)
        Move(self.ui.raidStartInvites175,204,-285,148,27)
        Move(self.ui.raidNoRole156,16,-320,396,48)
    end
end

local BaseRefreshRaidPlannerR4 = OTLGM.RefreshRaidPlanner156
function OTLGM:RefreshRaidPlanner156()
    local result = BaseRefreshRaidPlannerR4(self)
    local detail = self.ui and self.ui.raidSeen156 and self.ui.raidSeen156:GetParent() or nil
    if detail then
        local function Move(frame,x,y,w,h)
            if not frame then return end
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT",detail,"TOPLEFT",x,y)
            if w then frame:SetWidth(w) end
            if h then frame:SetHeight(h) end
        end
        Move(self.ui.raidDetailTitle156,16,-14,396,38)
        Move(self.ui.raidDetailTime156,16,-54,396,20)
        Move(self.ui.raidDetailGather156,16,-78,396,18)
        Move(self.ui.raidDetailLocation156,16,-99,396,18)
        Move(self.ui.raidDetailNote156,16,-126,396,66)
        Move(self.ui.raidDetailAuthor156,16,-201,396,42)
        Move(self.ui.raidSeen156,16,-251,92,27)
        Move(self.ui.raidReady156,116,-251,92,27)
        Move(self.ui.raidEdit156,224,-251,86,27)
        Move(self.ui.raidMore156,318,-251,94,27)
        Move(self.ui.raidWhisperInvite175,16,-285,180,27)
        Move(self.ui.raidStartInvites175,204,-285,148,27)
        Move(self.ui.raidNoRole156,16,-320,396,48)
        if self.ui.raidNoRole156 then
            self.ui.raidNoRole156:SetText("RAID PARTICIPATION ROLE\nReady may require an approved raider role. Every guild member can still read the raid and whisper the assigned invite contact.")
        end
    end
    return result
end

local BaseHomeRaidR4 = OTLGM.RefreshHomePveSummary155
function OTLGM:RefreshHomePveSummary155()
    BaseHomeRaidR4(self)
    if not self.ui or not self.ui.homeRaidText then return end
    local raids = self:GetRaidList156("UPCOMING")
    local selected = nil
    local index, raid
    for index=1,table.getn(raids) do
        raid = raids[index]
        if raid.status ~= "CANCELLED" and (tonumber(raid.startTs) or 0) >= self:Now()-60 then selected=raid break end
    end
    if not selected then return end
    local start = tonumber(selected.startTs) or 0
    local dateText = start > 0 and date("%a, %d %b",start) or "Date TBA"
    local timeText = self.GetPveRaidServerTime155 and self:GetPveRaidServerTime155(selected) or "Time TBA"
    local remaining = self.GetPveRaidRemainingText and self:GetPveRaidRemainingText(selected) or ""
    local leader = ShortNameR4(selected.raidLeader or selected.author or "Leadership")
    local contact = ShortNameR4(selected.inviteContact or leader)
    local location = selected.location and selected.location ~= "" and selected.location or "Meeting point TBA"
    local status = selected.invitesOpen and "|cff5fd9ffINVITES OPEN|r" or selected.featured and "|cffff5b3dIMPORTANT RAID|r" or "|cffffcc44NEXT RAID|r"
    self.ui.homeRaidText:SetText(status .. "\n|cffffffff" .. tostring(selected.name or "Guild Raid") .. "|r\n" ..
        dateText .. "  |  |cff69b7ff" .. timeText .. "|r\n" ..
        (remaining ~= "" and ("|cff78d67b" .. remaining .. "|r\n") or "") ..
        "Leader: |cffffd36b" .. leader .. "|r  Invites: |cffffd36b" .. contact .. "|r\n" ..
        "Meeting: " .. location)
end

-- ---------------------------------------------------------------------------
-- Darkmoon Faire: honest officer-confirmed Home status, never guessed.
-- ---------------------------------------------------------------------------

local DARKMOON_LABELS_R4 = {
    GOLDSHIRE="Goldshire",
    MULGORE="Mulgore",
    CLOSED="Closed",
    UNKNOWN="Unknown",
}

function OTLGM:GetDarkmoonStatusR4()
    OTLGM_DB.settings.darkmoonFaire175 = OTLGM_DB.settings.darkmoonFaire175 or {state="UNKNOWN",updatedAt=0,updatedBy=""}
    return OTLGM_DB.settings.darkmoonFaire175
end

function OTLGM:SetDarkmoonStatusR4(state)
    if not self:IsOfficerMode() then return false end
    state = string.upper(tostring(state or "UNKNOWN"))
    if not DARKMOON_LABELS_R4[state] then state="UNKNOWN" end
    local status = self:GetDarkmoonStatusR4()
    status.state=state
    status.updatedAt=self:Now()
    status.updatedBy=ShortNameR4(UnitName and UnitName("player") or "Leadership")
    self:RefreshDarkmoonStatusR4()
    if self.ui.darkmoonDialogR4 then self.ui.darkmoonDialogR4:Hide() end
    self:SetStatus("Darkmoon Faire status set to " .. DARKMOON_LABELS_R4[state] .. ".")
    return true
end

function OTLGM:RefreshDarkmoonStatusR4()
    if not self.ui or not self.ui.homeDarkmoonButtonR4 then return end
    local status = self:GetDarkmoonStatusR4()
    SetButtonTextR4(self.ui.homeDarkmoonButtonR4,"DMF: " .. (DARKMOON_LABELS_R4[status.state] or "Unknown"))
    local tone = status.state == "GOLDSHIRE" or status.state == "MULGORE"
    self.ui.homeDarkmoonButtonR4.actionStyle = tone and "confirm" or "utility"
    if self.ApplyButtonSkin then self:ApplyButtonSkin(self.ui.homeDarkmoonButtonR4) end
end

function OTLGM:BuildDarkmoonDialogR4()
    if self.ui.darkmoonDialogR4 then return end
    local dialog = CreatePanelR4(self.ui.main,0,0,460,245,"surface")
    dialog:ClearAllPoints()
    dialog:SetPoint("CENTER",self.ui.main,"CENTER",0,10)
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetFrameLevel(self.ui.main:GetFrameLevel()+72)
    dialog:Hide()
    self.ui.darkmoonDialogR4=dialog
    if self.RegisterModal152 then self:RegisterModal152(dialog) end
    CreateTextR4(dialog,"GameFontNormalLarge","DARKMOON FAIRE STATUS",20,-18,420,"CENTER")
    local note=CreateTextR4(dialog,"GameFontNormalSmall","OctoWoW does not expose a reliable world-wide Faire API. Leadership confirms the current state manually; the addon never guesses.",24,-56,412,"LEFT")
    note:SetHeight(42) note:SetTextColor(0.65,0.65,0.62)
    CreateButtonR4(dialog,"Goldshire",24,-112,92,30,function() OTLGM:SetDarkmoonStatusR4("GOLDSHIRE") end,"confirm")
    CreateButtonR4(dialog,"Mulgore",124,-112,92,30,function() OTLGM:SetDarkmoonStatusR4("MULGORE") end,"confirm")
    CreateButtonR4(dialog,"Closed",224,-112,92,30,function() OTLGM:SetDarkmoonStatusR4("CLOSED") end,"utility")
    CreateButtonR4(dialog,"Unknown",324,-112,92,30,function() OTLGM:SetDarkmoonStatusR4("UNKNOWN") end,"normal")
    CreateButtonR4(dialog,"Cancel",324,-194,92,28,function() dialog:Hide() end,"normal")
end

local BaseBuildHomeR4 = OTLGM.BuildHomePage
function OTLGM:BuildHomePage(page)
    BaseBuildHomeR4(self,page)
    if self.ui.homeGuildInfoButton then
        self.ui.homeGuildInfoButton:ClearAllPoints()
        self.ui.homeGuildInfoButton:SetPoint("TOPLEFT",page,"TOPLEFT",460,-492)
        self.ui.homeGuildInfoButton:SetWidth(126)
        SetButtonTextR4(self.ui.homeGuildInfoButton,"Guild Info")
    end
    self.ui.homeDarkmoonButtonR4 = CreateButtonR4(page,"DMF: Unknown",592,-492,126,24,function()
        local status=OTLGM:GetDarkmoonStatusR4()
        if OTLGM:IsOfficerMode() then
            OTLGM:BuildDarkmoonDialogR4()
            OTLGM:ShowModal152(OTLGM.ui.darkmoonDialogR4)
        else
            local text="Darkmoon Faire: " .. (DARKMOON_LABELS_R4[status.state] or "Unknown")
            if tonumber(status.updatedAt) and tonumber(status.updatedAt)>0 then text=text..". Last confirmed "..date("%d %b %H:%M",status.updatedAt).." by "..tostring(status.updatedBy or "leadership") end
            OTLGM:ShowNotice("Darkmoon Faire",text)
        end
    end,"utility")
    self.ui.homeDarkmoonButtonR4:SetScript("OnEnter",function()
        local status=OTLGM:GetDarkmoonStatusR4()
        GameTooltip:SetOwner(this,"ANCHOR_TOP")
        GameTooltip:AddLine("Darkmoon Faire",1,0.82,0.35)
        GameTooltip:AddLine(DARKMOON_LABELS_R4[status.state] or "Unknown",1,1,1)
        if tonumber(status.updatedAt) and tonumber(status.updatedAt)>0 then GameTooltip:AddLine("Confirmed "..date("%d %b %H:%M",status.updatedAt).." by "..tostring(status.updatedBy or "leadership"),0.7,0.7,0.68,true) end
        if OTLGM:IsOfficerMode() then GameTooltip:AddLine("Click to update the confirmed state.",0.45,0.75,1,true) end
        GameTooltip:Show()
    end)
    self.ui.homeDarkmoonButtonR4:SetScript("OnLeave",function() GameTooltip:Hide() end)
    self:RefreshDarkmoonStatusR4()
end

-- ---------------------------------------------------------------------------
-- Recruitment: Guild Info and Share Addon are editable with safe reset.
-- ---------------------------------------------------------------------------

local BaseRecruitmentPresetR4 = OTLGM.GetRecruitmentPreset170
function OTLGM:GetRecruitmentPreset170(key)
    local base = BaseRecruitmentPresetR4(self,key)
    if not base then return nil end
    if key == "GUILDINFO" or key == "ADDONINFO" then
        OTLGM_DB.settings.pinnedRecruitment175 = OTLGM_DB.settings.pinnedRecruitment175 or {}
        local override = OTLGM_DB.settings.pinnedRecruitment175[key]
        if override and override ~= "" then return {label=base.label,target=base.target,text=override} end
    end
    return base
end

function OTLGM:BuildPinnedRecruitmentEditorR4()
    if self.ui.pinnedRecruitEditorR4 then return end
    local dialog=CreatePanelR4(self.ui.main,0,0,560,310,"surface")
    dialog:ClearAllPoints()
    dialog:SetPoint("CENTER",self.ui.main,"CENTER",0,5)
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetFrameLevel(self.ui.main:GetFrameLevel()+74)
    dialog:Hide()
    self.ui.pinnedRecruitEditorR4=dialog
    if self.RegisterModal152 then self:RegisterModal152(dialog) end
    self.ui.pinnedRecruitTitleR4=CreateTextR4(dialog,"GameFontNormalLarge","EDIT PINNED MESSAGE",20,-18,520,"CENTER")
    self.ui.pinnedRecruitEditR4=CreateEditR4(dialog,"OTLGM_PinnedRecruitmentR4",24,-58,512,150,240,true)
    if self.ui.pinnedRecruitEditR4.SetJustifyV then self.ui.pinnedRecruitEditR4:SetJustifyV("TOP") end
    self.ui.pinnedRecruitCountR4=CreateTextR4(dialog,"GameFontNormalSmall","0 / 240",24,-216,512,"RIGHT")
    self.ui.pinnedRecruitEditR4:SetScript("OnTextChanged",function()
        local length=string.len(this:GetText() or "")
        OTLGM.ui.pinnedRecruitCountR4:SetText(tostring(length).." / 240")
        OTLGM.ui.pinnedRecruitCountR4:SetTextColor(length<=240 and 0.65 or 1,length<=240 and 0.65 or 0.25,length<=240 and 0.62 or 0.25)
    end)
    CreateButtonR4(dialog,"Reset Default",24,-258,116,30,function()
        local key=OTLGM.ui.pinnedRecruitEditorR4.keyR4
        OTLGM_DB.settings.pinnedRecruitment175=OTLGM_DB.settings.pinnedRecruitment175 or {}
        OTLGM_DB.settings.pinnedRecruitment175[key]=nil
        local preset=BaseRecruitmentPresetR4(OTLGM,key)
        OTLGM.ui.pinnedRecruitEditR4:SetText(preset and preset.text or "")
        OTLGM:RefreshRecruitmentPage()
    end,"utility")
    CreateButtonR4(dialog,"Save",330,-258,96,30,function()
        local key=OTLGM.ui.pinnedRecruitEditorR4.keyR4
        local text=TrimR4(OTLGM.ui.pinnedRecruitEditR4:GetText() or "")
        if text=="" then OTLGM:ShowNotice("Pinned Message","The message cannot be empty.") return end
        if string.len(text)>240 then OTLGM:ShowNotice("Pinned Message","The message exceeds the 240-character limit.") return end
        OTLGM_DB.settings.pinnedRecruitment175=OTLGM_DB.settings.pinnedRecruitment175 or {}
        OTLGM_DB.settings.pinnedRecruitment175[key]=text
        OTLGM.ui.pinnedRecruitEditorR4:Hide()
        OTLGM:RefreshRecruitmentPage()
        OTLGM:SetStatus("Pinned recruitment message updated.")
    end,"confirm")
    CreateButtonR4(dialog,"Cancel",438,-258,98,30,function() dialog:Hide() end,"normal")
end

function OTLGM:OpenPinnedRecruitmentEditorR4(key)
    if not self:IsOfficerMode() then return end
    self:BuildPinnedRecruitmentEditorR4()
    local preset=self:GetRecruitmentPreset170(key)
    self.ui.pinnedRecruitEditorR4.keyR4=key
    self.ui.pinnedRecruitTitleR4:SetText(key=="GUILDINFO" and "EDIT GUILD INFO" or "EDIT SHARE ADDON")
    self.ui.pinnedRecruitEditR4:SetText(preset and preset.text or "")
    self:ShowModal152(self.ui.pinnedRecruitEditorR4)
end

local BaseBuildRecruitmentR4 = OTLGM.BuildRecruitmentPage
function OTLGM:BuildRecruitmentPage(page)
    BaseBuildRecruitmentR4(self,page)
    self.ui.pinnedRecruitEditButtonsR4={}
    local keys={"GUILDINFO","ADDONINFO"}
    local index,key,row
    for index=1,2 do
        key=keys[index]
        row=self.ui.recruitPresetButtons[key] and self.ui.recruitPresetButtons[key]:GetParent() or nil
        if row then
            if self.ui.recruitPresetPreviews170[key] then self.ui.recruitPresetPreviews170[key]:SetWidth(402) end
            local captured=key
            self.ui.pinnedRecruitEditButtonsR4[key]=CreateButtonR4(row,"Edit",526,-6,56,28,function() OTLGM:OpenPinnedRecruitmentEditorR4(captured) end,"utility")
        end
    end
end

local BaseRefreshRecruitmentR4 = OTLGM.RefreshRecruitmentPage
function OTLGM:RefreshRecruitmentPage()
    BaseRefreshRecruitmentR4(self)
    local key,button
    for key,button in pairs(self.ui and self.ui.pinnedRecruitEditButtonsR4 or {}) do
        if self:IsOfficerMode() then button:Show() else button:Hide() end
    end
end

-- ---------------------------------------------------------------------------
-- Low-cost corrective event bridge.
-- ---------------------------------------------------------------------------

local eventFrameR4 = CreateFrame("Frame","OTLGM_Release175R4Event")
local eventsR4={"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_EQUIPMENT_CHANGED","GUILD_ROSTER_UPDATE","PLAYER_GUILD_UPDATE"}
local eventIndexR4
for eventIndexR4=1,table.getn(eventsR4) do pcall(eventFrameR4.RegisterEvent,eventFrameR4,eventsR4[eventIndexR4]) end
eventFrameR4:SetScript("OnEvent",function()
    if not OTLGM then return end
    if event=="PLAYER_LOGIN" then
        local db=OTLGM:EnsureAchievements174()
        local baseline=not db.thresholdBaseline175r4
        EvaluateThresholdAchievementsR4(OTLGM,baseline)
        db.thresholdBaseline175r4=true
        OTLGM:CheckUnderBanner175R4(false)
    elseif event=="PLAYER_ENTERING_WORLD" or event=="GUILD_ROSTER_UPDATE" or event=="PLAYER_GUILD_UPDATE" then
        OTLGM:CheckUnderBanner175R4(false)
    elseif event=="PLAYER_EQUIPMENT_CHANGED" then
        if arg1==nil or tonumber(arg1)==19 then OTLGM:CheckUnderBanner175R4(false) end
    end
end)

if OTLGM.RegisterModule then OTLGM:RegisterModule("Release175R4",{layer="feature",corrective=true,totalAchievements=121,eventDriven=true,noOnUpdate=true}) end

-- Direct-assignment trackers need one light post-action threshold evaluation.
local BaseUpdateGroupSessionR4 = OTLGM.UpdateGroupSession174
function OTLGM:UpdateGroupSession174(silent)
    local result = BaseUpdateGroupSessionR4(self,silent)
    EvaluateThresholdAchievementsR4(self,silent and true or false)
    return result
end

local BaseRecordGroupApplicationR4 = OTLGM.RecordGroupApplication174
function OTLGM:RecordGroupApplication174(group,record)
    local result = BaseRecordGroupApplicationR4(self,group,record)
    EvaluateThresholdAchievementsR4(self,false)
    return result
end

local BaseCheckResurrectionR4 = OTLGM.CheckResurrection175
function OTLGM:CheckResurrection175()
    local result = BaseCheckResurrectionR4(self)
    if result then EvaluateThresholdAchievementsR4(self,false) end
    return result
end

