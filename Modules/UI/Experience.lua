-- Premium 1.7 presentation layer. It builds on the canonical 1.6 systems and
-- owns the additive Inbox, Treasury, social chat, favorites and short
-- opt-out motion. No frame installs its own OnUpdate handler.

local X_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 10,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local function XPanel(parent, x, y, width, height, kind)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:SetWidth(width)
    frame:SetHeight(height)
    OTLGM:ApplyPanelSkin(frame, kind or "background")
    return frame
end

local function XText(parent, template, value, x, y, width, justify)
    local text = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    text:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then text:SetWidth(width) end
    text:SetJustifyH(justify or "LEFT")
    text:SetText(value or "")
    return text
end

local function XWrapped(parent, template, value, x, y, width, height)
    local text = XText(parent, template, value, x, y, width, "LEFT")
    text:SetJustifyV("TOP")
    if height then text:SetHeight(height) end
    return text
end

local function XButton(parent, label, x, y, width, height, handler, style)
    local button = CreateFrame("Button", nil, parent)
    OTLGM:PrepareInteractiveControl170(button, "button")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetBackdrop(X_BACKDROP)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.text:SetText(label or "")
    button.actionStyle = style or "normal"
    button.handler170 = handler
    button:SetScript("OnEnter", function() this.hovered = true OTLGM:ApplyButtonSkin(this) end)
    button:SetScript("OnLeave", function() this.hovered = false OTLGM:ApplyButtonSkin(this) if GameTooltip then GameTooltip:Hide() end end)
    button:SetScript("OnClick", function() if not this.disabled and this.handler170 then this.handler170(this) end end)
    OTLGM:ApplyButtonSkin(button)
    return button
end

local function XEnable(button, enabled, reason)
    if not button then return end
    OTLGM:SetControlEnabled170(button, enabled, reason)
    OTLGM:ApplyButtonSkin(button)
end

local function XSelect(button, selected)
    if not button then return end
    button.selected = selected and true or false
    OTLGM:ApplyButtonSkin(button)
end

local function XEdit(parent, name, x, y, width, height, maximum)
    local edit = CreateFrame("EditBox", name, parent, "InputBoxTemplate")
    OTLGM:PrepareInteractiveControl170(edit, "editbox")
    edit:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    edit:SetWidth(width)
    edit:SetHeight(height)
    edit:SetAutoFocus(false)
    if maximum then edit:SetMaxLetters(maximum) end
    -- EditBox:HasFocus is not part of the Interface 11200 API. Track focus
    -- through the stable Vanilla scripts and use HasFocus only when a custom
    -- client happens to provide it.
    edit:SetScript("OnEditFocusGained", function() this.focused170 = true end)
    edit:SetScript("OnEditFocusLost", function() this.focused170 = nil end)
    OTLGM:ApplyEditSkin(edit)
    return edit
end

function OTLGM:IsEditBoxFocused170(edit)
    if not edit then return false end
    if edit.focused170 then return true end
    if type(edit.HasFocus) == "function" then
        local ok, focused = pcall(edit.HasFocus, edit)
        if ok then return focused and true or false end
    end
    return false
end

local function XShort(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or 40
    if string.len(value) <= maximum then return value end
    return OTLGM:Utf8Truncate(value, maximum - 3) .. "..."
end

local function XMoney(copper, preferGold)
    copper = math.max(0, math.floor(tonumber(copper) or 0))
    local gold = math.floor(copper / 10000)
    local silver = math.floor(math.mod(copper, 10000) / 100)
    local coin = math.mod(copper, 100)
    if gold > 0 or preferGold then
        local text = tostring(gold) .. "g"
        if silver > 0 then text = text .. " " .. tostring(silver) .. "s" end
        if coin > 0 and gold == 0 then text = text .. " " .. tostring(coin) .. "c" end
        return text
    end
    if silver > 0 then return tostring(silver) .. "s" .. (coin > 0 and (" " .. tostring(coin) .. "c") or "") end
    return tostring(coin) .. "c"
end

local function XSetIconState(button, selected, enabled)
    if not button or not button.icon170 then return end
    -- SetDesaturated is absent on some 1.12 texture objects. Alpha and tint
    -- communicate the state without relying on a later-client API.
    button.icon170:SetAlpha(enabled == false and 0.30 or 0.92)
    if selected then button.icon170:SetVertexColor(1.0, 0.76, 0.20)
    elseif enabled == false then button.icon170:SetVertexColor(0.34, 0.32, 0.28)
    else button.icon170:SetVertexColor(0.62, 0.58, 0.48) end
end

local function XGoldToCopper(value)
    value = tonumber(value) or 0
    return math.max(0, math.floor(value * 10000))
end

-- -------------------------------------------------------------------------
-- Short, centralized and optional motion
-- -------------------------------------------------------------------------

function OTLGM:StartExperienceMotion170(frame, fromAlpha, toAlpha, duration)
    if not frame then return false end
    local mode = OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.motionMode170 or "FULL"
    if mode == "OFF" or self:InCombat() then frame:SetAlpha(toAlpha or 1) return false end
    if mode == "REDUCED" then duration = math.min(tonumber(duration) or 0.12, 0.08) end
    self.runtime = self.runtime or {}
    self.runtime.motion170 = self.runtime.motion170 or {}
    local index
    for index = table.getn(self.runtime.motion170), 1, -1 do
        if self.runtime.motion170[index].frame == frame then table.remove(self.runtime.motion170, index) end
    end
    frame:SetAlpha(fromAlpha or 0)
    table.insert(self.runtime.motion170, { frame = frame, from = fromAlpha or 0, target = toAlpha or 1, duration = math.max(0.04, tonumber(duration) or 0.14), elapsed = 0 })
    return true
end

function OTLGM:ProcessExperienceMotion170(elapsed)
    local motions = self.runtime and self.runtime.motion170
    if not motions or table.getn(motions) == 0 then return end
    local index = 1
    while index <= table.getn(motions) do
        local motion = motions[index]
        if not motion.frame or not motion.frame:IsVisible() or self:InCombat() then
            if motion.frame then motion.frame:SetAlpha(motion.target) end
            table.remove(motions, index)
        else
            motion.elapsed = motion.elapsed + math.max(0, tonumber(elapsed) or 0)
            local progress = math.min(1, motion.elapsed / motion.duration)
            motion.frame:SetAlpha(motion.from + ((motion.target - motion.from) * progress))
            if progress >= 1 then table.remove(motions, index) else index = index + 1 end
        end
    end
end

function OTLGM:PrepareMainShow170()
    if self.ui and self.ui.main then self:StartExperienceMotion170(self.ui.main, 0.70, 1, 0.14) end
end

-- -------------------------------------------------------------------------
-- Crafting favorites
-- -------------------------------------------------------------------------

function OTLGM:GetCraftingFavoriteKey170(result)
    if not result or not result.recipe then return nil end
    local identity = (tonumber(result.recipe.itemId) or 0) > 0 and tostring(result.recipe.itemId) or self:NormalizeText(result.recipe.name or "")
    if identity == "" then return nil end
    return tostring(result.professionKey or "ALL") .. ":" .. identity
end

function OTLGM:IsCraftingFavorite170(result)
    local craft = self:EnsureCraftingDB()
    local key = self:GetCraftingFavoriteKey170(result)
    return key and craft and craft.favorites170 and craft.favorites170[key] ~= nil or false
end

function OTLGM:ToggleCraftingFavorite170(result)
    local craft = self:EnsureCraftingDB()
    local key = self:GetCraftingFavoriteKey170(result)
    if not craft or not key then return false end
    craft.favorites170 = craft.favorites170 or {}
    if craft.favorites170[key] then craft.favorites170[key] = nil
    else
        if self:Count(craft.favorites170) >= 400 then
            local oldestKey, oldestAt
            local storedKey, stored
            for storedKey, stored in pairs(craft.favorites170) do
                local storedAt = type(stored) == "table" and tonumber(stored.ts) or tonumber(stored) or 0
                if not oldestAt or storedAt < oldestAt then oldestKey, oldestAt = storedKey, storedAt end
            end
            if oldestKey then craft.favorites170[oldestKey] = nil end
        end
        craft.favorites170[key] = { ts = self:Now(), name = self:SafeText(result.recipe.name, 80, false, false), professionKey = result.professionKey }
    end
    if self.RefreshProfessionsPage then self:RefreshProfessionsPage() end
    return true
end

function OTLGM:GetCraftingFavoriteCount170()
    local craft = self:EnsureCraftingDB()
    return self:Count(craft and craft.favorites170 or {})
end

function OTLGM:BuildProfessionExperience170()
    if self.ui.craftingFavoriteButton170 or not self.ui.craftingRecipeMeta then return end
    local parent = self.ui.craftingRecipeMeta:GetParent()
    if self.ui.craftingRecipeTitle then self.ui.craftingRecipeTitle:SetWidth(124) end
    self.ui.craftingRecipeMeta:SetWidth(158)
    self.ui.craftingRecipeMeta:SetHeight(28)
    self.ui.craftingRecipeMeta:SetJustifyV("TOP")
    self.ui.craftingFavoriteButton170 = XButton(parent, "+", 180, -10, 30, 26, function()
        if OTLGM.ui.craftingSelectedRecipeData then OTLGM:ToggleCraftingFavorite170(OTLGM.ui.craftingSelectedRecipeData) end
    end, "primary")
    self.ui.craftingFavoriteButton170.favoriteSymbol170 = self.ui.craftingFavoriteButton170.text
    local recipes = self.ui.craftingSearchEdit and self.ui.craftingSearchEdit:GetParent()
    if recipes then
        self.ui.craftingFavoritesOnly170 = XButton(recipes, "+", 284, -78, 30, 26, function()
            OTLGM_DB.settings.craftingFavoritesOnly170 = not OTLGM_DB.settings.craftingFavoritesOnly170
            OTLGM.ui.craftingRecipeOffset = 0
            OTLGM:RefreshProfessionsPage()
        end, "primary")
        self.ui.craftingFavoritesOnly170:SetScript("OnEnter", function()
            this.hovered = true OTLGM:ApplyButtonSkin(this)
            GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
            GameTooltip:AddLine("Favorite recipes", 1.0, 0.82, 0.35)
            GameTooltip:AddLine("Click to show only favorites. The + button on the recipe card saves the selected recipe.", 0.62, 0.62, 0.60, true)
            GameTooltip:Show()
        end)
        self.ui.craftingFavoritesOnly170:SetScript("OnLeave", function() this.hovered = false OTLGM:ApplyButtonSkin(this) GameTooltip:Hide() end)
    end
end

function OTLGM:RefreshProfessionExperience170()
    if not self.ui.craftingFavoriteButton170 then return end
    local selected = self.ui.craftingSelectedRecipeData
    local favorite = selected and self:IsCraftingFavorite170(selected)
    XEnable(self.ui.craftingFavoriteButton170, selected ~= nil, "Select a recipe first.")
    XSelect(self.ui.craftingFavoriteButton170, favorite)
    self.ui.craftingFavoriteButton170.text:SetText(favorite and "-" or "+")
    if self.ui.craftingFavoritesOnly170 then
        self.ui.craftingFavoritesOnly170.favoriteCount170 = self:GetCraftingFavoriteCount170()
        local enabled = OTLGM_DB.settings.craftingFavoritesOnly170 and true or false
        XSelect(self.ui.craftingFavoritesOnly170, enabled)
        self.ui.craftingFavoritesOnly170.text:SetText(enabled and "-" or "+")
    end
end

function OTLGM:BuildTreasuryPage170(page)
    if not page or self.ui.treasury170 then return end
    local ui = { page = page, offset = 0 }
    self.ui.treasury170 = ui
    XText(page, "GameFontNormalLarge", "Guild Treasury", 0, -2, 360, "LEFT")
    XWrapped(page, "GameFontNormalSmall", "Shared funding goals now; conservative read-only guild-bank support when the server exposes a compatible API.", 0, -28, 700, 32)

    ui.banner = XPanel(page, 0, -64, 718, 86, "raised")
    ui.bannerIcon = ui.banner:CreateTexture(nil, "OVERLAY")
    ui.bannerIcon:SetPoint("LEFT", ui.banner, "LEFT", 12, 0)
    ui.bannerIcon:SetWidth(32) ui.bannerIcon:SetHeight(32)
    ui.bannerIcon:SetTexture("Interface\\Icons\\INV_Letter_15")
    ui.contributionTitle = XText(ui.banner, "GameFontNormal", "HOW TO CONTRIBUTE", 54, -8, 330, "LEFT")
    ui.contributionTitle:SetTextColor(1.0, 0.82, 0.35)
    ui.contributionDetail = XWrapped(ui.banner, "GameFontNormalSmall", "Mail gold or items to Morrow and state which guild goal they are for. Leadership records the contribution and advances the shared total.", 54, -27, 430, 42)
    ui.contributionDetail:SetTextColor(0.78, 0.78, 0.74)
    ui.bannerStatus = XText(ui.banner, "GameFontNormalSmall", "Manual goals - no money or items are moved by the addon.", 54, -68, 500, "LEFT")
    ui.bannerStatus:SetTextColor(0.52, 0.52, 0.50)
    ui.copyMorrow = XButton(ui.banner, "Copy Morrow", 598, -10, 108, 28, function()
        OTLGM:ShowCopyDialog("Treasury recipient", "Morrow")
    end, "primary")
    ui.sync = XButton(ui.banner, "Sync Goals", 598, -46, 108, 28, function()
        if OTLGM:RequestTreasurySync170(true) then OTLGM:SetStatus("Requesting treasury goals from online leadership...") end
    end, "utility")

    local list = XPanel(page, 0, -160, 448, 358, "background")
    XText(list, "GameFontNormal", "FUNDING GOALS", 12, -12, 220, "LEFT")
    ui.newGoal = XButton(list, "+ New Goal", 324, -8, 112, 26, function()
        ui.selected = nil
        ui.nameEdit:SetText("") ui.currentEdit:SetText("0") ui.targetEdit:SetText("0")
        ui.editorTitle:SetText("NEW FUNDING GOAL")
    end, "confirm")
    ui.rows = {}
    local index
    for index = 1, 5 do
        local row = XButton(list, "", 10, -42 - ((index - 1) * 62), 428, 56, function(button)
            if button.goal170 then
                ui.selected = button.goal170.id
                OTLGM:RefreshTreasuryPage170(true)
            end
        end, "normal")
        row.text:Hide()
        row.name = XText(row, "GameFontNormal", "", 12, -8, 244, "LEFT")
        row.amount = XText(row, "GameFontNormalSmall", "", 264, -9, 150, "RIGHT")
        row.meta = XText(row, "GameFontNormalSmall", "", 12, -30, 402, "LEFT")
        row.meta:SetTextColor(0.58, 0.58, 0.56)
        row.progressBack = row:CreateTexture(nil, "BACKGROUND")
        row.progressBack:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 10, 5)
        row.progressBack:SetWidth(408) row.progressBack:SetHeight(3)
        row.progressBack:SetTexture(0.10, 0.09, 0.07, 1)
        row.progress = row:CreateTexture(nil, "ARTWORK")
        row.progress:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 10, 5)
        row.progress:SetWidth(1) row.progress:SetHeight(3)
        row.progress:SetTexture(0.94, 0.63, 0.16, 1)
        ui.rows[index] = row
    end
    ui.prev = XButton(list, "<", 328, -324, 48, 24, function() ui.offset = math.max(0, ui.offset - 5) OTLGM:RefreshTreasuryPage170() end, "utility")
    ui.next = XButton(list, ">", 386, -324, 48, 24, function() ui.offset = ui.offset + 5 OTLGM:RefreshTreasuryPage170() end, "utility")
    ui.status = XText(list, "GameFontNormalSmall", "", 12, -330, 300, "LEFT")

    local detail = XPanel(page, 458, -160, 260, 358, "background")
    ui.serverTitle = XText(detail, "GameFontNormal", "GUILD BANK ADAPTER", 12, -12, 236, "LEFT")
    ui.serverState = XWrapped(detail, "GameFontNormalSmall", "", 12, -34, 236, 48)
    ui.detect = XButton(detail, "Check Server Support", 12, -82, 236, 26, function() OTLGM:RefreshGuildBankAdapter170() OTLGM:RefreshTreasuryPage170() end, "utility")
    ui.editorTitle = XText(detail, "GameFontNormal", "GOAL DETAILS", 12, -124, 236, "LEFT")
    XText(detail, "GameFontNormalSmall", "Name", 12, -148, 60, "LEFT")
    ui.nameEdit = XEdit(detail, "OTLGM_TreasuryGoalName170", 72, -142, 176, 26, 42)
    XText(detail, "GameFontNormalSmall", "Raised (gold)", 12, -180, 108, "LEFT")
    XText(detail, "GameFontNormalSmall", "Target (gold)", 130, -180, 118, "LEFT")
    ui.currentEdit = XEdit(detail, "OTLGM_TreasuryCurrent170", 12, -194, 108, 26, 10)
    ui.targetEdit = XEdit(detail, "OTLGM_TreasuryTarget170", 130, -194, 118, 26, 10)
    ui.save = XButton(detail, "Save Shared Goal", 12, -228, 152, 28, function()
        local id = ui.selected or ("CUSTOM" .. tostring(OTLGM:Now()) .. tostring(math.random(10, 99)))
        local selectedGoal = ui.selected and OTLGM:GetTreasuryGoal170(ui.selected)
        local ok, problem = OTLGM:SetTreasuryGoal170(id, ui.nameEdit:GetText(), XGoldToCopper(ui.currentEdit:GetText()), XGoldToCopper(ui.targetEdit:GetText()), selectedGoal and selectedGoal.category or "CUSTOM")
        if not ok then OTLGM:ShowNotice("Treasury Goal", problem) else ui.selected = id OTLGM:RefreshTreasuryPage170(true) end
    end, "confirm")
    ui.delete = XButton(detail, "Delete", 172, -228, 76, 28, function()
        if ui.selected then OTLGM:ShowConfirm("Delete Treasury Goal", "Delete this shared funding goal?", "Delete", function() OTLGM:DeleteTreasuryGoal170(ui.selected) ui.selected = nil OTLGM:RefreshTreasuryPage170(true) end) end
    end, "danger")
    XText(detail, "GameFontNormalSmall", "RECENT CHANGES", 12, -266, 236, "LEFT")
    ui.history = {}
    for index = 1, 3 do
        ui.history[index] = XText(detail, "GameFontNormalSmall", "", 12, -288 - ((index - 1) * 22), 236, "LEFT")
        ui.history[index]:SetTextColor(0.64, 0.64, 0.61)
    end
end

function OTLGM:RefreshTreasuryPage170(forceEditor)
    local ui = self.ui and self.ui.treasury170
    if not ui then return end
    local treasury = self:EnsureTreasury170()
    local goals = self:GetTreasuryGoals170()
    local capability = self:GetGuildBankCapability170()
    local snapshot = self.runtime and self.runtime.guildBank170
    if capability.available then
        ui.bannerStatus:SetText(self.colors.green .. "Read-only server guild-bank data is available; addon goals remain leadership-recorded." .. self.colors.reset)
        ui.serverState:SetText("Detected: " .. (capability.money and "balance  " or "") .. (capability.tabs and "tabs  " or "") .. (capability.items and "items  " or "") .. (capability.history and "history" or "") .. (snapshot and snapshot.money and ("\nBalance: " .. XMoney(snapshot.money)) or ""))
    else
        ui.bannerStatus:SetText("Manual goals - the addon never reads mail or moves money/items on this client.")
        ui.serverState:SetText("Unavailable on this client build. The adapter is prepared and remains dormant until compatible APIs appear.")
    end
    local maximum = math.max(0, table.getn(goals) - 5)
    if ui.offset > maximum then ui.offset = maximum end
    local index, row, goal, percentage
    for index = 1, 5 do
        row = ui.rows[index]
        goal = goals[ui.offset + index]
        if goal then
            row.goal170 = goal
            percentage = (tonumber(goal.target) or 0) > 0 and math.min(1, (tonumber(goal.current) or 0) / goal.target) or 0
            row.name:SetText(XShort(goal.name, 34))
            row.amount:SetText((goal.target or 0) > 0 and (XMoney(goal.current, true) .. " / " .. XMoney(goal.target, true)) or "Goal not set")
            row.meta:SetText((goal.target or 0) > 0 and (tostring(math.floor(percentage * 100)) .. "% funded  -  updated by " .. tostring(goal.updatedBy or "Leadership")) or "Set a target to begin tracking progress")
            row.progress:SetWidth(math.max(1, math.floor(408 * percentage)))
            XSelect(row, ui.selected == goal.id)
            row:Show()
        else row.goal170 = nil row:Hide() end
    end
    ui.status:SetText(tostring(table.getn(goals)) .. " shared goal" .. (table.getn(goals) == 1 and "" or "s") .. "  -  manual planning")
    XEnable(ui.prev, ui.offset > 0, "First page")
    XEnable(ui.next, ui.offset < maximum, "Last page")
    local selected = ui.selected and self:GetTreasuryGoal170(ui.selected)
    if selected and (forceEditor or not self:IsEditBoxFocused170(ui.nameEdit)) then
        ui.nameEdit:SetText(selected.name or "")
        ui.currentEdit:SetText(tostring((tonumber(selected.current) or 0) / 10000))
        ui.targetEdit:SetText(tostring((tonumber(selected.target) or 0) / 10000))
        ui.editorTitle:SetText("EDIT SHARED GOAL")
    elseif not selected and forceEditor then
        ui.nameEdit:SetText("") ui.currentEdit:SetText("0") ui.targetEdit:SetText("0") ui.editorTitle:SetText("NEW FUNDING GOAL")
    end
    local canEdit = self:CanEditTreasury170()
    XEnable(ui.newGoal, canEdit, "Only guild leadership can edit shared goals.")
    XEnable(ui.save, canEdit, "Only guild leadership can edit shared goals.")
    XEnable(ui.delete, canEdit and selected ~= nil, "Select a goal you can edit.")
    for index = 1, 3 do
        local history = treasury.history[index]
        ui.history[index]:SetText(history and (date("%d %b", history.ts or self:Now()) .. "  " .. (history.actor or "Leadership") .. "  " .. string.lower(history.kind or "update")) or "")
    end
end

-- -------------------------------------------------------------------------
-- Action Inbox
-- -------------------------------------------------------------------------

function OTLGM:BuildInbox170()
    if self.ui.inbox170 or not self.ui.main then return end
    local main = self.ui.main
    local overlay = CreateFrame("Button", nil, main)
    if self.PrepareInteractiveControl170 then self:PrepareInteractiveControl170(overlay, "button") end
    overlay:SetAllPoints(main)
    overlay:SetFrameLevel(main:GetFrameLevel() + 54)
    overlay:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", tile=true, tileSize=16, edgeSize=0, insets={left=0,right=0,top=0,bottom=0} })
    overlay:SetBackdropColor(0,0,0,0.72)
    overlay:SetScript("OnClick", function() OTLGM:CloseInbox170() end)
    overlay:Hide()
    self.ui.inboxOverlay170 = overlay

    local drawer = XPanel(main, 199, -112, 620, 500, "raised")
    drawer:SetFrameLevel(main:GetFrameLevel() + 55)
    drawer:Hide()
    drawer.mode = "ALL"
    drawer.offset = 0
    self.ui.inbox170 = drawer
    XText(drawer, "GameFontNormalLarge", "Guild Inbox", 18, -16, 360, "LEFT")
    drawer.close = XButton(drawer, "X", 580, -12, 28, 26, function() OTLGM:CloseInbox170() end, "danger")
    drawer.subtitle = XText(drawer, "GameFontNormalSmall", "Replies, mentions, important posts and group updates in one place.", 18, -42, 560, "LEFT")
    drawer.tabs = {}
    local definitions = { {"ALL", "All"}, {"UNREAD", "Unread"}, {"ACTION", "Actions"} }
    local index
    for index = 1, 3 do
        local mode = definitions[index][1]
        drawer.tabs[mode] = XButton(drawer, definitions[index][2], 18 + ((index - 1) * 118), -68, 108, 28, function()
            drawer.mode = mode
            drawer.offset = 0
            OTLGM:RefreshInbox170()
        end, "utility")
    end
    drawer.rows = {}
    for index = 1, 7 do
        local row = XButton(drawer, "", 18, -106 - ((index - 1) * 49), 584, 45, function(button)
            local entry = button.entry170
            if not entry then return end
            OTLGM:MarkInboxRead170(entry.id)
            OTLGM:CloseInbox170()
            if entry.targetPage and OTLGM.ui.pages[entry.targetPage] then OTLGM:ShowPage(entry.targetPage) end
        end, "normal")
        row.text:Hide()
        row.state = XText(row, "GameFontNormalSmall", "", 8, -6, 62, "LEFT")
        row.title = XText(row, "GameFontNormalSmall", "", 74, -6, 480, "LEFT")
        row.body = XText(row, "GameFontNormalSmall", "", 8, -24, 548, "LEFT")
        row.body:SetTextColor(0.58, 0.58, 0.56)
        drawer.rows[index] = row
    end
    drawer.empty = XWrapped(drawer, "GameFontNormal", "You're all caught up.\nNew replies, important posts and group updates will appear here.", 120, -216, 380, 80)
    drawer.empty:SetTextColor(0.60, 0.60, 0.58)
    drawer.markAll = XButton(drawer, "Mark All Read", 18, -458, 122, 28, function() OTLGM:MarkInboxCategoryRead170(nil) OTLGM:RefreshInbox170() end, "utility")
    drawer.previous = XButton(drawer, "<", 430, -458, 38, 28, function() drawer.offset = math.max(0, (drawer.offset or 0) - 7) OTLGM:RefreshInbox170() end, "utility")
    drawer.next = XButton(drawer, ">", 474, -458, 38, 28, function() drawer.offset = (drawer.offset or 0) + 7 OTLGM:RefreshInbox170() end, "utility")
    drawer.count = XText(drawer, "GameFontNormalSmall", "", 520, -466, 82, "RIGHT")

    self.ui.inboxButton170 = XButton(main, "Inbox", 0, 0, 78, 24, function() OTLGM:ToggleInbox170() end, "utility")
    self.ui.inboxButton170:ClearAllPoints()
    self.ui.inboxButton170:SetPoint("TOPRIGHT", main, "TOPRIGHT", -250, -47)
    self.ui.inboxButton170:SetFrameLevel(main:GetFrameLevel() + 20)
end

function OTLGM:RefreshInbox170()
    local drawer = self.ui and self.ui.inbox170
    if not drawer then return end
    local entries = self:GetInboxEntries170(drawer.mode)
    local maximum = math.max(0, table.getn(entries) - 7)
    drawer.offset = math.max(0, math.min(tonumber(drawer.offset) or 0, maximum))
    local index, row, entry
    for index = 1, 7 do
        row = drawer.rows[index]
        entry = entries[drawer.offset + index]
        if entry then
            row.entry170 = entry
            row.state:SetText(entry.read and self.colors.grey .. "READ" .. self.colors.reset or self.colors.green .. "NEW" .. self.colors.reset)
            row.title:SetText(XShort(entry.title, 35))
            row.body:SetText(XShort(entry.body, 48))
            XSelect(row, not entry.read)
            row:Show()
        else row.entry170 = nil row:Hide() end
    end
    if table.getn(entries) == 0 then drawer.empty:Show() else drawer.empty:Hide() end
    if table.getn(entries) > 0 then
        drawer.count:SetText(tostring(drawer.offset + 1) .. "-" .. tostring(math.min(drawer.offset + 7, table.getn(entries))) .. "/" .. tostring(table.getn(entries)))
    else drawer.count:SetText("0") end
    XEnable(drawer.markAll, self:GetInboxUnreadCount170() > 0, "There are no unread notifications.")
    XEnable(drawer.previous, drawer.offset > 0, "This is the first page.")
    XEnable(drawer.next, drawer.offset < maximum, "There are no more notifications.")
    local mode, tab
    for mode, tab in pairs(drawer.tabs) do XSelect(tab, mode == drawer.mode) end
    self:RefreshExperienceNavigation170()
end

function OTLGM:ToggleInbox170()
    local drawer = self.ui and self.ui.inbox170
    if not drawer then return end
    if drawer:IsVisible() then self:CloseInbox170() return end
    if self.ui.inboxOverlay170 then self.ui.inboxOverlay170:Show() end
    drawer:Show()
    self:RefreshInbox170()
    self:StartExperienceMotion170(drawer, 0.45, 1, 0.12)
end

function OTLGM:CloseInbox170()
    if self.ui and self.ui.inbox170 then self.ui.inbox170:Hide() end
    if self.ui and self.ui.inboxOverlay170 then self.ui.inboxOverlay170:Hide() end
end

-- -------------------------------------------------------------------------
-- Guild Chat highlights: grouped conversations, mentions and local pins
-- -------------------------------------------------------------------------

local function XChatName(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "%-.*$", "")
    return string.gsub(value, "%s+", "")
end

function OTLGM:GetChatMessageKey170(message)
    if not message then return nil end
    return tostring(message.channel or "GUILD") .. ":" .. tostring(tonumber(message.ts) or 0) .. ":" .. XChatName(message.sender) .. ":" .. string.sub(tostring(message.text or ""), 1, 120)
end

function OTLGM:GetChatPins170()
    local db = self:GetGuildDB()
    if not db then return {} end
    db.chatPins170 = db.chatPins170 or {}
    while table.getn(db.chatPins170) > 30 do table.remove(db.chatPins170) end
    local index, pin
    for index = table.getn(db.chatPins170), 1, -1 do
        pin = db.chatPins170[index]
        if type(pin) ~= "table" or type(pin.key) ~= "string" or pin.key == "" then
            table.remove(db.chatPins170, index)
        else
            pin.channel = pin.channel == "OFFICER" and "OFFICER" or "GUILD"
        end
    end
    return db.chatPins170
end

function OTLGM:IsChatMessagePinned170(message)
    local key = self:GetChatMessageKey170(message)
    if not key then return false end
    local pins = self:GetChatPins170()
    local index
    for index = 1, table.getn(pins) do if pins[index].key == key then return true end end
    return false
end

function OTLGM:ToggleChatMessagePin170(message)
    local key = self:GetChatMessageKey170(message)
    if not key then return false end
    local pins = self:GetChatPins170()
    local index
    for index = 1, table.getn(pins) do
        if pins[index].key == key then
            table.remove(pins, index)
            if self.RefreshGuildChatPage then self:RefreshGuildChatPage() end
            if self.RefreshChatHighlights170 then self:RefreshChatHighlights170() end
            return true
        end
    end
    table.insert(pins, 1, {
        key = key,
        ts = tonumber(message.ts) or self:Now(),
        sender = self:SafeText(message.sender or "Unknown", 42, false, false),
        text = self:SafeText(message.text or "", 240, false, false),
        channel = message.channel == "OFFICER" and "OFFICER" or "GUILD",
    })
    while table.getn(pins) > 30 do table.remove(pins) end
    if self.RefreshGuildChatPage then self:RefreshGuildChatPage() end
    if self.RefreshChatHighlights170 then self:RefreshChatHighlights170() end
    return true
end

function OTLGM:GetChatHighlights170(mode, channel)
    mode = mode == "PINNED" and "PINNED" or "MENTIONS"
    channel = channel == "OFFICER" and "OFFICER" or "GUILD"
    local result = {}
    local source, index, message
    if mode == "PINNED" then
        source = self:GetChatPins170()
        for index = 1, table.getn(source) do
            message = source[index]
            if message.channel == channel then table.insert(result, message) end
        end
    else
        source = self:GetGuildChatMessages(channel)
        for index = table.getn(source), 1, -1 do
            message = source[index]
            if self:GuildChatTextMentionsPlayer(message.text or "") then table.insert(result, message) end
            if table.getn(result) >= 30 then break end
        end
    end
    return result
end

function OTLGM:OpenChatHighlight170(message)
    if not message then return end
    local channel = message.channel == "OFFICER" and "OFFICER" or "GUILD"
    OTLGM_DB.settings.guildChatView = channel
    self:SetGuildChatChannel(channel)
    local messages = self:GetGuildChatMessages(channel)
    local key = self:GetChatMessageKey170(message)
    local index
    for index = table.getn(messages), 1, -1 do
        if self:GetChatMessageKey170(messages[index]) == key then
            self.ui.chatOffsets[channel] = math.max(0, table.getn(messages) - index)
            self:RefreshGuildChatPage()
            return
        end
    end
    if self.SetStatus then self:SetStatus("That pinned message is no longer in the bounded local chat history.") end
end

function OTLGM:BuildGuildChatExperience170()
    if self.ui.chatHighlights170 or not self.ui.chatClearButton or not self.ui.pages.guildchat then return end
    local page = self.ui.pages.guildchat
    self.ui.chatClearButton.text:SetText("Highlights")
    self.ui.chatClearButton:SetScript("OnClick", function()
        local panel = OTLGM.ui.chatHighlights170
        if panel:IsVisible() then panel:Hide()
        else
            if OTLGM.ui.chatNameMenu then OTLGM.ui.chatNameMenu:Hide() end
            OTLGM:CloseInbox170()
            panel:Show()
            OTLGM:RefreshChatHighlights170()
            OTLGM:StartExperienceMotion170(panel, 0.45, 1, 0.10)
        end
    end)

    local panel = XPanel(page, 394, -72, 324, 414, "raised")
    panel:SetFrameLevel(page:GetFrameLevel() + 52)
    panel:Hide()
    panel.mode = "MENTIONS"
    panel.offset = 0
    self.ui.chatHighlights170 = panel
    XText(panel, "GameFontNormal", "CHAT HIGHLIGHTS", 14, -13, 214, "LEFT")
    panel.close = XButton(panel, "X", 282, -8, 28, 26, function() panel:Hide() end, "danger")
    panel.subtitle = XText(panel, "GameFontNormalSmall", "Focus without changing the real guild chat.", 14, -34, 286, "LEFT")
    panel.tabs = {
        MENTIONS = XButton(panel, "Mentions", 12, -58, 142, 26, function() panel.mode = "MENTIONS" panel.offset = 0 OTLGM:RefreshChatHighlights170() end, "utility"),
        PINNED = XButton(panel, "Pinned", 162, -58, 148, 26, function() panel.mode = "PINNED" panel.offset = 0 OTLGM:RefreshChatHighlights170() end, "utility"),
    }
    panel.rows = {}
    local rowIndex
    for rowIndex = 1, 7 do
        local row = XButton(panel, "", 12, -92 - ((rowIndex - 1) * 40), 298, 36, function(button)
            if button.message170 then panel:Hide() OTLGM:OpenChatHighlight170(button.message170) end
        end, "normal")
        row.text:Hide()
        row.sender = XText(row, "GameFontNormalSmall", "", 8, -5, 112, "LEFT")
        row.time = XText(row, "GameFontNormalSmall", "", 216, -5, 70, "RIGHT")
        row.time:SetTextColor(0.50, 0.50, 0.48)
        row.body = XText(row, "GameFontNormalSmall", "", 8, -20, 278, "LEFT")
        row.body:SetTextColor(0.68, 0.68, 0.66)
        panel.rows[rowIndex] = row
    end
    panel.empty = XWrapped(panel, "GameFontNormal", "No highlights here yet.\nMentions appear automatically; pin a useful message with its star.", 30, -172, 264, 78)
    panel.empty:SetTextColor(0.60, 0.60, 0.58)
    panel.previous = XButton(panel, "<", 12, -380, 34, 24, function() panel.offset = math.max(0, (panel.offset or 0) - 7) OTLGM:RefreshChatHighlights170() end, "utility")
    panel.next = XButton(panel, ">", 52, -380, 34, 24, function() panel.offset = (panel.offset or 0) + 7 OTLGM:RefreshChatHighlights170() end, "utility")
    panel.status = XText(panel, "GameFontNormalSmall", "", 94, -386, 82, "LEFT")
    panel.clear = XButton(panel, "Clear Local", 202, -380, 108, 24, function()
        local channel = OTLGM:GetGuildChatChannel()
        OTLGM:ShowConfirm("Clear Local Chat History", "Remove the locally stored " .. string.lower(channel) .. " chat history from this addon? This does not delete normal game chat.", "Clear", function() OTLGM:ClearGuildChatHistory(channel) panel:Hide() end)
    end, "danger")

    local index, row
    for index = 1, table.getn(self.ui.chatRows or {}) do
        row = self.ui.chatRows[index]
        local pin = CreateFrame("Button", nil, row)
        OTLGM:PrepareInteractiveControl170(pin, "button")
        pin:SetWidth(20) pin:SetHeight(20)
        pin:SetFrameLevel(row:GetFrameLevel() + 8)
        pin.text = pin:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        pin.text:SetPoint("CENTER", pin, "CENTER", 0, 0)
        pin.text:SetText("+")
        pin.text:SetTextColor(0.58, 0.51, 0.36)
        pin:SetScript("OnEnter", function()
            this.text:SetTextColor(1.0, 0.78, 0.24)
            GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
            GameTooltip:AddLine(this.pinned170 and "Unpin message" or "Pin message", 1.0, 0.82, 0.35)
            GameTooltip:AddLine("Local to this installation.", 0.58, 0.58, 0.58)
            GameTooltip:Show()
        end)
        pin:SetScript("OnLeave", function() this.text:SetTextColor(this.pinned170 and 1.0 or 0.58, this.pinned170 and 0.76 or 0.51, this.pinned170 and 0.20 or 0.36) GameTooltip:Hide() end)
        pin:SetScript("OnClick", function() if this.message170 then OTLGM:ToggleChatMessagePin170(this.message170) end end)
        row.pinButton170 = pin
    end
end

function OTLGM:RefreshChatHighlights170()
    local panel = self.ui and self.ui.chatHighlights170
    if not panel then return end
    local channel = self:GetGuildChatChannel()
    local entries = self:GetChatHighlights170(panel.mode, channel)
    local maximum = math.max(0, table.getn(entries) - 7)
    panel.offset = math.max(0, math.min(tonumber(panel.offset) or 0, maximum))
    local index, row, message
    for index = 1, 7 do
        row = panel.rows[index]
        message = entries[panel.offset + index]
        if message then
            row.message170 = message
            row.sender:SetText(self:GetGuildChatSenderColor(message.sender) .. XShort(string.gsub(message.sender or "Unknown", "%-.*$", ""), 16) .. self.colors.reset)
            row.time:SetText(date("%d %b %H:%M", message.ts or self:Now()))
            row.body:SetText(XShort(self:GetGuildChatVisibleText(message.text or ""), 54))
            row:Show()
        else row.message170 = nil row:Hide() end
    end
    panel.subtitle:SetText((channel == "OFFICER" and "Officer" or "Guild") .. " chat  -  " .. (panel.mode == "PINNED" and "local pins" or "mentions of you"))
    panel.empty:SetText(panel.mode == "PINNED" and "No pinned messages yet.\nUse the pin marker beside any message to keep it here." or "No recent mentions in this local history.\nMessages that name your character appear here automatically.")
    if table.getn(entries) == 0 then panel.empty:Show() else panel.empty:Hide() end
    panel.status:SetText(table.getn(entries) == 0 and "0" or (tostring(panel.offset + 1) .. "-" .. tostring(math.min(panel.offset + 7, table.getn(entries))) .. "/" .. tostring(table.getn(entries))))
    XSelect(panel.tabs.MENTIONS, panel.mode == "MENTIONS")
    XSelect(panel.tabs.PINNED, panel.mode == "PINNED")
    XEnable(panel.previous, panel.offset > 0, "This is the first page.")
    XEnable(panel.next, panel.offset < maximum, "There are no more highlights.")
end

function OTLGM:RefreshGuildChatExperience170()
    if not self.ui or not self.ui.chatRows then return end
    local view = OTLGM_DB.settings.guildChatView or "GUILD"
    if view == "BOARD" then
        if self.ui.chatHighlights170 then self.ui.chatHighlights170:Hide() end
        return
    end
    local compact = self:GetGuildChatChannel() == "OFFICER" and self:IsOfficerMode()
    local previous
    local index, row, message, grouped
    for index = 1, table.getn(self.ui.chatRows) do
        row = self.ui.chatRows[index]
        message = row.chatData
        if row.pinButton170 then
            if message and row:IsVisible() then
                row.pinButton170.message170 = message
                row.pinButton170.pinned170 = self:IsChatMessagePinned170(message)
                row.pinButton170.text:SetText(row.pinButton170.pinned170 and "*" or "+")
                row.pinButton170.text:SetTextColor(row.pinButton170.pinned170 and 1.0 or 0.58, row.pinButton170.pinned170 and 0.76 or 0.51, row.pinButton170.pinned170 and 0.20 or 0.36)
                row.pinButton170:ClearAllPoints()
                row.pinButton170:SetPoint("TOPRIGHT", row, "TOPRIGHT", -2, -2)
                if row.newLine:IsVisible() then row.pinButton170:Hide() else row.pinButton170:Show() end
                local isAchievement = string.find(tostring(message.text or ""), "^%[Guild Achievement%]") ~= nil
                row.messageFrame:SetWidth(isAchievement and 582 or ((compact and 284 or 444) - 24))
                -- Keep every message self-identifying. Hiding the sender on consecutive
                -- messages looked like broken wrapping and made separate messages merge visually.
                grouped = false
                row.channelAccent:SetAlpha(1)
                previous = message
            else
                row.pinButton170.message170 = nil
                row.pinButton170:Hide()
            end
        end
    end
    if self.ui.chatClearButton and self.ui.chatClearButton.text then
        local count = table.getn(self:GetChatHighlights170("MENTIONS", self:GetGuildChatChannel()))
        self.ui.chatClearButton.text:SetText(count > 0 and ("Highlights " .. tostring(count)) or "Highlights")
    end
    if self.ui.chatHighlights170 and self.ui.chatHighlights170:IsVisible() then self:RefreshChatHighlights170() end
end

-- -------------------------------------------------------------------------
-- Crest quick menu and general presentation
-- -------------------------------------------------------------------------

function OTLGM:BuildMotionSettings170()
    local panel = self.ui.settingsPanels and self.ui.settingsPanels.GENERAL
    if not panel or self.ui.motionButtons170 then return end
    XText(panel, "GameFontNormal", "MICRO-INTERACTIONS", 14, -350, 250, "LEFT")
    self.ui.motionButtons170 = {}
    local definitions = { {"FULL", "Full"}, {"REDUCED", "Reduced"}, {"OFF", "Off"} }
    local index
    for index = 1, 3 do
        local mode = definitions[index][1]
        self.ui.motionButtons170[mode] = XButton(panel, definitions[index][2], 14 + ((index - 1) * 92), -376, 84, 28, function()
            OTLGM_DB.settings.motionMode170 = mode
            OTLGM:RefreshSettingsPage()
        end, "utility")
    end
    XText(panel, "GameFontNormalSmall", "Short fades only; automatically suppressed in combat.", 300, -384, 390, "LEFT"):SetTextColor(0.58, 0.58, 0.56)
end

function OTLGM:RefreshExperienceSettings170()
    local buttons = self.ui and self.ui.motionButtons170
    if not buttons then return end
    local mode = OTLGM_DB.settings.motionMode170 or "FULL"
    local key, button
    for key, button in pairs(buttons) do XSelect(button, key == mode) end
end

function OTLGM:RefreshHomeExperience170()
    if self.ui.homeRaidText and not self.ui.homeRaidWatermark170 then
        local parent = self.ui.homeRaidText:GetParent()
        local texture = parent:CreateTexture(nil, "ARTWORK")
        texture:SetTexture("Interface\\Icons\\INV_BannerPVP_02")
        texture:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, -10)
        texture:SetWidth(40) texture:SetHeight(40) texture:SetAlpha(0.78)
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        self.ui.homeRaidWatermark170 = texture
        local hit = CreateFrame("Button", nil, parent)
        OTLGM:PrepareInteractiveControl170(hit, "button")
        hit:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -4)
        hit:SetWidth(250) hit:SetHeight(96)
        hit:SetFrameLevel(parent:GetFrameLevel() + 3)
        hit:SetScript("OnEnter", function() parent:SetBackdropBorderColor(0.94, 0.52, 0.18, 1) end)
        hit:SetScript("OnLeave", function() parent:SetBackdropBorderColor(0.52, 0.18, 0.12, 1) end)
        hit:SetScript("OnClick", function() OTLGM_DB.settings.pveSection = "RAIDS" OTLGM:ShowPage("pve") end)
        self.ui.homeRaidHit170 = hit
    end
end

function OTLGM:BuildRosterExperience170()
    if self.ui.rosterAddonMarkers170 or not self.ui.rosterRows then return end
    self.ui.rosterAddonMarkers170 = {}
    local index, row
    for index = 1, table.getn(self.ui.rosterRows) do
        row = self.ui.rosterRows[index]
        row.recentIcon:ClearAllPoints()
        row.recentIcon:SetPoint("TOPLEFT", row, "TOPLEFT", 456, -6)
        row.recentIcon:SetWidth(14)
        row.addonMarker170 = row:CreateTexture(nil, "OVERLAY")
        row.addonMarker170:SetTexture("Interface\\Icons\\INV_Misc_Rune_01")
        row.addonMarker170:SetPoint("TOPLEFT", row, "TOPLEFT", 474, -5)
        row.addonMarker170:SetWidth(14) row.addonMarker170:SetHeight(14)
        row.addonMarker170:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.addonMarker170:Hide()
        self.ui.rosterAddonMarkers170[index] = row.addonMarker170
    end
end

function OTLGM:RefreshRosterExperience170()
    if not self.ui.rosterRows then return end
    local officer = self:IsOfficerMode()
    local index, row, detection
    for index = 1, table.getn(self.ui.rosterRows) do
        row = self.ui.rosterRows[index]
        if row.addonMarker170 then
            if officer and row.memberName then
                detection = self:GetAddonDetection170(row.memberName)
                if detection.state == "ACTIVE" then row.addonMarker170:SetVertexColor(0.30, 0.95, 0.42) row.addonMarker170:Show()
                elseif detection.state == "RECENT" or detection.state == "SEEN" then row.addonMarker170:SetVertexColor(1.0, 0.72, 0.20) row.addonMarker170:Show()
                else row.addonMarker170:Hide() end
            else row.addonMarker170:Hide() end
        end
    end
end

local function XRaiseGroupFinderTree170(frame, baseLevel, depth)
    if not frame then return end
    depth = tonumber(depth) or 0
    if frame.SetFrameLevel then frame:SetFrameLevel(baseLevel + depth) end
    if not frame.GetChildren then return end
    local children = { frame:GetChildren() }
    local index, child
    for index = 1, table.getn(children) do
        child = children[index]
        if child and child ~= frame then XRaiseGroupFinderTree170(child, baseLevel, depth + 2) end
    end
end

function OTLGM:RaiseGroupFinderComposer170()
    if not self.ui or not self.ui.pveGroupForm170 or not self.ui.pveGroupFormShield170 then return end
    local form = self.ui.pveGroupForm170
    local shield = self.ui.pveGroupFormShield170
    local groups = self.ui.pvePanels and self.ui.pvePanels.GROUPS
    local baseLevel = (groups and groups:GetFrameLevel() or 1) + 24
    shield:SetFrameLevel(baseLevel)
    XRaiseGroupFinderTree170(form, baseLevel + 2, 0)
    form:EnableMouse(true)
end

function OTLGM:CloseGroupFinderComposer170()
    if self.ui and self.ui.pveGroupForm170 then
        self.ui.pveGroupForm170:Hide()
        if self.ui.pveRequestActivityEdit then self.ui.pveRequestActivityEdit:ClearFocus() end
        if self.ui.pveRequestNoteEdit then self.ui.pveRequestNoteEdit:ClearFocus() end
    end
    if self.ui and self.ui.pveGroupFormShield170 then self.ui.pveGroupFormShield170:Hide() end
end

function OTLGM:OpenGroupFinderComposer170()
    local form = self.ui and self.ui.pveGroupForm170
    if not form then return end
    self:RaiseGroupFinderComposer170()
    if self.ui.pveGroupFormShield170 then self.ui.pveGroupFormShield170:Show() end
    form:Show()
    self:StartExperienceMotion170(form, 0.45, 1, 0.10)
    if self.ui.pveRequestActivityEdit then self.ui.pveRequestActivityEdit:SetFocus() end
end

function OTLGM:BuildGroupFinderExperience170()
    if self.ui.pveGroupExperience170 or not self.ui.pveRequestCreateButton or not self.ui.pveRequestRows or not self.ui.pveRequestRows[1] then return end
    local form = self.ui.pveRequestCreateButton:GetParent()
    local list = self.ui.pveRequestRows[1]:GetParent()
    local groups = list:GetParent()
    local actions = self.ui.pveRequestSelectedText and self.ui.pveRequestSelectedText:GetParent()
    self.ui.pveGroupExperience170 = true
    self.ui.pveGroupForm170 = form
    self.ui.pveGroupList170 = list
    list:ClearAllPoints()
    list:SetPoint("TOPLEFT", groups, "TOPLEFT", 0, 0)
    list:SetWidth(718)
    if self.ui.pveRequestCount then self.ui.pveRequestCount:ClearAllPoints() self.ui.pveRequestCount:SetPoint("TOPRIGHT", list, "TOPRIGHT", -142, -10) self.ui.pveRequestCount:SetWidth(240) end
    self.ui.pveGroupCreateToggle170 = XButton(list, "Create Group", 584, -6, 122, 26, function() OTLGM:OpenGroupFinderComposer170() end, "confirm")
    local i, row
    for i = 1, table.getn(self.ui.pveRequestRows) do
        row = self.ui.pveRequestRows[i]
        row:SetWidth(670)
        row.title:SetWidth(390)
        row.author:ClearAllPoints() row.author:SetPoint("TOPRIGHT", row, "TOPRIGHT", -12, -6) row.author:SetWidth(180)
        row.composition:SetWidth(440)
        row.status:ClearAllPoints() row.status:SetPoint("TOPRIGHT", row, "TOPRIGHT", -12, -25) row.status:SetWidth(180)
    end
    if self.ui.pveGroupSlider then self.ui.pveGroupSlider:ClearAllPoints() self.ui.pveGroupSlider:SetPoint("TOPLEFT", list, "TOPLEFT", 692, -34) end
    if actions then
        actions:SetWidth(698)
        self.ui.pveRequestSelectedText:SetWidth(678)
    end
    self.ui.pveGroupEmpty170 = XWrapped(list, "GameFontNormal", "No open groups right now. Create one when you are ready to lead, or check again after synchronization.", 130, -150, 450, 70)
    self.ui.pveGroupEmpty170:SetTextColor(0.58, 0.58, 0.56)
    self.ui.pveGroupEmpty170:Hide()

    local shield = CreateFrame("Button", nil, groups)
    OTLGM:PrepareInteractiveControl170(shield, "button")
    shield:SetAllPoints(groups)
    shield:EnableMouse(true)
    shield:SetScript("OnClick", function() OTLGM:CloseGroupFinderComposer170() end)
    local shade = shield:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints(shield) shade:SetTexture(0, 0, 0, 0.72)
    shield:Hide()
    self.ui.pveGroupFormShield170 = shield
    form:ClearAllPoints()
    form:SetPoint("TOP", groups, "TOP", 0, -2)
    form:EnableMouse(true)
    local close = XButton(form, "X", 238, -8, 28, 26, function() OTLGM:CloseGroupFinderComposer170() end, "danger")
    self.ui.pveGroupFormClose170 = close
    self:RaiseGroupFinderComposer170()
    form:Hide()
end

function OTLGM:RefreshGroupFinderExperience170()
    if not self.ui or not self.ui.pveGroupExperience170 then return end
    local requests = self.GetPveRequests and self:GetPveRequests() or {}
    if self.ui.pveGroupEmpty170 then
        if table.getn(requests) == 0 then self.ui.pveGroupEmpty170:Show() else self.ui.pveGroupEmpty170:Hide() end
    end
end

function OTLGM:RefreshExperienceNavigation170()
    local button = self.ui and self.ui.inboxButton170
    if button then
        local unread = self:GetInboxUnreadCount170()
        button.text:SetText(unread > 0 and ("Inbox  " .. tostring(unread > 99 and "99+" or unread)) or "Inbox")
        button.actionStyle = unread > 0 and "primary" or "utility"
        self:ApplyButtonSkin(button)
    end
end

function OTLGM:BuildExperience170()
    if not self.ui or not self.ui.main or self.ui.experience170Built then return end
    self.ui.pages.treasury = self.ui.pages.treasury or CreateFrame("Frame", nil, self.ui.content)
    self.ui.pages.treasury:SetPoint("TOPLEFT", self.ui.content, "TOPLEFT", 18, -18)
    self.ui.pages.treasury:SetWidth(756) self.ui.pages.treasury:SetHeight(532) self.ui.pages.treasury:Hide()
    self.ui.navButtons.treasury = XButton(self.ui.sidebar, "Treasury", 12, -242, 142, 26, function() OTLGM:ShowPage("treasury") end, "normal")
    local icon = self.ui.navButtons.treasury:CreateTexture(nil, "OVERLAY")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01") icon:SetPoint("LEFT", self.ui.navButtons.treasury, "LEFT", 7, 0) icon:SetWidth(15) icon:SetHeight(15)
    self.ui.navButtons.treasury.text:ClearAllPoints() self.ui.navButtons.treasury.text:SetPoint("LEFT", self.ui.navButtons.treasury, "LEFT", 29, 0)
    self:BuildTreasuryPage170(self.ui.pages.treasury)
    self:BuildInbox170()
    self:BuildGuildChatExperience170()
    self:BuildProfessionExperience170()
    self:BuildMotionSettings170()
    self:BuildRosterExperience170()
    self:BuildGroupFinderExperience170()
    self:RefreshHomeExperience170()
    self.ui.experience170Built = true
    self:RefreshExperienceNavigation170()
    self:RefreshExperienceSettings170()
end

local XBaseRefreshPveGroupsPanel170 = OTLGM.RefreshPveGroupsPanel
if XBaseRefreshPveGroupsPanel170 then
    OTLGM.RefreshPveGroupsPanel = function(self)
        local result = XBaseRefreshPveGroupsPanel170(self)
        if self.RefreshGroupFinderExperience170 then self:RefreshGroupFinderExperience170() end
        return result
    end
end

OTLGM:RegisterModule("Experience", {
    layer = "ui",
    generation = "1.7",
    motion = "centralized",
    premiumViews = { "inbox", "treasury", "compact-chat", "favorites", "group-finder" },
})
