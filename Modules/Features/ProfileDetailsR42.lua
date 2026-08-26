-- Order of the Lion Guild Manager 1.8.3-r42
-- On-demand foreign achievement browser and member-specific profession routing.
-- No event frame, polling loop or passive full achievement broadcast.

if not OTLGM or not OTLGM.UI then return end
local UI = OTLGM.UI
local C = UI.colors
local ROWS_R42 = 9

local function N42(owner, value)
    if owner.NormalizeText then return owner:NormalizeText(value or "") end
    return string.lower(tostring(value or ""))
end

local function Short42(value, maximum)
    value = tostring(value or "") maximum = tonumber(maximum) or 70
    if string.len(value) <= maximum then return value end
    return string.sub(value, 1, math.max(1, maximum - 3)) .. "..."
end

local function Age42(owner, timestamp)
    timestamp = tonumber(timestamp) or 0
    if timestamp <= 0 then return "unknown" end
    local elapsed = math.max(0, owner:Now() - timestamp)
    if elapsed < 60 then return "just now" end
    if elapsed < 3600 then return tostring(math.floor(elapsed / 60)) .. "m ago" end
    if elapsed < 86400 then return tostring(math.floor(elapsed / 3600)) .. "h ago" end
    return tostring(math.floor(elapsed / 86400)) .. "d ago"
end

local function Date42(timestamp)
    timestamp = tonumber(timestamp) or 0
    if timestamp <= 0 then return nil end
    if date then
        local ok, value = pcall(date, "%d %b %Y", timestamp)
        if ok and value and value ~= "" then return tostring(value) end
    end
    return nil
end

local function RecentMap42(snapshot)
    local map, i, row = {}, nil, nil
    for i = 1, table.getn(snapshot and snapshot.recent or {}) do
        row = snapshot.recent[i]
        if row and row.id then map[row.id] = row end
    end
    return map
end

function OTLGM:BuildGuildMemberAchievementBrowserR42()
    self.ui = self.ui or {}
    if self.ui.memberAchievementBrowserR42 then return self.ui.memberAchievementBrowserR42 end
    if not self.ui.modalHost then return nil end
    local modal = UI:Modal(self.ui.modalHost, 720, 590)
    modal:SetPoint("CENTER", self.ui.modalHost, "CENTER", 0, 0)
    modal.otlDiagnosticName180 = "Member Achievements"
    modal.title = UI.Text(modal, "Member Achievements", "GameFontNormalLarge", "LEFT")
    modal.title:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -18) modal.title:SetWidth(430)
    modal.title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    modal.status = UI.Text(modal, "", "GameFontNormalSmall", "LEFT")
    modal.status:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -46) modal.status:SetWidth(540)
    modal.status:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    modal.refresh = UI:Button(modal, "Refresh", 92, 26, function()
        local name = modal.otlMemberNameR42
        if name and OTLGM.QueueGuildAchievementDetailRequestR42 then
            if OTLGM:QueueGuildAchievementDetailRequestR42(name, "manual") then
                modal.status:SetText("Request sent to " .. tostring(name) .. ". The list will update when their addon replies.")
            end
        end
    end, "utility")
    modal.refresh:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -20, -18)
    modal.close = UI:Button(modal, "Close", 82, 26, function() OTLGM:CloseModal180(modal, "member-achievements-close") end, "secondary")
    modal.close:SetPoint("RIGHT", modal.refresh, "LEFT", -8, 0)
    modal.search = UI:SearchBox(modal, 286, 28, "Search achievements...", function()
        modal.otlOffsetR42 = 0
        OTLGM:RefreshGuildMemberAchievementBrowserR42()
    end)
    modal.search:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -76)
    modal.all = UI:Button(modal, "All", 86, 28, function() modal.otlFilterR42="ALL" modal.otlOffsetR42=0 OTLGM:RefreshGuildMemberAchievementBrowserR42() end, "secondary")
    modal.all:SetPoint("LEFT", modal.search, "RIGHT", 10, 0)
    modal.completed = UI:Button(modal, "Completed", 104, 28, function() modal.otlFilterR42="COMPLETED" modal.otlOffsetR42=0 OTLGM:RefreshGuildMemberAchievementBrowserR42() end, "utility")
    modal.completed:SetPoint("LEFT", modal.all, "RIGHT", 8, 0)
    modal.missing = UI:Button(modal, "Not Completed", 122, 28, function() modal.otlFilterR42="MISSING" modal.otlOffsetR42=0 OTLGM:RefreshGuildMemberAchievementBrowserR42() end, "utility")
    modal.missing:SetPoint("LEFT", modal.completed, "RIGHT", 8, 0)
    modal.rows = {}
    local i
    for i = 1, ROWS_R42 do
        local row = UI:TableRow(modal, 650, 43, nil)
        row:SetPoint("TOPLEFT", modal, "TOPLEFT", 20, -116 - ((i - 1) * 47))
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetPoint("LEFT", row, "LEFT", 6, 0) row.icon:SetWidth(30) row.icon:SetHeight(30)
        row.icon:SetTexCoord(0.08,0.92,0.08,0.92)
        row.nameText = UI.Text(row, "", "GameFontNormal", "LEFT")
        row.nameText:SetPoint("TOPLEFT", row, "TOPLEFT", 44, -6) row.nameText:SetWidth(390)
        row.descText = UI.Text(row, "", "GameFontNormalSmall", "LEFT")
        row.descText:SetPoint("TOPLEFT", row, "TOPLEFT", 44, -24) row.descText:SetWidth(430)
        row.descText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
        row.stateText = UI.Text(row, "", "GameFontNormalSmall", "RIGHT")
        row.stateText:SetPoint("RIGHT", row, "RIGHT", -10, 0) row.stateText:SetWidth(150) row.stateText:SetHeight(34)
        row.stateText:SetJustifyV("MIDDLE")
        row.stateAccentR45 = row:CreateTexture(nil, "ARTWORK")
        row.stateAccentR45:SetPoint("TOPLEFT", row, "TOPLEFT", 1, -2)
        row.stateAccentR45:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 1, 2)
        row.stateAccentR45:SetWidth(3)
        modal.rows[i] = row
    end
    local function WheelR45(delta)
        local maximum = math.max(0, tonumber(modal.otlMaximumR45) or 0)
        local current = math.max(0, math.min(maximum, tonumber(modal.otlOffsetR42) or 0))
        delta = tonumber(delta) or 0
        if delta == 0 then return end
        local nextValue = math.max(0, math.min(maximum, current - (delta > 0 and 3 or -3)))
        if nextValue ~= current then
            modal.otlOffsetR42 = nextValue
            OTLGM:RefreshGuildMemberAchievementBrowserR42()
        end
    end
    if modal.EnableMouseWheel then modal:EnableMouseWheel(true) end
    modal:SetScript("OnMouseWheel", function() WheelR45(arg1) end)
    for i = 1, ROWS_R42 do
        if modal.rows[i].EnableMouseWheel then modal.rows[i]:EnableMouseWheel(true) end
        modal.rows[i]:SetScript("OnMouseWheel", function() WheelR45(arg1) end)
    end
    modal.scroll = UI:Scrollbar(modal, 420, function(value)
        modal.otlOffsetR42 = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
        OTLGM:RefreshGuildMemberAchievementBrowserR42()
    end)
    if modal.scroll.EnableMouseWheel then modal.scroll:EnableMouseWheel(true) end
    modal.scroll:SetScript("OnMouseWheel", function() WheelR45(arg1) end)
    modal.scroll:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -18, -116)
    modal.footer = UI.Text(modal, "", "GameFontNormalSmall", "LEFT")
    modal.footer:SetPoint("BOTTOMLEFT", modal, "BOTTOMLEFT", 20, 18) modal.footer:SetWidth(500)
    modal.footer:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
    self.ui.memberAchievementBrowserR42 = modal
    return modal
end

function OTLGM:RefreshGuildMemberAchievementBrowserR42()
    local modal = self.ui and self.ui.memberAchievementBrowserR42
    local name = modal and modal.otlMemberNameR42 or nil
    if not modal or not name then return false end
    local member = self.GetMember and self:GetMember(name) or nil
    if not member then return false end
    local snapshot = self.GetGuildProfileAchievementSnapshot183 and self:GetGuildProfileAchievementSnapshot183(name) or {known=false,recent={}}
    local details = self.GetGuildAchievementDetailsR42 and self:GetGuildAchievementDetailsR42(name) or nil
    local detailStatusR42 = self.GetGuildAchievementDetailStatusR42 and self:GetGuildAchievementDetailStatusR42(name) or nil
    local version = self.GetDetectedAddonVersion183 and self:GetDetectedAddonVersion183(name) or nil
    local detailSupported = self.IsDetailedAchievementPeerR42 and self:IsDetailedAchievementPeerR42(version) or false
    local recent = RecentMap42(snapshot)
    local query = N42(self, modal.search and modal.search:GetText() or "")
    local filter = modal.otlFilterR42 or "ALL"
    local list, catalog, i, def = {}, self.achievements174 and self.achievements174.catalog or {}, nil, nil
    for i = 1, table.getn(catalog) do
        def = catalog[i]
        local completed = details and details.completedMap and details.completedMap[def.id] and true or false
        local state = details and (completed and "COMPLETED" or "MISSING") or (recent[def.id] and "COMPLETED" or "UNKNOWN")
        local haystack = N42(self, tostring(def.name or "") .. " " .. tostring(def.description or "") .. " " .. tostring(def.id or ""))
        local matches = query == "" or string.find(haystack, query, 1, true)
        local filterMatches = filter == "ALL" or (filter == "COMPLETED" and state == "COMPLETED")
            or (filter == "MISSING" and ((details and state == "MISSING") or (not details and state == "UNKNOWN")))
        local completedAt = details and details.completedAtMap and tonumber(details.completedAtMap[def.id]) or nil
        if not completedAt and recent[def.id] then completedAt = tonumber(recent[def.id].ts) end
        if matches and filterMatches then table.insert(list, {def=def,state=state,completed=completed,recent=recent[def.id],completedAt=completedAt}) end
    end
    local maximum = math.max(0, table.getn(list) - ROWS_R42)
    modal.otlMaximumR45 = maximum
    modal.otlOffsetR42 = math.max(0, math.min(maximum, tonumber(modal.otlOffsetR42) or 0))
    modal.scroll.otlSilent = true
    modal.scroll:SetScrollMetrics180(table.getn(list), ROWS_R42, modal.otlOffsetR42)
    modal.scroll:SetValue(modal.otlOffsetR42)
    modal.scroll.otlSilent = nil
    modal.title:SetText(tostring(name) .. "'s Achievements")
    if details then
        if details.localStoredR42 then
            modal.status:SetText("Stored locally for this character  •  " .. tostring(details.completed or 0) .. "/" .. tostring(details.total or 0) .. " completed  •  completion dates available")
        else
            modal.status:SetText("Shared directly by " .. tostring(name) .. "'s addon  •  " .. tostring(details.completed or 0) .. "/" .. tostring(details.total or 0) .. " completed  •  " .. Age42(self, details.updatedAt)
                .. (details.completedAtMap and "  •  dates shared" or "  •  completion dates not available from this addon version"))
        end
    elseif detailStatusR42 and detailStatusR42.incompatibleCatalogR42 then
        modal.status:SetText("This character shared achievement details from a different catalogue. Showing the safe summary fallback instead of guessing statuses.")
    elseif snapshot.known then
        modal.status:SetText("Summary available: " .. tostring(snapshot.completed or 0) .. "/" .. tostring(snapshot.total or 0) .. ". Only recently shared completions can be identified individually on this client.")
    else
        modal.status:SetText("No achievement data has been shared by this character yet.")
    end
    local refreshReasonR47 = nil
    if not detailSupported then
        refreshReasonR47 = self.GetFeatureCompatibilityMessageR32 and self:GetFeatureCompatibilityMessageR32(name, "PROFILE_ACHIEVEMENT_DETAILS", false)
            or "Detailed achievement status needs a newer addon on this character."
    end
    UI:SetEnabled(modal.refresh, detailSupported, refreshReasonR47)
    UI:SetText(modal.completed, details and "Completed" or "Recent")
    UI:SetText(modal.missing, details and "Not Completed" or "Not Verified")
    UI:SetSelected(modal.all, filter == "ALL") UI:SetSelected(modal.completed, filter == "COMPLETED") UI:SetSelected(modal.missing, filter == "MISSING")
    for i = 1, ROWS_R42 do
        local row, entry = modal.rows[i], list[modal.otlOffsetR42 + i]
        if entry then
            local shownName = entry.def.name or entry.def.id
            local shownDesc = entry.def.secret and not entry.completed and "The title is your clue." or (entry.def.secret and entry.def.revealed or entry.def.description or "")
            row.icon:SetTexture(entry.def.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            local completedDateR45 = Date42(entry.completedAt)
            if entry.state == "COMPLETED" and entry.def.secret then
                row.icon:SetVertexColor(1, 0.92, 1)
                row.nameText:SetText(Short42(shownName, 48))
                row.nameText:SetTextColor(0.90, 0.68, 1)
                row.descText:SetText(Short42(shownDesc, 74))
                row.descText:SetTextColor(0.62, 0.55, 0.68)
                row.stateText:SetText("|cffd18cffCompleted • Secret|r"
                    .. "\n" .. self.colors.gold .. (completedDateR45 or "Date not shared") .. self.colors.reset)
                row.stateAccentR45:SetTexture(0.56, 0.30, 0.68, 0.95)
                if row.SetBackdropBorderColor then row:SetBackdropBorderColor(0.46, 0.25, 0.58, 1) end
            elseif entry.state == "COMPLETED" then
                row.icon:SetVertexColor(1, 1, 1)
                row.nameText:SetText(Short42(shownName, 48))
                row.nameText:SetTextColor(C.white[1], C.white[2], C.white[3])
                row.descText:SetText(Short42(shownDesc, 74))
                row.descText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
                row.stateText:SetText(self.colors.green .. "Completed" .. self.colors.reset
                    .. "\n" .. self.colors.gold .. (completedDateR45 or "Date not shared") .. self.colors.reset)
                row.stateAccentR45:SetTexture(C.green[1], C.green[2], C.green[3], 0.95)
                if row.SetBackdropBorderColor then row:SetBackdropBorderColor(0.23, 0.46, 0.23, 1) end
            elseif entry.state == "MISSING" then
                row.icon:SetVertexColor(0.34, 0.34, 0.34)
                row.nameText:SetText(Short42(shownName, 48))
                row.nameText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
                row.descText:SetText(Short42(shownDesc, 74))
                row.descText:SetTextColor(0.38, 0.37, 0.34)
                row.stateText:SetText(self.colors.grey .. "Not completed" .. self.colors.reset)
                if entry.def.secret then
                    row.stateAccentR45:SetTexture(0.38, 0.18, 0.52, 0.72)
                    if row.SetBackdropBorderColor then row:SetBackdropBorderColor(0.28, 0.17, 0.36, 1) end
                else
                    row.stateAccentR45:SetTexture(0.38, 0.37, 0.34, 0.80)
                    if row.SetBackdropBorderColor then row:SetBackdropBorderColor(0.20, 0.18, 0.15, 1) end
                end
            else
                row.icon:SetVertexColor(0.58, 0.58, 0.58)
                row.nameText:SetText(Short42(shownName, 48))
                row.nameText:SetTextColor(C.grey[1], C.grey[2], C.grey[3])
                row.descText:SetText(Short42(shownDesc, 74))
                row.descText:SetTextColor(0.38, 0.37, 0.34)
                row.stateText:SetText(self.colors.orange .. "Not verified" .. self.colors.reset)
                row.stateAccentR45:SetTexture(C.orange[1], C.orange[2], C.orange[3], 0.72)
                if row.SetBackdropBorderColor then row:SetBackdropBorderColor(0.34, 0.25, 0.12, 1) end
            end
            row:Show()
        else row:Hide() end
    end
    modal.footer:SetText(tostring(table.getn(list)) .. " matching achievement" .. (table.getn(list)==1 and "" or "s")
        .. (details and " • mouse wheel supported • status reported by this character's addon" or " • mouse wheel supported • summary fallback; unknown is not treated as incomplete"))
    return true
end

function OTLGM:OpenGuildMemberAchievementsR42(name)
    local member = self.GetMember and self:GetMember(name) or nil
    if not member then return false end
    if not self.ui or not self.ui.main then self:BuildUI() end
    local modal = self:BuildGuildMemberAchievementBrowserR42()
    if not modal then return false end
    modal.otlMemberNameR42 = member.name
    modal.otlFilterR42 = "ALL" modal.otlOffsetR42 = 0
    if modal.search then UI:SetSearchText(modal.search, "") end
    self:RefreshGuildMemberAchievementBrowserR42()
    local version = self.GetDetectedAddonVersion183 and self:GetDetectedAddonVersion183(member.name) or nil
    if self.IsDetailedAchievementPeerR42 and self:IsDetailedAchievementPeerR42(version) and self.QueueGuildAchievementDetailRequestR42 then
        self:QueueGuildAchievementDetailRequestR42(member.name, "open-browser")
    end
    self:ShowShellModal(modal)
    return true
end

function OTLGM:OpenGuildMemberProfessionsR42(name)
    local member = self.GetMember and self:GetMember(name) or nil
    if not member then return false end
    if not self.ui or not self.ui.main then self:BuildUI() end
    self.ui.craftingCrafterFilterR42 = member.name
    self.ui.professionsSection = "RECIPES"
    -- Profile -> Professions is a member-scoped entry point. Do not inherit a
    -- previous global profession/category/search state and accidentally make a
    -- character with many stored recipes look as if they only know two or four.
    self.ui.craftingProfessionFilterShell = "ALL"
    self.ui.craftingRecipeOffset = 0
    self.ui.craftingSelectedRecipeKey = nil
    if OTLGM_DB and OTLGM_DB.settings then
        OTLGM_DB.settings.craftingSection = "RECIPES"
        OTLGM_DB.settings.craftingCategory153 = "ALL"
        OTLGM_DB.settings.craftingLevelFilter153 = "ANY"
        OTLGM_DB.settings.craftingLevelBasis170 = "ITEM"
        OTLGM_DB.settings.craftingRarityFilter153 = "ANY"
        OTLGM_DB.settings.craftingOnlineOnly153 = false
        OTLGM_DB.settings.craftingFavoritesOnly170 = false
    end
    if self.ui.craftingSearchEdit then UI:SetSearchText(self.ui.craftingSearchEdit, "") end
    if self.InvalidateCraftingSearchCache then self:InvalidateCraftingSearchCache() end
    if not self:ShowPage("professions") then return false end
    if self.RefreshProfessionsPage then self:RefreshProfessionsPage() end
    if self.ShowToast then self:ShowToast("Showing recipes shared by " .. tostring(member.name) .. ".", "success", 3) end
    return true
end

-- Network detail responses refresh the open modal through SocialProfiles' normal
-- HandleSocialProfileMessage path below; this helper is public for that callback.

OTLGM:RegisterModule("ProfileDetailsR42", { achievementRows = ROWS_R42, onDemand = true })
