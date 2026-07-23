-- Order of the Lion Guild Manager v1.7.5
-- Corrective release layer r5. Loaded after Release175R4.lua.
-- Vanilla / OctoWoW / Lua 5.0 compatible. No additional OnUpdate handlers.

local R5 = {
    revision = 5,
    chatMeasureCache = {},
    keyboardInstalled = false,
}
OTLGM.release175r5 = R5
OTLGM.build = "stable-r5-20260723"

local LION_ICON_R5 = "Interface\\AddOns\\OrderOfTheLionGM\\Assets\\LionCrest"
local NEUTRAL_TABARD_R5 = LION_ICON_R5
local SAFE_ICON_R5 = "Interface\\Icons\\INV_Misc_Book_09"

local function TrimR5(text)
    text = tostring(text or "")
    return string.gsub(text, "^%s*(.-)%s*$", "%1")
end

local function ShortNameR5(name)
    return string.gsub(TrimR5(name), "%-.*$", "")
end

local function NameKeyR5(name)
    return string.lower(ShortNameR5(name or ""))
end

local function SetButtonTextR5(button, text)
    if not button then return end
    if button.text and button.text.SetText then button.text:SetText(text or "")
    elseif button.label156 and button.label156.SetText then button.label156:SetText(text or "") end
end

local function SetButtonSelectedR5(button, selected)
    if not button then return end
    button.selected = selected and true or false
    button.selected156 = selected and true or false
    if OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(button) end
end

local function SetButtonEnabledR5(button, enabled, reason)
    if not button then return end
    if OTLGM.SetControlEnabled170 then
        OTLGM:SetControlEnabled170(button, enabled and true or false, reason)
    else
        button.disabled = enabled and nil or true
        if button.Enable and button.Disable then if enabled then button:Enable() else button:Disable() end end
    end
    if OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(button) end
end

local function MoveR5(frame, parent, x, y, width, height)
    if not frame then return end
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", parent or frame:GetParent(), "TOPLEFT", x, y)
    if width then frame:SetWidth(width) end
    if height then frame:SetHeight(height) end
end

local function CreatePanelR5(parent, x, y, width, height, kind)
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

local function CreateTextR5(parent, template, text, x, y, width, justify)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then label:SetWidth(width) end
    label:SetJustifyH(justify or "LEFT")
    if label.SetJustifyV then label:SetJustifyV("TOP") end
    label:SetText(text or "")
    return label
end

local function CreateButtonR5(parent, text, x, y, width, height, callback, style)
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
    button.callbackR5 = callback
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function() if not this.disabled and this.callbackR5 then this.callbackR5(this) end end)
    button:SetScript("OnEnter", function() this.hovered=true if OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(this) end end)
    button:SetScript("OnLeave", function() this.hovered=nil if OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(this) end if GameTooltip then GameTooltip:Hide() end end)
    if OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(button) end
    return button
end

local function CreateEditR5(parent, name, x, y, width, height, maxLetters, multiline)
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
    edit:SetTextInsets(6,6,4,4)
    edit:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    return edit
end

local function AnyModalVisibleR5(self)
    local stack = self.ui and self.ui.modalStack154 or nil
    local index, frame
    for index=1,table.getn(stack or {}) do
        frame = stack[index]
        if frame and frame:IsVisible() then return true end
    end
    return false
end

local function GetKeyboardFocusR5()
    if GetCurrentKeyBoardFocus then return GetCurrentKeyBoardFocus() end
    return nil
end

local function BlizzardChatActiveR5()
    if ChatFrameEditBox and ChatFrameEditBox.IsVisible and ChatFrameEditBox:IsVisible() then return true end
    return false
end

local function IsGuildChatViewR5(self)
    if not self.ui or not self.ui.main or not self.ui.main:IsVisible() then return false end
    if self.ui.currentPage ~= "guildchat" then return false end
    return (OTLGM_DB.settings.guildChatView or "GUILD") ~= "BOARD"
end

-- ---------------------------------------------------------------------------
-- Achievement icon identity and layout polish.
-- ---------------------------------------------------------------------------

local ACHIEVEMENT_ICONS_R5 = {
    UNDER_BANNER = NEUTRAL_TABARD_R5,
    A044 = LION_ICON_R5,
    A054 = LION_ICON_R5,
    A092 = NEUTRAL_TABARD_R5,
    B073 = "Interface\\Icons\\INV_Misc_GroupNeedMore",
    B083 = LION_ICON_R5,
    C005 = "Interface\\Icons\\Spell_Holy_PrayerOfSpirit",
    C006 = LION_ICON_R5,
    C014 = "Interface\\Icons\\INV_Shield_06",
    C015 = LION_ICON_R5,
    C017 = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
    C018 = LION_ICON_R5,
}

local ACHIEVEMENT_NAME_ICONS_R5 = {
    ["Under the Banner"] = NEUTRAL_TABARD_R5,
    ["Five Under One Banner"] = LION_ICON_R5,
    ["Twenty Under One Banner"] = LION_ICON_R5,
    ["One Month Under the Banner"] = NEUTRAL_TABARD_R5,
    ["Proud Lion"] = LION_ICON_R5,
    ["All Nine Answer"] = "Interface\\Icons\\INV_Misc_GroupNeedMore",
    ["Diplomatic Incident"] = "Interface\\Icons\\Spell_Shadow_Twilight",
    ["What a Beautiful Moon..."] = "Interface\\Icons\\Spell_Arcane_StarFire",
    ["Wrong Tool for the Job"] = "Interface\\Icons\\INV_Fishingpole_02",
    ["Know Your Place"] = "Interface\\Icons\\Ability_DualWield",
    ["Bag Space Is a Myth"] = "Interface\\Icons\\INV_Misc_Bag_10",
    ["Fortune Favors the Guild"] = "Interface\\Icons\\INV_Misc_Gem_Pearl_05",
    ["Keeper of the Fallen"] = "Interface\\Icons\\Spell_Holy_Resurrection",
    ["Voice of Renewal"] = "Interface\\Icons\\Spell_Holy_Renew",
    ["No Lion Left Behind"] = "Interface\\Icons\\Spell_Holy_DivineIntervention",
    ["Known by a Hundred"] = "Interface\\Icons\\INV_Misc_GroupNeedMore",
    ["A Hall of Friends"] = "Interface\\Icons\\Spell_Holy_PrayerOfSpirit",
    ["Every Mane Remembered"] = LION_ICON_R5,
}

local function ApplyAchievementIconsR5()
    local state = OTLGM.achievements174
    local catalog = state and state.catalog or nil
    local index, def, icon
    for index=1,table.getn(catalog or {}) do
        def = catalog[index]
        icon = ACHIEVEMENT_ICONS_R5[def.id] or ACHIEVEMENT_NAME_ICONS_R5[def.name]
        if icon then def.icon = icon end
        if def.icon == "Interface\\Icons\\INV_BannerPVP_01" or def.icon == "Interface\\Icons\\INV_BannerPVP_02" then
            if string.find(string.lower(tostring(def.name or "")), "faction", 1, true) or string.find(string.lower(tostring(def.name or "")), "alliance", 1, true) or string.find(string.lower(tostring(def.name or "")), "horde", 1, true) then
                -- Keep faction art only where the achievement itself is faction-specific.
            else
                def.icon = LION_ICON_R5
            end
        end
    end
end

ApplyAchievementIconsR5()

local BaseBuildAchievementsR5 = OTLGM.BuildAchievementsPage174
function OTLGM:BuildAchievementsPage174(page)
    BaseBuildAchievementsR5(self,page)
    if self.ui.achievementSearchPlaceholder175 then
        self.ui.achievementSearchPlaceholder175:SetTextColor(0.58,0.58,0.56)
    end
    local progress = self.ui.achievementProgressFill174 and self.ui.achievementProgressFill174:GetParent() or nil
    if progress then progress:SetHeight(15) end
    if self.ui.achievementProgressFill174 then self.ui.achievementProgressFill174:SetHeight(9) end
    local key, button
    for key,button in pairs(self.ui.achievementCategoryButtons174 or {}) do
        if button.text then
            button.text:ClearAllPoints()
            button.text:SetPoint("LEFT",button,"LEFT",27,0)
            button.text:SetWidth(78)
            button.text:SetJustifyH("LEFT")
        end
        if button.countText174 then
            button.countText174:ClearAllPoints()
            button.countText174:SetPoint("RIGHT",button,"RIGHT",-7,0)
            button.countText174:SetWidth(44)
            button.countText174:SetJustifyH("RIGHT")
            if button.countText174.SetNonSpaceWrap then button.countText174:SetNonSpaceWrap(true) end
        end
    end
    local index,row
    for index=1,table.getn(self.ui.achievementRows174 or {}) do
        row=self.ui.achievementRows174[index]
        if row.description174 then
            row.description174:SetWidth(330)
            row.description174:SetHeight(27)
            if row.description174.SetJustifyV then row.description174:SetJustifyV("TOP") end
        end
    end
end

local BaseRefreshAchievementsR5 = OTLGM.RefreshAchievements174
function OTLGM:RefreshAchievements174()
    ApplyAchievementIconsR5()
    BaseRefreshAchievementsR5(self)
    if not self.ui or not self.ui.achievementRows174 then return end
    local completed,total = self:GetAchievementCount174()
    local list = self:GetAchievementDisplayList174()
    local pageSize = 6
    local totalRows = table.getn(list)
    local offset = tonumber(self.ui.achievementOffset174) or 0
    local page = totalRows > 0 and (math.floor(offset/pageSize)+1) or 0
    local pages = totalRows > 0 and math.ceil(totalRows/pageSize) or 0
    if self.ui.achievementStatus174 then
        if totalRows == 0 then self.ui.achievementStatus174:SetText("No achievements match this view.")
        else self.ui.achievementStatus174:SetText("Page "..tostring(page).." / "..tostring(pages).."   "..tostring(offset+1).."-"..tostring(math.min(offset+pageSize,totalRows)).." of "..tostring(totalRows)) end
    end
    local key,button,index,def,cc,ct
    for key,button in pairs(self.ui.achievementCategoryButtons174 or {}) do
        cc,ct=0,0
        for index=1,table.getn(OTLGM.achievements174.catalog or {}) do
            def=OTLGM.achievements174.catalog[index]
            if key=="OVERVIEW" or def.category==key then
                ct=ct+1
                if self:IsAchievementComplete174(def.id) then cc=cc+1 end
            end
        end
        if button.countText174 then button.countText174:SetText(tostring(cc).."/"..tostring(ct)) end
    end
    local row
    for index=1,table.getn(self.ui.achievementRows174) do
        row=self.ui.achievementRows174[index]
        if row and row.achievement174 and row:IsVisible() then
            local mapped=ACHIEVEMENT_ICONS_R5[row.achievement174.id] or ACHIEVEMENT_NAME_ICONS_R5[row.achievement174.name]
            if mapped and row.icon174 then row.icon174:SetTexture(mapped) end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Guild Chat: accurate layout, continuation grouping, channel badges and focus.
-- ---------------------------------------------------------------------------

local function EnsureChatMeasureR5(self)
    self.ui = self.ui or {}
    if self.ui.chatMeasureR5 then return self.ui.chatMeasureR5 end
    local holder = CreateFrame("Frame",nil,UIParent)
    holder:SetWidth(10) holder:SetHeight(10)
    holder:SetPoint("TOPLEFT",UIParent,"TOPLEFT",-3000,-3000)
    if holder.SetAlpha then holder:SetAlpha(0) end
    local label = holder:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    label:SetPoint("TOPLEFT",holder,"TOPLEFT",0,0)
    label:SetJustifyH("LEFT")
    if label.SetJustifyV then label:SetJustifyV("TOP") end
    self.ui.chatMeasureR5=label
    return label
end

local function MeasureChatHeightR5(self,text,width)
    local visible=self:GetGuildChatVisibleText(text or "")
    local key=tostring(width).."|"..visible
    local cached=R5.chatMeasureCache[key]
    if cached then return cached end
    local label=EnsureChatMeasureR5(self)
    label:SetWidth(width)
    label:SetText(visible)
    local height=label.GetStringHeight and tonumber(label:GetStringHeight()) or nil
    if not height or height<13 then
        local length=string.len(visible)
        local perLine=width>=560 and 76 or width>=430 and 52 or 32
        height=math.max(15,math.ceil(length/perLine)*16)
    end
    height=math.ceil(height+3)
    if height>210 then height=210 end
    R5.chatMeasureCache[key]=height
    return height
end

local function SameChatGroupR5(previous,current)
    if not previous or not current then return false end
    if tostring(previous.channel or "")~=tostring(current.channel or "") then return false end
    if NameKeyR5(previous.sender)~=NameKeyR5(current.sender) then return false end
    local gap=(tonumber(current.ts) or 0)-(tonumber(previous.ts) or 0)
    if gap<0 or gap>120 then return false end
    if string.find(tostring(previous.text or ""),"^%[Guild Achievement%]") then return false end
    if string.find(tostring(current.text or ""),"^%[Guild Achievement%]") then return false end
    return true
end

function OTLGM:GetGuildChatLineCount(text)
    local channel=self:GetGuildChatChannel()
    local width=channel=="OFFICER" and 284 or 420
    return math.max(1,math.ceil(MeasureChatHeightR5(self,text,width)/16))
end

function OTLGM:GetGuildChatRowMetrics(messages,index,markerIndex)
    local info=messages[index]
    if not info then return 28,1,nil,false end
    local achievement=string.find(tostring(info.text or ""),"^%[Guild Achievement%]")~=nil
    local width=achievement and 578 or (info.channel=="OFFICER" and 272 or 420)
    local textHeight=MeasureChatHeightR5(self,info.text or "",width)
    local lines=math.max(1,math.ceil(textHeight/16))
    local separator=self:GetGuildChatTimeSeparator(messages,index)
    local marker=markerIndex and markerIndex==index
    local grouped=SameChatGroupR5(messages[index-1],info)
    local nextGrouped=SameChatGroupR5(info,messages[index+1])
    local height=math.max(grouped and 23 or 28,textHeight+(grouped and 4 or 8))
    if not nextGrouped then height=height+4 end
    if separator then height=height+17 end
    if marker then height=height+9 end
    return height,lines,separator,marker
end

local function FocusGuildChatR5(self)
    if not IsGuildChatViewR5(self) then return false end
    if AnyModalVisibleR5(self) then return false end
    if BlizzardChatActiveR5() then return false end
    local edit=self.ui and self.ui.guildChatEdit
    if not edit or not edit:IsVisible() then return false end
    edit:SetFocus()
    return true
end

local BaseBuildGuildChatR5=OTLGM.BuildGuildChatPage
function OTLGM:BuildGuildChatPage(page)
    BaseBuildGuildChatR5(self,page)
    if self.ui.guildChatEdit then
        self.ui.guildChatEdit:SetScript("OnEnterPressed",function() OTLGM:SendGuildChatFromPage() end)
    end
    if page.EnableKeyboard then
        page:EnableKeyboard(true)
        if page.SetPropagateKeyboardInput then page:SetPropagateKeyboardInput(true) end
        page:SetScript("OnKeyDown",function()
            local key=arg1
            if key~="ENTER" then return end
            if not IsGuildChatViewR5(OTLGM) then return end
            if AnyModalVisibleR5(OTLGM) or BlizzardChatActiveR5() then return end
            local focus=GetKeyboardFocusR5()
            if focus and focus~=OTLGM.ui.guildChatEdit then return end
            FocusGuildChatR5(OTLGM)
        end)
    end
end

function OTLGM:SendGuildChatFromPage()
    if not self.ui or not self.ui.guildChatEdit then return end
    local edit=self.ui.guildChatEdit
    local text=edit:GetText() or ""
    local channel=self:GetGuildChatChannel()
    if self:SendGuildChatMessage(text,channel) then
        self.updatingGuildChatDraft=true
        edit:SetText("")
        self.updatingGuildChatDraft=nil
        OTLGM_DB.settings.guildChatDrafts[channel]=""
        self.ui.chatOffsets[channel]=0
        self:RefreshGuildChatPage()
        edit:SetFocus()
    end
end

local BaseSelectGuildChatViewR5=OTLGM.SelectGuildChatView152
function OTLGM:SelectGuildChatView152(view)
    local result=BaseSelectGuildChatViewR5(self,view)
    if view~="BOARD" and self.ui and self.ui.currentPage=="guildchat" then FocusGuildChatR5(self) end
    return result
end

local BaseRefreshGuildChatR5=OTLGM.RefreshGuildChatPage
function OTLGM:RefreshGuildChatPage()
    local result=BaseRefreshGuildChatR5(self)
    if not self.ui or not self.ui.chatRows then return result end
    if self.ui.chatUnreadText then self.ui.chatUnreadText:Hide() end
    local previous=nil
    local index,row,current,grouped
    for index=1,table.getn(self.ui.chatRows) do
        row=self.ui.chatRows[index]
        current=row and row:IsVisible() and row.chatData or nil
        if current then
            grouped=SameChatGroupR5(previous,current) and not row.separatorText:IsVisible() and not row.newLine:IsVisible()
            if row.messageFrame then
                if row.messageFrame.SetInsertMode then row.messageFrame:SetInsertMode("TOP") end
                if row.messageFrame.SetJustifyV then row.messageFrame:SetJustifyV("TOP") end
                if row.messageFrame.ScrollToTop then row.messageFrame:ScrollToTop() end
            end
            if not row.continuationR5 then
                row.continuationR5=row:CreateTexture(nil,"ARTWORK")
                row.continuationR5:SetTexture(0.40,0.34,0.23,0.65)
                row.continuationR5:SetWidth(2)
            end
            if grouped then
                row.timeText:Hide() row.rankButton:Hide() row.senderButton:Hide()
                row.continuationR5:ClearAllPoints()
                row.continuationR5:SetPoint("TOPLEFT",row,"TOPLEFT",214,-2)
                row.continuationR5:SetHeight(math.max(12,row:GetHeight()-6))
                row.continuationR5:Show()
                row.shade:SetTexture(0.045,0.038,0.028,0.30)
            else
                row.continuationR5:Hide()
            end
            previous=current
        else
            if row and row.continuationR5 then row.continuationR5:Hide() end
        end
    end
    if self.ui.chatClearButton and self.ui.chatClearButton.text then
        local count=table.getn(self:GetChatHighlights170("MENTIONS",self:GetGuildChatChannel()))
        self.ui.chatClearButton.text:SetText("Highlights")
        if not self.ui.chatHighlightsBadgeR5 then
            local badge=CreateFrame("Frame",nil,self.ui.chatClearButton)
            badge:SetWidth(22) badge:SetHeight(15)
            badge:SetPoint("RIGHT",self.ui.chatClearButton,"RIGHT",-5,0)
            badge:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=7,insets={left=1,right=1,top=1,bottom=1}})
            badge:SetBackdropColor(0.05,0.15,0.30,1)
            badge:SetBackdropBorderColor(0.26,0.60,0.95,1)
            badge.text=badge:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
            badge.text:SetPoint("CENTER",badge,"CENTER",0,0)
            self.ui.chatHighlightsBadgeR5=badge
        end
        if count>0 then self.ui.chatHighlightsBadgeR5.text:SetText(count>9 and "9+" or tostring(count)) self.ui.chatHighlightsBadgeR5:Show() else self.ui.chatHighlightsBadgeR5:Hide() end
    end
    return result
end

local function MentionChannelsR5(self)
    local guildMention,officerMention=false,false
    local db=self:GetGuildDB()
    local index,entry,id
    for index=1,table.getn(db and db.inbox170 or {}) do
        entry=db.inbox170[index]
        if type(entry)=="table" and not entry.read and tostring(entry.category or "")=="mention" then
            id=string.upper(tostring(entry.id or ""))
            if string.find(id,"OFFICER",1,true) then officerMention=true else guildMention=true end
        end
    end
    return guildMention,officerMention
end

local BaseRefreshGuildChatBadgeR5=OTLGM.RefreshGuildChatNavigationBadge
function OTLGM:RefreshGuildChatNavigationBadge()
    BaseRefreshGuildChatBadgeR5(self)
    local button=self.ui and self.ui.navButtons and self.ui.navButtons.guildchat or nil
    local badges=button and button.chatBadgesR4 or nil
    local guildUnread=self:GetGuildChatUnread("GUILD")
    local officerUnread=self:IsOfficerMode() and self:GetGuildChatUnread("OFFICER") or 0
    local boardUnread=self.GetPveUnread and self:GetPveUnread("BOARD") or 0
    local guildMention,officerMention=MentionChannelsR5(self)
    if button and button.text then
        button.text:ClearAllPoints()
        button.text:SetPoint("LEFT",button,"LEFT",28,0)
        button.text:SetWidth(62)
        button.text:SetJustifyH("LEFT")
        button.text:SetText("Guild Chat")
    end
    local function Style(badge,label,count,x,tip,mention)
        if not badge then return end
        badge:ClearAllPoints()
        badge:SetPoint("RIGHT",button,"RIGHT",x,0)
        badge:SetWidth(18) badge:SetHeight(15)
        badge.channelLabelR5=label
        badge.channelTipR5=tip
        if badge.EnableMouse then badge:EnableMouse(true) end
        badge:SetScript("OnEnter",function()
            if not GameTooltip then return end
            GameTooltip:SetOwner(this,"ANCHOR_RIGHT")
            GameTooltip:AddLine(this.channelTipR5 or "Guild Chat",1,0.82,0.35)
            GameTooltip:AddLine(tostring(this.channelCountR5 or 0).." unread",1,1,1)
            GameTooltip:Show()
        end)
        badge:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
        badge.channelCountR5=count
        if count>0 or mention then
            badge.text:SetText(count>0 and (count>9 and "9+" or tostring(count)) or "@")
            badge:Show()
        else badge:Hide() end
    end
    if badges then
        Style(badges.guild,"G",guildUnread,-39,"Guild channel",guildMention)
        Style(badges.officer,"O",officerUnread,-20,"Officer channel",officerMention)
        Style(badges.board,"B",boardUnread,-1,"Guild Board",false)
    end
    local tabs=self.ui and self.ui.chatChannelButtons or nil
    if tabs then
        if tabs.GUILD and tabs.GUILD.miniBadgeR4 then tabs.GUILD.miniBadgeR4.text:SetText(guildUnread>0 and (guildUnread>9 and "9+" or tostring(guildUnread)) or "@") if guildUnread>0 or guildMention then tabs.GUILD.miniBadgeR4:Show() else tabs.GUILD.miniBadgeR4:Hide() end end
        if tabs.OFFICER and tabs.OFFICER.miniBadgeR4 then tabs.OFFICER.miniBadgeR4.text:SetText(officerUnread>0 and (officerUnread>9 and "9+" or tostring(officerUnread)) or "@") if officerUnread>0 or officerMention then tabs.OFFICER.miniBadgeR4:Show() else tabs.OFFICER.miniBadgeR4:Hide() end end
        if tabs.BOARD and tabs.BOARD.miniBadgeR4 then tabs.BOARD.miniBadgeR4.text:SetText(boardUnread>9 and "9+" or tostring(boardUnread)) if boardUnread>0 then tabs.BOARD.miniBadgeR4:Show() else tabs.BOARD.miniBadgeR4:Hide() end end
    end
end

-- ---------------------------------------------------------------------------
-- Activity and Overview layout.
-- ---------------------------------------------------------------------------

local BaseBuildActivityR5=OTLGM.BuildActivityPage
function OTLGM:BuildActivityPage(page)
    BaseBuildActivityR5(self,page)
    local heat=self.ui.heatmapCells and self.ui.heatmapCells[0] and self.ui.heatmapCells[0][0] and self.ui.heatmapCells[0][0]:GetParent() or nil
    local composition=self.ui.compositionTotal and self.ui.compositionTotal:GetParent() or nil
    if heat then MoveR5(heat,page,0,-142,470,326) end
    if composition then MoveR5(composition,page,480,-142,238,326) end
    if self.ui.activityInsightPanelR4 then MoveR5(self.ui.activityInsightPanelR4,page,0,-474,718,40) end
    if self.ui.activityInsightText170 then
        MoveR5(self.ui.activityInsightText170,self.ui.activityInsightPanelR4 or page,9,-5,700,30)
        self.ui.activityInsightText170:SetHeight(30)
    end
    if self.ui.activitySync156 then MoveR5(self.ui.activitySync156,page,340,-518,178,27) end
    if self.ui.activitySummaryButton then MoveR5(self.ui.activitySummaryButton,page,528,-518,190,27) end
end

local BaseRefreshActivityR5=OTLGM.RefreshActivityPage
function OTLGM:RefreshActivityPage()
    local result=BaseRefreshActivityR5(self)
    if self.ui and self.ui.activityInsightText170 then
        local text=tostring(self.ui.activityInsightText170:GetText() or "")
        text=string.gsub(text,"%s+|%s+Coverage:","\nCoverage:")
        self.ui.activityInsightText170:SetText(text)
    end
    return result
end

local BaseBuildOverviewR5=OTLGM.BuildOverviewPage
function OTLGM:BuildOverviewPage(page)
    BaseBuildOverviewR5(self,page)
    local summary=self.ui.overviewGrowth and self.ui.overviewGrowth:GetParent() or nil
    if summary then summary:SetHeight(78) end
    if self.ui.overviewGrowth then MoveR5(self.ui.overviewGrowth,summary,14,-10,230,24) end
    if self.ui.overviewChanges then MoveR5(self.ui.overviewChanges,summary,252,-10,448,40) self.ui.overviewChanges:SetHeight(40) end
    if self.ui.overviewFreshness then MoveR5(self.ui.overviewFreshness,summary,14,-54,686,18) end
    if self.ui.overviewAnnouncementButton then MoveR5(self.ui.overviewAnnouncementButton,page,0,-494,126,28) end
    if self.ui.overviewRaidButton then MoveR5(self.ui.overviewRaidButton,page,136,-494,116,28) end
    if self.ui.overviewRecruitButton then MoveR5(self.ui.overviewRecruitButton,page,262,-494,120,28) end
    if self.ui.overviewSummaryButton then MoveR5(self.ui.overviewSummaryButton,page,552,-494,166,28) end
end

local BaseRefreshOverviewR5=OTLGM.RefreshOverviewPage
function OTLGM:RefreshOverviewPage()
    local result=BaseRefreshOverviewR5(self)
    if self.ui and self.ui.overviewFreshness then
        local text=tostring(self.ui.overviewFreshness:GetText() or "")
        text=string.gsub(text,"Compared with%s+","Compared with ")
        self.ui.overviewFreshness:SetText(text)
    end
    if self.ui and self.ui.overviewCards and self.ui.overviewCards.joined then
        local card=self.ui.overviewCards.joined
        if card.value and string.find(tostring(card.value:GetText() or ""),"REVIEW",1,true) then
            if card.label then card.label:SetText("ROSTER CHANGES") end
            if card.sub then card.sub:SetText("Large roster delta - review History") end
        end
    end
    return result
end

-- ---------------------------------------------------------------------------
-- Home layout and Darkmoon presentation.
-- ---------------------------------------------------------------------------

local BaseBuildHomeR5=OTLGM.BuildHomePage
function OTLGM:BuildHomePage(page)
    BaseBuildHomeR5(self,page)
    local raid=self.ui.homeRaidText and self.ui.homeRaidText:GetParent() or nil
    local leaders=self.ui.homeLeaderButtons and self.ui.homeLeaderButtons[1] and self.ui.homeLeaderButtons[1]:GetParent() or nil
    local recent=self.ui.homeRecentPanel153
    if raid then raid:SetHeight(230) self.ui.homeRaidText:SetHeight(126) end
    if leaders then MoveR5(leaders,page,460,-248,258,142) leaders:SetHeight(142) end
    if recent then MoveR5(recent,page,460,-394,258,98) recent:SetHeight(98) end
    local i
    for i=1,4 do
        if self.ui.homeLeaderButtons and self.ui.homeLeaderButtons[i] then MoveR5(self.ui.homeLeaderButtons[i],leaders,12,-34-((i-1)*26),234,23) end
        if self.ui.homeUsefulRows and self.ui.homeUsefulRows[i] then MoveR5(self.ui.homeUsefulRows[i],recent,12,-32-((i-1)*17),234,16) end
    end
    if self.ui.homeUsefulViewAll153 then MoveR5(self.ui.homeUsefulViewAll153,recent,184,-5,62,22) end
    if self.ui.homeGuildInfoButton then MoveR5(self.ui.homeGuildInfoButton,page,460,-500,126,24) end
    if self.ui.homeDarkmoonButtonR4 then
        MoveR5(self.ui.homeDarkmoonButtonR4,page,592,-500,126,24)
        self.ui.homeDarkmoonButtonR4.actionStyle="normal"
        if self.ApplyButtonSkin then self:ApplyButtonSkin(self.ui.homeDarkmoonButtonR4) end
    end
end

local BaseRefreshHomeRaidR5=OTLGM.RefreshHomePveSummary155
function OTLGM:RefreshHomePveSummary155()
    BaseRefreshHomeRaidR5(self)
    if not self.ui or not self.ui.homeRaidText then return end
    local raids=self:GetRaidList156("UPCOMING")
    local selected=nil
    local index,raid
    for index=1,table.getn(raids) do
        raid=raids[index]
        if raid.status~="CANCELLED" and (tonumber(raid.startTs) or 0)>=self:Now()-60 then selected=raid break end
    end
    if not selected then return end
    local start=tonumber(selected.startTs) or 0
    local dateText=start>0 and date("%A, %d %B",start) or "Date TBA"
    local timeText=self.GetPveRaidServerTime155 and self:GetPveRaidServerTime155(selected) or "Time TBA"
    local remaining=self.GetPveRaidRemainingText and self:GetPveRaidRemainingText(selected) or ""
    local leader=ShortNameR5(selected.raidLeader or selected.author or "Leadership")
    local contact=ShortNameR5(selected.inviteContact or leader)
    local location=selected.location and selected.location~="" and selected.location or "Meeting point TBA"
    local state=selected.invitesOpen and "|cff5fd9ffINVITES OPEN|r\n" or selected.featured and "|cffff5b3dIMPORTANT RAID|r\n" or ""
    self.ui.homeRaidText:SetText(
        state.."|cffffffff"..tostring(selected.name or "Guild Raid").."|r\n"..
        dateText.."\n|cff69b7ff"..timeText.."|r"..(remaining~="" and ("  |  |cff78d67b"..remaining.."|r") or "").."\n"..
        "Leader: |cffffd36b"..leader.."|r\nInvites: |cffffd36b"..contact.."|r\nMeeting: "..location)
end

local BaseRefreshDarkmoonR5=OTLGM.RefreshDarkmoonStatusR4
function OTLGM:RefreshDarkmoonStatusR4()
    BaseRefreshDarkmoonR5(self)
    if not self.ui or not self.ui.homeDarkmoonButtonR4 then return end
    local status=self:GetDarkmoonStatusR4()
    local labels={GOLDSHIRE="Goldshire",MULGORE="Mulgore",CLOSED="Closed",UNKNOWN="Location unconfirmed"}
    SetButtonTextR5(self.ui.homeDarkmoonButtonR4,"DMF: "..(labels[status.state] or "Location unconfirmed"))
    self.ui.homeDarkmoonButtonR4.actionStyle="normal"
    if self.ApplyButtonSkin then self:ApplyButtonSkin(self.ui.homeDarkmoonButtonR4) end
end

-- ---------------------------------------------------------------------------
-- Raid planner and editor final layout.
-- ---------------------------------------------------------------------------

local function ApplyRaidDetailLayoutR5(self)
    local detail=self.ui and self.ui.raidSeen156 and self.ui.raidSeen156:GetParent() or nil
    if not detail then return end
    MoveR5(self.ui.raidDetailTitle156,detail,16,-12,396,38)
    MoveR5(self.ui.raidDetailTime156,detail,16,-52,396,18)
    MoveR5(self.ui.raidDetailGather156,detail,16,-76,396,18)
    MoveR5(self.ui.raidDetailLocation156,detail,16,-98,396,18)
    MoveR5(self.ui.raidDetailNote156,detail,16,-128,396,58)
    MoveR5(self.ui.raidDetailAuthor156,detail,16,-194,396,44)
    MoveR5(self.ui.raidSeen156,detail,16,-244,92,27)
    MoveR5(self.ui.raidReady156,detail,116,-244,92,27)
    MoveR5(self.ui.raidEdit156,detail,224,-244,86,27)
    MoveR5(self.ui.raidMore156,detail,318,-244,94,27)
    MoveR5(self.ui.raidWhisperInvite175,detail,16,-278,180,27)
    MoveR5(self.ui.raidStartInvites175,detail,204,-278,148,27)
    MoveR5(self.ui.raidNoRole156,detail,16,-314,396,54)
    if self.ui.raidNoRole156 then
        self.ui.raidNoRole156:SetHeight(54)
        self.ui.raidNoRole156:SetText("RAID PARTICIPATION ROLE\nReady may require an approved raider role. Every member can still read the raid and whisper the invite contact.")
    end
    SetButtonTextR5(self.ui.raidSeen156,"Seen by "..tostring(self.ui.raidSeen156.count156 or 0))
end

local BaseBuildRaidEnhancementsR5=OTLGM.BuildRaidEnhancements157
function OTLGM:BuildRaidEnhancements157()
    local result=BaseBuildRaidEnhancementsR5(self)
    ApplyRaidDetailLayoutR5(self)
    local editor=self.ui and self.ui.raidEditor156
    if editor then
        editor:SetHeight(620)
        if self.ui.raidNote156 then self.ui.raidNote156:SetHeight(76) end
        if self.ui.raidFeaturedButton157 then
            MoveR5(self.ui.raidFeaturedButton157,editor,264,-470,170,30)
            SetButtonTextR5(self.ui.raidFeaturedButton157,"Important Raid: Off")
        end
        if self.ui.raidEditorHelpR4 then MoveR5(self.ui.raidEditorHelpR4,editor,22,-512,656,40) end
        if self.ui.raidSave156 then MoveR5(self.ui.raidSave156,editor,402,-570,132,34) end
        if self.ui.raidEditorCancel156 then MoveR5(self.ui.raidEditorCancel156,editor,546,-570,132,34) end
    end
    return result
end

local BaseRefreshRaidPlannerR5=OTLGM.RefreshRaidPlanner156
function OTLGM:RefreshRaidPlanner156()
    local result=BaseRefreshRaidPlannerR5(self)
    ApplyRaidDetailLayoutR5(self)
    if self.ui and self.ui.raidSeen156 then
        local raid=self.GetSelectedRaid156 and self:GetSelectedRaid156() or nil
        local seen=raid and raid.seen and 0 or nil
        if raid and raid.seen then local k for k in pairs(raid.seen) do seen=seen+1 end end
        if seen then SetButtonTextR5(self.ui.raidSeen156,"Seen by "..tostring(seen)) end
    end
    return result
end

local BaseBuildRaidEditorR5=OTLGM.BuildRaidEditor156
function OTLGM:BuildRaidEditor156()
    BaseBuildRaidEditorR5(self)
    local editor=self.ui and self.ui.raidEditor156
    if not editor then return end
    editor:SetHeight(620)
    if self.ui.raidNote156 then self.ui.raidNote156:SetHeight(76) end
    if self.ui.raidEditorHelpR4 then MoveR5(self.ui.raidEditorHelpR4,editor,22,-512,656,40) end
    if self.ui.raidSave156 then MoveR5(self.ui.raidSave156,editor,402,-570,132,34) end
    if self.ui.raidEditorCancel156 then MoveR5(self.ui.raidEditorCancel156,editor,546,-570,132,34) end
end

-- ---------------------------------------------------------------------------
-- Treasury, History, Roster, Search, Professions and Board polish.
-- ---------------------------------------------------------------------------

local BaseBuildTreasuryR5=OTLGM.BuildTreasuryPage170
function OTLGM:BuildTreasuryPage170(page)
    BaseBuildTreasuryR5(self,page)
    -- Keep the proven base geometry. r5 only improves wording and event history;
    -- moving editor controls without their labels caused misalignment on some scales.
end

local BaseRefreshTreasuryR5=OTLGM.RefreshTreasuryPage170
function OTLGM:RefreshTreasuryPage170(forceEditor)
    local result=BaseRefreshTreasuryR5(self,forceEditor)
    local ui=self.ui and self.ui.treasury170
    if not ui then return result end
    local capability=self:GetGuildBankCapability170()
    if not capability.available then
        ui.serverState:SetText("Server guild-bank access is unavailable. Shared goals remain leadership-recorded and fully usable.")
        SetButtonTextR5(ui.detect,"Check Server Support")
    end
    local treasury=self:EnsureTreasury170()
    local index,entry,kind,label
    for index=1,3 do
        entry=treasury.history[index]
        if entry then
            kind=string.upper(tostring(entry.kind or "UPDATE"))
            if kind=="ADD" or kind=="SYNC ADD" then label="created a shared goal"
            elseif kind=="DELETE" or kind=="SYNC DELETE" then label="removed a shared goal"
            else label="updated a shared goal" end
            ui.history[index]:SetText(date("%d %b",entry.ts or self:Now()).."  "..tostring(entry.actor or "Leadership").." "..label)
        else ui.history[index]:SetText("") end
    end
    return result
end

local BaseBuildHistoryR5=OTLGM.BuildHistoryPage
function OTLGM:BuildHistoryPage(page)
    BaseBuildHistoryR5(self,page)
    if self.ui.historyMarkButton then SetButtonTextR5(self.ui.historyMarkButton,"Mark Reviewed") end
    local index,row
    for index=1,table.getn(self.ui.historyRows or {}) do
        row=self.ui.historyRows[index]
        if row.actor then row.actor:SetWidth(86) end
        if row.detail then row.detail:SetWidth(206) end
    end
end

local BaseRefreshHistoryRowsR5=OTLGM.RefreshHistoryRowsOnly
function OTLGM:RefreshHistoryRowsOnly()
    local result=BaseRefreshHistoryRowsR5(self)
    local index,row,item,detail
    for index=1,table.getn(self.ui and self.ui.historyRows or {}) do
        row=self.ui.historyRows[index]
        item=row and row.eventInfo
        if item and not item.header then
            if not item.actor or item.actor=="" then row.actor:SetText("") end
            detail=tostring(item.detail or "")
            if string.len(detail)>36 then detail=string.sub(detail,1,33).."..." end
            if item.kind=="LEAVE" and string.find(string.lower(detail),"actor unavailable",1,true) then detail="Left or was removed" end
            if detail~="" then row.detail:SetText(detail) end
        end
    end
    return result
end

local BaseRefreshHistoryR5=OTLGM.RefreshHistoryPage
function OTLGM:RefreshHistoryPage()
    local result=BaseRefreshHistoryR5(self)
    if self.ui and self.ui.historyMarkButton then
        local unread=self:GetUnreadCount()
        SetButtonTextR5(self.ui.historyMarkButton,"Mark Reviewed")
        if not self.ui.historyUnreadBadgeR5 then
            local badge=CreateFrame("Frame",nil,self.ui.historyMarkButton)
            badge:SetWidth(22) badge:SetHeight(15)
            badge:SetPoint("RIGHT",self.ui.historyMarkButton,"RIGHT",-4,0)
            badge:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=7,insets={left=1,right=1,top=1,bottom=1}})
            badge:SetBackdropColor(0.30,0.17,0.02,1)
            badge:SetBackdropBorderColor(0.95,0.60,0.15,1)
            badge.text=badge:CreateFontString(nil,"OVERLAY","GameFontNormalSmall") badge.text:SetPoint("CENTER",badge,"CENTER",0,0)
            self.ui.historyUnreadBadgeR5=badge
        end
        if unread>0 then self.ui.historyUnreadBadgeR5.text:SetText(unread>9 and "9+" or tostring(unread)) self.ui.historyUnreadBadgeR5:Show() else self.ui.historyUnreadBadgeR5:Hide() end
    end
    return result
end

local BaseBuildRosterR5=OTLGM.BuildRosterPage
function OTLGM:BuildRosterPage(page)
    BaseBuildRosterR5(self,page)
    if self.ui.rosterDetailEmpty then
        self.ui.rosterDetailEmpty:SetWidth(190)
        self.ui.rosterDetailEmpty:SetHeight(54)
    end
end

local BaseRefreshRosterR5=OTLGM.RefreshRosterPage
function OTLGM:RefreshRosterPage()
    local result=BaseRefreshRosterR5(self)
    local selected=self.ui and self.ui.selectedMember
    local controls={self.ui and self.ui.whisperButton,self.ui and self.ui.inviteButton,self.ui and self.ui.memberHistoryButton}
    local index
    for index=1,table.getn(controls) do if controls[index] then SetButtonEnabledR5(controls[index],selected~=nil,"Select a member first.") end end
    if not selected then
        local protected={self.ui and self.ui.saveNotesButton,self.ui and self.ui.promoteButton,self.ui and self.ui.demoteButton,self.ui and self.ui.removeButton}
        for index=1,table.getn(protected) do if protected[index] then SetButtonEnabledR5(protected[index],false,"Select a member first.") end end
    end
    local detailFrames={self.ui and self.ui.publicNoteLabel,self.ui and self.ui.publicNoteEdit,self.ui and self.ui.officerNoteLabel,self.ui and self.ui.officerNoteEdit,self.ui and self.ui.memberHistoryText,self.ui and self.ui.rankActionLabel}
    for index=1,table.getn(detailFrames) do if detailFrames[index] then if selected then detailFrames[index]:Show() else detailFrames[index]:Hide() end end end
    return result
end

local BaseRefreshSearchR5=OTLGM.RefreshSearchPage
function OTLGM:RefreshSearchPage(force)
    local result=BaseRefreshSearchR5(self,force)
    local rows=self.ui and self.ui.searchRows or self.ui and self.ui.nextSearchRows
    local index,row
    for index=1,table.getn(rows or {}) do
        row=rows[index]
        if row and row:IsVisible() then
            if row.typeText then row.typeText:SetWidth(88) end
            if row.titleText then row.titleText:SetWidth(220) end
            if row.detailText then row.detailText:SetWidth(360) end
        end
    end
    return result
end

local BaseRefreshProfessionsR5=OTLGM.RefreshProfessionsPage
function OTLGM:RefreshProfessionsPage()
    local result=BaseRefreshProfessionsR5(self)
    if self.ui and self.ui.craftingNetworkText then
        local users,latest,online=self:GetDetectedAddonUsers(86400)
        local craft=self:EnsureCraftingDB()
        local state=craft and craft.syncState or nil
        local received=state and tonumber(state.received) or 0
        if state and state.active then
            self.ui.craftingNetworkText:SetText("Syncing: "..tostring(received).." received  |  "..tostring(online or 0).." online")
        else
            self.ui.craftingNetworkText:SetText("Network: "..tostring(online or 0).." online  |  "..tostring(received).." last sync")
        end
    end
    if self.ui and self.ui.craftingSyncButton and self.ui.craftingSyncButton.text then
        local craft=self:EnsureCraftingDB()
        local state=craft and craft.syncState or nil
        if not state or not state.active then SetButtonTextR5(self.ui.craftingSyncButton,"Sync Now") end
    end
    return result
end

local BaseBuildBoardR5=OTLGM.BuildGuildBoardChat152
function OTLGM:BuildGuildBoardChat152(page)
    BaseBuildBoardR5(self,page)
    if self.ui.guildBoardNewEdit152 then
        self.ui.guildBoardNewEdit152:SetHeight(48)
        self.ui.guildBoardNewEdit152:SetMaxLetters(240)
        if self.ui.guildBoardNewEdit152.SetJustifyV then self.ui.guildBoardNewEdit152:SetJustifyV("TOP") end
        if not self.ui.guildBoardCountR5 then
            local parent=self.ui.guildBoardNewEdit152:GetParent()
            self.ui.guildBoardCountR5=CreateTextR5(parent,"GameFontNormalSmall","0 / 240",162,-371,100,"RIGHT")
            self.ui.guildBoardCountR5:SetTextColor(0.56,0.56,0.54)
        end
        self.ui.guildBoardNewEdit152:SetScript("OnTextChanged",function()
            local length=string.len(this:GetText() or "")
            if OTLGM.ui.guildBoardCountR5 then OTLGM.ui.guildBoardCountR5:SetText(tostring(length).." / 240") end
        end)
    end
    if self.ui.guildBoardShare152 then SetButtonTextR5(self.ui.guildBoardShare152,"Share Summary") end
    if self.ui.guildBoardDelete152 then
        self.ui.guildBoardDelete152:SetScript("OnClick",function()
            local id=OTLGM.ui and OTLGM.ui.guildBoardSelected152
            if not id then return end
            OTLGM:ShowConfirm("Delete Guild Board Post","Delete the selected Guild Board post?","Delete",function()
                OTLGM:DeletePveBoardPost(id,false)
                OTLGM.ui.guildBoardSelected152=nil
                OTLGM:RefreshGuildBoardChat152()
            end)
        end)
    end
end

local BaseRefreshBoardR5=OTLGM.RefreshGuildBoardChat152
function OTLGM:RefreshGuildBoardChat152()
    local result=BaseRefreshBoardR5(self)
    if self.ui and self.ui.guildBoardDetailMeta152 then
        local text=tostring(self.ui.guildBoardDetailMeta152:GetText() or "")
        text=string.gsub(text,"  |  expires automatically","  |  auto-expires")
        self.ui.guildBoardDetailMeta152:SetText(text)
    end
    return result
end

-- Group Finder labels and safer replacement wording.
local function FindOwnPveRequestR5(self)
    local player=NameKeyR5(UnitName("player") or "")
    local requests=self.GetPveRequests and self:GetPveRequests() or {}
    local index,request
    for index=1,table.getn(requests) do
        request=requests[index]
        if NameKeyR5(request and request.author or "")==player then return request end
    end
    return nil
end

local BaseBuildPveR5=OTLGM._Stage_UI_BuildPvePage_1
function OTLGM:_Stage_UI_BuildPvePage_1(page)
    local result=BaseBuildPveR5(self,page)
    if self.ui.pveRequestActivityEdit and not self.ui.pveActivityPlaceholderR5 then
        local parent=self.ui.pveRequestActivityEdit:GetParent()
        self.ui.pveActivityPlaceholderR5=CreateTextR5(parent,"GameFontNormalSmall","Dungeon, quest or activity...",20,-244,230,"LEFT")
        self.ui.pveActivityPlaceholderR5:SetTextColor(0.48,0.48,0.46)
        self.ui.pveRequestActivityEdit:SetScript("OnTextChanged",function() if this:GetText()=="" then OTLGM.ui.pveActivityPlaceholderR5:Show() else OTLGM.ui.pveActivityPlaceholderR5:Hide() end end)
        self.ui.pveRequestActivityEdit:SetScript("OnEditFocusGained",function() OTLGM.ui.pveActivityPlaceholderR5:Hide() end)
        self.ui.pveRequestActivityEdit:SetScript("OnEditFocusLost",function() if this:GetText()=="" then OTLGM.ui.pveActivityPlaceholderR5:Show() end end)
    end
    if self.ui.pveRequestCreateButton then
        local existing=FindOwnPveRequestR5(self)
        SetButtonTextR5(self.ui.pveRequestCreateButton,existing and "Update Group" or "Create Group")
    end
    return result
end


local BaseRefreshPveGroupsR5=OTLGM.RefreshPveGroupsPanel
function OTLGM:RefreshPveGroupsPanel()
    local result=BaseRefreshPveGroupsR5(self)
    if self.ui and self.ui.pveRequestCreateButton then
        SetButtonTextR5(self.ui.pveRequestCreateButton,FindOwnPveRequestR5(self) and "Update Group" or "Create Group")
    end
    return result
end

-- Refresh once after all wrapped builders have run.
local BaseRefreshAllR5=OTLGM.RefreshAll
function OTLGM:RefreshAll()
    local result=BaseRefreshAllR5(self)
    if self.RefreshGuildChatNavigationBadge then self:RefreshGuildChatNavigationBadge() end
    if self.RefreshDarkmoonStatusR4 then self:RefreshDarkmoonStatusR4() end
    return result
end

if OTLGM.RegisterModule then OTLGM:RegisterModule("Release175R5",{layer="feature",corrective=true,revision=5,totalAchievements=121,eventDriven=true,noOnUpdate=true}) end
