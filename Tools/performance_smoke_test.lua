-- Standalone smoke test for Performance176.lua. Run with texlua.
local now = 1700000000
if not table.getn then table.getn=function(t) return #t end end
if not math.mod then math.mod=function(a,b) return a % b end end
local frames = {}

function time() return now end
function date() return "25 Jul 17:00" end
function getglobal(name) return _G[name] end
function UnitName() return "Luck" end
function GetGuildInfo() return "Order of the Lion" end
local realZone, subZone = "Thunder Bluff", "Lower Rise"
function GetRealZoneText() return realZone end
function GetZoneText() return realZone end
function GetSubZoneText() return subZone end
function GetMoney() return 1234567 end
local bagSlots = { [0]=15, [1]=0, [2]=0, [3]=0, [4]=0 }
local bagItems = {}
for i=1,15 do bagItems[i]={link="|cff9d9d9d|Hitem:"..tostring(5000+i)..":0:0:0|h[Test Item "..tostring(i).."]|h|r",count=1,name="Test Item "..tostring(i),itemType="Miscellaneous",subType="Junk"} end
bagItems[1]={link="|cffffffff|Hitem:2589:0:0:0|h[Linen Cloth]|h|r",count=20,name="Linen Cloth",itemType="Trade Goods",subType="Cloth"}
function GetContainerNumSlots(bag) return bagSlots[bag] or 0 end
function GetContainerItemLink(bag,slot) local item=bag==0 and bagItems[slot] or nil return item and item.link or nil end
function GetContainerItemInfo(bag,slot) local item=bag==0 and bagItems[slot] or nil return nil,item and item.count or nil end
function GetItemInfo(link)
    local _,_,id=string.find(tostring(link or ""),"item:(%d+)")
    id=tonumber(id)
    for _,item in pairs(bagItems) do
        local _,_,itemId=string.find(item.link,"item:(%d+)")
        if tonumber(itemId)==id then return item.name,item.link,1,1,1,item.itemType,item.subType,20 end
    end
    return nil
end
function CanGuildInvite() return true end
function GuildInvite() end
function GuildKey() return "order of the lion@octowow" end

local Frame = {}
Frame.__index = Frame
function Frame:RegisterEvent(name) self.events[name] = true end
function Frame:UnregisterEvent(name) self.events[name] = nil end
function Frame:SetScript(name, callback) self.scripts[name] = callback end
function Frame:IsVisible() return self.visible and true or false end
function Frame:Show() self.visible = true end
function Frame:Hide() self.visible = false end
function Frame:SetPoint() end
function Frame:SetWidth() end
function Frame:SetHeight() end
function Frame:SetFrameStrata() end
function Frame:SetFrameLevel() end
function Frame:GetFrameLevel() return 1 end
function Frame:SetClampedToScreen() end
function Frame:ClearAllPoints() end
function Frame:GetWidth() return 1000 end
function Frame:GetHeight() return 710 end
function Frame:GetCenter() return 512,384 end
function Frame:SetBackdrop() end
function Frame:SetBackdropColor() end
function Frame:SetBackdropBorderColor() end
function Frame:EnableMouse() end
function Frame:SetMovable() end
function Frame:RegisterForDrag() end
function Frame:CreateFontString()
    return setmetatable({ events={}, scripts={}, visible=true, SetText=function(self,v) self.text=v end,
        SetPoint=function() end, SetWidth=function() end, SetJustifyH=function() end,
        SetJustifyV=function() end, SetTextColor=function() end }, Frame)
end
function CreateFrame(_, name)
    local frame = setmetatable({ events={}, scripts={}, visible=false }, Frame)
    if name then _G[name] = frame frames[name] = frame end
    return frame
end

DEFAULT_CHAT_FRAME = { lines={}, AddMessage=function(self, line) table.insert(self.lines, line) end }
SlashCmdList = {}
UIParent = CreateFrame("Frame", "UIParent")
OTLGM_DB = { settings={}, guilds={} }
local guildKey = "order of the lion@octowow"
local guildDb = { roster={}, achievements174={characters={}}, crafting={}, pve={}, treasury170={goals={},deleted={},history={}} }
OTLGM_DB.guilds[guildKey] = guildDb

OTLGM = {
    runtime={}, ui={}, achievements174={catalog={},byId={},catalogRevision=14}, release175r4={thresholdGuard=false},
    colors={gold="",reset=""},
}
function OTLGM:Now() return now end
function OTLGM:GuildKey() return guildKey end
function OTLGM:SafeText(value, maximum) value=tostring(value or "") return string.sub(value,1,maximum or string.len(value)) end
function OTLGM:GetAchievementCharacterKey174() return "luck@octowow" end
function OTLGM:GetGuildDB() self.baseGuildCalls=(self.baseGuildCalls or 0)+1 return OTLGM_DB.guilds[guildKey] end
function OTLGM:EnsureCraftingDB() self.baseCraftDbCalls=(self.baseCraftDbCalls or 0)+1 return guildDb.crafting end
function OTLGM:EnsurePveDB() self.basePveDbCalls=(self.basePveDbCalls or 0)+1 return guildDb.pve end
function OTLGM:EnsureAchievements174()
    guildDb.achievements174.characters["luck@octowow"] = guildDb.achievements174.characters["luck@octowow"] or {completed={},counters={},sets={}}
    return guildDb.achievements174.characters["luck@octowow"]
end
function OTLGM:GetGroupSnapshot174() self.baseSnapshots=(self.baseSnapshots or 0)+1 return {total=1,guild=1,guildMembers={}} end
function OTLGM:UpdateGroupSession174() self.baseGroupCalls=(self.baseGroupCalls or 0)+1 self.runtime.achievementGroup174=self:GetGroupSnapshot174() return self.runtime.achievementGroup174 end
function OTLGM:UpdateRaidPresence174() self.baseRaidCalls=(self.baseRaidCalls or 0)+1 end
function OTLGM:UpdateMembershipPeriod174() self.membershipCalls=(self.membershipCalls or 0)+1 end
function OTLGM:CheckLegacyAchievements174() self.legacyCalls=(self.legacyCalls or 0)+1 end
function OTLGM:CheckUnderBanner175R4() self.tabardCalls=(self.tabardCalls or 0)+1 end
function OTLGM:InstallTooltipCompatibility160() self.tooltipCalls=(self.tooltipCalls or 0)+1 end
function OTLGM:DetectWorldChannel153() self.channelCalls=(self.channelCalls or 0)+1 end
function OTLGM:ApplyUIScale() self.scaleCalls=(self.scaleCalls or 0)+1 end
function OTLGM:RefreshRecruitmentPage() self.recruitCalls=(self.recruitCalls or 0)+1 end
function OTLGM:CompleteAchievement174() return false end
function OTLGM:GetAchievementPresentation174(def) return def.name,def.description,def.icon,false end
function OTLGM:RefreshAchievements174() self.baseAchievementRefresh=(self.baseAchievementRefresh or 0)+1 end
function OTLGM:ProcessAchievementGuildAnnouncements174() self.baseAnnouncements=(self.baseAnnouncements or 0)+1 end
function OTLGM:RefreshAchievementRosterCache174() return {members={},classes={},builtAt=now} end
function OTLGM:ProcessUIDebounce(elapsed) self.baseDebounceCalls=(self.baseDebounceCalls or 0)+1 self.lastDebounceElapsed=elapsed end
function OTLGM:ProcessNetworkQueue() self.baseNetworkCalls=(self.baseNetworkCalls or 0)+1 return 1 end
function OTLGM:ProcessCraftingCacheQueue() self.baseCraftCacheCalls=(self.baseCraftCacheCalls or 0)+1 return true end
function OTLGM:ProcessCraftingTimers() self.baseCraftTimerCalls=(self.baseCraftTimerCalls or 0)+1 end
function OTLGM:ProcessTreasuryTimers170() self.baseTreasuryTimerCalls=(self.baseTreasuryTimerCalls or 0)+1 end
function OTLGM:PurgePveData() self.basePvePurge=(self.basePvePurge or 0)+1 return true end
function OTLGM:PurgeCraftingData() self.baseCraftPurge=(self.baseCraftPurge or 0)+1 return true end
function OTLGM:ProcessQuality156Timers() self.baseQuality=(self.baseQuality or 0)+1 end
function OTLGM:ShowPveRaidNotice() self.baseRaidNotice=(self.baseRaidNotice or 0)+1 return true end
function OTLGM:EnsureTreasury170()
    local t=guildDb.treasury170
    t.goals=t.goals or {} t.deleted=t.deleted or {} t.history=t.history or {}
    return t
end
function OTLGM:GetTreasuryGoal170(id) return guildDb.treasury170.goals[id] end
function OTLGM:SetTreasuryGoal170(id,name,current,target,category)
    guildDb.treasury170.goals[id]={id=id,name=name,current=current,target=target,category=category}
    return true,guildDb.treasury170.goals[id]
end
function OTLGM:CanEditTreasury170() return true end
function OTLGM:QueueNetworkPayload() return true end
function OTLGM:InCombat() return false end

-- Existing frames that the overlay prunes.
for _, name in ipairs({"OTLGM_ReleaseEvent175","OTLGM_AchievementsEvent174","OTLGM_ReleaseEvent175R4","OTLGM_ReleaseEvent175R6","OTLGM_EventFrame"}) do
    local f=CreateFrame("Frame",name)
    for _,ev in ipairs({"UNIT_HEALTH","PLAYER_ENTERING_WORLD","PARTY_MEMBERS_CHANGED","RAID_ROSTER_UPDATE","GUILD_ROSTER_UPDATE","PLAYER_GUILD_UPDATE","ZONE_CHANGED_NEW_AREA","MINIMAP_ZONE_CHANGED","BAG_UPDATE","CHAT_MSG_COMBAT_SELF_HITS","CHAT_MSG_SPELL_SELF_DAMAGE","PLAYER_LOGIN","PLAYER_MONEY","MAIL_SHOW","MAIL_INBOX_UPDATE","MAIL_SEND_SUCCESS","START_LOOT_ROLL","CANCEL_LOOT_ROLL","CHAT_MSG_SYSTEM","CHAT_MSG_GUILD","CHAT_MSG_COMBAT_HOSTILE_DEATH","PLAYER_DEAD"}) do f:RegisterEvent(ev) end
end

local modulePath = arg[1] or "Modules/Core/Performance176.lua"
dofile(modulePath)
assert(OTLGM.version == "1.7.6")
assert(OTLGM.build == "performance-r4-ultrasafe-20260725")
assert(OTLGM.performance176 and OTLGM.performance176.revision == 4)

-- Guild/domain cache identity and replacement safety.
assert(OTLGM:GetGuildDB() == guildDb)
assert(OTLGM:GetGuildDB() == guildDb)
assert(OTLGM.baseGuildCalls == 1)
assert(OTLGM:EnsureCraftingDB() == guildDb.crafting)
assert(OTLGM:EnsureCraftingDB() == guildDb.crafting)
assert(OTLGM.baseCraftDbCalls == 1)

local replacement={roster={},achievements174={characters={}},crafting={},pve={},treasury170={goals={},deleted={},history={}}}
OTLGM_DB.guilds[guildKey]=replacement
guildDb=replacement
assert(OTLGM:GetGuildDB() == replacement)
assert(OTLGM.baseGuildCalls == 2)
assert(OTLGM:EnsureCraftingDB() == replacement.crafting)
assert(OTLGM.baseCraftDbCalls == 2)

-- Per-frame debounce: 100 frames at 100 FPS should call base around 20 times,
-- not 100 times. Hidden UI is reduced further.
OTLGM.ui.main={visible=true,IsVisible=function(self) return self.visible end}
for i=1,100 do OTLGM:ProcessUIDebounce(0.01) end
assert(OTLGM.baseDebounceCalls >= 19 and OTLGM.baseDebounceCalls <= 21, tostring(OTLGM.baseDebounceCalls))
OTLGM.ui.main.visible=false
local before=OTLGM.baseDebounceCalls
for i=1,100 do OTLGM:ProcessUIDebounce(0.01) end
assert(OTLGM.baseDebounceCalls-before == 2, tostring(OTLGM.baseDebounceCalls-before))

-- Same-second group calls and repeated snapshots are coalesced.
OTLGM.runtime.groupSnapshotDirty176=true
OTLGM:UpdateGroupSession174(false)
OTLGM:UpdateGroupSession174(false)
assert(OTLGM.baseGroupCalls == 1, tostring(OTLGM.baseGroupCalls))
assert(OTLGM.baseSnapshots == 1, tostring(OTLGM.baseSnapshots))

-- Idle guards do not call the expensive base paths.
OTLGM.runtime.transport={critical={count=0},normal={count=0},bulk={count=0}}
assert(OTLGM:ProcessNetworkQueue() == 0)
assert(not OTLGM.baseNetworkCalls)
OTLGM:ProcessCraftingTimers()
assert(not OTLGM.baseCraftTimerCalls)
OTLGM:ProcessTreasuryTimers170()
assert(not OTLGM.baseTreasuryTimerCalls)

-- Pending work still runs.
OTLGM.runtime.transport.normal.count=1
OTLGM:ProcessNetworkQueue()
assert(OTLGM.baseNetworkCalls == 1)
OTLGM.craftingRescan={due=now+10}
OTLGM:ProcessCraftingTimers()
assert(OTLGM.baseCraftTimerCalls == 1)
OTLGM.treasuryShareTargets170={luck={name="Luck",due=now+10}}
OTLGM:ProcessTreasuryTimers170()
assert(OTLGM.baseTreasuryTimerCalls == 1)

-- Raid notification dedupe.
assert(OTLGM:ShowPveRaidNotice("MC","Tomorrow",true) == true)
assert(OTLGM:ShowPveRaidNotice("MC","Tomorrow",true) == false)
assert(OTLGM.baseRaidNotice == 1)

-- High-frequency and duplicate transition listeners were actually detached.
assert(not frames.OTLGM_ReleaseEvent175.events.UNIT_HEALTH)
assert(not frames.OTLGM_ReleaseEvent175.events.PLAYER_ENTERING_WORLD)
assert(not frames.OTLGM_AchievementsEvent174.events.PLAYER_ENTERING_WORLD)
assert(not frames.OTLGM_ReleaseEvent175R4.events.PLAYER_ENTERING_WORLD)
assert(not frames.OTLGM_ReleaseEvent175R6.events.PLAYER_ENTERING_WORLD)
assert(not frames.OTLGM_ReleaseEvent175R6.events.ZONE_CHANGED_NEW_AREA)
assert(not frames.OTLGM_ReleaseEvent175R6.events.BAG_UPDATE)
assert(not frames.OTLGM_EventFrame.events.PLAYER_ENTERING_WORLD)
assert(not frames.OTLGM_ReleaseEvent175R6.events.CHAT_MSG_COMBAT_SELF_HITS)

local perfFrame=frames.OTLGM_PerformanceEvent176
local function fire(name,a1,a2)
    event=name arg1=a1 arg2=a2
    assert(perfFrame.scripts.OnEvent)
    perfFrame.scripts.OnEvent()
    event=nil arg1=nil arg2=nil
end

-- Thunder Bluff subzone chatter must not queue a full group/raid pass.
OTLGM.runtime.lastRealZone176="thunder bluff"
OTLGM.runtime.lastSubZone176="lower rise"
local groupBefore=OTLGM.baseGroupCalls or 0
for i=1,50 do
    subZone=(math.mod(i,2)==0) and "Lower Rise" or "Spirit Rise"
    fire("MINIMAP_ZONE_CHANGED")
end
assert(not OTLGM.runtime.transitionActive176)
assert(not OTLGM.runtime.performanceGroupDue176)
assert((OTLGM.baseGroupCalls or 0)==groupBefore)
assert(OTLGM.performance176.sameZoneMinimapIgnored==50)
assert(OTLGM.performance176.subzoneStateResets==50)

-- A real transition storm is coalesced and no expensive group work runs until
-- the zone has been stable for three seconds.
fire("PLAYER_ENTERING_WORLD")
fire("ZONE_CHANGED_NEW_AREA")
fire("ZONE_CHANGED_NEW_AREA")
assert(OTLGM.runtime.transitionActive176)
local beforeStable=OTLGM.baseGroupCalls or 0
OTLGM:UpdateGroupSession174(false)
assert((OTLGM.baseGroupCalls or 0)==beforeStable)
OTLGM:ProcessQuality156Timers()
assert((OTLGM.baseGroupCalls or 0)==beforeStable)
local networkBefore=OTLGM.baseNetworkCalls or 0
assert(OTLGM:ProcessNetworkQueue()==0)
assert((OTLGM.baseNetworkCalls or 0)==networkBefore)
now=now+3
OTLGM:ProcessQuality156Timers()
assert((OTLGM.baseGroupCalls or 0)==beforeStable+1)
assert((OTLGM.baseRaidCalls or 0)>=1)
assert(OTLGM.performance176.transitionStablePasses==1)
assert(not OTLGM.runtime.transitionActive176)
assert((OTLGM.membershipCalls or 0)==1)
assert((OTLGM.legacyCalls or 0)==1)
assert((OTLGM.tabardCalls or 0)==1)
assert((OTLGM.tooltipCalls or 0)==1)
assert((OTLGM.channelCalls or 0)==1)

-- Bag achievements are restored through bounded incremental work. The first
-- heartbeat may inspect at most ten slots, never the entire bag in one frame.
local slotsBefore=OTLGM.performance176.incrementalBagSlots
now=now+1
OTLGM:ProcessQuality156Timers()
local firstSlice=OTLGM.performance176.incrementalBagSlots-slotsBefore
assert(firstSlice>0 and firstSlice<=10,tostring(firstSlice))
for i=1,10 do now=now+1 OTLGM:ProcessQuality156Timers() end
assert(not OTLGM.runtime.incrementalBagScan176)
assert(OTLGM.performance176.incrementalBagScans>=1)
local adb=OTLGM:EnsureAchievements174()
assert((adb.counters.coreClothStacksR6 or 0)==1)

-- A BAG_UPDATE burst restarts/debounces the partial scan instead of doing work
-- in the event callback.
local scansBefore=OTLGM.performance176.incrementalBagScans
fire("BAG_UPDATE",0)
fire("BAG_UPDATE",0)
assert(not OTLGM.runtime.incrementalBagScan176)
now=now+1
OTLGM:ProcessQuality156Timers()
assert(OTLGM.performance176.incrementalBagScans==scansBefore+1)

print("PERFORMANCE176_R4_SMOKE_TEST_OK")
