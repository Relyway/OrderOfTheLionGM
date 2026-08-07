-- Order of the Lion Guild Manager
-- Safe events, diagnostics and controlled roster refresh.

SLASH_OTLGM1 = "/otl"
SLASH_OTLGM2 = "/liongm"
SLASH_OTLGMTEST1 = "/otltest"

local function PrintLine(message, errorLine)
    if not DEFAULT_CHAT_FRAME then return end
    local color = errorLine and "|cffff3333" or "|cffffcc33"
    DEFAULT_CHAT_FRAME:AddMessage(color .. "[Lion GM]|r " .. tostring(message or ""))
end

local function ToggleSafely()
    if not OTLGM or type(OTLGM.ToggleUI) ~= "function" then
        PrintLine("The UI module did not load. Type /otltest for the module report.", true)
        return
    end
    local ok, err = pcall(function() OTLGM:ToggleUI() end)
    if not ok then PrintLine("UI runtime error: " .. tostring(err), true) end
end

SlashCmdList["OTLGM"] = function(message)
    message = string.lower(message or "")
    if message == "scan" then
        if OTLGM and type(OTLGM.RequestScan) == "function" then OTLGM:RequestScan("MANUAL") end
    elseif message == "reset" then
        if IsShiftKeyDown() and OTLGM and OTLGM.ResetGuildData then
            OTLGM:ResetGuildData()
        else
            PrintLine("Hold Shift while entering /otl reset, or use Settings.")
        end
    elseif message == "minimap" then
        if OTLGM and OTLGM.EnsureDB then
            OTLGM:EnsureDB()
            OTLGM_DB.settings.showMinimap = not OTLGM_DB.settings.showMinimap
            if OTLGM.ApplyMinimapVisibility then OTLGM:ApplyMinimapVisibility() end
        end
    elseif message == "wizard" then
        if OTLGM and OTLGM.__impl180.OpenFirstRunWizard__impl1 then OTLGM:OpenFirstRunWizard() else ToggleSafely() end
    elseif message == "backup" then
        if OTLGM and OTLGM.__impl180.ShowCopyDialog__impl1 and OTLGM.ExportBackup then
            OTLGM:ShowCopyDialog("Order of the Lion Addon Backup", OTLGM:ExportBackup())
        else
            ToggleSafely()
        end
    elseif message == "help" then
        PrintLine("/otl - open | /otl scan - manual update | /otl minimap | /otltest - diagnostics")
    else
        ToggleSafely()
    end
end

SlashCmdList["OTLGMTEST"] = function()
    local loaded, reason = IsAddOnLoaded("OrderOfTheLionGM"), ""
    if GetAddOnInfo then
        local name, title, notes, enabled, loadable, loadReason = GetAddOnInfo("OrderOfTheLionGM")
        reason = tostring(loadReason)
    end
    if not OTLGM then PrintLine("Diagnostic: bootstrap is missing; TOC=" .. tostring(loaded) .. ", reason=" .. tostring(reason), true) return end
    local moduleCount = OTLGM.Count and OTLGM:Count(OTLGM.modules) or 0
    local registryReady = OTLGM.GetModule and OTLGM:GetModule("Transport") and OTLGM:GetModule("Security") and true or false
    local db = OTLGM.__impl180.GetGuildDB__impl1 and OTLGM:GetGuildDB() or nil
    local craft = OTLGM.EnsureCraftingDB and OTLGM:EnsureCraftingDB() or nil
    local queueTotal, queueCritical, queueNormal, queueBulk = 0, 0, 0, 0
    if OTLGM.GetNetworkQueueDepth then queueTotal, queueCritical, queueNormal, queueBulk = OTLGM:GetNetworkQueueDepth() end
    local metrics = OTLGM.runtime and OTLGM.runtime.metrics and OTLGM.runtime.metrics.network or {}
    local transport = OTLGM.runtime and OTLGM.runtime.transport or {}
    local backoff = math.max(0, (tonumber(transport.nextAttemptAt) or 0) - OTLGM:Now())
    local tooltipCompatibility = GameTooltip and GameTooltip.otlTooltipCompatibility160 or {}
    PrintLine("Runtime v" .. tostring(OTLGM.version) .. (OTLGM.hotfix and (" / " .. tostring(OTLGM.hotfix)) or "") .. " / schema " .. tostring(OTLGM.schemaVersion) .. " / protocol " .. tostring(OTLGM.protocolVersion) .. "; TOC=" .. tostring(loaded) .. ", reason=" .. tostring(reason))
    PrintLine("Modules=" .. tostring(moduleCount) .. "; registry=" .. tostring(registryReady and "ready" or "incomplete") .. "; database=" .. tostring(db and "ready" or "unavailable") .. "; migration=" .. tostring(db and db.migration and db.migration.foundation170 and "1.7" or "pending"))
    local nativeUI = OTLGM.GetNativeUIDiagnostics180 and OTLGM:GetNativeUIDiagnostics180() or {}
    PrintLine("Native UI=" .. tostring(nativeUI.loaded and "ready" or "unavailable") .. "; pages registered/built=" .. tostring(nativeUI.registered or 0) .. "/" .. tostring(nativeUI.built or 0) .. "; active=" .. tostring(nativeUI.activePage or "none") .. "; modal depth=" .. tostring(nativeUI.modalDepth or 0))
    PrintLine("Minimap=" .. tostring(OTLGM.ui and OTLGM.ui.minimapButton and "ready" or "unavailable") .. "; effective scale=" .. tostring(OTLGM.runtime and OTLGM.runtime.effectiveUIScale or "default") .. "; chat shield=" .. tostring(nativeUI.chatShield or "unknown"))
    PrintLine("Network queue total/critical/normal/bulk=" .. tostring(queueTotal) .. "/" .. tostring(queueCritical) .. "/" .. tostring(queueNormal) .. "/" .. tostring(queueBulk))
    PrintLine("Network sent/retried/dropped/rejected=" .. tostring(metrics.sent or 0) .. "/" .. tostring(metrics.retried or 0) .. "/" .. tostring(metrics.dropped or 0) .. "/" .. tostring(metrics.rejected or 0) .. "; sender validation=" .. tostring(OTLGM.IsKnownGuildSender and "enabled" or "missing"))
    PrintLine("Targeted routed/received/skipped (non-recipient packets are normal)=" .. tostring(metrics.targetedRouted or 0) .. "/" .. tostring(metrics.targetedReceived or 0) .. "/" .. tostring(metrics.targetedSkipped or metrics.targetedIgnored or 0) .. "; safely shortened=" .. tostring(metrics.targetedTrimmed or 0) .. "; backoff=" .. tostring(backoff) .. "s; TurtleRP tooltip guard=" .. tostring(tooltipCompatibility.wrapper and "active" or "not needed"))
    PrintLine("Crafting characters/details=" .. tostring(OTLGM.Count and OTLGM:Count(craft and craft.characters) or 0) .. "/" .. tostring(OTLGM.Count and OTLGM:Count(craft and craft.details) or 0) .. "; manifest=" .. tostring(OTLGM.HandleCraftingManifest157 and "ready" or "missing") .. "; result tooltips=" .. tostring(OTLGM.ShowCraftingResultTooltip and "ready" or "missing"))
    if metrics.lastError then PrintLine("Last network error (" .. tostring(metrics.lastErrorChannel or "?") .. "/" .. tostring(metrics.lastErrorSource or "?") .. "): " .. tostring(metrics.lastError), true) end
    if metrics.lastRejectReason then PrintLine("Last rejected packet: " .. tostring(metrics.lastRejectReason) .. " from " .. tostring(metrics.lastRejectSender or "unknown")) end
end




-- C5-R5 page-level circuit breaker.  A refresh error is shown once for a
-- specific page revision; repeated scheduled refreshes are suppressed until
-- the page is explicitly dirtied/reopened or the revision changes.
function OTLGM:ResetPageRefreshError180(pageKey, reason)
    self.runtime = self.runtime or {}
    self.runtime.pageRefreshErrors180 = self.runtime.pageRefreshErrors180 or {}
    self.runtime.pageRefreshErrors180[tostring(pageKey or "")] = nil
    self.runtime.lastPageRefreshReset180 = { page = tostring(pageKey or ""), reason = tostring(reason or "event"), at = self:Now() }
end

function OTLGM:SafeRefreshPage180(pageKey, revision, callback)
    if type(callback) ~= "function" then return false, "missing callback" end
    self.runtime = self.runtime or {}
    self.runtime.pageRefreshErrors180 = self.runtime.pageRefreshErrors180 or {}
    local key = tostring(pageKey or "unknown")
    local rev = tostring(revision or "0")
    local state = self.runtime.pageRefreshErrors180[key]
    if state and state.revision == rev and state.blocked then
        state.suppressed = (tonumber(state.suppressed) or 0) + 1
        return false, state.error
    end
    local ok, result = pcall(callback)
    if ok then
        if state then self.runtime.pageRefreshErrors180[key] = nil end
        return true, result
    end
    local message = tostring(result or "unknown refresh error")
    local fingerprint = string.sub(message, 1, 180)
    local same = state and state.fingerprint == fingerprint and state.revision == rev
    self.runtime.pageRefreshErrors180[key] = {
        revision = rev, fingerprint = fingerprint, error = message, blocked = true,
        count = same and ((tonumber(state.count) or 1) + 1) or 1,
        suppressed = same and (tonumber(state.suppressed) or 0) or 0, at = self:Now(),
    }
    self.runtime.lastPageRefreshError180 = { page = key, revision = rev, error = message, at = self:Now() }
    if not same and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa33[Lion GM]|r " .. key .. " page refresh stopped after an error. Open Diagnostics for details.")
    end
    return false, message
end

local eventFrame = CreateFrame("Frame", "OTLGM_EventFrame")

-- C5-R4 final closeout: one keyed scheduler which is physically asleep when
-- there is no work. Vanilla has no C_Timer, therefore a pending future task
-- temporarily owns the event frame OnUpdate; the script is removed again as
-- soon as the registry and all compatibility work queues are empty.
local SchedulerOnUpdate180
local SCHEDULER_TASK_LIMIT_180 = 8
local SCHEDULER_MIN_CHECK_180 = 0.02

-- Scheduler deadlines are stored as epoch seconds, but short slices need a
-- monotonic fractional clock.  The former implementation combined the current
-- epoch second with the unrelated fractional phase of GetTime(); near either
-- clock boundary that value could move backwards by almost a full second and
-- repeatedly postpone otherwise-ready work.  Anchor the epoch once and advance
-- it only by GetTime deltas.  Wall-clock jumps forward are honoured, while no
-- caller can ever observe the scheduler clock moving backwards.
function OTLGM:GetPreciseTime180()
    local epoch = tonumber(self:Now()) or (time and tonumber(time())) or 0
    self.runtime = self.runtime or {}
    local state = self.runtime.preciseClock180
    local uptime
    if GetTime then
        local ok, value = pcall(GetTime)
        if ok then uptime = tonumber(value) end
    end

    if not state then
        state = { value = epoch, uptime = uptime, wall = epoch }
        self.runtime.preciseClock180 = state
        return epoch
    end

    local previous = tonumber(state.value) or epoch
    local previousUptime = tonumber(state.uptime)
    local previousWall = tonumber(state.wall) or epoch
    local candidate = previous
    local elapsed
    if uptime and previousUptime then
        elapsed = uptime - previousUptime
        -- GetTime normally resets only on a full client restart (which also
        -- recreates runtime), but defensive handling keeps malformed test/UI
        -- replacements from producing a negative or absurd scheduler jump.
        if elapsed >= 0 and elapsed < 86400 then
            candidate = previous + elapsed
        else
            elapsed = nil
        end
    end

    if not elapsed then
        -- Without a usable monotonic delta, wall time is the only safe source.
        -- Never move backwards.
        if epoch > candidate then candidate = epoch end
    else
        -- `time()` changes in whole-second steps. Snapping candidate to `epoch`
        -- on each ordinary second boundary can make a 250 ms task fire after
        -- only a few milliseconds when the wall second rolls over. Use GetTime
        -- as the normal clock and honour only a *real* large forward wall-clock
        -- correction (manual/system time jump). Normal quantisation differs from
        -- the monotonic delta by at most about one second.
        local wallAdvance = epoch - previousWall
        if wallAdvance - elapsed > 2 then
            if epoch > candidate then candidate = epoch end
        end
    end
    if candidate < previous then candidate = previous end

    state.value = candidate
    state.uptime = uptime
    state.wall = epoch
    return candidate
end

local function SchedulerNow180(owner)
    return owner.GetPreciseTime180 and owner:GetPreciseTime180() or owner:Now()
end

local function SchedulerState180(owner)
    owner.runtime = owner.runtime or {}
    owner.runtime.scheduler180 = owner.runtime.scheduler180 or {
        tasks = {}, active = false, wakeCount = 0, sleepCount = 0,
        executed = 0, errors = 0, reasons = {}, nearestKey = nil,
        nearestDue = nil, nextCheckAt = 0, pollElapsed180 = 0,
        pollInterval180 = SCHEDULER_MIN_CHECK_180,
    }
    return owner.runtime.scheduler180
end

local function MinDue180(current, candidate, now)
    candidate = tonumber(candidate)
    if not candidate then return current end
    if candidate < now then candidate = now end
    if not current or candidate < current then return candidate end
    return current
end

local function MapDue180(map, now, fallback)
    if type(map) ~= "table" then return nil end
    local due, key, value
    for key, value in pairs(map) do
        if value ~= nil then
            if type(value) == "table" then
                local candidate = value.due or value.nextAt or value.nextAttemptAt or value.expiresAt or value.timeoutAt
                if candidate ~= nil then
                    due = MinDue180(due, candidate, now)
                elseif fallback ~= nil then
                    due = MinDue180(due, fallback, now)
                else
                    -- Every table map owned by this scheduler has an explicit
                    -- deadline field. A damaged/legacy child without one is not
                    -- actionable and several older processors assume a valid
                    -- table shape. Drop it here instead of turning corruption
                    -- into an always-due exception loop.
                    map[key] = nil
                end
            else
                -- Scalar deadline maps are also supported (achievement toast
                -- hide times use this form). The old generic branch treated any
                -- scalar as due-now, which kept the scheduler awake every frame
                -- for the whole toast lifetime. Nonnumeric scalars are malformed
                -- scheduler state and can be discarded safely.
                local scalarDue = tonumber(value)
                if scalarDue ~= nil then
                    due = MinDue180(due, scalarDue, now)
                elseif fallback ~= nil then
                    due = MinDue180(due, fallback, now)
                else
                    map[key] = nil
                end
            end
        end
    end
    return due
end

local function HasEntries180(value)
    return type(value) == "table" and next(value) ~= nil
end

local function CraftingDBNoCreate180(owner)
    local cache = owner.runtime and owner.runtime.featureDbCache176 and owner.runtime.featureDbCache176.crafting
    if cache and type(cache.db) == "table" then return cache.db end
    local guildKey = owner.GuildKey and owner:GuildKey() or nil
    local guild = guildKey and type(OTLGM_DB) == "table" and type(OTLGM_DB.guilds) == "table" and OTLGM_DB.guilds[guildKey] or nil
    return guild and guild.crafting or nil
end

local function PveDBNoCreate180(owner)
    local cache = owner.runtime and owner.runtime.featureDbCache176 and owner.runtime.featureDbCache176.pve
    if cache and type(cache.db) == "table" then return cache.db end
    local guildKey = owner.GuildKey and owner:GuildKey() or nil
    local guild = guildKey and type(OTLGM_DB) == "table" and type(OTLGM_DB.guilds) == "table" and OTLGM_DB.guilds[guildKey] or nil
    return guild and guild.pve or nil
end

local function NetworkDue180(owner, now)
    -- Performance176 deliberately pauses transport while a world/zone transition
    -- is settling. Let transitionDue176 own the wake instead of advertising an
    -- immediately-due network queue that the processor will refuse every frame.
    if owner.runtime and owner.runtime.transitionActive176 then return nil end
    local total, critical, normal, bulk = 0, 0, 0, 0
    if owner.GetNetworkQueueDepth then total, critical, normal, bulk = owner:GetNetworkQueueDepth() end
    if (tonumber(total) or 0) <= 0 then return nil end
    if owner.InCombat and owner:InCombat() and (tonumber(critical) or 0) <= 0 and (tonumber(normal) or 0) <= 0 and (tonumber(bulk) or 0) > 0 then
        -- Bulk is resumed by PLAYER_REGEN_ENABLED. Do not keep an OnUpdate alive
        -- merely to discover that combat still blocks the same packets.
        return nil
    end
    local transport = owner.runtime and owner.runtime.transport
    return MinDue180(nil, transport and transport.nextAttemptAt or now, now)
end

local function CraftingDue180(owner, now)
    -- The crafting timer owner is transition-gated.  Suppress its deadlines
    -- until the stable transition pass releases the barrier; QualityDue180
    -- already schedules that exact release time.
    if owner.runtime and owner.runtime.transitionActive176 then return nil end
    local due
    local inCombat = owner.InCombat and owner:InCombat()
    -- Full state responses, item-cache/detail work and profession rescans are
    -- bulk work. The detail processor is also explicitly combat-gated, so an
    -- outstanding detail queue must not advertise due-now work while combat
    -- prevents it from making progress. PLAYER_REGEN_ENABLED wakes us again.
    if not inCombat then
        local detailQueue = owner.runtime and owner.runtime.craftingDetailQueue
        if type(detailQueue) == "table" and type(detailQueue.items) == "table"
            and (tonumber(detailQueue.head) or 1) <= table.getn(detailQueue.items) then
            due = MinDue180(due, now, now)
        end
        due = MinDue180(due, owner.craftingRescan and owner.craftingRescan.due, now)
        due = MinDue180(due, MapDue180(owner.craftingShareTargets, now), now)
        due = MinDue180(due, MapDue180(owner.runtime and owner.runtime.craftingCacheQueue, now), now)
        due = MinDue180(due, MapDue180(owner.runtime and owner.runtime.craftingIconHydration180, now), now)
        local transferKey, transfer
        local transferStates = owner.runtime and owner.runtime.craftingOutboundTransferStates180
        if type(transferStates) == "table" then
            for transferKey, transfer in pairs(transferStates) do
                if type(transfer) == "table" then
                    due = MinDue180(due, transfer.nextAttemptAt or now, now)
                else
                    transferStates[transferKey] = nil
                end
            end
        end
        if owner.runtime and owner.runtime.deferredProfessionScanPack3_180 then due = MinDue180(due, now, now) end
    end
    -- Manifests and active-sync deadlines are compact metadata and may remain
    -- responsive in combat.
    due = MinDue180(due, MapDue180(owner.craftingManifestTargets157, now), now)
    local craft = CraftingDBNoCreate180(owner)
    local sync = craft and craft.syncState
    if type(sync) == "table" and sync.active then
        local started = tonumber(sync.started) or now
        local manifests = tonumber(sync.manifests157) or 0
        -- Match the actual timer state machine exactly.  A past deadline that
        -- no longer corresponds to actionable work would otherwise be clamped
        -- to `now` forever and turn the sleeping scheduler into a busy loop.
        if manifests <= 0 then
            due = MinDue180(due, started + 15, now)
        end
        local wantedCount, deferredCount = 0, 0
        local wantedKey, wanted
        if type(sync.wanted157) ~= "table" then sync.wanted157 = {} end
        for wantedKey, wanted in pairs(sync.wanted157) do
            if type(wanted) == "table" then
                wantedCount = wantedCount + 1
                local progress = tonumber(wanted.lastProgress or wanted.ts) or now
                local created = tonumber(wanted.createdAt or wanted.ts) or now
                if (tonumber(wanted.tries) or 1) < 2 then due = MinDue180(due, progress + 20, now) end
                due = MinDue180(due, math.min(progress + 90, created + 120), now)
            else
                sync.wanted157[wantedKey] = nil
            end
        end
        if type(sync.deferred157) ~= "table" then sync.deferred157 = {} end
        for _ in pairs(sync.deferred157) do deferredCount = deferredCount + 1 end
        if manifests > 0 and wantedCount + deferredCount == 0 then
            local quietBase = tonumber(sync.lastManifestAt157) or started
            due = MinDue180(due, quietBase + 5, now)
        end
        -- Legacy final safety bound remains useful if malformed/partial sync
        -- state escapes the ordinary wanted/deferred completion paths.
        due = MinDue180(due, started + 125, now)
    end
    return due
end

local function PveDue180(owner, now)
    local due
    local runtime = owner.runtime and owner.runtime.pve
    due = MinDue180(due, runtime and runtime.groupLiveStateDue180, now)
    due = MinDue180(due, MapDue180(runtime and runtime.pendingGroupMatchEval180, now), now)
    local pve = PveDBNoCreate180(owner)
    due = MinDue180(due, MapDue180(pve and pve.applicationRetries, now), now)
    if type(owner.pveSyncPending180) == "table" then
        due = MinDue180(due, (tonumber(owner.pveSyncPending180.startedAt) or now) + 18, now)
    elseif owner.pveSyncPending180 ~= nil then
        owner.pveSyncPending180 = nil
    end
    due = MinDue180(due, MapDue180(owner.runtime and owner.runtime.raidTeamMembershipPending180, now), now)
    return due
end

local function OperationDue180(owner, now)
    local due
    local key, item
    for key, item in pairs(owner.operationState156 or {}) do
        if type(item) == "table" then
            due = MinDue180(due, item.untilTs, now)
            if item.state == "WORKING" then
                local activeRosterRead = key == "ROSTER" and owner.runtime and owner.runtime.rosterRead180
                -- A sliced roster reader owns its own short scheduler task. Once
                -- the request has produced data, the original 15s request timeout
                -- must not remain permanently overdue and force frame-by-frame
                -- compatibility checks during a long bounded read.
                if not activeRosterRead then
                    local timeout = key == "ROSTER" and 15 or (key == "ACTIVITY" and 8 or (key == "PVE" and 20 or 20))
                    due = MinDue180(due, (tonumber(item.ts) or now) + timeout, now)
                end
            end
        end
    end
    return due
end

local function MarkRosterRequestTimeoutRC3(owner, now)
    owner.runtime = owner.runtime or {}
    local reason = tostring(owner.pendingScanReason or "")
    owner.pendingScan = false
    owner.pendingScanReason = nil
    owner.runtime.rosterRequestTimeoutsRC3 = (tonumber(owner.runtime.rosterRequestTimeoutsRC3) or 0) + 1
    owner.runtime.lastRosterRequestTimeoutRC3 = now
    owner.runtime.lastRosterRequestTimeoutReasonRC3 = reason
    -- Automatic roster requests back off after an unanswered GuildRoster().
    -- Manual requests remain immediately retryable by the user.
    if reason ~= "MANUAL" then
        local failures = math.min(5, tonumber(owner.runtime.rosterRequestTimeoutsRC3) or 1)
        local backoff = math.min(300, 15 * (2 ^ math.max(0, failures - 1)))
        owner.runtime.rosterAutoRetryAfterRC3 = now + backoff
    end
    if owner.CancelTask180 then owner:CancelTask180("guild-roster-visible-scan") end
end

local function PruneOperationStates180(owner, now)
    local states = owner.operationState156
    if type(states) ~= "table" then return false end
    local changed = false
    local key, item
    for key, item in pairs(states) do
        if type(item) ~= "table" then
            states[key] = nil
            changed = true
        elseif item.untilTs and now >= (tonumber(item.untilTs) or now) then
            states[key] = nil
            changed = true
        elseif item.state == "WORKING" then
            local timeout = key == "ROSTER" and 15 or (key == "PVE" and 20 or 20)
            local activeRosterRead = key == "ROSTER" and owner.runtime and owner.runtime.rosterRead180
            if not activeRosterRead and now >= (tonumber(item.ts) or now) + timeout then
                if key == "ROSTER" and owner.pendingScan then MarkRosterRequestTimeoutRC3(owner, now) end
                item.state = "ERROR"
                item.detail = item.detail ~= "" and item.detail or "The operation did not confirm in time."
                item.untilTs = now + 5
                changed = true
            end
        end
    end
    return changed
end

local function QualityDue180(owner, now)
    local runtime = owner.runtime or {}
    local due = OperationDue180(owner, now)
    local fields = {
        "performanceGroupDue176", "transitionDue176",
        "uiRefreshDue176", "achievementEquipmentDue174", "achievementGroupDue174",
        "achievementProfessionDue174", "achievementGroupTickAt174", "achievementRaidTickAt174",
        "achievementGuildDue174", "bagScanDueR6",
    }
    local index
    for index = 1, table.getn(fields) do due = MinDue180(due, runtime[fields[index]] or owner[fields[index]], now) end
    due = MinDue180(due, MapDue180(runtime.achievementToastHideAt174, now), now)
    if runtime.transitionActive176 then due = MinDue180(due, runtime.transitionDue176 or now, now) end
    -- Incremental bag work is intentionally slow/bounded. Respect both its
    -- start deadline and the R5 inter-slice gap; otherwise an active scan looks
    -- permanently overdue and keeps the shared scheduler awake between slices.
    local bagBlockedByCombat = owner.InCombat and owner:InCombat()
    if not bagBlockedByCombat then
        if runtime.incrementalBagScan176 then
            due = MinDue180(due, tonumber(runtime.nextBagSliceR5) or now, now)
        elseif runtime.incrementalBagDue176 then
            due = MinDue180(due, runtime.incrementalBagDue176, now)
        end
    end
    local mailScan = runtime.mailScan176 or runtime.mailboxScan176
    if type(mailScan) == "table" then
        due = MinDue180(due, mailScan.due or now, now)
    elseif mailScan then
        -- Legacy/corrupt boolean state: run once so the processor can clear it.
        due = MinDue180(due, now, now)
    end
    if HasEntries180(runtime.deferredOps176) and not (owner.InCombat and owner:InCombat()) then
        -- Cold-login/transition work is real pending work, but it must sleep until
        -- the earliest safe deadline instead of polling ProcessQuality every frame.
        local deferredDue = tonumber(runtime.nextDeferredOp176) or now
        local coldUntil = tonumber(runtime.loginColdUntil176) or 0
        local transitionUntil = runtime.transitionActive176 and (tonumber(runtime.transitionDue176) or 0) or 0
        if coldUntil > deferredDue then deferredDue = coldUntil end
        if transitionUntil > deferredDue then deferredDue = transitionUntil end
        due = MinDue180(due, deferredDue, now)
    end
    if runtime.achievementUiDirty176 and owner.ui and owner.ui.main and owner.ui.main:IsVisible() and owner.ui.currentPage == "achievements" then due = MinDue180(due, now, now) end

    -- Achievement/release cleanup used to keep a generic one-second heartbeat
    -- alive whenever any encounter/window state existed. Besides wasting idle
    -- work, that deadline was rebuilt as now+1 on every scheduler recompute and
    -- could slide forever under unrelated network/UI wakes. Schedule the exact
    -- expiry of each state instead. Event-driven success paths still run
    -- immediately; these deadlines only guarantee cleanup/recovery.
    due = MinDue180(due, runtime.highlightChatUntil174, now)
    if runtime.bossEncounter174 then
        due = MinDue180(due, (tonumber(runtime.bossEncounter174.started) or now) + 600, now)
    end
    local windowKeys180 = { "roarWindow174", "kneelWindow174", "danceWindow174" }
    local windowIndex180, windowState180
    for windowIndex180 = 1, table.getn(windowKeys180) do
        windowState180 = runtime[windowKeys180[windowIndex180]]
        if type(windowState180) == "table" then due = MinDue180(due, windowState180.expires, now) end
    end
    if runtime.pendingCraft175 then due = MinDue180(due, (tonumber(runtime.pendingCraft175.ts) or now) + 10, now) end
    if runtime.resurrection175 then due = MinDue180(due, (tonumber(runtime.resurrection175.started) or now) + 20, now) end
    if runtime.rabbitTarget175 then due = MinDue180(due, (tonumber(runtime.rabbitTarget175.ts) or now) + 45, now) end
    if runtime.bossEncounter175 then due = MinDue180(due, (tonumber(runtime.bossEncounter175.started) or now) + 600, now) end
    local groupKey180, groupState180
    for groupKey180, groupState180 in pairs(runtime.groupStates175 or {}) do
        if type(groupState180) == "table" then due = MinDue180(due, (tonumber(groupState180.ts) or now) + 180, now) end
    end

    local qualityBackoff = tonumber(runtime.qualityBackoffUntilR6)
    -- Transition release is a coordination barrier for transport/crafting. It
    -- must never inherit an unrelated achievement/maintenance backoff or the
    -- addon can look inactive for many seconds after zoning. The transition
    -- owner is itself fault-isolated and always clears the barrier.
    if not runtime.transitionActive176 and due and qualityBackoff and qualityBackoff > now and due < qualityBackoff then due = qualityBackoff end
    return due
end

local function UIDue180(owner, now)
    local ui = owner.ui
    if not ui or not ui.main or not ui.main:IsVisible() then
        if owner.runtime then owner.runtime.uiDebounceDue180 = nil end
        return nil
    end
    local page = tostring(ui.currentPage or "")
    local dirty = (page == "search" and ui.searchDirty)
        or (page == "professions" and ui.craftingSearchDirty)
        or (page == "achievements" and ui.achievementSearchDirty180)
        or (page == "roster" and ui.rosterSearchDirty180)
        or (page == "history" and ui.historySearchDirty180)
    owner.runtime = owner.runtime or {}
    if not dirty then
        owner.runtime.uiDebounceDue180 = nil
        return nil
    end
    -- Latch one real deadline instead of returning now+delay on every scheduler
    -- recomputation. Otherwise unrelated network/roster wakes can perpetually
    -- move the target forward (starvation), while an early compatibility slice
    -- can collapse a 250 ms text debounce into an immediate refresh.
    local due = tonumber(owner.runtime.uiDebounceDue180)
    if not due then
        due = now + 0.25
        owner.runtime.uiDebounceDue180 = due
    end
    return due
end

local function StatusDue180(owner, now)
    local runtime = owner.runtime or {}
    local due
    due = MinDue180(due, runtime.shellToastUntil, now)
    due = MinDue180(due, runtime.shellAddonCheckingUntil, now)
    due = MinDue180(due, runtime.statusUntil170, now)
    return due
end

local function CompatibilityDue180(owner, now)
    local due
    local pending = owner.rosterActionPending180
    if pending then
        local started = tonumber(pending.startedAt) or now
        if pending.kind == "NOTE" then
            -- Note edits are confirmed by GUILD_ROSTER_UPDATE. There is no
            -- periodic note poll, so nextCheckAt must not create an always-due
            -- compatibility wake for the entire twelve-second confirmation window.
            due = MinDue180(due, started + 12, now)
        else
            due = MinDue180(due, pending.nextCheckAt or now, now)
            if pending.kind == "APPROVE_LION" and pending.phase == 15 then
                due = MinDue180(due, pending.finalStepDue180, now)
            end
            due = MinDue180(due, started + 15, now)
        end
    end
    local recruitment = owner.recruitmentDeliveryPending180
    if recruitment then due = MinDue180(due, recruitment.timeoutAt or ((tonumber(recruitment.startedAt) or now) + 18), now) end
    local removal = owner.rosterRemovalPending180
    if removal then due = MinDue180(due, removal.nextCheckAt or now, now) end
    -- A confirmation request cannot start while another roster request/read is
    -- active. Do not keep an already-expired confirmScanAt as a zero-delay task;
    -- GUILD_ROSTER_UPDATE / roster-slice completion wakes and recomputes it.
    if owner.confirmScanAt and not owner.pendingScan and not (owner.runtime and owner.runtime.rosterRead180) then
        due = MinDue180(due, owner.confirmScanAt, now)
    end
    due = MinDue180(due, owner.craftingInitialSyncAt, now)
    due = MinDue180(due, owner.announcementInitialSyncAt, now)
    due = MinDue180(due, owner.sharedActivityInitialSync156, now)
    due = MinDue180(due, owner.pveSyncAt, now)
    due = MinDue180(due, MapDue180(owner.announcementShareTargets155, now), now)
    -- Treasury timers are transition-gated by their processor. Do not duplicate
    -- their raw deadlines here while the transition barrier is active.
    if not (owner.runtime and owner.runtime.transitionActive176) then
        due = MinDue180(due, MapDue180(owner.treasuryShareTargets170, now), now)
        local treasury = owner.runtime and owner.runtime.treasurySync170
        if type(treasury) == "table" and treasury.active then due = MinDue180(due, (tonumber(treasury.started) or now) + 15, now) end
    end
    due = MinDue180(due, NetworkDue180(owner, now), now)
    due = MinDue180(due, CraftingDue180(owner, now), now)
    due = MinDue180(due, PveDue180(owner, now), now)
    due = MinDue180(due, QualityDue180(owner, now), now)
    due = MinDue180(due, UIDue180(owner, now), now)
    due = MinDue180(due, StatusDue180(owner, now), now)
    return due
end

local function DueNow180(due, now)
    due = tonumber(due)
    now = tonumber(now) or 0
    return due ~= nil and due <= now + 0.001
end

local function HasCraftingWork180(owner, now)
    now = tonumber(now) or SchedulerNow180(owner)
    return DueNow180(CraftingDue180(owner, now), now)
end

local function HasPveWork180(owner, now)
    now = tonumber(now) or SchedulerNow180(owner)
    return DueNow180(PveDue180(owner, now), now)
end

local function HasQualityWork180(owner, now)
    now = tonumber(now) or SchedulerNow180(owner)
    return DueNow180(QualityDue180(owner, now), now)
end

local function AnnouncementDue180(owner, now)
    return MapDue180(owner.announcementShareTargets155, now)
end

local function TreasuryDue180(owner, now)
    if owner.runtime and owner.runtime.transitionActive176 then return nil end
    local due = MapDue180(owner.treasuryShareTargets170, now)
    local sync = owner.runtime and owner.runtime.treasurySync170
    if type(sync) == "table" and sync.active then due = MinDue180(due, (tonumber(sync.started) or now) + 15, now) end
    return due
end

function OTLGM:ScheduleTask180(key, dueAt, callback, priority)
    key = tostring(key or "")
    if key == "" or type(callback) ~= "function" then return false end
    local state = SchedulerState180(self)
    state.tasks[key] = { key = key, due = tonumber(dueAt) or SchedulerNow180(self), callback = callback, priority = tonumber(priority) or 0 }
    self:UpdateSchedulerState180("schedule:" .. key)
    return true
end

-- Relative delays must be based on the same monotonic fractional clock that
-- drives the scheduler.  time()/Now() has whole-second precision on Vanilla;
-- building a 0.02s or 0.25s deadline as Now()+delay can therefore make it
-- already overdue for most of the current second and collapse bounded work
-- back into the same frame.  Keep the absolute API above for already-normalized
-- deadlines and route all ordinary delayed work through this helper.
function OTLGM:ScheduleAfter180(key, delay, callback, priority)
    delay = math.max(0, tonumber(delay) or 0)
    return self:ScheduleTask180(key, SchedulerNow180(self) + delay, callback, priority)
end

function OTLGM:CancelTask180(key)
    local state = SchedulerState180(self)
    state.tasks[tostring(key or "")] = nil
    self:UpdateSchedulerState180("cancel:" .. tostring(key or ""))
end

function OTLGM:WakeScheduler180(reason)
    local state = SchedulerState180(self)
    state.wakeCount = (tonumber(state.wakeCount) or 0) + 1
    if reason and reason ~= "" then
        local rawReason = tostring(reason)
        -- Diagnostic wake reasons used to retain dynamic object/task suffixes for
        -- the whole session. Keep only the stable category so this table cannot
        -- grow with raid ids, character names or transfer keys.
        local separator = string.find(rawReason, ":", 1, true)
        local reasonKey = separator and string.sub(rawReason, 1, separator - 1) or rawReason
        state.reasons[reasonKey] = (tonumber(state.reasons[reasonKey]) or 0) + 1
        state.lastReason = rawReason
        if reasonKey == "ui-debounce" then
            self.runtime = self.runtime or {}
            -- Each keystroke moves the trailing-edge deadline. UIDue180 only
            -- reads this latched value, so unrelated scheduler recomputations
            -- cannot move it and typing cannot be refreshed prematurely.
            self.runtime.uiDebounceDue180 = SchedulerNow180(self) + 0.25
        end
    end

    -- Most wake calls happen while the shared scheduler is already active (for
    -- example while a targeted crafting transfer queues several chunks). A full
    -- CompatibilityDue180 walk on every enqueue is wasted work. Force one cheap
    -- next-frame re-evaluation instead; explicit ScheduleTask180 calls still
    -- update their deadlines synchronously.
    if state.active then
        local now = SchedulerNow180(self)
        if not state.nextCheckAt or state.nextCheckAt == 0 or state.nextCheckAt > now then state.nextCheckAt = now end
        state.pollInterval180 = SCHEDULER_MIN_CHECK_180
        state.pollElapsed180 = SCHEDULER_MIN_CHECK_180
        return
    end
    self:UpdateSchedulerState180(reason or "wake")
end

local function BeginPerformanceSampleSafe180(owner)
    if not owner or type(owner.BeginPerformanceSample180) ~= "function" then return nil end
    local ok, value = pcall(owner.BeginPerformanceSample180, owner)
    if ok then return value end
    if owner.RecordInternalIssueRC3 then pcall(owner.RecordInternalIssueRC3, owner, "Diagnostics/PERF_BEGIN", value) end
    return nil
end

local function EndPerformanceSampleSafe180(owner, label, started)
    if not owner or not started or type(owner.EndPerformanceSample180) ~= "function" then return false end
    local ok, value = pcall(owner.EndPerformanceSample180, owner, label, started)
    if not ok and owner.RecordInternalIssueRC3 then pcall(owner.RecordInternalIssueRC3, owner, "Diagnostics/PERF_END", value) end
    return ok and value or false
end

function OTLGM:ProcessScheduledCompatibilityWork180()
    local now = self:Now()
    local preciseNow = self.GetPreciseTime180 and self:GetPreciseTime180() or now
    local operationStateChanged = PruneOperationStates180(self, now)
    if operationStateChanged and self.IsUIVisible and self:IsUIVisible() and self.RefreshOperationButtons156 then
        local refreshOk, refreshProblem = pcall(self.RefreshOperationButtons156, self)
        if not refreshOk and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "UI/OPERATION_STATE_REFRESH", refreshProblem) end
    end

    -- Compatibility work can be entered because of an unrelated faster queue.
    -- Only touch each pending workflow when its own deadline is actually due.
    -- This is intentionally stricter than merely checking that a subsystem has
    -- future work: a fast network/crafting wake must not collapse UI debounce,
    -- PvE retries, announcement relays or maintenance timers into early polls.
    local rosterAction = self.rosterActionPending180
    if self.ProcessRosterAction180 and rosterAction then
        local rosterDue = false
        if rosterAction.kind == "NOTE" then
            rosterDue = now >= (tonumber(rosterAction.startedAt) or now) + 12
        else
            rosterDue = now >= (tonumber(rosterAction.nextCheckAt) or 0)
                or now >= (tonumber(rosterAction.startedAt) or now) + 15
            if rosterAction.kind == "APPROVE_LION" and rosterAction.phase == 15 and rosterAction.finalStepDue180 then
                rosterDue = rosterDue or preciseNow >= (tonumber(rosterAction.finalStepDue180) or preciseNow)
            end
        end
        if rosterDue then self:ProcessRosterAction180() end
    end
    local recruitment = self.recruitmentDeliveryPending180
    if self.ProcessRecruitmentDelivery180 and recruitment then
        local recruitmentDue = tonumber(recruitment.timeoutAt) or ((tonumber(recruitment.startedAt) or now) + 18)
        if now >= recruitmentDue then self:ProcessRecruitmentDelivery180() end
    end
    local removal = self.rosterRemovalPending180
    if self.ProcessRosterRemoval180 and removal and now >= (tonumber(removal.nextCheckAt) or 0) then
        self:ProcessRosterRemoval180(false)
    end

    if self.confirmScanAt and now >= self.confirmScanAt and not self.pendingScan and not (self.runtime and self.runtime.rosterRead180) then
        self.confirmScanAt = nil
        if self.RequestScan then self:RequestScan("CONFIRM") end
    end
    if self.craftingInitialSyncAt and now >= self.craftingInitialSyncAt then
        self.craftingInitialSyncAt = nil
        if self.RequestCraftingSync then self:RequestCraftingSync(false, false) end
    end
    if self.announcementInitialSyncAt and now >= self.announcementInitialSyncAt then
        self.announcementInitialSyncAt = nil
        if self.RequestAnnouncementSync152 then self:RequestAnnouncementSync152(false) end
    end
    if self.sharedActivityInitialSync156 and now >= self.sharedActivityInitialSync156 then
        self.sharedActivityInitialSync156 = nil
        if self.RequestSharedActivitySync156 then self:RequestSharedActivitySync156(false) end
    end
    if self.pveSyncAt and now >= self.pveSyncAt then
        self.pveSyncAt = nil
        if self.RequestPveSync then self:RequestPveSync(false) end
    end

    local networkDue = NetworkDue180(self, preciseNow)
    if self.ProcessNetworkQueue and DueNow180(networkDue, preciseNow) then
        local started = BeginPerformanceSampleSafe180(self)
        self:ProcessNetworkQueue()
        EndPerformanceSampleSafe180(self, "network queue", started)
    end

    if HasCraftingWork180(self, preciseNow) then
        local started = BeginPerformanceSampleSafe180(self)
        local transferDue = nil
        local transferKey, transfer
        local transferStates = self.runtime and self.runtime.craftingOutboundTransferStates180
        if type(transferStates) == "table" then
            for transferKey, transfer in pairs(transferStates) do
                if type(transfer) == "table" then
                    transferDue = MinDue180(transferDue, transfer.nextAttemptAt or preciseNow, preciseNow)
                else
                    transferStates[transferKey] = nil
                end
            end
        end
        if self.ProcessCraftingOutboundTransfers180 and DueNow180(transferDue, preciseNow) then
            self:ProcessCraftingOutboundTransfers180(10)
        end
        local hydrationDue = MapDue180(self.runtime and self.runtime.craftingIconHydration180, preciseNow)
        if self.ProcessCraftingIconHydration180 and DueNow180(hydrationDue, preciseNow) then
            self:ProcessCraftingIconHydration180(20)
        end
        -- Pack3 originally consumed this job from the old quality heartbeat.
        -- CraftingDue180 is now its scheduler owner, so process it here as well;
        -- otherwise the job advertises due-now forever while no quality deadline
        -- exists to clear it. The processor clears the job before the actual scan,
        -- making a scan exception non-repeating.
        if self.runtime and self.runtime.deferredProfessionScanPack3_180 and self.ProcessDeferredProfessionScanPack3_180 then
            local deferredOk, deferredProblem = pcall(self.ProcessDeferredProfessionScanPack3_180, self)
            if not deferredOk and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Crafting/DEFERRED_PROFESSION", deferredProblem) end
        end
        if self.ProcessCraftingTimers then self:ProcessCraftingTimers() end
        EndPerformanceSampleSafe180(self, "crafting sync", started)
    end

    local announcementDue = AnnouncementDue180(self, preciseNow)
    if self.ProcessAnnouncementTimers155 and DueNow180(announcementDue, preciseNow) then self:ProcessAnnouncementTimers155() end
    local treasuryDue = TreasuryDue180(self, preciseNow)
    if self.ProcessTreasuryTimers170 and DueNow180(treasuryDue, preciseNow) then self:ProcessTreasuryTimers170() end

    if HasPveWork180(self, preciseNow) then
        local started = BeginPerformanceSampleSafe180(self)
        local runtime = self.runtime and self.runtime.pve
        local pve = PveDBNoCreate180(self)
        local groupMatchDue = MapDue180(runtime and runtime.pendingGroupMatchEval180, preciseNow)
        if self.ProcessPveGroupMatching180 and DueNow180(groupMatchDue, preciseNow) then self:ProcessPveGroupMatching180() end
        if self.ProcessPveGroupLiveState180 and runtime and DueNow180(runtime.groupLiveStateDue180, preciseNow) then self:ProcessPveGroupLiveState180() end
        local applicationDue = MapDue180(pve and pve.applicationRetries, preciseNow)
        if self.ProcessPveApplicationRetries155 and DueNow180(applicationDue, preciseNow) then self:ProcessPveApplicationRetries155() end
        local membershipDue = MapDue180(self.runtime and self.runtime.raidTeamMembershipPending180, preciseNow)
        if self.ProcessRaidTeamMembershipNotifications180 and DueNow180(membershipDue, preciseNow) then self:ProcessRaidTeamMembershipNotifications180() end
        local syncDue = type(self.pveSyncPending180) == "table" and ((tonumber(self.pveSyncPending180.startedAt) or preciseNow) + 18) or nil
        if self.pveSyncPending180 ~= nil and type(self.pveSyncPending180) ~= "table" then self.pveSyncPending180 = nil end
        if self.ProcessPveSyncState180 and DueNow180(syncDue, preciseNow) then self:ProcessPveSyncState180() end
        EndPerformanceSampleSafe180(self, "PvE matching/live state", started)
    end

    local statusDue = StatusDue180(self, preciseNow)
    if self.ProcessStatus170 and DueNow180(statusDue, preciseNow) then self:ProcessStatus170() end
    local uiDue = UIDue180(self, preciseNow)
    if self.ProcessUIDebounce and DueNow180(uiDue, preciseNow) then
        -- Clear the latch before entering page code. If a page refresh fails, the
        -- still-dirty flag schedules one bounded retry instead of a zero-delay
        -- compatibility loop.
        if self.runtime then self.runtime.uiDebounceDue180 = nil end
        self:ProcessUIDebounce(0.25)
    end
    if self.ProcessQuality156Timers and HasQualityWork180(self, preciseNow) then
        local started = BeginPerformanceSampleSafe180(self)
        self:ProcessQuality156Timers()
        EndPerformanceSampleSafe180(self, "achievement checkpoints", started)
    end
end

function OTLGM:UpdateSchedulerState180(reason)
    local state = SchedulerState180(self)
    local now = SchedulerNow180(self)
    local compatDue = CompatibilityDue180(self, now)
    -- A persistent exception in one compatibility subsystem must not turn the
    -- sleeping scheduler into a per-frame error loop. Preserve the work, but
    -- retry the shared compatibility slice with a short bounded backoff.
    local compatibilityBackoff = tonumber(state.compatibilityBackoffUntil180)
    if compatDue and compatibilityBackoff and compatibilityBackoff > now and compatDue < compatibilityBackoff then
        compatDue = compatibilityBackoff
    elseif compatibilityBackoff and compatibilityBackoff <= now then
        state.compatibilityBackoffUntil180 = nil
    end
    if compatDue then
        state.tasks["__compatibility180"] = {
            key = "__compatibility180", due = compatDue, priority = -100,
            callback = function(owner) owner:ProcessScheduledCompatibilityWork180() end,
        }
    else
        state.tasks["__compatibility180"] = nil
    end

    local nearestDue, nearestKey, key, task
    for key, task in pairs(state.tasks) do
        if type(task) == "table" and type(task.callback) == "function" then
            local due = tonumber(task.due) or now
            if not nearestDue or due < nearestDue or (due == nearestDue and (tonumber(task.priority) or 0) > (tonumber(state.tasks[nearestKey] and state.tasks[nearestKey].priority) or 0)) then
                nearestDue, nearestKey = due, key
            end
        else
            state.tasks[key] = nil
        end
    end
    state.nearestDue = nearestDue
    state.nearestKey = nearestKey
    state.nextCheckAt = nearestDue or 0
    if nearestDue then
        local remaining = math.max(0, nearestDue - now)
        state.pollInterval180 = math.max(SCHEDULER_MIN_CHECK_180, math.min(0.25, remaining))
        if not state.active then
            state.active = true
            state.pollElapsed180 = 0
            eventFrame:SetScript("OnUpdate", SchedulerOnUpdate180)
        elseif remaining <= SCHEDULER_MIN_CHECK_180 then
            -- A newly queued urgent task must not wait behind a previous coarse
            -- sleep interval chosen for a far-future deadline.
            state.pollElapsed180 = state.pollInterval180
        end
    elseif state.active then
        state.active = false
        state.pollElapsed180 = 0
        state.pollInterval180 = SCHEDULER_MIN_CHECK_180
        state.sleepCount = (tonumber(state.sleepCount) or 0) + 1
        eventFrame:SetScript("OnUpdate", nil)
    end
end

function OTLGM:GetSchedulerDiagnostics180()
    local state = SchedulerState180(self)
    local count = 0
    local _
    for _ in pairs(state.tasks or {}) do count = count + 1 end
    return {
        active = state.active and true or false, taskCount = count,
        nearestKey = state.nearestKey, nearestDue = state.nearestDue,
        wakeCount = state.wakeCount or 0, sleepCount = state.sleepCount or 0,
        executed = state.executed or 0, errors = state.errors or 0,
        compatibilityFailures = state.compatibilityFailures180 or 0,
        compatibilityBackoffUntil = state.compatibilityBackoffUntil180,
        lastReason = state.lastReason, lastError = state.lastError, lastErrorKey = state.lastErrorKey,
    }
end

local function IsRosterConsumerVisible180(owner)
    local ui = owner and owner.ui
    if not ui or not ui.main or not ui.main.IsVisible or not ui.main:IsVisible() then return false end
    local page = ui.currentPage
    return page == "home" or page == "roster" or page == "overview"
end

local function ScheduleVisibleRosterEventScan180(owner)
    if not owner then return false end
    owner.runtime = owner.runtime or {}
    owner.runtime.rosterDataDirty180 = true
    local metrics = owner.runtime.rosterMetrics180 or { fullScans = 0, targetedRefreshes = 0, reasons = {} }
    owner.runtime.rosterMetrics180 = metrics
    metrics.guildEventsDirty = (tonumber(metrics.guildEventsDirty) or 0) + 1
    if not IsRosterConsumerVisible180(owner) then return false end
    if OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.autoScan == false then return false end
    if (tonumber(owner.runtime.rosterAutoRetryAfterRC3) or 0) > owner:Now() then return false end
    if not owner.ScheduleAfter180 then return false end
    if owner.runtime.scheduler180 and owner.runtime.scheduler180.tasks and owner.runtime.scheduler180.tasks["guild-roster-visible-scan"] then
        metrics.guildEventsCoalesced = (tonumber(metrics.guildEventsCoalesced) or 0) + 1
    end
    owner:ScheduleAfter180("guild-roster-visible-scan", 1, function(current)
        if not current.runtime or not current.runtime.rosterDataDirty180 then return end
        if not IsRosterConsumerVisible180(current) then return end
        if current.pendingScan or current.runtime.rosterRead180 then return end
        if (tonumber(current.runtime.rosterAutoRetryAfterRC3) or 0) > current:Now() then return end
        current:RequestScan("GUILD_EVENT")
    end, 35)
    return true
end

local function RunStableLoginBaseline180(owner)
    if not owner then return end
    if (owner.InCombat and owner:InCombat()) or (owner.runtime and (owner.runtime.transitionActive176 or owner.runtime.rosterRead180)) or owner.pendingScan then
        owner:ScheduleAfter180("achievement-login-baseline", 5, RunStableLoginBaseline180, 10)
        return
    end
    owner.runtime = owner.runtime or {}
    local failed = false
    if owner.RunAchievementLoginBaseline180 then
        local ok, problem = pcall(owner.RunAchievementLoginBaseline180, owner)
        if not ok then
            failed = true
            if owner.RecordInternalIssueRC3 then pcall(owner.RecordInternalIssueRC3, owner, "Login/ACHIEVEMENT_BASELINE", problem) end
        end
    end
    if owner.RunRelease175LoginBaseline180 then
        local ok, problem = pcall(owner.RunRelease175LoginBaseline180, owner)
        if not ok then
            failed = true
            if owner.RecordInternalIssueRC3 then pcall(owner.RecordInternalIssueRC3, owner, "Login/RELEASE_BASELINE", problem) end
        end
    end
    if failed then
        local retries = math.min(2, (tonumber(owner.runtime.loginBaselineRetries180) or 0) + 1)
        owner.runtime.loginBaselineRetries180 = retries
        if retries < 2 and owner.ScheduleAfter180 then
            owner:ScheduleAfter180("achievement-login-baseline", 10, RunStableLoginBaseline180, 10)
        end
    else
        owner.runtime.loginBaselineRetries180 = 0
    end
end

SchedulerOnUpdate180 = function()
    if not OTLGM then return end
    local state = SchedulerState180(OTLGM)
    local elapsed = tonumber(arg1) or SCHEDULER_MIN_CHECK_180
    if elapsed < 0 or elapsed > 10 then elapsed = SCHEDULER_MIN_CHECK_180 end
    state.pollElapsed180 = (tonumber(state.pollElapsed180) or 0) + elapsed
    local interval = math.max(SCHEDULER_MIN_CHECK_180, tonumber(state.pollInterval180) or SCHEDULER_MIN_CHECK_180)
    if state.pollElapsed180 < interval then return end
    state.pollElapsed180 = 0

    local now = SchedulerNow180(OTLGM)
    if (tonumber(state.nextCheckAt) or 0) > now then
        local remaining = (tonumber(state.nextCheckAt) or now) - now
        state.pollInterval180 = math.max(SCHEDULER_MIN_CHECK_180, math.min(0.25, remaining))
        return
    end
    local ready = {}
    local key, task
    for key, task in pairs(state.tasks or {}) do
        if type(task) == "table" and (tonumber(task.due) or now) <= now then table.insert(ready, task) end
    end
    table.sort(ready, function(left, right)
        local lp, rp = tonumber(left.priority) or 0, tonumber(right.priority) or 0
        if lp ~= rp then return lp > rp end
        local ld, rd = tonumber(left.due) or 0, tonumber(right.due) or 0
        if ld ~= rd then return ld < rd end
        return tostring(left.key) < tostring(right.key)
    end)
    local limit = math.min(SCHEDULER_TASK_LIMIT_180, table.getn(ready))
    local index
    for index = 1, limit do
        task = ready[index]
        state.tasks[task.key] = nil
        local ok, problem = pcall(task.callback, OTLGM, task.key)
        state.executed = (tonumber(state.executed) or 0) + 1
        if task.key == "__compatibility180" then
            if ok then
                state.compatibilityFailures180 = 0
                state.compatibilityBackoffUntil180 = nil
            else
                local failures = math.min(6, (tonumber(state.compatibilityFailures180) or 0) + 1)
                state.compatibilityFailures180 = failures
                state.compatibilityBackoffUntil180 = now + math.min(16, 0.5 * (2 ^ math.max(0, failures - 1)))
            end
        end
        if not ok then
            state.errors = (tonumber(state.errors) or 0) + 1
            state.lastError = tostring(problem or "scheduler callback failed")
            state.lastErrorKey = task.key
            if OTLGM.RecordInternalIssueRC3 then pcall(OTLGM.RecordInternalIssueRC3, OTLGM, "Scheduler/" .. tostring(task.key), state.lastError) end
            if OTLGM.RecordPerformanceSpike180 then pcall(OTLGM.RecordPerformanceSpike180, OTLGM, "scheduler:" .. tostring(task.key), 0) end
        end
    end
    local updateOk, updateProblem = pcall(OTLGM.UpdateSchedulerState180, OTLGM, "slice")
    if not updateOk then
        state.active = false
        state.pollElapsed180 = 0
        eventFrame:SetScript("OnUpdate", nil)
        state.errors = (tonumber(state.errors) or 0) + 1
        state.lastError = tostring(updateProblem or "scheduler state update failed")
        state.lastErrorKey = "__scheduler_state180"
        if OTLGM.RecordInternalIssueRC3 then pcall(OTLGM.RecordInternalIssueRC3, OTLGM, "Scheduler/STATE_UPDATE", state.lastError) end
    end
end
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CHANNEL_NOTICE")
eventFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("CHAT_MSG_GUILD")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
eventFrame:RegisterEvent("CHAT_MSG_OFFICER")
eventFrame:RegisterEvent("TRADE_SKILL_SHOW")
eventFrame:RegisterEvent("CRAFT_SHOW")
eventFrame:RegisterEvent("TRADE_SKILL_UPDATE")
eventFrame:RegisterEvent("CRAFT_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

local function SafeEventCallRC4(source, callback)
    if type(callback) ~= "function" then return false end
    local ok, problem = pcall(callback)
    if not ok and OTLGM and OTLGM.RecordInternalIssueRC3 then pcall(OTLGM.RecordInternalIssueRC3, OTLGM, "Event/" .. tostring(source or "unknown"), problem) end
    return ok
end

-- Guild chat is a primary user-facing stream.  If a later presentation wrapper
-- ever errors, fall back to the canonical capture implementation for that one
-- event instead of silently losing the message.
local function CaptureGuildChatEventRC5(channel, message, sender)
    if not OTLGM then return false end

    local function LastCapturedMessage180()
        if type(OTLGM.GetGuildChatMessages) ~= "function" then return nil end
        local ok, messages = pcall(OTLGM.GetGuildChatMessages, OTLGM, channel)
        if ok and type(messages) == "table" then return messages[table.getn(messages)] end
        return nil
    end

    local function RecoverGuildChatPresentation180(beforeLast)
        local afterLast = LastCapturedMessage180()
        if afterLast == beforeLast then return false end
        if OTLGM.ui and OTLGM.ui.main and OTLGM.ui.main:IsVisible() and OTLGM.ui.currentPage == "guildchat"
            and type(OTLGM.RefreshGuildChatPage) == "function" then
            local refreshOk, refreshProblem = pcall(OTLGM.RefreshGuildChatPage, OTLGM, "event-recovery")
            if not refreshOk and OTLGM.RecordInternalIssueRC3 then
                pcall(OTLGM.RecordInternalIssueRC3, OTLGM, "Event/CHAT_REFRESH_RECOVERY", refreshProblem)
            end
        end
        return true
    end

    local beforeLast = LastCapturedMessage180()
    if type(OTLGM.CaptureGuildChatMessage) == "function" then
        local ok, result = pcall(OTLGM.CaptureGuildChatMessage, OTLGM, channel, message, sender)
        if ok then return result ~= false end
        if OTLGM.RecordInternalIssueRC3 then pcall(OTLGM.RecordInternalIssueRC3, OTLGM, "Event/CHAT_CAPTURE_WRAPPER", result) end
        -- Presentation/notification code may fail after the record was already
        -- appended. Detect that before trying the canonical implementation so
        -- the bounded history never receives the same event twice.
        if RecoverGuildChatPresentation180(beforeLast) then return true end
    end

    local fallback = OTLGM.__impl180 and OTLGM.__impl180.CaptureGuildChatMessage__impl1
    if type(fallback) == "function" then
        local ok, result = pcall(fallback, OTLGM, channel, message, sender)
        if ok then
            if result ~= false then RecoverGuildChatPresentation180(beforeLast) end
            return result ~= false
        end
        if OTLGM.RecordInternalIssueRC3 then pcall(OTLGM.RecordInternalIssueRC3, OTLGM, "Event/CHAT_CAPTURE_FALLBACK", result) end
        -- Even the canonical path can append before a later side effect errors.
        -- Preserve and present that message instead of reporting a false loss.
        if RecoverGuildChatPresentation180(beforeLast) then return true end
    end
    return false
end

eventFrame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        if OTLGM and OTLGM.EnsureDB then SafeEventCallRC4("VARIABLES_DB", function() OTLGM:EnsureDB() end) end
        if OTLGM and OTLGM.ResetSessionData then SafeEventCallRC4("VARIABLES_SESSION", function() OTLGM:ResetSessionData() end) end
    elseif event == "PLAYER_LOGIN" then
        if not OTLGM then
            PrintLine("The addon bootstrap did not load.", true)
            return
        end
        if OTLGM.EnsureDB then SafeEventCallRC4("LOGIN_DB", function() OTLGM:EnsureDB() end) end
        if OTLGM.InstallTooltipCompatibility160 then SafeEventCallRC4("LOGIN_TOOLTIP", function() OTLGM:InstallTooltipCompatibility160() end) end
        if OTLGM.InstallInviteHook then SafeEventCallRC4("LOGIN_INVITE_HOOK", function() OTLGM:InstallInviteHook() end) end
        if OTLGM.InstallGuildActionHooks then SafeEventCallRC4("LOGIN_GUILD_HOOKS", function() OTLGM:InstallGuildActionHooks() end) end
        if OTLGM.BuildMinimapButton then
            local ok, err = pcall(function() OTLGM:BuildMinimapButton() end)
            if not ok then PrintLine("Minimap runtime error: " .. tostring(err), true) end
        end
        if OTLGM.__impl180.BroadcastVersion__impl1 then SafeEventCallRC4("LOGIN_VERSION", function() OTLGM:BroadcastVersion() end) end
        -- Hooks are cheap and must be ready immediately; wide achievement checks
        -- run once after the 30-second loading/cold-cache window instead. Each
        -- subsystem is isolated so one optional integration cannot abort the
        -- remainder of PLAYER_LOGIN and leave the addon half-initialized.
        if OTLGM.InstallAchievements174 then SafeEventCallRC4("LOGIN_ACHIEVEMENTS", function() OTLGM:InstallAchievements174() end) end
        if OTLGM.InstallEmoteHook175 then SafeEventCallRC4("LOGIN_EMOTE_HOOK", function() OTLGM:InstallEmoteHook175() end) end
        if OTLGM.InstallCraftHooks175 then SafeEventCallRC4("LOGIN_CRAFT_HOOKS", function() OTLGM:InstallCraftHooks175() end) end
        if OTLGM.InitializePveSync then SafeEventCallRC4("LOGIN_PVE", function() OTLGM:InitializePveSync() end) end
        if OTLGM.EnsureCraftingDB then SafeEventCallRC4("LOGIN_CRAFT_DB", function() OTLGM:EnsureCraftingDB() end) end
        local loginJitter180 = math.random and math.random(0, 6) or 3
        if OTLGM.__impl180.RequestCraftingSync__impl1 then OTLGM.craftingInitialSyncAt = OTLGM:Now() + 10 + loginJitter180 end
        if OTLGM.RequestAnnouncementSync152 then OTLGM.announcementInitialSyncAt = OTLGM:Now() + 7 + loginJitter180 end
        if OTLGM.DetectWorldChannel153 then SafeEventCallRC4("LOGIN_WORLD_CHANNEL", function() OTLGM:DetectWorldChannel153(true) end) end
        if OTLGM.RequestSharedActivitySync156 then OTLGM.sharedActivityInitialSync156 = OTLGM:Now() + 12 + loginJitter180 end
        if OTLGM.InvalidateSenderRosterCache180 then SafeEventCallRC4("LOGIN_SENDER_CACHE", function() OTLGM:InvalidateSenderRosterCache180() end) end
        if OTLGM.ScheduleAfter180 and type(OTLGM.RequestScan) == "function" then
            OTLGM:ScheduleAfter180("initial-roster-scan", 4 + loginJitter180, function(owner)
                if GetGuildInfo and GetGuildInfo("player") then owner:RequestScan("LOGIN") end
            end, 40)
        elseif type(OTLGM.RequestScan) == "function" and GetGuildInfo("player") then OTLGM:RequestScan("LOGIN") end
        if OTLGM.ScheduleAfter180 and (OTLGM.RunAchievementLoginBaseline180 or OTLGM.RunRelease175LoginBaseline180) then
            OTLGM:ScheduleAfter180("achievement-login-baseline", 32 + loginJitter180, RunStableLoginBaseline180, 10)
        end
        if not OTLGM.systems152Loaded then PrintLine("The community module did not load; shared-data features are unavailable.", true) end
        if not OTLGM.fullUILoaded or type(OTLGM.ToggleUI) ~= "function" then
            PrintLine("Full UI did not load. Type /otltest for details.", true)
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "CHANNEL_NOTICE" then
        if event == "PLAYER_ENTERING_WORLD" and OTLGM and OTLGM.InstallTooltipCompatibility160 then
            SafeEventCallRC4("WORLD_TOOLTIP", function() OTLGM:InstallTooltipCompatibility160() end)
        end
        if OTLGM and OTLGM.DetectWorldChannel153 then SafeEventCallRC4("WORLD_CHANNEL", function() OTLGM:DetectWorldChannel153(true) end) end
        if event == "PLAYER_ENTERING_WORLD" and OTLGM and OTLGM.ui and OTLGM.ui.main and OTLGM.RebaseUIParentGeometry180 then
            -- Most zone transitions do not alter UIParent. Rebase only when the
            -- logical size/effective scale really changed; this avoids repeating
            -- all responsive page layouts while the addon is idle or hidden.
            SafeEventCallRC4("UI_PARENT_REBASE", function() OTLGM:RebaseUIParentGeometry180("world", false) end)
            -- A few UI replacements finalize UIParent one event later. Keep one
            -- sleeping scheduler check, but it becomes a no-op unless the host
            -- metrics actually changed during that second.
            if OTLGM.ScheduleAfter180 then
                OTLGM:ScheduleAfter180("ui-parent-rebase", 1, function(owner)
                    if owner.RebaseUIParentGeometry180 then owner:RebaseUIParentGeometry180("world-delayed", false) end
                end, 85)
            end
        end
        if OTLGM and OTLGM.ui and OTLGM.ui.currentPage == "recruitment" and OTLGM.__impl180.RefreshRecruitmentPage__impl1 then SafeEventCallRC4("RECRUITMENT_WORLD_REFRESH", function() OTLGM:RefreshRecruitmentPage() end) end
    elseif event == "CHAT_MSG_SYSTEM" then
        if OTLGM and OTLGM.TryCaptureSystemGuildAction then SafeEventCallRC4("CHAT_MSG_SYSTEM", function() OTLGM:TryCaptureSystemGuildAction(arg1) end) end
    elseif event == "CHAT_MSG_ADDON" then
        if OTLGM and OTLGM.HandleAddonMessage then
            local started = BeginPerformanceSampleSafe180(OTLGM)
            if OTLGM.RecordPerformancePacket180 then pcall(OTLGM.RecordPerformancePacket180, OTLGM, "IN", arg2) end
            SafeEventCallRC4("CHAT_MSG_ADDON", function() OTLGM:HandleAddonMessage(arg1, arg2, arg3, arg4) end)
            EndPerformanceSampleSafe180(OTLGM, "sender validation", started)
        end
    elseif event == "CHAT_MSG_GUILD" then
        -- Recruitment echo tracking is secondary. It must never be able to stop
        -- canonical Guild Chat capture for the same client event.
        if OTLGM and OTLGM.HandleRecruitmentDeliveryEcho180 then SafeEventCallRC4("GUILD_RECRUIT_ECHO", function() OTLGM:HandleRecruitmentDeliveryEcho180("GUILD", arg1, arg2) end) end
        if OTLGM then SafeEventCallRC4("CHAT_MSG_GUILD", function() CaptureGuildChatEventRC5("GUILD", arg1, arg2) end) end
    elseif event == "CHAT_MSG_CHANNEL" then
        if OTLGM and OTLGM.HandleRecruitmentDeliveryEcho180 then SafeEventCallRC4("CHANNEL_RECRUIT_ECHO", function() OTLGM:HandleRecruitmentDeliveryEcho180("WORLD", arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) end) end
    elseif event == "CHAT_MSG_OFFICER" then
        if OTLGM then SafeEventCallRC4("CHAT_MSG_OFFICER", function() CaptureGuildChatEventRC5("OFFICER", arg1, arg2) end) end
    elseif event == "TRADE_SKILL_SHOW" then
        if OTLGM and OTLGM.__impl180.ScanCurrentProfession__impl1 then SafeEventCallRC4("TRADE_SKILL_SHOW", function() OTLGM:ScanCurrentProfession("TRADE", 0) end) end
    elseif event == "CRAFT_SHOW" then
        if OTLGM and OTLGM.__impl180.ScanCurrentProfession__impl1 then SafeEventCallRC4("CRAFT_SHOW", function() OTLGM:ScanCurrentProfession("CRAFT", 0) end) end
    elseif event == "TRADE_SKILL_UPDATE" then
        if OTLGM and OTLGM.ScheduleProfessionRescan then SafeEventCallRC4("TRADE_SKILL_UPDATE", function() OTLGM:ScheduleProfessionRescan("TRADE", 2, 0.6) end) end
    elseif event == "CRAFT_UPDATE" then
        if OTLGM and OTLGM.ScheduleProfessionRescan then SafeEventCallRC4("CRAFT_UPDATE", function() OTLGM:ScheduleProfessionRescan("CRAFT", 2, 0.6) end) end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if OTLGM and OTLGM.WakeScheduler180 then SafeEventCallRC4("COMBAT_ENDED_WAKE", function() OTLGM:WakeScheduler180("combat-ended") end) end
    elseif event == "PLAYER_GUILD_UPDATE" then
        if OTLGM and OTLGM.runtime then OTLGM.runtime.guildPermissionFlags170 = nil end
        if OTLGM and OTLGM.__impl180.RefreshSenderRosterCache__impl1 then SafeEventCallRC4("GUILD_SENDER_CACHE", function() OTLGM:RefreshSenderRosterCache(true) end) end
        if OTLGM and OTLGM.__impl180.BroadcastVersion__impl1 then SafeEventCallRC4("GUILD_VERSION", function() OTLGM:BroadcastVersion() end) end
        if OTLGM and OTLGM.RequestPveSync then SafeEventCallRC4("GUILD_PVE_SYNC", function() OTLGM:RequestPveSync(true) end) end
        if OTLGM and type(OTLGM.RequestCraftingSync) == "function" then SafeEventCallRC4("GUILD_CRAFT_SYNC", function() OTLGM:RequestCraftingSync(true) end) end
        if OTLGM and OTLGM.RequestAnnouncementSync152 then SafeEventCallRC4("GUILD_ANNOUNCEMENT_SYNC", function() OTLGM:RequestAnnouncementSync152(true) end) end
        if OTLGM and OTLGM.__impl180.RefreshNavigation__impl1 then SafeEventCallRC4("GUILD_NAVIGATION", function() OTLGM:RefreshNavigation() end) end
    elseif event == "GUILD_ROSTER_UPDATE" then
        if OTLGM and OTLGM.runtime then
            OTLGM.runtime.guildPermissionFlags170 = nil
            OTLGM.runtime.guildLeaderR6 = nil
        end
        if OTLGM and OTLGM.RefreshActiveRaidInviteSessions180 then SafeEventCallRC4("ROSTER_RAID_INVITES", function() OTLGM:RefreshActiveRaidInviteSessions180(true) end) end
        local targetedRankName
        local targetedRankOnly = false
        if OTLGM and OTLGM.rosterActionPending180 and OTLGM.rosterActionPending180.targeted180 and not OTLGM.pendingScan then
            targetedRankName = OTLGM.rosterActionPending180.name
            targetedRankOnly = true
        end
        if OTLGM and OTLGM.ConfirmRosterActionUpdate180 and OTLGM.rosterActionPending180 then SafeEventCallRC4("ROSTER_ACTION_CONFIRM", function() OTLGM:ConfirmRosterActionUpdate180() end) end
        if OTLGM and OTLGM.ProcessRosterRemoval180 and OTLGM.rosterRemovalPending180 then SafeEventCallRC4("ROSTER_REMOVAL_CONFIRM", function() OTLGM:ProcessRosterRemoval180(true) end) end
        if OTLGM and OTLGM.InvalidateSenderRosterCache180 then SafeEventCallRC4("ROSTER_SENDER_CACHE", function() OTLGM:InvalidateSenderRosterCache180() end) end
        if OTLGM and OTLGM.runtime then OTLGM.runtime.globalSearchRosterIndexRC4 = nil end
        local fullScanStarted180 = false
        if OTLGM and OTLGM.pendingScan then
            local reason = OTLGM.pendingScanReason or "INTERNAL"
            OTLGM.pendingScan = false
            OTLGM.pendingScanReason = nil
            if OTLGM.BeginRosterScan180 then
                local scanOk, scanResult = pcall(OTLGM.BeginRosterScan180, OTLGM, reason)
                if scanOk then
                    fullScanStarted180 = scanResult and true or false
                elseif OTLGM.RecordInternalIssueRC3 then
                    pcall(OTLGM.RecordInternalIssueRC3, OTLGM, "Event/ROSTER_SCAN_BEGIN", scanResult)
                end
            else
                -- Never fall back to a synchronous 780+ member read. A missing
                -- sliced reader is a module-load error, not permission to freeze
                -- the client in the roster event callback.
                if OTLGM.SetOperationState156 then OTLGM:SetOperationState156("ROSTER", "ERROR", "Bounded roster reader is unavailable", 6) end
                if OTLGM.__impl180.SetStatus__impl1 then OTLGM:SetStatus("Roster update could not start because the bounded reader is unavailable.") end
            end
        end
        if not fullScanStarted180 and OTLGM then
            if targetedRankOnly and targetedRankName and OTLGM.ui and OTLGM.ui.currentPage == "roster" and OTLGM.RefreshRosterTarget180 then
                local started = BeginPerformanceSampleSafe180(OTLGM)
                SafeEventCallRC4("ROSTER_TARGET_REFRESH", function() OTLGM:RefreshRosterTarget180(targetedRankName) end)
                EndPerformanceSampleSafe180(OTLGM, "roster targeted refresh", started)
            elseif not targetedRankOnly then
                -- An unsolicited roster event only marks hidden data dirty. If a
                -- roster-consuming page is visible, one keyed scan is scheduled;
                -- event storms replace the same task instead of rebuilding rows.
                SafeEventCallRC4("ROSTER_VISIBLE_SCAN", function() ScheduleVisibleRosterEventScan180(OTLGM) end)
            end
        end
        if OTLGM and OTLGM.OnGuildRosterUpdatedRecruitmentC5R4 then SafeEventCallRC4("ROSTER_RECRUITMENT", function() OTLGM:OnGuildRosterUpdatedRecruitmentC5R4() end) end
    end
    if OTLGM and OTLGM.UpdateSchedulerState180 then
        local schedulerOk, schedulerProblem = pcall(OTLGM.UpdateSchedulerState180, OTLGM, "event:" .. tostring(event or "unknown"))
        if not schedulerOk and OTLGM.RecordInternalIssueRC3 then pcall(OTLGM.RecordInternalIssueRC3, OTLGM, "Scheduler/EVENT_UPDATE", schedulerProblem) end
    end
end)

-- The scheduler is installed only while work exists. At file load the event
-- frame has no OnUpdate script and therefore costs nothing in steady idle.
OTLGM:UpdateSchedulerState180("module-load")

OTLGM:RegisterModule("Events", { layer = "core", scheduler = "keyed-sleeping", idleOnUpdateNil = true })
