-- Order of the Lion Guild Manager
-- Complete Blizzard-like interface for Vanilla WoW / OctoWoW - v1.5.6

OTLGM.fullUILoaded = true
OTLGM.fullUIVersion = "1.5.6"

local NAV_DEFS = {
    { key = "home", label = "Home", section = "primary" },
    { key = "guildchat", label = "Guild Chat", section = "primary" },
    { key = "pve", label = "PvE Hub", section = "primary" },
    { key = "roster", label = "Roster", section = "member" },
    { key = "activity", label = "Activity", section = "member" },
    { key = "guildinfo", label = "Guild Info", section = "hidden" },
    { key = "overview", label = "Overview", officer = true, section = "officer" },
    { key = "recruitment", label = "Recruitment", officer = true, section = "officer" },
    { key = "history", label = "History", officer = true, section = "officer" },
    { key = "inactive", label = "Inactive", officer = true, section = "officer" },
    { key = "settings", label = "Settings", section = "utility" },
}

local NAV_ICONS = {
    home = "Interface\\Icons\\Ability_TownWatch",
    overview = "Interface\\Icons\\INV_Misc_Map_01",
    guildinfo = "Interface\\Icons\\INV_Scroll_03",
    pve = "Interface\\Icons\\INV_Helmet_06",
    roster = "Interface\\Icons\\INV_Misc_Book_09",
    activity = "Interface\\Icons\\INV_Misc_PocketWatch_01",
    guildchat = "Interface\\Icons\\INV_Letter_15",
    history = "Interface\\Icons\\INV_Misc_Book_11",
    inactive = "Interface\\Icons\\Spell_Shadow_Cripple",
    recruitment = "Interface\\Icons\\INV_Misc_Horn_02",
    settings = "Interface\\Icons\\INV_Gizmo_02",
}

local ROW_HEIGHT = 24
local ROSTER_ROWS = 13
local HISTORY_ROWS = 15
local INACTIVE_ROWS = 12
local CHAT_ROWS = 18
local PAGE_WIDTH = 756
local PAGE_HEIGHT = 532

local function CreateBackdrop(frame, inset)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = inset or 4, right = inset or 4, top = inset or 4, bottom = inset or 4 },
    })
end

local function CreateSolidTexture(parent, layer, r, g, b, a)
    local texture = parent:CreateTexture(nil, layer or "BACKGROUND")
    texture:SetTexture(r or 0, g or 0, b or 0, a or 1)
    return texture
end

local function CreateText(parent, template, text, x, y, width, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then fs:SetWidth(width) end
    fs:SetJustifyH(justify or "LEFT")
    fs:SetText(text or "")
    return fs
end

local function CreateWrappedText(parent, template, text, x, y, width, height)
    local fs = CreateText(parent, template, text, x, y, width, "LEFT")
    if height then fs:SetHeight(height) end
    fs:SetJustifyV("TOP")
    return fs
end

local function ApplyButtonVisual(button)
    if button.disabled then
        button:SetBackdropColor(0.07, 0.06, 0.05, 0.95)
        button:SetBackdropBorderColor(0.20, 0.18, 0.15, 0.95)
        button.text:SetTextColor(0.42, 0.40, 0.36)
        return
    end
    if button.selected then
        if button.actionStyle == "raid" then
            button:SetBackdropColor(0.42, 0.028, 0.020, 0.99)
            button:SetBackdropBorderColor(1.0, 0.28, 0.18, 1)
            button.text:SetTextColor(1.0, 0.76, 0.52)
        else
            button:SetBackdropColor(0.34, 0.18, 0.025, 0.98)
            button:SetBackdropBorderColor(1.0, 0.72, 0.24, 1)
            button.text:SetTextColor(1.0, 0.84, 0.36)
        end
    elseif button.hovered then
        if button.actionStyle == "confirm" then
            button:SetBackdropColor(0.06, 0.28, 0.10, 0.98)
            button:SetBackdropBorderColor(0.35, 0.95, 0.46, 1)
            button.text:SetTextColor(0.72, 1.0, 0.75)
        elseif button.actionStyle == "utility" then
            button:SetBackdropColor(0.05, 0.16, 0.30, 0.98)
            button:SetBackdropBorderColor(0.38, 0.72, 1.0, 1)
            button.text:SetTextColor(0.72, 0.88, 1.0)
        elseif button.actionStyle == "primary" then
            button:SetBackdropColor(0.30, 0.18, 0.035, 0.99)
            button:SetBackdropBorderColor(1.0, 0.72, 0.24, 1)
            button.text:SetTextColor(1.0, 0.88, 0.48)
        else
            button:SetBackdropColor(0.30, 0.055, 0.035, 0.98)
            button:SetBackdropBorderColor(0.90, 0.58, 0.18, 1)
            button.text:SetTextColor(1.0, 0.86, 0.42)
        end
    elseif button.actionStyle == "confirm" then
        button:SetBackdropColor(0.025, 0.17, 0.055, 0.98)
        button:SetBackdropBorderColor(0.22, 0.64, 0.30, 1)
        button.text:SetTextColor(0.55, 0.95, 0.62)
    elseif button.actionStyle == "utility" then
        button:SetBackdropColor(0.025, 0.085, 0.18, 0.98)
        button:SetBackdropBorderColor(0.25, 0.48, 0.76, 1)
        button.text:SetTextColor(0.60, 0.78, 1.0)
    elseif button.actionStyle == "primary" then
        button:SetBackdropColor(0.12, 0.075, 0.025, 0.99)
        button:SetBackdropBorderColor(0.62, 0.42, 0.16, 1)
        button.text:SetTextColor(1.0, 0.82, 0.30)
    else
        button:SetBackdropColor(0.20, 0.025, 0.02, 0.98)
        button:SetBackdropBorderColor(0.48, 0.30, 0.13, 1)
        button.text:SetTextColor(1.0, 0.78, 0.22)
    end
end

local function SetButtonSelected(button, selected)
    if not button then return end
    button.selected = selected and true or false
    ApplyButtonVisual(button)
end

local function SetButtonEnabled(button, enabled, reason)
    if not button then return end
    button.disabled = not enabled
    button.disabledReason = reason
    ApplyButtonVisual(button)
end

local function CreateButton(parent, name, text, x, y, width, height, handler)
    local button = CreateFrame("Button", name, parent)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetWidth(width)
    button:SetHeight(height)
    CreateBackdrop(button, 3)

    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.text:SetText(text or "")
    button.labelText = text or ""
    button.selected = false
    button.hovered = false
    button.disabled = false
    button.handler = handler

    button:SetScript("OnEnter", function()
        if this.disabled then
            if this.disabledReason and OTLGM_DB and OTLGM_DB.settings.showHelp then
                GameTooltip:SetOwner(this, "ANCHOR_LEFT")
                GameTooltip:AddLine("Unavailable", 1, 0.70, 0.25)
                GameTooltip:AddLine(this.disabledReason, 1, 1, 1, true)
                GameTooltip:Show()
            end
            return
        end
        this.hovered = true
        ApplyButtonVisual(this)
    end)
    button:SetScript("OnLeave", function()
        this.hovered = false
        ApplyButtonVisual(this)
        GameTooltip:Hide()
    end)
    button:SetScript("OnClick", function()
        if this.disabled then
            if this.disabledReason then OTLGM:Notify("Action Unavailable", this.disabledReason) end
            return
        end
        if this.handler then this.handler() end
    end)
    ApplyButtonVisual(button)
    return button
end

local function SetButtonText(button, text)
    if not button then return end
    button.labelText = text or ""
    button.text:SetText(text or "")
end

local function AddButtonIcon(button, texturePath, size, leftAlignText)
    if not button or not texturePath then return end
    if not button.iconTexture then
        button.iconTexture = button:CreateTexture(nil, "OVERLAY")
        button.iconTexture:SetPoint("LEFT", button, "LEFT", 8, 0)
    end
    button.iconTexture:SetTexture(texturePath)
    button.iconTexture:SetWidth(size or 16)
    button.iconTexture:SetHeight(size or 16)
    button.iconTexture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.iconTexture:Show()
    if leftAlignText then
        button.text:ClearAllPoints()
        button.text:SetPoint("LEFT", button, "LEFT", 30, 0)
        button.text:SetWidth((button:GetWidth() or 0) - 36)
        button.text:SetJustifyH("LEFT")
    end
end

local function SetButtonActionStyle(button, style)
    if not button then return end
    button.actionStyle = style
    ApplyButtonVisual(button)
end

local function GetRankKindColor(kind)
    if kind == "Restricted" then return 0.86, 0.22, 0.18 end
    if kind == "Visitor" then return 0.46, 0.78, 0.26 end
    if kind == "Social" then return 0.25, 0.58, 0.98 end
    if kind == "Raiding" then return 0.68, 0.34, 0.94 end
    if kind == "Leadership" then return 0.98, 0.53, 0.12 end
    return 0.72, 0.72, 0.72
end

local function RankInfoMatches(rankInfo, currentRank)
    if not rankInfo or not currentRank or currentRank == "" then return false end
    local lowered = string.lower(currentRank)
    if string.find(lowered, string.lower(rankInfo.name or ""), 1, true) then return true end
    local i
    for i = 1, table.getn(rankInfo.aliases or {}) do
        if string.find(lowered, string.lower(rankInfo.aliases[i] or ""), 1, true) then return true end
    end
    return false
end

local function CreatePage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -14)
    page:SetWidth(PAGE_WIDTH)
    page:SetHeight(PAGE_HEIGHT)
    page:Hide()
    return page
end

local function CreateCard(parent, x, y, width, height, label)
    local card = CreateFrame("Frame", nil, parent)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    card:SetWidth(width)
    card:SetHeight(height)
    CreateBackdrop(card, 5)
    card:SetBackdropColor(0.055, 0.045, 0.028, 0.98)
    card:SetBackdropBorderColor(0.38, 0.27, 0.13, 1)
    card.label = CreateText(card, "GameFontNormalSmall", label, 10, -9, width - 20, "LEFT")
    card.value = CreateText(card, "GameFontNormalLarge", "0", 10, -31, width - 20, "LEFT")
    card.sub = CreateText(card, "GameFontNormalSmall", "", 10, -54, width - 20, "LEFT")
    card.sub:SetTextColor(0.58, 0.58, 0.58)
    return card
end

local function CreateClickableCard(parent, x, y, width, height, title, body, handler)
    local card = CreateButton(parent, nil, "", x, y, width, height, handler)
    card.text:Hide()
    card.title = CreateText(card, "GameFontNormal", title, 12, -12, width - 24, "LEFT")
    card.body = CreateWrappedText(card, "GameFontNormalSmall", body, 12, -38, width - 24, height - 48)
    card.body:SetTextColor(0.80, 0.80, 0.80)
    return card
end

local function CreateCheck(parent, name, label, x, y, onclick)
    local check = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    check:SetWidth(24)
    check:SetHeight(24)
    check:SetScript("OnClick", onclick)
    check.label = CreateText(parent, "GameFontNormal", label, x + 28, y - 3, 330, "LEFT")
    return check
end

local function CreateSlider(parent, name, x, y, height, onValueChanged)
    local slider = CreateFrame("Slider", name, parent)
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetWidth(16)
    slider:SetHeight(height)
    slider:SetOrientation("VERTICAL")
    slider:SetMinMaxValues(0, 0)
    slider:SetValueStep(1)

    local track = CreateSolidTexture(slider, "BACKGROUND", 0.07, 0.055, 0.035, 0.95)
    track:SetPoint("TOPLEFT", slider, "TOPLEFT", 5, 0)
    track:SetPoint("BOTTOMRIGHT", slider, "BOTTOMRIGHT", -5, 0)

    local border = CreateFrame("Frame", nil, slider)
    border:SetAllPoints(slider)
    CreateBackdrop(border, 3)
    border:SetBackdropColor(0, 0, 0, 0)
    border:SetBackdropBorderColor(0.38, 0.28, 0.13, 0.90)
    border:EnableMouse(false)

    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Vertical")
    local thumb = slider:GetThumbTexture()
    if thumb then thumb:SetWidth(16) thumb:SetHeight(24) end
    slider:SetValue(0)
    slider:SetScript("OnValueChanged", onValueChanged)
    return slider
end

local function CreateEditBox(parent, name, x, y, width, height, multiline)
    local edit = CreateFrame("EditBox", name, parent)
    edit:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    edit:SetWidth(width)
    edit:SetHeight(height)
    edit:SetAutoFocus(false)
    edit:SetFontObject("GameFontHighlightSmall")
    edit:SetTextInsets(8, 8, 7, 7)
    if multiline then edit:SetMultiLine(true) end
    CreateBackdrop(edit, 4)
    edit:SetBackdropColor(0.018, 0.018, 0.018, 0.98)
    edit:SetBackdropBorderColor(0.38, 0.30, 0.18, 1)
    edit:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    return edit
end

local function AttachMouseWheel(frame, callback)
    frame:EnableMouseWheel(1)
    frame:SetScript("OnMouseWheel", function() callback(arg1 or 0) end)
end

local function CreateHelpButton(parent, title, body, x)
    local button = CreateButton(parent, nil, "?", x or 724, -1, 26, 24, function() end)
    button:SetScript("OnEnter", function()
        if not OTLGM_DB or not OTLGM_DB.settings.showHelp then return end
        this.hovered = true
        ApplyButtonVisual(this)
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:AddLine(title or "Help", 1, 0.82, 0.35)
        GameTooltip:AddLine(body or "", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        this.hovered = false
        ApplyButtonVisual(this)
        GameTooltip:Hide()
    end)
    return button
end

local function CreateSortHeaderButton(parent, key, label, x, width)
    local button = CreateFrame("Button", nil, parent)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, 0)
    button:SetWidth(width)
    button:SetHeight(22)
    button.sortKey = key
    button.baseLabel = label
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.text:SetPoint("LEFT", button, "LEFT", 0, 0)
    button.text:SetJustifyH("LEFT")
    button.text:SetText(label)
    button:SetScript("OnClick", function() OTLGM:SetRosterSort(this.sortKey) end)
    button:SetScript("OnEnter", function()
        this.text:SetTextColor(1, 0.88, 0.42)
        if OTLGM_DB.settings.showHelp then
            GameTooltip:SetOwner(this, "ANCHOR_TOP")
            GameTooltip:AddLine("Sort by " .. string.lower(this.baseLabel), 1, 0.82, 0.35)
            GameTooltip:AddLine("Click again to reverse the order.", 0.82, 0.82, 0.82, true)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function()
        this.text:SetTextColor(1, 0.82, 0)
        GameTooltip:Hide()
    end)
    return button
end

local function SetEditVisual(edit, editable)
    edit.readOnly = not editable
    if editable then
        edit:SetTextColor(1.0, 1.0, 1.0)
        edit:SetBackdropBorderColor(0.52, 0.38, 0.17, 1)
        edit:EnableMouse(true)
    else
        edit:SetTextColor(0.66, 0.66, 0.66)
        edit:SetBackdropBorderColor(0.24, 0.22, 0.19, 1)
    end
end

local function ApplyLeadershipIcon(texture, member, online)
    if not texture then return end
    local iconPath = OTLGM:GetMemberBadge(member)
    if iconPath then
        texture:SetTexture(iconPath)
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        if online then texture:SetVertexColor(1, 1, 1) else texture:SetVertexColor(0.48, 0.48, 0.48) end
        texture:Show()
    else
        texture:Hide()
    end
end

local function ExtractFirstHyperlink(text)
    text = text or ""
    local _, _, link = string.find(text, "|H([^|]+)|h")
    local _, _, display = string.find(text, "(|H[^|]+|h%[[^%]]+%]|h)")
    return link, display
end

local function StripColorCodes(text)
    text = text or ""
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = string.gsub(text, "|r", "")
    return text
end

local function GetCompatibleChatFont()
    local source = ChatFrameEditBox or DEFAULT_CHAT_FRAME or ChatFrame1
    if source and source.GetFont then
        local fontPath, fontSize, fontFlags = source:GetFont()
        if fontPath and fontPath ~= "" then return fontPath, fontSize or 12, fontFlags end
    end
    if ChatFontNormal and ChatFontNormal.GetFont then
        local fontPath, fontSize, fontFlags = ChatFontNormal:GetFont()
        if fontPath and fontPath ~= "" then return fontPath, fontSize or 12, fontFlags end
    end
    return "Fonts\\ARIALN.TTF", 12, nil
end

local function ApplyCompatibleChatFont(frame, sizeOffset)
    if not frame then return end
    local fontPath, fontSize, fontFlags = GetCompatibleChatFont()
    fontSize = math.max(10, (tonumber(fontSize) or 12) + (tonumber(sizeOffset) or 0))
    if frame.SetFont then
        local ok = pcall(frame.SetFont, frame, fontPath, fontSize, fontFlags)
        if ok then return end
    end
    if frame.SetFontObject and ChatFontNormal then
        pcall(frame.SetFontObject, frame, ChatFontNormal)
    end
end

local function FormatShortDate(timestamp)
    if not timestamp then return "Unknown" end
    return date("%d/%m/%Y", timestamp)
end

local function RegisterSpecialFrame(frameName)
    if not UISpecialFrames or not frameName then return end
    local i
    for i = 1, table.getn(UISpecialFrames) do
        if UISpecialFrames[i] == frameName then return end
    end
    table.insert(UISpecialFrames, frameName)
end

function OTLGM:BuildUI()
    if self.ui.main then return end
    self:EnsureDB()

    local frame = CreateFrame("Frame", "OTLGM_MainFrame", UIParent)
    frame:SetWidth(1000)
    frame:SetHeight(710)
    frame:SetPoint("CENTER", UIParent, "CENTER", OTLGM_DB.settings.windowX or 0, OTLGM_DB.settings.windowY or 10)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        if not OTLGM_DB.settings.windowLocked then this:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        local frameX, frameY = this:GetCenter()
        local parentX, parentY = UIParent:GetCenter()
        if frameX and parentX then
            OTLGM_DB.settings.windowX = frameX - parentX
            OTLGM_DB.settings.windowY = frameY - parentY
        end
    end)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetScale(OTLGM_DB.settings.uiScale or 1)
    frame:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })

    local fullBackground = CreateSolidTexture(frame, "BACKGROUND", 0.012, 0.011, 0.009, 0.99)
    fullBackground:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12)
    fullBackground:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)
    local innerShade = CreateSolidTexture(frame, "BORDER", 0.055, 0.035, 0.018, 0.30)
    innerShade:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -16)
    innerShade:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 16)
    frame:Hide()
    self.ui.main = frame
    RegisterSpecialFrame("OTLGM_MainFrame")
    frame:SetScript("OnHide", function()
        if OTLGM and OTLGM.SaveGuildChatDraft and OTLGM.GetGuildChatChannel then OTLGM:SaveGuildChatDraft(OTLGM:GetGuildChatChannel()) end
        if OTLGM and OTLGM.ClearGuildChatNewMarkers then OTLGM:ClearGuildChatNewMarkers() end
    end)

    local headerLine = CreateSolidTexture(frame, "ARTWORK", 0.64, 0.39, 0.10, 0.80)
    headerLine:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -74)
    headerLine:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -74)
    headerLine:SetHeight(1)

    local iconFrame = CreateFrame("Frame", nil, frame)
    iconFrame:SetWidth(46)
    iconFrame:SetHeight(46)
    iconFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -15)
    CreateBackdrop(iconFrame, 4)
    iconFrame:SetBackdropColor(0.04, 0.025, 0.01, 1)
    iconFrame:SetBackdropBorderColor(0.80, 0.52, 0.16, 1)
    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\Ability_Hunter_Pet_Cat")
    icon:SetWidth(34)
    icon:SetHeight(34)
    icon:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -11)
    title:SetText(self.colors.gold .. "< ORDER OF THE LION >" .. self.colors.reset)
    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -2)
    subtitle:SetText(self.colors.white .. "OCTOWOW" .. self.colors.reset .. self.colors.grey .. "  -  OFFICIAL GUILD COMPANION" .. self.colors.reset)
    local motto = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    motto:SetPoint("TOP", subtitle, "BOTTOM", 0, -2)
    motto:SetText(self.colors.gold .. "Together We Grow Stronger" .. self.colors.reset)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)

    local sidebar = CreateFrame("Frame", nil, frame)
    sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -84)
    sidebar:SetWidth(166)
    sidebar:SetHeight(570)
    CreateBackdrop(sidebar, 5)
    sidebar:SetBackdropColor(0.024, 0.021, 0.017, 0.995)
    sidebar:SetBackdropBorderColor(0.40, 0.29, 0.14, 1)
    self.ui.sidebar = sidebar

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 194, -84)
    content:SetWidth(788)
    content:SetHeight(570)
    CreateBackdrop(content, 5)
    content:SetBackdropColor(0.022, 0.020, 0.017, 0.995)
    content:SetBackdropBorderColor(0.40, 0.29, 0.14, 1)
    self.ui.content = content

    self.ui.generalLabel = CreateText(sidebar, "GameFontNormalSmall", "MAIN", 12, -14, 142, "LEFT")
    self.ui.generalLabel:SetTextColor(0.82, 0.70, 0.42)

    self.ui.memberDivider = CreateSolidTexture(sidebar, "ARTWORK", 0.42, 0.29, 0.11, 0.75)
    self.ui.memberDivider:SetHeight(1)
    self.ui.memberDivider:SetWidth(130)
    self.ui.memberDivider:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 12, -168)
    self.ui.memberLabel = CreateText(sidebar, "GameFontNormalSmall", "MEMBER TOOLS", 12, -182, 142, "LEFT")
    self.ui.memberLabel:SetTextColor(0.66, 0.62, 0.54)

    self.ui.officerDivider = CreateSolidTexture(sidebar, "ARTWORK", 0.42, 0.29, 0.11, 0.75)
    self.ui.officerDivider:SetHeight(1)
    self.ui.officerDivider:SetWidth(130)
    self.ui.officerDivider:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 12, -270)
    self.ui.officerLabel = CreateText(sidebar, "GameFontNormalSmall", "OFFICER TOOLS", 12, -284, 142, "LEFT")
    self.ui.officerLabel:SetTextColor(0.66, 0.62, 0.54)

    self.ui.navButtons = {}
    local i
    for i = 1, table.getn(NAV_DEFS) do
        local definition = NAV_DEFS[i]
        local capturedKey = definition.key
        local button = CreateButton(sidebar, nil, definition.label, 12, -12, 142, 30, function()
            OTLGM:ShowPage(capturedKey)
        end)
        button.pageKey = definition.key
        button.baseLabel = definition.label
        button.navSection = definition.section
        button.officerOnly = definition.officer and true or false
        AddButtonIcon(button, NAV_ICONS[definition.key], 16, true)
        if definition.key == "pve" then
            button:SetHeight(36)
            SetButtonActionStyle(button, "raid")
        elseif definition.section == "primary" then
            button:SetHeight(36)
            SetButtonActionStyle(button, "primary")
        elseif definition.section == "utility" then
            SetButtonActionStyle(button, "utility")
        end
        self.ui.navButtons[definition.key] = button
    end

    self.ui.modeText = CreateText(sidebar, "GameFontNormalSmall", "", 12, -440, 142, "CENTER")
    self.ui.modeText:SetTextColor(0.66, 0.62, 0.54)
    self.ui.versionText = CreateText(sidebar, "GameFontNormalSmall", "Order of the Lion GM v" .. self.version, 12, -456, 142, "CENTER")
    self.ui.versionText:SetTextColor(0.48, 0.45, 0.39)

    self.ui.addonUsersButton = CreateButton(sidebar, nil, "Addon users: checking", 12, -476, 142, 24, function()
        OTLGM:RequestAddonUserPing()
        OTLGM:RefreshAddonUsersIndicator()
    end)
    AddButtonIcon(self.ui.addonUsersButton, "Interface\\Icons\\INV_Misc_Rune_01", 14, true)
    self.ui.addonUsersButton:SetScript("OnEnter", function()
        this.hovered = true
        ApplyButtonVisual(this)
        OTLGM:ShowAddonUsersTooltip(this)
    end)
    self.ui.addonUsersButton:SetScript("OnLeave", function()
        this.hovered = false
        ApplyButtonVisual(this)
        GameTooltip:Hide()
    end)

    local scanButton = CreateButton(sidebar, nil, "Update Roster", 12, -536, 142, 30, function()
        OTLGM:RequestScan("MANUAL")
    end)
    self.ui.scanButton = scanButton
    AddButtonIcon(scanButton, "Interface\\Icons\\INV_Misc_Spyglass_03", 16, true)

    self.ui.pages = {}
    local key
    for i = 1, table.getn(NAV_DEFS) do
        key = NAV_DEFS[i].key
        self.ui.pages[key] = CreatePage(content)
    end

    self:BuildHomePage(self.ui.pages.home)
    self:BuildOverviewPage(self.ui.pages.overview)
    self:BuildGuildInfoPage(self.ui.pages.guildinfo)
    self:BuildRosterPage(self.ui.pages.roster)
    self:BuildActivityPage(self.ui.pages.activity)
    self:BuildGuildChatPage(self.ui.pages.guildchat)
    self:BuildPvePage(self.ui.pages.pve)
    self:BuildHistoryPage(self.ui.pages.history)
    self:BuildInactivePage(self.ui.pages.inactive)
    self:BuildRecruitmentPage(self.ui.pages.recruitment)
    self:BuildSettingsPage(self.ui.pages.settings)

    local statusBar = CreateFrame("Frame", nil, frame)
    statusBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 17)
    statusBar:SetWidth(964)
    statusBar:SetHeight(30)
    CreateBackdrop(statusBar, 3)
    statusBar:SetBackdropColor(0.018, 0.018, 0.018, 0.99)
    statusBar:SetBackdropBorderColor(0.35, 0.27, 0.15, 1)
    self.ui.status = CreateText(statusBar, "GameFontNormalSmall", "Ready", 9, -8, 940, "LEFT")

    self:BuildNoticeDialog()
    self:BuildCopyDialog()
    self:BuildImportDialog()
    self:BuildConfirmDialog()
    self:BuildFirstRunWizard()
    self:BuildModalOverlay152()
    self:BuildAnnouncementDialogs152()
    self:RegisterStandardModals152()

    self.ui.currentPage = OTLGM_DB.settings.openHome and "home" or (OTLGM_DB.settings.lastPage or "home")
    if not self.ui.pages[self.ui.currentPage] then self.ui.currentPage = "home" end
    self:RefreshNavigation()
    self:ShowPage(self.ui.currentPage)
    self:RefreshVisiblePage()

    if not OTLGM_DB.settings.firstRunComplete then self:OpenFirstRunWizard() end
end

function OTLGM:BuildNoticeDialog()
    local dialog = CreateFrame("Frame", "OTLGM_NoticeDialog", self.ui.main)
    dialog:SetWidth(430)
    dialog:SetHeight(205)
    dialog:SetPoint("CENTER", self.ui.main, "CENTER", 0, 20)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetFrameLevel(self.ui.main:GetFrameLevel() + 50)
    CreateBackdrop(dialog, 8)
    dialog:SetBackdropColor(0.018, 0.015, 0.012, 1)
    dialog:SetBackdropBorderColor(0.86, 0.56, 0.18, 1)
    dialog.title = CreateText(dialog, "GameFontNormalLarge", "Order of the Lion", 18, -18, 394, "CENTER")
    dialog.body = CreateWrappedText(dialog, "GameFontHighlight", "", 22, -58, 386, 88)
    CreateButton(dialog, nil, "Close", 150, -158, 130, 30, function() OTLGM.ui.noticeDialog:Hide() end)
    dialog:Hide()
    self.ui.noticeDialog = dialog
end

function OTLGM:ShowNotice(title, body)
    if not self.ui.noticeDialog then return end
    if self.ui.main and not self.ui.main:IsVisible() then self.ui.main:Show() end
    self.ui.noticeDialog.title:SetText(self.colors.gold .. (title or "Order of the Lion") .. self.colors.reset)
    self.ui.noticeDialog.body:SetText(body or "")
    self:ShowModal152(self.ui.noticeDialog)
end

function OTLGM:BuildCopyDialog()
    local dialog = CreateFrame("Frame", "OTLGM_CopyDialog", self.ui.main)
    dialog:SetWidth(650)
    dialog:SetHeight(430)
    dialog:SetPoint("CENTER", self.ui.main, "CENTER", 0, 5)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetFrameLevel(self.ui.main:GetFrameLevel() + 55)
    CreateBackdrop(dialog, 8)
    dialog:SetBackdropColor(0.018, 0.015, 0.012, 1)
    dialog:SetBackdropBorderColor(0.86, 0.56, 0.18, 1)
    dialog.title = CreateText(dialog, "GameFontNormalLarge", "Copy Text", 18, -16, 614, "CENTER")
    dialog.edit = CreateEditBox(dialog, "OTLGM_CopyEdit", 18, -54, 614, 312, true)
    dialog.edit:SetMaxLetters(200000)
    CreateText(dialog, "GameFontNormalSmall", "The text is selected automatically. Press Ctrl+C.", 18, -374, 440, "LEFT")
    CreateButton(dialog, nil, "Select All", 470, -370, 76, 30, function()
        OTLGM.ui.copyDialog.edit:SetFocus()
        OTLGM.ui.copyDialog.edit:HighlightText()
    end)
    CreateButton(dialog, nil, "Close", 552, -370, 80, 30, function() OTLGM.ui.copyDialog:Hide() end)
    dialog:Hide()
    self.ui.copyDialog = dialog
end

function OTLGM:ShowCopyDialog(title, text)
    if not self.ui.copyDialog then return end
    if self.ui.main and not self.ui.main:IsVisible() then self.ui.main:Show() end
    self.ui.copyDialog.title:SetText(self.colors.gold .. (title or "Copy Text") .. self.colors.reset)
    self.ui.copyDialog.edit:SetText(text or "")
    self:ShowModal152(self.ui.copyDialog)
    self.ui.copyDialog.edit:SetFocus()
    self.ui.copyDialog.edit:HighlightText()
end

function OTLGM:BuildImportDialog()
    local dialog = CreateFrame("Frame", "OTLGM_ImportDialog", self.ui.main)
    dialog:SetWidth(650)
    dialog:SetHeight(450)
    dialog:SetPoint("CENTER", self.ui.main, "CENTER", 0, 5)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetFrameLevel(self.ui.main:GetFrameLevel() + 56)
    CreateBackdrop(dialog, 8)
    dialog:SetBackdropColor(0.018, 0.015, 0.012, 1)
    dialog:SetBackdropBorderColor(0.86, 0.56, 0.18, 1)
    CreateText(dialog, "GameFontNormalLarge", "Import Addon Backup", 18, -16, 614, "CENTER")
    CreateText(dialog, "GameFontNormalSmall", "Paste an OTLGM_BACKUP_V1 string below. Imported history replaces the current local history.", 18, -46, 614, "LEFT")
    dialog.edit = CreateEditBox(dialog, "OTLGM_ImportEdit", 18, -70, 614, 310, true)
    dialog.edit:SetMaxLetters(200000)
    CreateButton(dialog, nil, "Import", 438, -392, 92, 30, function()
        local ok, message = OTLGM:ImportBackup(OTLGM.ui.importDialog.edit:GetText())
        if ok then
            OTLGM.ui.importDialog:Hide()
            OTLGM:ShowNotice("Import Complete", message)
        else
            OTLGM:ShowNotice("Import Failed", message)
        end
    end)
    CreateButton(dialog, nil, "Cancel", 540, -392, 92, 30, function() OTLGM.ui.importDialog:Hide() end)
    dialog:Hide()
    self.ui.importDialog = dialog
end

function OTLGM:BuildConfirmDialog()
    local dialog = CreateFrame("Frame", "OTLGM_ConfirmDialog", self.ui.main)
    dialog:SetWidth(510)
    dialog:SetHeight(270)
    dialog:SetPoint("CENTER", self.ui.main, "CENTER", 0, 10)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetFrameLevel(self.ui.main:GetFrameLevel() + 58)
    CreateBackdrop(dialog, 8)
    dialog:SetBackdropColor(0.018, 0.015, 0.012, 1)
    dialog:SetBackdropBorderColor(0.86, 0.56, 0.18, 1)
    dialog.title = CreateText(dialog, "GameFontNormalLarge", "Confirm", 18, -16, 474, "CENTER")
    dialog.body = CreateWrappedText(dialog, "GameFontHighlight", "", 22, -56, 466, 145)
    dialog.confirm = CreateButton(dialog, nil, "Confirm", 260, -220, 108, 30, function()
        local handler = OTLGM.ui.confirmDialog.confirmHandler
        OTLGM.ui.confirmDialog:Hide()
        if handler then handler() end
    end)
    CreateButton(dialog, nil, "Cancel", 380, -220, 108, 30, function() OTLGM.ui.confirmDialog:Hide() end)
    dialog:Hide()
    self.ui.confirmDialog = dialog
end

function OTLGM:ShowConfirm(title, body, confirmLabel, handler)
    if self.ui.main and not self.ui.main:IsVisible() then self.ui.main:Show() end
    local dialog = self.ui.confirmDialog
    if not dialog then return end
    dialog.title:SetText(self.colors.gold .. (title or "Confirm") .. self.colors.reset)
    dialog.body:SetText(body or "")
    SetButtonText(dialog.confirm, confirmLabel or "Confirm")
    dialog.confirmHandler = handler
    self:ShowModal152(dialog)
end

function OTLGM:BuildFirstRunWizard()
    local wizard = CreateFrame("Frame", "OTLGM_FirstRunWizard", self.ui.main)
    wizard:SetWidth(610)
    wizard:SetHeight(420)
    wizard:SetPoint("CENTER", self.ui.main, "CENTER", 0, 5)
    wizard:SetFrameStrata("DIALOG")
    wizard:SetFrameLevel(self.ui.main:GetFrameLevel() + 60)
    CreateBackdrop(wizard, 8)
    wizard:SetBackdropColor(0.016, 0.014, 0.011, 1)
    wizard:SetBackdropBorderColor(0.95, 0.64, 0.20, 1)
    wizard.title = CreateText(wizard, "GameFontNormalLarge", "", 24, -22, 562, "CENTER")
    wizard.step = CreateText(wizard, "GameFontNormalSmall", "", 24, -52, 562, "CENTER")
    wizard.body = CreateWrappedText(wizard, "GameFontHighlight", "", 42, -92, 526, 184)
    wizard.intervalButtons = {}
    local intervals = { 600, 1200, 1800, 3600 }
    local labels = { "10 min", "20 min", "30 min", "60 min" }
    local i
    for i = 1, 4 do
        local seconds = intervals[i]
        local button = CreateButton(wizard, nil, labels[i], 55 + ((i - 1) * 126), -274, 112, 30, function()
            OTLGM_DB.settings.autoScan = true
            OTLGM_DB.settings.scanInterval = seconds
            OTLGM:RefreshWizard()
        end)
        button.interval = seconds
        button:Hide()
        wizard.intervalButtons[i] = button
    end
    wizard.back = CreateButton(wizard, nil, "Back", 42, -362, 110, 30, function()
        OTLGM.ui.firstRunWizard.currentStep = math.max(1, (OTLGM.ui.firstRunWizard.currentStep or 1) - 1)
        OTLGM:RefreshWizard()
    end)
    wizard.next = CreateButton(wizard, nil, "Next", 458, -362, 110, 30, function()
        local current = OTLGM.ui.firstRunWizard.currentStep or 1
        if current < 4 then
            OTLGM.ui.firstRunWizard.currentStep = current + 1
            OTLGM:RefreshWizard()
        else
            OTLGM_DB.settings.firstRunComplete = true
            OTLGM.ui.firstRunWizard:Hide()
            OTLGM:RefreshNavigation()
            OTLGM:RequestScan("MANUAL")
        end
    end)
    wizard:Hide()
    self.ui.firstRunWizard = wizard
end

function OTLGM:OpenFirstRunWizard()
    if self.ui.main and not self.ui.main:IsVisible() then self.ui.main:Show() end
    self.ui.firstRunWizard.currentStep = 1
    self:ShowModal152(self.ui.firstRunWizard)
    self:RefreshWizard()
end

function OTLGM:RefreshWizard()
    local wizard = self.ui.firstRunWizard
    if not wizard then return end
    local step = wizard.currentStep or 1
    wizard.step:SetText("Step " .. tostring(step) .. " of 4")
    local i
    for i = 1, table.getn(wizard.intervalButtons) do wizard.intervalButtons[i]:Hide() end

    if step == 1 then
        wizard.title:SetText(self.colors.gold .. "WELCOME TO ORDER OF THE LION" .. self.colors.reset)
        wizard.body:SetText("This addon is a guild companion for Order of the Lion on OctoWoW.\n\nIt stores local roster snapshots, guild history, unread changes, activity statistics, recruitment messages and interface settings. The first successful scan creates a safe baseline and does not mark every existing member as newly joined.")
    elseif step == 2 then
        wizard.title:SetText(self.colors.gold .. "ROSTER UPDATE INTERVAL" .. self.colors.reset)
        wizard.body:SetText("Choose how often the addon should refresh its local guild database. The recommended default is 20 minutes.\n\nOnly successful manual or timed database updates write one short line to normal chat. Joins, leaves, rank changes and other events remain inside the addon.")
        for i = 1, table.getn(wizard.intervalButtons) do
            wizard.intervalButtons[i]:Show()
            SetButtonSelected(wizard.intervalButtons[i], OTLGM_DB.settings.scanInterval == wizard.intervalButtons[i].interval)
        end
    elseif step == 3 then
        wizard.title:SetText(self.colors.gold .. "MEMBER AND OFFICER MODES" .. self.colors.reset)
        wizard.body:SetText("The interface automatically checks the permissions exposed by your guild rank.\n\nMember Mode keeps the addon clean and shows Home, Guild Chat, Roster and Activity. Guild Information opens from the first card on Home, while Settings stays with the service controls at the bottom.\n\nOfficer Mode adds Overview, Recruitment, History and Inactive review. Guild actions still use the server's real permissions.")
    else
        wizard.title:SetText(self.colors.gold .. "READY TO BEGIN" .. self.colors.reset)
        wizard.body:SetText("Professions are detected from guild notes because the Vanilla roster API does not reveal every guildmate's profession. Detected professions are marked as unconfirmed.\n\nThe addon protects against incomplete roster responses and keeps three valid backup snapshots. Press Finish to create or update the first safe baseline.")
    end
    SetButtonEnabled(wizard.back, step > 1)
    SetButtonText(wizard.next, step == 4 and "Finish" or "Next")
end

function OTLGM:RefreshAddonUsersIndicator()
    if not self.ui or not self.ui.addonUsersButton then return end
    local count, latest, online = self:GetDetectedAddonUsers(86400)
    SetButtonText(self.ui.addonUsersButton, "Addon users: " .. tostring(online) .. " online")
    SetButtonActionStyle(self.ui.addonUsersButton, "utility")
end

function OTLGM:ShowAddonUsersTooltip(owner)
    if not owner then return end
    local list = self:GetDetectedAddonUserList(86400)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Order of the Lion addon users", 1, 0.82, 0.35)
    GameTooltip:AddLine("Other guildmates detected during the last 24 hours.", 0.80, 0.80, 0.80, true)
    GameTooltip:AddLine("Offline users cannot be detected until their addon sends a message.", 0.58, 0.58, 0.58, true)
    GameTooltip:AddLine(" ")
    if table.getn(list) == 0 then
        GameTooltip:AddLine("No other users detected yet.", 0.70, 0.70, 0.70)
    else
        local i, info, status, classColor
        for i = 1, math.min(18, table.getn(list)) do
            info = list[i]
            status = info.online and "Online" or ("Seen " .. self:FormatElapsedShort(self:Now() - (info.ts or self:Now())) .. " ago")
            classColor = info.class and info.class ~= "" and self:GetClassColor(info.class) or self.colors.white
            GameTooltip:AddDoubleLine(classColor .. (info.name or "Unknown") .. self.colors.reset .. (info.version and info.version ~= "Detected" and ("  v" .. tostring(info.version)) or ""), status, 1, 1, 1, info.online and 0.35 or 0.60, info.online and 1.0 or 0.60, info.online and 0.35 or 0.60)
        end
        if table.getn(list) > 18 then GameTooltip:AddLine("...and " .. tostring(table.getn(list) - 18) .. " more", 0.65, 0.65, 0.65) end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Click to ping online addon users now.", 0.45, 0.75, 1.0)
    GameTooltip:Show()
end

function OTLGM:SetStatus(text)
    if self.ui.status then self.ui.status:SetText(text or "") end
end

function OTLGM:RefreshGuildChatNavigationBadge()
    if not self.ui or not self.ui.navButtons then return end
    local chatButton = self.ui.navButtons.guildchat
    if not chatButton then return end
    local guildUnread = self:GetGuildChatUnread("GUILD")
    local officerUnread = self:IsOfficerMode() and self:GetGuildChatUnread("OFFICER") or 0
    local boardUnread = self.GetPveUnread and self:GetPveUnread("BOARD") or 0
    if guildUnread > 0 or officerUnread > 0 or boardUnread > 0 then
        local label = "Guild Chat"
        if guildUnread > 0 then label = label .. "  " .. self.colors.green .. "G" .. tostring(guildUnread > 99 and "99+" or guildUnread) .. self.colors.reset end
        if officerUnread > 0 then label = label .. " " .. self.colors.gold .. "O" .. tostring(officerUnread > 99 and "99+" or officerUnread) .. self.colors.reset end
        if boardUnread > 0 then label = label .. " " .. self.colors.blue .. "B" .. tostring(boardUnread > 99 and "99+" or boardUnread) .. self.colors.reset end
        SetButtonText(chatButton, label)
    else
        SetButtonText(chatButton, "Guild Chat")
    end
end

function OTLGM:RefreshPveNavigationBadge()
    if not self.ui or not self.ui.navButtons then return end
    local button = self.ui.navButtons.pve
    if not button then return end
    local unread = self.GetPveUnreadTotal and self:GetPveUnreadTotal() or 0
    local summary = self.GetPveSummary and self:GetPveSummary() or { requests = 0, raid = nil }
    local label = "PvE Hub"
    if unread > 0 then
        label = label .. "  " .. self.colors.gold .. tostring(unread > 99 and "99+" or unread) .. self.colors.reset
    elseif summary.raid then
        label = label .. "  " .. self.colors.green .. "!" .. self.colors.reset
    elseif (summary.requests or 0) > 0 then
        label = label .. "  " .. self.colors.blue .. tostring(summary.requests) .. self.colors.reset
    end
    SetButtonText(button, label)
end

function OTLGM:RefreshNavigation()
    if not self.ui.navButtons then return end
    local officer = self:IsOfficerMode()
    local key, button

    for key, button in pairs(self.ui.navButtons) do button:Hide() end

    if self.ui.generalLabel then self.ui.generalLabel:Show() end
    if self.ui.memberDivider then self.ui.memberDivider:Show() end
    if self.ui.memberLabel then self.ui.memberLabel:Show() end

    local homeButton = self.ui.navButtons.home
    local chatButton = self.ui.navButtons.guildchat
    if homeButton then
        homeButton:ClearAllPoints()
        homeButton:SetPoint("TOPLEFT", self.ui.sidebar, "TOPLEFT", 12, -36)
        homeButton:SetHeight(36)
        homeButton:Show()
    end
    if chatButton then
        chatButton:ClearAllPoints()
        chatButton:SetPoint("TOPLEFT", self.ui.sidebar, "TOPLEFT", 12, -78)
        chatButton:SetHeight(36)
        chatButton:Show()
    end

    local pveButton = self.ui.navButtons.pve
    local rosterButton = self.ui.navButtons.roster
    local activityButton = self.ui.navButtons.activity
    if pveButton then
        pveButton:ClearAllPoints()
        pveButton:SetPoint("TOPLEFT", self.ui.sidebar, "TOPLEFT", 12, -120)
        pveButton:SetHeight(36)
        pveButton:Show()
    end
    if rosterButton then
        rosterButton:ClearAllPoints()
        rosterButton:SetPoint("TOPLEFT", self.ui.sidebar, "TOPLEFT", 12, -204)
        rosterButton:SetHeight(30)
        rosterButton:Show()
    end
    if activityButton then
        activityButton:ClearAllPoints()
        activityButton:SetPoint("TOPLEFT", self.ui.sidebar, "TOPLEFT", 12, -240)
        activityButton:SetHeight(30)
        activityButton:Show()
    end

    if self.ui.officerDivider and self.ui.officerLabel then
        if officer then
            self.ui.officerDivider:Show()
            self.ui.officerLabel:Show()
        else
            self.ui.officerDivider:Hide()
            self.ui.officerLabel:Hide()
        end
    end

    if officer then
        local officerKeys = { "overview", "recruitment", "history", "inactive" }
        local officerY = -306
        local i
        for i = 1, table.getn(officerKeys) do
            button = self.ui.navButtons[officerKeys[i]]
            if button then
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", self.ui.sidebar, "TOPLEFT", 12, officerY)
                button:SetHeight(30)
                button:Show()
                officerY = officerY - 34
            end
        end
    end

    local settingsButton = self.ui.navButtons.settings
    if settingsButton then
        settingsButton:ClearAllPoints()
        settingsButton:SetPoint("TOPLEFT", self.ui.sidebar, "TOPLEFT", 12, -504)
        settingsButton:SetHeight(30)
        settingsButton:Show()
    end

    local unread = self:GetUnreadCount()
    local historyButton = self.ui.navButtons.history
    if historyButton then
        if unread > 0 then SetButtonText(historyButton, "History  (" .. tostring(unread > 99 and "99+" or unread) .. ")")
        else SetButtonText(historyButton, "History") end
    end

    self:RefreshGuildChatNavigationBadge()
    self:RefreshPveNavigationBadge()
    self.ui.modeText:SetText(officer and self.colors.gold .. "OFFICER MODE" .. self.colors.reset or self.colors.grey .. "MEMBER MODE" .. self.colors.reset)
    self.ui.versionText:SetText("Order of the Lion GM v" .. self.version)
    self:RefreshAddonUsersIndicator()

    if self.ui.currentPage and self.ui.navButtons[self.ui.currentPage] then
        local visibleSelection = self.ui.currentPage == "guildinfo" and "home" or self.ui.currentPage
        for key, button in pairs(self.ui.navButtons) do SetButtonSelected(button, key == visibleSelection) end
        if self.ui.navButtons[self.ui.currentPage].officerOnly and not officer then
            self.ui.currentPage = "home"
            if self.ui.pages and self.ui.pages.home then
                local pageKey, page
                for pageKey, page in pairs(self.ui.pages) do
                    if pageKey == "home" then page:Show() else page:Hide() end
                end
            end
        end
    end
end

function OTLGM:ShowPage(pageKey)
    if not self.ui.pages or not self.ui.pages[pageKey] then return end
    local definition
    local i
    for i = 1, table.getn(NAV_DEFS) do
        if NAV_DEFS[i].key == pageKey then definition = NAV_DEFS[i] break end
    end
    if definition and definition.officer and not self:IsOfficerMode() then
        self:Notify("Officer Page Unavailable", "This page is hidden in Member Mode because your current guild rank does not expose the required officer permissions.")
        pageKey = "home"
    end

    local key, page
    for key, page in pairs(self.ui.pages) do
        if key == pageKey then page:Show() else page:Hide() end
    end
    self.ui.currentPage = pageKey
    OTLGM_DB.settings.lastPage = pageKey

    local visibleSelection = pageKey == "guildinfo" and "home" or pageKey
    for key, page in pairs(self.ui.navButtons) do SetButtonSelected(page, key == visibleSelection) end
    if pageKey == "home" then self:RefreshHomePage() end
    if pageKey == "overview" then self:RefreshOverviewPage() end
    if pageKey == "guildinfo" then self:RefreshGuildInfoPage() end
    if pageKey == "roster" then self:RefreshRosterPage() end
    if pageKey == "activity" then self:RefreshActivityPage() end
    if pageKey == "guildchat" then self:RefreshGuildChatPage() end
    if pageKey == "pve" then
        if self.RequestPveSync then self:RequestPveSync(false) end
        self:RefreshPvePage()
    end
    if pageKey == "history" then self:RefreshHistoryPage() end
    if pageKey == "inactive" then self:RefreshInactivePage() end
    if pageKey == "recruitment" then self:RefreshRecruitmentPage() end
    if pageKey == "settings" then self:RefreshSettingsPage() end
    if pageKey == "roster" and self.ui.main and self.ui.main:IsVisible() then self:MaybeRefreshVisibleRoster() end
end

function OTLGM:RefreshVisiblePage()
    if not self.ui or not self.ui.currentPage then return end
    local pageKey = self.ui.currentPage
    if pageKey == "home" then self:RefreshHomePage() end
    if pageKey == "overview" then self:RefreshOverviewPage() end
    if pageKey == "guildinfo" then self:RefreshGuildInfoPage() end
    if pageKey == "roster" then self:RefreshRosterPage() end
    if pageKey == "activity" then self:RefreshActivityPage() end
    if pageKey == "guildchat" then self:RefreshGuildChatPage() end
    if pageKey == "pve" then
        if self.RequestPveSync then self:RequestPveSync(false) end
        self:RefreshPvePage()
    end
    if pageKey == "history" then self:RefreshHistoryPage() end
    if pageKey == "inactive" then self:RefreshInactivePage() end
    if pageKey == "recruitment" then self:RefreshRecruitmentPage() end
    if pageKey == "settings" then self:RefreshSettingsPage() end
end

function OTLGM:MaybeRefreshVisibleRoster()
    if not self.ui or not self.ui.main or not self.ui.main:IsVisible() then return end
    if self.ui.currentPage ~= "roster" then return end
    if self.pendingScan or self.confirmScanAt then return end
    local db = self:GetGuildDB()
    local now = self:Now()
    local dataAge = db and db.lastScan and (now - db.lastScan) or 999999
    local requestAge = self.lastRosterViewRequestAt and (now - self.lastRosterViewRequestAt) or 999999
    if dataAge >= 120 and requestAge >= 300 then
        self.lastRosterViewRequestAt = now
        self:RequestScan("VIEW")
    end
end

function OTLGM:ToggleUI()
    if not self.ui.main then self:BuildUI() end
    if not self.ui.main then return end
    if self.ui.main:IsVisible() then
        self.ui.main:Hide()
    else
        self.ui.main:Show()
        self:RefreshNavigation()
        self:RefreshVisiblePage()
        self:MaybeRefreshVisibleRoster()
        self:RequestAddonUserPing()
    end
end

function OTLGM:ShowCommunityReactorsTooltip152(owner, targetType, targetId, reaction, label)
    if not owner or not targetId then return end
    local names = self.GetCommunityReactors and self:GetCommunityReactors(targetType, targetId, reaction) or {}
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:AddLine(label or reaction or "Reaction", 1.0, 0.82, 0.35)
    if table.getn(names) == 0 then
        GameTooltip:AddLine("No reactions yet.", 0.65, 0.65, 0.65)
    else
        local i
        local maximum = math.min(12, table.getn(names))
        for i = 1, maximum do GameTooltip:AddLine(names[i], 1, 1, 1) end
        if table.getn(names) > maximum then GameTooltip:AddLine("...and " .. tostring(table.getn(names) - maximum) .. " more", 0.60, 0.60, 0.60) end
    end
    GameTooltip:Show()
end


local function GetLeadershipRoleInfo153(member)
    if not member then return "Leadership", "Interface\\Icons\\INV_Shield_06" end
    local iconPath, badgeLabel = OTLGM:GetMemberBadge(member)
    local rankLabel = member.rank and member.rank ~= "" and member.rank or badgeLabel or "Leadership"
    if not iconPath then
        local index = tonumber(member.rankIndex) or 99
        if index == 0 then iconPath = "Interface\\Icons\\INV_Crown_01"
        elseif index <= 2 then iconPath = "Interface\\Icons\\INV_Shield_06"
        else iconPath = "Interface\\Icons\\INV_Misc_GroupNeedMore" end
    end
    return rankLabel, iconPath
end

local function BreakLongTokens154(text, maximumToken)
    text = tostring(text or "")
    maximumToken = tonumber(maximumToken) or 44
    return string.gsub(text, "([^%s]+)", function(token)
        if string.len(token) <= maximumToken then return token end
        local parts = {}
        local at = 1
        while at <= string.len(token) do
            table.insert(parts, string.sub(token, at, at + maximumToken - 1))
            at = at + maximumToken
        end
        return table.concat(parts, " ")
    end)
end

local function HomeShort152(text, maximum)
    text = tostring(text or "")
    text = string.gsub(text, "\r\n", "\n")
    text = string.gsub(text, "\r", "\n")
    text = string.gsub(text, "\t", " ")
    text = string.gsub(text, "\n\n\n+", "\n\n")
    text = BreakLongTokens154(text, 42)
    if string.len(text) > maximum then return string.sub(text, 1, maximum - 3) .. "..." end
    return text
end

function OTLGM:BuildHomePage(page)
    CreateText(page, "GameFontNormalLarge", "Order of the Lion", 0, -2, 420, "LEFT")
    CreateHelpButton(page, "Home", "Leadership announcements, the next raid, online leadership and a small useful activity feed. Technical database counters are kept in Settings instead of the guild home page.")
    CreateText(page, "GameFontNormalSmall", "Guild announcements and the information that matters now.", 0, -28, 700, "LEFT")

    local announcements = CreateFrame("Frame", nil, page)
    announcements:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -56)
    announcements:SetWidth(450)
    announcements:SetHeight(460)
    CreateBackdrop(announcements, 5)
    announcements:SetBackdropColor(0.026, 0.023, 0.019, 0.995)
    announcements:SetBackdropBorderColor(0.48, 0.34, 0.15, 1)
    CreateText(announcements, "GameFontNormal", "LEADERSHIP ANNOUNCEMENTS", 12, -12, 260, "LEFT")
    self.ui.homeNewAnnouncementButton = CreateButton(announcements, nil, "New Announcement", 300, -8, 138, 28, function()
        OTLGM:OpenAnnouncementComposer152(nil)
    end)
    SetButtonActionStyle(self.ui.homeNewAnnouncementButton, "confirm")

    self.ui.homeAnnouncementRows = {}
    local i
    for i = 1, 3 do
        local capturedIndex = i
        local row = CreateFrame("Button", nil, announcements)
        row:SetPoint("TOPLEFT", announcements, "TOPLEFT", 10, -42 - ((i - 1) * 126))
        row:SetWidth(430)
        row:SetHeight(118)
        CreateBackdrop(row, 4)
        row:SetBackdropColor(0.035, 0.030, 0.023, 0.995)
        row:SetBackdropBorderColor(0.34, 0.28, 0.18, 1)
        row:SetScript("OnEnter", function()
            this:SetBackdropColor(0.075, 0.048, 0.020, 1)
            this:SetBackdropBorderColor(0.72, 0.48, 0.17, 1)
        end)
        row:SetScript("OnLeave", function()
            this:SetBackdropColor(0.035, 0.030, 0.023, 0.995)
            this:SetBackdropBorderColor(0.34, 0.28, 0.18, 1)
            GameTooltip:Hide()
        end)
        row:SetScript("OnClick", function()
            if this.recordId then OTLGM:OpenAnnouncementReader152(this.recordId) end
        end)
        row.newText = CreateText(row, "GameFontNormalSmall", "", 10, -9, 42, "LEFT")
        row.newText:SetTextColor(0.40, 1.0, 0.48)
        row.titleText = CreateText(row, "GameFontNormal", "", 52, -8, 258, "LEFT")
        row.metaText = CreateText(row, "GameFontNormalSmall", "", 312, -10, 108, "RIGHT")
        row.metaText:SetTextColor(0.58, 0.58, 0.58)
        row.bodyText = CreateWrappedText(row, "GameFontHighlightSmall", "", 10, -31, 410, 47)
        row.reactionButtons = {}
        local reactions = { {"LIKE", "Like"}, {"SEEN", "Seen"}, {"SUPPORT", "Support"} }
        local r
        for r = 1, table.getn(reactions) do
            local capturedReaction = reactions[r][1]
            local capturedLabel = reactions[r][2]
            local button = CreateButton(row, nil, capturedLabel, 10 + ((r - 1) * 102), -86, 94, 24, function()
                local target = OTLGM.ui.homeAnnouncementRows[capturedIndex]
                if target and target.recordId then OTLGM:ReactToAnnouncement152(target.recordId, capturedReaction) OTLGM:RefreshHomePage() end
            end)
            SetButtonActionStyle(button, capturedReaction == "SUPPORT" and "confirm" or "utility")
            button:SetScript("OnEnter", function()
                this.hovered = true
                ApplyButtonVisual(this)
                local target = OTLGM.ui.homeAnnouncementRows[capturedIndex]
                if target and target.recordId then OTLGM:ShowCommunityReactorsTooltip152(this, "ANN", target.recordId, capturedReaction, capturedLabel) end
            end)
            button:SetScript("OnLeave", function() this.hovered = false ApplyButtonVisual(this) GameTooltip:Hide() end)
            row.reactionButtons[capturedReaction] = button
        end
        row.openText = CreateText(row, "GameFontNormalSmall", "Read full post", 330, -94, 88, "RIGHT")
        row.openText:SetTextColor(0.54, 0.72, 0.94)
        row:Hide()
        self.ui.homeAnnouncementRows[i] = row
    end
    self.ui.homeNoAnnouncements = CreateWrappedText(announcements, "GameFontNormal", "No leadership announcements have been published yet.\n\nWhen leadership posts an update, it will appear here instead of being mixed with roster history.", 34, -138, 382, 110)
    self.ui.homeNoAnnouncements:SetTextColor(0.62, 0.62, 0.60)
    self.ui.homeAnnouncementArchiveButton = CreateButton(announcements, nil, "Open Announcement Archive", 10, -424, 210, 26, function()
        OTLGM:OpenAnnouncementArchive152()
    end)
    SetButtonActionStyle(self.ui.homeAnnouncementArchiveButton, "utility")
    self.ui.homeAnnouncementHint = CreateText(announcements, "GameFontNormalSmall", "Reactions belong to each individual post.", 230, -432, 208, "RIGHT")
    self.ui.homeAnnouncementHint:SetTextColor(0.48, 0.48, 0.46)
    self.ui.homeAnnouncementsPanel = announcements

    local raid = CreateFrame("Frame", nil, page)
    raid:SetPoint("TOPLEFT", page, "TOPLEFT", 460, -56)
    raid:SetWidth(258)
    raid:SetHeight(138)
    CreateBackdrop(raid, 5)
    raid:SetBackdropColor(0.035, 0.025, 0.020, 0.995)
    raid:SetBackdropBorderColor(0.52, 0.18, 0.12, 1)
    CreateText(raid, "GameFontNormalSmall", "NEXT RAID", 12, -9, 108, "LEFT")
    self.ui.homeRaidText = CreateWrappedText(raid, "GameFontHighlightSmall", "", 12, -27, 234, 39)
    CreateText(raid, "GameFontNormalSmall", "ACTIVE GROUPS", 12, -67, 108, "LEFT")
    self.ui.homeGroupsText155 = CreateWrappedText(raid, "GameFontHighlightSmall", "", 12, -84, 234, 20)
    self.ui.homeRaidButton = CreateButton(raid, nil, "Raid Alerts", 12, -108, 104, 22, function()
        OTLGM_DB.settings.pveSection = "RAIDS"
        OTLGM:ShowPage("pve")
    end)
    SetButtonActionStyle(self.ui.homeRaidButton, "raid")
    self.ui.homeGroupsButton155 = CreateButton(raid, nil, "Group Finder", 124, -108, 122, 22, function()
        OTLGM_DB.settings.pveSection = "GROUPS"
        OTLGM:ShowPage("pve")
    end)
    SetButtonActionStyle(self.ui.homeGroupsButton155, "utility")

    local leaders = CreateFrame("Frame", nil, page)
    leaders:SetPoint("TOPLEFT", page, "TOPLEFT", 460, -204)
    leaders:SetWidth(258)
    leaders:SetHeight(142)
    CreateBackdrop(leaders, 5)
    leaders:SetBackdropColor(0.026, 0.023, 0.019, 0.995)
    leaders:SetBackdropBorderColor(0.40, 0.31, 0.17, 1)
    CreateText(leaders, "GameFontNormalSmall", "LEADERSHIP ONLINE", 12, -10, 234, "LEFT")
    self.ui.homeLeaderButtons = {}
    for i = 1, 4 do
        local capturedIndex = i
        local button = CreateButton(leaders, nil, "", 12, -34 - ((i - 1) * 25), 234, 23, function()
            local target = OTLGM.ui.homeLeaderButtons[capturedIndex]
            if target and target.memberName then OTLGM:WhisperMember(target.memberName) end
        end)
        button.roleIcon = button:CreateTexture(nil, "OVERLAY")
        button.roleIcon:SetPoint("LEFT", button, "LEFT", 7, 0)
        button.roleIcon:SetWidth(17)
        button.roleIcon:SetHeight(17)
        button.roleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.text:SetJustifyH("LEFT")
        button.text:ClearAllPoints()
        button.text:SetPoint("LEFT", button, "LEFT", 30, 0)
        button.text:SetWidth(198)
        button:SetScript("OnEnter", function()
            this.hovered = true
            ApplyButtonVisual(this)
            if this.memberName then
                GameTooltip:SetOwner(this, "ANCHOR_LEFT")
                GameTooltip:AddLine(this.memberName, 1, 0.82, 0.35)
                GameTooltip:AddLine((this.roleLabel or "Leadership") .. (this.memberClass and this.memberClass ~= "" and ("  -  " .. this.memberClass) or ""), 1, 1, 1)
                GameTooltip:AddLine("Click to whisper", 0.55, 0.75, 1.0)
                GameTooltip:Show()
            end
        end)
        button:SetScript("OnLeave", function() this.hovered = false ApplyButtonVisual(this) GameTooltip:Hide() end)
        button:Hide()
        self.ui.homeLeaderButtons[i] = button
    end
    self.ui.homeNoLeaders = CreateText(leaders, "GameFontNormalSmall", "No leadership detected online.", 16, -70, 226, "LEFT")
    self.ui.homeNoLeaders:SetTextColor(0.55, 0.55, 0.55)

    local recent = CreateFrame("Frame", nil, page)
    recent:SetPoint("TOPLEFT", page, "TOPLEFT", 460, -356)
    recent:SetWidth(258)
    recent:SetHeight(124)
    CreateBackdrop(recent, 5)
    recent:SetBackdropColor(0.026, 0.023, 0.019, 0.995)
    recent:SetBackdropBorderColor(0.36, 0.29, 0.18, 1)
    CreateText(recent, "GameFontNormalSmall", "RECENT USEFUL ACTIVITY", 12, -10, 150, "LEFT")
    self.ui.homeUsefulViewAll153 = CreateButton(recent, nil, "View All", 184, -6, 62, 22, function()
        if OTLGM.OpenActivityDialog153 then OTLGM:OpenActivityDialog153("GUILD", "ALL") end
    end)
    SetButtonActionStyle(self.ui.homeUsefulViewAll153, "utility")
    self.ui.homeRecentPanel153 = recent
    self.ui.homeUsefulRows = {}
    for i = 1, 4 do
        local row = CreateText(recent, "GameFontNormalSmall", "", 12, -34 - ((i - 1) * 21), 234, "LEFT")
        row:SetTextColor(0.78, 0.78, 0.75)
        self.ui.homeUsefulRows[i] = row
    end
    self.ui.homeUsefulEmpty = CreateWrappedText(recent, "GameFontNormalSmall", "No recent group, request or response activity.", 12, -48, 234, 48)
    self.ui.homeUsefulEmpty:SetTextColor(0.52, 0.52, 0.50)

    self.ui.homeGuildInfoButton = CreateButton(page, nil, "Guild Information & Rules", 460, -490, 258, 26, function() OTLGM:ShowPage("guildinfo") end)
    AddButtonIcon(self.ui.homeGuildInfoButton, "Interface\\Icons\\INV_Scroll_03", 14, true)
    SetButtonActionStyle(self.ui.homeGuildInfoButton, "primary")
end

function OTLGM:RefreshHomePveSummary155()
    if not self.ui or not self.ui.homeRaidText then return end
    local pve = self.GetPveSummary and self:GetPveSummary() or { requests = 0, pending = 0, raid = nil }
    if pve.raid then
        self.ui.homeRaidText:SetText(self.colors.red .. HomeShort152(pve.raid.name or "Guild Raid", 30) .. self.colors.reset .. "\n" ..
            (pve.raid.serverTime or "Time TBA") .. "  " .. (self.GetPveRaidRemainingText and self:GetPveRaidRemainingText(pve.raid) or ""))
    else
        self.ui.homeRaidText:SetText(self.colors.grey .. "No raid scheduled" .. self.colors.reset .. "\nSign-ups remain in Discord")
    end
    if self.ui.homeGroupsText155 then
        local requests = self.GetPveRequests and self:GetPveRequests() or {}
        local first = requests[1]
        if first then
            local need = {}
            if (tonumber(first.needTank) or 0) > 0 then table.insert(need, "T" .. tostring(first.needTank)) end
            if (tonumber(first.needHeal) or 0) > 0 then table.insert(need, "H" .. tostring(first.needHeal)) end
            if (tonumber(first.needDps) or 0) > 0 then table.insert(need, "D" .. tostring(first.needDps)) end
            self.ui.homeGroupsText155:SetText(self.colors.green .. tostring(table.getn(requests)) .. " open" .. self.colors.reset .. "  " .. HomeShort152(first.activity or "Group", 18) .. (table.getn(need) > 0 and ("  [" .. table.concat(need, " ") .. "]") or ""))
        else
            self.ui.homeGroupsText155:SetText(self.colors.grey .. "No open groups" .. self.colors.reset .. ((pve.pending or 0) > 0 and ("  •  " .. tostring(pve.pending) .. " pending") or ""))
        end
    end
end

function OTLGM:RefreshHomePage()
    if not self.ui or not self.ui.homeAnnouncementRows then return end
    local announcements = self.GetAnnouncementList152 and self:GetAnnouncementList152(false) or {}
    if self.CanPublishAnnouncement152 and self:CanPublishAnnouncement152() then self.ui.homeNewAnnouncementButton:Show() else self.ui.homeNewAnnouncementButton:Hide() end
    local i, row, record, summary
    for i = 1, table.getn(self.ui.homeAnnouncementRows) do
        row = self.ui.homeAnnouncementRows[i]
        record = announcements[i]
        if record then
            row.recordId = record.id
            local prefix = record.pinned and (self.colors.gold .. "[PINNED] " .. self.colors.reset) or ""
            local titleColor = record.importance == "CRITICAL" and self.colors.red or (record.importance == "IMPORTANT" and self.colors.gold or self.colors.white)
            local unread = self.IsAnnouncementUnread154 and self:IsAnnouncementUnread154(record.id)
            row.newText:SetText(unread and "NEW" or "")
            row.titleText:SetText(prefix .. titleColor .. HomeShort152(record.title, 48) .. self.colors.reset)
            row.metaText:SetText(self.colors.gold .. date("%d %b %Y", record.createdAt or record.updatedAt or self:Now()) .. self.colors.reset .. "\n" .. date("%H:%M", record.createdAt or record.updatedAt or self:Now()) .. "  " .. (record.author or "Leadership"))
            row.bodyText:SetText(HomeShort152(record.body, 185))
            summary = self:GetAnnouncementReactionSummary152(record.id)
            SetButtonText(row.reactionButtons.LIKE, "Like " .. tostring(summary.LIKE or 0))
            SetButtonText(row.reactionButtons.SEEN, "Seen " .. tostring(summary.SEEN or 0))
            SetButtonText(row.reactionButtons.SUPPORT, "Support " .. tostring(summary.SUPPORT or 0))
            row:Show()
        else
            row.recordId = nil
            if row.newText then row.newText:SetText("") end
            row:Hide()
        end
    end
    if table.getn(announcements) == 0 then self.ui.homeNoAnnouncements:Show() else self.ui.homeNoAnnouncements:Hide() end
    local allAnnouncements154 = self:GetAnnouncementList152(true)
    local archivedCount154 = 0
    local ai154
    for ai154 = 1, table.getn(allAnnouncements154) do if allAnnouncements154[ai154].archived then archivedCount154 = archivedCount154 + 1 end end
    SetButtonText(self.ui.homeAnnouncementArchiveButton, "Announcements  " .. tostring(table.getn(allAnnouncements154)) .. "  |  Archived " .. tostring(archivedCount154))

    self:RefreshHomePveSummary155()

    local leaders = self:GetLeadershipOnline() or {}
    for i = 1, 4 do
        local button = self.ui.homeLeaderButtons[i]
        local member = leaders[i]
        if member then
            local roleLabel, roleIcon = GetLeadershipRoleInfo153(member)
            button.memberName = member.name
            button.memberClass = member.class
            button.roleLabel = roleLabel
            if button.roleIcon then button.roleIcon:SetTexture(roleIcon) end
            SetButtonText(button, self:GetClassColor(member.class) .. (member.name or "Unknown") .. self.colors.reset .. "  " .. self.colors.grey .. roleLabel .. self.colors.reset)
            button:Show()
        else button.memberName = nil button.memberClass = nil button.roleLabel = nil button:Hide() end
    end
    if table.getn(leaders) == 0 then self.ui.homeNoLeaders:Show() else self.ui.homeNoLeaders:Hide() end

    local activity = self.GetUsefulActivity152 and self:GetUsefulActivity152(4) or {}
    for i = 1, 4 do
        if activity[i] then
            self.ui.homeUsefulRows[i]:SetText(self.colors.gold .. "•" .. self.colors.reset .. " " .. HomeShort152(activity[i].title, 39))
            self.ui.homeUsefulRows[i]:Show()
        else self.ui.homeUsefulRows[i]:SetText("") self.ui.homeUsefulRows[i]:Hide() end
    end
    if table.getn(activity) == 0 then self.ui.homeUsefulEmpty:Show() else self.ui.homeUsefulEmpty:Hide() end
end

function OTLGM:BuildModalOverlay152()
    if self.ui.modalOverlay152 then return end
    local overlay = CreateFrame("Button", "OTLGM_ModalOverlay154", self.ui.main)
    overlay:SetPoint("TOPLEFT", self.ui.main, "TOPLEFT", 12, -12)
    overlay:SetPoint("BOTTOMRIGHT", self.ui.main, "BOTTOMRIGHT", -12, 12)
    overlay:SetFrameStrata("FULLSCREEN_DIALOG")
    overlay:SetFrameLevel(self.ui.main:GetFrameLevel() + 90)
    overlay:EnableMouse(true)
    overlay:SetScript("OnClick", function() end)
    local shade = CreateSolidTexture(overlay, "BACKGROUND", 0, 0, 0, 0.80)
    shade:SetAllPoints(overlay)
    overlay:Hide()
    self.ui.modalOverlay152 = overlay
    self.ui.modalFrames152 = self.ui.modalFrames152 or {}
    self.ui.modalStack154 = self.ui.modalStack154 or {}
end

local function ModalRemoveFromStack154(stack, frame)
    local i
    for i = table.getn(stack or {}), 1, -1 do
        if stack[i] == frame then table.remove(stack, i) end
    end
end

local function RaiseModalChildren154(frame, baseLevel, depth)
    if not frame then return end
    depth = tonumber(depth) or 0
    if frame.SetFrameStrata then frame:SetFrameStrata("FULLSCREEN_DIALOG") end
    if frame.SetFrameLevel then frame:SetFrameLevel(baseLevel + depth) end
    if not frame.GetChildren then return end
    local children = { frame:GetChildren() }
    local i, child
    for i = 1, table.getn(children) do
        child = children[i]
        if child and child ~= frame then RaiseModalChildren154(child, baseLevel, depth + 2) end
    end
end

function OTLGM:AddModalCloseButton154(frame)
    if not frame or frame.modalCloseButton154 or frame.noCloseButton154 then return end
    local width = frame.GetWidth and frame:GetWidth() or 400
    local button = CreateButton(frame, nil, "X", width - 38, -10, 26, 24, function() frame:Hide() end)
    SetButtonActionStyle(button, "danger")
    button:SetScript("OnEnter", function()
        this.hovered = true ApplyButtonVisual(this)
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:AddLine("Close", 1, 0.82, 0.35)
        GameTooltip:AddLine("You can also press Escape.", 0.70, 0.70, 0.70)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() this.hovered = false ApplyButtonVisual(this) GameTooltip:Hide() end)
    frame.modalCloseButton154 = button
end

function OTLGM:RefreshModalOverlay152()
    if not self.ui or not self.ui.modalOverlay152 then return end
    local stack = self.ui.modalStack154 or {}
    local visible = {}
    local i, frame
    for i = 1, table.getn(stack) do
        frame = stack[i]
        if frame and frame:IsVisible() then table.insert(visible, frame) end
    end
    self.ui.modalStack154 = visible
    if table.getn(visible) == 0 then
        self.ui.modalOverlay152:Hide()
        return
    end
    self.ui.modalOverlay152:SetFrameStrata("FULLSCREEN_DIALOG")
    self.ui.modalOverlay152:SetFrameLevel(self.ui.main:GetFrameLevel() + 90)
    self.ui.modalOverlay152:Show()
    for i = 1, table.getn(visible) do
        RaiseModalChildren154(visible[i], self.ui.main:GetFrameLevel() + 120 + (i * 24), 0)
    end
end

function OTLGM:RegisterModal152(frame)
    if not frame then return end
    self:BuildModalOverlay152()
    if not frame.modal152Registered then
        frame.modal152Registered = true
        table.insert(self.ui.modalFrames152, frame)
        self:AddModalCloseButton154(frame)
        local frameName = frame.GetName and frame:GetName() or nil
        if frameName and frameName ~= "" and UISpecialFrames then
            local found, i = false, 1
            for i = 1, table.getn(UISpecialFrames) do if UISpecialFrames[i] == frameName then found = true break end end
            if not found then table.insert(UISpecialFrames, frameName) end
        end
        local oldShow = frame:GetScript("OnShow")
        local oldHide = frame:GetScript("OnHide")
        frame:SetScript("OnShow", function()
            if oldShow then oldShow() end
            local stack = OTLGM.ui.modalStack154 or {}
            ModalRemoveFromStack154(stack, frame)
            table.insert(stack, frame)
            OTLGM.ui.modalStack154 = stack
            OTLGM:RefreshModalOverlay152()
        end)
        frame:SetScript("OnHide", function()
            if oldHide then oldHide() end
            local stack = OTLGM.ui.modalStack154 or {}
            ModalRemoveFromStack154(stack, frame)
            OTLGM.ui.modalStack154 = stack
            OTLGM:RefreshModalOverlay152()
        end)
    end
    RaiseModalChildren154(frame, self.ui.main:GetFrameLevel() + 144, 0)
end

function OTLGM:ShowModal152(frame)
    if not frame then return end
    if self.ui.main and not self.ui.main:IsVisible() then self.ui.main:Show() end
    self:RegisterModal152(frame)
    if frame.modalCloseButton154 then
        frame.modalCloseButton154:ClearAllPoints()
        frame.modalCloseButton154:SetPoint("TOPLEFT", frame, "TOPLEFT", (frame:GetWidth() or 400) - 38, -10)
    end
    frame:Show()
    self:RefreshModalOverlay152()
end

function OTLGM:CloseTopModal152()
    local stack = self.ui and self.ui.modalStack154 or {}
    local i
    for i = table.getn(stack), 1, -1 do
        if stack[i] and stack[i]:IsVisible() then stack[i]:Hide() return true end
    end
    return false
end

function OTLGM:RegisterStandardModals152()
    local frames = { self.ui.noticeDialog, self.ui.copyDialog, self.ui.importDialog, self.ui.confirmDialog, self.ui.firstRunWizard, self.ui.announcementComposer152, self.ui.announcementReader152, self.ui.announcementArchive152 }
    local i
    for i = 1, table.getn(frames) do if frames[i] then self:RegisterModal152(frames[i]) end end
end

function OTLGM:BuildAnnouncementDialogs152()
    if self.ui.announcementComposer152 then return end
    local composer = CreateFrame("Frame", "OTLGM_AnnouncementComposer152", self.ui.main)
    composer:SetWidth(690)
    composer:SetHeight(536)
    composer:SetPoint("CENTER", self.ui.main, "CENTER", 0, 0)
    CreateBackdrop(composer, 8)
    composer:SetBackdropColor(0.010, 0.009, 0.008, 1)
    composer:SetBackdropBorderColor(0.96, 0.68, 0.22, 1)
    composer.titleLabel = CreateText(composer, "GameFontNormalLarge", "Publish Leadership Announcement", 24, -20, 642, "CENTER")
    composer.helpText = CreateWrappedText(composer, "GameFontNormalSmall", "Write an official guild post. Paragraphs and line breaks are preserved. Notify Members is optional.", 34, -50, 622, 34)
    composer.helpText:SetTextColor(0.74, 0.74, 0.72)
    CreateText(composer, "GameFontNormalSmall", "TITLE", 34, -92, 120, "LEFT")
    composer.titleEdit = CreateEditBox(composer, "OTLGM_AnnouncementTitle152", 34, -112, 622, 36, false)
    composer.titleEdit:SetMaxLetters(80)
    composer.titleEdit:SetTextColor(1, 1, 1)
    composer.titleEdit:SetBackdropColor(0.025, 0.024, 0.022, 1)
    composer.titleEdit:SetBackdropBorderColor(0.58, 0.42, 0.20, 1)
    CreateText(composer, "GameFontNormalSmall", "MESSAGE", 34, -160, 120, "LEFT")
    composer.bodyEdit = CreateEditBox(composer, "OTLGM_AnnouncementBody152", 34, -180, 622, 220, true)
    composer.bodyEdit:SetMaxLetters(900)
    composer.bodyEdit:SetTextColor(1, 1, 1)
    composer.bodyEdit:SetJustifyV("TOP")
    composer.bodyEdit:SetBackdropColor(0.025, 0.024, 0.022, 1)
    composer.bodyEdit:SetBackdropBorderColor(0.58, 0.42, 0.20, 1)
    local function FocusField(edit, focused)
        if focused then edit:SetBackdropBorderColor(1.0, 0.72, 0.24, 1)
        else edit:SetBackdropBorderColor(0.58, 0.42, 0.20, 1) end
    end
    composer.titleEdit:SetScript("OnEditFocusGained", function() FocusField(this, true) end)
    composer.titleEdit:SetScript("OnEditFocusLost", function() FocusField(this, false) end)
    composer.bodyEdit:SetScript("OnEditFocusGained", function() FocusField(this, true) end)
    composer.bodyEdit:SetScript("OnEditFocusLost", function() FocusField(this, false) end)
    CreateText(composer, "GameFontNormalSmall", "IMPORTANCE", 34, -414, 120, "LEFT")
    composer.importanceButtons = {}
    local levels = { {"NORMAL", "Normal"}, {"IMPORTANT", "Important"}, {"CRITICAL", "Critical"} }
    local i
    for i = 1, table.getn(levels) do
        local level = levels[i][1]
        composer.importanceButtons[level] = CreateButton(composer, nil, levels[i][2], 34 + ((i - 1) * 112), -436, 104, 28, function()
            OTLGM.ui.announcementComposer152.importance = level
            OTLGM:RefreshAnnouncementComposer152()
        end)
        if level == "CRITICAL" then SetButtonActionStyle(composer.importanceButtons[level], "danger") end
    end
    composer.notifyButton = CreateButton(composer, nil, "Notify Members", 388, -436, 128, 28, function() composer.notifyFlag = not composer.notifyFlag OTLGM:RefreshAnnouncementComposer152() end)
    composer.pinButton = CreateButton(composer, nil, "Pin on Home", 526, -436, 130, 28, function() composer.pinned = not composer.pinned OTLGM:RefreshAnnouncementComposer152() end)
    composer.validationText = CreateText(composer, "GameFontNormalSmall", "Title and message are required.", 34, -480, 370, "LEFT")
    composer.validationText:SetTextColor(0.82, 0.58, 0.35)
    composer.postButton = CreateButton(composer, nil, "Publish", 430, -484, 106, 30, function()
        local ok, result = OTLGM:PublishAnnouncement152(composer.titleEdit:GetText() or "", composer.bodyEdit:GetText() or "", composer.importance, composer.notifyFlag, composer.pinned, composer.editId)
        if ok then
            if not composer.editId then OTLGM_DB.settings.announcementDraftTitle153 = "" OTLGM_DB.settings.announcementDraftBody153 = "" end
            composer:Hide() OTLGM:RefreshHomePage()
        else
            composer.validationText:SetText(result or "The announcement could not be published.")
            OTLGM:ShowNotice("Announcement", result or "The announcement could not be published.")
        end
    end)
    SetButtonActionStyle(composer.postButton, "confirm")
    composer.cancelButton = CreateButton(composer, nil, "Cancel", 546, -484, 110, 30, function() composer:Hide() end)
    composer.titleEdit:SetScript("OnTextChanged", function()
        if OTLGM_DB and OTLGM_DB.settings and not composer.editId then OTLGM_DB.settings.announcementDraftTitle153 = this:GetText() or "" end
        OTLGM:RefreshAnnouncementComposer152()
    end)
    composer.bodyEdit:SetScript("OnTextChanged", function()
        if OTLGM_DB and OTLGM_DB.settings and not composer.editId then OTLGM_DB.settings.announcementDraftBody153 = this:GetText() or "" end
        OTLGM:RefreshAnnouncementComposer152()
    end)
    composer:SetScript("OnHide", function()
        if not composer.editId and OTLGM_DB and OTLGM_DB.settings then
            OTLGM_DB.settings.announcementDraftTitle153 = composer.titleEdit:GetText() or ""
            OTLGM_DB.settings.announcementDraftBody153 = composer.bodyEdit:GetText() or ""
        end
        composer.titleEdit:ClearFocus() composer.bodyEdit:ClearFocus()
    end)
    composer:Hide()
    self.ui.announcementComposer152 = composer

    local reader = CreateFrame("Frame", "OTLGM_AnnouncementReader152", self.ui.main)
    reader:SetWidth(700)
    reader:SetHeight(536)
    reader:SetPoint("CENTER", self.ui.main, "CENTER", 0, 0)
    CreateBackdrop(reader, 8)
    reader:SetBackdropColor(0.014, 0.013, 0.011, 1)
    reader:SetBackdropBorderColor(0.88, 0.58, 0.18, 1)
    reader.titleText = CreateWrappedText(reader, "GameFontNormalLarge", "Announcement", 28, -22, 570, 48)
    reader.unreadText = CreateText(reader, "GameFontNormalSmall", "", 604, -28, 50, "RIGHT")
    reader.unreadText:SetTextColor(0.40, 1.0, 0.48)
    reader.metaText = CreateWrappedText(reader, "GameFontNormalSmall", "", 28, -72, 644, 38)
    reader.metaText:SetTextColor(0.72, 0.72, 0.70)
    local bodyPanel = CreateFrame("Frame", nil, reader)
    bodyPanel:SetPoint("TOPLEFT", reader, "TOPLEFT", 24, -116)
    bodyPanel:SetWidth(652)
    bodyPanel:SetHeight(296)
    CreateBackdrop(bodyPanel, 5)
    bodyPanel:SetBackdropColor(0.025, 0.023, 0.020, 1)
    bodyPanel:SetBackdropBorderColor(0.42, 0.32, 0.18, 1)
    reader.bodyScroll = CreateFrame("ScrollFrame", "OTLGM_AnnouncementBodyScroll154", bodyPanel)
    reader.bodyScroll:SetPoint("TOPLEFT", bodyPanel, "TOPLEFT", 12, -12)
    reader.bodyScroll:SetWidth(608)
    reader.bodyScroll:SetHeight(272)
    reader.bodyChild = CreateFrame("Frame", nil, reader.bodyScroll)
    reader.bodyChild:SetWidth(598)
    reader.bodyChild:SetHeight(272)
    reader.bodyText = CreateWrappedText(reader.bodyChild, "GameFontHighlight", "", 2, -2, 588, 268)
    reader.bodyScroll:SetScrollChild(reader.bodyChild)
    reader.bodySlider = CreateSlider(bodyPanel, "OTLGM_AnnouncementBodySlider154", 628, -12, 272, function()
        if OTLGM.updatingAnnouncementScroll154 then return end
        reader.bodyScroll:SetVerticalScroll(this:GetValue() or 0)
    end)
    AttachMouseWheel(reader.bodyScroll, function(delta)
        local current = reader.bodySlider:GetValue() or 0
        reader.bodySlider:SetValue(math.max(0, current - (delta * 36)))
    end)
    reader.reactionButtons = {}
    local reactions = { {"LIKE", "Like"}, {"SEEN", "Seen"}, {"SUPPORT", "Support"} }
    for i = 1, table.getn(reactions) do
        local reaction = reactions[i][1]
        local label = reactions[i][2]
        local button = CreateButton(reader, nil, label, 28 + ((i - 1) * 112), -430, 104, 28, function()
            if reader.recordId then OTLGM:ReactToAnnouncement152(reader.recordId, reaction) OTLGM:RefreshAnnouncementReader152() OTLGM:RefreshHomePage() end
        end)
        button:SetScript("OnEnter", function()
            this.hovered = true ApplyButtonVisual(this)
            if reader.recordId then OTLGM:ShowCommunityReactorsTooltip152(this, "ANN", reader.recordId, reaction, label) end
        end)
        button:SetScript("OnLeave", function() this.hovered = false ApplyButtonVisual(this) GameTooltip:Hide() end)
        reader.reactionButtons[reaction] = button
    end
    reader.editButton = CreateButton(reader, nil, "Edit", 392, -430, 72, 28, function() local id = reader.recordId reader:Hide() OTLGM:OpenAnnouncementComposer152(id) end)
    reader.archiveButton = CreateButton(reader, nil, "Archive", 472, -430, 84, 28, function()
        if reader.recordId then local record = OTLGM:GetAnnouncement152(reader.recordId) OTLGM:SetAnnouncementArchived152(reader.recordId, not (record and record.archived)) reader:Hide() OTLGM:RefreshHomePage() end
    end)
    reader.deleteButton = CreateButton(reader, nil, "Delete", 564, -430, 84, 28, function()
        if not reader.recordId then return end
        local id = reader.recordId
        OTLGM:ShowConfirm("Delete Announcement", "Delete this leadership announcement from connected addon users?", "Delete", function() OTLGM:DeleteAnnouncement152(id) reader:Hide() OTLGM:RefreshHomePage() end)
    end)
    SetButtonActionStyle(reader.deleteButton, "danger")
    reader.closeButton = CreateButton(reader, nil, "Close", 544, -484, 104, 30, function() reader:Hide() end)
    reader:Hide()
    self.ui.announcementReader152 = reader

    local archive = CreateFrame("Frame", "OTLGM_AnnouncementArchive152", self.ui.main)
    archive:SetWidth(680)
    archive:SetHeight(520)
    archive:SetPoint("CENTER", self.ui.main, "CENTER", 0, 0)
    CreateBackdrop(archive, 8)
    archive:SetBackdropColor(0.014, 0.013, 0.011, 1)
    archive:SetBackdropBorderColor(0.78, 0.52, 0.17, 1)
    archive.titleText = CreateText(archive, "GameFontNormalLarge", "Announcements", 24, -20, 632, "CENTER")
    archive.mode154 = "ACTIVE"
    archive.activeButton = CreateButton(archive, nil, "Active", 24, -56, 120, 28, function() archive.mode154 = "ACTIVE" OTLGM:OpenAnnouncementArchive152("ACTIVE") end)
    archive.archivedButton = CreateButton(archive, nil, "Archived", 152, -56, 120, 28, function() archive.mode154 = "ARCHIVED" OTLGM:OpenAnnouncementArchive152("ARCHIVED") end)
    SetButtonActionStyle(archive.activeButton, "utility") SetButtonActionStyle(archive.archivedButton, "utility")
    archive.rows = {}
    for i = 1, 11 do
        local row = CreateButton(archive, nil, "", 24, -94 - ((i - 1) * 32), 632, 30, function()
            if this.recordId then archive:Hide() OTLGM:OpenAnnouncementReader152(this.recordId) end
        end)
        row.text:SetJustifyH("LEFT") row.text:ClearAllPoints() row.text:SetPoint("LEFT", row, "LEFT", 10, 0) row.text:SetWidth(612)
        row:Hide() archive.rows[i] = row
    end
    archive.emptyText = CreateWrappedText(archive, "GameFontNormal", "", 40, -190, 600, 80)
    archive.emptyText:SetTextColor(0.62, 0.62, 0.60)
    archive.offset154 = 0
    archive.previousButton = CreateButton(archive, nil, "Previous", 300, -472, 90, 30, function()
        archive.offset154 = math.max(0, (archive.offset154 or 0) - table.getn(archive.rows))
        OTLGM:OpenAnnouncementArchive152(archive.mode154)
    end)
    archive.pageText = CreateText(archive, "GameFontNormalSmall", "", 396, -481, 72, "CENTER")
    archive.nextButton = CreateButton(archive, nil, "Next", 474, -472, 66, 30, function()
        archive.offset154 = (archive.offset154 or 0) + table.getn(archive.rows)
        OTLGM:OpenAnnouncementArchive152(archive.mode154)
    end)
    archive.closeButton = CreateButton(archive, nil, "Close", 548, -472, 108, 30, function() archive:Hide() end)
    archive:Hide()
    self.ui.announcementArchive152 = archive
    self:RegisterStandardModals152()
end

function OTLGM:RefreshAnnouncementComposer152()
    local dialog = self.ui and self.ui.announcementComposer152
    if not dialog then return end
    local key, button
    for key, button in pairs(dialog.importanceButtons or {}) do SetButtonSelected(button, key == dialog.importance) end
    SetButtonSelected(dialog.notifyButton, dialog.notifyFlag)
    SetButtonSelected(dialog.pinButton, dialog.pinned)
    SetButtonText(dialog.notifyButton, dialog.notifyFlag and "Notify: ON" or "Notify Members")
    SetButtonText(dialog.pinButton, dialog.pinned and "Pinned: ON" or "Pin on Home")
    SetButtonText(dialog.postButton, dialog.editId and "Save Changes" or "Publish")

    local title = string.gsub(dialog.titleEdit:GetText() or "", "^%s*(.-)%s*$", "%1")
    local body = string.gsub(dialog.bodyEdit:GetText() or "", "^%s*(.-)%s*$", "%1")
    local ready = title ~= "" and body ~= ""
    if ready then
        dialog.validationText:SetText("Ready to publish. Notifications are sent only when Notify Members is enabled.")
        dialog.validationText:SetTextColor(0.45, 0.82, 0.48)
    elseif title == "" and body == "" then
        dialog.validationText:SetText("Title and message are required.")
        dialog.validationText:SetTextColor(0.72, 0.46, 0.30)
    elseif title == "" then
        dialog.validationText:SetText("Enter a title before publishing.")
        dialog.validationText:SetTextColor(0.90, 0.48, 0.30)
    else
        dialog.validationText:SetText("Enter the announcement message before publishing.")
        dialog.validationText:SetTextColor(0.90, 0.48, 0.30)
    end
    SetButtonEnabled(dialog.postButton, ready, ready and nil or "Fill in both the title and message.")
end

function OTLGM:OpenAnnouncementComposer152(id)
    if not self.ui.announcementComposer152 then self:BuildAnnouncementDialogs152() end
    local dialog = self.ui.announcementComposer152
    if not self.CanPublishAnnouncement152 or not self:CanPublishAnnouncement152() then self:ShowNotice("Leadership Announcement", "Only guild leadership can publish official announcements.") return end
    local record = id and self:GetAnnouncement152(id) or nil
    dialog.editId = record and record.id or nil
    local draftTitle = OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.announcementDraftTitle153 or ""
    local draftBody = OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.announcementDraftBody153 or ""
    dialog.titleEdit:SetText(record and record.title or draftTitle)
    dialog.bodyEdit:SetText(record and record.body or draftBody)
    dialog.importance = record and record.importance or "NORMAL"
    dialog.notifyFlag = record and record.notifyFlag and true or false
    dialog.pinned = record and record.pinned and true or false
    self:RefreshAnnouncementComposer152()
    self:ShowModal152(dialog)
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog.titleEdit:SetFrameLevel(dialog:GetFrameLevel() + 8)
    dialog.bodyEdit:SetFrameLevel(dialog:GetFrameLevel() + 8)
    local key, button
    for key, button in pairs(dialog.importanceButtons or {}) do button:SetFrameLevel(dialog:GetFrameLevel() + 8) end
    dialog.notifyButton:SetFrameLevel(dialog:GetFrameLevel() + 8)
    dialog.pinButton:SetFrameLevel(dialog:GetFrameLevel() + 8)
    dialog.postButton:SetFrameLevel(dialog:GetFrameLevel() + 8)
    dialog.cancelButton:SetFrameLevel(dialog:GetFrameLevel() + 8)
    dialog.titleEdit:SetFocus()
end

function OTLGM:RefreshAnnouncementReader152()
    local reader = self.ui and self.ui.announcementReader152
    local record = reader and reader.recordId and self:GetAnnouncement152(reader.recordId) or nil
    if not reader or not record then return end
    local color = record.importance == "CRITICAL" and self.colors.red or (record.importance == "IMPORTANT" and self.colors.gold or self.colors.white)
    reader.titleText:SetText(color .. BreakLongTokens154(record.title or "Announcement", 48) .. self.colors.reset)
    reader.unreadText:SetText(self.IsAnnouncementUnread154 and self:IsAnnouncementUnread154(record.id) and "NEW" or "")
    local published = date("%d %B %Y at %H:%M", record.createdAt or self:Now())
    local edited = tonumber(record.updatedAt) and tonumber(record.createdAt) and tonumber(record.updatedAt) > tonumber(record.createdAt) + 5
    local meta = "Published by " .. (record.author or "Leadership") .. "  •  " .. published
    if edited then meta = meta .. "\nEdited " .. date("%d %B %Y at %H:%M", record.updatedAt) end
    if record.pinned then meta = self.colors.gold .. "PINNED" .. self.colors.reset .. "  •  " .. meta end
    meta = meta .. "  •  " .. (record.importance or "NORMAL")
    reader.metaText:SetText(meta)
    local displayBody = BreakLongTokens154(record.body and record.body ~= "" and record.body or "No message text is stored for this announcement.", 52)
    reader.bodyText:SetText(displayBody)
    local measured = 268
    if reader.bodyText.GetStringHeight then measured = math.max(268, (reader.bodyText:GetStringHeight() or 260) + 14) end
    reader.bodyText:SetHeight(measured)
    reader.bodyChild:SetHeight(measured)
    local maximum = math.max(0, measured - 272)
    OTLGM.updatingAnnouncementScroll154 = true
    reader.bodySlider:SetMinMaxValues(0, maximum)
    reader.bodySlider:SetValue(0)
    reader.bodyScroll:SetVerticalScroll(0)
    OTLGM.updatingAnnouncementScroll154 = nil
    if maximum > 0 then reader.bodySlider:Show() else reader.bodySlider:Hide() end
    local summary = self:GetAnnouncementReactionSummary152(record.id)
    SetButtonText(reader.reactionButtons.LIKE, "Like " .. tostring(summary.LIKE or 0))
    SetButtonText(reader.reactionButtons.SEEN, "Seen " .. tostring(summary.SEEN or 0))
    SetButtonText(reader.reactionButtons.SUPPORT, "Support " .. tostring(summary.SUPPORT or 0))
    local canEdit = self:CanPublishAnnouncement152()
    if canEdit then reader.editButton:Show() reader.archiveButton:Show() reader.deleteButton:Show() else reader.editButton:Hide() reader.archiveButton:Hide() reader.deleteButton:Hide() end
    SetButtonText(reader.archiveButton, record.archived and "Restore" or "Archive")
end

function OTLGM:OpenAnnouncementReader152(id)
    if not self.ui.announcementReader152 then self:BuildAnnouncementDialogs152() end
    local record = self:GetAnnouncement152(id)
    if not record then return end
    self.ui.announcementReader152.recordId = id
    self:RefreshAnnouncementReader152()
    self:ShowModal152(self.ui.announcementReader152)
    if self.MarkAnnouncementRead154 then self:MarkAnnouncementRead154(id) end
    self.ui.announcementReader152.unreadText:SetText("")
    if self.RefreshHomePage then self:RefreshHomePage() end
end

function OTLGM:OpenAnnouncementArchive152(mode)
    if not self.ui.announcementArchive152 then self:BuildAnnouncementDialogs152() end
    local dialog = self.ui.announcementArchive152
    local requestedMode154 = mode == "ARCHIVED" and "ARCHIVED" or (mode == "ACTIVE" and "ACTIVE" or dialog.mode154 or "ACTIVE")
    if requestedMode154 ~= dialog.mode154 then dialog.offset154 = 0 end
    dialog.mode154 = requestedMode154
    local all = self:GetAnnouncementList152(true)
    local active, archived = {}, {}
    local i, record
    for i = 1, table.getn(all) do
        if all[i].archived then table.insert(archived, all[i]) else table.insert(active, all[i]) end
    end
    local list = dialog.mode154 == "ARCHIVED" and archived or active
    SetButtonSelected(dialog.activeButton, dialog.mode154 == "ACTIVE")
    SetButtonSelected(dialog.archivedButton, dialog.mode154 == "ARCHIVED")
    SetButtonText(dialog.activeButton, "Active " .. tostring(table.getn(active)))
    SetButtonText(dialog.archivedButton, "Archived " .. tostring(table.getn(archived)))
    dialog.titleText:SetText(self.colors.gold .. "Announcements" .. self.colors.reset)
    local perPage154 = table.getn(dialog.rows)
    local maximumOffset154 = math.max(0, table.getn(list) - perPage154)
    if (dialog.offset154 or 0) > maximumOffset154 then dialog.offset154 = math.floor(maximumOffset154 / perPage154) * perPage154 end
    local offset154 = dialog.offset154 or 0
    for i = 1, table.getn(dialog.rows) do
        record = list[offset154 + i]
        if record then
            dialog.rows[i].recordId = record.id
            local marker = self.IsAnnouncementUnread154 and self:IsAnnouncementUnread154(record.id) and "[NEW] " or ""
            SetButtonText(dialog.rows[i], marker .. date("%d %b %Y  %H:%M", record.createdAt or record.updatedAt or self:Now()) .. "  " .. HomeShort152(record.title, 56) .. "  —  " .. (record.author or "Leadership"))
            dialog.rows[i]:Show()
        else dialog.rows[i].recordId = nil dialog.rows[i]:Hide() end
    end
    if table.getn(list) == 0 then
        dialog.emptyText:SetText(dialog.mode154 == "ARCHIVED" and "No archived announcements yet." or "No active announcements have been published yet.")
        dialog.emptyText:Show()
    else dialog.emptyText:SetText("") dialog.emptyText:Hide() end
    local page154 = math.floor((dialog.offset154 or 0) / perPage154) + 1
    local pages154 = math.max(1, math.ceil(table.getn(list) / perPage154))
    dialog.pageText:SetText(tostring(page154) .. " / " .. tostring(pages154))
    SetButtonEnabled(dialog.previousButton, (dialog.offset154 or 0) > 0, "Already on the first page.")
    SetButtonEnabled(dialog.nextButton, (dialog.offset154 or 0) + perPage154 < table.getn(list), "Already on the last page.")
    self:ShowModal152(dialog)
end

function OTLGM:BuildOverviewPage(page)
    CreateText(page, "GameFontNormalLarge", "Guild Overview", 0, -2, 360, "LEFT")
    CreateHelpButton(page, "Overview", "Officer-oriented snapshot of guild growth, open group requests, shared board posts, addon adoption, the next raid notice and recent important events.")
    CreateText(page, "GameFontNormalSmall", "A practical management view of the latest valid local roster database.", 0, -28, 700, "LEFT")

    self.ui.overviewCards = {}
    self.ui.overviewCards.members = CreateCard(page, 0, -62, 140, 76, "MEMBERS")
    self.ui.overviewCards.online = CreateCard(page, 150, -62, 140, 76, "ONLINE")
    self.ui.overviewCards.joined = CreateCard(page, 300, -62, 140, 76, "JOINED / LEFT")
    self.ui.overviewCards.inactive = CreateCard(page, 450, -62, 140, 76, "INACTIVE 30D+")
    self.ui.overviewCards.unread = CreateCard(page, 600, -62, 118, 76, "UNREAD")

    self.ui.overviewPulseCards = {}
    self.ui.overviewPulseCards.level60 = CreateCard(page, 0, -148, 170, 68, "LEVEL 60")
    self.ui.overviewPulseCards.requests = CreateCard(page, 182, -148, 170, 68, "OPEN REQUESTS")
    self.ui.overviewPulseCards.pending = CreateCard(page, 364, -148, 170, 68, "GROUP APPLICANTS")
    self.ui.overviewPulseCards.addon = CreateCard(page, 546, -148, 172, 68, "ADDON USERS")
    self.ui.overviewPulseCards.addon:EnableMouse(true)
    self.ui.overviewPulseCards.addon:SetScript("OnEnter", function() OTLGM:ShowAddonUsersTooltip(this) end)
    self.ui.overviewPulseCards.addon:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.ui.overviewPulseCards.addon:SetScript("OnMouseDown", function() OTLGM:RequestAddonUserPing() end)

    local summary = CreateFrame("Frame", nil, page)
    summary:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -226)
    summary:SetWidth(718)
    summary:SetHeight(70)
    CreateBackdrop(summary, 5)
    summary:SetBackdropColor(0.045, 0.035, 0.020, 0.98)
    summary:SetBackdropBorderColor(0.38, 0.27, 0.13, 1)
    self.ui.overviewGrowth = CreateText(summary, "GameFontNormalLarge", "", 14, -12, 240, "LEFT")
    self.ui.overviewChanges = CreateWrappedText(summary, "GameFontNormalSmall", "", 270, -12, 430, 48)
    self.ui.overviewFreshness = CreateText(summary, "GameFontNormalSmall", "", 14, -47, 240, "LEFT")

    CreateText(page, "GameFontNormal", "Recent important activity", 0, -310, 330, "LEFT")
    self.ui.overviewEvents = {}
    local i
    for i = 1, 7 do
        self.ui.overviewEvents[i] = CreateText(page, "GameFontNormalSmall", "", 0, -338 - ((i - 1) * 23), 718, "LEFT")
    end
    self.ui.overviewSummaryButton = CreateButton(page, nil, "Copy Weekly Summary", 552, -494, 166, 30, function()
        OTLGM:ShowCopyDialog("Weekly Guild Summary", OTLGM:GenerateWeeklySummary())
    end)
    AddButtonIcon(self.ui.overviewSummaryButton, "Interface\\Icons\\INV_Scroll_06", 14, true)
    SetButtonActionStyle(self.ui.overviewSummaryButton, "utility")
end

function OTLGM:RefreshOverviewPage()
    if not self.ui.overviewCards then return end
    local db = self:GetGuildDB()
    if not db then return end
    local stats = self:GetStats(7)
    local roles = self:GetGuildRoleSnapshot()
    local addonUsers, latestVersion, addonOnline = self:GetDetectedAddonUsers(86400)
    local pve = self.GetPveSummary and self:GetPveSummary() or { requests = 0, board = 0, raid = nil, kinds = {} }
    local freshText, freshColor = self:GetFreshnessText(db.lastScan)
    local onlinePercent = (db.lastTotal or 0) > 0 and math.floor(((db.lastOnline or 0) * 100) / (db.lastTotal or 1) + 0.5) or 0
    local sixtyPercent = roles.level60 > 0 and math.floor((roles.level60Online * 100) / roles.level60 + 0.5) or 0
    self.ui.overviewCards.members.value:SetText(tostring(db.lastTotal or 0))
    self.ui.overviewCards.members.sub:SetText("Tracked characters")
    self.ui.overviewCards.online.value:SetText(self.colors.green .. tostring(db.lastOnline or 0) .. self.colors.reset)
    self.ui.overviewCards.online.sub:SetText(tostring(onlinePercent) .. "% of roster online")
    self.ui.overviewCards.joined.value:SetText(self.colors.green .. "+" .. tostring(stats.joins) .. self.colors.reset .. "  " .. self.colors.red .. "-" .. tostring(stats.leaves) .. self.colors.reset)
    self.ui.overviewCards.joined.sub:SetText("Last 7 days")
    self.ui.overviewCards.inactive.value:SetText(tostring(stats.inactive30))
    self.ui.overviewCards.inactive.sub:SetText("Offline 30 days or more")
    self.ui.overviewCards.unread.value:SetText(self.colors.gold .. tostring(stats.unread) .. self.colors.reset)
    self.ui.overviewCards.unread.sub:SetText("Awaiting review")

    self.ui.overviewPulseCards.level60.value:SetText(self.colors.gold .. tostring(roles.level60Online) .. self.colors.reset .. " / " .. tostring(roles.level60))
    self.ui.overviewPulseCards.level60.sub:SetText("online / total  -  " .. tostring(sixtyPercent) .. "%")
    self.ui.overviewPulseCards.requests.value:SetText(self.colors.blue .. tostring(pve.requests or 0) .. self.colors.reset)
    self.ui.overviewPulseCards.requests.sub:SetText("live group requests")
    self.ui.overviewPulseCards.pending.value:SetText((pve.pending or 0) > 0 and (self.colors.gold .. tostring(pve.pending or 0) .. self.colors.reset) or (self.colors.grey .. "0" .. self.colors.reset))
    self.ui.overviewPulseCards.pending.sub:SetText("waiting for your groups")
    self.ui.overviewPulseCards.addon.value:SetText(self.colors.green .. tostring(addonUsers) .. self.colors.reset)
    self.ui.overviewPulseCards.addon.sub:SetText(tostring(addonOnline) .. " online now - hover for names")

    local netColor = stats.net >= 0 and self.colors.green or self.colors.red
    if pve.raid then
        self.ui.overviewGrowth:SetText(self.colors.gold .. (pve.raid.name or "Guild Raid") .. self.colors.reset)
        self.ui.overviewChanges:SetText((pve.raid.serverTime or "Time TBA") .. "  -  " .. self:GetPveRaidRemainingText(pve.raid) ..
            "\n" .. ((pve.raid.location and pve.raid.location ~= "") and ("Meeting: " .. pve.raid.location) or "Meeting point not specified") .. "  -  Sign-ups in Discord")
    else
        self.ui.overviewGrowth:SetText("7-day growth: " .. netColor .. (stats.net >= 0 and "+" or "") .. tostring(stats.net) .. self.colors.reset)
        self.ui.overviewChanges:SetText("No active raid notice.  Open groups: " .. tostring(pve.requests or 0) .. "  -  Applicants: " .. tostring(pve.pending or 0) .. "  -  Board: " .. tostring(pve.board or 0) ..
            "\nRank changes: " .. tostring(stats.ranks) .. "  -  Milestones: " .. tostring(stats.levels) .. "  -  Returned: " .. tostring(stats.returns))
    end
    self.ui.overviewFreshness:SetText(freshColor .. freshText .. self.colors.reset)

    local shown = 0
    local i, eventInfo
    for i = 1, table.getn(db.log or {}) do
        eventInfo = db.log[i]
        if eventInfo.kind ~= "BASELINE" and not eventInfo.hiddenLegacyLevel then
            shown = shown + 1
            if shown <= 7 then
                local kindColor = self.colors.white
                if eventInfo.kind == "JOIN" then kindColor = self.colors.green end
                if eventInfo.kind == "LEAVE" then kindColor = self.colors.red end
                if eventInfo.kind == "RANK" then kindColor = self.colors.gold end
                if eventInfo.kind == "LEVEL" then kindColor = self.colors.blue end
                if eventInfo.kind == "RETURN" then kindColor = self.colors.green end
                if eventInfo.kind == "NOTE" then kindColor = self.colors.grey end
                local nameColor = eventInfo.class and eventInfo.class ~= "" and self:GetClassColor(eventInfo.class) or self.colors.white
                local actor = eventInfo.actor and eventInfo.actor ~= "" and ("  " .. self.colors.grey .. "by " .. eventInfo.actor .. self.colors.reset) or ""
                self.ui.overviewEvents[shown]:SetText(
                    self.colors.grey .. date("%d/%m %H:%M", eventInfo.ts) .. self.colors.reset .. "  " ..
                    kindColor .. eventInfo.kind .. self.colors.reset .. "  " ..
                    nameColor .. (eventInfo.name or "") .. self.colors.reset .. "  " ..
                    (eventInfo.detail or "") .. actor
                )
            end
        end
        if shown >= 7 then break end
    end
    for i = shown + 1, 7 do self.ui.overviewEvents[i]:SetText(self.colors.darkGrey .. "No recorded event" .. self.colors.reset) end
end

function OTLGM:BuildGuildInfoPage(page)
    CreateText(page, "GameFontNormalLarge", "Order of the Lion - Guild Information", 0, -2, 520, "LEFT")
    CreateHelpButton(page, "Guild Info", "A scrollable guild handbook with the MOTD, core information, rank structure, staff responsibilities and useful links.")
    CreateText(page, "GameFontNormalSmall", "Scroll with the mouse wheel or use the bar on the right.", 0, -28, 700, "LEFT")

    local viewport = CreateFrame("ScrollFrame", "OTLGM_GuildInfoScrollFrame", page)
    viewport:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -58)
    viewport:SetWidth(720)
    viewport:SetHeight(448)
    CreateBackdrop(viewport, 4)
    viewport:SetBackdropColor(0.018, 0.016, 0.013, 0.98)
    viewport:SetBackdropBorderColor(0.34, 0.27, 0.16, 1)

    local child = CreateFrame("Frame", nil, viewport)
    child:SetWidth(698)
    child:SetHeight(1700)
    viewport:SetScrollChild(child)
    self.ui.guildInfoViewport = viewport
    self.ui.guildInfoChild = child

    local function InfoPanel(y, height, title)
        local panel = CreateFrame("Frame", nil, child)
        panel:SetPoint("TOPLEFT", child, "TOPLEFT", 8, y)
        panel:SetWidth(680)
        panel:SetHeight(height)
        CreateBackdrop(panel, 5)
        panel:SetBackdropColor(0.040, 0.032, 0.023, 0.98)
        panel:SetBackdropBorderColor(0.38, 0.29, 0.16, 1)
        CreateText(panel, "GameFontNormal", title, 12, -10, 656, "LEFT")
        return panel
    end

    local motd = InfoPanel(-8, 82, "CURRENT GUILD MOTD")
    self.ui.guildInfoMotd = CreateWrappedText(motd, "GameFontHighlight", "", 12, -32, 656, 40)

    local info = InfoPanel(-98, 126, "FULL GUILD INFORMATION")
    self.ui.guildInfoText = CreateWrappedText(info, "GameFontHighlight", "", 12, -32, 656, 84)

    local about = InfoPanel(-232, 118, "ABOUT ORDER OF THE LION")
    CreateWrappedText(about, "GameFontHighlight", "<Order of the Lion> is an ENG/EU Social + PvE guild on OctoWoW. We focus on a friendly community, relaxed but organized progress, leveling, dungeons, professions and guild PvE.", 12, -32, 656, 46)
    self.ui.guildInfoLeadership = CreateWrappedText(about, "GameFontNormalSmall", "Online leadership: loading...", 12, -82, 656, 24)

    local startPanel = InfoPanel(-358, 126, "GETTING STARTED")
    CreateWrappedText(startPanel, "GameFontHighlight",
        "1. Join Discord using your in-game character name.\n" ..
        "2. Read the guild rules and announcements.\n" ..
        "3. Use Roster filters to find guildmates in your zone, near your level or with useful professions.\n" ..
        "4. Ask leadership to update helpful profession or role notes when needed.\n" ..
        "5. Contact online Leadership whenever you need help.",
        12, -32, 656, 86)

    local ranksHeaderY = -502
    CreateText(child, "GameFontNormalLarge", "Guild Ranks", 8, ranksHeaderY, 300, "LEFT")
    self.ui.guildCurrentRank = CreateText(child, "GameFontNormal", "Your current in-game rank: loading...", 320, ranksHeaderY - 2, 368, "RIGHT")
    CreateText(child, "GameFontNormalSmall", "Ranks are grouped by purpose. The highlighted row is your current in-game rank.", 8, ranksHeaderY - 26, 670, "LEFT")

    local columns = CreateFrame("Frame", nil, child)
    columns:SetPoint("TOPLEFT", child, "TOPLEFT", 8, ranksHeaderY - 52)
    columns:SetWidth(680)
    columns:SetHeight(26)
    CreateBackdrop(columns, 3)
    columns:SetBackdropColor(0.10, 0.070, 0.025, 0.98)
    columns:SetBackdropBorderColor(0.45, 0.31, 0.13, 1)
    CreateText(columns, "GameFontNormalSmall", "#", 12, -7, 32, "CENTER")
    CreateText(columns, "GameFontNormalSmall", "RANK", 52, -7, 142, "LEFT")
    CreateText(columns, "GameFontNormalSmall", "HOW TO RECEIVE", 204, -7, 230, "LEFT")
    CreateText(columns, "GameFontNormalSmall", "ROLE / MEANING", 442, -7, 224, "LEFT")

    local sectionTitles = {
        Restricted = { title = "RESTRICTED STATUS", subtitle = "Temporary disciplinary rank" },
        Visitor = { title = "VISITOR STATUS", subtitle = "Exploring the guild" },
        Social = { title = "SOCIAL RANKS", subtitle = "Community members" },
        Raiding = { title = "RAIDER RANKS", subtitle = "Part of the raid team" },
        Leadership = { title = "LEADERSHIP", subtitle = "Leads and manages the guild" },
    }

    self.ui.guildRankCards = {}
    local currentY = ranksHeaderY - 86
    local previousKind = nil
    local i
    for i = 1, table.getn(self.rankInformation) do
        local rankInfo = self.rankInformation[i]
        if rankInfo.kind ~= previousKind then
            local r, g, b = GetRankKindColor(rankInfo.kind)
            local group = sectionTitles[rankInfo.kind] or { title = string.upper(rankInfo.kind or "RANKS"), subtitle = "" }
            local groupFrame = CreateFrame("Frame", nil, child)
            groupFrame:SetPoint("TOPLEFT", child, "TOPLEFT", 8, currentY)
            groupFrame:SetWidth(680)
            groupFrame:SetHeight(32)
            CreateBackdrop(groupFrame, 3)
            groupFrame:SetBackdropColor(r * 0.10, g * 0.10, b * 0.10, 0.98)
            groupFrame:SetBackdropBorderColor(r * 0.72, g * 0.72, b * 0.72, 1)
            local groupTitle = CreateText(groupFrame, "GameFontNormal", group.title, 12, -8, 270, "LEFT")
            groupTitle:SetTextColor(r, g, b)
            local groupSubtitle = CreateText(groupFrame, "GameFontNormal", group.subtitle, 290, -8, 374, "LEFT")
            groupSubtitle:SetTextColor(r * 0.88, g * 0.88, b * 0.88)
            currentY = currentY - 38
            previousKind = rankInfo.kind
        end

        local r, g, b = GetRankKindColor(rankInfo.kind)
        local card = CreateFrame("Frame", nil, child)
        card:SetPoint("TOPLEFT", child, "TOPLEFT", 8, currentY)
        card:SetWidth(680)
        card:SetHeight(58)
        CreateBackdrop(card, 3)
        card:SetBackdropColor(0.027, 0.024, 0.021, 0.98)
        card:SetBackdropBorderColor(r * 0.42, g * 0.42, b * 0.42, 1)
        card.accent = CreateSolidTexture(card, "ARTWORK", r, g, b, 0.95)
        card.accent:SetPoint("TOPLEFT", card, "TOPLEFT", 5, -5)
        card.accent:SetWidth(4)
        card.accent:SetHeight(48)
        card.badge = CreateText(card, "GameFontNormalLarge", rankInfo.number or tostring(i), 14, -18, 32, "CENTER")
        card.badge:SetTextColor(r, g, b)
        card.title = CreateWrappedText(card, "GameFontNormal", rankInfo.displayName or rankInfo.name, 52, -10, 142, 40)
        card.title:SetTextColor(r, g, b)
        card.receive = CreateWrappedText(card, "GameFontNormalSmall", rankInfo.receive, 204, -8, 230, 44)
        card.receive:SetTextColor(0.90, 0.90, 0.90)
        card.access = CreateWrappedText(card, "GameFontNormalSmall", rankInfo.access, 442, -8, 224, 44)
        card.access:SetTextColor(0.78, 0.78, 0.78)
        card.rankInfo = rankInfo
        self.ui.guildRankCards[i] = card
        currentY = currentY - 64
    end

    local contactsY = currentY - 8
    local contacts = InfoPanel(contactsY, 150, "WHO TO CONTACT")
    CreateWrappedText(contacts, "GameFontHighlight",
        "Guild Leader / Lucky Luck - overall guild direction and final decisions.\n" ..
        "Lionheart - senior leadership and broad guild responsibility.\n" ..
        "Officer - rules, conflicts, recruitment, moderation and member assistance.\n" ..
        "Helper - Discord guidance, basic questions and day-to-day support.\n" ..
        "Raid leadership - raid timing, groups, preparation, tactics and raid decisions.",
        12, -32, 656, 108)

    local links = InfoPanel(contactsY - 160, 110, "USEFUL LINKS")
    CreateText(links, "GameFontNormalSmall", "Discord", 12, -40, 80, "LEFT")
    local discord = CreateEditBox(links, "OTLGM_GuildInfoDiscord", 90, -30, 370, 30, false)
    discord:SetText("https://discord.gg/UNacDPrGt2")
    discord:SetScript("OnTextChanged", nil)
    self.ui.guildInfoDiscord = discord
    local copyButton = CreateButton(links, nil, "Copy Discord Link", 474, -30, 188, 30, function()
        OTLGM:ShowCopyDialog("Order of the Lion Discord", "https://discord.gg/UNacDPrGt2")
    end)
    AddButtonIcon(copyButton, "Interface\\Icons\\INV_Letter_15", 14, true)
    SetButtonActionStyle(copyButton, "utility")
    CreateText(links, "GameFontNormalSmall", "The Vanilla client selects links for Ctrl+C instead of opening a browser.", 12, -76, 650, "LEFT")

    local contentBottom = math.abs(contactsY - 160) + 120
    child:SetHeight(contentBottom)
    self.ui.guildInfoContentHeight = contentBottom

    local slider = CreateSlider(page, "OTLGM_GuildInfoSlider", 728, -58, 448, function()
        OTLGM.ui.guildInfoViewport:SetVerticalScroll(this:GetValue())
    end)
    slider:SetMinMaxValues(0, math.max(0, contentBottom - 448))
    self.ui.guildInfoSlider = slider

    local function ScrollInfo(delta)
        local minValue, maxValue = OTLGM.ui.guildInfoSlider:GetMinMaxValues()
        local value = OTLGM.ui.guildInfoSlider:GetValue() - ((delta or 0) * 70)
        if value < minValue then value = minValue end
        if value > maxValue then value = maxValue end
        OTLGM.ui.guildInfoSlider:SetValue(value)
    end
    AttachMouseWheel(viewport, ScrollInfo)
    AttachMouseWheel(child, ScrollInfo)
end

function OTLGM:RefreshGuildInfoPage()
    if not self.ui.guildInfoMotd then return end
    local motd = GetGuildRosterMOTD and (GetGuildRosterMOTD() or "") or ""
    local info = GetGuildInfoText and (GetGuildInfoText() or "") or ""
    if motd == "" then motd = "No guild message of the day is currently set." end
    if info == "" then info = "No additional guild information is currently set." end
    self.ui.guildInfoMotd:SetText(motd)
    self.ui.guildInfoText:SetText(info)

    local leaders = self:GetLeadershipOnline()
    local names = {}
    local i
    for i = 1, math.min(6, table.getn(leaders)) do
        table.insert(names, self:GetClassColor(leaders[i].class) .. leaders[i].name .. self.colors.reset .. " " .. self.colors.grey .. "(" .. (leaders[i].rank or "Leadership") .. ")" .. self.colors.reset)
    end
    if table.getn(names) > 0 then
        self.ui.guildInfoLeadership:SetText("Online leadership: " .. table.concat(names, ", "))
    else
        self.ui.guildInfoLeadership:SetText(self.colors.grey .. "Online leadership: none currently shown." .. self.colors.reset)
    end

    local playerRank = ""
    local playerName = UnitName("player")
    local playerMember = playerName and self:GetMember(playerName)
    if playerMember then playerRank = string.lower(playerMember.rank or "") end
    if self.ui.guildCurrentRank then
        self.ui.guildCurrentRank:SetText("Your current in-game rank: " .. self.colors.gold .. (playerMember and playerMember.rank or "Unknown") .. self.colors.reset)
    end

    for i = 1, table.getn(self.ui.guildRankCards or {}) do
        local card = self.ui.guildRankCards[i]
        local rankInfo = card.rankInfo or self.rankInformation[i]
        local r, g, b = GetRankKindColor(rankInfo.kind)
        card.receive:SetText(rankInfo.receive)
        card.access:SetText(rankInfo.access)
        if RankInfoMatches(rankInfo, playerRank) then
            card:SetBackdropColor(r * 0.18, g * 0.18, b * 0.18, 0.98)
            card:SetBackdropBorderColor(1.0, 0.76, 0.22, 1)
            card.accent:SetVertexColor(1.0, 0.76, 0.22)
            card.badge:SetTextColor(1.0, 0.82, 0.30)
            card.title:SetText((rankInfo.displayName or rankInfo.name) .. "  -  YOU ARE HERE")
            card.title:SetTextColor(1.0, 0.82, 0.30)
        else
            card:SetBackdropColor(0.027, 0.024, 0.021, 0.98)
            card:SetBackdropBorderColor(r * 0.42, g * 0.42, b * 0.42, 1)
            card.accent:SetVertexColor(r, g, b)
            card.badge:SetTextColor(r, g, b)
            card.title:SetText(rankInfo.displayName or rankInfo.name)
            card.title:SetTextColor(r, g, b)
        end
    end
end

function OTLGM:BuildRosterPage(page)
    self:EnsureDB()
    CreateText(page, "GameFontNormalLarge", "Guild Roster", 0, -2, 300, "LEFT")
    CreateHelpButton(page, "Guild Roster", "Search and filter the latest valid roster snapshot. Left-click selects a member, right-click whispers and Shift-click invites. Offline members are grey. Profession results are unconfirmed because they are detected from guild notes.")
    CreateText(page, "GameFontNormalSmall", "Find people by rank, zone, level, activity and profession tags.", 0, -28, 700, "LEFT")

    local search = CreateEditBox(page, "OTLGM_RosterSearch", 0, -54, 242, 28, false)
    search:SetScript("OnTextChanged", function()
        OTLGM.ui.rosterOffset = 0
        OTLGM_DB.settings.rosterSearch = this:GetText() or ""
        OTLGM:RefreshRosterPage()
    end)
    self.ui.rosterSearch = search
    local hint = CreateText(page, "GameFontNormalSmall", "Search name, class, rank, zone or notes", 8, -62, 226, "LEFT")
    hint:SetTextColor(0.50, 0.50, 0.50)
    self.ui.rosterSearchHint = hint
    search:SetScript("OnEditFocusGained", function() if this:GetText() == "" then OTLGM.ui.rosterSearchHint:Hide() end end)
    search:SetScript("OnEditFocusLost", function() if this:GetText() == "" then OTLGM.ui.rosterSearchHint:Show() end end)
    self.ui.clearSearchButton = CreateButton(page, nil, "X", 248, -54, 28, 28, function()
        OTLGM.ui.rosterSearch:SetText("")
        OTLGM.ui.rosterSearch:ClearFocus()
        OTLGM.ui.rosterOffset = 0
        OTLGM:RefreshRosterPage()
    end)

    self.ui.rosterFilter = OTLGM_DB.settings.rosterFilter or "ALL"
    self.ui.rosterRankFilter = OTLGM_DB.settings.rosterRankFilter ~= "" and OTLGM_DB.settings.rosterRankFilter or nil
    self.ui.rosterProfessionFilter = OTLGM_DB.settings.rosterProfessionFilter ~= "" and OTLGM_DB.settings.rosterProfessionFilter or nil
    self.ui.rosterFilterButtons = {}

    local filters = {
        { "ALL", "All", 286, 54 },
        { "ONLINE", "Online", 346, 70 },
        { "LEADERSHIP", "Leadership", 422, 90 },
    }
    local i
    for i = 1, table.getn(filters) do
        local key = filters[i][1]
        local capturedKey = key
        local button = CreateButton(page, nil, filters[i][2], filters[i][3], -54, filters[i][4], 28, function()
            OTLGM.ui.rosterFilter = capturedKey
            OTLGM_DB.settings.rosterFilter = capturedKey
            OTLGM.ui.rosterOffset = 0
            OTLGM:RefreshRosterPage()
        end)
        self.ui.rosterFilterButtons[key] = button
    end

    self.ui.moreFilterButton = CreateButton(page, nil, "More", 518, -54, 90, 28, function()
        OTLGM:ToggleRosterPopup("more")
    end)
    self.ui.viewsButton = CreateButton(page, nil, "Saved Views", 614, -54, 104, 28, function()
        OTLGM:ToggleRosterPopup("views")
    end)

    CreateText(page, "GameFontNormalSmall", "Rank", 0, -94, 38, "LEFT")
    self.ui.rankFilterButton = CreateButton(page, nil, "All ranks", 38, -89, 150, 28, function()
        OTLGM:ToggleRosterPopup("rank")
    end)
    CreateText(page, "GameFontNormalSmall", "Profession", 198, -94, 68, "LEFT")
    self.ui.professionFilterButton = CreateButton(page, nil, "All professions", 266, -89, 150, 28, function()
        OTLGM:ToggleRosterPopup("profession")
    end)
    CreateButton(page, nil, "Reset Filters", 424, -89, 102, 28, function()
        OTLGM.ui.rosterFilter = "ALL"
        OTLGM.ui.rosterRankFilter = nil
        OTLGM.ui.rosterProfessionFilter = nil
        OTLGM_DB.settings.rosterFilter = "ALL"
        OTLGM_DB.settings.rosterRankFilter = ""
        OTLGM_DB.settings.rosterProfessionFilter = ""
        OTLGM.ui.rosterOffset = 0
        OTLGM:RefreshRosterPage()
    end)
    self.ui.rosterFreshness = CreateText(page, "GameFontNormalSmall", "", 538, -96, 180, "RIGHT")

    local header = CreateFrame("Frame", nil, page)
    header:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -126)
    header:SetWidth(492)
    header:SetHeight(22)
    CreateBackdrop(header, 3)
    header:SetBackdropColor(0.11, 0.075, 0.025, 0.98)
    header:SetBackdropBorderColor(0.45, 0.31, 0.13, 1)
    self.ui.rosterSortButtons = {}
    self.ui.rosterSortButtons.NAME = CreateSortHeaderButton(header, "NAME", "Name", 38, 118)
    self.ui.rosterSortButtons.LEVEL = CreateSortHeaderButton(header, "LEVEL", "Lvl", 160, 34)
    self.ui.rosterSortButtons.CLASS = CreateSortHeaderButton(header, "CLASS", "Class", 198, 78)
    self.ui.rosterSortButtons.RANK = CreateSortHeaderButton(header, "RANK", "Rank", 280, 112)
    self.ui.rosterSortButtons.LASTONLINE = CreateSortHeaderButton(header, "LASTONLINE", "Last online", 396, 92)
    AttachMouseWheel(header, function(delta) OTLGM:ScrollRoster(delta) end)

    local listFrame = CreateFrame("Frame", nil, page)
    listFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -150)
    listFrame:SetWidth(492)
    listFrame:SetHeight(ROSTER_ROWS * ROW_HEIGHT)
    listFrame:SetFrameLevel(page:GetFrameLevel() + 5)
    listFrame:EnableMouse(true)
    AttachMouseWheel(listFrame, function(delta) OTLGM:ScrollRoster(delta) end)
    self.ui.rosterListFrame = listFrame

    self.ui.rosterNoMatches = CreateWrappedText(listFrame, "GameFontNormalSmall", "No members match the current filters.\nUse Reset Filters or clear the search field.", 52, -118, 390, 54)
    self.ui.rosterNoMatches:SetJustifyH("CENTER")
    self.ui.rosterNoMatches:SetTextColor(0.55, 0.55, 0.55)
    self.ui.rosterNoMatches:Hide()

    self.ui.rosterRows = {}
    for i = 1, ROSTER_ROWS do
        local row = CreateFrame("Button", nil, listFrame)
        row:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, -((i - 1) * ROW_HEIGHT))
        row:SetWidth(492)
        row:SetHeight(ROW_HEIGHT)
        row:SetFrameLevel(listFrame:GetFrameLevel() + 2)
        row:EnableMouse(true)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row.baseStripe = CreateSolidTexture(row, "BACKGROUND", 0.12, 0.12, 0.12, 0.20)
        row.baseStripe:SetAllPoints(row)
        if math.mod(i, 2) ~= 0 then row.baseStripe:Hide() end
        row.leadership = CreateSolidTexture(row, "BACKGROUND", 0.35, 0.20, 0.035, 0.16)
        row.leadership:SetAllPoints(row)
        row.leadership:Hide()
        row.selectedTexture = CreateSolidTexture(row, "BORDER", 0.48, 0.30, 0.05, 0.48)
        row.selectedTexture:SetAllPoints(row)
        row.selectedTexture:Hide()
        row.returnTexture = CreateSolidTexture(row, "BORDER", 0.06, 0.28, 0.10, 0.28)
        row.returnTexture:SetAllPoints(row)
        row.returnTexture:Hide()
        row.roleIcon = row:CreateTexture(nil, "OVERLAY")
        row.roleIcon:SetWidth(14)
        row.roleIcon:SetHeight(14)
        row.roleIcon:SetPoint("LEFT", row, "LEFT", 20, 0)
        row.roleIcon:Hide()
        row.recentIcon = CreateText(row, "GameFontNormalSmall", "", 474, -6, 14, "CENTER")

        row:SetScript("OnClick", function()
            if not this.memberName then return end
            if arg1 == "RightButton" then OTLGM:WhisperMember(this.memberName)
            elseif IsShiftKeyDown() then OTLGM:InviteMemberToGroup(this.memberName)
            else OTLGM:SelectRosterMember(this.memberName) end
        end)
        row:SetScript("OnEnter", function()
            if this.memberName then OTLGM:ShowRosterTooltip(this.memberName, this) end
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        AttachMouseWheel(row, function(delta) OTLGM:ScrollRoster(delta) end)

        row.status = CreateText(row, "GameFontNormalSmall", "", 6, -6, 12, "LEFT")
        row.name = CreateText(row, "GameFontNormalSmall", "", 38, -6, 118, "LEFT")
        row.level = CreateText(row, "GameFontNormalSmall", "", 160, -6, 34, "LEFT")
        row.class = CreateText(row, "GameFontNormalSmall", "", 198, -6, 78, "LEFT")
        row.rank = CreateText(row, "GameFontNormalSmall", "", 280, -6, 112, "LEFT")
        row.lastOnline = CreateText(row, "GameFontNormalSmall", "", 396, -6, 76, "LEFT")
        self.ui.rosterRows[i] = row
    end

    self.ui.rosterSlider = CreateSlider(page, "OTLGM_RosterSlider", 494, -150, ROSTER_ROWS * ROW_HEIGHT, function()
        OTLGM.ui.rosterOffset = math.floor(this:GetValue() + 0.5)
        OTLGM:RefreshRosterRowsOnly()
    end)
    self.ui.rosterOffset = 0
    self.ui.rosterCount = CreateText(page, "GameFontNormalSmall", "0 members shown", 0, -468, 210, "LEFT")
    self.ui.rosterHelp = CreateText(page, "GameFontNormalSmall", "Wheel scroll | Left select | Right whisper | Shift invite", 210, -468, 284, "RIGHT")
    self.ui.rosterHelp:SetTextColor(0.58, 0.58, 0.58)

    local panel = CreateFrame("Frame", nil, page)
    panel:SetPoint("TOPLEFT", page, "TOPLEFT", 516, -126)
    panel:SetWidth(202)
    panel:SetHeight(370)
    CreateBackdrop(panel, 5)
    panel:SetBackdropColor(0.034, 0.029, 0.023, 0.99)
    panel:SetBackdropBorderColor(0.43, 0.31, 0.15, 1)
    self.ui.memberPanel = panel

    self.ui.memberRoleIcon = panel:CreateTexture(nil, "OVERLAY")
    self.ui.memberRoleIcon:SetWidth(24)
    self.ui.memberRoleIcon:SetHeight(24)
    self.ui.memberRoleIcon:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10)
    self.ui.memberRoleIcon:Hide()
    self.ui.memberName = CreateText(panel, "GameFontNormalLarge", "Select a member", 40, -10, 152, "LEFT")
    self.ui.memberStatus = CreateText(panel, "GameFontNormalSmall", "", 40, -34, 152, "LEFT")
    self.ui.memberRank = CreateText(panel, "GameFontNormal", "", 10, -56, 182, "LEFT")
    self.ui.memberSummary = CreateWrappedText(panel, "GameFontNormalSmall", "Choose a roster row to view member information.", 10, -79, 182, 42)
    self.ui.memberDates = CreateText(panel, "GameFontNormalSmall", "", 10, -120, 182, "LEFT")
    self.ui.memberDates:SetTextColor(0.60, 0.60, 0.60)

    self.ui.publicNoteLabel = CreateText(panel, "GameFontNormalSmall", "PUBLIC NOTE", 10, -143, 182, "LEFT")
    self.ui.publicNoteEdit = CreateEditBox(panel, "OTLGM_PublicNoteEdit", 8, -157, 186, 34, true)
    self.ui.publicNoteEdit:SetMaxLetters(31)
    self.ui.publicNoteEdit:SetScript("OnEditFocusGained", function() if this.readOnly then this:ClearFocus() end end)
    self.ui.officerNoteLabel = CreateText(panel, "GameFontNormalSmall", "OFFICER NOTE", 10, -195, 182, "LEFT")
    self.ui.officerNoteEdit = CreateEditBox(panel, "OTLGM_OfficerNoteEdit", 8, -209, 186, 34, true)
    self.ui.officerNoteEdit:SetMaxLetters(31)
    self.ui.officerNoteEdit:SetScript("OnEditFocusGained", function() if this.readOnly then this:ClearFocus() end end)

    self.ui.saveNotesButton = CreateButton(panel, nil, "Save Notes", 8, -250, 186, 26, function()
        if OTLGM.ui.selectedMember then
            OTLGM:SaveMemberNotes(OTLGM.ui.selectedMember, OTLGM.ui.publicNoteEdit:GetText(), OTLGM.ui.officerNoteEdit:GetText())
        end
    end)
    AddButtonIcon(self.ui.saveNotesButton, "Interface\\Icons\\INV_Misc_Note_01", 14, true)
    SetButtonActionStyle(self.ui.saveNotesButton, "confirm")

    self.ui.memberHistoryText = CreateWrappedText(panel, "GameFontNormalSmall", "", 10, -282, 182, 28)
    self.ui.memberHistoryText:SetTextColor(0.64, 0.62, 0.57)
    self.ui.rankActionLabel = CreateText(panel, "GameFontNormalSmall", "RANK ACTIONS", 10, -310, 88, "LEFT")
    self.ui.rankActionLabel:SetTextColor(0.70, 0.64, 0.54)
    self.ui.memberOfficerFrames = { self.ui.officerNoteLabel, self.ui.officerNoteEdit, self.ui.rankActionLabel }
    self.ui.promoteButton = CreateButton(panel, nil, "^  Promote", 8, -324, 92, 22, function()
        if OTLGM.ui.selectedMember then OTLGM:PromoteMember(OTLGM.ui.selectedMember) end
    end)
    self.ui.demoteButton = CreateButton(panel, nil, "v  Demote", 8, -348, 92, 22, function()
        if OTLGM.ui.selectedMember then OTLGM:DemoteMember(OTLGM.ui.selectedMember) end
    end)
    self.ui.removeButton = CreateButton(panel, nil, "Remove", 106, -324, 88, 46, function()
        if not OTLGM.ui.selectedMember then return end
        local name = OTLGM.ui.selectedMember
        OTLGM:ShowConfirm("Remove Guild Member", "Remove " .. name .. " from the guild?\n\nThis uses the standard guild permission and cannot be undone by the addon.", "Remove", function()
            OTLGM:RemoveMember(name)
        end)
    end)
    self.ui.memberOfficerButtons = { self.ui.saveNotesButton, self.ui.promoteButton, self.ui.demoteButton, self.ui.removeButton }

    self.ui.whisperButton = CreateButton(page, nil, "Whisper", 516, -502, 70, 27, function()
        if OTLGM.ui.selectedMember then OTLGM:WhisperMember(OTLGM.ui.selectedMember) end
    end)
    AddButtonIcon(self.ui.whisperButton, "Interface\\Icons\\INV_Letter_15", 14, false)
    self.ui.inviteButton = CreateButton(page, nil, "Invite", 592, -502, 58, 27, function()
        if OTLGM.ui.selectedMember then OTLGM:InviteMemberToGroup(OTLGM.ui.selectedMember) end
    end)
    AddButtonIcon(self.ui.inviteButton, "Interface\\Icons\\INV_Misc_Spyglass_03", 14, false)
    self.ui.memberHistoryButton = CreateButton(page, nil, "History", 656, -502, 62, 27, function()
        if not OTLGM.ui.selectedMember then return end
        if OTLGM:IsOfficerMode() then
            OTLGM_DB.settings.historySearch = OTLGM.ui.selectedMember
            if OTLGM.ui.historySearch then OTLGM.ui.historySearch:SetText(OTLGM.ui.selectedMember) end
            OTLGM:ShowPage("history")
        else
            OTLGM:ShowCopyDialog("Character Name", OTLGM.ui.selectedMember)
        end
    end)
    AddButtonIcon(self.ui.memberHistoryButton, "Interface\\Icons\\INV_Misc_Book_09", 14, false)

    self:BuildRosterPopups(page)
    search:SetText(OTLGM_DB.settings.rosterSearch or "")
    if search:GetText() == "" then hint:Show() else hint:Hide() end
end

function OTLGM:BuildRosterPopups(page)
    local function Popup(width, anchor)
        local popup = CreateFrame("Frame", nil, page)
        popup:SetWidth(width)
        popup:SetHeight(30)
        popup:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
        CreateBackdrop(popup, 4)
        popup:SetBackdropColor(0.018, 0.016, 0.013, 1)
        popup:SetBackdropBorderColor(0.65, 0.43, 0.16, 1)
        popup:SetFrameLevel(page:GetFrameLevel() + 40)
        popup:Hide()
        return popup
    end

    self.ui.rankPopup = Popup(184, self.ui.rankFilterButton)
    self.ui.rankPopupButtons = {}
    local i
    for i = 1, 12 do
        local button = CreateButton(self.ui.rankPopup, nil, "", 5, -5 - ((i - 1) * 25), 174, 23, function()
            OTLGM.ui.rosterRankFilter = this.rankName
            OTLGM_DB.settings.rosterRankFilter = this.rankName or ""
            OTLGM.ui.rosterOffset = 0
            OTLGM.ui.rankPopup:Hide()
            OTLGM:RefreshRosterPage()
        end)
        button:Hide()
        self.ui.rankPopupButtons[i] = button
    end

    self.ui.professionPopup = Popup(184, self.ui.professionFilterButton)
    self.ui.professionPopupButtons = {}
    for i = 1, 14 do
        local button = CreateButton(self.ui.professionPopup, nil, "", 5, -5 - ((i - 1) * 25), 174, 23, function()
            OTLGM.ui.rosterProfessionFilter = this.professionKey
            OTLGM_DB.settings.rosterProfessionFilter = this.professionKey or ""
            OTLGM.ui.rosterOffset = 0
            OTLGM.ui.professionPopup:Hide()
            OTLGM:RefreshRosterPage()
        end)
        button:Hide()
        self.ui.professionPopupButtons[i] = button
    end

    self.ui.moreFilterPopup = Popup(180, self.ui.moreFilterButton)
    self.ui.moreFilterButtons = {}
    local moreFilters = {
        { "SAMEZONE", "My zone" }, { "NEARLEVEL", "Near my level" }, { "LEVEL60", "Level 60" },
        { "NEW14", "New members" }, { "RETURNED14", "Recently returned" }, { "PROMOTED14", "Recently promoted" },
        { "INACTIVE14", "Inactive 14d+" }, { "INACTIVE30", "Inactive 30d+" }, { "INACTIVE60", "Inactive 60d+" },
        { "INACTIVE90", "Inactive 90d+" }, { "LEVEL1_19", "Levels 1-19" }, { "LEVEL20_39", "Levels 20-39" },
        { "LEVEL40_59", "Levels 40-59" },
    }
    self.ui.moreFilterPopup:SetHeight(10 + (table.getn(moreFilters) * 25))
    for i = 1, table.getn(moreFilters) do
        local capturedKey = moreFilters[i][1]
        local button = CreateButton(self.ui.moreFilterPopup, nil, moreFilters[i][2], 5, -5 - ((i - 1) * 25), 170, 23, function()
            OTLGM.ui.rosterFilter = capturedKey
            OTLGM_DB.settings.rosterFilter = capturedKey
            OTLGM.ui.rosterOffset = 0
            OTLGM.ui.moreFilterPopup:Hide()
            OTLGM:RefreshRosterPage()
        end)
        button.filterKey = capturedKey
        self.ui.moreFilterButtons[capturedKey] = button
    end

    self.ui.viewsPopup = Popup(210, self.ui.viewsButton)
    self.ui.viewsPopup:ClearAllPoints()
    self.ui.viewsPopup:SetPoint("TOPRIGHT", self.ui.viewsButton, "BOTTOMRIGHT", 0, -2)
    self.ui.viewsPopup:SetHeight(166)
    CreateText(self.ui.viewsPopup, "GameFontNormalSmall", "LOAD VIEW", 8, -8, 90, "LEFT")
    CreateText(self.ui.viewsPopup, "GameFontNormalSmall", "SAVE CURRENT", 108, -8, 94, "LEFT")
    self.ui.loadViewButtons = {}
    self.ui.saveViewButtons = {}
    for i = 1, 3 do
        local slot = i
        self.ui.loadViewButtons[i] = CreateButton(self.ui.viewsPopup, nil, "Load " .. tostring(i), 8, -28 - ((i - 1) * 34), 88, 28, function()
            OTLGM.ui.viewsPopup:Hide()
            OTLGM:LoadRosterView(slot)
        end)
        self.ui.saveViewButtons[i] = CreateButton(self.ui.viewsPopup, nil, "Save " .. tostring(i), 108, -28 - ((i - 1) * 34), 94, 28, function()
            OTLGM:SaveRosterView(slot)
            OTLGM.ui.viewsPopup:Hide()
        end)
    end
end

function OTLGM:HideRosterPopups()
    if self.ui.rankPopup then self.ui.rankPopup:Hide() end
    if self.ui.professionPopup then self.ui.professionPopup:Hide() end
    if self.ui.moreFilterPopup then self.ui.moreFilterPopup:Hide() end
    if self.ui.viewsPopup then self.ui.viewsPopup:Hide() end
end

function OTLGM:ToggleRosterPopup(which)
    local targets = {
        rank = self.ui.rankPopup,
        profession = self.ui.professionPopup,
        more = self.ui.moreFilterPopup,
        views = self.ui.viewsPopup,
    }
    local target = targets[which]
    if not target then return end
    local visible = target:IsVisible()
    self:HideRosterPopups()
    if not visible then
        if which == "rank" then self:RefreshRankPopup() end
        if which == "profession" then self:RefreshProfessionPopup() end
        if which == "more" then self:RefreshMoreFilterPopup() end
        if which == "views" then self:RefreshSavedViewsPopup() end
        target:Show()
    end
end

function OTLGM:RefreshRankPopup()
    if not self.ui.rankPopupButtons then return end
    local ranks = self:GetRosterRanks()
    local entries = math.min(12, table.getn(ranks) + 1)
    local i, button
    for i = 1, 12 do
        button = self.ui.rankPopupButtons[i]
        if i == 1 then
            button.rankName = nil
            SetButtonText(button, "All ranks")
            SetButtonSelected(button, not self.ui.rosterRankFilter)
            button:Show()
        elseif ranks[i - 1] then
            button.rankName = ranks[i - 1].name
            SetButtonText(button, button.rankName)
            SetButtonSelected(button, self.ui.rosterRankFilter == button.rankName)
            button:Show()
        else button:Hide() end
    end
    self.ui.rankPopup:SetHeight(10 + (entries * 25))
end

function OTLGM:RefreshProfessionPopup()
    if not self.ui.professionPopupButtons then return end
    local items = { { key = nil, label = "All professions" } }
    local i
    for i = 1, table.getn(self.professionDefinitions) do
        table.insert(items, { key = self.professionDefinitions[i].key, label = self.professionDefinitions[i].label })
    end
    local count = math.min(table.getn(items), table.getn(self.ui.professionPopupButtons))
    self.ui.professionPopup:SetHeight(10 + (count * 25))
    for i = 1, table.getn(self.ui.professionPopupButtons) do
        local button = self.ui.professionPopupButtons[i]
        local item = items[i]
        if item then
            button.professionKey = item.key
            SetButtonText(button, item.label)
            SetButtonSelected(button, (self.ui.rosterProfessionFilter or "") == (item.key or ""))
            button:Show()
        else button:Hide() end
    end
end

function OTLGM:RefreshMoreFilterPopup()
    local key, button
    for key, button in pairs(self.ui.moreFilterButtons or {}) do SetButtonSelected(button, self.ui.rosterFilter == key) end
end

function OTLGM:RefreshSavedViewsPopup()
    if not self.ui.loadViewButtons then return end
    local i
    for i = 1, 3 do
        local saved = OTLGM_DB.settings.savedRosterViews and OTLGM_DB.settings.savedRosterViews[i]
        SetButtonText(self.ui.loadViewButtons[i], saved and ("View " .. tostring(i)) or ("Empty " .. tostring(i)))
        SetButtonEnabled(self.ui.loadViewButtons[i], saved ~= nil, "This saved roster view is empty.")
        SetButtonText(self.ui.saveViewButtons[i], saved and ("Replace " .. tostring(i)) or ("Save " .. tostring(i)))
    end
end

function OTLGM:ScrollRoster(delta)
    if not self.ui.rosterSlider then return end
    local minValue, maxValue = self.ui.rosterSlider:GetMinMaxValues()
    local offset = (self.ui.rosterOffset or 0) - ((delta or 0) * 3)
    if offset < minValue then offset = minValue end
    if offset > maxValue then offset = maxValue end
    self.ui.rosterOffset = offset
    self.ui.rosterSlider:SetValue(offset)
end

function OTLGM:RefreshRosterRowsOnly()
    if not self.ui.rosterRows then return end
    local search = self.ui.rosterSearch and self.ui.rosterSearch:GetText() or ""
    local list = self:GetSortedRoster(search, self.ui.rosterFilter, self.ui.rosterRankFilter, self.ui.rosterProfessionFilter)
    local maxOffset = math.max(0, table.getn(list) - ROSTER_ROWS)
    if (self.ui.rosterOffset or 0) > maxOffset then self.ui.rosterOffset = maxOffset end
    if self.ui.rosterSearchHint then
        if search == "" then self.ui.rosterSearchHint:Show() else self.ui.rosterSearchHint:Hide() end
    end
    if table.getn(list) == 0 then self.ui.rosterNoMatches:Show() else self.ui.rosterNoMatches:Hide() end

    local now = self:Now()
    local recentCutoff = now - (14 * 86400)
    local i
    for i = 1, ROSTER_ROWS do
        local row = self.ui.rosterRows[i]
        local member = list[i + (self.ui.rosterOffset or 0)]
        if member then
            local leadership = self:IsLeadership(member)
            local badgePath, badgeLabel, badgeR, badgeG, badgeB, badgeType = self:GetMemberBadge(member)
            local classColor = member.online and self:GetClassColor(member.class) or self.colors.darkGrey
            local normalColor = member.online and self.colors.white or self.colors.darkGrey
            local rankColor = self.colors.white
            if leadership then rankColor = self.colors.gold end
            if badgeType == "CORE" or badgeType == "RAIDER" then rankColor = self.colors.purple end
            if badgeType == "RESTRICTED" then rankColor = self.colors.red end
            if not member.online then rankColor = self.colors.darkGrey end
            row.memberName = member.name
            row.status:SetText(member.online and self.colors.green .. "*" .. self.colors.reset or self.colors.darkGrey .. "-" .. self.colors.reset)
            row.name:SetText(classColor .. member.name .. self.colors.reset)
            row.level:SetText(normalColor .. tostring(member.level or 0) .. self.colors.reset)
            row.class:SetText(classColor .. (member.class or "") .. self.colors.reset)
            row.rank:SetText(rankColor .. (member.rank or "") .. self.colors.reset)
            row.lastOnline:SetText(member.online and self.colors.green .. "Online" .. self.colors.reset or self.colors.darkGrey .. (member.lastOnlineText or "Offline") .. self.colors.reset)
            if OTLGM_DB.settings.highlightLeadership then
                if leadership then row.leadership:Show() else row.leadership:Hide() end
                ApplyLeadershipIcon(row.roleIcon, member, member.online)
            else
                row.leadership:Hide()
                row.roleIcon:Hide()
            end
            local recentlyReturned = member.returnedAt and member.returnedAt >= recentCutoff
            local newlyJoined = member.joinedAt and member.joinedAt >= recentCutoff
            local recentlyPromoted = member.promotedAt and member.promotedAt >= recentCutoff
            if recentlyReturned then
                row.returnTexture:Show()
                row.recentIcon:SetText(self.colors.green .. "R" .. self.colors.reset)
            elseif newlyJoined then
                row.returnTexture:Hide()
                row.recentIcon:SetText(self.colors.green .. "+" .. self.colors.reset)
            elseif recentlyPromoted then
                row.returnTexture:Hide()
                row.recentIcon:SetText(self.colors.gold .. "^" .. self.colors.reset)
            else
                row.returnTexture:Hide()
                row.recentIcon:SetText("")
            end
            if self.ui.selectedMember == member.name then row.selectedTexture:Show() else row.selectedTexture:Hide() end
            row:Show()
        else
            row.memberName = nil
            row:Hide()
        end
    end
    self.ui.rosterCount:SetText(tostring(table.getn(list)) .. " members shown")
end

function OTLGM:RefreshRosterPage()
    if not self.ui.rosterSlider then return end
    self:EnsureDB()
    local search = self.ui.rosterSearch and self.ui.rosterSearch:GetText() or ""
    OTLGM_DB.settings.rosterSearch = search
    OTLGM_DB.settings.rosterFilter = self.ui.rosterFilter or "ALL"
    OTLGM_DB.settings.rosterRankFilter = self.ui.rosterRankFilter or ""
    OTLGM_DB.settings.rosterProfessionFilter = self.ui.rosterProfessionFilter or ""
    local list = self:GetSortedRoster(search, self.ui.rosterFilter, self.ui.rosterRankFilter, self.ui.rosterProfessionFilter)
    local maxOffset = math.max(0, table.getn(list) - ROSTER_ROWS)
    self.ui.rosterSlider:SetMinMaxValues(0, maxOffset)
    if (self.ui.rosterOffset or 0) > maxOffset then self.ui.rosterOffset = maxOffset end
    self.ui.rosterSlider:SetValue(self.ui.rosterOffset or 0)

    local key, button
    for key, button in pairs(self.ui.rosterFilterButtons or {}) do SetButtonSelected(button, key == self.ui.rosterFilter) end
    local moreLabels = {
        SAMEZONE = "My Zone", NEARLEVEL = "Near Level", LEVEL60 = "Level 60", NEW14 = "New Members",
        RETURNED14 = "Returned", PROMOTED14 = "Promoted", INACTIVE14 = "Inactive 14d",
        INACTIVE30 = "Inactive 30d", INACTIVE60 = "Inactive 60d", INACTIVE90 = "Inactive 90d",
        LEVEL1_19 = "Levels 1-19", LEVEL20_39 = "Levels 20-39", LEVEL40_59 = "Levels 40-59",
    }
    SetButtonText(self.ui.moreFilterButton, moreLabels[self.ui.rosterFilter] or "More")
    SetButtonSelected(self.ui.moreFilterButton, moreLabels[self.ui.rosterFilter] ~= nil)
    SetButtonText(self.ui.rankFilterButton, self.ui.rosterRankFilter or "All ranks")
    local professionLabel = "All professions"
    if self.ui.rosterProfessionFilter then
        local i
        for i = 1, table.getn(self.professionDefinitions) do
            if self.professionDefinitions[i].key == self.ui.rosterProfessionFilter then professionLabel = self.professionDefinitions[i].label break end
        end
    end
    SetButtonText(self.ui.professionFilterButton, professionLabel)

    local sortKey = OTLGM_DB.settings.rosterSortKey or "RANK"
    local ascending = OTLGM_DB.settings.rosterSortAsc and true or false
    for key, button in pairs(self.ui.rosterSortButtons or {}) do
        local marker = key == sortKey and (ascending and "  ^" or "  v") or ""
        button.text:SetText(button.baseLabel .. marker)
        button.text:SetTextColor(key == sortKey and 1 or 1, key == sortKey and 0.88 or 0.82, key == sortKey and 0.42 or 0)
    end

    local db = self:GetGuildDB()
    local fresh, color = self:GetFreshnessText(db and db.lastScan)
    self.ui.rosterFreshness:SetText(color .. fresh .. self.colors.reset)
    self:RefreshRankPopup()
    self:RefreshProfessionPopup()
    self:RefreshMoreFilterPopup()
    self:RefreshSavedViewsPopup()
    self:RefreshRosterRowsOnly()
    self:RefreshMemberPanel()
end

function OTLGM:ShowRosterTooltip(name, owner)
    local member = self:GetMember(name)
    if not member then return end
    GameTooltip:SetOwner(owner or self.ui.main, "ANCHOR_LEFT")
    local color = member.online and self:GetClassColor(member.class) or self.colors.darkGrey
    GameTooltip:AddLine(color .. member.name .. "|r", 1, 1, 1)
    GameTooltip:AddDoubleLine("Rank", member.rank or "", 1, 1, 1, 1, 0.82, 0.35)
    GameTooltip:AddDoubleLine("Level / Class", tostring(member.level or 0) .. " " .. (member.class or ""), 1, 1, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine("Zone", member.zone or "", 1, 1, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine("Last online", member.lastOnlineText or "Unknown", 1, 1, 1, 0.75, 0.75, 0.75)
    local badgePath, badgeLabel = self:GetMemberBadge(member)
    if badgeLabel then GameTooltip:AddDoubleLine("Guild role", badgeLabel, 1, 1, 1, 0.78, 0.52, 1.0) end
    local professions = self:GetMemberProfessionLabels(member)
    if table.getn(professions) > 0 then
        GameTooltip:AddLine("Professions: " .. table.concat(professions, ", "), 0.75, 0.90, 0.75, true)
        GameTooltip:AddLine("Detected from guild note - unconfirmed.", 0.55, 0.55, 0.55, true)
    end
    if member.joinedAt then GameTooltip:AddLine("Joined (detected): " .. self:Stamp(member.joinedAt), 0.65, 0.65, 0.65) end
    if member.trackedSince and not member.joinedAt then GameTooltip:AddLine("Tracked since: " .. self:Stamp(member.trackedSince), 0.65, 0.65, 0.65) end
    if member.returnedAt and member.returnAfterDays then GameTooltip:AddLine("Recently returned after " .. tostring(member.returnAfterDays) .. " days.", 0.55, 1, 0.55) end
    if member.note and member.note ~= "" then GameTooltip:AddLine("Public note: " .. member.note, 0.85, 0.85, 0.85, true) end
    if self:CanViewOfficerNotes() and member.officerNote and member.officerNote ~= "" then GameTooltip:AddLine("Officer note: " .. member.officerNote, 1, 0.75, 0.3, true) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click: select  |  Right-click: whisper", 0.65, 0.65, 0.65)
    GameTooltip:AddLine("Shift-click: group invite", 0.65, 0.65, 0.65)
    GameTooltip:Show()
end

function OTLGM:SelectRosterMember(name)
    if not self:GetMember(name) then return end
    self.ui.selectedMember = name
    self:RefreshRosterRowsOnly()
    self:RefreshMemberPanel()
end

function OTLGM:WhisperMember(name)
    if not name then return end
    if ChatFrame_SendTell then ChatFrame_SendTell(name)
    elseif ChatFrameEditBox then
        ChatFrameEditBox:Show()
        ChatFrameEditBox:SetText("/w " .. name .. " ")
        ChatFrameEditBox:SetFocus()
    end
end

function OTLGM:InviteMemberToGroup(name)
    if not name then return end
    if InviteByName then InviteByName(name)
    elseif InviteUnit then InviteUnit(name)
    else self:Notify("Group Invite Unavailable", "This client does not expose a group invite function.") end
end

function OTLGM:RefreshMemberPanel()
    if not self.ui.memberPanel then return end
    local member = self.ui.selectedMember and self:GetMember(self.ui.selectedMember)
    local officer = self:IsOfficerMode()
    SetButtonText(self.ui.memberHistoryButton, officer and "History" or "Copy Name")

    if not member then
        self.ui.memberName:SetText(self.colors.gold .. "Select a member" .. self.colors.reset)
        self.ui.memberStatus:SetText("")
        self.ui.memberRank:SetText("")
        self.ui.memberSummary:SetText("Choose a roster row to view member information.")
        self.ui.memberDates:SetText("")
        self.ui.publicNoteEdit:SetText("")
        self.ui.officerNoteEdit:SetText("")
        self.ui.memberHistoryText:SetText("")
        self.ui.memberRoleIcon:Hide()
        local frameIndex
        if officer then
            for frameIndex = 1, table.getn(self.ui.memberOfficerFrames) do self.ui.memberOfficerFrames[frameIndex]:Show() end
            for frameIndex = 1, table.getn(self.ui.memberOfficerButtons) do self.ui.memberOfficerButtons[frameIndex]:Show() end
        else
            for frameIndex = 1, table.getn(self.ui.memberOfficerFrames) do self.ui.memberOfficerFrames[frameIndex]:Hide() end
            for frameIndex = 1, table.getn(self.ui.memberOfficerButtons) do self.ui.memberOfficerButtons[frameIndex]:Hide() end
        end
        SetButtonEnabled(self.ui.whisperButton, false)
        SetButtonEnabled(self.ui.inviteButton, false)
        SetButtonEnabled(self.ui.memberHistoryButton, false)
        local i
        for i = 1, table.getn(self.ui.memberOfficerButtons) do SetButtonEnabled(self.ui.memberOfficerButtons[i], false) end
        return
    end
    local nameColor = member.online and self:GetClassColor(member.class) or self.colors.darkGrey
    self.ui.memberName:SetText(nameColor .. member.name .. self.colors.reset)
    self.ui.memberStatus:SetText(member.online and self.colors.green .. "Online now" .. self.colors.reset or self.colors.grey .. "Last online: " .. (member.lastOnlineText or "Unknown") .. self.colors.reset)
    self.ui.memberRank:SetText(self.colors.gold .. (member.rank or "No rank") .. self.colors.reset)
    local professions = self:GetMemberProfessionLabels(member)
    local levelText = self.colors.gold .. "Level " .. self.colors.white .. tostring(member.level or 0) .. self.colors.reset
    local classText = self:GetClassColor(member.class) .. (member.class or "Unknown") .. self.colors.reset
    local zoneText = self.colors.green .. "Location: " .. self.colors.white .. (member.zone or "Unknown zone") .. self.colors.reset
    local professionText = self.colors.blue .. "Professions: " .. self.colors.white .. (table.getn(professions) > 0 and table.concat(professions, ", ") or "Not listed") .. self.colors.reset
    self.ui.memberSummary:SetText(levelText .. "  " .. classText .. "\n" .. zoneText .. "\n" .. professionText)
    if member.joinedAt then
        self.ui.memberDates:SetText(self.colors.grey .. "Tracked since: " .. self.colors.white .. FormatShortDate(member.joinedAt) .. self.colors.reset)
    else
        self.ui.memberDates:SetText(self.colors.grey .. "Tracked since: " .. self.colors.white .. FormatShortDate(member.trackedSince) .. self.colors.reset)
    end
    ApplyLeadershipIcon(self.ui.memberRoleIcon, member, member.online)
    self.ui.publicNoteEdit:SetText(member.note or "")
    if self:CanViewOfficerNotes() then self.ui.officerNoteEdit:SetText(member.officerNote or "") else self.ui.officerNoteEdit:SetText("Not visible for your rank") end

    local recent = self:GetMemberRecentHistory(member.name, 2)
    local historyLines = {}
    local i, eventInfo
    for i = 1, table.getn(recent) do
        eventInfo = recent[i]
        table.insert(historyLines, date("%d/%m", eventInfo.ts) .. " " .. eventInfo.kind .. ": " .. (eventInfo.detail or ""))
    end
    self.ui.memberHistoryText:SetText(table.getn(historyLines) > 0 and table.concat(historyLines, "\n") or "No individual history recorded yet.")

    SetButtonEnabled(self.ui.whisperButton, true)
    SetButtonEnabled(self.ui.inviteButton, true)
    SetButtonEnabled(self.ui.memberHistoryButton, true)

    if officer then
        for i = 1, table.getn(self.ui.memberOfficerFrames) do self.ui.memberOfficerFrames[i]:Show() end
        for i = 1, table.getn(self.ui.memberOfficerButtons) do self.ui.memberOfficerButtons[i]:Show() end
        SetEditVisual(self.ui.publicNoteEdit, self:CanEditPublicNotes())
        SetEditVisual(self.ui.officerNoteEdit, self:CanEditOfficerNotes())
        SetButtonEnabled(self.ui.saveNotesButton, self:CanUseOfficerAction("NOTE"), "Your guild rank cannot edit notes.")
        SetButtonEnabled(self.ui.promoteButton, self:CanPromoteMembers(), "Your guild rank cannot promote members.")
        SetButtonEnabled(self.ui.demoteButton, self:CanDemoteMembers(), "Your guild rank cannot demote members.")
        SetButtonEnabled(self.ui.removeButton, self:CanRemoveMembers() and member.name ~= UnitName("player"), "Your guild rank cannot remove this member.")
    else
        for i = 1, table.getn(self.ui.memberOfficerFrames) do self.ui.memberOfficerFrames[i]:Hide() end
        for i = 1, table.getn(self.ui.memberOfficerButtons) do self.ui.memberOfficerButtons[i]:Hide() end
        SetEditVisual(self.ui.publicNoteEdit, false)
    end
end

function OTLGM:BuildActivityPage(page)
    CreateText(page, "GameFontNormalLarge", "Guild Activity", 0, -2, 340, "LEFT")
    CreateHelpButton(page, "Activity", "Activity is calculated from successful local roster scans. The heatmap becomes more accurate as scans accumulate. Composition is a light informational view and does not infer combat roles.")
    CreateText(page, "GameFontNormalSmall", "Online peaks, activity by weekday and hour, and a compact guild composition.", 0, -28, 700, "LEFT")

    self.ui.activityCards = {}
    self.ui.activityCards.today = CreateCard(page, 0, -62, 170, 78, "TODAY'S PEAK")
    self.ui.activityCards.week = CreateCard(page, 180, -62, 170, 78, "7-DAY PEAK")
    self.ui.activityCards.all = CreateCard(page, 360, -62, 170, 78, "ALL-TIME PEAK")
    self.ui.activityCards.average = CreateCard(page, 540, -62, 178, 78, "7-DAY AVERAGE")

    local heat = CreateFrame("Frame", nil, page)
    heat:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -154)
    heat:SetWidth(470)
    heat:SetHeight(340)
    CreateBackdrop(heat, 5)
    heat:SetBackdropColor(0.028, 0.025, 0.021, 0.98)
    heat:SetBackdropBorderColor(0.36, 0.28, 0.17, 1)
    CreateText(heat, "GameFontNormal", "ACTIVITY HEATMAP - AVERAGE ONLINE", 12, -10, 456, "LEFT")
    local hours = { "00", "03", "06", "09", "12", "15", "18", "21" }
    local weekdays = { {1,"Mon"}, {2,"Tue"}, {3,"Wed"}, {4,"Thu"}, {5,"Fri"}, {6,"Sat"}, {0,"Sun"} }
    local i, j
    for j = 1, 8 do CreateText(heat, "GameFontNormalSmall", hours[j], 74 + ((j - 1) * 49), -38, 42, "CENTER") end
    self.ui.heatmapCells = {}
    for i = 1, 7 do
        local weekday = weekdays[i][1]
        CreateText(heat, "GameFontNormalSmall", weekdays[i][2], 12, -67 - ((i - 1) * 38), 50, "LEFT")
        self.ui.heatmapCells[weekday] = {}
        for j = 0, 7 do
            local cell = CreateFrame("Frame", nil, heat)
            cell:SetPoint("TOPLEFT", heat, "TOPLEFT", 70 + (j * 49), -58 - ((i - 1) * 38))
            cell:SetWidth(43)
            cell:SetHeight(30)
            CreateBackdrop(cell, 3)
            cell:SetBackdropColor(0.06, 0.05, 0.04, 1)
            cell:SetBackdropBorderColor(0.22, 0.19, 0.15, 1)
            cell.text = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            cell.text:SetPoint("CENTER", cell, "CENTER", 0, 0)
            self.ui.heatmapCells[weekday][j] = cell
        end
    end
    CreateText(heat, "GameFontNormalSmall", "Darker = fewer players. Brighter gold = more players. Empty cells need more scans.", 12, -320, 460, "LEFT"):SetTextColor(0.58, 0.58, 0.58)

    local composition = CreateFrame("Frame", nil, page)
    composition:SetPoint("TOPLEFT", page, "TOPLEFT", 480, -154)
    composition:SetWidth(238)
    composition:SetHeight(340)
    CreateBackdrop(composition, 5)
    composition:SetBackdropColor(0.028, 0.025, 0.021, 0.98)
    composition:SetBackdropBorderColor(0.36, 0.28, 0.17, 1)
    CreateText(composition, "GameFontNormal", "GUILD COMPOSITION", 12, -10, 214, "LEFT")
    self.ui.compositionTotal = CreateWrappedText(composition, "GameFontNormal", "", 12, -38, 214, 202)
    self.ui.compositionOnline = CreateWrappedText(composition, "GameFontNormal", "", 12, -244, 214, 82)
    self.ui.activitySummaryButton = CreateButton(page, nil, "Copy Weekly Summary", 532, -502, 186, 28, function()
        OTLGM:ShowCopyDialog("Weekly Guild Summary", OTLGM:GenerateWeeklySummary())
    end)
    AddButtonIcon(self.ui.activitySummaryButton, "Interface\\Icons\\INV_Scroll_06", 14, true)
end

function OTLGM:RefreshActivityPage()
    if not self.ui.activityCards then return end
    local summary = self:GetActivitySummary(7)
    self.ui.activityCards.today.value:SetText(self.colors.green .. tostring(math.floor(summary.todayPeak or 0)) .. self.colors.reset)
    self.ui.activityCards.today.sub:SetText(summary.todayPeakAt and date("%H:%M", summary.todayPeakAt) or "No sample today")
    self.ui.activityCards.week.value:SetText(self.colors.gold .. tostring(math.floor(summary.periodPeak or 0)) .. self.colors.reset)
    self.ui.activityCards.week.sub:SetText(summary.periodPeakAt and date("%d/%m %H:%M", summary.periodPeakAt) or "No data")
    self.ui.activityCards.all.value:SetText(tostring(math.floor(summary.allTimePeak or 0)))
    self.ui.activityCards.all.sub:SetText(summary.allTimePeakAt and date("%d/%m/%Y %H:%M", summary.allTimePeakAt) or "No data")
    self.ui.activityCards.average.value:SetText(string.format("%.1f", summary.average or 0))
    self.ui.activityCards.average.sub:SetText(tostring(summary.samples or 0) .. " valid samples")

    local matrix, maxValue = self:GetActivityHeatmap()
    local weekday, slot
    for weekday = 0, 6 do
        for slot = 0, 7 do
            local value = matrix[weekday][slot] or 0
            local intensity = maxValue > 0 and (value / maxValue) or 0
            local cell = self.ui.heatmapCells[weekday][slot]
            cell:SetBackdropColor(0.05 + (0.38 * intensity), 0.04 + (0.19 * intensity), 0.025, 1)
            cell:SetBackdropBorderColor(0.24 + (0.55 * intensity), 0.18 + (0.30 * intensity), 0.10, 1)
            cell.text:SetText(value > 0 and tostring(math.floor(value + 0.5)) or "-")
        end
    end

    local total = self:GetComposition(false)
    local online = self:GetComposition(true)
    local classOrder = { "Warrior", "Paladin", "Hunter", "Rogue", "Priest", "Shaman", "Mage", "Warlock", "Druid" }
    local lines = { "ALL MEMBERS - " .. tostring(total.total) }
    local i, className
    for i = 1, table.getn(classOrder) do
        className = classOrder[i]
        table.insert(lines, self:GetClassColor(className) .. className .. self.colors.reset .. ": " .. tostring(total.classes[className] or 0))
    end
    table.insert(lines, "")
    table.insert(lines, self.colors.red .. "Levels 1-19" .. self.colors.reset .. ": " .. tostring(total.levels.low))
    table.insert(lines, self.colors.gold .. "Levels 20-39" .. self.colors.reset .. ": " .. tostring(total.levels.mid))
    table.insert(lines, self.colors.blue .. "Levels 40-59" .. self.colors.reset .. ": " .. tostring(total.levels.high))
    table.insert(lines, self.colors.green .. "Level 60" .. self.colors.reset .. ": " .. tostring(total.levels.max))
    self.ui.compositionTotal:SetText(table.concat(lines, "\n"))

    self.ui.compositionOnline:SetText(
        self.colors.green .. "ONLINE NOW - " .. tostring(online.total) .. self.colors.reset .. "\n" ..
        self.colors.green .. "Level 60 online: " .. tostring(online.levels.max) .. self.colors.reset .. "\n" ..
        self.colors.grey .. "Roster class and level data only." .. self.colors.reset
    )
end

function OTLGM:BuildHistoryPage(page)
    self:EnsureDB()
    CreateText(page, "GameFontNormalLarge", "Guild History", 0, -2, 300, "LEFT")
    CreateHelpButton(page, "Guild History", "History is grouped by date and built from valid local roster comparisons. Character names use class colours. Search can filter by character, actor or details. Mark Reviewed clears the unread badge without deleting events.")
    CreateText(page, "GameFontNormalSmall", "Review joins, departures, rank changes, milestone levels, returns and exact note edits.", 0, -28, 700, "LEFT")

    local search = CreateEditBox(page, "OTLGM_HistorySearch", 0, -54, 234, 28, false)
    search:SetScript("OnTextChanged", function()
        OTLGM_DB.settings.historySearch = this:GetText() or ""
        OTLGM.ui.historyOffset = 0
        OTLGM:RefreshHistoryPage()
    end)
    self.ui.historySearch = search
    local hint = CreateText(page, "GameFontNormalSmall", "Search character, actor or details", 8, -62, 218, "LEFT")
    hint:SetTextColor(0.50, 0.50, 0.50)
    self.ui.historySearchHint = hint
    search:SetScript("OnEditFocusGained", function() if this:GetText() == "" then OTLGM.ui.historySearchHint:Hide() end end)
    search:SetScript("OnEditFocusLost", function() if this:GetText() == "" then OTLGM.ui.historySearchHint:Show() end end)
    CreateButton(page, nil, "X", 240, -54, 28, 28, function()
        OTLGM.ui.historySearch:SetText("")
        OTLGM.ui.historySearch:ClearFocus()
    end)

    self.ui.historyFilter = OTLGM_DB.settings.historyFilter or "ALL"
    self.ui.historyFilterButtons = {}
    local filters = {
        { "ALL", "All", 278, 52 }, { "UNREAD", "Unread", 336, 66 }, { "MEMBERS", "Joined + Left", 408, 106 },
        { "RANK", "Ranks", 520, 62 }, { "MILESTONE", "Milestones", 588, 82 }, { "RETURN", "Returns", 676, 72 },
    }
    local i
    for i = 1, table.getn(filters) do
        local capturedKey = filters[i][1]
        local button = CreateButton(page, nil, filters[i][2], filters[i][3], -54, filters[i][4], 28, function()
            OTLGM.ui.historyFilter = capturedKey
            OTLGM_DB.settings.historyFilter = capturedKey
            OTLGM.ui.historyOffset = 0
            OTLGM:RefreshHistoryPage()
        end)
        self.ui.historyFilterButtons[capturedKey] = button
    end
    self.ui.historyNotesButton = CreateButton(page, nil, "Notes", 0, -88, 66, 27, function()
        OTLGM.ui.historyFilter = "NOTE"
        OTLGM_DB.settings.historyFilter = "NOTE"
        OTLGM.ui.historyOffset = 0
        OTLGM:RefreshHistoryPage()
    end)
    self.ui.historyFilterButtons.NOTE = self.ui.historyNotesButton
    self.ui.historyLevelButton = CreateButton(page, nil, "Level 60", 72, -88, 76, 27, function()
        OTLGM.ui.historyFilter = "LEVEL60"
        OTLGM_DB.settings.historyFilter = "LEVEL60"
        OTLGM.ui.historyOffset = 0
        OTLGM:RefreshHistoryPage()
    end)
    self.ui.historyFilterButtons.LEVEL60 = self.ui.historyLevelButton
    CreateText(page, "GameFontNormalSmall", "ACTIONS", 438, -95, 58, "RIGHT")
    self.ui.historyMarkButton = CreateButton(page, nil, "Mark Reviewed", 506, -88, 116, 27, function() OTLGM:MarkHistoryRead() end)
    AddButtonIcon(self.ui.historyMarkButton, "Interface\\Icons\\INV_Misc_Note_06", 14, true)
    SetButtonActionStyle(self.ui.historyMarkButton, "confirm")
    self.ui.historyCopyButton = CreateButton(page, nil, "Copy Weekly", 630, -88, 118, 27, function()
        OTLGM:ShowCopyDialog("Weekly Guild Summary", OTLGM:GenerateWeeklySummary())
    end)
    AddButtonIcon(self.ui.historyCopyButton, "Interface\\Icons\\INV_Scroll_06", 14, true)
    SetButtonActionStyle(self.ui.historyCopyButton, "utility")

    local header = CreateFrame("Frame", nil, page)
    header:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -122)
    header:SetWidth(726)
    header:SetHeight(22)
    CreateBackdrop(header, 3)
    header:SetBackdropColor(0.11, 0.075, 0.025, 0.98)
    header:SetBackdropBorderColor(0.45, 0.31, 0.13, 1)
    CreateText(header, "GameFontNormalSmall", "Time", 4, -6, 58, "LEFT")
    CreateText(header, "GameFontNormalSmall", "Type", 66, -6, 58, "LEFT")
    CreateText(header, "GameFontNormalSmall", "Character", 128, -6, 112, "LEFT")
    CreateText(header, "GameFontNormalSmall", "Rank / Change", 244, -6, 170, "LEFT")
    CreateText(header, "GameFontNormalSmall", "By", 418, -6, 92, "LEFT")
    CreateText(header, "GameFontNormalSmall", "Details", 514, -6, 200, "LEFT")
    AttachMouseWheel(header, function(delta) OTLGM:ScrollHistory(delta) end)

    local listFrame = CreateFrame("Frame", nil, page)
    listFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -146)
    listFrame:SetWidth(726)
    listFrame:SetHeight(HISTORY_ROWS * ROW_HEIGHT)
    listFrame:SetFrameLevel(page:GetFrameLevel() + 5)
    listFrame:EnableMouse(true)
    AttachMouseWheel(listFrame, function(delta) OTLGM:ScrollHistory(delta) end)
    self.ui.historyListFrame = listFrame
    self.ui.historyNoMatches = CreateWrappedText(listFrame, "GameFontNormal", "No history events match the current search and filters.", 118, -118, 490, 48)
    self.ui.historyNoMatches:SetJustifyH("CENTER")
    self.ui.historyNoMatches:SetTextColor(0.55, 0.55, 0.55)
    self.ui.historyNoMatches:Hide()

    self.ui.historyRows = {}
    for i = 1, HISTORY_ROWS do
        local row = CreateFrame("Frame", nil, listFrame)
        row:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, -((i - 1) * ROW_HEIGHT))
        row:SetWidth(726)
        row:SetHeight(ROW_HEIGHT)
        row:SetFrameLevel(listFrame:GetFrameLevel() + 2)
        row:EnableMouse(true)
        row.stripe = CreateSolidTexture(row, "BACKGROUND", 0.12, 0.12, 0.12, math.mod(i, 2) == 0 and 0.20 or 0.08)
        row.stripe:SetAllPoints(row)
        row.unread = CreateSolidTexture(row, "BORDER", 0.38, 0.22, 0.03, 0.32)
        row.unread:SetAllPoints(row)
        row.unread:Hide()
        row.header = CreateText(row, "GameFontNormal", "", 8, -5, 700, "LEFT")
        row.time = CreateText(row, "GameFontNormalSmall", "", 4, -6, 58, "LEFT")
        row.kind = CreateText(row, "GameFontNormalSmall", "", 66, -6, 58, "LEFT")
        row.name = CreateText(row, "GameFontNormalSmall", "", 128, -6, 112, "LEFT")
        row.rank = CreateText(row, "GameFontNormalSmall", "", 244, -6, 170, "LEFT")
        row.actor = CreateText(row, "GameFontNormalSmall", "", 418, -6, 92, "LEFT")
        row.detail = CreateText(row, "GameFontNormalSmall", "", 514, -6, 200, "LEFT")
        row:SetScript("OnEnter", function()
            if not this.eventInfo or this.eventInfo.header then return end
            local eventInfo = this.eventInfo
            GameTooltip:SetOwner(this, "ANCHOR_LEFT")
            GameTooltip:AddLine((eventInfo.kind or "Event") .. " - " .. (eventInfo.name or ""), 1, 0.82, 0.35)
            if eventInfo.class and eventInfo.class ~= "" then GameTooltip:AddLine("Class: " .. eventInfo.class, 0.85, 0.85, 0.85) end
            if eventInfo.rankBefore and eventInfo.rankBefore ~= "" then GameTooltip:AddLine("Previous rank: " .. eventInfo.rankBefore, 0.85, 0.85, 0.85) end
            if eventInfo.rankAfter and eventInfo.rankAfter ~= "" then GameTooltip:AddLine("New rank: " .. eventInfo.rankAfter, 1, 0.82, 0.35) end
            if eventInfo.milestone then GameTooltip:AddLine("Milestone: level " .. tostring(eventInfo.milestone), 0.45, 0.75, 1) end
            if eventInfo.detail and eventInfo.detail ~= "" then GameTooltip:AddLine(eventInfo.detail, 1, 1, 1, true) end
            if eventInfo.actor and eventInfo.actor ~= "" then GameTooltip:AddLine("By: " .. eventInfo.actor, 0.85, 0.85, 0.85) end
            if eventInfo.source and eventInfo.source ~= "" then GameTooltip:AddLine("Source: " .. eventInfo.source, 0.55, 0.55, 0.55) end
            if not eventInfo.reviewed then GameTooltip:AddLine("Unread change", 1, 0.75, 0.25) end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        AttachMouseWheel(row, function(delta) OTLGM:ScrollHistory(delta) end)
        self.ui.historyRows[i] = row
    end

    self.ui.historySlider = CreateSlider(page, "OTLGM_HistorySlider", 732, -146, HISTORY_ROWS * ROW_HEIGHT, function()
        OTLGM.ui.historyOffset = math.floor(this:GetValue() + 0.5)
        OTLGM:RefreshHistoryRowsOnly()
    end)
    self.ui.historyOffset = 0
    self.ui.historyCount = CreateText(page, "GameFontNormalSmall", "0 events", 0, -512, 300, "LEFT")
    search:SetText(OTLGM_DB.settings.historySearch or "")
    if search:GetText() == "" then hint:Show() else hint:Hide() end
end

function OTLGM:ScrollHistory(delta)
    if not self.ui.historySlider then return end
    local minValue, maxValue = self.ui.historySlider:GetMinMaxValues()
    local offset = (self.ui.historyOffset or 0) - ((delta or 0) * 3)
    if offset < minValue then offset = minValue end
    if offset > maxValue then offset = maxValue end
    self.ui.historyOffset = offset
    self.ui.historySlider:SetValue(offset)
end

function OTLGM:GetHistoryRankText(eventInfo)
    if eventInfo.kind == "RANK" then return (eventInfo.rankBefore or "?") .. " > " .. (eventInfo.rankAfter or "?") end
    if eventInfo.kind == "LEAVE" then return eventInfo.rankBefore or eventInfo.rank or "" end
    if eventInfo.kind == "JOIN" then return eventInfo.rankAfter or eventInfo.rank or "" end
    return eventInfo.rank or ""
end

function OTLGM:RefreshHistoryRowsOnly()
    if not self.ui.historyRows then return end
    local search = self.ui.historySearch and self.ui.historySearch:GetText() or ""
    local list = self:GetHistoryDisplayList(self.ui.historyFilter, search)
    if self.ui.historyFilter == "LEVEL60" then
        local filtered = {}
        local previousDay = nil
        local i, item
        for i = 1, table.getn(list) do
            item = list[i]
            if item.header then
                previousDay = item
            elseif item.kind == "LEVEL" and item.milestone == 60 then
                if previousDay then table.insert(filtered, previousDay) previousDay = nil end
                table.insert(filtered, item)
            end
        end
        list = filtered
    end

    local maxOffset = math.max(0, table.getn(list) - HISTORY_ROWS)
    if self.ui.historyNoMatches then
        if table.getn(list) == 0 then self.ui.historyNoMatches:Show() else self.ui.historyNoMatches:Hide() end
    end
    if (self.ui.historyOffset or 0) > maxOffset then self.ui.historyOffset = maxOffset end
    local i
    for i = 1, HISTORY_ROWS do
        local row = self.ui.historyRows[i]
        local item = list[i + (self.ui.historyOffset or 0)]
        if item then
            row.eventInfo = item
            if item.header then
                row.header:SetText(self.colors.gold .. item.label .. self.colors.reset)
                row.header:Show()
                row.time:Hide() row.kind:Hide() row.name:Hide() row.rank:Hide() row.actor:Hide() row.detail:Hide()
                row.unread:Hide()
                row.stripe:SetTexture(0.08, 0.055, 0.025, 0.82)
            else
                row.header:Hide()
                row.time:Show() row.kind:Show() row.name:Show() row.rank:Show() row.actor:Show() row.detail:Show()
                row.stripe:SetTexture(0.12, 0.12, 0.12, math.mod(i, 2) == 0 and 0.20 or 0.08)
                local color = self.colors.white
                if item.kind == "JOIN" then color = self.colors.green end
                if item.kind == "LEAVE" then color = self.colors.red end
                if item.kind == "RANK" then color = self.colors.gold end
                if item.kind == "LEVEL" then color = self.colors.blue end
                if item.kind == "RETURN" then color = self.colors.green end
                if item.kind == "NOTE" then color = self.colors.grey end
                local classColor = item.class and item.class ~= "" and self:GetClassColor(item.class) or self.colors.white
                row.time:SetText(self.colors.grey .. date("%H:%M", item.ts) .. self.colors.reset)
                row.kind:SetText(color .. item.kind .. self.colors.reset)
                row.name:SetText(classColor .. (item.name or "") .. self.colors.reset)
                row.rank:SetText(item.kind == "RANK" and self.colors.gold .. self:GetHistoryRankText(item) .. self.colors.reset or self:GetHistoryRankText(item))
                row.actor:SetText(item.actor and item.actor ~= "" and self.colors.gold .. item.actor .. self.colors.reset or self.colors.darkGrey .. "Unknown" .. self.colors.reset)
                local detail = item.detail or ""
                if item.kind == "LEVEL" and item.milestone then detail = item.milestone == 60 and "MAX LEVEL 60" or ("Reached " .. tostring(item.milestone)) end
                row.detail:SetText(detail)
                if item.reviewed then row.unread:Hide() else row.unread:Show() end
            end
            row:Show()
        else
            row.eventInfo = nil
            row:Hide()
        end
    end
    self.ui.historyCount:SetText(tostring(table.getn(self:GetFilteredHistory(self.ui.historyFilter, search))) .. " events")
end

function OTLGM:RefreshHistoryPage()
    if not self.ui.historySlider then return end
    OTLGM_DB.settings.historyFilter = self.ui.historyFilter or "ALL"
    OTLGM_DB.settings.historySearch = self.ui.historySearch and self.ui.historySearch:GetText() or ""
    local list = self:GetHistoryDisplayList(self.ui.historyFilter, OTLGM_DB.settings.historySearch)
    if self.ui.historyFilter == "LEVEL60" then
        local filtered = {}
        local previousHeader = nil
        local i, item
        for i = 1, table.getn(list) do
            item = list[i]
            if item.header then previousHeader = item
            elseif item.kind == "LEVEL" and item.milestone == 60 then
                if previousHeader then table.insert(filtered, previousHeader) previousHeader = nil end
                table.insert(filtered, item)
            end
        end
        list = filtered
    end
    local maxOffset = math.max(0, table.getn(list) - HISTORY_ROWS)
    self.ui.historySlider:SetMinMaxValues(0, maxOffset)
    if (self.ui.historyOffset or 0) > maxOffset then self.ui.historyOffset = maxOffset end
    self.ui.historySlider:SetValue(self.ui.historyOffset or 0)
    local key, button
    for key, button in pairs(self.ui.historyFilterButtons or {}) do SetButtonSelected(button, key == self.ui.historyFilter) end
    local unread = self:GetUnreadCount()
    if self.ui.historyMarkButton then
        SetButtonText(self.ui.historyMarkButton, unread > 0 and ("Mark Reviewed (" .. tostring(unread) .. ")") or "Reviewed")
        SetButtonEnabled(self.ui.historyMarkButton, unread > 0, "There are no unread history events.")
        SetButtonActionStyle(self.ui.historyMarkButton, "confirm")
    end
    if self.ui.historySearchHint then
        if OTLGM_DB.settings.historySearch == "" then self.ui.historySearchHint:Show() else self.ui.historySearchHint:Hide() end
    end
    self:RefreshHistoryRowsOnly()
    self:RefreshNavigation()
end

function OTLGM:BuildInactivePage(page)
    CreateText(page, "GameFontNormalLarge", "Inactive Member Review", 0, -2, 360, "LEFT")
    CreateHelpButton(page, "Inactive Review", "This officer-only page groups offline members by inactivity duration. Keep, Review and Exempt are local addon labels and do not change guild rank. Remove always asks for confirmation and still requires the real server permission.")
    CreateText(page, "GameFontNormalSmall", "Review long absences without losing context or accidentally removing protected members.", 0, -28, 700, "LEFT")

    self.ui.inactiveThresholdButtons = {}
    local thresholds = { 14, 30, 60, 90 }
    local i
    for i = 1, 4 do
        local threshold = thresholds[i]
        local button = CreateButton(page, nil, tostring(threshold) .. "d+", (i - 1) * 76, -54, 68, 28, function()
            OTLGM_DB.settings.inactiveThreshold = threshold
            OTLGM.ui.inactiveOffset = 0
            OTLGM:RefreshInactivePage()
        end)
        button.threshold = threshold
        self.ui.inactiveThresholdButtons[i] = button
    end

    self.ui.inactiveStatusButtons = {}
    local statuses = { { "ALL", "All" }, { "REVIEW", "Review" }, { "KEEP", "Keep" }, { "EXEMPT", "Exempt" } }
    for i = 1, 4 do
        local status = statuses[i][1]
        local button = CreateButton(page, nil, statuses[i][2], 340 + ((i - 1) * 86), -54, 78, 28, function()
            OTLGM_DB.settings.inactiveStatus = status
            OTLGM.ui.inactiveOffset = 0
            OTLGM:RefreshInactivePage()
        end)
        button.statusKey = status
        self.ui.inactiveStatusButtons[i] = button
    end

    local header = CreateFrame("Frame", nil, page)
    header:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -96)
    header:SetWidth(510)
    header:SetHeight(22)
    CreateBackdrop(header, 3)
    header:SetBackdropColor(0.11, 0.075, 0.025, 0.98)
    header:SetBackdropBorderColor(0.45, 0.31, 0.13, 1)
    CreateText(header, "GameFontNormalSmall", "Character", 30, -6, 130, "LEFT")
    CreateText(header, "GameFontNormalSmall", "Rank", 164, -6, 130, "LEFT")
    CreateText(header, "GameFontNormalSmall", "Last online", 298, -6, 92, "LEFT")
    CreateText(header, "GameFontNormalSmall", "Review state", 394, -6, 108, "LEFT")
    AttachMouseWheel(header, function(delta) OTLGM:ScrollInactive(delta) end)

    local list = CreateFrame("Frame", nil, page)
    list:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -120)
    list:SetWidth(510)
    list:SetHeight(INACTIVE_ROWS * ROW_HEIGHT)
    list:EnableMouse(true)
    AttachMouseWheel(list, function(delta) OTLGM:ScrollInactive(delta) end)
    self.ui.inactiveListFrame = list
    self.ui.inactiveRows = {}
    for i = 1, INACTIVE_ROWS do
        local row = CreateFrame("Button", nil, list)
        row:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -((i - 1) * ROW_HEIGHT))
        row:SetWidth(510)
        row:SetHeight(ROW_HEIGHT)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        local stripe = CreateSolidTexture(row, "BACKGROUND", 0.12, 0.12, 0.12, math.mod(i, 2) == 0 and 0.20 or 0.08)
        stripe:SetAllPoints(row)
        row.selectedTexture = CreateSolidTexture(row, "BORDER", 0.48, 0.30, 0.05, 0.48)
        row.selectedTexture:SetAllPoints(row)
        row.selectedTexture:Hide()
        row.name = CreateText(row, "GameFontNormalSmall", "", 30, -6, 130, "LEFT")
        row.rank = CreateText(row, "GameFontNormalSmall", "", 164, -6, 130, "LEFT")
        row.lastOnline = CreateText(row, "GameFontNormalSmall", "", 298, -6, 92, "LEFT")
        row.state = CreateText(row, "GameFontNormalSmall", "", 394, -6, 108, "LEFT")
        row:SetScript("OnClick", function()
            if not this.memberName then return end
            if arg1 == "RightButton" then OTLGM:WhisperMember(this.memberName)
            else OTLGM.ui.inactiveSelected = this.memberName OTLGM:RefreshInactivePage() end
        end)
        row:SetScript("OnEnter", function()
            if this.memberName then OTLGM:ShowRosterTooltip(this.memberName, this) end
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        AttachMouseWheel(row, function(delta) OTLGM:ScrollInactive(delta) end)
        self.ui.inactiveRows[i] = row
    end
    self.ui.inactiveSlider = CreateSlider(page, "OTLGM_InactiveSlider", 514, -120, INACTIVE_ROWS * ROW_HEIGHT, function()
        OTLGM.ui.inactiveOffset = math.floor(this:GetValue() + 0.5)
        OTLGM:RefreshInactiveRowsOnly()
    end)
    self.ui.inactiveOffset = 0
    self.ui.inactiveCount = CreateText(page, "GameFontNormalSmall", "0 members", 0, -414, 300, "LEFT")

    local panel = CreateFrame("Frame", nil, page)
    panel:SetPoint("TOPLEFT", page, "TOPLEFT", 540, -96)
    panel:SetWidth(178)
    panel:SetHeight(318)
    CreateBackdrop(panel, 5)
    panel:SetBackdropColor(0.034, 0.029, 0.023, 0.99)
    panel:SetBackdropBorderColor(0.43, 0.31, 0.15, 1)
    self.ui.inactivePanel = panel
    self.ui.inactiveName = CreateText(panel, "GameFontNormalLarge", "Select member", 10, -12, 158, "LEFT")
    self.ui.inactiveInfo = CreateWrappedText(panel, "GameFontHighlightSmall", "", 10, -46, 158, 118)
    self.ui.inactiveState = CreateText(panel, "GameFontNormal", "", 10, -170, 158, "LEFT")
    self.ui.inactiveReviewButton = CreateButton(panel, nil, "Review Later", 10, -198, 158, 26, function()
        if OTLGM.ui.inactiveSelected then OTLGM:SetInactiveStatus(OTLGM.ui.inactiveSelected, "REVIEW") end
    end)
    self.ui.inactiveKeepButton = CreateButton(panel, nil, "Keep", 10, -230, 74, 26, function()
        if OTLGM.ui.inactiveSelected then OTLGM:SetInactiveStatus(OTLGM.ui.inactiveSelected, "KEEP") end
    end)
    self.ui.inactiveExemptButton = CreateButton(panel, nil, "Exempt", 94, -230, 74, 26, function()
        if OTLGM.ui.inactiveSelected then OTLGM:SetInactiveStatus(OTLGM.ui.inactiveSelected, "EXEMPT") end
    end)
    self.ui.inactiveWhisperButton = CreateButton(panel, nil, "Whisper", 10, -262, 74, 26, function()
        if OTLGM.ui.inactiveSelected then OTLGM:WhisperMember(OTLGM.ui.inactiveSelected) end
    end)
    self.ui.inactiveRemoveButton = CreateButton(panel, nil, "Remove", 94, -262, 74, 26, function()
        if not OTLGM.ui.inactiveSelected then return end
        local name = OTLGM.ui.inactiveSelected
        OTLGM:ShowConfirm("Remove Inactive Member", "Remove " .. name .. " from the guild?\n\nReview the member's rank, notes and status before confirming.", "Remove", function()
            OTLGM:RemoveMember(name)
        end)
    end)
end

function OTLGM:ScrollInactive(delta)
    if not self.ui.inactiveSlider then return end
    local minValue, maxValue = self.ui.inactiveSlider:GetMinMaxValues()
    local value = (self.ui.inactiveOffset or 0) - ((delta or 0) * 3)
    if value < minValue then value = minValue end
    if value > maxValue then value = maxValue end
    self.ui.inactiveOffset = value
    self.ui.inactiveSlider:SetValue(value)
end

function OTLGM:RefreshInactiveRowsOnly()
    local threshold = OTLGM_DB.settings.inactiveThreshold or 30
    local status = OTLGM_DB.settings.inactiveStatus or "ALL"
    local list = self:GetInactiveList(threshold, status)
    local maxOffset = math.max(0, table.getn(list) - INACTIVE_ROWS)
    if (self.ui.inactiveOffset or 0) > maxOffset then self.ui.inactiveOffset = maxOffset end
    local i
    for i = 1, INACTIVE_ROWS do
        local row = self.ui.inactiveRows[i]
        local member = list[i + (self.ui.inactiveOffset or 0)]
        if member then
            row.memberName = member.name
            row.name:SetText(self.colors.darkGrey .. member.name .. self.colors.reset)
            row.rank:SetText(self.colors.darkGrey .. (member.rank or "") .. self.colors.reset)
            row.lastOnline:SetText(self.colors.darkGrey .. (member.lastOnlineText or "Offline") .. self.colors.reset)
            local state = self:GetInactiveStatus(member.name)
            row.state:SetText(state ~= "" and self.colors.gold .. state .. self.colors.reset or self.colors.grey .. "Unreviewed" .. self.colors.reset)
            if self.ui.inactiveSelected == member.name then row.selectedTexture:Show() else row.selectedTexture:Hide() end
            row:Show()
        else row.memberName = nil row:Hide() end
    end
    self.ui.inactiveCount:SetText(tostring(table.getn(list)) .. " members at " .. tostring(threshold) .. "d+")
end

function OTLGM:RefreshInactivePage()
    if not self.ui.inactiveSlider then return end
    local threshold = OTLGM_DB.settings.inactiveThreshold or 30
    local status = OTLGM_DB.settings.inactiveStatus or "ALL"
    local list = self:GetInactiveList(threshold, status)
    local maxOffset = math.max(0, table.getn(list) - INACTIVE_ROWS)
    self.ui.inactiveSlider:SetMinMaxValues(0, maxOffset)
    if (self.ui.inactiveOffset or 0) > maxOffset then self.ui.inactiveOffset = maxOffset end
    self.ui.inactiveSlider:SetValue(self.ui.inactiveOffset or 0)
    local i
    for i = 1, table.getn(self.ui.inactiveThresholdButtons) do
        SetButtonSelected(self.ui.inactiveThresholdButtons[i], self.ui.inactiveThresholdButtons[i].threshold == threshold)
    end
    for i = 1, table.getn(self.ui.inactiveStatusButtons) do
        SetButtonSelected(self.ui.inactiveStatusButtons[i], self.ui.inactiveStatusButtons[i].statusKey == status)
    end
    self:RefreshInactiveRowsOnly()

    local member = self.ui.inactiveSelected and self:GetMember(self.ui.inactiveSelected)
    if not member then
        self.ui.inactiveName:SetText("Select member")
        self.ui.inactiveInfo:SetText("Choose an inactive member to review their details and assign a local review state.")
        self.ui.inactiveState:SetText("")
        SetButtonEnabled(self.ui.inactiveReviewButton, false)
        SetButtonEnabled(self.ui.inactiveKeepButton, false)
        SetButtonEnabled(self.ui.inactiveExemptButton, false)
        SetButtonEnabled(self.ui.inactiveWhisperButton, false)
        SetButtonEnabled(self.ui.inactiveRemoveButton, false)
        return
    end
    self.ui.inactiveName:SetText(self.colors.darkGrey .. member.name .. self.colors.reset)
    self.ui.inactiveInfo:SetText(
        (member.rank or "") .. "\nLevel " .. tostring(member.level or 0) .. " " .. (member.class or "") ..
        "\nLast online: " .. (member.lastOnlineText or "Unknown") ..
        "\nPublic note: " .. ((member.note and member.note ~= "") and member.note or "(empty)") ..
        "\nTracked since: " .. FormatShortDate(member.trackedSince)
    )
    local state = self:GetInactiveStatus(member.name)
    self.ui.inactiveState:SetText("Local state: " .. (state ~= "" and self.colors.gold .. state .. self.colors.reset or "Unreviewed"))
    SetButtonEnabled(self.ui.inactiveReviewButton, true)
    SetButtonEnabled(self.ui.inactiveKeepButton, true)
    SetButtonEnabled(self.ui.inactiveExemptButton, true)
    SetButtonEnabled(self.ui.inactiveWhisperButton, true)
    SetButtonEnabled(self.ui.inactiveRemoveButton, self:CanRemoveMembers(), "Your guild rank cannot remove members.")
end

function OTLGM:GetGuildChatMember(sender)
    local member = self:GetMember(sender)
    if not member then
        local db = self:GetGuildDB()
        local shortName = string.lower(string.gsub(sender or "", "%-.*$", ""))
        local name, candidate
        if db then
            for name, candidate in pairs(db.roster or {}) do
                if string.lower(string.gsub(name or "", "%-.*$", "")) == shortName then
                    member = candidate
                    break
                end
            end
        end
    end
    return member
end

function OTLGM:GetGuildChatSenderColor(sender)
    local member = self:GetGuildChatMember(sender)
    if member and member.class and member.class ~= "" then return self:GetClassColor(member.class) end
    return self.colors.white
end

function OTLGM:GetGuildChatRankPresentation(member)
    if not member then return nil, "-", "Unknown rank", 0.65, 0.65, 0.65 end

    local leadershipPath, leadershipLabel = self:GetLeadershipRole(member)
    if leadershipPath then
        return leadershipPath, "", leadershipLabel or member.rank or "Leadership", 1, 1, 1
    end

    local rank = string.lower(member.rank or "")
    if string.find(rank, "core raider", 1, true) or string.find(rank, "the devoted", 1, true) then
        local badgePath, badgeLabel = self:GetMemberBadge(member)
        return badgePath or "Interface\\Icons\\Ability_DualWield", "", badgeLabel or member.rank or "Core Raider", 1, 1, 1
    end
    if string.find(rank, "muted", 1, true) or string.find(rank, "restricted", 1, true) or string.find(rank, "tormented", 1, true) then
        local badgePath, badgeLabel = self:GetMemberBadge(member)
        return badgePath or "Interface\\Icons\\Spell_Shadow_CurseOfTounges", "", badgeLabel or member.rank or "Muted", 1, 1, 1
    end
    if string.find(rank, "loyal", 1, true) then
        return "Interface\\Icons\\INV_Misc_Rune_01", "", member.rank or "Loyal", 1, 1, 1
    end
    if string.find(rank, "guest", 1, true) then
        return nil, "G", member.rank or "Guest", 0.35, 0.95, 0.42
    end
    if string.find(rank, "lion", 1, true) then
        return nil, "L", member.rank or "Lion", 0.35, 0.65, 1.0
    end
    local normalizedRank = string.lower(string.gsub(member.rank or "", "^%s*%d+%s*[-%.:]?%s*", ""))
    if normalizedRank == "raider" then
        return nil, "R", member.rank or "Raider", 0.72, 0.38, 0.95
    end

    local cleaned = string.gsub(member.rank or "", "^%s*%d+%s*[-%.:]?%s*", "")
    local _, _, first = string.find(cleaned, "([%a])")
    local token = first and string.upper(first) or "-"
    return nil, token, member.rank or "Unknown rank", 0.72, 0.72, 0.72
end

function OTLGM:OpenGuildChatWhisper(sender)
    sender = string.gsub(sender or "", "%-.*$", "")
    if sender == "" then return end
    local text = "/w " .. sender .. " "
    if ChatFrame_OpenChat then
        ChatFrame_OpenChat(text)
    elseif ChatFrameEditBox then
        ChatFrameEditBox:Show()
        ChatFrameEditBox:SetText(text)
        ChatFrameEditBox:SetFocus()
    end
end

function OTLGM:InsertGuildChatName(sender)
    if not self.ui or not self.ui.guildChatEdit then return end
    local shortName = string.gsub(sender or "", "%-.*$", "")
    if shortName == "" then return end
    local edit = self.ui.guildChatEdit
    edit:SetFocus()
    local current = edit:GetText() or ""
    local prefix = ""
    if current ~= "" and string.sub(current, -1) ~= " " then prefix = " " end
    local token = prefix .. "[" .. shortName .. "] "
    if edit.Insert then edit:Insert(token) else edit:SetText(current .. token) end
end

function OTLGM:TargetGuildChatMember(sender)
    local shortName = string.gsub(sender or "", "%-.*$", "")
    if shortName == "" then return end
    -- TargetByName prints the client-level red "Unknown unit." error for remote
    -- guild members. Open the reliable roster entry instead of invoking it.
    self:ShowPage("roster")
    self:SelectRosterMember(shortName)
    if self.SetStatus then self:SetStatus("Opened " .. shortName .. " in the guild roster.") end
end

function OTLGM:SaveGuildChatDraft(channel)
    self:EnsureDB()
    channel = channel == "OFFICER" and "OFFICER" or "GUILD"
    OTLGM_DB.settings.guildChatDrafts = OTLGM_DB.settings.guildChatDrafts or { GUILD = "", OFFICER = "" }
    if self.ui and self.ui.guildChatEdit then
        OTLGM_DB.settings.guildChatDrafts[channel] = self.ui.guildChatEdit:GetText() or ""
    end
end

function OTLGM:LoadGuildChatDraft(channel)
    if not self.ui or not self.ui.guildChatEdit then return end
    self:EnsureDB()
    channel = channel == "OFFICER" and "OFFICER" or "GUILD"
    OTLGM_DB.settings.guildChatDrafts = OTLGM_DB.settings.guildChatDrafts or { GUILD = "", OFFICER = "" }
    self.updatingGuildChatDraft = true
    self.ui.guildChatEdit:SetText(OTLGM_DB.settings.guildChatDrafts[channel] or "")
    self.updatingGuildChatDraft = nil
    self.ui.loadedGuildChatDraftChannel = channel
end

function OTLGM:SelectGuildChatChannel(channel)
    local oldChannel = self:GetGuildChatChannel()
    self:SaveGuildChatDraft(oldChannel)
    self.ui.loadedGuildChatDraftChannel = nil
    self:SetGuildChatChannel(channel)
    self:LoadGuildChatDraft(self:GetGuildChatChannel())
end

function OTLGM:IsGuildChatLinkTargetActive()
    if not self.ui or not self.ui.main or not self.ui.guildChatEdit then return false end
    if not self.ui.main:IsVisible() or self.ui.currentPage ~= "guildchat" then return false end
    if self.guildChatEditFocused then return true end
    if IsShiftKeyDown and IsShiftKeyDown() then return true end
    return false
end

function OTLGM:InsertGuildChatLink(link, force)
    if not link or link == "" then return false end
    if not force and not self:IsGuildChatLinkTargetActive() then return false end
    local edit = self.ui and self.ui.guildChatEdit
    if not edit then return false end
    edit:SetFocus()
    self.guildChatEditFocused = true
    local current = edit:GetText() or ""
    local prefix = ""
    if current ~= "" and string.sub(current, -1) ~= " " then prefix = " " end
    if edit.Insert then edit:Insert(prefix .. link .. " ") else edit:SetText(current .. prefix .. link .. " ") end
    self:SaveGuildChatDraft(self:GetGuildChatChannel())
    return true
end

function OTLGM:OpenGuildChatWithLink154(link)
    if not link or link == "" then return false end
    self:ShowPage("guildchat")
    if self.SelectGuildChatView152 then self:SelectGuildChatView152("GUILD") else self:SetGuildChatChannel("GUILD") end
    return self:InsertGuildChatLink(link, true)
end

function OTLGM:EnsureGuildChatLinkHook()
    if ChatEdit_InsertLink and ChatEdit_InsertLink ~= self.guildChatInsertLinkWrapper then
        self.guildChatPreviousInsertLink = ChatEdit_InsertLink
        self.guildChatInsertLinkWrapper = function(link)
            if OTLGM and OTLGM:InsertGuildChatLink(link) then return true end
            if OTLGM and OTLGM.guildChatPreviousInsertLink then
                return OTLGM.guildChatPreviousInsertLink(link)
            end
            return false
        end
        ChatEdit_InsertLink = self.guildChatInsertLinkWrapper
    end

    if HandleModifiedItemClick and HandleModifiedItemClick ~= self.guildChatModifiedItemWrapper then
        self.guildChatPreviousModifiedItemClick = HandleModifiedItemClick
        self.guildChatModifiedItemWrapper = function(link)
            if link and IsShiftKeyDown and IsShiftKeyDown() and OTLGM and OTLGM:InsertGuildChatLink(link) then
                return true
            end
            if OTLGM and OTLGM.guildChatPreviousModifiedItemClick then
                return OTLGM.guildChatPreviousModifiedItemClick(link)
            end
            return false
        end
        HandleModifiedItemClick = self.guildChatModifiedItemWrapper
    end

    -- Vanilla 1.12 bag buttons do not call ChatEdit_InsertLink unless the
    -- Blizzard ChatFrameEditBox is visible. Our chat uses a separate edit box,
    -- so the original click handlers must be intercepted before stack splitting.
    if ContainerFrameItemButton_OnClick and ContainerFrameItemButton_OnClick ~= self.guildChatContainerClickWrapper then
        self.guildChatPreviousContainerClick = ContainerFrameItemButton_OnClick
        self.guildChatContainerClickWrapper = function(button, ignoreModifiers)
            if button == "LeftButton" and not ignoreModifiers and IsShiftKeyDown and IsShiftKeyDown() and OTLGM and OTLGM:IsGuildChatLinkTargetActive() then
                local owner = this
                if owner and owner.GetParent and owner.GetID and GetContainerItemLink then
                    local parent = owner:GetParent()
                    local bag = parent and parent.GetID and parent:GetID() or nil
                    local slot = owner:GetID()
                    local link = bag and slot and GetContainerItemLink(bag, slot) or nil
                    if link and OTLGM:InsertGuildChatLink(link) then
                        if StackSplitFrame then StackSplitFrame:Hide() end
                        return
                    end
                end
            end
            if OTLGM and OTLGM.guildChatPreviousContainerClick then
                return OTLGM.guildChatPreviousContainerClick(button, ignoreModifiers)
            end
        end
        ContainerFrameItemButton_OnClick = self.guildChatContainerClickWrapper
    end

    if KeyRingItemButton_OnClick and KeyRingItemButton_OnClick ~= self.guildChatKeyRingClickWrapper then
        self.guildChatPreviousKeyRingClick = KeyRingItemButton_OnClick
        self.guildChatKeyRingClickWrapper = function(button)
            if button == "LeftButton" and IsShiftKeyDown and IsShiftKeyDown() and OTLGM and OTLGM:IsGuildChatLinkTargetActive() then
                local owner = this
                local slot = owner and owner.GetID and owner:GetID() or nil
                local link = slot and GetContainerItemLink and GetContainerItemLink(KEYRING_CONTAINER, slot) or nil
                if link and OTLGM:InsertGuildChatLink(link) then return end
            end
            if OTLGM and OTLGM.guildChatPreviousKeyRingClick then
                return OTLGM.guildChatPreviousKeyRingClick(button)
            end
        end
        KeyRingItemButton_OnClick = self.guildChatKeyRingClickWrapper
    end

    if PaperDollItemSlotButton_OnClick and PaperDollItemSlotButton_OnClick ~= self.guildChatPaperDollClickWrapper then
        self.guildChatPreviousPaperDollClick = PaperDollItemSlotButton_OnClick
        self.guildChatPaperDollClickWrapper = function(button, ignoreModifiers)
            if button == "LeftButton" and not ignoreModifiers and IsShiftKeyDown and IsShiftKeyDown() and OTLGM and OTLGM:IsGuildChatLinkTargetActive() then
                local owner = this
                local slot = owner and owner.GetID and owner:GetID() or nil
                local link = slot and GetInventoryItemLink and GetInventoryItemLink("player", slot) or nil
                if link and OTLGM:InsertGuildChatLink(link) then return end
            end
            if OTLGM and OTLGM.guildChatPreviousPaperDollClick then
                return OTLGM.guildChatPreviousPaperDollClick(button, ignoreModifiers)
            end
        end
        PaperDollItemSlotButton_OnClick = self.guildChatPaperDollClickWrapper
    end

    if SpellButton_OnClick and SpellButton_OnClick ~= self.guildChatSpellClickWrapper then
        self.guildChatPreviousSpellClick = SpellButton_OnClick
        self.guildChatSpellClickWrapper = function(drag)
            if not drag and IsShiftKeyDown and IsShiftKeyDown() and OTLGM and OTLGM:IsGuildChatLinkTargetActive() then
                local owner = this
                local spellID = owner and owner.GetID and SpellBook_GetSpellID and SpellBook_GetSpellID(owner:GetID()) or nil
                local bookType = SpellBookFrame and SpellBookFrame.bookType or BOOKTYPE_SPELL
                local link = nil
                if spellID and GetSpellLink then
                    local ok, value = pcall(GetSpellLink, spellID, bookType)
                    if ok then link = value end
                end
                if not link and spellID and GetSpellName then
                    local spellName = GetSpellName(spellID, bookType)
                    if spellName and spellName ~= "" then
                        link = "|cff71d5ff|Hspell:" .. tostring(spellID) .. "|h[" .. spellName .. "]|h|r"
                    end
                end
                if link and OTLGM:InsertGuildChatLink(link) then return end
            end
            if OTLGM and OTLGM.guildChatPreviousSpellClick then
                return OTLGM.guildChatPreviousSpellClick(drag)
            end
        end
        SpellButton_OnClick = self.guildChatSpellClickWrapper
    end
end

function OTLGM:FindNextGuildChatURL(text, startAt)
    text = text or ""
    startAt = startAt or 1
    local prefixes = { "https://", "http://", "www." }
    local bestStart, bestPrefix = nil, nil
    local i, found
    for i = 1, table.getn(prefixes) do
        found = string.find(text, prefixes[i], startAt, true)
        if found and (not bestStart or found < bestStart) then
            bestStart = found
            bestPrefix = prefixes[i]
        end
    end
    if not bestStart then return nil end

    local finish = bestStart
    local length = string.len(text)
    while finish <= length do
        local char = string.sub(text, finish, finish)
        if char == " " or char == "\t" or char == "\r" or char == "\n" or char == "|" then break end
        finish = finish + 1
    end
    finish = finish - 1
    if finish < bestStart then return nil end

    local raw = string.sub(text, bestStart, finish)
    local trailing = ""
    while string.len(raw) > 0 do
        local last = string.sub(raw, -1)
        if last == "." or last == "," or last == "!" or last == "?" or last == ";" or last == ":" or last == ")" then
            trailing = last .. trailing
            raw = string.sub(raw, 1, -2)
            finish = finish - 1
        else
            break
        end
    end
    if raw == "" then return nil end
    local copyValue = raw
    if bestPrefix == "www." then copyValue = "https://" .. raw end
    return bestStart, finish, raw, copyValue, trailing
end

function OTLGM:FormatGuildChatDisplayText(text)
    text = text or ""
    local result = ""
    local cursor = 1
    local length = string.len(text)
    while cursor <= length do
        local linkStart = string.find(text, "|H", cursor, true)
        local urlStart, urlEnd, urlDisplay, urlCopy, trailing = self:FindNextGuildChatURL(text, cursor)

        if linkStart and (not urlStart or linkStart < urlStart) then
            local firstClose = string.find(text, "|h", linkStart + 2, true)
            local secondClose = firstClose and string.find(text, "|h", firstClose + 2, true) or nil
            if secondClose then
                result = result .. string.sub(text, cursor, secondClose + 1)
                cursor = secondClose + 2
            else
                result = result .. string.sub(text, cursor)
                break
            end
        elseif urlStart then
            result = result .. string.sub(text, cursor, urlStart - 1)
            result = result .. "|cff69a8ff|Hotlgmurl:" .. urlCopy .. "|h" .. urlDisplay .. "|h|r" .. (trailing or "")
            cursor = urlEnd + 1 + string.len(trailing or "")
        else
            result = result .. string.sub(text, cursor)
            break
        end
    end
    return result
end

function OTLGM:HandleGuildChatHyperlink(link, display, mouseButton)
    if not link or link == "" then return end
    if string.sub(link, 1, 9) == "otlgmurl:" then
        local url = string.sub(link, 10)
        self:ShowCopyDialog("Copy Website Link", url)
        return
    end
    if SetItemRef then
        SetItemRef(link, display or link, mouseButton or "LeftButton")
    elseif ItemRefTooltip and ItemRefTooltip.SetHyperlink then
        ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
        ItemRefTooltip:SetHyperlink(link)
        ItemRefTooltip:Show()
    end
end

function OTLGM:GuildChatTextMentionsPlayer(text)
    local playerName = UnitName and UnitName("player") or ""
    playerName = string.lower(string.gsub(playerName or "", "%-.*$", ""))
    if playerName == "" then return false end
    local lowered = string.lower(StripColorCodes(text or ""))
    return string.find(lowered, playerName, 1, true) ~= nil
end

function OTLGM:GetGuildChatVisibleText(text)
    local visible = StripColorCodes(text or "")
    visible = string.gsub(visible, "|H[^|]+|h([^|]+)|h", "%1")
    visible = string.gsub(visible, "||", "|")
    return visible
end

function OTLGM:GetGuildChatLineCount(text)
    local visible = self:GetGuildChatVisibleText(text)
    local length = string.len(visible or "")
    local charactersPerLine = self:GetGuildChatChannel() == "OFFICER" and 38 or 62
    local lines = math.ceil(length / charactersPerLine)
    if lines < 1 then lines = 1 end
    if lines > 5 then lines = 5 end
    return lines
end

function OTLGM:GetGuildChatTimeSeparator(messages, index)
    if OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.chatTimeSeparators == false then return nil end
    local current = messages[index]
    if not current then return nil end
    if index == 1 then return date("%d/%m/%Y", current.ts or self:Now()) end
    local previous = messages[index - 1]
    if not previous then return nil end
    local currentTs = current.ts or self:Now()
    local previousTs = previous.ts or currentTs
    if date("%Y%m%d", currentTs) ~= date("%Y%m%d", previousTs) then
        return date("%d/%m/%Y", currentTs)
    end
    local gap = currentTs - previousTs
    if gap >= 900 then
        local minutes = math.floor(gap / 60)
        return tostring(minutes) .. " minutes later"
    end
    return nil
end

function OTLGM:GetGuildChatMarkerIndex(messages, channel)
    local markerTime = self.guildChatNewMarker and self.guildChatNewMarker[channel]
    if not markerTime then return nil end
    local i, messageInfo
    for i = 1, table.getn(messages) do
        messageInfo = messages[i]
        if messageInfo and (messageInfo.ts or 0) >= markerTime then return i end
    end
    return nil
end

function OTLGM:GetGuildChatRowMetrics(messages, index, markerIndex)
    local messageInfo = messages[index]
    if not messageInfo then return 24, 1, nil, false end
    local lines = self:GetGuildChatLineCount(messageInfo.text or "")
    local separator = self:GetGuildChatTimeSeparator(messages, index)
    local isMarker = markerIndex and markerIndex == index
    local height = 8 + (lines * 16)
    if separator then height = height + 17 end
    if isMarker then height = height + 9 end
    if height < 26 then height = 26 end
    return height, lines, separator, isMarker
end

function OTLGM:GetGuildChatTopEnd(messages, markerIndex)
    local used = 0
    local count = table.getn(messages)
    local i, height
    for i = 1, count do
        height = self:GetGuildChatRowMetrics(messages, i, markerIndex)
        if used + height > 376 and i > 1 then return i - 1 end
        used = used + height
    end
    return count
end

function OTLGM:GetGuildChatVisibleItems(messages, endIndex, markerIndex)
    local reversed = {}
    local used = 0
    local index, height, lines, separator, isMarker
    for index = endIndex, 1, -1 do
        height, lines, separator, isMarker = self:GetGuildChatRowMetrics(messages, index, markerIndex)
        if used + height > 376 and table.getn(reversed) > 0 then break end
        table.insert(reversed, { index = index, height = height, lines = lines, separator = separator, isMarker = isMarker })
        used = used + height
    end
    local result = {}
    for index = table.getn(reversed), 1, -1 do table.insert(result, reversed[index]) end
    return result
end

function OTLGM:OpenGuildChatNameMenu(sender, owner)
    if not self.ui or not self.ui.chatNameMenu then return end
    local shortName = string.gsub(sender or "", "%-.*$", "")
    if shortName == "" then return end
    local menu = self.ui.chatNameMenu
    menu.targetName = shortName
    menu.title:SetText(self:GetGuildChatSenderColor(shortName) .. shortName .. self.colors.reset)
    menu:ClearAllPoints()
    menu:SetPoint("TOPRIGHT", self.ui.pages.guildchat, "TOPRIGHT", -18, -76)
    menu:Show()
end

function OTLGM:IsOfficerChatMember(member)
    if not member or not member.online then return false end
    local rank = string.lower(member.rank or "")
    if (member.rankIndex or 99) <= 2 then return true end
    if string.find(rank, "guild leader", 1, true) or string.find(rank, "officer", 1, true) or string.find(rank, "raid leader", 1, true) then return true end
    if string.find(rank, "manager", 1, true) or string.find(rank, "inn keeper", 1, true) or string.find(rank, "lionheart", 1, true) then return true end
    if string.find(rank, "helper", 1, true) then return true end
    return false
end

function OTLGM:GetOfficerChatOnlineMembers()
    local result = {}
    local db = self:GetGuildDB()
    if not db then return result end
    local name, member
    for name, member in pairs(db.roster or {}) do
        if self:IsOfficerChatMember(member) then table.insert(result, member) end
    end
    table.sort(result, function(a, b)
        local ar = tonumber(a.rankIndex) or 99
        local br = tonumber(b.rankIndex) or 99
        if ar ~= br then return ar < br end
        return string.lower(a.name or "") < string.lower(b.name or "")
    end)
    return result
end

function OTLGM:RefreshOfficerOnlinePanel()
    local panel = self.ui and self.ui.officerOnlinePanel
    if not panel then return end
    local members = self:GetOfficerChatOnlineMembers()
    panel.sub:SetText(tostring(table.getn(members)) .. " online")
    local i, row, member, badgePath
    for i = 1, table.getn(panel.rows or {}) do
        row = panel.rows[i]
        member = members[i]
        if member then
            row.memberData = member
            badgePath = self:GetMemberBadge(member)
            row.icon:SetTexture(badgePath or "Interface\\Icons\\INV_Shield_06")
            row.icon:SetVertexColor(1, 1, 1)
            row.nameText:SetText(self:GetClassColor(member.class) .. (member.name or "Unknown") .. self.colors.reset)
            row:Show()
        else
            row.memberData = nil
            row:Hide()
        end
    end
    local hidden = table.getn(members) - table.getn(panel.rows or {})
    if hidden > 0 then panel.more:SetText("+" .. tostring(hidden) .. " more") else panel.more:SetText("") end
end

function OTLGM:ApplyGuildChatLayout(channel)
    if not self.ui or not self.ui.chatList then return end
    local compact = channel == "OFFICER" and self:IsOfficerMode() and self.ui.officerOnlinePanel
    local listWidth = compact and 558 or 718
    local headerWidth = compact and 526 or 686
    local rowWidth = compact and 514 or 674
    local messageWidth = compact and 284 or 444
    local separatorWidth = compact and 490 or 650
    local newTextX = compact and 452 or 612
    local sliderX = compact and 532 or 692

    self.ui.chatList:SetWidth(listWidth)
    if self.ui.chatListHeader then self.ui.chatListHeader:SetWidth(headerWidth) end
    if self.ui.chatHeaderMessage then self.ui.chatHeaderMessage:SetWidth(messageWidth) end
    if self.ui.chatEmptyText then self.ui.chatEmptyText:SetWidth(separatorWidth) end
    if self.ui.chatSlider then
        self.ui.chatSlider:ClearAllPoints()
        self.ui.chatSlider:SetPoint("TOPLEFT", self.ui.chatList, "TOPLEFT", sliderX, -28)
    end

    local i, row
    for i = 1, table.getn(self.ui.chatRows or {}) do
        row = self.ui.chatRows[i]
        row:SetWidth(rowWidth)
        row.newLine:SetWidth(rowWidth)
        row.newText:SetWidth(56)
        row.newText.layoutX = newTextX
        row.separatorText:SetWidth(separatorWidth)
        row.messageFrame:SetWidth(messageWidth)
    end

    if compact then
        self.ui.officerOnlinePanel:Show()
        self:RefreshOfficerOnlinePanel()
    else
        self.ui.officerOnlinePanel:Hide()
    end
end

function OTLGM:BuildGuildChatPage(page)
    CreateText(page, "GameFontNormalLarge", "Guild Chat", 0, -2, 300, "LEFT")
    CreateHelpButton(page, "Guild Chat", "Guild and officer messages are mirrored from the real game channels. Shift-click an item or spell while the message box is active to insert its link. Shift-click a sender name to insert [Name] into your draft.")

    self.ui.chatOffsets = self.ui.chatOffsets or { GUILD = 0, OFFICER = 0 }
    self.ui.chatChannelButtons = {}
    self.ui.chatChannelButtons.GUILD = CreateButton(page, nil, "Guild", 0, -34, 128, 30, function()
        OTLGM:SelectGuildChatView152("GUILD")
    end)
    AddButtonIcon(self.ui.chatChannelButtons.GUILD, "Interface\\Icons\\INV_Letter_15", 14, true)
    self.ui.chatChannelButtons.OFFICER = CreateButton(page, nil, "Officer", 136, -34, 128, 30, function()
        OTLGM:SelectGuildChatView152("OFFICER")
    end)
    AddButtonIcon(self.ui.chatChannelButtons.OFFICER, "Interface\\Icons\\INV_Shield_06", 14, true)
    self.ui.chatChannelButtons.BOARD = CreateButton(page, nil, "Guild Board", 272, -34, 128, 30, function()
        OTLGM:SelectGuildChatView152("BOARD")
    end)
    AddButtonIcon(self.ui.chatChannelButtons.BOARD, "Interface\\Icons\\INV_Misc_Note_01", 14, true)
    self.ui.chatUnreadText = CreateText(page, "GameFontNormalSmall", "", 408, -43, 112, "LEFT")
    self.ui.chatUnreadText:SetTextColor(0.66, 0.66, 0.66)
    self.ui.chatNewestButton = CreateButton(page, nil, "Newest", 534, -34, 84, 30, function()
        local channel = OTLGM:GetGuildChatChannel()
        OTLGM.ui.chatOffsets[channel] = 0
        OTLGM:SetGuildChatUnread(channel, 0)
        OTLGM:RefreshGuildChatPage()
        OTLGM:RefreshNavigation()
    end)
    SetButtonActionStyle(self.ui.chatNewestButton, "utility")
    self.ui.chatClearButton = CreateButton(page, nil, "Clear Local", 626, -34, 92, 30, function()
        local channel = OTLGM:GetGuildChatChannel()
        local label = channel == "OFFICER" and "officer" or "guild"
        OTLGM:ShowConfirm("Clear Local Chat History", "Remove the locally stored " .. label .. " chat history from this addon? This does not delete anything from the normal game chat.", "Clear", function()
            OTLGM:ClearGuildChatHistory(channel)
        end)
    end)

    local list = CreateFrame("Frame", nil, page)
    list:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -72)
    list:SetWidth(718)
    list:SetHeight(414)
    CreateBackdrop(list, 5)
    list:SetBackdropColor(0.020, 0.018, 0.015, 0.995)
    list:SetBackdropBorderColor(0.42, 0.30, 0.14, 1)
    self.ui.chatList = list

    local listHeader = CreateFrame("Frame", nil, list)
    listHeader:SetPoint("TOPLEFT", list, "TOPLEFT", 6, -6)
    listHeader:SetWidth(686)
    listHeader:SetHeight(20)
    self.ui.chatListHeader = listHeader
    CreateBackdrop(listHeader, 3)
    listHeader:SetBackdropColor(0.09, 0.06, 0.02, 0.98)
    listHeader:SetBackdropBorderColor(0.42, 0.30, 0.14, 1)
    CreateText(listHeader, "GameFontNormalSmall", "Time", 6, -5, 42, "LEFT")
    CreateText(listHeader, "GameFontNormalSmall", "Rank", 54, -5, 42, "LEFT")
    CreateText(listHeader, "GameFontNormalSmall", "Sender", 100, -5, 120, "LEFT")
    self.ui.chatHeaderMessage = CreateText(listHeader, "GameFontNormalSmall", "Message", 224, -5, 440, "LEFT")

    self.ui.chatRows = {}
    local i
    for i = 1, CHAT_ROWS do
        local row = CreateFrame("Frame", nil, list)
        row:SetWidth(674)
        row:SetHeight(26)
        row:EnableMouse(true)

        row.shade = CreateSolidTexture(row, "BACKGROUND", 0.06, 0.048, 0.032, i / 2 == math.floor(i / 2) and 0.52 or 0.28)
        row.shade:SetAllPoints(row)
        row.mention = CreateSolidTexture(row, "BORDER", 0.42, 0.28, 0.04, 0.28)
        row.mention:SetAllPoints(row)
        row.mention:Hide()
        row.channelAccent = CreateSolidTexture(row, "ARTWORK", 0.18, 0.76, 0.28, 0.95)
        row.channelAccent:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        row.channelAccent:SetWidth(3)
        row.channelAccent:SetHeight(26)
        row.newLine = CreateSolidTexture(row, "ARTWORK", 1.0, 0.82, 0.20, 0.92)
        row.newLine:SetWidth(674)
        row.newLine:SetHeight(1)
        row.newLine:Hide()
        row.newText = CreateText(row, "GameFontNormalSmall", "NEW", 612, -2, 56, "RIGHT")
        row.newText:SetTextColor(1.0, 0.84, 0.24)
        row.newText:Hide()
        row.separatorText = CreateText(row, "GameFontNormalSmall", "", 8, -2, 650, "CENTER")
        row.separatorText:SetTextColor(0.66, 0.58, 0.44)
        row.separatorText:Hide()

        row.timeText = CreateText(row, "GameFontNormal", "", 6, -4, 42, "LEFT")
        ApplyCompatibleChatFont(row.timeText, 0)
        row.timeText:SetTextColor(0.52, 0.52, 0.52)

        row.rankButton = CreateFrame("Button", nil, row)
        row.rankButton:SetWidth(42)
        row.rankButton:SetHeight(20)
        row.rankText = row.rankButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.rankText:SetPoint("CENTER", row.rankButton, "CENTER", 0, 0)
        ApplyCompatibleChatFont(row.rankText, 0)
        row.rankIcon = row.rankButton:CreateTexture(nil, "OVERLAY")
        row.rankIcon:SetWidth(15)
        row.rankIcon:SetHeight(15)
        row.rankIcon:SetPoint("CENTER", row.rankButton, "CENTER", 0, 0)
        row.rankIcon:Hide()
        row.rankButton:SetScript("OnEnter", function()
            if not this.rankLabel then return end
            GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
            GameTooltip:AddLine(this.rankLabel, 1, 0.82, 0.35)
            GameTooltip:Show()
        end)
        row.rankButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

        row.senderButton = CreateFrame("Button", nil, row)
        row.senderButton:SetWidth(120)
        row.senderButton:SetHeight(20)
        row.senderButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row.senderText = row.senderButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.senderText:SetPoint("LEFT", row.senderButton, "LEFT", 0, 0)
        ApplyCompatibleChatFont(row.senderText, 0)
        row.senderText:SetWidth(118)
        row.senderText:SetJustifyH("LEFT")
        row.senderButton:SetScript("OnEnter", function()
            if not this.sender then return end
            GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
            GameTooltip:AddLine(OTLGM:GetGuildChatSenderColor(this.sender) .. string.gsub(this.sender, "%-.*$", "") .. OTLGM.colors.reset, 1, 1, 1)
            local member = OTLGM:GetGuildChatMember(this.sender)
            if member then
                GameTooltip:AddLine("Level " .. tostring(member.level or "?") .. "  -  " .. (member.zone and member.zone ~= "" and member.zone or "Unknown location"), 1.0, 0.82, 0.35)
                GameTooltip:AddLine(member.rank or "Guild member", 0.68, 0.68, 0.68)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Click: whisper", 0.58, 0.58, 0.58)
            GameTooltip:AddLine("Shift-click: insert [Name]", 0.58, 0.58, 0.58)
            GameTooltip:AddLine("Ctrl-click: view in Roster", 0.58, 0.58, 0.58)
            GameTooltip:AddLine("Right-click: more actions", 0.58, 0.58, 0.58)
            GameTooltip:Show()
        end)
        row.senderButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row.senderButton:SetScript("OnClick", function()
            if not this.sender then return end
            if arg1 == "RightButton" then
                OTLGM:OpenGuildChatNameMenu(this.sender, this)
            elseif IsShiftKeyDown and IsShiftKeyDown() then
                OTLGM:InsertGuildChatName(this.sender)
            elseif IsControlKeyDown and IsControlKeyDown() then
                OTLGM:TargetGuildChatMember(this.sender)
            else
                OTLGM:OpenGuildChatWhisper(this.sender)
            end
        end)

        row.messageFrame = CreateFrame("ScrollingMessageFrame", nil, row)
        row.messageFrame:SetWidth(444)
        row.messageFrame:SetHeight(20)
        ApplyCompatibleChatFont(row.messageFrame, 1)
        if row.messageFrame.SetJustifyH then row.messageFrame:SetJustifyH("LEFT") end
        row.messageFrame:SetFading(false)
        row.messageFrame:SetMaxLines(5)
        if row.messageFrame.SetHyperlinksEnabled then row.messageFrame:SetHyperlinksEnabled(true) end
        row.messageFrame:EnableMouse(true)
        row.messageFrame:SetScript("OnHyperlinkClick", function()
            OTLGM:HandleGuildChatHyperlink(arg1, arg2, arg3)
        end)
        AttachMouseWheel(row, function(delta) OTLGM:ScrollGuildChat(delta) end)
        AttachMouseWheel(row.messageFrame, function(delta) OTLGM:ScrollGuildChat(delta) end)
        row:Hide()
        self.ui.chatRows[i] = row
    end

    local officerPanel = CreateFrame("Frame", nil, page)
    officerPanel:SetPoint("TOPLEFT", page, "TOPLEFT", 566, -72)
    officerPanel:SetWidth(152)
    officerPanel:SetHeight(414)
    CreateBackdrop(officerPanel, 5)
    officerPanel:SetBackdropColor(0.022, 0.020, 0.017, 0.995)
    officerPanel:SetBackdropBorderColor(0.48, 0.34, 0.15, 1)
    officerPanel.title = CreateText(officerPanel, "GameFontNormalSmall", "OFFICERS ONLINE", 8, -9, 136, "CENTER")
    officerPanel.title:SetTextColor(1.0, 0.82, 0.34)
    officerPanel.sub = CreateText(officerPanel, "GameFontNormalSmall", "", 8, -27, 136, "CENTER")
    officerPanel.sub:SetTextColor(0.58, 0.58, 0.58)
    officerPanel.rows = {}
    local officerRowIndex
    for officerRowIndex = 1, 12 do
        local officerRow = CreateFrame("Button", nil, officerPanel)
        officerRow:SetPoint("TOPLEFT", officerPanel, "TOPLEFT", 7, -48 - ((officerRowIndex - 1) * 27))
        officerRow:SetWidth(138)
        officerRow:SetHeight(24)
        officerRow:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        officerRow.bg = CreateSolidTexture(officerRow, "BACKGROUND", 0.055, 0.045, 0.030, officerRowIndex / 2 == math.floor(officerRowIndex / 2) and 0.55 or 0.28)
        officerRow.bg:SetAllPoints(officerRow)
        officerRow.icon = officerRow:CreateTexture(nil, "OVERLAY")
        officerRow.icon:SetWidth(16)
        officerRow.icon:SetHeight(16)
        officerRow.icon:SetPoint("LEFT", officerRow, "LEFT", 5, 0)
        officerRow.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        officerRow.nameText = officerRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        officerRow.nameText:SetPoint("LEFT", officerRow, "LEFT", 26, 0)
        officerRow.nameText:SetWidth(106)
        officerRow.nameText:SetJustifyH("LEFT")
        ApplyCompatibleChatFont(officerRow.nameText, 0)
        officerRow:SetScript("OnEnter", function()
            if not this.memberData then return end
            local member = this.memberData
            GameTooltip:SetOwner(this, "ANCHOR_LEFT")
            GameTooltip:AddLine(OTLGM:GetClassColor(member.class) .. (member.name or "Unknown") .. OTLGM.colors.reset, 1, 1, 1)
            GameTooltip:AddLine("Level " .. tostring(member.level or "?") .. "  -  " .. (member.zone and member.zone ~= "" and member.zone or "Unknown location"), 1.0, 0.82, 0.35)
            GameTooltip:AddLine(member.rank or "Officer", 0.68, 0.68, 0.68)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Click: whisper  |  Shift-click: insert [Name]", 0.58, 0.58, 0.58)
            GameTooltip:AddLine("Right-click: more actions", 0.58, 0.58, 0.58)
            GameTooltip:Show()
        end)
        officerRow:SetScript("OnLeave", function() GameTooltip:Hide() end)
        officerRow:SetScript("OnClick", function()
            if not this.memberData then return end
            local name = this.memberData.name
            if arg1 == "RightButton" then
                OTLGM:OpenGuildChatNameMenu(name, this)
            elseif IsShiftKeyDown and IsShiftKeyDown() then
                OTLGM:InsertGuildChatName(name)
            elseif IsControlKeyDown and IsControlKeyDown() then
                OTLGM:TargetGuildChatMember(name)
            else
                OTLGM:OpenGuildChatWhisper(name)
            end
        end)
        officerRow:Hide()
        officerPanel.rows[officerRowIndex] = officerRow
    end
    officerPanel.more = CreateText(officerPanel, "GameFontNormalSmall", "", 8, -378, 136, "CENTER")
    officerPanel.more:SetTextColor(0.60, 0.60, 0.60)
    officerPanel:Hide()
    self.ui.officerOnlinePanel = officerPanel

    self.ui.chatEmptyText = CreateText(list, "GameFontNormal", "No messages recorded yet.", 24, -194, 650, "CENTER")
    self.ui.chatEmptyText:SetTextColor(0.52, 0.52, 0.52)
    self.ui.chatSlider = CreateSlider(list, "OTLGM_ChatSlider", 692, -28, 378, function()
        if OTLGM.updatingChatSlider then return end
        local minValue, maxValue = this:GetMinMaxValues()
        local value = math.floor((arg1 or this:GetValue() or 0) + 0.5)
        OTLGM:SetGuildChatScrollOffset(maxValue - value)
    end)
    AttachMouseWheel(list, function(delta) OTLGM:ScrollGuildChat(delta) end)

    local edit = CreateEditBox(page, "OTLGM_GuildChatEdit", 0, -494, 606, 30, false)
    ApplyCompatibleChatFont(edit, 1)
    edit:SetMaxLetters(240)
    edit:SetScript("OnEditFocusGained", function()
        OTLGM.guildChatEditFocused = true
        OTLGM:EnsureGuildChatLinkHook()
    end)
    edit:SetScript("OnEditFocusLost", function()
        OTLGM.guildChatEditFocused = nil
        OTLGM:SaveGuildChatDraft(OTLGM:GetGuildChatChannel())
    end)
    edit:SetScript("OnTextChanged", function()
        if not OTLGM.updatingGuildChatDraft then OTLGM:SaveGuildChatDraft(OTLGM:GetGuildChatChannel()) end
    end)
    edit:SetScript("OnEnterPressed", function() OTLGM:SendGuildChatFromPage() end)
    self.ui.guildChatEdit = edit
    self:EnsureGuildChatLinkHook()
    self.ui.guildChatSendButton = CreateButton(page, nil, "Send", 614, -494, 104, 30, function()
        OTLGM:SendGuildChatFromPage()
    end)
    SetButtonActionStyle(self.ui.guildChatSendButton, "confirm")

    local menu = CreateFrame("Frame", nil, page)
    menu:SetWidth(170)
    menu:SetHeight(118)
    menu:SetFrameLevel(page:GetFrameLevel() + 60)
    CreateBackdrop(menu, 5)
    menu:SetBackdropColor(0.018, 0.016, 0.013, 1)
    menu:SetBackdropBorderColor(0.65, 0.43, 0.16, 1)
    menu.title = CreateText(menu, "GameFontNormal", "Player", 10, -10, 150, "CENTER")
    menu.whisper = CreateButton(menu, nil, "Whisper", 10, -34, 150, 24, function()
        if OTLGM.ui.chatNameMenu.targetName then OTLGM:OpenGuildChatWhisper(OTLGM.ui.chatNameMenu.targetName) end
        OTLGM.ui.chatNameMenu:Hide()
    end)
    menu.invite = CreateButton(menu, nil, "Invite", 10, -60, 150, 24, function()
        if OTLGM.ui.chatNameMenu.targetName then OTLGM:InviteMemberToGroup(OTLGM.ui.chatNameMenu.targetName) end
        OTLGM.ui.chatNameMenu:Hide()
    end)
    menu.roster = CreateButton(menu, nil, "View in Roster", 10, -86, 150, 24, function()
        local name = OTLGM.ui.chatNameMenu.targetName
        OTLGM.ui.chatNameMenu:Hide()
        if name then
            OTLGM:ShowPage("roster")
            OTLGM:SelectRosterMember(name)
        end
    end)
    menu:Hide()
    self.ui.chatNameMenu = menu
    self:BuildGuildBoardChat152(page)
end

function OTLGM:SelectGuildChatView152(view)
    self:EnsureDB()
    view = view == "BOARD" and "BOARD" or (view == "OFFICER" and "OFFICER" or "GUILD")
    if view == "OFFICER" and not self:IsOfficerMode() then view = "GUILD" end
    OTLGM_DB.settings.guildChatView = view
    if view ~= "BOARD" then self:SetGuildChatChannel(view) end
    self:RefreshGuildChatPage()
    self:RefreshNavigation()
end

function OTLGM:ShowGuildBoardChatLayout152(showBoard)
    local normalFrames = { self.ui.chatList, self.ui.guildChatEdit, self.ui.guildChatSendButton, self.ui.chatNewestButton, self.ui.chatClearButton, self.ui.chatUnreadText }
    local i
    for i = 1, table.getn(normalFrames) do
        if normalFrames[i] then if showBoard then normalFrames[i]:Hide() else normalFrames[i]:Show() end end
    end
    -- Officer Online belongs only to the Officer chat layout. It must never remain above Guild Board.
    if self.ui.officerOnlinePanel and showBoard then self.ui.officerOnlinePanel:Hide() end
    if self.ui.guildBoardChatPanel152 then if showBoard then self.ui.guildBoardChatPanel152:Show() else self.ui.guildBoardChatPanel152:Hide() end end
end

function OTLGM:BuildGuildBoardChat152(page)
    if self.ui.guildBoardChatPanel152 then return end
    local panel = CreateFrame("Frame", nil, page)
    panel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -72)
    panel:SetWidth(718)
    panel:SetHeight(452)
    panel:Hide()

    local list = CreateFrame("Frame", nil, panel)
    list:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    list:SetWidth(334)
    list:SetHeight(452)
    CreateBackdrop(list, 5)
    list:SetBackdropColor(0.020, 0.018, 0.015, 0.995)
    list:SetBackdropBorderColor(0.42, 0.30, 0.14, 1)
    CreateText(list, "GameFontNormalSmall", "GUILD BOARD POSTS", 12, -10, 200, "LEFT")
    self.ui.guildBoardChatRows152 = {}
    local i
    for i = 1, 8 do
        local row = CreateButton(list, nil, "", 10, -34 - ((i - 1) * 37), 314, 35, function()
            if this.postData then OTLGM.ui.guildBoardSelected152 = this.postData.id OTLGM:RefreshGuildBoardChat152() end
        end)
        row.text:Hide()
        row.titleText = CreateText(row, "GameFontNormalSmall", "", 8, -6, 206, "LEFT")
        row.metaText = CreateText(row, "GameFontNormalSmall", "", 218, -6, 86, "RIGHT")
        row.metaText:SetTextColor(0.52, 0.52, 0.52)
        row.previewText = CreateText(row, "GameFontHighlightSmall", "", 8, -20, 296, "LEFT")
        row:Hide()
        self.ui.guildBoardChatRows152[i] = row
    end
    self.ui.guildBoardPrev152 = CreateButton(list, nil, "<", 246, -334, 36, 24, function() OTLGM.ui.guildBoardOffset152 = math.max(0, (OTLGM.ui.guildBoardOffset152 or 0) - 8) OTLGM:RefreshGuildBoardChat152() end)
    self.ui.guildBoardNext152 = CreateButton(list, nil, ">", 288, -334, 36, 24, function() OTLGM.ui.guildBoardOffset152 = (OTLGM.ui.guildBoardOffset152 or 0) + 8 OTLGM:RefreshGuildBoardChat152() end)
    CreateText(list, "GameFontNormalSmall", "NEW COMMUNITY POST", 12, -370, 190, "LEFT")
    self.ui.guildBoardNewEdit152 = CreateEditBox(list, "OTLGM_GuildBoardNew152", 10, -392, 230, 48, true)
    self.ui.guildBoardNewEdit152:SetMaxLetters(180)
    self.ui.guildBoardPostButton152 = CreateButton(list, nil, "Post", 248, -392, 76, 48, function()
        local ok, result = OTLGM:CreatePveBoardPost(OTLGM.ui.guildBoardNewEdit152:GetText())
        if ok then OTLGM.ui.guildBoardNewEdit152:SetText("") OTLGM.ui.guildBoardOffset152 = 0 OTLGM:RefreshGuildBoardChat152()
        else OTLGM:ShowNotice("Guild Board", result or "The post could not be created.") end
    end)
    SetButtonActionStyle(self.ui.guildBoardPostButton152, "confirm")

    local detail = CreateFrame("Frame", nil, panel)
    detail:SetPoint("TOPLEFT", panel, "TOPLEFT", 344, 0)
    detail:SetWidth(374)
    detail:SetHeight(452)
    CreateBackdrop(detail, 5)
    detail:SetBackdropColor(0.026, 0.023, 0.019, 0.995)
    detail:SetBackdropBorderColor(0.42, 0.30, 0.14, 1)
    CreateText(detail, "GameFontNormalSmall", "SELECTED POST", 12, -10, 350, "LEFT")
    self.ui.guildBoardDetailTitle152 = CreateWrappedText(detail, "GameFontNormal", "Select a Guild Board post", 12, -38, 350, 42)
    self.ui.guildBoardDetailMeta152 = CreateText(detail, "GameFontNormalSmall", "", 12, -82, 350, "LEFT")
    self.ui.guildBoardDetailMeta152:SetTextColor(0.58, 0.58, 0.58)
    local body = CreateFrame("Frame", nil, detail)
    body:SetPoint("TOPLEFT", detail, "TOPLEFT", 10, -108)
    body:SetWidth(354)
    body:SetHeight(174)
    CreateBackdrop(body, 4)
    body:SetBackdropColor(0.018, 0.017, 0.015, 1)
    body:SetBackdropBorderColor(0.30, 0.26, 0.18, 1)
    self.ui.guildBoardDetailBody152 = CreateWrappedText(body, "GameFontHighlight", "", 12, -12, 330, 148)
    self.ui.guildBoardReactionButtons152 = {}
    local reactions = { {"HEART", "Heart"}, {"FUNNY", "Funny"}, {"SEEN", "Seen"} }
    for i = 1, table.getn(reactions) do
        local reaction = reactions[i][1]
        local label = reactions[i][2]
        local button = CreateButton(detail, nil, label, 12 + ((i - 1) * 112), -296, 104, 28, function()
            local id = OTLGM.ui.guildBoardSelected152
            if id then OTLGM:SetCommunityReaction("BOARD", id, reaction, false) OTLGM:RefreshGuildBoardChat152() end
        end)
        button:SetScript("OnEnter", function()
            this.hovered = true ApplyButtonVisual(this)
            local id = OTLGM.ui.guildBoardSelected152
            if id then OTLGM:ShowCommunityReactorsTooltip152(this, "BOARD", id, reaction, label) end
        end)
        button:SetScript("OnLeave", function() this.hovered = false ApplyButtonVisual(this) GameTooltip:Hide() end)
        self.ui.guildBoardReactionButtons152[reaction] = button
    end
    self.ui.guildBoardWhisper152 = CreateButton(detail, nil, "Whisper", 12, -342, 82, 28, function()
        local posts = OTLGM:GetPveBoardPosts()
        local i
        for i = 1, table.getn(posts) do if posts[i].id == OTLGM.ui.guildBoardSelected152 then OTLGM:OpenGuildChatWhisper(posts[i].author) return end end
    end)
    self.ui.guildBoardShare152 = CreateButton(detail, nil, "Share to /g", 102, -342, 98, 28, function()
        local posts = OTLGM:GetPveBoardPosts()
        local i
        for i = 1, table.getn(posts) do if posts[i].id == OTLGM.ui.guildBoardSelected152 then OTLGM:SharePveBoardToGuildChat(posts[i]) return end end
    end)
    self.ui.guildBoardDelete152 = CreateButton(detail, nil, "Delete", 208, -342, 78, 28, function()
        local id = OTLGM.ui.guildBoardSelected152
        if id then OTLGM:DeletePveBoardPost(id, false) OTLGM.ui.guildBoardSelected152 = nil OTLGM:RefreshGuildBoardChat152() end
    end)
    SetButtonActionStyle(self.ui.guildBoardDelete152, "danger")
    self.ui.guildBoardSync152 = CreateButton(detail, nil, "Sync", 294, -342, 68, 28, function() OTLGM:RequestPveSync(true) end)
    SetButtonActionStyle(self.ui.guildBoardSync152, "utility")
    self.ui.guildBoardInfo152 = CreateWrappedText(detail, "GameFontNormalSmall", "Guild Board is for community posts. Official leadership announcements are published on Home. Posts expire automatically and reactions are stored per post.", 12, -390, 350, 48)
    self.ui.guildBoardInfo152:SetTextColor(0.56, 0.56, 0.54)
    self.ui.guildBoardChatPanel152 = panel
end

function OTLGM:RefreshGuildBoardChat152()
    if not self.ui.guildBoardChatPanel152 then return end
    local posts = self:GetPveBoardPosts() or {}
    local offset = math.max(0, tonumber(self.ui.guildBoardOffset152) or 0)
    local maximum = math.max(0, table.getn(posts) - 8)
    if offset > maximum then offset = maximum end
    self.ui.guildBoardOffset152 = offset
    local i, row, post
    for i = 1, 8 do
        row = self.ui.guildBoardChatRows152[i]
        post = posts[offset + i]
        if post then
            row.postData = post
            row.titleText:SetText(self:GetClassColor(post.class) .. HomeShort152(post.author or "Unknown", 18) .. self.colors.reset)
            row.metaText:SetText(date("%d %b %H:%M", post.ts or self:Now()))
            row.previewText:SetText(HomeShort152(post.text, 48))
            SetButtonSelected(row, self.ui.guildBoardSelected152 == post.id)
            row:Show()
        else row.postData = nil row:Hide() end
    end
    SetButtonEnabled(self.ui.guildBoardPrev152, offset > 0, "This is the first page.")
    SetButtonEnabled(self.ui.guildBoardNext152, offset < maximum, "There are no more posts.")
    local selected
    for i = 1, table.getn(posts) do if posts[i].id == self.ui.guildBoardSelected152 then selected = posts[i] break end end
    if not selected and posts[1] then selected = posts[1] self.ui.guildBoardSelected152 = selected.id end
    if selected then
        self.ui.guildBoardDetailTitle152:SetText(self.colors.gold .. (selected.author or "Guild Member") .. self.colors.reset)
        self.ui.guildBoardDetailMeta152:SetText(date("%d %B %Y  %H:%M", selected.ts or self:Now()) .. "  |  expires automatically")
        self.ui.guildBoardDetailBody152:SetText(selected.text or "")
        local summary = self:GetCommunityReactionSummary("BOARD", selected.id)
        SetButtonText(self.ui.guildBoardReactionButtons152.HEART, "Heart " .. tostring(summary.HEART or 0))
        SetButtonText(self.ui.guildBoardReactionButtons152.FUNNY, "Funny " .. tostring(summary.FUNNY or 0))
        SetButtonText(self.ui.guildBoardReactionButtons152.SEEN, "Seen " .. tostring(summary.SEEN or 0))
        SetButtonEnabled(self.ui.guildBoardWhisper152, true)
        SetButtonEnabled(self.ui.guildBoardShare152, true)
        SetButtonEnabled(self.ui.guildBoardDelete152, self:CanModifyPveRecord(selected), "Only the author or leadership can delete this post.")
    else
        self.ui.guildBoardDetailTitle152:SetText(self.colors.grey .. "Select a Guild Board post" .. self.colors.reset)
        self.ui.guildBoardDetailMeta152:SetText("")
        self.ui.guildBoardDetailBody152:SetText("No posts are available yet. Create the first community post on the left.")
        SetButtonText(self.ui.guildBoardReactionButtons152.HEART, "Heart 0")
        SetButtonText(self.ui.guildBoardReactionButtons152.FUNNY, "Funny 0")
        SetButtonText(self.ui.guildBoardReactionButtons152.SEEN, "Seen 0")
        SetButtonEnabled(self.ui.guildBoardWhisper152, false, "Select a post first.")
        SetButtonEnabled(self.ui.guildBoardShare152, false, "Select a post first.")
        SetButtonEnabled(self.ui.guildBoardDelete152, false, "Select a post first.")
    end
    self:MarkPveSectionRead("BOARD")
end

function OTLGM:SetGuildChatScrollOffset(value)
    if not self.ui or not self.ui.chatOffsets then return end
    local channel = self:GetGuildChatChannel()
    local messages = self:GetGuildChatMessages(channel)
    local markerIndex = self:GetGuildChatMarkerIndex(messages, channel)
    local topEnd = self:GetGuildChatTopEnd(messages, markerIndex)
    local maximum = math.max(0, table.getn(messages) - topEnd)
    value = math.floor((tonumber(value) or 0) + 0.5)
    if value < 0 then value = 0 end
    if value > maximum then value = maximum end
    if self.ui.chatOffsets[channel] == value then return end
    self.ui.chatOffsets[channel] = value
    self:RefreshGuildChatPage()
end

function OTLGM:ScrollGuildChat(delta)
    if not self.ui or not self.ui.chatOffsets then return end
    local channel = self:GetGuildChatChannel()
    local current = self.ui.chatOffsets[channel] or 0
    if (delta or 0) > 0 then current = current + 2 else current = current - 2 end
    self:SetGuildChatScrollOffset(current)
end

function OTLGM:SendGuildChatFromPage()
    if not self.ui or not self.ui.guildChatEdit then return end
    local text = self.ui.guildChatEdit:GetText() or ""
    local channel = self:GetGuildChatChannel()
    if self:SendGuildChatMessage(text, channel) then
        self.updatingGuildChatDraft = true
        self.ui.guildChatEdit:SetText("")
        self.updatingGuildChatDraft = nil
        OTLGM_DB.settings.guildChatDrafts[channel] = ""
        self.ui.guildChatEdit:ClearFocus()
        self.ui.chatOffsets[channel] = 0
    end
end

function OTLGM:RefreshGuildChatPage()
    if not self.ui or not self.ui.chatRows or not self.ui.chatSlider then return end
    self:EnsureDB()
    self:EnsureGuildChatLinkHook()
    local view = OTLGM_DB.settings.guildChatView or self:GetGuildChatChannel()
    local officer = self:IsOfficerMode()
    if view == "OFFICER" and not officer then view = "GUILD" OTLGM_DB.settings.guildChatView = "GUILD" end
    SetButtonSelected(self.ui.chatChannelButtons.GUILD, view == "GUILD")
    SetButtonSelected(self.ui.chatChannelButtons.OFFICER, view == "OFFICER")
    SetButtonSelected(self.ui.chatChannelButtons.BOARD, view == "BOARD")
    SetButtonEnabled(self.ui.chatChannelButtons.OFFICER, officer, "Officer chat is available only to guild ranks with officer permissions.")
    if view == "BOARD" then
        self:ShowGuildBoardChatLayout152(true)
        self:RefreshGuildBoardChat152()
        return
    end
    self:ShowGuildBoardChatLayout152(false)
    local channel = self:GetGuildChatChannel()
    self:ApplyGuildChatLayout(channel)

    if self.ui.loadedGuildChatDraftChannel ~= channel then self:LoadGuildChatDraft(channel) end
    if self.ui.chatNameMenu then self.ui.chatNameMenu:Hide() end

    self.ui.chatOffsets = self.ui.chatOffsets or { GUILD = 0, OFFICER = 0 }
    local messages = self:GetGuildChatMessages(channel)
    local count = table.getn(messages)
    local markerIndex = self:GetGuildChatMarkerIndex(messages, channel)
    local topEnd = self:GetGuildChatTopEnd(messages, markerIndex)
    local maximum = math.max(0, count - topEnd)
    local offset = self.ui.chatOffsets[channel] or 0
    if offset > maximum then offset = maximum end
    if offset < 0 then offset = 0 end
    self.ui.chatOffsets[channel] = offset

    if self.ui.main and self.ui.main:IsVisible() and self.ui.currentPage == "guildchat" and offset == 0 then
        self:SetGuildChatUnread(channel, 0)
    end

    self.updatingChatSlider = true
    self.ui.chatSlider:SetMinMaxValues(0, maximum)
    self.ui.chatSlider:SetValue(maximum - offset)
    self.updatingChatSlider = nil

    local endIndex = count - offset
    if endIndex < 0 then endIndex = 0 end
    local visibleItems = self:GetGuildChatVisibleItems(messages, endIndex, markerIndex)
    local cursorY = 30
    local rowNumber, item, row, messageInfo, member, badgePath, rankToken, rankLabel, rankR, rankG, rankB
    for rowNumber = 1, CHAT_ROWS do
        row = self.ui.chatRows[rowNumber]
        item = visibleItems[rowNumber]
        if item then
            messageInfo = messages[item.index]
            member = self:GetGuildChatMember(messageInfo.sender)
            badgePath, rankToken, rankLabel, rankR, rankG, rankB = self:GetGuildChatRankPresentation(member)
            row.chatData = messageInfo
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", self.ui.chatList, "TOPLEFT", 8, -cursorY)
            row:SetHeight(item.height)
            row.channelAccent:SetHeight(item.height)
            row.senderButton.sender = messageInfo.sender
            row.rankButton.rankLabel = rankLabel

            local contentY = -3
            if item.separator then
                row.separatorText:ClearAllPoints()
                row.separatorText:SetPoint("TOPLEFT", row, "TOPLEFT", 8, contentY)
                row.separatorText:SetText(item.separator)
                row.separatorText:Show()
                contentY = contentY - 17
            else
                row.separatorText:Hide()
            end
            if item.isMarker then
                row.newLine:ClearAllPoints()
                row.newLine:SetPoint("TOPLEFT", row, "TOPLEFT", 0, contentY - 2)
                row.newLine:Show()
                row.newText:ClearAllPoints()
                row.newText:SetPoint("TOPLEFT", row, "TOPLEFT", row.newText.layoutX or 612, contentY - 1)
                row.newText:Show()
                contentY = contentY - 9
            else
                row.newLine:Hide()
                row.newText:Hide()
            end

            row.timeText:ClearAllPoints()
            row.timeText:SetPoint("TOPLEFT", row, "TOPLEFT", 6, contentY - 1)
            row.timeText:SetText(date("%H:%M", messageInfo.ts or self:Now()))
            row.rankButton:ClearAllPoints()
            row.rankButton:SetPoint("TOPLEFT", row, "TOPLEFT", 54, contentY)
            if OTLGM_DB.settings.chatShowRanks == false then
                row.rankIcon:Hide()
                row.rankText:SetText("")
            elseif badgePath then
                row.rankIcon:SetTexture(badgePath)
                row.rankIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                row.rankIcon:SetVertexColor(1, 1, 1)
                row.rankIcon:Show()
                row.rankText:SetText("")
            else
                row.rankIcon:Hide()
                row.rankText:SetText(rankToken or "-")
                row.rankText:SetTextColor(rankR or 0.72, rankG or 0.72, rankB or 0.72)
            end
            row.senderButton:ClearAllPoints()
            row.senderButton:SetPoint("TOPLEFT", row, "TOPLEFT", 100, contentY)
            row.senderText:SetText(self:GetGuildChatSenderColor(messageInfo.sender) .. string.gsub(messageInfo.sender or "Unknown", "%-.*$", "") .. self.colors.reset)

            row.messageFrame:ClearAllPoints()
            row.messageFrame:SetPoint("TOPLEFT", row, "TOPLEFT", 224, contentY)
            row.messageFrame:SetHeight(item.lines * 16 + 3)
            row.messageFrame:Clear()
            row.messageFrame:AddMessage(self:FormatGuildChatDisplayText(messageInfo.text or ""), 1, 1, 1)

            if messageInfo.channel == "OFFICER" then
                row.channelAccent:SetTexture(0.95, 0.58, 0.16, 0.95)
            else
                row.channelAccent:SetTexture(0.18, 0.78, 0.30, 0.95)
            end
            if OTLGM_DB.settings.chatHighlightMentions ~= false and self:GuildChatTextMentionsPlayer(messageInfo.text or "") then row.mention:Show() else row.mention:Hide() end
            row:Show()
            cursorY = cursorY + item.height
        else
            row.chatData = nil
            row.senderButton.sender = nil
            row.separatorText:Hide()
            row.newLine:Hide()
            row.newText:Hide()
            row.mention:Hide()
            row:Hide()
        end
    end
    if count == 0 then self.ui.chatEmptyText:Show() else self.ui.chatEmptyText:Hide() end

    local guildUnread = self:GetGuildChatUnread("GUILD")
    local officerUnread = officer and self:GetGuildChatUnread("OFFICER") or 0
    SetButtonText(self.ui.chatChannelButtons.GUILD, guildUnread > 0 and ("Guild (" .. tostring(guildUnread) .. ")") or "Guild")
    SetButtonText(self.ui.chatChannelButtons.OFFICER, officerUnread > 0 and ("Officer (" .. tostring(officerUnread) .. ")") or "Officer")
    if officer then
        self.ui.chatUnreadText:SetText(self.colors.green .. "Guild " .. tostring(guildUnread) .. self.colors.reset .. "   " .. self.colors.gold .. "Officer " .. tostring(officerUnread) .. self.colors.reset)
    else
        self.ui.chatUnreadText:SetText(self.colors.green .. "Guild " .. tostring(guildUnread) .. self.colors.reset)
    end
    SetButtonText(self.ui.chatNewestButton, offset > 0 and ("Newest (" .. tostring(offset) .. ")") or "Newest")
    SetButtonEnabled(self.ui.guildChatSendButton, channel ~= "OFFICER" or officer, "Your current guild rank cannot send to officer chat.")
    self:RefreshGuildChatNavigationBadge()
end

local function PveKindLabel(kind)
    if kind == "DUNGEON" then return "Dungeon" end
    if kind == "QUEST" then return "Quest" end
    if kind == "FARM" then return "Farm" end
    if kind == "ATTUNE" then return "Attunement" end
    return "Other"
end

local function PveRoleLabel(role)
    if role == "TANK" then return "Tank" end
    if role == "HEAL" then return "Healer" end
    if role == "DPS" then return "DPS" end
    return "Any role"
end

local function PveKindIcon(kind)
    if kind == "DUNGEON" then return "Interface\\Icons\\INV_Misc_Key_03" end
    if kind == "QUEST" then return "Interface\\Icons\\INV_Scroll_03" end
    if kind == "FARM" then return "Interface\\Icons\\INV_Misc_Herb_07" end
    if kind == "ATTUNE" then return "Interface\\Icons\\INV_Misc_Rune_01" end
    return "Interface\\Icons\\INV_Misc_Map_01"
end

local function PveRoleIcon(role)
    if role == "TANK" then return "Interface\\Icons\\INV_Shield_06" end
    if role == "HEAL" then return "Interface\\Icons\\Spell_Holy_Heal" end
    if role == "DPS" then return "Interface\\Icons\\INV_Sword_04" end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function PveStatusColor(status)
    if status == "FULL" then return OTLGM.colors.red end
    if status == "PENDING" then return OTLGM.colors.gold end
    if status == "CLOSED" then return OTLGM.colors.grey end
    return OTLGM.colors.green
end

function OTLGM:ShowPveSection(section)
    section = section == "GROUPS" and "GROUPS" or (section == "BOARD" and "BOARD" or "RAIDS")
    self:EnsurePveDB()
    OTLGM_DB.settings.pveSection = section
    self:MarkPveSectionRead(section)
    local key, panel
    for key, panel in pairs(self.ui.pvePanels or {}) do
        if key == section then panel:Show() else panel:Hide() end
    end
    local buttonKey, button
    for buttonKey, button in pairs(self.ui.pveTabButtons or {}) do SetButtonSelected(button, buttonKey == section) end
    self:RefreshPvePage()
end

function OTLGM:OpenPveRequestWhisper(request, interested)
    if not request or not request.author then return end
    local name = string.gsub(request.author, "%-.*$", "")
    local text = "/w " .. name .. " "
    if interested then text = text .. "Hi, I'm interested in your " .. (request.activity or "group") .. " request. " end
    if ChatFrame_OpenChat then ChatFrame_OpenChat(text)
    elseif ChatFrameEditBox then ChatFrameEditBox:Show() ChatFrameEditBox:SetText(text) ChatFrameEditBox:SetFocus() end
end

function OTLGM:SelectPveRequest(id)
    self.ui.pveSelectedRequest = id
    self:RefreshPveGroupsPanel()
end

function OTLGM:SetPveGroupOffset(value)
    local requests = self:GetPveRequests()
    local maximum = math.max(0, table.getn(requests) - 5)
    value = math.max(0, math.min(maximum, math.floor(tonumber(value) or 0)))
    self.ui.pveGroupOffset = value
    self:RefreshPveGroupsPanel()
end

function OTLGM:ScrollPveGroups(delta)
    local current = self.ui.pveGroupOffset or 0
    if (delta or 0) > 0 then current = current - 1 else current = current + 1 end
    self:SetPveGroupOffset(current)
end

function OTLGM:SelectPveBoardPost(id)
    self.ui.pveSelectedBoardPost = id
    self:RefreshPveBoardPanel()
end

function OTLGM:BuildPvePage(page)
    CreateText(page, "GameFontNormalLarge", "PvE Hub", 0, -2, 280, "LEFT")
    local testBadge = CreateFrame("Frame", nil, page)
    testBadge:SetPoint("TOPLEFT", page, "TOPLEFT", 104, -1)
    testBadge:SetWidth(104)
    testBadge:SetHeight(24)
    CreateBackdrop(testBadge, 3)
    testBadge:SetBackdropColor(0.12, 0.075, 0.015, 0.98)
    testBadge:SetBackdropBorderColor(0.82, 0.52, 0.14, 1)
    local badgeText = CreateText(testBadge, "GameFontNormalSmall", "GUILD NETWORK", 0, -6, 104, "CENTER")
    badgeText:SetTextColor(1.0, 0.78, 0.28)
    CreateHelpButton(page, "PvE Hub", "This page exchanges Group Finder requests and raid notices between online guildmates who use the addon. Guild Board community posts are now displayed in Guild Chat. Official raid sign-ups remain in Discord.")
    CreateText(page, "GameFontNormalSmall", "Live guild coordination between installed addon copies. No constant roster polling and no public chat spam.", 0, -28, 720, "LEFT")

    self.ui.pveTabButtons = {}
    self.ui.pveTabButtons.RAIDS = CreateButton(page, nil, "Raid Alerts", 0, -52, 142, 30, function() OTLGM:ShowPveSection("RAIDS") end)
    SetButtonActionStyle(self.ui.pveTabButtons.RAIDS, "raid")
    AddButtonIcon(self.ui.pveTabButtons.RAIDS, "Interface\\Icons\\Ability_Warrior_BattleShout", 16, true)
    self.ui.pveTabButtons.GROUPS = CreateButton(page, nil, "Group Finder", 158, -52, 142, 30, function() OTLGM:ShowPveSection("GROUPS") end)
    AddButtonIcon(self.ui.pveTabButtons.GROUPS, "Interface\\Icons\\INV_Misc_Spyglass_03", 16, true)
    self.ui.pveTabButtons.BOARD = CreateButton(page, nil, "Guild Board", 308, -52, 126, 30, function() OTLGM:ShowPveSection("BOARD") end)
    self.ui.pveNetworkText = CreateText(page, "GameFontNormalSmall", "Network: checking", 446, -60, 160, "RIGHT")
    self.ui.pveNetworkText:SetTextColor(0.58, 0.58, 0.58)
    self.ui.pveSyncButton = CreateButton(page, nil, "Sync Now", 614, -52, 104, 30, function()
        OTLGM:RequestAddonUserPing()
        if OTLGM:RequestPveSync(true) then OTLGM:SetStatus("Requesting current PvE Hub data from online addon users...") end
    end)
    SetButtonActionStyle(self.ui.pveSyncButton, "utility")

    self.ui.pvePanels = {}

    -- RAIDS
    local raids = CreateFrame("Frame", nil, page)
    raids:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -92)
    raids:SetWidth(718)
    raids:SetHeight(424)
    self.ui.pvePanels.RAIDS = raids

    local raidCard = CreateFrame("Frame", nil, raids)
    raidCard:SetPoint("TOPLEFT", raids, "TOPLEFT", 0, 0)
    raidCard:SetWidth(718)
    raidCard:SetHeight(122)
    CreateBackdrop(raidCard, 5)
    raidCard:SetBackdropColor(0.055, 0.018, 0.015, 0.99)
    raidCard:SetBackdropBorderColor(0.72, 0.16, 0.10, 1)
    raidCard.raidIcon = raidCard:CreateTexture(nil, "OVERLAY")
    raidCard.raidIcon:SetTexture("Interface\\Icons\\Ability_Warrior_BattleShout")
    raidCard.raidIcon:SetWidth(34)
    raidCard.raidIcon:SetHeight(34)
    raidCard.raidIcon:SetPoint("TOPLEFT", raidCard, "TOPLEFT", 14, -30)
    raidCard.raidIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    CreateText(raidCard, "GameFontNormalSmall", "ACTIVE RAID ALERT - RAIDER / CORE RAIDER NOTIFICATIONS", 14, -10, 480, "LEFT")
    self.ui.pveRaidName = CreateText(raidCard, "GameFontNormalLarge", "No active raid notice", 58, -34, 376, "LEFT")
    self.ui.pveRaidTime = CreateText(raidCard, "GameFontNormal", "", 58, -61, 376, "LEFT")
    self.ui.pveRaidLocation = CreateText(raidCard, "GameFontNormalSmall", "", 58, -84, 376, "LEFT")
    self.ui.pveRaidNote = CreateWrappedText(raidCard, "GameFontHighlightSmall", "", 58, -101, 370, 16)
    self.ui.pveRaidOrganizer = CreateText(raidCard, "GameFontNormalSmall", "", 440, -10, 260, "LEFT")
    self.ui.pveRaidOrganizer:SetTextColor(0.68, 0.68, 0.66)
    self.ui.pveRaidUpcomingButtons155 = {}
    local upcomingIndex155
    for upcomingIndex155 = 1, 3 do
        local capturedUpcoming155 = upcomingIndex155
        local upcomingButton155 = CreateButton(raidCard, nil, "", 440, -28 - ((upcomingIndex155 - 1) * 27), 260, 24, function()
            local target = OTLGM.ui.pveRaidUpcomingButtons155[capturedUpcoming155]
            if target and target.raidData155 then
                OTLGM.ui.pveRaidSelectedId155 = target.raidData155.id
                OTLGM:PopulateRaidEditor155(target.raidData155)
                OTLGM:RefreshPveRaidsPanel()
            end
        end)
        SetButtonActionStyle(upcomingButton155, "utility")
        upcomingButton155:Hide()
        self.ui.pveRaidUpcomingButtons155[upcomingIndex155] = upcomingButton155
    end

    local raidEditor = CreateFrame("Frame", nil, raids)
    raidEditor:SetPoint("TOPLEFT", raids, "TOPLEFT", 0, -132)
    raidEditor:SetWidth(718)
    raidEditor:SetHeight(292)
    CreateBackdrop(raidEditor, 5)
    raidEditor:SetBackdropColor(0.026, 0.023, 0.019, 0.99)
    raidEditor:SetBackdropBorderColor(0.38, 0.28, 0.15, 1)
    self.ui.pveRaidEditor = raidEditor
    CreateText(raidEditor, "GameFontNormal", "Publish Raid Notice", 14, -12, 260, "LEFT")
    self.ui.pveRaidOfficerOnly = CreateWrappedText(raidEditor, "GameFontNormalSmall", "Only leadership can publish or remove a guild raid notice. All addon users can see the active notice. Popup and chat reminders are shown only to Raider and Core Raider ranks.", 14, -40, 680, 48)
    self.ui.pveRaidOfficerOnly:SetTextColor(0.62, 0.62, 0.62)

    CreateText(raidEditor, "GameFontNormalSmall", "RAID", 14, -42, 70, "LEFT")
    self.ui.pveRaidNameEdit = CreateEditBox(raidEditor, "OTLGM_PveRaidName", 14, -58, 302, 30, false)
    self.ui.pveRaidNameEdit:SetMaxLetters(36)
    CreateText(raidEditor, "GameFontNormalSmall", "LOCATION / MEETING POINT", 330, -42, 230, "LEFT")
    self.ui.pveRaidLocationEdit = CreateEditBox(raidEditor, "OTLGM_PveRaidLocation", 330, -58, 374, 30, false)
    self.ui.pveRaidLocationEdit:SetMaxLetters(32)
    CreateText(raidEditor, "GameFontNormalSmall", "DAY / START TIME (SERVER TIME)", 14, -98, 250, "LEFT")
    self.ui.pveRaidDayEdit155 = CreateEditBox(raidEditor, "OTLGM_PveRaidDay155", 14, -114, 42, 30, false)
    self.ui.pveRaidDayEdit155:SetMaxLetters(2)
    self.ui.pveRaidDayEdit155:SetText("0")
    self.ui.pveRaidDayButtons155 = {}
    local dayOptions155 = { {0, "Today"}, {1, "Tomorrow"}, {2, "+2d"} }
    local quickIndex
    for quickIndex = 1, table.getn(dayOptions155) do
        local capturedDay155 = dayOptions155[quickIndex][1]
        self.ui.pveRaidDayButtons155[quickIndex] = CreateButton(raidEditor, nil, dayOptions155[quickIndex][2], 62 + ((quickIndex - 1) * 68), -114, 64, 30, function()
            OTLGM.ui.pveRaidDayEdit155:SetText(tostring(capturedDay155))
        end)
    end
    self.ui.pveRaidHourEdit155 = CreateEditBox(raidEditor, "OTLGM_PveRaidHour155", 270, -114, 42, 30, false)
    self.ui.pveRaidHourEdit155:SetMaxLetters(2)
    CreateText(raidEditor, "GameFontNormalLarge", ":", 315, -118, 10, "CENTER")
    self.ui.pveRaidMinuteEdit155 = CreateEditBox(raidEditor, "OTLGM_PveRaidMinute155", 328, -114, 42, 30, false)
    self.ui.pveRaidMinuteEdit155:SetMaxLetters(2)
    local defaultHour155, defaultMinute155
    if GetGameTime then defaultHour155, defaultMinute155 = GetGameTime() end
    defaultHour155 = tonumber(defaultHour155) or tonumber(date("%H", OTLGM:Now())) or 20
    defaultMinute155 = tonumber(defaultMinute155) or tonumber(date("%M", OTLGM:Now())) or 0
    defaultHour155 = math.mod(defaultHour155 + 1, 24)
    self.ui.pveRaidHourEdit155:SetText(string.format("%02d", defaultHour155))
    self.ui.pveRaidMinuteEdit155:SetText(string.format("%02d", defaultMinute155))
    self.ui.pveRaidRecurring155 = "ONCE"
    self.ui.pveRaidRecurringButton155 = CreateButton(raidEditor, nil, "Once", 382, -114, 92, 30, function()
        OTLGM.ui.pveRaidRecurring155 = OTLGM.ui.pveRaidRecurring155 == "WEEKLY" and "ONCE" or "WEEKLY"
        SetButtonText(OTLGM.ui.pveRaidRecurringButton155, OTLGM.ui.pveRaidRecurring155 == "WEEKLY" and "Weekly" or "Once")
        SetButtonSelected(OTLGM.ui.pveRaidRecurringButton155, OTLGM.ui.pveRaidRecurring155 == "WEEKLY")
    end)
    CreateText(raidEditor, "GameFontNormalSmall", "REMIND MIN", 486, -98, 88, "LEFT")
    self.ui.pveRaidReminderEdit155 = CreateEditBox(raidEditor, "OTLGM_PveRaidReminder155", 486, -114, 54, 30, false)
    self.ui.pveRaidReminderEdit155:SetMaxLetters(4)
    self.ui.pveRaidReminderEdit155:SetText("60")
    CreateText(raidEditor, "GameFontNormalSmall", "before start", 548, -122, 100, "LEFT")

    CreateText(raidEditor, "GameFontNormalSmall", "NOTE", 14, -154, 70, "LEFT")
    self.ui.pveRaidNoteEdit = CreateEditBox(raidEditor, "OTLGM_PveRaidNote", 14, -170, 690, 42, true)
    self.ui.pveRaidNoteEdit:SetMaxLetters(48)

    self.ui.pveRaidPublishButton = CreateButton(raidEditor, nil, "Save Raid", 14, -222, 118, 32, function()
        local ok, result = OTLGM:PublishPveRaidEvent155(
            OTLGM.ui.pveRaidNameEdit:GetText(), OTLGM.ui.pveRaidLocationEdit:GetText(), OTLGM.ui.pveRaidDayEdit155:GetText(),
            OTLGM.ui.pveRaidHourEdit155:GetText(), OTLGM.ui.pveRaidMinuteEdit155:GetText(), OTLGM.ui.pveRaidNoteEdit:GetText(),
            OTLGM.ui.pveRaidRecurring155, OTLGM.ui.pveRaidReminderEdit155:GetText(), OTLGM.ui.pveRaidSelectedId155)
        if ok then
            OTLGM.ui.pveRaidSelectedId155 = result and result.id or nil
            OTLGM:SetStatus("Raid event saved and shared with online addon users.")
            OTLGM:RefreshPvePage()
        else OTLGM:ShowNotice("Raid Event", result or "Could not save the raid event.") end
    end)
    SetButtonActionStyle(self.ui.pveRaidPublishButton, "confirm")
    self.ui.pveRaidNewButton155 = CreateButton(raidEditor, nil, "New Event", 140, -222, 104, 32, function()
        OTLGM.ui.pveRaidSelectedId155 = nil
        OTLGM:PopulateRaidEditor155(nil)
        OTLGM:RefreshPveRaidsPanel()
    end)
    self.ui.pveRaidGuildPostButton = CreateButton(raidEditor, nil, "Post to /g", 252, -222, 104, 32, function()
        if not OTLGM:PostPveRaidToGuildChat(OTLGM.ui.pveRaidSelectedId155) then OTLGM:ShowNotice("Raid Event", "Select or publish a raid event first.") end
    end)
    self.ui.pveRaidReminderNow155 = CreateButton(raidEditor, nil, "Remind Now", 364, -222, 104, 32, function()
        if not OTLGM:SendPveRaidNotice(0, OTLGM.ui.pveRaidSelectedId155) then OTLGM:ShowNotice("Raid Event", "Select or publish a raid event first.") end
    end)
    SetButtonActionStyle(self.ui.pveRaidReminderNow155, "utility")
    self.ui.pveRaidClearButton = CreateButton(raidEditor, nil, "Remove", 476, -222, 104, 32, function()
        local id = OTLGM.ui.pveRaidSelectedId155
        if not id then OTLGM:ShowNotice("Raid Event", "Select an event first.") return end
        OTLGM:ShowConfirm("Remove Raid Event", "Remove this raid event from connected addon users?", "Remove", function()
            OTLGM:ClearPveRaid(id)
            OTLGM.ui.pveRaidSelectedId155 = nil
            OTLGM:PopulateRaidEditor155(nil)
        end)
    end)
    SetButtonActionStyle(self.ui.pveRaidClearButton, "danger")
    self.ui.pveRaidMinutesEdit = self.ui.pveRaidDayEdit155
    self.ui.pveRaidMinuteButtons = self.ui.pveRaidDayButtons155
    self.ui.pveRaidReminderButtons = {}

    self.ui.pveRaidMemberPanel = CreateFrame("Frame", nil, raids)
    self.ui.pveRaidMemberPanel:SetPoint("TOPLEFT", raids, "TOPLEFT", 0, -132)
    self.ui.pveRaidMemberPanel:SetWidth(718)
    self.ui.pveRaidMemberPanel:SetHeight(184)
    CreateBackdrop(self.ui.pveRaidMemberPanel, 5)
    self.ui.pveRaidMemberPanel:SetBackdropColor(0.030, 0.026, 0.020, 0.99)
    self.ui.pveRaidMemberPanel:SetBackdropBorderColor(0.38, 0.28, 0.15, 1)
    CreateText(self.ui.pveRaidMemberPanel, "GameFontNormalLarge", "Raid Information", 14, -14, 300, "LEFT")
    self.ui.pveRaidMemberInfoText = CreateWrappedText(self.ui.pveRaidMemberPanel, "GameFontNormal", "", 14, -46, 684, 122)
    self.ui.pveRaidMemberInfoText:SetTextColor(0.72, 0.72, 0.72)

    -- GROUP FINDER
    local groups = CreateFrame("Frame", nil, page)
    groups:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -92)
    groups:SetWidth(718)
    groups:SetHeight(424)
    groups:Hide()
    self.ui.pvePanels.GROUPS = groups

    local groupForm = CreateFrame("Frame", nil, groups)
    groupForm:SetPoint("TOPLEFT", groups, "TOPLEFT", 0, 0)
    groupForm:SetWidth(278)
    groupForm:SetHeight(424)
    CreateBackdrop(groupForm, 5)
    groupForm:SetBackdropColor(0.030, 0.026, 0.020, 0.99)
    groupForm:SetBackdropBorderColor(0.38, 0.28, 0.15, 1)
    CreateText(groupForm, "GameFontNormal", "Create a Group", 12, -12, 250, "LEFT")
    CreateWrappedText(groupForm, "GameFontNormalSmall", "You become the leader. Choose the activity, your role and the open positions. One active group per character.", 12, -37, 250, 42):SetTextColor(0.66, 0.66, 0.66)

    CreateText(groupForm, "GameFontNormalSmall", "ACTIVITY TYPE", 12, -84, 110, "LEFT")
    self.ui.pveKindButtons = {}
    local kinds = { {"DUNGEON", "Dungeon"}, {"QUEST", "Quest"}, {"FARM", "Farm"}, {"ATTUNE", "Attune"}, {"OTHER", "Other"} }
    local kindIndex
    for kindIndex = 1, table.getn(kinds) do
        local capturedKind = kinds[kindIndex][1]
        local x = 12 + math.mod(kindIndex - 1, 3) * 84
        local y = -102 - math.floor((kindIndex - 1) / 3) * 32
        self.ui.pveKindButtons[capturedKind] = CreateButton(groupForm, nil, kinds[kindIndex][2], x, y, 78, 26, function()
            OTLGM_DB.settings.pveRequestKind = capturedKind
            OTLGM:RefreshPveGroupsPanel()
        end)
    end

    CreateText(groupForm, "GameFontNormalSmall", "YOUR ROLE", 12, -166, 100, "LEFT")
    self.ui.pveRoleButtons = {}
    local roles = { {"ANY", "Any"}, {"TANK", "Tank"}, {"HEAL", "Heal"}, {"DPS", "DPS"} }
    local roleIndex
    for roleIndex = 1, table.getn(roles) do
        local capturedRole = roles[roleIndex][1]
        self.ui.pveRoleButtons[capturedRole] = CreateButton(groupForm, nil, roles[roleIndex][2], 12 + ((roleIndex - 1) * 62), -184, 56, 26, function()
            OTLGM_DB.settings.pveRequestRole = capturedRole
            OTLGM:RefreshPveGroupsPanel()
        end)
    end

    CreateText(groupForm, "GameFontNormalSmall", "DUNGEON / QUEST / ACTIVITY", 12, -220, 244, "LEFT")
    self.ui.pveRequestActivityEdit = CreateEditBox(groupForm, "OTLGM_PveRequestActivity", 12, -236, 254, 28, false)
    self.ui.pveRequestActivityEdit:SetMaxLetters(36)

    CreateText(groupForm, "GameFontNormalSmall", "GROUP", 12, -272, 54, "LEFT")
    CreateText(groupForm, "GameFontNormalSmall", "NEED T", 84, -272, 54, "LEFT")
    CreateText(groupForm, "GameFontNormalSmall", "NEED H", 146, -272, 54, "LEFT")
    CreateText(groupForm, "GameFontNormalSmall", "NEED D", 208, -272, 54, "LEFT")
    self.ui.pveGroupSizeEdit = CreateEditBox(groupForm, "OTLGM_PveGroupSize", 12, -288, 54, 27, false)
    self.ui.pveGroupSizeEdit:SetMaxLetters(2)
    self.ui.pveNeedTankEdit = CreateEditBox(groupForm, "OTLGM_PveNeedTank", 84, -288, 48, 27, false)
    self.ui.pveNeedTankEdit:SetMaxLetters(2)
    self.ui.pveNeedHealEdit = CreateEditBox(groupForm, "OTLGM_PveNeedHeal", 146, -288, 48, 27, false)
    self.ui.pveNeedHealEdit:SetMaxLetters(2)
    self.ui.pveNeedDpsEdit = CreateEditBox(groupForm, "OTLGM_PveNeedDps", 208, -288, 48, 27, false)
    self.ui.pveNeedDpsEdit:SetMaxLetters(2)
    self.ui.pveGroupSizeEdit:SetText(OTLGM_DB.settings.pveGroupSize or "5")
    self.ui.pveNeedTankEdit:SetText(OTLGM_DB.settings.pveNeedTank or "1")
    self.ui.pveNeedHealEdit:SetText(OTLGM_DB.settings.pveNeedHeal or "1")
    self.ui.pveNeedDpsEdit:SetText(OTLGM_DB.settings.pveNeedDps or "3")

    CreateText(groupForm, "GameFontNormalSmall", "SHORT NOTE", 12, -323, 160, "LEFT")
    self.ui.pveRequestNoteEdit = CreateEditBox(groupForm, "OTLGM_PveRequestNote", 12, -339, 254, 40, true)
    self.ui.pveRequestNoteEdit:SetMaxLetters(52)
    self.ui.pveRequestCreateButton = CreateButton(groupForm, nil, "Create / Replace Group", 12, -386, 188, 28, function()
        OTLGM_DB.settings.pveGroupSize = OTLGM.ui.pveGroupSizeEdit:GetText()
        OTLGM_DB.settings.pveNeedTank = OTLGM.ui.pveNeedTankEdit:GetText()
        OTLGM_DB.settings.pveNeedHeal = OTLGM.ui.pveNeedHealEdit:GetText()
        OTLGM_DB.settings.pveNeedDps = OTLGM.ui.pveNeedDpsEdit:GetText()
        local ok, result = OTLGM:CreatePveRequest(
            OTLGM_DB.settings.pveRequestKind,
            OTLGM_DB.settings.pveRequestRole,
            OTLGM.ui.pveRequestActivityEdit:GetText(),
            OTLGM.ui.pveRequestNoteEdit:GetText(),
            OTLGM.ui.pveGroupSizeEdit:GetText(),
            OTLGM.ui.pveNeedTankEdit:GetText(),
            OTLGM.ui.pveNeedHealEdit:GetText(),
            OTLGM.ui.pveNeedDpsEdit:GetText()
        )
        if ok then
            OTLGM:SetStatus("Group shared with online addon users.")
            OTLGM:RefreshPvePage()
        else OTLGM:ShowNotice("Group Finder", result or "Could not create the group.") end
    end)
    SetButtonActionStyle(self.ui.pveRequestCreateButton, "confirm")

    local groupList = CreateFrame("Frame", nil, groups)
    groupList:SetPoint("TOPLEFT", groups, "TOPLEFT", 288, 0)
    groupList:SetWidth(430)
    groupList:SetHeight(424)
    CreateBackdrop(groupList, 5)
    groupList:SetBackdropColor(0.020, 0.018, 0.015, 0.995)
    groupList:SetBackdropBorderColor(0.38, 0.28, 0.15, 1)
    CreateText(groupList, "GameFontNormalSmall", "OPEN GROUPS", 12, -10, 210, "LEFT")
    self.ui.pveRequestCount = CreateText(groupList, "GameFontNormalSmall", "", 232, -10, 184, "RIGHT")
    self.ui.pveRequestCount:SetTextColor(0.58, 0.58, 0.58)
    self.ui.pveRequestRows = {}
    local requestRowIndex
    for requestRowIndex = 1, 5 do
        local row = CreateFrame("Button", nil, groupList)
        row:SetPoint("TOPLEFT", groupList, "TOPLEFT", 10, -34 - ((requestRowIndex - 1) * 54))
        row:SetWidth(390)
        row:SetHeight(50)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        CreateBackdrop(row, 3)
        row:SetBackdropColor(0.045, 0.038, 0.028, 0.92)
        row:SetBackdropBorderColor(0.25, 0.21, 0.15, 1)
        row.kindIcon = row:CreateTexture(nil, "OVERLAY")
        row.kindIcon:SetWidth(30)
        row.kindIcon:SetHeight(30)
        row.kindIcon:SetPoint("LEFT", row, "LEFT", 8, 0)
        row.kindIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.title = CreateText(row, "GameFontNormal", "", 46, -6, 210, "LEFT")
        row.author = CreateText(row, "GameFontNormalSmall", "", 260, -6, 120, "RIGHT")
        row.composition = CreateText(row, "GameFontNormalSmall", "", 46, -25, 244, "LEFT")
        row.composition:SetTextColor(0.72, 0.72, 0.72)
        row.status = CreateText(row, "GameFontNormalSmall", "", 294, -25, 86, "RIGHT")
        row:SetScript("OnEnter", function()
            if not this.requestData then return end
            local request = this.requestData
            GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
            GameTooltip:AddLine(request.activity or "Group", 1, 0.82, 0.35)
            GameTooltip:AddLine(OTLGM:GetClassColor(request.class) .. (request.author or "Unknown") .. OTLGM.colors.reset .. "  Level " .. tostring(request.level or "?"), 1, 1, 1)
            GameTooltip:AddLine("Leader role: " .. PveRoleLabel(request.role) .. "   Group: " .. tostring(request.current or 1) .. "/" .. tostring(request.maxSize or 5), 0.78, 0.78, 0.78)
            GameTooltip:AddLine("Needs: Tank " .. tostring(request.needTank or 0) .. "  Healer " .. tostring(request.needHeal or 0) .. "  DPS " .. tostring(request.needDps or 0), 0.45, 0.85, 0.55)
            if request.note and request.note ~= "" then GameTooltip:AddLine(request.note, 1, 1, 1, true) end
            GameTooltip:AddLine("Click to select  -  Right-click to whisper leader", 0.50, 0.50, 0.50)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        AttachMouseWheel(row, function(delta) OTLGM:ScrollPveGroups(delta) end)
        row:SetScript("OnClick", function()
            if not this.requestData then return end
            if arg1 == "RightButton" then OTLGM:OpenPveRequestWhisper(this.requestData, false)
            else OTLGM:SelectPveRequest(this.requestData.id) end
        end)
        row:Hide()
        self.ui.pveRequestRows[requestRowIndex] = row
    end
    self.ui.pveGroupSlider = CreateSlider(groupList, "OTLGM_PveGroupSlider", 404, -34, 266, function()
        if OTLGM.updatingPveGroupSlider then return end
        local minimum, maximum = this:GetMinMaxValues()
        OTLGM:SetPveGroupOffset((maximum or 0) - (arg1 or 0))
    end)
    AttachMouseWheel(groupList, function(delta) OTLGM:ScrollPveGroups(delta) end)

    local requestActions = CreateFrame("Frame", nil, groupList)
    requestActions:SetPoint("TOPLEFT", groupList, "TOPLEFT", 10, -310)
    requestActions:SetWidth(410)
    requestActions:SetHeight(104)
    CreateBackdrop(requestActions, 3)
    requestActions:SetBackdropColor(0.035, 0.030, 0.023, 0.95)
    requestActions:SetBackdropBorderColor(0.28, 0.23, 0.16, 1)
    self.ui.pveRequestSelectedText = CreateWrappedText(requestActions, "GameFontNormalSmall", "Select a group to interact with it.", 10, -8, 390, 30)

    self.ui.pveJoinControls = {}
    self.ui.pveJoinRoleButtons = {}
    local joinRoles = { {"TANK", "Tank"}, {"HEAL", "Heal"}, {"DPS", "DPS"}, {"ANY", "Any"} }
    for roleIndex = 1, table.getn(joinRoles) do
        local capturedJoinRole = joinRoles[roleIndex][1]
        local button = CreateButton(requestActions, nil, joinRoles[roleIndex][2], 10 + ((roleIndex - 1) * 55), -42, 50, 24, function()
            OTLGM_DB.settings.pveJoinRole = capturedJoinRole
            OTLGM:RefreshPveGroupsPanel()
        end)
        self.ui.pveJoinRoleButtons[capturedJoinRole] = button
        table.insert(self.ui.pveJoinControls, button)
    end
    self.ui.pveJoinNoteEdit = CreateEditBox(requestActions, "OTLGM_PveJoinNote", 232, -42, 168, 24, false)
    self.ui.pveJoinNoteEdit:SetMaxLetters(44)
    table.insert(self.ui.pveJoinControls, self.ui.pveJoinNoteEdit)
    self.ui.pveRequestJoinButton = CreateButton(requestActions, nil, "Request to Join", 10, -72, 124, 24, function()
        local request = OTLGM:GetPveRequestByID(OTLGM.ui.pveSelectedRequest)
        if not request then return end
        local ok, result = OTLGM:ApplyToPveGroup(request.id, OTLGM_DB.settings.pveJoinRole, OTLGM.ui.pveJoinNoteEdit:GetText())
        if ok then OTLGM:SetStatus("Join request sent to " .. (request.author or "the leader") .. ".") OTLGM:RefreshPvePage()
        else OTLGM:ShowNotice("Group Finder", result or "Could not send the join request.") end
    end)
    SetButtonActionStyle(self.ui.pveRequestJoinButton, "confirm")
    table.insert(self.ui.pveJoinControls, self.ui.pveRequestJoinButton)
    self.ui.pveRequestWhisperButton = CreateButton(requestActions, nil, "Whisper", 142, -72, 74, 24, function()
        local request = OTLGM:GetPveRequestByID(OTLGM.ui.pveSelectedRequest)
        if request then OTLGM:OpenPveRequestWhisper(request, false) end
    end)
    table.insert(self.ui.pveJoinControls, self.ui.pveRequestWhisperButton)
    self.ui.pveRequestCancelAppButton = CreateButton(requestActions, nil, "Cancel", 224, -72, 66, 24, function()
        local request = OTLGM:GetPveRequestByID(OTLGM.ui.pveSelectedRequest)
        local application = request and OTLGM:GetOwnPveApplication(request.id)
        if application then OTLGM:CancelPveApplication(application.id) OTLGM:RefreshPvePage() end
    end)
    table.insert(self.ui.pveJoinControls, self.ui.pveRequestCancelAppButton)
    self.ui.pveRequestDeleteButton = CreateButton(requestActions, nil, "Close Group", 298, -72, 102, 24, function()
        local request = OTLGM:GetPveRequestByID(OTLGM.ui.pveSelectedRequest)
        if request then OTLGM:DeletePveRequest(request.id, false) end
    end)

    self.ui.pveLeaderControls = {}
    self.ui.pveApplicantButtons = {}
    for requestRowIndex = 1, 3 do
        local button = CreateButton(requestActions, nil, "", 10 + ((requestRowIndex - 1) * 128), -42, 120, 24, function()
            local app = this.applicationData
            if app then OTLGM.ui.pveSelectedApplication = app.id OTLGM:RefreshPveGroupsPanel() end
        end)
        button.applicationData = nil
        AddButtonIcon(button, PveRoleIcon("ANY"), 14, true)
        self.ui.pveApplicantButtons[requestRowIndex] = button
        table.insert(self.ui.pveLeaderControls, button)
    end
    self.ui.pveApplicantAcceptButton = CreateButton(requestActions, nil, "Accept + Invite", 10, -72, 116, 24, function()
        if OTLGM.ui.pveSelectedApplication then OTLGM:UpdatePveApplication(OTLGM.ui.pveSelectedApplication, "ACCEPTED") OTLGM:RefreshPvePage() end
    end)
    SetButtonActionStyle(self.ui.pveApplicantAcceptButton, "confirm")
    table.insert(self.ui.pveLeaderControls, self.ui.pveApplicantAcceptButton)
    self.ui.pveApplicantDeclineButton = CreateButton(requestActions, nil, "Decline", 134, -72, 74, 24, function()
        if OTLGM.ui.pveSelectedApplication then OTLGM:UpdatePveApplication(OTLGM.ui.pveSelectedApplication, "DECLINED") OTLGM:RefreshPvePage() end
    end)
    table.insert(self.ui.pveLeaderControls, self.ui.pveApplicantDeclineButton)
    self.ui.pveApplicantWhisperButton = CreateButton(requestActions, nil, "Whisper", 216, -72, 74, 24, function()
        local app = OTLGM:GetPveApplicationByID(OTLGM.ui.pveSelectedApplication)
        if app then OTLGM:OpenGuildChatWhisper(app.author) end
    end)
    table.insert(self.ui.pveLeaderControls, self.ui.pveApplicantWhisperButton)
    -- GUILD BOARD
    local board = CreateFrame("Frame", nil, page)
    board:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -92)
    board:SetWidth(718)
    board:SetHeight(424)
    board:Hide()
    self.ui.pvePanels.BOARD = board

    local boardComposer = CreateFrame("Frame", nil, board)
    boardComposer:SetPoint("TOPLEFT", board, "TOPLEFT", 0, 0)
    boardComposer:SetWidth(718)
    boardComposer:SetHeight(82)
    CreateBackdrop(boardComposer, 5)
    boardComposer:SetBackdropColor(0.035, 0.030, 0.023, 0.98)
    boardComposer:SetBackdropBorderColor(0.38, 0.28, 0.15, 1)
    CreateText(boardComposer, "GameFontNormalSmall", "SHARED GUILD BOARD", 12, -10, 220, "LEFT")
    CreateText(boardComposer, "GameFontNormalSmall", "Short notes last 48 hours. Up to three active posts per character.", 240, -10, 466, "RIGHT")
    self.ui.pveBoardEdit = CreateEditBox(boardComposer, "OTLGM_PveBoardEdit", 12, -32, 584, 36, false)
    self.ui.pveBoardEdit:SetMaxLetters(130)
    self.ui.pveBoardPostButton = CreateButton(boardComposer, nil, "Post", 606, -32, 100, 36, function()
        local ok, result = OTLGM:CreatePveBoardPost(OTLGM.ui.pveBoardEdit:GetText())
        if ok then OTLGM.ui.pveBoardEdit:SetText("") OTLGM:SetStatus("Board post shared with online addon users.") OTLGM:RefreshPvePage()
        else OTLGM:ShowNotice("Guild Board", result or "Could not create the post.") end
    end)
    SetButtonActionStyle(self.ui.pveBoardPostButton, "confirm")

    local boardList = CreateFrame("Frame", nil, board)
    boardList:SetPoint("TOPLEFT", board, "TOPLEFT", 0, -92)
    boardList:SetWidth(718)
    boardList:SetHeight(332)
    CreateBackdrop(boardList, 5)
    boardList:SetBackdropColor(0.020, 0.018, 0.015, 0.995)
    boardList:SetBackdropBorderColor(0.38, 0.28, 0.15, 1)
    self.ui.pveBoardRows = {}
    local boardIndex
    for boardIndex = 1, 7 do
        local row = CreateFrame("Button", nil, boardList)
        row:SetPoint("TOPLEFT", boardList, "TOPLEFT", 10, -10 - ((boardIndex - 1) * 40))
        row:SetWidth(698)
        row:SetHeight(36)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row.bg = CreateSolidTexture(row, "BACKGROUND", 0.055, 0.045, 0.030, boardIndex / 2 == math.floor(boardIndex / 2) and 0.55 or 0.28)
        row.bg:SetAllPoints(row)
        row.timeText = CreateText(row, "GameFontNormalSmall", "", 6, -10, 72, "LEFT")
        row.authorText = CreateText(row, "GameFontNormal", "", 82, -9, 116, "LEFT")
        row.messageText = CreateText(row, "GameFontHighlightSmall", "", 202, -9, 486, "LEFT")
        row:SetScript("OnEnter", function()
            if not this.postData then return end
            GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
            GameTooltip:AddLine(OTLGM:GetClassColor(this.postData.class) .. (this.postData.author or "Unknown") .. OTLGM.colors.reset .. "  Level " .. tostring(this.postData.level or "?"), 1, 1, 1)
            GameTooltip:AddLine(this.postData.text or "", 1, 1, 1, true)
            GameTooltip:AddLine("Click to select  -  Right-click to whisper", 0.58, 0.58, 0.58)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row:SetScript("OnClick", function()
            if not this.postData then return end
            if arg1 == "RightButton" then OTLGM:OpenGuildChatWhisper(this.postData.author)
            else OTLGM:SelectPveBoardPost(this.postData.id) end
        end)
        row:Hide()
        self.ui.pveBoardRows[boardIndex] = row
    end
    self.ui.pveBoardSelected = CreateText(boardList, "GameFontNormalSmall", "Select a post for actions.", 10, -294, 420, "LEFT")
    self.ui.pveBoardWhisperButton = CreateButton(boardList, nil, "Whisper", 478, -288, 96, 30, function()
        local post = OTLGM:GetPveBoardPostByID(OTLGM.ui.pveSelectedBoardPost)
        if post then OTLGM:OpenGuildChatWhisper(post.author) end
    end)
    self.ui.pveBoardDeleteButton = CreateButton(boardList, nil, "Delete", 584, -288, 124, 30, function()
        local post = OTLGM:GetPveBoardPostByID(OTLGM.ui.pveSelectedBoardPost)
        if post then OTLGM:DeletePveBoardPost(post.id, false) end
    end)

    self:ShowPveSection(OTLGM_DB.settings.pveSection or "RAIDS")
end

function OTLGM:GetPveRequestByID(id)
    if not id then return nil end
    local requests = self:GetPveRequests()
    local i
    for i = 1, table.getn(requests) do if requests[i].id == id then return requests[i] end end
    return nil
end

function OTLGM:GetPveBoardPostByID(id)
    if not id then return nil end
    local posts = self:GetPveBoardPosts()
    local i
    for i = 1, table.getn(posts) do if posts[i].id == id then return posts[i] end end
    return nil
end

function OTLGM:PopulateRaidEditor155(raid)
    if not self.ui or not self.ui.pveRaidNameEdit then return end
    self.ui.pveRaidEditorLoadedId155 = raid and raid.id or nil
    self.ui.pveRaidNameEdit:SetText(raid and (raid.name or "") or "")
    self.ui.pveRaidLocationEdit:SetText(raid and (raid.location or "") or "")
    self.ui.pveRaidNoteEdit:SetText(raid and (raid.note or "") or "")
    local dayOffset = 0
    if raid and raid.startTs then dayOffset = math.max(0, math.min(28, math.floor(((raid.startTs - self:Now()) + 86399) / 86400))) end
    if self.ui.pveRaidDayEdit155 then self.ui.pveRaidDayEdit155:SetText(tostring(dayOffset)) end
    local hour = raid and tonumber(raid.stHour) or nil
    local minute = raid and tonumber(raid.stMinute) or nil
    if not hour and raid then
        local _, _, parsedHour, parsedMinute = string.find(raid.serverTime or "", "(%d%d):(%d%d)")
        hour = tonumber(parsedHour); minute = tonumber(parsedMinute)
    end
    if not hour then if GetGameTime then hour, minute = GetGameTime() end hour = math.mod((tonumber(hour) or 19) + 1, 24) end
    if self.ui.pveRaidHourEdit155 then self.ui.pveRaidHourEdit155:SetText(string.format("%02d", hour or 20)) end
    if self.ui.pveRaidMinuteEdit155 then self.ui.pveRaidMinuteEdit155:SetText(string.format("%02d", minute or 0)) end
    self.ui.pveRaidRecurring155 = raid and raid.recurring == "WEEKLY" and "WEEKLY" or "ONCE"
    if self.ui.pveRaidRecurringButton155 then
        SetButtonText(self.ui.pveRaidRecurringButton155, self.ui.pveRaidRecurring155 == "WEEKLY" and "Weekly" or "Once")
        SetButtonSelected(self.ui.pveRaidRecurringButton155, self.ui.pveRaidRecurring155 == "WEEKLY")
    end
    if self.ui.pveRaidReminderEdit155 then self.ui.pveRaidReminderEdit155:SetText(tostring(raid and raid.reminderMinutes or 60)) end
end

function OTLGM:RefreshPveRaidsPanel()
    local raids = self.GetPveRaids and self:GetPveRaids() or {}
    local selected
    local i
    for i = 1, table.getn(raids) do if raids[i].id == self.ui.pveRaidSelectedId155 then selected = raids[i] break end end
    if not selected then selected = raids[1] self.ui.pveRaidSelectedId155 = selected and selected.id or nil end
    local raid = selected or self:GetPveActiveRaid()
    if raid then
        self.ui.pveRaidName:SetText(self.colors.gold .. (raid.name or "Guild Raid") .. self.colors.reset)
        local timeLabel = self.GetPveRaidServerTime155 and self:GetPveRaidServerTime155(raid) or (raid.serverTime or "Time TBA")
        self.ui.pveRaidTime:SetText(self.colors.green .. timeLabel .. self.colors.reset .. "  -  " .. self:GetPveRaidRemainingText(raid))
        self.ui.pveRaidLocation:SetText((raid.location and raid.location ~= "" and ("Meeting: " .. raid.location) or "Meeting point not specified"))
        self.ui.pveRaidNote:SetText(raid.note and raid.note ~= "" and raid.note or "Sign-ups remain in Discord.")
    else
        self.ui.pveRaidName:SetText(self.colors.grey .. "No raid events scheduled" .. self.colors.reset)
        self.ui.pveRaidTime:SetText("Leadership can publish an exact Server Time below.")
        self.ui.pveRaidLocation:SetText("One-time and weekly events are supported.")
        self.ui.pveRaidNote:SetText("Sign-ups remain in Discord.")
    end
    self.ui.pveRaidOrganizer:SetText("UPCOMING RAIDS  •  " .. tostring(table.getn(raids)))
    for i = 1, table.getn(self.ui.pveRaidUpcomingButtons155 or {}) do
        local button = self.ui.pveRaidUpcomingButtons155[i]
        local event = raids[i]
        if event then
            button.raidData155 = event
            local label = HomeShort152(event.name or "Raid", 19) .. "  •  " .. (self.GetPveRaidServerTime155 and self:GetPveRaidServerTime155(event) or (event.serverTime or "TBA"))
            SetButtonText(button, label)
            SetButtonSelected(button, selected and selected.id == event.id)
            button:Show()
        else button.raidData155 = nil button:Hide() end
    end

    local officer = self:IsOfficerMode()
    self.ui.pveRaidOfficerOnly:Hide()
    if officer then
        self.ui.pveRaidEditor:Show()
        if self.ui.pveRaidMemberPanel then self.ui.pveRaidMemberPanel:Hide() end
        if self.ui.pveRaidEditorLoadedId155 ~= (selected and selected.id or nil) then self:PopulateRaidEditor155(selected) end
    else
        self.ui.pveRaidEditor:Hide()
        if self.ui.pveRaidMemberPanel then self.ui.pveRaidMemberPanel:Show() end
        local eligible = self.IsRaidNoticeEligible and self:IsRaidNoticeEligible()
        if eligible then
            self.ui.pveRaidMemberInfoText:SetText(self.colors.green .. "RAID NOTIFICATIONS ENABLED" .. self.colors.reset .. "\nYou will receive reminders for published raid events. Official sign-ups remain in Discord.")
        else
            self.ui.pveRaidMemberInfoText:SetText(self.colors.red .. "RAID NOTIFICATIONS LOCKED" .. self.colors.reset .. "\nYour current guild role does not receive raid popup reminders.\n\nJoin the Order of the Lion Discord, register using your in-game character name, and receive an approved raid role. You can still read every raid event on this page.")
        end
    end
    local controls = { self.ui.pveRaidNameEdit, self.ui.pveRaidLocationEdit, self.ui.pveRaidDayEdit155, self.ui.pveRaidHourEdit155, self.ui.pveRaidMinuteEdit155, self.ui.pveRaidRecurringButton155, self.ui.pveRaidReminderEdit155, self.ui.pveRaidNoteEdit, self.ui.pveRaidPublishButton, self.ui.pveRaidNewButton155, self.ui.pveRaidGuildPostButton, self.ui.pveRaidReminderNow155, self.ui.pveRaidClearButton }
    for i = 1, table.getn(self.ui.pveRaidDayButtons155 or {}) do table.insert(controls, self.ui.pveRaidDayButtons155[i]) end
    for i = 1, table.getn(controls) do if controls[i] then if officer then controls[i]:Show() else controls[i]:Hide() end end end
    SetButtonEnabled(self.ui.pveRaidGuildPostButton, selected ~= nil, "Select or publish a raid event first.")
    SetButtonEnabled(self.ui.pveRaidReminderNow155, selected ~= nil, "Select or publish a raid event first.")
    SetButtonEnabled(self.ui.pveRaidClearButton, selected ~= nil, "Select a raid event first.")
end

function OTLGM:RefreshPveGroupsPanel()
    local kind = OTLGM_DB.settings.pveRequestKind or "DUNGEON"
    local role = OTLGM_DB.settings.pveRequestRole or "ANY"
    local joinRole = OTLGM_DB.settings.pveJoinRole or "DPS"
    local key, button
    for key, button in pairs(self.ui.pveKindButtons or {}) do SetButtonSelected(button, key == kind) end
    for key, button in pairs(self.ui.pveRoleButtons or {}) do SetButtonSelected(button, key == role) end
    for key, button in pairs(self.ui.pveJoinRoleButtons or {}) do SetButtonSelected(button, key == joinRole) end

    local requests = self:GetPveRequests()
    local pending = self:GetPendingPveApplicationCount()
    local maximumOffset = math.max(0, table.getn(requests) - table.getn(self.ui.pveRequestRows or {}))
    self.ui.pveGroupOffset = math.max(0, math.min(maximumOffset, self.ui.pveGroupOffset or 0))
    if self.ui.pveGroupSlider then
        self.updatingPveGroupSlider = true
        self.ui.pveGroupSlider:SetMinMaxValues(0, maximumOffset)
        self.ui.pveGroupSlider:SetValue(maximumOffset - self.ui.pveGroupOffset)
        self.updatingPveGroupSlider = nil
    end
    self.ui.pveRequestCount:SetText(tostring(table.getn(requests)) .. " active" .. (pending > 0 and ("  -  " .. tostring(pending) .. " applicants") or ""))
    local i, row, request
    for i = 1, table.getn(self.ui.pveRequestRows or {}) do
        row = self.ui.pveRequestRows[i]
        request = requests[(self.ui.pveGroupOffset or 0) + i]
        if request then
            request.status = self:GetPveGroupStatus(request)
            row.requestData = request
            row.kindIcon:SetTexture(PveKindIcon(request.kind))
            row.title:SetText((request.activity or "Group") .. "  " .. self.colors.grey .. PveKindLabel(request.kind) .. self.colors.reset)
            row.author:SetText(self:GetClassColor(request.class) .. (request.author or "Unknown") .. self.colors.reset)
            row.composition:SetText(
                tostring(request.current or 1) .. "/" .. tostring(request.maxSize or 5) ..
                "   " .. self.colors.blue .. "T " .. tostring(request.needTank or 0) .. self.colors.reset ..
                "  " .. self.colors.green .. "H " .. tostring(request.needHeal or 0) .. self.colors.reset ..
                "  " .. self.colors.purple .. "D " .. tostring(request.needDps or 0) .. self.colors.reset
            )
            local remaining = math.max(0, math.floor(((request.expires or self:Now()) - self:Now()) / 60))
            row.status:SetText(PveStatusColor(request.status) .. request.status .. self.colors.reset .. "  " .. tostring(remaining) .. "m")
            if self.ui.pveSelectedRequest == request.id then row:SetBackdropBorderColor(0.92, 0.65, 0.20, 1) else row:SetBackdropBorderColor(0.25, 0.21, 0.15, 1) end
            row:Show()
        else
            row.requestData = nil
            row:Hide()
        end
    end

    local selected = self:GetPveRequestByID(self.ui.pveSelectedRequest)
    if not selected then self.ui.pveSelectedRequest = nil self.ui.pveSelectedApplication = nil end
    selected = self:GetPveRequestByID(self.ui.pveSelectedRequest)

    local joinIndex
    for joinIndex = 1, table.getn(self.ui.pveJoinControls or {}) do self.ui.pveJoinControls[joinIndex]:Hide() end
    for joinIndex = 1, table.getn(self.ui.pveLeaderControls or {}) do self.ui.pveLeaderControls[joinIndex]:Hide() end
    self.ui.pveRequestDeleteButton:Hide()

    if not selected then
        self.ui.pveRequestSelectedText:SetText("Select a group to view its open positions or manage applicants.")
        return
    end

    local own = self:IsOwnPveGroup(selected)
    local status = self:GetPveGroupStatus(selected)
    local selectedHeader = self:GetClassColor(selected.class) .. (selected.author or "Unknown") .. self.colors.reset ..
        " - " .. (selected.activity or "Group") .. "  " .. PveStatusColor(status) .. status .. self.colors.reset

    if own then
        local applications = self:GetPveApplications(selected.id, true)
        local filled = tonumber(selected.current) or 1
        local maximumSize = tonumber(selected.maxSize) or 5
        self.ui.pveRequestSelectedText:SetText(selectedHeader .. "\nFilled " .. tostring(filled) .. "/" .. tostring(maximumSize) .. "  •  " .. tostring(table.getn(applications)) .. " pending request(s). Select a candidate below.")
        local validSelected = false
        for i = 1, table.getn(self.ui.pveApplicantButtons or {}) do
            local app = applications[i]
            local appButton = self.ui.pveApplicantButtons[i]
            if app then
                appButton.applicationData = app
                if appButton.iconTexture then appButton.iconTexture:SetTexture(PveRoleIcon(app.role)) end
                SetButtonText(appButton, self:GetClassColor(app.class) .. (app.author or "Unknown") .. self.colors.reset)
                SetButtonSelected(appButton, self.ui.pveSelectedApplication == app.id)
                appButton:Show()
                if self.ui.pveSelectedApplication == app.id then validSelected = true end
            else
                appButton.applicationData = nil
                appButton:Hide()
            end
        end
        if not validSelected then
            self.ui.pveSelectedApplication = applications[1] and applications[1].id or nil
            if applications[1] then SetButtonSelected(self.ui.pveApplicantButtons[1], true) end
        end
        local selectedApplication = self:GetPveApplicationByID(self.ui.pveSelectedApplication)
        if selectedApplication then
            self.ui.pveRequestSelectedText:SetText(selectedHeader .. "\n" .. self:GetClassColor(selectedApplication.class) .. (selectedApplication.author or "Unknown") .. self.colors.reset .. " - Level " .. tostring(selectedApplication.level or "?") .. " " .. PveRoleLabel(selectedApplication.role) .. (selectedApplication.note and selectedApplication.note ~= "" and (" - " .. selectedApplication.note) or ""))
        end
        self.ui.pveApplicantAcceptButton:Show()
        self.ui.pveApplicantDeclineButton:Show()
        self.ui.pveApplicantWhisperButton:Show()
        self.ui.pveRequestDeleteButton:Show()
        local canAccept, acceptReason = false, "Select a candidate first."
        if selectedApplication and self.CanAcceptPveApplication155 then canAccept, acceptReason = self:CanAcceptPveApplication155(selectedApplication) end
        SetButtonEnabled(self.ui.pveApplicantAcceptButton, selectedApplication ~= nil and canAccept, acceptReason or "This role is already filled.")
        SetButtonEnabled(self.ui.pveApplicantDeclineButton, self.ui.pveSelectedApplication ~= nil, "Select a candidate first.")
        SetButtonEnabled(self.ui.pveApplicantWhisperButton, self.ui.pveSelectedApplication ~= nil, "Select a candidate first.")
        SetButtonEnabled(self.ui.pveRequestDeleteButton, true)
    else
        local ownApplication = self:GetOwnPveApplication(selected.id)
        local appStatus = ownApplication and ownApplication.status or nil
        local filled = tonumber(selected.current) or 1
        local maximumSize = tonumber(selected.maxSize) or 5
        local statusLine = "Filled " .. tostring(filled) .. "/" .. tostring(maximumSize) .. "  •  Needs: T " .. tostring(selected.needTank or 0) .. " / H " .. tostring(selected.needHeal or 0) .. " / D " .. tostring(selected.needDps or 0)
        if appStatus then statusLine = statusLine .. "  •  Your request: " .. appStatus end
        self.ui.pveRequestSelectedText:SetText(selectedHeader .. "\n" .. statusLine)
        for i = 1, table.getn(self.ui.pveJoinControls or {}) do self.ui.pveJoinControls[i]:Show() end
        self.ui.pveRequestDeleteButton:Hide()
        local roleAvailability = {
            TANK = (tonumber(selected.needTank) or 0) > 0,
            HEAL = (tonumber(selected.needHeal) or 0) > 0,
            DPS = (tonumber(selected.needDps) or 0) > 0,
        }
        roleAvailability.ANY = roleAvailability.TANK or roleAvailability.HEAL or roleAvailability.DPS
        for key, button in pairs(self.ui.pveJoinRoleButtons or {}) do
            SetButtonEnabled(button, roleAvailability[key], "This group no longer needs that role.")
        end
        if not roleAvailability[joinRole] then
            if roleAvailability.TANK then joinRole = "TANK" elseif roleAvailability.HEAL then joinRole = "HEAL" elseif roleAvailability.DPS then joinRole = "DPS" else joinRole = "ANY" end
            OTLGM_DB.settings.pveJoinRole = joinRole
            for key, button in pairs(self.ui.pveJoinRoleButtons or {}) do SetButtonSelected(button, key == joinRole) end
        end
        local canJoin = status == "OPEN" and roleAvailability[joinRole] and (not ownApplication or ownApplication.status == "DECLINED" or ownApplication.status == "CANCELLED")
        local joinReason = "This group is not open or no slot remains for that role."
        if appStatus == "PENDING" then joinReason = "Your request is waiting for the leader." elseif appStatus == "ACCEPTED" then joinReason = "You were already accepted." end
        SetButtonEnabled(self.ui.pveRequestJoinButton, canJoin, joinReason)
        SetButtonEnabled(self.ui.pveRequestCancelAppButton, ownApplication and ownApplication.status == "PENDING", "There is no pending request to cancel.")
        SetButtonEnabled(self.ui.pveRequestWhisperButton, true)
    end
end

function OTLGM:RefreshPveBoardPanel()
    local posts = self:GetPveBoardPosts()
    local i, row, post
    for i = 1, table.getn(self.ui.pveBoardRows or {}) do
        row = self.ui.pveBoardRows[i]
        post = posts[i]
        if post then
            row.postData = post
            row.timeText:SetText(date("%d/%m %H:%M", post.ts or self:Now()))
            row.authorText:SetText(self:GetClassColor(post.class) .. (post.author or "Unknown") .. self.colors.reset)
            row.messageText:SetText(post.text or "")
            if self.ui.pveSelectedBoardPost == post.id then row.bg:SetTexture(0.18, 0.11, 0.025, 0.72) else row.bg:SetTexture(0.055, 0.045, 0.030, i / 2 == math.floor(i / 2) and 0.55 or 0.28) end
            row:Show()
        else row.postData = nil row:Hide() end
    end
    local selected = self:GetPveBoardPostByID(self.ui.pveSelectedBoardPost)
    if not selected then self.ui.pveSelectedBoardPost = nil end
    selected = self:GetPveBoardPostByID(self.ui.pveSelectedBoardPost)
    if selected then self.ui.pveBoardSelected:SetText(self:GetClassColor(selected.class) .. (selected.author or "Unknown") .. self.colors.reset .. ": " .. (selected.text or ""))
    else self.ui.pveBoardSelected:SetText(tostring(table.getn(posts)) .. " active board posts") end
    SetButtonEnabled(self.ui.pveBoardWhisperButton, selected ~= nil, "Select a post first.")
    SetButtonEnabled(self.ui.pveBoardDeleteButton, selected and self:CanModifyPveRecord(selected), "Only the author or leadership can delete this post.")
end

function OTLGM:RefreshPvePage()
    if not self.ui or not self.ui.pvePanels then return end
    self:EnsurePveDB()
    self:PurgePveData(true)
    local section = OTLGM_DB.settings.pveSection or "RAIDS"
    local key, panel
    for key, panel in pairs(self.ui.pvePanels) do if key == section then panel:Show() else panel:Hide() end end
    for key, button in pairs(self.ui.pveTabButtons or {}) do SetButtonSelected(button, key == section) end
    self:MarkPveSectionRead(section)
    local raidUnread = self:GetPveUnread("RAIDS")
    local groupUnread = self:GetPveUnread("GROUPS")
    local boardUnread = self:GetPveUnread("BOARD")
    SetButtonText(self.ui.pveTabButtons.RAIDS, "Raid Alerts" .. (raidUnread > 0 and (" (" .. tostring(raidUnread) .. ")") or ""))
    SetButtonText(self.ui.pveTabButtons.GROUPS, "Group Finder" .. (groupUnread > 0 and (" (" .. tostring(groupUnread) .. ")") or ""))
    SetButtonText(self.ui.pveTabButtons.BOARD, "Guild Board" .. (boardUnread > 0 and (" (" .. tostring(boardUnread) .. ")") or ""))
    local detected, latest, online = self:GetDetectedAddonUsers(86400)
    if self.ui.pveNetworkText then self.ui.pveNetworkText:SetText(self.colors.green .. "Network: " .. tostring(online) .. " online" .. self.colors.reset) end
    self:RefreshPveRaidsPanel()
    self:RefreshPveGroupsPanel()
    self:RefreshPveBoardPanel()
    self:RefreshPveNavigationBadge()
end


function OTLGM:BuildRecruitmentPage(page)
    CreateText(page, "GameFontNormalLarge", "Guild Recruitment", 0, -2, 390, "LEFT")
    CreateHelpButton(page, "Recruitment", "Pinned messages are protected originals. Custom slots are persistent and can be renamed. The highlighted timer tracks only successful world-chat recruitment posts so guild messages never affect the anti-spam reminder.")
    CreateText(page, "GameFontNormalSmall", "Protected presets, named custom slots and a shared world-chat anti-spam timer.", 0, -28, 390, "LEFT")

    local worldCard = CreateFrame("Frame", nil, page)
    worldCard:SetPoint("TOPLEFT", page, "TOPLEFT", 408, -2)
    worldCard:SetWidth(310)
    worldCard:SetHeight(60)
    CreateBackdrop(worldCard, 5)
    worldCard:SetBackdropColor(0.040, 0.032, 0.022, 0.99)
    worldCard:SetBackdropBorderColor(0.50, 0.36, 0.16, 1)
    worldCard.label = CreateText(worldCard, "GameFontNormalSmall", "LAST WORLD RECRUITMENT", 10, -8, 196, "LEFT")
    worldCard.value = CreateText(worldCard, "GameFontNormalLarge", "NEVER", 10, -27, 102, "LEFT")
    worldCard.detail = CreateWrappedText(worldCard, "GameFontNormalSmall", "", 112, -25, 154, 21)
    worldCard.meta = CreateText(worldCard, "GameFontNormalSmall", "", 112, -45, 188, "LEFT")
    worldCard.meta:SetTextColor(0.52, 0.52, 0.52)
    CreateText(worldCard, "GameFontNormalSmall", "WORLD", 202, -7, 54, "RIGHT")
    CreateText(worldCard, "GameFontNormalLarge", "/", 260, -4, 12, "LEFT")
    local channel = CreateEditBox(worldCard, "OTLGM_ChannelEdit", 272, -3, 34, 27, false)
    channel:SetMaxLetters(2)
    channel:SetScript("OnTextChanged", function()
        if OTLGM.updatingWorldChannelEdit153 then return end
        local text = this:GetText() or ""
        local digits = string.gsub(text, "%D", "")
        if digits ~= text then this:SetText(digits) return end
        if not (OTLGM_DB.settings.worldChannelAuto153 and OTLGM_DB.settings.worldChannelDetected153) then
            OTLGM_DB.settings.worldChannel = digits
        end
        OTLGM:RefreshRecruitmentPage()
    end)
    channel:SetScript("OnEnterPressed", function() this:ClearFocus() end)
    worldCard.autoText = CreateText(worldCard, "GameFontNormalSmall", "Detecting World...", 202, -44, 98, "RIGHT")
    worldCard.autoText:SetTextColor(0.55, 0.55, 0.52)
    self.ui.channelEdit = channel
    self.ui.worldRecruitmentCard = worldCard

    CreateText(page, "GameFontNormal", "Pinned messages", 0, -62, 220, "LEFT")
    self.ui.recruitPresetButtons = {}
    self.ui.presetSendButtons = {}
    local presetKeys = { "BASE1", "BASE2", "GUILDINFO", "ADDONINFO" }
    local i
    for i = 1, table.getn(presetKeys) do
        local key = presetKeys[i]
        local capturedKey = key
        local row = CreateFrame("Frame", nil, page)
        row:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -82 - ((i - 1) * 46))
        row:SetWidth(718)
        row:SetHeight(40)
        CreateBackdrop(row, 4)
        row:SetBackdropColor(0.040, 0.032, 0.023, 0.98)
        row:SetBackdropBorderColor(0.35, 0.27, 0.16, 1)
        local select = CreateButton(row, nil, self.recruitmentPresets[key].label, 8, -6, 96, 28, function()
            OTLGM:SelectRecruitment(capturedKey)
        end)
        self.ui.recruitPresetButtons[key] = select
        local target = self.recruitmentPresets[key].target == "GUILD" and "PINNED - GUILD" or "PINNED - WORLD"
        local badge = CreateText(row, "GameFontNormalSmall", target, 112, -5, 136, "LEFT")
        badge:SetTextColor(0.72, 0.55, 0.22)
        CreateText(row, "GameFontNormalSmall", self:GetRecruitmentPreview(self.recruitmentPresets[key].text, 88), 112, -21, 468, "LEFT")
        local sendLabel = self.recruitmentPresets[key].target == "GUILD" and "Send Guild" or "Send /6"
        self.ui.presetSendButtons[key] = CreateButton(row, nil, sendLabel, 592, -6, 116, 28, function()
            OTLGM:RequestRecruitmentSend(capturedKey, false)
        end)
    end

    CreateText(page, "GameFontNormal", "Saved custom slots", 0, -270, 200, "LEFT")
    self.ui.customSlotButtons = {}
    for i = 1, 3 do
        local key = "CUSTOM" .. tostring(i)
        local capturedKey = key
        local button = CreateButton(page, nil, "", (i - 1) * 242, -288, 226, 38, function()
            OTLGM:SelectRecruitment(capturedKey)
        end)
        button.customIndex = i
        self.ui.recruitPresetButtons[key] = button
        self.ui.customSlotButtons[key] = button
    end

    self.ui.recruitmentState = CreateText(page, "GameFontNormalSmall", "", 0, -332, 410, "LEFT")
    CreateText(page, "GameFontNormalSmall", "SAVE COPY TO", 420, -332, 92, "RIGHT")
    self.ui.saveCopyButtons = {}
    for i = 1, 3 do
        local slot = i
        self.ui.saveCopyButtons[i] = CreateButton(page, nil, tostring(i), 522 + ((i - 1) * 42), -328, 34, 25, function()
            OTLGM:SaveCurrentToCustom(slot)
        end)
    end

    CreateText(page, "GameFontNormalSmall", "WORKING COPY", 0, -356, 120, "LEFT")
    self.ui.workingTargetText = CreateText(page, "GameFontNormalSmall", "", 410, -356, 308, "RIGHT")
    self.ui.workingTargetText:SetTextColor(0.52, 0.52, 0.52)
    local edit = CreateEditBox(page, "OTLGM_RecruitmentEdit", 0, -372, 718, 62, true)
    edit:SetMaxLetters(240)
    edit:SetScript("OnTextChanged", function()
        OTLGM_DB.settings.recruitmentMessage = this:GetText() or ""
        OTLGM:RefreshRecruitmentCount()
    end)
    self.ui.recruitmentEdit = edit
    self.ui.recruitmentCount = CreateText(page, "GameFontNormalSmall", "0 / 240", 632, -438, 86, "RIGHT")

    CreateText(page, "GameFontNormalSmall", "CUSTOM SLOT NAME", 0, -458, 116, "LEFT")
    self.ui.customNameEdit = CreateEditBox(page, "OTLGM_CustomNameEdit", 120, -452, 174, 28, false)
    self.ui.customNameEdit:SetMaxLetters(24)
    self.ui.renameCustomButton = CreateButton(page, nil, "Rename", 302, -452, 74, 28, function()
        local key = OTLGM_DB.settings.selectedRecruitment or ""
        local customKey = string.gsub(key, "^CUSTOM", "")
        local index = tonumber(customKey)
        if index then OTLGM:RenameCustomMessage(index, OTLGM.ui.customNameEdit:GetText()) end
    end)

    self.ui.customWorldButton = CreateButton(page, nil, "World", 386, -452, 62, 28, function()
        OTLGM_DB.settings.customTarget = "WORLD"
        OTLGM:RefreshRecruitmentPage()
    end)
    self.ui.customGuildButton = CreateButton(page, nil, "Guild", 454, -452, 62, 28, function()
        OTLGM_DB.settings.customTarget = "GUILD"
        OTLGM:RefreshRecruitmentPage()
    end)
    self.ui.saveSlotButton = CreateButton(page, nil, "Save Slot", 526, -452, 82, 28, function() OTLGM:SaveSelectedCustom() end)
    self.ui.clearSlotButton = CreateButton(page, nil, "Clear", 614, -452, 58, 28, function() OTLGM:ClearSelectedCustom() end)
    self.ui.sendCurrentButton = CreateButton(page, nil, "Send", 678, -452, 40, 28, function()
        OTLGM:RequestRecruitmentSend(OTLGM_DB.settings.selectedRecruitment or "WORKING", true)
    end)
    self.ui.sendNextButton = CreateButton(page, nil, "Send Next Recruit", 0, -486, 150, 26, function()
        local index = OTLGM_DB.settings.nextRecruitIndex or 1
        local key = index == 1 and "BASE1" or "BASE2"
        OTLGM:RequestRecruitmentSend(key, false, true)
    end)
    self.ui.recruitReadyText = CreateText(page, "GameFontNormalSmall", "", 164, -492, 554, "LEFT")
end

function OTLGM:RefreshRecruitmentButtons()
    if self.RefreshRecruitmentPage then self:RefreshRecruitmentPage() end
end

function OTLGM:RefreshRecruitmentCount()
    if not self.ui.recruitmentEdit then return end
    local length = string.len(self.ui.recruitmentEdit:GetText() or "")
    self.ui.recruitmentCount:SetText(tostring(length) .. " / 240")
    if length > 240 then self.ui.recruitmentCount:SetTextColor(1, 0.25, 0.25)
    else self.ui.recruitmentCount:SetTextColor(0.68, 0.68, 0.68) end
end

function OTLGM:RequestRecruitmentSend(key, useWorkingCopy, rotateAfter)
    self:EnsureDB()
    local message, target, label
    if useWorkingCopy then
        message = OTLGM_DB.settings.recruitmentMessage or ""
        target = OTLGM_DB.settings.customTarget or "WORLD"
        label = "Working Copy"
        local customKey = string.gsub(key or "", "^CUSTOM", "")
        local customNumber = tonumber(customKey)
        if customNumber then label = OTLGM_DB.settings.customMessageNames[customNumber] or label end
    else
        local preset = self.recruitmentPresets[key]
        if not preset then return end
        message = preset.text
        target = preset.target
        label = preset.label
    end
    local destination = target == "GUILD" and "guild chat" or ("/" .. tostring(self:GetWorldChannelNumber() or "?"))
    local function SendNow()
        if OTLGM:SendMessageText(message, target) then
            OTLGM:MarkRecruitmentSent(key, target, label)
            if rotateAfter then
                OTLGM_DB.settings.nextRecruitIndex = (OTLGM_DB.settings.nextRecruitIndex or 1) == 1 and 2 or 1
                OTLGM:RefreshRecruitmentPage()
            end
        end
    end
    if OTLGM_DB.settings.confirmRecruitment then
        self:ShowConfirm("Send Recruitment Message", label .. " -> " .. destination .. "\n\n" .. message, "Send", SendNow)
    else
        SendNow()
    end
end

function OTLGM:RefreshWorldRecruitmentIndicator()
    local card = self.ui and self.ui.worldRecruitmentCard
    if not card then return end
    local info = self:GetWorldRecruitmentInfo()
    card.value:SetText(info.value or "NEVER")
    card.detail:SetText(info.detail or "")

    if info.state == "WAIT" then
        card.value:SetTextColor(1.0, 0.30, 0.24)
        card.detail:SetTextColor(1.0, 0.52, 0.38)
        card:SetBackdropBorderColor(0.78, 0.20, 0.12, 1)
    elseif info.state == "WINDOW" then
        card.value:SetTextColor(1.0, 0.78, 0.22)
        card.detail:SetTextColor(1.0, 0.82, 0.38)
        card:SetBackdropBorderColor(0.74, 0.50, 0.14, 1)
    elseif info.state == "READY" then
        card.value:SetTextColor(0.42, 0.94, 0.48)
        card.detail:SetTextColor(0.62, 0.94, 0.64)
        card:SetBackdropBorderColor(0.20, 0.64, 0.28, 1)
    else
        card.value:SetTextColor(0.72, 0.72, 0.72)
        card.detail:SetTextColor(0.68, 0.68, 0.68)
        card:SetBackdropBorderColor(0.50, 0.36, 0.16, 1)
    end

    local channelText, channelName, automatic = self:GetWorldChannelDisplay153()
    if card.autoText then
        card.autoText:SetText(automatic and ("AUTO " .. channelText) or (channelText == "Not joined" and "NOT JOINED" or ("MANUAL " .. channelText)))
        if automatic then card.autoText:SetTextColor(0.42, 0.94, 0.48)
        elseif channelText == "Not joined" then card.autoText:SetTextColor(1.0, 0.42, 0.30)
        else card.autoText:SetTextColor(1.0, 0.78, 0.22) end
    end
    if info.timestamp then
        card.meta:SetText((info.label or "World post") .. " -> /" .. tostring(info.channel or "?") .. " at " .. date("%H:%M", info.timestamp))
    else
        card.meta:SetText(automatic and ("Detected: " .. tostring(channelName or "World")) or "Recommended interval: 10-15 min")
    end
end

function OTLGM:RefreshRecruitmentPage()
    if not self.ui.recruitmentEdit then return end
    self:EnsureDB()
    local selected = OTLGM_DB.settings.selectedRecruitment or "BASE1"
    local i, key, button
    local detectedChannel, detectedName, automatic = self:DetectWorldChannel153(false)
    local shownChannel = detectedChannel or tonumber(OTLGM_DB.settings.worldChannel) or 6
    if self.ui.channelEdit:GetText() ~= tostring(shownChannel) then
        self.updatingWorldChannelEdit153 = true
        self.ui.channelEdit:SetText(tostring(shownChannel))
        self.updatingWorldChannelEdit153 = nil
    end
    self.ui.channelEdit:EnableMouse(not automatic)
    self.ui.channelEdit:SetTextColor(automatic and 0.42 or 1.0, automatic and 0.94 or 0.82, automatic and 0.48 or 0.30)
    self.ui.channelEdit:SetBackdropBorderColor(automatic and 0.20 or 0.50, automatic and 0.64 or 0.36, automatic and 0.28 or 0.16, 1)

    local presetKeys = { "BASE1", "BASE2", "GUILDINFO", "ADDONINFO" }
    for i = 1, table.getn(presetKeys) do
        key = presetKeys[i]
        SetButtonSelected(self.ui.recruitPresetButtons[key], selected == key)
        local sendLabel = self.recruitmentPresets[key].target == "GUILD" and "Send Guild" or ("Send /" .. tostring(self:GetWorldChannelNumber() or "?"))
        SetButtonText(self.ui.presetSendButtons[key], sendLabel)
    end

    for i = 1, 3 do
        key = "CUSTOM" .. tostring(i)
        button = self.ui.customSlotButtons[key]
        local text = OTLGM_DB.settings.customMessages[i] or ""
        local customName = OTLGM_DB.settings.customMessageNames[i] or ("Custom " .. tostring(i))
        SetButtonText(button, customName .. (text == "" and " - Empty" or " - Saved"))
        SetButtonSelected(button, selected == key)
    end

    local currentText = OTLGM_DB.settings.recruitmentMessage or ""
    if self.ui.recruitmentEdit:GetText() ~= currentText then self.ui.recruitmentEdit:SetText(currentText) end

    local customText = string.gsub(selected, "^CUSTOM", "")
    local customIndex = tonumber(customText)
    if customIndex then
        self.ui.customNameEdit:SetText(OTLGM_DB.settings.customMessageNames[customIndex] or ("Custom " .. tostring(customIndex)))
        SetButtonEnabled(self.ui.renameCustomButton, true)
        SetButtonEnabled(self.ui.saveSlotButton, true)
        SetButtonEnabled(self.ui.clearSlotButton, true)
        self.ui.recruitmentState:SetText(self.colors.green .. "Editable persistent custom slot selected." .. self.colors.reset)
    else
        self.ui.customNameEdit:SetText("")
        SetButtonEnabled(self.ui.renameCustomButton, false, "Select a custom slot before renaming it.")
        SetButtonEnabled(self.ui.saveSlotButton, false, "Pinned originals are protected. Save a copy to a numbered custom slot.")
        SetButtonEnabled(self.ui.clearSlotButton, false, "Pinned originals cannot be cleared.")
        self.ui.recruitmentState:SetText(self.colors.gold .. "Pinned original protected - editor is a temporary working copy." .. self.colors.reset)
    end

    SetButtonSelected(self.ui.customWorldButton, OTLGM_DB.settings.customTarget == "WORLD")
    SetButtonSelected(self.ui.customGuildButton, OTLGM_DB.settings.customTarget == "GUILD")
    if OTLGM_DB.settings.customTarget == "GUILD" then
        self.ui.workingTargetText:SetText("Destination: Guild chat - does not affect world timer")
    else
        self.ui.workingTargetText:SetText("Destination: World /" .. tostring(self:GetWorldChannelNumber() or "?"))
    end
    local readyKey = (OTLGM_DB.settings.nextRecruitIndex or 1) == 1 and "BASE1" or "BASE2"
    self.ui.recruitReadyText:SetText("Next rotation: " .. self.recruitmentPresets[readyKey].label .. " - use the shared world timer above.")
    self:RefreshWorldRecruitmentIndicator()
    self:RefreshRecruitmentCount()
end

function OTLGM:ShowSettingsSection(section)
    if not self.ui or not self.ui.settingsPanels then return end
    section = section or "GENERAL"
    if not self.ui.settingsPanels[section] then section = "GENERAL" end
    OTLGM_DB.settings.settingsSection = section
    local key, panel
    for key, panel in pairs(self.ui.settingsPanels) do
        if key == section then panel:Show() else panel:Hide() end
    end
    for key, panel in pairs(self.ui.settingsSectionButtons or {}) do
        SetButtonSelected(panel, key == section)
    end
end

function OTLGM:BuildSettingsPage(page)
    CreateText(page, "GameFontNormalLarge", "Addon Settings", 0, -2, 300, "LEFT")
    CreateHelpButton(page, "Settings", "General options, Guild Chat options, notifications and database tools are separated into clear sections. All choices are saved in OTLGM_DB inside the WTF folder.")
    CreateText(page, "GameFontNormalSmall", "Choose a section below. Changes are saved immediately.", 0, -28, 700, "LEFT")

    self.ui.settingsSectionButtons = {}
    local sectionDefs = {
        { key = "GENERAL", label = "General", x = 0, width = 138 },
        { key = "CHAT", label = "Guild Chat", x = 146, width = 190 },
        { key = "PVE", label = "PvE Hub", x = 344, width = 150 },
        { key = "DATA", label = "Data & Diagnostics", x = 502, width = 216 },
    }
    local i
    for i = 1, table.getn(sectionDefs) do
        local def = sectionDefs[i]
        local captured = def.key
        self.ui.settingsSectionButtons[captured] = CreateButton(page, nil, def.label, def.x, -50, def.width, 30, function()
            OTLGM:ShowSettingsSection(captured)
        end)
    end

    self.ui.settingsPanels = {}
    local function MakePanel()
        local panel = CreateFrame("Frame", nil, page)
        panel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -88)
        panel:SetWidth(718)
        panel:SetHeight(430)
        CreateBackdrop(panel, 5)
        panel:SetBackdropColor(0.032, 0.028, 0.023, 0.98)
        panel:SetBackdropBorderColor(0.36, 0.28, 0.17, 1)
        panel:Hide()
        return panel
    end

    self.ui.settingChecks = {}

    local general = MakePanel()
    self.ui.settingsPanels.GENERAL = general
    CreateText(general, "GameFontNormal", "ROSTER UPDATE INTERVAL", 14, -14, 330, "LEFT")
    self.ui.scanIntervalButtons = {}
    local intervals = { {0,"Off"}, {600,"10m"}, {1200,"20m"}, {1800,"30m"}, {3600,"60m"} }
    for i = 1, table.getn(intervals) do
        local seconds = intervals[i][1]
        local button = CreateButton(general, nil, intervals[i][2], 14 + ((i - 1) * 67), -40, 59, 28, function()
            if seconds == 0 then
                OTLGM_DB.settings.autoScan = false
            else
                OTLGM_DB.settings.autoScan = true
                OTLGM_DB.settings.scanInterval = seconds
            end
            OTLGM.elapsed = 0
            OTLGM:RefreshSettingsPage()
        end)
        button.interval = seconds
        self.ui.scanIntervalButtons[i] = button
    end
    CreateText(general, "GameFontNormalSmall", "Recommended: 20 minutes. Manual Update Roster remains available at all times.", 14, -75, 680, "LEFT"):SetTextColor(0.58, 0.58, 0.58)

    CreateText(general, "GameFontNormal", "INTERFACE MODE", 14, -108, 330, "LEFT")
    self.ui.modeButtons = {}
    local modes = { "AUTO", "MEMBER", "OFFICER" }
    for i = 1, 3 do
        local mode = modes[i]
        self.ui.modeButtons[mode] = CreateButton(general, nil, mode == "AUTO" and "Auto" or (mode == "MEMBER" and "Member" or "Officer"), 14 + ((i - 1) * 112), -134, 102, 28, function()
            OTLGM:SetUIMode(mode)
            OTLGM:RefreshSettingsPage()
        end)
    end

    CreateText(general, "GameFontNormal", "WINDOW SCALE", 14, -178, 330, "LEFT")
    self.ui.scaleButtons = {}
    local scales = { {0.8,"80%"}, {0.9,"90%"}, {1.0,"100%"}, {1.1,"110%"}, {1.2,"120%"} }
    for i = 1, table.getn(scales) do
        local scale = scales[i][1]
        local button = CreateButton(general, nil, scales[i][2], 14 + ((i - 1) * 67), -204, 59, 28, function()
            OTLGM_DB.settings.uiScale = scale
            OTLGM.ui.main:SetScale(scale)
            OTLGM:RefreshSettingsPage()
        end)
        button.scaleValue = scale
        self.ui.scaleButtons[i] = button
    end

    CreateText(general, "GameFontNormal", "INTERFACE OPTIONS", 14, -252, 330, "LEFT")
    self.ui.settingChecks.minimap = CreateCheck(general, "OTLGM_SettingMinimap", "Show minimap button", 14, -278, function()
        OTLGM_DB.settings.showMinimap = this:GetChecked() and true or false
        OTLGM:ApplyMinimapVisibility()
    end)
    self.ui.settingChecks.help = CreateCheck(general, "OTLGM_SettingHelp", "Show contextual help tooltips", 14, -314, function()
        OTLGM_DB.settings.showHelp = this:GetChecked() and true or false
    end)
    self.ui.settingChecks.lock = CreateCheck(general, "OTLGM_SettingLock", "Lock the main window position", 370, -278, function()
        OTLGM_DB.settings.windowLocked = this:GetChecked() and true or false
    end)
    self.ui.settingChecks.home = CreateCheck(general, "OTLGM_SettingHome", "Open Home instead of the last page", 370, -314, function()
        OTLGM_DB.settings.openHome = this:GetChecked() and true or false
    end)

    local chat = MakePanel()
    self.ui.settingsPanels.CHAT = chat
    local chatLeft = CreateFrame("Frame", nil, chat)
    chatLeft:SetPoint("TOPLEFT", chat, "TOPLEFT", 12, -12)
    chatLeft:SetWidth(338)
    chatLeft:SetHeight(394)
    CreateBackdrop(chatLeft, 5)
    chatLeft:SetBackdropColor(0.024, 0.021, 0.017, 0.98)
    chatLeft:SetBackdropBorderColor(0.34, 0.27, 0.17, 1)
    CreateText(chatLeft, "GameFontNormal", "GUILD CHAT DISPLAY", 12, -12, 310, "LEFT")
    self.ui.settingChecks.chatMentions = CreateCheck(chatLeft, "OTLGM_SettingChatMentions", "Highlight messages that mention my character", 12, -42, function()
        OTLGM_DB.settings.chatHighlightMentions = this:GetChecked() and true or false
        OTLGM:RefreshGuildChatPage()
    end)
    self.ui.settingChecks.chatSeparators = CreateCheck(chatLeft, "OTLGM_SettingChatSeparators", "Show date and long-gap separators", 12, -78, function()
        OTLGM_DB.settings.chatTimeSeparators = this:GetChecked() and true or false
        OTLGM:RefreshGuildChatPage()
    end)
    self.ui.settingChecks.chatRanks = CreateCheck(chatLeft, "OTLGM_SettingChatRanks", "Show rank or leadership status in chat", 12, -114, function()
        OTLGM_DB.settings.chatShowRanks = this:GetChecked() and true or false
        OTLGM:RefreshGuildChatPage()
    end)
    self.ui.settingChecks.classColors = CreateCheck(chatLeft, "OTLGM_SettingClassColors", "Use class colours for player names", 12, -150, function()
        OTLGM_DB.settings.classColors = this:GetChecked() and true or false
        OTLGM:RefreshAll()
    end)
    self.ui.settingChecks.leadership = CreateCheck(chatLeft, "OTLGM_SettingLeadership", "Show leadership and special-rank icons", 12, -186, function()
        OTLGM_DB.settings.highlightLeadership = this:GetChecked() and true or false
        OTLGM:RefreshAll()
    end)
    local fontInfo = CreateWrappedText(chatLeft, "GameFontNormalSmall", "Russian and other supported characters use the same font as the normal game chat. Shift-click an item or spell while Guild Chat is open to insert its link.", 12, -238, 310, 76)
    fontInfo:SetTextColor(0.62, 0.62, 0.62)

    local chatRight = CreateFrame("Frame", nil, chat)
    chatRight:SetPoint("TOPLEFT", chat, "TOPLEFT", 362, -12)
    chatRight:SetWidth(344)
    chatRight:SetHeight(394)
    CreateBackdrop(chatRight, 5)
    chatRight:SetBackdropColor(0.024, 0.021, 0.017, 0.98)
    chatRight:SetBackdropBorderColor(0.34, 0.27, 0.17, 1)
    CreateText(chatRight, "GameFontNormal", "NOTIFICATIONS & SENDING", 12, -12, 316, "LEFT")
    self.ui.settingChecks.scanChat = CreateCheck(chatRight, "OTLGM_SettingScanChat", "Show one normal-chat line after roster updates", 12, -42, function()
        OTLGM_DB.settings.scanChat = this:GetChecked() and true or false
    end)
    self.ui.settingChecks.confirm = CreateCheck(chatRight, "OTLGM_SettingConfirmRecruit", "Preview recruitment messages before sending", 12, -78, function()
        OTLGM_DB.settings.confirmRecruitment = this:GetChecked() and true or false
    end)
    local noticeInfo = CreateWrappedText(chatRight, "GameFontNormalSmall", "Guild and Officer unread counters remain separate. Officer history is session-only. Guild history keeps the latest messages in the local guild database.", 12, -132, 316, 82)
    noticeInfo:SetTextColor(0.62, 0.62, 0.62)

    local pveSettings = MakePanel()
    self.ui.settingsPanels.PVE = pveSettings
    CreateText(pveSettings, "GameFontNormal", "PVE HUB NETWORK", 14, -14, 680, "LEFT")
    local pveInfo = CreateWrappedText(pveSettings, "GameFontNormalSmall", "Groups, join applications and raid notices travel directly between online guildmates who have the addon installed. Guild Board posts use the same safe network but are displayed in Guild Chat. Data is sent only when something changes or Sync Now is requested.", 14, -42, 680, 66)
    pveInfo:SetTextColor(0.66, 0.66, 0.66)
    self.ui.settingChecks.pveRaidPopups = CreateCheck(pveSettings, "OTLGM_SettingPveRaidPopups", "Show popup notifications for published raids and reminders", 14, -124, function()
        OTLGM_DB.settings.pveRaidPopups = this:GetChecked() and true or false
    end)
    self.ui.settingChecks.pveRaidChatLine = CreateCheck(pveSettings, "OTLGM_SettingPveRaidChatLine", "Also print raid notices in my normal chat window", 14, -160, function()
        OTLGM_DB.settings.pveRaidChatLine = this:GetChecked() and true or false
    end)
    CreateText(pveSettings, "GameFontNormal", "DATA LIFETIMES", 14, -212, 330, "LEFT")
    CreateWrappedText(pveSettings, "GameFontNormalSmall", "Groups and join applications expire after 60 minutes. Guild Board posts expire after 48 hours. Raid notices disappear four hours after the scheduled start. Raider alerts are filtered locally to Raider and Core Raider ranks. No sign-ups are stored here; official raid sign-ups remain in Discord.", 14, -240, 680, 66):SetTextColor(0.66, 0.66, 0.66)
    self.ui.pveSettingsSyncButton = CreateButton(pveSettings, nil, "Sync PvE Hub Now", 14, -326, 166, 32, function()
        if OTLGM:RequestPveSync(true) then OTLGM:SetStatus("Requesting PvE Hub data from online addon users...") end
    end)
    SetButtonActionStyle(self.ui.pveSettingsSyncButton, "utility")
    self.ui.pveSettingsOpenButton = CreateButton(pveSettings, nil, "Open PvE Hub", 190, -326, 140, 32, function() OTLGM:ShowPage("pve") end)
    self.ui.pveSettingsClearButton = CreateButton(pveSettings, nil, "Clear Local PvE Cache", 340, -326, 174, 32, function()
        OTLGM:ShowConfirm("Clear Local PvE Cache", "Remove locally stored requests, raid notice and board posts? You can press Sync Now afterward to request current data again from online addon users.", "Clear", function()
            local pve = OTLGM:EnsurePveDB()
            if pve then
                pve.requests = {}
                pve.board = {}
                pve.raid = nil
                pve.deleted = {}
                pve.unread = { RAIDS = 0, GROUPS = 0, BOARD = 0 }
                OTLGM:OnPveDataChanged(nil, false)
            end
        end)
    end)

    local data = MakePanel()
    self.ui.settingsPanels.DATA = data
    CreateText(data, "GameFontNormal", "DATABASE AND DIAGNOSTICS", 14, -14, 680, "LEFT")
    self.ui.diagnosticsText = CreateWrappedText(data, "GameFontNormalSmall", "", 14, -44, 690, 206)
    self.ui.versionUpdateText = CreateWrappedText(data, "GameFontNormalSmall", "", 14, -250, 690, 42)

    CreateButton(data, nil, "Export Backup", 14, -304, 126, 30, function()
        OTLGM:ShowCopyDialog("Order of the Lion Addon Backup", OTLGM:ExportBackup())
    end)
    CreateButton(data, nil, "Import Backup", 148, -304, 126, 30, function()
        OTLGM.ui.importDialog.edit:SetText("")
        OTLGM:ShowModal152(OTLGM.ui.importDialog)
        OTLGM.ui.importDialog.edit:SetFocus()
    end)
    CreateButton(data, nil, "First-Run Guide", 282, -304, 126, 30, function() OTLGM:OpenFirstRunWizard() end)
    CreateButton(data, nil, "Reset Window", 416, -304, 126, 30, function()
        OTLGM_DB.settings.windowX = 0
        OTLGM_DB.settings.windowY = 10
        OTLGM.ui.main:ClearAllPoints()
        OTLGM.ui.main:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
    end)
    CreateButton(data, nil, "Copy Weekly", 550, -304, 154, 30, function()
        OTLGM:ShowCopyDialog("Weekly Guild Summary", OTLGM:GenerateWeeklySummary())
    end)
    local reset = CreateButton(data, nil, "Reset Guild Data", 550, -348, 154, 30, function()
        OTLGM:ShowConfirm("Reset Local Guild Data", "This removes the local roster history and analytics for the current guild. It does not change anything on the server.\n\nExport a backup first if you need to keep the history.", "Reset", function()
            OTLGM:ResetGuildData()
        end)
    end)
    SetButtonActionStyle(reset, "danger")

    self:ShowSettingsSection(OTLGM_DB.settings.settingsSection or "GENERAL")
end

function OTLGM:RefreshSettingsPage()
    if not self.ui.scanIntervalButtons then return end
    self:ShowSettingsSection(OTLGM_DB.settings.settingsSection or "GENERAL")
    local interval = OTLGM_DB.settings.autoScan and (OTLGM_DB.settings.scanInterval or 1200) or 0
    local i
    for i = 1, table.getn(self.ui.scanIntervalButtons) do
        SetButtonSelected(self.ui.scanIntervalButtons[i], self.ui.scanIntervalButtons[i].interval == interval)
    end
    local mode, button
    for mode, button in pairs(self.ui.modeButtons or {}) do SetButtonSelected(button, OTLGM_DB.settings.uiMode == mode) end
    for i = 1, table.getn(self.ui.scaleButtons) do
        SetButtonSelected(self.ui.scaleButtons[i], math.abs((OTLGM_DB.settings.uiScale or 1) - self.ui.scaleButtons[i].scaleValue) < 0.01)
    end
    self.ui.settingChecks.scanChat:SetChecked(OTLGM_DB.settings.scanChat and 1 or nil)
    self.ui.settingChecks.minimap:SetChecked(OTLGM_DB.settings.showMinimap and 1 or nil)
    self.ui.settingChecks.help:SetChecked(OTLGM_DB.settings.showHelp and 1 or nil)
    self.ui.settingChecks.confirm:SetChecked(OTLGM_DB.settings.confirmRecruitment and 1 or nil)
    self.ui.settingChecks.lock:SetChecked(OTLGM_DB.settings.windowLocked and 1 or nil)
    self.ui.settingChecks.home:SetChecked(OTLGM_DB.settings.openHome and 1 or nil)
    self.ui.settingChecks.classColors:SetChecked(OTLGM_DB.settings.classColors and 1 or nil)
    self.ui.settingChecks.leadership:SetChecked(OTLGM_DB.settings.highlightLeadership and 1 or nil)
    self.ui.settingChecks.chatMentions:SetChecked(OTLGM_DB.settings.chatHighlightMentions and 1 or nil)
    self.ui.settingChecks.chatSeparators:SetChecked(OTLGM_DB.settings.chatTimeSeparators and 1 or nil)
    self.ui.settingChecks.chatRanks:SetChecked(OTLGM_DB.settings.chatShowRanks and 1 or nil)
    self.ui.settingChecks.pveRaidPopups:SetChecked(OTLGM_DB.settings.pveRaidPopups and 1 or nil)
    self.ui.settingChecks.pveRaidChatLine:SetChecked(OTLGM_DB.settings.pveRaidChatLine and 1 or nil)
    self.ui.diagnosticsText:SetText(self:GetDiagnosticsText())

    local users, latest = self:GetDetectedAddonUsers()
    if self:IsVersionNewer(latest, self.version) then
        self.ui.versionUpdateText:SetText(self.colors.gold .. "Update detected: v" .. latest .. "\nYour version: v" .. self.version .. self.colors.reset)
    else
        self.ui.versionUpdateText:SetText(self.colors.green .. "Current detected version: v" .. self.version .. self.colors.reset .. "\nOther addon users seen in 24h: " .. tostring(users))
    end
end

function OTLGM:RefreshAll()
    if not self.ui.main then return end
    self:RefreshNavigation()
    self:RefreshHomePage()
    self:RefreshOverviewPage()
    self:RefreshGuildInfoPage()
    self:RefreshRosterPage()
    self:RefreshActivityPage()
    self:RefreshPvePage()
    self:RefreshHistoryPage()
    self:RefreshInactivePage()
    self:RefreshRecruitmentPage()
    self:RefreshSettingsPage()
end
