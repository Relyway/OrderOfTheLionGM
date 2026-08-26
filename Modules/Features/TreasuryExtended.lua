-- Order of the Lion Guild Manager v1.7.6 R5 hotfix 1
-- Modal interaction, Treasury goal actions, contributor roster metadata and
-- donor achievements. No OnUpdate handler and no background roster scan.

if not OTLGM then return end

OTLGM.legacyVersionRelease176R5Hotfix = "1.7.6"
OTLGM.legacyBuildRelease176R5Hotfix = "performance-r5-hotfix1-20260726"

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

local function DisplayActorR8(value)
    local raw = tostring(value or "Leadership")
    local lower = string.lower(raw)
    local dash = string.find(lower, "-", 1, true)
    local short = dash and string.sub(lower, 1, dash - 1) or lower
    if short == "morrow" then return "Lucks" end
    return raw
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

local PreviousOpenExclusiveModalH1 = OTLGM.__impl180.OpenExclusiveModalR5__impl1
if PreviousOpenExclusiveModalH1 then
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
        self.runtime = self.runtime or {}
        self.runtime.treasuryDataRevisionRC5R3 = (tonumber(self.runtime.treasuryDataRevisionRC5R3) or 0) + 1
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
    self.runtime = self.runtime or {}
    self.runtime.treasuryDataRevisionRC5R3 = (tonumber(self.runtime.treasuryDataRevisionRC5R3) or 0) + 1
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

local function AddTreasuryUsefulActivityC8(owner, entry, goalName)
    if not owner or not entry or not owner.AddUsefulActivity152 then return false end
    owner.runtime = owner.runtime or {}
    owner.runtime.treasuryUsefulSeenC8 = owner.runtime.treasuryUsefulSeenC8 or {}
    local key = tostring(entry.id or "")
    if key == "" or owner.runtime.treasuryUsefulSeenC8[key] then return false end
    owner.runtime.treasuryUsefulSeenC8[key] = true
    local copper = math.max(0, tonumber(entry.amount) or 0)
    local gold = math.floor(copper / 10000)
    local silver = math.floor(math.mod(copper, 10000) / 100)
    local copperOnly = math.mod(copper, 100)
    local amountText
    if gold > 0 then amountText = tostring(gold) .. "g" .. (silver > 0 and (" " .. tostring(silver) .. "s") or "")
    elseif silver > 0 then amountText = tostring(silver) .. "s" .. (copperOnly > 0 and (" " .. tostring(copperOnly) .. "c") or "")
    else amountText = tostring(copperOnly) .. "c" end
    local contributor = ShortNameH1(entry.contributor or "Anonymous")
    owner:AddUsefulActivity152("TREASURY", contributor .. " donated " .. amountText .. " to the Guild Treasury.", SafeH1(goalName or "Guild Treasury", 48), "treasury", tonumber(entry.ts) or owner:Now(), "TREASURY:" .. key)
    return true
end

local PreviousAddContributionH1 = OTLGM.__impl180.AddTreasuryContribution176__impl2
if PreviousAddContributionH1 then
    function OTLGM:AddTreasuryContribution176(goalId, contributor, amountCopper, note)
        -- Migrate the old ledger before the new entry is inserted, otherwise the
        -- first post-upgrade contribution would be counted once by migration and
        -- a second time by the incremental update below.
        self:EnsureTreasuryDonorTotalsH1()
        local ok, result = PreviousAddContributionH1(self, goalId, contributor, amountCopper, note)
        if not ok or not result then return ok, result end
        local donor = self:AddTreasuryDonorAmountH1(result.contributor or contributor, result.amount or amountCopper, result.actor, result.ts)
        if donor then
            QueueDonorTotalH1(self, donor.name, donor.total, nil)
            if NameKeyH1(donor.name) == NameKeyH1(UnitName and UnitName("player") or "") then self:EvaluateTreasuryDonorAchievementsH1(donor.total) end
        end
        local goal = self.GetTreasuryGoal170 and self:GetTreasuryGoal170(goalId) or nil
        AddTreasuryUsefulActivityC8(self, result, goal and goal.name or "Guild Treasury")
        return ok, result
    end
end

local PreviousHandleTreasuryH1 = OTLGM.__impl180.HandleTreasuryMessage170__impl3
if PreviousHandleTreasuryH1 then
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
        local handled = PreviousHandleTreasuryH1(self, message, channel, sender)
        if handled and kind == "CONTRIB" and not seenBefore then
            local donorName = ShortNameH1(fields[7] or "")
            local amount = math.max(0, math.floor(tonumber(fields[8]) or 0))
            local donor = self:AddTreasuryDonorAmountH1(donorName, amount, fields[6] or sender, tonumber(fields[5]) or self:Now())
            if donor and NameKeyH1(donor.name) == NameKeyH1(UnitName and UnitName("player") or "") then self:EvaluateTreasuryDonorAchievementsH1(donor.total) end
            -- Only a live guild contribution becomes quiet Recent Activity.
            -- WHISPER packets are state replay during sync and must never flood
            -- Home with historical donations.
            if channel == "GUILD" then
                local goalId = SafeH1(fields[3] or "", 32)
                local entryId = SafeH1(fields[4] or "", 48)
                local entries = self.GetTreasuryContributions176 and self:GetTreasuryContributions176(goalId) or {}
                local entry, index
                for index = 1, table.getn(entries) do if entries[index].id == entryId then entry = entries[index] break end end
                local goal = self.GetTreasuryGoal170 and self:GetTreasuryGoal170(goalId) or nil
                if entry then AddTreasuryUsefulActivityC8(self, entry, goal and goal.name or "Guild Treasury") end
            end
        elseif handled and kind == "END" then
            local acceptedAt = self.runtime and tonumber(self.runtime.lastTreasuryEndAcceptedR13) or 0
            if acceptedAt > 0 and self:Now() - acceptedAt <= 1 then self:EvaluateTreasuryDonorAchievementsH1() end
        end
        return handled
    end
end

local PreviousQueueTreasuryStateH1 = OTLGM.__impl180.QueueTreasuryState170__impl2
if PreviousQueueTreasuryStateH1 then
    function OTLGM:QueueTreasuryState170(target)
        local result = PreviousQueueTreasuryStateH1(self, target)
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

local function MoneyCompactH1(copper)
    copper = math.max(0, math.floor(tonumber(copper) or 0))
    local gold = math.floor(copper / 10000)
    local silver = math.floor(math.mod(copper, 10000) / 100)
    local coins = math.mod(copper, 100)
    if gold > 0 then
        if silver > 0 then return tostring(gold) .. "g " .. tostring(silver) .. "s" end
        return tostring(gold) .. "g"
    end
    if silver > 0 then return tostring(silver) .. "s " .. tostring(coins) .. "c" end
    return tostring(coins) .. "c"
end

local function EnsureTreasuryContributorSummaryH1(self)
    local ui = self.ui and self.ui.treasury170
    if not ui or not ui.detail or ui.contributorSummaryH1 then return end

    -- The server-adapter implementation detail used to occupy the most visible
    -- part of the Treasury page. Players care about the goal and its donors,
    -- so keep adapter detection internal and use this space for useful data.
    if ui.serverTitle then ui.serverTitle:Hide() end
    if ui.serverState then ui.serverState:Hide() end
    if ui.detect then ui.detect:Hide() end

    local panel = ui.detail
    ui.contributorSummaryH1 = CreateFrame("Frame", nil, panel)
    ui.contributorSummaryH1:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -7)
    ui.contributorSummaryH1:SetWidth(244)
    ui.contributorSummaryH1:SetHeight(118)
    BackdropH1(ui.contributorSummaryH1, 8)
    if ui.contributorSummaryH1.SetBackdropColor then ui.contributorSummaryH1:SetBackdropColor(0.025, 0.022, 0.016, 0.96) end
    if ui.contributorSummaryH1.SetBackdropBorderColor then ui.contributorSummaryH1:SetBackdropBorderColor(0.38, 0.27, 0.10, 0.95) end

    ui.contributorIcon184 = ui.contributorSummaryH1:CreateTexture(nil, "ARTWORK")
    ui.contributorIcon184:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
    ui.contributorIcon184:SetWidth(17) ui.contributorIcon184:SetHeight(17)
    ui.contributorIcon184:SetPoint("TOPLEFT", ui.contributorSummaryH1, "TOPLEFT", 8, -7)
    if ui.contributorIcon184.SetTexCoord then ui.contributorIcon184:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    ui.contributorTitleH1 = TextH1(ui.contributorSummaryH1, "GameFontNormalSmall", "TOP CONTRIBUTORS", 31, -8, 110, "LEFT")
    ui.contributorTitleH1:SetTextColor(1.0, 0.78, 0.25)
    ui.contributorGoalH1 = TextH1(ui.contributorSummaryH1, "GameFontNormalSmall", "Select a funding goal", 31, -25, 108, "LEFT")
    ui.contributorGoalH1:SetTextColor(0.70, 0.70, 0.67)
    ui.contributorRowsH1 = {}
    local index
    for index = 1, 5 do
        local row = CreateFrame("Frame", nil, ui.contributorSummaryH1)
        row:SetPoint("TOPLEFT", ui.contributorSummaryH1, "TOPLEFT", 8, -41 - ((index - 1) * 19))
        row:SetWidth(228)
        row:SetHeight(18)
        row.rank = TextH1(row, "GameFontNormalSmall", tostring(index) .. ".", 1, -1, 18, "LEFT")
        row.rank:SetTextColor(0.55, 0.55, 0.52)
        row.name = TextH1(row, "GameFontNormalSmall", "", 21, -1, 133, "LEFT")
        row.amount = TextH1(row, "GameFontNormalSmall", "", 154, -1, 72, "RIGHT")
        row.amount:SetTextColor(1.0, 0.72, 0.20)
        ui.contributorRowsH1[index] = row
    end
    ui.fullLedgerH1 = ButtonH1(ui.contributorSummaryH1, "Full Ledger", 143, -14, 92, 24, function()
        local treasuryUI = OTLGM.ui and OTLGM.ui.treasury170
        if treasuryUI and treasuryUI.selected then OTLGM:OpenTreasuryGoalLedgerR5(treasuryUI.selected) end
    end, "utility")
    ui.contributorStatusH1 = TextH1(ui.contributorSummaryH1, "GameFontNormalSmall", "", 8, -97, 226, "LEFT")
    ui.contributorStatusH1:SetTextColor(0.62, 0.62, 0.58)
end

local function FundingPercentH1(current, target)
    current, target = math.max(0, tonumber(current) or 0), math.max(0, tonumber(target) or 0)
    if target <= 0 then return "0%" end
    local ratio = current / target
    if ratio > 0 and ratio < 0.01 then return "<1%" end
    return tostring(math.floor((ratio * 100) + 0.5)) .. "%"
end

local function RefreshTreasuryContributorSummaryH1(self)
    local ui = self.ui and self.ui.treasury170
    if not ui then return end
    EnsureTreasuryContributorSummaryH1(self)
    if not ui.contributorSummaryH1 then return end
    local goal = ui.selected and self.GetTreasuryGoal170 and self:GetTreasuryGoal170(ui.selected) or nil
    local ledger = goal and self.GetTreasuryGoalLedgerR5 and self:GetTreasuryGoalLedgerR5(goal.id) or nil
    if goal then
        local current = math.max(0, tonumber(goal.current) or 0)
        local target = math.max(0, tonumber(goal.target) or 0)
        local percentText = FundingPercentH1(current, target)
        ui.contributorGoalH1:SetText(SafeH1(goal.name or "Funding goal", 22) .. "  •  " .. percentText .. " funded")
        if ui.contributorStatusH1 then
            local contributorCount = table.getn(ledger and ledger.contributors or {})
            local entryCount = table.getn(ledger and ledger.entries or {})
            local lastText = "no contributions yet"
            if ledger and (tonumber(ledger.lastAt) or 0) > 0 then
                local clock = self.FormatServerClock180 and self:FormatServerClock180(ledger.lastAt, false) or date("%H:%M", ledger.lastAt)
                lastText = "last " .. tostring(clock) .. " ST"
            end
            ui.contributorStatusH1:SetText(tostring(contributorCount) .. " contributor" .. (contributorCount == 1 and "" or "s")
                .. "  •  " .. tostring(entryCount) .. " contribution" .. (entryCount == 1 and "" or "s") .. "  •  " .. lastText)
        end
    else
        ui.contributorGoalH1:SetText("Select a funding goal")
        if ui.contributorStatusH1 then ui.contributorStatusH1:SetText("Pick a goal to review donors and the full ledger.") end
    end
    SetEnabledH1(ui.fullLedgerH1, goal ~= nil, "Select a funding goal first.")
    local contributors = ledger and ledger.contributors or {}
    local visibleRows = math.max(3, math.min(5, tonumber(ui.contributorVisibleRowsR25) or 3))
    local index, contributor, row
    for index = 1, 5 do
        row = ui.contributorRowsH1[index]
        contributor = index <= visibleRows and contributors[index] or nil
        if contributor then
            row.rank:SetText(tostring(index) .. ".")
            row.name:SetTextColor(1, 1, 1)
            row.name:SetText(ColoredContributorNameH1(self, SafeH1(contributor.name or "Anonymous", 24)))
            row.amount:SetText(MoneyCompactH1(contributor.amount))
            row:Show()
        elseif index == 1 and goal then
            row.rank:SetText("")
            row.name:SetText("No contributions recorded yet")
            row.name:SetTextColor(0.62, 0.62, 0.59)
            row.amount:SetText("")
            row:Show()
        else
            row:Hide()
        end
    end
end

local function EnsureGoalButtonsH1(self)
    local ui = self.ui and self.ui.treasury170
    if not ui or not ui.rows then return end
    local index, row
    for index = 1, table.getn(ui.rows) do
        row = ui.rows[index]
        if row and not row.ledgerButtonH1 then
            if not row.goalIconH1 then
                row.goalIconH1 = row:CreateTexture(nil, "ARTWORK")
                row.goalIconH1:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -8)
                row.goalIconH1:SetWidth(24)
                row.goalIconH1:SetHeight(24)
                row.goalIconH1:SetTexture("Interface\\Icons\\INV_Misc_Coin_05")
            end
            if row.name then
                row.name:ClearAllPoints()
                row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 42, -8)
                row.name:SetWidth(138)
            end
            if row.amount then
                row.amount:ClearAllPoints()
                row.amount:SetPoint("TOPLEFT", row, "TOPLEFT", 188, -9)
                row.amount:SetWidth(108)
            end
            if row.meta then
                row.meta:ClearAllPoints()
                row.meta:SetPoint("TOPLEFT", row, "TOPLEFT", 42, -30)
                row.meta:SetWidth(244)
            end
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

local PreviousBuildTreasuryPageH1 = OTLGM.__impl180.BuildTreasuryPage170__impl4
if PreviousBuildTreasuryPageH1 then
    function OTLGM:BuildTreasuryPage170(page)
        local result = PreviousBuildTreasuryPageH1(self, page)
        EnsureGoalButtonsH1(self)
        EnsureTreasuryContributorSummaryH1(self)
        return result
    end
end

local PreviousRefreshTreasuryPageH1 = OTLGM.__impl180.RefreshTreasuryPage170__impl5
if PreviousRefreshTreasuryPageH1 then
    function OTLGM:RefreshTreasuryPage170(forceEditor)
        local result = PreviousRefreshTreasuryPageH1(self, forceEditor)
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
                    local progressWidth = math.max(1, tonumber(row.otlTreasuryProgressWidth184) or 286)
                    if row.progressBack then row.progressBack:SetWidth(progressWidth) end
                    row.progress:SetWidth(math.max(1, math.floor(progressWidth * percentage)))
                end
                if goal then
                    row.ledgerButtonH1:Show()
                    row.addButtonH1:Show()
                    if row.goalIconH1 then row.goalIconH1:Show() end
                else
                    row.ledgerButtonH1:Hide()
                    row.addButtonH1:Hide()
                    if row.goalIconH1 then row.goalIconH1:Hide() end
                end
            end
        end
        RefreshTreasuryContributorSummaryH1(self)
        self:EvaluateTreasuryDonorAchievementsH1()
        return result
    end
end

local function RepairContributionDialogH1(self)
    local dialog = self.ui and self.ui.treasuryContributionDialog176
    if not dialog or dialog.repairedH1 then return end
    dialog.repairedH1 = true
    StyleModalH1(dialog)
    dialog.goalStatusH1 = TextH1(dialog, "GameFontNormalSmall", "", 18, -48, 260, "LEFT")
    dialog.goalStatusH1:SetTextColor(1.0, 0.82, 0.28)
    dialog.goalProgressBackH1 = dialog:CreateTexture(nil, "BACKGROUND")
    dialog.goalProgressBackH1:SetPoint("TOPLEFT", dialog, "TOPLEFT", 18, -72)
    dialog.goalProgressBackH1:SetWidth(230) dialog.goalProgressBackH1:SetHeight(7)
    dialog.goalProgressBackH1:SetTexture(0.10, 0.08, 0.05, 1)
    dialog.goalProgressFillH1 = dialog:CreateTexture(nil, "ARTWORK")
    dialog.goalProgressFillH1:SetPoint("TOPLEFT", dialog.goalProgressBackH1, "TOPLEFT", 0, 0)
    dialog.goalProgressFillH1:SetHeight(7)
    dialog.goalProgressFillH1:SetTexture(1.0, 0.78, 0.22, 1)
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
    local previousTextChanged = dialog.contributor176 and dialog.contributor176.otlChanged or nil
    if dialog.contributor176 then
        dialog.contributor176.otlChanged = function(value, field)
            if previousTextChanged then previousTextChanged(value, field) end
            if OTLGM and OTLGM.RefreshTreasuryContributorMetaH1 then OTLGM:RefreshTreasuryContributorMetaH1() end
        end
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

local PreviousBuildContributionDialogH1 = OTLGM.__impl180.BuildTreasuryContributionDialog176__impl1
if PreviousBuildContributionDialogH1 then
    function OTLGM:BuildTreasuryContributionDialog176()
        local result = PreviousBuildContributionDialogH1(self)
        RepairContributionDialogH1(self)
        return result
    end
end

local PreviousRefreshContributionDialogH1 = OTLGM.__impl180.RefreshTreasuryContributionDialog176__impl1
if PreviousRefreshContributionDialogH1 then
    function OTLGM:RefreshTreasuryContributionDialog176()
        local result = PreviousRefreshContributionDialogH1(self)
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
                dialog.rows176[index]:SetText(((self.FormatServerDate180 and self:FormatServerDate180(entry.ts or self:Now(), "%d %b") or date("%d %b", entry.ts or self:Now())) .. " " .. (self.FormatServerClock180 and self:FormatServerClock180(entry.ts or self:Now(), false) or date("%H:%M", entry.ts or self:Now())) .. " ST") .. "  " .. identity .. "  +" .. tostring(math.floor((tonumber(entry.amount) or 0) / 10000)) .. "g  [" .. meta .. "]  by " .. DisplayActorR8(entry.actor) .. note)
            end
        end
        return result
    end
end

local PreviousOpenContributionDialogH1 = OTLGM.__impl180.OpenTreasuryContributionDialog176__impl2
if PreviousOpenContributionDialogH1 then
    function OTLGM:OpenTreasuryContributionDialog176()
        local result = PreviousOpenContributionDialogH1(self)
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

local PreviousBuildWhisperDialogH1 = OTLGM.__impl180.BuildRecentWhisperDialog176__impl2
if PreviousBuildWhisperDialogH1 then
    function OTLGM:BuildRecentWhisperDialog176()
        local result = PreviousBuildWhisperDialogH1(self)
        RepairWhisperDialogH1(self)
        return result
    end
end

local PreviousOpenWhisperDialogH1 = OTLGM.__impl180.OpenRecentWhispers176__impl2
if PreviousOpenWhisperDialogH1 then
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

local PreviousBuildLedgerH1 = OTLGM.__impl180.BuildTreasuryGoalLedgerR5__impl1
if PreviousBuildLedgerH1 then
    function OTLGM:BuildTreasuryGoalLedgerR5()
        local result = PreviousBuildLedgerH1(self)
        RepairLedgerRowsH1(self)
        return result
    end
end

local PreviousRefreshLedgerH1 = OTLGM.__impl180.RefreshTreasuryGoalLedgerR5__impl1
if PreviousRefreshLedgerH1 then
    function OTLGM:RefreshTreasuryGoalLedgerR5()
        local result = PreviousRefreshLedgerH1(self)
        RepairLedgerRowsH1(self)
        local dialog = self.ui and self.ui.treasuryLedgerDialogR5
        if not dialog then return result end
        local ledger = self:GetTreasuryGoalLedgerR5(dialog.goalIdR5)
        local goal = self.GetTreasuryGoal170 and self:GetTreasuryGoal170(dialog.goalIdR5) or nil
        local index, row, contributor, entry, meta, note
        if dialog.goalStatusH1 and goal then
            local current = math.max(0, tonumber(goal.current) or 0)
            local target = math.max(0, tonumber(goal.target) or 0)
            local percentText = FundingPercentH1(current, target)
            dialog.goalStatusH1:SetText(MoneyCompactH1(current) .. " raised  •  " .. percentText .. " funded")
            if dialog.goalProgressFillH1 then dialog.goalProgressFillH1:SetWidth(math.max(1, math.floor(230 * math.min(1, target > 0 and (current / target) or 0)))) end
        elseif dialog.goalStatusH1 then
            dialog.goalStatusH1:SetText("")
            if dialog.goalProgressFillH1 then dialog.goalProgressFillH1:SetWidth(1) end
        end
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
                row.textR5:SetText(((self.FormatServerDate180 and self:FormatServerDate180(entry.ts or self:Now(), "%d %b") or date("%d %b", entry.ts or self:Now())) .. " " .. (self.FormatServerClock180 and self:FormatServerClock180(entry.ts or self:Now(), false) or date("%H:%M", entry.ts or self:Now())) .. " ST") .. "  " .. ColoredContributorNameH1(self, entry.contributor) .. "  +" .. tostring(math.floor((tonumber(entry.amount) or 0) / 10000)) .. "g  [" .. meta .. "]  by " .. DisplayActorR8(entry.actor) .. note)
            end
        end
        return result
    end
end

local PreviousOpenLedgerH1 = OTLGM.__impl180.OpenTreasuryGoalLedgerR5__impl1
if PreviousOpenLedgerH1 then
    function OTLGM:OpenTreasuryGoalLedgerR5(goalId)
        local result = PreviousOpenLedgerH1(self, goalId)
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

local PreviousBuildActivityH1 = OTLGM.__impl180.BuildTreasuryActivityR5__impl1
if PreviousBuildActivityH1 then
    function OTLGM:BuildTreasuryActivityR5()
        local result = PreviousBuildActivityH1(self)
        RepairActivityRowsH1(self)
        return result
    end
end

local PreviousOpenActivityH1 = OTLGM.__impl180.OpenTreasuryActivityR5__impl1
if PreviousOpenActivityH1 then
    function OTLGM:OpenTreasuryActivityR5()
        local result = PreviousOpenActivityH1(self)
        RepairActivityRowsH1(self)
        local dialog = self.ui and self.ui.treasuryActivityDialogR5
        if dialog and dialog:IsVisible() then self:OpenExclusiveModalR5(dialog) end
        return result
    end
end

OTLGM:RegisterModule("TreasuryExtended", {
    layer = "release",
    version = OTLGM.version or "1.8.0",
    build = OTLGM.build,
    noOnUpdate = true,
    modalScope = "addon-window",
    donorAchievements = 4,
})
