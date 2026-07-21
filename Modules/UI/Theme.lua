-- Single visual language shared by all UI generations retained from 1.5.x.

local BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

local function Color(value, fallback)
    value = value or fallback
    return value[1], value[2], value[3], value[4] or 1
end

-- Interface 11200 does not consistently make script-created controls mouse
-- interactive. Every actionable control is explicitly prepared here instead
-- of relying on template/default behaviour that differs between Vanilla
-- clients and UI replacements.
function OTLGM:PrepareInteractiveControl170(control, kind)
    if not control then return nil end
    local objectType = kind
    if not objectType and control.GetObjectType then objectType = control:GetObjectType() end
    objectType = string.lower(tostring(objectType or ""))
    if objectType == "button" or objectType == "checkbutton" then
        if control.EnableMouse then control:EnableMouse(true) end
        -- Register only during first preparation. Some rows intentionally add
        -- RightButtonUp afterwards; page reconciliation must preserve it.
        if not control.otlInteractivePrepared170 and control.RegisterForClicks then control:RegisterForClicks("LeftButtonUp") end
        control.otlInteractivePrepared170 = true
    elseif objectType == "editbox" then
        if control.EnableMouse then control:EnableMouse(true) end
        if control.EnableKeyboard then control:EnableKeyboard(true) end
        control.otlInteractivePrepared170 = true
    elseif objectType == "slider" then
        if control.EnableMouse then control:EnableMouse(true) end
        control.otlInteractivePrepared170 = true
    end
    return control
end

-- Keep all generations of the UI state model in lockstep. Earlier releases
-- alternated between `disabled` and `enabled156`; a stale value could leave a
-- control visually active but natively disabled.
function OTLGM:SetControlEnabled170(control, enabled, reason)
    if not control then return false end
    enabled = enabled and true or false
    control.disabled = not enabled
    control.enabled156 = enabled
    control.disabledReason = enabled and nil or reason
    control.disabledReason156 = enabled and nil or reason
    self:PrepareInteractiveControl170(control, "button")
    if enabled then
        if control.Enable then control:Enable() end
    else
        if control.Disable then control:Disable() end
    end
    return enabled
end

-- Reconcile an entire page after it is refreshed. This is intentionally
-- event-driven (page open/refresh only), not an OnUpdate scan. It repairs
-- controls created by every retained UI generation and prevents a stale native
-- Disable state or missing mouse registration from surviving a redraw.
function OTLGM:RepairInteractiveTree170(root)
    local result = { buttons = 0, editBoxes = 0, repaired = 0, missingHandlers = 0 }
    local function Visit(frame)
        if not frame then return end
        local objectType = frame.GetObjectType and frame:GetObjectType() or ""
        if objectType == "Button" or objectType == "CheckButton" then
            local click = frame.GetScript and frame:GetScript("OnClick")
            if click then
                result.buttons = result.buttons + 1
                local wasPrepared = frame.otlInteractivePrepared170 and true or false
                OTLGM:PrepareInteractiveControl170(frame, "button")
                local disabled = (frame.disabled == true) or (frame.enabled156 == false)
                if disabled then
                    if frame.Disable then frame:Disable() end
                else
                    if frame.Enable then frame:Enable() end
                end
                if not wasPrepared then result.repaired = result.repaired + 1 end
            else
                result.missingHandlers = result.missingHandlers + 1
            end
        elseif objectType == "EditBox" then
            result.editBoxes = result.editBoxes + 1
            local wasPrepared = frame.otlInteractivePrepared170 and true or false
            OTLGM:PrepareInteractiveControl170(frame, "editbox")
            if frame.readOnly then
                if frame.EnableMouse then frame:EnableMouse(false) end
                if frame.EnableKeyboard then frame:EnableKeyboard(false) end
            end
            if not wasPrepared then result.repaired = result.repaired + 1 end
        end
        if frame.GetChildren then
            local children = { frame:GetChildren() }
            local index
            for index = 1, table.getn(children) do Visit(children[index]) end
        end
    end
    Visit(root)
    self.runtime = self.runtime or {}
    self.runtime.interactionAudit170 = result
    return result
end

function OTLGM:ApplyPanelSkin(frame, kind)
    if not frame or not frame.SetBackdrop then return end
    if frame.otlApplyingPanelSkin160 then return end
    frame.otlApplyingPanelSkin160 = true
    if not frame.otlThemeBackdrop160 then
        -- Mark before SetBackdrop: tooltip/UI addons can synchronously run
        -- scripts from this C call on Vanilla clients.
        frame.otlThemeBackdrop160 = true
        frame:SetBackdrop(BACKDROP)
    end
    local theme = self.theme
    local surface = kind == "raised" and theme.surfaceRaised or (kind == "background" and theme.background or theme.surface)
    frame:SetBackdropColor(Color(surface, theme.surface))
    frame:SetBackdropBorderColor(Color(kind == "accent" and theme.border or theme.borderSoft, theme.borderSoft))
    frame.otlApplyingPanelSkin160 = nil
end

function OTLGM:ApplyEditSkin(edit)
    if not edit then return end
    self:ApplyPanelSkin(edit, "background")
    if edit.SetTextColor then edit:SetTextColor(Color(self.theme.text, self.theme.text)) end
end

function OTLGM:ApplyButtonSkin(button)
    if not button or not button.SetBackdropColor then return false end
    -- Styling may run from OnEnter/OnLeave and Enable/Disable handlers owned by
    -- other addons. Re-entering the same button used to overflow the C stack
    -- with TurtleRP's tooltip scripts. This guard also makes the function a
    -- cheap no-op for nested callbacks.
    if button.otlApplyingButtonSkin160 then return true end
    button.otlApplyingButtonSkin160 = true
    if button.SetBackdrop and not button.otlThemeBackdrop160 then
        button.otlThemeBackdrop160 = true
        button:SetBackdrop(BACKDROP)
    end
    -- Either legacy flag may disable the control. Never let one generation
    -- silently override a stale value from another generation.
    local disabled = (button.disabled == true) or (button.enabled156 == false)
    local selected = button.selected or button.selected156
    local hovered = button.hovered or button.hover156
    local style = button.actionStyle or button.kind156 or "normal"
    local theme = self.theme
    local background, border, text = theme.surfaceRaised, theme.borderSoft, theme.text

    if disabled then
        background, border, text = theme.background, theme.borderSoft, theme.disabled
    elseif selected then
        background, border, text = { 0.12, 0.085, 0.030, 1 }, theme.gold, theme.goldBright
    elseif style == "danger" or style == "raid" then
        background, border, text = { 0.12, 0.030, 0.024, 1 }, theme.red, { 1.0, 0.66, 0.56, 1 }
    elseif style == "confirm" then
        background, border, text = { 0.025, 0.105, 0.050, 1 }, theme.green, { 0.68, 0.96, 0.72, 1 }
    elseif style == "utility" then
        background, border, text = { 0.025, 0.065, 0.105, 1 }, theme.blue, { 0.68, 0.84, 1.0, 1 }
    elseif style == "primary" then
        background, border, text = { 0.075, 0.060, 0.030, 1 }, theme.border, theme.goldBright
    end

    if hovered and not disabled then
        background = {
            math.min(1, background[1] + 0.035),
            math.min(1, background[2] + 0.035),
            math.min(1, background[3] + 0.028),
            background[4] or 1,
        }
        if style == "normal" then border = theme.gold end
    end

    button:SetBackdropColor(Color(background, theme.surfaceRaised))
    button:SetBackdropBorderColor(Color(border, theme.borderSoft))
    local label = button.text or button.label156
    if label and label.SetTextColor then label:SetTextColor(Color(text, theme.text)) end
    -- Change native state only when needed. Calling Enable on every hover was
    -- observable by other UI hooks and could recursively request another skin.
    if not disabled then self:PrepareInteractiveControl170(button, "button") end
    if button.IsEnabled then
        local enabledNow = button:IsEnabled() and true or false
        if disabled and enabledNow then button:Disable()
        elseif not disabled and not enabledNow then button:Enable() end
    end
    button.otlApplyingButtonSkin160 = nil
    return true
end

-- TurtleRP 1.1.1 restores every GameTooltip font from OnTooltipCleared. On
-- OctoWoW, SetFont can synchronously clear the tooltip again, so the handler
-- re-enters itself until the client reports a C stack overflow. Keep the
-- existing TurtleRP handler and any handler it chained, but reject only nested
-- invocations of that same chain.
function OTLGM:InstallTooltipCompatibility160()
    if type(TurtleRP) ~= "table" or not GameTooltip or TurtleRP.gameTooltip ~= GameTooltip then return false end
    if not GameTooltip.GetScript or not GameTooltip.SetScript then return false end

    self.runtime = self.runtime or {}
    -- Store the guard on the tooltip as well as in runtime. Backup restore and
    -- other session resets replace OTLGM.runtime, but must not stack another
    -- wrapper around the already protected tooltip handler.
    local state = GameTooltip.otlTooltipCompatibility160 or {}
    GameTooltip.otlTooltipCompatibility160 = state
    self.runtime.tooltipCompatibility160 = state
    local current = GameTooltip:GetScript("OnTooltipCleared")
    if current == state.wrapper then return true end
    if type(current) ~= "function" then return false end

    local original = current
    state.original = original
    state.busy = nil
    state.wrapper = function()
        if state.busy then
            state.reentriesBlocked = (state.reentriesBlocked or 0) + 1
            return
        end
        state.busy = true
        local ok, problem = pcall(original)
        state.busy = nil
        if not ok then error(problem) end
    end
    GameTooltip:SetScript("OnTooltipCleared", state.wrapper)
    state.installedAt = self:Now()
    return true
end

-- Preserve the user's preferred scale while still fitting the fixed-layout
-- Vanilla UI on smaller resolutions. The preference remains unchanged, so a
-- larger monitor automatically returns to the requested size next session.
function OTLGM:GetEffectiveUIScale(requested)
    requested = math.max(0.75, math.min(1.20, tonumber(requested) or 1))
    if not UIParent or not UIParent.GetWidth or not UIParent.GetHeight then return requested end
    local width = tonumber(UIParent:GetWidth()) or 0
    local height = tonumber(UIParent:GetHeight()) or 0
    if width <= 0 or height <= 0 then return requested end
    local fitWidth = (width - 24) / 1000
    local fitHeight = (height - 24) / 710
    return math.max(0.62, math.min(requested, fitWidth, fitHeight))
end

function OTLGM:ApplyUIScale(requested)
    if not self.ui or not self.ui.main then return tonumber(requested) or 1 end
    local effective = self:GetEffectiveUIScale(requested)
    self.ui.main:SetScale(effective)
    self.runtime = self.runtime or {}
    self.runtime.effectiveUIScale = effective
    return effective
end

function OTLGM:ApplyWindowTheme()
    if not self.ui or not self.ui.main then return end
    if self.ui.sidebar then self:ApplyPanelSkin(self.ui.sidebar, "background") end
    if self.ui.content then self:ApplyPanelSkin(self.ui.content, "background") end
    if self.ui.versionText then
        self.ui.versionText:SetText("Order of the Lion GM v" .. tostring(self.version))
        self.ui.versionText:SetTextColor(Color(self.theme.textMuted, self.theme.textMuted))
    end
    local _, button
    for _, button in pairs(self.ui.navButtons or {}) do self:ApplyButtonSkin(button) end
end

OTLGM:RegisterModule("Theme", {
    name = "Lion Obsidian",
    componentStates = { "normal", "selected", "hover", "disabled", "confirm", "utility", "danger" },
})
