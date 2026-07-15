-- Order of the Lion Guild Manager
-- Complete Blizzard-like interface for Vanilla WoW / OctoWoW - v1.0.9

OTLGM.fullUILoaded = true
OTLGM.fullUIVersion = "1.0.9"

local NAV_DEFS = {
    { key = "home", label = "Home" },
    { key = "overview", label = "Overview", officer = true },
    { key = "guildinfo", label = "Guild Info" },
    { key = "roster", label = "Roster" },
    { key = "activity", label = "Activity" },
    { key = "history", label = "History", officer = true },
    { key = "inactive", label = "Inactive", officer = true },
    { key = "recruitment", label = "Recruitment", officer = true },
    { key = "settings", label = "Settings" },
}

local NAV_ICONS = {
    home = "Interface\\Icons\\Ability_TownWatch",
    overview = "Interface\\Icons\\INV_Misc_Spyglass_03",
    guildinfo = "Interface\\Icons\\INV_Scroll_03",
    roster = "Interface\\Icons\\INV_Misc_GroupNeedMore",
    activity = "Interface\\Icons\\INV_Misc_PocketWatch_01",
    history = "Interface\\Icons\\INV_Misc_Book_09",
    inactive = "Interface\\Icons\\Spell_Shadow_Cripple",
    recruitment = "Interface\\Icons\\INV_Misc_Horn_02",
    settings = "Interface\\Icons\\INV_Gizmo_02",
}

local ROW_HEIGHT = 24
local ROSTER_ROWS = 13
local HISTORY_ROWS = 15
local INACTIVE_ROWS = 12
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
        button:SetBackdropColor(0.34, 0.18, 0.025, 0.98)
        button:SetBackdropBorderColor(1.0, 0.72, 0.24, 1)
        button.text:SetTextColor(1.0, 0.84, 0.36)
    elseif button.hovered then
        if button.actionStyle == "confirm" then
            button:SetBackdropColor(0.06, 0.28, 0.10, 0.98)
            button:SetBackdropBorderColor(0.35, 0.95, 0.46, 1)
            button.text:SetTextColor(0.72, 1.0, 0.75)
        elseif button.actionStyle == "utility" then
            button:SetBackdropColor(0.05, 0.16, 0.30, 0.98)
            button:SetBackdropBorderColor(0.38, 0.72, 1.0, 1)
            button.text:SetTextColor(0.72, 0.88, 1.0)
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
    local iconPath, label, r, g, b = OTLGM:GetMemberBadge(member)
    if iconPath then
        texture:SetTexture(iconPath)
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        if online then texture:SetVertexColor(r or 1, g or 1, b or 1) else texture:SetVertexColor(0.38, 0.38, 0.38) end
        texture:Show()
    else
        texture:Hide()
    end
end

local function FormatShortDate(timestamp)
    if not timestamp then return "Unknown" end
    return date("%d/%m/%Y", timestamp)
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

    self.ui.generalLabel = CreateText(sidebar, "GameFontNormalSmall", "MEMBER TOOLS", 12, -14, 142, "LEFT")
    self.ui.generalLabel:SetTextColor(0.66, 0.62, 0.54)
    self.ui.officerDivider = CreateSolidTexture(sidebar, "ARTWORK", 0.42, 0.29, 0.11, 0.75)
    self.ui.officerDivider:SetHeight(1)
    self.ui.officerDivider:SetWidth(130)
    self.ui.officerDivider:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 12, -258)
    self.ui.officerLabel = CreateText(sidebar, "GameFontNormalSmall", "OFFICER TOOLS", 12, -274, 142, "LEFT")
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
        button.officerOnly = definition.officer and true or false
        AddButtonIcon(button, NAV_ICONS[definition.key], 16, true)
        self.ui.navButtons[definition.key] = button
    end

    self.ui.modeText = CreateText(sidebar, "GameFontNormalSmall", "", 12, -446, 142, "CENTER")
    self.ui.modeText:SetTextColor(0.66, 0.62, 0.54)
    self.ui.versionText = CreateText(sidebar, "GameFontNormalSmall", "Order of the Lion GM v" .. self.version, 12, -466, 142, "CENTER")
    self.ui.versionText:SetTextColor(0.48, 0.45, 0.39)

    self.ui.addonUsersButton = CreateButton(sidebar, nil, "Addon users: checking", 12, -488, 142, 24, function()
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

    local scanButton = CreateButton(sidebar, nil, "Update Roster", 12, -520, 142, 30, function()
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
    self.ui.noticeDialog:Show()
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
    self.ui.copyDialog:Show()
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
    dialog:Show()
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
    self.ui.firstRunWizard:Show()
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
        wizard.body:SetText("The interface automatically checks the permissions exposed by your guild rank.\n\nMember Mode keeps the addon clean and shows Home, Guild Info, Roster, Activity and Settings.\n\nOfficer Mode adds Overview, History, Inactive review and Recruitment. Guild actions still use the server's real permissions.")
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
    SetButtonText(self.ui.addonUsersButton, "Addon users: " .. tostring(count))
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
            GameTooltip:AddDoubleLine(classColor .. (info.name or "Unknown") .. self.colors.reset .. "  v" .. tostring(info.version or "?"), status, 1, 1, 1, info.online and 0.35 or 0.60, info.online and 1.0 or 0.60, info.online and 0.35 or 0.60)
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

function OTLGM:RefreshNavigation()
    if not self.ui.navButtons then return end
    local officer = self:IsOfficerMode()
    local y = -36
    local i, definition, button
    if self.ui.generalLabel then self.ui.generalLabel:Show() end
    for i = 1, table.getn(NAV_DEFS) do
        definition = NAV_DEFS[i]
        button = self.ui.navButtons[definition.key]
        if not definition.officer then
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", self.ui.sidebar, "TOPLEFT", 12, y)
            button:Show()
            y = y - 36
        end
    end

    if self.ui.officerDivider and self.ui.officerLabel then
        if officer then
            self.ui.officerDivider:Show()
            self.ui.officerDivider:ClearAllPoints()
            self.ui.officerDivider:SetPoint("TOPLEFT", self.ui.sidebar, "TOPLEFT", 12, y - 6)
            self.ui.officerLabel:Show()
            self.ui.officerLabel:ClearAllPoints()
            self.ui.officerLabel:SetPoint("TOPLEFT", self.ui.sidebar, "TOPLEFT", 12, y - 18)
            y = y - 40
        else
            self.ui.officerDivider:Hide()
            self.ui.officerLabel:Hide()
        end
    end

    for i = 1, table.getn(NAV_DEFS) do
        definition = NAV_DEFS[i]
        button = self.ui.navButtons[definition.key]
        if definition.officer then
            if officer then
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", self.ui.sidebar, "TOPLEFT", 12, y)
                button:Show()
                y = y - 36
            else
                button:Hide()
            end
        end
    end

    local unread = self:GetUnreadCount()
    local historyButton = self.ui.navButtons.history
    if historyButton then
        if unread > 0 then SetButtonText(historyButton, "History  (" .. tostring(unread > 99 and "99+" or unread) .. ")")
        else SetButtonText(historyButton, "History") end
    end
    self.ui.modeText:SetText(officer and self.colors.gold .. "OFFICER MODE" .. self.colors.reset or self.colors.grey .. "MEMBER MODE" .. self.colors.reset)
    self.ui.versionText:SetText("Order of the Lion GM v" .. self.version)
    self:RefreshAddonUsersIndicator()

    if self.ui.currentPage and self.ui.navButtons[self.ui.currentPage] then
        local key
        for key, button in pairs(self.ui.navButtons) do SetButtonSelected(button, key == self.ui.currentPage) end
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

    for key, page in pairs(self.ui.navButtons) do SetButtonSelected(page, key == pageKey) end
    if pageKey == "home" then self:RefreshHomePage() end
    if pageKey == "overview" then self:RefreshOverviewPage() end
    if pageKey == "guildinfo" then self:RefreshGuildInfoPage() end
    if pageKey == "roster" then self:RefreshRosterPage() end
    if pageKey == "activity" then self:RefreshActivityPage() end
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

function OTLGM:BuildHomePage(page)
    CreateText(page, "GameFontNormalLarge", "Welcome to Order of the Lion", 0, -2, 460, "LEFT")
    CreateHelpButton(page, "Home", "The starting page shows the latest roster state, unread changes, online leadership and shortcuts to the main guild tools. Cards are clickable.")
    CreateText(page, "GameFontNormal", "Your guild companion for finding people, reading information and understanding guild activity.", 0, -28, 700, "LEFT")

    self.ui.homeCards = {}
    self.ui.homeCards.members = CreateCard(page, 0, -62, 172, 78, "MEMBERS")
    self.ui.homeCards.online = CreateCard(page, 182, -62, 172, 78, "ONLINE NOW")
    self.ui.homeCards.unread = CreateCard(page, 364, -62, 172, 78, "UNREAD CHANGES")
    self.ui.homeCards.fresh = CreateCard(page, 546, -62, 172, 78, "DATABASE")

    CreateText(page, "GameFontNormal", "What you can find", 0, -155, 300, "LEFT")
    self.ui.homeLinks = {}
    self.ui.homeLinks.roster = CreateClickableCard(page, 0, -180, 350, 86, "ROSTER",
        "Find online guildmates, people in your zone, nearby levels, ranks and profession tags.", function() OTLGM:ShowPage("roster") end)
    self.ui.homeLinks.guildinfo = CreateClickableCard(page, 360, -180, 358, 86, "GUILD INFO",
        "Read guild ranks, how to receive them, leadership responsibilities, MOTD, rules and links.", function() OTLGM:ShowPage("guildinfo") end)
    self.ui.homeLinks.activity = CreateClickableCard(page, 0, -276, 350, 86, "ACTIVITY",
        "See online peaks, the activity heatmap and a light-hearted composition of classes and levels.", function() OTLGM:ShowPage("activity") end)
    self.ui.homeLinks.fourth = CreateClickableCard(page, 360, -276, 358, 86, "HISTORY",
        "Review unread joins, departures, important rank changes, milestone levels and returns.", function()
            if OTLGM:IsOfficerMode() then OTLGM:ShowPage("history") else OTLGM:ShowPage("roster") end
        end)

    local unreadPanel = CreateFrame("Frame", nil, page)
    unreadPanel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -378)
    unreadPanel:SetWidth(350)
    unreadPanel:SetHeight(122)
    CreateBackdrop(unreadPanel, 5)
    unreadPanel:SetBackdropColor(0.035, 0.030, 0.023, 0.98)
    unreadPanel:SetBackdropBorderColor(0.35, 0.28, 0.17, 1)
    CreateText(unreadPanel, "GameFontNormalSmall", "NEW SINCE LAST REVIEW", 12, -10, 326, "LEFT")
    self.ui.homeUnreadSummary = CreateWrappedText(unreadPanel, "GameFontHighlightSmall", "", 12, -32, 326, 72)
    self.ui.homeReviewButton = CreateButton(unreadPanel, nil, "Open History", 206, -86, 132, 26, function()
        if OTLGM:IsOfficerMode() then OTLGM:ShowPage("history")
        else OTLGM:ShowNotice("History in Officer Mode", "The detailed guild-management history is hidden in Member Mode.") end
    end)
    AddButtonIcon(self.ui.homeReviewButton, "Interface\\Icons\\INV_Misc_Book_09", 14, true)

    local leaders = CreateFrame("Frame", nil, page)
    leaders:SetPoint("TOPLEFT", page, "TOPLEFT", 360, -378)
    leaders:SetWidth(358)
    leaders:SetHeight(122)
    CreateBackdrop(leaders, 5)
    leaders:SetBackdropColor(0.035, 0.030, 0.023, 0.98)
    leaders:SetBackdropBorderColor(0.35, 0.28, 0.17, 1)
    CreateText(leaders, "GameFontNormalSmall", "LEADERSHIP ONLINE - CLICK TO WHISPER", 12, -10, 334, "LEFT")
    self.ui.homeLeaderButtons = {}
    local i
    for i = 1, 4 do
        local capturedIndex = i
        local button = CreateButton(leaders, nil, "", 12 + ((i - 1) * 84), -34, 78, 72, function()
            local target = OTLGM.ui.homeLeaderButtons[capturedIndex]
            if target and target.memberName then OTLGM:WhisperMember(target.memberName) end
        end)
        button.text:ClearAllPoints()
        button.text:SetPoint("TOP", button, "TOP", 0, -7)
        button.text:SetWidth(68)
        button.rankText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        button.rankText:SetPoint("BOTTOM", button, "BOTTOM", 0, 7)
        button.rankText:SetWidth(68)
        button.rankText:SetJustifyH("CENTER")
        button.rankText:SetTextColor(0.64, 0.62, 0.58)
        button.roleIcon = button:CreateTexture(nil, "OVERLAY")
        button.roleIcon:SetWidth(18)
        button.roleIcon:SetHeight(18)
        button.roleIcon:SetPoint("CENTER", button, "CENTER", 0, 2)
        button:Hide()
        self.ui.homeLeaderButtons[i] = button
    end
    self.ui.homeNoLeaders = CreateWrappedText(leaders, "GameFontNormalSmall", "No leadership members are currently shown online.", 16, -46, 326, 48)
    self.ui.homeNoLeaders:SetTextColor(0.55, 0.55, 0.55)
end

function OTLGM:RefreshHomePage()
    if not self.ui.homeCards then return end
    local db = self:GetGuildDB()
    if not db then return end
    local unread = self:GetUnreadSummary()
    local freshText, freshColor = self:GetFreshnessText(db.lastScan)

    self.ui.homeCards.members.value:SetText(self.colors.white .. tostring(db.lastTotal or 0) .. self.colors.reset)
    self.ui.homeCards.members.sub:SetText("Tracked characters")
    self.ui.homeCards.online.value:SetText(self.colors.green .. tostring(db.lastOnline or 0) .. self.colors.reset)
    self.ui.homeCards.online.sub:SetText("Latest valid snapshot")
    self.ui.homeCards.unread.value:SetText((unread.total > 0 and self.colors.gold or self.colors.grey) .. tostring(unread.total) .. self.colors.reset)
    self.ui.homeCards.unread.sub:SetText(unread.total > 0 and "Open History to review" or "Everything reviewed")
    self.ui.homeCards.fresh.value:SetText(freshColor .. freshText .. self.colors.reset)
    self.ui.homeCards.fresh.sub:SetText(db.lastScan and self:Stamp(db.lastScan) or "Run the first update")

    self.ui.homeUnreadSummary:SetText(
        self.colors.green .. tostring(unread.joins) .. " joined" .. self.colors.reset .. "  " ..
        self.colors.red .. tostring(unread.leaves) .. " left" .. self.colors.reset .. "\n" ..
        self.colors.gold .. tostring(unread.ranks) .. " rank changes" .. self.colors.reset .. "  " ..
        self.colors.blue .. tostring(unread.levels) .. " milestones" .. self.colors.reset .. "\n" ..
        tostring(unread.returns) .. " returned  -  " .. tostring(unread.notes) .. " note changes"
    )

    if self:IsOfficerMode() then
        self.ui.homeLinks.fourth.title:SetText("HISTORY")
        self.ui.homeLinks.fourth.body:SetText("Review unread joins, departures, important rank changes, milestone levels and returns.")
        self.ui.homeReviewButton:Show()
    else
        self.ui.homeLinks.fourth.title:SetText("FIND GUILDMATES")
        self.ui.homeLinks.fourth.body:SetText("Use My Zone, Near My Level, Online and Profession filters to find people to play with.")
        self.ui.homeReviewButton:Hide()
    end

    local leaders = self:GetLeadershipOnline()
    local i
    for i = 1, 4 do
        local button = self.ui.homeLeaderButtons[i]
        local member = leaders[i]
        if member then
            button.memberName = member.name
            SetButtonText(button, member.name)
            button.text:SetTextColor(1, 0.82, 0.35)
            button.rankText:SetText(member.rank or "Leadership")
            ApplyLeadershipIcon(button.roleIcon, member, true)
            button:Show()
        else
            button.memberName = nil
            button:Hide()
        end
    end
    if table.getn(leaders) == 0 then self.ui.homeNoLeaders:Show() else self.ui.homeNoLeaders:Hide() end

end

function OTLGM:BuildOverviewPage(page)
    CreateText(page, "GameFontNormalLarge", "Guild Overview", 0, -2, 360, "LEFT")
    CreateHelpButton(page, "Overview", "Officer-oriented snapshot of growth, activity, raid strength, leadership availability, addon adoption and recent guild events.")
    CreateText(page, "GameFontNormalSmall", "A practical management view of the latest valid local roster database.", 0, -28, 700, "LEFT")

    self.ui.overviewCards = {}
    self.ui.overviewCards.members = CreateCard(page, 0, -62, 140, 76, "MEMBERS")
    self.ui.overviewCards.online = CreateCard(page, 150, -62, 140, 76, "ONLINE")
    self.ui.overviewCards.joined = CreateCard(page, 300, -62, 140, 76, "JOINED / LEFT")
    self.ui.overviewCards.inactive = CreateCard(page, 450, -62, 140, 76, "INACTIVE 30D+")
    self.ui.overviewCards.unread = CreateCard(page, 600, -62, 118, 76, "UNREAD")

    self.ui.overviewPulseCards = {}
    self.ui.overviewPulseCards.level60 = CreateCard(page, 0, -148, 170, 68, "LEVEL 60")
    self.ui.overviewPulseCards.core = CreateCard(page, 182, -148, 170, 68, "CORE RAIDERS")
    self.ui.overviewPulseCards.leadership = CreateCard(page, 364, -148, 170, 68, "LEADERSHIP")
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
    local freshText, freshColor = self:GetFreshnessText(db.lastScan)
    self.ui.overviewCards.members.value:SetText(tostring(db.lastTotal or 0))
    self.ui.overviewCards.members.sub:SetText("Tracked characters")
    self.ui.overviewCards.online.value:SetText(self.colors.green .. tostring(db.lastOnline or 0) .. self.colors.reset)
    self.ui.overviewCards.online.sub:SetText("Latest valid snapshot")
    self.ui.overviewCards.joined.value:SetText(self.colors.green .. "+" .. tostring(stats.joins) .. self.colors.reset .. "  " .. self.colors.red .. "-" .. tostring(stats.leaves) .. self.colors.reset)
    self.ui.overviewCards.joined.sub:SetText("Last 7 days")
    self.ui.overviewCards.inactive.value:SetText(tostring(stats.inactive30))
    self.ui.overviewCards.inactive.sub:SetText("Offline 30 days or more")
    self.ui.overviewCards.unread.value:SetText(self.colors.gold .. tostring(stats.unread) .. self.colors.reset)
    self.ui.overviewCards.unread.sub:SetText("Awaiting review")

    self.ui.overviewPulseCards.level60.value:SetText(self.colors.gold .. tostring(roles.level60Online) .. self.colors.reset .. " / " .. tostring(roles.level60))
    self.ui.overviewPulseCards.level60.sub:SetText("online / total")
    self.ui.overviewPulseCards.core.value:SetText(self.colors.purple .. tostring(roles.coreOnline) .. self.colors.reset .. " / " .. tostring(roles.core))
    self.ui.overviewPulseCards.core.sub:SetText("online / total")
    self.ui.overviewPulseCards.leadership.value:SetText(self.colors.gold .. tostring(roles.leadershipOnline) .. self.colors.reset .. " / " .. tostring(roles.leadership))
    self.ui.overviewPulseCards.leadership.sub:SetText("online / total")
    self.ui.overviewPulseCards.addon.value:SetText(self.colors.green .. tostring(addonUsers) .. self.colors.reset)
    self.ui.overviewPulseCards.addon.sub:SetText(tostring(addonOnline) .. " online - hover for names")

    local netColor = stats.net >= 0 and self.colors.green or self.colors.red
    self.ui.overviewGrowth:SetText("7-day growth: " .. netColor .. (stats.net >= 0 and "+" or "") .. tostring(stats.net) .. self.colors.reset)
    self.ui.overviewChanges:SetText(
        "Rank changes: " .. tostring(stats.ranks) .. "    Milestones: " .. tostring(stats.levels) .. "    Level 60: " .. tostring(stats.level60) ..
        "\nReturned: " .. tostring(stats.returns) .. "    Note changes: " .. tostring(stats.notes) .. "    Restricted: " .. tostring(roles.restricted)
    )
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
    self.ui.publicNoteEdit = CreateEditBox(panel, "OTLGM_PublicNoteEdit", 8, -157, 186, 38, true)
    self.ui.publicNoteEdit:SetMaxLetters(31)
    self.ui.publicNoteEdit:SetScript("OnEditFocusGained", function() if this.readOnly then this:ClearFocus() end end)
    self.ui.officerNoteLabel = CreateText(panel, "GameFontNormalSmall", "OFFICER NOTE", 10, -202, 182, "LEFT")
    self.ui.officerNoteEdit = CreateEditBox(panel, "OTLGM_OfficerNoteEdit", 8, -216, 186, 38, true)
    self.ui.officerNoteEdit:SetMaxLetters(31)
    self.ui.officerNoteEdit:SetScript("OnEditFocusGained", function() if this.readOnly then this:ClearFocus() end end)

    self.ui.memberHistoryText = CreateWrappedText(panel, "GameFontNormalSmall", "", 10, -260, 182, 34)
    self.ui.memberHistoryText:SetTextColor(0.64, 0.62, 0.57)
    self.ui.memberOfficerFrames = { self.ui.officerNoteLabel, self.ui.officerNoteEdit }

    self.ui.saveNotesButton = CreateButton(panel, nil, "Save Notes", 8, -294, 186, 26, function()
        if OTLGM.ui.selectedMember then
            OTLGM:SaveMemberNotes(OTLGM.ui.selectedMember, OTLGM.ui.publicNoteEdit:GetText(), OTLGM.ui.officerNoteEdit:GetText())
        end
    end)
    AddButtonIcon(self.ui.saveNotesButton, "Interface\\Icons\\INV_Misc_Note_01", 14, true)
    self.ui.promoteButton = CreateButton(panel, nil, "Promote", 8, -326, 58, 26, function()
        if OTLGM.ui.selectedMember then OTLGM:PromoteMember(OTLGM.ui.selectedMember) end
    end)
    AddButtonIcon(self.ui.promoteButton, "Interface\\Icons\\Ability_Warrior_BattleShout", 14, false)
    self.ui.demoteButton = CreateButton(panel, nil, "Demote", 72, -326, 58, 26, function()
        if OTLGM.ui.selectedMember then OTLGM:DemoteMember(OTLGM.ui.selectedMember) end
    end)
    AddButtonIcon(self.ui.demoteButton, "Interface\\Icons\\Spell_Shadow_Fumble", 14, false)
    self.ui.removeButton = CreateButton(panel, nil, "Remove", 136, -326, 58, 26, function()
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
    AddButtonIcon(self.ui.inviteButton, "Interface\\Icons\\INV_Misc_GroupLooking", 14, false)
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
        if officer then
            self.ui.officerNoteLabel:Show()
            self.ui.officerNoteEdit:Show()
            local frameIndex
            for frameIndex = 1, table.getn(self.ui.memberOfficerButtons) do self.ui.memberOfficerButtons[frameIndex]:Show() end
        else
            self.ui.officerNoteLabel:Hide()
            self.ui.officerNoteEdit:Hide()
            local frameIndex
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
    local professionText = table.getn(professions) > 0 and ("\nProfessions (guild note): " .. table.concat(professions, ", ")) or ""
    self.ui.memberSummary:SetText("Level " .. tostring(member.level or 0) .. " " .. (member.class or "") .. "  -  " .. (member.zone or "Unknown zone") .. professionText)
    if member.joinedAt then
        self.ui.memberDates:SetText("Joined: " .. FormatShortDate(member.joinedAt))
    else
        self.ui.memberDates:SetText("Tracked since: " .. FormatShortDate(member.trackedSince))
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
        self.ui.officerNoteLabel:Show()
        self.ui.officerNoteEdit:Show()
        for i = 1, table.getn(self.ui.memberOfficerButtons) do self.ui.memberOfficerButtons[i]:Show() end
        SetEditVisual(self.ui.publicNoteEdit, self:CanEditPublicNotes())
        SetEditVisual(self.ui.officerNoteEdit, self:CanEditOfficerNotes())
        SetButtonEnabled(self.ui.saveNotesButton, self:CanUseOfficerAction("NOTE"), "Your guild rank cannot edit notes.")
        SetButtonEnabled(self.ui.promoteButton, self:CanPromoteMembers(), "Your guild rank cannot promote members.")
        SetButtonEnabled(self.ui.demoteButton, self:CanDemoteMembers(), "Your guild rank cannot demote members.")
        SetButtonEnabled(self.ui.removeButton, self:CanRemoveMembers() and member.name ~= UnitName("player"), "Your guild rank cannot remove this member.")
    else
        self.ui.officerNoteLabel:Hide()
        self.ui.officerNoteEdit:Hide()
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
    heat:SetWidth(490)
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
    composition:SetPoint("TOPLEFT", page, "TOPLEFT", 500, -154)
    composition:SetWidth(218)
    composition:SetHeight(340)
    CreateBackdrop(composition, 5)
    composition:SetBackdropColor(0.028, 0.025, 0.021, 0.98)
    composition:SetBackdropBorderColor(0.36, 0.28, 0.17, 1)
    CreateText(composition, "GameFontNormal", "GUILD COMPOSITION", 12, -10, 194, "LEFT")
    self.ui.compositionTotal = CreateWrappedText(composition, "GameFontNormalSmall", "", 12, -38, 194, 190)
    self.ui.compositionOnline = CreateWrappedText(composition, "GameFontNormalSmall", "", 12, -228, 194, 80)
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
    table.insert(lines, "Levels 1-19: " .. tostring(total.levels.low))
    table.insert(lines, "Levels 20-39: " .. tostring(total.levels.mid))
    table.insert(lines, "Levels 40-59: " .. tostring(total.levels.high))
    table.insert(lines, "Level 60: " .. tostring(total.levels.max))
    self.ui.compositionTotal:SetText(table.concat(lines, "\n"))

    self.ui.compositionOnline:SetText(
        self.colors.green .. "ONLINE NOW - " .. tostring(online.total) .. self.colors.reset .. "\n" ..
        "Level 60 online: " .. tostring(online.levels.max) .. "\n" ..
        "This view uses only roster class and level data."
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

function OTLGM:BuildRecruitmentPage(page)
    CreateText(page, "GameFontNormalLarge", "Guild Recruitment", 0, -2, 320, "LEFT")
    CreateHelpButton(page, "Recruitment", "Pinned messages are protected originals. Custom slots are persistent and can be renamed. Last-sent times are remembered. Confirmation preview can be disabled in Settings.")
    CreateText(page, "GameFontNormalSmall", "Protected presets, named custom slots, message rotation and last-sent reminders.", 0, -28, 520, "LEFT")

    CreateText(page, "GameFontNormalSmall", "WORLD CHANNEL", 548, -8, 102, "RIGHT")
    CreateText(page, "GameFontNormalLarge", "/", 656, -4, 14, "LEFT")
    local channel = CreateEditBox(page, "OTLGM_ChannelEdit", 670, -3, 40, 27, false)
    channel:SetMaxLetters(2)
    channel:SetScript("OnTextChanged", function()
        local text = this:GetText() or ""
        local digits = string.gsub(text, "%D", "")
        if digits ~= text then this:SetText(digits) return end
        OTLGM_DB.settings.worldChannel = digits
        OTLGM:RefreshRecruitmentPage()
    end)
    channel:SetScript("OnEnterPressed", function() this:ClearFocus() end)
    self.ui.channelEdit = channel

    CreateText(page, "GameFontNormal", "Pinned messages", 0, -56, 220, "LEFT")
    self.ui.recruitPresetButtons = {}
    self.ui.presetLastSentTexts = {}
    self.ui.presetSendButtons = {}
    local presetKeys = { "BASE1", "BASE2", "GUILDINFO" }
    local i
    for i = 1, table.getn(presetKeys) do
        local key = presetKeys[i]
        local capturedKey = key
        local row = CreateFrame("Frame", nil, page)
        row:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -76 - ((i - 1) * 58))
        row:SetWidth(718)
        row:SetHeight(52)
        CreateBackdrop(row, 4)
        row:SetBackdropColor(0.040, 0.032, 0.023, 0.98)
        row:SetBackdropBorderColor(0.35, 0.27, 0.16, 1)
        local select = CreateButton(row, nil, self.recruitmentPresets[key].label, 8, -10, 92, 31, function()
            OTLGM:SelectRecruitment(capturedKey)
        end)
        self.ui.recruitPresetButtons[key] = select
        local target = self.recruitmentPresets[key].target == "GUILD" and "PINNED - GUILD" or "PINNED - WORLD"
        local badge = CreateText(row, "GameFontNormalSmall", target, 110, -6, 126, "LEFT")
        badge:SetTextColor(0.72, 0.55, 0.22)
        CreateWrappedText(row, "GameFontNormalSmall", self.recruitmentPresets[key].text, 110, -19, 474, 20)
        self.ui.presetLastSentTexts[key] = CreateText(row, "GameFontNormalSmall", "Last sent: never", 110, -39, 474, "LEFT")
        self.ui.presetLastSentTexts[key]:SetTextColor(0.52, 0.52, 0.52)
        local sendLabel = self.recruitmentPresets[key].target == "GUILD" and "Send Guild" or "Send /6"
        self.ui.presetSendButtons[key] = CreateButton(row, nil, sendLabel, 592, -10, 116, 31, function()
            OTLGM:RequestRecruitmentSend(capturedKey, false)
        end)
    end

    CreateText(page, "GameFontNormal", "Saved custom slots", 0, -258, 200, "LEFT")
    self.ui.customSlotButtons = {}
    self.ui.customSlotLastSent = {}
    for i = 1, 3 do
        local key = "CUSTOM" .. tostring(i)
        local capturedKey = key
        local button = CreateButton(page, nil, "", (i - 1) * 242, -280, 226, 44, function()
            OTLGM:SelectRecruitment(capturedKey)
        end)
        button.text:ClearAllPoints()
        button.text:SetPoint("TOP", button, "TOP", 0, -7)
        button.customIndex = i
        local sent = CreateText(button, "GameFontNormalSmall", "Never sent", 8, -27, 210, "CENTER")
        sent:SetTextColor(0.52, 0.52, 0.52)
        self.ui.customSlotLastSent[i] = sent
        self.ui.recruitPresetButtons[key] = button
        self.ui.customSlotButtons[key] = button
    end

    self.ui.recruitmentState = CreateText(page, "GameFontNormalSmall", "", 0, -336, 410, "LEFT")
    CreateText(page, "GameFontNormalSmall", "SAVE COPY TO", 420, -336, 92, "RIGHT")
    self.ui.saveCopyButtons = {}
    for i = 1, 3 do
        local slot = i
        self.ui.saveCopyButtons[i] = CreateButton(page, nil, tostring(i), 522 + ((i - 1) * 42), -332, 34, 25, function()
            OTLGM:SaveCurrentToCustom(slot)
        end)
    end

    CreateText(page, "GameFontNormalSmall", "WORKING COPY", 0, -362, 120, "LEFT")
    self.ui.workingLastSent = CreateText(page, "GameFontNormalSmall", "Last sent: never", 410, -362, 308, "RIGHT")
    self.ui.workingLastSent:SetTextColor(0.52, 0.52, 0.52)
    local edit = CreateEditBox(page, "OTLGM_RecruitmentEdit", 0, -378, 718, 72, true)
    edit:SetMaxLetters(240)
    edit:SetScript("OnTextChanged", function()
        OTLGM_DB.settings.recruitmentMessage = this:GetText() or ""
        OTLGM:RefreshRecruitmentCount()
    end)
    self.ui.recruitmentEdit = edit
    self.ui.recruitmentCount = CreateText(page, "GameFontNormalSmall", "0 / 240", 632, -454, 86, "RIGHT")

    CreateText(page, "GameFontNormalSmall", "CUSTOM SLOT NAME", 0, -478, 116, "LEFT")
    self.ui.customNameEdit = CreateEditBox(page, "OTLGM_CustomNameEdit", 120, -472, 174, 28, false)
    self.ui.customNameEdit:SetMaxLetters(24)
    self.ui.renameCustomButton = CreateButton(page, nil, "Rename", 302, -472, 74, 28, function()
        local key = OTLGM_DB.settings.selectedRecruitment or ""
        local customKey = string.gsub(key, "^CUSTOM", "")
        local index = tonumber(customKey)
        if index then OTLGM:RenameCustomMessage(index, OTLGM.ui.customNameEdit:GetText()) end
    end)

    self.ui.customWorldButton = CreateButton(page, nil, "World", 386, -472, 62, 28, function()
        OTLGM_DB.settings.customTarget = "WORLD"
        OTLGM:RefreshRecruitmentPage()
    end)
    self.ui.customGuildButton = CreateButton(page, nil, "Guild", 454, -472, 62, 28, function()
        OTLGM_DB.settings.customTarget = "GUILD"
        OTLGM:RefreshRecruitmentPage()
    end)
    self.ui.saveSlotButton = CreateButton(page, nil, "Save Slot", 526, -472, 82, 28, function() OTLGM:SaveSelectedCustom() end)
    self.ui.clearSlotButton = CreateButton(page, nil, "Clear", 614, -472, 58, 28, function() OTLGM:ClearSelectedCustom() end)
    self.ui.sendCurrentButton = CreateButton(page, nil, "Send", 678, -472, 40, 28, function()
        OTLGM:RequestRecruitmentSend(OTLGM_DB.settings.selectedRecruitment or "WORKING", true)
    end)
    self.ui.sendNextButton = CreateButton(page, nil, "Send Next Recruit", 0, -502, 150, 26, function()
        local index = OTLGM_DB.settings.nextRecruitIndex or 1
        local key = index == 1 and "BASE1" or "BASE2"
        OTLGM:RequestRecruitmentSend(key, false, true)
    end)
    self.ui.recruitReadyText = CreateText(page, "GameFontNormalSmall", "", 164, -508, 554, "LEFT")
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
            OTLGM:MarkRecruitmentSent(key)
            if rotateAfter then
                OTLGM_DB.settings.nextRecruitIndex = (OTLGM_DB.settings.nextRecruitIndex or 1) == 1 and 2 or 1
            end
        end
    end
    if OTLGM_DB.settings.confirmRecruitment then
        self:ShowConfirm("Send Recruitment Message", label .. " -> " .. destination .. "\n\n" .. message, "Send", SendNow)
    else
        SendNow()
    end
end

function OTLGM:RefreshRecruitmentPage()
    if not self.ui.recruitmentEdit then return end
    self:EnsureDB()
    local selected = OTLGM_DB.settings.selectedRecruitment or "BASE1"
    local i, key, button
    if self.ui.channelEdit:GetText() ~= tostring(OTLGM_DB.settings.worldChannel or "6") then
        self.ui.channelEdit:SetText(tostring(OTLGM_DB.settings.worldChannel or "6"))
    end

    local presetKeys = { "BASE1", "BASE2", "GUILDINFO" }
    for i = 1, table.getn(presetKeys) do
        key = presetKeys[i]
        SetButtonSelected(self.ui.recruitPresetButtons[key], selected == key)
        self.ui.presetLastSentTexts[key]:SetText(self:GetRecruitmentLastSentText(key, false))
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
        self.ui.customSlotLastSent[i]:SetText(self:GetRecruitmentLastSentText(key, true))
    end

    local currentText = OTLGM_DB.settings.recruitmentMessage or ""
    if self.ui.recruitmentEdit:GetText() ~= currentText then self.ui.recruitmentEdit:SetText(currentText) end
    self.ui.workingLastSent:SetText(self:GetRecruitmentLastSentText(selected, false))

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
    local readyKey = (OTLGM_DB.settings.nextRecruitIndex or 1) == 1 and "BASE1" or "BASE2"
    self.ui.recruitReadyText:SetText("Next rotation message: " .. self.recruitmentPresets[readyKey].label .. "  -  " .. self:GetRecruitmentLastSentText(readyKey, false))
    self:RefreshRecruitmentCount()
end

function OTLGM:BuildSettingsPage(page)
    CreateText(page, "GameFontNormalLarge", "Addon Settings", 0, -2, 300, "LEFT")
    CreateHelpButton(page, "Settings", "Configure scanning, interface mode, size, tooltips and safe recruitment confirmation. Diagnostics show which APIs and saved data are currently available.")
    CreateText(page, "GameFontNormalSmall", "All choices are saved in OTLGM_DB inside the WTF folder.", 0, -28, 700, "LEFT")

    local left = CreateFrame("Frame", nil, page)
    left:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -58)
    left:SetWidth(360)
    left:SetHeight(448)
    CreateBackdrop(left, 5)
    left:SetBackdropColor(0.032, 0.028, 0.023, 0.98)
    left:SetBackdropBorderColor(0.36, 0.28, 0.17, 1)

    CreateText(left, "GameFontNormal", "ROSTER UPDATE INTERVAL", 12, -12, 330, "LEFT")
    self.ui.scanIntervalButtons = {}
    local intervals = { {0,"Off"}, {600,"10m"}, {1200,"20m"}, {1800,"30m"}, {3600,"60m"} }
    local i
    for i = 1, table.getn(intervals) do
        local seconds = intervals[i][1]
        local button = CreateButton(left, nil, intervals[i][2], 12 + ((i - 1) * 65), -38, 57, 28, function()
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
    CreateText(left, "GameFontNormalSmall", "Default and recommended: 20 minutes.", 12, -73, 330, "LEFT"):SetTextColor(0.58, 0.58, 0.58)

    CreateText(left, "GameFontNormal", "INTERFACE MODE", 12, -103, 330, "LEFT")
    self.ui.modeButtons = {}
    local modes = { "AUTO", "MEMBER", "OFFICER" }
    for i = 1, 3 do
        local mode = modes[i]
        self.ui.modeButtons[mode] = CreateButton(left, nil, mode == "AUTO" and "Auto" or (mode == "MEMBER" and "Member" or "Officer"), 12 + ((i - 1) * 108), -129, 98, 28, function()
            OTLGM:SetUIMode(mode)
            OTLGM:RefreshSettingsPage()
        end)
    end

    CreateText(left, "GameFontNormal", "WINDOW SCALE", 12, -174, 330, "LEFT")
    self.ui.scaleButtons = {}
    local scales = { {0.8,"80%"}, {0.9,"90%"}, {1.0,"100%"}, {1.1,"110%"}, {1.2,"120%"} }
    for i = 1, table.getn(scales) do
        local scale = scales[i][1]
        local button = CreateButton(left, nil, scales[i][2], 12 + ((i - 1) * 65), -200, 57, 28, function()
            OTLGM_DB.settings.uiScale = scale
            OTLGM.ui.main:SetScale(scale)
            OTLGM:RefreshSettingsPage()
        end)
        button.scaleValue = scale
        self.ui.scaleButtons[i] = button
    end

    self.ui.settingChecks = {}
    self.ui.settingChecks.scanChat = CreateCheck(left, "OTLGM_SettingScanChat", "One chat line after successful manual/timed database update", 12, -244, function()
        OTLGM_DB.settings.scanChat = this:GetChecked() and true or false
    end)
    self.ui.settingChecks.minimap = CreateCheck(left, "OTLGM_SettingMinimap", "Show minimap button", 12, -278, function()
        OTLGM_DB.settings.showMinimap = this:GetChecked() and true or false
        OTLGM:ApplyMinimapVisibility()
    end)
    self.ui.settingChecks.help = CreateCheck(left, "OTLGM_SettingHelp", "Show contextual help tooltips", 12, -312, function()
        OTLGM_DB.settings.showHelp = this:GetChecked() and true or false
    end)
    self.ui.settingChecks.confirm = CreateCheck(left, "OTLGM_SettingConfirmRecruit", "Preview recruitment messages before sending", 12, -346, function()
        OTLGM_DB.settings.confirmRecruitment = this:GetChecked() and true or false
    end)
    self.ui.settingChecks.lock = CreateCheck(left, "OTLGM_SettingLock", "Lock the main window position", 12, -380, function()
        OTLGM_DB.settings.windowLocked = this:GetChecked() and true or false
    end)
    self.ui.settingChecks.home = CreateCheck(left, "OTLGM_SettingHome", "Open Home instead of the last page", 12, -414, function()
        OTLGM_DB.settings.openHome = this:GetChecked() and true or false
    end)

    local right = CreateFrame("Frame", nil, page)
    right:SetPoint("TOPLEFT", page, "TOPLEFT", 370, -58)
    right:SetWidth(348)
    right:SetHeight(448)
    CreateBackdrop(right, 5)
    right:SetBackdropColor(0.032, 0.028, 0.023, 0.98)
    right:SetBackdropBorderColor(0.36, 0.28, 0.17, 1)
    CreateText(right, "GameFontNormal", "DATABASE AND DIAGNOSTICS", 12, -12, 324, "LEFT")
    self.ui.diagnosticsText = CreateWrappedText(right, "GameFontNormalSmall", "", 12, -40, 324, 220)
    self.ui.versionUpdateText = CreateWrappedText(right, "GameFontNormalSmall", "", 12, -264, 324, 34)

    CreateButton(right, nil, "Export Backup", 12, -304, 100, 28, function()
        OTLGM:ShowCopyDialog("Order of the Lion Addon Backup", OTLGM:ExportBackup())
    end)
    CreateButton(right, nil, "Import Backup", 120, -304, 100, 28, function()
        OTLGM.ui.importDialog.edit:SetText("")
        OTLGM.ui.importDialog:Show()
        OTLGM.ui.importDialog.edit:SetFocus()
    end)
    CreateButton(right, nil, "First-Run Guide", 228, -304, 108, 28, function() OTLGM:OpenFirstRunWizard() end)
    CreateButton(right, nil, "Reset Window", 12, -340, 100, 28, function()
        OTLGM_DB.settings.windowX = 0
        OTLGM_DB.settings.windowY = 10
        OTLGM.ui.main:ClearAllPoints()
        OTLGM.ui.main:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
    end)
    CreateButton(right, nil, "Copy Weekly", 120, -340, 100, 28, function()
        OTLGM:ShowCopyDialog("Weekly Guild Summary", OTLGM:GenerateWeeklySummary())
    end)
    CreateButton(right, nil, "Reset Guild Data", 228, -340, 108, 28, function()
        OTLGM:ShowConfirm("Reset Local Guild Data", "This removes the local roster history and analytics for the current guild. It does not change anything on the server.\n\nExport a backup first if you need to keep the history.", "Reset", function()
            OTLGM:ResetGuildData()
        end)
    end)
    self.ui.settingChecks.classColors = CreateCheck(right, "OTLGM_SettingClassColors", "Use class colours for names", 12, -380, function()
        OTLGM_DB.settings.classColors = this:GetChecked() and true or false
        OTLGM:RefreshAll()
    end)
    self.ui.settingChecks.leadership = CreateCheck(right, "OTLGM_SettingLeadership", "Show leadership, raider and restricted-rank icons", 12, -414, function()
        OTLGM_DB.settings.highlightLeadership = this:GetChecked() and true or false
        OTLGM:RefreshAll()
    end)
end

function OTLGM:RefreshSettingsPage()
    if not self.ui.scanIntervalButtons then return end
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
    self:RefreshHistoryPage()
    self:RefreshInactivePage()
    self:RefreshRecruitmentPage()
    self:RefreshSettingsPage()
end
