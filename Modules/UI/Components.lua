-- Order of the Lion Guild Manager 1.8.0 shared UI components
-- Shared opaque UI toolkit for the Stage B shell and migrated pages.
-- Vanilla / OctoWoW / Lua 5.0 compatible. This module adds no OnUpdate.

if not OTLGM then return end

local Toolkit = {}
OTLGM.UI = Toolkit
OTLGM.uiToolkitButtons = OTLGM.uiToolkitButtons or {}
OTLGM.uiToolkitSurfaces = OTLGM.uiToolkitSurfaces or {}

local BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 10,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

-- Surface backgrounds must not depend on UI-Tooltip-Background.  Some
-- Vanilla-derived clients render that texture translucently even when the
-- backdrop alpha is one.  Every Toolkit surface therefore owns a separate
-- solid Texture, while this backdrop is used only for its border.
local SURFACE_BORDER = {
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    edgeSize = 10,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local COLORS = {
    window = { 0.010, 0.009, 0.008, 1 },
    surface = { 0.027, 0.023, 0.018, 1 },
    card = { 0.043, 0.034, 0.023, 1 },
    raised = { 0.062, 0.046, 0.027, 1 },
    input = { 0.015, 0.014, 0.012, 1 },
    gold = { 0.93, 0.68, 0.22, 1 },
    goldDark = { 0.43, 0.29, 0.11, 1 },
    goldMuted = { 0.62, 0.47, 0.23, 1 },
    white = { 0.92, 0.90, 0.84, 1 },
    grey = { 0.66, 0.64, 0.59, 1 },
    blue = { 0.20, 0.48, 0.76, 1 },
    purple = { 0.69, 0.42, 1.00, 1 },
    orange = { 0.90, 0.52, 0.12, 1 },
    green = { 0.25, 0.70, 0.36, 1 },
    red = { 0.78, 0.16, 0.10, 1 },
}
Toolkit.colors = COLORS

local function ApplyColor(frame, color, border)
    if frame.SetBackdropColor then
        frame:SetBackdropColor(color[1], color[2], color[3], 1)
    end
    border = border or COLORS.goldDark
    if frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(border[1], border[2], border[3], 1)
    end
end

local function Prepare(control, kind)
    if OTLGM.PrepareInteractiveControl170 then
        OTLGM:PrepareInteractiveControl170(control, kind)
    elseif control and control.EnableMouse then
        control:EnableMouse(true)
    end
end

local function RegisterSurface(frame, kind)
    frame.otlSurfaceKind = kind
    frame.otlOpaque = true
    frame.otlSurfaceAlpha = 1
    table.insert(OTLGM.uiToolkitSurfaces, frame)
    return frame
end

local function ApplySurfaceColor(frame, color, border)
    if not frame then return end
    color = color or COLORS.surface
    border = border or COLORS.goldDark
    local background = frame.otlSolidBackground
    if not background then
        background = frame:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints(frame)
        if background.SetDrawLayer then background:SetDrawLayer("BACKGROUND") end
        frame.otlSolidBackground = background
    end
    -- SetTexture(r,g,b,a) creates an actual one-colour texture in the
    -- Interface 11200 API.  This is deliberately not a backdrop bgFile.
    background:SetTexture(color[1], color[2], color[3], 1)
    background:SetAlpha(1)
    background:Show()
    background.otlSolidAlpha = 1
    background.otlSolidColor = { color[1], color[2], color[3], 1 }
    background.otlLayerOrder = 1
    frame.otlContentLayerOrder = 2
    frame.otlBorderLayerOrder = 3
    frame.otlSurfaceColor = background.otlSolidColor
    if frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(border[1], border[2], border[3], 1)
    end
end

function Toolkit:MakeOpaque(frame, color, border)
    if not frame then return nil end
    ApplySurfaceColor(frame, color or COLORS.input, border or COLORS.goldDark)
    frame:SetAlpha(1)
    frame.otlOpaque = true
    frame.otlSurfaceAlpha = 1
    return frame
end

local function Text(parent, value, template, justify)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    label:SetText(value or "")
    label:SetJustifyH(justify or "LEFT")
    label:SetTextColor(COLORS.white[1], COLORS.white[2], COLORS.white[3])
    return label
end
Toolkit.Text = Text

function Toolkit:SetText(control, value)
    if not control then return end
    control.labelText = tostring(value or "")
    if control.text then control.text:SetText(control.labelText)
    elseif control.SetText then control:SetText(control.labelText) end
end

function Toolkit:Surface(parent, kind, width, height, name)
    local frame = CreateFrame("Frame", name, parent)
    frame:SetWidth(width or 100)
    frame:SetHeight(height or 100)
    frame:SetBackdrop(SURFACE_BORDER)
    local color = kind == "window" and COLORS.window or (kind == "raised" and COLORS.raised or COLORS.surface)
    ApplySurfaceColor(frame, color, COLORS.goldDark)
    frame:SetAlpha(1)
    return RegisterSurface(frame, kind or "surface")
end

function Toolkit:Card(parent, width, height, title)
    local card = self:Surface(parent, "card", width, height)
    ApplySurfaceColor(card, COLORS.card, COLORS.goldDark)
    if title and title ~= "" then
        card.title = Text(card, string.upper(title), "GameFontNormalSmall", "LEFT")
        card.title:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -9)
        card.title:SetWidth((width or 100) - 20)
        card.title:SetTextColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3])
    end
    return card
end

local function ApplyButton(button)
    if not button then return end
    local style = button.otlStyle or "secondary"
    local selected = button.otlSelected
    local disabled = button.otlDisabled
    local hover = button.otlHovered
    local background, border, textColor

    if disabled then
        background, border, textColor = { 0.035, 0.032, 0.028, 1 }, { 0.20, 0.18, 0.15, 1 }, { 0.42, 0.40, 0.36, 1 }
    elseif style == "danger" then
        background = hover and { 0.32, 0.035, 0.025, 1 } or { 0.20, 0.022, 0.018, 1 }
        border, textColor = COLORS.red, { 1.00, 0.62, 0.54, 1 }
    elseif style == "primary" then
        background = selected and { 0.38, 0.20, 0.035, 1 } or (hover and { 0.30, 0.14, 0.025, 1 } or { 0.20, 0.095, 0.018, 1 })
        border, textColor = COLORS.gold, { 1.00, 0.86, 0.48, 1 }
    elseif style == "utility" then
        background = selected and { 0.035, 0.15, 0.27, 1 } or (hover and { 0.030, 0.105, 0.19, 1 } or { 0.020, 0.065, 0.12, 1 })
        border, textColor = COLORS.blue, { 0.72, 0.88, 1.00, 1 }
    elseif style == "nav" then
        if selected then
            background, border, textColor = { 0.29, 0.15, 0.025, 1 }, COLORS.gold, { 1.00, 0.84, 0.38, 1 }
        elseif hover then
            background, border, textColor = { 0.085, 0.068, 0.046, 1 }, COLORS.goldMuted, COLORS.white
        else
            background, border, textColor = { 0.030, 0.027, 0.023, 1 }, { 0.20, 0.18, 0.15, 1 }, COLORS.grey
        end
    elseif style == "tab" or style == "filter" then
        background = selected and { 0.29, 0.15, 0.025, 1 } or (hover and { 0.13, 0.075, 0.025, 1 } or { 0.045, 0.037, 0.027, 1 })
        border = selected and COLORS.gold or COLORS.goldDark
        textColor = selected and { 1.00, 0.84, 0.38, 1 } or COLORS.white
    elseif style == "inline" then
        background = hover and { 0.12, 0.075, 0.030, 1 } or { 0.030, 0.026, 0.020, 1 }
        border, textColor = COLORS.goldDark, COLORS.white
    else
        background = hover and { 0.15, 0.090, 0.032, 1 } or { 0.075, 0.055, 0.030, 1 }
        border, textColor = COLORS.goldMuted, COLORS.white
    end
    ApplySurfaceColor(button, background, border)
    ApplyColor(button, background, border)
    if button.text then button.text:SetTextColor(textColor[1], textColor[2], textColor[3]) end
    if button.otlAccent then
        if selected and not disabled then button.otlAccent:Show() else button.otlAccent:Hide() end
    end
end

function Toolkit:Button(parent, label, width, height, handler, style)
    local button = CreateFrame("Button", nil, parent)
    Prepare(button, "button")
    button:SetWidth(width or 100)
    button:SetHeight(height or 28)
    button:SetBackdrop(BACKDROP)
    button:SetAlpha(1)
    button.otlAccent = button:CreateTexture(nil, "ARTWORK")
    button.otlAccent:SetTexture(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3], 1)
    button.otlAccent:SetWidth(3)
    button.otlAccent:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    button.otlAccent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 2, 2)
    button.otlAccent:Hide()
    button.text = Text(button, label or "", "GameFontNormalSmall", "CENTER")
    button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.text:SetWidth(math.max(1, (width or 100) - 10))
    button.labelText = label or ""
    button.otlStyle = style or "secondary"
    button.otlHandler = handler or function() end
    button:SetScript("OnClick", function()
        if this.otlDisabled then return end
        if this.otlHandler then this.otlHandler(this) end
    end)
    button:SetScript("OnEnter", function()
        this.otlHovered = true
        ApplyButton(this)
        if this.otlDisabled and this.otlDisabledReason and GameTooltip then
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Unavailable", 1, 0.72, 0.28)
            GameTooltip:AddLine(this.otlDisabledReason, 1, 1, 1, true)
            GameTooltip:Show()
        elseif this.otlTooltip and OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.showHelp ~= false and GameTooltip then
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:AddLine(this.otlTooltipTitle or this.labelText or "Help", 1, 0.82, 0.35)
            GameTooltip:AddLine(this.otlTooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function()
        this.otlHovered = nil
        ApplyButton(this)
        if GameTooltip then GameTooltip:Hide() end
    end)
    ApplyButton(button)
    table.insert(OTLGM.uiToolkitButtons, button)
    return button
end

function Toolkit:IconButton(parent, texturePath, width, height, handler, tooltip, style)
    local button = self:Button(parent, "", width or 28, height or 28, handler, style or "utility")
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(texturePath)
    icon:SetWidth(math.max(12, (width or 28) - 10))
    icon:SetHeight(math.max(12, (height or 28) - 10))
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.icon = icon
    button.otlTooltip = tooltip
    button.otlTooltipTitle = tooltip
    return button
end

function Toolkit:Tab(parent, label, width, handler)
    return self:Button(parent, label, width or 110, 28, handler, "tab")
end

function Toolkit:FilterChip(parent, label, width, handler)
    return self:Button(parent, label, width or 90, 24, handler, "filter")
end

function Toolkit:SetSelected(button, selected)
    if not button then return end
    button.otlSelected = selected and true or nil
    ApplyButton(button)
end

function Toolkit:SetEnabled(button, enabled, reason)
    if not button then return end
    button.otlDisabled = not enabled
    button.otlDisabledReason = enabled and nil or reason
    if button.Enable and button.Disable then
        if enabled then button:Enable() else button:Disable() end
    end
    ApplyButton(button)
end

function Toolkit:ApplyEditBox(box, options)
    if not box then return nil end
    options = options or {}
    Prepare(box, "editbox")
    if options.width then box:SetWidth(options.width) end
    if options.height then box:SetHeight(options.height) end
    box:SetAutoFocus(false)
    if box.SetFontObject then box:SetFontObject(options.fontObject or "ChatFontNormal") end
    if box.SetTextColor then box:SetTextColor(COLORS.white[1], COLORS.white[2], COLORS.white[3]) end
    if box.SetHighlightColor then box:SetHighlightColor(0.78, 0.56, 0.18, 0.55) end
    if box.SetTextInsets then
        local top = options.multiline and 7 or 0
        local bottom = options.multiline and 7 or 0
        box:SetTextInsets(9, 8, top, bottom)
    end
    if options.multiline and box.SetMultiLine then box:SetMultiLine(true) end
    if options.maxLetters and box.SetMaxLetters then box:SetMaxLetters(options.maxLetters) end
    if box.SetBackdrop then box:SetBackdrop(BACKDROP) end
    ApplyColor(box, COLORS.input, COLORS.goldDark)
    self:MakeOpaque(box, COLORS.input, COLORS.goldDark)
    box.otlClipping = true
    box.otlUnifiedEdit180 = true
    box.otlCloseOnEmptyEscape = (options.closeOnEmptyEscape or options.closeMainOnEscape) and true or nil
    box.otlClearCallback180 = options.onClear
    box.otlChanged = options.changed

    if options.placeholder and options.placeholder ~= "" then
        if not box.otlPlaceholder then
            box.otlPlaceholder = Text(box, options.placeholder, "GameFontNormalSmall", "LEFT")
        else
            box.otlPlaceholder:SetText(options.placeholder)
        end
        box.otlPlaceholder:ClearAllPoints()
        if options.multiline then
            box.otlPlaceholder:SetPoint("TOPLEFT", box, "TOPLEFT", 9, -8)
            if box.otlPlaceholder.SetJustifyV then box.otlPlaceholder:SetJustifyV("TOP") end
        else
            box.otlPlaceholder:SetPoint("LEFT", box, "LEFT", 9, 0)
        end
        box.otlPlaceholder:SetWidth(math.max(1, (box:GetWidth() or options.width or 100) - 18))
        box.otlPlaceholder:SetHeight(math.max(16, (box:GetHeight() or options.height or 30) - 12))
        box.otlPlaceholder:SetTextColor(COLORS.grey[1], COLORS.grey[2], COLORS.grey[3])
    end

    local currentTextChanged = box.GetScript and box:GetScript("OnTextChanged") or nil
    local currentFocusGained = box.GetScript and box:GetScript("OnEditFocusGained") or nil
    local currentFocusLost = box.GetScript and box:GetScript("OnEditFocusLost") or nil
    local currentEscape = box.GetScript and box:GetScript("OnEscapePressed") or nil
    if currentTextChanged ~= box.otlUnifiedTextChangedHandler180 then box.otlPreviousTextChanged180 = currentTextChanged end
    if currentFocusGained ~= box.otlUnifiedFocusGainedHandler180 then box.otlPreviousFocusGained180 = currentFocusGained end
    if currentFocusLost ~= box.otlUnifiedFocusLostHandler180 then box.otlPreviousFocusLost180 = currentFocusLost end
    if currentEscape ~= box.otlUnifiedEscapeHandler180 then box.otlPreviousEscape180 = currentEscape end

    if not box.otlUnifiedTextChangedHandler180 then
        box.otlUnifiedTextChangedHandler180 = function()
            local value = this:GetText() or ""
            if this.otlPlaceholder then
                if value == "" and not this.otlFocused180 then this.otlPlaceholder:Show() else this.otlPlaceholder:Hide() end
            end
            if this.otlClearControl180 then
                if value == "" then this.otlClearControl180:Hide() else this.otlClearControl180:Show() end
            end
            local previous = this.otlPreviousTextChanged180
            if previous and previous ~= this.otlUnifiedTextChangedHandler180 then previous() end
            if not this.otlSilent and this.otlChanged then this.otlChanged(value, this) end
        end
        box.otlUnifiedFocusGainedHandler180 = function()
            this.otlFocused180 = true
            if this.otlPlaceholder then this.otlPlaceholder:Hide() end
            if this.SetBackdropBorderColor then this:SetBackdropBorderColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3], 1) end
            local previous = this.otlPreviousFocusGained180
            if previous and previous ~= this.otlUnifiedFocusGainedHandler180 then previous() end
            if this.otlFocusGainedCallback180 then this.otlFocusGainedCallback180(this) end
        end
        box.otlUnifiedFocusLostHandler180 = function()
            this.otlFocused180 = nil
            if this.otlPlaceholder and (this:GetText() or "") == "" then this.otlPlaceholder:Show() end
            if this.SetBackdropBorderColor then this:SetBackdropBorderColor(COLORS.goldDark[1], COLORS.goldDark[2], COLORS.goldDark[3], 1) end
            local previous = this.otlPreviousFocusLost180
            if previous and previous ~= this.otlUnifiedFocusLostHandler180 then previous() end
            if this.otlFocusLostCallback180 then this.otlFocusLostCallback180(this) end
        end
        box.otlUnifiedEscapeHandler180 = function()
            -- A transient surface owns Escape before the page field beneath it.
            -- This prevents a modal/drawer from remaining open while an obscured
            -- search or composer silently consumes the key.
            if OTLGM and OTLGM.CloseTopShellTransient180 and OTLGM:CloseTopShellTransient180() then return end
            if (this:GetText() or "") ~= "" then
                this:SetText("")
                if this.otlClearCallback180 then this.otlClearCallback180(this) end
                return
            end
            if this.otlFocused180 then
                this:ClearFocus()
                return
            end
            if this.otlCloseOnEmptyEscape and OTLGM and OTLGM.ui and OTLGM.ui.main then
                OTLGM.ui.main:Hide()
            else
                local previous = this.otlPreviousEscape180
                if previous and previous ~= this.otlUnifiedEscapeHandler180 then previous() end
            end
        end
    end
    box.otlUnifiedScripts180 = true
    box:SetScript("OnTextChanged", box.otlUnifiedTextChangedHandler180)
    box:SetScript("OnEditFocusGained", box.otlUnifiedFocusGainedHandler180)
    box:SetScript("OnEditFocusLost", box.otlUnifiedFocusLostHandler180)
    box:SetScript("OnEscapePressed", box.otlUnifiedEscapeHandler180)
    local value = box.GetText and (box:GetText() or "") or ""
    if box.otlPlaceholder then
        if value == "" and not box.otlFocused180 then box.otlPlaceholder:Show() else box.otlPlaceholder:Hide() end
    end
    if box.otlClearControl180 then
        if value == "" then box.otlClearControl180:Hide() else box.otlClearControl180:Show() end
    end
    return box
end

function Toolkit:EditBox(parent, width, height, options)
    local box = CreateFrame("EditBox", nil, parent)
    options = options or {}
    options.width = width or options.width or 220
    options.height = height or options.height or 30
    return self:ApplyEditBox(box, options)
end

function Toolkit:AttachClearControl180(box)
    if not box or box.otlClearControl180 then return box and box.otlClearControl180 or nil end
    local clear = self:Button(box, "×", 20, 20, function()
        if not box then return end
        box.otlSilent = true
        box:SetText("")
        box.otlSilent = nil
        if box.otlPlaceholder then box.otlPlaceholder:Show() end
        if box.otlClearCallback180 then box.otlClearCallback180(box) end
        if box.otlChanged then box.otlChanged("", box) end
        box:SetFocus()
    end, "inline")
    clear:SetPoint("RIGHT", box, "RIGHT", -4, 0)
    clear.otlTooltip = "Clear search"
    clear.otlTooltipTitle = "Clear"
    clear:Hide()
    box.otlClearControl180 = clear
    if box.SetTextInsets then
        local multiline = box.IsMultiLine and box:IsMultiLine()
        box:SetTextInsets(9, 30, multiline and 7 or 0, multiline and 7 or 0)
    end
    if box.otlPlaceholder then
        box.otlPlaceholder:SetWidth(math.max(1, (box:GetWidth() or 100) - 40))
    end
    return clear
end

function Toolkit:SearchBox(parent, width, height, placeholder, changed)
    local box = self:EditBox(parent, width or 220, height or 30, {
        placeholder = placeholder or "Search...",
        maxLetters = 80,
        changed = changed,
    })
    self:AttachClearControl180(box)
    return box
end

function Toolkit:Badge(parent, width, height)
    local badge = CreateFrame("Frame", nil, parent)
    badge:SetWidth(width or 24)
    badge:SetHeight(height or 16)
    badge:SetBackdrop(SURFACE_BORDER)
    ApplySurfaceColor(badge, COLORS.raised, COLORS.gold)
    badge.text = Text(badge, "", "GameFontNormalSmall", "CENTER")
    badge.text:SetPoint("CENTER", badge, "CENTER", 0, 0)
    badge.text:SetWidth(math.max(1, (width or 24) - 4))
    badge:Hide()
    return RegisterSurface(badge, "badge")
end

function Toolkit:SetSearchText(box, value)
    if not box then return end
    box.otlSilent = true
    box:SetText(value or "")
    box.otlSilent = nil
    if (value or "") == "" then box.otlPlaceholder:Show() else box.otlPlaceholder:Hide() end
end

function Toolkit:TableRow(parent, width, height, handler)
    local row = self:Button(parent, "", width, height or 28, handler, "inline")
    row.text:Hide()
    row.otlTableRow = true
    return row
end

function Toolkit:DetailsPanel(parent, width, height, title)
    local panel = self:Card(parent, width, height, title)
    panel.otlDetailsPanel = true
    return panel
end

function Toolkit:Drawer(parent, width, height)
    local drawer = self:Surface(parent, "drawer", width or 360, height or 560)
    drawer:SetFrameStrata("DIALOG")
    drawer:EnableMouse(true)
    drawer:Hide()
    return drawer
end

function Toolkit:Modal(parent, width, height)
    local modal = self:Surface(parent, "modal", width or 560, height or 440)
    modal:SetFrameStrata("FULLSCREEN_DIALOG")
    modal:EnableMouse(true)
    modal:Hide()
    return modal
end

function Toolkit:ContextMenu(parent, width, height)
    local menu = self:Surface(parent, "contextmenu", width or 190, height or 180)
    menu:SetFrameStrata("TOOLTIP")
    menu:EnableMouse(true)
    menu:Hide()
    return menu
end

function Toolkit:EmptyState(parent, width, height, title, body)
    local state = self:Card(parent, width or 320, height or 120)
    state.otlEmptyState = true
    state.titleText = Text(state, title or "Nothing here yet", "GameFontNormal", "CENTER")
    state.titleText:SetPoint("TOPLEFT", state, "TOPLEFT", 12, -22)
    state.titleText:SetWidth((width or 320) - 24)
    state.titleText:SetTextColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3])
    state.bodyText = Text(state, body or "", "GameFontNormalSmall", "CENTER")
    state.bodyText:SetPoint("TOPLEFT", state, "TOPLEFT", 16, -50)
    state.bodyText:SetWidth((width or 320) - 32)
    state.bodyText:SetHeight((height or 120) - 60)
    state.bodyText:SetJustifyV("TOP")
    return state
end

function Toolkit:Toast(parent, width)
    local toast = self:Surface(parent, "toast", width or 360, 42)
    ApplySurfaceColor(toast, COLORS.raised, COLORS.gold)
    toast.text = Text(toast, "", "GameFontNormalSmall", "LEFT")
    toast.text:SetPoint("LEFT", toast, "LEFT", 12, 0)
    toast.text:SetWidth((width or 360) - 24)
    toast:Hide()
    return toast
end

local function NearlyEqual180(left, right)
    return math.abs((tonumber(left) or 0) - (tonumber(right) or 0)) < 0.001
end

local function StopScrollbarDrag180(slider)
    if not slider then return end
    slider.otlDragging180 = nil
    slider:SetScript("OnUpdate", nil)
end

local function ScrollbarValueFromCursor180(slider)
    if not slider or not GetCursorPosition then return nil end
    local _, cursorY = GetCursorPosition()
    local scale = slider.GetEffectiveScale and slider:GetEffectiveScale()
        or (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
    cursorY = (tonumber(cursorY) or 0) / math.max(0.01, tonumber(scale) or 1)
    local top = slider.GetTop and slider:GetTop() or nil
    if not top then return nil end
    local minimum = tonumber(slider.otlMinimum180) or 0
    local maximum = tonumber(slider.otlMaximum180) or minimum
    local range = math.max(0, maximum - minimum)
    if range <= 0 then return minimum end
    local trackHeight = math.max(1, (slider:GetHeight() or 200) - 8)
    local thumbHeight = math.max(1, tonumber(slider.otlThumbHeight180) or 24)
    local travel = math.max(1, trackHeight - thumbHeight)
    local ratio = ((top - 4) - cursorY - (thumbHeight / 2)) / travel
    ratio = math.max(0, math.min(1, ratio))
    return minimum + (range * ratio)
end

local function RefreshScrollbarVisual180(slider)
    if not slider or slider.otlRefreshingVisual180 then return end
    slider.otlRefreshingVisual180 = true

    local minimum = tonumber(slider.otlMinimum180) or 0
    local maximum = tonumber(slider.otlMaximum180) or minimum
    local range = math.max(0, maximum - minimum)
    local visible = math.max(1, tonumber(slider.otlVisibleUnits180)
        or math.floor((slider:GetHeight() or 200) / 28))
    local total = math.max(visible, tonumber(slider.otlTotalUnits180) or (range + visible))
    local trackHeight = math.max(1, (slider:GetHeight() or 200) - 8)
    local thumbHeight = math.max(24, math.min(trackHeight, math.floor(trackHeight * (visible / total))))
    local value = tonumber(slider.otlValue180) or minimum
    value = math.max(minimum, math.min(maximum, value))
    slider.otlValue180 = value

    local thumb = slider.otlThumb180
    if thumb then
        if not NearlyEqual180(thumb:GetWidth() or 0, 10) then thumb:SetWidth(10) end
        if not NearlyEqual180(slider.otlThumbHeight180, thumbHeight) then
            thumb:SetHeight(thumbHeight)
            slider.otlThumbHeight180 = thumbHeight
        end
        local ratio = range > 0 and math.max(0, math.min(1, (value - minimum) / range)) or 0
        local travel = math.max(0, trackHeight - thumbHeight)
        local topOffset = -4 - math.floor((travel * ratio) + 0.5)
        if slider.otlThumbOffset180 ~= topOffset then
            thumb:ClearAllPoints()
            thumb:SetPoint("TOP", slider, "TOP", 0, topOffset)
            slider.otlThumbOffset180 = topOffset
        end
    end

    local shouldShow = range > 0
    if shouldShow then
        if not slider:IsShown() then slider:Show() end
    elseif slider:IsShown() then
        slider:Hide()
    end
    slider.otlRefreshingVisual180 = nil
end

function Toolkit:Scrollbar(parent, height, changed)
    -- A Slider is retained for Vanilla API compatibility, but its native thumb
    -- is made invisible. The visible thumb is an independent child frame. This
    -- avoids the live-client recursion where resizing the native thumb emitted
    -- OnValueChanged again and eventually caused Components.lua C stack overflow.
    local slider = CreateFrame("Slider", nil, parent)
    Prepare(slider, "slider")
    slider:SetWidth(16)
    slider:SetHeight(height or 200)
    slider:SetOrientation("VERTICAL")
    slider:SetValueStep(1)
    slider:SetBackdrop(BACKDROP)
    ApplyColor(slider, COLORS.input, COLORS.goldDark)
    self:MakeOpaque(slider, COLORS.input, COLORS.goldDark)
    slider:EnableMouse(true)

    slider.otlTrack180 = slider:CreateTexture(nil, "ARTWORK")
    slider.otlTrack180:SetTexture(0.10, 0.085, 0.060, 1)
    slider.otlTrack180:SetPoint("TOP", slider, "TOP", 0, -4)
    slider.otlTrack180:SetPoint("BOTTOM", slider, "BOTTOM", 0, 4)
    slider.otlTrack180:SetWidth(4)

    local nativeSetMinMaxValues = slider.SetMinMaxValues
    local nativeGetMinMaxValues = slider.GetMinMaxValues
    local nativeSetValue = slider.SetValue
    local nativeGetValue = slider.GetValue
    slider.otlNativeSetMinMaxValues180 = nativeSetMinMaxValues
    slider.otlNativeGetMinMaxValues180 = nativeGetMinMaxValues
    slider.otlNativeSetValue180 = nativeSetValue
    slider.otlNativeGetValue180 = nativeGetValue

    if slider.SetThumbTexture then
        slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
        local nativeThumb = slider.GetThumbTexture and slider:GetThumbTexture() or nil
        if nativeThumb then
            nativeThumb:SetAlpha(0)
            nativeThumb:SetWidth(1)
            nativeThumb:SetHeight(1)
            slider.otlNativeThumb180 = nativeThumb
        end
    end

    local thumb = CreateFrame("Button", nil, slider)
    Prepare(thumb, "button")
    thumb:SetWidth(10)
    thumb:SetHeight(24)
    thumb:SetBackdrop(BACKDROP)
    ApplyColor(thumb, COLORS.goldMuted, COLORS.goldMuted)
    self:MakeOpaque(thumb, COLORS.goldMuted, COLORS.goldMuted)
    thumb:SetFrameLevel((slider:GetFrameLevel() or 1) + 2)
    thumb:EnableMouse(true)
    slider.otlThumb180 = thumb
    slider.otlChanged = changed
    slider.otlMinimum180 = 0
    slider.otlMaximum180 = 0
    slider.otlValue180 = 0

    local function NotifyChanged180(self, value)
        if not self.otlSilent and self.otlChanged then
            self.otlChanged(value, self)
        end
    end

    slider.SetMinMaxValues = function(self, minimum, maximum)
        minimum = tonumber(minimum) or 0
        maximum = math.max(minimum, tonumber(maximum) or minimum)
        if self.otlMetricsInitialized180
            and NearlyEqual180(self.otlMinimum180, minimum)
            and NearlyEqual180(self.otlMaximum180, maximum) then
            return
        end
        self.otlMetricsInitialized180 = true
        self.otlMinimum180 = minimum
        self.otlMaximum180 = maximum
        self.otlValue180 = math.max(minimum, math.min(maximum, tonumber(self.otlValue180) or minimum))
        if nativeSetMinMaxValues and not self.otlApplyingNative180 then
            self.otlApplyingNative180 = true
            nativeSetMinMaxValues(self, minimum, maximum)
            self.otlApplyingNative180 = nil
        end
        RefreshScrollbarVisual180(self)
    end

    slider.GetMinMaxValues = function(self)
        return tonumber(self.otlMinimum180) or 0, tonumber(self.otlMaximum180) or 0
    end

    slider.SetValue = function(self, value)
        local minimum = tonumber(self.otlMinimum180) or 0
        local maximum = tonumber(self.otlMaximum180) or minimum
        value = math.max(minimum, math.min(maximum, tonumber(value) or minimum))
        if self.otlValueInitialized180 and NearlyEqual180(self.otlValue180, value) then
            RefreshScrollbarVisual180(self)
            return
        end
        self.otlValueInitialized180 = true
        self.otlValue180 = value
        if nativeSetValue and not self.otlApplyingNative180 then
            self.otlApplyingNative180 = true
            nativeSetValue(self, value)
            self.otlApplyingNative180 = nil
        end
        RefreshScrollbarVisual180(self)
        NotifyChanged180(self, value)
    end

    slider.GetValue = function(self)
        return tonumber(self.otlValue180) or tonumber(nativeGetValue and nativeGetValue(self)) or 0
    end

    slider.SetScrollMetrics180 = function(self, total, visible, offset)
        self.otlTotalUnits180 = math.max(0, tonumber(total) or 0)
        self.otlVisibleUnits180 = math.max(1, tonumber(visible) or 1)
        local maximum = math.max(0, self.otlTotalUnits180 - self.otlVisibleUnits180)
        self.otlSilent = true
        self:SetMinMaxValues(0, maximum)
        self:SetValue(math.max(0, math.min(maximum, tonumber(offset) or 0)))
        self.otlSilent = nil
        RefreshScrollbarVisual180(self)
    end
    slider.RefreshVisual180 = RefreshScrollbarVisual180

    slider:SetScript("OnValueChanged", function()
        if this.otlApplyingNative180 or this.otlRefreshingVisual180 then return end
        local value = tonumber(nativeGetValue and nativeGetValue(this)) or tonumber(arg1) or 0
        local minimum = tonumber(this.otlMinimum180) or 0
        local maximum = tonumber(this.otlMaximum180) or minimum
        value = math.max(minimum, math.min(maximum, value))
        if NearlyEqual180(this.otlValue180, value) then return end
        this.otlValue180 = value
        RefreshScrollbarVisual180(this)
        NotifyChanged180(this, value)
    end)

    local function StartDrag180(owner)
        local bar = owner and owner.otlScrollbarOwner180 or owner
        if not bar then return end
        bar.otlDragging180 = true
        bar:SetScript("OnUpdate", function()
            local active = this
            local ok, problem = pcall(function()
                if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
                    StopScrollbarDrag180(active)
                    return
                end
                local value = ScrollbarValueFromCursor180(active)
                if value then active:SetValue(math.floor(value + 0.5)) end
            end)
            if not ok then
                -- A custom UI skin can replace slider/cursor methods. Never
                -- leave a failed transient drag handler running every frame.
                StopScrollbarDrag180(active)
                if OTLGM and OTLGM.RecordInternalIssueRC3 then
                    pcall(OTLGM.RecordInternalIssueRC3, OTLGM, "UI/SCROLLBAR_DRAG", problem)
                end
            end
        end)
        local ok, value = pcall(ScrollbarValueFromCursor180, bar)
        if ok and value then
            local setOk, setProblem = pcall(bar.SetValue, bar, math.floor(value + 0.5))
            if not setOk then
                StopScrollbarDrag180(bar)
                if OTLGM and OTLGM.RecordInternalIssueRC3 then
                    pcall(OTLGM.RecordInternalIssueRC3, OTLGM, "UI/SCROLLBAR_DRAG_START", setProblem)
                end
            end
        elseif not ok then
            StopScrollbarDrag180(bar)
            if OTLGM and OTLGM.RecordInternalIssueRC3 then
                pcall(OTLGM.RecordInternalIssueRC3, OTLGM, "UI/SCROLLBAR_DRAG_START", value)
            end
        end
    end

    thumb.otlScrollbarOwner180 = slider
    thumb:SetScript("OnMouseDown", function() StartDrag180(this) end)
    thumb:SetScript("OnMouseUp", function()
        local bar = this.otlScrollbarOwner180
        StopScrollbarDrag180(bar)
    end)
    slider:SetScript("OnMouseDown", function() StartDrag180(this) end)
    slider:SetScript("OnMouseUp", function() StopScrollbarDrag180(this) end)
    slider:SetScript("OnHide", function() StopScrollbarDrag180(this) end)
    slider:SetScript("OnSizeChanged", function() RefreshScrollbarVisual180(this) end)

    thumb:SetScript("OnEnter", function()
        OTLGM.UI:MakeOpaque(this, COLORS.gold, COLORS.gold)
    end)
    thumb:SetScript("OnLeave", function()
        if not this.otlScrollbarOwner180 or not this.otlScrollbarOwner180.otlDragging180 then
            OTLGM.UI:MakeOpaque(this, COLORS.goldMuted, COLORS.goldMuted)
        end
    end)

    slider.otlSilent = true
    slider:SetMinMaxValues(0, 0)
    slider:SetValue(0)
    slider.otlSilent = nil
    slider.otlScrollbar = true
    slider.otlVisibleDraggable180 = true
    slider.otlReentrySafe180 = true
    RefreshScrollbarVisual180(slider)
    return slider
end

function Toolkit:Check(parent, label, width, changed)
    local check = CreateFrame("CheckButton", nil, parent)
    Prepare(check, "checkbutton")
    check:SetWidth(width or 240)
    check:SetHeight(26)
    check:SetBackdrop(BACKDROP)
    ApplyColor(check, COLORS.input, COLORS.goldDark)
    self:MakeOpaque(check, COLORS.input, COLORS.goldDark)
    check.box = check:CreateTexture(nil, "ARTWORK")
    check.box:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    check.box:SetWidth(20)
    check.box:SetHeight(20)
    check.box:SetPoint("LEFT", check, "LEFT", 3, 0)
    check.text = Text(check, label or "", "GameFontNormalSmall", "LEFT")
    check.text:SetPoint("LEFT", check, "LEFT", 28, 0)
    check.text:SetWidth((width or 240) - 34)
    check.otlChanged = changed or function() end
    check:SetScript("OnClick", function()
        if this:GetChecked() then this.box:Show() else this.box:Hide() end
        this.otlChanged(this:GetChecked() and true or false, this)
    end)
    table.insert(OTLGM.uiToolkitButtons, check)
    return check
end

function Toolkit:SetChecked(check, checked)
    if not check then return end
    check:SetChecked(checked and 1 or nil)
    if checked then check.box:Show() else check.box:Hide() end
end

function Toolkit:ClampPoint(x, y, width, height, screenWidth, screenHeight, margin)
    margin = tonumber(margin) or 8
    screenWidth = tonumber(screenWidth) or 1024
    screenHeight = tonumber(screenHeight) or 768
    width = tonumber(width) or 0
    height = tonumber(height) or 0
    x = math.max(margin, math.min(tonumber(x) or margin, screenWidth - width - margin))
    y = math.max(margin + height, math.min(tonumber(y) or (margin + height), screenHeight - margin))
    return x, y
end

function Toolkit:PlaceContextMenu(menu, x, y, fallbackLeft)
    if not menu then return end
    local scale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    local sw = UIParent and UIParent.GetWidth and UIParent:GetWidth() or 1024
    local sh = UIParent and UIParent.GetHeight and UIParent:GetHeight() or 768
    x = (tonumber(x) or 0) / math.max(0.01, scale)
    y = (tonumber(y) or 0) / math.max(0.01, scale)
    fallbackLeft = fallbackLeft and (tonumber(fallbackLeft) or 0) / math.max(0.01, scale) or nil
    local width = menu:GetWidth()
    local height = menu:GetHeight()
    local horizontal = "RIGHT"
    local vertical = "DOWN"
    local placedX = x
    local placedY = y
    if placedX + width > sw - 8 then
        placedX = fallbackLeft or (x - width)
        horizontal = "LEFT"
    end
    if placedY - height < 8 then
        placedY = y + height
        vertical = "UP"
    end
    placedX, placedY = self:ClampPoint(placedX, placedY, width, height, sw, sh, 8)
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", placedX, placedY)
    menu.otlClampedX = placedX
    menu.otlClampedY = placedY
    menu.otlHorizontalDirection = horizontal
    menu.otlVerticalDirection = vertical
end

function OTLGM:NormalizeEditBoxes180(root)
    if not root then return 0 end
    local count = 0
    local objectType = root.GetObjectType and root:GetObjectType() or ""
    if objectType == "EditBox" then
        OTLGM.UI:ApplyEditBox(root, {
            multiline = root.IsMultiLine and root:IsMultiLine() or false,
            closeOnEmptyEscape = true,
        })
        local name = root.GetName and tostring(root:GetName() or "") or ""
        local placeholder = root.otlPlaceholder and root.otlPlaceholder.GetText and tostring(root.otlPlaceholder:GetText() or "") or ""
        if string.find(string.lower(name), "search", 1, true)
            or string.find(string.lower(placeholder), "search", 1, true) then
            OTLGM.UI:AttachClearControl180(root)
        end
        count = count + 1
    end
    if root.GetChildren then
        local children = { root:GetChildren() }
        local index
        for index = 1, table.getn(children) do
            count = count + self:NormalizeEditBoxes180(children[index])
        end
    end
    return count
end


function Toolkit:ResetReusableRow180(row)
    if not row then return end
    row.otlHovered = nil
    row.otlSelected = nil
    row.otlDisabled = nil
    row.otlDisabledReason = nil
    row.otlTooltip = nil
    row.otlTooltipTitle = nil
    row.resultData = nil
    row.otlEntry = nil
    row.otlResult = nil
    row.otlRequestId = nil
    if row.SetAlpha then row:SetAlpha(1) end
    if row.SetBackdropColor then row:SetBackdropColor(0.030, 0.026, 0.020, 1) end
    if row.SetBackdropBorderColor then row:SetBackdropBorderColor(COLORS.goldDark[1], COLORS.goldDark[2], COLORS.goldDark[3], 1) end
    if row.icon and row.icon.SetVertexColor then row.icon:SetVertexColor(1, 1, 1, 1) end
    if row.typeIcon180 and row.typeIcon180.SetVertexColor then
        row.typeIcon180:SetVertexColor(1, 1, 1, 1)
        row.typeIcon180:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    ApplyButton(row)
end

OTLGM:RegisterModule("UIComponents180", {
    stage = "B",
    revision = 9,
    opaque = true,
    solidTexture = true,
    noPersistentOnUpdate = true,
    transientDragOnUpdate = true,
})


-- C5-R5 canonical responsive toolbar helper.  The caller owns visibility; this
-- routine owns every anchor in the group and therefore cannot leave stale
-- coordinates from an older layout pass.
function OTLGM:LayoutRightButtonGroup180(parent, buttons, parentWidth, y, gap)
    if not parent or type(buttons) ~= "table" then return false end
    local right = tonumber(parentWidth) or (parent.GetWidth and parent:GetWidth()) or 0
    local top = tonumber(y) or 0
    gap = tonumber(gap) or 6
    local index, button
    for index = table.getn(buttons), 1, -1 do
        button = buttons[index]
        if button and (not button.IsVisible or button:IsVisible()) then
            local width = math.max(54, tonumber(button.GetWidth and button:GetWidth()) or 70)
            local height = math.max(22, tonumber(button.GetHeight and button:GetHeight()) or 28)
            right = right - width
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", parent, "TOPLEFT", right, top)
            button:SetWidth(width) button:SetHeight(height)
            right = right - gap
        elseif button then
            button:ClearAllPoints()
        end
    end
    return true, right
end
