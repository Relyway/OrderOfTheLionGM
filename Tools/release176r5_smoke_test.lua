-- Focused runtime smoke test for the final 1.7.6 R5 layer.
if not table.getn then table.getn = function(t) return #t end end
if not math.mod then math.mod = function(a, b) return a % b end end

local root = arg and arg[1] or "."
local now = 1700000000
local function assertTrue(value, message)
    if not value then error(message or "assertion failed") end
end
local function assertEqual(actual, expected, message)
    if actual ~= expected then error((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual)) end
end

function time() return now end
function GetTime() return now end
function date() return "14 Nov 22:13" end
function UnitName(unit) if unit == "player" then return "Luck" end return nil end
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
SlashCmdList = {}
OTLGM_DB = { settings = {} }

local mainVisible = false
local main = { IsVisible = function() return mainVisible end }
local baseCalls = {}
local invited = {}
local notices = {}
local memberNames = {}
local queuedPayloads = {}
local achievementDb = { counters={}, completed={} }
local treasury = {
    goals = {
        BANK = { id="BANK", name="Guild Bank Purchase", current=300000, target=20000000, revision=2, updatedAt=now-10, updatedBy="Luck", category="BANK" },
    },
    history = {
        { id="BANK", name="Guild Bank Purchase", current=300000, target=20000000, ts=now-100, actor="Luck", kind="UPDATE" },
    },
    contributions176 = {
        BANK = {
            { id="old-1", ts=now-90, actor="Luck", contributor="Tokmek", amount=50000, note="First", current=50000 },
            { id="old-2", ts=now-80, actor="Luck", contributor="Tokmek", amount=100000, note="Second", current=150000 },
            { id="old-3", ts=now-70, actor="Luck", contributor="Amogog", amount=150000, note="Third", current=300000 },
        },
    },
    contributionSeen176 = {},
}

OTLGM = {
    version = "1.7.6",
    build = "performance-r4-ultrasafe-20260725",
    runtime = {},
    ui = { main=main, currentPage="home" },
    colors = { gold="", white="", reset="" },
    achievements174 = { catalog={}, byId={}, catalogRevision=0 },
    registeredModules = {},
}

function OTLGM:Now() return now end
function OTLGM:SafeText(value, maximum)
    value = tostring(value or "")
    value = string.gsub(value, "[%c]", " ")
    if maximum and string.len(value) > maximum then value = string.sub(value, 1, maximum) end
    return value
end
function OTLGM:RegisterModule(name, info) self.registeredModules[name]=info end
function OTLGM:PrepareInteractiveControl170() end
function OTLGM:SetControlEnabled170(button, enabled, reason) button.disabled = not enabled button.disabledReason = reason end
function OTLGM:ApplyButtonSkin() end
function OTLGM:SetStatus(text) self.lastStatus = text end
function OTLGM:ShowNotice(title, text) table.insert(notices, title .. ":" .. text) end
function OTLGM:IsGuildLeader170() return false end
function OTLGM:IsOfficerMode() return true end
function OTLGM:GetMember(name) return memberNames[string.lower(name or "")] end
function OTLGM:GetClassColor() return "" end
function OTLGM:EnsureAchievements174() return achievementDb end
function OTLGM:CompleteAchievement174(id) if achievementDb.completed[id] then return false end achievementDb.completed[id]={unlockedAt=now} return true end
function OTLGM:IsAchievementComplete174(id) return achievementDb.completed[id]~=nil end
function OTLGM:IsPveLeadershipName() return true end
function OTLGM:QueueNetworkPayload(payload, channel, target) table.insert(queuedPayloads,{payload=payload,channel=channel,target=target}) return true end
function OTLGM:Split(value, delimiter)
    local result, startAt = {}, 1
    delimiter = delimiter or "^"
    while true do
        local found = string.find(value or "", delimiter, startAt, true)
        if not found then table.insert(result, string.sub(value or "", startAt)) break end
        table.insert(result, string.sub(value or "", startAt, found - 1))
        startAt = found + string.len(delimiter)
    end
    return result
end
function CanGuildInvite() return true end
function GuildInvite(name) table.insert(invited, name) end

-- Base performance functions captured and wrapped by R5.
function OTLGM:ScheduleMailboxScan176() baseCalls.mailSchedule = (baseCalls.mailSchedule or 0) + 1 return true end
function OTLGM:ProcessMailboxScan176() baseCalls.mailProcess = (baseCalls.mailProcess or 0) + 1 return true end
function OTLGM:ProcessIncrementalBagScan176() baseCalls.bag = (baseCalls.bag or 0) + 1 return true end
function OTLGM:ProcessNetworkQueue(maximum) baseCalls.networkMaximum = maximum return maximum end
function OTLGM:InCombat() return false end

local function baseRefresh(name)
    return function(self) baseCalls[name] = (baseCalls[name] or 0) + 1 return true end
end
OTLGM.RefreshHomePage = baseRefresh("home")
OTLGM.RefreshOverviewPage = baseRefresh("overview")
OTLGM.RefreshRosterPage = baseRefresh("roster")
OTLGM.RefreshProfessionsPage = baseRefresh("professions")
OTLGM.RefreshPvePage = baseRefresh("pve")
OTLGM.RefreshGuildChatPage = baseRefresh("guildchat")
OTLGM.RefreshActivityPage = baseRefresh("activity")
OTLGM.RefreshRecruitmentPage = baseRefresh("recruitment")
OTLGM.RefreshHistoryPage = baseRefresh("history")
OTLGM.RefreshInactivePage = baseRefresh("inactive")
OTLGM.RefreshAchievements174 = baseRefresh("achievements")
OTLGM.RefreshTreasuryPage170 = function(self) baseCalls.treasury = (baseCalls.treasury or 0) + 1 return true end
OTLGM.RefreshNavigation = baseRefresh("navigation")
OTLGM.RefreshVisiblePage = baseRefresh("visible")
OTLGM.RefreshAddonUsersIndicator = baseRefresh("users")
OTLGM.RefreshDateIndicator = baseRefresh("date")
OTLGM.RefreshUpdateWarning = baseRefresh("warning")
OTLGM.RefreshAll = baseRefresh("all")
OTLGM.ShowPage = function(self, page) self.ui.currentPage=page return true end

-- UI builders exist so R5 wraps them but are not executed in this focused test.
OTLGM.BuildRecentWhisperDialog176 = function() end
OTLGM.RefreshRecentWhispers176 = function() end
OTLGM.OpenRecentWhispers176 = function() end
OTLGM.OpenTreasuryContributionDialog176 = function() end
OTLGM.BuildTreasuryPage170 = function() end
OTLGM.BuildUI = function() end
OTLGM.ParkWindow176 = function() return true end
OTLGM.UnparkWindow176 = function() return true end
OTLGM.BuildRecruitmentPage = function() end
OTLGM.RefreshHistoryRowsOnly = function() return true end
OTLGM.ProcessQuality156Timers = function() baseCalls.quality=(baseCalls.quality or 0)+1 return true end

-- Treasury bases captured by R5.
function OTLGM:EnsureTreasury170() return treasury end
function OTLGM:GetTreasuryGoal170(id) return treasury.goals[id] end
function OTLGM:CanEditTreasury170() return true end
function OTLGM:GetTreasuryContributions176(goalId) return treasury.contributions176[goalId] or {} end
function OTLGM:SetTreasuryGoal170(id, name, current, target, category)
    local goal = treasury.goals[id] or { id=id, revision=0 }
    goal.name=name goal.current=current goal.target=target goal.category=category
    goal.revision=(goal.revision or 0)+1 goal.updatedAt=now goal.updatedBy="Luck"
    treasury.goals[id]=goal
    return true, goal
end
function OTLGM:DeleteTreasuryGoal170(id) treasury.goals[id]=nil return true end
function OTLGM:AddTreasuryContribution176(goalId, contributor, amount, note)
    local goal = treasury.goals[goalId]
    if not goal then return false, "missing" end
    goal.current = goal.current + amount
    local entry = { id="new-"..tostring(table.getn(treasury.contributions176[goalId])+1), ts=now, actor="Luck", contributor=contributor, amount=amount, note=note, current=goal.current }
    table.insert(treasury.contributions176[goalId], 1, entry)
    return true, entry
end
function OTLGM:HandleTreasuryMessage170() return false end
function OTLGM:QueueTreasuryState170() return true end

local chunk, problem = loadfile(root .. "/Modules/Core/Release176R5.lua")
assertTrue(chunk, problem)
chunk()
local hotfixChunk, hotfixProblem = loadfile(root .. "/Modules/Core/Release176R5Hotfix.lua")
assertTrue(hotfixChunk, hotfixProblem)
hotfixChunk()

assertEqual(OTLGM.version, "1.7.6", "version")
assertEqual(OTLGM.build, "performance-r5-hotfix1-20260726", "build")
assertTrue(OTLGM.registeredModules.Release176R5~=nil, "R5 module registration")
assertTrue(OTLGM.registeredModules.Release176R5Hotfix~=nil, "hotfix module registration")
assertEqual(table.getn(OTLGM.achievements174.catalog), 4, "donor achievement definitions")

-- Mail must not invoke the old scanner.
assertEqual(OTLGM:ScheduleMailboxScan176("MAIL_SHOW"), false, "mail schedule disabled")
assertEqual(OTLGM:ProcessMailboxScan176(), false, "mail process disabled")
assertEqual(baseCalls.mailSchedule or 0, 0, "old mail schedule not called")
assertEqual(baseCalls.mailProcess or 0, 0, "old mail process not called")

-- Network budget is capped to two packets.
OTLGM:ProcessNetworkQueue(25)
assertEqual(baseCalls.networkMaximum, 2, "network budget")

-- Hidden page refresh is skipped; visible selected page still refreshes.
mainVisible = false
OTLGM.ui.currentPage = "home"
assertEqual(OTLGM:RefreshHomePage(), false, "hidden home refresh skipped")
assertEqual(baseCalls.home or 0, 0, "hidden home base not called")
mainVisible = true
assertTrue(OTLGM:RefreshHomePage(), "visible home refresh")
assertEqual(baseCalls.home, 1, "visible home base called")
OTLGM.ui.currentPage = "roster"
assertEqual(OTLGM:RefreshHomePage(), false, "non-selected home skipped")

-- Recent whisper invitation calls the guild API for an authorized non-member.
local ok, message = OTLGM:InviteRecentWhisper176("Newplayer-Realm")
assertTrue(ok, message)
assertEqual(invited[1], "Newplayer", "short invite name")
assertEqual(OTLGM.runtime.recentWhisperInviteStateR5.newplayer.state, "SENT", "invite state")
memberNames.existing = { name="Existing" }
local memberOk = OTLGM:InviteRecentWhisper176("Existing")
assertEqual(memberOk, false, "existing member rejected")

-- Existing contribution data migrates into activity exactly once.
local activity = OTLGM:GetTreasuryActivityR5("ALL")
assertTrue(table.getn(activity) >= 4, "activity migration")
local firstCount = table.getn(activity)
local secondCount = table.getn(OTLGM:GetTreasuryActivityR5("ALL"))
assertEqual(secondCount, firstCount, "activity migration deduplicated")

-- Per-goal ledger aggregates all contributions by person.
local ledger = OTLGM:GetTreasuryGoalLedgerR5("BANK")
assertEqual(table.getn(ledger.entries), 3, "ledger entries")
assertEqual(table.getn(ledger.contributors), 2, "ledger contributors")
local aggregateByName = {}
for index = 1, table.getn(ledger.contributors) do aggregateByName[ledger.contributors[index].name] = ledger.contributors[index].amount end
assertEqual(aggregateByName.Tokmek, 150000, "Tokmek aggregated amount")
assertEqual(aggregateByName.Amogog, 150000, "Amogog aggregated amount")
assertEqual(ledger.recorded, 300000, "recorded total")

-- New contribution is recorded in both ledger and activity without a duplicate goal event.
local addOk, entry = OTLGM:AddTreasuryContribution176("BANK", "Aethea", 25000, "Test")
assertTrue(addOk and entry, "new contribution")
local after = OTLGM:GetTreasuryGoalLedgerR5("BANK")
assertEqual(table.getn(after.entries), 4, "new ledger entry")
local contributionActivity = OTLGM:GetTreasuryActivityR5("CONTRIBUTIONS")
assertTrue(table.getn(contributionActivity) >= 4, "contribution activity")
assertTrue(not OTLGM:IsAchievementComplete174("E001"), "other donor does not reward recorder")

-- Donor totals are migrated before inserting a new entry, so the first local
-- contribution is counted exactly once and unlocks every 5-100g tier locally.
local selfOk,selfEntry=OTLGM:AddTreasuryContribution176("BANK","Luck",1000000,"Self donor")
assertTrue(selfOk and selfEntry, "self donor contribution")
local donorTotals=OTLGM:EnsureTreasuryDonorTotalsH1()
assertEqual(donorTotals.donorTotalsR5.luck.total,1000000,"first local donor amount counted once")
assertTrue(OTLGM:IsAchievementComplete174("E001"),"5g donor tier")
assertTrue(OTLGM:IsAchievementComplete174("E002"),"25g donor tier")
assertTrue(OTLGM:IsAchievementComplete174("E003"),"50g donor tier")
assertTrue(OTLGM:IsAchievementComplete174("E004"),"100g donor tier")
assertEqual(achievementDb.counters.treasuryDonatedGoldR5,100,"donor progress stored in gold")
OTLGM:QueueTreasuryState170("Luck")
local lastPacket=queuedPayloads[table.getn(queuedPayloads)]
assertTrue(lastPacket and lastPacket.channel=="WHISPER" and lastPacket.target=="Luck" and string.find(lastPacket.payload,"B1^DONOR^Luck^1000000",1,true)==1,"donor total sync targeted to requesting donor")

-- R5 adds no recurring visual maintenance to the heartbeat wrapper.
OTLGM:ProcessQuality156Timers()
assertEqual(baseCalls.quality, 1, "base quality timer called once")

print("RELEASE176_R5_SMOKE_TEST_OK")
