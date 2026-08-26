-- OrderOfTheLionGM v1.7.5 corrective release r6
-- Final integration pass: achievement pack, series ordering, event-safe trackers,
-- roster anomaly filtering, Activity layout repair and conservative UI polish.

if not OTLGM then return end

OTLGM.legacyBuildRelease175R6 = "stable-r7-20260723"
local R6 = { revision = 6 }
local A6 = OTLGM.achievements174
local LION_ICON_R6 = "Interface\\AddOns\\OrderOfTheLionGM\\Assets\\LionCrest.tga"
local SAFE_ICON_R6 = "Interface\\Icons\\INV_Misc_Book_09"
local MAX_LEVEL_R6 = 60
local COPPER_PER_GOLD_R6 = 10000
local MAX_SET_R6 = 700

local function TrimR6(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function ShortNameR6(value)
    value = TrimR6(value)
    local dash = string.find(value, "-", 1, true)
    if dash then value = string.sub(value, 1, dash - 1) end
    return value
end

local function KeyR6(value)
    value = string.lower(ShortNameR6(value))
    value = string.gsub(value, "[^%w]", "")
    return value
end

local function CountR6(tbl)
    local count = 0
    local key
    for key in pairs(tbl or {}) do count = count + 1 end
    return count
end

local function SetButtonTextR6(button, text)
    if not button then return end
    if button.text and button.text.SetText then button.text:SetText(text or "")
    elseif button.label156 and button.label156.SetText then button.label156:SetText(text or "") end
end

local function MoveR6(control, parent, x, y, width, height)
    if not control then return end
    if parent and control.SetParent and control.GetParent and control:GetParent() ~= parent then control:SetParent(parent) end
    control:ClearAllPoints()
    control:SetPoint("TOPLEFT", parent or control:GetParent(), "TOPLEFT", x, y)
    if width then control:SetWidth(width) end
    if height then control:SetHeight(height) end
end

local function IsPlayerR6(name)
    return KeyR6(name) ~= "" and KeyR6(name) == KeyR6(UnitName and UnitName("player") or "")
end

local function IsGuildMemberR6(self, name)
    local key = KeyR6(name)
    if key == "" then return false end
    local members = self.GetGuildMemberSet174 and self:GetGuildMemberSet174() or {}
    return members[key] ~= nil
end

local function GetGuildLeaderNameR6(self)
    if self.GetCanonicalGuildLeaderName180 then return ShortNameR6(self:GetCanonicalGuildLeaderName180() or "") end
    return ""
end

local function IsLucksNameR6(name)
    -- Published achievement text names Lucks explicitly. Legacy leader aliases
    -- are valid for old SavedVariables/administration compatibility only and
    -- must never satisfy an achievement condition.
    return KeyR6(name) == "lucks"
end

local function FullGuildPartyR6(self)
    local group = self.GetGroupSnapshot174 and self:GetGroupSnapshot174() or nil
    if not group then return nil, false end
    return group, group.isParty and not group.isRaid and tonumber(group.total) == 5 and tonumber(group.guild) == 5
end

local function HasGuildPartnerR6(self)
    local group = self.GetGroupSnapshot174 and self:GetGroupSnapshot174() or nil
    if not group then return false end
    return tonumber(group.guild) and tonumber(group.guild) >= 2
end

local function AddSetR6(self, key, value)
    value = KeyR6(value)
    if value == "" then return false end
    local set = self:GetAchievementSet174(key)
    if set[value] then return false end
    if CountR6(set) >= MAX_SET_R6 then return false end
    set[value] = true
    return true
end

local function AddAchievementR6(def)
    if not A6 or not def or not def.id or A6.byId[def.id] then return false end
    table.insert(A6.catalog, def)
    A6.byId[def.id] = def
    return true
end

-- 21 definitions from the new implementation pack that were not already present.
local ADDITIONS_R6 = {
    {id="D001",category="SOCIAL",name="A Witness to Sixty",description="Be there when a guild member reaches the maximum level.",icon="Interface\\Icons\\Spell_Holy_PrayerOfSpirit",progress="witnessMaxLevelR6",required=1},
    {id="D002",category="SOCIAL",name="Together, We Grow Stronger",description="Gain ten levels while grouped with the same guild member.",icon="Interface\\Icons\\Spell_Holy_DevotionAura",progress="partnerLevelBestR6",required=10},
    {id="D003",category="SOCIAL",name="Perfect Roll",description="Win an item with a perfect 100 Need or Greed roll.",icon="Interface\\Icons\\INV_Misc_Dice_02",progress="perfectRollR6",required=1},
    {id="D004",category="SOCIAL",name="So Close",description="Lose an item with a roll of 99 to a guild member who rolled 100.",icon="Interface\\Icons\\INV_Misc_Dice_01",progress="soCloseR6",required=1},
    {id="D005",category="SOCIAL",name="For the Greater Good",description="Pass on an epic item in a full guild party.",icon="Interface\\Icons\\INV_Misc_Gem_01",progress="epicPassR6",required=1},
    {id="D006",category="SOCIAL",name="Everybody Passes",description="Have every member of a full guild party pass on the same item.",icon="Interface\\Icons\\INV_Misc_GroupNeedMore",progress="everybodyPassesR6",required=1},
    {id="D007",category="SOCIAL",name="Generous Tip",description="Give a guild member at least one gold and receive nothing in return.",icon="Interface\\Icons\\INV_Misc_Coin_01",progress="generousTipR6",required=1},
    {id="D008",category="SOCIAL",name="Mail Call",description="Send an item to a guild member through the in-game mail.",icon="Interface\\Icons\\INV_Letter_15",progress="mailCallR6",required=1},
    {id="D009",category="SOCIAL",name="Pen Pals",description="Receive mail from ten different guild members.",icon="Interface\\Icons\\INV_Misc_Note_02",progress="mailGuildSendersR6",required=10},
    {id="D010",category="SOCIAL",name="Roll of Fate",description="Roll 100 with /roll while in a full guild party.",icon="Interface\\Icons\\INV_Misc_Dice_02",progress="rollOfFateR6",required=1},
    {id="D011",category="SOCIAL",name="Rise, Commander",description="Successfully resurrect Lucks with a standard resurrection spell.",icon="Interface\\Icons\\Spell_Holy_Resurrection",progress="riseCommanderR6",required=1},
    {id="D012",category="RAIDS",name="The World Is Watching",description="Defeat a world boss with at least ten guild members present.",icon="Interface\\Icons\\INV_Misc_Head_Dragon_01",progress="worldBossR6",required=1},
    {id="D013",category="LEGACY",name="The Final Step",description="Reach the maximum level while grouped with a guild member.",icon="Interface\\Icons\\INV_Crown_01",progress="finalStepR6",required=1},
    {id="D014",category="LEGACY",name="First Fortune",description="Carry at least one hundred gold on this character.",icon="Interface\\Icons\\INV_Misc_Coin_02",progress="moneyCopperR6",required=1000000,unitR6="gold"},
    {id="D015",category="LEGACY",name="Cloth Merchant",description="Carry a full stack of every core cloth type at the same time.",icon="Interface\\Icons\\INV_Fabric_Mageweave_01",progress="coreClothStacksR6",required=5},
    {id="D016",category="LEGACY",name="Packed Lunch",description="Carry twenty different kinds of food at the same time.",icon="Interface\\Icons\\INV_Misc_Food_15",progress="uniqueFoodR6",required=20},
    {id="D017",category="LEGACY",name="Traveling Apothecary",description="Carry ten different potions or elixirs at the same time.",icon="Interface\\Icons\\INV_Potion_01",progress="uniquePotionsR6",required=10},
    {id="D018",category="LEGACY",name="Living Legend",description="Link a legendary item you own in guild chat.",icon="Interface\\Icons\\INV_Misc_Gem_Pearl_05",progress="livingLegendR6",required=1},
    {id="D019",category="SECRETS",name="Absolutely Broke",description="The title is your clue.",revealed="Stand in a faction capital with exactly zero copper.",icon="Interface\\Icons\\INV_Misc_Coin_01",progress="absolutelyBrokeR6",required=1,secret=true},
    {id="D020",category="SECRETS",name="Exact Change",description="The title is your clue.",revealed="Give Lucks exactly one copper and receive nothing.",icon="Interface\\Icons\\INV_Misc_Coin_01",progress="exactChangeR6",required=1,secret=true},
    {id="D021",category="SECRETS",name="Gravity Wins",description="The title is your clue.",revealed="Die from falling damage while grouped with a guild member.",icon="Interface\\Icons\\Ability_Rogue_Sprint",progress="gravityWinsR6",required=1,secret=true},
}

local i
for i=1,table.getn(ADDITIONS_R6) do AddAchievementR6(ADDITIONS_R6[i]) end
if A6 then A6.catalogRevision = math.max(tonumber(A6.catalogRevision) or 0, 12) end

-- Series keep their existing published names, but share an icon and sort together.
local SERIES_R6 = {
    {key="resurrection",icon="Interface\\Icons\\Spell_Holy_Resurrection",ids={"B068","C001","C002","C003"}},
    {key="partners",icon="Interface\\Icons\\INV_Misc_GroupNeedMore",ids={"A013","A020","C004","C005","C006"}},
    {key="groupTime",icon="Interface\\Icons\\INV_Misc_PocketWatch_01",ids={"A018","C007","C008","C009","C010"}},
    {key="dungeonBosses",icon="Interface\\Icons\\INV_Misc_Key_03",ids={"A043","C011","A050","C012","C013"}},
    {key="fullDungeons",icon=LION_ICON_R6,ids={"B070","B071","B072","C014","C015"}},
    {key="raidBosses",icon="Interface\\Icons\\INV_Misc_Head_Dragon_01",ids={"A055","C016","A064","C017","C018"}},
    {key="craftActions",icon="Interface\\Icons\\Trade_BlackSmithing",ids={"B079","C019","C020","C021"}},
    {key="groupApplications",icon="Interface\\Icons\\INV_Letter_15",ids={"A021","C022","C023","C024"}},
    {key="acceptedApplications",icon="Interface\\Icons\\Spell_Holy_SealOfSalvation",ids={"A023","C025","C026"}},
    {key="crafterContacts",icon="Interface\\Icons\\INV_Misc_Rune_01",ids={"A040","C027","C028","C029"}},
    {key="announcementReactions",icon="Interface\\Icons\\INV_Misc_Note_01",ids={"A007","C030","C031","C032"}},
    {key="publishedRecipes",icon="Interface\\Icons\\INV_Scroll_03",ids={"A032","C033","C034"}},
    {key="riding",icon="Interface\\Icons\\Ability_Mount_RidingHorse",ids={"B080","B081"}},
}

local seriesAppliedRevisionR31 = nil
local function ApplySeriesR6()
    if not A6 then return end
    local seriesRevisionR31 = tostring(tonumber(A6.catalogRevision) or 0) .. ":" .. tostring(table.getn(A6.catalog or {}))
    if seriesAppliedRevisionR31 == seriesRevisionR31 then return end
    seriesAppliedRevisionR31 = seriesRevisionR31
    local catalogIndex = {}
    local index, def, series, tier
    for index=1,table.getn(A6.catalog or {}) do
        def=A6.catalog[index]
        catalogIndex[def.id]=index
        def.catalogIndexR6=index
    end
    for index=1,table.getn(SERIES_R6) do
        series=SERIES_R6[index]
        local firstIndex=999999
        for tier=1,table.getn(series.ids) do
            if catalogIndex[series.ids[tier]] and catalogIndex[series.ids[tier]]<firstIndex then firstIndex=catalogIndex[series.ids[tier]] end
        end
        for tier=1,table.getn(series.ids) do
            def=A6.byId[series.ids[tier]]
            if def then
                def.seriesKeyR6=series.key
                def.seriesTierR6=tier
                def.seriesOrderR6=firstIndex
                def.icon=series.icon
            end
        end
    end
    local neutral={"UNDER_BANNER","A044","A054","B051","B063","B073","B083"}
    for index=1,table.getn(neutral) do if A6.byId[neutral[index]] then A6.byId[neutral[index]].icon=LION_ICON_R6 end end
end
ApplySeriesR6()

local PreviousProgressR6 = OTLGM.__impl180.GetAchievementProgress174__impl3
function OTLGM:GetAchievementProgress174(def)
    if not def or string.sub(tostring(def.id or ""),1,1) ~= "D" then return PreviousProgressR6(self,def) end
    local db=self:EnsureAchievements174()
    if db.completed[def.id] then return def.required or 1,def.required or 1 end
    local key=def.progress
    local current=0
    if key=="mailGuildSendersR6" then current=CountR6(self:GetAchievementSet174(key))
    else current=tonumber(db.counters[key]) or 0 end
    return math.min(current,def.required or 1),def.required or 1
end

local PreviousDisplayListR6 = OTLGM.__impl180.GetAchievementDisplayList174__impl2
function OTLGM:GetAchievementDisplayList174()
    ApplySeriesR6()
    -- R31: the old chain sorted the same list twice and repeatedly called
    -- GetAchievementProgress174 from table.sort comparators. On a large catalog
    -- this turned one page open into ~100 ms. Evaluate each achievement once,
    -- retain the final R6 ordering semantics, and keep comparator work O(1).
    local category = OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.achievementCategory174 or "OVERVIEW"
    local filter = OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.achievementFilter174 or "ALL"
    local search = string.lower(TrimR6((self.ui and self.ui.achievementSearchRuntime180) or (OTLGM_DB and OTLGM_DB.settings and OTLGM_DB.settings.achievementSearch174) or ""))
    local list, meta = {}, {}
    local index, def, complete, current, required, matches, stateRank
    for index = 1, table.getn(A6 and A6.catalog or {}) do
        def = A6.catalog[index]
        complete = self:IsAchievementComplete174(def.id)
        current, required = self:GetAchievementProgress174(def)
        matches = search == "" or string.find(string.lower(def.name or ""), search, 1, true)
            or string.find(string.lower(def.description or ""), search, 1, true)
        if matches and (category == "OVERVIEW" or def.category == category) then
            if filter == "ALL" or (filter == "COMPLETE" and complete)
                or (filter == "PROGRESS" and not complete and (tonumber(current) or 0) > 0 and not def.secret)
                or (filter == "LOCKED" and not complete and (def.secret or (tonumber(current) or 0) <= 0)) then
                table.insert(list, def)
                if complete then stateRank = 1
                elseif not def.secret and (tonumber(current) or 0) > 0 then stateRank = 2
                else stateRank = 3 end
                meta[def.id] = {
                    state = stateRank,
                    tracked = (not complete and self.IsAchievementTracked183 and self:IsAchievementTracked183(def.id)) and 0 or 1,
                    order = tonumber(def.seriesOrderR6) or tonumber(def.catalogIndexR6) or index,
                    tier = tonumber(def.seriesTierR6) or 1,
                    name = tostring(def.name or ""),
                }
            end
        end
    end
    table.sort(list, function(left, right)
        local lm, rm = meta[left.id], meta[right.id]
        -- r32: tracked goals are pinned above ordinary results in every view.
        -- Completion still removes a goal automatically, so this cannot pin stale
        -- completed achievements ahead of the catalog.
        if lm.tracked ~= rm.tracked then return lm.tracked < rm.tracked end
        if category == "OVERVIEW" and lm.state ~= rm.state then return lm.state < rm.state end
        if lm.order ~= rm.order then return lm.order < rm.order end
        if lm.tier ~= rm.tier then return lm.tier < rm.tier end
        return lm.name < rm.name
    end)
    self.runtime = self.runtime or {}
    self.runtime.achievementDisplayEvaluationsR31 = (tonumber(self.runtime.achievementDisplayEvaluationsR31) or 0) + table.getn(A6 and A6.catalog or {})
    return list
end

local PreviousRefreshAchievementsR6 = OTLGM.__impl180.RefreshAchievements174__impl4
function OTLGM.__impl180.RefreshAchievements174__impl5(self)
    ApplySeriesR6()
    PreviousRefreshAchievementsR6(self)
    local index,row,def,current,required
    for index=1,table.getn(self.ui and self.ui.achievementRows174 or {}) do
        row=self.ui.achievementRows174[index]
        def=row and row.achievement174
        if def and row:IsVisible() then
            if row.icon174 then row.icon174:SetTexture(def.icon or SAFE_ICON_R6) end
            if def.unitR6=="gold" and not self:IsAchievementComplete174(def.id) then
                current,required=self:GetAchievementProgress174(def)
                row.status174:SetText(tostring(math.floor((current or 0)/COPPER_PER_GOLD_R6)).." / "..tostring(math.floor((required or 0)/COPPER_PER_GOLD_R6)).."g")
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Roster anomaly filtering. Large same-minute JOIN/LEAVE bursts are retained in
-- SavedVariables for forensic review but excluded from summaries and default UI.
-- ---------------------------------------------------------------------------

local function BuildAnomalyBucketsR6(self,days)
    local db=self:GetGuildDB()
    local cutoff=self:Now()-((days or 7)*86400)
    local counts={}
    local index,eventInfo,bucket
    for index=1,table.getn(db and db.log or {}) do
        eventInfo=db.log[index]
        if eventInfo.ts and eventInfo.ts>=cutoff and (eventInfo.kind=="JOIN" or eventInfo.kind=="LEAVE") then
            bucket=math.floor((tonumber(eventInfo.ts) or 0)/300)
            counts[bucket]=(counts[bucket] or 0)+1
        end
    end
    local threshold=math.max(25,math.floor((tonumber(db and db.lastTotal) or 0)*0.08))
    local bad={}
    for bucket,index in pairs(counts) do if index>=threshold then bad[bucket]=true end end
    return bad
end

local function IsAnomalousEventR6(eventInfo,bad)
    if not eventInfo or not eventInfo.ts or (eventInfo.kind~="JOIN" and eventInfo.kind~="LEAVE") then return false end
    return bad[math.floor((tonumber(eventInfo.ts) or 0)/300)] and true or false
end

local PreviousGetStatsR6=OTLGM.__impl180.GetStats__impl1
function OTLGM:GetStats(days)
    local stats=PreviousGetStatsR6(self,days)
    local db=self:GetGuildDB()
    local cutoff=self:Now()-((days or 7)*86400)
    local bad=BuildAnomalyBucketsR6(self,days)
    local joins,leaves=0,0
    local index,eventInfo
    for index=1,table.getn(db and db.log or {}) do
        eventInfo=db.log[index]
        if eventInfo.ts and eventInfo.ts>=cutoff and not IsAnomalousEventR6(eventInfo,bad) then
            if eventInfo.kind=="JOIN" then joins=joins+1 end
            if eventInfo.kind=="LEAVE" then leaves=leaves+1 end
        end
    end
    stats.joins=joins stats.leaves=leaves stats.net=joins-leaves
    stats.anomalyBatchesR6=CountR6(bad)
    return stats
end

local PreviousFilteredHistoryR6=OTLGM.__impl180.GetFilteredHistory__impl1
function OTLGM:GetFilteredHistory(filter,search)
    local list=PreviousFilteredHistoryR6(self,filter,search)
    if filter=="ALL" or filter==nil then
        local bad=BuildAnomalyBucketsR6(self,30)
        local result={}
        local index,item
        for index=1,table.getn(list) do item=list[index] if not IsAnomalousEventR6(item,bad) then table.insert(result,item) end end
        return result
    end
    return list
end

local PreviousRefreshOverviewR6=OTLGM.__impl180.RefreshOverviewPage__impl2
function OTLGM.__impl180.RefreshOverviewPage__impl3(self)
    local result=PreviousRefreshOverviewR6(self)
    if not self.ui or not self.ui.overviewCards then return result end
    local stats=self:GetStats(7)
    local card=self.ui.overviewCards.joined
    if card then
        if card.label then card.label:SetText(stats.anomalyBatchesR6>0 and "ROSTER CHANGES" or "JOINED / LEFT") end
        if stats.anomalyBatchesR6>0 then
            if card.value then card.value:SetText(self.colors.gold.."REVIEW"..self.colors.reset) end
            if card.sub then card.sub:SetText("Anomalous scan batch excluded") end
        end
    end
    if stats.anomalyBatchesR6>0 and self.ui.overviewFreshness then
        self.ui.overviewFreshness:SetText(self.colors.gold.."Anomalous roster batch ignored  |  verified net "..(stats.net>=0 and "+" or "")..tostring(stats.net)..self.colors.reset)
    end
    local db=self:GetGuildDB()
    local bad=BuildAnomalyBucketsR6(self,7)
    local shown=0
    local index,eventInfo
    for index=1,table.getn(db and db.log or {}) do
        eventInfo=db.log[index]
        if eventInfo.kind~="BASELINE" and not eventInfo.hiddenLegacyLevel and not IsAnomalousEventR6(eventInfo,bad) then
            shown=shown+1
            if shown<=7 and self.ui.overviewEvents[shown] then
                local color=self.colors.white
                if eventInfo.kind=="JOIN" then color=self.colors.green elseif eventInfo.kind=="LEAVE" then color=self.colors.red elseif eventInfo.kind=="RANK" then color=self.colors.gold elseif eventInfo.kind=="LEVEL" then color=self.colors.blue elseif eventInfo.kind=="RETURN" then color=self.colors.green end
                self.ui.overviewEvents[shown]:SetText(self.colors.grey..date("%d/%m %H:%M",eventInfo.ts)..self.colors.reset.."  "..color..tostring(eventInfo.kind or "")..self.colors.reset.."  "..tostring(eventInfo.name or "").."  "..tostring(eventInfo.detail or ""))
            end
        end
        if shown>=7 then break end
    end
    local fill
    for fill=shown+1,7 do if self.ui.overviewEvents[fill] then self.ui.overviewEvents[fill]:SetText(self.colors.darkGrey.."No recorded event"..self.colors.reset) end end
    return result
end

-- ---------------------------------------------------------------------------
-- Money, bags, mail, level, trade, loot and chat trackers.
-- ---------------------------------------------------------------------------

local CAPITALS_R6={stormwind=true,stormwindcity=true,ironforge=true,darnassus=true,orgrimmar=true,undercity=true,thunderbluff=true,silvermooncity=true,exodar=true,theexodar=true}
local CORE_CLOTH_R6={ [2589]=20,[2592]=20,[4306]=20,[4338]=20,[14047]=20 }
local WORLD_BOSSES_R6={
    azuregos=true,["lordkazzak"]=true,emeriss=true,lethon=true,taerar=true,ysondre=true,
    ostarius=true,ostariusofuldum=true,concavius=true,nerubianoverseer=true,darkreaverofkarazhan=true,
}

local function CurrentZoneKeyR6()
    local zone=GetRealZoneText and GetRealZoneText() or GetZoneText and GetZoneText() or ""
    return KeyR6(zone)
end

local function CheckMoneyR6(self,silent)
    local db=self:EnsureAchievements174()
    -- PLAYER_MONEY can arrive before the delayed R6 login baseline. Existing
    -- wallet state on a cold/fresh login is retrospective, so never announce
    -- First Fortune / Absolutely Broke until this character has established the
    -- baseline at least once. Persisted completed[id] remains the primary gate.
    if not db.releaseBaselineR6 then silent=true end
    local money=GetMoney and tonumber(GetMoney()) or 0
    self:SetAchievementCounter174("moneyCopperR6",money)
    if money>=100*COPPER_PER_GOLD_R6 then self:CompleteAchievement174("D014",silent) end
    if money==0 and CAPITALS_R6[CurrentZoneKeyR6()] then self:CompleteAchievement174("D019",silent) end
end

local function ItemIdFromLinkR6(link)
    local _,_,id=string.find(tostring(link or ""),"item:(%d+)")
    return tonumber(id)
end

local function ScanBagsR6(self,silent)
    local clothCounts={}
    local foodSet={}
    local potionSet={}
    local bag,slot,slots,link,id,count,name,quality,level,req,itemType,itemSubType,maxStack
    for bag=0,4 do
        slots=GetContainerNumSlots and tonumber(GetContainerNumSlots(bag)) or 0
        for slot=1,slots do
            link=GetContainerItemLink and GetContainerItemLink(bag,slot) or nil
            if link then
                id=ItemIdFromLinkR6(link)
                local texture,itemCount=GetContainerItemInfo and GetContainerItemInfo(bag,slot)
                count=tonumber(itemCount) or 1
                if id and CORE_CLOTH_R6[id] then clothCounts[id]=(clothCounts[id] or 0)+count end
                name,link,quality,level,req,itemType,itemSubType,maxStack=GetItemInfo(link)
                local typeKey=string.lower(tostring(itemType or ""))
                local subKey=string.lower(tostring(itemSubType or ""))
                local nameKey=string.lower(tostring(name or ""))
                if id and (string.find(subKey,"food",1,true) or (string.find(typeKey,"consumable",1,true) and (string.find(nameKey,"bread",1,true) or string.find(nameKey,"meat",1,true) or string.find(nameKey,"fish",1,true) or string.find(nameKey,"cheese",1,true) or string.find(nameKey,"fruit",1,true)))) then foodSet[id]=true end
                if id and (string.find(subKey,"potion",1,true) or string.find(subKey,"elixir",1,true) or string.find(subKey,"flask",1,true) or string.find(nameKey,"potion",1,true) or string.find(nameKey,"elixir",1,true) or string.find(nameKey,"flask",1,true)) then potionSet[id]=true end
            end
        end
    end
    local clothReady=0
    for id,count in pairs(clothCounts) do if count>=(CORE_CLOTH_R6[id] or 20) then clothReady=clothReady+1 end end
    self:SetAchievementCounter174("coreClothStacksR6",clothReady)
    self:SetAchievementCounter174("uniqueFoodR6",CountR6(foodSet))
    self:SetAchievementCounter174("uniquePotionsR6",CountR6(potionSet))
    if clothReady>=5 then self:CompleteAchievement174("D015",silent) end
    if CountR6(foodSet)>=20 then self:CompleteAchievement174("D016",silent) end
    if CountR6(potionSet)>=10 then self:CompleteAchievement174("D017",silent) end
end

local function OwnedItemIdR6(itemId)
    if not itemId then return false end
    local slot,bag,index,link
    for slot=1,19 do link=GetInventoryItemLink and GetInventoryItemLink("player",slot) or nil if ItemIdFromLinkR6(link)==itemId then return true end end
    for bag=0,4 do
        local slots=GetContainerNumSlots and tonumber(GetContainerNumSlots(bag)) or 0
        for index=1,slots do link=GetContainerItemLink and GetContainerItemLink(bag,index) or nil if ItemIdFromLinkR6(link)==itemId then return true end end
    end
    return false
end

local function CheckLivingLegendR6(self,message,sender)
    if not IsPlayerR6(sender) then return end
    local position=1
    while true do
        local startPos,endPos,idText=string.find(tostring(message or ""),"item:(%d+)",position)
        if not startPos then break end
        local itemId=tonumber(idText)
        local link="item:"..tostring(itemId or "")
        local name,fullLink,quality=GetItemInfo(link)
        if tonumber(quality)==5 and OwnedItemIdR6(itemId) then self:CompleteAchievement174("D018",false) return end
        position=endPos+1
    end
end

local function CheckLevelUpR6(self,newLevel)
    newLevel=tonumber(newLevel) or UnitLevel and tonumber(UnitLevel("player")) or 0
    local group=self:GetGroupSnapshot174()
    local db=self:EnsureAchievements174()
    if group and tonumber(group.guild)>=2 then
        local map=db.partnerLevelsR6
        if type(map)~="table" then map={} db.partnerLevelsR6=map end
        local index,member,best
        for index=1,table.getn(group.guildMembers or {}) do
            member=group.guildMembers[index]
            if not IsPlayerR6(member.name) then
                local key=KeyR6(member.name)
                map[key]=math.min(100,tonumber(map[key]) or 0)+1
                if map[key]>(tonumber(db.counters.partnerLevelBestR6) or 0) then db.counters.partnerLevelBestR6=map[key] end
            end
        end
        if (tonumber(db.counters.partnerLevelBestR6) or 0)>=10 then self:CompleteAchievement174("D002",false) end
        if newLevel>=MAX_LEVEL_R6 then self:CompleteAchievement174("D013",false) end
        if newLevel>=MAX_LEVEL_R6 and self.QueueNetworkPayload then
            local signature=""
            local names={}
            for index=1,table.getn(group.guildMembers or {}) do table.insert(names,KeyR6(group.guildMembers[index].name)) end
            table.sort(names) signature=table.concat(names,",")
            for index=1,table.getn(group.guildMembers or {}) do
                member=group.guildMembers[index]
                if not IsPlayerR6(member.name) then
                    local payload=table.concat({"F1","LEVEL",ShortNameR6(UnitName("player") or ""),tostring(newLevel),signature,tostring(self:Now())},"^")
                    self:QueueNetworkPayload(payload,"WHISPER",member.name,1,"release175","F1LEVEL:"..KeyR6(member.name))
                end
            end
        end
    end
end


-- r41: D001 must be observable by the local client even when the character
-- reaching 60 does not run the addon. We keep a transient baseline only for
-- guild members currently grouped with this player. Seeing somebody already at
-- 60 establishes a baseline; only a real <60 -> 60 transition awards progress.
function OTLGM:ObserveGroupedGuildLevelsR41(silent)
    self.runtime=self.runtime or {}
    if self.IsAchievementComplete174 and self:IsAchievementComplete174("D001") then
        self.runtime.groupLevelBaselineR41=nil
        return false
    end
    local group=self.GetGroupSnapshot174 and self:GetGroupSnapshot174() or nil
    local baseline=self.runtime.groupLevelBaselineR41 or {}
    self.runtime.groupLevelBaselineR41=baseline
    local seen={}
    local index,member,key,level,previous
    for index=1,table.getn(group and group.guildMembers or {}) do
        member=group.guildMembers[index]
        if member and not IsPlayerR6(member.name) then
            key=KeyR6(member.name)
            level=0
            if member.unit and UnitLevel then level=tonumber(UnitLevel(member.unit)) or 0 end
            if level<=0 then level=tonumber(member.level) or 0 end
            if key~="" and level>0 then
                seen[key]=true
                previous=tonumber(baseline[key]) or 0
                baseline[key]=level
                if previous>0 and previous<MAX_LEVEL_R6 and level>=MAX_LEVEL_R6 then
                    self:SetAchievementCounter174("witnessMaxLevelR6",1)
                    self:CompleteAchievement174("D001",silent and true or false)
                    self.runtime.groupLevelBaselineR41=nil
                    return true
                end
            end
        end
    end
    for key in pairs(baseline) do if not seen[key] then baseline[key]=nil end end
    return false
end

local PreviousReleaseMessageR6=OTLGM.__impl180.HandleRelease175Message__impl1
function OTLGM:HandleRelease175Message(message,channel,sender)
    local fields=self:Split(message or "","^")
    if fields[1]=="F1" and fields[2]=="LEVEL" then
        local level=tonumber(fields[4]) or 0
        local ts=tonumber(fields[6]) or 0
        if level>=MAX_LEVEL_R6 and math.abs(self:Now()-ts)<=180 and IsGuildMemberR6(self,sender) then
            local group=self:GetGroupSnapshot174()
            if not group then return PreviousReleaseMessageR6 and PreviousReleaseMessageR6(self,message,channel,sender) or false end
            local found=false
            local index,member
            for index=1,table.getn(group.guildMembers or {}) do
                member=group.guildMembers[index]
                if KeyR6(member and member.name or "")==KeyR6(sender) then found=true break end
            end
            if found then self:SetAchievementCounter174("witnessMaxLevelR6",1) self:CompleteAchievement174("D001",false) return true end
        end
    end
    return PreviousReleaseMessageR6 and PreviousReleaseMessageR6(self,message,channel,sender) or false
end

local PreviousBeginTradeR6=OTLGM.__impl180.BeginTradeTracking174__impl1
function OTLGM:BeginTradeTracking174()
    PreviousBeginTradeR6(self)
    if self.runtime and self.runtime.trade174 then self.runtime.trade174.r6=true end
end

local PreviousUpdateTradeR6=OTLGM.__impl180.UpdateTradeTracking174__impl1
function OTLGM:UpdateTradeTracking174()
    PreviousUpdateTradeR6(self)
    local trade=self.runtime and self.runtime.trade174
    if not trade then return end
    trade.playerMoney=GetPlayerTradeMoney and tonumber(GetPlayerTradeMoney()) or 0
    trade.targetMoney=GetTargetTradeMoney and tonumber(GetTargetTradeMoney()) or 0
    trade.playerItems=0 trade.targetItems=0
    local index
    for index=1,6 do
        if GetTradePlayerItemLink and GetTradePlayerItemLink(index) then trade.playerItems=trade.playerItems+1 end
        if GetTradeTargetItemLink and GetTradeTargetItemLink(index) then trade.targetItems=trade.targetItems+1 end
    end
end

local PreviousFinishTradeR6=OTLGM.__impl180.FinishTradeTracking174__impl1
function OTLGM:FinishTradeTracking174(success)
    local trade=self.runtime and self.runtime.trade174
    if trade then self:UpdateTradeTracking174() end
    trade=self.runtime and self.runtime.trade174
    local snapshot=nil
    if trade then
        snapshot={target=trade.target,playerMoney=tonumber(trade.playerMoney) or 0,targetMoney=tonumber(trade.targetMoney) or 0,playerItems=tonumber(trade.playerItems) or 0,targetItems=tonumber(trade.targetItems) or 0}
    end
    PreviousFinishTradeR6(self,success)
    if not success or not snapshot or not IsGuildMemberR6(self,snapshot.target) then return end
    if snapshot.playerMoney>=COPPER_PER_GOLD_R6 and snapshot.targetMoney==0 and snapshot.targetItems==0 then self:SetAchievementCounter174("generousTipR6",1) self:CompleteAchievement174("D007",false) end
    if snapshot.playerMoney==1 and snapshot.targetMoney==0 and snapshot.targetItems==0 and snapshot.playerItems==0 and IsLucksNameR6(snapshot.target) then self:SetAchievementCounter174("exactChangeR6",1) self:CompleteAchievement174("D020",false) end
end

local PreviousCheckResurrectionR6=OTLGM.__impl180.CheckResurrection175__impl2
function OTLGM.__impl180.CheckResurrection175__impl3(self)
    local target=self.runtime and self.runtime.resurrection175 and self.runtime.resurrection175.target or ""
    local result=PreviousCheckResurrectionR6(self)
    if result and target~="" and IsLucksNameR6(target) then self:SetAchievementCounter174("riseCommanderR6",1) self:CompleteAchievement174("D011",false) end
    return result
end

local function CaptureMailR6(self,recipient)
    local hasItem=false
    local index
    if GetSendMailItem then
        for index=1,12 do local name=GetSendMailItem(index) if name then hasItem=true break end end
    end
    if not hasItem and SendMailItemButton and SendMailItemButton.icon and SendMailItemButton.icon.GetTexture and SendMailItemButton.icon:GetTexture() then hasItem=true end
    self.runtime=self.runtime or {}
    self.runtime.pendingMailR6={recipient=ShortNameR6(recipient),hasItem=hasItem,ts=self:Now()}
end

local function InstallMailHookR6(self)
    if self.mailHookR6 or type(SendMail)~="function" then return end
    self.mailHookR6=true
    local base=SendMail
    SendMail=function(recipient,subject,body)
        if OTLGM then CaptureMailR6(OTLGM,recipient) end
        return base(recipient,subject,body)
    end
end

local function ScanInboxR6(self)
    if not GetInboxNumItems or not GetInboxHeaderInfo then return end
    local count=tonumber(GetInboxNumItems()) or 0
    local index,sender
    for index=1,count do
        local packageIcon,stationeryIcon,headerSender=GetInboxHeaderInfo(index)
        sender=ShortNameR6(headerSender)
        if sender~="" and IsGuildMemberR6(self,sender) then AddSetR6(self,"mailGuildSendersR6",sender) end
    end
    if CountR6(self:GetAchievementSet174("mailGuildSendersR6"))>=10 then self:CompleteAchievement174("D009",false) end
end

local function CompleteMailSendR6(self)
    local state=self.runtime and self.runtime.pendingMailR6
    if not state or self:Now()-(state.ts or 0)>30 then return end
    self.runtime.pendingMailR6=nil
    if state.hasItem and IsGuildMemberR6(self,state.recipient) then self:SetAchievementCounter174("mailCallR6",1) self:CompleteAchievement174("D008",false) end
end

-- Loot tracker is deliberately conservative. It only awards when the client has
-- both an active standard loot roll and a matching winner/result message.
local function EnsureLootRollR6(self,rollId)
    self.runtime=self.runtime or {} self.runtime.lootRollsR6=self.runtime.lootRollsR6 or {}
    local key=tostring(rollId or "recent")
    local state=self.runtime.lootRollsR6[key]
    if not state then state={id=rollId,ts=self:Now(),passes={},rolls={}} self.runtime.lootRollsR6[key]=state end
    if GetLootRollItemInfo and rollId then
        local texture,name,count,quality=GetLootRollItemInfo(rollId)
        state.name=name or state.name state.quality=tonumber(quality) or state.quality state.texture=texture or state.texture
    end
    return state
end

local function InstallLootHookR6(self)
    if self.lootHookR6 or type(RollOnLoot)~="function" then return end
    self.lootHookR6=true
    local base=RollOnLoot
    RollOnLoot=function(rollId,choice)
        if OTLGM then
            local state=EnsureLootRollR6(OTLGM,rollId)
            state.localChoice=tonumber(choice)
            local groupR6,fullR6=FullGuildPartyR6(OTLGM)
            state.fullGuild=fullR6
            if tonumber(choice)==0 then
                state.passes[KeyR6(UnitName("player") or "")]=true
                if state.fullGuild and tonumber(state.quality)==4 then OTLGM:SetAchievementCounter174("epicPassR6",1) OTLGM:CompleteAchievement174("D005",false) end
            end
        end
        return base(rollId,choice)
    end
end

local function RecentLootStateR6(self)
    local newest=nil
    local key,state
    for key,state in pairs(self.runtime and self.runtime.lootRollsR6 or {}) do if not newest or (state.ts or 0)>(newest.ts or 0) then newest=state end end
    return newest
end

local function ParseRollSystemR6(self,message)
    local text=tostring(message or "")
    local lower=string.lower(text)

    -- /roll remains a system-chat message.
    local _,_,name,value,minv,maxv=string.find(text,"^(.+) rolls (%d+) %((%d+)%-(%d+)%)")
    if name and tonumber(value)==100 and tonumber(minv)==1 and tonumber(maxv)==100 and IsPlayerR6(name) then
        local group,full=FullGuildPartyR6(self)
        if full then self:SetAchievementCounter174("rollOfFateR6",1) self:CompleteAchievement174("D010",false) end
    end

    local state=RecentLootStateR6(self)
    if not state then return end
    local player=ShortNameR6(UnitName and UnitName("player") or "")
    local rolledName,rolledValue,choice

    -- Vanilla 1.12 loot messages live in CHAT_MSG_LOOT and use different
    -- layouts for self and other players. Support both stock forms plus the
    -- older/custom "Name rolls N ... Need/Greed" wording.
    _,_,rolledValue=string.find(text,"^You roll a (%d+) %(Need%) on:")
    if rolledValue then rolledName=player choice="NEED" end
    if not rolledValue then
        _,_,rolledValue=string.find(text,"^You roll a (%d+) %(Greed%) on:")
        if rolledValue then rolledName=player choice="GREED" end
    end
    if not rolledValue then
        _,_,rolledValue,rolledName=string.find(text,"^Need Roll %- (%d+) .- by (.+)$")
        if rolledValue then choice="NEED" end
    end
    if not rolledValue then
        _,_,rolledValue,rolledName=string.find(text,"^Greed Roll %- (%d+) .- by (.+)$")
        if rolledValue then choice="GREED" end
    end
    if not rolledValue then
        local _,_,genericName,genericValue=string.find(text,"^(.+) rolls (%d+)")
        if genericName and genericValue and (string.find(lower,"need",1,true) or string.find(lower,"greed",1,true)) then
            rolledName=genericName rolledValue=genericValue
            choice=string.find(lower,"need",1,true) and "NEED" or "GREED"
        end
    end
    if rolledName and rolledValue and choice then
        state.rolls[KeyR6(rolledName)]={value=tonumber(rolledValue) or 0,choice=choice}
    end

    local passName=nil
    if string.find(text,"^You passed on:") then passName=player
    else _,_,passName=string.find(text,"^(.+) passed on:") end
    if passName and IsGuildMemberR6(self,passName) then
        state.passes[KeyR6(passName)]=true
        if state.fullGuild and CountR6(state.passes)>=5 then
            self:SetAchievementCounter174("everybodyPassesR6",1)
            self:CompleteAchievement174("D006",false)
        end
    end

    local winner=nil
    if string.find(text,"^You won:") then winner=player
    else _,_,winner=string.find(text,"^(.+) won:") end
    if winner then
        winner=ShortNameR6(winner)
        local localRoll=state.rolls[KeyR6(player)]
        local winnerRoll=state.rolls[KeyR6(winner)]
        if IsPlayerR6(winner) and localRoll and localRoll.value==100 then
            self:SetAchievementCounter174("perfectRollR6",1) self:CompleteAchievement174("D003",false)
        end
        if not IsPlayerR6(winner) and IsGuildMemberR6(self,winner) and localRoll and winnerRoll
            and localRoll.value==99 and winnerRoll.value==100 and localRoll.choice==winnerRoll.choice then
            self:SetAchievementCounter174("soCloseR6",1) self:CompleteAchievement174("D004",false)
        end
    end
end

local function DeathNameR6(message)
    local _,_,name=string.find(tostring(message or ""),"^(.+) dies%.$")
    if not name then _,_,name=string.find(tostring(message or ""),"^(.+) is slain") end
    return ShortNameR6(name)
end

local function CheckWorldBossR6(self,message)
    local name=DeathNameR6(message)
    if name=="" or not WORLD_BOSSES_R6[KeyR6(name)] then return end
    local group=self:GetGroupSnapshot174()
    if group and group.isRaid and tonumber(group.guild)>=10 then self:SetAchievementCounter174("worldBossR6",1) self:CompleteAchievement174("D012",false) end
end

local function CheckFallTextR6(self,message)
    local lower=string.lower(tostring(message or ""))
    if string.find(lower,"fall",1,true) or string.find(lower,"паден",1,true) or string.find(lower,"sturz",1,true) or string.find(lower,"chute",1,true) then
        self.runtime=self.runtime or {} self.runtime.pendingFallR6=self:Now()
    end
end

-- ---------------------------------------------------------------------------
-- Final UI corrections.
-- ---------------------------------------------------------------------------

local PreviousBuildActivityR6=OTLGM.__impl180.BuildActivityPage__impl4
function OTLGM:BuildActivityPage(page)
    PreviousBuildActivityR6(self,page)
    local heat=self.ui.heatmapCells and self.ui.heatmapCells[0] and self.ui.heatmapCells[0][0] and self.ui.heatmapCells[0][0]:GetParent() or nil
    local composition=self.ui.compositionTotal and self.ui.compositionTotal:GetParent() or nil
    if heat then MoveR6(heat,page,0,-142,470,340) end
    if composition then MoveR6(composition,page,480,-142,238,340) end
    -- The heatmap note ends around -472. Keep a dedicated gap before the
    -- two-line insight strip, then a separate action row below it.
    if self.ui.activityInsightPanelR4 then MoveR6(self.ui.activityInsightPanelR4,page,0,-486,718,42) end
    if self.ui.activityInsightText170 then
        MoveR6(self.ui.activityInsightText170,self.ui.activityInsightPanelR4 or page,9,-5,700,32)
        if self.ui.activityInsightText170.SetJustifyV then self.ui.activityInsightText170:SetJustifyV("TOP") end
    end
    if self.ui.activitySync156 then MoveR6(self.ui.activitySync156,page,340,-534,178,27) end
    if self.ui.activitySummaryButton then MoveR6(self.ui.activitySummaryButton,page,528,-534,190,27) end
end

local PreviousRefreshActivityR6=OTLGM.__impl180.RefreshActivityPage__impl3
function OTLGM:RefreshActivityPage()
    self.runtime = self.runtime or {}
    -- Preserve Activity's evidence-gathering semantics even when the expensive
    -- visual repaint can be skipped. Nearby faction observations may change
    -- without a roster commit, so perform that bounded probe before the cache key.
    if self.RefreshObservedGuildFactions180 then self:RefreshObservedGuildFactions180("activity-r31-probe") end
    local dbR31 = self.GetGuildDB and self:GetGuildDB() or nil
    local sharedR31 = self.EnsureSharedActivity156 and self:EnsureSharedActivity156() or nil
    local activityR31 = dbR31 and dbR31.activity or nil
    local renderRevisionR31 = tostring(tonumber(dbR31 and dbR31.lastScan) or 0) .. ":"
        .. tostring(tonumber(activityR31 and activityR31.totalScans) or 0) .. ":"
        .. tostring(tonumber(sharedR31 and sharedR31.revisionR26) or 0) .. ":"
        .. tostring(tonumber(self.runtime.factionObservationRevision180) or 0) .. ":"
        .. tostring(math.floor(self:Now() / 60))
    if self.runtime.activityRenderRevisionR31 == renderRevisionR31 then
        self.runtime.activityRenderSkipsR31 = (tonumber(self.runtime.activityRenderSkipsR31) or 0) + 1
        return true
    end
    self.runtime.activityRenderRevisionR31 = renderRevisionR31
    local result=PreviousRefreshActivityR6(self)
    if self.ui and self.ui.activityInsightText170 then
        local text=tostring(self.ui.activityInsightText170:GetText() or "")
        text=string.gsub(text,"%s+|%s+Coverage:","\nCoverage:")
        self.ui.activityInsightText170:SetText(text)
    end
    return result
end

local PreviousRefreshNavigationR6=OTLGM.__impl180.RefreshNavigation__impl1

-- ---------------------------------------------------------------------------
-- Event bridge and debounced work.
-- ---------------------------------------------------------------------------

local PreviousTimersR6=OTLGM.__impl180.ProcessQuality156Timers__impl2
function OTLGM.__impl180.ProcessQuality156Timers__impl3(self)
    if PreviousTimersR6 then
        local ok, problem = pcall(PreviousTimersR6, self)
        if not ok and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Quality/ACHIEVEMENT_CHAIN", problem) end
    end
    local now=self:Now()
    if self.runtime and self.runtime.bagScanDueR6 and now>=self.runtime.bagScanDueR6 then
        self.runtime.bagScanDueR6=nil
        local ok, problem = pcall(ScanBagsR6, self, false)
        if not ok and self.RecordInternalIssueRC3 then pcall(self.RecordInternalIssueRC3, self, "Quality/ACTIVITY_BAG_SCAN", problem) end
    end
    if self.runtime and self.runtime.pendingFallR6 and now-self.runtime.pendingFallR6>5 then self.runtime.pendingFallR6=nil end
    local key,state
    for key,state in pairs(self.runtime and self.runtime.lootRollsR6 or {}) do if now-(state.ts or now)>180 then self.runtime.lootRollsR6[key]=nil end end
end


-- Final 1.8 safety bridge. Performance176 intentionally detaches the old broad
-- R6 event frame during cold-start hardening. Expose the already conservative
-- achievement handlers so a later, filtered event bridge can restore the
-- achievements without restoring the old wide event ownership.
function OTLGM:EnsureSafeActivityHooks180()
    InstallLootHookR6(self)
    return true
end

function OTLGM:NeedsGravityTracking180()
    if self.IsAchievementComplete174 and self:IsAchievementComplete174("D021") then return false end
    return HasGuildPartnerR6(self) and true or false
end

function OTLGM:HandleSafeActivityEvent180(eventName, firstArg, secondArg)
    if eventName == "PLAYER_MONEY" then
        -- This is a constant-time check. R4 detached the legacy money event with
        -- the rest of the broad R6 frame, which meant First Fortune / Absolutely
        -- Broke could remain stale until a zone transition. Keep the event only
        -- while one of those two achievements is still incomplete.
        CheckMoneyR6(self, false)
        return true
    elseif eventName == "START_LOOT_ROLL" then
        EnsureLootRollR6(self, firstArg)
        return true
    elseif eventName == "CANCEL_LOOT_ROLL" then
        if self.runtime and self.runtime.lootRollsR6 then self.runtime.lootRollsR6[tostring(firstArg or "recent")] = nil end
        return true
    elseif eventName == "CHAT_MSG_SYSTEM" then
        local text = tostring(firstArg or "")
        -- Stock /roll results are system messages; Need/Greed/pass/winner
        -- traffic is handled from CHAT_MSG_LOOT below.
        if string.find(string.lower(text), " rolls ", 1, true) then ParseRollSystemR6(self, text) end
        return true
    elseif eventName == "CHAT_MSG_LOOT" then
        ParseRollSystemR6(self, tostring(firstArg or ""))
        return true
    elseif eventName == "UNIT_LEVEL" then
        self:ObserveGroupedGuildLevelsR41(false)
        return true
    elseif eventName == "CHAT_MSG_GUILD" then
        local text = tostring(firstArg or "")
        -- Living Legend is the only tracker on guild chat and only needs item
        -- links sent by this character. Normal guild chatter is a constant-time
        -- early return and never scans bags.
        if string.find(text, "item:", 1, true) then CheckLivingLegendR6(self, text, secondArg) end
        return true
    elseif eventName == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
        local lower = string.lower(tostring(firstArg or ""))
        -- World-boss death traffic is filtered by boss name before asking for a
        -- cached group snapshot, so ordinary raid trash deaths are near-free.
        if string.find(lower, "azuregos", 1, true) or string.find(lower, "kazzak", 1, true)
            or string.find(lower, "emeriss", 1, true) or string.find(lower, "lethon", 1, true)
            or string.find(lower, "taerar", 1, true) or string.find(lower, "ysondre", 1, true)
            or string.find(lower, "ostarius", 1, true) or string.find(lower, "concavius", 1, true)
            or string.find(lower, "nerubian overseer", 1, true)
            or string.find(lower, "dark reaver of karazhan", 1, true) then
            CheckWorldBossR6(self, firstArg)
        end
        return true
    elseif eventName == "CHAT_MSG_COMBAT_SELF_HITS" or eventName == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        -- Performance176 only subscribes to these high-frequency events while
        -- D021 is incomplete and a guild partner is actually in the group.
        CheckFallTextR6(self, firstArg)
        return true
    elseif eventName == "PLAYER_DEAD" then
        if self.runtime and self.runtime.pendingFallR6 and self:Now() - self.runtime.pendingFallR6 <= 3
            and HasGuildPartnerR6(self) then
            self:SetAchievementCounter174("gravityWinsR6", 1)
            self:CompleteAchievement174("D021", false)
        end
        if self.runtime then self.runtime.pendingFallR6 = nil end
        return true
    end
    return false
end

local frameR6=CreateFrame("Frame","OTLGM_ReleaseEvent175R6")
local eventsR6={"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_LEVEL_UP","PLAYER_MONEY","ZONE_CHANGED_NEW_AREA","BAG_UPDATE","MAIL_SHOW","MAIL_INBOX_UPDATE","MAIL_SEND_SUCCESS","START_LOOT_ROLL","CANCEL_LOOT_ROLL","CHAT_MSG_SYSTEM","CHAT_MSG_GUILD","CHAT_MSG_COMBAT_SELF_HITS","CHAT_MSG_SPELL_SELF_DAMAGE","PLAYER_DEAD","CHAT_MSG_COMBAT_HOSTILE_DEATH","GUILD_ROSTER_UPDATE"}
for i=1,table.getn(eventsR6) do pcall(frameR6.RegisterEvent,frameR6,eventsR6[i]) end
frameR6:SetScript("OnEvent",function()
    if not OTLGM then return end
    OTLGM.runtime=OTLGM.runtime or {}
    if event=="PLAYER_LOGIN" then
        InstallMailHookR6(OTLGM) InstallLootHookR6(OTLGM)
        local db=OTLGM:EnsureAchievements174()
        local silent=not db.releaseBaselineR6
        CheckMoneyR6(OTLGM,silent)
        ScanBagsR6(OTLGM,silent)
        db.releaseBaselineR6=true
    elseif event=="PLAYER_ENTERING_WORLD" then CheckMoneyR6(OTLGM,false) OTLGM.runtime.bagScanDueR6=OTLGM:Now()+1
    elseif event=="PLAYER_LEVEL_UP" then CheckLevelUpR6(OTLGM,arg1)
    elseif event=="PLAYER_MONEY" or event=="ZONE_CHANGED_NEW_AREA" then CheckMoneyR6(OTLGM,false)
    elseif event=="BAG_UPDATE" then OTLGM.runtime.bagScanDueR6=OTLGM:Now()+1
    elseif event=="MAIL_SHOW" or event=="MAIL_INBOX_UPDATE" then InstallMailHookR6(OTLGM) ScanInboxR6(OTLGM)
    elseif event=="MAIL_SEND_SUCCESS" then CompleteMailSendR6(OTLGM)
    elseif event=="START_LOOT_ROLL" then EnsureLootRollR6(OTLGM,arg1)
    elseif event=="CANCEL_LOOT_ROLL" then if OTLGM.runtime.lootRollsR6 then OTLGM.runtime.lootRollsR6[tostring(arg1 or "recent")]=nil end
    elseif event=="CHAT_MSG_SYSTEM" then ParseRollSystemR6(OTLGM,arg1) CheckFallTextR6(OTLGM,arg1)
    elseif event=="CHAT_MSG_GUILD" then CheckLivingLegendR6(OTLGM,arg1,arg2)
    elseif event=="CHAT_MSG_COMBAT_SELF_HITS" or event=="CHAT_MSG_SPELL_SELF_DAMAGE" then CheckFallTextR6(OTLGM,arg1)
    elseif event=="PLAYER_DEAD" then
        if OTLGM.runtime.pendingFallR6 and OTLGM:Now()-OTLGM.runtime.pendingFallR6<=3 and HasGuildPartnerR6(OTLGM) then OTLGM:SetAchievementCounter174("gravityWinsR6",1) OTLGM:CompleteAchievement174("D021",false) end
        OTLGM.runtime.pendingFallR6=nil
    elseif event=="CHAT_MSG_COMBAT_HOSTILE_DEATH" then CheckWorldBossR6(OTLGM,arg1)
    elseif event=="GUILD_ROSTER_UPDATE" then OTLGM.runtime.guildLeaderR6=nil
    end
end)

if OTLGM.RegisterModule then OTLGM:RegisterModule("ActivityTracking",{layer="feature",corrective=true,revision=7,totalAchievements=147,eventDriven=true,noOnUpdate=true}) end
