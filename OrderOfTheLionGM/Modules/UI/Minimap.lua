-- Order of the Lion Guild Manager
-- Compact minimap launcher

function OTLGM:GetImportantMinimapAlerts155()
    -- The minimap badge is a signal, not an accumulated history counter.
    -- One raid signal plus current group/application actions is enough.
    local raidUnread=self.GetPveUnread and self:GetPveUnread("RAIDS") or 0
    local activeRaid=self.GetPveActiveRaid and self:GetPveActiveRaid() or nil
    local raids=(tonumber(raidUnread) or 0)>0 and activeRaid and 1 or 0
    local groupUnread=self.GetPveUnread and self:GetPveUnread("GROUPS") or 0
    local pending=self.GetPendingPveApplicationCount and self:GetPendingPveApplicationCount() or 0
    local groups=math.min(9,(tonumber(pending) or 0)+(((tonumber(groupUnread) or 0)>0) and 1 or 0))
    return raids+groups,raids,groups
end

function OTLGM:BuildMinimapButton()
    if self.ui.minimapButton then return end
    self:EnsureDB()

    local button = CreateFrame("Button", "OTLGM_MinimapButton", Minimap)
    OTLGM:PrepareInteractiveControl170(button, "button")
    button:SetWidth(34)
    button:SetHeight(34)
    button:SetFrameStrata("HIGH")
    button:SetFrameLevel(10)
    button:SetMovable(true)
    button:SetClampedToScreen(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    button:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    button:SetBackdropColor(0.025, 0.018, 0.010, 1)
    button:SetBackdropBorderColor(0.90, 0.58, 0.16, 1)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\OrderOfTheLionGM\\Assets\\LionCrest")
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 5, -5)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, 5)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon = icon

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture(1, 0.82, 0.30, 0.22)
    highlight:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3)
    highlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
    highlight:SetBlendMode("ADD")

    local badge = CreateFrame("Frame", nil, button)
    badge:SetWidth(17)
    badge:SetHeight(17)
    badge:SetPoint("TOPRIGHT", button, "TOPRIGHT", 4, 4)
    badge:SetFrameLevel(button:GetFrameLevel() + 3)
    badge:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 7,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    badge:SetBackdropColor(0.62, 0.035, 0.025, 1)
    badge:SetBackdropBorderColor(0.95, 0.62, 0.18, 1)
    badge.text = badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    badge.text:SetPoint("CENTER", badge, "CENTER", 0, 0)
    badge:Hide()
    button.badge = badge

    button:SetScript("OnClick", function()
        if arg1 == "RightButton" then
            OTLGM:RequestScan("MANUAL")
        else
            if OTLGM.ToggleUI then OTLGM:ToggleUI()
            elseif DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffff3333[Lion GM]|r The UI module did not load. Type /otltest.") end
        end
    end)

    button:SetScript("OnDragStart", function()
        if IsShiftKeyDown() then
            this:StartMoving()
            this.isMoving = true
        end
    end)

    button:SetScript("OnDragStop", function()
        if this.isMoving then
            this:StopMovingOrSizing()
            this.isMoving = nil
            local buttonX, buttonY = this:GetCenter()
            local mapX, mapY = Minimap:GetCenter()
            if buttonX and mapX then
                OTLGM_DB.settings.minimapX = buttonX - mapX
                OTLGM_DB.settings.minimapY = buttonY - mapY
                OTLGM:PositionMinimapButton()
            end
        end
    end)

    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:AddLine("Order of the Lion Guild Manager", 1, 0.82, 0.35)
        GameTooltip:AddLine("Left-click: open manager", 1, 1, 1)
        GameTooltip:AddLine("Right-click: scan roster", 1, 1, 1)
        GameTooltip:AddLine("Shift-drag: move button", 0.65, 0.65, 0.65)
        local db = OTLGM:GetGuildDB()
        if db then
            local total,raids,groups=OTLGM:GetImportantMinimapAlerts155()
            GameTooltip:AddLine(" ")
            if total>0 then
                GameTooltip:AddLine("Important PvE alerts",1,0.82,0.25)
                GameTooltip:AddDoubleLine("Raid alerts",tostring(raids),0.8,0.8,0.8,1,0.35,0.25)
                GameTooltip:AddDoubleLine("Groups / applications",tostring(groups),0.8,0.8,0.8,0.35,0.75,1)
            else
                GameTooltip:AddLine("No important raid or group alerts",0.55,0.75,0.55)
            end
            GameTooltip:AddDoubleLine("Guild online", tostring(db.lastOnline or 0), 0.8, 0.8, 0.8, 0.4, 1, 0.4)
            GameTooltip:AddLine(OTLGM:IsOfficerMode() and "Officer Mode" or "Member Mode", 0.65, 0.65, 0.65)
        end
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.ui.minimapButton = button
    self:PositionMinimapButton()
    self:ApplyMinimapVisibility()
    self:UpdateMinimapBadge()
end

function OTLGM:PositionMinimapButton()
    if not self.ui.minimapButton then return end
    self:EnsureDB()
    local offsetX = tonumber(OTLGM_DB.settings.minimapX)
    local offsetY = tonumber(OTLGM_DB.settings.minimapY)
    if not offsetX or not offsetY or math.abs(offsetX) > 120 or math.abs(offsetY) > 120 then
        offsetX = -78
        offsetY = -78
        OTLGM_DB.settings.minimapX = offsetX
        OTLGM_DB.settings.minimapY = offsetY
    end
    self.ui.minimapButton:ClearAllPoints()
    self.ui.minimapButton:SetPoint("CENTER", Minimap, "CENTER", offsetX, offsetY)
end

function OTLGM:ApplyMinimapVisibility()
    if not self.ui.minimapButton then return end
    self:EnsureDB()
    if OTLGM_DB.settings.showMinimap then self.ui.minimapButton:Show() else self.ui.minimapButton:Hide() end
end

function OTLGM:UpdateMinimapBadge()
    if not self.ui.minimapButton or not self.ui.minimapButton.badge then return end
    local count,raids,groups=self:GetImportantMinimapAlerts155()
    if count and count>0 then
        self.ui.minimapButton.badge.text:SetText(count>9 and "9+" or tostring(count))
        if raids>0 then
            self.ui.minimapButton.badge:SetBackdropColor(0.62,0.035,0.025,1)
        else
            self.ui.minimapButton.badge:SetBackdropColor(0.05,0.24,0.52,1)
        end
        self.ui.minimapButton.badge:Show()
    else
        self.ui.minimapButton.badge:Hide()
    end
end

OTLGM:RegisterModule("Minimap", { layer = "ui", asset = "Assets\\LionCrest" })
