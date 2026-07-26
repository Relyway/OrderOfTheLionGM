-- Order of the Lion Guild Manager v1.7.6 R5 hotfix 1
-- Modal interaction, Treasury goal actions, contributor roster metadata and
-- donor achievements. No OnUpdate handler and no background roster scan.

if not OTLGM then return end

OTLGM.version = "1.7.6"
OTLGM.build = "performance-r5-hotfix1-20260726"

local H1 = {
    revision = 1,
    modalRepairs = 0,
    donorEvaluations = 0,
    donorMessages = 0,
    goalButtonsBuilt = 0,
}
OTLGM.release176r5Hotfix = H1

local DONOR_TOTAL_LIMIT_H1 = 300
local DONOR_ACHIEVEMENTS_H1 = {
    { id="E001", category="SOCIAL", name="First Coin for the Pride", description="Contribute at least five gold to shared guild Treasury goals.", icon="Interface\\Icons\\INV_Misc_Coin_01", progress="treasuryDonatedGoldR5", required=5, seriesKey176="treasuryDonor", seriesOrder176=1, seriesKeyR6="treasuryDonor", seriesTierR6=1 },
    { id="E002", category="SOCIAL", name="Helping Paw", description="Contribute at least twenty-five gold to shared guild Treasury goals.", icon="Interface\\Icons\\INV_Misc_Coin_02", progress="treasuryDonatedGoldR5", required=25, seriesKey176="treasuryDonor", seriesOrder176=2, seriesKeyR6="treasuryDonor", seriesTierR6=2 },
    { id="E003", category="SOCIAL", name="Patron of the Lion", description="Contribute at least fifty gold to shared guild Treasury goals.", icon="Interface\\Icons\\INV_Misc_Coin_03", progress="treasuryDonatedGoldR5", required=50, seriesKey176="treasuryDonor", seriesOrder176=3, seriesKeyR6="treasuryDonor", seriesTierR6=3 },
    { id="E004", category="SOCIAL", name="Golden Benefactor", description="Contribute at least one hundred gold to shared guild Treasury goals.", icon="Interface\\Icons\\INV_Misc_Coin_05", progress="treasuryDonatedGoldR5", required=100, seriesKey176="treasuryDonor", seriesOrder176=4, seriesKeyR6="treasuryDonor", seriesTierR6=4 },
}

local function TrimH1(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function ShortNameH1(value)
    value = TrimH1(value)
    local dash = string.find(value, "-", 1, true)
    if dash then value = string.sub(value, 1, dash - 1) end
    return value
end

local function NameKeyH1(value)
    return string.lower(ShortNameH1(value))
end

local function SafeH1(value, maximum)
    if OTLGM.SafeText then return OTLGM:SafeText(value, maximum or 80, false, false) end
    value = TrimH1(value)
    value = string.gsub(value, "[%c]", " ")
    if maximum and string.len(value) > maximum then value = string.sub(value, 1, maximum) end
    return value
end

local function CountH1(tbl)
    local count = 0
    local key
    for key in pairs(tbl or {}) do count = count + 1 end
    return count
end

local function BackdropH1(frame, edge)
    if not frame or not frame.SetBackdrop then return end
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = edge or 9,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
end

local function ApplyButtonH1(button)
    if button and OTLGM.ApplyButtonSkin then OTLGM:ApplyButtonSkin(button) end
end

local function SetButtonTextH1(button, text)
    if not button then return end
    button.labelText = text or ""
    if button.text then button.text:SetText(text or "") end
end

local function SetEnabledH1(button, enabled, reason)
    if not button then return end
    button.disabled = not enabled
    button.disabledReason = enabled and nil or reason
    if OTLGM.SetControlEnabled170 then OTLGM:SetControlEnabled170(button, enabled, reason)
    elseif button.Enable and button.Disable then if enabled then button:Enable() else button:Disable() end end
    ApplyButtonH1(button)
end

local function ButtonH1(parent, label, x, y, width, height, callback, style)
    local button = CreateFrame("Button", nil, parent)
    if OTLGM.PrepareInteractiveControl170 then OTLGM:PrepareInteractiveControl170(button, "button") end
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetWidth(width)
    button:SetHeight(height)
    if parent and parent.GetFrameLevel and button.SetFrameLevel then button:SetFrameLevel((parent:GetFrameLevel() or 1) + 2) end
    button:RegisterForClicks("LeftButtonUp")
    BackdropH1(button, 8)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.text:SetWidth(math.max(8, width - 8))
    button.text:SetText(label or "")
    button.actionStyle = style or "utility"
    button.callbackH1 = callback
    button:SetScript("OnEnter", function()
        this.hovered = true
        ApplyButtonH1(this)
        if this.disabled and this.disabledReason and GameTooltip then
            GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
            GameTooltip:AddLine("Unavailable", 1, 0.72, 0.28)
            GameTooltip:AddLine(this.disabledReason, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function()
        this.hovered = nil
        ApplyButtonH1(this)
        if GameTooltip then GameTooltip:Hide() end
    end)
    button:SetScript("OnClick", function()
        if this.disabled then return end
        if this.callbackH1 then this.callbackH1(this) end
    end)
    ApplyButtonH1(button)
    return button
end

local function TextH1(parent, template, text, x, y, width, justify)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then label:SetWidth(width) end
    label:SetJustifyH(justify or "LEFT")
    if label.SetJustifyV then label:SetJustifyV("TOP") end
    label:SetText(text or "")
    return label
end

local function RegisterDonorAchievementsH1()
    local achievements = OTLGM.achievements174
    if not achievements then return false end
    local index, def
    for index = 1, table.getn(DONOR_ACHIEVEMENTS_H1) do
        def = DONOR_ACHIEVEMENTS_H1[index]
        if not achievements.byId[def.id] then
            table.insert(achievements.catalog, def)
            achievements.byId[def.id] = def
        end
    end
    achievements.catalogRevision = math.max(tonumber(achievements.catalogRevision) or 0, 15)
    return true
end

RegisterDonorAchievementsH1()

-- ---------------------------------------------------------------------------
-- Modal repair. The shade is restricted to the addon window, while every
-- modal child control is recursively raised above it. This fixes darkened,
-- unclickable edit boxes and buttons without dimming the whole game world.
-- ---------------------------------------------------------------------------

local function RaiseModalTreeH1(frame, baseLevel, depth)
    if not frame then return end
    depth = tonumber(depth) or 0
    if frame.SetFrameStrata then frame:SetFrameStrata("DIALOG") end
    if frame.SetFrameLevel then frame:SetFrameLevel(baseLevel + depth) end
    if not frame.GetChildren then return end
    local children = { frame:GetChildren() }
    local index, child
    for index = 1, table.getn(children) do
        child = children[index]
        if child and child ~= frame then RaiseModalTreeH1(child, baseLevel, depth + 2) end
    end
end

local function PositionModalShadeH1(self, frame)
    local overlay = self.ui and self.ui.exclusiveModalOverlayR5
    if not overlay then return end
    overlay:ClearAllPoints()
    local main = self.ui and self.ui.main
    if main and main:IsVisible() then
        overlay:SetPoint("TOPLEFT", main, "TOPLEFT", 2, -2)
        overlay:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -2, 2)
        overlay.modalShadeScopeH1 = "ADDON"
    else
        overlay:SetPoint("TOPLEFT", frame, "TOPLEFT", -18, 18)
        overlay:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 18, -18)
        overlay.modalShadeScopeH1 = "DIALOG"
    end
    if overlay.SetBackdropColor then overlay:SetBackdropColor(0, 0, 0, 0.66) end
    if overlay.SetBackdropBorderColor then overlay:SetBackdropBorderColor(0, 0, 0, 0) end
end

local function StyleModalH1(frame)
    if not frame then return end
    if frame.SetAlpha then frame:SetAlpha(1) end
    if frame.SetBackdropColor then frame:SetBackdropColor(0.004, 0.005, 0.007, 1) end
    if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(0.82, 0.55, 0.18, 1) end
    frame:EnableMouse(true)
end

local BaseOpenExclusiveModalH1 = OTLGM.OpenExclusiveModalR5
if BaseOpenExclusiveModalH1 then
    function OTLGM:OpenExclusiveModalR5(frame)
        local result = BaseOpenExclusiveModalH1(self, frame)
        if not result or not frame then return result end
        PositionModalShadeH1(self, frame)
        StyleModalH1(frame)
        local overlay = self.ui and self.ui.exclusiveModalOverlayR5
        local baseLevel = overlay and (overlay:GetFrameLevel() + 4) or 204
        RaiseModalTreeH1(frame, baseLevel, 0)
        H1.modalRepairs = H1.modalRepairs + 1
        return result
    end
end

-- ---------------------------------------------------------------------------
-- Current roster metadata. This is a read-only lookup against the already
-- cached guild roster and never requests or scans the roster in the background.
-- ---------------------------------------------------------------------------

function OTLGM:GetTreasuryContributorMetaH1(name)
    name = ShortNameH1(name)
    if name == "" then return nil end
    local member = self.GetMember and self:GetMember(name) or nil
    if not member then
        local player = ShortNameH1(UnitName and UnitName("player") or "")
        if NameKeyH1(name) == NameKeyH1(player) then
            local className = ""
            if UnitClass then className = UnitClass("player") or "" end
            local rankName = ""
            if GetGuildInfo then local guildName; guildName, rankName = GetGuildInfo("player") end
            return { name=name, class=className, rank=rankName or "Guild member", level=UnitLevel and UnitLevel("player") or 0, online=true }
        end
        return nil
    end
    return {
        name = member.name or name,
        class = member.class or "",
        rank = member.rank or "Guild member",
        level = tonumber(member.level) or 0,
        online = member.online and true or false,
    }
end

local function ContributorMetaTextH1(self, name, compact)
    local meta = self:GetTreasuryContributorMetaH1(name)
    if not meta then return compact and "Roster: unavailable" or "Current guild roster: unavailable" end
    local className = meta.class ~= "" and meta.class or "Unknown class"
    local rankName = meta.rank ~= "" and meta.rank or "Guild member"
    if compact then return className .. "  -  " .. rankName end
    return "Current guild roster: " .. className .. "  -  " .. rankName .. (meta.level > 0 and ("  -  level " .. tostring(meta.level)) or "")
end

local function ColoredContributorNameH1(self, name)
    local meta = self:GetTreasuryContributorMetaH1(name)
    if meta and self.GetClassColor then return self:GetClassColor(meta.class) .. tostring(name or meta.name) .. self.colors.reset end
    return tostring(name or "Anonymous")
end

-- ---------------------------------------------------------------------------
-- Treasury donor totals and donor-owned achievements. Recording a contribution
-- never completes an achievement for the officer unless that officer is also
-- the named contributor. Leadership sync sends only the requesting donor's
-- total, so this adds negligible network work.
-- ---------------------------------------------------------------------------

function OTLGM:EnsureTreasuryDonorTotalsH1()
    local treasury = self:EnsureTreasury170()
    if not treasury then return nil end
    if type(treasury.donorTotalsR5) ~= "table" then treasury.donorTotalsR5 = {} end
    if not treasury.donorTotalsMigratedH1 then
        local totals = {}
        local goalId, entries, index, entry, key, row
        for goalId, entries in pairs(treasury.contributions176 or {}) do
            for index = 1, table.getn(entries or {}) do
                entry = entries[index]
                if type(entry) == "table" and (tonumber(entry.amount) or 0) > 0 then
                    key = NameKeyH1(entry.contributor)
                    if key ~= "" then
                        row = totals[key]
                        if not row then row = { name=ShortNameH1(entry.contributor), total=0, updatedAt=0, actor=SafeH1(entry.actor or "Leadership", 28) } totals[key] = row end
                        row.total = math.min(2000000000, row.total + math.max(0, math.floor(tonumber(entry.amount) or 0)))
                        row.updatedAt = math.max(row.updatedAt, math.floor(tonumber(entry.ts) or 0))
                    end
                end
            end
        end
        local storedKey, stored
        for storedKey, stored in pairs(treasury.donorTotalsR5) do
            if type(stored) == "table" and NameKeyH1(stored.name or storedKey) ~= "" then
                key = NameKeyH1(stored.name or storedKey)
                row = totals[key]
                if not row or (tonumber(stored.total) or 0) > row.total then
                    totals[key] = {
                        name = ShortNameH1(stored.name or storedKey),
                        total = math.max(0, math.min(2000000000, math.floor(tonumber(stored.total) or 0))),
                        updatedAt = math.max(0, math.floor(tonumber(stored.updatedAt) or 0)),
                        actor = SafeH1(stored.actor or "Leadership", 28),
                    }
                end
            end
        end
        treasury.donorTotalsR5 = totals
        treasury.donorTotalsMigratedH1 = true
    end
    if CountH1(treasury.donorTotalsR5) > DONOR_TOTAL_LIMIT_H1 then
        local rows = {}
        local key, row
        for key, row in pairs(treasury.donorTotalsR5) do table.insert(rows, { key=key, ts=tonumber(row.updatedAt) or 0 }) end
        table.sort(rows, function(left, right) return left.ts > right.ts end)
        local index
        for index = DONOR_TOTAL_LIMIT_H1 + 1, table.getn(rows) do treasury.donorTotalsR5[rows[index].key] = nil end
    end
    return treasury
end

function OTLGM:SetTreasuryDonorTotalH1(name, total, actor, updatedAt)
    name = ShortNameH1(name)
    local key = NameKeyH1(name)
    if key == "" then return nil end
    local treasury = self:EnsureTreasuryDonorTotalsH1()
    if not treasury then return nil end
    local old = treasury.donorTotalsR5[key]
    total = math.max(0, math.min(2000000000, math.floor(tonumber(total) or 0)))
    updatedAt = math.max(0, math.floor(tonumber(updatedAt) or self:Now()))
    if old and (tonumber(old.updatedAt) or 0) > updatedAt then return old end
    treasury.donorTotalsR5[key] = { name=name, total=total, actor=SafeH1(actor or "Leadership", 28), updatedAt=updatedAt }
    return treasury.donorTotalsR5[key]
end

function OTLGM:AddTreasuryDonorAmountH1(name, amount, actor, updatedAt)
    name = ShortNameH1(name)
    local key = NameKeyH1(name)
    if key == "" then return nil end
    local treasury = self:EnsureTreasuryDonorTotalsH1()
    if not treasury then return nil end
    local old = treasury.donorTotalsR5[key]
    local total = math.min(2000000000, math.max(0, tonumber(old and old.total) or 0) + math.max(0, math.floor(tonumber(amount) or 0)))
    return self:SetTreasuryDonorTotalH1(name, total, actor, updatedAt)
end

function OTLGM:EvaluateTreasuryDonorAchievementsH1(explicitTotal)
    RegisterDonorAchievementsH1()
    if not self.EnsureAchievements174 or not self.CompleteAchievement174 then return false end
    local player = ShortNameH1(UnitName and UnitName("player") or "")
    if player == "" then return false end
    local total = tonumber(explicitTotal)
    if total == nil then
        local treasury = self:EnsureTreasuryDonorTotalsH1()
        local row = treasury and treasury.donorTotalsR5 and treasury.donorTotalsR5[NameKeyH1(player)]
        total = tonumber(row and row.total) or 0
    end
    total = math.max(0, math.floor(total or 0))
    local gold = math.floor(total / 10000)
    local db = self:EnsureAchievements174()
    if not db then return false end
    db.counters.treasuryDonatedGoldR5 = math.max(tonumber(db.counters.treasuryDonatedGoldR5) or 0, gold)
    local index, def
    for index = 1, table.getn(DONOR_ACHIEVEMENTS_H1) do
        def = DONOR_ACHIEVEMENTS_H1[index]
        if total >= (def.required * 10000) then self:CompleteAchievement174(def.id, false) end
    end
    H1.donorEvaluations = H1.donorEvaluations + 1
    return true
end

local function QueueDonorTotalH1(self, name, total, target)
    if not self.QueueNetworkPayload then return false end
    name = ShortNameH1(name)
    target = target and ShortNameH1(target) or nil
    if name == "" then return false end
    local actor = ShortNameH1(UnitName and UnitName("player") or "Leadership")
    local payload = table.concat({ self.treasuryProtocol170 or "B1", "DONOR", SafeH1(name, 28), tostring(math.floor(tonumber(total) or 0)), tostring(self:Now()), SafeH1(actor, 28) }, "^")
    local channel = target and "WHISPER" or "GUILD"
    local queued = self:QueueNetworkPayload(payload, channel, target, target and 3 or 2, "treasury", "treasury:donor:" .. NameKeyH1(target or name))
    if queued then H1.donorMessages = H1.donorMessages + 1 end
    return queued
end

local BaseAddContributionH1 = OTLGM.AddTreasuryContribution176
if BaseAddContributionH1 then
    function OTLGM:AddTreasuryContribution176(goalId, contributor, amountCopper, note)
        -- Migrate the old ledger before the new entry is inserted, otherwise the
        -- first post-upgrade contribution would be counted once by migration and
        -- a second time by the incremental update below.
        self:EnsureTreasuryDonorTotalsH1()
        local ok, result = BaseAddContributionH1(self, goalId, contributor, amountCopper, note)
        if not ok or not result then return ok, result end
        local donor = self:AddTreasuryDonorAmountH1(result.contributor or contributor, result.amount or amountCopper, result.actor, result.ts)
        if donor then
            QueueDonorTotalH1(self, donor.name, donor.total, nil)
            if NameKeyH1(donor.name) == NameKeyH1(UnitName and UnitName("player") or "") then self:EvaluateTreasuryDonorAchievementsH1(donor.total) end
        end
        return ok, result
    end
end

local BaseHandleTreasuryH1 = OTLGM.HandleTreasuryMessage170
if BaseHandleTreasuryH1 then
    function OTLGM:HandleTreasuryMessage170(message, channel, sender)
        local fields = self:Split(message or "", "^")
        local kind = fields[2] or ""
        if fields[1] == (self.treasuryProtocol170 or "B1") and kind == "DONOR" then
            if self.IsPveLeadershipName and self:IsPveLeadershipName(sender) == false then return true end
            local donorName = ShortNameH1(fields[3] or "")
            local total = math.max(0, math.floor(tonumber(fields[4]) or 0))
            local updatedAt = math.max(0, math.floor(tonumber(fields[5]) or self:Now()))
            local actor = SafeH1(fields[6] or sender or "Leadership", 28)
            self:SetTreasuryDonorTotalH1(donorName, total, actor, updatedAt)
            if NameKeyH1(donorName) == NameKeyH1(UnitName and UnitName("player") or "") then self:EvaluateTreasuryDonorAchievementsH1(total) end
            return true
        end
        local seenBefore = false
        local entryId = ""
        if kind == "CONTRIB" then
            self:EnsureTreasuryDonorTotalsH1()
            entryId = SafeH1(fields[4] or "", 48)
            local treasury = self:EnsureTreasury170()
            seenBefore = treasury and treasury.contributionSeen176 and treasury.contributionSeen176[entryId] and true or false
        end
        local handled = BaseHandleTreasuryH1(self, message, channel, sender)
        if handled and kind == "CONTRIB" and not seenBefore then
            local donorName = ShortNameH1(fields[7] or "")
            local amount = math.max(0, math.floor(tonumber(fields[8]) or 0))
            local donor = self:AddTreasuryDonorAmountH1(donorName, amount, fields[6] or sender, tonumber(fields[5]) or self:Now())
            if donor and NameKeyH1(donor.name) == NameKeyH1(UnitName and UnitName("player") or "") then self:EvaluateTreasuryDonorAchievementsH1(donor.total) end
        elseif handled and kind == "END" then
            self:EvaluateTreasuryDonorAchievementsH1()
        end
        return handled
    end
end

local BaseQueueTreasuryStateH1 = OTLGM.QueueTreasuryState170
if BaseQueueTreasuryStateH1 then
    function OTLGM:QueueTreasuryState170(target)
        local result = BaseQueueTreasuryStateH1(self, target)
        if not result or not target or target == "" then return result end
        local treasury = self:EnsureTreasuryDonorTotalsH1()
        local donor = treasury and treasury.donorTotalsR5 and treasury.donorTotalsR5[NameKeyH1(target)]
        if donor then QueueDonorTotalH1(self, donor.name, donor.total, target) end
        return result
    end
end

-- ---------------------------------------------------------------------------
-- Treasury UI: direct buttons on every goal, current class/rank metadata and
-- stronger hover feedback. Work runs only while the Treasury UI is visible.
-- ---------------------------------------------------------------------------

local function EnsureGoalButtonsH1(self)
    local ui = self.ui and self.ui.treasury170
    if not ui or not ui.rows then return end
    local index, row
    for index = 1, table.getn(ui.rows) do
        row = ui.rows[index]
        if row and not row.ledgerButtonH1 then
            if row.name then row.name:SetWidth(176) end
            if row.amount then
                row.amount:ClearAllPoints()
                row.amount:SetPoint("TOPLEFT", row, "TOPLEFT", 188, -9)
                row.amount:SetWidth(108)
            end
            if row.meta then row.meta:SetWidth(284) end
            if row.progressBack then row.progressBack:SetWidth(286) end
            row.ledgerButtonH1 = ButtonH1(row, "Ledger", 302, -6, 58, 23, function(button)
                local goal = button.goalH1
                if not goal then return end
                OTLGM.ui.treasury170.selected = goal.id
                OTLGM:OpenTreasuryGoalLedgerR5(goal.id)
            end, "utility")
            row.addButtonH1 = ButtonH1(row, "+ Gold", 364, -6, 56, 23, function(button)
                local goal = button.goalH1
                if not goal then return end
                OTLGM.ui.treasury170.selected = goal.id
                OTLGM:OpenTreasuryContributionDialog176()
            end, "confirm")
            H1.goalButtonsBuilt = H1.goalButtonsBuilt + 2
        end
    end
end

local BaseBuildTreasuryPageH1 = OTLGM.BuildTreasuryPage170
if BaseBuildTreasuryPageH1 then
    function OTLGM:BuildTreasuryPage170(page)
        local result = BaseBuildTreasuryPageH1(self, page)
        EnsureGoalButtonsH1(self)
        return result
    end
end

local BaseRefreshTreasuryPageH1 = OTLGM.RefreshTreasuryPage170
if BaseRefreshTreasuryPageH1 then
    function OTLGM:RefreshTreasuryPage170(forceEditor)
        local result = BaseRefreshTreasuryPageH1(self, forceEditor)
        local ui = self.ui and self.ui.treasury170
        if not ui or not ui.rows then return result end
        EnsureGoalButtonsH1(self)
        local canEdit = self.CanEditTreasury170 and self:CanEditTreasury170()
        local index, row, goal, percentage
        for index = 1, table.getn(ui.rows) do
            row = ui.rows[index]
            goal = row and row.goal170
            if row and row.ledgerButtonH1 then
                row.ledgerButtonH1.goalH1 = goal
                row.addButtonH1.goalH1 = goal
                SetEnabledH1(row.ledgerButtonH1, goal ~= nil, "This funding goal is unavailable.")
                SetEnabledH1(row.addButtonH1, goal ~= nil and canEdit, "Only guild leadership can record contributions.")
                if goal and row.progress then
                    percentage = (tonumber(goal.target) or 0) > 0 and math.min(1, (tonumber(goal.current) or 0) / goal.target) or 0
                    if row.progressBack then row.progressBack:SetWidth(286) end
                    row.progress:SetWidth(math.max(1, math.floor(286 * percentage)))
                end
                if goal then row.ledgerButtonH1:Show() row.addButtonH1:Show() else row.ledgerButtonH1:Hide() row.addButtonH1:Hide() end
            end
        end
        self:EvaluateTreasuryDonorAchievementsH1()
        return result
    end
end

local function RepairContributionDialogH1(self)
    local dialog = self.ui and self.ui.treasuryContributionDialog176
    if not dialog or dialog.repairedH1 then return end
    dialog.repairedH1 = true
    StyleModalH1(dialog)
    if dialog.add176 then
        dialog.add176:ClearAllPoints()
        dialog.add176:SetPoint("TOPLEFT", dialog, "TOPLEFT", 382, -144)
        dialog.add176:SetWidth(158)
        dialog.add176:SetHeight(36)
        SetButtonTextH1(dialog.add176, "Add Contribution")
    end
    if dialog.note176 then
        dialog.note176:ClearAllPoints()
        dialog.note176:SetPoint("TOPLEFT", dialog, "TOPLEFT", 18, -158)
        dialog.note176:SetWidth(346)
        dialog.note176:SetHeight(30)
    end
    dialog.contributorMetaH1 = TextH1(dialog, "GameFontNormalSmall", "", 246, -130, 294, "LEFT")
    dialog.contributorMetaH1:SetTextColor(0.68, 0.68, 0.64)
    dialog.helpH1 = TextH1(dialog, "GameFontNormalSmall", "Contributor identity is resolved from the current guild roster. Achievements are granted to the named donor, not the officer recording the entry.", 18, -388, 520, "LEFT")
    dialog.helpH1:SetTextColor(0.50, 0.58, 0.50)
    local previousTextChanged = dialog.contributor176 and dialog.contributor176:GetScript("OnTextChanged") or nil
    if dialog.contributor176 then
        dialog.contributor176:SetScript("OnTextChanged", function()
            if previousTextChanged then previousTextChanged() end
            if OTLGM and OTLGM.RefreshTreasuryContributorMetaH1 then OTLGM:RefreshTreasuryContributorMetaH1() end
        end)
    end
end

function OTLGM:RefreshTreasuryContributorMetaH1()
    local dialog = self.ui and self.ui.treasuryContributionDialog176
    if not dialog or not dialog.contributorMetaH1 then return end
    local name = dialog.contributor176 and dialog.contributor176:GetText() or ""
    if TrimH1(name) == "" then dialog.contributorMetaH1:SetText("Enter a current guild member name.")
    else
        local meta = self:GetTreasuryContributorMetaH1(name)
        if meta then
            dialog.contributorMetaH1:SetText(self:GetClassColor(meta.class) .. (meta.class ~= "" and meta.class or "Unknown class") .. self.colors.reset .. "  -  " .. tostring(meta.rank or "Guild member") .. (meta.level > 0 and ("  -  Lv " .. tostring(meta.level)) or ""))
        else dialog.contributorMetaH1:SetText("Not found in the current guild roster. The contribution can still be recorded.") end
    end
end

local BaseBuildContributionDialogH1 = OTLGM.BuildTreasuryContributionDialog176
if BaseBuildContributionDialogH1 then
    function OTLGM:BuildTreasuryContributionDialog176()
        local result = BaseBuildContributionDialogH1(self)
        RepairContributionDialogH1(self)
        return result
    end
end

local BaseRefreshContributionDialogH1 = OTLGM.RefreshTreasuryContributionDialog176
if BaseRefreshContributionDialogH1 then
    function OTLGM:RefreshTreasuryContributionDialog176()
        local result = BaseRefreshContributionDialogH1(self)
        RepairContributionDialogH1(self)
        self:RefreshTreasuryContributorMetaH1()
        local dialog = self.ui and self.ui.treasuryContributionDialog176
        local ui = self.ui and self.ui.treasury170
        local goalId = ui and ui.selected
        local entries = goalId and self:GetTreasuryContributions176(goalId) or {}
        local index, entry, meta, note, identity
        for index = 1, table.getn(dialog and dialog.rows176 or {}) do
            entry = entries[index]
            if entry then
                meta = ContributorMetaTextH1(self, entry.contributor, true)
                note = entry.note and entry.note ~= "" and ("  -  " .. entry.note) or ""
                identity = ColoredContributorNameH1(self, entry.contributor)
                dialog.rows176[index]:SetText(date("%d %b %H:%M", entry.ts or self:Now()) .. "  " .. identity .. "  +" .. tostring(math.floor((tonumber(entry.amount) or 0) / 10000)) .. "g  [" .. meta .. "]  by " .. tostring(entry.actor or "Leadership") .. note)
            end
        end
        return result
    end
end

local BaseOpenContributionDialogH1 = OTLGM.OpenTreasuryContributionDialog176
if BaseOpenContributionDialogH1 then
    function OTLGM:OpenTreasuryContributionDialog176()
        local result = BaseOpenContributionDialogH1(self)
        RepairContributionDialogH1(self)
        local dialog = self.ui and self.ui.treasuryContributionDialog176
        if dialog and dialog:IsVisible() then self:OpenExclusiveModalR5(dialog) end
        return result
    end
end

local function RepairWhisperDialogH1(self)
    local dialog = self.ui and self.ui.recentWhisperDialog176
    if not dialog or dialog.repairedH1 then return end
    dialog.repairedH1 = true
    StyleModalH1(dialog)
    local index, row
    for index = 1, table.getn(dialog.rows176 or {}) do
        row = dialog.rows176[index]
        if row then
            row:EnableMouse(true)
            row:SetScript("OnEnter", function()
                this:SetBackdropColor(0.06, 0.055, 0.04, 1)
                this:SetBackdropBorderColor(0.68, 0.46, 0.16, 1)
            end)
            row:SetScript("OnLeave", function()
                this:SetBackdropColor(0.018, 0.019, 0.021, 1)
                this:SetBackdropBorderColor(0.28, 0.24, 0.17, 1)
            end)
            row:SetBackdropColor(0.018, 0.019, 0.021, 1)
            row:SetBackdropBorderColor(0.28, 0.24, 0.17, 1)
        end
    end
end

local BaseBuildWhisperDialogH1 = OTLGM.BuildRecentWhisperDialog176
if BaseBuildWhisperDialogH1 then
    function OTLGM:BuildRecentWhisperDialog176()
        local result = BaseBuildWhisperDialogH1(self)
        RepairWhisperDialogH1(self)
        return result
    end
end

local BaseOpenWhisperDialogH1 = OTLGM.OpenRecentWhispers176
if BaseOpenWhisperDialogH1 then
    function OTLGM:OpenRecentWhispers176()
        local result = BaseOpenWhisperDialogH1(self)
        RepairWhisperDialogH1(self)
        local dialog = self.ui and self.ui.recentWhisperDialog176
        if dialog and dialog:IsVisible() then self:OpenExclusiveModalR5(dialog) end
        return result
    end
end

local function RepairLedgerRowsH1(self)
    local dialog = self.ui and self.ui.treasuryLedgerDialogR5
    if not dialog or dialog.repairedH1 then return end
    dialog.repairedH1 = true
    StyleModalH1(dialog)
    local index, row
    for index = 1, table.getn(dialog.summaryRowsR5 or {}) do
        row = dialog.summaryRowsR5[index]
        if row then
            row:EnableMouse(true)
            row:SetScript("OnEnter", function()
                this:SetBackdropColor(0.065, 0.055, 0.035, 1)
                this:SetBackdropBorderColor(0.78, 0.52, 0.17, 1)
            end)
            row:SetScript("OnLeave", function()
                this:SetBackdropColor(0.018, 0.019, 0.020, 1)
                this:SetBackdropBorderColor(0.28, 0.24, 0.17, 1)
            end)
            row:SetBackdropColor(0.018, 0.019, 0.020, 1)
        end
    end
    for index = 1, table.getn(dialog.entryRowsR5 or {}) do
        row = dialog.entryRowsR5[index]
        if row then
            row:EnableMouse(true)
            row:SetScript("OnEnter", function()
                this:SetBackdropColor(0.055, 0.050, 0.038, 1)
                this:SetBackdropBorderColor(0.62, 0.43, 0.16, 1)
            end)
            row:SetScript("OnLeave", function()
                this:SetBackdropColor(0.016, 0.017, 0.019, 1)
                this:SetBackdropBorderColor(0.25, 0.22, 0.17, 1)
            end)
            row:SetBackdropColor(0.016, 0.017, 0.019, 1)
        end
    end
end

local BaseBuildLedgerH1 = OTLGM.BuildTreasuryGoalLedgerR5
if BaseBuildLedgerH1 then
    function OTLGM:BuildTreasuryGoalLedgerR5()
        local result = BaseBuildLedgerH1(self)
        RepairLedgerRowsH1(self)
        return result
    end
end

local BaseRefreshLedgerH1 = OTLGM.RefreshTreasuryGoalLedgerR5
if BaseRefreshLedgerH1 then
    function OTLGM:RefreshTreasuryGoalLedgerR5()
        local result = BaseRefreshLedgerH1(self)
        RepairLedgerRowsH1(self)
        local dialog = self.ui and self.ui.treasuryLedgerDialogR5
        if not dialog then return result end
        local ledger = self:GetTreasuryGoalLedgerR5(dialog.goalIdR5)
        local index, row, contributor, entry, meta, note
        for index = 1, table.getn(dialog.summaryRowsR5 or {}) do
            row = dialog.summaryRowsR5[index]
            contributor = ledger.contributors[(tonumber(dialog.summaryOffsetR5) or 0) + index]
            if row and contributor then
                row.nameR5:SetText(ColoredContributorNameH1(self, contributor.name))
                row.countR5:SetText(ContributorMetaTextH1(self, contributor.name, true) .. "  -  " .. tostring(contributor.count) .. " entr" .. (contributor.count == 1 and "y" or "ies"))
            end
        end
        for index = 1, table.getn(dialog.entryRowsR5 or {}) do
            row = dialog.entryRowsR5[index]
            entry = ledger.entries[(tonumber(dialog.offsetR5) or 0) + index]
            if row and entry then
                meta = ContributorMetaTextH1(self, entry.contributor, true)
                note = entry.note and entry.note ~= "" and (" - " .. entry.note) or ""
                row.textR5:SetText(date("%d %b %H:%M", entry.ts or self:Now()) .. "  " .. ColoredContributorNameH1(self, entry.contributor) .. "  +" .. tostring(math.floor((tonumber(entry.amount) or 0) / 10000)) .. "g  [" .. meta .. "]  by " .. tostring(entry.actor or "Leadership") .. note)
            end
        end
        return result
    end
end

local BaseOpenLedgerH1 = OTLGM.OpenTreasuryGoalLedgerR5
if BaseOpenLedgerH1 then
    function OTLGM:OpenTreasuryGoalLedgerR5(goalId)
        local result = BaseOpenLedgerH1(self, goalId)
        if result then
            RepairLedgerRowsH1(self)
            local dialog = self.ui and self.ui.treasuryLedgerDialogR5
            if dialog then self:OpenExclusiveModalR5(dialog) end
        end
        return result
    end
end

local function RepairActivityRowsH1(self)
    local dialog = self.ui and self.ui.treasuryActivityDialogR5
    if not dialog or dialog.repairedH1 then return end
    dialog.repairedH1 = true
    StyleModalH1(dialog)
    local index, row
    for index = 1, table.getn(dialog.rowsR5 or {}) do
        row = dialog.rowsR5[index]
        if row then
            row:EnableMouse(true)
            row:SetScript("OnEnter", function()
                this:SetBackdropColor(0.055, 0.050, 0.038, 1)
                this:SetBackdropBorderColor(0.64, 0.44, 0.16, 1)
            end)
            row:SetScript("OnLeave", function()
                this:SetBackdropColor(0.016, 0.017, 0.019, 1)
                this:SetBackdropBorderColor(0.25, 0.22, 0.17, 1)
            end)
            row:SetBackdropColor(0.016, 0.017, 0.019, 1)
        end
    end
end

local BaseBuildActivityH1 = OTLGM.BuildTreasuryActivityR5
if BaseBuildActivityH1 then
    function OTLGM:BuildTreasuryActivityR5()
        local result = BaseBuildActivityH1(self)
        RepairActivityRowsH1(self)
        return result
    end
end

local BaseOpenActivityH1 = OTLGM.OpenTreasuryActivityR5
if BaseOpenActivityH1 then
    function OTLGM:OpenTreasuryActivityR5()
        local result = BaseOpenActivityH1(self)
        RepairActivityRowsH1(self)
        local dialog = self.ui and self.ui.treasuryActivityDialogR5
        if dialog and dialog:IsVisible() then self:OpenExclusiveModalR5(dialog) end
        return result
    end
end

local BaseBuildUIH1 = OTLGM.BuildUI
if BaseBuildUIH1 then
    function OTLGM:BuildUI()
        local result = BaseBuildUIH1(self)
        RegisterDonorAchievementsH1()
        EnsureGoalButtonsH1(self)
        RepairWhisperDialogH1(self)
        RepairContributionDialogH1(self)
        RepairLedgerRowsH1(self)
        RepairActivityRowsH1(self)
        return result
    end
end

SlashCmdList = SlashCmdList or {}
SLASH_OTLGMHOTFIX1 = "/otlh1"
SlashCmdList["OTLGMHOTFIX"] = function()
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("OTL R5 hotfix 1: modal repairs=" .. tostring(H1.modalRepairs) .. ", donor evaluations=" .. tostring(H1.donorEvaluations) .. ", donor packets=" .. tostring(H1.donorMessages) .. ", goal buttons=" .. tostring(H1.goalButtonsBuilt))
    end
end

OTLGM:RegisterModule("Release176R5Hotfix", {
    layer = "release",
    version = "1.7.6",
    build = OTLGM.build,
    noOnUpdate = true,
    modalScope = "addon-window",
    donorAchievements = 4,
})
